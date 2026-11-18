extends RefCounted
## V171 : on entre dans les temples, les palais, les ateliers et les tours des Trois Soleils
## (Per-Hâpy, Yaxché, Aztlán), d'Arcanelle et de Port-Coutelas.
## Comme les boutiques (boutiques_v170.gd, qui délègue ici les métiers qu'il ne connaît pas) : chaque
## ville pose ses portes (porte_ville) ; on entre comme dans une maison (maisons_v81), et derrière la
## porte, la pièce de l'endroit (« b171 » ; build()) : le fournil de Mérit et ses fours en coupole, la
## Maison de Vie et ses petits scribes, le naos de Rê, la salle hypostyle du temple de la vallée, le
## trône du palais de Yaxché, l'observatoire d'Ah Kin, le calmecac de Citlali, la Tour d'Astrelune et
## ses livres qui flottent, la roulotte d'Agathe, la tour de Pyra, la caverne d'Isaac Cinq-Doigts, la
## Tour Lunette du cartographe…
## Celui qui tient l'endroit est la vraie personne de la ville quand elle existe (on lui parle comme
## dehors) ; sinon, un habitant (un petit menu). Les portes des quêtes (le temple de Kukulkán et
## Xibalba, les sanctuaires d'Aztlán et la dalle du Grand Temple, la pyramide, le Sphinx, le donjon du
## Fort Maudit) ne bougent pas.
## M : maisons_v81 ; R : la pièce (maisons_pieces_v81) ; B : les boutiques (les aides : le comptoir,
## le marchand, les enseignes, les lampes…).

const B = preload("res://scripts/boutiques_v170.gd")
const Sud = preload("res://scripts/maisons_sud_v169.gd")
const SM = preload("res://scripts/soleils_mats_v69.gd")

const HISTOIRE := "b171"

## Chaque endroit : la taille de la pièce (largeur, profondeur) et sa hauteur.
const METIERS := {
	"fournil": [Vector2(9.0, 6.5), 3.4], "pretresse": [Vector2(8.5, 6.5), 3.6], "maison_vie": [Vector2(13.0, 7.5), 4.2],
	"poterie": [Vector2(7.5, 6.0), 3.2], "naos": [Vector2(7.0, 6.0), 4.6], "temple_vallee": [Vector2(14.0, 10.0), 6.0],
	"palais_maya": [Vector2(15.0, 7.5), 4.6], "temple_jaguars": [Vector2(6.0, 5.5), 4.0], "observatoire_maya": [Vector2(8.0, 8.0), 5.0],
	"sanctuaire_cenote": [Vector2(5.5, 5.0), 3.4], "calmecac": [Vector2(11.5, 7.0), 4.2], "palais_azteque": [Vector2(12.5, 7.0), 4.6],
	"tour_archimage": [Vector2(10.0, 10.0), 6.5], "dortoir": [Vector2(9.0, 7.0), 3.0], "observatoire_arc": [Vector2(8.0, 8.0), 7.0],
	"alambic": [Vector2(8.5, 7.0), 3.4], "roulotte": [Vector2(3.2, 5.0), 2.7], "tour_pyra": [Vector2(6.6, 6.6), 5.0],
	"receleur": [Vector2(7.0, 6.0), 3.0], "cabinet_doc": [Vector2(7.0, 6.5), 3.0], "residence": [Vector2(11.0, 8.0), 4.4],
	"tour_lunette": [Vector2(7.0, 7.0), 5.0],
}

## Les pièces rondes (les tours) : le mur rond dans la pièce carrée.
const RONDS := ["observatoire_maya", "tour_archimage", "observatoire_arc", "tour_pyra", "tour_lunette"]

## Les endroits de chaque ville : id (celui de la ville) → [métier, la vraie personne, « E : entrer … », enseigne].
const VILLES := {
	"egypte": {
		"merit": ["fournil", "merit", "au fournil de Mérit", "Fournil de Mérit"],
		"neferet": ["pretresse", "neferet", "chez Néferet, la prêtresse de Rê", "Maison de Néferet"],
		"ecole": ["maison_vie", "amenemhat", "à la Maison de Vie, l'école des scribes", "Maison de Vie"],
		"ptahmose": ["poterie", "ptahmose", "à l'atelier de Ptahmosé, le potier", "Atelier de Ptahmosé"],
		"naos": ["naos", "", "dans le naos de Rê", "Naos de Rê"],
		"vallee": ["temple_vallee", "", "dans le temple de la vallée", "Temple de la vallée"],
	},
	"maya": {
		"palais": ["palais_maya", "ixkanul", "au palais de Yaxché", "Palais de Yaxché"],
		"jaguars": ["temple_jaguars", "", "dans le Temple des Jaguars", "Temple des Jaguars"],
		"observatoire": ["observatoire_maya", "ahkin", "à l'observatoire d'Ah Kin", "Observatoire"],
		"cenote": ["sanctuaire_cenote", "", "dans le sanctuaire du cénote", "Sanctuaire du cénote"],
	},
	"azteque": {
		"calmecac": ["calmecac", "citlali", "au calmecac, l'école de Citlali", "Calmecac"],
		"palais": ["palais_azteque", "mixtli", "au palais d'Aztlán", "Palais d'Aztlán"],
	},
	"arcanelle": {
		"tour": ["tour_archimage", "archimage", "dans la Tour d'Astrelune", "Tour d'Astrelune"],
		"dortoir": ["dortoir", "pip", "au dortoir des apprentis", "Dortoir des apprentis"],
		"observatoire": ["observatoire_arc", "lumen", "à l'Observatoire d'Aurélien Lumen", "Observatoire"],
		"alambic": ["alambic", "gustave", "à L'Alambic, chez Gustave Fiole", "L'Alambic"],
		"roulotte": ["roulotte", "agathe", "dans la roulotte d'Agathe", "Roulotte d'Agathe"],
		"pyra": ["tour_pyra", "pyra", "dans la tour de Pyra Flammèche", "Tour de Pyra"],
	},
	"pirate": {
		"receleur": ["receleur", "isaac", "chez Isaac Cinq-Doigts, le receleur", "Isaac Cinq-Doigts, receleur"],
		"doc": ["cabinet_doc", "doc", "au cabinet du Doc Saignée", "Doc Saignée, chirurgien-barbier"],
		"residence": ["residence", "gouverneur", "à la résidence du Gouverneur", "Résidence du Gouverneur"],
		"lunette": ["tour_lunette", "philemon", "à la Tour Lunette, chez le cartographe", "Tour Lunette"],
	},
}


# =================================================================== les portes (les villes les posent)

## Une ville pose la porte d'un de ses endroits (VILLES) : faux si ce n'en est pas un.
static func porte_ville(style: String, id: String, door: Vector3, out: Vector3) -> bool:
	var v: Dictionary = VILLES.get(style, {})
	if not v.has(id):
		return false
	var e: Array = v[id]
	return B.porte(door, out, style, str(e[0]), str(e[1]), str(e[2]), str(e[3]), HISTOIRE)


static func ouvre(style: String, id: String) -> bool:
	return (VILLES.get(style, {}) as Dictionary).has(id)


static func has_metier(met: String) -> bool:
	return METIERS.has(met)


# =================================================================== la coque

## La palette d'un endroit : [image, teinte, répétition] pour le sol, le mur, le bas, le plafond.
static func _pal(st: String, met: String) -> Dictionary:
	var p := {}
	match st:
		"egypte":
			p = {"sol": ["soleils/dalles_soleil.png", Color(1.0, 0.95, 0.88), 2.0], "mur": ["soleils/enduit.png", Color(1.0, 0.93, 0.8), 2.5],
				"bas": ["soleils/hieroglyphes.png", Color(1, 1, 1), 1.2], "plafond": ["soleils/limon.png", Color(0.8, 0.7, 0.55), 2.0], "fenetre": "fente"}
			match met:
				"fournil":
					p["sol"] = ["soleils/limon.png", Color(0.92, 0.82, 0.66), 2.0]
					p["mur"] = ["soleils/enduit.png", Color(1.0, 0.86, 0.66), 2.5]
					p["bas"] = ["soleils/brique.png", Color(0.9, 0.78, 0.66), 1.4]
					p["plafond"] = ["pirates/palmes.png", Color(0.75, 0.68, 0.52), 2.0]
				"pretresse":
					p["mur"] = ["soleils/enduit.png", Color(1.04, 1.02, 0.96), 2.5]
					p["plafond"] = ["beau171/ciel_nout.png", Color(1, 1, 1), 2.0]
					p["sans_poutres"] = true
				"maison_vie":
					p["mur"] = ["soleils/enduit.png", Color(1.03, 1.0, 0.94), 2.5]
				"poterie":
					p["sol"] = ["soleils/limon.png", Color(0.86, 0.74, 0.6), 2.0]
					p["mur"] = ["soleils/brique.png", Color(0.95, 0.85, 0.75), 2.0]
					p["bas"] = ["soleils/brique.png", Color(0.7, 0.6, 0.52), 1.4]
					p["plafond"] = ["pirates/palmes.png", Color(0.72, 0.65, 0.5), 2.0]
				"naos":
					p["sol"] = ["soleils/dalles_soleil.png", Color(0.95, 0.86, 0.68), 2.0]
					p["mur"] = ["soleils/gres.png", Color(0.95, 0.85, 0.7), 2.5]
					p["plafond"] = ["beau171/ciel_nout.png", Color(1, 1, 1), 2.0]
					p["fenetre"] = "aucune"
					p["sans_poutres"] = true
				"temple_vallee":
					p["sol"] = ["soleils/calcaire.png", Color(1.05, 1.03, 1.0), 2.5]
					p["mur"] = ["soleils/gres.png", Color(0.82, 0.55, 0.5), 3.0]
					p["bas"] = ["soleils/hieroglyphes.png", Color(0.95, 0.85, 0.8), 1.4]
					p["plafond"] = ["beau171/ciel_nout.png", Color(1, 1, 1), 2.0]
					p["fenetre"] = "aucune"
					p["sans_poutres"] = true
		"maya":
			p = {"sol": ["soleils/pierre_maya.png", Color(0.95, 0.95, 0.9), 2.0], "mur": ["soleils/enduit.png", Color(0.98, 0.95, 0.88), 2.5],
				"bas": ["soleils/glyphes_maya.png", Color(1, 1, 1), 1.2], "plafond": ["soleils/pierre_maya.png", Color(0.7, 0.68, 0.62), 2.0],
				"fenetre": "aucune", "sans_poutres": true}
			match met:
				"temple_jaguars", "sanctuaire_cenote":
					p["mur"] = ["soleils/stuc_rouge.png", Color(1.0, 0.92, 0.88), 2.5]
					p["bas"] = ["soleils/pierre_maya.png", Color(0.75, 0.72, 0.66), 1.4]
					if met == "sanctuaire_cenote":
						p["mur"] = ["soleils/enduit.png", Color(0.55, 0.78, 0.86), 2.5]
				"observatoire_maya":
					p["plafond"] = ["soleils/pierre_maya.png", Color(0.5, 0.48, 0.45), 2.0]
		"azteque":
			p = {"sol": ["soleils/tezontle.png", Color(0.95, 0.9, 0.88), 2.0], "mur": ["soleils/enduit.png", Color(1.02, 0.98, 0.92), 2.5],
				"bas": ["soleils/frise_azteque.png", Color(1, 1, 1), 1.2], "plafond": ["pirates/palmes.png", Color(0.72, 0.64, 0.5), 2.0], "fenetre": "fente"}
			if met == "palais_azteque":
				p["sol"] = ["soleils/dalles_soleil.png", Color(0.95, 0.88, 0.8), 2.0]
				p["mur"] = ["soleils/stuc_rouge.png", Color(1.0, 0.94, 0.9), 2.5]
				p["plafond"] = ["montjoie/bois_planches.png", Color(0.45, 0.34, 0.26), 2.0]
		"arcanelle":
			p = {"sol": ["arcanelle/dalles_arc.png", Color(0.95, 0.95, 1.0), 2.0], "mur": ["arcanelle/colombage.png", Color(1, 0.97, 0.92), 2.5],
				"bas": ["arcanelle/pierre_arc.png", Color(0.9, 0.9, 0.95), 1.8], "plafond": ["azur/planches.png", Color(0.45, 0.38, 0.4), 2.0]}
			match met:
				"tour_archimage", "observatoire_arc", "tour_pyra":
					p["mur"] = ["arcanelle/pierre_arc.png", Color(0.95, 0.93, 0.98), 2.2]
					p["bas"] = ["arcanelle/pierre_arc.png", Color(0.7, 0.68, 0.76), 1.6]
					p["colombage"] = false
					p["fenetre"] = "aucune"
					p["sans_poutres"] = true
					if met == "observatoire_arc":
						p["plafond"] = ["maisons/chaux_bleu.png", Color(0.1, 0.12, 0.28), 3.0]
						p["sol"] = ["maisons/parquet_chevron.png", Color(0.62, 0.52, 0.48), 2.4]
					elif met == "tour_pyra":
						p["sol"] = ["arcanelle/dalles_arc.png", Color(0.85, 0.66, 0.6), 2.0]
						p["mur"] = ["arcanelle/pierre_arc.png", Color(1.0, 0.86, 0.78), 2.2]
						p["plafond"] = ["azur/planches.png", Color(0.3, 0.22, 0.2), 2.0]
					else:
						p["plafond"] = ["azur/planches.png", Color(0.35, 0.3, 0.36), 2.0]
				"dortoir":
					p["sol"] = ["montjoie/bois_planches.png", Color(0.85, 0.7, 0.56), 1.8]
				"roulotte":
					p["sol"] = ["montjoie/bois_planches.png", Color(0.75, 0.58, 0.44), 1.6]
					p["mur"] = ["beau171/rideau_etoiles.png", Color(1, 1, 1), 1.6]
					p["bas"] = ["maisons/lambris_sombre.png", Color(0.75, 0.6, 0.55), 1.2]
					p["plafond"] = ["beau171/rideau_etoiles.png", Color(0.8, 0.8, 0.85), 1.6]
					p["colombage"] = false
					p["fenetre"] = "aucune"
					p["sans_poutres"] = true
		"pirate":
			p = {"sol": ["pirates/planchesp.png", Color(0.95, 0.88, 0.8), 2.0], "mur": ["pirates/planchesp.png", Color(0.85, 0.75, 0.65), 2.0],
				"bas": ["pirates/rondins.png", Color(0.8, 0.7, 0.6), 2.0], "plafond": ["pirates/palmes.png", Color(0.8, 0.75, 0.6), 2.0]}
			match met:
				"receleur":
					p["mur"] = ["pirates/planchesp.png", Color(0.62, 0.52, 0.45), 2.0]
					p["plafond"] = ["pirates/planchesp.png", Color(0.45, 0.38, 0.32), 2.0]
				"cabinet_doc":
					p["mur"] = ["maisons/chaux_bleu.png", Color(0.95, 0.98, 1.0), 3.0]
					p["bas"] = ["maisons/lambris_blanc.png", Color(0.95, 0.95, 0.92), 1.4]
				"residence":
					p["sol"] = ["maisons/parquet_chevron.png", Color(0.85, 0.72, 0.62), 2.4]
					p["mur"] = ["maisons/pp_damas_bordeaux.png", Color(1, 0.95, 0.92), 1.6]
					p["bas"] = ["maisons/lambris_sombre.png", Color(0.9, 0.82, 0.78), 1.4]
					p["plafond"] = ["montjoie/bois_planches.png", Color(0.5, 0.38, 0.3), 2.0]
				"tour_lunette":
					p["mur"] = ["pirates/pierrefort.png", Color(0.92, 0.88, 0.82), 2.2]
					p["bas"] = ["pirates/pierrefort.png", Color(0.62, 0.58, 0.54), 1.6]
					p["plafond"] = ["pirates/planchesp.png", Color(0.5, 0.42, 0.36), 2.0]
					p["fenetre"] = "aucune"
					p["sans_poutres"] = true
	return p


# =================================================================== construire

static func build(M) -> void:
	match str(M.cur.get("metier", "")):
		"fournil":
			_fournil(M)
		"pretresse":
			_pretresse(M)
		"maison_vie":
			_maison_vie(M)
		"poterie":
			_poterie(M)
		"naos":
			_naos(M)
		"temple_vallee":
			_temple_vallee(M)
		"palais_maya":
			_palais_maya(M)
		"temple_jaguars":
			_temple_jaguars(M)
		"observatoire_maya":
			_observatoire_maya(M)
		"sanctuaire_cenote":
			_sanctuaire_cenote(M)
		"calmecac":
			_calmecac(M)
		"palais_azteque":
			_palais_azteque(M)
		"tour_archimage":
			_tour_archimage(M)
		"dortoir":
			_dortoir(M)
		"observatoire_arc":
			_observatoire_arc(M)
		"alambic":
			_alambic(M)
		"roulotte":
			_roulotte(M)
		"tour_pyra":
			_tour_pyra(M)
		"receleur":
			_receleur(M)
		"cabinet_doc":
			_cabinet_doc(M)
		"residence":
			_residence(M)
		"tour_lunette":
			_tour_lunette(M)


# =================================================================== les petites aides

## Une matière des Trois Soleils (soleils_mats_v69 : « gres69 », « calc69_dore », « argile69_rouge »…).
static func _m(R, key: String) -> String:
	if R.mat(key) == null:
		var m: Material = SM.make(key)
		if m == null:
			return "pierre"
		R._put(key, m)
	return key


## Une fresque peinte à même le mur (x, y, z, yaw comme un tableau) ; bord : une bande en haut et en bas.
static func _fresque(M, path: String, x: float, y: float, z: float, yaw: float, w: float, h: float, bord: String = "", alpha: int = 0) -> void:
	var R = M.R
	if not ResourceLoader.exists("res://assets/textures/" + path):
		return
	var key: String = B._img(R, "fr171_" + path.get_file().get_basename(), path, alpha)
	R.mark_wall(x, y, z, w * 0.5 + 0.1)
	var xf: Transform3D = R.L(x, y, z, yaw)
	R.kit.quad(xf * Transform3D(Basis(Vector3.UP, PI), Vector3(0, 0, 0.02)), w, h, key)
	if bord != "":
		for s in [-1.0, 1.0]:
			R.kit.box(xf * B.T3(0, s * (h * 0.5 + 0.04), 0.025), Vector3(w + 0.12, 0.08, 0.035), bord, 1.0)


## Une pièce ronde (une tour) : un mur rond dans la pièce carrée, ouvert devant la porte ; renvoie le
## rayon. gap : la moitié de l'ouverture (en degrés, autour de la porte).
static func _rond(M, gap: float = 24.0, n: int = 28) -> float:
	var R = M.R
	var k = R.kit
	var r: float = minf(R.W, R.D) * 0.5 - 0.04
	var segw: float = 2.0 * (r + 0.14) * tan(PI / n) + 0.04
	var tm: float = float((R.pal["mur"] as Array)[2])
	for i in range(n):
		var a: float = TAU * (i + 0.5) / n
		var ad: float = rad_to_deg(a)
		if absf(wrapf(ad, -180.0, 180.0)) < gap:
			continue
		var xf: Transform3D = R.L(sin(a) * (r + 0.14), 0, cos(a) * (r + 0.14), ad)
		k.box(xf * B.T3(0, R.H * 0.5, 0), Vector3(segw, R.H, 0.28), "mur", tm)
		k.box(xf * B.T3(0, 0.3, -0.16), Vector3(segw, 0.6, 0.05), "bas", 1.2)
		k.col_box(xf * B.T3(0, R.H * 0.5, 0), Vector3(segw, R.H + 0.2, 0.32))
	# les deux piédroits de l'ouverture, la corniche en haut
	for s in [-1.0, 1.0]:
		var a2: float = deg_to_rad(s * gap)
		k.box(R.L(sin(a2) * (r + 0.05), R.H * 0.5, cos(a2) * (r + 0.05), rad_to_deg(a2)), Vector3(0.36, R.H, 0.45), "bas", 1.2)
	k.ring(R.L(0, R.H - 0.22, 0), r - 0.16, r + 0.02, 0.22, "bas", n)
	return r


## Un rai de lumière qui tombe d'une fente du plafond (x, z : là où il touche le sol).
static func _rayon(M, x: float, z: float, w: float = 0.6, pente: float = 0.25) -> void:
	var R = M.R
	var key: String = "rayon171"
	if R.mat(key) == null:
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		m.albedo_color = Color(1.0, 0.85, 0.55, 0.13)
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		R._put(key, m)
	var h: float = R.H - 0.05
	R.kit.box(R.L(x, h * 0.5, z - h * 0.5 * pente) * Transform3D(Basis(Vector3.RIGHT, atan(pente)), Vector3.ZERO), Vector3(w, h / cos(atan(pente)), w * 0.6), key, 1.0)


## Une jarre de terre (amphore à fond rond posée sur sa base).
static func _jarre(R, x: float, z: float, s: float = 1.0, key: String = "argile69", y: float = 0.0) -> void:
	var k = R.kit
	var m: String = _m(R, key)
	var xf: Transform3D = R.L(x, y, z)
	k.cyl(xf, 0.09 * s, 0.2 * s, 0.18 * s, m, 14)
	k.cyl(xf * B.T3(0, 0.18 * s, 0), 0.2 * s, 0.21 * s, 0.22 * s, m, 14)
	k.cyl(xf * B.T3(0, 0.4 * s, 0), 0.21 * s, 0.09 * s, 0.16 * s, m, 14)
	k.cyl(xf * B.T3(0, 0.56 * s, 0), 0.075 * s, 0.085 * s, 0.1 * s, m, 12)
	k.ring(xf * B.T3(0, 0.64 * s, 0), 0.065 * s, 0.1 * s, 0.03 * s, m, 12)
	if y < 0.05:
		k.col_box(xf * B.T3(0, 0.32 * s, 0), Vector3(0.36, 0.64, 0.36) * s)
		R.reserve(x, z, 0.5 * s, 0.5 * s)


## Une natte de roseaux posée au sol.
static func _natte(R, x: float, z: float, yaw: float, w: float, d: float) -> void:
	R.kit.box(R.L(x, 0.006, z, yaw), Vector3(w, 0.012, d), B._tex(R, "natte171", "beau171/natte.png", Color(1, 1, 1), 0.95), 0.8, 4 | 1 | 2 | 16 | 32)


## Un brasero de pierre (ou de terre) et son feu ; s : la taille.
static func _brasero(M, x: float, z: float, s: float = 1.0, key: String = "calc69", y0: float = 0.0) -> void:
	var R = M.R
	var k = R.kit
	var m: String = _m(R, key)
	k.cyl(R.L(x, y0, z), 0.18 * s, 0.14 * s, 0.45 * s, m, 12)
	k.cyl(R.L(x, y0 + 0.45 * s, z), 0.14 * s, 0.32 * s, 0.22 * s, m, 16)
	k.cyl(R.L(x, y0 + 0.62 * s, z), 0.27 * s, 0.27 * s, 0.03, B._c(R, "braises171", Color(1.0, 0.42, 0.12), 0.6, 0.0, 2.2), 14)
	R.fire(R.P(x, y0 + 0.7 * s, z), 0.55 * s)
	if y0 < 0.05:
		k.col_box(R.L(x, y0 + 0.35 * s, z), Vector3(0.6, 0.7, 0.6) * s)
		R.reserve(x, z, 0.8 * s, 0.8 * s)


## Une table d'offrandes basse (pains, fruits, une fleur de lotus, une cruche).
static func _offrandes(M, x: float, z: float, yaw: float, w: float = 1.0) -> void:
	var R = M.R
	var k = R.kit
	var xf: Transform3D = R.L(x, 0, z, yaw)
	var calc: String = _m(R, "calc69")
	k.box(xf * B.T3(0, 0.3, 0), Vector3(w, 0.6, 0.5), calc, 1.0)
	k.box(xf * B.T3(0, 0.62, 0), Vector3(w + 0.1, 0.05, 0.6), calc, 1.0)
	B._c(R, "croute", Color(0.72, 0.45, 0.2), 0.85)
	for i in range(3):
		k.cyl(xf * B.T3(-w * 0.35 + i * 0.12, 0.645, -0.08), 0.045, 0.0, 0.2, "croute", 10)
	k.cyl(xf * B.T3(w * 0.05, 0.645, 0.08), 0.1, 0.09, 0.04, "croute", 12)
	for j in range(4):
		Sud._boule(M.room, R.mat(B._c(R, "figue171", Color(0.42, 0.2, 0.32), 0.6)), xf * Vector3(w * 0.22 + 0.06 * (j % 2), 0.68, -0.12 + 0.06 * j), 0.035)
	var cr: Transform3D = xf * B.T3(w * 0.38, 0.645, 0.1)
	k.cyl(cr, 0.05, 0.07, 0.1, _m(R, "argile69_rouge"), 10)
	k.cyl(cr * B.T3(0, 0.1, 0), 0.07, 0.03, 0.06, _m(R, "argile69_rouge"), 10)
	_lotus(R, xf * B.T3(-w * 0.1, 0.645, 0.12))
	k.col_box(xf * B.T3(0, 0.33, 0), Vector3(w, 0.66, 0.5))
	R.reserve(x, z, w + 0.2, 0.8)


## Une fleur de lotus bleu (sa tige posée, la corolle ouverte).
static func _lotus(R, xf: Transform3D) -> void:
	var k = R.kit
	var tige: String = B._c(R, "tige_lotus", Color(0.25, 0.42, 0.2), 0.8)
	var pet: String = B._c(R, "lotus_bleu", Color(0.42, 0.55, 0.92), 0.55)
	k.cyl(xf * Transform3D(Basis(Vector3.BACK, PI * 0.5 - 0.1), Vector3(0.1, 0.012, 0)), 0.008, 0.008, 0.28, tige, 5)
	for p in range(6):
		var a: float = TAU * p / 6.0
		k.box(xf * Transform3D(Basis(Vector3.UP, a) * Basis(Vector3.RIGHT, 0.6), Vector3(cos(a) * 0.02, 0.04, sin(a) * 0.02)), Vector3(0.025, 0.07, 0.006), pet, 1.0)
	k.cyl(xf * B.T3(0, 0.02, 0), 0.015, 0.012, 0.025, B._c(R, "coeur_lotus", Color(0.95, 0.8, 0.3), 0.6), 8)


## Une colonne papyriforme peinte (le fût, les bandes de couleur, le chapiteau, l'abaque).
static func _colonne(M, x: float, z: float, h: float, r: float, key: String = "calc69") -> void:
	var R = M.R
	var k = R.kit
	var m: String = _m(R, key)
	k.cyl(R.L(x, 0, z), r * 1.3, r * 1.25, 0.16, m, 18)
	k.cyl(R.L(x, 0.16, z), r * 0.82, r, 0.28, m, 16)
	var top: float = h * 0.7
	k.cyl(R.L(x, 0.44, z), r, r * 0.88, top - 0.44, m, 16)
	var cols: Array = [Color(0.2, 0.32, 0.62), Color(0.72, 0.2, 0.12), Color(0.2, 0.48, 0.32)]
	for b in range(3):
		k.cyl(R.L(x, top - 0.36 + b * 0.1, z), r * 0.895, r * 0.89, 0.06, B._c(R, "bande171_%d" % b, cols[b], 0.7), 16, false)
	k.cyl(R.L(x, 0.6, z), r * 0.99, r * 0.97, top * 0.35, _m(R, "hiero69"), 16, false)
	k.cyl(R.L(x, top, z), r * 0.88, r * 1.55, h - 0.24 - top, m, 18)
	k.cyl(R.L(x, top + 0.04, z), r * 0.9, r * 1.0, 0.18, B._c(R, "bande171_0", cols[0], 0.7), 18, false)
	k.box(R.L(x, h - 0.12, z), Vector3(r * 2.4, 0.24, r * 2.4), m, 1.0)
	k.col_box(R.L(x, h * 0.5, z), Vector3(r * 2.0, h, r * 2.0))
	R.reserve(x, z, r * 2.8, r * 2.8)


## Une statue assise (un dieu, un pharaon) : le socle, le trône, le corps, la coiffe ; dieu : « re »
## (la tête de faucon et le disque solaire), « roi » (le némès rayé), « thot » (l'ibis).
static func _statue(M, x: float, z: float, yaw: float, s: float, dieu: String = "roi", key: String = "statue69", y0: float = 0.0) -> void:
	var R = M.R
	var k = R.kit
	var m: String = _m(R, key)
	var orr: String = _m(R, "or69")
	var xf: Transform3D = R.L(x, y0, z, yaw)
	k.box(xf * B.T3(0, 0.2 * s, 0), Vector3(0.8, 0.4, 1.15) * s, m, 1.0)
	k.box(xf * B.T3(0, 0.65 * s, -0.12 * s), Vector3(0.66, 0.5, 0.7) * s, m, 1.0)
	k.box(xf * B.T3(0, 1.0 * s, -0.42 * s), Vector3(0.66, 1.2, 0.12) * s, m, 1.0)
	# les jambes, les pieds
	k.box(xf * B.T3(0, 0.95 * s, 0.05 * s), Vector3(0.44, 0.16, 0.46) * s, m, 1.0)
	k.box(xf * B.T3(0, 0.66 * s, 0.25 * s), Vector3(0.42, 0.5, 0.14) * s, m, 1.0)
	k.box(xf * B.T3(0, 0.43 * s, 0.33 * s), Vector3(0.44, 0.06, 0.26) * s, m, 1.0)
	# le torse, les bras posés sur les cuisses
	k.box(xf * B.T3(0, 1.32 * s, -0.17 * s), Vector3(0.42, 0.62, 0.24) * s, m, 1.0)
	k.box(xf * B.T3(0, 1.52 * s, -0.17 * s), Vector3(0.56, 0.16, 0.24) * s, m, 1.0)
	for sx in [-1.0, 1.0]:
		k.box(xf * B.T3(sx * 0.26 * s, 1.27 * s, -0.12 * s), Vector3(0.1, 0.42, 0.12) * s, m, 1.0)
		k.box(xf * B.T3(sx * 0.17 * s, 1.07 * s, 0.12 * s), Vector3(0.1, 0.08, 0.36) * s, m, 1.0)
	# le pagne d'or, le collier
	k.box(xf * B.T3(0, 1.08 * s, -0.04 * s), Vector3(0.46, 0.08, 0.3) * s, orr, 1.0)
	k.cyl(xf * B.T3(0, 1.56 * s, -0.17 * s), 0.17 * s, 0.13 * s, 0.05 * s, _m(R, "lapis69"), 14)
	# la tête et sa coiffe
	var hx: Transform3D = xf * B.T3(0, 1.74 * s, -0.17 * s)
	match dieu:
		"re":
			k.box(hx, Vector3(0.22, 0.24, 0.24) * s, m, 1.0)
			k.cyl(hx * Transform3D(Basis(Vector3.RIGHT, PI * 0.55), Vector3(0, -0.02 * s, 0.1 * s)), 0.06 * s, 0.0, 0.14 * s, orr, 8)
			for sx2 in [-1.0, 1.0]:
				k.box(hx * B.T3(sx2 * 0.1 * s, -0.1 * s, 0.0), Vector3(0.06, 0.3, 0.2) * s, _m(R, "lapis69"), 1.0)
			k.cyl(hx * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0.3 * s, -0.04 * s)), 0.2 * s, 0.2 * s, 0.05 * s, _m(R, "or69"), 24)
			k.cyl(hx * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0.3 * s, 0.015 * s)), 0.17 * s, 0.17 * s, 0.01 * s, B._c(R, "disque_re", Color(0.95, 0.3, 0.1), 0.4, 0.2, 1.2), 24)
		"thot":
			k.box(hx, Vector3(0.2, 0.22, 0.24) * s, m, 1.0)
			k.cyl(hx * Transform3D(Basis(Vector3.RIGHT, PI * 0.62), Vector3(0, 0.0, 0.1 * s)), 0.035 * s, 0.008 * s, 0.34 * s, _m(R, "obsid69"), 8)
			for sx3 in [-1.0, 1.0]:
				k.box(hx * B.T3(sx3 * 0.1 * s, -0.1 * s, 0.0), Vector3(0.06, 0.3, 0.2) * s, _m(R, "lapis69"), 1.0)
		_:
			k.box(hx, Vector3(0.2, 0.25, 0.22) * s, m, 1.0)
			k.box(hx * B.T3(0, 0.07 * s, -0.02 * s), Vector3(0.3, 0.16, 0.28) * s, orr, 1.0)
			for sx4 in [-1.0, 1.0]:
				k.box(hx * B.T3(sx4 * 0.13 * s, -0.14 * s, 0.03 * s), Vector3(0.07, 0.3, 0.12) * s, orr, 1.0)
				for b in range(4):
					k.box(hx * B.T3(sx4 * 0.13 * s, -0.25 * s + b * 0.075 * s, 0.092 * s), Vector3(0.072, 0.025, 0.004) * s, _m(R, "lapis69"), 1.0)
			k.box(hx * B.T3(0, -0.15 * s, 0.1 * s), Vector3(0.05, 0.1, 0.03) * s, m, 1.0)
			k.cyl(hx * Transform3D(Basis(Vector3.RIGHT, -0.3), Vector3(0, 0.16 * s, 0.12 * s)), 0.02 * s, 0.015 * s, 0.07 * s, orr, 6)
	if y0 < 0.05:
		k.col_box(xf * B.T3(0, 0.95 * s, 0), Vector3(0.8, 1.9, 1.15) * s)
		R.reserve(x, z, 1.1 * s, 1.4 * s)


# =================================================================== Per-Hâpy : le fournil de Mérit

## Un four en coupole (la bouche rougeoie, une petite flamme lèche le bord).
static func _four(M, x: float, z: float) -> void:
	var R = M.R
	var k = R.kit
	var ar: String = _m(R, "argile69_terre")
	k.cyl(R.L(x, 0, z), 0.64, 0.62, 0.5, ar, 18)
	k.cyl(R.L(x, 0.5, z), 0.62, 0.4, 0.45, ar, 18)
	k.cyl(R.L(x, 0.95, z), 0.4, 0.12, 0.3, ar, 18)
	k.cyl(R.L(x, 1.25, z), 0.12, 0.1, 0.12, ar, 10)
	k.quad(R.L(x, 0.42, z + 0.625) * Transform3D(Basis(Vector3.UP, PI), Vector3.ZERO), 0.46, 0.42, "noir")
	k.box(R.L(x, 0.27, z + 0.6), Vector3(0.38, 0.1, 0.06), B._c(R, "braises171", Color(1.0, 0.42, 0.12), 0.6, 0.0, 2.2), 1.0)
	R.fire(R.P(x, 0.28, z + 0.66), 0.28)
	k.col_box(R.L(x, 0.65, z), Vector3(1.2, 1.3, 1.2))
	R.reserve(x, z, 1.4, 1.4)


## Une corbeille plate et ses pains (les pains en cône, les galettes rondes).
static func _corbeille(M, x: float, y: float, z: float, i: int) -> void:
	var R = M.R
	var k = R.kit
	var t: String = B._toile(R)
	B._c(R, "croute", Color(0.72, 0.45, 0.2), 0.85)
	B._c(R, "croute_doree", Color(0.86, 0.6, 0.28), 0.8)
	k.cyl(R.L(x, y, z), 0.26, 0.32, 0.1, t, 16)
	if i % 2 == 0:
		for j in range(5):
			var a: float = TAU * j / 5.0
			k.cyl(R.L(x + cos(a) * 0.15, y + 0.06, z + sin(a) * 0.15), 0.055, 0.0, 0.2, "croute", 10)
		k.cyl(R.L(x, y + 0.06, z), 0.06, 0.0, 0.24, "croute_doree", 10)
	else:
		for j2 in range(4):
			k.cyl(R.L(x + 0.02 * (j2 % 2), y + 0.06 + j2 * 0.035, z), 0.2 - j2 * 0.02, 0.19 - j2 * 0.02, 0.035, "croute_doree" if j2 % 2 == 0 else "croute", 16)


## La meule dormante (une pierre en pente, la molette, un petit tas de farine).
static func _meule(M, x: float, z: float) -> void:
	var R = M.R
	var k = R.kit
	k.box(R.L(x, 0.12, z), Vector3(0.6, 0.24, 0.95), _m(R, "brique69_ocre"), 1.0)
	k.box(R.L(x, 0.3, z) * Transform3D(Basis(Vector3.RIGHT, 0.14), Vector3.ZERO), Vector3(0.45, 0.1, 0.85), _m(R, "roche69_sombre"), 1.0)
	k.box(R.L(x, 0.4, z + 0.05), Vector3(0.32, 0.08, 0.16), "pierre_lisse", 1.0)
	k.cyl(R.L(x, 0.24, z - 0.5), 0.14, 0.02, 0.08, B._c(R, "farine171", Color(0.95, 0.92, 0.85), 0.95), 12)
	k.col_box(R.L(x, 0.2, z), Vector3(0.6, 0.4, 0.95))
	R.reserve(x, z, 0.8, 1.2)


static func _fournil(M) -> void:
	var R = M.R
	var k = R.kit
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var brique: String = _m(R, "brique69_ocre")
	# les deux fours en coupole, contre le mur du fond ; la pelle à enfourner
	for i in range(2):
		_four(M, -hw + 1.2 + i * 1.6, -hd + 0.95)
	k.box(R.L(-hw + 2.0, 1.1, -hd + 0.1) * Transform3D(Basis(Vector3.BACK, 0.25), Vector3.ZERO), Vector3(0.08, 2.0, 0.04), "bois_sombre", 1.0)
	k.box(R.L(-hw + 2.24, 0.15, -hd + 0.12), Vector3(0.3, 0.3, 0.02), "bois", 1.0)
	# la banquette de briques et ses corbeilles de pains (à droite)
	k.box(R.L(hw - 0.45, 0.35, -0.3), Vector3(0.7, 0.7, 3.8), brique, 1.5)
	k.col_box(R.L(hw - 0.45, 0.35, -0.3), Vector3(0.7, 0.7, 3.8))
	R.reserve(hw - 0.45, -0.3, 0.9, 4.0)
	for j in range(4):
		_corbeille(M, hw - 0.45, 0.7, -1.75 + j * 0.95, j)
	# les jarres de grain (à gauche), les sacs de blé
	for j2 in range(3):
		_jarre(R, -hw + 0.42, -0.6 + j2 * 0.62, 1.1, "argile69_terre")
	B._sac(R, -hw + 1.15, 0.3, Color(0.86, 0.72, 0.42), 0.9)
	B._sac(R, -hw + 1.25, 1.0, Color(0.9, 0.8, 0.5), 0.8)
	# la meule, et la petite qui moud le grain
	var qx: float = -hw + 1.3
	var qz: float = hd - 1.0
	_meule(M, qx, qz)
	var aide: Node = M.person("fille", qx + 0.62, qz, -90.0, "moudre", "Petite Taouret")
	aide.lines = ["Je mouds, je mouds… le blé devient farine, la farine devient pain !", "Mérit dit que j'ai les meilleurs bras du quartier."]
	# le comptoir de briques : les pains du jour, une corbeille de dattes, un pot de miel
	var zc: float = -0.35
	var cx: Transform3D = B._comptoir(M, 0.7, zc, 2.6, 0.0, false, 0.95, brique, "bois")
	B._c(R, "croute", Color(0.72, 0.45, 0.2), 0.85)
	for p in range(5):
		k.cyl(cx * B.T3(-1.0 + p * 0.16, 0.98, 0.05 + 0.08 * float(p % 2)), 0.055, 0.0, 0.22, "croute", 10)
	k.cyl(cx * B.T3(0.1, 0.98, 0.05), 0.2, 0.24, 0.08, B._toile(R), 14)
	for d in range(7):
		Sud._boule(M.room, R.mat(B._c(R, "datte171", Color(0.45, 0.22, 0.1), 0.45)), cx * Vector3(0.02 + 0.06 * (d % 4), 1.08, 0.0 + 0.06 * (d / 4)), 0.035, Vector3(1.0, 0.7, 0.7))
	k.cyl(cx * B.T3(0.75, 0.98, 0.05), 0.09, 0.1, 0.16, _m(R, "argile69_rouge"), 12)
	k.cyl(cx * B.T3(0.75, 1.14, 0.05), 0.1, 0.06, 0.03, B._c(R, "miel171", Color(0.9, 0.6, 0.1), 0.3, 0.0, 0.2), 12)
	# au mur : le Nil et ses barques, une étagère de pots
	_fresque(M, "soleils/fresque_nil.png", -hw + 0.02, 2.25, -0.2, 90.0, 2.6, 1.15, brique)
	B._rayons(M, hw - 0.22, hd - 1.15, -90.0, 1.1, 1.7, 3, "pots", 2)
	_lampe_huile(M, 0.25, 0.98, zc + 0.12)
	var lignes: Array = ["Le pain se lève avec le soleil… et moi un peu avant lui.", "Goûte ce pain au miel : c'est la recette de ma grand-mère.", "Attention, le four est chaud ! Chaud comme Rê à midi."]
	B._marchand(M, 0.7, zc - 0.55, 0.0, "comptoir", "femme", "Mérit", lignes, {"bonjour": "Bienvenue au fournil ! Du pain tout chaud, des dattes, du miel.", "vend": {"pain_egypte": 3, "dattes": 2, "miel": 6}, "achete": {"graines": 1},
		"infos": ["On cuit le pain dans des moules de terre, comme des cônes. Le dessus devient tout doré.", "Le miel vient des ruches du temple. Les abeilles sont les larmes de Rê, dit-on."]})
	M.ctx["bonjour170"] = ["Entre ! Ça sent bon, hein ?", "Bonjour ! La première fournée vient de sortir."]
	M.ctx["entree"] = "Le fournil de Mérit : les deux fours en coupole qui rougeoient, la meule à grain, les corbeilles de pains en cône, l'odeur du miel."


## Une petite lampe à huile (une coupelle de terre et sa flamme), posée sur un meuble (xf : ce meuble).
static func _lampe_huile(M, x: float, y: float, z: float) -> void:
	var R = M.R
	var k = R.kit
	var at: Transform3D = R.L(x, y, z)
	k.cyl(at, 0.04, 0.07, 0.035, _m(R, "argile69_rouge"), 10)
	k.cyl(at * B.T3(0.06, 0.03, 0), 0.006, 0.0, 0.03, "flamme", 5, false)
	B._lampe(M, x + 0.06, y + 0.12, z, Color(1.0, 0.75, 0.4), 0.5, 2.6)


# =================================================================== Per-Hâpy : la maison de Néferet

## Un petit naos de bois (les portes dorées ouvertes, le dieu dedans) sur son socle ; s : la taille.
static func _tabernacle(M, x: float, z: float, s: float, socle: float, dieu: String) -> void:
	var R = M.R
	var k = R.kit
	var orr: String = _m(R, "or69")
	var fond: String = _m(R, "lapis69")
	k.box(R.L(x, socle * 0.5, z), Vector3(1.5 * s, socle, 1.0 * s), _m(R, "calc69"), 1.0)
	k.col_box(R.L(x, socle * 0.5, z), Vector3(1.5 * s, socle, 1.0 * s))
	var w: float = 0.95 * s
	var h: float = 1.2 * s
	var d: float = 0.62 * s
	var y0: float = socle
	k.box(R.L(x, y0 + h * 0.5, z - d * 0.5), Vector3(w, h, 0.04), fond, 1.0)
	for sx in [-1.0, 1.0]:
		k.box(R.L(x + sx * w * 0.5, y0 + h * 0.5, z), Vector3(0.05, h, d), "bois_sombre", 1.0)
		# les portes ouvertes, dorées
		var hinge := Vector3(x + sx * w * 0.5, 0, z + d * 0.5)
		var dir := Vector3(sx * cos(deg_to_rad(65.0)), 0, sin(deg_to_rad(65.0)))
		var c: Vector3 = hinge + dir * w * 0.25
		k.box(R.L(c.x, y0 + h * 0.48, c.z, rad_to_deg(atan2(-dir.z, dir.x))), Vector3(w * 0.5, h * 0.92, 0.03), orr, 1.0)
	k.box(R.L(x, y0 + h + 0.06 * s, z), Vector3(w + 0.16 * s, 0.12 * s, d + 0.12 * s), orr, 1.0)
	k.box(R.L(x, y0 + h + 0.16 * s, z - 0.02), Vector3(w + 0.08 * s, 0.08 * s, d + 0.04 * s), "bois_sombre", 1.0)
	_statue(M, x, z - d * 0.12, 0.0, 0.52 * s, dieu, "or69", y0)
	B._lampe(M, x, y0 + h * 0.75, z + d * 0.6, Color(1.0, 0.82, 0.45), 0.7, 2.4)


static func _pretresse(M) -> void:
	var R = M.R
	var k = R.kit
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var orr: String = _m(R, "or69")
	# le petit naos de la maison, le disque de Rê au-dessus, la table d'offrandes et ses lampes
	_tabernacle(M, 0.0, -hd + 0.55, 1.0, 0.85, "re")
	_fresque(M, "soleils/sym_soleil.png", 0.0, 2.95, -hd + 0.02, 0.0, 0.7, 0.7, "", 1)
	_offrandes(M, 0.0, -hd + 1.55, 0.0, 1.1)
	for sx in [-1.0, 1.0]:
		k.cyl(R.L(sx * 0.95, 0, -hd + 1.0), 0.08, 0.06, 1.1, orr, 10)
		k.cyl(R.L(sx * 0.95, 1.1, -hd + 1.0), 0.06, 0.13, 0.08, orr, 12)
		k.cyl(R.L(sx * 0.95, 1.18, -hd + 1.0), 0.008, 0.0, 0.05, "flamme", 5, false)
		B._lampe(M, sx * 0.95, 1.35, -hd + 1.0, Color(1.0, 0.75, 0.4), 0.45, 2.2)
	# le lit (les pieds en pattes de lion, l'appui-tête), contre le mur de droite
	_lit_egypte(M, hw - 0.62, -0.5)
	R.chat(hw - 0.62, 0.15, 160.0, Color(0.78, 0.62, 0.4), true, 0.56)
	# le coin du jeu de senet : une chaise, une table, le plateau
	R.chaise(-hw + 1.55, 0.9, 90.0, "rouge")
	R.table(-hw + 0.75, 0.9, 90.0, 0.9, 0.6, 0.62)
	var sen: String = B._tex(R, "senet171", "maisons/damier_noir_blanc.png", Color(0.95, 0.88, 0.7), 0.6)
	k.box(R.L(-hw + 0.75, 0.66, 0.9, 90.0), Vector3(0.55, 0.05, 0.2), sen, 0.25)
	for p in range(6):
		k.cyl(R.L(-hw + 0.75 + (0.04 if p % 2 == 0 else -0.04), 0.685, 0.68 + p * 0.09), 0.018, 0.016, 0.04, orr if p < 3 else _m(R, "lapis69"), 8)
	# le bassin aux lotus, le coffre peint, les papyrus en pot
	var bx: float = -hw + 1.0
	var bz: float = -0.9
	k.cyl(R.L(bx, 0, bz), 0.48, 0.5, 0.42, _m(R, "calc69"), 20)
	k.disc(R.L(bx, 0.38, bz), 0.42, _m(R, "eau69"), 20)
	for f in range(3):
		_lotus(R, R.L(bx - 0.15 + f * 0.14, 0.39, bz - 0.1 + 0.1 * float(f % 2)))
	k.col_box(R.L(bx, 0.21, bz), Vector3(1.0, 0.42, 1.0))
	R.reserve(bx, bz, 1.1, 1.1)
	R.coffre_deco(hw - 0.55, hd - 1.15, -90.0)
	R.plante(-hw + 0.45, hd - 0.6, 0.0, 1.1)
	R.plante(hw - 0.45, -hd + 0.45, 0.0, 1.0)
	_fresque(M, "soleils/fresque_barque.png", -hw + 0.02, 2.2, -0.6, 90.0, 2.4, 1.1, orr)
	_fresque(M, "soleils/fresque_nil.png", hw - 0.02, 2.4, -0.4, -90.0, 2.0, 0.9, orr)
	R.tapis(0.0, 0.6, 0.0, 2.2, 1.4)
	var lignes: Array = ["Rê traverse le ciel le jour, et le monde d'en dessous la nuit. Chaque matin, il revient.", "Le lotus se ferme le soir et s'ouvre au soleil. Comme moi.", "Assieds-toi, si tu veux. Le chat ne mord pas. Enfin… rarement."]
	var benir := func() -> void:
		M.main.sfx("cristal_chante")
		M.say("Néferet pose la main sur ton front : « Que Rê éclaire ton chemin, et que ton ombre soit toujours derrière toi. » Tu te sens tout réchauffé.", 6.0)
		M.close_talk()
	B._marchand(M, -1.25, -hd + 1.45, 20.0, "mains_dos", "femme", "Néferet", lignes, {"bonjour": "Sois le bienvenu dans ma maison, voyageur.",
		"services": [{"label": "Recevoir la bénédiction de Rê", "cb": benir}],
		"infos": ["Ce petit naos, c'est la maison de Rê, chez moi. Je lui parle le matin. Il ne répond pas… mais il écoute.", "Le senet ? Un jeu de dés et de pions. Le chat triche : il pousse les pions avec sa patte."]})
	M.ctx["cloche170"] = false
	M.ctx["bonjour170"] = ["Entre, entre. Que la paix de Rê soit sur toi.", "Bienvenue chez moi."]
	M.ctx["entree"] = "La maison de Néferet : le petit naos doré de Rê et ses offrandes, le plafond bleu semé d'étoiles, le bassin aux lotus, et le chat qui dort sur le lit."


## Un lit d'Égypte (le cadre, le matelas de lin, le pied relevé, les pattes de lion, l'appui-tête) :
## le long de z, la tête vers -z.
static func _lit_egypte(M, x: float, z: float) -> void:
	var R = M.R
	var k = R.kit
	var orr: String = _m(R, "or69")
	k.box(R.L(x, 0.42, z), Vector3(0.95, 0.08, 2.0), "bois_sombre", 1.0)
	k.box(R.L(x, 0.5, z), Vector3(0.88, 0.09, 1.94), _m(R, "lin69"), 1.0)
	k.box(R.L(x, 0.62, z + 0.98), Vector3(0.95, 0.42, 0.05), "bois", 1.0)
	k.box(R.L(x, 0.62, z + 0.995), Vector3(0.7, 0.26, 0.012), orr, 1.0)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			k.box(R.L(x + sx * 0.4, 0.2, z + sz * 0.92), Vector3(0.08, 0.4, 0.08), "bois_sombre", 1.0)
			k.box(R.L(x + sx * 0.4, 0.03, z + sz * 0.92 + 0.03), Vector3(0.11, 0.06, 0.15), orr, 1.0)
	k.box(R.L(x, 0.58, z - 0.82), Vector3(0.2, 0.05, 0.1), "bois", 1.0)
	k.box(R.L(x, 0.65, z - 0.82), Vector3(0.05, 0.1, 0.06), "bois", 1.0)
	k.box(R.L(x, 0.71, z - 0.82), Vector3(0.24, 0.04, 0.1), "bois", 1.0)
	k.col_box(R.L(x, 0.3, z), Vector3(0.95, 0.6, 2.0))
	R.reserve(x, z, 1.2, 2.3)


# =================================================================== Per-Hâpy : la Maison de Vie (l'école des scribes)

## Une place d'écolier : le tabouret, la petite table, la feuille de papyrus, la palette et ses godets.
static func _place_scribe(M, x: float, z: float) -> void:
	var R = M.R
	var k = R.kit
	k.box(R.L(x, 0.42, z + 0.75), Vector3(0.4, 0.05, 0.36), "bois", 1.0)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			k.box(R.L(x + sx * 0.16, 0.2, z + 0.75 + sz * 0.14), Vector3(0.04, 0.4, 0.04), "bois_sombre", 1.0)
	k.box(R.L(x, 0.47, z), Vector3(0.62, 0.04, 0.4), "bois", 1.0)
	for sx2 in [-1.0, 1.0]:
		k.box(R.L(x + sx2 * 0.27, 0.23, z), Vector3(0.05, 0.45, 0.36), "bois_sombre", 1.0)
	var pap: String = B._img(R, "pap171", "soleils/papyrus_thot.png")
	k.quad(R.L(x - 0.05, 0.492, z + 0.02) * Transform3D(Basis(Vector3.UP, PI) * Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 0.34, 0.24, pap)
	k.box(R.L(x + 0.2, 0.5, z - 0.02), Vector3(0.06, 0.015, 0.26), "bois_clair", 1.0)
	for g in range(2):
		k.cyl(R.L(x + 0.2, 0.505, z - 0.09 + g * 0.06), 0.012, 0.012, 0.005, "noir" if g == 0 else B._c(R, "ocre_rouge", Color(0.7, 0.18, 0.1), 0.8), 8)
	k.col_box(R.L(x, 0.25, z), Vector3(0.62, 0.5, 0.4))
	R.reserve(x, z + 0.35, 0.8, 1.3)


static func _maison_vie(M) -> void:
	var R = M.R
	var k = R.kit
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	for sx in [-1.0, 1.0]:
		_colonne(M, sx * 4.6, 0.6, R.H, 0.3, "calc69")
	# au fond : le grand papyrus de Thot, les colonnes d'hiéroglyphes, Thot l'ibis dans son coin
	_fresque(M, "soleils/papyrus_thot.png", 0.0, 2.3, -hd + 0.02, 0.0, 2.6, 1.6, "bois_sombre")
	for sx2 in [-1.0, 1.0]:
		_fresque(M, "soleils/hieroglyphes.png", sx2 * 2.35, 2.3, -hd + 0.02, 0.0, 1.4, 1.6, "bois_sombre")
	_statue(M, -hw + 0.85, -hd + 0.85, 40.0, 0.85, "thot", "statue69_sombre")
	# le pupitre du maître
	k.box(R.L(1.1, 0.5, -hd + 1.0), Vector3(0.6, 1.0, 0.45), "bois_sombre", 1.0)
	k.box(R.L(1.1, 1.04, -hd + 1.05) * Transform3D(Basis(Vector3.RIGHT, 0.3), Vector3.ZERO), Vector3(0.66, 0.04, 0.5), "bois", 1.0)
	var pap: String = B._img(R, "pap171", "soleils/papyrus_thot.png")
	k.quad(R.L(1.1, 1.08, -hd + 1.05) * Transform3D(Basis(Vector3.RIGHT, 0.3) * Basis(Vector3.UP, PI) * Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 0.5, 0.36, pap)
	k.col_box(R.L(1.1, 0.5, -hd + 1.0), Vector3(0.6, 1.0, 0.45))
	R.reserve(1.1, -hd + 1.0, 0.8, 0.7)
	# les rouleaux dans leurs niches (à gauche), la jarre d'eau et sa coupe (à droite)
	_niches(M, -hw + 0.24, 0.2, 90.0, 3.0, 2.0)
	_fresque(M, "soleils/fresque_pesee.png", hw - 0.02, 2.3, -0.4, -90.0, 2.8, 1.3, "bois_sombre")
	_jarre(R, hw - 0.5, 1.6, 1.3, "argile69_rouge")
	k.cyl(R.L(hw - 0.5, 0.0, 2.35), 0.2, 0.22, 0.5, _m(R, "calc69"), 12)
	k.cyl(R.L(hw - 0.5, 0.5, 2.35), 0.06, 0.08, 0.06, _m(R, "argile69"), 10)
	# les petits scribes
	var gens: Array = [["garcon", -2.6, -0.75], ["fille", -0.9, -0.75], ["garcon", 0.9, -0.75], ["fille", 2.6, -0.75], ["fille", -2.6, 0.85], ["garcon", 2.6, 0.85]]
	var mots: Array = [["Le hibou, c'est le son « m ». La chouette ? Euh… aussi « m » ?"], ["J'ai dessiné un canard. C'est le mot « fils ». Ou peut-être que c'est juste un canard."], ["Maître, j'ai renversé l'encre rouge. Encore."],
		["Quand je serai grande, j'écrirai les livres du temple !"], ["Chut ! Le maître regarde."], ["Un roseau, une palette, deux godets : noir et rouge. Le rouge, c'est pour les titres."]]
	for i in range(gens.size()):
		var g: Array = gens[i]
		_place_scribe(M, float(g[1]), float(g[2]))
		var p: Node = M.person(str(g[0]), float(g[1]), float(g[2]) + 0.75, 180.0, "lire")
		p.lines = mots[i]
	var lecon := func() -> void:
		var st: Dictionary = M.state()
		var n: int = int(st.get("glyphe171", 0))
		st["glyphe171"] = n + 1
		var g2: Array = ["Le soleil, un rond avec un point au milieu : « rê ». Facile, non ?", "La bouche se dit « r ». Le pain, un petit dôme : « t ». Et voilà : tu sais écrire « r-t » !",
			"Le scarabée, c'est « khéper » : devenir. Le soleil du matin roule comme une boule que pousse le scarabée.", "L'œil d'Horus protège celui qui le porte. On le dessine sur les barques, pour qu'elles voient la route.",
			"Un nom de roi s'écrit dans un cartouche, une corde nouée tout autour : comme ça, personne ne l'efface."]
		M.close_talk()
		M.say("Amenemhat trace un signe sur ton ostracon : %s" % str(g2[n % g2.size()]), 7.0)
	B._marchand(M, 0.0, -hd + 1.25, 0.0, "enseigner", "vieux", "Amenemhat", ["Un scribe qui sait écrire n'a jamais faim. Il a juste mal au poignet.", "Le papyrus est patient. L'élève, beaucoup moins.", "Silence, mes petits roseaux ! On écoute."],
		{"bonjour": "Bienvenue à la Maison de Vie. Ici, on apprend les signes sacrés.", "services": [{"label": "Apprendre un hiéroglyphe", "cb": lecon}],
		"infos": ["Thot, le dieu à tête d'ibis, a inventé l'écriture. Il la garde jalousement. Il me la prête un peu."]})
	M.act(R.P(0.0, 0, -hd + 2.2), "E : regarder le grand papyrus", func(): M.say("Le papyrus de Thot : des colonnes de signes, des oiseaux, des yeux, des roseaux… Au milieu, un ibis tient une palette. On dirait qu'il te regarde.", 6.0), 1.0)
	M.ctx["cloche170"] = false
	M.ctx["bonjour170"] = ["Entre doucement : la classe travaille.", "Ah, un nouvel élève ? Prends un roseau !"]
	M.ctx["entree"] = "La Maison de Vie : les petits scribes penchés sur leur papyrus, le maître Amenemhat devant le grand papyrus de Thot, les rouleaux rangés dans leurs niches."


## Un mur de niches (des cases de bois pleines de rouleaux de papyrus), contre un mur.
static func _niches(M, x: float, z: float, yaw: float, w: float, h: float) -> void:
	var R = M.R
	var k = R.kit
	var bois: String = _m(R, "bois69")
	var xf: Transform3D = R.L(x, 0, z, yaw)
	var nx: int = int(w / 0.5)
	var ny: int = 4
	k.box(xf * B.T3(0, h * 0.5, -0.17), Vector3(w, h, 0.04), "bois_sombre", 1.0)
	for i in range(nx + 1):
		k.box(xf * B.T3(-w * 0.5 + i * w / nx, h * 0.5, 0), Vector3(0.04, h, 0.36), bois, 1.0)
	for j in range(ny + 1):
		k.box(xf * B.T3(0, j * h / ny + 0.02, 0), Vector3(w, 0.04, 0.36), bois, 1.0)
	var pap: String = B._c(R, "rouleau_pap", Color(0.9, 0.82, 0.6), 0.9)
	for i2 in range(nx):
		for j2 in range(ny):
			var cx: float = -w * 0.5 + (i2 + 0.5) * w / nx
			var cy: float = j2 * h / ny + 0.1
			for r in range(3 - (i2 + j2) % 2):
				k.cyl(xf * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(cx - 0.12 + r * 0.11, cy, -0.15)), 0.045, 0.045, 0.3, pap, 8)
	k.col_box(xf * B.T3(0, h * 0.5, 0), Vector3(w, h, 0.36))
	R.mark_wall(x, h * 0.5, z, w * 0.5)
	R.reserve(x, z, 0.6 if absf(sin(deg_to_rad(yaw))) > 0.5 else w, w if absf(sin(deg_to_rad(yaw))) > 0.5 else 0.6)


# =================================================================== Per-Hâpy : l'atelier de Ptahmosé, le potier

static func _poterie(M) -> void:
	var R = M.R
	var k = R.kit
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	# le four du potier (une tour de briques, la bouche rouge)
	var fx: float = -hw + 0.95
	var fz: float = -hd + 0.95
	k.cyl(R.L(fx, 0, fz), 0.75, 0.62, 1.9, _m(R, "brique69"), 18)
	k.ring(R.L(fx, 1.9, fz), 0.42, 0.64, 0.1, _m(R, "brique69_sombre"), 18)
	k.quad(R.L(fx + 0.48, 0.4, fz + 0.48, 45.0) * Transform3D(Basis(Vector3.UP, PI), Vector3(0, 0, 0.02)), 0.5, 0.5, "noir")
	k.box(R.L(fx + 0.5, 0.22, fz + 0.5, 45.0), Vector3(0.42, 0.1, 0.06), B._c(R, "braises171", Color(1.0, 0.42, 0.12), 0.6, 0.0, 2.2), 1.0)
	R.fire(R.P(fx + 0.56, 0.25, fz + 0.56), 0.3)
	k.col_box(R.L(fx, 0.95, fz), Vector3(1.4, 1.9, 1.4))
	R.reserve(fx, fz, 1.6, 1.6)
	# le tour : il tourne, et le pot monte dessus
	var wx: float = 0.6
	var wz: float = -0.35
	k.cyl(R.L(wx, 0, wz), 0.26, 0.2, 0.38, _m(R, "roche69"), 14)
	var tour := Node3D.new()
	M.room.add_child(tour)
	tour.global_position = R.P(wx, 0.38, wz)
	var argile: Material = R.mat(B._c(R, "argile_mouillee", Color(0.55, 0.33, 0.22), 0.35))
	var disque := MeshInstance3D.new()
	disque.mesh = B._cylm(0.3, 0.3, 0.05, 24)
	disque.material_override = R.mat(_m(R, "bois69"))
	disque.position = Vector3(0, 0.025, 0)
	tour.add_child(disque)
	var pot1 := MeshInstance3D.new()
	pot1.mesh = B._cylm(0.13, 0.09, 0.13, 18)
	pot1.material_override = argile
	pot1.position = Vector3(0, 0.115, 0)
	tour.add_child(pot1)
	var pot2 := MeshInstance3D.new()
	pot2.mesh = B._cylm(0.07, 0.13, 0.1, 18)
	pot2.material_override = argile
	pot2.position = Vector3(0, 0.23, 0)
	tour.add_child(pot2)
	(M.ctx["anims170"] as Array).append([tour, "tourne", Vector3.UP, 5.0])
	k.col_box(R.L(wx, 0.3, wz), Vector3(0.6, 0.6, 0.6))
	R.reserve(wx, wz, 0.8, 0.8)
	k.box(R.L(wx, 0.42, wz - 0.8), Vector3(0.38, 0.05, 0.34), "bois", 1.0)
	for sx in [-1.0, 1.0]:
		k.box(R.L(wx + sx * 0.15, 0.2, wz - 0.8), Vector3(0.05, 0.4, 0.3), "bois_sombre", 1.0)
	# les pots qui sèchent : les étagères, les jarres au sol, le tas d'argile, le baquet d'eau
	B._rayons(M, hw - 0.22, -0.7, -90.0, 1.6, 2.0, 4, "pots", 1)
	B._rayons(M, 1.9, -hd + 0.22, 0.0, 1.4, 2.0, 4, "pots", 3)
	var jp: Array = [[hw - 0.5, 1.0, 0.9, "argile69"], [hw - 0.95, 1.4, 0.7, "argile69_rouge"], [hw - 0.45, 1.8, 0.6, "argile69_terre"], [hw - 1.3, 2.1, 0.5, "argile69"]]
	for j in jp:
		_jarre(R, float(j[0]), float(j[1]), float(j[2]), str(j[3]))
	k.cyl(R.L(-1.2, 0, -hd + 0.6), 0.5, 0.25, 0.38, "argile_mouillee", 14)
	k.col_box(R.L(-1.2, 0.18, -hd + 0.6), Vector3(0.9, 0.36, 0.9))
	k.cyl(R.L(wx + 0.6, 0, wz + 0.2), 0.2, 0.24, 0.22, "bois", 14)
	k.disc(R.L(wx + 0.6, 0.2, wz + 0.2), 0.2, _m(R, "eau69"), 16)
	# la table où l'apprenti peint les pots
	R.table(-hw + 1.0, 0.7, 90.0, 1.2, 0.7, 0.8)
	for p in range(3):
		var px: float = -hw + 1.0
		var pz: float = 0.35 + p * 0.35
		k.cyl(R.L(px, 0.8, pz), 0.07, 0.11, 0.12, _m(R, "argile69"), 12)
		k.cyl(R.L(px, 0.92, pz), 0.11, 0.06, 0.08, _m(R, "argile69"), 12)
		k.cyl(R.L(px, 0.88, pz), 0.111, 0.111, 0.025, B._c(R, "bande171_%d" % p, [Color(0.2, 0.32, 0.62), Color(0.72, 0.2, 0.12), Color(0.2, 0.48, 0.32)][p], 0.7), 12, false)
	var app: Node = M.person("garcon", -hw + 1.75, 0.7, -90.0, "peindre", "Petit Ouni")
	app.lines = ["Je peins des bandes bleues. Le maître dit que le bleu, ça porte bonheur.", "Ce pot-là est un peu penché. C'est exprès. C'est… un style."]
	_fresque(M, "soleils/fresque_nil.png", -hw + 0.02, 2.2, -0.4, 90.0, 1.8, 0.8)
	var essayer := func() -> void:
		M.say("Tu poses les mains sur l'argile qui tourne… elle s'affaisse doucement. Ptahmosé rit : « La première fois, tout le monde fait une assiette ! »", 6.0)
	M.act(R.P(wx + 0.7, 0, wz + 0.75), "E : essayer le tour", essayer, 1.0)
	B._marchand(M, wx, wz - 0.8, 0.0, "assis", "homme", "Ptahmosé", ["Le pied tourne la roue, la main fait le pot. Et la tête ? Elle chante.", "Un bon pot sonne comme une cloche quand on le tape. Écoute… toc !", "La terre du Nil, c'est la meilleure. Elle se souvient de la crue."],
		{"bonjour": "Bienvenue à l'atelier ! Attention où tu marches : tout sèche.", "infos": ["Les grandes jarres gardent le grain, l'eau, l'huile. Les petites, les secrets.", "On cuit les pots dans le four toute une nuit. Au matin, ils sont rouges comme le couchant."]})
	M.ctx["bonjour170"] = ["Entre, entre ! Mais ne touche pas aux pots frais.", "Ah, de la visite ! La roue ne s'arrête jamais."]
	M.ctx["entree"] = "L'atelier de Ptahmosé : le tour qui tourne et le pot qui monte, le four de briques, des pots partout qui sèchent sur les étagères."


# =================================================================== Per-Hâpy : le naos de Rê

## Le disque solaire ailé (au-dessus d'une porte, d'une fresque).
static func _disque_aile(M, x: float, y: float, z: float, s: float = 1.0) -> void:
	var R = M.R
	var k = R.kit
	R.mark_wall(x, y, z, 1.4 * s)
	k.cyl(R.L(x, y, z + 0.03) * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 0.26 * s, 0.26 * s, 0.05, _m(R, "or69"), 24)
	k.cyl(R.L(x, y, z + 0.06) * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 0.2 * s, 0.2 * s, 0.02, B._c(R, "disque_re", Color(0.95, 0.3, 0.1), 0.4, 0.2, 1.2), 24)
	var cols: Array = [_m(R, "lapis69"), _m(R, "or69"), _m(R, "turq69"), B._c(R, "bande171_1", Color(0.72, 0.2, 0.12), 0.7)]
	for sx in [-1.0, 1.0]:
		for b in range(4):
			var l: float = (1.3 - b * 0.18) * s
			k.box(R.L(x + sx * (0.25 * s + l * 0.5), y + 0.12 * s - b * 0.09 * s, z + 0.02), Vector3(l, 0.08 * s, 0.03), str(cols[b]), 1.0)
		for u in range(2):
			k.cyl(R.L(x + sx * 0.3 * s, y - 0.28 * s, z + 0.03) * Transform3D(Basis(Vector3.BACK, sx * 0.2), Vector3.ZERO), 0.04 * s, 0.03 * s, 0.22 * s, _m(R, "or69"), 8)


## La barque sacrée sur son reposoir (le dieu y voyage pendant les fêtes).
static func _barque(M, x: float, z: float, s: float = 1.0) -> void:
	var R = M.R
	var k = R.kit
	var orr: String = _m(R, "or69")
	k.box(R.L(x, 0.3, z), Vector3(1.6, 0.6, 0.6) * Vector3(s, 1, s), _m(R, "calc69"), 1.0)
	k.box(R.L(x, 0.62, z), Vector3(1.7 * s, 0.05, 0.7 * s), _m(R, "hiero69"), 1.0)
	k.col_box(R.L(x, 0.3, z), Vector3(1.6 * s, 0.6, 0.6 * s))
	R.reserve(x, z, 1.9 * s, 0.9 * s)
	var y: float = 0.72
	k.box(R.L(x, y, z), Vector3(1.4, 0.16, 0.36) * s, orr, 1.0)
	for sx in [-1.0, 1.0]:
		k.box(R.L(x + sx * 0.85 * s, y + 0.12 * s, z) * Transform3D(Basis(Vector3.BACK, sx * 0.55), Vector3.ZERO), Vector3(0.42, 0.12, 0.26) * s, orr, 1.0)
		k.box(R.L(x + sx * 1.02 * s, y + 0.32 * s, z) * Transform3D(Basis(Vector3.BACK, sx * 0.25), Vector3.ZERO), Vector3(0.1, 0.32, 0.16) * s, _m(R, "lapis69"), 1.0)
	k.box(R.L(x, y + 0.26 * s, z), Vector3(0.5, 0.36, 0.28) * s, _m(R, "lin69"), 1.0)
	k.box(R.L(x, y + 0.46 * s, z), Vector3(0.56, 0.05, 0.32) * s, orr, 1.0)
	for sz in [-1.0, 1.0]:
		k.box(R.L(x, y + 0.02, z + sz * 0.26 * s), Vector3(2.3 * s, 0.05, 0.05), "bois_sombre", 1.0)


static func _naos(M) -> void:
	var R = M.R
	var k = R.kit
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	# le tabernacle doré, la statue de Rê, le rai de lumière qui tombe sur lui
	_tabernacle(M, 0.0, -hd + 0.75, 1.5, 0.5, "re")
	_rayon(M, 0.0, -hd + 1.6, 0.55, 0.32)
	_disque_aile(M, 0.0, 3.85, -hd + 0.01, 1.0)
	for sx in [-1.0, 1.0]:
		_brasero(M, sx * 1.75, -hd + 1.25, 0.95, "calc69")
	# la barque sacrée sur son reposoir
	_barque(M, 0.0, 0.25, 1.0)
	_fresque(M, "soleils/fresque_barque.png", -hw + 0.02, 2.3, -0.2, 90.0, 3.0, 1.4, _m(R, "or69"))
	_fresque(M, "soleils/fresque_osiris.png", hw - 0.02, 2.3, -0.2, -90.0, 3.0, 1.4, _m(R, "or69"))
	_offrandes(M, -hw + 0.6, 1.4, 90.0, 0.9)
	B._lampe(M, 0.0, 3.4, -hd + 1.5, Color(1.0, 0.85, 0.55), 0.9, 4.0)
	var offrir := func() -> void:
		M.main.sfx("cristal_chante")
		M.say("Tu déposes une fleur de lotus devant Rê. Les flammes des braseros se redressent, toutes droites, et la statue d'or brille un peu plus fort.", 6.0)
	M.act(R.P(0.0, 0, -hd + 1.85), "E : déposer une fleur devant Rê", offrir, 0.9)
	B._marchand(M, 1.55, -0.6, -110.0, "mains_dos", "vieux", "Ouserhat, prêtre de Rê", ["Chut… ici, on parle tout bas. Rê se repose.", "Chaque matin, on ouvre les portes du naos, et le dieu voit le jour.", "La barque, c'est pour les fêtes : on la porte sur les épaules, tout le long du fleuve."],
		{"bonjour": "Bienvenue dans la maison du dieu. Approche, mais doucement.", "infos": ["Au plafond, c'est Nout, la déesse du ciel. Ses étoiles veillent sur nous, même à midi.", "Seuls les prêtres touchent la statue. Les visiteurs, eux, peuvent sourire. C'est déjà beaucoup."]})
	M.ctx["cloche170"] = false
	M.ctx["bonjour170"] = ["Bienvenue, voyageur. Parle bas.", "Rê t'a vu entrer. Il est content."]
	M.ctx["entree"] = "Le naos de Rê : le tabernacle doré et le dieu à tête de faucon dans un rai de lumière, la barque sacrée sur son reposoir, le plafond bleu de Nout semé d'étoiles."


# =================================================================== Per-Hâpy : le temple de la vallée

static func _temple_vallee(M) -> void:
	var R = M.R
	var k = R.kit
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var granit: String = _m(R, "statue69_granit")
	# les piliers de granit d'un seul bloc, et les architraves
	for sx in [-1.0, 1.0]:
		for pz in [-3.0, -0.6, 1.8]:
			k.box(R.L(sx * 3.0, R.H * 0.5, pz), Vector3(0.9, R.H, 0.9), granit, 1.6)
			k.col_box(R.L(sx * 3.0, R.H * 0.5, pz), Vector3(0.9, R.H, 0.9))
			R.reserve(sx * 3.0, pz, 1.1, 1.1)
		k.box(R.L(sx * 3.0, R.H - 0.35, -0.6), Vector3(0.95, 0.7, 5.75), granit, 1.6)
	for pz2 in [-3.0, -0.6, 1.8]:
		k.box(R.L(0.0, R.H - 0.3, pz2), Vector3(5.1, 0.6, 0.8), granit, 1.6)
	# les rois assis, de pierre sombre, le long des murs
	for sx2 in [-1.0, 1.0]:
		for sz in [-1.8, 0.6]:
			_statue(M, sx2 * (hw - 0.85), sz, -sx2 * 90.0, 1.3, "roi", "statue69_sombre")
	# au fond : Osiris et le disque ailé ; l'autel et ses braseros
	_fresque(M, "soleils/fresque_osiris.png", 0.0, 2.6, -hd + 0.02, 0.0, 4.0, 2.2, _m(R, "or69"))
	_disque_aile(M, 0.0, 4.6, -hd + 0.01, 1.4)
	_offrandes(M, 0.0, -hd + 1.4, 0.0, 1.6)
	for sx3 in [-1.0, 1.0]:
		_brasero(M, sx3 * 1.5, -hd + 1.5, 1.1, "calc69")
		_fresque(M, "soleils/hieroglyphes.png", sx3 * (hw - 0.02), 3.9, -0.6, -sx3 * 90.0, 7.5, 1.0)
	# la lumière qui tombe des fentes du haut des murs
	_rayon(M, -1.5, 0.9, 0.5, 0.35)
	_rayon(M, 1.5, -1.6, 0.5, 0.35)
	_rayon(M, 0.0, 3.2, 0.45, 0.35)
	B._lampe(M, 0.0, 4.5, 0.0, Color(1.0, 0.86, 0.62), 1.0, 12.0)
	var lire := func() -> void:
		var st: Dictionary = M.state()
		var n: int = int(st.get("hiero171", 0))
		st["hiero171"] = n + 1
		var t: Array = ["« Le roi a bâti ce temple pour son père Rê, pour qu'il y descende chaque soir, comme le soleil descend vers l'ouest. »",
			"« Ici, les barques s'arrêtent, et l'on monte à pied jusqu'à la grande pyramide, par la chaussée. »",
			"Il y a aussi, tout en bas, un petit dessin qui n'a rien de sacré : un chat qui chasse une souris. Un ouvrier s'ennuyait, sans doute."]
		M.say(str(t[n % t.size()]), 7.0)
	M.act(R.P(-hw + 1.8, 0, -hd + 1.6), "E : lire les hiéroglyphes", lire, 1.2)
	B._marchand(M, 1.9, 3.2, -150.0, "mains_dos", "homme", "Sennefer, le gardien", ["Ce temple est plus vieux que le plus vieux des vieux palmiers.", "Les piliers ? Un seul bloc chacun. Je ne sais pas comment ils les ont portés. Moi, je porte déjà mal mon déjeuner."],
		{"bonjour": "Le temple de la vallée te souhaite la bienvenue.", "infos": ["Les statues du roi regardent toutes vers le centre. Elles attendent que tu dises bonjour.", "Le sol est d'albâtre : à la lumière des torches, il brille comme de la lune."]})
	var pel: Node = M.person("femme", 0.7, -hd + 2.35, 180.0, "prier", "Ahhotep")
	pel.lines = ["Je viens remercier Rê : mes champs ont bien poussé.", "Chut… je prie."]
	var gm: Node = M.person("garcon", -1.4, 1.1, -95.0, "pointer", "Petit Djehouti")
	gm.lines = ["Il est grand, le roi de pierre ! Plus grand que mon père. Plus grand que le chameau du voisin !"]
	M.ctx["cloche170"] = false
	M.ctx["bonjour170"] = ["Bienvenue au temple de la vallée.", "Entre. Les rois de pierre ne mordent pas."]
	M.ctx["entree"] = "Le temple de la vallée : les grands piliers de granit rose, le sol d'albâtre, les rois de pierre sombre assis le long des murs, et les rais de lumière qui tombent d'en haut."


# =================================================================== Yaxché : le palais

## Une peau de jaguar (un coussin, un tapis) : le fond fauve, les taches noires.
static func _jaguar(R) -> String:
	if R.mat("jaguar171") == null:
		R._put("jaguar171", R._col(Color(0.86, 0.58, 0.22), 0.9, 0.0))
	return "jaguar171"


static func _taches(R, xf: Transform3D, w: float, d: float, n: int, seed_t: int) -> void:
	var k = R.kit
	var noir: String = B._c(R, "tache_jaguar", Color(0.12, 0.08, 0.05), 0.9)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_t
	for i in range(n):
		var p := Vector3(rng.randf_range(-w * 0.45, w * 0.45), 0.0, rng.randf_range(-d * 0.45, d * 0.45))
		var r: float = rng.randf_range(0.02, 0.045)
		k.ring(xf * B.T3(p.x, 0.0, p.z), r * 0.55, r, 0.006, noir, 8)


static func _palais_maya(M) -> void:
	var R = M.R
	var k = R.kit
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var pm: String = _m(R, "pmaya69")
	# la voûte en encorbellement : deux pans de pierre qui se rapprochent en haut
	for s in [-1.0, 1.0]:
		k.box(R.L(0.0, R.H - 0.95, s * (hd - 0.55)) * Transform3D(Basis(Vector3.RIGHT, -s * 0.62), Vector3.ZERO), Vector3(R.W, 1.9, 0.3), "mur", 2.5)
	# le trône : le banc de pierre, le coussin en peau de jaguar, le dossier
	var tz: float = -hd + 0.72
	k.box(R.L(0.0, 0.2, tz), Vector3(2.6, 0.4, 0.8), pm, 1.2)
	k.box(R.L(0.0, 0.2, tz + 0.405), Vector3(2.5, 0.3, 0.01), _m(R, "glyphm69"), 1.0)
	k.col_box(R.L(0.0, 0.2, tz), Vector3(2.6, 0.4, 0.8))
	R.reserve(0.0, tz, 2.8, 1.0)
	var jag: String = _jaguar(R)
	k.box(R.L(0.0, 0.43, tz + 0.02), Vector3(2.2, 0.06, 0.72), jag, 1.0)
	_taches(R, R.L(0.0, 0.461, tz + 0.02), 2.2, 0.72, 40, 7)
	k.box(R.L(0.0, 0.75, -hd + 0.36) * Transform3D(Basis(Vector3.RIGHT, -0.12), Vector3.ZERO), Vector3(2.0, 0.6, 0.16), jag, 1.0)
	for sx in [-1.0, 1.0]:
		k.cyl(R.L(sx * 1.05, 0.46, -hd + 0.45) * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3.ZERO), 0.13, 0.13, 0.5, B._c(R, "coussin_maya", Color(0.15, 0.42, 0.55), 0.85), 12)
	# derrière le trône : Kukulkán ; au-dessus, un masque de stuc
	_fresque(M, "soleils/fresque_kukulkan.png", 0.0, 1.95, -hd + 0.02, 0.0, 3.2, 1.6, pm)
	for sxm in [-1.0, 1.0]:
		_masque(M, sxm * (hw - 0.02), 3.45, 0.0, -sxm * 90.0, 0.75)
	_fresque(M, "soleils/fresque_jumeaux.png", -hw + 0.02, 2.0, 0.0, 90.0, 3.0, 1.5, pm)
	_fresque(M, "soleils/codex_soleils.png", hw - 0.02, 2.0, 0.0, -90.0, 3.0, 1.4, pm)
	# les tentures, les éventails de plumes, la table du cacao et du jade, l'encensoir
	for sx2 in [-1.0, 1.0]:
		_tenture(M, sx2 * 3.4, -hd + 0.03, 0.0, 1.0, 1.9, sx2 > 0, 2.75)
		_eventail(M, sx2 * 1.75, -hd + 0.6)
	k.box(R.L(hw - 1.4, 0.22, -0.9), Vector3(1.6, 0.44, 0.7), pm, 1.2)
	k.col_box(R.L(hw - 1.4, 0.22, -0.9), Vector3(1.6, 0.44, 0.7))
	R.reserve(hw - 1.4, -0.9, 1.8, 0.9)
	for v in range(3):
		_vase_cacao(M, hw - 2.0 + v * 0.4, 0.44, -0.95 + 0.1 * float(v % 2))
	for j in range(5):
		Sud._boule(M.room, R.mat(_m(R, "jade69")), R.P(hw - 0.85 + 0.07 * float(j % 2), 0.48, -1.1 + j * 0.09), 0.035)
	_brasero(M, -hw + 1.2, -0.9, 0.8, "argile69_rouge")
	_natte(R, 0.0, 0.1, 0.0, 3.4, 2.2)
	B._lampe(M, 0.0, 3.2, -0.5, Color(1.0, 0.82, 0.55), 0.9, 9.0)
	for sx3 in [-1.0, 1.0]:
		var g: Node = M.person("homme", sx3 * 1.75, -hd + 1.35, -sx3 * 20.0, "bras_croises", "")
		g.lines = ["Je garde le trône. Le trône ne bouge pas beaucoup, mais je le garde quand même."] if sx3 < 0 else ["La grande prêtresse lit le ciel. Moi, je lis… les pieds des visiteurs. Essuie les tiens."]
	var lignes: Array = ["Kukulkán descend l'escalier du temple, deux fois par an, quand la lumière glisse sur les marches.", "Le ciel est un livre. Il suffit d'apprendre ses signes.", "Assieds-toi sur la natte, voyageur. Ici, on parle lentement."]
	B._marchand(M, 0.0, tz + 0.18, 0.0, "assis", "femme", "Ix Kanul", lignes, {"bonjour": "Sois le bienvenu au palais de Yaxché.", "vend": {"cacao": 4, "galette_mais": 2}, "infos": ["Le cacao, c'est la boisson des rois. Mousseux, avec un peu de piment. Les enfants, sans piment."]})
	var nob: Node = M.person("homme", -0.9, 0.25, 180.0, "mediter", "")
	nob.lines = ["J'attends mon tour pour parler à la grande prêtresse. Ça fait trois jours. Mais je suis bien assis."]
	M.ctx["cloche170"] = false
	M.ctx["bonjour170"] = ["Approche, voyageur.", "Le palais t'ouvre ses portes."]
	M.ctx["entree"] = "Le palais de Yaxché : la voûte de pierre, le trône couvert d'une peau de jaguar, Kukulkán peint sur le mur, les éventails de plumes et le cacao du matin."


## Un masque de stuc (un visage, les ornements d'oreilles, la coiffe), accroché au mur.
static func _masque(M, x: float, y: float, z: float, yaw: float, s: float) -> void:
	var R = M.R
	var k = R.kit
	var st: String = _m(R, "stucr69")
	var xf: Transform3D = R.L(x, y, z, yaw)
	R.mark_wall(x, y, z, 0.7 * s)
	k.box(xf * B.T3(0, 0, 0.08 * s), Vector3(0.6, 0.62, 0.16) * s, st, 1.0)
	k.box(xf * B.T3(0, 0.38 * s, 0.1 * s), Vector3(0.9, 0.16, 0.2) * s, _m(R, "pmaya69"), 1.0)
	for sx in [-1.0, 1.0]:
		k.cyl(xf * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(sx * 0.36 * s, 0.0, 0.1 * s)), 0.1 * s, 0.1 * s, 0.05 * s, _m(R, "jade69"), 12)
		k.box(xf * B.T3(sx * 0.13 * s, 0.08 * s, 0.17 * s), Vector3(0.13, 0.07, 0.02) * s, "noir", 1.0)
	k.box(xf * B.T3(0, -0.05 * s, 0.2 * s), Vector3(0.1, 0.18, 0.08) * s, st, 1.0)
	k.box(xf * B.T3(0, -0.2 * s, 0.17 * s), Vector3(0.28, 0.06, 0.02) * s, B._c(R, "levres_maya", Color(0.5, 0.1, 0.08), 0.8), 1.0)


## Une tenture tissée (des bandes de couleur), pendue à une perche.
static func _tenture(M, x: float, z: float, yaw: float, w: float, h: float, alt: bool, haut: float = -1.0) -> void:
	var R = M.R
	var k = R.kit
	var cols: Array = [Color(0.7, 0.15, 0.1), Color(0.95, 0.75, 0.2), Color(0.12, 0.38, 0.55), Color(0.9, 0.88, 0.78), Color(0.2, 0.45, 0.25)]
	var n: int = 9
	var top: float = haut if haut > 0.0 else R.H - 0.5
	R.mark_wall(x, top - h * 0.5, z, w * 0.5)
	k.cyl(R.L(x, top + 0.04, z + 0.06, yaw) * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(w * 0.5 + 0.08, 0, 0)), 0.02, 0.02, w + 0.16, "bois_sombre", 6)
	for i in range(n):
		var c: Color = cols[(i + (2 if alt else 0)) % cols.size()]
		k.box(R.L(x, top - h * (i + 0.5) / n, z + 0.03, yaw), Vector3(w, h / n + 0.002, 0.012), B._c(R, "tenture_%s" % c.to_html(false), c, 0.95), 1.0)


## Un grand éventail de plumes sur sa hampe (plantée dans un socle).
static func _eventail(M, x: float, z: float) -> void:
	var R = M.R
	var k = R.kit
	k.cyl(R.L(x, 0, z), 0.16, 0.14, 0.12, _m(R, "pmaya69"), 10)
	k.cyl(R.L(x, 0.12, z), 0.02, 0.02, 1.8, "bois_sombre", 6)
	var cols: Array = ["plume69", "plume69_rouge", "plume69_bleu", "plume69_jaune"]
	for i in range(13):
		var a: float = deg_to_rad(-80.0 + i * (160.0 / 12.0))
		k.box(R.L(x, 1.95, z) * Transform3D(Basis(Vector3.BACK, a), Vector3(-sin(a) * 0.32, cos(a) * 0.32, 0)), Vector3(0.07, 0.62, 0.01), _m(R, str(cols[i % 4])), 1.0)
	k.cyl(R.L(x, 1.88, z) * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0, -0.02)), 0.09, 0.09, 0.04, _m(R, "or69"), 12)
	k.col_box(R.L(x, 0.5, z), Vector3(0.3, 1.0, 0.3))
	R.reserve(x, z, 0.5, 0.5)


## Un vase à cacao (cylindrique, la bande de glyphes, la mousse dessus).
static func _vase_cacao(M, x: float, y: float, z: float) -> void:
	var R = M.R
	var k = R.kit
	k.cyl(R.L(x, y, z), 0.09, 0.1, 0.24, _m(R, "argile69_rouge"), 14)
	k.cyl(R.L(x, y + 0.08, z), 0.101, 0.101, 0.08, _m(R, "glyphm69"), 14, false)
	k.cyl(R.L(x, y + 0.235, z), 0.09, 0.09, 0.01, B._c(R, "mousse_cacao", Color(0.62, 0.42, 0.28), 0.8), 14)


# =================================================================== Yaxché : le Temple des Jaguars

## Le jaguar rouge (un trône de pierre peinte, ses taches de jade, ses yeux de jade, ses crocs).
static func _jaguar_rouge(M, x: float, z: float, yaw: float, s: float) -> void:
	var R = M.R
	var k = R.kit
	var rk: String = B._c(R, "jaguar_rouge", Color(0.68, 0.1, 0.07), 0.55)
	var jk: String = _m(R, "jade69")
	var xf: Transform3D = R.L(x, 0, z, yaw)
	k.box(xf * B.T3(0, 0.12 * s, 0), Vector3(0.9, 0.24, 1.7) * s, _m(R, "pmaya69"), 1.0)
	k.box(xf * B.T3(0, 0.12 * s, 0.855 * s), Vector3(0.8, 0.18, 0.01) * s, _m(R, "glyphm69"), 1.0)
	# le corps, le poitrail, la tête, le museau, les oreilles (des ovales de pierre peinte)
	var bc := Vector3(0, 0.68, -0.1) * s
	_ovale(M, rk, xf, bc, Vector3(0.3, 0.24, 0.62) * s)
	_ovale(M, rk, xf, Vector3(0, 0.72, 0.4) * s, Vector3(0.26, 0.26, 0.24) * s)
	_ovale(M, rk, xf, Vector3(0, 0.98, 0.62) * s, Vector3(0.22, 0.19, 0.2) * s)
	_ovale(M, rk, xf, Vector3(0, 0.92, 0.8) * s, Vector3(0.12, 0.085, 0.09) * s)
	for sx in [-1.0, 1.0]:
		_ovale(M, rk, xf, Vector3(sx * 0.13, 1.15, 0.57) * s, Vector3(0.06, 0.06, 0.035) * s)
		_ovale(M, jk, xf, Vector3(sx * 0.085, 1.02, 0.78) * s, Vector3(0.035, 0.03, 0.025) * s)
		k.cyl(xf * Transform3D(Basis(Vector3.RIGHT, PI), Vector3(sx * 0.045, 0.88, 0.85) * s), 0.016 * s, 0.0, 0.07 * s, "ceramique", 6)
		# les pattes (devant, derrière), les pieds
		for pz in [0.42, -0.5]:
			k.cyl(xf * B.T3(sx * 0.16 * s, 0.24 * s, pz * s), 0.075 * s, 0.085 * s, 0.42 * s, rk, 10)
			_ovale(M, rk, xf, Vector3(sx * 0.16, 0.27, pz + 0.05) * s, Vector3(0.09, 0.05, 0.12) * s)
	# la queue qui s'enroule
	k.cyl(xf * Transform3D(Basis(Vector3.RIGHT, -PI * 0.62), Vector3(0, 0.66, -0.68) * s), 0.05 * s, 0.035 * s, 0.5 * s, rk, 8)
	k.cyl(xf * Transform3D(Basis(Vector3.RIGHT, -PI * 0.95) * Basis(Vector3.BACK, 0.4), Vector3(0, 0.4, -1.08) * s), 0.035 * s, 0.025 * s, 0.25 * s, rk, 8)
	# les taches de jade, incrustées sur le dos et les flancs
	var rng := RandomNumberGenerator.new()
	rng.seed = 171
	for i in range(34):
		var th: float = rng.randf_range(0.15, 1.35)
		var ph: float = rng.randf() * TAU
		var p := Vector3(0.3 * sin(th) * cos(ph), 0.24 * cos(th), 0.62 * sin(th) * sin(ph)) * s + bc
		_ovale(M, jk, xf, p, Vector3(0.032, 0.022, 0.032) * s)
	k.col_box(xf * B.T3(0, 0.55 * s, 0), Vector3(0.9, 1.1, 1.7) * s)
	R.reserve(x, z, 1.2 * s, 1.9 * s)


## Un ovale (une sphère étirée) : p et r dans le repère xf (r : les trois rayons) ; key : la matière.
static func _ovale(M, key: String, xf: Transform3D, p: Vector3, r: Vector3) -> MeshInstance3D:
	var b: MeshInstance3D = Sud._boule(M.room, M.R.mat(key), xf * p, 1.0)
	b.global_transform = Transform3D(xf.basis * Basis.from_scale(r), xf * p)
	return b


static func _temple_jaguars(M) -> void:
	var R = M.R
	var k = R.kit
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	_jaguar_rouge(M, 0.0, -hd + 1.05, 0.0, 1.0)
	_fresque(M, "soleils/sym_soleil_jaguar.png", 0.0, 2.7, -hd + 0.02, 0.0, 1.3, 1.3, "", 1)
	_fresque(M, "soleils/stele_4ahau.png", -hw + 0.02, 1.9, -0.3, 90.0, 1.0, 1.8, _m(R, "pmaya69"))
	_fresque(M, "soleils/glyphes_maya.png", hw - 0.02, 2.0, -0.3, -90.0, 1.6, 1.6, _m(R, "pmaya69"))
	_brasero(M, -1.3, -0.4, 0.8, "argile69_rouge")
	for j in range(3):
		_vase_cacao(M, 1.1 + j * 0.28, 0.0, -0.3 + 0.12 * float(j % 2))
	k.box(R.L(1.4, 0.01, -0.3), Vector3(1.1, 0.02, 0.6), _m(R, "lin69_rouge"), 1.0)
	for f in range(6):
		Sud._boule(M.room, R.mat(B._c(R, "plumeria", Color(0.98, 0.95, 0.85), 0.6)), R.P(0.9 + f * 0.17, 0.05, 0.25 + 0.06 * float(f % 2)), 0.05, Vector3(1.0, 0.5, 1.0))
	B._lampe(M, 0.0, 2.4, -0.4, Color(1.0, 0.6, 0.4), 0.8, 6.0)
	var caresser := func() -> void:
		M.main.sfx("cristal_chante")
		M.say("Tu poses la main sur le jaguar rouge. La pierre est tiède, et ses yeux de jade semblent cligner… Il a l'air de ronronner.", 6.0)
	M.act(R.P(0.0, 0, -hd + 2.2), "E : caresser le jaguar de pierre", caresser, 1.0)
	B._marchand(M, 1.5, 0.9, -140.0, "mains_dos", "vieux", "Grand-père Itzam", ["Le jaguar garde le soleil de la nuit. Le jour, il dort, comme les chats.", "Ses taches sont de jade. On les compte chaque matin. Il en manque rarement."],
		{"bonjour": "Entre, petit. Le jaguar t'a déjà vu.", "infos": ["Les anciens disent que le premier soleil a été mangé par des jaguars. Celui-ci est sage : il préfère le cacao."]})
	M.ctx["cloche170"] = false
	M.ctx["bonjour170"] = ["Bienvenue au Temple des Jaguars.", "Ne fais pas de bruit, il dort."]
	M.ctx["entree"] = "Le Temple des Jaguars : le jaguar de pierre rouge et ses taches de jade, le soleil-jaguar au mur, l'encens de copal qui fume doucement."


# =================================================================== Yaxché : l'observatoire d'Ah Kin

static func _observatoire_maya(M) -> void:
	var R = M.R
	var k = R.kit
	var r: float = _rond(M, 24.0)
	var pm: String = _m(R, "pmaya69")
	# l'escalier en colimaçon autour du pilier du milieu (il monte vers la terrasse)
	k.cyl(R.L(0, 0, 0), 0.42, 0.38, R.H, pm, 16)
	for i in range(15):
		var a: float = deg_to_rad(200.0 + i * 24.0)
		var y: float = 0.28 * (i + 1)
		k.box(R.L(sin(a) * 0.82, y - 0.06, cos(a) * 0.82, rad_to_deg(a)), Vector3(0.36, 0.12, 0.9), pm, 1.0)
	k.col_box(R.L(0, R.H * 0.5, 0), Vector3(2.0, R.H, 2.0))
	R.reserve(0, 0, 2.6, 2.6)
	for l in R.lights:
		(l as Node3D).global_position = R.P(0, R.H - 0.95, 1.8)
	# les fentes de visée dans le mur rond : le soleil, Vénus, la lune
	var h: float = float(M.ctx.get("hour", 12.0))
	var nuit: bool = h >= 20.0 or h < 6.0
	var ciel: String = B._c(R, "fente_ciel_n" if nuit else "fente_ciel_j", Color(0.12, 0.16, 0.35) if nuit else Color(0.7, 0.85, 1.0), 0.5, 0.0, 0.6 if nuit else 1.6)
	for e in [[120.0, "VÉNUS"], [160.0, "SOLEIL"], [205.0, "LUNE"], [250.0, "PLÉIADES"]]:
		var a2: float = deg_to_rad(float(e[0]))
		var p := Vector3(sin(a2) * (r - 0.01), 0, cos(a2) * (r - 0.01))
		k.quad(R.L(p.x, 2.2, p.z, float(e[0])), 0.14, 1.0, ciel)
		B._ecrit(M, p.x - sin(a2) * 0.02, 2.95, p.z - cos(a2) * 0.02, float(e[0]) + 180.0, str(e[1]), 40, Color(0.95, 0.85, 0.5), 0.0035, 0.0)
	# la table du codex de Vénus, le bâton croisé de visée
	R.table(-2.0, 1.15, 30.0, 1.2, 0.7)
	var cod: String = B._img(R, "codex171", "soleils/codex_soleils.png")
	for c in range(5):
		var cx: float = -0.44 + c * 0.22
		var tilt: float = 0.22 if c % 2 == 0 else -0.22
		k.quad(R.L(-2.0, 0.8, 1.15, 30.0) * Transform3D(Basis(Vector3.BACK, tilt) * Basis(Vector3.UP, PI) * Basis(Vector3.RIGHT, PI * 0.5), Vector3(cx, 0.0, 0.0)), 0.22, 0.3, cod, Vector2(c * 0.2, 0), Vector2(c * 0.2 + 0.2, 1))
	k.cyl(R.L(1.9, 0, 1.6), 0.12, 0.1, 0.06, pm, 8)
	k.cyl(R.L(1.9, 0.06, 1.6), 0.02, 0.02, 1.5, "bois_sombre", 6)
	k.box(R.L(1.9, 1.55, 1.6, 45.0), Vector3(0.5, 0.025, 0.025), "bois_sombre", 1.0)
	k.box(R.L(1.9, 1.55, 1.6, -45.0), Vector3(0.5, 0.025, 0.025), "bois_sombre", 1.0)
	_natte(R, -1.6, -1.9, 30.0, 1.4, 0.9)
	B._lampe(M, 0.0, 3.6, 1.2, Color(1.0, 0.85, 0.6), 0.9, 7.0)
	_brasero(M, -2.4, -1.0, 0.6, "argile69_rouge")
	var viser := func() -> void:
		var h2: float = float(M.ctx.get("hour", 12.0))
		if h2 >= 18.5 or h2 < 6.5:
			M.say("Dans la fente de Vénus : l'étoile du soir, toute brillante, juste au bord de la pierre. Ah Kin note un trait sur son codex. « Encore deux cent soixante-trois jours, et elle reviendra le matin. »", 7.0)
		else:
			M.say("Par la fente, tu vois un bout de ciel bleu… et un toucan qui passe. Ah Kin sourit : « Vénus dort le jour. Reviens ce soir. »", 6.0)
	M.act(R.P(2.6, 0, -1.2), "E : regarder par la fente de Vénus", viser, 1.0)
	var lignes: Array = ["Le ciel tourne comme une roue. Moi, je compte ses tours.", "Vénus est l'étoile de Kukulkán. Elle disparaît, puis revient. Toujours à l'heure.", "Un jour, j'ai compté jusqu'à un million. Puis je me suis endormi."]
	B._marchand(M, 2.0, -1.0, 124.0, "observer", "vieux", "Ah Kin Pech", lignes, {"bonjour": "Bienvenue à l'observatoire. Lève les yeux : tout est là-haut.", "infos": ["Notre calendrier a deux roues : une de 260 jours, une de 365. Elles se retrouvent tous les 52 ans. C'est une fête !"]})
	M.ctx["cloche170"] = false
	M.ctx["bonjour170"] = ["Ah, un visiteur ! Tu tombes bien : je comptais les étoiles.", "Entre, entre. Attention à l'escalier."]
	M.ctx["entree"] = "L'observatoire d'Ah Kin : la tour ronde et son escalier en colimaçon, les fentes de visée du soleil, de Vénus et de la lune, le codex déplié sur la table."


# =================================================================== Yaxché : le sanctuaire du cénote

## Le Chac Mool : un homme de pierre couché, les genoux pliés, un bol sur le ventre, la tête tournée vers nous.
static func _chac_mool(M, x: float, z: float, s: float) -> void:
	var R = M.R
	var k = R.kit
	var m: String = _m(R, "statue69_sombre")
	k.box(R.L(x, 0.17, z), Vector3(1.9, 0.34, 1.0) * Vector3(s, 1, s), _m(R, "pmaya69"), 1.0)
	k.col_box(R.L(x, 0.17, z), Vector3(1.9 * s, 0.34, 1.0 * s))
	R.reserve(x, z, 2.1 * s, 1.2 * s)
	var xf: Transform3D = R.L(x, 0.34, z) * Transform3D(Basis().scaled(Vector3(s, s, s)), Vector3.ZERO)
	k.box(xf * B.T3(0.12, 0.12, 0), Vector3(0.38, 0.24, 0.44), m, 1.0)
	k.box(xf * Transform3D(Basis(Vector3.BACK, 2.51), Vector3(-0.2, 0.32, 0)), Vector3(0.68, 0.2, 0.42), m, 1.0)
	var hx: Transform3D = xf * B.T3(-0.5, 0.66, 0)
	k.box(hx, Vector3(0.24, 0.26, 0.24), m, 1.0)
	k.box(hx * B.T3(0, 0.15, 0), Vector3(0.28, 0.06, 0.28), m, 1.0)
	for sz in [-1.0, 1.0]:
		k.cyl(hx * Transform3D(Basis(Vector3.BACK, sz * PI * 0.5), Vector3(sz * 0.13, 0, 0)), 0.07, 0.07, 0.03, _m(R, "jade69"), 10)
		k.box(hx * B.T3(-0.05 * sz, 0.04, 0.122), Vector3(0.06, 0.03, 0.01), "noir", 1.0)
		k.box(xf * Transform3D(Basis(Vector3.BACK, 0.785), Vector3(0.38, 0.32, sz * 0.12)), Vector3(0.5, 0.16, 0.17), m, 1.0)
		k.box(xf * Transform3D(Basis(Vector3.BACK, -1.15), Vector3(0.64, 0.27, sz * 0.12)), Vector3(0.5, 0.14, 0.15), m, 1.0)
		k.box(xf * B.T3(0.82, 0.03, sz * 0.12), Vector3(0.22, 0.06, 0.13), m, 1.0)
		k.box(xf * Transform3D(Basis(Vector3.BACK, 1.9), Vector3(-0.33, 0.36, sz * 0.24)), Vector3(0.34, 0.1, 0.1), m, 1.0)
		k.box(xf * Transform3D(Basis(Vector3.BACK, 0.35), Vector3(-0.12, 0.33, sz * 0.15)), Vector3(0.3, 0.09, 0.09), m, 1.0)
	k.cyl(xf * B.T3(-0.06, 0.42, 0), 0.17, 0.13, 0.07, m, 16)
	k.disc(xf * B.T3(-0.06, 0.485, 0), 0.15, _m(R, "jade69"), 12)
	for j in range(4):
		Sud._boule(M.room, R.mat(B._c(R, "copal171", Color(0.95, 0.92, 0.78), 0.4)), xf * Vector3(-0.1 + 0.05 * float(j % 2), 0.51, -0.06 + 0.04 * j), 0.025 * s)


static func _sanctuaire_cenote(M) -> void:
	var R = M.R
	var k = R.kit
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	_chac_mool(M, 0.0, -hd + 0.8, 1.0)
	for sx in [-1.0, 1.0]:
		_masque_chaac(M, sx * (hw - 0.02), 2.2, -0.4, -sx * 90.0)
	_fresque(M, "soleils/glyphes_maya.png", 0.0, 2.5, -hd + 0.02, 0.0, 2.2, 0.9, _m(R, "pmaya69"))
	# le bassin d'eau du cénote, les coquillages, la conque, les jarres de pluie
	var bx: float = -hw + 1.0
	var bz: float = 0.9
	k.cyl(R.L(bx, 0, bz), 0.5, 0.55, 0.4, _m(R, "pmaya69"), 20)
	k.disc(R.L(bx, 0.36, bz), 0.45, _m(R, "eau69_cenote"), 20)
	k.col_box(R.L(bx, 0.2, bz), Vector3(1.1, 0.4, 1.1))
	R.reserve(bx, bz, 1.2, 1.2)
	for j in range(3):
		_jarre(R, hw - 0.45, 0.2 + j * 0.6, 0.85, "argile69_rouge" if j % 2 == 0 else "argile69")
	for c in range(4):
		k.cyl(R.L(-0.6 + c * 0.32, 0.34, -hd + 1.35), 0.04, 0.0, 0.08, B._c(R, "coquillage171", Color(0.98, 0.88, 0.8), 0.4), 8)
	_brasero(M, 1.15, -hd + 1.2, 0.7, "argile69_rouge")
	B._lampe(M, 0.0, 2.6, 0.0, Color(0.7, 0.9, 1.0), 0.8, 6.0)
	var ecouter := func() -> void:
		M.main.sfx("dalle_clic")
		M.say("Tu te penches sur le bassin. Au fond, une goutte tombe… plic. Puis une autre… ploc. La vieille Ix Chel murmure : « Chaac est content. Il pleuvra sur le maïs. »", 6.0)
	M.act(R.P(bx + 0.8, 0, bz), "E : écouter l'eau du cénote", ecouter, 1.0)
	B._marchand(M, 0.9, 0.6, 180.0, "prier", "vieille", "Ix Chel", ["Chaac, dieu de la pluie, aime les chansons et le copal.", "Le cénote est un puits vers le monde d'en bas. L'eau y est fraîche… et un peu bavarde."],
		{"bonjour": "Entre, mon enfant. Viens saluer Chaac.", "infos": ["Le Chac Mool tient un bol sur son ventre : on y pose les offrandes. Il ne les mange pas. Il les garde."]})
	M.ctx["cloche170"] = false
	M.ctx["bonjour170"] = ["Bienvenue au sanctuaire.", "Chut… on écoute la pluie."]
	M.ctx["entree"] = "Le sanctuaire du cénote : le Chac Mool couché, son bol d'offrandes sur le ventre, les masques de Chaac au long nez, l'eau fraîche qui goutte dans le bassin."


## Un masque de Chaac, le dieu de la pluie (le long nez recourbé, les yeux ronds).
static func _masque_chaac(M, x: float, y: float, z: float, yaw: float) -> void:
	var R = M.R
	var k = R.kit
	var st: String = _m(R, "pmaya69")
	var xf: Transform3D = R.L(x, y, z, yaw)
	R.mark_wall(x, y, z, 0.6)
	k.box(xf * B.T3(0, 0, 0.07), Vector3(0.7, 0.7, 0.14), st, 1.0)
	for sx in [-1.0, 1.0]:
		k.cyl(xf * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(sx * 0.17, 0.14, 0.14)), 0.09, 0.09, 0.04, st, 12)
		k.cyl(xf * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(sx * 0.17, 0.14, 0.18)), 0.04, 0.04, 0.01, "noir", 10)
	k.cyl(xf * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0.0, 0.14)), 0.07, 0.05, 0.28, st, 10)
	k.ring(xf * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(0, 0.06, 0.44)), 0.05, 0.09, 0.08, st, 12)
	k.box(xf * B.T3(0, -0.24, 0.15), Vector3(0.4, 0.08, 0.04), B._c(R, "levres_maya", Color(0.5, 0.1, 0.08), 0.8), 1.0)


# =================================================================== Aztlán : le calmecac (l'école des prêtres)

## Le huehuetl (le grand tambour debout, la peau de jaguar, la bande sculptée, les pieds).
static func _huehuetl(M, x: float, z: float) -> void:
	var R = M.R
	var k = R.kit
	var bois: String = _m(R, "bois69")
	for i in range(3):
		var a: float = TAU * i / 3.0
		k.box(R.L(x + cos(a) * 0.2, 0.12, z + sin(a) * 0.2, -rad_to_deg(a)), Vector3(0.14, 0.24, 0.1), bois, 1.0)
	k.cyl(R.L(x, 0.24, z), 0.25, 0.27, 0.72, bois, 18)
	k.cyl(R.L(x, 0.42, z), 0.262, 0.262, 0.22, _m(R, "frise69"), 18, false)
	k.cyl(R.L(x, 0.96, z), 0.275, 0.275, 0.02, _jaguar(R), 18)
	_taches(R, R.L(x, 0.981, z), 0.36, 0.36, 8, 3)
	k.col_box(R.L(x, 0.5, z), Vector3(0.6, 1.0, 0.6))
	R.reserve(x, z, 0.8, 0.8)


## Le teponaztli (le tambour couché, fendu en H, sur son support ; deux baguettes).
static func _teponaztli(M, x: float, z: float, yaw: float) -> void:
	var R = M.R
	var k = R.kit
	var bois: String = _m(R, "bois69")
	var xf: Transform3D = R.L(x, 0, z, yaw)
	for sx in [-1.0, 1.0]:
		k.box(xf * B.T3(sx * 0.32, 0.2, 0), Vector3(0.08, 0.4, 0.3), "bois_sombre", 1.0)
	k.cyl(xf * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(0.42, 0.52, 0)), 0.16, 0.16, 0.84, bois, 14)
	k.box(xf * B.T3(0, 0.685, 0), Vector3(0.5, 0.01, 0.025), "noir", 1.0)
	for sx2 in [-1.0, 1.0]:
		k.box(xf * B.T3(sx2 * 0.25, 0.682, 0), Vector3(0.025, 0.01, 0.16), "noir", 1.0)
		k.cyl(xf * Transform3D(Basis(Vector3.BACK, PI * 0.5 + sx2 * 0.2), Vector3(sx2 * 0.12 + 0.13, 0.7, 0.12)), 0.012, 0.012, 0.28, "bois_sombre", 6)
	k.col_box(xf * B.T3(0, 0.35, 0), Vector3(0.9, 0.7, 0.35))
	R.reserve(x, z, 1.0, 0.6)


## Un livre plié en accordéon (un codex) posé debout : un paravent de panneaux peints.
static func _paravent(M, x: float, z: float, yaw: float, n: int, w: float, h: float) -> void:
	var R = M.R
	var k = R.kit
	var cod: String = B._img(R, "codex171", "soleils/codex_soleils.png")
	var xf: Transform3D = R.L(x, 0, z, yaw)
	for i in range(n):
		var px: float = -w * n * 0.5 + (i + 0.5) * w
		var tilt: float = 0.3 if i % 2 == 0 else -0.3
		var pxf: Transform3D = xf * Transform3D(Basis(Vector3.UP, tilt), Vector3(px, 0.3 + h * 0.5, 0.0))
		k.quad(pxf * Transform3D(Basis(Vector3.UP, PI), Vector3(0, 0, 0.012)), w, h, cod, Vector2(float(i) / n, 0), Vector2(float(i + 1) / n, 1))
		k.box(pxf, Vector3(w, h, 0.02), "bois_clair", 1.0)
		k.box(pxf * B.T3(0, -h * 0.5 - 0.15, 0), Vector3(0.04, 0.3, 0.04), "bois_sombre", 1.0)
	k.col_box(xf * B.T3(0, (h + 0.3) * 0.5, 0), Vector3(w * n, h + 0.3, 0.3))
	R.reserve(x, z, w * n + 0.2, 0.6)


static func _calmecac(M) -> void:
	var R = M.R
	var k = R.kit
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var tez: String = _m(R, "tezo69")
	# les banquettes de pierre le long des murs (on s'y assied pour écouter)
	for sx in [-1.0, 1.0]:
		k.box(R.L(sx * (hw - 0.3), 0.21, -0.8), Vector3(0.6, 0.42, 3.6), tez, 1.2)
		k.box(R.L(sx * (hw - 0.6), 0.21, -0.8, -sx * 90.0), Vector3(3.6, 0.3, 0.01), _m(R, "frise69"), 1.0)
		k.col_box(R.L(sx * (hw - 0.3), 0.21, -0.8), Vector3(0.6, 0.42, 3.6))
		R.reserve(sx * (hw - 0.3), -0.8, 0.8, 3.8)
	var eleves: Array = [["garcon", -1.0, -2.0], ["fille", -1.0, -0.4], ["garcon", -1.0, 0.7], ["fille", 1.0, -1.5], ["garcon", 1.0, 0.1]]
	var mots: Array = [["Le Cinquième Soleil, c'est le nôtre. Il faut le nourrir de chansons. Enfin, je crois."], ["Moi, je préfère l'astronomie. Les étoiles ne grondent jamais."], ["J'ai entretenu le feu toute la nuit. Je ne me suis endormi que trois fois."],
		["Le calendrier a vingt signes de jours. Mon préféré, c'est le lapin."], ["Chut ! La maîtresse va poser une question."]]
	for i in range(eleves.size()):
		var e: Array = eleves[i]
		var sx2: float = float(e[1])
		var p: Node = M.person(str(e[0]), sx2 * (hw - 0.3), float(e[2]), sx2 * -90.0, "assis")
		p.lines = mots[i]
	# au fond : le grand codex peint en paravent, la Pierre du Soleil, l'étagère des livres pliés
	_paravent(M, -1.7, -hd + 0.45, 0.0, 4, 0.55, 1.3)
	_fresque(M, "soleils/pierre_soleil.png", 2.0, 2.45, -hd + 0.02, 0.0, 1.7, 1.7, "", 1)
	R.etagere(hw - 1.55, -hd + 0.25, 0.0, 1.2, 1.7, false, 3)
	for sh in range(3):
		for b in range(5):
			var c: Color = [Color(0.85, 0.75, 0.55), Color(0.7, 0.2, 0.12), Color(0.15, 0.35, 0.5), Color(0.9, 0.7, 0.2)][(sh + b) % 4]
			k.box(R.L(hw - 2.0 + b * 0.22, 0.12 + sh * 0.53 + 0.11, -hd + 0.25), Vector3(0.16, 0.2, 0.24), B._c(R, "codex_dos_%d" % ((sh + b) % 4), c, 0.85), 1.0)
	# les fresques des dieux au-dessus des banquettes, les braseros, les tambours
	_fresque(M, "soleils/fresque_huitzilopochtli.png", -hw + 0.02, 2.55, -0.8, 90.0, 2.8, 1.4, _m(R, "frise69"))
	_fresque(M, "soleils/fresque_tlaloc.png", hw - 0.02, 2.55, -0.8, -90.0, 2.8, 1.4, _m(R, "frise69"))
	for sx3 in [-1.0, 1.0]:
		_natte(R, sx3 * 1.9, -0.3, 0.0, 1.4, 1.4)
		_brasero(M, sx3 * 1.9, -0.3, 0.75, "argile69_rouge")
	_huehuetl(M, -hw + 1.2, hd - 1.0)
	_teponaztli(M, hw - 1.4, hd - 1.0, 0.0)
	var lecon := func() -> void:
		var st: Dictionary = M.state()
		var n: int = int(st.get("lecon171", 0))
		st["lecon171"] = n + 1
		var t: Array = ["Citlali montre la Pierre du Soleil : « Au milieu, c'est le visage du Soleil. Autour, les quatre soleils d'avant : les jaguars, le vent, la pluie de feu, l'eau. »",
			"« Vingt signes de jours, treize nombres : un, crocodile ; deux, vent ; trois, maison… Au bout de deux cent soixante jours, on recommence. Comme une chanson. »",
			"« Un bon prêtre sait trois choses : lire le ciel, garder le feu, et se taire quand il le faut. La troisième est la plus difficile. »"]
		M.say(str(t[n % t.size()]), 8.0)
	M.act(R.P(0.4, 0, -hd + 2.0), "E : écouter la leçon de Citlali", lecon, 1.2)
	B._marchand(M, 0.4, -hd + 1.3, 0.0, "enseigner", "femme", "Citlali", ["On apprend ici à lire le ciel et à compter les jours.", "Le feu du calmecac ne s'éteint jamais. Jamais ! Bon… presque jamais.", "Assieds-toi sur la banquette, et ouvre bien les oreilles."],
		{"bonjour": "Bienvenue au calmecac. Ici, on apprend.", "vend": {"galette_mais": 2}, "infos": ["Les livres pliés se lisent comme on marche : de droite à gauche, et en zigzag."]})
	M.ctx["cloche170"] = false
	M.ctx["bonjour170"] = ["Entre, et assieds-toi avec les autres.", "Bienvenue au calmecac !"]
	M.ctx["entree"] = "Le calmecac : les élèves assis sur les banquettes, le grand codex déplié en paravent, la Pierre du Soleil au mur, les braseros qu'on ne laisse jamais s'éteindre."


# =================================================================== Aztlán : le palais

## Un bouclier de plumes (chimalli) accroché au mur : la mosaïque de plumes, l'or, les plumes qui pendent.
static func _bouclier(M, x: float, y: float, z: float, yaw: float, s: float = 1.0) -> void:
	var R = M.R
	var k = R.kit
	var xf: Transform3D = R.L(x, y, z, yaw)
	R.mark_wall(x, y, z, 0.6 * s)
	var dr := Basis(Vector3.RIGHT, PI * 0.5)
	k.cyl(xf * Transform3D(dr, Vector3(0, 0, 0.01)), 0.45 * s, 0.45 * s, 0.05, _m(R, "turq69"), 28)
	k.ring(xf * Transform3D(dr, Vector3(0, 0, 0.06)), 0.32 * s, 0.4 * s, 0.015, _m(R, "or69"), 28)
	k.ring(xf * Transform3D(dr, Vector3(0, 0, 0.06)), 0.12 * s, 0.2 * s, 0.015, _m(R, "plume69_rouge"), 20)
	k.cyl(xf * Transform3D(dr, Vector3(0, 0, 0.06)), 0.08 * s, 0.08 * s, 0.02, _m(R, "or69"), 16)
	var cols: Array = ["plume69", "plume69_rouge", "plume69_jaune", "plume69_bleu"]
	for i in range(7):
		var px: float = (-0.3 + i * 0.1) * s
		k.box(xf * Transform3D(Basis(Vector3.BACK, (i - 3) * 0.06), Vector3(px, -0.62 * s, 0.03)), Vector3(0.07 * s, 0.34 * s, 0.01), _m(R, str(cols[i % 4])), 1.0)


## La coiffe de plumes de quetzal (le penacho) sur son support.
static func _penacho(M, x: float, y0: float, z: float) -> void:
	var R = M.R
	var k = R.kit
	k.cyl(R.L(x, y0, z), 0.16, 0.14, 0.08, "bois_sombre", 10)
	k.cyl(R.L(x, y0 + 0.08, z), 0.025, 0.025, 1.3, "bois_sombre", 6)
	var c: Vector3 = Vector3(x, y0 + 1.45, z)
	for i in range(25):
		var a: float = deg_to_rad(-85.0 + i * (170.0 / 24.0))
		var l: float = 0.75 + 0.08 * float(i % 3)
		k.box(R.L(c.x, c.y, c.z) * Transform3D(Basis(Vector3.BACK, a), Vector3(-sin(a) * (0.18 + l * 0.5), cos(a) * (0.18 + l * 0.5), 0)), Vector3(0.06, l, 0.008), _m(R, "plume69"), 1.0)
		k.box(R.L(c.x, c.y, c.z + 0.012) * Transform3D(Basis(Vector3.BACK, a), Vector3(-sin(a) * (0.2 + l * 0.15), cos(a) * (0.2 + l * 0.15), 0)), Vector3(0.05, 0.14, 0.006), _m(R, "plume69_bleu"), 1.0)
	k.ring(R.L(c.x, c.y, c.z + 0.02) * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 0.12, 0.2, 0.02, _m(R, "or69"), 20)
	for j in range(9):
		var a2: float = deg_to_rad(-80.0 + j * 20.0)
		k.box(R.L(c.x - sin(a2) * 0.16, c.y + cos(a2) * 0.16, c.z + 0.035), Vector3(0.035, 0.035, 0.01), _m(R, "or69"), 1.0)
	k.col_box(R.L(x, y0 + 0.7, z), Vector3(0.3, 1.4, 0.3))
	R.reserve(x, z, 0.5, 0.5)


## La tenue d'un guerrier-aigle ou d'un guerrier-jaguar, sur son support.
static func _costume(M, x: float, z: float, yaw: float, sorte: String) -> void:
	var R = M.R
	var k = R.kit
	var xf: Transform3D = R.L(x, 0, z, yaw)
	var t: String = _jaguar(R) if sorte == "jaguar" else B._c(R, "plumes_aigle", Color(0.48, 0.34, 0.22), 0.9)
	k.cyl(xf, 0.24, 0.26, 0.05, "bois_sombre", 12)
	k.cyl(xf * B.T3(0, 0.05, 0), 0.025, 0.025, 0.4, "bois_sombre", 6)
	k.cyl(xf * B.T3(0, 0.45, 0), 0.2, 0.2, 0.5, t, 14)
	k.cyl(xf * B.T3(0, 0.95, 0), 0.2, 0.22, 0.42, t, 14)
	k.box(xf * B.T3(0, 1.36, 0), Vector3(0.56, 0.1, 0.24), t, 1.0)
	for sx in [-1.0, 1.0]:
		k.box(xf * B.T3(sx * 0.3, 1.06, 0), Vector3(0.11, 0.56, 0.12), t, 1.0)
	if sorte == "jaguar":
		_taches(R, xf * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0.95, 0.225)), 0.36, 0.7, 14, 11)
	var hx: Transform3D = xf * B.T3(0, 1.58, 0)
	k.box(hx, Vector3(0.3, 0.32, 0.32), t, 1.0)
	k.box(hx * B.T3(0, -0.02, 0.12), Vector3(0.2, 0.18, 0.1), "noir", 1.0)
	if sorte == "jaguar":
		for sx2 in [-1.0, 1.0]:
			k.box(hx * B.T3(sx2 * 0.11, 0.2, -0.04), Vector3(0.08, 0.08, 0.05), t, 1.0)
		k.box(hx * B.T3(0, -0.15, 0.13), Vector3(0.26, 0.05, 0.14), t, 1.0)
		for f in range(2):
			k.cyl(hx * Transform3D(Basis(Vector3.RIGHT, PI), Vector3(-0.06 + f * 0.12, 0.12, 0.17)), 0.015, 0.0, 0.06, "ceramique", 6)
	else:
		k.box(hx * B.T3(0, 0.12, 0.2), Vector3(0.14, 0.08, 0.2), _m(R, "plume69_jaune"), 1.0)
		k.box(hx * Transform3D(Basis(Vector3.RIGHT, 0.6), Vector3(0, 0.07, 0.3)), Vector3(0.1, 0.06, 0.12), _m(R, "plume69_jaune"), 1.0)
		k.box(hx * B.T3(0, -0.14, 0.18), Vector3(0.14, 0.04, 0.16), _m(R, "plume69_jaune"), 1.0)
		for p in range(5):
			k.box(hx * Transform3D(Basis(Vector3.RIGHT, -0.4), Vector3(-0.1 + p * 0.05, 0.2, -0.18)), Vector3(0.04, 0.3, 0.008), "tissu_blanc" if p % 2 == 0 else t, 1.0)
	k.col_box(xf * B.T3(0, 0.85, 0), Vector3(0.6, 1.7, 0.5))
	R.reserve(x, z, 0.8, 0.8)


static func _palais_azteque(M) -> void:
	var R = M.R
	var k = R.kit
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var dal: String = _m(R, "dalles69")
	# l'estrade, le trône de roseaux tressés (l'icpalli), la peau de jaguar
	var dz: float = -hd + 0.9
	k.box(R.L(0.0, 0.12, dz), Vector3(4.0, 0.24, 1.8), dal, 1.5)
	k.box(R.L(0.0, 0.12, dz + 0.905), Vector3(4.0, 0.2, 0.01), _m(R, "frise69"), 1.0)
	k.col_box(R.L(0.0, 0.12, dz), Vector3(4.0, 0.24, 1.8))
	R.reserve(0.0, dz, 4.2, 2.0)
	var nat: String = B._tex(R, "natte171", "beau171/natte.png", Color(1, 1, 1), 0.95)
	k.box(R.L(0.0, 0.39, dz - 0.05), Vector3(0.95, 0.3, 0.8), nat, 0.6)
	k.box(R.L(0.0, 1.1, dz - 0.5) * Transform3D(Basis(Vector3.RIGHT, -0.15), Vector3.ZERO), Vector3(0.95, 1.5, 0.14), nat, 0.6)
	var jag: String = _jaguar(R)
	k.box(R.L(0.0, 0.55, dz + 0.05), Vector3(0.8, 0.03, 1.1), jag, 1.0)
	_taches(R, R.L(0.0, 0.567, dz + 0.05), 0.8, 1.1, 14, 5)
	_penacho(M, 1.4, 0.24, dz - 0.2)
	for sx in [-1.0, 1.0]:
		_bouclier(M, sx * 2.8, 2.5, -hd + 0.01, 0.0, 1.0)
		_brasero(M, sx * 2.4, dz + 0.5, 0.8, "argile69_rouge")
		k.box(R.L(sx * 3.2, R.H * 0.5, 0.2), Vector3(0.6, R.H, 0.6), _m(R, "stucr69"), 1.5)
		k.box(R.L(sx * 3.2, 2.2, 0.2), Vector3(0.62, 0.5, 0.62), _m(R, "frise69"), 1.0)
		k.col_box(R.L(sx * 3.2, R.H * 0.5, 0.2), Vector3(0.6, R.H, 0.6))
		R.reserve(sx * 3.2, 0.2, 0.8, 0.8)
	_bouclier(M, -hw + 0.01, 2.6, -1.8, 90.0, 0.8)
	_bouclier(M, hw - 0.01, 2.6, -1.8, -90.0, 0.8)
	_costume(M, -hw + 0.8, 0.6, 90.0, "aigle")
	_costume(M, hw - 0.8, 0.6, -90.0, "jaguar")
	_fresque(M, "soleils/fresque_huitzilopochtli.png", 0.0, 2.75, -hd + 0.02, 0.0, 2.4, 1.2, _m(R, "or69"))
	_huehuetl(M, -hw + 1.3, hd - 1.1)
	_teponaztli(M, hw - 1.5, hd - 1.1, 0.0)
	_natte(R, 0.0, 0.6, 0.0, 3.0, 2.0)
	B._lampe(M, 0.0, 3.6, 0.0, Color(1.0, 0.82, 0.55), 1.0, 10.0)
	var admirer := func() -> void:
		M.say("La coiffe du tlatoani : quatre cents plumes de quetzal, vertes comme la forêt, cousues une à une sur un filet d'or. Mixtli chuchote : « Personne n'a le droit de la porter. Même pas pour rire. »", 7.0)
	M.act(R.P(1.4, 0, dz + 1.25), "E : admirer la coiffe de plumes", admirer, 1.0)
	B._marchand(M, -1.3, dz + 1.15, 15.0, "bras_croises", "homme", "Mixtli", ["Un guerrier-jaguar ne dort jamais. Il fait juste semblant, très bien.", "Ce trône attend le tlatoani. Il est parti… inspecter les chinampas. Depuis ce matin.", "Les boucliers de plumes ? Plus beaux que solides. Comme certains guerriers."],
		{"bonjour": "Halte ! … Ah, un visiteur. Entre, et ne touche à rien.", "infos": ["Les guerriers-aigles servent le soleil du jour, les guerriers-jaguars celui de la nuit."]})
	var gm: Node = M.person("garcon", hw - 1.7, 1.3, -60.0, "pointer", "Petit Ollin")
	gm.lines = ["Quand je serai grand, je serai guerrier-aigle ! Ou guerrier-jaguar. Ou les deux, le mardi."]
	M.ctx["cloche170"] = false
	M.ctx["bonjour170"] = ["Bienvenue au palais d'Aztlán.", "Halte-là ! … Bon, tu peux entrer."]
	M.ctx["entree"] = "Le palais d'Aztlán : le trône de roseaux et sa peau de jaguar, la coiffe de plumes de quetzal, les boucliers de plumes, les tenues des guerriers-aigles et des guerriers-jaguars."


# =================================================================== Arcanelle : les aides

## Un repère posé sur le mur rond (angle a en degrés depuis la porte, rayon r), qui regarde le milieu.
static func _sur_rond(M, a: float, r: float, y: float) -> Transform3D:
	var ar: float = deg_to_rad(a)
	return M.R.L(sin(ar) * r, y, cos(ar) * r, a + 180.0)


## Un vitrail en ogive sur le mur rond (il s'allume un peu, comme si le jour passait derrière).
static func _vitrail(M, a: float, r: float, y: float, w: float, h: float) -> void:
	var R = M.R
	var k = R.kit
	if R.mat("vitrail171") == null:
		var m := StandardMaterial3D.new()
		if ResourceLoader.exists("res://assets/textures/arcanelle/vitrail.png"):
			var tx: Texture2D = load("res://assets/textures/arcanelle/vitrail.png")
			m.albedo_texture = tx
			m.emission_texture = tx
		m.emission_enabled = true
		m.emission = Color(1, 1, 1)
		m.emission_energy_multiplier = 0.9 if R.day else 0.25
		R._put("vitrail171", m)
	var xf: Transform3D = _sur_rond(M, a, r - 0.02, y)
	k.quad(xf * Transform3D(Basis(Vector3.UP, PI), Vector3(0, 0, 0.01)), w, h, "vitrail171")
	k.box(xf * B.T3(0, -h * 0.5 - 0.05, 0.05), Vector3(w + 0.3, 0.1, 0.18), "bas", 1.0)
	for sx in [-1.0, 1.0]:
		k.box(xf * B.T3(sx * (w * 0.5 + 0.06), 0, 0.03), Vector3(0.12, h, 0.1), "bas", 1.0)
	k.box(xf * B.T3(0, h * 0.5 + 0.06, 0.03), Vector3(w + 0.24, 0.12, 0.1), "bas", 1.0)
	B._lampe(M, sin(deg_to_rad(a)) * (r - 0.8), y, cos(deg_to_rad(a)) * (r - 0.8), Color(0.75, 0.7, 1.0), 0.6 if R.day else 0.2, 3.5)


## Des livres qui flottent (des nœuds à part, qui montent et descendent doucement).
static func _livres_volants(M, centre: Vector3, n: int, rayon: float) -> void:
	var R = M.R
	var cols: Array = [Color(0.55, 0.12, 0.15), Color(0.15, 0.25, 0.5), Color(0.2, 0.42, 0.25), Color(0.5, 0.3, 0.55), Color(0.62, 0.45, 0.2)]
	for i in range(n):
		var a: float = TAU * i / n
		var b := Node3D.new()
		M.room.add_child(b)
		b.global_position = R.P(centre.x + cos(a) * rayon, centre.y + 0.2 * float(i % 3), centre.z + sin(a) * rayon)
		b.rotation = Vector3(0.2 * float(i % 2), -a, 0.15)
		for s in [-1.0, 1.0]:
			var page := MeshInstance3D.new()
			page.mesh = B._boitem(0.16, 0.012, 0.22)
			page.material_override = R.mat(B._c(R, "couv_%d" % (i % cols.size()), cols[i % cols.size()], 0.7))
			page.position = Vector3(s * 0.075, 0.02, 0)
			page.rotation.z = s * 0.25
			b.add_child(page)
			var feuilles := MeshInstance3D.new()
			feuilles.mesh = B._boitem(0.145, 0.016, 0.2)
			feuilles.material_override = R.mat("papier")
			feuilles.position = Vector3(s * 0.07, 0.034, 0)
			feuilles.rotation.z = s * 0.25
			b.add_child(feuilles)
		(M.ctx["anims170"] as Array).append([b, "flotte", 0.08, b.position.y, i * 1.3])


## Des boules de lumière qui flottent (la magie d'Arcanelle) ; c : leur couleur.
static func _lueurs(M, centre: Vector3, n: int, rayon: float, c: Color) -> void:
	var R = M.R
	var m: Material = R.mat(B._c(R, "lueur_%s" % c.to_html(false), c, 0.3, 0.0, 3.0))
	for i in range(n):
		var a: float = TAU * i / n + 0.4
		var p: Vector3 = R.P(centre.x + cos(a) * rayon, centre.y + 0.3 * float(i % 2), centre.z + sin(a) * rayon)
		var bl: MeshInstance3D = Sud._boule(M.room, m, p, 0.06 + 0.02 * float(i % 2))
		(M.ctx["anims170"] as Array).append([bl, "flotte", 0.15, bl.position.y, i * 1.9])
	B._lampe(M, centre.x, centre.y, centre.z, c, 0.7, rayon * 3.0 + 2.0)


## Une sphère armillaire dont les anneaux tournent (sur son pied) ; le cristal au milieu.
static func _armillaire(M, x: float, z: float, s: float = 1.0) -> void:
	var R = M.R
	var k = R.kit
	k.cyl(R.L(x, 0, z), 0.32 * s, 0.38 * s, 0.08, "bois_sombre", 16)
	k.cyl(R.L(x, 0.08, z), 0.05 * s, 0.04 * s, 0.9 * s, "or", 10)
	k.cyl(R.L(x, 0.98 * s, z), 0.14 * s, 0.05 * s, 0.08 * s, "or", 12)
	var c: Vector3 = R.P(x, 1.45 * s, z)
	var orm: Material = R.mat("or")
	for i in range(3):
		var piv := Node3D.new()
		M.room.add_child(piv)
		piv.global_position = c
		var t := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = (0.4 - i * 0.06) * s
		tm.outer_radius = (0.43 - i * 0.06) * s
		tm.rings = 32
		tm.ring_segments = 6
		t.mesh = tm
		t.material_override = orm
		t.rotation = [Vector3(PI * 0.5, 0, 0), Vector3(0, 0, PI * 0.5), Vector3(0.4, 0, 0.3)][i]
		piv.add_child(t)
		(M.ctx["anims170"] as Array).append([piv, "tourne", [Vector3.UP, Vector3(0.3, 1, 0).normalized(), Vector3(1, 0.4, 0).normalized()][i], 0.3 + 0.2 * i])
	var cr: MeshInstance3D = Sud._boule(M.room, R.mat(B._verre(R, "cristal_arc", Color(0.75, 0.6, 1.0), 0.7, 2.0)), c, 0.12 * s)
	cr.name = "Cristal"
	B._lampe(M, x, 1.45 * s, z, Color(0.75, 0.6, 1.0), 0.8, 4.0)
	k.col_box(R.L(x, 0.7 * s, z), Vector3(0.9, 1.4, 0.9) * s)
	R.reserve(x, z, 1.2 * s, 1.2 * s)


## Un cercle de runes au sol (une image qui luit un peu).
static func _runes_sol(M, x: float, z: float, d: float, c: Color) -> void:
	var R = M.R
	if R.mat("runes171") == null:
		var m := StandardMaterial3D.new()
		if ResourceLoader.exists("res://assets/textures/arcanelle/runes.png"):
			var tx: Texture2D = load("res://assets/textures/arcanelle/runes.png")
			m.albedo_texture = tx
			m.emission_texture = tx
		m.albedo_color = c
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = 0.7
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		R._put("runes171", m)
	R.kit.quad(R.L(x, 0.015, z) * Transform3D(Basis(Vector3.UP, PI) * Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), d, d, "runes171")


## Une chouette sur son perchoir (le corps, la tête, les aigrettes, les yeux jaunes).
static func _chouette(M, x: float, z: float, yaw: float) -> void:
	var R = M.R
	var k = R.kit
	k.cyl(R.L(x, 0, z), 0.18, 0.2, 0.05, "bois_sombre", 10)
	k.cyl(R.L(x, 0.05, z), 0.025, 0.025, 1.5, "bois_sombre", 6)
	k.box(R.L(x, 1.55, z, yaw), Vector3(0.5, 0.04, 0.04), "bois_sombre", 1.0)
	var plume: Material = R.mat(B._c(R, "chouette171", Color(0.5, 0.38, 0.26), 0.9))
	var corps: MeshInstance3D = Sud._boule(M.room, plume, R.P(x, 1.72, z), 0.13, Vector3(1.0, 1.3, 0.95))
	corps.name = "Chouette"
	var tete: MeshInstance3D = Sud._boule(M.room, plume, R.P(x, 1.94, z), 0.1)
	var f: Vector3 = Basis(Vector3.UP, deg_to_rad(yaw)) * Vector3(0, 0, 1)
	var sd: Vector3 = Basis(Vector3.UP, deg_to_rad(yaw)) * Vector3(1, 0, 0)
	for s in [-1.0, 1.0]:
		Sud._boule(M.room, R.mat(B._c(R, "oeil_chouette", Color(1.0, 0.8, 0.15), 0.3, 0.0, 0.6)), R.P(x, 1.96, z) + f * 0.085 + sd * s * 0.04, 0.025)
		Sud._boule(M.room, R.mat("noir"), R.P(x, 1.96, z) + f * 0.1 + sd * s * 0.04, 0.012)
		k.cyl(Transform3D(Basis(Vector3.UP, deg_to_rad(yaw)) * Basis(Vector3.BACK, -s * 0.3), R.P(x, 2.0, z) + sd * s * 0.06), 0.025, 0.0, 0.08, "chouette171", 6)
	k.cyl(Transform3D(Basis(Vector3.UP, deg_to_rad(yaw)) * Basis(Vector3.RIGHT, PI * 0.5), R.P(x, 1.93, z) + f * 0.09), 0.015, 0.0, 0.03, "or", 6)
	k.col_box(R.L(x, 0.8, z), Vector3(0.3, 1.6, 0.3))
	R.reserve(x, z, 0.5, 0.5)
	tete.name = "Tete_chouette"


# =================================================================== Arcanelle : la Tour d'Astrelune

static func _tour_archimage(M) -> void:
	var R = M.R
	var k = R.kit
	var r: float = _rond(M, 22.0)
	# les bibliothèques le long du mur rond, le vitrail au fond, les bannières
	for a in [58.0, 76.0, 94.0, 112.0, 130.0, 230.0, 248.0, 266.0, 284.0, 302.0]:
		var ar: float = deg_to_rad(a)
		B._rayons(M, sin(ar) * (r - 0.22), cos(ar) * (r - 0.22), a + 180.0, 1.3, 2.8, 6, "livres")
	_vitrail(M, 180.0, r, 3.4, 1.3, 2.8)
	for a2 in [158.0, 202.0]:
		var bx: Transform3D = _sur_rond(M, a2, r - 0.03, 3.4)
		k.quad(bx * Transform3D(Basis(Vector3.UP, PI), Vector3(0, 0, 0.01)), 0.8, 2.4, B._img(R, "banniere171", "arcanelle/banniere.png"))
	# le cercle de runes, la sphère armillaire, les livres qui flottent, les lueurs
	_runes_sol(M, 0.0, -0.5, 3.2, Color(0.7, 0.55, 1.0))
	_armillaire(M, 0.0, -0.5, 1.1)
	_livres_volants(M, Vector3(0.0, 2.3, -0.5), 6, 1.3)
	_lueurs(M, Vector3(0.0, 4.6, 0.0), 6, 2.0, Color(0.8, 0.7, 1.0))
	# le bureau : le grimoire ouvert, la boule de cristal, les bougies, la plume
	var tx: float = 2.3
	var tz: float = 1.3
	R.table(tx, tz, -60.0, 1.4, 0.8)
	R.chaise(tx + 0.55, tz + 0.32, -60.0 + 180.0, "violet")
	k.box(R.L(tx, 0.79, tz, -60.0), Vector3(0.5, 0.04, 0.34), "papier", 1.0)
	k.box(R.L(tx, 0.775, tz, -60.0), Vector3(0.54, 0.03, 0.38), B._c(R, "couv_grimoire", Color(0.4, 0.1, 0.25), 0.7), 1.0)
	Sud._boule(M.room, R.mat(B._verre(R, "boule_cristal", Color(0.8, 0.85, 1.0), 0.5, 0.6)), R.P(tx - 0.25, 0.92, tz - 0.35), 0.12)
	k.cyl(R.L(tx - 0.25, 0.78, tz - 0.35), 0.08, 0.06, 0.04, "or", 10)
	R.bougie(tx + 0.3, 0.78, tz + 0.15)
	R.bougie(tx + 0.42, 0.78, tz + 0.05)
	_chouette(M, -2.6, 1.6, 120.0)
	# l'échelle de corde vers la trappe du haut de la tour
	var lx: float = -2.5
	var lz: float = -2.4
	for s in [-1.0, 1.0]:
		k.cyl(R.L(lx + s * 0.22, 0, lz), 0.02, 0.02, R.H, B._tex(R, "corde170", "beau161/corde.png", Color(0.9, 0.8, 0.62)), 6)
	for g in range(int(R.H / 0.35)):
		k.box(R.L(lx, 0.3 + g * 0.35, lz), Vector3(0.46, 0.04, 0.06), "bois", 1.0)
	k.box(R.L(lx, R.H - 0.02, lz), Vector3(0.9, 0.04, 0.9), "bois_sombre", 1.0)
	var grimoire := func() -> void:
		var st: Dictionary = M.state()
		var n: int = int(st.get("grimoire171", 0))
		st["grimoire171"] = n + 1
		var t: Array = ["« Sortilège de la Tasse Toujours Chaude » : il suffit de la tenir à deux mains, et de penser à quelqu'un qu'on aime.", "« Comment apprendre à voler » : chapitre 1, apprendre à tomber. Chapitre 2, voir chapitre 1.",
			"Une page couverte de petites étoiles dessinées à l'encre d'or. Dans la marge, une écriture d'enfant : « Séraphine, 9 ans, a tout compris. »"]
		M.say(str(t[n % t.size()]), 7.0)
	M.act(R.P(tx - 0.55, 0, tz - 0.6), "E : feuilleter le grimoire", grimoire, 1.0)
	B._marchand(M, -1.6, 0.6, 30.0, "enseigner", "femme", "Séraphine Astrelune", ["Les livres de cette tour ont plus de mille ans. Certains ronflent.", "La magie, c'est d'abord de la patience. Puis un peu de poussière d'étoile.", "Ne parle pas trop fort : les livres du haut sont timides."],
		{"bonjour": "Bienvenue dans la Tour d'Astrelune, jeune voyageur.", "vend": {"potion_mana": 12}, "infos": ["La sphère armillaire montre le chemin des étoiles. Elle ne s'arrête jamais de tourner, même quand je dors."]})
	M.ctx["cloche170"] = false
	M.ctx["bonjour170"] = ["Ah ! Je t'attendais. Enfin… les étoiles t'attendaient.", "Entre. Attention aux livres qui volent."]
	M.ctx["entree"] = "La Tour d'Astrelune : les bibliothèques tout autour, les livres qui flottent, la sphère armillaire au-dessus du cercle de runes, le grand vitrail, la chouette sur son perchoir."


# =================================================================== Arcanelle : le dortoir des apprentis

## Un balai de sorcier appuyé au mur.
static func _balai(M, x: float, z: float, yaw: float) -> void:
	var R = M.R
	var k = R.kit
	var xf: Transform3D = R.L(x, 0, z, yaw) * Transform3D(Basis(Vector3.RIGHT, -0.22), Vector3.ZERO)
	k.cyl(xf * B.T3(0, 0.25, 0), 0.02, 0.018, 1.4, "bois", 6)
	k.cyl(xf, 0.12, 0.04, 0.4, B._c(R, "paille171", Color(0.85, 0.72, 0.4), 0.95), 10)
	k.ring(xf * B.T3(0, 0.36, 0), 0.03, 0.05, 0.04, "cuivre", 8)


static func _dortoir(M) -> void:
	var R = M.R
	var k = R.kit
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	# les lits : le lit superposé, deux lits simples ; les malles au pied des lits
	R.lit(-hw + 1.0, -2.2, 90.0, 1.0, "violet", true)
	R.lit(-hw + 1.0, 0.3, 90.0, 1.0, "bleu")
	R.lit(hw - 1.0, -2.2, -90.0, 1.0, "vert")
	R.coffre_deco(-hw + 2.4, -2.2, -90.0)
	R.coffre_deco(-hw + 2.4, 0.3, -90.0)
	R.coffre_deco(hw - 2.4, -2.2, 90.0)
	# Oscar fait la sieste (en plein jour)
	var o: Node = B._habitue(M, "oscar", -hw + 1.2, 0.3, 90.0, "dormir", ["Zzz… non, Maître… c'est le chaudron qui a commencé… Zzz…"])
	if o != null:
		o.lie(R.P(-hw + 1.85, 0.45, 0.3), Vector3(-1, 0, 0))
	# le petit labo de Mirabelle (contre le fond) : la fumée verte, la tache de suie au mur
	R.table(1.0, -hd + 0.6, 0.0, 1.3, 0.6, 0.8)
	M.ctx["fiole_emit"] = 0.8
	B._fioles(R, R.L(0.55, 0.8, -hd + 0.5), 6, 0.11, 2, 0.8)
	k.cyl(R.L(1.3, 0.8, -hd + 0.6), 0.1, 0.12, 0.04, "fer", 10)
	R.fire(R.P(1.3, 0.86, -hd + 0.6), 0.12)
	var bal: MeshInstance3D = Sud._boule(M.room, R.mat(B._verre(R, "ballon_vert", Color(0.3, 0.95, 0.4), 0.55, 1.2)), R.P(1.3, 1.02, -hd + 0.6), 0.1)
	bal.name = "Ballon"
	var nuage: MeshInstance3D = Sud._boule(M.room, R.mat(B._verre(R, "fumee_verte", Color(0.5, 1.0, 0.5), 0.25, 0.5)), R.P(1.3, 1.5, -hd + 0.6), 0.22, Vector3(1.3, 0.8, 1.0))
	(M.ctx["anims170"] as Array).append([nuage, "flotte", 0.12, nuage.position.y, 0.0])
	var suie: String = B._img(R, "suie171", "beau170/suie.png", 2)
	k.quad(R.L(1.2, 2.0, -hd + 0.025) * Transform3D(Basis(Vector3.UP, PI), Vector3.ZERO), 1.3, 1.1, suie)
	B._habitue(M, "mirabelle", 1.0, -hd + 1.25, 180.0, "cuisiner", ["Ça va marcher, cette fois. Recule un peu, quand même.", "Si ça devient bleu, c'est réussi. Si ça devient vert… on ouvre la fenêtre."])
	# le bureau de Lin, sa chaise, ses livres en pile
	R.table(hw - 0.55, 0.6, -90.0, 1.1, 0.6, 0.76)
	R.chaise(hw - 1.3, 0.6, -90.0, "bleu")
	for p in range(4):
		k.box(R.L(hw - 0.5, 0.78 + p * 0.05, 0.25, 10.0 * p), Vector3(0.22, 0.045, 0.3), "tissu_" + ["rouge", "bleu", "vert", "brun"][p], 1.0)
	R.bougie(hw - 0.45, 0.76, 0.95)
	B._habitue(M, "lin", hw - 1.3, 0.6, -90.0, "lire", ["Chut… je révise le chapitre sept : les sortilèges de lévitation.", "Pip ronfle. Oscar parle en dormant. Mirabelle fait exploser des choses. Et moi, je lis."])
	# les chapeaux pointus aux patères, les balais, la corde à chaussettes, la carte du ciel
	for c in range(4):
		var cx: float = -2.6 + c * 0.55 if c < 2 else 1.8 + (c - 2) * 0.55
		k.cyl(R.L(cx, 1.75, hd - 0.04) * Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), Vector3.ZERO), 0.015, 0.015, 0.12, "bois_sombre", 6)
		B._chapeau(R, R.L(cx, 1.62, hd - 0.2) * Transform3D(Basis(Vector3.RIGHT, -0.3), Vector3.ZERO), "pointu", [Color(0.32, 0.2, 0.55), Color(0.15, 0.25, 0.5), Color(0.5, 0.12, 0.2), Color(0.18, 0.4, 0.3)][c], Color(0.9, 0.75, 0.3))
	_balai(M, -hw + 0.25, 1.8, 90.0)
	_balai(M, -hw + 0.3, 2.15, 80.0)
	k.cyl(R.L(-2.0, 2.45, -0.9) * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(2.0, 0, 0)), 0.006, 0.006, 4.0, "tissu_creme", 4, false)
	for ch in range(6):
		var col: Color = [Color(0.8, 0.2, 0.2), Color(0.2, 0.5, 0.8), Color(0.9, 0.8, 0.2), Color(0.5, 0.25, 0.6)][ch % 4]
		var chx: float = -3.6 + ch * 0.6
		k.box(R.L(chx, 2.3, -0.9), Vector3(0.1, 0.28, 0.03), B._c(R, "chaussette_%d" % (ch % 4), col, 0.95), 1.0)
		k.box(R.L(chx + 0.04, 2.17, -0.9), Vector3(0.16, 0.08, 0.03), B._c(R, "chaussette_%d" % (ch % 4), col, 0.95), 1.0)
	B._cadre(R, B._img(R, "carte_ciel_arc", "arcanelle/carte_ciel.png"), -hw + 0.02, 2.05, -0.95, 90.0, 0.9, 0.7, "bois_sombre")
	Sud._boule(M.room, R.mat(B._verre(R, "cristal_lampe", Color(0.7, 0.6, 1.0), 0.6, 1.5)), R.P(0.0, R.H - 0.5, 0.0), 0.1)
	B._lampe(M, 0.0, R.H - 0.6, 0.0, Color(0.8, 0.7, 1.0), 0.5, 5.0)
	R.tapis(0.0, 0.4, 0.0, 2.0, 1.4)
	B._marchand(M, 0.3, 0.9, 190.0, "pointer", "garcon", "Pip Grelot", ["Bienvenue au dortoir ! Ne marche pas sur les chaussettes.", "Le lit du haut, c'est le mien. Je suis plus près des étoiles.", "Oscar dort encore. Il dit qu'il « médite profondément »."],
		{"bonjour": "Salut ! Tu viens voir le dortoir ?", "infos": ["La nuit, on se raconte des histoires de fantômes. Mais des gentils fantômes."]})
	M.ctx["cloche170"] = false
	M.ctx["bonjour170"] = ["Oh, de la visite ! Range vite tes chaussettes, Oscar !", "Salut ! Fais pas attention au désordre."]
	M.ctx["entree"] = "Le dortoir des apprentis : le lit superposé, les malles, les chapeaux pointus aux patères, les chaussettes qui sèchent, le petit labo de Mirabelle… et Oscar qui fait la sieste."


# =================================================================== Arcanelle : l'Observatoire d'Aurélien Lumen

static func _observatoire_arc(M) -> void:
	var R = M.R
	var k = R.kit
	var r: float = _rond(M, 24.0)
	# la coupole peinte d'étoiles, la fente ouverte sur le ciel
	var etoile: String = B._c(R, "etoile170", Color(1.0, 0.95, 0.8), 0.4, 0.0, 3.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 171
	for s in range(70):
		var a: float = rng.randf() * TAU
		var d: float = sqrt(rng.randf()) * (r - 0.3)
		var rr: float = rng.randf_range(0.015, 0.045)
		k.cyl(R.L(cos(a) * d, R.H - 0.005, sin(a) * d), rr, rr, 0.004, etoile, 6)
	var h: float = float(M.ctx.get("hour", 12.0))
	var nuit: bool = h >= 20.0 or h < 6.0
	k.box(R.L(0, R.H - 0.01, -r * 0.5), Vector3(0.9, 0.02, r), B._c(R, "fente_nuit" if nuit else "fente_jour", Color(0.05, 0.07, 0.2) if nuit else Color(0.55, 0.75, 1.0), 0.9, 0.0, 0.4 if nuit else 1.4), 1.0)
	# la grande lunette de laiton qui vise la fente
	var lz: float = -0.6
	k.cyl(R.L(0, 0, lz), 0.55, 0.65, 0.35, "fer", 18)
	k.cyl(R.L(0, 0.35, lz), 0.16, 0.2, 1.3, "fer", 12)
	k.box(R.L(0, 1.75, lz), Vector3(0.45, 0.28, 0.28), "cuivre", 1.0)
	var tube: Transform3D = R.L(0, 1.9, lz) * Transform3D(Basis(Vector3.RIGHT, -0.7), Vector3.ZERO)
	k.cyl(tube * B.T3(0, -1.2, 0), 0.2, 0.26, 3.6, "or", 20)
	k.ring(tube * B.T3(0, 2.3, 0), 0.25, 0.3, 0.12, "cuivre", 20)
	k.cyl(tube * B.T3(0, -1.35, 0), 0.05, 0.05, 0.16, "fer", 10)
	k.col_box(R.L(0, 0.8, lz), Vector3(1.3, 1.6, 1.3))
	R.reserve(0, lz, 1.5, 1.5)
	# le planétaire qui tourne, le globe céleste, le bureau et ses notes, les cartes au mur
	var px: float = 2.1
	var pz: float = 0.9
	R.table(px, pz, -60.0, 0.9, 0.9, 0.8)
	Sud._boule(M.room, R.mat(B._c(R, "soleil170", Color(1.0, 0.75, 0.2), 0.4, 0.3, 1.5)), R.P(px, 1.05, pz), 0.09)
	for pl in range(4):
		var piv := Node3D.new()
		M.room.add_child(piv)
		piv.global_position = R.P(px, 1.0, pz)
		var bras := MeshInstance3D.new()
		var lr: float = 0.15 + pl * 0.08
		bras.mesh = B._boitem(lr, 0.008, 0.008)
		bras.material_override = R.mat("or")
		bras.position = Vector3(lr * 0.5, 0.05, 0)
		piv.add_child(bras)
		var pm := MeshInstance3D.new()
		var ps := SphereMesh.new()
		ps.radius = 0.025 + 0.01 * float(pl % 2)
		ps.height = ps.radius * 2.0
		pm.mesh = ps
		pm.material_override = R.mat(B._c(R, "planete_%d" % pl, [Color(0.7, 0.6, 0.5), Color(0.9, 0.7, 0.4), Color(0.3, 0.5, 0.9), Color(0.85, 0.35, 0.25)][pl], 0.5))
		pm.position = Vector3(lr, 0.05, 0)
		piv.add_child(pm)
		piv.rotation.y = pl * 1.7
		(M.ctx["anims170"] as Array).append([piv, "tourne", Vector3.UP, 0.8 / (pl + 1)])
	k.cyl(R.L(px, 0.8, pz), 0.1, 0.12, 0.04, "or", 12)
	k.cyl(R.L(px, 0.84, pz), 0.012, 0.012, 0.2, "or", 6)
	var gx: float = -2.2
	var gz: float = 1.0
	k.cyl(R.L(gx, 0, gz), 0.22, 0.26, 0.05, "bois_sombre", 14)
	k.cyl(R.L(gx, 0.05, gz), 0.035, 0.03, 0.8, "or", 8)
	k.ring(R.L(gx, 1.15, gz) * Transform3D(Basis(Vector3.BACK, 0.4) * Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 0.31, 0.33, 0.02, "or", 24)
	var gm := StandardMaterial3D.new()
	if ResourceLoader.exists("res://assets/textures/arcanelle/carte_ciel.png"):
		gm.albedo_texture = load("res://assets/textures/arcanelle/carte_ciel.png")
	gm.roughness = 0.4
	var globe: MeshInstance3D = Sud._boule(M.room, gm, R.P(gx, 1.15, gz), 0.29)
	(M.ctx["anims170"] as Array).append([globe, "tourne", Vector3.UP, 0.15])
	k.col_box(R.L(gx, 0.7, gz), Vector3(0.7, 1.4, 0.7))
	R.reserve(gx, gz, 0.8, 0.8)
	R.table(-1.9, -1.6, 50.0, 1.2, 0.7)
	for n in range(5):
		k.box(R.L(-1.9 + 0.08 * n, 0.775 + n * 0.004, -1.6 + 0.05 * n, R.rng.randf_range(-20, 20)), Vector3(0.22, 0.004, 0.3), "papier", 1.0)
	R.chaise(-1.45, -1.05, 50.0 + 180.0, "bleu")
	for a2 in [70.0, 115.0, 245.0, 290.0]:
		var cx: Transform3D = _sur_rond(M, a2, r - 0.03, 2.3)
		k.quad(cx * Transform3D(Basis(Vector3.UP, PI), Vector3(0, 0, 0.01)), 1.1, 0.85, B._img(R, "carte_ciel_arc", "arcanelle/carte_ciel.png"))
		k.box(cx * B.T3(0, 0, 0.004), Vector3(1.2, 0.95, 0.01), "bois_sombre", 1.0)
	# les lueurs : Aurélien Lumen est maître de la lumière
	_lueurs(M, Vector3(0.0, 4.6, 0.6), 7, 1.9, Color(1.0, 0.92, 0.6))
	var regarder := func() -> void:
		var h2: float = float(M.ctx.get("hour", 12.0))
		M.main.sfx("etoile_filante")
		if h2 >= 20.0 or h2 < 6.0:
			M.say(str(B._pick(M, ["Dans la lunette : la Lune, si proche qu'on croirait pouvoir y poser le pied. Lumen chuchote : « La mer de la Tranquillité. Très calme, en effet. »", "Une étoile filante traverse l'oculaire ! Lumen applaudit : « Fais un vœu, vite ! Moi, j'en ai déjà fait trois. »"])), 6.0)
		else:
			M.say("En plein jour, la lunette ne montre que du bleu… et un nuage en forme de lapin. Lumen sourit : « La lumière du jour cache les étoiles. Reviens ce soir. »", 6.0)
	M.act(R.P(-0.6, 0, 0.7), "E : regarder dans la grande lunette", regarder, 1.0)
	B._marchand(M, 0.7, 0.75, -150.0, "observer", "homme", "Aurélien Lumen", ["La lumière voyage longtemps avant d'arriver jusqu'à nous. Il faut la remercier.", "Cette nuit, je compte les étoiles filantes. Hier : quarante-deux. Et une chouette.", "Une étoile, c'est une lanterne que quelqu'un a laissée allumée, très loin."],
		{"bonjour": "Bienvenue à l'Observatoire ! Lève les yeux.", "infos": ["Les petites lumières qui flottent ? Elles me suivent partout. Je crois qu'elles m'aiment bien."]})
	M.ctx["cloche170"] = false
	M.ctx["bonjour170"] = ["Bonsoir… ou bonjour ? Ici, on perd la notion du temps.", "Entre, et laisse tes yeux s'habituer à la pénombre."]
	M.ctx["entree"] = "L'Observatoire d'Aurélien Lumen : la grande lunette de laiton qui vise la fente de la coupole, la coupole peinte d'étoiles, le planétaire, le globe céleste, et les petites lumières qui flottent."


# =================================================================== Arcanelle : L'Alambic de Gustave

static func _alambic(M) -> void:
	B._apothicaire(M)
	var R = M.R
	var k = R.kit
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	B._panneau(M, "arcanelle/enseigne_alambic.png", -hw + 0.03, 2.6, -0.9, 90.0, 1.4, 0.36)
	# les fioles qui flottent au-dessus du comptoir, les lueurs
	for i in range(4):
		var c: Color = B.TEINTES[(i * 3 + 1) % B.TEINTES.size()]
		var fi := MeshInstance3D.new()
		fi.mesh = B._cylm(0.03, 0.045, 0.14, 10)
		fi.material_override = R.mat(B._verre(R, "fiole_volante_%d" % i, c, 0.7, 1.2))
		M.room.add_child(fi)
		fi.global_position = R.P(-1.0 + i * 0.65, 2.15, -hd + 2.1)
		fi.rotation.z = 0.3 * float(i % 2) - 0.15
		(M.ctx["anims170"] as Array).append([fi, "flotte", 0.1, fi.position.y, i * 1.4])
	R.chat(hw - 0.7, hd - 1.0, -150.0, Color(0.2, 0.18, 0.2), true)
	M.ctx["bonjour170"] = ["Bienvenue à L'Alambic ! Ne respire pas trop fort près du chaudron.", "Ah, un client ! Une potion ? Un conseil ? Un mouchoir ?"]
	M.ctx["entree"] = "L'Alambic de Gustave Fiole : le grand mur de tiroirs, les fioles qui brillent (et celles qui flottent), le chaudron violet qui bouillonne, l'alambic qui glougloute."


# =================================================================== Arcanelle : la roulotte d'Agathe

static func _roulotte(M) -> void:
	var R = M.R
	var k = R.kit
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	# la voûte de la roulotte : des arceaux de bois peint
	for i in range(5):
		var z: float = -hd + 0.45 + i * 1.0
		for j in range(6):
			var a0: float = PI * j / 6.0
			var a1: float = PI * (j + 1) / 6.0
			var p0 := Vector3(cos(a0) * hw, 2.15 + sin(a0) * 0.5, z)
			var p1 := Vector3(cos(a1) * hw, 2.15 + sin(a1) * 0.5, z)
			var mid: Vector3 = (p0 + p1) * 0.5
			var d: Vector3 = p1 - p0
			k.box(R.L(mid.x, mid.y, mid.z) * Transform3D(Basis(Vector3.BACK, atan2(d.y, d.x)), Vector3.ZERO), Vector3(d.length() + 0.02, 0.07, 0.07), "bois_sombre", 1.0)
	# l'alcôve du lit, au fond : le matelas, les coussins, le rideau étoilé
	var bz: float = -hd + 0.45
	k.box(R.L(0, 0.25, bz), Vector3(R.W, 0.5, 0.9), "bois", 1.0)
	k.box(R.L(0, 0.56, bz), Vector3(R.W - 0.1, 0.12, 0.85), "drap", 1.0)
	for c in range(3):
		k.box(R.L(-0.9 + c * 0.9, 0.72, bz - 0.2) * Transform3D(Basis(Vector3.RIGHT, -0.4), Vector3.ZERO), Vector3(0.6, 0.35, 0.14), "tissu_" + ["rouge", "violet", "jaune"][c], 1.0)
	k.col_box(R.L(0, 0.3, bz), Vector3(R.W, 0.6, 0.9))
	R.reserve(0, bz, R.W, 1.0)
	R.chat(0.9, bz + 0.05, 200.0, Color(0.08, 0.08, 0.1), true, 0.62)
	var rid: String = B._tex(R, "rideau171", "beau171/rideau_etoiles.png", Color(1, 1, 1), 0.95)
	k.box(R.L(-hw + 0.3, 1.45, bz + 0.48), Vector3(0.6, 1.9, 0.02), rid, 1.0)
	k.cyl(R.L(-hw, 2.42, bz + 0.48) * Transform3D(Basis(Vector3.BACK, -PI * 0.5), Vector3.ZERO), 0.015, 0.015, R.W, "cuivre", 6)
	# la table ronde, la boule de cristal, les cartes du ciel étalées ; les deux tabourets
	var tz: float = -0.75
	R.table_ronde(0, tz, 0.42, 0.72)
	k.box(R.L(0, 0.725, tz), Vector3(0.8, 0.01, 0.8), "tissu_violet", 1.0, 4)
	k.cyl(R.L(0, 0.73, tz - 0.05), 0.07, 0.05, 0.05, "or", 10)
	var boule: MeshInstance3D = Sud._boule(M.room, R.mat(B._verre(R, "boule_agathe", Color(0.95, 0.65, 0.95), 0.55, 1.4)), R.P(0, 0.88, tz - 0.05), 0.11)
	boule.name = "Boule_cristal"
	B._lampe(M, 0, 0.95, tz, Color(1.0, 0.6, 0.95), 0.6, 2.5)
	var carte: String = B._img(R, "carte_ciel_arc", "arcanelle/carte_ciel.png")
	for cc in range(3):
		k.quad(R.L(-0.22 + cc * 0.22, 0.735, tz + 0.2, -15.0 + cc * 15.0) * Transform3D(Basis(Vector3.UP, PI) * Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 0.11, 0.17, carte, Vector2(cc * 0.3, 0.2), Vector2(cc * 0.3 + 0.25, 0.6))
	for sz in [-1.35, -0.05]:
		k.cyl(R.L(0, 0.42, sz), 0.18, 0.18, 0.05, "bois", 12)
		k.cyl(R.L(0, 0, sz), 0.14, 0.04, 0.42, "bois_sombre", 8)
	# l'étagère des bocaux, les herbes au plafond, la lanterne, le petit poêle et sa bouilloire de tisane
	B._rayons(M, hw - 0.2, 0.6, -90.0, 1.0, 1.5, 3, "bocaux", 5)
	B._herbes(M, -hw + 0.3, hw - 0.3, 0.4)
	B._lanterne(M, -0.6, tz, 1.95)
	k.cyl(R.L(-hw + 0.45, 0, 1.2), 0.22, 0.24, 0.6, "fer", 12)
	k.cyl(R.L(-hw + 0.45, 0.6, 1.2), 0.12, 0.1, 0.12, "cuivre", 12)
	k.cyl(R.L(-hw + 0.45, 0.6, 1.2), 0.04, 0.04, R.H, "fer", 6)
	k.col_box(R.L(-hw + 0.45, 0.3, 1.2), Vector3(0.5, 0.6, 0.5))
	R.reserve(-hw + 0.45, 1.2, 0.6, 0.6)
	k.cyl(R.L(-hw + 0.02, 1.6, -0.3) * Transform3D(Basis(Vector3.BACK, -PI * 0.5), Vector3.ZERO), 0.26, 0.26, 0.03, B._c(R, "hublot_ciel", Color(0.5, 0.7, 0.9) if R.day else Color(0.1, 0.12, 0.3), 0.3, 0.0, 0.8), 18)
	k.ring(R.L(-hw + 0.02, 1.6, -0.3) * Transform3D(Basis(Vector3.BACK, -PI * 0.5), Vector3.ZERO), 0.26, 0.32, 0.05, "cuivre", 18)
	var predire := func() -> void:
		var st: Dictionary = M.state()
		var n: int = int(st.get("avenir171", 0))
		st["avenir171"] = n + 1
		var t: Array = ["La boule s'éclaire : tu vois… une grande aventure. Et une tarte. Agathe hoche la tête : « La tarte, c'est sûr. »",
			"Des brumes roses tourbillonnent… Agathe plisse les yeux : « Quelqu'un pense à toi, très fort. Peut-être ton estomac. »",
			"Une étoile s'allume au fond de la boule. « Tu trouveras ce que tu cherches, dit Agathe, mais pas où tu le cherches. Regarde sous les lits. »"]
		M.main.sfx("cristal_chante")
		M.close_talk()
		M.say(str(t[n % t.size()]), 7.0)
	B._marchand(M, 0, -1.35, 0.0, "assis", "vieille", "Agathe Brumaire", ["Assieds-toi, mon petit. La boule t'attendait.", "Le Bois Tors a ses secrets. Moi, je les écoute.", "Mon chat voit l'avenir. Il voit surtout l'heure du dîner."],
		{"bonjour": "Entre, entre ! Ferme bien la porte, le brouillard est curieux.", "services": [{"label": "Se faire prédire l'avenir", "cb": predire}], "vend": {"tisane_lune": 5}})
	M.act(R.P(0, 0, 0.35), "E : regarder dans la boule de cristal", predire, 0.9)
	M.ctx["cloche170"] = false
	M.ctx["bonjour170"] = ["Ah ! Je savais que tu viendrais. La boule me l'a dit.", "Entre, mon petit. Fais attention au chat."]
	M.ctx["entree"] = "La roulotte d'Agathe : les arceaux peints, les rideaux semés de lunes, la boule de cristal sur la table ronde, les herbes qui sèchent, et le chat noir sur le lit."


# =================================================================== Arcanelle : la tour de Pyra

static func _tour_pyra(M) -> void:
	var R = M.R
	var k = R.kit
	var r: float = _rond(M, 26.0)
	# la grande vasque de feu sur son trépied, la hotte au-dessus, les étincelles
	var fz: float = -0.4
	for i in range(3):
		var a: float = TAU * i / 3.0 + 0.5
		k.box(R.L(cos(a) * 0.38, 0.45, fz + sin(a) * 0.38) * Transform3D(Basis(Vector3(-sin(a), 0, cos(a)), 0.25), Vector3.ZERO), Vector3(0.07, 0.95, 0.07), "fer", 1.0)
	k.cyl(R.L(0, 0.8, fz), 0.22, 0.55, 0.28, "cuivre", 20)
	k.cyl(R.L(0, 1.06, fz), 0.48, 0.48, 0.03, B._c(R, "braises171", Color(1.0, 0.42, 0.12), 0.6, 0.0, 2.2), 18)
	R.fire(R.P(0, 1.15, fz), 1.1)
	B._etincelles(M, R.P(0, 1.3, fz))
	k.cyl(R.L(0, 3.4, fz), 0.95, 0.35, 1.0, "cuivre", 20, false)
	k.cyl(R.L(0, 4.4, fz), 0.35, 0.35, R.H - 4.4, "cuivre", 14, false)
	k.col_box(R.L(0, 0.6, fz), Vector3(1.2, 1.2, 1.2))
	R.reserve(0, fz, 1.6, 1.6)
	for l in R.lights:
		(l as Node3D).global_position = R.P(0, R.H - 1.2, 1.5)
	# les traces de suie, les cristaux de feu sur leurs étagères, la salamandre de pierre
	var suie: String = B._img(R, "suie171", "beau170/suie.png", 2)
	for e in [[120.0, 2.6, 1.4], [205.0, 1.5, 1.0], [250.0, 3.1, 1.6]]:
		var sx: Transform3D = _sur_rond(M, float(e[0]), r - 0.04, float(e[1]))
		k.quad(sx * Transform3D(Basis(Vector3.UP, PI), Vector3.ZERO), float(e[2]), float(e[2]) * 0.8, suie)
	for a2 in [70.0, 290.0]:
		for row in range(3):
			var ex: Transform3D = _sur_rond(M, a2, r - 0.2, 0.9 + row * 0.55)
			k.box(ex, Vector3(1.0, 0.04, 0.3), "bois_sombre", 1.0)
			for c in range(4):
				var cc: Color = [Color(1.0, 0.35, 0.1), Color(1.0, 0.65, 0.15), Color(0.95, 0.2, 0.1), Color(1.0, 0.85, 0.3)][(c + row) % 4]
				k.cyl(ex * B.T3(-0.36 + c * 0.24, 0.02, 0), 0.05, 0.0, 0.2 + 0.05 * float(c % 2), B._c(R, "cristal_feu_%d" % ((c + row) % 4), cc, 0.3, 0.0, 2.0), 6)
	B._lampe(M, sin(deg_to_rad(70.0)) * (r - 0.6), 1.5, cos(deg_to_rad(70.0)) * (r - 0.6), Color(1.0, 0.5, 0.2), 0.5, 2.5)
	B._lampe(M, sin(deg_to_rad(290.0)) * (r - 0.6), 1.5, cos(deg_to_rad(290.0)) * (r - 0.6), Color(1.0, 0.5, 0.2), 0.5, 2.5)
	var sal: Transform3D = R.L(-1.5, 0, -1.6, 40.0)
	k.box(sal * B.T3(0, 0.25, 0), Vector3(0.6, 0.5, 0.6), "pierre", 1.0)
	var rouge: String = B._c(R, "salamandre", Color(0.85, 0.2, 0.08), 0.5, 0.0, 0.4)
	k.box(sal * B.T3(0, 0.56, 0), Vector3(0.12, 0.08, 0.36), rouge, 1.0)
	k.box(sal * B.T3(0, 0.58, 0.22), Vector3(0.1, 0.07, 0.1), rouge, 1.0)
	k.cyl(sal * Transform3D(Basis(Vector3.RIGHT, -PI * 0.5 + 0.2), Vector3(0, 0.55, -0.17)), 0.04, 0.0, 0.3, rouge, 6)
	for sxx in [-1.0, 1.0]:
		for szz in [-0.1, 0.1]:
			k.box(sal * B.T3(sxx * 0.09, 0.53, szz), Vector3(0.08, 0.03, 0.04), rouge, 1.0)
	k.col_box(sal * B.T3(0, 0.3, 0), Vector3(0.6, 0.6, 0.6))
	R.reserve(-1.5, -1.6, 0.8, 0.8)
	# le mannequin roussi, le seau d'eau (la prudence avant tout), l'écriteau
	var mx: float = 1.6
	var mz: float = -1.4
	k.box(R.L(mx, 0.8, mz), Vector3(0.1, 1.6, 0.1), "bois_sombre", 1.0)
	k.cyl(R.L(mx, 0.85, mz), 0.22, 0.2, 0.65, B._tex(R, "paille170", "beau161/foin_rond.png", Color(0.95, 0.85, 0.55)), 10)
	k.cyl(R.L(mx, 1.35, mz), 0.2, 0.12, 0.2, B._c(R, "roussi", Color(0.15, 0.1, 0.08), 0.95), 10)
	k.box(R.L(mx, 1.25, mz), Vector3(0.9, 0.1, 0.1), "bois_sombre", 1.0)
	k.col_box(R.L(mx, 0.8, mz), Vector3(0.5, 1.6, 0.5))
	R.reserve(mx, mz, 0.8, 0.8)
	k.cyl(R.L(1.6, 0, 1.6), 0.18, 0.22, 0.36, "bois", 12)
	k.disc(R.L(1.6, 0.33, 1.6), 0.19, B._c(R, "eau_seau", Color(0.25, 0.45, 0.6), 0.1), 12)
	var ecr: Transform3D = _sur_rond(M, 125.0, r - 0.05, 1.6)
	k.box(ecr, Vector3(1.0, 0.5, 0.03), "bois", 1.0)
	var ea: float = deg_to_rad(125.0)
	B._ecrit(M, sin(ea) * (r - 0.05), 1.6, cos(ea) * (r - 0.05), 305.0, "EN CAS D'INCENDIE :\nAPPELER PYRA.\nEN CAS DE PYRA :\nAPPELER BORÉE.", 36, Color(1.0, 0.9, 0.62), 0.0032, 0.035)
	var chauffer := func() -> void:
		M.main.sfx("forge_marteau")
		M.say("Tu tends les mains vers la vasque. La chaleur te chatouille les doigts. Pyra rit : « Pas trop près ! Le feu est un ami… qui mord un peu. »", 6.0)
	M.act(R.P(0, 0, fz + 1.1), "E : te réchauffer les mains", chauffer, 1.0)
	B._marchand(M, -1.2, 0.5, 120.0, "enseigner", "femme", "Pyra Flammèche", ["Le feu, c'est comme un chat : on le nourrit, on le respecte, et on ne lui tire pas la queue.", "Le mannequin ? Il a perdu. Encore.", "Ma première flamme était grosse comme une luciole. Maintenant, elle est grosse comme ma tour."],
		{"bonjour": "Bienvenue dans ma tour ! Il fait chaud, hein ?", "infos": ["Les cristaux de feu gardent la chaleur des étés. L'hiver, je les pose sous mon oreiller."]})
	M.ctx["cloche170"] = false
	M.ctx["bonjour170"] = ["Entre ! Mais pas trop près du feu.", "Ah, de la visite ! Tu as froid ? Viens par ici."]
	M.ctx["entree"] = "La tour de Pyra Flammèche : la grande vasque de feu sous sa hotte de cuivre, les cristaux de feu, la salamandre de pierre, le mannequin roussi… et le seau d'eau, par prudence."


# =================================================================== Port-Coutelas : la caverne d'Isaac Cinq-Doigts

static func _receleur(M) -> void:
	var R = M.R
	var k = R.kit
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	# le comptoir : la balance, la loupe, le registre, les piles de pièces, la bougie
	var zc: float = -0.85
	var cx: Transform3D = B._comptoir(M, 0.4, zc, 2.4, 0.0, false, 1.0, "bois_sombre", "bois")
	B._balance(R, cx * B.T3(-0.8, 1.06, 0.05))
	k.box(cx * B.T3(0.1, 1.08, 0.08), Vector3(0.36, 0.05, 0.26), B._c(R, "registre", Color(0.35, 0.15, 0.1), 0.8), 1.0)
	k.box(cx * B.T3(0.1, 1.11, 0.08), Vector3(0.32, 0.01, 0.24), "papier", 1.0)
	for pz in range(4):
		for n in range(3 + pz):
			k.cyl(cx * B.T3(0.6 + 0.09 * float(pz % 2), 1.06 + n * 0.012, -0.08 + pz * 0.07), 0.035, 0.035, 0.012, "or", 10)
	k.cyl(cx * Transform3D(Basis(Vector3.BACK, 1.2), Vector3(0.95, 1.08, 0.15)), 0.012, 0.012, 0.16, "bois_sombre", 6)
	k.ring(cx * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0.85, 1.12, 0.2)), 0.045, 0.055, 0.012, "cuivre", 14)
	R.bougie(-0.5, 1.06, zc + 0.1)
	# derrière : les étagères pleines de trouvailles, les écrins
	B._rayons(M, -1.1, -hd + 0.22, 0.0, 1.6, 2.2, 5, "mixte", 4)
	B._rayons(M, 1.8, -hd + 0.22, 0.0, 1.6, 2.2, 5, "bijoux", 1)
	# le bric-à-brac : les coffres, les tonneaux, la barre de navire, le crocodile empaillé au plafond, le perroquet
	R.coffre_deco(-hw + 0.5, 0.4, 90.0)
	R.coffre_deco(-hw + 0.5, 1.3, 90.0)
	R.tonneau(hw - 0.45, 0.5)
	R.tonneau(hw - 0.45, 1.25)
	R.tonneau(hw - 1.1, 0.85, true)
	B._barre(R, -hw + 0.06, 1.7, -0.9, 90.0, 0.45)
	var croco: String = B._tex(R, "croco171", "pirates/croco.png", Color(0.65, 0.7, 0.5), 0.8)
	var cz: float = 0.6
	for s in [-1.0, 1.0]:
		k.cyl(R.L(-0.8 + s * 0.5, R.H - 0.35, cz), 0.006, 0.006, 0.35, "fer", 4, false)
	k.box(R.L(-0.8, R.H - 0.45, cz), Vector3(1.4, 0.16, 0.3), croco, 0.5)
	k.box(R.L(-1.65, R.H - 0.46, cz), Vector3(0.45, 0.1, 0.16), croco, 0.5)
	k.cyl(R.L(-0.1, R.H - 0.47, cz) * Transform3D(Basis(Vector3.BACK, -PI * 0.5), Vector3.ZERO), 0.07, 0.0, 0.7, croco, 8)
	for t in range(5):
		k.cyl(Transform3D(Basis(Vector3.RIGHT, PI), R.P(-1.82 + t * 0.07, R.H - 0.5, cz + 0.07)), 0.01, 0.0, 0.035, "ceramique", 4)
	_perroquet(M, hw - 0.6, -hd + 0.6, -140.0)
	var lo: Transform3D = R.L(-hw + 1.4, 0, 2.0)
	k.cyl(lo * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(0.6, 0.15, 0)), 0.15, 0.15, 1.2, "tissu_rouge", 12)
	Sud._boule(M.room, R.mat(B._verre(R, "bouteille_navire", Color(0.75, 0.9, 0.85), 0.3)), cx * Vector3(-0.35, 1.13, 0.12), 0.07, Vector3(1.6, 1.0, 1.0))
	B._lanterne(M, 0.4, zc + 0.6)
	var lignes: Array = ["Tout s'achète, mon ami. Même les souvenirs.", "D'où vient ce collier ? D'une très, très vieille dame. Très gentille. Très distraite.", "Cinq doigts, cinq poches, cinq bonnes affaires par jour."]
	B._marchand(M, 0.4, zc - 0.55, 0.0, "comptoir", "homme", "Isaac Cinq-Doigts", lignes, {"bonjour": "Entre, entre ! Tu as quelque chose à vendre ?",
		"achete": {"perle": 12, "bague": 8, "rubis": 20, "piece_or": 10, "dent_requin": 3, "dent_croco": 4, "plume_perroquet": 2, "coquillage": 1}, "vend": {"boussole": 25, "corde_chanvre": 5}})
	M.ctx["cloche170"] = true
	M.ctx["bonjour170"] = ["Bienvenue dans ma caverne aux trésors ! Ne touche à rien… sauf pour acheter.", "Ah, un client ! Approche, approche."]
	M.ctx["entree"] = "La caverne d'Isaac Cinq-Doigts : des coffres, des tonneaux, des écrins, une barre de navire, un crocodile empaillé qui pend du plafond, et Isaac derrière sa balance."


## Un perroquet sur son perchoir (rouge, la queue bleue, le bec crochu).
static func _perroquet(M, x: float, z: float, yaw: float) -> void:
	var R = M.R
	var k = R.kit
	k.cyl(R.L(x, 0, z), 0.16, 0.18, 0.04, "bois_sombre", 10)
	k.cyl(R.L(x, 0.04, z), 0.02, 0.02, 1.35, "bois_sombre", 6)
	k.box(R.L(x, 1.4, z, yaw), Vector3(0.4, 0.035, 0.035), "bois_sombre", 1.0)
	var rouge: Material = R.mat(B._c(R, "plume_ara", Color(0.85, 0.1, 0.08), 0.6))
	Sud._boule(M.room, rouge, R.P(x, 1.53, z), 0.08, Vector3(0.9, 1.3, 0.9))
	Sud._boule(M.room, rouge, R.P(x, 1.68, z), 0.06)
	var f: Vector3 = Basis(Vector3.UP, deg_to_rad(yaw)) * Vector3(0, 0, 1)
	k.cyl(Transform3D(Basis(Vector3.UP, deg_to_rad(yaw)) * Basis(Vector3.RIGHT, PI * 0.6), R.P(x, 1.67, z) + f * 0.05), 0.022, 0.0, 0.05, "ceramique", 6)
	k.box(Transform3D(Basis(Vector3.UP, deg_to_rad(yaw)) * Basis(Vector3.RIGHT, 0.4), R.P(x, 1.36, z) - f * 0.08), Vector3(0.05, 0.25, 0.015), B._c(R, "plume_bleue", Color(0.1, 0.3, 0.85), 0.6), 1.0)
	k.col_box(R.L(x, 0.7, z), Vector3(0.3, 1.4, 0.3))
	R.reserve(x, z, 0.5, 0.5)


# =================================================================== Port-Coutelas : le cabinet du Doc Saignée

static func _cabinet_doc(M) -> void:
	var R = M.R
	var k = R.kit
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	# le fauteuil du barbier et son patient, la cuvette et le miroir, le poteau rayé
	var fx: float = 0.4
	var fz: float = -1.3
	R.fauteuil(fx, fz, 0.0, "rouge")
	k.box(R.L(fx, 0.2, fz + 0.5), Vector3(0.4, 0.05, 0.25), "cuir", 1.0)
	var pat: Node = M.person("homme", fx, fz, 0.0, "assis", "Bigorneau")
	pat.lines = ["Aïe ! Euh… je veux dire : même pas mal.", "Le Doc m'a promis une sucette si je suis courageux. Je suis TRÈS courageux."]
	k.box(R.L(-1.5, 0.45, -hd + 0.3), Vector3(0.7, 0.9, 0.45), "bois", 1.0)
	k.cyl(R.L(-1.5, 0.9, -hd + 0.3), 0.18, 0.22, 0.1, "ceramique", 16)
	k.cyl(R.L(-1.25, 0.9, -hd + 0.4), 0.06, 0.07, 0.22, "ceramique", 10)
	k.box(R.L(-1.5, 1.7, -hd + 0.02), Vector3(0.6, 0.8, 0.02), "argent", 1.0)
	k.box(R.L(-1.5, 1.7, -hd + 0.01), Vector3(0.7, 0.9, 0.02), "bois_sombre", 1.0)
	k.col_box(R.L(-1.5, 0.45, -hd + 0.3), Vector3(0.7, 0.9, 0.45))
	R.reserve(-1.5, -hd + 0.3, 0.9, 0.7)
	for i in range(10):
		var c: String = ["tissu_rouge", "tissu_blanc", "tissu_bleu", "tissu_blanc"][i % 4]
		k.cyl(R.L(-hw + 0.8, 0.3 + i * 0.18, hd - 0.5), 0.07, 0.07, 0.18, c, 12)
	k.cyl(R.L(-hw + 0.8, 0, hd - 0.5), 0.12, 0.12, 0.3, "cuivre", 12)
	k.cyl(R.L(-hw + 0.8, 2.1, hd - 0.5), 0.1, 0.04, 0.12, "cuivre", 12)
	# les bocaux d'onguents, les rouleaux de pansements, les livres du Doc
	B._rayons(M, hw - 0.22, -0.5, -90.0, 1.6, 2.0, 4, "bocaux", 2)
	B._rayons(M, 1.9, -hd + 0.22, 0.0, 1.2, 2.0, 4, "livres")
	R.table(hw - 0.7, 1.4, -90.0, 1.0, 0.6, 0.78)
	for b in range(5):
		k.cyl(R.L(hw - 0.7, 0.78, 1.05 + b * 0.16) * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0.05, -0.08)), 0.045, 0.045, 0.16, "tissu_blanc", 10)
	# le grand bocal de sucettes, pour les patients courageux
	var sx: float = hw - 0.7
	var sz: float = 1.85
	k.cyl(R.L(sx, 0.78, sz), 0.13, 0.13, 0.3, B._verre(R, "bocal_sucettes", Color(0.9, 0.95, 0.95), 0.25), 14)
	for l in range(7):
		var a: float = TAU * l / 7.0
		var cc: Color = B.TEINTES[l % B.TEINTES.size()]
		k.cyl(R.L(sx + cos(a) * 0.05, 0.88, sz + sin(a) * 0.05), 0.006, 0.006, 0.3, "papier", 4, false)
		Sud._boule(M.room, R.mat(B._c(R, "sucette_%d" % (l % B.TEINTES.size()), cc, 0.3)), R.P(sx + cos(a) * 0.06, 1.2, sz + sin(a) * 0.06), 0.035)
	# le lit de repos, et le pirate qui se remet de sa bosse
	R.lit(-hw + 1.0, 0.7, 90.0, 0.9, "blanc")
	var dor: Node = M.person("homme", -hw + 1.2, 0.7, 90.0, "dormir", "Calamar")
	dor.lie(R.P(-hw + 1.85, 0.45, 0.7), Vector3(-1, 0, 0))
	dor.lines = ["Zzz… maman… encore un biscuit… Zzz…"]
	# l'écriteau des tarifs
	k.box(R.L(-hw + 0.03, 1.75, -0.9, 90.0), Vector3(1.0, 0.7, 0.03), "bois", 1.0)
	R.mark_wall(-hw, 1.75, -0.9, 0.55)
	B._ecrit(M, -hw + 0.03, 1.75, -0.9, 90.0, "SOINS DU DOC\nBobos : gratuit\nDents : une pièce\nCourage : offert", 40, Color(0.2, 0.1, 0.05), 0.0035, 0.025)
	var sucette := func() -> void:
		M.main.sfx("clochette")
		M.say("Tu prends une sucette rouge dans le grand bocal. Le Doc hoche la tête : « Pour les patients courageux. Tu as l'air courageux. Et gourmand. »", 6.0)
	M.act(R.P(sx - 0.7, 0, sz), "E : prendre une sucette", sucette, 1.0)
	B._marchand(M, fx + 1.0, fz + 0.35, -110.0, "mains_dos", "vieux", "le Doc", ["Ouvre la bouche, dis « aaah ». Voilà. Une dent de moins, un sourire de plus.", "Un bon chirurgien-barbier a la main sûre… et des sucettes.", "Les pirates sont des enfants. Des enfants poilus, avec des sabres."],
		{"bonjour": "Entre ! Tu as mal quelque part ?", "vend": {"miel": 5, "tisane_lune": 6}, "infos": ["Je soigne les bosses, les échardes et les cœurs brisés. Pour les cœurs, j'ai surtout du miel."]})
	M.ctx["cloche170"] = true
	M.ctx["bonjour170"] = ["Entre ! Le Doc va s'occuper de toi.", "Bonjour ! Pas de bobo ? Tant mieux. Entre quand même."]
	M.ctx["entree"] = "Le cabinet du Doc Saignée : le fauteuil du barbier et son patient très courageux, les bocaux d'onguents, les pansements, et le grand bocal de sucettes."


# =================================================================== Port-Coutelas : la résidence du Gouverneur

static func _residence(M) -> void:
	var R = M.R
	var k = R.kit
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	# le portrait géant du Gouverneur, dans son cadre doré
	var por: String = B._img(R, "portrait_gouv", "beau171/portrait_gouverneur.png")
	B._cadre(R, por, 0.0, 2.55, -hd + 0.02, 0.0, 1.5, 2.0, "or")
	k.box(R.L(0.0, 3.68, -hd + 0.05), Vector3(1.9, 0.18, 0.08), "or", 1.0)
	# le bureau (deux caissons de tiroirs, le plateau), le fauteuil, la plume, la sonnette, les décrets
	var dz: float = -hd + 1.75
	k.box(R.L(0.0, 0.76, dz), Vector3(2.3, 0.06, 0.95), "bois_sombre", 1.0)
	k.box(R.L(0.0, 0.79, dz), Vector3(2.0, 0.005, 0.7), "cuir", 1.0)
	for sx in [-1.0, 1.0]:
		k.box(R.L(sx * 0.85, 0.37, dz), Vector3(0.58, 0.74, 0.9), "bois_sombre", 1.0)
		for t in range(3):
			k.box(R.L(sx * 0.85, 0.15 + t * 0.22, dz + 0.455), Vector3(0.5, 0.18, 0.01), "bois", 1.0)
			k.cyl(R.L(sx * 0.85, 0.15 + t * 0.22, dz + 0.465) * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 0.018, 0.018, 0.02, "or", 8)
	k.box(R.L(0.0, 0.6, dz + 0.44), Vector3(1.1, 0.3, 0.02), "bois_sombre", 1.0)
	k.col_box(R.L(0.0, 0.4, dz), Vector3(2.3, 0.8, 0.95))
	R.reserve(0.0, dz, 2.5, 1.2)
	for p in range(6):
		k.box(R.L(-0.7 + 0.03 * p, 0.8 + p * 0.006, dz - 0.05, -8.0 + p * 4.0), Vector3(0.24, 0.005, 0.32), "papier", 1.0)
	k.cyl(R.L(0.55, 0.79, dz - 0.15), 0.035, 0.03, 0.06, "noir", 8)
	k.cyl(R.L(0.58, 0.85, dz - 0.15) * Transform3D(Basis(Vector3.BACK, -0.4), Vector3.ZERO), 0.004, 0.004, 0.22, "tissu_blanc", 4)
	k.cyl(R.L(0.85, 0.79, dz + 0.1), 0.05, 0.035, 0.05, "or", 10)
	B._ecrit(M, 0.0, 0.6, dz + 0.455, 0.0, "Le Gouverneur reçoit\nles jours pairs.\n(Aujourd'hui est un jour pair.)", 24, Color(0.95, 0.85, 0.5), 0.0025, 0.0)
	R.fauteuil(0.0, -hd + 0.75, 0.0, "rouge")
	# le tapis rouge, le lustre, les pavillons, le globe, le canapé, le perroquet, la bibliothèque
	k.box(R.L(0.0, 0.006, 0.9), Vector3(1.4, 0.012, 4.8), "tissu_rouge", 1.0, 4 | 1 | 2 | 16 | 32)
	for sx2 in [-1.0, 1.0]:
		k.box(R.L(sx2 * 0.66, 0.008, 0.9), Vector3(0.06, 0.014, 4.8), "or", 1.0, 4)
	B._lustre(M, 0.0, 0.6, 0.6, 1.2)
	for sx3 in [-1.0, 1.0]:
		var pav: String = B._img(R, "pavillon_balafre", "pirates/pavillon_balafre.png")
		B._cadre(R, pav, sx3 * (hw - 0.02), 2.4, -1.6, -sx3 * 90.0, 1.4, 0.9, "or")
	var gx: float = -hw + 1.1
	var gz: float = -hd + 1.1
	k.cyl(R.L(gx, 0, gz), 0.25, 0.28, 0.06, "bois_sombre", 14)
	k.cyl(R.L(gx, 0.06, gz), 0.04, 0.035, 0.75, "or", 8)
	var gm := StandardMaterial3D.new()
	if ResourceLoader.exists("res://assets/textures/beau170/carte_marine.png"):
		gm.albedo_texture = load("res://assets/textures/beau170/carte_marine.png")
	gm.roughness = 0.5
	Sud._boule(M.room, gm, R.P(gx, 1.1, gz), 0.3)
	k.ring(R.L(gx, 1.1, gz) * Transform3D(Basis(Vector3.BACK, 0.4) * Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 0.32, 0.34, 0.02, "or", 24)
	k.col_box(R.L(gx, 0.7, gz), Vector3(0.7, 1.4, 0.7))
	R.reserve(gx, gz, 0.8, 0.8)
	R.canape(-hw + 0.6, 1.2, 90.0, "rouge", 2.0)
	R.table(-hw + 1.6, 1.2, 0.0, 0.6, 0.6, 0.5)
	_perroquet(M, hw - 0.9, -hd + 0.9, -140.0)
	R.etagere(hw - 0.25, 0.6, -90.0, 1.8, 2.2, true, 5)
	R.plante(-hw + 0.5, hd - 0.6, 0.0, 1.4)
	R.plante(hw - 0.5, hd - 0.6, 0.0, 1.4)
	# la Constitution de Port-Coutelas, sous verre
	k.box(R.L(hw - 0.03, 1.6, 2.2, -90.0), Vector3(0.6, 0.8, 0.03), "papier", 1.0)
	R.mark_wall(hw, 1.6, 2.2, 0.4)
	B._ecrit(M, hw - 0.03, 1.75, 2.2, -90.0, "CONSTITUTION\nde Port-Coutelas", 30, Color(0.25, 0.12, 0.05), 0.0035, 0.025)
	for sx4 in [-1.0, 1.0]:
		k.box(R.L(hw - 0.04, 1.6 + sx4 * 0.42, 2.2, -90.0), Vector3(0.7, 0.05, 0.05), "or", 1.0)
		k.box(R.L(hw - 0.04, 1.6, 2.2 + sx4 * 0.32), Vector3(0.05, 0.9, 0.05), "or", 1.0)
	var lire := func() -> void:
		var st: Dictionary = M.state()
		var n: int = int(st.get("constitution171", 0))
		st["constitution171"] = n + 1
		var t: Array = ["« Article premier : le Gouverneur a toujours raison. Article deux : en cas de doute, voir l'article premier. »",
			"« Article trois : le Gouverneur est élu chaque année, à l'unanimité de lui-même. »", "« Article quatre : les enfants ont le droit de rire du Gouverneur. (Ajouté au crayon, d'une petite écriture.) »"]
		M.say(str(t[n % t.size()]), 7.0)
	M.act(R.P(hw - 0.9, 0, 2.2), "E : lire la Constitution", lire, 1.0)
	B._marchand(M, 0.0, -hd + 0.75, 0.0, "assis", "homme", "le Gouverneur Lagrange", ["Bienvenue dans MA résidence ! Admire le portrait. Il est ressemblant, non ?", "Port-Coutelas n'a jamais été aussi bien gouverné. Par moi.", "Ce fauteuil était celui de mon prédécesseur. Je l'ai gagné aux cartes. Légalement."],
		{"bonjour": "Ah ! Un administré ! Approchez, approchez.", "infos": ["J'ai été élu à l'unanimité. Bon, il n'y avait que moi pour voter. Mais quelle unanimité !"]})
	R.table(hw - 1.3, 2.9, -90.0, 0.9, 0.55, 0.74)
	R.chaise(hw - 1.9, 2.9, -90.0, "rouge")
	var sec: Node = M.person("femme", hw - 1.9, 2.9, -90.0, "lire", "Mademoiselle Plume")
	sec.lines = ["Le Gouverneur dicte, j'écris. Parfois, j'écris autre chose. Il ne relit jamais.", "Décret numéro trois cent douze : interdiction de rire du chapeau du Gouverneur. Je ris quand même. Tout bas."]
	M.ctx["cloche170"] = false
	M.ctx["bonjour170"] = ["Entrez, entrez ! Le Gouverneur vous reçoit. C'est un jour pair.", "Ah, de la visite ! Admirez le portrait."]
	M.ctx["entree"] = "La résidence du Gouverneur Lagrange : le portrait géant dans son cadre doré, le grand bureau couvert de décrets, le tapis rouge, le lustre, le globe, et la Constitution sous verre."


# =================================================================== Port-Coutelas : la Tour Lunette du cartographe

static func _tour_lunette(M) -> void:
	var R = M.R
	var k = R.kit
	var r: float = _rond(M, 26.0)
	# la grande table des cartes : la carte de l'archipel, la carte au trésor, le compas, la loupe
	var tz: float = -0.4
	R.table(0.0, tz, 0.0, 1.8, 1.1, 0.85)
	var cm: String = B._img(R, "carte_marine171", "beau170/carte_marine.png")
	k.quad(R.L(0.0, 0.862, tz) * Transform3D(Basis(Vector3.UP, PI) * Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 1.5, 0.95, cm)
	var ct: String = B._img(R, "carte_tresor171", "pirates/carte_tresor.png")
	k.quad(R.L(0.55, 0.868, tz + 0.15, -25.0) * Transform3D(Basis(Vector3.UP, PI) * Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 0.45, 0.32, ct)
	for s in [-1.0, 1.0]:
		k.box(R.L(-0.35 + s * 0.04, 0.875, tz + 0.1, 70.0 + s * 12.0), Vector3(0.22, 0.008, 0.012), "argent", 1.0)
	for w in range(3):
		k.cyl(R.L(-0.7 + w * 1.4 if w < 2 else 0.0, 0.862, tz - 0.42 if w < 2 else tz + 0.42), 0.04, 0.04, 0.05, "fer", 10)
	k.ring(R.L(0.2, 0.9, tz - 0.2) * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 0.05, 0.06, 0.012, "cuivre", 14)
	# les cartes punaisées au mur rond, le globe, le tonneau des rouleaux, la longue-vue à la fenêtre
	var cartes: Array = [[60.0, "beau170/carte_marine.png", "carte_marine171"], [100.0, "pirates/carte_tresor.png", "carte_tresor171"], [255.0, "beau170/carte_campagne.png", "carte_campagne171"], [295.0, "arcanelle/carte_ciel.png", "carte_ciel_arc"]]
	for e in cartes:
		var cx: Transform3D = _sur_rond(M, float(e[0]), r - 0.03, 2.1)
		k.quad(cx * Transform3D(Basis(Vector3.UP, PI) * Basis(Vector3.BACK, 0.04), Vector3(0, 0, 0.01)), 1.0, 0.7, B._img(R, str(e[2]), str(e[1])))
		for p in [-1.0, 1.0]:
			k.cyl(cx * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(p * 0.45, 0.3, 0.0)), 0.015, 0.015, 0.03, "tissu_rouge", 6)
	var gx: float = -2.0
	var gz: float = 1.0
	k.cyl(R.L(gx, 0, gz), 0.22, 0.25, 0.05, "bois_sombre", 14)
	k.cyl(R.L(gx, 0.05, gz), 0.035, 0.03, 0.75, "cuivre", 8)
	var gm := StandardMaterial3D.new()
	if ResourceLoader.exists("res://assets/textures/beau170/carte_marine.png"):
		gm.albedo_texture = load("res://assets/textures/beau170/carte_marine.png")
	gm.roughness = 0.5
	var globe: MeshInstance3D = Sud._boule(M.room, gm, R.P(gx, 1.08, gz), 0.27)
	(M.ctx["anims170"] as Array).append([globe, "tourne", Vector3.UP, 0.1])
	k.col_box(R.L(gx, 0.7, gz), Vector3(0.7, 1.4, 0.7))
	R.reserve(gx, gz, 0.8, 0.8)
	R.tonneau(2.0, 1.0)
	for rl in range(6):
		var a: float = TAU * rl / 6.0
		k.cyl(R.L(2.0 + cos(a) * 0.12, 0.6, 1.0 + sin(a) * 0.12) * Transform3D(Basis(Vector3(-sin(a), 0, cos(a)), 0.15), Vector3.ZERO), 0.035, 0.035, 0.65, "papier", 8)
	var fen: Transform3D = _sur_rond(M, 215.0, r - 0.01, 1.7)
	var h: float = float(M.ctx.get("hour", 12.0))
	var nuit: bool = h >= 20.0 or h < 6.0
	k.quad(fen * Transform3D(Basis(Vector3.UP, PI), Vector3.ZERO), 0.5, 0.8, B._c(R, "fenetre_ciel_n" if nuit else "fenetre_ciel_j", Color(0.1, 0.12, 0.3) if nuit else Color(0.65, 0.82, 1.0), 0.5, 0.0, 0.5 if nuit else 1.4))
	var lv: Transform3D = _sur_rond(M, 215.0, r - 0.8, 0.0)
	for i in range(3):
		var aa: float = TAU * i / 3.0
		k.box(lv * Transform3D(Basis(Vector3(cos(aa), 0, sin(aa)), 0.25), Vector3(cos(aa + PI * 0.5) * 0.12, 0.6, sin(aa + PI * 0.5) * 0.12)), Vector3(0.03, 1.25, 0.03), "bois_sombre", 1.0)
	k.cyl(lv * Transform3D(Basis(Vector3.RIGHT, -PI * 0.5 + 0.12), Vector3(0, 1.25, 0.3)), 0.05, 0.035, 0.75, "cuivre", 12)
	# la maquette de navire pendue au plafond, l'échelle vers la trappe (la terrasse et la grande lunette)
	var sm: Transform3D = R.L(1.1, R.H - 1.0, 0.9, 30.0)
	k.box(sm, Vector3(0.18, 0.12, 0.7), "bois", 1.0)
	k.box(sm * B.T3(0, 0.07, 0), Vector3(0.14, 0.02, 0.66), "bois_clair", 1.0)
	for m in range(2):
		k.cyl(sm * B.T3(0, 0.07, -0.15 + m * 0.3), 0.008, 0.008, 0.45, "bois_sombre", 5)
		k.box(sm * B.T3(0, 0.3, -0.15 + m * 0.3), Vector3(0.22, 0.2, 0.004), "tissu_creme", 1.0)
	for s2 in [-1.0, 1.0]:
		k.cyl(sm * B.T3(0, 0.07, s2 * 0.3), 0.003, 0.003, 0.95, "fer", 3, false)
	var lx: float = -1.6
	var lz2: float = -2.2
	for s3 in [-1.0, 1.0]:
		k.box(R.L(lx + s3 * 0.22, R.H * 0.5, lz2) * Transform3D(Basis(Vector3.RIGHT, -0.12), Vector3.ZERO), Vector3(0.06, R.H + 0.1, 0.06), "bois", 1.0)
	for g in range(int(R.H / 0.32)):
		k.box(R.L(lx, 0.25 + g * 0.32, lz2 + 0.3 - (0.25 + g * 0.32) * 0.12), Vector3(0.46, 0.04, 0.05), "bois", 1.0)
	k.box(R.L(lx, R.H - 0.02, lz2 - 0.2), Vector3(0.9, 0.04, 0.9), "bois_sombre", 1.0)
	k.col_box(R.L(lx, R.H * 0.5, lz2), Vector3(0.6, R.H, 0.4))
	R.reserve(lx, lz2, 0.8, 0.8)
	var examiner := func() -> void:
		var st: Dictionary = M.state()
		var n: int = int(st.get("carte171", 0))
		st["carte171"] = n + 1
		var t: Array = ["La carte de l'archipel : chaque île y est dessinée à l'encre brune, avec ses ports, ses récifs… et, dans un coin, un serpent de mer qui sourit.",
			"Philémon a noté en marge : « Ici, les courants tournent dans le sens des aiguilles d'une montre. Le mardi, dans l'autre sens. »", "Une petite croix rouge, très effacée, près de la Balafre. Philémon pose vite la loupe dessus. « Ça ? Une tache de confiture. »"]
		M.say(str(t[n % t.size()]), 7.0)
	M.act(R.P(0.0, 0, tz + 1.0), "E : examiner la carte de l'archipel", examiner, 1.0)
	B._marchand(M, 0.0, tz - 0.85, 0.0, "pointer", "vieux", "Philémon Lunette", ["Une bonne carte, c'est un rêve bien mesuré.", "Là-haut, sur la terrasse, ma grande lunette voit jusqu'à Port-Azur. Par beau temps. Et avec beaucoup d'imagination.", "Ne marche pas sur les rouleaux : ce sont des océans."],
		{"bonjour": "Ah ! Un voyageur ! D'où viens-tu ? Montre-moi sur la carte.", "vend": {"boussole": 28}, "infos": ["Chaque île que je dessine, je l'ai vue de mes yeux. Sauf celles que j'ai rêvées. Celles-là sont plus jolies."]})
	M.ctx["cloche170"] = false
	M.ctx["bonjour170"] = ["Bienvenue à la Tour Lunette !", "Entre, mais attention aux cartes qui sèchent."]
	M.ctx["entree"] = "La Tour Lunette : la grande table des cartes, les cartes punaisées au mur rond, le globe, la longue-vue à la fenêtre, la maquette de navire au plafond, et l'échelle vers la terrasse."
