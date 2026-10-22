extends RefCounted
## V62 : le plan de Ramure, le village des oreilles, dans la forêt des brumes (l'est de la
## grande île). Les gens de Ramure ont des oreilles et une queue d'animal (renards, lapins,
## chats, loups, ours, tanukis, chouettes, écureuils, biches) ; ils vivent perchés dans six
## arbres géants reliés par des ponts de corde.
## Repère « village » : monde = ORIGIN + (x, y, z), sans rotation ; +X vers la mer (l'est),
## -Z vers le nord. Les hauteurs du sol viennent de l'île (grande_ile_v59.gd) : le village
## garde le relief naturel de la forêt (7 à 11 m), ses mares, et n'aplanit que le Cercle de la
## Lune et la Clairière des Jeux.

const ORIGIN := Vector3(1110.0, 0.0, -140.0)

## Les arbres géants : id, centre (x, z), rayon du tronc à la base, hauteur, plates-formes
## [hauteur au-dessus du pied, largeur du plancher], l'angle (°) où part l'escalier en colimaçon
## (INF : pas d'escalier, on y arrive par les ponts).
const TREES := [
	{"id": "mere", "x": 4.0, "z": -8.0, "r": 4.2, "h": 54.0, "decks": [[10.0, 8.0], [18.0, 8.0], [30.0, 8.0]], "spiral": -60.0},
	{"id": "ouest", "x": -22.0, "z": -42.0, "r": 3.0, "h": 40.0, "decks": [[10.0, 8.0]], "spiral": INF},
	{"id": "guet", "x": 34.0, "z": 8.0, "r": 3.0, "h": 42.0, "decks": [[10.0, 8.0], [20.0, 7.0]], "spiral": 0.0},
	{"id": "sud", "x": 14.0, "z": 42.0, "r": 3.2, "h": 42.0, "decks": [[10.0, 8.0]], "spiral": 236.0},
	{"id": "mares", "x": -22.0, "z": 50.0, "r": 2.8, "h": 38.0, "decks": [[10.0, 8.0]], "spiral": INF},
	{"id": "nord", "x": 16.0, "z": -64.0, "r": 3.0, "h": 40.0, "decks": [[10.0, 8.0]], "spiral": 90.0},
]
## Les ponts de corde (entre les plates-formes du bas).
const BRIDGES := [["mere", "ouest"], ["mere", "guet"], ["guet", "sud"], ["sud", "mares"], ["ouest", "nord"]]

## Les mares de la forêt (creusées par l'île) : centre (x, z), rayon de l'eau.
const PONDS := [[-23.0, 19.8, 15.6], [33.5, -34.5, 10.6], [-50.1, -4.0, 8.6], [-1.3, 77.7, 11.6], [-17.1, -84.0, 13.6], [47.8, -77.4, 8.1]]

const CERCLE := Vector2(8.0, 20.0)          # le Cercle de la Lune (le feu, les danses)
const CERCLE_R: float = 10.0
const JEUX := Vector2(16.0, -32.0)          # la Clairière des Jeux (départ de la Grande Course)
const DOCK := Vector2(88.0, 2.0)            # le ponton de la barque, sur la plage de l'est

## La Grande Course : les arches de lanternes, dans l'ordre (la première est le départ et
## l'arrivée). Une boucle d'environ 320 m autour du village, entre les arbres et les mares.
const COURSE := [Vector2(16.0, -32.0), Vector2(0.0, -50.0), Vector2(-30.0, -62.0), Vector2(-30.0, -20.0), Vector2(-4.0, 4.0),
	Vector2(-2.0, 46.0), Vector2(24.0, 60.0), Vector2(40.0, 24.0), Vector2(48.0, -6.0), Vector2(30.0, -18.0)]


static func to_world(x: float, z: float, y: float = 0.0) -> Vector3:
	return Vector3(ORIGIN.x + x, y, ORIGIN.z + z)


static func to_local(wx: float, wz: float) -> Vector2:
	return Vector2(wx - ORIGIN.x, wz - ORIGIN.z)


static func tree(id: String) -> Dictionary:
	for t in TREES:
		if str(t["id"]) == id:
			return t
	return {}


## Le rayon du tronc à la hauteur y (au-dessus du pied) : presque droit sur 32 m, puis effilé.
static func trunk_r(t: Dictionary, y: float) -> float:
	var r0: float = float(t["r"])
	if y < 32.0:
		return r0 * (1.0 - 0.1 * y / 32.0)
	var k: float = clampf((y - 32.0) / (float(t["h"]) - 32.0), 0.0, 1.0)
	return r0 * lerpf(0.9, 0.3, k)


## Le village (pour la végétation de l'île : pas de buissons dans les allées).
static func in_village(wx: float, wz: float) -> bool:
	var t: Vector2 = to_local(wx, wz)
	if t.x > -42.0 and t.x < 60.0 and t.y > -112.0 and t.y < 72.0:
		return true
	# le chemin et la plage du ponton
	return t.x >= 40.0 and t.x < 100.0 and t.y > -8.0 and t.y < 12.0


## Appelé par grande_ile_v59.gd pour chaque point de sa grille : on aplanit doucement le Cercle
## de la Lune et la Clairière des Jeux (le reste garde le relief de la forêt).
static func shape(wx: float, wz: float, h: float) -> float:
	var t: Vector2 = to_local(wx, wz)
	if t.x < -60.0 or t.x > 110.0 or t.y < -130.0 or t.y > 100.0:
		return h
	var dc: float = t.distance_to(CERCLE)
	if dc < CERCLE_R + 9.0:
		h = lerpf(9.0, h, smoothstep(CERCLE_R + 1.0, CERCLE_R + 9.0, dc))
	var dj: float = t.distance_to(JEUX)
	if dj < 15.0:
		h = lerpf(8.0, h, smoothstep(7.0, 15.0, dj))
	return h
