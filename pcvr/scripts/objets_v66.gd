extends Node3D
## V66 : des objets avec lesquels jouer.
##  - Des objets à casser (cassable_v66.gd) : les caisses et les tonneaux des villes, des
##    jarres et des pots dans les souterrains, des paniers au Bois-Doré, à Ramure et au souk de
##    Tazira. Ils se brisent en éclats qui volent et roulent, lâchent parfois un petit butin
##    (selon le pays : pièces, fruits, pain, bière, rarement une petite clé), font tomber ce
##    qui était posé dessus, et l'habitant d'à côté râle. Ils se reforment plus tard.
##  - Trente coffres cachés sur les îles (au village, dans la jungle, au Bois-Doré, sur la
##    Montagne de Feu, autour de Port-Azur, sur la grande île) : le couvercle s'ouvre, une
##    lueur dorée, le contenu saute dehors ; chacun compte comme une épreuve (expérience).
##    Un sur trois est fermé à clé : il faut une petite clé (on en trouve dans les autres
##    coffres et, rarement, dans les caisses et les jarres).
##  - À boire : bière, cidre, rhum, grog… se boivent pour de bon (le héros porte la chope à
##    sa bouche, glouglou, parfois un rot) même les cœurs pleins. L'alcool donne +1 de force
##    pendant deux minutes ; un verre de trop fait tanguer la caméra et zigzaguer la marche,
##    avec le hoquet (en VR : seulement le hoquet). Le thé et le café dégrisent.
##    Au comptoir des tavernes, on peut boire un verre sur place (Toni, Kiki, Ulfa, Mère
##    Gwenola, Mama Lou, Gaston, Zineb).

const Cassable = preload("res://scripts/cassable_v66.gd")

## [région, sorte, x, y, z, angle] : objets à casser ajoutés (villages, souterrains ; jamais dans
## un couloir : il faut au moins cinq mètres de large autour d'une jarre de souterrain).
const CASSES := [
	["village", "tonneau", -0.6, 5.45, -1.34, 1.52], ["village", "caisse", 18.45, 5.78, 7.54, 0.73], ["village", "caisse", -3.5, 4.99, 2.05, 1.34], ["village", "caisse", 2.86, 4.22, 22.76, 2.18],
	["village", "tonneau", 6.56, 6.26, 0.84, 3.86], ["village", "caisse", 21.08, 5.58, 1.03, 3.11], ["village", "caisse", -3.25, 4.95, 10.24, 2.99], ["village", "tonneau", -3.75, 6.71, -7.6, 2.93],
	["village", "tonneau", -4.25, 4.88, 5.84, 1.93], ["village", "caisse", -3.21, 4.62, 16.88, 0.06], ["elfes", "panier", 332.18, 14.22, -152.07, 5.28], ["elfes", "panier", 331.47, 14.22, -159.76, 3.52],
	["elfes", "pot", 324.04, 14.22, -171.6, 4.72], ["elfes", "panier", 330.3, 14.22, -160.36, 5.87], ["elfes", "panier", 350.64, 14.22, -164.15, 3.89], ["elfes", "pot", 343.7, 14.22, -149.42, 2.99],
	["elfes", "panier", 331.85, 14.22, -157.8, 2.13], ["elfes", "pot", 341.57, 14.22, -157.75, 0.47], ["ramure", "panier", 1096.1, 7.72, -119.33, 1.04], ["ramure", "tonneau", 1156.61, 5.78, -100.2, 4.47],
	["ramure", "tonneau", 1104.79, 7.08, -163.03, 5.95], ["ramure", "panier", 1100.74, 8.69, -112.9, 5.04], ["ramure", "panier", 1099.92, 8.25, -118.21, 6.01], ["ramure", "tonneau", 1106.72, 7.59, -179.28, 5.1],
	["ramure", "panier", 1105.32, 7.53, -179.18, 1.49], ["ramure", "tonneau", 1096.38, 8.0, -113.71, 5.75], ["ramure", "tonneau", 1163.1, 4.7, -94.58, 4.81], ["tazira", "jarre", 951.62, 4.37, 25.84, 2.35],
	["tazira", "panier", 956.58, 3.49, 41.03, 1.11], ["tazira", "jarre", 944.76, 3.78, 35.9, 0.35], ["tazira", "panier", 909.25, 1.4, 81.43, 1.86], ["tazira", "panier", 942.22, 4.27, 27.6, 4.86],
	["tazira", "panier", 913.5, 1.4, 83.65, 5.87], ["tazira", "jarre", 939.6, 3.18, 46.26, 5.57], ["tazira", "jarre", 934.82, 1.4, 80.2, 1.71], ["donjon", "pot", 337.51, -70.0, -204.11, 4.55],
	["donjon", "jarre", 993.03, -80.0, -273.94, 5.78], ["donjon", "jarre", 1003.44, -80.0, -276.74, 5.36], ["donjon", "pot", 340.72, -70.0, -188.25, 0.07], ["donjon", "jarre", -24.69, -113.0, -172.71, 1.35],
	["donjon", "jarre", 332.46, -70.0, -246.19, 2.51], ["donjon", "caisse", -28.31, -113.0, -136.19, 1.45], ["donjon", "jarre", -26.39, -113.0, -170.26, 1.26], ["donjon", "jarre", -33.26, -113.0, -209.53, 5.37],
	["donjon", "jarre", 342.1, -70.0, -245.88, 6.23], ["donjon", "jarre", -19.6, -70.0, -56.96, 1.08], ["donjon", "jarre", -18.91, -73.0, -220.66, 4.19], ["donjon", "pot", 327.41, -70.0, -251.31, 3.18],
	["donjon", "jarre", -27.74, -113.0, -144.51, 5.58], ["donjon", "jarre", 340.61, -70.0, -204.19, 2.82], ["donjon", "jarre", -46.84, -70.0, -284.1, 2.9], ["donjon", "pot", -149.13, -14.28, 198.55, 5.12],
	["donjon", "jarre", -28.76, -113.0, -205.3, 4.69], ["donjon", "jarre", -57.73, -70.0, -283.56, 3.0],
]

## [région, x, y, z, angle] : les coffres cachés (posés au sol, l'avant tourné vers l'intérieur de l'île).
const COFFRES := [
	["village", -28.55, 3.25, -29.11, 0.63], ["village", 21.02, 4.2, 27.1, -2.25], ["jungle", 76.04, 9.35, -307.33, -1.86],
	["jungle", -48.28, 19.15, -294.57, 2.2], ["jungle", 41.24, 14.64, -279.54, -2.46], ["jungle", -75.35, 2.96, -242.99, 2.43],
	["jungle", 52.12, 30.4, -309.73, -1.94], ["elfes", 327.71, 14.22, -192.83, 0.08], ["elfes", 344.78, 10.04, -100.07, -2.92],
	["elfes", 303.46, 9.36, -240.16, 0.34], ["elfes", 411.54, 9.5, -149.21, -1.76], ["nains", -278.85, 16.74, -123.53, -2.19],
	["nains", -374.19, 24.53, -120.73, 2.3], ["nains", -392.14, 29.53, -165.64, 1.48], ["azur", 274.52, 41.01, 269.61, 2.79],
	["azur", 307.13, 7.38, 86.68, -0.06], ["azur", 384.76, 2.5, 79.66, -0.61], ["azur", 377.1, 41.86, 167.55, -1.17],
	["azur", 350.66, 48.99, 234.4, -2.17], ["grande", 1125.83, 7.22, -74.05, -1.96], ["grande", 966.71, 11.67, -41.68, -2.9],
	["grande", 828.93, 3.54, 40.15, 2.61], ["grande", 661.29, 1.87, -43.64, 1.94], ["grande", 1048.49, 30.0, -273.31, -0.72],
	["grande", 1050.06, 2.63, 55.64, -2.65], ["grande", 755.01, 7.73, -266.49, 1.01], ["grande", 1120.19, 9.84, -252.59, -1.05],
	["grande", 1180.85, 1.94, -180.17, -1.45], ["grande", 782.66, 8.55, -41.65, 2.17], ["grande", 728.19, 2.16, -195.72, 1.36],
]
## Ce qu'un coffre contient selon le pays : [pièces min, max], objets possibles.
const COFFRE_BUTIN := {
	"village": [[10, 18], ["pomme", "baies", "champignon", "coquillage"]],
	"jungle": [[12, 22], ["noix_coco", "miel", "coquillage", "baies"]],
	"elfes": [[14, 24], ["pain_miel", "tisane_lune", "poussiere_fee", "baies"]],
	"nains": [[16, 28], ["biere_naine", "minerai_fer", "fromage_chevre", "champignon_braise"]],
	"azur": [[15, 26], ["croissant", "punch_coco", "coquillage", "biere_naine"]],
	"grande": [[20, 35], ["cidre_carene", "dattes", "rhum_murene", "galette_sarrasin", "pain_carotte"]],
}
## Région d'un coffre -> région des épreuves (page Héros).
const COFFRE_EP := {"village": "village", "jungle": "village", "elfes": "elfes", "nains": "nains", "azur": "azur", "grande": "grande"}

## Les îles (centre, rayon) pour savoir où l'on casse.
const ILES := [
	["village", Vector3(0, 0, 10), 160.0], ["jungle", Vector3(0, 0, -330), 175.0], ["elfes", Vector3(330, 0, -165), 150.0],
	["nains", Vector3(-330, 0, -160), 150.0], ["azur", Vector3(300, 0, 200), 215.0], ["grande", Vector3(940, 0, -150), 390.0],
	["celeste", Vector3(40, 0, 400), 130.0], ["fees", Vector3(-470, 0, 520), 170.0],
]
## Ce que lâche un objet cassé, selon le pays : à manger, à boire (tonneaux).
const MANGER := {
	"village": ["pomme", "baies", "champignon"], "jungle": ["noix_coco", "baies", "champignon"], "elfes": ["pain_miel", "baies", "champignon"],
	"nains": ["champignon_braise", "fromage_chevre"], "azur": ["croissant", "baguette", "pomme"], "carene": ["galette_sarrasin", "sardine", "pomme"],
	"tazira": ["dattes", "sardine"], "cliquetis": ["biscuit_engrenage", "pomme"], "ramure": ["pain_carotte", "baies", "pomme"],
	"grande": ["pomme", "baies"], "fees": ["baies", "champignon"], "celeste": ["pomme"], "ciel": ["pomme"], "donjon": ["champignon"],
}
const BOIRE := {
	"village": "cidre_carene", "jungle": "noix_coco", "elfes": "tisane_lune", "nains": "biere_naine", "azur": "biere_naine", "carene": "cidre_carene",
	"tazira": "rhum_murene", "cliquetis": "cafe_vapeur", "ramure": "tisane_brume", "grande": "cidre_carene", "fees": "nectar_fee",
}

## Ce qui se boit : [degré (+ ivre, - dégrise), effet particulier]
const BOISSONS := {
	"biere_naine": [0.35, ""], "cidre_carene": [0.25, ""], "rhum_murene": [0.5, ""], "grog_bordee": [0.4, ""],
	"punch_coco": [0.0, ""], "the_menthe": [-0.35, "the"], "cafe_vapeur": [-0.5, "cafe"], "nectar_fee": [0.0, "nectar"],
	"tisane_lune": [-0.2, "tisane"], "tisane_brume": [-0.2, "tisane"], "potion_seve": [0.0, ""], "noix_coco": [0.0, "coco"],
}
const FORCE_TEMPS: float = 120.0
const DEGRISE: float = 0.0075             # par seconde

## Au comptoir : pnj -> [boisson, prix, libellé]
const COMPTOIRS := {
	"toni": ["biere_naine", 4, "Une pression du Perroquet"],
	"kiki": ["punch_coco", 5, "Un punch coco à la paillote"],
	"ulfa": ["biere_naine", 3, "Une chope de la Chope Ardente"],
	"gwenola": ["cidre_carene", 3, "Une bolée de cidre"],
	"mamalou": ["rhum_murene", 4, "Un verre de rhum de la Murène"],
	"gaston": ["cafe_vapeur", 2, "Un café à vapeur au comptoir"],
	"zineb": ["the_menthe", 2, "Un thé à la menthe sur la terrasse"],
}

const PLAINTES := {
	"tu": ["Hé ! C'était à moi, ça !", "Mais ça va pas, non ?", "Tu vas me rembourser, j'espère !", "On ne casse pas ce qui n'est pas à soi !", "Tu l'as fait exprès ?", "Non mais je rêve…"],
	"vous": ["Hé ! C'était à moi, ça !", "Mais enfin, vous êtes fou ?", "Vous allez me rembourser, j'espère !", "On ne casse pas ce qui n'est pas à soi !", "Vous l'avez fait exprès ?", "Non mais je rêve…"],
}
const PLAINTE_SORTE := {"tonneau": "Mon tonneau ! Il était plein !", "jarre": "Ma jarre ! Elle venait de ma grand-mère !", "panier": "Mes fruits ! Tout par terre !", "pot": "Mon pot ! Mes herbes !", "caisse": "Ma caisse ! Toute ma marchandise !"}
const HAUSSE := ["Bah… il n'y avait plus grand-chose dedans.", "Pff. Encore un aventurier.", "Tant pis. Ça se recolle… peut-être.", "Ah, les jeunes…"]

var main: Node
var opened: Dictionary = {}               # « coffre66_<i> » -> true
var chests: Array = []                    # {id, i, region, locked, node, lid, lock, glint, light, coins, front, it}
var ivresse: float = 0.0
var verres: int = 0
var broken_total: int = 0
var _force_t: float = 0.0
var _hic_t: float = 6.0
var _debris: Array = []
var _uid: int = 0
var _complained: Dictionary = {}          # pnj -> instant
var _clock: float = 0.0
var _text_t: float = 0.0
var _rng := RandomNumberGenerator.new()
var _mesh: Dictionary = {}
var _wrapped: Dictionary = {}
var last_loot: Array = []                 # pour les tests : le dernier butin


func setup(main_node: Node) -> void:
	main = main_node
	Cassable.main = main
	Cassable.manager = self
	_rng.randomize()
	for e in CASSES:
		var sty: String = "tazira" if str(e[0]) == "tazira" else ("elfes" if str(e[0]) == "elfes" else ("donjon" if str(e[0]) == "donjon" else ""))
		Cassable.spawn(self, str(e[1]), Vector3(float(e[2]), float(e[3]), float(e[4])), float(e[5]), 0.8 if str(e[1]) == "caisse" else 1.0, str(e[0]), sty)
	for i in COFFRES.size():
		_build_chest(i)
	if main.get("inventory_v28") != null and main.inventory_v28 != null:
		main.inventory_v28.on_drink = on_drink
	if main.get("journal_v56") != null and main.journal_v56 != null:
		register_services(main.journal_v56)
	print("ILE_MANGA_V66: ", CASSES.size(), " objets à casser ajoutés, ", get_tree().get_nodes_in_group("cassables_v66").size(), " en tout ; ", chests.size(), " coffres")


# =================================================================== où sommes-nous ?

static func region_at(p: Vector3) -> String:
	if p.y < -4.0:
		return "donjon"
	if p.y > 150.0:
		return "ciel"
	var best: String = ""
	var best_k: float = INF
	for e in ILES:
		var c: Vector3 = e[1]
		var k: float = Vector2(p.x - c.x, p.z - c.z).length() / float(e[2])
		if k < best_k:
			best_k = k
			best = str(e[0])
	return best


## Le pays précis (les villes de la grande île ont chacune leur butin).
func zone_at(p: Vector3) -> String:
	var r: String = region_at(p)
	if r != "grande" or main == null or main.get("grande_v59") == null or main.grande_v59 == null:
		return r
	var g: Node = main.grande_v59
	for nm in ["tazira", "cliquetis", "ramure"]:
		var town: Variant = g.get(nm)
		if town != null and is_instance_valid(town) and town.has_method("contains") and bool(town.contains(p)):
			return nm
	if Vector2(p.x - 665.0, p.z + 150.0).length() < 110.0:
		return "carene"
	return "grande"


# =================================================================== objets cassés

## Appelé par un objet qui se brise : éclats, poussière, butin, ce qui tombe, l'habitant qui râle.
func on_shatter(c: Node3D, dir: Vector3) -> void:
	broken_total += 1
	var k: String = str(c.kind)
	var at: Vector3 = c.global_position
	var ground: float = _ground_below(at + Vector3.UP * 0.3, [])
	if is_inf(ground):
		ground = at.y
	_spawn_debris(c, dir, ground)
	var dust: Color = Cassable.KINDS[k]["poussiere"]
	_dust(c.center(), dust, 16 if k in ["caisse", "tonneau"] else 10)
	if main.get("combat_v28") != null and main.combat_v28 != null:
		main.combat_v28.puff(c.center(), dust)
	var zone: String = str(c.region) if str(c.region) != "" else zone_at(at)
	_loot(k, zone, at, ground)
	# ce qui était posé dessus tombe
	for o in get_tree().get_nodes_in_group("cassables_v66"):
		if o == c or bool(o.broken):
			continue
		var op: Vector3 = o.global_position
		if Vector2(op.x - at.x, op.z - at.z).length() > (float(c.hit_radius) + float(o.hit_radius)) * 0.8:
			continue
		if op.y < at.y + 0.15 or op.y > at.y + float(c.height) + 0.3:
			continue
		var gy: float = _ground_below(op + Vector3.UP * 0.05, [o._body.get_rid()])
		o.fall_to(gy if not is_inf(gy) else at.y)
	_complain(c, k)


func on_restore(c: Node3D) -> void:
	var at: Vector3 = c.global_position
	for o in get_tree().get_nodes_in_group("cassables_v66"):
		if o == c or not bool(o.displaced) or bool(o.broken):
			continue
		var hp: Vector3 = (o.get_parent() as Node3D).global_transform * (o.home as Transform3D).origin
		if Vector2(hp.x - at.x, hp.z - at.z).length() < (float(c.hit_radius) + float(o.hit_radius)) * 0.8:
			o.transform = o.home
			o.displaced = false


## Ce qui porte c (à sa place d'origine) est-il cassé ?
func support_broken(c: Node3D) -> bool:
	var hp: Vector3 = (c.get_parent() as Node3D).global_transform * (c.home as Transform3D).origin
	for o in get_tree().get_nodes_in_group("cassables_v66"):
		if o == c or not bool(o.broken):
			continue
		var op: Vector3 = o.global_position
		if Vector2(hp.x - op.x, hp.z - op.z).length() < (float(c.hit_radius) + float(o.hit_radius)) * 0.8 and hp.y > op.y + 0.15 and hp.y < op.y + float(o.height) + 0.3:
			return true
	return false


func _ground_below(from: Vector3, exclude: Array) -> float:
	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * 8.0, 1, exclude)
	var hit := space.intersect_ray(q)
	return float((hit["position"] as Vector3).y) if not hit.is_empty() else INF


## Le butin d'un objet cassé (rien, souvent).
func _loot(k: String, zone: String, at: Vector3, ground: float) -> void:
	var out: Array = []
	var roll: float = _rng.randf()
	match k:
		"panier":
			if roll < 0.7:
				out.append([_pick(MANGER.get(zone, ["pomme"])), _rng.randi_range(1, 2)])
			elif roll < 0.85:
				out.append(["piece", 1])
		"tonneau":
			if roll < 0.35 and BOIRE.has(zone):
				out.append([str(BOIRE[zone]), 1])
			elif roll < 0.65:
				out.append(["piece", _rng.randi_range(1, 3)])
		"caisse":
			if roll < 0.4:
				out.append(["piece", _rng.randi_range(1, 3)])
			elif roll < 0.62:
				out.append([_pick(MANGER.get(zone, ["pomme"])), 1])
			elif roll < 0.72:
				out.append([_pick(["baton", "caillou"] if zone != "nains" else ["minerai_fer", "caillou"]), 1])
		_:
			if roll < 0.5:
				out.append(["piece", _rng.randi_range(2, 6) if zone == "donjon" else _rng.randi_range(1, 4)])
			elif roll < 0.62:
				out.append([_pick(MANGER.get(zone, ["pomme"])), 1])
			elif roll < 0.7 and zone in ["village", "azur", "tazira", "carene", "jungle"]:
				out.append(["coquillage", 1])
			elif roll < 0.74 and zone == "donjon":
				out.append([_pick(["rubis", "perle"]), 1])
	# rarement, une petite clé (pas dans les paniers)
	if k != "panier" and _rng.randf() < (0.06 if zone == "donjon" else 0.035):
		out.append(["petite_cle", 1])
	last_loot = out
	var inv: Node = main.get("inventory_v28")
	if inv == null:
		return
	var j: int = 0
	for e in out:
		if not inv.ITEMS.has(str(e[0])):
			continue
		var a: float = _rng.randf() * TAU
		var spot: Vector3 = Vector3(at.x + cos(a) * 0.35 * (j + 1), ground + 0.02, at.z + sin(a) * 0.35 * (j + 1))
		_uid += 1
		inv.drop_counter += 1
		inv.spawn_pickup("casse66_%d_%d" % [inv.drop_counter, _uid], str(e[0]), int(e[1]), spot)
		j += 1


func _pick(a: Array) -> String:
	return str(a[_rng.randi() % a.size()])


## L'habitant le plus proche le fait savoir (ou hausse les épaules).
func _complain(c: Node3D, k: String) -> void:
	var at: Vector3 = c.global_position
	var best: Node3D = null
	var best_d: float = 9.0
	for n in main.get("npcs_v31") if main.get("npcs_v31") != null else []:
		if not is_instance_valid(n) or not (n as Node3D).is_visible_in_tree() or str(n.get("state")) == "parle":
			continue
		var np: Vector3 = (n as Node3D).global_position
		if absf(np.y - at.y) > 4.0:
			continue
		var d: float = Vector2(np.x - at.x, np.z - at.z).length()
		if d < best_d:
			best_d = d
			best = n
	if best == null or best.get("brain") == null:
		return
	var id: String = str((best.get("profile") as Dictionary).get("id", ""))
	if _clock - float(_complained.get(id, -99.0)) < 8.0:
		return
	_complained[id] = _clock
	var line: String
	if _rng.randf() < 0.25:
		line = _pick(HAUSSE)
	else:
		var vous: bool = bool(best.brain.get("vous")) if best.brain.get("vous") != null else false
		line = PLAINTE_SORTE.get(k, "") if _rng.randf() < 0.4 else _pick(PLAINTES["vous" if vous else "tu"])
		if line == "":
			line = _pick(PLAINTES["vous" if vous else "tu"])
		if best.has_method("gesture"):
			best.gesture("colere")
		if best.brain.has_method("_bond"):
			best.brain._bond(-1.0)
	if best.has_method("say_bubble"):
		best.say_bubble(line, 3.2)


# =================================================================== éclats et poussière

func _dmesh(key: String) -> Mesh:
	if _mesh.has(key):
		return _mesh[key]
	var m: Mesh
	match key:
		"planche":
			var b := BoxMesh.new()
			b.size = Vector3(0.9, 0.022, 0.22)
			b.material = Cassable.mat("caisse")
			m = b
		"tasseau":
			var b2 := BoxMesh.new()
			b2.size = Vector3(0.95, 0.08, 0.08)
			b2.material = Cassable.mat("cadre")
			m = b2
		"douelle":
			var b3 := BoxMesh.new()
			b3.size = Vector3(0.11, 0.88, 0.026)
			b3.material = Cassable.mat("douelles")
			m = b3
		"cercle":
			var t := TorusMesh.new()
			t.inner_radius = 0.3
			t.outer_radius = 0.33
			t.rings = 20
			t.ring_segments = 4
			t.material = Cassable.mat("fer")
			m = t
		"fond":
			var cy := CylinderMesh.new()
			cy.top_radius = 0.27
			cy.bottom_radius = 0.27
			cy.height = 0.03
			cy.radial_segments = 16
			cy.material = Cassable.mat("douelles")
			m = cy
		"tesson":
			var b4 := BoxMesh.new()
			b4.size = Vector3(0.12, 0.1, 0.018)
			b4.material = Cassable.mat("terre")
			m = b4
		"brin":
			var b5 := BoxMesh.new()
			b5.size = Vector3(0.3, 0.016, 0.035)
			b5.material = Cassable.mat("osier")
			m = b5
		_:
			# fruit_<couleur>
			var s := SphereMesh.new()
			s.radius = 0.055
			s.height = 0.105
			s.radial_segments = 12
			s.rings = 6
			var fm := StandardMaterial3D.new()
			fm.albedo_color = Color.html(key.trim_prefix("fruit_"))
			fm.roughness = 0.4
			s.material = fm
			m = s
	_mesh[key] = m
	return m


func _spawn_debris(c: Node3D, dir: Vector3, ground: float) -> void:
	var k: String = str(c.kind)
	var sc: Vector3 = c._scale
	var parts: Array = []           # [maillage, échelle, combien]
	match k:
		"caisse":
			parts = [["planche", sc, 7], ["tasseau", sc, 4]]
		"tonneau":
			parts = [["douelle", Vector3(sc.x, sc.y, sc.x), 9], ["cercle", sc, 2], ["fond", sc, 1]]
		"jarre":
			parts = [["tesson", Vector3.ONE, 14]]
		"pot":
			parts = [["tesson", Vector3.ONE * 0.8, 9]]
		"panier":
			parts = [["brin", Vector3.ONE, 9], ["fruit_b51a14", Vector3.ONE, 2], ["fruit_f08c1a", Vector3.ONE, 1], ["fruit_9cb535", Vector3.ONE, 1]]
	var center: Vector3 = c.center()
	for p in parts:
		for i in int(p[2]):
			var mi := MeshInstance3D.new()
			mi.mesh = _dmesh(str(p[0]))
			var s: Vector3 = p[1]
			if str(p[0]) in ["tesson", "brin"]:
				s *= _rng.randf_range(0.55, 1.25)
			mi.scale = s
			add_child(mi)
			var off := Vector3(_rng.randf_range(-1, 1), _rng.randf_range(-0.6, 0.6), _rng.randf_range(-1, 1)) * float(c.hit_radius) * 0.7
			mi.global_position = center + off
			mi.rotation = Vector3(_rng.randf() * TAU, _rng.randf() * TAU, _rng.randf() * TAU)
			var out: Vector3 = off.normalized() if off.length() > 0.01 else Vector3(1, 0, 0)
			var v: Vector3 = out * _rng.randf_range(1.0, 2.6) + dir * _rng.randf_range(0.6, 1.8) + Vector3.UP * _rng.randf_range(1.2, 3.4)
			var roll: bool = str(p[0]).begins_with("fruit") or str(p[0]) == "cercle"
			_debris.append({"node": mi, "vel": v, "spin": Vector3(_rng.randf_range(-9, 9), _rng.randf_range(-9, 9), _rng.randf_range(-9, 9)),
				"life": 0.0, "ground": ground + (0.05 if roll else 0.012 * s.y), "roll": roll, "rest": false})


func _dust(at: Vector3, col: Color, amount: int) -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.amount = amount
	p.lifetime = 1.6
	p.explosiveness = 0.9
	p.direction = Vector3.UP
	p.spread = 80.0
	p.initial_velocity_min = 0.4
	p.initial_velocity_max = 1.4
	p.gravity = Vector3(0, 0.25, 0)
	p.damping_min = 1.5
	p.damping_max = 2.5
	p.scale_amount_min = 1.0
	p.scale_amount_max = 2.2
	var curve := Curve.new()
	curve.add_point(Vector2(0, 0.5))
	curve.add_point(Vector2(1, 1.4))
	p.scale_amount_curve = curve
	var grad := Gradient.new()
	grad.set_color(0, Color(col.r, col.g, col.b, 0.55))
	grad.set_color(1, Color(col.r, col.g, col.b, 0.0))
	p.color_ramp = grad
	var q := QuadMesh.new()
	q.size = Vector2(0.35, 0.35)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.vertex_color_use_as_albedo = true
	if main.has_method("_soft_dot_v24"):
		m.albedo_texture = main._soft_dot_v24()
	q.material = m
	p.mesh = q
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(p)
	p.global_position = at
	p.emitting = true
	get_tree().create_timer(2.2).timeout.connect(p.queue_free)


func _tick_debris(delta: float) -> void:
	for i in range(_debris.size() - 1, -1, -1):
		var d: Dictionary = _debris[i]
		d["life"] = float(d["life"]) + delta
		var node: MeshInstance3D = d["node"]
		if not is_instance_valid(node):
			_debris.remove_at(i)
			continue
		var v: Vector3 = d["vel"]
		var g: float = float(d["ground"])
		if not bool(d["rest"]):
			v.y -= 13.0 * delta
			node.global_position += v * delta
			node.rotation += (d["spin"] as Vector3) * delta
			if node.global_position.y <= g:
				node.global_position.y = g
				if v.y < -1.6:
					v.y = -v.y * 0.3
					v.x *= 0.55
					v.z *= 0.55
					d["spin"] = (d["spin"] as Vector3) * 0.5
				else:
					v = Vector3.ZERO
					d["rest"] = true
					if not bool(d["roll"]):
						# à plat sur le sol
						node.rotation = Vector3(0, node.rotation.y, 0)
			d["vel"] = v
		elif bool(d["roll"]) and float(d["life"]) < 3.0:
			node.global_position += Vector3(cos(float(d["life"]) * 3.0), 0, sin(float(d["life"]) * 3.0)) * delta * 0.15
		if float(d["life"]) > 6.0:
			node.scale = node.scale * clampf(1.0 - (float(d["life"]) - 6.0) * 2.0 * delta * 10.0, 0.0, 1.0)
		if float(d["life"]) > 7.0:
			node.queue_free()
			_debris.remove_at(i)


# =================================================================== coffres

func _chest_mesh(part: String) -> ArrayMesh:
	if _mesh.has("coffre_" + part):
		return _mesh["coffre_" + part]
	var am := ArrayMesh.new()
	var W: float = 0.9
	var D: float = 0.55
	var H: float = 0.46
	var R: float = D * 0.5
	match part:
		"corps":
			var st := Cassable._new_st()
			Cassable._box(st, Vector3(0, H * 0.5, 0), Vector3(W, H, D))
			Cassable._add(am, st, _chest_mat("coffre"))
			var st2 := Cassable._new_st()
			# fond intérieur sombre (vu quand le couvercle est ouvert)
			Cassable._quad(st2, Vector3(-W * 0.46, H + 0.002, -D * 0.44), Vector3(W * 0.46, H + 0.002, -D * 0.44), Vector3(W * 0.46, H + 0.002, D * 0.44), Vector3(-W * 0.46, H + 0.002, D * 0.44), Vector3.UP, Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1))
			Cassable._add(am, st2, _chest_mat("fond"))
			var st3 := Cassable._new_st()
			# ferrures : deux sangles, coins, plaque de serrure
			for sx: float in [-0.3, 0.3]:
				Cassable._box(st3, Vector3(sx, H * 0.5, D * 0.5 + 0.006), Vector3(0.07, H, 0.012), 0.3)
				Cassable._box(st3, Vector3(sx, H * 0.5, -D * 0.5 - 0.006), Vector3(0.07, H, 0.012), 0.3)
				Cassable._box(st3, Vector3(sx, 0.006, 0), Vector3(0.07, 0.012, D + 0.024), 0.3)
			for cx: float in [-1.0, 1.0]:
				for cz: float in [-1.0, 1.0]:
					Cassable._box(st3, Vector3(cx * (W * 0.5 - 0.03), 0.05, cz * (D * 0.5 - 0.03)), Vector3(0.075, 0.1, 0.075), 0.3)
			Cassable._box(st3, Vector3(0, H - 0.09, D * 0.5 + 0.012), Vector3(0.13, 0.15, 0.016), 0.3)
			Cassable._add(am, st3, Cassable.mat("fer"))
			var st4 := Cassable._new_st()
			Cassable._box(st4, Vector3(0, H - 0.1, D * 0.5 + 0.0215), Vector3(0.022, 0.05, 0.004))
			Cassable._add(am, st4, Cassable.mat("interieur"))
		"couvercle":
			# demi-cylindre couché (axe X), charnière à l'arrière : le repère du couvercle est la charnière
			var st5 := Cassable._new_st()
			var seg: int = 12
			for i in seg:
				var a0: float = PI * i / seg
				var a1: float = PI * (i + 1) / seg
				var n0 := Vector3(0, sin(a0), cos(a0))
				var n1 := Vector3(0, sin(a1), cos(a1))
				var c := Vector3(0, 0, R)
				var p00: Vector3 = c + n0 * R + Vector3(-W * 0.5, 0, 0)
				var p01: Vector3 = c + n0 * R + Vector3(W * 0.5, 0, 0)
				var p11: Vector3 = c + n1 * R + Vector3(W * 0.5, 0, 0)
				var p10: Vector3 = c + n1 * R + Vector3(-W * 0.5, 0, 0)
				var nm: Vector3 = (n0 + n1).normalized()
				Cassable._quad(st5, p00, p01, p11, p10, nm, Vector2(0, float(i) / seg), Vector2(1, float(i) / seg), Vector2(1, float(i + 1) / seg), Vector2(0, float(i + 1) / seg))
			# joues (demi-disques) et dessous
			for sx2: float in [-1.0, 1.0]:
				for i2 in seg:
					var b0: float = PI * i2 / seg
					var b1: float = PI * (i2 + 1) / seg
					var cc := Vector3(sx2 * W * 0.5, 0, R)
					var q0: Vector3 = cc + Vector3(0, sin(b0), cos(b0)) * R
					var q1: Vector3 = cc + Vector3(0, sin(b1), cos(b1)) * R
					Cassable._quad(st5, cc, q0, q1, cc, Vector3(sx2, 0, 0), Vector2(0.5, 0), Vector2(0.5 + cos(b0) * 0.5, sin(b0) * 0.5), Vector2(0.5 + cos(b1) * 0.5, sin(b1) * 0.5), Vector2(0.5, 0))
			Cassable._quad(st5, Vector3(-W * 0.5, 0, 0), Vector3(W * 0.5, 0, 0), Vector3(W * 0.5, 0, D), Vector3(-W * 0.5, 0, D), Vector3.DOWN, Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1))
			Cassable._add(am, st5, _chest_mat("coffre"))
			var st6 := Cassable._new_st()
			for sx3: float in [-0.3, 0.3]:
				for i3 in seg:
					var e0: float = PI * i3 / seg
					var e1: float = PI * (i3 + 1) / seg
					var m0 := Vector3(0, sin(e0), cos(e0))
					var m1 := Vector3(0, sin(e1), cos(e1))
					var cz := Vector3(sx3, 0, R)
					var rr: float = R + 0.008
					Cassable._quad(st6, cz + m0 * rr + Vector3(-0.035, 0, 0), cz + m0 * rr + Vector3(0.035, 0, 0), cz + m1 * rr + Vector3(0.035, 0, 0), cz + m1 * rr + Vector3(-0.035, 0, 0), (m0 + m1).normalized(), Vector2(0, 0), Vector2(0.1, 0), Vector2(0.1, 0.1), Vector2(0, 0.1))
			# moraillon (la patte qui descend sur la serrure)
			Cassable._box(st6, Vector3(0, -0.03, D + 0.014), Vector3(0.06, 0.11, 0.012), 0.3)
			Cassable._add(am, st6, Cassable.mat("fer"))
		"cadenas":
			var st7 := Cassable._new_st()
			Cassable._box(st7, Vector3(0, 0, 0), Vector3(0.09, 0.08, 0.035), 0.3)
			Cassable._add(am, st7, _chest_mat("laiton"))
			var st8 := Cassable._new_st()
			var seg2: int = 10
			for i4 in seg2:
				var f0: float = PI * i4 / seg2
				var f1: float = PI * (i4 + 1) / seg2
				var p0 := Vector3(cos(f0) * 0.03, 0.04 + sin(f0) * 0.04, 0)
				var p1 := Vector3(cos(f1) * 0.03, 0.04 + sin(f1) * 0.04, 0)
				var mid: Vector3 = (p0 + p1) * 0.5
				var dd: Vector3 = p1 - p0
				var bb := Basis.looking_at(dd.normalized(), Vector3(0, 0, 1))
				var tmp := Cassable._new_st()
				Cassable._box(tmp, Vector3.ZERO, Vector3(0.012, 0.012, dd.length() + 0.004), 0.3)
				var arr: Array = tmp.commit_to_arrays()
				var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
				var ns: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
				for v in vs.size():
					st8.set_normal((bb * ns[v]).normalized())
					st8.set_uv(Vector2(0, 0))
					st8.add_vertex(mid + bb * vs[v])
			Cassable._add(am, st8, Cassable.mat("fer"))
		"pieces":
			# un tas de pièces rondes (et quelques-unes de chant)
			var st9 := Cassable._new_st()
			var r2 := RandomNumberGenerator.new()
			r2.seed = 66
			for k in 34:
				var pos := Vector3(r2.randf_range(-0.3, 0.3), H + 0.006 + r2.randf() * 0.05 * (1.0 - absf(r2.randf_range(-1, 1))), r2.randf_range(-0.17, 0.17))
				var tilt := Basis(Vector3(r2.randf_range(-1, 1), 0, r2.randf_range(-1, 1)).normalized(), r2.randf_range(0.0, 0.5))
				var seg3: int = 10
				for i5 in seg3:
					var g0: float = TAU * i5 / seg3
					var g1: float = TAU * (i5 + 1) / seg3
					var rr2: float = 0.022
					for face: float in [1.0, -1.0]:
						var cen: Vector3 = pos + tilt * Vector3(0, 0.003 * face, 0)
						var q0b: Vector3 = pos + tilt * Vector3(cos(g0) * rr2, 0.003 * face, sin(g0) * rr2)
						var q1b: Vector3 = pos + tilt * Vector3(cos(g1) * rr2, 0.003 * face, sin(g1) * rr2)
						Cassable._quad(st9, cen, q0b, q1b, cen, (tilt * Vector3.UP * face).normalized(), Vector2(0.5, 0.5), Vector2(0, 0), Vector2(1, 0), Vector2(0.5, 0.5))
					var s0b: Vector3 = pos + tilt * Vector3(cos(g0) * rr2, -0.003, sin(g0) * rr2)
					var s1b: Vector3 = pos + tilt * Vector3(cos(g1) * rr2, -0.003, sin(g1) * rr2)
					var t0b: Vector3 = pos + tilt * Vector3(cos(g0) * rr2, 0.003, sin(g0) * rr2)
					var t1b: Vector3 = pos + tilt * Vector3(cos(g1) * rr2, 0.003, sin(g1) * rr2)
					Cassable._quad(st9, s0b, s1b, t1b, t0b, (tilt * Vector3(cos((g0 + g1) * 0.5), 0, sin((g0 + g1) * 0.5))).normalized(), Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1))
			Cassable._add(am, st9, _chest_mat("or"))
	_mesh["coffre_" + part] = am
	return am


func _chest_mat(key: String) -> Material:
	if _mesh.has("mat_" + key):
		return _mesh["mat_" + key]
	var m := StandardMaterial3D.new()
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	match key:
		"coffre":
			if ResourceLoader.exists(Cassable.TEX + "coffre.png"):
				m.albedo_texture = load(Cassable.TEX + "coffre.png")
			if ResourceLoader.exists(Cassable.TEX + "coffre_n.png"):
				m.normal_enabled = true
				m.normal_texture = load(Cassable.TEX + "coffre_n.png")
			m.roughness = 0.6
		"fond":
			if ResourceLoader.exists(Cassable.TEX + "coffre.png"):
				m.albedo_texture = load(Cassable.TEX + "coffre.png")
			m.albedo_color = Color(0.32, 0.27, 0.24)
			m.roughness = 0.9
		"laiton":
			m.albedo_color = Color(0.74, 0.56, 0.26)
			m.metallic = 0.85
			m.roughness = 0.35
		"or":
			m.albedo_color = Color(1.0, 0.78, 0.3)
			m.metallic = 1.0
			m.roughness = 0.25
			m.emission_enabled = true
			m.emission = Color(1.0, 0.7, 0.2)
			m.emission_energy_multiplier = 0.35
	_mesh["mat_" + key] = m
	return m


func _build_chest(i: int) -> void:
	var e: Array = COFFRES[i]
	var root := Node3D.new()
	root.name = "Coffre_v66_%d" % i
	add_child(root)
	root.global_position = Vector3(float(e[1]), float(e[2]) - 0.03, float(e[3]))
	root.rotation.y = float(e[4])
	var body := MeshInstance3D.new()
	body.name = "Corps"
	body.mesh = _chest_mesh("corps")
	body.visibility_range_end = 120.0
	root.add_child(body)
	var hinge := Node3D.new()
	hinge.name = "Charniere"
	hinge.position = Vector3(0, 0.46, -0.275)
	root.add_child(hinge)
	var lid := MeshInstance3D.new()
	lid.name = "Couvercle"
	lid.mesh = _chest_mesh("couvercle")
	lid.visibility_range_end = 120.0
	hinge.add_child(lid)
	var coins := MeshInstance3D.new()
	coins.name = "Pieces"
	coins.mesh = _chest_mesh("pieces")
	coins.visible = false
	root.add_child(coins)
	var locked: bool = i % 3 == 2
	var lock: MeshInstance3D = null
	if locked:
		lock = MeshInstance3D.new()
		lock.name = "Cadenas"
		lock.mesh = _chest_mesh("cadenas")
		lock.position = Vector3(0, 0.37, 0.275 + 0.04)
		root.add_child(lock)
	var sb := StaticBody3D.new()
	sb.collision_layer = 1
	sb.collision_mask = 0
	root.add_child(sb)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(0.92, 0.72, 0.57)
	cs.shape = bs
	cs.position = Vector3(0, 0.36, 0)
	sb.add_child(cs)
	# un éclat doré de temps en temps, pour qui ouvre l'œil
	var glint := CPUParticles3D.new()
	glint.name = "Eclat"
	glint.amount = 3
	glint.lifetime = 1.4
	glint.direction = Vector3.UP
	glint.spread = 30.0
	glint.initial_velocity_min = 0.05
	glint.initial_velocity_max = 0.2
	glint.gravity = Vector3.ZERO
	glint.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	glint.emission_box_extents = Vector3(0.45, 0.2, 0.3)
	var gq := QuadMesh.new()
	gq.size = Vector2(0.09, 0.09)
	var gm := StandardMaterial3D.new()
	gm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	gm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	gm.albedo_color = Color(1.0, 0.85, 0.45, 0.9)
	if main.has_method("_soft_dot_v24"):
		gm.albedo_texture = main._soft_dot_v24()
	gq.material = gm
	glint.mesh = gq
	glint.position = Vector3(0, 0.55, 0)
	glint.visibility_range_end = 35.0
	glint.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(glint)
	var front: Vector3 = root.global_transform * Vector3(0, 0, 0.95)
	var ch := {"id": "coffre66_%d" % i, "i": i, "region": str(e[0]), "locked": locked, "node": root, "lid": hinge, "lock": lock,
		"glint": glint, "coins": coins, "front": front}
	var it := {"id": ch["id"], "pos": front, "radius": 1.5, "text": "", "vr": "", "call": func(): open_chest(i), "when": func(): return not opened.has(ch["id"])}
	ch["it"] = it
	chests.append(ch)
	_chest_text(ch)
	if main.get("donjon_v35") != null and main.donjon_v35 != null:
		main.donjon_v35._interactions.append(it)


func _chest_text(ch: Dictionary) -> void:
	var it: Dictionary = ch["it"]
	if not bool(ch["locked"]):
		it["text"] = "E : ouvrir le coffre"
		it["vr"] = "Gâchette : ouvrir le coffre"
	elif _keys() > 0:
		it["text"] = "E : ouvrir le coffre avec une petite clé"
		it["vr"] = "Gâchette : ouvrir avec une petite clé"
	else:
		it["text"] = "E : un coffre fermé à clé"
		it["vr"] = "Gâchette : coffre fermé à clé"


func _keys() -> int:
	var inv: Node = main.get("inventory_v28")
	return int(inv.count("petite_cle")) if inv != null else 0


func _show(entry_ch: Dictionary, opened_now: bool) -> void:
	var hinge: Node3D = entry_ch["lid"]
	hinge.rotation.x = -1.95 if opened_now else 0.0
	if entry_ch["lock"] != null:
		(entry_ch["lock"] as Node3D).visible = not opened_now
	(entry_ch["glint"] as CPUParticles3D).emitting = not opened_now
	(entry_ch["coins"] as Node3D).visible = false


## Ouvrir le coffre i (E ou la gâchette devant lui).
func open_chest(i: int) -> void:
	var ch: Dictionary = chests[i]
	if opened.has(ch["id"]):
		return
	var root: Node3D = ch["node"]
	var center: Vector3 = root.global_transform * Vector3(0, 0.5, 0)
	if bool(ch["locked"]):
		if _keys() <= 0:
			main.sfx("coffre_verrou", center)
			_say("Fermé à clé. Une petite clé l'ouvrirait… On en trouve dans les autres coffres, et parfois dans les caisses et les jarres.")
			var tw0 := create_tween()
			var lk: Node3D = ch["lock"]
			if lk != null:
				tw0.tween_property(lk, "rotation:z", 0.25, 0.06)
				tw0.tween_property(lk, "rotation:z", -0.2, 0.08)
				tw0.tween_property(lk, "rotation:z", 0.0, 0.06)
			return
		main.inventory_v28.remove("petite_cle", 1)
		main.sfx("serrure", center)
		if ch["lock"] != null:
			var lk2: Node3D = ch["lock"]
			var tw1 := create_tween()
			tw1.tween_property(lk2, "position:y", lk2.position.y - 0.4, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tw1.tween_callback(func(): lk2.visible = false)
	opened[ch["id"]] = true
	(ch["glint"] as CPUParticles3D).emitting = false
	if main.hero_v28 != null and not main.xr_active:
		main.hero_v28.play_action("pickup", center)
	main.sfx("coffre", center)
	var hinge: Node3D = ch["lid"]
	var tw := create_tween()
	tw.tween_interval(0.45 if bool(ch["locked"]) else 0.15)
	tw.tween_property(hinge, "rotation:x", -1.95, 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var coins: Node3D = ch["coins"]
	coins.visible = true
	# lueur dorée
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.78, 0.4)
	light.light_energy = 0.0
	light.omni_range = 4.0
	light.position = Vector3(0, 0.75, 0)
	root.add_child(light)
	var tl := create_tween()
	tl.tween_interval(0.35)
	tl.tween_property(light, "light_energy", 3.0, 0.35)
	tl.tween_property(light, "light_energy", 0.0, 1.6)
	tl.tween_callback(light.queue_free)
	get_tree().create_timer(1.3).timeout.connect(func(): coins.visible = false)
	_sparkle(root.global_transform * Vector3(0, 0.6, 0))
	if main.has_method("jingle"):
		main.jingle("decouverte")
	# le contenu saute dehors
	var loot: Array = chest_loot(i)
	var names: Array = []
	var inv: Node = main.inventory_v28
	var j: int = 0
	for e in loot:
		var a: float = -0.7 + 1.4 * float(j) / maxf(float(loot.size() - 1), 1.0)
		var spot: Vector3 = root.global_transform * Vector3(sin(a) * 0.9, 0.0, 0.75 + cos(a) * 0.35)
		var gy: float = _ground_below(spot + Vector3.UP * 1.2, [])
		spot.y = (gy if not is_inf(gy) else root.global_position.y) + 0.02
		inv.drop_counter += 1
		inv.spawn_pickup("coffre66_%d_%d" % [i, j], str(e[0]), int(e[1]), spot)
		var nm: String = str(inv.ITEMS[str(e[0])]["art"]) if int(e[1]) <= 1 else ("%d pièces" % int(e[1]) if str(e[0]) == "piece" else "%d × %s" % [int(e[1]), str(inv.ITEMS[str(e[0])]["name"]).to_lower()])
		names.append(nm)
		j += 1
	last_loot = loot
	_say("Un coffre caché ! Dedans : %s." % ", ".join(names), 6.0)
	var pr: Node = main.get("progression_v63")
	if pr != null and pr.has_method("on_chest"):
		pr.on_chest(center + Vector3.UP * 0.6)


## Le contenu (toujours le même pour un coffre donné).
func chest_loot(i: int) -> Array:
	var e: Array = COFFRES[i]
	var b: Array = COFFRE_BUTIN.get(str(e[0]), COFFRE_BUTIN["village"])
	var r := RandomNumberGenerator.new()
	r.seed = 66600 + i
	var out: Array = []
	var lo: int = int(b[0][0])
	var hi: int = int(b[0][1])
	out.append(["piece", r.randi_range(lo, hi) + (12 if i % 3 == 2 else 0)])
	var items: Array = (b[1] as Array).duplicate()
	var a: String = str(items[r.randi() % items.size()])
	items.erase(a)
	out.append([a, r.randi_range(1, 2)])
	match i % 3:
		0:
			out.append(["petite_cle", 1])
		1:
			out.append([str(items[r.randi() % items.size()]), 1])
		2:
			out.append(["piece_or", 1])
			out.append([["rubis", "perle"][r.randi() % 2], 1])
	return out


func _sparkle(at: Vector3) -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.amount = 40
	p.lifetime = 1.3
	p.explosiveness = 0.8
	p.direction = Vector3.UP
	p.spread = 35.0
	p.initial_velocity_min = 1.2
	p.initial_velocity_max = 3.0
	p.gravity = Vector3(0, -2.5, 0)
	p.scale_amount_min = 0.4
	p.scale_amount_max = 1.0
	var q := QuadMesh.new()
	q.size = Vector2(0.08, 0.08)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.albedo_color = Color(1.0, 0.85, 0.4, 1.0)
	if main.has_method("_soft_dot_v24"):
		m.albedo_texture = main._soft_dot_v24()
	q.material = m
	p.mesh = q
	add_child(p)
	p.global_position = at
	p.emitting = true
	get_tree().create_timer(2.0).timeout.connect(p.queue_free)


## Pour la page Héros : région des épreuves -> [ouverts, total].
func chest_counts() -> Dictionary:
	var out := {}
	for ch in chests:
		var r: String = str(COFFRE_EP.get(str(ch["region"]), "village"))
		var a: Array = out.get(r, [0, 0])
		out[r] = [int(a[0]) + (1 if opened.has(ch["id"]) else 0), int(a[1]) + 1]
	return out


func _say(text: String, seconds: float = 4.5) -> void:
	main._show_message_v28(text)
	if main.message_clock_v28 < seconds:
		main.message_clock_v28 = seconds
	if main.xr_active and main.get("combat_v28") != null and main.combat_v28 != null and main.xr_camera != null:
		var head: Vector3 = main.xr_camera.global_position
		var f: Vector3 = -main.xr_camera.global_basis.z
		main.combat_v28.float_text(head + f * 1.2 + Vector3.DOWN * 0.15, text, Color(1, 0.95, 0.8))


# =================================================================== boire

## Appelé par l'inventaire quand on « mange » un objet : vrai si c'est une boisson.
func on_drink(id: String, _healed: bool) -> bool:
	if not BOISSONS.has(id):
		return false
	drink(id)
	return true


## Le héros boit (inventaire ou comptoir).
func drink(id: String, at_counter: bool = false) -> void:
	verres += 1
	var info: Array = BOISSONS.get(id, [0.0, ""])
	var deg: float = float(info[0])
	var fx: String = str(info[1])
	var inv: Node = main.inventory_v28
	var art: String = str(inv.ITEMS[id]["art"]) if inv != null and inv.ITEMS.has(id) else id
	var hero: Node = main.get("hero_v28")
	if hero != null and not main.xr_active and hero.has_method("play_drink"):
		var prop: Node3D = inv.make_model(id) if inv != null else null
		hero.play_drink(prop)
	var me: Vector3 = main._player_pos_v27() + Vector3.UP * 1.5
	get_tree().create_timer(0.45).timeout.connect(func(): main.sfx("boire", me))
	var was: float = ivresse
	var msg: String = ("Tu bois %s au comptoir." % art) if at_counter else ("Tu bois %s." % art)
	if deg > 0.0:
		ivresse = minf(ivresse + deg, 2.2)
		_force_t = FORCE_TEMPS
		if hero != null:
			hero.set("temp_force", 1)
		if ivresse >= 1.5:
			msg += " Tout tourne… Tu ferais mieux de t'arrêter là !"
		elif ivresse >= 0.8:
			msg += " La tête te tourne un peu. (+1 de force)"
		else:
			msg += " Ça réchauffe ! +1 de force pendant deux minutes."
		if id in ["biere_naine", "cidre_carene"] and _rng.randf() < 0.45:
			get_tree().create_timer(2.1).timeout.connect(func(): main.sfx("rot", main._player_pos_v27() + Vector3.UP * 1.5))
	elif deg < 0.0:
		ivresse = maxf(ivresse + deg, 0.0)
		if was > 0.3:
			msg += " Les idées se remettent en place."
	match fx:
		"cafe":
			if hero != null:
				hero.set("stamina", float(hero.get("STAMINA_MAX")) if hero.get("STAMINA_MAX") != null else 10.0)
				hero.set("stamina_lock", false)
			msg += " Il te réveille d'un coup : endurance au maximum."
		"the":
			msg += " Brûlant, sucré, parfumé."
		"nectar":
			msg += " Il pétille sur la langue comme une poignée d'étoiles."
	main._show_message_v28(msg)


func _tick_drink(delta: float) -> void:
	var hero: Node = main.get("hero_v28")
	if ivresse > 0.0:
		ivresse = maxf(ivresse - DEGRISE * delta, 0.0)
	if _force_t > 0.0:
		_force_t -= delta
		if _force_t <= 0.0 and hero != null:
			hero.set("temp_force", 0)
	if hero != null:
		var t: float = 0.0 if main.xr_active else clampf((ivresse - 0.35) / 1.2, 0.0, 1.0)
		hero.set("tipsy", t)
	if ivresse > 0.55:
		_hic_t -= delta
		if _hic_t <= 0.0:
			_hic_t = _rng.randf_range(4.0, 10.0) / (0.7 + ivresse * 0.3)
			main.sfx("hoquet", main._player_pos_v27() + Vector3.UP * 1.5)
			if hero != null and not main.xr_active and hero.has_method("hiccup"):
				hero.hiccup()


# =================================================================== le comptoir des tavernes

func register_services(journal: Node) -> void:
	for id in COMPTOIRS:
		_wrap(journal, str(id))


## Notre service s'ajoute à celui qui existe déjà (la chambre de Zineb, de Gaston…). Si la
## ville enregistre le sien plus tard (îles construites à la demande), on se ré-ajoute.
func _wrap(journal: Node, pid: String) -> void:
	var prev: Variant = journal.services.get(pid, null)
	journal.add_service(pid, func(npc: Node) -> Array: return _bar_topics(npc, pid, prev),
		func(npc: Node, choice: String) -> Dictionary: return _bar_choose(npc, choice, pid, prev))
	_wrapped[pid] = journal.services[pid]


func _check_services() -> void:
	var j: Node = main.get("journal_v56")
	if j == null:
		return
	for id in COMPTOIRS:
		if not is_same(j.services.get(id, null), _wrapped.get(id, null)):
			_wrap(j, str(id))


func _bar_topics(npc: Node, id: String, prev: Variant) -> Array:
	var out: Array = []
	if prev != null:
		out = ((prev as Array)[0] as Callable).call(npc).duplicate()
	var c: Array = COMPTOIRS[id]
	out.append({"id": "q56:service:boire66", "label": "%s (%d pièces)" % [str(c[2]), int(c[1])]})
	return out


func _bar_choose(npc: Node, choice: String, id: String, prev: Variant) -> Dictionary:
	if choice != "q56:service:boire66":
		return ((prev as Array)[1] as Callable).call(npc, choice) if prev != null else {}
	var c: Array = COMPTOIRS[id]
	var vous: bool = npc.get("brain") != null and bool(npc.brain.get("vous"))
	var deg: float = float((BOISSONS.get(str(c[0]), [0.0, ""]) as Array)[0])
	if deg > 0.0 and ivresse >= 1.5:
		return {"texte": "Vous avez assez bu pour aujourd'hui. Un verre d'eau, et au lit !" if vous else "Toi, tu as assez bu pour aujourd'hui. Un verre d'eau, et au lit !", "geste": "parle"}
	if main.inventory_v28.count("piece") < int(c[1]):
		return {"texte": ("Il vous manque quelques pièces. Revenez quand vous aurez de quoi payer." if vous else "Il te manque quelques pièces. Reviens quand tu auras de quoi payer."), "geste": "parle"}
	var lines: Array = ["Et voilà ! À la vôtre !", "Servi bien frais. Santé !", "Pour vous, la meilleure du tonneau."] if vous else ["Et voilà ! À la tienne !", "Servi bien frais. Santé !", "Pour toi, la meilleure du tonneau."]
	if deg <= 0.0:
		lines = ["Et voilà. Prenez le temps de le savourer.", "Bien chaud, comme il faut."] if vous else ["Et voilà. Prends le temps de le savourer.", "Bien chaud, comme il faut."]
	return {"texte": str(lines[_rng.randi() % lines.size()]), "geste": "salut", "fin": true, "prendre": [["piece", int(c[1])]], "_boire66": str(c[0])}


## Appelé par main après une réplique réussie (le prix est payé).
func after_reply(r: Dictionary, npc: Node) -> void:
	if not r.has("_boire66"):
		return
	main._close_dialogue_v31()
	drink(str(r["_boire66"]), true)
	if npc != null and npc.has_method("say_bubble"):
		npc.say_bubble("Santé !", 2.5)


# =================================================================== chaque image

func _process(delta: float) -> void:
	_clock += delta
	_tick_debris(delta)
	if main == null or not bool(main.get("game_started")):
		return
	_tick_drink(delta)
	_text_t -= delta
	if _text_t <= 0.0:
		_text_t = 0.5
		_check_services()
		for ch in chests:
			if bool(ch["locked"]) and not opened.has(ch["id"]):
				_chest_text(ch)


# =================================================================== sauvegarde

func serialize() -> Dictionary:
	return {"coffres": opened.keys(), "verres": verres, "casses": broken_total}


func load_data(d: Dictionary) -> void:
	opened = {}
	for k in d.get("coffres", []):
		opened[str(k)] = true
	verres = int(d.get("verres", 0))
	broken_total = int(d.get("casses", 0))
	ivresse = 0.0
	_force_t = 0.0
	var hero: Node = main.get("hero_v28") if main != null else null
	if hero != null:
		hero.set("temp_force", 0)
		hero.set("tipsy", 0.0)
	for ch in chests:
		_show(ch, opened.has(ch["id"]))
		_chest_text(ch)
	# tout ce qui était cassé se reforme
	for c in get_tree().get_nodes_in_group("cassables_v66"):
		if bool(c.broken) or bool(c.displaced):
			c.restore()
