extends Node3D
## V68 : l'Île de la Balafre, l'île des pirates — le chef d'orchestre. Il construit l'île
## (ile_pirate_v68), le port de Port-Coutelas, ses tripots et ses navires (port_coutelas_v68),
## la jungle et le marais (pirate_flore_v68) ; il fait vivre les pirates et les gens du port
## (pnj_pirate_v68) selon l'heure ; il tient les bagarres (bagarre_v68) et les parties de dés ;
## il réveille les monstres de l'intérieur (repaires) quand on s'en approche ; il suit les quêtes
## (le perroquet de la capitaine, la dette de Jambe-de-Bois, le poing de fer, la fièvre des
## marais, le Roi de la Bagarre, la main de Crochet, la carte de Barbe-Sanglante et le trésor du
## Rocher du Crâne).

const IleScript = preload("res://scripts/ile_pirate_v68.gd")
const PortScript = preload("res://scripts/port_coutelas_v68.gd")
const FloreScript = preload("res://scripts/pirate_flore_v68.gd")
const Habitants = preload("res://scripts/pnj/pirates_habitants_v68.gd")
const PnjPir = preload("res://scripts/pnj/pnj_pirate_v68.gd")
const PirateBrain = preload("res://scripts/pnj/pnj_brain_pirate_v68.gd")
const BagarreScript = preload("res://scripts/bagarre_v68.gd")

const CHAMPIONS := ["gros_louis", "le_muet", "belle_humeur"]
## Les repaires : [id, centre local (x, z), rayon d'éveil, quand ("" toujours, "nuit"), réapparition (s),
## [[sorte, x, z], …]]. Les boss (Vieille-Dent, le Capitaine Sans-Chair) ont leurs propres règles.
const LAIRS := [
	["os", Vector2(-118.0, -136.0), 46.0, "", 480.0, [["crabe", -108.0, -128.0], ["crabe", -126.0, -127.0], ["crabe", -112.0, -146.0], ["crabe", -131.0, -142.0]]],
	["camp", Vector2(-40.0, -62.0), 40.0, "", 480.0, [["araignee", -49.0, -55.0], ["araignee", -31.0, -70.0], ["araignee", -45.0, -73.0], ["plante", -34.0, -51.0]]],
	["marais", Vector2(-132.0, -8.0), 58.0, "", 420.0, [["crocodile", -118.0, -20.0], ["crocodile", -146.0, 6.0], ["crocodile", -150.0, -30.0], ["crocodile", -122.0, 14.0]]],
	["marais_nuit", Vector2(-132.0, -8.0), 58.0, "nuit", 420.0, [["follet", -128.0, -2.0], ["follet", -140.0, -16.0], ["follet", -116.0, 6.0]]],
	["jungle_est", Vector2(64.0, -22.0), 40.0, "", 480.0, [["ronceux", 58.0, -16.0], ["ronceux", 72.0, -28.0], ["plante", 66.0, -10.0], ["plante", 54.0, -30.0], ["araignee", 76.0, -16.0]]],
	["balafre", Vector2(138.0, -36.0), 42.0, "", 480.0, [["scorpion", 120.0, -44.0], ["scorpion", 138.0, -36.0], ["scorpion", 158.0, -26.0]]],
	["fort", Vector2(150.0, 58.0), 46.0, "", 540.0, [["squelette", 141.0, 52.0], ["squelette", 158.0, 51.0], ["squelette", 149.0, 66.0], ["squelette", 161.0, 62.0]]],
	["cimetiere", Vector2(-88.0, 22.0), 32.0, "nuit", 420.0, [["squelette", -93.0, 18.0], ["squelette", -84.0, 27.0], ["squelette", -80.0, 15.0]]],
]
const VIEILLE_DENT := Vector2(-158.0, -14.0)

var main: Node
var ile: Node3D
var port: Node3D
var flore: Node3D
var pc: bool = true
var habitants: Array = []
var by_id: Dictionary = {}
var bagarre: Node
var state := {}
var lairs: Array = []                # {id, c, r, quand, respawn, list, monsters, dead_t, boss}
var rhubarbe: Node3D                 # le perroquet de la capitaine, sur son perchoir
var chest_lid: Node3D                # le couvercle du coffre de Barbe-Sanglante
var _claims: Dictionary = {}
var _clock: float = 0.0
var _rng := RandomNumberGenerator.new()
var _smoke: Array = []
var _fires: Array = []
var _torch_fires: Array = []
var _night: bool = false
var _night_t: float = 0.0
var _lair_t: float = 0.0
var _dice_fx: Array = []             # {node, t, from, to, spin}
var _lid_t: float = -1.0
var _interactions: Array = []
var _rowdy_t: float = 20.0
const CHERCHE := ["Qu'est-ce que tu regardes, toi ?", "Hé ! Tu m'as bousculé !", "T'as renversé mon verre, là. Tu vas me le payer.",
	"Toi, t'as une tête qui ne me revient pas.", "On t'a pas appris à saluer, terrien ?", "Pousse-toi, tu me fais de l'ombre."]


func setup(main_node: Node) -> void:
	main = main_node
	pc = OS.has_feature("ile_manga_pc")
	_rng.seed = 6890
	state = _fresh_state()
	PirateBrain.mgr = self
	bagarre = BagarreScript.new()
	bagarre.name = "Bagarre_v68"
	add_child(bagarre)
	bagarre.setup(self, main)


func _fresh_state() -> Dictionary:
	return {"visite": false, "champions": {}, "victoires": 0, "defaites": 0, "fuites": 0, "perroquet": false, "perroquet_rendu": false,
		"vieille_dent": false, "capitaine": false, "tresor": false, "tatouage": false, "nuits": 0, "chansons": 0}


# =================================================================== construction

func build_island() -> void:
	ile = IleScript.new()
	ile.name = "Ile_balafre_v68"
	add_child(ile)
	ile.build(pc)


## Après le relief et l'heure du jour : le port, les navires, la végétation, les feux.
func build_town() -> void:
	port = PortScript.new()
	port.name = "Port_Coutelas_v68"
	add_child(port)
	port.build(main, ile, pc)
	flore = FloreScript.new()
	flore.name = "Flore_balafre_v68"
	add_child(flore)
	for a in port.flora_avoid:
		flore.avoid.append(a)
	var palms: Array = []
	for pp in [Vector2(-60.0, 88.0), Vector2(-30.0, 46.0), Vector2(26.0, 74.0), Vector2(56.0, 70.0), Vector2(-14.0, 74.0), Vector2(68.0, 86.0), Vector2(-74.0, 66.0)]:
		var w: Vector3 = IleScript.W(pp.x, pp.y)
		w.y = ile.height(w.x, w.z)
		palms.append(w)
	for ep in port.extra_palms:
		palms.append(ep)
	flore.build_balafre(ile, pc, palms)
	for sp in port.smoke_spots:
		_smoke.append(_make_smoke(sp))
	for fs in port.fire_spots:
		_fires.append(_make_fire(fs[0], float(fs[1]), true))
	for tp in port.torches:
		_torch_fires.append(_make_fire(tp, 0.55, false))
	_build_lairs()
	_build_rhubarbe()
	_build_chest()
	print("ILE_MANGA_V68: Port-Coutelas prêt")


func dock() -> Array:
	return [IleScript.W(IleScript.DOCK_A.x, IleScript.DOCK_A.y), IleScript.W(IleScript.DOCK_B.x, IleScript.DOCK_B.y)]


func contains(p: Vector3) -> bool:
	return ile != null and ile.contains(p.x, p.z) and p.y > -45.0


## À bord d'un navire, sur un ponton, une passerelle ou un échafaudage du port ?
func on_structure(p: Vector3) -> bool:
	return port != null and port.on_structure(p)


## À pied : on peut marcher ici (la terre ferme, les navires, les pontons) ?
func walkable(p: Vector3) -> bool:
	if not contains(p):
		return false
	if on_structure(p):
		return true
	return ile.height(p.x, p.z) > -0.3


func blocks_boat(p: Vector3) -> bool:
	return port != null and port.blocks_boat(p)


## La zone du joueur (pour la musique et les ambiances).
func zone_at(p: Vector3) -> String:
	if ile == null or not ile.contains(p.x, p.z) or p.y < -20.0:
		return ""
	if port != null:
		var pz: String = port.zone_at(p)
		if pz != "":
			return pz
	var l: Vector2 = IleScript.L(p.x, p.z)
	var h: float = ile.height(p.x, p.z)
	if h < -0.42 and p.y < 2.0 and not on_structure(p):
		return "" if ile.coast_q(l.x, l.y) > 1.12 else "balafre_rivage"
	if IleScript._rect_dist(l.x, l.y, IleScript.TOWN) < 6.0 or (l.y > 88.0 and l.y < 150.0 and l.x > -90.0 and l.x < 75.0):
		return "balafre_port"
	if l.distance_to(IleScript.MARSH) < IleScript.MARSH_R + 10.0:
		return "balafre_marais"
	if IleScript.ravine(l.x, l.y).x < 16.0 or l.distance_to(IleScript.CIRQUE) < IleScript.CIRQUE_R + 8.0:
		return "balafre_ravin"
	if l.distance_to(Vector2(IleScript.PADS["fort"][0], IleScript.PADS["fort"][1])) < 34.0:
		return "balafre_fort"
	if l.distance_to(Vector2(IleScript.PADS["cimetiere"][0], IleScript.PADS["cimetiere"][1])) < 22.0:
		return "balafre_cimetiere"
	if l.distance_to(IleScript.BONES) < 42.0:
		return "balafre_plage"
	return "balafre_jungle"


## Dans une taverne (le Crâne Fendu, la Dent du Requin) : une bagarre y dégénère plus vite.
func inside_tavern(p: Vector3) -> bool:
	var z: String = port.zone_at(p) if port != null else ""
	return z in ["balafre_crane_fendu", "balafre_dent_requin"]


func respawn_point() -> Array:
	var at: Vector3 = IleScript.W(10.0, 86.0, IleScript.town_y(10.0, 86.0) + 0.3)
	return [at, Vector3(0, 0, 1)]


## Les monstres de l'intérieur sont éveillés (monstres_v36 : « dehors »), ou une bagarre a lieu
## (en VR, les cœurs s'affichent au poignet).
func hostile_zone(p: Vector3) -> bool:
	if bagarre != null and bool(bagarre.active):
		return true
	for L in lairs:
		if not (L["monsters"] as Array).is_empty() and Vector2(p.x - L["c"].x, p.z - L["c"].z).length() < float(L["r"]) + 20.0:
			return true
	return false


func hour() -> float:
	return float(main.temps_v56.hour) if main.get("temps_v56") != null and main.temps_v56 != null else 12.0


func _now() -> float:
	return float(main.game_menu.seconds) if main != null and main.game_menu != null else 0.0


# =================================================================== les habitants

func spot(name: String) -> Dictionary:
	return port.spots.get(name, {}) if port != null else {}


func spot_free(name: String, who: Node) -> bool:
	var c: Variant = _claims.get(name, null)
	return c == null or c == who or not is_instance_valid(c)


func claim_spot(name: String, who: Node) -> void:
	_claims[name] = who


func release_spot(name: String, who: Node) -> void:
	if _claims.get(name, null) == who:
		_claims.erase(name)


func spawn_npcs() -> void:
	if not habitants.is_empty() or port == null:
		return
	PirateBrain.mgr = self
	for data in Habitants.all_profiles():
		var start: String = "sq_c"
		var home: String = str(data.get("maison", ""))
		if port.points.has(home):
			start = home
		var npc: Node3D = PnjPir.new()
		main.add_child(npc)
		npc.setup(main, data, port.points, port.graph, start)
		npc.setup_azur(self, data)
		var saved: Variant = main.pending_pnj_v31.get(str(data["id"]), {})
		if saved is Dictionary and not (saved as Dictionary).is_empty():
			npc.load_data(saved)
		main.npcs_v31.append(npc)
		habitants.append(npc)
		by_id[str(data["id"])] = npc
	if bool(state.get("perroquet_rendu", false)):
		_give_parrot_back()
	print("ILE_MANGA_V68: %d habitants à Port-Coutelas" % habitants.size())


## Une bagarre éclate (un mot de travers, un coup, une partie de dés qui tourne mal).
func brawl(npc: Node3D, motif: String, loyal: bool) -> void:
	if bagarre != null:
		bagarre.start(npc, motif, loyal)


## Un attaquant au tapis, mis au tapis par le joueur.
func on_npc_down(npc: Node, fair: bool) -> void:
	var id: String = str(npc.profile.get("id", ""))
	if id in CHAMPIONS and fair:
		var ch: Dictionary = state["champions"]
		if not bool(ch.get(id, false)):
			ch[id] = true
			var n: int = 0
			for c in CHAMPIONS:
				if bool(ch.get(c, false)):
					n += 1
			main._show_message_v28("%s, un des trois champions du port, est au tapis ! (%d sur 3)" % [str(npc.display_name), n])


func on_brawl_won(down: Array, fair: bool, motif: String, leader: Node) -> void:
	state["victoires"] = int(state["victoires"]) + 1
	if motif == "dette" and is_instance_valid(leader) and str(leader.profile.get("id", "")) == "lestrange":
		main._show_message_v28("Jambe-de-Bois est au tapis. Quand il se sera relevé, parle-lui : il te doit une bourse.")
	if not fair and not down.is_empty():
		for n in down:
			if is_instance_valid(n) and str(n.profile.get("id", "")) in CHAMPIONS:
				main._show_message_v28("(Avec une lame, ça ne compte pas pour le titre de Roi de la Bagarre.)")
				break


## Évanoui sur l'île : une bagarre perdue (on se réveille sur le quai, la bourse plus légère), ou
## les monstres de l'intérieur (des pirates nous ramassent et le Doc nous recoud).
func on_faint() -> void:
	if bagarre != null and bool(bagarre.active):
		bagarre.end("defaite")
		state["defaites"] = int(state["defaites"]) + 1
		var have: int = main.inventory_v28.count("piece")
		var lost: int = mini(int(have * 0.2), 30)
		if lost > 0:
			main.inventory_v28.remove("piece", lost)
		var rp: Array = respawn_point()
		main.place_player_v35(rp[0], rp[1])
		if lost > 0:
			main._show_message_v28("Tu te réveilles sur le quai, la mâchoire en compote… et %d pièces en moins. Ici, les poches ont des mains." % lost)
		else:
			main._show_message_v28("Tu te réveilles sur le quai, la mâchoire en compote. Les mouettes rigolent.")
		return
	var sp: Dictionary = spot("doc_porte")
	if not sp.is_empty():
		var at: Vector3 = sp["pos"] + Vector3.UP * 0.3
		main.place_player_v35(at, Vector3(0, 0, 1))
	else:
		var rp2: Array = respawn_point()
		main.place_player_v35(rp2[0], rp2[1])
	main._show_message_v28("Vous vous êtes évanoui… Des pirates vous ont ramassé et déposé chez le Doc, qui vous a recousu sans poser de questions.")


# =================================================================== services

func register_services(journal: Node) -> void:
	journal.add_service("mama_grog", Callable(self, "_mama_topics"), Callable(self, "_mama_choose"))
	journal.add_service("doc", Callable(self, "_doc_topics"), Callable(self, "_doc_choose"))
	journal.add_service("coralie", Callable(self, "_coralie_topics"), Callable(self, "_coralie_choose"))
	journal.add_service("tom", Callable(self, "_tom_topics"), Callable(self, "_tom_choose"))
	for k in port.objets:
		journal.lieux["carte_fort" if k == "fort_donjon" else ("carte_mausolee" if k == "mausolee" else k)] = port.objets[k]
	for k2 in ["herbe_fievre_1", "herbe_fievre_2", "herbe_fievre_3"]:
		journal.lieux[k2] = _extra_spot(k2)
	_register_interactions()


func _extra_spot(k: String) -> Vector3:
	var pts := {"herbe_fievre_1": Vector2(-112.0, -4.0), "herbe_fievre_2": Vector2(-138.0, -30.0), "herbe_fievre_3": Vector2(-128.0, 18.0)}
	var v: Vector2 = pts[k]
	var w: Vector3 = IleScript.W(v.x, v.y)
	w.y = maxf(ile.height(w.x, w.z), IleScript.MARSH_Y) + 0.1
	return w


func _mama_topics(_npc: Node) -> Array:
	var night: bool = hour() >= 18.0 or hour() < 6.0
	return [{"id": "q56:service:hamac", "label": "☾ %s (5 pièces)" % ("Un hamac dans l'arrière-salle, pour la nuit" if night else "Un hamac pour une sieste")}]


func _mama_choose(_npc: Node, _choice: String) -> Dictionary:
	if main.inventory_v28.count("piece") < 5:
		return {"texte": "Cinq pièces, mon chou. Même les hamacs, ici, ça se paie. Surtout les hamacs : ils ont vu des choses.", "geste": "parle"}
	var night: bool = hour() >= 18.0 or hour() < 6.0
	return {"texte": ("Le hamac du fond, à côté des tonneaux. Si Tonneau ronfle, tape-lui dessus, il a l'habitude." if night else "Va, va. Je te réveille pour le grog du soir."),
		"geste": "salut", "fin": true, "prendre": [["piece", 5]], "_hamac68": 7.0 if night else 18.5}


func _doc_topics(_npc: Node) -> Array:
	return [{"id": "q56:service:soins", "label": "✚ Me faire recoudre (4 pièces)"}]


func _doc_choose(_npc: Node, _choice: String) -> Dictionary:
	var hero: Node = main.get("hero_v28")
	if hero != null and int(hero.hp) >= int(hero.HP_MAX) and not main.xr_active:
		return {"texte": "Te recoudre ? Il n'y a rien à recoudre. Reviens après ta prochaine bagarre. Ça ne devrait pas tarder.", "geste": "rire"}
	if main.inventory_v28.count("piece") < 4:
		return {"texte": "Quatre pièces. Le fil n'est pas gratuit, ni le rhum pour désinfecter. Surtout le rhum.", "geste": "parle"}
	return {"texte": "Assieds-toi. Serre les dents. … Voilà. Trois points de suture, un peu de baume, et une gorgée de rhum (pour moi). Tu es comme neuf. Enfin, comme d'occasion.",
		"geste": "parle", "prendre": [["piece", 4]], "_soins68": true}


func _coralie_topics(_npc: Node) -> Array:
	if bool(state.get("tatouage", false)):
		return []
	return [{"id": "q56:service:tatouage", "label": "✒ Un tatouage de pirate (15 pièces)"}]


func _coralie_choose(_npc: Node, _choice: String) -> Dictionary:
	if main.inventory_v28.count("piece") < 15:
		return {"texte": "Quinze pièces. L'encre de seiche, ça ne se pêche pas tout seul. Reviens quand tu auras de quoi.", "geste": "parle"}
	return {"texte": "Une ancre, sur l'avant-bras. Simple, solide, comme toi. Ne bouge pas… (bzzzt, bzzzt…) Voilà. Montre-la au comptoir : ici, ceux qui portent ma marque, on leur cherche un peu moins de noises.",
		"geste": "salut", "prendre": [["piece", 15]], "_tatouage68": true}


func _tom_topics(_npc: Node) -> Array:
	return [{"id": "q56:service:chanson", "label": "♪ Une chanson, Tom ! (1 pièce)"}]


func _tom_choose(_npc: Node, _choice: String) -> Dictionary:
	if main.inventory_v28.count("piece") < 1:
		return {"texte": "Même pas une pièce ? Bon. Je te chante le refrain gratis, mais je chante faux exprès.", "geste": "rire"}
	var roi: bool = main.get("journal_v56") != null and main.journal_v56.state("bal_roi") == "finie"
	var verses: Array = [
		"♪ À Port-Coutelas, mes frères, on boit, on chante, on se bat,\nUn mot de travers, c'est la guerre, et le grog coule à pleins bras ! ♪",
		"♪ Gros-Louis frappe comme un chêne, le Muet comme un volcan,\nBelle-Humeur, il a la haine, mais il a de beaux enfants ! ♪",
		"♪ Barbe-Sanglante a tout caché, sous le crâne aux yeux qui brillent,\nIl a laissé ses os garder… et ses os, eh bien, ils grillent ! ♪",
	]
	if roi:
		verses.append("♪ Et puis vint un étranger, aux poings durs comme l'airain,\nIl a mis les trois au tapis : vive le Roi, le roi des poings ! ♪")
	var v: String = str(verses[verses.size() - 1] if roi and _rng.randf() < 0.6 else verses[_rng.randi() % verses.size()])
	return {"texte": "(Tom accorde son violon, tape du pied, et chante à tue-tête.)\n\n" + v, "geste": "rire", "prendre": [["piece", 1]], "_chanson68": true}


## Appelé par main après un échange réussi : la bagarre, la tournée, les dés, le hamac, les soins…
func after_reply(r: Dictionary, npc: Node) -> void:
	if r.has("_bagarre68"):
		var b: Dictionary = r["_bagarre68"]
		main._close_dialogue_v31()
		if npc != null and npc.has_method("say_bubble"):
			var t: String = str(r.get("texte", ""))
			var last: String = t.split("\n")[-1] if t != "" else ""
			if last.length() < 90 and last != "":
				npc.say_bubble(last, 3.0)
		brawl(npc, str(b.get("motif", "")), bool(b.get("loyal", false)))
	if r.has("_trinque68"):
		main._close_dialogue_v31()
		var o: Node = main.get("objets_v66")
		if o != null:
			o.drink(str(r["_trinque68"]), true)
		if npc != null and npc.has_method("say_bubble"):
			npc.say_bubble(["À la tienne !", "Santé, matelot !", "Cul sec !", "À la Balafre !"][_rng.randi() % 4], 2.5)
	if r.has("_sfx68") and main.has_method("sfx") and npc != null:
		main.sfx(str(r["_sfx68"]), (npc as Node3D).global_position + Vector3.UP * 1.0)
	if r.has("_des68") and npc != null:
		_roll_dice_fx(npc)
	if r.has("_hamac68"):
		main._close_dialogue_v31()
		state["nuits"] = int(state["nuits"]) + 1
		main.temps_v56.sleep_until(float(r["_hamac68"]))
	if r.has("_soins68"):
		var hero: Node = main.get("hero_v28")
		if hero != null:
			hero.hp = hero.HP_MAX
			hero.health_changed.emit(hero.hp, hero.HP_MAX)
		if main.has_method("sfx"):
			main.sfx("sort_soin", main._player_pos_v27() + Vector3.UP)
	if r.has("_tatouage68"):
		state["tatouage"] = true
		main._show_message_v28("Une ancre tatouée sur l'avant-bras : les pirates de la Balafre te cherchent un peu moins de noises.")
		if main.has_method("jingle"):
			main.jingle("decouverte")
	if r.has("_chanson68"):
		state["chansons"] = int(state["chansons"]) + 1
	if str(r.get("_fin56", "")) == "bal_perroquet":
		state["perroquet_rendu"] = true
		_give_parrot_back()


## Rhubarbe retrouve l'épaule de la capitaine.
func _give_parrot_back() -> void:
	var ar: Node = by_id.get("anne_rose", null)
	if ar == null or ar.has_meta("perroquet68"):
		return
	ar._tz_accessories({"perroquet": true})
	ar.set_meta("perroquet68", true)


## Le soir, dans les tavernes (ou quand on a trop bu), un pirate éméché vient chercher des noises :
## il n'attaque pas tout de suite, mais il est déjà à moitié fâché (on peut le calmer, lui offrir
## un verre… ou s'éloigner).
func _rowdy_tick(p: Vector3) -> void:
	if bagarre == null or bool(bagarre.active) or not bool(main.get("game_started")):
		return
	if main.get("dialogue_v31") != null and main.dialogue_v31 != null and bool(main.dialogue_v31.opened):
		return
	var h: float = hour()
	var o: Node = main.get("objets_v66")
	var drunk: float = float(o.get("ivresse")) if o != null else 0.0
	var tavern: bool = inside_tavern(p)
	if not ((tavern and (h >= 19.0 or h < 2.0)) or drunk >= 0.9):
		return
	var chance: float = (0.35 if tavern else 0.15) + clampf(drunk - 0.5, 0.0, 1.0) * 0.3
	if bool(state.get("tatouage", false)):
		chance *= 0.6
	if _rng.randf() > chance:
		return
	var best: Node3D = null
	var best_d: float = 9.0
	for n in habitants:
		if bool(n.hidden_home) or not n.can_talk() or str(n.state) == "parle" or not n.brain.can_fight():
			continue
		if float((n.profile.get("traits", {}) as Dictionary).get("susceptible", 0.5)) < 0.5 or n.brain.tension() > 0.3 or float(n.brain.affinite) > 40.0:
			continue
		var d: float = n.global_position.distance_to(p)
		if d < best_d:
			best_d = d
			best = n
	if best == null:
		return
	best.brain.set_tension(0.55)
	best.say_bubble(str(CHERCHE[_rng.randi() % CHERCHE.size()]), 4.0)
	best.gesture("colere")


# =================================================================== les dés qui roulent

func _roll_dice_fx(npc: Node) -> void:
	var p: Vector3 = (npc as Node3D).global_position
	var best: Vector3 = Vector3.INF
	for k in port.dice_tables:
		var tp: Vector3 = port.dice_tables[k]["pos"]
		if tp.distance_to(p) < 2.6 and (best == Vector3.INF or tp.distance_to(p) < best.distance_to(p)):
			best = tp
	var player: Vector3 = main._player_pos_v27()
	if best == Vector3.INF:
		# pas de table : on lance par terre, entre le joueur et lui
		best = (p + player) * 0.5
		best.y = maxf(p.y, player.y) - 0.05
	var m: Material = port.kit.mat("de")
	for i in range(6):
		var d := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.07, 0.07, 0.07)
		d.mesh = bm
		d.material_override = m
		add_child(d)
		var from: Vector3 = (player if i < 3 else p) + Vector3.UP * 1.2
		var to: Vector3 = best + Vector3(_rng.randf_range(-0.22, 0.22), 0.04, _rng.randf_range(-0.22, 0.22))
		d.global_position = from
		_dice_fx.append({"node": d, "t": -0.08 * i, "from": from, "to": to, "spin": Vector3(_rng.randf_range(-14, 14), _rng.randf_range(-14, 14), _rng.randf_range(-14, 14))})


func _dice_tick(delta: float) -> void:
	for e in _dice_fx.duplicate():
		e["t"] = float(e["t"]) + delta
		var t: float = float(e["t"])
		var d: MeshInstance3D = e["node"]
		if t < 0.0:
			continue
		var k: float = clampf(t / 0.7, 0.0, 1.0)
		var pos: Vector3 = (e["from"] as Vector3).lerp(e["to"], k)
		pos.y += sin(k * PI) * 0.35 + absf(sin(k * PI * 3.0)) * 0.06 * (1.0 - k)
		d.global_position = pos
		if k < 1.0:
			d.rotation += (e["spin"] as Vector3) * delta * (1.0 - k)
		else:
			# posé : une face bien à plat
			d.rotation = Vector3(snappedf(d.rotation.x, PI * 0.5), d.rotation.y, snappedf(d.rotation.z, PI * 0.5))
		if t > 6.0:
			d.queue_free()
			_dice_fx.erase(e)


# =================================================================== les repaires des monstres

func _build_lairs() -> void:
	lairs.clear()
	for e in LAIRS:
		var c2: Vector2 = e[1]
		var list: Array = []
		for m in e[5]:
			list.append([str(m[0]), _ground(float(m[1]), float(m[2]))])
		lairs.append({"id": str(e[0]), "c": _ground(c2.x, c2.y), "r": float(e[2]), "quand": str(e[3]), "respawn": float(e[4]), "list": list,
			"monsters": [], "dead_t": -1e15, "boss": ""})
	# Vieille-Dent, au fond du marais (une seule fois)
	lairs.append({"id": "vieille_dent", "c": _ground(VIEILLE_DENT.x, VIEILLE_DENT.y), "r": 30.0, "quand": "", "respawn": 1e12,
		"list": [["vieille_dent", _ground(VIEILLE_DENT.x, VIEILLE_DENT.y)]], "monsters": [], "dead_t": -1e15, "boss": "vieille_dent"})
	# le Capitaine Sans-Chair, dans le Cirque du Crâne (quand on y vient avec la carte)
	var cc: Vector3 = port.cirque_center
	var cl: Array = [["capitaine_os", cc + Vector3(-2.0, 0.1, 0.0)], ["squelette", cc + Vector3(3.0, 0.1, -4.0)], ["squelette", cc + Vector3(3.0, 0.1, 4.0)]]
	lairs.append({"id": "capitaine", "c": cc, "r": 26.0, "quand": "", "respawn": 300.0, "list": cl, "monsters": [], "dead_t": -1e15, "boss": "capitaine"})


func _ground(x: float, z: float) -> Vector3:
	var w: Vector3 = IleScript.W(x, z)
	w.y = ile.height(w.x, w.z) + 0.15
	return w


func _lair_open(L: Dictionary) -> bool:
	var h: float = hour()
	if str(L["quand"]) == "nuit" and not (h >= 20.0 or h < 5.0):
		return false
	match str(L["boss"]):
		"vieille_dent":
			return not bool(state["vieille_dent"])
		"capitaine":
			return not bool(state["capitaine"]) and main.inventory_v28.count("carte_barbe") > 0
	return true


func _lairs_tick() -> void:
	var mo: Node = main.get("monstres_v36")
	if mo == null or not bool(main.get("game_started")):
		return
	var p: Vector3 = main._player_pos_v27()
	var now: float = _now()
	for L in lairs:
		var d: float = Vector2(p.x - L["c"].x, p.z - L["c"].z).length()
		var open: bool = _lair_open(L)
		var mons: Array = L["monsters"]
		if mons.is_empty():
			if open and d < float(L["r"]) and absf(p.y - L["c"].y) < 25.0 and now - float(L["dead_t"]) > float(L["respawn"]):
				_spawn_lair(L, mo)
			continue
		var alive: Array = mons.filter(func(m): return is_instance_valid(m) and str(m.state) != "mort")
		if alive.is_empty():
			L["monsters"] = []
			L["dead_t"] = now
			_lair_cleared(L)
		elif d > float(L["r"]) + 35.0 or not open:
			for m2 in mons:
				if is_instance_valid(m2):
					mo.monsters.erase(m2)
					m2.queue_free()
			L["monsters"] = []


func _spawn_lair(L: Dictionary, mo: Node) -> void:
	var out: Array = []
	for e in L["list"]:
		var at: Vector3 = e[1]
		var m: Node3D = mo.spawn_extra(str(e[0]), at)
		m.home = at
		m.state = "veille"
		if str(L["id"]) == "cimetiere" or str(L["boss"]) == "capitaine" or str(e[0]) == "vieille_dent":
			if m.has_method("emerge"):
				m.emerge(1.8)
		out.append(m)
	L["monsters"] = out
	match str(L["boss"]):
		"vieille_dent":
			main._show_message_v28("La vase bouillonne… Une gueule énorme sort de l'eau noire : VIEILLE-DENT !")
			if main.has_method("sfx"):
				main.sfx("croco_menace", L["c"] + Vector3.UP)
		"capitaine":
			main._show_message_v28("La carte frémit dans ton sac. Le sable du Cirque se soulève… des os remontent, s'assemblent : LE CAPITAINE SANS-CHAIR !")
			if main.has_method("sfx"):
				main.sfx("boss_coeur_cri", L["c"] + Vector3.UP)
	if str(L["id"]) == "cimetiere":
		main._show_message_v28("La terre du cimetière remue… Des mains d'os sortent des tombes !")


func _lair_cleared(L: Dictionary) -> void:
	match str(L["boss"]):
		"vieille_dent":
			state["vieille_dent"] = true
			main._show_message_v28("Vieille-Dent ne bougera plus. Le marais retient son souffle… Crochet va être content.")
			if main.has_method("jingle"):
				main.jingle("victoire")
		"capitaine":
			state["capitaine"] = true
			main._show_message_v28("Le Capitaine Sans-Chair s'effondre en un tas d'os. Les yeux du Rocher du Crâne s'éteignent… La bouche du crâne t'attend.")
			if main.has_method("jingle"):
				main.jingle("victoire")


# =================================================================== Rhubarbe, le coffre

func _build_rhubarbe() -> void:
	rhubarbe = Node3D.new()
	rhubarbe.name = "Rhubarbe"
	add_child(rhubarbe)
	var red := _m(Color(0.82, 0.1, 0.07))
	var blue := _m(Color(0.1, 0.32, 0.82))
	var yellow := _m(Color(0.98, 0.78, 0.12))
	_sph(rhubarbe, 0.08, red, Vector3(0, 0.1, 0), Vector3(0.9, 1.5, 1.0))
	var head := Node3D.new()
	head.name = "Tete"
	head.position = Vector3(0, 0.23, 0.02)
	rhubarbe.add_child(head)
	_sph(head, 0.058, red, Vector3.ZERO, Vector3.ONE)
	var beak := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.0
	cm.bottom_radius = 0.022
	cm.height = 0.06
	beak.mesh = cm
	beak.material_override = _m(Color(0.9, 0.85, 0.7))
	beak.position = Vector3(0, -0.01, 0.06)
	beak.rotation_degrees = Vector3(80, 0, 0)
	head.add_child(beak)
	for sx in [-1.0, 1.0]:
		_sph(rhubarbe, 0.05, blue, Vector3(sx * 0.06, 0.09, -0.01), Vector3(0.4, 1.5, 1.0))
		_sph(head, 0.012, _m(Color(0.02, 0.02, 0.02)), Vector3(sx * 0.04, 0.012, 0.035), Vector3.ONE)
	var tail := MeshInstance3D.new()
	var tb := BoxMesh.new()
	tb.size = Vector3(0.05, 0.2, 0.02)
	tail.mesh = tb
	tail.material_override = blue
	tail.position = Vector3(0, -0.07, -0.06)
	tail.rotation_degrees = Vector3(-24, 0, 0)
	rhubarbe.add_child(tail)
	_sph(rhubarbe, 0.03, yellow, Vector3(0, 0.0, 0.05), Vector3(1.2, 0.6, 0.6))
	rhubarbe.global_position = port.perch_pos
	rhubarbe.visible = false


func _build_chest() -> void:
	var at: Vector3 = port.treasure_pos
	var root := Node3D.new()
	root.name = "Coffre_Barbe_Sanglante"
	add_child(root)
	root.global_position = at
	root.rotation.y = PI * 0.5
	var wood: Material = port.kit.mat("planchesp_sombre")
	var iron: Material = port.kit.mat("fer")
	var gold: Material = port.kit.mat("orp")
	_boxm(root, Vector3(1.1, 0.55, 0.66), wood, Vector3(0, 0.28, 0))
	for x in [-0.42, 0.0, 0.42]:
		_boxm(root, Vector3(0.06, 0.57, 0.68), iron, Vector3(x, 0.28, 0))
	chest_lid = Node3D.new()
	chest_lid.position = Vector3(0, 0.56, -0.33)
	root.add_child(chest_lid)
	_boxm(chest_lid, Vector3(1.12, 0.2, 0.68), wood, Vector3(0, 0.1, 0.33))
	for x2 in [-0.42, 0.0, 0.42]:
		_boxm(chest_lid, Vector3(0.06, 0.22, 0.7), iron, Vector3(x2, 0.1, 0.33))
	_boxm(root, Vector3(0.14, 0.16, 0.04), gold, Vector3(0, 0.5, 0.35))
	# l'or dedans (visible quand le couvercle s'ouvre)
	_boxm(root, Vector3(0.98, 0.04, 0.56), gold, Vector3(0, 0.5, 0))
	var glow := OmniLight3D.new()
	glow.light_color = Color(1.0, 0.8, 0.4)
	glow.light_energy = 0.0
	glow.omni_range = 4.0
	glow.position = Vector3(0, 0.9, 0)
	glow.name = "Lueur"
	root.add_child(glow)
	var sb := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(1.1, 0.75, 0.66)
	cs.shape = bs
	cs.position = Vector3(0, 0.37, 0)
	sb.add_child(cs)
	root.add_child(sb)


func _m(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.6
	return m


func _sph(parent: Node3D, r: float, mat: Material, pos: Vector3, scl: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	sm.radial_segments = 12
	sm.rings = 6
	mi.mesh = sm
	mi.material_override = mat
	mi.position = pos
	mi.scale = scl
	parent.add_child(mi)


func _boxm(parent: Node3D, size: Vector3, mat: Material, pos: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)


func _register_interactions() -> void:
	var d: Node = main.get("donjon_v35")
	if d == null:
		return
	var I: Array = d._interactions
	var pi := {"id": "perchoir_rhubarbe", "pos": port.perch_pos + Vector3.DOWN * 2.0, "radius": 3.2, "text": "E : appeler Rhubarbe", "vr": "Gâchette : appeler Rhubarbe",
		"call": _call_parrot, "when": func(): return _parrot_here()}
	I.append(pi)
	var ti := {"id": "tresor_barbe_sanglante", "pos": port.treasure_pos + Vector3.UP * 0.3, "radius": 2.2, "text": "E : ouvrir le coffre de Barbe-Sanglante", "vr": "Gâchette : ouvrir le coffre",
		"call": _open_chest, "when": func(): return not bool(state["tresor"])}
	I.append(ti)
	_interactions = [pi, ti]


func _parrot_here() -> bool:
	var j: Node = main.get("journal_v56")
	return j != null and str(j.state("bal_perroquet")) == "en_cours" and str(j._step("bal_perroquet").get("cle", "")) == "perroquet_trouve" and not bool(state["perroquet"])


func _call_parrot() -> void:
	if main.inventory_v28.count("graines") <= 0:
		main._show_message_v28("Rhubarbe te regarde de haut, ébouriffé : « Tête de méduse ! » Il ne descendra pas pour rien… Perroquet-Joe a sûrement de quoi l'attirer.")
		if main.has_method("sfx"):
			main.sfx("perroquet", port.perch_pos)
		return
	main.inventory_v28.remove("graines", 1)
	state["perroquet"] = true
	_lid_t = -1.0
	main._show_message_v28("Tu tends les graines. Rhubarbe penche la tête… descend du perchoir, picore dans ta main, et grimpe sur ton épaule : « MILLE SABORDS ! » Ramène-le à la capitaine.")
	if main.has_method("sfx"):
		main.sfx("perroquet", port.perch_pos)
	if main.has_method("jingle"):
		main.jingle("decouverte")


func _open_chest() -> void:
	if main.inventory_v28.count("carte_barbe") <= 0:
		main._show_message_v28("Un vieux coffre cerclé de fer, fermé par une chaîne d'os. Elle ne cède pas. Sur le couvercle, gravé : « À qui porte ma carte. B.S. »")
		return
	if not bool(state["capitaine"]):
		main._show_message_v28("La chaîne d'os ne bouge pas. Dehors, quelque chose garde encore le trésor… (le Capitaine Sans-Chair, dans le Cirque)")
		return
	var gains := [["piece", 150], ["rubis", 2], ["perle", 3], ["piece_or", 4]]
	if not main.inventory_v28.can_accept(gains, []):
		main._show_message_v28("Ton sac est plein ! Fais de la place avant d'ouvrir le coffre.")
		return
	state["tresor"] = true
	_lid_t = 0.0
	var parts: Array = []
	for g in gains:
		var got: int = main.inventory_v28.add(str(g[0]), int(g[1]))
		if got > 0:
			parts.append("%d × %s" % [got, str(main.inventory_v28.ITEMS[str(g[0])]["name"]).to_lower()])
	main._show_message_v28("La chaîne d'os tombe en poussière. Le couvercle grince… LE TRÉSOR DE BARBE-SANGLANTE ! (" + ", ".join(parts) + ")")
	if main.has_method("sfx"):
		main.sfx("coffre", port.treasure_pos)
	if main.has_method("jingle"):
		main.jingle("victoire")


# =================================================================== chaque image

func _process(delta: float) -> void:
	if main == null or ile == null:
		return
	var p: Vector3 = main._player_pos_v27()
	# l'océan suit le joueur (comme autour de la grande île : par pas de 40 m)
	if ile.contains(p.x, p.z):
		var oc: Node3D = main.get("ocean")
		if oc != null:
			oc.position.x = snappedf(p.x, 40.0)
			oc.position.z = snappedf(p.z, 40.0)
	if not bool(state["visite"]) and ile.contains(p.x, p.z) and (ile.height(p.x, p.z) > -0.2 or on_structure(p)) and bool(main.get("game_started")):
		state["visite"] = true
		main._show_message_v28("L'Île de la Balafre — Port-Coutelas, le repaire des pirates")
		if main.has_method("jingle"):
			main.jingle("decouverte")
	if port == null or Vector2(p.x - ile.CENTER.x, p.z - ile.CENTER.z).length() > 420.0:
		return
	_clock += delta
	_dice_tick(delta)
	_lair_t -= delta
	if _lair_t <= 0.0:
		_lair_t = 0.5
		_lairs_tick()
	_rowdy_t -= delta
	if _rowdy_t <= 0.0:
		_rowdy_t = _rng.randf_range(14.0, 24.0)
		_rowdy_tick(p)
	# la nuit : les lanternes, les fenêtres des navires, les torches du Cirque, les yeux du crâne
	_night_t -= delta
	if _night_t <= 0.0:
		_night_t = 2.0
		var h: float = hour()
		var night: bool = h >= 19.0 or h < 6.0
		if night != _night or _clock < 3.0:
			_night = night
			for l in port.kit.lights68:
				(l as OmniLight3D).light_energy = (1.5 if (l as OmniLight3D).omni_range < 6.0 else 1.25) if night else 0.0
			for id in port.ships:
				port.ships[id].set_night(night)
			for tf in _torch_fires:
				(tf as Node3D).visible = night
	# les pavillons flottent au vent, la corde de la potence se balance
	for i in range(port.kit.flags.size()):
		var f: MeshInstance3D = port.kit.flags[i]
		var base: Transform3D = f.get_meta("base")
		f.transform = base * Transform3D(Basis(Vector3.UP, sin(_clock * 1.9 + i) * 0.22) * Basis(Vector3.RIGHT, sin(_clock * 3.1 + i * 2.0) * 0.06), Vector3.ZERO)
	if port.gallows_rope != null:
		port.gallows_rope.rotation.z = sin(_clock * 0.9) * 0.06
		port.gallows_rope.rotation.x = sin(_clock * 0.7 + 1.0) * 0.04
	# Rhubarbe sur son perchoir (tant qu'on ne l'a pas retrouvé)
	if rhubarbe != null:
		var j: Node = main.get("journal_v56")
		var show: bool = j != null and str(j.state("bal_perroquet")) == "en_cours" and not bool(state["perroquet"])
		rhubarbe.visible = show
		if show:
			var hd: Node3D = rhubarbe.get_node_or_null("Tete")
			if hd != null:
				hd.rotation.y = sin(_clock * 1.7) * 0.7 + sin(_clock * 5.1) * 0.2
			rhubarbe.position.y = port.perch_pos.y + absf(sin(_clock * 0.8)) * 0.02
			rhubarbe.rotation.y = sin(_clock * 0.3) * 0.8
	# le couvercle du coffre s'ouvre
	if chest_lid != null:
		if _lid_t >= 0.0:
			_lid_t += delta
		var open_k: float = 1.0 if bool(state["tresor"]) and _lid_t < 0.0 else clampf(_lid_t / 1.4, 0.0, 1.0)
		chest_lid.rotation.x = -open_k * 1.9
		var lg: OmniLight3D = chest_lid.get_parent().get_node_or_null("Lueur")
		if lg != null:
			lg.light_energy = 2.2 * open_k * (0.85 + 0.15 * sin(_clock * 3.0)) if not bool(state["tresor"]) or _lid_t < 30.0 else 0.6


func _make_smoke(at: Vector3) -> CPUParticles3D:
	var s := CPUParticles3D.new()
	s.name = "Fumee_bal"
	s.amount = 16
	s.lifetime = 5.0
	s.emitting = true
	s.direction = Vector3(0.2, 1, 0.1)
	s.spread = 12.0
	s.initial_velocity_min = 0.5
	s.initial_velocity_max = 0.9
	s.gravity = Vector3(0.2, 0.12, 0.05)
	s.scale_amount_min = 0.6
	s.scale_amount_max = 1.4
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.3))
	curve.add_point(Vector2(1.0, 1.6))
	s.scale_amount_curve = curve
	var qm := QuadMesh.new()
	qm.size = Vector2(0.9, 0.9)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.62, 0.6, 0.58, 0.24)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	if main != null and main.has_method("_soft_dot_v24"):
		m.albedo_texture = main._soft_dot_v24()
	qm.material = m
	s.mesh = qm
	s.visibility_aabb = AABB(Vector3(-3, -1, -3), Vector3(6, 12, 6))
	add_child(s)
	s.global_position = at
	return s


## Un feu (flammes en particules et une lumière orangée qui vacille).
func _make_fire(at: Vector3, s: float, on: bool) -> Node3D:
	var root := Node3D.new()
	root.name = "Feu_bal"
	add_child(root)
	root.global_position = at
	var p := CPUParticles3D.new()
	p.amount = int(24 * s) + 8
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
	root.add_child(p)
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.6, 0.25)
	l.light_energy = 1.6 * s
	l.omni_range = 6.0 * s + 2.0
	l.shadow_enabled = false
	l.position = Vector3.UP * 0.4
	l.distance_fade_enabled = true
	l.distance_fade_begin = 50.0
	l.distance_fade_length = 12.0
	root.add_child(l)
	root.visible = on
	return root


# =================================================================== carnet, sauvegarde

func trouvailles() -> Dictionary:
	var ch: Dictionary = state.get("champions", {})
	var n: int = 0
	for c in CHAMPIONS:
		if bool(ch.get(c, false)):
			n += 1
	return {"balafre": 1 if bool(state["visite"]) else 0, "perroquet_trouve": 1 if bool(state["perroquet"]) else 0,
		"champions_3": 1 if n >= 3 else 0, "champion_1": 1 if n >= 1 else 0, "bagarre_gagnee": 1 if int(state["victoires"]) > 0 else 0,
		"vieille_dent": 1 if bool(state["vieille_dent"]) else 0, "capitaine_os": 1 if bool(state["capitaine"]) else 0,
		"tresor_crane": 1 if bool(state["tresor"]) else 0, "tatouage": 1 if bool(state["tatouage"]) else 0}


func serialize() -> Dictionary:
	return state.duplicate(true)


func load_data(d: Dictionary) -> void:
	state = _fresh_state()
	for k in state:
		if d.has(k):
			state[k] = d[k] if not (d[k] is Dictionary) else (d[k] as Dictionary).duplicate(true)
	_claims.clear()
	_lid_t = -1.0
	if bagarre != null:
		bagarre.active = false
		bagarre.attackers.clear()
		bagarre.allies.clear()
		bagarre.brawlers.clear()
		bagarre.spectators.clear()
	var mo: Node = main.get("monstres_v36") if main != null else null
	for L in lairs:
		for m in L["monsters"]:
			if is_instance_valid(m):
				if mo != null:
					mo.monsters.erase(m)
				m.queue_free()
		L["monsters"] = []
		L["dead_t"] = -1e15
	for n in habitants:
		n.wake_now()
		n.slot = -2
	if bool(state.get("perroquet_rendu", false)):
		_give_parrot_back()
