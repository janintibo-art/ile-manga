extends RefCounted
## V173 : on entre dans les tours de la Citadelle des Nuées — la tour de la garde, la fauconnerie, les
## cuisines, et dans les deux tours de la porterie, la salle de la herse et la loge du portier : les
## fantômes de l'ancienne cour des Rois-Ciel y gardent leur poste (translucides, d'un bleu de lune ; ils
## flottent un peu) ; à Montjoie, dans le phare du Capitaine Isidore, le moulin de Clovis et la grange
## des Gaubert ; à Astralys, dans la tour de contrôle du Spatioport (Comète) ; à Sombreval, dans le
## mausolée du Vieux Cimetière (on y entre seul).
## Comme lieux_v171 et lieux_v172 (boutiques_v170 délègue ici les métiers qu'il ne connaît pas) : chaque
## ville pose ses portes (porte_ville) ; derrière la porte, la pièce de l'endroit (« b173 »), et celui
## qui le tient : la vraie personne de la ville quand elle existe.
## M : maisons_v81 ; R : la pièce ; B : les boutiques ; L1, L2 : les aides de lieux_v171 et lieux_v172.

const B = preload("res://scripts/boutiques_v170.gd")
const L1 = preload("res://scripts/lieux_v171.gd")
const L2 = preload("res://scripts/lieux_v172.gd")
const Sud = preload("res://scripts/maisons_sud_v169.gd")
const Animaux = preload("res://scripts/animaux_v75.gd")

const HISTOIRE := "b173"
const B173 := "beau173/"

const METIERS := {
	"corps_garde": [Vector2(8.4, 8.4), 4.2], "fauconnerie": [Vector2(8.4, 8.4), 4.6], "cuisines_ciel": [Vector2(9.0, 9.0), 4.4],
	"salle_herse": [Vector2(5.0, 5.6), 4.0], "loge_portier": [Vector2(5.0, 5.6), 3.2],
	"phare_isidore": [Vector2(5.6, 5.6), 4.0], "moulin_clovis": [Vector2(6.4, 6.4), 4.4], "grange_gaubert": [Vector2(8.6, 9.4), 5.0],
	"tour_controle": [Vector2(7.0, 7.0), 3.2], "mausolee": [Vector2(5.2, 5.2), 4.0],
}

## Les pièces rondes (les tours, le phare, le moulin, la cabine de la tour de contrôle).
const RONDS := ["corps_garde", "fauconnerie", "cuisines_ciel", "phare_isidore", "moulin_clovis", "tour_controle"]

## Les lieux où personne ne vit (on y entre seul).
const SEULS := ["mausolee"]

## id (celui de la ville) → [métier, la vraie personne, « E : entrer … », enseigne].
const VILLES := {
	"citadelle": {
		"garde": ["corps_garde", "", "dans la tour de la garde", "Tour de la garde"],
		"fauconnerie": ["fauconnerie", "", "dans la fauconnerie", "Fauconnerie"],
		"cuisines": ["cuisines_ciel", "", "dans les cuisines du château", "Cuisines"],
		"herse": ["salle_herse", "", "dans la salle de la herse", "Salle de la herse"],
		"portier": ["loge_portier", "", "dans la loge du portier", "Loge du portier"],
	},
	"montjoie": {
		"phare": ["phare_isidore", "isidore", "dans le phare du Capitaine Isidore", "Phare du Port des Mouettes"],
		"moulin": ["moulin_clovis", "clovis", "dans le moulin de Clovis", "Moulin de Clovis"],
		"grange": ["grange_gaubert", "gaubert", "dans la grange des Gaubert", "Grange des Gaubert"],
	},
	"astralys": {
		"tour": ["tour_controle", "comete", "dans la tour de contrôle du Spatioport", "Tour de contrôle"],
	},
	"sombreval": {
		"mausolee": ["mausolee", "", "dans le mausolée", "Mausolée des Vauclair"],
	},
}


static func porte_ville(style: String, id: String, door: Vector3, out: Vector3) -> bool:
	var v: Dictionary = VILLES.get(style, {})
	if not v.has(id):
		return false
	var e: Array = v[id]
	return B.porte(door, out, style, str(e[0]), str(e[1]), str(e[2]), str(e[3]), HISTOIRE)


static func has_metier(met: String) -> bool:
	return METIERS.has(met)


# =================================================================== la coque

static func _pal(st: String, met: String) -> Dictionary:
	var p := {}
	match st:
		"citadelle":
			p = {"sol": ["chateau/dalles_chateau.png", Color(0.8, 0.78, 0.74), 1.6], "mur": ["chateau/pierre_chateau.png", Color(0.86, 0.83, 0.78), 2.6],
				"bas": ["chateau/pierre_chateau.png", Color(0.64, 0.62, 0.58), 1.6], "plafond": ["montjoie/bois_planches.png", Color(0.42, 0.32, 0.25), 1.8],
				"fenetre": "aucune"}
			match met:
				"fauconnerie":
					p["sans_lampe"] = true
				"cuisines_ciel":
					p["mur"] = ["chateau/pierre_chateau.png", Color(0.74, 0.68, 0.62), 2.6]
					p["plafond"] = ["montjoie/bois_planches.png", Color(0.3, 0.24, 0.2), 1.8]
				"salle_herse":
					p["sol"] = ["montjoie/bois_planches.png", Color(0.62, 0.5, 0.4), 1.6]
					p["sans_lampe"] = true
				"loge_portier":
					p["sol"] = ["montjoie/bois_planches.png", Color(0.72, 0.58, 0.45), 1.8]
					p["bas"] = ["maisons/lambris_sombre.png", Color(0.85, 0.78, 0.72), 1.4]
					p["sans_lampe"] = true
		"montjoie":
			p = {"sol": ["montjoie/bois_planches.png", Color(0.78, 0.64, 0.5), 1.8], "mur": ["montjoie/enduit.png", Color(0.95, 0.92, 0.85), 2.5],
				"bas": ["montjoie/moellons.png", Color(0.75, 0.72, 0.68), 1.6], "plafond": ["montjoie/bois_planches.png", Color(0.48, 0.36, 0.27), 2.0],
				"fenetre": "aucune"}
			match met:
				"phare_isidore":
					p["sol"] = ["montjoie/dalles.png", Color(0.8, 0.78, 0.74), 1.2]
					p["mur"] = ["montjoie/enduit.png", Color(1.0, 0.98, 0.95), 2.2]
					p["sans_poutres"] = true
					p["sans_lampe"] = true
				"moulin_clovis":
					p["sol"] = ["montjoie/bois_planches.png", Color(0.9, 0.84, 0.74), 1.8]
					p["mur"] = ["montjoie/moellons.png", Color(0.92, 0.88, 0.82), 2.2]
					p["bas"] = ["montjoie/moellons.png", Color(0.7, 0.66, 0.6), 1.6]
					p["sans_lampe"] = true
				"grange_gaubert":
					p["sol"] = ["beau164/litiere.png", Color(0.95, 0.88, 0.7), 2.0]
					p["mur"] = ["montjoie/bois_planches.png", Color(0.62, 0.48, 0.36), 1.6]
					p["bas"] = ["montjoie/bois_planches.png", Color(0.45, 0.34, 0.26), 1.2]
					p["plafond"] = ["montjoie/bois_planches.png", Color(0.4, 0.3, 0.22), 2.0]
					p["sans_lampe"] = true
		"astralys":
			p = {"sol": ["astralys/metal_lumen.png", Color(0.82, 0.85, 0.92), 1.6], "mur": ["astralys/nacre_mur.png", Color(1.0, 1.0, 1.0), 2.0],
				"bas": ["astralys/metal_lumen.png", Color(0.72, 0.76, 0.86), 1.4], "plafond": ["astralys/nacre.png", Color(0.92, 0.94, 1.0), 2.0],
				"fenetre": "aucune", "sans_poutres": true, "porte": "verre"}
		"sombreval":
			p = {"sol": ["montjoie/dalles_donjon.png", Color(0.56, 0.57, 0.55), 1.4], "mur": ["montjoie/pierre_donjon.png", Color(0.64, 0.66, 0.64), 2.0],
				"bas": ["montjoie/mousse_donjon.png", Color(0.62, 0.64, 0.6), 1.4], "plafond": ["montjoie/pierre_donjon.png", Color(0.46, 0.47, 0.46), 2.0],
				"fenetre": "aucune", "sans_poutres": true, "sans_lampe": true}
	return p


static func build(M) -> void:
	match str(M.cur.get("metier", "")):
		"corps_garde":
			_corps_garde(M)
		"fauconnerie":
			_fauconnerie(M)
		"cuisines_ciel":
			_cuisines_ciel(M)
		"salle_herse":
			_salle_herse(M)
		"loge_portier":
			_loge_portier(M)
		"phare_isidore":
			_phare_isidore(M)
		"moulin_clovis":
			_moulin_clovis(M)
		"grange_gaubert":
			_grange_gaubert(M)
		"tour_controle":
			_tour_controle(M)
		"mausolee":
			_mausolee(M)


# =================================================================== les aides

## Un fantôme de l'ancienne cour des Rois-Ciel : un habitant (role, nom) qui tient le lieu, translucide.
static func _fantome(M, x: float, z: float, yaw: float, pose: String, role: String, nom: String, lignes: Array, menu: Dictionary = {}) -> Node:
	var f: Node = B._marchand(M, x, z, yaw, pose, role, nom, lignes, menu)
	_spectral(M, f)
	return f


## Rend une personne spectrale : translucide, d'un bleu de lune (un voile qui luit par-dessus), sans
## ombre ; une petite lueur bleue l'accompagne ; elle flotte (y0 : sa hauteur moyenne au-dessus du sol).
static func _spectral(M, f: Node, y0: float = 0.1) -> void:
	var R = M.R
	if R.mat("fantome173") == null:
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		m.albedo_color = Color(0.28, 0.5, 0.85, 0.5)
		R._put("fantome173", m)
	var n3: Node3D = f.npc
	for g in n3.find_children("*", "MeshInstance3D", true, false):
		var gi: MeshInstance3D = g
		gi.transparency = 0.42
		gi.material_overlay = R.mat("fantome173")
		gi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var l := OmniLight3D.new()
	l.name = "Lueur_fantome"
	l.light_color = Color(0.55, 0.72, 1.0)
	l.light_energy = 0.45
	l.omni_range = 2.4
	l.shadow_enabled = false
	n3.add_child(l)
	l.position = Vector3(0, 1.1, 0.25)
	f.set_meta("fantome173", true)
	(M.ctx["anims170"] as Array).append([n3, "flotte", 0.05, n3.position.y + y0, R.rng.randf() * 3.0])


## Un rai de lumière de a à b (repère de la pièce) : un cône très léger (additif), étroit à la fente,
## large de w sur le sol ; froid : bleuté.
static func _rai(M, a: Vector3, b: Vector3, w: float, froid: bool = false) -> void:
	var R = M.R
	var key: String = "rai173_froid" if froid else "rai173"
	if R.mat(key) == null:
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		m.albedo_color = Color(0.6, 0.75, 0.72, 0.05) if froid else Color(1.0, 0.86, 0.6, 0.055)
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		m.no_depth_test = false
		R._put(key, m)
	var pa: Vector3 = R.P(a.x, a.y, a.z)
	var pb: Vector3 = R.P(b.x, b.y, b.z)
	var d: Vector3 = pb - pa
	var up: Vector3 = Vector3.UP if absf(d.normalized().y) < 0.95 else Vector3.RIGHT
	var bs: Basis = Basis.looking_at(d, up) * Basis(Vector3.RIGHT, -PI * 0.5)
	R.kit.cyl(Transform3D(bs, pa), w * 0.3, w * 0.5, d.length(), key, 10, false)


## Le ciel derrière une fente (le jour : bleu clair ; la nuit : bleu nuit).
static func _ciel(M) -> String:
	var R = M.R
	return B._c(R, "ciel173_j" if R.day else "ciel173_n", Color(0.62, 0.8, 1.0) if R.day else Color(0.06, 0.08, 0.2), 0.5, 0.0, 1.5 if R.day else 0.5)


## Une meurtrière dans le mur rond (angle a, à la hauteur y) : l'ébrasement de pierre, le ciel au
## fond ; le jour, un rai de lumière qui tombe sur le sol.
static func _meurtriere(M, a: float, r: float, y: float) -> void:
	var R = M.R
	var k = R.kit
	var xf: Transform3D = L1._sur_rond(M, a, r - 0.01, y)
	k.quad(xf * Transform3D(Basis(Vector3.UP, PI), Vector3(0, 0, 0.005)), 0.13, 1.0, _ciel(M))
	for s in [-1.0, 1.0]:
		k.box(xf * Transform3D(Basis(Vector3.UP, s * 0.5), Vector3(s * 0.17, 0, 0.1)), Vector3(0.04, 1.15, 0.26), "bas", 1.0)
	k.box(xf * B.T3(0, -0.56, 0.12), Vector3(0.42, 0.06, 0.26), "bas", 1.0)
	k.box(xf * B.T3(0, 0.56, 0.12), Vector3(0.42, 0.06, 0.26), "bas", 1.0)
	R.mark_wall(sin(deg_to_rad(a)) * r, y, cos(deg_to_rad(a)) * r, 0.25)
	if R.day:
		var ar: float = deg_to_rad(a)
		var de: Vector3 = Vector3(sin(ar) * (r - 0.05), y + 0.2, cos(ar) * (r - 0.05))
		var au: Vector3 = Vector3(sin(ar) * (r - 2.3), 0.02, cos(ar) * (r - 2.3))
		_rai(M, de, au, 0.32)


## Le blason des Rois-Ciel (l'aigle d'or sur l'azur) : xf comme un tableau ; s : la largeur.
static func _blason(M, xf: Transform3D, s: float) -> void:
	var R = M.R
	var key: String = B._img(R, "blason173", B173 + "blason_rois_ciel.png", 1)
	R.kit.quad(xf * Transform3D(Basis(Vector3.UP, PI), Vector3(0, 0, 0.02)), s, s * 1.17, key)


## Une bannière de la Citadelle pendue au mur rond (angle a, le haut à y), sa hampe de fer.
static func _banniere(M, a: float, r: float, y: float) -> void:
	var R = M.R
	var k = R.kit
	var key: String = B._img(R, "banniere173", "chateau/banniere.png")
	var xf: Transform3D = L1._sur_rond(M, a, r - 0.04, y)
	k.quad(xf * Transform3D(Basis(Vector3.UP, PI), Vector3(0, -0.85, 0.03)), 0.85, 1.7, key)
	k.cyl(xf * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(0.5, 0.02, 0.06)), 0.018, 0.018, 1.0, "fer", 6)
	for s in [-1.0, 1.0]:
		R.kit.cyl(xf * B.T3(s * 0.5, 0.0, 0.06), 0.035, 0.035, 0.06, "or", 8)
	R.mark_wall(sin(deg_to_rad(a)) * r, y - 0.85, cos(deg_to_rad(a)) * r, 0.5)


## Une torche au mur rond (angle a, à la hauteur y) : le bras de fer, la torche, le feu.
static func _torche(M, a: float, r: float, y: float) -> void:
	var R = M.R
	var k = R.kit
	var xf: Transform3D = L1._sur_rond(M, a, r - 0.02, y)
	k.box(xf * B.T3(0, 0, 0.03), Vector3(0.1, 0.22, 0.04), "fer", 1.0)
	k.box(xf * Transform3D(Basis(Vector3.RIGHT, 0.6), Vector3(0, 0.02, 0.14)), Vector3(0.03, 0.03, 0.26), "fer", 1.0)
	k.cyl(xf * Transform3D(Basis(Vector3.RIGHT, 0.35), Vector3(0, 0.05, 0.26)), 0.03, 0.04, 0.42, "bois_sombre", 8)
	k.cyl(xf * Transform3D(Basis(Vector3.RIGHT, 0.35), Vector3(0, 0.4, 0.38)), 0.05, 0.045, 0.1, B._tex(R, "corde173", "beau161/corde.png", Color(0.7, 0.6, 0.45)), 8)
	R.fire(xf * Vector3(0, 0.55, 0.42), 0.32)
	R.mark_wall(sin(deg_to_rad(a)) * r, y, cos(deg_to_rad(a)) * r, 0.2)


## Un râtelier de hallebardes contre le mur rond (angle a) et deux boucliers ronds au-dessus.
static func _ratelier(M, a: float, r: float) -> void:
	var R = M.R
	var k = R.kit
	var xf: Transform3D = L1._sur_rond(M, a, r - 0.2, 0.0)
	k.box(xf * B.T3(0, 1.25, 0.05), Vector3(1.7, 0.08, 0.1), "bois_sombre", 1.0)
	k.box(xf * B.T3(0, 0.12, 0.08), Vector3(1.7, 0.12, 0.22), "bois_sombre", 1.0)
	for s in [-1.0, 1.0]:
		k.box(xf * B.T3(s * 0.84, 0.7, 0.05), Vector3(0.08, 1.4, 0.12), "bois_sombre", 1.0)
	for i in range(6):
		var px: float = -0.7 + i * 0.28
		var hx: Transform3D = xf * Transform3D(Basis(Vector3.RIGHT, -0.06), Vector3(px, 0.14, 0.1))
		k.cyl(hx, 0.018, 0.018, 2.3, "bois", 6)
		# la lame de la hallebarde : la hache, le pic, la pointe
		k.box(hx * B.T3(0.07, 2.12, 0), Vector3(0.14, 0.2, 0.012), "fer", 1.0)
		k.box(hx * B.T3(-0.05, 2.12, 0), Vector3(0.08, 0.035, 0.012), "fer", 1.0)
		k.cyl(hx * B.T3(0, 2.3, 0), 0.02, 0.0, 0.24, "fer", 4)
	for s2 in [-1.0, 1.0]:
		var bx: Transform3D = xf * B.T3(s2 * 0.5, 2.95, 0.04)
		k.cyl(bx * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 0.32, 0.32, 0.04, "bois", 18)
		k.ring(bx * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0.0, 0.0)), 0.3, 0.34, 0.05, "fer", 18)
		k.cyl(bx * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0.03, 0)), 0.08, 0.06, 0.05, "or", 12)
		k.quad(bx * Transform3D(Basis(Vector3.UP, PI), Vector3(0, 0, 0.025)), 0.34, 0.4, B._img(R, "blason173", B173 + "blason_rois_ciel.png", 1))
	k.col_box(xf * B.T3(0, 1.1, 0.1), Vector3(1.8, 2.2, 0.3))
	var ar: float = deg_to_rad(a)
	R.reserve(sin(ar) * (r - 0.3), cos(ar) * (r - 0.3), 1.0, 1.0)
	R.mark_wall(sin(ar) * r, 1.5, cos(ar) * r, 0.9)


## Une armure sur son mannequin (xf : le pied ; elle regarde +Z local).
static func _armure(M, xf: Transform3D) -> void:
	var R = M.R
	var k = R.kit
	var acier: String = B._c(R, "acier173", Color(0.72, 0.74, 0.78), 0.35, 0.85)
	k.cyl(xf, 0.25, 0.28, 0.06, "bois_sombre", 14)
	k.cyl(xf * B.T3(0, 0.06, 0), 0.03, 0.03, 0.9, "bois_sombre", 6)
	L1._ovale(M, acier, xf, Vector3(0, 1.3, 0.0), Vector3(0.21, 0.3, 0.14))
	L1._ovale(M, acier, xf, Vector3(0, 1.0, 0.0), Vector3(0.19, 0.12, 0.13))
	for s in [-1.0, 1.0]:
		L1._ovale(M, acier, xf, Vector3(s * 0.23, 1.5, 0), Vector3(0.11, 0.08, 0.11))
		k.cyl(xf * Transform3D(Basis(Vector3.BACK, s * 0.12), Vector3(s * 0.27, 0.95, 0)), 0.05, 0.055, 0.5, acier, 10)
		k.cyl(xf * B.T3(s * 0.1, 0.12, 0), 0.06, 0.055, 0.78, acier, 10)
		k.box(xf * B.T3(s * 0.1, 0.06, 0.05), Vector3(0.1, 0.08, 0.2), acier, 1.0)
	k.cyl(xf * B.T3(0, 0.82, 0), 0.24, 0.17, 0.2, acier, 14)
	k.cyl(xf * B.T3(0, 1.62, 0), 0.06, 0.07, 0.08, acier, 10)
	k.cyl(xf * B.T3(0, 1.68, 0), 0.13, 0.13, 0.2, acier, 14)
	L1._ovale(M, acier, xf, Vector3(0, 1.88, 0), Vector3(0.13, 0.08, 0.13))
	k.box(xf * B.T3(0, 1.77, 0.12), Vector3(0.16, 0.025, 0.02), "noir", 1.0)
	k.cyl(xf * B.T3(0, 1.95, -0.02), 0.012, 0.03, 0.22, "tissu_bleu", 6)
	k.col_box(xf * B.T3(0, 0.95, 0), Vector3(0.6, 1.9, 0.4))
	var p: Vector3 = xf.origin - M.R.P(0, 0, 0)
	R.reserve(p.x, p.z, 0.7, 0.7)


## Un faucon (p : les pattes, repère de la pièce ; yaw : où il regarde) ; chaperon : la tête coiffée de
## son petit capuchon de cuir. La tête est un nœud à part, qui penche de temps en temps.
static func _faucon(M, p: Vector3, yaw: float, chaperon: bool) -> void:
	var R = M.R
	var dos: Material = R.mat(B._c(R, "faucon_dos", Color(0.36, 0.26, 0.18), 0.85))
	var ventre: Material = R.mat(B._c(R, "faucon_ventre", Color(0.78, 0.66, 0.48), 0.9))
	var jaune: Material = R.mat(B._c(R, "faucon_bec", Color(0.95, 0.75, 0.2), 0.6))
	var bs := Basis(Vector3.UP, deg_to_rad(yaw))
	var base: Vector3 = R.P(p.x, p.y, p.z)
	var f: Vector3 = bs * Vector3(0, 0, 1)
	var sd: Vector3 = bs * Vector3(1, 0, 0)
	var corps := Basis(Vector3.UP, deg_to_rad(yaw)) * Basis(Vector3.RIGHT, 0.3)
	var b1: MeshInstance3D = Sud._boule(M.room, dos, base, 1.0)
	b1.global_transform = Transform3D(corps * Basis.from_scale(Vector3(0.07, 0.13, 0.065)), base + Vector3.UP * 0.15)
	var b2: MeshInstance3D = Sud._boule(M.room, ventre, base, 1.0)
	b2.global_transform = Transform3D(corps * Basis.from_scale(Vector3(0.045, 0.1, 0.042)), base + Vector3.UP * 0.15 + f * 0.03)
	for s in [-1.0, 1.0]:
		var ai: MeshInstance3D = Sud._boule(M.room, dos, base, 1.0)
		ai.global_transform = Transform3D(corps * Basis(Vector3.FORWARD, s * 0.06) * Basis.from_scale(Vector3(0.026, 0.17, 0.062)), base + Vector3.UP * 0.12 + sd * s * 0.052 - f * 0.035)
		R.kit.cyl(Transform3D(bs, base + sd * s * 0.025), 0.008, 0.01, 0.05, "or", 5)
	var q: MeshInstance3D = Sud._boule(M.room, dos, base, 1.0)
	q.global_transform = Transform3D(corps * Basis.from_scale(Vector3(0.034, 0.12, 0.012)), base - Vector3.UP * 0.01 - f * 0.08)
	var tete := Node3D.new()
	M.room.add_child(tete)
	tete.global_transform = Transform3D(bs, base + Vector3.UP * 0.29)
	var h: MeshInstance3D = Sud._boule(tete, dos, tete.global_position, 0.048)
	h.position = Vector3.ZERO
	var jo: MeshInstance3D = Sud._boule(tete, ventre, tete.global_position, 0.035)
	jo.position = Vector3(0, -0.018, 0.018)
	var bec := MeshInstance3D.new()
	bec.mesh = B._cylm(0.0, 0.014, 0.035, 6)
	bec.material_override = jaune
	tete.add_child(bec)
	bec.position = Vector3(0, -0.005, 0.055)
	bec.rotation.x = PI * 0.5
	if chaperon:
		var ch: MeshInstance3D = Sud._boule(tete, R.mat("cuir"), tete.global_position, 0.054)
		ch.position = Vector3(0, 0.01, -0.004)
		ch.scale = Vector3(1.0, 1.0, 1.05)
		var hp := MeshInstance3D.new()
		hp.mesh = B._cylm(0.0, 0.012, 0.05, 5)
		hp.material_override = R.mat("tissu_rouge")
		tete.add_child(hp)
		hp.position = Vector3(0, 0.07, 0)
	else:
		for s2 in [-1.0, 1.0]:
			var oe: MeshInstance3D = Sud._boule(tete, R.mat("noir"), tete.global_position, 0.011)
			oe.position = Vector3(s2 * 0.03, 0.01, 0.032)
	(M.ctx["anims170"] as Array).append([tete, "balance", 0.18, 0.5 + R.rng.randf() * 0.6])


## Un feu bleu de fantôme (at : repère du monde) : les flammes qui montent, une lueur bleue.
static func _feu_bleu(M, at: Vector3, s: float = 1.0) -> void:
	var R = M.R
	var p := CPUParticles3D.new()
	p.amount = 30
	p.lifetime = 0.9
	p.direction = Vector3.UP
	p.spread = 14.0
	p.initial_velocity_min = 0.25 * s
	p.initial_velocity_max = 0.6 * s
	p.gravity = Vector3(0, 0.5, 0)
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.22 * s
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.3
	var curve := Curve.new()
	curve.add_point(Vector2(0, 0.6))
	curve.add_point(Vector2(0.3, 1.0))
	curve.add_point(Vector2(1, 0.0))
	p.scale_amount_curve = curve
	var grad := Gradient.new()
	grad.set_color(0, Color(0.75, 0.95, 1.0, 1.0))
	grad.set_color(1, Color(0.15, 0.3, 0.95, 0.0))
	p.color_ramp = grad
	var q := QuadMesh.new()
	q.size = Vector2(0.24, 0.34) * s
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = R.dot_texture()
	q.material = m
	p.mesh = q
	M.room.add_child(p)
	p.global_position = at
	var l := OmniLight3D.new()
	l.light_color = Color(0.45, 0.65, 1.0)
	l.light_energy = 1.6 * s
	l.omni_range = 6.0 * s
	l.shadow_enabled = false
	M.room.add_child(l)
	l.global_position = at + Vector3.UP * 0.4


## Un chaudron (x, y, z : son fond, repère de la pièce ; r : le rayon) ; luit : la soupe qui luit.
static func _chaudron(M, x: float, y: float, z: float, r: float, luit: Color = Color(0, 0, 0, 0)) -> void:
	var R = M.R
	var k = R.kit
	var fonte: String = B._c(R, "fonte173", Color(0.12, 0.12, 0.13), 0.55, 0.6)
	k.cyl(R.L(x, y, z), r * 0.6, r, r * 0.6, fonte, 16)
	k.cyl(R.L(x, y + r * 0.6, z), r, r * 0.92, r * 0.5, fonte, 16)
	k.ring(R.L(x, y + r * 1.1, z), r * 0.86, r * 0.96, 0.04, fonte, 16)
	var soupe: String = B._c(R, "soupe173_%s" % luit.to_html(false), luit if luit.a > 0.0 else Color(0.45, 0.32, 0.15), 0.3, 0.0, 1.6 if luit.a > 0.0 else 0.0)
	k.cyl(R.L(x, y + r * 1.0, z), r * 0.88, r * 0.88, 0.02, soupe, 16)
	for s in [-1.0, 1.0]:
		k.ring(R.L(x + s * r * 0.95, y + r * 1.1, z) * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3.ZERO), r * 0.12, r * 0.16, 0.02, fonte, 10)


# =================================================================== la Citadelle des Nuées

## La tour de la garde (la tour du sud-ouest) : la grande cheminée et le blason, le râtelier des
## hallebardes, l'armure, les lits superposés, la table où deux gardes jouent aux mérelles depuis
## trois cents ans ; l'échelle vers le chemin de ronde.
static func _corps_garde(M) -> void:
	var R = M.R
	var k = R.kit
	var r: float = L1._rond(M, 22.0, 28)
	R.cheminee(0.0, -r + 0.42, 0.0)
	_blason(M, R.L(0.0, 2.6, -r + 0.53), 0.72)
	for a in [148.0, 212.0]:
		_banniere(M, a, r, 3.3)
	for a2 in [52.0, 135.0, 232.0]:
		_meurtriere(M, a2, r, 1.95)
	for a3 in [28.0, 332.0]:
		_torche(M, a3, r, 2.0)
	_ratelier(M, 262.0, r)
	_armure(M, L1._sur_rond(M, 312.0, r - 0.55, 0.0))
	var ab: float = deg_to_rad(98.0)
	R.lit(sin(ab) * (r - 0.78), cos(ab) * (r - 0.78), 188.0, 0.9, "rouge", true)
	var cf: Transform3D = L1._sur_rond(M, 72.0, r - 0.45, 0.0)
	R.coffre_deco(cf.origin.x - R.P(0, 0, 0).x, cf.origin.z - R.P(0, 0, 0).z, 72.0 + 180.0)
	# l'échelle vers le chemin de ronde, la trappe du plafond
	var al: float = deg_to_rad(292.0)
	R.echelle(sin(al) * (r - 0.95), cos(al) * (r - 0.95), 292.0 + 180.0, R.H)
	k.box(R.L(sin(al) * (r - 0.35), R.H - 0.03, cos(al) * (r - 0.35), 292.0), Vector3(0.8, 0.04, 0.7), "noir", 1.0)
	k.box(R.L(sin(al) * (r - 0.35), R.H - 0.06, cos(al) * (r - 0.35), 292.0), Vector3(0.9, 0.04, 0.8), "bois_sombre", 1.0, 8)
	var monter := func() -> void:
		M.say("Tu montes l'échelle, tu pousses la trappe : le chemin de ronde, le vent qui siffle entre les merlons… et tout en bas, la mer de nuages, si blanche qu'on dirait qu'on pourrait marcher dessus. (On ne peut pas. Le capitaine le dit à chaque recrue.)", 7.0)
	M.act(R.P(sin(al) * (r - 1.6), 0, cos(al) * (r - 1.6)), "E : monter au chemin de ronde", monter, 1.0)
	# la table des gardes, ses bancs, la partie de mérelles
	var tx: float = -1.5
	var tz: float = -0.4
	R.table(tx, tz, 90.0, 2.0, 0.85)
	R.banc(tx - 0.85, tz, 90.0, 1.8)
	R.banc(tx + 0.85, tz, 90.0, 1.8)
	var mer: String = B._img(R, "merelles173", B173 + "merelles.png")
	k.quad(R.L(tx, 0.765, tz - 0.3) * Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), Vector3.ZERO), 0.44, 0.44, mer)
	var blanc: String = B._c(R, "pion_blanc", Color(0.92, 0.9, 0.84), 0.5)
	var noir: String = B._c(R, "pion_noir", Color(0.12, 0.1, 0.1), 0.5)
	var cases: Array = [[-0.18, -0.18], [0.0, -0.18], [0.18, 0.0], [-0.12, 0.12], [0.06, 0.06], [-0.06, -0.06], [0.18, 0.18], [-0.18, 0.0]]
	for i in range(cases.size()):
		var c: Array = cases[i]
		k.cyl(R.L(tx + float(c[1]), 0.77, tz - 0.3 + float(c[0])), 0.022, 0.024, 0.02, blanc if i % 2 == 0 else noir, 10)
	k.cyl(R.L(tx, 0.76, tz + 0.45), 0.07, 0.06, 0.22, "terre_cuite", 12)
	k.ring(R.L(tx + 0.07, 0.88, tz + 0.45) * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3.ZERO), 0.04, 0.055, 0.015, "terre_cuite", 8)
	for j in range(3):
		k.cyl(R.L(tx + (-0.25 + j * 0.25), 0.76, tz + 0.15 + 0.1 * float(j % 2)), 0.035, 0.03, 0.09, "metal", 10)
	R.bougie(tx, 0.76, tz + 0.75)
	for j2 in range(4):
		Sud._boule(M.room, R.mat(B._c(R, "pomme173", Color(0.7, 0.15, 0.1), 0.5)), R.P(tx - 0.12 + j2 * 0.08, 0.81, tz - 0.75 + 0.03 * float(j2 % 2)), 0.04)
	var g1: Node = M.person("homme", tx + 0.85, tz - 0.3, -90.0, "assis", "Gauthier")
	g1.lines = ["Trois pions en ligne ! Mérelle ! … Ah non. Encore raté.", "On joue la même partie depuis trois cents ans. Je mène. Je crois."]
	_spectral(M, g1, 0.04)
	var g2: Node = M.person("vieux", tx - 0.85, tz - 0.3, 90.0, "assis", "Hubert")
	g2.lines = ["Il triche. Mais si mal que ça ne compte pas.", "À mon tour… je réfléchis. Ça peut prendre un siècle."]
	_spectral(M, g2, 0.04)
	# celui qui tient la tour : le capitaine
	_fantome(M, 1.3, -2.2, -15.0, "mains_dos", "homme", "Capitaine Bertold", ["Trois cents ans sans une seule relève. Je l'ai noté dans mon rapport.", "Personne ne nous a dit de partir. Alors on garde.", "Une garde, ça ne dort pas. Même quand c'est un fantôme. Surtout quand c'est un fantôme."],
		{"bonjour": "Halte ! … Oh, un visiteur. Pardon : trois cents ans de garde, ça donne des réflexes. Bienvenue dans la tour de la garde.",
			"infos": ["Les Rois-Ciel ont quitté la Citadelle il y a très longtemps. Nous, on est restés. On attend la relève.",
				"Les gargouilles de la cour ? De mauvaises recrues. Elles dorment le jour et bougent quand il ne faut pas.",
				"La bibliothèque garde un chant : celui des quatre cloches. Le beffroi s'en souvient, lui aussi.",
				"Les armures de la salle d'armes ne sont pas des gardes. Il n'y a personne dedans. Même pas un fantôme. Méfie-toi d'elles."]})
	R.poussiere(30)
	M.ctx["cloche170"] = false
	M.ctx["bonjour170"] = ["Halte ! … Ah, un visiteur. Entre.", "La garde te salue !"]
	M.ctx["bonjour_nuit170"] = ["La nuit, c'est notre heure. Entre donc : on ne dort jamais.", "Chut… Hubert fait semblant de dormir. Il ne dort plus depuis trois cents ans."]
	M.ctx["entree"] = "La tour de la garde : la grande cheminée et le blason des Rois-Ciel, le râtelier des hallebardes, l'armure qui veille, les lits des gardes… et les gardes eux-mêmes, qui n'ont jamais quitté leur poste. Ils sont un peu transparents. Ils sont très polis."


## La fauconnerie (la tour du sud-est) : la longue perche des faucons pèlerins (bien vivants, eux), les
## blocs, les niches où ils nichent, l'oculus du toit, la table des gants et des chaperons, la carte
## des vents ; Dame Aelis, la fauconnière.
static func _fauconnerie(M) -> void:
	var R = M.R
	var k = R.kit
	var r: float = L1._rond(M, 22.0, 28)
	for a in [42.0, 318.0, 205.0]:
		_meurtriere(M, a, r, 2.0)
	# l'oculus du plafond (le ciel), son rai de lumière
	k.cyl(R.L(0.4, R.H - 0.06, -0.6), 0.55, 0.55, 0.05, _ciel(M), 20)
	k.ring(R.L(0.4, R.H - 0.12, -0.6), 0.52, 0.66, 0.1, "bas", 20)
	if R.day:
		_rai(M, Vector3(0.4, R.H - 0.1, -0.6), Vector3(0.9, 0.02, -0.2), 0.9)
	for l in R.lights:
		(l as Node3D).global_position = R.P(-0.8, R.H - 1.0, 0.6)
	B._lampe(M, 0.4, R.H - 0.6, -0.6, Color(0.9, 0.95, 1.0) if R.day else Color(1.0, 0.8, 0.55), 0.8 if R.day else 0.5, 6.0)
	_torche(M, 160.0, r, 2.1)
	_torche(M, 250.0, r, 2.1)
	# la longue perche, contre le mur de gauche, et ses quatre faucons
	var px: Transform3D = L1._sur_rond(M, 270.0, r - 0.55, 0.0)
	k.cyl(px * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(1.3, 1.45, 0)), 0.035, 0.035, 2.6, "bois_sombre", 8)
	for s in [-1.0, 1.0]:
		k.cyl(px * B.T3(s * 1.2, 0, 0), 0.04, 0.045, 1.45, "bois_sombre", 8)
		k.box(px * B.T3(s * 1.2, 0.03, 0), Vector3(0.4, 0.06, 0.4), "bois_sombre", 1.0)
	k.box(px * B.T3(0, 0.02, 0.2), Vector3(2.6, 0.03, 0.7), B._tex(R, "litiere173", "beau164/litiere.png", Color(0.95, 0.88, 0.7)), 1.0)
	for i in range(4):
		var fp: Vector3 = px * Vector3(-0.9 + i * 0.6, 1.48, 0) - R.P(0, 0, 0)
		_faucon(M, fp, 90.0 + (i - 1.5) * 12.0, i % 2 == 1)
	k.col_box(px * B.T3(0, 0.75, 0), Vector3(2.6, 1.5, 0.3))
	var ap: float = deg_to_rad(270.0)
	R.reserve(sin(ap) * (r - 0.6), cos(ap) * (r - 0.6), 1.0, 2.8)
	# deux blocs (des billots de bois), un faucon sur chacun
	for e in [[1.9, 0.9], [2.6, -0.6]]:
		var bx: float = float(e[0])
		var bz: float = float(e[1])
		k.cyl(R.L(bx, 0, bz), 0.16, 0.18, 0.55, "bois", 12)
		k.cyl(R.L(bx, 0.55, bz), 0.17, 0.16, 0.04, B._tex(R, "corde173", "beau161/corde.png", Color(0.7, 0.6, 0.45)), 12)
		_faucon(M, Vector3(bx, 0.59, bz), -60.0 + bz * 30.0, false)
		k.col_cyl(R.P(bx, 0, bz), 0.2, 0.6)
		R.reserve(bx, bz, 0.5, 0.5)
	# le grand perchoir en T, au milieu (son faucon), la cage d'osier (un petit faucon qu'on soigne), la paille
	k.cyl(R.L(0.9, 0, -1.2), 0.25, 0.3, 0.06, "bois_sombre", 12)
	k.cyl(R.L(0.9, 0.06, -1.2), 0.035, 0.035, 1.3, "bois_sombre", 8)
	k.cyl(R.L(1.3, 1.36, -1.2) * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3.ZERO), 0.03, 0.03, 0.8, "bois_sombre", 8)
	k.cyl(R.L(1.0, 1.36, -1.2) * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3.ZERO), 0.036, 0.036, 0.2, "cuir", 8)
	_faucon(M, Vector3(0.9, 1.39, -1.2), 20.0, false)
	k.col_cyl(R.P(0.9, 0, -1.2), 0.3, 1.4)
	R.reserve(0.9, -1.2, 0.8, 0.8)
	var ag: float = deg_to_rad(200.0)
	var cgx: float = sin(ag) * (r - 0.75)
	var cgz: float = cos(ag) * (r - 0.75)
	var osier: String = B._c(R, "osier173", Color(0.72, 0.56, 0.34), 0.9)
	k.cyl(R.L(cgx, 0, cgz), 0.36, 0.36, 0.08, osier, 16)
	for b in range(14):
		var ab: float = TAU * b / 14.0
		k.cyl(R.L(cgx + cos(ab) * 0.33, 0.08, cgz + sin(ab) * 0.33), 0.012, 0.012, 0.6, osier, 4)
	k.ring(R.L(cgx, 0.4, cgz), 0.31, 0.36, 0.03, osier, 16)
	k.cyl(R.L(cgx, 0.68, cgz), 0.36, 0.06, 0.3, osier, 16)
	k.ring(R.L(cgx, 0.98, cgz), 0.03, 0.06, 0.04, "fer", 8)
	_faucon(M, Vector3(cgx, 0.08, cgz), 0.0, false)
	k.col_cyl(R.P(cgx, 0, cgz), 0.38, 1.0)
	R.reserve(cgx, cgz, 0.9, 0.9)
	var ap2: float = deg_to_rad(230.0)
	k.box(R.L(sin(ap2) * (r - 0.6), 0.25, cos(ap2) * (r - 0.6), 230.0 + 90.0), Vector3(1.0, 0.5, 0.5), B._tex(R, "foin173", "beau161/foin_rond.png", Color(0.95, 0.88, 0.62)), 1.0)
	k.col_box(R.L(sin(ap2) * (r - 0.6), 0.25, cos(ap2) * (r - 0.6), 230.0 + 90.0), Vector3(1.0, 0.5, 0.5))
	# les niches du mur du fond, en hauteur : la paille, un faucon qui regarde dehors
	for j in range(3):
		var aj: float = 165.0 + j * 15.0
		var nx: Transform3D = L1._sur_rond(M, aj, r - 0.18, 3.0)
		for sy in [-1.0, 1.0]:
			k.box(nx * B.T3(0, sy * 0.25, 0.0), Vector3(0.66, 0.07, 0.38), "bas", 1.0)
			k.box(nx * B.T3(sy * 0.3, 0, 0.0), Vector3(0.07, 0.5, 0.38), "bas", 1.0)
		k.quad(nx * Transform3D(Basis(Vector3.UP, PI), Vector3(0, 0, -0.16)), 0.56, 0.44, "noir")
		k.box(nx * B.T3(0, -0.19, 0.0), Vector3(0.54, 0.05, 0.34), B._tex(R, "litiere173", "beau164/litiere.png", Color(0.95, 0.88, 0.7)), 1.0)
		if j != 1:
			var npos: Vector3 = nx * Vector3(0, -0.17, 0.12) - R.P(0, 0, 0)
			_faucon(M, npos, aj + 180.0, false)
		R.mark_wall(sin(deg_to_rad(aj)) * r, 3.0, cos(deg_to_rad(aj)) * r, 0.35)
	# la table des gants, des chaperons, du leurre
	var tf: Transform3D = L1._sur_rond(M, 128.0, r - 0.7, 0.0)
	k.box(tf * B.T3(0, 0.78, 0), Vector3(1.4, 0.06, 0.6), "bois", 1.0)
	for sx in [-1.0, 1.0]:
		k.box(tf * B.T3(sx * 0.6, 0.38, 0), Vector3(0.08, 0.76, 0.5), "bois_sombre", 1.0)
	for g in range(2):
		var gx: Transform3D = tf * B.T3(-0.45 + g * 0.28, 0.81, 0.05)
		k.box(gx * Transform3D(Basis(Vector3.UP, 0.3 * g), Vector3.ZERO), Vector3(0.14, 0.05, 0.3), "cuir", 1.0)
		k.box(gx * Transform3D(Basis(Vector3.UP, 0.3 * g), Vector3(0.0, 0.0, 0.17)), Vector3(0.1, 0.04, 0.08), "cuir", 1.0)
	for h in range(3):
		var hx: Transform3D = tf * B.T3(0.05 + h * 0.15, 0.81, -0.12)
		k.cyl(hx, 0.045, 0.05, 0.07, "cuir", 10)
		k.cyl(hx * B.T3(0, 0.07, 0), 0.008, 0.002, 0.05, ["tissu_rouge", "tissu_vert", "tissu_jaune"][h], 5)
	var lx: Transform3D = tf * B.T3(0.45, 0.81, 0.12)
	k.box(lx, Vector3(0.16, 0.03, 0.1), "cuir", 1.0)
	for s3 in [-1.0, 1.0]:
		k.box(lx * Transform3D(Basis(Vector3.UP, s3 * 0.5), Vector3(s3 * 0.1, 0.02, 0)), Vector3(0.18, 0.01, 0.05), "faucon_dos", 1.0)
	k.ring(tf * B.T3(0.3, 0.81, 0.2), 0.05, 0.08, 0.02, B._tex(R, "corde173", "beau161/corde.png", Color(0.7, 0.6, 0.45)), 12)
	k.col_box(tf * B.T3(0, 0.4, 0), Vector3(1.4, 0.8, 0.6))
	var at: float = deg_to_rad(128.0)
	R.reserve(sin(at) * (r - 0.7), cos(at) * (r - 0.7), 1.4, 1.4)
	B._cadre(R, B._img(R, "carte_ciel173", "beau170/carte_ciel.png"), sin(deg_to_rad(232.0)) * (r - 0.02), 2.0, cos(deg_to_rad(232.0)) * (r - 0.02), 232.0 + 180.0, 1.1, 0.8, "bois_sombre")
	# des plumes par terre, et de la paille
	var pl: String = B._c(R, "plume173", Color(0.85, 0.82, 0.76), 0.9)
	for n in range(9):
		var a4: float = R.rng.randf() * TAU
		var d4: float = R.rng.randf_range(0.6, r - 0.8)
		k.box(R.L(cos(a4) * d4, 0.005, sin(a4) * d4, R.rng.randf() * 360.0), Vector3(0.025, 0.004, 0.12), pl if n % 2 == 0 else "faucon_dos", 1.0, 4)
	var siffler := func() -> void:
		M.say(str(B._pick(M, ["Tu siffles doucement. Quatre têtes se tournent vers toi d'un seul coup. Les deux faucons coiffés de leur chaperon font semblant de ne pas avoir entendu.", "« Doucement, dit Aelis. Ils n'aiment pas qu'on siffle faux. » Le plus petit faucon ébouriffe ses plumes, vexé pour toi."])), 6.0)
	M.act(R.P(-2.2, 0, 0.4), "E : siffler les faucons", siffler, 1.0)
	_fantome(M, -2.1, -1.1, 30.0, "bras_croises", "femme", "Dame Aelis", ["Les faucons pèlerins sont revenus d'eux-mêmes. Les fauconniers, eux, ne sont jamais partis.", "Un faucon ne s'apprivoise pas. Il accepte, ou il n'accepte pas.", "Celui-là, c'est Éclair. Il est vexé depuis mardi."],
		{"bonjour": "Entre sans courir : on n'effraie pas un faucon. Bienvenue dans ma fauconnerie.",
			"infos": ["Du temps des Rois-Ciel, les grands aigles se posaient sur l'Aire des Vents, et les faucons portaient les messages d'une tour à l'autre.",
				"Le chaperon, c'est pour qu'ils se reposent. Un faucon qui ne voit rien croit que c'est la nuit, et il dort.",
				"Les grands aigles ? Il n'en reste qu'une, dit-on. Si tu la croises, salue-la de ma part. Elle comprendra."]})
	M.ctx["cloche170"] = false
	M.ctx["bonjour170"] = ["Doucement… Entre.", "Les faucons t'ont vu avant moi."]
	M.ctx["bonjour_nuit170"] = ["Les faucons dorment. Parle tout bas.", "La nuit, je compte les plumes. Il y en a toujours une de trop."]
	M.ctx["entree"] = "La fauconnerie : la longue perche et ses faucons pèlerins (bien vivants, eux), les niches où ils nichent, l'oculus ouvert sur le ciel, les gants de cuir, les petits chaperons… et Dame Aelis, la fauconnière, qui n'est plus tout à fait là."


## Les cuisines du château (la tour du nord-ouest) : l'âtre immense où brûle un feu bleu de fantôme, le
## chaudron qui luit, le four à pain, la grande table, la batterie de cuivre, les oignons qui pendent ;
## Dame Brioche, la cuisinière, et le chat de la cuisine (bien vivant).
static func _cuisines_ciel(M) -> void:
	var R = M.R
	var k = R.kit
	var r: float = L1._rond(M, 22.0, 30)
	var pierre: String = "bas"
	# l'âtre : les deux piédroits, le manteau, la hotte jusqu'au plafond
	var hz: float = -r + 0.6
	for s in [-1.0, 1.0]:
		k.box(R.L(s * 1.35, 0.75, hz), Vector3(0.36, 1.5, 0.9), pierre, 1.0)
	k.box(R.L(0, 1.62, hz + 0.05), Vector3(3.1, 0.26, 0.95), "bois_sombre", 1.0)
	k.box(R.L(0, 1.75 + (R.H - 1.75) * 0.5, hz - 0.1), Vector3(2.6, R.H - 1.75, 0.7), pierre, 1.0)
	k.box(R.L(0, 0.75, hz - 0.36), Vector3(2.4, 1.5, 0.08), "noir", 1.0)
	k.box(R.L(0, 0.04, hz + 0.1), Vector3(2.4, 0.08, 1.0), pierre, 1.0)
	for s2 in [-1.0, 1.0]:
		k.box(R.L(s2 * 0.45, 0.2, hz), Vector3(0.05, 0.3, 0.5), "fer", 1.0)
	for j in range(3):
		k.cyl(R.L(-0.4 + j * 0.25, 0.14, hz + 0.05) * Transform3D(Basis(Vector3.BACK, PI * 0.5) * Basis(Vector3.UP, 0.3 * j), Vector3.ZERO), 0.07, 0.07, 0.9, "bois_sombre", 7)
	_feu_bleu(M, R.P(0, 0.3, hz), 1.1)
	# la crémaillère, le grand chaudron qui luit (une soupe bleue : de la soupe de nuage)
	k.cyl(R.L(0, 0.95, hz - 0.05), 0.012, 0.012, 0.7, "fer", 4)
	_chaudron(M, 0.0, 0.48, hz - 0.05, 0.3, Color(0.4, 0.75, 1.0))
	k.col_box(R.L(0, 0.75, hz), Vector3(3.1, 1.5, 0.95))
	R.reserve(0, hz, 3.3, 1.6)
	_blason(M, R.L(0.0, 2.6, hz + 0.26), 0.6)
	R.mark_wall(0, 2.4, -r, 1.6)
	# le four à pain (sa voûte de terre, ses braises) et la pelle à enfourner
	L1._four(M, sin(deg_to_rad(218.0)) * (r - 0.85), cos(deg_to_rad(218.0)) * (r - 0.85))
	var pe: Transform3D = L1._sur_rond(M, 236.0, r - 0.15, 0.0)
	k.cyl(pe * Transform3D(Basis(Vector3.RIGHT, -0.12), Vector3(0, 0.05, 0.1)), 0.02, 0.02, 1.9, "bois", 6)
	k.box(pe * Transform3D(Basis(Vector3.RIGHT, -0.12), Vector3(0, 0.12, 0.12)), Vector3(0.3, 0.3, 0.02), "bois", 1.0)
	# la batterie de cuivre, au mur de gauche
	var bc: Transform3D = L1._sur_rond(M, 280.0, r - 0.08, 2.1)
	k.box(bc, Vector3(2.0, 0.08, 0.06), "bois_sombre", 1.0)
	for i in range(6):
		var rr: float = 0.09 + 0.025 * float(i % 3)
		var hx: Transform3D = bc * B.T3(-0.8 + i * 0.32, -0.08, 0.06)
		k.cyl(hx * B.T3(0, -0.05, 0), 0.006, 0.006, 0.05, "fer", 4)
		k.cyl(hx * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, -0.12 - rr, 0.02)), rr, rr, 0.06, "cuivre", 14)
		k.box(hx * B.T3(0, -0.07, 0.02), Vector3(0.03, 0.12, 0.02), "cuivre", 1.0)
	R.mark_wall(sin(deg_to_rad(280.0)) * r, 2.0, cos(deg_to_rad(280.0)) * r, 1.0)
	# les étagères des pots et des bocaux, au mur de droite
	L2._rayon_rond(M, 82.0, r, 1.4, 1.9, 4, "pots", 3)
	L2._rayon_rond(M, 104.0, r, 1.2, 1.9, 4, "bocaux", 5)
	# les tonneaux (de l'eau, de la farine), les sacs, la pierre à évier
	var at: float = deg_to_rad(318.0)
	R.tonneau(sin(at) * (r - 0.6), cos(at) * (r - 0.6))
	var at2: float = deg_to_rad(302.0)
	R.tonneau(sin(at2) * (r - 0.6), cos(at2) * (r - 0.6))
	B._sac(R, sin(deg_to_rad(52.0)) * (r - 0.6), cos(deg_to_rad(52.0)) * (r - 0.6), Color(0.96, 0.94, 0.9))
	B._sac(R, sin(deg_to_rad(62.0)) * (r - 0.55), cos(deg_to_rad(62.0)) * (r - 0.55), Color(0.85, 0.7, 0.35), 0.9)
	var ev: Transform3D = L1._sur_rond(M, 140.0, r - 0.45, 0.0)
	k.box(ev * B.T3(0, 0.42, 0), Vector3(1.1, 0.84, 0.6), pierre, 1.0)
	k.box(ev * B.T3(0, 0.85, 0.02), Vector3(0.8, 0.04, 0.42), "noir", 1.0)
	k.cyl(ev * B.T3(0.4, 0.84, -0.18), 0.04, 0.04, 0.5, "fer", 8)
	k.box(ev * Transform3D(Basis(Vector3.RIGHT, 0.4), Vector3(0.4, 1.36, -0.08)), Vector3(0.025, 0.025, 0.25), "fer", 1.0)
	k.col_box(ev * B.T3(0, 0.45, 0), Vector3(1.1, 0.9, 0.6))
	R.reserve(sin(deg_to_rad(140.0)) * (r - 0.45), cos(deg_to_rad(140.0)) * (r - 0.45), 1.2, 1.2)
	# la grande table de travail : les pains, la meule de fromage, les choux, les carottes, la tarte
	var tx: float = -0.7
	var tz: float = -0.4
	R.table(tx, tz, 0.0, 2.4, 0.95, 0.86)
	var y: float = 0.86
	k.cyl(R.L(tx - 0.8, y, tz), 0.2, 0.2, 0.12, B._c(R, "fromage173", Color(0.95, 0.78, 0.35), 0.6), 18)
	k.box(R.L(tx - 0.8, y + 0.06, tz + 0.2), Vector3(0.12, 0.1, 0.05), B._c(R, "fromage173", Color(0.95, 0.78, 0.35), 0.6), 1.0)
	for j2 in range(3):
		Sud._boule(M.room, R.mat(B._c(R, "chou173", Color(0.42, 0.62, 0.3), 0.8)), R.P(tx - 0.35 + j2 * 0.17, y + 0.09, tz - 0.25), 0.09)
	for j3 in range(5):
		k.cyl(R.L(tx - 0.1 + j3 * 0.06, y + 0.02, tz + 0.2) * Transform3D(Basis(Vector3.BACK, PI * 0.5) * Basis(Vector3.UP, 0.2 * j3), Vector3.ZERO), 0.022, 0.0, 0.22, B._c(R, "carotte173", Color(0.95, 0.48, 0.12), 0.7), 7)
	B._pains(R, R.L(tx + 0.25, y, tz - 0.25) * Transform3D(Basis(Vector3.UP, 0.1), Vector3.ZERO), 3, 0.24)
	var croute: String = B._c(R, "croute173", Color(0.82, 0.55, 0.25), 0.8)
	k.cyl(R.L(tx + 0.85, y, tz + 0.1), 0.2, 0.18, 0.05, "ceramique", 18)
	k.cyl(R.L(tx + 0.85, y + 0.05, tz + 0.1), 0.18, 0.18, 0.03, B._c(R, "myrtille173", Color(0.3, 0.25, 0.6), 0.5, 0.0, 0.4), 18)
	for j4 in range(4):
		k.box(R.L(tx + 0.85, y + 0.085, tz + 0.1, 45.0 + 90.0 * float(j4 % 2)) * B.T3(0, 0, -0.1 + floorf(j4 * 0.5) * 0.2), Vector3(0.34, 0.015, 0.03), croute, 1.0)
	k.ring(R.L(tx + 0.85, y + 0.05, tz + 0.1), 0.16, 0.2, 0.04, croute, 18)
	k.cyl(R.L(tx + 0.45, y + 0.03, tz + 0.2) * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3.ZERO), 0.03, 0.03, 0.42, "bois_clair", 8)
	k.cyl(R.L(tx + 0.4, y, tz - 0.15), 0.18, 0.12, 0.12, "terre_cuite", 16)
	Sud._boule(M.room, R.mat(B._c(R, "pate173", Color(0.95, 0.9, 0.78), 0.9)), R.P(tx + 0.4, y + 0.12, tz - 0.15), 0.12, Vector3(1, 0.5, 1))
	# les tresses d'oignons, les herbes qui sèchent
	B._herbes(M, 0.6, 2.4, 0.9)
	var oi: Material = R.mat(B._c(R, "oignon173", Color(0.75, 0.5, 0.25), 0.7))
	for t in range(2):
		var ox: float = -2.4 + t * 0.6
		k.cyl(R.L(ox, R.H - 1.2, 1.2), 0.012, 0.012, 1.2, B._tex(R, "corde173", "beau161/corde.png", Color(0.7, 0.6, 0.45)), 5)
		for o in range(6):
			Sud._boule(M.room, oi, R.P(ox + 0.05 * float(o % 2) - 0.025, R.H - 1.15 + o * 0.17, 1.2), 0.055)
	# le chat de la cuisine, près de l'âtre (bien vivant, lui)
	R.chat(1.6, hz + 0.95, 200.0, Color(0.85, 0.55, 0.25), true)
	R.poussiere(25)
	var gouter := func() -> void:
		M.say("Tu goûtes la tarte des Rois-Ciel : c'est léger, léger… une myrtille, un nuage. Tu as l'impression d'avoir mangé, mais ton ventre n'est pas au courant.", 7.0)
	_fantome(M, 0.85, -0.4, -90.0, "cuisiner", "femme", "Dame Brioche", ["Une pincée de nuage, une pincée de vent… et on remue dans le sens des aiguilles d'une horloge. C'est important.", "Le feu bleu ne brûle pas. Mais il cuit. Ne me demande pas comment.", "Trois cents ans que je prépare le banquet du retour du roi. Il sera chaud, le jour venu."],
		{"bonjour": "Entre, entre, mais ne touche pas au chaudron ! Bienvenue dans mes cuisines.",
			"services": [{"label": "Goûter la tarte des Rois-Ciel", "cb": gouter}],
			"infos": ["Ici, on nourrissait toute la Citadelle : les gardes, les fauconniers, les bibliothécaires… et le roi, qui aimait la soupe de nuage.",
				"Le chat ? Il est arrivé un jour par la fenêtre et il n'est jamais reparti. Il est bien vivant. Il mange pour nous tous.",
				"La soupe de nuage, c'est simple : un nuage du matin, jamais de l'après-midi. Ceux de l'après-midi sont pleins d'orage."]})
	M.ctx["cloche170"] = false
	M.ctx["bonjour170"] = ["Entre ! Mais essuie tes pieds, j'ai lavé il y a deux siècles.", "Ça sent bon, hein ? C'est la soupe de nuage."]
	M.ctx["bonjour_nuit170"] = ["La nuit, je prépare le pain du matin. Un matin, il viendra bien quelqu'un le manger.", "Chut, le chat dort."]
	M.ctx["entree"] = "Les cuisines du château : l'âtre immense où brûle un feu bleu qui ne brûle pas, le grand chaudron qui luit, le four à pain, la batterie de cuivre, les oignons qui pendent, la tarte sur la table… Dame Brioche y prépare depuis trois cents ans le banquet du retour du roi."


## La salle de la herse (la tour ouest de la porterie) : la grande roue à cage où marche Fanfan, le
## page (il fait monter la herse), le tambour et sa chaîne, le contrepoids, l'assommoir.
static func _salle_herse(M) -> void:
	var R = M.R
	var k = R.kit
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var cz: float = -1.3
	var ay: float = 1.78
	var rr: float = 1.55
	# les deux chevalets (des A) qui portent l'essieu : la roue nous fait face
	for fz in [-0.8, 0.8]:
		for sx in [-1.0, 1.0]:
			var a: float = atan2(sx * 0.85, ay)
			k.box(R.L(sx * 0.42, ay * 0.5, cz + fz) * Transform3D(Basis(Vector3.BACK, a), Vector3.ZERO), Vector3(0.14, ay / cos(a) + 0.1, 0.14), "bois_sombre", 1.0)
			k.col_box(R.L(sx * 0.85, 0.4, cz + fz), Vector3(0.2, 0.8, 0.2))
		k.box(R.L(0, 0.06, cz + fz), Vector3(2.0, 0.12, 0.16), "bois_sombre", 1.0)
	k.cyl(R.L(0, ay, cz - 1.45) * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 0.08, 0.08, 2.9, "fer", 10)
	# la roue (un nœud qui tourne autour de l'essieu) : deux jantes, les rayons, les marches
	var roue := Node3D.new()
	roue.name = "Roue_herse"
	M.room.add_child(roue)
	roue.global_position = R.P(0, ay, cz)
	var bois: Material = R.mat("bois")
	var sombre: Material = R.mat("bois_sombre")
	var n: int = 20
	for i in range(n):
		var t: float = TAU * (i + 0.5) / n
		for sz2 in [-0.58, 0.58]:
			var seg := MeshInstance3D.new()
			seg.mesh = B._boitem(2.0 * rr * sin(PI / n) + 0.03, 0.14, 0.08)
			seg.material_override = sombre
			roue.add_child(seg)
			seg.position = Vector3(cos(t) * rr, sin(t) * rr, sz2)
			seg.rotation.z = t + PI * 0.5
		var marche := MeshInstance3D.new()
		marche.mesh = B._boitem(2.0 * (rr - 0.08) * sin(PI / n) - 0.03, 0.04, 1.1)
		marche.material_override = bois
		roue.add_child(marche)
		marche.position = Vector3(cos(t) * (rr - 0.09), sin(t) * (rr - 0.09), 0)
		marche.rotation.z = t + PI * 0.5
	for j in range(8):
		var t2: float = TAU * j / 8.0
		for sz3 in [-0.6, 0.6]:
			var ray := MeshInstance3D.new()
			ray.mesh = B._boitem(rr, 0.06, 0.07)
			ray.material_override = sombre
			roue.add_child(ray)
			ray.position = Vector3(cos(t2) * rr * 0.5, sin(t2) * rr * 0.5, sz3)
			ray.rotation.z = t2
	var anim: Array = [roue, "tourne", Vector3(0, 0, 1), 0.35]
	(M.ctx["anims170"] as Array).append(anim)
	R.reserve(0, cz, 3.4, 1.9)
	# le tambour (derrière la roue) et la chaîne qui monte vers la herse
	var tb := MeshInstance3D.new()
	tb.mesh = B._cylm(0.24, 0.24, 0.36, 16)
	tb.material_override = sombre
	roue.add_child(tb)
	tb.position = Vector3(0, 0, -1.08)
	tb.rotation.x = PI * 0.5
	var maille: String = "fer"
	for c in range(int((R.H - ay - 0.1) / 0.09)):
		k.ring(R.L(0.24, ay + 0.06 + c * 0.09, cz - 1.08) * Transform3D(Basis(Vector3.UP, PI * 0.5 * float(c % 2)) * Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 0.022, 0.034, 0.012, maille, 8)
	k.box(R.L(0.24, R.H - 0.02, cz - 1.08), Vector3(0.4, 0.04, 0.4), "noir", 1.0)
	# le contrepoids (un bloc de pierre) et sa poulie
	var cpx: float = hw - 0.5
	var cpz: float = -hd + 0.5
	k.cyl(R.L(cpx + 0.04, R.H - 0.2, cpz) * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3.ZERO), 0.14, 0.14, 0.08, "bois_sombre", 12)
	for c2 in range(int((R.H - 2.2) / 0.09)):
		k.ring(R.L(cpx, 2.2 + c2 * 0.09, cpz) * Transform3D(Basis(Vector3.UP, PI * 0.5 * float(c2 % 2)) * Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 0.022, 0.034, 0.012, maille, 8)
	k.box(R.L(cpx, 1.85, cpz), Vector3(0.55, 0.6, 0.55), "bas", 1.0)
	k.ring(R.L(cpx, 2.17, cpz), 0.05, 0.08, 0.05, "fer", 10)
	k.col_box(R.L(cpx, 1.85, cpz), Vector3(0.55, 0.6, 0.55))
	# l'assommoir : une grille dans le plancher, le passage de la porte tout en bas
	var gx: float = -1.4
	var gz: float = 1.0
	k.box(R.L(gx, 0.005, gz), Vector3(0.9, 0.012, 0.9), "noir", 1.0, 4)
	for g in range(7):
		k.box(R.L(gx - 0.39 + g * 0.13, 0.03, gz), Vector3(0.03, 0.03, 0.9), "fer", 1.0)
		k.box(R.L(gx, 0.03, gz - 0.39 + g * 0.13), Vector3(0.9, 0.03, 0.03), "fer", 1.0)
	k.box(R.L(gx, 0.02, gz), Vector3(1.05, 0.04, 1.05), "bas", 1.0, 4)
	var regarder := func() -> void:
		M.say(str(B._pick(M, ["Tu regardes par l'assommoir : tout en bas, le passage de la grande porte, ses pavés usés… et une gargouille de la cour qui fait semblant d'être une statue.", "Par la grille : le passage, la herse relevée au-dessus, et le ciel au bout, tout blanc de nuages. Un courant d'air te chatouille le nez."])), 6.0)
	M.act(R.P(gx, 0, gz), "E : regarder par l'assommoir", regarder, 1.0)
	# la fente sur le dehors, la lanterne, le pot de graisse, les outils
	k.quad(R.L(hw - 0.035, 2.0, 0.6, -90.0) * Transform3D(Basis(Vector3.UP, PI), Vector3.ZERO), 0.14, 0.9, _ciel(M))
	for s6 in [-1.0, 1.0]:
		k.box(R.L(hw - 0.08, 2.0, 0.6 + s6 * 0.12), Vector3(0.12, 1.0, 0.08), "bas", 1.0)
	R.mark_wall(hw, 2.0, 0.6, 0.2)
	if R.day:
		_rai(M, Vector3(hw - 0.05, 2.2, 0.6), Vector3(hw - 1.8, 0.02, 1.0), 0.5)
	B._lanterne(M, 1.5, 0.9)
	B._lanterne(M, -1.7, -0.2)
	k.cyl(R.L(1.85, 0, 1.6), 0.13, 0.11, 0.3, "terre_cuite", 12)
	k.cyl(R.L(1.85, 0.3, 1.6), 0.11, 0.11, 0.02, B._c(R, "graisse173", Color(0.35, 0.28, 0.15), 0.4), 12)
	k.cyl(R.L(1.85, 0.3, 1.6) * Transform3D(Basis(Vector3.BACK, 0.4), Vector3.ZERO), 0.012, 0.01, 0.4, "bois", 5)
	for c3 in range(3):
		k.ring(R.L(-1.9, 0.02 + c3 * 0.045, 0.3), 0.1 + 0.02 * c3, 0.17 + 0.02 * c3, 0.045, B._tex(R, "corde173", "beau161/corde.png", Color(0.7, 0.6, 0.45)), 16)
	k.box(R.L(-hw + 0.05, 2.35, 0.9, 90.0), Vector3(1.3, 0.4, 0.04), "bois_sombre", 1.0)
	B._ecrit(M, -hw + 0.08, 2.35, 0.9, 90.0, "UNE ROUE · UN PAGE · UNE HERSE\nMerci de ne pas courir dans la roue.", 40, Color(0.92, 0.88, 0.78), 0.0026)
	R.mark_wall(-hw, 2.35, 0.9, 0.7)
	var ralentir := func() -> void:
		anim[3] = 0.35
	var aider := func() -> void:
		anim[3] = 1.1
		M.say("Tu montes dans la roue à côté de Fanfan et vous marchez ensemble : grrr, grrr… là-haut, la herse grince. « Pas trop vite ! Sinon elle remonte jusqu'au ciel, et après, il faut tout redescendre. »", 6.0)
		M.timer(5.0).connect(ralentir)
	M.act(R.P(1.0, 0, cz + 1.25), "E : aider Fanfan à faire tourner la roue", aider, 1.0)
	var f: Node = B._marchand(M, 0.0, cz, -90.0, "marcher", "garcon", "Fanfan", ["Un pas, deux pas, trois pas… la herse monte d'un doigt.", "J'étais page. Maintenant je suis page ET roue. C'est une promotion.", "Ne me fais pas rire, sinon je trébuche."],
		{"bonjour": "Oh, un visiteur ! Je ne peux pas m'arrêter, sinon la herse redescend. Bonjour quand même !",
			"infos": ["La grande roue fait monter la herse. Il faut cent pas pour une coudée. J'ai compté.",
				"Le capitaine dit qu'un jour, le roi reviendra, et qu'il faudra ouvrir la porte vite. Alors je m'entraîne.",
				"La grille par terre, c'est l'assommoir. Avant, on y jetait des pierres sur les méchants. Maintenant, j'y fais tomber des miettes pour les oiseaux."]})
	_spectral(M, f, 1.78 - rr + 0.11)
	M.ctx["cloche170"] = false
	M.ctx["bonjour170"] = ["Bonjour ! … Je ne m'arrête pas, hein !", "Un visiteur ! Un, deux, un, deux…"]
	M.ctx["bonjour_nuit170"] = ["La nuit aussi, je marche. La herse ne dort jamais.", "Chut, le capitaine fait sa ronde."]
	M.ctx["entree"] = "La salle de la herse : la grande roue à cage qui tourne, tourne… et dedans, Fanfan, le petit page, qui marche depuis trois cents ans pour que la herse reste levée. Le tambour, la chaîne, le contrepoids, et la grille de l'assommoir."


## La loge du portier (la tour est de la porterie) : le tableau des clés, le registre des visiteurs,
## le lit étroit, le petit poêle, la tapisserie des Rois-Ciel ; Maître Gaspard, le portier, et le chat
## qui l'a adopté.
static func _loge_portier(M) -> void:
	var R = M.R
	var k = R.kit
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	# le bureau, le registre ouvert, l'encrier, la plume, la bougie ; la chaise
	var dx: float = 1.15
	var dz: float = -1.25
	R.table(dx, dz, 0.0, 1.3, 0.7)
	k.box(R.L(dx - 0.1, 0.77, dz + 0.05, 8.0), Vector3(0.62, 0.05, 0.44), B._c(R, "registre173", Color(0.4, 0.14, 0.1), 0.8), 1.0)
	for s in [-1.0, 1.0]:
		k.box(R.L(dx - 0.1, 0.81, dz + 0.05, 8.0) * B.T3(s * 0.15, 0, 0), Vector3(0.28, 0.025, 0.4), "papier", 1.0)
	k.cyl(R.L(dx + 0.4, 0.76, dz - 0.15), 0.04, 0.045, 0.06, "noir", 10)
	k.cyl(R.L(dx + 0.4, 0.8, dz - 0.15) * Transform3D(Basis(Vector3.BACK, 0.35), Vector3.ZERO), 0.006, 0.002, 0.26, "tissu_blanc", 5)
	R.bougie(dx - 0.5, 0.76, dz - 0.2)
	R.chaise(dx, dz - 0.62, 0.0)
	# le tableau des clés (au mur de gauche, près de la porte)
	var kx: Transform3D = R.L(-hw + 0.02, 1.55, 0.7, 90.0)
	k.box(kx * B.T3(0, 0, 0.02), Vector3(1.1, 0.75, 0.04), "bois_sombre", 1.0)
	var cle: String = B._c(R, "cle173", Color(0.4, 0.38, 0.36), 0.45, 0.7)
	for row in range(3):
		for c in range(5):
			var cx2: Transform3D = kx * B.T3(-0.4 + c * 0.2, 0.22 - row * 0.22, 0.05)
			k.cyl(cx2 * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 0.006, 0.006, 0.04, "or", 4)
			if (row * 5 + c) % 7 == 3:
				continue
			k.ring(cx2 * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, -0.04, 0.0)), 0.018, 0.03, 0.008, cle, 8)
			k.box(cx2 * B.T3(0, -0.12, 0.0), Vector3(0.012, 0.12, 0.012), cle, 1.0)
			k.box(cx2 * B.T3(0.018, -0.17, 0.0), Vector3(0.025, 0.03, 0.01), cle, 1.0)
	R.mark_wall(-hw, 1.55, 0.7, 0.6)
	# le lit étroit (et le chat dessus), le coffre, le petit poêle de fonte
	R.lit(-hw + 0.55, -hd + 1.05, 0.0, 0.85, "bleu")
	R.chat(-hw + 0.5, -hd + 1.3, 30.0, Color(0.25, 0.24, 0.26), true, 0.56)
	var fonte: String = B._c(R, "fonte173", Color(0.12, 0.12, 0.13), 0.55, 0.6)
	var px: float = hw - 0.5
	var pz: float = 1.3
	k.cyl(R.L(px, 0.0, pz), 0.24, 0.26, 0.7, fonte, 14)
	k.cyl(R.L(px, 0.7, pz), 0.27, 0.27, 0.05, fonte, 14)
	k.cyl(R.L(px, 0.75, pz), 0.06, 0.06, R.H - 0.75, fonte, 8)
	k.box(R.L(px - 0.24, 0.3, pz, -90.0), Vector3(0.2, 0.16, 0.02), B._c(R, "braises171", Color(1.0, 0.42, 0.12), 0.6, 0.0, 2.2), 1.0)
	B._lampe(M, px - 0.4, 0.4, pz, Color(1.0, 0.6, 0.3), 0.8, 3.0)
	_chaudron(M, px, 0.75, pz, 0.1)
	k.col_cyl(R.P(px, 0, pz), 0.3, 1.0)
	R.reserve(px, pz, 0.7, 0.7)
	# la tapisserie des Rois-Ciel, au mur de droite ; la petite fenêtre grillagée du fond
	var tap: String = B._img(R, "tapisserie173", B173 + "tapisserie_rois_ciel.png")
	B._cadre(R, tap, hw - 0.02, 1.75, -0.4, -90.0, 0.95, 1.42, "")
	k.cyl(R.L(hw - 0.06, 2.5, -0.4) * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 0.015, 0.015, 1.1, "bois_sombre", 6)
	k.quad(R.L(-0.6, 1.9, -hd + 0.035) * Transform3D(Basis(Vector3.UP, PI), Vector3.ZERO), 0.5, 0.4, _ciel(M))
	for b in range(4):
		k.box(R.L(-0.78 + b * 0.12, 1.9, -hd + 0.04), Vector3(0.02, 0.42, 0.02), "fer", 1.0)
	k.box(R.L(-0.6, 1.68, -hd + 0.08), Vector3(0.62, 0.05, 0.16), "bas", 1.0)
	R.mark_wall(-0.6, 1.9, -hd, 0.35)
	B._lanterne(M, 0.0, 0.0)
	R.tapis(-0.2, 0.2, 0.0, 1.4, 1.0)
	var signer := func() -> void:
		var st: Dictionary = M.state()
		st["signe173"] = int(st.get("signe173", 0)) + 1
		if int(st["signe173"]) == 1:
			M.say("Tu écris ton nom dans le registre des visiteurs, sous le dernier : « Sire Orage, gardien de la tour — pour affaires de tempête ». Et avant lui… personne depuis trois cents ans. Gaspard sèche l'encre en soufflant dessus. Très fier.", 8.0)
		else:
			M.say("Tu signes encore une fois. « Deux fois le même visiteur, dit Gaspard ravi. C'est le début de la foule. »", 6.0)
	M.act(R.P(dx - 0.1, 0, dz + 0.7), "E : signer le registre des visiteurs", signer, 0.9)
	var f: Node = B._marchand(M, dx, dz - 0.62, 0.0, "assis", "vieux", "Maître Gaspard", ["Qui va là ? … Ah, un vivant. Ça fait plaisir, on en voit si peu.", "Le chat est venu tout seul. Il dit que je suis le portier le plus calme du monde.", "Toutes les clés sont là. Enfin, presque toutes."],
		{"bonjour": "Qui va là ? … Bienvenue, voyageur ! Tu veux bien signer le registre ? C'est la règle.",
			"infos": ["La grande porte du donjon ne s'ouvre pas avec une clé. Il faut les deux cristaux et le Sceau des Vents. Je l'ai noté quelque part.",
				"Une clé manque au tableau : celle de la cave. Je la cherche depuis trois cents ans. La cave aussi, d'ailleurs.",
				"Le chat ? Il s'appelle Monseigneur. C'est lui qui l'a décidé."]})
	_spectral(M, f, 0.03)
	M.ctx["cloche170"] = false
	M.ctx["bonjour170"] = ["Qui va là ? … Entre, entre.", "Un visiteur ! Je prends le registre."]
	M.ctx["bonjour_nuit170"] = ["La porte est fermée la nuit… mais pas pour toi.", "Chut. Monseigneur dort."]
	M.ctx["entree"] = "La loge du portier : le tableau des clés (il en manque une), le registre des visiteurs ouvert sur le bureau, le lit étroit où dort un chat noir, le petit poêle, la tapisserie des Rois-Ciel… et Maître Gaspard, le portier, qui garde la porte depuis trois cents ans."


# =================================================================== Montjoie

## Une bête (animaux_v75 : « cochon », « rat », « mouette »…) posée dans la pièce (p : repère de la
## pièce) ; elle respire, bouge un peu (pose), à chaque image.
static func _bete(M, espece: String, v: Dictionary, p: Vector3, yaw: float, pose: String) -> Node3D:
	var R = M.R
	var a: Node3D = Animaux.build(espece, v)
	M.room.add_child(a)
	a.global_transform = Transform3D(Basis(Vector3.UP, deg_to_rad(yaw)), R.P(p.x, p.y, p.z))
	if not M.ctx.has("betes173"):
		M.ctx["betes173"] = []
		M.ctx["tick170"] = func(delta: float) -> void:
			var t: float = float(M.ctx.get("t170", 0.0))
			for e in M.ctx.get("betes173", []):
				if is_instance_valid(e[0]):
					Animaux.animate(e[0], t, 0.0, str(e[1]), 0.0, delta)
	(M.ctx["betes173"] as Array).append([a, pose])
	return a


## Le phare du Port des Mouettes, où habite le Capitaine Isidore (« une maison avec vue sur la mer »,
## disait Prosper) : l'escalier de pierre qui tourne le long du mur vers la lanterne, le hamac, le coffre
## de marin, la grande lentille de rechange, le baromètre, la carte marine, le hublot et sa mouette.
static func _phare_isidore(M) -> void:
	var R = M.R
	var k = R.kit
	var r: float = L1._rond(M, 24.0, 24)
	# l'escalier : des marches de pierre prises dans le mur (de 100° à 320°), jusqu'à la trappe
	var n: int = 14
	for i in range(n):
		var a: float = 100.0 + i * (220.0 / (n - 1))
		var y: float = 0.27 * (i + 1)
		var xf: Transform3D = L1._sur_rond(M, a, r - 0.45, y)
		k.box(xf * B.T3(0, -0.09, 0), Vector3(0.76, 0.18, 0.9), "bas", 1.0)
		k.box(xf * B.T3(0, -0.005, 0.44), Vector3(0.76, 0.01, 0.03), "bois_sombre", 1.0)
		if y < 1.7:
			k.col_box(xf * B.T3(0, -y * 0.5, 0), Vector3(0.7, y, 0.9))
	var atr: float = deg_to_rad(326.0)
	k.box(R.L(sin(atr) * (r - 0.5), R.H - 0.02, cos(atr) * (r - 0.5), 326.0), Vector3(0.8, 0.03, 0.8), "noir", 1.0)
	k.box(R.L(sin(atr) * (r - 0.5), R.H - 0.05, cos(atr) * (r - 0.5), 326.0), Vector3(0.9, 0.04, 0.9), "bois_sombre", 1.0, 8)
	var monter := func() -> void:
		M.say("Tu montes. Et tu montes. Cent trente-huit, cent trente-neuf… cent quarante ! La lanterne, sa grande lentille de verre qui tourne doucement, et toute la mer d'un seul coup d'œil : les barques du Port des Mouettes, Montjoie sur sa butte, et très loin, une voile. « Chaque soir, dit Isidore, je compte les marches. Parfois cent quarante et une : c'est que j'ai rêvé. »", 9.0)
	var am: float = deg_to_rad(100.0)
	M.act(R.P(sin(am) * 1.3, 0, cos(am) * 1.3), "E : monter les cent quarante marches", monter, 1.0)
	# le hamac, sous l'escalier, entre deux crochets
	var ha: float = deg_to_rad(197.0)
	var hb: float = deg_to_rad(253.0)
	var pa := Vector3(sin(ha) * (r - 0.08), 1.25, cos(ha) * (r - 0.08))
	var pb := Vector3(sin(hb) * (r - 0.08), 1.25, cos(hb) * (r - 0.08))
	var prev: Vector3 = pa
	var ns: int = 10
	for s in range(1, ns + 1):
		var t: float = float(s) / ns
		var p: Vector3 = pa.lerp(pb, t) + Vector3.DOWN * 0.55 * 4.0 * t * (1.0 - t)
		if s > 1 and s < ns:
			var d: Vector3 = p - prev
			var bs := Basis.looking_at(d, Vector3.UP)
			k.box(Transform3D(bs, R.P((prev.x + p.x) * 0.5, (prev.y + p.y) * 0.5, (prev.z + p.z) * 0.5)), Vector3(0.78, 0.03, d.length() + 0.02), "tissu_blanc" if s % 2 == 0 else "tissu_bleu", 1.0)
		else:
			k.cyl(Transform3D(Basis.looking_at(p - prev, Vector3.UP) * Basis(Vector3.RIGHT, -PI * 0.5), R.P(prev.x, prev.y, prev.z)), 0.008, 0.008, (p - prev).length(), B._tex(R, "corde173", "beau161/corde.png", Color(0.7, 0.6, 0.45)), 4)
		prev = p
	for e in [pa, pb]:
		k.ring(R.L(e.x, e.y, e.z), 0.02, 0.035, 0.02, "fer", 8)
	k.box(R.L(sin(deg_to_rad(225.0)) * (r - 0.35), 0.95, cos(deg_to_rad(225.0)) * (r - 0.35), 225.0), Vector3(0.36, 0.12, 0.25), "tissu_rouge", 1.0)
	# le coffre de marin, sous les marches
	var ca: float = deg_to_rad(152.0)
	R.coffre_deco(sin(ca) * (r - 0.5), cos(ca) * (r - 0.5), 152.0 + 180.0)
	# la grande lentille de rechange (des anneaux de verre dans leur cadre de laiton), sur sa caisse
	var la: Transform3D = L1._sur_rond(M, 55.0, r - 0.55, 0.0)
	k.box(la * B.T3(0, 0.3, 0), Vector3(0.7, 0.6, 0.55), "bois", 1.0)
	k.box(la * B.T3(0, 0.3, 0.28), Vector3(0.6, 0.06, 0.01), "bois_sombre", 1.0)
	var verre: String = B._verre(R, "lentille173", Color(0.8, 0.95, 1.0), 0.35, 0.2)
	for j in range(5):
		var rj: float = 0.06 + j * 0.065
		k.ring(la * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0.98, 0.0 - 0.012 * j)), rj, rj + 0.05, 0.05 + 0.02 * j, verre, 24)
	k.ring(la * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0.98, 0.02)), 0.38, 0.42, 0.06, "cuivre", 24)
	k.box(la * B.T3(0, 0.62, 0), Vector3(0.3, 0.04, 0.2), "cuivre", 1.0)
	k.col_box(la * B.T3(0, 0.5, 0), Vector3(0.75, 1.0, 0.6))
	R.reserve(sin(deg_to_rad(55.0)) * (r - 0.55), cos(deg_to_rad(55.0)) * (r - 0.55), 0.9, 0.9)
	# le baromètre, la carte marine, le manteau du capitaine et sa casquette
	var bx: Transform3D = L1._sur_rond(M, 80.0, r - 0.03, 1.6)
	k.cyl(bx * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0, 0.02)), 0.16, 0.16, 0.04, "cuivre", 20)
	k.cyl(bx * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0, 0.045)), 0.13, 0.13, 0.01, "papier", 20)
	k.box(bx * Transform3D(Basis(Vector3.BACK, 0.6), Vector3(0, 0.03, 0.055)), Vector3(0.01, 0.11, 0.005), "noir", 1.0)
	R.mark_wall(sin(deg_to_rad(80.0)) * r, 1.6, cos(deg_to_rad(80.0)) * r, 0.2)
	var cm: float = deg_to_rad(272.0)
	B._cadre(R, B._img(R, "carte_marine173", "beau170/carte_marine.png"), sin(cm) * (r - 0.02), 1.45, cos(cm) * (r - 0.02), 272.0 + 180.0, 1.0, 0.72, "bois_sombre")
	var mx: Transform3D = L1._sur_rond(M, 300.0, r - 0.12, 0.0)
	k.box(mx * B.T3(0, 1.85, -0.05), Vector3(0.06, 0.06, 0.12), "cuivre", 1.0)
	k.box(mx * B.T3(0, 1.4, 0.0), Vector3(0.5, 0.85, 0.12), "tissu_bleu", 1.0)
	k.box(mx * B.T3(0, 1.8, 0.03), Vector3(0.36, 0.1, 0.1), "tissu_bleu", 1.0)
	for bt in range(3):
		k.cyl(mx * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0.06, 1.65 - bt * 0.2, 0.065)), 0.018, 0.018, 0.01, "or", 8)
	k.cyl(mx * B.T3(0.32, 1.95, -0.02), 0.13, 0.14, 0.07, "tissu_bleu", 14)
	k.box(mx * B.T3(0.32, 1.96, 0.1), Vector3(0.2, 0.015, 0.1), "noir", 1.0)
	# la bouée de sauvetage (près de la porte) et la vieille roue de gouvernail
	var bo: Transform3D = L1._sur_rond(M, 34.0, r - 0.07, 2.2)
	k.ring(bo * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 0.17, 0.3, 0.1, "tissu_rouge", 20)
	for q in range(4):
		var aq: float = TAU * q / 4.0 + PI * 0.25
		k.box(bo * Transform3D(Basis(Vector3.BACK, aq), Vector3(cos(aq) * 0.235, sin(aq) * 0.235, 0.0)), Vector3(0.14, 0.09, 0.105), "tissu_blanc", 1.0)
	k.ring(bo * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0, 0.005)), 0.3, 0.32, 0.03, B._tex(R, "corde173", "beau161/corde.png", Color(0.7, 0.6, 0.45)), 20)
	R.mark_wall(sin(deg_to_rad(34.0)) * r, 2.2, cos(deg_to_rad(34.0)) * r, 0.35)
	var gv: Transform3D = L1._sur_rond(M, 319.0, r - 0.12, 1.55)
	k.ring(gv * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 0.36, 0.42, 0.05, "bois", 24)
	k.cyl(gv * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0, -0.04)), 0.07, 0.07, 0.1, "cuivre", 12)
	for q2 in range(8):
		var a5: float = TAU * q2 / 8.0
		k.cyl(gv * Transform3D(Basis(Vector3.BACK, a5), Vector3.ZERO), 0.018, 0.014, 0.4, "bois", 6)
		k.cyl(gv * Transform3D(Basis(Vector3.BACK, a5), Vector3.ZERO) * B.T3(0, 0.42, 0), 0.022, 0.03, 0.14, "bois_sombre", 6)
	k.box(gv * B.T3(0, 0, -0.1), Vector3(0.1, 0.1, 0.1), "fer", 1.0)
	R.mark_wall(sin(deg_to_rad(319.0)) * r, 1.55, cos(deg_to_rad(319.0)) * r, 0.6)
	# le hublot sur la mer, et la mouette qui entre par là (elle s'est posée sur une marche)
	var hx: Transform3D = L1._sur_rond(M, 126.0, r - 0.01, 1.75)
	var h: float = float(M.ctx.get("hour", 12.0))
	var nuit: bool = h >= 20.0 or h < 6.0
	k.cyl(hx * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 0.24, 0.24, 0.02, B._c(R, "hublot_mer_n" if nuit else "hublot_mer_j", Color(0.1, 0.12, 0.3) if nuit else Color(0.6, 0.8, 1.0), 0.3, 0.0, 0.5 if nuit else 1.4), 16)
	k.ring(hx * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 0.24, 0.31, 0.06, "cuivre", 16)
	R.mark_wall(sin(deg_to_rad(126.0)) * r, 1.75, cos(deg_to_rad(126.0)) * r, 0.35)
	var ag: float = deg_to_rad(117.0)
	_bete(M, "mouette", {"taille": 0.9, "seed": 4}, Vector3(sin(ag) * (r - 0.5), 0.54, cos(ag) * (r - 0.5)), 117.0 + 180.0 - 40.0, "")
	# la petite table ronde (la bouteille et son bateau, la tasse, le livre de bord), la chaise
	R.table_ronde(0.6, -0.55, 0.42, 0.72)
	var bt2: Transform3D = R.L(0.6, 0.72, -0.55, 25.0)
	k.cyl(bt2 * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(0.14, 0.055, 0)), 0.05, 0.05, 0.28, B._verre(R, "bouteille173", Color(0.7, 0.9, 0.8), 0.3), 12)
	k.cyl(bt2 * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(-0.14, 0.055, 0)), 0.02, 0.05, 0.06, B._verre(R, "bouteille173", Color(0.7, 0.9, 0.8), 0.3), 10)
	k.box(bt2 * B.T3(0, 0.035, 0), Vector3(0.14, 0.025, 0.035), "bois_sombre", 1.0)
	k.box(bt2 * B.T3(0, 0.075, 0), Vector3(0.006, 0.06, 0.006), "bois", 1.0)
	k.box(bt2 * B.T3(0.01, 0.07, 0), Vector3(0.05, 0.04, 0.003), "tissu_blanc", 1.0)
	k.cyl(R.L(0.85, 0.72, -0.35), 0.04, 0.035, 0.09, "ceramique", 10)
	k.box(R.L(0.4, 0.73, -0.75, 15.0), Vector3(0.22, 0.04, 0.3), B._c(R, "registre173", Color(0.4, 0.14, 0.1), 0.8), 1.0)
	R.chaise(1.15, -0.2, -110.0)
	B._lanterne(M, -0.3, 0.2)
	for l in R.lights:
		(l as Node3D).global_position = R.P(-0.2, R.H - 1.2, 0.2)
	B._marchand(M, -0.6, -0.4, 20.0, "bras_croises", "vieux", "Capitaine Isidore", ["Cent quarante marches. Je les compte chaque soir.", "Prosper m'a vendu une maison « avec vue sur la mer ». Il n'a pas menti.", "La mouette ? Elle s'appelle Amiral. C'est elle qui commande."],
		{"bonjour": "Ohé ! Bienvenue à bord… enfin, dans mon phare.", "infos": ["La lentille de rechange, c'est pour le jour où l'autre se fâche. Une lentille, ça a du caractère."]})
	M.ctx["cloche170"] = false
	M.ctx["bonjour170"] = ["Ohé ! Bienvenue dans mon phare !", "Attention à la mouette : elle mord les lacets."]
	M.ctx["entree"] = "Le phare du Port des Mouettes : l'escalier de pierre qui tourne vers la lanterne, le hamac, le coffre de marin, la grande lentille de rechange, le baromètre… Le Capitaine Isidore y habite. « Sans meubles », disait Prosper. Il y en a, maintenant."


## Le moulin de Clovis : les meules dans leur cuve de bois (la meule tourne), la trémie pleine de grain,
## l'arbre qui monte vers le grand rouet du plafond (il tourne aussi), la goulotte et le sac de farine,
## les sacs entassés, la balance, le tamis, l'échelle vers l'étage ; la farine qui danse dans la lumière.
static func _moulin_clovis(M) -> void:
	var R = M.R
	var k = R.kit
	var r: float = L1._rond(M, 22.0, 28)
	var poudre: String = B._c(R, "poudre173", Color(0.8, 0.76, 0.68), 0.95)
	# l'archure : l'estrade, la meule dormante, la cuve de bois
	k.cyl(R.L(0, 0, 0), 1.0, 1.05, 0.42, "bois_sombre", 20)
	k.cyl(R.L(0, 0.42, 0), 0.7, 0.7, 0.1, "pierre", 20)
	k.ring(R.L(0, 0.42, 0), 0.7, 0.82, 0.4, "bois", 20)
	k.ring(R.L(0, 0.82, 0), 0.68, 0.86, 0.04, "bois_sombre", 20)
	for i in range(6):
		var a: float = TAU * i / 6.0
		k.box(R.L(cos(a) * 0.83, 0.62, sin(a) * 0.83, -rad_to_deg(a) + 90.0), Vector3(0.05, 0.42, 0.03), "fer", 1.0)
	# la meule qui tourne (et l'arbre, qui monte jusqu'au plafond)
	var meule := Node3D.new()
	meule.name = "Meule"
	M.room.add_child(meule)
	meule.global_position = R.P(0, 0.52, 0)
	var mm := MeshInstance3D.new()
	mm.mesh = B._cylm(0.66, 0.66, 0.16, 24)
	mm.material_override = R.mat("pierre")
	meule.add_child(mm)
	mm.position = Vector3(0, 0.08, 0)
	var arbre := MeshInstance3D.new()
	arbre.mesh = B._cylm(0.1, 0.11, R.H - 0.52, 10)
	arbre.material_override = R.mat("bois_sombre")
	meule.add_child(arbre)
	arbre.position = Vector3(0, (R.H - 0.52) * 0.5, 0)
	for j in range(4):
		var fe := MeshInstance3D.new()
		fe.mesh = B._boitem(0.04, 0.02, 1.2)
		fe.material_override = R.mat("noir")
		meule.add_child(fe)
		fe.position = Vector3(0, 0.165, 0)
		fe.rotation.y = PI * 0.25 * j
	(M.ctx["anims170"] as Array).append([meule, "tourne", Vector3.UP, 0.7])
	B._engrenage(M, R.P(0, R.H - 0.55, 0), Basis(), 1.05, 28, 0.12, 0.7, R.mat("bois"))
	# la trémie pleine de grain, sur son chevalet
	var tx: float = 0.45
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			k.box(R.L(tx + sx * 0.32, 1.12, sz * 0.32), Vector3(0.06, 0.6, 0.06), "bois_sombre", 1.0)
	k.cyl(R.L(tx, 1.15, 0, 45.0), 0.07, 0.44, 0.5, "bois", 4)
	k.cyl(R.L(tx, 1.6, 0, 45.0), 0.4, 0.33, 0.06, B._c(R, "grain173", Color(0.86, 0.68, 0.32), 0.9), 4)
	k.box(R.L(tx * 0.5, 1.02, 0) * Transform3D(Basis(Vector3.BACK, 0.35), Vector3.ZERO), Vector3(0.42, 0.03, 0.14), "bois", 1.0)
	k.col_cyl(R.P(0, 0, 0), 1.05, 1.4)
	R.reserve(0, 0, 2.3, 2.3)
	# la goulotte, et le sac où coule la farine
	k.box(R.L(1.05, 0.55, 0.25) * Transform3D(Basis(Vector3.BACK, -0.45), Vector3.ZERO), Vector3(0.5, 0.05, 0.16), "bois", 1.0)
	B._sac(R, 1.42, 0.3, Color(0.97, 0.95, 0.9))
	k.cyl(R.L(1.3, 0.004, 0.5), 0.22, 0.22, 0.006, poudre, 16)
	# les sacs entassés, contre le mur de gauche
	for s in range(5):
		var a2: float = deg_to_rad(250.0 + s * 9.0)
		B._sac(R, sin(a2) * (r - 0.45), cos(a2) * (r - 0.45), Color(0.97, 0.95, 0.9) if s % 2 == 0 else Color(0.86, 0.68, 0.32), 0.95)
	for s2 in range(3):
		var sx2: Transform3D = L1._sur_rond(M, 284.0 + s2 * 2.0, r - 0.5, 0.18 + s2 * 0.3)
		k.box(sx2 * Transform3D(Basis(Vector3.UP, 0.2 * s2), Vector3.ZERO), Vector3(0.75, 0.28, 0.45), B._toile(R), 1.0)
	k.col_box(L1._sur_rond(M, 286.0, r - 0.5, 0.45), Vector3(0.8, 0.9, 0.5))
	# la balance sur sa petite table ; le tamis et la pelle au mur ; le balai
	var bt: Transform3D = L1._sur_rond(M, 62.0, r - 0.45, 0.0)
	k.box(bt * B.T3(0, 0.72, 0), Vector3(0.8, 0.05, 0.5), "bois", 1.0)
	for sx3 in [-1.0, 1.0]:
		k.box(bt * B.T3(sx3 * 0.34, 0.36, 0), Vector3(0.06, 0.72, 0.44), "bois_sombre", 1.0)
	B._balance(R, bt * B.T3(0, 0.745, 0))
	k.col_box(bt * B.T3(0, 0.37, 0), Vector3(0.8, 0.75, 0.5))
	var ta: Transform3D = L1._sur_rond(M, 118.0, r - 0.04, 1.7)
	k.ring(ta * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0, 0.04)), 0.26, 0.3, 0.08, "bois", 20)
	k.cyl(ta * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0, 0.04)), 0.26, 0.26, 0.005, "tissu_creme", 20)
	R.mark_wall(sin(deg_to_rad(118.0)) * r, 1.7, cos(deg_to_rad(118.0)) * r, 0.35)
	L1._balai(M, sin(deg_to_rad(330.0)) * (r - 0.3), cos(deg_to_rad(330.0)) * (r - 0.3), 330.0 + 180.0)
	# l'échelle vers l'étage (et sa trappe)
	var al: float = deg_to_rad(200.0)
	R.echelle(sin(al) * (r - 0.95), cos(al) * (r - 0.95), 200.0 + 180.0, R.H)
	k.box(R.L(sin(al) * (r - 0.35), R.H - 0.03, cos(al) * (r - 0.35), 200.0), Vector3(0.8, 0.04, 0.7), "noir", 1.0)
	# les petites fenêtres, la farine par terre, la poussière de farine dans la lumière
	for a3 in [84.0, 296.0]:
		var fx: Transform3D = L1._sur_rond(M, a3, r - 0.01, 2.3)
		k.quad(fx * Transform3D(Basis(Vector3.UP, PI), Vector3(0, 0, 0.005)), 0.45, 0.45, _ciel(M))
		k.box(fx * B.T3(0, 0, 0.04), Vector3(0.04, 0.5, 0.06), "bois_sombre", 1.0)
		k.box(fx * B.T3(0, 0, 0.04), Vector3(0.5, 0.04, 0.06), "bois_sombre", 1.0)
		k.box(fx * B.T3(0, -0.27, 0.08), Vector3(0.6, 0.05, 0.16), "bois", 1.0)
		R.mark_wall(sin(deg_to_rad(a3)) * r, 2.3, cos(deg_to_rad(a3)) * r, 0.35)
		if R.day:
			var ar: float = deg_to_rad(a3)
			_rai(M, Vector3(sin(ar) * (r - 0.05), 2.3, cos(ar) * (r - 0.05)), Vector3(sin(ar) * (r - 2.6), 0.02, cos(ar) * (r - 2.6) + 0.4), 0.42)
	for f in range(4):
		var a4: float = R.rng.randf() * TAU
		var d4: float = R.rng.randf_range(1.2, r - 0.6)
		k.cyl(R.L(cos(a4) * d4, 0.003, sin(a4) * d4), 0.08 + 0.05 * float(f % 3), 0.08 + 0.05 * float(f % 3), 0.004, poudre, 12)
	R.poussiere(70)
	B._lanterne(M, -1.4, 1.1)
	B._lanterne(M, 1.5, -1.3)
	for l in R.lights:
		(l as Node3D).global_position = R.P(-1.2, R.H - 1.3, 1.0)
	var couler := func() -> void:
		M.say("Le grain descend de la trémie, la meule tourne, et la farine coule dans le sac, douce et tiède comme de la neige qu'on aurait laissée au soleil. « Quand le vent souffle, Montjoie mange », dit Clovis.", 7.0)
	M.act(R.P(1.4, 0, 0.95), "E : regarder la farine couler", couler, 0.9)
	B._marchand(M, -1.5, -1.0, 28.0, "bras_croises", "homme", "Clovis", ["Le vent tourne, la meule tourne, et le meunier… attend.", "Ne touche pas la meule : elle mord. Enfin, elle écrase.", "Toute la farine de Montjoie passe par ici. Même celle des gâteaux d'Honorine."],
		{"bonjour": "Bienvenue au moulin ! Attention, ça farine.", "infos": ["La meule du haut tourne sur celle du bas. Le grain passe entre les deux, et il en sort de la farine. C'est tout simple. Il a juste fallu mille ans pour y penser."]})
	M.ctx["cloche170"] = false
	M.ctx["bonjour170"] = ["Bienvenue au moulin !", "Entre ! Tu vas ressortir tout blanc."]
	M.ctx["entree"] = "Le moulin de Clovis : la meule qui tourne dans sa cuve de bois, la trémie pleine de grain, l'arbre qui monte vers le grand rouet du plafond, la farine qui coule dans le sac… et qui danse dans la lumière des petites fenêtres."


## Une poule (p : ses pattes, repère de la pièce) : le corps, la queue, la tête, la crête, le bec.
static func _poule(M, p: Vector3, yaw: float, c: Color) -> void:
	var R = M.R
	var pl: String = B._c(R, "poule_%s" % c.to_html(false), c, 0.9)
	var bs := Basis(Vector3.UP, deg_to_rad(yaw))
	var xf := Transform3D(bs, R.P(p.x, p.y, p.z))
	L1._ovale(M, pl, xf, Vector3(0, 0.16, 0), Vector3(0.12, 0.1, 0.15))
	L1._ovale(M, pl, xf, Vector3(0, 0.22, -0.13), Vector3(0.04, 0.09, 0.06))
	L1._ovale(M, pl, xf, Vector3(0, 0.3, 0.11), Vector3(0.05, 0.055, 0.05))
	L1._ovale(M, B._c(R, "crete173", Color(0.85, 0.12, 0.1), 0.6), xf, Vector3(0, 0.36, 0.11), Vector3(0.012, 0.03, 0.04))
	L1._ovale(M, "crete173", xf, Vector3(0, 0.27, 0.15), Vector3(0.01, 0.02, 0.012))
	R.kit.cyl(xf * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0.3, 0.155)), 0.0, 0.012, 0.03, "or", 5)
	for s in [-1.0, 1.0]:
		R.kit.cyl(xf * B.T3(s * 0.04, 0.0, 0), 0.008, 0.008, 0.08, "or", 4)


## La grange des Gaubert : le fenil plein de bottes de foin (et son échelle), l'enclos de Pistache la
## truie (elle dort), le perchoir des poules et les pondoirs, la charrette, la charrue, les outils au
## mur, les bidons de lait, la baratte, la grosse botte ronde où dort le chat ; Père Gaubert.
static func _grange_gaubert(M) -> void:
	var R = M.R
	var k = R.kit
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var foin: String = B._tex(R, "foin173", "beau161/foin_rond.png", Color(0.95, 0.88, 0.62))
	# le fenil : son plancher à 2,6 m au fond, la sablière, les poteaux et leurs contrefiches
	var fz1: float = -1.5
	var fy: float = 2.6
	k.box(R.L(0, fy, (-hd + fz1) * 0.5), Vector3(R.W, 0.12, fz1 + hd), "bois", 1.0)
	k.box(R.L(0, fy - 0.17, fz1 - 0.12), Vector3(R.W, 0.22, 0.22), "bois_sombre", 1.0)
	for x in [-3.4, -1.15, 1.15, 3.4]:
		k.box(R.L(x, (fy - 0.28) * 0.5, fz1 - 0.12), Vector3(0.2, fy - 0.28, 0.2), "bois_sombre", 1.0)
		k.col_box(R.L(x, (fy - 0.28) * 0.5, fz1 - 0.12), Vector3(0.22, fy - 0.28, 0.22))
		for s in [-1.0, 1.0]:
			k.box(R.L(x + s * 0.32, fy - 0.55, fz1 - 0.12) * Transform3D(Basis(Vector3.BACK, s * 0.8), Vector3.ZERO), Vector3(0.12, 0.8, 0.12), "bois_sombre", 1.0)
	# les bottes de foin, sur le fenil ; du foin qui dépasse
	for row in range(2):
		for i in range(7):
			if row == 1 and (i == 0 or i == 6 or i == 3):
				continue
			var bx: float = -3.3 + i * 1.1 + 0.15 * float(row)
			k.box(R.L(bx, fy + 0.31 + row * 0.5, -hd + 0.6 + row * 0.15, 3.0 * float(i % 3)), Vector3(1.0, 0.48, 0.52), foin, 1.0)
			k.box(R.L(bx, fy + 0.31 + row * 0.5, -hd + 1.25, 3.0 * float(i % 3)), Vector3(1.0, 0.48, 0.52), foin, 1.0)
	for j in range(6):
		k.box(R.L(-3.0 + j * 1.25, fy + 0.04, fz1 + 0.05) * Transform3D(Basis(Vector3.RIGHT, 0.5 + 0.15 * float(j % 2)), Vector3.ZERO), Vector3(0.7, 0.04, 0.35), foin, 1.0)
	R.echelle(2.3, fz1 + 0.68, 0.0, fy + 0.4)
	# l'enclos de Pistache (sous le fenil, à gauche) : la clôture, la paille, l'auge
	var px0: float = -hw + 0.1
	var px1: float = -1.45
	var pz0: float = -hd + 0.1
	var pz1: float = -2.0
	for e in [[px0, pz1, px1, pz1], [px1, pz1, px1, pz0]]:
		var a := Vector2(float(e[0]), float(e[1]))
		var b := Vector2(float(e[2]), float(e[3]))
		var l: float = a.distance_to(b)
		var nseg: int = int(l / 0.7) + 1
		for q in range(nseg + 1):
			var pp: Vector2 = a.lerp(b, float(q) / nseg)
			k.box(R.L(pp.x, 0.45, pp.y), Vector3(0.09, 0.9, 0.09), "bois_sombre", 1.0)
		var ang: float = rad_to_deg(atan2(b.x - a.x, b.y - a.y))
		for hy in [0.35, 0.75]:
			k.box(R.L((a.x + b.x) * 0.5, hy, (a.y + b.y) * 0.5, ang), Vector3(0.05, 0.1, l), "bois", 1.0)
		k.col_box(R.L((a.x + b.x) * 0.5, 0.5, (a.y + b.y) * 0.5, ang), Vector3(0.12, 1.0, l))
	k.box(R.L((px0 + px1) * 0.5, 0.01, (pz0 + pz1) * 0.5), Vector3(px1 - px0, 0.02, pz1 - pz0), foin, 1.0)
	k.box(R.L(-2.0, 0.15, -2.4), Vector3(0.8, 0.3, 0.32), "bois_sombre", 1.0)
	k.box(R.L(-2.0, 0.27, -2.4), Vector3(0.7, 0.04, 0.22), B._c(R, "patee173", Color(0.55, 0.45, 0.3), 0.9), 1.0)
	R.reserve((px0 + px1) * 0.5, (pz0 + pz1) * 0.5, px1 - px0, pz1 - pz0)
	_bete(M, "cochon", {"taille": 1.15, "seed": 3}, Vector3(-3.0, 0.02, -3.4), 65.0, "dort")
	# le perchoir des poules et les pondoirs (sous le fenil, à droite)
	var rx: float = 2.6
	var rz: float = -3.6
	for s2 in [-1.0, 1.0]:
		k.box(R.L(rx + s2 * 0.8, 0.45, rz), Vector3(0.06, 0.9, 0.06), "bois_sombre", 1.0)
	k.cyl(R.L(rx + 0.85, 0.85, rz) * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3.ZERO), 0.03, 0.03, 1.7, "bois", 6)
	var cols: Array = [Color(0.6, 0.32, 0.15), Color(0.95, 0.93, 0.88), Color(0.25, 0.2, 0.18)]
	for h in range(3):
		_poule(M, Vector3(rx - 0.5 + h * 0.5, 0.88, rz), 180.0 + (h - 1) * 25.0, cols[h])
	for nb in range(3):
		var nx: float = 1.5 + nb * 0.62
		k.box(R.L(nx, 0.55, -hd + 0.32), Vector3(0.56, 0.06, 0.5), "bois", 1.0)
		k.box(R.L(nx, 0.8, -hd + 0.07), Vector3(0.56, 0.5, 0.04), "bois", 1.0)
		k.box(R.L(nx - 0.28, 0.8, -hd + 0.32), Vector3(0.03, 0.5, 0.5), "bois", 1.0)
		k.box(R.L(nx, 0.6, -hd + 0.32), Vector3(0.5, 0.05, 0.44), foin, 1.0)
		for o in range(2 - nb % 2):
			Sud._boule(M.room, R.mat(B._c(R, "oeuf173", Color(0.95, 0.88, 0.75), 0.6)), R.P(nx - 0.08 + o * 0.12, 0.66, -hd + 0.3), 0.035, Vector3(1, 1.25, 1))
	k.col_box(R.L(2.12, 0.5, -hd + 0.32), Vector3(1.9, 1.0, 0.5))
	R.reserve(rx, rz, 2.2, 1.2)
	# la charrette (devant, à gauche) et son foin
	var cx: Transform3D = R.L(-2.75, 0, 1.6)
	k.box(cx * B.T3(0, 0.78, 0), Vector3(1.3, 0.08, 2.3), "bois", 1.0)
	for s3 in [-1.0, 1.0]:
		k.box(cx * B.T3(s3 * 0.62, 1.0, 0), Vector3(0.05, 0.4, 2.3), "bois", 1.0)
		k.ring(cx * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(s3 * 0.72, 0.62, 0.2)), 0.54, 0.62, 0.07, "bois_sombre", 18)
		for sp in range(6):
			k.box(cx * Transform3D(Basis(Vector3.RIGHT, PI * sp / 6.0), Vector3(s3 * 0.72, 0.62, 0.2)), Vector3(0.04, 1.1, 0.04), "bois_sombre", 1.0)
		k.box(cx * Transform3D(Basis(Vector3.RIGHT, -0.32), Vector3(s3 * 0.45, 0.42, 2.0)), Vector3(0.07, 0.07, 1.6), "bois_sombre", 1.0)
	k.cyl(cx * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(0.85, 0.62, 0.2)), 0.05, 0.05, 1.7, "fer", 8)
	k.box(cx * B.T3(0, 1.0, -0.1), Vector3(1.15, 0.36, 1.8), foin, 1.0)
	L1._ovale(M, foin, cx, Vector3(0, 1.2, -0.1), Vector3(0.55, 0.25, 0.85))
	k.col_box(cx * B.T3(0, 0.7, 0.3), Vector3(1.5, 1.4, 3.0))
	R.reserve(-2.75, 1.9, 1.7, 3.3)
	# devant, à droite : les outils au mur, la charrue, les bidons de lait, la baratte
	for t in range(4):
		var tz: float = 0.4 + t * 0.55
		var tw: Transform3D = R.L(hw - 0.08, 0, tz, -90.0) * Transform3D(Basis(Vector3.RIGHT, -0.12), Vector3.ZERO)
		k.cyl(tw * B.T3(0, 0.3, 0), 0.02, 0.02, 1.45, "bois", 6)
		match t % 2:
			0:
				for d in range(4):
					k.cyl(tw * B.T3(-0.09 + d * 0.06, 1.72, 0), 0.008, 0.004, 0.32, "fer", 4)
				k.box(tw * B.T3(0, 1.72, 0), Vector3(0.22, 0.03, 0.03), "fer", 1.0)
			1:
				k.box(tw * B.T3(0, 1.76, 0), Vector3(0.5, 0.04, 0.04), "bois", 1.0)
				for d2 in range(8):
					k.cyl(tw * B.T3(-0.22 + d2 * 0.063, 1.66, 0), 0.006, 0.006, 0.1, "bois", 4)
	R.mark_wall(hw, 1.5, 1.2, 1.0)
	var pw: Transform3D = R.L(2.7, 0, 2.6, 30.0)
	k.box(pw * Transform3D(Basis(Vector3.RIGHT, 0.25), Vector3(0, 0.45, 0)), Vector3(0.12, 0.1, 1.8), "bois_sombre", 1.0)
	for s4 in [-1.0, 1.0]:
		k.box(pw * Transform3D(Basis(Vector3.RIGHT, -0.5), Vector3(s4 * 0.25, 0.55, -0.6)), Vector3(0.05, 0.05, 0.9), "bois", 1.0)
	k.box(pw * Transform3D(Basis(Vector3.RIGHT, 0.5), Vector3(0, 0.12, 0.75)), Vector3(0.28, 0.02, 0.38), "fer", 1.0)
	k.col_box(pw * B.T3(0, 0.4, 0), Vector3(0.6, 0.8, 1.8))
	R.reserve(2.7, 2.6, 1.4, 1.8)
	for b2 in range(3):
		var bxp: float = 3.7
		var bzp: float = -0.6 + b2 * 0.4
		k.cyl(R.L(bxp, 0, bzp), 0.16, 0.16, 0.48, "metal", 14)
		k.cyl(R.L(bxp, 0.48, bzp), 0.16, 0.07, 0.12, "metal", 14)
		k.cyl(R.L(bxp, 0.6, bzp), 0.08, 0.08, 0.06, "metal", 12)
	k.col_box(R.L(3.7, 0.35, -0.2), Vector3(0.4, 0.7, 1.2))
	k.cyl(R.L(3.6, 0, -1.05), 0.2, 0.16, 0.85, "bois", 14)
	k.ring(R.L(3.6, 0.2, -1.05), 0.18, 0.21, 0.04, "fer", 14)
	k.ring(R.L(3.6, 0.65, -1.05), 0.165, 0.195, 0.04, "fer", 14)
	k.cyl(R.L(3.6, 0.85, -1.05), 0.012, 0.012, 0.5, "bois", 6)
	R.reserve(3.6, -0.5, 0.8, 1.6)
	# la grosse botte ronde, couchée, et le chat qui dort dessus
	var rb: Transform3D = R.L(1.9, 0.62, 0.9, 80.0)
	k.cyl(rb * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(0.55, 0, 0)), 0.62, 0.62, 1.1, foin, 20)
	k.col_box(R.L(1.9, 0.6, 0.9, 80.0), Vector3(1.1, 1.2, 1.2))
	R.reserve(1.9, 0.9, 1.4, 1.4)
	R.chat(1.9, 0.9, 120.0, Color(0.95, 0.72, 0.4), true, 1.23)
	# la lanterne, les rais de lumière entre les planches, la poussière de foin
	B._lanterne(M, 0.2, 0.4)
	B._lanterne(M, 2.6, 2.4)
	B._lampe(M, -2.0, 2.0, -2.8, Color(1.0, 0.8, 0.55), 0.9, 5.0)
	B._lampe(M, 2.4, 2.0, -2.9, Color(1.0, 0.8, 0.55), 0.7, 4.5)
	for l in R.lights:
		(l as Node3D).global_position = R.P(0.2, R.H - 1.4, 0.6)
		(l as OmniLight3D).light_energy *= 1.6
		(l as OmniLight3D).omni_range *= 1.2
	if R.day:
		for rz2 in [-0.4, 1.4]:
			_rai(M, Vector3(-hw + 0.05, 3.9, rz2), Vector3(-hw + 2.2, 0.02, rz2 + 0.4), 0.7)
	R.poussiere(60)
	var gratter := func() -> void:
		var bl: Array = M.ctx.get("betes173", [])
		if not bl.is_empty():
			var e0: Array = bl[0]
			e0[1] = "content"
			M.timer(3.5).connect(func() -> void: e0[1] = "dort")
		M.say("Tu grattes le dos de Pistache avec un bâton. Elle ouvre un œil, pousse un grognement de bonheur, et se rendort en souriant. « Tu es adopté, dit Gaubert. C'est rare. »", 6.0)
	M.act(R.P(-1.2, 0, -1.7), "E : gratter le dos de Pistache", gratter, 0.9)
	B._marchand(M, 0.6, -0.4, 12.0, "bras_croises", "vieux", "Père Gaubert", ["Pistache dort. Pistache dort toujours. C'est son métier.", "Un bon foin, ça sent l'été même en hiver.", "Les poules ? Elles pondent quand elles veulent. Comme Germaine fait la soupe : quand elle veut."],
		{"bonjour": "Entre, entre ! Ferme bien derrière toi, sinon les poules s'en vont au marché.", "infos": ["Le foin du fenil, c'est pour tout l'hiver. On le monte à la fourche, une botte après l'autre."]})
	M.ctx["cloche170"] = false
	M.ctx["bonjour170"] = ["Bienvenue dans la grange !", "Attention où tu mets les pieds : il y a de la paille partout. Et des œufs, parfois."]
	M.ctx["entree"] = "La grange des Gaubert : le fenil plein de bottes de foin, Pistache la truie qui dort dans son enclos, les poules sur leur perchoir, la charrette, la charrue, les bidons de lait, et le chat qui dort sur la grosse botte ronde. Ça sent l'été."


# =================================================================== Astralys

## Une image qui luit (un écran, une vitre sur le dehors) : la texture, son émission (e), sa teinte.
static func _ecran(R, key: String, path: String, e: float, tint: Color = Color(1, 1, 1)) -> String:
	if R.mat(key) != null:
		return key
	var m := StandardMaterial3D.new()
	var p: String = "res://assets/textures/" + path
	if ResourceLoader.exists(p):
		var tx: Texture2D = load(p)
		m.albedo_texture = tx
		m.emission_texture = tx
	m.albedo_color = tint
	m.emission_enabled = true
	m.emission = tint
	m.emission_energy_multiplier = e
	m.roughness = 0.35
	R._put(key, m)
	return key


## La tour de contrôle du Spatioport (la cabine de verre, tout en haut) : les grandes vitres sur la
## cité et ses flèches de cristal, le pupitre en arc et ses écrans, le radar qui balaie, le tableau des
## départs, l'hologramme de l'île qui tourne au milieu, le tube de lumière ; Comète, la pilote.
static func _tour_controle(M) -> void:
	var R = M.R
	var k = R.kit
	var r: float = L1._rond(M, 22.0, 30)
	var metal: String = B._c(R, "metal173", Color(0.82, 0.84, 0.9), 0.3, 0.6)
	# les grandes vitres tout autour (sauf devant la porte), leurs montants, l'appui
	var vue: String = _ecran(R, "panorama173_j" if R.day else "panorama173_n", B173 + "panorama_astralys.png", 0.42 if R.day else 0.16, Color(0.92, 0.92, 0.95) if R.day else Color(0.4, 0.42, 0.65))
	var n: int = 30
	var segw: float = 2.0 * r * tan(PI / n)
	for i in range(n):
		var a: float = 360.0 * (i + 0.5) / n
		if absf(wrapf(a, -180.0, 180.0)) < 26.0:
			continue
		var xf: Transform3D = L1._sur_rond(M, a, r - 0.015, 1.75)
		k.quad(xf * Transform3D(Basis(Vector3.UP, PI), Vector3.ZERO), segw + 0.01, 1.7, vue, Vector2(2.0 * i / n, 0.0), Vector2(2.0 * (i + 1) / n, 1.0))
		k.box(xf * B.T3(0, -0.88, 0.06), Vector3(segw + 0.02, 0.06, 0.16), metal, 1.0)
		k.box(xf * B.T3(0, 0.88, 0.03), Vector3(segw + 0.02, 0.06, 0.08), metal, 1.0)
		if i % 3 == 0:
			k.box(L1._sur_rond(M, 360.0 * i / n, r - 0.04, 1.75), Vector3(0.06, 1.76, 0.06), metal, 1.0)
	# le pupitre en arc (au fond) : ses écrans qui luisent, ses boutons, le radar
	var hol: Array = ["holo_1", "holo_2", "radar", "holo_3", "holo_4", "holo_5"]
	var radar_xf := Transform3D()
	for j in range(hol.size()):
		var a2: float = 115.0 + j * 26.0
		var cx: Transform3D = L1._sur_rond(M, a2, r - 0.62, 0.0)
		k.box(cx * B.T3(0, 0.42, 0), Vector3(1.2, 0.84, 0.5), metal, 1.0)
		k.box(cx * Transform3D(Basis(Vector3.RIGHT, 0.22), Vector3(0, 0.86, 0.02)), Vector3(1.24, 0.04, 0.58), B._c(R, "pupitre173", Color(0.2, 0.22, 0.32), 0.3, 0.3), 1.0)
		for b in range(5):
			var bc: Color = [Color(0.3, 1.0, 0.9), Color(1.0, 0.5, 0.85), Color(1.0, 0.85, 0.3), Color(0.5, 0.7, 1.0), Color(0.3, 1.0, 0.9)][(b + j) % 5]
			k.box(cx * Transform3D(Basis(Vector3.RIGHT, 0.22), Vector3(-0.4 + b * 0.2, 0.89, 0.12)), Vector3(0.08, 0.02, 0.06), B._c(R, "bouton173_%s" % bc.to_html(false), bc, 0.3, 0.0, 2.0), 1.0)
		var sxf: Transform3D = cx * B.T3(0, 1.22, -0.14) * Transform3D(Basis(Vector3.RIGHT, -0.28), Vector3.ZERO)
		k.box(sxf * B.T3(0, 0, -0.03), Vector3(0.86, 0.52, 0.04), metal, 1.0)
		k.box(sxf * B.T3(0, -0.3, -0.03), Vector3(0.08, 0.2, 0.04), metal, 1.0)
		if str(hol[j]) == "radar":
			var rk: String = _ecran(R, "radar173", B173 + "radar_astralys.png", 1.4)
			k.quad(sxf * Transform3D(Basis(Vector3.UP, PI), Vector3(0, 0, 0.0)), 0.48, 0.48, rk)
			radar_xf = sxf
		else:
			var sk: String = _ecran(R, "holo173_%d" % j, "astralys/%s.png" % str(hol[j]), 1.3)
			k.quad(sxf * Transform3D(Basis(Vector3.UP, PI), Vector3(0, 0, 0.0)), 0.8, 0.46, sk)
		k.col_box(cx * B.T3(0, 0.45, 0), Vector3(1.2, 0.9, 0.55))
	# le balayage du radar (un trait de lumière qui tourne)
	var bal := Node3D.new()
	M.room.add_child(bal)
	bal.global_transform = radar_xf * B.T3(0, 0, 0.012)
	var trait_b := MeshInstance3D.new()
	trait_b.mesh = B._boitem(0.012, 0.23, 0.004)
	trait_b.material_override = R.mat(B._c(R, "balayage173", Color(0.75, 1.0, 0.95), 0.3, 0.0, 3.0))
	bal.add_child(trait_b)
	trait_b.position = Vector3(0, 0.115, 0)
	(M.ctx["anims170"] as Array).append([bal, "tourne", Vector3(0, 0, 1), -1.6])
	R.reserve(sin(deg_to_rad(180.0)) * (r - 0.6), cos(deg_to_rad(180.0)) * (r - 0.6), 4.0, 1.6)
	# le tableau des départs et des arrivées, pendu au plafond au-dessus du pupitre
	var vx: Transform3D = L1._sur_rond(M, 180.0, r - 1.05, 2.5)
	k.quad(vx * Transform3D(Basis(Vector3.UP, PI), Vector3(0, 0, 0.03)), 1.3, 0.65, _ecran(R, "vols173", B173 + "vols_astralys.png", 1.3))
	k.box(vx, Vector3(1.38, 0.73, 0.05), metal, 1.0)
	for s in [-1.0, 1.0]:
		k.cyl(vx * B.T3(s * 0.55, 0.36, 0), 0.008, 0.008, R.H - 2.86, metal, 4)
	# l'hologramme de l'île, au milieu, sur sa colonne : il tourne
	k.cyl(R.L(0, 0, 0), 0.38, 0.42, 0.06, metal, 20)
	k.cyl(R.L(0, 0.06, 0), 0.16, 0.22, 0.74, metal, 16)
	k.cyl(R.L(0, 0.8, 0), 0.52, 0.32, 0.06, metal, 24)
	k.cyl(R.L(0, 0.86, 0), 0.48, 0.48, 0.015, B._c(R, "socle_holo173", Color(0.4, 1.0, 0.92), 0.3, 0.0, 2.2), 24)
	var holo := Node3D.new()
	holo.name = "Hologramme_ile"
	M.room.add_child(holo)
	holo.global_position = R.P(0, 1.15, 0)
	if R.mat("holo173") == null:
		var hmm := StandardMaterial3D.new()
		hmm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		hmm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		hmm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		hmm.albedo_color = Color(0.25, 0.95, 0.85, 0.75)
		hmm.cull_mode = BaseMaterial3D.CULL_DISABLED
		R._put("holo173", hmm)
	var hm: Material = R.mat("holo173")
	var ile := MeshInstance3D.new()
	ile.mesh = B._cylm(0.34, 0.12, 0.12, 20)
	ile.material_override = hm
	holo.add_child(ile)
	for q in range(9):
		var aq: float = TAU * q / 9.0
		var dq: float = 0.08 + 0.2 * float(q % 3) / 2.0
		var fl := MeshInstance3D.new()
		fl.mesh = B._cylm(0.0, 0.02 + 0.01 * float(q % 2), 0.1 + 0.12 * float((q * 5) % 3), 6)
		fl.material_override = hm
		holo.add_child(fl)
		fl.position = Vector3(cos(aq) * dq, 0.12 + 0.03 * float((q * 5) % 3), sin(aq) * dq)
	var fc := MeshInstance3D.new()
	fc.mesh = B._cylm(0.0, 0.035, 0.42, 8)
	fc.material_override = hm
	holo.add_child(fc)
	fc.position = Vector3(0, 0.27, 0)
	var orb := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.42
	tm.outer_radius = 0.435
	orb.mesh = tm
	orb.material_override = hm
	holo.add_child(orb)
	orb.position = Vector3(0, 0.15, 0)
	orb.rotation.x = 0.35
	(M.ctx["anims170"] as Array).append([holo, "tourne", Vector3.UP, 0.45])
	k.col_cyl(R.P(0, 0, 0), 0.5, 1.0)
	R.reserve(0, 0, 1.2, 1.2)
	B._lampe(M, 0, 1.3, 0, Color(0.5, 1.0, 0.95), 0.9, 3.5)
	# le tube de lumière (c'est par là qu'on est monté) : le verre, les anneaux qui luisent
	var tu: float = deg_to_rad(282.0)
	var tpx: float = sin(tu) * (r - 0.65)
	var tpz: float = cos(tu) * (r - 0.65)
	k.cyl(R.L(tpx, 0, tpz), 0.45, 0.45, R.H, B._verre(R, "tube173", Color(0.75, 0.95, 1.0), 0.18, 0.3), 24, false)
	k.cyl(R.L(tpx, 0, tpz), 0.06, 0.06, R.H, B._c(R, "colonne_lumiere173", Color(0.7, 1.0, 0.95), 0.3, 0.0, 2.5), 10, false)
	for g in range(3):
		k.ring(R.L(tpx, 0.05 + g * 1.5, tpz), 0.43, 0.5, 0.05, B._c(R, "anneau173", Color(1.0, 0.6, 0.9), 0.3, 0.0, 1.6), 24)
	k.col_cyl(R.P(tpx, 0, tpz), 0.5, R.H)
	R.reserve(tpx, tpz, 1.3, 1.3)
	B._lampe(M, tpx, 1.6, tpz, Color(0.75, 0.95, 1.0), 0.7, 3.0)
	# deux tabourets qui flottent, devant le pupitre ; une contrôleuse lumen assise
	for e in [[196.0, "Orbite"], [229.0, ""]]:
		var ae: float = deg_to_rad(float(e[0]))
		var tx: float = sin(ae) * (r - 1.5)
		var tz: float = cos(ae) * (r - 1.5)
		k.cyl(R.L(tx, 0, tz), 0.16, 0.2, 0.04, metal, 14)
		k.cyl(R.L(tx, 0.04, tz), 0.04, 0.04, 0.34, B._c(R, "colonne_lumiere173", Color(0.7, 1.0, 0.95), 0.3, 0.0, 2.5), 8)
		k.cyl(R.L(tx, 0.38, tz), 0.2, 0.2, 0.07, B._c(R, "siege173", Color(0.95, 0.75, 0.9), 0.5), 16)
		if str(e[1]) != "":
			var p: Node = M.person("femme", tx, tz, float(e[0]), "assis", str(e[1]))
			p.lines = ["Soucoupe de Glorb en approche… avec trois jours d'avance. Encore.", "Piste deux dégagée ! … Elle l'était déjà. Mais j'aime le dire."]
	# Comète, la pilote, devant le radar
	var ac: float = deg_to_rad(152.0)
	B._marchand(M, sin(ac) * (r - 1.45), cos(ac) * (r - 1.45), 152.0, "holo", "femme", "Comète", ["Piste un, vent nul, ciel mauve : parfait pour décoller.", "D'ici, on voit toutes les soucoupes. Et toutes les étoiles. Et la tache de café sur la vitre."],
		{"bonjour": "Bienvenue dans la tour de contrôle ! Ne touche pas au bouton rose. Personne ne sait à quoi il sert.", "infos": ["Le radar voit toutes les soucoupes à cent lieues. Et les mouettes. Elles détestent ça."]})
	var radar := func() -> void:
		M.say(str(B._pick(M, ["Sur le radar : la soucoupe de Glorb, en approche… avec trois jours d'avance. Le vol pour la Lune est annulé : « elle dort », dit le tableau.", "Le trait de lumière tourne et tourne. Un petit point rose clignote : COMÈTE. « C'est moi, dit Comète. Enfin, ma soucoupe. Je l'ai garée là. »", "Un point qui va très vite, puis qui s'arrête net… « Une mouette, soupire Orbite. Elles font ça exprès. »"])), 7.0)
	var ra: float = deg_to_rad(167.0)
	M.act(R.P(sin(ra) * (r - 1.5), 0, cos(ra) * (r - 1.5)), "E : regarder le radar", radar, 0.9)
	M.ctx["cloche170"] = false
	M.ctx["bonjour170"] = ["Bienvenue dans la tour de contrôle !", "Tour de contrôle, j'écoute ! … Ah, c'est toi. Entre !"]
	M.ctx["entree"] = "La tour de contrôle du Spatioport, tout en haut, dans la cabine de verre : la cité et ses flèches de cristal tout autour, le pupitre et ses écrans qui luisent, le radar qui balaie, le tableau des départs (le vol pour la Lune est annulé : elle dort), l'hologramme de l'île qui tourne au milieu."


# =================================================================== Sombreval

## Le mausolée des Vauclair, au fond du Vieux Cimetière : le gisant de pierre sur son tombeau, les urnes
## dans leurs niches, les noms gravés, le vitrail, les bougies allumées (par qui ?), la montre arrêtée
## sur minuit, une rose toute fraîche ; les toiles d'araignée, le lierre, un rat. On y entre seul.
static func _mausolee(M) -> void:
	var R = M.R
	var k = R.kit
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var pierre: String = B._tex(R, "gisant173", "chateau/pierre_chateau.png", Color(0.62, 0.62, 0.6), 0.85)
	var grave := Color(0.82, 0.8, 0.72)
	# le tombeau et son gisant (la tête sur un coussin, les mains jointes, un petit chien aux pieds)
	var sx: Transform3D = R.L(0, 0, -0.55)
	k.box(sx * B.T3(0, 0.08, 0), Vector3(2.35, 0.16, 1.18), "bas", 1.0)
	k.box(sx * B.T3(0, 0.5, 0), Vector3(2.1, 0.7, 0.95), pierre, 1.0)
	for i in range(4):
		var ax: float = -0.75 + i * 0.5
		k.box(sx * B.T3(ax, 0.48, 0.476), Vector3(0.36, 0.48, 0.01), B._c(R, "ombre173", Color(0.42, 0.42, 0.4), 0.9), 1.0)
		k.cyl(sx * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(ax, 0.72, 0.48)), 0.18, 0.18, 0.012, "ombre173", 12)
	k.box(sx * B.T3(0, 0.89, 0), Vector3(2.26, 0.09, 1.1), pierre, 1.0)
	L1._ovale(M, pierre, sx, Vector3(-0.74, 0.98, 0), Vector3(0.15, 0.06, 0.25))
	L1._ovale(M, pierre, sx, Vector3(-0.66, 1.07, 0), Vector3(0.1, 0.095, 0.09))
	L1._ovale(M, pierre, sx, Vector3(-0.42, 1.02, 0), Vector3(0.13, 0.08, 0.2))
	L1._ovale(M, pierre, sx, Vector3(0.0, 1.0, 0), Vector3(0.48, 0.085, 0.21))
	L1._ovale(M, pierre, sx, Vector3(0.45, 0.98, 0), Vector3(0.3, 0.065, 0.17))
	k.box(sx * Transform3D(Basis(Vector3.BACK, -0.95), Vector3(-0.3, 1.13, 0)), Vector3(0.05, 0.15, 0.08), pierre, 1.0)
	for s in [-1.0, 1.0]:
		L1._ovale(M, pierre, sx, Vector3(0.76, 1.02, s * 0.06), Vector3(0.04, 0.06, 0.04))
	L1._ovale(M, pierre, sx, Vector3(0.9, 0.99, 0), Vector3(0.1, 0.06, 0.07))
	L1._ovale(M, pierre, sx, Vector3(0.98, 1.04, 0), Vector3(0.045, 0.045, 0.04))
	k.col_box(sx * B.T3(0, 0.5, 0), Vector3(2.35, 1.0, 1.18))
	R.reserve(0, -0.55, 2.6, 1.5)
	# la rose (toute fraîche) près des mains ; la montre de gousset arrêtée sur minuit
	k.cyl(sx * Transform3D(Basis(Vector3.BACK, PI * 0.5) * Basis(Vector3.UP, 0.3), Vector3(-0.05, 1.11, 0.12)), 0.005, 0.005, 0.3, "feuillage", 4)
	L1._ovale(M, B._c(R, "rose173", Color(0.72, 0.05, 0.08), 0.6), sx, Vector3(-0.2, 1.12, 0.17), Vector3(0.035, 0.03, 0.035))
	var mo: Transform3D = sx * B.T3(0.3, 0.935, 0.38)
	k.cyl(mo, 0.045, 0.045, 0.012, "or", 16)
	k.cyl(mo * B.T3(0, 0.012, 0), 0.038, 0.038, 0.002, "ceramique", 16)
	k.box(mo * B.T3(0, 0.016, -0.012), Vector3(0.003, 0.002, 0.026), "noir", 1.0)
	k.box(mo * B.T3(0, 0.017, -0.017), Vector3(0.002, 0.002, 0.034), "noir", 1.0)
	k.ring(mo * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0.006, -0.055)), 0.008, 0.013, 0.004, "or", 8)
	# les deux candélabres de fer, aux bouts du tombeau, et leurs bougies (allumées… par qui ?)
	for s2 in [-1.0, 1.0]:
		var cx: float = s2 * 1.62
		var cz: float = -0.55
		for t in range(3):
			var at: float = TAU * t / 3.0
			k.box(R.L(cx + cos(at) * 0.12, 0.08, cz + sin(at) * 0.12, -rad_to_deg(at)) * Transform3D(Basis(Vector3.BACK, 0.5), Vector3.ZERO), Vector3(0.24, 0.025, 0.025), "fer", 1.0)
		k.cyl(R.L(cx, 0.05, cz), 0.018, 0.018, 1.15, "fer", 6)
		k.cyl(R.L(cx, 1.2, cz), 0.16, 0.05, 0.05, "fer", 12)
		for c in range(3):
			var ac: float = TAU * c / 3.0 + 0.5
			R.bougie(cx + cos(ac) * 0.09, 1.25, cz + sin(ac) * 0.09, c == 0)
		k.col_cyl(R.P(cx, 0, cz), 0.18, 1.3)
	# le mur du fond : le vitrail (un jour gris-vert), l'inscription, deux niches et leurs urnes
	var vit: String = _ecran(R, "vitrail173", "beau161/vitrail.png", 0.55 if R.day else 0.12, Color(0.75, 0.85, 0.78))
	k.quad(R.L(0, 2.95, -hd + 0.035) * Transform3D(Basis(Vector3.UP, PI), Vector3.ZERO), 0.7, 1.15, vit)
	for s3 in [-1.0, 1.0]:
		k.box(R.L(s3 * 0.41, 2.95, -hd + 0.06), Vector3(0.12, 1.3, 0.12), "bas", 1.0)
	k.box(R.L(0, 3.58, -hd + 0.06), Vector3(0.94, 0.12, 0.12), "bas", 1.0)
	k.box(R.L(0, 2.32, -hd + 0.09), Vector3(0.94, 0.08, 0.18), "bas", 1.0)
	R.mark_wall(0, 2.95, -hd, 0.5)
	if R.day:
		_rai(M, Vector3(0, 2.9, -hd + 0.1), Vector3(0.3, 0.02, 0.6), 0.6, true)
	k.box(R.L(0, 1.92, -hd + 0.04), Vector3(1.9, 0.4, 0.05), pierre, 1.0)
	B._ecrit(M, 0, 1.92, -hd + 0.07, 0.0, "FAMILLE DE VAUCLAIR\nhorlogers de Sombreval", 40, grave, 0.0034)
	for s4 in [-1.0, 1.0]:
		var nx: float = s4 * 1.62
		var ny: float = 1.75
		for e in [[0.0, 0.42], [0.0, -0.42]]:
			k.box(R.L(nx, ny + float(e[1]), -hd + 0.12), Vector3(0.7, 0.08, 0.24), "bas", 1.0)
		for s5 in [-1.0, 1.0]:
			k.box(R.L(nx + s5 * 0.31, ny, -hd + 0.12), Vector3(0.08, 0.84, 0.24), "bas", 1.0)
		k.quad(R.L(nx, ny, -hd + 0.035) * Transform3D(Basis(Vector3.UP, PI), Vector3.ZERO), 0.56, 0.76, "noir")
		k.cyl(R.L(nx, ny - 0.38, -hd + 0.12), 0.08, 0.1, 0.06, "ceramique", 12)
		k.cyl(R.L(nx, ny - 0.32, -hd + 0.12), 0.11, 0.12, 0.22, B._c(R, "urne173", Color(0.22, 0.24, 0.3), 0.4, 0.3), 14)
		k.cyl(R.L(nx, ny - 0.1, -hd + 0.12), 0.12, 0.05, 0.1, "urne173", 14)
		k.cyl(R.L(nx, ny, -hd + 0.12), 0.07, 0.02, 0.06, "or", 10)
		R.mark_wall(nx, ny, -hd, 0.4)
	# les noms gravés sur les murs des côtés
	var noms: Array = [[-hw, -1.3, 90.0, "ANSELME DE VAUCLAIR\n1802 – 1871"], [-hw, 0.1, 90.0, "HORTENSE DE VAUCLAIR\n1810 – 1888"],
		[hw, -1.3, -90.0, "MATHILDE DE VAUCLAIR\n1840 – 1919"], [hw, 0.1, -90.0, "AUGUSTE DE VAUCLAIR\n1866 – 1931"]]
	for nm in noms:
		var wx: float = float(nm[0])
		var wz: float = float(nm[1])
		var yaw: float = float(nm[2])
		var off: float = 0.03 if wx < 0.0 else -0.03
		k.box(R.L(wx + off, 1.6, wz, yaw), Vector3(1.15, 0.42, 0.04), pierre, 1.0)
		B._ecrit(M, wx + off * 2.0, 1.6, wz, yaw, str(nm[3]), 34, grave, 0.0024)
		R.mark_wall(wx, 1.6, wz, 0.5)
	B._ecrit(M, hw - 0.04, 2.4, 1.2, -90.0, "« Le temps passe.\nNous, nous restons. »", 32, grave, 0.0032)
	# des fleurs fanées dans un vase, du lierre qui entre par une fissure, la poussière, un rat
	k.cyl(R.L(1.0, 0, 0.55), 0.09, 0.07, 0.3, "metal", 12)
	var fane: String = B._c(R, "fane173", Color(0.4, 0.3, 0.2), 0.95)
	for f in range(6):
		var af: float = TAU * f / 6.0
		k.cyl(R.L(1.0 + cos(af) * 0.02, 0.28, 0.55 + sin(af) * 0.02) * Transform3D(Basis(Vector3(cos(af + PI * 0.5), 0, sin(af + PI * 0.5)), 0.35 + 0.1 * float(f % 2)), Vector3.ZERO), 0.006, 0.004, 0.35, fane, 4)
		Sud._boule(M.room, R.mat(fane), R.P(1.0 + cos(af) * 0.14, 0.58 - 0.05 * float(f % 3), 0.55 + sin(af) * 0.14), 0.03)
	var lierre: String = Sud._img(R, "lierre173", "flora/leaves.png", 1, Color(0.32, 0.42, 0.26))
	for v in range(6):
		k.quad(R.L(-hw + 0.04 + 0.01 * float(v % 2), 2.5 + v * 0.26, -hd + 0.45 + v * 0.18, 90.0) * Transform3D(Basis(Vector3.UP, PI) * Basis(Vector3.BACK, 0.5 * float(v % 3) - 0.4), Vector3.ZERO), 0.6, 0.55, lierre)
	for c2 in range(4):
		k.box(R.L(-hw + 0.012, 3.6 - c2 * 0.3, -hd + 0.3 + c2 * 0.12, 90.0) * Transform3D(Basis(Vector3.BACK, 0.4 * (1.0 if c2 % 2 == 0 else -1.0)), Vector3.ZERO), Vector3(0.02, 0.34, 0.01), "noir", 1.0)
	R.toiles(4)
	R.poussiere(25)
	_bete(M, "rat", {"taille": 1.0, "seed": 2}, Vector3(1.85, 0.0, 1.35), 220.0, "renifle")
	for l in R.lights:
		(l as OmniLight3D).light_color = Color(0.62, 0.7, 0.72)
		(l as OmniLight3D).light_energy *= 0.45
	var lire := func() -> void:
		M.say("« Ici reposent les Vauclair, horlogers de Sombreval. Ils ont réglé toutes les horloges de la ville… sauf la dernière. » Sur le tombeau, une rose rouge. Fraîche. Toute fraîche.", 8.0)
	M.act(R.P(-0.7, 0, 0.55), "E : lire l'épitaphe", lire, 0.8)
	var montre := func() -> void:
		M.say("Une montre de gousset en or, posée sur le tombeau. Elle est arrêtée sur minuit, comme l'horloge du beffroi. Tu la portes à ton oreille : tic… Non. Tu as rêvé.", 7.0)
	M.act(R.P(0.5, 0, 0.45), "E : regarder la montre", montre, 0.7)
	M.ctx["cloche170"] = false
	M.ctx["bonjour170"] = []
	M.ctx["entree"] = "Le mausolée des Vauclair : le gisant de pierre sur son tombeau, les urnes dans leurs niches, les noms gravés… Les bougies sont allumées. Qui les a allumées ? Il n'y a personne. Juste un rat, qui te regarde."
