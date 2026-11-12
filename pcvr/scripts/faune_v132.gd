extends Node3D
## V132 : la faune sauvage des îles. Loin des villages et des habitants (dans les plaines, les
## forêts, sur les chemins entre deux hameaux), des bêtes vivent leur vie : elles apparaissent
## hors de vue, à bonne distance du héros, et s'en vont quand il s'éloigne.
## Chaque île a sa faune, plus nombreuse et plus dangereuse la nuit :
##  - l'île du village reste paisible : des crabes des sables sur les plages et des mouettes
##    chapardeuses (elles volent à manger, on peut les faire lâcher en les frappant) ;
##  - le Bois-Doré des elfes : sangliers qui chargent, ronceux cachés dans les fourrés, et la
##    nuit, des loups en meute ;
##  - la Montagne de Feu : salamandres de braise qui crachent du feu, boucs des roches qui
##    défendent leur coin, et la nuit, des nuées de chauves-souris des cendres.
## V133 : trois îles de plus (les bêtes elles-mêmes sont dans monstre_v133.gd) :
##  - la grande île de l'est, région par région : aurochs dans les prairies de l'ouest, ours et
##    boucs sur les hautes terres du nord, crapauds dans la forêt des brumes de l'est (et la nuit,
##    des feux follets au-dessus des mares), scorpions et serpents des sables dans le désert du
##    sud ; la nuit, des loups des plaines ;
##  - l'Île Al Dente : boulettes enragées qui roulent, spaghettis sauvages qui fouettent, et la
##    nuit, des tomates kamikazes ;
##  - l'Île Crayonnée : gribouillis en bande, taches d'encre qui bondissent, et la nuit, une gomme
##    géante qui efface tout devant elle.
## Les taches (encre, sauce, gomme) restent un moment au sol, puis s'effacent.
## V135 : deux îles de plus (les bêtes elles-mêmes sont dans monstre_v135.gd) :
##  - l'île de la jungle : singes hurleurs qui lancent des fruits, mille-pattes géants ; la nuit,
##    araignées géantes et nuées de lucioles (paisibles) ;
##  - l'Île des Trois Soleils, région par région : côté égyptien (le fleuve et le désert),
##    crocodiles tapis dans l'eau et scarabées géants qui poussent leur boule, la nuit des chacals ;
##    côté maya (les collines de jungle), coatis chapardeurs et singes, la nuit le jaguar et les
##    lucioles ; côté aztèque (le lac, le volcan, les hautes terres), aigles royaux, salamandres
##    sur les pentes du volcan, axolotls paisibles dans les jardins flottants, la nuit des coyotes
##    et des chauves-souris.
## V136 : trois îles du nord (les bêtes elles-mêmes sont dans monstre_v136.gd) :
##  - l'Île aux Moaïs : des chevaux sauvages en troupeau (ils ruent si on les frappe par derrière)
##    et des frégates qui plongent pêcher en mer ; la nuit, des tortues vertes viennent pondre sur
##    la plage ;
##  - l'Île de la Balafre : des aras bavards (ils crient des mots de pirate) et des varans ; la nuit,
##    des crabes de cocotier à la carapace très dure ;
##  - l'Île de Larsen : des lapins de garenne (ils plongent dans leur terrier), des frelons et un
##    renard chapardeur ; la nuit, des hérissons qui se roulent en boule et un grand-duc.
## Sous terre (un souterrain, une grotte), rien ne naît.
## V137 : les trois îles du ciel (les bêtes elles-mêmes sont dans monstre_v137.gd). Leur sol n'est
## pas celui de l'archipel : chaque île flottante a son relief, à son altitude ; les bêtes y
## naissent loin du bord, et ne s'avancent pas dans le vide.
##  - le royaume des fées : des papillons morphos (ils viennent se poser sur le héros s'il ne
##    bouge plus) et le cerf blanc, qu'on ne peut pas toucher ; la nuit, des lucioles et des
##    blaireaux qui défendent leur terrier ;
##  - l'île flottante : des marmottes (la sentinelle siffle, toutes plongent dans leur terrier) et
##    le gypaète, qui lâche des os sur les rochers ; la nuit, le lynx, à l'affût dans l'herbe ;
##  - Astralys : des raies célestes qui planent et des méduses de ciel sauvages qui dérivent (leurs
##    filaments piquent), lumineuses la nuit.
## Des milieux de plus pour naître : « fleuve » (au bord et dans l'eau peu profonde), « lac » (les
## rives et les jardins flottants du lac de la Lune), « volcan » (les pentes du Mont Fumant).
## Les bêtes ont leur propre gestionnaire (pas celui des donjons) : elles ne se mêlent pas aux
## monstres des quêtes. Dans les tests sans écran, la faune dort (enabled = false), sauf si
## une suite la réveille.

const Bete := preload("res://scripts/monstre_v137.gd")
const IleSoleils := preload("res://scripts/ile_soleils_v69.gd")

## île -> {"jour": [[espèce, nombre max, milieu, taille du groupe]…], "nuit": […]}
const ILES := {
	"village": {"jour": [["crabe_plage", 4, "plage", 1], ["mouette", 2, "air", 1]],
		"nuit": [["crabe_plage", 3, "plage", 1]]},
	"elfes": {"jour": [["sanglier", 3, "sol", 1], ["ronceux_sauvage", 3, "sol", 1]],
		"nuit": [["sanglier", 2, "sol", 1], ["ronceux_sauvage", 2, "sol", 1], ["loup_bois", 3, "sol", 3]]},
	"nains": {"jour": [["salamandre", 3, "sol", 1], ["bouc", 2, "sol", 1]],
		"nuit": [["salamandre", 3, "sol", 1], ["chauve_souris_mont", 4, "air", 4]]},
	# V133 : la grande île a une faune par région (celle où se trouve le héros)
	"grande": {"regions": {
		"ouest": {"jour": [["aurochs", 3, "sol", 1]],
			"nuit": [["aurochs", 2, "sol", 1], ["loup_plaine", 3, "sol", 3]]},
		"nord": {"jour": [["ours_lande", 1, "sol", 1], ["bouc", 2, "sol", 1]],
			"nuit": [["ours_lande", 1, "sol", 1], ["loup_plaine", 3, "sol", 3]]},
		"est": {"jour": [["crapaud_vase", 3, "sol", 1], ["sanglier", 2, "sol", 1]],
			"nuit": [["crapaud_vase", 2, "sol", 1], ["feu_follet", 3, "air", 3]]},
		"sud": {"jour": [["scorpion_dunes", 2, "sol", 1], ["serpent_sable", 3, "sol", 1]],
			"nuit": [["scorpion_dunes", 3, "sol", 1], ["serpent_sable", 2, "sol", 1]]}}},
	"aldente": {"jour": [["boulette", 3, "sol", 1], ["spaghetti_sauvage", 2, "sol", 1]],
		"nuit": [["boulette", 2, "sol", 1], ["spaghetti_sauvage", 2, "sol", 1], ["tomate_kamikaze", 4, "sol", 2]]},
	"crayon": {"jour": [["gribouillis", 3, "sol", 3], ["tache_encre", 3, "sol", 1]],
		"nuit": [["gribouillis", 3, "sol", 3], ["tache_encre", 2, "sol", 1], ["gomme_geante", 1, "sol", 1]]},
	# V135
	"jungle": {"jour": [["singe_hurleur", 4, "sol", 2], ["mille_pattes", 2, "sol", 1]],
		"nuit": [["araignee_geante", 2, "sol", 1], ["mille_pattes", 1, "sol", 1], ["luciole", 3, "air", 3]]},
	"soleils": {"regions": {
		"egypte": {"jour": [["crocodile", 2, "fleuve", 1], ["scarabee_geant", 3, "sol", 1]],
			"nuit": [["crocodile", 2, "fleuve", 1], ["chacal", 3, "sol", 3]]},
		"maya": {"jour": [["coati", 2, "sol", 1], ["singe_hurleur", 2, "sol", 2]],
			"nuit": [["jaguar_sauvage", 1, "sol", 1], ["luciole", 3, "air", 3]]},
		"azteque": {"jour": [["aigle_royal", 1, "air", 1], ["salamandre", 2, "volcan", 1], ["axolotl", 3, "lac", 1]],
			"nuit": [["coyote", 3, "sol", 3], ["chauve_souris_mont", 4, "air", 4]]}}},
	# V136
	"moai": {"jour": [["cheval_sauvage", 4, "sol", 4], ["fregate", 2, "air", 1]],
		"nuit": [["tortue_verte", 3, "plage", 1], ["cheval_sauvage", 3, "sol", 3]]},
	"balafre": {"jour": [["perroquet", 3, "air", 3], ["varan", 2, "sol", 1]],
		"nuit": [["crabe_cocotier", 3, "sol", 1], ["varan", 1, "sol", 1]]},
	"larsen": {"jour": [["lapin_garenne", 4, "sol", 2], ["frelon", 1, "air", 1], ["renard_roux", 1, "sol", 1]],
		"nuit": [["herisson", 3, "sol", 1], ["hibou_grand_duc", 1, "air", 1], ["renard_roux", 1, "sol", 1]]},
	# V137 : les îles du ciel
	"fees": {"jour": [["papillon_morpho", 2, "air", 1], ["cerf_blanc", 2, "sol", 1]],
		"nuit": [["luciole", 3, "air", 3], ["blaireau", 2, "sol", 1], ["cerf_blanc", 1, "sol", 1]]},
	"celeste": {"jour": [["marmotte", 3, "sol", 3], ["gypaete", 1, "air", 1]],
		"nuit": [["lynx", 1, "sol", 1]]},
	"astrale": {"jour": [["raie_celeste", 3, "air", 3], ["meduse_celeste", 4, "air", 2]],
		"nuit": [["meduse_celeste", 5, "air", 2]]},
}
const MAX_TOTAL: int = 11
const LOIN: float = 120.0                # au-delà, la bête s'en va

var main: Node
var enabled: bool = true
var active: bool = false
var donjon: Node
var betes: Array = []
var iles: Dictionary = {}                # id -> {"c": Vector3, "r": float}
var ile_joueur: String = ""
var spawned: Dictionary = {}             # tests : espèce -> nombre d'apparitions
var vols: int = 0                        # tests : mouettes qui ont chipé quelque chose
var rendus: int = 0
var _rng := RandomNumberGenerator.new()
var _tick: float = 1.0
var _npc_pos: Array = []
var _npc_t: float = 0.0
var _cool: Dictionary = {}               # espèce -> temps avant de revenir
var _token: Node = null
var _token_t: float = 0.0
var _steal_cd: float = 240.0
var _chap_cd: float = 60.0               # V135 : le coati ne revient pas chiper tout de suite
var _swoop_t: float = 60.0
var _spits: Array = []
var _decals: Array = []                  # V133 : taches d'encre, de sauce, de gomme au sol
static var _decal_tex: Dictionary = {}
var taches: Dictionary = {}              # tests : sorte de tache -> nombre posées
var os_tombes: int = 0                   # tests (V137) : os lâchés par le gypaète, éclatés au sol


func setup(main_node: Node) -> void:
	main = main_node
	name = "Faune_v132"
	donjon = main.get("donjon_v35")
	_rng.randomize()
	enabled = DisplayServer.get_name() != "headless"


# =================================================================== les îles

func _resolve_iles() -> void:
	if not iles.is_empty():
		return
	var centres := {"village": Vector3.ZERO}
	var e: Node = main.get("elfes_v41")
	if e != null and e.get("ile") != null:
		centres["elfes"] = e.ile.CENTER
	var n: Node = main.get("nains_v46")
	if n != null and n.get("ile") != null:
		centres["nains"] = n.ile.CENTER
	# V133
	for e2 in [["grande", "grande_v59"], ["aldente", "pasta_v97"], ["crayon", "crayon_v99"], ["soleils", "soleils_v69"],
			["moai", "moai_v87"], ["balafre", "pirates_v68"], ["larsen", "larsen_v91"]]:
		var w: Node = main.get(str(e2[1]))
		if w != null and w.get("ile") != null:
			centres[str(e2[0])] = w.ile.CENTER
	# V135 : l'île de la jungle est son propre relief
	var jg: Node = main.get("jungle_v29")
	if jg != null:
		centres["jungle"] = jg.CENTER
	for id in centres:
		var c: Vector3 = centres[id]
		iles[id] = {"c": c, "r": _rayon(c)}
	# V137 : les îles du ciel (leur relief à elles, à leur altitude)
	for e3 in [["fees", "feerie_v58"], ["celeste", "ciel_v54"], ["astrale", "astralys_v76"]]:
		var w2: Node = main.get(str(e3[1]))
		if w2 != null and w2.get("ile") != null and w2.ile.has_method("height"):
			var il: Node = w2.ile
			iles[str(e3[0])] = {"c": Vector3(il.CENTER.x, 0.0, il.CENTER.z), "r": float(il.R0), "y": float(il.Y0), "sol": Callable(il, "height")}
	print("ILE_MANGA_V132: faune sauvage sur ", iles.keys(), " ", iles)


## V137 : la hauteur du sol sur l'île « ile » (celle du héros si on ne dit rien). Sur une île du
## ciel, son relief ; hors de son bord, le vide (bien plus bas que l'île).
func hauteur(x: float, z: float, ile: String = "") -> float:
	var e: Dictionary = iles.get(ile if ile != "" else ile_joueur, {})
	if e.has("sol"):
		var h: float = float((e["sol"] as Callable).call(x, z))
		return h if h > -1e6 else float(e["y"]) - 100.0
	return float(main._height_at(x, z))


## L'altitude d'une île du ciel (-INF pour une île de l'archipel).
func niveau_ile(ile: String) -> float:
	var e: Dictionary = iles.get(ile, {})
	return float(e["y"]) if e.has("y") else -INF


## Le vide, au bord d'une île du ciel ?
func vide(p: Vector3, ile: String = "") -> bool:
	var e: Dictionary = iles.get(ile if ile != "" else ile_joueur, {})
	if not e.has("sol"):
		return false
	return not (float((e["sol"] as Callable).call(p.x, p.z)) > -1e6)


## Sur la terre ferme de l'île, à bonne distance du bord (pour une île du ciel).
func sur_ile(ile: String, q: Vector3) -> bool:
	var e: Dictionary = iles.get(ile, {})
	if not e.has("sol"):
		return true
	var f: Callable = e["sol"]
	for o in [Vector2.ZERO, Vector2(6, 0), Vector2(-6, 0), Vector2(0, 6), Vector2(0, -6)]:
		if not (float(f.call(q.x + o.x, q.z + o.y)) > -1e6):
			return false
	return true


## Le rayon d'une île : on marche du centre vers le large jusqu'à la mer, dans 16 directions.
func _rayon(c: Vector3) -> float:
	var rs: Array = []
	for k in range(16):
		var a: float = TAU * k / 16.0
		var last: float = 0.0
		var wet: int = 0
		var r: float = 8.0
		while r < 420.0:
			var h: float = main._height_at(c.x + cos(a) * r, c.z + sin(a) * r)
			if h < -0.3:
				wet += 1
				if wet >= 3:
					break
			else:
				wet = 0
				last = r
			r += 4.0
		rs.append(last)
	rs.sort()
	return float(rs[int(rs.size() * 0.8)])


func ile_de(p: Vector3) -> String:
	var best: String = ""
	var bk: float = 1.0
	var bas: float = -INF
	for id in iles:
		var e: Dictionary = iles[id]
		# V137 : une île du ciel, seulement à son altitude ; une île de l'archipel, pas de très haut
		if e.has("y"):
			if p.y < float(e["y"]) - 40.0 or p.y > float(e["y"]) + 80.0:
				continue
		else:
			if bas == -INF:
				bas = float(main._height_at(p.x, p.z))
			if p.y > bas + 60.0:
				continue
		var d: float = Vector2(p.x - (e["c"] as Vector3).x, p.z - (e["c"] as Vector3).z).length() / maxf(float(e["r"]), 1.0)
		if d < bk:
			bk = d
			best = id
	return best


# =================================================================== chaque instant

func _process(delta: float) -> void:
	if main == null:
		return
	var started: bool = bool(main.get("game_started"))
	var menu: Node = main.get("game_menu")
	var dlg: Node = main.get("dialogue_v31")
	active = enabled and started and (menu == null or not bool(menu.opened)) and (dlg == null or not bool(dlg.opened))
	_tick_spits(delta)
	_tick_decals(delta)
	if _token != null and (not is_instance_valid(_token) or _token_t <= 0.0):
		_token = null
	_token_t -= delta
	for k in _cool.keys():
		_cool[k] = float(_cool[k]) - delta
	_steal_cd -= delta
	_chap_cd -= delta
	if not enabled or not started:
		return
	_tick -= delta
	if _tick > 0.0:
		return
	_tick = 2.0
	_resolve_iles()
	var p: Vector3 = main._player_pos_v27()
	ile_joueur = ile_de(p)
	_npc_t -= 2.0
	if _npc_t <= 0.0:
		_npc_t = 6.0
		_refresh_npcs(p)
	# celles qui sont trop loin s'en vont
	for b in betes.duplicate():
		if not is_instance_valid(b):
			betes.erase(b)
		elif b.state != "mort" and (b as Node3D).global_position.distance_to(p) > LOIN:
			betes.erase(b)
			b.queue_free()
	if ile_joueur == "" or not active or _blocked(p):
		return
	_maybe_spawn(p)
	if ile_joueur == "village":
		_gulls(p)


func _blocked(p: Vector3) -> bool:
	var mv: Node = main.get("maisons_v81")
	if mv != null and bool(mv.get("inside")):
		return true
	if donjon != null and bool(donjon.get("inside")):
		return true
	# en vol (l'aigle, l'aéronef) : rien ne naît sous les ailes
	var hp: float = hauteur(p.x, p.z)
	if p.y - hp > 8.0:
		return true
	# V136 : sous terre (un souterrain, une grotte) non plus
	if p.y < hp - 4.0:
		return true
	return false


func _refresh_npcs(p: Vector3) -> void:
	_npc_pos.clear()
	for n in main.npcs_v31:
		if is_instance_valid(n):
			var q: Vector3 = (n as Node3D).global_position
			if q.distance_to(p) < 220.0:
				_npc_pos.append(q)


func night() -> bool:
	var t: Node = main.get("temps_v56")
	return t != null and t.has_method("is_night") and bool(t.is_night())


func _count(kind: String) -> int:
	var n: int = 0
	for b in betes:
		if is_instance_valid(b) and str(b.kind) == kind and b.state != "mort":
			n += 1
	return n


func _maybe_spawn(p: Vector3) -> void:
	var alive: int = 0
	for b in betes:
		if is_instance_valid(b) and b.state != "mort":
			alive += 1
	if alive >= MAX_TOTAL:
		return
	var region: String = region_de(ile_joueur, p)
	var table: Array = table_de(ile_joueur, region)
	var choix: Array = []
	for e in table:
		var kind: String = e[0]
		if _count(kind) + int(e[3]) <= int(e[1]) and float(_cool.get(kind, 0.0)) <= 0.0:
			choix.append(e)
	if choix.is_empty():
		return
	var e2: Array = choix[_rng.randi() % choix.size()]
	var at: Vector3 = _spot(p, str(e2[2]), str(e2[0]), region)
	if at == Vector3.INF:
		return
	# V136 : les chevaux du troupeau naissent un peu plus écartés
	var ecart: float = 5.0 if str(e2[0]) == "cheval_sauvage" else 2.5
	for i in range(int(e2[3])):
		var off := Vector3(_rng.randf_range(-ecart, ecart), 0, _rng.randf_range(-ecart, ecart)) if i > 0 else Vector3.ZERO
		var q: Vector3 = at + off
		if not sur_ile(ile_joueur, q):
			continue
		if str(e2[2]) != "air":
			q.y = hauteur(q.x, q.z) + 0.1
		spawn(str(e2[0]), q)


## V133 : la région de la grande île (« ouest », « nord », « est », « sud ») ; "" ailleurs.
## V135 : l'Île des Trois Soleils : « egypte » (à l'est : le fleuve, Per-Hâpy, le plateau de Rê),
## « maya » (au nord : les collines de jungle, Yaxché), « azteque » (le reste : le lac de la Lune,
## Aztlán, le Mont Fumant, les hautes terres).
func region_de(id: String, p: Vector3) -> String:
	if id == "soleils":
		var lx: float = p.x - IleSoleils.CENTER.x
		var lz: float = p.z - IleSoleils.CENTER.z
		if lx > 70.0:
			return "egypte"
		if lz < -55.0:
			return "maya"
		return "azteque"
	if id != "grande":
		return ""
	var g: Node = main.get("grande_v59")
	if g == null or g.get("ile") == null or not g.ile.has_method("region_name"):
		return ""
	return str(g.ile.region_name(p.x, p.z))


## Les bêtes possibles sur cette île (dans cette région), de jour ou de nuit.
func table_de(id: String, region: String = "") -> Array:
	if not ILES.has(id):
		return []
	var e: Dictionary = ILES[id]
	var key: String = "nuit" if night() else "jour"
	if e.has("regions"):
		var r: Dictionary = e["regions"]
		return (r[region] as Dictionary).get(key, []) if r.has(region) else []
	return e[key]


## Une bête de plus (les tests l'appellent aussi directement).
func spawn(kind: String, at: Vector3) -> Node3D:
	var b: CharacterBody3D = Bete.new()
	add_child(b)
	# V137 : la bête connaît son île (son sol, sur une île du ciel)
	if "ile_sol" in b:
		var il2: String = ile_de(at)
		b.ile_sol = il2 if il2 != "" else "-"
	b.setup(self, kind, at)
	b.died.connect(_on_died)
	betes.append(b)
	spawned[kind] = int(spawned.get(kind, 0)) + 1
	if kind in ["loup_bois", "loup_plaine", "chacal", "coyote"] and _count(kind) == 1:
		main.sfx({"chacal": "chacal_glapit", "coyote": "coyote_hurle"}.get(kind, "loup_hurle"), at + Vector3.UP)
	return b


## Un endroit pour naître : sur l'île, dans son milieu (plage, sol, ciel), loin des habitants,
## hors du regard, sans toit ni mur au-dessus.
func _spot(p: Vector3, milieu: String, kind: String, region: String = "") -> Vector3:
	var e: Dictionary = iles[ile_joueur]
	var c: Vector3 = e["c"]
	var peaceful: bool = int(Bete.spec_of(kind)["degats"]) == 0
	var far_npc: float = 12.0 if peaceful else 32.0
	var cam: Camera3D = get_viewport().get_camera_3d() if is_inside_tree() else null
	for tries in range(14):
		var a: float = _rng.randf() * TAU
		var d: float = _rng.randf_range(16.0, 42.0) if peaceful else _rng.randf_range(28.0, 55.0)
		var q := Vector3(p.x + cos(a) * d, 0, p.z + sin(a) * d)
		if Vector2(q.x - c.x, q.z - c.z).length() > float(e["r"]) * 0.97:
			continue
		if not sur_ile(ile_joueur, q):
			continue
		var h: float = hauteur(q.x, q.z)
		if not milieu_ok(q, h, milieu):
			continue
		# V133 : sur la grande île, la bête naît dans la région du héros
		if region != "" and region_de(ile_joueur, q) != region:
			continue
		var ok: bool = true
		for np in _npc_pos:
			if Vector2((np as Vector3).x - q.x, (np as Vector3).z - q.z).length() < far_npc:
				ok = false
				break
		if not ok:
			continue
		# hors du regard (sauf si on a beaucoup cherché)
		if cam != null and tries < 9:
			var to: Vector3 = Vector3(q.x, h + 1.0, q.z) - cam.global_position
			if to.normalized().dot(-cam.global_basis.z) > 0.55 and to.length() < 60.0:
				continue
		# pas de toit, de mur, de rocher posé au-dessus
		if is_inside_tree():
			var space := get_world_3d().direct_space_state
			var ray := PhysicsRayQueryParameters3D.create(Vector3(q.x, h + 40.0, q.z), Vector3(q.x, h - 2.0, q.z), 1)
			var hit: Dictionary = space.intersect_ray(ray)
			if not hit.is_empty() and float(hit.position.y) > h + 0.9:
				continue
		q.y = (h + (float(_rng.randf_range(10.0, 16.0)) if kind == "mouette" else 2.8)) if milieu == "air" else h + 0.1
		return q
	return Vector3.INF


## Le milieu où une bête peut naître : la plage, la terre ferme pas trop pentue, le ciel ; V135 :
## le fleuve (l'eau peu profonde et ses bords), le lac de la Lune (rives et jardins flottants),
## les pentes du Mont Fumant.
func milieu_ok(q: Vector3, h: float, milieu: String) -> bool:
	match milieu:
		"plage":
			return h >= 0.15 and h <= 2.2
		"sol", "volcan":
			if h < 1.2:
				return false
			if absf(hauteur(q.x + 1.5, q.z) - h) > 1.1 or absf(hauteur(q.x, q.z + 1.5) - h) > 1.1:
				return false
			if milieu == "volcan":
				return Vector2(q.x - IleSoleils.CENTER.x, q.z - IleSoleils.CENTER.z).distance_to(IleSoleils.VOLCANO) < 115.0
			return true
		"air":
			return h >= 0.3
		"fleuve":
			return h >= -1.3 and h <= 0.1
		"lac":
			var lq: float = IleSoleils.lake_q(q.x - IleSoleils.CENTER.x, q.z - IleSoleils.CENTER.z)
			return lq > 0.62 and lq < 1.12 and h > IleSoleils.LAKE_Y - 0.25 and h < IleSoleils.LAKE_Y + 0.8
	return false


## Les bêtes sauvages menaçantes autour du héros (les cœurs en VR, comme dans les donjons).
func hostile_zone(p: Vector3) -> bool:
	for b in betes:
		if is_instance_valid(b) and b.state != "mort" and not bool(b.peaceful) and (b as Node3D).global_position.distance_to(p) < 30.0:
			return true
	return false


# =================================================================== ce que les bêtes demandent

func alert(m: Node3D) -> void:
	var mo: Node = main.get("monstres_v36")
	if mo != null:
		mo.alert(m)


func hurt_player(amount: int, from_pos: Vector3) -> void:
	var mo: Node = main.get("monstres_v36")
	if mo != null:
		mo.hurt_player(amount, from_pos)


func spawn_extra(kind: String, at: Vector3) -> Node3D:
	return spawn(kind, at) if Bete.has_kind(kind) else null


## Un seul loup (ou une seule chauve-souris) attaque à la fois.
func take_token(b: Node) -> bool:
	if _token == null or not is_instance_valid(_token) or _token == b:
		_token = b
		_token_t = 2.5
		return true
	return false


func release_token(b: Node) -> void:
	if _token == b:
		_token = null


## Le héros est bousculé (charge du sanglier, coup de tête du bouc).
func shove(v: Vector3) -> void:
	var body: CharacterBody3D = null
	if bool(main.get("xr_active")) and main.get("vr_body") != null:
		body = main.vr_body
	elif main.get("pc_body") != null:
		body = main.pc_body
	if body != null and is_instance_valid(body):
		body.move_and_collide(Vector3(v.x, 0.0, v.z) * 0.12)


func _on_died(m: Node3D) -> void:
	betes.erase(m)
	_cool[str(m.kind)] = 25.0
	# la tomate qui a éclaté d'elle-même ne rapporte rien
	if m.get("_explose") == true:
		return
	if main.get("progression_v63") != null and main.progression_v63 != null:
		main.progression_v63.on_kill(str(m.kind), m.global_position + Vector3.UP * 1.0)
	var gains: Array = m.loot(_rng) if m.has_method("loot") else []
	var parts: Array = []
	for g in gains:
		var got: int = main.inventory_v28.add(str(g[0]), int(g[1]))
		if got > 0:
			parts.append("+%d %s" % [got, str(main.inventory_v28.ITEMS[str(g[0])]["name"])])
	if not parts.is_empty() and main.combat_v28 != null:
		main.combat_v28.float_text(m.global_position + Vector3.UP * 1.2, "  ".join(parts), Color(1.0, 0.9, 0.5))


# =================================================================== les crachats de braise

## V135 : « sorte » = "braise" (la salamandre) ou "fruit" (la mangue que lance le singe hurleur).
func spit(from: Vector3, to: Vector3, dmg: int, sorte: String = "braise") -> void:
	var n := Node3D.new()
	add_child(n)
	n.global_position = from
	var mi := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.13
	s.height = 0.26
	var m := StandardMaterial3D.new()
	if sorte == "fruit":
		# une mangue : ovale, jaune orangé virant au vert, luisante
		mi.scale = Vector3(0.62, 0.8, 0.62)
		m.albedo_color = Color(0.95, 0.6, 0.12)
		m.roughness = 0.4
		var tige := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.008
		cyl.bottom_radius = 0.012
		cyl.height = 0.05
		var tm := StandardMaterial3D.new()
		tm.albedo_color = Color(0.3, 0.4, 0.12)
		cyl.material = tm
		tige.mesh = cyl
		tige.position = Vector3(0, 0.12, 0)
		mi.add_child(tige)
	elif sorte == "os":
		# V137 : un os long (le gypaète le lâche de haut sur les rochers)
		var cap := CapsuleMesh.new()
		cap.radius = 0.035
		cap.height = 0.42
		mi.rotation = Vector3(0, 0, PI * 0.5)
		m.albedo_color = Color(0.9, 0.86, 0.76)
		m.roughness = 0.7
		cap.material = m
		mi.mesh = cap
		for sx in [-1.0, 1.0]:
			var bout := MeshInstance3D.new()
			var sb := SphereMesh.new()
			sb.radius = 0.055
			sb.height = 0.1
			sb.material = m
			bout.mesh = sb
			bout.position = Vector3(0, sx * 0.2, 0)
			mi.add_child(bout)
	else:
		m.albedo_color = Color(1.0, 0.55, 0.15)
		m.emission_enabled = true
		m.emission = Color(1.0, 0.45, 0.1)
		m.emission_energy_multiplier = 4.0
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if sorte != "os":
		s.material = m
		mi.mesh = s
	n.add_child(mi)
	var fx: Node = main.get("combat_fx_v129")
	if sorte not in ["fruit", "os"]:
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.5, 0.15)
		l.light_energy = 1.2
		l.omni_range = 3.0
		n.add_child(l)
		if fx != null and fx.has_method("_burst"):
			fx._burst(Vector3.ZERO, {"amount": 16, "life": 0.4, "v0": 0.0, "v1": 0.3, "radius": 0.05, "grav": Vector3(0, 1.0, 0), "size": 0.12,
				"explo": 0.0, "loop": true, "parent": n, "cols": [Color(1, 0.9, 0.5), Color(1.0, 0.45, 0.1), Color(0.6, 0.15, 0.05, 0.0)]})
	var t: float = clampf(from.distance_to(to) / 10.0, 0.5, 1.2)
	var v: Vector3 = (to - from) / t
	v.y += 0.5 * 9.8 * t
	if sorte == "os":
		# lâché, il tombe : presque pas de vitesse au départ
		var tf: float = sqrt(2.0 * maxf(from.y - to.y, 1.0) / 9.8)
		v = Vector3(to.x - from.x, 0.0, to.z - from.z) / tf
	_spits.append({"n": n, "v": v, "life": 6.0 if sorte == "os" else 2.5, "dmg": dmg, "from": from, "sorte": sorte, "spin": Vector3(randf_range(-9, 9), randf_range(-9, 9), 0)})
	if sorte not in ["fruit", "os"]:
		main.sfx("flamme_lance", from)


func _tick_spits(delta: float) -> void:
	if _spits.is_empty():
		return
	var p: Vector3 = main._player_pos_v27() + Vector3.UP * 1.0
	for s in _spits.duplicate():
		var n: Node3D = s["n"]
		if not is_instance_valid(n):
			_spits.erase(s)
			continue
		s["v"] = (s["v"] as Vector3) + Vector3.DOWN * 9.8 * delta
		n.global_position += (s["v"] as Vector3) * delta
		n.rotation += (s.get("spin", Vector3.ZERO) as Vector3) * delta
		s["life"] = float(s["life"]) - delta
		var done: bool = false
		if n.global_position.distance_to(p) < 0.8:
			hurt_player(int(s["dmg"]), s["from"])
			done = true
		elif n.global_position.y < hauteur(n.global_position.x, n.global_position.z) or float(s["life"]) <= 0.0:
			done = true
		if done:
			var fx: Node = main.get("combat_fx_v129")
			if str(s.get("sorte", "braise")) == "os":
				# l'os éclate sur le rocher
				os_tombes += 1
				if fx != null and fx.has_method("_puffs"):
					fx._puffs(n.global_position, 10, Color(0.92, 0.88, 0.78, 0.9), 0.04, 0.12, 0.6, 1.5, 4.0, 0.4, 0.2)
				main.sfx("os_choc", n.global_position)
			elif str(s.get("sorte", "braise")) == "fruit":
				# la mangue s'écrase : du jus et de la pulpe
				if fx != null and fx.has_method("_puffs"):
					fx._puffs(n.global_position, 8, Color(1.0, 0.68, 0.12, 0.9), 0.04, 0.12, 0.5, 1.5, 3.5, 0.4, 0.2)
				main.sfx("splotch", n.global_position)
			else:
				if fx != null and fx.has_method("_burst"):
					fx._burst(n.global_position, {"amount": 12, "life": 0.6, "v0": 1.0, "v1": 3.0, "dir": Vector3.UP, "spread": 70.0, "grav": Vector3(0, -6.0, 0),
						"size": 0.1, "mesh": "streak", "cols": [Color(1, 0.9, 0.5), Color(1.0, 0.45, 0.1), Color(1.0, 0.3, 0.05, 0.0)]})
				main.sfx("flamme_impact", n.global_position)
			n.queue_free()
			_spits.erase(s)


# =================================================================== les mouettes chapardeuses

func _gulls(p: Vector3) -> void:
	_swoop_t -= 2.0
	if _swoop_t > 0.0:
		return
	_swoop_t = _rng.randf_range(50.0, 100.0)
	# près du rivage seulement, et pas pendant une conversation
	if float(main._height_at(p.x, p.z)) > 4.0:
		return
	for b in betes:
		if is_instance_valid(b) and str(b.kind) == "mouette" and b.state == "vol" and (b as Node3D).global_position.distance_to(p) < 45.0:
			b.state = "pique"
			b.timer = 4.0
			b._sound("menace")
			return


func _food() -> String:
	var inv: Node = main.inventory_v28
	var opts: Array = []
	for id in inv.ITEMS:
		if str(inv.ITEMS[id].get("kind", "")) == "nourriture" and inv.count(id) > 0:
			opts.append(id)
	return str(opts[_rng.randi() % opts.size()]) if not opts.is_empty() else ""


func _art(id: String) -> String:
	var it: Dictionary = main.inventory_v28.ITEMS.get(id, {})
	return str(it.get("art", it.get("name", id)))


## La mouette passe en rase-mottes : elle chipe à manger (une fois de temps en temps).
func mouette_vole(g: Node3D) -> void:
	var id: String = _food() if _steal_cd <= 0.0 else ""
	main.sfx("mouette_cri", g.global_position)
	if id == "":
		if main.combat_v28 != null:
			main.combat_v28.float_text(g.global_position + Vector3.UP * 0.5, "Kiaaa !", Color(1, 1, 1))
		g.state = "fuite_air"
		g.timer = 2.0
		return
	main.inventory_v28.remove(id, 1)
	g.butin = id
	vols += 1
	_steal_cd = 180.0
	var mdl: Node3D = main.inventory_v28.make_model(id)
	if mdl != null:
		mdl.name = "Butin"
		mdl.scale = Vector3.ONE * 0.35
		var body: Node3D = g._pivots.get("corps")
		if body != null:
			body.add_child(mdl)
			mdl.position = Vector3(0, 0.02, 0.42)
	main._show_message_v28("Une mouette t'a chipé %s ! Frappe-la vite pour qu'elle le lâche." % _art(id))


func _drop_model(g: Node3D) -> void:
	for piv in ["corps", "tete"]:
		var body: Node3D = g._pivots.get(piv)
		if body != null:
			var m: Node = body.get_node_or_null("Butin")
			if m != null:
				m.queue_free()


# =================================================================== V135 : les coatis chapardeurs

func peut_chaparder() -> bool:
	return _chap_cd <= 0.0 and _food() != ""


## Le coati arrive au pied du héros : il chipe à manger (une fois de temps en temps), le garde
## dans la gueule et file. Renvoie vrai s'il a pris quelque chose.
func chapardeur_vole(g: Node3D) -> bool:
	var id: String = _food() if _chap_cd <= 0.0 else ""
	var renard: bool = str(g.get("kind")) == "renard_roux"
	main.sfx("renard_glapit" if renard else "coati_couine", g.global_position)
	if id == "":
		return false
	main.inventory_v28.remove(id, 1)
	g.butin = id
	vols += 1
	_chap_cd = 120.0
	var mdl: Node3D = main.inventory_v28.make_model(id)
	if mdl != null:
		mdl.name = "Butin"
		mdl.scale = Vector3.ONE * 0.3
		var head: Node3D = g._pivots.get("tete")
		if head != null:
			head.add_child(mdl)
			mdl.position = Vector3(0, -0.04, 0.32)
	if renard:
		main._show_message_v28("Un renard t'a chipé %s ! Frappe-le vite pour qu'il le lâche." % _art(id))
	else:
		main._show_message_v28("Un coati t'a chipé %s ! Frappe-le vite pour qu'il le lâche." % _art(id))
	return true


func chapardeur_lache(g: Node3D) -> void:
	var id: String = str(g.butin)
	g.butin = ""
	_drop_model(g)
	if id == "":
		return
	main.inventory_v28.add(id, 1)
	rendus += 1
	main._show_message_v28(("Le renard lâche %s !" if str(g.get("kind")) == "renard_roux" else "Le coati lâche %s !") % _art(id))
	main.sfx("ramasse_pieces", g.global_position)


func chapardeur_garde(g: Node3D) -> void:
	var id: String = str(g.butin)
	g.butin = ""
	_drop_model(g)
	if id != "":
		main._show_message_v28(("Trop tard : le renard a filé avec %s." if str(g.get("kind")) == "renard_roux" else "Trop tard : le coati a filé avec %s.") % _art(id))


func mouette_lache(g: Node3D) -> void:
	var id: String = str(g.butin)
	g.butin = ""
	_drop_model(g)
	if id == "":
		return
	main.inventory_v28.add(id, 1)
	rendus += 1
	main._show_message_v28("La mouette lâche %s !" % _art(id))
	main.sfx("ramasse_pieces", g.global_position)


func mouette_garde(g: Node3D) -> void:
	var id: String = str(g.butin)
	g.butin = ""
	_drop_model(g)
	if id != "":
		main._show_message_v28("Trop tard : la mouette s'est envolée avec %s." % _art(id))


# =================================================================== V133 : les taches au sol

## Une tache posée à plat sur le sol : "encre" (noire, luisante), "sauce" (rouge), "gomme"
## (le papier effacé, tout blanc). Elle s'efface au bout de `life` secondes.
func decal(at: Vector3, sorte: String, size: float, life: float) -> void:
	if main == null or not is_inside_tree():
		return
	var col: Color = {"encre": Color(0.01, 0.01, 0.012, 0.95), "sauce": Color(0.48, 0.04, 0.015, 0.95), "gomme": Color(0.99, 0.99, 0.98, 0.9)}.get(sorte, Color(0, 0, 0, 0.8))
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	q.orientation = PlaneMesh.FACE_Y
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_texture = _splat_tex(sorte)
	m.albedo_color = col
	m.roughness = 0.2 if sorte == "encre" else (0.3 if sorte == "sauce" else 0.95)
	if sorte == "encre":
		m.metallic_specular = 0.5
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	q.material = m
	mi.mesh = q
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	# posée selon la pente du terrain
	var h0: float = hauteur(at.x, at.z)
	var hx: float = hauteur(at.x + 0.5, at.z) - hauteur(at.x - 0.5, at.z)
	var hz: float = hauteur(at.x, at.z + 0.5) - hauteur(at.x, at.z - 0.5)
	var n := Vector3(-hx, 1.0, -hz).normalized()
	var x_axis: Vector3 = n.cross(Vector3.FORWARD).normalized() if absf(n.dot(Vector3.FORWARD)) < 0.95 else Vector3.RIGHT
	var b := Basis(x_axis, n, x_axis.cross(n).normalized())
	mi.global_transform = Transform3D(b.rotated(n, _rng.randf() * TAU), Vector3(at.x, h0 + 0.03, at.z))
	_decals.append({"n": mi, "m": m, "life": life, "t": 0.0, "a": col.a, "s": sorte})
	taches[sorte] = int(taches.get(sorte, 0)) + 1
	while _decals.size() > 14:
		var old: Dictionary = _decals.pop_front()
		if is_instance_valid(old["n"]):
			(old["n"] as Node).queue_free()


func _tick_decals(delta: float) -> void:
	for d in _decals.duplicate():
		if not is_instance_valid(d["n"]):
			_decals.erase(d)
			continue
		d["t"] = float(d["t"]) + delta
		var life: float = float(d["life"])
		var m: StandardMaterial3D = d["m"]
		m.albedo_color.a = float(d["a"]) * (1.0 - smoothstep(life * 0.65, life, float(d["t"])))
		if float(d["t"]) >= life:
			(d["n"] as Node).queue_free()
			_decals.erase(d)


## Une éclaboussure dessinée une fois pour toutes : un rond aux bords dentelés et des gouttes
## (l'encre, la sauce), ou une plage effacée aux bords doux, striée de coups de gomme.
func _splat_tex(sorte: String) -> Texture2D:
	if _decal_tex.has(sorte):
		return _decal_tex[sorte]
	var N: int = 96
	var img := Image.create(N, N, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = {"encre": 71, "sauce": 72, "gomme": 73}.get(sorte, 70)
	var lobes: Array = []
	for i in range(5):
		lobes.append([rng.randf_range(3.0, 11.0), rng.randf_range(0.0, TAU), rng.randf_range(0.03, 0.08)])
	var drops: Array = []
	for i in range(10):
		var a: float = rng.randf() * TAU
		drops.append([Vector2(cos(a), sin(a)) * rng.randf_range(0.36, 0.47), rng.randf_range(0.015, 0.04)])
	for y in range(N):
		for x in range(N):
			var p := Vector2((x + 0.5) / N - 0.5, (y + 0.5) / N - 0.5)
			var r: float = p.length()
			var a2: float = atan2(p.y, p.x)
			var alpha: float = 0.0
			if sorte == "gomme":
				var edge: float = 0.36 + 0.03 * sin(a2 * 3.0 + 1.0)
				alpha = 1.0 - smoothstep(edge - 0.12, edge, r)
				alpha *= 0.8 + 0.2 * sin(p.x * 70.0 + p.y * 20.0)
			else:
				var edge2: float = 0.27
				for l in lobes:
					edge2 += float(l[2]) * sin(a2 * float(l[0]) + float(l[1]))
				alpha = 1.0 - smoothstep(edge2 - 0.015, edge2, r)
				for d in drops:
					alpha = maxf(alpha, 1.0 - smoothstep(float(d[1]) - 0.008, float(d[1]), p.distance_to(d[0])))
			img.set_pixel(x, y, Color(1, 1, 1, clampf(alpha, 0.0, 1.0)))
	var t := ImageTexture.create_from_image(img)
	_decal_tex[sorte] = t
	return t
