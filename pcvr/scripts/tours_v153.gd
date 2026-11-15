extends Node3D
## V153 : on entre dans les tours de Néopolis, et l'on en visite tous les étages.
##  - Chaque tour a sa porte (un sas vitré, un auvent, une enseigne à son nom), au pied, du côté de la
##    rue. « E : entrer » : un fondu, et l'on est dans le hall.
##  - L'intérieur est bâti à l'endroit même de la tour, à sa vraie hauteur : par les fenêtres, on voit
##    la vraie ville (au 40ᵉ étage, la vue plonge sur les rues). Pendant la visite, les murs extérieurs
##    de la tour ne bloquent plus (ses collisions sont coupées) : ce sont les murs de l'étage qui tiennent.
##  - Un seul étage existe à la fois : on le bâtit quand on y arrive (toujours le même pour un même
##    étage : il est tiré d'une graine), on le défait quand on le quitte.
##  - L'ascenseur, au cœur de la tour : on choisit l'étage (un étage, cinq, le hall, le dernier…).
##  - Les étages : le hall (l'accueil, le vigile, les canapés, le grand écran) ; dans les tours de
##    bureaux (les Hauts, le Centre, le Quai), les bureaux en plateau (les postes, les écrans, une salle
##    de réunion vitrée), la cafétéria, la salle des serveurs, et tout en haut la direction ; dans les
##    autres tours, les couloirs des logements (on frappe aux portes ; les appartements s'ouvriront
##    avec la V154).
##  - Des gens y vivent : des employés à leur poste, en réunion, à la machine à café ; des voisins dans
##    les couloirs ; des androïdes. On peut leur parler.
## Les hauteurs d'étage suivent celles que les fenêtres peintes sur les façades (gratte_ciel_v94).

const IleScript = preload("res://scripts/ile_neo_v94.gd")
const Kit = preload("res://scripts/neo_kit_v94.gd")
const Figurant = preload("res://scripts/pnj/figurant_v81.gd")
const Gens = preload("res://scripts/pnj/maisons_habitants_v81.gd")
const PnjV31 = preload("res://scripts/pnj/pnj_v31.gd")

const NOMS_BUREAUX := ["Hikari", "Orion", "Kumo", "Prisme", "Quasar", "Tenshi", "Vertex", "Zénith", "Kaïdo", "Mirai", "Sora", "Haruka",
	"Nébula", "Ikaru", "Kōsei", "Polaris", "Sakura", "Tsubasa", "Arcturus", "Hoshi"]
const SOCIETES := ["Hikari Systèmes", "Orion Biotech", "Kumo Logistique", "Prisme Assurances", "Quasar Robotique", "Tenshi Médias",
	"Vertex Finances", "Zénith Énergie", "Kaïdo Holographie", "Mirai Jeux", "Sora Aéronefs", "Nébula Data"]
const NOMS_RESIDENCES := ["Les Cerisiers", "Les Lanternes", "Le Lotus", "Les Nuages", "Le Bambou", "La Pluie d'Or", "Les Carpes", "Le Héron"]
const NOMS_ARCADES := ["Le Pixel Palace", "Capsules Kibō", "Le Néon Bleu", "La Ruche à Capsules", "Le Dragon qui Chante", "Étoile Karaoké", "Le Bip-Bip Club", "Capsules du Lotus"]
const NOMS_ATELIERS := ["Atelier Rouage-Bot", "Le Docteur des Robots", "Boulons & Fils", "L'Atelier de Maître Kaneda"]
const NOMS_NOUILLES := ["Nouilles Mama Ren", "Le Bol Fumant", "Ramen du Dragon Rouge", "Chez Oncle Udon"]
const NOMS_BOUTIQUES := ["Électro Hoshi", "Gadgets & Circuits", "Le Bazar Néon", "Puces et Pixels"]
const FAMILLES := ["Tanaka", "Moreau", "Kimura", "Okafor", "Silva", "Nakamura", "Dubois", "Park", "Haddad", "Ishikawa", "Rossi", "Nguyen", "Sato", "Leclerc"]
const Q = preload("res://scripts/tours_quartiers_v155.gd")
const ETAGE_STYLE := {0: 3.5, 1: 3.5, 2: 3.8, 3: 3.1}
const COLW := {0: 1.5, 1: 2.6, 2: 3.0, 3: 2.2}

var main: Node
var N: Node3D                         # neo_v94
var tours: Array = []                 # {id, nom, b, e (hauteur d'étage), etages: [{y, rect}], porte, sortie, n (normale), quartier, type}
var inside: int = -1                  # la tour où l'on est (-1 : dehors)
var etage: int = 0
var visites: Dictionary = {}          # les tours visitées
var busy: bool = false
var test_mode: bool = false
var _node: Node3D                     # l'étage bâti
var _body: StaticBody3D
var _its: Array = []                  # les interactions de l'étage
var _gens: Array = []                 # les figurants de l'étage
var _ecrans: Array = []               # [MeshInstance3D, phase] : les écrans qui changent
var _anchor: Node3D
var _registered: bool = false
var _its_dehors: Array = []
var _t: float = 0.0
var _grace: float = 0.0              # juste après un déplacement : on laisse le temps au corps d'arriver
var info: Dictionary = {}             # l'étage bâti : {type, ascenseur (Vector3), regard, sortie_dedans…}
var _ouverte: int = -1                # V155 : la porte d'appartement ouverte à cet étage (son numéro)


func setup(main_node: Node, neo: Node3D) -> void:
	main = main_node
	N = neo
	name = "Tours_v153"
	_anchor = Node3D.new()
	add_child(_anchor)
	var b_entrees := Kit.Batch.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 1530
	var n_bur: int = 0
	var n_res: int = 0
	var n_arc: int = 0
	var n_rue: int = 0
	for i in range(N.batiments.size()):
		var b: Dictionary = N.batiments[i]
		var q: String = str(b.get("quartier", ""))
		if q in ["axiome", "arcade"] or (b.get("segs", []) as Array).is_empty():
			continue
		var t: Dictionary = {"id": tours.size(), "b": b, "quartier": q, "style": int(b["style"])}
		t["e"] = float(ETAGE_STYLE.get(int(b["style"]), 3.5))
		t["type"] = "bureaux" if q in ["hauts", "centre", "quai"] else "logements"
		if t["type"] == "bureaux":
			t["nom"] = "Tour " + str(NOMS_BUREAUX[n_bur % NOMS_BUREAUX.size()]) + ("" if n_bur < NOMS_BUREAUX.size() else " II")
			t["societe"] = str(SOCIETES[n_bur % SOCIETES.size()])
			n_bur += 1
		else:
			t["nom"] = ("Résidence " + str(NOMS_RESIDENCES[n_res % NOMS_RESIDENCES.size()])) if q == "residences" else "Immeuble n° %d" % (12 + n_res * 7 % 180)
			n_res += 1
		# V155 : le rez-de-chaussée selon le quartier ; les Arcades (karaoké, capsules) ; les échoppes des Ruelles
		t["rdc"] = "hall"
		if q == "quai":
			t["rdc"] = "hangar"
		elif q == "arcades":
			t["type"] = "arcades"
			t["rdc"] = "salle_jeux"
			t["nom"] = str(NOMS_ARCADES[n_arc % NOMS_ARCADES.size()]) + ("" if n_arc < NOMS_ARCADES.size() else " II")
			n_arc += 1
		elif q == "ruelles":
			t["rdc"] = ["atelier", "nouilles", "boutique"][n_rue % 3]
			var noms: Array = {"atelier": NOMS_ATELIERS, "nouilles": NOMS_NOUILLES, "boutique": NOMS_BOUTIQUES}[t["rdc"]]
			t["enseigne"] = str(noms[int(n_rue / 3.0) % noms.size()])
			n_rue += 1
		_etages(t)
		if (t["etages"] as Array).is_empty():
			continue
		_porte(t)
		_entree(b_entrees, t, rng)
		tours.append(t)
	b_entrees.commit(self, "Neo_entrees_v153")


## Les étages : à la hauteur des rangées de fenêtres peintes ; chaque étage prend la boîte (le fût, ou
## le socle, ou un retrait) qui contient son plafond.
func _etages(t: Dictionary) -> void:
	var b: Dictionary = t["b"]
	var e: float = t["e"]
	var y0: float = IleScript.Y0
	var top: float = y0 + float(b["h"])
	var segs: Array = b["segs"]
	var out: Array = []
	var k: int = 0
	while y0 + (k + 1) * e <= top - 0.3 and k < 80:
		var y: float = y0 + k * e
		var haut: float = y + e - 0.3
		var rect: Array = []
		for s in segs:
			if haut >= float(s[4]) - 0.01 and haut <= float(s[5]) + 0.01 and y >= float(s[4]) - e:
				rect = [float(s[0]), float(s[1]), float(s[2]), float(s[3])]
				break
		if rect.is_empty():
			break
		out.append({"y": y, "rect": rect})
		k += 1
	t["etages"] = out


## La porte : sur la face la plus proche d'une rue.
func _porte(t: Dictionary) -> void:
	var r: Array = (t["etages"] as Array)[0]["rect"]
	var cx: float = (float(r[0]) + float(r[2])) * 0.5
	var cz: float = (float(r[1]) + float(r[3])) * 0.5
	var faces: Array = [[Vector2(float(r[0]), cz), Vector2(-1, 0)], [Vector2(float(r[2]), cz), Vector2(1, 0)],
		[Vector2(cx, float(r[1])), Vector2(0, -1)], [Vector2(cx, float(r[3])), Vector2(0, 1)]]
	var best: Array = faces[0]
	var best_d: float = INF
	for f in faces:
		var p: Vector2 = (f[0] as Vector2) + (f[1] as Vector2) * 4.0
		var dx: float = absf(p.x - round(p.x / IleScript.PAS) * IleScript.PAS)
		var dz: float = absf(p.y - round(p.y / IleScript.PAS) * IleScript.PAS)
		var d: float = minf(dx, dz)
		if IleScript.on_road(p.x, p.y):
			d -= 10.0
		if d < best_d:
			best_d = d
			best = f
	var m: Vector2 = best[0]
	var n2: Vector2 = best[1]
	t["n"] = Vector3(n2.x, 0, n2.y)
	t["face"] = IleScript.W(m.x, m.y, IleScript.Y0)
	var so: Vector3 = IleScript.W(m.x + n2.x * 1.6, m.y + n2.y * 1.6, IleScript.Y0)
	if N.get("ile") != null:
		so.y = N.ile.height(so.x, so.z)
	t["sortie"] = so


## Le sas d'entrée, dehors : le cadre, les portes de verre, l'auvent et son néon, l'enseigne.
func _entree(b: Kit.Batch, t: Dictionary, rng: RandomNumberGenerator) -> void:
	var n: Vector3 = t["n"]
	var f: Vector3 = t["face"]
	var side: Vector3 = n.cross(Vector3.UP)
	var yaw: float = atan2(n.x, n.z)
	var y: float = f.y
	var neons: Array = ["neon_cyan", "neon_rose", "neon_ambre"]
	var neon: String = str(neons[rng.randi() % neons.size()])
	for s in [-1.0, 1.0]:
		b.box_at("metal_noir", f + side * s * 1.45 + n * 0.12 + Vector3.UP * (y * 0.0), Vector3(0.22, 3.1, 0.28), yaw)
	b.box_at("metal_noir", f + n * 0.12 + Vector3.UP * 3.0, Vector3(3.2, 0.3, 0.3), yaw)
	for s2 in [-1.0, 1.0]:
		b.box_at("verre_fume", f + side * s2 * 0.66 + n * 0.08, Vector3(1.26, 2.9, 0.05), yaw)
		b.box_at("chrome", f + side * s2 * 0.14 + n * 0.13 + Vector3.UP * 1.1, Vector3(0.04, 0.7, 0.04), yaw)
	# l'auvent, son néon
	b.box_at("metal_noir", f + n * 0.9 + Vector3.UP * 3.25, Vector3(4.2, 0.14, 1.8), yaw)
	b.box_at(neon, f + n * 1.78 + Vector3.UP * 3.2, Vector3(4.2, 0.05, 0.05), yaw)
	b.box_at("lampe_blanche", f + n * 0.9 + Vector3.UP * 3.18, Vector3(1.4, 0.03, 0.5), yaw)
	# l'enseigne (le nom)
	var l := Label3D.new()
	l.text = str(t.get("enseigne", t["nom"])).to_upper()
	l.font_size = 72
	l.pixel_size = 0.006
	l.modulate = Kit.NEONS.get(neon.substr(5), Color.WHITE)
	l.outline_size = 10
	l.outline_modulate = Color(0.02, 0.02, 0.04)
	l.shaded = false
	l.double_sided = false
	add_child(l)
	l.global_position = f + n * 1.82 + Vector3.UP * 3.65
	l.look_at(l.global_position - n, Vector3.UP)
	# le tapis devant
	b.box_at("metal_noir", f + n * 1.0 + Vector3.UP * 0.005, Vector3(2.6, 0.012, 1.6), yaw)


func _process(delta: float) -> void:
	if main == null:
		return
	if not _registered:
		_register()
	_t += delta
	# les écrans des étages (ils changent de couleur, défilent un peu)
	for e in _ecrans:
		var mi: MeshInstance3D = e[0]
		if is_instance_valid(mi) and mi.material_override is StandardMaterial3D:
			var ph: float = float(e[1])
			(mi.material_override as StandardMaterial3D).emission_energy_multiplier = 1.0 + 0.5 * sin(_t * 1.3 + ph)
	# dedans, mais on n'y est plus (un voyage, un évanouissement…) : on referme l'étage
	_grace = maxf(0.0, _grace - delta)
	if inside >= 0 and not busy and _node != null and _grace <= 0.0:
		var pq: Vector3 = main._player_pos_v27()
		var rr: Rect2 = info.get("rect", Rect2())
		if not rr.grow(3.0).has_point(Vector2(pq.x, pq.z)) or absf(pq.y - float(info.get("y", pq.y))) > 6.0:
			sortir_vite()
		# le filet de sécurité : dehors, on n'est jamais coincé dans une tour (une sauvegarde faite dedans…)
	if inside < 0 and not busy and _grace <= 0.0 and int(_t * 2.0) % 2 == 0:
		var p: Vector3 = main._player_pos_v27()
		var t: Dictionary = tour_at(p)
		if not t.is_empty() and p.y < IleScript.Y0 + float(t["b"]["h"]) - 0.5:
			_grace = 1.5
			main.place_player_v35(t["sortie"] + Vector3.UP * 0.2, t["n"])
		elif t.is_empty():
			# V155 : debout sur un toit (une sauvegarde faite là-haut…) : le toit se bâtit autour de nous
			var tt: Dictionary = toit_at(p)
			if not tt.is_empty():
				inside = int(tt["id"])
				_batir_toit()
				_grace = 1.0


## La tour dont l'emprise contient ce point (au sol), ou {}.
func tour_at(p: Vector3) -> Dictionary:
	var l: Vector2 = IleScript.L(p.x, p.z)
	for t in tours:
		for s in t["b"]["segs"]:
			if l.x > float(s[0]) + 0.2 and l.x < float(s[2]) - 0.2 and l.y > float(s[1]) + 0.2 and l.y < float(s[3]) - 0.2 and p.y > float(s[4]) - 1.0 and p.y < float(s[5]) - 0.3:
				return t
	return {}


func _register() -> void:
	var d: Node = main.get("donjon_v35")
	if d == null:
		return
	_registered = true
	for t in tours:
		var id: int = int(t["id"])
		var it := {"id": "tour153_%d" % id, "pos": (t["sortie"] as Vector3), "radius": 2.0, "text": "E : entrer — %s" % str(t.get("enseigne", t["nom"])),
			"vr": "Gâchette : entrer", "call": enter.bind(id), "when": func() -> bool: return inside < 0 and not busy}
		d._interactions.append(it)
		_its_dehors.append(it)


# =================================================================== entrer, sortir, monter

func _fade(v: float, s: float) -> void:
	var dj: Node = main.get("donjon_v35")
	if dj != null and dj.has_method("_fade_to") and not test_mode:
		await dj._fade_to(v, s)


func _cols(id: int, on: bool) -> void:
	for cs in tours[id]["b"]["cols"]:
		if is_instance_valid(cs):
			(cs as CollisionShape3D).set_deferred("disabled", not on)


func enter(id: int) -> void:
	if busy or inside >= 0 or id < 0 or id >= tours.size():
		return
	busy = true
	main.sfx("porte_ouvre", tours[id]["face"])
	await _fade(1.0, 0.35)
	inside = id
	_cols(id, false)
	_batir(0)
	var t: Dictionary = tours[id]
	_grace = 1.5
	main.place_player_v35((t["face"] as Vector3) - (t["n"] as Vector3) * 1.6 + Vector3.UP * 0.1, -(t["n"] as Vector3))
	await _fade(0.0, 0.45)
	busy = false
	var n: int = (t["etages"] as Array).size()
	if not visites.has(id):
		visites[id] = true
		if t["rdc"] == "hangar":
			main._show_message_v28("%s — %s, %d étages. Au rez-de-chaussée, le hangar ; l'ascenseur est au milieu." % [str(t["nom"]), str(t["societe"]), n])
		elif t["type"] == "bureaux":
			main._show_message_v28("%s — %s, %d étages. L'ascenseur est au fond du hall." % [str(t["nom"]), str(t["societe"]), n])
		elif t["type"] == "arcades":
			main._show_message_v28("%s — %d étages : la salle de jeux, le karaoké, l'hôtel capsule. Et le toit !" % [str(t["nom"]), n])
		elif t.has("enseigne"):
			main._show_message_v28("%s — au pied de l'immeuble ; au-dessus, %d étages de logements." % [str(t["enseigne"]), n - 1])
		else:
			main._show_message_v28("%s — %d étages de logements. L'ascenseur est au fond du hall." % [str(t["nom"]), n])


func leave() -> void:
	if busy or inside < 0:
		return
	busy = true
	await _fade(1.0, 0.35)
	var t: Dictionary = tours[inside]
	_defaire()
	_cols(inside, true)
	inside = -1
	_ouverte = -1
	_grace = 1.5
	main.place_player_v35((t["sortie"] as Vector3) + (t["n"] as Vector3) * 0.6 + Vector3.UP * 0.1, t["n"])
	await _fade(0.0, 0.45)
	busy = false


## Quitter la tour sans fondu (un évanouissement, un voyage, un chargement).
func sortir_vite() -> void:
	if inside < 0:
		return
	_defaire()
	_cols(inside, true)
	inside = -1
	_ouverte = -1
	busy = false


func aller(k: int) -> void:
	if busy or inside < 0:
		return
	var n: int = (tours[inside]["etages"] as Array).size()
	k = clampi(k, 0, n - 1)
	if k == etage:
		return
	busy = true
	main.sfx("ascenseur_tour", main._player_pos_v27())
	await _fade(1.0, 0.3)
	var du_toit: bool = etage >= n
	_defaire()
	if du_toit:
		_cols(inside, false)
	_ouverte = -1
	_batir(k)
	_grace = 1.5
	main.place_player_v35((info["ascenseur"] as Vector3) + Vector3.UP * 0.1, info["regard"])
	await _fade(0.0, 0.4)
	busy = false
	main.sfx("ding_ascenseur", main._player_pos_v27())
	if str(info.get("son", "")) != "":
		main.sfx(str(info["son"]), main._player_pos_v27())
	main._show_message_v28(_nom_etage(k))


## V155 : monter sur le toit (par l'ascenseur, du dernier étage ; ou par l'escalier).
func aller_toit() -> void:
	if busy or inside < 0:
		return
	busy = true
	main.sfx("ascenseur_tour", main._player_pos_v27())
	await _fade(1.0, 0.3)
	_defaire()
	_batir_toit()
	_grace = 1.5
	main.place_player_v35((info["ascenseur"] as Vector3) + Vector3.UP * 0.1, info["regard"])
	await _fade(0.0, 0.4)
	busy = false
	main.sfx(str(info.get("son", "deltaplane_vent")), main._player_pos_v27())
	var t: Dictionary = tours[inside]
	main._show_message_v28("%s — le toit, à %d mètres au-dessus des rues." % [str(t["nom"]), int(float(t["b"]["h"]))])


func _nom_etage(k: int) -> String:
	var t: Dictionary = tours[inside]
	if k >= (t["etages"] as Array).size():
		return "Le toit"
	var ty: String = type_etage(inside, k)
	var nom: String = "Rez-de-chaussée" if k == 0 else ("1er étage" if k == 1 else "%dᵉ étage" % k)
	var quoi := {"hall": "le hall", "bureaux": "les bureaux de %s" % str(t.get("societe", "")), "cafeteria": "la cafétéria", "serveurs": "la salle des serveurs",
		"direction": "la direction de %s" % str(t.get("societe", "")), "logements": "les logements", "hangar": "le hangar", "atelier": str(t.get("enseigne", "l'atelier")),
		"nouilles": str(t.get("enseigne", "les nouilles")), "boutique": str(t.get("enseigne", "la boutique")), "salle_jeux": "la salle de jeux", "karaoke": "le karaoké",
		"capsules": "l'hôtel capsule"}
	return "%s — %s" % [nom, str(quoi.get(ty, ty))]


func type_etage(id: int, k: int) -> String:
	var t: Dictionary = tours[id]
	var n: int = (t["etages"] as Array).size()
	if k == 0:
		return str(t.get("rdc", "hall"))
	if t["type"] == "arcades":
		return "karaoke" if k % 3 == 1 else "capsules"
	if t["type"] == "bureaux":
		if k == n - 1 and n > 3:
			return "direction"
		if k % 6 == 2:
			return "cafeteria"
		if k % 9 == 5:
			return "serveurs"
		return "bureaux"
	return "logements"


## Le panneau de l'ascenseur.
func ascenseur() -> void:
	if busy or inside < 0:
		return
	var n: int = (tours[inside]["etages"] as Array).size()
	var ch: Array = []
	if etage < n - 1:
		ch.append({"id": "+1", "label": "Monter d'un étage"})
	if etage < n - 5:
		ch.append({"id": "+5", "label": "Monter de cinq étages"})
	if etage > 0:
		ch.append({"id": "-1", "label": "Descendre d'un étage"})
	if etage > 4:
		ch.append({"id": "-5", "label": "Descendre de cinq étages"})
	if etage != 0:
		ch.append({"id": "0", "label": "Le hall (rez-de-chaussée)"})
	if etage != n - 1:
		ch.append({"id": "max", "label": "Le dernier étage"})
	if n > 6:
		ch.append({"id": "hasard", "label": "Un étage au hasard"})
	if etage == n - 1:
		ch.append({"id": "toit", "label": "Le toit"})
	ch.append({"id": "rester", "label": "Rester ici"})
	_anchor.global_position = info["ascenseur"]
	main.ask_v69(_anchor, "Ascenseur", "serein", "Vous êtes ici : %s. Où allons-nous ? (%d étages)" % [_nom_etage(etage), n], ch, _choix_ascenseur)


func _choix_ascenseur(id: String) -> void:
	main._close_dialogue_v31()
	var n: int = (tours[inside]["etages"] as Array).size()
	match id:
		"+1":
			aller(etage + 1)
		"+5":
			aller(etage + 5)
		"-1":
			aller(etage - 1)
		"-5":
			aller(etage - 5)
		"0":
			aller(0)
		"max":
			aller(n - 1)
		"hasard":
			var k: int = randi_range(1, n - 1)
			if k == etage:
				k = (k % (n - 1)) + 1
			aller(k)
		"toit":
			aller_toit()


# =================================================================== bâtir un étage

## Le repère de l'étage (monde) : les murs intérieurs, le cœur (l'ascenseur), la place libre.
func _batir(k: int) -> void:
	etage = k
	var t: Dictionary = tours[inside]
	var et: Dictionary = (t["etages"] as Array)[k]
	var rng := RandomNumberGenerator.new()
	rng.seed = int(t["id"]) * 1009 + k * 31 + 7
	_node = Node3D.new()
	_node.name = "Etage_v153"
	add_child(_node)
	_body = StaticBody3D.new()
	_body.collision_layer = 1
	_body.collision_mask = 0
	_node.add_child(_body)
	var b := Kit.Batch.new()
	var r: Array = et["rect"]
	var y: float = float(et["y"])
	var e: float = float(t["e"])
	var hc: float = e - 0.35                 # la hauteur sous plafond
	var X0: float = IleScript.CENTER.x + float(r[0]) + 0.3
	var X1: float = IleScript.CENTER.x + float(r[2]) - 0.3
	var Z0: float = IleScript.CENTER.z + float(r[1]) + 0.3
	var Z1: float = IleScript.CENTER.z + float(r[3]) - 0.3
	var ty: String = type_etage(int(t["id"]), k)
	var sols := {"hall": "in_terrazzo", "bureaux": "in_moquette", "cafeteria": "in_parquet", "serveurs": "in_sol_technique", "direction": "in_parquet", "logements": "in_moquette_bleue",
		"hangar": "in_beton_cire", "atelier": "in_sol_technique", "nouilles": "in_parquet", "boutique": "in_terrazzo", "salle_jeux": "in_moquette_bleue", "karaoke": "in_moquette",
		"capsules": "in_moquette"}
	var w: float = X1 - X0
	var d: float = Z1 - Z0
	var c := Vector3((X0 + X1) * 0.5, 0.0, (Z0 + Z1) * 0.5)
	# le sol, le plafond
	var y_sol: float = y + (0.03 if k == 0 else 0.0)
	_boite(b, str(sols.get(ty, "in_moquette")), Vector3(c.x, y_sol - 0.15, c.z), Vector3(w, 0.3, d), true)
	_boite(b, "in_plafond", Vector3(c.x, y_sol + hc + 0.15, c.z), Vector3(w, 0.3, d), true)
	# le cœur : l'ascenseur (face à la porte d'entrée), les escaliers
	var n: Vector3 = t["n"]
	var cw: float = clampf(w * 0.26, 3.2, 9.0)
	var cd: float = clampf(d * 0.26, 3.2, 7.0)
	var core := Rect2(c.x - cw * 0.5, c.z - cd * 0.5, cw, cd)
	_boite(b, "in_mur_gris", Vector3(c.x, y_sol + hc * 0.5, c.z), Vector3(cw, hc, cd), true)
	var fa: Vector3 = c + Vector3(n.x * cw * 0.5, 0, n.z * cd * 0.5)      # le milieu de la face de l'ascenseur
	var side: Vector3 = n.cross(Vector3.UP)
	var yaw: float = atan2(n.x, n.z)
	b.box_at("in_ascenseur", fa + n * 0.03 + Vector3.UP * y_sol, Vector3(1.7, 2.35, 0.06), yaw)
	b.box_at("in_noir", fa + n * 0.065 + Vector3.UP * y_sol, Vector3(0.02, 2.35, 0.02), yaw)
	b.box_at("in_menuiserie", fa + n * 0.05 + Vector3.UP * (y_sol + 2.35), Vector3(1.9, 0.12, 0.08), yaw)
	for s in [-1.0, 1.0]:
		b.box_at("in_menuiserie", fa + n * 0.05 + side * s * 0.9 + Vector3.UP * y_sol, Vector3(0.1, 2.4, 0.08), yaw)
	b.box_at("in_led_ambre", fa + n * 0.06 + side * 1.15 + Vector3.UP * (y_sol + 1.15), Vector3(0.08, 0.14, 0.03), yaw)
	var lab := _label(str(k) if k > 0 else "RDC", 80, Color(1.0, 0.65, 0.2))
	lab.global_position = fa + n * 0.08 + Vector3.UP * (y_sol + 2.62)
	lab.look_at(lab.global_position - n, Vector3.UP)
	info = {"type": ty, "ascenseur": fa + n * 1.3 + Vector3.UP * y_sol, "regard": n, "y": y_sol, "rect": Rect2(X0, Z0, w, d), "core": core}
	_its_add({"id": "ascenseur153", "pos": fa + n * 1.1 + Vector3.UP * y_sol, "radius": 1.6, "text": "E : appeler l'ascenseur", "vr": "Gâchette : appeler l'ascenseur",
		"call": ascenseur})
	# le panneau de l'étage, à côté de l'ascenseur
	var pan := _label(_nom_etage(k), 30, Color(0.9, 0.95, 1.0))
	var half_a: float = (absf(side.x) * cw + absf(side.z) * cd) * 0.5
	if half_a >= 2.6:
		pan.global_position = fa + n * 0.08 + side * 1.6 + Vector3.UP * (y_sol + 1.75)
		pan.look_at(pan.global_position - n, Vector3.UP)
	else:
		var half_s: float = (absf(n.x) * cw + absf(n.z) * cd) * 0.5
		pan.global_position = c + side * (half_a + 0.06) + Vector3.UP * (y_sol + 0.7)
		pan.look_at(pan.global_position - side, Vector3.UP)
		pan.width = maxf(200.0, (half_s * 2.0 - 0.3) / pan.pixel_size)
	pan.width = 520.0
	pan.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# l'escalier de secours (sa porte, de l'autre côté du cœur)
	var fs: Vector3 = c - Vector3(n.x * cw * 0.5, 0, n.z * cd * 0.5)
	b.box_at("in_porte", fs - n * 0.03 + Vector3.UP * y_sol, Vector3(1.0, 2.2, 0.06), yaw)
	b.box_at("in_led_verte", fs - n * 0.07 + Vector3.UP * (y_sol + 2.4), Vector3(0.5, 0.18, 0.03), yaw)
	_its_add({"id": "escalier153", "pos": fs - n * 1.0 + Vector3.UP * y_sol, "radius": 1.3, "text": "E : prendre l'escalier", "vr": "Gâchette : prendre l'escalier",
		"call": _escalier})
	# les murs extérieurs, leurs fenêtres (et la porte, au rez-de-chaussée)
	var colw: float = float(COLW.get(int(t["style"]), 2.6))
	_facade(b, Vector3(X0, y_sol, Z0), Vector3(X1, y_sol, Z0), Vector3(0, 0, 1), hc, colw, k == 0 and n.z < -0.5, t)
	_facade(b, Vector3(X0, y_sol, Z1), Vector3(X1, y_sol, Z1), Vector3(0, 0, -1), hc, colw, k == 0 and n.z > 0.5, t)
	_facade(b, Vector3(X0, y_sol, Z0), Vector3(X0, y_sol, Z1), Vector3(1, 0, 0), hc, colw, k == 0 and n.x < -0.5, t)
	_facade(b, Vector3(X1, y_sol, Z0), Vector3(X1, y_sol, Z1), Vector3(-1, 0, 0), hc, colw, k == 0 and n.x > 0.5, t)
	# les plafonniers et les lumières
	var nx: int = maxi(1, int(w / 4.5))
	var nz: int = maxi(1, int(d / 4.5))
	var chaud: bool = ty in ["cafeteria", "direction", "logements", "nouilles", "karaoke", "capsules"]
	for ix in range(nx):
		for iz in range(nz):
			var p := Vector3(X0 + (ix + 0.5) * w / nx, y_sol + hc - 0.02, Z0 + (iz + 0.5) * d / nz)
			if core.grow(0.3).has_point(Vector2(p.x, p.z)):
				continue
			b.box_at("in_plafonnier_chaud" if chaud else "in_plafonnier", p + Vector3.DOWN * 0.02, Vector3(1.2, 0.04, 0.6))
	var nl: int = clampi(int(w * d / 160.0) + 1, 2, 6)
	for li in range(nl):
		var a: float = TAU * li / nl
		var lp := Vector3(c.x + cos(a) * w * 0.3, y_sol + hc - 0.4, c.z + sin(a) * d * 0.3)
		var o := OmniLight3D.new()
		o.light_color = Color(1.0, 0.86, 0.68) if chaud else Color(0.92, 0.96, 1.0)
		o.light_energy = 1.1
		o.omni_range = maxf(w, d) * 0.45 + 4.0
		o.omni_attenuation = 1.2
		_node.add_child(o)
		o.global_position = lp
	# les piliers de la structure (une trame de 8 m, hors du cœur et des allées ; pas dans les cabines du karaoké)
	var piliers: Array = []
	info["piliers"] = piliers
	var px: float = X0 + 4.0 if ty != "karaoke" else X1
	while px < X1 - 2.5:
		var pz: float = Z0 + 4.0
		while pz < Z1 - 2.5:
			var pp := Vector3(px, y_sol, pz)
			if _libre(pp, 0.6):
				_boite(b, "in_mur", pp + Vector3.UP * hc * 0.5, Vector3(0.55, hc, 0.55), true)
				b.box_at("in_menuiserie", pp, Vector3(0.6, 0.1, 0.6))
				piliers.append(Vector2(px, pz))
			pz += 8.0
		px += 8.0
	# le contenu
	match ty:
		"hall":
			_hall(b, rng, t)
		"bureaux":
			_bureaux(b, rng, t)
		"cafeteria":
			_cafeteria(b, rng, t)
		"serveurs":
			_serveurs(b, rng, t)
		"direction":
			_direction(b, rng, t)
		"hangar":
			info["son"] = Q.hangar(self, b, rng, t)
		"atelier":
			info["son"] = Q.atelier(self, b, rng, t)
		"nouilles":
			info["son"] = Q.nouilles(self, b, rng, t)
		"boutique":
			info["son"] = Q.boutique(self, b, rng, t)
		"salle_jeux":
			info["son"] = Q.salle_jeux(self, b, rng, t)
		"karaoke":
			info["son"] = Q.karaoke(self, b, rng, t)
		"capsules":
			info["son"] = Q.capsules(self, b, rng, t)
		_:
			_logements(b, rng, t)
	b.commit(_node, "Etage_maillage", false)


## V155 : le toit (on y tient debout sur la tour elle-même : ses collisions reviennent) : le parapet,
## l'édicule de l'escalier (on redescend par là), ce qu'il y avait déjà dessus (citerne, climatiseurs,
## antenne : on ne les traverse plus), et le reste (tours_quartiers_v155.toit).
func _batir_toit() -> void:
	var t: Dictionary = tours[inside]
	var n: int = (t["etages"] as Array).size()
	etage = n
	_ouverte = -1
	_cols(inside, true)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(t["id"]) * 1009 + 777
	_node = Node3D.new()
	_node.name = "Toit_v155"
	add_child(_node)
	_body = StaticBody3D.new()
	_body.collision_layer = 1
	_body.collision_mask = 0
	_node.add_child(_body)
	var b := Kit.Batch.new()
	var top: Array = t["b"]["top"]
	var yt: float = IleScript.Y0 + float(t["b"]["h"])
	var X0: float = IleScript.CENTER.x + float(top[0])
	var X1: float = IleScript.CENTER.x + float(top[2])
	var Z0: float = IleScript.CENTER.z + float(top[1])
	var Z1: float = IleScript.CENTER.z + float(top[3])
	var rect := Rect2(X0, Z0, X1 - X0, Z1 - Z0)
	var c := Vector3(rect.get_center().x, yt, rect.get_center().y)
	# ce qui est déjà sur le toit
	var props: Array = []
	for pr in t["b"].get("toit", []):
		props.append(pr)
		var ph: float = minf(float(pr[2]), 6.0)
		_col((pr[0] as Vector3) + Vector3.UP * ph * 0.5, Vector3(float(pr[1]) * 1.5, ph, float(pr[1]) * 1.5))
	# le parapet (plus haut qu'il n'en a l'air : on ne l'enjambe pas)
	for e in [[Vector3(c.x, yt, Z0 + 0.12), Vector3(rect.size.x, 0, 0.25)], [Vector3(c.x, yt, Z1 - 0.12), Vector3(rect.size.x, 0, 0.25)],
			[Vector3(X0 + 0.12, yt, c.z), Vector3(0.25, 0, rect.size.y)], [Vector3(X1 - 0.12, yt, c.z), Vector3(0.25, 0, rect.size.y)]]:
		var at: Vector3 = e[0]
		var s0: Vector3 = e[1]
		b.box("in_mur_gris", Transform3D(Basis(), at + Vector3.UP * 0.55), Vector3(s0.x, 1.1, s0.z))
		b.box("metal_noir", Transform3D(Basis(), at + Vector3.UP * 1.12), Vector3(s0.x, 0.04, s0.z + 0.04))
		_col(at + Vector3.UP * 1.1, Vector3(s0.x, 2.2, s0.z))
	# l'édicule de l'escalier : là où il y a le plus de place
	var cands: Array = []
	var hx: float = maxf(0.0, rect.size.x * 0.5 - 2.4)
	var hz: float = maxf(0.0, rect.size.y * 0.5 - 2.3)
	for d in [Vector2(-hx, -hz), Vector2(hx, -hz), Vector2(hx, hz), Vector2(-hx, hz), Vector2(0, -hz), Vector2(0, hz), Vector2(-hx, 0), Vector2(hx, 0)]:
		cands.append(c + Vector3(d.x, 0, d.y))
	var best: Vector3 = cands[0]
	var best_s: float = -INF
	for cd in cands:
		var sc: float = 99.0
		for pr2 in props:
			var pp: Vector3 = pr2[0]
			sc = minf(sc, Vector2(pp.x - cd.x, pp.z - cd.z).length() - float(pr2[1]))
		if sc > best_s + 0.01:
			best_s = sc
			best = cd
	var dx: float = best.x - c.x
	var dz: float = best.z - c.z
	var kn := Vector3(-signf(dx), 0, 0) if absf(dx) >= absf(dz) and absf(dx) > 0.01 else Vector3(0, 0, -signf(dz) if absf(dz) > 0.01 else 1.0)
	var ksz := Vector3(2.8, 2.7, 2.4) if absf(kn.z) > 0.5 else Vector3(2.4, 2.7, 2.8)
	_boite(b, "in_mur", best + Vector3.UP * 1.35, ksz, true)
	b.box("metal_noir", Transform3D(Basis(), best + Vector3.UP * 2.74), ksz + Vector3(0.2, -2.62, 0.2))
	var yaw: float = atan2(kn.x, kn.z)
	var porte: Vector3 = best + kn * 1.2
	b.box_at("in_porte", porte + kn * 0.03, Vector3(1.0, 2.2, 0.06), yaw)
	b.box_at("in_led_verte", porte + kn * 0.07 + Vector3.UP * 2.35, Vector3(0.5, 0.16, 0.03), yaw)
	b.box_at("lampe_blanche", porte + kn * 0.3 + Vector3.UP * 2.6, Vector3(0.5, 0.04, 0.2), yaw)
	var kr := Rect2(best.x - ksz.x * 0.5, best.z - ksz.z * 0.5, ksz.x, ksz.z)
	info = {"type": "toit", "ascenseur": porte + kn * 1.3, "regard": kn, "y": yt, "rect": rect, "core": kr, "piliers": [], "props": props, "son": "deltaplane_vent"}
	_its_add({"id": "toit155", "pos": porte + kn * 1.0, "radius": 1.6, "text": "E : redescendre", "vr": "Gâchette : redescendre",
		"call": func(): aller(n - 1)})
	var o := OmniLight3D.new()
	o.light_color = Color(1.0, 0.9, 0.75)
	o.light_energy = 0.8
	o.omni_range = 5.0
	_node.add_child(o)
	o.global_position = porte + kn * 0.8 + Vector3.UP * 2.4
	info["son"] = Q.toit(self, b, rng, t)
	b.commit(_node, "Toit_maillage", true)


## La tour dont on est sur le toit (debout dessus), ou {}.
func toit_at(p: Vector3) -> Dictionary:
	var l: Vector2 = IleScript.L(p.x, p.z)
	for t in tours:
		var top: Array = t["b"]["top"]
		var yt: float = IleScript.Y0 + float(t["b"]["h"])
		if absf(p.y - yt) < 1.2 and l.x > float(top[0]) + 0.3 and l.x < float(top[2]) - 0.3 and l.y > float(top[1]) + 0.3 and l.y < float(top[3]) - 0.3:
			return t
	return {}


func _defaire() -> void:
	var dj: Node = main.get("donjon_v35")
	for it in _its:
		if dj != null:
			dj._interactions.erase(it)
	_its.clear()
	for f in _gens:
		if is_instance_valid(f) and f.get("npc") != null and is_instance_valid(f.npc):
			var rid: RID = (f.npc.get("_body") as AnimatableBody3D).get_rid() if f.npc.get("_body") != null else RID()
			if rid.is_valid():
				PnjV31._npc_bodies.erase(rid)
	_gens.clear()
	_ecrans.clear()
	if _node != null and is_instance_valid(_node):
		_node.queue_free()
	_node = null
	_body = null
	info = {}


func _its_add(it: Dictionary) -> void:
	_its.append(it)
	var dj: Node = main.get("donjon_v35")
	if dj != null:
		dj._interactions.append(it)


func _escalier() -> void:
	var n: int = (tours[inside]["etages"] as Array).size()
	var ch: Array = []
	if etage < n - 1:
		ch.append({"id": "+1", "label": "Monter d'un étage"})
	if etage > 0:
		ch.append({"id": "-1", "label": "Descendre d'un étage"})
	if etage == n - 1:
		ch.append({"id": "toit", "label": "Monter sur le toit"})
	ch.append({"id": "rester", "label": "Rester ici"})
	_anchor.global_position = main._player_pos_v27()
	main.ask_v69(_anchor, "Escalier de secours", "serein", "Des marches de béton, une rampe d'acier, une lumière verte. On entend l'écho de ses pas.", ch, _choix_ascenseur)


# =================================================================== les morceaux

## Une boîte (centre, taille) dans le lot ; au besoin, sa collision.
func _boite(b: Kit.Batch, key: String, at: Vector3, size: Vector3, col: bool, yaw: float = 0.0) -> void:
	b.box(key, Transform3D(Basis(Vector3.UP, yaw), at), size)
	if col:
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = size
		cs.shape = sh
		_body.add_child(cs)
		cs.global_transform = Transform3D(Basis(Vector3.UP, yaw), at)


func _col(at: Vector3, size: Vector3, yaw: float = 0.0) -> void:
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	_body.add_child(cs)
	cs.global_transform = Transform3D(Basis(Vector3.UP, yaw), at)


func _label(txt: String, size: int, col: Color) -> Label3D:
	var l := Label3D.new()
	l.text = txt
	l.font_size = size
	l.pixel_size = 0.004
	l.modulate = col
	l.outline_size = 6
	l.outline_modulate = Color(0.02, 0.02, 0.03)
	l.shaded = false
	l.double_sided = false
	_node.add_child(l)
	return l


## Un mur de façade, de a à c (au sol), qui regarde « dedans » : l'allège, le linteau, les meneaux et
## les vitres (alignés sur les fenêtres peintes dehors) ; la porte d'entrée, au besoin.
func _facade(b: Kit.Batch, a: Vector3, c: Vector3, dedans: Vector3, hc: float, colw: float, porte: bool, t: Dictionary) -> void:
	var L: float = a.distance_to(c)
	var u: Vector3 = (c - a).normalized()
	var yaw: float = atan2(u.z, -u.x) if absf(u.x) > 0.5 else atan2(u.z, u.x)
	var ep: float = 0.2
	var o: Vector3 = dedans * ep * 0.5
	var nc: int = maxi(1, int(L / colw))
	var cw: float = L / nc
	var mil: Vector3 = (a + c) * 0.5
	var gap0: float = L * 0.5 - 1.35
	var gap1: float = L * 0.5 + 1.35
	var long_x: bool = absf(u.x) > 0.5
	var sz := func(along: float, h: float, th: float) -> Vector3:
		return Vector3(along, h, th) if long_x else Vector3(th, h, along)
	# l'allège et le linteau (sur toute la longueur ; la porte coupe l'allège)
	if porte:
		b.box("in_mur", Transform3D(Basis(), a + u * (gap0 * 0.5) + o + Vector3.UP * 0.45), sz.call(gap0, 0.9, ep))
		b.box("in_mur", Transform3D(Basis(), a + u * ((gap1 + L) * 0.5) + o + Vector3.UP * 0.45), sz.call(L - gap1, 0.9, ep))
		b.box("in_mur", Transform3D(Basis(), mil + o + Vector3.UP * (2.75 + (hc - 2.75) * 0.5)), sz.call(2.7, hc - 2.75, ep))
	else:
		b.box("in_mur", Transform3D(Basis(), mil + o + Vector3.UP * 0.45), sz.call(L, 0.9, ep))
	b.box("in_mur", Transform3D(Basis(), mil + o + Vector3.UP * (2.55 + (hc - 2.55) * 0.5)), sz.call(L, hc - 2.55, ep))
	# les meneaux, les vitres
	for i in range(nc):
		var u0: float = i * cw
		var u1: float = u0 + cw
		if porte and u1 > gap0 and u0 < gap1:
			continue
		var pm: Vector3 = a + u * (u0 + cw * 0.5) + o + Vector3.UP * 1.72
		b.box("in_vitre", Transform3D(Basis(), pm), sz.call(cw - 0.1, 1.64, 0.03))
		b.box("in_menuiserie", Transform3D(Basis(), a + u * u0 + o + Vector3.UP * 1.72), sz.call(0.1, 1.66, 0.14))
	b.box("in_menuiserie", Transform3D(Basis(), c + o + Vector3.UP * 1.72), sz.call(0.1, 1.66, 0.14))
	# les collisions : le mur entier (moins la porte)
	if porte:
		_col(a + u * (gap0 * 0.5) + o + Vector3.UP * hc * 0.5, sz.call(gap0, hc, ep + 0.1))
		_col(a + u * ((gap1 + L) * 0.5) + o + Vector3.UP * hc * 0.5, sz.call(L - gap1, hc, ep + 0.1))
		# la porte, dedans : sortir
		var pd: Vector3 = mil - dedans * 0.0 + dedans * 1.2
		b.box("verre_fume", Transform3D(Basis(), mil + o + Vector3.UP * 1.35 - u * 0.66), sz.call(1.26, 2.7, 0.04))
		b.box("verre_fume", Transform3D(Basis(), mil + o + Vector3.UP * 1.35 + u * 0.66), sz.call(1.26, 2.7, 0.04))
		_col(mil + Vector3.UP * hc * 0.5 - dedans * 0.3, sz.call(2.7, hc, 0.1))
		_its_add({"id": "sortie153", "pos": pd, "radius": 1.6, "text": "E : sortir dans la rue", "vr": "Gâchette : sortir", "call": leave})
	else:
		_col(mil + o + Vector3.UP * hc * 0.5, sz.call(L, hc, ep + 0.1))


## Est-ce libre (dans l'étage, loin du cœur, hors de l'allée de l'ascenseur et de l'entrée) ?
func _libre(p: Vector3, r: float) -> bool:
	var rect: Rect2 = info["rect"]
	if not rect.grow(-0.4 - r).has_point(Vector2(p.x, p.z)):
		return false
	var core: Rect2 = info["core"]
	if core.grow(1.5 + r).has_point(Vector2(p.x, p.z)):
		return false
	# l'allée de l'ascenseur (vers la porte d'entrée, et au-delà) et celle de l'escalier
	var n: Vector3 = info["regard"]
	var cc := Vector2(core.get_center().x, core.get_center().y)
	var rel := Vector2(p.x, p.z) - cc
	var nn := Vector2(n.x, n.z)
	var lat: float = absf(rel.x * nn.y - rel.y * nn.x)
	if lat < 1.6 + r:
		return false
	for pl in info.get("piliers", []):
		if (pl as Vector2).distance_to(Vector2(p.x, p.z)) < 0.55 + r:
			return false
	for pr in info.get("props", []):
		if Vector2((pr[0] as Vector3).x, (pr[0] as Vector3).z).distance_to(Vector2(p.x, p.z)) < float(pr[1]) + 0.4 + r:
			return false
	return true


func _gens_ajoute(role: String, at: Vector3, face: Vector3, pose: String, rng: RandomNumberGenerator, lignes: Array, android: bool = false) -> Node:
	if _gens.size() >= 14:
		return null
	var prof: Dictionary = Gens.pick("neo_android" if android else "neo", role, rng)
	var f: Node = Figurant.spawn(_node, main, prof, at, face, pose)
	f.lines = lignes
	_gens.append(f)
	var nom: String = str(prof.get("nom", ""))
	_its_add({"id": "gens153_%d" % _gens.size(), "pos": at, "radius": 1.5, "text": "E : parler" + ((" à " + nom) if nom != "" else ""), "vr": "Gâchette : parler",
		"call": func():
			if is_instance_valid(f):
				f.say(str(lignes[randi() % lignes.size()]), 4.0)
				if f.has_method("gesture"):
					f.gesture("salut")})
	return f


func _plante(b: Kit.Batch, at: Vector3, s: float = 1.0) -> void:
	b.cyl("in_pot", Transform3D(Basis(), at + Vector3.UP * 0.25 * s), 0.22 * s, 0.17 * s, 0.5 * s, 10)
	b.cyl("in_terre", Transform3D(Basis(), at + Vector3.UP * 0.49 * s), 0.2 * s, 0.2 * s, 0.03, 10)
	for k in range(5):
		var a: float = TAU * k / 5.0
		b.blob("in_feuille", at + Vector3(cos(a) * 0.14, 0.75 + 0.12 * (k % 2), sin(a) * 0.14) * s + Vector3.UP * 0.1 * s, Vector3(0.2, 0.32, 0.2) * s, 6)
	_col(at + Vector3.UP * 0.4 * s, Vector3(0.45, 0.8, 0.45) * s)


func _chaise(b: Kit.Batch, at: Vector3, face: Vector3) -> void:
	var yaw: float = atan2(face.x, face.z)
	b.box_at("in_chaise", at + Vector3.UP * 0.44, Vector3(0.5, 0.07, 0.48), yaw)
	b.box_at("in_chaise", at - face * 0.22 + Vector3.UP * 0.5, Vector3(0.48, 0.55, 0.05), yaw)
	b.cyl("in_inox", Transform3D(Basis(), at + Vector3.UP * 0.22), 0.03, 0.03, 0.42, 6)
	b.box_at("in_inox", at + Vector3.UP * 0.02, Vector3(0.5, 0.03, 0.06), yaw)
	b.box_at("in_inox", at + Vector3.UP * 0.02, Vector3(0.06, 0.03, 0.5), yaw)


## Un poste de travail : le plateau, les pieds, l'écran, le clavier ; la chaise (« face » : vers l'écran).
func _poste(b: Kit.Batch, at: Vector3, face: Vector3, rng: RandomNumberGenerator) -> void:
	var yaw: float = atan2(face.x, face.z)
	var side: Vector3 = face.cross(Vector3.UP)
	b.box_at("in_bureau", at + Vector3.UP * 0.72, Vector3(1.5, 0.04, 0.75), yaw)
	for s in [-1.0, 1.0]:
		b.box_at("in_inox", at + side * s * 0.68 + Vector3.UP * 0.0, Vector3(0.05, 0.72, 0.65), yaw)
	var ec: Vector3 = at + face * 0.22 + Vector3.UP * 0.76
	b.box_at("in_noir", ec + Vector3.UP * 0.05, Vector3(0.08, 0.1, 0.08), yaw)
	b.box_at("in_noir", ec + Vector3.UP * 0.32, Vector3(0.62, 0.38, 0.03), yaw)
	var ecran: String = ["in_ecran", "in_ecran", "in_ecran_vert", "in_ecran_rose"][rng.randi() % 4]
	b.box_at(ecran, ec + Vector3.UP * 0.32 - face * 0.017, Vector3(0.56, 0.33, 0.005), yaw)
	b.box_at("in_noir", at - face * 0.05 + Vector3.UP * 0.745, Vector3(0.45, 0.015, 0.15), yaw)
	if rng.randf() < 0.5:
		b.cyl("in_bureau", Transform3D(Basis(), at + side * 0.5 + Vector3.UP * 0.79), 0.04, 0.035, 0.1, 8)
	_chaise(b, at - face * 0.6, face)
	_col(at + Vector3.UP * 0.37, Vector3(1.5, 0.74, 0.75) if absf(face.z) > 0.5 else Vector3(0.75, 0.74, 1.5))


# =================================================================== les étages

const LIGNES_BUREAU := ["Encore un rapport pour hier…", "Tu as vu la vue ? On ne s'en lasse pas.", "La réunion de dix heures est déplacée à dix heures.",
	"Mon écran me regarde plus que ma famille.", "Tu es le nouveau stagiaire ? Le café est au fond.", "Les androïdes du dixième font des heures sup' sans râler.",
	"Shhh… je suis en appel holographique.", "Un jour, je démissionne et j'ouvre un stand de nouilles."]
const LIGNES_ANDROIDE := ["BONJOUR. TRAITEMENT DES DONNÉES : 97 %.", "JE NE DORS PAS. JE DÉFRAGMENTE.", "VOTRE BADGE, S'IL VOUS PLAÎT. … MERCI.",
	"IL Y A 4 812 FENÊTRES DANS CETTE TOUR. JE LES AI COMPTÉES."]


func _hall(b: Kit.Batch, rng: RandomNumberGenerator, t: Dictionary) -> void:
	var y: float = info["y"]
	var n: Vector3 = info["regard"]
	var core: Rect2 = info["core"]
	var cc := Vector3(core.get_center().x, y, core.get_center().y)
	var side: Vector3 = n.cross(Vector3.UP)
	var yaw: float = atan2(n.x, n.z)
	var dist: float = (absf(n.x) * core.size.x + absf(n.z) * core.size.y) * 0.5
	# le comptoir d'accueil, entre l'ascenseur et la porte, sur le côté
	var rect: Rect2 = info["rect"]
	var portee: float = (absf(n.x) * rect.size.x + absf(n.z) * rect.size.y) * 0.5
	var ac: Vector3 = cc + n * (dist + (portee - dist) * 0.45) + side * minf(3.4, (absf(n.z) * rect.size.x + absf(n.x) * rect.size.y) * 0.28)
	b.box_at("in_bois", ac, Vector3(2.8, 1.05, 0.8), yaw)
	b.box_at("in_marbre_noir", ac + Vector3.UP * 1.05, Vector3(3.0, 0.06, 0.95), yaw)
	b.box_at("in_neon_accueil", ac + n * 0.41 + Vector3.UP * 0.12, Vector3(2.8, 0.04, 0.02), yaw)
	_col(ac + Vector3.UP * 0.55, Vector3(2.8, 1.1, 0.8) if absf(n.x) < 0.5 else Vector3(0.8, 1.1, 2.8))
	var hote: bool = rng.randf() < 0.5
	_gens_ajoute("femme" if rng.randf() < 0.5 else "homme", ac - n * 0.75, n, "comptoir", rng,
		["Bienvenue chez %s. Les ascenseurs sont au fond." % str(t.get("societe", t["nom"])), "Vous avez rendez-vous ? Non ? Ce n'est pas grave, visitez !", "Le dernier étage ? Tout le monde veut y monter."]
		if not hote else LIGNES_ANDROIDE, hote)
	# le nom de la tour sur le cœur (au-dessus de l'ascenseur, en grand)
	var logo := _label(str(t["nom"]).to_upper(), 110, Kit.NEONS["cyan"])
	logo.global_position = cc + n * (dist + 0.09) + Vector3.UP * maxf(2.62, float(t["e"]) - 0.75)
	logo.look_at(logo.global_position - n, Vector3.UP)
	logo.pixel_size = 0.0025
	# le grand écran (sur une autre face du cœur)
	var fe: Vector3 = cc + side * ((absf(side.x) * core.size.x + absf(side.z) * core.size.y) * 0.5 + 0.05)
	var ecran := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.03, 1.5, 2.6) if absf(side.x) > 0.5 else Vector3(2.6, 1.5, 0.03)
	ecran.mesh = bm
	var em: StandardMaterial3D = (Kit.mat("in_ecran") as StandardMaterial3D).duplicate()
	if ResourceLoader.exists("res://assets/textures/neo/ecrans_larges.png"):
		em.emission_texture = load("res://assets/textures/neo/ecrans_larges.png")
		em.albedo_texture = em.emission_texture
	ecran.material_override = em
	_node.add_child(ecran)
	ecran.global_position = fe + Vector3.UP * 1.7
	_ecrans.append([ecran, rng.randf() * TAU])
	# des canapés, des plantes, de part et d'autre de l'allée
	for s in [-1.0, 1.0]:
		var sp: Vector3 = cc + n * (dist + (portee - dist) * 0.55) - side * s * minf(3.6, (absf(n.z) * rect.size.x + absf(n.x) * rect.size.y) * 0.3)
		if s > 0.0 and _libre(sp, 1.0):
			b.box_at("in_cuir", sp + Vector3.UP * 0.22, Vector3(2.0, 0.44, 0.85), yaw + PI * 0.5)
			b.box_at("in_cuir", sp - side * 0.38 * s + Vector3.UP * 0.55, Vector3(2.0, 0.5, 0.15), yaw + PI * 0.5)
			_col(sp + Vector3.UP * 0.4, Vector3(0.9, 0.8, 2.0) if absf(n.x) < 0.5 else Vector3(2.0, 0.8, 0.9))
			if rng.randf() < 0.6:
				_gens_ajoute("homme" if rng.randf() < 0.5 else "femme", sp + side * 0.0 + Vector3.UP * 0.0, -side * s, "assis", rng,
					["J'attends mon rendez-vous depuis une heure.", "Ces canapés sont plus confortables que mon lit.", "Tu travailles ici, toi ?"])
	# des coins salon (deux banquettes, une table basse, un tapis, une plante), dans les grandes bandes
	var nsal: int = 0
	for bd in _bandes():
		var nx2: int = int(bd.size.x / 7.0)
		var nz2: int = int(bd.size.y / 7.0)
		for ix2 in range(nx2):
			for iz2 in range(nz2):
				var sc := Vector3(bd.position.x + (ix2 + 0.5) * bd.size.x / nx2, y, bd.position.y + (iz2 + 0.5) * bd.size.y / nz2)
				if not _libre(sc, 2.0) or nsal >= 8:
					continue
				nsal += 1
				b.box_at("in_tissu_rouge" if nsal % 2 == 0 else "in_tissu_gris", sc + Vector3.UP * 0.005, Vector3(3.2, 0.012, 2.4))
				b.box_at("in_marbre_noir", sc, Vector3(1.0, 0.4, 0.6))
				_col(sc + Vector3.UP * 0.2, Vector3(1.0, 0.4, 0.6))
				for sg in [-1.0, 1.0]:
					var bp: Vector3 = sc + Vector3(0, 0, sg * 1.1)
					b.box_at("in_cuir", bp, Vector3(2.0, 0.44, 0.8))
					b.box_at("in_cuir", bp + Vector3(0, 0, sg * 0.36), Vector3(2.0, 0.85, 0.14))
					_col(bp + Vector3.UP * 0.4, Vector3(2.0, 0.8, 0.85))
				if rng.randf() < 0.55:
					_gens_ajoute(["homme", "femme", "vieux", "vieille"][rng.randi() % 4], sc + Vector3(rng.randf_range(-0.6, 0.6), 0, 1.05), Vector3(0, 0, -1), "assis", rng,
						["J'attends mon rendez-vous depuis une heure.", "Ces banquettes sont plus confortables que mon lit.", "Tu travailles ici, toi ?", "On dit qu'au dernier étage, il y a un aquarium."])
				_plante(b, sc + Vector3(1.6, 0, 0), 1.4)
	for k in range(10):
		var pp: Vector3 = Vector3(rng.randf_range(rect.position.x + 0.8, rect.end.x - 0.8), y, rng.randf_range(rect.position.y + 0.8, rect.end.y - 0.8))
		if _libre(pp, 0.6):
			_plante(b, pp, rng.randf_range(1.2, 1.8))
	# le vigile, près de l'ascenseur
	_gens_ajoute("homme", cc + n * (dist + 1.0) - side * 2.2, n, "bras_croises", rng,
		["Les étages ? Montez, mais ne touchez à rien.", "Tout est calme. Trop calme.", "Il y a des caméras partout. Souriez."])


func _bandes() -> Array:
	# les quatre bandes autour du cœur (moins l'allée), en Rect2 monde
	var rect: Rect2 = info["rect"]
	var core: Rect2 = info["core"].grow(1.5)
	var out: Array = []
	out.append(Rect2(rect.position.x, rect.position.y, rect.size.x, core.position.y - rect.position.y))
	out.append(Rect2(rect.position.x, core.end.y, rect.size.x, rect.end.y - core.end.y))
	out.append(Rect2(rect.position.x, core.position.y, core.position.x - rect.position.x, core.size.y))
	out.append(Rect2(core.end.x, core.position.y, rect.end.x - core.end.x, core.size.y))
	var ok: Array = []
	for r in out:
		if r.size.x > 2.0 and r.size.y > 2.0:
			ok.append(r)
	return ok


func _bureaux(b: Kit.Batch, rng: RandomNumberGenerator, t: Dictionary) -> void:
	var y: float = info["y"]
	var bandes: Array = _bandes()
	# la plus grande bande (hors allée) devient parfois la salle de réunion
	var reunion: int = -1
	var best: float = 0.0
	for i in range(bandes.size()):
		var r: Rect2 = bandes[i]
		if r.get_area() > best and minf(r.size.x, r.size.y) > 4.5:
			best = r.get_area()
			reunion = i
	if rng.randf() < 0.35:
		reunion = -1
	var n_gens: int = 0
	for i2 in range(bandes.size()):
		var r2: Rect2 = bandes[i2]
		if i2 == reunion:
			_reunion(b, rng, r2, y)
			continue
		# les postes, en rangées le long du grand côté de la bande
		var le_long_x: bool = r2.size.x >= r2.size.y
		var pas_a: float = 1.7
		var pas_b: float = 2.9
		var na: int = int(((r2.size.x if le_long_x else r2.size.y) - 1.2) / pas_a)
		var nb: int = int(((r2.size.y if le_long_x else r2.size.x) - 0.8) / pas_b)
		for ia in range(na):
			for ib in range(maxi(nb, 1)):
				for s in [-1.0, 1.0]:
					var ua: float = (r2.position.x if le_long_x else r2.position.y) + 0.6 + (ia + 0.5) * pas_a
					var ub: float = (r2.position.y if le_long_x else r2.position.x) + 0.4 + (ib + 0.5) * pas_b + s * 0.42
					var p := Vector3(ua, y, ub) if le_long_x else Vector3(ub, y, ua)
					var face := Vector3(0, 0, -s) if le_long_x else Vector3(-s, 0, 0)
					if not _libre(p, 0.9):
						continue
					_poste(b, p, face, rng)
					if rng.randf() < 0.3 and n_gens < 8:
						n_gens += 1
						_gens_ajoute("femme" if rng.randf() < 0.5 else "homme", p - face * 0.62, face, "assis", rng, LIGNES_BUREAU, rng.randf() < 0.15)
	# des plantes, une fontaine à eau, l'imprimante
	var rect: Rect2 = info["rect"]
	for k in range(4):
		var pp := Vector3(rect.position.x + 0.8 if k % 2 == 0 else rect.end.x - 0.8, y, rect.position.y + 0.8 if k < 2 else rect.end.y - 0.8)
		if _libre(pp, 0.3):
			_plante(b, pp, 1.3)
	var core: Rect2 = info["core"]
	var fp := Vector3(core.end.x + 0.5, y, core.position.y - 0.6)
	b.box_at("in_bureau", fp, Vector3(0.35, 1.0, 0.35))
	b.cyl("in_vitre", Transform3D(Basis(), fp + Vector3.UP * 1.2), 0.15, 0.15, 0.4, 10)
	_col(fp + Vector3.UP * 0.5, Vector3(0.35, 1.0, 0.35))
	if rng.randf() < 0.6:
		_gens_ajoute("homme" if rng.randf() < 0.5 else "femme", fp + Vector3(0.7, 0, 0), Vector3(-1, 0, 0), "debout", rng,
			["Ici, on refait le monde. Et on boit de l'eau.", "Tu connais la dernière ? Le patron veut une piscine sur le toit.", "Chut, voilà la cheffe."])


func _reunion(b: Kit.Batch, rng: RandomNumberGenerator, r: Rect2, y: float) -> void:
	var hc: float = float(tours[inside]["e"]) - 0.35
	var c := Vector3(r.get_center().x, y, r.get_center().y)
	var le_long_x: bool = r.size.x >= r.size.y
	# les cloisons de verre (le côté du cœur, avec une porte)
	var core: Rect2 = info["core"]
	var cote_z: bool = r.end.y <= core.position.y + 0.01 or r.position.y >= core.end.y - 0.01
	if cote_z:
		var zc: float = r.end.y - 0.1 if r.end.y <= core.position.y + 1.6 else r.position.y + 0.1
		var x0: float = r.position.x + 0.3
		var x1: float = r.end.x - 0.3
		var xm: float = (x0 + x1) * 0.5
		for seg in [[x0, xm - 0.6], [xm + 0.6, x1]]:
			var l: float = float(seg[1]) - float(seg[0])
			if l > 0.2:
				var p := Vector3((float(seg[0]) + float(seg[1])) * 0.5, y + hc * 0.5, zc)
				b.box_at("in_cloison_verre", p + Vector3.DOWN * hc * 0.5, Vector3(l, hc, 0.04))
				b.box_at("in_menuiserie", p + Vector3.UP * (hc * 0.5 - 0.08), Vector3(l, 0.08, 0.08))
				_col(p, Vector3(l, hc, 0.1))
	else:
		var xc: float = r.end.x - 0.1 if r.end.x <= core.position.x + 1.6 else r.position.x + 0.1
		var z0: float = r.position.y + 0.3
		var z1: float = r.end.y - 0.3
		var zm: float = (z0 + z1) * 0.5
		for seg2 in [[z0, zm - 0.6], [zm + 0.6, z1]]:
			var l2: float = float(seg2[1]) - float(seg2[0])
			if l2 > 0.2:
				var p2 := Vector3(xc, y + hc * 0.5, (float(seg2[0]) + float(seg2[1])) * 0.5)
				b.box_at("in_cloison_verre", p2 + Vector3.DOWN * hc * 0.5, Vector3(0.04, hc, l2))
				b.box_at("in_menuiserie", p2 + Vector3.UP * (hc * 0.5 - 0.08), Vector3(0.08, 0.08, l2))
				_col(p2, Vector3(0.1, hc, l2))
	# la grande table, les chaises, l'écran
	var lt: float = clampf((r.size.x if le_long_x else r.size.y) * 0.55, 2.4, 6.0)
	var tsz := Vector3(lt, 0.05, 1.2) if le_long_x else Vector3(1.2, 0.05, lt)
	b.box_at("in_bois", c + Vector3.UP * 0.74, tsz)
	b.box_at("in_noir", c, Vector3(tsz.x * 0.6, 0.74, tsz.z * 0.4))
	_col(c + Vector3.UP * 0.38, Vector3(tsz.x, 0.76, tsz.z))
	var nch: int = int(lt / 1.0)
	var places: Array = []
	for i in range(nch):
		for s in [-1.0, 1.0]:
			var u: float = -lt * 0.5 + (i + 0.5) * lt / nch
			var p3: Vector3 = c + (Vector3(u, 0, s * 0.95) if le_long_x else Vector3(s * 0.95, 0, u))
			var f3: Vector3 = Vector3(0, 0, -s) if le_long_x else Vector3(-s, 0, 0)
			_chaise(b, p3, f3)
			places.append([p3, f3])
	places.shuffle()
	for k in range(mini(3, places.size())):
		_gens_ajoute("femme" if rng.randf() < 0.5 else "homme", places[k][0], places[k][1], "assis", rng,
			["Bon. Qui a une idée ?", "Le budget, encore le budget…", "On pourrait mettre des hologrammes partout ?", "Je propose une pause."])
	var ec := MeshInstance3D.new()
	var bm := BoxMesh.new()
	var bout: Vector3 = c + (Vector3(lt * 0.5 + 0.8, 0, 0) if le_long_x else Vector3(0, 0, lt * 0.5 + 0.8))
	bm.size = Vector3(0.04, 1.0, 1.7) if le_long_x else Vector3(1.7, 1.0, 0.04)
	ec.mesh = bm
	ec.material_override = (Kit.mat("in_ecran_vert") as StandardMaterial3D).duplicate()
	_node.add_child(ec)
	ec.global_position = bout + Vector3.UP * 1.5
	_ecrans.append([ec, rng.randf() * TAU])
	if _libre(bout - (Vector3(0.6, 0, 0) if le_long_x else Vector3(0, 0, 0.6)), 0.2):
		_gens_ajoute("homme" if rng.randf() < 0.5 else "femme", bout - (Vector3(0.7, 0, 0) if le_long_x else Vector3(0, 0, 0.7)),
			-(Vector3(1, 0, 0) if le_long_x else Vector3(0, 0, 1)), "bras_croises", rng, ["Comme vous le voyez sur ce graphique… tout monte !", "Des questions ? Non ? Parfait."])


func _cafeteria(b: Kit.Batch, rng: RandomNumberGenerator, t: Dictionary) -> void:
	var y: float = info["y"]
	var n_g: int = 0
	for r in _bandes():
		var nx: int = int((r.size.x - 1.0) / 2.6)
		var nz: int = int((r.size.y - 1.0) / 2.6)
		for ix in range(nx):
			for iz in range(nz):
				var p := Vector3(r.position.x + 0.5 + (ix + 0.5) * (r.size.x - 1.0) / nx, y, r.position.y + 0.5 + (iz + 0.5) * (r.size.y - 1.0) / nz)
				if not _libre(p, 1.1):
					continue
				b.cyl("in_bois_clair", Transform3D(Basis(), p + Vector3.UP * 0.73), 0.45, 0.45, 0.04, 16)
				b.cyl("in_inox", Transform3D(Basis(), p + Vector3.UP * 0.36), 0.04, 0.04, 0.72, 6)
				b.cyl("in_inox", Transform3D(Basis(), p + Vector3.UP * 0.01), 0.25, 0.25, 0.02, 10)
				_col(p + Vector3.UP * 0.38, Vector3(0.9, 0.76, 0.9))
				for k in range(3):
					var a: float = TAU * k / 3.0 + rng.randf() * 0.3
					var cp: Vector3 = p + Vector3(cos(a), 0, sin(a)) * 0.78
					var f: Vector3 = (p - cp).normalized()
					_chaise(b, cp, f)
					if rng.randf() < 0.25 and n_g < 9:
						n_g += 1
						_gens_ajoute("femme" if rng.randf() < 0.5 else "homme", cp, f, "assis", rng,
							["Les nouilles de la cantine sont meilleures que celles du marché. Ne le dis à personne.", "Pause ! Enfin.", "Tu as goûté le thé aux bulles ?"])
				if rng.randf() < 0.5:
					b.cyl("in_bureau", Transform3D(Basis(), p + Vector3(0.15, 0.8, 0.05)), 0.05, 0.04, 0.1, 8)
	# le comptoir : la machine à café, le frigo
	var core: Rect2 = info["core"]
	var n: Vector3 = info["regard"]
	var side: Vector3 = n.cross(Vector3.UP)
	var cc := Vector3(core.get_center().x, y, core.get_center().y)
	var fl: Vector3 = cc + side * ((absf(side.x) * core.size.x + absf(side.z) * core.size.y) * 0.5 + 0.35)
	var yaw: float = atan2(side.x, side.z)
	b.box_at("in_bois", fl, Vector3(2.4, 0.92, 0.6), yaw)
	b.box_at("in_marbre_noir", fl + Vector3.UP * 0.92, Vector3(2.5, 0.04, 0.65), yaw)
	b.box_at("in_inox", fl + Vector3.UP * 0.94 + side.cross(Vector3.UP) * 0.7, Vector3(0.4, 0.5, 0.4), yaw)
	b.box_at("in_inox", fl - side.cross(Vector3.UP) * 1.6 + Vector3.UP * 0.0, Vector3(0.8, 1.9, 0.7), yaw)
	_col(fl + Vector3.UP * 0.46, Vector3(2.4, 0.92, 0.6) if absf(side.z) > 0.5 else Vector3(0.6, 0.92, 2.4))
	_gens_ajoute("homme" if rng.randf() < 0.5 else "femme", fl + side * 0.9, -side, "debout", rng,
		["Un café ? La machine fait aussi des smoothies aux algues.", "Le distributeur m'a encore volé une pièce."])


func _serveurs(b: Kit.Batch, rng: RandomNumberGenerator, t: Dictionary) -> void:
	var y: float = info["y"]
	for r in _bandes():
		var le_long_x: bool = r.size.x >= r.size.y
		var nrows: int = maxi(1, int(((r.size.y if le_long_x else r.size.x) - 1.0) / 2.4))
		var long: float = (r.size.x if le_long_x else r.size.y) - 1.6
		var nr: int = maxi(1, int(long / 0.65))
		for ir in range(nrows):
			var ub: float = (r.position.y if le_long_x else r.position.x) + 0.5 + (ir + 0.5) * ((r.size.y if le_long_x else r.size.x) - 1.0) / nrows
			for k in range(nr):
				var ua: float = (r.position.x if le_long_x else r.position.y) + 0.8 + (k + 0.5) * long / nr
				var p := Vector3(ua, y, ub) if le_long_x else Vector3(ub, y, ua)
				if not _libre(p, 0.4):
					continue
				b.box_at("in_rack", p, Vector3(0.6, 2.0, 1.0) if le_long_x else Vector3(1.0, 2.0, 0.6))
				for sgn in [-1.0, 1.0]:
					var off := Vector3(0, 0, 0.505 * sgn) if le_long_x else Vector3(0.505 * sgn, 0, 0)
					b.box_at("in_menuiserie", p + off * 0.99 + Vector3.UP * 0.05, Vector3(0.56, 1.9, 0.01) if le_long_x else Vector3(0.01, 1.9, 0.56))
					for led in range(7):
						var lk: String = ["in_led_bleue", "in_led_verte", "in_led_bleue", "in_led_ambre"][rng.randi() % 4]
						b.box_at(lk, p + off * 1.01 + Vector3.UP * (0.25 + led * 0.24) + (Vector3(rng.randf_range(-0.2, 0.2), 0, 0) if le_long_x else Vector3(0, 0, rng.randf_range(-0.2, 0.2))), Vector3(0.05, 0.025, 0.01) if le_long_x else Vector3(0.01, 0.025, 0.05))
				_col(p + Vector3.UP * 1.0, Vector3(0.6, 2.0, 1.0) if le_long_x else Vector3(1.0, 2.0, 0.6))
	var o := OmniLight3D.new()
	o.light_color = Color(0.3, 0.6, 1.0)
	o.light_energy = 1.5
	o.omni_range = 12.0
	_node.add_child(o)
	o.global_position = Vector3(info["rect"].get_center().x, y + 2.0, info["rect"].get_center().y)
	var core: Rect2 = info["core"]
	_gens_ajoute("homme", Vector3(core.end.x + 0.9, y, core.get_center().y), Vector3(1, 0, 0), "bricoler", rng,
		["Ne touche à rien. Surtout pas au bouton rouge.", "Ici il fait 18 degrés toute l'année. J'ai froid.", "Tu entends ce bourdonnement ? Ce sont les données qui chantent."], rng.randf() < 0.5)


func _direction(b: Kit.Batch, rng: RandomNumberGenerator, t: Dictionary) -> void:
	var y: float = info["y"]
	var bandes: Array = _bandes()
	var best: Rect2 = bandes[0]
	for r in bandes:
		if r.get_area() > best.get_area():
			best = r
	var c := Vector3(best.get_center().x, y, best.get_center().y)
	# le grand bureau de bois sombre, le fauteuil, le canapé de cuir, la table basse
	b.box_at("in_bois", c + Vector3.UP * 0.0, Vector3(2.4, 0.76, 1.0))
	b.box_at("in_marbre_noir", c + Vector3.UP * 0.76, Vector3(2.5, 0.04, 1.1))
	_col(c + Vector3.UP * 0.4, Vector3(2.4, 0.8, 1.0))
	b.box_at("in_cuir", c + Vector3(0, 0, -1.25), Vector3(0.7, 1.15, 0.15))
	_gens_ajoute("homme" if rng.randf() < 0.5 else "femme", c + Vector3(0, 0, -0.85), Vector3(0, 0, 1), "assis", rng,
		["Ah, vous voilà. Asseyez-vous… non, restez debout, c'est plus rapide.", "D'ici, je vois toute la ville. Et la ville me voit.", "Mon conseil ? Achetez des actions de nouilles."])
	for k in range(3):
		var pp := Vector3(best.position.x + 0.8 + k * (best.size.x - 1.6) * 0.5, y, best.end.y - 0.8)
		if _libre(pp, 0.4):
			_plante(b, pp, 1.5)
	b.box_at("in_tissu_rouge", c + Vector3.UP * 0.005, Vector3(5.0, 0.012, 3.6))
	for k2 in range(int(best.size.x / 1.2)):
		var bp: Vector3 = Vector3(best.position.x + 0.6 + k2 * 1.2, y, best.position.y + 0.35)
		if _libre(bp, 0.3):
			b.box_at("in_bois", bp, Vector3(1.1, 2.2, 0.4))
			for et in range(4):
				b.box_at(["in_tissu_rouge", "in_tissu_gris", "in_bois_clair", "in_noir"][(k2 + et) % 4], bp + Vector3(0, 0.25 + et * 0.5, 0.05), Vector3(0.9, 0.32, 0.25))
			_col(bp + Vector3.UP * 1.1, Vector3(1.1, 2.2, 0.4))
	# un aquarium (une grande vitre bleue lumineuse, des poissons-points)
	var other: Rect2 = bandes[(bandes.find(best) + 1) % bandes.size()]
	var ac := Vector3(other.get_center().x, y, other.get_center().y)
	if _libre(ac, 1.0):
		b.box_at("in_noir", ac, Vector3(2.4, 0.8, 0.7))
		b.box_at("in_led_bleue", ac + Vector3.UP * 0.8, Vector3(2.3, 1.0, 0.6))
		_col(ac + Vector3.UP * 0.9, Vector3(2.4, 1.8, 0.7))
		b.box_at("in_cuir", ac + Vector3(0, 0, 1.6) + Vector3.UP * 0.22, Vector3(2.0, 0.44, 0.85))
		_col(ac + Vector3(0, 0, 1.6) + Vector3.UP * 0.3, Vector3(2.0, 0.6, 0.85))


func _logements(b: Kit.Batch, rng: RandomNumberGenerator, t: Dictionary) -> void:
	# un couloir autour du cœur ; les appartements derrière ses murs (on frappe aux portes)
	var y: float = info["y"]
	var hc: float = float(t["e"]) - 0.35
	var core: Rect2 = info["core"]
	var rect: Rect2 = info["rect"]
	var cr: Rect2 = core.grow(1.7)
	cr = Rect2(maxf(cr.position.x, rect.position.x + 1.0), maxf(cr.position.y, rect.position.y + 1.0), 0, 0).expand(Vector2(minf(cr.end.x, rect.end.x - 1.0), minf(cr.end.y, rect.end.y - 1.0)))
	var sides: Array = [[Vector2(cr.position.x, cr.position.y), Vector2(cr.end.x, cr.position.y), Vector3(0, 0, -1)],
		[Vector2(cr.position.x, cr.end.y), Vector2(cr.end.x, cr.end.y), Vector3(0, 0, 1)],
		[Vector2(cr.position.x, cr.position.y), Vector2(cr.position.x, cr.end.y), Vector3(-1, 0, 0)],
		[Vector2(cr.end.x, cr.position.y), Vector2(cr.end.x, cr.end.y), Vector3(1, 0, 0)]]
	var num: int = etage * 100 + 1
	var n: Vector3 = info["regard"]
	var nvois: int = 0
	for s in sides:
		var a := Vector3((s[0] as Vector2).x, y, (s[0] as Vector2).y)
		var c := Vector3((s[1] as Vector2).x, y, (s[1] as Vector2).y)
		var dehors: Vector3 = s[2]
		var L: float = a.distance_to(c)
		if L < 0.5:
			continue
		var u: Vector3 = (c - a).normalized()
		var long_x: bool = absf(u.x) > 0.5
		# au rez-de-chaussée, le côté de l'entrée reste ouvert (le hall)
		if etage == 0 and dehors.dot(n) > 0.5:
			continue
		var mil: Vector3 = (a + c) * 0.5
		var portes: int = maxi(1, int(L / 4.2))
		var trou: bool = absf(dehors.dot(n)) > 0.5
		# V155 : la profondeur des appartements (du mur du couloir au nu de la façade)
		var fac: float
		if dehors.z < -0.5:
			fac = rect.position.y + 0.2
		elif dehors.z > 0.5:
			fac = rect.end.y - 0.2
		elif dehors.x < -0.5:
			fac = rect.position.x + 0.2
		else:
			fac = rect.end.x - 0.2
		var P: float = absf(fac - (a.z if absf(dehors.z) > 0.5 else a.x)) - 0.08
		# les portes : [le long, début de l'appartement, fin, numéro]
		var dl: Array = []
		for k in range(portes):
			var up: float = (k + 0.5) * L / portes
			if trou and absf(up - L * 0.5) < 1.8:
				continue
			var r0: float = k * L / portes
			var r1: float = (k + 1) * L / portes
			if trou:
				if up < L * 0.5:
					r1 = minf(r1, L * 0.5 - 1.3)
				else:
					r0 = maxf(r0, L * 0.5 + 1.3)
			dl.append([up, r0, r1, num])
			num += 1
		var ouvert: Array = []
		for d0 in dl:
			if int(d0[3]) == _ouverte:
				ouvert = d0
		# le mur du couloir (une ouverture devant l'ascenseur et devant l'escalier ; la porte ouverte)
		var segs: Array = [[0.0, L]] if not trou else [[0.0, L * 0.5 - 1.3], [L * 0.5 + 1.3, L]]
		if not ouvert.is_empty():
			var g0: float = float(ouvert[0]) - 0.55
			var g1: float = float(ouvert[0]) + 0.55
			var s2: Array = []
			for sg0 in segs:
				if float(sg0[1]) <= g0 or float(sg0[0]) >= g1:
					s2.append(sg0)
				else:
					s2.append([float(sg0[0]), g0])
					s2.append([g1, float(sg0[1])])
			segs = s2
			b.box("in_mur_couloir", Transform3D(Basis(), a + u * float(ouvert[0]) + Vector3.UP * (2.2 + (hc - 2.2) * 0.5)), Vector3(1.1, hc - 2.2, 0.15) if long_x else Vector3(0.15, hc - 2.2, 1.1))
		for sg in segs:
			var l0: float = sg[0]
			var l1: float = sg[1]
			if l1 - l0 < 0.2:
				continue
			var pm: Vector3 = a + u * ((l0 + l1) * 0.5) + Vector3.UP * hc * 0.5
			var sz := Vector3(l1 - l0, hc, 0.15) if long_x else Vector3(0.15, hc, l1 - l0)
			b.box("in_mur_couloir", Transform3D(Basis(), pm), sz)
			_col(pm, sz)
		if trou and P > 0.5:
			# l'ouverture : un palier, une fenêtre au bout (fermé sur les côtés : derrière, ce sont les appartements)
			for sg2 in [L * 0.5 - 1.3, L * 0.5 + 1.3]:
				var pw: Vector3 = a + u * sg2 + dehors * (P * 0.5 + 0.08) + Vector3.UP * hc * 0.5
				var szw := Vector3(0.12, hc, P) if long_x else Vector3(P, hc, 0.12)
				b.box("in_mur_couloir", Transform3D(Basis(), pw), szw)
				_col(pw, szw)
		for d1 in dl:
			var up2: float = d1[0]
			var nm: int = d1[3]
			var pp: Vector3 = a + u * up2
			var yaw: float = atan2(-dehors.x, -dehors.z)
			var W: float = float(d1[2]) - float(d1[1])
			var ouvrable: bool = P >= 3.4 and W >= 3.2 and up2 - float(d1[1]) >= 0.9 and float(d1[2]) - up2 >= 0.9 and (int(t["id"]) * 7 + nm * 13) % 3 == 0
			var lab := _label("%d" % nm, 40, Color(0.95, 0.9, 0.75))
			lab.global_position = pp - dehors * 0.12 + Vector3.UP * 2.0
			lab.look_at(lab.global_position + dehors, Vector3.UP)
			if nm == _ouverte and ouvrable:
				# la porte ouverte (contre le mur, du côté opposé à l'hôte), le chambranle, l'appartement
				var gauche: bool = up2 - float(d1[1]) >= W * 0.5
				var hs: float = -1.0 if gauche else 1.0
				b.box_at("in_porte_bois", pp + u * hs * 0.45 + dehors * 0.56, Vector3(0.05, 2.15, 0.95), yaw)
				for sj in [-0.52, 0.52]:
					b.box_at("in_menuiserie", pp + u * sj, Vector3(0.06, 2.2, 0.2), yaw)
				var rng2 := RandomNumberGenerator.new()
				rng2.seed = int(t["id"]) * 7717 + nm * 97
				Q.appartement(self, b, rng2, {"O": a + u * float(d1[1]) + dehors * 0.08, "U": u, "D": dehors, "W": W, "P": P, "porte": up2 - float(d1[1]), "hc": hc})
				continue
			b.box_at("in_porte_bois", pp - dehors * 0.09, Vector3(0.95, 2.15, 0.05), yaw)
			b.box_at("in_inox", pp - dehors * 0.13 + u * 0.32 + Vector3.UP * 1.0, Vector3(0.12, 0.03, 0.04), yaw)
			var nom_porte: String = "%d" % nm
			_its_add({"id": "porte153_%d" % nm, "pos": pp - dehors * 0.8, "radius": 1.0, "text": "E : frapper à la porte " + nom_porte,
				"vr": "Gâchette : frapper", "call": _frapper.bind(nom_porte, ouvrable)})
		# un voisin dans le couloir, une plante
		if rng.randf() < 0.45 and nvois < 3:
			nvois += 1
			var vp: Vector3 = mil - dehors * 0.85
			_gens_ajoute(["homme", "femme", "vieux", "vieille", "garcon", "fille"][rng.randi() % 6], vp, u if rng.randf() < 0.5 else -u, "debout", rng,
				["Bonjour, voisin ! … Ah non, je ne vous connais pas.", "L'ascenseur est encore en panne ? Non ? Tant mieux.", "Le monsieur du dessus fait du karaoké à trois heures du matin.",
				"Tu as vu les carpes holographiques ? Ma fille les adore."])
		elif rng.randf() < 0.5:
			_plante(b, a + u * 0.6 - dehors * 0.6, 1.0)


const REPONSES_PORTE := ["Personne ne répond.", "Une voix étouffée : « Pas aujourd'hui, merci ! »", "On entend un chat miauler derrière la porte.",
	"« C'est pour la livraison de nouilles ? … Non ? Dommage. »", "Une télé hurle un jeu télévisé. Personne n'entend.", "« Qui est là ? … Je ne vous connais pas ! »",
	"Un robot ménager répond : « LES OCCUPANTS SONT ABSENTS. VEUILLEZ RÉESSAYER. »", "Des rires, de la musique : une fête. On ne vous entend pas."]


func _frapper(num: String, ouvrable: bool = false) -> void:
	main.sfx("toc_porte", main._player_pos_v27())
	if ouvrable and not busy and inside >= 0:
		main._show_message_v28("Porte %s : « Entrez donc ! » — chez les %s." % [num, famille(int(num))])
		_ouvrir(int(num))
		return
	main._show_message_v28("Porte %s : %s" % [num, str(REPONSES_PORTE[randi() % REPONSES_PORTE.size()])])


func famille(num: int) -> String:
	return str(FAMILLES[(maxi(inside, 0) * 3 + num) % FAMILLES.size()])


## V155 : la porte s'ouvre ; l'étage se rebâtit avec l'appartement derrière (on ne bouge pas).
func _ouvrir(num: int) -> void:
	busy = true
	await _fade(1.0, 0.18)
	_defaire()
	_ouverte = num
	_batir(etage)
	_grace = 1.0
	await _fade(0.0, 0.3)
	busy = false
	main.sfx("porte_ouvre", main._player_pos_v27())


# =================================================================== la sauvegarde

func serialize() -> Dictionary:
	return {"visites": visites.keys()}


func load_data(d: Dictionary) -> void:
	sortir_vite()
	visites = {}
	for k in d.get("visites", []):
		visites[int(k)] = true
