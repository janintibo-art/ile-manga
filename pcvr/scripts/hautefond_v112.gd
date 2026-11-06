extends Node3D
## V112 : l'Île de Hautefond, la cité-colonne — le chef d'orchestre. Il construit l'île
## (ile_hautefond_v112), la ville en terrasses autour de la Grande Colonne (hautefond_ville_v112, ses
## grands lieux hautefond_lieux_v112, la Colonne et son ascenseur hautefond_colonne_v112), ce qu'il y a
## dehors (hautefond_dehors_v112 : le port, le phare, le moulin, les vergers, la plage, les falaises,
## les arches, la cascade) et la végétation (hautefond_flore_v112) ; il tient les feux, les fumées,
## les panaches de vapeur, la lueur des fenêtres et des globes à la nuit, les ailes du moulin, les
## engrenages qui tournent, l'Albatros qui se balance à son mât, le marteau-pilon de la forge, les
## dirigeables qui croisent au-dessus de la ville ; il fait vivre les habitants selon l'heure (et les
## fait monter au Belvédère par la cabine) et les passants.
## La suite (les versions d'après) : la Cité des Nuées (l'île flottante), les Strates et le quartier
## de la Fronde (sous la ville), le Dôme d'Azur (au fond de la mer).

const IleScript = preload("res://scripts/ile_hautefond_v112.gd")
const CityScript = preload("res://scripts/hautefond_ville_v112.gd")
const DehorsScript = preload("res://scripts/hautefond_dehors_v112.gd")
const Mats = preload("res://scripts/hautefond_mats_v112.gd")
const Mats71 = preload("res://scripts/montjoie_mats_v71.gd")
const FLORE := "res://scripts/hautefond_flore_v112.gd"
const HABITANTS := "res://scripts/pnj/hautefond_habitants_v112.gd"
const PNJ := "res://scripts/pnj/pnj_montjoie_v71.gd"
const Gens = preload("res://scripts/pnj/maisons_habitants_v81.gd")
const Figurant = preload("res://scripts/pnj/figurant_v81.gd")

## Les passants : [style, rôle, phrases] (leurs lieux : les bancs des promenades, des coins de rue)
const PASSANTS := [
	["montjoie", "homme", ["Trois quarts d'heure de queue pour la cabine. Et elle ne monte qu'au Belvédère ! Bon, la vue vaut le coup.", "Par la Colonne, j'ai oublié mon parapluie au cinquième. Il n'y a pas de cinquième. Je ne comprends rien."]],
	["montjoie", "femme", ["Le chocolat de Firmin a sifflé : il est seize heures. Pas besoin de montre, ici.", "Le marché est plein, aujourd'hui. Rosalie a dû annoncer un nouveau potin."]],
	["montjoie", "vieux", ["De mon temps, on montait à la Colonne par l'escalier. Mille marches. Et on disait merci.", "Huile tes rouages, jeune homme. Et tes genoux aussi, tant que tu y es."]],
	["montjoie", "vieille", ["J'ai connu la Colonne quand la cabine était en bois. Elle grinçait comme mon mari. Je les regrette tous les deux.", "Regarde l'Albatros, là-haut ! Cette Héloïse, elle va finir par décrocher la lune."]],
	["montjoie", "enfant", ["Tu as vu les engrenages de l'horloger ? Il y en a un qui tourne à l'envers, exprès !", "Quand je serai grand, je serai liftier. Ou dirigeable. Je n'ai pas encore choisi."]],
	["montjoie", "homme", ["Il paraît que la ligne des Nuées rouvre bientôt. Mon beau-frère dit ça depuis trois ans.", "Attention, ça souffle ! Le tuyau de la Forge vient de lâcher sa vapeur."]],
	["montjoie", "femme", ["Au Belvédère, on voit l'île flottante juste au-dessus. Si près ! On a envie de tendre la main.", "Mon chapeau s'est envolé au Belvédère. Il doit être à la Cité des Nuées, maintenant. Veinard."]],
	["montjoie", "enfant", ["J'ai fait un vœu dans la fontaine de Dame Ysolde. Je ne te dis pas lequel. Ça a un rapport avec des boulons.", "Barnabé a fermé les yeux pendant toute la montée ! Moi, je les avais grands ouverts !"]],
	["montjoie", "vieux", ["Le vent tourne à l'ouest : le moulin d'Augustin va se mettre à chanter.", "Tu entends cette musique qui monte de la cage du bas ? Hm. De mon temps, les travaux faisaient moins de bruit."]],
	["montjoie", "vieille", ["J'ai acheté des dattes chez Rosalie, et elle m'a raconté la vie de tout le quartier. Gratuitement.", "Le Bourgmestre fait un discours sur la Place. Vite, prenons la rue de derrière."]],
	["montjoie", "homme", ["Là-haut, au-dessus des nuages, il fait toujours beau, paraît-il. Ici, il fait beau aussi. Mais en dessous.", "Ma montre avance de trois secondes. Si Gaspard le sait, je suis perdu."]],
	["montjoie", "femme", ["Un dirigeable, un bateau, une cabine… À Hautefond, on ne marche jamais. Enfin, si : on fait la queue.", "Ces bijoux de boulons, au marché, j'en voulais un. Mais ma voisine me regarde. Je reviendrai demain."]],
	["montjoie", "enfant", ["Il y a une baleine qui passe au-dessus du Dôme d'Azur, au fond de la mer ! Mon oncle l'a vue !", "Tout le monde descend ! … Non, je rigole. C'est ce que dit Barnabé quand il a peur."]],
	["montjoie", "homme", ["J'ai monté trois fois au Belvédère, aujourd'hui. Je n'ai rien vu : il y avait un nuage. Le même, trois fois.", "Le pavé est glissant près du lavoir. La vapeur, toujours la vapeur."]],
	["montjoie", "vieille", ["Ici, il y a plus d'horloges que d'habitants. Et elles ne sont jamais d'accord, sauf chez Gaspard.", "Une limonade à la vapeur, chez Firmin. Ça pique le nez, ça réchauffe le cœur."]],
	["montjoie", "femme", ["Il fait frais, sur la Haute-Ville. Le vent monte de la mer et redescend par les escaliers.", "Je travaille au lavoir. Avec toute cette vapeur, le linge sèche avant d'être lavé."]],
	["montjoie", "vieux", ["J'ai été liftier pendant trente ans. Je n'ai jamais eu le vertige. Seulement le mal de mer. Dans une tour.", "Ça monte, ça descend… Moi, je reste assis. C'est ma façon de voyager."]],
	["montjoie", "enfant", ["Maman dit que si je suis sage, on ira voir les poissons qui brillent au Dôme d'Azur. Quand la ligne rouvrira.", "J'ai trouvé un engrenage par terre ! Je vais l'échanger à Pimprenelle contre deux boulons."]],
	["montjoie", "homme", ["Je suis venu par le bateau de ligne pour voir la Colonne. Elle est plus haute que sur les cartes postales.", "Les cabines sont dorées, les rampes sont dorées… Même le guichet brille. Je n'ose pas toucher."]],
	["montjoie", "femme", ["Les pommes des Vergers sont arrivées au marché. Le Père Bastien leur a parlé toute la semaine : elles sont aux anges.", "Avec ce soleil, la Colonne brille tellement qu'il faut des lunettes pour la regarder."]],
	["montjoie", "vieux", ["Le soir, quand les réverbères s'allument, toute la ville ronronne. C'est la vapeur dans les tuyaux. Ou mon ventre.", "Par tous les pistons, ce que ça grimpe, ces rues ! Hautefond, c'est une ville pour les mollets."]],
	["montjoie", "vieille", ["On dit qu'il y a de la musique dans les Strates, sous nos pieds. Moi, j'entends surtout mes genoux.", "Dame Ysolde a construit la première cabine avec un panier à salade. Moi, j'ai encore le même panier à salade. Il n'a jamais monté nulle part."]],
	["montjoie", "homme", ["L'Albatros est amarré au Mât. Quand le vent tourne, il se balance comme un gros poisson rouge.", "Il paraît qu'au Phare de la Pointe, chaque mouette a un prénom. Celle qui m'a volé ma tartine s'appelle Firmin."]],
	["montjoie", "femme", ["J'ai pris le thé fumé au Piston Joyeux. La machine a sifflé, j'en ai renversé la moitié. Ça fait partie du charme.", "Cette nuit, il y avait une étoile qui clignait au-dessus du Phare. Le Professeur Lunette était tout excité."]],
]

var main: Node
var ile: Node3D
var city: Node3D                         # Hautefond (hautefond_ville_v112)
var dehors: Node3D
var flore: Node3D
var pc: bool = true
var habitants: Array = []
var by_id: Dictionary = {}
var state := {}
var crowd: Array = []                    # [figurant, heure de début, heure de fin, position]
var ships: Array = []                    # [Node3D, centre, rayon, hauteur, vitesse, phase] : les dirigeables qui croisent
var _claims: Dictionary = {}
var _clock: float = 0.0
var _rng := RandomNumberGenerator.new()
var _fires: Array = []
var _smoke: Array = []
var _steam: Array = []
var _sails: Array = []
var _night: float = 0.0
var _night_t: float = 0.0
var _crowd_t: float = 0.0
var _crowd_spawned: bool = false
var _interactions: Array = []
var _hammer_t: float = 0.0


func setup(main_node: Node) -> void:
	main = main_node
	pc = OS.has_feature("ile_manga_pc")
	_rng.seed = 11290
	state = _fresh_state()


func _fresh_state() -> Dictionary:
	return {"visite": false, "visites": {}, "montees": 0}


# =================================================================== construction

func build_island() -> void:
	ile = IleScript.new()
	ile.name = "Ile_hautefond_v112"
	add_child(ile)
	ile.build(pc)


## Après le relief et l'heure du jour : la ville, le dehors, la végétation, les feux, les fumées, la
## vapeur, les dirigeables.
func build_town() -> void:
	var t0: int = Time.get_ticks_msec()
	city = CityScript.new()
	city.name = "Hautefond_v112"
	add_child(city)
	city.build(main, ile, pc)
	dehors = DehorsScript.new()
	dehors.name = "Hautefond_dehors_v112"
	add_child(dehors)
	dehors.build(self)
	if ResourceLoader.exists(FLORE):
		flore = load(FLORE).new()
		flore.name = "Flore_hautefond_v112"
		add_child(flore)
		for a in city.flora_avoid:
			flore.avoid.append(a)
		for a2 in dehors.flora_avoid:
			flore.avoid.append(a2)
		flore.build_hautefond(ile, pc, {"arbres": city.tree_spots, "vergers": dehors.orchard_spots})
	for f in city.fire_spots:
		_fires.append(_make_fire(f[0], float(f[1])))
	for f2 in dehors.fire_spots:
		_fires.append(_make_fire(f2[0], float(f2[1])))
	var n_smoke: int = 0
	for sp in city.smoke_spots:
		if n_smoke < (40 if pc else 16):
			_smoke.append(_make_smoke(sp, Color(0.55, 0.54, 0.53, 0.22)))
			n_smoke += 1
	var n_steam: int = 0
	for sp2 in city.steam_spots + dehors.kit.steam_spots:
		if n_steam < (30 if pc else 12):
			_steam.append(_make_smoke(sp2, Color(0.95, 0.95, 0.97, 0.3), 0.7))
			n_steam += 1
	for k in [city.kit, dehors.kit]:
		for s in k.sails:
			_sails.append(s)
	_ships()
	_glows()
	print("ILE_MANGA_V112: l'Île de Hautefond est prête (%d ms)" % (Time.get_ticks_msec() - t0))


## Deux dirigeables qui tournent lentement au-dessus de la ville (pas de collision).
func _ships() -> void:
	var c: Vector3 = IleScript.W(0.0, 0.0)
	for e in [[150.0, 92.0, 0.018, 0.0, "tissu112_creme", 26.0], [230.0, 128.0, -0.012, 2.4, "tissu112_rouge", 20.0]]:
		var n := Node3D.new()
		n.name = "Dirigeable"
		add_child(n)
		var k = load("res://scripts/hautefond_kit_v112.gd").new()
		k.setup(n, null)
		k.airship112(Transform3D.IDENTITY, float(e[5]), str(e[4]))
		k.commit()
		for ch in n.get_children():
			if ch is GeometryInstance3D:
				(ch as GeometryInstance3D).visibility_range_end = 2200.0
		ships.append([n, c, float(e[0]), float(e[1]), float(e[2]), float(e[3])])
	_ships_tick(0.0)


func _ships_tick(_delta: float) -> void:
	for s in ships:
		var n: Node3D = s[0]
		var a: float = _clock * float(s[4]) + float(s[5])
		var c: Vector3 = s[1]
		var r: float = float(s[2])
		var p := Vector3(c.x + cos(a) * r, float(s[3]) + sin(_clock * 0.2 + float(s[5])) * 2.0, c.z + sin(a) * r)
		var tang := Vector3(-sin(a), 0, cos(a)) * signf(float(s[4]))
		n.global_position = p
		n.global_basis = Basis.looking_at(tang, Vector3.UP) * Basis(Vector3.UP, PI * 0.5) * Basis(Vector3.BACK, sin(_clock * 0.3 + float(s[5])) * 0.03)


## La nuit : les fenêtres, les globes, les cadrans, le phare s'allument.
func _glows() -> void:
	var t: Node = main.get("temps_v56") if main != null else null
	if t == null or not t.has_method("register_glow"):
		Mats.night(0.0)
		return
	t.register_glow(Mats71.make("vitre71_on"), 2.4, 0.12)
	t.register_glow(Mats.make("lampe112"), 4.0, 0.6)
	t.register_glow(Mats.make("cadran112"), 1.2, 0.05)
	t.register_glow(Mats.make("phare112"), 8.0, 1.0)
	if flore != null and flore.get("glow_mats") != null:
		for g in flore.glow_mats:
			t.register_glow(g[0], float(g[1]), float(g[2]))


func _register_interactions() -> void:
	var d: Node = main.get("donjon_v35")
	if d == null:
		return
	if city != null and city.colonne != null:
		city.colonne.register(d, self)
	var col: Node3D = city.colonne
	var me = self
	# les deux lignes encore fermées : un panneau à chaque portail (est et ouest)
	_ia(d, {"id": "hf_ligne_nuees", "pos": col.foot + Vector3(col.R_SOCLE + 3.2, 1.0, 0.0), "radius": 2.6, "text": "E : lire le panneau (Ligne des Nuées)",
		"vr": "Gâchette : lire le panneau (Ligne des Nuées)", "call": func(): me.say("« LIGNE DES NUÉES — en révision. La cabine de la Cité des Nuées rouvrira très bientôt. La Confrérie des Liftiers vous remercie de votre patience (et de votre absence de vertige). »", 8.0), "when": func(): return true})
	_ia(d, {"id": "hf_ligne_strates", "pos": col.foot + Vector3(-col.R_SOCLE - 3.2, 1.0, 0.0), "radius": 2.6, "text": "E : lire le panneau (Ligne des Strates)",
		"vr": "Gâchette : lire le panneau (Ligne des Strates)", "call": func(): me.say("« LIGNE DES STRATES ET DU DÔME D'AZUR — fermée pour travaux. » En dessous, quelqu'un a griffonné : « Les travaux, c'est nous qui les faisons. Bisous d'en bas. »", 8.0), "when": func(): return true})


func _ia(d: Node, it: Dictionary) -> void:
	d._interactions.append(it)
	_interactions.append(it)


func say(text: String, seconds: float = 6.0) -> void:
	if main != null and main.get("donjon_v35") != null:
		main.donjon_v35._say(text, seconds)
	elif main != null:
		main._show_message_v28(text)


func sfx(name: String, at: Vector3) -> void:
	if main != null and main.has_method("sfx"):
		main.sfx(name, at)


# =================================================================== les repères des autres

func dock() -> Array:
	return [IleScript.W(IleScript.DOCK_A.x, IleScript.DOCK_A.y), IleScript.W(IleScript.DOCK_B.x, IleScript.DOCK_B.y)]


func contains(p: Vector3) -> bool:
	return ile != null and ile.contains(p.x, p.z) and p.y > -45.0


func on_structure(p: Vector3) -> bool:
	return city != null and city.on_structure(p)


## À pied : on peut marcher ici (la terre ferme, les quais, la Colonne, le Belvédère) ?
func walkable(p: Vector3) -> bool:
	if not contains(p):
		return false
	if on_structure(p):
		return true
	return ile.height(p.x, p.z) > -0.3 or p.y > 1.0


func blocks_boat(_p: Vector3) -> bool:
	return false


## La zone du joueur (pour la musique, les ambiances, le carnet).
func zone_at(p: Vector3) -> String:
	if ile == null or not ile.contains(p.x, p.z) or p.y < -20.0:
		return ""
	var cz: String = city.zone_at(p) if city != null else ""
	if cz != "":
		return cz
	var l: Vector2 = IleScript.L(p.x, p.z)
	var h: float = ile.height(p.x, p.z)
	if l.distance_to(IleScript.HARBOR) < IleScript.HARBOR_R + 40.0:
		return "hf_port"
	if l.distance_to(IleScript.PHARE) < 26.0:
		return "hf_phare"
	if h < -0.42 and p.y < 2.0 and not on_structure(p):
		return "" if IleScript.coast_q(l.x, l.y) > 1.12 else "hf_rivage"
	if l.distance_to(IleScript.MILL) < IleScript.HILL_R:
		return "hf_moulin"
	var tp: Vector2 = IleScript.town_polar(l.x, l.y)
	if IleScript.in_arc(tp.x, IleScript.ORCH_A.x, IleScript.ORCH_A.y) and tp.y > IleScript.ORCH_R0 - 6.0 and IleScript.coast_q(l.x, l.y) < 0.95:
		return "hf_vergers"
	if IleScript.cliff_k(tp.x) > 0.5 and IleScript.coast_q(l.x, l.y) > 0.86:
		return "hf_falaises"
	if IleScript.coast_q(l.x, l.y) > 0.9:
		return "hf_plage" if absf(IleScript._adiff(tp.x, 20.0)) < 30.0 else "hf_rivage"
	return "hf_campagne"


func people_at(p: Vector3) -> String:
	var z: String = zone_at(p)
	if z == "":
		return ""
	if z in ["hf_rivage", "hf_campagne", "hf_falaises", "hf_vergers", "hf_moulin", "hf_plage", "hf_phare"]:
		return "sauvage"
	return "ville"


func village_point(id: String) -> Array:
	match id:
		"hautefond":
			return respawn_point()
		"hautefond_port":
			var q: Vector3 = city.points.get("port_q3", dock()[0])
			return [q + Vector3.UP * 0.3, Vector3(0, 0, 1)]
	return []


const PLACES := {"hf_colonne": "la Place de la Colonne", "hf_belvedere": "le Belvédère de la Grande Colonne", "hf_cabine": "la cabine de la Grande Colonne",
	"hf_haute": "Hautefond, la Haute-Ville", "hf_observatoire": "l'Observatoire", "hf_mairie": "l'Hôtel de Ville", "hf_bibliotheque": "la Bibliothèque des Cartes",
	"hf_moyenne": "Hautefond, la Ville-Moyenne", "hf_marche": "le Grand Marché", "hf_taverne": "la taverne « Le Piston Joyeux »", "hf_mat": "le Mât des dirigeables",
	"hf_basse": "Hautefond, la Basse-Ville", "hf_forge": "la Forge à vapeur", "hf_port": "le Port des Cordages", "hf_phare": "le Phare de la Pointe",
	"hf_moulin": "le Moulin des Quatre Vents", "hf_vergers": "les Vergers en terrasses", "hf_falaises": "les Falaises", "hf_plage": "la Plage des Galets Blonds",
	"hf_rivage": "le rivage", "hf_campagne": "la campagne"}


func place_name(p: Vector3) -> String:
	return "Île de Hautefond, " + str(PLACES.get(zone_at(p), "l'île"))


func respawn_point() -> Array:
	var sp: Dictionary = spot("place_fontaine")
	if sp.is_empty():
		return [city.points.values()[0] + Vector3.UP * 0.3, Vector3(0, 0, 1)]
	return [(sp["pos"] as Vector3) + Vector3.UP * 0.3, sp["face"]]


func hostile_zone(_p: Vector3) -> bool:
	return false


func hour() -> float:
	return float(main.temps_v56.hour) if main != null and main.get("temps_v56") != null and main.temps_v56 != null else 12.0


# =================================================================== les habitants

func spot(name: String) -> Dictionary:
	if city != null and (city.spots as Dictionary).has(name):
		return city.spots[name]
	return {}


func spot_free(name: String, who: Node) -> bool:
	var c: Variant = _claims.get(name, null)
	return c == null or c == who or not is_instance_valid(c)


func claim_spot(name: String, who: Node) -> void:
	_claims[name] = who


func release_spot(name: String, who: Node) -> void:
	if _claims.get(name, null) == who:
		_claims.erase(name)


func spawn_npcs() -> void:
	if not habitants.is_empty() or city == null or not ResourceLoader.exists(HABITANTS) or not ResourceLoader.exists(PNJ):
		return
	var H = load(HABITANTS)
	var P = load(PNJ)
	for data in H.all_profiles():
		var home: String = str(data.get("maison", ""))
		var start: String = home if city.points.has(home) else str(city.points.keys()[0])
		var npc: Node3D = P.new()
		main.add_child(npc)
		npc.setup(main, data, city.points, city.graph, start)
		npc.setup_azur(self, data)
		var saved: Variant = main.pending_pnj_v31.get(str(data["id"]), {})
		if saved is Dictionary and not (saved as Dictionary).is_empty():
			npc.load_data(saved)
		main.npcs_v31.append(npc)
		habitants.append(npc)
		by_id[str(data["id"])] = npc
	print("ILE_MANGA_V112: %d habitants à Hautefond" % habitants.size())


## Les habitants prennent la cabine : quand l'un d'eux arrive au pied (ou en haut) de la cage et
## repart vers l'autre bout, il est monté (ou descendu) avec elle.
func _npc_lift() -> void:
	if city == null or not city.points.has("cab_haut"):
		return
	var top_y: float = (city.points["cab_haut"] as Vector3).y
	var low_y: float = (city.points["cab_bas"] as Vector3).y
	for npc in habitants:
		if not is_instance_valid(npc):
			continue
		var ap: String = str(npc.get("at_point"))
		var y: float = (npc as Node3D).global_position.y
		if ap == "cab_haut" and y < top_y - 5.0:
			(npc as Node3D).global_position.y += top_y - low_y
		elif ap == "cab_bas" and y > low_y + 5.0:
			(npc as Node3D).global_position.y -= top_y - low_y


## Les services (les comptoirs, les lieux pour le carnet et les quêtes à venir).
func register_services(journal: Node) -> void:
	for k in city.objets:
		journal.lieux["hf_" + str(k)] = city.objets[k]
	if dehors != null:
		for k2 in dehors.objets:
			journal.lieux["hf_" + str(k2)] = dehors.objets[k2]
	journal.lieux["hautefond"] = respawn_point()[0]
	journal.lieux["hf_colonne"] = city.colonne.foot
	journal.lieux["hf_belvedere"] = city.colonne.top
	_register_interactions()


func after_reply(_r: Dictionary, _npc: Node) -> void:
	pass


# =================================================================== les passants

func _spawn_crowd() -> void:
	_crowd_spawned = true
	var names: Array = []
	for s in city.crowd_spots:
		names.append(str(s))
	var rng := RandomNumberGenerator.new()
	rng.seed = 112000
	names.shuffle()
	var n: int = mini(PASSANTS.size() if pc else 10, names.size())
	for i in range(n):
		var e: Array = PASSANTS[i]
		var sname: String = str(names[i])
		var sp: Dictionary = city.spots.get(sname, {})
		if sp.is_empty():
			continue
		var prof: Dictionary = Gens.pick(str(e[0]), str(e[1]), rng)
		if prof.is_empty():
			continue
		prof["nom"] = Gens.prenom(str(e[0]), str(e[1]), rng)
		var f: Node = Figurant.spawn(self, main, prof, sp["pos"], sp["face"], str(sp["pose"]))
		if f == null:
			continue
		f.set("lines", e[2])
		claim_spot(sname, f)
		var h0: float = [7.0, 8.0, 9.0, 10.0, 14.0, 16.0][i % 6]
		var h1: float = [18.0, 20.0, 21.0, 19.0, 22.0, 23.0][i % 6]
		crowd.append([f, h0, h1, sp["pos"]])
	_crowd_vis(true)


static func _in_hours(h: float, a: float, b: float) -> bool:
	return (a <= b and h >= a and h < b) or (a > b and (h >= a or h < b))


func _crowd_vis(force: bool = false) -> void:
	var p: Vector3 = main._player_pos_v27()
	var h: float = hour()
	for c in crowd:
		var f: Node = c[0]
		if not is_instance_valid(f):
			continue
		var npc: Node3D = f.get("npc")
		if npc == null:
			continue
		var want: bool = _in_hours(h, float(c[1]), float(c[2])) and (c[3] as Vector3).distance_to(p) < 240.0
		if want != npc.visible or force:
			npc.visible = want
			f.process_mode = Node.PROCESS_MODE_INHERIT if want else Node.PROCESS_MODE_DISABLED
			for k in npc.get_children():
				if k is PhysicsBody3D:
					for cs in k.get_children():
						if cs is CollisionShape3D:
							(cs as CollisionShape3D).disabled = not want


# =================================================================== la vie de l'île

func _process(delta: float) -> void:
	if main == null or ile == null:
		return
	_clock += delta
	for s in _sails:
		if is_instance_valid(s):
			(s as Node3D).rotate_object_local(Vector3.BACK, delta * 0.55)
	var p: Vector3 = main._player_pos_v27()
	var dist: float = Vector2(p.x - IleScript.CENTER.x, p.z - IleScript.CENTER.z).length()
	if dist > 1600.0:
		return
	_ships_tick(delta)
	_night_t -= delta
	if _night_t <= 0.0:
		_night_t = 1.0
		var h: float = hour()
		_night = 1.0 if (h >= 20.0 or h < 5.5) else (smoothstep(18.5, 20.0, h) if h > 12.0 else 1.0 - smoothstep(5.5, 7.0, h))
		if city != null and city.colonne != null:
			city.colonne.set_night(_night)
	if dehors != null:
		dehors.tick(delta, _clock, _night)
	if dist > 700.0:
		return
	if city != null and city.colonne != null:
		city.colonne.spin_gears(delta)
	_npc_lift()
	var lx = city.lieux if city != null else null
	if lx != null and lx.airship != null:
		lx.airship.transform = lx.airship_base * Transform3D(Basis(Vector3.UP, sin(_clock * 0.17) * 0.06) * Basis(Vector3.RIGHT, sin(_clock * 0.31) * 0.02), Vector3(0, sin(_clock * 0.4) * 0.25, 0))
	if lx != null and lx.steam_hammer != null:
		_hammer_t += delta
		var ph: float = fmod(_hammer_t, 2.4)
		var y: float = 1.2 if ph < 1.6 else lerpf(1.2, 0.0, smoothstep(1.6, 1.75, ph)) + lerpf(0.0, 1.2, smoothstep(1.9, 2.4, ph))
		(lx.steam_hammer as Node3D).global_position = lx.hammer_base + Vector3.UP * (y - 0.6)
		if ph - delta < 1.75 and ph >= 1.75 and p.distance_to(lx.hammer_base) < 30.0:
			sfx("enclume", lx.hammer_base)
	_crowd_t -= delta
	if _crowd_t <= 0.0:
		_crowd_t = 1.5
		if not _crowd_spawned:
			if dist < 420.0 and bool(main.get("game_started")):
				_spawn_crowd()
		else:
			_crowd_vis()
	if not ile.contains(p.x, p.z):
		return
	if not bool(state["visite"]) and (ile.height(p.x, p.z) > -0.2 or on_structure(p)) and bool(main.get("game_started")):
		state["visite"] = true
		main._show_message_v28("L'Île de Hautefond — la cité-colonne (ça monte !)")
		if main.has_method("jingle"):
			main.jingle("decouverte")
	if city == null:
		return
	var z: String = zone_at(p)
	var vis: Dictionary = state["visites"]
	if z == "hf_belvedere" and not bool(vis.get("belvedere", false)):
		vis["belvedere"] = true
		main._show_message_v28("Le Belvédère de la Grande Colonne : toute l'île à vos pieds")
	elif people_at(p) == "ville" and not bool(vis.get("ville", false)):
		vis["ville"] = true
		main._show_message_v28("Hautefond, la ville de pierre blonde, autour de sa Grande Colonne")
	for key in ["marche", "port", "phare", "moulin", "vergers", "falaises", "observatoire", "bibliotheque", "taverne", "mat"]:
		if z == "hf_" + key and not bool(vis.get(key, false)):
			vis[key] = true
	var mer: Node = main.get("mer_v55")
	if mer != null and mer.get("_underside") != null:
		(mer._underside as Node3D).global_position = Vector3(snappedf(p.x, 40.0), (mer._underside as Node3D).global_position.y, snappedf(p.z, 40.0))
	state["montees"] = int(city.colonne.rides)


func _make_smoke(at: Vector3, col: Color, scale_k: float = 1.0) -> CPUParticles3D:
	var s := CPUParticles3D.new()
	s.name = "Fumee"
	s.amount = 10
	s.lifetime = 5.0
	s.emitting = true
	s.direction = Vector3(0.2, 1, 0.1)
	s.spread = 12.0
	s.initial_velocity_min = 0.5
	s.initial_velocity_max = 0.9
	s.gravity = Vector3(0.25, 0.12, 0.05)
	s.scale_amount_min = 0.6 * scale_k
	s.scale_amount_max = 1.4 * scale_k
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.3))
	curve.add_point(Vector2(1.0, 1.6))
	s.scale_amount_curve = curve
	var qm := QuadMesh.new()
	qm.size = Vector2(0.9, 0.9)
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	if main != null and main.has_method("_soft_dot_v24"):
		m.albedo_texture = main._soft_dot_v24()
	qm.material = m
	s.mesh = qm
	s.visibility_aabb = AABB(Vector3(-3, -1, -3), Vector3(6, 12, 6))
	s.visibility_range_end = 160.0
	add_child(s)
	s.position = at
	return s


func _make_fire(at: Vector3, s: float) -> Node3D:
	var root := Node3D.new()
	root.name = "Feu"
	add_child(root)
	root.position = at
	var p := CPUParticles3D.new()
	p.amount = int(22 * s) + 8
	p.lifetime = 0.8
	p.direction = Vector3.UP
	p.spread = 15.0
	p.initial_velocity_min = 0.6 * s
	p.initial_velocity_max = 1.4 * s
	p.gravity = Vector3(0, 1.2, 0)
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.2 * s
	p.scale_amount_min = 0.5 * s
	p.scale_amount_max = 1.0 * s
	var grad := Gradient.new()
	grad.set_color(0, Color(1.0, 0.85, 0.4, 1.0))
	grad.set_color(1, Color(0.9, 0.2, 0.05, 0.0))
	p.color_ramp = grad
	var qm := QuadMesh.new()
	qm.size = Vector2(0.35, 0.45)
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	if main != null and main.has_method("_soft_dot_v24"):
		m.albedo_texture = main._soft_dot_v24()
	qm.material = m
	p.mesh = qm
	p.visibility_aabb = AABB(Vector3(-2, -1, -2), Vector3(4, 5, 4))
	root.add_child(p)
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.6, 0.25)
	l.light_energy = 1.5 * s
	l.omni_range = 6.0 * s + 2.0
	l.shadow_enabled = false
	l.position = Vector3.UP * 0.4
	l.distance_fade_enabled = true
	l.distance_fade_begin = 60.0
	l.distance_fade_length = 12.0
	root.add_child(l)
	return root


# =================================================================== s'évanouir, carnet, sauvegarde

func owns_point(p: Vector3) -> bool:
	return contains(p)


func on_faint(_p: Vector3) -> void:
	var at: Array = respawn_point()
	main.place_player_v35(at[0], at[1])
	main._show_message_v28("Vous vous êtes évanoui… Des passants vous ont porté jusqu'à la fontaine de Dame Ysolde, et Firmin vous a apporté un chocolat chaud. Ça remonte !")


func trouvailles() -> Dictionary:
	var vis: Dictionary = state["visites"]
	return {"hautefond": 1 if bool(state["visite"]) else 0, "hautefond_ville": 1 if bool(vis.get("ville", false)) else 0,
		"hautefond_belvedere": 1 if bool(vis.get("belvedere", false)) else 0, "hautefond_marche": 1 if bool(vis.get("marche", false)) else 0,
		"hautefond_port": 1 if bool(vis.get("port", false)) else 0, "hautefond_phare": 1 if bool(vis.get("phare", false)) else 0,
		"hautefond_moulin": 1 if bool(vis.get("moulin", false)) else 0, "hautefond_vergers": 1 if bool(vis.get("vergers", false)) else 0,
		"hautefond_falaises": 1 if bool(vis.get("falaises", false)) else 0, "hautefond_observatoire": 1 if bool(vis.get("observatoire", false)) else 0}


func serialize() -> Dictionary:
	return state.duplicate(true)


func load_data(d: Dictionary) -> void:
	state = _fresh_state()
	for k in state:
		if d.has(k):
			state[k] = d[k] if not (d[k] is Dictionary) else (d[k] as Dictionary).duplicate(true)
	_claims.clear()
