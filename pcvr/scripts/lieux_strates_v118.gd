extends RefCounted
## V118 : les grands lieux des Strates et de la Fronde qu'on visite, comme les maisons (maisons_v81 :
## devant la porte, « E : entrer… », un fondu, et l'on est dedans). Chacun a son intérieur, ses gens, ce
## qui bouge et ce qu'on y fait :
##  - LA MARMITE (st_marmite) : la cantine d'Honorine Lanterne (la grande salle, les tables, la cuisine
##    et ses marmites, le tableau du menu ; soupes, galettes, chocolat du mineur ; jamais d'alcool) ;
##  - l'ATELIER DES LUMIÈRES (st_lumieres) : la Docteure Opaline Quartz et ses lanternes à cristal ;
##  - la MAISON DE LA GUILDE (st_guilde) : la grande salle de la Doyenne Agathe Basalte (le registre, la
##    carte des galeries, les blasons) ;
##  - le BUREAU DU CONTREMAÎTRE (st_mine) : la cabane de Ludovic Grisou, à côté du portail des Mines ;
##  - la GRANDE HORLOGE (st_horloge) : la tour de la Place des Rouages, son mécanisme ;
##  - l'ATELIER LIBRE (fr_atelier) : les conteneurs de Bricole, l'inventrice de la Fronde ;
##  - le TROC (fr_troc) : le conteneur de Lumi, la gardienne du Troc, bijoutière de boulons ;
##  - la LOGE DES SOUPAPES (fr_loge) : la chaudière derrière la scène, où le groupe se prépare.
## Chaque lieu est une pièce de maisons_pieces_v81 (style « strates_lieu » ou « fronde_lieu ») bâtie à
## part ; les aides communes sont celles de lieux_hautefond_v116 (L) et de maisons_iles_v82 (I).
## Les fonctions de chaque lieu (_marmite, _lumieres, …) : M est maisons_v81 ; R = M.R la pièce.

const Kit = preload("res://scripts/azur_kit_v56.gd")
const L = preload("res://scripts/lieux_hautefond_v116.gd")
const I = preload("res://scripts/maisons_iles_v82.gd")
const S = preload("res://scripts/maisons_scenes_v81.gd")

const STYLE_ST := "strates_lieu"
const STYLE_FR := "fronde_lieu"
## La taille de la pièce de chaque lieu (largeur, profondeur).
const TAILLES := {"st_marmite": Vector2(12.0, 9.0), "st_lumieres": Vector2(10.0, 8.0), "st_guilde": Vector2(14.0, 7.5),
	"st_mine": Vector2(5.0, 4.0), "st_horloge": Vector2(5.0, 5.0),
	"fr_atelier": Vector2(5.0, 6.0), "fr_troc": Vector2(4.8, 6.0), "fr_loge": Vector2(3.2, 4.0)}
## Ce qui s'affiche devant la porte.
const ENTRER := {"st_marmite": "E : entrer à La Marmite", "st_lumieres": "E : entrer dans l'Atelier des Lumières",
	"st_guilde": "E : entrer dans la Maison de la Guilde", "st_mine": "E : entrer dans le bureau du contremaître",
	"st_horloge": "E : entrer dans la Grande Horloge", "fr_atelier": "E : entrer dans l'Atelier Libre",
	"fr_troc": "E : entrer dans le Troc", "fr_loge": "E : entrer dans la loge des Soupapes"}


static func is_lieu(style: String) -> bool:
	return style == STYLE_ST or style == STYLE_FR


static func taille(cur: Dictionary) -> Vector2:
	return TAILLES.get(str(cur.get("histoire", "")), Vector2(8.0, 7.0))


static func has(sc: String) -> bool:
	return TAILLES.has(sc)


static func style_de(lieu: String) -> String:
	return STYLE_FR if lieu.begins_with("fr_") else STYLE_ST


## Les portes des lieux : « lieu » -> [porte, dehors] (celles des Strates, puis celles de la Fronde).
static func register(portes_st: Dictionary, portes_fr: Dictionary) -> int:
	var n: int = 0
	for portes in [portes_st, portes_fr]:
		for lieu in TAILLES:
			var e: Variant = portes.get(lieu, null)
			if not (e is Array) or (e as Array).size() < 2:
				continue
			var out: Vector3 = e[1]
			out.y = 0.0
			if out.length() < 0.01:
				continue
			var tl: Vector2 = TAILLES[lieu]
			Kit.PORTES_V81.append({"door": e[0], "out": out.normalized(), "w": tl.x, "d": tl.y, "style": style_de(str(lieu)), "floors": 1, "owner": "",
				"histoire": str(lieu), "entrer": str(ENTRER[lieu])})
			n += 1
	return n


# =================================================================== la coque de la pièce

static func shell(M) -> void:
	var R = M.R
	R.pal = (R.pal as Dictionary).duplicate()
	match str(M.ctx.get("scenario", "")):
		"st_marmite":
			R.H = 3.8
			L._mur(M, "sol", "montjoie/bois_planches.png", Color(0.9, 0.82, 0.72), 2.0)
			R.shell()
		"st_lumieres":
			R.H = 3.4
			R.shell()
		"st_guilde":
			R.H = 4.4
			L._mur(M, "sol", "montjoie/dalles.png", Color(0.9, 0.86, 0.8), 2.2)
			R.shell()
		"st_mine":
			R.H = 2.7
			R.pal["fenetre"] = "atelier"
			L._mur(M, "mur", "montjoie/bois_planches.png", Color(0.6, 0.5, 0.4), 2.0)
			L._mur(M, "bas", "montjoie/bois_planches.png", Color(0.55, 0.45, 0.36), 2.0)
			L._mur(M, "sol", "montjoie/bois_planches.png", Color(0.7, 0.6, 0.48), 2.0)
			R.shell()
		"st_horloge":
			R.H = 7.5
			R.pal["fenetre"] = "fente"
			L._mur(M, "mur", "montjoie/pierre_rempart.png", Color(0.85, 0.8, 0.74), 2.5)
			L._mur(M, "bas", "montjoie/pierre_rempart.png", Color(0.8, 0.76, 0.7), 2.5)
			L._mur(M, "sol", "montjoie/dalles_donjon.png", Color(0.8, 0.76, 0.7), 2.0)
			R.shell()
		"fr_atelier":
			R.H = 2.6
			R.shell()
		"fr_troc":
			R.H = 2.6
			L._mur(M, "sol", "montjoie/bois_planches.png", Color(0.7, 0.6, 0.48), 1.8)
			R.shell()
		"fr_loge":
			R.H = 2.4
			R.pal["fenetre"] = "hublot"
			L._mur(M, "mur", "boucan/metal_rivete.png", Color(0.62, 0.6, 0.58), 1.5)
			L._mur(M, "bas", "boucan/metal_rivete.png", Color(0.55, 0.53, 0.52), 1.5)
			L._mur(M, "plafond", "boucan/metal_rivete.png", Color(0.5, 0.48, 0.47), 1.5)
			R.shell()
		_:
			R.shell()


# =================================================================== les aides des Strates

## Le cristal des Strates (bleu, qui luit un peu) ; « violet » pour les cristaux violets de l'Atelier.
static func _cristal(M, violet: bool = false) -> StandardMaterial3D:
	if violet:
		return L._m(M, "cristal118_v", Color(0.75, 0.55, 1.0, 0.85), 0.1, 0.0, 1.2)
	return L._m(M, "cristal118", Color(0.55, 0.8, 1.0, 0.85), 0.1, 0.0, 1.2)


## Une lanterne à cristal (un cadre de fer, un cristal qui luit dedans), pendue ou posée, à « at ».
static func _lanterne(M, at: Vector3, violet: bool = false, lumiere: bool = true) -> Node3D:
	var n: Node3D = I._node(M, at)
	L._mesh(n, L._cylm(0.1, 0.12, 0.3, 8, false), L._m(M, "verre118", Color(0.8, 0.9, 1.0, 0.25), 0.05))
	L._mesh(n, L._cylm(0.13, 0.13, 0.03, 8), L._fer(M), Transform3D(Basis(), Vector3(0, 0.3, 0)))
	L._mesh(n, L._cylm(0.13, 0.13, 0.03, 8), L._fer(M))
	L._mesh(n, I._sph(0.06), _cristal(M, violet), Transform3D(Basis(), Vector3(0, 0.15, 0)))
	for k in range(4):
		var a: float = TAU * k / 4.0
		L._mesh(n, I._boxm(Vector3(0.015, 0.3, 0.015)), L._fer(M), Transform3D(Basis(), Vector3(cos(a) * 0.12, 0.15, sin(a) * 0.12)))
	if lumiere:
		L._lampe(M, at + Vector3(0, 0.15, 0), Color(0.75, 0.6, 1.0) if violet else Color(0.6, 0.8, 1.0), 0.5, 4.0)
	return n


## Un établi de planches sombres (le bois des mines), avec son étau.
static func _etabli_mine(M, x: float, z: float, yaw: float, w: float = 2.2) -> Transform3D:
	var R = M.R
	var k = R.kit
	var xf: Transform3D = R.L(x, 0, z, yaw)
	k.box(xf * Transform3D(Basis(), Vector3(0, 0.88, 0)), Vector3(w, 0.08, 0.8), "bois_sombre", 1.0)
	for sx in [-1.0, 1.0]:
		k.box(xf * Transform3D(Basis(), Vector3(sx * (w * 0.5 - 0.1), 0.42, 0)), Vector3(0.1, 0.84, 0.7), "bois_sombre", 1.0)
	k.box(xf * Transform3D(Basis(), Vector3(w * 0.5 - 0.3, 0.99, 0.2)), Vector3(0.22, 0.14, 0.14), "fer", 1.0)
	k.col_box(xf * Transform3D(Basis(), Vector3(0, 0.45, 0)), Vector3(w, 0.9, 0.8))
	R.reserve(x, z, w + 0.2, 1.0)
	return xf


# =================================================================== construire

static func build(M, sc: String) -> void:
	match sc:
		"st_marmite":
			_marmite(M)
		"st_lumieres":
			_lumieres(M)
		"st_guilde":
			_guilde(M)
		"st_mine":
			_mine(M)
		"st_horloge":
			_horloge(M)
		"fr_atelier":
			_atelier(M)
		"fr_troc":
			_troc(M)
		"fr_loge":
			_loge(M)


# =================================================================== V118 (partie A) : La Marmite, l'Atelier des Lumières, la Maison de la Guilde

## Les menus de l'ardoise de La Marmite (on les lit l'un après l'autre).
const MENU_MARMITE := ["L'ARDOISE DE LA MARMITE. Bouillon des Strates (il tient au corps, et au bol). Galettes des Rouages, croustillantes comme un engrenage neuf. Chocolat du mineur : la cuillère tient debout toute seule. Sirop de la Cascade pour les petits et les grands. Pas une goutte de boisson forte : sous terre, on garde la tête claire et le pied sûr.",
	"MENU DU LUNDI. Bouillon des Strates aux champignons bruns de Bertille (pas ceux qui brillent). Galette des Rouages au fromage. Dessert : chocolat du mineur. Rappel : on ne mange jamais un champignon qui fait de l'œil.",
	"MENU DES FORGERONS. Double bouillon, double galette, et un bol « pour le marteau-pilon » (demandez à Maîtresse Brunehaut). Sirop de la Cascade à volonté. Ceux qui chantent la bouche pleine seront servis en dernier.",
	"MENU DU SOIR. Soupe du jour (c'est celle de midi, mais elle a eu le temps de réfléchir). Galettes chaudes. Chocolat du mineur. En bas, en petites lettres : « Tu as maigri. Reprends un bol. » Signé : Honorine."]

## Les pages du grand registre de la Guilde (on les lit l'une après l'autre).
const REGISTRE_GUILDE := ["LE GRAND REGISTRE DE LA GUILDE, page des métiers. Mineurs, forgerons, lampistes, cristalliers, cheminots, cantiniers, jardiniers de l'ombre. Et, depuis cette année : « liftier, mais il faut parler fort » (Anatole Crémaillère).",
	"LE GRAND REGISTRE, les disputes réglées. Affaire du banc de travers, à La Marmite : Maîtresse Brunehaut garde le banc, Honorine garde le dernier mot. Affaire du champignon trop brillant : Bertille et la Docteure Opaline sont déclarées ex aequo. Le petit Tom a servi de jury.",
	"LE GRAND REGISTRE, les records de descente. Le plus rapide : la cabine d'Anatole, deux minutes et dix secondes. Le plus lent : le Bourgmestre Hector, quarante minutes, à cause du discours. Le plus joyeux : une classe de Hautefond, qui a chanté tout le long.",
	"LE GRAND REGISTRE, page des inventions. La lanterne qui clignote en rythme (Docteure Opaline, pour les Soupapes). Le casque pot-à-crayons (même auteure, sans le faire exprès). La galette en forme d'engrenage, qui ne roule jamais : elle est mangée avant.",
	"LE GRAND REGISTRE, dernière page écrite, de la main de la Doyenne : « La Ligne a rouvert. Ils descendent. Ils regardent. Ils reviennent. Bien. » En dessous, plus petit : « J'ai souri. Deux millimètres. »"]

## Le blason accroché au fond de la Maison de la Guilde.
const GUILDE_BLASON_TEX := "strates/enseigne_guilde.png"


## Toujours dans la même pièce ? (après un délai, on a pu sortir… ou entrer dans un autre lieu)
static func _la(M, room0) -> bool:
	return is_instance_valid(room0) and M.inside and M.room == room0


# =================================================================== les aides de la partie A

## Une lanterne à cristal pendue à une chaîne, sous « top » (le plafond, une poutre), qui se balance.
static func _marmite_pendre(M, top: Vector3, drop: float, violet: bool, lumiere: bool, phase: float) -> Node3D:
	var piv: Node3D = I._node(M, top)
	var lan: Node3D = _lanterne(M, top - Vector3(0, drop, 0), violet, false)
	lan.reparent(piv)
	var ch: float = maxf(drop - 0.33, 0.05)
	L._mesh(piv, L._cylm(0.006, 0.006, ch, 4), L._fer(M), Transform3D(Basis(), Vector3(0, -ch * 0.5, 0)))
	if lumiere:
		var c: Color = Color(0.75, 0.6, 1.0) if violet else Color(0.6, 0.8, 1.0)
		L._lampe(M, top - Vector3(0, drop - 0.15, 0), c, 0.45, 4.5)
	L._balance(M, piv, Vector3.FORWARD, 0.04, 4.0 + phase, phase)
	return piv


## De la vapeur qui monte (les marmites) : de petites bouffées blanches.
static func _marmite_vapeur(M, at: Vector3, ext: Vector3, n: int) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = n
	p.lifetime = 2.6
	p.preprocess = 2.6
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = ext
	p.direction = Vector3.UP
	p.spread = 18.0
	p.gravity = Vector3(0, 0.12, 0)
	p.initial_velocity_min = 0.05
	p.initial_velocity_max = 0.15
	p.scale_amount_min = 0.08
	p.scale_amount_max = 0.18
	var qm := QuadMesh.new()
	qm.size = Vector2.ONE
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.billboard_keep_scale = true
	m.albedo_color = Color(1, 1, 1, 0.35)
	m.albedo_texture = M.R.dot_texture()
	qm.material = m
	p.mesh = qm
	M.room.add_child(p)
	p.global_position = at
	return p


## Une image (une fresque, un blason) : une matière à texture ; « alpha » : le fond est transparent.
static func _marmite_tex(M, tex: String, alpha: bool = false) -> StandardMaterial3D:
	var key: String = "tex118a_" + tex
	if not M.ctx.has("mats116"):
		M.ctx["mats116"] = {}
	var cache: Dictionary = M.ctx["mats116"]
	if cache.has(key):
		return cache[key]
	var m := StandardMaterial3D.new()
	var p: String = "res://assets/textures/" + tex
	if ResourceLoader.exists(p):
		m.albedo_texture = load(p)
	else:
		m.albedo_color = Color(0.5, 0.42, 0.34)
	if alpha:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		m.alpha_scissor_threshold = 0.4
	m.roughness = 0.8
	cache[key] = m
	return m


## Un panneau plat (xf : son centre ; il regarde +Z).
static func _marmite_panneau(M, xf: Transform3D, size: Vector2, mat: Material) -> MeshInstance3D:
	var qm := QuadMesh.new()
	qm.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = qm
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	M.room.add_child(mi)
	mi.global_transform = xf
	return mi


## Une longue table de cantine en bois sombre, sur tréteaux (x, z : repère de la pièce).
static func _marmite_table(M, x: float, z: float, w: float, d: float) -> void:
	var R = M.R
	var k = R.kit
	var xf: Transform3D = R.L(x, 0, z)
	k.box(xf * Transform3D(Basis(), Vector3(0, 0.73, 0)), Vector3(w, 0.07, d), "bois_sombre", 1.0)
	for sx in [-1.0, 1.0]:
		k.box(xf * Transform3D(Basis(), Vector3(sx * (w * 0.5 - 0.3), 0.35, 0)), Vector3(0.1, 0.7, d - 0.2), "bois_sombre", 1.0)
	k.box(xf * Transform3D(Basis(), Vector3(0, 0.2, 0)), Vector3(w - 0.6, 0.06, 0.08), "bois_sombre", 1.0)
	k.col_box(xf * Transform3D(Basis(), Vector3(0, 0.38, 0)), Vector3(w, 0.76, d))
	R.reserve(x, z, w + 0.2, d + 1.6)


## Un banc de cantine (le long de la table) ; « renverse » : posé à l'envers sur la table (la nuit).
static func _marmite_banc(M, x: float, z: float, w: float, renverse: bool) -> void:
	var R = M.R
	var k = R.kit
	var xf: Transform3D = R.L(x, 0, z)
	if renverse:
		xf = R.L(x, 0.765, z) * Transform3D(Basis(Vector3.RIGHT, PI), Vector3(0, 0.47, 0))
	k.box(xf * Transform3D(Basis(), Vector3(0, 0.44, 0)), Vector3(w, 0.06, 0.34), "bois_sombre", 1.0)
	for sx in [-1.0, 1.0]:
		k.box(xf * Transform3D(Basis(), Vector3(sx * (w * 0.5 - 0.15), 0.21, 0)), Vector3(0.06, 0.42, 0.3), "bois_sombre", 1.0)
	if not renverse:
		k.col_box(xf * Transform3D(Basis(), Vector3(0, 0.23, 0)), Vector3(w, 0.46, 0.34))


## Un plateau de bols qu'on porte (le gamin de La Marmite) : un nœud sur le corps.
static func _marmite_plateau(M, f: Node) -> Node3D:
	var n := Node3D.new()
	f.npc.add_child(n)
	L._mesh(n, L._cylm(0.17, 0.17, 0.02, 14), L._m(M, "plateau118a", Color(0.5, 0.36, 0.24), 0.7), Transform3D(Basis(), Vector3(0, 0.8, 0.3)))
	for k2 in range(2):
		L._mesh(n, L._cylm(0.06, 0.045, 0.06, 12), L._m(M, "bol118a", Color(0.93, 0.89, 0.8), 0.4), Transform3D(Basis(), Vector3(-0.07 + k2 * 0.14, 0.84, 0.3)))
	return n


## Une ligne de laiton gravée sur une plaque (la carte des galeries) : de a à b (en mètres, sur la plaque).
static func _guilde_trait(M, plaque: Transform3D, a: Vector2, b: Vector2, ep: float = 0.022) -> void:
	var d: Vector2 = b - a
	if d.length() < 0.001:
		return
	var mid: Vector2 = (a + b) * 0.5
	M.R.kit.box(plaque * Transform3D(Basis(Vector3.BACK, atan2(d.y, d.x)), Vector3(mid.x, mid.y, 0.045)), Vector3(d.length() + ep * 0.6, ep, 0.012), "or", 1.0)


# =================================================================== La Marmite

## La Marmite, la cantine d'Honorine Lanterne : de longues tables de bois sombre et leurs bancs, les
## lanternes à cristal pendues aux poutres, l'ardoise du menu, la cuisine au fond (le fourneau de fonte,
## ses marmites qui fument, la louche qui tourne dans la grande, les casseroles de cuivre), le comptoir ;
## le jour, la cantinière, deux mineurs attablés et le gamin qui sert ; la nuit, les bancs à l'envers sur
## les tables, et Honorine (ou son aide) qui récure.
static func _marmite(M) -> void:
	var R = M.R
	var k = R.kit
	var nuit: bool = L._nuit(M)
	var room0 = M.room
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	# la cuisine au fond : le grand fourneau de fonte, ses portes, son tuyau
	var fx: Transform3D = R.L(2.8, 0, -hd + 0.45)
	k.box(fx * Transform3D(Basis(), Vector3(0, 0.45, 0)), Vector3(3.6, 0.9, 0.8), "fer", 1.0)
	k.box(fx * Transform3D(Basis(), Vector3(0, 0.92, 0)), Vector3(3.7, 0.04, 0.86), "metal", 1.0)
	for i in range(3):
		k.box(fx * Transform3D(Basis(), Vector3(-1.2 + i * 1.2, 0.42, 0.405)), Vector3(0.5, 0.32, 0.01), "flamme" if i == 1 else "noir", 1.0, 16)
		k.box(fx * Transform3D(Basis(), Vector3(-1.2 + i * 1.2, 0.62, 0.42)), Vector3(0.3, 0.03, 0.03), "cuivre", 1.0)
	k.cyl(fx * Transform3D(Basis(), Vector3(1.55, 0.94, -0.25)), 0.1, 0.1, R.H - 0.94, "fer", 10, false)
	k.col_box(fx * Transform3D(Basis(), Vector3(0, 0.45, 0)), Vector3(3.6, 0.9, 0.8))
	L._lampe(M, fx * Vector3(0, 0.5, 0.9), Color(1.0, 0.58, 0.28), 0.7, 4.0)
	# les marmites : la grande (de fonte, le bouillon), la moyenne (de cuivre, couverte), la petite (le chocolat)
	var pot: Vector3 = fx * Vector3(-0.9, 0.94, 0)
	k.cyl(Transform3D(Basis(), pot), 0.34, 0.37, 0.42, "fer", 18, false)
	k.ring(Transform3D(Basis(), pot + Vector3.UP * 0.4), 0.33, 0.38, 0.03, "fer", 18)
	k.cyl(Transform3D(Basis(), pot + Vector3.UP * 0.34), 0.335, 0.335, 0.01, "soupe", 18)
	for s in [-1.0, 1.0]:
		k.box(Transform3D(Basis(), pot + Vector3(s * 0.4, 0.33, 0)), Vector3(0.08, 0.04, 0.12), "fer", 1.0)
	var pot2: Vector3 = fx * Vector3(0.3, 0.94, 0)
	k.cyl(Transform3D(Basis(), pot2), 0.24, 0.25, 0.3, "cuivre", 16)
	k.cyl(Transform3D(Basis(), pot2 + Vector3.UP * 0.3), 0.25, 0.2, 0.05, "cuivre", 16)
	k.cyl(Transform3D(Basis(), pot2 + Vector3.UP * 0.35), 0.03, 0.03, 0.05, "fer", 8)
	var pot3: Vector3 = fx * Vector3(1.05, 0.94, 0.05)
	k.cyl(Transform3D(Basis(), pot3), 0.18, 0.19, 0.22, "cuivre", 14, false)
	k.cyl(Transform3D(Basis(), pot3 + Vector3.UP * 0.18), 0.175, 0.175, 0.01, "chocolat", 14)
	k.box(Transform3D(Basis(), pot3 + Vector3(0.28, 0.16, 0)), Vector3(0.22, 0.03, 0.04), "fer", 1.0)
	var vap: CPUParticles3D = _marmite_vapeur(M, pot + Vector3.UP * 0.5, Vector3(0.2, 0.04, 0.2), 16)
	_marmite_vapeur(M, pot3 + Vector3.UP * 0.25, Vector3(0.1, 0.03, 0.1), 6)
	# la louche qui tourne dans la grande marmite
	var lpiv: Node3D = I._node(M, pot + Vector3.UP * 0.34)
	L._mesh(lpiv, L._cylm(0.012, 0.012, 0.75, 6), L._fer(M), Transform3D(Basis(Vector3.BACK, -0.35), Vector3(0.22, 0.32, 0)))
	L._mesh(lpiv, I._sph(0.07), L._fer(M), Transform3D(Basis.from_scale(Vector3(1, 0.6, 1)), Vector3(0.1, -0.02, 0)))
	L._tourne(M, lpiv, Vector3.UP, 0.5, true)
	# les casseroles de cuivre pendues au mur du fond, et la grande louche à son crochet
	k.box(R.L(2.8, 2.05, -hd + 0.12), Vector3(3.6, 0.04, 0.04), "fer", 1.0)
	for i2 in range(5):
		var cxp: float = 1.5 + i2 * 0.65
		var rr: float = 0.09 + (i2 % 3) * 0.03
		k.box(R.L(cxp, 2.05 - 0.09, -hd + 0.1), Vector3(0.025, 0.18, 0.025), "cuivre", 1.0)
		k.cyl(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), R.P(cxp, 1.83 - rr, -hd + 0.08)), rr, rr, 0.06, "cuivre", 14)
	k.box(R.L(1.0, 1.7, -hd + 0.1), Vector3(0.03, 0.7, 0.03), "fer", 1.0)
	k.cyl(R.L(1.0, 1.28, -hd + 0.14), 0.09, 0.06, 0.08, "fer", 12, false)
	R.mark_wall(2.7, 1.9, -hd, 1.9)
	# le comptoir, devant la cuisine : les bols empilés, la corbeille de galettes, les tasses de chocolat
	var cx: Transform3D = R.L(2.8, 0, -2.5)
	k.box(cx * Transform3D(Basis(), Vector3(0, 0.52, 0)), Vector3(3.6, 1.04, 0.6), "bois_sombre", 1.0)
	k.box(cx * Transform3D(Basis(), Vector3(0, 1.06, 0.02)), Vector3(3.8, 0.05, 0.72), "bois", 1.0)
	k.box(cx * Transform3D(Basis(), Vector3(0, 0.12, 0.33)), Vector3(3.6, 0.04, 0.04), "cuivre", 1.0)
	k.col_box(cx * Transform3D(Basis(), Vector3(0, 0.55, 0)), Vector3(3.6, 1.1, 0.6))
	R.reserve(2.8, -3.3, 4.4, 2.6)
	for j in range(5):
		k.cyl(cx * Transform3D(Basis(), Vector3(-1.4, 1.085 + j * 0.045, 0.0)), 0.1, 0.075, 0.05, "ceramique", 12)
	k.cyl(cx * Transform3D(Basis(), Vector3(-0.4, 1.085, 0.05)), 0.2, 0.16, 0.09, "bois_clair", 14)
	for j2 in range(4):
		k.cyl(cx * Transform3D(Basis(Vector3.RIGHT, 0.3 * (j2 % 2)), Vector3(-0.5 + j2 * 0.07, 1.15 + (j2 % 2) * 0.02, 0.05)), 0.09, 0.09, 0.02, "pain", 12)
	for j3 in range(3):
		var tp: Vector3 = cx * Vector3(0.6 + j3 * 0.22, 1.085, 0.12)
		k.cyl(Transform3D(Basis(), tp), 0.045, 0.04, 0.09, "ceramique", 10, false)
		k.cyl(Transform3D(Basis(), tp + Vector3.UP * 0.075), 0.042, 0.042, 0.005, "chocolat", 10)
	# l'ardoise du menu (mur du fond, à gauche de la cuisine)
	var ax: Transform3D = R.L(-0.6, 1.95, -hd + 0.04)
	k.box(ax, Vector3(1.5, 1.0, 0.03), "noir", 1.0)
	for s2 in [-1.0, 1.0]:
		k.box(ax * Transform3D(Basis(), Vector3(s2 * 0.78, 0, 0.01)), Vector3(0.06, 1.12, 0.04), "bois_sombre", 1.0)
		k.box(ax * Transform3D(Basis(), Vector3(0, s2 * 0.53, 0.01)), Vector3(1.62, 0.06, 0.04), "bois_sombre", 1.0)
	k.box(ax * Transform3D(Basis(), Vector3(0, 0.36, 0.02)), Vector3(0.9, 0.05, 0.005), "ceramique", 1.0)
	for li in range(5):
		k.box(ax * Transform3D(Basis(), Vector3(-0.2 + (li % 2) * 0.06, 0.18 - li * 0.13, 0.02)), Vector3(0.85 - (li % 3) * 0.18, 0.025, 0.005), "ceramique", 1.0)
		k.box(ax * Transform3D(Basis(), Vector3(0.55, 0.18 - li * 0.13, 0.02)), Vector3(0.1, 0.025, 0.005), "tissu_jaune", 1.0)
	R.mark_wall(-0.6, 1.95, -hd, 0.85)
	# une fresque des Strates (mur de gauche, entre les fenêtres), les bocaux (mur de droite)
	_marmite_panneau(M, R.L(-hw + 0.03, 1.9, 0.0, 90), Vector2(1.7, 1.0), _marmite_tex(M, "strates/fresque_1.png"))
	R.mark_wall(-hw, 1.9, 0.0, 0.95)
	R.etagere_murale(hw - 0.14, 1.45, 0.0, -90, 1.6, "terre_cuite", 6)
	R.etagere_murale(hw - 0.14, 1.95, 0.0, -90, 1.6, "verre", 5)
	# les longues tables et leurs bancs (à l'envers sur les tables, la nuit)
	var tables: Array = [[-2.6, -1.4, 3.4], [-2.6, 1.4, 3.4], [2.6, 1.0, 2.8]]
	for t in tables:
		var tx: float = float(t[0])
		var tz: float = float(t[1])
		var tw: float = float(t[2])
		_marmite_table(M, tx, tz, tw, 0.85)
		for sz in [-1.0, 1.0]:
			if nuit:
				_marmite_banc(M, tx, tz + sz * 0.2, tw - 0.3, true)
			else:
				_marmite_banc(M, tx, tz + sz * 0.62, tw - 0.3, false)
	if not nuit:
		# les bols des mineurs, et une galette
		for b in [Vector2(-3.2, -1.15), Vector2(-2.0, -1.65), Vector2(-1.7, 1.2)]:
			k.cyl(R.L(b.x, 0.765, b.y), 0.09, 0.07, 0.06, "ceramique", 12, false)
			k.cyl(R.L(b.x, 0.81, b.y), 0.085, 0.085, 0.005, "soupe", 12)
		k.cyl(R.L(-2.6, 0.765, -1.4), 0.1, 0.1, 0.02, "pain", 12)
	# les lanternes à cristal pendues aux poutres, une lumière chaude au milieu
	var pend: Array = [[-3.43, -1.4, false, true], [-1.71, -1.4, true, false], [-3.43, 1.4, true, false], [-1.71, 1.4, false, true], [1.71, 1.0, false, false], [3.43, 1.0, true, true], [0.0, -0.2, false, false]]
	for e in pend:
		_marmite_pendre(M, R.P(float(e[0]), R.H - 0.24, float(e[1])), 1.15, bool(e[2]), bool(e[3]) and not nuit, float(e[0]) + float(e[1]))
	L._lampe(M, R.P(0, 2.9, 0.2), Color(1.0, 0.86, 0.62), 0.75 if not nuit else 0.35, 9.0)
	var bulle: Label3D = L._etiquette(M, pot + Vector3.UP * 1.1, "Bloup ! Bloup !")
	# les gens
	if nuit:
		var hon: Node = L._patron(M, 2.4, -3.15, 180.0, "cuisiner", ["Ah, de la visite ! On est fermé, mais pas pour toi, mon petit. Assieds-toi. Il reste du bouillon. Il reste toujours du bouillon.",
			"Bonsoir ! Je récure la grande marmite. Elle a nourri trois cents personnes aujourd'hui. Elle mérite un bain.",
			"Entre, ne reste pas dans le courant d'air ! Je range les bancs. Il en reste toujours un de travers : celui de Brunehaut."])
		if hon == null:
			var aide: Node = L._gens(M, "femme", 2.4, -3.15, 180.0, "cuisiner", ["Je récure la grande marmite. Elle est si grande que je pourrais m'asseoir dedans. Je l'ai fait, une fois. Honorine n'a rien dit. Elle a juste rajouté du sel.",
				"Les bancs dorment sur les tables. Demain, à cinq heures, Honorine rallume les fourneaux. Les mineurs arrivent à six."])
			L._causer(M, aide, ["Bonsoir ! La Marmite est fermée, mais la casserole de chocolat est encore tiède. Ne le dis à personne.", "Bon fond ! Attention, le sol est mouillé : je viens de passer la serpillière. Glisse doucement."],
				[["honorine", "Honorine n'est pas là ?", ["Elle est rentrée chez elle, dans les Galeries. Elle rallume les fourneaux à cinq heures. La première soupe est pour les mineurs, la deuxième pour les forgerons, la troisième pour le petit Tom. Il croit que c'est le hasard."]],
				["chocolat", "Il reste vraiment du chocolat ?", ["Un fond de casserole, épais comme du mortier. La cuillère tient debout toute seule. C'est comme ça qu'on sait qu'il est réussi. Honorine dit qu'un chocolat où la cuillère se couche, c'est une boisson. Ici, on sert des repas."]]])
		R.chat(1.0, -3.3, 30, Color(0.85, 0.55, 0.3), true, 0.0)
		M.ctx["entree"] = "La Marmite, la nuit : les bancs dorment à l'envers sur les tables, les lanternes luisent tout bas, et la grande marmite fume encore un peu, comme si elle rêvait de soupe."
	else:
		var hon2: Node = L._patron(M, 2.8, -3.15, 0.0, "comptoir", ["Entre, entre, ne reste pas dans le courant d'air ! Tu as mangé ? Non. Je le vois. Assieds-toi, je t'apporte un bol.",
			"Te voilà, mon petit ! Tu as maigri. Si, si. Depuis hier. Va lire l'ardoise, et choisis : tout est chaud.",
			"Bonne descente ! Ici, on mange chaud, on boit chaud, et on repart le cœur chaud. Pas une goutte de boisson forte : sous terre, on garde la tête claire."])
		if hon2 == null:
			var serv: Node = L._gens(M, "femme", 2.8, -3.15, 0.0, "comptoir", ["Un bouillon, un ! Et une galette pour le petit, il a l'air d'avoir creusé toute la matinée.", "Ici, on ne demande pas « tu as faim ? ». On demande « combien de bols ? »."])
			L._causer(M, serv, ["Bonne descente ! Bienvenue à La Marmite ! Assieds-toi où tu veux : tous les bancs sont de bons bancs. Sauf celui de travers : c'est celui de Maîtresse Brunehaut.", "Bon fond ! Honorine est partie aux Jardins, je garde les marmites. Tu as mangé ? Non ? Je le vois."],
				[["menu", "Qu'est-ce qu'il y a à manger ?", ["Tout est sur l'ardoise ! Le bouillon des Strates, les galettes des Rouages, le chocolat du mineur, et le sirop de la Cascade pour les petits. Pas une goutte de boisson forte : sous terre, on garde la tête claire et le pied sûr."]],
				["honorine", "Où est Honorine ?", ["Elle est partie chercher les champignons bruns chez Bertille, aux Jardins. Elle revient toujours avec un panier plein et trois histoires. Les champignons, elle les met dans la soupe. Les histoires aussi."]],
				["chocolat", "C'est vrai que la cuillère tient debout ?", ["Dans le chocolat du mineur ? Bien sûr ! Si elle tombe, on le refait. Honorine dit qu'un chocolat où la cuillère se couche, c'est une boisson. Ici, on sert des repas."]]])
		var min1: Node = L._gens(M, "homme", -3.2, -0.78, 180.0, "manger", ["Mmm… Le bouillon d'Honorine. Après huit heures de mine, c'est comme un deuxième casque, mais pour l'intérieur.", "Par les Strates ! Elle a encore mis des champignons bruns. Les meilleurs."])
		L._causer(M, min1, ["Bonne descente, l'ami ! Assieds-toi, il y a de la place sur le banc. Pousse-toi, Gustin.", "Bon fond ! Tu viens d'en haut ? Ça se voit : tu ne t'es pas encore cogné la tête aux poutres."],
			[["mine", "C'est dur, la mine ?", ["Dur, non. Long, oui. On creuse doucement, on dit bonjour à la Vieille, la roche, et on remonte avec des cristaux. Le contremaître Ludovic compte les jours sans accident. Quatre mille deux cents. Il en est plus fier que de sa barbe."]],
			["vieille", "Qui est la Vieille ?", ["La roche ! Ludovic lui parle tous les matins : bonjour, merci, pardon. Au début, on riait. Maintenant, on fait tous pareil. Elle n'a jamais répondu. Mais elle ne nous est jamais tombée dessus non plus."]],
			["marmite", "Pourquoi « La Marmite » ?", ["Parce qu'à midi, toute la caverne descend ici, et ça bouillonne comme une marmite ! Et Honorine dit que les gens, c'est comme la soupe : ça n'est bon que tous ensemble."]]])
		L._gens(M, "homme", -2.0, -2.02, 0.0, "rire_assis", ["Ha ha ! Gustin s'est fait une moustache de chocolat. Ne lui dis pas, c'est plus drôle.", "Le chocolat du mineur se mange à la cuillère. Si tu essaies de le boire, il te regarde de travers."])
		var gam: Node = L._gens(M, "garcon", 0.9, -1.8, 0.0, "marcher", ["Attention, bol chaud ! Pardon ! Bol chaud qui passe !", "Honorine me paie en galettes. C'est le meilleur métier des Strates."])
		var pl: Node3D = _marmite_plateau(M, gam)
		L._va_et_vient(M, gam, R.P(0.9, 0, -1.8), R.P(-0.6, 0, 0.1), 0.9, 2.5, pl)
		L._causer(M, gam, ["Bonne descente ! Je ne peux pas parler longtemps : j'ai deux bols qui refroidissent.", "Bon fond ! Tu veux une galette ? Demande au comptoir, moi je porte."],
			[["metier", "Tu travailles ici ?", ["J'aide Honorine après l'école ! Je porte les bols, j'essuie les tables, et je goûte le chocolat pour vérifier. C'est le plus important. Quelqu'un doit le faire."]]])
		M.ctx["entree"] = str(L._pick(M, ["La Marmite : de longues tables de bois sombre, des lanternes à cristal pendues aux poutres, et au fond, un grand fourneau où fument les marmites. Ça sent le bouillon jusque dans la rue.",
			"« Un bouillon, un ! » La cantine bourdonne : les mineurs mangent, la vapeur monte, et la louche tourne toute seule dans la grande marmite.",
			"Bonne descente ! À La Marmite, il fait chaud, ça sent la galette, et quelqu'un te demande déjà si tu as mangé."]))
	# ce qu'on fait : goûter le bouillon, lire l'ardoise, remuer la marmite
	M.act(R.P(2.0, 1.0, -1.95), "E : goûter le bouillon", func() -> void:
		M.main.sfx("boire", R.P(2.0, 1.0, -2.2))
		var st: Dictionary = M.state()
		if not bool(st.get("bouillon118", false)):
			st["bouillon118"] = true
			M.give([["bouillon_strates", 1]], "« Goûte, c'est la maison qui offre ! » On te tend un bol de bouillon des Strates, si chaud qu'il fume jusqu'aux poutres. Il tient au corps, et au bol :\n")
		else:
			M.say(str(L._pick(M, ["Mmm… Un bouillon épais, doré, aux champignons bruns. Il réchauffe jusqu'aux orteils, même ceux qui sont restés en haut.",
				"Tu goûtes une cuillère. Puis deux. Puis tu ne comptes plus. « Encore un bol ? », te demande-t-on. On le demande toujours.",
				"Le bouillon des Strates a un goût de grès chaud, de champignon et de dimanche. Ne demande pas comment : c'est le secret d'Honorine."])), 6.0)
	, 1.5)
	M.act(R.P(-0.6, 1.3, -hd + 0.9), "E : lire l'ardoise", func() -> void:
		M.main.sfx("ui_ouvrir", R.P(-0.6, 1.9, -hd + 0.2))
		var n: int = int(M.ctx.get("menu118", L._r(M).randi() % MENU_MARMITE.size()))
		M.ctx["menu118"] = n + 1
		M.say(str(MENU_MARMITE[n % MENU_MARMITE.size()]), 9.0)
	, 1.3)
	M.act(R.P(1.3, 1.0, -3.2), "E : remuer la marmite", func() -> void:
		if bool(M.ctx.get("remue118", false)):
			return
		M.ctx["remue118"] = true
		M.main.sfx("louche", pot)
		M.main.sfx("vapeur", pot)
		M.ctx["vite116"] = 6.0
		if is_instance_valid(vap):
			vap.amount = 48
			vap.initial_velocity_max = 0.6
		L._montrer(M, bulle, 2.5)
		M.say(str(L._pick(M, ["Tu prends la grande louche et tu remues. Bloup, bloup : la marmite gronde de plaisir et souffle un grand nuage de vapeur jusqu'aux poutres. Ça sent le bouillon jusqu'à la Place des Rouages.",
			"Tu remues trois fois dans un sens, trois fois dans l'autre : c'est comme ça qu'Honorine fait. La vapeur monte en tourbillon, et quelqu'un, derrière toi, dit « Mmmh ! » sans le faire exprès.",
			"La louche fait le tour de la marmite, la soupe chante « bloup », et la vapeur embrume les lanternes. Pendant un instant, La Marmite ressemble à un nuage qui sent bon."])), 6.0)
		await M.get_tree().create_timer(3.0).timeout
		if not _la(M, room0):
			return
		M.ctx["vite116"] = 1.0
		if is_instance_valid(vap):
			vap.amount = 16
			vap.initial_velocity_max = 0.15
		M.ctx["remue118"] = false
	, 1.5)


# =================================================================== l'Atelier des Lumières

## L'Atelier des Lumières, chez la Docteure Opaline Quartz : des lanternes à cristal partout (bleues et
## violettes, sur l'étagère, par terre, pendues), le grand établi (la loupe sur son bras, les bacs de
## cristaux bruts, le bec de gaz et sa petite flamme, le tour à polir qui tourne), la vitrine des
## cristaux taillés qui respirent, le comptoir (une lanterne éteinte, le casque-pot-à-crayons) ; le jour,
## Opaline (ou son apprentie) et une cliente ; la nuit, l'apprentie qui range, ou Opaline qui veille.
static func _lumieres(M) -> void:
	var R = M.R
	var k = R.kit
	var nuit: bool = L._nuit(M)
	var room0 = M.room
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	# le grand établi (au fond)
	var ex: Transform3D = _etabli_mine(M, 1.4, -hd + 0.65, 0.0, 2.6)
	# la loupe sur son bras (à gauche de l'établi)
	var lb: Vector3 = ex * Vector3(-0.95, 0.92, -0.2)
	k.cyl(Transform3D(Basis(), lb), 0.07, 0.08, 0.03, "fer", 10)
	k.cyl(Transform3D(Basis(Vector3.BACK, -0.5), lb), 0.012, 0.012, 0.55, "or", 6, false)
	var lens: Vector3 = lb + Vector3(0.26, 0.47, 0)
	k.ring(Transform3D(Basis(Vector3.BACK, 0.9), lens), 0.09, 0.115, 0.02, "or", 18)
	k.cyl(Transform3D(Basis(Vector3.BACK, 0.9), lens), 0.09, 0.09, 0.005, "verre", 18, true)
	L._lampe(M, lens + Vector3(0.1, -0.15, 0.1), Color(0.75, 0.85, 1.0), 0.5, 2.4)
	# le bec de gaz et sa petite flamme bleue (elle vacille)
	var bg: Vector3 = ex * Vector3(-0.45, 0.92, -0.25)
	k.cyl(Transform3D(Basis(), bg), 0.05, 0.06, 0.04, "fer", 10)
	k.cyl(Transform3D(Basis(), bg + Vector3.UP * 0.04), 0.015, 0.015, 0.2, "cuivre", 8)
	var fl: Node3D = I._node(M, bg + Vector3.UP * 0.24)
	L._mesh(fl, L._cylm(0.0, 0.022, 0.07, 8), L._m(M, "flamme118a", Color(0.5, 0.72, 1.0, 0.9), 0.5, 0.0, 3.0), Transform3D(Basis(), Vector3(0, 0.035, 0)))
	L._mesh(fl, L._cylm(0.0, 0.012, 0.04, 6), L._m(M, "flamme118b", Color(1.0, 0.85, 0.5), 0.5, 0.0, 3.0), Transform3D(Basis(), Vector3(0, 0.02, 0)))
	L._chaque(M, func(_delta: float, t: float) -> void:
		if is_instance_valid(fl):
			fl.scale = Vector3(1.0, 1.0 + 0.18 * sin(t * 13.0) + 0.08 * sin(t * 29.0), 1.0))
	# les bacs de cristaux bruts (sur l'établi, et par terre à côté)
	var bac: Vector3 = ex * Vector3(0.05, 0.92, -0.15)
	k.box(Transform3D(Basis(), bac + Vector3.UP * 0.06), Vector3(0.42, 0.12, 0.3), "bois", 1.0)
	for c in range(6):
		var cp: Vector3 = bac + Vector3(-0.14 + (c % 3) * 0.14, 0.1, -0.06 + int(c / 3) * 0.12)
		k.cyl(Transform3D(Basis(Vector3(1, 0, 1).normalized(), 0.25 * ((c % 3) - 1)), cp), 0.035, 0.0, 0.12 + (c % 2) * 0.04, "cristal", 6)
	var bac2: Vector3 = R.P(3.5, 0, -hd + 0.7)
	k.box(Transform3D(Basis(), bac2 + Vector3.UP * 0.2), Vector3(0.7, 0.4, 0.5), "bois", 1.0)
	k.col_box(Transform3D(Basis(), bac2 + Vector3.UP * 0.2), Vector3(0.7, 0.4, 0.5))
	R.reserve(3.5, -hd + 0.7, 0.9, 0.7)
	for c2 in range(7):
		var cp2: Vector3 = bac2 + Vector3(-0.24 + (c2 % 4) * 0.16, 0.38, -0.1 + int(c2 / 4) * 0.2)
		L._mesh(I._node(M, cp2), L._cylm(0.0, 0.05, 0.2 + (c2 % 3) * 0.05, 6), _cristal(M, c2 % 3 == 0), Transform3D(Basis(Vector3.BACK, 0.2 * ((c2 % 3) - 1)), Vector3(0, 0.1, 0)))
	# le tour à polir : sa meule qui tourne, un cristal contre elle
	var tour: Vector3 = ex * Vector3(0.6, 0.92, 0.05)
	k.box(Transform3D(Basis(), tour + Vector3.UP * 0.08), Vector3(0.26, 0.16, 0.2), "fer", 1.0)
	k.cyl(Transform3D(Basis(Vector3.BACK, PI * 0.5), tour + Vector3(0.16, 0.3, 0)), 0.015, 0.015, 0.32, "metal", 8)
	var meule: Node3D = I._node(M, tour + Vector3(0.0, 0.3, 0))
	L._mesh(meule, L._cylm(0.13, 0.13, 0.035, 20), L._m(M, "meule118", Color(0.62, 0.64, 0.68), 0.8), Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3.ZERO))
	L._mesh(meule, I._boxm(Vector3(0.04, 0.03, 0.22)), L._m(M, "meule118_trait", Color(0.4, 0.42, 0.46), 0.8))
	L._tourne(M, meule, Vector3.RIGHT, 7.0)
	L._mesh(I._node(M, tour + Vector3(-0.02, 0.3, 0.16)), L._cylm(0.0, 0.03, 0.08, 6), _cristal(M), Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), Vector3.ZERO))
	_marmite_vapeur(M, tour + Vector3(0, 0.3, 0.12), Vector3(0.03, 0.03, 0.03), 5)
	# l'étagère des lanternes (mur de gauche) : trois rangs, des bleues et des violettes
	R.etagere(-hw + 0.25, 0.0, 90, 2.0, 2.2, false, 4)
	for row in range(4):
		var yy: float = 0.08 + 2.08 * float(row) / 4.0 + 0.015
		for col in range(3):
			_lanterne(M, R.P(-hw + 0.25, yy, -0.65 + col * 0.65), (row + col) % 2 == 1, false)
	# des lanternes par terre (le coin du fond, à gauche), plus grandes
	for e in [[-hw + 0.6, -hd + 0.6, 1.6, false], [-hw + 1.25, -hd + 0.55, 1.3, true], [-hw + 0.7, -hd + 1.2, 1.1, true]]:
		var gl: Node3D = _lanterne(M, R.P(float(e[0]), 0, float(e[1])), bool(e[3]), false)
		gl.scale = Vector3.ONE * float(e[2])
	R.reserve(-hw + 0.9, -hd + 0.85, 1.4, 1.3)
	L._lampe(M, R.P(-hw + 0.9, 0.5, -hd + 0.9), Color(0.65, 0.7, 1.0), 0.4, 3.0)
	# les lanternes pendues sous les poutres
	var pend: Array = [[-2.5, -1.3, false, true], [-0.83, 0.5, true, false], [0.83, -1.6, false, false], [2.5, 0.6, true, true], [-2.5, 1.2, true, false]]
	for p2 in pend:
		_marmite_pendre(M, R.P(float(p2[0]), R.H - 0.24, float(p2[1])), 0.95, bool(p2[2]), bool(p2[3]), float(p2[0]) - float(p2[1]))
	# la vitrine des cristaux taillés (mur de droite) : ils pulsent doucement
	var vx: Transform3D = R.L(hw - 0.35, 0, 0.0, -90)
	k.box(vx * Transform3D(Basis(), Vector3(0, 0.45, 0)), Vector3(1.9, 0.9, 0.55), "bois_sombre", 1.0)
	k.box(vx * Transform3D(Basis(), Vector3(0, 0.92, 0)), Vector3(2.0, 0.04, 0.6), "bois", 1.0)
	k.box(vx * Transform3D(Basis(), Vector3(0, 1.25, 0)), Vector3(1.9, 0.62, 0.5), "verre", 1.0)
	k.box(vx * Transform3D(Basis(), Vector3(0, 1.58, 0)), Vector3(2.0, 0.04, 0.6), "bois", 1.0)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			k.box(vx * Transform3D(Basis(), Vector3(sx * 0.96, 1.25, sz * 0.26)), Vector3(0.03, 0.62, 0.03), "or", 1.0)
	k.col_box(vx * Transform3D(Basis(), Vector3(0, 0.8, 0)), Vector3(1.9, 1.6, 0.55))
	R.reserve(hw - 0.35, 0.0, 0.8, 2.1)
	var tb: StandardMaterial3D = L._m(M, "taille118_b", Color(0.55, 0.82, 1.0, 0.9), 0.1, 0.0, 1.2)
	var tv: StandardMaterial3D = L._m(M, "taille118_v", Color(0.78, 0.58, 1.0, 0.9), 0.1, 0.0, 1.2)
	var tailles: Array = []
	for i in range(7):
		var cn: Node3D = I._node(M, vx * Vector3(-0.75 + i * 0.25, 0.96, 0.05 * ((i % 2) * 2 - 1)))
		var tm: StandardMaterial3D = tv if i % 2 == 1 else tb
		var hh: float = 0.14 + (i % 3) * 0.04
		L._mesh(cn, L._cylm(0.0, 0.05, hh, 6), tm, Transform3D(Basis(), Vector3(0, 0.035 + hh * 0.5, 0)))
		L._mesh(cn, L._cylm(0.05, 0.0, 0.035, 6), tm, Transform3D(Basis(), Vector3(0, 0.0175, 0)))
		tailles.append(cn)
	L._lampe(M, vx * Vector3(0, 1.3, 0.6), Color(0.6, 0.75, 1.0), 0.35, 3.0)
	M.ctx["pulse118"] = 1.0
	L._chaque(M, func(_delta: float, t: float) -> void:
		var pz: float = float(M.ctx.get("pulse118", 1.0))
		tb.emission_energy_multiplier = (0.7 + 0.6 * (0.5 + 0.5 * sin(t * 1.5))) * pz
		tv.emission_energy_multiplier = (0.7 + 0.6 * (0.5 + 0.5 * sin(t * 1.5 + 2.0))) * pz
		for j in range(tailles.size()):
			var n2: Node3D = tailles[j]
			if is_instance_valid(n2):
				n2.scale = Vector3.ONE * (1.0 + 0.04 * sin(t * 1.5 + j * 0.9) * pz))
	var bulle: Label3D = L._etiquette(M, vx * Vector3(0, 1.9, 0.2), "Liiing… tiiing… diiing !")
	# le comptoir (devant, à gauche) : la lanterne éteinte qu'on allume, le casque-pot-à-crayons
	var cx: Transform3D = R.L(-2.8, 0, 1.2)
	k.box(cx * Transform3D(Basis(), Vector3(0, 0.5, 0)), Vector3(1.8, 1.0, 0.6), "bois_sombre", 1.0)
	k.box(cx * Transform3D(Basis(), Vector3(0, 1.02, 0.02)), Vector3(1.95, 0.05, 0.72), "bois", 1.0)
	k.col_box(cx * Transform3D(Basis(), Vector3(0, 0.52, 0)), Vector3(1.8, 1.05, 0.6))
	R.reserve(-2.8, 1.2, 2.1, 1.0)
	var lat: Vector3 = cx * Vector3(0.35, 1.045, 0.05)
	var lan: Node3D = _lanterne(M, lat, false, false)
	var mcov := StandardMaterial3D.new()
	mcov.albedo_color = Color(0.25, 0.3, 0.38, 0.95)
	mcov.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mcov.roughness = 0.1
	mcov.emission_enabled = true
	mcov.emission = Color(0.55, 0.8, 1.0)
	mcov.emission_energy_multiplier = 0.0
	L._mesh(lan, I._sph(0.07), mcov, Transform3D(Basis(), Vector3(0, 0.15, 0)))
	var lum: OmniLight3D = L._lampe(M, lat + Vector3(0, 0.15, 0), Color(0.6, 0.8, 1.0), 0.0, 4.0)
	var casque: Node3D = I._node(M, cx * Vector3(-0.5, 1.045, 0.0))
	L._mesh(casque, I._sph(0.14), L._m(M, "casque118", Color(0.92, 0.72, 0.18), 0.5), Transform3D(Basis.from_scale(Vector3(1.0, 0.65, 1.0)), Vector3(0, 0.0, 0)))
	L._mesh(casque, L._cylm(0.16, 0.16, 0.015, 16), L._m(M, "casque118", Color(0.92, 0.72, 0.18), 0.5), Transform3D(Basis(), Vector3(0, 0.0, 0)))
	for pc in range(4):
		L._mesh(casque, I._boxm(Vector3(0.012, 0.18, 0.012)), L._m(M, "crayon118_%d" % pc, [Color(0.85, 0.2, 0.2), Color(0.2, 0.45, 0.85), Color(0.25, 0.6, 0.3), Color(0.95, 0.8, 0.2)][pc], 0.7), Transform3D(Basis(Vector3(cos(pc * 1.6), 0, sin(pc * 1.6)), 0.25), Vector3(cos(pc * 1.6) * 0.03, 0.1, sin(pc * 1.6) * 0.03)))
	# les gens
	var opa: Node = L._patron(M, 1.1, -2.45, 180.0, "bricoler", ["Oh ! Bonjour ! Pardon, j'étais dans un cristal. Dans ma tête. Entrez, entrez, mais ne marchez pas sur les éclats : ils sont timides.",
		"Ah, une visite ! Vous tombez bien : j'ai besoin de quelqu'un pour tenir cette lanterne pendant que je cherche mes lunettes. … Elles sont sur ma tête ? Ah.",
		"Bonsoir ! Je travaille tard, mais les cristaux aussi : la nuit, ils rendent la lumière qu'ils ont bue toute la journée. C'est le meilleur moment pour les écouter."])
	if nuit:
		if opa == null:
			var range_f: Node = L._gens(M, "femme", -hw + 1.1, -0.4, -90.0, "marcher", ["Je range les lanternes par couleur, puis par taille, puis par humeur. Celle-ci est grognon. Je la mets au fond.",
				"La nuit, l'atelier s'éclaire tout seul. Je n'ai jamais besoin d'allumer : les cristaux font la veillée."])
			var porte: Node3D = _lanterne(M, R.P(-hw + 1.1, 0.8, -0.1), true, false)
			porte.reparent(range_f.npc)
			porte.position = Vector3(0.18, 0.75, 0.3)
			porte.rotation = Vector3.ZERO
			porte.scale = Vector3.ONE * 0.8
			L._va_et_vient(M, range_f, R.P(-hw + 1.1, 0, -0.4), R.P(0.2, 0, -2.3), 0.7, 3.0, porte)
			L._causer(M, range_f, ["Bonsoir ! L'atelier est fermé, mais les lanternes, elles, ne ferment jamais l'œil.", "Bon fond ! Chut… les cristaux rendent leur lumière. On dirait qu'ils respirent."],
				[["nuit", "Pourquoi ça brille plus, la nuit ?", ["Les cristaux ont bu la lumière du Soleil de Laiton toute la journée. La nuit, quand il devient ambré, ils la rendent. Comme un enfant qui a trop goûté et qui ne veut pas se coucher."]],
				["opaline", "La Docteure n'est pas là ?", ["Elle est au bord de l'étang des Jardins. Elle regarde ses lanternes, les champignons de Bertille et le reflet du Soleil de Laiton. Elle dit que les trois lumières se parlent. Elle essaie de comprendre ce qu'elles se disent."]]])
			M.ctx["entree"] = "L'Atelier des Lumières, la nuit : il n'y a rien à allumer. Les cristaux rendent toute la lumière bue dans la journée, et l'atelier entier luit comme une grotte heureuse."
		else:
			M.ctx["entree"] = "L'Atelier des Lumières, tard le soir : toutes les lanternes luisent, et la Docteure Opaline, penchée sur l'établi, parle tout bas à un cristal. Il a l'air d'écouter."
	else:
		if opa == null:
			var app: Node = L._gens(M, "femme", 1.1, -2.45, 180.0, "bricoler", ["Je polis les facettes une par une. Quarante-huit par cristal. Au quarante-septième, j'oublie toujours où j'en suis.",
				"La Docteure dit qu'un cristal mal poli boude. Il brille quand même, mais de travers."])
			L._causer(M, app, ["Bonne descente ! Bienvenue à l'Atelier des Lumières. Attention, ça brille de partout. C'est un peu le principe.", "Bon fond ! La Docteure Opaline est partie choisir des cristaux à la mine. Sans casque, sûrement."],
				[["lanterne", "Comment marche une lanterne à cristal ?", ["Un cristal bleu de la mine, une cage de laiton de la Forge, et de la lumière pour le nourrir. Le cristal boit la lumière du Soleil de Laiton toute la journée, et il la rend toute la nuit. Sans flamme, sans fumée. Juste de la patience."]],
				["opaline", "Où est la Docteure Opaline ?", ["Au fond de la Grotte aux Cristaux, à choisir ses pierres une par une. Le contremaître Ludovic lui crie « Casque ! », elle répond « Oui ! », et elle oublie. Son casque est là, sur le comptoir. Il sert de pot à crayons."]],
				["violet", "Pourquoi certaines sont violettes ?", ["Les violettes, ce sont les cristaux du fond de la mine, les plus vieux. Ils éclairent plus doux. La Docteure dit qu'ils ont l'âge de rêver. On les met dans les chambres d'enfants."]]])
		var cli: Node = L._gens(M, "vieille", hw - 1.3, 0.35, 90.0, "observer", ["Je cherche une lanterne pour la chambre de mon petit-fils. Une violette. Il dit que les bleues lui font peur. Les bleues ! Elles sont si gentilles.",
			"La lanterne de ma grand-mère brille encore. Quatre-vingts ans, et pas une panne. Moi, je tombe en panne tous les après-midi, vers trois heures."])
		L._causer(M, cli, ["Bon fond ! Tu viens aussi choisir une lanterne ? Prends ton temps : elles te choisissent autant que tu les choisis.", "Bonne descente ! Regarde ces cristaux, dans la vitrine : on dirait qu'ils respirent."],
			[["choix", "Laquelle me conseillez-vous ?", ["Celle qui te fait sourire sans que tu saches pourquoi. Moi, c'est la petite violette, là, sur l'étagère. Elle a l'air d'écouter."]],
			["galeries", "Tout le monde a une lanterne ?", ["Chaque famille des Galeries ! La Docteure les connaît toutes par leur prénom. Les lanternes, je veux dire. La mienne s'appelle Clémence. Elle a soixante ans et pas une ride."]]])
		M.ctx["entree"] = str(L._pick(M, ["L'Atelier des Lumières : des lanternes partout, posées, pendues, bleues et violettes, et sur l'établi, un cristal qui tourne contre la meule. Tout brille doucement.",
			"Ça sent le métal chaud et la poussière de cristal. Dans la vitrine, les cristaux taillés respirent, un peu plus clairs, un peu plus sombres, comme s'ils dormaient.",
			"Chhhhh… La meule du tour à polir chante tout bas. Autour, cent lanternes à cristal éclairent l'atelier sans une flamme, sauf le petit bec de gaz bleu de l'établi."]))
	# ce qu'on fait : allumer une lanterne, regarder dans la loupe, faire chanter un cristal
	M.act(cx * Vector3(0.35, 1.1, 0.75), "E : allumer une lanterne", func() -> void:
		M.main.sfx("cristal_eveil", lat)
		if not bool(M.ctx.get("allume118", false)):
			M.ctx["allume118"] = true
			var tw: Tween = M.room.create_tween()
			tw.set_parallel(true)
			tw.tween_property(mcov, "emission_energy_multiplier", 2.6, 1.4)
			tw.tween_property(mcov, "albedo_color", Color(0.6, 0.85, 1.0, 0.9), 1.4)
			tw.tween_property(lum, "light_energy", 0.8, 1.4)
		var st: Dictionary = M.state()
		if not bool(st.get("cristal118", false)):
			st["cristal118"] = true
			M.give([["eclat_cristal", 1]], "Tu tournes doucement la cage de laiton vers la lumière : le cristal boit, frémit, puis s'allume d'un bleu tout neuf. « Bravo ! On dirait qu'elle vous attendait. Gardez cet éclat : il était trop petit pour une lanterne, mais pas pour une poche. » Tu reçois :\n")
		else:
			M.say(str(L._pick(M, ["La lanterne s'allume d'un bleu calme, sans flamme ni fumée. Elle éclairera toute la nuit, avec la lumière qu'elle a bue aujourd'hui.",
				"Le cristal s'éveille, hésite, puis brille tout à fait. Dans l'atelier, deux ou trois lanternes clignotent, comme pour le saluer.",
				"Un petit « ting », et la lanterne s'allume. Elle a l'air contente. On dit qu'il ne faut pas parler aux lanternes. On dit beaucoup de choses."])), 6.0)
	, 1.3)
	M.act(ex * Vector3(-0.75, 1.1, 0.75), "E : regarder dans la loupe", func() -> void:
		M.say(str(L._pick(M, ["Dans la loupe, un éclat de cristal bleu devient une ville entière : des couloirs, des facettes, des petites lumières qui se promènent. On dirait les Strates, en tout petit.",
			"Sous la loupe, une minuscule bulle d'air est prisonnière du cristal depuis des millions d'années. Elle a l'air d'aller très bien. Elle a eu le temps de s'habituer.",
			"Tu regardes dans la loupe : une étiquette, écrite tout petit, dit « Ne pas oublier le casque ». En dessous, encore plus petit : « Oui, Ludovic. »"])), 7.0)
	, 1.2)
	M.act(vx * Vector3(0, 1.2, 0.75), "E : faire chanter un cristal", func() -> void:
		M.main.sfx("cristal_chante", vx * Vector3(0, 1.2, 0))
		M.ctx["pulse118"] = 2.6
		L._montrer(M, bulle, 2.5)
		M.say(str(L._pick(M, ["Tu effleures le bord d'un cristal taillé : il chante une note claire, très longue. Tous les autres, dans la vitrine, s'allument plus fort, comme un chœur qui reprend le refrain.",
			"Liiing… Le cristal chante, et les lanternes les plus proches clignotent en mesure. La Docteure dit que les cristaux bleus chantent en sol. Les violets, en « sol un peu rêveur ».",
			"Une note pure monte de la vitrine et fait trembler la lumière de toutes les lanternes. Quelque part dans l'atelier, une petite cuillère se met à vibrer, elle aussi."])), 6.0)
		await M.get_tree().create_timer(3.0).timeout
		if _la(M, room0):
			M.ctx["pulse118"] = 1.0
	, 1.3)


# =================================================================== la Maison de la Guilde

## La Maison de la Guilde, chez la Doyenne Agathe Basalte : la longue table du conseil et ses chaises, le
## blason de la Guilde et ses bannières, la carte des galeries gravée en laiton, le grand registre sur son
## lutrin, la maquette de la caverne sous sa cloche de verre (la Colonne Renversée, le Soleil de Laiton qui
## tourne), la cheminée et ses fauteuils de cuir ; le jour, la Doyenne (ou son commis) et deux artisans
## venus régler un différend, tout bas ; la nuit, le commis qui veille, ou Agathe qui lit au coin du feu.
static func _guilde(M) -> void:
	var R = M.R
	var k = R.kit
	var nuit: bool = L._nuit(M)
	var room0 = M.room
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	# la longue table du conseil, son chemin de table, le maillet de la Doyenne, ses chaises
	var tz: float = -0.7
	var tx: Transform3D = R.L(0, 0, tz)
	k.box(tx * Transform3D(Basis(), Vector3(0, 0.75, 0)), Vector3(5.0, 0.07, 1.3), "bois_sombre", 1.0)
	for sx in [-1.0, 1.0]:
		k.box(tx * Transform3D(Basis(), Vector3(sx * 2.0, 0.36, 0)), Vector3(0.14, 0.72, 1.0), "bois_sombre", 1.0)
		k.box(tx * Transform3D(Basis(), Vector3(sx * 2.0, 0.04, 0)), Vector3(0.3, 0.08, 1.2), "bois_sombre", 1.0)
	k.box(tx * Transform3D(Basis(), Vector3(0, 0.3, 0)), Vector3(3.9, 0.08, 0.1), "bois_sombre", 1.0)
	k.box(tx * Transform3D(Basis(), Vector3(0, 0.79, 0)), Vector3(4.6, 0.01, 0.45), "tissu_rouge", 1.0)
	k.col_box(tx * Transform3D(Basis(), Vector3(0, 0.39, 0)), Vector3(5.0, 0.78, 1.3))
	R.reserve(0, tz, 6.8, 3.0)
	k.box(tx * Transform3D(Basis(Vector3.UP, 0.4), Vector3(-1.9, 0.83, 0.1)), Vector3(0.22, 0.07, 0.07), "bois", 1.0)
	k.box(tx * Transform3D(Basis(Vector3.UP, 0.4), Vector3(-1.85, 0.81, 0.24)), Vector3(0.025, 0.025, 0.26), "bois", 1.0)
	for pp in range(5):
		k.box(tx * Transform3D(Basis(Vector3.UP, 0.2 * (pp - 2)), Vector3(-1.2 + pp * 0.6, 0.795, 0.4 - (pp % 2) * 0.8)), Vector3(0.21, 0.004, 0.29), "papier", 1.0)
	for cxp in [-1.8, -0.6, 0.6, 1.8]:
		R.chaise(cxp, tz - 1.0, 0.0, "rouge")
		R.chaise(cxp, tz + 1.0, 180.0, "rouge")
	R.chaise(-2.9, tz, 90.0, "rouge")
	R.chaise(2.9, tz, -90.0, "rouge")
	# le blason de la Guilde (au fond, au milieu) et ses bannières
	_marmite_panneau(M, R.L(0, 3.1, -hd + 0.06), Vector2(2.8, 1.4), _marmite_tex(M, GUILDE_BLASON_TEX, true))
	R.mark_wall(0, 2.95, -hd, 0.9)
	for s in [-1.0, 1.0]:
		var bx: float = s * 1.75
		k.box(R.L(bx, 2.7, -hd + 0.05), Vector3(0.75, 2.2, 0.02), "tissu_bleu" if s < 0.0 else "tissu_rouge", 1.0)
		k.box(R.L(bx, 2.7, -hd + 0.065), Vector3(0.1, 2.2, 0.01), "or", 1.0)
		k.box(R.L(bx, 3.0, -hd + 0.07), Vector3(0.22, 0.34, 0.01), "or", 1.0)
		k.box(R.L(bx, 3.22, -hd + 0.07), Vector3(0.12, 0.08, 0.01), "or", 1.0)
		k.cyl(Transform3D(Basis(Vector3.BACK, PI * 0.5), R.P(bx + 0.45, 3.82, -hd + 0.07)), 0.02, 0.02, 0.9, "or", 6, false)
		R.mark_wall(bx, 2.7, -hd, 0.45)
	k.box(R.L(-hw + 0.05, 2.7, 0.0, 90), Vector3(0.75, 2.0, 0.02), "tissu_vert", 1.0)
	k.box(R.L(-hw + 0.065, 2.7, 0.0, 90), Vector3(0.1, 2.0, 0.01), "or", 1.0)
	R.mark_wall(-hw, 2.7, 0.0, 0.45)
	# la carte des galeries (au fond, à droite) : des lignes de laiton gravées sur une plaque de fer
	var cg: Transform3D = R.L(4.4, 2.3, -hd + 0.05)
	k.box(cg, Vector3(2.7, 1.75, 0.05), "bois_sombre", 1.0)
	k.box(cg * Transform3D(Basis(), Vector3(0, 0, 0.03)), Vector3(2.5, 1.55, 0.02), "fer", 1.0)
	var prev := Vector2(0.85, 0.0)
	for i in range(1, 25):
		var a: float = TAU * i / 24.0
		var cur := Vector2(cos(a) * 0.85, sin(a) * 0.52)
		_guilde_trait(M, cg, prev, cur)
		prev = cur
	for i2 in range(1, 9):
		var a2: float = TAU * i2 / 8.0
		var a1: float = TAU * (i2 - 1) / 8.0
		_guilde_trait(M, cg, Vector2(cos(a1), sin(a1)) * 0.07, Vector2(cos(a2), sin(a2)) * 0.07, 0.015)
	for gy in [0.36, 0.44]:
		_guilde_trait(M, cg, Vector2(-0.5, gy), Vector2(0.5, gy), 0.015)
		for d in range(6):
			_guilde_trait(M, cg, Vector2(-0.42 + d * 0.17, gy), Vector2(-0.42 + d * 0.17, gy + 0.04), 0.012)
	_guilde_trait(M, cg, Vector2(-0.85, 0.0), Vector2(-1.0, 0.12))
	_guilde_trait(M, cg, Vector2(-1.0, 0.12), Vector2(-1.12, 0.05))
	_guilde_trait(M, cg, Vector2(-0.85, 0.0), Vector2(-1.05, -0.15))
	_guilde_trait(M, cg, Vector2(-1.05, -0.15), Vector2(-1.12, -0.3))
	for j in range(1, 7):
		var aj0: float = PI * (j - 1) / 6.0
		var aj1: float = PI * j / 6.0
		_guilde_trait(M, cg, Vector2(cos(aj0) * 0.22, -0.52 - sin(aj0) * 0.15), Vector2(cos(aj1) * 0.22, -0.52 - sin(aj1) * 0.15), 0.015)
	_guilde_trait(M, cg, Vector2(0.85, 0.0), Vector2(1.05, 0.0), 0.03)
	for e in [Vector2(1.12, 0.08), Vector2(1.1, -0.08), Vector2(0.35, 0.2), Vector2(-0.3, -0.25), Vector2(0.2, -0.3)]:
		k.box(cg * Transform3D(Basis(), Vector3(e.x, e.y, 0.045)), Vector3(0.05, 0.05, 0.012), "or", 1.0)
	R.mark_wall(4.4, 2.3, -hd, 1.45)
	# le grand registre, ouvert sur son lutrin (au fond, à gauche), l'encrier et la plume
	var lt: Transform3D = R.L(-4.6, 0, -hd + 1.4)
	k.box(lt * Transform3D(Basis(), Vector3(0, 0.55, 0)), Vector3(0.1, 1.1, 0.1), "bois_sombre", 1.0)
	k.box(lt * Transform3D(Basis(), Vector3(0, 0.03, 0)), Vector3(0.55, 0.06, 0.45), "bois_sombre", 1.0)
	k.box(lt * Transform3D(Basis(Vector3.RIGHT, 0.35), Vector3(0, 1.12, 0)), Vector3(0.75, 0.05, 0.5), "bois_sombre", 1.0)
	k.box(lt * Transform3D(Basis(Vector3.RIGHT, 0.35), Vector3(0, 1.15, 0)), Vector3(0.7, 0.02, 0.46), "cuir", 1.0)
	for s3 in [-1.0, 1.0]:
		k.box(lt * Transform3D(Basis(Vector3.RIGHT, 0.35) * Basis(Vector3.FORWARD, s3 * 0.06), Vector3(s3 * 0.165, 1.175, 0)), Vector3(0.32, 0.03, 0.42), "papier", 1.0)
	k.cyl(lt * Transform3D(Basis(), Vector3(0.3, 1.2, 0.18)), 0.03, 0.03, 0.05, "noir", 8)
	k.box(lt * Transform3D(Basis(Vector3.BACK, 0.4), Vector3(0.33, 1.32, 0.18)), Vector3(0.012, 0.25, 0.04), "tissu_blanc", 1.0)
	k.col_box(lt * Transform3D(Basis(), Vector3(0, 0.6, 0)), Vector3(0.75, 1.2, 0.5))
	R.reserve(-4.6, -hd + 1.4, 1.0, 1.0)
	# la maquette de la caverne sous sa cloche de verre (devant, à gauche)
	var mq: Vector3 = R.P(-4.9, 0, 1.1)
	k.cyl(Transform3D(Basis(), mq), 0.42, 0.48, 1.0, "bois_sombre", 16)
	k.cyl(Transform3D(Basis(), mq + Vector3.UP * 1.0), 0.46, 0.46, 0.04, "or", 16)
	k.col_cyl(mq, 0.5, 1.9)
	R.reserve(-4.9, 1.1, 1.2, 1.2)
	var base: Node3D = I._node(M, mq + Vector3.UP * 1.04)
	L._mesh(base, L._cylm(0.38, 0.38, 0.03, 20), L._m(M, "gres118a", Color(0.82, 0.66, 0.48), 0.9), Transform3D(Basis(), Vector3(0, 0.015, 0)))
	for h in range(9):
		var ah: float = TAU * h / 9.0 + 0.3
		var rh: float = 0.2 + (h % 2) * 0.08
		L._mesh(base, I._boxm(Vector3(0.05, 0.05 + (h % 3) * 0.015, 0.05)), L._m(M, "maison118a", Color(0.92, 0.82, 0.62), 0.8), Transform3D(Basis(Vector3.UP, ah), Vector3(cos(ah) * rh, 0.055, sin(ah) * rh)))
	L._mesh(base, L._cylm(0.02, 0.02, 0.42, 10), L._laiton(M), Transform3D(Basis(), Vector3(0, 0.55, 0)))
	L._mesh(base, L._cylm(0.03, 0.03, 0.04, 10), L._laiton(M), Transform3D(Basis(), Vector3(0, 0.05, 0)))
	var msol := StandardMaterial3D.new()
	msol.albedo_color = Color(1.0, 0.82, 0.45)
	msol.emission_enabled = true
	msol.emission = Color(1.0, 0.75, 0.35)
	msol.emission_energy_multiplier = 0.5
	msol.metallic = 0.4
	var soleil: Node3D = I._node(M, mq + Vector3.UP * 1.36)
	L._mesh(soleil, I._sph(0.045), msol)
	var anneau1: Node3D = Node3D.new()
	soleil.add_child(anneau1)
	L._mesh(anneau1, L._tore(0.1, 0.115), L._laiton(M))
	var anneau2: Node3D = Node3D.new()
	anneau1.add_child(anneau2)
	L._mesh(anneau2, L._tore(0.075, 0.088), L._laiton(M), Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO))
	L._tourne(M, anneau1, Vector3.UP, 0.5, true)
	L._tourne(M, anneau2, Vector3.RIGHT, 0.8, true)
	L._mesh(base, I._sph(0.4), L._m(M, "cloche118a", Color(0.82, 0.9, 1.0, 0.18), 0.05), Transform3D(Basis.from_scale(Vector3(1.0, 1.25, 1.0)), Vector3(0, 0.25, 0)))
	var slum: OmniLight3D = L._lampe(M, mq + Vector3.UP * 1.36, Color(1.0, 0.8, 0.45), 0.0, 3.0)
	# la cheminée (mur de droite) et ses fauteuils de cuir, un guéridon
	R.cheminee(hw - 0.35, 0.0, -90, true)
	R.fauteuil(4.9, -1.3, 53.0, "brun")
	R.fauteuil(4.9, 1.3, 127.0, "brun")
	R.table_ronde(5.3, 0.0, 0.3, 0.55)
	k.cyl(R.L(5.3, 0.55, 0.05), 0.05, 0.04, 0.08, "ceramique", 10)
	# les lanternes pendues au-dessus de la table, une lumière chaude
	var pend: Array = [[-2.625, false, true], [-0.875, true, false], [0.875, false, false], [2.625, true, true]]
	for p2 in pend:
		_marmite_pendre(M, R.P(float(p2[0]), R.H - 0.24, tz), 1.5, bool(p2[1]), bool(p2[2]), float(p2[0]))
	L._lampe(M, R.P(0, 3.4, 0.4), Color(1.0, 0.88, 0.66), 0.7 if not nuit else 0.3, 10.0)
	# les gens
	if nuit:
		var aga: Node = L._patron(M, 4.9, -1.3, 53.0, "lire", ["Bonsoir. Je lisais le registre. On y trouve toute la ville, si on lit entre les lignes. Et dans les marges.",
			"Ah. Vous. Asseyez-vous près du feu. Je surveille la Fronde, de loin, avec fierté. Mais ne le répétez pas."])
		if aga == null:
			var com: Node = L._gens(M, "homme", 4.9, 1.3, 127.0, "lire", ["Je veille sur le registre. La nuit, quelqu'un pourrait venir écrire « record de descente » à côté de son nom. Ça s'est déjà vu.",
				"Le feu crépite, la ville dort, et de l'autre côté du Gouffre, la Fronde joue encore. La Doyenne dit que c'est une berceuse. Elle a de drôles de berceuses."])
			L._causer(M, com, ["Bonsoir ! La Guilde est fermée, mais le feu est allumé. Approchez-vous, c'est gratuit.", "Bon fond ! Chut… le registre dort. Moi, je veille."],
				[["fronde", "On entend la Fronde, d'ici ?", ["Un peu, quand le vent descend le tunnel. Les Soupapes jouent jusqu'à onze heures. La Doyenne ouvre la fenêtre du balcon pour mieux surveiller. Je crois qu'elle tape du pied. Je n'ai rien vu."]],
				["veille", "Pourquoi veiller sur un livre ?", ["Parce que c'est toute la ville, ce livre : les métiers, les disputes, les records, les promesses. On ne laisse pas une ville toute seule la nuit. Même en papier."]]])
			M.ctx["entree"] = "La Maison de la Guilde, la nuit : le feu crépite, les bannières dorment, et sous sa cloche de verre, le petit Soleil de Laiton veille sur la caverne miniature."
		else:
			M.ctx["entree"] = "La Maison de la Guilde, la nuit : la Doyenne lit au coin du feu, le grand registre sur les genoux. Elle lève les yeux, et sourit. D'un millimètre."
	else:
		var aga2: Node = L._patron(M, -2.9, tz, 90.0, "assis", ["Bonjour. Agathe Basalte, Doyenne de la Guilde. Asseyez-vous. Je ne dirai rien pendant une minute : c'est ma façon d'être contente de vous voir.",
			"Vous. Bienvenue à la Guilde. Ici, on règle les disputes, on écrit le registre, et on sert le thé. Dans cet ordre-là, en général."])
		if aga2 == null:
			var com2: Node = L._gens(M, "homme", -2.9, tz, 90.0, "lire", ["J'écris tout dans le registre : les métiers, les disputes, les records. La Doyenne relit tout. Elle corrige les virgules. Il y en a beaucoup.",
				"Le différend du jour : deux doigts de crochet de lanterne. On en a vu de plus grands. On en a vu de plus petits, aussi."])
			L._causer(M, com2, ["Bonne descente ! Bienvenue à la Maison de la Guilde. La Doyenne est à la Grande Horloge ; elle revient bientôt. Elle revient toujours à l'heure.", "Bon fond ! Vous voulez lire le registre ? Il est sur le lutrin. Tournez les pages doucement : elles sont vieilles, et un peu susceptibles."],
				[["registre", "Qu'y a-t-il dans le registre ?", ["Tout ! Les métiers, les disputes réglées, les records de descente, les inventions. Et si vous signez en bas, vous devenez membre d'honneur. C'est une vieille coutume. Il y a même une galette."]],
				["doyenne", "Comment est la Doyenne ?", ["Elle parle peu. Elle écoute tout. Quand elle dit trois mots, la dispute est finie. Une fois, elle a réglé une querelle de trente ans avec un seul « Hm ». On l'a noté dans le registre."]],
				["guilde", "À quoi sert la Guilde ?", ["À ce que tout le monde travaille ensemble : les mineurs, les forgerons, les lampistes, les cheminots. On partage les outils, les fours et les soucis. Et le thé. Surtout le thé."]]])
		var forg: Node = L._gens(M, "homme", 0.6, 1.55, 90.0, "bras_croises", ["Je dis seulement que son crochet de lanterne dépasse de deux doigts devant ma porte. Deux doigts ! On ne va pas se fâcher pour deux doigts. … Mais c'est deux doigts.",
			"Chut, on se dispute tout bas : à la Guilde, même les disputes ont de bonnes manières."])
		L._causer(M, forg, ["Bonne descente. Parlez doucement : on se dispute.", "Bon fond ! Vous êtes témoin : deux doigts. Vous avez vu ? Deux doigts."],
			[["lanterne", "Ce n'est qu'une lanterne, non ?", ["Si. Une très belle lanterne, d'ailleurs. Elle éclaire ma porte toute la nuit. Gratuitement. … Ah. Dit comme ça, je ne sais plus très bien pourquoi je suis venu."]]])
		var lamp: Node = L._gens(M, "femme", 1.8, 1.55, -90.0, "pointer", ["Deux doigts ? Un doigt et demi ! Et c'est la plus jolie lanterne de la Galerie. Elle éclaire sa porte gratuitement, en plus.",
			"La Doyenne va nous écouter, puis elle dira trois mots. Tout le monde sera d'accord. C'est comme ça depuis trente ans."])
		L._causer(M, lamp, ["Bonne descente ! Pardon, on se dispute. Doucement. C'est la Guilde, ici : on se dispute bien élevés.", "Bon fond ! Vous tombez bien : il nous faut un avis neutre. Vous avez l'air neutre."],
			[["dispute", "Pourquoi vous disputez-vous ?", ["Mon crochet de lanterne dépasse d'un doigt et demi devant sa porte. Il dit deux. On se dispute tout bas : la Doyenne n'aime pas qu'on crie. Elle trouve que ça use la roche."]],
			["doyenne", "Que va décider la Doyenne ?", ["Elle va nous écouter tous les deux, longtemps. Puis elle dira trois mots, du genre « Raccourcissez. Partagez. Thé. » Et on rentrera bras dessus, bras dessous. C'est agaçant, tellement ça marche."]]])
		M.ctx["entree"] = str(L._pick(M, ["La Maison de la Guilde : une longue salle de grès, une table de conseil, des bannières, et au fond, le blason de la Guilde. Ça sent le papier ancien et le feu de bois.",
			"Chut… Deux artisans se disputent à voix basse devant la table du conseil. À la Guilde, même les disputes ont de bonnes manières.",
			"Sur un lutrin, le grand registre est ouvert. Sous une cloche de verre, une maquette de la caverne brille doucement. Au mur, toute la ville est gravée en lignes de laiton."]))
	# ce qu'on fait : lire le registre, le signer, regarder la maquette, regarder la carte
	M.act(lt * Vector3(-0.3, 1.1, 0.6), "E : lire le registre", func() -> void:
		M.main.sfx("ui_ouvrir", lt.origin)
		var n: int = int(M.ctx.get("registre118", 0))
		M.ctx["registre118"] = n + 1
		M.say(str(REGISTRE_GUILDE[n % REGISTRE_GUILDE.size()]), 9.0)
	, 1.0)
	M.act(lt * Vector3(0.35, 1.1, 0.6), "E : signer le registre", func() -> void:
		var st: Dictionary = M.state()
		if bool(st.get("guilde118", false)):
			M.say(str(L._pick(M, ["Ta signature est déjà dans le registre, tout en bas de la dernière page, avec une petite étoile à côté. Quelqu'un l'a ajoutée. Tu sais qui.",
				"Tu es déjà membre d'honneur de la Guilde. Le titre ne donne aucun droit, sauf celui de revenir. C'est le meilleur."])), 6.0)
			return
		st["guilde118"] = true
		M.main.sfx("ui_quete", lt.origin)
		for f in M.people:
			if is_instance_valid(f) and f.has_method("gesture"):
				f.gesture("applaudir", 2.5)
		M.give([["galette_rouages", 1]], "Tu trempes la plume et tu signes, tout en bas de la dernière page. « Par les Strates ! Te voilà membre d'honneur de la Guilde. Le titre ne donne aucun droit, sauf celui-ci : une galette des Rouages, offerte. » Tu reçois :\n")
	, 1.0)
	M.act(mq + Vector3(0.6, 1.2, 0.0), "E : regarder la maquette", func() -> void:
		if bool(M.ctx.get("soleil118", false)):
			return
		M.ctx["soleil118"] = true
		M.main.sfx("mecanisme", mq + Vector3.UP * 1.3)
		M.ctx["vite116"] = 4.0
		var tw: Tween = M.room.create_tween()
		tw.set_parallel(true)
		tw.tween_property(slum, "light_energy", 1.4, 0.8)
		tw.tween_property(msol, "emission_energy_multiplier", 4.0, 0.8)
		M.say(str(L._pick(M, ["Sous la cloche de verre, toute la caverne en petit : la Colonne Renversée qui pend de la voûte, les maisons de pierre blonde, les Galeries. Tu tournes la petite clé : le Soleil de Laiton s'allume et ses anneaux se mettent à tourner.",
			"La maquette des Strates, offerte à la Guilde par les apprentis de la Forge. Le petit Soleil de Laiton s'allume, tout doré. Une étiquette dit : « Échelle : un doigt pour vingt mètres. Ne pas souffler sur la cloche. »",
			"Le petit Soleil de Laiton s'allume et tourne. Dans les Galeries miniatures, quelqu'un a peint une minuscule fenêtre allumée. C'est celle de la Doyenne, paraît-il. Elle dit qu'elle ne l'a jamais remarquée."])), 7.0)
		await M.get_tree().create_timer(6.0).timeout
		if not _la(M, room0):
			return
		M.ctx["vite116"] = 1.0
		var tw2: Tween = M.room.create_tween()
		tw2.set_parallel(true)
		tw2.tween_property(slum, "light_energy", 0.0, 1.5)
		tw2.tween_property(msol, "emission_energy_multiplier", 0.5, 1.5)
		M.ctx["soleil118"] = false
	, 1.3)
	M.act(R.P(4.4, 1.3, -hd + 1.3), "E : regarder la carte des galeries", func() -> void:
		M.say(str(L._pick(M, ["LA CARTE DES GALERIES, gravée en lignes de laiton. Au milieu, la Colonne et la Grande Strate. Au nord, les deux étages des Galeries. À l'ouest, les Mines et leurs tunnels. Au sud, les Jardins et l'étang. À l'est, un petit pont, et derrière, un mot gravé plus profond que les autres : « Fronde ».",
			"Sur la carte, une minuscule marmite fumante est gravée sur la Place des Rouages. Ce n'était pas prévu. La Guilde a voté pour la garder. À l'unanimité, et avec une galette."])), 8.0)
	, 1.3)


# =================================================================== CONSTANTES (à mettre avant « static func build »)

## L'Atelier Libre : ce qu'on dit quand on donne un coup de clé, quand on réveille Clapet, quand on
## lance la machine à bulles.
const ATL118_CLE := ["Tu serres le boulon de l'étau d'un grand coup de clé. Clonk ! Sur son support, la roue du vélo se met à filer toute seule, comme si elle avait entendu un départ.",
	"Un quart de tour, puis un autre. Clonk ! Quelqu'un lève le pouce au fond de l'atelier : « Serré juste ce qu'il faut. Ni trop, ni pas assez. C'est tout l'art. »",
	"Tu donnes un coup de clé à un boulon qui grinçait. Il arrête de grincer. Il a l'air soulagé. Toi aussi. La roue du vélo fait trois tours pour fêter ça.",
	"Clonk ! Le boulon est serré. Par réflexe, tu en serres un deuxième, puis un troisième. À l'Atelier Libre, on appelle ça « attraper la fièvre de la clé »."]
const ATL118_CLAPET := ["Bip ! Bouïp ! Clapet ouvre un œil, puis l'autre, et hoche la tête à toute vitesse. Il a l'air de dire : « Encore toi ? Super ! »",
	"Bip-bip ! Clapet te fait un grand salut de la tête. Son couvercle de boîte de conserve claque comme un chapeau qu'on soulève.",
	"Bouïïïp… Clapet bâille (enfin, son couvercle s'ouvre tout grand), puis hoche la tête très vite, très content d'être réveillé.",
	"Bip ! Les yeux de Clapet clignotent en morse. Ça veut dire « bonjour ». Ou « j'ai faim de boulons ». Personne n'a jamais su lire le morse de Clapet."]
const ATL118_BULLES := ["Tu tournes l'interrupteur : le ventilateur ronfle, l'anneau trempe dans la bassine, et des dizaines de bulles s'envolent dans l'atelier. Elles reflètent tout : les outils, les affiches, ta tête ravie.",
	"Frrrr… La machine à bulles crache un nuage de bulles. Une grosse se pose sur le nez de Clapet. Il ne bouge plus. Il ne veut pas la faire éclater.",
	"Le ventilateur souffle, les bulles partent en procession vers la porte. Bricole dit qu'elle a inventé cette machine pour tester les courants d'air. Tout le monde sait qu'elle l'a inventée pour les bulles."]
const ATL118_PEINTS := [Color(0.85, 0.22, 0.18), Color(0.95, 0.75, 0.2), Color(0.22, 0.5, 0.85), Color(0.3, 0.68, 0.4), Color(0.62, 0.32, 0.78)]

## Le Troc : ce qu'on trouve en fouillant les étagères (un objet différent à chaque fois), ce que joue
## le phonographe.
const TROC118_FOUILLE := ["Tu fouilles l'étagère et tu trouves… un réveil qui ne sonne qu'une fois par an. Une étiquette dit : « Très ponctuel. Très patient. »",
	"Tu trouves une chaussette toute seule. Une étiquette dit : « Cherche sa sœur. Récompense : l'autre chaussette. »",
	"Une boîte à musique qui joue « boum-tchak ». Une étiquette dit : « Fabriquée par Rivet. Ne pas remonter après vingt-trois heures. »",
	"Une louche percée. Une étiquette, de la main de Mémé Gamelle : « Parfaite pour servir le vent. »",
	"Un vieux casque de mineur dont la lampe s'allume quand on lui dit bonjour. Tu lui dis bonjour. Elle s'allume. Tu es tout ému.",
	"Une boîte pleine de boutons, tous différents. Une étiquette dit : « Ne pas trier. Ils sont amis comme ça. »",
	"Un parapluie à l'envers, pour récupérer les gouttes qui tombent de la voûte. Dans une caverne, c'est presque un objet de luxe.",
	"Une soupape en forme de canard. Tu appuies dessus : « Pouêt. » Une étiquette dit : « Prototype. Bricole. Ne pas rendre. »"]
const TROC118_PHONO := ["Le phonographe crachote, puis une vieille chanson des Strates s'élève : un mineur qui chante l'amour de sa lanterne. Le cornet se tourne un peu vers toi, pour mieux te la chanter.",
	"Grrr… crrr… puis un air de guitare, très vieux et très punk à la fois. L'étiquette du disque dit : « Les Soupapes, premier enregistrement. Dans une chaudière. »",
	"Le disque tourne, l'aiguille saute, la musique repart. Le chat ouvre un œil, remue une oreille en rythme, et se rendort."]


# =================================================================== les aides de l'Atelier Libre et du Troc

## Toujours dans la même pièce ? (après un délai, on a pu sortir… ou entrer dans un autre lieu)


static func _atelier_t(x: float, y: float, z: float) -> Transform3D:
	return Transform3D(Basis(), Vector3(x, y, z))


## Une tôle peinte (les bidons de peinture, le corps de Clapet, le vélo).
static func _atelier_peint(M, i: int) -> StandardMaterial3D:
	var j: int = posmod(i, ATL118_PEINTS.size())
	return L._m(M, "peint118_%d" % j, ATL118_PEINTS[j], 0.7, 0.2)


## Un tube (un cadre de vélo, un fil, une tige) de a à b, en local du nœud n.
static func _atelier_tube(n: Node3D, a: Vector3, b: Vector3, r: float, mat: Material) -> void:
	var d: Vector3 = b - a
	if d.length() < 0.001:
		return
	var bs := Basis(Quaternion(Vector3.UP, d.normalized())) if absf(d.normalized().dot(Vector3.UP)) < 0.999 else Basis()
	L._mesh(n, L._cylm(r, r, d.length(), 8), mat, Transform3D(bs, (a + b) * 0.5))


## Une affiche (une image collée au mur, qui regarde +Z de xf).
static func _atelier_affiche(M, xf: Transform3D, size: Vector2, tex: String) -> MeshInstance3D:
	var key: String = "affiche118_" + tex
	if not M.ctx.has("mats116"):
		M.ctx["mats116"] = {}
	var cache: Dictionary = M.ctx["mats116"]
	var m: StandardMaterial3D = cache.get(key, null)
	if m == null:
		m = StandardMaterial3D.new()
		var p: String = "res://assets/textures/" + tex
		if ResourceLoader.exists(p):
			m.albedo_texture = load(p)
		else:
			m.albedo_color = Color(0.8, 0.3, 0.25)
		m.roughness = 0.9
		cache[key] = m
	var qm := QuadMesh.new()
	qm.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = qm
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	M.room.add_child(mi)
	mi.global_transform = xf
	return mi


## Une roue de vélo (le pneu, la jante, les rayons, le moyeu), dans le plan XY local d'un nouveau nœud
## enfant de parent ; elle tourne autour de son Z local.
static func _atelier_roue(M, parent: Node3D, r: float) -> Node3D:
	var n := Node3D.new()
	parent.add_child(n)
	var up := Basis(Vector3.RIGHT, PI * 0.5)
	L._mesh(n, L._tore(r - 0.035, r), M.R.mat("noir"), Transform3D(up, Vector3.ZERO))
	L._mesh(n, L._tore(r - 0.05, r - 0.035), M.R.mat("argent"), Transform3D(up, Vector3.ZERO))
	for i in range(8):
		L._mesh(n, I._boxm(Vector3(0.006, (r - 0.04) * 2.0, 0.006)), M.R.mat("argent"), Transform3D(Basis(Vector3.BACK, PI * i / 8.0), Vector3.ZERO))
	L._mesh(n, L._cylm(0.03, 0.03, 0.08, 10), M.R.mat("argent"), Transform3D(up, Vector3.ZERO))
	return n


## Des bulles de savon (la machine à bulles) : elles partent vers dirv et montent un peu.
static func _atelier_bulles(M, at: Vector3, dirv: Vector3, n: int) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = n
	p.lifetime = 4.0
	p.preprocess = 2.0
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.08
	p.direction = dirv.normalized()
	p.spread = 28.0
	p.gravity = Vector3(0, 0.04, 0)
	p.initial_velocity_min = 0.25
	p.initial_velocity_max = 0.55
	p.damping_min = 0.08
	p.damping_max = 0.2
	p.scale_amount_min = 0.03
	p.scale_amount_max = 0.09
	var qm := QuadMesh.new()
	qm.size = Vector2.ONE
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.billboard_keep_scale = true
	m.albedo_color = Color(0.82, 0.93, 1.0, 0.5)
	m.albedo_texture = M.R.dot_texture()
	qm.material = m
	p.mesh = qm
	M.room.add_child(p)
	p.global_position = at
	return p


## Des étincelles de soudure (Bricole qui soude tard).
static func _atelier_etincelles(M, at: Vector3) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = 36
	p.lifetime = 0.6
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.02
	p.direction = Vector3.UP
	p.spread = 70.0
	p.gravity = Vector3(0, -6.0, 0)
	p.initial_velocity_min = 0.8
	p.initial_velocity_max = 2.0
	p.scale_amount_min = 0.012
	p.scale_amount_max = 0.025
	var qm := QuadMesh.new()
	qm.size = Vector2.ONE
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.billboard_keep_scale = true
	m.albedo_color = Color(1.0, 0.78, 0.35, 1.0)
	m.albedo_texture = M.R.dot_texture()
	qm.material = m
	p.mesh = qm
	M.room.add_child(p)
	p.global_position = at
	return p


## La radio de l'atelier grésille tout bas, une fois, quand on entre.
static func _atelier_radio(M, at: Vector3) -> void:
	var room0 = M.room
	await M.get_tree().create_timer(1.2).timeout
	if not _la(M, room0):
		return
	M.main.sfx("radio_jingle", at, -14.0)


# =================================================================== l'Atelier Libre

## L'ATELIER LIBRE (fr_atelier) : les deux conteneurs réunis de Bricole, l'inventrice de la Fronde. Le
## grand établi et son étau, le tableau à outils, les étagères de caisses et la radio qui grésille, les
## bidons de peinture, le poêle fait d'un bidon, un vélo à moitié fait dont la roue tourne toute seule,
## des roues pendues au mur, Clapet (le robot de bidons et de boîtes de conserve qui hoche la tête et
## cligne des yeux), la machine à bulles (un ventilateur, une bassine) ; le jour, Bricole (ou son
## apprenti) et un Frondeur qui répare son skate ; la nuit, Bricole qui soude tard, ou l'apprenti qui
## dort sur le matelas.
static func _atelier(M) -> void:
	var R = M.R
	var k = R.kit
	var nuit: bool = L._nuit(M)
	var room0 = M.room
	var o: Node3D = I._node(M, R.P(0, 0, 0))          # un repère : en local, les coordonnées de la pièce
	# ---------------------------------------------------------------- l'établi (au fond, à gauche) et son étau
	var ex: Transform3D = _etabli_mine(M, -0.9, -2.55, 0.0, 2.2)
	var vise: Vector3 = ex * Vector3(0.8, 1.0, 0.2)
	k.cyl(ex * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(0.95, 1.0, 0.2)), 0.025, 0.025, 0.3, "argent", 8)
	for g in range(3):
		k.cyl(ex * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(-0.7 + g * 0.22, 0.97, 0.15 - g * 0.05)), 0.07 + g * 0.02, 0.07 + g * 0.02, 0.02, "cuivre" if g != 1 else "fer", 10)
	for b in range(5):
		k.cyl(ex * _atelier_t(-0.15 + b * 0.07, 0.92, 0.25), 0.018, 0.018, 0.02, "argent", 6)
	k.box(ex * Transform3D(Basis(Vector3.UP, 0.5), Vector3(0.2, 0.935, -0.15)), Vector3(0.3, 0.03, 0.05), "fer", 1.0)
	# la lampe de travail au-dessus de l'établi
	k.cyl(R.L(-0.9, 2.05, -2.25), 0.005, 0.005, R.H - 2.05, "fer", 4, false)
	k.cyl(R.L(-0.9, 1.92, -2.25), 0.17, 0.05, 0.14, "fer", 12)
	L._mesh(I._node(M, R.P(-0.9, 1.93, -2.25)), I._sph(0.05), R.mat("lumiere"))
	L._lampe(M, R.P(-0.9, 1.8, -2.1), Color(1.0, 0.92, 0.78), 0.8, 3.5)
	# ---------------------------------------------------------------- le tableau à outils (au-dessus de l'établi)
	var tb: Transform3D = R.L(-0.9, 1.72, -2.96)
	k.box(tb, Vector3(2.0, 0.85, 0.03), "bois", 1.0)
	R.mark_wall(-0.9, 1.72, -3.0, 1.05)
	for i in range(9):
		var tx: float = -0.8 + i * 0.2
		var ty: float = 0.02 + (i % 2) * 0.05
		match i % 3:
			0:          # une clé
				k.box(tb * _atelier_t(tx, ty - 0.04, 0.025), Vector3(0.035, 0.32, 0.012), "fer", 1.0)
				for sj in [-1.0, 1.0]:
					k.box(tb * _atelier_t(tx + sj * 0.028, ty + 0.15, 0.025), Vector3(0.02, 0.07, 0.012), "fer", 1.0)
			1:          # un marteau
				k.box(tb * _atelier_t(tx, ty - 0.05, 0.03), Vector3(0.03, 0.3, 0.015), "noir", 1.0)
				k.box(tb * _atelier_t(tx, ty + 0.12, 0.035), Vector3(0.15, 0.05, 0.04), "fer", 1.0)
			2:          # une pince
				for sj2 in [-1.0, 1.0]:
					k.box(tb * Transform3D(Basis(Vector3.BACK, sj2 * 0.16), Vector3(tx, ty - 0.03, 0.025)), Vector3(0.022, 0.3, 0.012), "noir", 1.0)
				k.cyl(tb * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(tx, ty + 0.06, 0.04)), 0.02, 0.02, 0.02, "fer", 8)
		k.box(tb * _atelier_t(tx, ty + 0.21, 0.02), Vector3(0.012, 0.03, 0.03), "fer", 1.0)
	# ---------------------------------------------------------------- les étagères de caisses (au fond, à droite)
	for cx in [1.0, 1.55, 2.1]:
		for lv in range(3):
			if float(cx) > 2.0 and lv == 2:
				continue
			var cxf: Transform3D = R.L(float(cx), 0.25 + lv * 0.5, -2.72, 0)
			k.box(cxf, Vector3(0.5, 0.48, 0.5), "bois_clair", 0.6)
			for sy in [-0.15, 0.0, 0.15]:
				k.box(cxf * _atelier_t(0, float(sy), 0.252), Vector3(0.46, 0.07, 0.01), "bois_sombre", 1.0)
	k.col_box(R.L(1.55, 0.75, -2.72), Vector3(1.6, 1.5, 0.5))
	R.reserve(1.55, -2.72, 1.8, 0.7)
	# un bocal de boulons, une pile de boîtes de conserve, et la radio, sur les caisses
	k.cyl(R.L(1.0, 1.5, -2.72), 0.1, 0.1, 0.22, "verre", 12, false)
	k.cyl(R.L(1.0, 1.72, -2.72), 0.105, 0.105, 0.03, "fer", 12)
	for bj in range(6):
		k.box(R.L(0.95 + (bj % 3) * 0.04, 1.52 + floori(bj / 3.0) * 0.03, -2.74 + (bj % 2) * 0.05, bj * 20.0), Vector3(0.03, 0.02, 0.03), "argent" if bj % 2 == 0 else "cuivre", 1.0)
	for cj in range(3):
		k.cyl(R.L(2.02 + (cj % 2) * 0.16, 1.0 + floori(cj / 2.0) * 0.14, -2.72), 0.06, 0.06, 0.14, "argent", 10)
	var rp: Vector3 = R.P(1.55, 1.5, -2.72)
	var radio: Node3D = I._node(M, rp)
	L._mesh(radio, I._boxm(Vector3(0.4, 0.22, 0.16)), L._m(M, "radio118", Color(0.25, 0.6, 0.58), 0.6, 0.1), _atelier_t(0, 0.11, 0))
	L._mesh(radio, I._boxm(Vector3(0.2, 0.15, 0.01)), R.mat("noir"), _atelier_t(-0.07, 0.11, 0.081))
	L._mesh(radio, L._cylm(0.04, 0.04, 0.02, 12), L._m(M, "cadran118", Color(1.0, 0.75, 0.35), 0.4, 0.0, 1.4), Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0.11, 0.13, 0.08)))
	L._mesh(radio, L._cylm(0.02, 0.02, 0.03, 8), R.mat("argent"), Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0.11, 0.05, 0.08)))
	_atelier_tube(radio, Vector3(0.15, 0.22, -0.04), Vector3(0.28, 0.55, -0.06), 0.005, R.mat("argent"))
	# ---------------------------------------------------------------- les bidons de peinture (devant les caisses)
	var pots: Array = [[0.95, 0.0, -2.2, 0], [1.3, 0.0, -2.24, 2], [1.1, 0.29, -2.2, 1]]
	for e in pots:
		var pn: Node3D = I._node(M, R.P(float(e[0]), float(e[1]), float(e[2])))
		var pm: StandardMaterial3D = _atelier_peint(M, int(e[3]))
		L._mesh(pn, L._cylm(0.13, 0.13, 0.28, 14), R.mat("argent"), _atelier_t(0, 0.14, 0))
		L._mesh(pn, L._cylm(0.132, 0.132, 0.16, 14, false), pm, _atelier_t(0, 0.14, 0))
		L._mesh(pn, L._cylm(0.125, 0.125, 0.01, 14), pm, _atelier_t(0, 0.285, 0))
		L._mesh(pn, I._boxm(Vector3(0.03, 0.08, 0.005)), pm, _atelier_t(0.05, 0.25, 0.132))
	k.box(R.L(1.12, 0.6, -2.2, 30), Vector3(0.04, 0.02, 0.25), "bois_clair", 1.0)
	k.col_box(R.L(1.12, 0.3, -2.22), Vector3(0.65, 0.6, 0.35))
	R.reserve(1.12, -2.22, 0.75, 0.45)
	# ---------------------------------------------------------------- le poêle fait d'un bidon (mur de gauche)
	var pp: Vector3 = R.P(-2.0, 0, -1.45)
	var rouille: StandardMaterial3D = L._m(M, "rouille118", Color(0.55, 0.3, 0.18), 0.85, 0.3)
	var poele: Node3D = I._node(M, pp)
	L._mesh(poele, L._cylm(0.27, 0.27, 0.72, 16), rouille, _atelier_t(0, 0.46, 0))
	for fy in [0.3, 0.62]:
		k.ring(Transform3D(Basis(), pp + Vector3.UP * float(fy)), 0.27, 0.295, 0.03, "fer", 16)
	for fp in range(3):
		var af: float = TAU * fp / 3.0
		k.box(Transform3D(Basis(), pp + Vector3(cos(af) * 0.18, 0.05, sin(af) * 0.18)), Vector3(0.05, 0.1, 0.05), "fer", 1.0)
	k.box(Transform3D(Basis(Vector3.UP, PI * 0.5), pp + Vector3(0.272, 0.42, 0)), Vector3(0.22, 0.16, 0.02), "flamme", 1.0)
	k.cyl(Transform3D(Basis(), pp + Vector3.UP * 0.82), 0.07, 0.07, R.H - 0.82, "fer", 10, false)
	k.cyl(Transform3D(Basis(), pp + Vector3(0.1, 0.82, 0.08)), 0.11, 0.08, 0.15, "cuivre", 10)
	k.col_cyl(pp, 0.32, 0.9)
	R.reserve(-2.0, -1.45, 0.8, 0.8)
	var feu: OmniLight3D = L._lampe(M, pp + Vector3(0.5, 0.45, 0), Color(1.0, 0.55, 0.25), 0.9 if nuit else 0.5, 3.0)
	R.flames.append([feu, 0.9 if nuit else 0.5])
	# ---------------------------------------------------------------- le matelas (mur de gauche, devant)
	k.box(R.L(-1.55, 0.08, 0.35), Vector3(0.85, 0.16, 1.8), "tissu_bleu", 1.0)
	k.box(R.L(-1.55, 0.2, -0.36), Vector3(0.6, 0.1, 0.3), "tissu_creme", 1.0)
	k.box(R.L(-1.75, 0.165, 0.7), Vector3(0.22, 0.01, 0.2), "tissu_jaune", 1.0)
	if nuit:
		k.box(R.L(-1.55, 0.19, 0.5), Vector3(0.88, 0.05, 1.3), "tissu_rouge", 1.0)
	else:
		k.cyl(Transform3D(Basis(Vector3.BACK, PI * 0.5), R.P(-1.15, 0.27, 1.05)), 0.1, 0.1, 0.8, "tissu_rouge", 10)
	R.reserve(-1.55, 0.35, 1.0, 1.9)
	# ---------------------------------------------------------------- Clapet, le robot de bidons (mur de droite)
	var cp: Vector3 = R.P(1.95, 0, -1.3)
	var clap: Node3D = I._node(M, cp, -90.0)
	var bidon: StandardMaterial3D = L._m(M, "clapet118_bidon", Color(0.82, 0.25, 0.18), 0.6, 0.35)
	var conserve: StandardMaterial3D = L._m(M, "clapet118_conserve", Color(0.78, 0.8, 0.82), 0.3, 0.85)
	for sx in [-1.0, 1.0]:
		L._mesh(clap, L._cylm(0.07, 0.07, 0.22, 10), conserve, _atelier_t(float(sx) * 0.1, 0.13, 0))
		L._mesh(clap, I._boxm(Vector3(0.13, 0.04, 0.2)), L._fer(M), _atelier_t(float(sx) * 0.1, 0.02, 0.03))
		L._mesh(clap, L._cylm(0.055, 0.055, 0.3, 10), conserve, Transform3D(Basis(Vector3.BACK, float(sx) * 0.35), Vector3(float(sx) * 0.27, 0.5, 0.03)))
		for pj in [-1.0, 1.0]:
			L._mesh(clap, I._boxm(Vector3(0.02, 0.07, 0.02)), L._fer(M), _atelier_t(float(sx) * 0.33 + float(pj) * 0.02, 0.33, 0.03))
	L._mesh(clap, L._cylm(0.2, 0.2, 0.48, 16), bidon, _atelier_t(0, 0.48, 0))
	for ry in [0.3, 0.66]:
		L._mesh(clap, L._tore(0.195, 0.215), L._fer(M), _atelier_t(0, float(ry), 0))
	L._mesh(clap, I._boxm(Vector3(0.14, 0.12, 0.02)), L._fer(M), _atelier_t(0, 0.47, 0.2))
	L._mesh(clap, I._sph(0.022), L._m(M, "clapet118_voyant", Color(1.0, 0.75, 0.2), 0.4, 0.0, 1.6), _atelier_t(0.08, 0.58, 0.19))
	L._mesh(clap, L._cylm(0.03, 0.03, 0.1, 8), L._fer(M), _atelier_t(0, 0.77, 0))
	var tete := Node3D.new()
	clap.add_child(tete)
	tete.position = Vector3(0, 0.8, 0)
	var visage := Node3D.new()
	tete.add_child(visage)
	L._mesh(visage, L._cylm(0.13, 0.13, 0.22, 16), conserve, _atelier_t(0, 0.12, 0))
	L._mesh(visage, L._cylm(0.132, 0.132, 0.09, 16, false), L._m(M, "clapet118_etiquette", Color(0.95, 0.82, 0.3), 0.8), _atelier_t(0, 0.09, 0))
	L._mesh(visage, L._cylm(0.13, 0.13, 0.01, 16), conserve, Transform3D(Basis(Vector3.RIGHT, -0.5), Vector3(0, 0.26, -0.06)))
	var oeil: StandardMaterial3D = L._m(M, "clapet118_oeil", Color(0.45, 1.0, 0.6), 0.4, 0.0, 2.0)
	for sx2 in [-1.0, 1.0]:
		L._mesh(visage, I._sph(0.032), oeil, _atelier_t(float(sx2) * 0.05, 0.15, 0.12))
		L._mesh(visage, L._tore(0.032, 0.042), L._fer(M), Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(float(sx2) * 0.05, 0.15, 0.125)))
	L._mesh(visage, L._cylm(0.006, 0.006, 0.18, 6), L._fer(M), _atelier_t(0.05, 0.32, 0))
	L._mesh(visage, I._sph(0.025), L._m(M, "clapet118_boule", Color(1.0, 0.4, 0.3), 0.4, 0.0, 1.5), _atelier_t(0.05, 0.42, 0))
	L._balance(M, tete, Vector3.RIGHT, 0.14, 2.4, 0.0)
	k.col_cyl(cp, 0.3, 1.1)
	R.reserve(1.95, -1.3, 0.8, 0.8)
	var bip: Label3D = L._etiquette(M, cp + Vector3(0, 1.45, 0), "Bip ! Bouïp !")
	# ---------------------------------------------------------------- la machine à bulles (mur de droite, devant)
	var mb: Vector3 = R.P(1.95, 0, 0.45)
	k.box(Transform3D(Basis(), mb + Vector3.UP * 0.25), Vector3(0.5, 0.5, 0.5), "bois_clair", 0.6)
	for sy2 in [0.12, 0.38]:
		k.box(Transform3D(Basis(Vector3.UP, PI * 0.5), mb + Vector3(-0.252, float(sy2), 0)), Vector3(0.46, 0.07, 0.01), "bois_sombre", 1.0)
	k.col_box(Transform3D(Basis(), mb + Vector3.UP * 0.25), Vector3(0.5, 0.5, 0.5))
	R.reserve(1.95, 0.45, 0.7, 0.7)
	var ven: Node3D = I._node(M, mb + Vector3.UP * 0.5, -90.0)
	L._mesh(ven, L._cylm(0.1, 0.12, 0.04, 12), L._fer(M), _atelier_t(0, 0.02, 0))
	L._mesh(ven, L._cylm(0.02, 0.02, 0.22, 8), L._fer(M), _atelier_t(0, 0.13, 0))
	L._mesh(ven, L._cylm(0.06, 0.06, 0.12, 12), L._fer(M), Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0.27, -0.06)))
	L._mesh(ven, L._tore(0.19, 0.205), R.mat("argent"), Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0.27, 0.04)))
	for cg in range(4):
		L._mesh(ven, I._boxm(Vector3(0.006, 0.4, 0.006)), R.mat("argent"), Transform3D(Basis(Vector3.BACK, PI * cg / 4.0), Vector3(0, 0.27, 0.045)))
	var helice := Node3D.new()
	ven.add_child(helice)
	helice.position = Vector3(0, 0.27, 0.02)
	for hb in range(3):
		var ah: float = TAU * hb / 3.0
		L._mesh(helice, I._boxm(Vector3(0.07, 0.15, 0.01)), _atelier_peint(M, 1), Transform3D(Basis(Vector3.BACK, ah) * Basis(Vector3.UP, 0.4), Vector3(-sin(ah), cos(ah), 0) * 0.09))
	L._mesh(ven, L._tore(0.12, 0.135), L._m(M, "anneau118", Color(0.3, 0.75, 0.95), 0.4), Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0.27, 0.17)))
	var bs: Vector3 = R.P(1.95, 0, 1.1)
	k.cyl(Transform3D(Basis(), bs), 0.24, 0.27, 0.2, "argent", 16)
	L._mesh(I._node(M, bs + Vector3.UP * 0.2), L._cylm(0.245, 0.245, 0.012, 16), L._m(M, "savon118", Color(0.75, 0.9, 1.0, 0.75), 0.05, 0.0, 0.3))
	_atelier_tube(o, Vector3(1.95, 0.2, 0.95), Vector3(1.95, 0.55, 0.62), 0.015, L._m(M, "tuyau118", Color(0.9, 0.45, 0.6), 0.6))
	k.col_cyl(bs, 0.28, 0.22)
	R.reserve(1.95, 1.1, 0.6, 0.6)
	var bulles: CPUParticles3D = _atelier_bulles(M, ven.global_transform * Vector3(0, 0.27, 0.2), Vector3(-1.0, 0.25, 0.0), 14)
	# ---------------------------------------------------------------- le vélo à moitié fait (au milieu), sur son support
	var velo: Node3D = I._node(M, R.P(0.7, 0, 0.65))
	var cadre: StandardMaterial3D = L._m(M, "velo118", Color(0.2, 0.65, 0.62), 0.5, 0.3)
	var arr := Vector3(-0.48, 0.42, 0)
	var pedal := Vector3(-0.05, 0.38, 0)
	var selle := Vector3(-0.2, 0.86, 0)
	var direc := Vector3(0.36, 0.86, 0)
	var avant := Vector3(0.5, 0.42, 0)
	for tu in [[arr, pedal], [arr, selle], [pedal, selle], [pedal, direc], [selle, direc]]:
		_atelier_tube(velo, tu[0], tu[1], 0.02, cadre)
	for sz in [-1.0, 1.0]:
		_atelier_tube(velo, direc, avant + Vector3(0, 0, float(sz) * 0.05), 0.014, cadre)
	_atelier_tube(velo, selle, selle + Vector3(-0.02, 0.08, 0), 0.012, R.mat("argent"))
	L._mesh(velo, I._boxm(Vector3(0.24, 0.05, 0.12)), R.mat("noir"), _atelier_t(-0.23, 0.96, 0))
	_atelier_tube(velo, direc, direc + Vector3(-0.03, 0.14, 0), 0.014, R.mat("argent"))
	_atelier_tube(velo, Vector3(0.33, 1.0, -0.24), Vector3(0.33, 1.0, 0.24), 0.013, R.mat("argent"))
	for sg in [-1.0, 1.0]:
		L._mesh(velo, L._cylm(0.018, 0.018, 0.09, 8), R.mat("noir"), Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0.33, 1.0, float(sg) * 0.22)))
		L._mesh(velo, I._boxm(Vector3(0.03, 0.15, 0.015)), R.mat("argent"), Transform3D(Basis(Vector3.BACK, 0.5 * float(sg)), pedal + Vector3(0, 0, float(sg) * 0.07)))
	L._mesh(velo, L._tore(0.06, 0.08), R.mat("argent"), Transform3D(Basis(Vector3.RIGHT, PI * 0.5), pedal + Vector3(0, 0, 0.04)))
	L._mesh(velo, I._boxm(Vector3(0.05, 0.42, 0.34)), L._fer(M), _atelier_t(-0.48, 0.21, 0))
	L._mesh(velo, I._boxm(Vector3(0.05, 0.38, 0.3)), L._fer(M), _atelier_t(-0.05, 0.19, 0))
	var elan := Node3D.new()
	velo.add_child(elan)
	elan.position = avant
	var roue: Node3D = _atelier_roue(M, elan, 0.33)
	L._tourne(M, roue, Vector3.BACK, -1.3)
	k.col_box(R.L(0.7, 0.45, 0.65), Vector3(1.3, 0.9, 0.3))
	R.reserve(0.7, 0.65, 1.8, 0.6)
	var clonk: Label3D = L._etiquette(M, vise + Vector3(0, 0.45, 0.1), "Clonk !")
	# des roues pendues au mur de devant (à droite de la porte), et un cadre tout nu au-dessus
	for wi in range(2):
		var rw: Node3D = I._node(M, R.P(1.3 + wi * 0.62, 1.7 - wi * 0.12, 2.9))
		_atelier_roue(M, rw, 0.27)
		k.box(R.L(1.3 + wi * 0.62, 1.99 - wi * 0.12, 2.94), Vector3(0.03, 0.06, 0.1), "fer", 1.0)
	R.mark_wall(1.6, 1.7, 3.0, 0.7)
	# ---------------------------------------------------------------- les affiches
	_atelier_affiche(M, R.L(-1.55, 1.55, 2.96, 180), Vector2(0.6, 0.85), "strates/affiche_soupapes_1.png")
	R.mark_wall(-1.55, 1.55, 3.0, 0.4)
	_atelier_affiche(M, R.L(-2.46, 1.75, -2.4, 90), Vector2(0.5, 0.7), "boucan/affiche_concert_2.png")
	R.mark_wall(-2.5, 1.75, -2.4, 0.3)
	_atelier_affiche(M, R.L(2.46, 1.85, -1.95, -90), Vector2(0.55, 0.75), "strates/affiche_soupapes_2.png")
	R.mark_wall(2.5, 1.85, -1.95, 0.35)
	_atelier_affiche(M, R.L(2.46, 1.8, 1.5, -90), Vector2(0.6, 0.6), "boucan/graffiti_4.png")
	R.mark_wall(2.5, 1.8, 1.5, 0.35)
	L._lampe(M, R.P(1.2, 2.0, 0.3), Color(0.92, 0.95, 1.0), 0.4, 3.0)
	# ---------------------------------------------------------------- ce qui bouge : les yeux de Clapet, le ventilateur
	M.ctx["bulles118"] = 1.0
	M.ctx["eveil118"] = 0.0
	L._chaque(M, func(delta: float, t: float) -> void:
		var ev: float = maxf(0.0, float(M.ctx.get("eveil118", 0.0)) - delta)
		M.ctx["eveil118"] = ev
		var cyc: float = fmod(t, 3.7)
		var ferme: bool = cyc < 0.14 or (cyc > 0.4 and cyc < 0.52 and int(t / 3.7) % 3 == 0)
		if ev > 0.0:
			ferme = fmod(t, 0.45) < 0.1
		oeil.emission_energy_multiplier = 0.0 if ferme else (4.5 if ev > 0.0 else 2.0)
		if is_instance_valid(helice):
			helice.rotate_object_local(Vector3.BACK, delta * 5.0 * float(M.ctx.get("bulles118", 1.0))))
	# ---------------------------------------------------------------- les gens
	if nuit:
		var bri: Node = L._patron(M, -0.25, -1.75, 180.0, "bricoler", ["Oh, de la visite ! Mets les lunettes, là, sur le clou. Je soude encore un peu : le pont de la draisine a un boulon qui fait des caprices.",
			"Bonsoir ! Chut, l'atelier dort. Sauf moi. Et la soudure. Et Clapet, qui fait semblant."])
		if bri != null:
			var et: CPUParticles3D = _atelier_etincelles(M, vise + Vector3(0, 0.05, 0.05))
			var lw: OmniLight3D = L._lampe(M, vise + Vector3(0, 0.25, 0.3), Color(0.65, 0.78, 1.0), 0.0, 3.0)
			L._chaque(M, func(_delta: float, t: float) -> void:
				var on: bool = fmod(t, 3.2) < 2.0
				if is_instance_valid(et):
					et.emitting = on
				if is_instance_valid(lw):
					lw.light_energy = (1.0 + randf() * 0.9) if on else 0.0)
			L._souvent(M, 5.0, 9.0, func() -> void:
				M.main.sfx("soudure", vise, -12.0))
			M.ctx["entree"] = "L'Atelier Libre, la nuit : le poêle rougeoie, Clapet cligne des yeux dans son coin, et au fond, sous la lampe, Bricole soude encore, dans une pluie d'étincelles."
		else:
			var dor: Node = L._gens(M, "garcon", -1.55, 0.35, 180.0, "dormir", ["Zzz… Passe-moi la clé de douze… Zzz…", "Zzz… Non, Clapet, pas le grille-pain… Zzz…"])
			L._causer(M, dor, ["Mmh… Zzz… Hein ? Oh, bonsoir… Je garde l'atelier. Les yeux fermés, mais je le garde.", "Chut… Bricole est rentrée. Moi, je dors ici, à côté du poêle. C'est le meilleur lit de la Fronde."],
				[["clapet", "Clapet dort aussi ?", ["Clapet ne dort jamais. Il fait semblant, pour me tenir compagnie. Ses yeux clignotent toute la nuit, comme une veilleuse. Ça me rassure."]],
				["bricole", "Où est Bricole ?", ["Chez elle, enfin. Elle a dit : « Éteins le poêle à minuit. » Il est quelle heure ? … Ne réponds pas. Zzz…"]]])
			M.ctx["entree"] = "L'Atelier Libre, la nuit : le poêle rougeoie, la machine à bulles se repose, et sur un matelas, près du feu, l'apprenti de Bricole ronfle tout doucement. Dans un coin, Clapet cligne des yeux."
	else:
		var bri2: Node = L._patron(M, -0.9, -1.85, 180.0, "bricoler", ["Attention, ça va… PSCHIIIT ! … Voilà. Ça a marché. Enfin, je crois. Salut, camarade ! Tu as un truc cassé ? Non ? Tu en auras un.",
			"Salut, camarade ! Tiens-moi ça. Non, pas comme ça. Comme ça. Voilà. Ne bouge plus pendant dix minutes."])
		if bri2 == null:
			var app: Node = L._gens(M, "garcon", -0.9, -1.85, 180.0, "bricoler", ["Bricole m'a dit : « Une vis toute seule, c'est une vis qui attend ses copines. » Alors je lui cherche des copines.",
				"J'ai réparé un grille-pain ! Il sonne quand le pain est prêt. À trois heures du matin, mais il sonne."])
			L._causer(M, app, ["Salut, camarade ! Bricole est sortie chercher des boulons au Troc. Je garde l'atelier. Ne touche pas à Clapet, il est chatouilleux.", "Bienvenue à l'Atelier Libre ! Ici, tout se répare. Et on répare ensemble."],
				[["bricole", "Où est Bricole ?", ["Au Troc, chez Lumi, ou à l'Assemblée, ou dans la fosse à surveiller son orgue à vapeur. Elle dit que le tuyau trente-sept est fragile des poumons."]],
				["clapet", "C'est quoi, ce robot ?", ["C'est Clapet ! Bricole l'a fait avec un bidon, six boîtes de conserve et une soupape. Il ne sert à rien. Enfin, si : il dit bonjour. C'est déjà beaucoup."]],
				["regle", "Quelle est la règle, ici ?", ["Tu prends un outil, tu répares ton truc, tu remets l'outil. La troisième partie, c'est la plus dure. Surtout pour Ressort."]]])
		var fr: Node = L._gens(M, "homme", 0.45, -0.75, 165.0, "bricoler", ["Ma planche fait « clac-clac-pschit ». Le « pschit », Bricole dit que c'est normal. C'est elle qui l'a ajouté.",
			"Une roue de wagonnet, deux boulons, un peu de graisse… et hop, je redescends la Baleine ce soir."])
		L._causer(M, fr, ["Salut, camarade ! Tu tiens la roue ? Non ? Pas grave, je la tiens avec les dents.", "Salut ! Je répare mon skate. Ici, personne ne répare pour toi : on répare avec toi. C'est mieux. C'est plus long, mais c'est mieux."],
			[["skate", "Il a quoi, ton skate ?", ["Une roue qui voulait partir toute seule. Je l'ai rattrapée au bord du Gouffre. Elle a eu peur. Moi aussi. Maintenant, on la serre bien."]],
			["ressort", "Tu connais Ressort ?", ["Le fils de Bricole ? Tout le monde le connaît ! Il traverse le Pont des Frondeurs en skate. Doucement, très doucement. Il dit qu'il n'est pas fou, qu'il est courageux. C'est différent."]]])
		R.tabouret(0.65, -1.35)
		k.box(R.L(0.65, 0.47, -1.35, 30), Vector3(0.2, 0.025, 0.7), "bois", 1.0)
		for wk in [-1.0, 1.0]:
			for wl in [-1.0, 1.0]:
				k.cyl(R.L(0.65, 0.48, -1.35, 30) * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(float(wk) * 0.07 + 0.02, 0.04, float(wl) * 0.24)), 0.035, 0.035, 0.04, "tissu_jaune", 10)
		M.ctx["entree"] = str(L._pick(M, ["L'Atelier Libre : deux conteneurs réunis, de la ferraille utile partout, un établi qui a tout vu, et dans un coin, un robot fait de bidons qui te salue de la tête.",
			"Ça sent la graisse, la soudure et le savon. Des bulles flottent dans l'atelier ; une roue de vélo tourne toute seule sur son support ; une radio grésille sur les caisses.",
			"« Rien ne se jette ! » dit une affiche au mur. À l'Atelier Libre, tout attend sa deuxième vie : les vélos, les bidons, les boîtes de conserve… et même le robot, qui s'appelle Clapet."]))
	# ---------------------------------------------------------------- ce qu'on fait : un coup de clé, réveiller Clapet, les bulles
	M.act(ex * Vector3(0.8, 1.0, 0.75), "E : donner un coup de clé", func() -> void:
		var n: int = int(M.ctx.get("cle118", 0))
		M.ctx["cle118"] = n + 1
		M.main.sfx("soudure" if n % 2 == 1 else "touche_bois", vise)
		L._montrer(M, clonk, 1.6)
		if is_instance_valid(elan):
			var tw: Tween = M.room.create_tween()
			tw.tween_property(elan, "rotation:z", elan.rotation.z - TAU * 3.0, 2.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		M.say(str(ATL118_CLE[n % ATL118_CLE.size()]), 6.0)
	, 1.0)
	M.act(R.P(1.35, 1.0, -1.45), "E : réveiller Clapet", func() -> void:
		M.main.sfx("robot_bip", cp + Vector3.UP)
		M.ctx["eveil118"] = 4.0
		if is_instance_valid(visage):
			var tw2: Tween = M.room.create_tween()
			for _i in range(5):
				tw2.tween_property(visage, "rotation:x", 0.35, 0.12)
				tw2.tween_property(visage, "rotation:x", -0.1, 0.12)
			tw2.tween_property(visage, "rotation:x", 0.0, 0.2)
		L._montrer(M, bip, 1.8)
		var st: Dictionary = M.state()
		if not bool(st.get("clapet118", false)):
			st["clapet118"] = true
			M.give([["bague_boulon", 1]], "Bip-bouïp ! Clapet hoche la tête à toute vitesse, fouille dans son ventre de bidon… Clapet te tend un boulon poli : une bague de boulon. Ses yeux clignotent de fierté.\n")
		else:
			M.say(str(L._pick(M, ATL118_CLAPET)), 5.0)
	, 1.2)
	M.act(R.P(1.35, 1.0, 1.0), "E : lancer la machine à bulles", func() -> void:
		if float(M.ctx.get("bulles118", 1.0)) > 1.5:
			return
		M.main.sfx("bulles", mb + Vector3.UP * 0.7)
		M.ctx["bulles118"] = 5.0
		if is_instance_valid(bulles):
			bulles.amount = 70
			bulles.initial_velocity_max = 0.9
		M.say(str(L._pick(M, ATL118_BULLES)), 6.0)
		await M.get_tree().create_timer(6.0).timeout
		if not _la(M, room0):
			return
		M.ctx["bulles118"] = 1.0
		if is_instance_valid(bulles):
			bulles.amount = 14
			bulles.initial_velocity_max = 0.55
	, 1.2)
	# la radio grésille tout bas, une fois, en entrant
	_atelier_radio(M, rp)


# =================================================================== le Troc

## LE TROC (fr_troc) : le conteneur de Lumi, la gardienne du Troc, bijoutière de boulons et de cristal.
## Le comptoir de palettes et son présentoir (des bagues de boulons et des colliers de cristal qui
## scintillent), les étagères pleines de récup (bocaux de boulons, vieux disques, livres, lampes,
## boîtes), l'établi de bijouterie (de minuscules cristaux, des boulons polis, la lampe-loupe), les
## caisses où l'on fouille, le tableau « ICI ON TROQUE » (dessiné à la craie), la pile de fanzines, le
## phonographe à cornet, la guirlande d'ampoules qui clignotent, le chat qui dort sur les livres ; le
## jour, Lumi (ou sa remplaçante), un enfant qui troque ses billes et un Frondeur qui fouille ; la nuit,
## Lumi qui polit une bague, ou la remplaçante qui compte les boulons.
static func _troc(M) -> void:
	var R = M.R
	var k = R.kit
	var nuit: bool = L._nuit(M)
	var room0 = M.room
	var o: Node3D = I._node(M, R.P(0, 0, 0))          # un repère : en local, les coordonnées de la pièce
	var orm: StandardMaterial3D = L._m(M, "or118_troc", Color(0.95, 0.75, 0.3), 0.3, 0.9, 0.3)
	var perle_a: StandardMaterial3D = L._m(M, "perle118_a", Color(0.6, 0.85, 1.0, 0.9), 0.1, 0.0, 1.0)
	var perle_b: StandardMaterial3D = L._m(M, "perle118_b", Color(0.75, 0.6, 1.0, 0.9), 0.1, 0.0, 1.0)
	# ---------------------------------------------------------------- les étagères de récup (au fond, à droite)
	var sh: Transform3D = R.L(1.05, 0, -2.78)
	k.box(sh * _atelier_t(0, 1.05, -0.17), Vector3(2.4, 2.1, 0.02), "bois_sombre", 1.0)
	for sx in [-1.0, 1.0]:
		k.box(sh * _atelier_t(float(sx) * 1.2, 1.05, 0), Vector3(0.04, 2.1, 0.36), "bois_sombre", 1.0)
	for y in [0.1, 0.6, 1.1, 1.6, 2.05]:
		k.box(sh * _atelier_t(0, float(y), 0), Vector3(2.4, 0.03, 0.36), "bois", 1.0)
	# en bas : des boîtes de bois, de fer, de verre (et ce qui brille dedans)
	k.box(sh * _atelier_t(-0.8, 0.3, 0), Vector3(0.5, 0.38, 0.3), "bois", 1.0)
	k.box(sh * _atelier_t(-0.2, 0.29, 0), Vector3(0.4, 0.36, 0.3), "fer", 1.0)
	k.box(sh * _atelier_t(0.38, 0.28, 0), Vector3(0.45, 0.33, 0.28), "verre", 1.0)
	for gi in range(5):
		L._mesh(o, I._sph(0.025), orm if gi % 2 == 0 else perle_a, _atelier_t(1.05 + 0.25 + gi * 0.06, 0.15, -2.78 + (gi % 2) * 0.06))
	k.box(sh * _atelier_t(0.9, 0.27, 0), Vector3(0.4, 0.3, 0.3), "bois_clair", 1.0)
	# puis : les bocaux de boulons, les vieux disques
	for bi in range(5):
		var bx: Transform3D = sh * _atelier_t(-1.0 + bi * 0.21, 0.615, 0)
		k.cyl(bx, 0.08, 0.08, 0.22, "verre", 12, false)
		k.cyl(bx * _atelier_t(0, 0.22, 0), 0.085, 0.085, 0.03, "fer" if bi % 2 == 0 else "cuivre", 12)
		for bo in range(4):
			k.box(bx * Transform3D(Basis(Vector3.UP, bo * 0.7), Vector3(-0.03 + (bo % 2) * 0.05, 0.02 + floori(bo / 2.0) * 0.03, 0.0)), Vector3(0.03, 0.02, 0.03), "argent" if (bi + bo) % 3 != 0 else "or", 1.0)
	for di in range(7):
		k.cyl(sh * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(0.25 + di * 0.035, 0.775, 0)), 0.15, 0.15, 0.012, "noir", 20)
	k.cyl(sh * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(0.48, 0.775, 0)), 0.05, 0.05, 0.014, "tissu_rouge", 12)
	k.box(sh * _atelier_t(0.85, 0.72, 0), Vector3(0.38, 0.22, 0.26), "verre", 1.0)
	for ci in range(4):
		L._mesh(o, I._sph(0.03), _cristal(M, ci % 2 == 1), _atelier_t(1.05 + 0.75 + ci * 0.06, 0.66, -2.78))
	# puis : les livres, deux vieilles lampes
	var lx: float = -1.12
	var li: int = 0
	while lx < 0.05:
		var lw: float = 0.04 + (li % 3) * 0.015
		var lh: float = 0.24 + (li % 4) * 0.03
		k.box(sh * Transform3D(Basis(Vector3.BACK, 0.03 * ((li % 3) - 1)), Vector3(lx + lw * 0.5, 1.115 + lh * 0.5, 0)), Vector3(lw, lh, 0.24), "tissu_" + ["rouge", "bleu", "vert", "brun", "jaune", "violet", "creme"][li % 7], 0.5)
		lx += lw + 0.006
		li += 1
	for lp in [0.45, 0.9]:
		var lt: Transform3D = sh * _atelier_t(float(lp), 1.115, 0)
		k.cyl(lt, 0.07, 0.07, 0.03, "cuivre", 10)
		k.cyl(lt * _atelier_t(0, 0.03, 0), 0.012, 0.012, 0.22, "cuivre", 6)
		k.cyl(lt * _atelier_t(0, 0.2, 0), 0.13, 0.06, 0.14, "tissu_jaune" if float(lp) < 0.6 else "tissu_turquoise", 12)
	# en haut : des boîtes, et le chapeau à plume qu'une dame d'en haut a troqué
	k.box(sh * _atelier_t(-0.75, 1.75, 0), Vector3(0.45, 0.28, 0.28), "fer", 1.0)
	k.box(sh * _atelier_t(-0.2, 1.73, 0), Vector3(0.4, 0.24, 0.28), "bois", 1.0)
	k.box(sh * _atelier_t(0.3, 1.74, 0), Vector3(0.36, 0.26, 0.26), "verre", 1.0)
	k.cyl(sh * _atelier_t(0.8, 1.615, 0), 0.2, 0.2, 0.02, "tissu_noir", 16)
	k.cyl(sh * _atelier_t(0.8, 1.635, 0), 0.11, 0.1, 0.14, "tissu_noir", 14)
	k.box(sh * Transform3D(Basis(Vector3.BACK, -0.6), Vector3(0.95, 1.82, 0.02)), Vector3(0.04, 0.3, 0.012), "tissu_blanc", 1.0)
	k.col_box(sh * _atelier_t(0, 1.05, 0), Vector3(2.4, 2.1, 0.36))
	R.reserve(1.05, -2.78, 2.6, 0.6)
	# ---------------------------------------------------------------- l'établi de bijouterie (au fond, à gauche)
	var bj: Node3D = I._node(M, R.P(-1.45, 0, -2.6))
	var bjx: Transform3D = R.L(-1.45, 0, -2.6)
	k.box(bjx * _atelier_t(0, 0.85, 0), Vector3(1.4, 0.06, 0.65), "bois", 1.0)
	for sx2 in [-1.0, 1.0]:
		for sz2 in [-1.0, 1.0]:
			k.box(bjx * _atelier_t(float(sx2) * 0.62, 0.41, float(sz2) * 0.26), Vector3(0.07, 0.82, 0.07), "bois_sombre", 1.0)
	for dr in range(3):
		k.box(bjx * _atelier_t(-0.4 + dr * 0.4, 0.74, 0.3), Vector3(0.36, 0.14, 0.04), "bois_clair", 1.0)
		k.cyl(bjx * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(-0.4 + dr * 0.4, 0.74, 0.32)), 0.015, 0.015, 0.02, "cuivre", 8)
	k.box(bjx * _atelier_t(-0.25, 0.885, 0.05), Vector3(0.42, 0.012, 0.26), "tissu_violet", 1.0)
	for ci2 in range(7):
		L._mesh(bj, I._sph(0.01 + (ci2 % 3) * 0.004), _cristal(M, ci2 % 3 == 2), _atelier_t(-0.4 + ci2 * 0.05, 0.9, 0.0 + (ci2 % 2) * 0.08))
	for oi in range(5):
		L._mesh(bj, I._sph(0.016), orm, _atelier_t(-0.38 + oi * 0.07, 0.903, 0.13))
	for ni in range(4):
		L._mesh(bj, L._cylm(0.022, 0.022, 0.014, 6), L._laiton(M), _atelier_t(0.08 + ni * 0.06, 0.89, 0.12 - (ni % 2) * 0.05))
	k.cyl(bjx * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0.35, 0.93, -0.05)), 0.05, 0.05, 0.06, "cuivre", 12)
	for pj in [-1.0, 1.0]:
		k.box(bjx * Transform3D(Basis(Vector3.UP, 0.3 + float(pj) * 0.12), Vector3(0.12, 0.89, 0.18)), Vector3(0.012, 0.012, 0.16), "noir", 1.0)
	# la lampe-loupe
	_atelier_tube(bj, Vector3(0.5, 0.88, -0.22), Vector3(0.5, 1.38, -0.18), 0.012, R.mat("argent"))
	_atelier_tube(bj, Vector3(0.5, 1.38, -0.18), Vector3(0.22, 1.3, 0.02), 0.012, R.mat("argent"))
	L._mesh(bj, L._tore(0.075, 0.09), L._laiton(M), Transform3D(Basis(Vector3.RIGHT, 0.35), Vector3(0.18, 1.27, 0.04)))
	L._mesh(bj, L._cylm(0.076, 0.076, 0.005, 16), R.mat("verre"), Transform3D(Basis(Vector3.RIGHT, 0.35), Vector3(0.18, 1.27, 0.04)))
	L._lampe(M, R.P(-1.3, 1.2, -2.5), Color(1.0, 0.9, 0.75), 0.6, 2.5)
	k.col_box(bjx * _atelier_t(0, 0.44, 0), Vector3(1.4, 0.88, 0.65))
	R.reserve(-1.45, -2.6, 1.6, 0.9)
	# ---------------------------------------------------------------- le comptoir de palettes, son présentoir
	var cx: Transform3D = R.L(0.75, 0, -1.05)
	var cn: Node3D = I._node(M, R.P(0.75, 0, -1.05))
	k.box(cx * _atelier_t(0, 0.5, 0), Vector3(2.1, 0.98, 0.5), "bois_sombre", 1.0)
	for si in range(4):
		k.box(cx * _atelier_t(0, 0.12 + si * 0.25, 0.27), Vector3(2.2, 0.14, 0.03), "bois_clair", 1.0)
	for px in [-1.0, 0.0, 1.0]:
		k.box(cx * _atelier_t(float(px), 0.5, 0.3), Vector3(0.1, 0.98, 0.04), "bois", 1.0)
	k.box(cx * _atelier_t(0, 1.02, 0), Vector3(2.3, 0.05, 0.65), "bois", 1.0)
	k.col_box(cx * _atelier_t(0, 0.52, 0), Vector3(2.2, 1.05, 0.6))
	R.reserve(0.75, -1.05, 2.4, 0.8)
	# le présentoir des bagues (deux gradins de velours noir), les anneaux d'or et leurs petits cristaux
	k.box(cx * _atelier_t(-0.65, 1.095, 0.02), Vector3(0.52, 0.1, 0.3), "tissu_noir", 1.0)
	k.box(cx * _atelier_t(-0.65, 1.19, -0.06), Vector3(0.52, 0.1, 0.15), "tissu_noir", 1.0)
	for ri in range(5):
		var ry: float = 1.175 if ri % 2 == 0 else 1.27
		var rz: float = 0.08 if ri % 2 == 0 else -0.06
		L._mesh(cn, L._tore(0.02, 0.029), orm, Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(-0.85 + ri * 0.1, ry, rz)))
		L._mesh(cn, I._sph(0.012), perle_a if ri % 2 == 0 else perle_b, _atelier_t(-0.85 + ri * 0.1, ry + 0.032, rz))
	# le porte-colliers : un T de laiton, un collier de perles de cristal, un collier de boulons
	_atelier_tube(cn, Vector3(-0.15, 1.045, 0.0), Vector3(-0.15, 1.5, 0.0), 0.01, L._laiton(M))
	_atelier_tube(cn, Vector3(-0.32, 1.5, 0.0), Vector3(0.02, 1.5, 0.0), 0.01, L._laiton(M))
	for nk in range(2):
		var x0: float = -0.24 + nk * 0.18
		for pi in range(9):
			var a: float = PI * (pi + 0.5) / 9.0
			var pos := Vector3(x0 + cos(a) * 0.07, 1.49 - sin(a) * 0.17, 0.015 * nk)
			if nk == 0:
				L._mesh(cn, I._sph(0.014), perle_a if pi % 2 == 0 else perle_b, _atelier_t(pos.x, pos.y, pos.z))
			else:
				L._mesh(cn, L._cylm(0.014, 0.014, 0.01, 6), orm, Transform3D(Basis(Vector3.RIGHT, PI * 0.5), pos))
	# un bocal de boulons sur le comptoir, et les billes de l'enfant (le jour) ou les piles de boulons (la nuit)
	k.cyl(cx * _atelier_t(0.55, 1.045, -0.05), 0.07, 0.07, 0.2, "verre", 12, false)
	k.cyl(cx * _atelier_t(0.55, 1.245, -0.05), 0.075, 0.075, 0.025, "cuivre", 12)
	if nuit:
		for pl in range(3):
			for hi in range(3 + pl):
				L._mesh(cn, L._cylm(0.022, 0.022, 0.014, 6), L._laiton(M), _atelier_t(0.05 + pl * 0.09, 1.052 + hi * 0.015, 0.12))
	else:
		var bc: Array = [Color(0.3, 0.75, 0.4), Color(0.25, 0.5, 0.95), Color(0.95, 0.35, 0.3), Color(0.95, 0.8, 0.25)]
		for bl in range(4):
			L._mesh(cn, I._sph(0.018), L._m(M, "bille118_%d" % bl, bc[bl], 0.15), _atelier_t(-0.35 + bl * 0.04, 1.063, 0.2 - (bl % 2) * 0.03))
		L._mesh(cn, L._cylm(0.025, 0.025, 0.016, 6), L._laiton(M), _atelier_t(-0.1, 1.053, 0.15))
	L._lampe(M, R.P(0.75, 2.0, -1.2), Color(1.0, 0.88, 0.7), 0.7, 3.5)
	# ---------------------------------------------------------------- le tableau « ICI ON TROQUE » (mur de gauche, à la craie)
	var pz: Transform3D = R.L(-2.44, 1.65, -1.45, 90)
	var pzn: Node3D = I._node(M, pz.origin, 90.0)
	k.box(pz * _atelier_t(0, 0, -0.012), Vector3(1.1, 0.8, 0.02), "bois", 1.0)
	k.box(pz, Vector3(1.0, 0.7, 0.02), "noir", 1.0)
	var craie: StandardMaterial3D = L._m(M, "craie118", Color(0.95, 0.95, 0.9), 0.9)
	var mots: Array = [[-0.3, 0.12], [-0.08, 0.1], [0.2, 0.26]]
	for mo in mots:
		L._mesh(pzn, I._boxm(Vector3(float(mo[1]), 0.06, 0.004)), craie, _atelier_t(float(mo[0]), 0.22, 0.013))
	L._mesh(pzn, I._boxm(Vector3(0.75, 0.012, 0.004)), craie, _atelier_t(0, 0.14, 0.013))
	for hx in range(6):
		var ah: float = TAU * hx / 6.0
		L._mesh(pzn, I._boxm(Vector3(0.075, 0.012, 0.004)), craie, Transform3D(Basis(Vector3.BACK, ah + PI * 0.5), Vector3(-0.27 + cos(ah) * 0.065, -0.1 + sin(ah) * 0.065, 0.013)))
	L._mesh(pzn, L._tore(0.025, 0.035), craie, Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(-0.27, -0.1, 0.013)))
	for ar in [-1.0, 1.0]:
		var ay: float = -0.06 if float(ar) > 0.0 else -0.14
		L._mesh(pzn, I._boxm(Vector3(0.22, 0.012, 0.004)), craie, _atelier_t(0.03, ay, 0.013))
		L._mesh(pzn, I._boxm(Vector3(0.05, 0.012, 0.004)), craie, Transform3D(Basis(Vector3.BACK, float(ar) * 0.6), Vector3(0.03 + float(ar) * 0.1, ay + 0.015, 0.013)))
		L._mesh(pzn, I._boxm(Vector3(0.05, 0.012, 0.004)), craie, Transform3D(Basis(Vector3.BACK, -float(ar) * 0.6), Vector3(0.03 + float(ar) * 0.1, ay - 0.015, 0.013)))
	L._mesh(pzn, L._tore(0.045, 0.058), craie, Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0.3, -0.1, 0.013)))
	L._mesh(pzn, I._boxm(Vector3(0.025, 0.025, 0.004)), craie, _atelier_t(0.3, -0.035, 0.013))
	R.mark_wall(-2.4, 1.65, -1.45, 0.55)
	# ---------------------------------------------------------------- les caisses de récup où l'on fouille (mur de gauche)
	var fx: Transform3D = R.L(-2.12, 0, 0.25, 90)
	for fo in [-0.3, 0.3]:
		for lv in range(2):
			var fb: Transform3D = fx * _atelier_t(float(fo), lv * 0.42, 0)
			k.box(fb * _atelier_t(0, 0.015, 0), Vector3(0.56, 0.03, 0.38), "bois_clair", 1.0)
			k.box(fb * _atelier_t(0, 0.4, 0), Vector3(0.56, 0.03, 0.38), "bois_clair", 1.0)
			k.box(fb * _atelier_t(0, 0.21, -0.18), Vector3(0.56, 0.4, 0.02), "bois_clair", 1.0)
			for sd in [-1.0, 1.0]:
				k.box(fb * _atelier_t(float(sd) * 0.27, 0.21, 0), Vector3(0.02, 0.4, 0.38), "bois_clair", 1.0)
	var bric: Array = [[-0.4, 0.03, "cuivre", 0], [-0.18, 0.03, "tissu_rouge", 1], [0.2, 0.03, "fer", 1], [0.4, 0.03, "tissu_vert", 0],
		[-0.4, 0.45, "tissu_bleu", 1], [-0.2, 0.45, "argent", 0], [0.22, 0.45, "tissu_jaune", 1], [0.4, 0.45, "noir", 0]]
	for e in bric:
		var bt: Transform3D = fx * _atelier_t(float(e[0]), float(e[1]), 0.02)
		if int(e[3]) == 0:
			k.cyl(bt, 0.07, 0.07, 0.15, str(e[2]), 10)
		else:
			k.box(bt * _atelier_t(0, 0.07, 0), Vector3(0.14, 0.14, 0.2), str(e[2]), 1.0)
	var casque: Node3D = I._node(M, fx * Vector3(-0.2, 0.84, 0.0))
	L._mesh(casque, I._sph(0.15), L._m(M, "casque118", Color(0.95, 0.75, 0.2), 0.5), Transform3D(Basis.from_scale(Vector3(1.0, 0.7, 1.1)), Vector3.ZERO))
	L._mesh(casque, L._cylm(0.04, 0.04, 0.04, 10), R.mat("lumiere"), Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0.05, 0.14)))
	k.cyl(fx * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0.3, 0.92, 0.0)), 0.08, 0.08, 0.06, "cuivre", 12)
	k.col_box(fx * _atelier_t(0, 0.42, 0), Vector3(1.2, 0.84, 0.4))
	R.reserve(-2.12, 0.25, 0.6, 1.3)
	# ---------------------------------------------------------------- la pile de fanzines (devant, à gauche)
	k.box(R.L(-1.9, 0.2, 1.25, 8), Vector3(0.5, 0.4, 0.4), "bois_clair", 0.6)
	for zi in range(8):
		k.box(R.L(-1.9 + (zi % 3) * 0.006, 0.404 + zi * 0.008, 1.25, 8.0 + (zi % 4) * 3.0), Vector3(0.3, 0.008, 0.21), "papier", 1.0)
	_atelier_affiche(M, R.L(-1.9, 0.47, 1.25, 20) * Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), Vector3.ZERO), Vector2(0.21, 0.3), "boucan/fanzine_couverture.png")
	k.col_box(R.L(-1.9, 0.22, 1.25), Vector3(0.5, 0.44, 0.4))
	R.reserve(-1.9, 1.25, 0.6, 0.55)
	# ---------------------------------------------------------------- les livres, et le chat qui dort dessus (mur de droite)
	R.etagere(2.2, -0.35, -90, 1.2, 0.85, true, 2)
	var hy: float = 0.825
	for hb in range(3):
		var hh: float = 0.07 if hb != 1 else 0.06
		k.box(R.L(2.2, hy + hh * 0.5, -0.35, 4.0 - hb * 6.0), Vector3(0.26, hh, 0.36), "tissu_" + ["rouge", "vert", "bleu"][hb], 0.5)
		hy += hh
	R.chat(2.2, -0.35, 200.0, Color(0.95, 0.6, 0.28), true, hy)
	# ---------------------------------------------------------------- le phonographe à cornet (devant, à droite)
	var ph: Vector3 = R.P(1.95, 0, 1.15)
	k.box(Transform3D(Basis(), ph + Vector3.UP * 0.3), Vector3(0.55, 0.6, 0.5), "bois", 1.0)
	k.col_box(Transform3D(Basis(), ph + Vector3.UP * 0.3), Vector3(0.55, 0.6, 0.5))
	R.reserve(1.95, 1.15, 0.7, 0.7)
	var pn: Node3D = I._node(M, ph + Vector3.UP * 0.6, -90.0)
	L._mesh(pn, I._boxm(Vector3(0.34, 0.14, 0.34)), R.mat("bois_sombre"), _atelier_t(0, 0.07, 0))
	L._mesh(pn, L._cylm(0.01, 0.01, 0.12, 6), L._laiton(M), Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(0.22, 0.08, 0.05)))
	var disque := Node3D.new()
	pn.add_child(disque)
	disque.position = Vector3(0.0, 0.146, 0.04)
	L._mesh(disque, L._cylm(0.14, 0.14, 0.012, 24), R.mat("noir"))
	L._mesh(disque, L._cylm(0.04, 0.04, 0.014, 12), L._m(M, "etiquette118", Color(0.85, 0.25, 0.2), 0.7))
	L._mesh(disque, I._boxm(Vector3(0.02, 0.016, 0.05)), orm, _atelier_t(0.09, 0, 0))
	_atelier_tube(pn, Vector3(0.13, 0.16, -0.12), Vector3(0.05, 0.16, 0.06), 0.006, L._laiton(M))
	var cornet := Node3D.new()
	pn.add_child(cornet)
	cornet.position = Vector3(-0.12, 0.14, -0.12)
	L._mesh(cornet, L._cylm(0.014, 0.014, 0.22, 8), L._laiton(M), _atelier_t(0, 0.11, 0))
	L._mesh(cornet, L._cylm(0.2, 0.02, 0.36, 20, false), L._laiton(M), Transform3D(Basis(Vector3.RIGHT, 0.95), Vector3(0, 0.22, 0) + Vector3(0, cos(0.95), sin(0.95)) * 0.18))
	var note: Label3D = L._etiquette(M, ph + Vector3(0, 1.45, 0), "♪")
	# ---------------------------------------------------------------- la guirlande d'ampoules (au plafond, en zigzag)
	var amp: Array = []
	var ac: Array = [Color(1.0, 0.85, 0.45), Color(1.0, 0.4, 0.35), Color(0.45, 1.0, 0.55), Color(0.45, 0.65, 1.0)]
	for ci3 in range(4):
		amp.append(L._m(M, "ampoule118_%d" % ci3, ac[ci3], 0.3, 0.0, 1.5))
	var fil: Array = [Vector3(-2.2, 2.32, -2.6), Vector3(2.2, 2.32, -1.3), Vector3(-2.2, 2.32, 0.3), Vector3(2.2, 2.32, 1.9)]
	var noir: Material = R.mat("noir")
	var nb: int = 0
	for s in range(fil.size() - 1):
		var a0: Vector3 = fil[s]
		var a1: Vector3 = fil[s + 1]
		var prev: Vector3 = a0
		for j in range(1, 11):
			var t: float = j / 10.0
			var p: Vector3 = a0.lerp(a1, t) + Vector3.DOWN * sin(t * PI) * 0.18
			_atelier_tube(o, prev, p, 0.004, noir)
			prev = p
			if j % 2 == 1:
				L._mesh(o, L._cylm(0.015, 0.015, 0.03, 8), noir, _atelier_t(p.x, p.y - 0.02, p.z))
				L._mesh(o, I._sph(0.035), amp[nb % 4], _atelier_t(p.x, p.y - 0.065, p.z))
				nb += 1
	L._lampe(M, R.P(0, 2.0, -0.3), Color(1.0, 0.85, 0.6), 0.5, 4.5)
	# ---------------------------------------------------------------- les affiches, le tapis
	_atelier_affiche(M, R.L(-1.5, 1.6, 2.96, 180), Vector2(0.6, 0.85), "boucan/affiche_concert_3.png")
	R.mark_wall(-1.5, 1.6, 3.0, 0.4)
	_atelier_affiche(M, R.L(2.36, 1.75, -2.0, -90), Vector2(0.5, 0.7), "strates/affiche_soupapes_3.png")
	R.mark_wall(2.4, 1.75, -2.0, 0.3)
	_atelier_affiche(M, R.L(1.5, 1.65, 2.96, 180), Vector2(0.55, 0.55), "boucan/graffiti_7.png")
	R.mark_wall(1.5, 1.65, 3.0, 0.35)
	R.tapis(0.15, 0.6, 0, 1.6, 1.1)
	# ---------------------------------------------------------------- ce qui bouge : les ampoules, les bijoux, le disque
	M.ctx["phono118"] = 0.0
	L._chaque(M, func(delta: float, t: float) -> void:
		for c4 in range(amp.size()):
			var m4: StandardMaterial3D = amp[c4]
			var on: float = 0.5 + 0.5 * sin(t * 1.4 + c4 * 1.57)
			if int(t * 2.0 + c4) % 7 == 0:
				on = 0.0
			m4.emission_energy_multiplier = 0.3 + 1.8 * on
		perle_a.emission_energy_multiplier = 0.6 + 1.6 * pow(maxf(0.0, sin(t * 2.3)), 6.0)
		perle_b.emission_energy_multiplier = 0.6 + 1.6 * pow(maxf(0.0, sin(t * 1.9 + 2.0)), 6.0)
		orm.emission_energy_multiplier = 0.2 + 0.9 * pow(maxf(0.0, sin(t * 1.6 + 1.0)), 8.0)
		var v: float = float(M.ctx.get("phono118", 0.0))
		if v > 0.0 and is_instance_valid(disque):
			disque.rotate_object_local(Vector3.UP, delta * 3.5 * v))
	# ---------------------------------------------------------------- les gens
	if nuit:
		var lumi: Node = L._patron(M, -1.45, -1.95, 180.0, "bricoler", ["Oh, bonsoir ! Approche, mais doucement : je polis une bague, et elle est timide. Ça brille, hein ?",
			"Tiens, de la visite ! Je profite du calme pour polir. Les bagues brillent mieux quand la Fronde dort."])
		if lumi == null:
			var rem: Node = L._gens(M, "femme", 0.75, -1.7, 0.0, "comptoir", ["Mille deux cent douze… mille deux cent treize… Zut. Mille deux cent… Je recommence.",
				"Lumi dit qu'il faut compter les boulons la nuit. Le jour, ils bougent."])
			L._causer(M, rem, ["Oh, bonsoir ! Je compte les boulons du Troc. Ne parle pas trop fort : je perds le fil à chaque mot.", "Salut, camarade ! Le Troc est fermé, mais un rien, ça s'échange à toute heure."],
				[["compte", "Combien de boulons ?", ["Mille deux cent quatorze. Ou quinze. Il y en a un qui roule toujours sous le comptoir. Je crois qu'il fait exprès."]],
				["lumi", "Où est Lumi ?", ["Au concert, avec tous ses bijoux ! Sous les projecteurs, elle fait des reflets partout. Rivet l'appelle la boule à facettes de la Fronde."]]])
			M.ctx["entree"] = "Le Troc, la nuit : la guirlande clignote doucement, le chat dort sur les livres, et derrière le comptoir, quelqu'un compte des boulons à voix basse."
		else:
			M.ctx["entree"] = "Le Troc, la nuit : la guirlande clignote doucement, le chat dort sur les livres, et sous la lampe-loupe, Lumi polit une bague qui brille de plus en plus."
	else:
		var lumi2: Node = L._patron(M, 0.75, -1.65, 0.0, "comptoir", ["Bonjour ! Approche, regarde. Tu peux toucher. Ça brille, hein ? Ce sont des boulons. Si, si. Regarde de plus près.",
			"Salut, camarade ! Tu as quelque chose dans tes poches ? Tout le monde a un trésor dans ses poches. Même un bouton. Surtout un bouton."])
		if lumi2 == null:
			var rem2: Node = L._gens(M, "femme", 0.75, -1.65, 0.0, "comptoir", ["Un boulon, c'est un bijou qui s'ignore. C'est Lumi qui le dit. Moi, je le répète.",
				"On échange ? Tout se troque, ici. Même les histoires."])
			L._causer(M, rem2, ["Salut, camarade ! Je garde le Troc pendant que Lumi est sortie. Ça brille, hein ? Je dis ça comme elle.", "Bonjour ! Regarde, choisis, et dis-moi ce que tu as. Ici, on ne demande pas « c'est combien ? »."],
				[["lumi", "Où est Lumi ?", ["Quelque part dans la Fronde, à faire briller quelque chose. Ou à la Cantine, chez Mémé Gamelle. Elle revient toujours avec un boulon de plus."]],
				["regle", "Comment ça marche, le troc ?", ["Tu donnes ce que tu n'utilises plus, tu prends ce dont tu as besoin. Une seule règle : on ne prend jamais le dernier de quelque chose. Il faut laisser une chance au suivant."]]])
		var enf: Node = L._gens(M, "garcon", 0.4, -0.4, 180.0, "comptoir", ["Trois billes contre un boulon ! … Bon, quatre. Mais la bleue compte double.",
			"Ce boulon-là a une forme de cœur. Si on le regarde de très près. De très, très près."])
		L._causer(M, enf, ["Salut ! Tu troques quoi, toi ? Moi, mes billes. Sauf la verte. La verte, c'est ma porte-bonheur.", "Chut ! Je négocie. C'est très sérieux, le troc."],
			[["billes", "Pourquoi un boulon ?", ["Pour faire une bague, comme Ysaé ! Lumi dit que je dois d'abord apprendre à regarder. Je regarde. Pour l'instant, je vois un boulon."]],
			["verte", "Et la bille verte ?", ["Je l'ai trouvée au bord du Gouffre. Elle brille dans le noir. Ressort voulait l'échanger contre trois tours de skate. J'ai dit non. Enfin, j'ai dit « peut-être »."]]])
		var fou: Node = L._gens(M, "homme", -1.35, -0.15, -90.0, "bricoler", ["Il me faut un ressort pour ma guitare. Ou une guitare pour mon ressort. Je verrai ce que je trouve d'abord.",
			"Oh, un grille-pain ! … Non, c'est une radio. Non, c'est un grille-pain qui capte la radio."])
		L._causer(M, fou, ["Salut, camarade ! Pousse-toi pas, il y a de la place pour deux fouilleurs.", "Salut ! Si tu trouves une soupape en forme de canard, elle est à moi. Enfin, je l'ai vue le premier."],
			[["trouve", "Tu as trouvé quelque chose ?", ["Une chaussette, un réveil et une soupape en forme de canard. Je les prends tous les trois, et je laisse mon vieux casque à la place. C'est la règle."]]])
		M.ctx["entree"] = str(L._pick(M, ["Le Troc : un conteneur plein à craquer de récup, un comptoir de palettes, des bagues de boulons qui brillent sous la guirlande, et un chat qui dort sur les livres.",
			"Ça brille partout : des bocaux de boulons, des cristaux minuscules, des colliers qui scintillent. Sur le mur, un tableau à la craie, et dans un coin, un phonographe à cornet.",
			"Au Troc, rien n'a de prix : tout s'échange. Une bague contre une bille, une lampe contre une histoire. Au-dessus du comptoir, les ampoules de la guirlande clignotent comme des clins d'œil."]))
	# ---------------------------------------------------------------- ce qu'on fait : fouiller, écouter le phonographe, troquer
	M.act(R.P(-1.5, 0.8, 0.65), "E : fouiller les étagères", func() -> void:
		var st: Dictionary = M.state()
		var n: int = int(st.get("fouille118", 0))
		st["fouille118"] = n + 1
		M.main.sfx("ramasse", R.P(-2.0, 0.6, 0.25))
		M.say(str(TROC118_FOUILLE[n % TROC118_FOUILLE.size()]), 7.0)
	, 1.1)
	M.act(R.P(1.45, 1.0, 1.15), "E : écouter le phonographe", func() -> void:
		if float(M.ctx.get("phono118", 0.0)) > 0.0:
			return
		var n2: int = int(M.ctx.get("disque118", 0))
		M.ctx["disque118"] = n2 + 1
		M.main.sfx("luth" if n2 % 2 == 0 else "guitare_riff", ph + Vector3.UP * 0.8)
		M.ctx["phono118"] = 1.0
		L._montrer(M, note, 3.0)
		if is_instance_valid(cornet):
			var tw: Tween = M.room.create_tween()
			tw.tween_property(cornet, "rotation:y", 0.45, 1.2).set_trans(Tween.TRANS_SINE)
			tw.tween_property(cornet, "rotation:y", -0.2, 1.6).set_trans(Tween.TRANS_SINE)
			tw.tween_property(cornet, "rotation:y", 0.0, 1.0).set_trans(Tween.TRANS_SINE)
		M.say(str(TROC118_PHONO[n2 % TROC118_PHONO.size()]), 7.0)
		await M.get_tree().create_timer(6.0).timeout
		if _la(M, room0):
			M.ctx["phono118"] = 0.0
	, 1.1)
	M.act(R.P(1.45, 1.0, -0.45), "E : troquer", func() -> void:
		var st2: Dictionary = M.state()
		if bool(st2.get("troc118", false)):
			M.say("Lumi dit que le troc est fait, et bien fait. Ici, on ne troque pas deux fois le même rien.", 5.0)
			return
		st2["troc118"] = true
		M.main.sfx("clochette", R.P(0.75, 1.1, -1.05))
		var inv: Node = M.main.get("inventory_v28")
		if inv != null and int(inv.count("bague_boulon")) > 0:
			M.give([["fanzine", 1]], "Tu poses « rien » sur le comptoir, avec beaucoup de soin. « Tu as déjà une bague de boulon ? Alors, pour ton rien, voilà de quoi lire. » On te tend un fanzine tout corné, plein de dessins et de potins.\n")
		else:
			M.give([["bague_boulon", 1]], "Tu poses « rien » sur le comptoir, avec beaucoup de soin. On le regarde de très près, on hoche la tête : « Du rien de première qualité. Ça se fait rare. » En échange, on te glisse une bague de boulon au doigt.\n")
	, 1.0)


# =================================================================== V118 (lieux_b) : le bureau du contremaître,
# la Grande Horloge, la loge des Soupapes
# (_la(M, room0) : celle du fichier principal, déjà présente)

# =================================================================== le bureau du contremaître

const REGISTRE_MINE := ["LE REGISTRE DES ÉQUIPES, lundi. Équipe du matin : six mineurs, six casques, six « Bonjour, la Vieille ! ». Cristaux trouvés : quarante-deux bleus, un violet, et une chaussette. À qui est la chaussette ?",
	"LE REGISTRE DES ÉQUIPES, mardi. Pause de dix heures : chocolat d'Honorine. Pause de dix heures et quart : encore du chocolat d'Honorine. Note du contremaître, souligné deux fois : « UNE seule pause de dix heures. Merci. »",
	"LE REGISTRE DES ÉQUIPES, mercredi. Galerie quatre : un petit craquement. Tout étayé, tout vérifié, trois fois pardon à la Vieille. Elle s'est tue. Chez elle, ça veut dire « c'est bon ».",
	"LE REGISTRE DES ÉQUIPES, jeudi. Visite de gens d'en haut. Casques : mis. Ligne blanche : respectée. Bouches : grandes ouvertes devant les cristaux. Une dame a dit « oh » quatorze fois. Record battu.",
	"LE REGISTRE DES ÉQUIPES, vendredi. Pinson a chanté toute la journée : tout va bien. Cristaux trouvés : cinquante-trois. Le plus beau est parti à l'Atelier des Lumières. La Docteure Opaline a encore oublié son casque."]


## Une lampe de mineur posée à « at » (le pied de laiton, le verre, la flamme, l'anse) ; éteinte si
## « allumee » est faux (les lampes rendues, le soir, sur le râtelier).
static func _mine_lampe(M, at: Vector3, allumee: bool = true) -> Node3D:
	var n: Node3D = I._node(M, at)
	var lt: StandardMaterial3D = L._laiton(M)
	L._mesh(n, L._cylm(0.045, 0.055, 0.07, 12), lt, Transform3D(Basis(), Vector3(0, 0.035, 0)))
	L._mesh(n, L._cylm(0.035, 0.04, 0.09, 12, false), L._m(M, "verre118", Color(0.8, 0.9, 1.0, 0.25), 0.05), Transform3D(Basis(), Vector3(0, 0.115, 0)))
	L._mesh(n, L._cylm(0.03, 0.045, 0.04, 12), lt, Transform3D(Basis(), Vector3(0, 0.18, 0)))
	L._mesh(n, L._tore(0.03, 0.04), lt, Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0.235, 0)))
	var fl: StandardMaterial3D = L._m(M, "flamme118", Color(1.0, 0.72, 0.3), 0.5, 0.0, 2.5) if allumee else L._m(M, "meche118", Color(0.15, 0.12, 0.1), 0.9)
	L._mesh(n, I._sph(0.014), fl, Transform3D(Basis.from_scale(Vector3(1.0, 1.7, 1.0)), Vector3(0, 0.11, 0)))
	return n


## Un casque de mineur (la bombe jaune, le bord, la petite lampe de laiton devant) ; il regarde « yaw ».
static func _mine_casque(M, at: Vector3, yaw: float) -> Node3D:
	var n: Node3D = I._node(M, at, yaw)
	var sm := SphereMesh.new()
	sm.radius = 0.12
	sm.height = 0.12
	sm.is_hemisphere = true
	sm.radial_segments = 16
	sm.rings = 6
	var cm: StandardMaterial3D = L._m(M, "casque118", Color(0.93, 0.74, 0.22), 0.45, 0.1)
	L._mesh(n, sm, cm)
	L._mesh(n, L._cylm(0.15, 0.15, 0.012, 18), cm, Transform3D(Basis(), Vector3(0, 0.006, 0)))
	L._mesh(n, L._cylm(0.03, 0.03, 0.04, 10), L._laiton(M), Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0.07, 0.11)))
	L._mesh(n, L._cylm(0.022, 0.022, 0.005, 10), L._m(M, "verre_casque118", Color(1.0, 0.95, 0.8), 0.3, 0.0, 0.6), Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0.07, 0.132)))
	return n


## Le bureau du contremaître (la cabane de Ludovic Grisou, à côté du portail des Mines) : le bureau de
## planches couvert de papiers, la lampe de mine, le registre des équipes, le tamis aux cristaux, la carte
## des galeries à la craie, le tableau des clés de laiton (une clé accrochée = un mineur au fond), le
## râtelier des lampes, les casques sur leurs patères, Pinson le canari dans sa cage de laiton (il saute
## d'un perchoir à l'autre et chante tout bas), le poêle et son chocolat ; le jour, Ludovic (ou son
## adjoint), un mineur qui pointe, une mineuse qui se réchauffe ; la nuit, l'adjoint qui compte les
## lampes, ou Ludovic, tard.
static func _mine(M) -> void:
	var R = M.R
	var k = R.kit
	var nuit: bool = L._nuit(M)
	var room0 = M.room
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var lt: StandardMaterial3D = L._laiton(M)
	var rng: RandomNumberGenerator = L._r(M)
	# le bureau de planches (au fond, à gauche) : le plateau, les flancs, le caisson à tiroirs ; la chaise
	var bx: Transform3D = R.L(-0.9, 0, -1.05)
	k.box(bx * Transform3D(Basis(), Vector3(0, 0.76, 0)), Vector3(1.6, 0.06, 0.7), "bois_sombre", 1.0)
	for sx in [-1.0, 1.0]:
		k.box(bx * Transform3D(Basis(), Vector3(sx * 0.74, 0.37, 0)), Vector3(0.08, 0.74, 0.64), "bois_sombre", 1.0)
	k.box(bx * Transform3D(Basis(), Vector3(0.42, 0.5, 0.0)), Vector3(0.56, 0.46, 0.6), "bois", 1.0)
	for j in range(2):
		k.box(bx * Transform3D(Basis(), Vector3(0.42, 0.38 + j * 0.22, -0.305)), Vector3(0.12, 0.025, 0.02), "or", 1.0)
	k.col_box(bx * Transform3D(Basis(), Vector3(0, 0.4, 0)), Vector3(1.6, 0.8, 0.7))
	R.reserve(-0.9, -1.05, 1.8, 0.9)
	R.chaise(-1.2, -1.6, 0)
	# les papiers en désordre
	for i in range(6):
		k.box(bx * Transform3D(Basis(Vector3.UP, rng.randf_range(-0.5, 0.5)), Vector3(0.1 + rng.randf_range(-0.1, 0.1), 0.795 + i * 0.004, rng.randf_range(-0.2, 0.15))), Vector3(0.21, 0.004, 0.29), "papier", 1.0)
	# le registre des équipes, ouvert (la couverture de cuir, les deux pages, les lignes d'écriture)
	k.box(bx * Transform3D(Basis(), Vector3(-0.3, 0.8, 0.1)), Vector3(0.5, 0.02, 0.34), "cuir", 1.0)
	for s2 in [-1.0, 1.0]:
		k.box(bx * Transform3D(Basis(Vector3.BACK, s2 * 0.05), Vector3(-0.3 + s2 * 0.12, 0.815, 0.1)), Vector3(0.23, 0.012, 0.31), "papier", 1.0)
		for l2 in range(6):
			k.box(bx * Transform3D(Basis(), Vector3(-0.3 + s2 * 0.12, 0.823, -0.02 + l2 * 0.045)), Vector3(0.16 - (l2 % 3) * 0.03, 0.002, 0.008), "noir", 1.0)
	# la lampe de mine, allumée, au bout du bureau
	_mine_lampe(M, bx * Vector3(-0.65, 0.79, -0.1), true)
	L._lampe(M, bx * Vector3(-0.65, 1.05, -0.1), Color(1.0, 0.75, 0.42), 0.9 if nuit else 0.6, 3.2)
	# le tamis (un cercle de bois, la grille, des éclats de cristal bleu sur le sable)
	var tamis: Node3D = I._node(M, bx * Vector3(0.48, 0.79, 0.08))
	L._mesh(tamis, L._cylm(0.17, 0.17, 0.06, 20, false), L._m(M, "tamis118", Color(0.7, 0.55, 0.35), 0.8, 0.0, 0.0, true), Transform3D(Basis(), Vector3(0, 0.03, 0)))
	L._mesh(tamis, L._tore(0.16, 0.18), lt, Transform3D(Basis(), Vector3(0, 0.06, 0)))
	L._mesh(tamis, L._cylm(0.165, 0.165, 0.004, 20), L._m(M, "grille118", Color(0.32, 0.3, 0.3, 0.75), 0.5, 0.4), Transform3D(Basis(), Vector3(0, 0.012, 0)))
	L._mesh(tamis, L._cylm(0.12, 0.15, 0.012, 16), L._m(M, "sable118", Color(0.86, 0.68, 0.45), 1.0), Transform3D(Basis(), Vector3(0, 0.02, 0)))
	var eclats: Array = []
	for e3 in range(6):
		var a3: float = TAU * e3 / 6.0 + 0.3
		eclats.append(L._mesh(tamis, I._boxm(Vector3(0.02, 0.035, 0.02)), _cristal(M), Transform3D(Basis(Vector3(cos(a3), 0, sin(a3)).cross(Vector3.UP).normalized(), 0.6), Vector3(cos(a3) * 0.07, 0.035, sin(a3) * 0.07))))
	# la carte des galeries, à la craie sur une ardoise, au-dessus du bureau
	var mt: Transform3D = R.L(-0.9, 1.78, -hd + 0.03)
	k.box(mt * Transform3D(Basis(), Vector3(0, 0, -0.006)), Vector3(1.46, 0.88, 0.02), "bois", 1.0)
	k.box(mt, Vector3(1.36, 0.78, 0.02), "noir", 1.0)
	for ln in [[-0.6, 0.28, 0.6, 0.28], [-0.35, 0.28, -0.35, -0.25], [-0.35, -0.25, 0.2, -0.3], [0.2, -0.3, 0.45, -0.05], [0.1, 0.28, 0.25, 0.0],
			[-0.35, 0.02, -0.58, -0.1], [0.45, -0.05, 0.58, -0.28], [0.25, 0.0, 0.45, -0.05]]:
		var p0 := Vector2(float(ln[0]), float(ln[1]))
		var p1 := Vector2(float(ln[2]), float(ln[3]))
		var c0: Vector2 = (p0 + p1) * 0.5
		var dv: Vector2 = p1 - p0
		k.box(mt * Transform3D(Basis(Vector3.BACK, atan2(dv.y, dv.x)), Vector3(c0.x, c0.y, 0.013)), Vector3(dv.length() + 0.02, 0.016, 0.004), "papier", 1.0)
	for pin in [Vector2(-0.35, 0.28), Vector2(0.2, -0.3), Vector2(-0.58, -0.1), Vector2(0.58, -0.28), Vector2(0.1, 0.28)]:
		L._mesh(M.room, I._sph(0.018), lt, Transform3D(Basis(), mt * Vector3(pin.x, pin.y, 0.025)))
	L._mesh(M.room, I._sph(0.035), _cristal(M), Transform3D(Basis(), mt * Vector3(0.45, -0.05, 0.03)))
	L._mesh(M.room, I._sph(0.02), L._m(M, "punaise118", Color(0.85, 0.15, 0.12), 0.4), Transform3D(Basis(), mt * Vector3(-0.58, -0.1, 0.03)))
	R.mark_wall(-0.9, 1.78, -hd, 0.75)
	# le tableau des clés de laiton (une clé au crochet : un mineur au fond) et le compteur des jours
	var kt: Transform3D = R.L(0.65, 1.5, -hd + 0.03)
	k.box(kt, Vector3(0.7, 0.5, 0.025), "bois_clair", 1.0)
	var cles: Array = [0, 1, 2, 4, 5, 6] if not nuit else []
	for hk in range(8):
		var hx: float = -0.24 + (hk % 4) * 0.16
		var hy: float = 0.12 - floori(hk / 4.0) * 0.24
		k.box(kt * Transform3D(Basis(), Vector3(hx, hy, 0.03)), Vector3(0.015, 0.015, 0.05), "fer", 1.0)
		if hk in cles:
			var cle: Node3D = I._node(M, kt * Vector3(hx, hy - 0.005, 0.05))
			L._mesh(cle, L._tore(0.011, 0.019), lt, Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, -0.022, 0)))
			L._mesh(cle, I._boxm(Vector3(0.008, 0.07, 0.006)), lt, Transform3D(Basis(), Vector3(0, -0.075, 0)))
			L._mesh(cle, I._boxm(Vector3(0.022, 0.012, 0.006)), lt, Transform3D(Basis(), Vector3(0.01, -0.1, 0)))
			L._balance(M, cle, Vector3.BACK, 0.05, 2.6 + hk * 0.25, float(hk))
	R.mark_wall(0.65, 1.5, -hd, 0.4)
	var pa: Transform3D = R.L(0.65, 2.05, -hd + 0.03)
	k.box(pa, Vector3(0.78, 0.2, 0.02), "bois_sombre", 1.0)
	var jl := Label3D.new()
	jl.text = "JOURS SANS ACCIDENT : %d" % 4213
	jl.font_size = 28
	jl.pixel_size = 0.0011
	jl.outline_size = 0
	jl.modulate = Color(1.0, 0.88, 0.55)
	M.room.add_child(jl)
	jl.global_transform = pa * Transform3D(Basis(), Vector3(0, 0, 0.015))
	# le poêle (au fond, à droite) et la vapeur du chocolat qui chauffe dessus
	R.foyer(1.85, -1.45, 0, true)
	var vap: CPUParticles3D = L._poussiere(M, R.P(1.97, 1.1, -1.4), Vector3(0.04, 0.02, 0.04), 10, Color(1, 1, 1, 0.35), 0.06)
	vap.direction = Vector3.UP
	vap.spread = 15.0
	vap.gravity = Vector3(0, 0.12, 0)
	vap.lifetime = 2.5
	vap.preprocess = 2.5
	# le râtelier des lampes (mur de gauche) : le jour, il en reste deux ; le soir, toutes sont rentrées
	var rk: Transform3D = R.L(-hw + 0.14, 1.25, -1.2, 90)
	k.box(rk, Vector3(1.0, 0.03, 0.24), "bois", 1.0)
	for s4 in [-1.0, 1.0]:
		k.box(rk * Transform3D(Basis(), Vector3(s4 * 0.4, -0.08, -0.08)), Vector3(0.03, 0.16, 0.08), "bois_sombre", 1.0)
	for i5 in range(5 if nuit else 2):
		_mine_lampe(M, rk * Vector3(-0.4 + i5 * 0.2, 0.015, 0.0), false)
	R.mark_wall(-hw, 1.3, -1.2, 0.5)
	# les casques sur leurs patères (mur de droite, près de l'entrée)
	var pt: Transform3D = R.L(hw - 0.03, 1.72, 1.15, -90)
	k.box(pt, Vector3(0.8, 0.08, 0.03), "bois_sombre", 1.0)
	var casques: Array = []
	for i6 in range(3):
		var px6: float = -0.26 + i6 * 0.26
		k.box(pt * Transform3D(Basis(), Vector3(px6, -0.02, 0.07)), Vector3(0.025, 0.025, 0.12), "bois", 1.0)
		casques.append(_mine_casque(M, pt * Vector3(px6, -0.2, 0.16), -90.0))
	R.mark_wall(hw, 1.7, 1.15, 0.45)
	# Pinson, le canari, dans sa cage de laiton pendue près de la fenêtre
	var cc: Vector3 = R.P(-1.8, 1.55, 0.35)
	k.cyl(R.L(-1.8, 2.05, 0.35), 0.006, 0.006, R.H - 2.05, "fer", 4, false)
	var cage: Node3D = I._node(M, cc)
	L._mesh(cage, L._cylm(0.17, 0.17, 0.025, 20), lt, Transform3D(Basis(), Vector3(0, 0.0125, 0)))
	for b7 in range(14):
		var a7: float = TAU * b7 / 14.0
		L._mesh(cage, L._cylm(0.004, 0.004, 0.36, 4), lt, Transform3D(Basis(), Vector3(cos(a7) * 0.16, 0.205, sin(a7) * 0.16)))
	L._mesh(cage, L._tore(0.15, 0.17), lt, Transform3D(Basis(), Vector3(0, 0.385, 0)))
	L._mesh(cage, L._cylm(0.02, 0.165, 0.09, 16, false), lt, Transform3D(Basis(), Vector3(0, 0.43, 0)))
	L._mesh(cage, L._tore(0.02, 0.03), lt, Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0.5, 0)))
	var pa7 := Vector3(-0.07, 0.11, 0)
	var pb7 := Vector3(0.07, 0.22, 0)
	for pe in [pa7, pb7]:
		L._mesh(cage, L._cylm(0.006, 0.006, 0.28, 6), L._m(M, "perchoir118", Color(0.55, 0.4, 0.25), 0.8), Transform3D(Basis(Vector3.RIGHT, PI * 0.5), pe))
	L._mesh(cage, L._cylm(0.03, 0.025, 0.025, 12), L._m(M, "graines118", Color(0.95, 0.94, 0.9), 0.3), Transform3D(Basis(), Vector3(0.1, 0.04, 0.08)))
	var oiseau := Node3D.new()
	cage.add_child(oiseau)
	oiseau.position = pa7 + Vector3(0, 0.035, 0)
	oiseau.rotation.y = PI * 0.5
	var jaune: StandardMaterial3D = L._m(M, "canari118", Color(1.0, 0.85, 0.15), 0.6)
	L._mesh(oiseau, I._sph(0.03), jaune, Transform3D(Basis.from_scale(Vector3(0.9, 0.85, 1.3)), Vector3.ZERO))
	L._mesh(oiseau, I._sph(0.022), jaune, Transform3D(Basis(), Vector3(0, 0.03, 0.03)))
	L._mesh(oiseau, L._cylm(0.0, 0.008, 0.016, 6), L._m(M, "bec118", Color(1.0, 0.55, 0.15), 0.5), Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0.028, 0.055)))
	L._mesh(oiseau, I._boxm(Vector3(0.03, 0.006, 0.04)), jaune, Transform3D(Basis(Vector3.RIGHT, -0.4), Vector3(0, 0.0, -0.045)))
	for s8 in [-1.0, 1.0]:
		L._mesh(oiseau, I._sph(0.005), L._m(M, "oeil118", Color(0.05, 0.05, 0.05), 0.3), Transform3D(Basis(), Vector3(s8 * 0.016, 0.036, 0.045)))
	L._balance(M, cage, Vector3.FORWARD, 0.025, 4.2, 0.0)
	# il saute d'un perchoir à l'autre (un petit bond en cloche), et chante tout bas, de temps en temps
	var saut: Dictionary = {"attente": 2.0, "t": -1.0, "de": 0}
	L._chaque(M, func(delta: float, _t: float) -> void:
		if not is_instance_valid(oiseau):
			return
		var perches: Array = [pa7 + Vector3(0, 0.035, 0), pb7 + Vector3(0, 0.035, 0)]
		if float(saut["t"]) >= 0.0:
			saut["t"] = float(saut["t"]) + delta
			var u: float = clampf(float(saut["t"]) / 0.35, 0.0, 1.0)
			var a: Vector3 = perches[int(saut["de"])]
			var b: Vector3 = perches[1 - int(saut["de"])]
			oiseau.position = a.lerp(b, u) + Vector3(0, sin(u * PI) * 0.06, 0)
			if u >= 1.0:
				saut["t"] = -1.0
				saut["de"] = 1 - int(saut["de"])
				saut["attente"] = rng.randf_range(1.5, 4.5)
		else:
			saut["attente"] = float(saut["attente"]) - delta
			if float(saut["attente"]) <= 0.0:
				saut["t"] = 0.0
				var dest: Vector3 = perches[1 - int(saut["de"])]
				oiseau.rotation.y = PI * 0.5 if dest.x > oiseau.position.x else -PI * 0.5)
	var chant: Label3D = L._etiquette(M, cc + Vector3(0, 0.75, 0), "♪ Tuiii-tuiii ! ♪")
	L._souvent(M, 9.0, 16.0, func() -> void:
		if not is_instance_valid(oiseau):
			return
		M.main.sfx("chant_2", oiseau.global_position, -16.0)
		L._montrer(M, chant, 1.6))
	# la frontale qu'on essaie : elle suit la tête
	L._chaque(M, func(_delta: float, _t: float) -> void:
		var lum: Variant = M.ctx.get("frontale118", null)
		if lum == null or not is_instance_valid(lum):
			return
		var cam: Camera3D = M.get_viewport().get_camera_3d()
		if cam != null:
			(lum as OmniLight3D).global_position = cam.global_position - cam.global_transform.basis.z * 0.4 + Vector3.UP * 0.1)
	# les gens
	var chef: Node = L._patron(M, -1.2, -1.6, 0.0, "lire", ["Ah. Bonsoir. Je relis le registre des équipes. Tout le monde est rentré : le compte est bon. Entrez, mais gardez un casque à portée de main.",
		"Bonsoir. Pinson dort, la Vieille aussi. Je finis mes comptes, et j'enlève mon casque. Pas avant.",
		"Tiens, de la visite. Asseyez-vous près du poêle. Et regardez où vous mettez les pieds : même dans un bureau, la sécurité d'abord."])
	if nuit:
		if chef == null:
			var adj: Node = L._gens(M, "homme", -1.95, -0.3, -155.0, "pointer", ["Une, deux, trois, quatre, cinq lampes. Toutes rentrées, toutes éteintes. Tout le monde est à la maison.",
				"Le tableau des clés est vide : personne n'est resté au fond. C'est le plus beau tableau du monde, un tableau vide."])
			L._causer(M, adj, ["Bonsoir ! Chut, Pinson dort. Je compte les lampes, puis je ferme.", "Bon fond, et bonne nuit ! Le compte est bon : cinq lampes au râtelier, pas une clé au tableau. Ludovic sera content."],
				[["compte", "Pourquoi compter les lampes ?", ["Une lampe au râtelier, c'est un mineur à la maison. Ludovic a appris ça de son père. Le soir, il compte ses mineurs sur la Place ; moi, je compte leurs lampes. Ça fait deux comptes. On n'est jamais trop prudents."]],
				["ludovic", "Où est Ludovic ?", ["Sur son banc de la Place des Rouages, ou déjà chez lui. Il ne rentre qu'après avoir compté tout le monde. Une fois, il a compté le Petit Train. Par habitude."]]])
		M.ctx["entree"] = "Le bureau du contremaître, le soir : le poêle ronronne, le tableau des clés est vide, et les lampes de mine dorment en rang sur leur râtelier. Tout le monde est rentré."
	else:
		if chef == null:
			var adj2: Node = L._gens(M, "homme", -1.2, -1.6, 0.0, "lire", ["Quatre mille deux cent treize jours sans accident. J'ajoute un jour chaque matin. C'est mon moment préféré.",
				"Le contremaître est au front de taille. Moi, je tiens le registre. Et Pinson tient le moral."])
			L._causer(M, adj2, ["Bon fond ! Vous êtes au bureau du contremaître. Ici, le casque est obligatoire même pour lire. Enfin, presque.", "Bonne descente ! Ludovic est dans la mine. Je suis son adjoint : je compte les lampes, les clés, les cristaux, et les pauses chocolat."],
				[["ludovic", "Où est Ludovic ?", ["Au fond de la Grotte aux Cristaux, avec l'équipe du jour. Il dit bonjour à la Vieille en entrant et merci en sortant. Il ne remonte au bureau qu'à cinq heures, pour le registre."]],
				["canari", "Pourquoi un canari ?", ["C'est Pinson. Oui, un canari qui s'appelle Pinson. Il chante tant que tout va bien, alors il chante tout le temps. Ludovic dit que c'est le plus vieux mineur de l'équipe. Il a même sa petite lampe."]],
				["cles", "À quoi servent les clés ?", ["Chaque mineur a sa clé de laiton. En descendant, il l'accroche au tableau ; en remontant, il la reprend. Le soir, le tableau doit être vide. Ludovic ne rentre pas chez lui tant qu'il reste une clé."]]])
		var mineur: Node = L._gens(M, "homme", 0.65, -1.4, 180.0, "pointer", ["Clé numéro sept, accrochée. Lampe, allumée. Casque, attaché. Bonjour, la Vieille !",
			"La pause de dix heures, c'est sacré : chocolat d'Honorine. Celle de dix heures et quart aussi, mais ne le dites pas au contremaître."])
		L._causer(M, mineur, ["Bon fond ! Je pointe, et je descends. Vous venez ? Non ? Sage décision : il faut un casque.", "Bonne descente ! Enfin, pour moi. Vous, vous restez au bureau : c'est plus sûr, et il y a le poêle."],
			[["cristaux", "Vous trouvez beaucoup de cristaux ?", ["Une quarantaine par jour, des bleus surtout. Un violet, c'est une fois par semaine, et toute l'équipe applaudit. Ils partent en wagonnet à l'Atelier de la Docteure Opaline. Doucement : on ne secoue pas un cristal."]],
			["vieille", "Qui est la Vieille ?", ["La roche ! Le contremaître lui parle. Au début, j'ai ri. Maintenant, je lui dis bonjour aussi. En cachette. Et vous savez quoi ? Elle craque moins quand on est polis."]]])
		L._gens(M, "femme", 1.25, -0.45, 155.0, "boire", ["Le poêle du bureau, c'est le meilleur endroit des Strates. Après La Marmite.",
			"Un chocolat du mineur, et je redescends. La cuillère tient debout dedans : c'est comme ça qu'on sait qu'il est bon."])
		M.ctx["entree"] = str(L._pick(M, ["Le bureau du contremaître : une cabane de planches qui sent le poêle et le papier. Sur le bureau, une lampe de mine ; au mur, la carte des galeries à la craie ; près de la fenêtre, un canari qui chante.",
			"« Bonjour, la Vieille ! » crie quelqu'un en passant devant la fenêtre. Ici, à côté du portail des Mines, même la roche a droit à son bonjour.",
			"Des clés de laiton sur un tableau, des casques sur leurs patères, un registre ouvert : au bureau du contremaître, on compte tout, deux fois. Sauf les chansons du canari."]))
	# ce qu'on fait : lire le registre, essayer un casque, tamiser les cristaux
	M.act(bx * Vector3(-0.3, 1.0, 0.7), "E : lire le registre des équipes", func() -> void:
		M.main.sfx("ui_ouvrir", bx * Vector3(-0.3, 0.85, 0.1))
		var n: int = int(M.ctx.get("registre118", 0))
		M.ctx["registre118"] = n + 1
		M.say(str(REGISTRE_MINE[n % REGISTRE_MINE.size()]), 8.0)
	, 1.0)
	M.act(pt * Vector3(0, -0.6, 0.65), "E : essayer un casque de mineur", func() -> void:
		if bool(M.ctx.get("casque118", false)):
			return
		M.ctx["casque118"] = true
		var c0: Node3D = casques[L._r(M).randi() % casques.size()]
		M.main.sfx("equiper", c0.global_position)
		c0.visible = false
		var lum := OmniLight3D.new()
		lum.light_color = Color(1.0, 0.86, 0.6)
		lum.light_energy = 1.4
		lum.omni_range = 4.0
		lum.shadow_enabled = false
		M.room.add_child(lum)
		lum.global_position = c0.global_position
		M.ctx["frontale118"] = lum
		M.say(str(L._pick(M, ["Tu mets le casque, tu boucles la jugulaire, et clic : la petite lampe s'allume sur ton front. Partout où tu regardes, il fait jour. « Parfait, dit-on derrière toi. Bien attaché. »",
			"Le casque est un peu grand : il te tombe sur les yeux. Tu le remontes, et la lampe de laiton s'allume. Pinson te regarde, la tête penchée, comme pour dire : « Ça te va bien. »",
			"Clic ! Ta lampe frontale s'allume. Tu tournes la tête : la carte des galeries, le registre, le canari… Tout s'éclaire à tour de rôle. Tu te sens prêt à dire bonjour à la Vieille."])), 6.0)
		await M.get_tree().create_timer(9.0).timeout
		if not _la(M, room0):
			return
		if is_instance_valid(lum):
			lum.queue_free()
		M.ctx.erase("frontale118")
		if is_instance_valid(c0):
			c0.visible = true
		M.ctx["casque118"] = false
	, 1.2)
	M.act(bx * Vector3(0.5, 1.0, 0.7), "E : tamiser les cristaux", func() -> void:
		M.main.sfx("sable_effondre", tamis.global_position, -6.0)
		var tw: Tween = M.room.create_tween()
		for i9 in range(4):
			tw.tween_property(tamis, "rotation:z", 0.08, 0.12)
			tw.tween_property(tamis, "rotation:z", -0.08, 0.12)
		tw.tween_property(tamis, "rotation:z", 0.0, 0.1)
		var st: Dictionary = M.state()
		if not bool(st.get("tamis118", false)):
			st["tamis118"] = true
			M.main.sfx("cristal_chante", tamis.global_position)
			if is_instance_valid(eclats[0]):
				(eclats[0] as Node3D).visible = false
			M.give([["eclat_cristal", 1]], "Tu secoues le tamis : le sable de grès file entre les mailles, et au fond, un petit éclat bleu se met à briller. « Gardez-le, c'est votre premier filon ! » dit-on derrière toi.\n")
		else:
			M.say(str(L._pick(M, ["Tu secoues le tamis : le sable s'en va, les éclats restent. Ceux-là partiront à l'Atelier des Lumières. Doucement : on ne secoue pas un cristal. Enfin, pas trop.",
				"Chhh, chhh… Le sable de grès coule comme dans un sablier. Il ne reste que du bleu. On dirait un petit morceau de ciel tombé au fond de la mine.",
				"Tu tamises encore. Rien de nouveau, sauf un caillou en forme de cœur. Le mineur dit que la Vieille t'aime bien."])), 6.0)
	, 1.0)


# =================================================================== la Grande Horloge

const PLAQUE_HORLOGE := "LA GRANDE HORLOGE DES STRATES. Bâtie il y a deux cents ans par Maître Gédéon Rouet, horloger, avec les roues fondues à la Grande Forge et les cristaux choisis aux Mines. Elle donne l'heure à toute la caverne, et au Petit Train, qui fait semblant de l'écouter. Gravé plus bas, en tout petit : « Ici, il est toujours un peu plus tard qu'en haut : la lumière met du temps à descendre. »"


## Une tige (un arbre de transmission, un bras de loupe) de a à b, de rayon r, dans la matière « mat ».
static func _horloge_tige(M, a: Vector3, b: Vector3, r: float, mat: Material) -> void:
	var d: Vector3 = b - a
	if d.length() < 0.001:
		return
	var n: Vector3 = d.normalized()
	var bs := Basis(Quaternion(Vector3.UP, n)) if absf(n.dot(Vector3.UP)) < 0.999 else Basis()
	L._mesh(M.room, L._cylm(r, r, d.length(), 8), mat, Transform3D(bs, (a + b) * 0.5))


## La Grande Horloge (l'intérieur de la tour de la Place des Rouages) : le bâti de fer, les roues de
## laiton à moyeux de cristal qui tournent chacune à sa vitesse, la roue d'échappement qui avance d'une
## dent toutes les deux secondes (tic… tac…), l'ancre aux palettes de cristal, le grand balancier à
## lentille de cristal, les deux poids qui descendent lentement sur leurs câbles (la manivelle pour les
## remonter), les deux cadrans de verre dépoli vus de dos, tout en haut (leurs aiguilles à l'heure du
## jeu), l'échelle de fer et sa petite plateforme, l'établi de l'horloger (la loupe, les huiliers) ; le
## jour, le vieil horloger qui graisse le mécanisme et une petite fille qui compte les tics ; la nuit, le
## veilleur qui dort sur sa chaise.
static func _horloge(M) -> void:
	var R = M.R
	var k = R.kit
	var nuit: bool = L._nuit(M)
	var room0 = M.room
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var lt: StandardMaterial3D = L._laiton(M)
	var fer: StandardMaterial3D = L._fer(M)
	var cri: StandardMaterial3D = _cristal(M)
	var rng: RandomNumberGenerator = L._r(M)
	var zf: float = -1.6
	# le bâti de fer, au fond : quatre montants, les traverses (le mécanisme est dedans)
	for e in [[-1.0, -1.95], [1.0, -1.95], [-1.0, -1.25], [1.0, -1.25]]:
		k.box(R.L(float(e[0]), 1.4, float(e[1])), Vector3(0.1, 2.8, 0.1), "fer", 1.0)
	for e2 in [[2.8, -1.95], [2.8, -1.25], [0.25, -1.95], [0.25, -1.25]]:
		k.box(R.L(0, float(e2[0]), float(e2[1])), Vector3(2.1, 0.09, 0.09), "fer", 1.0)
	for sx in [-1.0, 1.0]:
		k.box(R.L(sx * 1.0, 2.8, zf), Vector3(0.09, 0.09, 0.8), "fer", 1.0)
	k.col_box(R.L(0, 1.4, zf), Vector3(2.2, 2.8, 0.85))
	R.reserve(0, zf, 2.4, 1.1)
	# les roues : chacune sa vitesse, chacune son cœur de cristal
	var grande: Node3D = L._roue(M, R.P(-0.35, 1.45, zf), Vector3.BACK, 0.62, 40, 0.05, lt)
	var moyenne: Node3D = L._roue(M, R.P(0.55, 1.62, zf - 0.02), Vector3.BACK, 0.3, 20, 0.05, fer)
	var petite: Node3D = L._roue(M, R.P(0.42, 2.2, zf + 0.02), Vector3.BACK, 0.2, 14, 0.04, lt)
	var esc: Node3D = L._roue(M, R.P(0.0, 2.45, zf + 0.05), Vector3.BACK, 0.17, 30, 0.03, lt)
	L._mesh(grande, L._tore(0.3, 0.34), cri, Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0, 0.03)))
	for g in [[grande, 0.11], [moyenne, 0.06], [petite, 0.045], [esc, 0.04]]:
		L._mesh(g[0] as Node3D, I._sph(float(g[1])), cri)
	L._tourne(M, grande, Vector3.BACK, 0.1, true)
	L._tourne(M, moyenne, Vector3.BACK, -0.2, true)
	L._tourne(M, petite, Vector3.BACK, 0.31, true)
	# l'ancre (une barre de fer, deux palettes de cristal) qui bascule au rythme du balancier
	var ancre: Node3D = I._node(M, R.P(0, 2.66, zf + 0.12))
	L._mesh(ancre, I._boxm(Vector3(0.42, 0.04, 0.025)), fer)
	for s2 in [-1.0, 1.0]:
		L._mesh(ancre, I._boxm(Vector3(0.035, 0.1, 0.03)), cri, Transform3D(Basis(Vector3.BACK, s2 * 0.3), Vector3(s2 * 0.18, -0.06, 0)))
	L._mesh(ancre, I._sph(0.03), lt)
	L._balance(M, ancre, Vector3.BACK, 0.1, 4.0)
	# le grand balancier (sa tige de laiton, sa lentille et son cristal) et sa suspension
	var bal: Node3D = I._node(M, R.P(0, 5.45, -0.95))
	L._mesh(bal, L._cylm(0.018, 0.018, 3.6, 8), lt, Transform3D(Basis(), Vector3(0, -1.8, 0)))
	L._mesh(bal, L._cylm(0.28, 0.28, 0.05, 32), lt, Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, -3.75, 0)))
	L._mesh(bal, L._tore(0.22, 0.25), cri, Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, -3.75, 0.03)))
	L._mesh(bal, I._sph(0.09), cri, Transform3D(Basis(), Vector3(0, -3.75, 0)))
	L._balance(M, bal, Vector3.BACK, 0.085, 4.0, 0.0)
	k.box(R.L(0, 5.5, -0.95), Vector3(1.2, 0.12, 0.14), "fer", 1.0)
	for s3 in [-1.0, 1.0]:
		k.box(R.L(s3 * 0.55, 5.5, -1.72), Vector3(0.08, 0.08, 1.56), "fer", 1.0)
	k.col_box(R.L(0, 1.65, -0.95), Vector3(1.0, 0.7, 0.25))
	R.reserve(0, -0.95, 1.2, 0.5)
	L._lampe(M, R.P(0, 1.75, -0.6), Color(0.6, 0.8, 1.0), 0.35, 2.0)
	# les deux poids, qui descendent tout doucement sur leurs câbles (les poulies en haut)
	var pys: Array = [rng.randf_range(2.4, 4.8), rng.randf_range(1.6, 4.0)]
	var poids: Array = []
	var cables: Array = []
	var zw: float = -2.1
	for i in range(2):
		var x: float = -1.6 if i == 0 else 1.6
		var pl: Node3D = I._node(M, R.P(x, 6.6, zw))
		L._mesh(pl, L._cylm(0.12, 0.12, 0.04, 16), lt, Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3.ZERO))
		L._mesh(pl, I._sph(0.03), cri)
		k.box(R.L(x, 6.75, zw - 0.2), Vector3(0.06, 0.3, 0.4), "fer", 1.0)
		L._tourne(M, pl, Vector3.RIGHT, -0.05, true)
		var cab: Node3D = I._node(M, R.P(x, 6.6, zw + 0.12))
		L._mesh(cab, L._cylm(0.008, 0.008, 1.0, 6), fer, Transform3D(Basis(), Vector3(0, -0.5, 0)))
		cables.append(cab)
		var w: Node3D = I._node(M, R.P(x, float(pys[i]), zw + 0.12))
		L._mesh(w, L._tore(0.02, 0.03), fer, Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, -0.02, 0)))
		L._mesh(w, L._cylm(0.06, 0.14, 0.06, 16), lt, Transform3D(Basis(), Vector3(0, -0.07, 0)))
		L._mesh(w, L._cylm(0.14, 0.14, 0.62, 16), lt, Transform3D(Basis(), Vector3(0, -0.4, 0)))
		L._mesh(w, L._cylm(0.147, 0.147, 0.06, 16), cri, Transform3D(Basis(), Vector3(0, -0.4, 0)))
		L._mesh(w, L._cylm(0.14, 0.1, 0.04, 16), lt, Transform3D(Basis(), Vector3(0, -0.73, 0)))
		poids.append(w)
	L._chaque(M, func(delta: float, _t: float) -> void:
		for j in range(2):
			var wj: Node3D = poids[j]
			var cj: Node3D = cables[j]
			if not is_instance_valid(wj) or not is_instance_valid(cj):
				continue
			pys[j] = maxf(0.8, float(pys[j]) - delta * 0.004 * float(M.ctx.get("vite116", 1.0)))
			var p: Vector3 = wj.global_position
			wj.global_position = Vector3(p.x, R.P(0, float(pys[j]), 0).y, p.z)
			cj.scale = Vector3(1.0, maxf(0.05, 6.6 - float(pys[j])), 1.0))
	# la manivelle (sur le côté droit du bâti), pour remonter les poids
	var mv: Node3D = I._node(M, R.P(1.08, 1.15, zf), 90.0)
	L._mesh(mv, L._cylm(0.05, 0.05, 0.08, 12), fer, Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO))
	L._mesh(mv, I._boxm(Vector3(0.04, 0.28, 0.03)), lt, Transform3D(Basis(), Vector3(0, 0.14, 0.05)))
	L._mesh(mv, L._cylm(0.02, 0.02, 0.14, 8), L._m(M, "poignee118", Color(0.45, 0.3, 0.18), 0.7), Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0.27, 0.12)))
	# les deux cadrans, vus de dos, tout en haut : du verre dépoli qui laisse passer la lumière du Soleil
	# de Laiton ; les aiguilles tournent à l'heure du jeu
	var verre: StandardMaterial3D = L._m(M, "cadran118", Color(1.0, 0.93, 0.78, 0.92), 0.5, 0.0, 0.45 if nuit else 1.2)
	var aig: Array = []
	for spec in [[Vector3(0, 5.9, -hd + 0.06), Basis()], [Vector3(-hw + 0.06, 5.9, 0), Basis(Vector3.UP, PI * 0.5)]]:
		var lp: Vector3 = spec[0]
		var at: Vector3 = R.P(lp.x, lp.y, lp.z)
		var b: Basis = spec[1]
		var holder := Node3D.new()
		M.room.add_child(holder)
		holder.global_transform = Transform3D(b, at)
		L._mesh(holder, L._cylm(0.95, 0.95, 0.03, 40), verre, Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO))
		k.ring(Transform3D(b * Basis(Vector3.RIGHT, PI * 0.5), at + b * Vector3(0, 0, 0.02)), 0.95, 1.06, 0.06, "or", 40)
		for hr in range(12):
			var mb := Basis(Vector3.BACK, TAU * hr / 12.0)
			k.box(Transform3D(b * mb, at + b * (Vector3(0, 0, 0.03) + mb * Vector3(0, 0.8, 0))), Vector3(0.05, 0.16 if hr % 3 == 0 else 0.09, 0.01), "noir", 1.0)
			if hr % 3 == 0:
				L._mesh(holder, I._sph(0.035), cri, Transform3D(Basis(), Vector3(0, 0, 0.04) + mb * Vector3(0, 0.62, 0)))
		var piv := Node3D.new()
		holder.add_child(piv)
		piv.position = Vector3(0, 0, 0.05)
		L._mesh(piv, I._boxm(Vector3(0.07, 0.55, 0.02)), fer, Transform3D(Basis(), Vector3(0, 0.23, 0)))
		var piv2 := Node3D.new()
		holder.add_child(piv2)
		piv2.position = Vector3(0, 0, 0.07)
		L._mesh(piv2, I._boxm(Vector3(0.045, 0.8, 0.02)), fer, Transform3D(Basis(), Vector3(0, 0.36, 0)))
		L._mesh(holder, L._cylm(0.06, 0.06, 0.06, 12), lt, Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0, 0.09)))
		aig.append([piv, piv2])
		R.mark_wall(lp.x, lp.y, lp.z, 1.1)
		L._lampe(M, at + b * Vector3(0, 0, 0.7), Color(1.0, 0.85, 0.6), 0.5 if nuit else 1.3, 4.5)
	L._chaque(M, func(_delta: float, _t: float) -> void:
		var hh: float = float(M.main.temps_v56.hour) if M.main.get("temps_v56") != null else float(M.ctx.get("hour", 12.0))
		var a_m: float = fmod(hh, 1.0) * TAU
		var a_h: float = fmod(hh, 12.0) / 12.0 * TAU
		for p2 in aig:
			if is_instance_valid(p2[0]) and is_instance_valid(p2[1]):
				(p2[0] as Node3D).transform.basis = Basis(Vector3.BACK, a_h)
				(p2[1] as Node3D).transform.basis = Basis(Vector3.BACK, a_m))
	# les arbres de transmission : du bâti à la boîte de renvoi, puis aux deux cadrans
	_horloge_tige(M, R.P(0, 2.85, zf), R.P(0, 5.9, zf), 0.025, fer)
	k.box(R.L(0, 5.9, zf), Vector3(0.26, 0.26, 0.26), "fer", 1.0)
	_horloge_tige(M, R.P(0, 5.9, zf), R.P(0, 5.9, -hd + 0.1), 0.025, fer)
	_horloge_tige(M, R.P(0, 5.9, zf), R.P(-hw + 0.1, 5.9, 0), 0.025, fer)
	# le tic-tac : la roue d'échappement avance d'une dent toutes les deux secondes
	var tk: Dictionary = {"a": 1.0}
	M.ctx["tic118"] = -18.0
	L._chaque(M, func(delta: float, _t: float) -> void:
		tk["a"] = float(tk["a"]) + delta
		if float(tk["a"]) < 2.0:
			return
		tk["a"] = float(tk["a"]) - 2.0
		if is_instance_valid(esc):
			esc.rotate_object_local(Vector3.BACK, -TAU / 30.0)
		M.main.sfx("rouage", R.P(0, 2.5, zf + 0.2), float(M.ctx.get("tic118", -18.0))))
	# l'échelle de fer (mur de droite) et la petite plateforme, tout là-haut
	for sz in [-1.0, 1.0]:
		k.box(R.L(hw - 0.12, 2.6, 0.65 + sz * 0.22), Vector3(0.05, 5.2, 0.05), "fer", 1.0)
	for r9 in range(17):
		k.box(R.L(hw - 0.12, 0.3 + r9 * 0.3, 0.65), Vector3(0.04, 0.03, 0.44), "fer", 1.0)
	k.col_box(R.L(hw - 0.12, 2.6, 0.65), Vector3(0.2, 5.2, 0.5))
	k.box(R.L(2.05, 4.2, -0.45), Vector3(0.9, 0.08, 1.7), "bois_sombre", 1.0)
	for pz in [-1.25, 0.35]:
		k.box(R.L(1.64, 2.1, pz), Vector3(0.07, 4.2, 0.07), "fer", 1.0)
		k.col_box(R.L(1.64, 2.1, pz), Vector3(0.1, 4.2, 0.1))
	for pz2 in [-1.25, -0.45, 0.35]:
		k.box(R.L(1.64, 4.7, pz2), Vector3(0.04, 0.9, 0.04), "fer", 1.0)
	k.box(R.L(1.64, 5.15, -0.45), Vector3(0.04, 0.04, 1.64), "fer", 1.0)
	k.box(R.L(2.07, 5.15, -1.27), Vector3(0.86, 0.04, 0.04), "fer", 1.0)
	_lanterne(M, R.P(2.2, 4.24, -1.0), false, true)
	k.cyl(R.L(2.25, 4.24, -0.1), 0.06, 0.08, 0.12, "cuivre", 10)
	# l'établi de l'horloger (mur de gauche) : la loupe sur son bras, les huiliers, les petites roues
	var eb: Transform3D = _etabli_mine(M, -2.05, -1.35, 90.0, 1.2)
	var lb: Vector3 = eb * Vector3(-0.35, 0.92, -0.2)
	k.cyl(Transform3D(Basis(), lb), 0.06, 0.07, 0.03, "fer", 10)
	var lens: Vector3 = lb + Vector3(0.25, 0.4, 0.0)
	_horloge_tige(M, lb, lens, 0.01, lt)
	var loupe: Node3D = I._node(M, lens, 90.0)
	L._mesh(loupe, L._tore(0.07, 0.085), lt, Transform3D(Basis(Vector3.RIGHT, 0.9), Vector3.ZERO))
	L._mesh(loupe, L._cylm(0.072, 0.072, 0.004, 18), L._m(M, "loupe118", Color(0.85, 0.95, 1.0, 0.3), 0.05), Transform3D(Basis(Vector3.RIGHT, 0.9), Vector3.ZERO))
	for h3 in range(3):
		var hp: Vector3 = eb * Vector3(0.1 + h3 * 0.15, 0.92, 0.15)
		var hu: Node3D = I._node(M, hp)
		L._mesh(hu, L._cylm(0.035, 0.05, 0.07, 12), lt if h3 % 2 == 0 else L._m(M, "huilier118", Color(0.7, 0.4, 0.22), 0.4, 0.6), Transform3D(Basis(), Vector3(0, 0.035, 0)))
		L._mesh(hu, L._cylm(0.004, 0.009, 0.14, 6), lt, Transform3D(Basis(Vector3.BACK, 0.9), Vector3(0.05, 0.1, 0)))
	for g4 in range(7):
		var gp: Vector3 = eb * Vector3(-0.1 + rng.randf_range(-0.25, 0.25), 0.925, rng.randf_range(-0.3, 0.0))
		var gr: float = rng.randf_range(0.012, 0.04)
		k.cyl(Transform3D(Basis(), gp), gr, gr, 0.01, ["or", "cuivre", "argent"][g4 % 3], 10)
	k.box(Transform3D(eb.basis, eb * Vector3(0.45, 0.93, -0.2)), Vector3(0.1, 0.02, 0.08), "tissu_rouge", 1.0)
	L._mesh(M.room, I._sph(0.025), cri, Transform3D(Basis(), eb * Vector3(0.45, 0.965, -0.2)))
	L._lampe(M, eb * Vector3(0, 1.4, 0.2), Color(1.0, 0.88, 0.65), 0.6, 3.0)
	R.tabouret(-1.45, -1.35)
	# la plaque de la Grande Horloge (mur de gauche, près de l'entrée)
	var pq: Transform3D = R.L(-hw + 0.03, 1.5, 0.9, 90)
	k.box(pq, Vector3(0.5, 0.32, 0.02), "or", 1.0)
	for l5 in range(5):
		k.box(pq * Transform3D(Basis(), Vector3(0, 0.1 - l5 * 0.05, 0.012)), Vector3(0.38 - (l5 % 2) * 0.08, 0.012, 0.004), "noir", 1.0)
	R.mark_wall(-hw, 1.5, 0.9, 0.3)
	# la lumière d'en bas, la poussière qui danse dans la lumière des cadrans
	L._lampe(M, R.P(0, 2.6, 0.3), Color(1.0, 0.9, 0.72), 0.6 if nuit else 1.0, 6.0)
	L._poussiere(M, R.P(0, 3.5, -0.5), Vector3(2.0, 2.5, 1.8), 40, Color(1.0, 0.92, 0.75, 0.35), 0.02)
	# les gens
	if nuit:
		R.chaise(-1.25, 0.4, 135.0)
		var veil: Node = L._gens(M, "vieux", -1.25, 0.4, 135.0, "dormir_assis", ["Zzz… tic… Zzz… tac…", "Zzz… Je ne dors pas… je compte les tics les yeux fermés… Zzz…"])
		L._causer(M, veil, ["Hein ? Quoi ? Il est quelle heure ? … Ah, oui, c'est vrai : je suis dans l'horloge. Bonsoir !", "Zzz… Oh ! Bonsoir. Je veille. Si, si. D'un œil. L'autre se repose."],
			[["veille", "Que surveilles-tu ?", ["Que l'horloge ne s'arrête pas ! Elle ne s'est jamais arrêtée. Mais si elle s'arrêtait, toutes les Strates seraient en retard demain, et ce serait ma faute. Alors je veille. Et le tic-tac me berce. C'est un métier difficile."]],
			["heure", "Il est quelle heure ?", ["Regarde les cadrans, là-haut ! Ah, c'est vrai, on les voit de dos : il faut lire à l'envers. Moi, je ne lis plus l'heure. Je l'écoute. Tic, c'est maintenant. Tac, c'est un peu plus tard."]]])
		M.ctx["entree"] = "La Grande Horloge, la nuit : les cadrans luisent tout bas, couleur d'ambre, le balancier bat dans le silence, et le veilleur dort sur sa chaise, bercé par le tic-tac."
	else:
		var hor: Node = L._gens(M, "vieux", 0.75, -0.85, 200.0, "bricoler", ["Une goutte d'huile par roue, chaque matin. Pas deux : elles deviennent paresseuses.",
			"Le balancier bat les secondes depuis deux cents ans. Il n'a jamais demandé de vacances. Moi si."])
		L._causer(M, hor, ["Bon fond ! Bienvenue dans le ventre de la Grande Horloge. Parle doucement : elle compte.", "Ah, un visiteur ! Tu tombes bien, c'est l'heure de l'huile. C'est toujours l'heure de quelque chose, ici."],
			[["marche", "Comment marche-t-elle ?", ["Les poids descendent tout doucement sur leurs câbles et font tourner les roues. L'échappement, là-haut, les retient : une dent toutes les deux secondes. Tic… tac. Sans lui, la journée passerait en une minute, et Honorine n'aurait pas le temps de faire la soupe."]],
			["cristal", "Pourquoi tout ce cristal ?", ["Les cristaux des Mines ne s'usent jamais. Alors on en a mis là où ça frotte : dans l'ancre, dans les moyeux, et dans la lentille du balancier, pour faire joli. Ludovic les a choisis lui-même. Avec son casque."]],
			["heure", "Elle est à l'heure ?", ["Elle est à l'heure d'en bas ! Celle de Hautefond, à une seconde près. Gaspard, l'horloger d'en haut, m'envoie un mot par la cabine chaque lundi : « Toujours d'accord ? » Je réponds : « Toujours. » On s'écrit ça depuis trente ans."]]])
		var fil: Node = L._gens(M, "fille", -0.75, 0.25, 175.0, "observer", ["Quatre cent douze… tic… quatre cent treize… Chut, je compte !", "Mon record, c'est mille tics. Après, j'ai eu faim."])
		L._causer(M, fil, ["Chut ! Je compte les tics. … Zut, j'ai perdu. Bonjour !", "Bonne descente ! Tu veux compter avec moi ? Moi les tics, toi les tacs."],
			[["combien", "Combien de tics par jour ?", ["Papy horloger dit quarante-trois mille deux cents. Moi, je n'arrive jamais au bout : il y a toujours le goûter au milieu."]]])
		M.ctx["entree"] = str(L._pick(M, ["Tu entres dans la Grande Horloge : tout en haut, deux cadrans de verre dépoli laissent passer la lumière du Soleil de Laiton, et le grand balancier va et vient, lentement, comme une respiration.",
			"Tic… tac… Dans la tour de la Place des Rouages, des roues de laiton grandes comme des tables tournent chacune à sa vitesse, et des poids descendent, si lentement qu'on ne les voit pas bouger.",
			"Ça sent l'huile fine et le laiton chaud. Au milieu des roues, un vieil horloger graisse le mécanisme, et une petite fille compte les tics à voix basse."]))
	# ce qu'on fait : remonter les poids, écouter le tic-tac, lire la plaque
	M.act(R.P(1.4, 1.0, -1.0), "E : remonter les poids", func() -> void:
		if bool(M.ctx.get("remonte118", false)):
			return
		M.ctx["remonte118"] = true
		M.main.sfx("levier", mv.global_position)
		M.ctx["vite116"] = 5.0
		var a0: float = float(pys[0])
		var a1: float = float(pys[1])
		var monte := func(v: float) -> void:
			pys[0] = lerpf(a0, 6.0, v)
			pys[1] = lerpf(a1, 6.0, v)
		var tw: Tween = M.room.create_tween()
		tw.set_parallel(true)
		tw.tween_method(monte, 0.0, 1.0, 3.5).set_trans(Tween.TRANS_SINE)
		tw.tween_property(mv, "rotation:z", mv.rotation.z - TAU * 4.0, 3.5)
		M.say(str(L._pick(M, ["Tu tournes la manivelle : crr, crr, crr. Les roues s'emballent, les câbles s'enroulent, et les deux gros poids de laiton remontent tout en haut, jusque sous les poulies.",
			"Quarante tours de manivelle ! Les poids remontent lentement, leurs bagues de cristal brillent en passant devant les cadrans. La Grande Horloge en a pour huit jours.",
			"Crr, crr… Les poids montent, les roues tournent à toute vitesse, puis tout reprend son pas tranquille. Tic… tac. Merci, dit l'horloge. Enfin, c'est ce qu'il semble."])), 6.0)
		await M.get_tree().create_timer(3.6).timeout
		if not _la(M, room0):
			return
		M.ctx["vite116"] = 1.0
		M.ctx["remonte118"] = false
		M.main.sfx("rouage", mv.global_position)
		var st: Dictionary = M.state()
		if not bool(st.get("poids118", false)):
			st["poids118"] = true
			if nuit:
				M.give([["galette_rouages", 1]], "Le veilleur ouvre un œil : « Merci… Tu as fait mon travail. » Et il te tend la galette de sa veillée, découpée en roue dentée.\n")
			else:
				M.give([["galette_rouages", 1]], "« Merci du coup de main ! dit l'horloger. Voilà de quoi reprendre des forces : une galette des Rouages, en forme de roue dentée, comme il se doit. »\n")
	, 1.2)
	M.act(R.P(-0.3, 1.2, -0.35), "E : écouter le tic-tac", func() -> void:
		M.ctx["tic118"] = -4.0
		M.main.sfx("mecanisme", R.P(0, 2.2, zf + 0.2), -4.0)
		M.say(str(L._pick(M, ["Tu fermes les yeux. Tic… tac… Le balancier passe devant toi, lentement, et chaque battement résonne dans toute la tour, jusque dans la pierre. On dirait le cœur de la caverne.",
			"Tic, la palette de cristal attrape une dent. Tac, elle la relâche. Deux secondes, toujours deux secondes. Depuis deux cents ans, la Grande Horloge n'a jamais perdu le fil.",
			"Tu comptes avec la petite fille : tic, un… tac, deux… À cinquante, tu t'aperçois que tu respires au même rythme que le balancier. C'est très reposant."])), 7.0)
		await M.get_tree().create_timer(8.0).timeout
		if _la(M, room0):
			M.ctx["tic118"] = -18.0
	, 1.2)
	M.act(R.P(-1.95, 1.2, 0.9), "E : lire la plaque", func() -> void:
		M.say(PLAQUE_HORLOGE, 9.0)
	, 1.1)


# =================================================================== la loge des Soupapes

const SETLIST_SOUPAPES := ["LA SETLIST DES SOUPAPES (au feutre, avec des taches de limonade). Un : « Boum-Tchak des Profondeurs ». Deux : « Ma Clé à Molette ». Trois : « La Soupe de Mémé Gamelle (deuxième service) ». Quatre : « Le Pont des Nouveaux Amis ». Rappel : « Plus Fort, Je N'Entends Pas ! »",
	"LA SETLIST DES SOUPAPES, version longue. Un : « Rail Numéro Sept ». Deux : « Le Gouffre Répond Trois Fois ». Trois : « Ça Rime Avec Chaudière ». Quatre : « La Crête de Brasero Tient Toute Seule ». Rappel : « Bonne Nuit, la Colonne ». Au crayon, en bas : « Rivet, PAS de solo de vingt minutes. »",
	"LA SETLIST DES SOUPAPES, spéciale gens d'en haut. Un : « Bienvenue en Bas ». Deux : « Le Soleil de Laiton Ne Se Couche Jamais ». Trois : « Le Monsieur au Chapeau ». Quatre : « Casque Obligatoire » (dédiée à Ludovic). Rappel : « Une Note Très Basse » (Écho, tout seul)."]
const VOCALISES_LOGE := ["♪ Laaa… laaa… LAAA ! ♪", "♪ Mi-mi-mi-mi… ♪", "♪ Boum-tchak, la-la ! ♪", "♪ Chau-diè-re… ri-vi-è-re ! ♪", "♪ Ouh-ouh-OUH ! ♪"]


## Une affiche (une image collée au mur) : xf = son centre ; elle regarde +Z.
static func _loge_affiche(M, xf: Transform3D, size: Vector2, tex: String) -> MeshInstance3D:
	if not M.ctx.has("mats116"):
		M.ctx["mats116"] = {}
	var cache: Dictionary = M.ctx["mats116"]
	var key: String = "affiche118_" + tex
	var m: StandardMaterial3D = cache.get(key, null)
	if m == null:
		m = StandardMaterial3D.new()
		var p: String = "res://assets/textures/" + tex
		if ResourceLoader.exists(p):
			m.albedo_texture = load(p)
		else:
			m.albedo_color = Color(0.8, 0.3, 0.2)
		m.roughness = 0.85
		cache[key] = m
	var qm := QuadMesh.new()
	qm.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = qm
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	M.room.add_child(mi)
	mi.global_transform = xf
	return mi


## Une bouteille de limonade du Gouffre (verre vert pâle, étiquette jaune, capsule rouge), posée à « at ».
static func _loge_bouteille(M, at: Vector3) -> void:
	var n: Node3D = I._node(M, at)
	L._mesh(n, L._cylm(0.03, 0.03, 0.16, 12), L._m(M, "limonade118", Color(0.55, 0.88, 0.7, 0.65), 0.1), Transform3D(Basis(), Vector3(0, 0.08, 0)))
	L._mesh(n, L._cylm(0.031, 0.031, 0.05, 12), L._m(M, "etiquette118", Color(0.95, 0.8, 0.2), 0.7), Transform3D(Basis(), Vector3(0, 0.08, 0)))
	L._mesh(n, L._cylm(0.012, 0.028, 0.06, 10), L._m(M, "limonade118", Color(0.55, 0.88, 0.7, 0.65), 0.1), Transform3D(Basis(), Vector3(0, 0.19, 0)))
	L._mesh(n, L._cylm(0.014, 0.014, 0.012, 10), L._m(M, "capsule118", Color(0.85, 0.15, 0.12), 0.4, 0.5), Transform3D(Basis(), Vector3(0, 0.226, 0)))


## Une guitare (ou une basse : un manche plus long) sur son pied, à « at », qui regarde « yaw » ; renvoie
## l'instrument (pour le faire bouger).
static func _loge_instrument(M, at: Vector3, yaw: float, corps: Color, basse: bool) -> Node3D:
	var pied: Node3D = I._node(M, at, yaw)
	var fer: StandardMaterial3D = L._fer(M)
	for s in [-1.0, 1.0]:
		L._mesh(pied, I._boxm(Vector3(0.025, 0.02, 0.36)), fer, Transform3D(Basis(Vector3.UP, s * 0.5), Vector3(s * 0.08, 0.01, -0.02)))
	L._mesh(pied, L._cylm(0.012, 0.012, 0.75, 6), fer, Transform3D(Basis(Vector3.RIGHT, -0.18), Vector3(0, 0.37, -0.1)))
	L._mesh(pied, I._boxm(Vector3(0.24, 0.025, 0.06)), fer, Transform3D(Basis(), Vector3(0, 0.22, 0.04)))
	var inst := Node3D.new()
	pied.add_child(inst)
	inst.position = Vector3(0, 0.22, 0.05)
	inst.rotation.x = -0.22
	var cm: StandardMaterial3D = L._m(M, "instrument118_%s" % corps.to_html(false), corps, 0.3, 0.2)
	L._mesh(inst, I._sph(0.17), cm, Transform3D(Basis.from_scale(Vector3(1.0, 1.0, 0.3)), Vector3(0, 0.17, 0)))
	L._mesh(inst, I._sph(0.13), cm, Transform3D(Basis.from_scale(Vector3(1.0, 1.0, 0.3)), Vector3(0, 0.38, 0)))
	L._mesh(inst, I._boxm(Vector3(0.12, 0.1, 0.005)), L._m(M, "plaque118", Color(0.08, 0.08, 0.09), 0.5), Transform3D(Basis(), Vector3(0.05, 0.2, 0.052)))
	var ln: float = 0.72 if basse else 0.55
	var manche: StandardMaterial3D = L._m(M, "manche118", Color(0.42, 0.26, 0.15), 0.6)
	L._mesh(inst, I._boxm(Vector3(0.05, ln, 0.025)), manche, Transform3D(Basis(), Vector3(0, 0.45 + ln * 0.5, 0.02)))
	L._mesh(inst, I._boxm(Vector3(0.08, 0.16, 0.02)), manche, Transform3D(Basis(Vector3.RIGHT, -0.2), Vector3(0, 0.53 + ln, 0.0)))
	L._mesh(inst, I._boxm(Vector3(0.03, ln + 0.35, 0.002)), L._m(M, "cordes118", Color(0.85, 0.86, 0.88), 0.25, 1.0), Transform3D(Basis(), Vector3(0, 0.3 + ln * 0.5, 0.054)))
	return inst


## La loge des Soupapes (l'ancienne chaudière derrière la Scène, où le groupe se prépare) : minuscule et
## pleine : le miroir à ampoules et sa coiffeuse (les limonades du Gouffre, la laque pour crêtes), les
## affiches, la guitare et la basse sur leurs pieds, la caisse claire et ses baguettes, le canapé défoncé,
## le portemanteau et ses vestes à clous, la setlist punaisée, le ventilateur qui tourne en grinçant ; le
## soir (de 19 h à 23 h), Bielle qui s'échauffe la voix et Écho qui accorde sa basse ; le jour, Rivet qui
## répare une baguette et un roadie qui range ; tard dans la nuit, Écho qui dort sur le canapé.
static func _loge(M) -> void:
	var R = M.R
	var k = R.kit
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var rng: RandomNumberGenerator = L._r(M)
	var h: float = float(M.ctx.get("hour", 12.0))
	var soir: bool = h >= 19.0 and h < 23.0
	var tard: bool = h >= 23.0 or h < 7.0
	# le miroir à ampoules (mur du fond, à gauche), sa coiffeuse et ce qu'il y a dessus
	var mx: float = -0.6
	var mp: Transform3D = R.L(mx, 1.45, -hd + 0.03)
	k.box(mp, Vector3(0.78, 0.92, 0.03), "noir", 1.0)
	k.box(mp * Transform3D(Basis(), Vector3(0, 0, 0.02)), Vector3(0.6, 0.74, 0.01), "argent", 1.0)
	var pts: Array = []
	for i in range(5):
		pts.append(Vector2(-0.3 + i * 0.15, 0.42))
	for sx in [-1.0, 1.0]:
		for j in range(4):
			pts.append(Vector2(sx * 0.36, 0.27 - j * 0.18))
	var ampoules: Array = []
	var bm: Material = R.mat("lumiere")
	for q in range(pts.size()):
		var pp: Vector2 = pts[q]
		var bn: Node3D = I._node(M, mp * Vector3(pp.x, pp.y, 0.04))
		L._mesh(bn, I._sph(0.03), bm)
		if tard and q % 2 == 0:
			bn.visible = false
		ampoules.append(bn)
	R.mark_wall(mx, 1.45, -hd, 0.5)
	L._lampe(M, mp * Vector3(0, 0, 0.5), Color(1.0, 0.88, 0.65), 0.4 if tard else 0.8, 3.0)
	L._souvent(M, 3.0, 7.0, func() -> void:
		var b: Node3D = ampoules[rng.randi() % ampoules.size()]
		if not is_instance_valid(b) or not b.visible:
			return
		var tw: Tween = M.room.create_tween()
		tw.tween_callback(func() -> void: b.visible = false)
		tw.tween_interval(0.12)
		tw.tween_callback(func() -> void: b.visible = true)
		tw.tween_interval(0.08)
		tw.tween_callback(func() -> void: b.visible = false)
		tw.tween_interval(0.1)
		tw.tween_callback(func() -> void: b.visible = true))
	k.box(R.L(mx, 0.78, -hd + 0.2), Vector3(0.95, 0.04, 0.38), "bois", 1.0)
	for s2 in [-1.0, 1.0]:
		k.box(R.L(mx + s2 * 0.44, 0.39, -hd + 0.2), Vector3(0.04, 0.78, 0.34), "bois_sombre", 1.0)
	k.col_box(R.L(mx, 0.4, -hd + 0.2), Vector3(0.95, 0.8, 0.38))
	R.reserve(mx, -hd + 0.2, 1.0, 0.5)
	for b2 in range(3):
		_loge_bouteille(M, R.P(mx - 0.32 + b2 * 0.09, 0.8, -hd + 0.25 + (b2 % 2) * 0.05))
	for c3 in range(2):
		k.cyl(R.L(mx + 0.12 + c3 * 0.1, 0.8, -hd + 0.22), 0.03, 0.03, 0.2, ["tissu_rose", "tissu_turquoise"][c3], 10)
		k.cyl(R.L(mx + 0.12 + c3 * 0.1, 1.0, -hd + 0.22), 0.012, 0.012, 0.02, "noir", 8)
	k.cyl(R.L(mx + 0.33, 0.8, -hd + 0.25), 0.045, 0.04, 0.12, "metal", 10)
	for d4 in range(4):
		k.cyl(Transform3D(Basis(Vector3.BACK, -0.15 + d4 * 0.1), R.P(mx + 0.33 + (d4 - 1.5) * 0.012, 0.82, -hd + 0.25)), 0.007, 0.01, 0.4, "bois_clair", 6)
	# les affiches (mur du fond, mur de gauche, mur de devant, mur de droite)
	_loge_affiche(M, R.L(0.85, 1.6, -hd + 0.025), Vector2(0.5, 0.7), "strates/affiche_soupapes_1.png")
	R.mark_wall(0.85, 1.6, -hd, 0.3)
	_loge_affiche(M, R.L(-hw + 0.025, 1.65, -1.4, 90), Vector2(0.45, 0.62), "strates/affiche_soupapes_2.png")
	R.mark_wall(-hw, 1.65, -1.4, 0.25)
	_loge_affiche(M, R.L(-1.1, 1.6, hd - 0.025, 180), Vector2(0.45, 0.62), "strates/affiche_soupapes_3.png")
	R.mark_wall(-1.1, 1.6, hd, 0.25)
	_loge_affiche(M, R.L(hw - 0.025, 1.75, -1.3, -90), Vector2(0.4, 0.55), "boucan/affiche_concert_1.png")
	R.mark_wall(hw, 1.75, -1.3, 0.22)
	# la setlist, punaisée au mur de gauche, au-dessus du canapé
	var sl: Transform3D = R.L(-hw + 0.02, 1.45, -0.72, 90) * Transform3D(Basis(Vector3.BACK, 0.05), Vector3.ZERO)
	k.box(sl, Vector3(0.26, 0.36, 0.005), "papier", 1.0)
	for l6 in range(6):
		k.box(sl * Transform3D(Basis(), Vector3(-0.02, 0.12 - l6 * 0.05, 0.004)), Vector3(0.18 - (l6 % 3) * 0.03, 0.012, 0.002), "noir", 1.0)
	L._mesh(M.room, I._sph(0.015), L._m(M, "punaise118", Color(0.85, 0.15, 0.12), 0.4), sl * Transform3D(Basis(), Vector3(0, 0.16, 0.01)))
	R.mark_wall(-hw, 1.45, -0.72, 0.2)
	# le canapé défoncé (contre le mur de gauche) et la caisse aux limonades, devant
	R.canape(-1.15, -0.35, 90.0, "rouge", 1.4)
	R.caisse(-0.3, 0.15, 0.4)
	for b5 in range(2):
		_loge_bouteille(M, R.P(-0.38 + b5 * 0.13, 0.4, 0.12 + b5 * 0.05))
	k.cyl(Transform3D(Basis(Vector3.UP, 0.4) * Basis(Vector3.BACK, PI * 0.5), R.P(-0.25, 0.41, 0.25)), 0.007, 0.01, 0.4, "bois_clair", 6)
	# la caisse claire sur son pied, ses baguettes croisées dessus
	var sp: Vector3 = R.P(0.2, 0, -1.55)
	for j2 in range(3):
		var aj: float = TAU * j2 / 3.0
		_horloge_tige(M, sp + Vector3(cos(aj), 0, sin(aj)) * 0.2, sp + Vector3(0, 0.48, 0), 0.01, L._fer(M))
	var dr: Node3D = I._node(M, sp + Vector3(0, 0.48, 0))
	L._mesh(dr, L._cylm(0.18, 0.18, 0.13, 24), L._m(M, "caisse118", Color(0.75, 0.12, 0.12), 0.35, 0.3), Transform3D(Basis(), Vector3(0, 0.065, 0)))
	L._mesh(dr, L._cylm(0.182, 0.182, 0.006, 24), L._m(M, "peau118", Color(0.95, 0.93, 0.88), 0.6), Transform3D(Basis(), Vector3(0, 0.133, 0)))
	for yr in [0.0, 0.13]:
		L._mesh(dr, L._tore(0.175, 0.19), R.mat("argent"), Transform3D(Basis(), Vector3(0, yr, 0)))
	for lg in range(8):
		var al: float = TAU * lg / 8.0
		L._mesh(dr, I._boxm(Vector3(0.015, 0.08, 0.015)), R.mat("argent"), Transform3D(Basis(), Vector3(cos(al) * 0.185, 0.065, sin(al) * 0.185)))
	for s6 in [-1.0, 1.0]:
		L._mesh(dr, L._cylm(0.007, 0.01, 0.4, 6), L._m(M, "baguette118", Color(0.85, 0.7, 0.45), 0.6), Transform3D(Basis(Vector3.UP, s6 * 0.35) * Basis(Vector3.BACK, PI * 0.5), Vector3(0, 0.15, s6 * 0.02)))
	k.col_box(R.L(0.2, 0.3, -1.55), Vector3(0.4, 0.65, 0.4))
	R.reserve(0.2, -1.55, 0.5, 0.5)
	var paf: Label3D = L._etiquette(M, sp + Vector3(0, 1.1, 0), "Ba-dam-tsss !")
	# la guitare et la basse sur leurs pieds (contre le mur de droite) ; le soir, Écho a pris sa basse
	var guitare: Node3D = _loge_instrument(M, R.P(1.25, 0, -1.6), -90.0, Color(0.15, 0.55, 0.35), false)
	var basse: Node3D = _loge_instrument(M, R.P(1.25, 0, -0.95), -90.0, Color(0.2, 0.3, 0.7), true)
	if soir:
		basse.visible = false
	k.col_box(R.L(1.25, 0.6, -1.28), Vector3(0.4, 1.2, 1.0))
	R.reserve(1.25, -1.28, 0.6, 1.2)
	# le portemanteau et ses vestes à clous
	var pm: Vector3 = R.P(1.2, 0, 0.3)
	k.cyl(Transform3D(Basis(), pm), 0.025, 0.025, 1.75, "fer", 8, false)
	for f7 in range(3):
		var af: float = TAU * f7 / 3.0
		k.box(Transform3D(Basis(Vector3.UP, -af), pm + Vector3(cos(af), 0, sin(af)) * 0.14 + Vector3.UP * 0.02), Vector3(0.28, 0.03, 0.04), "fer", 1.0)
	var clou: Material = R.mat("argent")
	for v8 in range(2):
		var vy: float = 1.22 if v8 == 0 else 1.15
		var vx: Transform3D = Transform3D(Basis(Vector3.UP, deg_to_rad(-60.0 + v8 * 150.0)), pm + Vector3(0, vy, 0)) * Transform3D(Basis(), Vector3(0, 0, 0.1))
		k.box(vx, Vector3(0.42, 0.66, 0.1), "cuir" if v8 == 0 else "tissu_noir", 1.0)
		k.box(vx * Transform3D(Basis(), Vector3(0, 0.32, 0.02)), Vector3(0.3, 0.08, 0.12), "cuir" if v8 == 0 else "tissu_noir", 1.0)
		for c9 in range(8):
			L._mesh(M.room, I._sph(0.012), clou, vx * Transform3D(Basis(), Vector3(-0.16 + (c9 % 4) * 0.1, 0.24 - floori(c9 / 4.0) * 0.08, 0.055)))
	k.col_box(R.L(1.2, 0.9, 0.3), Vector3(0.5, 1.8, 0.5))
	R.reserve(1.2, 0.3, 0.6, 0.6)
	# le ventilateur, dans le coin du plafond : il tourne (et il grince, paraît-il)
	k.box(R.L(1.5, 2.05, -1.9), Vector3(0.12, 0.12, 0.12), "fer", 1.0)
	var fan: Node3D = I._node(M, R.P(1.4, 2.05, -1.8), -45.0)
	L._mesh(fan, L._cylm(0.06, 0.07, 0.12, 12), L._fer(M), Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0, -0.02)))
	L._mesh(fan, L._tore(0.19, 0.205), L._fer(M), Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0, 0.07)))
	var pales := Node3D.new()
	fan.add_child(pales)
	pales.position = Vector3(0, 0, 0.07)
	for p9 in range(3):
		L._mesh(pales, I._boxm(Vector3(0.06, 0.17, 0.008)), L._m(M, "pale118", Color(0.85, 0.3, 0.25), 0.5), Transform3D(Basis(Vector3.BACK, TAU * p9 / 3.0), Basis(Vector3.BACK, TAU * p9 / 3.0) * Vector3(0, 0.09, 0)))
	L._tourne(M, pales, Vector3.BACK, 3.0 if tard else 9.0)
	# les gens
	if soir:
		var bielle: Node = M.person("femme", mx, -1.15, 180.0, "chanter", "Bielle")
		bielle.lines = ["Mi-mi-mi-mi… Laaa… Bon, ma voix est réveillée. Mes genoux, pas encore.", "Ce soir, nouvelle chanson ! Elle parle d'un rail qui voulait devenir guitare. Je ne te dis pas la fin."]
		L._causer(M, bielle, ["Salut, camarade ! Tu tombes en plein échauffement. Mi-mi-mi… Voilà, je suis à toi.", "Oh, de la visite dans la loge ! Assieds-toi sur le canapé, mais attention au ressort de gauche : il est plus punk que nous."],
			[["chanson", "Tu chantes quoi, ce soir ?", ["La setlist est punaisée au mur, là. Mais on change toujours au dernier moment. Si la fosse crie « encore », on rejoue. Si elle crie « la soupe ! », on joue la chanson de Mémé Gamelle. Elle crie souvent « la soupe ! »."]],
			["ysae", "Ysaé viendra ?", ["Ma fille ? Elle descend de Hautefond pour le dernier morceau, presque tous les soirs. Elle se met au fond de la fosse et elle chante plus fort que moi. Je fais semblant de ne pas l'entendre. Je l'entends très bien."]],
			["trac", "Tu as le trac ?", ["Un peu, chaque soir. Le trac, c'est comme la vapeur : si on le garde dedans, ça siffle. Alors on l'envoie dans la chanson. Et ça fait un très bon refrain."]]])
		var echo: Node = M.person("homme", 0.65, -0.45, -120.0, "basse_bo", "Écho")
		echo.lines = ["… Le mi grave. (Il tourne une clé.) Voilà. La roche est d'accord.", "Chut. (Il pince une corde, tend l'oreille.) … Encore un quart de ton."]
		L._causer(M, echo, ["… Bonsoir. (Il pince une corde.) Tu entends ? Elle est juste, maintenant.", "Chut. J'accorde. … Voilà. Bonjour."],
			[["accorder", "Comment accordes-tu ta basse ?", ["Sur la rivière du Gouffre. Elle chante une seule note, depuis toujours. (Un temps.) Ce soir, elle est en sol. Alors nous aussi."]]])
		var vocal: Label3D = L._etiquette(M, R.P(mx, 2.1, -1.15), "♪")
		L._souvent(M, 3.0, 5.5, func() -> void:
			if not is_instance_valid(bielle) or not is_instance_valid(vocal):
				return
			vocal.text = str(L._pick(M, VOCALISES_LOGE))
			L._montrer(M, vocal, 1.8))
		M.ctx["entree"] = str(L._pick(M, ["La loge des Soupapes, juste avant le concert : le miroir à ampoules brille, Bielle fait ses vocalises, Écho accorde sa basse, et à travers la tôle, on entend la fosse qui se remplit.",
			"« Mi-mi-mi-mi… » Dans la chaudière derrière la Scène, ça sent la limonade et la laque pour crêtes. Le concert va commencer. Ou il vient de finir : ici, c'est toujours un peu les deux."]))
	elif tard:
		var dort: Node = M.person("homme", -1.05, -0.35, 90.0, "dormir_assis", "Écho")
		dort.lines = ["Zzz… (Il sourit en dormant.) … en sol… Zzz…", "Zzz… Le silence a une note… très basse… Zzz…"]
		L._causer(M, dort, ["… Mm ? (Il ouvre un œil.) Ah. C'est toi. La loge est le seul endroit vraiment silencieux, après le concert.", "Chut… (Il chuchote.) Le ventilateur ronronne en ré. C'est très reposant."],
			[["dormir", "Tu dors ici ?", ["Parfois. (Il bâille.) Après le concert, les oreilles bourdonnent encore. Ici, il n'y a que le ventilateur et la chaudière qui refroidit. Tic, tic. Ça m'endort. Rivet dit que je ronfle en mesure."]]])
		M.ctx["entree"] = "La loge, après le concert : la moitié des ampoules du miroir sont éteintes, le ventilateur tourne tout doucement, et Écho dort sur le canapé, sa basse posée à côté de lui."
	else:
		var rivet: Node = M.person("homme", -0.4, -1.3, 90.0, "bricoler", "Rivet")
		rivet.lines = ["Boum-tchak ! … Crac. Et voilà, encore une baguette cassée. La sixième de la semaine. Un peu de ruban, et elle repart !",
			"Une baguette, ça se répare comme un rail : on serre, on scotche, on tape dessus pour voir. Si ça sonne, c'est bon."]
		L._causer(M, rivet, ["Salut, camarade ! Bienvenue dans la loge ! C'est petit, mais c'est la chaudière la plus punk de la Fronde.", "BOUM-TCHAK ! Oh, salut ! Pardon, je teste ma baguette sur tout ce qui passe. Tape là !"],
			[["baguette", "Tu casses beaucoup de baguettes ?", ["Six par semaine. Sept quand Ysaé est dans la fosse : je tape plus fort pour qu'elle m'entende. Mémé Gamelle dit que je pourrais jouer avec des cuillères en bois. J'ai essayé. Ça fait « poc ». Le public a fait « poc » aussi."]],
			["loge", "C'est quoi, cette loge ?", ["L'ancienne chaudière de la Scène ! Bricole l'a vidée, on a mis un canapé, un miroir et le ventilateur le plus bruyant du monde. Avant le concert, on s'y prépare. Après, on s'y écroule. C'est une chaudière à musiciens."]],
			["concert", "À quelle heure est le concert ?", ["Tous les soirs, de vingt heures à vingt-trois heures ! Moi aux fûts, Bielle au micro, Écho à la basse, et l'orgue à vapeur de Bricole pour les refrains. Viens dans la fosse : ici, on se relève les uns les autres."]]])
		var roadie: Node = L._gens(M, "homme", 0.6, 0.0, 45.0, "bricoler", ["Un câble, deux câbles, trois câbles… Qui a fait un nœud avec le câble du micro ? Rivet ?!",
			"Je range la loge tous les jours. Tous les soirs, elle se dérange toute seule. C'est un mystère du punk."])
		L._causer(M, roadie, ["Salut, camarade ! Attention où tu marches : il y a des câbles partout. Enfin, moins qu'hier.", "Bonjour ! Je range. Ne touche à rien… Non, je plaisante. Touche à tout, c'est la Fronde."],
			[["roadie", "Qu'est-ce que tu fais ici ?", ["Je suis le roadie des Soupapes : je porte les amplis, je répare les câbles, je retrouve les médiators. Le soir, je pousse les boutons de l'orgue de Bricole. C'est moi le cinquième membre du groupe. Celui qu'on ne voit pas."]]])
		M.ctx["entree"] = str(L._pick(M, ["La loge des Soupapes : une ancienne chaudière, avec des hublots, un canapé défoncé, un miroir à ampoules et des affiches partout. Ça sent la limonade et la laque pour crêtes.",
			"Le ventilateur tourne en grinçant, une caisse claire attend dans un coin, et sur le mur, une setlist pleine de taches. Bienvenue dans les coulisses du punk à vapeur.",
			"C'est minuscule et plein à craquer : guitare, basse, baguettes, vestes à clous. Rivet dit que la loge est « intime ». Bielle dit qu'elle est « petite ». Les deux ont raison."]))
	# ce qu'on fait : lire la setlist, taper sur la caisse claire, essayer la guitare
	M.act(R.P(-0.55, 1.3, -0.72), "E : lire la setlist", func() -> void:
		M.main.sfx("ui_ouvrir", R.P(-hw + 0.1, 1.45, -0.72))
		var n: int = int(M.ctx.get("setlist118", rng.randi() % SETLIST_SOUPAPES.size()))
		M.ctx["setlist118"] = n + 1
		M.say(str(SETLIST_SOUPAPES[n % SETLIST_SOUPAPES.size()]), 9.0)
	, 1.0)
	M.act(R.P(0.2, 0.9, -1.1), "E : taper sur la caisse claire", func() -> void:
		M.main.sfx("batterie_roulement", dr.global_position)
		var tw: Tween = M.room.create_tween()
		tw.tween_property(dr, "scale", Vector3(1.08, 0.92, 1.08), 0.06)
		tw.tween_property(dr, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		L._montrer(M, paf, 1.6)
		for f in M.people:
			if is_instance_valid(f) and f.has_method("gesture"):
				f.gesture("rire", 1.5)
		M.say(str(L._pick(M, ["Ba-dam-tsss ! La caisse claire claque comme un rail qu'on resserre. Quelque part dans la Fronde, quelqu'un répond en tapant sur une casserole.",
			"Tu fais un roulement : brrrrrap ! Puis un coup sec. Le ventilateur, de saisissement, grince un peu plus fort. « Pas mal ! » dit-on derrière toi.",
			"Tchak ! Une seule frappe, bien nette. Ça résonne dans toute la chaudière. Rivet dirait : « Ça tient comme un rivet. »"])), 5.0)
	, 0.9)
	M.act(R.P(0.85, 1.0, -1.45), "E : essayer la guitare", func() -> void:
		M.main.sfx("guitare_riff", guitare.global_position)
		var tw: Tween = M.room.create_tween()
		tw.tween_property(guitare, "rotation:z", 0.12, 0.15)
		tw.tween_property(guitare, "rotation:z", -0.1, 0.2)
		tw.tween_property(guitare, "rotation:z", 0.0, 0.2)
		var st: Dictionary = M.state()
		if not bool(st.get("fanzine118", false)):
			st["fanzine118"] = true
			M.give([["fanzine", 1]], "Tu grattes trois accords. Ce n'est pas tout à fait juste, mais c'est très punk. « Bravo, camarade ! Tiens, le fanzine de la semaine : il y a une page entière sur les Soupapes ! »\n")
		else:
			M.say(str(L._pick(M, ["Tu grattes un accord : drang ! La guitare verte de Bielle ronronne comme une chaudière contente. Un jour, peut-être, une Soupape de plus ?",
				"Trois accords, un larsen imaginaire, et une pose de rock-star devant le miroir à ampoules. Personne n'a rien vu. Enfin, presque personne.",
				"Drang, drang ! Tu joues le début de « Boum-Tchak des Profondeurs ». Enfin, quelque chose qui y ressemble de loin. De très loin. Mais avec beaucoup de cœur."])), 6.0)
	, 0.9)
