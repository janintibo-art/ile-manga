extends Node3D
## Extension « Le Château d'Ombrelac » (v14) : la vie à l'Académie (le gestionnaire des habitants).
##  - les lieux des habitants (« spots ») : les places assises (les bancs de la Grande Salle, les chaises
##    de l'estrade, les bancs des salles de cours, les chaises de la Bibliothèque, les canapés de la Salle
##    Commune…), et les postes debout (les paillasses des élixirs, le cercle des sortilèges, la fontaine,
##    la cour, les allées du jardin…). Un groupe (« @astres ») : toutes les places d'une salle ;
##  - le plan des chemins (chemins_ombrelac.gd, calculé par tools/ext_chateau_chemins.gd) : les couloirs
##    libres de chaque étage, d'un lieu à l'autre. D'un étage à l'autre, l'habitant passe d'un coup ;
##  - les sièges s'inscrivent dans bancs_v183.gd : on s'y assied à la bonne hauteur, face au bon côté ;
##  - le gestionnaire que demandent pnj_azur_v56 / pnj_montjoie_v71 : spot, spot_free, claim_spot,
##    release_spot, hostile_zone, concert_on, hour ; et spawn_npcs (les 18 habitants).
## Tout est dans le repère du château (son origine : le rocher, au niveau de la cour) ; le monde ensuite.

const HABITANTS := "res://scripts/ext_chateau/habitants_ombrelac.gd"
const CHEMINS := "res://scripts/ext_chateau/chemins_ombrelac.gd"
const PNJ := "res://scripts/pnj/pnj_montjoie_v71.gd"
const Bancs183 = preload("res://scripts/pnj/bancs_v183.gd")

## Les intérieurs (enfants du château) qui portent des sièges et des postes
const INTERIEURS := ["Ombrelac_interieurs", "Ombrelac_bibliotheque", "Ombrelac_salles", "Ombrelac_dortoirs", "Ombrelac_astrolabe_dedans",
	"Ombrelac_horloge_dedans", "Ombrelac_sortileges_dedans", "Ombrelac_grosse_tour_dedans"]
## Les groupes où l'on va et vient entre les places (les jeux de la cour, le service à table)
const VA_ET_VIENT := ["cour_jeu", "service"]
## Les maisons qui ne sont pas des lieux (on y dort, caché)
const MAISONS := ["dortoir_aube", "dortoir_crepuscule"]

var main: Node
var chateau: Node3D
var points: Dictionary = {}               # nœud → position (monde)
var graph: Dictionary = {}                # nœud → [voisins]
var spots: Dictionary = {}                # lieu → {pos, face, pose, node} (monde)
var groupes: Dictionary = {}              # groupe → [lieux]
var habitants: Array = []
var by_id: Dictionary = {}
var _claims: Dictionary = {}
var _built: bool = false


# =================================================================== les lieux (repère du château)

## Tous les lieux du château : {"spots": nom → {pos, face, pose, appr, siege}, "groupes": nom → [noms],
## "bancs": [[repère, dessus, largeur, arrière, avant]]}. « appr » : là où l'on arrive à pied (devant ou
## derrière le siège ; le lieu même, debout). Sert au jeu et à l'outil des chemins.
static func definir(ch: Node3D) -> Dictionary:
	var sp: Dictionary = {}
	var gr: Dictionary = {}
	var tous: Array = []
	var par: Dictionary = {}
	var postes: Dictionary = {}
	for nom in INTERIEURS:
		var n: Node = ch.get_node_or_null(nom)
		if n == null or n.get("bancs") == null:
			continue
		for b in n.bancs:
			tous.append(b)
			var pc: String = str(b[6])
			if not par.has(pc):
				par[pc] = []
			(par[pc] as Array).append(b)
		for k in n.postes:
			postes[k] = n.postes[k]
	var lieux: Dictionary = ch.get("lieux") if ch.get("lieux") != null else {}
	# --- les chaises de l'estrade (de la plus au nord à la plus au sud) : les maîtres, aux repas
	var est: Array = (par.get("estrade", []) as Array).duplicate()
	est.sort_custom(func(a, b): return (a[0] as Transform3D).origin.z < (b[0] as Transform3D).origin.z)
	for i in range(est.size()):
		_sieges(sp, gr, "", "estrade_s%d" % i, [est[i]], [0.0], "assis")
	# --- la Grande Salle : la table du milieu ; l'Aube à l'ouest, le Crépuscule à l'est
	var gs_o: Array = []
	var gs_e: Array = []
	for b in par.get("grande_salle", []):
		var o: Vector3 = (b[0] as Transform3D).origin
		if absf(o.z - 4.0) < 1.6:
			(gs_o if o.x < 0.0 else gs_e).append(b)
	var rang: Array = [-2.1, -1.4, -0.7, 0.0, 0.7, 1.4, 2.1]
	_sieges(sp, gr, "gs_aube", "gs_aube_", gs_o, rang, "assis")
	_sieges(sp, gr, "gs_crepuscule", "gs_crepuscule_", gs_e, rang, "assis")
	# --- les salles de cours, la Bibliothèque, la Salle Commune
	_sieges(sp, gr, "astres", "astres_", par.get("astres", []), [-0.6, 0.6], "assis")
	_sieges(sp, gr, "amphi", "amphi_", par.get("amphi", []), [-2.4, -1.2, 0.0, 1.2, 2.4], "assis")
	_sieges(sp, gr, "biblio", "biblio_", par.get("bibliotheque", []), [0.0], "lire")
	var canapes: Array = []
	var chaises_c: Array = []
	for b in par.get("commune", []):
		(canapes if float(b[2]) > 0.7 else chaises_c).append(b)
	_sieges(sp, gr, "commune", "commune_", canapes, [-0.7, 0.0, 0.7], "assis")
	_sieges(sp, gr, "commune", "commune_c", chaises_c, [0.0], "lire")
	# --- les autres sièges : le bureau de la Rectrice, l'observatoire, la salle de l'horloge
	for b in par.get("", []):
		var o2: Vector3 = (b[0] as Transform3D).origin
		if o2.y > 11.0 and o2.y < 13.0 and float(b[2]) > 0.75:
			_sieges(sp, gr, "", "bureau_recteur", [b], [0.0], "lire")
		elif o2.y > 53.0 and (b[0] as Transform3D).basis.z.z > 0.5:
			_sieges(sp, gr, "", "observatoire", [b], [0.0], "lire")
		elif o2.y < 1.0 and o2.x > 30.0 and o2.z > 25.0:
			_sieges(sp, gr, "", "horloge_salle", [b], [0.0], "lire")
	# --- les postes debout des salles : les maîtres, les paillasses des élixirs
	for k in postes:
		var e: Array = postes[k]
		if str(k).ends_with("_maitre"):
			_debout(sp, gr, "", str(k), e[0], e[1], "debout")
		elif str(k).begins_with("elixirs_"):
			_debout(sp, gr, "elixirs", str(k), e[0], e[1], "peindre")
	# --- le cercle des sortilèges : huit élèves autour de Dame Sortelame
	var sc: Vector3 = lieux.get("sortileges_centre", Vector3(-52, 0, 34))
	for i in range(8):
		var a: float = TAU * i / 8.0 + PI / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		_debout(sp, gr, "cercle", "cercle_%d" % i, sc + d * 2.6, -d, "debout")
	_debout(sp, gr, "", "sort_maitre", sc + Vector3(0.6, 0, 0), Vector3(-1, 0, 0), "bras_croises")
	_debout(sp, gr, "", "sort_cabinet", lieux.get("sortileges_cabinet", Vector3(-52, 24, 31.4)), Vector3(0, 0, 1), "bras_croises")
	# --- les hauteurs : la terrasse de l'Astrolabe, les rouages de l'horloge
	_debout(sp, gr, "", "terrasse", lieux.get("terrasse_astrolabe", Vector3(-44, 54, -17.9)), Vector3(0, 0, 1), "debout")
	_debout(sp, gr, "", "rouages", lieux.get("horloge_rouages", Vector3(38.4, 28, 36.6)), Vector3(0, 0, 1), "forger")
	# --- la Bibliothèque : le comptoir de Dame Reliure (à l'entrée)
	var bp: Vector3 = lieux.get("bibliotheque_porte", Vector3(43, 0, -8))
	_debout(sp, gr, "", "biblio_comptoir", bp + Vector3(7.6, 0, -1.0), Vector3(-1, 0, 0.3), "bras_croises")
	# --- la cour : le portier, les jeux, la promenade
	var po: Vector3 = lieux.get("porte", Vector3(0, 0, 64))
	_debout(sp, gr, "", "portier", po + Vector3(3.0, 0, -4.0), Vector3(-1, 0, 0.3), "bras_croises")
	var co: Vector3 = lieux.get("cour", Vector3(0, 0, 44))
	for i2 in range(6):
		var a2: float = TAU * i2 / 6.0
		var d2 := Vector3(cos(a2), 0, sin(a2))
		_debout(sp, gr, "cour_jeu", "cour_jeu_%d" % i2, co + Vector3(12.0, 0, 8.0) + d2 * 3.0, -d2, "jouer")
	# (à l'écart des allées : de la porte à la Grande Salle, de la cour aux tours)
	for e2 in [[-10.0, 37.0], [10.0, 37.0], [-14.0, 52.0], [-6.0, 57.0], [20.0, 48.0], [-20.0, 49.0]]:
		var p2: Vector3 = Vector3(float(e2[0]), 0, float(e2[1]))
		_debout(sp, gr, "cour", "cour_%d_%d" % [int(e2[0]), int(e2[1])], p2, (co - p2) * Vector3(1, 0, 1), "debout")
	# --- la fontaine du cloître (on bavarde autour, face à l'eau)
	var fo: Vector3 = lieux.get("fontaine", Vector3(10, 0, -23))
	for i3 in range(8):
		var a3: float = TAU * i3 / 8.0 + PI / 8.0
		var d3 := Vector3(cos(a3), 0, sin(a3))
		_debout(sp, gr, "fontaine", "fontaine_%d" % i3, fo + d3 * 4.9, -d3, "debout")
	# --- le jardin : Firmin taille les haies, le long des allées en croix
	for e3 in [[-8.0, -1.0], [0.0, -1.0], [20.0, -1.0], [28.0, -1.0], [-4.0, 1.0], [24.0, 1.0]]:
		var s: float = float(e3[1])
		var p3 := Vector3(float(e3[0]), 0, fo.z + s * 0.75)
		_debout(sp, gr, "jardin", "jardin_%d_%d" % [int(e3[0]), int(s)], p3, Vector3(0, 0, s), "petanque")
	for e4 in [[-30.0, -1.0], [-16.0, 1.0]]:
		var s2: float = float(e4[1])
		var p4 := Vector3(fo.x + s2 * 0.75, 0, float(e4[0]))
		_debout(sp, gr, "jardin", "jardin_x_%d" % int(e4[0]), p4, Vector3(s2, 0, 0), "petanque")
	# --- la Grande Salle : le service (entre les tables), la cheminée de Mère Fournil
	for x in [-17.0, -10.0, -5.0, 5.0, 10.0, 17.0]:
		_debout(sp, gr, "service", "service_n_%d" % int(x), Vector3(x, 0, 1.5), Vector3(0, 0, 1), "debout")
		_debout(sp, gr, "service", "service_s_%d" % int(x), Vector3(x, 0, 6.5), Vector3(0, 0, -1), "debout")
	_debout(sp, gr, "", "cheminee_feu", Vector3(24.6, 0, 4.0), Vector3(1, 0, 0), "debout")
	# --- la salle du conseil (la Grosse Tour, en bas) : les maîtres, en cercle
	var cs: Vector3 = lieux.get("grosse_conseil", Vector3(58.56, 0, -37.26))
	for i4 in range(5):
		var a4: float = TAU * i4 / 5.0
		var d4 := Vector3(cos(a4), 0, sin(a4))
		_debout(sp, gr, "conseil", "conseil_%d" % i4, cs + d4 * 1.4, -d4, "debout")
	# --- les serres (le jardinier, l'intendante, la maîtresse des élixirs)
	var se: Vector3 = lieux.get("serres", Vector3(46, 0, 36))
	_debout(sp, gr, "", "serres", se, Vector3(0, 0, -1), "petanque")
	for i5 in range(3):
		_debout(sp, gr, "serres", "serres_%d" % i5, se + Vector3(-2.0 + 2.0 * i5, 0, 1.6), Vector3(0, 0, 1), "petanque")
	var out: Array = []
	for b2 in tous:
		out.append([b2[0], b2[1], b2[2], b2[3], b2[4]])
	return {"spots": sp, "groupes": gr, "bancs": out, "maisons": {"dortoir_aube": lieux.get("dortoir_aube", Vector3(-2.75, 6.25, -46)),
		"dortoir_crepuscule": lieux.get("dortoir_crepuscule", Vector3(31.55, 6.25, -46))}}


## Des places assises le long de chaque banc (aux décalages « rang » du milieu, dans sa largeur)
static func _sieges(sp: Dictionary, gr: Dictionary, groupe: String, nom: String, bancs: Array, rang: Array, pose: String) -> void:
	var k: int = 0
	for b in bancs:
		var t: Transform3D = b[0]
		var lg: float = float(b[2])
		var mz: float = (float(b[3]) + float(b[4])) * 0.5
		for dx in rang:
			if absf(float(dx)) > lg * 0.5 - 0.25 and float(dx) != 0.0:
				continue
			var n: String = nom if groupe == "" else nom + str(k)
			k += 1
			sp[n] = {"pos": t * Vector3(float(dx), 0, mz), "face": t.basis.z.normalized(), "pose": pose,
				"appr": t * Vector3(float(dx), 0, float(b[5])), "siege": true}
			if groupe != "":
				if not gr.has(groupe):
					gr[groupe] = []
				(gr[groupe] as Array).append(n)


static func _debout(sp: Dictionary, gr: Dictionary, groupe: String, nom: String, p: Vector3, face: Vector3, pose: String) -> void:
	sp[nom] = {"pos": p, "face": face.normalized(), "pose": pose, "appr": p, "siege": false}
	if groupe != "":
		if not gr.has(groupe):
			gr[groupe] = []
		(gr[groupe] as Array).append(nom)


# =================================================================== dans le monde

func _xf() -> Transform3D:
	return chateau.global_transform if chateau.is_inside_tree() else chateau.transform


## Les lieux, les sièges et les chemins, dans le monde
func build(the_main: Node, the_chateau: Node3D) -> void:
	main = the_main
	chateau = the_chateau
	var xf: Transform3D = _xf()
	var d: Dictionary = definir(chateau)
	for b in d["bancs"]:
		Bancs183.ajouter(xf * (b[0] as Transform3D), float(b[1]), float(b[2]), float(b[3]), float(b[4]))
	if ResourceLoader.exists(CHEMINS):
		var C = load(CHEMINS)
		for n in C.POINTS:
			points[str(n)] = xf * (C.POINTS[n] as Vector3)
		for l in C.LIENS:
			_link(str(l[0]), str(l[1]))
	for m in MAISONS:
		if not points.has(m):
			points[m] = xf * (d["maisons"][m] as Vector3)
	var sd: Dictionary = d["spots"]
	for nom in sd:
		var e: Dictionary = sd[nom]
		# un lieu sans chemin (bouché, ou le château a changé depuis le calcul des chemins) : on l'oublie
		if not points.has(nom):
			continue
		var pw: Vector3 = xf * (e["pos"] as Vector3)
		if bool(e["siege"]):
			# le siège a son point à lui (relié au point d'approche) : on se lève, on fait un pas en
			# arrière ou de côté, puis on s'en va (sans traverser la table qui est devant)
			var ap: String = nom + "~"
			points[ap] = points[nom]
			for nb in graph.get(nom, []):
				_link(ap, str(nb))
				(graph[nb] as Array).erase(nom)
			graph[nom] = []
			points[nom] = Vector3(pw.x, (points[ap] as Vector3).y, pw.z)
			_link(nom, ap)
		spots[nom] = {"pos": pw, "face": (xf.basis * (e["face"] as Vector3)).normalized(), "pose": e["pose"], "node": nom}
	for g in d["groupes"]:
		var ok: Array = (d["groupes"][g] as Array).filter(func(s): return spots.has(s))
		if not ok.is_empty():
			groupes[g] = ok
	_built = true


func _link(a: String, b: String) -> void:
	if a == b:
		return
	for pair in [[a, b], [b, a]]:
		if not graph.has(pair[0]):
			graph[pair[0]] = []
		if not (graph[pair[0]] as Array).has(pair[1]):
			(graph[pair[0]] as Array).append(pair[1])


## L'emploi du temps d'un habitant, ses groupes « @… » remplacés par leurs places
func agenda_monde(agenda: Array) -> Array:
	var out: Array = []
	for e in agenda:
		var w: Variant = e[2]
		if w is String and (w as String).begins_with("@"):
			var g: String = (w as String).substr(1)
			var arr: Array = groupes.get(g, [])
			if arr.is_empty():
				out.append([e[0], e[1], "maison"])
			elif g in VA_ET_VIENT:
				out.append([e[0], e[1], arr.duplicate(), arr.duplicate()])
			else:
				out.append([e[0], e[1], arr.duplicate()])
		else:
			out.append(e.duplicate())
	return out


# =================================================================== pour les habitants (le gestionnaire)

func spot(nom: String) -> Dictionary:
	return spots.get(nom, {})


func spot_free(nom: String, who: Node) -> bool:
	var c: Variant = _claims.get(nom, null)
	return c == null or c == who or not is_instance_valid(c)


func claim_spot(nom: String, who: Node) -> void:
	_claims[nom] = who


func release_spot(nom: String, who: Node) -> void:
	if _claims.get(nom, null) == who:
		_claims.erase(nom)


func hostile_zone(_p: Vector3) -> bool:
	return false


func concert_on() -> bool:
	return false


func hour() -> float:
	return float(main.temps_v56.hour) if main != null and main.get("temps_v56") != null and main.temps_v56 != null else 12.0


## Les dix-huit habitants (une fois ; ceux d'une partie enregistrée reprennent leur mémoire)
func spawn_npcs() -> void:
	if not habitants.is_empty() or not _built or main == null or main.get("npcs_v31") == null:
		return
	if not ResourceLoader.exists(HABITANTS) or not ResourceLoader.exists(PNJ):
		return
	var H = load(HABITANTS)
	var P = load(PNJ)
	for d0 in H.all_profiles():
		var data: Dictionary = (d0 as Dictionary).duplicate(true)
		data["agenda"] = agenda_monde(data.get("agenda", []))
		var home: String = str(data.get("maison", ""))
		var start: String = home if points.has(home) else str(points.keys()[0])
		var npc: Node3D = P.new()
		main.add_child(npc)
		npc.setup(main, data, points, graph, start)
		npc.setup_azur(self, data)
		var pend: Variant = main.get("pending_pnj_v31")
		var saved: Variant = (pend as Dictionary).get(str(data["id"]), {}) if pend is Dictionary else {}
		if saved is Dictionary and not (saved as Dictionary).is_empty():
			npc.load_data(saved)
		main.npcs_v31.append(npc)
		habitants.append(npc)
		by_id[str(data["id"])] = npc
	print("OMBRELAC: %d habitants à l'Académie" % habitants.size())
