extends Node3D
## Extension « Le Château d'Ombrelac » : les intérieurs. Pour l'instant, la Grande Salle :
##  - l'estrade à l'ouest (sous la grande baie) et la table d'honneur, ses hautes chaises ;
##  - trois longues tables de chêne, leurs bancs, la vaisselle dorée, les chandeliers ;
##  - la charpente à blochets (les fermes, les aisseliers, les pannes) sous le lambris ;
##  - la grande cheminée à hotte à l'est (sous la rose), son feu qui danse ;
##  - quatre lustres de fer à bougies, suspendus à la charpente ;
##  - les bannières de l'Académie entre les baies, le tapis de l'allée.
## Les lumières (le feu, les lustres) et une sonde de reflets : le dedans est plus sombre que le
## dehors, plus chaud ; la nuit, les bougies éclairent davantage (set_nuit).
## Repère : celui du château (l'origine au centre du Roc, y = le plateau).

const Kit = preload("res://scripts/ext_chateau/archi_ombrelac.gd")

const LUMIERE := Color(1.0, 0.7, 0.42)
const AMBIANT_JOUR := Color(0.42, 0.33, 0.24)
const AMBIANT_NUIT := Color(0.07, 0.05, 0.04)

var lumieres: Array = []        # [OmniLight3D, énergie de jour, énergie de nuit]
var feu: OmniLight3D
var sonde: ReflectionProbe
var nuit: float = 0.0
## Les lieux de la salle (repère château) : nom → Vector3
var lieux: Dictionary = {}
var _t: float = 0.0
var rayons: ShaderMaterial          # (v13) les rayons de soleil des baies : éteints la nuit


## Une poutre de section s (carrée) de a à b ; « large » : l'axe des x de la section
func _poutre(k: RefCounted, m: String, a: Vector3, b: Vector3, s: float, large := Vector3.RIGHT) -> void:
	var y: Vector3 = b - a
	var lg: float = y.length()
	if lg < 0.01:
		return
	y /= lg
	var x: Vector3 = (large - y * large.dot(y)).normalized()
	if x.length_squared() < 0.5:
		x = y.cross(Vector3.FORWARD).normalized()
	var z: Vector3 = x.cross(y)
	k.box(m, Transform3D(Basis(x, y, z), a), Vector3(s, lg, s))


## Une flamme : deux quads croisés, le bas en p
func _flamme(k: RefCounted, p: Vector3, w: float, h: float) -> void:
	var g := Vector2(p.x * 3.1 + p.y, p.z * 2.7)
	for d in [Vector3.RIGHT, Vector3.BACK]:
		var e: Vector3 = d * w * 0.5
		var n: Vector3 = d.cross(Vector3.UP)
		k.quad("flamme", Transform3D.IDENTITY, p - e, p + e, p + e + Vector3(0, h, 0), p - e + Vector3(0, h, 0), n,
			Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1), g)


## Une bougie sur sa bobèche : la cire, la flamme
func _bougie(k: RefCounted, p: Vector3, hc: float = 0.22) -> void:
	k.cyl("cire", Transform3D(Basis.IDENTITY, p), 0.035, 0.032, hc, 6)
	_flamme(k, p + Vector3(0, hc + 0.005, 0), 0.07, 0.16)


## (v11) Une colonne tournée (le pied de lit, la rampe) : le dé carré du bas, le fût et ses bagues,
## les renflements ; t : le repère au pied de la colonne (y vers le haut), h sa hauteur, r son rayon
func _colonne_tournee(k: RefCounted, m: String, t: Transform3D, h: float, r: float) -> void:
	var d: float = minf(0.5, h * 0.25)
	k.box(m, t, Vector3(r * 2.2, d, r * 2.2))
	var y: float = d
	var prof := [[0.0, 0.08, 1.0, 1.25], [0.08, 0.04, 1.25, 0.8], [0.12, 0.3, 0.8, 0.6], [0.42, 0.04, 1.15, 1.15],
		[0.46, 0.14, 0.7, 1.05], [0.6, 0.14, 1.05, 0.7], [0.74, 0.04, 1.15, 1.15], [0.78, 0.22, 0.6, 0.72]]
	var reste: float = h - d
	for e in prof:
		k.cyl(m, t * Transform3D(Basis.IDENTITY, Vector3(0, y + e[0] * reste, 0)), r * e[2], r * e[3], e[1] * reste, 10, false)
	k.cyl(m, t * Transform3D(Basis.IDENTITY, Vector3(0, h, 0)), r * 0.72, r * 1.0, 0.03, 10)


## (v11) Une tenture plissée, pendue (le haut en a, le long de « le_long », vers le bas sur h) : des plis
## ronds qui se touchent, chacun un peu plus ou moins profond ; out : le côté que l'on voit
func _tenture(k: RefCounted, m: String, a: Vector3, le_long: Vector3, w: float, h: float, out: Vector3) -> void:
	var n: int = maxi(3, int(w / 0.09))
	var pas: float = w / n
	for i in range(n):
		var c: Vector3 = a + le_long * (pas * (i + 0.5)) - Vector3(0, h, 0)
		var r: float = pas * (0.55 + 0.12 * sin(i * 2.3 + a.x * 3.0))
		k.cyl(m, Transform3D(Basis.IDENTITY, c - out * r * 0.35), r, r * 0.9, h, 8, false)


## (v11) Un rideau noué à une colonne : il tombe en éventail du haut (y1), serré par l'embrasse (yn),
## s'évase vers le bas (y0) ; c : la colonne du rideau (au sol), le tout en repère monde
func _rideau_noue(k: RefCounted, m: String, c: Vector3, y0: float, yn: float, y1: float, r_haut: float, r_bas: float) -> void:
	k.cyl(m, Transform3D(Basis.IDENTITY, c + Vector3(0, yn, 0)), 0.055, r_haut, y1 - yn, 10, false)
	k.cyl(m, Transform3D(Basis.IDENTITY, c + Vector3(0, y0, 0)), r_bas, 0.055, yn - y0, 10, true)
	# l'embrasse : un cordon d'or et son gland
	k.cyl("or", Transform3D(Basis.IDENTITY, c + Vector3(0, yn - 0.03, 0)), 0.065, 0.065, 0.06, 10)
	k.cyl("or", Transform3D(Basis.IDENTITY, c + Vector3(0.07, yn - 0.2, 0)), 0.012, 0.028, 0.14, 6)


## (v11) Un livre ouvert posé (t : le milieu du dessous ; w × d : sa taille ouvert) : la reliure, les
## deux blocs de pages qui montent vers le dos, les lignes d'écriture, le signet
func _livre_ouvert(k: RefCounted, t: Transform3D, w: float, d: float, cuir: String = "velours_pourpre") -> void:
	if w > d:
		t = t * Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3.ZERO)
		var tmp: float = w
		w = d
		d = tmp
	# le dos le long de x ; les pages vers ±z
	k.box(cuir, t, Vector3(w + 0.02, 0.008, d + 0.02))
	for e in [-1.0, 1.0]:
		var tp: Transform3D = t * Transform3D(Basis(Vector3.RIGHT, e * 0.07), Vector3(0, 0.008, e * d * 0.245))
		k.box("drap", tp, Vector3(w, 0.016, d * 0.48))
		for i in range(7):
			var lx: float = -w * 0.36 + i * w * 0.12
			var ll: float = d * (0.34 if i < 6 else 0.2)
			k.box("suie", tp * Transform3D(Basis.IDENTITY, Vector3(lx, 0.016, -e * (d * 0.24 - ll * 0.5 - d * 0.06))), Vector3(0.005, 0.0015, ll))
	k.box("velours_bleu", t * Transform3D(Basis.IDENTITY, Vector3(w * 0.15, 0.025, 0.0)), Vector3(0.012, 0.002, d * 0.02 + 0.01))
	k.box("velours_bleu", t * Transform3D(Basis.IDENTITY, Vector3(w * 0.5 + 0.03, -0.03, 0.0)), Vector3(0.012, 0.055, 0.004))


## (v11) Un livre fermé, posé à plat (t : le milieu du dessous ; taille : largeur, épaisseur, hauteur) :
## les plats de la reliure, le dos arrondi, la tranche des pages, les nerfs dorés du dos
func _livre_ferme(k: RefCounted, t: Transform3D, taille: Vector3, cuir: String) -> void:
	var w: float = taille.x
	var h: float = taille.y
	var d: float = taille.z
	for y in [0.0, h - 0.006]:
		k.box(cuir, t * Transform3D(Basis.IDENTITY, Vector3(0, y, 0)), Vector3(w, 0.006, d))
	k.box("drap", t * Transform3D(Basis.IDENTITY, Vector3(0.004, 0.006, 0)), Vector3(w - 0.016, h - 0.012, d - 0.012))
	k.box(cuir, t * Transform3D(Basis.IDENTITY, Vector3(-w * 0.5 + 0.004, 0, 0)), Vector3(0.012, h, d))
	for i in range(3):
		k.box("or", t * Transform3D(Basis.IDENTITY, Vector3(-w * 0.5 - 0.0025, h * 0.2, -d * 0.3 + i * d * 0.3)), Vector3(0.003, h * 0.6, 0.008))


## (v12) Un banc à dossier contre un mur (t : le milieu du pied, au sol ; x le long, z+ vers la salle) :
## l'assise, son coussin de velours, les pieds tournés, le dossier à panneaux, les accoudoirs
func _banc(k: RefCounted, t: Transform3D, lg: float, velours: String = "velours_bleu") -> void:
	var n: int = maxi(2, int(lg / 1.1) + 1)
	for i in range(n):
		var x: float = -lg * 0.5 + 0.08 + (lg - 0.16) * i / (n - 1)
		_colonne_tournee(k, "chene", t * Transform3D(Basis.IDENTITY, Vector3(x, 0, 0.17)), 0.4, 0.035)
		k.box("chene", t * Transform3D(Basis.IDENTITY, Vector3(x, 0, -0.18)), Vector3(0.07, 0.4, 0.07))
		k.box("chene", t * Transform3D(Basis.IDENTITY, Vector3(x, 0.1, 0)), Vector3(0.04, 0.04, 0.36))
	k.box("chene", t * Transform3D(Basis.IDENTITY, Vector3(0, 0.4, 0)), Vector3(lg, 0.05, 0.46), true)
	k.box("chene", t * Transform3D(Basis.IDENTITY, Vector3(0, 0.34, 0.215)), Vector3(lg - 0.1, 0.06, 0.02))
	k.box(velours, t * Transform3D(Basis.IDENTITY, Vector3(0, 0.45, 0.02)), Vector3(lg - 0.12, 0.05, 0.4))
	k.cyl(velours, t * Transform3D(Basis(Vector3.BACK, -PI * 0.5), Vector3(-lg * 0.5 + 0.06, 0.475, 0.22)), 0.025, 0.025, lg - 0.12, 8, false)
	# le dossier : le cadre, les panneaux en relief, la corniche
	k.box("chene", t * Transform3D(Basis.IDENTITY, Vector3(0, 0.45, -0.21)), Vector3(lg, 0.75, 0.05))
	var np: int = maxi(1, int(lg / 0.6))
	for j in range(np):
		var px: float = -lg * 0.5 + (j + 0.5) * lg / np
		k.box("bois", t * Transform3D(Basis.IDENTITY, Vector3(px, 0.55, -0.18)), Vector3(lg / np - 0.12, 0.5, 0.015))
	k.box("chene", t * Transform3D(Basis.IDENTITY, Vector3(0, 1.2, -0.2)), Vector3(lg + 0.06, 0.05, 0.1))
	for e in [-1.0, 1.0]:
		k.box("chene", t * Transform3D(Basis.IDENTITY, Vector3(e * (lg * 0.5 - 0.03), 0.45, 0.0)), Vector3(0.05, 0.25, 0.44))
		k.cyl("chene", t * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(e * (lg * 0.5 - 0.03), 0.7, -0.22)), 0.04, 0.04, 0.46, 8)


## (v12) Un coffre ferré (t : le milieu du dessous ; z+ : sa face) : le corps, le couvercle, les
## bandes et les coins de fer, la serrure, les poignées, les petits pieds
func _coffre_ferre(k: RefCounted, t: Transform3D, w: float, h: float, d: float, collide: bool = true) -> void:
	for ex in [-1.0, 1.0]:
		for ez in [-1.0, 1.0]:
			k.box("chene", t * Transform3D(Basis.IDENTITY, Vector3(ex * (w * 0.5 - 0.05), 0, ez * (d * 0.5 - 0.05))), Vector3(0.08, 0.05, 0.08))
	k.box("bois", t * Transform3D(Basis.IDENTITY, Vector3(0, 0.05, 0)), Vector3(w, h - 0.15, d), collide)
	k.box("chene", t * Transform3D(Basis.IDENTITY, Vector3(0, h - 0.1, 0)), Vector3(w + 0.04, 0.1, d + 0.04))
	k.box("chene", t * Transform3D(Basis.IDENTITY, Vector3(0, h - 0.13, 0)), Vector3(w + 0.02, 0.03, d + 0.02))
	var nb: int = maxi(2, int(w / 0.45) + 1)
	for i in range(nb):
		var x: float = -w * 0.5 + 0.08 + (w - 0.16) * i / (nb - 1)
		k.box("fer", t * Transform3D(Basis.IDENTITY, Vector3(x, 0.045, 0)), Vector3(0.05, h - 0.04, d + 0.03))
	for ex2 in [-1.0, 1.0]:
		for ez2 in [-1.0, 1.0]:
			k.box("fer", t * Transform3D(Basis.IDENTITY, Vector3(ex2 * (w * 0.5 - 0.02), 0.045, ez2 * (d * 0.5 - 0.02))), Vector3(0.07, h - 0.04, 0.07))
		k.box("fer", t * Transform3D(Basis.IDENTITY, Vector3(ex2 * (w * 0.5 + 0.015), h * 0.6, 0)), Vector3(0.02, 0.03, 0.2))
		for ez3 in [-0.08, 0.08]:
			k.box("fer", t * Transform3D(Basis.IDENTITY, Vector3(ex2 * (w * 0.5 + 0.015), h * 0.6 - 0.06, ez3)), Vector3(0.02, 0.07, 0.02))
	k.box("or", t * Transform3D(Basis.IDENTITY, Vector3(0, h * 0.62, d * 0.5 + 0.01)), Vector3(0.13, 0.16, 0.015))
	k.box("suie", t * Transform3D(Basis.IDENTITY, Vector3(0, h * 0.66, d * 0.5 + 0.018)), Vector3(0.02, 0.05, 0.004))


## (v12) Un tabouret (t : au sol) : trois pieds tournés écartés, l'entretoise, l'assise ronde
func _tabouret(k: RefCounted, t: Transform3D, h: float = 0.5) -> void:
	for i in range(3):
		var a: float = TAU * i / 3.0 + 0.5
		_poutre(k, "chene", t * Vector3(cos(a) * 0.19, 0, sin(a) * 0.19), t * Vector3(cos(a) * 0.12, h - 0.03, sin(a) * 0.12), 0.04)
		_poutre(k, "chene", t * Vector3(cos(a) * 0.16, h * 0.3, sin(a) * 0.16), t * Vector3(cos(a + TAU / 3.0) * 0.16, h * 0.3, sin(a + TAU / 3.0) * 0.16), 0.022)
	k.cyl("chene", t * Transform3D(Basis.IDENTITY, Vector3(0, h - 0.04, 0)), 0.19, 0.2, 0.045, 16, true, true)


## (v11) Un encrier et sa plume d'oie (p : le dessous de l'encrier, en repère monde)
func _encrier(k: RefCounted, p: Vector3) -> void:
	k.cyl("verre", Transform3D(Basis.IDENTITY, p), 0.038, 0.034, 0.05, 10)
	k.cyl("suie", Transform3D(Basis.IDENTITY, p + Vector3(0, 0.004, 0)), 0.03, 0.028, 0.04, 10)
	k.cyl("or", Transform3D(Basis.IDENTITY, p + Vector3(0, 0.05, 0)), 0.026, 0.018, 0.012, 10)
	var dir := Vector3(0.25, 1.0, 0.35).normalized()
	var a: Vector3 = p + Vector3(0, 0.02, 0)
	_poutre(k, "drap", a, a + dir * 0.32, 0.005)
	var cote: Vector3 = dir.cross(Vector3.UP).normalized()
	for e in [-1.0, 1.0]:
		var b0: Vector3 = a + dir * 0.1
		var b1: Vector3 = a + dir * 0.33
		k.quad("drap", Transform3D.IDENTITY, b0, b1, b1 + cote * e * 0.012, b0 + dir * 0.06 + cote * e * 0.03, Vector3.UP)


func _lumiere(p: Vector3, portee: float, jour: float, nuit_e: float) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.position = p
	l.light_color = LUMIERE
	l.omni_range = portee
	l.omni_attenuation = 1.2
	l.light_energy = jour
	l.shadow_enabled = false
	l.light_specular = 0.4
	add_child(l)
	lumieres.append([l, jour, nuit_e])
	return l


# =================================================================== la Grande Salle

## c : le centre de la salle au sol ; L x W x H : le dehors des murs ; T : leur épaisseur ;
## voute : la hauteur du lambris au faîte (au-dessus de H) ; bx : les x des baies
func grande_salle(c: Vector3, L: float, W: float, H: float, T: float, voute: float, bx: Array) -> void:
	var k := Kit.new()
	var hl: float = L * 0.5 - T          # le dedans : x de -hl à hl
	var hw: float = W * 0.5 - T          # z de c.z - hw à c.z + hw
	_charpente(k, c, L, hl, hw, H, voute)
	_estrade(k, c, hl, hw)
	_tables(k, c, hl, hw)
	_cheminee(k, c, hl, hw)
	_lustres(k, c, H, voute, hw)
	_bannieres(k, c, L, hl, hw, bx)
	_rayons(c, hw, bx)
	# le tapis de l'allée : de la porte jusqu'au mur nord
	k.quad("tapis", Transform3D.IDENTITY, Vector3(-1.3, 0.012, c.z + hw - 0.3), Vector3(1.3, 0.012, c.z + hw - 0.3),
		Vector3(1.3, 0.012, c.z - hw + 0.6), Vector3(-1.3, 0.012, c.z - hw + 0.6), Vector3.UP,
		Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1))
	var mi: MeshInstance3D = k.commit("Ombrelac_salle_meubles")
	mi.visibility_range_end = 160.0
	add_child(mi)
	if not k.shapes.is_empty():
		add_child(k.body("Ombrelac_salle_meubles_col"))
	# la sonde : un dedans (pas de ciel), une lumière ambiante chaude et faible
	sonde = ReflectionProbe.new()
	sonde.name = "Ombrelac_salle_sonde"
	sonde.position = Vector3(c.x, (H + voute) * 0.5 - 1.0, c.z)
	sonde.size = Vector3(hl * 2.0, H + voute + 3.0, hw * 2.0)
	sonde.interior = true
	sonde.box_projection = true
	sonde.ambient_mode = ReflectionProbe.AMBIENT_COLOR
	sonde.ambient_color = AMBIANT_JOUR
	sonde.ambient_color_energy = 1.0
	sonde.update_mode = ReflectionProbe.UPDATE_ONCE
	sonde.max_distance = 80.0
	sonde.blend_distance = 0.5
	add_child(sonde)
	lieux["salle"] = c
	lieux["table_honneur"] = Vector3(-hl + 3.2, 0.6, c.z)
	lieux["cheminee"] = Vector3(hl - 3.0, 0.0, c.z)


## (v13) Les rayons de soleil : depuis les baies du côté sud (le soleil de midi), un volume oblique
## de lumière poudreuse qui descend vers l'allée. Ajouté à l'image, sans ombre, éteint la nuit.
func _rayons(c: Vector3, hw: float, bx: Array) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var d: Vector3 = Vector3(0.12, -0.72, -0.68).normalized()
	var lg: float = 15.0
	for x in bx:
		if absf(x) < 6.0:
			continue
		var z: float = c.z + hw - 0.2
		# la baie : 2,2 m de large, de 6,6 à 16 m de haut (le rayon part du haut de l'embrasure)
		var a := [Vector3(x - 1.1, 6.6, z), Vector3(x + 1.1, 6.6, z), Vector3(x + 1.1, 16.0, z), Vector3(x - 1.1, 16.0, z)]
		# les quatre faces du volume (UV.x le long du rayon, UV.y en travers)
		for f in range(4):
			var p0: Vector3 = a[f]
			var p1: Vector3 = a[(f + 1) % 4]
			var q0: Vector3 = p0 + d * lg
			var q1: Vector3 = p1 + d * lg
			var nrm: Vector3 = (p1 - p0).cross(d).normalized()
			for v in [[p0, Vector2(0, 0)], [p1, Vector2(0, 1)], [q1, Vector2(1, 1)], [p0, Vector2(0, 0)], [q1, Vector2(1, 1)], [q0, Vector2(1, 0)]]:
				st.set_normal(nrm)
				st.set_uv(v[1])
				st.add_vertex(v[0])
		# une nappe au milieu, pour que le rayon se voie aussi de face
		var m0: Vector3 = (a[0] + a[3]) * 0.5
		var m1: Vector3 = (a[1] + a[2]) * 0.5
		var mid: Array = [[a[0].lerp(a[1], 0.5), Vector2(0, 0)], [a[3].lerp(a[2], 0.5), Vector2(0, 1)], [a[3].lerp(a[2], 0.5) + d * lg, Vector2(1, 1)],
			[a[0].lerp(a[1], 0.5), Vector2(0, 0)], [a[3].lerp(a[2], 0.5) + d * lg, Vector2(1, 1)], [a[0].lerp(a[1], 0.5) + d * lg, Vector2(1, 0)]]
		for v2 in mid:
			st.set_normal((m1 - m0).normalized())
			st.set_uv(v2[1])
			st.add_vertex(v2[0])
	rayons = ShaderMaterial.new()
	rayons.shader = load("res://shaders/ext_chateau/ombrelac_rayon.gdshader")
	var mesh: ArrayMesh = st.commit()
	mesh.surface_set_material(0, rayons)
	var mi := MeshInstance3D.new()
	mi.name = "Ombrelac_salle_rayons"
	mi.mesh = mesh
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.visibility_range_end = 120.0
	add_child(mi)


## La charpente : à chaque travée une ferme à blochets (les poteaux sur leurs corbeaux, les
## blochets en porte-à-faux, les aisseliers courbes jusqu'à l'entrait retroussé), des pannes
func _charpente(k: RefCounted, c: Vector3, L: float, hl: float, hw: float, H: float, voute: float) -> void:
	var lambris := func(dz: float) -> float:
		return H + voute * (1.0 - absf(dz) / hw)
	for i in range(1, 8):
		var x: float = -L * 0.5 + 0.7 + i * (L - 1.4) / 8.0
		for s in [-1.0, 1.0]:
			var zw: float = c.z + s * (hw - 0.22)
			# le corbeau de pierre, le poteau
			k.box("pierre_claire", Transform3D(Basis.IDENTITY, Vector3(x, H - 4.4, c.z + s * (hw - 0.4))), Vector3(0.7, 0.9, 0.8))
			_poutre(k, "chene", Vector3(x, H - 3.5, zw), Vector3(x, H + 0.2, zw), 0.38)
			# le blochet (en porte-à-faux) et son poinçon
			var zb: float = c.z + s * (hw - 2.4)
			_poutre(k, "chene", Vector3(x, H, c.z + s * hw), Vector3(x, H, zb), 0.36, Vector3.UP)
			_poutre(k, "chene", Vector3(x, H - 0.6, zb), Vector3(x, lambris.call(hw - 2.4) - 0.1, zb), 0.32)
			# l'aisselier du bas (du poteau au bout du blochet), en quart de cercle
			var prev := Vector3(x, H - 3.0, zw)
			for j in range(1, 7):
				var a: float = PI * 0.5 * j / 6.0
				var p := Vector3(x, H - 3.0 + 3.0 * sin(a), c.z + s * ((hw - 0.22) - 2.1 * (1.0 - cos(a))))
				_poutre(k, "chene", prev, p, 0.26)
				prev = p
			# le grand aisselier (du blochet à l'entrait) : un arc brisé
			var ze: float = voute * 0.62
			var ye: float = H + ze
			var zt: float = hw * (1.0 - ze / voute)
			prev = Vector3(x, H + 0.5, zb)
			for j in range(1, 9):
				var u: float = float(j) / 8.0
				var a2: float = PI * 0.5 * u
				var p2 := Vector3(x, H + 0.5 + (ye - H - 0.5) * sin(a2), c.z + s * ((hw - 2.4) * cos(a2) + 0.0 * u))
				_poutre(k, "chene", prev, p2, 0.3)
				prev = p2
			# l'arbalétrier, sous le lambris
			_poutre(k, "chene", Vector3(x, H + 0.05, c.z + s * (hw - 0.05)), Vector3(x, H + voute - 0.25, c.z), 0.34)
			# l'entrait retroussé
			if s > 0:
				_poutre(k, "chene", Vector3(x, ye, c.z - zt), Vector3(x, ye, c.z + zt), 0.34, Vector3.UP)
	# les pannes (sous le lambris, d'un pignon à l'autre) et la panne faîtière
	for f in [0.3, 0.62]:
		for s in [-1.0, 1.0]:
			var dz: float = hw * (1.0 - f)
			var y: float = lambris.call(dz) - 0.3
			_poutre(k, "chene", Vector3(-hl, y, c.z + s * dz), Vector3(hl, y, c.z + s * dz), 0.3, Vector3.UP)
	_poutre(k, "chene", Vector3(-hl, H + voute - 0.4, c.z), Vector3(hl, H + voute - 0.4, c.z), 0.36, Vector3.UP)


## L'estrade à l'ouest : deux marches, la table d'honneur (en travers), ses hautes chaises
func _estrade(k: RefCounted, c: Vector3, hl: float, hw: float) -> void:
	var x1: float = -hl + 5.4
	k.box("pierre_claire", Transform3D(Basis.IDENTITY, Vector3((-hl + x1) * 0.5, 0.0, c.z)), Vector3(x1 + hl, 0.6, hw * 2.0), true)
	k.box("pierre_claire", Transform3D(Basis.IDENTITY, Vector3(x1 + 0.4, 0.0, c.z)), Vector3(0.8, 0.3, hw * 2.0 - 4.0), true)
	k.box("bois", Transform3D(Basis.IDENTITY, Vector3((-hl + x1) * 0.5, 0.6, c.z)), Vector3(x1 + hl - 0.4, 0.04, hw * 2.0 - 0.6))
	var xt: float = -hl + 3.2
	_table(k, Vector3(xt, 0.64, c.z), 13.0, 1.4, true)
	# les chaises, face à la salle ; celle du milieu plus haute (la directrice de l'Académie)
	for i in range(9):
		var z: float = c.z + (i - 4) * 1.4
		var haut: float = 2.9 if i == 4 else 1.7
		var xc: float = xt - 1.15
		k.box("bois", Transform3D(Basis.IDENTITY, Vector3(xc, 0.64, z)), Vector3(0.55, 0.48, 0.55))
		k.box("bois", Transform3D(Basis.IDENTITY, Vector3(xc - 0.26, 0.64, z)), Vector3(0.08, haut, 0.55))
		if i == 4:
			k.cyl("or", Transform3D(Basis.IDENTITY, Vector3(xc - 0.26, 0.64 + haut, z)), 0.16, 0.0, 0.4, 8)
	lieux["estrade"] = Vector3(xt - 0.2, 0.64, c.z)


## Une table de chêne : le plateau (le long de x, ou de z si « travers »), les tréteaux ; les
## couverts dorés ; des chandeliers sur la ligne du milieu
func _table(k: RefCounted, p: Vector3, lg: float, lar: float, travers: bool = false) -> void:
	var ax := Vector3(0, 0, 1) if travers else Vector3(1, 0, 0)
	var sx := Vector3(1, 0, 0) if travers else Vector3(0, 0, 1)
	var yaw: float = PI * 0.5 if travers else 0.0
	var b := Basis(Vector3.UP, yaw)
	k.box("bois", Transform3D(b, p + Vector3(0, 0.7, 0)), Vector3(lg, 0.09, lar), true)
	var n: int = maxi(2, int(lg / 3.2) + 1)
	for i in range(n):
		var q: Vector3 = p + ax * lerpf(-lg * 0.5 + 0.5, lg * 0.5 - 0.5, float(i) / (n - 1))
		k.box("bois", Transform3D(b, q), Vector3(0.12, 0.7, lar * 0.7))
		k.box("bois", Transform3D(b, q), Vector3(0.18, 0.1, lar * 0.85))
	k.box("bois", Transform3D(b, p + Vector3(0, 0.22, 0)), Vector3(lg - 1.0, 0.1, 0.1))
	# (v11) la ceinture sous le plateau, le chemin de table de velours (il retombe aux deux bouts)
	for s2 in [-1.0, 1.0]:
		k.box("bois", Transform3D(b, p + sx * s2 * (lar * 0.5 - 0.06) + Vector3(0, 0.6, 0)), Vector3(lg - 0.3, 0.1, 0.04))
	var chemin: String = "velours_pourpre" if travers else "velours_bleu"
	k.box(chemin, Transform3D(b, p + Vector3(0, 0.79, 0)), Vector3(lg + 0.02, 0.006, 0.46))
	for e2 in [-1.0, 1.0]:
		k.box(chemin, Transform3D(b, p + ax * e2 * (lg * 0.5 + 0.004) + Vector3(0, 0.5, 0)), Vector3(0.008, 0.296, 0.46))
	# les couverts : une assiette et un gobelet tous les 0,8 m, des deux côtés
	var m: int = int(lg / 0.8)
	for i in range(m):
		var u: float = -lg * 0.5 + 0.4 + i * 0.8
		for s in [-1.0, 1.0]:
			if travers and s > 0:
				continue
			var a: Vector3 = p + ax * u + sx * s * (lar * 0.5 - 0.25) + Vector3(0, 0.79, 0)
			# (v11) l'assiette creuse et son marli, le gobelet sur son pied, le couteau
			k.cyl("or", Transform3D(Basis.IDENTITY, a), 0.08, 0.13, 0.012, 16)
			k.cyl("or", Transform3D(Basis.IDENTITY, a + Vector3(0, 0.012, 0)), 0.13, 0.145, 0.01, 16, false)
			var g: Vector3 = a + ax * 0.24 + sx * s * 0.08
			k.cyl("or", Transform3D(Basis.IDENTITY, g), 0.035, 0.03, 0.008, 10)
			k.cyl("or", Transform3D(Basis.IDENTITY, g + Vector3(0, 0.008, 0)), 0.008, 0.008, 0.06, 6, false)
			k.cyl("or", Transform3D(Basis.IDENTITY, g + Vector3(0, 0.068, 0)), 0.012, 0.042, 0.03, 10, false)
			k.cyl("or", Transform3D(Basis.IDENTITY, g + Vector3(0, 0.098, 0)), 0.042, 0.046, 0.07, 10, false)
			k.box("fer", Transform3D(b, a - ax * 0.2 + Vector3(0, 0.004, 0)), Vector3(0.02, 0.006, 0.2))
			# un petit pain sur une assiette sur trois
			if (i + int(s > 0.0)) % 3 == 0:
				k.cyl("pain", Transform3D(Basis.IDENTITY, a + Vector3(0.02, 0.014, 0.02)), 0.045, 0.03, 0.04, 10)
	# les chandeliers à trois branches
	var nc: int = int(lg / 3.4)
	for i in range(nc):
		var cp: Vector3 = p + ax * (-lg * 0.5 + (i + 0.5) * lg / nc) + Vector3(0, 0.79, 0)
		# (v11) le pied mouluré du chandelier, et une coupe de fruits entre deux chandeliers
		k.cyl("or", Transform3D(Basis.IDENTITY, cp), 0.11, 0.1, 0.02, 12)
		k.cyl("or", Transform3D(Basis.IDENTITY, cp + Vector3(0, 0.02, 0)), 0.09, 0.03, 0.08, 12, false)
		k.cyl("or", Transform3D(Basis.IDENTITY, cp + Vector3(0, 0.1, 0)), 0.03, 0.03, 0.22, 8, false)
		k.cyl("or", Transform3D(Basis.IDENTITY, cp + Vector3(0, 0.16, 0)), 0.045, 0.045, 0.025, 10)
		if i < nc - 1 or nc == 1:
			var fp: Vector3 = cp + ax * (lg / nc * 0.5) if i < nc - 1 else cp + ax * 0.9
			_coupe_fruits(k, fp)
		for j in [-1.0, 0.0, 1.0]:
			var bp: Vector3 = cp + ax * j * 0.16 + Vector3(0, 0.32 + (0.06 if j == 0.0 else 0.0), 0)
			k.cyl("or", Transform3D(Basis.IDENTITY, bp - Vector3(0, 0.03, 0)), 0.045, 0.05, 0.03, 8)
			_bougie(k, bp, 0.2)


## (v11) Une coupe de fruits dorée : le pied, la vasque, des pommes rouges et vertes, des poires
func _coupe_fruits(k: RefCounted, p: Vector3) -> void:
	k.cyl("or", Transform3D(Basis.IDENTITY, p), 0.07, 0.05, 0.015, 12)
	k.cyl("or", Transform3D(Basis.IDENTITY, p + Vector3(0, 0.015, 0)), 0.02, 0.02, 0.07, 8, false)
	k.cyl("or", Transform3D(Basis.IDENTITY, p + Vector3(0, 0.085, 0)), 0.05, 0.17, 0.06, 16)
	var h: float = absf(sin(p.x * 3.7 + p.z * 1.3))
	for j in range(7):
		var a: float = TAU * j / 6.0 + h * 2.0
		var r: float = 0.09 if j < 6 else 0.0
		var y: float = 0.165 if j < 6 else 0.215
		var fr: String = ["pomme_rouge", "pomme_verte", "poire"][(j + int(h * 5.0)) % 3]
		_fruit(k, fr, p + Vector3(cos(a) * r, y, sin(a) * r), 0.042)


func _fruit(k: RefCounted, m: String, c: Vector3, r: float) -> void:
	var nl: int = 5
	var nm: int = 8
	var allonge: float = 1.25 if m == "poire" else 0.92
	for i in range(nl):
		var t0: float = PI * i / nl - PI * 0.5
		var t1: float = PI * (i + 1) / nl - PI * 0.5
		for j in range(nm):
			var p0: float = TAU * j / nm
			var p1: float = TAU * (j + 1) / nm
			var d := [Vector3(cos(t0) * cos(p0), sin(t0), cos(t0) * sin(p0)), Vector3(cos(t0) * cos(p1), sin(t0), cos(t0) * sin(p1)),
				Vector3(cos(t1) * cos(p1), sin(t1), cos(t1) * sin(p1)), Vector3(cos(t1) * cos(p0), sin(t1), cos(t1) * sin(p0))]
			var e := [d[0], d[1], d[2], d[3]]
			for q in range(4):
				var v: Vector3 = d[q]
				# la poire s'affine vers le haut
				var w: float = (1.0 - 0.35 * maxf(v.y, 0.0)) if m == "poire" else 1.0
				e[q] = Vector3(v.x * w, v.y * allonge, v.z * w) * r
			k.quad_smooth(m, Transform3D(Basis.IDENTITY, c), e[0], e[1], e[2], e[3], d[0], d[1], d[2], d[3])
	k.cyl("bois", Transform3D(Basis.IDENTITY, c + Vector3(0, r * allonge * 0.9, 0)), 0.004, 0.003, 0.025, 4, false)


## Trois longues tables (de part et d'autre de l'allée), leurs bancs
func _tables(k: RefCounted, c: Vector3, hl: float, hw: float) -> void:
	var xa: float = -hl + 7.0
	var xb: float = hl - 4.6
	for r in [-5.0, 0.0, 5.0]:
		var z: float = c.z + r
		for seg in [[xa, -2.6], [2.6, xb]]:
			var x0: float = seg[0]
			var x1: float = seg[1]
			var lg: float = x1 - x0
			var mid: float = (x0 + x1) * 0.5
			_table(k, Vector3(mid, 0, z), lg, 1.3)
			for s in [-1.0, 1.0]:
				var bz: float = z + s * 1.05
				k.box("bois", Transform3D(Basis.IDENTITY, Vector3(mid, 0.4, bz)), Vector3(lg, 0.07, 0.4), true)
				var n: int = int(lg / 3.0) + 1
				for i in range(n):
					var bxp: float = lerpf(x0 + 0.4, x1 - 0.4, float(i) / (n - 1))
					k.box("bois", Transform3D(Basis.IDENTITY, Vector3(bxp, 0.0, bz)), Vector3(0.09, 0.4, 0.32))
	# un peu de lumière au-dessus des tables (les chandeliers)
	for xl in [(xa - 2.6) * 0.5, (2.6 + xb) * 0.5]:
		_lumiere(Vector3(xl, 1.8, c.z), 11.0, 0.5, 1.0)


## La grande cheminée : les piédroits, le manteau, la hotte qui monte en se resserrant, le contre-
## cœur noirci, les chenets, les bûches, le feu
func _cheminee(k: RefCounted, c: Vector3, hl: float, hw: float) -> void:
	var xm: float = hl                     # la face du mur
	var d: float = 1.6                     # la saillie
	var lw: float = 6.0                    # la largeur du manteau
	for s in [-1.0, 1.0]:
		k.box("pierre_claire", Transform3D(Basis.IDENTITY, Vector3(xm - d * 0.5, 0.0, c.z + s * (lw * 0.5 - 0.45))), Vector3(d, 2.7, 0.9), true)
		k.box("pierre_claire", Transform3D(Basis.IDENTITY, Vector3(xm - d * 0.5 - 0.06, 2.45, c.z + s * (lw * 0.5 - 0.45))), Vector3(d + 0.14, 0.25, 1.0))
	k.box("pierre_claire", Transform3D(Basis.IDENTITY, Vector3(xm - d * 0.5, 2.7, c.z)), Vector3(d + 0.2, 0.75, lw + 0.3), true)
	k.box("pierre_claire", Transform3D(Basis.IDENTITY, Vector3(xm - d * 0.5 - 0.1, 3.45, c.z)), Vector3(d + 0.35, 0.2, lw + 0.5))
	# la hotte : un tronc de pyramide jusqu'au-dessous de la rose
	var y0: float = 3.65
	var y1: float = 7.4
	var a0: Vector3 = Vector3(xm - d, y0, c.z - lw * 0.5)
	var b0: Vector3 = Vector3(xm - d, y0, c.z + lw * 0.5)
	var a1: Vector3 = Vector3(xm - 0.7, y1, c.z - 1.6)
	var b1: Vector3 = Vector3(xm - 0.7, y1, c.z + 1.6)
	k.quad("pierre_int", Transform3D.IDENTITY, a0, b0, b1, a1, Vector3(-1, 0.2, 0))
	for s in [-1.0, 1.0]:
		var e0: Vector3 = a0 if s < 0 else b0
		var e1: Vector3 = a1 if s < 0 else b1
		k.quad("pierre_int", Transform3D.IDENTITY, e0, Vector3(xm, y0, e0.z), Vector3(xm, y1, e1.z), e1, Vector3(0, 0, s))
	k.quad("pierre_claire", Transform3D.IDENTITY, a1, b1, Vector3(xm, y1, b1.z), Vector3(xm, y1, a1.z), Vector3.UP)
	# le foyer : le contrecœur, l'âtre, les chenets, les bûches
	k.box("suie", Transform3D(Basis.IDENTITY, Vector3(xm - 0.05, 0.0, c.z)), Vector3(0.1, 2.7, lw - 1.8))
	for s in [-1.0, 1.0]:
		k.box("suie", Transform3D(Basis.IDENTITY, Vector3(xm - d * 0.5, 0.0, c.z + s * (lw * 0.5 - 0.91))), Vector3(d, 2.7, 0.02))
	k.box("suie", Transform3D(Basis.IDENTITY, Vector3(xm - d * 0.5, 2.68, c.z)), Vector3(d, 0.02, lw - 1.8))
	k.box("pierre_claire", Transform3D(Basis.IDENTITY, Vector3(xm - d * 0.5 - 0.3, 0.0, c.z)), Vector3(d + 0.6, 0.12, lw + 0.8), true)
	for s in [-1.0, 1.0]:
		var cz: float = c.z + s * 0.9
		_poutre(k, "fer", Vector3(xm - d + 0.1, 0.12, cz), Vector3(xm - 0.4, 0.12, cz), 0.07)
		_poutre(k, "fer", Vector3(xm - d + 0.1, 0.12, cz), Vector3(xm - d + 0.1, 0.62, cz), 0.07)
		k.cyl("or", Transform3D(Basis.IDENTITY, Vector3(xm - d + 0.1, 0.62, cz)), 0.08, 0.0, 0.14, 8)
	for j in range(3):
		var lz: float = c.z + (j - 1) * 0.3
		var ly: float = 0.3 + (0.22 if j == 1 else 0.0)
		_poutre(k, "bois", Vector3(xm - 0.35, ly, lz - 1.2 + j * 0.2), Vector3(xm - 1.05, ly, lz + 1.1 - j * 0.15), 0.2, Vector3.UP)
	for j in range(7):
		var fz: float = c.z + (j - 3) * 0.32
		var fh: float = 1.25 - absf(j - 3) * 0.17
		_flamme(k, Vector3(xm - 0.7 - 0.08 * (j % 2), 0.32, fz), 0.75, fh)
	feu = _lumiere(Vector3(xm - 1.4, 1.2, c.z), 16.0, 1.6, 2.6)
	_ombres(feu)


## Quatre lustres de fer : une grande couronne à seize bougies, une petite au-dessus, les chaînes
func _lustres(k: RefCounted, c: Vector3, H: float, voute: float, hw: float) -> void:
	for x in [-16.0, -5.5, 5.5, 16.0]:
		var p := Vector3(x, H - 9.5, c.z)
		for rr in [[1.7, 0.0, 16], [0.9, 0.9, 8]]:
			var r: float = rr[0]
			var dy: float = rr[1]
			var nb: int = rr[2]
			for i in range(nb):
				var a0: float = TAU * i / nb
				var a1: float = TAU * (i + 1) / nb
				var q0: Vector3 = p + Vector3(cos(a0) * r, dy, sin(a0) * r)
				var q1: Vector3 = p + Vector3(cos(a1) * r, dy, sin(a1) * r)
				_poutre(k, "fer", q0, q1, 0.07, Vector3.UP)
				k.cyl("fer", Transform3D(Basis.IDENTITY, q0 + Vector3(0, 0.035, 0)), 0.06, 0.07, 0.03, 6)
				_bougie(k, q0 + Vector3(0, 0.065, 0), 0.24)
			# les chaînes de la couronne au crochet
			for i in range(4):
				var a: float = TAU * i / 4.0 + 0.4
				_poutre(k, "fer", p + Vector3(cos(a) * r, dy, sin(a) * r), p + Vector3(0, 3.2, 0), 0.035)
		_poutre(k, "fer", p + Vector3(0, 3.2, 0), Vector3(x, H + voute - 0.6, c.z), 0.06)
		k.cyl("or", Transform3D(Basis.IDENTITY, p + Vector3(0, -0.5, 0)), 0.0, 0.18, 0.5, 8)
		_lumiere(p + Vector3(0, 0.6, 0), 19.0, 1.5, 2.6)


## Les bannières de l'Académie (bleu nuit et or, pourpre et argent) entre les hautes baies, deux
## grandes de part et d'autre de la baie ouest ; leur tringle dorée
func _bannieres(k: RefCounted, c: Vector3, L: float, hl: float, hw: float, bx: Array) -> void:
	var j: int = 0
	for i in range(1, 8):
		var x: float = -L * 0.5 + 0.7 + i * (L - 1.4) / 8.0
		for s in [-1.0, 1.0]:
			if s > 0 and absf(x) < 4.0:
				continue
			var z: float = c.z + s * (hw - 0.09)
			var m: String = "banniere_bleu" if j % 2 == 0 else "banniere_pourpre"
			j += 1
			_banniere(k, m, Vector3(x, 15.6, z), 1.5, 6.0, Vector3(0, 0, -s))
	for s2 in [-1.0, 1.0]:
		_banniere(k, "banniere_bleu", Vector3(-hl + 0.09, 13.0, c.z + s2 * 5.6), 2.2, 8.8, Vector3.RIGHT)


## Une bannière : le haut au milieu en p, w x h, tournée vers n
func _banniere(k: RefCounted, m: String, p: Vector3, w: float, h: float, n: Vector3) -> void:
	var u: Vector3 = Vector3.UP.cross(n).normalized() * w * 0.5
	if u.dot(Vector3(1, 0, 1)) < 0.0:
		u = -u
	k.quad(m, Transform3D.IDENTITY, p - u - Vector3(0, h, 0), p + u - Vector3(0, h, 0), p + u, p - u, n,
		Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1))
	_poutre(k, "or", p - u * 1.15 + n * 0.04, p + u * 1.15 + n * 0.04, 0.06, Vector3.UP)
	for e in [-1.0, 1.0]:
		k.cyl("or", Transform3D(Basis.IDENTITY, p + u * 1.15 * e + n * 0.04 - Vector3(0, 0.07, 0)), 0.07, 0.0, 0.16, 8)


# =================================================================== la vie

## 0 le jour, 1 la nuit : les bougies éclairent plus fort, le dedans s'assombrit
## (v13) Le feu porte des ombres douces (les pieds des tables, les fauteuils, les chenets sur le sol)
func _ombres(l: OmniLight3D) -> void:
	l.shadow_enabled = true
	l.light_size = 0.25
	l.shadow_blur = 1.6
	l.shadow_bias = 0.06
	l.shadow_normal_bias = 1.5


func set_nuit(n: float) -> void:
	nuit = n
	if rayons != null:
		rayons.set_shader_parameter("force", 0.1 * clampf(1.0 - n * 1.6, 0.0, 1.0))
	for e in lumieres:
		(e[0] as OmniLight3D).light_energy = lerpf(float(e[1]), float(e[2]), n)
	if sonde != null:
		sonde.ambient_color = AMBIANT_JOUR.lerp(AMBIANT_NUIT, n)


func _process(delta: float) -> void:
	if feu == null:
		return
	_t += delta
	var base: float = lerpf(1.6, 2.6, nuit)
	feu.light_energy = base * (0.86 + 0.09 * sin(_t * 9.0) + 0.05 * sin(_t * 23.0 + 1.3))
