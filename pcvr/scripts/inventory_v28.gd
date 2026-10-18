extends Node3D
## V28 : inventaire (24 cases + arme en main), objets à ramasser dans l'île, sauvegarde.
## Pensé pour grandir : chaque objet est décrit dans ITEMS (catégorie, pile max, effets) ;
## il suffit d'ajouter une ligne pour un nouvel objet (artisanat, quêtes, marchands…).
## PC : I ou Tab ouvre la fenêtre, clic sur une case pour voir l'objet, puis Utiliser /
## Équiper / Jeter. VR : bouton Y, stick droit pour choisir, gâchette pour utiliser.

signal changed
signal equipped_changed(item_id: String)
signal notify(text: String)

const SLOT_COUNT: int = 24
const PICK_RADIUS: float = 1.7

## kind : nourriture, materiau, tresor, arme. heal en demi-cœurs, damage en points.
const ITEMS := {
	"pomme": {"name": "Pomme", "art": "une pomme", "kind": "nourriture", "max": 20, "heal": 2,
		"desc": "Une pomme bien rouge tombée d'un arbre. Rend un cœur."},
	"champignon": {"name": "Champignon des bois", "art": "un champignon", "kind": "nourriture", "max": 20, "heal": 1,
		"desc": "Il pousse à l'ombre des grands arbres. Rend un demi-cœur."},
	"baies": {"name": "Baies sauvages", "art": "des baies", "kind": "nourriture", "max": 30, "heal": 1,
		"desc": "Petites baies sucrées des buissons. Rend un demi-cœur."},
	"baton": {"name": "Bâton", "art": "un bâton", "kind": "materiau", "max": 30,
		"desc": "Une branche solide. Servira à fabriquer des outils."},
	"caillou": {"name": "Caillou", "art": "un caillou", "kind": "materiau", "max": 30,
		"desc": "Un caillou lisse. Servira à fabriquer des outils."},
	"coquillage": {"name": "Coquillage nacré", "art": "un coquillage nacré", "kind": "tresor", "max": 50,
		"desc": "Il brille au soleil. Un marchand en voudra peut-être."},
	"piece": {"name": "Pièce de cuivre", "art": "une pièce", "kind": "tresor", "max": 999,
		"desc": "La monnaie de l'île."},
	"epee_bois": {"name": "Épée en bois", "art": "une épée en bois", "kind": "arme", "max": 1, "damage": 3,
		"desc": "Une épée d'entraînement taillée à la forge. Dégâts : 3."},
	# V32 : pêche
	"canne_peche": {"name": "Canne à pêche", "art": "une canne à pêche", "kind": "canne", "max": 1,
		"desc": "La vieille canne de Barnabé. Équipe-la, approche-toi de l'eau et maintiens le clic pour lancer."},
	"sardine": {"name": "Sardine", "art": "une sardine", "kind": "nourriture", "max": 30, "heal": 1,
		"desc": "Petit poisson argenté des côtes. Rend un demi-cœur."},
	"maquereau": {"name": "Maquereau", "art": "un maquereau", "kind": "nourriture", "max": 20, "heal": 2,
		"desc": "Rayé de bleu, vif et nerveux. Rend un cœur."},
	"dorade": {"name": "Dorade", "art": "une dorade", "kind": "nourriture", "max": 20, "heal": 3,
		"desc": "Le bandeau doré entre les yeux ne trompe pas. Rend un cœur et demi."},
	"bar": {"name": "Bar", "art": "un bar", "kind": "nourriture", "max": 20, "heal": 3,
		"desc": "Un poisson noble qui se défend bien. Rend un cœur et demi."},
	"poisson_perroquet": {"name": "Poisson-perroquet", "art": "un poisson-perroquet", "kind": "nourriture", "max": 10, "heal": 4,
		"desc": "Couleurs de Gaston, en poisson. On ne le trouve que dans la baie de la jungle. Rend deux cœurs."},
	"merou": {"name": "Mérou", "art": "un mérou", "kind": "nourriture", "max": 10, "heal": 6,
		"desc": "Un colosse des eaux profondes, au bout des pontons. Rend trois cœurs."},
	"poisson_lune": {"name": "Poisson-lune doré", "art": "un poisson-lune doré", "kind": "tresor", "max": 5,
		"desc": "Légendaire. Barnabé dit qu'il n'en existe qu'un. Il se trompait."},
	"vieille_botte": {"name": "Vieille botte", "art": "une vieille botte", "kind": "materiau", "max": 10,
		"desc": "Gorgée d'eau, avec une algue en prime. Quelqu'un, quelque part, a froid au pied."},
	# V33 : chez Octave Taillefer (cabane dans l'arbre, côté est de la jungle)
	"pelle": {"name": "Pelle", "art": "une pelle", "kind": "outil", "equip": true, "max": 1, "damage": 2,
		"desc": "Fer forgé par Octave. En main, clic (gâchette en VR) pour creuser le sable ou la terre : coquillages, pièces… et parfois un trésor."},
	"hache": {"name": "Hache", "art": "une hache", "kind": "arme", "max": 1, "damage": 5,
		"desc": "Lourde et bien équilibrée. Elle abat les jeunes arbres (une entaille claire sur le tronc) et les cocotiers : bûches, noix de coco, miel… Dégâts : 5."},
	"epee": {"name": "Épée d'acier", "art": "une épée d'acier", "kind": "arme", "max": 1, "damage": 6,
		"desc": "Le chef-d'œuvre d'Octave : acier trempé, garde en laiton. Dégâts : 6, et le troisième coup d'un enchaînement frappe moitié plus fort. Prête pour les combats à venir."},
	# V34 : le bois (hache) et les petits trésors (pelle)
	"buche": {"name": "Bûche", "art": "une bûche", "kind": "materiau", "max": 30,
		"desc": "Du bon bois, coupé à la hache. Octave en rachète pour sa forge."},
	"noix_coco": {"name": "Noix de coco", "art": "une noix de coco", "kind": "nourriture", "max": 20, "heal": 2,
		"desc": "Tombée d'un cocotier abattu. Son lait rend un cœur."},
	"miel": {"name": "Miel sauvage", "art": "du miel", "kind": "nourriture", "max": 10, "heal": 4,
		"desc": "Un rayon de miel trouvé dans un arbre creux. Rend deux cœurs."},
	"perle": {"name": "Perle", "art": "une perle", "kind": "tresor", "max": 50,
		"desc": "Une perle bien ronde, sortie d'un trésor enfoui. Octave la rachète 10 pièces."},
	"bague": {"name": "Bague d'argent", "art": "une bague", "kind": "tresor", "max": 20,
		"desc": "Une bague de marin, avec une pierre bleue. Octave la rachète 18 pièces."},
	"rubis": {"name": "Rubis", "art": "un rubis", "kind": "tresor", "max": 20,
		"desc": "Une pierre rouge qui brille comme une braise. Octave la rachète 30 pièces."},
	"piece_or": {"name": "Pièce d'or", "art": "une pièce d'or", "kind": "tresor", "max": 99,
		"desc": "Une vieille pièce d'or frappée d'une couronne. Octave en donne 12 pièces de cuivre."},
	# V35 : le Temple englouti
	"fragment_amulette": {"name": "Fragment d'amulette", "art": "un fragment d'amulette", "kind": "quete", "max": 3,
		"desc": "Un morceau d'amulette en jade, gravé d'un symbole ancien. Il en faut trois pour ouvrir la Porte du Serpent, au fond du Temple englouti."},
	# V38
	"amulette_serpent": {"name": "Amulette du Serpent", "art": "l'Amulette du Serpent", "kind": "quete", "max": 1,
		"desc": "Les trois fragments de jade, soudés autour d'un œil vert. Sous terre, elle éclaire les ténèbres autour de toi. Elle vibre près du sceau des Abysses."},
	# V41 : la quête de Lyra et l'île des elfes
	"fiole_vide": {"name": "Fiole de cristal", "art": "une fiole de cristal", "kind": "quete", "max": 1,
		"desc": "Une fiole elfique, fine comme une bulle. Lyra te l'a confiée pour y puiser l'eau de la source, au bassin de la grande chute (nord-est de l'île du village)."},
	"eau_source": {"name": "Eau de la source", "art": "l'eau de la source", "kind": "quete", "max": 1,
		"desc": "L'eau du bassin de la grande chute, dans la fiole de cristal. Elle scintille un peu, comme si elle gardait des étoiles."},
	"fleur_lune": {"name": "Fleur de lune", "art": "une fleur de lune", "kind": "quete", "max": 3,
		"desc": "Une fleur blanche aux pétales lumineux, cueillie au sommet d'un piton de la jungle. Elle ne se fane pas."},
	"graine_or": {"name": "Graine d'or", "art": "une graine d'or", "kind": "quete", "max": 1,
		"desc": "Une graine dorée, lourde et tiède. Barnabé l'avait trouvée sur une plage il y a vingt ans. Elle vient de l'Arbre-Mère des elfes."},
	"boussole_elfique": {"name": "Boussole elfique", "art": "la boussole elfique", "kind": "outil", "max": 1,
		"desc": "Le cadeau de Lyra : son aiguille de cristal pointe vers l'Arbre-Mère, à l'est. Avec elle, le bateau traverse la brume du Bois-Doré."},
	# V42 : le marché du Bois-Doré
	"potion_seve": {"name": "Potion de sève", "art": "une potion de sève", "kind": "nourriture", "max": 10, "heal": 6,
		"desc": "La potion d'Aëlwen, l'herboriste du Bois-Doré : de la sève dorée et des herbes de lune. Rend trois cœurs."},
	"tisane_lune": {"name": "Tisane de lune", "art": "une tisane de lune", "kind": "nourriture", "max": 10, "heal": 3,
		"desc": "Une tisane parfumée aux fleurs de nuit, encore tiède. Rend un cœur et demi."},
	"pain_miel": {"name": "Pain de miel", "art": "un pain de miel", "kind": "nourriture", "max": 10, "heal": 4,
		"desc": "Le pain doré de Sylwen, la boulangère du Bois-Doré. Il sent le miel et le soleil. Rend deux cœurs."},
	# V43 : le Royaume des Racines
	"lanterne_fee": {"name": "Lanterne de fée", "art": "la lanterne de fée", "kind": "quete", "max": 1,
		"desc": "Une petite lanterne d'argent et de verre, confiée par Faelar. Les esprits-lucioles du Bois-Doré peuvent s'y abriter. Ramène-les à la porte de l'Arbre-Mère."},
	"poussiere_fee": {"name": "Poussière de fée", "art": "de la poussière de fée", "kind": "quete", "max": 10,
		"desc": "Une bourse de poussière qui scintille de toutes les couleurs, trouvée dans le coffre du Jardin des Fées. Lumi dit qu'il en faudra beaucoup pour passer les ronces."},
	# V44 : le Village des Fées
	"goutte_rosee": {"name": "Goutte de rosée de lune", "art": "une goutte de rosée de lune", "kind": "quete", "max": 10,
		"desc": "Une goutte de rosée qui ne s'évapore jamais et brille comme une petite lune. La fée Brindille en cherche cinq."},
	"baguette_fee": {"name": "Baguette de Pimprenelle", "art": "la baguette de Pimprenelle", "kind": "quete", "max": 1,
		"desc": "Une baguette de fée en bois de sureau, terminée par une étoile de cristal. Pimprenelle l'a perdue dans la Grotte des Champignons Sauteurs."},
	"eclat_cristal": {"name": "Éclat de cristal", "art": "un éclat de cristal", "kind": "tresor", "max": 30,
		"desc": "Un éclat rose et tiède, laissé par une araignée de cristal. Le lutin Grommelot en collectionne ; Mélisse en rachète."},
	"nectar_fee": {"name": "Nectar de fée", "art": "un nectar de fée", "kind": "nourriture", "max": 10, "heal": 8,
		"desc": "Le nectar doré de Mélisse, cueilli au cœur des fleurs géantes. Rend quatre cœurs."},
	# V46 : la carte de l'île des nains
	"carte_naine": {"name": "Carte des Récifs de Feu", "art": "la carte des Récifs de Feu", "kind": "quete", "max": 1,
		"desc": "Un vieux parchemin offert par Églantine, la Reine des Ronces délivrée. Il montre la passe à travers les récifs et les cendres, à l'ouest, jusqu'à l'île volcanique des nains."},
	# V47 : l'île des nains
	"minerai_fer": {"name": "Minerai de fer", "art": "du minerai de fer", "kind": "materiau", "max": 30,
		"desc": "Une pierre lourde veinée de rouille, ramassée sur les pentes du volcan. Borin le forgeron en fait de l'acier."},
	"obsidienne": {"name": "Éclat d'obsidienne", "art": "un éclat d'obsidienne", "kind": "materiau", "max": 30,
		"desc": "Du verre de volcan, noir et tranchant, qu'on trouve près du cratère. Nori le runiste y grave ses runes."},
	"champignon_braise": {"name": "Champignon de braise", "art": "un champignon de braise", "kind": "nourriture", "max": 20, "heal": 2,
		"desc": "Un champignon rouge et tiède qui pousse dans la cendre, près des fumerolles. Dagna en met dans son ragoût. Rend un cœur."},
	"plume_corbeau": {"name": "Plume de corbeau", "art": "une plume de corbeau", "kind": "materiau", "max": 30,
		"desc": "Une longue plume noire aux reflets bleus, perdue par un corbeau des cendres. Hilda en fait des flèches… et des chapeaux."},
	"coeur_magma": {"name": "Cœur de magma", "art": "un cœur de magma", "kind": "tresor", "max": 20,
		"desc": "Le noyau encore chaud d'un élémentaire de magma. Grimli le mineur s'en sert pour éclairer ses galeries."},
	"rune_golem": {"name": "Rune de golem", "art": "une rune de golem", "kind": "tresor", "max": 20,
		"desc": "La pierre gravée qui animait un golem des hauteurs. Bramm, le garde de la porte, en demande la preuve de ta valeur."},
	"epee_naine": {"name": "Épée naine", "art": "une épée naine", "kind": "arme", "max": 1, "damage": 9,
		"desc": "Forgée par Borin Barbe-de-Fer dans l'acier du volcan : lame courte et large, garde d'or, un rubis au pommeau. Dégâts : 9, et le troisième coup d'un enchaînement frappe moitié plus fort."},
	"ragout_nain": {"name": "Ragoût de Dagna", "art": "un ragoût de Dagna", "kind": "nourriture", "max": 10, "heal": 8,
		"desc": "Un bol fumant de ragoût aux champignons de braise. Ça brûle la langue et ça rend quatre cœurs."},
	"fromage_chevre": {"name": "Fromage de chèvre", "art": "un fromage de chèvre", "kind": "nourriture", "max": 10, "heal": 4,
		"desc": "Le fromage des chèvres des cendres de Hilda. Il sent fort. Rend deux cœurs."},
	"biere_naine": {"name": "Bière de Forgefer", "art": "une bière de Forgefer", "kind": "nourriture", "max": 10, "heal": 3,
		"desc": "Une chope de bière brune et mousseuse brassée sous la montagne. Rend un cœur et demi… et donne chaud aux oreilles."},
	# V40
	"ecaille_naga": {"name": "Écaille de Nâga", "art": "une écaille de Nâga", "kind": "tresor", "max": 5,
		"desc": "Une écaille du Serpent des Abysses, verte et dure comme du jade, large comme une main. La preuve de ta victoire. Octave en donnerait une fortune."},
	"boussole": {"name": "Boussole de Barnabé", "art": "une boussole", "kind": "outil", "max": 1,
		"desc": "La vieille boussole de marine de Barnabé. Elle montre ce que tu cherches vraiment. En général, le nord."},
}
const KIND_LABEL := {"nourriture": "Nourriture", "materiau": "Matériau", "tresor": "Trésor", "arme": "Arme", "outil": "Outil", "canne": "Outil de pêche", "quete": "Objet de quête"}

var main: Node
var xr_mode: bool = false
var opened: bool = false
var slots: Array = []                   # [{id, n}] ; id "" = case vide
var equipped: String = ""
var taken: Dictionary = {}              # objets du monde déjà ramassés (uid -> true)
var pickups: Array = []                 # {uid, id, n, node, pos}
var drop_counter: int = 0
var selected: int = -1
var _icons: Dictionary = {}
var _materials: Dictionary = {}
var _clock: float = 0.0

## Fournis par main.gd
var use_food: Callable                  # (demi-cœurs) -> bool : soigne, false si déjà plein
var drop_point: Callable                # () -> Vector3 : où poser un objet jeté

# Fenêtre PC
var _layer: CanvasLayer
var _buttons: Array = []
var _counts: Array = []
var _detail_icon: TextureRect
var _detail_name: Label
var _detail_kind: Label
var _detail_desc: Label
var _use_button: Button
var _drop_button: Button
var _equip_label: Label
# Panneau VR
var _vr_panel: Node3D
var _vr_text: Label3D
var _vr_sel: int = 0
var _vr_neutral: bool = true
var _vr_trigger_ready: bool = false
var _vr_labels: Array = []


func setup(main_node: Node, use_xr: bool) -> void:
	main = main_node
	xr_mode = use_xr
	_clear_slots()
	for id in ITEMS:
		var path: String = "res://assets/textures/items/%s.png" % id
		if ResourceLoader.exists(path):
			_icons[id] = load(path)
	if xr_mode:
		_build_vr_panel()
	else:
		_build_pc_window()


func _clear_slots() -> void:
	slots.clear()
	for i in range(SLOT_COUNT):
		slots.append({"id": "", "n": 0})


# =================================================================== données

func count(id: String) -> int:
	var total: int = 0
	for s in slots:
		if s["id"] == id:
			total += int(s["n"])
	return total


## Ajoute n objets ; renvoie combien ont vraiment trouvé place.
func add(id: String, n: int = 1) -> int:
	if not ITEMS.has(id) or n <= 0:
		return 0
	var cap: int = int(ITEMS[id]["max"])
	var left: int = n
	for s in slots:
		if left <= 0:
			break
		if s["id"] == id and int(s["n"]) < cap:
			var put: int = mini(cap - int(s["n"]), left)
			s["n"] = int(s["n"]) + put
			left -= put
	for s in slots:
		if left <= 0:
			break
		if s["id"] == "":
			var put2: int = mini(cap, left)
			s["id"] = id
			s["n"] = put2
			left -= put2
	if left < n:
		changed.emit()
		_refresh()
	return n - left


## V48 : l'échange tient-il dans le sac ? On simule : d'abord ce qui sort (takes), puis ce
## qui entre (gives), exactement comme add(). Rien n'est modifié.
func can_accept(gives: Array, takes: Array = []) -> bool:
	var sim: Array = []
	for s in slots:
		sim.append({"id": str(s["id"]), "n": int(s["n"])})
	for t in takes:
		var left: int = int(t[1])
		for s in sim:
			if left <= 0:
				break
			if s["id"] == str(t[0]):
				var k: int = mini(int(s["n"]), left)
				s["n"] = int(s["n"]) - k
				left -= k
				if int(s["n"]) <= 0:
					s["id"] = ""
					s["n"] = 0
	for g in gives:
		var id: String = str(g[0])
		var left2: int = int(g[1])
		if not ITEMS.has(id) or left2 <= 0:
			continue
		var cap: int = int(ITEMS[id]["max"])
		for s in sim:
			if left2 <= 0:
				break
			if s["id"] == id and int(s["n"]) < cap:
				var put: int = mini(cap - int(s["n"]), left2)
				s["n"] = int(s["n"]) + put
				left2 -= put
		for s in sim:
			if left2 <= 0:
				break
			if s["id"] == "":
				var put2: int = mini(cap, left2)
				s["id"] = id
				s["n"] = put2
				left2 -= put2
		if left2 > 0:
			return false
	return true


## V33 : combien d'objets de ce type peuvent encore entrer (piles entamées + cases vides).
func space_for(id: String) -> int:
	if not ITEMS.has(id):
		return 0
	var cap: int = int(ITEMS[id]["max"])
	var room: int = 0
	var have: int = 0
	for s in slots:
		if s["id"] == id:
			room += cap - int(s["n"])
			have += int(s["n"])
		elif s["id"] == "":
			room += cap
	# « max » vaut aussi pour le total des objets uniques (une seule pelle, une seule épée…).
	if cap == 1:
		return 0 if have >= 1 else mini(room, 1)
	return room


## V31 : retire n objets d'un type (dons aux personnages, quêtes). Renvoie le nombre retiré.
func remove(id: String, n: int) -> int:
	var left: int = n
	for i in range(slots.size()):
		if left <= 0:
			break
		if slots[i]["id"] == id:
			var take: int = mini(int(slots[i]["n"]), left)
			left -= take
			remove_from_slot(i, take)
	return n - left


func counts() -> Dictionary:
	var out := {}
	for s in slots:
		if s["id"] != "":
			out[s["id"]] = int(out.get(s["id"], 0)) + int(s["n"])
	return out


func remove_from_slot(i: int, n: int = 1) -> void:
	if i < 0 or i >= slots.size() or slots[i]["id"] == "":
		return
	var id: String = slots[i]["id"]
	slots[i]["n"] = int(slots[i]["n"]) - n
	if int(slots[i]["n"]) <= 0:
		slots[i] = {"id": "", "n": 0}
		if equipped == id and count(id) == 0:
			equip_item("")
	changed.emit()
	_refresh()


## Utiliser (manger) ou équiper / ranger l'arme selon l'objet.
func use_slot(i: int) -> void:
	if i < 0 or i >= slots.size() or slots[i]["id"] == "":
		return
	var id: String = slots[i]["id"]
	var info: Dictionary = ITEMS[id]
	match str(info["kind"]):
		"nourriture":
			if use_food.is_valid() and use_food.call(int(info.get("heal", 1))):
				_sfx("manger")
				remove_from_slot(i, 1)
				notify.emit(str(info["name"]) + " mangé(e).")
			else:
				_sfx("ui_erreur")
				notify.emit("Vos cœurs sont déjà pleins.")
		"arme", "canne":
			equip_item("" if equipped == id else id)
		"outil":
			if bool(info.get("equip", false)):
				equip_item("" if equipped == id else id)
			else:
				notify.emit(str(info["desc"]))
		_:
			notify.emit("Cet objet servira plus tard.")


func equip_item(id: String) -> void:
	if id != "" and id != equipped and opened:
		_sfx("equiper")
	equipped = id
	equipped_changed.emit(id)
	if id != "":
		notify.emit(str(ITEMS[id]["name"]) + " en main.")
	_refresh()


func drop_slot(i: int) -> void:
	if i < 0 or i >= slots.size() or slots[i]["id"] == "":
		return
	var id: String = slots[i]["id"]
	var where: Vector3 = drop_point.call() if drop_point.is_valid() else Vector3.ZERO
	remove_from_slot(i, 1)
	drop_counter += 1
	spawn_pickup("jete_%d" % drop_counter, id, 1, where)
	_sfx("jeter")


## V50 : bruitages (via main.sfx).
func _sfx(name: String, at: Variant = null) -> void:
	if main != null and main.has_method("sfx"):
		main.sfx(name, at)


## Le bruit d'un objet ramassé : pièces, gemmes, pierres, bois, ou un bruit d'objet ordinaire.
static func pickup_sound(id: String) -> String:
	if id in ["piece", "piece_or"]:
		return "ramasse_pieces"
	if id in ["rubis", "perle", "eclat_cristal", "obsidienne", "coeur_magma", "rune_golem", "poussiere_fee", "goutte_rosee"]:
		return "ramasse_gemme"
	if id in ["caillou", "minerai_fer", "fragment_amulette"]:
		return "ramasse_pierre"
	if id in ["baton", "buche"]:
		return "ramasse_bois"
	return "ramasse"


func serialize() -> Dictionary:
	var list: Array = []
	for s in slots:
		list.append([s["id"], int(s["n"])])
	var loose: Array = []
	for p in pickups:
		if str(p["uid"]).begins_with("jete_"):
			loose.append([p["id"], int(p["n"]), p["pos"].x, p["pos"].y, p["pos"].z])
	return {"cases": list, "main": equipped, "ramasses": taken.keys(), "poses": loose}


func load_data(d: Dictionary) -> void:
	_clear_slots()
	var list: Array = d.get("cases", [])
	for i in range(mini(list.size(), SLOT_COUNT)):
		var e: Array = list[i]
		if e.size() == 2 and ITEMS.has(str(e[0])) and int(e[1]) > 0:
			slots[i] = {"id": str(e[0]), "n": int(e[1])}
	taken.clear()
	for uid in d.get("ramasses", []):
		taken[str(uid)] = true
	_respawn_world()
	for e2 in d.get("poses", []):
		if e2 is Array and e2.size() == 5 and ITEMS.has(str(e2[0])):
			drop_counter += 1
			spawn_pickup("jete_%d" % drop_counter, str(e2[0]), int(e2[1]), Vector3(float(e2[2]), float(e2[3]), float(e2[4])))
	var eq: String = str(d.get("main", ""))
	equip_item(eq if count(eq) > 0 else "")
	changed.emit()
	_refresh()


func reset() -> void:
	_clear_slots()
	taken.clear()
	_respawn_world()
	equip_item("")


# =================================================================== objets dans le monde

## Placement déterministe : les mêmes objets aux mêmes endroits à chaque partie, ce qui
## permet de mémoriser dans la sauvegarde ceux qui ont déjà été ramassés.
func _world_plan() -> Array:
	var plan: Array = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 2828
	var spots := [
		["pomme", 12, 9.0, 34.0, 1.2, 7.5],
		["baies", 10, 12.0, 46.0, 1.2, 8.0],
		["champignon", 10, 18.0, 52.0, 2.0, 10.0],
		["baton", 12, 8.0, 44.0, 1.0, 9.0],
		["caillou", 12, 8.0, 50.0, 0.4, 7.0],
		["coquillage", 14, 38.0, 62.0, 0.12, 1.4],
	]
	for s in spots:
		var made: int = 0
		var tries: int = 0
		while made < int(s[1]) and tries < 400:
			tries += 1
			var a: float = rng.randf() * TAU
			var r: float = rng.randf_range(float(s[2]), float(s[3]))
			var x: float = cos(a) * r
			var z: float = 4.0 + sin(a) * r
			var y: float = main._height_at(x, z)
			if y < float(s[4]) or y > float(s[5]):
				continue
			if Vector2(x - 9.0, z - 4.0).length() < 6.5 or Vector2(x + 11.0, z - 9.0).length() < 5.5 or Vector2(x, z - 4.0).length() < 2.5:
				continue
			plan.append({"uid": "%s_%d" % [s[0], made], "id": s[0], "n": 1, "x": x, "z": z})
			made += 1
	return plan


func spawn_world() -> void:
	_respawn_world()


func _respawn_world() -> void:
	for p in pickups:
		if is_instance_valid(p["node"]):
			p["node"].queue_free()
	pickups.clear()
	if main == null or not main.is_inside_tree():
		return
	var space: PhysicsDirectSpaceState3D = main.get_world_3d().direct_space_state
	for e in _world_plan():
		if taken.has(e["uid"]):
			continue
		var x: float = e["x"]
		var z: float = e["z"]
		var h: float = main._height_at(x, z)
		# On pose l'objet sur le sol réel, et seulement si rien d'autre n'est là (rocher, buisson…).
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(x, h + 8.0, z), Vector3(x, h - 2.0, z), 1))
		if hit.is_empty() or str(hit.collider.name) != "Sol_collision_v11":
			continue
		spawn_pickup(e["uid"], e["id"], int(e["n"]), hit.position)
	# V47 : minerai, obsidienne, champignons de braise et plumes de l'île des nains.
	if main.get("nains_v46") != null and main.nains_v46 != null:
		for e2 in main.nains_v46.pickup_plan():
			if not taken.has(str(e2["uid"])):
				spawn_pickup(str(e2["uid"]), str(e2["id"]), 1, e2["pos"])
	# L'épée d'entraînement repose sur l'établi de la forge.
	if not taken.has("epee_forge") and main.houses_v27 != null:
		var bench: Node3D = main.houses_v27.find_child("Etabli_v27", true, false) as Node3D
		if bench != null:
			spawn_pickup("epee_forge", "epee_bois", 1, bench.global_position + Vector3.UP * 0.46, bench.global_rotation.y)


func spawn_pickup(uid: String, id: String, n: int, pos: Vector3, yaw: float = INF) -> void:
	var node := Node3D.new()
	node.name = "Objet_" + uid
	add_child(node)
	node.global_position = pos
	var model: Node3D = make_model(id)
	if id == "epee_bois":
		model.rotation_degrees = Vector3(0, 0, 90)   # couchée
		model.position.y = 0.03
	node.add_child(model)
	node.rotation.y = yaw if not is_inf(yaw) else float(hash(uid) % 628) / 100.0
	# Petit éclat lumineux pour repérer l'objet dans l'herbe.
	var glint := MeshInstance3D.new()
	glint.name = "Eclat"
	var quad := QuadMesh.new()
	quad.size = Vector2(0.16, 0.16)
	glint.mesh = quad
	glint.material_override = _glint_material()
	glint.position = Vector3(0, 0.22, 0)
	glint.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.add_child(glint)
	var label := Label3D.new()
	label.name = "Aide_VR"
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 40
	label.pixel_size = 0.0022
	label.outline_size = 10
	label.position = Vector3(0, 0.55, 0)
	label.no_depth_test = true
	label.visible = false
	label.text = "Gâchette : ramasser\n" + str(ITEMS[id]["name"])
	node.add_child(label)
	pickups.append({"uid": uid, "id": id, "n": n, "node": node, "pos": pos})


func _glint_material() -> StandardMaterial3D:
	if _materials.has("glint"):
		return _materials["glint"]
	var grad := Gradient.new()
	grad.set_color(0, Color(1, 1, 0.9, 1))
	grad.set_color(1, Color(1, 1, 0.8, 0))
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 0.0)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.albedo_texture = tex
	m.albedo_color = Color(1, 1, 1, 0.0)
	_materials["glint"] = m
	return m


func _mat(key: String, color: Color, rough: float = 0.7) -> StandardMaterial3D:
	if _materials.has(key):
		return _materials[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	_materials[key] = m
	return m


func _part(parent: Node3D, mesh: Mesh, mat: Material, pos: Vector3, rot_deg: Vector3 = Vector3.ZERO, scl: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot_deg
	mi.scale = scl
	parent.add_child(mi)
	return mi


func _sphere(r: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = 16
	s.rings = 10
	return s


func _cyl(r_top: float, r_bottom: float, h: float, seg: int = 12) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = r_top
	c.bottom_radius = r_bottom
	c.height = h
	c.radial_segments = seg
	return c


func _box_mesh(size: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = size
	return b


## Maillage 3D d'un objet (au sol, dans la main ou à la ceinture). Taille réelle, en mètres.
func make_model(id: String) -> Node3D:
	var m := Node3D.new()
	m.name = "Modele_" + id
	match id:
		"pomme":
			_part(m, _sphere(0.075), _mat("pomme", Color(0.72, 0.08, 0.07), 0.45), Vector3(0, 0.07, 0), Vector3.ZERO, Vector3(1, 0.9, 1))
			_part(m, _cyl(0.006, 0.008, 0.05, 6), _mat("tige", Color(0.3, 0.2, 0.1)), Vector3(0, 0.15, 0), Vector3(0, 0, 12))
			_part(m, _sphere(0.03), _mat("feuille", Color(0.25, 0.5, 0.18)), Vector3(0.025, 0.16, 0), Vector3(0, 0, -30), Vector3(1.4, 0.25, 0.7))
		"champignon":
			_part(m, _cyl(0.025, 0.032, 0.1, 10), _mat("pied", Color(0.9, 0.86, 0.78)), Vector3(0, 0.05, 0))
			_part(m, _sphere(0.075), _mat("chapeau", Color(0.55, 0.26, 0.12), 0.6), Vector3(0, 0.1, 0), Vector3.ZERO, Vector3(1, 0.55, 1))
		"baies":
			for k in range(7):
				var a: float = k * 0.9
				_part(m, _sphere(0.022), _mat("baie", Color(0.22, 0.1, 0.38), 0.35), Vector3(cos(a) * 0.04 * (k % 3), 0.025 + (k % 2) * 0.03, sin(a) * 0.04 * (k % 3)))
			_part(m, _sphere(0.04), _mat("feuille", Color(0.25, 0.5, 0.18)), Vector3(0, 0.02, 0.04), Vector3.ZERO, Vector3(1.5, 0.2, 1))
		"baton":
			_part(m, _cyl(0.018, 0.024, 0.7, 8), _mat("bois_brut", Color(0.42, 0.28, 0.16), 0.9), Vector3(0, 0.024, 0), Vector3(0, 0, 90))
			_part(m, _cyl(0.008, 0.012, 0.18, 6), _mat("bois_brut", Color(0.42, 0.28, 0.16), 0.9), Vector3(0.12, 0.05, 0.04), Vector3(40, 0, 70))
		"caillou":
			_part(m, _sphere(0.09), _mat("caillou", Color(0.5, 0.5, 0.48), 0.95), Vector3(0, 0.05, 0), Vector3(0, 0, 8), Vector3(1.2, 0.65, 0.9))
		"coquillage":
			_part(m, _sphere(0.07), _mat("nacre", Color(0.93, 0.8, 0.74), 0.3), Vector3(0, 0.02, 0), Vector3.ZERO, Vector3(1, 0.3, 0.9))
			for k in range(5):
				_part(m, _box_mesh(Vector3(0.006, 0.006, 0.12)), _mat("strie", Color(0.8, 0.6, 0.55)), Vector3(-0.04 + k * 0.02, 0.04, 0), Vector3(0, (k - 2) * 12, 0))
		"piece":
			_part(m, _cyl(0.035, 0.035, 0.008, 16), _mat("cuivre", Color(0.78, 0.5, 0.25), 0.3), Vector3(0, 0.004, 0))
		"canne_peche":
			# Construite le long de +Y : poignée en bas, scion vers le haut (2 m).
			var cork := _mat("liege", Color(0.72, 0.58, 0.4), 0.9)
			var rod := _mat("canne", Color(0.32, 0.2, 0.1), 0.45)
			_part(m, _cyl(0.018, 0.02, 0.32, 10), cork, Vector3(0, 0.0, 0))
			_part(m, _cyl(0.006, 0.014, 1.75, 8), rod, Vector3(0, 1.03, 0))
			_part(m, _cyl(0.035, 0.035, 0.03, 14), _mat("moulinet", Color(0.6, 0.6, 0.64), 0.3), Vector3(0.035, 0.12, 0), Vector3(0, 0, 90))
			for k in range(4):
				_part(m, _cyl(0.008, 0.008, 0.004, 8), _mat("anneau", Color(0.8, 0.8, 0.82), 0.2), Vector3(0.012, 0.5 + k * 0.38, 0), Vector3(0, 0, 90))
			var tip := Marker3D.new()
			tip.name = "Pointe"
			tip.position = Vector3(0, 1.9, 0)
			m.add_child(tip)
		"vieille_botte":
			_part(m, _box_mesh(Vector3(0.1, 0.26, 0.12)), _mat("cuir", Color(0.36, 0.24, 0.14), 0.9), Vector3(0, 0.13, 0))
			_part(m, _box_mesh(Vector3(0.1, 0.08, 0.24)), _mat("cuir", Color(0.36, 0.24, 0.14), 0.9), Vector3(0, 0.04, 0.06))
		"sardine", "maquereau", "dorade", "bar", "poisson_perroquet", "merou", "poisson_lune":
			_fish_model(m, id)
		"boussole":
			_part(m, _cyl(0.05, 0.05, 0.022, 20), _mat("laiton", Color(0.72, 0.56, 0.24), 0.25), Vector3(0, 0.011, 0))
			_part(m, _cyl(0.042, 0.042, 0.004, 20), _mat("cadran", Color(0.92, 0.88, 0.78), 0.5), Vector3(0, 0.023, 0))
			_part(m, _box_mesh(Vector3(0.006, 0.003, 0.07)), _mat("aiguille", Color(0.75, 0.1, 0.08), 0.4), Vector3(0, 0.027, 0), Vector3(0, 30, 0))
		"pelle":
			# Le long de +Y : poignée en T en bas (dans la main), fer en haut.
			var handle := _mat("manche", Color(0.5, 0.34, 0.2), 0.75)
			var iron := _mat("fer", Color(0.3, 0.31, 0.33), 0.55)
			iron.metallic = 0.4
			_part(m, _box_mesh(Vector3(0.13, 0.03, 0.03)), handle, Vector3(0, -0.06, 0))
			_part(m, _cyl(0.016, 0.018, 0.95, 8), handle, Vector3(0, 0.42, 0))
			_part(m, _cyl(0.024, 0.02, 0.1, 8), iron, Vector3(0, 0.93, 0))
			_part(m, _box_mesh(Vector3(0.21, 0.24, 0.012)), iron, Vector3(0, 1.08, 0.01), Vector3(-8, 0, 0))
			_part(m, _box_mesh(Vector3(0.15, 0.06, 0.012)), iron, Vector3(0, 1.215, 0.03), Vector3(-8, 0, 0))
			_tip(m, 1.2)
		"hache":
			var haft := _mat("manche_hache", Color(0.56, 0.38, 0.22), 0.7)
			var head := _mat("fer_hache", Color(0.4, 0.42, 0.45), 0.3)
			head.metallic = 0.8
			_part(m, _cyl(0.017, 0.021, 0.72, 8), haft, Vector3(0, 0.3, 0))
			_part(m, _cyl(0.024, 0.024, 0.09, 8), _mat("cuir", Color(0.36, 0.24, 0.14), 0.9), Vector3(0, 0.0, 0))
			_part(m, _box_mesh(Vector3(0.05, 0.07, 0.05)), head, Vector3(0, 0.62, 0))
			_part(m, _box_mesh(Vector3(0.012, 0.13, 0.17)), head, Vector3(0, 0.62, 0.1))
			_part(m, _box_mesh(Vector3(0.008, 0.17, 0.02)), _mat("fil_hache", Color(0.8, 0.82, 0.85), 0.15), Vector3(0, 0.62, 0.19))
			_tip(m, 0.66, 0.19)
		"epee":
			var steel := _mat("acier", Color(0.78, 0.8, 0.83), 0.18)
			steel.metallic = 0.9
			var brass := _mat("laiton", Color(0.72, 0.56, 0.24), 0.25)
			brass.metallic = 0.8
			_part(m, _cyl(0.015, 0.017, 0.15, 8), _mat("cuir", Color(0.36, 0.24, 0.14), 0.9), Vector3(0, 0.0, 0))
			_part(m, _box_mesh(Vector3(0.2, 0.025, 0.04)), brass, Vector3(0, 0.09, 0))
			_part(m, _box_mesh(Vector3(0.045, 0.7, 0.008)), steel, Vector3(0, 0.45, 0))
			_part(m, _box_mesh(Vector3(0.032, 0.032, 0.008)), steel, Vector3(0, 0.8, 0), Vector3(0, 0, 45))
			_part(m, _sphere(0.022), brass, Vector3(0, -0.09, 0))
			_tip(m, 0.8)
		"buche":
			var bark := _mat("ecorce_buche", Color(0.4, 0.27, 0.16), 0.95)
			_part(m, _cyl(0.09, 0.1, 0.45, 12), bark, Vector3(0, 0.1, 0), Vector3(0, 0, 90))
			for sx in [-1.0, 1.0]:
				_part(m, _cyl(0.085, 0.085, 0.01, 12), _mat("tranche", Color(0.82, 0.66, 0.44), 0.8), Vector3(sx * 0.226, 0.1, 0), Vector3(0, 0, 90))
		"noix_coco":
			_part(m, _sphere(0.08), _mat("coco", Color(0.38, 0.25, 0.14), 0.95), Vector3(0, 0.075, 0), Vector3.ZERO, Vector3(1, 0.92, 1))
		"miel":
			_part(m, _sphere(0.07), _mat("pot", Color(0.62, 0.36, 0.18), 0.6), Vector3(0, 0.07, 0), Vector3.ZERO, Vector3(1, 1.1, 1))
			_part(m, _cyl(0.05, 0.05, 0.03, 12), _mat("tissu", Color(0.86, 0.78, 0.58), 0.9), Vector3(0, 0.15, 0))
		"perle":
			_part(m, _sphere(0.025), _mat("nacre_perle", Color(0.96, 0.94, 0.92), 0.15), Vector3(0, 0.025, 0))
		"bague":
			_part(m, _cyl(0.03, 0.03, 0.012, 16), _mat("argent", Color(0.82, 0.84, 0.88), 0.2), Vector3(0, 0.006, 0))
			_part(m, _sphere(0.012), _mat("saphir", Color(0.2, 0.5, 0.85), 0.1), Vector3(0, 0.03, 0))
		"rubis":
			_part(m, _cyl(0.0, 0.035, 0.05, 6), _mat("rubis", Color(0.75, 0.05, 0.12), 0.1), Vector3(0, 0.025, 0))
			_part(m, _cyl(0.035, 0.0, 0.025, 6), _mat("rubis", Color(0.75, 0.05, 0.12), 0.1), Vector3(0, 0.0625, 0))
		"piece_or":
			_part(m, _cyl(0.04, 0.04, 0.01, 16), _mat("or", Color(0.95, 0.75, 0.2), 0.25), Vector3(0, 0.005, 0))
		"fragment_amulette":
			_part(m, _cyl(0.07, 0.07, 0.012, 3), _mat("jade", Color(0.25, 0.62, 0.42), 0.25), Vector3(0, 0.006, 0))
		"fleur_lune":
			_part(m, _cyl(0.004, 0.005, 0.12, 6), _mat("tige_fleur", Color(0.3, 0.55, 0.3)), Vector3(0, 0.06, 0))
			for k in range(6):
				var a: float = TAU * k / 6.0
				_part(m, _sphere(0.025), _mat("petale_lune", Color(0.92, 0.95, 1.0), 0.3), Vector3(cos(a) * 0.03, 0.125, sin(a) * 0.03), Vector3.ZERO, Vector3(1.0, 0.4, 1.0))
		"graine_or":
			_part(m, _sphere(0.03), _mat("or", Color(0.95, 0.75, 0.2), 0.25), Vector3(0, 0.03, 0), Vector3.ZERO, Vector3(0.8, 1.2, 0.8))
		"fiole_vide", "eau_source":
			_part(m, _sphere(0.045), _mat("verre", Color(0.75, 0.88, 0.95), 0.1), Vector3(0, 0.045, 0))
			_part(m, _cyl(0.012, 0.012, 0.05, 8), _mat("verre", Color(0.75, 0.88, 0.95), 0.1), Vector3(0, 0.1, 0))
		"boussole_elfique":
			_part(m, _cyl(0.045, 0.045, 0.015, 20), _mat("argent", Color(0.82, 0.84, 0.88), 0.2), Vector3(0, 0.008, 0))
		"goutte_rosee":
			_part(m, _sphere(0.035), _mat("rosee", Color(0.75, 0.95, 1.0), 0.05), Vector3(0, 0.035, 0), Vector3.ZERO, Vector3(1.0, 1.2, 1.0))
		"baguette_fee":
			_part(m, _cyl(0.006, 0.009, 0.32, 8), _mat("sureau", Color(0.75, 0.6, 0.4), 0.7), Vector3(0, 0.16, 0))
			_part(m, _sphere(0.03), _mat("etoile_fee", Color(1.0, 0.9, 0.6), 0.1), Vector3(0, 0.34, 0))
		"eclat_cristal":
			_part(m, _cyl(0.0, 0.03, 0.08, 6), _mat("cristal_rose", Color(0.9, 0.55, 0.9), 0.1), Vector3(0, 0.04, 0))
		"minerai_fer":
			_part(m, _sphere(0.05), _mat("roche_fer", Color(0.42, 0.38, 0.36), 0.9), Vector3(0, 0.04, 0), Vector3.ZERO, Vector3(1.2, 0.8, 1.0))
			for k in 4:
				_part(m, _sphere(0.014), _mat("rouille", Color(0.72, 0.36, 0.2), 0.6), Vector3(cos(k * 1.6) * 0.04, 0.06, sin(k * 1.6) * 0.035))
		"obsidienne":
			var obs := _mat("obsidienne", Color(0.08, 0.07, 0.11), 0.05)
			obs.metallic = 0.3
			_part(m, _cyl(0.0, 0.035, 0.11, 5), obs, Vector3(0, 0.055, 0), Vector3(8, 20, 5))
		"champignon_braise":
			_part(m, _cyl(0.012, 0.016, 0.06, 8), _mat("pied_braise", Color(0.35, 0.25, 0.22), 0.8), Vector3(0, 0.03, 0))
			var cap := _mat("braise_champi", Color(0.95, 0.35, 0.12), 0.5)
			cap.emission_enabled = true
			cap.emission = Color(1.0, 0.4, 0.1)
			cap.emission_energy_multiplier = 0.8
			_part(m, _sphere(0.045), cap, Vector3(0, 0.065, 0), Vector3.ZERO, Vector3(1.0, 0.55, 1.0))
		"plume_corbeau":
			_part(m, _box_mesh(Vector3(0.04, 0.004, 0.22)), _mat("plume", Color(0.06, 0.06, 0.09), 0.4), Vector3(0, 0.004, 0), Vector3(0, 25, 0))
		"coeur_magma":
			var lava := _mat("magma", Color(1.0, 0.45, 0.1), 0.4)
			lava.emission_enabled = true
			lava.emission = Color(1.0, 0.45, 0.1)
			lava.emission_energy_multiplier = 2.0
			_part(m, _sphere(0.045), lava, Vector3(0, 0.045, 0))
		"rune_golem":
			_part(m, _box_mesh(Vector3(0.1, 0.03, 0.13)), _mat("pierre_golem", Color(0.55, 0.53, 0.5), 0.9), Vector3(0, 0.015, 0))
			var rn := _mat("rune_bleue", Color(0.35, 0.8, 1.0), 0.3)
			rn.emission_enabled = true
			rn.emission = Color(0.35, 0.8, 1.0)
			rn.emission_energy_multiplier = 2.0
			_part(m, _box_mesh(Vector3(0.012, 0.004, 0.09)), rn, Vector3(0, 0.032, 0))
		"epee_naine":
			var steel2 := _mat("acier_nain", Color(0.72, 0.74, 0.78), 0.15)
			steel2.metallic = 0.9
			var gold := _mat("or_nain", Color(0.9, 0.7, 0.25), 0.25)
			gold.metallic = 0.9
			_part(m, _cyl(0.018, 0.02, 0.14, 8), _mat("cuir", Color(0.36, 0.24, 0.14), 0.9), Vector3(0, 0.0, 0))
			_part(m, _box_mesh(Vector3(0.24, 0.035, 0.05)), gold, Vector3(0, 0.09, 0))
			_part(m, _box_mesh(Vector3(0.075, 0.55, 0.012)), steel2, Vector3(0, 0.38, 0))
			_part(m, _box_mesh(Vector3(0.053, 0.053, 0.012)), steel2, Vector3(0, 0.655, 0), Vector3(0, 0, 45))
			_part(m, _sphere(0.028), _mat("rubis_pommeau", Color(0.85, 0.1, 0.1), 0.1), Vector3(0, -0.09, 0))
			_tip(m, 0.67)
		"ragout_nain":
			_part(m, _cyl(0.07, 0.05, 0.05, 14), _mat("bol", Color(0.4, 0.27, 0.17), 0.8), Vector3(0, 0.025, 0))
			_part(m, _cyl(0.064, 0.064, 0.01, 14), _mat("ragout", Color(0.6, 0.3, 0.15), 0.6), Vector3(0, 0.048, 0))
		"fromage_chevre":
			_part(m, _cyl(0.06, 0.065, 0.05, 16), _mat("fromage", Color(0.95, 0.92, 0.8), 0.8), Vector3(0, 0.025, 0))
		"biere_naine":
			_part(m, _cyl(0.04, 0.04, 0.1, 12), _mat("chope", Color(0.5, 0.33, 0.18), 0.7), Vector3(0, 0.05, 0))
			_part(m, _cyl(0.042, 0.042, 0.02, 12), _mat("mousse", Color(0.98, 0.96, 0.9), 0.9), Vector3(0, 0.105, 0))
		"carte_naine":
			_part(m, _box_mesh(Vector3(0.2, 0.006, 0.14)), _mat("parchemin", Color(0.86, 0.76, 0.56), 0.9), Vector3(0, 0.003, 0))
			_part(m, _cyl(0.012, 0.012, 0.15, 8), _mat("parchemin", Color(0.86, 0.76, 0.56), 0.9), Vector3(-0.1, 0.012, 0), Vector3(90, 0, 0))
			_part(m, _cyl(0.012, 0.012, 0.15, 8), _mat("parchemin", Color(0.86, 0.76, 0.56), 0.9), Vector3(0.1, 0.012, 0), Vector3(90, 0, 0))
			_part(m, _sphere(0.015), _mat("cire_rouge", Color(0.7, 0.1, 0.08), 0.4), Vector3(0.04, 0.01, 0.03), Vector3.ZERO, Vector3(1, 0.4, 1))
		"nectar_fee":
			_part(m, _sphere(0.04), _mat("verre_nectar", Color(1.0, 0.8, 0.3), 0.1), Vector3(0, 0.04, 0))
			_part(m, _cyl(0.012, 0.012, 0.04, 8), _mat("verre", Color(0.75, 0.88, 0.95), 0.1), Vector3(0, 0.09, 0))
		"lanterne_fee":
			_part(m, _cyl(0.035, 0.04, 0.012, 12), _mat("argent", Color(0.82, 0.84, 0.88), 0.2), Vector3(0, 0.006, 0))
			_part(m, _sphere(0.035), _mat("verre_fee", Color(0.85, 1.0, 0.7), 0.1), Vector3(0, 0.045, 0), Vector3.ZERO, Vector3(1.0, 1.2, 1.0))
			_part(m, _cyl(0.0, 0.04, 0.03, 12), _mat("argent", Color(0.82, 0.84, 0.88), 0.2), Vector3(0, 0.095, 0))
		"poussiere_fee":
			_part(m, _sphere(0.04), _mat("bourse", Color(0.55, 0.35, 0.6), 0.9), Vector3(0, 0.035, 0), Vector3.ZERO, Vector3(1.0, 0.9, 1.0))
			_part(m, _sphere(0.012), _mat("paillette", Color(1.0, 0.85, 0.95), 0.1), Vector3(0, 0.075, 0))
		"potion_seve":
			_part(m, _sphere(0.045), _mat("verre_seve", Color(0.3, 0.75, 0.4), 0.1), Vector3(0, 0.045, 0))
			_part(m, _cyl(0.012, 0.012, 0.05, 8), _mat("verre", Color(0.75, 0.88, 0.95), 0.1), Vector3(0, 0.1, 0))
			_part(m, _cyl(0.014, 0.014, 0.02, 8), _mat("bouchon", Color(0.5, 0.34, 0.2), 0.8), Vector3(0, 0.13, 0))
		"tisane_lune":
			_part(m, _cyl(0.045, 0.035, 0.06, 14), _mat("porcelaine", Color(0.9, 0.88, 0.95), 0.25), Vector3(0, 0.03, 0))
			_part(m, _cyl(0.04, 0.04, 0.004, 14), _mat("tisane", Color(0.62, 0.52, 0.8), 0.1), Vector3(0, 0.058, 0))
		"pain_miel":
			_part(m, _sphere(0.08), _mat("croute", Color(0.78, 0.5, 0.22), 0.7), Vector3(0, 0.04, 0), Vector3.ZERO, Vector3(1.3, 0.55, 1.0))
			_part(m, _sphere(0.025), _mat("miel_goutte", Color(0.98, 0.75, 0.2), 0.2), Vector3(0, 0.085, 0))
		"ecaille_naga":
			_part(m, _sphere(0.07), _mat("ecaille", Color(0.2, 0.5, 0.36), 0.2), Vector3(0, 0.012, 0), Vector3.ZERO, Vector3(1.0, 0.16, 1.25))
		"amulette_serpent":
			_part(m, _cyl(0.08, 0.08, 0.016, 24), _mat("jade", Color(0.25, 0.62, 0.42), 0.25), Vector3(0, 0.008, 0))
			_part(m, _sphere(0.022), _mat("oeil_vert", Color(0.3, 0.95, 0.5), 0.1), Vector3(0, 0.02, 0))
		"epee_bois":
			# Construite le long de +Y : poignée en bas, lame vers le haut.
			var wood := _mat("lame_bois", Color(0.72, 0.56, 0.36), 0.6)
			var dark := _mat("poignee", Color(0.32, 0.2, 0.11), 0.8)
			_part(m, _cyl(0.016, 0.018, 0.16, 8), dark, Vector3(0, 0.0, 0))
			_part(m, _box_mesh(Vector3(0.17, 0.03, 0.045)), dark, Vector3(0, 0.095, 0))
			_part(m, _box_mesh(Vector3(0.05, 0.62, 0.018)), wood, Vector3(0, 0.42, 0))
			_part(m, _box_mesh(Vector3(0.035, 0.035, 0.018)), wood, Vector3(0, 0.735, 0), Vector3(0, 0, 45))
			_part(m, _sphere(0.022), dark, Vector3(0, -0.09, 0))
	for c in m.get_children():
		if c is MeshInstance3D:
			(c as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	return m


## V34 : repère au bout de la lame (traînée des coups d'épée et de hache).
func _tip(m: Node3D, y: float, z: float = 0.0) -> void:
	var tip := Marker3D.new()
	tip.name = "Pointe"
	tip.position = Vector3(0, y, z)
	m.add_child(tip)


## V32 : poisson en volume (corps fuselé, queue, nageoire dorsale), couleurs de l'espèce.
const FISH_LOOK := {
	"sardine": [Color(0.5, 0.6, 0.7), Color(0.88, 0.9, 0.92), 0.2, 0.32],
	"maquereau": [Color(0.18, 0.42, 0.46), Color(0.88, 0.9, 0.88), 0.28, 0.32],
	"dorade": [Color(0.68, 0.7, 0.72), Color(0.92, 0.92, 0.9), 0.34, 0.44],
	"bar": [Color(0.45, 0.48, 0.5), Color(0.86, 0.87, 0.86), 0.42, 0.34],
	"poisson_perroquet": [Color(0.16, 0.74, 0.66), Color(0.94, 0.55, 0.66), 0.36, 0.42],
	"merou": [Color(0.46, 0.33, 0.22), Color(0.74, 0.62, 0.47), 0.62, 0.46],
	"poisson_lune": [Color(0.9, 0.74, 0.24), Color(0.98, 0.9, 0.6), 0.4, 0.75],
}


func _fish_model(m: Node3D, id: String) -> void:
	var look: Array = FISH_LOOK.get(id, FISH_LOOK["sardine"])
	var length: float = float(look[2])
	var tall: float = float(look[3])
	var body_mat := _mat("poisson_" + id, look[0], 0.35)
	var belly_mat := _mat("ventre_" + id, look[1], 0.35)
	_part(m, _sphere(length * 0.5), body_mat, Vector3(0, length * tall * 0.5, 0), Vector3.ZERO, Vector3(1, tall, 0.38))
	_part(m, _sphere(length * 0.45), belly_mat, Vector3(0, length * tall * 0.38, 0), Vector3.ZERO, Vector3(0.95, tall * 0.7, 0.34))
	_part(m, _box_mesh(Vector3(length * 0.22, length * tall * 0.9, 0.01)), body_mat, Vector3(length * 0.56, length * tall * 0.5, 0), Vector3(0, 0, 0))
	_part(m, _box_mesh(Vector3(length * 0.3, length * tall * 0.35, 0.008)), body_mat, Vector3(0.02, length * tall * 1.0, 0), Vector3(0, 0, -12))
	for sz in [-1.0, 1.0]:
		_part(m, _sphere(length * 0.045), _mat("oeil", Color(0.05, 0.05, 0.06), 0.2), Vector3(-length * 0.36, length * tall * 0.58, sz * length * 0.17))


## Objet ramassable le plus proche (index dans pickups), ou -1.
func nearest_pickup(pos: Vector3, radius: float = PICK_RADIUS) -> int:
	var best: int = -1
	var best_d: float = radius
	for i in range(pickups.size()):
		var p: Vector3 = pickups[i]["pos"]
		if absf(p.y - pos.y) > 2.2:
			continue
		var d: float = Vector2(p.x - pos.x, p.z - pos.z).length()
		if d < best_d:
			best_d = d
			best = i
	return best


func pickup_distance(i: int, pos: Vector3) -> float:
	if i < 0 or i >= pickups.size():
		return INF
	var p: Vector3 = pickups[i]["pos"]
	return Vector2(p.x - pos.x, p.z - pos.z).length()


func collect(i: int) -> bool:
	if i < 0 or i >= pickups.size():
		return false
	var p: Dictionary = pickups[i]
	var got: int = add(p["id"], int(p["n"]))
	if got <= 0:
		_sfx("ui_erreur")
		notify.emit("Inventaire plein.")
		return false
	_sfx(pickup_sound(str(p["id"])), p["pos"])
	var name: String = str(ITEMS[p["id"]]["name"])
	notify.emit("+ " + name + ("" if got == 1 else " ×%d" % got))
	if got < int(p["n"]):
		p["n"] = int(p["n"]) - got
		return true
	if not str(p["uid"]).begins_with("jete_"):
		taken[p["uid"]] = true
	if is_instance_valid(p["node"]):
		p["node"].queue_free()
	pickups.remove_at(i)
	# Une arme ramassée sans rien en main est équipée tout de suite.
	if str(ITEMS[p["id"]]["kind"]) == "arme" and equipped == "":
		equip_item(p["id"])
	return true


func prompt_text(pos: Vector3) -> String:
	var i: int = nearest_pickup(pos)
	if i < 0:
		return ""
	return "E : ramasser " + str(ITEMS[pickups[i]["id"]]["name"])


## Étiquettes VR au-dessus de l'objet à portée de main.
func update_vr_labels(hand_pos: Vector3) -> int:
	var i: int = nearest_pickup(hand_pos, 1.3)
	for k in range(pickups.size()):
		var lbl: Label3D = pickups[k]["node"].get_node_or_null("Aide_VR")
		if lbl != null:
			lbl.visible = k == i
	return i


func _process(delta: float) -> void:
	_clock += delta
	# L'éclat scintille doucement, chaque objet à son rythme.
	var m: StandardMaterial3D = _materials.get("glint")
	if m != null:
		m.albedo_color.a = 0.12 + 0.3 * maxf(0.0, sin(_clock * 2.3))


# =================================================================== fenêtre PC

func _style(bg: Color, border: Color, radius: int = 12, width: int = 2) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(width)
	s.set_corner_radius_all(radius)
	s.set_content_margin_all(8)
	return s


func _build_pc_window() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 11
	_layer.visible = false
	add_child(_layer)
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.02, 0.05, 0.5)
	_layer.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.add_child(center)
	var card := PanelContainer.new()
	var cs := _style(Color(0.025, 0.095, 0.145, 0.95), Color(0.98, 0.76, 0.32), 18, 2)
	cs.set_content_margin_all(22)
	card.add_theme_stylebox_override("panel", cs)
	center.add_child(card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	card.add_child(col)
	var title := Label.new()
	title.text = "✦  INVENTAIRE  ✦"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1.0, 0.82, 0.47))
	col.add_child(title)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 22)
	col.add_child(row)
	var grid := GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	row.add_child(grid)
	for i in range(SLOT_COUNT):
		var b := Button.new()
		b.custom_minimum_size = Vector2(78, 78)
		b.expand_icon = true
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(_select.bind(i))
		b.gui_input.connect(_slot_input.bind(i))
		grid.add_child(b)
		var c := Label.new()
		c.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
		c.offset_left = -40
		c.offset_top = -24
		c.offset_right = -6
		c.offset_bottom = -2
		c.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		c.add_theme_font_size_override("font_size", 16)
		c.add_theme_color_override("font_outline_color", Color.BLACK)
		c.add_theme_constant_override("outline_size", 5)
		b.add_child(c)
		_buttons.append(b)
		_counts.append(c)
	var side := VBoxContainer.new()
	side.custom_minimum_size = Vector2(300, 0)
	side.add_theme_constant_override("separation", 10)
	row.add_child(side)
	_equip_label = Label.new()
	_equip_label.add_theme_font_size_override("font_size", 17)
	_equip_label.add_theme_color_override("font_color", Color(0.74, 0.92, 1.0))
	side.add_child(_equip_label)
	side.add_child(HSeparator.new())
	_detail_icon = TextureRect.new()
	_detail_icon.custom_minimum_size = Vector2(96, 96)
	_detail_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_detail_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	side.add_child(_detail_icon)
	_detail_name = Label.new()
	_detail_name.add_theme_font_size_override("font_size", 22)
	_detail_name.add_theme_color_override("font_color", Color(1.0, 0.9, 0.7))
	side.add_child(_detail_name)
	_detail_kind = Label.new()
	_detail_kind.add_theme_font_size_override("font_size", 14)
	_detail_kind.add_theme_color_override("font_color", Color(0.98, 0.76, 0.32))
	side.add_child(_detail_kind)
	_detail_desc = Label.new()
	_detail_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_desc.custom_minimum_size = Vector2(300, 70)
	_detail_desc.add_theme_font_size_override("font_size", 15)
	side.add_child(_detail_desc)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	side.add_child(buttons)
	_use_button = Button.new()
	_use_button.custom_minimum_size = Vector2(140, 40)
	_use_button.pressed.connect(func(): use_slot(selected))
	buttons.add_child(_use_button)
	_drop_button = Button.new()
	_drop_button.text = "Jeter"
	_drop_button.custom_minimum_size = Vector2(100, 40)
	_drop_button.pressed.connect(func(): drop_slot(selected))
	buttons.add_child(_drop_button)
	var help := Label.new()
	help.text = "Clic : choisir  •  double-clic : utiliser  •  I / Tab / Échap : fermer"
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help.add_theme_font_size_override("font_size", 14)
	help.add_theme_color_override("font_color", Color(0.7, 0.8, 0.88))
	col.add_child(help)
	_refresh()


func _slot_input(event: InputEvent, i: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.double_click and event.button_index == MOUSE_BUTTON_LEFT:
		use_slot(i)


func _select(i: int) -> void:
	selected = i
	_refresh()


func toggle() -> void:
	if opened:
		close()
	else:
		open()


func open() -> void:
	if not opened:
		_sfx("ui_ouvrir")
	opened = true
	_vr_sel = clampi(_vr_sel, 0, SLOT_COUNT - 1)
	_vr_trigger_ready = false
	if selected < 0 or slots[selected]["id"] == "":
		selected = _first_filled()
	if _layer != null:
		_layer.visible = true
	if _vr_panel != null:
		_place_vr_panel()
		_vr_panel.visible = true
	_refresh()


func close() -> void:
	if opened:
		_sfx("ui_fermer")
	opened = false
	if _layer != null:
		_layer.visible = false
	if _vr_panel != null:
		_vr_panel.visible = false


func _first_filled() -> int:
	for i in range(slots.size()):
		if slots[i]["id"] != "":
			return i
	return -1


func _refresh() -> void:
	if _layer != null:
		_refresh_pc()
	if _vr_panel != null:
		_refresh_vr()


func _refresh_pc() -> void:
	for i in range(SLOT_COUNT):
		var b: Button = _buttons[i]
		var s: Dictionary = slots[i]
		var id: String = s["id"]
		b.icon = _icons.get(id) if id != "" else null
		var n: int = int(s["n"])
		_counts[i].text = str(n) if n > 1 else ""
		var is_eq: bool = id != "" and id == equipped
		var border := Color(1.0, 0.85, 0.45) if i == selected else (Color(0.45, 0.85, 1.0) if is_eq else Color(0.3, 0.42, 0.52))
		var st := _style(Color(0.06, 0.16, 0.22, 0.95), border, 10, 3 if i == selected or is_eq else 1)
		b.add_theme_stylebox_override("normal", st)
		b.add_theme_stylebox_override("hover", _style(Color(0.1, 0.22, 0.3, 0.95), border, 10, 3))
		b.add_theme_stylebox_override("pressed", st)
		b.tooltip_text = str(ITEMS[id]["name"]) if id != "" else ""
	_equip_label.text = "En main : " + (str(ITEMS[equipped]["name"]) if equipped != "" else "mains nues")
	var has: bool = selected >= 0 and slots[selected]["id"] != ""
	_use_button.visible = has
	_drop_button.visible = has
	if not has:
		_detail_icon.texture = null
		_detail_name.text = "Rien de choisi"
		_detail_kind.text = ""
		_detail_desc.text = "Ramassez des objets dans l'île avec E." if _first_filled() < 0 else "Cliquez sur un objet."
		return
	var sid: String = slots[selected]["id"]
	var info: Dictionary = ITEMS[sid]
	_detail_icon.texture = _icons.get(sid)
	_detail_name.text = str(info["name"]) + ("" if int(slots[selected]["n"]) <= 1 else "  ×" + str(slots[selected]["n"]))
	_detail_kind.text = str(KIND_LABEL.get(info["kind"], ""))
	_detail_desc.text = str(info["desc"])
	match str(info["kind"]):
		"nourriture":
			_use_button.text = "Manger"
		"arme", "canne":
			_use_button.text = "Ranger" if equipped == sid else "Équiper"
		"outil":
			_use_button.text = ("Ranger" if equipped == sid else "Équiper") if bool(info.get("equip", false)) else "Examiner"
		_:
			_use_button.text = "Examiner"


# =================================================================== panneau VR

func _build_vr_panel() -> void:
	_vr_panel = Node3D.new()
	_vr_panel.name = "Inventaire_VR"
	_vr_panel.visible = false
	add_child(_vr_panel)
	var back := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(0.9, 0.62)
	back.mesh = q
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(0.025, 0.095, 0.145, 0.9)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	back.mesh.material = m
	_vr_panel.add_child(back)
	_vr_text = Label3D.new()
	_vr_text.font_size = 34
	_vr_text.pixel_size = 0.0011
	_vr_text.position = Vector3(0, 0, 0.005)
	_vr_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_vr_text.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_vr_text.width = 760
	_vr_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_vr_text.offset = Vector2(-380, 260)
	_vr_text.no_depth_test = true
	_vr_panel.add_child(_vr_text)


func _place_vr_panel() -> void:
	if main == null or main.xr_camera == null:
		return
	var head: Transform3D = main.xr_camera.global_transform
	var fwd: Vector3 = -head.basis.z
	fwd.y = 0.0
	fwd = fwd.normalized() if fwd.length() > 0.01 else Vector3.FORWARD
	_vr_panel.global_position = head.origin + fwd * 0.85 + Vector3.DOWN * 0.12
	_vr_panel.look_at(head.origin, Vector3.UP)
	_vr_panel.rotate_object_local(Vector3.UP, PI)


func _filled_indices() -> Array:
	var list: Array = []
	for i in range(slots.size()):
		if slots[i]["id"] != "":
			list.append(i)
	return list


func _refresh_vr() -> void:
	var list: Array = _filled_indices()
	var lines: Array = ["INVENTAIRE      En main : " + (str(ITEMS[equipped]["name"]) if equipped != "" else "mains nues"), ""]
	if list.is_empty():
		lines.append("Vide. Gâchette près d'un objet pour le ramasser.")
	_vr_sel = clampi(_vr_sel, 0, maxi(list.size() - 1, 0))
	for k in range(list.size()):
		var s: Dictionary = slots[list[k]]
		var mark: String = "> " if k == _vr_sel else "   "
		var eq: String = "  [en main]" if s["id"] == equipped else ""
		lines.append(mark + str(ITEMS[s["id"]]["name"]) + "  x" + str(s["n"]) + eq)
	if not list.is_empty():
		lines.append("")
		lines.append(str(ITEMS[slots[list[_vr_sel]]["id"]]["desc"]))
	lines.append("")
	lines.append("Stick droit : choisir   Gâchette : utiliser   Poignée : jeter   Y : fermer")
	_vr_text.text = "\n".join(lines)


## Appelé chaque image physique en VR quand le panneau est ouvert.
func vr_tick(stick_y: float, trigger: float, grip: float) -> void:
	var list: Array = _filled_indices()
	if absf(stick_y) < 0.3:
		_vr_neutral = true
	elif _vr_neutral and not list.is_empty():
		_vr_sel = wrapi(_vr_sel + (1 if stick_y < 0.0 else -1), 0, list.size())
		_vr_neutral = false
		_refresh_vr()
	var pressed: bool = trigger > 0.7 or grip > 0.8
	if pressed and _vr_trigger_ready and not list.is_empty():
		if trigger > 0.7:
			use_slot(list[_vr_sel])
		else:
			drop_slot(list[_vr_sel])
	_vr_trigger_ready = not pressed
