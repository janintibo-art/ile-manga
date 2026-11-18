extends RefCounted
## V170 : on entre dans les boutiques et les bâtiments publics de Pile-ou-Face (l'Île Perchée), de
## Port-Azur, de Pandémonia (l'Île de Braise), de Montjoie et de Cliquetis.
## Chaque ville pose la porte de ses boutiques (porte()) : on entre comme dans une maison (maisons_v81),
## et derrière la porte, la pièce de son métier (« b170 » ; build()) : le comptoir, les étagères
## pleines, ce qui dit le métier (le four du boulanger, la forge et l'enclume, les tiroirs de
## l'apothicaire, la grille du guichet, le grand coffre de la banque, les stalles de l'écurie, la
## scène du théâtre, la lunette de l'observatoire…), et le marchand derrière son comptoir.
## Le marchand est la vraie personne de la ville quand elle existe (son visage, sa tenue ; on lui
## parle comme dehors : sa boutique, ses histoires, ce qu'elle pense de nous) ; sinon, un habitant
## de la ville tient la boutique (un petit menu : acheter, vendre, ses services, ce qu'il raconte).
## Pas d'alcool sur les étagères (on est en famille) : des sirops, des jus, du café.
## M : maisons_v81 ; R : la pièce (maisons_pieces_v81).

const S = preload("res://scripts/maisons_scenes_v81.gd")
const Kit = preload("res://scripts/azur_kit_v56.gd")
const Inv = preload("res://scripts/inventory_v28.gd")
const Figurant = preload("res://scripts/pnj/figurant_v81.gd")
const Sud = preload("res://scripts/maisons_sud_v169.gd")
## V171 : les temples, les palais, les ateliers et les tours (Trois Soleils, Arcanelle, Port-Coutelas)
const L171 = preload("res://scripts/lieux_v171.gd")
## V172 : Tazira, Ramure, Port-Boucan
const L172 = preload("res://scripts/lieux_v172.gd")
## Les modules de lieux (chacun : HISTOIRE, METIERS, VILLES, _pal, build)
## V173 : les tours de la Citadelle des Nuées, le phare, le moulin et la grange de Montjoie, la tour de
## contrôle d'Astralys, le mausolée de Sombreval.
const L173 = preload("res://scripts/lieux_v173.gd")
## V174 : chez les Géants (la maison des Grandpré, le Moulin de la Butte) ; ils font leur coque eux-mêmes
const L174 = preload("res://scripts/lieux_v174.gd")
const LIEUX := [L171, L172, L173, L174]

const HISTOIRE := "b170"
const ALCOOL := ["rhum", "biere", "cidre", "hydromel", "grog", "vin_"]

## Chaque métier : la taille de la pièce (largeur, profondeur) et sa hauteur.
const METIERS := {
	"bazar": [Vector2(10.0, 8.0), 3.4], "banque": [Vector2(11.0, 9.0), 3.9], "forge": [Vector2(10.0, 9.0), 3.8],
	"poste": [Vector2(9.0, 7.5), 3.3], "hotel": [Vector2(11.0, 9.0), 3.6], "epicerie": [Vector2(9.0, 7.5), 3.2],
	"apothicaire": [Vector2(8.5, 7.5), 3.3], "sherif": [Vector2(9.5, 8.0), 3.3], "prospecteurs": [Vector2(9.0, 7.5), 3.3],
	"chapelier": [Vector2(8.5, 7.0), 3.2], "sellerie": [Vector2(9.0, 7.5), 3.3], "ecurie": [Vector2(12.0, 10.0), 4.2],
	"horloger": [Vector2(8.5, 7.0), 3.3], "theatre": [Vector2(12.0, 13.0), 5.2], "gare": [Vector2(12.0, 8.5), 4.4],
	"capitainerie": [Vector2(9.0, 7.5), 3.3], "location": [Vector2(9.0, 7.5), 3.3], "restaurant": [Vector2(11.0, 8.5), 3.4],
	"cafe": [Vector2(10.0, 8.0), 3.4], "bijouterie": [Vector2(8.0, 6.5), 3.2], "boulangerie": [Vector2(9.0, 7.5), 3.3],
	"libraire": [Vector2(9.0, 7.5), 3.6], "magie": [Vector2(8.5, 7.5), 3.6], "couture": [Vector2(9.0, 7.5), 3.3],
	"barbier": [Vector2(8.0, 7.0), 3.3], "atelier": [Vector2(10.0, 8.5), 3.8], "poissonnerie": [Vector2(9.0, 7.0), 3.3],
	"caserne": [Vector2(11.0, 9.0), 3.5], "epices": [Vector2(9.0, 7.5), 3.3], "academie": [Vector2(12.0, 9.0), 4.2],
	"labo": [Vector2(10.0, 9.0), 4.4], "observatoire": [Vector2(8.5, 8.5), 6.0], "fabrique": [Vector2(12.0, 10.0), 4.8],
}

## Les couleurs des sirops, des confitures, des potions (pour les bocaux, les fioles).
const TEINTES := [Color(0.75, 0.12, 0.15), Color(0.95, 0.62, 0.12), Color(0.35, 0.6, 0.18), Color(0.55, 0.25, 0.6),
	Color(0.92, 0.82, 0.3), Color(0.2, 0.45, 0.75), Color(0.6, 0.35, 0.18), Color(0.85, 0.4, 0.55)]


# =================================================================== les portes (les villes les posent)

## Une porte de boutique : door (devant la porte, dehors), out (vers la rue), style (la ville :
## « perchee », « azur », « braise », « montjoie », « cliquetis »), metier (METIERS), proprio (l'id de
## la vraie personne qui la tient, ou ""), nom (« au Bazar de la Veuve Clou » : pour « E : entrer … »),
## enseigne (ce qu'on lit dedans, au-dessus du comptoir).
static func porte(door: Vector3, out: Vector3, style: String, metier: String, proprio: String, nom: String, enseigne: String = "", histoire: String = HISTOIRE) -> bool:
	out.y = 0.0
	var me: Array = _met(metier)
	if out.length() < 0.01 or me.is_empty():
		return false
	var t: Vector2 = me[0]
	Kit.PORTES_V81.append({"door": door, "out": out.normalized(), "w": t.x, "d": t.y, "style": style, "floors": 1, "owner": proprio,
		"histoire": histoire, "metier": metier, "proprio": proprio, "nom170": nom, "enseigne170": enseigne if enseigne != "" else nom,
		"entrer": "E : entrer " + nom})
	return true


## Les boutiques de chaque ville : id (celui de la ville) → [métier, la vraie personne, « E : entrer … », enseigne].
const VILLES := {
	"perchee": {
		"bazar": ["bazar", "veuve_clou_pp", "au Bazar de la Veuve Clou", "Bazar de la Veuve Clou"],
		"banque": ["banque", "", "à la Banque de l'Écu Perché", "Banque de l'Écu Perché"],
		"forge": ["forge", "hilda_pp", "à la Forge du Marteau-Pilon", "Forge du Marteau-Pilon"],
		"poste": ["poste", "", "à la Poste & Télégraphe", "Poste & Télégraphe"],
		"hotel": ["hotel", "", "à l'Hôtel des Nuages", "Hôtel des Nuages"],
		"epicerie": ["epicerie", "rosemonde_pp", "chez Clous & Confitures", "Clous & Confitures"],
		"apothicaire": ["apothicaire", "cornemuse_pp", "chez Doc Cornemuse, l'apothicaire", "Apothicaire Doc Cornemuse"],
		"sherif": ["sherif", "sherif_plomb_pp", "au Bureau du Shérif", "Bureau du Shérif"],
		"prospecteurs": ["prospecteurs", "pepite_pp", "au Comptoir des Prospecteurs", "Comptoir des Prospecteurs"],
		"chapelier": ["chapelier", "fanchon_pp", "au Chapeau Pointu", "Au Chapeau Pointu"],
		"sellerie": ["sellerie", "", "à la Sellerie des Éperons", "Sellerie des Éperons"],
		"ecurie": ["ecurie", "", "à l'Écurie du Grand Galop", "Écurie du Grand Galop"],
		"horloger": ["horloger", "gedeon_tic_pp", "à l'Horlogerie Tic & Tac", "Horlogerie Tic & Tac"],
		"theatre": ["theatre", "", "au Théâtre des Mirages", "Théâtre des Mirages"],
	},
	"azur": {
		"gare": ["gare", "", "à la gare maritime", "Gare maritime"],
		"capitainerie": ["capitainerie", "odette", "à la capitainerie", "Capitainerie"],
		"location": ["location", "yannick", "chez Yannick, le loueur de bateaux", "Location de bateaux"],
		"paulo": ["restaurant", "paulo", "chez Paulo", "Chez Paulo"],
		"bijouterie": ["bijouterie", "ines", "à la bijouterie d'Inès", "Bijouterie"],
		"souvenirs": ["bazar", "victor", "aux Souvenirs de Victor", "Souvenirs de Port-Azur"],
		"boulangerie": ["boulangerie", "margaux", "à la boulangerie de Margaux", "Boulangerie"],
		"epicerie": ["epicerie", "colette", "à l'épicerie de Colette", "Épicerie"],
		"cafe": ["cafe", "gisele", "au Café de la Place", "Café de la Place"],
		"poste": ["poste", "nadine", "à la poste", "La Poste"],
		"libraire": ["libraire", "felix", "à la librairie de Félix", "Librairie"],
		"herboriste": ["apothicaire", "amelie", "chez l'herboriste", "Herboristerie"],
		"armurerie": ["forge", "hector", "à l'armurerie d'Hector", "Armurerie"],
	},
	"braise": {
		"armurier": ["forge", "kraxx", "chez Kraxx, l'armurier", "Armurerie du Grand Marché"],
		"apothicaire": ["apothicaire", "vesperine", "chez Vespérine, l'apothicaire", "Apothicaire du Grand Marché"],
		"boulangerie": ["boulangerie", "bobor", "au Four Éternel", "Le Four Éternel"],
		"epices": ["epices", "zebuline", "aux Épices de Zébuline", "Épices de Zébuline"],
		"couture": ["couture", "grisette", "chez Grisette, la couturière", "Atelier de Grisette"],
		"barbier": ["barbier", "tiburce", "chez Tiburce, barbe et cornes", "Tiburce, barbe et cornes"],
		"inventeur": ["atelier", "zigomar", "à l'atelier de Zigomar", "Atelier de Zigomar"],
		"capitainerie": ["capitainerie", "charbonnel", "à la capitainerie du Port de Cendre", "Capitainerie du Port de Cendre"],
		"poste": ["poste", "brindille_braise", "à la poste ailée", "Poste ailée"],
		"poissonnerie": ["poissonnerie", "moloka", "chez Moloka, la poissonnière", "Poissonnerie"],
		"caserne": ["caserne", "pyrus", "à la caserne de la Garde", "Caserne de la Garde"],
	},
	"montjoie": {
		"olga": ["magie", "olga", "chez Madame Olga, marchande de magie", "Boutique de magie"],
		"aubin": ["apothicaire", "aubin", "chez Aubin, l'apothicaire", "Apothicaire"],
		"honorine": ["boulangerie", "honorine", "à la boulangerie d'Honorine", "Boulangerie"],
		"colombe": ["couture", "colombe", "chez Colombe, la couturière", "Couture"],
		"caserne": ["caserne", "ferdinand", "à la caserne", "Caserne de la garde"],
	},
	"cliquetis": {
		"academie": ["academie", "heloise", "à l'Académie des Ingénieurs", "Académie des Ingénieurs"],
		"cafe": ["cafe", "gaston", "au Café de la Bielle", "Café de la Bielle"],
		"bazar": ["bazar", "bricolette", "au Bazar des Inutilités", "Bazar des Inutilités"],
		"boum": ["atelier", "boum", "à l'atelier du Professeur Boum", "Atelier du Professeur Boum"],
		"volta": ["labo", "electre", "au laboratoire Volta", "Laboratoire Volta"],
		"observatoire": ["observatoire", "celeste", "à l'observatoire", "Observatoire"],
		"fabrique": ["fabrique", "rivet", "à la fabrique de robots", "Fabrique de robots"],
	},
}


## Une ville pose la porte d'une de ses boutiques (VILLES) : faux si ce n'en est pas une.
static func porte_ville(style: String, id: String, door: Vector3, out: Vector3) -> bool:
	var v: Dictionary = VILLES.get(style, {})
	if not v.has(id):
		return false
	var e: Array = v[id]
	return porte(door, out, style, str(e[0]), str(e[1]), str(e[2]), str(e[3]))


## Cette boutique s'ouvre-t-elle (pour la ville : ne plus dire « la porte est fermée ») ?
static func ouvre(style: String, id: String) -> bool:
	return (VILLES.get(style, {}) as Dictionary).has(id)


# =================================================================== ce que maisons_v81 demande

## (V171 : les lieux de lieux_v171 passent par ici aussi : leur histoire est « b171 »)
static func is_b170(cur: Dictionary) -> bool:
	return has(str(cur.get("histoire", "")))


## Le métier : [taille, hauteur] (les boutiques, puis les lieux de la V171) ; [] s'il n'existe pas.
static func _met(metier: String) -> Array:
	if METIERS.has(metier):
		return METIERS[metier]
	var L: Variant = _lieu(metier)
	return (L.METIERS as Dictionary)[metier] if L != null else []


## Le module de lieux qui connaît ce métier (null : une boutique, ou rien).
static func _lieu(metier: String) -> Variant:
	for L in LIEUX:
		if (L.METIERS as Dictionary).has(metier):
			return L
	return null


static func taille(cur: Dictionary) -> Vector2:
	var me: Array = _met(str(cur.get("metier", "")))
	return me[0] if not me.is_empty() else Vector2(9.0, 7.5)


static func has(sc: String) -> bool:
	if sc == HISTOIRE:
		return true
	for L in LIEUX:
		if sc == str(L.HISTOIRE):
			return true
	return false


## La coque : les murs, le sol et le plafond du métier, à la mode de la ville.
static func shell(M) -> void:
	var R = M.R
	var met: String = str(M.cur.get("metier", ""))
	var st: String = str(M.cur.get("style", ""))
	R.pal = (R.pal as Dictionary).duplicate()
	var me: Array = _met(met)
	R.H = float(me[1]) if not me.is_empty() else 3.3
	var L: Variant = _lieu(met)
	var p: Dictionary = L._pal(st, met) if L != null and (L.VILLES as Dictionary).has(st) else _pal(st, met)
	for key in ["sol", "mur", "bas", "plafond"]:
		var e: Array = p[key]
		R.pal[key] = e
		R._put(key, R._texmat(str(e[0]), e[1], {"sol": 0.72, "mur": 0.92, "bas": 0.88, "plafond": 0.95}[key]))
	for k2 in ["fenetre", "colombage", "tuyaux", "sans_poutres", "sans_lampe", "porte"]:
		if p.has(k2):
			R.pal[k2] = p[k2]
	# V174 : un lieu à l'échelle des géants fait sa coque lui-même (les murs épais, les fenêtres de géant)
	if L == L174 and L174.coque(M):
		return
	R.rideaux = false
	R.shell()
	R.rideaux = true


## La palette d'une boutique : [image, teinte, répétition] pour le sol, le mur, le bas, le plafond.
static func _pal(st: String, met: String) -> Dictionary:
	var planches := ["montjoie/bois_planches.png", Color(0.8, 0.64, 0.5), 1.8]
	var plafond := ["montjoie/bois_planches.png", Color(0.48, 0.36, 0.27), 2.0]
	var p := {"sol": planches, "mur": ["montjoie/enduit.png", Color(0.95, 0.92, 0.85), 2.5], "bas": ["maisons/lambris_miel.png", Color(1, 1, 1), 1.4], "plafond": plafond}
	match st:
		"perchee":
			p["mur"] = ["maisons/pp_rayures_sauge.png", Color(1, 1, 1), 1.8]
			match met:
				"banque":
					p["sol"] = ["maisons/damier_noir_blanc.png", Color(0.92, 0.9, 0.86), 1.0]
					p["mur"] = ["maisons/pp_damas_bleu.png", Color(0.9, 0.95, 1.0), 1.6]
					p["bas"] = ["maisons/lambris_sombre.png", Color(0.9, 0.85, 0.8), 1.4]
				"forge":
					p["sol"] = ["montjoie/dalles_donjon.png", Color(0.62, 0.56, 0.5), 2.0]
					p["mur"] = ["cliquetis/brique.png", Color(0.82, 0.7, 0.64), 2.2]
					p["bas"] = ["montjoie/moellons.png", Color(0.55, 0.5, 0.46), 1.4]
					p["plafond"] = ["montjoie/bois_planches.png", Color(0.3, 0.24, 0.2), 2.0]
					p["fenetre"] = "aucune"
				"poste":
					p["sol"] = ["maisons/damier_noir_blanc.png", Color(0.9, 0.88, 0.84), 1.0]
					p["mur"] = ["maisons/pp_rayures_bleu.png", Color(1, 1, 1), 1.8]
				"hotel":
					p["sol"] = ["maisons/parquet_chevron.png", Color(0.9, 0.8, 0.7), 2.4]
					p["mur"] = ["maisons/pp_fleurs_creme.png", Color(1, 1, 1), 1.8]
					p["bas"] = ["maisons/lambris_sombre.png", Color(0.95, 0.9, 0.85), 1.4]
				"epicerie":
					p["mur"] = ["maisons/pp_rayures_rose.png", Color(1, 1, 1), 1.8]
				"apothicaire":
					p["sol"] = ["maisons/damier_noir_blanc.png", Color(0.88, 0.9, 0.86), 1.0]
					p["mur"] = ["maisons/pp_fleurs_vert.png", Color(1, 1, 1), 1.8]
					p["bas"] = ["maisons/lambris_sombre.png", Color(0.9, 0.9, 0.85), 1.4]
				"sherif", "sellerie":
					p["mur"] = ["montjoie/bois_planches.png", Color(0.86, 0.72, 0.58), 1.6]
					p["bas"] = ["maisons/lambris_sombre.png", Color(0.9, 0.85, 0.8), 1.4]
				"prospecteurs":
					p["mur"] = ["beau165/adobe.png", Color(0.96, 0.88, 0.78), 2.2]
				"chapelier":
					p["sol"] = ["maisons/parquet_chevron_clair.png", Color(1, 1, 1), 2.4]
					p["mur"] = ["maisons/pp_rayures_rose.png", Color(1, 0.96, 0.96), 1.8]
					p["bas"] = ["maisons/lambris_blanc.png", Color(1, 1, 1), 1.4]
				"ecurie":
					p["sol"] = ["beau164/litiere.png", Color(0.95, 0.88, 0.7), 2.0]
					p["mur"] = ["montjoie/bois_planches.png", Color(0.78, 0.6, 0.46), 1.6]
					p["bas"] = ["montjoie/bois_planches.png", Color(0.55, 0.42, 0.32), 1.4]
					p["plafond"] = ["montjoie/bois_planches.png", Color(0.42, 0.32, 0.24), 2.0]
				"horloger":
					p["sol"] = ["maisons/parquet_chevron.png", Color(0.85, 0.75, 0.66), 2.4]
					p["mur"] = ["maisons/pp_damas_bleu.png", Color(1, 1, 1), 1.6]
					p["bas"] = ["maisons/lambris_sombre.png", Color(0.9, 0.85, 0.8), 1.4]
				"theatre":
					p["sol"] = ["maisons/parquet_chevron.png", Color(0.62, 0.48, 0.38), 2.6]
					p["mur"] = ["maisons/pp_damas_bordeaux.png", Color(1, 0.92, 0.9), 1.6]
					p["bas"] = ["maisons/lambris_sombre.png", Color(0.8, 0.72, 0.68), 1.4]
					p["fenetre"] = "aucune"
		"azur":
			p["sol"] = ["maisons/tomettes.png", Color(1, 1, 1), 2.2]
			p["mur"] = ["maisons/chaux_ocre.png", Color(1, 1, 1), 3.0]
			p["bas"] = ["maisons/lambris_miel.png", Color(1, 1, 1), 1.4]
			p["plafond"] = ["montjoie/bois_planches.png", Color(0.62, 0.5, 0.4), 2.0]
			match met:
				"gare":
					p["sol"] = ["maisons/damier_noir_blanc.png", Color(0.9, 0.88, 0.84), 1.0]
					p["mur"] = ["azur/enduit.png", Color(0.98, 0.93, 0.82), 2.5]
					p["bas"] = ["maisons/lambris_sombre.png", Color(0.95, 0.9, 0.85), 1.4]
				"capitainerie", "location":
					p["sol"] = ["maisons/parquet_chevron_clair.png", Color(0.95, 0.92, 0.88), 2.4]
					p["mur"] = ["maisons/chaux_bleu.png", Color(1, 1, 1), 3.0]
					p["bas"] = ["maisons/lambris_blanc.png", Color(1, 1, 1), 1.4]
				"restaurant":
					p["sol"] = ["maisons/carreaux_ciment_vert.png", Color(1, 1, 1), 1.6]
					p["mur"] = ["maisons/chaux_terracotta.png", Color(1, 1, 1), 3.0]
				"bijouterie":
					p["sol"] = ["maisons/damier_noir_blanc.png", Color(0.95, 0.93, 0.9), 1.0]
					p["mur"] = ["maisons/pp_fleurs_creme.png", Color(1, 0.97, 0.94), 1.8]
					p["bas"] = ["maisons/lambris_sombre.png", Color(0.9, 0.85, 0.82), 1.4]
				"bazar":
					p["mur"] = ["maisons/chaux_bleu.png", Color(1, 1, 1), 3.0]
				"boulangerie":
					p["sol"] = ["maisons/carreaux_ciment_bleu.png", Color(1, 1, 1), 1.6]
				"epicerie", "apothicaire":
					p["mur"] = ["maisons/chaux_vert.png", Color(1, 1, 1), 3.0]
					if met == "apothicaire":
						p["bas"] = ["maisons/lambris_blanc.png", Color(1, 1, 1), 1.4]
				"cafe":
					p["sol"] = ["maisons/damier_rouge_creme.png", Color(1, 1, 1), 1.2]
					p["bas"] = ["maisons/lambris_sombre.png", Color(0.95, 0.9, 0.85), 1.4]
				"poste":
					p["sol"] = ["maisons/damier_noir_blanc.png", Color(0.9, 0.88, 0.84), 1.0]
					p["mur"] = ["azur/enduit.png", Color(1.0, 0.9, 0.62), 2.5]
					p["bas"] = ["maisons/lambris_sombre.png", Color(0.95, 0.9, 0.85), 1.4]
				"libraire":
					p["sol"] = ["maisons/parquet_chevron.png", Color(0.9, 0.82, 0.72), 2.4]
					p["mur"] = ["maisons/chaux_vert.png", Color(0.9, 0.95, 0.88), 3.0]
					p["bas"] = ["maisons/lambris_sombre.png", Color(0.95, 0.9, 0.85), 1.4]
				"forge":
					p["sol"] = ["azur/dalles.png", Color(0.75, 0.68, 0.6), 1.2]
					p["mur"] = ["azur/moellons.png", Color(0.85, 0.78, 0.7), 2.0]
					p["bas"] = ["azur/moellons.png", Color(0.6, 0.54, 0.48), 1.4]
					p["plafond"] = ["montjoie/bois_planches.png", Color(0.34, 0.27, 0.22), 2.0]
		"braise":
			p["sol"] = ["braise/dalles_palais.png", Color(0.82, 0.76, 0.76), 2.2]
			p["mur"] = ["braise/enduit_rouge.png", Color(0.92, 0.78, 0.76), 2.5]
			p["bas"] = ["braise/basalte.png", Color(0.62, 0.58, 0.58), 1.4]
			p["plafond"] = ["braise/bois_brule.png", Color(0.6, 0.52, 0.5), 2.0]
			match met:
				"forge", "boulangerie", "atelier":
					p["mur"] = ["braise/brique_noire.png", Color(0.85, 0.78, 0.76), 2.2]
					p["sol"] = ["braise/basalte.png", Color(0.7, 0.66, 0.64), 1.8]
				"apothicaire":
					p["mur"] = ["braise/enduit_rouge.png", Color(0.7, 0.6, 0.85), 2.5]
				"couture":
					p["sol"] = ["maisons/parquet_chevron.png", Color(0.6, 0.45, 0.42), 2.4]
					p["mur"] = ["maisons/pp_damas_bordeaux.png", Color(0.95, 0.82, 0.86), 1.6]
					p["bas"] = ["maisons/lambris_sombre.png", Color(0.7, 0.62, 0.62), 1.4]
				"barbier":
					p["sol"] = ["maisons/damier_noir_blanc.png", Color(0.8, 0.74, 0.74), 1.0]
					p["mur"] = ["maisons/pp_rayures_rose.png", Color(1.0, 0.62, 0.62), 1.8]
					p["bas"] = ["maisons/lambris_sombre.png", Color(0.75, 0.66, 0.66), 1.4]
				"capitainerie":
					p["sol"] = ["braise/bois_brule.png", Color(0.82, 0.7, 0.64), 1.8]
				"poissonnerie":
					p["sol"] = ["maisons/carreaux_ciment_bleu.png", Color(0.75, 0.72, 0.78), 1.6]
					p["bas"] = ["maisons/lambris_blanc.png", Color(0.8, 0.78, 0.8), 1.4]
				"caserne":
					p["mur"] = ["braise/basalte.png", Color(0.75, 0.7, 0.7), 2.0]
					p["fenetre"] = "aucune"
		"montjoie":
			p["sol"] = ["montjoie/dalles.png", Color(0.88, 0.84, 0.78), 2.0]
			p["mur"] = ["montjoie/enduit.png", Color(0.98, 0.94, 0.84), 2.5]
			p["bas"] = ["montjoie/moellons.png", Color(0.8, 0.76, 0.7), 1.4]
			p["colombage"] = true
			match met:
				"magie":
					p["sol"] = ["montjoie/dalles_donjon.png", Color(0.7, 0.66, 0.74), 2.0]
					p["mur"] = ["maisons/pp_damas_bleu.png", Color(0.72, 0.58, 0.95), 1.6]
					p["bas"] = ["maisons/lambris_sombre.png", Color(0.75, 0.68, 0.8), 1.4]
					p["colombage"] = false
				"couture":
					p["sol"] = ["montjoie/bois_planches.png", Color(0.9, 0.78, 0.64), 1.8]
					p["mur"] = ["maisons/pp_fleurs_creme.png", Color(1, 1, 1), 1.8]
					p["bas"] = ["maisons/lambris_miel.png", Color(1, 1, 1), 1.4]
					p["colombage"] = false
				"caserne":
					p["sol"] = ["montjoie/dalles_donjon.png", Color(0.75, 0.72, 0.68), 2.0]
					p["mur"] = ["montjoie/moellons.png", Color(0.9, 0.86, 0.8), 1.8]
					p["colombage"] = false
		"cliquetis":
			p["sol"] = ["azur/planches.png", Color(0.75, 0.6, 0.45), 2.0]
			p["mur"] = ["cliquetis/brique.png", Color(1, 0.95, 0.9), 2.5]
			p["bas"] = ["maisons/lambris_sombre.png", Color(0.95, 0.9, 0.85), 1.4]
			p["plafond"] = ["montjoie/bois_planches.png", Color(0.42, 0.34, 0.28), 2.0]
			p["tuyaux"] = true
			match met:
				"academie":
					p["sol"] = ["maisons/parquet_chevron.png", Color(0.9, 0.8, 0.7), 2.6]
					p["mur"] = ["maisons/chaux_vert.png", Color(0.92, 0.96, 0.9), 3.0]
				"cafe":
					p["sol"] = ["maisons/damier_noir_blanc.png", Color(0.9, 0.86, 0.8), 1.0]
				"bazar":
					p["sol"] = ["maisons/parquet_chevron.png", Color(0.85, 0.74, 0.62), 2.4]
					p["mur"] = ["maisons/pp_damas_bleu.png", Color(0.95, 0.98, 1.0), 1.6]
				"atelier":
					p["sol"] = ["cliquetis/ardoise.png", Color(0.7, 0.7, 0.72), 2.0]
					p["mur"] = ["cliquetis/brique.png", Color(0.8, 0.72, 0.68), 2.5]
				"labo":
					p["sol"] = ["maisons/damier_noir_blanc.png", Color(0.95, 0.95, 0.95), 1.0]
					p["mur"] = ["maisons/lambris_blanc.png", Color(0.95, 0.97, 1.0), 1.6]
					p["bas"] = ["maisons/carreaux_ciment_bleu.png", Color(1, 1, 1), 1.2]
				"observatoire":
					p["sol"] = ["maisons/parquet_chevron.png", Color(0.6, 0.5, 0.44), 2.4]
					p["mur"] = ["maisons/pp_damas_bleu.png", Color(0.42, 0.46, 0.7), 1.6]
					p["plafond"] = ["maisons/chaux_bleu.png", Color(0.12, 0.14, 0.3), 3.0]
					p["fenetre"] = "aucune"
					p["sans_poutres"] = true
				"fabrique":
					p["sol"] = ["beau160/metal_patine.png", Color(0.75, 0.72, 0.68), 2.0]
	return p


# =================================================================== construire

static func build(M) -> void:
	var met: String = str(M.cur.get("metier", ""))
	M.ctx["metier"] = met
	M.ctx["anims170"] = []
	M.ctx["tick"] = func(delta: float) -> void:
		_tick(M, delta)
	match met:
		"bazar":
			_bazar(M)
		"banque":
			_banque(M)
		"forge":
			_forge(M)
		"poste":
			_poste(M)
		"hotel":
			_hotel(M)
		"epicerie", "epices":
			_epicerie(M)
		"apothicaire":
			_apothicaire(M)
		"sherif", "caserne":
			_sherif(M)
		"prospecteurs":
			_prospecteurs(M)
		"chapelier", "couture":
			_chapelier(M)
		"sellerie":
			_sellerie(M)
		"ecurie":
			_ecurie(M)
		"horloger":
			_horloger(M)
		"theatre":
			_theatre(M)
		"gare":
			_gare(M)
		"capitainerie", "location":
			_capitainerie(M)
		"restaurant", "cafe":
			_cafe(M)
		"bijouterie":
			_bijouterie(M)
		"boulangerie":
			_boulangerie(M)
		"libraire":
			_libraire(M)
		"magie":
			_magie(M)
		"barbier":
			_barbier(M)
		"atelier", "fabrique":
			_atelier(M)
		"poissonnerie":
			_poissonnerie(M)
		"academie":
			_academie(M)
		"labo":
			_labo(M)
		"observatoire":
			_observatoire(M)
		_:
			var L: Variant = _lieu(met)
			if L != null:
				L.build(M)
	if str(M.cur.get("style", "")) == "braise":
		_lampe(M, 0.0, M.R.H - 0.8, 0.4, Color(1.0, 0.72, 0.5), 0.9, maxf(M.R.W, M.R.D) * 1.1)
	_accueil(M)


## Ce qui bouge (les rouages, les balanciers, les ailes du ventilateur) ; le marchand d'ici cesse de
## nous regarder quand la conversation (avec la vraie personne) est finie.
static func _tick(M, delta: float) -> void:
	var t: float = float(M.ctx.get("t170", 0.0)) + delta
	M.ctx["t170"] = t
	for a in M.ctx.get("anims170", []):
		var n: Node3D = a[0]
		if not is_instance_valid(n):
			continue
		match str(a[1]):
			"tourne":
				n.rotate_object_local(a[2], float(a[3]) * delta)
			"balance":
				n.rotation.z = float(a[2]) * sin(t * float(a[3]))
			"flotte":
				n.position.y = float(a[3]) + float(a[2]) * sin(t * 1.3 + float(a[4]))
	var f: Variant = M.ctx.get("marchand", null)
	if bool(M.ctx.get("parle170", false)) and (M.main.dialogue_v31 == null or not M.main.dialogue_v31.opened):
		M.ctx["parle170"] = false
		if f != null and is_instance_valid(f):
			f.end_talk()
		if M._talk_with == f:
			M._talk_with = null
	var tk: Variant = M.ctx.get("tick170", null)
	if tk is Callable and (tk as Callable).is_valid():
		(tk as Callable).call(delta)


## En entrant : la clochette de la porte, le bonjour du marchand ; la première fois, ce qu'on voit.
static func _accueil(M) -> void:
	var entree: String = str(M.ctx.get("entree", ""))
	M.ctx["entree"] = ""
	var cloche: bool = bool(M.ctx.get("cloche170", true))
	M.ctx["on_enter"] = func(first: bool) -> void:
		if cloche:
			M.main.sfx("cloche")
		if first and entree != "":
			M.say(entree, 7.0)
		await M.get_tree().create_timer(0.8).timeout
		var f: Variant = M.ctx.get("marchand", null)
		if not M.inside or f == null or not is_instance_valid(f):
			return
		var b: Array = M.ctx.get("bonjour170", [])
		if b.is_empty():
			return
		var t: String = str(b[_r(M).randi() % b.size()])
		if not M.R.day:
			# V173 : un lieu peut avoir son bonjour du soir (les fantômes de la Citadelle ne ferment jamais)
			var bn: Array = M.ctx.get("bonjour_nuit170", [])
			t = str(_pick(M, bn if not bn.is_empty() else ["Oh ! Je m'apprêtais à fermer… Entre, entre, puisque tu es là.", "Il est tard ! Mais pour toi, c'est encore ouvert.", "Chut, la boutique dort… Bon, d'accord, entre."]))
		elif not first:
			t = str(_pick(M, ["Re-bonjour ! Tu reviens nous voir ?", "Te revoilà ! Ça fait plaisir.", "Ah, un habitué !"]))
		f.say(t, 3.5)


# =================================================================== les petites aides

static func _r(M) -> RandomNumberGenerator:
	return M.ctx["rng"]


static func _pick(M, a: Array) -> Variant:
	return a[_r(M).randi() % a.size()]


static func T3(x: float, y: float, z: float, yaw: float = 0.0) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, deg_to_rad(yaw)), Vector3(x, y, z))


## Un matériau de couleur (mis en cache dans la pièce) ; emit : il brille un peu.
static func _c(R, key: String, c: Color, rough: float = 0.7, metal: float = 0.0, emit: float = 0.0) -> String:
	if R.mat(key) == null:
		var m: StandardMaterial3D = R._col(c, rough, metal)
		if emit > 0.0:
			m.emission_enabled = true
			m.emission = c
			m.emission_energy_multiplier = emit
		R._put(key, m)
	return key


## Un verre teinté (les bocaux, les fioles, les vitrines).
static func _verre(R, key: String, c: Color, a: float = 0.45, emit: float = 0.0) -> String:
	if R.mat(key) == null:
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(c.r, c.g, c.b, a)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.roughness = 0.05
		m.metallic = 0.1
		m.metallic_specular = 0.8
		if emit > 0.0:
			m.emission_enabled = true
			m.emission = c
			m.emission_energy_multiplier = emit
		R._put(key, m)
	return key


## Une image (une affiche, une carte, un tableau) : la clé du matériau.
static func _img(R, key: String, path: String, alpha: int = 0) -> String:
	return Sud._img(R, key, path, alpha)


## Une image au mur, dans son cadre (yaw : 0 au fond, 90 à gauche, -90 à droite).
static func _cadre(R, key: String, x: float, y: float, z: float, yaw: float, w: float, h: float, cadre: String = "bois_sombre") -> void:
	Sud._cadre(R, key, x, y, z, yaw, w, h, cadre)


## Un morceau qui bouge (un nœud à part, pas fondu dans la pièce).
static func _piece(M, mesh: Mesh, m: Material, at: Vector3, basis: Basis = Basis()) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = m
	M.room.add_child(mi)
	mi.global_transform = Transform3D(basis, at)
	return mi


static func _cylm(rt: float, rb: float, h: float, seg: int = 16) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = rt
	c.bottom_radius = rb
	c.height = h
	c.radial_segments = seg
	c.rings = 1
	return c


static func _boitem(sx: float, sy: float, sz: float) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = Vector3(sx, sy, sz)
	return b


## Une lumière (une lampe, une flamme) : x, y, z en repère de la pièce.
static func _lampe(M, x: float, y: float, z: float, c: Color, e: float, portee: float) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.light_color = c
	l.light_energy = e
	l.omni_range = portee
	l.omni_attenuation = 1.2
	l.shadow_enabled = false
	M.room.add_child(l)
	l.global_position = M.R.P(x, y, z)
	return l


## Un écriteau (Label3D) posé contre un mur : x, y, z, yaw comme un tableau.
static func _ecrit(M, x: float, y: float, z: float, yaw: float, t: String, taille: int = 56, c: Color = Color(1.0, 0.86, 0.5), px: float = 0.004, dz: float = 0.03) -> Label3D:
	var lb := Label3D.new()
	lb.text = t
	lb.font_size = taille
	lb.pixel_size = px
	lb.modulate = c
	lb.outline_size = 8
	lb.outline_modulate = Color(0.1, 0.06, 0.03, 0.8)
	lb.double_sided = false
	M.room.add_child(lb)
	lb.global_transform = M.R.L(x, y, z, yaw) * Transform3D(Basis(), Vector3(0, 0, dz))
	return lb


## Une enseigne au mur du fond : la planche, son cadre, le nom peint.
static func _enseigne(M, x: float, y: float, z: float, yaw: float, t: String, w: float = 2.6, fond: String = "bois_sombre", c: Color = Color(1.0, 0.84, 0.42)) -> void:
	var R = M.R
	var lines: int = t.count("\n") + 1
	var h: float = 0.32 + 0.22 * lines
	R.kit.box(R.L(x, y, z, yaw) * T3(0, 0, 0.04), Vector3(w, h, 0.04), fond, 1.0)
	R.kit.box(R.L(x, y, z, yaw) * T3(0, 0, 0.025), Vector3(w + 0.1, h + 0.1, 0.03), "or", 1.0)
	R.mark_wall(x, y, z, w * 0.5 + 0.1)
	var taille: int = 72 if t.length() < 22 else 56
	_ecrit(M, x, y, z, yaw, t, taille, c, minf(0.0045, (w - 0.3) / maxf(1.0, t.split("\n")[0].length() * taille * 0.55)), 0.075)


## Une enseigne peinte (l'image de la ville, celle de la façade) : key d'image, largeur, hauteur.
static func _panneau(M, path: String, x: float, y: float, z: float, yaw: float, w: float, h: float) -> void:
	var R = M.R
	if not ResourceLoader.exists("res://assets/textures/" + path):
		return
	var key: String = _img(R, "ens_" + path.get_file().get_basename(), path)
	_cadre(R, key, x, y, z, yaw, w, h, "bois_sombre")


# =================================================================== les meubles et les marchandises

## Un comptoir (x, z : son milieu ; yaw 0 : le marchand au fond, le client devant) : le coffre de
## bois, ses panneaux moulurés côté client, le plateau, la plinthe ; vitre : le haut est une vitrine.
static func _comptoir(M, x: float, z: float, w: float, yaw: float = 0.0, vitre: bool = false, h: float = 1.0, bois: String = "bois_sombre", dessus: String = "bois") -> Transform3D:
	var R = M.R
	var k = R.kit
	var xf: Transform3D = R.L(x, 0, z, yaw)
	k.box(xf * T3(0, h * 0.5, 0), Vector3(w, h, 0.62), bois, 1.0)
	k.box(xf * T3(0, h + 0.03, 0.03), Vector3(w + 0.1, 0.06, 0.74), dessus, 1.0)
	k.box(xf * T3(0, 0.05, 0.32), Vector3(w + 0.02, 0.1, 0.03), "bois_sombre", 1.0)
	var n: int = maxi(2, int(w / 0.75))
	for i in range(n):
		var px: float = -w * 0.5 + (i + 0.5) * w / n
		k.box(xf * T3(px, h * 0.52, 0.315), Vector3(w / n - 0.16, h * 0.56, 0.02), "bois", 1.0)
		k.box(xf * T3(px, h * 0.52, 0.322), Vector3(w / n - 0.26, h * 0.44, 0.012), bois, 1.0)
	if vitre:
		var vh: float = 0.34
		k.box(xf * T3(0, h + 0.06 + vh * 0.5, 0.03), Vector3(w - 0.06, vh, 0.6), _verre(R, "vitrine170", Color(0.85, 0.92, 0.95), 0.18), 1.0)
		for sx in [-1.0, 1.0]:
			k.box(xf * T3(sx * (w * 0.5 - 0.03), h + 0.06 + vh * 0.5, 0.03), Vector3(0.04, vh, 0.62), "or", 1.0)
		k.box(xf * T3(0, h + 0.07 + vh, 0.03), Vector3(w, 0.03, 0.64), "bois_sombre", 1.0)
	k.col_box(xf * T3(0, h * 0.5 + (0.2 if vitre else 0.0), 0), Vector3(w, h + (0.4 if vitre else 0.0), 0.62))
	if absf(fposmod(yaw, 180.0)) < 1.0:
		R.reserve(x, z, w + 0.3, 1.0)
	else:
		R.reserve(x, z, 1.0, w + 0.3)
	return xf


## Une caisse enregistreuse de laiton (sur le comptoir).
static func _caisse(R, xf: Transform3D) -> void:
	var k = R.kit
	k.box(xf * T3(0, 0.1, 0), Vector3(0.36, 0.2, 0.3), "or", 1.0)
	k.box(xf * Transform3D(Basis(Vector3.RIGHT, -0.5), Vector3(0, 0.24, 0.06)), Vector3(0.34, 0.14, 0.14), "or", 1.0)
	for i in range(3):
		for j in range(4):
			k.cyl(xf * T3(-0.12 + j * 0.08, 0.27 + i * 0.03, 0.03 + i * 0.045), 0.014, 0.014, 0.02, "ceramique", 6)
	k.box(xf * T3(0, 0.38, -0.08), Vector3(0.3, 0.12, 0.05), "or", 1.0)
	k.box(xf * T3(0, 0.39, -0.052), Vector3(0.22, 0.06, 0.005), "noir", 1.0)
	k.box(xf * T3(0.21, 0.16, 0), Vector3(0.03, 0.03, 0.18), "or", 1.0)


## Une balance de Roberval (deux plateaux de cuivre).
static func _balance(R, xf: Transform3D) -> void:
	var k = R.kit
	k.box(xf * T3(0, 0.04, 0), Vector3(0.42, 0.08, 0.18), "fer", 1.0)
	k.cyl(xf * T3(0, 0.08, 0), 0.025, 0.02, 0.1, "cuivre", 8)
	k.box(xf * T3(0, 0.19, 0), Vector3(0.4, 0.025, 0.04), "cuivre", 1.0)
	for sx in [-1.0, 1.0]:
		k.cyl(xf * T3(sx * 0.17, 0.2, 0), 0.1, 0.07, 0.03, "cuivre", 16)
	k.cyl(xf * T3(-0.17, 0.23, 0), 0.03, 0.03, 0.05, "fer", 8)


## Des bocaux de verre (un contenu de couleur, un couvercle), alignés le long de +x.
static func _bocaux(R, xf: Transform3D, n: int, pas: float = 0.16, r: float = 0.055, hb: float = 0.17, seed_c: int = 0) -> void:
	var k = R.kit
	var v: String = _verre(R, "bocal170", Color(0.9, 0.95, 0.95), 0.28)
	for i in range(n):
		var c: Color = TEINTES[(i + seed_c) % TEINTES.size()]
		var at: Transform3D = xf * T3(i * pas, 0, 0)
		k.cyl(at * T3(0, 0.005, 0), r * 0.9, r * 0.9, hb * 0.62, _c(R, "bocal_c%d" % ((i + seed_c) % TEINTES.size()), c, 0.5), 10)
		k.cyl(at, r, r, hb, v, 12)
		k.cyl(at * T3(0, hb, 0), r * 1.05, r * 1.05, 0.03, "cuivre" if (i + seed_c) % 3 == 0 else "bois", 12)


## Des fioles (de petites bouteilles colorées, un bouchon).
static func _fioles(R, xf: Transform3D, n: int, pas: float = 0.11, seed_c: int = 0, emit: float = 0.0) -> void:
	var k = R.kit
	for i in range(n):
		var c: Color = TEINTES[(i * 3 + seed_c) % TEINTES.size()]
		var key: String = _verre(R, "fiole_%d_%d" % [(i * 3 + seed_c) % TEINTES.size(), int(emit * 10)], c, 0.7, emit)
		var at: Transform3D = xf * T3(i * pas, 0, 0.02 * float(i % 2))
		var h: float = 0.12 + 0.04 * float((i + seed_c) % 3)
		k.cyl(at, 0.035, 0.04, h, key, 10)
		k.cyl(at * T3(0, h, 0), 0.04, 0.013, 0.04, key, 10, false)
		k.cyl(at * T3(0, h + 0.04, 0), 0.013, 0.013, 0.035, "bois_clair", 6)


## Des boîtes et des paquets (les conserves, le thé, les biscuits, les clous).
static func _boites(R, xf: Transform3D, n: int, pas: float = 0.15, seed_c: int = 0) -> void:
	var k = R.kit
	for i in range(n):
		var c: Color = TEINTES[(i * 5 + seed_c) % TEINTES.size()].lerp(Color(0.9, 0.86, 0.75), 0.35)
		var key: String = _c(R, "boite_%d" % ((i * 5 + seed_c) % TEINTES.size()), c, 0.6)
		if (i + seed_c) % 3 == 0:
			k.cyl(xf * T3(i * pas, 0, 0), 0.05, 0.05, 0.13, key, 12)
			k.cyl(xf * T3(i * pas, 0.13, 0), 0.05, 0.05, 0.01, "metal", 12)
		else:
			k.box(xf * T3(i * pas, 0.08, 0), Vector3(0.11, 0.16, 0.09), key, 1.0)
			k.box(xf * T3(i * pas, 0.09, 0.046), Vector3(0.08, 0.06, 0.002), "papier", 1.0)


## Des pains (boules, couronnes, baguettes dans leur panier).
static func _pains(R, xf: Transform3D, n: int, pas: float = 0.24) -> void:
	var k = R.kit
	_c(R, "croute", Color(0.72, 0.45, 0.2), 0.85)
	_c(R, "croute_doree", Color(0.86, 0.6, 0.28), 0.8)
	for i in range(n):
		var at: Transform3D = xf * T3(i * pas, 0, 0)
		match i % 3:
			0:
				k.cyl(at, 0.09, 0.1, 0.05, "croute", 12)
				k.cyl(at * T3(0, 0.05, 0), 0.1, 0.06, 0.05, "croute", 12)
				k.box(at * Transform3D(Basis(Vector3.UP, 0.6), Vector3(0, 0.1, 0)), Vector3(0.12, 0.012, 0.012), "croute_doree", 1.0)
			1:
				k.ring(at * T3(0, 0.03, 0), 0.04, 0.1, 0.06, "croute_doree", 14)
			_:
				for b in range(3):
					k.cyl(at * Transform3D(Basis(Vector3.BACK, PI * 0.5 - 0.15) * Basis(Vector3.RIGHT, 0.12 * (b - 1)), Vector3(-0.08 + b * 0.05, 0.12, -0.03 + b * 0.03)), 0.028, 0.03, 0.42, "croute_doree", 8)


## Des chapeaux (le bord, la calotte, un ruban) : sorte « stetson », « haut-de-forme », « pointu ».
static func _chapeau(R, xf: Transform3D, sorte: String, c: Color, ruban: Color) -> void:
	var k = R.kit
	var key: String = _c(R, "feutre_%s" % c.to_html(false), c, 0.85)
	var rb: String = _c(R, "ruban_%s" % ruban.to_html(false), ruban, 0.5)
	match sorte:
		"stetson":
			k.cyl(xf, 0.17, 0.17, 0.012, key, 18)
			k.cyl(xf * T3(0, 0.012, 0), 0.085, 0.075, 0.11, key, 14)
			k.cyl(xf * T3(0, 0.012, 0), 0.087, 0.087, 0.025, rb, 14, false)
		"haut":
			k.cyl(xf, 0.13, 0.13, 0.01, key, 18)
			k.cyl(xf * T3(0, 0.01, 0), 0.075, 0.08, 0.17, key, 14)
			k.cyl(xf * T3(0, 0.01, 0), 0.077, 0.077, 0.03, rb, 14, false)
		_:
			k.cyl(xf, 0.16, 0.16, 0.012, key, 18)
			k.cyl(xf * T3(0, 0.012, 0), 0.08, 0.0, 0.26, key, 14)
			k.cyl(xf * T3(0, 0.012, 0), 0.08, 0.075, 0.025, rb, 14, false)


## Des rouleaux de tissu (couchés sur une étagère, le long de +x).
static func _rouleaux(R, xf: Transform3D, n: int, long: float = 0.7, seed_c: int = 0) -> void:
	var k = R.kit
	var cols: Array = [Color(0.6, 0.12, 0.15), Color(0.18, 0.3, 0.55), Color(0.85, 0.75, 0.45), Color(0.25, 0.45, 0.3),
		Color(0.55, 0.32, 0.55), Color(0.9, 0.88, 0.82), Color(0.15, 0.15, 0.18), Color(0.8, 0.45, 0.25)]
	for i in range(n):
		var key: String = _c(R,"rouleau_%d" % ((i + seed_c) % cols.size()), cols[(i + seed_c) % cols.size()], 0.95)
		k.cyl(xf * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(0, 0.075, i * 0.16)), 0.075, 0.075, long, key, 12)
		k.cyl(xf * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(-0.02, 0.075, i * 0.16)), 0.018, 0.018, long + 0.04, "carton", 6)


## Une étagère murale pleine (sorte : « bocaux », « fioles », « boites », « pains », « chapeaux »,
## « tissus », « livres », « pots », « horloges »…) : x, z, yaw comme R.etagere.
static func _rayons(M, x: float, z: float, yaw: float, w: float, h: float, rows: int, sorte: String, seed_c: int = 0) -> void:
	var R = M.R
	R.etagere(x, z, yaw, w, h, sorte == "livres", rows)
	if sorte == "livres":
		return
	var xf: Transform3D = R.L(x, 0, z, yaw)
	for i in range(rows):
		var y: float = 0.08 + (h - 0.12) * float(i) / rows + 0.016
		var row: Transform3D = xf * T3(-w * 0.5 + 0.1, y, 0.0)
		var s: String = sorte
		if sorte == "mixte":
			s = ["bocaux", "boites", "fioles", "pots"][(i + seed_c) % 4]
		match s:
			"bocaux":
				_bocaux(R, row, int((w - 0.15) / 0.16), 0.16, 0.055, minf(0.17, (h - 0.12) / rows - 0.08), seed_c + i * 2)
			"fioles":
				_fioles(R, row, int((w - 0.12) / 0.11), 0.11, seed_c + i, float(M.ctx.get("fiole_emit", 0.0)))
			"boites":
				_boites(R, row, int((w - 0.12) / 0.15), 0.15, seed_c + i)
			"pains":
				_pains(R, row * T3(0.05, 0, 0), int((w - 0.12) / 0.24), 0.24)
			"chapeaux":
				var nc: int = int((w - 0.05) / 0.36)
				for j in range(nc):
					_chapeau(R, row * T3(0.12 + j * 0.36, 0.0, 0.0), ["stetson", "haut", "pointu"][(j + i + seed_c) % 3],
						[Color(0.42, 0.28, 0.18), Color(0.12, 0.1, 0.1), Color(0.55, 0.12, 0.14), Color(0.25, 0.3, 0.42), Color(0.72, 0.62, 0.45)][(j * 2 + i + seed_c) % 5],
						[Color(0.75, 0.6, 0.25), Color(0.6, 0.1, 0.1), Color(0.15, 0.15, 0.15)][(j + i) % 3])
			"tissus":
				_rouleaux(R, row * Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(w * 0.5 - 0.1, 0, 0.12)), 2, w - 0.15, seed_c + i * 2)
			"pots":
				for j2 in range(int((w - 0.12) / 0.15)):
					var rr: float = 0.045 + 0.015 * float((j2 + i) % 3)
					R.kit.cyl(row * T3(j2 * 0.15, 0, 0), rr, rr * 1.15, 0.12 + 0.03 * float(j2 % 2), "terre_cuite" if (j2 + i) % 2 == 0 else "ceramique", 10)
			"outils":
				for j3 in range(int((w - 0.12) / 0.2)):
					R.kit.box(row * T3(j3 * 0.2, 0.04, 0), Vector3(0.16, 0.08, 0.12), "fer" if j3 % 2 == 0 else "cuivre", 1.0)
			"sacs":
				for j4 in range(int((w - 0.1) / 0.3)):
					R.kit.cyl(row * T3(0.05 + j4 * 0.3, 0, 0), 0.12, 0.1, 0.22, _toile(R), 10)
					R.kit.cyl(row * T3(0.05 + j4 * 0.3, 0.22, 0), 0.1, 0.04, 0.06, _toile(R), 10)
			"bijoux":
				for j5 in range(int((w - 0.1) / 0.18)):
					_ecrin(R, row * T3(j5 * 0.18, 0, 0), j5 + i + seed_c)


static func _toile(R) -> String:
	if R.mat("toile_sac") == null:
		R._put("toile_sac", R._texmat("beau161/toile_lin.png", Color(0.82, 0.7, 0.52), 0.95))
	return "toile_sac"


## Un sac de jute ouvert, plein (grain, épices, café, haricots) : couleur du contenu.
static func _sac(R, x: float, z: float, c: Color, s: float = 1.0) -> void:
	var k = R.kit
	var xf: Transform3D = R.L(x, 0, z, R.rng.randf_range(0, 360))
	k.cyl(xf, 0.24 * s, 0.22 * s, 0.5 * s, _toile(R), 12)
	k.ring(xf * T3(0, 0.5 * s, 0), 0.19 * s, 0.26 * s, 0.06 * s, _toile(R), 12)
	k.cyl(xf * T3(0, 0.44 * s, 0), 0.2 * s, 0.1 * s, 0.09 * s, _c(R, "grain_%s" % c.to_html(false), c, 0.95), 12)
	k.col_box(xf * T3(0, 0.25 * s, 0), Vector3(0.44, 0.5, 0.44) * s)
	R.reserve(x, z, 0.55 * s, 0.55 * s)


## Un écrin de velours ouvert (une bague, un collier de perles, une broche).
static func _ecrin(R, xf: Transform3D, i: int) -> void:
	var k = R.kit
	var vel: String = _c(R, "velours_ecrin", Color(0.32, 0.05, 0.1), 0.95)
	k.box(xf * T3(0, 0.025, 0), Vector3(0.13, 0.05, 0.1), vel, 1.0)
	k.box(xf * Transform3D(Basis(Vector3.RIGHT, -0.5), Vector3(0, 0.08, -0.06)), Vector3(0.13, 0.08, 0.012), vel, 1.0)
	match i % 3:
		0:
			k.ring(xf * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0.075, 0.0)), 0.018, 0.024, 0.008, "or", 14)
			k.cyl(xf * T3(0, 0.098, 0.0), 0.009, 0.004, 0.012, _verre(R, "gemme_rouge", Color(0.9, 0.1, 0.2), 0.85, 0.6), 6)
		1:
			for p in range(9):
				var a: float = PI * 0.15 + PI * 0.7 * p / 8.0
				k.cyl(xf * T3(cos(a) * 0.04, 0.05, -sin(a) * 0.03 + 0.012), 0.008, 0.008, 0.012, _c(R, "perle170", Color(0.96, 0.94, 0.9), 0.15, 0.2), 8)
		_:
			k.cyl(xf * T3(0, 0.05, 0), 0.022, 0.022, 0.008, "argent", 8)
			k.cyl(xf * T3(0, 0.058, 0), 0.012, 0.006, 0.01, _verre(R, "gemme_bleue", Color(0.15, 0.35, 0.95), 0.85, 0.6), 6)


## Une petite plante dans son pot (sur un meuble : y).
static func _plante(R, x: float, y: float, z: float, s: float = 1.0) -> void:
	R.plante(x, z, y, s)


## Des bouquets d'herbes qui sèchent, pendus à une perche sous le plafond (le long de +x).
static func _herbes(M, x0: float, x1: float, z: float) -> void:
	var R = M.R
	var k = R.kit
	var y: float = R.H - 0.45
	k.cyl(R.L((x0 + x1) * 0.5, y, z) * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3.ZERO), 0.025, 0.025, x1 - x0, "bois_sombre", 8)
	for sx in [x0, x1]:
		k.cyl(R.L(sx, y, z), 0.005, 0.005, R.H - y, "fer", 4, false)
	var cols: Array = [Color(0.32, 0.45, 0.2), Color(0.5, 0.48, 0.25), Color(0.45, 0.3, 0.42), Color(0.62, 0.55, 0.3), Color(0.28, 0.38, 0.22)]
	var n: int = int((x1 - x0) / 0.22)
	for i in range(n):
		var bx: float = x0 + 0.11 + i * 0.22
		var l: float = 0.25 + 0.08 * float(i % 3)
		k.cyl(R.L(bx, y - 0.04, z), 0.004, 0.004, 0.04, "fer", 3, false)
		var hk: String = _c(R, "herbe_%d" % (i % cols.size()), cols[i % cols.size()], 0.95)
		k.cyl(R.L(bx, y - 0.04 - l, z), 0.05, 0.014, l, hk, 9)
		k.cyl(R.L(bx + 0.02, y - 0.06 - l * 0.8, z + 0.015), 0.035, 0.01, l * 0.75, hk, 7)
		k.cyl(R.L(bx, y - 0.075, z), 0.017, 0.017, 0.03, "carton", 6)


## Le marchand (ou la personne qui tient l'endroit) : la vraie personne de la ville si elle existe
## (son visage, sa tenue ; on lui parle comme dehors), sinon un habitant de la ville (role, nom).
## menu : ce que propose le menu de secours (vend, achete, services, infos, bonjour).
static func _marchand(M, x: float, z: float, yaw: float, pose: String, role: String, nom: String, lignes: Array, menu: Dictionary = {}) -> Node:
	var R = M.R
	var n: Node = _vrai(M, str(M.cur.get("proprio", "")))
	var f: Node = null
	if n != null:
		var p: Dictionary = (n.get("profile") as Dictionary).duplicate(true)
		p["classe"] = _classe(n)
		f = Figurant.spawn(M.room, M.main, p, R.P(x, 0, z), Basis(Vector3.UP, deg_to_rad(yaw)) * Vector3(0, 0, 1), pose)
		M.people.append(f)
	else:
		f = M.person(role, x, z, yaw, pose, nom)
	f.lines = lignes
	M.ctx["marchand"] = f
	if not M.ctx.has("menu170"):
		M.ctx["menu170"] = menu
	M.talk_spot(f, func(): _parler(M, f, menu))
	return f


## Le corps d'une vraie personne pour sa copie (V172 : les gens de Ramure gardent leurs oreilles et leur queue).
static func _classe(n: Node) -> String:
	var scr: String = str((n.get_script() as Script).resource_path)
	if scr.contains("pirate"):
		return "pirate"
	if scr.contains("ramure"):
		return "ramure"
	# V173 : les gens de Montjoie (et de Port-Boucan, de Hautefond, de Pile-ou-Face : le même corps)
	# gardent leur chapeau et ce qu'ils tiennent à la main
	if scr.contains("montjoie") or scr.contains("boucan"):
		return "montjoie"
	return "lumen"


## La vraie personne (dans la ville) : son nœud, s'il est là.
static func _vrai(M, id: String) -> Node:
	if id == "":
		return null
	var all: Variant = M.main.get("npcs_v31")
	if not (all is Array):
		return null
	for n in all:
		if is_instance_valid(n) and n.is_inside_tree() and n.get("profile") is Dictionary and str((n.get("profile") as Dictionary).get("id", "")) == id and n.get("brain") != null:
			return n
	return null


## Parler au marchand : avec la vraie personne, la vraie conversation (sa boutique, ses histoires) ; le
## portrait et le panneau (en VR) regardent le marchand d'ici. Sinon, le menu de la boutique.
static func _parler(M, f: Node, menu: Dictionary) -> void:
	var n: Node = _vrai(M, str(M.cur.get("proprio", "")))
	var dlg: Node = M.main.get("dialogue_v31")
	if n != null and dlg != null and not bool(dlg.get("opened")) and M.main.has_method("_talk_v31"):
		if M._talk_with != null and is_instance_valid(M._talk_with) and M._talk_with != f:
			M._talk_with.end_talk()
		M._talk_with = f
		f.begin_talk()
		M.main._talk_v31(n)
		if bool(dlg.get("opened")):
			dlg.open(f.npc)
			M.ctx["parle170"] = true
			var hero: Variant = M.main.get("hero_v28")
			if hero != null and not bool(M.main.get("xr_active")):
				var to: Vector3 = f.npc.global_position - M.main.pc_root.global_position
				to.y = 0.0
				if to.length() > 0.05:
					hero.facing = to.normalized()
		return
	_menu(M, f, menu, "")


static func _nom(id: String) -> String:
	return str((Inv.ITEMS.get(id, {}) as Dictionary).get("name", id))


static func _sans_alcool(id: String) -> bool:
	for a in ALCOOL:
		if id.begins_with(a) or id.contains("_" + a):
			return false
	return true


static func _prix(M, base: int) -> int:
	return S.Pop120.prix(base, S.Pop120.region_maison(M.cur))


## Le menu de la boutique (quand la vraie personne n'est pas là) : acheter, vendre, ses services, ce
## qu'elle raconte.
static func _menu(M, f: Node, data: Dictionary, msg: String) -> void:
	var inv: Node = M.main.get("inventory_v28")
	var coins: int = int(inv.count("piece")) if inv != null else 0
	var ch: Array = []
	var vend: Dictionary = data.get("vend", {})
	for id in vend:
		if Inv.ITEMS.has(str(id)) and _sans_alcool(str(id)):
			ch.append({"id": "b:" + str(id), "label": "Acheter : %s — %d pièces" % [_nom(str(id)), _prix(M, int(vend[id]))]})
	var ach: Dictionary = data.get("achete", {})
	for id2 in ach:
		if inv != null and Inv.ITEMS.has(str(id2)) and int(inv.count(str(id2))) > 0:
			ch.append({"id": "v:" + str(id2), "label": "Vendre : %s — %d pièces (tu en as %d)" % [_nom(str(id2)), int(ach[id2]), int(inv.count(str(id2)))]})
	var sv: Array = data.get("services", [])
	for i in range(sv.size()):
		ch.append({"id": "s:%d" % i, "label": str((sv[i] as Dictionary)["label"])})
	if not (data.get("infos", []) as Array).is_empty():
		ch.append({"id": "info", "label": "Parle-moi un peu de cet endroit."})
	ch.append({"id": "fermer", "label": "Au revoir !"})
	var t: String = msg
	if t == "":
		t = str(data.get("bonjour", "Bonjour ! Que puis-je pour toi ?"))
		if not vend.is_empty():
			t += " Tu as %d pièce%s." % [coins, "s" if coins > 1 else ""]
	var cb := func(id) -> void:
		_choix(M, f, data, str(id))
	M.talk(f, t, ch, cb)


static func _choix(M, f: Node, data: Dictionary, id: String) -> void:
	var inv: Node = M.main.get("inventory_v28")
	var st: Dictionary = M.state()
	if id.begins_with("b:"):
		var it: String = id.substr(2)
		var p: int = _prix(M, int((data["vend"] as Dictionary)[it]))
		if inv == null or int(inv.count("piece")) < p:
			var manque: int = p - (int(inv.count("piece")) if inv != null else 0)
			_menu(M, f, data, "Il te manque %d pièce%s. Reviens quand ta bourse sera plus ronde !" % [manque, "s" if manque > 1 else ""])
			return
		inv.remove("piece", p)
		M.main.sfx("obole")
		M.give([[it, 1]], "")
		f.gesture("salut", 1.5)
		st["ventes170"] = int(st.get("ventes170", 0)) + 1
		_menu(M, f, data, str(_pick(M, ["Merci ! Bon usage !", "Et voilà ! Prends-en soin.", "Merci bien ! Reviens quand tu veux.", "Excellent choix, vraiment."])))
	elif id.begins_with("v:"):
		var it2: String = id.substr(2)
		if inv == null or int(inv.count(it2)) <= 0:
			_menu(M, f, data, "")
			return
		var pv: int = int((data["achete"] as Dictionary)[it2])
		inv.remove(it2, 1)
		M.give([["piece", pv]], "")
		_menu(M, f, data, "Marché conclu ! %d pièce%s pour toi." % [pv, "s" if pv > 1 else ""])
	elif id.begins_with("s:"):
		var sv: Dictionary = (data["services"] as Array)[int(id.substr(2))]
		(sv["cb"] as Callable).call()
	elif id == "info":
		var infos: Array = data["infos"]
		var k: int = int(st.get("info170", 0))
		st["info170"] = k + 1
		_menu(M, f, data, str(infos[k % infos.size()]))
	else:
		M.close_talk()


## Des clients (des habitants de la ville) : [role, x, z, yaw, pose, lignes].
static func _clients(M, liste: Array) -> void:
	for c in liste:
		var p: Node = M.person(str(c[0]), float(c[1]), float(c[2]), float(c[3]), str(c[4]))
		p.lines = c[5] if c.size() > 5 else []


## Une habituée (la vraie personne de la ville, si elle existe) : on lui parle comme dehors.
static func _habitue(M, id: String, x: float, z: float, yaw: float, pose: String, lignes: Array = []) -> Node:
	var n: Node = _vrai(M, id)
	if n == null:
		return null
	var p: Dictionary = (n.get("profile") as Dictionary).duplicate(true)
	p["classe"] = _classe(n)
	var f: Node = Figurant.spawn(M.room, M.main, p, M.R.P(x, 0, z), Basis(Vector3.UP, deg_to_rad(yaw)) * Vector3(0, 0, 1), pose)
	M.people.append(f)
	f.lines = lignes
	var cb := func() -> void:
		var dlg: Node = M.main.get("dialogue_v31")
		var n2: Node = _vrai(M, id)
		if n2 == null or dlg == null or bool(dlg.get("opened")):
			return
		if M._talk_with != null and is_instance_valid(M._talk_with) and M._talk_with != f:
			M._talk_with.end_talk()
		M._talk_with = f
		f.begin_talk()
		M.main._talk_v31(n2)
		if bool(dlg.get("opened")):
			dlg.open(f.npc)
			M.ctx["parle170"] = true
			M.ctx["marchand"] = f
	M.talk_spot(f, cb)
	return f


## Un matériau d'image qui se répète (la corde, le foin, le cuir…).
static func _tex(R, key: String, path: String, tint: Color = Color(1, 1, 1), rough: float = 0.9) -> String:
	if R.mat(key) == null:
		R._put(key, R._texmat(path, tint, rough))
	return key


## Un engrenage qui tourne (at : son centre, basis : son axe est le Y de basis).
static func _engrenage(M, at: Vector3, basis: Basis, r: float, n: int, ep: float, vitesse: float, m: Material) -> Node3D:
	var g := Node3D.new()
	M.room.add_child(g)
	g.global_transform = Transform3D(basis, at)
	var d := MeshInstance3D.new()
	d.mesh = _cylm(r, r, ep, maxi(16, n * 2))
	d.material_override = m
	g.add_child(d)
	var hub := MeshInstance3D.new()
	hub.mesh = _cylm(r * 0.22, r * 0.22, ep * 1.8, 12)
	hub.material_override = m
	g.add_child(hub)
	var tb: BoxMesh = _boitem(r * 0.2, ep, r * 0.24)
	for i in range(n):
		var a: float = TAU * i / n
		var t := MeshInstance3D.new()
		t.mesh = tb
		t.material_override = m
		t.position = Vector3(cos(a) * r * 1.05, 0, sin(a) * r * 1.05)
		t.rotation.y = -a
		g.add_child(t)
	(M.ctx["anims170"] as Array).append([g, "tourne", Vector3.UP, vitesse])
	return g


## Une lanterne pendue (au plafond, ou à une perche) : x, z ; allumée ou non.
static func _lanterne(M, x: float, z: float, y: float = -1.0, allume: bool = true) -> void:
	var R = M.R
	var k = R.kit
	var ly: float = y if y > 0.0 else R.H - 0.75
	k.cyl(R.L(x, ly + 0.32, z), 0.006, 0.006, R.H - ly - 0.32, "fer", 4, false)
	k.box(R.L(x, ly + 0.27, z), Vector3(0.2, 0.025, 0.2), "fer", 1.0)
	k.box(R.L(x, ly, z), Vector3(0.2, 0.025, 0.2), "fer", 1.0)
	k.box(R.L(x, ly + 0.135, z), Vector3(0.16, 0.24, 0.16), _verre(R, "lanterne170", Color(1.0, 0.85, 0.55), 0.35, 1.2 if allume else 0.0), 1.0)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			k.box(R.L(x + sx * 0.09, ly + 0.135, z + sz * 0.09), Vector3(0.015, 0.27, 0.015), "fer", 1.0)
	k.cyl(R.L(x, ly + 0.3, z), 0.08, 0.02, 0.08, "fer", 8)
	if allume:
		k.cyl(R.L(x, ly + 0.04, z), 0.015, 0.015, 0.06, "ceramique", 6)
		k.cyl(R.L(x, ly + 0.1, z), 0.012, 0.0, 0.04, "flamme", 5, false)


## Un guichet (x, z : son milieu ; n fenêtres) : le comptoir, la vitre, les barreaux de laiton, les
## ouvertures où l'on parle ; renvoie le repère du guichet.
static func _guichet(M, x: float, z: float, w: float, n: int, yaw: float = 0.0, barreaux: String = "or") -> Transform3D:
	var R = M.R
	var k = R.kit
	var G: Transform3D = _comptoir(M, x, z, w, yaw, false, 1.1)
	var top: float = minf(2.45, R.H - 0.35)
	var ph: float = top - 1.17
	k.box(G * T3(0, 1.17 + ph * 0.5, -0.12), Vector3(w, ph, 0.02), _verre(R, "vitre_guichet", Color(0.85, 0.9, 0.9), 0.15), 1.0)
	var nb: int = int(w / 0.12)
	for i in range(nb + 1):
		var bx: float = -w * 0.5 + i * w / nb
		var trou: bool = false
		for j in range(n):
			var ox: float = -w * 0.5 + (j + 0.5) * w / n
			if absf(bx - ox) < 0.26:
				trou = true
		k.cyl(G * T3(bx, 1.17 + (0.42 if trou else 0.0), -0.1), 0.008, 0.008, ph - (0.42 if trou else 0.0), barreaux, 6)
	for j2 in range(n):
		var ox2: float = -w * 0.5 + (j2 + 0.5) * w / n
		k.box(G * T3(ox2, 1.6, -0.1), Vector3(0.56, 0.03, 0.04), barreaux, 1.0)
		for sx in [-1.0, 1.0]:
			k.box(G * T3(ox2 + sx * 0.27, 1.38, -0.1), Vector3(0.03, 0.44, 0.04), barreaux, 1.0)
	k.box(G * T3(0, top + 0.04, -0.1), Vector3(w + 0.1, 0.08, 0.1), "bois_sombre", 1.0)
	k.box(G * T3(0, 1.17, -0.1), Vector3(w + 0.04, 0.03, 0.06), barreaux, 1.0)
	k.col_box(G * T3(0, (1.1 + top) * 0.5, -0.05), Vector3(w, top - 1.1, 0.12))
	return G


## Un lustre (une couronne de laiton et ses globes) et sa lumière.
static func _lustre(M, x: float, z: float, r: float = 0.45, e: float = 1.2) -> void:
	var R = M.R
	var k = R.kit
	var y: float = R.H - 0.9
	k.cyl(R.L(x, y + 0.2, z), 0.01, 0.01, R.H - y - 0.2, "or", 4, false)
	k.ring(R.L(x, y, z), r - 0.05, r, 0.05, "or", 24)
	k.cyl(R.L(x, y - 0.18, z), 0.03, 0.08, 0.38, "or", 10)
	var n: int = 6
	for i in range(n):
		var a: float = TAU * i / n
		k.cyl(R.L(x + cos(a) * r, y + 0.05, z + sin(a) * r), 0.035, 0.035, 0.05, "or", 8)
		k.cyl(R.L(x + cos(a) * r, y + 0.1, z + sin(a) * r), 0.06, 0.07, 0.13, _verre(R, "globe170", Color(1.0, 0.9, 0.7), 0.6, 1.4), 10)
	_lampe(M, x, y - 0.2, z, Color(1.0, 0.86, 0.62), e, maxf(R.W, R.D) * 0.9)


## Une horloge murale ronde (x, y, z, yaw ; rayon) ; balancier : une pendule (le balancier bat).
static func _horloge(M, x: float, y: float, z: float, yaw: float, rr: float, balancier: bool = false, cadre: String = "bois_sombre") -> void:
	var R = M.R
	var k = R.kit
	R.mark_wall(x, y, z, rr + 0.1)
	var H: Transform3D = R.L(x, y, z, yaw)
	k.cyl(H * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0, 0.03)), rr, rr, 0.03, "ceramique", 24)
	k.ring(H * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0, 0.0)), rr, rr + 0.05, 0.07, cadre, 24)
	for i in range(12):
		var a: float = TAU * i / 12.0
		k.box(H * Transform3D(Basis(Vector3.BACK, a), Vector3(sin(a) * rr * 0.84, cos(a) * rr * 0.84, 0.065)), Vector3(rr * 0.05, rr * 0.14, 0.006), "noir", 1.0)
	var h0: float = R.rng.randf() * TAU
	k.box(H * Transform3D(Basis(Vector3.BACK, h0), Vector3(-sin(h0) * rr * 0.25, cos(h0) * rr * 0.25, 0.07)), Vector3(rr * 0.07, rr * 0.5, 0.006), "noir", 1.0)
	var m0: float = R.rng.randf() * TAU
	k.box(H * Transform3D(Basis(Vector3.BACK, m0), Vector3(-sin(m0) * rr * 0.36, cos(m0) * rr * 0.36, 0.075)), Vector3(rr * 0.04, rr * 0.72, 0.006), "noir", 1.0)
	if balancier:
		var lb: float = rr * 2.2
		k.box(H * T3(0, -rr - lb * 0.5 - 0.02, 0.02), Vector3(rr * 1.1, lb + 0.1, 0.04), cadre, 1.0)
		var piv := Node3D.new()
		M.room.add_child(piv)
		piv.global_transform = H * T3(0, -rr - 0.05, 0.06)
		var tige := MeshInstance3D.new()
		tige.mesh = _boitem(0.015, lb * 0.8, 0.01)
		tige.material_override = R.mat("or")
		tige.position = Vector3(0, -lb * 0.4, 0)
		piv.add_child(tige)
		var disque := MeshInstance3D.new()
		disque.mesh = _cylm(rr * 0.28, rr * 0.28, 0.015, 18)
		disque.material_override = R.mat("or")
		disque.rotation.x = PI * 0.5
		disque.position = Vector3(0, -lb * 0.82, 0)
		piv.add_child(disque)
		(M.ctx["anims170"] as Array).append([piv, "balance", 0.22, 3.1 + R.rng.randf() * 0.6])


## Des chaises de spectateurs, des tables, etc. : une rangée de chaises (le long de x).
static func _rangee(R, x0: float, x1: float, z: float, yaw: float, pas: float = 0.62) -> void:
	var n: int = int((x1 - x0) / pas) + 1
	for i in range(n):
		R.chaise(x0 + i * pas, z, yaw)


# =================================================================== le bazar
## La Veuve Clou (Pile-ou-Face), les souvenirs de Victor (Port-Azur), le Bazar des Inutilités de
## Madame Bricolette (Cliquetis).

static func _bazar(M) -> void:
	var R = M.R
	var k = R.kit
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var st: String = str(M.cur.get("style", ""))
	var zc: float = -hd + 1.85
	for i in range(3):
		_rayons(M, -hw + 1.0 + i * 1.45, -hd + 0.22, 0.0, 1.35, 2.3, 5, ["mixte", "boites", "pots"][i], i * 3)
	_rayons(M, hw - 0.9, -hd + 0.22, 0.0, 1.35, 2.3, 5, "outils" if st == "perchee" else "mixte", 7)
	var cx: Transform3D = _comptoir(M, 0.9, zc, 3.0)
	_caisse(R, cx * T3(0.95, 1.06, 0.0))
	_balance(R, cx * T3(-0.95, 1.06, 0.05))
	_bocaux(R, cx * T3(-0.3, 1.06, 0.12), 3, 0.17, 0.07, 0.24, 2)
	_enseigne(M, 0.0, R.H - 0.55, -hd + 0.02, 0.0, str(M.cur.get("enseigne170", "")).to_upper(), 3.4)
	var lignes: Array = ["Tout se vend, tout s'achète !", "Il y a de tout. Même ce qu'on ne cherche pas.", "Ne touche pas à la pile du fond : elle tient par miracle."]
	var menu: Dictionary = {"vend": {"corde_chanvre": 4, "pelle": 8, "boussole": 10, "ressort": 2, "engrenage": 3}, "achete": {"boulon": 1, "vieille_botte": 1, "ressort": 1}}
	match st:
		"perchee":
			# des rouleaux de corde aux chevilles, des fers à cheval, les tonneaux de clous, les pelles
			var corde: String = _tex(R, "corde170", "beau161/corde.png", Color(0.9, 0.8, 0.62))
			for j in range(3):
				var cz: float = -hd + 2.6 + j * 0.9
				k.box(R.L(-hw + 0.06, 1.75, cz), Vector3(0.06, 0.06, 0.18), "bois_sombre", 1.0)
				k.ring(R.L(-hw + 0.14, 1.5, cz) * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3.ZERO), 0.12, 0.24, 0.07, corde, 18)
				R.mark_wall(-hw, 1.5, cz, 0.3)
			for j2 in range(5):
				k.ring(R.L(hw - 0.05, 1.3 + 0.18 * float(j2 % 2), -hd + 2.5 + j2 * 0.32, -90.0) * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 0.06, 0.085, 0.02, "fer", 12)
			R.mark_wall(hw, 1.4, -hd + 3.1, 0.9)
			for b in [[-hw + 0.6, hd - 1.4], [-hw + 1.3, hd - 1.0]]:
				R.tonneau(float(b[0]), float(b[1]))
				k.cyl(R.L(float(b[0]), 0.88, float(b[1])), 0.28, 0.24, 0.05, "fer", 12)
			for p in range(4):
				k.box(R.L(hw - 0.4 - p * 0.12, 0.75, hd - 1.2, -90.0) * Transform3D(Basis(Vector3.RIGHT, 0.22), Vector3.ZERO), Vector3(0.04, 1.4, 0.04), "bois", 1.0)
				k.box(R.L(hw - 0.4 - p * 0.12, 0.12, hd - 1.05, -90.0), Vector3(0.18, 0.24, 0.03), "fer", 1.0)
			R.reserve(hw - 0.55, hd - 1.15, 0.7, 0.6)
			for lx in [-hw + 1.5, hw - 1.8]:
				_lanterne(M, lx, 0.4)
			menu["bonjour"] = "Bienvenue au Bazar ! Clous, cordes, ressorts, boussoles."
		"azur":
			# le tourniquet de cartes postales, les cerfs-volants, les coquillages, les petits bateaux
			var tq := Node3D.new()
			M.room.add_child(tq)
			tq.global_position = R.P(-hw + 1.2, 0, hd - 2.0)
			var pole := MeshInstance3D.new()
			pole.mesh = _cylm(0.025, 0.025, 1.7, 8)
			pole.material_override = R.mat("metal")
			pole.position.y = 0.85
			tq.add_child(pole)
			var cp: String = _img(R, "cartes170", "beau170/cartes_postales.png")
			for f4 in range(4):
				var q := MeshInstance3D.new()
				var qm := QuadMesh.new()
				qm.size = Vector2(0.42, 0.9)
				q.mesh = qm
				q.material_override = R.mat(cp)
				q.rotation.y = f4 * PI * 0.5
				q.position = Vector3(sin(f4 * PI * 0.5) * 0.12, 1.15, cos(f4 * PI * 0.5) * 0.12)
				tq.add_child(q)
			k.cyl(R.L(-hw + 1.2, 0, hd - 2.0), 0.25, 0.25, 0.04, "metal", 14)
			k.col_box(R.L(-hw + 1.2, 0.8, hd - 2.0), Vector3(0.4, 1.6, 0.4))
			R.reserve(-hw + 1.2, hd - 2.0, 0.7, 0.7)
			(M.ctx["anims170"] as Array).append([tq, "tourne", Vector3.UP, 0.25])
			M.act(R.P(-hw + 1.2, 0, hd - 1.4), "E : faire tourner les cartes postales", func(): M.say(str(_pick(M, ["Le phare au soleil couchant. La plage des Sardines. « Bons baisers de Port-Azur ! » avec un chat en lunettes de soleil.", "Une carte avec Pépé Fernand et sa casquette, qui fait un clin d'œil. On l'a déjà vue quelque part…", "Le port, les bateaux, la mer bleue, bleue, bleue. Il n'y a rien de plus bleu que Port-Azur."])), 6.0), 1.0)
			var cols: Array = [Color(0.9, 0.2, 0.2), Color(0.95, 0.75, 0.15), Color(0.2, 0.55, 0.85), Color(0.25, 0.7, 0.4)]
			for c4 in range(4):
				var xf: Transform3D = R.L(-hw + 1.4 + c4 * 1.9, R.H - 0.75 - 0.15 * float(c4 % 2), hd - 2.8 + 0.5 * float(c4 % 2), 15.0 * (c4 - 1.5))
				k.quad(xf * Transform3D(Basis(Vector3.BACK, PI * 0.25), Vector3.ZERO), 0.5, 0.5, _c(R, "cv_%d" % c4, cols[c4], 0.7), Vector2(0, 0), Vector2(1, 1), true)
				k.box(xf, Vector3(0.7, 0.012, 0.012), "bois_clair", 1.0)
				k.box(xf, Vector3(0.012, 0.7, 0.012), "bois_clair", 1.0)
				for qq in range(4):
					k.box(xf * T3(0.04 * float(qq % 2), -0.42 - qq * 0.12, 0), Vector3(0.06, 0.03, 0.01), _c(R, "cv_%d" % ((c4 + qq + 1) % 4), cols[(c4 + qq + 1) % 4], 0.7), 1.0)
				k.cyl(xf * T3(0, 0.36, 0), 0.003, 0.003, R.H - (R.H - 0.75) , "fer", 3, false)
			for bk in range(2):
				var bx: float = hw - 1.0 - bk * 0.75
				k.cyl(R.L(bx, 0, hd - 1.3), 0.26, 0.3, 0.32, _tex(R, "osier170", "objets/osier.png"), 14)
				for s6 in range(7):
					k.cyl(R.L(bx - 0.15 + 0.05 * s6, 0.3, hd - 1.32 + 0.04 * float(s6 % 3)), 0.04, 0.0, 0.03, _c(R, "nacre", Color(0.98, 0.9, 0.88), 0.3, 0.1), 8)
				k.col_box(R.L(bx, 0.16, hd - 1.3), Vector3(0.6, 0.32, 0.6))
				R.reserve(bx, hd - 1.3, 0.7, 0.7)
			menu = {"vend": {"carte_postale": 2, "cerf_volant": 12, "coquillage": 6}, "achete": {"coquillage": 2}, "bonjour": "Bienvenue aux Souvenirs de Port-Azur !"}
			lignes = ["Une carte postale ? Deux pièces, et le bonheur en plus.", "Les cerfs-volants volent tout seuls. Enfin, avec du vent.", "Ce coquillage, on entend la mer dedans. Et parfois mon voisin."]
		"cliquetis":
			# les Inutilités : le parapluie à hélice, les tasses qui tournent, la boîte à rien
			for u in range(2):
				var ux: float = -hw + 1.6 + u * 2.6
				k.cyl(R.L(ux, R.H - 1.4, hd - 2.6), 0.01, 0.01, 1.4, "fer", 4, false)
				var hel: Node3D = Node3D.new()
				M.room.add_child(hel)
				hel.global_position = R.P(ux, R.H - 1.45, hd - 2.6)
				var dome := MeshInstance3D.new()
				dome.mesh = _cylm(0.02, 0.45, 0.22, 16)
				dome.material_override = R.mat(_c(R, "parapluie_%d" % u, [Color(0.75, 0.15, 0.2), Color(0.15, 0.4, 0.7)][u], 0.6))
				dome.position.y = -0.11
				hel.add_child(dome)
				var pale := MeshInstance3D.new()
				pale.mesh = _boitem(0.7, 0.01, 0.06)
				pale.material_override = R.mat("cuivre")
				pale.position.y = 0.04
				hel.add_child(pale)
				(M.ctx["anims170"] as Array).append([hel, "tourne", Vector3.UP, 2.5 + u])
			for t3 in range(3):
				var tasse := Node3D.new()
				M.room.add_child(tasse)
				tasse.global_transform = cx * T3(-0.2 + t3 * 0.18, 1.07, 0.18)
				var tm := MeshInstance3D.new()
				tm.mesh = _cylm(0.04, 0.03, 0.06, 12)
				tm.material_override = R.mat("ceramique")
				tm.position.y = 0.03
				tasse.add_child(tm)
				var anse := MeshInstance3D.new()
				anse.mesh = _boitem(0.02, 0.035, 0.012)
				anse.material_override = R.mat("ceramique")
				anse.position = Vector3(0.045, 0.035, 0)
				tasse.add_child(anse)
				(M.ctx["anims170"] as Array).append([tasse, "tourne", Vector3.UP, 1.5 + t3 * 0.7])
			# la boîte à rien, sur son socle
			k.cyl(R.L(-hw + 1.0, 0, hd - 1.6), 0.22, 0.25, 0.9, "bois_sombre", 12)
			k.box(R.L(-hw + 1.0, 1.0, hd - 1.6), Vector3(0.2, 0.18, 0.2), "or", 1.0)
			k.col_box(R.L(-hw + 1.0, 0.45, hd - 1.6), Vector3(0.5, 0.9, 0.5))
			R.reserve(-hw + 1.0, hd - 1.6, 0.6, 0.6)
			_ecrit(M, -hw + 1.0, 1.22, hd - 1.6 + 0.1, 0.0, "LA BOÎTE À RIEN\n(il n'y a rien dedans)", 28, Color(0.95, 0.85, 0.55), 0.0035)
			M.act(R.P(-hw + 1.0, 0, hd - 1.1), "E : ouvrir la boîte à rien", func(): M.say(str(_pick(M, ["Il n'y a rien dedans. C'est écrit dessus. Et pourtant, on est un peu déçu.", "Rien ! Absolument rien ! Un rien de première qualité, garanti sans quelque chose.", "Toujours rien. Madame Bricolette dit que c'est son article qui se vend le mieux."])), 5.0), 1.1)
			menu = {"vend": {"boite_a_rien": 8, "canard_mecanique": 15, "tasse_tourneuse": 14, "sifflet_muet": 6}, "achete": {"engrenage": 2, "ressort": 1}, "bonjour": "Bienvenue au Bazar des Inutilités ! Rien ne sert à rien, et tout est à vendre."}
			lignes = ["Cette tasse tourne toute seule. Le thé, lui, reste où il est.", "Un sifflet muet ! Idéal pour appeler les chiens qui dorment.", "Rien d'utile ici. C'est tout le charme."]
	var who: Array = ["femme", "Odile"] if st != "azur" else ["homme", "Victor"]
	_marchand(M, 0.9, zc - 0.55, 0.0, "comptoir", str(who[0]), str(who[1]), lignes, menu)
	_clients(M, [["vieux", -1.6, 0.6, 200.0, "observer", ["Hmm… celui-là, ou celui-là ?", "De mon temps, tout coûtait deux sous."]]])
	M.ctx["bonjour170"] = ["Bonjour ! Fais le tour, prends ton temps.", "Entre ! Il y a de tout, et même le reste.", "Bienvenue ! Regarde avec les yeux, achète avec les pièces."]
	M.ctx["entree"] = "%s : des étagères jusqu'au plafond, des boîtes, des bocaux, des choses dont on ignore le nom." % str(M.cur.get("enseigne170", "Le bazar"))


# =================================================================== la banque (Pile-ou-Face)

static func _banque(M) -> void:
	var R = M.R
	var k = R.kit
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var zg: float = -hd + 2.7
	_guichet(M, 0.0, zg, R.W - 2.6, 3)
	# derrière le guichet : le grand coffre rond, sa roue, ses boulons
	var cz: float = -hd + 0.12
	var V: Transform3D = R.L(0.0, 1.45, cz)
	var acier: String = _c(R, "acier170", Color(0.55, 0.56, 0.58), 0.35, 0.85)
	k.cyl(V * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0, 0.0)), 1.25, 1.25, 0.08, "fer", 32)
	k.cyl(V * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0, 0.08)), 1.1, 1.1, 0.22, acier, 32)
	for i in range(16):
		var a: float = TAU * i / 16.0
		k.cyl(V * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(cos(a) * 0.98, sin(a) * 0.98, 0.3)), 0.04, 0.04, 0.03, "or", 8)
	k.cyl(V * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0, 0.3)), 0.18, 0.18, 0.08, "or", 16)
	var roue := Node3D.new()
	M.room.add_child(roue)
	roue.global_transform = V * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0, 0.38))
	for s in range(3):
		var bar := MeshInstance3D.new()
		bar.mesh = _boitem(0.85, 0.05, 0.05)
		bar.material_override = R.mat("or")
		bar.rotation.y = s * PI / 3.0
		roue.add_child(bar)
	var rim := MeshInstance3D.new()
	rim.mesh = _cylm(0.06, 0.06, 0.06, 12)
	rim.material_override = R.mat("or")
	roue.add_child(rim)
	R.mark_wall(0.0, 1.45, cz, 1.35)
	R.reserve(0.0, -hd + 0.4, 2.8, 0.8)
	M.ctx["roue170"] = roue
	var voir := func() -> void:
		M.say(str(_pick(M, ["Le grand coffre de l'Écu Perché : un mètre de bon acier, seize boulons, et une roue qui pèse plus lourd que toi.", "Derrière cette porte, dit-on, il y a l'or de tout le ranch. Et la tarte aux figues de la Shérif, en lieu sûr.", "On raconte que personne n'a jamais ouvert ce coffre. Pas même le banquier : il a perdu la combinaison."])), 6.0)
		M.ctx["roue_t"] = 2.5
	M.act(R.P(0.0, 0, zg + 0.9), "E : regarder le grand coffre", voir, 1.4)
	# les bureaux derrière la grille : les registres, la lampe verte
	for bx in [-hw + 1.2, hw - 1.2]:
		R.table(bx, -hd + 1.3, 0.0, 1.2, 0.7)
		R.chaise(bx, -hd + 0.75, 0.0)
		k.box(R.L(bx - 0.25, 0.8, -hd + 1.3), Vector3(0.36, 0.06, 0.26), "cuir", 1.0)
		k.cyl(R.L(bx + 0.35, 0.78, -hd + 1.4), 0.07, 0.08, 0.02, "or", 10)
		k.cyl(R.L(bx + 0.35, 0.8, -hd + 1.4), 0.012, 0.012, 0.3, "or", 6)
		k.cyl(R.L(bx + 0.35, 1.08, -hd + 1.4), 0.12, 0.05, 0.1, _verre(R, "abat_vert", Color(0.1, 0.6, 0.3), 0.85, 0.8), 12)
	# le hall : le cordon de velours, les bancs, le lustre, l'horloge, le cours de l'or
	var vel: String = _c(R, "velours_rouge", Color(0.55, 0.05, 0.08), 0.9)
	for p in range(4):
		var px: float = -1.8 + p * 1.2
		k.cyl(R.L(px, 0, zg + 1.6), 0.12, 0.12, 0.04, "or", 12)
		k.cyl(R.L(px, 0, zg + 1.6), 0.025, 0.025, 0.95, "or", 8)
		k.cyl(R.L(px, 0.95, zg + 1.6), 0.04, 0.04, 0.05, "or", 8)
		if p < 3:
			k.cyl(R.L(px + 0.6, 0.86, zg + 1.6) * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3.ZERO), 0.022, 0.022, 1.1, vel, 8)
	k.col_box(R.L(0.0, 0.5, zg + 1.6), Vector3(3.6, 1.0, 0.1))
	R.reserve(0.0, zg + 1.6, 3.8, 0.4)
	R.banc(-hw + 0.5, hd - 2.2, 90.0, 1.6)
	R.banc(hw - 0.5, hd - 2.2, -90.0, 1.6)
	_lustre(M, 0.0, 0.6, 0.55, 1.4)
	_horloge(M, -hw + 0.04, 2.5, -hd + 3.6, 90.0, 0.32, false, "or")
	var co: String = _img(R, "cours170", "beau170/cours_or.png")
	_cadre(R, co, hw - 0.03, 1.9, hd - 3.3, -90.0, 1.0, 1.3, "or")
	_enseigne(M, 0.0, R.H - 0.45, -hd + 0.02, 0.0, "BANQUE DE L'ÉCU PERCHÉ", 4.0, "bois_sombre", Color(0.95, 0.8, 0.4))
	var tick := func(delta: float) -> void:
		var tr: float = float(M.ctx.get("roue_t", 0.0))
		if tr > 0.0:
			M.ctx["roue_t"] = tr - delta
			var rn: Variant = M.ctx.get("roue170", null)
			if rn != null and is_instance_valid(rn):
				(rn as Node3D).rotate_object_local(Vector3.UP, delta * 1.2 * signf(sin(tr * 2.0)))
	M.ctx["tick170"] = tick
	var menu := {"bonjour": "Bienvenue à la Banque de l'Écu Perché. Dépôts, retraits, et pépites pesées au gramme près.",
		"achete": {"pepite_or": 10, "piece_or": 12, "perle": 14, "rubis": 22},
		"services": [{"label": "Je voudrais ouvrir un compte.", "cb": func(): _menu(M, M.ctx["marchand"], M.ctx["menu170"], "Un compte ? Avec plaisir ! Le dépôt minimum est de… mille pièces. Revenez quand vous serez riche. Ou très, très patient.")}],
		"infos": ["La banque a été bâtie avec la première pépite du vieux Pépite. Il l'a déposée ici, et il vient la voir tous les dimanches.",
			"Le coffre ? Seize boulons, une roue, et une combinaison que je… que nous gardons secrète. Très secrète. Même pour nous, hélas.",
			"Ici, on pèse l'or, on compte les pièces, et on ne joue jamais. Pour jouer, c'est en face : au Tripot. Hélas."]}
	M.ctx["menu170"] = menu
	_marchand(M, 0.0, zg - 0.6, 0.0, "comptoir", "homme", "Monsieur Écu", ["Un dépôt ? Un retrait ? Une pépite à peser ?", "Silence, s'il vous plaît : on compte.", "La banque ne dort jamais. Moi, si."], menu)
	var commis: Node = M.person("femme", hw - 1.2, -hd + 0.75, 0.0, "lire", "Mademoiselle Liard")
	commis.lines = ["Mille deux cent trente-trois… mille deux cent trente-quatre…", "Ah zut, je recommence."]
	_clients(M, [["vieux", -1.2, zg + 2.3, 180.0, "debout", ["Je viens voir ma pépite. Elle va bien, merci."]], ["femme", 1.4, zg + 2.6, 190.0, "bras_croises", ["Ça n'avance pas, cette file…"]]])
	M.ctx["bonjour170"] = ["Bienvenue à l'Écu Perché.", "Entrez, entrez ! Faites la queue derrière le cordon."]
	M.ctx["entree"] = "La Banque de l'Écu Perché : le marbre, les guichets derrière leurs barreaux de laiton, et au fond, le grand coffre rond."


# =================================================================== la forge (Hilda Enclume, Hector, Kraxx)

static func _forge(M) -> void:
	var R = M.R
	var k = R.kit
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var st: String = str(M.cur.get("style", ""))
	# le foyer de la forge, au fond à gauche : le massif de briques, la hotte, les braises, le soufflet
	var fx: float = -hw + 1.3
	var fz: float = -hd + 1.0
	var mur: String = "brique"
	k.box(R.L(fx, 0.45, fz), Vector3(1.9, 0.9, 1.5), mur, 1.2)
	k.box(R.L(fx, 0.93, fz), Vector3(1.95, 0.06, 1.55), "fer", 1.0)
	k.box(R.L(fx, 0.97, fz + 0.1), Vector3(1.1, 0.06, 0.8), _c(R, "braises170", Color(1.0, 0.35, 0.08), 0.9, 0.0, 2.2), 1.0)
	for b in range(8):
		k.box(R.L(fx - 0.45 + 0.12 * b, 1.01, fz + 0.1 + 0.08 * float(b % 3) - 0.08), Vector3(0.1, 0.05, 0.1), _c(R, "charbon170", Color(0.06, 0.05, 0.05), 0.95), 1.0)
	R.fire(R.P(fx, 1.0, fz + 0.1), 0.8)
	k.box(R.L(fx, 1.9, fz - 0.1), Vector3(1.7, 0.7, 1.2), "fer", 1.0)
	k.box(R.L(fx, 2.25 + (R.H - 2.25) * 0.5, fz - 0.35), Vector3(0.6, R.H - 2.25, 0.6), "fer", 1.0)
	k.col_box(R.L(fx, 0.5, fz), Vector3(1.9, 1.0, 1.5))
	R.reserve(fx, fz, 2.2, 1.9)
	# le soufflet, à côté
	var sx0: float = fx + 1.35
	k.box(R.L(sx0, 0.75, fz + 0.2), Vector3(0.5, 0.12, 0.9), "bois", 1.0)
	k.box(R.L(sx0, 0.9, fz + 0.2) * Transform3D(Basis(Vector3.RIGHT, 0.15), Vector3.ZERO), Vector3(0.45, 0.2, 0.85), "cuir", 1.0)
	k.box(R.L(sx0, 0.4, fz + 0.2), Vector3(0.1, 0.8, 0.1), "bois_sombre", 1.0)
	R.reserve(sx0, fz + 0.2, 0.7, 1.0)
	# l'enclume sur sa souche, le baquet pour tremper, les pinces et les marteaux au mur
	var ax: float = -0.6
	var az: float = -hd + 2.7
	k.cyl(R.L(ax, 0, az), 0.3, 0.34, 0.55, _tex(R, "souche170", "beau164/ecorce_buche.png", Color(0.8, 0.7, 0.6)), 14)
	k.box(R.L(ax, 0.62, az), Vector3(0.22, 0.14, 0.3), "fer", 1.0)
	k.box(R.L(ax, 0.75, az), Vector3(0.62, 0.14, 0.28), "fer", 1.0)
	k.cyl(R.L(ax + 0.31, 0.75, az) * Transform3D(Basis(Vector3.BACK, -PI * 0.5), Vector3.ZERO), 0.07, 0.0, 0.3, "fer", 8)
	k.col_box(R.L(ax, 0.42, az), Vector3(0.7, 0.84, 0.6))
	R.reserve(ax, az, 1.6, 1.2)
	k.box(R.L(ax - 0.05, 0.84, az + 0.04, 30.0), Vector3(0.3, 0.03, 0.04), _c(R, "fer_rouge", Color(1.0, 0.4, 0.1), 0.6, 0.2, 2.5), 1.0)
	R.tonneau(ax - 1.0, az + 0.3)
	k.cyl(R.L(ax - 1.0, 0.82, az + 0.3), 0.29, 0.29, 0.02, _verre(R, "eau170", Color(0.2, 0.35, 0.4), 0.8), 14)
	for t in range(5):
		var tz: float = -hd + 2.3 + t * 0.25
		k.box(R.L(-hw + 0.05, 1.95, tz), Vector3(0.05, 0.05, 0.05), "fer", 1.0)
		k.box(R.L(-hw + 0.08, 1.6, tz), Vector3(0.03, 0.65, 0.04), "fer" if t % 2 == 0 else "bois_sombre", 1.0)
		k.box(R.L(-hw + 0.08, 1.28, tz), Vector3(0.06, 0.08, 0.12) if t % 2 == 1 else Vector3(0.04, 0.12, 0.05), "fer", 1.0)
	R.mark_wall(-hw, 1.6, -hd + 2.8, 0.8)
	# le râtelier : les épées, les haches, les boucliers ; ou les pelles et les fers (Pile-ou-Face)
	var rz: float = -hd + 2.2
	var rk: Transform3D = R.L(hw - 0.15, 0, rz, -90.0)
	k.box(rk * T3(0, 0.25, 0), Vector3(2.4, 0.08, 0.3), "bois_sombre", 1.0)
	k.box(rk * T3(0, 1.55, -0.05), Vector3(2.4, 0.08, 0.2), "bois_sombre", 1.0)
	for i in range(7):
		var ix: float = -1.05 + i * 0.35
		if st == "perchee" and i % 2 == 1:
			k.box(rk * Transform3D(Basis(Vector3.RIGHT, 0.12), Vector3(ix, 0.85, 0.02)), Vector3(0.04, 1.3, 0.04), "bois", 1.0)
			k.box(rk * T3(ix, 0.25, 0.08), Vector3(0.2, 0.26, 0.03), "fer", 1.0)
		elif i % 3 == 2:
			k.box(rk * Transform3D(Basis(Vector3.RIGHT, 0.1), Vector3(ix, 0.8, 0.03)), Vector3(0.04, 1.2, 0.04), "bois", 1.0)
			k.box(rk * T3(ix + 0.08, 1.3, 0.07), Vector3(0.18, 0.2, 0.03), "argent", 1.0)
		else:
			k.box(rk * Transform3D(Basis(Vector3.RIGHT, 0.08), Vector3(ix, 0.95, 0.02)), Vector3(0.06, 0.95, 0.012), "argent", 1.0)
			k.box(rk * T3(ix, 0.45, 0.0), Vector3(0.2, 0.03, 0.04), "or" if st == "braise" else "fer", 1.0)
			k.box(rk * T3(ix, 0.36, -0.01), Vector3(0.035, 0.16, 0.035), "cuir", 1.0)
	k.col_box(rk * T3(0, 0.8, 0), Vector3(2.4, 1.6, 0.4))
	R.reserve(hw - 0.3, rz, 0.7, 2.6)
	if st != "perchee":
		for s2 in range(3):
			var shx: float = hw - 0.04
			var shz: float = -hd + 3.9 + s2 * 0.75
			if shz > hd - 1.0:
				continue
			k.cyl(R.L(shx, 2.1, shz, -90.0) * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 0.3, 0.3, 0.04, ["bois", "tissu_rouge", "fer"][s2], 18)
			k.cyl(R.L(shx - 0.04, 2.1, shz, -90.0) * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 0.08, 0.06, 0.05, "or" if s2 != 2 else "argent", 12)
			R.mark_wall(shx, 2.1, shz, 0.35)
	else:
		for h4 in range(6):
			k.ring(R.L(hw - 0.05, 2.0 + 0.16 * float(h4 % 2), -hd + 3.6 + h4 * 0.3, -90.0) * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 0.06, 0.085, 0.02, "fer", 12)
		R.mark_wall(hw, 2.05, -hd + 4.3, 1.0)
	# le comptoir près de la porte : ce qui est à vendre, posé dessus
	var cx: Transform3D = _comptoir(M, hw - 2.2, hd - 2.4, 1.8, 0.0)
	k.box(cx * Transform3D(Basis(Vector3.UP, 0.3), Vector3(-0.3, 1.08, 0.05)), Vector3(0.75, 0.02, 0.06), "argent", 1.0)
	k.box(cx * T3(0.4, 1.12, 0.0), Vector3(0.2, 0.12, 0.3), "fer", 1.0)
	_lampe(M, fx, 1.4, fz + 0.6, Color(1.0, 0.5, 0.2), 1.6, 5.0)
	_lampe(M, 0.8, R.H - 0.9, 0.6, Color(1.0, 0.85, 0.65), 0.9, 9.0)
	var lignes: Array = ["Le fer, ça se travaille chaud. Comme l'amitié.", "Recule un peu : ça pique, les étincelles.", "Une bonne lame, c'est cent coups de marteau. Et un peu d'amour."]
	_marchand(M, ax + 0.75, az - 0.25, -100.0, "forger", "homme", "Gaspard", lignes, {"vend": {"pelle": 8, "hache": 14, "epee": 60, "canne_peche": 12}, "achete": {"minerai_fer": 3, "obsidienne": 4, "boulon": 1}})
	var tick := func(delta: float) -> void:
		var tt: float = float(M.ctx.get("marteau_t", 1.5)) - delta
		if tt <= 0.0:
			tt = _r(M).randf_range(1.4, 3.2)
			if not bool(M.ctx.get("parle170", false)) and (M.main.dialogue_v31 == null or not M.main.dialogue_v31.opened):
				M.main.sfx("forge_marteau", M.R.P(ax, 0.9, az), -10.0)
		M.ctx["marteau_t"] = tt
	M.ctx["tick170"] = tick
	M.ctx["cloche170"] = false
	M.ctx["bonjour170"] = ["Ah ! Entre, mais ne touche pas au fer rouge.", "Bienvenue à la forge ! Attention aux étincelles."]
	M.ctx["entree"] = "%s : la chaleur du foyer, l'odeur du charbon, le marteau qui sonne sur l'enclume." % str(M.cur.get("enseigne170", "La forge"))


# =================================================================== la poste (Pile-ou-Face, Nadine, Brindille)

static func _poste(M) -> void:
	var R = M.R
	var k = R.kit
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var st: String = str(M.cur.get("style", ""))
	var zg: float = -hd + 2.3
	var G: Transform3D = _guichet(M, 0.0, zg, R.W - 3.0, 2, 0.0, "or" if st != "braise" else "fer")
	_balance(R, G * T3(-1.6, 1.13, 0.12))
	k.box(G * T3(1.0, 1.15, 0.1), Vector3(0.08, 0.06, 0.08), "bois_sombre", 1.0)
	k.box(G * T3(1.12, 1.13, 0.12), Vector3(0.12, 0.02, 0.08), _c(R, "encre_tampon", Color(0.15, 0.1, 0.3), 0.9), 1.0)
	# les casiers du tri, au fond : les lettres, les paquets ficelés
	var cw: float = minf(4.2, R.W - 2.0)
	var ch: float = 1.9
	var C: Transform3D = R.L(0.0, 0.0, -hd + 0.22)
	k.box(C * T3(0, 0.45 + ch * 0.5, -0.15), Vector3(cw, ch, 0.02), "bois_sombre", 1.0)
	var nx: int = int(cw / 0.3)
	var ny: int = 7
	for i in range(nx + 1):
		k.box(C * T3(-cw * 0.5 + i * cw / nx, 0.45 + ch * 0.5, 0.0), Vector3(0.02, ch, 0.3), "bois", 1.0)
	for j in range(ny + 1):
		k.box(C * T3(0, 0.45 + j * ch / ny, 0.0), Vector3(cw, 0.02, 0.3), "bois", 1.0)
	var env: Array = ["papier", _c(R, "env_bleu", Color(0.7, 0.8, 0.95), 0.9), _c(R, "env_rose", Color(0.98, 0.8, 0.82), 0.9), _c(R, "env_kraft", Color(0.75, 0.6, 0.42), 0.9)]
	for i2 in range(nx):
		for j2 in range(ny):
			if R.rng.randf() < 0.35:
				continue
			var n: int = 1 + R.rng.randi() % 3
			for e in range(n):
				k.box(C * Transform3D(Basis(Vector3.BACK, R.rng.randf_range(-0.15, 0.15)), Vector3(-cw * 0.5 + (i2 + 0.5) * cw / nx + 0.02 * e, 0.45 + j2 * ch / ny + 0.1, 0.02 + 0.03 * e)), Vector3(0.2, 0.13, 0.008), str(env[(i2 + j2 + e) % env.size()]), 1.0)
	k.box(C * T3(0, 0.22, 0), Vector3(cw, 0.44, 0.3), "bois_sombre", 1.0)
	for p in range(4):
		var px: float = -cw * 0.5 + 0.4 + p * 0.95
		k.box(C * T3(px, 0.45 + ch + 0.14, 0.0), Vector3(0.4, 0.26, 0.28), "carton", 1.0)
		k.box(C * T3(px, 0.45 + ch + 0.14, 0.0), Vector3(0.41, 0.02, 0.29), _tex(R, "ficelle", "beau161/corde.png", Color(0.95, 0.85, 0.65)), 1.0)
	k.col_box(C * T3(0, (0.45 + ch) * 0.5, 0), Vector3(cw, 0.45 + ch, 0.3))
	R.reserve(0.0, -hd + 0.22, cw, 0.6)
	R.mark_wall(0.0, 1.4, -hd, cw * 0.5)
	# les sacs postaux, dans le coin
	for s in range(3):
		var sxp: float = hw - 0.7 - 0.5 * float(s % 2)
		var szp: float = -hd + 1.0 + 0.45 * s
		k.cyl(R.L(sxp, 0, szp), 0.24, 0.2, 0.6, _toile(R), 12)
		k.cyl(R.L(sxp, 0.6, szp), 0.2, 0.05, 0.18, _toile(R), 12)
		k.ring(R.L(sxp, 0.66, szp), 0.06, 0.09, 0.04, "cuir", 10)
	# le télégraphe (Pile-ou-Face), le perchoir des messagers ailés (Pandémonia)
	if st == "perchee":
		var tg: Transform3D = G * T3(1.7, 1.13, 0.1)
		k.box(tg * T3(0, 0.03, 0), Vector3(0.32, 0.06, 0.2), "bois_sombre", 1.0)
		k.box(tg * T3(0.04, 0.08, 0), Vector3(0.18, 0.02, 0.03), "or", 1.0)
		k.cyl(tg * T3(0.12, 0.09, 0), 0.02, 0.02, 0.025, "noir", 8)
		k.cyl(tg * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(-0.1, 0.1, 0.0)), 0.05, 0.05, 0.08, "or", 12)
		k.box(tg * T3(-0.1, 0.075, 0.12), Vector3(0.03, 0.002, 0.25), "papier", 1.0)
		var tick := func(delta: float) -> void:
			var tt: float = float(M.ctx.get("morse_t", 3.0)) - delta
			if tt <= 0.0:
				tt = _r(M).randf_range(4.0, 9.0)
				M.main.sfx("dalle_clic", M.R.P(1.7, 1.2, zg), -14.0)
			M.ctx["morse_t"] = tt
		M.ctx["tick170"] = tick
	elif st == "braise":
		k.cyl(R.L(-hw + 0.8, 0, -hd + 1.2), 0.04, 0.05, 1.9, "fer", 8)
		k.box(R.L(-hw + 0.8, 1.9, -hd + 1.2), Vector3(0.9, 0.05, 0.05), "fer", 1.0)
		k.cyl(R.L(-hw + 0.8, 0, -hd + 1.2), 0.2, 0.22, 0.04, "fer", 12)
		R.reserve(-hw + 0.8, -hd + 1.2, 0.5, 0.5)
	# la boîte aux lettres, près de la porte
	var bc: Color = {"perchee": Color(0.15, 0.3, 0.55), "azur": Color(0.95, 0.75, 0.12), "braise": Color(0.12, 0.08, 0.08)}.get(st, Color(0.2, 0.35, 0.6))
	var bl: String = _c(R, "boite_lettres", bc, 0.5, 0.3)
	var bx0: float = -hw + 0.4
	var bz0: float = hd - 1.4
	k.box(R.L(bx0, 1.15, bz0, 90.0), Vector3(0.45, 0.55, 0.3), bl, 1.0)
	k.box(R.L(bx0, 1.45, bz0, 90.0), Vector3(0.5, 0.06, 0.34), bl, 1.0)
	k.box(R.L(bx0 + 0.16, 1.28, bz0, 90.0), Vector3(0.24, 0.02, 0.01), "noir", 1.0)
	k.box(R.L(bx0, 0.45, bz0), Vector3(0.08, 0.9, 0.08), "fer", 1.0)
	k.col_box(R.L(bx0, 0.7, bz0), Vector3(0.4, 1.4, 0.5))
	R.reserve(bx0, bz0, 0.6, 0.6)
	_ecrit(M, bx0 + 0.16, 1.2, bz0, 90.0, "POSTE", 40, Color(1, 0.95, 0.8), 0.003)
	var poster := func() -> void:
		var inv: Node = M.main.get("inventory_v28")
		if inv != null and int(inv.count("carte_postale")) > 0:
			inv.remove("carte_postale", 1)
			M.main.sfx("dalle_clic")
			M.say("Ta carte postale glisse dans la fente… Elle partira demain. Quelqu'un, quelque part, sera content.", 5.0)
		else:
			M.say("Tu n'as pas de carte postale à poster. (On en trouve chez les marchands de souvenirs, et ici, au guichet.)", 5.0)
	M.act(R.P(bx0 + 0.6, 0, bz0), "E : poster une carte postale", poster, 1.0)
	var tp: String = _img(R, "tarifs_poste", "beau170/tarifs_poste.png")
	_cadre(R, tp, hw - 0.02, 1.7, hd - 2.4, -90.0, 0.8, 1.0)
	# le pupitre où l'on écrit (une plume, un encrier)
	# (contre le mur ; on écrit debout, devant, à bonne distance : la tête au-dessus du pupitre)
	R.table(-hw + 0.55, hd - 2.6, 90.0, 1.2, 0.55, 1.05)
	k.cyl(R.L(-hw + 0.45, 1.07, hd - 2.35), 0.03, 0.035, 0.05, "noir", 8)
	k.box(R.L(-hw + 0.45, 1.13, hd - 2.35) * Transform3D(Basis(Vector3.BACK, 0.4), Vector3.ZERO), Vector3(0.012, 0.18, 0.012), "papier", 1.0)
	k.box(R.L(-hw + 0.6, 1.065, hd - 2.65, 90.0), Vector3(0.3, 0.004, 0.22), "papier", 1.0)
	var menu := {"vend": {"carte_postale": 2, "lettre_azur": 1} if st == "azur" else {"carte_postale": 2},
		"bonjour": "Bienvenue à la poste ! Lettres, colis, télégrammes." if st == "perchee" else "Bonjour ! Un timbre ? Une carte ? Un colis ?",
		"services": [{"label": "J'aimerais envoyer un télégramme.", "cb": func(): _menu(M, M.ctx["marchand"], M.ctx["menu170"], "Un télégramme ? Bien sûr. Dites-moi tout… STOP. Ah non, pas STOP tout de suite : d'abord le message. STOP.")}],
		"infos": ["Chaque matin, le courrier arrive par la Navette des Nuées. Zoé le jette sur la place, et moi je cours le ramasser.", "Le télégraphe va jusqu'au Quai des Nuées. Au-delà, ce sont les pigeons. Ils sont moins rapides, mais plus bavards."]}
	M.ctx["menu170"] = menu
	_marchand(M, -1.5, zg - 0.6, 0.0, "comptoir", "femme", "Mademoiselle Morse", ["Un timbre, deux timbres…", "Le courrier n'attend pas !", "Tamponné, trié, envoyé."], menu)
	var trieur: Node = M.person("homme", 1.6, -hd + 0.85, 180.0, "debout", "Firmin")
	trieur.lines = ["Celle-ci… à gauche. Celle-là… à gauche aussi. Tout va à gauche, aujourd'hui."]
	_clients(M, [["vieille", -hw + 1.3, hd - 2.65, -90.0, "debout", ["Ma chère sœur… non. Ma très chère sœur…"]]])
	M.ctx["bonjour170"] = ["Bonjour ! La poste est ouverte.", "Entrez ! Le courrier n'attend pas."]
	M.ctx["entree"] = "%s : le guichet et ses grilles, les casiers du tri pleins de lettres, l'odeur du papier et de l'encre." % str(M.cur.get("enseigne170", "La poste"))


# =================================================================== l'hôtel (l'Hôtel des Nuages, Pile-ou-Face)

static func _hotel(M) -> void:
	var R = M.R
	var k = R.kit
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	# la réception, à gauche ; le tableau des clés derrière
	var rz: float = -0.6
	var cx: Transform3D = _comptoir(M, -hw + 1.55, rz, 2.8, 90.0)
	k.cyl(cx * T3(0.6, 1.06, 0.1), 0.05, 0.06, 0.02, "or", 12)
	k.cyl(cx * T3(0.6, 1.08, 0.1), 0.05, 0.0, 0.06, "or", 12)
	k.box(cx * Transform3D(Basis(Vector3.UP, 0.2), Vector3(-0.4, 1.075, 0.05)), Vector3(0.45, 0.03, 0.32), "papier", 1.0)
	k.box(cx * T3(-0.4, 1.065, 0.05), Vector3(0.47, 0.02, 0.34), "cuir", 1.0)
	k.cyl(cx * T3(-0.05, 1.06, -0.05), 0.025, 0.03, 0.05, "noir", 8)
	var tab: Transform3D = R.L(-hw + 0.03, 1.75, rz, 90.0)
	k.box(tab * T3(0, 0, 0.02), Vector3(1.8, 1.0, 0.04), "bois_sombre", 1.0)
	for i in range(4):
		for j in range(3):
			var hx: float = -0.7 + i * 0.47
			var hy: float = 0.28 - j * 0.3
			k.cyl(tab * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(hx, hy, 0.06)), 0.01, 0.01, 0.05, "or", 6)
			if (i + j) % 4 != 1:
				k.box(tab * T3(hx, hy - 0.08, 0.075), Vector3(0.02, 0.1, 0.01), "or", 1.0)
				k.cyl(tab * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(hx, hy - 0.16, 0.075)), 0.03, 0.03, 0.01, "or", 10)
	R.mark_wall(-hw, 1.75, rz, 1.0)
	var sonner := func() -> void:
		M.main.sfx("clochette", M.R.P(-hw + 1.55, 1.1, rz + 0.6))
		var f: Variant = M.ctx.get("marchand", null)
		if f != null and is_instance_valid(f):
			f.say(str(_pick(M, ["Voilà, voilà ! J'arrive !", "Ding ! Oui ? Une chambre ? Un renseignement ?", "Pas besoin de sonner trois fois, je suis juste là."])), 3.0)
	M.act(R.P(-hw + 2.4, 0, rz + 0.6), "E : sonner la clochette", sonner, 1.0)
	# l'escalier qui monte aux chambres (à droite), le palier, la porte « Chambres »
	var nst: int = 9
	var z0: float = hd - 1.7
	var z1: float = -hd + 1.7
	var rise: float = 1.8 / nst
	var run: float = (z0 - z1) / nst
	var sx: float = hw - 0.75
	for s in range(nst):
		var sz: float = z0 - (s + 0.5) * run
		k.box(R.L(sx, (s + 1) * rise * 0.5, sz), Vector3(1.3, (s + 1) * rise, run), "bois_sombre", 1.0)
		k.box(R.L(sx, (s + 1) * rise + 0.01, sz), Vector3(1.32, 0.02, run + 0.02), "bois", 1.0)
		k.box(R.L(sx, (s + 1) * rise + 0.025, sz), Vector3(0.7, 0.01, run), _c(R, "tapis_rouge", Color(0.55, 0.08, 0.1), 0.95), 1.0)
		k.col_box(R.L(sx, (s + 1) * rise * 0.5, sz), Vector3(1.3, (s + 1) * rise, run))
	k.box(R.L(sx - 0.15, 1.8 * 0.5, -hd + 0.85), Vector3(1.6, 1.8, 1.7), "bois_sombre", 1.0)
	k.col_box(R.L(sx - 0.15, 0.9, -hd + 0.85), Vector3(1.6, 1.8, 1.7))
	for s2 in range(nst + 1):
		var bz: float = z0 - s2 * run
		k.cyl(R.L(sx - 0.62, s2 * rise, bz), 0.02, 0.02, 0.9, "bois", 6)
	var rampe_len: float = sqrt(pow(z0 - z1, 2) + 1.8 * 1.8)
	k.box(R.L(sx - 0.62, 0.9 + 0.9, (z0 + z1) * 0.5) * Transform3D(Basis(Vector3.RIGHT, atan2(1.8, z0 - z1)), Vector3.ZERO), Vector3(0.07, 0.07, rampe_len), "bois_sombre", 1.0)
	R.reserve(sx, 0.0, 1.6, R.D)
	var pd: Transform3D = R.L(sx - 0.15, 1.8, -hd + 0.02)
	k.box(pd * T3(0, 0.85, 0.025), Vector3(1.1, 1.72, 0.03), "bois_sombre", 1.0)
	k.box(pd * T3(0, 0.82, 0.05), Vector3(0.95, 1.6, 0.04), "bois", 1.0)
	k.cyl(pd * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0.32, 0.8, 0.07)), 0.03, 0.03, 0.04, "or", 8)
	_ecrit(M, sx - 0.15, 1.8 + 1.35, -hd + 0.02, 0.0, "CHAMBRES", 40, Color(1.0, 0.85, 0.5), 0.003, 0.1)
	var vel: String = _c(R, "velours_rouge", Color(0.55, 0.05, 0.08), 0.9)
	for p in [-1.0, 1.0]:
		k.cyl(R.L(sx + p * 0.6, 0, z0 + 0.3), 0.1, 0.1, 0.04, "or", 10)
		k.cyl(R.L(sx + p * 0.6, 0, z0 + 0.3), 0.02, 0.02, 0.9, "or", 8)
	k.cyl(R.L(sx, 0.82, z0 + 0.3) * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3.ZERO), 0.02, 0.02, 1.15, vel, 8)
	k.col_box(R.L(sx, 0.5, z0 + 0.3), Vector3(1.3, 1.0, 0.1))
	# le salon : le tapis, les fauteuils, le canapé, la table basse et le journal, le lustre
	R.tapis(0.2, 0.9, 0.0, 3.2, 2.4)
	R.canape(0.2, -0.3, 0.0, "rouge", 2.0)
	R.fauteuil(-1.4, 1.1, 90.0, "vert")
	R.fauteuil(1.8, 1.1, -90.0, "vert")
	R.table(0.2, 1.0, 0.0, 1.0, 0.6, 0.45)
	k.box(R.L(0.1, 0.475, 1.0, 10.0), Vector3(0.36, 0.01, 0.26), "papier", 1.0)
	R.plante(-hw + 0.5, hd - 0.7, 0.0, 1.2)
	R.plante(1.9, -hd + 0.5, 0.0, 1.1)
	_lustre(M, 0.2, 0.5, 0.55, 1.3)
	R.tableau(0.2, 2.2, -hd + 0.02, 0.0, 1.1, 0.8)
	_horloge(M, -0.9, 2.3, -hd + 0.03, 0.0, 0.26)
	# les bagages qui attendent, le chariot de laiton
	var gx: float = -hw + 1.0
	var gz: float = hd - 2.4
	k.box(R.L(gx, 0.12, gz), Vector3(0.8, 0.04, 0.5), "or", 1.0)
	for sx2 in [-0.38, 0.38]:
		k.cyl(R.L(gx + sx2, 0.14, gz - 0.22), 0.015, 0.015, 1.3, "or", 6)
		k.cyl(R.L(gx + sx2, 0.14, gz + 0.22), 0.015, 0.015, 1.3, "or", 6)
	k.box(R.L(gx, 1.44, gz), Vector3(0.8, 0.03, 0.03), "or", 1.0)
	k.box(R.L(gx, 0.36, gz), Vector3(0.6, 0.44, 0.22), "cuir", 1.0)
	k.box(R.L(gx + 0.05, 0.7, gz, 8.0), Vector3(0.48, 0.24, 0.32), "tissu_rouge", 1.0)
	k.col_box(R.L(gx, 0.7, gz), Vector3(0.85, 1.4, 0.55))
	R.reserve(gx, gz, 1.0, 0.8)
	var habit: Node = _habitue(M, "zoe_pp", 1.8, 1.1, -90.0, "lire", ["Le vent d'est se lève… Demain, ça va secouer là-haut.", "Une chambre au dernier étage : je dors plus près du ciel."])
	if habit != null:
		habit.npc.global_position += Vector3.UP * 0.02
	var dormir := func() -> void:
		M.close_talk()
		var inv: Node = M.main.get("inventory_v28")
		var p8: int = _prix(M, 8)
		if inv == null or int(inv.count("piece")) < p8:
			M.say("Une chambre coûte %d pièces. Il t'en manque un peu…" % p8, 4.0)
			return
		var t: Node = M.main.get("temps_v56")
		if t == null:
			return
		inv.remove("piece", p8)
		M.main.sfx("lit_dodo")
		var h: float = float(t.hour)
		t.sleep_until(7.0 if (h >= 17.0 or h < 6.0) else 19.0)
		M.say("La chambre 7, tout en haut : un lit moelleux, la fenêtre ouverte sur les nuages. Tu t'endors en un clin d'œil… Zzz.", 6.0)
	var menu := {"bonjour": "Bienvenue à l'Hôtel des Nuages ! Des chambres avec vue… sur les nuages, évidemment.",
		"services": [{"label": "Prendre une chambre pour la nuit (%d pièces)." % _prix(M, 8), "cb": dormir}],
		"infos": ["L'hôtel a trois étages ; le dernier touche presque les nuages. Les jours de brume, on ne voit plus le rez-de-chaussée.", "Mademoiselle Zoé Nuée loge ici : chambre 12, celle qui a un hublot à la place de la fenêtre.", "Le petit-déjeuner ? Haricots du ranch et café à la vapeur. Comme partout à Pile-ou-Face."]}
	_marchand(M, -hw + 0.95, rz, 90.0, "comptoir", "homme", "Monsieur Édouard", ["Clé numéro sept… où ai-je mis la sept ?", "L'hôtel est complet ! Sauf les chambres libres.", "Bonne nuit d'avance !"], menu)
	M.ctx["bonjour170"] = ["Bienvenue à l'Hôtel des Nuages !", "Bonjour ! Une chambre ? Ou juste une visite ?"]
	M.ctx["entree"] = "L'Hôtel des Nuages : le tapis rouge de l'escalier, le tableau des clés derrière la réception, le salon et son lustre."


# =================================================================== l'épicerie (Rosemonde, Colette) ; les épices (Zébuline)

static func _epicerie(M) -> void:
	var R = M.R
	var k = R.kit
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var st: String = str(M.cur.get("style", ""))
	var epices: bool = str(M.cur.get("metier", "")) == "epices"
	var zc: float = -hd + 1.85
	for i in range(3):
		_rayons(M, -hw + 1.0 + i * 1.45, -hd + 0.22, 0.0, 1.35, 2.2, 5, "bocaux" if i != 1 else ("sacs" if epices else "boites"), i * 2)
	_rayons(M, hw - 0.9, -hd + 0.22, 0.0, 1.35, 2.2, 5, "pots" if epices else "bocaux", 5)
	var cx: Transform3D = _comptoir(M, 0.9, zc, 2.8)
	_balance(R, cx * T3(-0.8, 1.06, 0.05))
	_caisse(R, cx * T3(0.95, 1.06, 0.0))
	if not epices:
		# la meule de fromage, le bocal de bonbons
		k.cyl(cx * T3(0.1, 1.06, 0.1), 0.2, 0.2, 0.16, "fromage", 18)
		k.box(cx * Transform3D(Basis(Vector3.UP, 0.4), Vector3(0.18, 1.14, 0.18)), Vector3(0.14, 0.16, 0.14), "fromage", 1.0)
		_bocaux(R, cx * T3(-0.3, 1.06, 0.18), 1, 0.2, 0.09, 0.28, 4)
	# l'étal en gradins, contre le mur de gauche : les cagettes de fruits et de légumes
	var fruits: Array = [Color(0.78, 0.1, 0.08), Color(0.95, 0.55, 0.1), Color(0.95, 0.85, 0.2), Color(0.35, 0.6, 0.2), Color(0.45, 0.2, 0.45), Color(0.9, 0.35, 0.3)]
	if epices:
		fruits = [Color(0.75, 0.15, 0.05), Color(0.95, 0.6, 0.1), Color(0.9, 0.75, 0.15), Color(0.45, 0.25, 0.12), Color(0.35, 0.45, 0.15), Color(0.6, 0.1, 0.2)]
	var ex: float = -hw + 0.55
	for g in range(3):
		var gz: float = -hd + 2.8 + g * 1.0
		if gz > hd - 1.6:
			break
		for lv in range(2):
			var xf: Transform3D = R.L(ex + 0.35 * lv, 0.45 + 0.3 * (1 - lv), gz, 90.0) * Transform3D(Basis(Vector3.RIGHT, 0.18), Vector3.ZERO)
			k.box(xf * T3(0, 0, 0), Vector3(0.85, 0.16, 0.42), "bois_clair", 1.0)
			var fk: String = _c(R, "fruit_%d_%d" % [g, lv], fruits[(g * 2 + lv) % fruits.size()], 0.45 if not epices else 0.95)
			if epices:
				k.cyl(xf * T3(0, 0.08, 0), 0.19, 0.0, 0.2, fk, 14)
			else:
				for fx in range(5):
					for fz in range(2):
						k.cyl(xf * T3(-0.32 + fx * 0.16, 0.08, -0.08 + fz * 0.16), 0.06, 0.065, 0.09, fk, 8)
		k.box(R.L(ex + 0.2, 0.22, gz), Vector3(0.75, 0.44, 0.8), "bois_sombre", 1.0)
		k.col_box(R.L(ex + 0.2, 0.4, gz), Vector3(0.8, 0.8, 0.85))
		R.reserve(ex + 0.2, gz, 0.9, 0.9)
	# les sacs ouverts devant le comptoir (le grain, les haricots, les lentilles ; ou les épices)
	var sacs: Array = [Color(0.85, 0.75, 0.45), Color(0.45, 0.25, 0.15), Color(0.6, 0.35, 0.2)]
	if epices:
		sacs = [Color(0.85, 0.2, 0.05), Color(0.95, 0.65, 0.05), Color(0.55, 0.3, 0.12), Color(0.3, 0.42, 0.18)]
	for s in range(sacs.size()):
		_sac(R, 2.2 - s * 0.6, zc + 1.0 + 0.15 * float(s % 2), sacs[s], 0.9)
	R.tonneau(hw - 0.6, hd - 1.3)
	k.cyl(R.L(hw - 0.6, 0.88, hd - 1.3), 0.28, 0.28, 0.02, _c(R, "cornichons", Color(0.35, 0.45, 0.15), 0.3), 14)
	if epices:
		# des chapelets de piments et d'ail, les lanternes de cuivre, le tapis
		_herbes(M, -hw + 1.0, hw - 1.4, -hd + 1.2)
		for lx in [-1.6, 1.8]:
			_lanterne(M, lx, 0.6)
		R.tapis(0.4, 1.4, 0.0, 2.6, 1.6)
	else:
		_herbes(M, -hw + 1.2, -0.2, hd - 2.4)
	var lignes: Array = ["Goûte d'abord, tu me diras après !", "Tout est frais du jour. Enfin, d'hier soir.", "Ici, ça sent bon, c'est déjà la moitié du travail."]
	if epices:
		lignes = ["Une pincée de piment infernal, et ta soupe chante !", "Attention, celui-là pique. Celui-là aussi. Tout pique, en fait.", "Pépin ! Ne mets pas le nez dans le sac de poivre !"]
		_habitue(M, "pepin_braise", -0.6, zc + 1.2, 160.0, "observer", ["Maman, je peux goûter le rouge ?"])
	_marchand(M, 0.9, zc - 0.55, 0.0, "comptoir", "femme", "Madame Prune", lignes, {"vend": {"pomme": 1, "miel": 4, "pain_miel": 4, "baies": 1}, "achete": {"champignon": 2, "baies": 1, "pomme": 1}})
	_clients(M, [["femme", -1.0, zc + 1.6, 200.0, "debout", ["Il me faut… du sel, du sucre, et je ne sais plus quoi."]]] if not epices else [])
	M.ctx["bonjour170"] = ["Bonjour, mon sucre ! Entre !", "Bienvenue ! Il y a des nouveautés."] if not epices else ["Entre, entre ! Sens-moi ça !", "Bienvenue chez Zébuline ! Ça pique, ici."]
	M.ctx["entree"] = "%s : les bocaux de confiture, les sacs de grain, les cagettes de fruits, la meule de fromage." % str(M.cur.get("enseigne170", "L'épicerie")) if not epices else "Les Épices de Zébuline : des sacs ouverts de toutes les couleurs, des chapelets de piments, une odeur qui fait éternuer."


# =================================================================== l'apothicaire (Doc Cornemuse, Amélie, Vespérine, Aubin)

static func _apothicaire(M) -> void:
	var R = M.R
	var k = R.kit
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var st: String = str(M.cur.get("style", ""))
	var magique: bool = st in ["braise", "montjoie", "arcanelle"]
	M.ctx["fiole_emit"] = 0.7 if magique else 0.0
	var zc: float = -hd + 1.8
	# le mur des tiroirs, derrière le comptoir
	var tw: float = minf(3.6, R.W - 2.6)
	var th: float = 2.2
	var T: Transform3D = R.L(0.0, 0.0, -hd + 0.25)
	k.box(T * T3(0, th * 0.5, 0), Vector3(tw, th, 0.4), "bois_sombre", 1.0)
	var nx: int = 9
	var ny: int = 6
	var etiq: String = _c(R, "etiquette", Color(0.95, 0.92, 0.8), 0.9)
	for i in range(nx):
		for j in range(ny):
			var dx: float = -tw * 0.5 + (i + 0.5) * tw / nx
			var dy: float = 0.2 + (j + 0.5) * (th - 0.25) / ny
			k.box(T * T3(dx, dy, 0.205), Vector3(tw / nx - 0.04, (th - 0.25) / ny - 0.04, 0.02), "bois", 1.0)
			k.cyl(T * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(dx, dy - 0.05, 0.215)), 0.014, 0.014, 0.025, "or", 6)
			k.box(T * T3(dx, dy + 0.05, 0.218), Vector3(0.14, 0.05, 0.004), etiq, 1.0)
	k.box(T * T3(0, th + 0.05, 0.03), Vector3(tw + 0.12, 0.1, 0.48), "bois_sombre", 1.0)
	_bocaux(R, T * T3(-tw * 0.5 + 0.2, th + 0.1, 0.0), int(tw / 0.24), 0.24, 0.08, 0.26, 3)
	k.col_box(T * T3(0, th * 0.5, 0), Vector3(tw, th, 0.4))
	R.reserve(0.0, -hd + 0.25, tw, 0.6)
	R.mark_wall(0.0, 1.2, -hd, tw * 0.5)
	# les fioles sur les côtés
	_rayons(M, -hw + 0.22, -hd + 2.6, 90.0, 1.4, 2.1, 5, "fioles", 1)
	_rayons(M, hw - 0.22, -hd + 2.6, -90.0, 1.4, 2.1, 5, "fioles", 4)
	# le comptoir : le mortier et son pilon, la balance, les grands bocaux d'herbes
	var cx: Transform3D = _comptoir(M, 0.0, zc, 2.6)
	k.cyl(cx * T3(-0.8, 1.06, 0.1), 0.1, 0.08, 0.1, "pierre_lisse", 14)
	k.cyl(cx * Transform3D(Basis(Vector3.BACK, 0.4), Vector3(-0.78, 1.18, 0.1)), 0.018, 0.025, 0.2, "pierre_lisse", 8)
	_balance(R, cx * T3(0.75, 1.06, 0.05))
	_bocaux(R, cx * T3(-0.3, 1.06, 0.15), 3, 0.2, 0.08, 0.26, 2)
	# l'alambic, sur sa table : le chaudron de cuivre, le ballon de verre, le serpentin
	var ax: float = hw - 1.3
	var az: float = hd - 2.4
	R.table(ax, az, 0.0, 1.2, 0.7)
	k.cyl(R.L(ax - 0.3, 0.77, az), 0.16, 0.13, 0.25, "cuivre", 14)
	k.cyl(R.L(ax - 0.3, 1.02, az), 0.13, 0.04, 0.12, "cuivre", 14)
	k.cyl(R.L(ax - 0.1, 1.12, az) * Transform3D(Basis(Vector3.BACK, -1.1), Vector3.ZERO), 0.018, 0.018, 0.5, "cuivre", 8)
	var liq: Color = Color(0.3, 0.8, 0.4) if not magique else Color(0.6, 0.3, 0.95)
	var ball: MeshInstance3D = Sud._boule(M.room, R.mat(_verre(R, "ballon170", liq, 0.55, 0.8 if magique else 0.2)), R.P(ax + 0.32, 0.93, az), 0.14)
	ball.name = "Ballon"
	k.cyl(R.L(ax + 0.32, 0.77, az), 0.06, 0.08, 0.04, "fer", 10)
	k.cyl(R.L(ax - 0.3, 0.77, az), 0.04, 0.04, 0.02, "fer", 8)
	R.fire(R.P(ax - 0.3, 0.74, az), 0.25)
	for b in range(3):
		var bub: MeshInstance3D = Sud._boule(M.room, R.mat(_verre(R, "bulle170", Color(1, 1, 1), 0.35)), R.P(ax + 0.32, 0.9, az), 0.018)
		(M.ctx["anims170"] as Array).append([bub, "flotte", 0.05, bub.position.y, b * 2.1])
	_lampe(M, ax + 0.3, 1.1, az, liq, 0.6, 2.2)
	# les herbes qui sèchent, les planches de botanique
	_herbes(M, -hw + 0.9, hw - 0.9, -hd + 1.1)
	var pb: String = _img(R, "planches170", "beau170/planches_botanique.png")
	_cadre(R, pb, -hw + 0.02, 1.7, hd - 2.2, 90.0, 1.0, 0.75)
	if st == "azur":
		for pz in range(3):
			R.plante(-hw + 0.5 + pz * 0.6, hd - 0.6, 0.0, 0.9 + 0.2 * float(pz % 2))
	if magique:
		# un chaudron qui bouillonne, une lueur violette
		var chx: float = -hw + 1.3
		var chz: float = hd - 1.6
		k.cyl(R.L(chx, 0.0, chz), 0.3, 0.42, 0.55, "fer", 16)
		k.cyl(R.L(chx, 0.5, chz), 0.33, 0.33, 0.02, _c(R, "potion_chaudron", liq, 0.3, 0.0, 1.5), 16)
		k.col_box(R.L(chx, 0.3, chz), Vector3(0.8, 0.6, 0.8))
		R.reserve(chx, chz, 0.9, 0.9)
		_lampe(M, chx, 0.9, chz, liq, 0.9, 2.6)
		for b2 in range(4):
			var bb: MeshInstance3D = Sud._boule(M.room, R.mat(_c(R, "potion_bulle", liq.lightened(0.3), 0.3, 0.0, 1.8)), R.P(chx - 0.15 + 0.1 * b2, 0.56, chz + 0.05 * float(b2 % 2)), 0.03)
			(M.ctx["anims170"] as Array).append([bb, "flotte", 0.03, bb.position.y, b2 * 1.7])
	var lignes: Array = ["Une tisane pour dormir, une potion pour se réveiller.", "Rien ne vaut une bonne nuit… et une goutte de sève.", "On ne goûte pas les fioles du haut, s'il te plaît !"]
	_marchand(M, 0.0, zc - 0.55, 0.0, "comptoir", "vieux", "Maître Salsifis", lignes, {"vend": {"potion_seve": 14, "tisane_lune": 6}, "achete": {"champignon": 2, "fleur_lune": 12, "baies": 1}})
	M.ctx["bonjour170"] = ["Bonjour ! Un remède ? Un conseil ?", "Entre ! Tu as bonne mine… mais on peut toujours faire mieux."]
	M.ctx["entree"] = "%s : le grand mur de tiroirs, les fioles de toutes les couleurs, les herbes qui sèchent au plafond, l'alambic qui glougloute." % str(M.cur.get("enseigne170", "L'apothicaire"))


# =================================================================== le bureau du shérif (Pile-ou-Face) ; la caserne (Pandémonia, Montjoie)

static func _sherif(M) -> void:
	var R = M.R
	var k = R.kit
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var st: String = str(M.cur.get("style", ""))
	if str(M.cur.get("metier", "")) == "caserne":
		_caserne(M)
		return
	# le bureau, le fauteuil, les papiers, l'étoile
	var bx: float = -0.8
	var bz: float = -hd + 2.0
	R.table(bx, bz, 0.0, 1.7, 0.85)
	R.chaise(bx, bz - 0.7, 0.0)
	for p in range(4):
		k.box(R.L(bx - 0.5 + p * 0.12, 0.775 + p * 0.004, bz + 0.05, R.rng.randf_range(-15, 15)), Vector3(0.22, 0.004, 0.3), "papier", 1.0)
	k.cyl(R.L(bx + 0.55, 0.77, bz + 0.1), 0.06, 0.06, 0.01, "or", 5)
	k.cyl(R.L(bx + 0.3, 0.77, bz - 0.15), 0.04, 0.035, 0.1, "ceramique", 10)
	# la cellule, au fond à droite : les barreaux, la porte ouverte, la couchette… et le chat qui dort
	var cx0: float = hw - 2.4
	var cz0: float = -hd + 2.4
	for i in range(13):
		var x: float = cx0 + i * 0.18
		if i >= 2 and i <= 6:
			continue
		k.cyl(R.L(x, 0, cz0), 0.018, 0.018, R.H - 0.2, "fer", 6)
	k.box(R.L(cx0 + 1.2, R.H - 0.25, cz0), Vector3(2.4, 0.08, 0.08), "fer", 1.0)
	k.box(R.L(cx0 + 1.2, 0.05, cz0), Vector3(2.4, 0.06, 0.08), "fer", 1.0)
	var porte: Transform3D = R.L(cx0 + 0.36, 0, cz0, -70.0)
	for i2 in range(5):
		k.cyl(porte * T3(0.09 + i2 * 0.18, 0, 0), 0.016, 0.016, 2.1, "fer", 6)
	k.box(porte * T3(0.45, 2.1, 0), Vector3(0.9, 0.05, 0.04), "fer", 1.0)
	k.box(porte * T3(0.45, 1.0, 0), Vector3(0.9, 0.05, 0.04), "fer", 1.0)
	k.col_box(R.L(cx0 + 1.75, 1.2, cz0), Vector3(1.3, 2.4, 0.1))
	k.col_box(R.L(cx0 + 0.18, 1.2, cz0), Vector3(0.36, 2.4, 0.1))
	R.lit(hw - 1.05, -hd + 1.1, -90.0, 0.8, "rouge")
	R.chat(hw - 1.2, -hd + 1.05, -90.0, Color(0.9, 0.55, 0.2), true, 0.55)
	R.reserve(hw - 1.2, -hd + 1.2, 2.4, 2.4)
	M.act(R.P(cx0 + 0.9, 0, cz0 + 0.8), "E : regarder dans la cellule", func(): M.say("La cellule est vide. Enfin, presque : Biscotte, le chat de la Shérif, ronfle sur la couchette. « C'est mon seul prisonnier, dit la Shérif. Il a volé une tarte. Il purge sa peine. »", 7.0), 1.2)
	# le poêle et sa cafetière, le tableau des avis de recherche, les lassos, le porte-chapeaux
	var px: float = -hw + 0.8
	var pz: float = -hd + 0.8
	k.cyl(R.L(px, 0, pz), 0.28, 0.3, 0.8, "fer", 14)
	k.cyl(R.L(px, 0.8, pz), 0.3, 0.3, 0.05, "fer", 14)
	k.cyl(R.L(px, 0.85, pz), 0.06, 0.06, R.H - 0.85, "fer", 8)
	k.cyl(R.L(px + 0.1, 0.85, pz + 0.05), 0.07, 0.06, 0.16, "argent", 10)
	k.box(R.L(px, 0.3, pz + 0.29), Vector3(0.24, 0.2, 0.02), _c(R, "braises170", Color(1.0, 0.35, 0.08), 0.9, 0.0, 2.2), 1.0)
	k.col_box(R.L(px, 0.45, pz), Vector3(0.6, 0.9, 0.6))
	R.reserve(px, pz, 0.8, 0.8)
	var liege: String = _img(R, "liege170", "montjoie/tableau_liege.png")
	_cadre(R, liege, -hw + 0.02, 1.6, -hd + 2.7, 90.0, 1.6, 1.1)
	var av: String = _img(R, "avis170", "beau170/avis_recherche.png")
	for a in range(3):
		k.quad(R.L(-hw + 0.045, 1.6 + 0.12 * float(a % 2), -hd + 2.2 + a * 0.5, 90.0) * Transform3D(Basis(Vector3.UP, PI) * Basis(Vector3.BACK, 0.05 * (a - 1)), Vector3.ZERO), 0.38, 0.5, av, Vector2(a * 0.333, 0), Vector2((a + 1) * 0.333, 1))
	M.act(R.P(-hw + 0.9, 0, -hd + 2.7), "E : lire les avis de recherche", func(): M.say("RECHERCHÉ : « Le Voleur de Tartes » (moustaches, quatre pattes, ronronne). RECHERCHÉ : « Le Siffleur Fou » (siffle faux, la nuit). RECHERCHÉ : « Un bon pianiste » (pour le Saloon. Bien payé).", 8.0), 1.2)
	var corde: String = _tex(R, "corde170", "beau161/corde.png", Color(0.9, 0.8, 0.62))
	for l in range(2):
		k.box(R.L(-hw + 0.06, 1.95, hd - 2.6 + l * 0.6), Vector3(0.06, 0.06, 0.16), "bois_sombre", 1.0)
		k.ring(R.L(-hw + 0.14, 1.65, hd - 2.6 + l * 0.6) * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3.ZERO), 0.14, 0.22, 0.05, corde, 18)
	R.mark_wall(-hw, 1.7, hd - 2.3, 0.6)
	k.cyl(R.L(hw - 0.5, 0, hd - 1.3), 0.03, 0.03, 1.8, "bois_sombre", 8)
	k.cyl(R.L(hw - 0.5, 0, hd - 1.3), 0.2, 0.22, 0.04, "bois_sombre", 10)
	_chapeau(R, R.L(hw - 0.5, 1.82, hd - 1.3), "stetson", Color(0.42, 0.28, 0.18), Color(0.15, 0.15, 0.15))
	R.reserve(hw - 0.5, hd - 1.3, 0.5, 0.5)
	# la table de dames (le soir, la Shérif y joue contre son adjoint), le banc des visiteurs, le tapis
	var tx: float = hw - 1.7
	var tz: float = hd - 2.5
	R.table(tx, tz, 0.0, 0.9, 0.9)
	k.box(R.L(tx, 0.765, tz, 10.0), Vector3(0.5, 0.012, 0.5), _img(R, "damier170", "maisons/damier_noir_blanc.png"), 1.0)
	for q in range(7):
		k.cyl(R.L(tx - 0.18 + 0.06 * q, 0.772, tz - 0.12 + 0.08 * float(q % 3)), 0.022, 0.022, 0.012, "tissu_rouge" if q % 2 else "noir", 10)
	R.chaise(tx - 0.65, tz, 90.0)
	R.chaise(tx + 0.65, tz, -90.0)
	R.banc(-hw + 0.45, hd - 1.5, 90.0, 1.4)
	R.tapis(bx, bz + 1.3, 0.0, 2.6, 1.5)
	_ecrit(M, 0.0, R.H - 0.5, -hd + 0.03, 0.0, "BUREAU DU SHÉRIF", 64, Color(0.95, 0.82, 0.45), 0.004)
	k.cyl(R.L(0.0, R.H - 0.95, -hd + 0.05) * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 0.22, 0.22, 0.03, "or", 5)
	R.mark_wall(0.0, R.H - 0.95, -hd, 0.3)
	var lignes: Array = ["Ici, c'est la loi. Et la loi, c'est moi. Et un peu le chat.", "Tout est calme. Trop calme. J'adore ça.", "Si tu vois le Siffleur Fou, préviens-moi."]
	_marchand(M, bx, bz - 0.7, 0.0, "assis", "femme", "la Shérif", lignes, {"bonjour": "Bureau du Shérif. Tu viens signaler quelque chose ?", "infos": ["À Pile-ou-Face, on joue beaucoup, on triche un peu, et on se dispute rarement. Je veille à ce que ça dure."]})
	M.ctx["cloche170"] = false
	M.ctx["bonjour170"] = ["Entre, l'ami. Tu as la tête de quelqu'un d'honnête.", "Bureau du Shérif. Essuie tes bottes."]
	M.ctx["entree"] = "Le Bureau du Shérif : le bureau couvert de papiers, le poêle et sa cafetière, les avis de recherche, et la cellule… où dort un chat."


static func _caserne(M) -> void:
	var R = M.R
	var k = R.kit
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var st: String = str(M.cur.get("style", ""))
	var drap: String = "rouge" if st == "braise" else "bleu"
	# les lits superposés, le long du mur de gauche ; les coffres au pied
	for i in range(3):
		var lz: float = -hd + 1.2 + i * 1.5
		if lz > hd - 1.6:
			break
		R.lit(-hw + 1.05, lz, 90.0, 0.9, drap, true)
		R.coffre_deco(-hw + 2.4, lz, 90.0)
	# la table de la carte, au milieu ; les chaises
	R.table(0.6, -0.4, 0.0, 2.0, 1.1)
	var carte: String = _img(R, "carte_ile170", "beau170/carte_campagne.png")
	k.quad(R.L(0.6, 0.775, -0.4) * Transform3D(Basis(Vector3.UP, PI) * Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 1.7, 0.9, carte)
	for p in range(3):
		k.cyl(R.L(0.1 + p * 0.5, 0.78, -0.5 + 0.15 * float(p % 2)), 0.025, 0.02, 0.06, ["tissu_rouge", "tissu_bleu", "or"][p], 8)
	for cx in [-0.2, 1.4]:
		R.chaise(cx, 0.4, 180.0)
	# le râtelier (les lances, les épées), les boucliers, l'armure, le mannequin de paille
	var rk: Transform3D = R.L(hw - 0.15, 0, -hd + 2.0, -90.0)
	k.box(rk * T3(0, 0.3, 0), Vector3(2.2, 0.08, 0.3), "bois_sombre", 1.0)
	k.box(rk * T3(0, 1.6, -0.05), Vector3(2.2, 0.08, 0.2), "bois_sombre", 1.0)
	for i2 in range(6):
		var ix: float = -0.9 + i2 * 0.36
		if i2 % 2 == 0:
			k.cyl(rk * T3(ix, 0.3, 0.02), 0.02, 0.02, 2.2, "bois", 6)
			k.cyl(rk * T3(ix, 2.5, 0.02), 0.04, 0.0, 0.22, "argent", 6)
		else:
			k.box(rk * Transform3D(Basis(Vector3.RIGHT, 0.08), Vector3(ix, 0.95, 0.02)), Vector3(0.06, 0.95, 0.012), "argent", 1.0)
			k.box(rk * T3(ix, 0.45, 0.0), Vector3(0.2, 0.03, 0.04), "or", 1.0)
	k.col_box(rk * T3(0, 0.9, 0), Vector3(2.2, 1.8, 0.4))
	R.reserve(hw - 0.3, -hd + 2.0, 0.7, 2.4)
	var blason: Color = Color(0.6, 0.1, 0.08) if st == "braise" else Color(0.15, 0.3, 0.6)
	for s in range(3):
		var sz: float = -hd + 0.9 + s * 1.2
		if s == 1:
			continue
		var X: Transform3D = R.L(0.6 - 1.4 + s * 1.4, 1.9, -hd + 0.06) * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO)
		k.cyl(X, 0.35, 0.35, 0.05, _c(R, "blason170", blason, 0.6), 20)
		k.ring(X * T3(0, 0.02, 0), 0.33, 0.37, 0.06, "or", 20)
		k.cyl(X * T3(0, 0.05, 0), 0.09, 0.07, 0.04, "or", 12)
		R.mark_wall(0.6 - 1.4 + s * 1.4, 1.9, -hd, 0.4)
	k.box(R.L(0.6, 2.0, -hd + 0.04), Vector3(0.7, 1.4, 0.02), _c(R, "banniere170", blason.darkened(0.1), 0.9), 1.0)
	k.box(R.L(0.6, 2.72, -hd + 0.06), Vector3(0.9, 0.05, 0.05), "or", 1.0)
	# l'armure sur son support
	var axr: float = hw - 1.0
	var azr: float = hd - 2.0
	k.cyl(R.L(axr, 0, azr), 0.2, 0.22, 0.05, "bois_sombre", 12)
	k.cyl(R.L(axr, 0.05, azr), 0.03, 0.03, 1.0, "bois_sombre", 6)
	k.cyl(R.L(axr, 1.0, azr), 0.2, 0.17, 0.5, "argent", 14)
	k.box(R.L(axr, 1.48, azr), Vector3(0.5, 0.08, 0.2), "argent", 1.0)
	k.cyl(R.L(axr, 1.55, azr), 0.12, 0.11, 0.25, "argent", 14)
	k.box(R.L(axr, 1.66, azr + 0.1), Vector3(0.16, 0.03, 0.02), "noir", 1.0)
	k.col_box(R.L(axr, 0.85, azr), Vector3(0.5, 1.7, 0.5))
	R.reserve(axr, azr, 0.7, 0.7)
	# le mannequin de paille, pour l'entraînement
	var mx: float = 2.4
	var mz: float = 1.6
	k.box(R.L(mx, 0.8, mz), Vector3(0.1, 1.6, 0.1), "bois_sombre", 1.0)
	k.cyl(R.L(mx, 0.85, mz), 0.22, 0.2, 0.65, _tex(R, "paille170", "beau161/foin_rond.png", Color(0.95, 0.85, 0.55)), 10)
	k.box(R.L(mx, 1.25, mz), Vector3(0.9, 0.1, 0.1), "bois_sombre", 1.0)
	Sud._boule(M.room, R.mat("paille170"), R.P(mx, 1.68, mz), 0.15)
	k.col_box(R.L(mx, 0.8, mz), Vector3(0.5, 1.6, 0.5))
	R.reserve(mx, mz, 0.9, 0.9)
	var lignes: Array = ["Garde à vous ! Ah non, repos. Tu n'es pas de la garde.", "Le service, c'est le service.", "Qui a encore laissé traîner son épée ?"]
	_marchand(M, 0.6, -1.15, 0.0, "pointer", "homme", "le Sergent", lignes, {"bonjour": "La caserne. Tu viens t'engager ?", "infos": ["On s'entraîne le matin, on monte la garde l'après-midi, et le soir… on raconte nos exploits. Surtout ceux qu'on n'a pas faits."]})
	var g1: Node = M.person("homme", -hw + 1.05, -hd + 1.2, 90.0, "dormir", "Garde Roupille")
	g1.lie(R.P(-hw + 1.9, 0.45, -hd + 1.2), Vector3(-1, 0, 0))
	g1.lines = ["Zzz… pas maintenant, sergent… Zzz…"]
	_clients(M, [["femme", 1.6, 1.0, -90.0, "bras_croises", ["Prête pour la ronde !"]]])
	M.ctx["cloche170"] = false
	M.ctx["bonjour170"] = ["Halte ! … Ah, c'est toi. Entre.", "Bienvenue à la caserne. On ne court pas dans les couloirs."]
	M.ctx["entree"] = "La caserne : les lits superposés, le râtelier, la grande table et sa carte, l'armure qui monte la garde toute seule."


# =================================================================== le Comptoir des Prospecteurs (Pile-ou-Face)

static func _prospecteurs(M) -> void:
	var R = M.R
	var k = R.kit
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var zc: float = -hd + 1.9
	var cx: Transform3D = _comptoir(M, 0.6, zc, 2.8)
	_balance(R, cx * T3(-0.7, 1.06, 0.05))
	k.cyl(cx * T3(0.2, 1.06, 0.1), 0.16, 0.12, 0.04, "fer", 16)
	var or_m: String = _c(R, "or_brut", Color(0.95, 0.72, 0.22), 0.35, 0.9, 0.25)
	for n in range(9):
		k.box(cx * Transform3D(Basis(Vector3.UP, n * 0.7), Vector3(0.12 + 0.07 * cos(n * 1.3), 1.11, 0.1 + 0.07 * sin(n * 2.1))), Vector3(0.035, 0.025, 0.03), or_m, 1.0)
	k.box(cx * T3(0.9, 1.075, 0.05), Vector3(0.36, 0.05, 0.26), "cuir", 1.0)
	# les étagères : les lanternes, les batées, les boîtes ; les pioches et les pelles au mur
	_rayons(M, -hw + 1.0, -hd + 0.22, 0.0, 1.35, 2.1, 4, "boites", 2)
	_rayons(M, hw - 1.0, -hd + 0.22, 0.0, 1.35, 2.1, 4, "pots", 3)
	for b in range(3):
		k.cyl(R.L(-hw + 0.15, 1.3 + b * 0.36, -hd + 2.6, 90.0) * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3.ZERO), 0.2, 0.16, 0.05, "fer", 18)
	for t in range(4):
		var tz: float = -hd + 3.3 + t * 0.32
		k.box(R.L(-hw + 0.08, 1.4, tz) * Transform3D(Basis(Vector3.RIGHT, 0.1 * (t - 1.5)), Vector3.ZERO), Vector3(0.04, 1.1, 0.04), "bois", 1.0)
		if t % 2 == 0:
			k.box(R.L(-hw + 0.1, 1.95, tz), Vector3(0.05, 0.05, 0.42), "fer", 1.0)
		else:
			k.box(R.L(-hw + 0.1, 0.88, tz), Vector3(0.04, 0.24, 0.2), "fer", 1.0)
	R.mark_wall(-hw, 1.5, -hd + 3.0, 1.2)
	var pm: String = _img(R, "plan_mine170", "beau170/plan_mine.png")
	_cadre(R, pm, hw - 0.02, 1.75, -hd + 2.8, -90.0, 1.3, 0.95)
	# le wagonnet de minerai sur son bout de rail, les sacs, le tamis
	var wx: float = hw - 1.4
	var wz: float = hd - 2.4
	for rx in [-0.28, 0.28]:
		k.box(R.L(wx + rx, 0.03, wz), Vector3(0.05, 0.06, 2.6), "fer", 1.0)
	for tr in range(6):
		k.box(R.L(wx, 0.02, wz - 1.1 + tr * 0.44), Vector3(0.9, 0.04, 0.12), "bois_sombre", 1.0)
	k.box(R.L(wx, 0.5, wz), Vector3(0.8, 0.55, 1.0), "fer", 1.0)
	k.box(R.L(wx, 0.78, wz), Vector3(0.7, 0.06, 0.9), _c(R, "minerai170", Color(0.35, 0.32, 0.3), 0.95), 1.0)
	for g in range(7):
		k.box(R.L(wx - 0.25 + 0.08 * g, 0.83, wz - 0.3 + 0.1 * float(g % 3)), Vector3(0.1, 0.08, 0.1), "minerai170" if g % 3 else or_m, 1.0)
	for wh in [[-0.33, -0.3], [0.33, -0.3], [-0.33, 0.3], [0.33, 0.3]]:
		k.cyl(R.L(wx + float(wh[0]), 0.13, wz + float(wh[1])) * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3.ZERO), 0.12, 0.12, 0.05, "fer", 12)
	k.col_box(R.L(wx, 0.5, wz), Vector3(0.85, 1.0, 1.05))
	R.reserve(wx, wz, 1.1, 2.8)
	for s in range(2):
		_sac(R, -hw + 0.8 + s * 0.55, hd - 1.4, Color(0.4, 0.38, 0.35), 0.85)
	for lx in [-1.8, 1.8]:
		_lanterne(M, lx, 0.3)
	var lignes: Array = ["J'ai trouvé ma première pépite à six ans. Je la cherche encore, la deuxième.", "De l'or, de l'or ! Enfin… surtout du caillou.", "Montre-moi ce que tu as trouvé !"]
	_marchand(M, 0.6, zc - 0.55, 0.0, "comptoir", "vieux", "le vieux Gédéon", lignes, {"vend": {"pelle": 8, "galette_mais": 3}, "achete": {"pepite_or": 8, "minerai_fer": 3, "eclat_cristal": 7}})
	_clients(M, [["homme", -1.4, zc + 1.2, 160.0, "observer", ["Il paraît qu'il y a un filon sous la Fosse aux Dés…"]]])
	M.ctx["bonjour170"] = ["Entre, chercheur d'or !", "Bienvenue au Comptoir ! Tu as trouvé quelque chose ?"]
	M.ctx["entree"] = "Le Comptoir des Prospecteurs : la balance à pépites, les pioches au mur, le plan de la mine, et un wagonnet plein de cailloux."


# =================================================================== le chapelier (Fanchon) ; la couture (Grisette, Colombe)

## Un mannequin de couturière (le buste, la jupe, le pied) habillé d'un tissu.
static func _mannequin(R, x: float, z: float, yaw: float, c: Color) -> void:
	var k = R.kit
	var xf: Transform3D = R.L(x, 0, z, yaw)
	var t: String = _c(R, "robe_%s" % c.to_html(false), c, 0.9)
	k.cyl(xf, 0.2, 0.22, 0.04, "bois_sombre", 12)
	k.cyl(xf * T3(0, 0.04, 0), 0.02, 0.02, 0.5, "bois_sombre", 6)
	k.cyl(xf * T3(0, 0.5, 0), 0.38, 0.17, 0.55, t, 16)
	k.cyl(xf * T3(0, 1.05, 0), 0.17, 0.14, 0.2, t, 14)
	k.cyl(xf * T3(0, 1.25, 0), 0.14, 0.18, 0.2, t, 14)
	k.cyl(xf * T3(0, 1.45, 0), 0.18, 0.06, 0.1, t, 14)
	k.cyl(xf * T3(0, 1.55, 0), 0.03, 0.03, 0.08, "bois", 6)
	k.cyl(xf * T3(0, 1.63, 0), 0.05, 0.02, 0.06, "bois", 8)
	k.col_box(xf * T3(0, 0.8, 0), Vector3(0.6, 1.6, 0.6))
	R.reserve(x, z, 0.8, 0.8)


## Une machine à coudre sur sa table (le pied en fonte, le volant, la pédale).
static func _machine_coudre(R, x: float, z: float, yaw: float) -> Transform3D:
	var k = R.kit
	var xf: Transform3D = R.L(x, 0, z, yaw)
	k.box(xf * T3(0, 0.76, 0), Vector3(1.0, 0.04, 0.5), "bois", 1.0)
	for sx in [-1.0, 1.0]:
		k.box(xf * T3(sx * 0.42, 0.37, 0), Vector3(0.05, 0.74, 0.4), "fer", 1.0)
	k.box(xf * T3(0, 0.12, 0.05), Vector3(0.4, 0.03, 0.25), "fer", 1.0)
	k.cyl(xf * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(0.42, 0.4, 0)), 0.22, 0.22, 0.03, "fer", 18, false)
	k.box(xf * T3(-0.05, 0.84, 0), Vector3(0.5, 0.12, 0.14), "noir", 1.0)
	k.box(xf * T3(0.16, 0.98, 0), Vector3(0.12, 0.3, 0.13), "noir", 1.0)
	k.box(xf * T3(-0.02, 1.1, 0), Vector3(0.42, 0.1, 0.12), "noir", 1.0)
	k.box(xf * T3(-0.2, 0.95, 0), Vector3(0.06, 0.2, 0.06), "noir", 1.0)
	k.cyl(xf * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(0.24, 1.0, 0)), 0.07, 0.07, 0.03, "argent", 14)
	k.box(xf * T3(-0.1, 1.155, 0), Vector3(0.3, 0.008, 0.02), "or", 1.0)
	k.box(xf * T3(-0.35, 0.785, 0.05), Vector3(0.3, 0.01, 0.35), _c(R, "tissu_ouvrage", Color(0.6, 0.15, 0.25), 0.95), 1.0)
	k.col_box(xf * T3(0, 0.6, 0), Vector3(1.0, 1.2, 0.5))
	R.reserve(x, z, 1.2, 0.7)
	return xf


static func _chapelier(M) -> void:
	var R = M.R
	var k = R.kit
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var st: String = str(M.cur.get("style", ""))
	var couture: bool = str(M.cur.get("metier", "")) == "couture"
	var zc: float = -hd + 1.85
	if couture:
		_rayons(M, -hw + 1.0, -hd + 0.22, 0.0, 1.35, 2.2, 4, "tissus", 0)
		_rayons(M, -hw + 2.45, -hd + 0.22, 0.0, 1.35, 2.2, 4, "tissus", 3)
		_rayons(M, hw - 0.9, -hd + 0.22, 0.0, 1.35, 2.2, 4, "tissus", 5)
		# la grande table de coupe, le tissu déplié, les ciseaux, le mètre
		var tx: float = 0.9
		R.table(tx, zc, 0.0, 2.4, 1.0, 0.9)
		k.box(R.L(tx - 0.2, 0.91, zc, 4.0), Vector3(1.6, 0.006, 0.8), _c(R, "tissu_coupe", Color(0.25, 0.32, 0.6) if st == "montjoie" else Color(0.5, 0.08, 0.15), 0.95), 1.0)
		k.box(R.L(tx + 0.7, 0.925, zc + 0.1, 30.0), Vector3(0.22, 0.012, 0.03), "argent", 1.0)
		k.box(R.L(tx + 0.75, 0.925, zc + 0.15, -20.0), Vector3(0.22, 0.012, 0.03), "argent", 1.0)
		k.box(R.L(tx - 0.3, 0.92, zc - 0.32, 0.0), Vector3(1.4, 0.004, 0.02), _c(R, "metre_ruban", Color(0.95, 0.85, 0.3), 0.6), 1.0)
		# le mur des bobines de fil
		var B: Transform3D = R.L(hw - 0.03, 1.5, hd - 2.6, -90.0)
		k.box(B * T3(0, 0, 0.02), Vector3(1.2, 0.9, 0.03), "bois", 1.0)
		for i in range(8):
			for j in range(5):
				var c: Color = Color.from_hsv(float(i * 5 + j) / 40.0, 0.7, 0.85)
				k.cyl(B * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(-0.5 + i * 0.14, -0.33 + j * 0.165, 0.07)), 0.035, 0.035, 0.07, _c(R, "fil_%d" % ((i * 5 + j) % 12), Color.from_hsv(float((i * 5 + j) % 12) / 12.0, 0.7, 0.85), 0.8), 10)
		R.mark_wall(hw, 1.5, hd - 2.6, 0.7)
		_machine_coudre(R, -hw + 0.9, 0.2, 90.0)
		R.chaise(-hw + 1.55, 0.2, -90.0)
		_mannequin(R, -1.6, 1.2, 160.0, Color(0.55, 0.1, 0.18) if st == "braise" else Color(0.85, 0.75, 0.55))
		_mannequin(R, 1.9, 1.4, 200.0, Color(0.15, 0.12, 0.2) if st == "braise" else Color(0.35, 0.55, 0.7))
		# la cabine d'essayage : la tringle, le rideau
		var cz: float = hd - 1.5
		k.cyl(R.L(hw - 0.75, R.H - 0.9, cz) * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 0.015, 0.015, 1.4, "or", 6)
		for f2 in range(7):
			k.cyl(R.L(hw - 1.3 + f2 * 0.18, 0.05, cz - 0.7 + 0.04 * float(f2 % 2)), 0.06, 0.06, R.H - 0.95, _c(R, "rideau_cabine", Color(0.45, 0.1, 0.18) if st == "braise" else Color(0.2, 0.35, 0.3), 0.95), 8)
		k.col_box(R.L(hw - 0.75, 1.2, cz - 0.7), Vector3(1.4, 2.4, 0.15))
		R.reserve(hw - 0.75, cz, 1.6, 1.6)
	else:
		for i2 in range(3):
			_rayons(M, -hw + 1.0 + i2 * 1.45, -hd + 0.22, 0.0, 1.35, 2.2, 5, "chapeaux", i2 * 2)
		_rayons(M, hw - 0.9, -hd + 0.22, 0.0, 1.35, 2.2, 5, "chapeaux", 7)
		# les têtes à chapeaux, sur le comptoir et sur des colonnes
		var cx: Transform3D = _comptoir(M, 0.8, zc, 2.6, 0.0, true)
		for t in range(4):
			var px: float = -1.6 + t * 1.2
			if absf(px) < 0.9:
				continue
			var pz: float = 0.7 + 0.4 * float(t % 2)
			k.cyl(R.L(px, 0, pz), 0.18, 0.18, 0.04, "bois_sombre", 12)
			k.cyl(R.L(px, 0.04, pz), 0.05, 0.05, 1.2, "bois_sombre", 8)
			Sud._boule(M.room, R.mat("ceramique"), R.P(px, 1.38, pz), 0.12, Vector3(0.9, 1.1, 0.95))
			_chapeau(R, R.L(px, 1.47, pz, t * 40.0), ["haut", "stetson", "pointu", "stetson"][t], [Color(0.12, 0.1, 0.1), Color(0.75, 0.6, 0.42), Color(0.45, 0.15, 0.4), Color(0.3, 0.2, 0.15)][t], Color(0.8, 0.65, 0.25))
			k.col_box(R.L(px, 0.7, pz), Vector3(0.36, 1.4, 0.36))
			R.reserve(px, pz, 0.5, 0.5)
		# les cartons à chapeaux empilés, le vase de plumes
		for b in range(5):
			var bz: float = hd - 1.4 - 0.1 * float(b % 2)
			var bx: float = -hw + 0.6 + 0.08 * float(b % 2)
			k.cyl(R.L(bx, 0.32 * b, bz), 0.28 - 0.03 * b, 0.28 - 0.03 * b, 0.3, _c(R, "carton_%d" % (b % 3), [Color(0.85, 0.6, 0.65), Color(0.6, 0.75, 0.85), Color(0.95, 0.9, 0.75)][b % 3], 0.8), 18)
			k.cyl(R.L(bx, 0.32 * b + 0.28, bz), 0.29 - 0.03 * b, 0.29 - 0.03 * b, 0.04, "carton", 18)
		k.col_box(R.L(-hw + 0.6, 0.8, hd - 1.4), Vector3(0.6, 1.6, 0.6))
		R.reserve(-hw + 0.6, hd - 1.4, 0.8, 0.8)
		k.cyl(R.L(hw - 0.6, 0, hd - 1.4), 0.12, 0.16, 0.5, "ceramique", 14)
		for f in range(7):
			var a: float = TAU * f / 7.0
			k.box(R.L(hw - 0.6 + cos(a) * 0.05, 0.85, hd - 1.4 + sin(a) * 0.05) * Transform3D(Basis(Vector3(sin(a), 0, -cos(a)), 0.25), Vector3.ZERO), Vector3(0.05, 0.75, 0.01), _c(R, "plume_%d" % (f % 4), [Color(0.9, 0.15, 0.2), Color(0.1, 0.6, 0.5), Color(0.95, 0.85, 0.3), Color(0.2, 0.2, 0.25)][f % 4], 0.8), 1.0)
		R.reserve(hw - 0.6, hd - 1.4, 0.5, 0.5)
	# le grand miroir (la psyché)
	var mx: float = -hw + 0.35
	var mz: float = -hd + 3.1
	k.box(R.L(mx, 1.0, mz, 90.0), Vector3(0.75, 1.8, 0.05), "bois_sombre", 1.0)
	k.box(R.L(mx + 0.03, 1.0, mz, 90.0), Vector3(0.62, 1.66, 0.01), _c(R, "miroir170", Color(0.62, 0.68, 0.72), 0.04, 0.95), 1.0)
	R.mark_wall(-hw, 1.0, mz, 0.45)
	R.reserve(mx, mz, 0.5, 0.9)
	var essayer := func() -> void:
		M.say(str(_pick(M, ["Tu te regardes dans la glace. Pas mal du tout. Le chapeau en plus, ce serait parfait.", "Dans le miroir, quelqu'un te sourit. C'est toi. Avec un air très élégant, aujourd'hui.", "Tu prends la pose. Le miroir est d'accord : tu as de l'allure."] if not couture else ["Tu tiens un tissu devant toi, dans le miroir. Le rouge te va bien. Le bleu aussi. Le choix est difficile.", "Le miroir te montre avec une cape imaginaire. Grandiose."])), 5.0)
	M.act(R.P(mx + 0.7, 0, mz), "E : se regarder dans le miroir", essayer, 1.0)
	var lignes: Array = ["Un chapeau, c'est une humeur qu'on porte sur la tête.", "Tourne-toi… Voilà ! Celui-là est fait pour toi.", "Les plumes, c'est pour les jours de fête. Donc tous les jours."]
	var menu: Dictionary = {"vend": {"chapeau_stetson": 25, "chapeau_ventilateur": 22, "plume_perroquet": 6}, "achete": {"plume_ara": 5, "plume_corbeau": 3}}
	if couture:
		lignes = ["Une robe, un manteau, une cape ? Tout se coud, tout se recoud.", "Tiens-toi droit, je prends tes mesures !", "Ce tissu vient de très loin. Enfin, du marché."]
		menu = {"vend": {"corde_chanvre": 4}, "achete": {"toile_voile": 3, "plume_ara": 5}, "bonjour": "Bienvenue à l'atelier ! Une retouche ? Un ourlet ?"}
		_marchand(M, 0.9, zc - 0.65, 0.0, "bricoler", "femme", "Madame Aiguille", lignes, menu)
	else:
		_marchand(M, 0.8, zc - 0.55, 0.0, "comptoir", "femme", "Fanchon", lignes, menu)
	_clients(M, [["femme", 0.2, 1.4, 150.0, "observer", ["Le bleu ou le rouge ? Le rouge ou le bleu ?"]]])
	M.ctx["bonjour170"] = ["Bienvenue ! Essaie tout ce que tu veux.", "Entre ! Le miroir est à gauche."] if not couture else ["Bonjour ! Attention aux épingles par terre.", "Entre ! Je finis cet ourlet et je suis à toi."]
	M.ctx["entree"] = ("%s : des chapeaux du sol au plafond, des têtes de bois coiffées, des cartons à rubans, un grand miroir." if not couture else "%s : les rouleaux de tissu, la machine à coudre, les mannequins habillés, le mur des bobines de fil.") % str(M.cur.get("enseigne170", "La boutique"))


# =================================================================== la sellerie des Éperons (Pile-ou-Face)

## Une selle de cow-boy sur son chevalet.
static func _selle(R, x: float, z: float, yaw: float, c: Color) -> void:
	var k = R.kit
	var xf: Transform3D = R.L(x, 0, z, yaw)
	for sx in [-0.45, 0.45]:
		k.box(xf * Transform3D(Basis(Vector3.RIGHT, 0.28), Vector3(sx, 0.4, -0.11)), Vector3(0.06, 0.85, 0.06), "bois_sombre", 1.0)
		k.box(xf * Transform3D(Basis(Vector3.RIGHT, -0.28), Vector3(sx, 0.4, 0.11)), Vector3(0.06, 0.85, 0.06), "bois_sombre", 1.0)
	k.box(xf * T3(0, 0.82, 0), Vector3(1.1, 0.08, 0.1), "bois", 1.0)
	var cuir: String = _c(R, "cuir_%s" % c.to_html(false), c, 0.6)
	k.box(xf * T3(0, 0.9, 0), Vector3(0.6, 0.06, 0.42), cuir, 1.0)
	k.box(xf * Transform3D(Basis(Vector3.BACK, 0.35), Vector3(-0.32, 0.94, 0)), Vector3(0.14, 0.06, 0.4), cuir, 1.0)
	k.box(xf * Transform3D(Basis(Vector3.BACK, -0.3), Vector3(0.3, 0.97, 0)), Vector3(0.12, 0.08, 0.38), cuir, 1.0)
	k.cyl(xf * T3(0.33, 1.0, 0), 0.035, 0.03, 0.12, cuir, 8)
	k.cyl(xf * T3(0.33, 1.12, 0), 0.05, 0.05, 0.02, cuir, 10)
	for sz in [-1.0, 1.0]:
		k.box(xf * T3(0, 0.72, sz * 0.24), Vector3(0.44, 0.34, 0.02), cuir, 1.0)
		k.box(xf * T3(0, 0.52, sz * 0.25), Vector3(0.03, 0.4, 0.01), cuir, 1.0)
		k.ring(xf * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0.3, sz * 0.25)), 0.05, 0.065, 0.06, "bois_sombre", 10)
	k.col_box(xf * T3(0, 0.55, 0), Vector3(1.1, 1.1, 0.6))
	R.reserve(x, z, 1.3, 0.8)


static func _sellerie(M) -> void:
	var R = M.R
	var k = R.kit
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var cuirs: Array = [Color(0.45, 0.24, 0.12), Color(0.3, 0.16, 0.08), Color(0.6, 0.38, 0.2)]
	for s in range(3):
		_selle(R, -1.8 + s * 1.6, 0.6, 0.0, cuirs[s])
	# les brides, les licols, les sangles, accrochés aux chevilles du mur du fond
	for i in range(7):
		var bx: float = -hw + 0.8 + i * 0.55
		if bx > hw - 2.6:
			break
		k.box(R.L(bx, 2.0, -hd + 0.06), Vector3(0.05, 0.05, 0.12), "bois_sombre", 1.0)
		k.ring(R.L(bx, 1.7, -hd + 0.1) * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 0.12, 0.15, 0.03, "cuir", 14)
		k.box(R.L(bx, 1.35, -hd + 0.1), Vector3(0.04, 0.6, 0.01), "cuir", 1.0)
		k.ring(R.L(bx, 1.05, -hd + 0.1) * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 0.03, 0.04, 0.02, "or", 10)
	R.mark_wall(-hw + 2.4, 1.6, -hd, 2.0)
	# l'établi du sellier : les cuirs, l'alêne, le maillet
	R.etabli(hw - 1.4, -hd + 0.8, 0.0, 2.2)
	for p in range(3):
		k.box(R.L(hw - 1.9 + p * 0.4, 0.93, -hd + 0.7, p * 12.0), Vector3(0.34, 0.01, 0.4), _c(R, "cuir_%s" % (cuirs[p] as Color).to_html(false), cuirs[p], 0.6), 1.0)
	# les bottes (des paires, sur un banc), les éperons dans la vitrine
	R.banc(-hw + 0.5, hd - 2.4, 90.0, 1.8)
	for b in range(3):
		var bz: float = hd - 3.1 + b * 0.55
		for sx in [-0.07, 0.07]:
			k.box(R.L(-hw + 0.5 + sx, 0.62, bz), Vector3(0.1, 0.32, 0.13), "cuir", 1.0)
			k.box(R.L(-hw + 0.5 + sx, 0.48, bz + 0.07), Vector3(0.1, 0.06, 0.26), "cuir", 1.0)
	var zc: float = hd - 2.0
	var cx: Transform3D = _comptoir(M, hw - 1.6, zc, 1.8, -90.0, true)
	for e in range(3):
		k.ring(cx * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(-0.5 + e * 0.5, 1.12, 0.05)), 0.03, 0.045, 0.01, "argent", 10)
		k.box(cx * T3(-0.5 + e * 0.5 + 0.06, 1.12, 0.05), Vector3(0.1, 0.012, 0.02), "argent", 1.0)
	var corde: String = _tex(R, "corde170", "beau161/corde.png", Color(0.9, 0.8, 0.62))
	for l in range(3):
		k.ring(R.L(hw - 0.12, 1.8, -hd + 3.0 + l * 0.5, -90.0) * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 0.14, 0.22, 0.05, corde, 18)
	R.mark_wall(hw, 1.8, -hd + 3.5, 0.8)
	var lignes: Array = ["Une bonne selle, c'est dix ans de voyages sans mal de dos.", "Le cuir, ça se nourrit. Comme les chevaux.", "Ces éperons-là ? Ils chantent quand on marche."]
	var cirer := func() -> void:
		var inv: Node = M.main.get("inventory_v28")
		var p2: int = _prix(M, 2)
		if inv != null and int(inv.count("piece")) >= p2:
			inv.remove("piece", p2)
			_menu(M, M.ctx["marchand"], M.ctx["menu170"], "Frotte, frotte, frotte… Voilà ! Elles brillent tant que tu vas te voir dedans.")
		else:
			_menu(M, M.ctx["marchand"], M.ctx["menu170"], "Deux pièces, et tes bottes brilleront comme des sous neufs. Il t'en manque un peu.")
	var menu := {"bonjour": "Bienvenue à la Sellerie des Éperons ! Une selle ? Un lasso ? Des bottes ?",
		"vend": {"corde_chanvre": 4}, "achete": {"vieille_botte": 1},
		"services": [{"label": "Cirer mes bottes (2 pièces).", "cb": cirer}],
		"infos": ["Les selles d'ici viennent toutes de l'Écurie du Grand Galop, juste à côté. Les chevaux les essaient avant toi.", "Le lasso ? C'est un art. Il faut viser, tourner, lancer… et ne jamais attraper son propre chapeau."]}
	M.ctx["menu170"] = menu
	_marchand(M, hw - 1.05, zc, -90.0, "comptoir", "homme", "Josué Lanière", lignes, menu)
	M.ctx["bonjour170"] = ["Bienvenue ! Ça sent bon le cuir, hein ?", "Entre ! Attention à la selle du milieu, elle mord."]
	M.ctx["entree"] = "La Sellerie des Éperons : des selles sur leurs chevalets, des brides aux chevilles, l'odeur du cuir neuf."


# =================================================================== l'Écurie du Grand Galop (Pile-ou-Face)

## Un cheval (la bête de la faune, immobile, dans sa stalle) ; sinon rien.
static func _cheval(M, x: float, z: float, yaw: float, nom: String) -> void:
	var path: String = "res://scripts/monstre_v140.gd"
	if not ResourceLoader.exists(path):
		return
	var b: Node = (load(path) as Script).new()
	M.room.add_child(b)
	if "ile_sol" in b:
		b.set("ile_sol", "-")
	b.setup(null, "cheval_sauvage", M.R.P(x, 0, z))
	b.set_physics_process(false)
	b.set_process(false)
	for g in ["cibles_v28", "faune_v132"]:
		if b.is_in_group(g):
			b.remove_from_group(g)
	(b as Node3D).rotation.y = deg_to_rad(yaw)
	var piv: Variant = b.get("_pivots")
	if piv is Dictionary and (piv as Dictionary).get("tete", null) is Node3D:
		((piv as Dictionary)["tete"] as Node3D).rotation.x = -0.2
	var cav := func() -> void:
		M.main.sfx("cheval_hennit", (b as Node3D).global_position + Vector3.UP)
		M.say(str(_pick(M, ["%s souffle doucement dans ta main. Il aime bien qu'on lui gratte le front." % nom, "%s pose sa grosse tête sur ton épaule. C'est un câlin de cheval." % nom, "%s renifle tes poches. Il cherche une pomme, ce gourmand." % nom])), 5.0)
	var face: Vector3 = Basis(Vector3.UP, deg_to_rad(yaw)) * Vector3(0, 0, 1)
	M.act(M.R.P(x, 0, z) + face * 1.6, "E : caresser %s" % nom, cav, 1.2)


static func _ecurie(M) -> void:
	var R = M.R
	var k = R.kit
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var foin: String = _tex(R, "foin170", "beau161/foin_rond.png", Color(0.95, 0.85, 0.55))
	var planche: String = "bois"
	# les stalles, de part et d'autre de l'allée : les cloisons, les barreaux, les portillons
	var aw: float = 1.6
	var sd: float = hw - aw
	var nstalle: int = 3
	var sl: float = (R.D - 2.6) / nstalle
	var noms: Array = ["Tonnerre", "Biscotte", "Poussière", "Caramel", "Mistral", "Plume"]
	for side in [-1.0, 1.0]:
		for i in range(nstalle + 1):
			var z: float = -hd + i * sl
			var cx: float = side * (aw + sd * 0.5)
			k.box(R.L(cx, 0.7, z), Vector3(sd, 1.4, 0.08), planche, 1.0)
			for b in range(int(sd / 0.2)):
				k.cyl(R.L(side * (aw + 0.1 + b * 0.2), 1.4, z), 0.015, 0.015, 0.7, "fer", 6)
			k.box(R.L(cx, 2.1, z), Vector3(sd, 0.06, 0.1), "bois_sombre", 1.0)
			k.col_box(R.L(cx, 1.05, z), Vector3(sd, 2.1, 0.1))
		for i2 in range(nstalle):
			var z0: float = -hd + i2 * sl
			var zm: float = z0 + sl * 0.5
			# le portillon (côté allée), les gonds
			var px: float = side * aw
			k.box(R.L(px, 0.65, z0 + sl * 0.25), Vector3(0.08, 1.3, sl * 0.5 - 0.05), "bois_sombre", 1.0)
			k.box(R.L(px, 0.65, z0 + sl * 0.75), Vector3(0.08, 1.3, sl * 0.5 - 0.05), planche, 1.0)
			k.box(R.L(px, 1.32, zm), Vector3(0.12, 0.05, sl), "bois_sombre", 1.0)
			k.col_box(R.L(px, 0.7, zm), Vector3(0.12, 1.4, sl))
			# le râtelier à foin, l'auge, le seau
			var rx: float = side * (hw - 0.3)
			k.box(R.L(rx, 1.5, zm), Vector3(0.4, 0.5, sl * 0.6), "bois_sombre", 1.0)
			k.box(R.L(rx - side * 0.05, 1.78, zm), Vector3(0.35, 0.12, sl * 0.55), foin, 1.0)
			k.box(R.L(rx, 0.4, zm + sl * 0.25), Vector3(0.4, 0.25, 0.5), "bois", 1.0)
			k.cyl(R.L(rx - side * 0.1, 0, zm - sl * 0.3), 0.14, 0.12, 0.3, "metal", 12)
			# la paille au sol
			k.box(R.L(side * (aw + sd * 0.5), 0.02, zm), Vector3(sd - 0.1, 0.04, sl - 0.1), foin, 2.0)
			R.reserve(side * (aw + sd * 0.5), zm, sd, sl)
			# un cheval (dans deux stalles sur trois), la tête vers l'allée
			var n_i: int = i2 + (0 if side < 0 else nstalle)
			if n_i % 3 != 2:
				_cheval(M, side * (aw + sd * 0.5 - 0.1), zm, -90.0 * side, str(noms[n_i]))
			_ecrit(M, side * (aw + 0.05), 1.55, zm, -90.0 * side, str(noms[n_i]).to_upper(), 30, Color(0.95, 0.88, 0.7), 0.003)
	# les bottes de foin près de la porte, la fourche, la brouette, les lanternes de l'allée
	for hb in range(3):
		k.box(R.L(hw - 0.8, 0.25 + 0.5 * float(hb == 2), hd - 0.9 - 0.95 * float(hb == 1) - 0.45 * float(hb == 2)), Vector3(0.9, 0.5, 0.6), foin, 1.0)
	k.col_box(R.L(hw - 0.8, 0.5, hd - 1.3), Vector3(0.9, 1.0, 1.6))
	R.reserve(hw - 0.8, hd - 1.3, 1.0, 1.8)
	k.box(R.L(-hw + 0.4, 0.8, hd - 0.9) * Transform3D(Basis(Vector3.RIGHT, 0.15), Vector3.ZERO), Vector3(0.04, 1.6, 0.04), "bois", 1.0)
	for t in range(3):
		k.box(R.L(-hw + 0.37 + t * 0.03, 1.62, hd - 0.78), Vector3(0.012, 0.3, 0.012), "fer", 1.0)
	_selle(R, -hw + 0.9, hd - 1.9, 90.0, Color(0.45, 0.24, 0.12))
	for lz in range(nstalle):
		_lanterne(M, 0.0, -hd + (lz + 0.5) * sl, R.H - 1.2)
	_lampe(M, 0.0, R.H - 1.4, 0.0, Color(1.0, 0.8, 0.5), 0.8, 7.0)
	var pomme := func() -> void:
		var inv: Node = M.main.get("inventory_v28")
		if inv != null and int(inv.count("pomme")) > 0:
			inv.remove("pomme", 1)
			M.main.sfx("cheval_hennit")
			var st2: Dictionary = M.state()
			if not bool(st2.get("pomme170", false)):
				st2["pomme170"] = true
				_menu(M, M.ctx["marchand"], M.ctx["menu170"], "Croc ! Biscotte a tout mangé, même le trognon. Tiens, pour la peine : un coup de main, ça se paie.")
				M.give([["piece", 5]], "")
			else:
				_menu(M, M.ctx["marchand"], M.ctx["menu170"], "Croc ! Encore une pomme engloutie. Ils t'adorent, maintenant.")
		else:
			_menu(M, M.ctx["marchand"], M.ctx["menu170"], "Une pomme ? Il faudrait d'abord en avoir une. Il y en a chez Rosemonde, à l'épicerie.")
	var menu := {"bonjour": "Bienvenue à l'Écurie du Grand Galop ! On ne court pas, on ne crie pas : les chevaux font la sieste.",
		"services": [{"label": "Donner une pomme aux chevaux.", "cb": pomme}],
		"infos": ["Tonnerre est le plus rapide de l'île. Biscotte, la plus gourmande. Poussière… Poussière dort. Tout le temps.", "Ici, les chevaux montent jusqu'au corral, au bout de la rue. Le dimanche, il y a la course : on parie des carottes."]}
	M.ctx["menu170"] = menu
	_marchand(M, 0.4, hd - 2.6, 180.0, "jardiner", "homme", "Basile Crin", ["Tout doux, Tonnerre, tout doux…", "Un cheval content, c'est un cheval qui mange.", "La paille ne se change pas toute seule. Malheureusement."], menu)
	M.ctx["cloche170"] = false
	M.ctx["bonjour170"] = ["Salut ! Doucement, les chevaux se reposent.", "Bienvenue à l'écurie ! Viens dire bonjour."]
	M.ctx["entree"] = "L'Écurie du Grand Galop : l'odeur du foin, l'allée entre les stalles, des chevaux qui tournent la tête vers toi."


# =================================================================== l'Horlogerie Tic & Tac (Gédéon Tic)

static func _horloger(M) -> void:
	var R = M.R
	var k = R.kit
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var zc: float = -hd + 1.8
	# le mur des horloges, au fond : toutes les tailles, deux pendules qui battent
	var places: Array = [[-2.8, 2.3, 0.3, false], [-1.9, 1.6, 0.22, false], [-1.0, 2.5, 0.38, true], [0.2, 2.0, 0.25, false], [0.9, 2.6, 0.2, false],
		[1.7, 2.1, 0.34, true], [2.8, 2.4, 0.26, false], [-2.6, 1.3, 0.18, false], [2.7, 1.5, 0.2, false]]
	for p in places:
		if absf(float(p[0])) > hw - 0.4:
			continue
		_horloge(M, float(p[0]), float(p[1]) if not bool(p[3]) else float(p[1]) + 0.2, -hd + 0.03, 0.0, float(p[2]), bool(p[3]), "or" if int(float(p[0]) * 10) % 3 == 0 else "bois_sombre")
	R.horloge(-hw + 0.4, -hd + 1.8, 90.0)
	R.horloge(hw - 0.4, -hd + 1.8, -90.0)
	# la vitrine des montres (le comptoir)
	var cx: Transform3D = _comptoir(M, 0.0, zc, 2.6, 0.0, true)
	for m in range(6):
		var mxp: float = -1.0 + m * 0.4
		k.cyl(cx * Transform3D(Basis(Vector3.RIGHT, -0.3), Vector3(mxp, 1.1, 0.05)), 0.05, 0.05, 0.015, "or" if m % 2 == 0 else "argent", 16)
		k.cyl(cx * Transform3D(Basis(Vector3.RIGHT, -0.3), Vector3(mxp, 1.112, 0.052)), 0.042, 0.042, 0.003, "ceramique", 16)
		k.box(cx * T3(mxp + 0.08, 1.09, 0.05), Vector3(0.12, 0.006, 0.01), "or" if m % 2 == 0 else "argent", 1.0)
	# l'établi de Gédéon : la loupe sur son bras, les rouages éparpillés, une montre ouverte
	var ex: float = -hw + 1.4
	var ez: float = hd - 2.2
	R.etabli(ex, ez, 90.0, 1.8)
	for g in range(9):
		k.cyl(R.L(ex + 0.1 * cos(g * 1.7), 0.93, ez - 0.4 + 0.1 * g), 0.015 + 0.01 * float(g % 3), 0.015 + 0.01 * float(g % 3), 0.006, "or" if g % 2 else "cuivre", 10)
	k.cyl(R.L(ex - 0.2, 0.92, ez + 0.4), 0.025, 0.025, 0.4, "or", 6)
	k.box(R.L(ex - 0.05, 1.3, ez + 0.4) * Transform3D(Basis(Vector3.BACK, -0.8), Vector3.ZERO), Vector3(0.02, 0.35, 0.02), "or", 1.0)
	k.ring(R.L(ex + 0.08, 1.25, ez + 0.4) * Transform3D(Basis(Vector3.BACK, 0.6), Vector3.ZERO), 0.06, 0.075, 0.015, "or", 16)
	k.cyl(R.L(ex + 0.08, 1.25, ez + 0.4) * Transform3D(Basis(Vector3.BACK, 0.6), Vector3.ZERO), 0.06, 0.06, 0.006, _verre(R, "loupe170", Color(0.9, 0.95, 1.0), 0.25), 16)
	# la grande mécanique au mur de droite : trois rouages qui s'engrènent
	var mat_or: Material = R.mat("or")
	var mat_cu: Material = R.mat("cuivre")
	var gx: float = hw - 0.08
	var gb: Basis = Basis(Vector3.UP, deg_to_rad(-90.0)) * Basis(Vector3.RIGHT, PI * 0.5)
	_engrenage(M, R.P(gx, 1.9, -hd + 3.3), gb, 0.42, 16, 0.04, 0.5, mat_or)
	_engrenage(M, R.P(gx, 1.62, -hd + 3.3 + 0.62), gb, 0.2, 8, 0.04, -1.0, mat_cu)
	_engrenage(M, R.P(gx, 2.3, -hd + 3.3 - 0.6), gb, 0.22, 9, 0.04, -0.9, mat_cu)
	R.mark_wall(hw, 1.9, -hd + 3.3, 1.0)
	var tick := func(delta: float) -> void:
		var tt: float = float(M.ctx.get("tic_t", 1.0)) - delta
		if tt <= 0.0:
			tt = 1.05
			M.main.sfx("roue_tic", M.R.P(0, 2.2, -M.R.D * 0.5 + 0.3), -20.0)
		M.ctx["tic_t"] = tt
	M.ctx["tick170"] = tick
	var lignes: Array = ["Tic… tac… tic… Pardon, c'est une manie.", "Cette montre-là tourne à l'envers. Elle a toujours une heure d'avance sur hier.", "Une seconde ! Non, deux. Ça y est."]
	_marchand(M, 0.0, zc - 0.55, 0.0, "comptoir", "vieux", "Maître Tic", lignes, {"vend": {"montre_envers": 14, "ressort": 2, "engrenage": 3}, "achete": {"engrenage": 2, "ressort": 1}})
	M.ctx["bonjour170"] = ["Pile à l'heure ! Bienvenue.", "Entre ! Tu es en avance… ou en retard ? Peu importe."]
	M.ctx["entree"] = "L'Horlogerie Tic & Tac : un mur entier d'horloges, des balanciers qui battent, des rouages qui tournent, et le tic-tac partout."


# =================================================================== le Théâtre des Mirages (Pile-ou-Face)

const SCENE_THEATRE := [
	[0.5, "acteur", "Ô cactus doré, toi qui brilles au loin… es-tu un mirage ?", "joie"],
	[4.5, "actrice", "Ce n'est pas un mirage, cow-boy. C'est la lampe du saloon.", "rire"],
	[8.5, "acteur", "Alors… j'ai traversé tout le désert pour rien ?", "colere"],
	[12.5, "actrice", "Pour rien ? Tu m'as trouvée, moi !", "joie"],
	[16.5, "metteur", "Coupez ! Magnifique ! On la refait avec plus de poussière !", "applaudir"],
]


static func _theatre(M) -> void:
	var R = M.R
	var k = R.kit
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	# la scène : le plancher surélevé, le cadre doré, les rideaux de velours, la rampe
	var sz: float = 4.0
	var sh: float = 1.0
	var sw: float = R.W - 1.0
	k.box(R.L(0, sh * 0.5, -hd + sz * 0.5), Vector3(sw, sh, sz), "bois_sombre", 1.0)
	k.box(R.L(0, sh + 0.02, -hd + sz * 0.5), Vector3(sw, 0.04, sz), "sol", 2.0)
	k.box(R.L(0, sh * 0.5, -hd + sz + 0.01), Vector3(sw, sh, 0.02), _c(R, "velours_scene", Color(0.35, 0.04, 0.06), 0.95), 1.0)
	k.col_box(R.L(0, sh * 0.5, -hd + sz * 0.5), Vector3(sw, sh, sz))
	R.reserve(0, -hd + sz * 0.5, sw, sz + 0.2)
	for st in range(4):
		k.box(R.L(-hw + 1.0, (st + 1) * 0.125, -hd + sz + 0.2 + (3 - st) * 0.28), Vector3(0.9, (st + 1) * 0.25, 0.28), "bois_sombre", 1.0)
		k.col_box(R.L(-hw + 1.0, (st + 1) * 0.125, -hd + sz + 0.2 + (3 - st) * 0.28), Vector3(0.9, (st + 1) * 0.25, 0.28))
	var decor: String = _img(R, "decor170", "beau170/decor_theatre.png")
	var dh: float = R.H - sh - 0.4
	k.quad(R.L(0, sh + dh * 0.5, -hd + 0.04) * Transform3D(Basis(Vector3.UP, PI), Vector3.ZERO), sw - 0.6, dh, decor)
	var vel: String = _c(R, "velours_rideau", Color(0.6, 0.05, 0.08), 0.9)
	var top: float = R.H - 0.2
	for side in [-1.0, 1.0]:
		k.box(R.L(side * (sw * 0.5 - 0.15), (sh + top) * 0.5, -hd + sz - 0.1), Vector3(0.3, top - sh, 0.3), "or", 1.0)
		for f in range(6):
			k.cyl(R.L(side * (sw * 0.5 - 0.45 - f * 0.12), sh, -hd + sz - 0.35 + 0.05 * float(f % 2)), 0.08 - 0.004 * f, 0.1, top - sh - 0.4, vel, 8)
		k.cyl(R.L(side * (sw * 0.5 - 0.75), sh + 1.4, -hd + sz - 0.3) * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3.ZERO), 0.02, 0.02, 0.8, "or", 6)
	for v in range(int(sw / 0.25)):
		k.cyl(R.L(-sw * 0.5 + 0.12 + v * 0.25, top - 0.7, -hd + sz - 0.2), 0.12, 0.1, 0.55, vel, 8)
	k.box(R.L(0, top - 0.1, -hd + sz - 0.15), Vector3(sw, 0.25, 0.3), "or", 1.0)
	_ecrit(M, 0, top - 0.1, -hd + sz + 0.0, 0.0, "THÉÂTRE DES MIRAGES", 56, Color(0.35, 0.05, 0.05), 0.0045)
	for fl in range(9):
		var fx: float = -sw * 0.5 + 0.5 + fl * (sw - 1.0) / 8.0
		k.box(R.L(fx, sh + 0.06, -hd + sz - 0.12), Vector3(0.18, 0.1, 0.1), "or", 1.0)
		k.box(R.L(fx, sh + 0.08, -hd + sz - 0.17), Vector3(0.12, 0.06, 0.01), _c(R, "rampe_lumiere", Color(1.0, 0.85, 0.5), 0.5, 0.0, 2.5), 1.0)
	_lampe(M, 0, sh + 0.6, -hd + sz - 0.6, Color(1.0, 0.82, 0.55), 1.8, 6.0)
	_lampe(M, 0, sh + 2.6, -hd + 1.2, Color(1.0, 0.9, 0.75), 1.2, 6.0)
	# les fauteuils des spectateurs, l'allée au milieu
	for row in range(5):
		var rz: float = -hd + sz + 1.4 + row * 1.05
		if rz > hd - 2.0:
			break
		_rangee(R, -hw + 0.8, -1.1, rz, 180.0)
		_rangee(R, 1.1, hw - 0.8, rz, 180.0)
	# la loge des billets, près de la porte
	var bx: float = -hw + 1.0
	var bz: float = hd - 1.2
	k.box(R.L(bx, 0.55, bz), Vector3(1.4, 1.1, 0.9), "bois_sombre", 1.0)
	k.box(R.L(bx, 1.12, bz), Vector3(1.5, 0.05, 1.0), "or", 1.0)
	k.box(R.L(bx, 1.9, bz), Vector3(1.4, 0.06, 0.9), "bois_sombre", 1.0)
	_ecrit(M, bx, 1.5, bz + 0.47, 0.0, "BILLETS", 40, Color(1.0, 0.85, 0.5), 0.0035)
	k.col_box(R.L(bx, 0.95, bz), Vector3(1.4, 1.9, 0.9))
	R.reserve(bx, bz, 1.6, 1.2)
	var aff: String = _img(R, "affiche_theatre170", "beau170/affiche_theatre.png")
	_cadre(R, aff, hw - 0.02, 1.7, hd - 1.8, -90.0, 0.8, 1.15, "or")
	# les comédiens qui répètent, le metteur en scène au premier rang
	var acteur: Node = M.person("homme", -0.9, -hd + 2.0, 20.0, "pointer", "Achille Mirage")
	acteur.npc.global_position += Vector3.UP * sh
	var actrice: Node = M.person("femme", 0.9, -hd + 2.3, -20.0, "debout", "Mimi Poussière")
	actrice.npc.global_position += Vector3.UP * sh
	acteur.lines = ["Ô cactus doré…", "Je n'ai pas soif, je suis assoiffé de gloire !"]
	actrice.lines = ["Plus fort, Achille, plus fort !", "Le saloon, c'est par là !"]
	var lignes: Array = ["Encore ! Avec plus de poussière !", "Silence, on répète !", "Le théâtre, c'est la vie. En mieux éclairé."]
	var voir := func() -> void:
		M.close_talk()
		M.ctx["scene_t"] = 0.0
	var menu := {"bonjour": "Bienvenue au Théâtre des Mirages ! Ce soir : « Le Mirage du Cactus Doré ». On répète encore un peu…",
		"services": [{"label": "Regarder la répétition.", "cb": voir}],
		"infos": ["La troupe joue tous les samedis soir. Le reste de la semaine, on répète, et on se dispute pour savoir qui a le meilleur rôle.", "Le décor ? Peint à la main par toute la troupe. Le cactus doré, c'est Mimi. Le désert, c'est moi. Le ciel, c'est le chat : il a marché dans la peinture bleue."]}
	var directeur: Node = _marchand(M, 0.4, -hd + sz + 0.6, 180.0, "pointer", "homme", "Monsieur Rideau", lignes, menu)
	M.ctx["acteurs170"] = {"acteur": acteur, "actrice": actrice, "metteur": directeur}
	var regarder := func() -> void:
		M.ctx["scene_t"] = 0.0
	M.act(R.P(-1.6, 0, -hd + sz + 1.2), "E : s'asseoir et regarder la répétition", regarder, 1.2)
	var tick := func(delta: float) -> void:
		if not M.ctx.has("scene_t"):
			return
		var t0: float = float(M.ctx["scene_t"])
		var t1: float = t0 + delta
		M.ctx["scene_t"] = t1
		var who: Dictionary = M.ctx["acteurs170"]
		for e in SCENE_THEATRE:
			if t0 < float(e[0]) and t1 >= float(e[0]):
				var f: Variant = who.get(str(e[1]), null)
				if f != null and is_instance_valid(f):
					f.say(str(e[2]), 4.0)
					f.gesture(str(e[3]), 2.5)
				if str(e[1]) == "metteur":
					M.main.sfx("foule_acclame", null, -12.0)
		if t1 > 20.0:
			M.ctx.erase("scene_t")
	M.ctx["tick170"] = tick
	M.ctx["cloche170"] = false
	M.ctx["bonjour170"] = ["Chut ! On répète… Bienvenue, assieds-toi !", "Ah, un spectateur ! Enfin !"]
	M.ctx["entree"] = "Le Théâtre des Mirages : la scène et ses rideaux de velours, le décor du désert, les rangées de fauteuils, la rampe qui brille."


# =================================================================== la gare maritime (Port-Azur)

static func _gare(M) -> void:
	var R = M.R
	var k = R.kit
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	# les guichets, sur le mur de droite
	var G: Transform3D = _guichet(M, hw - 1.1, -0.6, 3.4, 2, -90.0)
	k.box(G * T3(0.9, 1.13, 0.15), Vector3(0.25, 0.02, 0.18), "papier", 1.0)
	_ecrit(M, hw - 1.2, 2.55, -0.6, -90.0, "BILLETS", 48, Color(0.95, 0.85, 0.55), 0.004)
	# le tableau des départs et la grande horloge, au fond
	var tb: String = _img(R, "horaires_azur", "beau170/horaires_azur.png")
	_cadre(R, tb, -0.8, 2.0, -hd + 0.03, 0.0, 3.2, 1.6, "bois_sombre")
	_ecrit(M, -0.8, 2.95, -hd + 0.05, 0.0, "DÉPARTS", 56, Color(0.95, 0.88, 0.6), 0.004)
	_horloge(M, -0.8, R.H - 0.5, -hd + 0.03, 0.0, 0.36, false, "or")
	M.act(R.P(-0.8, 0, -hd + 1.3), "E : lire le tableau des départs", func(): M.say("DÉPARTS — L'Hirondelle, du Capitaine Léon : tous les jours, quand le vent le veut bien. « Retard possible : le capitaine fait la sieste. » À la craie, en bas : « Les îles, c'est par la mer. Ou par le ciel, pour ceux qui ont des ailes. »", 8.0), 1.3)
	# les bancs de la salle d'attente (avec leurs dossiers), on regarde le tableau
	for bz in [-0.4, 1.0]:
		for bx in [-2.6, 0.0]:
			R.banc(bx, bz, 180.0, 2.0)
			k.box(R.L(bx, 0.78, bz + 0.17, 180.0) * Transform3D(Basis(Vector3.RIGHT, -0.15), Vector3.ZERO), Vector3(2.0, 0.5, 0.05), "bois", 1.0)
			R.reserve(bx, bz, 2.2, 0.7)
	# le kiosque à journaux, la balance pèse-personne, les valises, l'affiche du ferry
	var kx: float = -hw + 0.8
	var kz: float = hd - 2.2
	k.box(R.L(kx, 0.5, kz), Vector3(0.8, 1.0, 1.4), "bois", 1.0)
	k.box(R.L(kx + 0.3, 1.02, kz) * Transform3D(Basis(Vector3.BACK, 0.35), Vector3.ZERO), Vector3(0.5, 0.04, 1.3), "bois_sombre", 1.0)
	for j in range(4):
		k.box(R.L(kx + 0.3, 1.08, kz - 0.45 + j * 0.3) * Transform3D(Basis(Vector3.BACK, 0.35), Vector3.ZERO), Vector3(0.36, 0.01, 0.26), "papier", 1.0)
	k.col_box(R.L(kx, 0.5, kz), Vector3(0.8, 1.0, 1.4))
	R.reserve(kx, kz, 1.0, 1.6)
	var px: float = -hw + 0.6
	var pz: float = -hd + 0.6
	k.box(R.L(px, 0.05, pz), Vector3(0.5, 0.1, 0.5), "fer", 1.0)
	k.cyl(R.L(px, 0.1, pz - 0.15), 0.06, 0.05, 1.1, "tissu_rouge", 10)
	k.cyl(R.L(px, 1.3, pz - 0.15) * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 0.18, 0.18, 0.08, _c(R, "peseur", Color(0.7, 0.12, 0.12), 0.4, 0.4), 18)
	k.cyl(R.L(px, 1.3, pz - 0.1) * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 0.14, 0.14, 0.01, "ceramique", 18)
	k.col_box(R.L(px, 0.7, pz), Vector3(0.5, 1.4, 0.5))
	R.reserve(px, pz, 0.7, 0.7)
	M.act(R.P(px + 0.3, 0, pz + 0.6), "E : monter sur la balance", func(): M.say(str(_pick(M, ["Clong ! L'aiguille hésite, tourne, revient… « Un peu plus qu'hier. » Ce sont les croissants de Margaux.", "La balance grince et annonce, sur un petit carton : « Vous allez faire un beau voyage. »", "L'aiguille fait trois tours et s'arrête sur « Poids plume ». Flatteuse, cette balance."])), 5.0), 1.0)
	for v in range(3):
		var vx: float = 2.2 + 0.3 * float(v % 2)
		var vz: float = hd - 1.6 - 0.2 * v
		k.box(R.L(vx, 0.22 + 0.44 * float(v == 2), vz - 0.1 * float(v == 2), 8.0 * v), Vector3(0.65, 0.44, 0.24), ["cuir", "tissu_rouge", "tissu_bleu"][v], 1.0)
	k.col_box(R.L(2.35, 0.45, hd - 1.8), Vector3(0.9, 0.9, 0.6))
	R.reserve(2.35, hd - 1.8, 1.0, 0.8)
	if ResourceLoader.exists("res://assets/textures/azur/affiche_ferry.png"):
		_cadre(R, _img(R, "aff_ferry", "azur/affiche_ferry.png"), -hw + 0.02, 1.7, -0.4, 90.0, 0.8, 1.1)
	_lustre(M, -1.2, 0.3, 0.5, 1.1)
	var menu := {"bonjour": "Gare maritime de Port-Azur, bonjour ! Un renseignement ? Un billet ?",
		"vend": {"carte_postale": 2},
		"infos": ["L'Hirondelle part quand le Capitaine Léon se réveille. C'est-à-dire… assez souvent, quand même.", "De Port-Azur, on va partout : il suffit d'un bateau, d'un peu de vent, et d'un capitaine de bonne humeur.", "La salle d'attente est ouverte tout le temps. Même la nuit : il y a toujours quelqu'un qui attend quelqu'un."]}
	_marchand(M, hw - 0.5, -0.6 - 0.85, -90.0, "comptoir", "homme", "Monsieur Bastien", ["Le prochain départ ? Bientôt. Très bientôt. Presque maintenant.", "Billet aller, billet retour, billet souvenir…", "Tchou-tchou ! … Pardon, ce n'est pas un train. Mais j'aime bien faire tchou-tchou."], menu)
	_clients(M, [["femme", -2.6, -0.4 + 0.05, 180.0, "assis", ["Il est en retard, ce bateau…"]], ["garcon", -2.0, -0.4 + 0.05, 180.0, "assis", ["On arrive quand ? On arrive quand ?"]],
		["homme", 2.6, 1.7, 200.0, "debout", ["J'ai oublié mon parapluie. À Port-Azur. Il ne pleut jamais à Port-Azur."]]])
	M.ctx["cloche170"] = false
	M.ctx["bonjour170"] = ["Bienvenue à la gare maritime !", "Bonjour ! Le tableau des départs est au fond."]
	M.ctx["entree"] = "La gare maritime : le grand tableau des départs, l'horloge, les bancs de la salle d'attente, les valises qui attendent leur bateau."


# =================================================================== la capitainerie (Odette, Charbonnel) ; la location de bateaux (Yannick)

## Une barre à roue de navire, au mur.
static func _barre(R, x: float, y: float, z: float, yaw: float, r: float = 0.45) -> void:
	var k = R.kit
	var B: Transform3D = R.L(x, y, z, yaw) * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0, 0.1))
	k.ring(B, r * 0.82, r, 0.06, "bois_sombre", 24)
	k.cyl(B * T3(0, -0.04, 0), r * 0.18, r * 0.18, 0.12, "bois_sombre", 12)
	for i in range(8):
		var a: float = TAU * i / 8.0
		k.box(B * Transform3D(Basis(Vector3.UP, -a), Vector3(cos(a) * r * 0.6, 0, sin(a) * r * 0.6)), Vector3(r * 1.2, 0.035, 0.035), "bois", 1.0)
		k.box(B * Transform3D(Basis(Vector3.UP, -a), Vector3(cos(a) * r * 1.12, 0, sin(a) * r * 1.12)), Vector3(r * 0.26, 0.05, 0.05), "bois_sombre", 1.0)
	R.mark_wall(x, y, z, r + 0.2)


## Une bouée (rouge et blanche) accrochée au mur.
static func _bouee(R, x: float, y: float, z: float, yaw: float) -> void:
	var k = R.kit
	var B: Transform3D = R.L(x, y, z, yaw) * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0, 0.1))
	k.ring(B, 0.18, 0.32, 0.12, _c(R, "bouee_blanc", Color(0.95, 0.94, 0.9), 0.6), 20)
	for q in range(4):
		var a: float = TAU * q / 4.0 + 0.4
		k.box(B * Transform3D(Basis(Vector3.UP, -a), Vector3(cos(a) * 0.25, 0, sin(a) * 0.25)), Vector3(0.15, 0.125, 0.16), _c(R, "bouee_rouge", Color(0.85, 0.12, 0.1), 0.6), 1.0)
	R.mark_wall(x, y, z, 0.4)


static func _capitainerie(M) -> void:
	var R = M.R
	var k = R.kit
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var st: String = str(M.cur.get("style", ""))
	var location: bool = str(M.cur.get("metier", "")) == "location"
	var zc: float = -hd + 1.9
	var cx: Transform3D = _comptoir(M, 0.6, zc, 2.8)
	_barre(R, -1.8, 1.9, -hd + 0.03, 0.0, 0.5)
	_bouee(R, 2.4, 1.9, -hd + 0.03, 0.0)
	# les fanions en guirlande sous le plafond
	var cols: Array = [Color(0.9, 0.15, 0.12), Color(0.95, 0.85, 0.2), Color(0.15, 0.3, 0.7), Color(0.95, 0.95, 0.95)]
	var gy: float = R.H - 0.5
	for g in range(int((R.W - 1.0) / 0.4)):
		var gx: float = -hw + 0.6 + g * 0.4
		var gzz: float = hd - 2.5 - 0.15 * sin(g * 0.8)
		k.tri(_c(R, "fanion_%d" % (g % 4), cols[g % 4], 0.8), R.P(gx - 0.15, gy, gzz), R.P(gx + 0.15, gy, gzz), R.P(gx, gy - 0.32, gzz), Vector3(0, 0, 1), Vector2(0, 0), Vector2(1, 0), Vector2(0.5, 1))
		k.tri(_c(R, "fanion_%d" % (g % 4), cols[g % 4], 0.8), R.P(gx + 0.15, gy, gzz), R.P(gx - 0.15, gy, gzz), R.P(gx, gy - 0.32, gzz), Vector3(0, 0, -1), Vector2(0, 0), Vector2(1, 0), Vector2(0.5, 1))
	k.box(R.L(0, gy, hd - 2.5) * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3.ZERO), Vector3(0.008, R.W - 1.0, 0.008), "fer", 1.0)
	if location:
		# les rames croisées, les gilets, la barque retournée sur ses tréteaux, le tableau des tarifs
		for s in [-1.0, 1.0]:
			k.box(R.L(-hw + 0.08, 1.9, -0.6) * Transform3D(Basis(Vector3.RIGHT, s * 0.6), Vector3.ZERO), Vector3(0.04, 2.0, 0.06), "bois_clair", 1.0)
			k.box(R.L(-hw + 0.1, 1.9 + s * 0.0, -0.6) * Transform3D(Basis(Vector3.RIGHT, s * 0.6), Vector3(0, 0.9, 0)), Vector3(0.03, 0.4, 0.16), "bois_clair", 1.0)
		R.mark_wall(-hw, 1.9, -0.6, 1.0)
		for v in range(3):
			var vz: float = hd - 3.6 + v * 0.45
			k.box(R.L(hw - 0.12, 1.5, vz), Vector3(0.12, 0.5, 0.36), _c(R, "gilet", Color(0.95, 0.45, 0.08), 0.7), 1.0)
			k.box(R.L(hw - 0.06, 1.8, vz), Vector3(0.05, 0.05, 0.1), "bois_sombre", 1.0)
		R.mark_wall(hw, 1.5, hd - 3.15, 0.8)
		var B: Transform3D = R.L(-hw + 0.95, 0, 0.7, 90.0)
		for t in [-0.9, 0.9]:
			k.box(B * T3(t, 0.35, 0), Vector3(0.08, 0.7, 0.9), "bois_sombre", 1.0)
		var coque: String = _c(R, "coque_barque", Color(0.15, 0.4, 0.6), 0.6)
		k.box(B * T3(0, 0.85, 0), Vector3(2.6, 0.1, 0.9), coque, 1.0)
		k.box(B * T3(0, 1.0, 0), Vector3(2.4, 0.2, 0.75), coque, 1.0)
		k.box(B * T3(0, 1.13, 0), Vector3(2.0, 0.08, 0.4), "bois", 1.0)
		k.box(B * Transform3D(Basis(Vector3.UP, PI * 0.25), Vector3(1.35, 0.95, 0)), Vector3(0.5, 0.25, 0.5), coque, 1.0)
		k.box(B * T3(0, 0.79, 0.455), Vector3(2.5, 0.06, 0.02), _c(R, "lisere_blanc", Color(0.95, 0.95, 0.92), 0.6), 1.0)
		k.col_box(B * T3(0, 0.6, 0), Vector3(2.8, 1.2, 1.0))
		R.reserve(-hw + 0.95, 0.7, 1.2, 3.0)
		var tf: String = _img(R, "tarifs_location", "beau170/tarifs_location.png")
		_cadre(R, tf, hw - 0.02, 1.7, -0.4, -90.0, 0.9, 1.1)
		k.box(cx * T3(0.6, 1.08, 0.05), Vector3(0.3, 0.04, 0.22), "papier", 1.0)
		R.etagere(hw - 0.6, -hd + 0.25, 0.0, 1.0, 1.9, false, 3)
		for c4 in range(4):
			k.box(R.L(hw - 0.95 + c4 * 0.24, 0.95, -hd + 0.3) * Transform3D(Basis(Vector3.BACK, 0.06), Vector3.ZERO), Vector3(0.02, 1.8, 0.02), "bois_clair", 1.0)
	else:
		# la grande carte marine sur la table, la longue-vue, les maquettes dans leurs bouteilles, le registre
		R.table(-1.2, 0.6, 0.0, 1.8, 1.1, 0.85)
		var carte: String = _img(R, "carte_marine170", "beau170/carte_marine.png")
		k.quad(R.L(-1.2, 0.865, 0.6) * Transform3D(Basis(Vector3.UP, PI) * Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 1.6, 0.95, carte)
		k.cyl(R.L(-0.6, 0.88, 0.5) * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3.ZERO), 0.02, 0.02, 0.4, "or", 6)
		k.box(R.L(-1.7, 0.875, 0.75, 30.0), Vector3(0.18, 0.012, 0.01), "or", 1.0)
		k.box(R.L(-1.7, 0.875, 0.75, -30.0), Vector3(0.18, 0.012, 0.01), "or", 1.0)
		var lv: Vector3 = Vector3(hw - 0.9, 0, hd - 2.0)
		for tl in range(3):
			var a: float = TAU * tl / 3.0
			k.box(R.L(lv.x + cos(a) * 0.2, 0.6, lv.z + sin(a) * 0.2) * Transform3D(Basis(Vector3(sin(a), 0, -cos(a)), 0.3), Vector3.ZERO), Vector3(0.03, 1.25, 0.03), "bois_sombre", 1.0)
		k.cyl(R.L(lv.x, 1.25, lv.z) * Transform3D(Basis(Vector3.RIGHT, 1.3) * Basis(Vector3.BACK, 0.0), Vector3(0, -0.35, 0)), 0.045, 0.035, 0.9, "or", 12)
		k.col_box(R.L(lv.x, 0.7, lv.z), Vector3(0.5, 1.4, 0.5))
		R.reserve(lv.x, lv.z, 0.7, 0.7)
		M.act(R.P(lv.x - 0.3, 0, lv.z - 0.6), "E : regarder dans la longue-vue", func(): M.say(str(_pick(M, ["Dans la longue-vue : une voile au loin, des mouettes, et… un bateau qui rentre au port. Bon vent !", "Tu vises l'horizon. Rien que la mer, la mer, la mer. Et tout au bout, une île qui fait des signes.", "Un dauphin ! Non, une vague. Non… si, un dauphin !"] if st == "azur" else ["Dans la longue-vue : la mer de cendre, le Port de Cendre, et une gerbe d'étincelles au loin.", "Un navire noir aux voiles rouges rentre au port. C'est le courrier de l'Archiduchesse."])), 5.0), 1.0)
		_rayons(M, hw - 0.9, -hd + 0.22, 0.0, 1.35, 2.0, 4, "livres")
		for m in range(3):
			var mz: float = -hd + 2.6 + m * 0.75
			k.box(R.L(-hw + 0.25, 1.0, mz), Vector3(0.35, 0.04, 0.5), "bois_sombre", 1.0)
			k.cyl(R.L(-hw + 0.25, 1.02, mz) * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, -0.2, 0)), 0.08, 0.08, 0.32, _verre(R, "bouteille_maquette", Color(0.6, 0.85, 0.7), 0.3), 12)
			k.box(R.L(-hw + 0.25, 1.06, mz), Vector3(0.05, 0.04, 0.2), "bois", 1.0)
			k.box(R.L(-hw + 0.25, 1.1, mz), Vector3(0.005, 0.08, 0.12), "papier", 1.0)
		R.mark_wall(-hw, 1.0, -hd + 3.3, 1.0)
		k.box(cx * T3(-0.7, 1.08, 0.05), Vector3(0.4, 0.05, 0.3), "cuir", 1.0)
		k.cyl(R.L(1.6, R.H - 0.45, zc), 0.12, 0.1, 0.2, "or", 14)
		M.act(R.P(1.6, 0, zc + 0.9), "E : sonner la cloche", func(): M.main.sfx("cloche_bateau"), 1.0)
	_lampe(M, 0.6, 2.2, zc + 0.4, Color(1.0, 0.9, 0.75), 0.6, 4.0)
	var lignes: Array = ["Grand beau temps aujourd'hui ! Enfin, pour l'instant.", "Le port est calme. Trop calme ? Non, juste calme.", "Tout bateau qui entre passe par ce registre."]
	if location:
		lignes = ["Une barque ? Un pédalo ? Un pédalo en forme de cygne ?", "Rendez les rames, s'il vous plaît. On en a perdu trois cette semaine.", "La mer est d'huile, aujourd'hui. Idéal pour ramer."]
	_marchand(M, 0.6, zc - 0.55, 0.0, "comptoir", "homme", "Capitaine Bosco", lignes, {"bonjour": "Capitainerie, bonjour !", "vend": {"canne_peche": 18, "boussole": 25}, "achete": {"vieille_botte": 1}})
	M.ctx["bonjour170"] = ["Bienvenue à bord ! Enfin, à terre.", "Ohé ! Entre !"] if not location else ["Bienvenue ! On part en mer ?", "Salut ! Une barque t'attend."]
	M.ctx["entree"] = ("%s : la grande carte marine, la barre de navire au mur, les maquettes dans leurs bouteilles, la longue-vue sur son trépied." if not location else "%s : les rames croisées au mur, les gilets orange, une barque retournée sur ses tréteaux.") % str(M.cur.get("enseigne170", "La capitainerie"))


# =================================================================== les cafés et le restaurant (Paulo, Gisèle, Gaston Bielle)

## Le percolateur (la machine à café de laiton, son aigle, ses manettes).
static func _percolateur(M, xf: Transform3D) -> void:
	var R = M.R
	var k = R.kit
	k.box(xf * T3(0, 0.05, 0), Vector3(0.6, 0.1, 0.4), "fer", 1.0)
	k.cyl(xf * T3(0, 0.1, 0), 0.18, 0.18, 0.45, "or", 18)
	k.cyl(xf * T3(0, 0.55, 0), 0.18, 0.04, 0.16, "or", 18)
	k.cyl(xf * T3(0, 0.71, 0), 0.04, 0.0, 0.08, "or", 8)
	for s in [-1.0, 1.0]:
		k.cyl(xf * Transform3D(Basis(Vector3.BACK, s * PI * 0.5), Vector3(s * 0.18, 0.3, 0.05)), 0.03, 0.03, 0.08, "argent", 8)
		k.box(xf * T3(s * 0.26, 0.24, 0.1), Vector3(0.03, 0.12, 0.03), "noir", 1.0)
		k.cyl(xf * T3(s * 0.26, 0.12, 0.1), 0.035, 0.03, 0.06, "ceramique", 10)
	var vap: CPUParticles3D = CPUParticles3D.new()
	vap.amount = 10
	vap.lifetime = 1.4
	vap.direction = Vector3.UP
	vap.spread = 15.0
	vap.initial_velocity_min = 0.15
	vap.initial_velocity_max = 0.3
	vap.gravity = Vector3(0, 0.2, 0)
	var q := QuadMesh.new()
	q.size = Vector2(0.12, 0.12)
	vap.mesh = q
	var vm := StandardMaterial3D.new()
	vm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	vm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	vm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	vm.albedo_color = Color(1, 1, 1, 0.18)
	vap.material_override = vm
	M.room.add_child(vap)
	vap.global_position = xf * Vector3(0, 0.78, 0)


static func _cafe(M) -> void:
	var R = M.R
	var k = R.kit
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var st: String = str(M.cur.get("style", ""))
	var resto: bool = str(M.cur.get("metier", "")) == "restaurant"
	# le comptoir (le zinc), le percolateur, les sirops, le gâteau sous sa cloche
	var zc: float = -hd + 1.7
	var bx: float = hw - 2.2
	var cx: Transform3D = _comptoir(M, bx, zc, 3.4, 0.0, false, 1.05, "bois_sombre", "metal")
	_percolateur(M, cx * T3(0.9, 1.11, -0.05))
	k.cyl(cx * T3(-0.6, 1.11, 0.05), 0.16, 0.18, 0.02, "ceramique", 16)
	k.cyl(cx * T3(-0.6, 1.13, 0.05), 0.13, 0.13, 0.1, "gateau", 16)
	k.cyl(cx * T3(-0.6, 1.23, 0.05), 0.13, 0.13, 0.02, "chocolat", 16)
	k.cyl(cx * T3(-0.6, 1.11, 0.05), 0.17, 0.12, 0.26, _verre(R, "cloche_verre", Color(0.95, 0.98, 1.0), 0.18), 18)
	for g in range(5):
		k.cyl(cx * T3(-1.4 + g * 0.12, 1.11, 0.15), 0.03, 0.025, 0.09, _verre(R, "verre170", Color(0.95, 0.98, 1.0), 0.3), 10)
	_rayons(M, bx, -hd + 0.22, 0.0, 3.0, 2.0, 3, "fioles", 1)
	var miroir: String = _c(R, "miroir170", Color(0.62, 0.68, 0.72), 0.04, 0.95)
	k.box(R.L(bx, 2.4, -hd + 0.03), Vector3(3.0, 0.6, 0.02), miroir, 1.0)
	R.mark_wall(bx, 2.2, -hd, 1.6)
	# l'ardoise du menu
	var ard: String = _img(R, "ardoise170_%s" % ("paulo" if resto else st), "beau170/ardoise_%s.png" % ("paulo" if resto else ("bielle" if st == "cliquetis" else "cafe")))
	_cadre(R, ard, -hw + 0.02, 1.7, -hd + 1.6, 90.0, 0.9, 1.2)
	# les tables, les chaises, les clients
	var places: Array = [[-hw + 1.3, -0.2], [-hw + 1.3, 1.9], [-0.4, 0.8], [1.6, 1.9]]
	var nappe: String = "rouge" if resto else ""
	var gens: Array = [["homme", "manger" if resto else "assis"], ["femme", "rire_assis"], ["vieux", "lire"], ["fille", "manger"]]
	for i in range(places.size()):
		var t: Array = places[i]
		if float(t[1]) > hd - 1.4:
			continue
		R.table(float(t[0]), float(t[1]), 0.0, 1.0, 0.8, 0.76, nappe)
		R.chaise(float(t[0]) - 0.65, float(t[1]), 90.0)
		R.chaise(float(t[0]) + 0.65, float(t[1]), -90.0)
		k.cyl(R.L(float(t[0]) + 0.15, 0.77, float(t[1])), 0.05, 0.04, 0.06, "ceramique", 10)
		if resto:
			k.cyl(R.L(float(t[0]) - 0.2, 0.77, float(t[1]) + 0.1), 0.13, 0.11, 0.025, "ceramique", 16)
			k.cyl(R.L(float(t[0]) - 0.2, 0.795, float(t[1]) + 0.1), 0.1, 0.1, 0.006, "soupe", 16)
			R.bougie(float(t[0]) + 0.3, 0.77, float(t[1]) - 0.2)
		if i < gens.size() and i != 2:
			var p: Node = M.person(str(gens[i][0]), float(t[0]) - 0.6, float(t[1]), 90.0, str(gens[i][1]))
			p.lines = [str(_pick(M, ["Hmm ! Délicieux !", "Un autre, s'il vous plaît !", "Il fait bon, ici.", "Tu as goûté la tarte ?"]))]
	if resto:
		# la cuisine ouverte au fond à gauche : les casseroles de cuivre, la grande marmite qui fume, les filets
		var kx: float = -hw + 1.6
		k.box(R.L(kx, 0.45, -hd + 0.45), Vector3(2.6, 0.9, 0.8), "pierre_lisse", 1.0)
		k.box(R.L(kx, 0.92, -hd + 0.45), Vector3(2.7, 0.05, 0.85), "metal", 1.0)
		k.cyl(R.L(kx - 0.4, 0.95, -hd + 0.45), 0.28, 0.26, 0.45, "cuivre", 16)
		k.cyl(R.L(kx - 0.4, 1.36, -hd + 0.45), 0.25, 0.25, 0.02, _c(R, "bouillabaisse170", Color(0.85, 0.42, 0.12), 0.25), 16)
		R.fire(R.P(kx - 0.4, 0.95, -hd + 0.45), 0.35)
		for c3 in range(5):
			k.cyl(R.L(kx - 1.1 + c3 * 0.45, 1.75, -hd + 0.1) * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0.0, 0)), 0.11 + 0.02 * float(c3 % 2), 0.11 + 0.02 * float(c3 % 2), 0.06, "cuivre", 14)
			k.box(R.L(kx - 1.1 + c3 * 0.45, 1.98, -hd + 0.06), Vector3(0.03, 0.2, 0.02), "cuivre", 1.0)
		R.mark_wall(kx, 1.8, -hd, 1.3)
		k.col_box(R.L(kx, 0.5, -hd + 0.45), Vector3(2.6, 1.0, 0.8))
		R.reserve(kx, -hd + 0.45, 2.8, 1.0)
		var filet: String = _tex(R, "filet170", "azur/filet.png", Color(0.9, 0.85, 0.75))
		k.quad(R.L(-hw + 0.04, 2.3, 0.6, 90.0) * Transform3D(Basis(Vector3.UP, PI), Vector3.ZERO), 2.4, 1.0, filet, Vector2(0, 0), Vector2(3, 1.2))
		R.mark_wall(-hw, 2.3, 0.6, 1.2)
	elif st == "cliquetis":
		# le robot serveur (le plateau, la tête qui tourne), les tuyaux qui sifflent
		var rx: float = -0.4
		var rz: float = 1.9
		var corps: String = _c(R, "robot_laiton", Color(0.82, 0.62, 0.3), 0.35, 0.8)
		k.cyl(R.L(rx, 0.0, rz), 0.22, 0.26, 0.12, "fer", 14)
		k.cyl(R.L(rx, 0.12, rz), 0.2, 0.24, 0.75, corps, 14)
		k.cyl(R.L(rx, 0.87, rz), 0.24, 0.2, 0.08, "cuivre", 14)
		var tete := Node3D.new()
		M.room.add_child(tete)
		tete.global_position = R.P(rx, 0.95, rz)
		var tm := MeshInstance3D.new()
		tm.mesh = _cylm(0.13, 0.15, 0.22, 14)
		tm.material_override = R.mat(corps)
		tm.position.y = 0.11
		tete.add_child(tm)
		for e in [-0.05, 0.05]:
			var oeil := MeshInstance3D.new()
			oeil.mesh = _cylm(0.025, 0.025, 0.02, 10)
			oeil.material_override = R.mat(_c(R, "oeil_robot", Color(0.4, 0.9, 1.0), 0.3, 0.0, 2.5))
			oeil.rotation.x = PI * 0.5
			oeil.position = Vector3(e, 0.14, 0.14)
			tete.add_child(oeil)
		(M.ctx["anims170"] as Array).append([tete, "balance", 0.6, 0.7])
		k.box(R.L(rx + 0.3, 0.7, rz + 0.1) * Transform3D(Basis(Vector3.BACK, -0.6), Vector3.ZERO), Vector3(0.05, 0.4, 0.05), "fer", 1.0)
		k.cyl(R.L(rx + 0.45, 0.85, rz + 0.1), 0.18, 0.18, 0.015, "argent", 16)
		k.cyl(R.L(rx + 0.45, 0.865, rz + 0.1), 0.04, 0.035, 0.07, "ceramique", 10)
		k.col_box(R.L(rx, 0.6, rz), Vector3(0.6, 1.2, 0.6))
		R.reserve(rx, rz, 0.8, 0.8)
		var bip := func() -> void:
			M.main.sfx("robot_bip", M.R.P(rx, 1.0, rz))
			M.say(str(_pick(M, ["« BIP. CAFÉ. À. VAPEUR ? » Le robot penche la tête. Il attend ta réponse depuis 1847.", "« BONJOUR. CLIENT. ASSIS-TOI. » Le plateau tremble. La tasse aussi.", "Le robot fait une petite révérence. Quelque chose grince. « PARDON. » "])), 5.0)
		M.act(R.P(rx, 0, rz + 0.8), "E : saluer le robot serveur", bip, 1.0)
	var lignes: Array = ["Un café ? Un chocolat ? Un sirop de grenadine ?", "Installe-toi où tu veux !", "La tarte du jour ? Elle part vite !"]
	if resto:
		lignes = ["La bouillabaisse, c'est un art. Et une religion.", "Mangia ! Euh, non, ça c'est Al Dente. Mange !", "Le poisson du jour ? Il est encore surpris d'être là."]
	_marchand(M, bx, zc - 0.55, 0.0, "comptoir", "homme", "Gaston", lignes, {"vend": {"cafe_vapeur": 3, "chocolat_chaud": 4, "croissant": 3}, "achete": {"miel": 4}})
	M.ctx["bonjour170"] = ["Bienvenue ! Assieds-toi, j'arrive !", "Salut ! Comme d'habitude ?"] if not resto else ["Benvenuto ! Euh… Bienvenue chez Paulo !", "Entre ! Ça sent bon, hein ?"]
	M.ctx["entree"] = ("%s : le comptoir de zinc, le percolateur qui siffle, l'ardoise du jour, les petites tables." if not resto else "%s : les nappes à carreaux, la cuisine ouverte, les casseroles de cuivre, la grande marmite qui fume.") % str(M.cur.get("enseigne170", "Le café"))


# =================================================================== la bijouterie (Inès)

static func _bijouterie(M) -> void:
	var R = M.R
	var k = R.kit
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var zc: float = -hd + 1.7
	var cx: Transform3D = _comptoir(M, 0.0, zc, 2.6, 0.0, true)
	for e in range(6):
		_ecrin(R, cx * T3(-1.0 + e * 0.4, 1.07, 0.05), e)
	k.ring(cx * Transform3D(Basis(Vector3.BACK, 0.3), Vector3(1.05, 1.14, -0.2)), 0.05, 0.065, 0.01, "or", 16)
	# les vitrines sur pieds : le velours, les colliers, les bagues, les pierres qui brillent
	for v in [[-hw + 1.1, -0.2, 90.0], [hw - 1.1, -0.2, -90.0], [-hw + 1.1, 1.6, 90.0], [hw - 1.1, 1.6, -90.0]]:
		var V: Transform3D = R.L(float(v[0]), 0, float(v[1]), float(v[2]))
		for sx in [-0.5, 0.5]:
			for sz in [-0.22, 0.22]:
				k.box(V * T3(sx, 0.45, sz), Vector3(0.05, 0.9, 0.05), "or", 1.0)
		k.box(V * T3(0, 0.9, 0), Vector3(1.1, 0.05, 0.5), "bois_sombre", 1.0)
		k.box(V * T3(0, 0.93, 0), Vector3(1.05, 0.01, 0.46), _c(R, "velours_bleu", Color(0.08, 0.1, 0.3), 0.95), 1.0)
		for e2 in range(5):
			_ecrin(R, V * T3(-0.4 + e2 * 0.2, 0.935, 0.0), e2 + int(v[1]))
		k.box(V * T3(0, 1.12, 0), Vector3(1.1, 0.36, 0.5), _verre(R, "vitrine170", Color(0.85, 0.92, 0.95), 0.18), 1.0)
		k.box(V * T3(0, 1.31, 0), Vector3(1.12, 0.03, 0.52), "or", 1.0)
		k.col_box(V * T3(0, 0.65, 0), Vector3(1.1, 1.3, 0.5))
		R.reserve(float(v[0]), float(v[1]), 0.7, 1.3)
	# les bustes de velours (les colliers de perles), au fond ; le miroir ; le coffre
	for b in range(3):
		var bxp: float = -1.4 + b * 1.4
		var B: Transform3D = R.L(bxp, 0, -hd + 0.35)
		R.etagere(bxp, -hd + 0.25, 0.0, 1.2, 1.0, false, 1)
		k.cyl(B * T3(0, 1.0, 0), 0.14, 0.18, 0.32, _c(R, "velours_noir", Color(0.06, 0.05, 0.06), 0.95), 14)
		k.cyl(B * T3(0, 1.32, 0), 0.05, 0.05, 0.14, "velours_noir", 10)
		for p in range(13):
			var a: float = PI * 0.15 + PI * 0.7 * p / 12.0
			k.cyl(B * T3(cos(a) * 0.13, 1.27 - sin(a) * 0.12, 0.13), 0.014, 0.014, 0.02, _c(R, "perle170", Color(0.96, 0.94, 0.9), 0.15, 0.2), 8)
	var mir: String = _c(R, "miroir170", Color(0.62, 0.68, 0.72), 0.04, 0.95)
	k.box(R.L(-hw + 0.04, 1.5, hd - 1.8, 90.0), Vector3(0.6, 0.9, 0.02), mir, 1.0)
	k.ring(R.L(-hw + 0.05, 1.5, hd - 1.8, 90.0) * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 0.3, 0.36, 0.04, "or", 4)
	R.mark_wall(-hw, 1.5, hd - 1.8, 0.4)
	R.coffre_deco(hw - 0.7, -hd + 0.6, -90.0)
	_lustre(M, 0.0, 0.5, 0.45, 1.3)
	for li in [-hw + 1.1, hw - 1.1]:
		_lampe(M, li, 1.4, 0.7, Color(1.0, 0.95, 0.9), 0.4, 2.2)
	var lignes: Array = ["Une perle, c'est une larme de la mer qui a décidé d'être heureuse.", "Approche, regarde… mais ne respire pas sur la vitre !", "Chaque pierre a son histoire. Celle-là, c'est un roman."]
	_marchand(M, 0.0, zc - 0.55, 0.0, "comptoir", "femme", "Inès", lignes, {"vend": {"perle": 45, "bague": 60}, "achete": {"perle": 28, "rubis": 40, "coquillage": 3}})
	M.ctx["bonjour170"] = ["Bienvenue ! Prends ton temps, tout brille.", "Bonjour ! Une perle t'attend peut-être."]
	M.ctx["entree"] = "La bijouterie : les vitrines sur leurs pieds dorés, le velours bleu, les colliers de perles sur leurs bustes, tout qui scintille."


# =================================================================== la boulangerie (Margaux, Bobor, Honorine)

static func _boulangerie(M) -> void:
	var R = M.R
	var k = R.kit
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var st: String = str(M.cur.get("style", ""))
	var zc: float = -hd + 2.2
	# le four au fond : la voûte de briques, la gueule qui rougeoie (le Four Éternel, à Pandémonia)
	var fx: float = -hw + 1.6
	var fz: float = -hd + 0.6
	var briq: String = "brique"
	k.box(R.L(fx, 0.75, fz), Vector3(2.2, 1.5, 1.2), briq, 1.2)
	k.cyl(R.L(fx, 1.5, fz - 0.6) * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 1.1, 1.1, 1.2, briq, 18)
	k.box(R.L(fx, 0.9, fz + 0.61), Vector3(0.75, 0.55, 0.02), _c(R, "gueule_four", Color(1.0, 0.45, 0.12) if st != "braise" else Color(1.0, 0.3, 0.05), 0.9, 0.0, 2.6), 1.0)
	k.box(R.L(fx, 1.2, fz + 0.62), Vector3(0.95, 0.1, 0.06), "fer", 1.0)
	k.box(R.L(fx, 0.6, fz + 0.62), Vector3(0.95, 0.06, 0.06), "fer", 1.0)
	R.fire(R.P(fx, 0.75, fz + 0.45), 0.6 if st != "braise" else 1.0)
	_lampe(M, fx, 1.0, fz + 1.0, Color(1.0, 0.55, 0.2), 1.4 if st != "braise" else 2.2, 4.0)
	k.col_box(R.L(fx, 1.0, fz), Vector3(2.2, 2.0, 1.2))
	R.reserve(fx, fz, 2.4, 1.5)
	k.box(R.L(fx + 1.25, 1.0, fz + 0.4) * Transform3D(Basis(Vector3.BACK, 0.35), Vector3.ZERO), Vector3(0.05, 2.0, 0.05), "bois", 1.0)
	k.box(R.L(fx + 1.6, 0.12, fz + 0.4), Vector3(0.35, 0.02, 0.3), "bois", 1.0)
	# les grilles de pain, contre le mur du fond et le mur de droite
	_rayons(M, 1.2, -hd + 0.22, 0.0, 1.5, 2.1, 5, "pains", 0)
	_rayons(M, hw - 0.22, -hd + 2.1, -90.0, 1.4, 2.1, 5, "pains", 2)
	# le comptoir et sa vitrine de gâteaux, les paniers de baguettes
	var cx: Transform3D = _comptoir(M, 0.8, zc, 3.0, 0.0, true)
	var gcols: Array = [Color(0.98, 0.88, 0.9), Color(0.42, 0.22, 0.12), Color(0.95, 0.75, 0.35), Color(0.85, 0.3, 0.35)]
	for g in range(6):
		var gx: float = -1.1 + g * 0.44
		k.cyl(cx * T3(gx, 1.07, 0.05), 0.11, 0.11, 0.08, _c(R, "gateau_%d" % (g % 4), gcols[g % 4], 0.6), 14)
		k.cyl(cx * T3(gx, 1.15, 0.05), 0.11, 0.08, 0.03, "gateau", 14)
		if g % 2 == 0:
			k.cyl(cx * T3(gx, 1.18, 0.05), 0.02, 0.02, 0.02, "pomme", 8)
	_caisse(R, cx * T3(1.3, 1.06, -0.05))
	for b in range(3):
		var px: float = -hw + 0.6 + b * 0.55
		var pz: float = zc + 1.0
		k.cyl(R.L(px, 0, pz), 0.18, 0.22, 0.45, _tex(R, "osier170", "objets/osier.png"), 14)
		for bb in range(5):
			var a: float = TAU * bb / 5.0
			k.cyl(R.L(px + cos(a) * 0.07, 0.1, pz + sin(a) * 0.07) * Transform3D(Basis(Vector3(sin(a), 0, -cos(a)), 0.12), Vector3.ZERO), 0.028, 0.03, 0.75, "croute_doree" if R.mat("croute_doree") != null else "pain", 8)
		k.col_box(R.L(px, 0.3, pz), Vector3(0.45, 0.6, 0.45))
		R.reserve(px, pz, 0.55, 0.55)
	# les sacs de farine, le pétrin et la pâte qui lève
	for s in range(3):
		var sx2: float = hw - 0.6 - 0.15 * float(s % 2)
		var sz2: float = hd - 1.4 - 0.45 * s
		k.cyl(R.L(sx2, 0, sz2), 0.24, 0.22, 0.55, _c(R, "sac_farine", Color(0.94, 0.92, 0.86), 0.95), 12)
		k.cyl(R.L(sx2, 0.55, sz2), 0.22, 0.12, 0.08, "sac_farine", 12)
	k.col_box(R.L(hw - 0.65, 0.3, hd - 1.85), Vector3(0.6, 0.6, 1.4))
	R.reserve(hw - 0.65, hd - 1.85, 0.8, 1.6)
	var lignes: Array = ["Tout chaud, tout chaud ! Attention, ça brûle les doigts.", "La première fournée est partie à six heures. La deuxième, à six heures et une minute.", "Une baguette bien cuite, c'est une baguette qui chante quand on la serre."]
	if st == "braise":
		lignes = ["Le Four Éternel ne s'éteint jamais. Jamais ! Même pas le dimanche.", "Une brioche de braise ? Elle est encore fumante. Elle le sera toujours.", "Souffle dessus avant de croquer. Non, plus fort."]
	_marchand(M, 0.8, zc - 0.55, 0.0, "comptoir", "femme", "Madame Mie", lignes, {"vend": {"croissant": 3, "baguette": 4, "pain_miel": 6}, "achete": {"miel": 5, "pomme": 1}})
	if st == "azur":
		_habitue(M, "nina", fx + 1.5, fz + 1.4, 160.0, "debout", ["Maman, je peux goûter un croissant ? Juste un petit bout ?"])
	elif st == "montjoie":
		_habitue(M, "noisette_mj", fx + 1.5, fz + 1.4, 160.0, "debout", ["Moi aussi, je sais faire des petits pains ! En forme de grenouille."])
	M.ctx["bonjour170"] = ["Bonjour ! Ça sort du four !", "Entre, entre ! Il reste des croissants."] if st != "braise" else ["Bienvenue au Four Éternel ! Tout est chaud, toujours.", "Entre, et ne touche pas le four. Sérieusement."]
	M.ctx["entree"] = ("%s : le four qui rougeoie au fond, les grilles pleines de pains dorés, la vitrine des gâteaux, l'odeur de la croûte chaude." % str(M.cur.get("enseigne170", "La boulangerie")))


# =================================================================== la librairie de Félix (libraire et cartographe)

static func _libraire(M) -> void:
	var R = M.R
	var k = R.kit
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var hh: float = R.H - 0.25
	# des livres jusqu'au plafond, sur tous les murs
	for i in range(int((R.W - 0.4) / 1.3)):
		R.etagere(-hw + 0.85 + i * 1.3, -hd + 0.22, 0.0, 1.25, hh, true, 6)
	for side in [-1.0, 1.0]:
		for j in range(2):
			var z: float = -hd + 1.7 + j * 1.3
			R.etagere(side * (hw - 0.22), z, -90.0 * side, 1.25, hh, true, 6)
	# l'échelle sur son rail
	k.box(R.L(0, hh - 0.1, -hd + 0.5), Vector3(R.W - 1.0, 0.03, 0.03), "or", 1.0)
	var ex: float = 1.4
	for s in [-0.22, 0.22]:
		k.box(R.L(ex + s, hh * 0.5, -hd + 0.75) * Transform3D(Basis(Vector3.RIGHT, -0.18), Vector3.ZERO), Vector3(0.04, hh, 0.05), "bois_sombre", 1.0)
	for r in range(int(hh / 0.32)):
		k.box(R.L(ex, 0.25 + r * 0.32, -hd + 0.95 - r * 0.32 * 0.18), Vector3(0.44, 0.03, 0.05), "bois_sombre", 1.0)
	# le comptoir : le registre, la plume ; la table des cartes (les rouleaux, le compas)
	var zc: float = -hd + 2.0
	var cx: Transform3D = _comptoir(M, -1.2, zc, 2.2)
	k.box(cx * T3(0.4, 1.065, 0.05), Vector3(0.4, 0.03, 0.3), "papier", 1.0)
	k.box(cx * T3(0.4, 1.055, 0.05), Vector3(0.42, 0.02, 0.32), "cuir", 1.0)
	R.table(1.2, 0.8, 0.0, 1.6, 1.0, 0.85)
	var carte: String = _img(R, "carte_marine170", "beau170/carte_marine.png")
	k.quad(R.L(1.1, 0.865, 0.8, 8.0) * Transform3D(Basis(Vector3.UP, PI) * Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 1.1, 0.7, carte)
	for rl in range(4):
		k.cyl(R.L(1.75, 0.87, 0.5 + rl * 0.18) * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3.ZERO), 0.035, 0.035, 0.5, "papier", 10)
	# le globe sur son pied, le fauteuil de lecture, la lampe, les piles de livres par terre
	var gx: float = -hw + 1.4
	var gz: float = hd - 2.0
	k.cyl(R.L(gx, 0, gz), 0.22, 0.25, 0.05, "bois_sombre", 14)
	k.cyl(R.L(gx, 0.05, gz), 0.04, 0.03, 0.7, "bois_sombre", 8)
	k.ring(R.L(gx, 1.0, gz) * Transform3D(Basis(Vector3.BACK, 0.4) * Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 0.27, 0.29, 0.02, "or", 24)
	var gm := StandardMaterial3D.new()
	var gt: String = "res://assets/textures/beau170/carte_marine.png"
	if ResourceLoader.exists(gt):
		gm.albedo_texture = load(gt)
	gm.roughness = 0.5
	var globe: MeshInstance3D = Sud._boule(M.room, gm, R.P(gx, 1.0, gz), 0.25)
	(M.ctx["anims170"] as Array).append([globe, "tourne", Vector3.UP, 0.15])
	k.col_box(R.L(gx, 0.6, gz), Vector3(0.6, 1.2, 0.6))
	R.reserve(gx, gz, 0.7, 0.7)
	R.fauteuil(gx + 1.1, gz + 0.3, -60.0, "vert")
	k.cyl(R.L(gx + 1.8, 0, gz - 0.2), 0.12, 0.15, 0.04, "or", 10)
	k.cyl(R.L(gx + 1.8, 0.04, gz - 0.2), 0.015, 0.015, 1.3, "or", 6)
	k.cyl(R.L(gx + 1.8, 1.3, gz - 0.2), 0.2, 0.12, 0.22, _verre(R, "abat_jour", Color(0.95, 0.8, 0.5), 0.85, 0.7), 14)
	_lampe(M, gx + 1.8, 1.25, gz - 0.2, Color(1.0, 0.85, 0.6), 0.6, 3.0)
	for p in range(3):
		R.pile(hw - 1.4 + p * 0.35, hd - 1.6 - 0.25 * p, "livres", 4 + p)
	var feuilleter := func() -> void:
		M.say(str(_pick(M, ["« Les Îles et leurs Secrets », tome 3. Quelqu'un a souligné : « Le plus beau trésor, c'est le chemin. »", "Un atlas ancien : Port-Azur y est dessiné… avec un dragon dans le port. Félix jure que c'était vrai, à l'époque.", "« Comment apprivoiser un cerf-volant », par un auteur anonyme. Chapitre 1 : « Courir. »"])), 6.0)
	M.act(R.P(-hw + 1.0, 0, -hd + 1.7), "E : feuilleter un livre", feuilleter, 1.2)
	var lignes: Array = ["Un livre, c'est une île où l'on débarque quand on veut.", "Cette carte ? Je l'ai dessinée moi-même. Les dragons, c'est pour décorer.", "Chut… les livres dorment. Enfin, certains."]
	_marchand(M, -1.2, zc - 0.55, 0.0, "comptoir", "homme", "Félix", lignes, {"vend": {"boussole": 30, "carte_postale": 2}, "achete": {"carte_naine": 30}})
	R.chaise(-0.2, 1.7, 160.0, "vert")
	_clients(M, [["vieille", -0.2, 1.7, 160.0, "lire", ["« Et ils vécurent heureux… » Déjà ? Mais j'en suis à la page trois !"]]])
	M.ctx["bonjour170"] = ["Bienvenue dans le monde des livres !", "Bonjour ! Cherche, fouille, lis : c'est fait pour."]
	M.ctx["entree"] = "La librairie : des livres du sol au plafond, l'échelle sur son rail, la table des cartes, le globe qui tourne doucement."


# =================================================================== la boutique de magie (Madame Olga, Montjoie)

static func _magie(M) -> void:
	var R = M.R
	var k = R.kit
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	M.ctx["fiole_emit"] = 1.2
	var zc: float = -hd + 1.8
	_rayons(M, -hw + 1.0, -hd + 0.22, 0.0, 1.35, 2.3, 5, "fioles", 0)
	_rayons(M, hw - 1.0, -hd + 0.22, 0.0, 1.35, 2.3, 5, "fioles", 3)
	_rayons(M, -hw + 0.22, -hd + 2.6, 90.0, 1.4, 2.3, 5, "livres")
	var cx: Transform3D = _comptoir(M, 0.0, zc, 2.4, 0.0, false, 1.0, "bois_sombre", "bois_sombre")
	# la boule de cristal sur son coussin, les cristaux qui brillent, les baguettes dans leur vase
	var boule: MeshInstance3D = Sud._boule(M.room, R.mat(_verre(R, "boule_cristal", Color(0.75, 0.6, 1.0), 0.45, 1.0)), cx * Vector3(-0.6, 1.24, 0.05), 0.15)
	k.cyl(cx * T3(-0.6, 1.06, 0.05), 0.12, 0.14, 0.05, _c(R, "coussin_violet", Color(0.35, 0.1, 0.45), 0.95), 12)
	(M.ctx["anims170"] as Array).append([boule, "flotte", 0.012, boule.position.y, 0.0])
	_lampe(M, -0.6, 1.4, zc + 0.1, Color(0.7, 0.5, 1.0), 0.8, 2.5)
	var cristal: String = _c(R, "cristal_bleu", Color(0.45, 0.85, 1.0), 0.15, 0.1, 1.8)
	for c in range(7):
		var a: float = TAU * c / 7.0
		k.cyl(cx * Transform3D(Basis(Vector3(cos(a), 0, sin(a)), 0.25 * float(c % 3)), Vector3(0.55 + cos(a) * 0.06, 1.06, 0.05 + sin(a) * 0.06)), 0.03, 0.0, 0.14 + 0.05 * float(c % 3), cristal, 6)
	k.cyl(cx * T3(0.95, 1.06, 0.05), 0.07, 0.09, 0.2, "ceramique", 12)
	for b in range(5):
		k.box(cx * Transform3D(Basis(Vector3.BACK, 0.12 * (b - 2)), Vector3(0.95 + 0.02 * (b - 2), 1.38, 0.05)), Vector3(0.015, 0.4, 0.015), "bois_sombre" if b % 2 else "bois_clair", 1.0)
	var voir := func() -> void:
		M.main.sfx("cristal_chante")
		M.say(str(_pick(M, ["Dans la boule de cristal, des brumes violettes tourbillonnent… On croit voir un chemin, une île, et quelqu'un qui te fait signe. Bientôt.", "La boule s'éclaire : une pluie d'étoiles, puis un chat qui baille. Madame Olga hausse les épaules : « Les visions, ça ne se commande pas. »", "Tu vois ton propre reflet, déformé, avec de grands yeux. « Ça, dit Olga, c'est toi qui regardes la boule. »"])), 6.0)
	M.act(cx * Vector3(-0.6, 0, 0.9), "E : regarder dans la boule de cristal", voir, 1.0)
	# le chaudron qui bouillonne, les bougies qui flottent, le hibou (en peluche)
	var chx: float = hw - 1.3
	var chz: float = hd - 2.0
	k.cyl(R.L(chx, 0.0, chz), 0.32, 0.45, 0.6, "fer", 16)
	k.cyl(R.L(chx, 0.55, chz), 0.36, 0.36, 0.02, _c(R, "potion_verte", Color(0.3, 0.95, 0.45), 0.3, 0.0, 1.6), 16)
	for l in range(3):
		var a2: float = TAU * l / 3.0
		k.box(R.L(chx + cos(a2) * 0.35, 0.12, chz + sin(a2) * 0.35), Vector3(0.06, 0.24, 0.06), "fer", 1.0)
	k.col_box(R.L(chx, 0.3, chz), Vector3(0.9, 0.6, 0.9))
	R.reserve(chx, chz, 1.0, 1.0)
	_lampe(M, chx, 0.9, chz, Color(0.3, 1.0, 0.5), 0.9, 2.8)
	for b2 in range(5):
		var bb: MeshInstance3D = Sud._boule(M.room, R.mat(_c(R, "bulle_verte", Color(0.5, 1.0, 0.6), 0.3, 0.0, 2.0)), R.P(chx - 0.2 + 0.1 * b2, 0.6, chz + 0.06 * float(b2 % 2)), 0.035)
		(M.ctx["anims170"] as Array).append([bb, "flotte", 0.04, bb.position.y, b2 * 1.3])
	var cire: String = _c(R, "cire170", Color(0.95, 0.92, 0.85), 0.6)
	var flamme: Material = R.mat("flamme")
	for f in range(6):
		var bp: Vector3 = R.P(-1.6 + f * 0.65, R.H - 1.0 - 0.25 * float(f % 3), 0.4 + 0.5 * float(f % 2))
		var bg := Node3D.new()
		M.room.add_child(bg)
		bg.global_position = bp
		var cm := MeshInstance3D.new()
		cm.mesh = _cylm(0.025, 0.025, 0.16, 10)
		cm.material_override = R.mat(cire)
		bg.add_child(cm)
		var fm := MeshInstance3D.new()
		fm.mesh = _cylm(0.0, 0.012, 0.035, 6)
		fm.material_override = flamme
		fm.position.y = 0.1
		bg.add_child(fm)
		(M.ctx["anims170"] as Array).append([bg, "flotte", 0.06, bg.position.y, f * 1.1])
	_lampe(M, 0.0, R.H - 1.1, 0.6, Color(1.0, 0.8, 0.5), 0.7, 4.0)
	var hib: Vector3 = R.P(-hw + 0.3, 2.5, -hd + 1.0)
	k.box(R.L(-hw + 0.25, 2.3, -hd + 1.0), Vector3(0.3, 0.04, 0.3), "bois_sombre", 1.0)
	Sud._boule(M.room, R.mat(_c(R, "plume_hibou", Color(0.5, 0.38, 0.25), 0.95)), hib, 0.13, Vector3(1.0, 1.3, 0.9))
	Sud._boule(M.room, R.mat("plume_hibou"), hib + Vector3.UP * 0.2, 0.1)
	for e in [-0.04, 0.04]:
		Sud._boule(M.room, R.mat(_c(R, "oeil_hibou", Color(1.0, 0.75, 0.2), 0.3, 0.0, 1.2)), hib + Vector3(0.09, 0.22, e), 0.025)
	R.tapis(0.0, 0.9, 0.0, 2.6, 1.8)
	var lignes: Array = ["Une baguette ne choisit pas son sorcier. C'est l'inverse. Enfin, je crois.", "Ne touche pas au chaudron : il a ses humeurs.", "Les bougies flottent parce qu'elles sont bien élevées."]
	_marchand(M, 0.0, zc - 0.55, 0.0, "comptoir", "vieille", "Madame Olga", lignes, {"vend": {"potion_mana": 9, "elixir_etoile": 16, "poussiere_fee": 8}, "achete": {"eclat_cristal": 8, "fleur_lune": 12}})
	M.ctx["bonjour170"] = ["Ah… je savais que tu viendrais.", "Entre, entre. Les cristaux m'ont parlé de toi."]
	M.ctx["entree"] = "La boutique de magie : des fioles qui brillent, une boule de cristal, des cristaux bleus, un chaudron qui glougloute… et des bougies qui flottent toutes seules."


# =================================================================== le barbier et polisseur de cornes (Tiburce, Pandémonia)

static func _barbier(M) -> void:
	var R = M.R
	var k = R.kit
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var cuir: String = _c(R, "cuir_rouge170", Color(0.45, 0.06, 0.06), 0.55)
	var mir: String = _c(R, "miroir170", Color(0.62, 0.68, 0.72), 0.04, 0.95)
	# deux fauteuils de barbier devant leurs miroirs, au fond
	for q in range(2):
		var fx: float = -1.3 + q * 2.6
		var fz: float = -hd + 1.4
		k.cyl(R.L(fx, 0, fz), 0.25, 0.3, 0.06, "fer", 14)
		k.cyl(R.L(fx, 0.06, fz), 0.08, 0.1, 0.38, "fer", 10)
		k.box(R.L(fx, 0.5, fz), Vector3(0.6, 0.15, 0.6), cuir, 1.0)
		k.box(R.L(fx, 0.9, fz - 0.28) * Transform3D(Basis(Vector3.RIGHT, -0.25), Vector3.ZERO), Vector3(0.6, 0.75, 0.12), cuir, 1.0)
		for s in [-1.0, 1.0]:
			k.box(R.L(fx + s * 0.32, 0.7, fz), Vector3(0.08, 0.06, 0.6), "or", 1.0)
		k.box(R.L(fx, 0.2, fz + 0.45) * Transform3D(Basis(Vector3.RIGHT, 0.5), Vector3.ZERO), Vector3(0.4, 0.04, 0.3), "fer", 1.0)
		k.col_box(R.L(fx, 0.5, fz), Vector3(0.7, 1.0, 0.7))
		R.reserve(fx, fz, 0.9, 1.2)
		k.box(R.L(fx, 1.7, -hd + 0.04), Vector3(0.9, 1.1, 0.02), mir, 1.0)
		k.box(R.L(fx, 1.7, -hd + 0.03), Vector3(1.0, 1.2, 0.02), "or", 1.0)
		R.mark_wall(fx, 1.7, -hd, 0.55)
		k.box(R.L(fx, 1.05, -hd + 0.2), Vector3(1.0, 0.05, 0.36), "pierre_lisse", 1.0)
		_fioles(R, R.L(fx - 0.4, 1.075, -hd + 0.15), 7, 0.12, q * 3, 0.3)
	# l'atelier des cornes : les cornes sur leurs supports, l'huile
	var C: Transform3D = R.L(hw - 0.5, 0, 0.0, -90.0)
	k.box(C * T3(0, 0.45, 0), Vector3(1.8, 0.9, 0.6), "bois_sombre", 1.0)
	k.box(C * T3(0, 0.92, 0), Vector3(1.85, 0.05, 0.65), "pierre_lisse", 1.0)
	var corne: String = _c(R, "corne170", Color(0.25, 0.12, 0.08), 0.25, 0.1)
	for c in range(4):
		var cxp: float = -0.6 + c * 0.4
		k.cyl(C * T3(cxp, 0.95, 0), 0.04, 0.04, 0.08, "bois", 8)
		k.cyl(C * Transform3D(Basis(Vector3.BACK, 0.2 - 0.12 * c), Vector3(cxp, 1.03, 0)), 0.05, 0.0, 0.3 + 0.05 * c, corne, 10)
	_fioles(R, C * T3(0.5, 0.945, 0.15), 3, 0.12, 4, 0.0)
	k.col_box(C * T3(0, 0.45, 0), Vector3(1.8, 0.9, 0.6))
	R.reserve(hw - 0.5, 0.0, 0.8, 2.0)
	var tarif: String = _img(R, "tarifs_cornes", "beau170/tarifs_cornes.png")
	_cadre(R, tarif, hw - 0.02, 1.75, -1.6, -90.0, 0.8, 1.0)
	_ecrit(M, 0.0, R.H - 0.5, -hd + 0.03, 0.0, "TIBURCE — BARBE & CORNES", 52, Color(1.0, 0.82, 0.45), 0.004)
	R.banc(-hw + 0.5, 1.0, 90.0, 1.8)
	for t in range(4):
		k.box(R.L(-hw + 0.5, 1.05 + t * 0.06, -hd + 2.6), Vector3(0.4, 0.05, 0.3), _c(R, "serviette", Color(0.95, 0.95, 0.92), 0.95), 1.0)
	k.box(R.L(-hw + 0.5, 0.5, -hd + 2.6), Vector3(0.5, 1.0, 0.4), "bois_sombre", 1.0)
	k.col_box(R.L(-hw + 0.5, 0.6, -hd + 2.6), Vector3(0.5, 1.2, 0.4))
	R.reserve(-hw + 0.5, -hd + 2.6, 0.6, 0.6)
	var client: Node = M.person("homme", 1.3, -hd + 1.4, 180.0, "assis", "Gargouillon")
	client.npc.global_position += Vector3.UP * 0.12
	client.lines = ["Pas trop pointues, les cornes, hein. J'ai un rendez-vous.", "Ça brille ? Dis-moi que ça brille."]
	var lignes: Array = ["Une corne bien polie, c'est une âme bien rangée.", "Barbe, moustache, cornes : je fais tout ce qui pousse.", "Tiens-toi tranquille, ou je te fais une raie au milieu."]
	_marchand(M, 1.3 - 0.75, -hd + 1.6, 90.0, "bricoler", "homme", "Tiburce", lignes, {"vend": {"huile_cornes": 8}, "achete": {"perle": 11, "corail_rouge": 9}})
	M.ctx["bonjour170"] = ["Entre ! Un polissage ? Un rasage ? Les deux ?", "Bienvenue chez Tiburce ! Assieds-toi, c'est bientôt ton tour."]
	M.ctx["entree"] = "Chez Tiburce, barbe et cornes : deux fauteuils de cuir rouge, des miroirs dorés, des flacons d'huile, et des cornes qui brillent sur leurs supports."


# =================================================================== les ateliers : l'inventeur (Zigomar), le Professeur Boum, la fabrique de robots (Maître Rivet)

## Un robot en construction (le tronc, la tête, les bras) sur son socle ; fini : de 0 à 1.
static func _robot(M, x: float, z: float, yaw: float, fini: float) -> void:
	var R = M.R
	var k = R.kit
	var xf: Transform3D = R.L(x, 0, z, yaw)
	var laiton: String = _c(R, "robot_laiton", Color(0.82, 0.62, 0.3), 0.35, 0.8)
	k.cyl(xf, 0.35, 0.38, 0.15, "fer", 16)
	k.cyl(xf * T3(0, 0.15, 0), 0.05, 0.05, 0.4, "fer", 8)
	k.box(xf * T3(0, 0.85, 0), Vector3(0.55, 0.65, 0.38), laiton, 1.0)
	k.cyl(xf * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0.9, 0.2)), 0.1, 0.1, 0.02, "cuivre", 14)
	if fini > 0.4:
		k.cyl(xf * T3(0, 1.18, 0), 0.06, 0.06, 0.08, "fer", 8)
		k.box(xf * T3(0, 1.38, 0), Vector3(0.36, 0.3, 0.32), laiton, 1.0)
		for e in [-0.08, 0.08]:
			k.cyl(xf * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(e, 1.4, 0.16)), 0.04, 0.04, 0.02, _c(R, "oeil_robot", Color(0.4, 0.9, 1.0), 0.3, 0.0, 2.5) if fini > 0.8 else "noir", 10)
	if fini > 0.7:
		for s in [-1.0, 1.0]:
			k.cyl(xf * Transform3D(Basis(Vector3.BACK, s * 0.2), Vector3(s * 0.34, 0.65, 0)), 0.05, 0.045, 0.5, "fer", 8)
	else:
		k.cyl(xf * Transform3D(Basis(Vector3.BACK, 0.15), Vector3(0.34, 0.65, 0)), 0.05, 0.045, 0.5, "fer", 8)
		k.cyl(xf * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(-0.3, 0.9, 0)), 0.02, 0.02, 0.15, "cuivre", 6)
	k.col_box(xf * T3(0, 0.75, 0), Vector3(0.75, 1.5, 0.75))
	R.reserve(x, z, 0.9, 0.9)


## Des étincelles (la soudure, la meule).
static func _etincelles(M, at: Vector3) -> void:
	var p := CPUParticles3D.new()
	p.amount = 16
	p.lifetime = 0.5
	p.direction = Vector3.UP
	p.spread = 60.0
	p.initial_velocity_min = 0.8
	p.initial_velocity_max = 1.6
	p.gravity = Vector3(0, -4.0, 0)
	var q := QuadMesh.new()
	q.size = Vector2(0.02, 0.02)
	p.mesh = q
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.albedo_color = Color(1.0, 0.85, 0.4)
	p.material_override = m
	M.room.add_child(p)
	p.global_position = at


static func _atelier(M) -> void:
	var R = M.R
	var k = R.kit
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var fabrique: bool = str(M.cur.get("metier", "")) == "fabrique"
	# les établis, la grande roue dentée au mur, les plans punaisés
	R.etabli(-hw + 1.4, -hd + 0.8, 0.0, 2.4)
	R.etabli(hw - 0.8, -0.2, -90.0, 2.2)
	var mo: Material = R.mat("cuivre")
	var mf: Material = R.mat("fer")
	var gb: Basis = Basis(Vector3.RIGHT, PI * 0.5)
	_engrenage(M, R.P(1.2, 2.2, -hd + 0.1), gb, 0.6, 18, 0.06, 0.35, mo)
	_engrenage(M, R.P(1.2 + 0.95, 2.2 - 0.25, -hd + 0.1), gb, 0.32, 10, 0.06, -0.65, mf)
	_engrenage(M, R.P(1.2 - 0.6, 2.2 + 0.78, -hd + 0.1), gb, 0.3, 9, 0.06, -0.7, mf)
	R.mark_wall(1.4, 2.3, -hd, 1.4)
	var plan: String = _img(R, "schema170", "beau170/schema_robot.png")
	_cadre(R, plan, -hw + 0.02, 1.8, -hd + 2.6, 90.0, 1.2, 0.85, "")
	var bp: String = _img(R, "schema170b", "beau170/schema_fusee.png")
	_cadre(R, bp, -hw + 0.02, 1.8, -hd + 4.0, 90.0, 0.9, 0.9, "")
	_etincelles(M, R.P(-hw + 1.4, 0.95, -hd + 0.8))
	_lampe(M, -hw + 1.4, 1.2, -hd + 1.0, Color(0.7, 0.85, 1.0), 0.6, 2.2)
	if fabrique:
		# la chaîne de montage : les robots à moitié faits, le tapis roulant, le crochet de la grue
		for r in range(3):
			_robot(M, -2.4 + r * 2.0, 0.9, 0.0 if r != 1 else 20.0, 0.3 + 0.35 * r)
		var tz: float = -0.9
		k.box(R.L(0, 0.55, tz), Vector3(R.W - 3.0, 0.08, 0.6), _c(R, "tapis_roulant", Color(0.12, 0.12, 0.13), 0.8), 1.0)
		for rr in range(int((R.W - 3.0) / 0.5)):
			k.cyl(R.L(-(R.W - 3.0) * 0.5 + 0.25 + rr * 0.5, 0.5, tz) * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0, -0.3)), 0.05, 0.05, 0.6, "metal", 8)
		for lg in range(4):
			k.box(R.L(-(R.W - 3.0) * 0.5 + 0.2 + lg * (R.W - 3.4) / 3.0, 0.25, tz), Vector3(0.08, 0.5, 0.5), "fer", 1.0)
		for tete in range(3):
			k.box(R.L(-1.6 + tete * 1.2, 0.74, tz), Vector3(0.3, 0.28, 0.28), "robot_laiton", 1.0)
		k.col_box(R.L(0, 0.3, tz), Vector3(R.W - 3.0, 0.6, 0.6))
		R.reserve(0, tz, R.W - 2.8, 0.9)
		k.box(R.L(0.4, R.H - 0.3, 0.0), Vector3(0.2, 0.2, R.D - 1.0), "fer", 1.0)
		k.box(R.L(0.4, R.H - 0.5, 1.6), Vector3(0.4, 0.3, 0.4), "fer", 1.0)
		k.cyl(R.L(0.4, R.H - 2.0, 1.6), 0.01, 0.01, 1.4, "fer", 4, false)
		k.ring(R.L(0.4, R.H - 2.08, 1.6) * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 0.05, 0.08, 0.03, "fer", 10)
		_rayons(M, hw - 1.0, -hd + 0.22, 0.0, 1.35, 2.4, 5, "outils", 3)
	else:
		# les fusées et les pétards rangés (pour les fêtes), les bidons, le panneau « DANGER »
		var bouton: Vector3 = R.machine(hw - 1.3, hd - 2.1, -90.0)
		# la grande table au milieu : l'oiseau mécanique (pas encore fini), les rouages, la lanterne
		R.table(-0.7, 0.3, 0.0, 1.9, 1.0, 0.85)
		var oiseau: MeshInstance3D = Sud._boule(M.room, R.mat("cuivre"), R.P(-0.9, 1.05, 0.3), 0.17, Vector3(1.4, 1.0, 1.0))
		oiseau.name = "Oiseau"
		for s2 in [-1.0, 1.0]:
			k.box(R.L(-0.9, 1.1, 0.3 + s2 * 0.32) * Transform3D(Basis(Vector3.RIGHT, s2 * 0.35), Vector3.ZERO), Vector3(0.36, 0.015, 0.4), "laiton" if R.mat("laiton") != null else "or", 1.0)
		k.cyl(R.L(-0.62, 1.07, 0.3) * Transform3D(Basis(Vector3.BACK, -PI * 0.5), Vector3.ZERO), 0.05, 0.0, 0.14, "or", 8)
		for g2 in range(6):
			k.cyl(R.L(-0.2 + 0.09 * cos(g2 * 1.9), 0.86, 0.1 + 0.08 * g2), 0.03 + 0.012 * float(g2 % 3), 0.03 + 0.012 * float(g2 % 3), 0.008, "or" if g2 % 2 else "cuivre", 10)
		_lanterne(M, -0.7, 0.3, 1.05, true)
		# la roue de feu d'artifice au mur (elle tourne)
		var roue := Node3D.new()
		M.room.add_child(roue)
		roue.global_transform = R.L(-1.7, 2.1, -hd + 0.15) * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO)
		var jante := MeshInstance3D.new()
		jante.mesh = _cylm(0.35, 0.35, 0.03, 20)
		jante.material_override = R.mat("bois_sombre")
		roue.add_child(jante)
		for f3 in range(6):
			var a3: float = TAU * f3 / 6.0
			var fu := MeshInstance3D.new()
			fu.mesh = _cylm(0.035, 0.035, 0.28, 8)
			fu.material_override = R.mat(_c(R, "fusee_%d" % (f3 % 4), [Color(0.85, 0.15, 0.15), Color(0.15, 0.4, 0.85), Color(0.95, 0.8, 0.15), Color(0.2, 0.7, 0.35)][f3 % 4], 0.6))
			fu.position = Vector3(cos(a3) * 0.38, 0.03, sin(a3) * 0.38)
			fu.rotation = Vector3(PI * 0.5, -a3, 0)
			roue.add_child(fu)
		(M.ctx["anims170"] as Array).append([roue, "tourne", Vector3.UP, 0.8])
		R.mark_wall(-1.7, 2.1, -hd, 0.5)
		_lampe(M, 0.0, R.H - 0.9, 0.3, Color(1.0, 0.85, 0.65), 1.0, 9.0)
		var cols: Array = [Color(0.85, 0.15, 0.15), Color(0.15, 0.4, 0.85), Color(0.95, 0.8, 0.15), Color(0.2, 0.7, 0.35)]
		var rk: Transform3D = R.L(hw - 0.3, 0, -hd + 2.0, -90.0)
		k.box(rk * T3(0, 0.6, -0.1), Vector3(1.6, 1.2, 0.05), "bois_sombre", 1.0)
		for f in range(7):
			var fxp: float = -0.65 + f * 0.22
			var fk: String = _c(R, "fusee_%d" % (f % 4), cols[f % 4], 0.6)
			k.cyl(rk * T3(fxp, 0.3, 0.05), 0.05, 0.05, 0.6, fk, 10)
			k.cyl(rk * T3(fxp, 0.9, 0.05), 0.055, 0.0, 0.15, fk, 10)
			k.box(rk * T3(fxp, 0.15, 0.05), Vector3(0.008, 0.3, 0.008), "bois_clair", 1.0)
		k.col_box(rk * T3(0, 0.6, 0), Vector3(1.6, 1.2, 0.3))
		R.reserve(hw - 0.3, -hd + 2.0, 0.5, 1.8)
		for b in range(3):
			k.cyl(R.L(-hw + 0.5 + b * 0.5, 0, hd - 1.3), 0.2, 0.2, 0.6, _c(R, "bidon_%d" % b, [Color(0.6, 0.15, 0.1), Color(0.3, 0.35, 0.4), Color(0.75, 0.6, 0.15)][b], 0.5, 0.4), 14)
		k.col_box(R.L(-hw + 1.0, 0.3, hd - 1.3), Vector3(1.4, 0.6, 0.45))
		R.reserve(-hw + 1.0, hd - 1.3, 1.6, 0.6)
		var danger: Label3D = _ecrit(M, 0.0, R.H - 0.6, -hd + 0.04, 0.0, "DANGER ! ÇA PEUT FAIRE BOUM", 44, Color(1.0, 0.85, 0.15), 0.0035)
		danger.outline_modulate = Color(0.2, 0.05, 0.0, 1.0)
		var suie: String = _img(R, "suie170", "beau170/suie.png", 2)
		for tache in range(4):
			k.quad(R.L(-2.0 + tache * 1.3, 1.0 + 0.6 * float(tache % 2), -hd + 0.035) * Transform3D(Basis(Vector3.UP, PI), Vector3.ZERO), 0.8, 0.6, suie)
		var essai := func() -> void:
			M.main.sfx("confettis")
			M.say(str(_pick(M, ["Tu tournes la manivelle. PAF ! Une pluie de confettis jaillit de la machine, et une petite voix mécanique dit : « Joyeux non-anniversaire ! »", "La machine tousse, crache un nuage de fumée rose, et dépose une bille dans ta main. Elle est… inutile. Mais jolie.", "Rien ne se passe. Puis, très lentement, un petit drapeau sort : « BRAVO ». La machine est contente d'elle."])), 6.0)
		M.act(bouton, "E : tourner la manivelle de la machine", essai, 1.0)
	var lignes: Array = ["Recule ! … Non, c'est bon. Fausse alerte.", "Cette machine fait des étincelles. C'est voulu. Presque.", "Une invention, c'est une idée qui n'a pas peur du ridicule."]
	if fabrique:
		lignes = ["Encore un boulon, et celui-là marchera. Peut-être même dans le bon sens.", "Mes robots ? Ils sont gentils. Le troisième est un peu timide.", "Passe-moi la clé de douze ! … Merci. Ah non, c'est une cuillère."]
	var mp: Vector3 = Vector3(-1.65, 0, 1.5) if fabrique else Vector3(-hw + 1.4, 0, -hd + 1.4)
	_marchand(M, mp.x, mp.z, -126.0 if fabrique else 180.0, "bricoler", "homme", "Maître Écrou", lignes, {"vend": {"engrenage": 3, "ressort": 2}, "achete": {"boulon": 1, "engrenage": 2, "minerai_fer": 3}})
	var tick := func(delta: float) -> void:
		var tt: float = float(M.ctx.get("soudure_t", 2.0)) - delta
		if tt <= 0.0:
			tt = _r(M).randf_range(3.0, 6.0)
			M.main.sfx("soudure" if fabrique else "piston", M.R.P(-M.R.W * 0.5 + 1.4, 1.0, -M.R.D * 0.5 + 0.8), -16.0)
		M.ctx["soudure_t"] = tt
	M.ctx["tick170"] = tick
	M.ctx["cloche170"] = false
	M.ctx["bonjour170"] = ["Ah ! Un visiteur ! Ne touche à rien, tout est branché.", "Bienvenue à l'atelier ! Lunettes de protection conseillées."]
	M.ctx["entree"] = ("%s : les établis encombrés, les engrenages qui tournent au mur, les plans punaisés, l'odeur d'huile et de poudre." if not fabrique else "%s : la chaîne de montage, des robots à moitié finis, le tapis roulant, les étincelles de la soudure.") % str(M.cur.get("enseigne170", "L'atelier"))


# =================================================================== la poissonnerie (Moloka, Pandémonia)

## Un poisson sur la glace (le corps, la queue) ; xf : sa tête vers +x, couché.
static func _poisson(R, xf: Transform3D, c: Color, l: float) -> void:
	var k = R.kit
	var m: String = _c(R, "poisson_%s" % c.to_html(false), c, 0.3, 0.3)
	k.cyl(xf * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(l * 0.35, 0, 0)) * Transform3D(Basis.from_scale(Vector3(1.0, 1.0, 0.45)), Vector3.ZERO), l * 0.16, l * 0.1, l * 0.7, m, 10)
	k.tri(m, xf * Vector3(-l * 0.35, 0, 0), xf * Vector3(-l * 0.6, l * 0.14, 0), xf * Vector3(-l * 0.6, -l * 0.14, 0), xf.basis * Vector3(0, 0, 1), Vector2(0, 0), Vector2(1, 0), Vector2(0, 1))
	k.tri(m, xf * Vector3(-l * 0.35, 0, 0), xf * Vector3(-l * 0.6, -l * 0.14, 0), xf * Vector3(-l * 0.6, l * 0.14, 0), xf.basis * Vector3(0, 0, -1), Vector2(0, 0), Vector2(1, 0), Vector2(0, 1))


static func _poissonnerie(M) -> void:
	var R = M.R
	var k = R.kit
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var glace: String = _c(R, "glace_pilee", Color(0.85, 0.92, 0.98), 0.25)
	var cols: Array = [Color(0.6, 0.65, 0.72), Color(0.85, 0.35, 0.3), Color(0.45, 0.55, 0.6), Color(0.9, 0.7, 0.35), Color(0.35, 0.4, 0.55)]
	var zc: float = -hd + 1.8
	var cx: Transform3D = _comptoir(M, 0.0, zc, R.W - 2.4, 0.0, false, 0.9, "bois_sombre", "metal")
	k.box(cx * Transform3D(Basis(Vector3.RIGHT, 0.25), Vector3(0, 0.98, 0.05)), Vector3(R.W - 2.6, 0.08, 0.6), glace, 1.0)
	for f in range(int((R.W - 3.0) / 0.4)):
		var fxp: float = -(R.W - 3.0) * 0.5 + f * 0.4
		_poisson(R, cx * Transform3D(Basis(Vector3.RIGHT, 0.25), Vector3(fxp + 0.2, 1.04, 0.05)) * Transform3D(Basis(Vector3.UP, 0.3 * float(f % 2) - 0.15) * Basis(Vector3.RIGHT, -PI * 0.5), Vector3.ZERO), cols[f % cols.size()], 0.38 + 0.06 * float(f % 3))
	var E: Transform3D = R.L(-1.4, 0, 0.5)
	k.box(E * T3(0, 0.4, 0), Vector3(2.0, 0.8, 0.9), "bois_sombre", 1.0)
	k.box(E * T3(0, 0.82, 0), Vector3(2.0, 0.06, 0.9), glace, 1.0)
	for f2 in range(8):
		_poisson(R, E * Transform3D(Basis(Vector3.UP, 0.4 * float(f2 % 3) - 0.4) * Basis(Vector3.RIGHT, -PI * 0.5), Vector3(-0.75 + (f2 % 4) * 0.5, 0.88, -0.2 + 0.4 * float(f2 / 4))), cols[(f2 + 2) % cols.size()], 0.42)
	for c in range(5):
		k.cyl(E * T3(0.55 + 0.08 * c, 0.86, 0.3 - 0.1 * float(c % 2)), 0.05, 0.0, 0.03, _c(R, "coquille", Color(0.95, 0.88, 0.85), 0.4, 0.1), 8)
	k.col_box(E * T3(0, 0.45, 0), Vector3(2.0, 0.9, 0.9))
	R.reserve(-1.4, 0.5, 2.2, 1.1)
	# les filets au mur, les seaux, les casiers à crabes, la balance
	var filet: String = _tex(R, "filet170", "azur/filet.png", Color(0.75, 0.7, 0.65))
	k.quad(R.L(-hw + 0.04, 2.0, -0.2, 90.0) * Transform3D(Basis(Vector3.UP, PI), Vector3.ZERO), 2.6, 1.3, filet, Vector2(0, 0), Vector2(3, 1.5))
	k.quad(R.L(hw - 0.04, 2.0, -0.2, -90.0) * Transform3D(Basis(Vector3.UP, PI), Vector3.ZERO), 2.6, 1.3, filet, Vector2(0, 0), Vector2(3, 1.5))
	for b in range(3):
		k.cyl(R.L(hw - 0.6, 0, hd - 1.4 - b * 0.45), 0.18, 0.15, 0.32, "metal", 12)
		k.cyl(R.L(hw - 0.6, 0.28, hd - 1.4 - b * 0.45), 0.165, 0.165, 0.01, _verre(R, "eau170", Color(0.2, 0.35, 0.4), 0.8), 12)
	k.col_box(R.L(hw - 0.6, 0.2, hd - 1.85), Vector3(0.45, 0.4, 1.4))
	R.reserve(hw - 0.6, hd - 1.85, 0.6, 1.6)
	for cg in range(2):
		var cgx: float = -hw + 0.6
		var cgz: float = hd - 1.4 - cg * 0.7
		k.box(R.L(cgx, 0.25, cgz), Vector3(0.6, 0.5, 0.5), "bois", 1.0)
		for bb in range(4):
			k.box(R.L(cgx - 0.22 + bb * 0.15, 0.25, cgz + 0.26), Vector3(0.02, 0.5, 0.02), "bois_sombre", 1.0)
		k.col_box(R.L(cgx, 0.25, cgz), Vector3(0.6, 0.5, 0.5))
		R.reserve(cgx, cgz, 0.7, 0.6)
	_balance(R, cx * T3(R.W * 0.5 - 1.5, 0.95, 0.15))
	var lignes: Array = ["Frais de ce matin ! Il nageait encore à l'aube.", "Celui-là, c'est un poisson de lave. Il se mange froid.", "Un maquereau ? Deux maquereaux ? Toute la famille maquereau ?"]
	_marchand(M, 0.0, zc - 0.55, 0.0, "comptoir", "femme", "Moloka", lignes, {"vend": {"maquereau": 6, "sardine": 4}, "achete": {"sardine": 2, "maquereau": 4, "dorade": 6, "bar": 7}})
	M.ctx["bonjour170"] = ["Frais, frais, tout est frais !", "Entre ! Ça sent la mer, hein ?"]
	M.ctx["entree"] = "La poissonnerie : les étals de glace pilée, les poissons en rang, les filets aux murs, les seaux et les casiers à crabes."


# =================================================================== l'Académie des Ingénieurs (Héloïse Manivelle, Cliquetis)

static func _academie(M) -> void:
	var R = M.R
	var k = R.kit
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	# l'estrade, le bureau, le grand tableau noir couvert de rouages et de formules
	k.box(R.L(0, 0.1, -hd + 1.0), Vector3(R.W - 2.0, 0.2, 2.0), "bois_sombre", 1.0)
	k.col_box(R.L(0, 0.1, -hd + 1.0), Vector3(R.W - 2.0, 0.2, 2.0))
	var tn: String = _img(R, "tableau_noir170", "beau170/tableau_noir.png")
	_cadre(R, tn, 0.0, 1.85, -hd + 0.03, 0.0, 4.2, 1.6, "bois")
	k.box(R.L(0, 1.0, -hd + 0.1), Vector3(4.2, 0.04, 0.12), "bois", 1.0)
	for cr in range(3):
		k.box(R.L(-1.2 + cr * 0.15, 1.03, -hd + 0.1), Vector3(0.08, 0.015, 0.015), "ceramique", 1.0)
	R.table(1.8, -hd + 1.4, 0.0, 1.6, 0.8)
	k.box(R.L(1.6, 0.78, -hd + 1.4), Vector3(0.3, 0.05, 0.22), "livres", 1.0)
	var globe: MeshInstance3D = Sud._boule(M.room, R.mat("cuivre"), R.P(2.3, 0.95, -hd + 1.4), 0.14)
	(M.ctx["anims170"] as Array).append([globe, "tourne", Vector3.UP, 0.4])
	# la démonstration : un grand mécanisme à engrenages, au mur de droite
	var gb: Basis = Basis(Vector3.UP, deg_to_rad(-90.0)) * Basis(Vector3.RIGHT, PI * 0.5)
	_engrenage(M, R.P(hw - 0.12, 2.0, -hd + 1.4), gb, 0.5, 16, 0.05, 0.4, R.mat("or"))
	_engrenage(M, R.P(hw - 0.12, 1.55, -hd + 1.4 + 0.75), gb, 0.25, 9, 0.05, -0.8, R.mat("cuivre"))
	_engrenage(M, R.P(hw - 0.12, 2.6, -hd + 1.4 + 0.55), gb, 0.2, 7, 0.05, -1.0, R.mat("cuivre"))
	R.mark_wall(hw, 2.0, -hd + 1.8, 1.0)
	# les pupitres des élèves, en rangs, face au tableau
	for r in range(3):
		var dz: float = -hd + 3.0 + r * 1.3
		for c in range(4):
			var dx: float = -3.3 + c * 2.2
			R.table(dx, dz, 0.0, 1.2, 0.5, 0.75)
			R.tabouret(dx, dz + 0.5)
			k.box(R.L(dx - 0.2, 0.765, dz, 8.0), Vector3(0.3, 0.012, 0.22), "papier", 1.0)
	var eleves: Array = [["garcon", -3.3, 0], ["fille", -1.1, 0], ["fille", 1.1, 1], ["garcon", 3.3, 1], ["garcon", -1.1, 2]]
	for e in eleves:
		var p: Node = M.person(str(e[0]), float(e[1]), -hd + 3.0 + float(e[2]) * 1.3 + 0.5, 180.0, "lire")
		p.lines = [str(_pick(M, ["Madame ! Madame ! J'ai compris ! … Non, en fait.", "Si l'engrenage A tourne à gauche, le B tourne… à droite ?", "Mon robot a mangé mes devoirs.", "Quand est-ce qu'on fait exploser quelque chose ?"]))]
	_lustre(M, 0.0, 0.4, 0.6, 1.3)
	var cours := func() -> void:
		var f: Variant = M.ctx.get("marchand", null)
		if f != null and is_instance_valid(f):
			f.say(str(_pick(M, ["Un engrenage, c'est une roue qui a des dents… et de l'ambition !", "Retenez bien : un ressort qui se tend finit toujours par se détendre. Comme les élèves.", "La vapeur pousse, le rouage tourne, l'ingénieur sourit. C'est tout le programme."])), 4.0)
		M.say("Tu t'assois au fond de la classe. Au tableau, des rouages, des flèches, et une formule qui finit par « = MERVEILLEUX ».", 5.0)
	M.act(R.P(3.3, 0, -hd + 3.0 + 2 * 1.3 + 0.9), "E : s'asseoir et écouter le cours", cours, 1.2)
	var lignes: Array = ["Silence dans les rangs ! Les engrenages travaillent.", "Qui peut me dire pourquoi la vapeur monte ? … Oui, parce qu'elle est chaude.", "L'erreur est la mère de l'invention. Et l'explosion, sa cousine."]
	_marchand(M, -0.8, -hd + 1.2, 0.0, "enseigner", "femme", "Madame Manivelle", lignes, {"bonjour": "Bienvenue à l'Académie des Ingénieurs ! Un nouvel élève ?", "infos": ["Ici, on apprend à visser, à dévisser, et surtout à ne pas tout faire sauter. Surtout."]})
	M.ctx["cloche170"] = false
	M.ctx["bonjour170"] = ["Ah ! Un nouvel élève ? Assieds-toi au fond.", "Bienvenue à l'Académie ! Le cours a commencé."]
	M.ctx["entree"] = "L'Académie des Ingénieurs : le tableau noir couvert de rouages, les pupitres alignés, un grand mécanisme qui tourne au mur."


# =================================================================== le laboratoire Volta (Docteure Électre Volta, Cliquetis)

## Une bobine de Tesla (le socle, l'enroulement de cuivre, le tore au sommet) ; renvoie son sommet.
static func _bobine(M, x: float, z: float, h: float) -> Vector3:
	var R = M.R
	var k = R.kit
	k.cyl(R.L(x, 0, z), 0.35, 0.4, 0.3, "bois_sombre", 16)
	k.cyl(R.L(x, 0.3, z), 0.12, 0.12, h, _c(R, "bobine_cuivre", Color(0.85, 0.45, 0.2), 0.3, 0.9), 16)
	for r in range(int(h / 0.08)):
		k.ring(R.L(x, 0.32 + r * 0.08, z), 0.12, 0.13, 0.02, "cuivre", 16)
	k.ring(R.L(x, 0.3 + h + 0.05, z), 0.12, 0.32, 0.12, "argent", 24)
	k.col_box(R.L(x, (0.3 + h) * 0.5, z), Vector3(0.7, 0.3 + h, 0.7))
	R.reserve(x, z, 0.9, 0.9)
	return R.P(x, 0.3 + h + 0.12, z)


static func _labo(M) -> void:
	var R = M.R
	var k = R.kit
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var top1: Vector3 = _bobine(M, -hw + 1.3, -hd + 1.3, 2.0)
	var top2: Vector3 = _bobine(M, hw - 1.3, -hd + 1.3, 2.0)
	var arc := OmniLight3D.new()
	arc.light_color = Color(0.6, 0.75, 1.0)
	arc.light_energy = 0.0
	arc.omni_range = 6.0
	M.room.add_child(arc)
	arc.global_position = (top1 + top2) * 0.5
	var eclair := MeshInstance3D.new()
	var em := StandardMaterial3D.new()
	em.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	em.albedo_color = Color(0.8, 0.9, 1.0)
	eclair.mesh = _boitem(top1.distance_to(top2), 0.025, 0.025)
	eclair.material_override = em
	M.room.add_child(eclair)
	eclair.global_position = (top1 + top2) * 0.5
	eclair.visible = false
	# le tableau des manettes et des cadrans, le grand levier
	var P: Transform3D = R.L(0, 0, -hd + 0.15)
	k.box(P * T3(0, 1.3, 0), Vector3(2.4, 1.8, 0.25), "fer", 1.0)
	var cad: String = _img(R, "cadran170", "cliquetis/cadran.png")
	for d in range(3):
		k.cyl(P * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(-0.7 + d * 0.7, 1.7, 0.13)), 0.2, 0.2, 0.02, "or", 18)
		k.quad(P * Transform3D(Basis(Vector3.UP, PI), Vector3(-0.7 + d * 0.7, 1.7, 0.145)), 0.34, 0.34, cad)
	for s in range(6):
		k.box(P * T3(-1.0 + s * 0.4, 1.0, 0.14), Vector3(0.06, 0.18, 0.06), "noir", 1.0)
		k.cyl(P * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(-1.0 + s * 0.4, 0.82, 0.13)), 0.03, 0.03, 0.02, _c(R, "voyant_%d" % (s % 3), [Color(1, 0.2, 0.15), Color(0.2, 1, 0.3), Color(1, 0.85, 0.2)][s % 3], 0.3, 0.0, 2.5), 10)
	var levier := Node3D.new()
	M.room.add_child(levier)
	levier.global_transform = P * T3(1.45, 1.0, 0.1)
	var lm := MeshInstance3D.new()
	lm.mesh = _boitem(0.05, 0.6, 0.05)
	lm.material_override = R.mat("fer")
	lm.position.y = 0.3
	levier.add_child(lm)
	var lp := MeshInstance3D.new()
	lp.mesh = _cylm(0.05, 0.05, 0.12, 10)
	lp.material_override = R.mat(_c(R, "poignee_rouge", Color(0.8, 0.1, 0.1), 0.4))
	lp.position.y = 0.62
	levier.add_child(lp)
	levier.rotation.x = 0.5
	k.col_box(P * T3(0, 1.3, 0), Vector3(2.4, 1.8, 0.3))
	R.reserve(0, -hd + 0.15, 2.6, 0.6)
	R.mark_wall(0, 1.3, -hd, 1.3)
	# les paillasses : les fioles, les bocaux, la bouteille d'éclair
	R.table(-hw + 1.2, 0.8, 90.0, 2.0, 0.8, 0.9)
	R.table(hw - 1.2, 0.8, -90.0, 2.0, 0.8, 0.9)
	_fioles(R, R.L(-hw + 1.2, 0.9, 0.2, 90.0), 8, 0.14, 2, 0.6)
	_bocaux(R, R.L(hw - 1.2, 0.9, 1.4, -90.0), 4, 0.25, 0.09, 0.3, 5)
	Sud._boule(M.room, R.mat(_verre(R, "eclair_bouteille", Color(0.6, 0.8, 1.0), 0.5, 3.0)), R.P(-hw + 1.2, 1.1, 1.4), 0.15)
	_lampe(M, -hw + 1.2, 1.3, 1.4, Color(0.6, 0.8, 1.0), 0.7, 2.4)
	for c in range(3):
		k.cyl(R.L(0, R.H - 0.3 - c * 0.05, -hd + 1.3 + c * 0.08) * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(0, -(R.W - 2.6) * 0.5, 0)), 0.02, 0.02, R.W - 2.6, "noir", 6)
	# la dynamo : son socle de fonte, ses deux bobines de cuivre, la grande roue qui tourne
	var dx: float = -1.9
	var dz2: float = 0.5
	k.box(R.L(dx, 0.25, dz2), Vector3(1.4, 0.5, 0.8), "fer", 1.0)
	for s3 in [-0.35, 0.35]:
		k.cyl(R.L(dx + s3, 0.72, dz2 - 0.25) * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 0.2, 0.2, 0.5, "bobine_cuivre", 16)
	k.box(R.L(dx + 0.85, 0.6, dz2), Vector3(0.12, 0.7, 0.12), "fer", 1.0)
	var roue := Node3D.new()
	M.room.add_child(roue)
	roue.global_transform = Transform3D(Basis(Vector3.BACK, PI * 0.5), R.P(dx + 0.97, 0.95, dz2))
	var jante := MeshInstance3D.new()
	jante.mesh = _cylm(0.45, 0.45, 0.05, 28)
	jante.material_override = R.mat("fer")
	roue.add_child(jante)
	for r4 in range(6):
		var rai := MeshInstance3D.new()
		rai.mesh = _boitem(0.85, 0.06, 0.05)
		rai.material_override = R.mat("cuivre")
		rai.rotation.y = r4 * PI / 6.0
		roue.add_child(rai)
	(M.ctx["anims170"] as Array).append([roue, "tourne", Vector3.UP, 2.2])
	k.col_box(R.L(dx + 0.1, 0.5, dz2), Vector3(1.8, 1.0, 1.0))
	R.reserve(dx + 0.1, dz2, 2.0, 1.2)
	var abaisser := func() -> void:
		M.ctx["arc_t"] = 1.6
		levier.rotation.x = -0.5
		M.main.sfx("tesla", (top1 + top2) * 0.5)
		var f: Variant = M.ctx.get("marchand", null)
		if f != null and is_instance_valid(f):
			f.say(str(_pick(M, ["ÇA MARCHE ! Euh… recule un peu, quand même.", "Tu as senti ? Tes cheveux se dressent ! C'est scientifique.", "Ah, la belle étincelle ! Je ne m'en lasse pas."])), 3.5)
	M.act(P * Vector3(1.45, 0, 0.9), "E : abaisser le grand levier", abaisser, 1.0)
	var dir: Vector3 = top2 - top1
	var tick := func(delta: float) -> void:
		var t: float = float(M.ctx.get("arc_t", 0.0))
		var auto: float = float(M.ctx.get("arc_auto", 5.0)) - delta
		if auto <= 0.0:
			auto = _r(M).randf_range(6.0, 11.0)
			t = maxf(t, 0.35)
			M.main.sfx("tesla", (top1 + top2) * 0.5, -10.0)
		M.ctx["arc_auto"] = auto
		var on: bool = t > 0.0 and fmod(t * 23.0, 1.0) < 0.6
		eclair.visible = on
		arc.light_energy = 2.5 if on else 0.0
		if on:
			eclair.rotation = Vector3(_r(M).randf_range(-0.1, 0.1), atan2(-dir.z, dir.x), _r(M).randf_range(-0.12, 0.12))
		if t > 0.0:
			t -= delta
			if t <= 0.0:
				levier.rotation.x = 0.5
		M.ctx["arc_t"] = t
	M.ctx["tick170"] = tick
	var lignes: Array = ["La foudre, c'est juste de l'électricité pressée.", "Ne touche pas la bobine. Ni l'autre. Ni le levier. Enfin, le levier, si tu veux.", "Un jour, toute la ville s'éclairera avec ça. Ou explosera. On verra."]
	_marchand(M, 0.8, -hd + 1.1, 0.0, "bricoler", "femme", "Docteure Volta", lignes, {"bonjour": "Laboratoire Volta ! Attention aux étincelles.", "infos": ["Les deux bobines discutent entre elles. Quand elles s'énervent, ça fait des éclairs. C'est magnifique."]})
	M.ctx["cloche170"] = false
	M.ctx["bonjour170"] = ["Entre ! Mais touche le moins de choses possible.", "Bienvenue au labo ! Tes cheveux vont friser."]
	M.ctx["entree"] = "Le laboratoire Volta : deux grandes bobines de cuivre, le tableau des manettes et des cadrans, et l'air qui sent l'orage."


# =================================================================== l'observatoire (Céleste Lunette, Cliquetis)

static func _observatoire(M) -> void:
	var R = M.R
	var k = R.kit
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	# le ciel peint au plafond : des étoiles
	var etoile: String = _c(R, "etoile170", Color(1.0, 0.95, 0.8), 0.4, 0.0, 3.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 170
	for s in range(70):
		var sx: float = rng.randf_range(-hw + 0.2, hw - 0.2)
		var sz: float = rng.randf_range(-hd + 0.2, hd - 0.2)
		var r: float = rng.randf_range(0.015, 0.045)
		k.cyl(R.L(sx, R.H - 0.005, sz), r, r, 0.004, etoile, 6)
	# la grande lunette sur sa monture, qui vise le ciel
	var lx: float = 0.0
	var lz: float = -0.4
	k.cyl(R.L(lx, 0, lz), 0.6, 0.7, 0.4, "fer", 18)
	k.cyl(R.L(lx, 0.4, lz), 0.18, 0.22, 1.2, "fer", 12)
	k.box(R.L(lx, 1.7, lz), Vector3(0.5, 0.3, 0.3), "fer", 1.0)
	var tube: Transform3D = R.L(lx, 1.85, lz) * Transform3D(Basis(Vector3.RIGHT, -0.75), Vector3.ZERO)
	k.cyl(tube * T3(0, -1.2, 0), 0.22, 0.28, 3.4, "or", 20)
	k.ring(tube * T3(0, 2.15, 0), 0.27, 0.31, 0.12, "cuivre", 20)
	k.cyl(tube * T3(0, -1.35, 0), 0.06, 0.06, 0.18, "fer", 10)
	k.col_box(R.L(lx, 0.8, lz), Vector3(1.4, 1.6, 1.4))
	R.reserve(lx, lz, 1.6, 1.6)
	k.box(R.L(0, R.H - 0.01, -hd * 0.5), Vector3(0.9, 0.02, hd), _c(R, "fente_ciel", Color(0.05, 0.07, 0.18), 0.9, 0.0, 0.4), 1.0)
	var regarder := func() -> void:
		var h: float = float(M.ctx.get("hour", 12.0))
		var nuit: bool = h >= 20.0 or h < 6.0
		M.main.sfx("etoile_filante")
		M.say(str(_pick(M, ["Dans la lunette : la Lune, toute ronde, avec ses cratères comme des fossettes. Céleste murmure : « Elle te fait coucou. »", "Une étoile filante traverse l'oculaire ! Vite, un vœu !", "Tu vois une planète avec des anneaux, comme un chapeau de fête. « Saturne, dit Céleste. Ou un engrenage géant. On n'est jamais sûr. »"] if nuit else ["En plein jour, la lunette ne montre… que du bleu. Et un pigeon qui passe. Céleste rit : « Reviens ce soir ! »", "Le Soleil ? On ne le regarde JAMAIS dans la lunette ! Céleste a mis un capuchon. Sage précaution."])), 6.0)
	M.act(R.P(lx, 0, lz + 1.3), "E : regarder dans la lunette", regarder, 1.2)
	# les cartes du ciel, le planétaire qui tourne, le bureau plein de notes
	var cc: String = _img(R, "carte_ciel170", "beau170/carte_ciel.png")
	_cadre(R, cc, 0.0, 2.2, -hd + 0.03, 0.0, 2.4, 1.6, "or")
	_cadre(R, cc, -hw + 0.03, 2.2, 0.4, 90.0, 1.6, 1.1, "or")
	var px: float = hw - 1.3
	var pz: float = hd - 2.0
	R.table(px, pz, 0.0, 1.0, 1.0, 0.8)
	Sud._boule(M.room, R.mat(_c(R, "soleil170", Color(1.0, 0.75, 0.2), 0.4, 0.3, 1.5)), R.P(px, 1.05, pz), 0.09)
	for pl in range(4):
		var piv := Node3D.new()
		M.room.add_child(piv)
		piv.global_position = R.P(px, 1.0, pz)
		var bras := MeshInstance3D.new()
		var lr: float = 0.16 + pl * 0.09
		bras.mesh = _boitem(lr, 0.008, 0.008)
		bras.material_override = R.mat("or")
		bras.position = Vector3(lr * 0.5, 0.05, 0)
		piv.add_child(bras)
		var pm := MeshInstance3D.new()
		var ps := SphereMesh.new()
		ps.radius = 0.025 + 0.01 * float(pl % 2)
		ps.height = ps.radius * 2.0
		pm.mesh = ps
		pm.material_override = R.mat(_c(R, "planete_%d" % pl, [Color(0.7, 0.6, 0.5), Color(0.9, 0.7, 0.4), Color(0.3, 0.5, 0.9), Color(0.85, 0.35, 0.25)][pl], 0.5))
		pm.position = Vector3(lr, 0.05, 0)
		piv.add_child(pm)
		piv.rotation.y = pl * 1.7
		(M.ctx["anims170"] as Array).append([piv, "tourne", Vector3.UP, 0.9 / (pl + 1)])
	k.cyl(R.L(px, 0.8, pz), 0.1, 0.12, 0.04, "or", 12)
	k.cyl(R.L(px, 0.84, pz), 0.012, 0.012, 0.2, "or", 6)
	R.table(-hw + 1.2, hd - 2.0, 90.0, 1.4, 0.8)
	for n in range(5):
		k.box(R.L(-hw + 1.1, 0.775 + n * 0.004, hd - 2.4 + n * 0.15, R.rng.randf_range(-20, 20)), Vector3(0.22, 0.004, 0.3), "papier", 1.0)
	k.cyl(R.L(-hw + 1.3, 0.77, hd - 1.6), 0.045, 0.04, 0.12, "noir", 8)
	R.chaise(-hw + 1.85, hd - 2.0, -90.0)
	_lampe(M, -hw + 1.2, 1.2, hd - 2.0, Color(1.0, 0.8, 0.55), 0.6, 3.0)
	_lampe(M, 0.0, R.H - 1.5, 0.0, Color(0.7, 0.78, 1.0), 1.0, 10.0)
	_rayons(M, hw - 0.22, -hd + 1.6, -90.0, 1.3, 2.4, 6, "livres")
	k.cyl(R.L(-hw + 1.0, 0, -hd + 1.2), 0.22, 0.26, 0.05, "bois_sombre", 14)
	k.cyl(R.L(-hw + 1.0, 0.05, -hd + 1.2), 0.035, 0.03, 0.8, "or", 8)
	k.ring(R.L(-hw + 1.0, 1.15, -hd + 1.2) * Transform3D(Basis(Vector3.BACK, 0.4) * Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 0.31, 0.33, 0.02, "or", 24)
	var gm := StandardMaterial3D.new()
	if ResourceLoader.exists("res://assets/textures/beau170/carte_ciel.png"):
		gm.albedo_texture = load("res://assets/textures/beau170/carte_ciel.png")
	gm.roughness = 0.4
	var globe: MeshInstance3D = Sud._boule(M.room, gm, R.P(-hw + 1.0, 1.15, -hd + 1.2), 0.29)
	(M.ctx["anims170"] as Array).append([globe, "tourne", Vector3.UP, 0.12])
	k.col_box(R.L(-hw + 1.0, 0.7, -hd + 1.2), Vector3(0.7, 1.4, 0.7))
	R.reserve(-hw + 1.0, -hd + 1.2, 0.8, 0.8)
	var lignes: Array = ["Chaque étoile a un nom. Moi, je les appelle toutes « ma belle ».", "Cette nuit, il y aura des étoiles filantes. Prépare tes vœux.", "Le ciel ne ment jamais. Les nuages, eux, cachent tout."]
	_marchand(M, lx - 0.9, lz + 0.5, 30.0, "observer", "femme", "Céleste", lignes, {"bonjour": "Bienvenue à l'observatoire ! Le ciel est à tout le monde.", "achete": {"eclat_lune": 10, "fragment_meteorite": 6}, "infos": ["La lunette a été polie par cent ingénieurs, pendant cent jours. Le cent unième jour, quelqu'un a éternué dessus."]})
	M.ctx["cloche170"] = false
	M.ctx["bonjour170"] = ["Bonsoir… ou bonjour ? Ici, on perd la notion du temps.", "Bienvenue sous les étoiles !"]
	M.ctx["entree"] = "L'observatoire : la grande lunette dorée qui vise le ciel, un plafond plein d'étoiles, les cartes du ciel, le petit planétaire qui tourne."
