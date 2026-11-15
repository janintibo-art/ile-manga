extends RefCounted
## V147 : la Fosse aux Dés, le premier lieu de jeu de Pile-ou-Face (l'Île Perchée), qu'on visite comme les
## maisons (maisons_v81 : devant la porte, « E : entrer… », un fondu, et l'on est dedans).
## Une cave voûtée de moellons, des arcs de bois, des lanternes, des tonneaux ; trois tables :
##  - le Grand Lancer (à gauche, au fond) : on lance deux dés contre Grand-Dé, le maître des lieux ;
##  - le Sept (à droite, au fond) : Monsieur Rouage, l'automate de laiton de Gédéon Tic, tient la table ;
##  - le Menteur (au milieu, la table ronde) : Abélard Pépite, Hilda Enclume et la Veuve Clou y jouent ;
## près de la porte, la Caisse (les jetons du jour, les lots) ; au mur, le Tableau des réputations ;
## quelques curieux qui regardent et commentent.
## V148 : le Tripot de la Dame de Pique : un salon de papier peint bordeaux et de parquet, le lustre, le
## bar et son miroir, le piano, et la table de blackjack en demi-lune où la Dame de Pique donne les cartes
## (Gédéon Tic et Fanchon Fil-d'Or y jouent aussi) ; la Caisse, le Tableau des réputations.
## Les tables sont confiées à jeux_v147 (main.jeux_v147) : on s'y assoit, on mise, on joue.
## M : maisons_v81.

const Kit = preload("res://scripts/azur_kit_v56.gd")
const Des = preload("res://scripts/des_v147.gd")
const Figurant = preload("res://scripts/pnj/figurant_v81.gd")
const Cartes = preload("res://scripts/cartes_v148.gd")

const STYLE := "perchee_lieu"
const TAILLES := {"pp_fosse": Vector2(15.0, 13.0), "pp_tripot": Vector2(15.0, 12.0)}
const ENTRER := {"pp_fosse": "E : descendre à la Fosse aux Dés", "pp_tripot": "E : entrer au Tripot de la Dame de Pique"}
const H: float = 4.2
const HABITANTS := "res://scripts/pnj/perchee_habitants_v146.gd"
## Les rangs du Tableau des réputations (les habitués ; le joueur s'y ajoute).
const HABITUES := [["Dame de Pique", "Maître du jeu"], ["Hilda Enclume", "Fine lame"], ["la Veuve Clou", "Fine lame"],
	["Grand-Dé", "Joueur"], ["Gédéon Tic", "Bleu"], ["Abélard Pépite", "Pigeon"]]


static func is_lieu(style: String) -> bool:
	return style == STYLE


static func taille(cur: Dictionary) -> Vector2:
	return TAILLES.get(str(cur.get("histoire", "")), Vector2(12.0, 10.0))


static func has(sc: String) -> bool:
	return TAILLES.has(sc)


## La porte d'un lieu (perchee_bourg_v146 l'appelle) : « lieu » (pp_fosse), la porte, le dehors.
static func register(lieu: String, door: Vector3, out: Vector3) -> bool:
	if not TAILLES.has(lieu):
		return false
	out.y = 0.0
	if out.length() < 0.01:
		return false
	var tl: Vector2 = TAILLES[lieu]
	Kit.PORTES_V81.append({"door": door, "out": out.normalized(), "w": tl.x, "d": tl.y, "style": STYLE, "floors": 1, "owner": "",
		"histoire": lieu, "entrer": str(ENTRER[lieu])})
	return true


# =================================================================== la coque

static func _mur(M, key: String, tex: String, tint: Color, tile: float) -> void:
	var R = M.R
	R._put(key, R._texmat(tex, tint, 0.9))
	R.pal[key] = [tex, tint, tile]


static func shell(M) -> void:
	var R = M.R
	R.pal = (R.pal as Dictionary).duplicate()
	if str(M.ctx.get("scenario", "")) == "pp_tripot":
		R.H = 3.7
		R.pal["fenetre"] = "aucune"
		_mur(M, "mur", "maisons/pp_damas_bordeaux.png", Color(0.95, 0.85, 0.82), 1.6)
		_mur(M, "bas", "maisons/lambris_sombre.png", Color(0.9, 0.85, 0.8), 1.4)
		_mur(M, "sol", "maisons/parquet_chevron.png", Color(0.8, 0.66, 0.54), 2.2)
		_mur(M, "plafond", "montjoie/bois_planches.png", Color(0.36, 0.24, 0.18), 2.0)
		R.shell()
		return
	R.H = H
	R.pal["fenetre"] = "aucune"
	_mur(M, "mur", "montjoie/moellons.png", Color(0.9, 0.8, 0.7), 1.8)
	_mur(M, "bas", "montjoie/moellons.png", Color(0.68, 0.58, 0.5), 1.4)
	_mur(M, "sol", "montjoie/dalles_donjon.png", Color(0.78, 0.7, 0.62), 2.0)
	_mur(M, "plafond", "montjoie/bois_planches.png", Color(0.42, 0.32, 0.24), 2.0)
	R.style = "cave"
	R.rideaux = false
	R.shell()
	R.rideaux = true
	R.style = STYLE


# =================================================================== les petites choses

static func _r(M) -> RandomNumberGenerator:
	return M.ctx["rng"]


static func _pick(M, a: Array) -> Variant:
	return a[_r(M).randi() % a.size()]


static func _m(M, key: String, c: Color, rough: float = 0.6, metal: float = 0.0, emit: float = 0.0) -> StandardMaterial3D:
	if not M.ctx.has("mats147"):
		M.ctx["mats147"] = {}
	var cache: Dictionary = M.ctx["mats147"]
	if cache.has(key):
		return cache[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = Color(c.r, c.g, c.b)
		m.emission_energy_multiplier = emit
	cache[key] = m
	return m


static func _mesh(parent: Node3D, mesh: Mesh, mat: Material, at: Vector3, basis: Basis = Basis()) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	parent.add_child(mi)
	mi.global_transform = Transform3D(basis, at)
	return mi


static func _boite(sx: float, sy: float, sz: float) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = Vector3(sx, sy, sz)
	return b


static func _cyl(rt: float, rb: float, h: float, seg: int = 16) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = rt
	c.bottom_radius = rb
	c.height = h
	c.radial_segments = seg
	c.rings = 1
	return c


static func _lampe(M, at: Vector3, c: Color, e: float, rng_m: float) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.light_color = c
	l.light_energy = e
	l.omni_range = rng_m
	l.omni_attenuation = 1.1
	l.shadow_enabled = false
	M.room.add_child(l)
	l.global_position = at
	M.R.lights.append(l)
	return l


static func _texte(M, at: Vector3, face: Vector3, t: String, size: int, c: Color) -> Label3D:
	var l := Label3D.new()
	l.text = t
	l.font_size = size
	l.pixel_size = 0.0035
	l.modulate = c
	l.outline_size = 6
	l.outline_modulate = Color(0.08, 0.05, 0.03)
	l.shaded = false
	l.double_sided = false
	M.room.add_child(l)
	l.global_position = at
	l.look_at(at - face, Vector3.UP)
	return l


## Une lanterne pendue (le fer, le verre qui brille) et sa lumière.
static func _lanterne(M, at: Vector3) -> void:
	var fer: StandardMaterial3D = _m(M, "fer", Color(0.16, 0.15, 0.14), 0.5, 0.6)
	var verre: StandardMaterial3D = _m(M, "verre_lampe", Color(1.0, 0.72, 0.36), 0.3, 0.0, 2.4)
	_mesh(M.room, _cyl(0.008, 0.008, 0.6, 4), fer, at + Vector3.UP * 0.45)
	_mesh(M.room, _cyl(0.05, 0.11, 0.08, 6), fer, at + Vector3.UP * 0.18)
	_mesh(M.room, _cyl(0.085, 0.085, 0.24, 6), verre, at)
	_mesh(M.room, _cyl(0.1, 0.08, 0.04, 6), fer, at + Vector3.DOWN * 0.14)
	_lampe(M, at + Vector3.DOWN * 0.1, Color(1.0, 0.74, 0.44), 1.15, 6.5)


## Le tapis de jeu (le feutre vert, bordé de bois et de laiton) sur une table rectangulaire.
static func _tapis_rect(M, c: Vector3, w: float, d: float, h: float, couleur: Color) -> void:
	var R = M.R
	var k = R.kit
	var bois: StandardMaterial3D = _m(M, "acajou", Color(0.34, 0.16, 0.08), 0.45)
	var feutre: StandardMaterial3D = _m(M, "feutre_%s" % couleur.to_html(false), couleur, 0.95)
	var laiton: StandardMaterial3D = _m(M, "laiton", Color(0.88, 0.68, 0.32), 0.35, 0.65)
	_mesh(M.room, _boite(w, 0.08, d), bois, c + Vector3.UP * (h - 0.04))
	_mesh(M.room, _boite(w - 0.16, 0.012, d - 0.16), feutre, c + Vector3.UP * h)
	for sx in [-1.0, 1.0]:
		_mesh(M.room, _boite(0.035, 0.035, d + 0.02), laiton, c + Vector3(sx * w * 0.5, h - 0.02, 0))
		for sz in [-1.0, 1.0]:
			_mesh(M.room, _cyl(0.05, 0.035, h - 0.08, 8), bois, c + Vector3(sx * (w * 0.5 - 0.12), (h - 0.08) * 0.5, sz * (d * 0.5 - 0.12)))
	# le rebord, pour que les dés ne tombent pas
	for sz2 in [-1.0, 1.0]:
		_mesh(M.room, _boite(w, 0.06, 0.06), bois, c + Vector3(0, h + 0.03, sz2 * (d * 0.5 - 0.03)))
	for sx2 in [-1.0, 1.0]:
		_mesh(M.room, _boite(0.06, 0.06, d), bois, c + Vector3(sx2 * (w * 0.5 - 0.03), h + 0.03, 0))
	k.col_box(Transform3D(Basis(), c + Vector3.UP * h * 0.5), Vector3(w, h, d))


static func _tabouret(M, at: Vector3) -> void:
	var bois: StandardMaterial3D = _m(M, "bois_tab", Color(0.42, 0.26, 0.14), 0.7)
	var cuir: StandardMaterial3D = _m(M, "cuir_rouge", Color(0.45, 0.1, 0.08), 0.6)
	_mesh(M.room, _cyl(0.2, 0.2, 0.06, 14), cuir, at + Vector3.UP * 0.62)
	_mesh(M.room, _cyl(0.04, 0.06, 0.6, 8), bois, at + Vector3.UP * 0.3)
	_mesh(M.room, _cyl(0.2, 0.22, 0.04, 14), bois, at + Vector3.UP * 0.02)


static func _tonneau(M, at: Vector3, s: float = 1.0) -> void:
	var bois: StandardMaterial3D = _m(M, "douelles", Color(0.46, 0.3, 0.16), 0.75)
	var fer: StandardMaterial3D = _m(M, "fer", Color(0.16, 0.15, 0.14), 0.5, 0.6)
	_mesh(M.room, _cyl(0.3 * s, 0.3 * s, 0.9 * s, 14), bois, at + Vector3.UP * 0.45 * s)
	_mesh(M.room, _cyl(0.34 * s, 0.34 * s, 0.6 * s, 14), bois, at + Vector3.UP * 0.45 * s)
	for y in [0.12, 0.45, 0.78]:
		_mesh(M.room, _cyl(0.345 * s, 0.345 * s, 0.04 * s, 14), fer, at + Vector3.UP * y * s)
	M.R.kit.col_box(Transform3D(Basis(), at + Vector3.UP * 0.45 * s), Vector3(0.68, 0.9, 0.68) * s)


## Un habitant de Pile-ou-Face (sa fiche à lui : son visage, sa tenue) en figurant.
static func _habitant(M, id: String, at: Vector3, face: Vector3, pose: String) -> Node:
	if not ResourceLoader.exists(HABITANTS):
		return null
	var prof: Dictionary = {}
	for p in (load(HABITANTS) as Script).all_profiles():
		if str(p.get("id", "")) == id:
			prof = (p as Dictionary).duplicate(true)
	if prof.is_empty():
		return null
	prof["classe"] = "montjoie"
	var f: Node = Figurant.spawn(M.room, M.main, prof, at, face, pose)
	M.people.append(f)
	return f


# =================================================================== construire

static func build(M, sc: String) -> void:
	if sc == "pp_fosse":
		_fosse(M)
	elif sc == "pp_tripot":
		_tripot(M)


static func _fosse(M) -> void:
	var R = M.R
	var k = R.kit
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var jeux: Node = M.main.get("jeux_v147")
	if jeux != null:
		jeux.vider_tables()
	var ex: Vector3 = R.P(1, 0, 0) - R.P(0, 0, 0)        # l'axe +X de la pièce, dans le monde
	var ez: Vector3 = R.P(0, 0, 1) - R.P(0, 0, 0)        # l'axe +Z (vers la porte)
	# ---------------------------------------------------------------- la voûte : arcs de bois, poutres
	var poutre: StandardMaterial3D = _m(M, "poutre", Color(0.26, 0.17, 0.1), 0.8)
	for zz in [-4.2, -0.6, 3.0]:
		for sx in [-1.0, 1.0]:
			_mesh(M.room, _boite(0.3, H, 0.3), poutre, R.P(sx * (hw - 0.2), H * 0.5, zz))
			k.col_box(Transform3D(Basis(), R.P(sx * (hw - 0.2), H * 0.5, zz)), Vector3(0.3, H, 0.3))
		_mesh(M.room, _boite(R.W, 0.32, 0.3), poutre, R.P(0, H - 0.16, zz))
		# les jambes de force
		for sx3 in [-1.0, 1.0]:
			_mesh(M.room, _boite(0.18, 1.5, 0.18), poutre, R.P(sx3 * (hw - 0.75), H - 0.62, zz), Basis(Vector3.BACK, sx3 * 0.75))
	# ---------------------------------------------------------------- l'enseigne du fond, les affiches
	_texte(M, R.P(0, 3.25, -hd + 0.08), ez, "LA FOSSE AUX DÉS", 120, Color(1.0, 0.82, 0.42))
	_texte(M, R.P(0, 2.82, -hd + 0.08), ez, "Ici, tout roule !", 64, Color(0.95, 0.9, 0.8))
	var rouge: StandardMaterial3D = _m(M, "enseigne_rouge", Color(0.42, 0.08, 0.06), 0.7)
	_mesh(M.room, _boite(4.4, 0.95, 0.04), rouge, R.P(0, 3.05, -hd + 0.03))
	# deux grands dés de bois peint, au-dessus du fond
	for sx4 in [-1.0, 1.0]:
		var gd: MeshInstance3D = Des.de(M.room, R.P(sx4 * 2.9, 2.6, -hd + 0.4), 6 if sx4 < 0 else 5, 0.42, "rouge")
		gd.rotate_y(sx4 * 0.4)
	# ---------------------------------------------------------------- les lanternes
	for p in [Vector3(-4.2, 3.0, -3.2), Vector3(4.2, 3.0, -3.2), Vector3(0, 3.0, 1.0), Vector3(-5.4, 3.0, 4.3), Vector3(5.0, 3.1, 3.6)]:
		_lanterne(M, R.P(p.x, p.y, p.z))
	_lampe(M, R.P(0, 3.6, -2.0), Color(1.0, 0.8, 0.55), 0.6, 12.0)
	# ---------------------------------------------------------------- les tonneaux, les caisses
	for t in [Vector3(-hw + 0.5, 0, -hd + 0.5), Vector3(-hw + 1.2, 0, -hd + 0.45), Vector3(hw - 0.5, 0, -hd + 0.5), Vector3(hw - 0.5, 0, 0.6), Vector3(-hw + 0.5, 0, 0.9)]:
		_tonneau(M, R.P(t.x, 0, t.z), _r(M).randf_range(0.9, 1.1))
	R.caisse(hw - 0.5, 1.5, 0.6)
	R.caisse(hw - 0.55, 1.5, 0.45, 0.6)
	# ---------------------------------------------------------------- le Grand Lancer (Grand-Dé)
	var cl: Vector3 = R.P(-4.2, 0, -3.2)
	_tapis_rect(M, cl, 1.9, 1.2, 0.86, Color(0.12, 0.34, 0.18))
	_texte(M, R.P(-4.2, 2.2, -4.5), ez, "LE GRAND LANCER", 72, Color(1.0, 0.85, 0.5))
	_texte(M, R.P(-4.2, 1.95, -4.5), ez, "Double six : triple mise !", 44, Color(0.95, 0.92, 0.85))
	var gd_node: Node = _habitant(M, "grand_de_pp", R.P(-4.2, 0, -4.15), ez, "comptoir")
	if gd_node != null:
		gd_node.lines = ["Ça roule ! Qui lance ?", "HA HA ! Approche, approche !", "Pétula me dit que tu as de la chance aujourd'hui."]
	_tabouret(M, R.P(-4.9, 0, -2.25))
	# ---------------------------------------------------------------- le Sept (Monsieur Rouage, l'automate)
	var cs: Vector3 = R.P(4.2, 0, -3.2)
	_tapis_rect(M, cs, 1.9, 1.2, 0.86, Color(0.36, 0.08, 0.08))
	_texte(M, R.P(4.2, 2.35, -4.5), ez, "LE SEPT", 80, Color(1.0, 0.85, 0.5))
	_texte(M, R.P(4.2, 2.08, -4.5), ez, "Moins de 7 · Sept · Plus de 7", 44, Color(0.95, 0.92, 0.85))
	for lab in [["MOINS DE 7", -0.58], ["SEPT", 0.0], ["PLUS DE 7", 0.58]]:
		var tl: Label3D = _texte(M, cs + ex * float(lab[1]) + ez * 0.3 + Vector3.UP * 0.875, Vector3.UP, str(lab[0]), 24, Color(1.0, 0.92, 0.7))
		tl.look_at(tl.global_position + Vector3.DOWN, -ez)
	var rouage: Dictionary = _automate(M, R.P(4.2, 0, -4.15), ez)
	_tabouret(M, R.P(4.9, 0, -2.25))
	# ---------------------------------------------------------------- le Menteur (la table ronde)
	var cm: Vector3 = R.P(0, 0, 0.9)
	var bois: StandardMaterial3D = _m(M, "acajou", Color(0.34, 0.16, 0.08), 0.45)
	_mesh(M.room, _cyl(1.0, 1.0, 0.08, 32), bois, cm + Vector3.UP * 0.8)
	_mesh(M.room, _cyl(0.86, 0.86, 0.012, 32), _m(M, "feutre_bleu", Color(0.1, 0.18, 0.3), 0.95), cm + Vector3.UP * 0.845)
	_mesh(M.room, _cyl(0.1, 0.16, 0.76, 10), bois, cm + Vector3.UP * 0.38)
	_mesh(M.room, _cyl(0.45, 0.5, 0.06, 16), bois, cm + Vector3.UP * 0.03)
	k.col_box(Transform3D(Basis(), cm + Vector3.UP * 0.42), Vector3(1.5, 0.84, 1.5))
	var adv: Array = []
	var places: Array = []
	var noms: Array = ["pepite_pp", "hilda_pp", "veuve_clou_pp"]
	var dirs: Array = [ez, -ex, -ez, ex]          # le joueur au sud (vers la porte), puis ouest, nord, est
	for i in range(4):
		var dv: Vector3 = dirs[i]
		places.append(cm + dv * 0.55 + Vector3.UP * 0.85)
		if i == 0:
			continue
		_tabouret(M, cm + dv * 1.35)
		var f: Node = _habitant(M, str(noms[i - 1]), cm + dv * 1.3, -dv, "assis")
		if f != null:
			f.lines = ["Hm.", "À toi de parler.", "Trois dés, et beaucoup de mensonges."] if i != 1 else ["Ginette dit que je vais gagner. Ginette, c'est ma pioche.", "Hé hé…"]
		adv.append(f)
	_tabouret(M, cm + ez * 1.35)
	# ---------------------------------------------------------------- la Caisse (près de la porte)
	var cc: Vector3 = R.P(-hw + 1.3, 0, hd - 1.9)
	var comptoir: StandardMaterial3D = _m(M, "comptoir", Color(0.3, 0.17, 0.09), 0.5)
	_mesh(M.room, _boite(0.7, 1.1, 2.2), comptoir, cc + Vector3.UP * 0.55)
	_mesh(M.room, _boite(0.8, 0.05, 2.3), _m(M, "laiton", Color(0.88, 0.68, 0.32), 0.35, 0.65), cc + Vector3.UP * 1.12)
	k.col_box(Transform3D(Basis(), cc + Vector3.UP * 0.55), Vector3(0.7, 1.1, 2.2))
	# le grillage du guichet
	var fer: StandardMaterial3D = _m(M, "fer", Color(0.16, 0.15, 0.14), 0.5, 0.6)
	for g in range(9):
		_mesh(M.room, _cyl(0.006, 0.006, 0.6, 4), fer, cc + Vector3(0, 1.45, 0) + ez * (-0.8 + g * 0.2))
	_mesh(M.room, _boite(0.05, 0.05, 2.2), fer, cc + Vector3.UP * 1.75)
	_texte(M, cc + Vector3.UP * 2.15 + ex * 0.36, ex, "CAISSE", 70, Color(1.0, 0.85, 0.5))
	# les piles de jetons sur le comptoir
	var couleurs: Array = [Color(0.75, 0.1, 0.08), Color(0.1, 0.25, 0.6), Color(0.9, 0.86, 0.75), Color(0.12, 0.45, 0.2)]
	for pi in range(5):
		var pc: Vector3 = cc + Vector3.UP * 1.145 + ez * (-0.7 + pi * 0.12) + ex * 0.2
		var n: int = 3 + _r(M).randi() % 6
		for j in range(n):
			_mesh(M.room, _cyl(0.022, 0.022, 0.008, 12), _m(M, "jeton_%d" % (pi % 4), couleurs[pi % 4], 0.5), pc + Vector3.UP * (0.004 + j * 0.0085))
	var caissiere: Node = M.person("femme", -hw + 0.6, hd - 1.9, 90.0, "comptoir", "Rosalie")
	caissiere.lines = ["Des jetons ? Des lots ? La Caisse ne dort jamais.", "Pas de crédit, mon chou.", "Sachez vous arrêter, c'est ça, le vrai jeu."]
	# ---------------------------------------------------------------- le Tableau des réputations
	_tableau(M, R.P(hw - 0.06, 0, -2.4), -ex, jeux)
	# ---------------------------------------------------------------- les curieux
	var c1: Node = M.person("homme", -2.6, -1.6, 225.0, "debout")
	c1.lines = ["Allez, le six !", "Grand-Dé n'a jamais perdu un mardi. On est mardi ?", "J'ai tout misé sur le sept, une fois. Une seule fois."]
	var c2: Node = M.person("vieille", 2.5, 2.4, 140.0, "bras_croises")
	c2.lines = ["De mon temps, on jouait des haricots.", "Celui-là, il bluffe. Ça se voit à ses oreilles.", "Pigeon ou maître du jeu, on le saura vite."]
	var c3: Node = M.person("homme", 2.4, -1.5, 135.0, "applaudir")
	c3.lines = ["Bravo ! Encore !", "TIC, TAC, la machine a parlé !"]
	# ---------------------------------------------------------------- les tables, confiées aux jeux
	if jeux != null:
		var hauteur: float = 0.875
		jeux.table("lancer", {"centre": cl + Vector3.UP * hauteur, "siege": cl + ez * 1.0, "regard": -ez, "parent": M.room, "croupier": gd_node})
		jeux.table("sept", {"centre": cs + Vector3.UP * hauteur, "siege": cs + ez * 1.0, "regard": -ez, "parent": M.room, "croupier": null,
			"dire": rouage["dire"], "lancer": rouage["lancer"]})
		jeux.table("menteur", {"centre": cm + Vector3.UP * 0.85, "siege": cm + ez * 1.15, "regard": -ez, "parent": M.room, "adversaires": adv, "places": places})
		jeux.table("caisse", {"centre": cc + Vector3.UP * 1.1, "siege": cc + ex * 1.0, "regard": -ex, "parent": M.room})
		var assis_pas := func() -> bool: return str(jeux.assis) == ""
		M.act(cl + ez * 1.0 + Vector3.UP * 0.4, "E : jouer au Grand Lancer", func(): jeux.asseoir("lancer"), 1.3, assis_pas, "Gâchette : jouer au Grand Lancer")
		M.act(cs + ez * 1.0 + Vector3.UP * 0.4, "E : jouer au Sept", func(): jeux.asseoir("sept"), 1.3, assis_pas, "Gâchette : jouer au Sept")
		M.act(cm + ez * 1.15 + Vector3.UP * 0.4, "E : s'asseoir à la table du Menteur", func(): jeux.asseoir("menteur"), 1.3, assis_pas, "Gâchette : s'asseoir à la table du Menteur")
		M.act(cc + ex * 1.0 + Vector3.UP * 0.4, "E : aller à la Caisse", func(): jeux.asseoir("caisse"), 1.4, assis_pas, "Gâchette : aller à la Caisse")
	# le bruit de la salle : des dés qui roulent, des rires, de temps en temps
	M.ctx["t147"] = 3.0
	M.ctx["tick"] = func(delta: float) -> void:
		M.ctx["t147"] = float(M.ctx["t147"]) - delta
		if float(M.ctx["t147"]) <= 0.0:
			M.ctx["t147"] = _r(M).randf_range(6.0, 14.0)
			if jeux == null or str(jeux.assis) == "":
				M.main.sfx("des_roule", R.P(_r(M).randf_range(-3.0, 3.0), 0.9, -2.0), -12.0)
		(rouage["tick"] as Callable).call(delta)
	M.ctx["entree"] = str(_pick(M, ["La Fosse aux Dés : une cave voûtée qui sent la bière et la cire, des lanternes, le bruit des dés sur le feutre. Au fond, Grand-Dé rit déjà.",
		"Des dés qui roulent, des jetons qui claquent, et une machine de laiton qui fait « TIC… TAC… ». Bienvenue à la Fosse aux Dés.",
		"La Fosse aux Dés. Trois tables : le Grand Lancer, le Sept, et le Menteur. La Caisse est près de la porte."]))


## Monsieur Rouage : l'automate de laiton du Sept (un buste sur un socle, la tête qui tourne, le bras qui
## lance, une bulle de texte pour parler). Rend {dire: Callable, lancer: Callable, tick: Callable}.
static func _automate(M, at: Vector3, face: Vector3) -> Dictionary:
	var laiton: StandardMaterial3D = _m(M, "laiton", Color(0.88, 0.68, 0.32), 0.35, 0.65)
	var cuivre: StandardMaterial3D = _m(M, "cuivre", Color(0.72, 0.4, 0.24), 0.4, 0.7)
	var fer: StandardMaterial3D = _m(M, "fer", Color(0.16, 0.15, 0.14), 0.5, 0.6)
	var oeil: StandardMaterial3D = _m(M, "oeil_auto", Color(0.4, 0.85, 1.0), 0.2, 0.0, 3.0)
	var root := Node3D.new()
	root.name = "MonsieurRouage"
	M.room.add_child(root)
	root.global_position = at
	root.look_at(at + face, Vector3.UP)
	root.rotate_y(PI)
	var socle := _mesh(root, _cyl(0.32, 0.4, 0.75, 16), fer, at + Vector3.UP * 0.375)
	socle.name = "socle"
	_mesh(root, _cyl(0.24, 0.3, 0.55, 16), laiton, at + Vector3.UP * 1.05)
	_mesh(root, _cyl(0.31, 0.31, 0.05, 16), cuivre, at + Vector3.UP * 0.78)
	# la tête (un globe, deux yeux qui brillent, un chapeau melon)
	var tete := Node3D.new()
	root.add_child(tete)
	tete.global_position = at + Vector3.UP * 1.5
	var sm := SphereMesh.new()
	sm.radius = 0.17
	sm.height = 0.34
	_mesh(tete, sm, laiton, at + Vector3.UP * 1.5)
	var fwd: Vector3 = face.normalized()
	var side: Vector3 = fwd.cross(Vector3.UP)
	for s in [-1.0, 1.0]:
		var so := SphereMesh.new()
		so.radius = 0.035
		so.height = 0.07
		_mesh(tete, so, oeil, at + Vector3.UP * 1.53 + fwd * 0.15 + side * s * 0.065)
	_mesh(tete, _cyl(0.12, 0.13, 0.12, 14), fer, at + Vector3.UP * 1.7)
	_mesh(tete, _cyl(0.2, 0.2, 0.015, 14), fer, at + Vector3.UP * 1.64)
	# le rouage dans la poitrine (il tourne)
	var roue := _mesh(root, _cyl(0.12, 0.12, 0.03, 12), cuivre, at + Vector3.UP * 1.08 + fwd * 0.27, Basis(side, PI * 0.5))
	# le bras qui lance (une épaule, un avant-bras, un gobelet)
	var epaule := Node3D.new()
	root.add_child(epaule)
	epaule.global_position = at + Vector3.UP * 1.25 + side * 0.3
	_mesh(epaule, _cyl(0.035, 0.035, 0.45, 8), laiton, epaule.global_position + fwd * 0.2 + Vector3.DOWN * 0.05, Basis(side, PI * 0.5 - 0.3))
	_mesh(epaule, _cyl(0.06, 0.045, 0.12, 10), cuivre, epaule.global_position + fwd * 0.42 + Vector3.DOWN * 0.1)
	var bulle := Label3D.new()
	bulle.font_size = 48
	bulle.pixel_size = 0.0035
	bulle.modulate = Color(0.75, 0.95, 1.0)
	bulle.outline_size = 8
	bulle.outline_modulate = Color(0.05, 0.08, 0.1)
	bulle.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	bulle.width = 600.0
	bulle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bulle.visible = false
	M.room.add_child(bulle)
	bulle.global_position = at + Vector3.UP * 2.05
	var st := {"t": 0.0, "dire": 0.0, "lancer": 0.0, "parle": 8.0}
	var phrases: Array = ["TIC. TAC. FAITES VOS JEUX.", "BONJOUR. JE SUIS MONSIEUR ROUAGE. JE NE TRICHE PAS. JE CALCULE.", "LE SEPT SORT UNE FOIS SUR SIX. JE LE SAIS. JE SUIS UNE MACHINE.", "TIC… TAC…"]
	var dire := func(s: String) -> void:
		bulle.text = s
		bulle.visible = true
		st["dire"] = 4.0
	var lancer := func() -> void:
		st["lancer"] = 0.8
		M.main.sfx("gobelet", at + Vector3.UP * 1.2, -4.0)
	var tick := func(delta: float) -> void:
		if not is_instance_valid(tete):
			return
		st["t"] = float(st["t"]) + delta
		var t: float = st["t"]
		tete.rotation.y = sin(t * 0.7) * 0.35
		roue.rotate_object_local(Vector3.UP, delta * 2.5)
		if float(st["dire"]) > 0.0:
			st["dire"] = float(st["dire"]) - delta
			if float(st["dire"]) <= 0.0:
				bulle.visible = false
		if float(st["lancer"]) > 0.0:
			st["lancer"] = float(st["lancer"]) - delta
			epaule.rotation.x = sin(float(st["lancer"]) * 12.0) * 0.4
		else:
			epaule.rotation.x = 0.0
		st["parle"] = float(st["parle"]) - delta
		if float(st["parle"]) <= 0.0:
			st["parle"] = randf_range(14.0, 26.0)
			if float(st["dire"]) <= 0.0:
				bulle.text = str(phrases[randi() % phrases.size()])
				bulle.visible = true
				st["dire"] = 4.0
	return {"dire": dire, "lancer": lancer, "tick": tick}


## Le Tableau des réputations : les habitués, et le joueur à son rang.
static func _tableau(M, at: Vector3, face: Vector3, jeux: Node) -> void:
	var bois: StandardMaterial3D = _m(M, "cadre", Color(0.3, 0.18, 0.1), 0.6)
	var ardoise: StandardMaterial3D = _m(M, "ardoise", Color(0.12, 0.14, 0.13), 0.9)
	var side: Vector3 = face.cross(Vector3.UP)
	var b := Basis.looking_at(-face, Vector3.UP)
	_mesh(M.room, _boite(1.9, 1.6, 0.05), bois, at + Vector3.UP * 1.75 - face * 0.0, b)
	_mesh(M.room, _boite(1.75, 1.45, 0.02), ardoise, at + Vector3.UP * 1.75 + face * 0.03, b)
	_texte(M, at + Vector3.UP * 2.35 + face * 0.05, face, "TABLEAU DES RÉPUTATIONS", 46, Color(1.0, 0.85, 0.5))
	var rangs: Array = HABITUES.duplicate(true)
	if jeux != null:
		rangs.append(["Vous", jeux.titre()])
	var y: float = 2.17
	for r in rangs:
		var nom: Label3D = _texte(M, at + Vector3.UP * y + face * 0.05 + side * 0.78, face, str(r[0]), 28, Color(0.95, 0.95, 0.9) if str(r[0]) != "Vous" else Color(1.0, 0.9, 0.45))
		nom.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		var ti: Label3D = _texte(M, at + Vector3.UP * y + face * 0.05 - side * 0.05, face, str(r[1]), 28, Color(0.85, 0.95, 0.8))
		ti.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		y -= 0.16


# =================================================================== le Tripot de la Dame de Pique (V148)

## Une demi-lune (le plateau de la table de blackjack) : le côté droit en -Z (la donneuse), l'arrondi vers +Z.
static func _demi_lune(r: float, ep: float, seg: int = 28) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pts: Array = []
	for i in range(seg + 1):
		var a: float = PI * i / seg
		pts.append(Vector3(cos(a) * r, 0, sin(a) * r))
	for i in range(seg):
		for v in [Vector3.ZERO, pts[i], pts[i + 1]]:
			st.set_normal(Vector3.UP)
			st.set_uv(Vector2(0.5 + (v as Vector3).x / (2 * r), (v as Vector3).z / r))
			st.add_vertex(v + Vector3.UP * ep * 0.5)
		# le chant
		var a0: Vector3 = pts[i]
		var a1: Vector3 = pts[i + 1]
		var nn: Vector3 = ((a0 + a1) * 0.5).normalized()
		for v2 in [a0 + Vector3.UP * ep * 0.5, a1 - Vector3.UP * ep * 0.5, a1 + Vector3.UP * ep * 0.5, a0 + Vector3.UP * ep * 0.5, a0 - Vector3.UP * ep * 0.5, a1 - Vector3.UP * ep * 0.5]:
			st.set_normal(nn)
			st.set_uv(Vector2(0, 0))
			st.add_vertex(v2)
	# le côté droit
	for v3 in [Vector3(-r, ep * 0.5, 0), Vector3(r, -ep * 0.5, 0), Vector3(r, ep * 0.5, 0), Vector3(-r, ep * 0.5, 0), Vector3(-r, -ep * 0.5, 0), Vector3(r, -ep * 0.5, 0)]:
		st.set_normal(Vector3.FORWARD)
		st.set_uv(Vector2(0, 0))
		st.add_vertex(v3)
	return st.commit()


static func _lustre(M, at: Vector3) -> void:
	var laiton: StandardMaterial3D = _m(M, "laiton", Color(0.88, 0.68, 0.32), 0.35, 0.65)
	var flamme: StandardMaterial3D = _m(M, "flamme", Color(1.0, 0.78, 0.4), 0.3, 0.0, 3.0)
	var cire: StandardMaterial3D = _m(M, "cire", Color(0.95, 0.92, 0.84), 0.6)
	_mesh(M.room, _cyl(0.01, 0.01, 0.9, 4), laiton, at + Vector3.UP * 0.5)
	var tm := TorusMesh.new()
	tm.inner_radius = 0.42
	tm.outer_radius = 0.46
	_mesh(M.room, tm, laiton, at)
	_mesh(M.room, _cyl(0.06, 0.12, 0.25, 10), laiton, at + Vector3.DOWN * 0.08)
	for k in range(8):
		var a: float = TAU * k / 8.0
		var p: Vector3 = at + Vector3(cos(a), 0, sin(a)) * 0.44
		_mesh(M.room, _cyl(0.014, 0.014, 0.1, 6), cire, p + Vector3.UP * 0.06)
		var fl := SphereMesh.new()
		fl.radius = 0.012
		fl.height = 0.035
		_mesh(M.room, fl, flamme, p + Vector3.UP * 0.125)
	_lampe(M, at + Vector3.DOWN * 0.1, Color(1.0, 0.76, 0.48), 1.5, 9.0)


static func _bouteilles(M, at: Vector3, along: Vector3, n: int) -> void:
	var cols: Array = [Color(0.35, 0.18, 0.08), Color(0.2, 0.35, 0.15), Color(0.5, 0.12, 0.1), Color(0.75, 0.55, 0.2), Color(0.18, 0.22, 0.4)]
	for k in range(n):
		var c: Color = cols[(k * 7 + 3) % cols.size()]
		var m: StandardMaterial3D = _m(M, "bouteille_%d" % ((k * 7 + 3) % cols.size()), c, 0.12)
		var p: Vector3 = at + along * (k * 0.14)
		_mesh(M.room, _cyl(0.035, 0.038, 0.2, 10), m, p + Vector3.UP * 0.1)
		_mesh(M.room, _cyl(0.012, 0.03, 0.08, 8), m, p + Vector3.UP * 0.24)


static func _tripot(M) -> void:
	var R = M.R
	var k = R.kit
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var jeux: Node = M.main.get("jeux_v147")
	if jeux != null:
		jeux.vider_tables()
	var ex: Vector3 = R.P(1, 0, 0) - R.P(0, 0, 0)
	var ez: Vector3 = R.P(0, 0, 1) - R.P(0, 0, 0)
	var bois: StandardMaterial3D = _m(M, "acajou", Color(0.34, 0.16, 0.08), 0.45)
	var laiton: StandardMaterial3D = _m(M, "laiton", Color(0.88, 0.68, 0.32), 0.35, 0.65)
	# ---------------------------------------------------------------- les lustres, les appliques
	_lustre(M, R.P(0, 3.05, -1.6))
	_lustre(M, R.P(-4.3, 3.05, 2.2))
	_lustre(M, R.P(4.3, 3.05, 2.2))
	# ---------------------------------------------------------------- le grand pique du fond, l'enseigne
	var pique := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(1.1, 1.1)
	pique.mesh = qm
	var pm := StandardMaterial3D.new()
	pm.albedo_texture = Cartes.texture_symbole(0, Color(0.1, 0.07, 0.06), 256)
	pm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pm.roughness = 0.4
	pique.material_override = pm
	M.room.add_child(pique)
	pique.global_position = R.P(0, 2.75, -hd + 0.065)
	_mesh(M.room, _cyl(0.68, 0.68, 0.03, 32), laiton, R.P(0, 2.75, -hd + 0.02), Basis(Vector3.RIGHT, PI * 0.5))
	_mesh(M.room, _cyl(0.64, 0.64, 0.035, 32), _m(M, "creme", Color(0.92, 0.86, 0.72), 0.7), R.P(0, 2.75, -hd + 0.025), Basis(Vector3.RIGHT, PI * 0.5))
	_texte(M, R.P(0, 1.85, -hd + 0.06), ez, "TRIPOT DE LA DAME DE PIQUE", 64, Color(1.0, 0.85, 0.5))
	# ---------------------------------------------------------------- la table de blackjack (la demi-lune)
	var cb: Vector3 = R.P(0, 0, -2.9)
	var h: float = 0.86
	var dl := MeshInstance3D.new()
	dl.mesh = _demi_lune(1.35, 0.08)
	var bois2: StandardMaterial3D = _m(M, "acajou_2f", Color(0.34, 0.16, 0.08), 0.45)
	bois2.cull_mode = BaseMaterial3D.CULL_DISABLED
	dl.material_override = bois2
	M.room.add_child(dl)
	dl.global_position = cb + Vector3.UP * (h - 0.04)
	var feutre := MeshInstance3D.new()
	feutre.mesh = _demi_lune(1.2, 0.012)
	var feutre_m: StandardMaterial3D = _m(M, "feutre_bj_2f", Color(0.1, 0.3, 0.17), 0.95)
	feutre_m.cull_mode = BaseMaterial3D.CULL_DISABLED
	feutre.material_override = feutre_m
	M.room.add_child(feutre)
	feutre.global_position = cb + Vector3.UP * h + ez * 0.06
	for a in [-1.0, -0.33, 0.33, 1.0]:
		_mesh(M.room, _cyl(0.05, 0.035, h - 0.08, 8), bois, cb + Vector3.UP * (h - 0.08) * 0.5 + (ex * sin(a) + ez * cos(a)) * 0.95)
	k.col_box(Transform3D(Basis(), cb + Vector3.UP * h * 0.5 + ez * 0.6), Vector3(2.6, h, 1.3))
	# l'arc doré, les inscriptions sur le feutre
	for i in range(24):
		var a2: float = PI * (i + 0.5) / 24.0
		_mesh(M.room, _boite(0.18, 0.006, 0.012), laiton, cb + Vector3.UP * (h + 0.008) + (ex * cos(a2) + ez * sin(a2)) * 0.62, Basis(Vector3.UP, -a2 + PI * 0.5))
	var l1: Label3D = _texte(M, cb + Vector3.UP * (h + 0.009) + ez * 0.62, Vector3.UP, "LE BLACKJACK PAIE 3 POUR 2", 26, Color(1.0, 0.88, 0.55))
	l1.look_at(l1.global_position + Vector3.DOWN, -ez)
	var l2: Label3D = _texte(M, cb + Vector3.UP * (h + 0.009) + ez * 0.54, Vector3.UP, "LA DONNEUSE TIRE JUSQU'À 17", 20, Color(0.92, 0.9, 0.8))
	l2.look_at(l2.global_position + Vector3.DOWN, -ez)
	# le sabot (une boîte de bois et de laiton, à la droite de la donneuse), les plaques de jetons
	var sabot: Vector3 = cb + ex * 0.75 + ez * 0.14 + Vector3.UP * (h + 0.06)
	_mesh(M.room, _boite(0.14, 0.1, 0.22), bois, sabot + Vector3.DOWN * 0.01)
	_mesh(M.room, _boite(0.145, 0.02, 0.225), laiton, sabot + Vector3.UP * 0.045)
	var couleurs: Array = [Color(0.75, 0.1, 0.08), Color(0.1, 0.25, 0.6), Color(0.9, 0.86, 0.75), Color(0.12, 0.45, 0.2), Color(0.1, 0.1, 0.1)]
	_mesh(M.room, _boite(0.5, 0.03, 0.14), bois, cb + Vector3.UP * (h + 0.015) - ex * 0.55 + ez * 0.1)
	for j in range(5):
		for q in range(6):
			_mesh(M.room, _cyl(0.02, 0.02, 0.008, 12), _m(M, "jeton_%d" % j, couleurs[j], 0.5), cb + Vector3.UP * (h + 0.034 + q * 0.0085) - ex * (0.75 - j * 0.1) + ez * 0.1)
	# la donneuse, les voisins de table, les places
	var dame: Node = _habitant(M, "dame_pique_pp", cb - ez * 0.45, ez, "comptoir")
	if dame != null:
		dame.lines = ["Faites vos jeux.", "Les cartes ne mentent pas. Les joueurs, si.", "Savoir s'arrêter, c'est déjà gagner."]
	var mains: Array = []
	var adv: Array = []
	var noms: Array = ["gedeon_tic_pp", "fanchon_pp"]
	var angles: Array = [0.0, -0.95, 0.95]       # le joueur au milieu ; Gédéon à gauche, Fanchon à droite
	for i in range(3):
		var dir: Vector3 = ez * cos(float(angles[i])) + ex * sin(float(angles[i]))
		mains.append(cb + dir * 0.82 + Vector3.UP * (h + 0.008))
		_tabouret(M, cb + dir * 1.62)
		if i > 0:
			var f: Node = _habitant(M, str(noms[i - 1]), cb + dir * 1.58, -dir, "assis")
			if f != null:
				f.lines = ["Tic. Je compte.", "Le sabot est chaud ce soir."] if i == 1 else ["Une carte, chéri, pour la beauté du geste.", "Ce chapeau me porte bonheur."]
			adv.append(f)
	mains.append(cb + ez * 0.32 + Vector3.UP * (h + 0.008))
	# ---------------------------------------------------------------- le bar (le mur ouest) et son miroir
	var bx: float = -hw + 0.9
	_mesh(M.room, _boite(0.7, 1.1, 4.4), bois, R.P(bx, 0.55, -1.0))
	_mesh(M.room, _boite(0.85, 0.06, 4.5), _m(M, "marbre", Color(0.85, 0.82, 0.78), 0.25), R.P(bx, 1.13, -1.0))
	_mesh(M.room, _cyl(0.025, 0.025, 4.4, 8), laiton, R.P(bx + 0.42, 0.18, -1.0), Basis(Vector3.RIGHT, PI * 0.5))
	k.col_box(R.L(bx, 0.55, -1.0), Vector3(0.7, 1.1, 4.4))
	_mesh(M.room, _boite(0.04, 1.2, 3.0), _m(M, "miroir", Color(0.55, 0.6, 0.62), 0.05, 0.9), R.P(-hw + 0.05, 1.95, -1.0))
	for y in [1.45, 1.85]:
		_mesh(M.room, _boite(0.25, 0.03, 3.6), bois, R.P(-hw + 0.15, y, -1.0))
		_bouteilles(M, R.P(-hw + 0.15, y + 0.015, -2.6), ez, 23)
	for z in [-2.6, -1.6, -0.6, 0.4]:
		_tabouret(M, R.P(bx + 0.75, 0, z))
	var barman: Node = M.person("homme", -hw + 0.35, -1.2, 90.0, "comptoir")
	barman.lines = ["Une salsepareille ? La maison n'a que ça. Et c'est très bien.", "Ici, on boit doux et on joue sec.", "La Dame ne perd jamais. Presque jamais."]
	# ---------------------------------------------------------------- le piano (au nord-est) et son pianiste
	var pp: Vector3 = R.P(hw - 1.2, 0, -hd + 0.7)
	_mesh(M.room, _boite(1.5, 1.3, 0.6), _m(M, "piano", Color(0.08, 0.05, 0.04), 0.3), pp + Vector3.UP * 0.65)
	_mesh(M.room, _boite(1.3, 0.04, 0.22), _m(M, "touches", Color(0.95, 0.93, 0.88), 0.4), pp + Vector3.UP * 0.75 + ez * 0.38)
	for t in range(12):
		_mesh(M.room, _boite(0.03, 0.03, 0.12), _m(M, "noires", Color(0.05, 0.05, 0.05), 0.4), pp + Vector3.UP * 0.78 + ez * 0.34 - ex * 0.6 + ex * (t * 0.105))
	k.col_box(Transform3D(Basis(), pp + Vector3.UP * 0.65), Vector3(1.5, 1.3, 0.8))
	_tabouret(M, pp + ez * 0.85)
	var pianiste: Node = M.person("homme", hw - 1.2, -hd + 1.5, 180.0, "assis")
	pianiste.lines = ["♪ Tadaa-da-dam… ♪", "Une valse ? Un ragtime ? Tout, sauf la marche funèbre.", "Je joue plus vite quand quelqu'un gagne."]
	# ---------------------------------------------------------------- deux petites tables d'habitués
	for tp in [Vector3(-3.6, 0, 2.4), Vector3(3.4, 0, 1.6)]:
		var ct: Vector3 = R.P(tp.x, 0, tp.z)
		_mesh(M.room, _cyl(0.55, 0.55, 0.05, 24), bois, ct + Vector3.UP * 0.76)
		_mesh(M.room, _cyl(0.5, 0.5, 0.008, 24), _m(M, "feutre_bj", Color(0.1, 0.3, 0.17), 0.95), ct + Vector3.UP * 0.788)
		_mesh(M.room, _cyl(0.06, 0.12, 0.74, 10), bois, ct + Vector3.UP * 0.37)
		k.col_box(Transform3D(Basis(), ct + Vector3.UP * 0.4), Vector3(1.0, 0.8, 1.0))
		var rng: RandomNumberGenerator = _r(M)
		for q in range(5):
			Cartes.carte(M.room, {"r": rng.randi_range(1, 13), "c": rng.randi_range(0, 3)}, ct + Vector3.UP * 0.795 + Vector3(rng.randf_range(-0.25, 0.25), 0.001 * q, rng.randf_range(-0.25, 0.25)), rng.randf() * TAU, rng.randf() < 0.6)
	var j1: Node = M.person("homme", -4.35, 2.4, 90.0, "assis")
	j1.lines = ["Je passe.", "Cartes ! … Non, rien. Je passe encore."]
	var j2: Node = M.person("vieille", -2.85, 2.4, -90.0, "assis")
	j2.lines = ["À mon âge, on bluffe avec les rides.", "Paire de rois. Hé hé."]
	var j3: Node = M.person("femme", 3.4, 2.35, 180.0, "assis")
	j3.lines = ["La Dame de Pique a des yeux derrière la tête.", "Je joue petit, mais je joue longtemps."]
	# ---------------------------------------------------------------- la Caisse (à l'est, près de la porte)
	var cc: Vector3 = R.P(hw - 1.1, 0, hd - 1.8)
	var comptoir: StandardMaterial3D = _m(M, "comptoir", Color(0.3, 0.17, 0.09), 0.5)
	_mesh(M.room, _boite(0.7, 1.1, 1.8), comptoir, cc + Vector3.UP * 0.55)
	_mesh(M.room, _boite(0.8, 0.05, 1.9), laiton, cc + Vector3.UP * 1.12)
	k.col_box(Transform3D(Basis(), cc + Vector3.UP * 0.55), Vector3(0.7, 1.1, 1.8))
	var fer: StandardMaterial3D = _m(M, "fer", Color(0.16, 0.15, 0.14), 0.5, 0.6)
	for g in range(8):
		_mesh(M.room, _cyl(0.006, 0.006, 0.6, 4), fer, cc + Vector3(0, 1.45, 0) + ez * (-0.7 + g * 0.2))
	_mesh(M.room, _boite(0.05, 0.05, 1.8), fer, cc + Vector3.UP * 1.75)
	_texte(M, cc + Vector3.UP * 2.15 - ex * 0.36, -ex, "CAISSE", 70, Color(1.0, 0.85, 0.5))
	var caissier: Node = M.person("homme", hw - 0.6, hd - 1.8, -90.0, "comptoir", "Ambroise")
	caissier.lines = ["Jetons, lots, monnaie. Tout se règle ici.", "Madame Pique n'aime pas les dettes. Moi non plus."]
	_tableau(M, R.P(hw - 0.06, 0, -0.6), -ex, jeux)
	# ---------------------------------------------------------------- les tables, confiées aux jeux
	if jeux != null:
		jeux.table("blackjack", {"centre": cb + Vector3.UP * h + ez * 0.6, "siege": cb + ez * 1.45, "regard": -ez, "parent": M.room, "croupier": dame,
			"adversaires": adv, "mains": mains, "sabot": sabot + Vector3.UP * 0.06})
		jeux.table("caisse", {"centre": cc + Vector3.UP * 1.1, "siege": cc - ex * 1.0, "regard": ex, "parent": M.room, "titre": "La Caisse du Tripot"})
		var assis_pas := func() -> bool: return str(jeux.assis) == ""
		M.act(cb + ez * 1.45 + Vector3.UP * 0.4, "E : jouer au blackjack", func(): jeux.asseoir("blackjack"), 1.3, assis_pas, "Gâchette : jouer au blackjack")
		M.act(cc - ex * 1.0 + Vector3.UP * 0.4, "E : aller à la Caisse", func(): jeux.asseoir("caisse"), 1.4, assis_pas, "Gâchette : aller à la Caisse")
	# le bruit de la salle : des cartes qu'on bat, des jetons, de temps en temps
	M.ctx["t148"] = 4.0
	M.ctx["tick"] = func(delta: float) -> void:
		M.ctx["t148"] = float(M.ctx["t148"]) - delta
		if float(M.ctx["t148"]) <= 0.0:
			M.ctx["t148"] = _r(M).randf_range(7.0, 15.0)
			if jeux == null or str(jeux.assis) == "":
				M.main.sfx("cartes_battre" if _r(M).randf() < 0.5 else "jetons", R.P(_r(M).randf_range(-4.0, 4.0), 0.9, 2.0), -12.0)
	M.ctx["entree"] = str(_pick(M, ["Le Tripot de la Dame de Pique : du velours, un lustre, un piano qui joue en sourdine. Au fond, la Dame de Pique bat les cartes sans les regarder.",
		"Ça sent la cire et la salsepareille. Des chuchotements, des jetons qui claquent, le froissement des cartes. Bienvenue au Tripot.",
		"Le Tripot. Une table de blackjack en demi-lune, un bar, un piano. La Caisse est près de la porte."]))
