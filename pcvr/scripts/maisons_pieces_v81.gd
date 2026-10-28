extends RefCounted
## V81 : les pièces des maisons qu'on visite (une seule construite à la fois, loin sous la mer,
## voir maisons_v81.gd). Ce fichier bâtit la pièce : sol, murs, plafond et poutres, fenêtres qui
## montrent le jour ou la nuit, la porte d'entrée, et tout le mobilier (tables, lits, armoires,
## bibliothèques, cheminée, cuisine…), dans les matériaux de la ville d'où l'on vient.
## Repère de la pièce : origine au milieu du sol, la porte d'entrée dans le mur +Z (z = D/2),
## le mur du fond en z = -D/2 ; x de -W/2 (gauche quand on entre… à droite pour qui regarde la
## porte) à +W/2. La géométrie est regroupée par matériau (une boîte à outils azur_kit_v56).

const Kit = preload("res://scripts/azur_kit_v56.gd")
const TX := "res://assets/textures/"

## Les ambiances des villes : sol, murs, plafond, poutres, bois des meubles, tapis, tableaux.
## [texture, teinte, taille d'un motif en m]
const STYLES := {
	"montjoie": {"sol": ["montjoie/bois_planches.png", Color(0.95, 0.88, 0.8), 2.0], "mur": ["montjoie/enduit.png", Color(0.98, 0.94, 0.84), 2.5],
		"bas": ["montjoie/moellons.png", Color(0.9, 0.88, 0.84), 1.6], "plafond": ["montjoie/bois_planches.png", Color(0.7, 0.6, 0.5), 2.0],
		"poutre": Color(0.36, 0.25, 0.16), "bois": Color(0.62, 0.45, 0.3), "colombage": true, "h": 2.9,
		"tapis": ["tazira/tapis_2.png", "tazira/tapis_3.png"], "tableaux": ["montjoie/tableau_liege.png", "montjoie/vitrail_aube.png", "azur/tableau_2.png"],
		"fenetre": "plomb", "foyer": "cheminee"},
	"braise": {"sol": ["braise/dalles_palais.png", Color(0.9, 0.86, 0.86), 2.4], "mur": ["braise/enduit_rouge.png", Color(0.95, 0.8, 0.78), 2.5],
		"bas": ["braise/pierre_gothique.png", Color(0.7, 0.68, 0.7), 2.0], "plafond": ["braise/pierre_gothique.png", Color(0.45, 0.42, 0.45), 2.4],
		"poutre": Color(0.12, 0.1, 0.1), "bois": Color(0.3, 0.18, 0.16), "h": 3.4,
		"tapis": ["tazira/tapis_1.png"], "tableaux": ["braise/fresque_cerbere.png", "braise/fresque_charon.png", "braise/affiche_fete.png", "braise/plan_ville.png"],
		"fenetre": "gothique", "foyer": "cheminee"},
	"boucan": {"sol": ["boucan/carrelage_bureau.png", Color(0.95, 0.95, 0.95), 1.6], "mur": ["boucan/brique_peinte.png", Color(1, 1, 1), 2.5],
		"bas": ["boucan/beton.png", Color(0.85, 0.85, 0.85), 2.0], "plafond": ["boucan/beton.png", Color(0.8, 0.8, 0.8), 3.0],
		"poutre": Color(0.25, 0.25, 0.27), "bois": Color(0.68, 0.55, 0.38), "h": 2.9, "poutres_metal": true,
		"tapis": ["tazira/tapis_3.png"], "tableaux": ["boucan/affiche_concert_1.png", "boucan/affiche_concert_2.png", "boucan/affiche_concert_3.png", "boucan/affiche_concert_4.png", "boucan/fanzine_couverture.png", "boucan/fresque_3.png"],
		"fenetre": "atelier", "foyer": "poele"},
	"boucan_entrepot": {"sol": ["boucan/beton_usine.png", Color(0.9, 0.9, 0.9), 3.0], "mur": ["boucan/brique.png", Color(0.95, 0.9, 0.88), 2.5],
		"bas": ["boucan/beton.png", Color(0.8, 0.8, 0.8), 2.0], "plafond": ["boucan/tole_rouille.png", Color(0.8, 0.8, 0.8), 3.0],
		"poutre": Color(0.3, 0.2, 0.15), "bois": Color(0.68, 0.55, 0.38), "h": 4.2, "poutres_metal": true,
		"tapis": ["tazira/tapis_3.png"], "tableaux": ["boucan/graffiti_3.png", "boucan/graffiti_7.png", "boucan/affiche_concert_2.png", "boucan/fresque_5.png"],
		"fenetre": "atelier", "foyer": "poele"},
	"boucan_conteneur": {"sol": ["boucan/moquette_bureau.png", Color(0.9, 0.9, 0.95), 1.6], "mur": ["boucan/panneau_lisse.png", Color(0.95, 0.95, 0.95), 2.0],
		"bas": ["boucan/tole_peinte.png", Color(0.85, 0.85, 0.85), 1.5], "plafond": ["boucan/tole_peinte.png", Color(0.75, 0.75, 0.75), 2.0],
		"poutre": Color(0.3, 0.3, 0.32), "bois": Color(0.7, 0.58, 0.4), "h": 2.4, "poutres_metal": true,
		"tapis": ["tazira/tapis_3.png"], "tableaux": ["boucan/affiche_concert_3.png", "boucan/affiche_concert_4.png", "boucan/fanzine_couverture.png"],
		"fenetre": "atelier", "foyer": "poele"},
	"tazira": {"sol": ["tazira/zellige.png", Color(1, 1, 1), 1.2], "mur": ["tazira/chaux.png", Color(1, 0.98, 0.94), 2.5],
		"bas": ["tazira/zellige.png", Color(0.9, 0.95, 1.0), 0.9], "plafond": ["tazira/canisse.png", Color(0.85, 0.75, 0.6), 1.5],
		"poutre": Color(0.42, 0.28, 0.16), "bois": Color(0.6, 0.38, 0.22), "h": 3.0,
		"tapis": ["tazira/tapis_1.png", "tazira/tapis_2.png", "tazira/tapis_3.png"], "tableaux": ["tazira/tapis_2.png", "azur/tableau_3.png"],
		"fenetre": "moucharabieh", "foyer": "brasero"},
	"azur": {"sol": ["azur/dalles.png", Color(1.0, 0.88, 0.78), 1.2], "mur": ["azur/enduit.png", Color(0.98, 0.93, 0.85), 2.5],
		"bas": ["azur/calcaire.png", Color(0.95, 0.92, 0.86), 2.0], "plafond": ["azur/enduit.png", Color(0.96, 0.95, 0.92), 3.0],
		"poutre": Color(0.45, 0.32, 0.22), "bois": Color(0.7, 0.52, 0.36), "h": 3.0,
		"tapis": ["tazira/tapis_2.png", "tazira/tapis_3.png"], "tableaux": ["azur/tableau_1.png", "azur/tableau_2.png", "azur/tableau_3.png", "azur/affiche_ferry.png"],
		"fenetre": "volets", "foyer": "cuisiniere"},
	"cliquetis": {"sol": ["azur/planches.png", Color(0.75, 0.6, 0.45), 2.0], "mur": ["cliquetis/brique.png", Color(1, 0.95, 0.9), 2.5],
		"bas": ["cliquetis/cuivre.png", Color(0.9, 0.8, 0.7), 1.5], "plafond": ["azur/planches.png", Color(0.5, 0.42, 0.34), 2.0],
		"poutre": Color(0.2, 0.18, 0.17), "bois": Color(0.55, 0.38, 0.24), "h": 3.1, "poutres_metal": true, "tuyaux": true,
		"tapis": ["tazira/tapis_1.png"], "tableaux": ["cliquetis/affiche_dirigeable.png", "cliquetis/affiche_foire.png", "cliquetis/affiche_telepherique.png", "cliquetis/cadran.png"],
		"fenetre": "hublot", "foyer": "poele"},
	"ramure": {"sol": ["ramure/planches.png", Color(0.95, 0.88, 0.75), 1.8], "mur": ["ramure/rondins.png", Color(1, 0.95, 0.88), 2.0],
		"bas": ["ramure/rondins.png", Color(0.85, 0.8, 0.72), 2.0], "plafond": ["ramure/chaume.png", Color(0.85, 0.78, 0.6), 2.0],
		"poutre": Color(0.4, 0.28, 0.18), "bois": Color(0.66, 0.5, 0.34), "h": 2.6, "rond": true,
		"tapis": ["tazira/tapis_2.png"], "tableaux": ["ramure/banniere_lune.png", "ramure/records.png", "ramure/papier.png"],
		"fenetre": "rond", "foyer": "irori"},
	"arcanelle": {"sol": ["arcanelle/dalles_arc.png", Color(0.95, 0.95, 1.0), 2.0], "mur": ["arcanelle/colombage.png", Color(1, 0.97, 0.92), 2.5],
		"bas": ["arcanelle/pierre_arc.png", Color(0.9, 0.9, 0.95), 1.8], "plafond": ["azur/planches.png", Color(0.45, 0.38, 0.4), 2.0],
		"poutre": Color(0.25, 0.18, 0.15), "bois": Color(0.45, 0.3, 0.22), "colombage": true, "h": 2.8,
		"tapis": ["tazira/tapis_2.png", "tazira/tapis_1.png"], "tableaux": ["arcanelle/carte_ciel.png", "arcanelle/runes.png", "arcanelle/banniere.png", "arcanelle/vitrail.png"],
		"fenetre": "plomb", "foyer": "cheminee"},
	"pirate": {"sol": ["pirates/planchesp.png", Color(0.95, 0.88, 0.8), 2.0], "mur": ["pirates/planchesp.png", Color(0.85, 0.75, 0.65), 2.0],
		"bas": ["pirates/rondins.png", Color(0.8, 0.7, 0.6), 2.0], "plafond": ["pirates/palmes.png", Color(0.8, 0.75, 0.6), 2.0],
		"poutre": Color(0.32, 0.22, 0.14), "bois": Color(0.5, 0.35, 0.22), "h": 2.6,
		"tapis": ["tazira/tapis_1.png"], "tableaux": ["pirates/carte_tresor.png", "pirates/avis_lestrange.png", "pirates/avis_malaterre.png", "pirates/pavillon_morue.png"],
		"fenetre": "volets_bois", "foyer": "brasero"},
	"carene": {"sol": ["carene/pont.png", Color(0.95, 0.92, 0.85), 2.0], "mur": ["carene/bordage_int.png", Color(1, 0.95, 0.9), 2.0],
		"bas": ["carene/bordage_int.png", Color(0.7, 0.65, 0.6), 2.0], "plafond": ["carene/bordage_int.png", Color(0.6, 0.55, 0.5), 2.0],
		"poutre": Color(0.28, 0.2, 0.14), "bois": Color(0.52, 0.38, 0.26), "h": 2.5,
		"tapis": ["tazira/tapis_3.png"], "tableaux": ["carene/voile.png", "pirates/carte_tresor.png", "azur/tableau_3.png"],
		"fenetre": "hublot", "foyer": "poele"},
	"egypte": {"sol": ["soleils/dalles_soleil.png", Color(1, 0.95, 0.88), 2.0], "mur": ["soleils/enduit.png", Color(1.0, 0.92, 0.78), 2.5],
		"bas": ["soleils/hieroglyphes.png", Color(1, 1, 1), 1.2], "plafond": ["soleils/limon.png", Color(0.8, 0.7, 0.55), 2.0],
		"poutre": Color(0.5, 0.36, 0.2), "bois": Color(0.6, 0.42, 0.24), "h": 3.0,
		"tapis": ["tazira/tapis_3.png"], "tableaux": ["soleils/fresque_nil.png", "soleils/fresque_barque.png", "soleils/papyrus_thot.png", "soleils/fresque_pesee.png"],
		"fenetre": "fente", "foyer": "four"},
	"maya": {"sol": ["soleils/pierre_maya.png", Color(0.95, 0.95, 0.9), 2.0], "mur": ["soleils/enduit.png", Color(0.98, 0.95, 0.88), 2.5],
		"bas": ["soleils/glyphes_maya.png", Color(1, 1, 1), 1.2], "plafond": ["pirates/palmes.png", Color(0.75, 0.7, 0.5), 2.0],
		"poutre": Color(0.36, 0.26, 0.15), "bois": Color(0.55, 0.38, 0.22), "h": 2.6,
		"tapis": ["tazira/tapis_1.png"], "tableaux": ["soleils/fresque_kukulkan.png", "soleils/codex_soleils.png", "soleils/fresque_jumeaux.png"],
		"fenetre": "fente", "foyer": "foyer_pierres"},
	"azteque": {"sol": ["soleils/tezontle.png", Color(0.95, 0.9, 0.88), 2.0], "mur": ["soleils/stuc_rouge.png", Color(1, 0.95, 0.92), 2.5],
		"bas": ["soleils/frise_azteque.png", Color(1, 1, 1), 1.2], "plafond": ["soleils/limon.png", Color(0.75, 0.65, 0.55), 2.0],
		"poutre": Color(0.36, 0.24, 0.14), "bois": Color(0.55, 0.36, 0.22), "h": 2.8,
		"tapis": ["tazira/tapis_3.png"], "tableaux": ["soleils/fresque_huitzilopochtli.png", "soleils/fresque_tlaloc.png", "soleils/pierre_soleil.png"],
		"fenetre": "fente", "foyer": "foyer_pierres"},
	"elfe": {"sol": ["azur/planches.png", Color(0.95, 0.85, 0.65), 2.0], "mur": ["temple/temple_wall.png", Color(1.0, 0.97, 0.9), 2.5],
		"bas": ["ramure/rondins.png", Color(0.9, 0.8, 0.62), 2.0], "plafond": ["fees/cernes.png", Color(0.9, 0.82, 0.62), 3.0],
		"poutre": Color(0.55, 0.4, 0.22), "bois": Color(0.78, 0.62, 0.4), "h": 3.0, "rond": true,
		"tapis": ["tazira/tapis_2.png"], "tableaux": ["elfes/elfe_lyra.png", "elfes/elfe_azur.png", "arcanelle/carte_ciel.png"],
		"fenetre": "rond", "foyer": "cristal"},
	"fee": {"sol": ["fees/cernes.png", Color(1.0, 0.92, 0.8), 2.0], "mur": ["fees/ecorce_ygg.png", Color(1.0, 0.95, 0.9), 2.0],
		"bas": ["fees/ecorce_ygg.png", Color(0.8, 0.72, 0.65), 2.0], "plafond": ["fees/fleurs_arbre.png", Color(1.0, 0.9, 0.95), 2.0],
		"poutre": Color(0.45, 0.32, 0.22), "bois": Color(0.7, 0.52, 0.36), "h": 3.0, "rond": true,
		"tapis": ["tazira/tapis_2.png"], "tableaux": ["fees/runes_porte.png", "fees/fleurs_arbre.png"],
		"fenetre": "rond", "foyer": "cristal"},
	"atlante": {"sol": ["atlantide/mosaique.png", Color(1, 1, 1), 2.0], "mur": ["atlantide/marbre.png", Color(0.96, 0.98, 1.0), 2.5],
		"bas": ["atlantide/frise.png", Color(1, 1, 1), 1.2], "plafond": ["atlantide/cuivre_vert.png", Color(0.8, 0.9, 0.9), 2.5],
		"poutre": Color(0.75, 0.62, 0.35), "bois": Color(0.75, 0.68, 0.55), "h": 3.2, "rond": true, "poutres_metal": true,
		"tapis": ["tazira/tapis_2.png"], "tableaux": ["atlantide/fresque.png", "temple/fresque.png", "temple/glyph_vague.png"],
		"fenetre": "hublot", "foyer": "cristal"},
	"cave": {"sol": ["montjoie/dalles_donjon.png", Color(0.85, 0.82, 0.78), 2.0], "mur": ["montjoie/pierre_donjon.png", Color(0.85, 0.82, 0.78), 2.5],
		"bas": ["montjoie/moellons.png", Color(0.7, 0.68, 0.64), 1.6], "plafond": ["montjoie/bois_planches.png", Color(0.45, 0.38, 0.32), 2.0],
		"poutre": Color(0.28, 0.2, 0.14), "bois": Color(0.5, 0.36, 0.24), "h": 2.6,
		"tapis": ["tazira/tapis_2.png"], "tableaux": ["pirates/carte_tresor.png"], "fenetre": "aucune", "foyer": "brasero"},
	"astralys": {"sol": ["astralys/cristal_sol.png", Color(1, 1, 1), 2.0], "mur": ["astralys/nacre_mur.png", Color(1, 1, 1), 3.0],
		"bas": ["astralys/metal_lumen.png", Color(0.9, 0.92, 1.0), 2.0], "plafond": ["astralys/nacre_mur.png", Color(0.85, 0.88, 0.95), 3.0],
		"poutre": Color(0.8, 0.82, 0.9), "bois": Color(0.85, 0.88, 0.95), "h": 3.0, "rond": true, "poutres_metal": true,
		"tapis": ["tazira/tapis_2.png"], "tableaux": ["astralys/holo_1.png", "astralys/holo_2.png", "astralys/holo_3.png", "astralys/holo_4.png", "astralys/fresque_lumen_1.png"],
		"fenetre": "hublot", "foyer": "cristal"},
}

var kit
var root: Node3D
var main: Node
var xf0: Transform3D
var origin: Vector3
var W: float = 7.0
var D: float = 6.0
var H: float = 2.9
var style: String = "montjoie"
var pal: Dictionary = {}
var rng := RandomNumberGenerator.new()
var hour: float = 12.0
var pc: bool = true
var day: bool = true
var door_x: float = 0.0
var lights: Array = []                    # OmniLight3D de la pièce
var flames: Array = []                    # [OmniLight3D, énergie] qui vacillent
var occupied: Array = []                  # [Rect2] déjà meublés (repère de la pièce)
var _mats: Dictionary = {}
static var _cobweb: Texture2D
static var _dot: Texture2D


func setup(parent: Node3D, main_node: Node, at: Vector3, w: float, d: float, style_name: String, seed_v: int, hour_now: float) -> void:
	main = main_node
	root = parent
	origin = at
	xf0 = Transform3D(Basis(), at)
	style = style_name if STYLES.has(style_name) else "montjoie"
	pal = STYLES[style]
	W = w
	D = d
	H = float(pal.get("h", 2.9))
	rng.seed = seed_v
	hour = hour_now
	day = hour >= 7.0 and hour < 19.5
	pc = OS.has_feature("ile_manga_pc")
	kit = Kit.new()
	kit.setup(root, null)
	kit.rng.seed = seed_v
	_materials()


# =================================================================== repères

func L(x: float, y: float, z: float, yaw_deg: float = 0.0) -> Transform3D:
	return xf0 * Transform3D(Basis(Vector3.UP, deg_to_rad(yaw_deg)), Vector3(x, y, z))


func P(x: float, y: float, z: float) -> Vector3:
	return xf0 * Vector3(x, y, z)


## Une place libre (repère de la pièce) pour un meuble de taille (sx, sz) ; marque la place.
func reserve(x: float, z: float, sx: float, sz: float) -> void:
	occupied.append(Rect2(x - sx * 0.5, z - sz * 0.5, sx, sz))


func is_free(x: float, z: float, sx: float, sz: float) -> bool:
	var r := Rect2(x - sx * 0.5, z - sz * 0.5, sx, sz)
	for o in occupied:
		if (o as Rect2).intersects(r):
			return false
	return true


# =================================================================== matériaux

func _tex(path: String) -> Texture2D:
	var p: String = TX + path
	return load(p) if ResourceLoader.exists(p) else null


func _texmat(path: String, tint: Color, rough: float = 0.85) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = _tex(path)
	m.albedo_color = tint
	m.roughness = rough
	var n: String = path.trim_suffix(".png") + "_n.png"
	if ResourceLoader.exists(TX + n):
		m.normal_enabled = true
		m.normal_texture = _tex(n)
		m.normal_scale = 0.8
	return m


func _col(c: Color, rough: float = 0.8, metal: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	return m


func _put(key: String, m: Material) -> void:
	_mats[key] = m
	kit.mats[key] = m


func _materials() -> void:
	var s: Array = pal["sol"]
	_put("sol", _texmat(str(s[0]), s[1], 0.75))
	var mu: Array = pal["mur"]
	_put("mur", _texmat(str(mu[0]), mu[1], 0.92))
	var b: Array = pal["bas"]
	_put("bas", _texmat(str(b[0]), b[1], 0.9))
	var pl: Array = pal["plafond"]
	_put("plafond", _texmat(str(pl[0]), pl[1], 0.95))
	var wood: Color = pal["bois"]
	var wt: Texture2D = load("res://assets/textures/doors/wood_plain.png")
	for k in [["bois", wood], ["bois_clair", wood.lightened(0.3)], ["bois_sombre", wood.darkened(0.45)], ["poutre", pal["poutre"]]]:
		var m := StandardMaterial3D.new()
		m.albedo_texture = wt
		m.albedo_color = k[1]
		m.roughness = 0.72
		if bool(pal.get("poutres_metal", false)) and str(k[0]) == "poutre":
			m.albedo_texture = null
			m.metallic = 0.6
			m.roughness = 0.45
		_put(str(k[0]), m)
	# des tissus de toutes les couleurs (literie, rideaux, coussins, nappes, vêtements suspendus)
	var tissus := {"rouge": Color(0.7, 0.16, 0.14), "bleu": Color(0.2, 0.32, 0.62), "vert": Color(0.25, 0.5, 0.3), "jaune": Color(0.92, 0.75, 0.25),
		"blanc": Color(0.95, 0.94, 0.9), "creme": Color(0.94, 0.88, 0.74), "violet": Color(0.45, 0.25, 0.55), "rose": Color(0.92, 0.6, 0.66),
		"brun": Color(0.45, 0.3, 0.2), "gris": Color(0.5, 0.5, 0.52), "orange": Color(0.92, 0.5, 0.18), "turquoise": Color(0.2, 0.62, 0.62), "noir": Color(0.08, 0.08, 0.09)}
	for c in tissus:
		_put("tissu_" + c, _col(tissus[c], 0.95))
	var drap := _col(Color(0.92, 0.91, 0.87), 1.0)
	_put("drap", drap)
	_put("metal", _col(Color(0.35, 0.36, 0.38), 0.4, 0.8))
	_put("fer", _col(Color(0.08, 0.08, 0.09), 0.55, 0.6))
	_put("cuivre", _col(Color(0.78, 0.45, 0.25), 0.35, 0.9))
	_put("or", _col(Color(0.95, 0.75, 0.3), 0.3, 1.0))
	_put("argent", _col(Color(0.85, 0.86, 0.88), 0.25, 1.0))
	_put("pierre", _texmat("montjoie/moellons.png", Color(0.8, 0.78, 0.74), 0.9))
	_put("pierre_lisse", _texmat("azur/calcaire.png", Color(0.9, 0.88, 0.84), 0.85))
	_put("brique", _texmat("cliquetis/brique.png", Color(0.9, 0.8, 0.75), 0.9))
	_put("ceramique", _col(Color(0.96, 0.95, 0.92), 0.2))
	_put("terre_cuite", _col(Color(0.72, 0.4, 0.26), 0.85))
	_put("cuir", _col(Color(0.42, 0.24, 0.14), 0.6))
	_put("papier", _col(Color(0.95, 0.92, 0.82), 0.95))
	_put("livres", _texmat("arcanelle/livres.png", Color(1, 1, 1), 0.8))
	_put("feuillage", _col(Color(0.22, 0.48, 0.2), 0.8))
	_put("terreau", _col(Color(0.22, 0.15, 0.1), 1.0))
	_put("fromage", _col(Color(0.98, 0.82, 0.38), 0.6))
	_put("pain", _col(Color(0.8, 0.55, 0.28), 0.8))
	_put("pomme", _col(Color(0.75, 0.12, 0.1), 0.4))
	_put("gateau", _col(Color(0.98, 0.9, 0.92), 0.6))
	_put("chocolat", _col(Color(0.3, 0.16, 0.1), 0.5))
	_put("soupe", _col(Color(0.85, 0.55, 0.2), 0.2))
	_put("confiture", _col(Color(0.6, 0.08, 0.15), 0.15))
	_put("carton", _col(Color(0.68, 0.52, 0.34), 0.95))
	_put("noir", _col(Color(0.03, 0.03, 0.035), 0.9))
	var v := StandardMaterial3D.new()
	v.albedo_color = Color(0.7, 0.85, 0.95, 0.25)
	v.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	v.roughness = 0.05
	v.metallic_specular = 0.9
	_put("verre", v)
	# les vitres : elles montrent le jour (ou la nuit) dehors
	var f := StandardMaterial3D.new()
	f.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	f.albedo_color = _window_color()
	_put("vitre", f)
	var fl := StandardMaterial3D.new()
	fl.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fl.albedo_color = Color(1.0, 0.75, 0.35)
	fl.emission_enabled = true
	_put("flamme", fl)
	var lu := StandardMaterial3D.new()
	lu.albedo_color = Color(1.0, 0.93, 0.75)
	lu.emission_enabled = true
	lu.emission = Color(1.0, 0.85, 0.55)
	lu.emission_energy_multiplier = 2.0
	_put("lumiere", lu)
	var cr := StandardMaterial3D.new()
	cr.albedo_color = Color(0.6, 0.85, 1.0, 0.8)
	cr.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cr.emission_enabled = true
	cr.emission = Color(0.45, 0.75, 1.0)
	cr.emission_energy_multiplier = 1.6
	_put("cristal", cr)
	var web := StandardMaterial3D.new()
	web.albedo_texture = cobweb_texture()
	web.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	web.cull_mode = BaseMaterial3D.CULL_DISABLED
	web.albedo_color = Color(1, 1, 1, 0.75)
	web.roughness = 1.0
	_put("toile", web)
	var dust := _col(Color(0.62, 0.6, 0.55), 1.0)
	_put("poussiere", dust)
	for i in range((pal["tapis"] as Array).size()):
		_put("tapis_%d" % i, _texmat(str(pal["tapis"][i]), Color(1, 1, 1), 1.0))
	for i in range((pal["tableaux"] as Array).size()):
		_put("tableau_%d" % i, _texmat(str(pal["tableaux"][i]), Color(1, 1, 1), 0.7))


func mat(key: String) -> Material:
	return _mats.get(key, null)


func _window_color() -> Color:
	if style == "atlante":
		return Color(0.12, 0.42, 0.55)          # la mer, derrière le hublot
	if style == "fee":
		return Color(0.55, 0.4, 0.75)           # la lueur de la caverne des fées
	if hour >= 7.5 and hour < 18.5:
		return Color(0.78, 0.88, 1.0)
	if hour >= 6.0 and hour < 7.5:
		return Color(1.0, 0.72, 0.5)
	if hour >= 18.5 and hour < 20.5:
		return Color(1.0, 0.55, 0.35)
	return Color(0.05, 0.07, 0.16)


## Une toile d'araignée dessinée une fois (rayons et spirale), fond transparent.
static func cobweb_texture() -> Texture2D:
	if _cobweb != null:
		return _cobweb
	var n: int = 256
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 0))
	var c := Vector2(0, 0)            # coin : la toile part du coin haut-gauche
	var rays: int = 9
	for k in range(rays):
		var a: float = (PI * 0.5) * float(k) / float(rays - 1)
		for t in range(0, n * 14 / 10):
			var p: Vector2 = c + Vector2(cos(a), sin(a)) * float(t)
			if p.x >= 0 and p.y >= 0 and p.x < n and p.y < n:
				img.set_pixel(int(p.x), int(p.y), Color(1, 1, 1, 0.85))
	var r: float = 14.0
	while r < float(n) * 1.35:
		for s in range(0, 400):
			var a2: float = (PI * 0.5) * float(s) / 399.0
			var sag: float = 1.0 - 0.08 * sin(a2 * float(rays - 1) * 2.0)
			var p2: Vector2 = c + Vector2(cos(a2), sin(a2)) * r * sag
			if p2.x >= 0 and p2.y >= 0 and p2.x < n and p2.y < n:
				img.set_pixel(int(p2.x), int(p2.y), Color(1, 1, 1, 0.7))
		r += 16.0 + r * 0.06
	_cobweb = ImageTexture.create_from_image(img)
	return _cobweb


# =================================================================== la pièce

## Sol, murs (la porte en +Z, à door_x), plafond, poutres, plinthes, fenêtres, porte d'entrée,
## lumière du plafond. Les collisions : sol, murs, plafond (la caméra s'y règle).
func shell(with_door: bool = true) -> void:
	var hw: float = W * 0.5
	var hd: float = D * 0.5
	var t: float = 0.25
	door_x = clampf(door_x, -hw + 1.0, hw - 1.0)
	# le sol (une dalle épaisse) et le plafond
	var ts: float = float((pal["sol"] as Array)[2])
	kit.box(L(0, -0.1, 0), Vector3(W, 0.2, D), "sol", ts, 4)
	kit.col_box(L(0, -0.25, 0), Vector3(W + 1.0, 0.5, D + 1.0))
	var tp: float = float((pal["plafond"] as Array)[2])
	kit.box(L(0, H + 0.1, 0), Vector3(W, 0.2, D), "plafond", tp, 8)
	kit.col_box(L(0, H + 0.35, 0), Vector3(W + 1.0, 0.5, D + 1.0))
	# les murs : un soubassement (bas) et l'enduit au-dessus
	var tm: float = float((pal["mur"] as Array)[2])
	var bh: float = 0.9 if style != "astralys" else 0.35
	# fond (-Z) et côtés
	_wall(L(0, 0, -hd, 0), W, bh, tm)
	_wall(L(-hw, 0, 0, 90), D, bh, tm)
	_wall(L(hw, 0, 0, -90), D, bh, tm)
	# devant (+Z) : de part et d'autre de la porte, et le linteau
	var dw: float = 1.1
	var dh: float = 2.2
	var left_w: float = (door_x - dw * 0.5) + hw
	var right_w: float = hw - (door_x + dw * 0.5)
	if left_w > 0.05:
		_wall(L(-hw + left_w * 0.5, 0, hd, 180), left_w, bh, tm)
	if right_w > 0.05:
		_wall(L(hw - right_w * 0.5, 0, hd, 180), right_w, bh, tm)
	kit.box(L(door_x, dh + (H - dh) * 0.5, hd - 0.01, 180), Vector3(dw, H - dh, 0.02), "mur", tm, 16)
	for c in [[0, -hd - t * 0.5, W + 2 * t, t], [0, hd + t * 0.5, W + 2 * t, t]]:
		kit.col_box(L(float(c[0]), H * 0.5, float(c[1])), Vector3(float(c[2]), H + 0.4, float(c[3])))
	for sx in [-1.0, 1.0]:
		kit.col_box(L(sx * (hw + t * 0.5), H * 0.5, 0), Vector3(t, H + 0.4, D + 2 * t))
	if not with_door:
		kit.box(L(door_x, dh * 0.5, hd - 0.01, 180), Vector3(dw, dh, 0.02), "mur", tm, 16)
	# la porte d'entrée (fermée derrière nous), son cadre, la poignée
	if with_door:
		_entry_door(dw, dh, hd)
	_after_door(hw, hd)


func _entry_door(dw: float, dh: float, hd: float) -> void:
	kit.box(L(door_x, dh * 0.5, hd - 0.05), Vector3(dw, dh, 0.06), "bois_sombre", 1.0)
	for sx2 in [-1.0, 1.0]:
		kit.box(L(door_x + sx2 * (dw * 0.5 + 0.06), dh * 0.5, hd - 0.04), Vector3(0.12, dh + 0.12, 0.1), "poutre", 1.0)
	kit.box(L(door_x, dh + 0.06, hd - 0.04), Vector3(dw + 0.24, 0.12, 0.1), "poutre", 1.0)
	for k in range(3):
		kit.box(L(door_x, 0.35 + k * 0.75, hd - 0.085), Vector3(dw - 0.1, 0.06, 0.02), "bois", 1.0)
	kit.cyl(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), P(door_x + dw * 0.35, 1.0, hd - 0.09)), 0.035, 0.035, 0.06, "or", 8)


func _after_door(hw: float, hd: float) -> void:
	# les poutres du plafond
	var nb: int = maxi(2, int(W / 1.6))
	for i in range(nb):
		var bx: float = -hw + W * (i + 0.5) / nb
		kit.box(L(bx, H - 0.12, 0), Vector3(0.18, 0.24, D), "poutre", 1.0)
	if bool(pal.get("colombage", false)):
		_colombage(hw, hd)
	if bool(pal.get("tuyaux", false)):
		for k2 in range(2):
			kit.cyl(Transform3D(Basis(Vector3.BACK, PI * 0.5), P(hw - 0.15, H - 0.45 - k2 * 0.25, -hd + 0.2 + k2 * 0.18)), 0.07, 0.07, W - 0.3, "cuivre", 10, false)
	# les fenêtres : une ou deux sur les côtés, une au fond si la pièce est large
	_windows(hw, hd)
	# la lumière de la pièce : une lampe au plafond (ou la lumière du jour)
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.86, 0.66) if not day else Color(1.0, 0.95, 0.88)
	l.light_energy = 1.25 if not day else 1.0
	l.omni_range = maxf(W, D) * 1.15
	l.omni_attenuation = 0.9
	l.shadow_enabled = pc and not main.xr_active
	l.light_specular = 0.3
	root.add_child(l)
	l.global_position = P(0, H - 0.95, 0)
	lights.append(l)
	ceiling_lamp(0, 0)
	if day and str(pal.get("fenetre", "")) != "aucune":
		# un peu de jour qui entre par les fenêtres, d'un côté
		var sl := OmniLight3D.new()
		sl.light_color = Color(0.85, 0.92, 1.0)
		sl.light_energy = 0.6
		sl.omni_range = maxf(W, D)
		sl.shadow_enabled = false
		root.add_child(sl)
		sl.global_position = P(-hw + 0.6, H * 0.6, 0)
		lights.append(sl)


## La lampe suspendue (le mobilier qu'on voit ; la lumière est posée à part).
func ceiling_lamp(x: float, z: float) -> void:
	var y: float = H - 0.55
	match style:
		"montjoie", "arcanelle", "braise", "cave":
			# une couronne de bois et ses bougies
			kit.cyl(L(x, y + 0.25, z), 0.006, 0.006, H - y - 0.25, "fer", 4, false)
			kit.ring(L(x, y, z), 0.42, 0.48, 0.06, "bois_sombre" if style != "braise" else "fer", 16)
			for k in range(6):
				var a: float = TAU * k / 6.0
				kit.cyl(L(x + cos(a) * 0.45, y + 0.06, z + sin(a) * 0.45), 0.02, 0.02, 0.1, "ceramique", 6)
				kit.cyl(L(x + cos(a) * 0.45, y + 0.16, z + sin(a) * 0.45), 0.008, 0.0, 0.03, "flamme", 5, false)
			for k2 in range(3):
				var a2: float = TAU * k2 / 3.0
				kit.box(Transform3D(Basis(Vector3.UP, -a2) * Basis(Vector3.BACK, 0.62), P(x + cos(a2) * 0.22, y + 0.17, z + sin(a2) * 0.22)), Vector3(0.012, 0.52, 0.012), "fer", 1.0)
		"boucan", "boucan_entrepot", "boucan_conteneur", "cliquetis":
			kit.cyl(L(x, y + 0.2, z), 0.008, 0.008, H - y - 0.2, "noir", 4, false)
			kit.cyl(L(x, y, z), 0.28, 0.06, 0.2, "metal", 14, false)
			kit.cyl(L(x, y - 0.04, z), 0.06, 0.06, 0.08, "lumiere", 8)
		"astralys":
			kit.cyl(L(x, y, z), 0.35, 0.35, 0.05, "lumiere", 20)
			kit.ring(L(x, y + 0.02, z), 0.35, 0.4, 0.06, "argent", 20)
		_:
			# une lanterne de papier / de tissu, ronde
			kit.cyl(L(x, y + 0.3, z), 0.006, 0.006, H - y - 0.3, "fer", 4, false)
			kit.cyl(L(x, y - 0.15, z), 0.18, 0.25, 0.22, "papier", 12)
			kit.cyl(L(x, y + 0.07, z), 0.25, 0.16, 0.22, "papier", 12)
			kit.cyl(L(x, y - 0.05, z), 0.05, 0.05, 0.08, "lumiere", 8)


func _wall(xf: Transform3D, len: float, bh: float, tm: float) -> void:
	# xf : le pied du mur, au milieu ; le mur regarde -Z local vers l'intérieur… on construit
	# des boîtes fines dont seule la face tournée vers l'intérieur est utile (faces 32 = -Z).
	kit.box(xf * Transform3D(Basis(), Vector3(0, bh * 0.5, 0.01)), Vector3(len, bh, 0.02), "bas", float((pal["bas"] as Array)[2]), 16)
	kit.box(xf * Transform3D(Basis(), Vector3(0, bh + (H - bh) * 0.5, 0.01)), Vector3(len, H - bh, 0.02), "mur", tm, 16)
	# plinthe et cimaise
	kit.box(xf * Transform3D(Basis(), Vector3(0, bh, 0.035)), Vector3(len, 0.06, 0.05), "bois_sombre", 1.0, 16 + 4 + 8)
	kit.box(xf * Transform3D(Basis(), Vector3(0, 0.06, 0.03)), Vector3(len, 0.12, 0.04), "bois_sombre", 1.0, 16 + 4)


func _colombage(hw: float, hd: float) -> void:
	# des pans de bois sur les murs (montants et une écharpe)
	for side in [[L(0, 0, -hd + 0.03, 0), W], [L(-hw + 0.03, 0, 0, 90), D], [L(hw - 0.03, 0, 0, -90), D]]:
		var xf: Transform3D = side[0]
		var len: float = float(side[1])
		var n: int = maxi(2, int(len / 1.8))
		for i in range(n + 1):
			var x: float = -len * 0.5 + len * float(i) / n
			kit.box(xf * Transform3D(Basis(), Vector3(x, (H + 0.9) * 0.5, 0.0)), Vector3(0.14, H - 0.9, 0.05), "poutre", 1.0, 16 + 1 + 2)
		kit.box(xf * Transform3D(Basis(), Vector3(0, 0.95, 0.0)), Vector3(len, 0.12, 0.05), "poutre", 1.0, 16 + 4 + 8)


func _windows(hw: float, hd: float) -> void:
	var kind: String = str(pal.get("fenetre", "plomb"))
	if kind == "aucune":
		return
	var wy: float = 1.55 if H > 2.7 else 1.4
	var spots: Array = []
	# côtés : au milieu de la profondeur (ou deux si c'est profond)
	var nz: int = 1 if D < 7.0 else 2
	for k in range(nz):
		var z: float = -hd + D * (k + 0.5) / nz
		spots.append([L(-hw + 0.02, wy, z, 90), "g"])
		spots.append([L(hw - 0.02, wy, z, -90), "d"])
	if W > 7.5:
		spots.append([L(-W * 0.25, wy, -hd + 0.02, 0), "f"])
	for s in spots:
		window(s[0], kind)


## Une fenêtre (xf : son centre, posée sur le mur, qui regarde l'intérieur = +Z local).
func window(xf: Transform3D, kind: String) -> void:
	var w: float = 0.9
	var h: float = 1.15
	match kind:
		"hublot", "rond":
			var r: float = 0.42
			var qx: Transform3D = xf * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0, 0.01))
			kit.cyl(qx, r, r, 0.005, "vitre", 20, true)
			kit.ring(qx, r, r + 0.08, 0.06, "cuivre" if kind == "hublot" else "bois_sombre", 20)
			return
		"fente":
			w = 0.35
			h = 0.9
		"gothique":
			w = 0.8
			h = 1.6
		"moucharabieh":
			w = 0.85
			h = 1.2
	kit.box(xf * Transform3D(Basis(), Vector3(0, 0, 0.005)), Vector3(w, h, 0.01), "vitre", 1.0, 16)
	# le cadre
	var fk: String = "bois_sombre" if kind != "atelier" else "fer"
	for sx in [-1.0, 1.0]:
		kit.box(xf * Transform3D(Basis(), Vector3(sx * (w * 0.5 + 0.04), 0, 0.03)), Vector3(0.08, h + 0.16, 0.06), fk, 1.0)
	for sy in [-1.0, 1.0]:
		kit.box(xf * Transform3D(Basis(), Vector3(0, sy * (h * 0.5 + 0.04), 0.03)), Vector3(w + 0.16, 0.08, 0.06), fk, 1.0)
	# l'appui
	kit.box(xf * Transform3D(Basis(), Vector3(0, -h * 0.5 - 0.1, 0.1)), Vector3(w + 0.3, 0.06, 0.2), "bois", 1.0)
	match kind:
		"plomb", "gothique":
			for i in range(1, 4):
				kit.box(xf * Transform3D(Basis(), Vector3(0, -h * 0.5 + h * i / 4.0, 0.012)), Vector3(w, 0.015, 0.01), "fer", 1.0, 16)
			kit.box(xf * Transform3D(Basis(), Vector3(0, 0, 0.012)), Vector3(0.015, h, 0.01), "fer", 1.0, 16)
		"moucharabieh":
			for i2 in range(1, 7):
				kit.box(xf * Transform3D(Basis(), Vector3(-w * 0.5 + w * i2 / 7.0, 0, 0.015)), Vector3(0.03, h, 0.02), "bois_sombre", 1.0, 16)
				kit.box(xf * Transform3D(Basis(), Vector3(0, -h * 0.5 + h * i2 / 7.0, 0.015)), Vector3(w, 0.03, 0.02), "bois_sombre", 1.0, 16)
		"atelier":
			for i3 in range(1, 3):
				kit.box(xf * Transform3D(Basis(), Vector3(-w * 0.5 + w * i3 / 3.0, 0, 0.012)), Vector3(0.025, h, 0.01), "fer", 1.0, 16)
			kit.box(xf * Transform3D(Basis(), Vector3(0, 0, 0.012)), Vector3(w, 0.025, 0.01), "fer", 1.0, 16)
		_:
			kit.box(xf * Transform3D(Basis(), Vector3(0, 0, 0.012)), Vector3(0.03, h, 0.01), "bois_sombre", 1.0, 16)
			kit.box(xf * Transform3D(Basis(), Vector3(0, 0, 0.012)), Vector3(w, 0.03, 0.01), "bois_sombre", 1.0, 16)
	# des rideaux de part et d'autre (souvent)
	if rng.randf() < 0.6 and kind != "fente":
		var tc: String = ["rouge", "bleu", "vert", "jaune", "creme", "rose", "violet"][rng.randi() % 7]
		for sx2 in [-1.0, 1.0]:
			kit.box(xf * Transform3D(Basis(), Vector3(sx2 * (w * 0.5 + 0.22), -0.1, 0.08)), Vector3(0.3, h + 0.6, 0.04), "tissu_" + tc, 1.0)
		kit.cyl(xf * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(w * 0.5 + 0.45, h * 0.5 + 0.22, 0.09)), 0.015, 0.015, w + 0.9, "fer", 6, false)


# =================================================================== les meubles
## Tous en repère de la pièce : (x, z) le centre au sol, yaw en degrés (0 : le meuble regarde +Z,
## vers la porte d'entrée).

func table(x: float, z: float, yaw: float, w: float = 1.4, d: float = 0.85, h: float = 0.76, nappe: String = "") -> void:
	var xf: Transform3D = L(x, 0, z, yaw)
	kit.box(xf * Transform3D(Basis(), Vector3(0, h - 0.03, 0)), Vector3(w, 0.06, d), "bois", 1.0)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			kit.box(xf * Transform3D(Basis(), Vector3(sx * (w * 0.5 - 0.07), (h - 0.06) * 0.5, sz * (d * 0.5 - 0.07))), Vector3(0.07, h - 0.06, 0.07), "bois_sombre", 1.0)
	if nappe != "":
		kit.box(xf * Transform3D(Basis(), Vector3(0, h + 0.005, 0)), Vector3(w * 0.8, 0.01, d + 0.1), "tissu_" + nappe, 1.0, 4 + 16 + 32)
	kit.col_box(xf * Transform3D(Basis(), Vector3(0, h * 0.5, 0)), Vector3(w, h, d))
	reserve(x, z, w + 0.2, d + 0.2)


func table_ronde(x: float, z: float, r: float = 0.6, h: float = 0.75) -> void:
	var xf: Transform3D = L(x, 0, z)
	kit.cyl(xf * Transform3D(Basis(), Vector3(0, h - 0.05, 0)), r, r, 0.05, "bois", 20)
	kit.cyl(xf * Transform3D(Basis(), Vector3(0, 0.0, 0)), 0.06, 0.06, h - 0.05, "bois_sombre", 8, false)
	kit.cyl(xf, 0.3, 0.25, 0.05, "bois_sombre", 12)
	kit.col_box(xf * Transform3D(Basis(), Vector3(0, h * 0.5, 0)), Vector3(r * 1.5, h, r * 1.5))
	reserve(x, z, r * 2.0, r * 2.0)


func chaise(x: float, z: float, yaw: float, coussin: String = "") -> void:
	var xf: Transform3D = L(x, 0, z, yaw)
	kit.box(xf * Transform3D(Basis(), Vector3(0, 0.45, 0)), Vector3(0.44, 0.05, 0.42), "bois", 1.0)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			kit.box(xf * Transform3D(Basis(), Vector3(sx * 0.18, 0.22, sz * 0.17)), Vector3(0.04, 0.45, 0.04), "bois_sombre", 1.0)
	kit.box(xf * Transform3D(Basis(), Vector3(0, 0.75, -0.19)), Vector3(0.44, 0.55, 0.04), "bois", 1.0)
	if coussin != "":
		kit.box(xf * Transform3D(Basis(), Vector3(0, 0.49, 0)), Vector3(0.38, 0.05, 0.36), "tissu_" + coussin, 1.0)


func tabouret(x: float, z: float) -> void:
	var xf: Transform3D = L(x, 0, z, rng.randf_range(0, 90))
	kit.cyl(xf * Transform3D(Basis(), Vector3(0, 0.42, 0)), 0.18, 0.18, 0.04, "bois", 12)
	for k in range(3):
		var a: float = TAU * k / 3.0
		kit.box(xf * Transform3D(Basis(Vector3(cos(a + PI * 0.5), 0, sin(a + PI * 0.5)), 0.12), Vector3(cos(a) * 0.12, 0.21, sin(a) * 0.12)), Vector3(0.035, 0.44, 0.035), "bois_sombre", 1.0)


func banc(x: float, z: float, yaw: float, w: float = 1.4) -> void:
	var xf: Transform3D = L(x, 0, z, yaw)
	kit.box(xf * Transform3D(Basis(), Vector3(0, 0.44, 0)), Vector3(w, 0.06, 0.34), "bois", 1.0)
	for sx in [-1.0, 1.0]:
		kit.box(xf * Transform3D(Basis(), Vector3(sx * (w * 0.5 - 0.12), 0.21, 0)), Vector3(0.06, 0.42, 0.3), "bois_sombre", 1.0)


## Un lit (xf : la tête contre le mur, yaw : le lit regarde +Z local = le pied).
func lit(x: float, z: float, yaw: float, w: float = 1.0, couverture: String = "bleu", superpose: bool = false) -> void:
	var xf: Transform3D = L(x, 0, z, yaw)
	var len: float = 2.0
	kit.box(xf * Transform3D(Basis(), Vector3(0, 0.25, 0)), Vector3(w + 0.08, 0.2, len), "bois", 1.0)
	kit.box(xf * Transform3D(Basis(), Vector3(0, 0.42, 0)), Vector3(w, 0.16, len - 0.06), "drap", 1.0)
	kit.box(xf * Transform3D(Basis(), Vector3(0, 0.52, 0.2)), Vector3(w + 0.04, 0.06, len - 0.5), "tissu_" + couverture, 1.0)
	kit.box(xf * Transform3D(Basis(), Vector3(0, 0.56, -len * 0.5 + 0.28)), Vector3(w * 0.75, 0.12, 0.36), "drap", 1.0)
	kit.box(xf * Transform3D(Basis(), Vector3(0, 0.6, -len * 0.5 - 0.02)), Vector3(w + 0.12, 1.2, 0.08), "bois_sombre", 1.0)
	kit.box(xf * Transform3D(Basis(), Vector3(0, 0.35, len * 0.5 + 0.02)), Vector3(w + 0.12, 0.7, 0.06), "bois_sombre", 1.0)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			kit.box(xf * Transform3D(Basis(), Vector3(sx * (w * 0.5 + 0.02), 0.08, sz * (len * 0.5 - 0.02))), Vector3(0.08, 0.16, 0.08), "bois_sombre", 1.0)
	if superpose:
		kit.box(xf * Transform3D(Basis(), Vector3(0, 1.45, 0)), Vector3(w + 0.08, 0.16, len), "bois", 1.0)
		kit.box(xf * Transform3D(Basis(), Vector3(0, 1.6, 0)), Vector3(w, 0.14, len - 0.06), "drap", 1.0)
		kit.box(xf * Transform3D(Basis(), Vector3(0, 1.68, 0.2)), Vector3(w + 0.04, 0.06, len - 0.5), "tissu_" + ["rouge", "vert", "jaune"][rng.randi() % 3], 1.0)
		for sx2 in [-1.0, 1.0]:
			kit.box(xf * Transform3D(Basis(), Vector3(sx2 * (w * 0.5 + 0.02), 1.0, len * 0.5 - 0.04)), Vector3(0.07, 2.0, 0.07), "bois_sombre", 1.0)
		for k in range(4):
			kit.box(xf * Transform3D(Basis(), Vector3(w * 0.25, 0.7 + k * 0.25, len * 0.5 + 0.03)), Vector3(0.4, 0.04, 0.04), "bois_sombre", 1.0)
	kit.col_box(xf * Transform3D(Basis(), Vector3(0, 0.3, 0)), Vector3(w + 0.1, 0.6, len))
	reserve(x, z, (w + 0.3) if absf(sin(deg_to_rad(yaw))) < 0.5 else 2.3, 2.3 if absf(sin(deg_to_rad(yaw))) < 0.5 else (w + 0.3))


func armoire(x: float, z: float, yaw: float, w: float = 1.1, h: float = 2.0) -> void:
	var xf: Transform3D = L(x, 0, z, yaw)
	kit.box(xf * Transform3D(Basis(), Vector3(0, h * 0.5, 0)), Vector3(w, h, 0.55), "bois", 1.0)
	kit.box(xf * Transform3D(Basis(), Vector3(0, h + 0.04, 0)), Vector3(w + 0.1, 0.08, 0.62), "bois_sombre", 1.0)
	kit.box(xf * Transform3D(Basis(), Vector3(0, h * 0.5 + 0.05, 0.28)), Vector3(0.02, h - 0.3, 0.02), "bois_sombre", 1.0)
	for sx in [-1.0, 1.0]:
		kit.box(xf * Transform3D(Basis(), Vector3(sx * w * 0.25, h * 0.5 + 0.05, 0.285)), Vector3(w * 0.38, h * 0.7, 0.01), "bois_clair", 1.0, 16)
		kit.cyl(Transform3D(xf.basis * Basis(Vector3.RIGHT, PI * 0.5), xf * Vector3(sx * 0.07, h * 0.5, 0.3)), 0.025, 0.025, 0.04, "or", 6)
	kit.col_box(xf * Transform3D(Basis(), Vector3(0, h * 0.5, 0)), Vector3(w, h, 0.55))
	reserve(x, z, w + 0.2, 0.8)


## Une étagère (ou une bibliothèque si livres) contre un mur.
func etagere(x: float, z: float, yaw: float, w: float = 1.2, h: float = 1.9, livres: bool = true, rows: int = 4) -> void:
	var xf: Transform3D = L(x, 0, z, yaw)
	var dp: float = 0.36
	kit.box(xf * Transform3D(Basis(), Vector3(0, h * 0.5, -dp * 0.5 + 0.01)), Vector3(w, h, 0.02), "bois_sombre", 1.0)
	for sx in [-1.0, 1.0]:
		kit.box(xf * Transform3D(Basis(), Vector3(sx * (w * 0.5 - 0.02), h * 0.5, 0)), Vector3(0.04, h, dp), "bois", 1.0)
	for i in range(rows + 1):
		var y: float = 0.08 + (h - 0.12) * float(i) / rows
		kit.box(xf * Transform3D(Basis(), Vector3(0, y, 0)), Vector3(w, 0.03, dp), "bois", 1.0)
		if livres and i < rows:
			var bx: float = -w * 0.5 + 0.06
			while bx < w * 0.5 - 0.12:
				var bw: float = rng.randf_range(0.03, 0.07)
				var bh: float = rng.randf_range(0.2, 0.32)
				var col: String = ["rouge", "bleu", "vert", "brun", "jaune", "violet", "noir", "creme"][rng.randi() % 8]
				if rng.randf() < 0.08:
					bx += 0.1
					continue
				kit.box(xf * Transform3D(Basis(Vector3.BACK, rng.randf_range(-0.04, 0.04)), Vector3(bx + bw * 0.5, y + 0.015 + bh * 0.5, 0.0)), Vector3(bw, bh, 0.24), "tissu_" + col, 0.5)
				bx += bw + 0.004
	kit.col_box(xf * Transform3D(Basis(), Vector3(0, h * 0.5, 0)), Vector3(w, h, dp))
	reserve(x, z, w + 0.1, 0.6)


## Une petite étagère murale chargée de bocaux / pots / objets (key des objets).
func etagere_murale(x: float, y: float, z: float, yaw: float, w: float, key: String = "ceramique", n: int = 5) -> void:
	var xf: Transform3D = L(x, y, z, yaw)
	kit.box(xf, Vector3(w, 0.03, 0.25), "bois", 1.0)
	for sx in [-1.0, 1.0]:
		kit.box(xf * Transform3D(Basis(), Vector3(sx * (w * 0.4), -0.08, -0.08)), Vector3(0.03, 0.16, 0.08), "bois_sombre", 1.0)
	for i in range(n):
		var px: float = -w * 0.5 + w * (i + 0.5) / n
		var r: float = rng.randf_range(0.04, 0.07)
		kit.cyl(xf * Transform3D(Basis(), Vector3(px, 0.015, 0)), r, r * 0.9, rng.randf_range(0.1, 0.2), key, 10)


func coffre_deco(x: float, z: float, yaw: float) -> void:
	var xf: Transform3D = L(x, 0, z, yaw)
	kit.box(xf * Transform3D(Basis(), Vector3(0, 0.25, 0)), Vector3(0.9, 0.5, 0.5), "bois", 1.0)
	kit.box(xf * Transform3D(Basis(), Vector3(0, 0.52, 0)), Vector3(0.94, 0.06, 0.54), "bois_sombre", 1.0)
	for sx in [-1.0, 1.0]:
		kit.box(xf * Transform3D(Basis(), Vector3(sx * 0.3, 0.27, 0)), Vector3(0.05, 0.54, 0.52), "fer", 1.0)
	kit.col_box(xf * Transform3D(Basis(), Vector3(0, 0.27, 0)), Vector3(0.9, 0.54, 0.5))
	reserve(x, z, 1.0, 0.7)


func tonneau(x: float, z: float, couche: bool = false) -> void:
	var xf: Transform3D = L(x, 0, z, rng.randf_range(0, 180))
	if couche:
		xf = xf * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(0.45, 0.32, 0))
	kit.cyl(xf, 0.3, 0.34, 0.45, "bois", 14, false)
	kit.cyl(xf * Transform3D(Basis(), Vector3(0, 0.45, 0)), 0.34, 0.3, 0.45, "bois", 14, true)
	kit.cyl(xf, 0.3, 0.3, 0.02, "bois_sombre", 14, true)
	for y in [0.1, 0.45, 0.8]:
		kit.cyl(xf * Transform3D(Basis(), Vector3(0, y - 0.02, 0)), 0.32 + (0.02 if y == 0.45 else 0.0), 0.32 + (0.02 if y == 0.45 else 0.0), 0.05, "fer", 14, false)
	if not couche:
		kit.col_box(L(x, 0.45, z), Vector3(0.6, 0.9, 0.6))
	reserve(x, z, 0.75, 0.75)


func caisse(x: float, z: float, s: float = 0.6, y: float = 0.0) -> void:
	var xf: Transform3D = L(x, y, z, rng.randf_range(-12, 12))
	kit.box(xf * Transform3D(Basis(), Vector3(0, s * 0.5, 0)), Vector3(s, s, s), "bois_clair", 0.6)
	for sy in [0.08, s - 0.08]:
		kit.box(xf * Transform3D(Basis(), Vector3(0, sy, 0)), Vector3(s + 0.02, 0.06, s + 0.02), "bois_sombre", 1.0)
	if y < 0.1:
		kit.col_box(xf * Transform3D(Basis(), Vector3(0, s * 0.5, 0)), Vector3(s, s, s))
		reserve(x, z, s + 0.15, s + 0.15)


func tapis(x: float, z: float, yaw: float, w: float, d: float, idx: int = -1) -> void:
	var n: int = (pal["tapis"] as Array).size()
	var k: int = idx if idx >= 0 else rng.randi() % n
	kit.box(L(x, 0.006, z, yaw), Vector3(w, 0.012, d), "tapis_%d" % (k % n), maxf(w, d), 4)


## Un tableau sur un mur (xf du mur : yaw tel que le tableau regarde l'intérieur).
func tableau(x: float, y: float, z: float, yaw: float, w: float = 0.8, h: float = 0.6, idx: int = -1) -> void:
	var n: int = (pal["tableaux"] as Array).size()
	var k: int = idx if idx >= 0 else rng.randi() % n
	var xf: Transform3D = L(x, y, z, yaw)
	kit.box(xf * Transform3D(Basis(), Vector3(0, 0, 0.02)), Vector3(w, h, 0.02), "tableau_%d" % (k % n), maxf(w, h), 16)
	for s in [-1.0, 1.0]:
		kit.box(xf * Transform3D(Basis(), Vector3(s * (w * 0.5 + 0.03), 0, 0.03)), Vector3(0.06, h + 0.12, 0.04), "or" if rng.randf() < 0.4 else "bois_sombre", 1.0)
		kit.box(xf * Transform3D(Basis(), Vector3(0, s * (h * 0.5 + 0.03), 0.03)), Vector3(w + 0.12, 0.06, 0.04), "or" if rng.randf() < 0.4 else "bois_sombre", 1.0)


## La cheminée (contre un mur) : un vrai feu (flammes, lumière qui vacille) si allume.
func cheminee(x: float, z: float, yaw: float, allume: bool = true) -> Vector3:
	var xf: Transform3D = L(x, 0, z, yaw)
	var key: String = "pierre" if style not in ["braise", "boucan", "astralys"] else ("brique" if style == "boucan" else "pierre_lisse")
	kit.box(xf * Transform3D(Basis(), Vector3(-0.65, 0.55, 0)), Vector3(0.3, 1.1, 0.6), key, 1.0)
	kit.box(xf * Transform3D(Basis(), Vector3(0.65, 0.55, 0)), Vector3(0.3, 1.1, 0.6), key, 1.0)
	kit.box(xf * Transform3D(Basis(), Vector3(0, 1.2, 0)), Vector3(1.7, 0.2, 0.7), "bois_sombre", 1.0)
	kit.box(xf * Transform3D(Basis(), Vector3(0, 1.3 + (H - 1.3) * 0.5, -0.12)), Vector3(1.2, H - 1.3, 0.4), key, 1.0)
	kit.box(xf * Transform3D(Basis(), Vector3(0, 0.55, -0.22)), Vector3(1.0, 1.1, 0.1), "noir", 1.0)
	kit.box(xf * Transform3D(Basis(), Vector3(0, 0.03, 0.15)), Vector3(1.6, 0.06, 0.9), key, 1.0)
	for k in range(3):
		kit.cyl(Transform3D(xf.basis * Basis(Vector3.BACK, PI * 0.5) * Basis(Vector3.UP, 0.3 * k), xf * Vector3(-0.3, 0.12 + k * 0.05, -0.05 + k * 0.05)), 0.06, 0.06, 0.6, "bois_sombre", 6, true)
	kit.col_box(xf * Transform3D(Basis(), Vector3(0, 0.6, -0.05)), Vector3(1.6, 1.2, 0.6))
	reserve(x, z, 1.9, 1.3)
	# sur le manteau : des petites choses
	for i in range(3):
		kit.cyl(xf * Transform3D(Basis(), Vector3(-0.55 + i * 0.5, 1.3, 0.05)), 0.05, 0.04, 0.16 + 0.05 * i, ["ceramique", "cuivre", "terre_cuite"][i], 10)
	var fire_at: Vector3 = xf * Vector3(0, 0.3, 0.0)
	if allume:
		fire(fire_at, 0.9)
	return xf * Vector3(0, 0, 0.9)


## Le foyer de la maison, selon la ville (cheminée, poêle, brasero, irori, four de terre,
## pierres du foyer, lampe de cristal…), contre le mur, qui regarde +Z local.
func foyer(x: float, z: float, yaw: float, allume: bool = true) -> void:
	var kind: String = str(pal.get("foyer", "cheminee"))
	var xf: Transform3D = L(x, 0, z, yaw)
	match kind:
		"cheminee":
			cheminee(x, z, yaw, allume)
		"poele", "cuisiniere":
			kit.cyl(xf, 0.32, 0.32, 0.85, "fer", 14)
			kit.cyl(xf * Transform3D(Basis(), Vector3(0, 0.85, 0)), 0.36, 0.36, 0.06, "fer", 14)
			for k in range(4):
				var a: float = TAU * k / 4.0 + 0.6
				kit.box(xf * Transform3D(Basis(), Vector3(cos(a) * 0.26, -0.0, sin(a) * 0.26)), Vector3(0.05, 0.12, 0.05), "fer", 1.0)
			kit.cyl(xf * Transform3D(Basis(), Vector3(0, 0.9, -0.1)), 0.08, 0.08, H - 0.9, "fer", 10, false)
			kit.box(xf * Transform3D(Basis(), Vector3(0, 0.35, 0.3)), Vector3(0.3, 0.22, 0.02), "noir" if not allume else "flamme", 1.0, 16)
			kit.cyl(xf * Transform3D(Basis(), Vector3(0.12, 0.91, 0.05)), 0.12, 0.1, 0.16, "cuivre", 10)
			kit.col_box(xf * Transform3D(Basis(), Vector3(0, 0.45, 0)), Vector3(0.7, 0.9, 0.7))
			reserve(x, z, 1.1, 1.1)
			if allume:
				var l := OmniLight3D.new()
				l.light_color = Color(1.0, 0.55, 0.25)
				l.light_energy = 1.0
				l.omni_range = 4.0
				root.add_child(l)
				l.global_position = xf * Vector3(0, 0.4, 0.5)
				flames.append([l, 1.0])
		"brasero", "foyer_pierres":
			if kind == "brasero":
				kit.cyl(xf, 0.12, 0.2, 0.5, "cuivre", 12)
				kit.cyl(xf * Transform3D(Basis(), Vector3(0, 0.5, 0)), 0.42, 0.28, 0.2, "cuivre", 16)
				if allume:
					fire(xf * Vector3(0, 0.68, 0), 0.7)
			else:
				for k2 in range(9):
					var a2: float = TAU * k2 / 9.0
					kit.box(Transform3D(xf.basis * Basis(Vector3.UP, a2), xf * Vector3(cos(a2) * 0.5, 0.1, sin(a2) * 0.5)), Vector3(0.22, 0.2, 0.18), "pierre", 0.5)
				kit.cyl(xf * Transform3D(Basis(), Vector3(0, 0.0, 0)), 0.4, 0.4, 0.04, "noir", 14)
				if allume:
					fire(xf * Vector3(0, 0.15, 0), 0.8)
			kit.col_box(xf * Transform3D(Basis(), Vector3(0, 0.3, 0)), Vector3(1.0, 0.6, 1.0))
			reserve(x, z, 1.4, 1.4)
		"irori":
			kit.box(xf * Transform3D(Basis(), Vector3(0, 0.06, 0)), Vector3(1.3, 0.12, 1.3), "bois_sombre", 1.0)
			kit.box(xf * Transform3D(Basis(), Vector3(0, 0.07, 0)), Vector3(1.0, 0.12, 1.0), "noir", 1.0, 4)
			kit.box(xf * Transform3D(Basis(), Vector3(0, H * 0.5 + 0.6, 0)), Vector3(0.03, H - 1.3, 0.03), "fer", 1.0)
			kit.cyl(xf * Transform3D(Basis(), Vector3(0, 0.55, 0)), 0.2, 0.24, 0.26, "fer", 12)
			if allume:
				fire(xf * Vector3(0, 0.15, 0), 0.6)
			kit.col_box(xf * Transform3D(Basis(), Vector3(0, 0.1, 0)), Vector3(1.3, 0.2, 1.3))
			reserve(x, z, 1.6, 1.6)
		"four":
			kit.cyl(xf, 0.65, 0.55, 0.6, "terre_cuite", 16)
			kit.cyl(xf * Transform3D(Basis(), Vector3(0, 0.6, 0)), 0.55, 0.05, 0.7, "terre_cuite", 16)
			kit.box(xf * Transform3D(Basis(), Vector3(0, 0.35, 0.58)), Vector3(0.4, 0.35, 0.02), "flamme" if allume else "noir", 1.0, 16)
			kit.col_box(xf * Transform3D(Basis(), Vector3(0, 0.6, 0)), Vector3(1.2, 1.2, 1.2))
			reserve(x, z, 1.5, 1.5)
			if allume:
				var l2 := OmniLight3D.new()
				l2.light_color = Color(1.0, 0.55, 0.25)
				l2.light_energy = 1.0
				l2.omni_range = 4.0
				root.add_child(l2)
				l2.global_position = xf * Vector3(0, 0.4, 0.9)
				flames.append([l2, 1.0])
		"cristal":
			kit.cyl(xf, 0.3, 0.2, 0.5, "argent", 12)
			for k3 in range(5):
				var a3: float = TAU * k3 / 5.0
				kit.cyl(Transform3D(xf.basis * Basis(Vector3(cos(a3), 0, sin(a3)).cross(Vector3.UP).normalized(), 0.25), xf * Vector3(cos(a3) * 0.08, 0.5, sin(a3) * 0.08)), 0.07, 0.0, 0.6 + 0.1 * k3, "cristal", 6)
			var l3 := OmniLight3D.new()
			l3.light_color = Color(0.55, 0.8, 1.0)
			l3.light_energy = 1.4
			l3.omni_range = 6.0
			root.add_child(l3)
			l3.global_position = xf * Vector3(0, 1.0, 0.2)
			lights.append(l3)
			kit.col_box(xf * Transform3D(Basis(), Vector3(0, 0.5, 0)), Vector3(0.6, 1.0, 0.6))
			reserve(x, z, 0.9, 0.9)


## Un petit feu : des flammes en particules et une lumière chaude qui vacille.
func fire(at: Vector3, s: float = 1.0) -> void:
	var p := CPUParticles3D.new()
	p.amount = 26
	p.lifetime = 0.7
	p.direction = Vector3.UP
	p.spread = 12.0
	p.initial_velocity_min = 0.3 * s
	p.initial_velocity_max = 0.7 * s
	p.gravity = Vector3(0, 0.6, 0)
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.18 * s
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.2
	var curve := Curve.new()
	curve.add_point(Vector2(0, 0.6))
	curve.add_point(Vector2(0.3, 1.0))
	curve.add_point(Vector2(1, 0.0))
	p.scale_amount_curve = curve
	var grad := Gradient.new()
	grad.set_color(0, Color(1.0, 0.85, 0.4, 1.0))
	grad.set_color(1, Color(0.9, 0.25, 0.05, 0.0))
	p.color_ramp = grad
	var q := QuadMesh.new()
	q.size = Vector2(0.22, 0.3) * s
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = dot_texture()
	q.material = m
	p.mesh = q
	root.add_child(p)
	p.global_position = at
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.6, 0.3)
	l.light_energy = 1.8 * s
	l.omni_range = 5.5 * s
	l.shadow_enabled = false
	root.add_child(l)
	l.global_position = at + Vector3.UP * 0.4
	flames.append([l, 1.8 * s])


func bougie(x: float, y: float, z: float, lumiere: bool = true) -> void:
	kit.cyl(L(x, y, z), 0.025, 0.025, 0.14, "ceramique", 8)
	kit.cyl(L(x, y + 0.14, z), 0.008, 0.0, 0.035, "flamme", 6, false)
	if lumiere:
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.7, 0.4)
		l.light_energy = 0.7
		l.omni_range = 3.2
		root.add_child(l)
		l.global_position = P(x, y + 0.25, z)
		flames.append([l, 0.7])


static func dot_texture() -> Texture2D:
	if _dot != null:
		return _dot
	var g := GradientTexture2D.new()
	var gr := Gradient.new()
	gr.set_color(0, Color(1, 1, 1, 1))
	gr.set_color(1, Color(1, 1, 1, 0))
	g.gradient = gr
	g.fill = GradientTexture2D.FILL_RADIAL
	g.fill_from = Vector2(0.5, 0.5)
	g.fill_to = Vector2(1.0, 0.5)
	g.width = 64
	g.height = 64
	_dot = g
	return _dot


## La cuisine : un plan de travail, un fourneau (ou un four), des casseroles, des bocaux.
func cuisine(x: float, z: float, yaw: float, w: float = 2.4) -> void:
	var xf: Transform3D = L(x, 0, z, yaw)
	kit.box(xf * Transform3D(Basis(), Vector3(0, 0.45, 0)), Vector3(w, 0.9, 0.6), "bois", 1.0)
	kit.box(xf * Transform3D(Basis(), Vector3(0, 0.92, 0.02)), Vector3(w + 0.04, 0.05, 0.66), "pierre_lisse", 1.0)
	for i in range(int(w / 0.6)):
		kit.box(xf * Transform3D(Basis(), Vector3(-w * 0.5 + 0.3 + i * 0.6, 0.45, 0.305)), Vector3(0.52, 0.75, 0.01), "bois_clair", 1.0, 16)
	# le fourneau, à gauche
	kit.box(xf * Transform3D(Basis(), Vector3(-w * 0.5 - 0.4, 0.45, 0)), Vector3(0.75, 0.9, 0.62), "fer", 1.0)
	kit.cyl(xf * Transform3D(Basis(), Vector3(-w * 0.5 - 0.4, 0.9, 0.0)), 0.18, 0.2, 0.22, "cuivre", 12)
	kit.box(xf * Transform3D(Basis(), Vector3(-w * 0.5 - 0.4, 0.45, 0.315)), Vector3(0.5, 0.35, 0.01), "noir", 1.0, 16)
	# des casseroles pendues, des bocaux, une miche
	for i2 in range(3):
		kit.cyl(xf * Transform3D(Basis(), Vector3(-w * 0.3 + i2 * 0.35, 1.55, -0.2)), 0.1 + i2 * 0.02, 0.1 + i2 * 0.02, 0.1, "cuivre", 10)
	kit.box(xf * Transform3D(Basis(), Vector3(0, 1.7, -0.28)), Vector3(w, 0.04, 0.04), "fer", 1.0)
	for i3 in range(4):
		kit.cyl(xf * Transform3D(Basis(), Vector3(w * 0.15 + i3 * 0.16, 0.945, -0.15)), 0.05, 0.05, 0.16, ["verre", "confiture", "ceramique", "terre_cuite"][i3], 10)
	kit.box(xf * Transform3D(Basis(Vector3.UP, 0.4), Vector3(-w * 0.15, 1.0, 0.0)), Vector3(0.3, 0.1, 0.16), "pain", 1.0)
	kit.col_box(xf * Transform3D(Basis(), Vector3(-0.2, 0.45, 0)), Vector3(w + 0.8, 0.9, 0.6))
	reserve(x, z, w + 1.0, 0.9)


## Un fauteuil (assise basse, accoudoirs).
func fauteuil(x: float, z: float, yaw: float, c: String = "rouge") -> void:
	var xf: Transform3D = L(x, 0, z, yaw)
	kit.box(xf * Transform3D(Basis(), Vector3(0, 0.25, 0)), Vector3(0.8, 0.3, 0.75), "tissu_" + c, 1.0)
	kit.box(xf * Transform3D(Basis(), Vector3(0, 0.45, 0.05)), Vector3(0.6, 0.1, 0.6), "tissu_" + c, 1.0)
	kit.box(xf * Transform3D(Basis(), Vector3(0, 0.75, -0.32)), Vector3(0.8, 0.75, 0.15), "tissu_" + c, 1.0)
	for sx in [-1.0, 1.0]:
		kit.box(xf * Transform3D(Basis(), Vector3(sx * 0.36, 0.5, 0.0)), Vector3(0.12, 0.3, 0.72), "tissu_" + c, 1.0)
	kit.col_box(xf * Transform3D(Basis(), Vector3(0, 0.4, 0)), Vector3(0.8, 0.8, 0.75))
	reserve(x, z, 1.0, 1.0)


func canape(x: float, z: float, yaw: float, c: String = "vert", w: float = 1.9) -> void:
	var xf: Transform3D = L(x, 0, z, yaw)
	kit.box(xf * Transform3D(Basis(), Vector3(0, 0.22, 0)), Vector3(w, 0.3, 0.85), "tissu_" + c, 1.0)
	for i in range(2):
		kit.box(xf * Transform3D(Basis(), Vector3(-w * 0.25 + i * w * 0.5, 0.43, 0.06)), Vector3(w * 0.48, 0.12, 0.66), "tissu_" + c, 1.0)
	kit.box(xf * Transform3D(Basis(), Vector3(0, 0.66, -0.36)), Vector3(w, 0.65, 0.16), "tissu_" + c, 1.0)
	for sx in [-1.0, 1.0]:
		kit.box(xf * Transform3D(Basis(), Vector3(sx * (w * 0.5 - 0.06), 0.48, 0.0)), Vector3(0.14, 0.32, 0.85), "tissu_" + c, 1.0)
	kit.box(xf * Transform3D(Basis(Vector3.BACK, 0.2), Vector3(w * 0.3, 0.6, -0.15)), Vector3(0.35, 0.3, 0.12), "tissu_" + ["jaune", "rose", "creme", "orange"][rng.randi() % 4], 1.0)
	kit.col_box(xf * Transform3D(Basis(), Vector3(0, 0.4, 0)), Vector3(w, 0.8, 0.85))
	reserve(x, z, w + 0.2, 1.1)


## Une plante en pot (y : posée sur un meuble à cette hauteur).
func plante(x: float, z: float, y: float = 0.0, s: float = 1.0) -> void:
	var xf: Transform3D = L(x, y, z)
	kit.cyl(xf, 0.14 * s, 0.18 * s, 0.28 * s, "terre_cuite", 12)
	kit.cyl(xf * Transform3D(Basis(), Vector3(0, 0.27 * s, 0)), 0.15 * s, 0.15 * s, 0.01, "terreau", 12)
	for k in range(6):
		var a: float = TAU * k / 6.0 + rng.randf()
		var lx: Transform3D = xf * Transform3D(Basis(Vector3.UP, -a) * Basis(Vector3.RIGHT, rng.randf_range(0.4, 0.9)), Vector3(0, 0.28 * s, 0))
		kit.box(lx * Transform3D(Basis(), Vector3(0, 0.22 * s, 0)), Vector3(0.12 * s, 0.45 * s, 0.02), "feuillage", 1.0)
	if y < 0.1:
		reserve(x, z, 0.5 * s, 0.5 * s)


## Une horloge comtoise contre un mur.
func horloge(x: float, z: float, yaw: float) -> Vector3:
	var xf: Transform3D = L(x, 0, z, yaw)
	kit.box(xf * Transform3D(Basis(), Vector3(0, 0.95, 0)), Vector3(0.45, 1.9, 0.32), "bois", 1.0)
	kit.box(xf * Transform3D(Basis(), Vector3(0, 2.0, 0)), Vector3(0.55, 0.25, 0.36), "bois_sombre", 1.0)
	kit.cyl(Transform3D(xf.basis * Basis(Vector3.RIGHT, PI * 0.5), xf * Vector3(0, 1.55, 0.17)), 0.17, 0.17, 0.01, "ceramique", 18)
	kit.box(xf * Transform3D(Basis(), Vector3(0, 0.8, 0.165)), Vector3(0.22, 0.8, 0.01), "verre", 1.0, 16)
	kit.cyl(xf * Transform3D(Basis(), Vector3(0, 0.45, 0.14)), 0.07, 0.07, 0.02, "or", 12)
	kit.col_box(xf * Transform3D(Basis(), Vector3(0, 1.0, 0)), Vector3(0.5, 2.0, 0.35))
	reserve(x, z, 0.7, 0.6)
	return xf * Vector3(0, 0, 0.6)


## Un drap blanc posé sur un meuble (maison abandonnée).
func drape(x: float, z: float, yaw: float, w: float, d: float, h: float) -> void:
	var xf: Transform3D = L(x, 0, z, yaw)
	kit.box(xf * Transform3D(Basis(), Vector3(0, h * 0.5, 0)), Vector3(w, h, d), "drap", 1.0, 63 - 8)
	kit.box(xf * Transform3D(Basis(Vector3.RIGHT, 0.12), Vector3(0, h * 0.2, d * 0.5 + 0.04)), Vector3(w + 0.04, h * 0.45, 0.02), "drap", 1.0)
	kit.col_box(xf * Transform3D(Basis(), Vector3(0, h * 0.5, 0)), Vector3(w, h, d))
	reserve(x, z, w + 0.2, d + 0.2)


## Des toiles d'araignée dans les coins du plafond.
func toiles(n: int = 4) -> void:
	var hw: float = W * 0.5
	var hd: float = D * 0.5
	var corners: Array = [[-hw, -hd, 45.0], [hw, -hd, -45.0], [-hw, hd, 135.0], [hw, hd, -135.0]]
	for i in range(mini(n, 4)):
		var c: Array = corners[i]
		var s: float = rng.randf_range(0.7, 1.1)
		var xf: Transform3D = L(float(c[0]), H - 0.02, float(c[1]), float(c[2]) + 180.0)
		var q := xf * Transform3D(Basis(Vector3.RIGHT, -PI * 0.25), Vector3(0, -s * 0.35, -s * 0.35))
		kit.quad(q, s * 1.2, s * 1.0, "toile", Vector2(0, 0), Vector2(1, 1), true)


## De la poussière qui danse dans la lumière (particules lentes).
func poussiere(n: int = 40) -> void:
	var p := CPUParticles3D.new()
	p.amount = n
	p.lifetime = 9.0
	p.preprocess = 9.0
	p.direction = Vector3.UP
	p.spread = 180.0
	p.initial_velocity_min = 0.01
	p.initial_velocity_max = 0.05
	p.gravity = Vector3(0, -0.005, 0)
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(W * 0.45, H * 0.4, D * 0.45)
	p.scale_amount_min = 0.3
	p.scale_amount_max = 0.8
	var q := QuadMesh.new()
	q.size = Vector2(0.03, 0.03)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(1.0, 0.95, 0.85, 0.5)
	m.albedo_texture = dot_texture()
	q.material = m
	p.mesh = q
	root.add_child(p)
	p.global_position = P(0, H * 0.5, 0)


## Une trappe dans le sol (la descente vers la cave). Renvoie son centre.
func trappe(x: float, z: float) -> Vector3:
	kit.box(L(x, 0.01, z), Vector3(1.1, 0.03, 1.1), "bois_sombre", 1.0, 4)
	for k in range(5):
		kit.box(L(x - 0.44 + k * 0.22, 0.03, z), Vector3(0.2, 0.02, 1.0), "bois", 1.0, 4)
	kit.box(L(x, 0.04, z - 0.25), Vector3(0.9, 0.02, 0.06), "fer", 1.0, 4)
	kit.box(L(x, 0.04, z + 0.25), Vector3(0.9, 0.02, 0.06), "fer", 1.0, 4)
	kit.ring(L(x + 0.35, 0.03, z), 0.05, 0.07, 0.02, "fer", 10)
	return P(x, 0, z)


## Une échelle posée contre un mur.
func echelle(x: float, z: float, yaw: float, h: float = 2.4) -> void:
	var xf: Transform3D = L(x, 0, z, yaw) * Transform3D(Basis(Vector3.RIGHT, -0.22), Vector3.ZERO)
	for sx in [-1.0, 1.0]:
		kit.box(xf * Transform3D(Basis(), Vector3(sx * 0.22, h * 0.5, 0)), Vector3(0.05, h, 0.05), "bois_clair", 1.0)
	for i in range(int(h / 0.3)):
		kit.box(xf * Transform3D(Basis(), Vector3(0, 0.25 + i * 0.3, 0)), Vector3(0.44, 0.035, 0.035), "bois_clair", 1.0)


## Des assiettes, des verres et un plat au milieu d'une table (hauteur y).
func couverts(x: float, z: float, y: float, places: Array, plat: String = "soupe") -> void:
	for pp in places:
		var p: Vector2 = pp
		kit.cyl(L(x + p.x, y, z + p.y), 0.13, 0.12, 0.02, "ceramique", 14)
		kit.cyl(L(x + p.x * 1.3 + 0.12, y, z + p.y * 1.3), 0.035, 0.03, 0.1, "verre", 8, false)
	kit.cyl(L(x, y, z), 0.2, 0.17, 0.12, "ceramique", 16)
	kit.cyl(L(x, y + 0.11, z), 0.19, 0.19, 0.005, plat, 16)


## Un gâteau d'anniversaire (avec des bougies allumées).
func gateau(x: float, y: float, z: float) -> void:
	kit.cyl(L(x, y, z), 0.22, 0.22, 0.02, "argent", 18)
	kit.cyl(L(x, y + 0.02, z), 0.18, 0.18, 0.12, "gateau", 18)
	kit.cyl(L(x, y + 0.14, z), 0.13, 0.13, 0.09, "chocolat", 18)
	for k in range(5):
		var a: float = TAU * k / 5.0
		bougie(x + cos(a) * 0.08, y + 0.23, z + sin(a) * 0.08, k == 0)


## Une guirlande de fanions d'un mur à l'autre.
func guirlande(a: Vector3, b: Vector3, n: int = 12) -> void:
	var colors: Array = ["rouge", "jaune", "bleu", "vert", "rose", "orange", "violet", "turquoise"]
	for i in range(n):
		var t: float = (i + 0.5) / n
		var p: Vector3 = a.lerp(b, t) + Vector3.DOWN * sin(t * PI) * 0.35
		var dir: Vector3 = (b - a).normalized()
		var xf := Transform3D(Basis(Vector3.UP, atan2(dir.x, dir.z) + PI * 0.5), p)
		kit.tri("tissu_" + colors[i % colors.size()], xf * Vector3(-0.1, 0, 0), xf * Vector3(0.1, 0, 0), xf * Vector3(0, -0.22, 0), xf.basis * Vector3(0, 0, 1), Vector2(0, 0), Vector2(1, 0), Vector2(0.5, 1))
		kit.tri("tissu_" + colors[i % colors.size()], xf * Vector3(-0.1, 0, 0), xf * Vector3(0.1, 0, 0), xf * Vector3(0, -0.22, 0), xf.basis * Vector3(0, 0, -1), Vector2(0, 0), Vector2(1, 0), Vector2(0.5, 1))


## Un ballon de baudruche (une sphère et sa ficelle).
func ballon(x: float, y: float, z: float, c: String) -> void:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.16
	sm.height = 0.38
	sm.radial_segments = 16
	sm.rings = 8
	mi.mesh = sm
	var m := StandardMaterial3D.new()
	m.albedo_color = (mat("tissu_" + c) as StandardMaterial3D).albedo_color.lightened(0.15)
	m.roughness = 0.25
	m.metallic_specular = 0.8
	mi.material_override = m
	root.add_child(mi)
	mi.global_position = P(x, y, z)
	kit.box(L(x, y - 0.6, z), Vector3(0.006, 0.84, 0.006), "papier", 1.0)


## Une pile de livres, de papiers, ou d'objets posés au sol.
func pile(x: float, z: float, key: String = "livres", n: int = 5) -> void:
	var y: float = 0.0
	for i in range(n):
		var t: float = rng.randf_range(0.04, 0.08)
		kit.box(L(x + rng.randf_range(-0.03, 0.03), y + t * 0.5, z, rng.randf_range(-20, 20)), Vector3(rng.randf_range(0.22, 0.3), t, rng.randf_range(0.16, 0.22)), key if key != "livres" else "tissu_" + ["rouge", "bleu", "vert", "brun", "creme"][rng.randi() % 5], 0.4)
		y += t


## Un établi d'inventeur (plateau, étau, outils, une machine bizarre dessus).
func etabli(x: float, z: float, yaw: float, w: float = 2.0) -> void:
	var xf: Transform3D = L(x, 0, z, yaw)
	kit.box(xf * Transform3D(Basis(), Vector3(0, 0.88, 0)), Vector3(w, 0.08, 0.8), "bois", 1.0)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			kit.box(xf * Transform3D(Basis(), Vector3(sx * (w * 0.5 - 0.08), 0.42, sz * 0.32)), Vector3(0.09, 0.84, 0.09), "bois_sombre", 1.0)
	kit.box(xf * Transform3D(Basis(), Vector3(0, 0.25, 0)), Vector3(w - 0.2, 0.04, 0.7), "bois_sombre", 1.0)
	kit.box(xf * Transform3D(Basis(), Vector3(w * 0.4, 0.98, 0.3)), Vector3(0.18, 0.12, 0.12), "fer", 1.0)
	for i in range(4):
		kit.box(xf * Transform3D(Basis(Vector3.UP, rng.randf_range(-0.5, 0.5)), Vector3(-w * 0.35 + i * 0.18, 0.93, 0.2)), Vector3(0.04, 0.02, 0.25), ["fer", "cuivre", "bois_clair", "metal"][i], 1.0)
	kit.col_box(xf * Transform3D(Basis(), Vector3(0, 0.45, 0)), Vector3(w, 0.9, 0.8))
	reserve(x, z, w + 0.2, 1.0)


## Une machine farfelue (chaudière, engrenages, tuyaux, voyants) ; renvoie son bouton.
func machine(x: float, z: float, yaw: float) -> Vector3:
	var xf: Transform3D = L(x, 0, z, yaw)
	kit.cyl(xf * Transform3D(Basis(), Vector3(0, 0, 0)), 0.45, 0.45, 1.3, "cuivre", 16)
	kit.cyl(xf * Transform3D(Basis(), Vector3(0, 1.3, 0)), 0.45, 0.15, 0.4, "cuivre", 16)
	kit.cyl(xf * Transform3D(Basis(), Vector3(0, 1.7, 0)), 0.06, 0.06, 0.6, "fer", 8)
	for k in range(3):
		var g: Transform3D = xf * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(-0.3 + k * 0.3, 0.6 + k * 0.25, 0.46))
		kit.cyl(g, 0.12 + k * 0.03, 0.12 + k * 0.03, 0.03, "or" if k == 1 else "fer", 12)
	kit.box(xf * Transform3D(Basis(), Vector3(0.55, 0.9, 0.0)), Vector3(0.4, 0.6, 0.4), "metal", 1.0)
	kit.cyl(Transform3D(xf.basis * Basis(Vector3.RIGHT, PI * 0.5), xf * Vector3(0.55, 0.95, 0.2)), 0.06, 0.06, 0.04, "pomme", 10)
	for k2 in range(3):
		kit.cyl(Transform3D(xf.basis * Basis(Vector3.RIGHT, PI * 0.5), xf * Vector3(0.45 + k2 * 0.1, 1.12, 0.2)), 0.02, 0.02, 0.02, "lumiere", 6)
	kit.col_box(xf * Transform3D(Basis(), Vector3(0.1, 0.8, 0)), Vector3(1.4, 1.6, 1.0))
	reserve(x, z, 1.6, 1.2)
	return xf * Vector3(0.55, 0.0, 0.8)


## Un piano droit.
func piano(x: float, z: float, yaw: float) -> void:
	var xf: Transform3D = L(x, 0, z, yaw)
	kit.box(xf * Transform3D(Basis(), Vector3(0, 0.62, -0.1)), Vector3(1.5, 1.24, 0.5), "bois_sombre", 1.0)
	kit.box(xf * Transform3D(Basis(), Vector3(0, 0.74, 0.22)), Vector3(1.4, 0.06, 0.24), "ceramique", 1.0)
	for i in range(14):
		kit.box(xf * Transform3D(Basis(), Vector3(-0.6 + i * 0.093, 0.79, 0.2)), Vector3(0.03, 0.03, 0.12), "noir", 1.0)
	kit.col_box(xf * Transform3D(Basis(), Vector3(0, 0.62, -0.05)), Vector3(1.5, 1.24, 0.6))
	reserve(x, z, 1.7, 1.0)


## Une baignoire sabot (les baignoires, c'est drôle dans un salon).
func baignoire(x: float, z: float, yaw: float) -> void:
	var xf: Transform3D = L(x, 0, z, yaw)
	# une vraie cuve : le fond, quatre bords, l'eau (on peut s'y asseoir)
	kit.box(xf * Transform3D(Basis(), Vector3(0, 0.1, 0)), Vector3(0.8, 0.12, 1.6), "ceramique", 1.0)
	for sx in [-1.0, 1.0]:
		kit.box(xf * Transform3D(Basis(), Vector3(sx * 0.36, 0.33, 0)), Vector3(0.08, 0.5, 1.6), "ceramique", 1.0)
	for sz in [-1.0, 1.0]:
		kit.box(xf * Transform3D(Basis(), Vector3(0, 0.33, sz * 0.76)), Vector3(0.8, 0.5, 0.08), "ceramique", 1.0)
	kit.box(xf * Transform3D(Basis(), Vector3(0, 0.42, 0)), Vector3(0.64, 0.01, 1.44), "verre", 1.0, 4)
	# de la mousse
	for k in range(9):
		kit.cyl(xf * Transform3D(Basis(), Vector3(rng.randf_range(-0.25, 0.25), 0.41, rng.randf_range(-0.6, 0.6))), rng.randf_range(0.06, 0.12), 0.0, 0.08, "drap", 8)
	for sx2 in [-1.0, 1.0]:
		for sz2 in [-1.0, 1.0]:
			kit.cyl(xf * Transform3D(Basis(), Vector3(sx2 * 0.32, 0, sz2 * 0.7)), 0.05, 0.04, 0.08, "or", 8)
	# le canard en bois
	kit.cyl(xf * Transform3D(Basis(), Vector3(0.12, 0.42, 0.45)), 0.05, 0.04, 0.06, "fromage", 8)
	kit.cyl(xf * Transform3D(Basis(), Vector3(0.12, 0.48, 0.49)), 0.03, 0.025, 0.04, "fromage", 8)
	for sx3 in [-1.0, 1.0]:
		kit.col_box(xf * Transform3D(Basis(), Vector3(sx3 * 0.36, 0.3, 0)), Vector3(0.08, 0.6, 1.6))
	reserve(x, z, 1.0, 1.8)


## Un chat (petit, simple : corps, tête, oreilles, queue), assis ou couché.
func chat(x: float, z: float, yaw: float, c: Color, couche: bool = false, y: float = 0.0) -> Node3D:
	var n := Node3D.new()
	n.name = "Chat"
	root.add_child(n)
	n.global_transform = L(x, y, z, yaw)
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.95
	var add := func(mesh: Mesh, pos: Vector3, scl: Vector3, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.material_override = m
		mi.position = pos
		mi.scale = scl
		mi.rotation = rot
		n.add_child(mi)
		return mi
	var sph := SphereMesh.new()
	sph.radius = 0.5
	sph.height = 1.0
	sph.radial_segments = 12
	sph.rings = 6
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.5
	cone.height = 1.0
	cone.radial_segments = 4
	var tube := CylinderMesh.new()
	tube.top_radius = 0.5
	tube.bottom_radius = 0.5
	tube.height = 1.0
	tube.radial_segments = 6
	if couche:
		add.call(sph, Vector3(0, 0.1, 0), Vector3(0.28, 0.18, 0.4))
		add.call(sph, Vector3(0, 0.15, 0.2), Vector3(0.17, 0.15, 0.16))
		add.call(cone, Vector3(-0.05, 0.25, 0.2), Vector3(0.06, 0.08, 0.05))
		add.call(cone, Vector3(0.05, 0.25, 0.2), Vector3(0.06, 0.08, 0.05))
		add.call(tube, Vector3(0.12, 0.06, -0.12), Vector3(0.05, 0.3, 0.05), Vector3(PI * 0.5, 0, 0.6))
	else:
		add.call(sph, Vector3(0, 0.16, 0), Vector3(0.22, 0.3, 0.26))
		add.call(sph, Vector3(0, 0.36, 0.08), Vector3(0.17, 0.15, 0.16))
		add.call(cone, Vector3(-0.05, 0.46, 0.08), Vector3(0.06, 0.08, 0.05))
		add.call(cone, Vector3(0.05, 0.46, 0.08), Vector3(0.06, 0.08, 0.05))
		add.call(tube, Vector3(0.0, 0.05, -0.18), Vector3(0.05, 0.3, 0.05), Vector3(PI * 0.42, 0, 0))
	var eye := StandardMaterial3D.new()
	eye.albedo_color = Color(0.9, 0.8, 0.2)
	eye.emission_enabled = true
	eye.emission = Color(0.5, 0.45, 0.1)
	for sx in [-1.0, 1.0]:
		var e := MeshInstance3D.new()
		var es := SphereMesh.new()
		es.radius = 0.018
		es.height = 0.036
		e.mesh = es
		e.material_override = eye
		e.position = Vector3(sx * 0.045, (0.17 if couche else 0.38), (0.33 if couche else 0.22))
		if not couche or rng.randf() < 0.3:
			n.add_child(e)
	return n


## Construit dans un nœud à part (qu'on peut ensuite déplacer : une bibliothèque qui glisse, un
## tapis qu'on soulève, des meubles au plafond…). fn : les appels de meubles, en repère de pièce.
func movable(fn: Callable) -> Node3D:
	var n := Node3D.new()
	n.name = "Mobile"
	root.add_child(n)
	var saved = kit
	kit = Kit.new()
	kit.setup(n, null)
	kit.mats = saved.mats
	fn.call()
	kit.commit()
	kit = saved
	return n


## Toute la géométrie regroupée part dans la scène (un maillage par matériau).
func commit() -> void:
	kit.commit()
	for c in root.get_children():
		if c is MeshInstance3D:
			(c as MeshInstance3D).visibility_range_end = 0.0


## Les flammes vacillent (appelé par maisons_v81 à chaque image).
func tick(t: float) -> void:
	for f in flames:
		var l: OmniLight3D = f[0]
		if is_instance_valid(l):
			l.light_energy = float(f[1]) * (0.85 + 0.12 * sin(t * 9.0 + l.get_instance_id() % 7) + 0.08 * sin(t * 23.0))
