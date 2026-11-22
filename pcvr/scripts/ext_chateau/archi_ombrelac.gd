extends RefCounted
## Extension « Le Château d'Ombrelac » : la boîte à outils de l'architecte. On y empile les pièces
## du château (murs, tours rondes et carrées, toits en poivrière, toits à deux pans, flèches,
## créneaux, mâchicoulis, contreforts, baies en ogive, roses, arcades…) ; tout ce qui a la même
## matière finit dans un seul maillage (un appel de dessin par matière et par bâtiment), et les
## formes de collision suivent (boîtes, cylindres).
## Les matières : « pierre » (la pierre de taille vieillie), « pierre_claire » (les encadrements,
## les moulures), « socle » (la pierre sombre des soubassements), « ardoise » (les toits en
## écailles), « vitre » et « vitrail » (les baies), « or » (les épis de faîtage, les girouettes,
## le cadran), « bois » (les portes, les charpentes), « dalles » (les sols), « fer » (les grilles).
## Godot : les faces avant tournent dans le sens des aiguilles d'une montre.

const T := "res://assets/textures/"
const PIERRE := "res://shaders/pierre_chateau_v161.gdshader"
const ARDOISE := "res://shaders/ext_chateau/ombrelac_ardoise.gdshader"
const VITRE := "res://shaders/ext_chateau/ombrelac_vitre.gdshader"
const LAMBRIS := "res://shaders/ext_chateau/ombrelac_lambris.gdshader"
const LIVRES := "res://shaders/ext_chateau/ombrelac_livres.gdshader"
const TABLEAU := "res://shaders/ext_chateau/ombrelac_tableau.gdshader"
const CARTE_CIEL := "res://shaders/ext_chateau/ombrelac_carte_ciel.gdshader"
const FLAMME := "res://shaders/ext_chateau/ombrelac_flamme.gdshader"
const TISSU := "res://shaders/ext_chateau/ombrelac_tissu.gdshader"

static var _mats: Dictionary = {}

var _st: Dictionary = {}
var _uv_mats := {"ardoise": true, "vitre": true, "vitrail": true, "flamme": true, "livres": true, "tableau": true, "tableau_amphi": true, "carte_ciel": true, "banniere_bleu": true, "banniere_pourpre": true, "tapis": true}
## Les formes de collision : [Shape3D, Transform3D]
var shapes: Array = []
var sol_y: float = 0.0


# =================================================================== matières

static func mat(key: String) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: Material
	match key:
		"pierre", "pierre_claire", "socle", "pierre_int":
			var sp := ShaderMaterial.new()
			sp.shader = load(PIERRE)
			if key == "socle":
				sp.set_shader_parameter("tex_albedo", load(T + "montjoie/pierre_rempart.png"))
				sp.set_shader_parameter("tex_normal", load(T + "montjoie/pierre_rempart_n.png"))
				sp.set_shader_parameter("teinte", Color(0.66, 0.64, 0.62))
				sp.set_shader_parameter("echelle", 1.0 / 4.0)
			elif key == "pierre":
				sp.set_shader_parameter("tex_albedo", load(T + "ext_chateau/pierre_ombrelac.png"))
				sp.set_shader_parameter("tex_normal", load(T + "ext_chateau/pierre_ombrelac_n.png"))
				sp.set_shader_parameter("teinte", Color(1.0, 0.97, 0.92))
				sp.set_shader_parameter("echelle", 1.0 / 4.0)
			elif key == "pierre_int":
				# les murs du dedans : la pierre de taille, plus chaude, sans mousse ni coulures
				sp.set_shader_parameter("tex_albedo", load(T + "ext_chateau/pierre_ombrelac.png"))
				sp.set_shader_parameter("tex_normal", load(T + "ext_chateau/pierre_ombrelac_n.png"))
				sp.set_shader_parameter("teinte", Color(1.0, 0.93, 0.84))
				sp.set_shader_parameter("echelle", 1.0 / 3.0)
			else:
				sp.set_shader_parameter("tex_albedo", load(T + "ext_chateau/pierre_claire_ombrelac.png"))
				sp.set_shader_parameter("tex_normal", load(T + "ext_chateau/pierre_claire_ombrelac_n.png"))
				sp.set_shader_parameter("teinte", Color(1.0, 0.98, 0.94))
				sp.set_shader_parameter("echelle", 1.0 / 2.0)
			sp.set_shader_parameter("relief", 1.1)
			sp.set_shader_parameter("mousse", 0.0 if key == "pierre_int" else (0.7 if key != "pierre_claire" else 0.35))
			sp.set_shader_parameter("sol_y", 52.0)
			m = sp
		"ardoise":
			var sa := ShaderMaterial.new()
			sa.shader = load(ARDOISE)
			sa.set_shader_parameter("grain", load(T + "chateau/ardoise.png"))
			sa.set_shader_parameter("grain_n", load(T + "chateau/ardoise_n.png"))
			m = sa
		"vitre", "vitrail":
			var sv := ShaderMaterial.new()
			sv.shader = load(VITRE)
			sv.set_shader_parameter("vitrail", key == "vitrail")
			m = sv
		"or":
			var so := StandardMaterial3D.new()
			so.albedo_color = Color(0.95, 0.72, 0.3)
			so.metallic = 1.0
			so.roughness = 0.32
			m = so
		"fer":
			var sf := StandardMaterial3D.new()
			sf.albedo_color = Color(0.12, 0.12, 0.13)
			sf.metallic = 0.85
			sf.roughness = 0.55
			m = sf
		"bois", "chene":
			var sb := StandardMaterial3D.new()
			sb.albedo_texture = load(T + "montjoie/bois_planches.png")
			sb.normal_enabled = true
			sb.normal_texture = load(T + "montjoie/bois_planches_n.png")
			sb.uv1_triplanar = true
			sb.uv1_world_triplanar = true
			sb.uv1_scale = Vector3.ONE / 2.0
			sb.albedo_color = Color(0.55, 0.38, 0.26) if key == "bois" else Color(0.9, 0.66, 0.44)
			sb.roughness = 0.8
			m = sb
		"dalles", "dalles_int":
			var sd := StandardMaterial3D.new()
			sd.albedo_texture = load(T + "ext_chateau/dalles_ombrelac.png")
			sd.normal_enabled = true
			sd.normal_texture = load(T + "ext_chateau/dalles_ombrelac_n.png")
			sd.uv1_triplanar = true
			sd.uv1_world_triplanar = true
			sd.uv1_scale = Vector3.ONE / 4.0
			sd.albedo_color = Color(1.0, 0.94, 0.84)
			sd.roughness = 0.95
			if key == "dalles_int":
				sd.albedo_color = Color(0.92, 0.8, 0.66)
				sd.metallic_specular = 0.2
			m = sd
		"gazon":
			var sg := StandardMaterial3D.new()
			sg.albedo_texture = load(T + "montjoie/prairie.png")
			sg.normal_enabled = true
			sg.normal_texture = load(T + "montjoie/prairie_n.png")
			sg.uv1_triplanar = true
			sg.uv1_world_triplanar = true
			sg.uv1_scale = Vector3.ONE / 3.0
			sg.albedo_color = Color(0.85, 0.95, 0.8)
			sg.roughness = 1.0
			m = sg
		"cuivre":
			var sc := StandardMaterial3D.new()
			sc.albedo_color = Color(0.36, 0.62, 0.52)
			sc.metallic = 0.6
			sc.roughness = 0.5
			m = sc
		"livres":
			var sli := ShaderMaterial.new()
			sli.shader = load(LIVRES)
			m = sli
		"parquet":
			var spq := StandardMaterial3D.new()
			spq.albedo_texture = load(T + "montjoie/bois_planches.png")
			spq.normal_enabled = true
			spq.normal_texture = load(T + "montjoie/bois_planches_n.png")
			spq.uv1_triplanar = true
			spq.uv1_world_triplanar = true
			spq.uv1_scale = Vector3.ONE / 1.6
			spq.albedo_color = Color(0.62, 0.42, 0.27)
			spq.roughness = 0.55
			m = spq
		"lampe":
			var sla := StandardMaterial3D.new()
			sla.albedo_color = Color(0.2, 0.42, 0.26)
			sla.emission_enabled = true
			sla.emission = Color(0.55, 0.85, 0.45)
			sla.emission_energy_multiplier = 0.6
			sla.roughness = 0.15
			sla.metallic_specular = 0.8
			m = sla
		"lanterne":
			var sln := StandardMaterial3D.new()
			sln.albedo_color = Color(0.9, 0.6, 0.25)
			sln.emission_enabled = true
			sln.emission = Color(1.0, 0.62, 0.28)
			sln.emission_energy_multiplier = 2.2
			sln.roughness = 0.1
			sln.cull_mode = BaseMaterial3D.CULL_DISABLED
			m = sln
		"tableau", "tableau_amphi":
			var stb := ShaderMaterial.new()
			stb.shader = load(TABLEAU)
			stb.set_shader_parameter("mode", 0 if key == "tableau" else 1)
			m = stb
		"carte_ciel":
			var scc := ShaderMaterial.new()
			scc.shader = load(CARTE_CIEL)
			m = scc
		"potion_vert", "potion_bleu", "potion_rouge", "potion_ambre", "potion_violet":
			var cols := {"potion_vert": Color(0.25, 0.95, 0.35), "potion_bleu": Color(0.2, 0.55, 1.0), "potion_rouge": Color(1.0, 0.2, 0.18),
				"potion_ambre": Color(1.0, 0.62, 0.15), "potion_violet": Color(0.7, 0.3, 1.0)}
			var spo := StandardMaterial3D.new()
			var cc: Color = cols[key]
			spo.albedo_color = cc * 0.6
			spo.emission_enabled = true
			spo.emission = cc
			spo.emission_energy_multiplier = 1.4
			spo.roughness = 0.05
			spo.metallic_specular = 1.0
			m = spo
		"verre":
			var sve := StandardMaterial3D.new()
			sve.albedo_color = Color(0.55, 0.66, 0.66)
			sve.roughness = 0.04
			sve.metallic = 0.3
			sve.metallic_specular = 1.0
			m = sve
		"cuivre_neuf":
			var scn := StandardMaterial3D.new()
			scn.albedo_color = Color(0.86, 0.47, 0.3)
			scn.metallic = 1.0
			scn.roughness = 0.33
			m = scn
		"moellons":
			var smo := StandardMaterial3D.new()
			smo.albedo_texture = load(T + "montjoie/moellons.png")
			smo.normal_enabled = true
			smo.normal_texture = load(T + "montjoie/moellons_n.png")
			smo.uv1_triplanar = true
			smo.uv1_world_triplanar = true
			smo.uv1_scale = Vector3.ONE / 1.5
			smo.albedo_color = Color(0.95, 0.72, 0.58)
			smo.roughness = 0.95
			m = smo
		"herbes":
			var she := StandardMaterial3D.new()
			she.albedo_color = Color(0.32, 0.36, 0.17)
			she.roughness = 1.0
			she.cull_mode = BaseMaterial3D.CULL_DISABLED
			m = she
		"soleil":
			var sso := StandardMaterial3D.new()
			sso.albedo_color = Color(1.0, 0.75, 0.3)
			sso.emission_enabled = true
			sso.emission = Color(1.0, 0.7, 0.3)
			sso.emission_energy_multiplier = 2.5
			sso.metallic = 0.6
			sso.roughness = 0.3
			m = sso
		"lambris":
			var sl := ShaderMaterial.new()
			sl.shader = load(LAMBRIS)
			m = sl
		"flamme":
			var sfl := ShaderMaterial.new()
			sfl.shader = load(FLAMME)
			m = sfl
		"cire":
			var sw := StandardMaterial3D.new()
			sw.albedo_color = Color(0.93, 0.88, 0.76)
			sw.roughness = 0.6
			sw.subsurf_scatter_enabled = false
			sw.emission_enabled = true
			sw.emission = Color(1.0, 0.6, 0.25)
			sw.emission_energy_multiplier = 0.25
			m = sw
		"velours_bleu", "velours_pourpre", "velours_vert":
			# les rideaux des lits, les édredons, les fauteuils : un velours (un peu de reflet rasant)
			var sv := StandardMaterial3D.new()
			if key == "velours_bleu":
				sv.albedo_color = Color(0.1, 0.14, 0.36)
			elif key == "velours_pourpre":
				sv.albedo_color = Color(0.36, 0.07, 0.14)
			else:
				sv.albedo_color = Color(0.12, 0.26, 0.14)
			sv.roughness = 0.85
			sv.rim_enabled = true
			sv.rim = 0.45
			sv.rim_tint = 0.6
			sv.cull_mode = BaseMaterial3D.CULL_DISABLED
			m = sv
		"cadran":
			# le verre opalin des cadrans de l'horloge : laiteux le jour, éclairé du dedans la nuit
			var sc := StandardMaterial3D.new()
			sc.albedo_color = Color(0.93, 0.9, 0.8)
			sc.roughness = 0.45
			sc.emission_enabled = true
			sc.emission = Color(1.0, 0.86, 0.58)
			sc.emission_energy_multiplier = 0.25
			sc.cull_mode = BaseMaterial3D.CULL_DISABLED
			m = sc
		"bronze":
			var sb := StandardMaterial3D.new()
			sb.albedo_color = Color(0.72, 0.5, 0.27)
			sb.metallic = 0.35
			sb.roughness = 0.5
			m = sb
		"drap":
			var sd := StandardMaterial3D.new()
			sd.albedo_color = Color(0.86, 0.83, 0.76)
			sd.roughness = 0.92
			m = sd
		"suie":
			var su := StandardMaterial3D.new()
			su.albedo_color = Color(0.05, 0.045, 0.04)
			su.roughness = 1.0
			m = su
		"banniere_bleu", "banniere_pourpre", "tapis":
			var sti := ShaderMaterial.new()
			sti.shader = load(TISSU)
			if key == "banniere_bleu":
				sti.set_shader_parameter("fond", Color(0.06, 0.09, 0.26))
				sti.set_shader_parameter("bord", Color(0.86, 0.66, 0.26))
			elif key == "banniere_pourpre":
				sti.set_shader_parameter("fond", Color(0.24, 0.05, 0.14))
				sti.set_shader_parameter("bord", Color(0.78, 0.8, 0.84))
			else:
				sti.set_shader_parameter("fond", Color(0.32, 0.05, 0.05))
				sti.set_shader_parameter("bord", Color(0.8, 0.6, 0.24))
				sti.set_shader_parameter("tapis", true)
				sti.set_shader_parameter("aspect", 7.0)
			m = sti
		_:
			var s0 := StandardMaterial3D.new()
			s0.albedo_color = Color(1, 0, 1)
			m = s0
	_mats[key] = m
	return m


## Toutes les matières de vitre (pour allumer les fenêtres le soir)
static func vitres() -> Array:
	return [mat("vitre"), mat("vitrail")]


# =================================================================== bas niveau

func _tool(m: String) -> SurfaceTool:
	if not _st.has(m):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		_st[m] = st
	return _st[m]


func _v(st: SurfaceTool, p: Vector3, n: Vector3, uv: Vector2, uv2: Vector2) -> void:
	st.set_normal(n)
	st.set_uv(uv)
	st.set_uv2(uv2)
	st.add_vertex(p)


## Un triangle, normale plate, tourné vers « out » (dans le repère local de xf)
func tri(m: String, xf: Transform3D, a: Vector3, b: Vector3, c: Vector3, out: Vector3, ua := Vector2.ZERO, ub := Vector2.ZERO, uc := Vector2.ZERO, uv2 := Vector2.ZERO) -> void:
	var st: SurfaceTool = _tool(m)
	var A: Vector3 = xf * a
	var B: Vector3 = xf * b
	var C: Vector3 = xf * c
	var o: Vector3 = xf.basis * out
	var n: Vector3 = (B - A).cross(C - A)
	if n.length_squared() < 1e-12:
		return
	n = n.normalized()
	if n.dot(o) < 0.0:
		n = -n
		_v(st, A, n, ua, uv2)
		_v(st, B, n, ub, uv2)
		_v(st, C, n, uc, uv2)
	else:
		_v(st, A, n, ua, uv2)
		_v(st, C, n, uc, uv2)
		_v(st, B, n, ub, uv2)


## Un quadrilatère a b c d (dans l'ordre du tour), tourné vers « out »
func quad(m: String, xf: Transform3D, a: Vector3, b: Vector3, c: Vector3, d: Vector3, out: Vector3, ua := Vector2(0, 0), ub := Vector2(1, 0), uc := Vector2(1, 1), ud := Vector2(0, 1), uv2 := Vector2.ZERO) -> void:
	tri(m, xf, a, b, c, out, ua, ub, uc, uv2)
	tri(m, xf, a, c, d, out, ua, uc, ud, uv2)


## Un quadrilatère aux normales lissées (na, nb, nc, nd), pour les surfaces courbes
func quad_smooth(m: String, xf: Transform3D, a: Vector3, b: Vector3, c: Vector3, d: Vector3, na: Vector3, nb: Vector3, nc: Vector3, nd: Vector3, ua := Vector2(0, 0), ub := Vector2(1, 0), uc := Vector2(1, 1), ud := Vector2(0, 1)) -> void:
	var st: SurfaceTool = _tool(m)
	var P := [xf * a, xf * b, xf * c, xf * d]
	var N := [(xf.basis * na).normalized(), (xf.basis * nb).normalized(), (xf.basis * nc).normalized(), (xf.basis * nd).normalized()]
	var U := [ua, ub, uc, ud]
	var avg: Vector3 = N[0] + N[1] + N[2] + N[3]
	var g: Vector3 = (P[1] - P[0]).cross(P[2] - P[0])
	if g.length_squared() < 1e-12:
		g = (P[2] - P[0]).cross(P[3] - P[0])
	var order := [0, 2, 1, 0, 3, 2] if g.dot(avg) >= 0.0 else [0, 1, 2, 0, 2, 3]
	for i in order:
		_v(st, P[i], N[i], U[i], Vector2.ZERO)


# =================================================================== volumes

## Une boîte : xf au milieu de la base, size = largeur (x), hauteur (y), profondeur (z)
func box(m: String, xf: Transform3D, size: Vector3, collide: bool = false) -> void:
	var hx: float = size.x * 0.5
	var hz: float = size.z * 0.5
	var h: float = size.y
	var p := [Vector3(-hx, 0, -hz), Vector3(hx, 0, -hz), Vector3(hx, 0, hz), Vector3(-hx, 0, hz),
		Vector3(-hx, h, -hz), Vector3(hx, h, -hz), Vector3(hx, h, hz), Vector3(-hx, h, hz)]
	quad(m, xf, p[4], p[5], p[6], p[7], Vector3.UP)
	quad(m, xf, p[0], p[1], p[2], p[3], Vector3.DOWN)
	quad(m, xf, p[3], p[2], p[6], p[7], Vector3.BACK)
	quad(m, xf, p[1], p[0], p[4], p[5], Vector3.FORWARD)
	quad(m, xf, p[2], p[1], p[5], p[6], Vector3.RIGHT)
	quad(m, xf, p[0], p[3], p[7], p[4], Vector3.LEFT)
	if collide:
		var s := BoxShape3D.new()
		s.size = size
		shapes.append([s, xf * Transform3D(Basis.IDENTITY, Vector3(0, h * 0.5, 0))])


## Un tronc de cône (une tour ronde) : xf au centre de la base ; r0 en bas, r1 en haut
func cyl(m: String, xf: Transform3D, r0: float, r1: float, h: float, sides: int = 24, caps: bool = true, collide: bool = false) -> void:
	var slope: float = (r0 - r1) / maxf(h, 0.001)
	for i in range(sides):
		var a0: float = TAU * i / sides
		var a1: float = TAU * (i + 1) / sides
		var d0 := Vector3(cos(a0), 0, sin(a0))
		var d1 := Vector3(cos(a1), 0, sin(a1))
		var n0: Vector3 = (d0 + Vector3(0, slope, 0)).normalized()
		var n1: Vector3 = (d1 + Vector3(0, slope, 0)).normalized()
		quad_smooth(m, xf, d0 * r0, d1 * r0, d1 * r1 + Vector3(0, h, 0), d0 * r1 + Vector3(0, h, 0), n0, n1, n1, n0)
		if caps:
			tri(m, xf, Vector3(0, h, 0), d0 * r1 + Vector3(0, h, 0), d1 * r1 + Vector3(0, h, 0), Vector3.UP)
	if collide:
		var s := CylinderShape3D.new()
		s.radius = maxf(r0, r1)
		s.height = h
		shapes.append([s, xf * Transform3D(Basis.IDENTITY, Vector3(0, h * 0.5, 0))])


## Un prisme vertical sur un polygone (x, z) : un mur épais, un pilier octogonal…
func prism(m: String, xf: Transform3D, poly: PackedVector2Array, y0: float, y1: float, top: bool = true, bottom: bool = false) -> void:
	var n: int = poly.size()
	var c := Vector2.ZERO
	for p in poly:
		c += p
	c /= n
	for i in range(n):
		var a: Vector2 = poly[i]
		var b: Vector2 = poly[(i + 1) % n]
		var mid: Vector2 = (a + b) * 0.5 - c
		quad(m, xf, Vector3(a.x, y0, a.y), Vector3(b.x, y0, b.y), Vector3(b.x, y1, b.y), Vector3(a.x, y1, a.y), Vector3(mid.x, 0, mid.y))
		if top:
			tri(m, xf, Vector3(c.x, y1, c.y), Vector3(a.x, y1, a.y), Vector3(b.x, y1, b.y), Vector3.UP)
		if bottom:
			tri(m, xf, Vector3(c.x, y0, c.y), Vector3(a.x, y0, a.y), Vector3(b.x, y0, b.y), Vector3.DOWN)


static func ngon(r: float, n: int, rot: float = 0.0) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in range(n):
		var a: float = rot + TAU * i / n
		out.append(Vector2(cos(a), sin(a)) * r)
	return out


# =================================================================== toits

## Le toit en poivrière : un cône d'ardoises à coyau (le bas s'évase), xf au centre, à la base du
## toit. r : le rayon de la tour ; h : la hauteur du toit ; un épi de faîtage doré.
func cone_roof(xf: Transform3D, r: float, h: float, sides: int = 24, epi: bool = true) -> void:
	# le profil : [rayon, hauteur]
	var prof := [[r * 1.16, -0.5], [r * 1.02, h * 0.1], [r * 0.78, h * 0.3], [r * 0.4, h * 0.62], [0.0, h]]
	var slant := [0.0]
	for k in range(1, prof.size()):
		slant.append(float(slant[k - 1]) + Vector2(float(prof[k][0]) - float(prof[k - 1][0]), float(prof[k][1]) - float(prof[k - 1][1])).length())
	for i in range(sides):
		var a0: float = TAU * i / sides
		var a1: float = TAU * (i + 1) / sides
		var d0 := Vector3(cos(a0), 0, sin(a0))
		var d1 := Vector3(cos(a1), 0, sin(a1))
		for k in range(prof.size() - 1):
			var ra: float = float(prof[k][0])
			var rb: float = float(prof[k + 1][0])
			var ya: float = float(prof[k][1])
			var yb: float = float(prof[k + 1][1])
			var sl: float = (ra - rb) / maxf(yb - ya, 0.01)
			var na0: Vector3 = (d0 * 1.0 + Vector3(0, sl, 0)).normalized()
			var na1: Vector3 = (d1 * 1.0 + Vector3(0, sl, 0)).normalized()
			# u : la longueur de l'arc à la base du rang (les ardoises rétrécissent vers la pointe)
			var ua0: float = a0 * maxf(ra, 0.3)
			var ua1: float = a1 * maxf(ra, 0.3)
			var ub0: float = a0 * maxf(rb, 0.3)
			var ub1: float = a1 * maxf(rb, 0.3)
			quad_smooth("ardoise", xf, d0 * ra + Vector3(0, ya, 0), d1 * ra + Vector3(0, ya, 0), d1 * rb + Vector3(0, yb, 0), d0 * rb + Vector3(0, yb, 0),
				na0, na1, na1, na0, Vector2(ua0, slant[k]), Vector2(ua1, slant[k]), Vector2(ub1, slant[k + 1]), Vector2(ub0, slant[k + 1]))
	# le dessous de l'avant-toit
	for i in range(sides):
		var a0: float = TAU * i / sides
		var a1: float = TAU * (i + 1) / sides
		tri("pierre_claire", xf, Vector3(0, -0.5, 0), Vector3(cos(a0), 0, sin(a0)) * r * 1.16 + Vector3(0, -0.5, 0), Vector3(cos(a1), 0, sin(a1)) * r * 1.16 + Vector3(0, -0.5, 0), Vector3.DOWN)
	if epi:
		finial(xf * Transform3D(Basis.IDENTITY, Vector3(0, h - 0.2, 0)), maxf(0.6, r * 0.12))


## Le toit en pavillon (quatre pans) sur un carré de demi-côtés hx, hz ; coyau, épi
func hip_roof(xf: Transform3D, hx: float, hz: float, h: float, epi: bool = true) -> void:
	var e: float = 0.9
	var corners := [Vector3(-hx - e, -0.4, -hz - e), Vector3(hx + e, -0.4, -hz - e), Vector3(hx + e, -0.4, hz + e), Vector3(-hx - e, -0.4, hz + e)]
	var mids := [Vector3(-hx * 0.86, h * 0.14, -hz * 0.86), Vector3(hx * 0.86, h * 0.14, -hz * 0.86), Vector3(hx * 0.86, h * 0.14, hz * 0.86), Vector3(-hx * 0.86, h * 0.14, hz * 0.86)]
	var apex := Vector3(0, h, 0)
	for i in range(4):
		var a: Vector3 = corners[i]
		var b: Vector3 = corners[(i + 1) % 4]
		var ma: Vector3 = mids[i]
		var mb: Vector3 = mids[(i + 1) % 4]
		var out: Vector3 = ((a + b) * 0.5) * Vector3(1, 0, 1)
		var wlen: float = a.distance_to(b)
		var s1: float = a.distance_to(ma)
		var s2: float = s1 + ma.distance_to(apex)
		quad("ardoise", xf, a, b, mb, ma, out + Vector3(0, 0.6, 0), Vector2(0, 0), Vector2(wlen, 0), Vector2(wlen - 1.0, s1), Vector2(1.0, s1))
		tri("ardoise", xf, ma, mb, apex, out + Vector3(0, 1.0, 0), Vector2(1.0, s1), Vector2(wlen - 1.0, s1), Vector2(wlen * 0.5, s2))
	if epi:
		finial(xf * Transform3D(Basis.IDENTITY, apex - Vector3(0, 0.2, 0)), maxf(0.6, minf(hx, hz) * 0.1))


## Le toit à deux pans (faîtage selon x), xf au milieu du haut des murs ; length, width : les murs.
## Les pignons sont en pierre, débordants (rampants), avec un épi à chaque bout.
func gable_roof(xf: Transform3D, length: float, width: float, h: float, pignons: bool = true, epis: bool = true) -> void:
	var hl: float = length * 0.5 + 0.6
	var hw: float = width * 0.5 + 1.0
	var slope_len: float = Vector2(hw, h + 0.5).length()
	for s in [-1.0, 1.0]:
		var a := Vector3(-hl, -0.5, s * hw)
		var b := Vector3(hl, -0.5, s * hw)
		var c := Vector3(hl, h, 0)
		var d := Vector3(-hl, h, 0)
		quad("ardoise", xf, a, b, c, d, Vector3(0, hw / (h + 0.5), s), Vector2(0, 0), Vector2(length + 1.2, 0), Vector2(length + 1.2, slope_len), Vector2(0, slope_len))
		# le dessous du débord
		quad("pierre_claire", xf, Vector3(-hl, -0.5, s * hw), Vector3(hl, -0.5, s * hw), Vector3(hl, -0.5, s * width * 0.5), Vector3(-hl, -0.5, s * width * 0.5), Vector3.DOWN)
	# le faîtage : une crête de plomb
	box("fer", xf * Transform3D(Basis.IDENTITY, Vector3(0, h - 0.05, 0)), Vector3(length + 1.2, 0.25, 0.35))
	if pignons:
		for e in [-1.0, 1.0]:
			var x: float = e * length * 0.5
			# le pignon : un triangle de pierre, et ses rampants (deux bandeaux en saillie)
			tri("pierre", xf, Vector3(x, 0, -width * 0.5), Vector3(x, 0, width * 0.5), Vector3(x, h, 0), Vector3(e, 0, 0))
			for s in [-1.0, 1.0]:
				var p0 := Vector3(x + e * 0.35, -0.6, s * (hw + 0.2))
				var p1 := Vector3(x + e * 0.35, h + 0.45, 0)
				_rampant(xf, p0, p1, e)
			if epis:
				finial(xf * Transform3D(Basis.IDENTITY, Vector3(x + e * 0.35, h + 0.4, 0)), 0.55)


func _rampant(xf: Transform3D, p0: Vector3, p1: Vector3, e: float) -> void:
	var dir: Vector3 = (p1 - p0).normalized()
	var up: Vector3 = dir.cross(Vector3(e, 0, 0)).normalized()
	if up.y < 0.0:
		up = -up
	var side := Vector3(e * 0.4, 0, 0)
	var t := up * 0.55
	quad("pierre_claire", xf, p0 - side, p1 - side, p1 + side, p0 + side, -up)
	quad("pierre_claire", xf, p0 - side + t, p1 - side + t, p1 + side + t, p0 + side + t, up)
	quad("pierre_claire", xf, p0 + side, p1 + side, p1 + side + t, p0 + side + t, Vector3(e, 0, 0))
	quad("pierre_claire", xf, p0 - side, p1 - side, p1 - side + t, p0 - side + t, Vector3(-e, 0, 0))


## La flèche : une pyramide octogonale très effilée, des lucarnes, un épi et une girouette
func spire(xf: Transform3D, r: float, h: float) -> void:
	var sides: int = 8
	var slant: float = Vector2(r * 1.08, h).length()
	for i in range(sides):
		var a0: float = TAU * (i + 0.5) / sides
		var a1: float = TAU * (i + 1.5) / sides
		var p0 := Vector3(cos(a0), 0, sin(a0)) * r * 1.08 + Vector3(0, -0.4, 0)
		var p1 := Vector3(cos(a1), 0, sin(a1)) * r * 1.08 + Vector3(0, -0.4, 0)
		var w: float = p0.distance_to(p1)
		var mid: Vector3 = (p0 + p1) * 0.5
		tri("ardoise", xf, p0, p1, Vector3(0, h, 0), mid + Vector3(0, r * r / h, 0), Vector2(0, 0), Vector2(w, 0), Vector2(w * 0.5, slant))
		# les arêtiers : un fin bandeau de plomb
		box("fer", xf * Transform3D(Basis.looking_at(Vector3(0, h, 0) - p0 * 1.0, Vector3.UP) * Basis(Vector3.RIGHT, -PI * 0.5), p0), Vector3(0.18, slant, 0.18))
	# quatre lucarnes au pied de la flèche
	for i in range(4):
		var a: float = TAU * (i + 0.5) / 4.0
		var d := Vector3(cos(a), 0, sin(a))
		var b := Basis.looking_at(-d, Vector3.UP)
		var lx := Transform3D(b, d * r * 0.62 + Vector3(0, h * 0.06, 0))
		box("pierre_claire", xf * lx, Vector3(r * 0.42, r * 0.7, r * 0.6))
		window(xf * lx * Transform3D(Basis.IDENTITY, Vector3(0, r * 0.12, r * 0.3)), r * 0.24, r * 0.45, "vitre", 0.08)
		var gx: Transform3D = xf * lx * Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(0, r * 0.7, 0))
		gable_roof(gx, r * 0.6, r * 0.42, r * 0.35, false, false)
	finial(xf * Transform3D(Basis.IDENTITY, Vector3(0, h - 0.3, 0)), maxf(0.8, r * 0.1), true)


## L'épi de faîtage : une tige, une boule, une pointe (et une girouette en fanion)
func finial(xf: Transform3D, s: float, girouette: bool = false) -> void:
	cyl("or", xf, s * 0.16, s * 0.12, s * 2.6, 6, true)
	_ball(xf * Transform3D(Basis.IDENTITY, Vector3(0, s * 1.2, 0)), s * 0.42)
	cyl("or", xf * Transform3D(Basis.IDENTITY, Vector3(0, s * 2.6, 0)), s * 0.12, 0.0, s * 1.6, 6, false)
	if girouette:
		var fx: Transform3D = xf * Transform3D(Basis.IDENTITY, Vector3(0, s * 2.8, 0))
		quad("or", fx, Vector3(0, 0, 0), Vector3(s * 1.8, 0.1, 0), Vector3(s * 1.5, s * 0.55, 0), Vector3(0, s * 0.7, 0), Vector3(0, 0, 1))
		quad("or", fx, Vector3(0, 0, 0), Vector3(s * 1.8, 0.1, 0), Vector3(s * 1.5, s * 0.55, 0), Vector3(0, s * 0.7, 0), Vector3(0, 0, -1))


func _ball(xf: Transform3D, r: float) -> void:
	var rings: int = 5
	var segs: int = 8
	for j in range(rings):
		var t0: float = PI * j / rings - PI * 0.5
		var t1: float = PI * (j + 1) / rings - PI * 0.5
		for i in range(segs):
			var a0: float = TAU * i / segs
			var a1: float = TAU * (i + 1) / segs
			var p := [Vector3(cos(a0) * cos(t0), sin(t0), sin(a0) * cos(t0)), Vector3(cos(a1) * cos(t0), sin(t0), sin(a1) * cos(t0)),
				Vector3(cos(a1) * cos(t1), sin(t1), sin(a1) * cos(t1)), Vector3(cos(a0) * cos(t1), sin(t1), sin(a0) * cos(t1))]
			quad_smooth("or", xf, p[0] * r, p[1] * r, p[2] * r, p[3] * r, p[0], p[1], p[2], p[3])


# =================================================================== détails des murs

## Les créneaux le long d'un segment (a → b, dans le plan du haut du mur), épaisseur ep
func crenels(xf: Transform3D, a: Vector3, b: Vector3, ep: float, m: String = "pierre") -> void:
	var len: float = a.distance_to(b)
	var n: int = maxi(1, int(len / 2.4))
	var dir: Vector3 = (b - a) / len
	var basis := Basis.looking_at(dir.cross(Vector3.UP), Vector3.UP)
	var step: float = len / n
	for i in range(n):
		var c: Vector3 = a + dir * (step * (i + 0.5))
		box(m, xf * Transform3D(basis, c), Vector3(step * 0.55, 1.5, ep))
	# le chaperon : un parapet bas continu sous les merlons
	box(m, xf * Transform3D(basis, (a + b) * 0.5 - Vector3(0, 1.0, 0)), Vector3(len, 1.0, ep))


## Les créneaux sur le pourtour d'une tour ronde (rayon r, à la hauteur y) avec des mâchicoulis :
## le parapet en encorbellement, porté par des consoles
func crown(xf: Transform3D, r: float, y: float, sides: int = 20, m: String = "pierre") -> void:
	var ro: float = r + 0.8
	# le bandeau en saillie
	cyl(m, xf * Transform3D(Basis.IDENTITY, Vector3(0, y - 1.6, 0)), r, ro, 1.6, sides, false)
	cyl(m, xf * Transform3D(Basis.IDENTITY, Vector3(0, y, 0)), ro, ro, 1.1, sides, true)
	# les consoles
	for i in range(sides):
		var a: float = TAU * (i + 0.5) / sides
		var d := Vector3(cos(a), 0, sin(a))
		box(m, xf * Transform3D(Basis.looking_at(d, Vector3.UP), d * (r + 0.35) + Vector3(0, y - 2.8, 0)), Vector3(0.45, 1.4, 0.7))
	# les merlons
	var n: int = sides
	for i in range(n):
		if i % 2 == 1:
			continue
		var a0: float = TAU * i / n
		var d0 := Vector3(cos(a0 + PI / n), 0, sin(a0 + PI / n))
		box(m, xf * Transform3D(Basis.looking_at(d0, Vector3.UP), d0 * (ro - 0.3) + Vector3(0, y + 1.1, 0)), Vector3(TAU * ro / n * 0.95, 1.4, 0.6))


## Une baie en ogive : xf au milieu du bas de la baie, sur la face du mur (z+ vers dehors) ; un
## encadrement de pierre claire en saillie, l'appui, le verre un peu en retrait.
func window(xf: Transform3D, w: float, h: float, verre: String = "vitre", saillie: float = 0.38) -> void:
	var outline: PackedVector2Array = ogive(w, h, 10)
	# le verre (UV de 0 à 1 ; UV2 : le centre de la baie, dans le monde, pour l'allumer d'un bloc)
	var cw: Vector3 = xf * Vector3(0, h * 0.5, 0)
	var c2 := Vector2(cw.x, cw.z + cw.y * 7.0)
	var n: int = outline.size()
	var center := Vector3(0, h * 0.45, 0.06)
	for i in range(n):
		var a: Vector2 = outline[i]
		var b: Vector2 = outline[(i + 1) % n]
		tri(verre, xf, center, Vector3(a.x, a.y, 0.06), Vector3(b.x, b.y, 0.06), Vector3(0, 0, 1),
			Vector2(0.5, 0.45), Vector2(a.x / w + 0.5, a.y / h), Vector2(b.x / w + 0.5, b.y / h), c2)
	# l'encadrement : une bande autour de l'ogive, en saillie
	var fw: float = maxf(0.18, w * 0.12)
	var outer: PackedVector2Array = ogive(w + fw * 2.0, h + fw, 10)
	for i in range(n):
		var a: Vector2 = outline[i]
		var b: Vector2 = outline[(i + 1) % n]
		var oa: Vector2 = outer[i] + Vector2(0, -fw * 0.0)
		var ob: Vector2 = outer[(i + 1) % n]
		if i == n - 1:
			continue          # le bas (l'appui est à part)
		quad("pierre_claire", xf, Vector3(a.x, a.y, saillie), Vector3(b.x, b.y, saillie), Vector3(ob.x, ob.y, saillie), Vector3(oa.x, oa.y, saillie), Vector3(0, 0, 1))
		# l'épaisseur de l'ébrasement (côté baie) et le tour extérieur
		var mid: Vector2 = (a + b) * 0.5
		quad("pierre_claire", xf, Vector3(a.x, a.y, 0.06), Vector3(b.x, b.y, 0.06), Vector3(b.x, b.y, saillie), Vector3(a.x, a.y, saillie), Vector3(-mid.x, h * 0.5 - mid.y, 0))
		var omid: Vector2 = (oa + ob) * 0.5
		quad("pierre_claire", xf, Vector3(oa.x, oa.y, 0.0), Vector3(ob.x, ob.y, 0.0), Vector3(ob.x, ob.y, saillie), Vector3(oa.x, oa.y, saillie), Vector3(omid.x, omid.y - h * 0.5, 0))
	# l'appui
	box("pierre_claire", xf * Transform3D(Basis.IDENTITY, Vector3(0, -0.3, saillie * 0.5)), Vector3(w + fw * 2.6, 0.3, saillie + 0.4))


## Le contour d'une ogive (dans le plan x, y), du bas gauche au bas droit en passant par la pointe
static func ogive(w: float, h: float, seg: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	var hw: float = w * 0.5
	var spring: float = h - w * 0.86          # la naissance de l'arc
	out.append(Vector2(-hw, 0))
	out.append(Vector2(-hw, spring))
	# l'arc brisé : deux arcs de rayon w centrés sur les naissances opposées
	var r: float = w
	for i in range(1, seg + 1):
		var t: float = float(i) / seg
		var ang: float = lerpf(0.0, acos(0.5), t)
		out.append(Vector2(hw - r * cos(ang), spring + r * sin(ang) * (h - spring) / (r * sin(acos(0.5)))))
	for i in range(seg - 1, 0, -1):
		var t: float = float(i) / seg
		var ang: float = lerpf(0.0, acos(0.5), t)
		out.append(Vector2(-(hw - r * cos(ang)), spring + r * sin(ang) * (h - spring) / (r * sin(acos(0.5)))))
	out.append(Vector2(hw, spring))
	out.append(Vector2(hw, 0))
	return out


## Une rose (un grand vitrail rond) : xf au centre, sur la face du mur
func rose(xf: Transform3D, r: float) -> void:
	var seg: int = 32
	var c2v: Vector3 = xf.origin
	var c2 := Vector2(c2v.x, c2v.z + c2v.y * 7.0)
	for i in range(seg):
		var a0: float = TAU * i / seg
		var a1: float = TAU * (i + 1) / seg
		var p0 := Vector3(cos(a0), sin(a0), 0) * r
		var p1 := Vector3(cos(a1), sin(a1), 0) * r
		tri("vitrail", xf, Vector3(0, 0, 0.06), p0 + Vector3(0, 0, 0.06), p1 + Vector3(0, 0, 0.06), Vector3(0, 0, 1),
			Vector2(0.5, 0.5), Vector2(cos(a0) * 0.5 + 0.5, sin(a0) * 0.5 + 0.5), Vector2(cos(a1) * 0.5 + 0.5, sin(a1) * 0.5 + 0.5), c2)
		# le cercle de pierre
		var q0 := Vector3(cos(a0), sin(a0), 0) * (r + 0.7)
		var q1 := Vector3(cos(a1), sin(a1), 0) * (r + 0.7)
		quad("pierre_claire", xf, p0 + Vector3(0, 0, 0.35), p1 + Vector3(0, 0, 0.35), q1 + Vector3(0, 0, 0.35), q0 + Vector3(0, 0, 0.35), Vector3(0, 0, 1))
		quad("pierre_claire", xf, p0 + Vector3(0, 0, 0.06), p1 + Vector3(0, 0, 0.06), p1 + Vector3(0, 0, 0.35), p0 + Vector3(0, 0, 0.35), -(p0 + p1))
	# les rayons du remplage
	for i in range(12):
		var a: float = TAU * i / 12.0
		box("pierre_claire", xf * Transform3D(Basis(Vector3(0, 0, 1), a - PI * 0.5), Vector3(0, 0, 0.0)), Vector3(0.22, r, 0.3))
	cyl("pierre_claire", xf * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), r * 0.18, r * 0.18, 0.4, 12)


## Un contrefort : xf au pied, contre le mur (z+ vers dehors) ; il s'amincit par ressauts
func buttress(xf: Transform3D, h: float, w: float = 1.4, d: float = 2.4) -> void:
	var steps: int = 3
	for i in range(steps):
		var y0: float = h * i / steps
		var dd: float = d * (1.0 - 0.28 * i)
		box("pierre", xf * Transform3D(Basis.IDENTITY, Vector3(0, y0, dd * 0.5)), Vector3(w, h / steps, dd))
		# le glacis (le dessus en pente de chaque ressaut)
		var y1: float = y0 + h / steps
		var dn: float = d * (1.0 - 0.28 * (i + 1))
		quad("pierre_claire", xf, Vector3(-w * 0.5, y1, dd), Vector3(w * 0.5, y1, dd), Vector3(w * 0.5, y1 + 0.8, dn), Vector3(-w * 0.5, y1 + 0.8, dn), Vector3(0, 1, 1))
		tri("pierre_claire", xf, Vector3(-w * 0.5, y1, dd), Vector3(-w * 0.5, y1, dn), Vector3(-w * 0.5, y1 + 0.8, dn), Vector3.LEFT)
		tri("pierre_claire", xf, Vector3(w * 0.5, y1, dd), Vector3(w * 0.5, y1, dn), Vector3(w * 0.5, y1 + 0.8, dn), Vector3.RIGHT)
	# un pinacle au sommet
	cyl("pierre_claire", xf * Transform3D(Basis.IDENTITY, Vector3(0, h + 0.8, d * 0.16)), w * 0.42, 0.0, 2.6, 4, false)


## Un bandeau (une moulure horizontale) le long d'un segment, en saillie sur un mur
func cordon(xf: Transform3D, a: Vector3, b: Vector3, out: Vector3, s: float = 0.3) -> void:
	var o: Vector3 = out.normalized() * s
	quad("pierre_claire", xf, a, b, b + o, a + o, Vector3.UP)
	quad("pierre_claire", xf, a - Vector3(0, s, 0), b - Vector3(0, s, 0), b + o, a + o, o - Vector3(0, s, 0))


# =================================================================== murs percés (les intérieurs)

## Une baie en ogive dans un mur percé : x au milieu, y0 au bas, w x h
static func trou_ogive(x: float, y0: float, w: float, h: float) -> Dictionary:
	var o: PackedVector2Array = ogive(w, h, 10)
	var haut: Array = []
	for i in range(1, o.size() - 1):
		haut.append(Vector2(o[i].x + x, o[i].y + y0))
	return {"xl": x - w * 0.5, "xr": x + w * 0.5, "yb": y0, "yt": y0 + h, "haut": haut, "bas": []}


## Un oculus (une rose) dans un mur percé : centre (x, y), rayon r
static func trou_rond(x: float, y: float, r: float) -> Dictionary:
	var haut: Array = []
	var bas: Array = []
	var seg: int = 16
	for i in range(seg + 1):
		var a: float = PI - PI * i / seg
		haut.append(Vector2(x + cos(a) * r, y + sin(a) * r))
		bas.append(Vector2(x + cos(a) * r, y - sin(a) * r))
	return {"xl": x - r, "xr": x + r, "yb": y - r, "yt": y + r, "haut": haut, "bas": bas}


## Un mur épais percé de baies. Repère xf : le mur va de x = -L/2 à L/2, de y = 0 à H ; la face du
## dehors en z = 0 (tournée vers z+), celle du dedans en z = -T. « trous » : des trou_ogive /
## trou_rond, de gauche à droite. Le dehors en « ext », le dedans en « int », les ébrasements en
## pierre claire. collide : des boîtes de collision pour les trumeaux, les allèges, les dessus.
func mur(xf: Transform3D, L: float, H: float, T: float, trous: Array, ext: String = "pierre", int_m: String = "pierre_int", collide: bool = true) -> void:
	var cols: Array = []
	for tr in trous:
		cols.append([tr])
	mur_col(xf, L, H, T, cols, ext, int_m, collide)


## Le même, avec des colonnes de baies superposées : « cols » est une liste de colonnes (de gauche
## à droite), chacune une liste de baies de même largeur, de bas en haut.
func mur_col(xf: Transform3D, L: float, H: float, T: float, cols: Array, ext: String = "pierre", int_m: String = "pierre_int", collide: bool = true) -> void:
	var x0: float = -L * 0.5
	var zi: float = -T
	# un pan plein du mur entre xa et xb, de ya à yb (les deux faces)
	var pan := func(xa: float, xb: float, ya: float, yb: float) -> void:
		if xb - xa < 0.01 or yb - ya < 0.01:
			return
		quad(ext, xf, Vector3(xa, ya, 0), Vector3(xb, ya, 0), Vector3(xb, yb, 0), Vector3(xa, yb, 0), Vector3.BACK)
		quad(int_m, xf, Vector3(xa, ya, zi), Vector3(xb, ya, zi), Vector3(xb, yb, zi), Vector3(xa, yb, zi), Vector3.FORWARD)
		if collide:
			var s := BoxShape3D.new()
			s.size = Vector3(xb - xa, yb - ya, T)
			shapes.append([s, xf * Transform3D(Basis.IDENTITY, Vector3((xa + xb) * 0.5, (ya + yb) * 0.5, -T * 0.5))])
	for col in cols:
		var xl: float = col[0]["xl"]
		var xr: float = col[0]["xr"]
		pan.call(x0, xl, 0.0, H)
		var y: float = 0.0
		for tr in col:
			var yb: float = tr["yb"]
			var yt: float = tr["yt"]
			pan.call(xl, xr, y, yb)
			y = yt
			# les tableaux (les côtés droits de la baie)
			var hs: Array = tr["haut"]
			var bs: Array = tr["bas"]
			var ys0: float = yb if bs.is_empty() else (bs[0] as Vector2).y
			var ys1: float = (hs[0] as Vector2).y
			if ys1 - ys0 > 0.01:
				quad("pierre_claire", xf, Vector3(xl, ys0, 0), Vector3(xl, ys1, 0), Vector3(xl, ys1, zi), Vector3(xl, ys0, zi), Vector3.RIGHT)
				quad("pierre_claire", xf, Vector3(xr, ys0, 0), Vector3(xr, ys1, 0), Vector3(xr, ys1, zi), Vector3(xr, ys0, zi), Vector3.LEFT)
			# l'appui (une baie à fond plat)
			if bs.is_empty() and yb > 0.01:
				quad("pierre_claire", xf, Vector3(xl, yb, 0), Vector3(xr, yb, 0), Vector3(xr, yb, zi), Vector3(xl, yb, zi), Vector3.UP)
			# l'arc : les écoinçons (entre l'arc et le dessus) sur les deux faces, et l'intrados
			for i in range(hs.size() - 1):
				var a: Vector2 = hs[i]
				var b: Vector2 = hs[i + 1]
				quad(ext, xf, Vector3(a.x, a.y, 0), Vector3(b.x, b.y, 0), Vector3(b.x, yt, 0), Vector3(a.x, yt, 0), Vector3.BACK)
				quad(int_m, xf, Vector3(a.x, a.y, zi), Vector3(b.x, b.y, zi), Vector3(b.x, yt, zi), Vector3(a.x, yt, zi), Vector3.FORWARD)
				quad("pierre_claire", xf, Vector3(a.x, a.y, 0), Vector3(b.x, b.y, 0), Vector3(b.x, b.y, zi), Vector3(a.x, a.y, zi), Vector3(0, -1, 0))
			for i in range(bs.size() - 1):
				var a2: Vector2 = bs[i]
				var b2: Vector2 = bs[i + 1]
				quad(ext, xf, Vector3(a2.x, a2.y, 0), Vector3(b2.x, b2.y, 0), Vector3(b2.x, yb, 0), Vector3(a2.x, yb, 0), Vector3.BACK)
				quad(int_m, xf, Vector3(a2.x, a2.y, zi), Vector3(b2.x, b2.y, zi), Vector3(b2.x, yb, zi), Vector3(a2.x, yb, zi), Vector3.FORWARD)
				quad("pierre_claire", xf, Vector3(a2.x, a2.y, 0), Vector3(b2.x, b2.y, 0), Vector3(b2.x, b2.y, zi), Vector3(a2.x, a2.y, zi), Vector3(0, 1, 0))
		pan.call(xl, xr, y, H)
		x0 = xr
	pan.call(x0, L * 0.5, 0.0, H)
	# le dessus du mur, les deux bouts
	quad(ext, xf, Vector3(-L * 0.5, H, 0), Vector3(L * 0.5, H, 0), Vector3(L * 0.5, H, zi), Vector3(-L * 0.5, H, zi), Vector3.UP)
	for e in [-1.0, 1.0]:
		quad(ext, xf, Vector3(e * L * 0.5, 0, 0), Vector3(e * L * 0.5, H, 0), Vector3(e * L * 0.5, H, zi), Vector3(e * L * 0.5, 0, zi), Vector3(e, 0, 0))

# =================================================================== sortie

## Le maillage (une surface par matière) ; les vitres, l'ardoise : avec leurs tangentes.
func commit(node_name: String) -> MeshInstance3D:
	var mesh := ArrayMesh.new()
	for k in _st:
		var st: SurfaceTool = _st[k]
		if k in _uv_mats or k == "ardoise":
			st.generate_tangents()
		st.index()
		st.commit(mesh)
		mesh.surface_set_material(mesh.get_surface_count() - 1, mat(k))
	_st.clear()
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = mesh
	return mi


## Le corps de collision (toutes les formes notées)
func body(node_name: String) -> StaticBody3D:
	var b := StaticBody3D.new()
	b.name = node_name
	b.collision_layer = 1
	b.collision_mask = 0
	for s in shapes:
		var cs := CollisionShape3D.new()
		cs.shape = s[0]
		cs.transform = s[1]
		b.add_child(cs)
	shapes.clear()
	return b
