extends Node3D
## V76 : le CHANTIER NAVAL DE PORT-AZUR — le bateau qui évolue.
## Au bout de la plage, contre la gare maritime : une cale de halage en pierre qui descend dans
## l'eau, une goélette en construction sur son ber (quille, membrures, premiers bordages,
## accores), une grue de bois à treuil, un appentis d'atelier (établi, outils, planches,
## goudron), des voiles qui sèchent sur une corde, et le REGISTRE DU CHANTIER sur son pupitre.
## Le charpentier : Yannick (le loueur de bateaux, qui rêve de faire le tour de l'archipel en
## voilier) ; on lui parle (sujet « ⚓ Le chantier naval ») ou on consulte le registre (E).
## Les évolutions (états sauvegardés, pas des objets) se paient en pièces + matériaux :
##   coque : la Barque -> le Sloop -> la Goélette ; propulsion : voile -> vapeur (il faut avoir
##   visité Cliquetis) -> cristal (il faut avoir visité Astralys) ; six accessoires.
## Le bateau (boat_v29.gd) se reconstruit aussitôt et attend au ponton des plaisanciers.
##
## API : setup(main), build(), serialize(), load_data(d), trouvailles(), register_interactions(d),
## register_services(journal), open_menu(speaker = null), apply_to_boat(), buy(item) (tests).

const Kit = preload("res://scripts/azur_kit_v56.gd")
const Boat = preload("res://scripts/boat_v29.gd")

## Prix : pièces + matériaux ; « apres » : l'évolution qu'il faut déjà avoir ; « visite » : la
## trouvaille qu'il faut avoir.
const PRIX := {
	"sloop": {"piece": 120, "buche": 12, "toile_voile": 4, "boulon": 6},
	"goelette": {"piece": 300, "buche": 20, "toile_voile": 8, "boulon": 10, "minerai_fer": 4},
	"vapeur": {"piece": 200, "minerai_fer": 8, "engrenage": 6, "ressort": 4, "boulon": 6},
	"cristal": {"piece": 400, "cristal_astral": 5, "engrenage": 4, "ressort": 2},
	"lanterne": {"piece": 30, "minerai_fer": 1, "boulon": 1},
	"longue_vue": {"piece": 45, "engrenage": 1, "minerai_fer": 1},
	"couchette": {"piece": 35, "buche": 3, "toile_voile": 2},
	"canon": {"piece": 40, "ressort": 2, "boulon": 2, "minerai_fer": 1},
	"peinture": {"piece": 25},
	"pavillon": {"piece": 20, "toile_voile": 1},
}
const TOILE_PRIX: int = 8                 # le chantier vend de la toile à voile
const NOMS := {
	"sloop": "le Sloop", "goelette": "la Goélette", "vapeur": "le moteur à vapeur", "cristal": "le moteur à cristal",
	"lanterne": "la lanterne de proue", "longue_vue": "la longue-vue", "couchette": "la couchette",
	"canon": "le canon à confettis", "peinture": "la peinture de la coque", "pavillon": "le pavillon",
}
const DESCRIPTIONS := {
	"sloop": "Le Sloop : six mètres et demi, une petite cabine à hublots, un grand mât, une grand-voile et un foc sur son bout-dehors. Plus stable, plus rapide (10 m/s à la voile), et on peut y emmener ses amis à quatre pattes.",
	"goelette": "La Goélette : huit mètres et demi, deux mâts, des voiles auriques et une vraie roue de barre, comme les grands capitaines. La plus élégante, la plus rapide à la voile (12 m/s).",
	"vapeur": "Le moteur à vapeur, d'après les plans de Cliquetis : une chaudière, une cheminée qui fume, une hélice qui fait des bouillons. Trente pour cent plus vite. Tchou-tchou… euh, pardon : tut-tut !",
	"cristal": "Le moteur à cristal des Lumens : silencieux comme un poisson qui rêve, il laisse derrière lui un sillage de lumière. Soixante-dix pour cent plus vite que la voile seule !",
	"lanterne": "Une lanterne de proue, avec une vraie flamme : la nuit, on voit la mer devant soi (et les îles nous voient arriver).",
	"longue_vue": "Une longue-vue de laiton : à bord, touche L (LB à la manette) pour regarder au loin. Les îles, les baleines, les mouettes qui se croient discrètes…",
	"couchette": "Une couchette avec couverture et oreiller : à l'arrêt, loin du rivage, la nuit, E pour dormir jusqu'au matin, bercé par les vagues.",
	"canon": "Un canon à confettis : à bord, touche K (B à la manette, A en VR). Pour fêter chaque arrivée, chaque trésor, chaque mardi.",
	"peinture": "La peinture de la coque : huit couleurs au choix, et on en change gratuitement quand on veut.",
	"pavillon": "Un pavillon à la poupe : six dessins au choix, à changer quand on veut.",
}
const PLURIELS := {
	"piece": ["pièce", "pièces"], "buche": ["bûche", "bûches"], "minerai_fer": ["bloc de minerai de fer", "blocs de minerai de fer"],
	"boulon": ["boulon", "boulons"], "ressort": ["ressort", "ressorts"], "toile_voile": ["rouleau de toile à voile", "rouleaux de toile à voile"],
	"engrenage": ["engrenage", "engrenages"], "cristal_astral": ["cristal astral", "cristaux astraux"],
}
const OU_TROUVER := {
	"piece": "les coffres, les quêtes, les ventes…",
	"buche": "une hache et un arbre, sur n'importe quelle île boisée",
	"minerai_fer": "les galeries des nains, à la Montagne de Feu",
	"boulon": "les robots du Boucan en sont pleins (et la ferraille aussi)",
	"ressort": "la casse du Boucan et ses robots",
	"toile_voile": "j'en vends ici même, %d pièces le rouleau" % TOILE_PRIX,
	"engrenage": "Cliquetis, la ville des inventeurs, en déborde",
	"cristal_astral": "ça vient d'Astralys, l'île qui flotte dans le ciel",
}
const ACC_ORDRE := ["lanterne", "longue_vue", "couchette", "canon", "peinture", "pavillon"]
const CHOIX := "q56:service:ch76:"

var main: Node
var azur: Node
var ile: Node3D
var kit
var state: Dictionary = {}
var force_found: Dictionary = {}          # tests : trouvailles forcées
var registre_pos: Vector3 = Vector3.ZERO  # le pupitre du registre (monde)
var charpentier_spot: Vector3 = Vector3.ZERO
var map_pos: Vector2 = Vector2.ZERO        # pour la carte (x, z monde)
var built: bool = false
var _speaker: Node3D                      # repère sur le registre (dialogue sans personnage)
var _hook: Node3D                         # le crochet de la grue (il se balance)
var _sails: Array = []
var _clock: float = 0.0
var _ia: Dictionary = {}


func setup(main_node: Node) -> void:
	main = main_node
	state = _default_state()


func _default_state() -> Dictionary:
	return {"coque": 1, "propulsion": 1, "accessoires": {}, "couleur": "", "pavillon": 0, "achats": 0, "visite": false}


# =================================================================== repère (la ville de Port-Azur)

func W(x: float, z: float, y: float) -> Vector3:
	return ile.to_world(x, z, y)


func G(x: float, z: float) -> float:
	var w: Vector3 = ile.to_world(x, z)
	return ile.height(w.x, w.z)


## Repère local : x le long du quai, z vers les terres, -z vers la mer ; rot en degrés autour de Y.
func XF(x: float, z: float, y: float, rot: float = 0.0) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, ile.TOWN_YAW + deg_to_rad(rot)), W(x, z, y))


## Une poutre carrée de a à b (monde).
func _beam(a: Vector3, b: Vector3, w: float, key: String, h: float = -1.0) -> void:
	var d: Vector3 = b - a
	var l: float = d.length()
	if l < 0.001:
		return
	kit.box(Transform3D(Boat._basis_y(d / l), (a + b) * 0.5), Vector3(w, l, w if h < 0.0 else h), key, 1.0)


## Une corde (cylindre fin) de a à b.
func _rope(a: Vector3, b: Vector3, r: float = 0.012, key: String = "corde76") -> void:
	var d: Vector3 = b - a
	var l: float = d.length()
	if l < 0.001:
		return
	kit.cyl(Transform3D(Boat._basis_y(d / l), a), r, r, l, key, 5, false)


# =================================================================== construction

func build() -> void:
	azur = main.get("azur_v56")
	if azur == null or azur.get("ile") == null or azur.ile == null:
		push_warning("V76 : pas de Port-Azur, pas de chantier naval")
		return
	ile = azur.ile
	var t0: int = Time.get_ticks_msec()
	kit = Kit.new()
	kit.setup(self, main.get("temps_v56"))
	_extra_mats()
	_slipway()
	_skeleton()
	_crane()
	_shed()
	_yard_props()
	_drying_sails()
	_lectern()
	kit.commit()
	var mid: Vector3 = W(-88.0, 6.0, 0.0)
	map_pos = Vector2(mid.x, mid.z)
	built = true
	# le charpentier a sa place au chantier (pour l'agenda de Yannick, voir le rapport V76)
	var port: Node = azur.get("port")
	if port != null and port.get("spots") != null:
		port.spots["chantier_charpentier"] = {"pos": charpentier_spot, "face": W(-88.0, 9.0, G(-88.0, 9.0)), "pose": "debout"}
		port.spots["chantier_etabli"] = {"pos": W(-80.2, 7.0, G(-80.2, 7.0) + 0.02), "face": W(-78.0, 7.0, 1.0), "pose": "comptoir"}
	print("ILE_MANGA_V76: chantier naval de Port-Azur bâti en ", Time.get_ticks_msec() - t0, " ms")


## Quelques matériaux propres au chantier, ajoutés au kit de Port-Azur.
func _extra_mats() -> void:
	var rope := StandardMaterial3D.new()
	rope.albedo_color = Color(0.6, 0.5, 0.34)
	rope.roughness = 0.95
	kit.mats["corde76"] = rope
	var fresh := StandardMaterial3D.new()
	fresh.albedo_texture = load("res://assets/textures/doors/wood_plain.png")
	fresh.albedo_color = Color(1.05, 0.88, 0.66)
	fresh.uv1_triplanar = true
	fresh.uv1_scale = Vector3(1.8, 1.8, 1.8)
	fresh.roughness = 0.75
	fresh.cull_mode = BaseMaterial3D.CULL_DISABLED
	kit.mats["bois_neuf"] = fresh
	var goudron := StandardMaterial3D.new()
	goudron.albedo_color = Color(0.05, 0.045, 0.04)
	goudron.roughness = 0.15
	goudron.metallic_specular = 0.8
	kit.mats["goudron"] = goudron
	var wet := StandardMaterial3D.new()
	wet.albedo_texture = load("res://assets/textures/azur/moellons.png") if ResourceLoader.exists("res://assets/textures/azur/moellons.png") else null
	wet.albedo_color = Color(0.62, 0.6, 0.55)
	wet.uv1_triplanar = true
	wet.uv1_scale = Vector3(0.45, 0.45, 0.45)
	wet.roughness = 0.6
	kit.mats["cale76"] = wet
	var page := StandardMaterial3D.new()
	page.albedo_color = Color(0.96, 0.93, 0.84)
	page.roughness = 0.9
	kit.mats["page76"] = page


## La cale de halage : une rampe de pierre de 5 m de large qui descend dans l'eau, avec ses
## deux coulisses de bois et des anneaux d'amarrage.
func _slipway() -> void:
	var z_top: float = 10.0
	var z_bot: float = -16.0
	var y_top: float = 0.72
	var y_bot: float = -1.55
	var ang: float = atan2(y_top - y_bot, z_top - z_bot)
	var lng: float = Vector2(z_top - z_bot, y_top - y_bot).length()
	var zm: float = (z_top + z_bot) * 0.5
	var ym: float = (y_top + y_bot) * 0.5
	var xf: Transform3D = XF(-88.0, zm, ym) * Transform3D(Basis(Vector3.RIGHT, -ang), Vector3.ZERO)
	kit.box(xf * Transform3D(Basis(), Vector3(0, -0.6, 0)), Vector3(5.0, 1.2, lng), "cale76", 1.5)
	kit.col_box(xf * Transform3D(Basis(), Vector3(0, -0.6, 0)), Vector3(5.0, 1.2, lng))
	# bordures de pierre de taille
	for sx in [-2.62, 2.62]:
		kit.box(xf * Transform3D(Basis(), Vector3(sx, -0.45, 0)), Vector3(0.36, 1.1, lng), "pierre_sombre", 1.2)
	# les coulisses (deux longrines goudronnées) et leurs traverses
	for rx in [-1.1, 1.1]:
		kit.box(xf * Transform3D(Basis(), Vector3(rx, 0.07, 0)), Vector3(0.28, 0.14, lng - 0.4), "bois_sombre", 1.0)
	var k: float = -lng * 0.5 + 0.8
	while k < lng * 0.5 - 0.5:
		kit.box(xf * Transform3D(Basis(), Vector3(0, 0.03, k)), Vector3(3.0, 0.06, 0.18), "bois_sombre", 1.0)
		k += 1.6
	# la tête de la cale : un treuil de halage et un bollard
	var head: Vector3 = W(-88.0, z_top + 1.2, G(-88.0, z_top + 1.2))
	kit.box(Transform3D(Basis(Vector3.UP, ile.TOWN_YAW), head + Vector3(0, 0.25, 0)), Vector3(1.6, 0.5, 0.7), "bois_sombre", 1.0)
	kit.cyl(Transform3D(Basis(Vector3.UP, ile.TOWN_YAW) * Basis(Vector3.BACK, PI * 0.5), head + Vector3(0.0, 0.75, 0.0) + _dir(0.75, 0)), 0.2, 0.2, 1.5, "bois", 12)
	kit.col_box(Transform3D(Basis(Vector3.UP, ile.TOWN_YAW), head + Vector3(0, 0.45, 0)), Vector3(1.6, 0.9, 0.8))
	for sx2 in [-1.0, 1.0]:
		var crank: Vector3 = head + _dir(sx2 * 0.85, 0.0) + Vector3(0, 0.75, 0)
		_beam(crank, crank + Vector3(0, 0.32, 0) + _dir(0, 0.12), 0.04, "fer")
	kit.bollard(W(-91.2, 6.5, G(-91.2, 6.5)))
	kit.bollard(W(-84.8, -1.0, G(-84.8, -1.0)))


## Un décalage exprimé dans les axes de la ville.
func _dir(x: float, z: float) -> Vector3:
	return W(x, z, 0.0) - W(0.0, 0.0, 0.0)


## La goélette en construction : quille, étrave, étambot, membrures, premiers bordages,
## posée sur des tins et calée par des accores.
func _skeleton() -> void:
	var L: float = 8.4
	var B: float = 2.6
	var D: float = 1.1
	var cz: float = 4.6
	var slope: float = atan2(0.72 + 1.55, 26.0)
	var ys: float = 0.72 - (10.0 - cz) * tan(slope)       # la cale sous le milieu du bateau
	var hx: Transform3D = XF(-88.0, cz, ys + 0.62) * Transform3D(Basis(Vector3.RIGHT, -slope), Vector3.ZERO)
	# quille
	kit.box(hx * Transform3D(Basis(), Vector3(0, 0.0, 0)), Vector3(0.2, 0.22, L * 0.94), "bois_neuf", 1.2)
	# étrave (courbe de la proue) et étambot
	var prev: Vector3 = Boat.hull_point(0.9, 0.0, L, B, D)
	for i in range(1, 9):
		var s: float = 0.9 + 0.1 * i / 8.0
		var p: Vector3 = Boat.hull_point(minf(s, 0.999), 0.0, L, B, D)
		p.y += (s - 0.9) / 0.1 * 0.0
		_beam(hx * Vector3(0, prev.y, prev.z), hx * Vector3(0, p.y, p.z), 0.16, "bois_neuf")
		prev = p
	var stem_top: Vector3 = Boat.hull_point(0.999, 1.0, L, B, D)
	_beam(hx * Vector3(0, prev.y, prev.z), hx * Vector3(0, stem_top.y + 0.15, stem_top.z - 0.08), 0.16, "bois_neuf")
	var sp0: Vector3 = Boat.hull_point(0.0, 0.0, L, B, D)
	var sp1: Vector3 = Boat.hull_point(0.0, 1.0, L, B, D)
	_beam(hx * Vector3(0, sp0.y, sp0.z), hx * Vector3(0, sp1.y + 0.1, sp1.z), 0.18, "bois_neuf")
	# tableau arrière (les premières planches)
	for j in range(4):
		var a0: float = 0.45 + j * 0.13
		var q0: Vector3 = Boat.hull_point(0.0, a0, L, B, D)
		kit.box(hx * Transform3D(Basis(), Vector3(0, q0.y, q0.z + 0.03)), Vector3(q0.x * 2.0, 0.12, 0.05), "bois_neuf", 1.0)
	# membrures (couples), des deux bords
	var nf: int = 13
	for f in range(nf):
		var s2: float = 0.06 + 0.86 * f / (nf - 1)
		for side in [-1.0, 1.0]:
			var last: Vector3 = Vector3.INF
			for j2 in range(9):
				var a: float = float(j2) / 8.0
				var q: Vector3 = Boat.hull_point(s2, a, L, B, D) * Vector3(side, 1, 1)
				if j2 == 8:
					q.y += 0.12
				if last != Vector3.INF:
					_beam(hx * last, hx * q, 0.09, "bois_neuf")
				last = q
		# le barrot qui relie les deux bords en haut (sur un couple sur deux)
		if f % 2 == 0:
			var top: Vector3 = Boat.hull_point(s2, 1.0, L, B, D)
			kit.box(hx * Transform3D(Basis(), Vector3(0, top.y - 0.05, top.z)), Vector3(top.x * 2.0, 0.08, 0.1), "bois_neuf", 1.0)
	# serre-bauquière (la lisse qui court en haut des couples)
	for side2 in [-1.0, 1.0]:
		var lst: Vector3 = Vector3.INF
		for i2 in range(17):
			var s3: float = 0.02 + 0.95 * i2 / 16.0
			var q2: Vector3 = Boat.hull_point(s3, 0.97, L, B, D) * Vector3(side2, 1, 1)
			if lst != Vector3.INF:
				_beam(hx * lst, hx * q2, 0.07, "bois_neuf")
			lst = q2
	# les premiers bordages (bas de coque, sur la partie centrale)
	var ns: int = 16
	var na: int = 5
	for side3 in [-1.0, 1.0]:
		for i3 in range(ns):
			var sa: float = 0.12 + 0.74 * i3 / ns
			var sb: float = 0.12 + 0.74 * (i3 + 1) / ns
			for j3 in range(na):
				var a0b: float = 0.0 + 0.48 * j3 / na
				var a1b: float = 0.0 + 0.48 * (j3 + 1) / na - 0.012
				var p00: Vector3 = hx * (Boat.hull_point(sa, a0b, L, B, D, 1.03) * Vector3(side3, 1, 1))
				var p10: Vector3 = hx * (Boat.hull_point(sb, a0b, L, B, D, 1.03) * Vector3(side3, 1, 1))
				var p11: Vector3 = hx * (Boat.hull_point(sb, a1b, L, B, D, 1.03) * Vector3(side3, 1, 1))
				var p01: Vector3 = hx * (Boat.hull_point(sa, a1b, L, B, D, 1.03) * Vector3(side3, 1, 1))
				var n: Vector3 = (p10 - p00).cross(p01 - p00).normalized() * side3
				var out: Vector3 = (hx.basis * Vector3(side3, -0.3, 0)).normalized()
				if n.dot(out) < 0.0:
					n = -n
				kit.quad4("bois_neuf", p00, p10, p11, p01, n, Vector2(0, 0), Vector2(1, 0), Vector2(1, 0.15), Vector2(0, 0.15))
				kit.quad4("bois_neuf", p00, p01, p11, p10, -n, Vector2(0, 0), Vector2(0, 0.15), Vector2(1, 0.15), Vector2(1, 0))
	# tins (piles de cales sous la quille) et accores (étais obliques)
	for tz in [-3.2, -1.6, 0.0, 1.6, 3.2]:
		var under: Vector3 = hx * Vector3(0, -0.11, tz)
		var g: Vector3 = W(-88.0, cz - tz, 0.0)
		var gy: float = 0.72 - (10.0 - (cz - tz)) * tan(slope) + 0.14
		var hgt: float = under.y - gy
		for kk in range(3):
			kit.box(Transform3D(Basis(Vector3.UP, ile.TOWN_YAW + (0.0 if kk % 2 == 0 else PI * 0.5)), Vector3(g.x, gy + hgt * (kk + 0.5) / 3.0, g.z)), Vector3(0.9 if kk % 2 == 0 else 0.5, hgt / 3.0 - 0.01, 0.5 if kk % 2 == 0 else 0.9), "bois_sombre", 1.0)
	for az in [-2.6, 0.0, 2.6]:
		for side4 in [-1.0, 1.0]:
			var on_hull: Vector3 = hx * (Boat.hull_point(clampf(0.5 - az / L, 0.05, 0.95), 0.62, L, B, D, 1.04) * Vector3(side4, 1, 1))
			var foot: Vector3 = W(-88.0 + side4 * 2.25, cz - az, 0.0)
			foot.y = 0.72 - (10.0 - (cz - az)) * tan(slope) + 0.12
			_beam(foot, on_hull, 0.13, "bois_sombre")
			kit.box(Transform3D(Basis(Vector3.UP, ile.TOWN_YAW), foot + Vector3(0, 0.05, 0)), Vector3(0.4, 0.1, 0.4), "bois_sombre", 1.0)
	kit.col_box(hx * Transform3D(Basis(), Vector3(0, 0.45, 0)), Vector3(B, 1.1, L))
	# une échelle appuyée contre le flanc
	var l0: Vector3 = W(-90.3, 6.3, 0.0)
	l0.y = 0.72 - (10.0 - 6.3) * tan(slope) + 0.1
	var l1: Vector3 = hx * (Boat.hull_point(0.33, 1.0, L, B, D) * Vector3(-1, 1, 1)) + Vector3(0, 0.25, 0)
	var lside: Vector3 = _dir(0, 0.25)
	for sl in [-1.0, 1.0]:
		_beam(l0 + lside * sl, l1 + lside * sl, 0.05, "bois")
	for r in range(7):
		var t: float = (r + 0.7) / 8.0
		_beam(l0.lerp(l1, t) - lside, l0.lerp(l1, t) + lside, 0.035, "bois")


## La grue de bois (une chèvre à flèche) et son treuil, qui soulève un paquet de planches
## au-dessus du bateau en construction.
func _crane() -> void:
	var bx: float = -93.4
	var bz: float = 5.2
	var g: float = G(bx, bz)
	var base: Vector3 = W(bx, bz, g)
	# l'embase en croix et le mât
	for rot in [0.0, 90.0]:
		kit.box(XF(bx, bz, g + 0.15, rot), Vector3(3.0, 0.3, 0.32), "bois_sombre", 1.0)
	var top: Vector3 = base + Vector3(0, 7.2, 0)
	_beam(base, top, 0.32, "bois")
	kit.box(Transform3D(Basis(Vector3.UP, ile.TOWN_YAW), top + Vector3(0, 0.12, 0)), Vector3(0.46, 0.18, 0.46), "bois_sombre", 1.0)
	for d in [Vector2(1.4, 0), Vector2(-1.4, 0), Vector2(0, 1.4), Vector2(0, -1.4)]:
		_beam(base + _dir(d.x, d.y) + Vector3(0, 0.3, 0), base + Vector3(0, 2.4, 0), 0.16, "bois")
	kit.col_box(Transform3D(Basis(Vector3.UP, ile.TOWN_YAW), base + Vector3(0, 1.2, 0)), Vector3(1.2, 2.4, 1.2))
	# la flèche, du pied du mât jusqu'au-dessus de la cale
	var foot: Vector3 = base + Vector3(0, 1.1, 0) + _dir(0.25, 0)
	var tip: Vector3 = W(-88.6, 4.2, g + 7.6)
	_beam(foot, tip, 0.22, "bois")
	kit.box(Transform3D(Basis(Vector3.UP, ile.TOWN_YAW), tip + Vector3(0, 0.0, 0)), Vector3(0.3, 0.3, 0.3), "bois_sombre", 1.0)
	# hauban de flèche, haubans au sol
	_rope(top, tip, 0.02)
	_rope(top, tip + Vector3(0, -0.1, 0), 0.016)
	for gd in [Vector2(-4.5, 3.0), Vector2(-4.0, -3.5), Vector2(1.0, 5.0)]:
		var stake: Vector3 = W(bx + gd.x, bz + gd.y, G(bx + gd.x, bz + gd.y))
		_rope(top + Vector3(0, -0.1, 0), stake + Vector3(0, 0.3, 0), 0.014)
		kit.box(Transform3D(Basis(Vector3.UP, ile.TOWN_YAW) * Basis(Vector3.RIGHT, 0.3), stake + Vector3(0, 0.2, 0)), Vector3(0.1, 0.5, 0.1), "bois_sombre", 1.0)
	# le treuil, au pied du mât
	var w0: Vector3 = base + _dir(0.0, 1.1) + Vector3(0, 0.75, 0)
	kit.cyl(Transform3D(Basis(Vector3.UP, ile.TOWN_YAW) * Basis(Vector3.BACK, PI * 0.5), w0 + _dir(0.45, 0)), 0.18, 0.18, 0.9, "bois", 12)
	kit.cyl(Transform3D(Basis(Vector3.UP, ile.TOWN_YAW) * Basis(Vector3.BACK, PI * 0.5), w0 + _dir(0.3, 0)), 0.2, 0.2, 0.6, "corde76", 12, false)
	for sx in [-0.55, 0.55]:
		_beam(base + _dir(sx, 1.1) + Vector3(0, 0.3, 0), w0 + _dir(sx, 0), 0.1, "bois_sombre")
		var c0: Vector3 = w0 + _dir(sx * 1.12, 0)
		_beam(c0, c0 + Vector3(0, 0.35, 0), 0.04, "fer")
		_beam(c0 + Vector3(0, 0.35, 0), c0 + Vector3(0, 0.35, 0) + _dir(sx * 0.18, 0), 0.04, "bois_sombre")
	_rope(w0 + Vector3(0, 0.2, 0), foot + Vector3(0, 0.1, 0), 0.014)
	_rope(foot + Vector3(0, 0.15, 0), tip + Vector3(0, -0.1, 0), 0.014)
	# le crochet et son paquet de planches (un nœud à part : il se balance)
	_hook = Node3D.new()
	_hook.name = "Crochet_grue"
	add_child(_hook)
	_hook.global_position = tip + Vector3(0, -0.15, 0)
	var hk := Kit.new()
	hk.setup(_hook, null)
	hk.mats = kit.mats
	var drop: float = 2.6
	hk.cyl(Transform3D(Basis(Vector3.DOWN, 0), Vector3(0, 0, 0)) * Transform3D(Basis(Vector3.RIGHT, PI), Vector3.ZERO), 0.014, 0.014, drop, "corde76", 5, false)
	hk.box(Transform3D(Basis(), Vector3(0, -drop - 0.12, 0)), Vector3(0.16, 0.24, 0.12), "bois_sombre", 1.0)
	hk.ring(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, -drop - 0.3, -0.03)), 0.06, 0.1, 0.05, "fer", 12)
	var by: float = -drop - 1.15
	for k in range(5):
		hk.box(Transform3D(Basis(Vector3.UP, ile.TOWN_YAW), Vector3(0, by + (k % 3) * 0.06, 0) + (W(0, (k - 2) * 0.24, 0) - W(0, 0, 0))), Vector3(3.2, 0.06, 0.22), "bois_neuf", 1.0)
	for sx2 in [-1.1, 1.1]:
		var anchor: Vector3 = W(sx2, 0, 0) - W(0, 0, 0)
		var a2: Vector3 = Vector3(0, -drop - 0.3, 0)
		var b2: Vector3 = Vector3(0, by + 0.1, 0) + anchor
		var d2: Vector3 = b2 - a2
		hk.cyl(Transform3D(Boat._basis_y(d2.normalized()), a2), 0.012, 0.012, d2.length(), "corde76", 5, false)
	hk.commit()


## L'atelier : un appentis adossé à la gare maritime, ouvert du côté de la cale.
func _shed() -> void:
	var x0: float = -84.8                  # l'avant (ouvert)
	var x1: float = -78.35                 # le mur de la gare
	var z0: float = 1.6
	var z1: float = 14.2
	var y_hi: float = 4.3
	var y_lo: float = 3.05
	# poteaux et sablières
	var z: float = z0
	while z <= z1 + 0.01:
		var g: float = G(x0 + 0.15, z)
		kit.box(XF(x0 + 0.15, z, (g + y_lo) * 0.5), Vector3(0.22, y_lo - g, 0.22), "bois", 1.0)
		kit.box(XF(x0 + 0.15, z, g + 0.1), Vector3(0.36, 0.2, 0.36), "pierre", 1.0)
		kit.col_box(XF(x0 + 0.15, z, (g + y_lo) * 0.5), Vector3(0.24, y_lo - g, 0.24))
		# entrait (poutre en travers) et jambe de force
		_beam(W(x0 + 0.15, z, y_lo - 0.1), W(x1, z, y_hi - 0.25), 0.16, "bois_sombre")
		_beam(W(x0 + 0.15, z, y_lo - 0.95), W(x0 + 0.95, z, y_lo - 0.1), 0.1, "bois_sombre")
		z += (z1 - z0) / 4.0
	kit.box(XF(x0 + 0.15, (z0 + z1) * 0.5, y_lo + 0.05), Vector3(0.24, 0.24, z1 - z0 + 0.4), "bois_sombre", 1.0)
	kit.box(XF(x1 - 0.1, (z0 + z1) * 0.5, y_hi - 0.12), Vector3(0.2, 0.24, z1 - z0 + 0.4), "bois_sombre", 1.0)
	# le toit de tuiles (un seul pan, de la gare vers la cale)
	var a: Vector3 = W(x1 + 0.1, z0 - 0.6, y_hi + 0.02)
	var b: Vector3 = W(x1 + 0.1, z1 + 0.6, y_hi + 0.02)
	var c: Vector3 = W(x0 - 0.7, z1 + 0.6, y_lo - 0.08)
	var d: Vector3 = W(x0 - 0.7, z0 - 0.6, y_lo - 0.08)
	var n: Vector3 = (b - a).cross(d - a).normalized()
	if n.y < 0.0:
		n = -n
	var span: float = Vector2(x1 - x0 + 0.8, y_hi - y_lo).length()
	kit.quad4("tuiles", a, b, c, d, n, Vector2(0, 0), Vector2((z1 - z0 + 1.2) / 2.4, 0), Vector2((z1 - z0 + 1.2) / 2.4, span / 2.4), Vector2(0, span / 2.4))
	kit.quad4("bois_sombre", a + Vector3.DOWN * 0.05, d + Vector3.DOWN * 0.05, c + Vector3.DOWN * 0.05, b + Vector3.DOWN * 0.05, -n, Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1))
	kit.col_box(Transform3D(Basis(Vector3.UP, ile.TOWN_YAW), (a + c) * 0.5 + Vector3.UP * 0.1), Vector3(0.1, 0.1, 0.1))
	# le mur du fond (planches contre la gare) et le pignon côté terre
	kit.box(XF(x1 - 0.05, (z0 + z1) * 0.5, (0.4 + y_hi) * 0.5), Vector3(0.1, y_hi - 0.4 + 0.6, z1 - z0), "planches", 2.0)
	for zz in [z1]:
		var gl: float = G((x0 + x1) * 0.5, zz)
		kit.box(XF((x0 + x1) * 0.5, zz + 0.05, (gl + y_lo) * 0.5), Vector3(x1 - x0, y_lo - gl, 0.08), "planches", 2.0)
		kit.col_box(XF((x0 + x1) * 0.5, zz + 0.05, (gl + y_lo) * 0.5), Vector3(x1 - x0, y_lo - gl, 0.1))
	# l'établi, contre le mur du fond
	var ex: float = x1 - 0.55
	for ez in [4.0, 9.0]:
		var ge: float = G(ex, (ez + 4.0 + ez) * 0.5)
		var top_y: float = ge + 0.88
		var xfb: Transform3D = XF(ex, ez + 2.0, top_y)
		kit.box(xfb, Vector3(0.8, 0.09, 4.2), "bois_sombre", 1.2)
		kit.box(xfb * Transform3D(Basis(), Vector3(0, -0.6, 0)), Vector3(0.7, 0.05, 4.0), "bois", 1.2)
		for lz in [-1.95, 1.95]:
			for lx in [-0.32, 0.32]:
				kit.box(xfb * Transform3D(Basis(), Vector3(lx, -0.45, lz)), Vector3(0.09, 0.9, 0.09), "bois_sombre", 1.0)
		kit.col_box(xfb * Transform3D(Basis(), Vector3(0, -0.44, 0)), Vector3(0.8, 0.9, 4.2))
		# étau, rabot, maillet, scie, ciseaux à bois, copeaux
		kit.box(xfb * Transform3D(Basis(), Vector3(-0.38, 0.0, 1.6)), Vector3(0.12, 0.22, 0.3), "fer", 1.0)
		kit.box(xfb * Transform3D(Basis(Vector3.UP, 0.3), Vector3(0.0, 0.09, 0.4)), Vector3(0.08, 0.1, 0.28), "bois", 1.0)
		kit.box(xfb * Transform3D(Basis(Vector3.UP, 0.3), Vector3(0.0, 0.16, 0.4)), Vector3(0.03, 0.06, 0.08), "fer", 1.0)
		kit.box(xfb * Transform3D(Basis(Vector3.UP, -0.6), Vector3(0.1, 0.1, -0.7)), Vector3(0.12, 0.12, 0.2), "bois_sombre", 1.0)
		kit.box(xfb * Transform3D(Basis(Vector3.UP, -0.6), Vector3(0.1, 0.07, -0.95)), Vector3(0.035, 0.035, 0.3), "bois", 1.0)
		kit.box(xfb * Transform3D(Basis(Vector3.UP, 0.15), Vector3(0.12, 0.05, -1.5)), Vector3(0.3, 0.008, 0.62), "chrome", 1.0)
		kit.box(xfb * Transform3D(Basis(Vector3.UP, 0.15), Vector3(0.12, 0.08, -1.12)), Vector3(0.06, 0.1, 0.14), "bois", 1.0)
		for k in range(4):
			kit.box(xfb * Transform3D(Basis(Vector3.UP, 0.1 * k), Vector3(-0.15 + 0.07 * k, 0.06, -0.15)), Vector3(0.02, 0.02, 0.2), "bois_sombre", 1.0)
	# le râtelier d'outils au mur
	for k2 in range(6):
		var tz: float = 5.0 + k2 * 0.55
		kit.box(XF(x1 - 0.14, tz, 2.1), Vector3(0.04, 0.6, 0.05 if k2 % 2 == 0 else 0.12), "bois_sombre" if k2 % 3 else "fer", 1.0)
	kit.box(XF(x1 - 0.12, 6.4, 2.45), Vector3(0.06, 0.08, 3.2), "bois", 1.0)
	# une étagère de pots (peinture, goudron, clous)
	var sh: Transform3D = XF(x1 - 0.25, 12.6, 1.6)
	kit.box(sh, Vector3(0.4, 0.04, 2.0), "bois", 1.0)
	kit.box(sh * Transform3D(Basis(), Vector3(0, 0.7, 0)), Vector3(0.4, 0.04, 2.0), "bois", 1.0)
	var cols := ["peinture_rouge", "peinture_bleu", "peinture_blanc", "goudron", "peinture_vert", "peinture_jaune", "laiton", "goudron"]
	for k3 in range(8):
		var shelf: float = 0.02 if k3 < 4 else 0.72
		kit.cyl(sh * Transform3D(Basis(), Vector3(0, shelf, -0.75 + (k3 % 4) * 0.5)), 0.1, 0.1, 0.2, cols[k3], 10)
	# planches debout contre le mur, au fond de l'appentis
	for k4 in range(9):
		var pz: float = 13.6 - k4 * 0.13
		var gp: float = G(x1 - 0.5, pz)
		kit.box(Transform3D(Basis(Vector3.UP, ile.TOWN_YAW) * Basis(Vector3.BACK, -0.18 + k4 * 0.006), W(x1 - 0.45, pz, gp + 1.6)), Vector3(0.05, 3.2, 0.22), "bois_neuf", 1.0)
	kit.col_box(XF(x1 - 0.5, 13.1, 1.6), Vector3(0.6, 3.0, 1.3))
	# la lanterne de l'atelier (allumée la nuit)
	var lamp_pos: Vector3 = W(x1 - 2.6, 8.0, y_hi - 0.95)
	kit.cyl(Transform3D(Basis(), lamp_pos + Vector3(0, 0.25, 0)), 0.01, 0.01, 0.55, "fer", 4, false)
	kit.cyl(Transform3D(Basis(), lamp_pos - Vector3(0, 0.12, 0)), 0.09, 0.09, 0.26, "lampe", 8)
	kit.cyl(Transform3D(Basis(), lamp_pos + Vector3(0, 0.14, 0)), 0.11, 0.01, 0.12, "fer", 8)
	var lt := OmniLight3D.new()
	lt.name = "Lampe_atelier"
	lt.light_color = Color(1.0, 0.78, 0.5)
	lt.omni_range = 9.0
	lt.shadow_enabled = false
	lt.position = lamp_pos
	add_child(lt)
	var t: Node = main.get("temps_v56")
	if t != null:
		t.register_lamp(lt, 1.6)
	# l'enseigne « CHANTIER NAVAL » sur la panne avant
	var sign_xf: Transform3D = XF(x0 - 0.2, 8.0, y_lo + 0.35, -90.0)
	kit.box(sign_xf, Vector3(4.4, 0.62, 0.08), "bois_sombre", 1.0)
	kit.box(sign_xf * Transform3D(Basis(), Vector3(0, 0, -0.045)), Vector3(4.25, 0.5, 0.02), "peinture_creme", 1.0)
	var lab := Label3D.new()
	lab.name = "Enseigne_chantier"
	lab.text = "CHANTIER NAVAL"
	lab.font_size = 96
	lab.pixel_size = 0.0042
	lab.modulate = Color(0.12, 0.2, 0.36)
	lab.outline_size = 0
	lab.double_sided = false
	lab.shaded = true
	if ResourceLoader.exists("res://assets/fonts/Lora-Bold.ttf"):
		lab.font = load("res://assets/fonts/Lora-Bold.ttf")
	add_child(lab)
	lab.global_transform = sign_xf * Transform3D(Basis(Vector3.UP, PI), Vector3(0, 0.02, -0.06))
	var lab2 := Label3D.new()
	lab2.text = "~ de Port-Azur ~"
	lab2.font_size = 40
	lab2.pixel_size = 0.0042
	lab2.modulate = Color(0.55, 0.12, 0.1)
	lab2.shaded = true
	lab2.double_sided = false
	if lab.font != null:
		lab2.font = lab.font
	add_child(lab2)
	lab2.global_transform = sign_xf * Transform3D(Basis(Vector3.UP, PI), Vector3(0, -0.2, -0.06))


## Le désordre heureux d'un chantier : piles de planches, grumes, tonneaux de goudron et
## chaudron, une barque retournée sur ses tréteaux, avirons, cordages lovés, ancre.
func _yard_props() -> void:
	# pile de planches séchant sur leurs tasseaux
	var px: float = -82.9
	var pz: float = -0.4
	var gp: float = G(px, pz)
	for layer in range(6):
		var y: float = gp + 0.12 + layer * 0.12
		if layer % 2 == 0:
			for s in range(3):
				kit.box(XF(px, pz - 1.6 + s * 1.6, y), Vector3(1.3, 0.05, 0.07), "bois_sombre", 1.0)
		else:
			for k in range(5):
				kit.box(XF(px - 0.5 + k * 0.25, pz, y), Vector3(0.22, 0.05, 3.6 - layer * 0.05), "bois_neuf", 1.0)
	kit.col_box(XF(px, pz, gp + 0.4), Vector3(1.3, 0.8, 3.6))
	# grumes
	for k2 in range(3):
		var lz: float = -3.0 - k2 * 0.05
		var lx: float = -94.0 + k2 * 0.62
		var gl: float = G(lx, lz)
		kit.cyl(XF(lx, lz, gl + 0.28 + (0.45 if k2 == 2 else 0.0)) * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(0, 0, 0)) * Transform3D(Basis(), Vector3(0, -2.2, 0)), 0.3, 0.27, 4.4, "bois_sombre", 12)
	kit.col_box(XF(-93.4, -3.0, G(-93.4, -3.0) + 0.4), Vector3(4.4, 0.8, 1.4))
	# la barque retournée sur ses tréteaux (à repeindre)
	var bx: float = -96.2
	var bz: float = 9.6
	var gb: float = G(bx, bz)
	for tz in [-1.3, 1.3]:
		var tr: Transform3D = XF(bx, bz + tz, gb)
		kit.box(tr * Transform3D(Basis(), Vector3(0, 0.75, 0)), Vector3(1.4, 0.08, 0.12), "bois", 1.0)
		for sx in [-0.55, 0.55]:
			for sz in [-0.15, 0.15]:
				kit.box(tr * Transform3D(Basis(Vector3.FORWARD, sx * 0.25) * Basis(Vector3.RIGHT, sz * 1.2), Vector3(sx, 0.37, sz)), Vector3(0.07, 0.8, 0.07), "bois", 1.0)
	var hull_xf: Transform3D = XF(bx, bz, gb + 0.82 + 0.72) * Transform3D(Basis(Vector3.BACK, PI), Vector3.ZERO)
	for side in [-1.0, 1.0]:
		for i in range(12):
			var sa: float = float(i) / 12.0
			var sb: float = float(i + 1) / 12.0
			for j in range(5):
				var a0: float = j / 5.0
				var a1: float = (j + 1) / 5.0
				var p00: Vector3 = hull_xf * (Boat.hull_point(sa, a0, 4.4, 1.5, 0.72) * Vector3(side, 1, 1))
				var p10: Vector3 = hull_xf * (Boat.hull_point(sb, a0, 4.4, 1.5, 0.72) * Vector3(side, 1, 1))
				var p11: Vector3 = hull_xf * (Boat.hull_point(sb, a1, 4.4, 1.5, 0.72) * Vector3(side, 1, 1))
				var p01: Vector3 = hull_xf * (Boat.hull_point(sa, a1, 4.4, 1.5, 0.72) * Vector3(side, 1, 1))
				var n: Vector3 = (p10 - p00).cross(p01 - p00).normalized()
				var mid: Vector3 = (p00 + p11) * 0.5
				var c: Vector3 = hull_xf * Vector3(0, 0.4, (p00 - hull_xf.origin).length() * 0.0)
				if n.dot(mid - hull_xf * Vector3(0, 0.45, (hull_xf.affine_inverse() * mid).z)) < 0.0:
					n = -n
				var key: String = "peinture_bleu" if j >= 3 else "bois"
				if j == 2:
					key = "peinture_blanc"
				kit.quad4(key, p00, p10, p11, p01, n, Vector2(0, 0), Vector2(1, 0), Vector2(1, 0.2), Vector2(0, 0.2))
				kit.quad4("bois_sombre", p00, p01, p11, p10, -n, Vector2(0, 0), Vector2(0, 0.2), Vector2(1, 0.2), Vector2(1, 0))
	kit.col_box(XF(bx, bz, gb + 0.8), Vector3(1.5, 1.6, 4.4))
	# tonneaux de goudron, le chaudron sur son feu éteint, des seaux
	for b in [[-82.6, 4.2], [-83.0, 5.0], [-82.4, 5.6]]:
		var gbb: float = G(b[0], b[1])
		kit.barrel(W(b[0], b[1], gbb), true)
		kit.disc(Transform3D(Basis(), W(b[0], b[1], gbb + 0.91)), 0.31, "goudron", 12)
	var cx: Vector3 = W(-91.6, 12.6, G(-91.6, 12.6))
	for k3 in range(3):
		var a: float = TAU * k3 / 3.0
		_beam(cx + Vector3(cos(a) * 0.55, 0, sin(a) * 0.55), cx + Vector3(0, 1.0, 0), 0.05, "fer")
	kit.cyl(Transform3D(Basis(), cx + Vector3(0, 0.38, 0)), 0.22, 0.3, 0.38, "fer", 14)
	kit.disc(Transform3D(Basis(), cx + Vector3(0, 0.74, 0)), 0.29, "goudron", 14)
	for k4 in range(5):
		var a2: float = TAU * k4 / 5.0
		kit.box(Transform3D(Basis(Vector3.UP, a2), cx + Vector3(cos(a2) * 0.45, 0.05, sin(a2) * 0.45)), Vector3(0.22, 0.12, 0.18), "pierre_sombre", 1.0)
	kit.col_cyl(cx, 0.6, 1.0)
	# avirons debout contre l'appentis, cordages lovés, une ancre, des poulies
	for k5 in range(3):
		var oz: float = 2.3 + k5 * 0.25
		var og: float = G(-84.95, oz)
		var o0: Vector3 = W(-85.05, oz, og + 0.02)
		var o1: Vector3 = W(-84.75, oz + 0.05, og + 2.7)
		_beam(o0, o1, 0.045, "bois")
		var bl: Vector3 = o0.lerp(o1, 0.14)
		kit.box(Transform3D(Boat._basis_y((o1 - o0).normalized()), bl), Vector3(0.16, 0.6, 0.02), "bois", 1.0)
	for c in [[-86.6, 12.4, 0.5], [-82.0, 2.6, 0.38], [-90.4, -2.8, 0.42]]:
		var gc: float = G(c[0], c[1])
		for r in range(4):
			kit.ring(Transform3D(Basis(), W(c[0], c[1], gc + r * 0.06)), float(c[2]) * 0.4 + r * 0.02, float(c[2]) - r * 0.06, 0.06, "corde76", 18)
	var an: Vector3 = W(-81.4, 0.6, G(-81.4, 0.6) + 0.06)
	var ay: Basis = Basis(Vector3.UP, ile.TOWN_YAW + 0.6) * Basis(Vector3.RIGHT, PI * 0.5 - 0.15)
	kit.box(Transform3D(ay, an + ay * Vector3(0, 0.0, 0)), Vector3(0.08, 1.5, 0.08), "fer", 1.0)
	kit.box(Transform3D(ay, an + ay * Vector3(0, 0.62, 0)), Vector3(0.9, 0.07, 0.07), "fer", 1.0)
	for sd in [-1.0, 1.0]:
		kit.box(Transform3D(ay * Basis(Vector3.BACK, sd * 0.8), an + ay * Vector3(sd * 0.28, -0.66, 0)), Vector3(0.07, 0.7, 0.07), "fer", 1.0)
	kit.ring(Transform3D(ay * Basis(Vector3.RIGHT, PI * 0.5), an + ay * Vector3(0, 0.82, 0)), 0.08, 0.13, 0.05, "fer", 12)
	kit.crate(W(-81.2, 12.0, G(-81.2, 12.0)), ile.TOWN_YAW + 0.2, 0.7, true)
	kit.crate(W(-81.3, 12.0, G(-81.3, 12.0) + 0.7), ile.TOWN_YAW - 0.3, 0.5, true)


## Des voiles qui sèchent : une longue corde entre trois poteaux, trois toiles qui ondulent.
func _drying_sails() -> void:
	var zl: float = 15.0
	var xs := [-97.5, -91.0, -85.2]
	var tops: Array = []
	for x in xs:
		var g: float = G(x, zl)
		kit.box(XF(x, zl, g + 1.9), Vector3(0.16, 3.8, 0.16), "bois", 1.0)
		kit.col_box(XF(x, zl, g + 1.9), Vector3(0.2, 3.8, 0.2))
		tops.append(W(x, zl, g + 3.7))
	for i in range(tops.size() - 1):
		var a: Vector3 = tops[i]
		var b: Vector3 = tops[i + 1]
		var m: Vector3 = (a + b) * 0.5 + Vector3(0, -0.12, 0)
		_rope(a, m, 0.012)
		_rope(m, b, 0.012)
	# trois voiles : crème, ocre (« tannée »), blanche
	var defs := [[-95.6, 3.0, 2.6, Color(0.88, 0.84, 0.74)], [-91.7, 2.2, 2.9, Color(0.78, 0.42, 0.24)], [-88.0, 2.6, 2.3, Color(0.86, 0.85, 0.8)]]
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode cull_disabled;
uniform sampler2D tex : source_color, filter_linear_mipmap;
uniform vec3 tint : source_color = vec3(1.0);
uniform float phase = 0.0;
void vertex() {
	float k = 1.0 - UV.y;
	float t = TIME * 1.6 + phase;
	VERTEX.z += (sin(UV.x * 4.0 + t) * 0.12 + sin(UV.x * 9.0 - t * 1.3) * 0.04) * (1.0 - k) * 1.0 + 0.18 * (1.0 - k) * (1.0 - k);
}
void fragment() {
	vec4 c = texture(tex, UV * vec2(1.0, 1.4));
	ALBEDO = c.rgb * tint;
	ROUGHNESS = 0.95;
	BACKLIGHT = tint * 0.4;
}
"""
	for k in range(defs.size()):
		var d: Array = defs[k]
		var qm := QuadMesh.new()
		qm.size = Vector2(float(d[1]), float(d[2]))
		qm.subdivide_width = 8
		qm.subdivide_depth = 8
		var mi := MeshInstance3D.new()
		mi.name = "Voile_qui_seche_%d" % k
		mi.mesh = qm
		var mat := ShaderMaterial.new()
		mat.shader = sh
		mat.set_shader_parameter("tex", Boat.sail_texture())
		mat.set_shader_parameter("tint", d[3])
		mat.set_shader_parameter("phase", k * 1.7)
		mi.material_override = mat
		add_child(mi)
		var hang_y: float = 3.7 - 0.06 - float(d[2]) * 0.5 - 0.02
		mi.global_transform = Transform3D(Basis(Vector3.UP, ile.TOWN_YAW), W(float(d[0]), zl + 0.03, G(float(d[0]), zl) + hang_y))
		_sails.append(mi)


## Le pupitre du REGISTRE DU CHANTIER (un gros livre ouvert) et son petit écriteau.
func _lectern() -> void:
	var lx: float = -85.4
	var lz: float = 11.3
	var g: float = G(lx, lz)
	var xf: Transform3D = XF(lx, lz, g, -90.0)
	kit.box(xf * Transform3D(Basis(), Vector3(0, 0.05, 0)), Vector3(0.5, 0.1, 0.5), "bois_sombre", 1.0)
	kit.box(xf * Transform3D(Basis(), Vector3(0, 0.55, 0)), Vector3(0.12, 1.0, 0.12), "bois", 1.0)
	var top: Transform3D = xf * Transform3D(Basis(Vector3.RIGHT, -0.38), Vector3(0, 1.1, 0))
	kit.box(top, Vector3(0.62, 0.05, 0.46), "bois_sombre", 1.0)
	kit.box(top * Transform3D(Basis(), Vector3(0, 0.045, 0)), Vector3(0.58, 0.04, 0.4), "cuir_rouge76", 1.0)
	for sx in [-1.0, 1.0]:
		kit.box(top * Transform3D(Basis(Vector3.BACK, sx * 0.08), Vector3(sx * 0.14, 0.075, 0)), Vector3(0.27, 0.02, 0.37), "page76", 1.0)
	kit.box(top * Transform3D(Basis(), Vector3(0.16, 0.095, 0.0)), Vector3(0.008, 0.004, 0.3), "goudron", 1.0)
	kit.col_box(xf * Transform3D(Basis(), Vector3(0, 0.55, 0)), Vector3(0.5, 1.1, 0.5))
	var cuir := StandardMaterial3D.new()
	cuir.albedo_color = Color(0.45, 0.1, 0.08)
	cuir.roughness = 0.6
	kit.mats["cuir_rouge76"] = cuir
	# un encrier et sa plume
	kit.cyl(top * Transform3D(Basis(), Vector3(0.24, 0.05, 0.17)), 0.03, 0.03, 0.05, "goudron", 8)
	kit.box(top * Transform3D(Basis(Vector3.FORWARD, 0.5), Vector3(0.27, 0.13, 0.17)), Vector3(0.008, 0.18, 0.02), "page76", 1.0)
	# l'écriteau
	var post_xf: Transform3D = XF(lx + 0.05, lz + 0.75, g, -90.0)
	kit.box(post_xf * Transform3D(Basis(), Vector3(0, 0.85, 0)), Vector3(0.08, 1.7, 0.08), "bois", 1.0)
	kit.box(post_xf * Transform3D(Basis(), Vector3(0, 1.55, -0.05)), Vector3(0.9, 0.42, 0.05), "bois_sombre", 1.0)
	var lab := Label3D.new()
	lab.text = "Registre du chantier\nCommandes & évolutions"
	lab.font_size = 36
	lab.pixel_size = 0.0036
	lab.modulate = Color(1.0, 0.92, 0.75)
	lab.outline_size = 0
	lab.shaded = true
	lab.double_sided = false
	if ResourceLoader.exists("res://assets/fonts/Lora-Bold.ttf"):
		lab.font = load("res://assets/fonts/Lora-Bold.ttf")
	add_child(lab)
	lab.global_transform = post_xf * Transform3D(Basis(Vector3.UP, PI), Vector3(0, 1.55, -0.085))
	registre_pos = W(lx, lz, g + 0.05)
	charpentier_spot = W(lx - 0.3, lz + 1.6, G(lx - 0.3, lz + 1.6) + 0.02)
	_speaker = Node3D.new()
	_speaker.name = "Registre_chantier"
	add_child(_speaker)
	_speaker.global_position = W(lx, lz, g + 1.2)


func _process(delta: float) -> void:
	if not built:
		return
	_clock += delta
	if _hook != null:
		_hook.rotation = Vector3(sin(_clock * 0.7) * 0.025, 0.0, sin(_clock * 0.53 + 1.0) * 0.03)
	if not bool(state.get("visite", false)) and main != null and main.has_method("_player_pos_v27") and registre_pos != Vector3.ZERO:
		var p: Vector3 = main._player_pos_v27()
		if p.distance_to(registre_pos) < 14.0:
			state["visite"] = true
			if main.has_method("_show_message_v28"):
				main._show_message_v28("Le chantier naval de Port-Azur : ça sent la sciure et le goudron. Sur la cale, une goélette prend forme, membrure après membrure…")


# =================================================================== l'état, le bateau

func serialize() -> Dictionary:
	var d: Dictionary = state.duplicate(true)
	d["accessoires"] = (state["accessoires"] as Dictionary).keys()
	return d


## Une ancienne sauvegarde (sans « chantier ») : la barque d'origine.
func load_data(d: Dictionary) -> void:
	state = _default_state()
	if d != null and not d.is_empty():
		state["coque"] = clampi(int(d.get("coque", 1)), 1, 3)
		state["propulsion"] = clampi(int(d.get("propulsion", 1)), 1, 3)
		var acc: Dictionary = {}
		var src: Variant = d.get("accessoires", [])
		if src is Array:
			for k in src:
				if ACC_ORDRE.has(str(k)):
					acc[str(k)] = true
		elif src is Dictionary:
			for k2 in src:
				if ACC_ORDRE.has(str(k2)) and bool(src[k2]):
					acc[str(k2)] = true
		state["accessoires"] = acc
		state["couleur"] = str(d.get("couleur", "")) if Boat.COULEURS.has(str(d.get("couleur", ""))) else ""
		state["pavillon"] = clampi(int(d.get("pavillon", 0)), 0, Boat.PAVILLONS.size() - 1)
		state["achats"] = int(d.get("achats", 0))
		state["visite"] = bool(d.get("visite", false))
	apply_to_boat()


func apply_to_boat() -> void:
	var b: Node = main.get("boat_v29") if main != null else null
	if b != null and b.has_method("set_evolution"):
		b.set_evolution({"coque": state["coque"], "propulsion": state["propulsion"], "accessoires": (state["accessoires"] as Dictionary).keys(),
			"couleur": state["couleur"], "pavillon": state["pavillon"]})


func has(item: String) -> bool:
	match item:
		"sloop":
			return int(state["coque"]) >= 2
		"goelette":
			return int(state["coque"]) >= 3
		"vapeur":
			return int(state["propulsion"]) >= 2
		"cristal":
			return int(state["propulsion"]) >= 3
	return (state["accessoires"] as Dictionary).has(item)


func trouvailles() -> Dictionary:
	var full: bool = int(state["coque"]) >= 3 and int(state["propulsion"]) >= 3
	for a in ACC_ORDRE:
		if not has(a):
			full = false
	return {
		"bateau_sloop": 1 if int(state["coque"]) >= 2 else 0,
		"bateau_goelette": 1 if int(state["coque"]) >= 3 else 0,
		"bateau_vapeur": 1 if int(state["propulsion"]) >= 2 else 0,
		"bateau_cristal": 1 if int(state["propulsion"]) >= 3 else 0,
		"bateau_complet": 1 if full else 0,
	}


## Une trouvaille du jeu (main._npc_ctx_v31().trouvailles : « cliquetis », « astralys »…).
func _found(key: String) -> bool:
	if force_found.has(key):
		return bool(force_found[key])
	if main == null or not main.has_method("_npc_ctx_v31"):
		return false
	var ctx: Dictionary = main._npc_ctx_v31()
	return int((ctx.get("trouvailles", {}) as Dictionary).get(key, 0)) > 0


# =================================================================== prix, achats

func _inv() -> Node:
	return main.get("inventory_v28") if main != null else null


func _count(id: String) -> int:
	var inv: Node = _inv()
	return int(inv.count(id)) if inv != null else 0


## Ce qui manque pour un achat : {id: quantité}.
func missing(item: String) -> Dictionary:
	var out: Dictionary = {}
	var p: Dictionary = PRIX.get(item, {})
	for id in p:
		var need: int = int(p[id]) - _count(str(id))
		if need > 0:
			out[str(id)] = need
	return out


## Pourquoi on ne peut pas encore le construire ("" : rien ne s'y oppose).
func blocker(item: String) -> String:
	if has(item):
		return "déjà"
	match item:
		"goelette":
			if not has("sloop"):
				return "Une goélette ? Commence par le sloop, matelot : on n'apprend pas à courir avant de marcher… ni à barrer deux mâts avant un seul."
		"vapeur":
			if not _found("cliquetis"):
				return "Un moteur à vapeur, j'aimerais bien… mais il me faudrait les plans des inventeurs de Cliquetis, la ville des engrenages, sur la grande île de l'est. Va donc y faire un tour !"
		"cristal":
			if not has("vapeur"):
				return "Le moteur à cristal se monte à la place du moteur à vapeur. D'abord la vapeur, ensuite les étoiles !"
			if not _found("astralys"):
				return "Un moteur à cristal… Seuls les Lumens d'Astralys, l'île qui flotte dans le ciel, savent faire chanter ces cristaux-là. Il faudrait aller leur rendre visite."
	return ""


func can_buy(item: String) -> bool:
	return PRIX.has(item) and blocker(item) == "" and missing(item).is_empty()


## Achète une évolution (vrai si c'est fait) : paie, enregistre, reconstruit le bateau.
func buy(item: String) -> bool:
	if not can_buy(item):
		return false
	var inv: Node = _inv()
	var p: Dictionary = PRIX[item]
	for id in p:
		inv.remove(str(id), int(p[id]))
	match item:
		"sloop":
			state["coque"] = 2
		"goelette":
			state["coque"] = 3
		"vapeur":
			state["propulsion"] = 2
		"cristal":
			state["propulsion"] = 3
		_:
			(state["accessoires"] as Dictionary)[item] = true
			if item == "peinture" and str(state["couleur"]) == "":
				state["couleur"] = "bleu"
			if item == "pavillon" and int(state["pavillon"]) == 0:
				state["pavillon"] = 1
	state["achats"] = int(state["achats"]) + 1
	apply_to_boat()
	_bring_boat()
	if main.has_method("sfx"):
		main.sfx("ramasse_pieces")
		var hammer: String = "marteau_chantier" if ResourceLoader.exists("res://assets/sons/sfx/marteau_chantier_1.ogg") else "forge_marteau"
		main.sfx(hammer, registre_pos if registre_pos != Vector3.ZERO else null, -4.0)
	return true


## Le bateau neuf (ou amélioré) attend au ponton des plaisanciers de Port-Azur.
func _bring_boat() -> void:
	var b: Node = main.get("boat_v29")
	if b == null or bool(b.get("driving")):
		return
	var i: int = b.dock_index("Ponton_azur") if b.has_method("dock_index") else -1
	if i >= 0:
		b.moor(i)


func _cost_text(item: String) -> String:
	var parts: Array = []
	var p: Dictionary = PRIX.get(item, {})
	for id in p:
		parts.append(_qty(str(id), int(p[id])))
	return ", ".join(parts)


func _qty(id: String, n: int) -> String:
	var pl: Array = PLURIELS.get(id, [id, id + "s"])
	return "%d %s" % [n, str(pl[0] if n == 1 else pl[1])]


# =================================================================== le menu du chantier

## Une page du menu : {texte, choix}. act : "menu", "voir", "item:sloop", "acheter:sloop",
## "accessoires", "peinture", "couleur:bleu", "pavillon", "drapeau:3", "toile", "venir".
func page(act: String, yannick: bool) -> Dictionary:
	var parts: PackedStringArray = act.split(":", true, 1)
	var a: String = parts[0]
	var arg: String = parts[1] if parts.size() > 1 else ""
	match a:
		"voir":
			return {"texte": _boat_text(yannick), "choix": _main_choices()}
		"item":
			return _item_page(arg, yannick)
		"acheter":
			return _buy_page(arg, yannick)
		"accessoires":
			return _acc_page(yannick)
		"peinture":
			return _paint_page(yannick)
		"couleur":
			if has("peinture") and Boat.COULEURS.has(arg):
				state["couleur"] = arg
				apply_to_boat()
				if main.has_method("sfx"):
					main.sfx("ui_choix")
				return {"texte": "Coup de pinceau, coup de pinceau… Et voilà : une coque %s ! Elle sèche en un clin d'œil (c'est de la peinture de Port-Azur)." % str(Boat.COULEURS[arg][1]).to_lower(), "choix": _main_choices()}
			if has("peinture") and arg == "bois":
				state["couleur"] = ""
				apply_to_boat()
				return {"texte": "On gratte, on ponce, on vernit : retour au bois d'origine. Ça a son charme.", "choix": _main_choices()}
			return page("menu", yannick)
		"pavillon":
			return _flag_page(yannick)
		"drapeau":
			var n: int = int(arg)
			if has("pavillon") and n >= 0 and n < Boat.PAVILLONS.size():
				state["pavillon"] = n
				apply_to_boat()
				if main.has_method("sfx"):
					main.sfx("ui_choix")
				if n == 0:
					return {"texte": "Pavillon rangé dans le coffre. Discret, le capitaine…", "choix": _main_choices()}
				return {"texte": "Hissez le pavillon ! « %s » flotte maintenant à la poupe." % str(Boat.PAVILLONS[n]), "choix": _main_choices()}
			return page("menu", yannick)
		"toile":
			return _toile_page(int(arg) if arg != "" else 1, yannick)
		"venir":
			var b: Node = main.get("boat_v29")
			_bring_boat()
			var where: String = "au ponton des plaisanciers, juste là"
			return {"texte": ("C'est fait : ton bateau t'attend %s. Un ami pêcheur me l'a ramené en chantant faux." % where) if b != null else "Hum… je ne vois pas de bateau.", "choix": _main_choices()}
	# le menu principal
	var hello: String
	if yannick:
		hello = "Bienvenue au chantier, capitaine ! Ici, on rabote, on cloue, on goudronne… et on rêve de grand large. "
	else:
		hello = "Le gros registre du chantier est ouvert. Yannick y a écrit : « Commandes à noter ici, paiement dans la boîte, je construis la nuit (et je chante). » "
	return {"texte": hello + _short_boat() + " Dans ta bourse : %s." % _qty("piece", _count("piece")), "choix": _main_choices()}


func _short_boat() -> String:
	var b: String = "%s %s" % [str(Boat.HULLS[int(state["coque"])]["nom"]), str(Boat.PROPULSIONS[int(state["propulsion"])]["nom"])]
	return "Ton bateau : %s." % b


func _main_choices() -> Array:
	var out: Array = []
	var c: int = int(state["coque"])
	var p: int = int(state["propulsion"])
	if c < 3:
		var it: String = "sloop" if c == 1 else "goelette"
		out.append({"id": CHOIX + "item:" + it, "label": "⚓ Nouvelle coque : %s (%d pièces + matériaux)" % [str(NOMS[it]).substr(0, 1).to_upper() + str(NOMS[it]).substr(1), int(PRIX[it]["piece"])]})
	if p < 3:
		var it2: String = "vapeur" if p == 1 else "cristal"
		out.append({"id": CHOIX + "item:" + it2, "label": "⚒ Propulsion : %s (%d pièces + matériaux)" % [str(NOMS[it2]), int(PRIX[it2]["piece"])]})
	var nb: int = 0
	for a in ACC_ORDRE:
		if has(a):
			nb += 1
	out.append({"id": CHOIX + "accessoires", "label": "✦ Accessoires (%d sur 6 à bord)" % nb})
	if has("peinture"):
		out.append({"id": CHOIX + "peinture", "label": "✎ Changer la couleur de la coque"})
	if has("pavillon"):
		out.append({"id": CHOIX + "pavillon", "label": "✎ Changer de pavillon"})
	out.append({"id": CHOIX + "voir", "label": "Voir mon bateau"})
	out.append({"id": CHOIX + "venir", "label": "Faire venir mon bateau au ponton de Port-Azur"})
	out.append({"id": CHOIX + "toile", "label": "Acheter un rouleau de toile à voile (%d pièces)" % TOILE_PRIX})
	out.append({"id": "fermer", "label": "(Partir)"})
	return out


func _boat_text(_yannick: bool) -> String:
	var c: int = int(state["coque"])
	var p: int = int(state["propulsion"])
	var h: Dictionary = Boat.HULLS[c]
	var speed: float = float(h["v"]) * float(Boat.PROPULSIONS[p]["k"])
	var t: String = "%s %s : %s mètres de long, %s m/s à fond." % [str(h["nom"]).substr(0, 1).to_upper() + str(h["nom"]).substr(1), str(Boat.PROPULSIONS[p]["nom"]), str(snappedf(float(h["L"]), 0.1)).replace(".", ","), str(snappedf(speed, 0.1)).replace(".", ",")]
	var acc: Array = []
	for a in ACC_ORDRE:
		if has(a):
			acc.append(str(NOMS[a]))
	t += " À bord : %s." % (", ".join(acc) if not acc.is_empty() else "rien encore, pas même un coussin")
	if has("peinture") and str(state["couleur"]) != "":
		t += " Coque peinte en %s." % str(Boat.COULEURS[str(state["couleur"])][1]).to_lower()
	if has("pavillon") and int(state["pavillon"]) > 0:
		t += " Pavillon : « %s »." % str(Boat.PAVILLONS[int(state["pavillon"])])
	var b: Node = main.get("boat_v29")
	if b != null and b.get("hull") != null:
		var d: float = b.hull.global_position.distance_to(registre_pos) if registre_pos != Vector3.ZERO else 0.0
		t += " Il est amarré %s." % ("tout près d'ici" if d < 120.0 else "loin d'ici (je peux le faire venir)")
	return t


func _item_page(item: String, yannick: bool) -> Dictionary:
	if not PRIX.has(item):
		return page("menu", yannick)
	var desc: String = str(DESCRIPTIONS[item])
	if has(item):
		return {"texte": desc + " C'est déjà à bord !", "choix": _main_choices()}
	var bl: String = blocker(item)
	var back: Array = [{"id": CHOIX + ("accessoires" if ACC_ORDRE.has(item) else "menu"), "label": "Retour"}, {"id": "fermer", "label": "(Partir)"}]
	if bl != "":
		return {"texte": desc + "\n" + bl, "choix": back}
	var t: String = desc + "\nPrix : %s." % _cost_text(item)
	var miss: Dictionary = missing(item)
	if miss.is_empty():
		t += " Tu as tout ce qu'il faut. On le fait ?"
		return {"texte": t, "choix": [{"id": CHOIX + "acheter:" + item, "label": "✔ Oui, construis-le ! (%s)" % _cost_text(item)}] + back}
	var lines: Array = []
	for id in miss:
		lines.append("%s (%s)" % [_qty(str(id), int(miss[id])), str(OU_TROUVER.get(str(id), "…"))])
	t += "\nIl te manque : " + " ; ".join(lines) + "."
	if miss.has("toile_voile"):
		back.insert(0, {"id": CHOIX + "toile", "label": "Acheter un rouleau de toile à voile (%d pièces)" % TOILE_PRIX})
	return {"texte": t, "choix": back}


func _buy_page(item: String, yannick: bool) -> Dictionary:
	if not buy(item):
		return _item_page(item, yannick)
	var t: String
	match item:
		"sloop":
			t = "Coups de marteau, copeaux qui volent, une nuit de travail… et voici le Sloop ! Sa cabine sent encore le vernis. Il t'attend au ponton des plaisanciers."
		"goelette":
			t = "Deux mâts, des voiles neuves, une roue de barre qui brille : la Goélette est à l'eau ! Je crois que je vais pleurer. (Je pleure.) Elle t'attend au ponton."
		"vapeur":
			t = "La chaudière ronronne, la cheminée fume, l'hélice mouline : ton bateau a un moteur à vapeur ! Attention, il démarre sec."
		"cristal":
			t = "Les cristaux s'allument et chantent tout bas… Le moteur à cristal est en place. Regarde derrière toi en naviguant : un sillage d'étoiles !"
		"peinture":
			t = "Pots de peinture ouverts, pinceaux prêts ! Je t'ai mis du bleu marine en attendant ; choisis ta couleur."
			var r: Dictionary = _paint_page(yannick)
			return {"texte": t, "choix": r["choix"]}
		"pavillon":
			t = "Un beau pavillon tout neuf ! J'ai hissé la Mouette rieuse ; choisis le dessin qui te plaît."
			var r2: Dictionary = _flag_page(yannick)
			return {"texte": t, "choix": r2["choix"]}
		_:
			t = "C'est installé : %s ! Ça te va comme un gant de marin." % str(NOMS[item])
	if main.has_method("_show_message_v28"):
		main._show_message_v28("Chantier naval : %s %s." % [str(NOMS[item]).substr(0, 1).to_upper() + str(NOMS[item]).substr(1), "est prêt" if item in ["sloop", "vapeur", "cristal", "canon", "pavillon"] else "est prête"])
	return {"texte": t, "choix": _main_choices()}


func _acc_page(_yannick: bool) -> Dictionary:
	var out: Array = []
	for a in ACC_ORDRE:
		if has(a):
			out.append({"id": CHOIX + "item:" + a, "label": "✔ %s (à bord)" % (str(NOMS[a]).substr(0, 1).to_upper() + str(NOMS[a]).substr(1))})
		else:
			out.append({"id": CHOIX + "item:" + a, "label": "✦ %s (%s)" % [str(NOMS[a]).substr(0, 1).to_upper() + str(NOMS[a]).substr(1), _cost_text(a)]})
	out.append({"id": CHOIX + "menu", "label": "Retour"})
	out.append({"id": "fermer", "label": "(Partir)"})
	return {"texte": "Les accessoires du chantier : chacun s'installe une fois pour toutes.", "choix": out}


func _paint_page(_yannick: bool) -> Dictionary:
	if not has("peinture"):
		return _item_page("peinture", _yannick)
	var out: Array = []
	for id in Boat.COULEURS:
		out.append({"id": CHOIX + "couleur:" + str(id), "label": ("✔ " if str(state["couleur"]) == str(id) else "") + str(Boat.COULEURS[id][1])})
	out.append({"id": CHOIX + "couleur:bois", "label": ("✔ " if str(state["couleur"]) == "" else "") + "Bois verni (d'origine)"})
	out.append({"id": CHOIX + "menu", "label": "Retour"})
	return {"texte": "Quelle couleur pour la coque ? (On peut en changer gratuitement, j'ai des pots plein l'atelier.)", "choix": out}


func _flag_page(_yannick: bool) -> Dictionary:
	if not has("pavillon"):
		return _item_page("pavillon", _yannick)
	var out: Array = []
	for n in range(1, Boat.PAVILLONS.size()):
		out.append({"id": CHOIX + "drapeau:%d" % n, "label": ("✔ " if int(state["pavillon"]) == n else "") + str(Boat.PAVILLONS[n])})
	out.append({"id": CHOIX + "drapeau:0", "label": ("✔ " if int(state["pavillon"]) == 0 else "") + "Pas de pavillon"})
	out.append({"id": CHOIX + "menu", "label": "Retour"})
	return {"texte": "Quel pavillon hisser ? La Mouette rieuse, l'Étoile du marin, le Crâne qui rigole, le Cœur vaillant, l'Ancre d'or ou le Poisson-lune.", "choix": out}


func _toile_page(n: int, yannick: bool) -> Dictionary:
	var inv: Node = _inv()
	if inv == null:
		return page("menu", yannick)
	if _count("piece") < TOILE_PRIX * n:
		return {"texte": "Un rouleau de toile, c'est %d pièces… et ta bourse fait la grimace." % TOILE_PRIX, "choix": _main_choices()}
	if inv.has_method("space_for") and int(inv.space_for("toile_voile")) < n:
		return {"texte": "Ton sac est plein à craquer : fais-lui un peu de place pour la toile.", "choix": _main_choices()}
	inv.remove("piece", TOILE_PRIX * n)
	inv.add("toile_voile", n)
	if main.has_method("sfx"):
		main.sfx("ramasse_pieces")
	if main.has_method("_show_message_v28"):
		main._show_message_v28("+ Toile à voile")
	return {"texte": "Et un rouleau de toile à voile, un ! Solide, souple, et ça sent le large. Tu en as maintenant %d." % _count("toile_voile"), "choix": _main_choices()}


# =================================================================== les deux portes d'entrée

## Le registre (ou n'importe quel repère) : le menu s'ouvre dans le dialogue de main (ask_v69).
func open_menu(speaker: Node3D = null) -> void:
	_ask(page("menu", false), speaker)


func _ask(r: Dictionary, speaker: Node3D = null) -> void:
	if main == null or not main.has_method("ask_v69"):
		return
	var who: Node3D = speaker if speaker != null else _speaker
	main.ask_v69(who, "Registre du chantier", "plein de taches de goudron", str(r["texte"]), r["choix"], Callable(self, "_on_registre_choice"))


func _on_registre_choice(id: String) -> void:
	if not id.begins_with(CHOIX):
		if main.has_method("_close_dialogue_v31"):
			main._close_dialogue_v31()
		return
	_ask(page(id.substr(CHOIX.length()), false))


func register_interactions(d: Node) -> void:
	if d == null or d.get("_interactions") == null or not built:
		return
	var me = self
	_ia = {"id": "ch76_registre", "pos": registre_pos, "radius": 1.8, "text": "E : consulter le registre du chantier naval",
		"vr": "Gâchette : consulter le registre du chantier", "call": func(): me.open_menu(), "when": func(): return true}
	d._interactions.append(_ia)


## Yannick, le charpentier : un sujet « ⚓ Le chantier naval », puis tout le menu dans sa conversation.
func register_services(journal: Node) -> void:
	if journal == null:
		return
	var prev: Variant = journal.services.get("yannick", null)
	journal.add_service("yannick", Callable(self, "_yan_topics").bind(prev), Callable(self, "_yan_choose").bind(prev))


func _yan_topics(npc: Node, prev: Variant) -> Array:
	var out: Array = [{"id": CHOIX + "menu", "label": "⚓ Le chantier naval : voir mon bateau, l'améliorer"}]
	if prev != null:
		out += ((prev as Array)[0] as Callable).call(npc)
	return out


func _yan_choose(npc: Node, choice: String, prev: Variant) -> Dictionary:
	if not choice.begins_with(CHOIX):
		return ((prev as Array)[1] as Callable).call(npc, choice) if prev != null else {}
	var r: Dictionary = page(choice.substr(CHOIX.length()), true)
	return {"texte": str(r["texte"]), "choix": r["choix"], "geste": "parle"}
