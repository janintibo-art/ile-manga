extends RefCounted
## V61 : le relief de Cliquetis, la cité des ingénieurs fous, sur les hautes terres du nord de
## la grande île (grande_ile_v59.gd appelle shape() pour chaque point de sa grille).
## Repère « cité » : monde = ORIGIN + (x, y, z) (pas de rotation). -Z : le nord, vers la mer.
##  - la cité, sur une terrasse à 30 m au bord des falaises du nord ;
##  - le port, au pied des falaises : un quai à 1,4 m, la mer devant ;
##  - la route en lacet qui monte du port (deux rampes, à l'est) ;
##  - les aires du dirigeable « le Zéphyr » : à Cliquetis, au nord de Tazira, à l'est de Carène.

const ORIGIN := Vector3(960.0, 0.0, -315.0)
const CITY_Y: float = 30.0
const CITY := Rect2(-100.0, -42.0, 200.0, 90.0)          # x, z, largeur, profondeur (repère cité)
const PORT := Rect2(-56.0, -97.0, 130.0, 13.0)
const PORT_Y: float = 1.4
const ROAD := [Vector3(62.0, 1.4, -90.0), Vector3(132.0, 16.0, -72.0), Vector3(101.0, 30.0, -36.0)]
const ROAD_W: float = 3.6
## Les aires du dirigeable (monde) : [centre, rayon, hauteur]
const PADS := [[Vector3(890.0, 30.0, -293.0), 13.0], [Vector3(948.0, 8.5, -16.0), 13.0], [Vector3(770.0, 8.3, -136.0), 13.0]]


static func to_world(x: float, z: float, y: float = 0.0) -> Vector3:
	return Vector3(ORIGIN.x + x, y, ORIGIN.z + z)


static func to_city(wx: float, wz: float) -> Vector2:
	return Vector2(wx - ORIGIN.x, wz - ORIGIN.z)


static func _rect_dist(x: float, z: float, r: Rect2) -> float:
	var dx: float = maxf(maxf(r.position.x - x, x - r.end.x), 0.0)
	var dz: float = maxf(maxf(r.position.y - z, z - r.end.y), 0.0)
	return Vector2(dx, dz).length()


## La hauteur de la route en (x, z) et la distance à son axe.
static func road_at(x: float, z: float) -> Vector2:
	var best := Vector2(INF, 0.0)
	for i in range(ROAD.size() - 1):
		var a: Vector3 = ROAD[i]
		var b: Vector3 = ROAD[i + 1]
		var a2 := Vector2(a.x, a.z)
		var ab := Vector2(b.x - a.x, b.z - a.z)
		var t: float = clampf((Vector2(x, z) - a2).dot(ab) / ab.length_squared(), 0.0, 1.0)
		var q: Vector2 = a2 + ab * t
		var d: float = Vector2(x, z).distance_to(q)
		if d < best.x:
			best = Vector2(d, lerpf(a.y, b.y, t))
	return best


static func shape(wx: float, wz: float, h: float) -> float:
	# les aires du dirigeable
	for pd in PADS:
		var c: Vector3 = pd[0]
		var r: float = float(pd[1])
		var dd: float = Vector2(wx - c.x, wz - c.z).length()
		if dd < r + 14.0:
			h = lerpf(c.y, h, smoothstep(r, r + 14.0, dd))
	var t: Vector2 = to_city(wx, wz)
	var x: float = t.x
	var z: float = t.y
	if x < -170.0 or x > 200.0 or z < -150.0 or z > 110.0:
		return h
	var wob: float = sin(x * 0.19 + z * 0.13) * 0.3 + sin(x * 0.07 - z * 0.11) * 0.4
	# --- la cité : une terrasse ; au nord, la falaise reste une falaise
	var dc: float = _rect_dist(x, z, CITY)
	if dc <= 0.0:
		h = CITY_Y
	elif dc < 36.0:
		var k: float = smoothstep(0.0, 36.0, dc)
		if z < CITY.position.y:
			# la falaise : on garde la pente naturelle, mais le bord est net
			h = minf(lerpf(CITY_Y, h, smoothstep(0.0, 6.0, dc)), CITY_Y)
		else:
			h = lerpf(CITY_Y, h, k)
	# --- le port au pied des falaises
	var dp: float = _rect_dist(x, z, PORT)
	if dp <= 0.0:
		h = PORT_Y
	elif dp < 18.0:
		if z < PORT.position.y:
			h = minf(h, lerpf(PORT_Y - 0.6, -4.5 + wob, smoothstep(0.0, 10.0, dp)))
		else:
			h = lerpf(PORT_Y, h, smoothstep(0.0, 18.0, dp))
	# devant le port, assez de fond pour la barque et le vapeur
	if z < PORT.position.y and z > -150.0 and x > PORT.position.x - 20.0 and x < PORT.end.x + 20.0:
		var edge: float = minf(x - (PORT.position.x - 20.0), (PORT.end.x + 20.0) - x)
		h = minf(h, lerpf(h, -4.5 + wob, smoothstep(0.0, 14.0, edge) * smoothstep(PORT.position.y, PORT.position.y - 8.0, z)))
	# --- la route du port à la cité
	var rd: Vector2 = road_at(x, z)
	if rd.x < ROAD_W + 9.0:
		var ry: float = rd.y
		if rd.x <= ROAD_W:
			h = ry
		else:
			h = lerpf(ry, h, smoothstep(ROAD_W, ROAD_W + 9.0, rd.x))
	return h
