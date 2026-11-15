extends RefCounted
## V155 : les quartiers de Néopolis, dedans (ce que tours_v153 bâtit selon le quartier de la tour) :
##  - le Quai : au rez-de-chaussée des tours de bureaux, un hangar (des rayonnages, des piles de caisses,
##    un chariot-robot, des drones sur leurs socles de recharge, des dockers, un androïde trieur) ;
##  - les Ruelles : au pied des immeubles, une échoppe (un atelier de réparation de robots, un comptoir
##    de nouilles, une boutique d'électronique) ; au-dessus, les logements ;
##  - les Arcades : la salle de jeux au rez-de-chaussée (des bornes, des pinces à peluches, une machine
##    à danser), puis des étages de karaoké (des cabines vitrées, des chanteurs) et d'hôtel capsule ;
##  - les appartements : certaines portes s'ouvrent quand on frappe (« Entrez donc ! ») : l'entrée et la
##    cuisine, le séjour (le canapé, la télé, parfois le lit), les habitants (et parfois leur robot) ;
##  - les toits : un jardin suspendu (des bacs, des guirlandes, du linge qui sèche), une hélistation ou
##    des panneaux solaires sur les tours de bureaux, une longue-vue.
## Les fonctions reçoivent T (tours_v153) : l'étage en cours (T.info), ses outils (_col, _boite,
## _gens_ajoute, _plante, _chaise, _label, _libre, _its_add) ; elles rendent le son de l'arrivée.

const Kit = preload("res://scripts/neo_kit_v94.gd")

const LIGNES_HANGAR := ["Attention, le chariot recule ! … Il recule toujours, en fait.", "Trois cents caisses à charger avant ce soir. Et un seul chariot.",
	"Les drones livrent tout, même les nouilles. Surtout les nouilles.", "Ce qu'il y a dans les caisses ? Des caisses plus petites.",
	"Le patron dit que le quai ne dort jamais. Moi si."]
const LIGNES_TRI := ["COLIS 4471 : DESTINATION LES HAUTS. COLIS 4472 : DESTINATION… INCONNUE.", "JE TRIE. TU TRIES. NOUS TRIONS.",
	"UN DRONE SUR TROIS REVIENT AVEC UN PIGEON. J'ENQUÊTE."]
const LIGNES_MECANO := ["Il a perdu un bras en jouant au ping-pong. Je lui en mets un neuf.", "Passe-moi la clé de douze… non, l'autre clé de douze.",
	"Les robots, c'est comme les gens : il faut les écouter. Celui-là grince quand il est triste.", "Ici, on répare tout. Sauf les cœurs brisés. Quoique…"]
const LIGNES_CLIENT_ROBOT := ["MON PROPRIÉTAIRE DIT QUE JE FAIS UN BRUIT BIZARRE. BZZT. QUEL BRUIT ?", "JE SUIS ICI POUR UNE MISE À JOUR. ET UN PEU D'HUILE."]
const LIGNES_CUISINIER := ["Un ramen ? Le bouillon mijote depuis trois jours. Ou quatre.", "Ici, les nouilles sont tirées à la main. Par moi.",
	"Attention, c'est chaud ! Et c'est bon.", "Mon secret ? Un peu de gingembre, et beaucoup de patience."]
const LIGNES_CLIENT_NOUILLES := ["Slurp ! … Pardon. C'est trop bon.", "Je viens ici tous les soirs depuis dix ans.", "Les gyoza sont croustillants comme il faut.",
	"Le robot des nouilles du marché ? Bof. Ici, c'est meilleur."]
const LIGNES_VENDEUR := ["Un casque holographique ? Dernier modèle. Enfin, jusqu'à demain.", "Tout est garanti trois jours. Ou trois minutes, selon l'humeur du robot.",
	"Vous cherchez un câble ? J'ai tous les câbles. Même ceux qui n'existent pas encore."]
const LIGNES_CLIENT_BOUTIQUE := ["Je compare les prix. Depuis deux heures.", "Mon robot-chat a besoin d'une nouvelle queue.", "Ça brille, ça bipe… je prends !"]
const LIGNES_JOUEUR := ["Chut ! Je bats le record. … Raté.", "Encore une pièce, juste une !", "La pince est truquée, je te dis. Elle ne serre jamais.",
	"Tu connais le code secret ? Haut, haut, bas, bas…"]
const LIGNES_KARAOKE := ["♪ Néopolis, ville de lumière… ♪ Tu chantes avec nous ?", "C'est mon tour ! Passe-moi le micro !", "Il chante faux, mais avec tellement de cœur…",
	"On a réservé jusqu'à l'aube. Ou jusqu'à ce que ma voix lâche."]
const PAROLES := ["♪ Néopolis, ville de lumière… ♪", "♪ Sous les néons, je t'attendrai… ♪", "♪ Monorail de mon cœur… ♪", "♪ Danse, danse, carpe de lumière… ♪"]
const LIGNES_CAPSULE := ["Une capsule, c'est petit… mais c'est chez moi pour la nuit.", "Chut, mon voisin du dessus ronfle comme un drone.",
	"J'ai raté le dernier monorail. Alors, capsule !", "Il y a un écran, une lampe et un ventilateur. Le luxe."]
const LIGNES_MENAGE := ["CAPSULE 214 : NETTOYÉE. CAPSULE 215 : IL Y A UNE CHAUSSETTE. ANALYSE EN COURS.", "SILENCE APRÈS VINGT-DEUX HEURES. MERCI."]
const ACCUEIL := ["Entrez, entrez ! Vous prendrez bien un thé ?", "Faites comme chez vous. Mais enlevez vos chaussures !",
	"Vous êtes le nouveau voisin ? Bienvenue dans l'immeuble !", "Ne faites pas attention au désordre, le robot ménager est en grève."]
const SALON := ["Chut, c'est la fin de mon feuilleton !", "D'ici, on voit le monorail passer. Je compte les wagons.", "Vous voulez des biscuits aux algues ?"]
const CUISINE := ["Ça mijote ! Vous restez dîner ?", "Le secret, c'est le gingembre. Beaucoup de gingembre."]
const ENFANT := ["Tu veux voir ma collection de robots ?", "Quand je serai grand, je piloterai une voiture volante !", "Chut, je joue à cache-cache avec le robot."]
const ROBOT_MENAGER := ["BIENVENUE. JE PRÉPARE DES CHAUSSONS POUR LES INVITÉS.", "POUSSIÈRE DÉTECTÉE. POUSSIÈRE ÉLIMINÉE."]
const LIGNES_TOIT := ["D'ici, on voit les voitures volantes passer sous nos pieds.", "Le soir, toute la ville s'allume d'un coup. Il faut voir ça.",
	"Je monte ici pour réfléchir. Et pour regarder le ciel.", "Ne te penche pas trop, hein."]
const LIGNES_JARDIN := ["Mes tomates poussent mieux ici qu'à la campagne. C'est le néon.", "Un potager sur le toit, c'est ma fierté.",
	"Les abeilles robots s'occupent des fleurs. Moi, du reste."]
const VUES := ["Dans la longue-vue : le Quai des Drones, et les bateaux qui arrivent.", "Dans la longue-vue : la Tour Axiome, si haute qu'elle touche presque les nuages.",
	"Dans la longue-vue : les trois carpes de lumière de la Place des Hologrammes.", "Dans la longue-vue : la mer, et les îles de l'archipel, au loin.",
	"Dans la longue-vue : un monorail qui file sur son viaduc.", "Dans la longue-vue : quelqu'un, sur un autre toit, vous fait signe !"]
const CAISSES := ["bois_clair", "bois_clair", "conteneur_bleu", "conteneur_vert", "conteneur_rouge", "conteneur_orange"]


# =================================================================== les outils

static func _yaw(f: Vector3) -> float:
	return atan2(f.x, f.z)


## Un meuble : le milieu de sa base, sa taille (x en travers, z dans le sens de « face »), et sa collision.
static func _meuble(T: Node, b: Kit.Batch, key: String, at: Vector3, size: Vector3, face: Vector3, col: bool = true) -> void:
	var yw: float = _yaw(face)
	b.box_at(key, at, size, yw)
	if col:
		T._col(at + Vector3.UP * size.y * 0.5, size, yw)


## Une pièce dans le repère d'un objet (bs : sa base ; p : le milieu de sa base ; l : le centre de la pièce).
static func _piece(b: Kit.Batch, key: String, p: Vector3, bs: Basis, l: Vector3, size: Vector3) -> void:
	b.box(key, Transform3D(bs, p + bs * l), size)


## Libre pour l'étage (T._libre) et loin de ce qu'on a déjà posé (occ : [Vector2, rayon]).
static func _ok(T: Node, occ: Array, p: Vector3, r: float) -> bool:
	if not T._libre(p, r):
		return false
	for o in occ:
		if (o[0] as Vector2).distance_to(Vector2(p.x, p.z)) < float(o[1]) + r:
			return false
	return true


## Pareil, pour un meuble contre la façade (à « d » mètres de son nu intérieur ; o : la normale de la
## façade) : la marge du bord de l'étage ne compte pas, mais l'allée de l'entrée, si.
static func _okf(T: Node, occ: Array, p: Vector3, r: float, o: Vector3, d: float) -> bool:
	var s: float = maxf(0.0, 0.25 + r - d)
	return _ok(T, occ, p - o * s, r)


static func _prend(occ: Array, p: Vector3, r: float) -> void:
	occ.append([Vector2(p.x, p.z), r])


## Une place libre au hasard dans un rectangle (Vector3.INF s'il n'y en a pas).
static func _place(T: Node, occ: Array, rng: RandomNumberGenerator, r: Rect2, rad: float, y: float, essais: int = 16) -> Vector3:
	if r.size.x < 2.0 * rad + 0.2 or r.size.y < 2.0 * rad + 0.2:
		return Vector3.INF
	for k in range(essais):
		var p := Vector3(rng.randf_range(r.position.x + rad, r.end.x - rad), y, rng.randf_range(r.position.y + rad, r.end.y - rad))
		if _ok(T, occ, p, rad):
			return p
	return Vector3.INF


static func _dir(rng: RandomNumberGenerator) -> Vector3:
	var a: float = rng.randf() * TAU
	return Vector3(cos(a), 0.0, sin(a))


## Une bande autour du cœur, vue de sa façade : o (la normale sortante de la façade), f (le nu intérieur
## de la façade), prof (la profondeur jusqu'au couloir du cœur), a0…a1 (le long de la façade), ax (le
## long de x ?).
static func bande(T: Node, r: Rect2) -> Dictionary:
	var R: Rect2 = T.info["rect"]
	var o := Vector3(1, 0, 0)
	var f: float = R.end.x - 0.2
	var inner: float = r.position.x
	if absf(r.position.y - R.position.y) < 0.05 and r.size.x >= R.size.x - 0.1:
		o = Vector3(0, 0, -1)
		f = R.position.y + 0.2
		inner = r.end.y
	elif absf(r.end.y - R.end.y) < 0.05 and r.size.x >= R.size.x - 0.1:
		o = Vector3(0, 0, 1)
		f = R.end.y - 0.2
		inner = r.position.y
	elif absf(r.position.x - R.position.x) < 0.05:
		o = Vector3(-1, 0, 0)
		f = R.position.x + 0.2
		inner = r.end.x
	var ax: bool = absf(o.z) > 0.5
	return {"o": o, "f": f, "prof": absf(inner - f), "ax": ax, "a0": r.position.x if ax else r.position.y,
		"a1": r.end.x if ax else r.end.y, "r": r, "u": Vector3(1, 0, 0) if ax else Vector3(0, 0, 1)}


## Un point d'une bande : « a » le long de la façade, « d » vers l'intérieur depuis la façade.
static func pt(bi: Dictionary, a: float, d: float, y: float) -> Vector3:
	var o: Vector3 = bi["o"]
	if bi["ax"]:
		return Vector3(a, y, float(bi["f"]) - o.z * d)
	return Vector3(float(bi["f"]) - o.x * d, y, a)


## Une taille dans le repère d'une bande (le long, la hauteur, la profondeur).
static func sz(bi: Dictionary, along: float, h: float, prof: float) -> Vector3:
	return Vector3(along, h, prof) if bi["ax"] else Vector3(prof, h, along)


## La plus grande bande (en surface).
static func _grande(T: Node) -> Dictionary:
	var best: Dictionary = {}
	for r in T._bandes():
		var bi: Dictionary = bande(T, r)
		if best.is_empty() or (r as Rect2).get_area() > (best["r"] as Rect2).get_area():
			best = bi
	return best


## Un écran qui vit (son matériau à lui : _process le fait battre).
static func ecran(T: Node, key: String, at: Vector3, size: Vector3, bs: Basis, rng: RandomNumberGenerator) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = (Kit.mat(key) as Material).duplicate()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	T._node.add_child(mi)
	mi.global_transform = Transform3D(bs, at)
	T._ecrans.append([mi, rng.randf() * TAU])
	return mi


static func lumiere(T: Node, at: Vector3, c: Color, e: float, r: float) -> OmniLight3D:
	var o := OmniLight3D.new()
	o.light_color = c
	o.light_energy = e
	o.omni_range = r
	o.omni_attenuation = 1.3
	T._node.add_child(o)
	o.global_position = at
	return o


## Une enseigne sur une face du cœur (sign : -1 la face « gauche », +1 la face « droite » vue de l'ascenseur).
static func enseigne(T: Node, b: Kit.Batch, txt: String, neon: String, cote: float = -1.0, taille: int = 90, haut: float = 1.95) -> Label3D:
	var core: Rect2 = T.info["core"]
	var n: Vector3 = T.info["regard"]
	var side: Vector3 = n.cross(Vector3.UP) * cote
	var y: float = T.info["y"]
	var cc := Vector3(core.get_center().x, y, core.get_center().y)
	var half: float = (absf(side.x) * core.size.x + absf(side.z) * core.size.y) * 0.5
	var at: Vector3 = cc + side * (half + 0.06) + Vector3.UP * haut
	var l: Label3D = T._label(txt, taille, Kit.NEONS.get(neon.substr(5), Color.WHITE))
	l.global_position = at
	l.look_at(at - side, Vector3.UP)
	l.width = maxf(200.0, (absf(n.x) * core.size.x + absf(n.z) * core.size.y + 0.0) / l.pixel_size * 0.9)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.box_at(neon, cc + side * (half + 0.03) + Vector3.UP * (haut - 0.45), Vector3(minf(2.6, (absf(side.z) * core.size.x + absf(side.x) * core.size.y) - 0.4), 0.04, 0.03), _yaw(side))
	return l


static func _gens(T: Node, rng: RandomNumberGenerator, at: Vector3, face: Vector3, pose: String, lignes: Array, roles: Array = ["homme", "femme"], android: bool = false) -> void:
	if at == Vector3.INF:
		return
	T._gens_ajoute(str(roles[rng.randi() % roles.size()]), at, face, pose, rng, lignes, android)


# =================================================================== le Quai : le hangar

static func hangar(T: Node, b: Kit.Batch, rng: RandomNumberGenerator, t: Dictionary) -> String:
	var y: float = T.info["y"]
	var hc: float = float(t["e"]) - 0.35
	var core: Rect2 = T.info["core"]
	var occ: Array = []
	# les lignes jaunes, autour de l'allée du cœur
	var g: Rect2 = core.grow(1.6)
	for e in [[Vector3(g.get_center().x, y + 0.006, g.position.y), Vector3(g.size.x, 0.01, 0.1)], [Vector3(g.get_center().x, y + 0.006, g.end.y), Vector3(g.size.x, 0.01, 0.1)],
			[Vector3(g.position.x, y + 0.006, g.get_center().y), Vector3(0.1, 0.01, g.size.y)], [Vector3(g.end.x, y + 0.006, g.get_center().y), Vector3(0.1, 0.01, g.size.y)]]:
		b.box("peinture_jaune", Transform3D(Basis(), e[0]), e[1])
	var hmax: float = minf(2.7, hc - 0.25)
	var bandes: Array = T._bandes()
	if bandes.is_empty():
		return "drone_vol"
	for r in bandes:
		var bi: Dictionary = bande(T, r)
		var o: Vector3 = bi["o"]
		# les rayonnages, contre la façade
		var a: float = float(bi["a0"]) + 1.6
		while a + 1.3 < float(bi["a1"]) - 0.3:
			var p: Vector3 = pt(bi, a, 0.75, y)
			if _okf(T, occ, p, 0.7, o, 0.75):
				_rayonnage(T, b, p, -o, hmax, rng)
				_prend(occ, p, 1.25)
			a += 2.75
		# au milieu : des piles de caisses sur leurs palettes
		if float(bi["prof"]) > 4.2:
			var a2: float = float(bi["a0"]) + 2.0
			while a2 < float(bi["a1"]) - 1.5:
				var p2: Vector3 = pt(bi, a2 + rng.randf_range(-0.4, 0.4), minf(float(bi["prof"]) * 0.55, 3.6), y)
				if rng.randf() < 0.6 and _ok(T, occ, p2, 0.8):
					_pile(T, b, p2, rng, hmax)
					_prend(occ, p2, 0.85)
				a2 += 3.2
	var gr: Dictionary = _grande(T)
	if gr.is_empty():
		return ""
	# le chariot-robot
	var pc: Vector3 = _place(T, occ, rng, gr["r"], 1.4, y)
	if pc != Vector3.INF:
		_chariot(T, b, pc, (gr["u"] as Vector3) * (1.0 if rng.randf() < 0.5 else -1.0), rng)
		_prend(occ, pc, 1.5)
	# les drones, sur leurs socles de recharge
	var nd: int = 0
	for r2 in bandes:
		var bi2: Dictionary = bande(T, r2)
		if nd >= 4 or float(bi2["prof"]) < 3.4:
			continue
		var a3: float = float(bi2["a0"]) + 1.4
		while a3 < float(bi2["a1"]) - 1.0 and nd < 4:
			var q: Vector3 = pt(bi2, a3, float(bi2["prof"]) - 1.0, y)
			if _ok(T, occ, q, 0.7):
				_drone(T, b, q, rng)
				_prend(occ, q, 0.75)
				nd += 1
			a3 += 1.7
	# les dockers, l'androïde trieur
	for k in range(3):
		var pp: Vector3 = _place(T, occ, rng, (bandes[rng.randi() % bandes.size()] as Rect2), 0.5, y)
		if pp != Vector3.INF:
			_prend(occ, pp, 0.6)
			_gens(T, rng, pp, _dir(rng), ["pointer", "bras_croises", "bricoler"][k], LIGNES_HANGAR)
	var pa: Vector3 = _place(T, occ, rng, gr["r"], 0.5, y)
	if pa != Vector3.INF:
		_prend(occ, pa, 0.6)
		_gens(T, rng, pa, _dir(rng), "debout", LIGNES_TRI, ["homme", "femme"], true)
	return "drone_vol"


static func _rayonnage(T: Node, b: Kit.Batch, p: Vector3, face: Vector3, h: float, rng: RandomNumberGenerator) -> void:
	var bs := Basis(Vector3.UP, _yaw(face))
	for sx in [-1.15, 1.15]:
		for sz2 in [-0.45, 0.45]:
			_piece(b, "metal_noir", p, bs, Vector3(sx, h * 0.5, sz2), Vector3(0.07, h, 0.07))
	var n: int = 3 if h >= 2.6 else 2
	var pas: float = (h - 0.2) / n
	for i in range(n):
		var ly: float = 0.12 + i * pas
		for sz3 in [-0.47, 0.47]:
			_piece(b, "conteneur_orange", p, bs, Vector3(0, ly, sz3), Vector3(2.4, 0.08, 0.06))
		_piece(b, "metal", p, bs, Vector3(0, ly + 0.03, 0), Vector3(2.3, 0.03, 0.95))
		for sx2 in [-0.58, 0.58]:
			if rng.randf() < 0.75:
				var ch: float = minf(pas - 0.18, rng.randf_range(0.5, 0.8))
				_piece(b, CAISSES[rng.randi() % CAISSES.size()], p, bs, Vector3(sx2 + rng.randf_range(-0.05, 0.05), ly + 0.05 + ch * 0.5, 0), Vector3(rng.randf_range(0.85, 1.0), ch, 0.8))
	T._col(p + Vector3.UP * h * 0.5, Vector3(2.4, h, 1.0), _yaw(face))


static func _pile(T: Node, b: Kit.Batch, p: Vector3, rng: RandomNumberGenerator, hmax: float) -> void:
	var yw: float = rng.randf_range(-0.2, 0.2)
	var bs := Basis(Vector3.UP, yw)
	b.box("bois_clair", Transform3D(bs, p + Vector3.UP * 0.07), Vector3(1.2, 0.14, 1.0))
	var hh: float = 0.14
	for k in range(rng.randi_range(1, 3)):
		var ch: float = rng.randf_range(0.5, 0.8)
		if hh + ch > hmax:
			break
		b.box(CAISSES[rng.randi() % CAISSES.size()], Transform3D(bs.rotated(Vector3.UP, rng.randf_range(-0.1, 0.1)), p + Vector3.UP * (hh + ch * 0.5)),
			Vector3(rng.randf_range(0.9, 1.12), ch, rng.randf_range(0.8, 0.95)))
		hh += ch
	T._col(p + Vector3.UP * hh * 0.5, Vector3(1.2, hh, 1.05), yw)


static func _chariot(T: Node, b: Kit.Batch, p: Vector3, face: Vector3, rng: RandomNumberGenerator) -> void:
	var bs := Basis(Vector3.UP, _yaw(face))
	_piece(b, "peinture_jaune", p, bs, Vector3(0, 0.75, -0.25), Vector3(1.0, 1.1, 1.5))
	_piece(b, "metal_noir", p, bs, Vector3(0, 2.1, -0.35), Vector3(1.0, 0.06, 0.9))
	for sx in [-0.46, 0.46]:
		for sz2 in [-0.75, 0.05]:
			_piece(b, "metal_noir", p, bs, Vector3(sx, 1.65, sz2), Vector3(0.06, 0.9, 0.06))
		_piece(b, "metal_noir", p, bs, Vector3(sx * 0.65, 1.2, 0.58), Vector3(0.08, 2.3, 0.08))
		_piece(b, "metal_noir", p, bs, Vector3(sx * 0.55, 0.12, 1.15), Vector3(0.12, 0.05, 1.1))
		for sz3 in [-0.7, 0.3]:
			_piece(b, "plastique_noir", p, bs, Vector3(sx * 1.1, 0.25, sz3), Vector3(0.18, 0.5, 0.5))
	_piece(b, "in_led_ambre", p, bs, Vector3(0, 1.05, 0.505), Vector3(0.36, 0.07, 0.02))
	_piece(b, "in_led_ambre", p, bs, Vector3(0, 2.16, -0.35), Vector3(0.12, 0.08, 0.12))
	if rng.randf() < 0.7:
		_piece(b, CAISSES[rng.randi() % CAISSES.size()], p, bs, Vector3(0, 0.58, 1.15), Vector3(1.0, 0.8, 0.9))
	T._col(p + bs * Vector3(0, 1.05, 0.2), Vector3(1.2, 2.1, 2.5), _yaw(face))


static func _drone(T: Node, b: Kit.Batch, q: Vector3, rng: RandomNumberGenerator) -> void:
	b.cyl_at("metal_noir", q, 0.62, 0.62, 0.06, 18)
	b.cyl_at("in_led_verte", q + Vector3.UP * 0.06, 0.6, 0.6, 0.005, 18)
	b.cyl_at("metal_noir", q + Vector3.UP * 0.062, 0.54, 0.54, 0.006, 18)
	var c: Vector3 = q + Vector3.UP * 0.2
	var yw: float = rng.randf() * TAU
	b.box("in_noir", Transform3D(Basis(Vector3.UP, yw), c), Vector3(0.36, 0.1, 0.36))
	for k in range(4):
		var a: float = yw + PI * 0.25 + k * PI * 0.5
		var tip: Vector3 = c + Vector3(cos(a), 0.02, sin(a)) * 0.38
		b.tube("in_noir", c, tip, 0.02, 5)
		b.cyl_at("plastique_noir", tip + Vector3.UP * 0.03, 0.17, 0.17, 0.012, 12)
	b.box("in_led_bleue", Transform3D(Basis(Vector3.UP, yw), c + Vector3.UP * 0.055), Vector3(0.08, 0.01, 0.08))
	T._col(q + Vector3.UP * 0.15, Vector3(1.2, 0.3, 1.2))


# =================================================================== les Ruelles : les échoppes

static func atelier(T: Node, b: Kit.Batch, rng: RandomNumberGenerator, t: Dictionary) -> String:
	var y: float = T.info["y"]
	var occ: Array = []
	enseigne(T, b, str(t.get("enseigne", "")).to_upper(), "neon_cyan")
	var bandes: Array = T._bandes()
	if bandes.is_empty():
		return "soudure"
	for r in bandes:
		var bi: Dictionary = bande(T, r)
		var o: Vector3 = bi["o"]
		# les établis, contre la façade
		var a: float = float(bi["a0"]) + 1.3
		while a + 0.9 < float(bi["a1"]) - 0.3:
			var p: Vector3 = pt(bi, a, 0.6, y)
			if _okf(T, occ, p, 0.5, o, 0.6):
				_etabli(T, b, p, -o, rng)
				_prend(occ, p, 1.0)
				if rng.randf() < 0.35:
					var pm: Vector3 = p - o * 0.8
					_prend(occ, pm, 0.5)
					_gens(T, rng, pm, o, "bricoler", LIGNES_MECANO)
			a += 2.2
	var gr: Dictionary = _grande(T)
	if gr.is_empty():
		return "soudure"
	# le grand robot sur son socle, que l'on répare
	var pr: Vector3 = _place(T, occ, rng, gr["r"], 1.2, y)
	if pr != Vector3.INF:
		var f: Vector3 = -(gr["o"] as Vector3)
		_robot(T, b, pr, f)
		_prend(occ, pr, 1.2)
		var pm2: Vector3 = pr + f * 1.1 + f.cross(Vector3.UP) * 0.6
		_gens(T, rng, pm2, -f, "bricoler", LIGNES_MECANO)
		_prend(occ, pm2, 0.5)
		lumiere(T, pr + Vector3.UP * 1.6 + f * 0.6, Color(1.0, 0.6, 0.25), 0.9, 4.0)
	# des étagères de pièces détachées
	for k in range(4):
		var ps: Vector3 = _place(T, occ, rng, (bandes[rng.randi() % bandes.size()] as Rect2), 0.8, y)
		if ps != Vector3.INF:
			_etagere(T, b, ps, [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)][rng.randi() % 4], rng, ["plastique_rouge", "plastique_bleu", "metal", "in_inox", "plastique_noir"])
			_prend(occ, ps, 0.9)
	# un client : un robot venu se faire réparer
	var pc: Vector3 = _place(T, occ, rng, gr["r"], 0.5, y)
	if pc != Vector3.INF:
		_gens(T, rng, pc, _dir(rng), "debout", LIGNES_CLIENT_ROBOT, ["homme", "femme"], true)
	return "soudure"


static func _etabli(T: Node, b: Kit.Batch, p: Vector3, face: Vector3, rng: RandomNumberGenerator) -> void:
	var bs := Basis(Vector3.UP, _yaw(face))
	_piece(b, "in_bois", p, bs, Vector3(0, 0.88, 0), Vector3(1.8, 0.06, 0.8))
	for sx in [-0.82, 0.82]:
		_piece(b, "in_inox", p, bs, Vector3(sx, 0.43, 0), Vector3(0.06, 0.86, 0.7))
	_piece(b, "in_menuiserie", p, bs, Vector3(0, 0.2, 0), Vector3(1.64, 0.04, 0.66))
	# ce qu'il y a dessus : une tête de robot, un bras, des outils, la lampe
	if rng.randf() < 0.7:
		var tp: Vector3 = p + bs * Vector3(rng.randf_range(-0.5, 0.2), 1.08, 0.0)
		b.blob("in_inox", tp, Vector3(0.17, 0.15, 0.16), 8)
		for sx2 in [-0.06, 0.06]:
			b.blob("in_led_bleue" if rng.randf() < 0.6 else "in_led_ambre", tp + bs * Vector3(sx2, 0.02, 0.15), Vector3(0.03, 0.03, 0.02), 6)
	if rng.randf() < 0.6:
		var a0: Vector3 = p + bs * Vector3(0.3, 0.95, -0.1)
		b.tube("in_inox", a0, a0 + bs * Vector3(0.45, 0.02, 0.2), 0.045, 6)
		b.blob("in_noir", a0 + bs * Vector3(0.47, 0.02, 0.2), Vector3(0.07, 0.06, 0.07), 6)
	for k in range(3):
		_piece(b, ["in_noir", "plastique_rouge", "in_inox"][k], p, bs, Vector3(rng.randf_range(-0.8, 0.8), 0.93, rng.randf_range(-0.3, 0.3)), Vector3(rng.randf_range(0.08, 0.25), 0.04, 0.05))
	_piece(b, "in_noir", p, bs, Vector3(-0.75, 1.2, -0.3), Vector3(0.03, 0.6, 0.03))
	b.blob("in_led_ambre", p + bs * Vector3(-0.75, 1.5, -0.15), Vector3(0.07, 0.04, 0.07), 6)
	T._col(p + Vector3.UP * 0.46, Vector3(1.8, 0.92, 0.8), _yaw(face))


static func _robot(T: Node, b: Kit.Batch, p: Vector3, face: Vector3) -> void:
	var bs := Basis(Vector3.UP, _yaw(face))
	_piece(b, "metal_noir", p, bs, Vector3(0, 0.1, 0), Vector3(1.3, 0.2, 1.3))
	for sx in [-0.22, 0.22]:
		b.tube("in_inox", p + bs * Vector3(sx, 0.2, 0), p + bs * Vector3(sx, 1.05, 0.02), 0.09, 8)
		_piece(b, "in_noir", p, bs, Vector3(sx, 0.28, 0.08), Vector3(0.24, 0.12, 0.38))
	_piece(b, "in_inox", p, bs, Vector3(0, 1.45, 0), Vector3(0.75, 0.85, 0.48))
	_piece(b, "in_noir", p, bs, Vector3(0, 1.5, 0.245), Vector3(0.42, 0.42, 0.02))
	_piece(b, "in_led_ambre", p, bs, Vector3(0.05, 1.42, 0.25), Vector3(0.12, 0.08, 0.01))
	b.tube("in_inox", p + bs * Vector3(-0.42, 1.75, 0), p + bs * Vector3(-0.5, 1.1, 0.15), 0.07, 6)
	b.tube("in_inox", p + bs * Vector3(0.42, 1.75, 0), p + bs * Vector3(0.75, 1.55, 0.35), 0.07, 6)
	b.blob("in_inox", p + bs * Vector3(0, 2.1, 0), Vector3(0.24, 0.2, 0.22), 10)
	_piece(b, "in_led_bleue", p, bs, Vector3(0, 2.12, 0.2), Vector3(0.24, 0.05, 0.03))
	# le portique d'entretien, au-dessus
	for sx3 in [-0.65, 0.65]:
		_piece(b, "metal_noir", p, bs, Vector3(sx3, 1.2, -0.55), Vector3(0.08, 2.4, 0.08))
	_piece(b, "metal_noir", p, bs, Vector3(0, 2.4, -0.55), Vector3(1.4, 0.08, 0.08))
	T._col(p + Vector3.UP * 1.1, Vector3(1.4, 2.2, 1.3), _yaw(face))


static func _etagere(T: Node, b: Kit.Batch, p: Vector3, face: Vector3, rng: RandomNumberGenerator, cles: Array) -> void:
	var bs := Basis(Vector3.UP, _yaw(face))
	var h: float = 1.9
	for sx in [-0.78, 0.78]:
		_piece(b, "in_menuiserie", p, bs, Vector3(sx, h * 0.5, 0), Vector3(0.04, h, 0.45))
	for i in range(4):
		var ly: float = 0.1 + i * 0.58
		_piece(b, "in_menuiserie", p, bs, Vector3(0, ly, 0), Vector3(1.6, 0.03, 0.45))
		if i < 3:
			var x: float = -0.65
			while x < 0.6:
				var w: float = rng.randf_range(0.12, 0.3)
				var hh: float = rng.randf_range(0.1, 0.35)
				_piece(b, str(cles[rng.randi() % cles.size()]), p, bs, Vector3(x + w * 0.5, ly + 0.015 + hh * 0.5, rng.randf_range(-0.08, 0.08)), Vector3(w, hh, 0.25))
				x += w + rng.randf_range(0.04, 0.12)
	T._col(p + Vector3.UP * h * 0.5, Vector3(1.6, h, 0.45), _yaw(face))


static func nouilles(T: Node, b: Kit.Batch, rng: RandomNumberGenerator, t: Dictionary) -> String:
	var y: float = T.info["y"]
	var hc: float = float(t["e"]) - 0.35
	var occ: Array = []
	enseigne(T, b, str(t.get("enseigne", "")).to_upper(), "neon_rouge")
	var menu := enseigne(T, b, "MENU\nRamen au bouillon de porc — 8\nUdon néon — 7\nSoba froides — 6\nGyoza (six) — 4\nThé au jasmin — 2", "neon_ambre", 1.0, 34, 1.7)
	menu.modulate = Color(1.0, 0.92, 0.75)
	var gr: Dictionary = _grande(T)
	var nc: int = 0
	if not gr.is_empty() and float(gr["prof"]) >= 3.6:
		var o: Vector3 = gr["o"]
		var dc: float = float(gr["prof"]) - 1.9
		var am: float = (float(gr["a0"]) + float(gr["a1"])) * 0.5
		var la: float = minf(float(gr["a1"]) - float(gr["a0"]) - 2.0, 9.0)
		if la >= 2.4:
			# le comptoir : les clients côté façade, la cuisine côté cœur
			_meuble(T, b, "in_bois", pt(gr, am, dc, y), Vector3(la, 1.0, 0.6), o)
			b.box_at("in_marbre_noir", pt(gr, am, dc, y) + Vector3.UP * 1.0, Vector3(la + 0.1, 0.05, 0.75), _yaw(o))
			b.box_at("neon_rouge", pt(gr, am, dc - 0.31, y) + Vector3.UP * 0.85, Vector3(la, 0.04, 0.02), _yaw(o))
			_prend(occ, pt(gr, am, dc, y), 0.1)
			var ns: int = int(la / 0.8)
			for k in range(ns):
				var ua: float = am - la * 0.5 + 0.4 + k * (la - 0.8) / maxf(1.0, ns - 1)
				var sp: Vector3 = pt(gr, ua, dc - 0.75, y)
				b.cyl_at("in_inox", sp, 0.04, 0.04, 0.68, 6)
				b.cyl_at("in_tissu_rouge", sp + Vector3.UP * 0.66, 0.2, 0.2, 0.07, 12)
				b.cyl_at("in_inox", sp, 0.2, 0.2, 0.02, 10)
				if rng.randf() < 0.4 and nc < 4:
					nc += 1
					_gens(T, rng, sp, -o, "manger", LIGNES_CLIENT_NOUILLES, ["homme", "femme", "vieux", "vieille", "garcon", "fille"])
				if rng.randf() < 0.5:
					b.cyl_at("peinture_blanche", pt(gr, ua, dc - 0.1, y) + Vector3.UP * 1.03, 0.09, 0.12, 0.08, 10)
			# la cuisine : le fourneau, les marmites, le cuisinier
			var fp: Vector3 = pt(gr, am - la * 0.2, dc + 1.15, y)
			_meuble(T, b, "in_noir", fp, Vector3(minf(2.4, la - 0.4), 0.9, 0.6), -o)
			for k2 in range(3):
				var mp: Vector3 = pt(gr, am - la * 0.2 + (k2 - 1) * 0.7, dc + 1.15, y) + Vector3.UP * 0.9
				b.cyl_at("neon_ambre", mp, 0.18, 0.18, 0.01, 12)
				b.cyl_at("in_inox", mp + Vector3.UP * 0.01, 0.2, 0.22, 0.3 if k2 != 1 else 0.12, 12)
			_gens(T, rng, pt(gr, am - la * 0.2, dc + 0.55, y), o, "cuisiner", LIGNES_CUISINIER)
			# les lanternes au-dessus du comptoir
			var nl: int = int(la / 1.6)
			for k3 in range(nl):
				var lp: Vector3 = pt(gr, am - la * 0.5 + 0.8 + k3 * 1.6, dc, y) + Vector3.UP * (hc - 0.55)
				b.tube("in_noir", lp + Vector3.UP * 0.3, lp + Vector3.UP * 0.55, 0.01, 4)
				b.blob("neon_rouge", lp, Vector3(0.2, 0.26, 0.2), 10)
			lumiere(T, pt(gr, am, dc, y) + Vector3.UP * (hc - 0.6), Color(1.0, 0.55, 0.3), 1.2, 6.0)
	# des petites tables rouges dans les autres bandes
	for r in T._bandes():
		for k4 in range(3):
			var tp: Vector3 = _place(T, occ, rng, r, 1.0, y)
			if tp == Vector3.INF:
				continue
			Kit.table(b, tp)
			T._col(tp + Vector3.UP * 0.4, Vector3(0.95, 0.8, 0.95))
			_prend(occ, tp, 1.05)
			if rng.randf() < 0.5 and nc < 7:
				nc += 1
				var s: Vector3 = tp + Vector3(cos(0.4), 0, sin(0.4)) * 0.75
				_gens(T, rng, s, (tp - s).normalized(), "manger", LIGNES_CLIENT_NOUILLES, ["homme", "femme", "vieux", "vieille"])
	return "friture_wok"


static func boutique(T: Node, b: Kit.Batch, rng: RandomNumberGenerator, t: Dictionary) -> String:
	var y: float = T.info["y"]
	var occ: Array = []
	enseigne(T, b, str(t.get("enseigne", "")).to_upper(), "neon_violet")
	var gadgets: Array = ["in_ecran", "in_ecran_vert", "in_ecran_rose", "in_noir", "plastique_rouge", "plastique_bleu", "in_led_bleue", "in_inox"]
	for r in T._bandes():
		var bi: Dictionary = bande(T, r)
		var o: Vector3 = bi["o"]
		var a: float = float(bi["a0"]) + 1.0
		while a + 0.8 < float(bi["a1"]) - 0.2:
			var p: Vector3 = pt(bi, a, 0.4, y)
			if _okf(T, occ, p, 0.4, o, 0.4):
				_etagere(T, b, p, -o, rng, gadgets)
				_prend(occ, p, 0.85)
			a += 1.75
		# des tables de démonstration, et leurs gadgets
		for k in range(2):
			var tp: Vector3 = _place(T, occ, rng, r, 1.0, y)
			if tp == Vector3.INF:
				continue
			_meuble(T, b, "in_bureau", tp, Vector3(1.6, 0.85, 0.8), bi["u"])
			for k2 in range(4):
				var gp: Vector3 = tp + Vector3(rng.randf_range(-0.3, 0.3), 0.85, rng.randf_range(-0.3, 0.3)) + (bi["u"] as Vector3).cross(Vector3.UP) * rng.randf_range(-0.5, 0.5)
				b.box(str(gadgets[rng.randi() % gadgets.size()]), Transform3D(Basis(Vector3.UP, rng.randf() * TAU), gp + Vector3.UP * 0.05), Vector3(rng.randf_range(0.12, 0.3), 0.1, rng.randf_range(0.1, 0.2)))
			# un hologramme qui tourne au-dessus de la table
			b.cyl_at("in_neon_accueil", tp + Vector3.UP * 0.85, 0.14, 0.14, 0.03, 12)
			ecran(T, "in_ecran_rose", tp + Vector3.UP * 1.25, Vector3(0.22, 0.22, 0.22), Basis(Vector3(1, 1, 0).normalized(), 0.8), rng)
			_prend(occ, tp, 1.1)
	# le comptoir et le vendeur
	var gr: Dictionary = _grande(T)
	if not gr.is_empty():
		var o2: Vector3 = gr["o"]
		var am: float = (float(gr["a0"]) + float(gr["a1"])) * 0.5
		var cp: Vector3 = pt(gr, am, float(gr["prof"]) - 1.3, y)
		if T._libre(cp, 0.4):
			_meuble(T, b, "in_bois", cp, Vector3(2.2, 1.0, 0.6), o2)
			b.box_at("in_marbre_noir", cp + Vector3.UP * 1.0, Vector3(2.3, 0.05, 0.7), _yaw(o2))
			b.box_at("in_ecran", cp + o2 * 0.31 + Vector3.UP * 0.45, Vector3(2.0, 0.3, 0.02), _yaw(o2))
			_gens(T, rng, cp - o2 * 0.75, o2, "comptoir", LIGNES_VENDEUR, ["homme", "femme"], rng.randf() < 0.3)
			_prend(occ, cp, 1.2)
	var bandes2: Array = T._bandes()
	for k3 in range(3 if not bandes2.is_empty() else 0):
		var pp: Vector3 = _place(T, occ, rng, (bandes2[rng.randi() % bandes2.size()] as Rect2), 0.5, y)
		if pp != Vector3.INF:
			_prend(occ, pp, 0.6)
			_gens(T, rng, pp, _dir(rng), ["holo", "debout", "pointer"][k3], LIGNES_CLIENT_BOUTIQUE, ["homme", "femme", "garcon", "fille", "vieux"])
	return "bip"


# =================================================================== les Arcades

static func salle_jeux(T: Node, b: Kit.Batch, rng: RandomNumberGenerator, t: Dictionary) -> String:
	var y: float = T.info["y"]
	var hc: float = float(t["e"]) - 0.35
	var occ: Array = []
	var l := enseigne(T, b, str(t["nom"]).to_upper(), "neon_rose")
	l.modulate = Kit.NEONS["rose"]
	var neons: Array = ["neon_cyan", "neon_rose", "neon_violet", "neon_vert", "neon_ambre"]
	var anim: int = 0
	var nj: int = 0
	for r in T._bandes():
		var bi: Dictionary = bande(T, r)
		var o: Vector3 = bi["o"]
		var a: float = float(bi["a0"]) + 0.9
		while a + 0.5 < float(bi["a1"]) - 0.2:
			var p: Vector3 = pt(bi, a, 0.45, y)
			if _okf(T, occ, p, 0.42, o, 0.45):
				_borne(T, b, p, -o, rng, str(neons[rng.randi() % neons.size()]), anim < 14)
				anim += 1
				_prend(occ, p, 0.48)
				if rng.randf() < 0.25 and nj < 6:
					nj += 1
					_gens(T, rng, p - o * 0.85, o, "debout", LIGNES_JOUEUR, ["garcon", "fille", "homme", "femme"])
					_prend(occ, p - o * 0.85, 0.4)
			a += 0.95
		# au milieu : des pinces à peluches
		if float(bi["prof"]) >= 4.5:
			for k in range(2):
				var pp: Vector3 = _place(T, occ, rng, r, 0.8, y)
				if pp != Vector3.INF:
					_pince(T, b, pp, -o, rng, str(neons[rng.randi() % neons.size()]))
					_prend(occ, pp, 0.9)
	# la machine à danser, et sa danseuse
	var gr: Dictionary = _grande(T)
	if not gr.is_empty():
		var dp: Vector3 = _place(T, occ, rng, gr["r"], 1.3, y)
		if dp != Vector3.INF:
			var f: Vector3 = -(gr["o"] as Vector3)
			var bs := Basis(Vector3.UP, _yaw(f))
			_piece(b, "in_noir", dp, bs, Vector3(0, 0.05, 0), Vector3(1.8, 0.1, 1.8))
			for k2 in range(4):
				var ap: Vector3 = Vector3([0.0, 0.0, -0.55, 0.55][k2], 0.105, [-0.55, 0.55, 0.0, 0.0][k2])
				_piece(b, ["neon_rose", "neon_cyan", "neon_vert", "neon_ambre"][k2], dp, bs, ap, Vector3(0.45, 0.01, 0.45))
			_piece(b, "in_noir", dp, bs, Vector3(0, 1.1, -1.0), Vector3(1.6, 2.2, 0.4))
			ecran(T, "in_ecran_rose", dp + bs * Vector3(0, 1.45, -0.79), Vector3(1.3, 0.8, 0.02), bs, rng)
			T._col(dp + bs * Vector3(0, 1.1, -1.0), Vector3(1.6, 2.2, 0.4), _yaw(f))
			_gens(T, rng, dp + Vector3.UP * 0.1, -f, "danse", ["Regarde mes pieds ! … Non, ne regarde pas mes pieds.", "Niveau expert ! Je vais transpirer des néons."], ["fille", "femme", "garcon"])
			_prend(occ, dp, 1.4)
		# le changeur de jetons
		var vp: Vector3 = _place(T, occ, rng, gr["r"], 0.7, y)
		if vp != Vector3.INF:
			Kit.vending(b, vp, -(gr["o"] as Vector3), "plastique_bleu")
			T._col(vp + Vector3.UP * 0.95, Vector3(1.05, 1.9, 0.8), _yaw(-(gr["o"] as Vector3)))
	var rect: Rect2 = T.info["rect"]
	for k3 in range(3):
		lumiere(T, Vector3(rect.position.x + rect.size.x * (0.2 + 0.3 * k3), y + hc - 0.5, rect.position.y + rect.size.y * (0.75 - 0.25 * k3)),
			[Color(0.7, 0.3, 1.0), Color(1.0, 0.3, 0.75), Color(0.2, 0.8, 1.0)][k3], 1.1, 9.0)
	return "arcade"


static func _borne(T: Node, b: Kit.Batch, p: Vector3, face: Vector3, rng: RandomNumberGenerator, neon: String, anime: bool) -> void:
	var bs := Basis(Vector3.UP, _yaw(face))
	_piece(b, "in_noir", p, bs, Vector3(0, 0.9, -0.05), Vector3(0.8, 1.8, 0.7))
	_piece(b, neon, p, bs, Vector3(0, 1.72, 0.31), Vector3(0.78, 0.18, 0.04))
	for sx in [-0.41, 0.41]:
		_piece(b, neon, p, bs, Vector3(sx, 0.9, 0.0), Vector3(0.015, 1.7, 0.6))
	var ek: String = ["in_ecran", "in_ecran_vert", "in_ecran_rose"][rng.randi() % 3]
	var ec: Vector3 = p + bs * Vector3(0, 1.32, 0.31)
	var tilt := bs * Basis(Vector3.RIGHT, -0.22)
	if anime:
		ecran(T, ek, ec, Vector3(0.6, 0.46, 0.02), tilt, rng)
	else:
		b.box(ek, Transform3D(tilt, ec), Vector3(0.6, 0.46, 0.02))
	_piece(b, "in_noir", p, bs, Vector3(0, 0.98, 0.45), Vector3(0.78, 0.07, 0.32))
	b.cyl_at("in_inox", p + bs * Vector3(-0.18, 1.02, 0.47), 0.012, 0.012, 0.09, 5)
	b.blob("plastique_rouge", p + bs * Vector3(-0.18, 1.12, 0.47), Vector3(0.035, 0.035, 0.035), 6)
	for k in range(3):
		b.blob(["plastique_rouge", "plastique_bleu", "peinture_jaune"][k], p + bs * Vector3(0.05 + k * 0.09, 1.025, 0.48 - (k % 2) * 0.04), Vector3(0.028, 0.012, 0.028), 6)
	T._col(p + Vector3.UP * 0.9, Vector3(0.8, 1.8, 0.95), _yaw(face))


static func _pince(T: Node, b: Kit.Batch, p: Vector3, face: Vector3, rng: RandomNumberGenerator, neon: String) -> void:
	var bs := Basis(Vector3.UP, _yaw(face))
	_piece(b, "in_noir", p, bs, Vector3(0, 0.45, 0), Vector3(1.0, 0.9, 1.0))
	_piece(b, "in_vitre", p, bs, Vector3(0, 1.45, 0), Vector3(0.96, 1.1, 0.96))
	_piece(b, neon, p, bs, Vector3(0, 2.05, 0), Vector3(1.0, 0.12, 1.0))
	for k in range(9):
		b.blob(["tissu_rouge", "tissu_jaune", "tissu_bleu", "tissu_vert"][rng.randi() % 4], p + bs * Vector3(rng.randf_range(-0.35, 0.35), 1.0 + rng.randf_range(0.0, 0.15), rng.randf_range(-0.35, 0.35)),
			Vector3(0.12, 0.11, 0.12), 6)
	var cp: Vector3 = p + bs * Vector3(rng.randf_range(-0.2, 0.2), 1.8, rng.randf_range(-0.2, 0.2))
	b.tube("in_inox", cp + Vector3.UP * 0.18, cp, 0.01, 4)
	for k2 in range(3):
		var a: float = TAU * k2 / 3.0
		b.tube("in_inox", cp, cp + Vector3(cos(a) * 0.08, -0.12, sin(a) * 0.08), 0.012, 4)
	T._col(p + Vector3.UP * 1.05, Vector3(1.0, 2.1, 1.0), _yaw(face))


## Les bandes où l'on bâtit des pièces (les cabines de karaoké, devant leur couloir) : jamais devant
## l'ascenseur ni l'escalier. Rend [bande, a0, a1].
static func _troncons(T: Node, prof_min: float) -> Array:
	var core: Rect2 = T.info["core"]
	var n: Vector3 = T.info["regard"]
	var out: Array = []
	for r in T._bandes():
		var bi: Dictionary = bande(T, r)
		if float(bi["prof"]) < prof_min:
			continue
		var a0: float = float(bi["a0"])
		var a1: float = float(bi["a1"])
		var parts: Array = [[a0, a1]]
		if absf((bi["o"] as Vector3).dot(n)) > 0.5:
			var cm: float = core.get_center().x if bi["ax"] else core.get_center().y
			parts = [[a0, cm - 1.7], [cm + 1.7, a1]]
		for pr in parts:
			if float(pr[1]) - float(pr[0]) >= 3.0:
				out.append([bi, float(pr[0]), float(pr[1])])
	return out


static func karaoke(T: Node, b: Kit.Batch, rng: RandomNumberGenerator, t: Dictionary) -> String:
	var y: float = T.info["y"]
	var hc: float = float(t["e"]) - 0.35
	var cabines: int = 0
	var couleurs: Array = [[Color(1.0, 0.3, 0.75), "in_tissu_rouge"], [Color(0.6, 0.3, 1.0), "in_tissu_gris"], [Color(0.2, 0.8, 1.0), "in_cuir"]]
	for tr in _troncons(T, 4.0):
		var bi: Dictionary = tr[0]
		var a0: float = tr[1]
		var a1: float = tr[2]
		var prof: float = float(bi["prof"]) - 1.4
		var o: Vector3 = bi["o"]
		var u: Vector3 = bi["u"]
		var nb: int = maxi(1, int((a1 - a0) / 3.6))
		var wb: float = (a1 - a0) / nb
		# les cloisons
		for k in range(nb + 1):
			var ap: float = a0 + k * wb
			T._boite(b, "in_mur", pt(bi, ap, prof * 0.5, y) + Vector3.UP * hc * 0.5, sz(bi, 0.12, hc, prof), true)
		for k2 in range(nb):
			var c0: float = a0 + k2 * wb
			var am: float = c0 + wb * 0.5
			# la façade de la cabine, côté couloir : du verre, une porte
			for sg in [[c0 + 0.06, am - 0.5], [am + 0.5, c0 + wb - 0.06]]:
				var l0: float = sg[0]
				var l1: float = sg[1]
				if l1 - l0 < 0.1:
					continue
				var gp: Vector3 = pt(bi, (l0 + l1) * 0.5, prof - 0.05, y)
				b.box("in_cloison_verre", Transform3D(Basis(), gp + Vector3.UP * hc * 0.5), sz(bi, l1 - l0, hc, 0.04))
				T._col(gp + Vector3.UP * hc * 0.5, sz(bi, l1 - l0, hc, 0.1))
			b.box("in_menuiserie", Transform3D(Basis(), pt(bi, am, prof - 0.05, y) + Vector3.UP * 2.25), sz(bi, wb, 0.08, 0.08))
			for sx in [-0.5, 0.5]:
				b.box("in_menuiserie", Transform3D(Basis(), pt(bi, am + sx, prof - 0.05, y) + Vector3.UP * 1.12), sz(bi, 0.06, 2.25, 0.08))
			var lab: Label3D = T._label("%d" % (cabines + 1), 40, Kit.NEONS["cyan"])
			lab.global_position = pt(bi, am, prof + 0.01, y) + Vector3.UP * 2.45
			lab.look_at(lab.global_position + o, Vector3.UP)
			cabines += 1
			var col: Array = couleurs[(cabines + rng.randi()) % couleurs.size()]
			# la banquette contre la fenêtre, la table, le micro
			var lb: float = wb - 0.5
			_meuble(T, b, str(col[1]), pt(bi, am, 0.5, y), Vector3(lb, 0.42, 0.7), -o)
			b.box_at(str(col[1]), pt(bi, am, 0.2, y) + Vector3.UP * 0.42, Vector3(lb, 0.45, 0.14), _yaw(-o))
			if prof >= 3.4:
				_meuble(T, b, "in_marbre_noir", pt(bi, am, 1.5, y), Vector3(minf(1.6, wb - 1.4), 0.42, 0.6), -o)
				b.cyl_at("in_noir", pt(bi, am + 0.3, 1.5, y) + Vector3.UP * 0.42, 0.025, 0.03, 0.22, 6)
				b.blob("in_inox", pt(bi, am + 0.3, 1.5, y) + Vector3.UP * 0.66, Vector3(0.04, 0.04, 0.04), 6)
			# l'écran, sur la cloison, et les paroles
			var ep: Vector3 = pt(bi, c0 + 0.08, prof * 0.5, y) + Vector3.UP * 1.45
			ecran(T, "in_ecran_rose" if cabines % 2 == 0 else "in_ecran", ep, sz(bi, 0.03, 0.8, minf(1.4, prof - 0.8)), Basis(), rng)
			var pl: Label3D = T._label(str(PAROLES[rng.randi() % PAROLES.size()]), 26, Color(1, 1, 1))
			pl.global_position = ep + u * 0.03 + Vector3.DOWN * 0.25
			pl.look_at(pl.global_position - u, Vector3.UP)
			lumiere(T, pt(bi, am, prof * 0.5, y) + Vector3.UP * (hc - 0.4), col[0], 1.2, 3.8)
			# les chanteurs
			if rng.randf() < 0.65:
				_gens(T, rng, pt(bi, am + 0.2, prof * 0.62, y), -u, "chanter", LIGNES_KARAOKE, ["homme", "femme", "fille", "garcon", "vieux"])
				if rng.randf() < 0.7:
					_gens(T, rng, pt(bi, am - lb * 0.25, 0.55, y), -o, "rire_assis", LIGNES_KARAOKE, ["homme", "femme", "vieille"])
	# le couloir : un néon au plafond, le long du cœur
	var cg: Rect2 = (T.info["core"] as Rect2).grow(0.75)
	for e in [[Vector3(cg.get_center().x, y + hc - 0.03, cg.position.y), Vector3(cg.size.x, 0.03, 0.06)], [Vector3(cg.get_center().x, y + hc - 0.03, cg.end.y), Vector3(cg.size.x, 0.03, 0.06)]]:
		b.box("neon_violet", Transform3D(Basis(), e[0]), e[1])
	return "karaoke"


static func capsules(T: Node, b: Kit.Batch, rng: RandomNumberGenerator, t: Dictionary) -> String:
	var y: float = T.info["y"]
	var hc: float = float(t["e"]) - 0.35
	var deux: bool = hc >= 2.55
	var hcap: float = 1.12
	var occ: Array = []
	var n_cap: int = 0
	var rideaux: Array = ["tissu_bleu", "tissu_rouge", "tissu_vert", "tissu_jaune"]
	for r in T._bandes():
		var bi: Dictionary = bande(T, r)
		var o: Vector3 = bi["o"]
		var rangs: Array = [[1.05, -o]]
		if float(bi["prof"]) >= 6.2:
			rangs.append([4.6, o])
		for rg in rangs:
			var a: float = float(bi["a0"]) + 0.65
			while a + 0.6 < float(bi["a1"]) - 0.1:
				var p: Vector3 = pt(bi, a, float(rg[0]), y)
				var face: Vector3 = rg[1]
				if _okf(T, occ, p, 0.6, o, float(rg[0])):
					_capsule(T, b, p, face, deux, hcap, rng, str(rideaux[rng.randi() % rideaux.size()]), n_cap)
					n_cap += 1
				a += 1.25
	# les casiers, sur une face du cœur
	var core: Rect2 = T.info["core"]
	var n: Vector3 = T.info["regard"]
	var side: Vector3 = n.cross(Vector3.UP)
	var cc := Vector3(core.get_center().x, y, core.get_center().y)
	for sgn in [-1.0]:
		var fs: Vector3 = side * sgn
		var half: float = (absf(fs.x) * core.size.x + absf(fs.z) * core.size.y) * 0.5
		var lg: float = (absf(fs.z) * core.size.x + absf(fs.x) * core.size.y) - 0.6
		var nk: int = int(lg / 0.5)
		for k in range(nk):
			var lp: Vector3 = cc + fs * (half + 0.2) + fs.cross(Vector3.UP) * (-lg * 0.5 + 0.25 + k * 0.5)
			b.box_at("in_inox", lp, Vector3(0.46, 1.9, 0.38), _yaw(fs))
			b.box_at("in_noir", lp + fs * 0.191 + Vector3.UP * 0.95, Vector3(0.44, 0.01, 0.005), _yaw(fs))
			b.box_at("in_led_verte" if rng.randf() < 0.7 else "in_led_ambre", lp + fs * 0.192 + Vector3.UP * 1.3, Vector3(0.04, 0.03, 0.005), _yaw(fs))
		T._col(cc + fs * (half + 0.2) + Vector3.UP * 0.95, Vector3(lg, 1.9, 0.38) if absf(fs.z) > 0.5 else Vector3(0.38, 1.9, lg))
	# des clients en pyjama, un androïde de ménage
	var bandes: Array = T._bandes()
	if not bandes.is_empty():
		for k2 in range(3):
			var pp: Vector3 = _place(T, occ, rng, (bandes[rng.randi() % bandes.size()] as Rect2), 0.45, y)
			if pp != Vector3.INF:
				_prend(occ, pp, 0.5)
				_gens(T, rng, pp, _dir(rng), ["debout", "bras_croises", "lire"][k2] if k2 < 2 else "debout", LIGNES_CAPSULE, ["homme", "femme", "vieux", "garcon"])
		var pa: Vector3 = _place(T, occ, rng, (bandes[rng.randi() % bandes.size()] as Rect2), 0.45, y)
		_gens(T, rng, pa, _dir(rng), "debout", LIGNES_MENAGE, ["homme", "femme"], true)
	return ""


static func _capsule(T: Node, b: Kit.Batch, p: Vector3, face: Vector3, deux: bool, h: float, rng: RandomNumberGenerator, rideau: String, num: int) -> void:
	var bs := Basis(Vector3.UP, _yaw(face))
	var niveaux: Array = [0.06, 0.06 + h + 0.06] if deux else [0.06]
	for i in range(niveaux.size()):
		var by: float = niveaux[i]
		_piece(b, "in_bureau", p, bs, Vector3(0, by + h * 0.5, 0), Vector3(1.2, h, 2.1))
		_piece(b, "in_noir", p, bs, Vector3(0, by + h * 0.5, 1.051), Vector3(0.88, 0.82, 0.01))
		var allume: bool = rng.randf() < 0.55
		_piece(b, "in_plafonnier_chaud" if allume else "in_menuiserie", p, bs, Vector3(0, by + h * 0.5 + 0.36, 1.056), Vector3(0.78, 0.03, 0.01))
		if rng.randf() < 0.5:
			_piece(b, rideau, p, bs, Vector3(-0.22 if rng.randf() < 0.5 else 0.22, by + h * 0.5, 1.06), Vector3(0.44, 0.8, 0.012))
		if i == 1:
			# l'échelle
			for sx in [0.46, 0.58]:
				_piece(b, "in_inox", p, bs, Vector3(sx, by * 0.5 + 0.05, 1.13), Vector3(0.025, by + 0.1, 0.025))
			for k in range(3):
				_piece(b, "in_inox", p, bs, Vector3(0.52, 0.3 + k * 0.3, 1.13), Vector3(0.14, 0.02, 0.02))
		if num % 4 == 0:
			var lab: Label3D = T._label("%d" % (100 + num * (niveaux.size()) + i), 22, Color(0.9, 0.9, 0.95))
			lab.global_position = p + bs * Vector3(-0.5, by + h - 0.12, 1.07)
			lab.look_at(lab.global_position - bs * Vector3(0, 0, 1), Vector3.UP)
	var ht: float = float(niveaux[niveaux.size() - 1]) + h
	T._col(p + Vector3.UP * ht * 0.5, Vector3(1.2, ht, 2.1), _yaw(face))


# =================================================================== les appartements

## Un appartement derrière une porte ouverte. A : O (le coin, au mur du couloir, au sol), U (le long du
## couloir), D (vers la façade), W (la largeur), P (la profondeur), porte (la porte, le long de U), hc.
static func appartement(T: Node, b: Kit.Batch, rng: RandomNumberGenerator, A: Dictionary) -> void:
	var O: Vector3 = A["O"]
	var U: Vector3 = A["U"]
	var D: Vector3 = A["D"]
	var W: float = A["W"]
	var P: float = A["P"]
	var hc: float = A["hc"]
	var porte: float = A["porte"]
	# la porte au plus près du côté droit : la cuisine et la télé contre le mur de gauche
	if porte < W * 0.5:
		O = O + U * W
		U = -U
		porte = W - porte
	var lp := func(ua: float, dd: float) -> Vector3:
		return O + U * ua + D * dd
	var tz := func(lu: float, h: float, ld: float) -> Vector3:
		return Vector3(absf(U.x) * lu + absf(D.x) * ld, h, absf(U.z) * lu + absf(D.z) * ld)
	# le parquet, les murs mitoyens
	b.box("in_parquet", Transform3D(Basis(), lp.call(W * 0.5, P * 0.5) + Vector3.UP * 0.012), tz.call(W, 0.02, P))
	for ua in [0.06, W - 0.06]:
		T._boite(b, "in_mur_couloir", lp.call(ua, P * 0.5) + Vector3.UP * hc * 0.5, tz.call(0.12, hc, P), true)
	# la cloison entre l'entrée (la cuisine) et le séjour
	var dp1: float = -1.0
	if P >= 6.0:
		dp1 = clampf(P * 0.42, 2.6, 4.2)
		for sg in [[0.0, porte - 0.5], [porte + 0.5, W]]:
			var s0: float = sg[0]
			var s1: float = sg[1]
			if s1 - s0 > 0.1:
				T._boite(b, "in_mur_couloir", lp.call((s0 + s1) * 0.5, dp1) + Vector3.UP * hc * 0.5, tz.call(s1 - s0, hc, 0.1), true)
		b.box("in_mur_couloir", Transform3D(Basis(), lp.call(porte, dp1) + Vector3.UP * (2.2 + (hc - 2.2) * 0.5)), tz.call(1.0, hc - 2.2, 0.1))
	var sej0: float = (dp1 + 0.15) if dp1 > 0.0 else 2.4
	var sej1: float = P - 0.3
	# la cuisine : le frigo, le plan de travail, la plaque, l'évier
	var kz1: float = (dp1 - 0.2) if dp1 > 0.0 else 2.2
	_meuble(T, b, "in_inox", lp.call(0.45, 0.5), Vector3(0.7, 1.85, 0.65), U)
	var lk: float = kz1 - 0.95
	var kc: float = 0.95 + lk * 0.5
	if lk >= 1.0:
		_meuble(T, b, "in_bois_clair", lp.call(0.42, kc), Vector3(lk, 0.88, 0.6), U)
		b.box("in_marbre_noir", Transform3D(Basis(), lp.call(0.42, kc) + Vector3.UP * 0.9), tz.call(0.64, 0.04, lk))
		b.box("in_noir", Transform3D(Basis(), lp.call(0.42, kc - lk * 0.25) + Vector3.UP * 0.925), tz.call(0.5, 0.01, 0.55))
		b.cyl_at("in_inox", lp.call(0.42, kc - lk * 0.25 - 0.1) + Vector3.UP * 0.93, 0.13, 0.15, 0.14, 10)
		b.box("in_inox", Transform3D(Basis(), lp.call(0.42, kc + lk * 0.25) + Vector3.UP * 0.915), tz.call(0.45, 0.02, 0.4))
		b.box("in_bois_clair", Transform3D(Basis(), lp.call(0.25, kc) + Vector3.UP * 1.75), tz.call(0.35, 0.6, lk))
	# la petite table de la cuisine
	if W >= 5.0:
		var tp: Vector3 = lp.call(W - 0.75, (dp1 - 0.9) if dp1 > 0.0 else 1.7)
		b.cyl_at("in_bois", tp + Vector3.UP * 0.72, 0.42, 0.42, 0.04, 14)
		b.cyl_at("in_inox", tp, 0.04, 0.04, 0.72, 6)
		T._col(tp + Vector3.UP * 0.38, Vector3(0.84, 0.76, 0.84))
		for sgn in [-1.0, 1.0]:
			T._chaise(b, tp + D * 0.65 * sgn, -D * sgn)
	# le séjour : le tapis, le canapé contre le mur de droite, la télé en face, la table basse
	var lit: bool = sej1 - sej0 >= 5.0
	var vie1: float = (sej1 - 2.4) if lit else sej1
	var mid: float = (sej0 + vie1) * 0.5
	var ls: float = minf(2.0, vie1 - sej0 - 0.3)
	b.box(["in_tissu_rouge", "in_tissu_gris"][rng.randi() % 2], Transform3D(Basis(), lp.call(W * 0.55, mid) + Vector3.UP * 0.024), tz.call(minf(2.4, W - 1.4), 0.01, minf(2.2, vie1 - sej0 - 0.3)))
	if ls >= 1.2:
		var tissu: String = ["in_tissu_gris", "in_cuir", "in_tissu_rouge"][rng.randi() % 3]
		_meuble(T, b, tissu, lp.call(W - 0.52, mid), Vector3(ls, 0.42, 0.8), -U)
		b.box_at(tissu, lp.call(W - 0.2, mid) + Vector3.UP * 0.42, Vector3(ls, 0.45, 0.14), atan2(-U.x, -U.z))
		for sgn2 in [-1.0, 1.0]:
			b.box_at(tissu, lp.call(W - 0.52, mid + sgn2 * (ls * 0.5 - 0.08)) + Vector3.UP * 0.42, Vector3(0.16, 0.22, 0.8), atan2(-U.x, -U.z))
	# la télé (elle vit), son meuble
	_meuble(T, b, "in_bois", lp.call(0.3, mid), Vector3(clampf(ls, 0.6, 1.6), 0.45, 0.4), U)
	ecran(T, "in_ecran", lp.call(0.14, mid) + Vector3.UP * 1.2, tz.call(0.03, 0.68, 1.15), Basis(), rng)
	if W >= 3.8:
		_meuble(T, b, "in_bois_clair", lp.call(W - 1.5, mid), Vector3(1.0, 0.38, 0.5), -U)
		b.cyl_at("in_ecran_vert" if rng.randf() < 0.3 else "in_bureau", lp.call(W - 1.5, mid + 0.2) + Vector3.UP * 0.38, 0.05, 0.04, 0.1, 8)
	# une lampe sur pied, une plante, des livres
	var lpp: Vector3 = lp.call(0.35, vie1 - 0.25)
	b.cyl_at("in_inox", lpp, 0.02, 0.02, 1.5, 6)
	b.cyl_at("in_inox", lpp, 0.15, 0.15, 0.02, 10)
	b.blob("lampe_chaude", lpp + Vector3.UP * 1.55, Vector3(0.18, 0.14, 0.18), 8)
	if mid - clampf(ls, 0.6, 1.6) * 0.5 > sej0 + 0.95:
		T._plante(b, lp.call(0.45, sej0 + 0.45), 1.1)
	# le lit, contre la façade, si le séjour est profond
	if lit:
		var bp: Vector3 = lp.call(0.85, sej1 - 1.05)
		_meuble(T, b, "in_bois", bp, Vector3(2.0, 0.35, 1.5), U)
		b.box("in_bureau", Transform3D(Basis(), bp + Vector3.UP * 0.44), tz.call(1.4, 0.18, 1.92))
		b.box(["in_tissu_rouge", "in_tissu_gris", "tissu_bleu"][rng.randi() % 3], Transform3D(Basis(), bp - D * 0.3 + Vector3.UP * 0.55), tz.call(1.44, 0.05, 1.3))
		b.box("in_bureau", Transform3D(Basis(), bp + D * 0.75 + Vector3.UP * 0.58), tz.call(1.2, 0.12, 0.35))
		_meuble(T, b, "in_bois_clair", lp.call(1.85, sej1 - 0.3), Vector3(0.4, 0.5, 0.4), -D)
		b.blob("lampe_chaude", lp.call(1.85, sej1 - 0.3) + Vector3.UP * 0.62, Vector3(0.1, 0.12, 0.1), 8)
	lumiere(T, lp.call(W * 0.5, P * 0.5) + Vector3.UP * (hc - 0.45), Color(1.0, 0.82, 0.62), 0.9, maxf(W, P) * 0.85)
	# les habitants
	var hote: Vector3 = lp.call(clampf(porte + 0.75, 0.6, W - 0.6), 0.75)
	_gens(T, rng, hote, -D, "debout", ACCUEIL, ["homme", "femme", "vieux", "vieille"])
	if ls >= 1.2 and rng.randf() < 0.65:
		_gens(T, rng, lp.call(W - 0.55, mid + 0.4), -U, "lire" if rng.randf() < 0.4 else "assis", SALON, ["homme", "femme", "vieux", "vieille"])
	if lk >= 1.0 and rng.randf() < 0.45:
		_gens(T, rng, lp.call(1.1, kc), -U, "cuisiner", CUISINE, ["homme", "femme", "vieille"])
	if rng.randf() < 0.4:
		_gens(T, rng, lp.call(W * 0.45, mid - 0.7), -U, "rire", ENFANT, ["garcon", "fille"])
	elif rng.randf() < 0.3:
		_gens(T, rng, lp.call(W * 0.45, sej0 + 0.6), D, "debout", ROBOT_MENAGER, ["homme", "femme"], true)


# =================================================================== les toits

static func toit(T: Node, b: Kit.Batch, rng: RandomNumberGenerator, t: Dictionary) -> String:
	var R: Rect2 = T.info["rect"]
	var y: float = T.info["y"]
	var occ: Array = []
	var c := Vector3(R.get_center().x, y, R.get_center().y)
	var bureaux: bool = str(t["type"]) == "bureaux"
	var interieur := R.grow(-1.1)
	if bureaux and minf(R.size.x, R.size.y) >= 16.0 and _ok(T, occ, c, 5.6):
		# l'hélistation
		b.cyl_at("beton", c, 5.0, 5.0, 0.06, 32)
		b.cyl_at("peinture_jaune", c + Vector3.UP * 0.06, 4.6, 4.6, 0.006, 32)
		b.cyl_at("beton", c + Vector3.UP * 0.064, 4.35, 4.35, 0.006, 32)
		for e in [[Vector3(-0.9, 0, 0), Vector3(0.45, 0.01, 3.0)], [Vector3(0.9, 0, 0), Vector3(0.45, 0.01, 3.0)], [Vector3(0, 0, 0), Vector3(1.8, 0.01, 0.45)]]:
			b.box("peinture_blanche", Transform3D(Basis(), c + (e[0] as Vector3) + Vector3.UP * 0.072), e[1])
		for k in range(10):
			var a: float = TAU * k / 10.0
			b.blob("neon_vert", c + Vector3(cos(a) * 4.85, 0.1, sin(a) * 4.85), Vector3(0.08, 0.06, 0.08), 6)
		_prend(occ, c, 5.3)
	if bureaux:
		# des panneaux solaires, en rangées
		var np: int = 0
		var x: float = interieur.position.x + 1.3
		while x < interieur.end.x - 1.2 and np < 16:
			var z: float = interieur.position.y + 1.0
			while z < interieur.end.y - 0.9 and np < 16:
				var p := Vector3(x, y, z)
				if _ok(T, occ, p, 1.25):
					b.box("metal", Transform3D(Basis(), p + Vector3.UP * 0.3), Vector3(2.0, 0.6, 0.08))
					b.box("verre_fume", Transform3D(Basis(Vector3.RIGHT, -0.45), p + Vector3.UP * 0.62), Vector3(2.2, 0.04, 1.4))
					T._col(p + Vector3.UP * 0.5, Vector3(2.2, 1.0, 1.3))
					_prend(occ, p, 1.2)
					np += 1
				z += 2.6
			x += 2.8
		var pa: Vector3 = _place(T, occ, rng, interieur, 0.5, y)
		_gens(T, rng, pa, _dir(rng), "observer", LIGNES_TOIT, ["homme", "femme"], rng.randf() < 0.4)
		_prend(occ, pa, 0.6)
	else:
		# le jardin suspendu : des bacs le long du parapet, la table, les guirlandes, le linge
		for e2 in [[Vector3(1, 0, 0), interieur.position.y + 0.1, true], [Vector3(1, 0, 0), interieur.end.y - 0.1, true], [Vector3(0, 0, 1), interieur.position.x + 0.1, false], [Vector3(0, 0, 1), interieur.end.x - 0.1, false]]:
			var u: Vector3 = e2[0]
			var fixe: float = e2[1]
			var deb: float = interieur.position.x if e2[2] else interieur.position.y
			var fin: float = interieur.end.x if e2[2] else interieur.end.y
			var s: float = deb + 1.3
			while s < fin - 1.2:
				var p2 := Vector3(s, y, fixe) if e2[2] else Vector3(fixe, y, s)
				if rng.randf() < 0.7 and _ok(T, occ, p2, 0.6):
					_bac(T, b, p2, u, rng)
					_prend(occ, p2, 1.1)
				s += 2.6
		var tp: Vector3 = _place(T, occ, rng, interieur, 1.1, y)
		if tp != Vector3.INF:
			Kit.table(b, tp)
			T._col(tp + Vector3.UP * 0.4, Vector3(0.95, 0.8, 0.95))
			_prend(occ, tp, 1.1)
			if rng.randf() < 0.6:
				var s2: Vector3 = tp + Vector3(cos(0.4), 0, sin(0.4)) * 0.75
				_gens(T, rng, s2, (tp - s2).normalized(), "assis", LIGNES_TOIT, ["homme", "femme", "vieux", "vieille"])
		var gp: Vector3 = _place(T, occ, rng, interieur, 0.5, y)
		_gens(T, rng, gp, _dir(rng), "jardiner", LIGNES_JARDIN, ["vieux", "vieille", "homme", "femme"])
		_prend(occ, gp, 0.6)
		# les guirlandes : des poteaux aux coins, des ampoules entre eux
		var coins: Array = [Vector3(interieur.position.x + 0.3, y, interieur.position.y + 0.3), Vector3(interieur.end.x - 0.3, y, interieur.position.y + 0.3),
			Vector3(interieur.end.x - 0.3, y, interieur.end.y - 0.3), Vector3(interieur.position.x + 0.3, y, interieur.end.y - 0.3)]
		for k2 in range(4):
			var a2: Vector3 = coins[k2]
			var b2: Vector3 = coins[(k2 + 1) % 4]
			b.cyl_at("metal_noir", a2, 0.05, 0.05, 2.7, 6)
			var nb: int = int(a2.distance_to(b2) / 1.2)
			for i in range(1, nb):
				var f: float = float(i) / nb
				var q: Vector3 = a2.lerp(b2, f) + Vector3.UP * (2.6 - 0.5 * sin(f * PI))
				b.blob("lampe_chaude", q, Vector3(0.045, 0.055, 0.045), 6)
		# le linge qui sèche
		var lp2: Vector3 = _place(T, occ, rng, interieur, 1.6, y)
		if lp2 != Vector3.INF:
			var lu: Vector3 = Vector3(1, 0, 0) if rng.randf() < 0.5 else Vector3(0, 0, 1)
			for sg in [-1.4, 1.4]:
				b.cyl_at("metal_noir", lp2 + lu * sg, 0.03, 0.03, 1.9, 6)
			b.tube("in_noir", lp2 - lu * 1.4 + Vector3.UP * 1.85, lp2 + lu * 1.4 + Vector3.UP * 1.85, 0.008, 4)
			for k3 in range(5):
				var cp: Vector3 = lp2 + lu * (-1.1 + k3 * 0.55) + Vector3.UP * 1.55
				b.box(["tissu_rouge", "tissu_bleu", "peinture_blanche", "tissu_jaune", "tissu_vert"][rng.randi() % 5], Transform3D(Basis(Vector3.UP, atan2(lu.x, lu.z) + PI * 0.5), cp),
					Vector3(0.45, 0.6, 0.01))
			T._col(lp2 + Vector3.UP * 0.95, Vector3(0.1, 1.9, 0.1))
			_prend(occ, lp2, 1.6)
	# la longue-vue, au bord, du côté le plus long
	var lv := Vector3(c.x, y, R.position.y + 1.05) if R.size.x >= R.size.y else Vector3(R.position.x + 1.05, y, c.z)
	var dehors := Vector3(0, 0, -1) if R.size.x >= R.size.y else Vector3(-1, 0, 0)
	if not _ok(T, occ, lv, 0.4):
		lv = Vector3(c.x, y, R.end.y - 1.05) if R.size.x >= R.size.y else Vector3(R.end.x - 1.05, y, c.z)
		dehors = -dehors
	b.cyl_at("metal_noir", lv, 0.05, 0.05, 1.2, 8)
	b.cyl_at("metal_noir", lv, 0.25, 0.25, 0.04, 10)
	b.tube("in_inox", lv + Vector3.UP * 1.25 - dehors * 0.25, lv + Vector3.UP * 1.35 + dehors * 0.3, 0.07, 10)
	T._col(lv + Vector3.UP * 0.65, Vector3(0.3, 1.3, 0.3))
	var main: Node = T.main
	T._its_add({"id": "longue_vue155", "pos": lv - dehors * 0.6, "radius": 1.2, "text": "E : regarder dans la longue-vue", "vr": "Gâchette : regarder",
		"call": func(): main._show_message_v28(str(VUES[randi() % VUES.size()]))})
	return "deltaplane_vent"


static func _bac(T: Node, b: Kit.Batch, p: Vector3, u: Vector3, rng: RandomNumberGenerator) -> void:
	var yw: float = atan2(u.x, u.z) + PI * 0.5
	b.box_at("in_bois", p, Vector3(2.0, 0.55, 0.75), yw)
	b.box_at("in_terre", p + Vector3.UP * 0.55, Vector3(1.9, 0.02, 0.65), yw)
	var side: Vector3 = Basis(Vector3.UP, yw) * Vector3(1, 0, 0)
	for k in range(5):
		var q: Vector3 = p + side * (-0.75 + k * 0.38) + Vector3.UP * 0.58
		var hh: float = rng.randf_range(0.25, 0.6)
		b.blob("in_feuille", q + Vector3.UP * hh * 0.5, Vector3(0.16, hh * 0.5, 0.16), 6)
		if rng.randf() < 0.4:
			b.blob(["plastique_rouge", "peinture_jaune", "tissu_rouge"][rng.randi() % 3], q + Vector3(0.05, hh * 0.6, 0.04), Vector3(0.05, 0.05, 0.05), 5)
	T._col(p + Vector3.UP * 0.3, Vector3(2.0, 0.6, 0.75), yw)


# =================================================================== V156 : les étages à part

const LIGNES_LABO := ["Ne touche pas à la cuve verte. Elle ne t'a rien fait.", "Expérience 412 : la plante parle. Enfin, elle chante faux.",
	"Le microscope dit que tout va bien. Le microscope ment parfois.", "On cherche un remède contre le hoquet des robots."]
const LIGNES_LABO_ANDROIDE := ["ÉCHANTILLON 7 : STABLE. ÉCHANTILLON 8 : IL M'A FAIT UN CLIN D'ŒIL.", "PORTEZ VOS LUNETTES DE PROTECTION. MERCI."]
const LIGNES_STUDIO := ["Silence, on tourne ! … Coupez ! Encore une fois.", "Trois, deux, un… à l'antenne !", "Le présentateur a encore oublié son texte. Vive le prompteur.",
	"Souriez, vous êtes en direct dans tout Néopolis !"]
const LIGNES_SPORT := ["Encore dix ! … Bon, encore cinq.", "Le tapis de course, c'est comme le monorail : on avance sans bouger.", "Je m'entraîne pour le marathon des toits.",
	"Pense à boire de l'eau. Et à respirer."]
const LIGNES_JARDIN_INT := ["Ici, on vient respirer entre deux réunions.", "Les cerisiers fleurissent toute l'année. C'est un réglage du chauffage.",
	"Écoute la fontaine… on oublierait presque les bureaux.", "Je médite. Enfin, j'essaie. Mon téléphone, lui, ne médite pas."]
const LIGNES_PISCINE := ["L'eau est parfaite ! Viens !", "Une longueur, deux longueurs… je compte les étoiles par la verrière.", "Pas de plongeon, c'est le règlement. Et le règlement, c'est moi.",
	"Nager au-dessus de la ville… c'est le luxe des Résidences."]


static func labo(T: Node, b: Kit.Batch, rng: RandomNumberGenerator, t: Dictionary) -> String:
	var y: float = T.info["y"]
	var hc: float = float(t["e"]) - 0.35
	var occ: Array = []
	enseigne(T, b, "LABORATOIRE — " + str(t.get("societe", "")).to_upper(), "neon_vert", -1.0, 60)
	var bandes: Array = T._bandes()
	if bandes.is_empty():
		return ""
	var ng: int = 0
	for r in bandes:
		var bi: Dictionary = bande(T, r)
		var o: Vector3 = bi["o"]
		# les sorbonnes (des hottes vitrées), contre la façade
		var a: float = float(bi["a0"]) + 1.3
		while a + 1.0 < float(bi["a1"]) - 0.3:
			var p: Vector3 = pt(bi, a, 0.5, y)
			if _okf(T, occ, p, 0.6, o, 0.5) and rng.randf() < 0.6:
				var bs := Basis(Vector3.UP, _yaw(-o))
				_piece(b, "in_bureau", p, bs, Vector3(0, 0.45, 0), Vector3(1.5, 0.9, 0.75))
				_piece(b, "in_inox", p, bs, Vector3(0, 0.92, 0), Vector3(1.55, 0.04, 0.8))
				_piece(b, "in_vitre", p, bs, Vector3(0, 1.55, 0.3), Vector3(1.45, 1.2, 0.02))
				_piece(b, "in_bureau", p, bs, Vector3(0, 2.25, -0.05), Vector3(1.55, 0.3, 0.75))
				_piece(b, "in_led_verte", p, bs, Vector3(0, 2.08, 0.0), Vector3(1.3, 0.02, 0.4))
				for k in range(3):
					b.cyl_at(["in_ecran_vert", "in_ecran_rose", "in_ecran"][k], p + bs * Vector3(-0.4 + k * 0.4, 0.94, 0.0), 0.04, 0.04, 0.22, 8)
				T._col(p + Vector3.UP * 1.2, Vector3(1.55, 2.4, 0.8), _yaw(-o))
				_prend(occ, p, 1.0)
			a += 1.9
		# les paillasses, au milieu
		var a2: float = float(bi["a0"]) + 2.0
		while a2 < float(bi["a1"]) - 1.6 and float(bi["prof"]) >= 4.4:
			var p2: Vector3 = pt(bi, a2, float(bi["prof"]) * 0.55, y)
			if _ok(T, occ, p2, 1.1):
				_paillasse(T, b, p2, bi["u"], rng)
				_prend(occ, p2, 1.25)
				if rng.randf() < 0.45 and ng < 6:
					ng += 1
					_gens(T, rng, p2 - (bi["u"] as Vector3).cross(Vector3.UP) * 0.85, (bi["u"] as Vector3).cross(Vector3.UP), "bricoler", LIGNES_LABO)
			a2 += 3.2
	# la grande cuve, qui luit
	var gr: Dictionary = _grande(T)
	var cp: Vector3 = _place(T, occ, rng, gr["r"], 1.1, y)
	if cp != Vector3.INF:
		b.cyl_at("in_inox", cp, 0.85, 0.85, 0.3, 24)
		b.cyl_at("in_inox", cp + Vector3.UP * (hc - 0.3), 0.85, 0.85, 0.3, 24)
		b.cyl_at("in_vitre", cp + Vector3.UP * 0.3, 0.8, 0.8, hc - 0.6, 24)
		var cuve := ecran(T, "in_ecran_vert", cp + Vector3.UP * (hc * 0.5), Vector3(1.2, hc - 0.7, 1.2), Basis(), rng)
		var cm := CylinderMesh.new()
		cm.top_radius = 0.72
		cm.bottom_radius = 0.72
		cm.height = hc - 0.7
		cuve.mesh = cm
		(cuve.material_override as StandardMaterial3D).transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		(cuve.material_override as StandardMaterial3D).albedo_color.a = 0.45
		b.blob("in_feuille", cp + Vector3.UP * (hc * 0.5), Vector3(0.25, 0.4, 0.25), 8)
		T._col(cp + Vector3.UP * hc * 0.5, Vector3(1.7, hc, 1.7))
		lumiere(T, cp + Vector3.UP * 1.2, Color(0.4, 1.0, 0.55), 1.4, 5.0)
		_prend(occ, cp, 1.2)
	var pa: Vector3 = _place(T, occ, rng, gr["r"], 0.5, y)
	_gens(T, rng, pa, _dir(rng), "debout", LIGNES_LABO_ANDROIDE, ["homme", "femme"], true)
	return "bip"


static func _paillasse(T: Node, b: Kit.Batch, p: Vector3, u: Vector3, rng: RandomNumberGenerator) -> void:
	var bs := Basis(Vector3.UP, atan2(u.x, u.z) + PI * 0.5)
	_piece(b, "in_bureau", p, bs, Vector3(0, 0.45, 0), Vector3(2.4, 0.9, 1.2))
	_piece(b, "in_marbre_noir", p, bs, Vector3(0, 0.92, 0), Vector3(2.5, 0.04, 1.3))
	_piece(b, "in_inox", p, bs, Vector3(0, 1.45, 0), Vector3(2.2, 0.03, 0.35))
	for sx in [-1.05, 1.05]:
		_piece(b, "in_inox", p, bs, Vector3(sx, 1.2, 0), Vector3(0.04, 0.55, 0.04))
	# le microscope, les tubes, la centrifugeuse
	var mp: Vector3 = p + bs * Vector3(-0.7, 0.94, 0.25)
	_piece(b, "in_noir", mp, Basis(), Vector3(0, 0.03, 0), Vector3(0.22, 0.06, 0.26))
	b.tube("in_noir", mp + Vector3.UP * 0.05, mp + Vector3.UP * 0.32 + bs * Vector3(0, 0, -0.06), 0.035, 6)
	b.tube("in_bureau", mp + Vector3.UP * 0.28, mp + Vector3.UP * 0.42 + bs * Vector3(0, 0, 0.08), 0.025, 6)
	for k in range(6):
		b.cyl_at(["in_ecran_vert", "in_ecran_rose", "in_ecran", "in_vitre"][rng.randi() % 4], p + bs * Vector3(0.1 + k * 0.08, 0.94, -0.3), 0.018, 0.018, 0.14, 6)
	b.cyl_at("in_inox", p + bs * Vector3(0.75, 0.94, 0.2), 0.16, 0.16, 0.22, 14)
	b.cyl_at("in_led_bleue", p + bs * Vector3(0.75, 1.16, 0.2), 0.1, 0.1, 0.01, 12)
	T._col(p + Vector3.UP * 0.47, Vector3(2.5, 0.94, 1.3), atan2(u.x, u.z) + PI * 0.5)


static func studio(T: Node, b: Kit.Batch, rng: RandomNumberGenerator, t: Dictionary) -> String:
	var y: float = T.info["y"]
	var hc: float = float(t["e"]) - 0.35
	var occ: Array = []
	var gr: Dictionary = _grande(T)
	if gr.is_empty():
		return ""
	var o: Vector3 = gr["o"]
	var u: Vector3 = gr["u"]
	var am: float = (float(gr["a0"]) + float(gr["a1"])) * 0.5
	var la: float = minf(float(gr["a1"]) - float(gr["a0"]) - 2.0, 10.0)
	var prof: float = gr["prof"]
	if la >= 4.0 and prof >= 4.5:
		# le plateau : l'estrade, le grand écran du fond (contre la façade), le bureau du présentateur
		var pe: Vector3 = pt(gr, am, 1.6, y)
		_meuble(T, b, "in_bois", pe, Vector3(la, 0.25, 2.8), -o)
		b.box_at("neon_cyan", pt(gr, am, 3.0, y) + Vector3.UP * 0.12, Vector3(la, 0.03, 0.03), _yaw(-o))
		var fond: Vector3 = pt(gr, am, 0.3, y) + Vector3.UP * (hc * 0.5 + 0.1)
		b.box("in_noir", Transform3D(Basis(), fond), sz(gr, la, hc - 0.2, 0.15))
		ecran(T, "in_ecran", fond - o * 0.09, sz(gr, la - 0.6, hc - 0.9, 0.02), Basis(), rng)
		var titre: Label3D = T._label("NÉO-INFO — EN DIRECT", 80, Color(1, 1, 1))
		titre.global_position = fond - o * 0.11 + Vector3.UP * (hc * 0.3)
		titre.look_at(titre.global_position + o, Vector3.UP)
		var bp: Vector3 = pt(gr, am, 1.9, y) + Vector3.UP * 0.25
		_meuble(T, b, "in_marbre_noir", bp, Vector3(2.6, 0.95, 0.7), -o)
		b.box_at("neon_rose", bp - o * 0.36 + Vector3.UP * 0.2, Vector3(2.6, 0.04, 0.02), _yaw(-o))
		_gens(T, rng, bp + o * 0.7 + u * 0.5, -o, "pointer", LIGNES_STUDIO, ["homme", "femme"])
		_gens(T, rng, bp + o * 0.7 - u * 0.6, -o, "comptoir", LIGNES_STUDIO, ["femme", "homme"])
		_prend(occ, pt(gr, am, 1.6, y), 0.1)
		# les caméras, les projecteurs (de vraies lumières, braquées sur le bureau)
		for k in range(3):
			var cp: Vector3 = pt(gr, am + (k - 1) * la * 0.3, 4.2, y)
			if not T._libre(cp, 0.4):
				continue
			for a in range(3):
				var an: float = TAU * a / 3.0
				b.tube("in_noir", cp + Vector3.UP * 1.3, cp + Vector3(cos(an) * 0.4, 0, sin(an) * 0.4), 0.02, 4)
			var cb := Basis(Vector3.UP, _yaw(o))
			_piece(b, "in_noir", cp, cb, Vector3(0, 1.45, 0), Vector3(0.3, 0.32, 0.55))
			b.tube("in_noir", cp + cb * Vector3(0, 1.45, 0.25), cp + cb * Vector3(0, 1.45, 0.45), 0.08, 10)
			b.blob("in_led_ambre", cp + cb * Vector3(0.1, 1.64, -0.2), Vector3(0.03, 0.03, 0.03), 6)
			T._col(cp + Vector3.UP * 0.8, Vector3(0.8, 1.6, 0.8))
			if k != 1:
				_gens(T, rng, cp - o * 0.5, o, "observer", LIGNES_STUDIO)
			_prend(occ, cp, 0.6)
		for s in [-1.0, 1.0]:
			var sp: Vector3 = pt(gr, am + s * (la * 0.5 - 0.3), 3.4, y)
			b.cyl_at("in_noir", sp, 0.03, 0.03, 2.3, 6)
			b.cyl_at("in_noir", sp, 0.3, 0.3, 0.03, 10)
			var tete: Vector3 = sp + Vector3.UP * 2.35
			var cible: Vector3 = bp + Vector3.UP * 1.0
			b.box("in_noir", Transform3D(Basis.looking_at(cible - tete, Vector3.UP), tete), Vector3(0.35, 0.3, 0.45))
			var sl := SpotLight3D.new()
			sl.light_color = Color(1.0, 0.95, 0.85)
			sl.light_energy = 3.0
			sl.spot_range = 9.0
			sl.spot_angle = 24.0
			T._node.add_child(sl)
			sl.global_transform = Transform3D(Basis.looking_at(cible - tete, Vector3.UP), tete)
			T._col(sp + Vector3.UP * 1.1, Vector3(0.4, 2.2, 0.4))
		# « En direct » : la lampe rouge au-dessus de la porte du plateau
		var ed: Label3D = enseigne(T, b, "● EN DIRECT", "neon_rouge", -1.0, 70, 2.1)
		ed.modulate = Kit.NEONS["rouge"]
	# la régie : des pupitres, des écrans
	for r in T._bandes():
		var bi: Dictionary = bande(T, r)
		if bi["r"] == gr["r"]:
			continue
		for k2 in range(2):
			var rp: Vector3 = _place(T, occ, rng, r, 1.0, y)
			if rp == Vector3.INF:
				continue
			var f: Vector3 = -(bi["o"] as Vector3)
			_meuble(T, b, "in_noir", rp, Vector3(1.8, 0.85, 0.8), f)
			for k3 in range(3):
				var bs := Basis(Vector3.UP, _yaw(f))
				ecran(T, ["in_ecran", "in_ecran_vert", "in_ecran_rose"][k3], rp + bs * Vector3(-0.6 + k3 * 0.6, 1.15, 0.25), Vector3(0.5, 0.3, 0.02), bs * Basis(Vector3.RIGHT, -0.15), rng)
			_gens(T, rng, rp - f * 0.75, f, "assis", LIGNES_STUDIO)
			_prend(occ, rp, 1.1)
	return "bip"


static func sport(T: Node, b: Kit.Batch, rng: RandomNumberGenerator, t: Dictionary) -> String:
	var y: float = T.info["y"]
	var hc: float = float(t["e"]) - 0.35
	var occ: Array = []
	enseigne(T, b, "SALLE DE SPORT", "neon_vert", -1.0, 80)
	var n_tapis: int = 0
	var n_gens: int = 0
	for r in T._bandes():
		var bi: Dictionary = bande(T, r)
		var o: Vector3 = bi["o"]
		# les tapis de course et les vélos, face aux fenêtres
		var a: float = float(bi["a0"]) + 1.0
		while a + 0.6 < float(bi["a1"]) - 0.2:
			var p: Vector3 = pt(bi, a, 1.3, y)
			if _okf(T, occ, p, 0.55, o, 1.3):
				var velo: bool = rng.randf() < 0.35
				if velo:
					_velo(T, b, p, o)
				else:
					_tapis(T, b, p, o, rng)
					n_tapis += 1
				_prend(occ, p, 0.7)
				if rng.randf() < 0.35 and n_gens < 5:
					n_gens += 1
					_gens(T, rng, p + Vector3.UP * (0.18 if not velo else 0.0), o, "marcher" if not velo else "assis", LIGNES_SPORT, ["homme", "femme", "garcon", "fille"])
			a += 1.1
		# le miroir, sur la façade intérieure du cœur ? non : un grand miroir sur une cloison
		if float(bi["prof"]) >= 4.5:
			var tp: Vector3 = _place(T, occ, rng, r, 1.1, y)
			if tp != Vector3.INF:
				# des tapis de sol, quelqu'un fait des pompes
				b.box_at(["tissu_bleu", "tissu_rouge", "tissu_vert"][rng.randi() % 3], tp + Vector3.UP * 0.01, Vector3(0.7, 0.02, 1.9), _yaw(bi["u"]))
				_prend(occ, tp, 1.1)
				if n_gens < 7:
					n_gens += 1
					var f: Node = T._gens_ajoute(["homme", "femme", "garcon"][rng.randi() % 3], tp - (bi["u"] as Vector3) * 0.7, bi["u"], "debout", rng, LIGNES_SPORT)
					if f != null and f.has_method("plank"):
						f.plank(tp - (bi["u"] as Vector3) * 0.75 + Vector3.UP * 0.03, bi["u"])
	# le coin des haltères
	var gr: Dictionary = _grande(T)
	if not gr.is_empty():
		var hp: Vector3 = _place(T, occ, rng, gr["r"], 1.1, y)
		if hp != Vector3.INF:
			var f2: Vector3 = -(gr["o"] as Vector3)
			var bs := Basis(Vector3.UP, _yaw(f2))
			_piece(b, "metal_noir", hp, bs, Vector3(0, 0.45, 0), Vector3(1.8, 0.06, 0.5))
			for sx in [-0.85, 0.85]:
				_piece(b, "metal_noir", hp, bs, Vector3(sx, 0.22, 0), Vector3(0.06, 0.44, 0.45))
			for k in range(8):
				var dp: Vector3 = hp + bs * Vector3(-0.75 + k * 0.215, 0.52, 0)
				b.tube("in_inox", dp - bs * Vector3(0, 0, 0.14), dp + bs * Vector3(0, 0, 0.14), 0.015, 5)
				for sz2 in [-0.12, 0.12]:
					b.cyl("in_noir", Transform3D(bs * Basis(Vector3.RIGHT, PI * 0.5), dp + bs * Vector3(0, 0, sz2)), 0.04 + k * 0.006, 0.04 + k * 0.006, 0.05, 10)
			T._col(hp + Vector3.UP * 0.3, Vector3(1.8, 0.6, 0.5), _yaw(f2))
			_gens(T, rng, hp + f2 * 0.8, -f2, "bras_croises", LIGNES_SPORT)
			_prend(occ, hp, 1.2)
	# le grand miroir, sur une face du cœur
	var core: Rect2 = T.info["core"]
	var n: Vector3 = T.info["regard"]
	var side: Vector3 = n.cross(Vector3.UP)
	var half: float = (absf(side.x) * core.size.x + absf(side.z) * core.size.y) * 0.5
	var lg: float = (absf(n.x) * core.size.x + absf(n.z) * core.size.y) - 0.4
	var mc := Vector3(core.get_center().x, y, core.get_center().y) + side * (half + 0.03)
	b.box_at("in_miroir", mc + Vector3.UP * 0.2, Vector3(lg, 2.0, 0.02), _yaw(side))
	b.box_at("in_menuiserie", mc + Vector3.UP * 0.15, Vector3(lg + 0.06, 0.05, 0.05), _yaw(side))
	# l'eau fraîche
	var fp: Vector3 = _place(T, occ, rng, (T._bandes()[0] as Rect2), 0.5, y) if not T._bandes().is_empty() else Vector3.INF
	if fp != Vector3.INF:
		Kit.vending(b, fp, Vector3(0, 0, 1), "plastique_bleu")
		T._col(fp + Vector3.UP * 0.95, Vector3(1.05, 1.9, 0.8))
	return ""


static func _tapis(T: Node, b: Kit.Batch, p: Vector3, face: Vector3, rng: RandomNumberGenerator) -> void:
	var bs := Basis(Vector3.UP, _yaw(face))
	_piece(b, "in_noir", p, bs, Vector3(0, 0.1, 0), Vector3(0.75, 0.2, 1.8))
	_piece(b, "in_cuir", p, bs, Vector3(0, 0.205, -0.05), Vector3(0.55, 0.01, 1.55))
	for sx in [-0.33, 0.33]:
		b.tube("in_inox", p + bs * Vector3(sx, 0.2, 0.75), p + bs * Vector3(sx, 1.25, 0.85), 0.025, 6)
	_piece(b, "in_noir", p, bs, Vector3(0, 1.3, 0.85), Vector3(0.7, 0.3, 0.1))
	_piece(b, "in_ecran_vert" if rng.randf() < 0.5 else "in_ecran", p, bs, Vector3(0, 1.32, 0.795), Vector3(0.36, 0.18, 0.01))
	T._col(p + Vector3.UP * 0.1, Vector3(0.75, 0.2, 1.8), _yaw(face))
	T._col(p + bs * Vector3(0, 0.75, 0.85), Vector3(0.75, 1.5, 0.15), _yaw(face))


static func _velo(T: Node, b: Kit.Batch, p: Vector3, face: Vector3) -> void:
	var bs := Basis(Vector3.UP, _yaw(face))
	_piece(b, "in_noir", p, bs, Vector3(0, 0.05, 0), Vector3(0.5, 0.1, 1.1))
	b.tube("in_inox", p + bs * Vector3(0, 0.1, -0.35), p + bs * Vector3(0, 0.75, -0.2), 0.04, 6)
	b.tube("in_inox", p + bs * Vector3(0, 0.1, 0.35), p + bs * Vector3(0, 1.0, 0.35), 0.04, 6)
	_piece(b, "in_cuir", p, bs, Vector3(0, 0.78, -0.2), Vector3(0.24, 0.07, 0.3))
	_piece(b, "in_noir", p, bs, Vector3(0, 1.02, 0.35), Vector3(0.5, 0.04, 0.06))
	b.cyl("in_noir", Transform3D(bs * Basis(Vector3.FORWARD, PI * 0.5), p + bs * Vector3(0, 0.35, 0.2)), 0.25, 0.25, 0.06, 16)
	T._col(p + Vector3.UP * 0.5, Vector3(0.5, 1.0, 1.1), _yaw(face))


static func jardin(T: Node, b: Kit.Batch, rng: RandomNumberGenerator, t: Dictionary) -> String:
	var y: float = T.info["y"]
	var occ: Array = []
	enseigne(T, b, "JARDIN SUSPENDU", "neon_vert", -1.0, 80)
	# des cerisiers dans leurs bacs, des bambous, des bancs, des pas japonais
	for r in T._bandes():
		var bi: Dictionary = bande(T, r)
		var o: Vector3 = bi["o"]
		var a: float = float(bi["a0"]) + 1.8
		while a < float(bi["a1"]) - 1.6:
			var p: Vector3 = pt(bi, a, 1.0, y)
			if _okf(T, occ, p, 0.9, o, 1.0):
				if rng.randf() < 0.55:
					b.cyl_at("in_bois", p, 0.85, 0.8, 0.45, 16)
					b.cyl_at("in_terre", p + Vector3.UP * 0.45, 0.78, 0.78, 0.02, 16)
					Kit.cherry(b, p + Vector3.UP * 0.45, rng, 0.75)
					T._col(p + Vector3.UP * 0.5, Vector3(1.6, 1.0, 1.6))
				else:
					_meuble(T, b, "in_bois", p, Vector3(1.8, 0.4, 0.6), -o)
					for k in range(9):
						var bp: Vector3 = p + (bi["u"] as Vector3) * (-0.8 + k * 0.2) + Vector3.UP * 0.4
						var hb: float = rng.randf_range(1.6, 2.4)
						b.tube("in_feuille", bp, bp + Vector3(rng.randf_range(-0.08, 0.08), hb, rng.randf_range(-0.08, 0.08)), 0.03, 5)
						b.blob("in_feuille", bp + Vector3.UP * hb, Vector3(0.18, 0.25, 0.18), 6)
				_prend(occ, p, 1.0)
			a += 2.6
		for k2 in range(2):
			var bp2: Vector3 = _place(T, occ, rng, r, 1.0, y)
			if bp2 != Vector3.INF:
				var yaw: float = _yaw(-o)
				Kit.bench(b, bp2, yaw)
				T._col(bp2 + Vector3.UP * 0.4, Vector3(1.9, 0.8, 0.5), yaw)
				_prend(occ, bp2, 1.0)
				if rng.randf() < 0.6:
					_gens(T, rng, bp2, -o, ["assis", "lire", "mediter"][rng.randi() % 3], LIGNES_JARDIN_INT, ["homme", "femme", "vieux", "vieille"])
		# des pas japonais sur le gravier
		for k3 in range(6):
			var sp: Vector3 = Vector3(rng.randf_range(r.position.x + 0.5, r.end.x - 0.5), y, rng.randf_range(r.position.y + 0.5, r.end.y - 0.5))
			b.cyl_at("pierre", sp, 0.3, 0.32, 0.04, 9)
	# la fontaine
	var gr: Dictionary = _grande(T)
	var fp: Vector3 = _place(T, occ, rng, gr["r"], 1.3, y)
	if fp != Vector3.INF:
		b.cyl_at("pierre", fp, 1.2, 1.25, 0.45, 24)
		b.cyl_at("eau", fp + Vector3.UP * 0.4, 1.05, 1.05, 0.02, 24)
		b.cyl_at("pierre", fp + Vector3.UP * 0.4, 0.2, 0.25, 0.7, 10)
		b.blob("eau", fp + Vector3.UP * 1.15, Vector3(0.12, 0.12, 0.12), 8)
		T._col(fp + Vector3.UP * 0.25, Vector3(2.4, 0.5, 2.4))
		lumiere(T, fp + Vector3.UP * 0.6, Color(0.6, 0.85, 1.0), 0.7, 3.5)
		_prend(occ, fp, 1.4)
	return "fontaine_holo"


## La piscine (le dernier étage des grandes Résidences) : le bassin creusé dans la dalle (T.info["bassin"] :
## son rectangle ; tours_v153 a laissé le trou dans le sol), l'eau qui ondule, les transats, la verrière.
static func piscine(T: Node, b: Kit.Batch, rng: RandomNumberGenerator, t: Dictionary) -> String:
	var y: float = T.info["y"]
	var hc: float = float(t["e"]) - 0.35
	var occ: Array = []
	var B: Rect2 = T.info.get("bassin", Rect2())
	if B.size.x < 2.0:
		return ""
	var prof: float = 1.35
	var c := Vector3(B.get_center().x, y, B.get_center().y)
	# le fond et les parois carrelées, les lignes d'eau, les marches
	T._boite(b, "in_carrelage", c + Vector3.DOWN * (prof + 0.1), Vector3(B.size.x, 0.2, B.size.y), true)
	for e in [[Vector3(c.x, 0, B.position.y - 0.1), Vector3(B.size.x + 0.4, 0, 0.2)], [Vector3(c.x, 0, B.end.y + 0.1), Vector3(B.size.x + 0.4, 0, 0.2)],
			[Vector3(B.position.x - 0.1, 0, c.z), Vector3(0.2, 0, B.size.y)], [Vector3(B.end.x + 0.1, 0, c.z), Vector3(0.2, 0, B.size.y)]]:
		var at: Vector3 = e[0]
		var s0: Vector3 = e[1]
		T._boite(b, "in_carrelage", Vector3(at.x, y - prof * 0.5, at.z), Vector3(s0.x, prof, s0.z), true)
		# la margelle
		b.box("in_marbre_blanc", Transform3D(Basis(), Vector3(at.x, y + 0.02, at.z)), Vector3(s0.x + 0.1, 0.04, s0.z + 0.2))
	var long_x: bool = B.size.x >= B.size.y
	for k in range(1, 4):
		var f: float = float(k) / 4.0
		var lp := Vector3(lerpf(B.position.x, B.end.x, f), y - prof + 0.005, c.z) if not long_x else Vector3(c.x, y - prof + 0.005, lerpf(B.position.y, B.end.y, f))
		b.box("plastique_bleu", Transform3D(Basis(), lp), Vector3(0.2, 0.01, B.size.y - 1.0) if not long_x else Vector3(B.size.x - 1.0, 0.01, 0.2))
	# les marches, à un bout (quatre marches de 27 cm : on descend dans l'eau, on en ressort)
	for i in range(4):
		var haut: float = prof - (i + 1) * prof / 5.0
		var al: float = (B.position.x if long_x else B.position.y) + 0.2 + i * 0.4
		var sp := Vector3(al, y - prof + haut * 0.5, c.z) if long_x else Vector3(c.x, y - prof + haut * 0.5, al)
		T._boite(b, "in_carrelage", sp, Vector3(0.4, haut, 1.6) if long_x else Vector3(1.6, haut, 0.4), true)
	# l'eau : une surface qui ondule (son relief glisse : _process), une lumière dessous
	var eau := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = B.size
	eau.mesh = pm
	var em := StandardMaterial3D.new()
	em.albedo_color = Color(0.25, 0.65, 0.8, 0.55)
	em.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	em.roughness = 0.04
	em.metallic = 0.1
	em.cull_mode = BaseMaterial3D.CULL_DISABLED
	if ResourceLoader.exists("res://assets/textures/neo156/eau_n.png"):
		em.normal_enabled = true
		em.normal_texture = load("res://assets/textures/neo156/eau_n.png")
		em.normal_scale = 0.6
		em.uv1_scale = Vector3(B.size.x / 2.0, B.size.y / 2.0, 1.0)
	eau.material_override = em
	eau.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	T._node.add_child(eau)
	eau.global_position = c + Vector3.DOWN * 0.15
	T._eaux.append(em)
	lumiere(T, c + Vector3.DOWN * 0.9, Color(0.35, 0.8, 1.0), 1.6, maxf(B.size.x, B.size.y) * 0.7)
	_prend(occ, c, 0.0)
	occ.append([Vector2(c.x, c.z), maxf(B.size.x, B.size.y) * 0.5 + 0.4])
	# les baigneurs (debout dans l'eau), le maître-nageur sur sa chaise haute
	for k2 in range(rng.randi_range(2, 4)):
		var bp := Vector3(rng.randf_range(B.position.x + 2.0, B.end.x - 0.6), y - prof, rng.randf_range(B.position.y + 0.6, B.end.y - 0.6)) if long_x \
			else Vector3(rng.randf_range(B.position.x + 0.6, B.end.x - 0.6), y - prof, rng.randf_range(B.position.y + 2.0, B.end.y - 0.6))
		_gens(T, rng, bp, _dir(rng), ["debout", "rire"][rng.randi() % 2], LIGNES_PISCINE, ["homme", "femme", "garcon", "fille"])
	# les transats, autour
	for r in T._bandes():
		for k3 in range(3):
			var tp: Vector3 = _place(T, occ, rng, r, 0.8, y)
			if tp == Vector3.INF:
				continue
			var f2: Vector3 = (c - tp)
			f2.y = 0.0
			f2 = f2.normalized()
			var bs := Basis(Vector3.UP, _yaw(f2))
			_piece(b, "peinture_blanche", tp, bs, Vector3(0, 0.3, 0.1), Vector3(0.65, 0.06, 1.3))
			b.box(["tissu_bleu", "tissu_jaune", "tissu_rouge"][rng.randi() % 3], Transform3D(bs * Basis(Vector3.RIGHT, -0.7), tp + bs * Vector3(0, 0.55, -0.62)), Vector3(0.62, 0.06, 0.7))
			for sx in [-0.28, 0.28]:
				_piece(b, "metal", tp, bs, Vector3(sx, 0.14, 0.1), Vector3(0.04, 0.28, 1.2))
			T._col(tp + Vector3.UP * 0.35, Vector3(0.7, 0.7, 1.6), _yaw(f2))
			_prend(occ, tp, 0.9)
			if rng.randf() < 0.4:
				var f3: Node = T._gens_ajoute(["homme", "femme", "vieux", "vieille"][rng.randi() % 4], tp, f2, "debout", rng, LIGNES_PISCINE)
				if f3 != null and f3.has_method("lie"):
					f3.lie(tp + bs * Vector3(0, 0.25, 0.55), -f2)
	var mp: Vector3 = Vector3(B.end.x + 1.3, y, c.z) if long_x else Vector3(c.x, y, B.end.y + 1.3)
	if T._libre(mp, 0.4):
		for sx2 in [-0.25, 0.25]:
			b.cyl_at("peinture_blanche", mp + (Vector3(0, 0, sx2) if long_x else Vector3(sx2, 0, 0)), 0.03, 0.03, 1.7, 6)
		b.box("peinture_blanche", Transform3D(Basis(), mp + Vector3.UP * 1.7), Vector3(0.6, 0.06, 0.6))
		b.box("plastique_rouge", Transform3D(Basis(), mp + Vector3.UP * 1.95 + (Vector3(0.25, 0, 0) if long_x else Vector3(0, 0, 0.25))), Vector3(0.6, 0.5, 0.06) if not long_x else Vector3(0.06, 0.5, 0.6))
		T._col(mp + Vector3.UP * 1.0, Vector3(0.7, 2.0, 0.7))
		_gens(T, rng, mp + Vector3.UP * 1.73, (c - mp).normalized(), "assis", ["Pas de plongeon, c'est le règlement. Et le règlement, c'est moi.", "Je surveille. Même quand j'ai l'air de dormir."], ["homme", "femme"])
	# des plantes
	for k4 in range(6):
		var pp: Vector3 = _place(T, occ, rng, T.info["rect"], 0.4, y)
		if pp != Vector3.INF:
			T._plante(b, pp, 1.5)
			_prend(occ, pp, 0.5)
	return "nage"
