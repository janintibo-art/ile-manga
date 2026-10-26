extends Node
## V76 : LES COMPAGNONS ANIMAUX — le gestionnaire des quatre compagnons (un seul suit le héros à
## la fois ; les autres attendent « à la maison ») :
##  - SARDINE, le chien (V75, quête bo_sardine, Île du Boucan) : mord les robots et les monstres,
##    rapporte parfois une pièce ;
##  - BRIOCHE, la chatte (quête pet_brioche, Port-Azur) : tigrée rousse et blanche, très digne ;
##    « flair du trésor » (coffre caché d'objets_v66 ou cachette de digging_v33 à moins de 40 m) ;
##    elle chasse les papillons ;
##  - BISCOTTE, le rat (quête pet_biscotte, Île de la Balafre) : blanc et brun, sur l'épaule ;
##    toutes les 3 à 6 minutes, il rapporte un petit trésor (pièces, une gemme, un matériau de
##    l'île) ;
##  - TRUFFE, le cochon (quête pet_truffe, Montjoie) : rose et noir ; dans l'herbe et les bois,
##    toutes les 2 à 4 minutes, il déterre une truffe (et parfois un objet enfoui).
## Le Sifflet des compagnons (objet « sifflet_compagnons », donné à la première adoption) ouvre
## le menu « Qui vient avec moi ? ».
##
## API :
##   setup(main)                      pet(id) -> Node3D        (le compagnon ; pet("sardine") a l'API V75)
##   adopt(id, quiet := false) -> bool    is_adopted(id) -> bool    adopted_list() -> Array
##   active_id() -> String            call_pet(id) -> bool      dismiss(quiet := false)
##   open_menu()                      use_whistle() -> bool    (inventory_v28.use_tool → « sifflet_compagnons »)
##   set_babil(on)                    on_faint()
##   on_board_boat() / on_leave_boat()   (appelés tout seuls quand main.boat_v29.driving change)
##   serialize() -> Dictionary        load_data(d)              trouvailles() -> Dictionary
##   line(id, cle) -> String          (les textes : astralys_textes_v76.gd, const COMPAGNONS)
## Textes (astralys_textes_v76.gd ; des lignes de secours sont ici) : COMPAGNONS[id][clé] = String
## ou Array : adopte, content, trouve (Brioche : un trésor flairé ; Biscotte : « {objet} » ;
## Truffe : une truffe), trouve_objet (Truffe : « {objet} »), dort, bateau, babil ; nos clés en plus
## (facultatives) : appel, maison, papillon, flair ({dir}, {dist}, {quoi}). Sardine : babil, puis
## boucan_textes_v75 (SARDINE). SIFFLET : titre, choix ({nom}), maison ({nom}), vient ({nom}),
## aucun, seul ({nom} : déjà là), personne.

const PetScript = preload("res://scripts/compagnon_v76.gd")
const TEXTES_PATH := "res://scripts/pnj/astralys_textes_v76.gd"
const TEXTES_V75 := "res://scripts/pnj/boucan_textes_v75.gd"
const SIFFLET := "sifflet_compagnons"
const ORDER := ["sardine", "brioche", "biscotte", "truffe"]

## Les quatre compagnons. place : [à droite, en arrière] du joueur ; vitesses : [pas, trot, course] ;
## bateau : la place dans la barque (repère de la coque, la proue vers -Z).
const PETS := {
	"sardine": {"nom": "Sardine", "article": "le chien", "il": "il", "espece": "chien", "noeud": "Sardine_v75",
		"variante": {"taille": 0.95, "base": Color(0.6, 0.43, 0.26), "tache": Color(0.93, 0.9, 0.84), "taches": 0.3, "taches_f": 4.5,
			"ventre": Color(0.93, 0.9, 0.84), "museau_c": Color(0.93, 0.9, 0.84), "museau_k": 0.75, "oreilles": "mixte", "queue": "courbe",
			"hirsute": 0.7, "bandana": Color(0.8, 0.08, 0.06), "museau": 1.0, "pattes": 0.95, "seed": 21},
		"place": [1.1, 1.3], "vitesses": [1.5, 3.4, 6.2], "bulle_y": 1.05, "cris": ["aboiement"], "bateau": Vector3(0, 0.2, -1.38),
		"couche_apres": 20.0, "taille_m": 0.8, "hauteur_rayon": 0.35},
	"brioche": {"nom": "Brioche", "article": "la chatte", "il": "elle", "espece": "chat", "noeud": "Brioche_v76",
		"variante": {"taille": 1.05, "base": Color(0.82, 0.5, 0.22), "tigre": 0.85, "rayure": Color(0.55, 0.27, 0.08), "tache": Color(0.97, 0.95, 0.9),
			"taches": 0.25, "taches_f": 3.0, "ventre": Color(0.97, 0.95, 0.9), "chaussettes": true, "museau_c": Color(0.97, 0.95, 0.9), "museau_k": 0.9,
			"oeil": Color(0.85, 0.65, 0.15), "seed": 76},
		"place": [-1.0, 1.4], "vitesses": [1.0, 2.9, 6.0], "bulle_y": 0.62, "cris": ["miaou"], "bateau": Vector3(0, 0.2, -1.42),
		"couche_apres": 9.0, "taille_m": 0.45, "hauteur_rayon": 0.2},
	"biscotte": {"nom": "Biscotte", "article": "le rat", "il": "il", "espece": "rat", "noeud": "Biscotte_v76",
		"variante": {"taille": 1.0, "base": Color(0.9, 0.88, 0.84), "tache": Color(0.45, 0.3, 0.18), "capuche": true, "seed": 77},
		"place": [-0.6, 0.8], "vitesses": [0.8, 2.6, 5.8], "bulle_y": 0.32, "cris": ["couinement_rat"], "bateau": Vector3(0, 0.45, -0.55),
		"couche_apres": 12.0, "taille_m": 0.2, "hauteur_rayon": 0.06, "epaule_h": 0.06},
	"truffe": {"nom": "Truffe", "article": "le cochon", "il": "il", "espece": "cochon", "noeud": "Truffe_v76",
		"variante": {"taille": 1.0, "seed": 78},
		"place": [1.2, 1.6], "vitesses": [1.2, 3.0, 5.6], "bulle_y": 0.9, "cris": ["groin", "grouik"], "bateau": Vector3(0, 0.2, -1.3),
		"couche_apres": 14.0, "taille_m": 0.75, "hauteur_rayon": 0.3},
}

## Les matériaux de chaque île (Biscotte) : [variable de main.gd, objets].
const ILES := [
	["boucan_v75", ["boulon", "ressort", "bombe_peinture"]],
	["montjoie_v71", ["navet_dore", "buche", "croc_gobelin"]],
	["braise_v70", ["cristal_soufre", "obsidienne"]],
	["soleils_v69", ["plume_ara", "os_jaguar"]],
	["pirates_v68", ["dent_croco", "vieille_botte", "corail_rouge"]],
	["arcanelle_v67", ["caillou", "baton"]],
	["astrale_v76", ["cristal_astral", "fragment_meteorite"]],
	["astralys_v76", ["cristal_astral", "fragment_meteorite"]],
	["azur_v56", ["coquillage", "etoile_mer"]],
	["grande_v59", ["minerai_fer", "engrenage", "boulon"]],
]
const GEMMES := ["perle", "rubis", "eclat_cristal", "bague", "piece_or"]
const ENFOUIS := ["bague", "piece_or", "perle", "vieille_botte", "rubis", "piece"]
const DEFAUT_ILE := ["coquillage", "caillou", "baton"]

const FALLBACK := {
	"sardine": {
		"babil": ["Tu es mon humain préféré. Enfin, après Tornade. Et après le vendeur de saucisses.", "On court ? On court ! ON COURT !",
			"Ce robot sent le boulon. Je peux le mordre ? Dis oui.", "J'ai trouvé un bâton. Il est à toi. Non, à moi. Non, à toi.",
			"Je garde. Je garde tout. Même toi.", "Les champignards, ça me fait éternuer. Atchii !"],
		"rapporte": ["Sardine revient en trottinant, une pièce dans la gueule, très fier de lui.", "Sardine a déterré quelque chose… Une pièce ! Il la dépose à tes pieds.",
			"Sardine pose une pièce un peu baveuse à tes pieds et attend des compliments."],
		"aboie_robot": ["Sardine aboie de toutes ses forces : un robot ! Il fonce lui mordre les chevilles en fer."],
		"content": ["Sardine s'allonge contre ta jambe et pousse un grand soupir de chien heureux."],
		"adoption": ["Sardine fait trois fois le tour de toi en remuant tout le derrière. C'est décidé : il est à toi, et toi à lui."],
		"appel": ["Fuiii-iii ! Sardine arrive au grand galop, les oreilles au vent (enfin, une seule).", "Sardine déboule en dérapant et te lèche la main. Mission : te suivre."],
		"maison": ["Sardine rentre à la maison en trottinant. Il se retourne deux fois pour vérifier que tu ne changes pas d'avis."],
		"bateau": ["Sardine saute dans la barque et se poste à la proue, le nez au vent, comme un vrai loup de mer."],
		"dort": ["…des saucisses…", "…je cours… je cours…"],
	},
	"brioche": {
		"babil": ["Je ne te suis pas. Je vais dans la même direction que toi. Nuance.", "Tu peux me caresser. Une fois. Pas deux.",
			"Le soleil, là-bas. Il est pour moi. Pousse-toi.", "Je ronronne, mais c'est pour moi, pas pour toi.",
			"J'ai un sixième sens pour les trésors. Le septième, c'est pour le poisson.", "Si je cligne des yeux lentement, ça veut dire que je t'aime. Ne t'y habitue pas."],
		"flair": ["Brioche s'arrête net, les oreilles dressées, et fixe le {dir}. « Miaou. » Il y a {quoi} caché par là, {dist}.",
			"Brioche se fige, la queue en point d'interrogation, le nez tourné vers le {dir}. Elle miaule : {quoi}, {dist} !",
			"Brioche s'assoit très droite et regarde fixement vers le {dir}. Quand une chatte regarde comme ça, c'est qu'il y a {quoi}… {dist}."],
		"papillon": ["Brioche bondit sur un papillon… et le rate. Elle fait sa toilette comme si de rien n'était. C'était voulu.",
			"Le papillon s'envole. Brioche le regarde partir, très digne : « Je le laissais filer. »"],
		"adoption": ["Brioche se frotte contre tes jambes, ronronne un grand coup, puis fait semblant de ne pas te connaître. C'est sa façon de dire oui."],
		"appel": ["Brioche arrive… quand elle a décidé d'arriver. La queue bien droite.", "Fuiii ! Brioche apparaît sur un muret, s'étire longuement, et vient te rejoindre sans se presser."],
		"maison": ["Brioche rentre à la maison sans se retourner. Elle reviendra. Si elle veut."],
		"bateau": ["Brioche monte dans la barque du bout des pattes. De l'eau partout ! Elle s'assoit à l'avant, très offensée."],
		"dort": ["…ron… ron…", "…poisson…"],
	},
	"biscotte": {
		"babil": ["Ta épaule, c'est le meilleur poste de vigie de l'archipel !", "J'ai été rat de cale, rat de quai, maintenant je suis rat d'épaule.",
			"Tu as du fromage ? Même un petit bout ? Même une odeur de fromage ?", "Accroche-toi, j'ai le pied marin. Enfin, les quatre.",
			"Si tu entends couiner dans ton oreille, c'est moi qui te dis bonjour.", "Je connais tous les trous de l'île. Tous. Même les petits."],
		"tresor": ["Biscotte file dans un trou… et revient avec {objet} entre les dents ! Il te le tend, la moustache frémissante.",
			"Petites pattes, grandes trouvailles : Biscotte te rapporte {objet}.", "Biscotte ressort d'un trou, tout poussiéreux, avec {objet}. Il est très fier."],
		"adoption": ["Biscotte grimpe le long de ton bras et s'installe sur ton épaule, la queue autour de ton cou. Il est chez lui."],
		"appel": ["Couic ! Biscotte surgit de nulle part et grimpe sur ton épaule.", "Biscotte arrive en trottinant et te tire sur le lacet : « On y va ? »"],
		"maison": ["Biscotte saute de ton épaule et file vers la maison en zigzaguant."],
		"bateau": ["Biscotte se dresse sur ton épaule, renifle l'air salé : « Ah, l'odeur de la cale ! »"],
		"dort": ["…fromage…", "…couic…"],
	},
	"truffe": {
		"babil": ["Ça sent bon par ici. Ça sent bon partout, en fait.", "Je ne suis pas gros. Je suis rempli d'amour. Et de pommes.",
			"Une flaque de boue ! Non ? Pas maintenant ? D'accord…", "Mon groin a un super-pouvoir : il trouve à manger.",
			"Grouik ! Ça veut dire « je suis content ». Grouik grouik, ça veut dire « très ».", "Tu as vu ma queue ? Elle fait des tire-bouchons quand je suis heureux."],
		"truffe": ["Truffe renifle, renifle… et creuse comme un fou ! Il te rapporte une truffe noire qui sent la forêt.",
			"Grouik ! Truffe a déterré une truffe ! Il la pose à tes pieds, le groin plein de terre.", "Truffe a le groin d'or : une truffe toute fraîche pour toi !"],
		"objet": ["Truffe creuse, creuse… et déterre {objet} ! Quelqu'un l'avait enterré là il y a longtemps.",
			"Le groin de Truffe a trouvé mieux qu'une truffe : {objet} !"],
		"adoption": ["Truffe frétille de la queue au groin, fait un petit saut de joie et colle son nez contre ta main. Grouik !"],
		"appel": ["Grouik grouik ! Truffe arrive au petit trot, les oreilles qui ballottent.", "Truffe accourt en couinant de joie, la queue en tire-bouchon."],
		"maison": ["Truffe rentre à la maison en grognant doucement. Il y a sûrement des pommes là-bas."],
		"bateau": ["Truffe monte dans la barque (elle tangue un peu) et s'assoit à l'avant, le groin au vent."],
		"dort": ["…ronf… ronf…", "…pommes…"],
	},
	"menu": {
		"question": "Tu souffles dans le sifflet : fuiii-iii ! Qui vient avec moi ?",
		"personne": "Personne : rentrez à la maison",
		"ranger": "(Ranger le sifflet)",
		"deja": "— déjà avec toi",
		"aucun": "Tu souffles dans le sifflet : fuiii-iii ! … Personne ne vient. Tu n'as pas encore de compagnon.",
		"sac_plein": "Ton sac est plein : le sifflet des compagnons t'attend. Fais un peu de place !",
		"sifflet": "Tu reçois le Sifflet des compagnons ! Utilise-le pour choisir qui vient avec toi.",
		"seul": "Tu siffles doucement… Tout le monde est rentré à la maison. Tu fais un bout de chemin seul.",
		"deja_la": "Tu siffles. {nom} te regarde comme pour dire : « Mais je suis déjà là. »",
	},
}

var main: Node
var pets: Dictionary = {}                 # id -> compagnon_v76 (créés au setup)
var adopted: Dictionary = {}              # id -> true
var active: String = ""
var babil: bool = false
var flair_seen: Dictionary = {}           # clé du trésor -> true (Brioche le signale une fois)
var flair_notes: Array = []               # [{pos, texte}] : les derniers trésors flairés (pour le carnet)
var stats: Dictionary = {"pieces": 0, "tresors": 0, "truffes": 0, "objets": 0, "flairs": 0}
var _whistle_pending: bool = false
var _boat_was: bool = false
var _hooked_v75: bool = false
var _hook_t: float = 0.0
var _v75: Dictionary = {}                 # la sauvegarde V75 de Sardine (boucan « sardine »)
var _v75_frame: int = -100
var _v76_frame: int = -100
var _v76_data: bool = false
var _spk: Node3D
var _textes: Dictionary = {}
var _textes_ok: bool = false
var _sifflet: Dictionary = {}             # astralys_textes_v76.SIFFLET (titre, choix, maison, vient, aucun, seul, personne)
## Les clés des textes V76 (astralys_textes_v76) qui correspondent aux nôtres.
const ALIAS := {"adoption": ["adoption", "adopte"], "flair": ["flair", "trouve"], "tresor": ["tresor", "trouve"],
	"truffe": ["truffe", "trouve"], "objet": ["objet", "trouve_objet"]}
var _rng := RandomNumberGenerator.new()


func setup(main_node: Node) -> void:
	main = main_node
	name = "Compagnons_animaux_v76"
	_rng.randomize()
	for pid in ORDER:
		var p: Node3D = PetScript.new()
		main.add_child(p)
		p.setup(self, main, pid, PETS[pid])
		pets[pid] = p
	_hook_boucan()
	print("ILE_MANGA_V76: compagnons animaux prêts (", pets.size(), ")")


func pet(id: String) -> Node3D:
	return pets.get(id)


func is_adopted(id: String) -> bool:
	return adopted.has(id)


func adopted_list() -> Array:
	var out: Array = []
	for pid in ORDER:
		if adopted.has(pid):
			out.append(pid)
	return out


func active_id() -> String:
	return active


## Rend le compagnon disponible (fin de sa quête), l'appelle, joue la ritournelle, donne le sifflet.
func adopt(id: String, quiet: bool = false) -> bool:
	if not pets.has(id):
		return false
	var first: bool = not adopted.has(id)
	adopted[id] = true
	_switch_to(id, false)
	if main != null and main.has_method("jingle") and first:
		main.jingle("compagnons")
	if not quiet and first:
		_message(line(id, "adoption"))
	_give_whistle()
	return first


## Un seul compagnon suit à la fois : l'ancien rentre « à la maison ».
func call_pet(id: String) -> bool:
	if not adopted.has(id) or not pets.has(id):
		return false
	if active == id:
		var p: Node3D = pets[id]
		if not p.visible or p.global_position.distance_to(p._player_feet()) > 8.0:
			p.teleport_near_player()
		p._happy_t = 2.0
		p._cry(false)
		_message(_menu_text("deja_la").replace("{nom}", str(PETS[id]["nom"])))
		return true
	_switch_to(id, true)
	_message(line(id, "appel"))
	return true


## Tout le monde rentre à la maison.
func dismiss(quiet: bool = false) -> void:
	if active == "":
		return
	var old: String = active
	active = ""
	(pets[old] as Node3D)._deactivate(true)
	if not quiet:
		_message(line(old, "maison"))


func _switch_to(id: String, _announce: bool) -> void:
	if active != "" and active != id and pets.has(active):
		(pets[active] as Node3D)._deactivate(true)
	active = id
	var p: Node3D = pets[id]
	p._set_babil(babil)
	p._activate(true)
	if boat_driving():
		p.on_board_boat()
	_boat_was = boat_driving()


## Sardine (V75) : trouvé à la Casse, ou ramené à Tornade.
func _compat_spawn(id: String) -> void:
	if not adopted.has(id):
		adopt(id, true)
	elif active == "":
		_switch_to(id, true)
	elif active == id:
		var p: Node3D = pets[id]
		if not p.visible:
			p._activate(true)
	# un autre compagnon suit déjà le joueur : Sardine attend à la maison (le sifflet l'appelle)


func set_babil(on: bool) -> void:
	babil = on
	for pid in pets:
		(pets[pid] as Node3D)._set_babil(on)


func on_faint() -> void:
	if active != "" and pets.has(active):
		(pets[active] as Node3D)._pet_faint()


func boat_driving() -> bool:
	var b: Node = main.get("boat_v29") if main != null else null
	return b != null and bool(b.get("driving"))


func on_board_boat() -> void:
	_boat_was = true
	if active != "" and pets.has(active):
		(pets[active] as Node3D).on_board_boat()
		if _rng.randf() < 0.5:
			_message(line(active, "bateau"))


func on_leave_boat() -> void:
	_boat_was = false
	if active != "" and pets.has(active):
		(pets[active] as Node3D).on_leave_boat()


## Pour les autres moyens de voler (V76 : l'aéronef) : le compagnon attend au sol.
func player_flying() -> bool:
	for nm in ["aeronef_v76", "aile_v76", "ailes_v76"]:
		var n: Node = main.get(nm)
		if n != null:
			for prop in ["flying", "riding", "driving"]:
				if n.get(prop) == true:
					return true
	return false


func _process(delta: float) -> void:
	if main == null:
		return
	# le bateau : il monte dedans, il en descend
	var bd: bool = boat_driving()
	if bd != _boat_was:
		if bd:
			on_board_boat()
		else:
			on_leave_boat()
	# Sardine de la V75 : boucan_v75 a créé son propre chien (chien_v75) : on prend sa place
	if not _hooked_v75:
		_hook_t -= delta
		if _hook_t <= 0.0:
			_hook_t = 0.5
			_hook_boucan()
	if _whistle_pending:
		if Engine.get_process_frames() % 120 == 0:
			_give_whistle()


func _hook_boucan() -> void:
	var bo: Node = main.get("boucan_v75") if main != null else null
	if bo == null:
		return
	var old: Variant = bo.get("chien")
	if old == pets.get("sardine"):
		_hooked_v75 = true
		return
	if old == null or not is_instance_valid(old):
		# pas encore créé (la ville se construit plus tard) : on patiente ; s'il n'y a pas de chien
		# du tout (boucan_v75 déjà modifié pour nous), on se branche directement
		if bo.get("city") != null:
			bo.set("chien", pets["sardine"])
			_hooked_v75 = true
		return
	if (old as Object).get_script() == PetScript:
		_hooked_v75 = true                # déjà un compagnon V76 (un autre gestionnaire, un essai)
		return
	# le chien V75 a peut-être déjà reçu la sauvegarde : on la reprend
	var d: Dictionary = {}
	if (old as Object).has_method("serialize"):
		d = old.serialize()
	(old as Node).queue_free()
	bo.set("chien", pets["sardine"])
	_hooked_v75 = true
	if bool(d.get("actif", false)):
		_compat_load_v75("sardine", d)


# =================================================================== le sifflet

func _give_whistle() -> void:
	var inv: Node = main.get("inventory_v28")
	if inv == null:
		return
	if int(inv.count(SIFFLET)) > 0:
		_whistle_pending = false
		return
	if int(inv.add(SIFFLET, 1)) > 0:
		_whistle_pending = false
		_message(_menu_text("sifflet"))
		if main.has_method("sfx"):
			main.sfx(SIFFLET)
	else:
		if not _whistle_pending:
			_message(_menu_text("sac_plein"))
		_whistle_pending = true


## « Utiliser » le sifflet (inventory_v28.use_tool) : vrai si l'objet est le sifflet.
func use_whistle(item_id: String = SIFFLET) -> bool:
	if item_id != SIFFLET:
		return false
	var inv: Node = main.get("inventory_v28")
	if inv != null and bool(inv.get("opened")):
		inv.close()
	open_menu()
	return true


## Le menu « Qui vient avec moi ? » (main.ask_v69).
func open_menu() -> void:
	if main.has_method("sfx"):
		main.sfx(SIFFLET)
	var list: Array = adopted_list()
	if list.is_empty():
		_message(_menu_text("aucun"))
		return
	var choices: Array = []
	for pid in list:
		var sp: Dictionary = PETS[pid]
		var lab: String = "✦ %s, %s" % [sp["nom"], sp["article"]]
		_texts()
		if _sifflet.get("choix") is String:
			lab = "✦ " + str(_sifflet["choix"]).replace("{nom}", "%s (%s)" % [sp["nom"], sp["article"]])
		if pid == active:
			lab += " " + _menu_text("deja")
		choices.append({"id": "pet76:" + pid, "label": lab})
	choices.append({"id": "pet76:maison", "label": _menu_text("personne")})
	choices.append({"id": "fermer", "label": _menu_text("ranger")})
	if not main.has_method("ask_v69"):
		return
	main.ask_v69(_speaker(), "Le sifflet des compagnons", "", _menu_text("question"), choices, Callable(self, "_menu_pick"))


func _menu_pick(choice: String) -> void:
	if main.has_method("_close_dialogue_v31"):
		main._close_dialogue_v31()
	var pid: String = choice.trim_prefix("pet76:")
	if pid == "maison":
		if active == "":
			_message(_menu_text("seul"))
		dismiss()
		return
	call_pet(pid)


func _speaker() -> Node3D:
	if _spk == null:
		_spk = Node3D.new()
		_spk.name = "Sifflet_v76"
		main.add_child(_spk)
	var p: Node3D = pets.get(active) if active != "" else null
	if p != null and p.visible:
		_spk.global_position = p.global_position + Vector3.UP * 0.4
	elif main.has_method("_player_pos_v27"):
		_spk.global_position = main._player_pos_v27()
	return _spk


# =================================================================== les trouvailles

## Le compagnon pose sa trouvaille aux pieds du joueur : pièces (Sardine), petit trésor (Biscotte),
## truffe ou objet enfoui (Truffe).
func give_find(p: Node3D, kind: String) -> void:
	var inv: Node = main.get("inventory_v28")
	var item: String = "piece"
	var n: int = 1
	var key: String = ""
	match kind:
		"rapporte":
			n = _rng.randi_range(1, 3)
			key = "rapporte"
		"tresor":
			var r: float = _rng.randf()
			if r < 0.55:
				item = "piece"
				n = _rng.randi_range(3, 12)
			elif r < 0.75:
				item = _pick_existing(GEMMES, "perle")
			else:
				item = _pick_existing(island_items(p.global_position), "coquillage")
			key = "tresor"
		"truffe":
			if _rng.randf() < 0.18:
				item = _pick_existing(ENFOUIS, "piece")
				n = 3 if item == "piece" else 1
				key = "objet"
			else:
				item = "truffe"
				key = "truffe"
	var got: int = n
	if inv != null:
		got = int(inv.add(item, n))
	if got <= 0:
		# le sac est plein : il le pose par terre
		if inv != null and inv.has_method("spawn_pickup"):
			inv.drop_counter = int(inv.get("drop_counter")) + 1
			inv.spawn_pickup("compagnon76_%d" % int(inv.drop_counter), item, n, p.global_position + Vector3.UP * 0.05)
	match kind:
		"rapporte":
			stats["pieces"] = int(stats["pieces"]) + n
			p.coins_given += n
		"tresor":
			stats["tresors"] = int(stats["tresors"]) + 1
			p.found_n += 1
		"truffe":
			if item == "truffe":
				stats["truffes"] = int(stats["truffes"]) + 1
			else:
				stats["objets"] = int(stats["objets"]) + 1
			p.found_n += 1
	var t: String = line(str(p.id), key)
	t = t.replace("{objet}", _art(item, n)).replace("{n}", str(n))
	_message(t)
	var cb: Node = main.get("combat_v28")
	if cb != null:
		cb.float_text(p._player_feet() + Vector3.UP * 1.8, "+%d %s" % [n, _item_name(item)], Color(1.0, 0.9, 0.5))
	if main.has_method("sfx"):
		main.sfx("ramasse_pieces" if item.begins_with("piece") else "ramasse", p.global_position + Vector3.UP * 0.4)
	p._cry(false)


func _pick_existing(list: Array, fallback: String) -> String:
	var ok: Array = []
	var items: Dictionary = _items()
	for it in list:
		if items.is_empty() or items.has(it):
			ok.append(it)
	if ok.is_empty():
		return fallback
	return str(ok[_rng.randi() % ok.size()])


func _items() -> Dictionary:
	var inv: Node = main.get("inventory_v28")
	if inv == null:
		return {}
	var v: Variant = inv.get("ITEMS")
	if v is Dictionary:
		return v
	var scr: Script = inv.get_script()
	if scr != null:
		var c: Dictionary = scr.get_script_constant_map()
		if c.get("ITEMS") is Dictionary:
			return c["ITEMS"]
	return {}


func _item_name(id: String) -> String:
	var info: Variant = _items().get(id)
	if info is Dictionary:
		return str((info as Dictionary).get("name", id))
	return id


func _art(id: String, n: int) -> String:
	if id == "piece":
		return "%d pièce%s" % [n, "s" if n > 1 else ""]
	var info: Variant = _items().get(id)
	if info is Dictionary:
		return str((info as Dictionary).get("art", (info as Dictionary).get("name", id)))
	return id


## Les matériaux de l'île où l'on est.
func island_items(p: Vector3) -> Array:
	for e in ILES:
		var n: Node = main.get(str(e[0]))
		if n == null:
			continue
		var inside: bool = false
		if n.has_method("owns_point"):
			inside = bool(n.owns_point(p))
		elif n.has_method("contains"):
			inside = bool(n.contains(p))
		if inside:
			return e[1]
	return DEFAUT_ILE


# =================================================================== le flair de Brioche

## Le trésor caché non signalé le plus proche : {key, pos, quoi} ou {}.
func nearest_treasure(at: Vector3, radius: float) -> Dictionary:
	var best: Dictionary = {}
	var best_d: float = radius
	var ob: Node = main.get("objets_v66")
	if ob != null and ob.get("chests") is Array:
		var opened: Dictionary = ob.get("opened") if ob.get("opened") is Dictionary else {}
		for ch in ob.chests:
			var c: Dictionary = ch
			if opened.has(c.get("id", "")):
				continue
			var node: Node3D = c.get("node")
			if node == null or not is_instance_valid(node):
				continue
			var k: String = "coffre:" + str(c.get("id", ""))
			if flair_seen.has(k):
				continue
			var d: float = node.global_position.distance_to(at)
			if d < best_d and absf(node.global_position.y - at.y) < 12.0:
				best_d = d
				best = {"key": k, "pos": node.global_position, "quoi": "un coffre caché"}
	var dg: Node = main.get("digging_v33")
	if dg != null and dg.has_method("active_treasures"):
		var spots: Array = dg.get("treasure_spots") if dg.get("treasure_spots") is Array else []
		for i in dg.active_treasures():
			if int(i) < 0 or int(i) >= spots.size():
				continue
			var q: Vector3 = spots[int(i)]
			var k2: String = "creuse:%d_%d" % [int(round(q.x)), int(round(q.z))]
			if flair_seen.has(k2):
				continue
			var d2: float = q.distance_to(at)
			if d2 < best_d and absf(q.y - at.y) < 12.0:
				best_d = d2
				best = {"key": k2, "pos": q, "quoi": "une cachette à creuser"}
		var ms: Variant = dg.get("mouette_spot")
		if ms is Vector3 and (ms as Vector3) != Vector3.INF and not bool(dg.get("mouette_found")):
			var k3: String = "creuse:mouette"
			var d3: float = (ms as Vector3).distance_to(at)
			if not flair_seen.has(k3) and d3 < best_d:
				best_d = d3
				best = {"key": k3, "pos": ms, "quoi": "une cachette à creuser"}
	return best


func mark_flair(key: String) -> void:
	if key != "":
		flair_seen[key] = true
		stats["flairs"] = int(stats["flairs"]) + 1


func note_flair(at: Vector3, text: String) -> void:
	flair_notes.append({"pos": at, "texte": text})
	while flair_notes.size() > 8:
		flair_notes.pop_front()


# =================================================================== les animaux de la ville

## Un animal de la faune (V75) près de « at » : {esp, pos} ou {}.
func nearby_animal(at: Vector3, r: float, _self_esp: String) -> Dictionary:
	var bo: Node = main.get("boucan_v75")
	if bo == null or bo.get("faune") == null:
		return {}
	var fa: Node = bo.faune
	if not (fa.get("animals") is Array):
		return {}
	for a in fa.animals:
		var d: Dictionary = a
		var p: Vector3 = d.get("pos", Vector3.INF)
		if p == Vector3.INF:
			continue
		if p.distance_to(at) < r:
			return {"esp": str(d.get("esp", "")), "pos": p}
	return {}


## Au milieu des maisons ? (des murs tout autour) : le cochon ne creuse pas dans la rue.
func in_town(p: Vector3) -> bool:
	var pt: Node3D = pets.get("truffe")
	if pt == null or not pt.is_inside_tree():
		return false
	var space := pt.get_world_3d().direct_space_state
	var walls: int = 0
	for k in range(8):
		var a: float = TAU * float(k) / 8.0
		var from: Vector3 = p + Vector3.UP * 1.6
		var q := PhysicsRayQueryParameters3D.create(from, from + Vector3(cos(a), 0, sin(a)) * 9.0, 1, pt._excl)
		var hit := space.intersect_ray(q)
		if not hit.is_empty():
			var c: Object = hit.get("collider")
			if c is Node and not str((c as Node).name).begins_with("Sol_"):
				walls += 1
	return walls >= 3


# =================================================================== textes

func _texts() -> Dictionary:
	if _textes_ok:
		return _textes
	_textes_ok = true
	if ResourceLoader.exists(TEXTES_PATH):
		var scr: Script = load(TEXTES_PATH)
		if scr != null:
			var cm: Dictionary = scr.get_script_constant_map()
			var c: Variant = cm.get("COMPAGNONS")
			if c is Dictionary:
				_textes = (c as Dictionary).duplicate()
			if cm.get("SIFFLET") is Dictionary:
				_sifflet = cm["SIFFLET"]
	return _textes


static func _pick_from(v: Variant, rng: RandomNumberGenerator) -> String:
	if v is String:
		return v
	if v is Array and not (v as Array).is_empty():
		var e: Variant = (v as Array)[rng.randi() % (v as Array).size()]
		if e is Dictionary:
			return str((e as Dictionary).get("texte", (e as Dictionary).get("text", "")))
		if e is Array and not (e as Array).is_empty():
			return str((e as Array)[(e as Array).size() - 1])
		return str(e)
	return ""


## Une réplique : COMPAGNONS[id][clé] (astralys_textes_v76), sinon les lignes V75 de Sardine
## (boucan_textes_v75), sinon les lignes de secours d'ici.
func line(id: String, key: String) -> String:
	var t: Dictionary = _texts()
	var s: String = ""
	for k in ALIAS.get(key, [key]):
		if s != "":
			break
		if t.get(id) is Dictionary:
			s = _pick_from((t[id] as Dictionary).get(k), _rng)
		elif t.get(id) is Array and k == "babil":
			s = _pick_from(t[id], _rng)
		if s == "":
			s = _pick_from(t.get(id + "_" + k), _rng)
	# l'appel et le retour à la maison : le Sifflet (« {nom} »)
	if s == "" and key in ["appel", "maison"] and not _sifflet.is_empty():
		s = _pick_from(_sifflet.get("vient" if key == "appel" else "maison"), _rng).replace("{nom}", str(PETS.get(id, {}).get("nom", id)))
	if s == "" and id == "sardine":
		s = _v75_line(key)
	if s == "" and FALLBACK.get(id) is Dictionary:
		s = _pick_from((FALLBACK[id] as Dictionary).get(key), _rng)
	return s


func _v75_line(key: String) -> String:
	if not ResourceLoader.exists(TEXTES_V75):
		return ""
	var scr: Script = load(TEXTES_V75)
	if scr == null:
		return ""
	var c: Dictionary = scr.get_script_constant_map()
	var src: Variant = c.get("ANIMAUX", {}) if key == "babil" else c.get("SARDINE", {})
	var k: String = "sardine" if key == "babil" else key
	if src is Dictionary and (src as Dictionary).has(k):
		return _pick_from((src as Dictionary)[k], _rng)
	return ""


## Les textes du sifflet : astralys_textes_v76.SIFFLET (titre → question, aucun, seul : déjà là,
## personne : tout le monde à la maison), sinon COMPAGNONS["menu"], sinon les lignes d'ici.
const MENU_ALIAS := {"question": "titre", "aucun": "aucun", "seul": "personne", "deja_la": "seul"}

func _menu_text(key: String) -> String:
	var t: Dictionary = _texts()
	if t.get("menu") is Dictionary and (t["menu"] as Dictionary).has(key):
		var s: String = _pick_from((t["menu"] as Dictionary)[key], _rng)
		if s != "":
			return s
	if MENU_ALIAS.has(key) and _sifflet.has(MENU_ALIAS[key]):
		var s2: String = _pick_from(_sifflet[MENU_ALIAS[key]], _rng)
		if s2 != "":
			return ("Fuiii-iii ! " + s2) if key == "question" else s2
	return str((FALLBACK["menu"] as Dictionary).get(key, ""))


func _message(t: String) -> void:
	if t != "" and main != null and main.has_method("_show_message_v28"):
		main._show_message_v28(t)


# =================================================================== sauvegarde, carnet

func serialize() -> Dictionary:
	var ps: Dictionary = {}
	for pid in pets:
		ps[pid] = (pets[pid] as Node3D)._save()
	return {"v": 76, "adoptes": adopted_list(), "actif": active, "flair": flair_seen.keys(), "stats": stats.duplicate(), "compagnons": ps}


func load_data(d: Dictionary) -> void:
	_v76_frame = Engine.get_process_frames()
	for pid in pets:
		(pets[pid] as Node3D)._deactivate(false)
	adopted.clear()
	active = ""
	flair_seen.clear()
	flair_notes.clear()
	stats = {"pieces": 0, "tresors": 0, "truffes": 0, "objets": 0, "flairs": 0}
	_whistle_pending = false
	_boat_was = false
	if d.has("adoptes"):
		for pid in d.get("adoptes", []):
			if pets.has(str(pid)):
				adopted[str(pid)] = true
		for k in d.get("flair", []):
			flair_seen[str(k)] = true
		var st: Variant = d.get("stats", {})
		if st is Dictionary:
			for k2 in stats:
				stats[k2] = int((st as Dictionary).get(k2, 0))
		var ps: Variant = d.get("compagnons", {})
		if ps is Dictionary:
			for pid2 in pets:
				var pd: Variant = (ps as Dictionary).get(pid2, {})
				(pets[pid2] as Node3D)._restore(pd if pd is Dictionary else {})
		var a: String = str(d.get("actif", ""))
		if adopted.has(a):
			active = a
			(pets[a] as Node3D)._set_babil(babil)
			(pets[a] as Node3D)._activate(false, true)
	_v76_data = d.has("adoptes")
	# une partie V75 : Sardine était là (la clé « sardine » de boucan), rien encore pour la V76
	_merge_v75()


## boucan_v75.load_data → Sardine.load_data(d) (format V75 {actif, pieces, prochaine_piece}).
func _compat_load_v75(id: String, d: Dictionary) -> void:
	if id != "sardine":
		return
	_v75 = d.duplicate()
	_v75_frame = Engine.get_process_frames()
	_merge_v75()


## La sauvegarde V76 fait foi ; la clé V75 ne compte que pour une partie qui n'a pas encore de
## données V76 (chargées dans la même image : main.gd charge tout d'un coup).
func _merge_v75() -> void:
	if _v75.is_empty() or not bool(_v75.get("actif", false)):
		return
	if absi(_v75_frame - Engine.get_process_frames()) > 2:
		return
	if _v76_data and absi(_v76_frame - _v75_frame) <= 2:
		return
	var sd: Node3D = pets["sardine"]
	if not adopted.has("sardine"):
		# Sardine suivait le joueur en V75 : il est adopté (sans fanfare, sans sifflet : un seul compagnon)
		adopted["sardine"] = true
		sd._restore({"pieces": _v75.get("pieces", 0), "t": _v75.get("prochaine_piece", 200.0)})
		stats["pieces"] = maxi(int(stats["pieces"]), int(_v75.get("pieces", 0)))
	if active == "":
		active = "sardine"
		sd._set_babil(babil)
		sd._activate(false, true)


## Les « trouvailles » du carnet (clés d'état) : brioche_adoptee, biscotte_adoptee, truffe_adoptee,
## sardine_trouvee (seulement s'il est adopté : la V75 a la même clé), compagnons_4.
func trouvailles() -> Dictionary:
	var t := {"brioche_adoptee": 1 if adopted.has("brioche") else 0, "biscotte_adoptee": 1 if adopted.has("biscotte") else 0,
		"truffe_adoptee": 1 if adopted.has("truffe") else 0, "compagnons_4": 1 if adopted.size() >= 4 else 0}
	if adopted.has("sardine"):
		t["sardine_trouvee"] = 1
	return t
