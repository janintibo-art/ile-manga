extends RefCounted
## V119 : les grands lieux du Dôme d'Azur qu'on visite, comme les maisons (maisons_v81 : devant la porte,
## « E : entrer… », un fondu, et l'on est dedans). Chacun a son intérieur, ses gens, ce qui bouge et ce
## qu'on y fait :
##  - le PETIT PLONGEON (da_plongeon) : la cabine du bathyscaphe jaune de Lou Grenadier, au Bassin des
##    Bathyscaphes (ses hublots, son tableau de bord, la plongée dans la Faille) ;
##  - la SALLE DES MARÉES (da_marees) : à l'étage de la Maison du Conseil, la salle ronde où la Présidente
##    Ondine Nacre et le Conseil des Marées décident (la table en arc, l'horloge des marées, la maquette) ;
##  - le CABINET D'ÉCOUTE (da_benthos) : à l'Institut des Abysses, le bureau du Professeur Hippolyte Benthos
##    (l'hydrophone, les enregistrements de la Grande Chanteuse, les carnets) ;
##  - la SALLE DU CIEL (da_ciel) : à l'étage de l'École des Abysses, la classe de Madame Odile où l'on
##    apprend le ciel qu'on n'a jamais vu (le plafond peint, le planétaire, les cartes postales d'en haut) ;
##  - la SALLE DES SOUFFLERIES (da_souffleries) : au pied de la Cheminée d'Air, les grandes hélices, les
##    filtres et les compteurs qui font respirer le Dôme ;
##  - le POSTE DU CHEF DE GARE (da_gare) : le bureau de Marius Trident, à la Gare d'Azur (le pupitre du
##    Funiculaire, les lettres d'Anatole, la casquette) ;
##  - la RÉSERVE DU COMPTOIR (da_reserve) : l'arrière-boutique d'Ernest Coquillard au Comptoir des Courants
##    (les coquillages qui chantent, les caisses du troc avec la surface) ;
##  - la CHAMBRE DES SEMENCES (da_semences) : aux Serres, la chambre fraîche de Mélisande Varech (les
##    tiroirs de graines, les germoirs sous les lampes roses).
## Chaque lieu est une pièce de maisons_pieces_v81 (style « dome_lieu ») bâtie à part ; les aides communes
## sont celles de lieux_hautefond_v116 (L) et de maisons_iles_v82 (I). M est maisons_v81 ; R = M.R.

const Kit = preload("res://scripts/azur_kit_v56.gd")
const L = preload("res://scripts/lieux_hautefond_v116.gd")
const I = preload("res://scripts/maisons_iles_v82.gd")
const S = preload("res://scripts/maisons_scenes_v81.gd")

const STYLE := "dome_lieu"
## La taille de la pièce de chaque lieu (largeur, profondeur).
const TAILLES := {"da_plongeon": Vector2(4.2, 4.2), "da_marees": Vector2(12.0, 9.0), "da_benthos": Vector2(8.0, 6.5),
	"da_ciel": Vector2(10.0, 7.5), "da_souffleries": Vector2(10.0, 8.0), "da_gare": Vector2(6.0, 5.0),
	"da_reserve": Vector2(6.0, 5.0), "da_semences": Vector2(7.0, 5.5)}
## Ce qui s'affiche devant la porte.
const ENTRER := {"da_plongeon": "E : monter à bord du Petit Plongeon", "da_marees": "E : entrer dans la Salle des Marées",
	"da_benthos": "E : entrer dans le cabinet du Professeur Benthos", "da_ciel": "E : entrer dans la Salle du Ciel",
	"da_souffleries": "E : entrer dans la salle des Souffleries", "da_gare": "E : entrer dans le poste du chef de gare",
	"da_reserve": "E : entrer dans la réserve du Comptoir", "da_semences": "E : entrer dans la Chambre des Semences"}


static func is_lieu(style: String) -> bool:
	return style == STYLE


static func taille(cur: Dictionary) -> Vector2:
	return TAILLES.get(str(cur.get("histoire", "")), Vector2(8.0, 7.0))


static func has(sc: String) -> bool:
	return TAILLES.has(sc)


## Les portes des lieux : « lieu » -> [porte, dehors] (dome_azur_v115.portes119).
static func register(portes: Dictionary) -> int:
	var n: int = 0
	for lieu in TAILLES:
		var e: Variant = portes.get(lieu, null)
		if not (e is Array) or (e as Array).size() < 2:
			continue
		var out: Vector3 = e[1]
		out.y = 0.0
		if out.length() < 0.01:
			continue
		var tl: Vector2 = TAILLES[lieu]
		Kit.PORTES_V81.append({"door": e[0], "out": out.normalized(), "w": tl.x, "d": tl.y, "style": STYLE, "floors": 1, "owner": "",
			"histoire": str(lieu), "entrer": str(ENTRER[lieu])})
		n += 1
	return n


# =================================================================== la coque de la pièce

static func shell(M) -> void:
	var R = M.R
	R.pal = (R.pal as Dictionary).duplicate()
	match str(M.ctx.get("scenario", "")):
		"da_plongeon":
			R.H = 2.3
			L._mur(M, "mur", "astralys/metal_lumen.png", Color(0.95, 0.85, 0.45), 1.5)
			L._mur(M, "bas", "astralys/metal_lumen.png", Color(0.75, 0.72, 0.6), 1.5)
			L._mur(M, "plafond", "astralys/metal_lumen.png", Color(0.9, 0.82, 0.5), 1.5)
			L._mur(M, "sol", "astralys/metal_lumen.png", Color(0.55, 0.56, 0.6), 1.2)
			R.pal["fenetre"] = "aucune"
			R.shell()
		"da_marees":
			R.H = 4.4
			R.shell()
		"da_benthos":
			R.H = 3.2
			L._mur(M, "sol", "nuees/bois_blond.png", Color(0.95, 0.9, 0.85), 2.4)
			R.shell()
		"da_ciel":
			R.H = 3.6
			R.shell()
		"da_souffleries":
			R.H = 5.2
			L._mur(M, "mur", "astralys/metal_lumen.png", Color(0.85, 0.88, 0.92), 2.0)
			L._mur(M, "bas", "astralys/metal_lumen.png", Color(0.7, 0.74, 0.78), 2.0)
			R.pal["fenetre"] = "aucune"
			R.shell()
		"da_gare":
			R.H = 2.9
			R.shell()
		"da_reserve":
			R.H = 2.8
			L._mur(M, "sol", "nuees/bois_blond.png", Color(0.9, 0.84, 0.76), 2.2)
			R.shell()
		"da_semences":
			R.H = 2.8
			R.pal["fenetre"] = "aucune"
			R.shell()
		_:
			R.shell()


# =================================================================== les aides du Dôme

## Après une attente : sommes-nous toujours dans cette pièce-là ?
static func _la(M, room0) -> bool:
	return is_instance_valid(room0) and M.inside and M.room == room0


## La mer profonde vue à travers un hublot (un bleu qui luit doucement, plus sombre la nuit).
static func _mer(M) -> StandardMaterial3D:
	var nuit: bool = L._nuit(M)
	return L._m(M, "mer119_n" if nuit else "mer119", Color(0.02, 0.07, 0.14) if nuit else Color(0.05, 0.22, 0.34), 0.2, 0.0, 0.6)


## Un hublot rond dans un mur (xf : posé contre le mur, regardant vers la pièce) : un cerclage de titane,
## la mer derrière ; renvoie le nœud (on peut y ajouter des poissons qui passent).
static func _hublot(M, xf: Transform3D, r: float = 0.45) -> Node3D:
	var n: Node3D = I._node(M, xf.origin)
	n.global_transform = xf
	var disc := CylinderMesh.new()
	disc.top_radius = r
	disc.bottom_radius = r
	disc.height = 0.02
	disc.radial_segments = 24
	L._mesh(n, disc, _mer(M), Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0, -0.02)))
	L._mesh(n, L._tore(r - 0.02, r + 0.08), L._m(M, "titane119", Color(0.8, 0.83, 0.86), 0.3, 0.8), Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO))
	return n


## Un liseré de diodes aigue-marine (une fine barre qui luit), de a à b (repère de la pièce).
static func _diodes(M, a: Vector3, b: Vector3) -> void:
	var R = M.R
	var pa: Vector3 = R.P(a.x, a.y, a.z)
	var pb: Vector3 = R.P(b.x, b.y, b.z)
	var n: Node3D = I._node(M, (pa + pb) * 0.5)
	var len: float = pa.distance_to(pb)
	if len < 0.01:
		return
	n.look_at(pb, Vector3.UP if absf((pb - pa).normalized().y) < 0.95 else Vector3.RIGHT)
	L._mesh(n, I._boxm(Vector3(0.03, 0.03, len)), L._m(M, "diode119", Color(0.4, 1.0, 0.9), 0.3, 0.0, 2.0))


# =================================================================== construire

static func build(M, sc: String) -> void:
	match sc:
		"da_plongeon":
			_plongeon(M)
		"da_marees":
			_marees(M)
		"da_benthos":
			_benthos(M)
		"da_ciel":
			_ciel(M)
		"da_souffleries":
			_souffleries(M)
		"da_gare":
			_gare(M)
		"da_reserve":
			_reserve(M)
		"da_semences":
			_semences(M)


# =================================================================== V119 (lieux_c) : la réserve du Comptoir des
# Courants, la Chambre des Semences des Serres
# (_la(M, room0), _diodes(M, a, b) : celles du fichier principal, déjà présentes)

# =================================================================== la réserve du Comptoir des Courants

## Les hauteurs des planches des étagères à coquillages (au fond de la réserve).
const RESERVE_PLANCHES := [0.08, 0.58, 1.08, 1.58, 2.08]
const RESERVE_REGISTRE := ["LE GRAND REGISTRE DU COMPTOIR, page du lundi. Monté par le Funiculaire : six caisses de poisson des nasses, une boîte de sept perles d'Azur, douze bocaux de spiruline. Descendu : trois sacs de pommes, un carton de livres, et une plume « pour Mila, de la part d'un monsieur très gentil ».",
	"LE GRAND REGISTRE, page du mardi. Monté : du poisson, de la spiruline, et un coquillage qui chante, pour Rosalie Cannelle, au Grand Marché de Hautefond. Descendu : onze nouvelles de Rosalie. Elle tient à ce qu'on les compte comme des marchandises. Je les ai comptées.",
	"LE GRAND REGISTRE, page du mercredi. Descendu : une caisse de plumes pour l'École des Abysses. Madame Nautile veut montrer aux enfants à quoi ressemble un oiseau. Une plume, c'est un début. Mila en a déjà mis une dans ses cheveux.",
	"LE GRAND REGISTRE, page du jeudi. Monté : rien. Descendu : rien. Le Funiculaire était en révision. Nouvelles du jour : aucune. J'ai relu celles d'hier. Elles étaient encore très bonnes.",
	"LE GRAND REGISTRE, dans la marge, d'une toute petite écriture : « Demander à chaque voyageur de quelle couleur était le ciel, ce matin. Chaque jour, une réponse différente. Je les note toutes. Un jour, j'irai vérifier. Peut-être. »"]
## Les pesées : [l'inclinaison du fléau (vers le plateau de gauche si > 0), ce qu'on lit].
const RESERVE_PESEES := [[0.22, "Sur un plateau, une perle d'Azur. Sur l'autre, une plume d'en haut. La balance hésite longtemps… puis penche du côté de la perle. Le fond de la mer pèse plus lourd. Ce n'est pas une surprise."],
	[0.0, "Une pomme d'en haut contre trois bocaux de spiruline : ça tombe juste ! C'est écrit au-dessus de la balance : « Une pomme vaut trois spirulines. » Depuis toujours. Enfin, depuis la réouverture."],
	[-0.05, "Tu poses un coquillage qui chante sur le plateau. La balance bouge à peine, mais le coquillage fredonne un peu plus fort. Il n'aime pas beaucoup qu'on le pèse."],
	[-0.2, "Un livre d'en haut contre un poisson des nasses. Le poisson gagne. Le livre, vexé, reste ouvert à la page des baleines."],
	[0.0, "Rien sur un plateau, rien sur l'autre. La balance est parfaitement d'accord. C'est la pesée préférée du commis : elle ne se trompe jamais."]]
const RESERVE_COQUILLAGES := ["Tu approches le coquillage de ton oreille… Houuuu… Un chant très lointain, très grave, qui monte et redescend. La Grande Chanteuse ? Ou ton sang qui bouge, comme dit le Professeur Benthos. Tu préfères la Chanteuse.",
	"Dans celui-ci, on entend des vagues. De vraies vagues d'en haut, avec du vent dedans. Ernest dit qu'il les garde pour ceux qui n'ont jamais vu la mer de dessus.",
	"Ce petit coquillage rose chante un peu faux. On l'aime quand même : c'est le plus courageux de l'étagère. Il chante même quand personne n'écoute.",
	"Tu écoutes… et le coquillage se tait. Puis, tout bas, trois notes. Comme une baleine qui dirait bonjour avec la bouche fermée."]
const RESERVE_BERNARD := ["Un bernard-l'ermite sort la tête, regarde la coquille vide, hésite… et part l'essayer. Il entre dedans, se tourne, se retourne. Elle est à sa taille ! Il laisse l'ancienne à qui la voudra.",
	"Le bernard-l'ermite file vers la coquille vide, entre, ressort, rentre encore. Il la garde. Ernest a déjà une rubrique pour ça dans son Cahier : « Déménagements au Comptoir ».",
	"Les bernard-l'ermite font presque la queue devant la coquille vide. Le plus pressé déménage. Les autres regardent, l'air de dire : « La prochaine, c'est pour moi. »"]
const RESERVE_TRI := ["Tu tries la caisse : les pommes à gauche, les livres à droite, les plumes… un peu partout. Une plume s'envole et se pose sur ta tête. Elle a choisi.",
	"Dans la caisse d'en haut : un parapluie plié, un pot de miel, et une lettre adressée à « Quelqu'un, au fond de la mer ». On la range avec le courrier. Quelqu'un, ici, la lira.",
	"Tu ranges les livres d'en haut par taille, puis par couleur, puis par nombre de baleines dedans. Le dernier classement est de loin le plus utile."]


## La réserve du Comptoir des Courants : l'arrière-boutique d'Ernest Coquillard. Au fond, les étagères
## de coquillages (dont quelques-uns, nacrés, qui chantent et luisent tout doucement), les cordes et les
## bocaux de perles ; le pupitre et son grand registre ; la balance à plateaux sur sa table ronde ;
## l'aquarium des bernard-l'ermite (qui se promènent, et l'un d'eux change de coquille) ; les caisses du
## troc avec la surface (ce qui monte : poisson, perles, spiruline ; ce qui descend : pommes, livres,
## plumes). Ernest et deux visiteurs le jour ; son commis le soir et la nuit.
static func _reserve(M) -> void:
	var R = M.R
	var k = R.kit
	var nuit: bool = L._nuit(M)
	var soir: bool = nuit or float(M.ctx.get("hour", 12.0)) >= 18.0
	var room0 = M.room
	var rng: RandomNumberGenerator = L._r(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var o: Node3D = I._node(M, R.P(0, 0, 0))          # un repère : en local, les coordonnées de la pièce
	var nacres: Array = []
	for e in [["a", Color(0.97, 0.93, 0.9)], ["b", Color(0.98, 0.78, 0.74)], ["c", Color(0.95, 0.85, 0.62)], ["d", Color(0.8, 0.88, 0.97)], ["e", Color(0.9, 0.62, 0.45)]]:
		nacres.append(L._m(M, "reserve119_nacre_" + str(e[0]), e[1], 0.25, 0.15))
	var chante: StandardMaterial3D = L._m(M, "reserve119_chante", Color(0.78, 0.92, 1.0), 0.2, 0.1, 0.6)
	# ---------------------------------------------------------------- les étagères à coquillages (au fond)
	var zs: float = -hd + 0.21
	var chantants: Array = []
	for u in [[-1.5, 2.3], [1.5, 2.3]]:
		var ux: float = float(u[0])
		var uw: float = float(u[1])
		_reserve_etagere(M, ux, uw)
		for pl in range(RESERVE_PLANCHES.size()):
			if ux > 0.0 and pl < 2:
				continue                                # (en bas, à droite : les cordes et les bocaux de perles)
			var py: float = float(RESERVE_PLANCHES[pl]) + 0.015
			for j in range(7):
				var px: float = ux - uw * 0.5 + 0.2 + (uw - 0.4) * j / 6.0 + rng.randf_range(-0.04, 0.04)
				var spec: bool = ux < 0.0 and pl == 2 and j % 3 == 1
				var mat: Material = chante if spec else nacres[rng.randi() % nacres.size()]
				var sh: Node3D = _reserve_coquillage(o, Vector3(px, py, zs + rng.randf_range(-0.05, 0.05)), rng.randf_range(0.8, 1.4) * (1.3 if spec else 1.0), mat, rng.randi() % 3, rng.randf_range(-0.7, 0.7))
				if spec:
					chantants.append(sh)
	# en bas, à droite : des rouleaux de corde, des bocaux de perles d'Azur
	var corde: StandardMaterial3D = L._m(M, "reserve119_corde", Color(0.78, 0.66, 0.45), 0.9)
	for c in range(3):
		for hh in range(3 - c % 2):
			L._mesh(o, L._tore(0.07, 0.15), corde, Transform3D(Basis(), Vector3(0.75 + c * 0.6, 0.135 + hh * 0.07, zs)))
	var perle: StandardMaterial3D = L._m(M, "reserve119_perle", Color(0.55, 0.8, 1.0), 0.1, 0.2, 0.8)
	for b in range(4):
		var bx: float = 0.7 + b * 0.55
		k.cyl(R.L(bx, 0.595, zs), 0.09, 0.09, 0.24, "verre", 14, false)
		k.cyl(R.L(bx, 0.835, zs), 0.095, 0.095, 0.03, "cuivre", 14)
		for q in range(6):
			L._mesh(o, I._sph(0.022), perle if b % 2 == 0 else nacres[q % nacres.size()], Transform3D(Basis(), Vector3(bx - 0.04 + (q % 3) * 0.04, 0.62 + floori(q / 3.0) * 0.038, zs - 0.015 + (q % 2) * 0.03)))
	# entre les deux étagères : l'enseigne du Comptoir, et une caisse fermée en dessous
	k.box(R.L(0, 1.75, -hd + 0.02), Vector3(0.62, 0.62, 0.02), "argent", 1.0)
	_reserve_affiche(M, R.L(0, 1.75, -hd + 0.035), Vector2(0.56, 0.56), "dome115/enseigne_comptoir.png")
	R.mark_wall(0, 1.75, -hd, 0.35)
	R.caisse(0.0, -hd + 0.33, 0.45)
	_diodes(M, Vector3(-hw + 0.1, R.H - 0.05, -hd + 0.05), Vector3(hw - 0.1, R.H - 0.05, -hd + 0.05))
	L._lampe(M, R.P(-1.5, 2.3, -1.5), Color(1.0, 0.92, 0.82), 0.4 if nuit else 0.6, 3.2)
	# ---------------------------------------------------------------- le pupitre d'Ernest et le grand registre
	var pu: Transform3D = R.L(1.5, 0, -1.0)
	for sx in [-1.0, 1.0]:
		k.box(pu * Transform3D(Basis(), Vector3(sx * 0.5, 0.5, 0)), Vector3(0.05, 1.0, 0.5), "argent", 1.0)
	k.box(pu * Transform3D(Basis(), Vector3(0, 0.52, 0.22)), Vector3(1.0, 0.9, 0.03), "ceramique", 1.0)
	k.box(pu * Transform3D(Basis(), Vector3(0, 0.25, 0)), Vector3(0.96, 0.03, 0.46), "bois_clair", 1.0)
	var incl := Basis(Vector3.RIGHT, -0.22)
	var dessus: Transform3D = pu * Transform3D(incl, Vector3(0, 1.0, 0))
	k.box(dessus, Vector3(1.1, 0.04, 0.6), "bois", 1.0)
	k.box(dessus * Transform3D(Basis(), Vector3(0, 0.025, 0.0)), Vector3(0.62, 0.012, 0.42), "tissu_bleu", 1.0)
	for s2 in [-1.0, 1.0]:
		k.box(dessus * Transform3D(Basis(Vector3.BACK, -s2 * 0.05), Vector3(s2 * 0.15, 0.04, 0.0)), Vector3(0.29, 0.016, 0.39), "papier", 1.0)
		for li in range(6):
			k.box(dessus * Transform3D(Basis(), Vector3(s2 * 0.15, 0.05 + s2 * 0.0, -0.14 + li * 0.055)), Vector3(0.21 - (li % 3) * 0.04, 0.003, 0.008), "tissu_bleu", 1.0)
	k.cyl(dessus * Transform3D(Basis(), Vector3(0.44, 0.02, -0.12)), 0.035, 0.03, 0.06, "noir", 10)
	var plume_mat: StandardMaterial3D = L._m(M, "reserve119_plume", Color(0.97, 0.97, 0.95), 0.8)
	var pn: Node3D = I._node(M, (dessus * Transform3D(Basis(), Vector3(0.44, 0.1, -0.12))).origin)
	L._mesh(pn, I._boxm(Vector3(0.012, 0.2, 0.04)), plume_mat, Transform3D(Basis(Vector3.BACK, 0.35), Vector3.ZERO))
	k.col_box(pu * Transform3D(Basis(), Vector3(0, 0.55, 0)), Vector3(1.05, 1.1, 0.55))
	R.reserve(1.5, -1.0, 1.3, 0.8)
	L._lampe(M, R.P(1.5, 1.7, -1.1), Color(1.0, 0.86, 0.66), 0.55, 2.8)
	# ---------------------------------------------------------------- la balance à plateaux, sur sa table ronde
	var bt := Vector2(-0.6, -0.7)
	k.cyl(R.L(bt.x, 0.77, bt.y), 0.4, 0.4, 0.03, "ceramique", 22)
	k.cyl(R.L(bt.x, 0.0, bt.y), 0.04, 0.04, 0.77, "argent", 8, false)
	k.cyl(R.L(bt.x, 0.0, bt.y), 0.24, 0.26, 0.03, "argent", 16)
	k.col_box(R.L(bt.x, 0.4, bt.y), Vector3(0.6, 0.8, 0.6))
	R.reserve(bt.x, bt.y, 1.0, 1.0)
	var cuivre: Material = R.mat("cuivre")
	var bal: Node3D = I._node(M, R.P(bt.x, 0.8, bt.y))
	L._mesh(bal, L._cylm(0.1, 0.12, 0.03, 16), cuivre, Transform3D(Basis(), Vector3(0, 0.015, 0)))
	L._mesh(bal, L._cylm(0.015, 0.02, 0.48, 8), cuivre, Transform3D(Basis(), Vector3(0, 0.27, 0)))
	var fleau := Node3D.new()
	bal.add_child(fleau)
	fleau.position = Vector3(0, 0.5, 0)
	L._mesh(fleau, I._boxm(Vector3(0.56, 0.018, 0.018)), cuivre)
	L._mesh(fleau, I._sph(0.025), cuivre)
	L._mesh(fleau, L._cylm(0.003, 0.012, 0.1, 6), cuivre, Transform3D(Basis(), Vector3(0, 0.06, 0)))
	var plateaux: Array = []
	for s3 in [-1.0, 1.0]:
		var pt := Node3D.new()
		bal.add_child(pt)
		pt.position = Vector3(s3 * 0.26, 0.29, 0)
		L._mesh(pt, L._cylm(0.1, 0.08, 0.015, 18), cuivre)
		for ch in range(3):
			var a: float = TAU * ch / 3.0
			_reserve_tige(pt, Vector3(cos(a) * 0.085, 0.008, sin(a) * 0.085), Vector3(0, 0.21, 0), 0.0025, cuivre)
		plateaux.append(pt)
	L._mesh(plateaux[0], I._sph(0.03), perle, Transform3D(Basis(), Vector3(0, 0.035, 0)))
	L._mesh(plateaux[1], I._boxm(Vector3(0.012, 0.012, 0.16)), plume_mat, Transform3D(Basis(Vector3.UP, 0.5), Vector3(0, 0.015, 0)))
	M.ctx["pese119"] = 0.0
	M.ctx["fleau119"] = 0.0
	# ---------------------------------------------------------------- l'aquarium des bernard-l'ermite (mur de gauche)
	var aq := Vector2(-hw + 0.33, -1.3)
	k.box(R.L(aq.x, 0.37, aq.y), Vector3(0.52, 0.74, 1.1), "ceramique", 1.0)
	k.box(R.L(aq.x + 0.262, 0.62, aq.y), Vector3(0.01, 0.03, 1.0), "argent", 1.0)
	k.col_box(R.L(aq.x, 0.6, aq.y), Vector3(0.52, 1.2, 1.1))
	R.reserve(aq.x, aq.y, 0.7, 1.3)
	var bac: Node3D = I._node(M, R.P(aq.x, 0.74, aq.y))
	L._mesh(bac, I._boxm(Vector3(0.46, 0.44, 1.02)), L._m(M, "reserve119_vitre", Color(0.85, 0.95, 1.0, 0.16), 0.05, 0.0, 0.0, true), Transform3D(Basis(), Vector3(0, 0.22, 0)))
	L._mesh(bac, I._boxm(Vector3(0.44, 0.36, 1.0)), L._m(M, "reserve119_eau", Color(0.3, 0.75, 0.85, 0.2), 0.1, 0.0, 0.3), Transform3D(Basis(), Vector3(0, 0.2, 0)))
	L._mesh(bac, I._boxm(Vector3(0.44, 0.05, 1.0)), L._m(M, "reserve119_sable", Color(0.92, 0.85, 0.7), 1.0), Transform3D(Basis(), Vector3(0, 0.025, 0)))
	for sx2 in [-1.0, 1.0]:
		L._mesh(bac, I._boxm(Vector3(0.02, 0.02, 1.04)), R.mat("argent"), Transform3D(Basis(), Vector3(sx2 * 0.235, 0.44, 0)))
		L._mesh(bac, I._boxm(Vector3(0.48, 0.02, 0.02)), R.mat("argent"), Transform3D(Basis(), Vector3(0, 0.44, sx2 * 0.515)))
	var roche: StandardMaterial3D = L._m(M, "reserve119_roche", Color(0.55, 0.57, 0.6), 0.9)
	for r2 in range(3):
		L._mesh(bac, I._sph(0.05 + r2 * 0.015), roche, Transform3D(Basis.from_scale(Vector3(1.2, 0.6, 1.0)), Vector3(-0.13 + r2 * 0.12, 0.06, -0.42 + r2 * 0.4)))
	var algue: StandardMaterial3D = L._m(M, "reserve119_algue", Color(0.25, 0.65, 0.4), 0.7, 0.0, 0.2, true)
	for g in range(4):
		var ag := Node3D.new()
		bac.add_child(ag)
		ag.position = Vector3(0.15 - (g % 2) * 0.3, 0.05, -0.3 + g * 0.2)
		L._mesh(ag, I._boxm(Vector3(0.03, 0.22 + (g % 3) * 0.05, 0.004)), algue, Transform3D(Basis(), Vector3(0, 0.12, 0)))
		L._balance(M, ag, Vector3.FORWARD, 0.18, 3.0 + g * 0.4, g * 1.3)
	var crabe: StandardMaterial3D = L._m(M, "reserve119_crabe", Color(0.95, 0.45, 0.3), 0.6)
	var bernards: Array = []
	for i in range(4):
		var bn: Node3D = _reserve_bernard(bac, crabe, R.mat("noir"), nacres[i % nacres.size()], 0.85 + i * 0.12)
		bn.position = Vector3(-0.1 + (i % 2) * 0.18, 0.05, -0.32 + i * 0.12)
		bernards.append(bn)
	var aqua: Dictionary = {"vide": _reserve_coquillage(bac, Vector3(0.1, 0.05, 0.36), 1.1, nacres[4], 2, 0.6)}
	var bulles: CPUParticles3D = _reserve_bulles(M, R.P(aq.x + 0.15, 0.82, aq.y + 0.42), Vector3(0.02, 0.01, 0.02), 10, 0.15, 0.012, 2.2, Color(1, 1, 1, 0.6))
	L._lampe(M, R.P(aq.x + 0.15, 1.15, aq.y), Color(0.45, 0.9, 1.0), 0.5 if nuit else 0.35, 2.0)
	# ---------------------------------------------------------------- les caisses du troc
	# ce qui monte (devant, à gauche) : le poisson des nasses, les perles, la spiruline
	R.caisse(-2.3, -0.3, 0.55)
	R.caisse(-2.3, -0.3, 0.45, 0.55)
	var cm := Vector2(-2.15, 0.45)
	_reserve_caisse(M, cm.x, cm.y, 0.0)
	k.box(R.L(cm.x, 0.2, cm.y), Vector3(0.64, 0.3, 0.44), "papier", 1.0)
	var poisson: StandardMaterial3D = L._m(M, "reserve119_poisson", Color(0.72, 0.78, 0.84), 0.3, 0.6)
	for f in range(4):
		var fp := Vector3(cm.x - 0.17, 0.375 + (f % 2) * 0.025, cm.y - 0.14 + f * 0.09)
		L._mesh(o, I._sph(0.03), poisson, Transform3D(Basis(Vector3.UP, 0.15 * (f % 3 - 1)) * Basis.from_scale(Vector3(3.6, 0.8, 1.0)), fp))
		L._mesh(o, I._boxm(Vector3(0.04, 0.008, 0.05)), poisson, Transform3D(Basis(), fp + Vector3(0.13, 0, 0)))
	k.cyl(R.L(cm.x + 0.06, 0.35, cm.y), 0.085, 0.08, 0.03, "ceramique", 16)
	for q2 in range(6):
		L._mesh(o, I._sph(0.018), perle, Transform3D(Basis(), Vector3(cm.x + 0.03 + (q2 % 3) * 0.03, 0.39, cm.y - 0.02 + floori(q2 / 3.0) * 0.04)))
	var spiru: StandardMaterial3D = L._m(M, "reserve119_spiruline", Color(0.15, 0.55, 0.62), 0.3, 0.0, 0.4)
	for j2 in range(3):
		var jp: Vector3 = Vector3(cm.x + 0.24, 0.35, cm.y - 0.13 + j2 * 0.13)
		k.cyl(R.L(jp.x, jp.y, jp.z), 0.045, 0.045, 0.15, "verre", 12, false)
		k.cyl(R.L(jp.x, jp.y + 0.15, jp.z), 0.048, 0.048, 0.02, "cuivre", 12)
		L._mesh(o, L._cylm(0.04, 0.04, 0.1, 12), spiru, Transform3D(Basis(), jp + Vector3(0, 0.05, 0)))
	# ce qui descend (devant, à droite) : des pommes, des livres, des plumes
	var cd := Vector2(2.15, 0.4)
	_reserve_caisse(M, cd.x, cd.y, 0.0)
	k.box(R.L(cd.x, 0.2, cd.y), Vector3(0.64, 0.3, 0.44), "carton", 1.0)
	var objets_tri: Array = []
	var pomme: Material = R.mat("pomme")
	var queue: StandardMaterial3D = L._m(M, "reserve119_queue", Color(0.35, 0.25, 0.15), 0.9)
	for a2 in range(6):
		var ap: Node3D = I._node(M, R.P(cd.x - 0.22 + (a2 % 3) * 0.09, 0.39, cd.y - 0.1 + floori(a2 / 3.0) * 0.1))
		L._mesh(ap, I._sph(0.045), pomme)
		L._mesh(ap, L._cylm(0.004, 0.004, 0.03, 4), queue, Transform3D(Basis(), Vector3(0, 0.05, 0)))
		objets_tri.append(ap)
	for l2 in range(3):
		var lv: Node3D = I._node(M, R.P(cd.x + 0.08, 0.37 + l2 * 0.045, cd.y + 0.02), 10.0 * (l2 - 1))
		L._mesh(lv, I._boxm(Vector3(0.18, 0.04, 0.25)), R.mat(["tissu_rouge", "tissu_vert", "tissu_jaune"][l2]))
		L._mesh(lv, I._boxm(Vector3(0.17, 0.034, 0.005)), R.mat("papier"), Transform3D(Basis(), Vector3(0, 0, 0.125)))
		objets_tri.append(lv)
	k.cyl(R.L(cd.x + 0.26, 0.35, cd.y - 0.12), 0.05, 0.05, 0.1, "argent", 12, false)
	for p2 in range(4):
		var fe: Node3D = I._node(M, R.P(cd.x + 0.26, 0.4, cd.y - 0.12))
		L._mesh(fe, I._boxm(Vector3(0.012, 0.2, 0.04)), plume_mat, Transform3D(Basis(Vector3.UP, p2 * 0.8) * Basis(Vector3.BACK, -0.35 + p2 * 0.22), Vector3(0, 0.08, 0)))
		objets_tri.append(fe)
	# ---------------------------------------------------------------- ce qui bouge : les coquillages qui chantent, le fléau, les bernard-l'ermite
	var note: Label3D = L._etiquette(M, R.P(-1.5, 1.9, -1.9), "♪")
	M.ctx["chant119"] = 0.0
	L._chaque(M, func(delta: float, t: float) -> void:
		var boost: float = maxf(0.0, float(M.ctx.get("chant119", 0.0)) - delta)
		M.ctx["chant119"] = boost
		chante.emission_energy_multiplier = 0.35 + 0.55 * pow(maxf(0.0, sin(t * 0.9)), 4.0) + boost * 1.2 + (0.3 if nuit else 0.0)
		var a0: float = lerpf(float(M.ctx.get("fleau119", 0.0)), float(M.ctx.get("pese119", 0.0)), minf(1.0, delta * 2.0))
		M.ctx["fleau119"] = a0
		var a1: float = a0 + sin(t * 1.7) * 0.012
		if is_instance_valid(fleau):
			fleau.rotation.z = a1
			for s4 in range(2):
				var sg: float = -1.0 if s4 == 0 else 1.0
				(plateaux[s4] as Node3D).position = Vector3(sg * 0.26 * cos(a1), 0.5 + sg * 0.26 * sin(a1) - 0.21, 0)
		for i2 in range(1, bernards.size()):
			var bw: Node3D = bernards[i2]
			if is_instance_valid(bw):
				var ph: float = t * (0.16 + i2 * 0.05) + i2 * 1.7
				bw.position.z = -0.3 + i2 * 0.12 + sin(ph) * 0.18
				bw.rotation.y = lerp_angle(bw.rotation.y, 0.0 if cos(ph) > 0.0 else PI, minf(1.0, delta * 3.0)))
	# ---------------------------------------------------------------- les gens
	if soir:
		var commis: Node = L._gens(M, "homme", 1.5, -1.6, 0.0, "comptoir", ["Trois cent soixante-quinze… trois cent soixante-seize… Il en manque un. Ah non : il était dans ma poche. Il chantait.",
			"Monsieur Coquillard m'a laissé la liste de l'inventaire. Elle fait quatre pages. La liste des nouvelles en fait six."])
		L._causer(M, commis, ["Bonsoir ! Monsieur Coquillard est parti. Moi, je range, je compte, et je garde la réserve jusqu'à ce que tout soit compté.", "Bonnes bulles ! Chut… à cette heure-ci, les coquillages chantent un peu plus fort. Écoute."],
			[["ernest", "Où est Ernest ?", ["Le soir, il attend le dernier Funiculaire sur le banc de la Gare. Il cueille les nouvelles à la sortie, comme des fruits mûrs. Puis il va manger à La Conque, puis il rentre relire ses cahiers. Il revient toujours avec une page de plus."]],
			["commis", "Tu travailles ici depuis longtemps ?", ["Depuis la réouverture de la Ligne. Avant, il n'y avait pas assez de caisses pour avoir besoin d'un commis. Maintenant, il y en a tant que Monsieur Coquillard a besoin de moi, d'un registre neuf et d'un crayon de rechange."]],
			["chanter", "Les coquillages chantent la nuit ?", ["Un peu plus fort, oui. Le Professeur Benthos dit que c'est parce que le Dôme est plus silencieux. Moi, je crois qu'ils s'ennuient de la Grande Chanteuse. Je leur laisse la lampe allumée."]]])
		if not nuit:
			var port: Node = L._gens(M, "homme", -0.2, 0.8, 90.0, "marcher", ["Le dernier Funiculaire est arrivé ! Six caisses en bas, six caisses en haut. Ernest dit que c'est « l'équilibre des mondes ». Moi, je dis que c'est mon dos.",
				"Une caisse de pommes d'en haut ! Elle sent l'herbe. Je ne sais pas ce que c'est, l'herbe, mais ça sent bon."])
			var cs: Node3D = _reserve_porte_caisse(port)
			L._va_et_vient(M, port, R.P(-0.2, 0, 0.8), R.P(1.45, 0, 0.75), 0.8, 2.5, cs)
			L._causer(M, port, ["Bonnes bulles ! Pardon, je passe, c'est lourd !", "Bonsoir ! Attention aux pieds : cette caisse est pleine de livres d'en haut. Ils pèsent plus lourd que les nôtres. Ils ont plus de pages."],
				[["caisse", "Qu'est-ce que tu portes ?", ["Des pommes de Hautefond, pour La Conque. Josette en fait une tarte qui a le goût de la surface. Tout le Dôme fait la queue. Moi, je porte la caisse : j'ai droit à la première part."]]])
		M.ctx["entree"] = "Le soir, dans la réserve du Comptoir : la lampe du pupitre est allumée, l'aquarium luit tout bleu, et le commis compte les coquillages à voix basse. Certains, à cette heure-ci, chantent un peu plus fort."
	else:
		var ernest: Node = M.person("homme", 1.5, -1.6, 0.0, "comptoir", "Ernest Coquillard")
		ernest.lines = ["Celui-ci, je l'appelle Hortense. Et celui-là, Gaspard. Trois cent soixante-dix-sept coquillages, trois cent soixante-dix-sept prénoms. Je n'en ai oublié aucun. Enfin, presque.",
			"Ça monte, ça descend, ça monte… Je note, je note ! Le Funiculaire, c'est un grand registre qui bouge."]
		L._causer(M, ernest, ["Un client dans ma réserve ! Bonnes bulles ! Attention où tu mets les pieds : la caisse de gauche, elle chante. Alors, quoi de neuf, là-haut ?", "Bonnes bulles ! Tu tombes bien, je fais l'inventaire : des coquillages, des cordes, des perles… et zéro nouvelle. Tu en as une ? Même une toute petite ?"],
			[["chantent", "Pourquoi ces coquillages chantent-ils ?", ["Une affaire de forme ! Tu en approches un de ton oreille, et tu entends la Grande Chanteuse. Le Professeur Benthos dit que c'est ton sang qui bouge. Il en a quand même acheté trois. Je l'ai noté dans mon Cahier."]],
			["troc", "Qu'y a-t-il dans ces caisses ?", ["Le troc avec la surface ! Ce qui monte : notre poisson, nos perles d'Azur, la spiruline des Serres. Ce qui descend : des pommes, des livres, des plumes… et des potins. Les potins sont plus légers que les pommes. Ils descendent plus vite."]],
			["registre", "C'est quoi, ce grand registre ?", ["Tout ce qui monte et tout ce qui descend, depuis que la Ligne a rouvert. Et dans la marge, les nouvelles. Les marchandises, c'est pour le Comptoir. Les nouvelles, c'est pour moi."]],
			["nouvelle", "J'ai une nouvelle pour toi !", func() -> void:
				if is_instance_valid(ernest) and ernest.has_method("gesture"):
					ernest.gesture("joie", 2.5)
				M.talk(ernest, str(L._pick(M, ["Une nouvelle ?! Attends, attends, je prends mon crayon… Voilà. Raconte. Non, plus lentement. … Formidable ! Je l'écris en grand sur le tableau. Tout le Dôme le saura avant ce soir.",
					"Une nouvelle d'en haut ! Une vraie ! Je note, je note ! … C'est la meilleure de la journée. Bon, c'est la seule. Mais elle est excellente."])), [{"id": "fermer", "label": "Bonnes bulles !"}], func(_i): M.close_talk())]])
		var cult: Node = L._gens(M, "femme", -1.35, 0.45, -90.0, "bricoler", ["Douze bocaux de spiruline, tout frais du mur des algues. Regarde mes mains : bleues jusqu'aux coudes !",
			"Là-haut, ils mettent notre spiruline dans leurs gâteaux. Des gâteaux bleus ! Je voudrais bien voir ça."])
		L._causer(M, cult, ["Bonnes bulles ! Je livre la spiruline des Serres. Elle monte ce soir, avec le dernier Funiculaire.", "Bonjour ! Ne fais pas attention à mes mains bleues. C'est la spiruline. Ça part. Au bout d'une semaine."],
			[["spiruline", "Ça sert à quoi, la spiruline ?", ["C'est une petite algue, toute bleue, pleine de forces. On en met dans la limonade de Josette, dans les galettes, partout. Les enfants ont la langue bleue toute la journée. Là-haut, ils commencent à adorer ça."]]])
		var port2: Node = L._gens(M, "homme", -0.2, 0.8, 90.0, "marcher", ["Une caisse de livres d'en haut ! Ils pèsent plus lourd que les nôtres. Ils ont plus de pages.",
			"Six caisses en bas, six caisses en haut. Ernest dit que c'est « l'équilibre des mondes ». Moi, je dis que c'est mon dos."])
		var cs2: Node3D = _reserve_porte_caisse(port2)
		L._va_et_vient(M, port2, R.P(-0.2, 0, 0.8), R.P(1.45, 0, 0.75), 0.8, 3.0, cs2)
		L._causer(M, port2, ["Bonnes bulles ! Pardon, je passe, c'est lourd !"],
			[["caisse", "Qu'est-ce que tu portes ?", ["Des pommes de Hautefond, pour La Conque. Josette en fait une tarte qui a le goût de la surface. Tout le Dôme fait la queue. Moi, je porte la caisse : j'ai droit à la première part."]]])
		M.ctx["entree"] = str(L._pick(M, ["La réserve du Comptoir des Courants : des étagères de coquillages jusqu'au plafond, des caisses ouvertes qui sentent la mer et la pomme, une balance de cuivre, et dans un coin, un aquarium où des bernard-l'ermite déménagent.",
			"Ça sent le sel, le carton et la pomme d'en haut. Sur les étagères, certains coquillages fredonnent tout bas. Derrière son pupitre, Ernest Coquillard écrit dans un très grand registre.",
			"L'arrière-boutique d'Ernest Coquillard : ce qui monte vers la surface d'un côté, ce qui en descend de l'autre, et au milieu, la balance qui met tout le monde d'accord."]))
	# ---------------------------------------------------------------- ce qu'on fait : écouter, peser, trier, regarder, lire
	M.act(R.P(-1.5, 1.2, -1.75), "E : écouter un coquillage", func() -> void:
		M.main.sfx("cristal_chante", R.P(-1.5, 1.2, -2.2))
		M.ctx["chant119"] = 2.5
		var n: int = int(M.ctx.get("ecoute119", 0))
		M.ctx["ecoute119"] = n + 1
		if not chantants.is_empty():
			var sh2: Node3D = chantants[n % chantants.size()]
			if is_instance_valid(sh2):
				var tw: Tween = M.room.create_tween()
				tw.tween_property(sh2, "scale", Vector3.ONE * 1.3, 0.4).set_trans(Tween.TRANS_SINE)
				tw.tween_property(sh2, "scale", Vector3.ONE, 1.2).set_trans(Tween.TRANS_SINE)
		L._montrer(M, note, 3.0)
		M.say(str(RESERVE_COQUILLAGES[n % RESERVE_COQUILLAGES.size()]), 7.0)
	, 1.3)
	M.act(R.P(bt.x, 1.0, bt.y + 0.5), "E : peser", func() -> void:
		var n2: int = int(M.ctx.get("pesee119", rng.randi() % RESERVE_PESEES.size()))
		M.ctx["pesee119"] = n2 + 1
		var pe: Array = RESERVE_PESEES[n2 % RESERVE_PESEES.size()]
		M.main.sfx("clochette", R.P(bt.x, 1.2, bt.y))
		M.ctx["pese119"] = float(pe[0]) * 0.4 - 0.25 * signf(float(pe[0]) + 0.001)
		M.say(str(pe[1]), 7.0)
		await M.get_tree().create_timer(1.2).timeout
		if not _la(M, room0):
			return
		M.ctx["pese119"] = float(pe[0])
		await M.get_tree().create_timer(5.0).timeout
		if _la(M, room0):
			M.ctx["pese119"] = 0.0
	, 1.2)
	M.act(R.P(cd.x - 0.6, 0.8, cd.y + 0.05), "E : aider à trier la caisse", func() -> void:
		if bool(M.ctx.get("tri119", false)):
			return
		M.ctx["tri119"] = true
		M.main.sfx("ramasse", R.P(cd.x, 0.5, cd.y))
		for j3 in range(objets_tri.size()):
			var it: Node3D = objets_tri[j3]
			if is_instance_valid(it):
				var p0: Vector3 = it.position
				var tw2: Tween = M.room.create_tween()
				tw2.tween_interval(j3 * 0.12)
				tw2.tween_property(it, "position", p0 + Vector3(0, 0.28, 0), 0.25).set_trans(Tween.TRANS_SINE)
				tw2.tween_property(it, "position", p0, 0.4).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		var st: Dictionary = M.state()
		if not bool(st.get("tri_reserve119", false)):
			st["tri_reserve119"] = true
			for f2 in M.people:
				if is_instance_valid(f2) and f2.has_method("gesture"):
					f2.gesture("applaudir", 2.0)
			M.give([["coquillage_chanteur", 1]], "Tu tries toute la caisse : les pommes avec les pommes, les livres avec les livres, les plumes avec beaucoup de patience. Au fond, un petit coquillage fredonnait tout seul. « Garde-le : il a choisi de remonter avec toi. » Tu reçois :\n")
		else:
			M.say(str(L._pick(M, RESERVE_TRI)), 6.0)
		await M.get_tree().create_timer(2.5).timeout
		if _la(M, room0):
			M.ctx["tri119"] = false
	, 1.2)
	M.act(R.P(aq.x + 0.75, 1.0, aq.y), "E : regarder les bernard-l'ermite", func() -> void:
		M.main.sfx("bulles", R.P(aq.x, 1.0, aq.y))
		if is_instance_valid(bulles):
			var n0: int = bulles.amount
			bulles.amount = 30
			_reserve_bulles_calme(M, room0, bulles, n0)
		var n3: int = int(M.ctx.get("bernard119", 0))
		M.ctx["bernard119"] = n3 + 1
		M.say(str(RESERVE_BERNARD[n3 % RESERVE_BERNARD.size()]), 7.0)
		if bool(M.ctx.get("demenage119", false)):
			return
		var b0: Node3D = bernards[0]
		var vide: Node3D = aqua["vide"]
		if not is_instance_valid(b0) or not is_instance_valid(vide):
			return
		M.ctx["demenage119"] = true
		var depart: Vector3 = b0.position
		var arrivee: Vector3 = vide.position + Vector3(0, 0, -0.07)
		var dv: Vector3 = arrivee - depart
		b0.rotation.y = atan2(dv.x, dv.z)
		var tw3: Tween = M.room.create_tween()
		tw3.tween_property(b0, "position", arrivee, 2.5).set_trans(Tween.TRANS_SINE)
		await tw3.finished
		if not _la(M, room0) or not is_instance_valid(b0) or not is_instance_valid(vide):
			return
		# l'échange : l'ancienne coquille reste dans le sable, la nouvelle part sur le dos du bernard-l'ermite
		var ancienne: Node3D = b0.get_meta("coquille")
		ancienne.reparent(bac)
		vide.reparent(b0, false)
		vide.position = Vector3(0, 0, -0.01)
		vide.rotation = Vector3(0, PI * 0.5, 0)
		vide.scale = Vector3.ONE * 0.75
		b0.set_meta("coquille", vide)
		aqua["vide"] = ancienne
		M.main.sfx("bulles", R.P(aq.x, 1.0, aq.y))
		await M.get_tree().create_timer(1.5).timeout
		if not _la(M, room0) or not is_instance_valid(b0):
			return
		b0.rotation.y = atan2(-dv.x, -dv.z)
		var tw4: Tween = M.room.create_tween()
		tw4.tween_property(b0, "position", depart, 2.5).set_trans(Tween.TRANS_SINE)
		await tw4.finished
		if _la(M, room0):
			M.ctx["demenage119"] = false
	, 1.3)
	M.act(R.P(1.5, 1.1, -0.45), "E : lire le registre", func() -> void:
		M.main.sfx("ui_ouvrir", R.P(1.5, 1.1, -1.0))
		var n4: int = int(M.ctx.get("registre119", 0))
		M.ctx["registre119"] = n4 + 1
		M.say(str(RESERVE_REGISTRE[n4 % RESERVE_REGISTRE.size()]), 9.0)
	, 1.1)


## Les bulles de l'aquarium s'emballent un moment, puis se calment.
static func _reserve_bulles_calme(M, room0, p: CPUParticles3D, n0: int) -> void:
	await M.get_tree().create_timer(3.0).timeout
	if _la(M, room0) and is_instance_valid(p):
		p.amount = n0


## Une étagère à coquillages contre le mur du fond (x : son milieu, w : sa largeur) : un fond de nacre,
## des montants de titane, des planches claires.
static func _reserve_etagere(M, x: float, w: float) -> void:
	var R = M.R
	var k = R.kit
	var z: float = -R.D * 0.5 + 0.21
	var xf: Transform3D = R.L(x, 0, z)
	k.box(xf * Transform3D(Basis(), Vector3(0, 1.25, -0.18)), Vector3(w, 2.5, 0.02), "ceramique", 1.0)
	for sx in [-1.0, 1.0]:
		k.box(xf * Transform3D(Basis(), Vector3(sx * (w * 0.5 - 0.02), 1.25, 0)), Vector3(0.04, 2.5, 0.38), "argent", 1.0)
	for y in RESERVE_PLANCHES:
		k.box(xf * Transform3D(Basis(), Vector3(0, float(y), 0)), Vector3(w, 0.03, 0.38), "bois_clair", 1.0)
	k.col_box(xf * Transform3D(Basis(), Vector3(0, 1.25, 0)), Vector3(w, 2.5, 0.38))
	R.reserve(x, z, w + 0.1, 0.5)


## Un coquillage posé en p (dans parent) : 0 une conque, 1 une coquille en éventail, 2 un escargot de mer.
static func _reserve_coquillage(parent: Node3D, p: Vector3, s: float, mat: Material, kind: int, yaw: float) -> Node3D:
	var n := Node3D.new()
	parent.add_child(n)
	n.position = p
	n.rotation.y = yaw
	match kind:
		0:
			L._mesh(n, L._cylm(0.004, 0.045 * s, 0.13 * s, 10), mat, Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(0.05 * s, 0.04 * s, 0)))
			L._mesh(n, I._sph(0.045 * s), mat, Transform3D(Basis.from_scale(Vector3(0.9, 0.9, 0.75)), Vector3(-0.03 * s, 0.04 * s, 0)))
		1:
			L._mesh(n, I._sph(0.06 * s), mat, Transform3D(Basis(Vector3.RIGHT, -1.1) * Basis.from_scale(Vector3(1.0, 0.25, 0.9)), Vector3(0, 0.05 * s, 0)))
			L._mesh(n, I._boxm(Vector3(0.03, 0.02, 0.012) * s), mat, Transform3D(Basis(), Vector3(0, 0.01 * s, 0.02 * s)))
		_:
			for j in range(3):
				var r: float = (0.045 - j * 0.012) * s
				L._mesh(n, I._sph(r), mat, Transform3D(Basis(), Vector3(j * 0.025 * s, r + j * 0.02 * s, 0)))
	return n


## Un bernard-l'ermite (la tête vers +Z) : le corps, les pinces, les pattes, les yeux au bout de leurs
## tiges, et sa coquille (gardée dans la méta « coquille »).
static func _reserve_bernard(parent: Node3D, chair: Material, noir: Material, coq: Material, s: float) -> Node3D:
	var n := Node3D.new()
	parent.add_child(n)
	n.scale = Vector3.ONE * s
	var coquille: Node3D = _reserve_coquillage(n, Vector3(0, 0, -0.01), 0.75, coq, 2, PI * 0.5)
	n.set_meta("coquille", coquille)
	L._mesh(n, I._sph(0.018), chair, Transform3D(Basis.from_scale(Vector3(1.2, 0.8, 1.0)), Vector3(0, 0.015, 0.025)))
	for sx in [-1.0, 1.0]:
		L._mesh(n, I._sph(0.012), chair, Transform3D(Basis(), Vector3(sx * 0.018, 0.012, 0.05)))
		for lg in range(2):
			L._mesh(n, I._boxm(Vector3(0.03, 0.006, 0.006)), chair, Transform3D(Basis(Vector3.BACK, sx * 0.4), Vector3(sx * 0.025, 0.008, 0.012 + lg * 0.016)))
		L._mesh(n, L._cylm(0.002, 0.002, 0.025, 4), chair, Transform3D(Basis(), Vector3(sx * 0.008, 0.035, 0.035)))
		L._mesh(n, I._sph(0.005), noir, Transform3D(Basis(), Vector3(sx * 0.008, 0.048, 0.035)))
	return n


## Une tige (une chaînette, un montant) de a à b dans un nœud.
static func _reserve_tige(parent: Node3D, a: Vector3, b: Vector3, r: float, mat: Material) -> void:
	var d: Vector3 = b - a
	if d.length() < 0.001:
		return
	var bs := Basis(Quaternion(Vector3.UP, d.normalized())) if absf(d.normalized().dot(Vector3.UP)) < 0.999 else Basis()
	L._mesh(parent, L._cylm(r, r, d.length(), 6), mat, Transform3D(bs, (a + b) * 0.5))


## Une caisse ouverte du troc (x, z : son centre, repère de la pièce) : le fond, les côtés, les lattes.
static func _reserve_caisse(M, x: float, z: float, yaw: float) -> void:
	var R = M.R
	var k = R.kit
	var xf: Transform3D = R.L(x, 0, z, yaw)
	var w: float = 0.7
	var d: float = 0.5
	var h: float = 0.42
	k.box(xf * Transform3D(Basis(), Vector3(0, 0.03, 0)), Vector3(w, 0.06, d), "bois_clair", 1.0)
	for sz in [-1.0, 1.0]:
		k.box(xf * Transform3D(Basis(), Vector3(0, h * 0.5, sz * (d * 0.5 - 0.01))), Vector3(w, h, 0.02), "bois_clair", 1.0)
		k.box(xf * Transform3D(Basis(), Vector3(0, h - 0.06, sz * (d * 0.5 + 0.003))), Vector3(w + 0.02, 0.05, 0.02), "bois_sombre", 1.0)
	for sx in [-1.0, 1.0]:
		k.box(xf * Transform3D(Basis(), Vector3(sx * (w * 0.5 - 0.01), h * 0.5, 0)), Vector3(0.02, h, d), "bois_clair", 1.0)
	k.col_box(xf * Transform3D(Basis(), Vector3(0, h * 0.5, 0)), Vector3(w, h, d))
	R.reserve(x, z, w + 0.2, d + 0.2)


## La caisse que porte le porteur (un nœud sur le corps ; il ne la porte qu'à l'aller).
static func _reserve_porte_caisse(f: Node) -> Node3D:
	var n := Node3D.new()
	f.npc.add_child(n)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.82, 0.68, 0.5)
	m.roughness = 0.9
	L._mesh(n, I._boxm(Vector3(0.5, 0.3, 0.38)), m, Transform3D(Basis(), Vector3(0.0, 1.0, 0.32)))
	var m2 := StandardMaterial3D.new()
	m2.albedo_color = Color(0.75, 0.12, 0.1)
	m2.roughness = 0.4
	for a in range(3):
		L._mesh(n, I._sph(0.05), m2, Transform3D(Basis(), Vector3(-0.14 + a * 0.14, 1.17, 0.32)))
	return n


## De petites particules qui montent (les bulles de l'aquarium, la brume fraîche de la Chambre des Semences).
static func _reserve_bulles(M, at: Vector3, ext: Vector3, n: int, vitesse: float, taille: float, vie: float, c: Color) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = n
	p.lifetime = vie
	p.preprocess = vie
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = ext
	p.direction = Vector3.UP
	p.spread = 12.0
	p.gravity = Vector3(0, vitesse * 0.2, 0)
	p.initial_velocity_min = vitesse * 0.8
	p.initial_velocity_max = vitesse * 1.2
	p.scale_amount_min = taille * 0.6
	p.scale_amount_max = taille * 1.4
	var qm := QuadMesh.new()
	qm.size = Vector2.ONE
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.billboard_keep_scale = true
	m.albedo_color = c
	m.albedo_texture = M.R.dot_texture()
	qm.material = m
	p.mesh = qm
	M.room.add_child(p)
	p.global_position = at
	return p


## Une affiche ou une enseigne (une image qui luit un peu) : xf = son centre ; elle regarde +Z.
static func _reserve_affiche(M, xf: Transform3D, size: Vector2, tex: String, e: float = 0.35) -> MeshInstance3D:
	var key: String = "reserve119_tex_" + tex
	if not M.ctx.has("mats116"):
		M.ctx["mats116"] = {}
	var cache: Dictionary = M.ctx["mats116"]
	var m: StandardMaterial3D = null
	if cache.has(key):
		m = cache[key]
	else:
		m = StandardMaterial3D.new()
		var p: String = "res://assets/textures/" + tex
		if ResourceLoader.exists(p):
			var t: Texture2D = load(p)
			m.albedo_texture = t
			m.emission_enabled = true
			m.emission_texture = t
			m.emission = Color(1, 1, 1)
			m.emission_energy_multiplier = e
		else:
			m.albedo_color = Color(0.85, 0.9, 0.95)
		m.roughness = 0.5
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


# =================================================================== la Chambre des Semences

const SEMENCES_TIROIRS := ["Tiroir « Salicorne, récolte du printemps ». Des graines minuscules, grises, qui sentent un peu la mer. Josette en attend déjà la soupe.",
	"Tiroir « Fraises des Lampes ». Les graines sont si petites qu'on les compte à la loupe. Quelqu'un a écrit dessous : « Ne pas éternuer. »",
	"Tiroir « Graines d'en haut, de la part de Flora ». Elles sont enveloppées dans une feuille qui sent le soleil. L'une d'elles a déjà germé dans l'enveloppe. Elle était pressée.",
	"Tiroir « Spores des Strates, de la part de Bertille ». Une poudre bleue qui luit un peu dans le noir. Sur l'étiquette : « À garder fermé. Elles aiment le noir. »",
	"Tiroir « Pépins de mandarine ». Chacun dans sa petite case. L'étiquette dit : « Pour le Verger des Lampes. Un pépin, un arbre, une joue rose. »",
	"Tiroir « Graines inconnues ». Personne ne sait ce qu'elles donneront. C'est le tiroir préféré de Mélisande."]
const SEMENCES_LETTRES := ["Une lettre de Flora, aux Nuées : « Chère Mélisande, ici, il y a tant de soleil que mes tournesols ont pris des lunettes. Je t'envoie des graines de fraises géantes. Plante-les loin de la lampe : elles poussent si vite qu'elles vont la toucher. Ta Flora, d'en haut. »",
	"Une lettre de Bertille, aux Strates : « Chère Mélisande, mes champignons brillent, ma cave est douce, et je t'envoie des spores qui aiment le noir. Garde-les dans un tiroir fermé et dis-leur bonsoir. Ta Bertille, d'en dessous. Enfin, d'au-dessus de toi. Tout est relatif. »",
	"Un brouillon de Mélisande, plein de ratures : « Chères Flora et Bertille, les trois jardinières, c'est nous : celle qui a trop de soleil, celle qui n'en a pas, et celle qui l'allume avec un bouton. Un jour, on plantera une graine ensemble, sous le vrai soleil. Je n'ose pas encore. Bientôt. »"]
const SEMENCES_GRAINE := "Sous la cloche de verre, sur un petit coussin, une graine de mandarinier, ridée et dorée. La plaque dit : « La plus ancienne graine du Dôme. Descendue avec les premiers bâtisseurs. À planter le jour où quelqu'un l'emmènera voir le soleil. » Elle a l'air de très bien savoir attendre."
const SEMENCES_ARROSER := ["Tu arroses tout doucement, rangée par rangée. Les pousses boivent, se redressent, et sous la lampe rose, elles ont l'air de te dire merci.",
	"Pschhh… Une petite pluie tombe sur les germoirs. C'est la seule pluie du fond de la mer. Les pousses en profitent, très fières.",
	"Tu verses un filet d'eau. Une pousse se redresse si vite qu'elle fait trembler sa voisine. « Tout doux, elles se réveillent », chuchote-t-on."]
const SEMENCES_PLANTER := ["Tu plantes une autre graine. Elle sort la tête, regarde la lampe rose, et décide que c'est le soleil. Elle a bien raison.",
	"Un trou, une graine, un peu d'eau, un bonjour. La pousse arrive aussitôt. Ici, on dit que les graines poussent plus vite quand on leur parle. Tu as parlé.",
	"Tu enfonces la graine du bout du doigt et tu lui souhaites bonne chance. Une feuille minuscule se déplie. Elle a l'air de trouver la mer très bien."]
## Les tiroirs qui s'ouvrent (colonne, rangée) dans le grand meuble à graines.
const SEMENCES_MOBILES := [[4, 3], [7, 2], [2, 4], [5, 2], [9, 3], [1, 3]]


## La Chambre des Semences des Serres, chez Mélisande Varech : une pièce fraîche (une brume froide au ras
## du sol), le grand meuble aux tiroirs de graines étiquetés du sol au plafond et son échelle, les germoirs
## sous les lampes roses (violettes la nuit), l'établi aux fioles de petites pousses et le pot où l'on
## plante, la plus ancienne graine du Dôme sous sa cloche de verre, les lettres de Flora et de Bertille
## (« les trois jardinières ») ; Mélisande, une cultivatrice et un apprenti le jour, la veilleuse la nuit.
static func _semences(M) -> void:
	var R = M.R
	var k = R.kit
	var nuit: bool = L._nuit(M)
	var room0 = M.room
	var rng: RandomNumberGenerator = L._r(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var o: Node3D = I._node(M, R.P(0, 0, 0))          # un repère : en local, les coordonnées de la pièce
	var rose: StandardMaterial3D = L._m(M, "semences119_rose_n" if nuit else "semences119_rose", Color(0.65, 0.38, 1.0) if nuit else Color(1.0, 0.45, 0.75), 0.4, 0.0, 2.0)
	var vert: StandardMaterial3D = L._m(M, "semences119_vert", Color(0.4, 0.8, 0.35), 0.7, 0.0, 0.05, true)
	var tige: StandardMaterial3D = L._m(M, "semences119_tige", Color(0.55, 0.8, 0.45), 0.7)
	# ---------------------------------------------------------------- le grand meuble aux tiroirs (le mur du fond)
	var cx0: float = -hw + 0.15
	var cx1: float = 1.15
	var cw: float = cx1 - cx0
	var cz: float = -hd + 0.23
	k.box(R.L((cx0 + cx1) * 0.5, 1.36, cz), Vector3(cw, 2.72, 0.44), "ceramique", 1.0)
	k.col_box(R.L((cx0 + cx1) * 0.5, 1.36, cz), Vector3(cw, 2.72, 0.44))
	R.reserve((cx0 + cx1) * 0.5, cz, cw + 0.1, 0.6)
	var cols: int = 12
	var rows: int = 8
	var dw: float = cw / cols
	var dh: float = 2.56 / rows
	var zf: float = cz + 0.23
	var mobiles: Dictionary = {}
	for e in SEMENCES_MOBILES:
		mobiles["%d_%d" % [int(e[0]), int(e[1])]] = true
	var bois_clair: Material = R.mat("bois_clair")
	var papier: Material = R.mat("papier")
	var cuivre: Material = R.mat("cuivre")
	var tiroirs: Array = []
	for r in range(rows):
		var y: float = 0.1 + dh * (r + 0.5)
		for c in range(cols):
			var x: float = cx0 + dw * (c + 0.5)
			if mobiles.has("%d_%d" % [c, r]):
				continue
			k.box(R.L(x, y, zf), Vector3(dw - 0.03, dh - 0.03, 0.02), "bois_clair", 1.0)
			k.box(R.L(x, y + 0.05, zf + 0.012), Vector3(dw * 0.5, 0.06, 0.004), "papier", 1.0)
			k.box(R.L(x, y - 0.06, zf + 0.015), Vector3(0.05, 0.018, 0.02), "cuivre", 1.0)
	var graines_mat: StandardMaterial3D = L._m(M, "semences119_graines", Color(0.62, 0.5, 0.32), 0.9)
	for e2 in SEMENCES_MOBILES:
		var c2: int = int(e2[0])
		var r2: int = int(e2[1])
		var tn: Node3D = I._node(M, R.P(cx0 + dw * (c2 + 0.5), 0.1 + dh * (r2 + 0.5), zf))
		L._mesh(tn, I._boxm(Vector3(dw - 0.03, dh - 0.03, 0.02)), bois_clair)
		L._mesh(tn, I._boxm(Vector3(dw * 0.5, 0.06, 0.004)), papier, Transform3D(Basis(), Vector3(0, 0.05, 0.012)))
		L._mesh(tn, I._boxm(Vector3(0.05, 0.018, 0.02)), cuivre, Transform3D(Basis(), Vector3(0, -0.06, 0.015)))
		L._mesh(tn, I._boxm(Vector3(dw - 0.06, dh - 0.08, 0.34)), bois_clair, Transform3D(Basis(), Vector3(0, -0.01, -0.18)))
		for g in range(7):
			L._mesh(tn, I._sph(0.012), graines_mat, Transform3D(Basis.from_scale(Vector3(1.0, 0.6, 1.3)), Vector3(-0.1 + (g % 4) * 0.065, dh * 0.5 - 0.06, -0.08 - floori(g / 4.0) * 0.08)))
		tn.set_meta("z0", tn.position.z)
		tiroirs.append(tn)
	# l'échelle, appuyée contre le meuble
	var argent: Material = R.mat("argent")
	for sx in [-1.0, 1.0]:
		_reserve_tige(o, Vector3(0.75 + sx * 0.2, 0.0, -hd + 0.95), Vector3(0.75 + sx * 0.2, 2.62, zf + 0.02), 0.018, argent)
	for rg in range(8):
		var t2: float = (rg + 0.5) / 8.0
		var rp: Vector3 = Vector3(0.75, 0.0, -hd + 0.95).lerp(Vector3(0.75, 2.62, zf + 0.02), t2)
		L._mesh(o, L._cylm(0.012, 0.012, 0.4, 6), argent, Transform3D(Basis(Vector3.BACK, PI * 0.5), rp))
	k.col_box(R.L(0.75, 0.6, -hd + 0.75), Vector3(0.45, 1.2, 0.3))
	R.reserve(0.75, -hd + 0.8, 0.6, 0.5)
	_diodes(M, Vector3(cx0, R.H - 0.04, zf + 0.03), Vector3(cx1, R.H - 0.04, zf + 0.03))
	# ---------------------------------------------------------------- la plus ancienne graine du Dôme, sous sa cloche (au fond, à droite)
	var gp := Vector2(2.35, -2.0)
	k.cyl(R.L(gp.x, 0, gp.y), 0.26, 0.3, 0.06, "argent", 20)
	k.cyl(R.L(gp.x, 0.06, gp.y), 0.17, 0.2, 0.94, "ceramique", 20)
	k.cyl(R.L(gp.x, 1.0, gp.y), 0.24, 0.22, 0.05, "argent", 20)
	k.ring(R.L(gp.x, 1.05, gp.y), 0.15, 0.17, 0.012, "lumiere", 24)
	k.cyl(R.L(gp.x, 1.05, gp.y), 0.08, 0.09, 0.04, "tissu_vert", 14)
	k.box(R.L(gp.x, 0.78, gp.y + 0.19) * Transform3D(Basis(Vector3.RIGHT, -0.2), Vector3.ZERO), Vector3(0.2, 0.08, 0.01), "cuivre", 1.0)
	k.col_cyl(R.P(gp.x, 0, gp.y), 0.3, 1.35)
	R.reserve(gp.x, gp.y, 0.8, 0.8)
	var or_graine: StandardMaterial3D = L._m(M, "semences119_graine", Color(0.9, 0.65, 0.3), 0.5, 0.2, 0.4)
	var graine: Node3D = I._node(M, R.P(gp.x, 1.12, gp.y))
	L._mesh(graine, I._sph(0.02), or_graine, Transform3D(Basis.from_scale(Vector3(1.0, 0.75, 1.5)), Vector3.ZERO))
	L._tourne(M, graine, Vector3.UP, 0.25)
	var verre: StandardMaterial3D = L._m(M, "semences119_cloche", Color(0.88, 0.96, 1.0, 0.18), 0.03, 0.0, 0.0, true)
	var cn: Node3D = I._node(M, R.P(gp.x, 1.05, gp.y))
	L._mesh(cn, L._cylm(0.15, 0.15, 0.2, 24, false), verre, Transform3D(Basis(), Vector3(0, 0.1, 0)))
	var calotte := SphereMesh.new()
	calotte.radius = 0.15
	calotte.height = 0.15
	calotte.is_hemisphere = true
	calotte.radial_segments = 24
	calotte.rings = 8
	L._mesh(cn, calotte, verre, Transform3D(Basis(), Vector3(0, 0.2, 0)))
	L._mesh(cn, I._sph(0.022), argent, Transform3D(Basis(), Vector3(0, 0.36, 0)))
	L._lampe(M, R.P(gp.x, 1.7, gp.y + 0.3), Color(1.0, 0.85, 0.6), 0.45, 1.8)
	M.ctx["graine119"] = 0.0
	# ---------------------------------------------------------------- les lettres des trois jardinières (mur de droite) et le petit bureau
	var lb: Transform3D = R.L(hw - 0.03, 1.55, -0.4, -90)
	k.box(lb, Vector3(1.3, 0.85, 0.03), "argent", 1.0)
	k.box(lb * Transform3D(Basis(), Vector3(0, 0, 0.018)), Vector3(1.22, 0.77, 0.01), "carton", 1.0)
	for le in [[-0.38, 0.08, 0.08], [0.0, 0.1, -0.05], [0.38, 0.06, 0.1]]:
		var lt: Transform3D = lb * Transform3D(Basis(Vector3.BACK, float(le[2])), Vector3(float(le[0]), float(le[1]), 0.026))
		k.box(lt, Vector3(0.28, 0.4, 0.004), "papier", 1.0)
		for li in range(5):
			k.box(lt * Transform3D(Basis(), Vector3(-0.01 * (li % 2), 0.12 - li * 0.06, 0.003)), Vector3(0.2 - (li % 3) * 0.03, 0.008, 0.002), "tissu_bleu", 1.0)
		k.box(lt * Transform3D(Basis(), Vector3(0, 0.18, 0.006)), Vector3(0.02, 0.02, 0.01), "tissu_rouge", 1.0)
	# la petite image des trois jardinières : trois silhouettes, verte, rose et brune
	var ph: Transform3D = lb * Transform3D(Basis(Vector3.BACK, 0.04), Vector3(-0.05, -0.26, 0.026))
	k.box(ph, Vector3(0.3, 0.17, 0.004), "tissu_blanc", 1.0)
	for pj in range(3):
		var col: String = ["tissu_vert", "tissu_rose", "tissu_brun"][pj]
		k.box(ph * Transform3D(Basis(), Vector3(-0.08 + pj * 0.08, -0.025, 0.003)), Vector3(0.035, 0.07, 0.002), col, 1.0)
		k.box(ph * Transform3D(Basis(), Vector3(-0.08 + pj * 0.08, 0.035, 0.003)), Vector3(0.025, 0.025, 0.002), col, 1.0)
	k.box(lb * Transform3D(Basis(Vector3.BACK, 0.5), Vector3(0.38, -0.26, 0.026)), Vector3(0.04, 0.12, 0.004), "feuillage", 1.0)
	R.mark_wall(hw, 1.55, -0.4, 0.7)
	R.etagere_murale(hw - 0.13, 2.3, -0.4, -90, 1.1, "verre", 6)
	var bu: Transform3D = R.L(hw - 0.3, 0, -0.4)
	k.box(bu * Transform3D(Basis(), Vector3(0, 0.76, 0)), Vector3(0.5, 0.04, 1.0), "ceramique", 1.0)
	for sz in [-1.0, 1.0]:
		k.box(bu * Transform3D(Basis(), Vector3(0, 0.37, sz * 0.46)), Vector3(0.46, 0.74, 0.04), "argent", 1.0)
	for en in range(4):
		k.box(bu * Transform3D(Basis(Vector3.UP, 0.2 * (en - 1.5)), Vector3(-0.05, 0.785 + en * 0.006, -0.22 + (en % 2) * 0.05)), Vector3(0.16, 0.005, 0.11), "papier" if en % 2 == 0 else "tissu_creme", 1.0)
	k.box(bu * Transform3D(Basis(Vector3.UP, 0.4), Vector3(0.0, 0.79, 0.2)), Vector3(0.012, 0.012, 0.16), "noir", 1.0)
	k.col_box(bu * Transform3D(Basis(), Vector3(0, 0.4, 0)), Vector3(0.5, 0.8, 1.0))
	R.reserve(hw - 0.3, -0.4, 0.7, 1.2)
	# ---------------------------------------------------------------- les germoirs sous les lampes roses (mur de gauche)
	var gx: float = -hw + 0.42
	var gz0: float = -1.95
	var gz1: float = 0.55
	var gl: float = gz1 - gz0
	var gzm: float = (gz0 + gz1) * 0.5
	k.box(R.L(gx, 0.8, gzm), Vector3(0.7, 0.05, gl), "ceramique", 1.0)
	k.box(R.L(gx + 0.02, 0.4, gzm), Vector3(0.62, 0.76, gl - 0.08), "ceramique", 1.0)
	k.box(R.L(gx + 0.335, 0.05, gzm), Vector3(0.01, 0.1, gl - 0.1), "argent", 1.0)
	k.col_box(R.L(gx, 0.42, gzm), Vector3(0.7, 0.85, gl))
	R.reserve(gx, gzm, 0.9, gl + 0.2)
	var plateaux: Array = []
	for ti in range(4):
		var tz: float = gz0 + 0.33 + ti * 0.56
		k.box(R.L(gx, 0.86, tz), Vector3(0.56, 0.07, 0.5), "noir", 1.0)
		k.box(R.L(gx, 0.88, tz), Vector3(0.52, 0.05, 0.46), "terreau", 1.0)
		var pt: Node3D = I._node(M, R.P(gx, 0.905, tz))
		var haut: float = rng.randf_range(0.6, 1.0)
		for sp in range(12):
			var sp_p := Vector3(-0.18 + (sp % 4) * 0.12, 0, -0.15 + floori(sp / 4.0) * 0.15)
			L._mesh(pt, L._cylm(0.003, 0.004, 0.06, 4), tige, Transform3D(Basis(), sp_p + Vector3(0, 0.03, 0)))
			for fl in [-1.0, 1.0]:
				L._mesh(pt, I._boxm(Vector3(0.028, 0.003, 0.014)), vert, Transform3D(Basis(Vector3.UP, sp * 0.7) * Basis(Vector3.BACK, fl * 0.35), sp_p + Vector3(fl * 0.014, 0.06, 0)))
		pt.scale = Vector3(1.0, haut, 1.0)
		pt.set_meta("haut", haut)
		plateaux.append(pt)
	# les lampes roses, pendues au plafond
	for lz in [gzm - 0.62, gzm + 0.62]:
		k.box(R.L(gx, 1.8, lz), Vector3(0.18, 0.05, 1.15), "argent", 1.0)
		for cz2 in [-0.5, 0.5]:
			k.cyl(R.L(gx, 1.82, lz + cz2), 0.006, 0.006, R.H - 1.82, "argent", 4, false)
		L._mesh(I._node(M, R.P(gx, 1.77, lz)), I._boxm(Vector3(0.12, 0.02, 1.1)), rose)
	var lampes: Array = []
	for lz2 in [gzm - 0.62, gzm + 0.62]:
		lampes.append(L._lampe(M, R.P(gx + 0.1, 1.5, lz2), Color(0.7, 0.45, 1.0) if nuit else Color(1.0, 0.5, 0.78), 0.4 if nuit else 0.75, 2.6))
	var brume: CPUParticles3D = _reserve_bulles(M, R.P(gx, 0.95, gzm), Vector3(0.25, 0.03, gl * 0.45), 16, 0.04, 0.09, 3.5, Color(1, 1, 1, 0.3))
	# l'arrosoir, au bout des germoirs
	var arro: Node3D = I._node(M, R.P(gx + 0.12, 0.825, gz1 - 0.15))
	var zinc: StandardMaterial3D = L._m(M, "semences119_arrosoir", Color(0.55, 0.82, 0.78), 0.35, 0.5)
	L._mesh(arro, L._cylm(0.07, 0.08, 0.16, 16), zinc, Transform3D(Basis(), Vector3(0, 0.08, 0)))
	_reserve_tige(arro, Vector3(0.06, 0.06, 0), Vector3(0.19, 0.2, 0), 0.012, zinc)
	L._mesh(arro, L._cylm(0.03, 0.014, 0.03, 10), zinc, Transform3D(Basis(Vector3.BACK, -0.75), Vector3(0.2, 0.21, 0)))
	L._mesh(arro, L._tore(0.045, 0.06), zinc, Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(-0.03, 0.17, 0)))
	# ---------------------------------------------------------------- l'établi du milieu : les fioles de petites pousses, le pot où l'on plante
	var et: Transform3D = R.L(0.4, 0, -0.5)
	k.box(et * Transform3D(Basis(), Vector3(0, 0.84, 0)), Vector3(1.4, 0.04, 0.75), "ceramique", 1.0)
	for s7 in [-1.0, 1.0]:
		for s8 in [-1.0, 1.0]:
			k.box(et * Transform3D(Basis(), Vector3(s7 * 0.64, 0.41, s8 * 0.32)), Vector3(0.04, 0.82, 0.04), "argent", 1.0)
	k.box(et * Transform3D(Basis(), Vector3(0, 0.2, 0)), Vector3(1.3, 0.03, 0.66), "bois_clair", 1.0)
	k.col_box(et * Transform3D(Basis(), Vector3(0, 0.43, 0)), Vector3(1.4, 0.86, 0.75))
	R.reserve(0.4, -0.5, 1.6, 1.0)
	for sk in range(3):
		k.box(et * Transform3D(Basis(Vector3.UP, 0.1 * sk), Vector3(-0.5 + sk * 0.07, 0.235, 0.05)), Vector3(0.25, 0.04, 0.2), "papier" if sk != 1 else "tissu_creme", 1.0)
	k.box(et * Transform3D(Basis(), Vector3(-0.15, 0.875, -0.18)), Vector3(0.55, 0.03, 0.12), "argent", 1.0)
	var eau: StandardMaterial3D = L._m(M, "semences119_eau", Color(0.6, 0.85, 1.0, 0.35), 0.1)
	var fioles: Array = []
	for fi in range(6):
		var fx: float = 0.4 - 0.38 + fi * 0.09
		var fz: float = -0.5 - 0.18
		k.cyl(R.L(fx, 0.89, fz), 0.02, 0.02, 0.16, "verre", 10, false)
		L._mesh(o, L._cylm(0.017, 0.017, 0.08, 10), eau, Transform3D(Basis(), Vector3(fx, 0.93, fz)))
		var fn: Node3D = I._node(M, R.P(fx, 0.9, fz))
		L._mesh(fn, L._cylm(0.002, 0.003, 0.15, 4), tige, Transform3D(Basis(), Vector3(0, 0.075, 0)))
		for fl2 in [-1.0, 1.0]:
			L._mesh(fn, I._boxm(Vector3(0.03, 0.003, 0.015)), vert, Transform3D(Basis(Vector3.UP, fi * 0.9) * Basis(Vector3.BACK, fl2 * 0.4), Vector3(fl2 * 0.015, 0.15 + fi % 2 * 0.02, 0)))
		fioles.append(fn)
	var pot := Vector2(0.95, -0.38)
	k.cyl(R.L(pot.x, 0.86, pot.y), 0.08, 0.105, 0.14, "ceramique", 16)
	k.cyl(R.L(pot.x, 0.995, pot.y), 0.098, 0.098, 0.01, "terreau", 16)
	var pousse: Node3D = I._node(M, R.P(pot.x, 1.005, pot.y))
	L._mesh(pousse, L._cylm(0.004, 0.006, 0.12, 5), tige, Transform3D(Basis(), Vector3(0, 0.06, 0)))
	for fl3 in [-1.0, 1.0]:
		L._mesh(pousse, I._boxm(Vector3(0.05, 0.004, 0.025)), vert, Transform3D(Basis(Vector3.BACK, fl3 * 0.3), Vector3(fl3 * 0.025, 0.12, 0)))
	pousse.scale = Vector3.ONE * 0.01
	pousse.visible = false
	k.box(et * Transform3D(Basis(Vector3.UP, 0.5), Vector3(0.25, 0.87, 0.18)), Vector3(0.12, 0.02, 0.05), "argent", 1.0)
	k.box(et * Transform3D(Basis(Vector3.UP, 0.5), Vector3(0.36, 0.875, 0.24)), Vector3(0.1, 0.025, 0.03), "bois", 1.0)
	k.box(et * Transform3D(Basis(Vector3.UP, -0.2), Vector3(0.2, 0.87, -0.05)), Vector3(0.1, 0.02, 0.14), "tissu_vert", 1.0)
	# ---------------------------------------------------------------- l'enseigne des Serres (mur de l'entrée), un mandarinier en pot
	k.box(R.L(-2.2, 1.8, hd - 0.02, 180), Vector3(0.62, 0.62, 0.02), "argent", 1.0)
	_reserve_affiche(M, R.L(-2.2, 1.8, hd - 0.035, 180), Vector2(0.56, 0.56), "dome115/enseigne_serres.png")
	R.mark_wall(-2.2, 1.8, hd, 0.35)
	R.plante(2.9, 0.75, 0.0, 1.5)
	var mandarine: StandardMaterial3D = L._m(M, "semences119_mandarine", Color(1.0, 0.55, 0.12), 0.5)
	for mi in range(5):
		var ma: float = TAU * mi / 5.0 + 0.4
		L._mesh(o, I._sph(0.035), mandarine, Transform3D(Basis(), Vector3(2.9 + cos(ma) * 0.2, 0.75 + (mi % 3) * 0.12, 0.75 + sin(ma) * 0.2)))
	# la fraîcheur : une brume froide au ras du sol, une lumière bleutée
	_reserve_bulles(M, R.P(-0.6, 0.06, -1.9), Vector3(2.2, 0.03, 0.3), 14, 0.03, 0.14, 4.0, Color(0.85, 0.95, 1.0, 0.22))
	L._lampe(M, R.P(0.4, 2.3, -0.8), Color(0.82, 0.92, 1.0), 0.3 if nuit else 0.55, 5.0)
	# ---------------------------------------------------------------- ce qui bouge : les lampes roses, les pousses, la graine
	M.ctx["pousse119"] = 1.0
	M.ctx["rose119"] = 0.0
	L._chaque(M, func(delta: float, t: float) -> void:
		var flash: float = maxf(0.0, float(M.ctx.get("rose119", 0.0)) - delta)
		M.ctx["rose119"] = flash
		var puls: float = 0.5 + 0.5 * sin(t * 0.6)
		rose.emission_energy_multiplier = (1.2 if nuit else 1.8) + 0.4 * puls + flash
		for lp in lampes:
			if is_instance_valid(lp):
				(lp as OmniLight3D).light_energy = (0.35 if nuit else 0.65) + 0.12 * puls + flash * 0.4
		var gr: float = maxf(0.0, float(M.ctx.get("graine119", 0.0)) - delta * 0.5)
		M.ctx["graine119"] = gr
		or_graine.emission_energy_multiplier = 0.35 + 0.25 * pow(maxf(0.0, sin(t * 0.7)), 3.0) + gr * 2.0
		var croit: float = float(M.ctx.get("pousse119", 1.0))
		for i3 in range(plateaux.size()):
			var pt2: Node3D = plateaux[i3]
			if is_instance_valid(pt2):
				pt2.rotation.z = sin(t * 0.8 + i3 * 1.3) * 0.03
				var cible: float = float(pt2.get_meta("haut", 1.0)) * croit
				pt2.scale.y = lerpf(pt2.scale.y, cible, minf(1.0, delta * 1.5))
		for i4 in range(fioles.size()):
			var fn2: Node3D = fioles[i4]
			if is_instance_valid(fn2):
				fn2.rotation.z = sin(t * 1.1 + i4) * 0.06)
	# ---------------------------------------------------------------- les gens
	if nuit:
		var veil: Node = L._gens(M, "femme", -1.6, 0.75, 90.0, "marcher", ["Treize degrés, l'eau des germoirs à niveau. Les graines dorment, les germoirs veillent, et moi aussi.",
			"La nuit, les lampes passent au violet. Mélisande dit que c'est la berceuse des pousses."])
		L._va_et_vient(M, veil, R.P(-1.6, 0, 0.75), R.P(1.9, 0, 0.75), 0.5, 4.0)
		L._causer(M, veil, ["Bonsoir ! Chut… je fais la ronde de nuit des Serres. Ici, je vérifie le froid et les germoirs.", "Bonnes bulles ! Mélisande est rentrée chez elle. Elle a éteint les lampes une par une, sauf celles des germoirs."],
			[["ronde", "Que surveilles-tu, la nuit ?", ["Le froid de la chambre, l'eau des germoirs, et la graine sous la cloche. Elle ne bouge jamais, bien sûr. Mais tout le Dôme dort mieux en sachant que quelqu'un la regarde."]],
			["melisande", "Où est Mélisande ?", ["Chez elle, au fond du Verger des Lampes. Avant de partir, elle dit bonne nuit à chaque germoir. Parfois, elle revient en chaussons pour vérifier la petite pousse qui a peur du noir."]]])
		M.ctx["entree"] = "La Chambre des Semences, la nuit : les lampes des germoirs sont passées au violet, la graine sous sa cloche luit tout doucement, et les tiroirs dorment, bien rangés."
	else:
		var meli: Node = M.person("femme", -2.35, -1.1, -90.0, "jardiner", "Mélisande Varech")
		meli.lines = ["Tout doux, elles se réveillent… Bonjour, mes petites. Vous avez bien dormi sous la lampe ?",
			"Celle-ci a germé cette nuit. Je l'appelle Petite Bertille. Elle pousse dans le coin le plus sombre, comme la vraie."]
		L._causer(M, meli, ["Oh… bonjour. Parle doucement, s'il te plaît : les germoirs viennent de se réveiller, et les pousses écoutent. Bienvenue dans la Chambre des Semences.", "Bonnes bulles… Tu as froid ? C'est normal : ici, il fait frais, pour que les graines dorment bien. Elles attendent leur tour."],
			[["jardinieres", "Qui sont les trois jardinières ?", ["Flora Verdine, aux Nuées, qui a trop de soleil. Bertille Champignac, aux Strates, qui n'en a pas du tout. Et moi, qui allume le mien avec un bouton. On s'écrit, on s'échange des graines. Leurs lettres sont là, au mur. Je les relis quand les lampes grésillent."]],
			["ancienne", "Et la graine sous la cloche ?", ["La plus ancienne graine du Dôme : une graine de mandarinier, descendue avec les premiers bâtisseurs. Personne ne l'a jamais plantée. Ma mère disait qu'on la garde pour le jour où quelqu'un l'emmènera pousser sous le vrai soleil. Je crois que ce jour approche. Doucement."]],
			["lampes", "Pourquoi les lampes sont-elles roses ?", ["Les plantes n'aiment que le rouge et le bleu de la lumière. Mélangés, ça fait du rose. Les gens d'en haut trouvent ça étrange. Les pousses, elles, trouvent ça très normal : elles n'ont jamais rien vu d'autre. Comme moi, avec le ciel."]],
			["tiroirs", "Combien y a-t-il de graines, ici ?", ["Personne ne sait. Chaque tiroir a son étiquette, mais certaines graines se glissent dans le tiroir d'à côté pour ne pas être seules. Je les laisse faire. Les graines aussi ont besoin d'amies."]]])
		var cult: Node = L._gens(M, "femme", 0.05, -1.8, 180.0, "observer", ["Tiroir quarante-deux : salicorne. Tiroir quarante-trois : salicorne aussi. Josette en veut beaucoup.",
			"Je range les graines arrivées d'en haut. Celles de Flora sont si pressées qu'elles germent dans l'enveloppe."])
		L._causer(M, cult, ["Bonnes bulles ! Je fais l'inventaire des tiroirs. C'est long, mais ça sent bon la terre sèche.", "Bonjour ! Attention à l'échelle : elle roule toute seule quand on la regarde de travers."],
			[["haut", "Des graines arrivent d'en haut ?", ["Depuis que la Ligne a rouvert, oui ! Des pépins de pomme de Hautefond, des spores des Strates, des graines de fraises géantes des Nuées. On leur trouve une lampe, un tiroir, et beaucoup de patience."]]])
		var app: Node = L._gens(M, "garcon", 0.75, -1.2, 0.0, "bricoler", ["Une graine, un trou, un peu d'eau, un bonjour. Mélisande dit que le bonjour, c'est le plus important.",
			"J'ai planté trente graines ce matin. Vingt-neuf ont dit bonjour. La dernière est timide."])
		L._causer(M, app, ["Salut ! Tu veux planter une graine ? Le pot est prêt, il n'attend que toi.", "Bonnes bulles ! Attention aux fioles : les pousses dedans sont toutes petites, mais elles ont beaucoup de caractère."],
			[["fioles", "Qu'y a-t-il dans les fioles ?", ["Des pousses qui ont germé trop tôt ! On les garde dans l'eau, sous la lampe, le temps qu'elles prennent des forces. Après, elles vont dans les tours des Serres. Celle-ci, c'est une fraise. Elle ne le sait pas encore."]]])
		M.ctx["entree"] = str(L._pick(M, ["La Chambre des Semences : une pièce fraîche, des tiroirs de graines étiquetés du sol au plafond, et des germoirs qui se réveillent sous des lampes roses.",
			"Il fait frais, ça sent la terre sèche et la feuille neuve. Au fond, sous une cloche de verre, une seule graine luit doucement : la plus ancienne du Dôme.",
			"Des centaines de petits tiroirs, des fioles où trempent des pousses minuscules, et sous les lampes roses, des rangées de germes qui s'étirent. Ici, tout le monde parle bas."]))
	# ---------------------------------------------------------------- ce qu'on fait : arroser, ouvrir un tiroir, planter, lire les lettres, regarder la graine
	M.act(R.P(gx + 0.7, 1.0, gz1 - 0.3), "E : arroser les germoirs", func() -> void:
		if bool(M.ctx.get("arrose119", false)):
			return
		M.ctx["arrose119"] = true
		M.main.sfx("verser", R.P(gx, 1.0, gzm))
		if is_instance_valid(arro):
			var tw: Tween = M.room.create_tween()
			tw.tween_property(arro, "rotation:z", -0.6, 0.6).set_trans(Tween.TRANS_SINE)
			tw.tween_interval(1.4)
			tw.tween_property(arro, "rotation:z", 0.0, 0.6).set_trans(Tween.TRANS_SINE)
		if is_instance_valid(brume):
			brume.amount = 40
		M.ctx["rose119"] = 1.5
		M.ctx["pousse119"] = minf(1.45, float(M.ctx.get("pousse119", 1.0)) + 0.15)
		M.say(str(L._pick(M, SEMENCES_ARROSER)), 6.0)
		await M.get_tree().create_timer(3.0).timeout
		if not _la(M, room0):
			return
		if is_instance_valid(brume):
			brume.amount = 16
		M.ctx["arrose119"] = false
	, 1.3)
	M.act(R.P(-1.5, 1.2, -1.75), "E : ouvrir un tiroir", func() -> void:
		var n: int = int(M.ctx.get("tiroir119", rng.randi() % SEMENCES_TIROIRS.size()))
		M.ctx["tiroir119"] = n + 1
		var tn2: Node3D = tiroirs[n % tiroirs.size()]
		M.main.sfx("touche_bois", R.P(-1.1, 1.2, zf))
		if is_instance_valid(tn2) and not bool(tn2.get_meta("ouvert", false)):
			tn2.set_meta("ouvert", true)
			var z0: float = float(tn2.get_meta("z0", tn2.position.z))
			var tw2: Tween = M.room.create_tween()
			tw2.tween_property(tn2, "position:z", z0 + 0.28, 0.5).set_trans(Tween.TRANS_SINE)
			tw2.tween_interval(4.0)
			tw2.tween_property(tn2, "position:z", z0, 0.5).set_trans(Tween.TRANS_SINE)
			tw2.tween_callback(func() -> void:
				if is_instance_valid(tn2):
					tn2.set_meta("ouvert", false))
		M.say(str(SEMENCES_TIROIRS[n % SEMENCES_TIROIRS.size()]), 7.0)
	, 1.5)
	M.act(R.P(pot.x, 1.0, pot.y + 0.55), "E : planter une graine", func() -> void:
		if bool(M.ctx.get("plante119", false)):
			return
		M.ctx["plante119"] = true
		M.main.sfx("ramasse", R.P(pot.x, 1.0, pot.y))
		if is_instance_valid(pousse):
			pousse.visible = true
			pousse.scale = Vector3.ONE * 0.01
			var tw3: Tween = M.room.create_tween()
			tw3.tween_interval(0.6)
			tw3.tween_property(pousse, "scale", Vector3.ONE * 1.1, 1.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw3.tween_property(pousse, "scale", Vector3.ONE, 0.4)
		var st: Dictionary = M.state()
		if not bool(st.get("graine_semences119", false)):
			st["graine_semences119"] = true
			for f in M.people:
				if is_instance_valid(f) and f.has_method("gesture"):
					f.gesture("joie", 2.0)
			M.give([["graines", 2]], "Tu creuses un petit trou du bout du doigt, tu poses une graine, tu la couvres, tu lui dis bonjour. Sous la lampe, une minuscule pousse sort déjà la tête. « Elle t'a entendu », dit-on tout bas. Et pour ton jardin d'en haut, on te glisse un sachet :\n")
		else:
			M.say(str(L._pick(M, SEMENCES_PLANTER)), 6.0)
		await M.get_tree().create_timer(3.0).timeout
		if _la(M, room0):
			M.ctx["plante119"] = false
	, 1.2)
	M.act(R.P(hw - 0.85, 1.3, -0.4), "E : lire les lettres", func() -> void:
		M.main.sfx("ui_ouvrir", R.P(hw - 0.1, 1.5, -0.4))
		var n2: int = int(M.ctx.get("lettre119", 0))
		M.ctx["lettre119"] = n2 + 1
		M.say(str(SEMENCES_LETTRES[n2 % SEMENCES_LETTRES.size()]), 10.0)
	, 1.1)
	M.act(R.P(gp.x - 0.1, 1.1, gp.y + 0.6), "E : regarder la plus ancienne graine", func() -> void:
		M.main.sfx("cristal_eveil", R.P(gp.x, 1.15, gp.y))
		M.ctx["graine119"] = 1.0
		M.say(SEMENCES_GRAINE, 9.0)
	, 1.1)


# =================================================================== la Salle du Ciel

## Ce qu'on lit sur les cartes postales du Mur du Dessus (une après l'autre).
const CIEL_CARTES := ["Une carte de Hautefond : la Place de la Colonne sous un grand ciel bleu. Au dos : « Chère classe, ici le ciel est si haut qu'on n'en voit pas le bout. Je vous en garde un morceau. Philippine. »",
	"Une carte de la Cité des Nuées : des toits blancs posés sur un tapis de nuages. Au dos, une écriture ronde : « Bonjour, la classe d'en bas. Est-ce que la mer fait du bruit ? Lili. »",
	"Une carte du Phare de la Pointe, au coucher du soleil : toute la mer est rouge. Au dos, Madame Odile a écrit au crayon : « Oui, Mila, le soleil rougit vraiment. »",
	"Une carte de la Cascade des Nuées, qui tombe dans le vide et se change en nuage. Juste à côté, un petit trou : une punaise dorée a été enlevée cette semaine. Quelqu'un a vu le vrai paysage.",
	"Une carte du Grand Marché de Hautefond, un jour de pluie : des parapluies de toutes les couleurs. Au dos, un élève a écrit : « Pourquoi ils se cachent ? C'est de l'eau gratuite ! »"]
const CIEL_PLUME := ["Dans un petit pot de verre, une vraie plume d'oiseau, grise et blanche : une plume de mouette de Hautefond. L'étiquette dit : « La seule plume du Dôme. On regarde avec les yeux. Et on ne souffle pas dessus. »",
	"La plume frémit à peine quand tu t'approches. Madame Odile dit qu'elle se souvient du vent. Mila dit qu'elle a envie de repartir.",
	"Elle est descendue avec la spiruline, par la petite nacelle de service, pendant les douze ans de ligne fermée. Avec un mot : « Pour les enfants qui n'ont jamais vu d'oiseau. »"]
const CIEL_PLANETAIRE := ["Tu tournes la petite manivelle : le soleil de laiton s'allume, la Terre file sur son bras, et la Lune danse autour d'elle. « Un jour, c'est un tour de la Terre sur elle-même ; un an, un tour du soleil », récite une petite voix.",
	"Le planétaire tourne de plus en plus vite : les saisons défilent en trois secondes. « Doucement ! dit-on derrière toi. Sinon, l'été arrive avant le goûter. »",
	"La Lune tourne autour de la Terre, la Terre tourne autour du soleil, et les étoiles de laiton tournent tout autour. Tout le monde tourne autour de quelqu'un, dit Madame Odile. Même nous, autour de la Perle."]
const CIEL_SOLEIL_JOUR := ["Clic ! Le soleil peint du plafond s'allume, tout doré, et une lumière chaude tombe sur les tables. Pour un instant, la Salle du Ciel a l'air d'un vrai matin d'en haut.",
	"Tu appuies sur l'interrupteur en forme de soleil : le plafond s'illumine. « C'est ça, le soleil ? demande une petite voix. En plus grand ? En beaucoup plus grand ? »"]
const CIEL_SOLEIL_NUIT := ["Clic ! Le soleil du plafond se lève au milieu des étoiles. Ce n'est pas tout à fait juste : en haut, on ne voit pas les deux en même temps. Mais c'est très joli."]
const CIEL_ETEINDRE := ["Clic. Le soleil du plafond s'éteint doucement, comme un vrai soir. Il ne manque que le rouge. Madame Odile dit qu'elle y travaille.",
	"Tu éteins le soleil. Le ciel peint reste là, bleu et tranquille. Il n'a jamais besoin de dormir, lui."]
const CIEL_OMBELINE := "Un ciel au coucher du soleil, orange, rose et violet, au-dessus d'une ville posée sur les nuages. C'est signé « Ombeline, des Nuées ». Le premier vrai ciel de la classe. Les élèves disent qu'il ressemble à la Perle, le soir."
## Les cartes du Mur du Dessus : [image, en hauteur ?] (les autres cartes sont des aplats de couleur).
const CIEL_IMAGES := [["nuees/tableau_nuages.png", false], ["nuees/tableau_coucher.png", false], ["nuees/tableau_cascade.png", true], ["nuees/affiche_ligne.png", true]]
## La Grande Ourse du plafond, la nuit (repère de la pièce, autour de son centre).
const CIEL_OURSE := [Vector2(-1.5, 0.35), Vector2(-0.95, 0.5), Vector2(-0.45, 0.42), Vector2(0.0, 0.2), Vector2(0.15, -0.35), Vector2(0.85, -0.42), Vector2(0.8, 0.15)]


## (Pour les trois lieux de ce fichier) une image posée à plat (une carte postale, un tableau, un écran) :
## xf = son centre, elle regarde +Z ; e > 0 : elle luit.
static func _ciel_image(M, xf: Transform3D, size: Vector2, tex: String, e: float = 0.0) -> MeshInstance3D:
	if not M.ctx.has("mats116"):
		M.ctx["mats116"] = {}
	var cache: Dictionary = M.ctx["mats116"]
	var key: String = "ciel119_img_" + tex + "_" + str(int(e * 10.0))
	var m: StandardMaterial3D = cache.get(key, null)
	if m == null:
		m = StandardMaterial3D.new()
		var p: String = "res://assets/textures/" + tex
		if ResourceLoader.exists(p):
			var t: Texture2D = load(p)
			m.albedo_texture = t
			if e > 0.0:
				m.emission_enabled = true
				m.emission_texture = t
				m.emission = Color(1, 1, 1)
				m.emission_energy_multiplier = e
		else:
			m.albedo_color = Color(0.55, 0.72, 0.9)
		m.roughness = 0.6
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


## (Pour les trois lieux de ce fichier) un maillage posé n'importe où (xf : dans le monde).
static func _ciel_bloc(M, xf: Transform3D, mesh: Mesh, mat: Material) -> Node3D:
	var n: Node3D = I._node(M, xf.origin)
	n.global_transform = xf
	L._mesh(n, mesh, mat)
	return n


## Le ciel peint du plafond : le jour, un bleu plus clair vers les bords (comme vers l'horizon) ; la nuit,
## le bleu de nuit semé d'étoiles.
static func _ciel_tex_plafond(nuit: bool) -> ImageTexture:
	var img := Image.create(256, 192, false, Image.FORMAT_RGB8)
	for y in range(192):
		var t: float = absf(float(y) / 191.0 - 0.5) * 2.0
		for x in range(256):
			var u: float = absf(float(x) / 255.0 - 0.5) * 2.0
			var b: float = clampf(maxf(t, u) * 0.85 + 0.15 * t * u, 0.0, 1.0)
			var c: Color = Color(0.03, 0.05, 0.16).lerp(Color(0.08, 0.11, 0.27), b) if nuit else Color(0.3, 0.55, 0.9).lerp(Color(0.74, 0.87, 0.98), b * b)
			img.set_pixel(x, y, c)
	if nuit:
		var r := RandomNumberGenerator.new()
		r.seed = 119119
		for i in range(420):
			var s: float = r.randf_range(0.4, 1.0)
			img.set_pixel(r.randi() % 256, r.randi() % 192, Color(s, s, s * 0.92))
	return ImageTexture.create_from_image(img)


## Une chaise d'écolier (coque blanche, pieds de titane) qui regarde yaw.
static func _ciel_chaise(M, x: float, z: float, yaw: float) -> void:
	var R = M.R
	var k = R.kit
	var xf: Transform3D = R.L(x, 0, z, yaw)
	k.box(xf * Transform3D(Basis(), Vector3(0, 0.42, 0)), Vector3(0.4, 0.04, 0.38), "ceramique", 1.0)
	k.box(xf * Transform3D(Basis(Vector3.RIGHT, -0.12), Vector3(0, 0.68, -0.18)), Vector3(0.38, 0.42, 0.04), "ceramique", 1.0)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			k.box(xf * Transform3D(Basis(), Vector3(sx * 0.16, 0.21, sz * 0.15)), Vector3(0.025, 0.42, 0.025), "argent", 1.0)


## Une table d'écoliers (deux places), ses cahiers aux couvertures de couleur ; les deux chaises derrière (+Z).
static func _ciel_table(M, x: float, z: float, i: int) -> void:
	var R = M.R
	var k = R.kit
	k.box(R.L(x, 0.67, z), Vector3(1.2, 0.04, 0.5), "ceramique", 1.0)
	k.box(R.L(x, 0.6, z - 0.05), Vector3(1.1, 0.02, 0.36), "argent", 1.0)
	for sx in [-1.0, 1.0]:
		k.box(R.L(x + sx * 0.55, 0.33, z), Vector3(0.04, 0.66, 0.44), "argent", 1.0)
	k.col_box(R.L(x, 0.35, z), Vector3(1.2, 0.7, 0.5))
	var cols: Array = ["tissu_bleu", "tissu_rouge", "tissu_jaune", "tissu_vert", "tissu_turquoise", "tissu_rose"]
	for s in range(2):
		var cx: float = x - 0.3 + s * 0.6
		k.box(R.L(cx, 0.695, z + 0.04, 8.0 * ((i + s) % 3 - 1)), Vector3(0.24, 0.012, 0.32), cols[(i * 2 + s) % cols.size()], 1.0)
		k.box(R.L(cx + 0.02, 0.703, z + 0.04, 8.0 * ((i + s) % 3 - 1)), Vector3(0.2, 0.004, 0.28), "papier", 1.0)
		_ciel_chaise(M, cx, z + 0.48, 180.0)
	R.reserve(x, z + 0.2, 1.4, 1.2)


## La Salle du Ciel, à l'étage de l'École des Abysses : la classe de Madame Odile Nautile, où les enfants
## du Dôme apprennent le ciel qu'ils n'ont jamais vu. Le plafond peint en ciel (des nuages qui passent le
## jour, les étoiles et la Grande Ourse la nuit) et son soleil qu'on allume, le planétaire de laiton (le
## soleil, la Terre, la Lune, la couronne d'étoiles), le grand tableau de la Leçon de Ciel, le Mur du
## Dessus et ses cartes postales d'en haut à punaises dorées, la vraie plume d'oiseau dans son pot, le
## tableau d'Ombeline ; le jour, Madame Odile, la petite Mila et un élève (après la classe, la maman de
## Mila vient la chercher) ; le soir, l'institutrice qui range ; la nuit, le veilleur.
static func _ciel(M) -> void:
	var R = M.R
	var k = R.kit
	var nuit: bool = L._nuit(M)
	var room0 = M.room
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var h: float = float(M.ctx.get("hour", 12.0))
	var classe: bool = not nuit and h >= 8.0 and h < 16.5
	var rng: RandomNumberGenerator = L._r(M)
	# le plafond peint : tout le ciel
	var ciel := StandardMaterial3D.new()
	ciel.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ciel.albedo_texture = _ciel_tex_plafond(nuit)
	var pq := QuadMesh.new()
	pq.size = Vector2(R.W - 0.04, R.D - 0.04)
	L._mesh(I._node(M, R.P(0, R.H - 0.015, 0)), pq, ciel, Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO))
	if not nuit:
		# le jour, des nuages qui passent lentement sur le plafond (ils s'effacent au bord, et reviennent)
		var nt: Texture2D = null
		if ResourceLoader.exists("res://assets/textures/nuees/nuage.png"):
			nt = load("res://assets/textures/nuees/nuage.png")
		var nuages: Array = []
		for i in range(5):
			var nmat := StandardMaterial3D.new()
			nmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			nmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			nmat.cull_mode = BaseMaterial3D.CULL_DISABLED
			nmat.albedo_texture = nt
			nmat.albedo_color = Color(1, 1, 1, 0.9)
			var nq := QuadMesh.new()
			nq.size = Vector2(1.9, 0.95) * (0.8 + 0.12 * (i % 3))
			var nn: Node3D = I._node(M, R.P(-hw + 1.4 + i * 1.75, R.H - 0.04 - i * 0.004, -hd + 0.9 + i * 1.4))
			L._mesh(nn, nq, nmat, Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO))
			nuages.append([nn, nmat, 0.05 + 0.015 * i])
		var x00: float = R.P(0, 0, 0).x
		L._chaque(M, func(delta: float, _t: float) -> void:
			for e in nuages:
				var nd: Node3D = e[0]
				if not is_instance_valid(nd):
					continue
				var lx: float = nd.global_position.x - x00 + delta * float(e[2])
				if lx > hw - 1.1:
					lx = -hw + 1.1
				nd.global_position.x = x00 + lx
				(e[1] as StandardMaterial3D).albedo_color = Color(1, 1, 1, clampf((hw - 1.1 - absf(lx)) / 0.9, 0.0, 1.0) * 0.9))
	else:
		# la nuit, la Grande Ourse : sept étoiles plus grosses, qui scintillent
		var em: StandardMaterial3D = L._m(M, "etoile119", Color(1.0, 0.97, 0.86), 0.5, 0.0, 3.0)
		var etoiles: Array = []
		for p in CIEL_OURSE:
			var en: Node3D = I._node(M, R.P(1.4 + (p as Vector2).x, R.H - 0.05, 0.9 + (p as Vector2).y))
			L._mesh(en, I._sph(0.035), em)
			etoiles.append(en)
		var lune: Node3D = I._node(M, R.P(-3.6, R.H - 0.04, 2.2))
		L._mesh(lune, L._cylm(0.22, 0.22, 0.01, 24), L._m(M, "lune119", Color(0.92, 0.93, 0.88), 0.6, 0.0, 1.2))
		L._chaque(M, func(_delta: float, t: float) -> void:
			for j in range(etoiles.size()):
				var e2: Node3D = etoiles[j]
				if is_instance_valid(e2):
					e2.scale = Vector3.ONE * (0.75 + 0.45 * (0.5 + 0.5 * sin(t * (1.3 + j * 0.37) + j * 2.0))))
	# le soleil du plafond (peint, et qu'on allume) : un disque doré, ses rayons ; sa lumière
	var sp: Vector3 = R.P(-2.4, R.H - 0.05, -1.0)
	var sm: StandardMaterial3D = L._m(M, "soleil119", Color(1.0, 0.8, 0.3), 0.5, 0.0, 0.4)
	sm.emission_energy_multiplier = 0.12 if nuit else 0.4
	var sol: Node3D = I._node(M, sp)
	L._mesh(sol, L._cylm(0.34, 0.34, 0.02, 28), sm)
	for i2 in range(12):
		var a: float = TAU * i2 / 12.0
		var ln: float = 0.26 if i2 % 2 == 0 else 0.16
		L._mesh(sol, I._boxm(Vector3(ln, 0.012, 0.05)), sm, Transform3D(Basis(Vector3.UP, -a), Vector3(cos(a), 0, sin(a)) * (0.42 + ln * 0.5)))
	var sl: OmniLight3D = L._lampe(M, sp + Vector3.DOWN * 0.7, Color(1.0, 0.88, 0.62), 0.0, 8.0)
	M.ctx["soleil119"] = false
	# l'interrupteur du soleil (mur du fond, à gauche) : une plaque blanche, un bouton-soleil doré
	var ix: Transform3D = R.L(-4.3, 1.3, -hd + 0.02)
	k.box(ix, Vector3(0.18, 0.18, 0.02), "ceramique", 1.0)
	k.cyl(ix * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0, 0.02)), 0.05, 0.05, 0.02, "or", 12)
	R.mark_wall(-4.3, 1.3, -hd, 0.2)
	# le grand tableau de la Leçon de Ciel (mur du fond) : un écran qui montre le ciel d'en haut
	var tb: Transform3D = R.L(-0.2, 1.75, -hd + 0.03)
	k.box(tb, Vector3(2.55, 1.35, 0.04), "argent", 1.0)
	var pm := StandardMaterial3D.new()
	var pt: String = "res://assets/textures/nuees/panorama_nuit.png" if nuit else "res://assets/textures/nuees/panorama_jour.png"
	if ResourceLoader.exists(pt):
		var ptex: Texture2D = load(pt)
		pm.albedo_texture = ptex
		pm.emission_enabled = true
		pm.emission_texture = ptex
		pm.emission = Color(1, 1, 1)
		pm.emission_energy_multiplier = 0.35 if nuit else 0.6
		pm.uv1_scale = Vector3(0.39, 1.0, 1.0)
		pm.uv1_offset = Vector3(0.12, 0.0, 0.0)
	else:
		pm.albedo_color = Color(0.4, 0.62, 0.9)
	var bq := QuadMesh.new()
	bq.size = Vector2(2.4, 1.2)
	var bmi := MeshInstance3D.new()
	bmi.mesh = bq
	bmi.material_override = pm
	M.room.add_child(bmi)
	bmi.global_transform = tb * Transform3D(Basis(), Vector3(0, 0, 0.025))
	k.box(tb * Transform3D(Basis(), Vector3(0, -0.72, 0.06)), Vector3(2.4, 0.03, 0.1), "argent", 1.0)
	for c in range(3):
		k.box(tb * Transform3D(Basis(Vector3.UP, 0.3 * c), Vector3(-0.9 + c * 0.12, -0.69, 0.07)), Vector3(0.07, 0.015, 0.015), ["ceramique", "tissu_jaune", "tissu_bleu"][c], 1.0)
	var titre := Label3D.new()
	titre.text = "LEÇON DE CIEL"
	titre.font_size = 56
	titre.pixel_size = 0.004
	titre.modulate = Color(0.25, 0.5, 0.75)
	titre.outline_size = 0
	M.room.add_child(titre)
	titre.global_transform = tb * Transform3D(Basis(), Vector3(0, 0.88, 0.03))
	R.mark_wall(-0.2, 1.75, -hd, 1.35)
	_diodes(M, Vector3(-1.45, 1.02, -hd + 0.05), Vector3(1.05, 1.02, -hd + 0.05))
	# le Mur du Dessus (mur du fond, à droite) : les cartes postales d'en haut et leurs punaises dorées
	var mx: Transform3D = R.L(2.9, 1.75, -hd + 0.03)
	k.box(mx, Vector3(2.6, 1.3, 0.03), "bois_clair", 1.0)
	for sy in [-1.0, 1.0]:
		k.box(mx * Transform3D(Basis(), Vector3(0, sy * 0.67, 0.01)), Vector3(2.7, 0.05, 0.05), "argent", 1.0)
		k.box(mx * Transform3D(Basis(), Vector3(sy * 1.32, 0, 0.01)), Vector3(0.05, 1.38, 0.05), "argent", 1.0)
	var punaise: StandardMaterial3D = L._m(M, "punaise119", Color(1.0, 0.8, 0.3), 0.3, 0.9)
	var aplats: Array = [Color(0.45, 0.7, 0.95), Color(0.98, 0.62, 0.35), Color(0.6, 0.82, 0.55), Color(0.95, 0.85, 0.5), Color(0.75, 0.6, 0.9)]
	var n: int = 0
	for row in range(3):
		for col in range(6):
			n += 1
			if n == 5 or n == 9 or n == 16:
				# une punaise enlevée cette semaine : il ne reste qu'un petit trou
				L._mesh(I._node(M, mx * Vector3(-1.05 + col * 0.42, 0.52 - row * 0.4, 0.02)), I._sph(0.008), L._m(M, "trou119", Color(0.3, 0.25, 0.2), 0.9))
				continue
			var cx: float = -1.05 + col * 0.42 + rng.randf_range(-0.03, 0.03)
			var cy: float = 0.42 - row * 0.4 + rng.randf_range(-0.03, 0.03)
			var cxf: Transform3D = mx * Transform3D(Basis(Vector3.BACK, rng.randf_range(-0.09, 0.09)), Vector3(cx, cy, 0.02 + 0.001 * n))
			if n % 3 == 0:
				var cm: StandardMaterial3D = L._m(M, "carte119_%d" % (n % aplats.size()), aplats[n % aplats.size()], 0.8)
				_ciel_bloc(M, cxf, I._boxm(Vector3(0.32, 0.22, 0.004)), cm)
			else:
				var im: Array = CIEL_IMAGES[n % CIEL_IMAGES.size()]
				_ciel_image(M, cxf, Vector2(0.22, 0.3) if bool(im[1]) else Vector2(0.34, 0.24), str(im[0]))
			L._mesh(I._node(M, mx * Vector3(cx, cy + 0.1, 0.035)), I._sph(0.014), punaise)
	var mt := Label3D.new()
	mt.text = "LE MUR DU DESSUS"
	mt.font_size = 44
	mt.pixel_size = 0.004
	mt.modulate = Color(0.85, 0.65, 0.25)
	mt.outline_size = 0
	M.room.add_child(mt)
	mt.global_transform = mx * Transform3D(Basis(), Vector3(0, 0.82, 0.03))
	R.mark_wall(2.9, 1.75, -hd, 1.4)
	# le bureau de Madame Odile (devant le Mur du Dessus) : ses cahiers, la boîte des cartes en double
	var bx: Transform3D = R.L(2.2, 0, -2.7)
	k.box(bx * Transform3D(Basis(), Vector3(0, 0.74, 0)), Vector3(1.5, 0.05, 0.7), "ceramique", 1.0)
	k.box(bx * Transform3D(Basis(), Vector3(0.5, 0.36, 0)), Vector3(0.45, 0.72, 0.62), "ceramique", 1.0)
	k.box(bx * Transform3D(Basis(), Vector3(-0.68, 0.36, 0)), Vector3(0.05, 0.72, 0.6), "argent", 1.0)
	for d in range(3):
		k.box(bx * Transform3D(Basis(), Vector3(0.5, 0.15 + d * 0.22, 0.315)), Vector3(0.36, 0.005, 0.01), "argent", 1.0)
	for p2 in range(5):
		k.box(bx * Transform3D(Basis(Vector3.UP, 0.08 * (p2 % 3 - 1)), Vector3(-0.35, 0.775 + p2 * 0.018, 0.05)), Vector3(0.24, 0.016, 0.32), ["tissu_bleu", "tissu_rouge", "tissu_vert", "tissu_jaune", "tissu_rose"][p2], 1.0)
	k.box(bx * Transform3D(Basis(), Vector3(0.25, 0.83, -0.1)), Vector3(0.3, 0.12, 0.2), "carton", 1.0)
	k.box(bx * Transform3D(Basis(), Vector3(0.25, 0.835, 0.002)), Vector3(0.2, 0.05, 0.002), "papier", 1.0)
	k.cyl(bx * Transform3D(Basis(), Vector3(0.55, 0.765, 0.15)), 0.05, 0.045, 0.1, "tissu_turquoise", 12)
	k.col_box(bx * Transform3D(Basis(), Vector3(0, 0.38, 0)), Vector3(1.5, 0.76, 0.7))
	R.reserve(2.2, -2.75, 1.7, 1.6)
	_ciel_chaise(M, 2.2, -3.3, 0.0)
	# les tables des élèves (deux rangs de trois)
	var ti: int = 0
	for tz in [-0.9, 0.8]:
		for tx in [-3.0, -1.0, 1.0]:
			_ciel_table(M, tx, tz, ti)
			ti += 1
	# le planétaire (devant, à droite) : le pied, le soleil de laiton, la Terre et la Lune sur leurs bras,
	# la couronne d'étoiles qui tourne dans l'autre sens
	var pc: Vector3 = R.P(3.4, 0, 1.0)
	var laiton: StandardMaterial3D = L._laiton(M)
	k.cyl(Transform3D(Basis(), pc), 0.3, 0.36, 0.08, "argent", 20)
	k.cyl(Transform3D(Basis(), pc + Vector3.UP * 0.08), 0.07, 0.09, 0.82, "ceramique", 14)
	k.cyl(Transform3D(Basis(), pc + Vector3.UP * 0.9), 0.26, 0.2, 0.05, "or", 20)
	k.col_cyl(pc, 0.4, 1.0)
	R.reserve(3.4, 1.0, 1.7, 1.7)
	L._mesh(I._node(M, pc + Vector3.UP * 1.1), L._cylm(0.012, 0.012, 0.3, 6), laiton)
	var soleil_p: StandardMaterial3D = L._m(M, "planet119_soleil", Color(1.0, 0.78, 0.3), 0.35, 0.3, 1.6)
	L._mesh(I._node(M, pc + Vector3.UP * 1.3), I._sph(0.13), soleil_p)
	var bras: Node3D = I._node(M, pc + Vector3.UP * 1.08)
	L._mesh(bras, I._boxm(Vector3(0.55, 0.012, 0.012)), laiton, Transform3D(Basis(), Vector3(0.275, 0, 0)))
	L._mesh(bras, L._cylm(0.008, 0.008, 0.16, 6), laiton, Transform3D(Basis(), Vector3(0.55, 0.08, 0)))
	var terre := Node3D.new()
	bras.add_child(terre)
	terre.position = Vector3(0.55, 0.18, 0)
	L._mesh(terre, I._sph(0.055), L._m(M, "planet119_terre", Color(0.22, 0.48, 0.9), 0.4))
	L._mesh(terre, I._sph(0.032), L._m(M, "planet119_vert", Color(0.32, 0.66, 0.36), 0.6), Transform3D(Basis(), Vector3(0.03, 0.02, 0.02)))
	var orbite := Node3D.new()
	terre.add_child(orbite)
	L._mesh(orbite, I._boxm(Vector3(0.12, 0.004, 0.004)), laiton, Transform3D(Basis(), Vector3(0.06, 0, 0)))
	L._mesh(orbite, I._sph(0.022), L._m(M, "planet119_lune", Color(0.9, 0.9, 0.86), 0.7), Transform3D(Basis(), Vector3(0.13, 0, 0)))
	var couronne: Node3D = I._node(M, pc + Vector3.UP * 1.3)
	L._mesh(couronne, L._tore(0.71, 0.73), laiton)
	var etoile_l: StandardMaterial3D = L._m(M, "planet119_etoile", Color(1.0, 0.9, 0.6), 0.3, 0.5, 1.2)
	for s in range(8):
		var a2: float = TAU * s / 8.0
		L._mesh(couronne, I._sph(0.025), etoile_l, Transform3D(Basis(), Vector3(cos(a2) * 0.72, 0.03 * ((s % 3) - 1), sin(a2) * 0.72)))
	M.ctx["planet119"] = 1.0
	L._chaque(M, func(delta: float, _t: float) -> void:
		var v: float = float(M.ctx.get("planet119", 1.0))
		if is_instance_valid(bras):
			bras.rotate_y(delta * 0.25 * v)
			terre.rotate_y(delta * 1.2 * v)
			orbite.rotate_y(delta * 0.9 * v)
		if is_instance_valid(couronne):
			couronne.rotate_y(-delta * 0.05 * v))
	L._lampe(M, pc + Vector3.UP * 1.4, Color(1.0, 0.85, 0.55), 0.35, 2.5)
	# la vraie plume d'oiseau, dans son pot de verre, sur une colonne (mur de gauche)
	var cp: Vector3 = R.P(-4.55, 0, 0.0)
	k.cyl(Transform3D(Basis(), cp), 0.2, 0.22, 0.04, "argent", 16)
	k.cyl(Transform3D(Basis(), cp + Vector3.UP * 0.04), 0.14, 0.16, 0.96, "ceramique", 16)
	k.cyl(Transform3D(Basis(), cp + Vector3.UP * 1.0), 0.2, 0.18, 0.04, "argent", 16)
	k.cyl(Transform3D(Basis(), cp + Vector3.UP * 1.04), 0.07, 0.06, 0.16, "verre", 14, false)
	k.col_cyl(cp, 0.22, 1.1)
	R.reserve(-4.55, 0.0, 0.6, 0.6)
	var plume: Node3D = I._node(M, cp + Vector3.UP * 1.1)
	plume.rotation.z = -0.25
	var pblanc: StandardMaterial3D = L._m(M, "plume119", Color(0.94, 0.94, 0.92), 0.8)
	var pgris: StandardMaterial3D = L._m(M, "plume119_gris", Color(0.55, 0.58, 0.62), 0.8)
	L._mesh(plume, L._cylm(0.003, 0.004, 0.36, 5), pblanc, Transform3D(Basis(), Vector3(0, 0.18, 0)))
	for b in range(7):
		var t2: float = float(b) / 6.0
		var w2: float = sin(t2 * PI * 0.9 + 0.2) * 0.045 + 0.01
		for sx in [-1.0, 1.0]:
			L._mesh(plume, I._boxm(Vector3(w2, 0.05, 0.004)), pgris if b > 4 else pblanc, Transform3D(Basis(Vector3.BACK, sx * 0.5), Vector3(sx * w2 * 0.5, 0.1 + t2 * 0.24, 0)))
	L._balance(M, plume, Vector3.FORWARD, 0.05, 3.6)
	# le tableau d'Ombeline (mur de droite) : un ciel au coucher du soleil
	var ox: Transform3D = R.L(hw - 0.03, 1.8, 0.0, -90)
	k.box(ox, Vector3(1.24, 0.96, 0.03), "or", 1.0)
	_ciel_image(M, ox * Transform3D(Basis(), Vector3(0, 0, 0.02)), Vector2(1.12, 0.84), "nuees/tableau_coucher.png")
	R.mark_wall(hw, 1.8, 0.0, 0.7)
	# les crochets du mur de devant (à gauche de la porte) : les petits cirés des élèves
	var cr: Transform3D = R.L(-2.9, 1.45, hd - 0.03, 180)
	k.box(cr, Vector3(2.6, 0.08, 0.04), "argent", 1.0)
	for j in range(6):
		k.box(cr * Transform3D(Basis(), Vector3(-1.1 + j * 0.44, -0.24, 0.05)), Vector3(0.3, 0.42, 0.06), ["tissu_jaune", "tissu_rouge", "tissu_turquoise", "tissu_jaune", "tissu_rose", "tissu_bleu"][j], 1.0)
	R.mark_wall(-2.9, 1.45, hd, 1.35)
	L._lampe(M, R.P(-1.5, 2.6, 0.0), Color(1.0, 0.97, 0.92), 0.55 if not nuit else 0.2, 6.0)
	# les gens
	if nuit:
		var odile_soir: bool = h >= 20.5 and h < 22.0
		if odile_soir:
			var od: Node = M.person("femme", -2.6, 0.15, 90.0, "marcher", "Madame Odile Nautile")
			od.lines = ["Je range les cahiers, j'allume les étoiles, et je dis bonne nuit à la classe vide. C'est idiot. Je le fais quand même.",
				"Chut… Le plafond fait nuit. Demain, la leçon du vent."]
			var pile := Node3D.new()
			od.npc.add_child(pile)
			L._mesh(pile, I._boxm(Vector3(0.24, 0.12, 0.32)), L._m(M, "cahiers119", Color(0.3, 0.5, 0.85), 0.8), Transform3D(Basis(), Vector3(0, 1.0, 0.3)))
			L._va_et_vient(M, od, R.P(-2.6, 0, 0.15), R.P(1.9, 0, 0.15), 0.6, 3.5, pile)
			L._causer(M, od, ["Bonsoir ! Tu viens voir les étoiles du plafond ? Ce sont les mêmes que là-haut. Enfin, les mêmes que dans les livres.", "Bonnes bulles ! Doucement : la classe dort. Enfin, la salle. Les élèves dorment chez eux, j'espère."],
				[["etoiles", "Les étoiles sont vraiment comme ça ?", ["Je les ai peintes d'après les cartes du ciel de Mademoiselle Philippine, à Hautefond. Les sept grosses, là, c'est la Grande Ourse. Là-haut, il y en a des milliers de plus. Je n'ai pas eu assez de peinture. Ni assez d'échelle."]],
				["voyage", "Vous emmènerez la classe en haut ?", ["C'est mon rêve : de la mer au ciel en une seule journée. Les Strates, Hautefond, et jusqu'à la Cité des Nuées. Le Conseil a voté. Maintenant, il faut quatorze autorisations, quatorze goûters, et beaucoup de mouchoirs. Pour moi, surtout."]]])
			M.ctx["entree"] = "La Salle du Ciel, le soir : le plafond s'est changé en nuit étoilée, la Grande Ourse brille au-dessus des tables, et Madame Odile range les cahiers sans faire de bruit."
		else:
			var veil: Node = L._gens(M, "vieux", -2.6, 0.15, 90.0, "mains_dos", ["Ronde de nuit. Je vérifie que le soleil est bien éteint et que les étoiles sont bien allumées. Tout est en ordre.",
				"Madame Odile laisse toujours le ciel étoilé allumé. Elle dit que la classe vide aime les étoiles."])
			L._va_et_vient(M, veil, R.P(-2.6, 0, 0.15), R.P(1.9, 0, 0.15), 0.5, 4.0)
			L._causer(M, veil, ["Bonsoir ! L'école est fermée, mais le ciel du plafond veille.", "Bonnes bulles ! Chut… regarde en haut : la Grande Ourse. Moi, je l'appelle la Casserole. Madame Odile fait semblant de ne pas entendre."],
				[["nuit", "Pourquoi laisser les étoiles allumées ?", ["Pour les enfants des maisons-bulles d'en face. De leur fenêtre, ils voient la Salle du Ciel tout étoilée, et ils s'endorment en la regardant. C'est Madame Odile qui l'a voulu. Elle a toujours une idée de plus."]]])
			M.ctx["entree"] = "La Salle du Ciel, la nuit : la classe est vide, mais le plafond est plein d'étoiles. Par les hublots, les poissons-lanternes viennent voir."
	elif classe:
		var odile: Node = M.person("femme", -0.2, -2.9, 0.0, "enseigner", "Madame Odile Nautile")
		odile.lines = ["Les mains sur les genoux. Aujourd'hui : le vent. Qui sait ce que c'est, le vent ? … Non, Mila, ce n'est pas la Cheminée d'Air qui éternue.",
			"Le ciel n'a pas de plafond. Je sais, c'est difficile à croire. Regardez le nôtre, et imaginez qu'il continue. Toujours. Bien."]
		L._causer(M, odile, ["Bonnes bulles ! Entre, entre : tu tombes en pleine Leçon de Ciel. Assieds-toi au fond, et lève la main avant de parler.", "Ah, quelqu'un d'en haut ! Parfait. Les enfants, regardez bien : cette personne a vu le vrai ciel. Ce matin, peut-être."],
			[["plafond", "Pourquoi un ciel peint au plafond ?", ["Parce qu'au Dôme, quand on lève la tête, on voit la mer. Ici, au moins, mes élèves voient un ciel : le jour, des nuages qui passent ; le soir, des étoiles. Ce n'est pas le vrai. Mais c'est un début."]],
			["mur", "Qu'est-ce que le Mur du Dessus ?", ["Toutes les cartes postales reçues en vingt ans, chacune avec sa punaise dorée. Quand un élève voit enfin le vrai paysage d'une carte, il enlève la punaise et garde la carte. Pendant douze ans, aucune punaise n'a bougé. Cette semaine, trois."]],
			["voyage", "Vous emmènerez la classe en haut ?", ["C'est mon rêve : de la mer au ciel en une seule journée. Les Strates, Hautefond, et jusqu'à la Cité des Nuées. Le Conseil a voté. Maintenant, il faut quatorze autorisations, quatorze goûters, et beaucoup de mouchoirs. Pour moi, surtout."]]])
		var mila: Node = M.person("fille", -1.3, 1.28, 180.0, "assis", "Mila Mérou")
		mila.lines = ["Madame Nautile, est-ce qu'un nuage, c'est lourd ? … Je lève la main. Voilà. Est-ce qu'un nuage, c'est lourd ?",
			"Je le note dans mon cahier ! « Le vent : de l'air qui court. » Mais il court où ?"]
		L._causer(M, mila, ["Psst ! Tu viens d'en haut ? C'est comment, le ciel ? Le vrai ? Il ressemble à notre plafond ?", "Par la Grande Perle, c'est toi ! J'ai une nouvelle question. Non, trois. Mais tout bas, on est en classe."],
			[["plafond", "Le vrai ciel n'a pas de plafond.", ["Pas DU TOUT de plafond ? Même pas un tout petit, tout en haut ? … Je le note. Je souligne deux fois, parce que c'est un peu effrayant. Et un peu magnifique."]],
			["pluie", "La pluie, c'est de l'eau qui tombe des nuages.", ["Toute seule ? Sans tuyau ? Et les gens d'en haut, ils ne se fâchent pas ? … Ils ouvrent des parapluies ? Un petit dôme qu'on tient à la main ? Alors j'en veux un !"]],
			["oiseau", "Les oiseaux tiennent dans l'air avec leurs ailes.", ["Comme les raies dans l'eau ! Alors un oiseau, c'est une raie du ciel. … Madame Nautile dit que ce n'est pas tout à fait ça. Mais elle a souri. Quand elle sourit, c'est que c'est presque ça."]]])
		var eleve: Node = L._gens(M, "garcon", -2.7, -0.42, 180.0, "assis", ["Moi, j'ai dessiné le ciel à pois. Madame dit que ce n'est pas juste. Mais c'est joli.",
			"Mon grand frère a vu le soleil, la semaine dernière. Il dit que ça pique les yeux. Je ne sais pas si j'ai envie."])
		L._causer(M, eleve, ["Chut ! On est en leçon. … Tu as vraiment vu le ciel ? Il pique les yeux ?", "Bonnes bulles ! Tu peux me souffler la réponse ? C'est quoi, un arc-en-ciel ?"],
			[["soleil", "Le soleil pique un peu les yeux, oui.", ["Ah ! Mon frère n'a pas menti, alors. Il faudra que je le lui dise. Enfin, pas trop fort : il va être insupportable."]],
			["arc", "Un arc-en-ciel, c'est le soleil à travers la pluie.", ["Le soleil ET la pluie en même temps ? Ils ne se disputent pas ? … Et ça fait des couleurs ? Je vais dessiner ça. Avec toutes mes craies."]]])
		M.ctx["entree"] = str(L._pick(M, ["La Salle du Ciel : un plafond peint en ciel bleu où passent des nuages, des cartes postales d'en haut épinglées au mur, et au fond, Madame Odile qui fait la Leçon de Ciel.",
			"« Le ciel n'a pas de plafond. » Tu entres en pleine leçon, sous un plafond peint tout bleu. Toutes les têtes se tournent vers toi : tu viens d'en haut, tu as vu le vrai.",
			"Ça sent la craie et la limonade bleue. Sous le plafond-ciel, un planétaire de laiton tourne tout doucement, et les élèves dessinent des nuages qu'ils n'ont jamais vus."]))
	else:
		var odile2: Node = M.person("femme", 2.2, -3.3, 0.0, "lire", "Madame Odile Nautile")
		odile2.lines = ["Quatorze cahiers à corriger. Quatorze ciels dessinés. Un vert, un à pois, un avec un plafond. Tous très bien.",
			"Mila est encore là. Elle dit qu'elle range. Elle regarde le planétaire."]
		L._causer(M, odile2, ["Bonnes bulles ! La classe est finie, mais la Salle du Ciel reste ouverte. Le ciel, ça ne ferme pas.", "Ah, bonjour. Je corrige. Les mains sur les… Pardon, l'habitude."],
			[["plafond", "Pourquoi un ciel peint au plafond ?", ["Parce qu'au Dôme, quand on lève la tête, on voit la mer. Ici, au moins, mes élèves voient un ciel : le jour, des nuages qui passent ; le soir, des étoiles. Ce n'est pas le vrai. Mais c'est un début."]],
			["mur", "Qu'est-ce que le Mur du Dessus ?", ["Toutes les cartes postales reçues en vingt ans, chacune avec sa punaise dorée. Quand un élève voit enfin le vrai paysage d'une carte, il enlève la punaise et garde la carte. Pendant douze ans, aucune punaise n'a bougé. Cette semaine, trois."]],
			["soleil", "Vous avez déjà vu le vrai soleil ?", ["Une fois, à dix-huit ans, en sortant de la Colonne, à Hautefond. Je me suis assise par terre au milieu de la Place, et j'ai pleuré une heure. Le soleil du plafond, je l'ai peint de mémoire. Il est un peu plus petit. Je n'ai pas osé."]]])
		var mila2: Node = M.person("fille", 2.5, 1.3, 108.0, "observer", "Mila Mérou")
		mila2.lines = ["Regarde : la Terre tourne autour du soleil, et la Lune tourne autour de la Terre. Et nous, on tourne autour de la Perle. Tout le monde tourne !",
			"Encore cinq minutes, maman ! Le planétaire n'a pas fini sa journée."]
		L._causer(M, mila2, ["Bonnes bulles ! Viens voir le planétaire ! La petite boule bleue, c'est la Terre. Toi, tu habites dessus. Moi aussi, mais en dessous de l'eau.", "C'est toi ! Dis, en haut, le soleil, il tourne vraiment autour de rien ? Sans fil ? Sans bras de laiton ?"],
			[["soleil", "Le vrai soleil n'a pas de bras de laiton.", ["Alors qui le tient ? … Personne ? Il tient tout seul ? Comme la Perle, mais sans la Cheminée ? Je vais demander à Madame Nautile. Elle va dire « c'est la gravité ». Elle dit ça quand c'est compliqué."]],
			["lune", "La Lune, on la voit la nuit, toute ronde.", ["Toute ronde ? Pas en laiton ? Et elle brille toute seule ? … Elle renvoie la lumière du soleil ? Comme les poissons-lanternes renvoient la lumière de la Perle ! Non ? Presque ? Je note « presque »."]]])
		var maman: Node = L._gens(M, "femme", -2.0, 1.9, 150.0, "bras_croises", ["Je viens chercher Mila. Elle a demandé cinq minutes. Il y a une heure.",
			"Regarde mes mains : toutes bleues ! Je récolte la spiruline au mur des algues. Mila dit que je suis à moitié mer."])
		L._causer(M, maman, ["Bonnes bulles ! Tu connais ma fille ? Alors tu connais ses questions.", "Bonjour ! Si tu vois Mila poser une question, compte jusqu'à trois : il y en aura déjà une autre."],
			[["mila", "Mila pose beaucoup de questions ?", ["Avant le petit déjeuner, pendant, et après. Hier soir, en dormant, elle a demandé : « Et le vent, il dort ? » Je n'ai pas su répondre. Je lui ai dit de demander à Madame Odile."]]])
		M.ctx["entree"] = str(L._pick(M, ["La Salle du Ciel, après la classe : les chaises sont rentrées, des nuages peints passent au plafond, et quelqu'un regarde encore tourner le planétaire.",
			"Le soleil du plafond est éteint, mais le ciel peint reste bleu. Sur le Mur du Dessus, des dizaines de cartes postales d'en haut attendent qu'on les regarde.",
			"Il reste des dessins de ciel sur toutes les tables : un ciel vert, un à pois, un avec un plafond. Tous ont un soleil. Certains en ont trois."]))
	# ce qu'on fait : allumer (ou éteindre) le soleil du plafond, faire tourner le planétaire, lire les cartes
	# postales, regarder la plume, regarder le tableau d'Ombeline
	M.act(R.P(-4.3, 1.3, -hd + 0.45), "E : allumer le soleil du plafond", func() -> void:
		M.ctx["soleil119"] = true
		M.main.sfx("cloche_soleil", sp)
		var tw: Tween = M.room.create_tween()
		tw.set_parallel(true)
		tw.tween_property(sm, "emission_energy_multiplier", 3.2, 1.6)
		tw.tween_property(sl, "light_energy", 1.6, 1.6)
		tw.tween_property(sol, "rotation:y", sol.rotation.y + PI, 1.6).set_trans(Tween.TRANS_SINE)
		M.say(str(L._pick(M, CIEL_SOLEIL_NUIT if L._nuit(M) else CIEL_SOLEIL_JOUR)), 6.0)
		for f in M.people:
			if is_instance_valid(f) and f.has_method("gesture"):
				f.gesture("joie", 2.0)
	, 1.3, func() -> bool: return not bool(M.ctx.get("soleil119", false)))
	M.act(R.P(-4.3, 1.3, -hd + 0.45), "E : éteindre le soleil du plafond", func() -> void:
		M.ctx["soleil119"] = false
		M.main.sfx("cloche_lune", sp)
		var tw2: Tween = M.room.create_tween()
		tw2.set_parallel(true)
		tw2.tween_property(sm, "emission_energy_multiplier", 0.12 if L._nuit(M) else 0.4, 2.5)
		tw2.tween_property(sl, "light_energy", 0.0, 2.5)
		M.say(str(L._pick(M, CIEL_ETEINDRE)), 5.0)
	, 1.3, func() -> bool: return bool(M.ctx.get("soleil119", false)))
	M.act(pc + Vector3(-0.5, 1.1, 0.5), "E : faire tourner le planétaire", func() -> void:
		M.main.sfx("mecanisme", pc + Vector3.UP * 1.2)
		M.ctx["planet119"] = 9.0
		var tw3: Tween = M.room.create_tween()
		tw3.tween_property(soleil_p, "emission_energy_multiplier", 3.5, 0.6)
		tw3.tween_property(soleil_p, "emission_energy_multiplier", 1.6, 2.4)
		M.say(str(L._pick(M, CIEL_PLANETAIRE)), 7.0)
		for f2 in M.people:
			if is_instance_valid(f2) and f2.has_method("gesture"):
				f2.gesture("applaudir", 2.0)
		await M.get_tree().create_timer(3.5).timeout
		if _la(M, room0):
			M.ctx["planet119"] = 1.0
	, 1.4)
	M.act(R.P(2.9, 1.3, -1.95), "E : lire les cartes postales", func() -> void:
		M.main.sfx("ui_ouvrir", mx.origin)
		var nc: int = int(M.ctx.get("carte119", 0))
		M.ctx["carte119"] = nc + 1
		var st: Dictionary = M.state()
		if not bool(st.get("ciel_carte119", false)):
			st["ciel_carte119"] = true
			M.give([["carte_postale", 1]], "Sous le Mur du Dessus, une boîte porte un mot de Madame Odile : « Cartes en double. Servez-vous, une chacun. Et écrivez-nous quand vous verrez le vrai paysage ! »\n")
		else:
			M.say(str(CIEL_CARTES[nc % CIEL_CARTES.size()]), 8.0)
	, 1.6)
	M.act(cp + Vector3(0.45, 1.2, 0.0), "E : regarder la plume d'oiseau", func() -> void:
		var np: int = int(M.ctx.get("plume119", 0))
		M.ctx["plume119"] = np + 1
		var tw4: Tween = M.room.create_tween()
		tw4.tween_property(plume, "rotation:z", -0.45, 0.4).set_trans(Tween.TRANS_SINE)
		tw4.tween_property(plume, "rotation:z", -0.25, 1.2).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		M.say(str(CIEL_PLUME[np % CIEL_PLUME.size()]), 7.0)
	, 1.2)
	M.act(R.P(hw - 0.6, 1.5, 0.0), "E : regarder le tableau d'Ombeline", func() -> void:
		M.say(CIEL_OMBELINE, 7.0)
	, 1.3)


# =================================================================== la salle des Souffleries

## Les trois vitesses des hélices (la vitesse de la pièce : vite116).
const SOUF_VITESSES := [0.45, 1.0, 2.4]
const SOUF_TEXTES_VITESSE := ["Petite vitesse : les hélices ronronnent tout bas. C'est le réglage de la nuit, quand le Dôme dort et respire lentement.",
	"Vitesse normale : les grandes hélices tournent d'un bon pas. Le Dôme respire comme quelqu'un qui se promène.",
	"Grande vitesse ! Les hélices rugissent, les filtres bouillonnent, et quelque part sur la Place, un chapeau s'envole. « Pas trop longtemps ! » dit-on derrière toi."]
const SOUF_RETOUR := "Clac. Le levier revient tout seul à la vitesse normale. « Le Dôme a assez couru pour aujourd'hui », dit la technicienne."
const SOUF_AIRS_JOUR := ["Tu approches le nez de la bouche d'air. L'air qui descend est frais et un peu mouillé : il sent la pluie sur la mer. Là-haut, quelqu'un est en train d'ouvrir un parapluie.",
	"Ffff… Ça sent le sel chaud et le soleil. « Grand beau temps, en haut, dit la technicienne. On le sent avant même que l'Institut ne l'annonce. »",
	"L'air sent l'iode, et un tout petit peu la crêpe. « Le vent vient de Hautefond, aujourd'hui, dit-on derrière toi. C'est jour de marché. »"]
const SOUF_AIRS_NUIT := ["L'air de la nuit descend tout doucement, très frais. Il sent la mer noire et quelque chose de pointu, de brillant. La technicienne dit que ce sont les étoiles. Elle ne plaisante qu'à moitié.",
	"Ffff… Un air froid, qui sent le sel et le silence. Là-haut, il fait nuit, et la bouée-phare tourne au-dessus de la mer."]
const SOUF_ATCHOUM := "Tu respires un grand coup l'air de la surface… et ATCHOUM ! « À tes souhaits ! L'air d'en haut chatouille toujours, la première fois. C'est le vent qui dit bonjour. »"
const SOUF_FILTRE := ["Les quatre filtres bouillonnent, bien verts. Tu tapotes le verre : les bulles accélèrent, comme pour te dire merci.",
	"Tu essuies une vitre de filtre. Derrière, les algues ondulent dans les bulles. Elles mangent ce qui ne sert à rien dans l'air, et elles rendent ce qui sert à tout.",
	"Blop, blop, blop. Le filtre propre fait des bulles de plus en plus grosses. La technicienne dit que c'est bon signe : les algues sont contentes."]
## Où sont les quatre filtres d'algues (x, dans la pièce ; contre le mur du fond).
const SOUF_FX := [-3.9, -2.75, 2.75, 3.9]


## (Souffleries) un tube droit de a à b (des points du monde), de rayon r.
static func _souf_tube(M, a: Vector3, b: Vector3, r: float, mat: Material) -> void:
	var d: Vector3 = b - a
	if d.length() < 0.001:
		return
	var n: Node3D = I._node(M, (a + b) * 0.5)
	var bs := Basis(Quaternion(Vector3.UP, d.normalized())) if absf(d.normalized().dot(Vector3.UP)) < 0.999 else Basis()
	L._mesh(n, L._cylm(r, r, d.length(), 20), mat, Transform3D(bs, Vector3.ZERO))


## (Souffleries) des bulles qui montent dans un filtre (une boîte de taille 2 × ext autour de at).
static func _souf_bulles(M, at: Vector3, ext: Vector3, n: int) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = n
	p.lifetime = 3.0
	p.preprocess = 3.0
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = ext
	p.direction = Vector3.UP
	p.spread = 8.0
	p.gravity = Vector3(0, 0.25, 0)
	p.initial_velocity_min = 0.25
	p.initial_velocity_max = 0.45
	p.scale_amount_min = 0.015
	p.scale_amount_max = 0.04
	var qm := QuadMesh.new()
	qm.size = Vector2.ONE
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.billboard_keep_scale = true
	m.albedo_color = Color(0.85, 1.0, 0.95, 0.7)
	m.albedo_texture = M.R.dot_texture()
	qm.material = m
	p.mesh = qm
	M.room.add_child(p)
	p.global_position = at
	return p


## (Souffleries) un manomètre (un cadran blanc qui regarde yaw, son aiguille) ; renvoie l'aiguille.
static func _souf_manometre(M, at: Vector3, yaw: float, r: float) -> Node3D:
	var n: Node3D = I._node(M, at, yaw)
	var face := Basis(Vector3.RIGHT, PI * 0.5)
	L._mesh(n, L._cylm(r, r, 0.03, 24), L._m(M, "cadran119", Color(0.97, 0.97, 0.95), 0.4), Transform3D(face, Vector3.ZERO))
	L._mesh(n, L._tore(r, r + 0.025), L._m(M, "titane119", Color(0.8, 0.83, 0.86), 0.3, 0.8), Transform3D(face, Vector3(0, 0, 0.01)))
	L._mesh(n, I._boxm(Vector3(r * 0.5, 0.012, 0.004)), L._m(M, "cadran119_rouge", Color(0.85, 0.2, 0.15), 0.6), Transform3D(Basis(Vector3.BACK, -0.6), Vector3(r * 0.45, r * 0.35, 0.017)))
	var aig := Node3D.new()
	n.add_child(aig)
	aig.position = Vector3(0, 0, 0.022)
	L._mesh(aig, I._boxm(Vector3(0.008, r * 0.8, 0.004)), L._m(M, "aiguille119", Color(0.1, 0.1, 0.12), 0.5), Transform3D(Basis(), Vector3(0, r * 0.38, 0)))
	L._mesh(aig, I._sph(0.012), L._m(M, "aiguille119", Color(0.1, 0.1, 0.12), 0.5))
	return aig


## (Souffleries) régler la vitesse des hélices : 0 (petite), 1 (normale), 2 (grande) ; le levier suit.
static func _souf_vitesse(M, niv: int, levier: Node3D, anime: bool = true) -> void:
	M.ctx["souf119_niv"] = niv
	M.ctx["vite116"] = float(SOUF_VITESSES[niv])
	if not anime:
		levier.rotation.x = -0.55 + 0.55 * niv
	elif is_instance_valid(levier):
		var tw: Tween = M.room.create_tween()
		tw.tween_property(levier, "rotation:x", -0.55 + 0.55 * niv, 0.35).set_trans(Tween.TRANS_BACK)


## La salle des Souffleries, au pied de la Cheminée d'Air : le grand conduit blanc qui descend du plafond
## (à son pied, sous une cage de verre, la grande hélice d'aspiration ; la bouche d'air où l'on renifle
## l'air de la surface, son petit ruban), les deux grandes hélices des murs dans leurs cercles de titane,
## les quatre filtres d'algues qui bouillonnent (l'un d'eux est brun : on peut le nettoyer), les
## manomètres, le pupitre et son levier des trois vitesses ; le jour, la technicienne de la Cheminée, le
## papa de Mila qui nettoie les filtres, un visiteur ; la nuit, la technicienne de garde.
static func _souffleries(M) -> void:
	var R = M.R
	var k = R.kit
	var nuit: bool = L._nuit(M)
	var room0 = M.room
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var hh: float = R.H
	var h: float = float(M.ctx.get("hour", 12.0))
	var rng: RandomNumberGenerator = L._r(M)
	var titane: StandardMaterial3D = L._m(M, "titane119", Color(0.8, 0.83, 0.86), 0.3, 0.8)
	var nacre: StandardMaterial3D = L._m(M, "souf119_nacre", Color(0.95, 0.95, 0.97), 0.25, 0.1)
	var diode: StandardMaterial3D = L._m(M, "souf119_diode", Color(0.4, 1.0, 0.9), 0.3, 0.0, 0.8 if nuit else 1.8)
	var sombre: StandardMaterial3D = L._m(M, "souf119_sombre", Color(0.16, 0.18, 0.2), 0.5, 0.5)
	# le grand conduit de la Cheminée d'Air (au fond, au milieu) : il descend du plafond ; à son pied, la cage
	# de verre où tourne la grande hélice d'aspiration
	var cz: float = -hd + 1.7
	var cc: Vector3 = R.P(0, 0, cz)
	k.ring(Transform3D(Basis(), cc + Vector3.UP * 0.005), 1.75, 1.88, 0.01, "tissu_jaune", 32)
	k.cyl(Transform3D(Basis(), cc), 1.55, 1.6, 0.3, "argent", 32)
	k.ring(Transform3D(Basis(), cc + Vector3.UP * 0.3), 1.35, 1.5, 0.03, "lumiere", 32)
	k.cyl(Transform3D(Basis(), cc + Vector3.UP * 0.3), 1.2, 1.2, 1.4, "verre", 32, false)
	for i in range(8):
		var a: float = TAU * i / 8.0
		k.cyl(Transform3D(Basis(), cc + Vector3(cos(a) * 1.24, 0.3, sin(a) * 1.24)), 0.04, 0.04, 1.4, "argent", 6, false)
	k.cyl(Transform3D(Basis(), cc + Vector3.UP * 1.7), 1.4, 1.4, 0.18, "argent", 32)
	L._mesh(I._node(M, cc + Vector3.UP * (1.88 + (hh - 1.88) * 0.5)), L._cylm(1.25, 1.25, hh - 1.88, 32), nacre)
	for y in [2.6, 3.5, 4.4]:
		L._mesh(I._node(M, cc + Vector3.UP * y), L._tore(1.24, 1.32), diode)
	k.col_cyl(cc, 1.6, hh)
	R.reserve(0, cz, 3.6, 3.6)
	var hel: Node3D = I._node(M, cc + Vector3.UP * 0.95)
	for b in range(4):
		L._mesh(hel, I._boxm(Vector3(1.05, 0.03, 0.3)), titane, Transform3D(Basis(Vector3.UP, b * PI * 0.5) * Basis(Vector3.RIGHT, 0.35), Basis(Vector3.UP, b * PI * 0.5) * Vector3(0.55, 0, 0)))
	L._mesh(hel, I._sph(0.16), nacre)
	L._mesh(hel, L._cylm(0.05, 0.05, 0.75, 10), titane, Transform3D(Basis(), Vector3(0, 0.38, 0)))
	L._tourne(M, hel, Vector3.UP, 3.0, true)
	var brume: CPUParticles3D = L._poussiere(M, cc + Vector3.UP * 1.0, Vector3(0.95, 0.55, 0.95), 40, Color(0.92, 0.98, 1.0, 0.45), 0.04)
	var lab := Label3D.new()
	lab.text = "CHEMINÉE D'AIR"
	lab.font_size = 64
	lab.pixel_size = 0.005
	lab.modulate = Color(0.3, 0.55, 0.7)
	lab.outline_size = 0
	M.room.add_child(lab)
	lab.global_transform = R.L(0, 3.05, cz + 1.27)
	# la bouche d'air (devant le conduit) : un petit tuyau, un pavillon, sa grille et un ruban qui flotte
	var mz: float = cz + 1.5
	k.cyl(R.L(0, 1.25, mz), 0.1, 0.1, 0.5, "argent", 12, false)
	var bouche: Vector3 = R.P(0, 1.25, mz + 0.05)
	L._mesh(I._node(M, bouche + Vector3(0, 0, 0.08)), L._cylm(0.24, 0.1, 0.16, 20, false), titane, Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO))
	for rr in [0.08, 0.16, 0.23]:
		L._mesh(I._node(M, bouche + Vector3(0, 0, 0.16)), L._tore(rr - 0.008, rr), sombre, Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO))
	var ruban: Node3D = I._node(M, bouche + Vector3(0, 0.2, 0.17))
	L._mesh(ruban, I._boxm(Vector3(0.03, 0.22, 0.004)), L._m(M, "souf119_ruban", Color(0.95, 0.35, 0.3), 0.7, 0.0, 0.0, true), Transform3D(Basis(), Vector3(0, -0.11, 0)))
	M.ctx["souf119_ruban"] = 1.0
	# les deux grandes hélices des murs, dans leurs cercles de titane, et les gaines qui les relient au conduit
	for s in [-1.0, 1.0]:
		var fx: float = s * (hw - 0.3)
		var fan: Node3D = I._node(M, R.P(fx, 2.8, cz), -90.0 * s)
		L._mesh(fan, L._cylm(1.18, 1.18, 0.5, 32, false), titane, Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0, -0.02)))
		L._mesh(fan, L._cylm(1.17, 1.17, 0.02, 32), sombre, Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0, -0.26)))
		L._mesh(fan, L._tore(1.16, 1.26), titane, Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0, 0.23)))
		L._mesh(fan, L._tore(1.27, 1.31), diode, Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0, 0.23)))
		var rot := Node3D.new()
		fan.add_child(rot)
		for b2 in range(5):
			var ab: float = TAU * b2 / 5.0
			L._mesh(rot, I._boxm(Vector3(0.36, 0.95, 0.03)), nacre, Transform3D(Basis(Vector3.BACK, ab) * Basis(Vector3.UP, 0.45), Basis(Vector3.BACK, ab) * Vector3(0, 0.56, 0)))
		L._mesh(rot, I._sph(0.2), titane)
		L._tourne(M, rot, Vector3.BACK, 4.5 if s < 0.0 else -4.0, true)
		for rg in [0.45, 0.8]:
			L._mesh(fan, L._tore(rg - 0.012, rg), sombre, Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0, 0.25)))
		for g in range(4):
			L._mesh(fan, I._boxm(Vector3(0.025, 2.3, 0.02)), sombre, Transform3D(Basis(Vector3.BACK, PI * 0.25 + g * PI * 0.5), Vector3(0, 0, 0.26)))
		k.col_box(R.L(fx, 2.8, cz), Vector3(0.6, 2.5, 2.5))
		R.reserve(fx, cz, 0.9, 2.6)
		_souf_tube(M, R.P(s * 1.2, 4.55, cz), R.P(fx, 4.55, cz), 0.32, titane)
		_souf_tube(M, R.P(fx, 3.95, cz), R.P(fx, 4.87, cz), 0.32, titane)
		L._mesh(I._node(M, R.P(fx, 4.55, cz)), I._sph(0.33), titane)
	# les quatre filtres d'algues (contre le mur du fond) : l'un d'eux est brun, à nettoyer
	var sale: int = rng.randi() % 4
	var bulles: Array = []
	var algue_sale: StandardMaterial3D = null
	for fi in range(4):
		var fxp: float = float(SOUF_FX[fi])
		var fz: float = -hd + 0.38
		k.box(R.L(fxp, 0.15, fz), Vector3(1.0, 0.3, 0.5), "argent", 1.0)
		k.box(R.L(fxp, 2.55, fz), Vector3(1.0, 0.16, 0.5), "argent", 1.0)
		for sx in [-1.0, 1.0]:
			k.box(R.L(fxp + sx * 0.47, 1.35, fz), Vector3(0.06, 2.2, 0.5), "argent", 1.0)
		var am: StandardMaterial3D
		if fi == sale:
			am = L._m(M, "souf119_algue_sale", Color(0.32, 0.36, 0.16, 0.92), 0.6, 0.0, 0.2)
			algue_sale = am
		else:
			am = L._m(M, "souf119_algue", Color(0.2, 0.78, 0.48, 0.9), 0.6, 0.0, 0.9)
		L._mesh(I._node(M, R.P(fxp, 1.35, fz)), I._boxm(Vector3(0.86, 2.06, 0.34)), am)
		k.box(R.L(fxp, 1.35, fz + 0.2), Vector3(0.88, 2.08, 0.02), "verre", 1.0)
		bulles.append(_souf_bulles(M, R.P(fxp, 0.9, fz), Vector3(0.36, 0.5, 0.12), 18 if fi != sale else 6))
		var fl := Label3D.new()
		fl.text = "FILTRE %d" % (fi + 1)
		fl.font_size = 40
		fl.pixel_size = 0.004
		fl.modulate = Color(0.2, 0.3, 0.35)
		fl.outline_size = 0
		M.room.add_child(fl)
		fl.global_transform = R.L(fxp, 2.55, fz + 0.26)
		k.col_box(R.L(fxp, 1.35, fz), Vector3(1.0, 2.7, 0.5))
		R.reserve(fxp, fz, 1.2, 0.8)
	# le pupitre (à droite, devant) : l'écran des mesures, les boutons, le levier des trois vitesses, les
	# manomètres sur leur panneau
	var px: Transform3D = R.L(2.3, 0, 0.2)
	k.box(px * Transform3D(Basis(), Vector3(0, 0.47, 0)), Vector3(1.8, 0.94, 0.7), "ceramique", 1.0)
	k.box(px * Transform3D(Basis(Vector3.RIGHT, 0.45), Vector3(0, 0.98, 0.08)), Vector3(1.8, 0.05, 0.6), "noir", 1.0)
	_ciel_image(M, px * Transform3D(Basis(Vector3.RIGHT, 0.45 - PI * 0.5), Vector3(-0.3, 1.01, 0.07)), Vector2(0.8, 0.45), "nuees/ecran_mesures.png", 1.0)
	for bt in range(3):
		k.cyl(px * Transform3D(Basis(Vector3.RIGHT, 0.45), Vector3(0.3 + bt * 0.14, 1.0, 0.12)), 0.035, 0.035, 0.03, ["lumiere", "tissu_rouge", "tissu_turquoise"][bt], 12)
	k.box(px * Transform3D(Basis(), Vector3(0, 1.45, -0.3)), Vector3(1.8, 0.62, 0.06), "argent", 1.0)
	k.col_box(px * Transform3D(Basis(), Vector3(0, 0.6, -0.05)), Vector3(1.8, 1.2, 0.8))
	R.reserve(2.3, 0.2, 2.0, 1.0)
	_diodes(M, Vector3(1.4, 0.94, 0.56), Vector3(3.2, 0.94, 0.56))
	var aiguilles: Array = []
	for mi in range(3):
		aiguilles.append(_souf_manometre(M, px * Vector3(-0.55 + mi * 0.55, 1.45, -0.24), 0.0, 0.17))
	for mj in [-1.0, 1.0]:
		aiguilles.append(_souf_manometre(M, R.P(mj * 0.55, 2.25, cz + 1.18 + 0.02), mj * 25.0, 0.2))
	var levier: Node3D = I._node(M, px * Vector3(0.78, 0.95, 0.2))
	k.box(px * Transform3D(Basis(), Vector3(0.78, 0.95, 0.2)), Vector3(0.14, 0.04, 0.2), "argent", 1.0)
	L._mesh(levier, L._cylm(0.015, 0.015, 0.4, 8), titane, Transform3D(Basis(), Vector3(0, 0.2, 0)))
	L._mesh(levier, I._sph(0.045), L._m(M, "souf119_pommeau", Color(0.9, 0.2, 0.15), 0.4), Transform3D(Basis(), Vector3(0, 0.42, 0)))
	# les manomètres et le ruban suivent la vitesse ; la brume du conduit aussi
	L._chaque(M, func(_delta: float, t: float) -> void:
		var v: float = float(M.ctx.get("vite116", 1.0))
		for j in range(aiguilles.size()):
			var ag: Node3D = aiguilles[j]
			if is_instance_valid(ag):
				ag.rotation.z = 1.2 - v * 0.9 + 0.05 * sin(t * (2.0 + j) + j)
		if is_instance_valid(ruban):
			var rv: float = v * float(M.ctx.get("souf119_ruban", 1.0))
			ruban.rotation.x = 0.35 + 0.25 * rv + sin(t * (8.0 + 4.0 * rv)) * 0.12 * rv
		if is_instance_valid(brume):
			brume.speed_scale = 0.6 + v * 0.6)
	# les lampes de service, les liserés de diodes
	L._lampe(M, R.P(-2.5, hh - 0.8, 0.5), Color(0.9, 0.96, 1.0), 0.9 if not nuit else 0.35, 7.0)
	L._lampe(M, R.P(2.5, hh - 0.8, 0.5), Color(0.9, 0.96, 1.0), 0.9 if not nuit else 0.35, 7.0)
	L._lampe(M, R.P(0, 1.0, cz + 1.8), Color(0.5, 1.0, 0.85), 0.5, 4.0)
	L._lampe(M, R.P(0, 1.4, -hd + 0.9), Color(0.4, 0.9, 0.6), 0.45, 5.0)
	for s3 in [-1.0, 1.0]:
		_diodes(M, Vector3(s3 * (hw - 0.05), 0.2, -hd + 0.4), Vector3(s3 * (hw - 0.05), 0.2, hd - 0.4))
	# les gens
	if nuit:
		var garde: Node = L._gens(M, "femme", 2.3, 0.9, 180.0, "lire", ["Garde de nuit. La ville dort, les hélices tournent tout doucement. C'est le moment où le Dôme ronfle.",
			"La nuit, l'air d'en haut est plus frais. Il sent la mer noire. Et un peu les étoiles, si on a de l'imagination."])
		L._causer(M, garde, ["Bonsoir ! Doucement : la ville dort, et elle respire par ici.", "Bonnes bulles ! Tu ne dors pas ? Moi non plus. Mais moi, c'est mon travail."],
			[["nuit", "Que fait-on ici, la nuit ?", ["On baisse les hélices, on surveille les aiguilles, et on boit une limonade bleue. Si une aiguille bouge, on appelle Yolande. Elle arrive en pyjama, avec sa clé à molette. C'est arrivé une fois. Elle avait un très joli pyjama."]],
			["respirer", "Comment respire le Dôme ?", ["Par la Cheminée ! L'air frais descend de la bouée-phare, à la surface, cent quarante mètres plus haut. Ici, on le filtre dans les algues, et les grandes hélices le soufflent dans les trois dômes. Le mur des algues des Serres fait le reste."]]])
		M.ctx["entree"] = "La salle des Souffleries, la nuit : les hélices tournent au ralenti, les filtres luisent tout verts dans la pénombre, et la technicienne de garde surveille les aiguilles."
	else:
		var tech: Node = L._gens(M, "femme", 2.3, 0.9, 180.0, "holo", ["Pression : bonne. Débit : bon. Odeur : la pluie. Tout va bien au Dôme.",
			"Ici, on écoute les hélices comme on écoute un cœur. Celle de gauche a un petit hoquet. Je l'aime bien comme ça."])
		L._causer(M, tech, ["Bonnes bulles ! Bienvenue au pied de la Cheminée d'Air. Ici, on fait respirer toute la ville. Respire, toi aussi : c'est offert.", "Bonjour ! Attention à ta casquette près des grilles : les hélices adorent les casquettes."],
			[["respirer", "Comment respire le Dôme ?", ["Par la Cheminée ! L'air frais descend de la bouée-phare, à la surface, cent quarante mètres plus haut. Ici, on le filtre dans les algues, et les grandes hélices le soufflent dans les trois dômes. Le mur des algues des Serres fait le reste."]],
			["filtres", "À quoi servent les filtres d'algues ?", ["Les algues mangent ce qui ne sert à rien dans l'air, et elles rendent ce qui sert à tout. En plus, elles poussent ! Quand on nettoie un filtre, on récolte de la spiruline. Josette en met dans sa limonade bleue."]],
			["perle", "Et la Grande Perle, tout en haut ?", ["Elle est enfilée sur la Cheminée, comme une perle sur un fil : le conduit passe en plein milieu. Les jours de grande vitesse, il paraît qu'elle chante un peu. Moi, je ne l'ai jamais entendue. Mais Mila, si."]]])
		var partenaire: int = sale ^ 1
		var papa: Node = L._gens(M, "homme", float(SOUF_FX[partenaire]), -hd + 1.2, 180.0, "bricoler", ["Encore un filtre à frotter. Les algues poussent plus vite que je ne nettoie. C'est bon signe : elles sont heureuses.",
			"Ma fille Mila me demande chaque soir quel temps il fait en haut. Je renifle mes mains, et je lui dis. Je me trompe rarement."])
		L._causer(M, papa, ["Bonnes bulles ! Tu connais ma fille, Mila ? Petite, des boucles, mille questions ? C'est la mienne.", "Bonjour ! Mains vertes, mains bleues : ici, on finit toujours la journée de toutes les couleurs."],
			[["mila", "Mila sait que vous travaillez ici ?", ["Elle vient mettre la main sur la grille de la Place pour sentir l'air que je lui envoie. Je lui ai dit qu'en haut, le vent souffle tout seul, sans hélice. Elle a mis trois jours à me croire. Elle me regarde un peu de travers, depuis."]],
			["aider", "Je peux vous aider ?", ["Avec plaisir ! Tu vois le filtre un peu brun, là ? On frotte, on rince, et il redevient vert. Et ce qu'on récolte, c'est de la spiruline. Garde-la : c'est la paye des nettoyeurs."]]])
		if h < 12.0:
			var vieux: Node = L._gens(M, "vieux", 0.75, -0.25, -118.0, "observer", ["Tous les matins, je viens respirer l'air d'en haut. Trois grandes bouffées. Le docteur dit que c'est inutile. Moi, je dis que c'est délicieux.",
				"Aujourd'hui, l'air sent la pluie. J'ai quatre-vingts ans, et je n'ai jamais vu la pluie. Mais je la connais par le nez."])
			L._causer(M, vieux, ["Bonnes bulles ! Viens, approche ton nez de la bouche d'air. Doucement. Voilà. Tu sens ? C'est la surface.", "Bonjour, jeune homme, jeune fille, je ne vois plus très bien. Mais je sens très bien. Ça sent le beau temps."],
				[["pluie", "Vous n'êtes jamais monté voir la pluie ?", ["Jamais. Mes petits-enfants veulent m'emmener, maintenant que la ligne a rouvert. Je leur ai dit : « Je la connais déjà par le nez. » Mais entre nous… je crois que je vais dire oui. Un jour de pluie, bien sûr."]]])
		else:
			L._gens(M, "garcon", 0.75, -0.25, -118.0, "pointer", ["Regarde l'hélice ! Si je mets ma casquette devant la grille, elle s'envole jusqu'à la Perle ? … La dame dit non. Dommage.",
				"Mon papa dit que la Cheminée d'Air, c'est le nez du Dôme. Alors ici, on est dans les narines. Beurk. Et génial."])
		M.ctx["entree"] = str(L._pick(M, ["La salle des Souffleries : au milieu, le grand conduit blanc de la Cheminée d'Air descend du plafond, et de chaque côté, deux grandes hélices tournent dans leurs cercles de titane.",
			"Vrrrrouuum… Ici, tout souffle, tout tourne et tout bouillonne. Les filtres d'algues font des bulles vertes, et l'air sent la surface.",
			"C'est ici que le Dôme respire : l'air d'en haut descend par le grand conduit, traverse les filtres d'algues, et les hélices l'envoient dans toute la ville."]))
	# ce qu'on fait : changer de vitesse, renifler l'air de la surface, nettoyer un filtre
	M.act(px * Vector3(0.78, 1.1, 0.75), "E : changer de vitesse", func() -> void:
		var niv: int = (int(M.ctx.get("souf119_niv", 1)) + 1) % 3
		_souf_vitesse(M, niv, levier)
		M.main.sfx("levier", levier.global_position)
		if niv == 2:
			M.main.sfx("bourrasque", cc + Vector3.UP * 1.0)
		M.say(str(SOUF_TEXTES_VITESSE[niv]), 6.0)
		if niv != 2:
			return
		await M.get_tree().create_timer(8.0).timeout
		if not _la(M, room0) or int(M.ctx.get("souf119_niv", 1)) != 2:
			return
		_souf_vitesse(M, 1, levier)
		M.main.sfx("levier", levier.global_position)
		M.say(SOUF_RETOUR, 4.0)
	, 1.4)
	M.act(bouche + Vector3(0, 0.0, 0.7), "E : renifler l'air de la surface", func() -> void:
		M.main.sfx("bourrasque", bouche)
		M.ctx["souf119_ruban"] = 3.0
		if L._r(M).randf() < 0.25:
			M.main.sfx("eternuement", bouche)
			M.say(SOUF_ATCHOUM, 6.0)
		else:
			M.say(str(L._pick(M, SOUF_AIRS_NUIT if L._nuit(M) else SOUF_AIRS_JOUR)), 7.0)
		await M.get_tree().create_timer(2.5).timeout
		if _la(M, room0):
			M.ctx["souf119_ruban"] = 1.0
	, 1.2)
	M.act(R.P(float(SOUF_FX[sale]), 1.2, -hd + 1.1), "E : nettoyer un filtre", func() -> void:
		M.main.sfx("bulles", R.P(float(SOUF_FX[sale]), 1.3, -hd + 0.4))
		var pb: CPUParticles3D = bulles[sale]
		if is_instance_valid(pb):
			pb.speed_scale = 3.0
		if not bool(M.ctx.get("souf119_propre", false)):
			M.ctx["souf119_propre"] = true
			if algue_sale != null:
				var tw: Tween = M.room.create_tween()
				tw.set_parallel(true)
				tw.tween_property(algue_sale, "albedo_color", Color(0.2, 0.78, 0.48, 0.9), 2.0)
				tw.tween_property(algue_sale, "emission", Color(0.2, 0.78, 0.48), 2.0)
				tw.tween_property(algue_sale, "emission_energy_multiplier", 0.9, 2.0)
			if is_instance_valid(pb):
				pb.amount = 18
		var st: Dictionary = M.state()
		if not bool(st.get("souf_spiruline119", false)):
			st["souf_spiruline119"] = true
			M.give([["spiruline", 1]], "Tu frottes, tu rinces, et le filtre brun redevient d'un beau vert qui bouillonne. Les algues que tu as récoltées, c'est de la spiruline toute fraîche. « Garde-la, dit-on derrière toi : c'est la paye des nettoyeurs. »\n")
		else:
			M.say(str(L._pick(M, SOUF_FILTRE)), 6.0)
		await M.get_tree().create_timer(2.5).timeout
		if _la(M, room0) and is_instance_valid(pb):
			pb.speed_scale = 1.0
	, 1.4)
	# la vitesse du début : normale le jour, petite la nuit
	_souf_vitesse(M, 0 if nuit else 1, levier, false)


# =================================================================== le poste du chef de gare

## Les lettres d'Anatole Crémaillère, le liftier des Strates (on les lit une après l'autre).
const GARE_LETTRES := ["« Cher Marius. Grille huilée. Toujours fermée. Toujours prête. Anatole. » Il y en a des dizaines comme celle-là, rangées par année, avec un ruban bleu.",
	"« Cher Marius. Ta lettre de douze pages est arrivée. Je l'ai lue. Toute. Oui. Anatole. » Pour Anatole, c'est une très longue réponse.",
	"« Cher Marius. Barnabé est passé à la Gare. Il avait le vertige. Je lui ai dit : regarde la grille, pas le trou. Anatole. »",
	"« Cher Marius. La ligne rouvre. J'ai mis ma veste du dimanche. Je descends avec toi. Comment ? Anatole. » Le « Comment ? » est barré, puis réécrit, plus gros.",
	"La dernière lettre, toute neuve : « Cher Marius. Je l'ai entendue. La baleine. Dans mes mains. Merci. Anatole. » Le papier est un peu gondolé, comme si quelqu'un avait pleuré dessus. Ou une moustache."]
const GARE_PHOTO := ["Dans un cadre de laiton : un garçon en uniforme d'apprenti liftier, cramponné à une rampe, qui sourit quand même. Dessous, écrit à la main : « Barnabé, premier jour à Hautefond. »",
	"La photo de Barnabé, le neveu de Marius. Sur le cadre, une petite étoile dorée et un mot : « Descendu jusqu'au fond sans fermer les yeux. » Pour la remontée, le mot ne dit rien."]
const GARE_RADIO := ["« Gare des Strates pour Gare d'Azur : cage de laiton arrivée, six voyageurs, un chapeau à plume, et du pain chaud. » Marius attrape le micro : « Bien reçu ! Le pain d'abord ! »",
	"« Ici l'Atelier des Scaphandres. Les roues de la cabine vont très bien. — Vous êtes sûre, Yolande ? — Oui, Marius. — Merci, Yolande. » Puis un petit silence très satisfait.",
	"« Bulletin du Dôme : la Grande Chanteuse passe au-dessus du tube. Je répète : la baleine passe au-dessus du tube. Merci de ne pas lui faire de grands signes, ça la déconcentre. »"]
const GARE_RADIO_CHANT := ["« … Plus bas, toujours plus bas, la bulle s'en va, tra-la-la ! » Par le haut-parleur, la voix de Marius résonne dans le tunnel. Elle est forte, joyeuse, et pas tout à fait juste.",
	"« Ici la cabine ! Tout va bien, je passe la falaise ! … Et voilà la ville qui s'allume dans le bleu, la-la-la ! » L'agente baisse un peu le son. « Le tunnel a une très bonne acoustique. Malheureusement. »",
	"« Bonnes bulles, bonnes bulles, tout le monde descend ! » Puis, plus bas : « Pardon, madame, je chante pour la cabine. Elle aime ça. »"]
const GARE_RADIO_NUIT := "La radio grésille tout bas : « … ici la bouée-phare, tout est calme en surface. La mer dort, la Cheminée respire, les étoiles sont à leur place. Bonne nuit, le fond. »"
const GARE_CLOCHE := ["Ding-ding ! La cloche du départ sonne dans tout le poste. Sur le tableau de la ligne, la petite cabine lumineuse file vers la falaise.",
	"Ding-ding ! Tu tires sur le cordon, juste comme il faut. « Pas ding-dong, hein, dit quelqu'un. Ding-dong, c'est pour les mariages. »"]
const GARE_CLOCHE_NUIT := "Ding… La cloche résonne dans le poste endormi. « Chut ! fait le veilleur en souriant. Pas de départ la nuit : la cabine dort au quai. »"
const GARE_CASQUETTE := ["Tu essaies la casquette de rechange du chef de gare. Elle te tombe sur les yeux. « Regarde dehors, pas tes pieds ! » dit quelqu'un. Facile : tu ne vois plus tes pieds.",
	"La casquette bleu nuit, avec son galon doré : « Chef de gare ». Tu la mets, tu salues le poste. Le poste ne répond pas, mais tu te sens très important pendant trois secondes."]
## Le tableau des départs (on le lit de haut en bas).
const GARE_DEPARTS := ["Funiculaire d'Azur : un départ toutes les vingt minutes", "Premier départ : sept heures (avec le pain chaud)", "Dernier départ : vingt heures (cloche de Mila)", "Correspondance : la cage de laiton, Gare des Strates"]
## Ce que Marius chante (au poste, ou dans le tunnel, par le haut-parleur).
const GARE_NOTES := ["♪ Plus bas, toujours plus bas ! ♪", "♪ Tra-la-la, la bulle s'en va ! ♪", "♪ Bonnes bulles ! ♪", "♪ Tout le monde descend ! ♪"]


## (Poste du chef de gare) une ligne de texte posée sur un mur ou un tableau.
static func _gare_texte(M, xf: Transform3D, text: String, fs: int, c: Color, largeur: int = 0) -> Label3D:
	var lab := Label3D.new()
	lab.text = text
	lab.font_size = fs
	lab.pixel_size = 0.0018
	lab.modulate = c
	lab.outline_size = 0
	if largeur > 0:
		lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		lab.width = largeur
		lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	M.room.add_child(lab)
	lab.global_transform = xf
	return lab


## Le poste du chef de gare, à la Gare d'Azur : le bureau de Marius Trident. Le pupitre du Funiculaire
## (ses boutons, son levier) et, au-dessus, le tableau de la ligne où la petite cabine lumineuse descend et
## remonte, la cloche du départ, la radio de la ligne, le tableau des départs, le bureau (les lettres
## d'Anatole sous leur ruban bleu, la photo de Barnabé), la casquette de rechange au crochet, le banc ;
## le jour, Marius à son pupitre (ou, quand il conduit, sa voix qui chante dans le tunnel, par la radio),
## l'agente de quai, la petite Mila sur le banc après l'école (ou un voyageur) ; la nuit, le veilleur.
static func _gare(M) -> void:
	var R = M.R
	var k = R.kit
	var nuit: bool = L._nuit(M)
	var room0 = M.room
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var h: float = float(M.ctx.get("hour", 12.0))
	var marius_la: bool = not nuit and ((h >= 6.5 and h < 12.0) or (h >= 17.0 and h < 20.5))
	var mila_la: bool = not nuit and h >= 16.0
	var laiton: StandardMaterial3D = L._laiton(M)
	var nuit_bleu: StandardMaterial3D = L._m(M, "gare119_marine", Color(0.1, 0.14, 0.28), 0.7)
	# le pupitre du Funiculaire (contre le mur du fond) : ses boutons, ses voyants, son levier
	var px: Transform3D = R.L(-0.5, 0, -hd + 0.4)
	k.box(px * Transform3D(Basis(), Vector3(0, 0.48, 0)), Vector3(2.0, 0.96, 0.6), "ceramique", 1.0)
	k.box(px * Transform3D(Basis(Vector3.RIGHT, 0.4), Vector3(0, 1.0, 0.06)), Vector3(2.0, 0.05, 0.5), "noir", 1.0)
	for bt in range(6):
		k.cyl(px * Transform3D(Basis(Vector3.RIGHT, 0.4), Vector3(-0.8 + bt * 0.18, 1.03, 0.1)), 0.03, 0.03, 0.025, ["lumiere", "tissu_rouge", "tissu_turquoise", "lumiere", "tissu_jaune", "tissu_turquoise"][bt], 10)
	k.box(px * Transform3D(Basis(Vector3.RIGHT, 0.4), Vector3(0.05, 1.03, -0.05)), Vector3(0.6, 0.01, 0.12), "lumiere", 1.0)
	k.col_box(px * Transform3D(Basis(), Vector3(0, 0.5, 0)), Vector3(2.0, 1.0, 0.6))
	R.reserve(-0.5, -hd + 0.4, 2.2, 1.0)
	_diodes(M, Vector3(-1.5, 0.96, -hd + 0.71), Vector3(0.5, 0.96, -hd + 0.71))
	var levier: Node3D = I._node(M, px * Vector3(0.75, 1.0, 0.1))
	L._mesh(levier, L._cylm(0.014, 0.014, 0.34, 8), laiton, Transform3D(Basis(), Vector3(0, 0.17, 0)))
	L._mesh(levier, I._sph(0.04), L._m(M, "gare119_pommeau", Color(0.15, 0.2, 0.4), 0.4), Transform3D(Basis(), Vector3(0, 0.36, 0)))
	levier.rotation.x = -0.4
	# le tableau de la ligne (au-dessus du pupitre) : la Gare des Strates, la falaise, le tube, la Gare
	# d'Azur ; la petite cabine lumineuse qui descend et remonte
	var lx: Transform3D = R.L(-0.5, 1.95, -hd + 0.03)
	k.box(lx, Vector3(2.3, 0.66, 0.03), "noir", 1.0)
	k.box(lx * Transform3D(Basis(), Vector3(0, 0, -0.005)), Vector3(2.38, 0.74, 0.02), "argent", 1.0)
	var ligne_m: StandardMaterial3D = L._m(M, "gare119_trait", Color(0.4, 1.0, 0.9), 0.3, 0.0, 1.6)
	var pente: float = atan2(-0.24, 1.9)
	L._mesh(I._node(M, lx * Vector3(0, 0, 0.025)), I._boxm(Vector3(1.92, 0.015, 0.004)), ligne_m, Transform3D(Basis(Vector3.BACK, pente), Vector3.ZERO))
	var gare_or: StandardMaterial3D = L._m(M, "gare119_station", Color(1.0, 0.8, 0.35), 0.4, 0.3, 1.4)
	for st2 in [-0.95, 0.95]:
		L._mesh(I._node(M, lx * Vector3(st2, -0.12 * st2 / 0.95, 0.028)), I._sph(0.03), gare_or)
	for py in range(4):
		var u: float = -0.55 + py * 0.4
		L._mesh(I._node(M, lx * Vector3(u, -0.12 * u / 0.95 - 0.1, 0.026)), I._boxm(Vector3(0.012, 0.18, 0.004)), L._m(M, "gare119_pylone", Color(0.5, 0.6, 0.7), 0.5, 0.0, 0.4))
	_gare_texte(M, lx * Transform3D(Basis(), Vector3(-0.72, 0.24, 0.03)), "Gare des Strates", 30, Color(1.0, 0.85, 0.5))
	_gare_texte(M, lx * Transform3D(Basis(), Vector3(0.72, -0.24, 0.03)), "Gare d'Azur", 30, Color(0.55, 1.0, 0.9))
	var cabine: Node3D = I._node(M, lx * Vector3(0.95, -0.12, 0.032))
	L._mesh(cabine, I._sph(0.04), L._m(M, "gare119_cabine", Color(1.0, 1.0, 0.85), 0.3, 0.0, 3.0))
	R.mark_wall(-0.5, 1.95, -hd, 1.25)
	M.ctx["gare119_ph"] = 1.0
	M.ctx["gare119_v"] = 1.0
	L._chaque(M, func(delta: float, _t: float) -> void:
		if not is_instance_valid(cabine):
			return
		var u2: float = 1.0
		if not L._nuit(M):
			var ph: float = fmod(float(M.ctx.get("gare119_ph", 1.0)) + delta * float(M.ctx.get("gare119_v", 1.0)) / 30.0, 2.0)
			M.ctx["gare119_ph"] = ph
			u2 = 1.0 - absf(ph - 1.0)
		var xx: float = lerpf(-0.95, 0.95, u2)
		cabine.global_position = lx * Vector3(xx, -0.12 * xx / 0.95, 0.032))
	# la cloche du départ (sur le mur du fond, à droite du pupitre) : son bras, son cordon
	k.box(R.L(0.95, 2.3, -hd + 0.12), Vector3(0.05, 0.05, 0.24), "argent", 1.0)
	var cloche: Node3D = I._node(M, R.P(0.95, 2.28, -hd + 0.22))
	L._mesh(cloche, L._cylm(0.05, 0.12, 0.16, 18, false), laiton, Transform3D(Basis(), Vector3(0, -0.08, 0)))
	L._mesh(cloche, I._sph(0.05), laiton, Transform3D(Basis(), Vector3(0, -0.01, 0)))
	L._mesh(cloche, I._sph(0.025), L._fer(M), Transform3D(Basis(), Vector3(0, -0.17, 0)))
	L._mesh(cloche, L._cylm(0.005, 0.005, 0.6, 4), L._m(M, "gare119_cordon", Color(0.85, 0.2, 0.18), 0.8), Transform3D(Basis(), Vector3(0, -0.5, 0)))
	L._mesh(cloche, I._sph(0.022), L._m(M, "gare119_cordon", Color(0.85, 0.2, 0.18), 0.8), Transform3D(Basis(), Vector3(0, -0.8, 0)))
	R.mark_wall(0.95, 2.2, -hd, 0.25)
	var ding: Label3D = L._etiquette(M, R.P(0.95, 2.6, -hd + 0.3), "Ding-ding !")
	# la radio de la ligne, sur son meuble (au fond, à droite) : le cadran qui luit, le haut-parleur, l'antenne
	var rx: Transform3D = R.L(2.25, 0, -hd + 0.32)
	k.box(rx * Transform3D(Basis(), Vector3(0, 0.45, 0)), Vector3(0.9, 0.9, 0.5), "ceramique", 1.0)
	k.box(rx * Transform3D(Basis(), Vector3(0, 0.91, 0)), Vector3(0.94, 0.03, 0.54), "argent", 1.0)
	k.box(rx * Transform3D(Basis(), Vector3(-0.08, 1.08, -0.02)), Vector3(0.56, 0.32, 0.3), "metal", 1.0)
	k.box(rx * Transform3D(Basis(), Vector3(-0.2, 1.14, 0.135)), Vector3(0.22, 0.06, 0.01), "lumiere", 1.0)
	for kb in range(2):
		k.cyl(rx * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(-0.28 + kb * 0.16, 1.0, 0.13)), 0.025, 0.025, 0.03, "argent", 10)
	var hp: Vector3 = rx * Vector3(0.1, 1.08, 0.135)
	for rr in [0.04, 0.08, 0.11]:
		L._mesh(I._node(M, hp), L._tore(rr - 0.007, rr), L._fer(M), Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO))
	k.cyl(rx * Transform3D(Basis(Vector3.BACK, 0.35), Vector3(0.12, 1.24, -0.1)), 0.006, 0.004, 0.45, "argent", 4, false)
	k.col_box(rx * Transform3D(Basis(), Vector3(0, 0.6, 0)), Vector3(0.9, 1.2, 0.5))
	R.reserve(2.25, -hd + 0.32, 1.0, 0.7)
	# le tableau des départs (mur de droite)
	var tx: Transform3D = R.L(hw - 0.03, 1.75, -1.55, -90)
	k.box(tx, Vector3(1.4, 0.9, 0.03), "noir", 1.0)
	k.box(tx * Transform3D(Basis(), Vector3(0, 0, -0.01)), Vector3(1.5, 1.0, 0.02), "argent", 1.0)
	_gare_texte(M, tx * Transform3D(Basis(), Vector3(0, 0.33, 0.02)), "DÉPARTS", 40, Color(0.55, 1.0, 0.9))
	for li in range(GARE_DEPARTS.size()):
		_gare_texte(M, tx * Transform3D(Basis(), Vector3(-0.02, 0.15 - li * 0.16, 0.02)), str(GARE_DEPARTS[li]), 24, Color(1.0, 0.88, 0.55) if li < 3 else Color(0.85, 0.92, 1.0), 700)
	R.mark_wall(hw, 1.75, -1.55, 0.75)
	# le bureau de Marius (mur de gauche) : les lettres d'Anatole sous leur ruban, la boîte en fer, la photo
	# de Barnabé, une tasse ; sa chaise
	var bx: Transform3D = R.L(-hw + 0.45, 0, -1.5, 90)
	k.box(bx * Transform3D(Basis(), Vector3(0, 0.74, 0)), Vector3(1.2, 0.05, 0.62), "ceramique", 1.0)
	for sx in [-1.0, 1.0]:
		k.box(bx * Transform3D(Basis(), Vector3(sx * 0.56, 0.36, 0)), Vector3(0.05, 0.72, 0.58), "argent", 1.0)
	k.col_box(bx * Transform3D(Basis(), Vector3(0, 0.38, 0)), Vector3(1.2, 0.76, 0.62))
	R.reserve(-hw + 0.45, -1.5, 0.8, 1.4)
	for lt in range(4):
		k.box(bx * Transform3D(Basis(Vector3.UP, 0.05 * (lt % 3 - 1)), Vector3(0.32, 0.772 + lt * 0.012, -0.05)), Vector3(0.2, 0.01, 0.28), "papier", 1.0)
	k.box(bx * Transform3D(Basis(), Vector3(0.32, 0.8, -0.05)), Vector3(0.025, 0.012, 0.3), "tissu_bleu", 1.0)
	k.cyl(bx * Transform3D(Basis(), Vector3(0.0, 0.765, -0.12)), 0.11, 0.11, 0.09, "cuivre", 18)
	var photo: Transform3D = bx * Transform3D(Basis(Vector3.RIGHT, -0.2), Vector3(-0.38, 0.88, -0.12))
	k.box(photo, Vector3(0.2, 0.25, 0.015), "or", 1.0)
	_ciel_bloc(M, photo * Transform3D(Basis(), Vector3(0, 0, 0.009)), I._boxm(Vector3(0.16, 0.21, 0.004)), L._m(M, "gare119_photo", Color(0.72, 0.62, 0.46), 0.6))
	_ciel_bloc(M, photo * Transform3D(Basis.from_scale(Vector3(1.0, 1.1, 0.1)), Vector3(0, 0.03, 0.012)), I._sph(0.04), L._m(M, "gare119_photo_tete", Color(0.42, 0.33, 0.24), 0.7))
	k.cyl(bx * Transform3D(Basis(), Vector3(-0.15, 0.765, 0.18)), 0.04, 0.035, 0.09, "ceramique", 12)
	_ciel_chaise(M, -hw + 1.1, -1.5, -90.0)
	# le crochet (mur de gauche, près de l'entrée) : la veste bleu nuit et la casquette de rechange
	var cr: Transform3D = R.L(-hw + 0.03, 1.7, 1.45, 90)
	k.box(cr, Vector3(0.6, 0.06, 0.03), "argent", 1.0)
	_ciel_bloc(M, cr * Transform3D(Basis(), Vector3(-0.12, -0.42, 0.07)), I._boxm(Vector3(0.42, 0.75, 0.1)), nuit_bleu)
	var casq: Node3D = I._node(M, Vector3.ZERO)
	casq.global_transform = cr * Transform3D(Basis(), Vector3(0.18, 0.06, 0.1))
	L._mesh(casq, L._cylm(0.1, 0.095, 0.08, 16), nuit_bleu, Transform3D(Basis(), Vector3(0, 0.04, 0)))
	L._mesh(casq, L._cylm(0.101, 0.101, 0.02, 16), laiton, Transform3D(Basis(), Vector3(0, 0.02, 0)))
	L._mesh(casq, I._boxm(Vector3(0.16, 0.012, 0.09)), L._m(M, "gare119_visiere", Color(0.05, 0.05, 0.08), 0.3), Transform3D(Basis(Vector3.RIGHT, 0.2), Vector3(0, 0.005, 0.12)))
	R.mark_wall(-hw, 1.5, 1.45, 0.45)
	# le banc des voyageurs (mur de droite, sous le hublot)
	var bc: Transform3D = R.L(hw - 0.4, 0, 0.2, -90)
	k.box(bc * Transform3D(Basis(), Vector3(0, 0.44, 0)), Vector3(1.3, 0.05, 0.42), "ceramique", 1.0)
	k.box(bc * Transform3D(Basis(Vector3.RIGHT, -0.1), Vector3(0, 0.75, -0.2)), Vector3(1.3, 0.4, 0.04), "ceramique", 1.0)
	for sx2 in [-1.0, 1.0]:
		k.box(bc * Transform3D(Basis(), Vector3(sx2 * 0.55, 0.22, 0)), Vector3(0.05, 0.44, 0.38), "argent", 1.0)
	k.col_box(bc * Transform3D(Basis(), Vector3(0, 0.25, 0)), Vector3(1.3, 0.5, 0.42))
	R.reserve(hw - 0.4, 0.2, 0.7, 1.5)
	L._lampe(M, R.P(-0.5, 2.3, -1.2), Color(1.0, 0.95, 0.85), 0.6 if not nuit else 0.25, 4.5)
	L._lampe(M, R.P(-0.5, 1.9, -hd + 0.4), Color(0.4, 1.0, 0.9), 0.3, 2.5)
	# les gens
	var chant: Label3D = null
	if nuit:
		var veil: Node = L._gens(M, "homme", -hw + 1.1, -1.5, -90.0, "lire", ["Ronde de nuit. La cabine dort au quai, le tube est éteint, et les poissons-lanternes montent la garde dehors.",
			"Marius a laissé un mot sur le pupitre : « Dire bonne nuit à la cabine. » Je le fais tous les soirs. Elle ne répond pas, mais elle a l'air contente."])
		L._causer(M, veil, ["Bonsoir ! Le dernier départ est passé. Le premier, c'est demain, à sept heures, avec le pain chaud.", "Chut… La ligne dort. Tu veux t'asseoir un peu ? Ici, la nuit, on entend la mer respirer."],
			[["marius", "Où est Marius ?", ["Le soir, il va sur la Promenade des Hublots regarder le tube éclairé qui monte vers la falaise. Puis il rentre dans sa maison-bulle. En passant, il dit bonne nuit à Anatole. Anatole ne l'entend pas, il est bien trop loin. Mais il le sait."]]])
		M.ctx["entree"] = "Le poste du chef de gare, la nuit : sur le tableau de la ligne, la petite cabine dort au quai, la radio grésille tout bas, et le veilleur lit au bureau de Marius."
	else:
		var agente: Node
		if marius_la:
			var marius: Node = M.person("homme", -0.5, -hd + 1.05, 180.0, "comptoir", "Marius Trident")
			marius.lines = ["Plus bas, toujours plus bas ! … Pardon, l'habitude. Ici, on est déjà tout en bas.",
				"Regarde dehors, pas tes pieds ! C'est ce que je dis à tous les voyageurs. Et à mes pieds, parfois."]
			L._causer(M, marius, ["Bonnes bulles ! Bienvenue dans mon poste ! C'est petit, mais d'ici, je vois toute la ligne, de la falaise jusqu'au quai.", "Ah, mon voyageur du fond ! Assieds-toi sur le banc, la prochaine bulle part dans un quart d'heure. Ou dans une chanson."],
				[["anatole", "Qui vous écrit toutes ces lettres ?", ["Anatole Crémaillère, le liftier des Strates ! On s'écrit depuis trente ans. Ses lettres font trois lignes, les miennes douze pages. Pendant les douze ans de ligne fermée, il a huilé sa grille tous les soirs, au cas où. Lis-en une, sur le bureau : elles sont courtes."]],
				["barnabe", "C'est qui, sur la photo ?", ["Mon neveu Barnabé, apprenti liftier à Hautefond ! Il a le vertige. Un liftier qui a le vertige, tu te rends compte ? Mais il est descendu jusqu'ici sans fermer les yeux. Il m'a dit : « Dans l'eau, il n'y a pas de vide, tonton. Il y a du bleu. » J'ai fait encadrer la photo. Et la phrase, dans ma tête."]],
				["chanter", "Pourquoi chantez-vous dans le tunnel ?", ["Pour la cabine ! Quand elle entre dans la roche, il fait noir, alors je lui chante quelque chose. Elle descend plus doucement. Les voyageurs aussi, d'ailleurs : ils sont trop occupés à se boucher les oreilles pour avoir peur."]]])
			chant = L._etiquette(M, R.P(-0.5, 2.25, -hd + 1.05), "♪")
			agente = L._gens(M, "femme", -hw + 1.1, -1.5, -90.0, "lire", ["Billets compostés, quai balayé, poissons-lanternes comptés. Tout est en ordre.",
				"Trente fois par jour, Marius demande à Yolande : « Et les roues ? » Trente fois, elle répond : « Très bien. » C'est leur façon de se dire bonjour."])
			L._causer(M, agente, ["Bonnes bulles ! Poste du chef de gare, j'écoute. Un billet, un renseignement, une chanson ?", "Bonjour ! La cloche du départ ? Tu peux la sonner. Tout le monde veut la sonner."],
				[["roues", "Et les roues ?", ["Ha ha ! Tu as entendu Marius, toi aussi ! Les roues vont très bien. Yolande les vérifie à chaque descente. Marius le sait. Il demande quand même. C'est plus fort que lui."]],
				["ligne", "Comment marche le Funiculaire ?", ["Une bulle de verre suspendue à un rail, dans un long tube de verre posé sur des pylônes. Elle part de la Gare des Strates, sort de la falaise, et descend jusqu'ici, au-dessus de la Fosse. Sur le tableau, la petite lumière, c'est elle."]]])
		else:
			agente = L._gens(M, "femme", -0.5, -hd + 1.05, 180.0, "holo", ["Marius est dans la cabine. Écoute la radio : tu l'entendras chanter dans le tunnel. Tu ne pourras pas l'éviter.",
				"Je tiens le poste pendant que Marius conduit. Il m'a laissé une consigne : « Si la baleine passe, prévenir tout le monde. »"])
			L._causer(M, agente, ["Bonnes bulles ! Marius est en cabine. Je garde le poste. Et la cloche.", "Bonjour ! Chut… écoute le haut-parleur. Marius entre dans le tunnel. Trois, deux, un…"],
				[["marius", "Où est Marius ?", ["Dans la cabine, entre la falaise et le quai ! Il conduit les descentes de l'après-midi. On l'entend chanter à la radio : dans le tunnel, il y a de l'écho, alors il en profite. La cabine adore ça. Les voyageurs, ça dépend."]],
				["ligne", "Comment marche le Funiculaire ?", ["Une bulle de verre suspendue à un rail, dans un long tube de verre posé sur des pylônes. Elle part de la Gare des Strates, sort de la falaise, et descend jusqu'ici, au-dessus de la Fosse. Sur le tableau, la petite lumière, c'est elle."]]])
			chant = L._etiquette(M, hp + Vector3(0, 0.35, 0.1), "♪")
		if mila_la:
			var mila: Node = M.person("fille", hw - 0.45, 0.2, -90.0, "assis", "Mila Mérou")
			mila.lines = ["Ding-ding ! Le soir, c'est moi qui sonne la cloche du dernier départ. Marius m'a nommée sonneuse officielle.",
				"J'attends les voyageurs du soir. Je leur demande : « C'est comment, le ciel ? » Hier, une dame a dit : « Mouillé. » Je l'ai noté."]
			L._causer(M, mila, ["Bonnes bulles ! Tu descends ou tu remontes ? Si tu remontes, tu peux regarder le ciel pour moi ?", "Chut ! J'écoute le tube. Quand la cabine arrive, il fait « hmmmm ». Comme la baleine, mais en plus petit."],
				[["cloche", "C'est toi qui sonnes la cloche ?", ["Oui ! Le soir, pour le dernier départ. Ding-ding ! Mais il faut tirer doucement, sinon elle fait « ding-dong », et Marius dit que ça, c'est pour les mariages."]],
				["cahier", "Qu'est-ce que tu notes dans ton cahier ?", ["Tout ce que les voyageurs me disent du ciel ! « Grand », « mouillé », « plein d'oiseaux », « ça dépend ». J'ai déjà quarante-deux réponses. Aucune n'est pareille. Le ciel doit être très compliqué. Ou très grand."]]])
		else:
			var voy: Node = L._gens(M, "vieux", hw - 0.45, 0.2, -90.0, "assis", ["Je remonte à Hautefond. J'ai vu la Grande Perle, la Fontaine des Bulles, et une raie. Ma femme ne va jamais me croire, pour la raie.",
				"Dans le tube, on voit la ville s'allumer dans le bleu. J'ai fait la descente deux fois. Je vais la refaire une troisième, pour fermer les yeux et écouter."])
			L._causer(M, voy, ["Bonnes bulles, comme ils disent ici ! J'attends la bulle. Elle est toujours à l'heure. C'est moi qui suis en avance.", "Bonjour ! Tu remontes aussi ? On pourra se tenir la barre, dans le tube. Enfin, si tu veux."],
				[["descente", "C'était comment, la descente ?", ["Au début, j'ai tenu la barre très fort. Puis une raie est passée sous mes pieds, toute lente, toute grande. J'ai lâché la barre pour lui dire bonjour. Le chef de gare a applaudi."]]])
		var chant_l: Label3D = chant
		L._souvent(M, 4.0, 7.5, func() -> void:
			if not is_instance_valid(chant_l):
				return
			chant_l.text = str(L._pick(M, GARE_NOTES))
			L._montrer(M, chant_l, 2.2))
		M.ctx["entree"] = str(L._pick(M, ["Le poste du chef de gare : un pupitre plein de boutons, une cloche de laiton, le tableau des départs, et sur le mur, la ligne du Funiculaire où avance une petite lumière.",
			"Ça sent le café et le cuivre astiqué. Sur le bureau, une pile de lettres attachées d'un ruban bleu, et la photo d'un garçon qui s'agrippe à une rampe en souriant.",
			"« Plus bas, toujours plus bas ! » Une voix chante quelque part. Par les hublots, des poissons-lanternes passent, ponctuels comme des voyageurs."]))
	# ce qu'on fait : sonner la cloche du départ, lire une lettre d'Anatole, regarder la photo de Barnabé,
	# écouter la radio de la ligne, essayer la casquette
	M.act(R.P(0.95, 1.3, -hd + 0.8), "E : sonner la cloche du départ", func() -> void:
		M.main.sfx("clochette", cloche.global_position)
		var tw: Tween = M.room.create_tween()
		tw.tween_property(cloche, "rotation:x", 0.5, 0.15)
		tw.tween_property(cloche, "rotation:x", -0.4, 0.25)
		tw.tween_property(cloche, "rotation:x", 0.2, 0.25)
		tw.tween_property(cloche, "rotation:x", 0.0, 0.3)
		var tw2: Tween = M.room.create_tween()
		tw2.tween_property(levier, "rotation:x", 0.45, 0.3)
		tw2.tween_interval(0.8)
		tw2.tween_property(levier, "rotation:x", -0.4, 0.5)
		L._montrer(M, ding, 1.6)
		var st: Dictionary = M.state()
		if not bool(st.get("gare_chocolat119", false)):
			st["gare_chocolat119"] = true
			M.give([["chocolat_abysses", 1]], "Ding-ding ! La cloche résonne dans tout le poste. Sur le pupitre, une boîte en fer porte une étiquette : « Pour les sonneurs de cloche. Un chacun. Signé : Marius. » Dedans, des chocolats des abysses.\n")
		elif L._nuit(M):
			M.say(GARE_CLOCHE_NUIT, 6.0)
		else:
			M.say(str(L._pick(M, GARE_CLOCHE)), 6.0)
		if L._nuit(M):
			return
		M.ctx["gare119_v"] = 8.0
		await M.get_tree().create_timer(3.0).timeout
		if _la(M, room0):
			M.ctx["gare119_v"] = 1.0
	, 1.2)
	M.act(bx * Vector3(0.25, 1.0, 0.55), "E : lire une lettre d'Anatole", func() -> void:
		M.main.sfx("ui_ouvrir", bx * Vector3(0.32, 0.8, 0.0))
		var nl: int = int(M.ctx.get("lettre119", 0))
		M.ctx["lettre119"] = nl + 1
		M.say(str(GARE_LETTRES[nl % GARE_LETTRES.size()]), 8.0)
	, 1.0)
	M.act(bx * Vector3(-0.38, 1.0, 0.55), "E : regarder la photo de Barnabé", func() -> void:
		var nf: int = int(M.ctx.get("photo119", 0))
		M.ctx["photo119"] = nf + 1
		M.say(str(GARE_PHOTO[nf % GARE_PHOTO.size()]), 7.0)
	, 1.0)
	M.act(rx * Vector3(0, 1.1, 0.75), "E : écouter la radio de la ligne", func() -> void:
		M.main.sfx("radio_jingle", hp)
		var nr: int = int(M.ctx.get("radio119", 0))
		M.ctx["radio119"] = nr + 1
		if L._nuit(M):
			M.say(GARE_RADIO_NUIT, 7.0)
		elif marius_la:
			M.say(str(GARE_RADIO[nr % GARE_RADIO.size()]), 8.0)
		else:
			M.say(str(GARE_RADIO_CHANT[nr % GARE_RADIO_CHANT.size()]), 8.0)
			if chant != null and is_instance_valid(chant):
				chant.text = str(L._pick(M, GARE_NOTES))
				L._montrer(M, chant, 2.5)
	, 1.3)
	M.act(R.P(-hw + 0.6, 1.4, 0.9), "E : essayer la casquette", func() -> void:
		M.main.sfx("ui_clic", casq.global_position)
		var tw3: Tween = M.room.create_tween()
		tw3.tween_property(casq, "position:y", casq.position.y + 0.08, 0.2)
		tw3.tween_property(casq, "position:y", casq.position.y, 0.3).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		M.say(str(L._pick(M, GARE_CASQUETTE)), 6.0)
	, 1.1)


# =================================================================== CONSTANTES (à mettre avant « static func build »)

## Le Petit Plongeon : la coque ronde de la cabine (le rayon intérieur, le nombre de facettes ; la
## facette n° 0 est la porte, la n° 6 le fond, où sont le tableau de bord et les deux gros hublots).
const PLONGEON_R: float = 1.95
const PLONGEON_SEG: int = 12
## Le journal de bord de Lou (on le lit page après page).
const PLONGEON_JOURNAL := ["JOURNAL DE BORD DU PETIT PLONGEON. Lundi : cent quatre-vingt-douze mètres. Une raie m'a fait coucou avec une aile. Le Professeur dit que c'est impossible. La raie n'était pas au courant.",
	"Mardi : nasses relevées, du poisson pour le Grand Marché de Hautefond. Une crevette pour le Professeur. Elle était d'accord. Je crois.",
	"Mercredi : révision. Yolande a trouvé une vis qui la regardait de travers. Journée au sec. Bloup a boudé toute la journée.",
	"Jeudi : cent quatre-vingt-dix-neuf mètres. J'ai lu la plaque. J'ai souri. Je suis remontée. Ne pas le dire à Yolande."]
const PLONGEON_PLAQUE := "Sur le tableau de bord, une petite plaque de titane, gravée : « 200 ». C'est la limite de Lou, en mètres. Juste dessous, en tout petit : « Lou, je te vois. » C'est signé d'un Y."

## La Salle des Marées : les propositions mises au vote à main levée (l'une après l'autre).
const MAREES_VOTES := ["Proposition du jour : repeindre la Fontaine des Bulles. Elle est en verre, avec de l'eau dedans. Tu lèves la main contre, avec tout le monde. Rejetée à l'unanimité, après trois heures de débat. « Un très bon Conseil », sourit la Présidente.",
	"Proposition du jour : la pétition de la petite Mila, « Pour que tous les enfants du Dôme voient le ciel ». Tu lèves la main. Toutes les mains se lèvent. La greffière écrit « unanimité » et dessine une étoile à côté.",
	"Proposition du jour : un hublot d'honneur pour la raie qui vient tous les jours à la Promenade des Hublots. Tu lèves la main. Adoptée ! Il faudra lui expliquer la cérémonie.",
	"Proposition du jour : une minute de silence chaque fois que la Grande Chanteuse passe au-dessus du Dôme. Tu lèves la main. Adoptée ! Le Professeur Benthos, au fond, demande deux minutes. On lui en accorde une et demie.",
	"Proposition du jour : envoyer un huitième centimètre de ruban au Bourgmestre Hector, par le Funiculaire. Tu lèves la main, par gentillesse. Adoptée. Le ruban partira demain matin, dans une enveloppe."]
## Le Livre des Marées : des phrases pour ceux qui vivront ici dans cent ans (on les lit l'une après l'autre).
const MAREES_LIVRE := ["LE LIVRE DES MARÉES. « Ce jour, la Ligne a rouvert après douze ans. Une dame d'en haut a pleuré devant la Grande Perle. Une dame d'en bas a pleuré devant son chapeau à plume. »",
	"LE LIVRE DES MARÉES. « Ce jour, des enfants d'en haut ont collé leur nez contre la vitre du Funiculaire. Il reste des marques. Marius ne veut pas qu'on les efface. »",
	"LE LIVRE DES MARÉES. « Ce jour, la Grande Chanteuse est passée trois fois. Le Professeur Benthos a noté trois fois la même phrase : bonjour, le Dôme. »",
	"LE LIVRE DES MARÉES. « Ce jour, rien de spécial. Les algues ont fait l'air, la Perle a fait le jour, et tout le monde a eu de la soupe. Dans cent ans, j'espère que ce sera pareil. » C'est une écriture d'enfant, au crayon bleu."]
const MAREES_FAUTEUIL := "Au bout de la table, un fauteuil vide, et sur le coussin, un coquillage. Une petite plaque de nacre : « Réservé à notre cousine l'Atlantide. On ne sait jamais. » Personne ne s'y assoit. Même la poussière n'ose pas."

## Le cabinet d'écoute : les pages du Grand Dictionnaire de la Chanteuse, les rouleaux enregistrés.
const BENTHOS_DICO := ["LE GRAND DICTIONNAIRE DE LA CHANTEUSE, page un. Trois notes graves, une aiguë : « Bonjour, le Dôme. » Deux longues : « Il fait bon, là-haut. » En marge : « Vérifié quarante-trois fois. »",
	"LE GRAND DICTIONNAIRE DE LA CHANTEUSE, page cent douze. Une note très grave, qui ne finit pas : « Je reviendrai. » En marge, d'une écriture tremblée : « Elle est toujours revenue. »",
	"LE GRAND DICTIONNAIRE DE LA CHANTEUSE, page six cent quatre. Quatre petites notes qui montent : « Tiens, des poissons-lanternes. » Hypothèse du Professeur : elle aime les lumières. Hypothèse de la petite Mila : elle a faim.",
	"LE GRAND DICTIONNAIRE DE LA CHANTEUSE, dernière page. Une phrase recopiée note à note, sans traduction. Juste un mot, à côté : « À garder pour la prochaine fois. C'est mon rendez-vous. »"]
const BENTHOS_ROULEAUX := ["Rouleau numéro 87 : « La Chanteuse au-dessus de la Place de la Perle, un mardi. » Un chant grave, très long, qui fait vibrer le pavillon. À la fin, on entend Josette crier : « La soupe ! » Puis le silence.",
	"Rouleau numéro 214 : « Bonjour, le Dôme, trois fois de suite. » Trois fois les mêmes notes, de plus en plus près. On dirait quelqu'un qui frappe doucement à la porte avant d'entrer.",
	"Rouleau numéro 9, le tout premier. On entend surtout la mer, un petit bruit de verre, et la voix d'un jeune homme qui chuchote : « Elle chante. Elle chante vraiment. »",
	"Rouleau numéro 301 : « Duo. » La Chanteuse, puis un fredonnement humain, un peu faux, puis la Chanteuse de nouveau, plus doucement. Sur l'étiquette : « Elle m'a répondu. Notez la date ! »"]


# =================================================================== les aides de ces lieux

## Une image qui luit (un écran, une affiche) : une matière à texture, gardée pour la pièce ; e = 0 :
## une affiche qui ne luit pas.
static func _marees_ecran(M, tex: String, e: float = 0.9) -> StandardMaterial3D:
	var key: String = "ecran119_%d_" % int(e * 10.0) + tex
	if not M.ctx.has("mats116"):
		M.ctx["mats116"] = {}
	var cache: Dictionary = M.ctx["mats116"]
	if cache.has(key):
		return cache[key]
	var m := StandardMaterial3D.new()
	var p: String = "res://assets/textures/" + tex
	if ResourceLoader.exists(p):
		var t: Texture2D = load(p)
		m.albedo_texture = t
		if e > 0.0:
			m.emission_enabled = true
			m.emission_texture = t
			m.emission = Color(1, 1, 1)
			m.emission_energy_multiplier = e
	else:
		m.albedo_color = Color(0.1, 0.25, 0.35)
	m.roughness = 0.4
	cache[key] = m
	return m


## Un panneau plat (un écran, une affiche) : xf = son centre ; il regarde +Z.
static func _marees_panneau(M, xf: Transform3D, size: Vector2, mat: Material) -> MeshInstance3D:
	var qm := QuadMesh.new()
	qm.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = qm
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	M.room.add_child(mi)
	mi.global_transform = xf
	return mi


## Une barre (un câble, une tige) de a à b (dans le monde), de rayon r, dans une matière de la pièce.
static func _benthos_fil(M, a: Vector3, b: Vector3, r: float, key: String) -> void:
	var d: Vector3 = b - a
	if d.length() < 0.001:
		return
	var bs := Basis(Quaternion(Vector3.UP, d.normalized())) if absf(d.normalized().dot(Vector3.UP)) < 0.999 else Basis()
	M.R.kit.cyl(Transform3D(bs, a), r, r, d.length(), key, 8, false)


## Une ombre qui passe sur un hublot (le calmar, la Grande Chanteuse) : un disque noir, transparent,
## devant la mer ; renvoie sa matière (on fait varier son alpha).
static func _plongeon_ombre(hub: Node3D, r: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.0, 0.01, 0.03, 0.0)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var od := CylinderMesh.new()
	od.top_radius = r - 0.01
	od.bottom_radius = r - 0.01
	od.height = 0.002
	od.radial_segments = 24
	L._mesh(hub, od, m, Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0, -0.003)))
	return m


## Un texte posé à plat (les chiffres d'un cadran) : il regarde +Z de xf.
static func _plongeon_texte(M, xf: Transform3D, text: String, px: float, c: Color) -> Label3D:
	var lab := Label3D.new()
	lab.text = text
	lab.font_size = 64
	lab.pixel_size = px
	lab.outline_size = 0
	lab.modulate = c
	lab.shaded = false
	lab.double_sided = false
	M.room.add_child(lab)
	lab.global_transform = xf
	return lab


## La direction (au sol, depuis le centre) de la facette n° i de la cabine du Petit Plongeon.
static func _plongeon_dir(i: int) -> Vector3:
	var am: float = PI * 0.5 + TAU * i / PLONGEON_SEG
	return Vector3(cos(am), 0, sin(am))


## La coque ronde du Petit Plongeon, dans la pièce carrée : un mur à facettes (la n° 0 s'ouvre sur la
## porte), le soubassement, deux ceintures et des rivets, les membrures de titane aux arêtes.
static func _plongeon_coque(M) -> void:
	var R = M.R
	var k = R.kit
	var r: float = PLONGEON_R
	var hh: float = R.H
	var th: float = 0.2
	var chord: float = 2.0 * r * tan(PI / PLONGEON_SEG) + 0.04
	var tm: float = float((R.pal["mur"] as Array)[2])
	var tb: float = float((R.pal["bas"] as Array)[2])
	for i in range(PLONGEON_SEG):
		var dv: Vector3 = _plongeon_dir(i)
		var xf := Transform3D(Basis.looking_at(-dv, Vector3.UP), R.P(0, 0, 0) + dv * (r + th * 0.5))
		if i == 0:
			# au-dessus de la porte : un linteau
			k.box(xf * Transform3D(Basis(), Vector3(0, (hh + 2.2) * 0.5, 0)), Vector3(chord, hh - 2.2, th), "mur", tm)
			continue
		k.box(xf * Transform3D(Basis(), Vector3(0, hh * 0.5, 0)), Vector3(chord, hh, th), "mur", tm)
		k.box(xf * Transform3D(Basis(), Vector3(0, 0.3, -th * 0.5 - 0.01)), Vector3(chord, 0.6, 0.02), "bas", tb)
		k.box(xf * Transform3D(Basis(), Vector3(0, 0.61, -th * 0.5 - 0.02)), Vector3(chord, 0.04, 0.03), "argent", 1.0)
		k.box(xf * Transform3D(Basis(), Vector3(0, hh - 0.12, -th * 0.5 - 0.02)), Vector3(chord, 0.05, 0.03), "argent", 1.0)
		for rx in range(4):
			for ry in [0.72, hh - 0.22]:
				k.cyl(xf * Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), Vector3(-chord * 0.375 + rx * chord * 0.25, float(ry), -th * 0.5)), 0.016, 0.016, 0.015, "argent", 6)
		k.col_box(xf * Transform3D(Basis(), Vector3(0, hh * 0.5, 0)), Vector3(chord, hh + 0.4, th))
	# les membrures, aux arêtes
	var rv: float = r / cos(PI / PLONGEON_SEG) - 0.03
	for i2 in range(PLONGEON_SEG):
		var av: float = PI * 0.5 + TAU * (i2 + 0.5) / PLONGEON_SEG
		var dv2 := Vector3(cos(av), 0, sin(av))
		k.box(Transform3D(Basis.looking_at(-dv2, Vector3.UP), R.P(0, hh * 0.5, 0) + dv2 * rv), Vector3(0.08, hh, 0.06), "argent", 1.0)


## Un siège du Petit Plongeon (un baquet sur un pied de titane) qui regarde yaw.
static func _plongeon_siege(M, x: float, z: float, yaw: float, c: String) -> void:
	var R = M.R
	var k = R.kit
	var xf: Transform3D = R.L(x, 0, z, yaw)
	k.cyl(xf, 0.2, 0.24, 0.05, "argent", 14)
	k.cyl(xf * Transform3D(Basis(), Vector3(0, 0.05, 0)), 0.05, 0.05, 0.3, "argent", 8, false)
	k.box(xf * Transform3D(Basis(), Vector3(0, 0.38, 0.02)), Vector3(0.52, 0.08, 0.5), "ceramique", 1.0)
	k.box(xf * Transform3D(Basis(), Vector3(0, 0.43, 0.03)), Vector3(0.46, 0.05, 0.44), "tissu_" + c, 1.0)
	k.box(xf * Transform3D(Basis(Vector3.RIGHT, -0.15), Vector3(0, 0.76, -0.22)), Vector3(0.46, 0.6, 0.06), "tissu_" + c, 1.0)
	k.box(xf * Transform3D(Basis(Vector3.RIGHT, -0.15), Vector3(0, 0.74, -0.26)), Vector3(0.52, 0.7, 0.03), "ceramique", 1.0)
	for s in [-1.0, 1.0]:
		k.box(xf * Transform3D(Basis(), Vector3(s * 0.27, 0.56, 0.02)), Vector3(0.05, 0.05, 0.42), "argent", 1.0)
		k.box(xf * Transform3D(Basis(), Vector3(s * 0.27, 0.48, 0.2)), Vector3(0.04, 0.14, 0.04), "argent", 1.0)
	k.col_box(xf * Transform3D(Basis(), Vector3(0, 0.4, 0)), Vector3(0.55, 0.8, 0.55))
	R.reserve(x, z, 0.7, 0.7)


## Un banc de poissons-lanternes qui passent derrière des hublots (hubs : [[le nœud du hublot, son
## rayon], …]) : de petits corps sombres et leurs points de lumière ; « banc119 » (dans le contexte) :
## combien sont dehors en ce moment (tous, par défaut) ; « courant119 » : leur vitesse.
static func _plongeon_banc(M, hubs: Array, n: int) -> void:
	var rng: RandomNumberGenerator = L._r(M)
	var corps: StandardMaterial3D = L._m(M, "lanterne119_corps", Color(0.06, 0.1, 0.16), 0.6)
	var lum: StandardMaterial3D = L._m(M, "lanterne119_lum", Color(0.55, 1.0, 0.9), 0.3, 0.0, 3.0)
	var lum2: StandardMaterial3D = L._m(M, "lanterne119_or", Color(1.0, 0.85, 0.4), 0.3, 0.0, 3.0)
	var fish: Array = []
	for i in range(n):
		var hi: int = i % hubs.size()
		var hub: Node3D = hubs[hi][0]
		var r: float = float(hubs[hi][1])
		var s: float = clampf(r / 0.4, 0.6, 1.4) * rng.randf_range(0.7, 1.2)
		var f := Node3D.new()
		hub.add_child(f)
		L._mesh(f, I._sph(0.022 * s), corps, Transform3D(Basis.from_scale(Vector3(2.2, 1.0, 0.5)), Vector3.ZERO))
		L._mesh(f, I._boxm(Vector3(0.025, 0.03, 0.004) * s), corps, Transform3D(Basis(), Vector3(-0.055 * s, 0, 0)))
		var lm: StandardMaterial3D = lum if i % 3 != 0 else lum2
		for pp in range(3):
			L._mesh(f, I._sph(0.006 * s), lm, Transform3D(Basis(), Vector3((0.025 - pp * 0.02) * s, -0.012 * s, 0.006)))
		L._mesh(f, I._sph(0.008 * s), lm, Transform3D(Basis(), Vector3(0.045 * s, 0.012 * s, 0.006)))
		fish.append({"n": f, "r": r, "x": rng.randf_range(-r, r), "y": rng.randf_range(-r * 0.7, r * 0.7), "v": rng.randf_range(0.04, 0.1),
			"d": 1.0 if rng.randf() < 0.5 else -1.0, "ph": rng.randf() * TAU})
	L._chaque(M, func(delta: float, t: float) -> void:
		var act: int = int(M.ctx.get("banc119", n))
		var vit: float = float(M.ctx.get("courant119", 1.0))
		for i2 in range(fish.size()):
			var e: Dictionary = fish[i2]
			var nd: Node3D = e["n"]
			if not is_instance_valid(nd):
				continue
			var rr: float = float(e["r"])
			var x: float = float(e["x"]) + float(e["v"]) * float(e["d"]) * vit * delta
			if absf(x) > rr + 0.1:
				x = -float(e["d"]) * (rr + 0.05)
				e["y"] = rng.randf_range(-rr * 0.7, rr * 0.7)
			e["x"] = x
			var y: float = float(e["y"]) + sin(t * 1.3 + float(e["ph"])) * 0.012
			nd.position = Vector3(x, y, -0.006)
			nd.scale = Vector3(float(e["d"]), 1.0, 1.0)
			nd.visible = i2 < act and Vector2(x, y).length() < rr - 0.04)


## Le calmar géant (très gentil, très timide) passe devant le grand hublot : son ombre couvre le verre,
## un œil doré s'ouvre, te regarde, cligne, et s'en va.
static func _plongeon_calmar(M, ombre: StandardMaterial3D, oeil: Node3D) -> void:
	if not is_instance_valid(oeil):
		return
	oeil.visible = true
	oeil.position = Vector3(0.24, 0.05, 0.0)
	oeil.scale = Vector3(1.0, 0.05, 1.0)
	var tw: Tween = M.room.create_tween()
	tw.tween_property(ombre, "albedo_color:a", 0.9, 1.6)
	tw.tween_property(oeil, "scale", Vector3.ONE, 0.7).set_trans(Tween.TRANS_SINE)
	tw.tween_property(oeil, "position:x", -0.05, 2.5).set_trans(Tween.TRANS_SINE)
	tw.tween_property(oeil, "scale:y", 0.05, 0.15)
	tw.tween_property(oeil, "scale:y", 1.0, 0.2)
	tw.tween_property(oeil, "position:x", -0.25, 2.0).set_trans(Tween.TRANS_SINE)
	tw.tween_property(oeil, "scale:y", 0.05, 0.4)
	tw.tween_property(ombre, "albedo_color:a", 0.0, 1.8)
	tw.tween_callback(func() -> void:
		if is_instance_valid(oeil):
			oeil.visible = false)


## Des bulles qui montent (les colonnes de verre de la Salle des Marées).
static func _marees_bulles(M, at: Vector3, r: float, hgt: float, n: int) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = n
	p.lifetime = hgt / 0.55
	p.preprocess = p.lifetime
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(r * 0.6, 0.05, r * 0.6)
	p.direction = Vector3.UP
	p.spread = 6.0
	p.gravity = Vector3.ZERO
	p.initial_velocity_min = 0.4
	p.initial_velocity_max = 0.55
	p.scale_amount_min = 0.025
	p.scale_amount_max = 0.06
	var qm := QuadMesh.new()
	qm.size = Vector2.ONE
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.billboard_keep_scale = true
	m.albedo_color = Color(0.8, 0.97, 1.0, 0.6)
	m.albedo_texture = M.R.dot_texture()
	qm.material = m
	p.mesh = qm
	M.room.add_child(p)
	p.global_position = at
	return p


# =================================================================== le Petit Plongeon

## LE PETIT PLONGEON (da_plongeon) : la cabine ronde et étroite du bathyscaphe jaune de Lou Grenadier (une
## coque à facettes, ses membrures et ses rivets) ; le tableau de bord en arc (le sonar qui balaie, la
## profondeur, la plaque « 200 » gravée par Yolande, la manette des ballasts, le manche, les boutons), le
## manomètre, les deux gros hublots devant (« comme des yeux étonnés ») et les deux petits des côtés, où
## passent des poissons-lanternes ; les sièges, le sas au plafond, Bloup le canard porte-bonheur qui se
## balance, la boîte à goûter, le journal de bord. On « plonge » : la lumière baisse, la mer devient noire
## derrière les hublots, les poissons-lanternes arrivent, et parfois le calmar géant (très gentil) passe.
## Le jour, Lou (à ses heures) et un petit passager, sinon l'apprentie et un mécanicien ; la nuit, le
## mécanicien de garde (on ne plonge pas : on allume les projecteurs).
static func _plongeon(M) -> void:
	var R = M.R
	var k = R.kit
	var nuit: bool = L._nuit(M)
	var room0 = M.room
	var h: float = float(M.ctx.get("hour", 12.0))
	var lou_la: bool = not nuit and ((h >= 9.0 and h < 13.0) or (h >= 14.0 and h < 18.0))
	var r: float = PLONGEON_R
	_plongeon_coque(M)
	var titane: StandardMaterial3D = L._m(M, "titane119", Color(0.8, 0.83, 0.86), 0.3, 0.8)
	# le plancher : un tapis rond, cerclé de titane
	k.disc(Transform3D(Basis(), R.P(0, 0.012, 0)), 1.1, "tissu_gris", 24, 1.0)
	k.ring(Transform3D(Basis(), R.P(0, 0.0, 0)), 1.1, 1.16, 0.02, "argent", 24)
	# le sas, au plafond (près de la porte) : la trappe ronde et son volant
	var sas: Vector3 = R.P(0, R.H, 0.8)
	k.cyl(Transform3D(Basis(), sas + Vector3.DOWN * 0.05), 0.38, 0.38, 0.05, "argent", 20)
	k.ring(Transform3D(Basis(), sas + Vector3.DOWN * 0.07), 0.3, 0.38, 0.02, "fer", 20)
	var volant: Node3D = I._node(M, sas + Vector3.DOWN * 0.17)
	L._mesh(volant, L._tore(0.15, 0.18), titane)
	for sp in range(3):
		L._mesh(volant, I._boxm(Vector3(0.32, 0.015, 0.015)), titane, Transform3D(Basis(Vector3.UP, PI * sp / 3.0), Vector3.ZERO))
	L._mesh(volant, L._cylm(0.03, 0.03, 0.1, 10), titane, Transform3D(Basis(), Vector3(0, 0.05, 0)))
	# le tableau de bord : trois pupitres en arc (facettes 5, 6, 7), leurs dessus inclinés, une ligne de
	# diodes devant
	var tops: Array = []
	for ci in [5, 6, 7]:
		var dv: Vector3 = _plongeon_dir(ci)
		var cx := Transform3D(Basis.looking_at(dv, Vector3.UP), R.P(0, 0, 0) + dv * (r - 0.26))
		k.box(cx * Transform3D(Basis(), Vector3(0, 0.42, 0)), Vector3(0.94, 0.84, 0.5), "ceramique", 1.0)
		k.box(cx * Transform3D(Basis(), Vector3(0, 0.06, 0.26)), Vector3(0.94, 0.12, 0.02), "argent", 1.0)
		var top: Transform3D = cx * Transform3D(Basis(Vector3.RIGHT, 0.45), Vector3(0, 0.88, 0.02))
		k.box(top, Vector3(0.96, 0.04, 0.54), "noir", 1.0)
		k.col_box(cx * Transform3D(Basis(), Vector3(0, 0.45, 0)), Vector3(0.94, 0.9, 0.5))
		_diodes(M, cx * Vector3(-0.45, 0.78, 0.26) - R.P(0, 0, 0), cx * Vector3(0.45, 0.78, 0.26) - R.P(0, 0, 0))
		tops.append(top)
	R.reserve(0, -r + 0.35, 2.8, 0.9)
	var boutons: Array = ["lumiere", "tissu_rouge", "tissu_vert", "tissu_jaune"]
	for ti in range(3):
		var tp: Transform3D = tops[ti]
		for b in range(4):
			k.cyl(tp * Transform3D(Basis(), Vector3(-0.38 + b * 0.07, 0.02, 0.2)), 0.017, 0.017, 0.015, str(boutons[(b + ti) % 4]), 8)
	# au milieu : le sonar (et son trait qui balaie), le manche
	var flat := Basis(Vector3.RIGHT, -PI * 0.5)
	_marees_panneau(M, tops[1] * Transform3D(flat, Vector3(0, 0.025, -0.07)), Vector2(0.34, 0.3), _marees_ecran(M, "nuees/radar.png", 1.1))
	var balai: Node3D = I._node(M, Vector3.ZERO)
	balai.global_transform = tops[1] * Transform3D(Basis(), Vector3(0, 0.03, -0.07))
	L._mesh(balai, I._boxm(Vector3(0.006, 0.003, 0.13)), L._m(M, "sonar119", Color(0.4, 1.0, 0.5), 0.3, 0.0, 2.5), Transform3D(Basis(), Vector3(0, 0, 0.065)))
	L._tourne(M, balai, Vector3.UP, 1.6)
	k.cyl(tops[1] * Transform3D(Basis(), Vector3(0, 0.02, 0.17)), 0.04, 0.05, 0.02, "argent", 12)
	k.cyl(tops[1] * Transform3D(Basis(), Vector3(0, 0.03, 0.17)), 0.012, 0.012, 0.13, "argent", 6)
	k.cyl(tops[1] * Transform3D(Basis(), Vector3(0, 0.15, 0.17)), 0.03, 0.03, 0.05, "tissu_jaune", 10)
	# à gauche : la profondeur (en chiffres qui luisent) et la plaque « 200 »
	_marees_panneau(M, tops[0] * Transform3D(flat, Vector3(-0.05, 0.023, -0.08)), Vector2(0.4, 0.18), L._m(M, "fond119", Color(0.02, 0.08, 0.12), 0.4, 0.0, 0.3))
	var prof_lab: Label3D = _plongeon_texte(M, tops[0] * Transform3D(flat, Vector3(-0.05, 0.026, -0.08)), "%d m" % 140, 0.0021, Color(0.45, 1.0, 0.9))
	k.box(tops[0] * Transform3D(Basis(), Vector3(0.33, 0.025, 0.08)), Vector3(0.16, 0.008, 0.08), "argent", 1.0)
	_plongeon_texte(M, tops[0] * Transform3D(flat, Vector3(0.33, 0.031, 0.08)), "200", 0.0009, Color(0.2, 0.22, 0.26))
	# à droite : les courbes, et la manette des ballasts (son levier bascule quand on plonge)
	_marees_panneau(M, tops[2] * Transform3D(flat, Vector3(-0.12, 0.025, -0.07)), Vector2(0.38, 0.24), _marees_ecran(M, "nuees/ecran_mesures.png", 0.9))
	k.box(tops[2] * Transform3D(Basis(), Vector3(0.3, 0.025, 0.05)), Vector3(0.08, 0.02, 0.22), "fer", 1.0)
	var socle: Node3D = I._node(M, Vector3.ZERO)
	socle.global_transform = tops[2] * Transform3D(Basis(), Vector3(0.3, 0.03, 0.05))
	var levier := Node3D.new()
	socle.add_child(levier)
	L._mesh(levier, L._cylm(0.012, 0.012, 0.2, 8), titane, Transform3D(Basis(), Vector3(0, 0.1, 0)))
	L._mesh(levier, I._sph(0.032), L._m(M, "pommeau119", Color(0.85, 0.15, 0.1), 0.35), Transform3D(Basis(), Vector3(0, 0.21, 0)))
	# le manomètre, au-dessus du tableau de bord, entre les deux gros hublots
	var d6: Vector3 = _plongeon_dir(6)
	var mano: Node3D = I._node(M, Vector3.ZERO)
	mano.global_transform = Transform3D(Basis.looking_at(d6, Vector3.UP), R.P(0, 1.58, 0) + d6 * (r - 0.03))
	L._mesh(mano, L._cylm(0.15, 0.15, 0.03, 24), L._m(M, "cadran119", Color(0.96, 0.95, 0.9), 0.4), Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0, -0.01)))
	L._mesh(mano, L._tore(0.14, 0.17), titane, Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO))
	for g in range(9):
		var ag: float = -2.2 + g * 0.55
		L._mesh(mano, I._boxm(Vector3(0.008, 0.025, 0.004)), L._fer(M), Transform3D(Basis(Vector3.BACK, ag), Vector3(0, 0, 0.008)) * Transform3D(Basis(), Vector3(0, 0.11, 0)))
	var aig := Node3D.new()
	mano.add_child(aig)
	aig.position = Vector3(0, 0, 0.012)
	L._mesh(aig, I._boxm(Vector3(0.01, 0.12, 0.004)), L._m(M, "aiguille119", Color(0.85, 0.15, 0.1), 0.5), Transform3D(Basis(), Vector3(0, 0.05, 0)))
	L._mesh(mano, I._sph(0.018), titane, Transform3D(Basis(), Vector3(0, 0, 0.014)))
	# les hublots : les deux gros devant (facettes 5 et 7), deux petits sur les côtés (3 et 9) ; les
	# poissons-lanternes qui passent ; l'ombre et l'œil du calmar, sur le grand hublot de gauche
	var hubs: Array = []
	for e in [[5, 1.52, 0.4], [7, 1.52, 0.4], [3, 1.42, 0.26], [9, 1.42, 0.26]]:
		var dvh: Vector3 = _plongeon_dir(int(e[0]))
		var hp: Vector3 = R.P(0, float(e[1]), 0) + dvh * (r - 0.03)
		hubs.append([_hublot(M, Transform3D(Basis.looking_at(dvh, Vector3.UP), hp), float(e[2])), float(e[2])])
	M.ctx["banc119"] = 5
	_plongeon_banc(M, hubs, 14)
	var h0: Node3D = hubs[0][0]
	var ombre: StandardMaterial3D = _plongeon_ombre(h0, 0.4)
	var oeil := Node3D.new()
	h0.add_child(oeil)
	oeil.visible = false
	L._mesh(oeil, I._sph(0.075), L._m(M, "oeil119", Color(1.0, 0.8, 0.35), 0.3, 0.0, 1.6), Transform3D(Basis.from_scale(Vector3(1.0, 0.75, 0.12)), Vector3.ZERO))
	L._mesh(oeil, I._sph(0.04), L._m(M, "pupille119", Color(0.02, 0.02, 0.03), 0.4), Transform3D(Basis.from_scale(Vector3(0.5, 1.0, 0.12)), Vector3(0, 0, 0.005)))
	# les sièges : la pilote face au tableau de bord, un passager face au hublot de droite ; un
	# strapontin replié sous le hublot de gauche
	_plongeon_siege(M, 0.0, -0.75, 180.0, "bleu")
	_plongeon_siege(M, 1.2, -0.2, 90.0, "bleu")
	var d3: Vector3 = _plongeon_dir(3)
	var sx3 := Transform3D(Basis.looking_at(d3, Vector3.UP), R.P(0, 0, 0) + d3 * (r - 0.06))
	k.box(sx3 * Transform3D(Basis(), Vector3(0, 0.75, 0.0)), Vector3(0.42, 0.5, 0.06), "tissu_bleu", 1.0)
	k.box(sx3 * Transform3D(Basis(), Vector3(0, 0.48, 0.02)), Vector3(0.46, 0.04, 0.08), "argent", 1.0)
	# les bouteilles d'oxygène (facette 4), le ciré jaune de Lou (facette 8)
	var d4: Vector3 = _plongeon_dir(4)
	var t4 := Vector3(-d4.z, 0, d4.x)
	for sb in [-1.0, 1.0]:
		var bp: Vector3 = R.P(0, 0, 0) + d4 * (r - 0.16) + t4 * (sb * 0.14)
		k.cyl(Transform3D(Basis(), bp), 0.09, 0.09, 0.95, "tissu_vert", 12)
		k.cyl(Transform3D(Basis(), bp + Vector3.UP * 0.95), 0.09, 0.03, 0.08, "tissu_vert", 12)
		k.cyl(Transform3D(Basis(), bp + Vector3.UP * 1.03), 0.025, 0.025, 0.07, "argent", 8)
		k.col_cyl(bp, 0.1, 1.1)
	k.box(Transform3D(Basis.looking_at(d4, Vector3.UP), R.P(0, 0.7, 0) + d4 * (r - 0.07)), Vector3(0.5, 0.05, 0.03), "argent", 1.0)
	var d8: Vector3 = _plongeon_dir(8)
	var cx8 := Transform3D(Basis.looking_at(d8, Vector3.UP), R.P(0, 0, 0) + d8 * (r - 0.06))
	k.cyl(cx8 * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 1.85, 0.0)), 0.015, 0.015, 0.06, "argent", 6)
	k.box(cx8 * Transform3D(Basis(Vector3.RIGHT, 0.06), Vector3(0, 1.42, 0.04)), Vector3(0.4, 0.78, 0.05), "tissu_jaune", 1.0)
	k.box(cx8 * Transform3D(Basis(), Vector3(0, 1.82, 0.05)), Vector3(0.18, 0.08, 0.05), "tissu_jaune", 1.0)
	# la boîte à goûter (facette 2) et le journal de bord (facette 10), près de la porte
	var d2: Vector3 = _plongeon_dir(2)
	var cx2 := Transform3D(Basis.looking_at(d2, Vector3.UP), R.P(0, 0, 0) + d2 * (r - 0.15))
	k.box(cx2 * Transform3D(Basis(), Vector3(0, 0.95, 0)), Vector3(0.5, 0.4, 0.26), "ceramique", 1.0)
	k.box(cx2 * Transform3D(Basis(), Vector3(0, 0.95, 0.135)), Vector3(0.44, 0.34, 0.01), "argent", 1.0)
	k.box(cx2 * Transform3D(Basis(), Vector3(0, 1.21, 0.0)), Vector3(0.32, 0.12, 0.2), "tissu_jaune", 1.0)
	k.box(cx2 * Transform3D(Basis(), Vector3(0, 1.28, 0.0)), Vector3(0.34, 0.02, 0.22), "argent", 1.0)
	k.col_box(cx2 * Transform3D(Basis(), Vector3(0, 1.0, 0)), Vector3(0.5, 0.6, 0.26))
	var d10: Vector3 = _plongeon_dir(10)
	var cx10 := Transform3D(Basis.looking_at(d10, Vector3.UP), R.P(0, 0, 0) + d10 * (r - 0.12))
	k.box(cx10 * Transform3D(Basis(), Vector3(0, 1.0, 0)), Vector3(0.5, 0.03, 0.22), "argent", 1.0)
	k.box(cx10 * Transform3D(Basis(Vector3.UP, 0.2), Vector3(-0.05, 1.035, 0.01)), Vector3(0.24, 0.04, 0.17), "tissu_bleu", 1.0)
	k.box(cx10 * Transform3D(Basis(Vector3.UP, 0.2), Vector3(-0.05, 1.035, 0.01)), Vector3(0.22, 0.045, 0.15), "papier", 1.0)
	k.box(cx10 * Transform3D(Basis(Vector3.UP, -0.5), Vector3(0.15, 1.025, 0.04)), Vector3(0.14, 0.012, 0.012), "tissu_rouge", 1.0)
	# Bloup, le canard porte-bonheur, pendu au plafond : il se balance (beaucoup, en plongée)
	var bloup: Node3D = I._node(M, R.P(0.55, R.H - 0.02, -0.95))
	L._mesh(bloup, L._cylm(0.003, 0.003, 0.34, 4), L._m(M, "fil119", Color(0.2, 0.2, 0.22), 0.8), Transform3D(Basis(), Vector3(0, -0.17, 0)))
	var jaune: StandardMaterial3D = L._m(M, "canard119", Color(1.0, 0.82, 0.1), 0.45)
	L._mesh(bloup, I._sph(0.045), jaune, Transform3D(Basis.from_scale(Vector3(1.0, 0.8, 1.3)), Vector3(0, -0.4, 0)))
	L._mesh(bloup, I._sph(0.03), jaune, Transform3D(Basis(), Vector3(0, -0.345, 0.04)))
	L._mesh(bloup, I._boxm(Vector3(0.022, 0.008, 0.028)), L._m(M, "bec119", Color(1.0, 0.5, 0.1), 0.5), Transform3D(Basis(), Vector3(0, -0.35, 0.075)))
	for se in [-1.0, 1.0]:
		L._mesh(bloup, I._sph(0.006), L._fer(M), Transform3D(Basis(), Vector3(se * 0.017, -0.335, 0.066)))
	# ce qui bouge : Bloup, l'aiguille du manomètre, les chiffres de la profondeur
	M.ctx["prof119"] = 140.0
	M.ctx["cible119"] = 140.0
	M.ctx["roulis119"] = 0.0
	L._chaque(M, func(delta: float, t: float) -> void:
		var p: float = float(M.ctx.get("prof119", 140.0))
		var c: float = float(M.ctx.get("cible119", 140.0))
		if absf(c - p) > 0.05:
			p = move_toward(p, c, delta * 9.0)
			M.ctx["prof119"] = p
			if is_instance_valid(prof_lab):
				prof_lab.text = "%d m" % int(round(p))
		if is_instance_valid(aig):
			aig.rotation.z = 1.9 - (p - 100.0) / 120.0 * 3.2 + sin(t * 3.0) * 0.015
		if is_instance_valid(bloup):
			var a: float = 0.05 + float(M.ctx.get("roulis119", 0.0)) * 0.22
			bloup.rotation = Vector3(sin(t * 1.6) * a, 0.0, sin(t * 1.1 + 1.0) * a * 0.7))
	# les lumières : la lueur du tableau de bord, une lampe de cabine ; tout est plus doux la nuit
	L._lampe(M, R.P(0, 1.15, -1.2), Color(0.4, 0.95, 0.9), 0.5, 2.4)
	L._lampe(M, R.P(0, 2.0, 0.3), Color(1.0, 0.92, 0.75), 0.5, 3.5)
	if nuit:
		for l in R.lights:
			if is_instance_valid(l):
				(l as OmniLight3D).light_energy *= 0.55
	# les gens
	if nuit:
		var meca: Node = L._gens(M, "vieux", 1.2, -0.2, 90.0, "lire", ["La nuit, le Petit Plongeon fait de petits bruits : « tic », « bloup », « hmm ». Je les note tous. Yolande les lit le matin, avec son café.",
			"Chut… il dort. Enfin, ses ballasts dorment. Moi, je veille. C'est moi le mécanicien de garde, cette nuit."])
		L._causer(M, meca, ["Bonsoir ! Bonnes bulles. Doucement : le Petit Plongeon dort, les hublots ouverts.", "Tiens, de la visite ! Assieds-toi au poste de pilotage, si tu veux. Mais on ne plonge pas : c'est la nuit."],
			[["nuit", "Pourquoi garder le Petit Plongeon la nuit ?", ["Quelqu'un doit écouter les joints. Un bathyscaphe, ça parle tout bas, la nuit. Je note tout dans un carnet, Yolande le lit le matin. Elle dit que c'est le meilleur journal du Dôme. Il n'y a jamais de mauvaises nouvelles dedans."]],
			["plonger", "On peut plonger ?", ["La nuit ? Jamais. Le Petit Plongeon dort, et Lou aussi. Mais si tu allumes les projecteurs, tu verras la nuit de la Fosse. Elle est bien plus allumée que la nôtre."]]])
		M.ctx["entree"] = "Le Petit Plongeon, la nuit : la cabine ronde ne brille plus que par son tableau de bord ; derrière les hublots, la mer est noire, piquée de petites lumières qui passent."
	elif lou_la:
		var lou: Node = M.person("femme", 0.0, -0.75, 180.0, "assis", "Lou Grenadier")
		lou.lines = ["Doucement, mon canard. Encore dix mètres… Bon, d'accord, on est au quai. Mais il aime bien que je lui parle.",
			"Ballasts, vérifiés. Projecteurs, vérifiés. Sandwichs, vérifiés deux fois. On peut plonger !"]
		L._causer(M, lou, ["Salut ! Bienvenue à bord du Petit Plongeon ! Oui, c'est petit. Rentre le ventre, assieds-toi, et touche avec les yeux.", "Hé, mon passager ! Bonnes bulles ! Tu tombes bien : je m'apprêtais à faire un petit tour dans la Faille."],
			[["plonger", "On peut plonger ?", ["Bien sûr ! Pousse la manette des ballasts, là, à droite. Pas trop fort. La Faille commence juste sous le Bassin, et ma limite, c'est deux cents mètres. Yolande l'a gravée sur le tableau de bord. Tu verras."]],
			["canard", "Pourquoi un canard au plafond ?", ["C'est Bloup, mon porte-bonheur ! Quand il se balance, c'est qu'on bouge. Quand il ne se balance plus, c'est qu'on est arrivés. C'est mon meilleur instrument de bord. Yolande n'est pas d'accord."]],
			["chanteuse", "Tu as déjà vu la Grande Chanteuse ?", ["Une fois, de tout près. Elle est passée au-dessus du Petit Plongeon, et tout est devenu noir pendant une minute entière. Puis elle a chanté. Les hublots vibraient. J'ai pleuré dans mon sandwich. Il était quand même très bon."]]])
		var pas: Node = L._gens(M, "garcon", 1.2, -0.2, 90.0, "assis", ["Regarde ! Un poisson avec une lampe sur la tête ! Comme un mineur des Strates !",
			"Quand je serai grand, je serai pilote de bathyscaphe. Ou calmar. Je n'ai pas encore choisi."])
		L._causer(M, pas, ["Chut ! Je compte les poissons-lanternes. J'en suis à… je ne sais plus. Bonjour !", "Salut ! Lou a dit que je pouvais rester si je ne touchais à rien. Je ne touche à rien. Je regarde fort."],
			[["calmar", "Il y a des calmars, dehors ?", ["Lou dit qu'il y en a un très grand, qui s'appelle Augustin. Il est timide. Il passe devant le hublot, il te regarde avec un œil grand comme une assiette, et il s'en va. Moi, je l'attends. J'ai apporté un dessin pour lui."]]])
		M.ctx["entree"] = str(L._pick(M, ["Tu te glisses par l'écoutille dans le Petit Plongeon : une cabine toute ronde, deux gros hublots sur la mer bleue, un tableau de bord qui clignote, et Lou aux commandes.",
			"« Bienvenue à bord ! Attention à la tête ! » La cabine du Petit Plongeon est si petite qu'on y entend battre son cœur. Et le « bloup » des ballasts.",
			"Derrière les deux gros hublots, la mer bleue du Bassin. Au plafond, un canard en plastique se balance. Lou se retourne : « Tu viens plonger ? »"]))
	else:
		var app: Node = L._gens(M, "femme", 0.0, -0.75, 180.0, "lire", ["Liste de plongée : ballasts, oxygène, projecteurs, goûter. Lou dit que le goûter, c'est le plus important. Je commence à la croire.",
			"Je compte les bulles du Petit Plongeon depuis trois ans. Quarante mille ! Lou dit qu'il en faut cent mille pour devenir pilote."])
		L._causer(M, app, ["Bonnes bulles ! Je suis l'apprentie de Lou. Elle n'est pas là, mais je peux te faire faire une plongée d'essai, juste au bord de la Faille.", "Bonjour ! Tu cherches Lou ? Moi, je garde le Petit Plongeon. Assieds-toi, on va faire une petite plongée d'essai."],
			[["lou", "Où est Lou ?", ["Le matin, sur le quai du Bassin, à vérifier les ballasts. À midi, à La Conque, chez Josette. Et le soir, à l'Atelier de Yolande, à se faire gronder pour une vis. Elle revient toujours ici, dans la journée. Le Petit Plongeon s'ennuie sans elle."]],
			["apprentie", "Tu seras pilote, un jour ?", ["J'espère ! Lou dit que c'est comme ça qu'elle a commencé : en comptant les bulles du vieux bathyscaphe. Moi, je compte celles du Petit Plongeon. Et je parle à Bloup. Ça aussi, ça compte."]]])
		var mec: Node = L._gens(M, "homme", 1.2, -0.2, 90.0, "assis", ["Yolande m'a envoyé vérifier les joints du hublot de droite. Ils sont parfaits. Je vérifie quand même. Avec Yolande, on vérifie toujours deux fois.",
			"J'ai revissé quarante-deux écrous ce matin. Ils étaient bien vissés. Ils le sont encore plus."])
		L._causer(M, mec, ["Bonjour ! Pardon, je surveille ce hublot. Il ne fait rien de spécial. C'est bon signe.", "Bonnes bulles ! Tu es venu voir le plus beau sous-marin du monde ? C'est aussi le seul du Dôme. Ça aide."],
			[["yolande", "Yolande est sévère ?", ["Sévère ? Elle tapote chaque vitre du Dôme deux fois par jour. Mais quand Lou remonte d'une plongée, elle est toujours sur le quai, « par hasard », avec deux chocolats. Je ne dis rien. Personne ne dit rien. C'est notre secret à tous."]]])
		M.ctx["entree"] = str(L._pick(M, ["Le Petit Plongeon : une cabine ronde, jaune, à peine plus grande qu'une armoire, deux gros hublots sur la mer, et un tableau de bord qui clignote doucement.",
			"Tu te glisses dans le Petit Plongeon. Ça sent le métal, le caoutchouc, et un peu le sandwich. Au plafond, un canard en plastique te regarde entrer.",
			"Derrière les gros hublots, la mer bleue du Bassin. Un poisson-lanterne passe, sa petite lumière allumée. L'apprentie de Lou lève le nez de sa liste."]))
	# ce qu'on fait : plonger (ou, la nuit, allumer les projecteurs), lire la plaque, regarder par le
	# hublot, ouvrir la boîte à goûter, lire le journal de bord
	var lev_pos: Vector3 = R.P(0.8, 1.0, -1.1)
	var mer: StandardMaterial3D = _mer(M)
	if not nuit:
		var debut: Array = ["« Plongée d'essai, juste au bord de la Faille ! » L'apprentie pousse la manette avec toi. Le Petit Plongeon fait « bloup », et le bleu s'assombrit derrière les hublots.",
			"La manette bascule, les ballasts se remplissent dans un grand gargouillis, et le Petit Plongeon descend doucement. « Ne le dis pas à Lou, chuchote l'apprentie. Enfin, si. Elle sera fière. »"]
		if lou_la:
			debut = ["« Ballasts pleins ! On plonge ! » Lou pousse la manette avec toi. Le Petit Plongeon fait « bloup », glisse sous le Dôme, et le bleu s'assombrit doucement derrière les hublots.",
				"« Accroche-toi à Bloup ! » La manette bascule, les ballasts gargouillent, et le Petit Plongeon s'enfonce dans la Faille. Les chiffres de la profondeur se mettent à défiler."]
		M.act(lev_pos, "E : plonger", func() -> void:
			if bool(M.ctx.get("plonge119", false)):
				M.say("On est déjà en plongée ! Regarde plutôt par les hublots.", 4.0)
				return
			M.ctx["plonge119"] = true
			var lums: Array = []
			for l2 in R.lights:
				if is_instance_valid(l2):
					lums.append([l2, (l2 as OmniLight3D).light_energy])
			var c0: Color = mer.albedo_color
			var e0: float = mer.emission_energy_multiplier
			M.main.sfx("levier", lev_pos)
			var tw0: Tween = M.room.create_tween()
			tw0.tween_property(levier, "rotation:x", 0.8, 0.4)
			tw0.tween_property(levier, "rotation:x", 0.0, 0.8).set_delay(1.2)
			M.say(str(L._pick(M, debut)), 6.0)
			await M.get_tree().create_timer(1.0).timeout
			if not _la(M, room0):
				return
			M.main.sfx("bulles", lev_pos)
			M.ctx["cible119"] = 192.0
			M.ctx["roulis119"] = 1.0
			M.ctx["banc119"] = 14
			M.ctx["courant119"] = 1.6
			var tw: Tween = M.room.create_tween()
			tw.set_parallel(true)
			tw.tween_property(mer, "albedo_color", Color(0.01, 0.03, 0.07), 6.0)
			tw.tween_property(mer, "emission_energy_multiplier", 0.12, 6.0)
			for e2 in lums:
				tw.tween_property(e2[0], "light_energy", float(e2[1]) * 0.35, 6.0)
			await M.get_tree().create_timer(7.0).timeout
			if not _la(M, room0):
				return
			var st: Dictionary = M.state()
			var nb: int = int(st.get("plongees119", 0))
			st["plongees119"] = nb + 1
			if nb == 0 or L._r(M).randf() < 0.5:
				M.main.sfx("bulles", hubs[0][0].global_position)
				_plongeon_calmar(M, ombre, oeil)
				M.say(str(L._pick(M, ["Une ombre immense glisse devant le grand hublot. Puis un œil s'ouvre, doré, grand comme une assiette… Un calmar géant ! Il te regarde, cligne doucement, et s'en va. « C'est Augustin, chuchote-t-on derrière toi. Il est très timide. Et très gentil. »",
					"Tout devient noir derrière le hublot de gauche. Un œil doré apparaît, très calme, très grand. Le calmar géant te regarde un long moment, comme on regarde un aquarium. Puis il cligne de l'œil, et repart dans la nuit de la Faille."])), 9.0)
				await M.get_tree().create_timer(9.0).timeout
			else:
				M.say(str(L._pick(M, ["Cent quatre-vingt-dix mètres. Derrière les hublots, c'est presque la nuit. Des dizaines de poissons-lanternes passent, chacun avec sa petite lampe. On dirait une procession qui rentre d'une fête.",
					"Le Petit Plongeon flotte au bord de la Faille. Dehors, des points de lumière bleus et dorés s'allument et s'éteignent tout autour. Bloup se balance. Tout le monde chuchote, sans savoir pourquoi."])), 7.0)
				await M.get_tree().create_timer(7.0).timeout
			if not _la(M, room0):
				return
			M.main.sfx("bulles", lev_pos)
			M.say(str(L._pick(M, ["« On remonte ! » Le Petit Plongeon vide ses ballasts dans un grand gargouillis. Le bleu revient, puis la lumière du Bassin. Bloup se balance encore un peu, très content.",
				"Les ballasts se vident, les chiffres remontent, et la lumière bleue revient derrière les hublots. « Cent quarante mètres, tout le monde descend ! Enfin… tout le monde remonte. »"])), 6.0)
			M.ctx["cible119"] = 140.0
			M.ctx["roulis119"] = 0.4
			var tw2: Tween = M.room.create_tween()
			tw2.set_parallel(true)
			tw2.tween_property(mer, "albedo_color", c0, 5.0)
			tw2.tween_property(mer, "emission_energy_multiplier", e0, 5.0)
			for e3 in lums:
				tw2.tween_property(e3[0], "light_energy", float(e3[1]), 5.0)
			await M.get_tree().create_timer(6.5).timeout
			if not _la(M, room0):
				return
			M.ctx["roulis119"] = 0.0
			M.ctx["banc119"] = 5
			M.ctx["courant119"] = 1.0
			M.ctx["plonge119"] = false
		, 0.9)
	else:
		M.act(lev_pos, "E : allumer les projecteurs", func() -> void:
			if bool(M.ctx.get("plonge119", false)):
				return
			M.ctx["plonge119"] = true
			M.main.sfx("levier", lev_pos)
			var c0: Color = mer.albedo_color
			var e0: float = mer.emission_energy_multiplier
			M.ctx["banc119"] = 14
			var tw: Tween = M.room.create_tween()
			tw.set_parallel(true)
			tw.tween_property(mer, "albedo_color", Color(0.08, 0.32, 0.42), 1.0)
			tw.tween_property(mer, "emission_energy_multiplier", 1.4, 1.0)
			M.say(str(L._pick(M, ["Tu allumes les projecteurs : la nuit de la Fosse s'éclaire d'un coup. Des poissons-lanternes, des crevettes blanches, une pluie de neige marine qui tombe tout doucement. « Pas trop longtemps, dit le mécanicien. Ils dorment, eux aussi. »",
				"Clac ! Les projecteurs s'allument. Derrière les hublots, des dizaines de petits poissons-lanternes s'arrêtent, étonnés, puis repartent. On dirait qu'ils ont été surpris en pyjama."])), 8.0)
			await M.get_tree().create_timer(9.0).timeout
			if not _la(M, room0):
				return
			M.main.sfx("ui_clic", lev_pos)
			var tw2: Tween = M.room.create_tween()
			tw2.set_parallel(true)
			tw2.tween_property(mer, "albedo_color", c0, 2.0)
			tw2.tween_property(mer, "emission_energy_multiplier", e0, 2.0)
			await M.get_tree().create_timer(2.0).timeout
			if not _la(M, room0):
				return
			M.ctx["banc119"] = 5
			M.ctx["plonge119"] = false
		, 0.9)
	M.act(R.P(-0.75, 1.0, -1.15), "E : lire la plaque", func() -> void:
		M.say(PLONGEON_PLAQUE, 7.0)
	, 0.8)
	M.act(R.P(-1.3, 1.3, -0.25), "E : regarder par le hublot", func() -> void:
		if L._nuit(M):
			M.say(str(L._pick(M, ["La nuit, derrière le hublot, la mer est noire. Mais pas vide : de petites lumières clignotent partout, bleues, vertes, dorées. La Fosse a ses étoiles, elle aussi.",
				"Un poisson-lanterne s'approche du hublot, sa petite lampe allumée au bout du nez. Il te regarde, tu le regardes. Il repart. Vous vous êtes compris."])), 7.0)
		else:
			M.say(str(L._pick(M, ["Par le hublot : le bleu profond du Bassin, la paroi de la Faille couverte d'éponges de verre, et un poisson-lanterne qui passe, sa petite lumière allumée, comme quelqu'un qui rentre chez lui.",
				"Une méduse passe tout près du hublot, lente, transparente, avec des franges qui s'allument. Elle a l'air de te regarder. Le Professeur Benthos lui a sûrement déjà donné un nom."])), 7.0)
	, 1.0)
	M.act(R.P(-1.17, 1.1, 0.68), "E : ouvrir la boîte à goûter", func() -> void:
		M.main.sfx("ui_ouvrir", R.P(-1.17, 1.1, 0.68))
		var st: Dictionary = M.state()
		if bool(st.get("plongeon119", false)):
			M.say(str(L._pick(M, ["La boîte à goûter est presque vide. Il reste un sandwich, avec un mot : « Pour Lou. Pas touche. Y. »",
				"Dans la boîte, une pomme, deux sandwichs, et une étiquette : « Règle numéro un des pilotes : jamais de plongée sans goûter. » Tu refermes la boîte. Tu as déjà eu ta part."])), 6.0)
			return
		st["plongeon119"] = true
		M.give([["chocolat_abysses", 1]], "La boîte à goûter de Lou : des sandwichs, une pomme, et des chocolats. Sur le couvercle : « Règle numéro un des pilotes : jamais de plongée sans goûter. Servez-vous, l'équipage ! » Tu fais partie de l'équipage. ")
	, 0.9)
	M.act(R.P(1.17, 1.1, 0.68), "E : lire le journal de bord", func() -> void:
		M.main.sfx("ui_ouvrir", R.P(1.17, 1.1, 0.68))
		var n: int = int(M.ctx.get("journal119", 0))
		M.ctx["journal119"] = n + 1
		M.say(str(PLONGEON_JOURNAL[n % PLONGEON_JOURNAL.size()]), 8.0)
	, 0.9)


# =================================================================== la Salle des Marées

## LA SALLE DES MARÉES (da_marees) : à l'étage de la Maison du Conseil, la grande salle où siège le
## Conseil des Marées : la table de nacre en arc et sa ligne de diodes, les fauteuils (celui de la
## Présidente, adossé à une grande coquille ; le fauteuil vide gardé pour l'Atlantide), l'horloge des
## marées au mur du fond (la marée d'en haut, qu'on n'a pas ici), la maquette des trois dômes sous sa
## cloche de verre (la petite Perle, le petit Petit Plongeon), les écrans des courants et des mesures,
## l'affiche de la Perle, deux colonnes de bulles, la barre du public, le Livre des Marées sur son lutrin,
## le bureau de la greffière. Le jour, en séance, la Présidente Ondine Nacre (vouvoie), deux conseillers
## et la greffière (on vote à main levée) ; entre deux séances, des conseillers qui bavardent ; la nuit,
## le veilleur.
static func _marees(M) -> void:
	var R = M.R
	var k = R.kit
	var nuit: bool = L._nuit(M)
	var room0 = M.room
	var h: float = float(M.ctx.get("hour", 12.0))
	var seance: bool = not nuit and ((h >= 8.0 and h < 12.0) or (h >= 14.0 and h < 18.0))
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var c := Vector2(0.0, 0.6)
	var cw: Vector3 = R.P(c.x, 0, c.y)
	# la table du Conseil : un arc de nacre (de 200° à 340° autour de c), sa jupe, ses diodes
	var nseg: int = 14
	for i in range(nseg):
		var a0: float = deg_to_rad(200.0 + 140.0 * i / nseg)
		var a1: float = deg_to_rad(200.0 + 140.0 * (i + 1) / nseg)
		var am: float = (a0 + a1) * 0.5
		var dv := Vector3(cos(am), 0, sin(am))
		var p: Vector3 = cw + dv * 3.0
		var chord: float = 2.0 * 3.0 * sin((a1 - a0) * 0.5) + 0.04
		var bb := Basis.looking_at(-dv, Vector3.UP)
		k.box(Transform3D(bb, p + Vector3.UP * 0.76), Vector3(chord, 0.05, 0.82), "ceramique", 1.0)
		k.box(Transform3D(bb, p + Vector3.UP * 0.787), Vector3(chord, 0.005, 0.5), "tissu_turquoise", 1.0)
		k.box(Transform3D(bb, p - dv * 0.37 + Vector3.UP * 0.37), Vector3(chord * 0.96, 0.74, 0.04), "ceramique", 1.0)
		k.box(Transform3D(bb, p + Vector3.UP * 0.37), Vector3(0.08, 0.74, 0.08), "argent", 1.0)
		k.col_box(Transform3D(bb, p + Vector3.UP * 0.4), Vector3(chord, 0.8, 0.82))
		var ia: Vector3 = Vector3(c.x + cos(a0) * 2.6, 0.72, c.y + sin(a0) * 2.6)
		var ib: Vector3 = Vector3(c.x + cos(a1) * 2.6, 0.72, c.y + sin(a1) * 2.6)
		_diodes(M, ia, ib)
		R.reserve(c.x + dv.x * 3.0, c.y + dv.z * 3.0, 0.9, 0.9)
	# les fauteuils, derrière la table, tournés vers le milieu : les conseillers, la Présidente (au
	# milieu, sa grande coquille), le fauteuil vide de l'Atlantide (au bout, à droite)
	var places: Array = []
	for a in [210.0, 235.0, 270.0, 305.0, 330.0]:
		var ar: float = deg_to_rad(a)
		var px: float = c.x + cos(ar) * 3.8
		var pz: float = c.y + sin(ar) * 3.8
		places.append([px, pz, rad_to_deg(atan2(c.x - px, c.y - pz)), ar])
	for ip in range(places.size()):
		var pl: Array = places[ip]
		R.fauteuil(float(pl[0]), float(pl[1]), float(pl[2]), "blanc" if ip == 2 else ("bleu" if ip == 4 else "turquoise"))
		if ip != 4:
			var dvp := Vector3(cos(float(pl[3])), 0, sin(float(pl[3])))
			var sp: Vector3 = cw + dvp * 3.12 + Vector3.UP * 0.89
			k.box(Transform3D(Basis.looking_at(-dvp, Vector3.UP), sp - dvp * 0.06 + Vector3.DOWN * 0.05), Vector3(0.3, 0.1, 0.03), "argent", 1.0)
			_marees_panneau(M, Transform3D(Basis.looking_at(-dvp, Vector3.UP) * Basis(Vector3.RIGHT, -1.0), sp), Vector2(0.34, 0.22), _marees_ecran(M, "nuees/ecran_mesures.png", 0.6))
	var pres: Transform3D = R.L(float(places[2][0]), 0, float(places[2][1]), float(places[2][2]))
	for f in range(9):
		var af: float = -1.1 + f * 0.275
		k.box(pres * Transform3D(Basis(Vector3.BACK, af), Vector3(0, 0.95, -0.47)) * Transform3D(Basis(), Vector3(0, 0.55, 0)), Vector3(0.09, 1.1, 0.04), "ceramique", 1.0)
	k.box(pres * Transform3D(Basis(), Vector3(0, 0.95, -0.47)), Vector3(0.3, 0.12, 0.05), "argent", 1.0)
	var atl: Array = places[4]
	var coq: Node3D = I._node(M, R.P(float(atl[0]), 0.53, float(atl[1])), float(atl[2]))
	var nacre: StandardMaterial3D = L._m(M, "nacre119", Color(0.97, 0.93, 0.95), 0.2, 0.3)
	L._mesh(coq, I._sph(0.09), nacre, Transform3D(Basis.from_scale(Vector3(1.0, 0.35, 0.9)), Vector3.ZERO))
	for rb in range(5):
		L._mesh(coq, I._boxm(Vector3(0.012, 0.012, 0.16)), nacre, Transform3D(Basis(Vector3.UP, -0.6 + rb * 0.3), Vector3(0, 0.03, 0)))
	var dva := Vector3(cos(float(atl[3])), 0, sin(float(atl[3])))
	k.box(Transform3D(Basis.looking_at(-dva, Vector3.UP) * Basis(Vector3.RIGHT, -0.5), cw + dva * 3.2 + Vector3.UP * 0.82), Vector3(0.26, 0.1, 0.01), "ceramique", 1.0)
	# l'horloge des marées (au mur du fond) : le cadran, les repères, les deux aiguilles (la grande fait
	# le tour en une marée), « marée haute » en haut, « marée basse » en bas
	var hc: Vector3 = R.P(0, 3.05, -hd + 0.02)
	k.cyl(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), hc), 0.9, 0.9, 0.06, "ceramique", 36)
	k.ring(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), hc + Vector3.BACK * 0.0), 0.86, 0.97, 0.1, "argent", 36)
	for tk in range(12):
		var at: float = TAU * tk / 12.0
		var big: bool = tk % 3 == 0
		k.box(Transform3D(Basis(Vector3.BACK, -at), hc + Vector3(sin(at) * 0.72, cos(at) * 0.72, 0.07)), Vector3(0.04 if big else 0.025, 0.16 if big else 0.09, 0.01), "lumiere" if big else "argent", 1.0)
	_plongeon_texte(M, Transform3D(Basis(), hc + Vector3(0, 0.42, 0.075)), "MARÉE HAUTE", 0.0016, Color(0.15, 0.4, 0.5))
	_plongeon_texte(M, Transform3D(Basis(), hc + Vector3(0, -0.42, 0.075)), "MARÉE BASSE", 0.0016, Color(0.15, 0.4, 0.5))
	var gde: Node3D = I._node(M, hc + Vector3.BACK * 0.09)
	L._mesh(gde, I._boxm(Vector3(0.05, 0.66, 0.012)), L._m(M, "aiguille119b", Color(0.12, 0.3, 0.42), 0.4, 0.3), Transform3D(Basis(), Vector3(0, 0.28, 0)))
	L._mesh(gde, I._sph(0.05), L._m(M, "vague119", Color(0.35, 0.95, 0.9), 0.3, 0.0, 1.5), Transform3D(Basis(), Vector3(0, 0.62, 0.01)))
	gde.rotation.z = -fmod(h, 12.4) / 12.4 * TAU
	L._tourne(M, gde, Vector3.BACK, -0.03)
	var pte: Node3D = I._node(M, hc + Vector3.BACK * 0.1)
	L._mesh(pte, I._boxm(Vector3(0.06, 0.42, 0.012)), L._m(M, "aiguille119b", Color(0.12, 0.3, 0.42), 0.4, 0.3), Transform3D(Basis(), Vector3(0, 0.17, 0)))
	pte.rotation.z = -fmod(h, 12.0) / 12.0 * TAU
	L._mesh(I._node(M, hc + Vector3.BACK * 0.11), I._sph(0.06), L._m(M, "titane119", Color(0.8, 0.83, 0.86), 0.3, 0.8))
	R.mark_wall(0, 3.05, -hd, 1.0)
	# au mur du fond : l'enseigne du Conseil, l'affiche de la Grande Perle ; aux murs de côté, les écrans
	# des courants et des mesures ; une ligne de diodes sous le plafond
	_marees_panneau(M, R.L(-3.0, 3.5, -hd + 0.04), Vector2(1.6, 0.8), _marees_ecran(M, "dome115/enseigne_conseil.png", 0.8))
	R.mark_wall(-3.0, 3.5, -hd, 0.85)
	k.box(R.L(3.4, 2.15, -hd + 0.02), Vector3(1.17, 1.52, 0.03), "argent", 1.0)
	_marees_panneau(M, R.L(3.4, 2.15, -hd + 0.04), Vector2(1.05, 1.4), _marees_ecran(M, "dome119/affiche_perle.png", 0.0))
	R.mark_wall(3.4, 2.15, -hd, 0.65)
	for side in [-1.0, 1.0]:
		var sxw: float = side * (hw - 0.03)
		k.box(R.L(sxw, 2.35, 0.0, -90.0 * side), Vector3(1.92, 1.22, 0.03), "argent", 1.0)
		_marees_panneau(M, R.L(sxw - side * 0.02, 2.35, 0.0, -90.0 * side), Vector2(1.8, 1.1), _marees_ecran(M, "nuees/isobares.png" if side > 0.0 else "nuees/ecran_mesures.png", 0.9))
		R.mark_wall(side * hw, 2.35, 0.0, 0.95)
		_diodes(M, Vector3(side * (hw - 0.05), R.H - 0.22, -hd + 0.1), Vector3(side * (hw - 0.05), R.H - 0.22, hd - 0.3))
	_diodes(M, Vector3(-hw + 0.1, R.H - 0.22, -hd + 0.05), Vector3(hw - 0.1, R.H - 0.22, -hd + 0.05))
	# deux colonnes de bulles, dans les coins du fond
	for side2 in [-1.0, 1.0]:
		var bc: Vector3 = R.P(side2 * (hw - 0.7), 0, -hd + 0.6)
		k.cyl(Transform3D(Basis(), bc), 0.3, 0.32, 0.25, "ceramique", 18)
		k.cyl(Transform3D(Basis(), bc + Vector3.UP * (R.H - 0.25)), 0.3, 0.3, 0.25, "ceramique", 18)
		var tube: Node3D = I._node(M, bc + Vector3.UP * (R.H * 0.5))
		L._mesh(tube, L._cylm(0.26, 0.26, R.H - 0.5, 20, false), L._m(M, "tube119", Color(0.45, 0.85, 1.0, 0.2), 0.05, 0.0, 0.3, true))
		_marees_bulles(M, bc + Vector3.UP * 0.3, 0.26, R.H - 0.8, 26)
		k.col_cyl(bc, 0.34, R.H)
		R.reserve(side2 * (hw - 0.7), -hd + 0.6, 0.8, 0.8)
	# la maquette des trois dômes, sous sa cloche de verre (au milieu de l'arc)
	k.cyl(Transform3D(Basis(), cw), 0.46, 0.52, 0.95, "ceramique", 24)
	k.ring(Transform3D(Basis(), cw + Vector3.UP * 0.5), 0.46, 0.5, 0.03, "lumiere", 24)
	k.cyl(Transform3D(Basis(), cw + Vector3.UP * 0.95), 0.5, 0.5, 0.03, "argent", 24)
	k.col_cyl(cw, 0.55, 1.6)
	R.reserve(c.x, c.y, 1.3, 1.3)
	var mq: Node3D = I._node(M, cw + Vector3.UP * 0.98)
	L._mesh(mq, L._cylm(0.44, 0.44, 0.02, 28), L._m(M, "sable119", Color(0.6, 0.66, 0.72), 0.9), Transform3D(Basis(), Vector3(0, 0.01, 0)))
	var vitre: StandardMaterial3D = L._m(M, "domes119", Color(0.78, 0.93, 1.0, 0.4), 0.1, 0.0, 0.2, true)
	var blanc: StandardMaterial3D = L._m(M, "nacre119", Color(0.97, 0.93, 0.95), 0.2, 0.3)
	var domes: Array = [[Vector3(0, 0.02, 0), 0.16], [Vector3(-0.27, 0.02, -0.05), 0.09], [Vector3(0.26, 0.02, 0.07), 0.09]]
	for e in domes:
		var hs := SphereMesh.new()
		hs.radius = float(e[1])
		hs.height = float(e[1])
		hs.is_hemisphere = true
		hs.radial_segments = 20
		hs.rings = 8
		L._mesh(mq, hs, vitre, Transform3D(Basis(), e[0]))
		L._mesh(mq, L._tore(float(e[1]) - 0.005, float(e[1]) + 0.012), blanc, Transform3D(Basis(), e[0]))
		for bi in range(4):
			var ab: float = TAU * bi / 4.0 + 0.4
			L._mesh(mq, I._boxm(Vector3(0.025, 0.02, 0.025)), blanc, Transform3D(Basis(), (e[0] as Vector3) + Vector3(cos(ab), 0.4, sin(ab)) * float(e[1]) * 0.55))
	for gi in [1, 2]:
		var ga: Vector3 = domes[0][0]
		var gb: Vector3 = domes[gi][0]
		var gd: Vector3 = (gb - ga).normalized()
		L._mesh(mq, L._cylm(0.022, 0.022, ga.distance_to(gb), 8), vitre, Transform3D(Basis(Quaternion(Vector3.UP, gd)), (ga + gb) * 0.5 + Vector3.UP * 0.02))
	L._mesh(mq, L._cylm(0.012, 0.012, 0.36, 8), blanc, Transform3D(Basis(), Vector3(0, 0.2, 0)))
	var perle_m := StandardMaterial3D.new()
	perle_m.albedo_color = Color(0.6, 0.5, 1.0) if nuit else Color(1.0, 0.95, 0.8)
	perle_m.emission_enabled = true
	perle_m.emission = perle_m.albedo_color
	perle_m.emission_energy_multiplier = 1.2
	perle_m.roughness = 0.2
	L._mesh(mq, I._sph(0.035), perle_m, Transform3D(Basis(), Vector3(0, 0.13, 0)))
	var petit: Node3D = Node3D.new()
	mq.add_child(petit)
	L._mesh(petit, I._sph(0.02), L._m(M, "jaune119", Color(1.0, 0.82, 0.12), 0.4), Transform3D(Basis(), Vector3.ZERO))
	var cloche := SphereMesh.new()
	cloche.radius = 0.47
	cloche.height = 0.47
	cloche.is_hemisphere = true
	cloche.radial_segments = 28
	cloche.rings = 10
	L._mesh(mq, cloche, L._m(M, "cloche119", Color(0.85, 0.95, 1.0, 0.12), 0.05, 0.0, 0.0, true), Transform3D(Basis.from_scale(Vector3(1.0, 0.95, 1.0)), Vector3(0, 0.02, 0)))
	var mql: OmniLight3D = L._lampe(M, cw + Vector3.UP * 1.35, Color(0.6, 0.9, 1.0), 0.3, 2.5)
	M.ctx["maquette119"] = 0.0
	L._chaque(M, func(_dt: float, t: float) -> void:
		var boost: float = float(M.ctx.get("maquette119", 0.0))
		perle_m.emission_energy_multiplier = 1.2 + sin(t * 1.2) * 0.3 + boost * 2.0
		if is_instance_valid(petit):
			var plonge: float = absf(sin(t * 0.35)) if boost > 0.0 else 0.0
			petit.position = Vector3(0.3, 0.04 + sin(t * 1.4) * 0.006 - plonge * 0.03, 0.1))
	# le Livre des Marées, ouvert sur son lutrin (devant, à gauche), la boîte de nacre à côté
	var lt: Transform3D = R.L(-4.4, 0, 2.2, 115)
	k.box(lt * Transform3D(Basis(), Vector3(0, 0.55, 0)), Vector3(0.08, 1.1, 0.08), "argent", 1.0)
	k.box(lt * Transform3D(Basis(), Vector3(0, 0.02, 0)), Vector3(0.5, 0.04, 0.4), "argent", 1.0)
	k.box(lt * Transform3D(Basis(Vector3.RIGHT, 0.35), Vector3(0, 1.12, 0)), Vector3(0.62, 0.04, 0.46), "ceramique", 1.0)
	k.box(lt * Transform3D(Basis(Vector3.RIGHT, 0.35), Vector3(0, 1.145, 0)), Vector3(0.64, 0.012, 0.44), "tissu_turquoise", 1.0)
	for s3 in [-1.0, 1.0]:
		k.box(lt * Transform3D(Basis(Vector3.RIGHT, 0.35) * Basis(Vector3.FORWARD, s3 * 0.08), Vector3(s3 * 0.15, 1.16, 0)), Vector3(0.29, 0.02, 0.4), "papier", 1.0)
	k.box(lt * Transform3D(Basis(Vector3.BACK, 0.4), Vector3(0.36, 1.25, 0.05)), Vector3(0.012, 0.25, 0.04), "tissu_blanc", 1.0)
	k.box(lt * Transform3D(Basis(), Vector3(0.0, 1.0, -0.12)), Vector3(0.22, 0.06, 0.14), "ceramique", 1.0)
	k.col_box(lt * Transform3D(Basis(), Vector3(0, 0.6, 0)), Vector3(0.62, 1.2, 0.5))
	R.reserve(-4.4, 2.2, 1.0, 1.0)
	# le bureau de la greffière (devant, à droite) : les papiers, le tampon, sa chaise
	var gx: Transform3D = R.L(4.35, 0, 1.9, -90)
	k.box(gx * Transform3D(Basis(), Vector3(0, 0.74, 0)), Vector3(1.2, 0.05, 0.62), "ceramique", 1.0)
	k.box(gx * Transform3D(Basis(), Vector3(0, 0.36, 0.2)), Vector3(1.1, 0.72, 0.04), "ceramique", 1.0)
	for sg in [-1.0, 1.0]:
		k.box(gx * Transform3D(Basis(), Vector3(sg * 0.55, 0.36, 0)), Vector3(0.05, 0.72, 0.56), "argent", 1.0)
	for pp in range(4):
		k.box(gx * Transform3D(Basis(Vector3.UP, 0.25 * (pp - 1.5)), Vector3(-0.35 + pp * 0.2, 0.768, -0.05 + (pp % 2) * 0.08)), Vector3(0.21, 0.004, 0.29), "papier", 1.0)
	k.cyl(gx * Transform3D(Basis(), Vector3(0.42, 0.765, 0.1)), 0.04, 0.04, 0.03, "fer", 10)
	k.cyl(gx * Transform3D(Basis(), Vector3(0.42, 0.795, 0.1)), 0.015, 0.015, 0.08, "bois_sombre", 6)
	k.col_box(gx * Transform3D(Basis(), Vector3(0, 0.4, 0)), Vector3(1.2, 0.8, 0.62))
	R.reserve(4.35, 1.9, 0.8, 1.3)
	R.chaise(5.0, 1.9, -90.0, "turquoise")
	# la barre du public (de part et d'autre de l'allée), ses diodes
	for sr in [-1.0, 1.0]:
		var x0: float = sr * 1.2
		var x1: float = sr * 3.4
		for pst in range(4):
			k.cyl(R.L(lerpf(x0, x1, pst / 3.0), 0, 2.6), 0.03, 0.03, 0.95, "argent", 8)
		k.box(R.L((x0 + x1) * 0.5, 0.97, 2.6), Vector3(2.25, 0.06, 0.12), "ceramique", 1.0)
		_diodes(M, Vector3(x0, 0.92, 2.6), Vector3(x1, 0.92, 2.6))
		k.col_box(R.L((x0 + x1) * 0.5, 0.5, 2.6), Vector3(2.2, 1.0, 0.1))
		R.reserve((x0 + x1) * 0.5, 2.6, 2.4, 0.3)
	L._lampe(M, R.P(0, 3.6, -1.8), Color(1.0, 0.97, 0.92), 0.8 if not nuit else 0.3, 8.0)
	L._lampe(M, R.P(0, 3.4, -hd + 0.6), Color(0.5, 0.9, 1.0), 0.5, 3.5)
	# les gens
	var tous: Array = []
	if nuit:
		var veil: Node = L._gens(M, "vieux", -3.5, 1.7, 90.0, "mains_dos", ["La nuit, j'écoute l'horloge des marées. Elle ne fait pas tic-tac. Elle fait « chhh… chhh… », comme la mer, là-haut.",
			"Chut… Le Conseil dort. Le fauteuil de l'Atlantide aussi, je crois. Il a l'habitude."])
		L._va_et_vient(M, veil, R.P(-3.5, 0, 1.7), R.P(3.3, 0, 1.7), 0.5, 4.0)
		L._causer(M, veil, ["Bonsoir ! Bonnes bulles. La séance est levée depuis longtemps, mais tu peux regarder. Doucement.", "Tiens, un visiteur de nuit ! La maquette est jolie, à cette heure-ci : la petite Perle devient violette, comme la grande."],
			[["nuit", "Que fait-on ici, la nuit ?", ["On veille l'horloge, la maquette et le fauteuil vide. Et parfois, très tard, la Présidente monte relire le Livre des Marées. Elle croit que personne ne la voit. Moi, je regarde ailleurs. C'est mon métier : veiller, et regarder ailleurs quand il faut."]],
			["fauteuil", "Pourquoi un fauteuil vide ?", ["C'est celui de l'Atlantide, notre cousine. Personne ne sait où elle est. Mais on lui garde sa place depuis quatre-vingts ans. Je l'époussette tous les soirs. Au cas où elle arriverait de nuit."]]])
		tous.append(veil)
		M.ctx["entree"] = "La Salle des Marées, la nuit : la grande table en arc est vide, les écrans dorment, et seule l'aiguille de l'horloge des marées avance, très lentement, au-dessus du fauteuil de la Présidente."
	elif seance:
		var pr: Array = places[2]
		var ond: Node = M.person("vieille", float(pr[0]), float(pr[1]), float(pr[2]), "assis", "la Présidente Ondine Nacre")
		ond.lines = ["Respirons. La mer a le temps. Et nous aussi.", "Doucement, comme la marée. Qui demande la parole ?"]
		L._causer(M, ond, ["Bonnes bulles. Asseyez-vous où vous voulez, sauf dans le fauteuil vide, au bout de la table : il est réservé. Respirons. Voilà. La séance peut reprendre.",
			"Ah, un visiteur. Le Conseil des Marées vous souhaite la bienvenue. Ici, on décide lentement, comme la marée. Mais on décide bien."],
			[["marees", "Pourquoi « des Marées », si profond ?", ["À cent quarante mètres, il n'y a pas de marées. Nos fondateurs ont choisi ce nom quand même : une bonne décision, disaient-ils, c'est comme la marée. Elle monte lentement, et elle revient toujours. L'horloge, au mur, donne la marée d'en haut. Pour ne pas oublier que la mer respire."]],
			["seance", "De quoi parle la séance ?", ["De la pétition de la petite Mila, d'abord : que tous les enfants du Dôme voient le ciel. Nous l'avons votée. Maintenant, il faut organiser le voyage. C'est le plus difficile : on ne fait pas monter quatorze enfants de cent quarante mètres sans goûter."]],
			["fauteuil", "À qui est le fauteuil vide ?", ["À notre cousine l'Atlantide. Les vieilles cartes parlent d'une cité engloutie, sous une bulle d'air, quelque part au nord-est. Personne ici ne l'a jamais vue. Mais nous lui gardons sa place, au Conseil. On ne sait jamais. Et il serait impoli de la faire attendre debout."]]])
		tous.append(ond)
		var p0: Array = places[0]
		var cons1: Node = L._gens(M, "vieux", float(p0[0]), float(p0[1]), float(p0[2]), "lire", ["Je relis le dossier de la Fontaine des Bulles. Trois cents pages pour décider de ne rien changer. C'est du beau travail.",
			"Je siège ici depuis quarante ans. J'ai voté pour tous les hublots d'honneur. Il y en a eu onze. Dont une raie."])
		tous.append(cons1)
		var p1: Array = places[1]
		var cons2: Node = L._gens(M, "femme", float(p1[0]), float(p1[1]), float(p1[2]), "assis", ["Je demande la parole ! … Pour dire que je suis d'accord. C'est rare, profitons-en.",
			"Au Conseil des Marées, on vote à main levée. Et quand on hésite, à main à moitié levée."])
		L._causer(M, cons2, ["Bonnes bulles ! Un visiteur au Conseil, quelle bonne surprise. Ici, tout le monde peut écouter. Et même lever la main.", "Bonjour ! Chut… la Présidente réfléchit. Cela peut durer. C'est très bon signe."],
			[["vote", "Comment vote-t-on, ici ?", ["À main levée, comme nos grands-parents. Nous avons essayé les écrans, une fois : tout le monde votait si vite que plus personne ne réfléchissait. La Présidente a dit : « Respirons. » Et nous sommes revenus aux mains. Levez la vôtre, si vous voulez, à la barre du public."]]])
		tous.append(cons2)
		var p3: Array = places[3]
		tous.append(L._gens(M, "homme", float(p3[0]), float(p3[1]), float(p3[2]), "rire_assis", ["Ha ha ! Repeindre une fontaine en verre ! Je vote contre, des deux mains.",
			"Ma proposition à moi : un concert de la Grande Chanteuse sur la Place de la Perle. Il ne reste plus qu'à la prévenir."]))
		var gre: Node = L._gens(M, "femme", 5.0, 1.9, -90.0, "lire", ["J'écris tout ce qui se dit. Les soupirs de la Présidente, je les note comme des virgules.", "Le Livre des Marées, là-bas, c'est pour tout le monde. Mon registre, c'est pour l'histoire. Elle est plus bavarde."])
		L._causer(M, gre, ["Bonjour ! Je suis la greffière : j'écris tout ce que décide le Conseil. Lentement. Comme la marée.", "Bonnes bulles ! Chut, je note… Voilà. Que puis-je pour vous ?"],
			[["livre", "Qu'est-ce que le Livre des Marées ?", ["C'est une idée de la Présidente : un livre ouvert, sur le lutrin, où chacun écrit une phrase pour ceux qui vivront ici dans cent ans. Les enfants écrivent au crayon bleu. Le Professeur Benthos écrit en notes de musique. Personne ne sait les lire."]]])
		tous.append(gre)
		M.ctx["entree"] = str(L._pick(M, ["La Salle des Marées : une grande table de nacre en arc, des fauteuils blancs et turquoise, et au mur, une horloge qui donne la marée d'en haut. Le Conseil est en séance.",
			"« … et je propose donc de ne pas repeindre la Fontaine des Bulles. » Tu entres en pleine séance. La Présidente Ondine Nacre t'adresse un petit signe : ici, tout le monde peut écouter.",
			"Au milieu de la table en arc, sous une cloche de verre, les trois dômes en miniature brillent doucement. Autour, le Conseil des Marées réfléchit, sans se presser."]))
	else:
		var b1: Node = L._gens(M, "homme", -1.9, 1.6, 70.0, "rire", ["La séance reprend tout à l'heure. En attendant, on se dispute pour rire. C'est un bon entraînement.",
			"La Présidente est partie respirer. Elle dit qu'on décide mieux après une promenade."])
		L._causer(M, b1, ["Bonnes bulles ! C'est la pause. Le Conseil se repose, la marée aussi.", "Bonjour ! Vous cherchez la Présidente ? Elle revient. Elle revient toujours, comme la marée."],
			[["presidente", "Où est la Présidente ?", ["Le matin, au balcon du Conseil, à regarder la Grande Perle s'allumer. À midi, à La Conque. L'après-midi, un moment au Jardin des Coraux. Puis elle remonte ici, à son bureau d'en bas, et à cette table. Elle dit que la séance a besoin de pauses comme la mer a besoin de vagues."]]])
		tous.append(b1)
		tous.append(L._gens(M, "vieille", -0.95, 2.0, -110.0, "boire", ["Une infusion d'algues entre deux votes. Ça éclaircit les idées, et ça ne fait pas trembler la main.",
			"Quatre-vingts ans de Conseil, et je n'ai jamais manqué une séance. J'ai manqué beaucoup de pauses, par contre."]))
		var gre2: Node = L._gens(M, "femme", 5.0, 1.9, -90.0, "lire", ["Je recopie la séance de ce matin au propre. Il y a beaucoup de « Respirons ». Je les compte : trente-deux.", "Entre deux séances, je relis tout. On trouve toujours une virgule qui s'est cachée."])
		L._causer(M, gre2, ["Bonjour ! La séance reprend plus tard. Vous pouvez regarder la maquette, et écrire dans le Livre des Marées : c'est ouvert à tous.", "Bonnes bulles ! Pause. Même les greffières en ont besoin. Enfin, presque."],
			[["livre", "Qu'est-ce que le Livre des Marées ?", ["C'est une idée de la Présidente : un livre ouvert, sur le lutrin, où chacun écrit une phrase pour ceux qui vivront ici dans cent ans. Les enfants écrivent au crayon bleu. Le Professeur Benthos écrit en notes de musique. Personne ne sait les lire."]]])
		tous.append(gre2)
		M.ctx["entree"] = str(L._pick(M, ["La Salle des Marées, entre deux séances : les fauteuils sont vides, les écrans tournent tout seuls, et deux conseillers bavardent près de la maquette des trois dômes.",
			"Une grande salle de nacre, une table en arc, une horloge des marées au mur. C'est la pause : on entend les bulles monter dans les colonnes de verre.",
			"Personne dans le fauteuil de la Présidente. Personne non plus dans le fauteuil vide, au bout de la table. Mais celui-là, c'est normal : il attend l'Atlantide."]))
	# ce qu'on fait : regarder l'horloge, regarder la maquette, ouvrir le Livre des Marées, regarder le
	# fauteuil vide, et en séance, lever la main
	M.act(R.P(-1.1, 1.5, -1.3), "E : regarder l'horloge des marées", func() -> void:
		M.main.sfx("clochette", hc)
		var tw: Tween = M.room.create_tween()
		tw.tween_property(gde, "rotation:z", gde.rotation.z - TAU, 2.0).set_trans(Tween.TRANS_SINE)
		var hh: float = float(M.ctx.get("hour", 12.0))
		if int(floor(hh / 6.2)) % 2 == 0:
			M.say("L'HORLOGE DES MARÉES. Là-haut, à la surface, autour de la bouée-phare, la mer monte. Ici, à cent quarante mètres, rien ne bouge. Les fondateurs l'ont accrochée quand même, « pour ne pas oublier que la mer respire ».", 8.0)
		else:
			M.say("L'HORLOGE DES MARÉES. Là-haut, la mer descend : les bateaux du Port des Cordages touchent presque le sable. Ici, la marée ne descend jamais. Mais l'aiguille avance, et le Conseil la regarde avant chaque vote.", 8.0)
	, 0.9)
	M.act(cw + Vector3(0, 1.1, 0.75), "E : regarder la maquette", func() -> void:
		if float(M.ctx.get("maquette119", 0.0)) > 0.0:
			return
		M.ctx["maquette119"] = 1.0
		M.main.sfx("hologramme", cw + Vector3.UP * 1.1)
		var tw: Tween = M.room.create_tween()
		tw.tween_property(mql, "light_energy", 1.2, 0.8)
		M.say(str(L._pick(M, ["Sous la cloche de verre, le Dôme d'Azur en petit : le Grand Dôme au milieu, sa Cheminée d'Air et sa Perle qui brille ; à l'ouest, le Dôme des Serres ; à l'est, celui de l'Institut. Un minuscule bathyscaphe jaune plonge et remonte dans son Bassin.",
			"La maquette des trois dômes, offerte au Conseil par l'École des Abysses. Une étiquette, au crayon bleu : « Échelle : un doigt pour vingt mètres. Ne pas souffler sur la cloche. Les poissons sont trop petits pour être vus. »",
			"La petite Perle s'allume plus fort. Dans la maquette, quelqu'un a peint une minuscule fenêtre éclairée dans le Grand Dôme. C'est celle de la Présidente, paraît-il. Elle dit qu'elle ne l'a jamais remarquée."])), 8.0)
		await M.get_tree().create_timer(7.0).timeout
		if not _la(M, room0):
			return
		var tw2: Tween = M.room.create_tween()
		tw2.tween_property(mql, "light_energy", 0.3, 1.5)
		M.ctx["maquette119"] = 0.0
	, 1.0)
	M.act(lt * Vector3(0, 1.1, 0.55), "E : ouvrir le Livre des Marées", func() -> void:
		M.main.sfx("ui_ouvrir", lt.origin)
		var st: Dictionary = M.state()
		if not bool(st.get("marees119", false)):
			st["marees119"] = true
			M.give([["perle_azur", 1]], "Tu prends la plume et tu écris une phrase pour ceux qui vivront ici dans cent ans. À côté du livre, une petite boîte de nacre porte une étiquette : « Pour ceux qui écrivent : une perle d'Azur. Merci pour dans cent ans. » ")
			return
		var n: int = int(M.ctx.get("livre119", 0))
		M.ctx["livre119"] = n + 1
		M.say(str(MAREES_LIVRE[n % MAREES_LIVRE.size()]), 9.0)
	, 1.0)
	M.act(R.P(2.1, 1.0, -0.6), "E : regarder le fauteuil vide", func() -> void:
		M.say(MAREES_FAUTEUIL, 8.0)
	, 0.9)
	if seance:
		M.act(R.P(2.2, 1.0, 2.25), "E : lever la main", func() -> void:
			var st2: Dictionary = M.state()
			var n2: int = int(st2.get("vote119", 0))
			st2["vote119"] = n2 + 1
			M.main.sfx("tampon_bureau", R.P(4.35, 0.8, 1.9))
			M.say(str(MAREES_VOTES[n2 % MAREES_VOTES.size()]), 8.0)
			for f2 in tous:
				if is_instance_valid(f2) and f2.has_method("gesture"):
					f2.gesture("applaudir", 2.5)
		, 1.2)


# =================================================================== le cabinet d'écoute du Professeur Benthos

## LE CABINET D'ÉCOUTE (da_benthos) : à l'Institut des Abysses, le bureau du Professeur Hippolyte Benthos.
## Le grand hublot sur la Fosse et l'hydrophone collé contre le verre ; le bureau d'écoute (le lecteur à
## rouleaux dont le rouleau tourne, le casque, le vumètre dont l'aiguille tremble) ; le grand pavillon de
## laiton sur son pied, où l'on fredonne pour répondre à la baleine ; l'étagère des rouleaux de la Grande
## Chanteuse, la vitrine des bocaux (de l'eau du fond, certains luisent), la table des carnets, le Grand
## Dictionnaire sur son lutrin, la colonne d'eau des méduses baptisées qui montent et descendent en
## s'allumant, l'affiche de la Chanteuse. Le jour, le Professeur (vouvoie) à ses heures, une chercheuse,
## la petite Mila un soir sur deux ; sinon l'assistant ; la nuit, la veilleuse d'écoute.
static func _benthos(M) -> void:
	var R = M.R
	var k = R.kit
	var nuit: bool = L._nuit(M)
	var room0 = M.room
	var rng: RandomNumberGenerator = L._r(M)
	var h: float = float(M.ctx.get("hour", 12.0))
	var prof_la: bool = not nuit and ((h >= 8.0 and h < 13.0) or (h >= 18.0 and h < 20.0))
	var mila_la: bool = not nuit and h >= 18.0 and h < 19.0
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	# le grand hublot (au fond), ses poissons-lanternes, son ombre (quand la Chanteuse passe) ; l'enseigne
	# de l'Institut au-dessus ; l'hydrophone collé contre le verre
	var hb: Node3D = _hublot(M, Transform3D(Basis(), R.P(0.3, 1.75, -hd + 0.04)), 0.55)
	R.mark_wall(0.3, 1.75, -hd, 0.65)
	_plongeon_banc(M, [[hb, 0.55]], 5)
	var ombre: StandardMaterial3D = _plongeon_ombre(hb, 0.55)
	_marees_panneau(M, R.L(0.3, 2.78, -hd + 0.03), Vector2(1.1, 0.55), _marees_ecran(M, "dome115/enseigne_institut.png", 0.7))
	R.mark_wall(0.3, 2.78, -hd, 0.6)
	var hy: Vector3 = R.P(0.72, 1.38, -hd + 0.07)
	k.cyl(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), hy + Vector3.BACK * -0.03), 0.05, 0.05, 0.12, "argent", 12)
	k.cyl(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), hy + Vector3.BACK * 0.09), 0.035, 0.035, 0.02, "fer", 12)
	_benthos_fil(M, hy + Vector3(0, -0.05, 0.08), R.P(0.9, 0.79, -hd + 0.3), 0.01, "fer")
	# le bureau d'écoute (sous le hublot) : le lecteur à rouleaux, le casque, le vumètre, les carnets,
	# la lampe ; le fauteuil du Professeur
	var bx: Transform3D = R.L(0.3, 0, -hd + 0.45)
	k.box(bx * Transform3D(Basis(), Vector3(0, 0.76, 0)), Vector3(2.3, 0.05, 0.72), "bois", 1.0)
	for sb in [-1.0, 1.0]:
		k.box(bx * Transform3D(Basis(), Vector3(sb * 1.05, 0.37, 0)), Vector3(0.12, 0.74, 0.66), "bois_sombre", 1.0)
	k.box(bx * Transform3D(Basis(), Vector3(-0.75, 0.47, 0.0)), Vector3(0.5, 0.5, 0.62), "bois_sombre", 1.0)
	k.col_box(bx * Transform3D(Basis(), Vector3(0, 0.4, 0)), Vector3(2.3, 0.8, 0.72))
	R.reserve(0.3, -hd + 0.45, 2.5, 0.95)
	var lec: Vector3 = R.P(-0.45, 0.785, -hd + 0.45)
	k.box(Transform3D(Basis(), lec + Vector3.UP * 0.05), Vector3(0.4, 0.1, 0.3), "bois_sombre", 1.0)
	k.box(Transform3D(Basis(), lec + Vector3(-0.17, 0.15, 0)), Vector3(0.03, 0.12, 0.2), "or", 1.0)
	k.box(Transform3D(Basis(), lec + Vector3(0.17, 0.15, 0)), Vector3(0.03, 0.12, 0.2), "or", 1.0)
	var rouleau: Node3D = I._node(M, lec + Vector3(0, 0.17, 0))
	rouleau.rotation.z = PI * 0.5
	var cire: StandardMaterial3D = L._m(M, "cire119", Color(0.55, 0.38, 0.2), 0.5)
	L._mesh(rouleau, L._cylm(0.05, 0.05, 0.3, 16), cire)
	for rg in range(5):
		L._mesh(rouleau, L._cylm(0.051, 0.051, 0.006, 16), L._m(M, "sillon119", Color(0.35, 0.22, 0.1), 0.6), Transform3D(Basis(), Vector3(0, -0.12 + rg * 0.06, 0)))
	var cornet: Node3D = I._node(M, lec + Vector3(0.0, 0.25, 0.05))
	var laiton_c: StandardMaterial3D = L._m(M, "pavillon119", Color(0.88, 0.68, 0.32), 0.3, 0.7, 0.0, true)
	L._mesh(cornet, L._cylm(0.1, 0.015, 0.22, 16, false), laiton_c, Transform3D(Basis(Vector3.RIGHT, 1.1), Vector3(0, 0.08, 0.05)))
	var casque: Node3D = I._node(M, R.P(0.45, 0.8, -hd + 0.55))
	L._mesh(casque, L._tore(0.08, 0.095), L._fer(M), Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0.08, 0)))
	for sc2 in [-1.0, 1.0]:
		L._mesh(casque, L._cylm(0.04, 0.04, 0.03, 12), L._m(M, "coussin119", Color(0.15, 0.25, 0.35), 0.8), Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(sc2 * 0.09, 0.03, 0)))
	var vu: Vector3 = R.P(1.0, 0.785, -hd + 0.35)
	k.box(Transform3D(Basis(Vector3.RIGHT, -0.3), vu + Vector3.UP * 0.12), Vector3(0.36, 0.24, 0.12), "bois_sombre", 1.0)
	_marees_panneau(M, Transform3D(Basis(Vector3.RIGHT, -0.3), vu + Vector3(0, 0.13, 0.065)), Vector2(0.3, 0.17), _marees_ecran(M, "nuees/ecran_mesures.png", 0.8))
	var vaig: Node3D = I._node(M, Vector3.ZERO)
	vaig.global_transform = Transform3D(Basis(Vector3.RIGHT, -0.3), vu + Vector3(0, 0.06, 0.075))
	L._mesh(vaig, I._boxm(Vector3(0.006, 0.12, 0.004)), L._m(M, "aiguille119", Color(0.85, 0.15, 0.1), 0.5), Transform3D(Basis(), Vector3(0, 0.06, 0)))
	for cp in range(3):
		k.box(R.L(1.25 + cp * 0.03, 0.8 + cp * 0.025, -hd + 0.6, 10.0 * cp), Vector3(0.18, 0.025, 0.24), "tissu_" + ["bleu", "vert", "rouge"][cp], 1.0)
	k.cyl(R.L(-1.05, 0.785, -hd + 0.35), 0.07, 0.09, 0.03, "argent", 12)
	k.cyl(R.L(-1.05, 0.815, -hd + 0.35), 0.012, 0.012, 0.35, "argent", 6)
	k.cyl(R.L(-1.05, 1.13, -hd + 0.4), 0.09, 0.05, 0.1, "tissu_vert", 12)
	L._lampe(M, R.P(-1.05, 1.1, -hd + 0.55), Color(1.0, 0.85, 0.6), 0.6, 3.0)
	R.fauteuil(0.3, -2.05, 180.0, "brun")
	# le grand pavillon de laiton sur son pied (au fond, à droite), tourné vers la pièce ; son câble
	var gorge: Vector3 = R.P(2.95, 1.25, -2.45)
	k.cyl(Transform3D(Basis(), R.P(2.95, 0, -2.45)), 0.22, 0.26, 0.05, "argent", 16)
	k.cyl(Transform3D(Basis(), R.P(2.95, 0.05, -2.45)), 0.035, 0.035, 1.18, "argent", 8, false)
	k.col_cyl(R.P(2.95, 0, -2.45), 0.3, 1.4)
	R.reserve(2.95, -2.45, 0.7, 0.7)
	var hdir: Vector3 = Vector3(-0.45, 0.22, 1.0).normalized()
	var pav: Node3D = I._node(M, gorge)
	pav.global_transform = Transform3D(Basis(Quaternion(Vector3.UP, hdir)), gorge)
	var laiton: StandardMaterial3D = L._m(M, "pavillon119", Color(0.88, 0.68, 0.32), 0.3, 0.7, 0.0, true)
	L._mesh(pav, L._cylm(0.075, 0.04, 0.3, 18, false), laiton, Transform3D(Basis(), Vector3(0, 0.15, 0)))
	L._mesh(pav, L._cylm(0.18, 0.075, 0.3, 22, false), laiton, Transform3D(Basis(), Vector3(0, 0.45, 0)))
	L._mesh(pav, L._cylm(0.5, 0.18, 0.32, 28, false), laiton, Transform3D(Basis(), Vector3(0, 0.76, 0)))
	L._mesh(pav, L._tore(0.49, 0.53), laiton, Transform3D(Basis(), Vector3(0, 0.92, 0)))
	L._mesh(pav, I._sph(0.06), laiton, Transform3D(Basis(), Vector3.ZERO))
	_benthos_fil(M, gorge + Vector3.DOWN * 0.05, R.P(1.45, 0.79, -hd + 0.4), 0.012, "fer")
	var bouche: Vector3 = gorge + hdir * 0.95
	# l'étagère des rouleaux (mur de gauche, au fond) : quatre planches, des rouleaux debout et étiquetés
	var ex: float = -hw + 0.17
	for yb in [0.5, 0.95, 1.4, 1.85, 2.3]:
		k.box(R.L(ex, yb, -2.05), Vector3(0.3, 0.03, 1.6), "bois", 1.0)
	for se in [-1.0, 1.0]:
		k.box(R.L(ex, 1.2, -2.05 + se * 0.79), Vector3(0.3, 2.4, 0.03), "bois_sombre", 1.0)
	for yb2 in [0.5, 0.95, 1.4, 1.85]:
		for ri in range(12):
			var rz: float = -2.75 + ri * 0.127
			if rng.randf() < 0.15:
				continue
			k.cyl(R.L(ex + 0.02, yb2 + 0.015, rz), 0.045, 0.045, 0.14, "bois_clair" if ri % 3 != 0 else "tissu_creme", 10)
			k.cyl(R.L(ex + 0.02, yb2 + 0.07, rz), 0.047, 0.047, 0.02, "papier", 10)
	k.col_box(R.L(ex, 1.2, -2.05), Vector3(0.34, 2.4, 1.6))
	R.reserve(ex, -2.05, 0.5, 1.7)
	R.mark_wall(-hw, 1.5, -2.05, 0.8)
	# l'affiche de la Grande Chanteuse (au fond, à gauche)
	k.box(R.L(-3.4, 1.95, -hd + 0.02), Vector3(0.66, 0.86, 0.02), "or", 1.0)
	_marees_panneau(M, R.L(-3.4, 1.95, -hd + 0.035), Vector2(0.6, 0.8), _marees_ecran(M, "dome119/affiche_chanteuse.png", 0.0))
	R.mark_wall(-3.4, 1.95, -hd, 0.35)
	# la vitrine des bocaux (mur de gauche, devant) : de l'eau du fond ; certains luisent
	var vx: float = -hw + 0.22
	k.box(R.L(vx - 0.18, 1.0, 1.4), Vector3(0.04, 2.0, 1.1), "bois_sombre", 1.0)
	for yv in [0.05, 0.6, 1.1, 1.6, 2.0]:
		k.box(R.L(vx, yv, 1.4), Vector3(0.38, 0.03, 1.1), "bois", 1.0)
	for sv in [-1.0, 1.0]:
		k.box(R.L(vx, 1.0, 1.4 + sv * 0.54), Vector3(0.38, 2.0, 0.03), "bois_sombre", 1.0)
	var couleurs: Array = [Color(0.3, 0.8, 0.9), Color(0.5, 0.9, 0.6), Color(0.8, 0.6, 1.0), Color(0.95, 0.85, 0.5), Color(0.4, 0.6, 1.0)]
	for yv2 in [0.6, 1.1, 1.6]:
		for jb in range(5):
			var jz: float = 1.0 + jb * 0.2
			var jp: Vector3 = R.P(vx, yv2 + 0.015, jz)
			var jc: Color = couleurs[(jb + int(yv2 * 10.0)) % couleurs.size()]
			var lumi: bool = (jb + int(yv2 * 10.0)) % 3 == 0
			var jar: Node3D = I._node(M, jp)
			L._mesh(jar, L._cylm(0.06, 0.06, 0.18, 12), L._m(M, "bocal119", Color(0.85, 0.95, 1.0, 0.25), 0.05, 0.0, 0.0, true), Transform3D(Basis(), Vector3(0, 0.09, 0)))
			L._mesh(jar, L._cylm(0.052, 0.052, 0.11, 12), L._m(M, "eau119_" + jc.to_html(false) + ("_l" if lumi else ""), Color(jc.r, jc.g, jc.b, 0.55), 0.2, 0.0, 1.4 if lumi else 0.0), Transform3D(Basis(), Vector3(0, 0.06, 0)))
			L._mesh(jar, L._cylm(0.064, 0.064, 0.025, 12), L._fer(M), Transform3D(Basis(), Vector3(0, 0.19, 0)))
	k.col_box(R.L(vx, 1.0, 1.4), Vector3(0.42, 2.0, 1.1))
	R.reserve(vx, 1.4, 0.6, 1.2)
	R.mark_wall(-hw, 1.2, 1.4, 0.6)
	# la table des carnets (au milieu, à gauche) : des piles de carnets, un carnet ouvert, l'encrier
	R.table(-1.5, -0.55, 0.0, 1.6, 0.85)
	R.chaise(-1.5, -1.2, 0.0, "bleu")
	for pc in range(4):
		var pxz := Vector2(-2.05 + pc * 0.32, -0.7 + (pc % 2) * 0.12)
		for cc in range(3 + pc % 3):
			k.box(R.L(pxz.x, 0.79 + cc * 0.026, pxz.y, rng.randf_range(-15.0, 15.0)), Vector3(0.15, 0.024, 0.21), "tissu_" + ["bleu", "vert", "creme", "rouge", "gris"][(cc + pc) % 5], 1.0)
	for so in [-1.0, 1.0]:
		k.box(R.L(-1.1 + so * 0.09, 0.79, -0.45, so * 4.0), Vector3(0.17, 0.006, 0.23), "papier", 1.0)
	k.cyl(R.L(-0.85, 0.79, -0.3), 0.03, 0.03, 0.05, "noir", 8)
	k.box(Transform3D(Basis(Vector3.BACK, 0.4), R.P(-0.82, 0.92, -0.3)), Vector3(0.01, 0.2, 0.03), "tissu_blanc", 1.0)
	# le Grand Dictionnaire de la Chanteuse, sur son lutrin
	var lt: Transform3D = R.L(2.0, 0, -0.5, -45)
	k.box(lt * Transform3D(Basis(), Vector3(0, 0.55, 0)), Vector3(0.08, 1.1, 0.08), "bois_sombre", 1.0)
	k.box(lt * Transform3D(Basis(), Vector3(0, 0.02, 0)), Vector3(0.45, 0.04, 0.38), "bois_sombre", 1.0)
	k.box(lt * Transform3D(Basis(Vector3.RIGHT, 0.35), Vector3(0, 1.12, 0)), Vector3(0.64, 0.05, 0.46), "bois_sombre", 1.0)
	k.box(lt * Transform3D(Basis(Vector3.RIGHT, 0.35), Vector3(0, 1.15, 0)), Vector3(0.6, 0.04, 0.42), "tissu_bleu", 1.0)
	for s3 in [-1.0, 1.0]:
		k.box(lt * Transform3D(Basis(Vector3.RIGHT, 0.35) * Basis(Vector3.FORWARD, s3 * 0.07), Vector3(s3 * 0.145, 1.18, 0)), Vector3(0.28, 0.035, 0.4), "papier", 1.0)
	k.col_box(lt * Transform3D(Basis(), Vector3(0, 0.6, 0)), Vector3(0.64, 1.2, 0.5))
	R.reserve(2.0, -0.5, 0.9, 0.9)
	# la colonne des méduses baptisées (devant, à droite) : elles montent, descendent et s'allument
	var tc: Vector3 = R.P(3.35, 0, 1.2)
	k.cyl(Transform3D(Basis(), tc), 0.42, 0.46, 0.32, "ceramique", 24)
	k.cyl(Transform3D(Basis(), tc + Vector3.UP * 1.92), 0.42, 0.42, 0.1, "ceramique", 24)
	k.ring(Transform3D(Basis(), tc + Vector3.UP * 0.32), 0.38, 0.43, 0.04, "argent", 24)
	var colonne: Node3D = I._node(M, tc + Vector3.UP * 1.12)
	L._mesh(colonne, L._cylm(0.38, 0.38, 1.6, 28, false), L._m(M, "colonne119", Color(0.35, 0.75, 0.95, 0.22), 0.05, 0.0, 0.25, true))
	for pq in range(3):
		var aq: float = -0.9 + pq * 0.45
		k.box(Transform3D(Basis(Vector3.UP, aq + PI * 1.5), tc + Vector3(cos(aq + PI) * 0.44, 0.2, -sin(aq + PI) * 0.44)), Vector3(0.12, 0.05, 0.01), "or", 1.0)
	k.col_cyl(tc, 0.45, 2.0)
	R.reserve(3.35, 1.2, 1.0, 1.0)
	var meds: Array = []
	var mats_m: Array = []
	for e in [[Color(0.75, 0.45, 1.0), 0.09, 0.0, Vector2(0.1, 0.05)], [Color(1.0, 0.55, 0.75), 0.07, 2.1, Vector2(-0.12, 0.08)], [Color(0.4, 1.0, 0.9), 0.06, 4.0, Vector2(0.02, -0.14)]]:
		var mc: Color = e[0]
		var mm: StandardMaterial3D = L._m(M, "meduse119_" + mc.to_html(false), Color(mc.r, mc.g, mc.b, 0.7), 0.3, 0.0, 1.2, true)
		mats_m.append(mm)
		var md: Node3D = I._node(M, tc + Vector3.UP * 1.1)
		var bell := SphereMesh.new()
		bell.radius = float(e[1])
		bell.height = float(e[1])
		bell.is_hemisphere = true
		bell.radial_segments = 16
		bell.rings = 6
		L._mesh(md, bell, mm)
		for tn in range(5):
			var at2: float = TAU * tn / 5.0
			var tl: float = float(e[1]) * rng.randf_range(1.6, 2.6)
			L._mesh(md, L._cylm(0.004, 0.002, tl, 4), mm, Transform3D(Basis(), Vector3(cos(at2) * float(e[1]) * 0.6, -tl * 0.5, sin(at2) * float(e[1]) * 0.6)))
		meds.append([md, float(e[2]), e[3]])
	M.ctx["meduses119"] = 0.0
	M.ctx["signal119"] = 0.0
	M.ctx["joue119"] = false
	L._chaque(M, func(delta: float, t: float) -> void:
		for m2 in meds:
			var nd: Node3D = m2[0]
			if not is_instance_valid(nd):
				continue
			var ph: float = float(m2[1])
			var off: Vector2 = m2[2]
			var s: float = sin(t * 2.4 + ph)
			nd.global_position = tc + Vector3(off.x, 1.1 + sin(t * 0.45 + ph) * 0.45 + s * 0.015, off.y)
			nd.scale = Vector3(1.0 + 0.08 * s, 1.0 - 0.1 * s, 1.0 + 0.08 * s)
		var g: float = float(M.ctx.get("meduses119", 0.0))
		for mm2 in mats_m:
			(mm2 as StandardMaterial3D).emission_energy_multiplier = 1.2 + g * 2.5
		var sig: float = maxf(0.0, float(M.ctx.get("signal119", 0.0)) - delta * 0.25)
		M.ctx["signal119"] = sig
		if is_instance_valid(vaig):
			vaig.rotation.z = 0.8 - sig * 1.4 - absf(sin(t * 7.0)) * (0.12 + sig * 0.6)
		if bool(M.ctx.get("joue119", false)) and is_instance_valid(rouleau):
			rouleau.rotate_object_local(Vector3.UP, delta * 5.0))
	L._lampe(M, tc + Vector3.UP * 1.2, Color(0.5, 0.8, 1.0), 0.45, 2.5)
	if nuit:
		for l in R.lights:
			if is_instance_valid(l):
				(l as OmniLight3D).light_energy *= 0.6
	# les gens
	var tous: Array = []
	if nuit:
		var veil: Node = L._gens(M, "femme", -1.5, -1.2, 0.0, "lire", ["Chut… J'écoute. La Chanteuse ne prévient jamais. Il faut quelqu'un, toujours, l'oreille tendue.",
			"Cette nuit : trois raies, un banc de poissons-lanternes, et un bruit que je n'ai pas encore classé. Peut-être la tuyauterie. Peut-être pas."])
		L._causer(M, veil, ["Bonsoir… doucement, s'il vous plaît. Je suis la veilleuse d'écoute. La nuit, le cabinet écoute la mer pour le Professeur.", "Bonnes bulles. Asseyez-vous, et ne dites rien. La mer parle bas, la nuit."],
			[["nuit", "Vous écoutez toute la nuit ?", ["Quelqu'un doit écouter. La Chanteuse ne prévient pas, et le Professeur reste sur son banc de la Baie jusque tard, puis il rentre dormir. S'il se passe quelque chose, je tire la petite sonnette. Il arrive en pyjama. Il est toujours content."]],
			["repondre", "On peut lui répondre, la nuit ?", ["Bien sûr. Fredonnez dans le grand pavillon, tout doucement. La nuit, le son porte plus loin. Mais ne soyez pas déçu si elle ne répond pas : elle a toute une mer à qui chanter."]]])
		tous.append(veil)
		M.ctx["entree"] = "Le cabinet d'écoute, la nuit : une seule lampe sur le bureau, le grand hublot noir où passent de petites lumières, et les méduses de la colonne qui s'allument et s'éteignent, comme si elles rêvaient."
	else:
		if prof_la:
			var hip: Node = M.person("vieux", -1.5, -1.2, 0.0, "lire", "le Professeur Hippolyte Benthos")
			hip.lines = ["Remarquable ! … Ah non, c'est la tuyauterie.", "Notez la date ! Une méduse vient de clignoter deux fois. C'est peut-être un message. C'est peut-être le hasard. Notons quand même."]
			L._causer(M, hip, ["Oh ! Pardon, j'écoutais. Entrez, entrez, mais doucement : la mer parle bas. Professeur Hippolyte Benthos. Bienvenue dans mon cabinet d'écoute.",
				"Ah, vous voilà. Chut… Non, ce n'était que la tuyauterie. Approchez-vous du grand pavillon. Elle passera peut-être. Elle aime les nouveaux."],
				[["repondre", "On peut lui répondre ?", ["Bien sûr ! Fredonnez dans le grand pavillon : le son descend par le câble jusqu'à l'hydrophone, collé contre le hublot, et part dans la mer. Pas trop fort, pas trop aigu. Elle n'aime pas qu'on crie. Personne n'aime qu'on crie."]],
				["dico", "Qu'y a-t-il dans le Grand Dictionnaire ?", ["Mille deux cents phrases de la Chanteuse, notées en vingt ans. « Bonjour, le Dôme », « il fait bon, là-haut », « je reviendrai ». Mes collègues disent que j'invente. Peut-être. Mais elle revient toujours."]],
				["bocaux", "Et tous ces bocaux ?", ["De l'eau du fond, que Lou me rapporte. Chaque bocal est une profondeur. Celui qui luit vient de cent quatre-vingt-dix mètres. Un autre a contenu une crevette, qui n'était pas d'accord : je l'ai relâchée. Le bocal, je l'ai gardé. Il se souvient d'elle."]]])
			tous.append(hip)
			M.ctx["entree"] = str(L._pick(M, ["Le cabinet d'écoute du Professeur Benthos : un grand hublot sur la Fosse, un pavillon de laiton grand comme un parapluie, des rouleaux par centaines, et le Professeur, le nez dans un carnet.",
				"« Chut ! » Tu entres sur la pointe des pieds. Le Professeur Benthos lève un doigt, écoute… puis sourit : « Ce n'était que la tuyauterie. Entrez ! »",
				"Ça sent le vieux papier, la cire et l'eau de mer. Dans une colonne de verre, trois méduses montent et descendent en s'allumant. Le Professeur Benthos t'adresse un grand signe."]))
		else:
			var asst: Node = L._gens(M, "homme", -1.5, -1.2, 0.0, "lire", ["Je recopie les carnets du Professeur au propre. Il écrit vite, et parfois en notes de musique. Je fais de mon mieux.",
				"Le Professeur a baptisé quarante méduses ce mois-ci. J'ai fait un tableau. Il a baptisé le tableau."])
			L._causer(M, asst, ["Bonnes bulles ! Je suis l'assistant du Professeur. Il n'est pas là, mais le cabinet est ouvert : la mer, elle, n'a pas d'horaires.", "Bonjour ! Vous venez écouter la Chanteuse ? Mettez-vous près du pavillon. Et surtout, ne faites pas de bruit avec vos chaussures."],
				[["professeur", "Où est le Professeur ?", ["À cette heure-ci ? Au laboratoire, à l'Aquarium, à La Conque, ou dans la Galerie, le nez dans un carnet. Il revient toujours ici le soir, pour écouter. Et le matin, pour écouter aussi."]],
				["repondre", "On peut répondre à la baleine ?", ["Le Professeur dit que oui. Il fredonne dans le grand pavillon, et parfois, elle répond. Une fois, elle a répondu à Mila. Le Professeur en a été jaloux toute une semaine. Essayez, vous verrez."]]])
			tous.append(asst)
			M.ctx["entree"] = str(L._pick(M, ["Le cabinet d'écoute du Professeur Benthos : un grand hublot sur la Fosse, un pavillon de laiton, des étagères de rouleaux, des bocaux qui luisent. Le Professeur n'est pas là, mais la mer, si.",
				"Des carnets partout, des rouleaux de cire par centaines, et un grand pavillon de laiton tourné vers toi, comme une oreille géante. Elle a l'air d'attendre quelque chose.",
				"Dans une colonne de verre, trois méduses montent et descendent en s'allumant. Derrière le grand hublot, un poisson-lanterne passe. L'assistant du Professeur lève la tête de ses carnets."]))
		var cher: Node = L._gens(M, "femme", -3.1, 1.25, -90.0, "lire", ["Ce bocal-ci luit depuis trois semaines. Le Professeur dit que c'est une bactérie très heureuse. Je note : « très heureuse ».",
			"J'étudie les méduses. Celle de la colonne qui s'appelle Mirabelle s'allume quand on dit son nom. … Mirabelle. Tu vois ?"])
		L._causer(M, cher, ["Bonjour ! Je suis chercheuse à l'Institut. Je range les bocaux du Professeur. Il en ajoute un chaque jour. Je n'en range qu'un tous les deux jours. Ça avance.", "Bonnes bulles ! Attention aux bocaux : certains luisent. Ce n'est pas dangereux. C'est juste joli."],
			[["meduses", "Comment s'appellent les méduses ?", ["Capucine, Octavie et Mirabelle. C'est le Professeur qui les a baptisées. Il les baptise toutes : il y en a même une, dans l'Aquarium, qui s'appelle « Professeur ». Elle ne s'allume jamais. Il dit que c'est de la modestie."]]])
		tous.append(cher)
		if mila_la:
			var mila: Node = M.person("fille", 3.55, 0.0, 90.0, "observer", "Mila Mérou")
			mila.lines = ["J'ai collé mon verre préféré contre la vitre. Le Professeur dit qu'on entend mieux. J'entends surtout mon oreille.",
				"Si la baleine voit le ciel tous les jours, elle pourrait me le raconter. Je lui ai préparé une question."]
			L._causer(M, mila, ["Chut ! J'écoute la mer. Bonjour quand même !", "Salut ! Tu viens écouter la baleine, toi aussi ? Mets-toi à côté de moi, il y a de la place contre la vitre."],
				[["ciel", "Tu as déjà vu le ciel ?", ["Jamais ! Je suis née ici. Mais la Présidente a voté ma pétition : bientôt, on montera tous voir le ciel. Je vais demander à la baleine s'il est aussi bleu qu'on le dit. Elle doit savoir : elle y va tous les jours."]]])
			tous.append(mila)
	# ce qu'on fait : écouter un enregistrement, répondre à la baleine, lire le Grand Dictionnaire,
	# regarder les méduses
	M.act(R.P(-0.45, 1.0, -hd + 0.85), "E : écouter un enregistrement", func() -> void:
		if bool(M.ctx.get("joue119", false)):
			return
		M.ctx["joue119"] = true
		M.ctx["signal119"] = 0.6
		M.main.sfx("baleine", lec)
		var n: int = int(M.ctx.get("rouleau119", 0))
		M.ctx["rouleau119"] = n + 1
		M.say(str(BENTHOS_ROULEAUX[n % BENTHOS_ROULEAUX.size()]), 8.0)
		await M.get_tree().create_timer(8.0).timeout
		if not _la(M, room0):
			return
		M.ctx["joue119"] = false
	, 1.0)
	M.act(bouche + Vector3.DOWN * 0.3, "E : répondre à la baleine", func() -> void:
		if bool(M.ctx.get("chante119", false)):
			return
		M.ctx["chante119"] = true
		M.main.sfx("chant_%d" % (L._r(M).randi() % 5), bouche)
		var tw: Tween = M.room.create_tween()
		tw.tween_property(pav, "scale", Vector3.ONE * 1.08, 0.4).set_trans(Tween.TRANS_SINE)
		tw.tween_property(pav, "scale", Vector3.ONE, 0.6).set_trans(Tween.TRANS_SINE)
		M.say(str(L._pick(M, ["Tu te penches sur le grand pavillon et tu fredonnes, tout doucement. Le son descend dans le câble, jusqu'à l'hydrophone collé contre le hublot, et part dans la mer.",
			"Tu fredonnes trois notes graves, puis une aiguë, comme dans le Grand Dictionnaire. Le pavillon de laiton vibre un peu. Puis plus rien. Tout le monde retient son souffle."])), 5.0)
		await M.get_tree().create_timer(4.0).timeout
		if not _la(M, room0):
			M.ctx["chante119"] = false
			return
		var st: Dictionary = M.state()
		var premier: bool = not bool(st.get("benthos119", false))
		if premier or L._r(M).randf() < 0.55:
			M.main.sfx("baleine", hb.global_position)
			M.ctx["signal119"] = 1.0
			var tw2: Tween = M.room.create_tween()
			tw2.tween_property(ombre, "albedo_color:a", 0.8, 2.0)
			tw2.tween_property(ombre, "albedo_color:a", 0.0, 3.0).set_delay(1.5)
			var tw3: Tween = M.room.create_tween()
			tw3.tween_method(func(v: float) -> void: M.ctx["meduses119"] = v, 0.0, 1.0, 1.5)
			tw3.tween_method(func(v: float) -> void: M.ctx["meduses119"] = v, 1.0, 0.0, 3.0).set_delay(2.0)
			for f in tous:
				if is_instance_valid(f) and f.has_method("gesture"):
					f.gesture("joie", 2.5)
			M.say(str(L._pick(M, ["Une ombre immense passe sur le grand hublot. Puis, à travers la mer, le verre et les murs, un chant très grave te répond : trois notes graves, une aiguë. « Bonjour, le Dôme. » Toutes les méduses de la colonne s'allument en même temps.",
				"D'abord, rien. Puis l'aiguille du vumètre bondit, le pavillon se met à chanter tout seul, et une voix immense, très douce, remplit le cabinet : deux notes longues. « Il fait bon, là-haut. » Elle t'a répondu !"])), 8.0)
			if premier:
				await M.get_tree().create_timer(2.5).timeout
				if not _la(M, room0):
					M.ctx["chante119"] = false
					return
				st["benthos119"] = true
				if prof_la:
					M.give([["coquillage_chanteur", 1]], "Le Professeur Benthos en a laissé tomber son carnet. « Elle vous a répondu ! Notez la date ! Tenez, gardez ceci : un coquillage qui chante. Collez-le à votre oreille, là-haut, et vous l'entendrez encore. » ")
				else:
					M.give([["coquillage_chanteur", 1]], "Dans le tiroir du bureau, une boîte porte une étiquette de la main du Professeur : « Pour ceux à qui elle répond : un coquillage qui chante. Notez la date ! » Tu en prends un. ")
			else:
				await M.get_tree().create_timer(5.0).timeout
		else:
			M.say(str(L._pick(M, ["Rien. La mer garde le silence. La Chanteuse a peut-être d'autres gens à qui chanter, ce soir. « Elle reviendra, dit-on derrière toi. Elle revient toujours. »",
				"Tu attends. Un poisson-lanterne passe devant le hublot, l'air curieux. Mais pas de chant. Le Professeur dit que le silence aussi est une réponse. Il dit qu'elle veut dire : « Plus tard. »"])), 7.0)
			await M.get_tree().create_timer(4.0).timeout
		if _la(M, room0):
			M.ctx["chante119"] = false
	, 1.1)
	M.act(lt * Vector3(0, 1.1, 0.55), "E : lire le Grand Dictionnaire", func() -> void:
		M.main.sfx("ui_ouvrir", lt.origin)
		var n2: int = int(M.ctx.get("dico119", 0))
		M.ctx["dico119"] = n2 + 1
		M.say(str(BENTHOS_DICO[n2 % BENTHOS_DICO.size()]), 9.0)
	, 1.0)
	M.act(R.P(2.8, 1.1, 1.15), "E : regarder les méduses", func() -> void:
		M.main.sfx("cristal_chante", tc + Vector3.UP * 1.1)
		var tw4: Tween = M.room.create_tween()
		tw4.tween_method(func(v: float) -> void: M.ctx["meduses119"] = v, 0.0, 0.8, 0.8)
		tw4.tween_method(func(v: float) -> void: M.ctx["meduses119"] = v, 0.8, 0.0, 2.0).set_delay(1.5)
		M.say(str(L._pick(M, ["Sur les plaquettes de la colonne : « Capucine », « Octavie », « Mirabelle ». C'est le Professeur qui les a baptisées. Mirabelle s'allume chaque fois qu'on dit son nom. … Mirabelle. Tu vois ?",
			"Au mur, à côté de la colonne, une liste à l'encre bleue : « Méduses baptisées : Clémence, Gertrude, Pervenche, Capucine, Octavie, Mirabelle… » Elle continue sur trois pages. Il reste de la place en bas, pour les prochaines."])), 7.0)
	, 1.0)
