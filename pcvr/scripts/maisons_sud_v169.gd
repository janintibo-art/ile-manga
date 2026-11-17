extends RefCounted
## V169 : on entre dans tous les bâtiments d'Al Dente, de l'Île Crayonnée et de Sombreval.
##  - Al Dente : les six maisons du Borgo (le style « pasta » : les tomettes, la chaux, le four de
##    terre) et la Barque-Maison du Capitaine ; chez chacun, ce qui dit son métier (touches()) : le
##    coin des pâtes fraîches de Mamma Lasagna, le petit autel du Père Farfalle, les pupitres de
##    Sœur Penne et le chevalet de Tagliatelle, les cagettes de tomates de Ravioli, le tableau noir
##    de la Professeure Fusilli, le gong d'entraînement de Macaroni, la meule de parmesan du Capitaine ;
##  - l'Île Crayonnée : les quatre arbres-maisons, des pièces rondes (shell()) sous un plafond en cône,
##    dessinées comme l'île (en noir et blanc tant que la clairière n'a pas retrouvé ses couleurs :
##    apres() convertit la pièce, crayon_dedans dit au coloriage où est la maison) ; chez les
##    Pinceau, les Gomme, les Buvard (« cr_maison ») et la Maison du Conseil (« cr_conseil » : la
##    grande table ronde, la carte de l'île et ses neuf godets, l'affiche) ;
##  - Sombreval : chaque immeuble fermé, chaque maison des Faubourgs (sombreval_v121 pose leurs
##    portes) : des appartements abandonnés depuis trois hivers, la poussière, le papier peint qui
##    se décolle, les planches clouées sur les fenêtres (_usure) ; leurs histoires (le souper
##    interrompu, le refuge de Solène, la chambre d'enfant, le chat qui est resté, la vieille
##    pharmacie, la maison abandonnée) ; et la salle d'attente de la gare, le mécanisme du beffroi.

const S = preload("res://scripts/maisons_scenes_v81.gd")
const AzurKit = preload("res://scripts/azur_kit_v56.gd")
const CrayonMat = preload("res://scripts/crayon_mat_v99.gd")
const Figurant = preload("res://scripts/pnj/figurant_v81.gd")

## Les histoires tirées au sort dans les immeubles de Sombreval : [id, poids, conditions]
const SCENARIOS := [
	["sv_souper", 14, {"style": ["sombreval"]}], ["sv_refuge", 10, {"style": ["sombreval"]}],
	["sv_enfant", 9, {"style": ["sombreval"]}], ["sv_chat", 9, {"style": ["sombreval"]}],
	["sv_pharmacie", 6, {"style": ["sombreval"]}],
]
## Les histoires générales qui vont à Sombreval aussi (une ville morte : personne n'y vit plus)
const GENERALES_SV := [["abandon", 12, {}]]
## Les histoires d'une porte à elle
const FIXES := ["sv_gare", "sv_beffroi", "cr_maison", "cr_conseil"]
## Le rayon de la pièce ronde d'un arbre-maison (la Maison du Conseil est plus grande)
const RC: float = 3.0
const RC_CONSEIL: float = 3.5
const HC: float = 4.6
## Les poissons qu'un chat accepte
const POISSONS := ["sardine", "maquereau", "dorade", "bar", "poisson_perroquet", "merou"]
## Le coloriage regarde-t-il la carte des couleurs à la porte d'un arbre-maison (crayon_dedans) ?
static var dedans: bool = false


# =================================================================== ce que maisons_v81 demande

static func gere(style: String) -> bool:
	return style == "sombreval" or style == "crayon"


static func is_lieu(style: String) -> bool:
	return style == "crayon"


static func taille(cur: Dictionary) -> Vector2:
	var r: float = RC_CONSEIL if str(cur.get("maison_id", "")) == "grand" else RC
	return Vector2(r * 2.0, r * 2.0)


static func has(sc: String) -> bool:
	if sc in FIXES:
		return true
	for e in SCENARIOS:
		if str(e[0]) == sc:
			return true
	return false


static func pick(M) -> String:
	return pick_id(str(M.ctx["style"]), str(M.ctx["id"]))


## L'histoire d'une maison (toujours la même pour une maison donnée : id, comme maisons_v81).
static func pick_id(style: String, id: String) -> String:
	if style == "crayon":
		return "cr_maison"
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(id + "scenario")
	var total: float = 0.0
	for e in SCENARIOS + GENERALES_SV:
		total += float(e[1])
	var x: float = rng.randf() * total
	for e2 in SCENARIOS + GENERALES_SV:
		x -= float(e2[1])
		if x <= 0.0:
			return str(e2[0])
	return "abandon"


static func build(M, sc: String) -> void:
	match sc:
		"sv_souper":
			_souper(M)
		"sv_refuge":
			_refuge(M)
		"sv_enfant":
			_enfant(M)
		"sv_chat":
			_chat(M)
		"sv_pharmacie":
			_pharmacie(M)
		"sv_gare":
			_gare(M)
		"sv_beffroi":
			_beffroi(M)
		"cr_maison":
			_cr_maison(M)
		"cr_conseil":
			_cr_conseil(M)


## Après la construction (la pièce est posée) : à l'Île Crayonnée, la pièce passe au coloriage (sauf
## les habitants et ce qui est marqué « crayon_non ») ; le coloriage lit la carte des couleurs à la porte.
static func apres(M) -> void:
	if str(M.ctx.get("style", "")) != "crayon":
		return
	for f in M.people:
		if is_instance_valid(f) and f.get("npc") != null and is_instance_valid(f.npc):
			for g in (f.npc as Node).find_children("*", "GeometryInstance3D", true, false):
				g.set_meta("crayon_non", true)
	CrayonMat.convert_tree(M.room)
	var d: Vector3 = M.cur.get("door", Vector3.ZERO)
	RenderingServer.global_shader_parameter_set("crayon_dedans", Vector4(d.x, d.z, -150.0, 1.0))
	M.ctx["crayon_dedans"] = true
	dedans = true


static func sortir(M) -> void:
	if dedans or (M.ctx is Dictionary and bool((M.ctx as Dictionary).get("crayon_dedans", false))):
		RenderingServer.global_shader_parameter_set("crayon_dedans", Vector4(0.0, 0.0, -150.0, 0.0))
		dedans = false


# =================================================================== aides

static func _r(M) -> RandomNumberGenerator:
	return M.ctx["rng"]


static func _pick(M, a: Array) -> Variant:
	return a[_r(M).randi() % a.size()]


## Un matériau d'image (une affiche, un calendrier, un dessin…), mis en cache dans la pièce ; alpha :
## 0 opaque, 1 découpé (le papier peint décollé), 2 transparent (les auréoles d'humidité).
static func _img(R, key: String, path: String, alpha: int = 0, tint: Color = Color(1, 1, 1)) -> String:
	if R.mat(key) != null:
		return key
	var m := StandardMaterial3D.new()
	var p: String = "res://assets/textures/" + path
	if ResourceLoader.exists(p):
		m.albedo_texture = load(p)
	m.albedo_color = tint
	m.roughness = 0.9
	if alpha == 1:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		m.alpha_scissor_threshold = 0.5
	elif alpha == 2:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.roughness = 1.0
	R._put(key, m)
	return key


static func _couleur(R, key: String, c: Color, rough: float = 0.8, metal: float = 0.0) -> String:
	if R.mat(key) == null:
		R._put(key, R._col(c, rough, metal))
	return key


## Une image accrochée au mur, en entier (x, y, z : son centre ; yaw comme R.tableau : 0 au fond,
## 90 à gauche, -90 à droite) ; cadre : la clé du cadre (ou "" pour une feuille punaisée).
static func _cadre(R, key: String, x: float, y: float, z: float, yaw: float, w: float, h: float, cadre: String = "bois_sombre") -> void:
	R.mark_wall(x, y, z, w * 0.5 + 0.1)
	var xf: Transform3D = R.L(x, y, z, yaw)
	R.kit.quad(xf * Transform3D(Basis(Vector3.UP, PI), Vector3(0, 0, 0.022)), w, h, key)
	if cadre == "":
		_couleur(R, "rouge_v169", Color(0.6, 0.1, 0.08), 0.5)
		R.kit.box(xf * Transform3D(Basis(), Vector3(0, h * 0.5 - 0.03, 0.03)), Vector3(0.02, 0.02, 0.012), "rouge_v169", 1.0)
		return
	for s in [-1.0, 1.0]:
		R.kit.box(xf * Transform3D(Basis(), Vector3(s * (w * 0.5 + 0.025), 0, 0.022)), Vector3(0.05, h + 0.1, 0.04), cadre, 1.0)
		R.kit.box(xf * Transform3D(Basis(), Vector3(0, s * (h * 0.5 + 0.025), 0.022)), Vector3(w + 0.1, 0.05, 0.04), cadre, 1.0)
	R.kit.box(xf * Transform3D(Basis(), Vector3(0, 0, 0.006)), Vector3(w + 0.04, h + 0.04, 0.012), cadre, 1.0, 16)


## Une boule (une sphère à part : un ballon, une tomate, une tête d'ourson…).
static func _boule(parent: Node3D, m: Material, pos: Vector3, r: float, scl: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	sm.radial_segments = 14
	sm.rings = 7
	mi.mesh = sm
	mi.material_override = m
	parent.add_child(mi)
	mi.global_position = pos
	mi.scale = scl
	return mi


## Une chaise renversée (sur le dos).
static func _chaise_renversee(R, x: float, z: float, yaw: float) -> void:
	var xf: Transform3D = R.L(x, 0, z, yaw) * Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), Vector3(0, 0.24, 0.3))
	R.kit.box(xf * Transform3D(Basis(), Vector3(0, 0.45, 0)), Vector3(0.44, 0.05, 0.42), "bois", 1.0)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			R.kit.box(xf * Transform3D(Basis(), Vector3(sx * 0.18, 0.22, sz * 0.17)), Vector3(0.04, 0.45, 0.04), "bois_sombre", 1.0)
	R.kit.box(xf * Transform3D(Basis(), Vector3(0, 0.75, -0.19)), Vector3(0.44, 0.55, 0.04), "bois", 1.0)
	R.reserve(x, z, 1.0, 1.0)


## Les places des fenêtres (comme R._windows) : [x, y, z, yaw].
static func _fenetres(R) -> Array:
	var out: Array = []
	if str(R.pal.get("fenetre", "")) == "aucune":
		return out
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var wy: float = 1.55 if R.H > 2.7 else 1.4
	var nz: int = 1 if R.D < 7.0 else 2
	for k in range(nz):
		var z: float = -hd + R.D * (k + 0.5) / nz
		out.append([-hw + 0.02, wy, z, 90.0])
		out.append([hw - 0.02, wy, z, -90.0])
	if R.W > 7.5:
		out.append([-R.W * 0.25, wy, -hd + 0.02, 0.0])
	return out


# =================================================================== Sombreval : l'usure

## Trois hivers d'abandon : la lumière grise et faible (la lampe est morte), les planches clouées en
## travers des fenêtres, le papier peint qui se décolle par plaques, les taches d'humidité au
## plafond, le plâtre tombé, les feuilles mortes entrées par une vitre cassée, la poussière.
static func _usure(M, planches: float = 0.5, papier: bool = true) -> void:
	var R = M.R
	var r := _r(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	_couleur(R, "rouge_v169", Color(0.6, 0.1, 0.08), 0.5)
	# la lampe ne marche plus : la pièce n'a que le jour gris (ou la lune) des fenêtres ; les draps sont gris de poussière
	R._put("lumiere", R._col(Color(0.32, 0.31, 0.29), 0.9))
	var dr: StandardMaterial3D = (R.mat("drap") as StandardMaterial3D).duplicate()
	dr.albedo_color = dr.albedo_color * Color(0.74, 0.72, 0.67)
	R._put("drap", dr)
	for l in R.lights:
		(l as OmniLight3D).light_energy *= 0.42
		(l as OmniLight3D).light_color = Color(0.74, 0.8, 0.86)
	var fen: Array = _fenetres(R)
	if not fen.is_empty():
		var f0: Array = fen[0]
		var lf := OmniLight3D.new()
		lf.light_color = Color(0.7, 0.8, 0.86) if R.day else Color(0.45, 0.52, 0.75)
		lf.light_energy = 0.55 if R.day else 0.18
		lf.omni_range = maxf(R.W, R.D) * 0.9
		lf.shadow_enabled = false
		R.root.add_child(lf)
		lf.global_position = R.P(float(f0[0]) * 0.8, float(f0[1]), float(f0[2]))
		R.lights.append(lf)
	# les planches en travers des fenêtres
	for f in fen:
		if r.randf() > planches:
			continue
		var xf: Transform3D = R.L(float(f[0]), float(f[1]), float(f[2]), float(f[3]))
		for k in range(r.randi_range(2, 3)):
			var a: float = r.randf_range(-0.35, 0.35)
			R.kit.box(xf * Transform3D(Basis(Vector3.BACK, a), Vector3(r.randf_range(-0.1, 0.1), -0.45 + k * 0.42 + r.randf_range(-0.08, 0.08), 0.08)), Vector3(1.3, r.randf_range(0.11, 0.16), 0.03), "bois_sombre" if k % 2 == 0 else "bois", 1.0)
			for sx in [-0.55, 0.55]:
				R.kit.box(xf * Transform3D(Basis(Vector3.BACK, a), Vector3(sx, -0.45 + k * 0.42, 0.1)), Vector3(0.02, 0.02, 0.02), "fer", 1.0)
	# le papier peint qui se décolle (des plaques sur les murs), les taches d'humidité
	var dec: String = _img(R, "sv_decolle", "beau169/sv_decolle.png", 1)
	var tac: String = _img(R, "sv_taches", "beau169/sv_taches.png", 2)
	var murs: Array = [[0.0, -hd + 0.012, 0.0, R.W], [-hw + 0.012, 0.0, 90.0, R.D], [hw - 0.012, 0.0, -90.0, R.D]]
	for k2 in range(r.randi_range(6, 10) if papier else 0):
		var mu: Array = murs[r.randi() % murs.size()]
		var along: float = r.randf_range(-0.42, 0.42) * float(mu[3])
		var y: float = r.randf_range(1.2, R.H - 0.7)
		var x: float = float(mu[0]) if absf(float(mu[2])) > 1.0 else along
		var z: float = float(mu[1]) if absf(float(mu[2])) < 1.0 else along
		var w: float = r.randf_range(0.6, 1.5)
		if not R.wall_free(x, y, z, w * 0.5):
			continue
		var xf2: Transform3D = R.L(x, y, z, float(mu[2]))
		R.kit.quad(xf2 * Transform3D(Basis(Vector3.UP, PI) * Basis(Vector3.BACK, r.randf_range(-0.3, 0.3)), Vector3(0, 0, 0.004 + 0.001 * k2)), w, w * r.randf_range(0.7, 1.2), dec)
	for k3 in range(r.randi_range(2, 4)):
		var mu2: Array = murs[r.randi() % murs.size()]
		var along2: float = r.randf_range(-0.4, 0.4) * float(mu2[3])
		var x2: float = float(mu2[0]) if absf(float(mu2[2])) > 1.0 else along2
		var z2: float = float(mu2[1]) if absf(float(mu2[2])) < 1.0 else along2
		var w2: float = r.randf_range(0.8, 1.6)
		var xf3: Transform3D = R.L(x2, R.H - w2 * 0.35, z2, float(mu2[2]))
		R.kit.quad(xf3 * Transform3D(Basis(Vector3.UP, PI), Vector3(0, 0, 0.003 + 0.001 * k3)), w2, w2 * 0.7, tac)
	# au sol, des traces sombres (l'eau qui a coulé, la poussière accumulée)
	for k7 in range(r.randi_range(2, 3)):
		R.kit.quad(R.L(r.randf_range(-hw + 0.8, hw - 0.8), 0.006 + 0.001 * k7, r.randf_range(-hd + 0.8, hd - 1.5)) * Transform3D(Basis(Vector3.UP, r.randf_range(0, TAU)) * Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), r.randf_range(1.0, 2.0), r.randf_range(0.8, 1.6), tac)
	# au plafond, une grande auréole
	R.kit.quad(R.L(r.randf_range(-hw * 0.5, hw * 0.5), R.H - 0.004, r.randf_range(-hd * 0.5, 0.0)) * Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), Vector3.ZERO), r.randf_range(1.2, 2.0), r.randf_range(1.0, 1.6), tac)
	# le plâtre tombé, les papiers, les feuilles mortes
	for k4 in range(r.randi_range(5, 9)):
		var px: float = r.randf_range(-hw + 0.4, hw - 0.4)
		var pz: float = r.randf_range(-hd + 0.4, hd - 1.6)
		R.kit.box(R.L(px, 0.02, pz, r.randf_range(0, 180)), Vector3(r.randf_range(0.06, 0.25), r.randf_range(0.02, 0.05), r.randf_range(0.05, 0.2)), "pierre_lisse", 1.0)
	for k5 in range(r.randi_range(3, 6)):
		R.kit.box(R.L(r.randf_range(-hw + 0.6, hw - 0.6), 0.005, r.randf_range(-hd + 0.6, hd - 1.4), r.randf_range(0, 180)), Vector3(0.21, 0.004, 0.3), "papier", 1.0, 4)
	_couleur(R, "feuille_morte", Color(0.42, 0.3, 0.16), 0.95)
	if not fen.is_empty():
		var f1: Array = fen[r.randi() % fen.size()]
		var inward: Vector3 = Basis(Vector3.UP, deg_to_rad(float(f1[3]))) * Vector3(0, 0, 1)
		for k6 in range(12):
			var q: Vector3 = Vector3(float(f1[0]), 0.0, float(f1[2])) + inward * r.randf_range(0.2, 1.4) + inward.cross(Vector3.UP) * r.randf_range(-0.8, 0.8)
			R.kit.box(R.L(q.x, 0.008, q.z, r.randf_range(0, 180)), Vector3(r.randf_range(0.05, 0.09), 0.006, r.randf_range(0.04, 0.07)), "feuille_morte", 1.0, 4)
	R.toiles(4)
	R.poussiere(45)


# =================================================================== Sombreval : les histoires

## Le souper interrompu : la table encore mise, les chaises repoussées, le gâteau d'anniversaire
## sous sa cloche ; le calendrier, l'horloge arrêtée à minuit, une lettre jamais postée.
static func _souper(M) -> void:
	var R = M.R
	var r := _r(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	_usure(M, 0.4)
	R.foyer(R.W * 0.18, -hd + 0.38, 0, false)
	R.tapis(-0.2, 0.0, 0, minf(2.6, R.W - 2.6), minf(1.9, R.D - 2.6))
	var tx: float = -0.2
	var tz: float = 0.0
	R.table(tx, tz, 0, 1.5, 0.85, 0.76, "blanc")
	R.chaise(tx - 0.4, tz + 0.95, 195.0)
	R.chaise(tx + 0.4, tz - 0.92, -12.0)
	R.chaise(tx + 1.2, tz + 0.1, -64.0)
	_chaise_renversee(R, tx - 1.35, tz + 0.2, 70.0)
	R.couverts(tx, tz, 0.79, [Vector2(-0.4, 0.26), Vector2(0.4, -0.26), Vector2(0.58, 0.05), Vector2(-0.56, -0.05)], "chocolat")
	# le chandelier (les bougies ont brûlé jusqu'au bout)
	R.kit.cyl(R.L(tx + 0.2, 0.79, tz + 0.05), 0.07, 0.05, 0.03, "or", 12)
	R.kit.cyl(R.L(tx + 0.2, 0.82, tz + 0.05), 0.015, 0.015, 0.22, "or", 8)
	for k in range(3):
		var bx: float = tx + 0.2 + (k - 1) * 0.11
		R.kit.cyl(R.L(bx, 1.02, tz + 0.05), 0.03, 0.03, 0.02, "or", 8)
		R.kit.cyl(R.L(bx, 1.04, tz + 0.05), 0.02, 0.022, 0.02 + 0.02 * k, "ceramique", 8)
	R.kit.box(R.L(tx + 0.2, 1.0, tz + 0.05), Vector3(0.24, 0.015, 0.015), "or", 1.0)
	# le gâteau d'anniversaire, sous sa cloche de verre (huit petites bougies jamais allumées)
	var gx: float = tx - 0.42
	var gz: float = tz - 0.12
	R.kit.cyl(R.L(gx, 0.79, gz), 0.2, 0.2, 0.015, "argent", 18)
	R.kit.cyl(R.L(gx, 0.805, gz), 0.15, 0.15, 0.1, "gateau", 18)
	R.kit.cyl(R.L(gx, 0.905, gz), 0.15, 0.13, 0.02, "poussiere", 18)
	for k2 in range(8):
		var a: float = TAU * k2 / 8.0
		R.kit.cyl(R.L(gx + cos(a) * 0.09, 0.925, gz + sin(a) * 0.09), 0.006, 0.006, 0.05, "ceramique", 5)
	R.kit.cyl(R.L(gx, 0.805, gz), 0.18, 0.17, 0.3, "verre", 18, false)
	R.kit.cyl(R.L(gx, 1.105, gz), 0.17, 0.02, 0.07, "verre", 18)
	R.kit.cyl(R.L(gx, 1.17, gz), 0.02, 0.02, 0.04, "verre", 8)
	# le buffet, et la lettre jamais postée
	var bfx: float = -hw + 0.32
	var bfz: float = -hd * 0.35
	R.kit.box(R.L(bfx, 0.45, bfz, 90), Vector3(1.5, 0.9, 0.5), "bois", 1.0)
	R.kit.box(R.L(bfx, 0.92, bfz, 90), Vector3(1.6, 0.04, 0.56), "bois_sombre", 1.0)
	for sx in [-0.37, 0.37]:
		R.kit.box(R.L(bfx + 0.26, 0.45, bfz + sx, 90), Vector3(0.68, 0.72, 0.01), "bois_clair", 1.0, 16)
	R.kit.col_box(R.L(bfx, 0.45, bfz, 90), Vector3(1.5, 0.9, 0.5))
	R.reserve(bfx, bfz, 0.8, 1.8)
	S._mot(M, bfx + 0.05, bfz + 0.3, 0.94, "Une lettre, jamais postée : « Chère maman, ici tout va bien… enfin, presque. Hier soir, toutes les horloges de la ville se sont arrêtées en même temps, à minuit. Papa dit que c'est le froid. Léa aura huit ans samedi : viens pour le gâteau ! »", "E : lire la lettre")
	# le calendrier (un jour entouré de rouge), l'horloge arrêtée
	var cal: String = _img(R, "sv_cal", "beau169/sv_calendrier.png")
	var cz: float = hd * 0.2
	_cadre(R, cal, -hw + 0.02, 1.62, cz, 90.0, 0.4, 0.56, "")
	M.act(R.P(-hw + 0.5, 0, cz), "E : regarder le calendrier", func(): M.say("Le calendrier s'est arrêté en novembre, il y a trois hivers. Un samedi est entouré de rouge : « Anniversaire de Léa — 8 ans ! ». Personne n'a tourné la page.", 8.0), 1.2)
	var hz: Vector3 = R.horloge(hw - 0.3, -hd * 0.35, -90.0)
	M.act(hz, "E : regarder l'horloge", func(): M.say("L'horloge est arrêtée sur minuit. Comme toutes les horloges de Sombreval.", 5.0), 1.2)
	M.chest(hw - 0.75, -hd + 0.6, -25.0, M.loot(1.0), "coffre", "E : ouvrir le coffre au pied du buffet")
	S._murs(M, 1)
	M.ctx["entree"] = "Un appartement… La table est encore mise. Les assiettes sont sèches depuis longtemps, et le gâteau d'anniversaire attend toujours sous sa cloche de verre. Personne n'a fini son souper."
	M.ctx["on_enter"] = func(first: bool) -> void:
		if first:
			M.say(str(M.ctx["entree"]), 7.0)
		await M.get_tree().create_timer(5.0).timeout
		if M.inside:
			M.main.sfx("porte_grince")


## Le refuge : quelqu'un s'est caché ici (les fenêtres clouées, l'armoire contre la vitre, le matelas
## par terre, les conserves, la radio, le plan de la ville annoté) ; ses bougies sont encore tièdes.
## Le mot de Solène, la postière (elle est dans les souterrains du château).
static func _refuge(M) -> void:
	var R = M.R
	var r := _r(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	_usure(M, 1.0)
	# l'armoire poussée contre une fenêtre, des chaises entassées devant l'autre
	var fen: Array = _fenetres(R)
	for f in fen:
		if float(f[3]) < -45.0:
			R.armoire(hw - 0.3, float(f[2]), -90.0, 1.1, minf(2.0, R.H - 0.5))
			break
	for f2 in fen:
		if float(f2[3]) > 45.0:
			var cz: float = float(f2[2])
			R.chaise(-hw + 0.35, cz - 0.3, 100.0)
			R.kit.box(R.L(-hw + 0.4, 0.95, cz + 0.1, 90.0) * Transform3D(Basis(Vector3.RIGHT, 0.4), Vector3.ZERO), Vector3(1.2, 0.06, 0.7), "bois", 1.0)
			R.kit.box(R.L(-hw + 0.3, 0.55, cz + 0.45), Vector3(0.5, 1.1, 0.4), "bois_sombre", 1.0)
			R.reserve(-hw + 0.5, cz, 1.0, 1.6)
			break
	# le matelas par terre, la couverture grise, l'oreiller
	var mx: float = -0.6
	var mz: float = -hd + 1.15
	R.kit.box(R.L(mx, 0.08, mz, 90.0), Vector3(1.95, 0.16, 0.95), "drap", 1.0)
	R.kit.box(R.L(mx + 0.25, 0.18, mz, 90.0 + r.randf_range(-6, 6)), Vector3(1.3, 0.05, 1.0), "tissu_gris", 1.0)
	R.kit.box(R.L(mx - 0.72, 0.2, mz, 90.0), Vector3(0.36, 0.1, 0.7), "drap", 1.0)
	R.reserve(mx, mz, 2.2, 1.2)
	# les caisses : les bougies (encore tièdes), les conserves, les bouteilles d'eau, la radio
	R.caisse(mx + 1.55, mz - 0.1, 0.6)
	for k in range(3):
		R.bougie(mx + 1.42 + k * 0.12, 0.6, mz - 0.22 + (k % 2) * 0.16, k == 1)
	R.caisse(mx + 1.6, mz + 0.75, 0.55)
	for row in range(3):
		for c in range(3 - row):
			R.kit.cyl(R.L(mx + 1.48 + c * 0.1 + row * 0.05, 0.55 + row * 0.11, mz + 0.7), 0.045, 0.045, 0.11, "metal", 10)
	for k2 in range(3):
		R.kit.cyl(R.L(mx + 1.75, 0.55, mz + 0.55 + k2 * 0.09), 0.035, 0.03, 0.26, "verre", 8)
	var rx: float = hw - 0.9
	var rz: float = hd * 0.15
	R.caisse(rx, rz, 0.6)
	R.kit.box(R.L(rx, 0.73, rz, -70.0), Vector3(0.42, 0.26, 0.2), "bois_sombre", 1.0)
	R.kit.box(R.L(rx, 0.73, rz, -70.0) * Transform3D(Basis(), Vector3(-0.08, 0, 0.101)), Vector3(0.2, 0.18, 0.005), "noir", 1.0, 16)
	R.kit.cyl(Transform3D(R.L(rx, 0.73, rz, -70.0).basis * Basis(Vector3.RIGHT, PI * 0.5), R.L(rx, 0.73, rz, -70.0) * Vector3(0.12, 0.0, 0.1)), 0.03, 0.03, 0.03, "or", 10)
	R.kit.box(R.L(rx, 0.73, rz, -70.0) * Transform3D(Basis(Vector3.BACK, 0.4), Vector3(0.1, 0.4, -0.05)), Vector3(0.01, 0.6, 0.01), "fer", 1.0)
	var radio_txt: Array = ["Grésillements… puis, très loin, une musique de bal. Une valse. Elle vient du château.",
		"Grésillements… une voix, à peine : « … ici le continent… Sombreval, répondez… » Puis plus rien.",
		"Grésillements. Rien que des grésillements. Et, par-dessous, comme un cœur qui bat."]
	var radio := func() -> void:
		var nr: int = int(M.state().get("radio", 0))
		M.state()["radio"] = nr + 1
		M.main.sfx("radio_gresillement", R.P(rx, 0.8, rz))
		M.say(str(radio_txt[nr % radio_txt.size()]), 6.0)
	M.act(R.P(rx - 0.6, 0, rz), "E : tourner le bouton de la radio", radio, 1.2)
	# le plan de la ville, annoté
	var pl: String = _img(R, "sv_plan", "beau169/sv_plan.png")
	_cadre(R, pl, -0.3, 1.65, -hd + 0.02, 0.0, 1.0, 0.75, "")
	M.act(R.P(-0.3, 0, -hd + 0.9), "E : regarder le plan de la ville", func(): M.say("Un plan de Sombreval, annoté au crayon. Des croix rouges sur les rues où ils rôdent. Une flèche vers le port : « bateau ? ». Et, autour du château, entouré trois fois : « NE PAS Y ALLER ».", 8.0), 1.2)
	# le mot de Solène
	var libres: bool = _captifs_libres(M)
	S._mot(M, mx + 0.3, mz - 0.1, 0.22, "Un mot, plié en quatre : « À qui trouvera ce mot. Je m'appelle Solène, je suis (j'étais) la postière. J'ai tenu onze jours ici. Ils ne voient pas bien, mais ils entendent tout : ne fais pas de bruit. Ce soir, je tente le port. Prends ce qui reste, tu en auras plus besoin que moi. »" + (" (Solène est libre, maintenant : elle est sur la Place du Marché, avec les autres.)" if libres else ""), "E : lire le mot plié en quatre")
	M.chest(-hw + 0.75, hd * 0.35, 60.0, [["pomme", 2], ["jus_pomme", 1], ["remontant_doc", 1], ["piece", 12 + r.randi() % 10]], "coffre", "E : ouvrir la réserve de Solène")
	M.ctx["entree"] = "Quelqu'un s'est caché ici. Des planches clouées sur les fenêtres, une armoire poussée contre la vitre, un matelas par terre… et des bougies. Elles ont brûlé il n'y a pas si longtemps."


## La chambre d'enfant : le petit lit, le coffre à jouets, le cheval à bascule, les cubes, le ballon,
## les dessins punaisés, la boîte à musique, l'ours en peluche tombé par terre (on le remet sur l'oreiller).
static func _enfant(M) -> void:
	var R = M.R
	var r := _r(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	_usure(M, 0.6)
	var c: String = str(_pick(M, ["rose", "bleu", "jaune", "vert"]))
	var lx: float = -hw + 0.62
	var lz: float = -hd + 1.08
	R.lit(lx, lz, 0.0, 0.9, c)
	R.coffre_deco(lx + 1.05, -hd + 0.45, 0.0)
	# le cheval à bascule
	var hx: float = hw - 1.0
	var hz: float = -hd + 1.3
	var X: Transform3D = R.L(hx, 0, hz, -60.0)
	for sx in [-0.16, 0.16]:
		for k in range(7):
			var u: float = (k - 3) / 3.0
			R.kit.box(X * Transform3D(Basis(Vector3.RIGHT, -u * 0.45), Vector3(sx, 0.05 + u * u * 0.09, u * 0.36)), Vector3(0.04, 0.03, 0.14), "bois_sombre", 1.0)
		R.kit.box(X * Transform3D(Basis(), Vector3(sx, 0.25, 0.0)), Vector3(0.03, 0.34, 0.04), "bois_sombre", 1.0)
	R.kit.box(X * Transform3D(Basis(), Vector3(0, 0.45, 0)), Vector3(0.26, 0.24, 0.62), "bois_clair", 1.0)
	R.kit.box(X * Transform3D(Basis(Vector3.RIGHT, -0.5), Vector3(0, 0.66, 0.3)), Vector3(0.14, 0.34, 0.14), "bois_clair", 1.0)
	R.kit.box(X * Transform3D(Basis(Vector3.RIGHT, 0.2), Vector3(0, 0.8, 0.44)), Vector3(0.13, 0.13, 0.26), "bois_clair", 1.0)
	R.kit.box(X * Transform3D(Basis(Vector3.RIGHT, -0.5), Vector3(0, 0.76, 0.24)), Vector3(0.05, 0.4, 0.06), "tissu_brun", 1.0)
	R.kit.box(X * Transform3D(Basis(), Vector3(0, 0.58, -0.05)), Vector3(0.3, 0.04, 0.26), "tissu_rouge", 1.0)
	R.kit.box(X * Transform3D(Basis(Vector3.RIGHT, 0.6), Vector3(0, 0.44, -0.36)), Vector3(0.04, 0.3, 0.05), "tissu_brun", 1.0)
	R.reserve(hx, hz, 1.0, 1.0)
	# les cubes, le ballon
	for k2 in range(7):
		var bx: float = r.randf_range(-0.6, 0.9)
		var bz: float = r.randf_range(-0.3, 0.8)
		R.kit.box(R.L(bx, 0.06 if k2 < 5 else 0.18, bz, r.randf_range(0, 90)), Vector3(0.12, 0.12, 0.12), "tissu_" + str(["rouge", "bleu", "jaune", "vert", "orange", "violet", "rose"][k2]), 1.0)
	_boule(R.root, R.mat("tissu_rouge"), R.P(hw - 0.7, 0.14, hd * 0.1), 0.14)
	# les dessins punaisés au-dessus du lit
	var des: String = _img(R, "sv_dessins", "beau169/sv_dessins.png")
	_cadre(R, des, lx + 0.9, 1.55, -hd + 0.02, 0.0, 0.9, 0.6, "")
	M.act(R.P(lx + 0.9, 0, -hd + 1.2), "E : regarder les dessins", func(): M.say("Des dessins aux crayons de couleur. Un château sur une colline, avec des fenêtres rouges et des chauves-souris. Une maison, un chat noir, un grand soleil jaune. En bas, d'une écriture appliquée : « Quand je serai grande, je ferai partir le brouillard. »", 9.0), 1.2)
	# la commode et la boîte à musique
	var cx: float = hw - 0.32
	var cz: float = hd * 0.12
	R.kit.box(R.L(cx, 0.4, cz, -90.0), Vector3(0.8, 0.8, 0.45), "bois", 1.0)
	for k3 in range(3):
		R.kit.box(R.L(cx - 0.226, 0.16 + k3 * 0.24, cz, -90.0), Vector3(0.72, 0.2, 0.01), "bois_clair", 1.0, 16)
	R.kit.col_box(R.L(cx, 0.4, cz, -90.0), Vector3(0.8, 0.8, 0.45))
	R.reserve(cx, cz, 0.6, 1.0)
	R.kit.box(R.L(cx - 0.02, 0.86, cz, -90.0), Vector3(0.2, 0.12, 0.14), "bois_clair", 1.0)
	R.kit.box(R.L(cx - 0.02, 0.93, cz, -90.0), Vector3(0.21, 0.02, 0.15), "or", 1.0)
	_couleur(R, "rose_v169", Color(0.95, 0.75, 0.8), 0.5)
	R.kit.cyl(R.L(cx - 0.02, 0.94, cz), 0.025, 0.02, 0.06, "rose_v169", 8)
	var musique := func() -> void:
		M.main.sfx("boite_musique", R.P(cx, 0.9, cz))
		M.say("Une petite mélodie grêle s'élève, une berceuse… La danseuse tourne, tourne, puis s'arrête net, au milieu d'une note.", 6.0)
	M.act(R.P(cx - 0.7, 0, cz), "E : remonter la boîte à musique", musique, 1.2)
	# l'ours en peluche, tombé par terre
	var brun: Material = R.mat("tissu_brun")
	var ours := Node3D.new()
	ours.name = "Ours_v169"
	R.root.add_child(ours)
	var op: Vector3 = R.P(0.2, 0.0, hd * 0.25)
	var lit_p: Vector3 = R.P(lx, 0.62, lz - 0.6)
	ours.global_position = lit_p if bool(M.state().get("ours", false)) else op
	ours.rotation.y = 0.0 if bool(M.state().get("ours", false)) else 1.1
	var corps := [[Vector3(0, 0.12, 0), 0.1, Vector3(1, 1.15, 0.9)], [Vector3(0, 0.29, 0.01), 0.075, Vector3.ONE], [Vector3(-0.06, 0.35, 0.0), 0.028, Vector3.ONE],
		[Vector3(0.06, 0.35, 0.0), 0.028, Vector3.ONE], [Vector3(0, 0.27, 0.065), 0.03, Vector3(1, 0.8, 1)], [Vector3(-0.1, 0.15, 0.03), 0.04, Vector3(1, 1.4, 1)],
		[Vector3(0.1, 0.15, 0.03), 0.04, Vector3(1, 1.4, 1)], [Vector3(-0.06, 0.03, 0.06), 0.045, Vector3(1, 0.8, 1.3)], [Vector3(0.06, 0.03, 0.06), 0.045, Vector3(1, 0.8, 1.3)]]
	for e in corps:
		var mi: MeshInstance3D = _boule(ours, brun, Vector3.ZERO, float(e[1]), e[2])
		mi.position = e[0]
	var nez: MeshInstance3D = _boule(ours, R.mat("noir"), Vector3.ZERO, 0.012)
	nez.position = Vector3(0, 0.28, 0.095)
	var ramasser := func() -> void:
		M.state()["ours"] = true
		var tw: Tween = M.room.create_tween()
		tw.tween_property(ours, "global_position", lit_p, 0.8).set_trans(Tween.TRANS_QUAD)
		tw.parallel().tween_property(ours, "rotation:y", 0.0, 0.8)
		M.say("Tu ramasses l'ours en peluche, tu le secoues un peu, et tu le poses sur l'oreiller. Il a l'air un peu moins seul.", 6.0)
	var par_terre := func() -> bool:
		return not bool(M.state().get("ours", false))
	M.act(op, "E : ramasser l'ours en peluche", ramasser, 1.2, par_terre)
	M.ctx["entree"] = "Une chambre d'enfant. Des jouets partout sous la poussière, un cheval à bascule qui ne bascule plus. Aux murs, des dessins aux crayons de couleur."


## Le chat qui est resté : un salon sous les draps, deux gamelles, et Minuit, le chat noir, sur le
## fauteuil ; on le caresse, on lui donne un poisson (une bonne action).
static func _chat(M) -> void:
	var R = M.R
	var r := _r(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	_usure(M, 0.5)
	R.drape(-0.3, -0.1, 0, 1.4, 0.9, 0.78)
	R.drape(-hw + 0.5, -hd * 0.3, 90, 1.6, 0.6, 1.9)
	R.foyer(R.W * 0.2, -hd + 0.38, 0, false)
	var fx: float = hw - 0.85
	var fz: float = -hd + 1.0
	R.fauteuil(fx, fz, -135.0, "vert")
	var nourri: bool = bool(M.state().get("nourri", false))
	R.chat(fx - 0.05, fz + 0.05, 45.0 if not nourri else 30.0, Color(0.07, 0.07, 0.08), nourri, 0.5)
	# les gamelles, près de la porte de la cuisine
	var gx: float = -hw + 0.6
	var gz: float = hd * 0.35
	R.kit.cyl(R.L(gx, 0.0, gz), 0.1, 0.08, 0.06, "ceramique", 14)
	R.kit.cyl(R.L(gx + 0.25, 0.0, gz + 0.05), 0.1, 0.08, 0.06, "ceramique", 14)
	R.kit.cyl(R.L(gx + 0.25, 0.045, gz + 0.05), 0.085, 0.085, 0.004, "verre", 14)
	R.reserve(gx + 0.1, gz, 0.6, 0.4)
	var chat_p: Vector3 = R.P(fx - 0.3, 0, fz + 0.45)
	var caresser := func() -> void:
		M.main.sfx("ronron", R.P(fx, 0.6, fz))
		var n: int = int(M.state().get("caresses", 0))
		M.state()["caresses"] = n + 1
		if n == 0:
			M.say("Le chat recule d'un pas… puis vient se frotter contre ta main. Ronron. Il est maigre, mais il se débrouille : la ville est pleine de souris. Sur son collier, une petite médaille : « Minuit ».", 8.0)
		else:
			M.say(str(_pick(M, ["Ronron… Minuit ferme les yeux.", "Minuit s'étire de tout son long et ronronne de plus belle.", "Minuit te donne un petit coup de tête : encore !"])), 4.0)
	M.act(chat_p, "E : caresser le chat", caresser, 1.3)
	var donner := func() -> void:
		var pf: String = _poisson(M)
		if pf == "":
			return
		(M.main.get("inventory_v28") as Node).remove(pf, 1)
		M.state()["nourri"] = true
		M.main.sfx("chat_miaou", R.P(fx, 0.6, fz))
		M.bonne_action_v120("animal")
		M.say("Minuit ne se fait pas prier : le poisson disparaît en trois bouchées. Puis il se roule en boule sur le fauteuil et s'endort, le ventre plein. Il ronronne en dormant.", 7.0)
	var a_faim := func() -> bool:
		return not bool(M.state().get("nourri", false)) and _poisson(M) != ""
	M.act(chat_p + R.xf0.basis * Vector3(0.45, 0, 0.0), "E : donner un poisson à Minuit", donner, 1.3, a_faim)
	S._murs(M, 2)
	M.ctx["entree"] = "Un salon abandonné, les meubles sous des draps… Deux yeux jaunes brillent dans la pénombre, sur le fauteuil. Un chat noir ! Il te regarde sans bouger." if not nourri else "Le salon de Minuit. Il dort en boule sur son fauteuil, et ronronne en dormant."
	M.ctx["on_enter"] = func(first: bool) -> void:
		M.say(str(M.ctx["entree"]), 6.0)
		await M.get_tree().create_timer(1.6).timeout
		if M.inside:
			M.main.sfx("chat_miaou" if not bool(M.state().get("nourri", false)) else "ronron", R.P(fx, 0.6, fz))


## La vieille pharmacie : le comptoir et son marbre, les étagères de flacons et de pots de faïence, la
## balance, le mortier, la croix verte ; une ordonnance du docteur Vasseur ; le coffre du pharmacien.
static func _pharmacie(M) -> void:
	var R = M.R
	var r := _r(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	_usure(M, 0.3)
	# le comptoir (on passe à droite)
	var cz: float = -hd * 0.15
	var cw: float = R.W - 2.2
	var ccx: float = -hw + 0.4 + cw * 0.5
	R.kit.box(R.L(ccx, 0.5, cz), Vector3(cw, 1.0, 0.6), "bois_sombre", 1.0)
	R.kit.box(R.L(ccx, 1.02, cz), Vector3(cw + 0.06, 0.04, 0.66), "pierre_lisse", 1.0)
	for k in range(int(cw / 0.9)):
		R.kit.box(R.L(-hw + 0.4 + 0.45 + k * 0.9, 0.5, cz + 0.301), Vector3(0.74, 0.74, 0.01), "bois", 1.0, 16)
	R.kit.col_box(R.L(ccx, 0.5, cz), Vector3(cw, 1.0, 0.6))
	R.reserve(ccx, cz, cw, 0.8)
	# la balance, le mortier, le registre
	R.kit.cyl(R.L(ccx - 0.6, 1.04, cz), 0.08, 0.1, 0.03, "cuivre", 12)
	R.kit.cyl(R.L(ccx - 0.6, 1.07, cz), 0.012, 0.012, 0.32, "cuivre", 6)
	R.kit.box(R.L(ccx - 0.6, 1.39, cz), Vector3(0.44, 0.012, 0.012), "cuivre", 1.0)
	for sx in [-0.21, 0.21]:
		R.kit.cyl(R.L(ccx - 0.6 + sx, 1.2, cz), 0.07, 0.05, 0.03, "cuivre", 12)
		R.kit.box(R.L(ccx - 0.6 + sx, 1.3, cz), Vector3(0.004, 0.18, 0.004), "cuivre", 1.0)
	R.kit.cyl(R.L(ccx + 0.3, 1.04, cz + 0.05), 0.07, 0.09, 0.09, "pierre_lisse", 12)
	R.kit.box(R.L(ccx + 0.3, 1.14, cz + 0.05) * Transform3D(Basis(Vector3.BACK, 0.5), Vector3.ZERO), Vector3(0.025, 0.18, 0.025), "pierre_lisse", 1.0)
	S._mot(M, ccx + 0.85, cz, 1.04, "Une ordonnance, de la main du docteur Vasseur : « Pour Mme Grimaud : de l'ail. Beaucoup d'ail. Des volets bien fermés. Et surtout, ne sortez plus après minuit. »", "E : lire l'ordonnance")
	# les étagères de flacons (au fond), les pots de faïence
	var fk: Array = ["verre", "ceramique", "cuivre", "verre_ambre", "verre_vert"]
	_couleur(R, "verre_ambre", Color(0.55, 0.32, 0.1), 0.15)
	_couleur(R, "verre_vert", Color(0.18, 0.35, 0.22), 0.15)
	var sw: float = R.W - 1.2
	for row in range(5):
		var y: float = 0.35 + row * 0.42
		R.kit.box(R.L(0, y, -hd + 0.2), Vector3(sw, 0.03, 0.34), "bois_sombre", 1.0)
		var n: int = int(sw / 0.14)
		for i in range(n):
			if r.randf() < 0.22:
				continue
			var bx: float = -sw * 0.5 + 0.07 + i * 0.14
			var key: String = str(fk[r.randi() % fk.size()])
			var hh: float = r.randf_range(0.12, 0.26)
			if key == "ceramique":
				R.kit.cyl(R.L(bx, y + 0.015, -hd + 0.2), 0.055, 0.055, hh * 0.8, "ceramique", 10)
				R.kit.cyl(R.L(bx, y + 0.015 + hh * 0.35, -hd + 0.2), 0.057, 0.057, 0.04, "or", 10, false)
			else:
				R.kit.cyl(R.L(bx, y + 0.015, -hd + 0.2), 0.04, 0.04, hh, key, 8)
				R.kit.cyl(R.L(bx, y + 0.015 + hh, -hd + 0.2), 0.015, 0.012, 0.04, key, 6)
	for sx2 in [-sw * 0.5, sw * 0.5]:
		R.kit.box(R.L(sx2, 1.1, -hd + 0.2), Vector3(0.04, 2.2, 0.36), "bois_sombre", 1.0)
	R.kit.col_box(R.L(0, 1.1, -hd + 0.2), Vector3(sw, 2.2, 0.36))
	R.reserve(0, -hd + 0.2, sw, 0.6)
	R.mark_wall(0, 1.6, -hd + 0.02, sw * 0.5)
	# la croix verte, au mur de droite (éteinte)
	_couleur(R, "croix_verte", Color(0.12, 0.42, 0.2), 0.4)
	var gx: Transform3D = R.L(hw - 0.03, 2.2, hd * 0.1, -90.0)
	R.kit.box(gx, Vector3(0.5, 0.16, 0.06), "croix_verte", 1.0)
	R.kit.box(gx, Vector3(0.16, 0.5, 0.06), "croix_verte", 1.0)
	R.mark_wall(hw - 0.03, 2.2, hd * 0.1, 0.4)
	M.chest(hw - 0.7, -hd * 0.5, -60.0, [["remontant_doc", 1], ["fiole_vide", 2], ["piece", 14 + r.randi() % 8]], "coffre", "E : ouvrir le coffre du pharmacien")
	M.ctx["entree"] = "Une vieille pharmacie. Derrière le comptoir, des centaines de flacons alignés sous un doigt de poussière. Ça sent encore un peu le camphre."


## La salle d'attente de la gare : les bancs, le guichet et sa grille, le tableau des départs (tous
## supprimés), la grande horloge arrêtée, les valises qui attendent leurs voyageurs.
static func _gare(M) -> void:
	var R = M.R
	var r := _r(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	R._put("sol", R._texmat("maisons/damier_noir_blanc.png", Color(0.64, 0.62, 0.58), 0.6))
	R._put("mur", R._texmat("maisons/chaux_vert.png", Color(0.62, 0.66, 0.62), 0.95))
	R._put("bas", R._texmat("maisons/lambris_sombre.png", Color(0.72, 0.7, 0.66), 0.9))
	_usure(M, 0.5)
	# les bancs (on regarde le tableau)
	for bz in [-hd * 0.15, hd * 0.25]:
		for bx in [-1.5, 1.5]:
			R.banc(bx, bz, 180.0, 2.2)
			R.kit.box(R.L(bx, 0.78, bz - 0.17, 180.0) * Transform3D(Basis(Vector3.RIGHT, -0.15), Vector3.ZERO), Vector3(2.2, 0.5, 0.05), "bois", 1.0)
			R.reserve(bx, bz, 2.4, 0.7)
	# le tableau des départs
	var ho: String = _img(R, "sv_horaires", "beau169/sv_horaires.png")
	_cadre(R, ho, 0.0, 2.05, -hd + 0.02, 0.0, 2.6, 1.3)
	M.act(R.P(0.0, 0, -hd + 1.2), "E : lire le tableau des départs", func(): M.say("DÉPARTS. Tous les trains : SUPPRIMÉ. En bas, à la craie : « Plus aucun train depuis trois hivers. Le dernier est parti à minuit… sans personne dedans. »", 8.0), 1.3)
	# le guichet (mur de gauche), sa grille, son écriteau
	var gz: float = -hd * 0.1
	var G: Transform3D = R.L(-hw + 0.4, 0, gz, 90.0)
	R.kit.box(G * Transform3D(Basis(), Vector3(0, 0.55, 0)), Vector3(2.4, 1.1, 0.7), "bois_sombre", 1.0)
	R.kit.box(G * Transform3D(Basis(), Vector3(0, 1.12, 0.05)), Vector3(2.5, 0.05, 0.8), "pierre_lisse", 1.0)
	R.kit.box(G * Transform3D(Basis(), Vector3(0, 1.75, -0.15)), Vector3(2.4, 1.2, 0.02), "verre", 1.0)
	for k in range(13):
		R.kit.box(G * Transform3D(Basis(), Vector3(-1.2 + k * 0.2, 1.75, -0.13)), Vector3(0.015, 1.2, 0.015), "fer", 1.0)
	R.kit.box(G * Transform3D(Basis(), Vector3(0, 2.4, -0.1)), Vector3(2.5, 0.1, 0.12), "bois_sombre", 1.0)
	R.kit.col_box(G * Transform3D(Basis(), Vector3(0, 0.9, 0)), Vector3(2.4, 1.8, 0.7))
	R.reserve(-hw + 0.4, gz, 0.9, 2.6)
	R.mark_wall(-hw + 0.02, 1.6, gz, 1.3)
	var lb := Label3D.new()
	lb.text = "GUICHET"
	lb.font_size = 64
	lb.pixel_size = 0.0035
	lb.modulate = Color(0.85, 0.8, 0.62)
	lb.outline_size = 0
	R.root.add_child(lb)
	lb.global_transform = G * Transform3D(Basis(), Vector3(0, 2.4, -0.035))
	R.kit.box(G * Transform3D(Basis(), Vector3(0.3, 1.16, 0.1)), Vector3(0.12, 0.06, 0.08), "fer", 1.0)
	M.act(G * Vector3(0, 0, 1.2), "E : regarder par le guichet", func(): M.say("Derrière la grille : un tampon, un carnet de billets. Le dernier vendu : « Sombreval → La Mer, aller simple ». Il n'a jamais été composté.", 7.0), 1.3)
	# la grande horloge (mur de droite), arrêtée sur minuit
	var H: Transform3D = R.L(hw - 0.03, 2.25, -hd * 0.1, -90.0)
	R.kit.cyl(H * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0, 0.02)), 0.5, 0.5, 0.04, "ceramique", 28)
	R.kit.ring(H * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0, 0.0)), 0.5, 0.56, 0.07, "fer", 28)
	for k2 in range(12):
		var a: float = TAU * k2 / 12.0
		R.kit.box(H * Transform3D(Basis(Vector3.BACK, a), Vector3(sin(a) * 0.42, cos(a) * 0.42, 0.065)), Vector3(0.025, 0.07, 0.01), "noir", 1.0)
	R.kit.box(H * Transform3D(Basis(), Vector3(0, 0.17, 0.075)), Vector3(0.035, 0.34, 0.01), "noir", 1.0)
	R.kit.box(H * Transform3D(Basis(), Vector3(0.0, 0.12, 0.085)), Vector3(0.05, 0.24, 0.01), "noir", 1.0)
	R.mark_wall(hw - 0.03, 2.25, -hd * 0.1, 0.65)
	# les valises, la malle, le parapluie oublié
	for k3 in range(4):
		var vx: float = r.randf_range(-hw + 1.6, hw - 1.0)
		var vz: float = r.randf_range(-hd * 0.6, hd * 0.5)
		if not R.is_free(vx, vz, 0.7, 0.5):
			continue
		var yaw: float = r.randf_range(0, 180)
		R.kit.box(R.L(vx, 0.22, vz, yaw), Vector3(0.6, 0.44, 0.2), str(_pick(M, ["cuir", "tissu_brun", "tissu_rouge"])), 1.0)
		R.kit.box(R.L(vx, 0.47, vz, yaw), Vector3(0.16, 0.05, 0.03), "fer", 1.0)
		R.reserve(vx, vz, 0.7, 0.5)
	R.kit.box(R.L(hw - 0.8, 0.3, hd * 0.45, -20.0), Vector3(0.9, 0.6, 0.55), "bois", 1.0)
	for sx in [-0.3, 0.3]:
		R.kit.box(R.L(hw - 0.8, 0.3, hd * 0.45, -20.0) * Transform3D(Basis(), Vector3(sx, 0, 0)), Vector3(0.05, 0.62, 0.57), "fer", 1.0)
	R.kit.col_box(R.L(hw - 0.8, 0.3, hd * 0.45, -20.0), Vector3(0.9, 0.6, 0.55))
	R.kit.box(R.L(hw - 0.35, 0.45, -hd * 0.55, 0.0) * Transform3D(Basis(Vector3.BACK, 0.25), Vector3.ZERO), Vector3(0.025, 0.9, 0.025), "noir", 1.0)
	# l'affiche d'avant (Sombreval, sa fête des lanternes)
	var av: String = _img(R, "sv_avant_aff", "beau169/sv_avant.png")
	_cadre(R, av, hw - 0.02, 1.6, hd * 0.35, -90.0, 0.8, 0.6)
	M.ctx["entree"] = "La salle d'attente de la gare. Les bancs sont vides, les valises attendent encore leurs voyageurs… Là-haut, la grande horloge marque minuit."


## Le mécanisme du beffroi : les grandes roues dentées dans leur bâti, le balancier, les poids, la
## corde de la cloche qui pend du plafond, l'échelle vers la chambre des cloches, le dos du cadran ;
## figé sur minuit… jusqu'à ce que le comte tombe : alors tout se remet à tourner.
static func _beffroi(M) -> void:
	var R = M.R
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	R._put("mur", R._texmat("montjoie/moellons.png", Color(0.62, 0.6, 0.57), 0.95))
	R._put("bas", R._texmat("montjoie/moellons.png", Color(0.5, 0.48, 0.46), 0.95))
	R._put("sol", R._texmat("montjoie/bois_planches.png", Color(0.55, 0.48, 0.42), 0.9))
	_usure(M, 0.0, false)
	var libre: bool = _libere(M)
	# le bâti de chêne
	var bz: float = -hd + 0.9
	for sx in [-1.1, 1.1]:
		R.kit.box(R.L(sx, R.H * 0.5, bz), Vector3(0.14, R.H, 0.14), "poutre", 1.0)
		R.kit.box(R.L(sx, R.H * 0.5, bz - 0.5), Vector3(0.14, R.H, 0.14), "poutre", 1.0)
	for y in [0.3, 1.6, R.H - 0.3]:
		R.kit.box(R.L(0, y, bz), Vector3(2.36, 0.12, 0.12), "poutre", 1.0)
		R.kit.box(R.L(0, y, bz - 0.5), Vector3(2.36, 0.12, 0.12), "poutre", 1.0)
	R.kit.col_box(R.L(0, R.H * 0.5, bz - 0.25), Vector3(2.4, R.H, 0.7))
	R.reserve(0, bz - 0.25, 2.6, 1.0)
	# les roues dentées (chacune sur son axe : elles tournent quand le temps repart)
	var roues: Array = []
	for g in [[-0.45, 1.25, 0.62, 40, "cuivre", 1.0], [0.42, 1.75, 0.36, 24, "fer", -1.72], [0.6, 0.85, 0.24, 16, "or", 2.6]]:
		var piv := Node3D.new()
		piv.name = "Roue_v169"
		R.root.add_child(piv)
		piv.global_transform = R.L(float(g[0]), float(g[1]), bz - 0.25)
		var k := AzurKit.new()
		k.setup(piv, null)
		k.mats = R.kit.mats
		var rr: float = float(g[2])
		var key: String = str(g[4])
		k.cyl(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0, -0.03)), rr, rr, 0.06, key, 32)
		k.ring(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0, -0.04)), rr * 0.3, rr * 0.82, 0.08, "noir", 24)
		for sp in range(6):
			k.box(Transform3D(Basis(Vector3.BACK, TAU * sp / 6.0), Vector3.ZERO) * Transform3D(Basis(), Vector3(0, rr * 0.55, 0)), Vector3(0.05, rr * 0.55, 0.1), key, 1.0)
		for t in range(int(g[3])):
			var a: float = TAU * t / float(g[3])
			k.box(Transform3D(Basis(Vector3.BACK, a), Vector3(sin(a), cos(a), 0) * (rr + 0.03)), Vector3(0.045, 0.07, 0.06), key, 1.0)
		k.cyl(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0, -0.3)), 0.04, 0.04, 0.6, "fer", 10)
		k.commit()
		roues.append([piv, float(g[5])])
	# le balancier, les poids et leurs chaînes
	var bal := Node3D.new()
	bal.name = "Balancier_v169"
	R.root.add_child(bal)
	bal.global_transform = R.L(0.0, R.H - 0.35, bz + 0.25)
	var kb := AzurKit.new()
	kb.setup(bal, null)
	kb.mats = R.kit.mats
	kb.box(Transform3D(Basis(), Vector3(0, -1.0, 0)), Vector3(0.03, 2.0, 0.02), "fer", 1.0)
	kb.cyl(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, -2.15, -0.03)), 0.2, 0.2, 0.06, "or", 24)
	kb.commit()
	for sx3 in [-0.8, 0.8]:
		R.kit.cyl(R.L(sx3, 0.5, bz + 0.2), 0.11, 0.11, 0.45, "fer", 12)
		for k4 in range(int((R.H - 1.1) / 0.09)):
			R.kit.box(R.L(sx3, 0.98 + k4 * 0.09, bz + 0.2, 45.0 * (k4 % 2)), Vector3(0.02, 0.08, 0.05), "fer", 1.0)
	# la corde de la cloche, le trou dans le plafond ; l'échelle vers la chambre des cloches
	R.kit.cyl(R.L(hw - 1.0, R.H - 0.01, hd * 0.05), 0.28, 0.28, 0.02, "noir", 16)
	R.kit.cyl(R.L(hw - 1.0, 0.8, hd * 0.05), 0.022, 0.022, R.H - 0.8, "tissu_brun", 8)
	R.kit.cyl(R.L(hw - 1.0, 0.55, hd * 0.05), 0.045, 0.04, 0.3, "tissu_rouge", 10)
	R.echelle(-hw + 0.5, -hd + 0.55, 90.0, R.H)
	R.kit.box(R.L(-hw + 0.75, R.H - 0.005, -hd + 0.6), Vector3(0.9, 0.01, 0.9), "noir", 1.0, 8)
	# le dos du cadran (le jour passe à travers le verre dépoli), les aiguilles sur minuit
	var C: Transform3D = R.L(hw - 0.03, 1.85, -hd * 0.25, -90.0)
	R.kit.cyl(C * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0, 0.01)), 0.95, 0.95, 0.02, "vitre", 36)
	R.kit.ring(C * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0, 0.0)), 0.95, 1.05, 0.06, "fer", 36)
	for k5 in range(12):
		var a5: float = TAU * k5 / 12.0
		R.kit.box(C * Transform3D(Basis(Vector3.BACK, a5), Vector3(sin(a5) * 0.8, cos(a5) * 0.8, 0.035)), Vector3(0.04, 0.16, 0.012), "noir", 1.0)
	R.kit.box(C * Transform3D(Basis(), Vector3(0, 0.33, 0.045)), Vector3(0.05, 0.66, 0.012), "noir", 1.0)
	R.kit.box(C * Transform3D(Basis(), Vector3(0, 0.22, 0.055)), Vector3(0.07, 0.44, 0.012), "noir", 1.0)
	R.kit.cyl(C * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0, 0.03)), 0.06, 0.06, 0.06, "fer", 12)
	R.mark_wall(hw - 0.03, 1.85, -hd * 0.25, 1.1)
	S._mot(M, -hw + 0.9, hd * 0.2, 0.0, "Le carnet du sonneur, le père Joachim : « Minuit. La cloche s'est tue d'elle-même, au milieu du douzième coup. J'ai tiré la corde de toutes mes forces : pas un son. Et toutes les horloges de la ville se sont arrêtées avec elle. »", "E : lire le carnet du sonneur")
	var pousser := func() -> void:
		if _libere(M):
			M.say("Le balancier va et vient, tranquille. Tic… tac… Le beffroi sonne de nouveau les heures : le temps est revenu à Sombreval.", 6.0)
			return
		M.main.sfx("mecanisme", R.P(0, 1.5, bz))
		var tw: Tween = M.room.create_tween()
		tw.tween_property(bal, "rotation:z", 0.22, 0.5).set_trans(Tween.TRANS_SINE)
		tw.tween_property(bal, "rotation:z", 0.0, 0.35).set_trans(Tween.TRANS_BACK)
		M.say("Tu pousses le grand balancier. Il fait un aller… et s'arrête net, comme retenu par une main invisible. Tant que le comte règne sur Sombreval, le temps reste figé à minuit.", 8.0)
	M.act(R.P(0.0, 0, bz + 0.9), "E : pousser le grand balancier", pousser, 1.4)
	if libre:
		var t0: Array = [0.0]
		M.ctx["tick"] = func(dt: float) -> void:
			t0[0] += dt
			for e in roues:
				if is_instance_valid(e[0]):
					(e[0] as Node3D).rotate_object_local(Vector3.BACK, dt * 0.25 * float(e[1]))
			if is_instance_valid(bal):
				bal.rotation.z = sin(t0[0] * 2.6) * 0.16
	M.ctx["entree"] = "Le mécanisme de l'horloge du beffroi : des roues dentées grandes comme des tables, un balancier, des poids sur leurs chaînes… Tout est figé sur minuit." if not libre else "Le mécanisme de l'horloge du beffroi. Les roues tournent, le balancier va et vient : tic… tac… Le temps est revenu à Sombreval."


## Un poisson dans le sac (pour Minuit), ou "".
static func _poisson(M) -> String:
	var inv: Node = M.main.get("inventory_v28")
	if inv == null:
		return ""
	for p in POISSONS:
		if inv.count(p) > 0:
			return p
	return ""


static func _libere(M) -> bool:
	var sv: Node = M.main.get("sombreval_v121")
	return sv != null and (sv.get("state") is Dictionary) and bool((sv.state as Dictionary).get("libere", false))


static func _captifs_libres(M) -> bool:
	var sv: Node = M.main.get("sombreval_v121")
	if sv == null or sv.get("castle") == null or sv.castle == null:
		return false
	return (sv.castle.get("state") is Dictionary) and bool((sv.castle.state as Dictionary).get("libres", false))


# =================================================================== l'Île Crayonnée : la pièce ronde

## La coque d'un arbre-maison : le plancher rond et son tapis, le mur de lambris (ses montants, la
## plinthe, la cimaise), le plafond en cône sur ses chevrons et la couronne du faîte, trois fenêtres
## rondes, la porte en arc (fermée derrière nous), le poêle et son tuyau, la lanterne.
static func shell(M) -> void:
	var R = M.R
	var k = R.kit
	var rc: float = R.W * 0.5
	var hw: float = R.H
	var door_a: float = PI * 0.5
	var gap: float = 0.62 / rc
	# le plancher
	k.cyl(R.L(0, -0.2, 0), rc + 0.12, rc + 0.12, 0.2, "sol", 44, true, 1.2)
	k.col_box(R.L(0, -0.25, 0), Vector3(rc * 2.0 + 1.0, 0.5, rc * 2.0 + 1.0))
	k.cyl(R.L(0, 0.005, 0.1), rc * 0.55, rc * 0.55, 0.012, "tapis_0", 36, true, rc * 1.1)
	# le mur : des panneaux de lambris (pas devant la porte)
	var n: int = 44
	for i in range(n):
		var a: float = TAU * (i + 0.5) / n
		if absf(wrapf(a - door_a, -PI, PI)) < gap:
			continue
		var d := Vector3(cos(a), 0, sin(a))
		var w: float = TAU * (rc + 0.04) / n * 1.05
		var B := Basis(Vector3.UP, atan2(d.x, d.z))
		k.box(Transform3D(B, R.P(d.x * (rc + 0.04), 0.45, d.z * (rc + 0.04))), Vector3(w, 0.9, 0.05), "bas", 1.4)
		k.box(Transform3D(B, R.P(d.x * (rc + 0.04), 0.9 + (hw - 0.9) * 0.5, d.z * (rc + 0.04))), Vector3(w, hw - 0.9, 0.05), "mur", 1.4)
	# les montants, la plinthe, la cimaise, la sablière
	for j in range(12):
		var a2: float = TAU * (j + 0.5) / 12.0
		if absf(wrapf(a2 - door_a, -PI, PI)) < gap + 0.12:
			continue
		var d2 := Vector3(cos(a2), 0, sin(a2))
		k.box(Transform3D(Basis(Vector3.UP, atan2(d2.x, d2.z)), R.P(d2.x * (rc - 0.02), hw * 0.5, d2.z * (rc - 0.02))), Vector3(0.12, hw, 0.08), "poutre", 1.0)
	for ring in [[0.0, 0.12, "bois_sombre"], [0.88, 0.06, "bois_sombre"], [hw - 0.12, 0.16, "poutre"]]:
		for i2 in range(n):
			var a3: float = TAU * (i2 + 0.5) / n
			if absf(wrapf(a3 - door_a, -PI, PI)) < gap and float(ring[0]) < 2.0:
				continue
			var d3 := Vector3(cos(a3), 0, sin(a3))
			k.box(Transform3D(Basis(Vector3.UP, atan2(d3.x, d3.z)), R.P(d3.x * (rc - 0.02), float(ring[0]) + float(ring[1]) * 0.5, d3.z * (rc - 0.02))), Vector3(TAU * rc / n * 1.06, float(ring[1]), 0.06), str(ring[2]), 1.0)
	# le plafond en cône (des pans de planches), les chevrons, la couronne du faîte
	var m: int = 32
	for i3 in range(m):
		var a0: float = TAU * i3 / m
		var a1: float = TAU * (i3 + 1) / m
		var p0 := Vector3(cos(a0) * (rc + 0.06), hw, sin(a0) * (rc + 0.06))
		var p1 := Vector3(cos(a1) * (rc + 0.06), hw, sin(a1) * (rc + 0.06))
		var q0 := Vector3(cos(a0) * 0.22, HC, sin(a0) * 0.22)
		var q1 := Vector3(cos(a1) * 0.22, HC, sin(a1) * 0.22)
		var nrm: Vector3 = (q1 - p0).cross(p1 - p0).normalized()
		if nrm.y > 0.0:
			nrm = -nrm
		k.tri("plafond", R.P(p0.x, p0.y, p0.z), R.P(p1.x, p1.y, p1.z), R.P(q1.x, q1.y, q1.z), nrm, Vector2(0, 0), Vector2(p0.distance_to(p1) / 1.6, 0), Vector2(p0.distance_to(p1) / 1.6 * 0.1, (HC - hw) / 1.0))
		k.tri("plafond", R.P(p0.x, p0.y, p0.z), R.P(q1.x, q1.y, q1.z), R.P(q0.x, q0.y, q0.z), nrm, Vector2(0, 0), Vector2(p0.distance_to(p1) / 1.6 * 0.1, (HC - hw) / 1.0), Vector2(0, (HC - hw) / 1.0))
	for i4 in range(12):
		var a4: float = TAU * (i4 + 0.5) / 12.0
		var lo := Vector3(cos(a4) * (rc - 0.04), hw - 0.02, sin(a4) * (rc - 0.04))
		var hi := Vector3(cos(a4) * 0.28, HC - 0.06, sin(a4) * 0.28)
		var dir: Vector3 = hi - lo
		var yax: Vector3 = dir.normalized()
		var xax: Vector3 = yax.cross(Vector3(cos(a4), 0, sin(a4))).normalized()
		var zax: Vector3 = xax.cross(yax)
		k.box(Transform3D(Basis(xax, yax, zax), R.P((lo.x + hi.x) * 0.5, (lo.y + hi.y) * 0.5 - 0.05, (lo.z + hi.z) * 0.5)), Vector3(0.09, dir.length(), 0.12), "poutre", 1.0)
	k.cyl(R.L(0, HC - 0.32, 0), 0.32, 0.3, 0.32, "poutre", 16)
	k.cyl(R.L(0, HC - 0.5, 0), 0.09, 0.04, 0.2, "poutre", 10)
	k.col_box(R.L(0, HC + 0.3, 0), Vector3(rc * 2.0 + 1.0, 0.4, rc * 2.0 + 1.0))
	# la collision des murs
	for i5 in range(20):
		var a5: float = TAU * (i5 + 0.5) / 20
		var d5 := Vector3(cos(a5), 0, sin(a5))
		k.col_box(Transform3D(Basis(Vector3.UP, atan2(d5.x, d5.z)), R.P(d5.x * (rc + 0.25), 1.4, d5.z * (rc + 0.25))), Vector3(rc * TAU / 20.0 * 1.15, 3.2, 0.4))
	# les fenêtres rondes (comme dehors : de part et d'autre de la porte, et en face)
	for wa in [door_a + 1.65, door_a - 1.65, door_a + PI]:
		var dw := Vector3(cos(wa), 0, sin(wa))
		R.window(Transform3D(Basis(Vector3.UP, atan2(-dw.x, -dw.z)), R.P(dw.x * (rc - 0.01), 1.5, dw.z * (rc - 0.01))), "rond")
		R.kit.box(Transform3D(Basis(Vector3.UP, atan2(-dw.x, -dw.z)), R.P(dw.x * (rc - 0.12), 1.0, dw.z * (rc - 0.12))), Vector3(0.7, 0.05, 0.22), "bois", 1.0)
	# la porte en arc (de l'intérieur) : les planches, le haut arrondi, l'encadrement, la poignée de fer
	var dz: float = rc - 0.03
	k.box(R.L(0, 0.7, dz), Vector3(1.0, 1.4, 0.05), "bois_sombre", 1.0)
	k.cyl(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), R.P(0, 1.4, dz + 0.025)), 0.5, 0.5, 0.05, "bois_sombre", 20)
	for pl in range(4):
		k.box(R.L(-0.375 + pl * 0.25, 0.85, dz - 0.03), Vector3(0.012, 1.7, 0.012), "noir", 1.0)
	for sx in [-1.0, 1.0]:
		k.box(R.L(sx * 0.57, 0.72, dz - 0.02), Vector3(0.12, 1.44, 0.1), "poutre", 1.0)
	for s in range(17):
		var aa: float = PI * s / 16.0
		k.box(Transform3D(Basis(Vector3.BACK, aa - PI * 0.5), R.P(cos(aa) * 0.57, 1.4 + sin(aa) * 0.57, dz - 0.02)), Vector3(0.13, 0.13, 0.1), "poutre", 1.0)
	k.cyl(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), R.P(0.32, 0.95, dz - 0.07)), 0.04, 0.04, 0.05, "fer", 10)
	k.box(R.L(0.32, 0.95, dz - 0.05), Vector3(0.03, 0.12, 0.03), "fer", 1.0)
	# le poêle (du côté de la cheminée, dehors)
	var sa: float = atan2(-0.66, 0.75)
	var sd := Vector3(cos(sa), 0, sin(sa))
	R.foyer(sd.x * (rc - 0.62), sd.z * (rc - 0.62), rad_to_deg(atan2(-sd.x, -sd.z)), true)
	# la lumière : la lanterne au faîte, et le jour par les fenêtres
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.88, 0.7) if not R.day else Color(1.0, 0.96, 0.9)
	l.light_energy = 1.2 if not R.day else 0.95
	l.omni_range = rc * 2.6
	l.omni_attenuation = 0.9
	l.shadow_enabled = R.pc and not M.main.get("xr_active")
	R.root.add_child(l)
	l.global_position = R.P(0, hw + 0.4, 0)
	R.lights.append(l)
	# la lanterne pend du faîte (au-dessus des têtes)
	k.cyl(R.L(0, hw + 0.42, 0), 0.008, 0.008, HC - 0.5 - hw - 0.42, "fer", 4, false)
	k.cyl(R.L(0, hw + 0.16, 0), 0.13, 0.17, 0.2, "papier", 12)
	k.cyl(R.L(0, hw + 0.36, 0), 0.17, 0.08, 0.08, "papier", 12)
	k.cyl(R.L(0, hw + 0.2, 0), 0.04, 0.04, 0.08, "lumiere", 8)
	if R.day:
		var sl := OmniLight3D.new()
		sl.light_color = Color(0.86, 0.92, 1.0)
		sl.light_energy = 0.5
		sl.omni_range = rc * 2.0
		R.root.add_child(sl)
		sl.global_position = R.P(-rc * 0.6, 1.8, -rc * 0.3)
		R.lights.append(sl)


# =================================================================== l'Île Crayonnée : les maisons

static func _crayon(M) -> Node:
	return M.main.get("crayon_v99")


## Les habitants d'un arbre-maison (leur maison : « porte_<id> »).
static func _cr_habitants(M, id: String) -> Array:
	var cr: Node = _crayon(M)
	var out: Array = []
	if cr == null or cr.get("vie") == null or cr.vie == null:
		return out
	for n in cr.vie.habitants:
		if is_instance_valid(n) and n.get("profile") is Dictionary and str((n.profile as Dictionary).get("maison", "")) == "porte_" + id:
			out.append(n)
	return out


## La porte est notée « visitée » (la trouvaille des portes du village, comme quand on frappait).
static func _cr_visite(M, id: String) -> void:
	var cr: Node = _crayon(M)
	if cr != null and cr.get("state") is Dictionary and (cr.state as Dictionary).has("portes"):
		((cr.state as Dictionary)["portes"] as Dictionary)[id] = true


## Un habitant chez lui (le soir) : assis à sa place ; on lui parle.
static func _cr_chez(M, n: Node, x: float, z: float, yaw: float, pose: String) -> Node:
	var p: Dictionary = (n.get("profile") as Dictionary).duplicate(true)
	p["classe"] = "lumen"
	var f: Node = Figurant.spawn(M.room, M.main, p, M.R.P(x, 0, z), Basis(Vector3.UP, deg_to_rad(yaw)) * Vector3(0, 0, 1), pose)
	M.people.append(f)
	return f


## Un point près du mur rond (angle en degrés, 90 = la porte ; r : la distance au centre) et le yaw
## d'un meuble qui regarde le centre.
static func _rond(a_deg: float, r: float) -> Array:
	var a: float = deg_to_rad(a_deg)
	var d := Vector3(cos(a), 0, sin(a))
	return [d.x * r, d.z * r, rad_to_deg(atan2(-d.x, -d.z))]


## Chez les Pinceau, les Gomme, les Buvard : les lits le long du mur, la table ronde, l'armoire, le
## buffet, et ce qui dit le métier de chacun ; le soir, la famille est là ; de jour, un mot sur la table.
static func _cr_maison(M) -> void:
	var R = M.R
	var r := _r(M)
	var id: String = str(M.cur.get("maison_id", "pinceau"))
	var rc: float = R.W * 0.5
	_cr_visite(M, id)
	# la table ronde et ses chaises
	R.table_ronde(0.0, -0.25, 0.55, 0.75)
	var places: Array = []
	for a in [20.0, 140.0, 260.0]:
		var d := Vector3(cos(deg_to_rad(a)), 0, sin(deg_to_rad(a)))
		var px: float = d.x * 0.92
		var pz: float = -0.25 + d.z * 0.92
		var yaw: float = rad_to_deg(atan2(-d.x, -d.z))
		R.chaise(px, pz, yaw, str(_pick(M, ["", "rouge", "jaune", "bleu"])))
		places.append([px, pz, yaw])
	R.kit.cyl(R.L(0.0, 0.75, -0.25), 0.07, 0.06, 0.12, "terre_cuite", 10)
	for k in range(4):
		R.kit.box(R.L(r.randf_range(-0.08, 0.08), 0.92, -0.25 + r.randf_range(-0.06, 0.06), r.randf_range(0, 90)) * Transform3D(Basis(Vector3.RIGHT, r.randf_range(-0.3, 0.3)), Vector3.ZERO), Vector3(0.012, 0.16, 0.012), "feuillage", 1.0)
	# les lits, le long du mur (les deux habitants)
	for e in [[195.0, str(_pick(M, ["rouge", "bleu", "vert"]))], [250.0, str(_pick(M, ["jaune", "rose", "violet"]))]]:
		var a2: float = deg_to_rad(float(e[0]))
		var c := Vector3(cos(a2), 0, sin(a2)) * 2.2 * (rc / 3.0)
		var t := Vector3(-sin(a2), 0, cos(a2))
		R.lit(c.x, c.z, rad_to_deg(atan2(t.x, t.z)), 0.9, str(e[1]))
	# l'armoire, près de la porte ; le buffet et ses bocaux
	var ar: Array = _rond(140.0, rc - 0.36)
	R.armoire(float(ar[0]), float(ar[1]), float(ar[2]), 1.0, 1.9)
	var bu: Array = _rond(296.0, rc - 0.3)
	R.kit.box(R.L(float(bu[0]), 0.45, float(bu[1]), float(bu[2])), Vector3(1.0, 0.9, 0.45), "bois", 1.0)
	R.kit.box(R.L(float(bu[0]), 0.92, float(bu[1]), float(bu[2])), Vector3(1.08, 0.04, 0.5), "bois_sombre", 1.0)
	for k2 in range(4):
		var lb: Transform3D = R.L(float(bu[0]), 0.94, float(bu[1]), float(bu[2])) * Transform3D(Basis(), Vector3(-0.36 + k2 * 0.24, 0, 0))
		R.kit.cyl(lb, 0.06, 0.06, 0.16 + 0.03 * (k2 % 2), "verre", 10)
		R.kit.cyl(lb * Transform3D(Basis(), Vector3(0, 0.16 + 0.03 * (k2 % 2), 0)), 0.065, 0.065, 0.025, "tissu_" + ["rouge", "creme", "vert", "bleu"][k2], 10)
	R.kit.col_box(R.L(float(bu[0]), 0.45, float(bu[1]), float(bu[2])), Vector3(1.0, 0.9, 0.45))
	# ce qui dit le métier de chacun
	match id:
		"pinceau":
			_cr_pinceau(M, rc)
		"gomme":
			_cr_gomme(M, rc)
		"buvard":
			_cr_buvard(M, rc)
	# une affiche, un dessin, au mur
	var dg: Array = _rond(320.0 if id != "pinceau" else 350.0, rc - 0.07)
	_cadre(R, _img(R, "cr_dessin_m", "beau169/cr_dessin.png"), float(dg[0]), 1.6, float(dg[1]), float(dg[2]), 0.62, 0.46)
	# les habitants : le soir chez eux ; de jour, partis chercher les couleurs (un mot)
	var gens: Array = _cr_habitants(M, id)
	var la: Array = []
	for n in gens:
		if bool(n.get("hidden_home")):
			la.append(n)
	var cr: Node = _crayon(M)
	if gens.is_empty():
		var mot: String = str(cr.MOTS.get(id, "Personne.")) if cr != null else "Personne."
		S._mot(M, 0.15, -0.25, 0.76, mot.replace("Toc toc… ", ""), "E : lire le mot sur la table")
		M.ctx["entree"] = "La maison des %s. Il n'y a personne : sur la table, un petit mot." % id.capitalize()
	elif la.is_empty():
		var ou: String = str(cr.OU.get(id, "")) if cr != null else ""
		S._mot(M, 0.15, -0.25, 0.76, "Un mot sur la table : « Partis chercher les couleurs ! Le pot de soupe est sur le poêle. » " + ou, "E : lire le mot sur la table")
		M.ctx["entree"] = "La maison des %s. Personne : de jour, tout le monde cherche les pots de couleur." % id.capitalize()
	else:
		for i in range(la.size()):
			var pl: Array = places[i % places.size()]
			var f: Node = _cr_chez(M, la[i], float(pl[0]), float(pl[1]), float(pl[2]), "assis")
			_cr_parle(M, f, id)
		M.ctx["entree"] = "Chez les %s. Il fait bon, le poêle ronronne." % id.capitalize()


## Ce que dit un habitant chez lui (et le petit cadeau, une fois).
static func _cr_parle(M, f: Node, id: String) -> void:
	var cr: Node = _crayon(M)
	var parle := func() -> void:
		var n: int = cr.vie.nb_pots() if cr != null and cr.get("vie") != null and cr.vie != null else 0
		var t: String = "Oh, de la visite ! Entre, entre. Il fait meilleur ici que dehors. "
		if n >= 9:
			t += "Tu as vu ? Toute l'île a retrouvé ses couleurs. Grâce à toi !"
		elif n > 0:
			t += "Déjà %d pots sur neuf dans la Palette… On y croit !" % n
		else:
			t += "Tu nous aideras à retrouver nos couleurs, dis ?"
		M.talk(f, t, [{"id": "maison", "label": "Elle est jolie, ta maison ronde !"}, {"id": "fermer", "label": "Bonne soirée !"}], func(cid):
			if cid == "maison" and not bool(M.state().get("cadeau_cr", false)):
				M.state()["cadeau_cr"] = true
				M.talk(f, "Merci ! C'est le Grand-Chêne qui la porte, depuis cent ans. Tiens, un peu de pain au miel pour la route.", [{"id": "fermer", "label": "Merci !"}], func(_i):
					M.give([["pain_miel", 1]], "")
					M.close_talk())
			else:
				M.close_talk())
	M.talk_spot(f, parle)


## Chez les Pinceau : les pots de peinture, les pinceaux dans leur bocal, l'échelle, la bâche tachée,
## le chevalet de Lili et son dessin.
static func _cr_pinceau(M, rc: float) -> void:
	var R = M.R
	var r := _r(M)
	var p: Array = _rond(40.0, rc - 0.45)
	var X: Transform3D = R.L(float(p[0]), 0, float(p[1]), float(p[2]))
	R.kit.box(X * Transform3D(Basis(), Vector3(0, 0.006, 0.15)), Vector3(1.2, 0.012, 0.9), "drap", 1.0, 4)
	for k in range(6):
		var q := Vector3(-0.4 + (k % 3) * 0.32, 0.0, (k / 3) * 0.32)
		var h: float = 0.22 if k < 3 else 0.18
		R.kit.cyl(X * Transform3D(Basis(), q), 0.12, 0.12, h, "metal", 12)
		R.kit.cyl(X * Transform3D(Basis(), q + Vector3.UP * h), 0.11, 0.11, 0.01, "tissu_" + ["rouge", "bleu", "jaune", "vert", "orange", "violet"][k], 12)
	R.kit.cyl(X * Transform3D(Basis(), Vector3(0.45, 0.0, 0.5)), 0.07, 0.06, 0.18, "verre", 10)
	for k2 in range(5):
		R.kit.box(X * Transform3D(Basis(Vector3.BACK, r.randf_range(-0.25, 0.25)), Vector3(0.45 + r.randf_range(-0.03, 0.03), 0.25, 0.5)), Vector3(0.015, 0.3, 0.015), "bois_clair", 1.0)
	R.reserve(float(p[0]), float(p[1]), 1.3, 1.3)
	var e: Array = _rond(60.0, rc - 0.25)
	R.echelle(float(e[0]), float(e[1]), float(e[2]) + 180.0, 2.3)
	# le chevalet de Lili
	var c: Array = _rond(118.0, rc - 0.8)
	var C: Transform3D = R.L(float(c[0]), 0, float(c[1]), float(c[2]))
	for sx in [-0.25, 0.25]:
		R.kit.box(C * Transform3D(Basis(Vector3.RIGHT, -0.12), Vector3(sx, 0.7, 0.0)), Vector3(0.04, 1.45, 0.04), "bois_clair", 1.0)
	R.kit.box(C * Transform3D(Basis(Vector3.RIGHT, 0.4), Vector3(0, 0.6, -0.3)), Vector3(0.04, 1.3, 0.04), "bois_clair", 1.0)
	R.kit.box(C * Transform3D(Basis(), Vector3(0, 0.62, 0.06)), Vector3(0.7, 0.04, 0.08), "bois_clair", 1.0)
	R.kit.quad(C * Transform3D(Basis(Vector3.UP, PI) * Basis(Vector3.RIGHT, 0.12), Vector3(0, 1.0, 0.04)), 0.62, 0.48, _img(R, "cr_lili", "beau169/cr_dessin.png"), Vector2(0, 0), Vector2(1, 1), true)
	R.reserve(float(c[0]), float(c[1]), 0.8, 0.8)


## Chez les Gomme : les semis de Rosalie (les terrines, l'arrosoir), le pupitre de Papi Augustin (son
## ardoise, le boulier), et une gomme grosse comme un pain.
static func _cr_gomme(M, rc: float) -> void:
	var R = M.R
	var p: Array = _rond(40.0, rc - 0.5)
	var X: Transform3D = R.L(float(p[0]), 0, float(p[1]), float(p[2]))
	R.kit.box(X * Transform3D(Basis(), Vector3(0, 0.7, 0)), Vector3(1.1, 0.04, 0.5), "bois", 1.0)
	for sx in [-0.5, 0.5]:
		R.kit.box(X * Transform3D(Basis(), Vector3(sx, 0.35, 0)), Vector3(0.05, 0.7, 0.45), "bois_sombre", 1.0)
	for k in range(3):
		var tx: Transform3D = X * Transform3D(Basis(), Vector3(-0.34 + k * 0.34, 0.72, 0))
		R.kit.box(tx * Transform3D(Basis(), Vector3(0, 0.04, 0)), Vector3(0.3, 0.08, 0.36), "terre_cuite", 1.0)
		R.kit.box(tx * Transform3D(Basis(), Vector3(0, 0.081, 0)), Vector3(0.27, 0.005, 0.33), "terreau", 1.0, 4)
		for s in range(9):
			R.kit.box(tx * Transform3D(Basis(Vector3.UP, s * 0.7), Vector3(-0.09 + (s % 3) * 0.09, 0.11, -0.1 + (s / 3) * 0.1)), Vector3(0.03, 0.06, 0.004), "feuillage", 1.0)
	R.kit.cyl(X * Transform3D(Basis(), Vector3(0.6, 0, 0.3)), 0.13, 0.11, 0.26, "cuivre", 12)
	R.kit.cyl(X * Transform3D(Basis(Vector3.BACK, -0.9), Vector3(0.72, 0.2, 0.3)), 0.02, 0.012, 0.32, "cuivre", 8)
	R.reserve(float(p[0]), float(p[1]), 1.3, 0.8)
	# le pupitre et l'ardoise
	var d: Array = _rond(118.0, rc - 0.7)
	var D: Transform3D = R.L(float(d[0]), 0, float(d[1]), float(d[2]))
	R.kit.box(D * Transform3D(Basis(Vector3.RIGHT, 0.18), Vector3(0, 0.72, 0)), Vector3(0.7, 0.04, 0.45), "bois", 1.0)
	R.kit.box(D * Transform3D(Basis(), Vector3(0, 0.35, -0.05)), Vector3(0.62, 0.7, 0.3), "bois_sombre", 1.0)
	R.kit.box(D * Transform3D(Basis(Vector3.RIGHT, 0.18), Vector3(-0.08, 0.755, 0.02)), Vector3(0.34, 0.012, 0.24), "noir", 1.0)
	for k3 in range(4):
		R.kit.box(D * Transform3D(Basis(Vector3.RIGHT, 0.18), Vector3(-0.2 + k3 * 0.07, 0.763, 0.0)), Vector3(0.04, 0.004, 0.006), "papier", 1.0)
	_couleur(R, "gomme_rose", Color(0.92, 0.62, 0.66), 0.85)
	R.kit.box(D * Transform3D(Basis(Vector3.UP, 0.4), Vector3(0.22, 0.76, -0.05)), Vector3(0.2, 0.08, 0.12), "gomme_rose", 1.0)
	R.chaise(float(d[0]) * 0.72, float(d[1]) * 0.72, float(d[2]) + 180.0)
	R.reserve(float(d[0]), float(d[1]), 0.9, 0.9)


## Chez les Buvard : les seaux de fleurs de Capucine, les bouquets qui sèchent ; l'écritoire
## d'Achille (l'encrier, la plume, les feuilles, les boulettes de papier froissé par terre).
static func _cr_buvard(M, rc: float) -> void:
	var R = M.R
	var r := _r(M)
	for k in range(3):
		var p: Array = _rond(28.0 + k * 16.0, rc - 0.42)
		R.kit.cyl(R.L(float(p[0]), 0, float(p[1])), 0.16, 0.13, 0.32, "metal", 12)
		for f in range(7):
			var fp := Vector3(float(p[0]) + r.randf_range(-0.1, 0.1), 0.32 + r.randf_range(0.15, 0.4), float(p[1]) + r.randf_range(-0.1, 0.1))
			R.kit.box(R.L(fp.x, (fp.y + 0.3) * 0.5, fp.z, r.randf_range(0, 90)), Vector3(0.012, fp.y - 0.3, 0.012), "feuillage", 1.0)
			_boule(R.root, R.mat("tissu_" + str(["rouge", "jaune", "rose", "violet", "orange"][(f + k) % 5])), R.P(fp.x, fp.y, fp.z), 0.045)
		R.reserve(float(p[0]), float(p[1]), 0.45, 0.45)
	# des bouquets qui sèchent, la tête en bas, sous les chevrons
	for k2 in range(4):
		var b: Array = _rond(170.0 + k2 * 22.0, rc - 0.7)
		R.kit.cyl(R.L(float(b[0]), 2.05, float(b[1])), 0.006, 0.006, 0.45, "fer", 4, false)
		R.kit.cyl(R.L(float(b[0]), 1.78, float(b[1])), 0.02, 0.09, 0.28, "feuillage", 8)
	# l'écritoire
	var d: Array = _rond(120.0, rc - 0.55)
	var D: Transform3D = R.L(float(d[0]), 0, float(d[1]), float(d[2]))
	R.kit.box(D * Transform3D(Basis(), Vector3(0, 0.74, 0)), Vector3(0.9, 0.04, 0.5), "bois", 1.0)
	for sx in [-0.4, 0.4]:
		R.kit.box(D * Transform3D(Basis(), Vector3(sx, 0.37, 0)), Vector3(0.04, 0.74, 0.46), "bois_sombre", 1.0)
	R.kit.cyl(D * Transform3D(Basis(), Vector3(0.28, 0.76, -0.1)), 0.04, 0.045, 0.06, "noir", 10)
	R.kit.box(D * Transform3D(Basis(Vector3.BACK, 0.4), Vector3(0.3, 0.88, -0.1)), Vector3(0.006, 0.24, 0.025), "drap", 1.0)
	for k3 in range(4):
		R.kit.box(D * Transform3D(Basis(Vector3.UP, r.randf_range(-0.3, 0.3)), Vector3(-0.1 + r.randf_range(-0.05, 0.05), 0.762 + k3 * 0.003, 0.02)), Vector3(0.21, 0.003, 0.29), "papier", 1.0, 4)
	R.chaise(float(d[0]) * 0.74, float(d[1]) * 0.74, float(d[2]) + 180.0)
	for k4 in range(5):
		_boule(R.root, R.mat("papier"), R.P(float(d[0]) * 0.8 + r.randf_range(-0.5, 0.5), 0.04, float(d[1]) * 0.8 + r.randf_range(-0.4, 0.4)), 0.045, Vector3(1, 0.85, 1.1))
	R.reserve(float(d[0]), float(d[1]), 1.0, 0.9)


## La Maison du Conseil : la grande table ronde et ses neuf chaises (une par godet), la carte de l'île
## où brillent les godets déjà retrouvés, l'affiche « Où sont passées nos couleurs ? », le fauteuil à
## bascule de Grand-Mère Aquarelle, la cloche du Conseil, le lutrin et le Grand Livre.
static func _cr_conseil(M) -> void:
	var R = M.R
	var rc: float = R.W * 0.5
	_cr_visite(M, "grand")
	var cr: Node = _crayon(M)
	var vie: Node = cr.vie if cr != null and cr.get("vie") != null else null
	var poured: Dictionary = vie.poured() if vie != null else {}
	# la table et les neuf chaises
	var tz: float = -0.15
	R.table_ronde(0.0, tz, 1.2, 0.76)
	R.kit.ring(R.L(0.0, 0.7, tz), 1.16, 1.22, 0.06, "bois_sombre", 40)
	for i in range(9):
		var a: float = TAU * (i + 0.5) / 9.0 + PI * 0.5
		var d := Vector3(cos(a), 0, sin(a))
		R.chaise(d.x * 1.62, tz + d.z * 1.62, rad_to_deg(atan2(-d.x, -d.z)), "")
	# la carte de l'île, ses neuf godets (de la vraie couleur, s'ils sont retrouvés)
	var carte: String = _img(R, "cr_carte", "beau169/cr_carte.png")
	R.kit.cyl(R.L(0.0, 0.761, tz), 0.92, 0.92, 0.006, carte, 40)
	var Vie = load("res://scripts/crayon_vie_v101.gd")
	var cup := CylinderMesh.new()
	cup.top_radius = 0.05
	cup.bottom_radius = 0.042
	cup.height = 0.035
	cup.radial_segments = 14
	for c in Vie.ORDRE:
		var e: Array = Vie.POTS[c]
		var reg: Array = e[3]
		var p := Vector2(float(reg[0]), float(reg[1])) / 190.0 * 0.85
		var mi := MeshInstance3D.new()
		mi.name = "Godet_v169_" + str(c)
		mi.mesh = cup
		var m := StandardMaterial3D.new()
		m.albedo_color = (e[2] as Color) if poured.has(c) else Color(0.95, 0.94, 0.9)
		m.roughness = 0.35
		if poured.has(c):
			m.emission_enabled = true
			m.emission = (e[2] as Color) * 0.35
			mi.set_meta("crayon_non", true)
		mi.material_override = m
		R.root.add_child(mi)
		mi.global_position = R.P(p.x, 0.782, tz + p.y)
	var regarder := func() -> void:
		var vu: Array = []
		var reste: Array = []
		for c2 in Vie.ORDRE:
			if poured.has(c2):
				vu.append(str(Vie.POTS[c2][1]))
			else:
				reste.append("%s (%s)" % [str(Vie.POTS[c2][1]), str(Vie.POTS[c2][4])])
		if reste.is_empty():
			M.say("La carte du Conseil : les neuf godets brillent de toutes leurs couleurs. Quelqu'un a écrit en grand, à l'encre : « MERCI ! »", 7.0)
		elif vu.is_empty():
			M.say("La carte de l'île, dessinée à l'encre, et neuf godets tout blancs posés dessus, chacun à sa place : " + ", ".join(reste) + ".", 10.0)
		else:
			M.say("La carte du Conseil : %d godets sur 9 ont retrouvé leur couleur (%s). Il manque encore : %s." % [vu.size(), ", ".join(vu), ", ".join(reste)], 10.0)
	M.act(R.P(0.0, 0, tz + 1.35), "E : regarder la carte du Conseil", regarder, 1.3)
	# l'affiche, au mur
	var af: Array = _rond(270.0, rc - 0.07)
	_cadre(R, _img(R, "cr_affiche_c", "beau169/cr_affiche.png"), float(af[0]), 1.55, float(af[1]), float(af[2]), 0.62, 0.86)
	# le fauteuil à bascule de Grand-Mère Aquarelle, près du poêle
	var fa: Array = _rond(345.0, rc - 0.9)
	R.fauteuil(float(fa[0]), float(fa[1]), float(fa[2]), "violet")
	for sx in [-0.38, 0.38]:
		R.kit.box(R.L(float(fa[0]), 0.03, float(fa[1]), float(fa[2])) * Transform3D(Basis(), Vector3(sx, 0, 0)), Vector3(0.04, 0.05, 0.95), "bois_sombre", 1.0)
	# la cloche du Conseil, sur son pied ; le lutrin et le Grand Livre
	var cl: Array = _rond(45.0, rc - 0.55)
	var CL: Transform3D = R.L(float(cl[0]), 0, float(cl[1]), float(cl[2]))
	for sx2 in [-0.25, 0.25]:
		R.kit.box(CL * Transform3D(Basis(), Vector3(sx2, 0.6, 0)), Vector3(0.05, 1.2, 0.05), "bois_sombre", 1.0)
	R.kit.box(CL * Transform3D(Basis(), Vector3(0, 1.2, 0)), Vector3(0.6, 0.06, 0.06), "bois_sombre", 1.0)
	R.kit.cyl(CL * Transform3D(Basis(), Vector3(0, 0.88, 0)), 0.17, 0.08, 0.28, "or", 16)
	R.kit.cyl(CL * Transform3D(Basis(), Vector3(0, 1.16, 0)), 0.03, 0.03, 0.04, "or", 8)
	R.reserve(float(cl[0]), float(cl[1]), 0.8, 0.6)
	var sonner := func() -> void:
		M.main.sfx("cloche", R.P(float(cl[0]), 1.0, float(cl[1])))
		if cr != null and bool(cr.state.get("fete", false)):
			M.say("DING ! Au-dehors, tout le village répond par des hourras. Ce soir, on fait la fête dans les couleurs !", 6.0)
		else:
			M.say("DING ! … Personne ne vient : tout le village est parti chercher les couleurs. (On ne sonne la cloche du Conseil que pour les grandes nouvelles.)", 6.0)
	M.act(CL * Vector3(0, 0, 0.9), "E : sonner la cloche du Conseil", sonner, 1.2)
	var lu: Array = _rond(135.0, rc - 0.6)
	var LU: Transform3D = R.L(float(lu[0]), 0, float(lu[1]), float(lu[2]))
	R.kit.cyl(LU, 0.2, 0.16, 0.04, "bois_sombre", 12)
	R.kit.cyl(LU * Transform3D(Basis(), Vector3(0, 0.04, 0)), 0.04, 0.04, 1.0, "bois_sombre", 10)
	R.kit.box(LU * Transform3D(Basis(Vector3.RIGHT, 0.45), Vector3(0, 1.1, 0)), Vector3(0.55, 0.03, 0.4), "bois", 1.0)
	R.kit.box(LU * Transform3D(Basis(Vector3.RIGHT, 0.45), Vector3(0, 1.13, 0.0)), Vector3(0.5, 0.04, 0.34), "papier", 1.0)
	R.kit.box(LU * Transform3D(Basis(Vector3.RIGHT, 0.45), Vector3(0, 1.152, 0.0)), Vector3(0.012, 0.012, 0.34), "tissu_rouge", 1.0)
	R.reserve(float(lu[0]), float(lu[1]), 0.6, 0.6)
	S._mot(M, float(lu[0]) * 0.97, float(lu[1]) * 0.97, 1.16, "Le Grand Livre du Conseil, à la dernière page : « Ce matin, toutes les couleurs de l'île ont disparu d'un coup, comme on efface un dessin. Décidé à l'unanimité : chacun cherche partout, et l'on rapporte les pots à la Palette. »", "E : lire le Grand Livre")
	# Grand-Mère Aquarelle et Gaspard, le soir
	var gens: Array = _cr_habitants(M, "grand")
	var k: int = 0
	for n in gens:
		if bool(n.get("hidden_home")):
			var pl: Array = [float(fa[0]), float(fa[1]), float(fa[2])] if k == 0 else _rond(230.0, 1.62)
			var f: Node = _cr_chez(M, n, float(pl[0]), float(pl[1]), float(pl[2]), "assis")
			_cr_parle(M, f, "grand")
			k += 1
	M.ctx["entree"] = "La Maison du Conseil. Une grande table ronde, neuf chaises, et sur la table, la carte de l'île avec ses neuf godets."


# =================================================================== Al Dente : chez chacun

## Ce qui dit le métier de chacun, chez lui (le Borgo ; la Barque-Maison du Capitaine).
static func touches(M) -> void:
	var st: String = str(M.ctx.get("style", ""))
	var ow: String = str(M.ctx.get("owner", ""))
	if ow == "" and M.cur.has("owner"):
		ow = str(M.cur["owner"])
	if not (st == "pasta" or (st == "pirate" and ow == "rigatoni")):
		return
	match ow:
		"lasagna", "tortellini", "gnocchi":
			_pa_pates(M)
		"farfalle":
			_pa_autel(M)
		"penne", "tagliatelle":
			_pa_musique(M)
		"ravioli", "linguini":
			_pa_tomates(M)
		"fusilli":
			_pa_savante(M)
		"macaroni":
			_pa_gong(M)
		"rigatoni":
			_pa_capitaine(M)


## Une place libre contre un mur pour un meuble (sx le long du mur, sz en profondeur) : [x, z, yaw]
## (yaw comme R.tableau : 0 au fond, 90 à gauche, -90 à droite) ; [] s'il n'y en a pas.
static func _place(M, sx: float, sz: float) -> Array:
	var R = M.R
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var cands: Array = []
	for i in range(7):
		cands.append([-hw + sx * 0.5 + 0.15 + i * maxf(R.W - sx - 0.3, 0.0) / 6.0, -hd + sz * 0.5 + 0.08, 0.0])
	for j in range(5):
		var z: float = -hd + sx * 0.5 + 0.3 + j * maxf(R.D - sx - 1.9, 0.0) / 4.0
		cands.append([-hw + sz * 0.5 + 0.08, z, 90.0])
		cands.append([hw - sz * 0.5 - 0.08, z, -90.0])
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(M.ctx.get("id", "")) + "touches%d" % int(sx * 10.0))
	for i2 in range(cands.size() - 1, 0, -1):
		var j2: int = rng.randi() % (i2 + 1)
		var t: Variant = cands[i2]
		cands[i2] = cands[j2]
		cands[j2] = t
	for c in cands:
		var along: bool = absf(float(c[2])) < 1.0
		if R.is_free(float(c[0]), float(c[1]), sx if along else sz, sz if along else sx):
			R.reserve(float(c[0]), float(c[1]), sx if along else sz, sz if along else sx)
			return c
	return []


## Le mur derrière un meuble posé par _place (le point du mur, pour y accrocher quelque chose).
static func _mur_de(M, c: Array) -> Vector2:
	var R = M.R
	match int(round(float(c[2]))):
		0:
			return Vector2(float(c[0]), -R.D * 0.5 + 0.02)
		90:
			return Vector2(-R.W * 0.5 + 0.02, float(c[1]))
		_:
			return Vector2(R.W * 0.5 - 0.02, float(c[1]))


## Mamma Lasagna : la table à pâtes (la fontaine de farine, l'œuf dans son puits, la pâte étalée, le
## rouleau), et le séchoir où pendent les tagliatelles.
static func _pa_pates(M) -> void:
	var R = M.R
	var r := _r(M)
	var c: Array = _place(M, 2.4, 0.85)
	if c.is_empty():
		return
	var X: Transform3D = R.L(float(c[0]), 0, float(c[1]), float(c[2]))
	R.kit.box(X * Transform3D(Basis(), Vector3(-0.4, 0.85, 0)), Vector3(1.4, 0.06, 0.75), "bois_clair", 1.0)
	for sx in [-1.0, 0.2]:
		for sz in [-0.3, 0.3]:
			R.kit.box(X * Transform3D(Basis(), Vector3(sx, 0.41, sz)), Vector3(0.07, 0.82, 0.07), "bois_sombre", 1.0)
	R.kit.col_box(X * Transform3D(Basis(), Vector3(-0.4, 0.44, 0)), Vector3(1.4, 0.88, 0.75))
	R.kit.cyl(X * Transform3D(Basis(), Vector3(-0.75, 0.88, 0.05)), 0.2, 0.05, 0.09, "papier", 16)
	R.kit.cyl(X * Transform3D(Basis(), Vector3(-0.75, 0.955, 0.05)), 0.045, 0.04, 0.015, "fromage", 10)
	R.kit.box(X * Transform3D(Basis(Vector3.UP, 0.15), Vector3(-0.25, 0.885, 0.05)), Vector3(0.52, 0.008, 0.36), "fromage", 1.0)
	R.kit.cyl(X * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(0.0, 0.92, -0.22)), 0.032, 0.032, 0.5, "bois_clair", 10)
	for k in range(3):
		var e: MeshInstance3D = _boule(R.root, R.mat("ceramique"), X * Vector3(-0.98 + k * 0.08, 0.91, -0.22), 0.028, Vector3(1, 1.25, 1))
		e.rotation.z = 0.2
	# le séchoir
	var S0: Transform3D = X * Transform3D(Basis(), Vector3(0.7, 0, 0))
	for sx2 in [-0.42, 0.42]:
		for sz2 in [-0.2, 0.2]:
			R.kit.box(S0 * Transform3D(Basis(Vector3.RIGHT, -signf(sz2) * 0.2), Vector3(sx2, 0.72, sz2 * 0.5)), Vector3(0.04, 1.48, 0.04), "bois", 1.0)
	for by in [1.4, 1.05]:
		R.kit.cyl(S0 * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(0.45, by, 0)), 0.015, 0.015, 0.9, "bois_clair", 8)
		for k2 in range(16):
			var x: float = -0.38 + k2 * 0.05
			var l: float = r.randf_range(0.28, 0.42) * (1.0 if by > 1.2 else 0.8)
			for sz3 in [-0.02, 0.02]:
				R.kit.box(S0 * Transform3D(Basis(Vector3.RIGHT, sz3 * 4.0), Vector3(x + r.randf_range(-0.01, 0.01), by - l * 0.5, sz3)), Vector3(0.012, l, 0.003), "fromage", 1.0)
	R.kit.col_box(S0 * Transform3D(Basis(), Vector3(0, 0.75, 0)), Vector3(0.9, 1.5, 0.5))


## Le Père Farfalle : un petit autel (la nappe blanche, la passoire sacrée sur son coussin, deux
## bougies, deux boulettes de bois doré) et, au-dessus, l'icône du Grand Spaghetti Volant.
static func _pa_autel(M) -> void:
	var R = M.R
	var c: Array = _place(M, 1.3, 0.6)
	if c.is_empty():
		return
	var X: Transform3D = R.L(float(c[0]), 0, float(c[1]), float(c[2]))
	R.kit.box(X * Transform3D(Basis(), Vector3(0, 0.45, 0)), Vector3(1.2, 0.9, 0.5), "bois_sombre", 1.0)
	R.kit.box(X * Transform3D(Basis(), Vector3(0, 0.905, 0)), Vector3(1.3, 0.012, 0.56), "drap", 1.0)
	R.kit.box(X * Transform3D(Basis(), Vector3(0, 0.7, 0.285)), Vector3(1.3, 0.42, 0.01), "drap", 1.0)
	R.kit.col_box(X * Transform3D(Basis(), Vector3(0, 0.45, 0)), Vector3(1.2, 0.9, 0.5))
	R.kit.box(X * Transform3D(Basis(), Vector3(0, 0.95, 0)), Vector3(0.36, 0.08, 0.3), "tissu_rouge", 1.0)
	R.kit.cyl(X * Transform3D(Basis(), Vector3(0, 0.99, 0)), 0.15, 0.08, 0.12, "argent", 18)
	R.kit.ring(X * Transform3D(Basis(), Vector3(0, 0.99, 0)), 0.15, 0.18, 0.015, "argent", 18)
	for k in range(10):
		var a: float = TAU * k / 10.0
		R.kit.box(X * Transform3D(Basis(Vector3.UP, -a) * Basis(Vector3.RIGHT, 0.55), Vector3(cos(a) * 0.118, 1.05, sin(a) * 0.118)), Vector3(0.018, 0.018, 0.004), "noir", 1.0)
	for sx in [-0.45, 0.45]:
		R.kit.cyl(X * Transform3D(Basis(), Vector3(sx, 0.91, 0)), 0.05, 0.04, 0.05, "or", 10)
		R.bougie(float(c[0]) + (X.basis * Vector3(sx, 0, 0)).x, 0.96, float(c[1]) + (X.basis * Vector3(sx, 0, 0)).z, true)
	for sx2 in [-0.25, 0.25]:
		_boule(R.root, R.mat("or"), X * Vector3(sx2, 0.96, 0.12), 0.04)
	var w: Vector2 = _mur_de(M, c)
	_cadre(R, _img(R, "pa_icone_c", "beau169/pa_icone.png"), w.x, 1.75, w.y, float(c[2]), 0.56, 0.75, "or")


## Sœur Penne et Tagliatelle : les pupitres de la chorale (les partitions), le violon sur sa chaise,
## le chevalet et la bannière vert-blanc-rouge en train d'être peinte, les pots de peinture.
static func _pa_musique(M) -> void:
	var R = M.R
	var c: Array = _place(M, 2.0, 0.8)
	if c.is_empty():
		return
	var X: Transform3D = R.L(float(c[0]), 0, float(c[1]), float(c[2]))
	for sx in [-0.7, -0.15]:
		var P0: Transform3D = X * Transform3D(Basis(), Vector3(sx, 0, 0.1))
		R.kit.cyl(P0, 0.16, 0.12, 0.02, "fer", 10)
		R.kit.cyl(P0, 0.012, 0.012, 1.1, "fer", 6)
		R.kit.box(P0 * Transform3D(Basis(Vector3.RIGHT, -0.45), Vector3(0, 1.15, 0.0)), Vector3(0.45, 0.32, 0.01), "noir", 1.0)
		R.kit.box(P0 * Transform3D(Basis(Vector3.RIGHT, -0.45), Vector3(0, 1.16, 0.012)), Vector3(0.38, 0.26, 0.003), "papier", 1.0)
	# le chevalet et la bannière
	var C: Transform3D = X * Transform3D(Basis(), Vector3(0.6, 0, 0))
	for sx2 in [-0.3, 0.3]:
		R.kit.box(C * Transform3D(Basis(Vector3.RIGHT, -0.1), Vector3(sx2, 0.85, 0.05)), Vector3(0.05, 1.75, 0.05), "bois", 1.0)
	R.kit.box(C * Transform3D(Basis(Vector3.RIGHT, 0.35), Vector3(0, 0.75, -0.25)), Vector3(0.05, 1.55, 0.05), "bois", 1.0)
	R.kit.box(C * Transform3D(Basis(), Vector3(0, 0.62, 0.1)), Vector3(0.8, 0.04, 0.1), "bois", 1.0)
	for k in range(3):
		R.kit.box(C * Transform3D(Basis(Vector3.RIGHT, -0.1), Vector3(-0.22 + k * 0.22, 1.12, 0.1)), Vector3(0.22, 0.95, 0.01), ["tissu_vert", "tissu_blanc", "tissu_rouge"][k], 1.0)
	for k2 in range(3):
		R.kit.cyl(C * Transform3D(Basis(), Vector3(-0.3 + k2 * 0.18, 0.0, 0.42)), 0.07, 0.07, 0.12, "metal", 10)
		R.kit.cyl(C * Transform3D(Basis(), Vector3(-0.3 + k2 * 0.18, 0.12, 0.42)), 0.065, 0.065, 0.005, ["tissu_vert", "tissu_blanc", "tissu_rouge"][k2], 10)


## Ravioli et Linguini : les cagettes de tomates de la Tomateraie, les terrines de semis, l'arrosoir,
## le balai du parvis.
static func _pa_tomates(M) -> void:
	var R = M.R
	var r := _r(M)
	var c: Array = _place(M, 1.8, 0.7)
	if c.is_empty():
		return
	var X: Transform3D = R.L(float(c[0]), 0, float(c[1]), float(c[2]))
	var rouge: Material = R.mat("pomme")
	for k in range(2):
		var cx: float = -0.5 + k * 0.62
		var B: Transform3D = X * Transform3D(Basis(Vector3.UP, r.randf_range(-0.1, 0.1)), Vector3(cx, 0, 0))
		for sx in [-0.27, 0.27]:
			R.kit.box(B * Transform3D(Basis(), Vector3(sx, 0.14, 0)), Vector3(0.02, 0.28, 0.4), "bois_clair", 1.0)
		for sz in [-0.19, 0.19]:
			for y in [0.06, 0.2]:
				R.kit.box(B * Transform3D(Basis(), Vector3(0, y, sz)), Vector3(0.56, 0.07, 0.015), "bois_clair", 1.0)
		R.kit.box(B * Transform3D(Basis(), Vector3(0, 0.02, 0)), Vector3(0.56, 0.02, 0.4), "bois_clair", 1.0)
		for t in range(12):
			var tp: Vector3 = B * Vector3(-0.2 + (t % 4) * 0.13 + r.randf_range(-0.02, 0.02), 0.25 + (t / 8) * 0.07, -0.12 + ((t / 4) % 2) * 0.13 + r.randf_range(-0.02, 0.02))
			_boule(R.root, rouge, tp, 0.058, Vector3(1, 0.85, 1))
	R.kit.cyl(X * Transform3D(Basis(), Vector3(0.62, 0, 0.1)), 0.13, 0.11, 0.26, "cuivre", 12)
	R.kit.cyl(X * Transform3D(Basis(Vector3.BACK, -0.9), Vector3(0.74, 0.2, 0.1)), 0.02, 0.012, 0.32, "cuivre", 8)
	R.kit.box(X * Transform3D(Basis(Vector3.BACK, 0.2), Vector3(0.82, 0.75, -0.2)), Vector3(0.03, 1.5, 0.03), "bois_clair", 1.0)
	R.kit.box(X * Transform3D(Basis(Vector3.BACK, 0.2), Vector3(0.66, 0.08, -0.2)), Vector3(0.26, 0.22, 0.06), "pain", 1.0)


## La Professeure Fusilli : le tableau noir couvert de spirales (la théologie de la pâte en
## tire-bouchon), le lutrin, les piles de livres.
static func _pa_savante(M) -> void:
	var R = M.R
	var c: Array = _place(M, 1.8, 0.6)
	if c.is_empty():
		return
	var X: Transform3D = R.L(float(c[0]), 0, float(c[1]), float(c[2]))
	R.kit.box(X * Transform3D(Basis(), Vector3(0, 1.45, -0.2)), Vector3(1.5, 1.0, 0.04), "noir", 1.0)
	for sx in [-0.78, 0.78]:
		R.kit.box(X * Transform3D(Basis(), Vector3(sx, 1.45, -0.18)), Vector3(0.06, 1.1, 0.06), "bois", 1.0)
	for sy in [0.92, 1.98]:
		R.kit.box(X * Transform3D(Basis(), Vector3(0, sy, -0.18)), Vector3(1.62, 0.06, 0.06), "bois", 1.0)
	R.kit.box(X * Transform3D(Basis(), Vector3(0, 0.93, -0.12)), Vector3(1.4, 0.03, 0.1), "bois", 1.0)
	for sp in range(2):
		var cx: float = -0.38 + sp * 0.72
		var prev := Vector2(cx, 1.45)
		for k in range(1, 34):
			var a: float = k * 0.42
			var rr: float = 0.02 + k * 0.0085
			var q := Vector2(cx + cos(a) * rr, 1.45 + sin(a) * rr)
			var d: Vector2 = q - prev
			R.kit.box(X * Transform3D(Basis(Vector3.BACK, atan2(d.y, d.x)), Vector3((prev.x + q.x) * 0.5, (prev.y + q.y) * 0.5, -0.176)), Vector3(d.length() + 0.004, 0.008, 0.003), "papier", 1.0)
			prev = q
	R.mark_wall((_mur_de(M, c)).x, 1.6, (_mur_de(M, c)).y, 0.85)
	var b: Vector3 = R.xf0.affine_inverse() * (X * Vector3(0.55, 0, 0.25))
	R.pile(b.x, b.z, "livres", 6)
	var b2: Vector3 = R.xf0.affine_inverse() * (X * Vector3(-0.6, 0, 0.3))
	R.pile(b2.x, b2.z, "livres", 4)


## Macaroni, gardien du Couvercle Sacré : son gong d'entraînement (un couvercle de marmite dans son
## cadre), la mailloche, le tambour, et sa passoire-casque accrochée au portemanteau.
static func _pa_gong(M) -> void:
	var R = M.R
	var c: Array = _place(M, 1.6, 0.6)
	if c.is_empty():
		return
	var X: Transform3D = R.L(float(c[0]), 0, float(c[1]), float(c[2]))
	for sx in [-0.6, 0.6]:
		R.kit.box(X * Transform3D(Basis(), Vector3(sx, 0.8, 0)), Vector3(0.08, 1.6, 0.08), "bois_sombre", 1.0)
		R.kit.box(X * Transform3D(Basis(), Vector3(sx, 0.03, 0)), Vector3(0.12, 0.06, 0.5), "bois_sombre", 1.0)
	R.kit.box(X * Transform3D(Basis(), Vector3(0, 1.62, 0)), Vector3(1.36, 0.1, 0.1), "bois_sombre", 1.0)
	var G: Transform3D = X * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0.95, -0.02))
	R.kit.cyl(G, 0.46, 0.46, 0.03, "cuivre", 32)
	R.kit.ring(G, 0.4, 0.47, 0.05, "cuivre", 32)
	R.kit.cyl(G * Transform3D(Basis(), Vector3(0, -0.02, 0)), 0.06, 0.06, 0.07, "cuivre", 12)
	for sx2 in [-0.28, 0.28]:
		R.kit.box(X * Transform3D(Basis(), Vector3(sx2, 1.45, -0.02)), Vector3(0.008, 0.3, 0.008), "fer", 1.0)
	R.kit.box(X * Transform3D(Basis(Vector3.BACK, 0.5), Vector3(0.45, 0.35, 0.25)), Vector3(0.03, 0.6, 0.03), "bois_clair", 1.0)
	R.kit.cyl(X * Transform3D(Basis(), Vector3(0.6, 0.62, 0.25)), 0.07, 0.07, 0.1, "tissu_rouge", 10)
	R.kit.cyl(X * Transform3D(Basis(), Vector3(-0.95, 0, 0.15)), 0.24, 0.22, 0.5, "tissu_rouge", 16)
	R.kit.cyl(X * Transform3D(Basis(), Vector3(-0.95, 0.5, 0.15)), 0.245, 0.245, 0.02, "cuir", 16)
	R.kit.col_box(X * Transform3D(Basis(), Vector3(0, 0.8, 0)), Vector3(1.3, 1.6, 0.4))


## Le Capitaine Rigatoni : la meule de parmesan et la Râpe d'Or posée dessus, la longue-vue sur son
## trépied, le coffre de marin.
static func _pa_capitaine(M) -> void:
	var R = M.R
	var c: Array = _place(M, 1.6, 0.8)
	if c.is_empty():
		return
	var X: Transform3D = R.L(float(c[0]), 0, float(c[1]), float(c[2]))
	R.kit.cyl(X * Transform3D(Basis(), Vector3(-0.35, 0, 0.05)), 0.36, 0.36, 0.24, "fromage", 24)
	R.kit.ring(X * Transform3D(Basis(), Vector3(-0.35, 0.0, 0.05)), 0.33, 0.37, 0.245, "pain", 24)
	R.kit.box(X * Transform3D(Basis(Vector3.UP, 0.5), Vector3(-0.35, 0.27, 0.05)), Vector3(0.08, 0.05, 0.22), "or", 1.0)
	R.kit.box(X * Transform3D(Basis(Vector3.UP, 0.5), Vector3(-0.35, 0.27, 0.05)) * Transform3D(Basis(), Vector3(0, 0, 0.16)), Vector3(0.03, 0.03, 0.12), "bois_sombre", 1.0)
	R.kit.col_box(X * Transform3D(Basis(), Vector3(-0.35, 0.12, 0.05)), Vector3(0.7, 0.24, 0.7))
	var T: Transform3D = X * Transform3D(Basis(), Vector3(0.45, 0, 0.1))
	for k in range(3):
		var a: float = TAU * k / 3.0
		R.kit.box(T * Transform3D(Basis(Vector3(cos(a + PI * 0.5), 0, sin(a + PI * 0.5)), 0.2), Vector3(cos(a) * 0.12, 0.6, sin(a) * 0.12)), Vector3(0.03, 1.22, 0.03), "bois_sombre", 1.0)
	R.kit.cyl(T * Transform3D(Basis(Vector3.RIGHT, PI * 0.42), Vector3(0, 1.2, -0.3)), 0.045, 0.03, 0.7, "cuivre", 12)
