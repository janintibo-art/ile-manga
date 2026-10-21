extends RefCounted
## V60 : le relief de Tazira, le grand port de pêcheurs de la côte sud de la grande île
## (grande_ile_v59.gd appelle shape() pour chaque point de sa grille).
## Repère « ville » : origine au milieu du quai, au niveau de la mer ; +Z vers l'intérieur
## des terres (le nord), -Z vers la mer (le sud), +X vers l'ouest du monde (le repère est
## tourné d'un demi-tour : monde = ORIGIN + (-x, y, -z)).
##  - le port : un bassin de 5 m de fond, abrité par deux jetées (construites par la ville) ;
##  - le quai, à 1,4 m, tout le long du bassin ;
##  - la ville, sur une terrasse en pente douce qui monte vers les remparts du nord ;
##  - la plage des barques à l'est du port ;
##  - à l'ouest, la pointe rocheuse de la Skala, le bastion aux canons.

const ORIGIN := Vector3(940.0, 0.0, 95.0)
const QUAY_Y: float = 1.4
const QUAY_Z1: float = 18.0          # fond du quai (début de la ville)
const TOWN_Z1: float = 76.0          # rempart du nord
const TOWN_X: float = 102.0          # remparts est et ouest
const BASIN := Rect2(-84.0, -104.0, 172.0, 104.0)     # x0, z0, largeur, profondeur
const BASIN_Y: float = -5.5
const SKALA := Rect2(92.0, -74.0, 44.0, 92.0)
const SKALA_Y: float = 5.2
const BEACH_X0: float = -184.0
const BEACH_X1: float = -88.0
const MURENE := Rect2(42.0, 20.0, 20.0, 14.0)          # la taverne des pirates (x, z, largeur, profondeur)


static func to_world(x: float, z: float, y: float = 0.0) -> Vector3:
	return Vector3(ORIGIN.x - x, y, ORIGIN.z - z)


static func to_town(wx: float, wz: float) -> Vector2:
	return Vector2(ORIGIN.x - wx, ORIGIN.z - wz)


## La hauteur du sol de la ville (rues, places) en (x, z) du repère ville.
static func town_y(x: float, z: float) -> float:
	if z <= QUAY_Z1:
		return QUAY_Y
	return QUAY_Y + (minf(z, TOWN_Z1 + 10.0) - QUAY_Z1) * 0.058


static func _rect_dist(x: float, z: float, r: Rect2) -> float:
	var dx: float = maxf(maxf(r.position.x - x, x - r.end.x), 0.0)
	var dz: float = maxf(maxf(r.position.y - z, z - r.end.y), 0.0)
	return Vector2(dx, dz).length()


static func shape(wx: float, wz: float, h: float) -> float:
	var t: Vector2 = to_town(wx, wz)
	var x: float = t.x
	var z: float = t.y
	if x < -270.0 or x > 270.0 or z < -170.0 or z > 240.0:
		return h
	var wob: float = sin(x * 0.21 + z * 0.13) * 0.25 + sin(x * 0.07 - z * 0.11) * 0.35
	# --- la ville et le quai : une terrasse, fondue dans le relief autour
	var town := Rect2(-TOWN_X - 4.0, 0.0, 2.0 * TOWN_X + 8.0, TOWN_Z1 + 6.0)
	var dt: float = _rect_dist(x, z, town)
	if dt < 40.0:
		var ty: float = town_y(clampf(x, town.position.x, town.end.x), clampf(z, 0.0, town.end.y))
		if dt <= 0.0:
			h = ty
		else:
			var k: float = smoothstep(0.0, 40.0, dt)
			# au nord et sur les côtés, la ville est adossée aux dunes (on ne creuse pas plus bas)
			h = lerpf(ty, maxf(h, ty - dt * 0.25) if z > 0.0 else h, k)
	# derrière les remparts, les dunes ne montent que doucement (pas de montagne adossée à la ville)
	if z > 0.0 and dt > 0.0 and dt < 150.0:
		var ty2: float = town_y(clampf(x, town.position.x, town.end.x), clampf(z, 0.0, town.end.y))
		var cap: float = ty2 + dt * 0.12 + maxf(0.0, dt - 60.0) * 0.25
		h = minf(h, lerpf(cap, h, smoothstep(90.0, 150.0, dt)))
	# sous la taverne des pirates (on y entre) : le sol ne dépasse pas le plancher
	if x > MURENE.position.x - 0.5 and x < MURENE.end.x + 0.5 and z > MURENE.position.y - 0.5 and z < MURENE.end.y + 0.5:
		h = minf(h, town_y(x, MURENE.position.y) - 0.05)
	# --- la plage des barques, à côté du port (à l'est du monde)
	if x > BEACH_X0 - 30.0 and x < BEACH_X1 + 6.0 and z > -70.0 and z < 40.0:
		var by: float
		if z >= 10.0:
			by = QUAY_Y - 0.1
		elif z >= -36.0:
			by = lerpf(-0.9, QUAY_Y - 0.1, smoothstep(-36.0, 10.0, z))
		else:
			by = lerpf(-0.9, -4.5, smoothstep(-36.0, -66.0, z))
		by += wob * 0.15
		var ex: float = maxf(maxf(BEACH_X0 - x, x - BEACH_X1), 0.0)
		var wb: float = 1.0 - smoothstep(0.0, 30.0, ex)
		if z > 10.0:
			wb *= 1.0 - smoothstep(10.0, 38.0, z)
		h = lerpf(h, by if z < 10.0 else maxf(h, by), wb)
	# --- la pointe de la Skala (le bastion) : un éperon de roche
	var ds: float = _rect_dist(x, z, SKALA)
	if ds < 22.0:
		var rock: float = SKALA_Y + wob * 0.4
		# côté quai, une rampe courte (le quai reste plat jusqu'au bout) ; ailleurs, la roche descend
		var span: float = 9.0 if (x < SKALA.position.x and z > SKALA.position.y + 4.0) else 22.0
		h = lerpf(rock, minf(h, rock), smoothstep(0.0, span, ds)) if ds > 0.0 else rock
		if ds > 0.0 and z < SKALA.position.y + 4.0:
			h = lerpf(rock, -6.0, smoothstep(0.0, 14.0, ds))
	# --- le bassin du port : 5 m d'eau devant le quai ; le mur du quai est vertical
	var db: float = _rect_dist(x, z, BASIN)
	if db <= 0.0:
		var floor_y: float = BASIN_Y + wob * 0.6
		h = lerpf(QUAY_Y, floor_y, smoothstep(0.0, -1.4, z)) if z > -1.4 else floor_y
	elif db < 26.0 and z < 0.0 and ds > 0.0:
		h = minf(h, lerpf(BASIN_Y + wob * 0.6, h, smoothstep(0.0, 26.0, db)))
	# au large, devant l'entrée du port : la mer (pas de terre qui bouche le chenal)
	if z < -60.0 and x > -90.0 and x < 110.0:
		h = minf(h, lerpf(BASIN_Y, -14.0, smoothstep(-100.0, -160.0, z)) + wob * 0.5)
	return h
