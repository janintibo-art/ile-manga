extends Node3D
## V213 : la roche de l'Île Foraine, devenue volcanique. Peu de choses, mais tout près de la voie du
## grand huit, pour que la vitesse se voie : les orgues de basalte (des colonnes à six pans, par
## bouquets) le long de la ligne droite de l'est et, dressées dans la mer, le long des deux grands
## virages au ras de l'eau ; les arches de roche que la voie traverse (deux sur la Faille, une sur
## chaque virage) ; le panache du cratère et la lueur de la lave, la nuit. La lave d'ici est une
## croûte tiède : on y marche (l'île est une île paisible).

const Kit = preload("res://scripts/foraine_kit_v209.gd")
const GK = preload("res://scripts/geants_kit_v142.gd")
const IleScript = preload("res://scripts/ile_foraine_v209.gd")
const Trace = preload("res://scripts/grand_huit_trace_v209.gd")

const LIBRE: float = 4.3                  # rien à moins de 4,3 m de l'axe de la voie
## Les bouquets d'orgues : [premier point de la voie, dernier, pas (m), hauteur au-dessus de la voie mini, maxi]
const ORGUES := [
	[1146, 1300, 13, 2.0, 8.0],               # la ligne droite de l'est
	[468, 690, 17, 3.0, 12.0],                # le virage du nord, dans la mer
	[1322, 1470, 17, 3.0, 11.0],              # le virage du sud, dans la mer
	[806, 880, 15, 1.0, 6.0],                 # la descente vers la boucle
	[1478, 1600, 14, 1.5, 6.0],               # les petites bosses, sur la grève du sud-ouest
]
## Les arches : [point de la voie, demi-portée, hauteur de la clé au-dessus de la voie, grosseur]
const ARCHES := [[318, 11.5, 15.5, 2.3], [342, 11.5, 14.5, 2.5], [592, 10.0, 10.5, 2.1], [1420, 10.0, 10.5, 2.1]]

var main: Node
var ile: Node3D
var colonnes: int = 0
var bouquets: int = 0
var arches: int = 0
var au_plus_pres: float = 99.0            # la roche la plus proche de l'axe de la voie (m)
var lueurs: Array = []
var _pts: PackedVector3Array
var _rng := RandomNumberGenerator.new()


func setup(main_node: Node, ile_node: Node3D, cols: GK.Cols) -> void:
	main = main_node
	ile = ile_node
	name = "Volcan_v213"
	_rng.seed = 21301
	_pts = Trace.tracer()["pts"]
	var tan: PackedVector3Array = Trace.tracer()["tan"]
	var k: int = 0
	for o in ORGUES:
		var b := Kit.Lot.new()
		var i: int = int(o[0])
		while i <= int(o[1]):
			var cote: float = 1.0 if k % 2 == 0 else -1.0
			k += 1
			var t: Vector3 = tan[i]
			var lat := Vector3(t.z, 0.0, -t.x).normalized()
			var rayon: float = _rng.randf_range(2.6, 4.2)
			var c: Vector3 = _pts[i] + lat * cote * (LIBRE + rayon + _rng.randf_range(0.3, 1.6))
			_bouquet(b, cols, c, rayon, _pts[i].y + _rng.randf_range(float(o[3]), float(o[4])))
			i += int(o[2]) + _rng.randi_range(-3, 3)
		b.commit(self, "Orgues_%d_v213" % int(o[0]), true, 1400.0)
	var ba := Kit.Lot.new()
	for a in ARCHES:
		_arche(ba, cols, int(a[0]), float(a[1]), float(a[2]), float(a[3]), tan[int(a[0])])
	ba.commit(self, "Arches_v213", true, 1600.0)
	_panache()
	_lueur(IleScript.W(IleScript.BUTTE.x, IleScript.BUTTE.y, IleScript.LAVE_Y + 5.0) + Vector3(0, 0, 17), 60.0)
	_lueur(IleScript.W(IleScript.FAILLE_A.x, (IleScript.FAILLE_A.y + IleScript.FAILLE_B.y) * 0.5, 7.0), 34.0)
	print("ILE_MANGA_V213: la roche de l'Île Foraine : %d colonnes de basalte en %d bouquets, %d arches, au plus près à %.1f m de la voie" % [colonnes, bouquets, arches, au_plus_pres])


func _w(l: Vector3) -> Vector3:
	return Vector3(IleScript.CENTER.x + l.x, l.y, IleScript.CENTER.z + l.z)


## La distance (à plat) d'un point à la voie, pour les bouts de voie qui passent à sa hauteur
func _a_la_voie(p: Vector3, haut: float) -> float:
	var best: float = 1e9
	for q in _pts:
		if q.y > haut + 3.0 or q.y < p.y - 3.0:
			continue
		var dx: float = q.x - p.x
		var dz: float = q.z - p.z
		if absf(dx) < 12.0 and absf(dz) < 12.0:
			best = minf(best, sqrt(dx * dx + dz * dz))
	return best


## Un bouquet d'orgues : des colonnes à six pans serrées, les plus hautes au milieu
func _bouquet(b: Kit.Lot, cols: GK.Cols, c: Vector3, rayon: float, sommet: float) -> void:
	var r: float = _rng.randf_range(0.72, 0.95)
	var pas: float = r * 1.74
	var n: int = int(ceil(rayon / pas))
	var faits: int = 0
	var haut_max: float = -99.0
	var pied_min: float = 99.0
	for qz in range(-n, n + 1):
		for qx in range(-n, n + 1):
			var lx: float = (qx + (0.5 if (qz & 1) != 0 else 0.0)) * pas
			var lz: float = qz * pas * 0.866
			var d: float = Vector2(lx, lz).length()
			if d > rayon:
				continue
			var p := Vector3(c.x + lx, 0.0, c.z + lz)
			var sol: float = float(ile.height_l(p.x, p.z))
			var pied: float = maxf(sol, -9.0) - 1.2
			var haut: float = sommet - (d / rayon) * (d / rayon) * (sommet - maxf(sol, 0.0)) * 0.7 - _rng.randf_range(0.0, 3.2)
			haut = snappedf(haut, 0.4)
			if haut < maxf(sol, -0.2) + 0.8:
				continue
			p.y = pied
			var dv: float = _a_la_voie(p, haut)
			if dv < LIBRE + r:
				continue
			au_plus_pres = minf(au_plus_pres, dv - r)
			b.cyl("basalte", Transform3D(Basis(Vector3.UP, 0.5236), _w(p)), r * 1.01, r * 0.97, haut - pied, 6)
			colonnes += 1
			faits += 1
			haut_max = maxf(haut_max, haut)
			pied_min = minf(pied_min, maxf(sol, -2.0))
	if faits > 0:
		bouquets += 1
		if cols != null and haut_max > pied_min + 1.0:
			cols.cyl(_w(Vector3(c.x, pied_min, c.z)), rayon * 0.82, haut_max - pied_min)


## Une arche de roche par-dessus la voie : un gros boudin de basalte en demi-ovale, bosselé, épais
## aux pieds (ils descendent dans le sol, ou au fond de l'eau), plus mince à la clé.
func _arche(b: Kit.Lot, cols: GK.Cols, i: int, demi: float, cle: float, gros: float, t: Vector3) -> void:
	var lat := Vector3(t.z, 0.0, -t.x).normalized()
	var av := Vector3(t.x, 0.0, t.z).normalized()
	var c: Vector3 = _pts[i]
	var bruit := FastNoiseLite.new()
	bruit.seed = 21300 + i
	bruit.frequency = 0.16
	bruit.fractal_octaves = 3
	var pas: int = 26
	var pans: int = 10
	var enfoui: float = 0.0
	for cote in [-1.0, 1.0]:
		var pp: Vector3 = c + lat * cote * demi
		enfoui = maxf(enfoui, c.y - maxf(float(ile.height_l(pp.x, pp.z)), -9.0) + 1.5)
	var anneaux: Array = []
	for k in range(pas + 1):
		# du pied gauche (sous le sol) à la clé, puis au pied droit
		var a: float = PI * float(k) / float(pas)
		var centre: Vector3 = c + lat * cos(a) * demi * (1.0 + 0.12 * sin(a * 3.0 + i)) + Vector3.UP * (sin(a) * (cle + enfoui) - enfoui)
		centre += av * bruit.get_noise_1d(k * 3.0) * 1.2
		var vers: Vector3 = (lat * -sin(a) * demi + Vector3.UP * cos(a) * (cle + enfoui)).normalized()
		var dehors: Vector3 = vers.cross(av).normalized()
		var r: float = gros * lerpf(1.45, 0.8, sin(a))
		var ring: Array = []
		for j in range(pans):
			var ang: float = TAU * j / pans
			var dir: Vector3 = dehors * cos(ang) + av * sin(ang)
			var q: Vector3 = centre + dir * r
			var rr: float = r * (1.0 + 0.3 * bruit.get_noise_3d(q.x * 1.6, q.y * 1.6, q.z * 1.6)) * (1.25 if absf(sin(ang)) > 0.7 else 1.0)
			ring.append([_w(centre + dir * rr), dir])
			# vers la voie : jamais trop près
			if centre.y - rr < c.y + 4.5 and centre.y + rr > c.y - 1.0:
				au_plus_pres = minf(au_plus_pres, Vector2((centre + dir * rr - c).dot(lat), 0.0).length())
		anneaux.append(ring)
	var v: float = 0.0
	for k in range(pas):
		var r0: Array = anneaux[k]
		var r1: Array = anneaux[k + 1]
		var dv: float = ((r0[0][0] as Vector3) - (r1[0][0] as Vector3)).length()
		for j in range(pans):
			var j1: int = (j + 1) % pans
			var u0: float = float(j) * gros * 0.63
			var u1: float = float(j + 1) * gros * 0.63
			b.tri("basalte", [r0[j][0], r1[j1][0], r1[j][0]], [r0[j][1], r1[j1][1], r1[j][1]], [Vector2(u0, v), Vector2(u1, v + dv), Vector2(u0, v + dv)])
			b.tri("basalte", [r0[j][0], r0[j1][0], r1[j1][0]], [r0[j][1], r0[j1][1], r1[j1][1]], [Vector2(u0, v), Vector2(u1, v), Vector2(u1, v + dv)])
		v += dv
	if cols != null:
		for cote in [-1.0, 1.0]:
			var pied: Vector3 = c + lat * cote * demi
			var sol: float = maxf(float(ile.height_l(pied.x, pied.z)), -2.0)
			cols.cyl(_w(Vector3(pied.x, sol, pied.z)), gros * 1.3, maxf(c.y + cle * 0.45 - sol, 1.0))
	arches += 1


## Le panache : une fumée grise qui monte du cratère et file au vent
func _panache() -> void:
	var s := CPUParticles3D.new()
	s.name = "Panache_v213"
	s.amount = 26
	s.lifetime = 16.0
	s.preprocess = 16.0
	s.direction = Vector3(0.25, 1.0, 0.1)
	s.spread = 9.0
	s.initial_velocity_min = 3.0
	s.initial_velocity_max = 4.6
	s.gravity = Vector3(0.5, 0.05, 0.2)
	s.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	s.emission_sphere_radius = 9.0
	s.scale_amount_min = 9.0
	s.scale_amount_max = 15.0
	var courbe := Curve.new()
	courbe.add_point(Vector2(0.0, 0.35))
	courbe.add_point(Vector2(1.0, 2.2))
	s.scale_amount_curve = courbe
	var g := Gradient.new()
	g.set_color(0, Color(0.34, 0.3, 0.3, 0.0))
	g.add_point(0.12, Color(0.3, 0.27, 0.27, 0.5))
	g.set_color(g.get_point_count() - 1, Color(0.62, 0.6, 0.6, 0.0))
	s.color_ramp = g
	var qm := QuadMesh.new()
	qm.size = Vector2(1.0, 1.0)
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	if main != null and main.has_method("_soft_dot_v24"):
		m.albedo_texture = main._soft_dot_v24()
	else:
		var gt := GradientTexture2D.new()
		gt.fill = GradientTexture2D.FILL_RADIAL
		gt.fill_from = Vector2(0.5, 0.5)
		gt.fill_to = Vector2(1.0, 0.5)
		var gg := Gradient.new()
		gg.set_color(0, Color(1, 1, 1, 1))
		gg.set_color(1, Color(1, 1, 1, 0))
		gt.gradient = gg
		m.albedo_texture = gt
	qm.material = m
	s.mesh = qm
	s.visibility_aabb = AABB(Vector3(-40, -10, -40), Vector3(140, 130, 110))
	s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(s)
	s.global_position = IleScript.W(IleScript.BUTTE.x + 4.0, IleScript.BUTTE.y - 13.0, IleScript.CRATERE_Y - 8.0)


## La lueur rouge de la lave (sans ombre, une petite portée : elle ne coûte presque rien)
func _lueur(at: Vector3, portee: float) -> void:
	var l := OmniLight3D.new()
	l.name = "Lueur_lave_v213"
	l.light_color = Color(1.0, 0.36, 0.1)
	l.light_energy = 2.2
	l.omni_range = portee
	l.omni_attenuation = 1.3
	l.shadow_enabled = false
	l.distance_fade_enabled = true
	l.distance_fade_begin = 260.0
	l.distance_fade_length = 60.0
	add_child(l)
	l.global_position = at
	lueurs.append(l)
