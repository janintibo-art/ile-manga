extends Node3D
## V115 : LE DÔME D'AZUR, la ville au fond de la mer, à cent quarante mètres sous la surface, au fond de
## la Fosse d'Azur (fosse_azur_v115), au pied des falaises du sud de Hautefond. Futuriste, réaliste et
## lumineux : nacre blanche, verre, titane brossé, diodes aigue-marine, formes de coquillages.
##  - le GRAND DÔME (une coupole géodésique de 140 m sur un tambour vitré) : la PLACE DE LA PERLE, la
##    CHEMINÉE D'AIR (la colonne blanche qui monte jusqu'à la surface, où flotte sa bouée-phare) et la
##    GRANDE PERLE enfilée dessus (le soleil du Dôme), la FONTAINE DES BULLES ; la GARE D'AZUR (le
##    Funiculaire d'Azur : dome_ligne_v115) ; LA CONQUE, le COMPTOIR DES COURANTS, l'ATELIER DES
##    SCAPHANDRES, l'ÉCOLE DES ABYSSES, le JARDIN DES CORAUX, la MAISON DU CONSEIL DES MARÉES ; les
##    maisons-bulles, les deux tours-coquillages, les Gradins ; la PROMENADE DES HUBLOTS et le
##    BELVÉDÈRE DES ABYSSES (au-dessus de la Faille) ;
##  - le DÔME DES SERRES (à l'ouest, par la Galerie des Serres) : les tours de culture, le mur des
##    algues, le Verger des Lampes, le bassin aux nénuphars, l'étal et la maison de la jardinière ;
##  - le DÔME DE L'INSTITUT (à l'est, par la Galerie de l'Institut) : l'Institut des Abysses, le Grand
##    Aquarium, le Bassin des Bathyscaphes (« Le Petit Plongeon »), la Baie d'Observation (face à la
##    cheminée hydrothermale) ;
##  - dehors : le tube de verre du Funiculaire, ses pylônes, le portail du canyon et son tunnel.
## Le verre (verre_abysse_v115) connaît les volumes d'air (set_glass) : derrière lui, la mer profonde.
## Les points, le réseau et les lieux des habitants vont dans ceux de Hautefond (comme ceux des Strates).
## V119 : on entre dans les maisons (maisons_v81, style « dome ») : les quatorze maisons-bulles, les deux
## tours-coquillages, la maisonnette de Mélisande ; huit grands lieux ont leur porte dessinée (portes119 :
## lieux_dome_v119) ; les repères des lieux ouverts pour l'activité (cadres119 : dome_activite_v119).

const F = preload("res://scripts/fosse_azur_v115.gd")
const Kit56 = preload("res://scripts/azur_kit_v56.gd")
const Kit = preload("res://scripts/dome_kit_v115.gd")
const Mats = preload("res://scripts/dome_mats_v115.gd")
const DomeFlore = preload("res://scripts/dome_flore_v115.gd")

const R_G: float = 70.0
const R_SAT: float = 32.0
const H_DRUM: float = 6.0
const H_CAP_G: float = 40.0
const H_CAP_S: float = 20.0
const S_C := Vector2(-128.0, -16.0)
const I_C := Vector2(124.0, 22.0)
const A_GARE: float = -66.0
const PERLE_Y: float = 30.0
const R_GAL: float = 3.2                  # les galeries (rayon ; l'axe à 2,2 m du sol)
const GAL_AXE: float = 2.2
const R_FUNI: float = 3.4
const POOL_R: float = 5.5
const COL_SPLIT: float = 96.0             # la Cheminée d'Air : au-dessus, elle est à la surface (surface_root)
## Les portes des habitants : porte_<prénom> -> ["b", numéro de la maison-bulle (BULLES)],
## ["o", clé d'objets (une porte bâtie ailleurs)] ou [quel dôme ("g", "s", "i"), angle, rayon] (au sol).
const PORTES := {
	"porte_marius": ["b", 9], "porte_josette": ["b", 10], "porte_ernest": ["b", 6], "porte_yolande": ["b", 8],
	"porte_odile": ["b", 12], "porte_mila": ["b", 13], "porte_ondine": ["b", 3], "porte_hippolyte": ["b", 11],
	"porte_lou": ["b", 5], "porte_melisande": ["o", "maison_melisande"],
}

## Les maisons-bulles du Grand Dôme : [angle, rayon, rayon de la bulle, étages, teinte]
const BULLES := [[264.0, 53.0, 4.6, 1, ""], [248.0, 58.0, 5.2, 2, "rose"], [230.0, 52.0, 4.2, 1, "bleu"], [214.0, 58.0, 4.8, 1, ""],
	[197.0, 53.0, 5.4, 2, "sable"], [24.0, 54.0, 4.6, 1, "bleu"], [40.0, 59.0, 5.2, 2, ""], [55.0, 52.0, 4.4, 1, "rose"],
	[78.0, 56.0, 5.0, 2, "sable"], [315.0, 56.0, 4.8, 1, ""], [330.0, 51.0, 4.2, 1, "bleu"], [355.0, 57.0, 5.2, 2, "rose"],
	[118.0, 55.0, 4.6, 1, ""], [178.0, 54.0, 4.4, 1, "bleu"]]

var main: Node
var fosse: Node3D
var hf: Node3D                           # la ville de Hautefond (ses points, son réseau, ses lieux)
var kit
var pc: bool = true
var ligne: Node3D                        # dome_ligne_v115 (bâtie par hautefond_v112)
var objets: Dictionary = {}
var crowd_spots: Array = []
var doors: Dictionary = {}
var bulle_doors: Array = []              # Vector3 : les portes des maisons-bulles (dans l'ordre de BULLES)
var lights: Array = []                   # [OmniLight3D, énergie de jour, énergie de nuit]
var perle_light: OmniLight3D
var sat_lights: Array = []
var perle: Node3D
var bubbles: Array = []                  # les particules (la Fontaine des Bulles, les tubes d'algues)
var jellies_in: Array = []               # [Node3D, centre, phase] : les méduses des cuves
var bathy: Node3D                        # le Petit Plongeon (il se balance à son portique)
var bathy_base := Transform3D.IDENTITY
var surface_root: Node3D                 # la bouée-phare (à la surface : reste visible d'en haut)
var bouee_light: OmniLight3D
var _clock: float = 0.0
var flore: Node3D                        # dome_flore_v115 : les jardinets, les arbres, le Verger
var tank_mm: MultiMeshInstance3D         # les poissons de la grande cuve de l'Aquarium
var tank_fish: Array = []
var tank_center := Vector3.ZERO
var massifs: Array = []                  # [centre (le dessus de la terre), rayon, "arbre" | "buisson"]
var _rng := RandomNumberGenerator.new()
var portes119: Dictionary = {}           # V119 : les grands lieux qu'on visite : lieu -> [porte, dehors]
var cadres119: Dictionary = {}           # V119 : les repères des lieux ouverts (dome_activite_v119)


# =================================================================== repères

static func P(lx: float, lz: float, dy: float = 0.0) -> Vector3:
	return F.W(lx, lz, dy)


static func dirv(deg: float) -> Vector3:
	var a: float = deg_to_rad(deg)
	return Vector3(cos(a), 0, sin(a))


## Autour du Grand Dôme (angle en degrés : 0 = est, 90 = sud).
static func PR(deg: float, r: float, dy: float = 0.0) -> Vector3:
	return P(cos(deg_to_rad(deg)) * r, sin(deg_to_rad(deg)) * r, dy)


## Autour d'un dôme satellite.
static func PC(c: Vector2, deg: float, r: float, dy: float = 0.0) -> Vector3:
	return P(c.x + cos(deg_to_rad(deg)) * r, c.y + sin(deg_to_rad(deg)) * r, dy)


static func ang_to(a: Vector2, b: Vector2) -> float:
	return rad_to_deg(atan2(b.y - a.y, b.x - a.x))


## Le long de la ligne du Funiculaire : à la distance r du centre, décalé de lat (vers l'est-sud-est).
static func LR(r: float, lat: float, dy: float = 0.0) -> Vector3:
	var d: Vector3 = dirv(A_GARE)
	var sd: Vector3 = d.cross(Vector3.UP).normalized()
	return P(0, 0, dy) + d * r + sd * lat


## Un repère au sol en p, dont la façade (+Z) regarde vers q.
static func XL(p: Vector3, q: Vector3) -> Transform3D:
	var d := Vector3(q.x - p.x, 0, q.z - p.z)
	return Transform3D(Basis.looking_at(-d.normalized(), Vector3.UP), p)


## Un repère au sol (angle, rayon autour du Grand Dôme), façade vers le centre.
static func XR(deg: float, r: float, dy: float = 0.0) -> Transform3D:
	return XL(PR(deg, r, dy), P(0, 0, dy))


static func XC(c: Vector2, deg: float, r: float, dy: float = 0.0) -> Transform3D:
	return XL(PC(c, deg, r, dy), P(c.x, c.y, dy))


func _pt(name: String, p: Vector3) -> String:
	return hf._pt(name, p)


func _link(a: String, b: String) -> void:
	hf._link(a, b)


func _chain(names: Array) -> void:
	hf._chain(names)


func _near_pt(p: Vector3, prefix: String = "da_p_") -> String:
	var best: String = ""
	var bd: float = INF
	for k in hf.points:
		if not str(k).begins_with(prefix):
			continue
		var d: float = (hf.points[k] as Vector3).distance_to(p)
		if d < bd:
			bd = d
			best = str(k)
	return best


## Un lieu de rendez-vous (un « spot »), relié au point du réseau le plus proche.
func _sp(name: String, pos: Vector3, face_to: Vector3, pose: String) -> void:
	var f := Vector3(face_to.x - pos.x, 0, face_to.z - pos.z)
	hf._spot(name, pos + Vector3.UP * 0.05, f.normalized() if f.length() > 0.01 else Vector3.FORWARD, pose, _near_pt(pos))


func _crowd(name: String, pos: Vector3, face_to: Vector3, pose: String) -> void:
	_sp(name, pos, face_to, pose)
	crowd_spots.append(name)


## Une porte d'habitant (« porte_<prénom> ») : un point du réseau, relié au plus proche.
func _door(name: String, p: Vector3) -> void:
	var near: String = _near_pt(p)
	_pt(name, p + Vector3.UP * 0.05)
	if near != "":
		_link(name, near)
	doors[name] = p


## V119 : une maison où l'on entre (maisons_v81, style « dome ») : door, la porte (au sol, dehors, juste
## devant le seuil) ; out, la direction du dehors ; w × d, la pièce.
func _maison119(door: Vector3, out: Vector3, w: float, d: float, floors: int) -> void:
	Kit56.note_v81(door + Vector3.UP * 0.05, Vector3(out.x, 0, out.z), w, d, "dome", floors)


## V119 : une maison-bulle de rayon r : la taille de sa pièce.
static func taille_bulle119(r: float) -> Vector2:
	return Vector2(clampf(r * 1.55, 6.5, 8.5), clampf(r * 1.35, 6.0, 7.5))


## V119 : un grand lieu qu'on visite : sa porte dessinée (xf : son pied, au ras du mur ; elle regarde +Z)
## et, dans portes119, le point devant elle (au sol + 0,05, dehors) et la direction du dehors.
func _lieu119(lieu: String, xf: Transform3D, leaf: String = "titane") -> void:
	kit.door119(xf, leaf)
	var out: Vector3 = xf.basis * Vector3.BACK
	out.y = 0.0
	portes119[lieu] = [xf * Vector3(0, 0.05, 0.6), out.normalized()]


func _light(p: Vector3, c: Color, e_day: float, e_night: float, rng_m: float, shadow: bool = false) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.light_color = c
	l.light_energy = e_day
	l.omni_range = rng_m
	l.omni_attenuation = 1.1
	l.shadow_enabled = shadow
	l.distance_fade_enabled = true
	l.distance_fade_begin = 110.0
	l.distance_fade_length = 30.0
	add_child(l)
	l.global_position = p
	lights.append([l, e_day, e_night])
	return l


# =================================================================== construction

func build(main_node: Node, fosse_node: Node3D, hf_city: Node3D, high_quality: bool, surface: Node3D) -> void:
	main = main_node
	fosse = fosse_node
	hf = hf_city
	pc = high_quality
	surface_root = surface
	_rng.seed = 11510
	var t0: int = Time.get_ticks_msec()
	kit = Kit.new()
	kit.setup(self, main.get("temps_v56") if main != null else null)
	kit.main = main
	kit.pc = pc
	kit.rng.seed = 11511
	_network()
	_coques()
	_galeries()
	_funiculaire()
	_place_perle()
	_gare()
	_conque()
	_comptoir()
	_atelier()
	_ecole()
	_jardin()
	_conseil()
	_tours()
	_bulles()
	_gradins()
	_promenade()
	_belvedere()
	_serres()
	_institut()
	_rues()
	_portes()
	_jardinets()
	kit.commit()
	for ch in get_children():
		if ch is GeometryInstance3D and (str(ch.name).contains("vitre") or str(ch.name).contains("eau115") or str(ch.name).contains("algue")):
			(ch as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_lumieres()
	_flore()
	_bouee()
	set_glass(0.0)
	print("ILE_MANGA_V115: le Dôme d'Azur est bâti (%d ms, %d points)" % [Time.get_ticks_msec() - t0, hf.points.size()])


# =================================================================== le réseau des rues

const PL_R: float = 12.0
const AN_R: float = 22.0
const CO_R: float = 46.0
const PR_R: float = 64.5


static func _in_station(deg: float, r: float) -> bool:
	var l: Vector3 = F.L(PR(deg, r))
	var d: Vector3 = dirv(A_GARE)
	var sd: Vector3 = d.cross(Vector3.UP).normalized()
	var along: float = l.x * d.x + l.z * d.z
	var lat: float = l.x * sd.x + l.z * sd.z
	return along > 44.0 and lat > -5.0 and lat < 11.0


func _network() -> void:
	for k in range(12):
		_pt("da_p_pl_%d" % k, PR(30.0 * k + 15.0, PL_R))
	for k in range(12):
		_link("da_p_pl_%d" % k, "da_p_pl_%d" % ((k + 1) % 12))
	for k2 in range(16):
		_pt("da_p_an_%d" % k2, PR(22.5 * k2, AN_R))
	for k2 in range(16):
		_link("da_p_an_%d" % k2, "da_p_an_%d" % ((k2 + 1) % 16))
	for k3 in range(24):
		_pt("da_p_co_%d" % k3, PR(15.0 * k3, CO_R))
	for k3 in range(24):
		_link("da_p_co_%d" % k3, "da_p_co_%d" % ((k3 + 1) % 24))
	# la Promenade des Hublots : pas dans la gare ni derrière les Gradins
	var prs: Array = []
	for k4 in range(32):
		var a: float = 11.25 * k4
		var gr: bool = a > 126.0 and a < 174.0
		if _in_station(a, PR_R) or gr:
			prs.append("")
			continue
		prs.append(_pt("da_p_pr_%d" % k4, PR(a, PR_R)))
	for k4 in range(32):
		var a2: String = prs[k4]
		var b2: String = prs[(k4 + 1) % 32]
		if a2 != "" and b2 != "":
			_link(a2, b2)
	# les allées : de la Place à la Promenade, le long des quatre avenues et de quatre traverses
	for spec in [[A_GARE, false], [10.06, true], [100.0, true], [187.125, true], [55.0, true], [230.0, true], [-20.0, true], [150.0, false]]:
		var deg: float = spec[0]
		var names: Array = [_near_pt(PR(deg, PL_R), "da_p_pl_"), _near_pt(PR(deg, AN_R), "da_p_an_"), _near_pt(PR(deg, CO_R), "da_p_co_")]
		if bool(spec[1]):
			var npr: String = _near_pt(PR(deg, PR_R), "da_p_pr_")
			if npr != "" and (hf.points[npr] as Vector3).distance_to(PR(deg, PR_R)) < 8.0:
				names.append(npr)
		_chain(names)
	# les bouts de la Promenade, de part et d'autre de la gare et des Gradins : vers le Cours
	for k5 in range(32):
		var nm: String = prs[k5]
		if nm == "":
			continue
		if prs[(k5 + 1) % 32] == "" or prs[(k5 + 31) % 32] == "":
			_link(nm, _near_pt(PR(11.25 * k5, CO_R), "da_p_co_"))


# =================================================================== les coques (dômes, tambours, sols)

func _coques() -> void:
	var g: Vector3 = P(0, 0)
	var s: Vector3 = P(S_C.x, S_C.y)
	var i: Vector3 = P(I_C.x, I_C.y)
	var a_gs: float = ang_to(Vector2.ZERO, S_C)
	var a_gi: float = ang_to(Vector2.ZERO, I_C)
	# les sols (le puits des bathyscaphes perce celui de l'Institut)
	kit.floor_disc(g, R_G + 0.3, [])
	kit.floor_disc(s, R_SAT + 0.3, [])
	objets["bassin"] = PC(I_C, 110.0, 17.0)
	kit.floor_disc(i, R_SAT + 0.3, [[objets["bassin"], POOL_R]])
	# les socles (vus du dehors) : un anneau de béton gris sous chaque dôme
	for c in [[g, R_G], [s, R_SAT], [i, R_SAT]]:
		kit.cyl(Transform3D(Basis(), (c[0] as Vector3) + Vector3.DOWN * 1.8), float(c[1]) + 1.6, float(c[1]) + 1.2, 1.8, "nacre115_gris", 64, false, 3.0)
		kit.ring(Transform3D(Basis(), (c[0] as Vector3) + Vector3.UP * 0.0), float(c[1]) + 0.25, float(c[1]) + 1.25, 0.04, "nacre115_gris", 64)
	# les tambours et les coupoles
	kit.drum115(g, R_G, H_DRUM, [[A_GARE, 4.3], [a_gs, 3.9], [a_gi, 3.9]], "Verre_tambour_grand")
	kit.drum115(s, R_SAT, H_DRUM, [[a_gs + 180.0, 3.9]], "Verre_tambour_serres")
	kit.drum115(i, R_SAT, H_DRUM, [[a_gi + 180.0, 3.9]], "Verre_tambour_institut")
	kit.geodome(g + Vector3.UP * H_DRUM, R_G + 0.25, H_CAP_G, 12, "Verre_coupole_grand")
	kit.geodome(s + Vector3.UP * H_DRUM, R_SAT + 0.25, H_CAP_S, 6, "Verre_coupole_serres")
	kit.geodome(i + Vector3.UP * H_DRUM, R_SAT + 0.25, H_CAP_S, 6, "Verre_coupole_institut")
	# la ceinture lumineuse au pied des coupoles (dedans)
	for c2 in [[g, R_G], [s, R_SAT], [i, R_SAT]]:
		kit.ring(Transform3D(Basis(), (c2[0] as Vector3) + Vector3.UP * (H_DRUM - 0.62)), float(c2[1]) - 0.25, float(c2[1]) - 0.1, 0.06, "led115_cyan", 96 if float(c2[1]) > 40.0 else 48)


# =================================================================== les galeries

func _galeries() -> void:
	for spec in [[S_C, "serres", "da_p_gs_"], [I_C, "institut", "da_p_gi_"]]:
		var c: Vector2 = spec[0]
		var a: float = ang_to(Vector2.ZERO, c)
		var d: Vector3 = dirv(a)
		var p0: Vector3 = P(0, 0) + d * (R_G - 0.3) + Vector3.UP * GAL_AXE
		var p1: Vector3 = P(c.x, c.y) - d * (R_SAT - 0.3) + Vector3.UP * GAL_AXE
		kit.glass_tube(p0, p1, R_GAL, GAL_AXE, 4.0, "Verre_galerie_" + str(spec[1]))
		# les portails (deux colliers de titane, une enseigne au-dessus, dedans)
		for q in [[p0, d], [p1, -d]]:
			var pq: Vector3 = q[0]
			var dq: Vector3 = q[1]
			var sd: Vector3 = dq.cross(Vector3.UP).normalized()
			kit.ring(Transform3D(Basis(sd, dq, sd.cross(dq)).orthonormalized(), pq - dq * 0.45), R_GAL - 0.1, R_GAL + 0.7, 0.9, "nacre115", 32)
		var sd2: Vector3 = d.cross(Vector3.UP).normalized()
		# les montants du tambour, de chaque côté de l'ouverture (un cadre de nacre)
		for side in [-1.0, 1.0]:
			for q2 in [[P(0, 0) + d * (R_G + 0.2), 1.0], [P(c.x, c.y) - d * (R_SAT + 0.2), -1.0]]:
				var base: Vector3 = (q2[0] as Vector3) + sd2 * side * (R_GAL + 0.6)
				kit.box(Transform3D(Basis.looking_at(d, Vector3.UP), base + Vector3.UP * (H_DRUM * 0.5)), Vector3(0.8, H_DRUM, 1.2), "nacre115", 1.0)
				kit.col_box(Transform3D(Basis.looking_at(d, Vector3.UP), base + Vector3.UP * (H_DRUM * 0.5)), Vector3(0.8, H_DRUM, 1.2))
		# les enseignes, au-dessus de l'entrée, dans le Grand Dôme et dans le satellite
		kit.sign115(Transform3D(Basis.looking_at(d, Vector3.UP), P(0, 0) + d * (R_G - 1.2) + Vector3.UP * 6.4), str(spec[1]), 3.2, 1.6)
		kit.sign115(Transform3D(Basis.looking_at(-d, Vector3.UP), P(c.x, c.y) - d * (R_SAT - 1.2) + Vector3.UP * 6.4), str(spec[1]), 2.4, 1.2)
		# les points du réseau (l'entrée, le milieu, la sortie) et le banc des poissons, au milieu
		var pre: String = spec[2]
		var g0: Vector3 = P(0, 0) + d * (R_G - 3.0)
		var g2: Vector3 = P(c.x, c.y) - d * (R_SAT - 3.0)
		var gm: Vector3 = (g0 + g2) * 0.5
		_pt(pre + "0", g0)
		_pt(pre + "1", gm)
		_pt(pre + "2", g2)
		_chain([pre + "0", pre + "1", pre + "2"])
		_link(pre + "0", _near_pt(g0 - d * 4.0, "da_p_pr_"))
		var bx: Transform3D = XL(gm + sd2 * 1.25, gm + sd2 * 6.0)
		kit.bench115(bx, 2.0, "corail")
		_sp("da_galerie_" + str(spec[1]), gm - sd2 * 1.4 + d * 3.0, gm - sd2 * 6.0 + d * 3.0, "observer")
		_crowd("da_c_galerie_" + str(spec[1]), bx * Vector3(0, 0.45, 0.15), gm + sd2 * 6.0, "assis")


# =================================================================== le Funiculaire (dehors) et la gare

func _funiculaire() -> void:
	# F.tube_axis est en local (y compris) ; P(0, 0) ajoute l'origine
	var a0: Vector3 = P(0, 0) + F.tube_axis(R_G - 0.4)
	var a1: Vector3 = P(0, 0) + F.tube_axis(F.L_FLAT)
	var a2: Vector3 = P(0, 0) + F.tube_axis(F.L_PORTAL)
	kit.glass_tube(a0, a1, R_FUNI, -1.0, 4.0, "Verre_funiculaire_plat")
	kit.glass_tube(a1, a2, R_FUNI, -1.0, 5.0, "Verre_funiculaire_pente")
	var d: Vector3 = dirv(A_GARE)
	var sd: Vector3 = d.cross(Vector3.UP).normalized()
	# le coude (un gros collier) et le portail du canyon (un anneau de béton dans la falaise, ses feux)
	var ax_s: Vector3 = (a2 - a1).normalized()
	kit.ring(Transform3D(Basis(sd, d, sd.cross(d)).orthonormalized(), a1 - d * 0.5), R_FUNI - 0.05, R_FUNI + 0.6, 1.0, "nacre115", 32)
	var pb := Basis(sd, ax_s, sd.cross(ax_s)).orthonormalized()
	kit.ring(Transform3D(pb, a2 - ax_s * 1.2), R_FUNI - 0.05, R_FUNI + 2.2, 2.4, "nacre115_gris", 36)
	kit.ring(Transform3D(pb, a2 - ax_s * 1.25), R_FUNI + 1.4, R_FUNI + 1.7, 2.5, "led115_cyan", 36)
	kit.sign115(Transform3D(Basis.looking_at(d, Vector3.UP), a2 - d * 1.4 + Vector3.UP * (R_FUNI + 3.4)), "ligne", 4.0, 2.0)
	# le tunnel : un tube de titane (sombre) éclairé d'anneaux, son fond
	var t0: Vector3 = a2
	var t1: Vector3 = P(0, 0) + Vector3(d.x * F.L_END, F.AXE_HAUT, d.z * F.L_END)
	var tb := Basis(sd, d, sd.cross(d)).orthonormalized()
	var n_t: int = 18
	for k in range(n_t):
		var u0: float = TAU * k / n_t
		var u1: float = TAU * (k + 1) / n_t
		var e0: Vector3 = Vector3.UP * cos(u0) + sd * sin(u0)
		var e1: Vector3 = Vector3.UP * cos(u1) + sd * sin(u1)
		var rr: float = R_FUNI + 0.3
		kit.quad4("titane115_sombre", t0 + e0 * rr, t0 + e1 * rr, t1 + e1 * rr, t1 + e0 * rr, -(e0 + e1).normalized(), Vector2(0, 0), Vector2(1, 0), Vector2(1, 5), Vector2(0, 5))
	for k2 in range(6):
		var q: Vector3 = t0.lerp(t1, (float(k2) + 0.5) / 6.0)
		kit.ring(Transform3D(tb, q), R_FUNI + 0.05, R_FUNI + 0.3, 0.2, "led115_cyan", 24)
	kit.cyl(Transform3D(tb, t1), R_FUNI + 0.4, R_FUNI + 0.4, 0.3, "titane115_sombre", 24, true)
	# le rail du tunnel (en haut)
	kit.box(Transform3D(Basis.looking_at(d, Vector3.UP), (t0 + t1) * 0.5 + Vector3.UP * (R_FUNI - 0.45)), Vector3(0.36, 0.42, t0.distance_to(t1)), "titane115", 2.0)
	# les selles du tube plat, les pylônes du tube en pente (du fond du canyon au tube)
	for r in [74.0, 82.0, 90.0]:
		var q2: Vector3 = P(0, 0) + d * r
		kit.box(Transform3D(Basis.looking_at(d, Vector3.UP), q2 + Vector3.UP * (F.AXE_BAS - R_FUNI - 0.6)), Vector3(R_FUNI * 1.6, 1.6, 1.2), "nacre115_gris", 2.0)
	var r3: float = 100.0
	while r3 < 196.0:
		var ax3: Vector3 = F.tube_axis(r3)
		var top: Vector3 = P(0, 0) + Vector3(ax3.x, ax3.y - R_FUNI - 0.2, ax3.z)
		var fl: float = maxf(-1.4, ax3.y - R_FUNI - 7.0) - 1.5
		var foot: Vector3 = P(0, 0) + Vector3(ax3.x, fl, ax3.z)
		kit.cyl(Transform3D(Basis(), foot), 0.9, 0.55, top.y - foot.y - 1.6, "nacre115", 12, false, 2.0)
		var fork: Vector3 = top + Vector3.DOWN * 1.6
		for s in [-1.0, 1.0]:
			kit.rod(fork, top + sd * s * (R_FUNI * 0.75) + Vector3.UP * 0.9, 0.3, 0.22, "nacre115", 8)
		kit.box(Transform3D(Basis.looking_at(d, Vector3.UP), fork + Vector3.UP * 0.5), Vector3(1.0, 1.0, 1.0), "titane115_sombre", 1.0)
		kit.cyl(Transform3D(Basis(), foot + Vector3.DOWN * 0.4), 2.0, 1.6, 0.9, "nacre115_gris", 12, true, 2.0)
		r3 += 16.0
	objets["portail"] = a2


func _gare() -> void:
	var d: Vector3 = dirv(A_GARE)
	var sd: Vector3 = d.cross(Vector3.UP).normalized()
	var bd := Basis.looking_at(d, Vector3.UP)            # +Z local : vers le centre (le long de la ligne, vers dedans)
	var bs := Basis.looking_at(-sd, Vector3.UP)          # +Z local : vers le quai (côté est-sud-est)
	var plat_h: float = 1.0
	# le quai (de r = 55,5 à 69,6 ; de 1,65 à 6,6 de côté)
	var r0: float = 55.5
	var r1: float = 69.6
	var l0: float = 1.65
	var l1: float = 6.6
	var pc_q: Vector3 = LR((r0 + r1) * 0.5, (l0 + l1) * 0.5)
	kit.box(Transform3D(bd, pc_q + Vector3.UP * (plat_h * 0.5)), Vector3(l1 - l0, plat_h, r1 - r0), "nacre115_gris", 2.0, 63 - 4)
	kit.box(Transform3D(bd, pc_q + Vector3.UP * (plat_h - 0.03)), Vector3(l1 - l0, 0.06, r1 - r0), "terrazzo115", 3.0, 4)
	kit.box(Transform3D(bd, LR((r0 + r1) * 0.5, l0 + 0.25, plat_h + 0.01)), Vector3(0.3, 0.02, r1 - r0), "led115_ambre", 1.0, 4)
	kit.col_box(Transform3D(bd, pc_q + Vector3.UP * (plat_h * 0.5)), Vector3(l1 - l0, plat_h, r1 - r0))
	# la rampe (du sol au quai, vers le centre)
	var ra: Vector3 = LR(r0, 4.6, plat_h)
	var rb: Vector3 = LR(r0 - 6.5, 4.6, 0.0)
	var rmid: Vector3 = (ra + rb) * 0.5
	var slope: float = atan2(plat_h, ra.distance_to(Vector3(rb.x, ra.y, rb.z)))
	var rbasis := bd * Basis(Vector3.RIGHT, slope)
	kit.box(Transform3D(rbasis, rmid + Vector3.DOWN * 0.08), Vector3(3.6, 0.2, 6.6), "terrazzo115", 2.0)
	kit.col_box(Transform3D(rbasis, rmid + Vector3.DOWN * 0.12), Vector3(3.6, 0.24, 6.6))
	for s in [-1.0, 1.0]:
		kit.glass_rail113(LR(r0 - 6.4, 4.6 + s * 1.8, 0.0), LR(r0, 4.6 + s * 1.8, plat_h), 1.0, true)
	# les portes palières (le verre le long du quai ; l'ouverture au milieu : dome_ligne_v115 y met ses
	# portes qui coulissent) ; le garde-corps de l'autre côté de la voie, et au bout
	var stop: float = 63.5
	for seg in [[r0 + 0.3, stop - 1.0], [stop + 1.0, r1 - 0.2]]:
		var pa: Vector3 = LR(float(seg[0]), l0, plat_h)
		var pb2: Vector3 = LR(float(seg[1]), l0, plat_h)
		kit.box(Transform3D(bd, (pa + pb2) * 0.5 + Vector3.UP * 1.1), Vector3(0.06, 2.2, pa.distance_to(pb2)), "vitre115", 1.0)
		kit.box(Transform3D(bd, (pa + pb2) * 0.5 + Vector3.UP * 2.25), Vector3(0.14, 0.12, pa.distance_to(pb2)), "titane115_clair", 1.0)
		kit.col_box(Transform3D(bd, (pa + pb2) * 0.5 + Vector3.UP * 1.1), Vector3(0.12, 2.2, pa.distance_to(pb2)))
	kit.box(Transform3D(bd, LR(stop, l0, plat_h + 2.5)), Vector3(0.2, 0.5, 2.4), "titane115_clair", 1.0)
	kit.glass_rail113(LR(r0 - 0.5, -2.0, 0.0), LR(R_G - 0.4, -2.0, 0.0), 1.2, true)
	kit.glass_rail113(LR(r0 - 0.5, -2.0, 0.0), LR(r0 - 0.5, l0, 0.0), 1.2, true)
	objets["quai_porte"] = LR(stop, l0, plat_h)
	# les portiques du rail (au-dessus de la voie) et le rail lui-même, jusqu'au butoir
	var rail_y: float = F.AXE_BAS + R_FUNI - 0.45
	for r in [57.0, 62.5, 68.0]:
		var c0: Vector3 = LR(r, -2.8)
		var c1: Vector3 = LR(r, 7.4)
		for cp in [c0, c1]:
			kit.cyl(Transform3D(Basis(), cp), 0.22, 0.18, rail_y + 0.9, "titane115_clair", 10, false)
			kit.col_cyl(cp, 0.24, rail_y + 0.9)
		kit.box(Transform3D(bd, (c0 + c1) * 0.5 + Vector3.UP * (rail_y + 0.75)), Vector3(c0.distance_to(c1) + 0.4, 0.4, 0.4), "titane115_clair", 1.0)
	kit.box(Transform3D(bd, LR((56.0 + R_G) * 0.5, 0.0, rail_y)), Vector3(0.36, 0.42, R_G - 56.0), "titane115", 2.0)
	kit.box(Transform3D(bd, LR(56.3, 0.0, rail_y - 0.1)), Vector3(0.8, 0.8, 0.6), "jaune115", 1.0)
	# la marquise : une voûte de nacre sur ses portiques, un liseré de diodes
	var vy: float = rail_y + 1.0
	var n_v: int = 8
	for k in range(n_v):
		var t0: float = float(k) / n_v
		var t1: float = float(k + 1) / n_v
		var la: float = lerpf(-3.4, 8.0, t0)
		var lb: float = lerpf(-3.4, 8.0, t1)
		var ya: float = vy + sin(t0 * PI) * 1.1
		var yb: float = vy + sin(t1 * PI) * 1.1
		var qa: Vector3 = LR(54.0, la, ya)
		var qb: Vector3 = LR(54.0, lb, yb)
		var qc: Vector3 = LR(R_G - 0.6, lb, yb)
		var qd: Vector3 = LR(R_G - 0.6, la, ya)
		var nn: Vector3 = (qb - qa).cross(qd - qa).normalized()
		if nn.y < 0.0:
			nn = -nn
		kit.quad4("nacre115", qa, qb, qc, qd, nn, Vector2(0, 0), Vector2(1, 0), Vector2(1, 4), Vector2(0, 4))
		kit.quad4("nacre115", qa + Vector3.DOWN * 0.15, qb + Vector3.DOWN * 0.15, qc + Vector3.DOWN * 0.15, qd + Vector3.DOWN * 0.15, -nn, Vector2(0, 0), Vector2(1, 0), Vector2(1, 4), Vector2(0, 4))
	kit.box(Transform3D(bd, LR(54.0, 2.3, vy + 0.7)), Vector3(11.6, 0.08, 0.1), "led115_cyan", 1.0)
	kit.sign115(Transform3D(bd, LR(53.8, 2.3, vy + 1.9)), "gare", 4.4, 2.2)
	kit.sign115(Transform3D(bd, LR(R_G - 1.0, 0.0, F.AXE_BAS + R_FUNI + 1.6)), "ligne", 3.2, 1.6)
	# le pupitre (au bout du quai), le guichet (au pied de la rampe), les bancs
	var px: Transform3D = Transform3D(bs, LR(68.6, 4.6, plat_h))
	kit.box(px * kit.T(0, 0.55, 0), Vector3(1.6, 1.1, 0.7), "nacre115", 1.0)
	kit.box(Transform3D(px.basis * Basis(Vector3.RIGHT, -0.5), px * Vector3(0, 1.15, 0.05)), Vector3(1.5, 0.05, 0.6), "ecran115", 1.0)
	kit.col_box(px * kit.T(0, 0.55, 0), Vector3(1.6, 1.1, 0.7))
	_sp("da_gare_pupitre", px * Vector3(0, 0, 0.75), px * Vector3(0, 0, -2.0), "comptoir")
	var gx: Transform3D = XL(LR(50.5, 10.0), LR(50.5, 4.0))
	kit.box(gx * kit.T(0, 0.55, 0), Vector3(2.8, 1.1, 0.8), "nacre115", 1.0)
	kit.box(gx * kit.T(0, 1.13, 0.05), Vector3(3.0, 0.06, 1.0), "titane115_clair", 1.0)
	kit.box(gx * kit.T(0, 2.1, -0.3), Vector3(1.6, 0.9, 0.06), "ecran115", 1.0)
	kit.cyl(Transform3D(Basis(), gx * Vector3(0, 0, -0.9)), 1.9, 1.9, 0.05, "terrazzo115_bleu", 24, true)
	kit.col_box(gx * kit.T(0, 0.55, 0), Vector3(2.8, 1.1, 0.8))
	_sp("da_gare_guichet", gx * Vector3(0, 0, -0.75), gx * Vector3(0, 0, 3.0), "comptoir")
	## V119 : le poste du chef de gare : une petite cabine de nacre juste derrière le guichet (un hublot
	## sur le côté, un toit de titane, un liseré de diodes) ; sa porte au bout, vers le Cours (da_gare)
	var cbx := Transform3D(bd, LR(50.5, 13.3))          # +Z : vers le centre ; +X : vers le dehors du guichet
	kit.box(cbx * kit.T(0, 1.5, 0), Vector3(2.4, 3.0, 3.4), "nacre115", 1.5)
	kit.box(cbx * kit.T(0, 3.07, 0), Vector3(2.7, 0.14, 3.7), "titane115_clair", 1.0)
	kit.box(cbx * kit.T(0, 2.95, 0), Vector3(2.44, 0.06, 3.44), "led115_cyan", 1.0, 1 | 2 | 16 | 32)
	kit.col_box(cbx * kit.T(0, 1.5, 0), Vector3(2.4, 3.0, 3.4))
	kit.porthole115(Transform3D(kit._basis_up(sd), cbx * Vector3(1.21, 1.7, 0)), 0.45)
	_lieu119("da_gare", cbx * Transform3D(Basis(), Vector3(0, 0, 1.7)), "titane")
	for k2 in range(2):
		var bp: Vector3 = LR(57.8 + k2 * 2.6, 6.0, plat_h)
		var bx: Transform3D = XL(bp, bp - sd * 3.0)
		kit.bench115(bx, 2.2, "")
		_sp("da_gare_banc_%d" % (k2 + 1), bx * Vector3(0, 0.45, 0.15), bx * Vector3(0, 0, 3.0), "assis")
	_sp("da_gare_quai", LR(stop + 1.6, 3.6, plat_h), LR(stop + 1.6, 0.0, plat_h), "debout")
	_crowd("da_c_gare", LR(65.6, 5.2, plat_h), LR(65.6, 0.0, plat_h), "debout")
	# les points : la rampe, le haut, le quai, le bout ; le guichet
	_pt("da_p_ga_0", LR(48.0, 4.6))
	_pt("da_p_ga_1", LR(r0 + 0.4, 4.6, plat_h))
	_pt("da_p_ga_2", LR(stop, 4.0, plat_h))
	_pt("da_p_ga_3", LR(67.8, 4.0, plat_h))
	_pt("da_p_ga_cab", LR(stop, 0.0, plat_h))
	_chain(["da_p_ga_0", "da_p_ga_1", "da_p_ga_2", "da_p_ga_3"])
	_link("da_p_ga_2", "da_p_ga_cab")
	_link("da_p_ga_0", _near_pt(LR(46.0, 4.0), "da_p_co_"))
	_link("da_p_ga_0", _near_pt(LR(40.0, 0.0), "da_p_an_"))
	_link("da_p_ga_0", _near_pt(LR(46.0, 10.0), "da_p_co_"))
	objets["gare"] = LR(60.0, 4.0, plat_h)
	objets["guichet"] = gx.origin
	## V119 : le repère du quai (au milieu du quai, à sa hauteur ; +X le long de la voie vers le fond, +Z
	## vers les bancs, loin de la voie)
	cadres119["gare"] = Transform3D(bs, LR(62.5, 4.0, plat_h))
	# le totem, au départ de l'avenue
	kit.totem115(PR(A_GARE - 9.0, 19.0), deg_to_rad(-A_GARE + 90.0), "gare")


# =================================================================== la Place de la Perle

func _place_perle() -> void:
	var c: Vector3 = P(0, 0)
	# le sol : un grand cercle de terrazzo bleuté, des anneaux de laiton et de diodes
	kit.cyl(Transform3D(Basis(), c + Vector3.UP * 0.01), 17.0, 17.0, 0.02, "terrazzo115_bleu", 64, true, 4.0)
	kit.ring(Transform3D(Basis(), c + Vector3.UP * 0.02), 16.8, 17.3, 0.03, "titane115_clair", 64)
	kit.ring(Transform3D(Basis(), c + Vector3.UP * 0.02), 12.6, 12.8, 0.03, "led115_cyan", 64)
	# la spirale de nacre (une conque dessinée au sol)
	for k in range(90):
		var t: float = float(k) / 90.0
		var a: float = t * TAU * 1.6
		var rr: float = 7.4 + t * 9.0
		var p0: Vector3 = c + Vector3(cos(a), 0, sin(a)) * rr
		var a1: float = (float(k) + 1.0) / 90.0 * TAU * 1.6
		var p1: Vector3 = c + Vector3(cos(a1), 0, sin(a1)) * (7.4 + (float(k) + 1.0) / 90.0 * 9.0)
		kit.box(Transform3D(Basis.looking_at(p1 - p0, Vector3.UP), (p0 + p1) * 0.5 + Vector3.UP * 0.03), Vector3(0.3, 0.02, p0.distance_to(p1) + 0.02), "nacre115", 1.0, 4)
	# la Fontaine des Bulles : le bassin, l'eau qui luit, le grand cylindre de verre, les bulles
	kit.ring(Transform3D(Basis(), c), 6.2, 6.9, 0.6, "nacre115", 48)
	kit.ring(Transform3D(Basis(), c + Vector3.UP * 0.6), 6.15, 6.95, 0.06, "titane115_clair", 48)
	kit.disc(Transform3D(Basis(), c + Vector3.UP * 0.05), 6.2, "titane115_sombre", 32, 2.0)
	var wm := MeshInstance3D.new()
	wm.name = "Eau_fontaine"
	var cm := CylinderMesh.new()
	cm.top_radius = 6.2
	cm.bottom_radius = 6.2
	cm.height = 0.04
	cm.radial_segments = 48
	wm.mesh = cm
	wm.material_override = kit.mat("eau115")
	add_child(wm)
	wm.global_position = c + Vector3.UP * 0.45
	for k2 in range(24):
		var a0: float = TAU * k2 / 24.0
		var a1b: float = TAU * (k2 + 1) / 24.0
		var q0: Vector3 = c + Vector3(cos(a0), 0, sin(a0)) * 6.55
		var q1: Vector3 = c + Vector3(cos(a1b), 0, sin(a1b)) * 6.55
		kit.col_box(Transform3D(Basis.looking_at(q1 - q0, Vector3.UP), (q0 + q1) * 0.5 + Vector3.UP * 0.3), Vector3(0.7, 0.6, q0.distance_to(q1) + 0.05))
	var colw: float = 9.0
	var water := MeshInstance3D.new()
	water.name = "Eau_colonne"
	var cw := CylinderMesh.new()
	cw.top_radius = 3.3
	cw.bottom_radius = 3.3
	cw.height = colw - 0.4
	cw.radial_segments = 40
	water.mesh = cw
	water.material_override = kit.mat("eau115")
	add_child(water)
	water.global_position = c + Vector3.UP * (0.5 + (colw - 0.4) * 0.5)
	kit.cyl(Transform3D(Basis(), c + Vector3.UP * 0.4), 3.45, 3.45, colw, "vitre115", 40, false)
	kit.cyl(Transform3D(Basis(), c + Vector3.UP * 0.2), 3.7, 3.7, 0.5, "titane115_clair", 40, true)
	kit.cyl(Transform3D(Basis(), c + Vector3.UP * (colw + 0.3)), 3.8, 3.5, 0.6, "nacre115", 40, true)
	kit.ring(Transform3D(Basis(), c + Vector3.UP * (colw + 0.35)), 3.8, 3.86, 0.4, "led115_cyan", 40)
	kit.col_cyl(c, 3.7, colw + 1.0)
	bubbles.append(_bubbles_fx(c + Vector3.UP * 0.6, 3.0, colw - 1.0, 120 if pc else 50))
	# la Cheminée d'Air : du sol jusqu'en haut de la coupole, et dehors jusqu'à la surface
	var col := MeshInstance3D.new()
	col.name = "Cheminee_d_air"
	var cc := CylinderMesh.new()
	cc.top_radius = 2.05
	cc.bottom_radius = 2.2
	cc.height = COL_SPLIT - 0.5
	cc.radial_segments = 32
	col.mesh = cc
	col.material_override = kit.mat("nacre115")
	col.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(col)
	col.global_position = c + Vector3.UP * (0.5 + (COL_SPLIT - 0.5) * 0.5)
	for k3 in range(int((H_DRUM + H_CAP_G) / 4.0)):
		var y: float = colw + 2.0 + k3 * 4.0
		if absf(y - PERLE_Y) < 6.5 or y > H_DRUM + H_CAP_G - 1.0:
			continue
		kit.ring(Transform3D(Basis(), c + Vector3.UP * y), 2.15, 2.4, 0.18, "led115_cyan", 32)
	kit.ring(Transform3D(Basis(), c + Vector3.UP * (H_DRUM + H_CAP_G - 0.6)), 2.0, 3.6, 0.8, "titane115_clair", 32)
	# la Grande Perle, enfilée sur la Cheminée
	perle = Node3D.new()
	perle.name = "Grande_Perle"
	add_child(perle)
	perle.global_position = c + Vector3.UP * PERLE_Y
	var pm := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 4.8
	sm.height = 9.6
	sm.radial_segments = 48
	sm.rings = 24
	pm.mesh = sm
	pm.material_override = kit.mat("perle115")
	pm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	perle.add_child(pm)
	for s in [-1.0, 1.0]:
		kit.ring(Transform3D(Basis(), c + Vector3.UP * (PERLE_Y + s * 4.65 - 0.2)), 2.0, 2.9, 0.4, "titane115_clair", 32)
	perle_light = OmniLight3D.new()
	perle_light.name = "Lumiere_de_la_Perle"
	perle_light.light_color = Color(1.0, 0.95, 0.86)
	perle_light.light_energy = 6.5
	perle_light.omni_range = 130.0
	perle_light.omni_attenuation = 0.6
	perle_light.shadow_enabled = pc
	perle_light.shadow_bias = 0.08
	add_child(perle_light)
	perle_light.global_position = c + Vector3.UP * PERLE_Y
	objets["perle"] = c + Vector3.UP * PERLE_Y
	objets["fontaine"] = c
	## V119 : la guérite des Souffleries : le pied de la Cheminée est dans la Fontaine (pas de socle où
	## mettre une porte) ; une petite guérite de titane, adossée au bassin (vers le sud-est, là où il n'y
	## a ni banc ni allée), reliée à la colonne par une conduite au-dessus de l'eau ; sa porte regarde
	## dehors (da_souffleries)
	var ga: float = 95.0
	var gw: Transform3D = XL(PR(ga, 7.75), PR(ga, 20.0))
	kit.box(gw * kit.T(0, 1.5, 0), Vector3(2.2, 3.0, 1.5), "titane119", 1.5)
	kit.box(gw * kit.T(0, 3.07, 0), Vector3(2.5, 0.14, 1.8), "nacre115", 1.0)
	kit.box(gw * kit.T(0, 2.95, 0), Vector3(2.24, 0.06, 1.54), "led115_cyan", 1.0, 1 | 2 | 16 | 32)
	for s in [-1.0, 1.0]:
		kit.box(gw * kit.T(s * 1.12, 1.5, 0), Vector3(0.08, 3.0, 1.56), "titane115_sombre", 1.0, 1 | 2)
	kit.col_box(gw * kit.T(0, 1.5, 0), Vector3(2.2, 3.0, 1.5))
	var dk_a: Vector3 = gw * Vector3(0, 2.4, -0.75)
	var dk_b: Vector3 = PR(ga, 3.5, 2.4)
	kit.rod(dk_a, dk_b, 0.34, 0.34, "titane115", 12)
	for q in [dk_a.lerp(dk_b, 0.08), dk_a.lerp(dk_b, 0.92)]:
		kit.ring(Transform3D(Basis(dirv(ga).cross(Vector3.UP), dirv(ga), Vector3.UP).orthonormalized(), q), 0.33, 0.44, 0.14, "led115_cyan", 16)
	_lieu119("da_souffleries", gw * Transform3D(Basis(), Vector3(0, 0, 0.75)), "titane")
	## V119 : les repères de la Place et de la Fontaine : le centre (le pied de la Cheminée), au sol ;
	## +X vers l'est, +Z vers le sud (les angles de PR)
	cadres119["place"] = Transform3D(Basis(), c)
	cadres119["fontaine"] = Transform3D(Basis(), c)
	# les bancs autour de la Place, les spots
	var bench_a: Array = [-30.0, 40.0, 130.0, 160.0, 220.0, 255.0]
	for k4 in range(bench_a.size()):
		var bx: Transform3D = XR(float(bench_a[k4]), 10.4)
		kit.bench115(bx * Transform3D(Basis(Vector3.UP, PI), Vector3.ZERO), 2.6, ["", "corail", "sable", ""][k4 % 4])
		var bxx: Transform3D = bx * Transform3D(Basis(Vector3.UP, PI), Vector3.ZERO)
		if k4 < 4:
			_sp("da_place_banc_%d" % (k4 + 1), bxx * Vector3(0, 0.45, 0.15), c, "assis")
		else:
			_crowd("da_c_place_banc_%d" % k4, bxx * Vector3(0, 0.45, 0.15), c, "assis")
	_sp("da_fontaine", PR(-85.0, 7.6), c, "observer")
	var pl_a: Array = [-5.0, 70.0, 115.0, 175.0, 200.0, 285.0]
	for k5 in range(6):
		var pp: Vector3 = PR(float(pl_a[k5]), 14.5)
		_sp("da_place_%d" % (k5 + 1), pp, pp + (PR(float(pl_a[k5]) + 90.0, 14.5) - pp), "debout")
	for k6 in range(3):
		var pp2: Vector3 = PR(25.0 + 120.0 * k6, 15.5)
		_crowd("da_c_place_%d" % k6, pp2, c, "debout")
	# les lampadaires de la Place
	for k7 in range(8):
		kit.lamp115(PR(22.5 + 45.0 * k7, 17.6), deg_to_rad(-(22.5 + 45.0 * k7) - 90.0), 5.0, "cyan", k7 % 2 == 0)


## Des bulles qui montent (un cylindre de rayon r, haut de h, à partir de base).
func _bubbles_fx(base: Vector3, r: float, h: float, n: int) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.name = "Bulles"
	p.amount = n * 2
	p.lifetime = h / 1.6
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	p.emission_ring_axis = Vector3.UP
	p.emission_ring_height = 0.2
	p.emission_ring_radius = r * 0.9
	p.emission_ring_inner_radius = 0.2
	p.direction = Vector3.UP
	p.spread = 4.0
	p.gravity = Vector3(0, 0.3, 0)
	p.initial_velocity_min = 1.0
	p.initial_velocity_max = 1.9
	p.scale_amount_min = 0.035
	p.scale_amount_max = 0.12
	var grad := Gradient.new()
	grad.set_color(0, Color(0.8, 0.97, 1.0, 0.0))
	grad.add_point(0.1, Color(0.8, 0.97, 1.0, 0.8))
	grad.set_color(grad.get_point_count() - 1, Color(0.8, 0.97, 1.0, 0.0))
	p.color_ramp = grad
	var qm := QuadMesh.new()
	qm.size = Vector2(1, 1)
	qm.material = kit.mat("bulle115")
	p.mesh = qm
	p.visibility_aabb = AABB(Vector3(-r - 1, -1, -r - 1), Vector3(r * 2 + 2, h + 2, r * 2 + 2))
	add_child(p)
	p.global_position = base
	return p


# =================================================================== les lieux du Grand Dôme

func _conque() -> void:
	var a: float = -40.0
	var xf: Transform3D = XR(a, 33.0)
	var c: Vector3 = xf.origin
	objets["conque"] = c
	# le plancher, les colonnes (pas devant), le mur du fond (une demi-coquille)
	kit.cyl(Transform3D(Basis(), c), 8.4, 8.4, 0.3, "terrazzo115", 40, true, 3.0)
	kit.col_cyl(c, 8.4, 0.3)
	var fwd: Vector3 = xf.basis * Vector3.BACK
	for k in range(10):
		var aa: float = TAU * k / 10.0
		var dd := Vector3(cos(aa), 0, sin(aa))
		if dd.dot(fwd) > 0.55:
			continue
		var p: Vector3 = c + dd * 7.6
		kit.cyl(Transform3D(Basis(), p + Vector3.UP * 0.3), 0.26, 0.2, 4.2, "titane115_clair", 10, false)
		kit.col_cyl(p, 0.28, 4.5)
	for k2 in range(14):
		var a0: float = TAU * k2 / 14.0
		var a1: float = TAU * (k2 + 1) / 14.0
		var dm := Vector3(cos((a0 + a1) * 0.5), 0, sin((a0 + a1) * 0.5))
		if dm.dot(fwd) > -0.35:
			continue
		var q0: Vector3 = c + Vector3(cos(a0), 0, sin(a0)) * 8.0
		var q1: Vector3 = c + Vector3(cos(a1), 0, sin(a1)) * 8.0
		kit.quad4("nacre115_rose", q0 + Vector3.UP * 0.3, q1 + Vector3.UP * 0.3, q1 + Vector3.UP * 4.5, q0 + Vector3.UP * 4.5, -dm, Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0))
		kit.quad4("nacre115_rose", q0 + Vector3.UP * 0.3 + dm * 0.3, q1 + Vector3.UP * 0.3 + dm * 0.3, q1 + Vector3.UP * 4.5 + dm * 0.3, q0 + Vector3.UP * 4.5 + dm * 0.3, dm, Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0))
		kit.col_box(Transform3D(Basis.looking_at(q1 - q0, Vector3.UP), (q0 + q1) * 0.5 + dm * 0.15 + Vector3.UP * 2.4), Vector3(0.4, 4.2, q0.distance_to(q1) + 0.1))
	# le toit : une conque qui s'enroule (des anneaux de nacre rose qui montent en spirale)
	var n: int = 12
	for k3 in range(n):
		var t: float = float(k3) / n
		var rr: float = lerpf(8.6, 0.6, pow(t, 0.8))
		var r2: float = lerpf(8.6, 0.6, pow(t + 1.0 / n, 0.8))
		var aa2: float = t * TAU * 1.4
		var off := Vector3(cos(aa2), 0, sin(aa2)) * (2.2 * (1.0 - t))
		var y: float = 4.5 + t * 8.5
		kit.cyl(Transform3D(Basis(Vector3.UP, aa2), c + off + Vector3.UP * y), rr, r2, 8.5 / n + 0.06, "nacre115_rose", 32, k3 == 0 or k3 == n - 1, 2.0)
		kit.ring(Transform3D(Basis(Vector3.UP, aa2), c + off + Vector3.UP * (y - 0.04)), rr - 0.1, rr + 0.12, 0.1, "nacre115", 32)
	kit.ring(Transform3D(Basis(), c + Vector3.UP * 4.46), 8.4, 8.6, 0.1, "led115_ambre", 40)
	# le comptoir (un arc), la cuisine (au fond), des suspensions
	var cx: Transform3D = xf * Transform3D(Basis(), Vector3(0, 0.3, -1.5))
	for k4 in range(7):
		var u: float = -1.2 + k4 * 0.4
		var p4: Vector3 = cx * Vector3(sin(u) * 3.6, 0, -cos(u) * 3.6 + 3.6)
		kit.box(Transform3D(Basis(Vector3.UP, -u) * xf.basis, p4 + Vector3.UP * 0.55), Vector3(1.5, 1.1, 0.6), "nacre115", 1.0)
		kit.box(Transform3D(Basis(Vector3.UP, -u) * xf.basis, p4 + Vector3.UP * 1.13), Vector3(1.6, 0.06, 0.8), "titane115_clair", 1.0)
	kit.col_box(cx * kit.T(0, 0.55, 0.3), Vector3(5.6, 1.1, 1.0))
	var kx: Transform3D = xf * Transform3D(Basis(), Vector3(0, 0.3, -5.6))
	kit.box(kx * kit.T(0, 0.5, 0), Vector3(4.6, 1.0, 1.0), "titane115", 1.0)
	kit.box(kx * kit.T(0, 1.02, 0), Vector3(4.6, 0.05, 1.0), "titane115_sombre", 1.0)
	for k5 in range(3):
		kit.cyl(kx * kit.T(-1.4 + k5 * 1.4, 1.05, 0), 0.28, 0.28, 0.35, "titane115_clair", 12, true)
	kit.col_box(kx * kit.T(0, 0.5, 0), Vector3(4.6, 1.0, 1.0))
	for k6 in range(3):
		var lp: Vector3 = xf * Vector3(-2.0 + k6 * 2.0, 3.8, -1.0)
		kit.ball(Transform3D(Basis(), lp), 0.3, "led115_ambre", 10, 6)
		kit.cyl(Transform3D(Basis(), lp), 0.01, 0.01, 0.8, "titane115_sombre", 4, false)
	_sp("da_conque_comptoir", cx * Vector3(0, 0, -0.6), cx * Vector3(0, 0, 4.0), "comptoir")
	_sp("da_conque_cuisine", kx * Vector3(0, 0, 0.9), kx * Vector3(0, 0, -2.0), "cuisiner")
	# la terrasse (devant, vers la Place) : quatre tables rondes et leurs tabourets
	for k7 in range(4):
		var tp: Vector3 = xf * Vector3(-4.5 + k7 * 3.0, 0.0, 10.5 + (k7 % 2) * 1.6)
		kit.cyl(Transform3D(Basis(), tp), 0.12, 0.08, 0.72, "titane115_clair", 8, false)
		kit.cyl(Transform3D(Basis(), tp + Vector3.UP * 0.72), 0.7, 0.7, 0.05, "nacre115", 20, true)
		kit.col_cyl(tp, 0.7, 0.78)
		var sp: Vector3 = tp + xf.basis * Vector3(0, 0, 1.0)
		kit.cyl(Transform3D(Basis(), sp), 0.22, 0.2, 0.45, "nacre115_bleu", 12, true)
		_sp("da_conque_table_%d" % (k7 + 1), sp + Vector3.UP * 0.4, tp, "assis")
		if k7 % 2 == 0:
			var sp2: Vector3 = tp - xf.basis * Vector3(0, 0, 1.0)
			kit.cyl(Transform3D(Basis(), sp2), 0.22, 0.2, 0.45, "nacre115_bleu", 12, true)
			_crowd("da_c_conque_%d" % k7, sp2 + Vector3.UP * 0.4, tp, "assis")
	kit.totem115(xf * Vector3(6.5, 0, 9.0), atan2((xf.basis * Vector3.BACK).x, (xf.basis * Vector3.BACK).z), "conque")
	## V119 : le repère de la terrasse (son milieu, au sol, devant la Conque ; +Z vers la Place)
	cadres119["conque"] = Transform3D(xf.basis, xf * Vector3(0, 0, 11.0))
	kit.glows115.append([xf * Vector3(0, 3.6, -1.0), Color(1.0, 0.8, 0.55), 2.2, 12.0])


func _comptoir() -> void:
	var xf: Transform3D = XR(34.0, 33.0)
	var c: Vector3 = xf.origin
	objets["comptoir"] = c
	kit.cyl(Transform3D(Basis(), c), 7.0, 7.0, 0.25, "terrazzo115", 40, true, 3.0)
	kit.col_cyl(c, 7.0, 0.25)
	for k in range(10):
		var a: float = TAU * k / 10.0 + 0.31
		var p: Vector3 = c + Vector3(cos(a), 0, sin(a)) * 6.4
		kit.cyl(Transform3D(Basis(), p + Vector3.UP * 0.25), 0.22, 0.18, 4.2, "titane115_clair", 10, false)
		kit.col_cyl(p, 0.24, 4.5)
	kit.cyl(Transform3D(Basis(), c + Vector3.UP * 4.4), 7.1, 7.1, 0.4, "nacre115", 40, true, 2.0)
	kit.dome76(Transform3D(Basis(), c + Vector3.UP * 4.8), 7.1, 3.0, "nacre115_bleu", 40, 10)
	kit.ring(Transform3D(Basis(), c + Vector3.UP * 4.38), 7.05, 7.2, 0.08, "led115_cyan", 40)
	# le comptoir rond (ouvert vers la Place), les étagères, les coquillages, les bocaux
	var fwd: Vector3 = xf.basis * Vector3.BACK
	for k2 in range(12):
		var a2: float = TAU * k2 / 12.0
		var dd := Vector3(cos(a2), 0, sin(a2))
		if dd.dot(fwd) > 0.8:
			continue
		var p2: Vector3 = c + dd * 3.4
		kit.box(Transform3D(Basis.looking_at(dd, Vector3.UP), p2 + Vector3.UP * 0.75), Vector3(1.7, 1.0, 0.5), "nacre115", 1.0)
		kit.box(Transform3D(Basis.looking_at(dd, Vector3.UP), p2 + Vector3.UP * 1.27), Vector3(1.8, 0.05, 0.6), "titane115_clair", 1.0)
		kit.col_box(Transform3D(Basis.looking_at(dd, Vector3.UP), p2 + Vector3.UP * 0.75), Vector3(1.7, 1.0, 0.5))
		if k2 % 2 == 0:
			var cols: Array = ["corail115_rose", "corail115_orange", "nacre115_bleu", "corail115_jaune"]
			for k3 in range(3):
				kit.ball(Transform3D(Basis(), p2 + Vector3.UP * 1.38 + dd.cross(Vector3.UP) * (-0.5 + k3 * 0.5)), 0.12, cols[(k2 + k3) % cols.size()], 8, 4)
	var sx: Transform3D = xf * Transform3D(Basis(), Vector3(0, 0.25, -5.4))
	for k4 in range(3):
		kit.box(sx * kit.T(0, 0.5 + k4 * 0.6, 0), Vector3(3.6, 0.05, 0.6), "titane115_clair", 1.0)
		for k5 in range(6):
			kit.cyl(sx * kit.T(-1.5 + k5 * 0.6, 0.53 + k4 * 0.6, 0), 0.12, 0.1, 0.3, ["vitre115", "jaune115", "nacre115_rose"][(k4 + k5) % 3], 8, true)
	kit.box(sx * kit.T(0, 1.0, -0.32), Vector3(3.8, 2.0, 0.05), "nacre115_sable", 1.0)
	kit.col_box(sx * kit.T(0, 1.0, 0), Vector3(3.8, 2.0, 0.7))
	_sp("da_comptoir", c + fwd * 1.6, c + fwd * 6.0, "comptoir")
	_sp("da_comptoir_reserve", sx * Vector3(0, 0, 0.9), sx * Vector3(0, 0, -2.0), "bricoler")
	## V119 : la réserve : une cloison de nacre sable, plus haute, contre le dos des étagères ; sa porte
	## de l'autre côté, vers le fond du Comptoir (dehors, entre deux colonnes) (da_reserve)
	kit.box(sx * kit.T(0, 1.55, -0.45), Vector3(3.9, 3.1, 0.14), "nacre115_sable", 1.5)
	kit.box(sx * kit.T(0, 3.12, -0.45), Vector3(3.96, 0.05, 0.18), "led115_cyan", 1.0)
	kit.col_box(sx * kit.T(0, 1.55, -0.45), Vector3(3.9, 3.1, 0.14))
	_lieu119("da_reserve", sx * Transform3D(Basis(Vector3.UP, PI), Vector3(0, 0, -0.52)), "titane")
	## V119 : le repère du Comptoir (le centre du pavillon, au sol ; son plancher est à +0,25 ; +Z vers la Place)
	cadres119["comptoir"] = xf
	kit.totem115(c + fwd * 8.4 + (fwd.cross(Vector3.UP)) * 3.0, atan2(fwd.x, fwd.z), "comptoir")
	kit.glows115.append([c + Vector3.UP * 3.8, Color(0.85, 0.95, 1.0), 1.6, 10.0])


func _atelier() -> void:
	var xf: Transform3D = XR(72.0, 33.5)
	var c: Vector3 = xf.origin
	objets["atelier"] = c
	var w: float = 12.0
	var dpt: float = 10.0
	var h: float = 6.5
	var back: Transform3D = xf * Transform3D(Basis(), Vector3(0, 0, -dpt * 0.5))
	kit.box(back * kit.T(0, 0.12, 0), Vector3(w, 0.24, dpt), "terrazzo115_mat", 3.0, 4 | 1 | 2 | 16 | 32)
	kit.col_box(back * kit.T(0, 0.12, 0), Vector3(w, 0.24, dpt))
	# les murs (le fond, les côtés), le toit en voûte, la façade (un grand portail ouvert, un hublot)
	kit.box(back * kit.T(0, h * 0.5, -dpt * 0.5 + 0.2), Vector3(w, h, 0.4), "nacre115_gris", 2.0)
	kit.col_box(back * kit.T(0, h * 0.5, -dpt * 0.5 + 0.2), Vector3(w, h, 0.4))
	for s in [-1.0, 1.0]:
		kit.box(back * kit.T(s * (w * 0.5 - 0.2), h * 0.5, 0), Vector3(0.4, h, dpt), "nacre115_gris", 2.0)
		kit.col_box(back * kit.T(s * (w * 0.5 - 0.2), h * 0.5, 0), Vector3(0.4, h, dpt))
		kit.box(back * kit.T(s * (w * 0.5 - 1.6), h * 0.5, dpt * 0.5 - 0.2), Vector3(3.2, h, 0.4), "nacre115", 2.0)
		kit.col_box(back * kit.T(s * (w * 0.5 - 1.6), h * 0.5, dpt * 0.5 - 0.2), Vector3(3.2, h, 0.4))
	kit.box(back * kit.T(0, h - 1.1, dpt * 0.5 - 0.2), Vector3(w - 6.4, 2.2, 0.4), "nacre115", 2.0)
	var n_v: int = 8
	for k in range(n_v):
		var t0: float = float(k) / n_v
		var t1: float = float(k + 1) / n_v
		var xa: float = lerpf(-w * 0.5, w * 0.5, t0)
		var xb: float = lerpf(-w * 0.5, w * 0.5, t1)
		var ya: float = h + sin(t0 * PI) * 1.6
		var yb: float = h + sin(t1 * PI) * 1.6
		var nn: Vector3 = (back.basis * Vector3(-(yb - ya), xb - xa, 0)).normalized()
		kit.quad4("nacre115", back * Vector3(xa, ya, -dpt * 0.5), back * Vector3(xb, yb, -dpt * 0.5), back * Vector3(xb, yb, dpt * 0.5), back * Vector3(xa, ya, dpt * 0.5), nn, Vector2(0, 0), Vector2(1, 0), Vector2(1, 3), Vector2(0, 3))
	kit.porthole115(Transform3D(back.basis * Basis(Vector3.RIGHT, PI * 0.5), back * Vector3(0, h - 1.1, dpt * 0.5 + 0.02)), 0.85, "hublot115")
	kit.sign115(Transform3D(back.basis, back * Vector3(0, h + 0.5, dpt * 0.5 + 0.25)), "atelier", 4.0, 2.0)
	# l'établi, les scaphandres sur leurs supports, le caisson de pression, les tuyaux
	var ex: Transform3D = back * Transform3D(Basis(), Vector3(-2.5, 0.24, -3.8))
	kit.box(ex * kit.T(0, 0.45, 0), Vector3(3.6, 0.9, 1.0), "titane115", 1.0)
	kit.box(ex * kit.T(0, 0.92, 0), Vector3(3.8, 0.06, 1.1), "titane115_sombre", 1.0)
	kit.col_box(ex * kit.T(0, 0.45, 0), Vector3(3.6, 0.9, 1.0))
	kit.ball(Transform3D(Basis(), ex * Vector3(0.8, 1.2, 0)), 0.3, "jaune115", 12, 6)
	_sp("da_atelier_etabli", ex * Vector3(0, 0, 0.9), ex * Vector3(0, 0, -2.0), "bricoler")
	for k2 in range(3):
		_scaphandre(back * Transform3D(Basis(), Vector3(2.0 + k2 * 1.4 - 1.2, 0.24, -1.0 + (k2 % 2) * 0.6)))
	var tx: Transform3D = back * Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(-4.2, 0.24, 0.5))
	kit.cyl(Transform3D(tx.basis * Basis(Vector3.RIGHT, PI * 0.5), tx * Vector3(0, 1.1, -1.8)), 1.0, 1.0, 3.6, "titane115_clair", 20, true)
	kit.porthole115(Transform3D(tx.basis * Basis(Vector3.RIGHT, PI * 0.5), tx * Vector3(0, 1.1, 1.85)), 0.4)
	kit.col_box(tx * kit.T(0, 1.1, 0), Vector3(2.0, 2.2, 3.6))
	var cx: Transform3D = xf * Transform3D(Basis(), Vector3(2.5, 0.24, 1.2))
	kit.box(cx * kit.T(0, 0.55, 0), Vector3(2.6, 1.1, 0.7), "nacre115", 1.0)
	kit.box(cx * kit.T(0, 1.12, 0), Vector3(2.8, 0.06, 0.8), "titane115_clair", 1.0)
	kit.col_box(cx * kit.T(0, 0.55, 0), Vector3(2.6, 1.1, 0.7))
	_sp("da_atelier_comptoir", cx * Vector3(0, 0, -0.75), cx * Vector3(0, 0, 3.0), "comptoir")
	## V119 : le repère de l'Atelier (le milieu de sa façade, au sol ; +Z vers la Place ; l'atelier vers -Z)
	cadres119["atelier"] = xf
	kit.glows115.append([back * Vector3(0, h - 0.6, 0), Color(0.9, 0.95, 1.0), 2.0, 12.0])


## Un scaphandre sur son support : le casque rond (un gros hublot devant, trois petits), le corps, les
## bottes lestées.
func _scaphandre(xf: Transform3D) -> void:
	kit.cyl(xf * kit.T(0, 0, 0), 0.4, 0.4, 0.08, "titane115_sombre", 12, true)
	kit.cyl(xf * kit.T(0, 0.08, 0), 0.04, 0.04, 1.5, "titane115", 6, false)
	for s in [-1.0, 1.0]:
		kit.cyl(xf * kit.T(s * 0.13, 0.12, 0.05), 0.11, 0.1, 0.75, "tissu115_sable", 10, true)
		kit.box(xf * kit.T(s * 0.13, 0.13, 0.1), Vector3(0.18, 0.18, 0.32), "titane115_sombre", 1.0)
	kit.cyl(xf * kit.T(0, 0.85, 0), 0.28, 0.32, 0.65, "tissu115_sable", 14, true)
	kit.cyl(xf * kit.T(0, 1.48, 0), 0.34, 0.34, 0.08, "jaune115", 16, true)
	kit.ball(Transform3D(xf.basis, xf * Vector3(0, 1.75, 0)), 0.3, "jaune115", 14, 8)
	kit.porthole115(Transform3D(xf.basis * Basis(Vector3.RIGHT, PI * 0.5), xf * Vector3(0, 1.75, 0.28)), 0.16, "hublot115_froid")
	for s2 in [-1.0, 1.0]:
		kit.porthole115(Transform3D(xf.basis * Basis(Vector3.FORWARD, s2 * PI * 0.5), xf * Vector3(s2 * 0.28, 1.75, 0)), 0.09, "hublot115_froid")
	for s3 in [-1.0, 1.0]:
		kit.cyl(Transform3D(xf.basis * Basis(Vector3.FORWARD, s3 * 0.25), xf * Vector3(s3 * 0.34, 1.0, 0)), 0.08, 0.07, 0.5, "tissu115_sable", 8, true)


func _ecole() -> void:
	var xf: Transform3D = XR(126.0, 34.0)
	var c: Vector3 = xf.origin
	objets["ecole"] = c
	# un bâtiment courbe à deux niveaux : la grande classe (ouverte devant), l'étage vitré, le toit
	var r_in: float = 30.0
	var r_out: float = 40.0
	var a0: float = 116.0
	var a1: float = 136.0
	var h1: float = 4.4
	var h2: float = 8.6
	var n: int = 6
	for k in range(n):
		var t0: float = lerpf(a0, a1, float(k) / n)
		var t1: float = lerpf(a0, a1, float(k + 1) / n)
		var po0: Vector3 = PR(t0, r_out)
		var po1: Vector3 = PR(t1, r_out)
		var pi0: Vector3 = PR(t0, r_in)
		var pi1: Vector3 = PR(t1, r_in)
		var out := (PR((t0 + t1) * 0.5, 1.0) - P(0, 0)).normalized()
		# le mur du fond
		kit.quad4("nacre115_sable", po0, po1, po1 + Vector3.UP * h2, po0 + Vector3.UP * h2, -out, Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0))
		kit.quad4("nacre115_sable", po0 + out * 0.3, po1 + out * 0.3, po1 + out * 0.3 + Vector3.UP * h2, po0 + out * 0.3 + Vector3.UP * h2, out, Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0))
		kit.col_box(Transform3D(Basis.looking_at(po1 - po0, Vector3.UP), (po0 + po1) * 0.5 + out * 0.15 + Vector3.UP * (h2 * 0.5)), Vector3(0.4, h2, po0.distance_to(po1) + 0.1))
		# des hublots dans le mur du fond (deux rangées, vers le Cours)
		for yy2 in [2.3, 6.5]:
			kit.porthole115(Transform3D(kit._basis_up(out), PR((t0 + t1) * 0.5, r_out) + out * 0.33 + Vector3.UP * yy2), 0.65)
		# le plancher de l'étage, le toit
		for y in [h1, h2]:
			kit.quad4("nacre115", pi0 + Vector3.UP * y, pi1 + Vector3.UP * y, po1 + Vector3.UP * y, po0 + Vector3.UP * y, Vector3.DOWN, Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1))
			kit.quad4("nacre115", pi0 + Vector3.UP * (y + 0.3), pi1 + Vector3.UP * (y + 0.3), po1 + Vector3.UP * (y + 0.3), po0 + Vector3.UP * (y + 0.3), Vector3.UP, Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1))
		# l'étage : un mur-rideau ; le rez-de-chaussée : ouvert (des poteaux)
		kit.facade_panel(pi1 + Vector3.UP * (h1 + 0.3), pi0 + Vector3.UP * (h1 + 0.3), h2 - h1 - 0.3, -out, float(k) * 0.4)
		kit.cyl(Transform3D(Basis(), pi0), 0.2, 0.2, h1, "titane115_clair", 8, false)
		kit.col_cyl(pi0, 0.22, h1)
	# les bords (deux murs pleins), le liseré
	for t in [a0, a1]:
		var e0: Vector3 = PR(t, r_in)
		var e1: Vector3 = PR(t, r_out)
		kit.box(Transform3D(Basis.looking_at(e1 - e0, Vector3.UP), (e0 + e1) * 0.5 + Vector3.UP * (h2 * 0.5)), Vector3(0.4, h2 + 0.3, r_out - r_in), "nacre115_sable", 2.0)
		kit.col_box(Transform3D(Basis.looking_at(e1 - e0, Vector3.UP), (e0 + e1) * 0.5 + Vector3.UP * (h2 * 0.5)), Vector3(0.4, h2, r_out - r_in))
		# des hublots dans les murs pleins des bords (vers le dehors)
		var tg := Vector3(-sin(deg_to_rad(t)), 0, cos(deg_to_rad(t))) * (-1.0 if t == a0 else 1.0)
		for rr2 in [32.2, 35.0, 37.8]:
			for yy3 in [2.3, 6.5]:
				kit.porthole115(Transform3D(kit._basis_up(tg), PR(t, rr2) + tg * 0.22 + Vector3.UP * yy3), 0.6)
	kit.sign115(Transform3D(xf.basis, PR(126.0, r_in - 0.3, h1 + 1.6)), "ecole", 3.6, 1.8)
	## V119 : la porte « vers l'étage » (la Salle du Ciel) : dans le mur plein du bord est (136°), sur sa
	## face de dedans, à deux mètres et demi de l'entrée (les hublots sont sur l'autre face) (da_ciel)
	var nin := Vector3(sin(deg_to_rad(a1)), 0, -cos(deg_to_rad(a1)))
	_lieu119("da_ciel", Transform3D(Basis.looking_at(-nin, Vector3.UP), PR(a1, 32.6) + nin * 0.2), "verre")
	# la classe : le grand tableau (un écran), les deux bancs
	var tx: Transform3D = XL(PR(126.0, r_out - 1.2), P(0, 0))
	kit.box(tx * kit.T(0, 2.0, 0), Vector3(5.0, 2.4, 0.1), "ecran115", 1.0)
	kit.box(tx * kit.T(0, 2.0, -0.08), Vector3(5.3, 2.7, 0.06), "titane115_clair", 1.0)
	_sp("da_ecole_tableau", tx * Vector3(1.6, 0, 1.4), tx * Vector3(0, 0, 8.0), "debout")
	for k2 in range(2):
		var bxf: Transform3D = XL(PR(122.0 + k2 * 8.0, r_out - 5.0), PR(126.0, r_out - 1.0))
		kit.bench115(bxf, 3.0, "corail")
		_sp("da_ecole_banc_%d" % (k2 + 1), bxf * Vector3(0, 0.45, 0.15), PR(126.0, r_out - 1.0), "assis")
	# la cour : un toboggan en coquille, un dôme à grimper, le sol bleu
	var cour: Vector3 = PR(126.0, 25.0)
	kit.cyl(Transform3D(Basis(), cour + Vector3.UP * 0.01), 5.0, 5.0, 0.02, "terrazzo115_bleu", 32, true, 3.0)
	var gq := Vector3(2.4, 0, 0)
	for k3 in range(5):
		var t2: float = float(k3) / 5.0
		var yy: float = 2.4 * (1.0 - t2)
		var aa: float = t2 * TAU * 0.8
		kit.box(Transform3D(Basis(Vector3.UP, aa), cour + gq + Vector3(cos(aa), 0, sin(aa)) * 1.2 + Vector3.UP * yy), Vector3(1.0, 0.1, 1.1), "nacre115_rose", 1.0)
	kit.cyl(Transform3D(Basis(), cour + gq), 0.15, 0.15, 2.6, "titane115_clair", 8, false)
	kit.col_cyl(cour + gq, 1.8, 2.6)
	var gym: Vector3 = cour - Vector3(2.0, 0, 0.5)
	for k4 in range(8):
		var a4: float = TAU * k4 / 8.0
		kit.rod(gym + Vector3(cos(a4), 0, sin(a4)) * 1.6, gym + Vector3.UP * 1.7, 0.04, 0.04, "titane115_clair", 6)
	kit.ring(Transform3D(Basis(), gym + Vector3.UP * 0.9), 1.1, 1.18, 0.06, "led115_rose", 16)
	kit.col_cyl(gym, 1.6, 1.8)
	_sp("da_ecole_cour", cour + Vector3(1.0, 0, 3.4), cour, "debout")
	## V119 : le repère de la cour (son centre, au sol ; +Z vers la Place, l'École derrière, vers -Z)
	cadres119["ecole"] = XL(cour, P(0, 0))
	kit.glows115.append([PR(126.0, 35.0, 3.6), Color(0.9, 0.95, 1.0), 1.8, 12.0])


func _jardin() -> void:
	var c: Vector3 = PR(160.0, 31.0)
	objets["jardin"] = c
	kit.cyl(Transform3D(Basis(), c + Vector3.UP * 0.01), 9.5, 9.5, 0.02, "terrazzo115_bleu", 40, true, 4.0)
	var vases: Array = [[Vector3(0, 0, 0), 2.4], [Vector3(5.2, 0, -2.0), 1.6], [Vector3(-4.6, 0, -2.8), 1.8], [Vector3(-3.8, 0, 4.2), 1.5], [Vector3(4.0, 0, 4.4), 1.7]]
	var cols: Array = ["rose", "violet", "cyan", "orange", "jaune"]
	for k in range(vases.size()):
		var p: Vector3 = c + (vases[k][0] as Vector3)
		var r: float = vases[k][1]
		kit.ring(Transform3D(Basis(), p), r - 0.25, r, 0.7, "nacre115", 28)
		kit.disc(Transform3D(Basis(), p + Vector3.UP * 0.5), r - 0.25, "titane115_sombre", 20, 2.0)
		kit.cyl(Transform3D(Basis(), p + Vector3.UP * 0.55), r - 0.27, r - 0.27, 0.05, "eau115_bassin", 20, true)
		kit.col_cyl(p, r, 0.7)
		for j in range(3 + int(r * 1.5)):
			var aa: float = TAU * j / (3.0 + r * 1.5) + 0.4 * k
			var rr: float = (r - 0.6) * (0.3 + 0.6 * fmod(float(j) * 0.618, 1.0))
			kit.coral115(p + Vector3(cos(aa) * rr, 0.55, sin(aa) * rr), 0.9 + r * 0.45, cols[(k + j) % cols.size()], 11520 + k * 17 + j)
	for k2 in range(2):
		var bxf: Transform3D = XL(c + Vector3(-6.5 + k2 * 13.0, 0, 6.5), c)
		kit.bench115(bxf, 2.4, "sable")
		if k2 == 0:
			_sp("da_jardin_banc", bxf * Vector3(0, 0.45, 0.15), c, "assis")
		else:
			_crowd("da_c_jardin", bxf * Vector3(0, 0.45, 0.15), c, "assis")
	_sp("da_jardin_1", c + Vector3(2.4, 0, -4.8), c + Vector3(5.2, 0, -2.0), "observer")
	_sp("da_jardin_2", c + Vector3(-1.0, 0, 6.6), c + Vector3(-3.8, 0, 4.2), "observer")
	kit.totem115(c + (P(0, 0) - c).normalized() * 9.0 + Vector3(2.0, 0, 0), atan2((P(0, 0) - c).x, (P(0, 0) - c).z), "jardin")
	kit.glows115.append([c + Vector3.UP * 2.5, Color(0.6, 0.45, 1.0), 1.6, 12.0])
	## V119 : le repère du Jardin des Coraux (son centre, au sol ; +X vers l'est, +Z vers le sud)
	cadres119["jardin"] = Transform3D(Basis(), c)


func _conseil() -> void:
	var xf: Transform3D = XR(218.0, 34.0)
	var c: Vector3 = xf.origin
	objets["conseil"] = c
	# le perron (une terrasse de trois marches), le bâtiment rond à deux niveaux, la coupole
	var fwd: Vector3 = xf.basis * Vector3.BACK
	var per: Vector3 = c + fwd * 6.5
	for k in range(3):
		kit.cyl(Transform3D(Basis(), per + Vector3.UP * (k * 0.2)), 6.2 - k * 0.5, 6.2 - k * 0.5, 0.2, "terrazzo115", 32, true, 3.0)
	kit.col_cyl(per, 5.2, 0.6)
	kit.col_cyl(per, 6.2, 0.2)
	var r: float = 7.5
	var gf: float = 4.6
	var seg: int = 24
	for i in range(seg):
		var t0: float = TAU * i / seg
		var t1: float = TAU * (i + 1) / seg
		var dm := Vector3(cos((t0 + t1) * 0.5), 0, sin((t0 + t1) * 0.5))
		var q0: Vector3 = c + Vector3(cos(t0), 0, sin(t0)) * r
		var q1: Vector3 = c + Vector3(cos(t1), 0, sin(t1)) * r
		var front: bool = dm.dot(fwd) > 0.45
		if not front:
			kit.quad4("nacre115", q0, q1, q1 + Vector3.UP * gf, q0 + Vector3.UP * gf, dm, Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0))
			kit.quad4("nacre115", q0 - dm * 0.3, q1 - dm * 0.3, q1 - dm * 0.3 + Vector3.UP * gf, q0 - dm * 0.3 + Vector3.UP * gf, -dm, Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0))
			kit.col_box(Transform3D(Basis.looking_at(q1 - q0, Vector3.UP), (q0 + q1) * 0.5 - dm * 0.15 + Vector3.UP * (gf * 0.5)), Vector3(0.4, gf, q0.distance_to(q1) + 0.1))
		else:
			kit.cyl(Transform3D(Basis(), q0), 0.22, 0.22, gf, "titane115_clair", 8, false)
			kit.col_cyl(q0, 0.24, gf)
		kit.facade_panel(q1 + Vector3.UP * (gf + 0.3), q0 + Vector3.UP * (gf + 0.3), 3.6, dm, float(i) * 0.3)
	kit.cyl(Transform3D(Basis(), c + Vector3.UP * gf), r + 0.4, r + 0.4, 0.3, "nacre115", seg, true, 2.0)
	kit.cyl(Transform3D(Basis(), c + Vector3.UP * (gf + 3.9)), r + 0.5, r + 0.5, 0.35, "nacre115", seg, true, 2.0)
	kit.dome76(Transform3D(Basis(), c + Vector3.UP * (gf + 4.25)), r + 0.3, 3.4, "nacre115_bleu", seg, 8)
	kit.ring(Transform3D(Basis(), c + Vector3.UP * (gf + 4.2)), r + 0.45, r + 0.6, 0.08, "led115_cyan", seg)
	kit.cyl(Transform3D(Basis(), c), r, r, 0.12, "terrazzo115", seg, true, 3.0)
	kit.sign115(Transform3D(xf.basis, c + fwd * (r + 0.55) + Vector3.UP * (gf + 1.9)), "conseil", 4.0, 2.0)
	# le bureau (une grande table de nacre, des écrans), des fauteuils
	var bx: Transform3D = xf * Transform3D(Basis(), Vector3(0, 0.12, -2.4))
	kit.box(bx * kit.T(0, 0.38, 0), Vector3(3.6, 0.06, 1.4), "nacre115", 1.0)
	kit.cyl(bx * kit.T(0, 0, 0), 0.4, 0.3, 0.38, "titane115_clair", 12, false)
	kit.box(Transform3D(bx.basis * Basis(Vector3.RIGHT, -0.25), bx * Vector3(0, 1.0, -0.5)), Vector3(1.6, 0.9, 0.05), "ecran115", 1.0)
	kit.col_box(bx * kit.T(0, 0.4, 0), Vector3(3.6, 0.8, 1.4))
	_sp("da_conseil_bureau", bx * Vector3(0, 0, -1.3), bx * Vector3(0, 0, 3.0), "scribe")
	_sp("da_conseil_balcon", per + Vector3.UP * 0.6 + fwd * 2.0, per + fwd * 10.0, "observer")
	## V119 : la porte « vers l'étage » (la Salle des Marées) : dans le mur plein, au rez-de-chaussée, sur
	## sa face de dedans, du côté +X du repère (à droite en entrant), loin du bureau (da_marees)
	var side: Vector3 = xf.basis * Vector3.RIGHT
	var best_a: float = 0.0
	var best_d: float = -2.0
	for i2 in range(seg):
		var am: float = TAU * (i2 + 0.5) / seg
		var dd: float = Vector3(cos(am), 0, sin(am)).dot(side)
		if dd > best_d:
			best_d = dd
			best_a = am
	var dmx := Vector3(cos(best_a), 0, sin(best_a))
	_lieu119("da_marees", Transform3D(Basis.looking_at(dmx, Vector3.UP), c + dmx * (r * cos(PI / seg) - 0.31) + Vector3.UP * 0.12), "verre")
	## V119 : le repère du perron (le centre des marches, au sol ; le dessus est à +0,6 ; +Z vers la Place,
	## le bâtiment vers -Z)
	cadres119["conseil"] = Transform3D(xf.basis, per)
	kit.glows115.append([c + Vector3.UP * 3.8, Color(1.0, 0.92, 0.8), 1.8, 12.0])


func _tours() -> void:
	for spec in [[-14.0, 41.0, 6, 0.11], [258.0, 41.0, 6, -0.1]]:
		var c: Vector3 = PR(float(spec[0]), float(spec[1]))
		var door: Vector3 = kit.shell_tower(c, 6.5, int(spec[2]), float(spec[3]), (P(0, 0) - c).normalized())
		_pt("da_tour_%d" % int(spec[0]), door)
		_link("da_tour_%d" % int(spec[0]), _near_pt(door + (P(0, 0) - c).normalized() * 3.0))
		## V119 : on y entre (une pièce de 8 × 7)
		_maison119(door, (P(0, 0) - c).normalized(), 8.0, 7.0, int(spec[2]))


func _bulles() -> void:
	for b in BULLES:
		var p: Vector3 = PR(float(b[0]), float(b[1]))
		var face: Vector3 = (P(0, 0) - p).normalized()
		var door: Vector3 = kit.bubble_house(p, float(b[2]), face, str(b[4]), int(b[3]))
		bulle_doors.append(door)
		## V119 : on y entre (la pièce à la taille de la bulle)
		var tb: Vector2 = taille_bulle119(float(b[2]))
		_maison119(door, face, tb.x, tb.y, int(b[3]))
		# un petit jardin de corail devant chaque bulle, une lampe
		if bulle_doors.size() % 2 == 0:
			kit.coral115(p + face * (float(b[2]) + 0.6) + face.cross(Vector3.UP) * 2.2, 1.0, ["rose", "cyan", "violet"][bulle_doors.size() % 3], 11530 + bulle_doors.size())
		kit.lamp115(p + face * (float(b[2]) + 1.2) - face.cross(Vector3.UP) * 2.4, atan2(face.x, face.z), 3.6, "ambre", false)


func _gradins() -> void:
	for a in [140.0, 160.0]:
		var xf: Transform3D = XR(a, 56.6)
		var doors_g: Array = kit.terraces113(xf, 15.0, 9.0, 3, 2.8)
		for k in range(doors_g.size()):
			_pt("da_gradin_%d_%d" % [int(a), k], doors_g[k])
			_link("da_gradin_%d_%d" % [int(a), k], _near_pt(doors_g[k], "da_p_co_"))


func _promenade() -> void:
	# des bancs face au verre, les spots des hublots
	var hub: Array = [[-20.0, "da_hublot_1"], [45.0, "da_hublot_2"], [215.0, "da_hublot_3"], [242.0, "da_hublot_4"]]
	for h in hub:
		var a: float = h[0]
		var pos: Vector3 = PR(a, 67.6)
		_sp(str(h[1]), pos, PR(a, 80.0), "observer")
		var bxf: Transform3D = XL(PR(a + 3.0, 66.2), PR(a + 3.0, 80.0))
		kit.bench115(bxf, 2.4, "")
	for a2 in [-100.0, 70.0, 186.0 - 12.0, 280.0]:
		var bxf2: Transform3D = XL(PR(a2, 66.2), PR(a2, 80.0))
		kit.bench115(bxf2, 2.4, "corail")
		_crowd("da_c_hublot_%d" % int(absf(a2)), bxf2 * Vector3(0, 0.45, 0.15), PR(a2, 80.0), "assis")
	## V119 : le repère de la Promenade (un tronçon libre, entre la Galerie de l'Institut et le deuxième
	## hublot ; au sol, sur la Promenade ; +Z vers le verre, +X le long de la Promenade)
	cadres119["promenade"] = XL(PR(22.5, 66.5), PR(22.5, 80.0))
	# les lampadaires du Cours
	for k in range(12):
		var a3: float = 30.0 * k + 7.0
		if _in_station(a3, CO_R + 2.5):
			continue
		kit.lamp115(PR(a3, CO_R + 2.5), deg_to_rad(-a3 + 90.0), 4.8, "ambre" if k % 2 == 0 else "cyan", k % 3 == 0)


func _belvedere() -> void:
	var a: float = 100.0
	var c: Vector3 = PR(a, 64.5)
	objets["belvedere"] = c
	# une terrasse en demi-lune, à peine surélevée, face au verre (au-dessus de la Faille)
	for k in range(12):
		var t0: float = a - 11.0 + 22.0 * float(k) / 12.0
		var t1: float = a - 11.0 + 22.0 * float(k + 1) / 12.0
		var q0: Vector3 = PR(t0, 59.5, 0.35)
		var q1: Vector3 = PR(t1, 59.5, 0.35)
		var q2: Vector3 = PR(t1, 69.6, 0.35)
		var q3: Vector3 = PR(t0, 69.6, 0.35)
		kit.quad4("terrazzo115_bleu", q0, q1, q2, q3, Vector3.UP, Vector2(0, 0), Vector2(1, 0), Vector2(1, 2), Vector2(0, 2))
		kit.quad4("nacre115", q0 + Vector3.DOWN * 0.35, q1 + Vector3.DOWN * 0.35, q1, q0, (P(0, 0) - (q0 + q1) * 0.5).normalized(), Vector2(0, 0), Vector2(1, 0), Vector2(1, 0.2), Vector2(0, 0.2))
	kit.col_box(Transform3D(Basis.looking_at(dirv(a), Vector3.UP), PR(a, 64.5, 0.17)), Vector3(23.0, 0.34, 10.0))
	# la longue-vue (vers le dehors), les bancs, l'enseigne
	var lv: Vector3 = PR(a, 68.2, 0.35)
	kit.cyl(Transform3D(Basis(), lv), 0.3, 0.2, 1.1, "titane115_clair", 10, true)
	kit.cyl(Transform3D(Basis.looking_at(dirv(a), Vector3.UP) * Basis(Vector3.RIGHT, -PI * 0.5 + 0.15), lv + Vector3.UP * 1.25 - dirv(a) * 0.4), 0.13, 0.1, 1.1, "jaune115", 12, true)
	kit.col_cyl(lv, 0.3, 1.3)
	_sp("da_belvedere_1", PR(a - 4.5, 68.4, 0.35), PR(a - 4.5, 80.0), "observer")
	_sp("da_belvedere_2", PR(a + 4.5, 68.4, 0.35), PR(a + 4.5, 80.0), "observer")
	var bxf: Transform3D = XL(PR(a, 63.6, 0.35), PR(a, 80.0))
	kit.bench115(bxf, 2.8, "")
	_sp("da_belvedere_banc", bxf * Vector3(0, 0.45, 0.15), PR(a, 80.0), "assis")
	kit.totem115(PR(a + 13.0, 60.0), deg_to_rad(-a - 90.0), "belvedere")
	## V119 : le repère du Belvédère (le milieu de la terrasse, au sol ; le dessus est à +0,35 ; +Z vers le
	## verre et la Faille)
	cadres119["belvedere"] = XL(c, PR(a, 80.0))
	_pt("da_p_be", PR(a, 62.0, 0.35))
	_link("da_p_be", _near_pt(PR(a, PR_R), "da_p_pr_"))


# =================================================================== le Dôme des Serres

func _serres() -> void:
	var c: Vector3 = P(S_C.x, S_C.y)
	objets["serres"] = c
	var a_in: float = ang_to(S_C, Vector2.ZERO)   # l'entrée (vers le Grand Dôme)
	# le réseau : un anneau
	for k in range(8):
		_pt("da_p_se_%d" % k, PC(S_C, 45.0 * k + a_in, 14.0))
	for k in range(8):
		_link("da_p_se_%d" % k, "da_p_se_%d" % ((k + 1) % 8))
	_link("da_p_gs_2", "da_p_se_0")
	# les tours de culture (deux rangées, au nord)
	var nn := Vector3(0, 0, -1)
	for row in [-21.0, -15.5]:
		for x in [-11.0, -5.5, 0.0, 5.5, 11.0]:
			kit.hydro_tower115(P(S_C.x + x, S_C.y + row), 6.2)
	_sp("da_serres_tour_1", P(S_C.x - 2.75, S_C.y - 18.2), P(S_C.x - 5.5, S_C.y - 18.2), "jardiner")
	_sp("da_serres_tour_2", P(S_C.x + 8.2, S_C.y - 18.2), P(S_C.x + 11.0, S_C.y - 18.2), "jardiner")
	_pt("da_p_se_tours", P(S_C.x, S_C.y - 18.2))
	_link("da_p_se_tours", _near_pt(P(S_C.x, S_C.y - 14.0), "da_p_se_"))
	# le mur des algues (à l'ouest) et ses bulles
	for k2 in range(11):
		var aa: float = 150.0 + 6.0 * k2
		kit.algae_tube115(PC(S_C, aa, 27.5), 8.0, 0.5)
	bubbles.append(_bubbles_fx(PC(S_C, 180.0, 27.5, 0.4), 1.8, 7.0, 40 if pc else 16))
	_sp("da_serres_algues", PC(S_C, 180.0, 22.5), PC(S_C, 180.0, 28.0), "observer")
	# le Verger des Lampes (au sud) : des petits arbres en bacs, leurs soleils
	var trees: Array = [Vector2(-10.0, 12.0), Vector2(-3.5, 16.5), Vector2(3.5, 16.5), Vector2(10.0, 12.0), Vector2(-14.0, 4.0), Vector2(14.0, 5.0)]
	for t in trees:
		var tp: Vector3 = P(S_C.x + (t as Vector2).x, S_C.y + (t as Vector2).y)
		kit.planter113(Transform3D(Basis(), tp), 2.2, 2.2, true, 0.6)
		var lp: Vector3 = tp + Vector3(1.4, 0, 1.4)
		kit.cyl(Transform3D(Basis(), lp), 0.06, 0.05, 4.2, "titane115_clair", 6, false)
		kit.box(Transform3D(Basis(Vector3.UP, 0.78), lp + Vector3(-0.5, 4.2, -0.5)), Vector3(1.6, 0.08, 0.5), "led115_ambre", 1.0)
	_sp("da_serres_verger", P(S_C.x, S_C.y + 13.0), P(S_C.x - 3.5, S_C.y + 16.5), "jardiner")
	# le bassin aux nénuphars (au centre)
	var bc: Vector3 = P(S_C.x - 1.0, S_C.y + 1.5)
	kit.ring(Transform3D(Basis(), bc), 4.4, 5.0, 0.5, "nacre115", 40)
	kit.disc(Transform3D(Basis(), bc + Vector3.UP * 0.05), 4.4, "titane115_sombre", 24, 2.0)
	kit.cyl(Transform3D(Basis(), bc + Vector3.UP * 0.38), 4.4, 4.4, 0.04, "eau115_bassin", 40, true)
	for k3 in range(9):
		var a3: float = TAU * k3 / 9.0 + 0.3
		var rr: float = 1.2 + fmod(float(k3) * 0.7, 2.6)
		kit.cyl(Transform3D(Basis(), bc + Vector3(cos(a3) * rr, 0.43, sin(a3) * rr)), 0.5, 0.5, 0.02, "feuille115_fonce", 12, true)
		if k3 % 3 == 0:
			kit.ball(Transform3D(Basis(), bc + Vector3(cos(a3) * rr, 0.55, sin(a3) * rr)), 0.15, "corail115_rose", 8, 4)
	kit.col_cyl(bc, 5.0, 0.5)
	_sp("da_serres_bassin", bc + Vector3(0, 0, -6.2), bc, "observer")
	var bxf: Transform3D = XL(bc + Vector3(6.3, 0, -1.0), bc)
	kit.bench115(bxf, 2.4, "sable")
	_sp("da_serres_banc", bxf * Vector3(0, 0.45, 0.15), bc, "assis")
	var bxf2: Transform3D = XL(bc + Vector3(-6.3, 0, 1.0), bc)
	kit.bench115(bxf2, 2.4, "")
	_crowd("da_c_serres", bxf2 * Vector3(0, 0.45, 0.15), bc, "assis")
	# l'étal de la jardinière (près de l'entrée) : un comptoir, des cagettes
	var ex: Transform3D = XC(S_C, a_in - 32.0, 21.0)
	kit.box(ex * kit.T(0, 0.5, 0), Vector3(3.2, 1.0, 0.9), "nacre115_sable", 1.0)
	kit.box(ex * kit.T(0, 1.02, 0), Vector3(3.4, 0.05, 1.0), "bois113", 1.0)
	kit.col_box(ex * kit.T(0, 0.5, 0), Vector3(3.2, 1.0, 0.9))
	for k4 in range(4):
		var cp: Vector3 = ex * Vector3(-1.2 + k4 * 0.8, 1.15, 0.1)
		kit.box(Transform3D(ex.basis, cp), Vector3(0.6, 0.22, 0.45), "bois113", 1.0)
		for k5 in range(4):
			kit.ball(Transform3D(Basis(), cp + ex.basis * Vector3(-0.18 + (k5 % 2) * 0.36, 0.14, -0.1 + (k5 / 2) * 0.2)), 0.09, ["fruit115", "fruit115_fraise", "fruit115_citron", "feuille115_salade"][k4], 6, 3)
	kit.canopy113(ex * Transform3D(Basis(), Vector3(0, 0, -0.3)), 4.4, 2.6, 2.6, "toile113_vert")
	_sp("da_serres_etal", ex * Vector3(0, 0, -0.8), ex * Vector3(0, 0, 3.0), "comptoir")
	## V119 : la chambre des semences : une petite cabine de nacre, à côté de l'étal (quatorze degrés plus
	## au nord), un toit de titane, un liseré de diodes vertes, un hublot ; sa porte regarde le centre des
	## Serres, comme l'étal (da_semences)
	var smx: Transform3D = XC(S_C, a_in - 46.0, 23.6)
	kit.box(smx * kit.T(0, 1.5, 0), Vector3(3.2, 3.0, 2.6), "nacre115", 1.5)
	kit.box(smx * kit.T(0, 3.07, 0), Vector3(3.5, 0.14, 2.9), "titane115_clair", 1.0)
	kit.box(smx * kit.T(0, 2.95, 0), Vector3(3.24, 0.06, 2.64), "led115_vert", 1.0, 1 | 2 | 16 | 32)
	kit.col_box(smx * kit.T(0, 1.5, 0), Vector3(3.2, 3.0, 2.6))
	kit.porthole115(Transform3D(kit._basis_up(smx.basis * Vector3.RIGHT), smx * Vector3(1.61, 1.7, 0)), 0.42)
	_lieu119("da_semences", smx * Transform3D(Basis(), Vector3(0, 0, 1.3)), "verre")
	## V119 : le repère des Serres (le centre du dôme, au sol ; +X vers l'est, +Z vers le sud)
	cadres119["serres"] = Transform3D(Basis(), c)
	kit.totem115(PC(S_C, a_in, 24.0) + Vector3(0, 0, 3.0), deg_to_rad(-a_in + 90.0), "serres")
	# la maisonnette de la jardinière, au fond du Verger des Lampes
	var mh: Vector3 = PC(S_C, 90.0, 25.0)
	objets["maison_melisande"] = kit.bubble_house(mh, 3.3, c - mh, "sable", 1)
	## V119 : on y entre aussi (une maison-bulle de 3,3 m)
	var tm: Vector2 = taille_bulle119(3.3)
	_maison119(objets["maison_melisande"], (c - mh).normalized(), tm.x, tm.y, 1)
	kit.coral115(mh + Vector3(3.9, 0, -1.2), 0.8, "rose", 11590)
	# la petite Perle des Serres (au sommet, au bout d'un câble)
	var pp: Vector3 = c + Vector3.UP * 17.5
	kit.cyl(Transform3D(Basis(), pp), 0.02, 0.02, H_DRUM + H_CAP_S - 17.5, "titane115_sombre", 4, false)
	var sp := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 1.6
	sm.height = 3.2
	sp.mesh = sm
	sp.material_override = kit.mat("perle115")
	sp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(sp)
	sp.global_position = pp
	var l := _light(pp + Vector3.DOWN * 0.2, Color(1.0, 0.94, 0.86), 5.0, 1.6, 48.0)
	sat_lights.append(l)
	objets["serres_perle"] = pp


# =================================================================== le Dôme de l'Institut

func _institut() -> void:
	var c: Vector3 = P(I_C.x, I_C.y)
	objets["institut"] = c
	var a_in: float = ang_to(I_C, Vector2.ZERO)
	# (pas de point au-dessus du puits du Bassin : l'anneau s'ouvre là, en C)
	for k in range(8):
		var q: Vector3 = PC(I_C, 45.0 * k + a_in, 14.0)
		if q.distance_to(objets["bassin"]) > POOL_R + 2.5:
			_pt("da_p_in_%d" % k, q)
	for k in range(8):
		_link("da_p_in_%d" % k, "da_p_in_%d" % ((k + 1) % 8))
	_link("da_p_gi_2", "da_p_in_0")
	# l'Institut des Abysses : un bâtiment courbe à deux niveaux, au nord (le rez-de-chaussée ouvert)
	var r_in: float = 18.0
	var r_out: float = 27.0
	var a0: float = 215.0
	var a1: float = 325.0
	var h1: float = 4.4
	var h2: float = 8.8
	var n: int = 10
	for k2 in range(n):
		var t0: float = lerpf(a0, a1, float(k2) / n)
		var t1: float = lerpf(a0, a1, float(k2 + 1) / n)
		var po0: Vector3 = PC(I_C, t0, r_out)
		var po1: Vector3 = PC(I_C, t1, r_out)
		var pi0: Vector3 = PC(I_C, t0, r_in)
		var pi1: Vector3 = PC(I_C, t1, r_in)
		var out: Vector3 = dirv((t0 + t1) * 0.5)
		kit.quad4("nacre115", po0, po1, po1 + Vector3.UP * h2, po0 + Vector3.UP * h2, -out, Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0))
		kit.quad4("nacre115", po0 + out * 0.3, po1 + out * 0.3, po1 + out * 0.3 + Vector3.UP * h2, po0 + out * 0.3 + Vector3.UP * h2, out, Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0))
		kit.col_box(Transform3D(Basis.looking_at(po1 - po0, Vector3.UP), (po0 + po1) * 0.5 + out * 0.15 + Vector3.UP * (h2 * 0.5)), Vector3(0.4, h2, po0.distance_to(po1) + 0.1))
		for y in [h1, h2]:
			kit.quad4("nacre115", pi0 + Vector3.UP * y, pi1 + Vector3.UP * y, po1 + Vector3.UP * y, po0 + Vector3.UP * y, Vector3.DOWN, Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1))
			kit.quad4("nacre115", pi0 + Vector3.UP * (y + 0.3), pi1 + Vector3.UP * (y + 0.3), po1 + Vector3.UP * (y + 0.3), po0 + Vector3.UP * (y + 0.3), Vector3.UP, Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1))
		kit.facade_panel(pi1 + Vector3.UP * (h1 + 0.3), pi0 + Vector3.UP * (h1 + 0.3), h2 - h1 - 0.3, -out, float(k2) * 0.4)
		kit.cyl(Transform3D(Basis(), pi0), 0.2, 0.2, h1, "titane115_clair", 8, false)
		kit.col_cyl(pi0, 0.22, h1)
		# les paillasses du laboratoire, contre le mur du fond
		if k2 % 2 == 1:
			var lb: Transform3D = XL(PC(I_C, (t0 + t1) * 0.5, r_out - 1.2), c)
			kit.box(lb * kit.T(0, 0.45, 0), Vector3(3.0, 0.9, 0.8), "nacre115", 1.0)
			kit.box(lb * kit.T(0, 0.92, 0), Vector3(3.1, 0.05, 0.9), "titane115_sombre", 1.0)
			kit.col_box(lb * kit.T(0, 0.45, 0), Vector3(3.0, 0.9, 0.8))
			for k3 in range(3):
				kit.cyl(lb * kit.T(-1.0 + k3 * 1.0, 0.95, 0), 0.1, 0.06, 0.3, "vitre115", 8, true)
	for t in [a0, a1]:
		var e0: Vector3 = PC(I_C, t, r_in)
		var e1: Vector3 = PC(I_C, t, r_out)
		kit.box(Transform3D(Basis.looking_at(e1 - e0, Vector3.UP), (e0 + e1) * 0.5 + Vector3.UP * (h2 * 0.5)), Vector3(0.4, h2 + 0.3, r_out - r_in), "nacre115", 2.0)
		kit.col_box(Transform3D(Basis.looking_at(e1 - e0, Vector3.UP), (e0 + e1) * 0.5 + Vector3.UP * (h2 * 0.5)), Vector3(0.4, h2, r_out - r_in))
	kit.sign115(Transform3D(Basis.looking_at(dirv(270.0), Vector3.UP), PC(I_C, 270.0, r_in - 0.3, h1 + 1.8)), "institut", 4.0, 2.0)
	# les tables holographiques (les labos), le bureau
	for spec in [[245.0, "da_institut_labo_1"], [295.0, "da_institut_labo_2"]]:
		var hp: Vector3 = PC(I_C, float(spec[0]), 22.0)
		kit.cyl(Transform3D(Basis(), hp), 0.9, 0.7, 0.9, "nacre115", 20, true)
		kit.cyl(Transform3D(Basis(), hp + Vector3.UP * 0.9), 0.85, 0.85, 0.03, "ecran115", 20, true)
		kit.col_cyl(hp, 0.9, 1.0)
		_sp(str(spec[1]), hp + (c - hp).normalized() * 1.5, hp, "holo")
	var bp: Vector3 = PC(I_C, 270.0, 24.5)
	kit.box(Transform3D(Basis.looking_at(dirv(270.0), Vector3.UP), bp + Vector3.UP * 0.38), Vector3(2.6, 0.06, 1.2), "nacre115", 1.0)
	kit.col_box(Transform3D(Basis.looking_at(dirv(270.0), Vector3.UP), bp + Vector3.UP * 0.4), Vector3(2.6, 0.8, 1.2))
	_sp("da_institut_bureau", bp + (c - bp).normalized() * -1.0 + Vector3.ZERO, c, "scribe")
	## V119 : le cabinet du Professeur Benthos : une porte dans le mur du fond, juste à côté de son bureau
	## (le pan entre 259° et 270°, sans paillasse) (da_benthos)
	var bw0: Vector3 = PC(I_C, 259.0, r_out)
	var bw1: Vector3 = PC(I_C, 270.0, r_out)
	_lieu119("da_benthos", Transform3D(Basis.looking_at(dirv(264.5), Vector3.UP), (bw0 + bw1) * 0.5), "titane")
	## V119 : le repère de l'Institut (au rez-de-chaussée, devant le bureau ; +Z vers l'Aquarium, le mur
	## du fond vers -Z)
	cadres119["institut"] = XC(I_C, 270.0, 22.5)
	cadres119["aquarium"] = Transform3D(Basis(), c)
	# le Grand Aquarium : une grande cuve au centre, des petites autour (des méduses qui luisent)
	var centers: Array = []
	centers.append(kit.tank115(c, 3.0, 6.0))
	for aa in [20.0, 80.0, 140.0]:
		centers.append(kit.tank115(PC(I_C, aa, 9.5), 1.4, 4.0))
	_sp("da_aquarium_1", PC(I_C, a_in, 5.8), c, "observer")
	_sp("da_aquarium_2", PC(I_C, 50.0, 6.0), c, "observer")
	_crowd("da_c_aquarium", PC(I_C, 110.0, 6.2), c, "observer")
	_meduses_cuves(centers)
	_poissons_cuve(centers[0], 2.4, 2.2)
	# le Bassin des Bathyscaphes : le puits, son garde-corps, le portique, le Petit Plongeon
	var bc: Vector3 = objets["bassin"]
	kit.ring(Transform3D(Basis(), bc + Vector3.DOWN * 3.0), POOL_R, POOL_R + 0.35, 3.05, "titane115_sombre", 40)
	kit.ring(Transform3D(Basis(), bc), POOL_R - 0.05, POOL_R + 1.2, 0.06, "jaune115", 40)
	var pw := MeshInstance3D.new()
	pw.name = "Eau_puits"
	var pcm := CylinderMesh.new()
	pcm.top_radius = POOL_R
	pcm.bottom_radius = POOL_R
	pcm.height = 0.04
	pcm.radial_segments = 40
	pw.mesh = pcm
	pw.material_override = kit.mat("eau115_puits")
	add_child(pw)
	pw.global_position = bc + Vector3.DOWN * 0.9
	## V119 : le garde-corps s'ouvre (le pan de 337,5° à 360°) sur la passerelle du Petit Plongeon
	var gg: Vector3 = dirv(348.75)
	var gt: Vector3 = gg.cross(Vector3.UP).normalized()
	for k4 in range(16):
		var q0: Vector3 = bc + dirv(22.5 * k4) * (POOL_R + 0.9)
		var q1: Vector3 = bc + dirv(22.5 * (k4 + 1)) * (POOL_R + 0.9)
		if k4 == 15:
			var qm: Vector3 = bc + gg * ((POOL_R + 0.9) * cos(deg_to_rad(11.25)))
			kit.glass_rail113(q0, qm - gt * 0.8, 1.1, true)
			kit.glass_rail113(qm + gt * 0.8, q1, 1.1, true)
			continue
		kit.glass_rail113(q0, q1, 1.1, true)
	## V119 : la passerelle : un tablier de titane au-dessus du puits (ses bords jaunes, ses garde-corps), au
	## bout le sas (un caisson de titane, sa porte vers le quai) et le soufflet qui monte à l'écoutille du
	## bathyscaphe, suspendu au milieu du puits (da_plongeon)
	var g_in: float = 2.25
	var g_sas: float = 2.8
	var g_out: float = POOL_R + 1.5
	var gb := Basis.looking_at(-gg, Vector3.UP)
	var gmid: Vector3 = bc + gg * ((g_in + g_out) * 0.5)
	kit.box(Transform3D(gb, gmid + Vector3.UP * 0.02), Vector3(1.6, 0.12, g_out - g_in), "titane119", 1.0)
	kit.col_box(Transform3D(gb, gmid + Vector3.UP * 0.02), Vector3(1.6, 0.12, g_out - g_in))
	var qm2: Vector3 = bc + gg * ((POOL_R + 0.9) * cos(deg_to_rad(11.25)))
	for s in [-1.0, 1.0]:
		kit.box(Transform3D(gb, gmid + gt * s * 0.72 + Vector3.UP * 0.085), Vector3(0.12, 0.01, g_out - g_in), "jaune115", 1.0)
		kit.glass_rail113(bc + gg * g_sas + gt * s * 0.8, qm2 + gt * s * 0.8, 1.1, true)
	var sas: Vector3 = bc + gg * ((g_in + g_sas) * 0.5)
	kit.box(Transform3D(gb, sas + Vector3.UP * 1.54), Vector3(2.0, 2.92, g_sas - g_in), "titane119", 1.5)
	kit.box(Transform3D(gb, sas + Vector3.UP * 3.06), Vector3(2.2, 0.12, g_sas - g_in + 0.2), "nacre115", 1.0)
	kit.box(Transform3D(gb, sas + Vector3.UP * 2.96), Vector3(2.04, 0.06, g_sas - g_in + 0.04), "led115_cyan", 1.0, 1 | 2 | 16 | 32)
	kit.col_box(Transform3D(gb, sas + Vector3.UP * 1.54), Vector3(2.0, 2.92, g_sas - g_in))
	var sf_a: Vector3 = bc + gg * (g_in + 0.05) + Vector3.UP * 2.2
	var sf_b: Vector3 = bc + Vector3.UP * 3.2 + (gg + Vector3.DOWN * 0.85).normalized() * 1.15
	kit.rod(sf_a, sf_b, 0.4, 0.36, "titane115_sombre", 12)
	for k5 in range(4):
		kit.ring(Transform3D(kit._basis_up((sf_b - sf_a).normalized()), sf_a.lerp(sf_b, 0.12 + 0.24 * k5)), 0.38, 0.47, 0.1, "titane115_clair", 14)
	_lieu119("da_plongeon", Transform3D(gb, bc + gg * g_sas + Vector3.UP * 0.08), "titane")
	## V119 : le repère du Bassin (le centre du puits, au sol ; +X vers l'est, +Z vers le sud)
	cadres119["bassin"] = Transform3D(Basis(), bc)
	var g0: Vector3 = bc + dirv(20.0) * (POOL_R + 1.6)
	var g1: Vector3 = bc + dirv(200.0) * (POOL_R + 1.6)
	for gp in [g0, g1]:
		kit.cyl(Transform3D(Basis(), gp), 0.3, 0.25, 7.0, "jaune115", 10, false)
		kit.col_cyl(gp, 0.3, 7.0)
	kit.box(Transform3D(Basis.looking_at(g1 - g0, Vector3.UP), (g0 + g1) * 0.5 + Vector3.UP * 7.1), Vector3(0.5, 0.6, g0.distance_to(g1) + 0.6), "jaune115", 1.0)
	bathy = Node3D.new()
	bathy.name = "Le_Petit_Plongeon"
	add_child(bathy)
	bathy_base = Transform3D(Basis(Vector3.UP, 0.3), bc + Vector3.UP * 3.2)
	bathy.global_transform = bathy_base
	var bk = Kit.new()
	bk.setup(bathy, null)
	_bathyscaphe(bk, Transform3D.IDENTITY)
	bk.cyl(Transform3D(Basis(), Vector3(0, 1.3, 0)), 0.02, 0.02, 2.7, "titane115_sombre", 4, false)
	bk.commit()
	var bk2 = Kit.new()
	bk2.setup(self, null)
	_bathyscaphe(bk2, Transform3D(Basis(Vector3.UP, 2.2), bc + dirv(250.0) * 2.4 + Vector3.DOWN * 1.2))
	bk2.commit()
	_sp("da_bassin_quai", bc + dirv(300.0) * (POOL_R + 1.6), bc, "observer")
	var wb: Transform3D = XL(bc + dirv(70.0) * (POOL_R + 3.2), bc)
	kit.box(wb * kit.T(0, 0.45, 0), Vector3(2.6, 0.9, 0.8), "titane115", 1.0)
	kit.col_box(wb * kit.T(0, 0.45, 0), Vector3(2.6, 0.9, 0.8))
	_sp("da_bassin_bathyscaphe", wb * Vector3(0, 0, -0.9), bc, "bricoler")
	kit.sign115(Transform3D(Basis.looking_at(-dirv(110.0), Vector3.UP), bc + dirv(110.0) * (POOL_R + 4.2) + Vector3.UP * 2.6), "bassin", 2.8, 1.4)
	kit.box(Transform3D(Basis.looking_at(-dirv(110.0), Vector3.UP), bc + dirv(110.0) * (POOL_R + 4.3) + Vector3.UP * 1.3), Vector3(0.2, 2.6, 0.2), "titane115_clair", 1.0)
	# la Baie d'Observation : des bancs face au verre, vers la cheminée hydrothermale
	var a_v: float = ang_to(I_C, F.VENT)
	_sp("da_observation_1", PC(I_C, a_v, 29.4), PC(I_C, a_v, 40.0), "observer")
	var obx: Transform3D = XL(PC(I_C, a_v + 6.0, 26.6), PC(I_C, a_v + 6.0, 40.0))
	kit.bench115(obx, 2.6, "")
	_sp("da_observation_banc", obx * Vector3(0, 0.45, 0.15), PC(I_C, a_v + 6.0, 40.0), "assis")
	var obx2: Transform3D = XL(PC(I_C, a_v - 6.0, 26.6), PC(I_C, a_v - 6.0, 40.0))
	kit.bench115(obx2, 2.6, "corail")
	_crowd("da_c_observation", obx2 * Vector3(0, 0.45, 0.15), PC(I_C, a_v - 6.0, 40.0), "assis")
	kit.sign115(Transform3D(Basis.looking_at(-dirv(a_in), Vector3.UP), PC(I_C, a_in, 6.5, 6.8)), "aquarium", 2.8, 1.4)
	# la petite Perle de l'Institut
	var pp: Vector3 = c + Vector3.UP * 17.5
	kit.cyl(Transform3D(Basis(), pp), 0.02, 0.02, H_DRUM + H_CAP_S - 17.5, "titane115_sombre", 4, false)
	var sp := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 1.6
	sm.height = 3.2
	sp.mesh = sm
	sp.material_override = kit.mat("perle115")
	sp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(sp)
	sp.global_position = pp
	var l := _light(pp + Vector3.DOWN * 0.2, Color(0.9, 0.96, 1.0), 5.0, 1.6, 48.0)
	sat_lights.append(l)


## Le bathyscaphe jaune : une sphère d'acier (ses hublots), un flotteur dessus, des hélices.
func _bathyscaphe(bk, xf: Transform3D) -> void:
	bk.ball(xf * bk.T(0, 0, 0), 1.25, "jaune115", 20, 10)
	bk.porthole115(Transform3D(xf.basis * Basis(Vector3.RIGHT, PI * 0.5), xf * Vector3(0, 0.1, 1.2)), 0.42, "hublot115_froid")
	for s in [-1.0, 1.0]:
		bk.porthole115(Transform3D(xf.basis * Basis(Vector3.FORWARD, s * PI * 0.5), xf * Vector3(s * 1.2, 0.05, 0)), 0.22, "hublot115_froid")
	bk.cyl(Transform3D(xf.basis * Basis(Vector3.RIGHT, PI * 0.5), xf * Vector3(0, 1.15, -1.6)), 0.55, 0.55, 3.2, "jaune115", 16, true)
	bk.box(xf * bk.T(0, 0.85, 0), Vector3(0.6, 0.4, 1.6), "titane115_sombre", 1.0)
	for s2 in [-1.0, 1.0]:
		bk.cyl(Transform3D(xf.basis * Basis(Vector3.RIGHT, PI * 0.5), xf * Vector3(s2 * 1.0, -0.2, -1.6)), 0.22, 0.18, 0.5, "titane115", 10, true)
		bk.box(xf * bk.T(s2 * 1.0, -0.2, -1.65), Vector3(0.7, 0.05, 0.1), "titane115_clair", 1.0)
	bk.box(xf * bk.T(0, -1.25, 0), Vector3(1.4, 0.12, 0.9), "titane115_sombre", 1.0)
	bk.ball(Transform3D(Basis(), xf * Vector3(0, 1.5, 0.6)), 0.09, "led115_ambre", 6, 4)


## Les poissons de la grande cuve : un petit banc de poissons de récif (ceux de la vie marine de la V55),
## qui tourne en rond dans l'eau claire ; chacun à sa hauteur, à sa vitesse.
func _poissons_cuve(cc: Vector3, r: float, hh: float) -> void:
	var vm = load("res://scripts/vie_marine_v55.gd").new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = vm._make_fish_mesh()
	vm.free()
	var n: int = 16 if pc else 9
	mm.instance_count = n
	tank_fish.clear()
	for i in range(n):
		var sp: int = [0, 2, 4, 5, 6][i % 5]
		mm.set_instance_custom_data(i, Color(_rng.randf(), (sp + 0.0) / 8.0, _rng.randf_range(0.7, 1.1), 0.0))
		# [rayon, hauteur, vitesse (tours par seconde, signée), phase, taille]
		tank_fish.append([_rng.randf_range(0.6, r), _rng.randf_range(-hh, hh), _rng.randf_range(0.03, 0.07) * (1.0 if i % 3 != 0 else -1.0), _rng.randf() * TAU, _rng.randf_range(0.24, 0.4)])
		mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ONE * 0.12), cc))
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/poisson_v55.gdshader")
	if ResourceLoader.exists("res://assets/textures/mer/poissons.png"):
		mat.set_shader_parameter("atlas", load("res://assets/textures/mer/poissons.png"))
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Poissons_de_la_cuve"
	mmi.multimesh = mm
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)
	tank_mm = mmi
	tank_center = cc


func _tick_poissons_cuve() -> void:
	if tank_mm == null:
		return
	var mm: MultiMesh = tank_mm.multimesh
	for i in range(tank_fish.size()):
		var f: Array = tank_fish[i]
		var a: float = float(f[3]) + _clock * float(f[2]) * TAU
		var rr: float = float(f[0]) + sin(_clock * 0.3 + i) * 0.15
		var y: float = float(f[1]) + sin(_clock * 0.4 + i * 1.3) * 0.25
		var dirf := Vector3(-sin(a), 0, cos(a)) * signf(float(f[2]))
		mm.set_instance_transform(i, Transform3D(Basis.looking_at(dirf, Vector3.UP).scaled(Vector3.ONE * float(f[4])), tank_center + Vector3(cos(a) * rr, y, sin(a) * rr)))


## Les méduses des cuves : des cloches qui pulsent et dérivent doucement dans l'eau.
func _meduses_cuves(centers: Array) -> void:
	var sh: Shader = load("res://shaders/meduse_v55.gdshader")
	var bell := SphereMesh.new()
	bell.radius = 0.5
	bell.height = 0.6
	bell.is_hemisphere = true
	bell.radial_segments = 16
	bell.rings = 6
	var tints := [Color(0.95, 0.45, 0.85), Color(0.45, 0.75, 1.0), Color(0.75, 0.55, 1.0), Color(1.0, 0.65, 0.45)]
	var k: int = 0
	for cc in centers:
		var n: int = 5 if k == 0 else 2
		for i in range(n):
			var root := Node3D.new()
			root.name = "Meduse_cuve"
			add_child(root)
			var m := ShaderMaterial.new()
			m.shader = sh
			m.set_shader_parameter("tint", tints[(k + i) % tints.size()])
			m.set_shader_parameter("seed", _rng.randf() * 10.0)
			var bi := MeshInstance3D.new()
			bi.mesh = bell
			bi.material_override = m
			bi.scale = Vector3.ONE * (0.55 if k == 0 else 0.35)
			root.add_child(bi)
			var home: Vector3 = (cc as Vector3) + Vector3(_rng.randf_range(-0.6, 0.6), _rng.randf_range(-1.0, 1.0), _rng.randf_range(-0.6, 0.6)) * (1.4 if k == 0 else 0.5)
			root.global_position = home
			jellies_in.append([root, home, _rng.randf() * TAU, m, 1.6 if k == 0 else 0.5])
		k += 1


# =================================================================== les rues, les lumières, les portes

func _rues() -> void:
	# les crowd spots du Cours et de l'Anneau (des passants debout, qui bavardent)
	for k in range(6):
		var a: float = 60.0 * k + 30.0
		if _in_station(a, CO_R - 2.0):
			continue
		var p: Vector3 = PR(a, CO_R - 2.0)
		_crowd("da_c_cours_%d" % k, p, PR(a + 30.0, CO_R - 2.0), "debout")
	for k2 in range(4):
		var a2: float = 90.0 * k2 + 50.0
		var p2: Vector3 = PR(a2, AN_R + 1.5)
		_crowd("da_c_anneau_%d" % k2, p2, P(0, 0), "debout")
	# des lampadaires de l'Anneau
	for k3 in range(8):
		var a3: float = 45.0 * k3 + 11.0
		kit.lamp115(PR(a3, AN_R + 2.6), deg_to_rad(-a3 + 90.0), 4.6, "cyan", false)


## Les jardinets : des massifs ronds bordés de nacre (un petit arbre ou des buissons, du gazon, des
## fleurs), partout où il y a de la place : autour de la Place de la Perle, le long du Cours, devant les
## maisons-bulles, dans les Serres ; jamais sur une allée, devant une porte, sur un lieu de rendez-vous ni
## dans un bâtiment (d'après les collisions déjà posées). La végétation elle-même : _flore().
func _jardinets() -> void:
	var fp: Array = _footprints()
	var segs: Array = _path_segs()
	var keep: Array = []
	for k in hf.spots:
		if str(k).begins_with("da_"):
			var sp: Vector3 = hf.spots[k]["pos"]
			keep.append([Vector2(sp.x, sp.z), 1.3])
	for d in bulle_doors:
		keep.append([Vector2((d as Vector3).x, (d as Vector3).z), 2.8])
	for d2 in doors.values():
		keep.append([Vector2((d2 as Vector3).x, (d2 as Vector3).z), 2.8])
	## V119 : pas de massif devant les portes des grands lieux
	for e119 in portes119.values():
		keep.append([Vector2((e119[0] as Vector3).x, (e119[0] as Vector3).z), 2.4])
	# [centre du dôme, rayon de l'anneau, rayon du massif, écart, genre, rayon du dôme]
	var rings: Array = [[Vector2.ZERO, 17.0, 2.4, 9.0, "arbre", R_G], [Vector2.ZERO, 40.5, 2.1, 11.0, "arbre", R_G],
		[Vector2.ZERO, 49.5, 1.7, 9.0, "buisson", R_G], [S_C, 10.0, 1.4, 6.5, "buisson", R_SAT], [S_C, 22.5, 1.6, 7.0, "arbre", R_SAT]]
	for ring in rings:
		var cc: Vector2 = ring[0]
		var r: float = ring[1]
		var br: float = ring[2]
		var a: float = 3.0
		while a < 363.0:
			var c: Vector3 = PC(cc, a, r)
			if _bed_ok(c, br, cc, float(ring[5]), fp, segs, keep):
				var kind: String = ring[4]
				if kind == "arbre" and massifs.size() % 3 == 2:
					kind = "buisson"
				massifs.append([c + Vector3.UP * 0.36, br, kind])
				keep.append([Vector2(c.x, c.z), br + 1.0])
				a += rad_to_deg(float(ring[3]) / r)
			else:
				a += 2.0
	for m in massifs:
		var c2: Vector3 = (m[0] as Vector3) - Vector3.UP * 0.36
		var r2: float = m[1]
		kit.ring(Transform3D(Basis(), c2), r2 - 0.16, r2, 0.42, "nacre115", 32)
		kit.disc(Transform3D(Basis(), c2 + Vector3.UP * 0.36), r2 - 0.16, "gazon113", 24, 1.0)
		kit.col_cyl(c2, r2, 0.42)


## L'empreinte au sol de ce qui est déjà posé (boîtes, cylindres, sphères) : [genre, repère, taille].
func _footprints() -> Array:
	var out: Array = []
	var fy: float = P(0, 0).y
	for cs in kit.body.get_children():
		if not (cs is CollisionShape3D):
			continue
		var sh: Shape3D = (cs as CollisionShape3D).shape
		var xf: Transform3D = (cs as CollisionShape3D).transform
		if sh is BoxShape3D:
			var hs: Vector3 = (sh as BoxShape3D).size * 0.5
			var ey: float = absf(xf.basis.x.y) * hs.x + absf(xf.basis.y.y) * hs.y + absf(xf.basis.z.y) * hs.z
			if xf.origin.y - ey < fy + 2.5 and xf.origin.y + ey > fy - 0.2:
				out.append(["b", xf, hs])
		elif sh is CylinderShape3D:
			var h2: float = (sh as CylinderShape3D).height * 0.5
			if xf.origin.y - h2 < fy + 2.5 and xf.origin.y + h2 > fy - 0.2:
				out.append(["c", xf.origin, (sh as CylinderShape3D).radius])
		elif sh is SphereShape3D:
			out.append(["c", xf.origin, (sh as SphereShape3D).radius])
	return out


## Les allées du Dôme (au sol) : [Vector2, Vector2].
func _path_segs() -> Array:
	var out: Array = []
	var fy: float = P(0, 0).y
	for a in hf.graph:
		if not str(a).begins_with("da_"):
			continue
		var pa: Vector3 = hf.points[a]
		for b in hf.graph[a]:
			if str(a) >= str(b) or not hf.points.has(b):
				continue
			var pb: Vector3 = hf.points[b]
			if absf(pa.y - fy) > 1.5 or absf(pb.y - fy) > 1.5:
				continue
			out.append([Vector2(pa.x, pa.z), Vector2(pb.x, pb.z)])
	return out


func _bed_ok(c: Vector3, br: float, dc: Vector2, dr: float, fp: Array, segs: Array, keep: Array) -> bool:
	var c2 := Vector2(c.x, c.z)
	var l: Vector3 = F.L(c)
	if Vector2(l.x - dc.x, l.z - dc.y).length() + br > dr - 4.0:
		return false
	for k in keep:
		if c2.distance_to(k[0]) < float(k[1]) + br:
			return false
	for sg in segs:
		var a: Vector2 = sg[0]
		var ab: Vector2 = (sg[1] as Vector2) - a
		var t: float = clampf((c2 - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
		if c2.distance_to(a + ab * t) < br + 1.4:
			return false
	for f in fp:
		if f[0] == "b":
			var lc: Vector3 = (f[1] as Transform3D).affine_inverse() * c
			var hs: Vector3 = f[2]
			if absf(lc.x) < hs.x + br + 0.4 and absf(lc.z) < hs.z + br + 0.4:
				return false
		elif c2.distance_to(Vector2((f[1] as Vector3).x, (f[1] as Vector3).z)) < float(f[2]) + br + 0.4:
			return false
	return true


## La végétation (dome_flore_v115) : les jardinets, les arbres des Gradins, le Verger des Lampes.
func _flore() -> void:
	var arbres: Array = []
	var vergers: Array = []
	for tp in kit.tree_spots:
		var l: Vector3 = F.L(tp)
		if Vector2(l.x - S_C.x, l.z - S_C.y).length() < R_SAT:
			vergers.append(tp)
		else:
			arbres.append(tp)
	flore = DomeFlore.new()
	flore.name = "Flore_dome_v115"
	add_child(flore)
	flore.build_dome(pc, {"massifs": massifs, "arbres": arbres, "vergers": vergers})


## Les portes des habitants (d'après PORTES) ; et des points pour les portes des maisons-bulles libres.
func _portes() -> void:
	for k in range(bulle_doors.size()):
		_pt("da_bulle_%d" % k, bulle_doors[k])
		_link("da_bulle_%d" % k, _near_pt(bulle_doors[k] + (P(0, 0) - bulle_doors[k]).normalized() * 3.0))
	for name in PORTES:
		var spec: Array = PORTES[name]
		var where: String = spec[0]
		var p: Vector3
		if where == "b":
			p = bulle_doors[int(spec[1])]
		elif where == "o":
			p = objets[str(spec[1])]
		elif where == "s":
			p = PC(S_C, float(spec[1]), float(spec[2]))
		elif where == "i":
			p = PC(I_C, float(spec[1]), float(spec[2]))
		else:
			p = PR(float(spec[1]), float(spec[2]))
		_door(str(name), p)


func _lumieres() -> void:
	for g in kit.glows115:
		_light(g[0], g[1], float(g[2]) * 0.6, float(g[2]), float(g[3]))
	# dehors : quelques projecteurs qui éclairent le fond, au pied des tambours
	for spec in [[Vector2.ZERO, R_G, [20.0, 140.0, 250.0, 330.0]], [S_C, R_SAT, [120.0, 240.0]], [I_C, R_SAT, [0.0, 60.0, 300.0]]]:
		for a in spec[2]:
			var pos: Vector3 = PC(spec[0], float(a), float(spec[1]) + 7.0, 4.0)
			var l := _light(pos, Color(0.8, 0.92, 1.0), 2.2, 2.2, 26.0)
			l.light_specular = 0.2


## La bouée-phare de la Cheminée d'Air, à la surface (dans surface_root : elle reste visible d'en haut).
func _bouee() -> void:
	if surface_root == null:
		return
	var b := Node3D.new()
	b.name = "Bouee_de_la_Cheminee"
	surface_root.add_child(b)
	var top: Vector3 = Vector3(F.O.x, -0.42, F.O.z)
	var bk = Kit.new()
	bk.setup(b, main.get("temps_v56") if main != null else null)
	# le haut de la Cheminée d'Air (on le voit en plongeant, on peut le toucher) et ses anneaux de
	# lumière (la nuit, de la falaise, on voit des lumières dans la mer)
	var c0: Vector3 = P(0, 0, COL_SPLIT)
	bk.cyl(Transform3D(Basis(), c0), 2.05, 2.0, top.y - c0.y - 0.2, "nacre115", 24, false, 3.0)
	bk.col_cyl(c0, 2.1, top.y - c0.y)
	var yy: float = c0.y + 6.0
	while yy < top.y - 2.0:
		bk.ring(Transform3D(Basis(), Vector3(top.x, yy, top.z)), 2.0, 2.35, 0.25, "led115_cyan", 24)
		yy += 7.0
	bk.cyl(Transform3D(Basis(), top + Vector3.DOWN * 1.4), 3.2, 3.2, 2.0, "nacre115", 32, true, 2.0)
	bk.ring(Transform3D(Basis(), top + Vector3.UP * 0.2), 3.15, 3.3, 0.25, "jaune115", 32)
	bk.cyl(Transform3D(Basis(), top + Vector3.UP * 0.6), 1.4, 1.1, 2.4, "nacre115", 20, true, 2.0)
	for k in range(3):
		bk.cyl(Transform3D(Basis(Vector3.UP, TAU * k / 3.0), top + Vector3.UP * 0.6 + Vector3(cos(TAU * k / 3.0), 0, sin(TAU * k / 3.0)) * 1.8), 0.2, 0.2, 2.4, "titane115_clair", 8, false)
	bk.cyl(Transform3D(Basis(), top + Vector3.UP * 3.0), 0.12, 0.08, 5.0, "titane115_clair", 8, false)
	bk.ball(Transform3D(Basis(), top + Vector3.UP * 8.2), 0.45, "led115_cyan", 12, 6)
	bk.ring(Transform3D(Basis(), top + Vector3.UP * 3.0), 1.0, 1.5, 0.3, "titane115_clair", 20)
	bk.col_cyl(top + Vector3.DOWN * 1.4, 3.3, 2.8)
	bk.commit()
	bouee_light = OmniLight3D.new()
	bouee_light.light_color = Color(0.4, 0.95, 1.0)
	bouee_light.light_energy = 2.0
	bouee_light.omni_range = 26.0
	b.add_child(bouee_light)
	bouee_light.global_position = top + Vector3.UP * 8.2


# =================================================================== le verre (la mer derrière)

## Les volumes d'air (dômes, galeries, tube) et la lumière de la Perle, pour le verre.
func set_glass(night: float) -> void:
	var m: ShaderMaterial = kit.mat("verre115") as ShaderMaterial
	if m == null:
		return
	var ell_c: Array = []
	var ell_r: Array = []
	for spec in [[Vector2.ZERO, R_G, H_CAP_G], [S_C, R_SAT, H_CAP_S], [I_C, R_SAT, H_CAP_S]]:
		var cc: Vector3 = P((spec[0] as Vector2).x, (spec[0] as Vector2).y, H_DRUM)
		ell_c.append(Vector4(cc.x, cc.y, cc.z, H_DRUM))
		ell_r.append(Vector4(float(spec[1]) + 0.3, float(spec[2]) + 0.3, float(spec[1]) + 0.3, 0.0))
	ell_c.append(Vector4.ZERO)
	ell_r.append(Vector4(1, 1, 1, 0))
	var cap_a: Array = []
	var cap_b: Array = []
	for c2 in [S_C, I_C]:
		var d: Vector3 = dirv(ang_to(Vector2.ZERO, c2))
		var a: Vector3 = P(0, 0) + d * (R_G - 1.0) + Vector3.UP * GAL_AXE
		var b: Vector3 = P(c2.x, c2.y) - d * (R_SAT - 1.0) + Vector3.UP * GAL_AXE
		cap_a.append(Vector4(a.x, a.y, a.z, R_GAL + 0.1))
		cap_b.append(Vector4(b.x, b.y, b.z, 0.0))
	var dl: Vector3 = dirv(A_GARE)
	var q0: Vector3 = P(0, 0) + dl * (R_G - 1.0) + Vector3.UP * F.AXE_BAS
	var q1: Vector3 = P(0, 0) + dl * F.L_FLAT + Vector3.UP * F.AXE_BAS
	var q2: Vector3 = P(0, 0) + dl * F.L_PORTAL + Vector3.UP * F.AXE_HAUT
	var q3: Vector3 = P(0, 0) + dl * F.L_END + Vector3.UP * F.AXE_HAUT
	for seg in [[q0, q1], [q1, q2], [q2, q3]]:
		cap_a.append(Vector4((seg[0] as Vector3).x, (seg[0] as Vector3).y, (seg[0] as Vector3).z, R_FUNI + 0.1))
		cap_b.append(Vector4((seg[1] as Vector3).x, (seg[1] as Vector3).y, (seg[1] as Vector3).z, 0.0))
	cap_a.append(Vector4.ZERO)
	cap_b.append(Vector4.ZERO)
	m.set_shader_parameter("n_ell", 3)
	m.set_shader_parameter("ell_c", PackedVector4Array(ell_c))
	m.set_shader_parameter("ell_r", PackedVector4Array(ell_r))
	m.set_shader_parameter("n_cap", 5)
	m.set_shader_parameter("cap_a", PackedVector4Array(cap_a))
	m.set_shader_parameter("cap_b", PackedVector4Array(cap_b))
	m.set_shader_parameter("lumiere_pos", objets.get("perle", P(0, 0, PERLE_Y)))
	night_glass(night)


func night_glass(night: float) -> void:
	var m: ShaderMaterial = kit.mat("verre115") as ShaderMaterial
	if m == null:
		return
	m.set_shader_parameter("jour", 1.0 - night * 0.85)
	m.set_shader_parameter("lumiere_force", lerpf(1.0, 0.45, night))
	m.set_shader_parameter("lumiere_col", Color(1.0, 0.93, 0.8).lerp(Color(0.6, 0.55, 1.0), night))


# =================================================================== les zones

static func _seg_dist(p: Vector3, a: Vector3, b: Vector3) -> float:
	var ab: Vector3 = b - a
	var t: float = clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	return p.distance_to(a + ab * t)


## Dans l'air (un dôme, une galerie, le tube ou le tunnel du Funiculaire) ? (sinon : dans l'eau)
func inside_air(p: Vector3) -> bool:
	var l: Vector3 = F.L(p)
	if l.y < -4.0:
		return false
	for spec in [[Vector2.ZERO, R_G, H_CAP_G], [S_C, R_SAT, H_CAP_S], [I_C, R_SAT, H_CAP_S]]:
		var c: Vector2 = spec[0]
		var rr: float = Vector2(l.x - c.x, l.z - c.y).length()
		var R: float = float(spec[1]) + 1.0
		if rr < R:
			if l.y <= H_DRUM:
				return true
			if pow(rr / R, 2.0) + pow((l.y - H_DRUM) / (float(spec[2]) + 1.0), 2.0) < 1.0:
				return true
	for c2 in [S_C, I_C]:
		var d: Vector3 = dirv(ang_to(Vector2.ZERO, c2))
		var a: Vector3 = d * (R_G - 1.0) + Vector3.UP * GAL_AXE
		var b: Vector3 = Vector3(c2.x, GAL_AXE, c2.y) - d * (R_SAT - 1.0)
		if _seg_dist(l, a, b) < R_GAL + 1.0:
			return true
	var dl: Vector3 = dirv(A_GARE)
	var pts: Array = [dl * (R_G - 1.0) + Vector3.UP * F.AXE_BAS, dl * F.L_FLAT + Vector3.UP * F.AXE_BAS, dl * F.L_PORTAL + Vector3.UP * F.AXE_HAUT, dl * F.L_END + Vector3.UP * F.AXE_HAUT]
	for k in range(3):
		if _seg_dist(l, pts[k], pts[k + 1]) < R_FUNI + 1.2:
			return true
	return false


func zone_at(p: Vector3) -> String:
	var l: Vector3 = F.L(p)
	var l2 := Vector2(l.x, l.z)
	if ligne != null and ligne.in_cabin(p):
		return "da_funiculaire"
	if l2.distance_to(S_C) < R_SAT + 0.5:
		return "da_serres"
	if l2.distance_to(I_C) < R_SAT + 0.5:
		var bc: Vector3 = F.L(objets.get("bassin", Vector3.ZERO))
		if l2.distance_to(Vector2(bc.x, bc.z)) < POOL_R + 4.0:
			return "da_bassin"
		if l2.distance_to(I_C) < 12.5:
			return "da_aquarium"
		return "da_institut"
	var r: float = l2.length()
	if r > R_G + 0.5:
		return "da_galerie" if l.y < 8.0 and (r < 100.0) and (absf(l.z) < 30.0) else "da_funiculaire"
	if _in_station(rad_to_deg(atan2(l.z, l.x)), r):
		return "da_gare"
	for k in [["conque", "da_conque", 9.5], ["comptoir", "da_comptoir", 8.0], ["atelier", "da_atelier", 9.0], ["ecole", "da_ecole", 10.0],
			["conseil", "da_conseil", 10.0], ["jardin", "da_jardin", 10.0]]:
		var o: Vector3 = objets.get(str(k[0]), Vector3.INF)
		if o != Vector3.INF and Vector2(p.x - o.x, p.z - o.z).length() < float(k[2]):
			return str(k[1])
	if r < 18.0:
		return "da_place"
	var deg: float = rad_to_deg(atan2(l.z, l.x))
	if absf(wrapf(deg - 100.0, -180.0, 180.0)) < 12.0 and r > 58.0:
		return "da_belvedere"
	if r > 62.0:
		return "da_hublots"
	return "da_ville"


# =================================================================== la vie

func tick(delta: float, night: float, near: bool) -> void:
	_clock += delta
	if perle_light != null:
		perle_light.light_energy = lerpf(6.5, 2.2, night)
		perle_light.light_color = Color(1.0, 0.95, 0.86).lerp(Color(0.62, 0.56, 1.0), night)
	for l in lights:
		(l[0] as OmniLight3D).light_energy = lerpf(float(l[1]), float(l[2]), night)
	if not near:
		return
	if perle != null:
		perle.rotation.y += delta * 0.05
	_tick_poissons_cuve()
	for j in jellies_in:
		var root: Node3D = j[0]
		var home: Vector3 = j[1]
		var ph: float = float(j[2]) + _clock * 0.45
		var amp: float = j[4]
		root.global_position = home + Vector3(sin(ph * 0.7) * 0.25 * amp, sin(ph) * 0.35 * amp, cos(ph * 0.6) * 0.25 * amp)
		(j[3] as ShaderMaterial).set_shader_parameter("pulse", 0.5 + 0.5 * sin(ph * 3.0))
	if bathy != null:
		bathy.global_transform = bathy_base * Transform3D(Basis(Vector3.FORWARD, sin(_clock * 0.6) * 0.03) * Basis(Vector3.RIGHT, sin(_clock * 0.45) * 0.025), Vector3.ZERO)
