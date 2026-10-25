extends "res://scripts/monstre_v70.gd"
## V71 : les monstres de l'Île de Montjoie (les monstres « de débutants » des aventuriers) et du
## Donjon des Mille Marches. Même règle que les autres (groupe « cibles_v28 », take_hit, butin,
## conseil à la première rencontre) :
##  - le slime (vert ; bleu et rose, un peu plus solides) : une petite gelée translucide au cœur
##    plus sombre, deux yeux ronds ; il avance par petits bonds écrasés, et fait « splotch » ;
##  - le Roi Gélatineux (le fond du donjon) : un slime de quatre mètres, une toute petite couronne
##    d'or ; il retombe lourdement (le sol tremble) et se divise aux deux tiers et au tiers ;
##  - la grenouille géante (le lac) : deux mètres, une peau tachetée et luisante, un sac vocal qui
##    gonfle ; elle bondit, fouette de la langue… et parfois AVALE le joueur (trois secondes dans le
##    noir, puis recraché, couvert de bave) ; la grenouille reine, la plus grosse du lac ;
##  - le gobelin (le Bois des Lutins) : petit, rapide, une lance de silex… et peureux : à bout de
##    forces, il détale ; le chef gobelin : un casque d'os, sa bannière en loques comme arme ;
##  - le navet fuyard (les Champs du Sud) : il se sauve en couinant, se replante, ne mord jamais ;
##    une petite tape l'attrape ;
##  - la mimique (le donjon) : un coffre en bois, tout pareil aux autres… qui dort ; à deux pas,
##    il ouvre un œil, sort ses dents et sa langue, et bondit.
## Petits plus pour les autres scripts :
##  - m.set_meta("butin_extra", [["cle_cuivre", 1]]) ajoute un objet au butin (la clé dans le
##    ventre d'une grenouille, le chapelet de Pétronille…) ;
##  - mimique : is_sleeping(), wake() ; tous : is_swallowing() (la grenouille qui a avalé le joueur).

const SPECS71 := {
	"slime": {"pv": 6, "vitesse": 1.7, "degats": 1, "portee": 1.5, "armer": 0.55, "repos": 1.5, "vue": 9.0, "laisse": 14.0,
		"rayon": 0.32, "haut": 0.22, "nom": "Slime", "bond": 5.2},
	"slime_bleu": {"pv": 10, "vitesse": 1.9, "degats": 1, "portee": 1.6, "armer": 0.5, "repos": 1.4, "vue": 10.0, "laisse": 15.0,
		"rayon": 0.34, "haut": 0.24, "nom": "Slime bleu", "bond": 5.6},
	"slime_rose": {"pv": 14, "vitesse": 2.0, "degats": 1, "portee": 1.7, "armer": 0.5, "repos": 1.3, "vue": 11.0, "laisse": 16.0,
		"rayon": 0.36, "haut": 0.25, "nom": "Slime rose", "bond": 6.0},
	"slime_roi": {"pv": 160, "vitesse": 1.25, "degats": 2, "portee": 3.4, "armer": 0.95, "repos": 1.6, "vue": 30.0, "laisse": 50.0,
		"rayon": 1.9, "haut": 0.9, "nom": "le Roi Gélatineux", "boss": true},
	"grenouille_geante": {"pv": 24, "vitesse": 2.1, "degats": 1, "portee": 2.6, "armer": 0.65, "repos": 1.6, "vue": 13.0, "laisse": 22.0,
		"rayon": 0.75, "haut": 0.45, "nom": "Grenouille géante", "bond": 8.0, "langue": 6.0, "avale": 0.33},
	"grenouille_reine": {"pv": 75, "vitesse": 2.0, "degats": 2, "portee": 3.6, "armer": 0.75, "repos": 1.6, "vue": 18.0, "laisse": 30.0,
		"rayon": 1.15, "haut": 0.6, "nom": "la Duchesse, Grenouille Reine du lac", "bond": 9.0, "langue": 8.5, "avale": 0.45, "chef": true},
	"gobelin": {"pv": 10, "vitesse": 3.0, "degats": 1, "portee": 1.9, "armer": 0.45, "repos": 1.1, "vue": 12.0, "laisse": 20.0,
		"rayon": 0.32, "haut": 0.55, "nom": "Gobelin"},
	"gobelin_chef": {"pv": 60, "vitesse": 2.3, "degats": 2, "portee": 2.7, "armer": 0.8, "repos": 1.4, "vue": 16.0, "laisse": 26.0,
		"rayon": 0.55, "haut": 0.95, "nom": "le Chef gobelin", "chef": true},
	"navet": {"pv": 1, "vitesse": 3.5, "degats": 0, "portee": 0.0, "armer": 1.0, "repos": 1.0, "vue": 7.0, "laisse": 40.0,
		"rayon": 0.22, "haut": 0.2, "nom": "Navet fuyard"},
	"mimique": {"pv": 26, "vitesse": 2.3, "degats": 2, "portee": 1.9, "armer": 0.5, "repos": 1.3, "vue": 2.0, "laisse": 14.0,
		"rayon": 0.5, "haut": 0.35, "nom": "Mimique", "bond": 6.0},
}
const SOUNDS71 := {"slime": ["slime_saut", "slime_mort"], "slime_bleu": ["slime_saut", "slime_mort"], "slime_rose": ["slime_saut", "slime_mort"],
	"slime_roi": ["slime_roi_cri", "slime_mort"], "grenouille_geante": ["grenouille_coasse", "grenouille_coasse"],
	"grenouille_reine": ["grenouille_coasse", "grenouille_coasse"], "gobelin": ["gobelin_cri", "gobelin_mort"],
	"gobelin_chef": ["gobelin_chef_cri", "gobelin_mort"], "navet": ["navet_cri", "navet_attrape"], "mimique": ["mimique_morsure", "coffre"]}
const LEAPERS71 := ["slime", "slime_bleu", "slime_rose", "grenouille_geante", "grenouille_reine", "mimique"]
const SLIMES := ["slime", "slime_bleu", "slime_rose"]
const FROGS := ["grenouille_geante", "grenouille_reine"]
## Les sauteurs : [période d'un bond (s), part au sol (squash), hauteur (m)]
const HOPS := {"slime": [0.62, 0.36, 0.3], "slime_bleu": [0.58, 0.36, 0.32], "slime_rose": [0.55, 0.35, 0.34],
	"slime_roi": [1.5, 0.45, 0.8], "grenouille_geante": [0.95, 0.42, 0.5], "grenouille_reine": [1.1, 0.42, 0.7], "mimique": [0.55, 0.4, 0.28]}
const GELEE := {"slime": Color(0.38, 0.88, 0.3), "slime_bleu": Color(0.3, 0.62, 1.0), "slime_rose": Color(1.0, 0.5, 0.74), "slime_roi": Color(0.42, 0.9, 0.36)}
const SEA71: float = -0.42
const FROG_S := {"grenouille_geante": 2.0, "grenouille_reine": 3.1}

static var _swallower: Node = null       # la grenouille qui a avalé le joueur (une seule à la fois)
static var _mesh71: Dictionary = {}       # maillages partagés (slime, navet, grenouille, feuille…)
static var _tex71: Dictionary = {}        # textures de bruit partagées (peau, cuir, bois)

var _base_speed: float = 0.0
var _hop_p: float = 0.0
var _hop_air: bool = false
var _hop_snd: float = 0.0
var _size_k: float = 1.0
var _phase71: int = 0
var _woken: bool = false
var _started: bool = false
var _gel: Node3D                          # slimes : le corps de gelée (squash and stretch)
var _crown: Node3D
var _frog: Node3D                         # grenouilles : le corps (à l'échelle)
var _sac: Node3D
var _fjaw: Node3D
var _tongue: Node3D
var _tongue_mesh: Node3D
var _tongue_tip: Node3D
var _tongue_hit: bool = false
var _hind: Array = []                     # [hanche, genou, cheville, côté]
var _croak_t: float = 3.0
var _croak: float = 0.0
var _swallow_cd: float = 0.0
var _sw_layer: CanvasLayer
var _sw_rect: ColorRect
var _sw_vr: Node3D
var _sw_from: Vector3 = Vector3.ZERO
var _sw_t: float = 0.0
var _flee_dir: Vector3 = Vector3.ZERO
var _flee_said: bool = false
var _lid: Node3D                          # mimique : la charnière du couvercle
var _mim_awake: Array = []                # dents, langue, yeux (cachés quand elle dort)
var _mim_tongue: Node3D
var _twitch: float = 6.0
var _nav: Node3D                          # navet : le corps
var _nav_mouth: Node3D
var _nav_legs: Array = []
var _nav_arms: Array = []
var _nav_leaves: Array = []
var _jump_from: Vector3
var _jump_to: Vector3
var _banner: Node3D
var _cs71: CollisionShape3D


func _v63() -> bool:
	return SPECS71.has(kind) or super._v63()


func _leaper() -> bool:
	return kind in LEAPERS71 or super._leaper()


func _sound_pair() -> Array:
	return SOUNDS71.get(kind, super._sound_pair())


func _armer_anim() -> void:
	match kind:
		"gobelin":
			_play("v28/slash1", 0.1, 0.9)
		"gobelin_chef":
			_play("v28/slash3", 0.1, 0.6)
		_:
			super._armer_anim()


func is_sleeping() -> bool:
	return kind == "mimique" and state == "dort"


func is_swallowing() -> bool:
	return state == "avale"


func setup(m: Node, k: String, at: Vector3) -> void:
	if not SPECS71.has(k):
		super.setup(m, k, at)
		return
	manager = m
	kind = k
	spec = (SPECS71[k] as Dictionary).duplicate()
	_base_speed = float(spec["vitesse"])
	home = at
	hp = int(spec["pv"])
	hit_radius = float(spec["rayon"])
	hit_height = float(spec["haut"])
	name = "Monstre_%s_%d" % [k, get_instance_id()]
	collision_layer = 1
	collision_mask = 1
	var cs := CollisionShape3D.new()
	match k:
		"slime", "slime_bleu", "slime_rose":
			var sp := SphereShape3D.new()
			sp.radius = 0.24
			cs.shape = sp
			cs.position.y = 0.24
		"slime_roi":
			var cap := CapsuleShape3D.new()
			cap.radius = 1.6
			cap.height = 3.2
			cs.shape = cap
			cs.position.y = 1.6
		"grenouille_geante", "grenouille_reine":
			var s: float = float(FROG_S[k])
			var cap2 := CapsuleShape3D.new()
			cap2.radius = 0.3 * s
			cap2.height = 0.95 * s
			cs.shape = cap2
			cs.rotation.x = PI * 0.5
			cs.position = Vector3(0, 0.3 * s, 0)
		"gobelin":
			var cap3 := CapsuleShape3D.new()
			cap3.radius = 0.22
			cap3.height = 1.05
			cs.shape = cap3
			cs.position.y = 0.53
		"gobelin_chef":
			var cap4 := CapsuleShape3D.new()
			cap4.radius = 0.36
			cap4.height = 1.85
			cs.shape = cap4
			cs.position.y = 0.93
		"navet":
			var sp2 := SphereShape3D.new()
			sp2.radius = 0.15
			cs.shape = sp2
			cs.position.y = 0.16
		"mimique":
			var b := BoxShape3D.new()
			b.size = Vector3(0.9, 0.7, 0.56)
			cs.shape = b
			cs.position.y = 0.36
	add_child(cs)
	_cs71 = cs
	_visual = Node3D.new()
	add_child(_visual)
	match k:
		"slime", "slime_bleu", "slime_rose":
			_build_slime(GELEE[k], 1.0, false)
		"slime_roi":
			_build_slime(GELEE[k], 6.6, true)
		"grenouille_geante", "grenouille_reine":
			_build_frog(float(FROG_S[k]), k == "grenouille_reine")
		"gobelin":
			_build_gobelin(false)
		"gobelin_chef":
			_build_gobelin(true)
		"navet":
			_build_navet()
		"mimique":
			_build_mimic()
	add_to_group("cibles_v28")
	add_to_group("monstres_v36")
	global_position = at
	facing = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
	if k == "mimique":
		state = "dort"
	elif k == "navet":
		state = "cache"
	_croak_t = randf_range(2.0, 6.0)


# =================================================================== outils

func _m71() -> Node:
	return manager.main if manager != null else null


func _sfx71(snd: String, at: Vector3, db: float = 0.0) -> void:
	var mn: Node = _m71()
	if mn != null and mn.has_method("sfx"):
		mn.sfx(snd, at, db)


func _near_player(r: float) -> bool:
	var mn: Node = _m71()
	if mn == null or not mn.has_method("_player_pos_v27"):
		return false
	return global_position.distance_to(mn._player_pos_v27()) < r


func _dot_tex() -> Texture2D:
	var mn: Node = _m71()
	if mn != null and mn.has_method("_soft_dot_v24"):
		return mn._soft_dot_v24()
	return null


## Une texture de bruit (taches, grain de peau, cuir…), partagée entre tous les monstres.
func _noise_tex(key: String, seed_i: int, freq: float, cols: Array, normal: bool = false, bump: float = 8.0, cellular: bool = false) -> Texture2D:
	var kk: String = key + ("_n" if normal else "")
	if _tex71.has(kk):
		return _tex71[kk]
	var nt := NoiseTexture2D.new()
	nt.width = 512
	nt.height = 512
	nt.seamless = true
	var fn := FastNoiseLite.new()
	fn.seed = seed_i
	fn.frequency = freq
	fn.fractal_octaves = 4
	if cellular:
		fn.noise_type = FastNoiseLite.TYPE_CELLULAR
		fn.cellular_return_type = FastNoiseLite.RETURN_DISTANCE2_DIV
	nt.noise = fn
	if normal:
		nt.as_normal_map = true
		nt.bump_strength = bump
	else:
		var g := Gradient.new()
		var offs := PackedFloat32Array()
		var cc := PackedColorArray()
		for c in cols:
			offs.append(float(c[0]))
			cc.append(c[1])
		g.offsets = offs
		g.colors = cc
		nt.color_ramp = g
	_tex71[kk] = nt
	return nt


func _skin71(key: String, seed_i: int, freq: float, cols: Array, rough: float, scale_uv: float, bump: float = 6.0, cellular: bool = false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = _noise_tex(key, seed_i, freq, cols, false, bump, cellular)
	m.normal_enabled = true
	m.normal_texture = _noise_tex(key, seed_i + 7, freq * 1.7, [], true, bump, cellular)
	m.normal_scale = 0.8
	m.roughness = rough
	m.uv1_triplanar = true
	m.uv1_scale = Vector3.ONE * scale_uv
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_flash_mats.append(m)
	return m


## Maillage « grille » : des anneaux fermés (même nombre de points), du premier au dernier ;
## normales lissées calculées sur la grille, faces vers l'extérieur (Godot : sens horaire).
static func _grid71(rows: Array, cols: Array = [], closed: bool = true, ctr: Array = []) -> ArrayMesh:
	var nr: int = rows.size()
	var n: int = (rows[0] as PackedVector3Array).size()
	var centers: Array = ctr.duplicate()
	if centers.size() != nr:
		centers.clear()
		for i in range(nr):
			var c := Vector3.ZERO
			for p in rows[i]:
				c += p
			centers.append(c / float(n))
	var norms: Array = []
	for i in range(nr):
		var ring := PackedVector3Array()
		var row: PackedVector3Array = rows[i]
		var up_r: PackedVector3Array = rows[mini(i + 1, nr - 1)]
		var dn_r: PackedVector3Array = rows[maxi(i - 1, 0)]
		for j in range(n):
			var jn: int = (j + 1) % n if closed else mini(j + 1, n - 1)
			var jp: int = (j - 1 + n) % n if closed else maxi(j - 1, 0)
			var du: Vector3 = row[jn] - row[jp]
			var dv: Vector3 = up_r[j] - dn_r[j]
			var nn: Vector3 = du.cross(dv)
			var out: Vector3 = row[j] - (centers[i] as Vector3)
			if nn.length() < 1e-9 or out.length() < 1e-6:
				# un pôle : la direction depuis l'anneau voisin
				var nb: Vector3 = centers[1] if i == 0 else centers[nr - 2]
				nn = row[j] - nb
				out = nn
			nn = nn.normalized()
			if nn.dot(out) < 0.0:
				nn = -nn
			ring.append(nn)
		norms.append(ring)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var has_c: bool = cols.size() == nr
	for i in range(nr - 1):
		for j in range(n if closed else n - 1):
			var j2: int = (j + 1) % n
			var q: Array = [[i, j, float(j)], [i, j2, float(j + 1)], [i + 1, j2, float(j + 1)], [i + 1, j, float(j)]]
			for tri in [[0, 1, 2], [0, 2, 3]]:
				var a: Array = q[tri[0]]
				var b: Array = q[tri[1]]
				var c2: Array = q[tri[2]]
				var pa: Vector3 = rows[a[0]][a[1]]
				var pb: Vector3 = rows[b[0]][b[1]]
				var pc: Vector3 = rows[c2[0]][c2[1]]
				var g: Vector3 = (pb - pa).cross(pc - pa)
				if g.length() < 1e-12:
					continue
				var nsum: Vector3 = norms[a[0]][a[1]] + norms[b[0]][b[1]] + norms[c2[0]][c2[1]]
				var order: Array = [a, b, c2] if g.dot(nsum) < 0.0 else [a, c2, b]
				for v in order:
					st.set_normal(norms[v[0]][v[1]])
					st.set_uv(Vector2(float(v[2]) / float(n), float(v[0]) / float(nr - 1)))
					if has_c:
						st.set_color((cols[v[0]] as PackedColorArray)[v[1]])
					st.add_vertex(rows[v[0]][v[1]])
	return st.commit()


## Un tour (révolution autour de Y) : prof = [Vector2(rayon, y)], du bas vers le haut.
static func _lathe71(prof: Array, seg: int, wob: float = 0.0, cols: Array = []) -> ArrayMesh:
	var rows: Array = []
	var crow: Array = []
	for i in range(prof.size()):
		var pr: Vector2 = prof[i]
		var ring := PackedVector3Array()
		var cr := PackedColorArray()
		for j in range(seg):
			var a: float = TAU * float(j) / float(seg)
			var r: float = pr.x * (1.0 + wob * sin(a * 3.0 + pr.y * 9.0) + wob * 0.6 * sin(a * 5.0 - pr.y * 13.0))
			ring.append(Vector3(sin(a) * r, pr.y, cos(a) * r))
			if cols.size() == prof.size():
				cr.append(cols[i])
		rows.append(ring)
		crow.append(cr)
	return _grid71(rows, crow if cols.size() == prof.size() else [])


## Un rubis, une pièce, une étincelle : petite boule brillante.
func _glow_mat(c: Color, e: float) -> StandardMaterial3D:
	var m := _mat(c, 0.15, e)
	m.metallic_specular = 1.0
	return m


func _gold_mat() -> StandardMaterial3D:
	var g := _mat(Color(1.0, 0.77, 0.3), 0.22)
	g.metallic = 1.0
	return g


func _wet_mat(c: Color, rough: float) -> StandardMaterial3D:
	var m := _mat(c, rough)
	m.clearcoat_enabled = true
	m.clearcoat = 0.8
	m.clearcoat_roughness = 0.15
	m.metallic_specular = 0.8
	return m


func _tube(parent: Node3D, pts: Array, r0: float, r1: float, mat: Material, sides: int = 8) -> MeshInstance3D:
	var path: PackedVector3Array = PB.smooth_path(pts, 12)
	var radii := PackedFloat32Array()
	for i in range(path.size()):
		radii.append(lerpf(r0, r1, float(i) / float(path.size() - 1)))
	var mi := MeshInstance3D.new()
	mi.mesh = PB.tube_mesh(path, radii, sides, 0.0, 0.0, Color(1, 1, 1), Color(1, 1, 1))
	mi.material_override = mat
	parent.add_child(mi)
	return mi


# =================================================================== les slimes

func _jelly(c: Color, a: float, prio: int = 0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(c.r, c.g, c.b, a)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.04
	m.metallic_specular = 1.0
	m.clearcoat_enabled = true
	m.clearcoat = 1.0
	m.clearcoat_roughness = 0.03
	m.rim_enabled = true
	m.rim = 0.4
	m.rim_tint = 0.7
	m.emission_enabled = true
	m.emission = Color(c.r * 0.5, c.g * 0.5, c.b * 0.5)
	m.emission_energy_multiplier = 0.35
	m.refraction_enabled = true
	m.refraction_scale = 0.03
	m.render_priority = prio
	_flash_mats.append(m)
	return m


func _slime_mesh() -> ArrayMesh:
	if _mesh71.has("slime"):
		return _mesh71["slime"]
	var R: float = 0.3
	var H: float = 0.46
	var prof: Array = []
	var m: int = 18
	for i in range(m + 1):
		var a: float = lerpf(-PI * 0.5, PI * 0.5, float(i) / float(m))
		var s: float = sin(a)
		var c: float = maxf(cos(a), 0.0)
		if a < 0.0:
			prof.append(Vector2(R * pow(c, 0.32), 0.15 * H * (1.0 + s)))
		else:
			prof.append(Vector2(R * pow(c, 0.85) * (1.0 - 0.1 * s), 0.15 * H + 0.85 * H * s))
	var mesh: ArrayMesh = _lathe71(prof, 30, 0.018)
	_mesh71["slime"] = mesh
	return mesh


## Un slime : la gelée, un cœur plus sombre, deux grands yeux, une petite bouche ; s = échelle
## (le Roi : 6,6, avec sa couronne et ce qu'il a avalé au fil des ans).
func _build_slime(c: Color, s: float, roi: bool) -> void:
	_gel = Node3D.new()
	_gel.name = "Gelee"
	_gel.scale = Vector3.ONE * s
	_visual.add_child(_gel)
	_body_node = _gel
	var shell := _jelly(c, 0.46 if not roi else 0.55, 1)
	shell.emission_energy_multiplier = 0.2
	var core := _jelly(c.darkened(0.55), 0.85, 0)
	core.refraction_enabled = false
	var body := MeshInstance3D.new()
	body.mesh = _slime_mesh()
	body.material_override = shell
	_gel.add_child(body)
	_mesh(_gel, _sphere(0.15), core, Vector3(0, 0.15, -0.02), Vector3(1.0, 0.85, 1.0))
	# une seconde épaisseur de gelée, plus claire : du volume, comme un vrai bonbon
	var vol := _jelly(c.lightened(0.15), 0.22, 0)
	vol.refraction_enabled = false
	var inner := MeshInstance3D.new()
	inner.mesh = _slime_mesh()
	inner.material_override = vol
	inner.scale = Vector3(0.86, 0.84, 0.86)
	inner.position.y = 0.01
	_gel.add_child(inner)
	# des bulles prises dans la gelée
	var bub := _jelly(Color(1, 1, 1), 0.35, 2)
	bub.refraction_enabled = false
	for k in range(5):
		var a: float = TAU * k / 5.0 + 0.4
		_mesh(_gel, _sphere(0.012 + 0.006 * (k % 3)), bub, Vector3(cos(a) * 0.16, 0.08 + 0.05 * (k % 3), sin(a) * 0.14 - 0.03))
	# les yeux (grands, ronds, brillants) et la bouche
	var white := _wet_mat(Color(0.97, 0.97, 0.95), 0.1)
	var pupil := _wet_mat(Color(0.03, 0.03, 0.04), 0.05)
	var shine := _mat(Color(1, 1, 1), 0.1, 3.0)
	for sx in [-1.0, 1.0]:
		var th: float = sx * 0.3
		var y: float = 0.25
		var r: float = 0.258
		var p := Vector3(sin(th) * r, y, cos(th) * r)
		_mesh(_gel, _sphere(0.05), white, p, Vector3(1.0, 1.2, 0.55), Vector3(0, th, 0))
		_mesh(_gel, _sphere(0.03), pupil, p + Vector3(sin(th) * 0.022, -0.004, cos(th) * 0.022), Vector3(1.0, 1.15, 0.5), Vector3(0, th, 0))
		_mesh(_gel, _sphere(0.009), shine, p + Vector3(sin(th) * 0.03 + 0.008, 0.016, cos(th) * 0.03), Vector3(1, 1, 0.5))
		if roi:
			# des sourcils froncés : il est très, très vexé qu'on vienne chez lui
			var brow := _wet_mat(c.darkened(0.6), 0.3)
			_tube(_gel, [p + Vector3(-sx * 0.035, 0.07, 0.01), p + Vector3(0, 0.083, 0.015), p + Vector3(sx * 0.04, 0.095, 0.0)], 0.009, 0.006, brow, 6)
	var mouth := _mat(Color(0.05, 0.12, 0.06) if not roi else Color(0.06, 0.1, 0.04), 0.4)
	var mp: Array = []
	for k2 in range(5):
		var t: float = lerpf(-0.13, 0.13, float(k2) / 4.0)
		var dip: float = (0.012 if not roi else -0.008) * (1.0 - pow(t / 0.13, 2.0))
		mp.append(Vector3(sin(t) * 0.272, 0.185 - dip, cos(t) * 0.272))
	_tube(_gel, mp, 0.008, 0.008, mouth, 6)
	if roi:
		_build_crown()
		_swallowed_junk(c)
		var l := OmniLight3D.new()
		l.light_color = c.lightened(0.3)
		l.light_energy = 0.8
		l.omni_range = 7.0
		l.position = Vector3(0, 1.4, 0)
		_visual.add_child(l)


## La petite couronne d'or (ridiculement petite pour un tel roi), un peu de travers.
func _build_crown() -> void:
	_crown = Node3D.new()
	_crown.name = "Couronne"
	_crown.position = Vector3(0.012, 0.445, 0.0)
	_crown.rotation = Vector3(0.12, 0, -0.2)
	_crown.scale = Vector3.ONE * 1.35
	_gel.add_child(_crown)
	var gold := _gold_mat()
	var band := CylinderMesh.new()
	band.top_radius = 0.034
	band.bottom_radius = 0.031
	band.height = 0.018
	band.cap_top = false
	band.cap_bottom = true
	band.radial_segments = 20
	var bm := MeshInstance3D.new()
	bm.mesh = band
	bm.material_override = gold
	_crown.add_child(bm)
	var ruby := _glow_mat(Color(0.85, 0.05, 0.1), 0.6)
	var saph := _glow_mat(Color(0.1, 0.25, 0.95), 0.6)
	for k in range(5):
		var a: float = TAU * k / 5.0
		var p := Vector3(cos(a) * 0.032, 0.017, sin(a) * 0.032)
		_mesh(_crown, _cyl(0.0, 0.009, 0.02), gold, p, Vector3(1.0, 1.0, 0.5), Vector3(0, -a, 0))
		_mesh(_crown, _sphere(0.004), gold, p + Vector3(0, 0.011, 0))
		_mesh(_crown, _sphere(0.0045), ruby if k % 2 == 0 else saph, Vector3(cos(a + 0.6) * 0.034, 0.0, sin(a + 0.6) * 0.034))


## Ce que le Roi a avalé au fil des siècles : une vieille botte, des pièces, une clé.
func _swallowed_junk(c: Color) -> void:
	var leather := _mat(Color(0.3, 0.18, 0.1), 0.8)
	var boot := Node3D.new()
	boot.position = Vector3(0.08, 0.2, 0.05)
	boot.rotation = Vector3(0.6, 0.8, 0.3)
	_gel.add_child(boot)
	_mesh(boot, _cyl(0.014, 0.016, 0.05), leather, Vector3(0, 0.025, 0))
	_mesh(boot, _sphere(0.017), leather, Vector3(0, -0.002, 0.016), Vector3(1.0, 0.7, 1.6))
	var gold := _gold_mat()
	for k in range(6):
		var a: float = k * 1.7
		_mesh(_gel, _cyl(0.008, 0.008, 0.002), gold, Vector3(cos(a) * 0.1 - 0.04, 0.06 + k * 0.02, sin(a) * 0.08), Vector3.ONE, Vector3(a, 0.3, a * 0.5))
	var iron := _mat(Color(0.45, 0.4, 0.35), 0.5)
	iron.metallic = 0.7
	var key := Node3D.new()
	key.position = Vector3(-0.1, 0.27, -0.05)
	key.rotation = Vector3(0.3, 0, 1.0)
	_gel.add_child(key)
	_mesh(key, _cyl(0.0025, 0.0025, 0.05), iron, Vector3.ZERO)
	var ring := TorusMesh.new()
	ring.inner_radius = 0.006
	ring.outer_radius = 0.009
	_mesh(key, ring, iron, Vector3(0, 0.03, 0), Vector3.ONE, Vector3(PI * 0.5, 0, 0))
	_mesh(key, _box_mesh_g(Vector3(0.012, 0.008, 0.003)), iron, Vector3(0.006, -0.02, 0))


# =================================================================== les grenouilles

## Le corps de la grenouille, en deux morceaux : le dos (tacheté) et le ventre (crème).
func _frog_mesh(part: String) -> ArrayMesh:
	if _mesh71.has("frog_" + part):
		return _mesh71["frog_" + part]
	# sections le long du corps (z, demi-largeur, demi-hauteur, hauteur du centre), de l'arrière au museau
	var secs: Array = [[-0.5, 0.02, 0.02, 0.15], [-0.47, 0.15, 0.12, 0.16], [-0.41, 0.25, 0.18, 0.18], [-0.3, 0.32, 0.22, 0.2],
		[-0.16, 0.35, 0.225, 0.23], [-0.02, 0.345, 0.205, 0.25], [0.08, 0.335, 0.18, 0.27], [0.18, 0.325, 0.16, 0.28],
		[0.27, 0.3, 0.14, 0.285], [0.35, 0.255, 0.118, 0.28], [0.42, 0.19, 0.092, 0.275], [0.47, 0.11, 0.065, 0.27], [0.5, 0.02, 0.025, 0.265]]
	var n: int = 32
	var split: float = -0.42           # sinus de l'angle où le dos rejoint le ventre
	var rows_b: Array = []
	var rows_v: Array = []
	var ctr: Array = []
	for sc in secs:
		var w: float = float(sc[1])
		var h: float = float(sc[2])
		var back := PackedVector3Array()
		var bel := PackedVector3Array()
		var a0: float = asin(split)
		# le dos : de a0 (côté droit) en passant par le haut jusqu'à PI - a0 ; le ventre : le reste
		for j in range(n + 1):
			var a: float = lerpf(a0, PI - a0, float(j) / float(n))
			back.append(_frog_pt(a, w, h, float(sc[3]), float(sc[0])))
		for j2 in range(n / 2 + 1):
			var a2: float = lerpf(PI - a0, TAU + a0, float(j2) / float(n / 2))
			bel.append(_frog_pt(a2, w, h, float(sc[3]), float(sc[0])))
		rows_b.append(back)
		rows_v.append(bel)
		ctr.append(Vector3(0, float(sc[3]), float(sc[0])))
	_mesh71["frog_dos"] = _grid71(rows_b, [], false, ctr)
	_mesh71["frog_ventre"] = _grid71(rows_v, [], false, ctr)
	return _mesh71["frog_" + part]


static func _frog_pt(a: float, w: float, h: float, c: float, z: float) -> Vector3:
	var sa: float = sin(a)
	# le dos un peu bosselé (deux bourrelets), le ventre plus plat
	var ridge: float = 1.0 + 0.05 * exp(-pow((absf(cos(a)) - 0.5) * 6.0, 2.0)) * maxf(sa, 0.0)
	var y: float = c + (h * sa * ridge if sa > 0.0 else h * 0.72 * sa)
	return Vector3(w * cos(a) * ridge, y, z)


func _frog_skin(reine: bool) -> StandardMaterial3D:
	var cols: Array
	if reine:
		cols = [[0.0, Color(0.16, 0.14, 0.06)], [0.42, Color(0.2, 0.18, 0.07)], [0.5, Color(0.32, 0.36, 0.14)], [0.75, Color(0.4, 0.44, 0.18)], [1.0, Color(0.46, 0.42, 0.2)]]
	else:
		cols = [[0.0, Color(0.15, 0.16, 0.05)], [0.4, Color(0.19, 0.2, 0.06)], [0.48, Color(0.33, 0.45, 0.14)], [0.8, Color(0.42, 0.55, 0.2)], [1.0, Color(0.5, 0.5, 0.22)]]
	var m := _skin71("grenouille" + ("_r" if reine else ""), 711 if not reine else 712, 0.022, cols, 0.32, 1.6, 5.0)
	m.clearcoat_enabled = true
	m.clearcoat = 0.7
	m.clearcoat_roughness = 0.2
	m.metallic_specular = 0.7
	m.rim_enabled = true
	m.rim = 0.15
	return m


## La grenouille géante (et la Reine) : un corps lisse et luisant, tacheté, deux yeux dorés qui
## dépassent du crâne, un sac vocal sous le menton, des cuisses énormes repliées. Vers +Z.
func _build_frog(s: float, reine: bool) -> void:
	_frog = Node3D.new()
	_frog.name = "Grenouille"
	_frog.scale = Vector3.ONE * s
	_visual.add_child(_frog)
	_body_node = _frog
	var skin := _frog_skin(reine)
	var belly := _skin71("ventre_grenouille", 713, 0.05, [[0.0, Color(0.78, 0.74, 0.52)], [1.0, Color(0.92, 0.88, 0.66)]], 0.5, 2.0, 3.0)
	var body := MeshInstance3D.new()
	body.mesh = _frog_mesh("dos")
	body.material_override = skin
	_frog.add_child(body)
	var under := MeshInstance3D.new()
	under.mesh = _frog_mesh("ventre")
	under.material_override = belly
	_frog.add_child(under)
	# les yeux : de grosses billes dorées, une pupille horizontale, posées sur deux bosses
	var iris := _wet_mat(Color(0.78, 0.55, 0.12), 0.08)
	iris.emission_enabled = true
	iris.emission = Color(0.5, 0.3, 0.05)
	iris.emission_energy_multiplier = 0.25
	var pupil := _wet_mat(Color(0.02, 0.02, 0.02), 0.05)
	var shine := _mat(Color(1, 1, 1), 0.1, 2.5)
	for sx in [-1.0, 1.0]:
		var ep := Vector3(sx * 0.16, 0.43, 0.26)
		_mesh(_frog, _sphere(0.085), skin, ep + Vector3(-sx * 0.01, -0.035, -0.01), Vector3(1.0, 0.75, 1.1))
		var eye := Node3D.new()
		eye.position = ep
		eye.rotation.y = sx * 0.4
		_frog.add_child(eye)
		_mesh(eye, _sphere(0.072), iris, Vector3.ZERO)
		_mesh(eye, _sphere(0.042), pupil, Vector3(0, 0.0, 0.05), Vector3(1.3, 0.45, 0.5))
		_mesh(eye, _sphere(0.012), shine, Vector3(0.022, 0.032, 0.06))
		# la paupière (un bourrelet de peau, juste au-dessus)
		_mesh(eye, _sphere(0.078), skin, Vector3(0, 0.03, -0.035), Vector3(1.06, 0.62, 1.0))
		# les narines
		_mesh(_frog, _sphere(0.008), pupil, Vector3(sx * 0.04, 0.355, 0.475), Vector3(1.0, 0.6, 0.8))
		# le tympan (un disque brun derrière l'œil)
		_mesh(_frog, _cyl(0.038, 0.038, 0.01), _wet_mat(Color(0.36, 0.3, 0.14), 0.3), Vector3(sx * 0.285, 0.355, 0.15), Vector3.ONE, Vector3(0, 0, sx * PI * 0.5))
	# la bouche : une longue fente de coin à coin
	var lip := _mat(Color(0.12, 0.1, 0.05), 0.4)
	for sx2 in [-1.0, 1.0]:
		_tube(_frog, [Vector3(sx2 * 0.318, 0.29, 0.1), Vector3(sx2 * 0.31, 0.285, 0.24), Vector3(sx2 * 0.24, 0.282, 0.38), Vector3(sx2 * 0.12, 0.282, 0.465), Vector3(0, 0.283, 0.502)], 0.007, 0.006, lip, 6)
	# la mâchoire du bas (elle s'ouvre : on voit l'intérieur rose)
	_fjaw = Node3D.new()
	_fjaw.position = Vector3(0, 0.255, 0.1)
	_frog.add_child(_fjaw)
	_mesh(_fjaw, _sphere(1.0), belly, Vector3(0, -0.04, 0.2), Vector3(0.215, 0.045, 0.2))
	var inside := _wet_mat(Color(0.62, 0.22, 0.25), 0.2)
	_mesh(_fjaw, _sphere(1.0), inside, Vector3(0, -0.02, 0.2), Vector3(0.19, 0.03, 0.18))
	_jaw_low = _fjaw
	# le sac vocal : il gonfle quand elle coasse
	_sac = Node3D.new()
	_sac.position = Vector3(0, 0.17, 0.27)
	_frog.add_child(_sac)
	var sacm := _wet_mat(Color(0.86, 0.8, 0.5), 0.2)
	sacm.subsurf_scatter_enabled = true
	sacm.subsurf_scatter_strength = 0.4
	_mesh(_sac, _sphere(0.11), sacm, Vector3.ZERO, Vector3(1.25, 0.85, 1.0))
	_sac.scale = Vector3.ONE * 0.4
	# la langue (rose, collante), roulée dans la bouche
	_tongue = Node3D.new()
	_tongue.position = Vector3(0, 0.265, 0.42)
	_frog.add_child(_tongue)
	var tm := _wet_mat(Color(0.9, 0.45, 0.52), 0.18)
	_tongue_mesh = Node3D.new()
	_tongue.add_child(_tongue_mesh)
	_mesh(_tongue_mesh, _cyl(0.022, 0.026, 1.0), tm, Vector3(0, 0, 0.5), Vector3(1.0, 1.0, 0.55), Vector3(PI * 0.5, 0, 0))
	_tongue_tip = Node3D.new()
	_tongue.add_child(_tongue_tip)
	_mesh(_tongue_tip, _sphere(0.045), tm, Vector3.ZERO, Vector3(1.2, 0.7, 1.0))
	_tongue.visible = false
	# les pattes avant (fines, quatre doigts aux pelotes rondes)
	var pad := _wet_mat(Color(0.42, 0.44, 0.24), 0.3)
	for sx3 in [-1.0, 1.0]:
		var sh := Node3D.new()
		sh.position = Vector3(sx3 * 0.22, 0.17, 0.2)
		_frog.add_child(sh)
		var el := Vector3(sx3 * 0.11, -0.07, 0.0)
		var wr := Vector3(sx3 * 0.12, -0.16, 0.08)
		_stick(sh, Vector3.ZERO, el, 0.05, skin)
		_mesh(sh, _sphere(0.045), skin, el)
		_stick(sh, el, wr, 0.036, skin)
		for f in range(4):
			var fa: float = (-0.7 + f * 0.47) * sx3 + sx3 * 0.35
			var tip := wr + Vector3(sin(fa) * 0.07, -0.006, cos(fa) * 0.07)
			_stick(sh, wr, tip, 0.01, skin)
			_mesh(sh, _sphere(0.012), pad, tip, Vector3(1.0, 0.6, 1.0))
		_legs.append([sh, sx3, 1.0])
	# les pattes arrière : cuisse énorme, jambe, long pied palmé (repliées le long du corps)
	var web := _wet_mat(Color(0.36, 0.42, 0.16), 0.35)
	web.cull_mode = BaseMaterial3D.CULL_DISABLED
	for sx4 in [-1.0, 1.0]:
		var hip := Node3D.new()
		hip.position = Vector3(sx4 * 0.25, 0.2, -0.3)
		_frog.add_child(hip)
		var knee_p := Vector3(sx4 * 0.14, -0.06, 0.24)
		_mesh(hip, _sphere(0.1), skin, knee_p * 0.5, Vector3(0.95, 0.9, 1.9), Vector3(0, atan2(knee_p.x, knee_p.z), 0))
		var knee := Node3D.new()
		knee.position = knee_p
		hip.add_child(knee)
		var ank_p := Vector3(sx4 * -0.02, -0.07, -0.3)
		_mesh(knee, _sphere(0.06), skin, ank_p * 0.5, Vector3(0.85, 0.8, 2.6), Vector3(0, atan2(ank_p.x, ank_p.z), 0))
		var ank := Node3D.new()
		ank.position = ank_p
		knee.add_child(ank)
		var toes: Array = []
		for t in range(5):
			var ta: float = sx4 * (0.05 + t * 0.12)
			var tl: float = 0.2 + 0.05 * sin(float(t) / 4.0 * PI)
			var tp := Vector3(sin(ta) * tl, -0.035, cos(ta) * tl)
			_stick(ank, Vector3(0, -0.02, 0), tp, 0.012, skin)
			_mesh(ank, _sphere(0.013), pad, tp, Vector3(1.0, 0.6, 1.0))
			toes.append(tp)
		# la palmure entre les doigts
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for t2 in range(4):
			for v in [Vector3(0, -0.025, 0.02), toes[t2] * 0.92, toes[t2 + 1] * 0.92]:
				st.set_normal(Vector3.UP)
				st.add_vertex(v)
		var wm := MeshInstance3D.new()
		wm.mesh = st.commit()
		wm.material_override = web
		ank.add_child(wm)
		_hind.append([hip, knee, ank, sx4])
	if reine:
		# la Reine porte un nénuphar sur la tête, et une fleur rose : c'est sa couronne
		var lily := _wet_mat(Color(0.22, 0.42, 0.14), 0.4)
		lily.cull_mode = BaseMaterial3D.CULL_DISABLED
		var pad_n := Node3D.new()
		pad_n.position = Vector3(0, 0.45, 0.08)
		pad_n.rotation = Vector3(-0.12, 0.4, 0.08)
		_frog.add_child(pad_n)
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.13
		cyl.bottom_radius = 0.13
		cyl.height = 0.006
		cyl.radial_segments = 24
		_mesh(pad_n, cyl, lily, Vector3.ZERO)
		var petal := _mat(Color(1.0, 0.62, 0.78), 0.5)
		petal.cull_mode = BaseMaterial3D.CULL_DISABLED
		for p in range(8):
			var pa: float = TAU * p / 8.0
			_mesh(pad_n, _sphere(0.03), petal, Vector3(cos(pa) * 0.03, 0.03, sin(pa) * 0.03), Vector3(0.5, 0.35, 1.0), Vector3(0.6, -pa + PI * 0.5, 0))
		_mesh(pad_n, _sphere(0.015), _mat(Color(1.0, 0.85, 0.25), 0.5), Vector3(0, 0.035, 0))


# =================================================================== les gobelins

func _gob_skin(chef: bool) -> StandardMaterial3D:
	var base: Color = Color(0.27, 0.36, 0.17) if not chef else Color(0.24, 0.31, 0.16)
	var m := _skin71("gobelin" + ("_c" if chef else ""), 721 if not chef else 722, 0.012,
		[[0.0, base.darkened(0.25)], [0.45, base], [0.75, base.lightened(0.06)], [1.0, Color(0.36, 0.36, 0.2)]], 0.58, 1.2, 1.5)
	m.normal_scale = 0.35
	m.subsurf_scatter_enabled = true
	m.subsurf_scatter_strength = 0.2
	m.rim_enabled = true
	m.rim = 0.12
	return m


## Un membre : un fuseau effilé de l'os « a » à l'os « b », une articulation discrète au départ.
func _limb71(skel: Skeleton3D, a: String, b: String, r0: float, r1: float, mat: Material) -> void:
	var ia: int = skel.find_bone(a)
	var ib: int = skel.find_bone(b)
	if ia < 0 or ib < 0:
		return
	var v: Vector3 = skel.get_bone_global_rest(ib).origin - skel.get_bone_global_rest(ia).origin
	var len_m: float = v.length() * 0.01
	if len_m < 0.01:
		return
	var holder := Node3D.new()
	var dir: Vector3 = v.normalized()
	var xb: Vector3 = dir.cross(Vector3.FORWARD if absf(dir.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
	var zb: Vector3 = xb.cross(dir).normalized()
	holder.transform = Transform3D(Basis(xb, dir, zb), dir * len_m * 0.5)
	var c := CylinderMesh.new()
	c.top_radius = r1
	c.bottom_radius = r0
	c.height = len_m * 1.02
	c.radial_segments = 12
	c.rings = 3
	_mesh(holder, c, mat, Vector3.ZERO)
	# un léger renflement du muscle, au tiers
	_mesh(holder, _sphere(maxf(r0, r1) * 1.05), mat, Vector3(0, -len_m * 0.15, 0), Vector3(1.0, len_m * 0.32 / maxf(r0, r1), 1.0))
	_mesh(holder, _sphere(r0 * 0.98), mat, Vector3(0, -len_m * 0.5, 0))
	_attach(skel, a, Vector3.ZERO, holder)


func _leather71() -> StandardMaterial3D:
	return _skin71("cuir", 731, 0.06, [[0.0, Color(0.2, 0.12, 0.07)], [0.6, Color(0.33, 0.21, 0.12)], [1.0, Color(0.42, 0.3, 0.18)]], 0.8, 3.0, 7.0)


func _wood71() -> StandardMaterial3D:
	var m := _skin71("bois", 741, 0.04, [[0.0, Color(0.25, 0.16, 0.08)], [0.5, Color(0.4, 0.27, 0.14)], [1.0, Color(0.48, 0.34, 0.19)]], 0.75, 2.0, 5.0)
	m.uv1_scale = Vector3(2.0, 14.0, 2.0)
	return m


## Une jupe de cuir aux bords déchiquetés (un anneau, le bas en dents de scie).
func _rag_skirt(r0: float, r1: float, h: float, seed_i: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_i
	var n: int = 18
	var top := PackedVector3Array()
	var mid := PackedVector3Array()
	var bot := PackedVector3Array()
	for j in range(n):
		var a: float = TAU * float(j) / float(n)
		var hh: float = h * rng.randf_range(0.65, 1.1) * (0.8 if j % 2 == 0 else 1.0)
		top.append(Vector3(sin(a) * r0, 0, cos(a) * r0))
		mid.append(Vector3(sin(a) * lerpf(r0, r1, 0.5), -hh * 0.5, cos(a) * lerpf(r0, r1, 0.5)))
		bot.append(Vector3(sin(a) * r1 * rng.randf_range(0.95, 1.08), -hh, cos(a) * r1 * rng.randf_range(0.95, 1.08)))
	return _grid71([bot, mid, top])


## Un drapeau en loques (rectangle déchiqueté qui pend, légèrement ondulé).
func _rag_flag(w: float, h: float, seed_i: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_i
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var nx: int = 8
	var ny: int = 6
	var grid: Array = []
	for iy in range(ny + 1):
		var row: Array = []
		for ix in range(nx + 1):
			var u: float = float(ix) / float(nx)
			var v: float = float(iy) / float(ny)
			var tear: float = 0.0
			if iy == ny:
				tear = rng.randf_range(0.0, 0.3) * h
			row.append(Vector3(u * w, -v * h - tear, sin(u * 7.0 + v * 2.0) * 0.03 * u))
		grid.append(row)
	for iy2 in range(ny):
		for ix2 in range(nx):
			# des trous, çà et là
			if iy2 > 1 and rng.randf() < 0.07:
				continue
			var a: Vector3 = grid[iy2][ix2]
			var b: Vector3 = grid[iy2][ix2 + 1]
			var c: Vector3 = grid[iy2 + 1][ix2 + 1]
			var d: Vector3 = grid[iy2 + 1][ix2]
			for v3 in [a, b, c, a, c, d]:
				st.set_normal(Vector3(0, 0, 1))
				st.set_uv(Vector2(v3.x / w, -v3.y / h))
				st.add_vertex(v3)
	return st.commit()


## Le gobelin (et son chef) : la silhouette du héros pour les mouvements, mais petite, verte,
## noueuse ; une grosse tête aux oreilles pointues, un nez crochu, des yeux jaunes ; un pagne de
## cuir déchiré ; une lance de silex (le chef : casque d'os, cape de fourrure, sa bannière).
func _build_gobelin(chef: bool) -> void:
	var s: float = 0.6 if not chef else 1.02
	var skel: Skeleton3D = _humanoid(s)
	if skel == null:
		return
	var skin := _gob_skin(chef)
	var leather := _leather71()
	var dark := _mat(Color(0.05, 0.04, 0.03), 0.6)
	var k: float = 1.0 if not chef else 1.25
	for pair in [["LeftArm", "LeftForeArm", 0.055, 0.04], ["LeftForeArm", "LeftHand", 0.042, 0.03], ["RightArm", "RightForeArm", 0.055, 0.04], ["RightForeArm", "RightHand", 0.042, 0.03],
			["LeftUpLeg", "LeftLeg", 0.08, 0.05], ["LeftLeg", "LeftFoot", 0.055, 0.035], ["RightUpLeg", "RightLeg", 0.08, 0.05], ["RightLeg", "RightFoot", 0.055, 0.035],
			["Spine02", "LeftArm", 0.07, 0.055], ["Spine02", "RightArm", 0.07, 0.055], ["Spine02", "neck", 0.075, 0.06], ["neck", "Head", 0.06, 0.06]]:
		_limb71(skel, str(pair[0]), str(pair[1]), float(pair[2]) * k, float(pair[3]) * k, skin)
	# le torse : une petite bedaine, des épaules osseuses
	var torso := Node3D.new()
	_mesh(torso, _sphere(0.17 * k), skin, Vector3(0, 0.02, 0.02), Vector3(1.0, 1.05, 0.95))
	_attach(skel, "Spine01", Vector3.ZERO, torso)
	var chest := Node3D.new()
	_mesh(chest, _sphere(0.155 * k), skin, Vector3(0, 0.0, 0.0), Vector3(1.15, 0.95, 0.85))
	_attach(skel, "Spine02", Vector3(0, 4, 0), chest)
	var hips := Node3D.new()
	_mesh(hips, _sphere(0.14 * k), skin, Vector3.ZERO, Vector3(1.15, 0.8, 0.9))
	_attach(skel, "Hips", Vector3.ZERO, hips)
	# les mains (trois gros doigts) et les grands pieds nus
	for hb in ["LeftHand", "RightHand"]:
		var hn := Node3D.new()
		_mesh(hn, _sphere(0.045 * k), skin, Vector3(0, -0.03, 0), Vector3(1.0, 1.2, 0.8))
		for f in range(3):
			_mesh(hn, _cyl(0.008 * k, 0.012 * k, 0.07 * k), skin, Vector3((f - 1) * 0.022 * k, -0.08 * k, 0.01), Vector3.ONE, Vector3(0.2, 0, (f - 1) * 0.15))
		_attach(skel, hb, Vector3.ZERO, hn)
	for fb in ["LeftFoot", "RightFoot"]:
		var fn := Node3D.new()
		_mesh(fn, _sphere(0.07 * k), skin, Vector3(0, -0.04, 0.07), Vector3(0.85, 0.5, 1.6))
		for t in range(3):
			_mesh(fn, _sphere(0.022 * k), skin, Vector3((t - 1) * 0.035, -0.05, 0.17 * k), Vector3(1.0, 0.7, 1.2))
		_attach(skel, fb, Vector3.ZERO, fn)
	# la tête
	var head := Node3D.new()
	var R: float = 0.15 * (1.0 if not chef else 1.08)
	_mesh(head, _sphere(R), skin, Vector3(0, 0.04, 0.01), Vector3(1.0, 0.92, 1.05))
	_mesh(head, _sphere(R * 0.75), skin, Vector3(0, -0.04, 0.06), Vector3(1.05, 0.7, 1.0))
	# l'arcade sourcilière, le nez crochu, les oreilles en pointe
	_mesh(head, _sphere(R * 0.5), skin, Vector3(0, 0.07, 0.11), Vector3(1.7, 0.45, 0.6))
	var nose := Node3D.new()
	nose.position = Vector3(0, 0.02, R * 0.95)
	head.add_child(nose)
	_tube(nose, [Vector3(0, 0.03, -0.02), Vector3(0, 0.0, 0.05), Vector3(0, -0.04, 0.08), Vector3(0, -0.07, 0.065)], 0.032, 0.012, skin, 8)
	for sx in [-1.0, 1.0]:
		_tube(head, [Vector3(sx * R * 0.85, 0.05, -0.01), Vector3(sx * (R + 0.08), 0.1, -0.04), Vector3(sx * (R + 0.17), 0.17, -0.07), Vector3(sx * (R + 0.24), 0.22, -0.09)], 0.05, 0.004, skin, 8)
		# les yeux jaunes, la pupille en fente
		var eye := Node3D.new()
		eye.position = Vector3(sx * 0.055, 0.035, R * 0.86)
		head.add_child(eye)
		_mesh(eye, _sphere(0.032), _wet_mat(Color(0.95, 0.75, 0.12), 0.1), Vector3.ZERO, Vector3(1.0, 0.85, 0.7))
		_mesh(eye, _sphere(0.016), _wet_mat(Color(0.02, 0.02, 0.02), 0.05), Vector3(0, 0, 0.02), Vector3(0.45, 1.25, 0.5))
		_mesh(eye, _sphere(0.006), _mat(Color(1, 1, 1), 0.1, 2.0), Vector3(0.008, 0.012, 0.026))
		# des verrues
		_mesh(head, _sphere(0.012), skin, Vector3(sx * 0.1, -0.03 + sx * 0.02, R * 0.78))
	# la bouche : un grand sourire de travers, deux crocs qui dépassent
	_tube(head, [Vector3(-0.07, -0.06, 0.12), Vector3(-0.03, -0.075, 0.14), Vector3(0.03, -0.072, 0.142), Vector3(0.075, -0.055, 0.12)], 0.007, 0.006, dark, 6)
	var tooth := _mat(Color(0.92, 0.88, 0.7), 0.4)
	for tx in [-0.035, 0.04]:
		_mesh(head, _cyl(0.0, 0.009, 0.03), tooth, Vector3(tx, -0.06, 0.138), Vector3.ONE, Vector3(0.2, 0, 0))
	# quelques mèches noires
	var hair := _mat(Color(0.16, 0.12, 0.08), 0.8)
	for h in range(5):
		var ha: float = -0.9 + h * 0.45
		_tube(head, [Vector3(sin(ha) * 0.06, R * 0.95, -0.02), Vector3(sin(ha) * 0.1, R + 0.04, -0.07), Vector3(sin(ha) * 0.14, R - 0.02, -0.13)], 0.005, 0.0015, hair, 5)
	_attach(skel, "Head", Vector3(0, 9, 1), head)
	# le pagne de cuir déchiré et la ceinture de corde
	var skirt := Node3D.new()
	var sm := leather.duplicate() as StandardMaterial3D
	sm.cull_mode = BaseMaterial3D.CULL_DISABLED
	_flash_mats.append(sm)
	var sk := MeshInstance3D.new()
	sk.mesh = _rag_skirt(0.16 * k, 0.22 * k, 0.24 * k, 7100 + int(chef))
	sk.material_override = sm
	skirt.add_child(sk)
	_mesh(skirt, _cyl(0.175 * k, 0.175 * k, 0.04), _mat(Color(0.55, 0.45, 0.28), 0.9), Vector3(0, -0.01, 0))
	_attach(skel, "Hips", Vector3(0, 5, 0), skirt)
	# une bandoulière de cuir en travers du torse
	var strap := Node3D.new()
	_mesh(strap, _box_mesh_g(Vector3(0.05, 0.42 * k, 0.02)), leather, Vector3(0, 0, 0.13 * k), Vector3.ONE, Vector3(0, 0, 0.7))
	_mesh(strap, _box_mesh_g(Vector3(0.05, 0.42 * k, 0.02)), leather, Vector3(0, 0, -0.13 * k), Vector3.ONE, Vector3(0, 0, -0.7))
	_attach(skel, "Spine02", Vector3(0, 0, 0), strap)
	if chef:
		_chef_parts(skel, skin, leather)
	else:
		# la lance : un bâton noueux, une pointe de silex taillée, ligaturée de cuir
		_spear = Node3D.new()
		var wood := _wood71()
		_mesh(_spear, _cyl(0.018, 0.022, 1.45), wood, Vector3(0, 0.25, 0))
		var flint := _mat(Color(0.22, 0.22, 0.24), 0.35)
		flint.metallic_specular = 0.8
		var tip := CylinderMesh.new()
		tip.top_radius = 0.0
		tip.bottom_radius = 0.045
		tip.height = 0.2
		tip.radial_segments = 4
		_mesh(_spear, tip, flint, Vector3(0, 1.07, 0), Vector3(1.0, 1.0, 0.35))
		_mesh(_spear, _cyl(0.026, 0.026, 0.07), leather, Vector3(0, 0.95, 0))
		_mesh(_spear, _box_mesh_g(Vector3(0.02, 0.12, 0.004)), _mat(Color(0.6, 0.15, 0.1), 0.9), Vector3(0.03, 0.88, 0), Vector3.ONE, Vector3(0, 0, -0.3))
		var att := BoneAttachment3D.new()
		att.bone_name = "RightHand"
		skel.add_child(att)
		var hold := Node3D.new()
		hold.position = Vector3(0, 8.5, 2.5)
		hold.rotation_degrees = Vector3(0, 0, 180)
		hold.scale = Vector3.ONE * 100.0
		att.add_child(hold)
		hold.add_child(_spear)
	_play("v28/idle")


func _chef_parts(skel: Skeleton3D, skin: Material, leather: Material) -> void:
	# le casque d'os : un crâne de bête, deux cornes
	var bone := _skin71("os", 751, 0.05, [[0.0, Color(0.62, 0.56, 0.44)], [1.0, Color(0.86, 0.82, 0.7)]], 0.7, 3.0, 5.0)
	var helm := Node3D.new()
	_mesh(helm, _sphere(0.175), bone, Vector3(0, 0.08, -0.01), Vector3(1.02, 0.7, 1.1))
	_mesh(helm, _box_mesh_g(Vector3(0.12, 0.06, 0.12)), bone, Vector3(0, 0.07, 0.15), Vector3.ONE, Vector3(-0.3, 0, 0))
	var hole := _mat(Color(0.02, 0.02, 0.02), 0.9)
	for sx in [-1.0, 1.0]:
		_mesh(helm, _sphere(0.03), hole, Vector3(sx * 0.05, 0.1, 0.16), Vector3(1.0, 0.8, 0.5))
	_mesh(helm, _cyl(0.0, 0.012, 0.03), hole, Vector3(0, 0.06, 0.2), Vector3.ONE, Vector3(PI * 0.5, 0, 0))
	_horns(helm, Vector3(0, 0.13, -0.01), 0.11, 1.15, Color(0.75, 0.7, 0.58))
	_attach(skel, "Head", Vector3(0, 12, 0), helm)
	# la cape de fourrure sur les épaules
	var fur := _skin71("fourrure", 761, 0.12, [[0.0, Color(0.15, 0.11, 0.08)], [1.0, Color(0.32, 0.24, 0.16)]], 0.95, 4.0, 10.0)
	var mantle := Node3D.new()
	for f in range(10):
		var a: float = lerpf(-2.2, 2.2, float(f) / 9.0)
		_mesh(mantle, _cyl(0.025, 0.06, 0.24), fur, Vector3(sin(a) * 0.17, -0.02, cos(a) * 0.13 - 0.02), Vector3.ONE, Vector3(-0.4 * cos(a), 0, 0.45 * sin(a)))
	_attach(skel, "Spine02", Vector3(0, 14, -2), mantle)
	# la bannière en loques sur sa hampe, qu'il manie comme un gourdin
	_banner = Node3D.new()
	var wood := _wood71()
	_mesh(_banner, _cyl(0.024, 0.03, 2.3), wood, Vector3(0, 0.75, 0))
	_mesh(_banner, _cyl(0.014, 0.014, 0.62), wood, Vector3(0.28, 1.78, 0), Vector3.ONE, Vector3(0, 0, PI * 0.5))
	var cloth := _skin71("banniere", 771, 0.06, [[0.0, Color(0.32, 0.06, 0.05)], [0.6, Color(0.5, 0.1, 0.07)], [1.0, Color(0.58, 0.2, 0.1)]], 0.92, 3.0, 4.0)
	cloth.cull_mode = BaseMaterial3D.CULL_DISABLED
	var flag := MeshInstance3D.new()
	flag.mesh = _rag_flag(0.58, 0.75, 4242)
	flag.material_override = cloth
	flag.position = Vector3(0.0, 1.77, 0.0)
	_banner.add_child(flag)
	# le symbole peint (un croissant de lune jaune, tout de travers)
	var paint := _mat(Color(0.85, 0.7, 0.2), 0.9)
	_mesh(_banner, _cyl(0.1, 0.1, 0.004), paint, Vector3(0.27, 1.45, 0.04), Vector3.ONE, Vector3(PI * 0.5, 0, 0))
	_mesh(_banner, _cyl(0.085, 0.085, 0.006), cloth, Vector3(0.3, 1.47, 0.045), Vector3.ONE, Vector3(PI * 0.5, 0, 0))
	var bone2 := _mesh(_banner, _sphere(0.06), bone, Vector3(0, 1.96, 0), Vector3(1.0, 1.1, 1.15))
	bone2.name = "Crane"
	for sx2 in [-1.0, 1.0]:
		_mesh(_banner, _sphere(0.016), hole, Vector3(sx2 * 0.022, 1.97, 0.055))
	var att := BoneAttachment3D.new()
	att.bone_name = "RightHand"
	skel.add_child(att)
	var hold := Node3D.new()
	hold.position = Vector3(0, 8.5, 2.5)
	hold.rotation_degrees = Vector3(0, 0, 180)
	hold.scale = Vector3.ONE * 100.0
	att.add_child(hold)
	hold.add_child(_banner)
	_spear = _banner


# =================================================================== le navet

func _navet_mesh() -> ArrayMesh:
	if _mesh71.has("navet"):
		return _mesh71["navet"]
	var prof: Array = [Vector2(0.0, 0.0), Vector2(0.006, 0.025), Vector2(0.016, 0.05), Vector2(0.04, 0.08), Vector2(0.08, 0.11), Vector2(0.11, 0.14),
		Vector2(0.125, 0.17), Vector2(0.123, 0.2), Vector2(0.11, 0.228), Vector2(0.085, 0.252), Vector2(0.05, 0.268), Vector2(0.02, 0.276), Vector2(0.0, 0.278)]
	var cols: Array = []
	for p in prof:
		var t: float = smoothstep(0.15, 0.235, (p as Vector2).y)
		cols.append(Color(0.96, 0.94, 0.88).lerp(Color(0.56, 0.14, 0.46), t))
	var mesh: ArrayMesh = _lathe71(prof, 22, 0.02, cols)
	_mesh71["navet"] = mesh
	return mesh


func _leaf_mesh() -> ArrayMesh:
	if _mesh71.has("feuille"):
		return _mesh71["feuille"]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n: int = 10
	var L: float = 0.24
	var pts: Array = []
	for i in range(n + 1):
		var t: float = float(i) / float(n)
		var w: float = 0.055 * sin(t * PI) * (1.0 + 0.25 * sin(t * PI * 5.0)) * (1.0 - 0.3 * t)
		var y: float = t * L
		var z: float = -0.06 * t * t
		pts.append([Vector3(-w, y, z + absf(w) * 0.3), Vector3(0, y, z), Vector3(w, y, z + absf(w) * 0.3)])
	for i in range(n):
		for side in [0, 2]:
			var a: Vector3 = pts[i][1]
			var b: Vector3 = pts[i][side]
			var c: Vector3 = pts[i + 1][side]
			var d: Vector3 = pts[i + 1][1]
			for v in [a, b, c, a, c, d]:
				st.set_normal(Vector3(0, 0.3, 1).normalized())
				st.set_uv(Vector2(v.x * 5.0 + 0.5, v.y / L))
				st.add_vertex(v)
	var mesh: ArrayMesh = st.commit()
	_mesh71["feuille"] = mesh
	return mesh


## Le navet fuyard : une racine blanche et violette, un bouquet de feuilles, deux yeux de jais,
## une petite bouche, et des jambes-radicelles toutes fines pour courir.
func _build_navet() -> void:
	_nav = Node3D.new()
	_nav.name = "Navet"
	_nav.scale = Vector3.ONE * 1.35
	_visual.add_child(_nav)
	_body_node = _nav
	var rm := StandardMaterial3D.new()
	rm.vertex_color_use_as_albedo = true
	rm.albedo_texture = _noise_tex("navet_grain", 781, 0.08, [[0.0, Color(0.86, 0.84, 0.82)], [1.0, Color(1, 1, 1)]])
	rm.uv1_triplanar = true
	rm.uv1_scale = Vector3.ONE * 6.0
	rm.roughness = 0.42
	rm.clearcoat_enabled = true
	rm.clearcoat = 0.3
	_flash_mats.append(rm)
	var bulb := MeshInstance3D.new()
	bulb.mesh = _navet_mesh()
	bulb.material_override = rm
	_nav.add_child(bulb)
	# quelques radicelles
	var hairm := _mat(Color(0.85, 0.82, 0.74), 0.8)
	for r in range(4):
		var ra: float = r * 1.9
		_tube(_nav, [Vector3(cos(ra) * 0.05, 0.08, sin(ra) * 0.05), Vector3(cos(ra) * 0.09, 0.05, sin(ra) * 0.09), Vector3(cos(ra) * 0.11, 0.02, sin(ra) * 0.1)], 0.003, 0.001, hairm, 4)
	# le bouquet de feuilles
	var leaf := _mat(Color(0.24, 0.52, 0.14), 0.55)
	leaf.cull_mode = BaseMaterial3D.CULL_DISABLED
	leaf.backlight_enabled = true
	leaf.backlight = Color(0.25, 0.45, 0.1)
	var stalk := _mat(Color(0.42, 0.55, 0.22), 0.6)
	for l in range(6):
		var a: float = TAU * l / 6.0
		var lp := Node3D.new()
		lp.position = Vector3(0, 0.27, 0)
		lp.rotation = Vector3(0, a, 0)
		_nav.add_child(lp)
		var tilt: float = 0.35 + 0.15 * (l % 2)
		_tube(lp, [Vector3.ZERO, Vector3(0, 0.05, 0.015), Vector3(0, 0.1, 0.05 + tilt * 0.05)], 0.008, 0.005, stalk, 5)
		var blade := MeshInstance3D.new()
		blade.mesh = _leaf_mesh()
		blade.material_override = leaf
		blade.position = Vector3(0, 0.09, 0.05)
		blade.rotation = Vector3(tilt, 0, 0)
		blade.scale = Vector3.ONE * (0.9 + 0.2 * (l % 3) * 0.5)
		lp.add_child(blade)
		_nav_leaves.append([lp, a, tilt])
	# le visage
	var bead := _wet_mat(Color(0.03, 0.03, 0.03), 0.05)
	var shine := _mat(Color(1, 1, 1), 0.1, 2.5)
	for sx in [-1.0, 1.0]:
		var ep := Vector3(sx * 0.04, 0.19, 0.115)
		_mesh(_nav, _sphere(0.014), bead, ep, Vector3(1.0, 1.25, 0.6))
		_mesh(_nav, _sphere(0.004), shine, ep + Vector3(0.004, 0.006, 0.008))
	_nav_mouth = Node3D.new()
	_nav_mouth.position = Vector3(0, 0.155, 0.122)
	_nav.add_child(_nav_mouth)
	_mesh(_nav_mouth, _sphere(0.012), _mat(Color(0.25, 0.04, 0.06), 0.5), Vector3.ZERO, Vector3(1.3, 0.5, 0.4))
	# les jambes et les bras (des radicelles)
	var root := _mat(Color(0.9, 0.86, 0.76), 0.7)
	for sx2 in [-1.0, 1.0]:
		var leg := Node3D.new()
		leg.position = Vector3(sx2 * 0.035, 0.05, 0)
		_nav.add_child(leg)
		_stick(leg, Vector3.ZERO, Vector3(sx2 * 0.01, -0.1, 0.0), 0.008, root)
		_mesh(leg, _sphere(0.018), root, Vector3(sx2 * 0.01, -0.105, 0.012), Vector3(1.0, 0.5, 1.6))
		_nav_legs.append([leg, sx2])
		var arm := Node3D.new()
		arm.position = Vector3(sx2 * 0.11, 0.14, 0.01)
		_nav.add_child(arm)
		_stick(arm, Vector3.ZERO, Vector3(sx2 * 0.07, -0.04, 0.02), 0.006, root)
		_nav_arms.append([arm, sx2])
	_nav.position.y = -0.17


# =================================================================== la mimique

## La mimique : un coffre exactement comme les autres (les mêmes planches, les mêmes ferrures),
## qui cache des dents, une langue, et deux yeux jaunes.
func _build_mimic() -> void:
	var body := Node3D.new()
	body.name = "Coffre"
	_visual.add_child(body)
	_body_node = body
	var ob: Node = _m71().get("objets_v66") if _m71() != null else null
	var real: bool = ob != null and ob.has_method("_chest_mesh")
	if real:
		var c := MeshInstance3D.new()
		c.mesh = ob.call("_chest_mesh", "corps")
		body.add_child(c)
	else:
		var wood := _skin71("bois_coffre", 791, 0.05, [[0.0, Color(0.3, 0.19, 0.1)], [1.0, Color(0.5, 0.33, 0.18)]], 0.7, 4.0, 6.0)
		var iron := _mat(Color(0.2, 0.2, 0.22), 0.45)
		iron.metallic = 0.7
		_mesh(body, _box_mesh_g(Vector3(0.9, 0.46, 0.55)), wood, Vector3(0, 0.23, 0))
		for sx in [-0.3, 0.3]:
			_mesh(body, _box_mesh_g(Vector3(0.07, 0.47, 0.565)), iron, Vector3(sx, 0.23, 0))
	_lid = Node3D.new()
	_lid.name = "Charniere"
	_lid.position = Vector3(0, 0.46, -0.275)
	body.add_child(_lid)
	if real:
		var l := MeshInstance3D.new()
		l.mesh = ob.call("_chest_mesh", "couvercle")
		_lid.add_child(l)
	else:
		var wood2 := _skin71("bois_coffre", 791, 0.05, [[0.0, Color(0.3, 0.19, 0.1)], [1.0, Color(0.5, 0.33, 0.18)]], 0.7, 4.0, 6.0)
		_mesh(_lid, _cyl(0.275, 0.275, 0.9), wood2, Vector3(0, 0, 0.275), Vector3(1.0, 1.0, 1.0), Vector3(0, 0, PI * 0.5))
	# les dents (rangée du bas, sur le bord du coffre ; rangée du haut, sous le couvercle)
	var tooth := _mat(Color(0.95, 0.92, 0.8), 0.35)
	tooth.clearcoat_enabled = true
	tooth.clearcoat = 0.5
	var gum := _wet_mat(Color(0.55, 0.12, 0.16), 0.3)
	var lower := Node3D.new()
	body.add_child(lower)
	_mim_awake.append(lower)
	_mesh(lower, _box_mesh_g(Vector3(0.84, 0.03, 0.5)), gum, Vector3(0, 0.44, 0))
	for i in range(9):
		var x: float = lerpf(-0.38, 0.38, float(i) / 8.0)
		_mesh(lower, _cyl(0.0, 0.022, 0.07 + 0.02 * (i % 2)), tooth, Vector3(x, 0.49, 0.24))
	for sx2 in [-1.0, 1.0]:
		for j in range(4):
			_mesh(lower, _cyl(0.0, 0.018, 0.06), tooth, Vector3(sx2 * 0.42, 0.48, lerpf(-0.18, 0.18, float(j) / 3.0)))
	var upper := Node3D.new()
	_lid.add_child(upper)
	_mim_awake.append(upper)
	_mesh(upper, _box_mesh_g(Vector3(0.84, 0.02, 0.5)), gum, Vector3(0, 0.005, 0.275))
	for i2 in range(8):
		var x2: float = lerpf(-0.35, 0.35, float(i2) / 7.0)
		_mesh(upper, _cyl(0.022, 0.0, 0.07 + 0.025 * (i2 % 2)), tooth, Vector3(x2, -0.035, 0.515))
	# les yeux, au fond, sous le couvercle
	var eyes := Node3D.new()
	_lid.add_child(eyes)
	_mim_awake.append(eyes)
	var glow := _mat(Color(1.0, 0.82, 0.2), 0.2, 4.0)
	var slit := _mat(Color(0.02, 0.02, 0.02), 0.3)
	for sx3 in [-1.0, 1.0]:
		_mesh(eyes, _sphere(0.04), glow, Vector3(sx3 * 0.13, -0.03, 0.12), Vector3(1.0, 0.8, 0.6))
		_mesh(eyes, _sphere(0.02), slit, Vector3(sx3 * 0.13, -0.03, 0.142), Vector3(0.4, 1.1, 0.4))
	# la langue : longue, rose, baveuse, qui pend par-dessus le bord
	_mim_tongue = Node3D.new()
	_mim_tongue.position = Vector3(0, 0.45, 0.05)
	body.add_child(_mim_tongue)
	_mim_awake.append(_mim_tongue)
	var tm := _wet_mat(Color(0.88, 0.38, 0.48), 0.15)
	var tp: Array = [Vector3(0, -0.02, -0.12), Vector3(0, 0.02, 0.1), Vector3(0.01, 0.03, 0.24), Vector3(0.02, -0.02, 0.3), Vector3(0.03, -0.14, 0.32), Vector3(0.0, -0.26, 0.31)]
	var tmi := _tube(_mim_tongue, tp, 0.034, 0.024, tm, 10)
	tmi.scale = Vector3(1.8, 1.0, 1.0)
	for n in _mim_awake:
		(n as Node3D).visible = false


# =================================================================== comportement

func is_hittable() -> bool:
	if SPECS71.has(kind):
		return state != "mort"
	return super.is_hittable()


func take_hit(damage: int, from_pos: Vector3) -> void:
	if not SPECS71.has(kind):
		super.take_hit(damage, from_pos)
		return
	if state == "mort":
		return
	var cb: Node = _m71().get("combat_v28") if _m71() != null else null
	if kind == "navet":
		# une petite tape suffit : attrapé !
		hp = 0
		if cb != null:
			cb.float_text(global_position + Vector3.UP * 0.8, "Attrapé !", Color(1.0, 0.9, 0.45))
			cb.puff(global_position + Vector3.UP * 0.2, Color(0.55, 0.42, 0.28))
		_die63()
		return
	if state == "dort":
		_wake(true)
	var dmg: int = damage * (2 if state == "avale" else 1)
	hp -= dmg
	_flash = 0.18
	var away: Vector3 = global_position - from_pos
	away.y = 0.0
	away = away.normalized() if away.length() > 0.01 else -facing
	var kb: float = 3.2 if kind in SLIMES else (2.6 if kind == "gobelin" else (1.0 if kind in ["grenouille_geante", "mimique"] else 0.3))
	if state != "avale":
		_knock = away * kb
	if cb != null:
		var at: Vector3 = global_position + Vector3.UP * (hit_height * 2.0 + 0.3)
		if state == "avale":
			cb.damage_number_color(at, dmg, Color(1.0, 0.6, 0.3), " x2")
		elif bool(cb.get("critical")):
			cb.damage_number_color(at, dmg, Color(1.0, 0.55, 0.2), " !")
		else:
			cb.damage_number(at, dmg)
		cb.puff(global_position + Vector3.UP * hit_height, _puff_color())
	if kind == "slime_roi":
		_king_split_check()
	if hp <= 0:
		if state == "avale":
			_spit()
		_die63()
		return
	if state == "avale":
		return
	if kind == "gobelin" and hp <= 3 and not (state in ["fuite", "tapi"]):
		_start_flee()
		return
	if is_boss() or is_chef() or state in ["fuite", "tapi", "langue", "saut_roi", "reveil"]:
		return
	state = "recul"
	timer = 0.25
	if kind == "gobelin":
		_play("v28/hurt", 0.05)


func _die63() -> void:
	if state == "avale":
		_spit()
	super._die63()
	match kind:
		"gobelin", "gobelin_chef":
			_play("Knock_Down", 0.1)
		"slime", "slime_bleu", "slime_rose", "slime_roi":
			_splat()
		"mimique":
			if _m71() != null and _m71().get("combat_v28") != null:
				for k in range(5):
					_m71().combat_v28.puff(global_position + Vector3(randf_range(-0.3, 0.3), 0.6, randf_range(-0.2, 0.3)), Color(1.0, 0.85, 0.35))
	if _tongue != null:
		_tongue.visible = false


## « Splotch » : une gerbe de gouttes de gelée.
func _splat() -> void:
	var c: Color = GELEE.get(kind, Color(0.4, 0.9, 0.3))
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.emitting = true
	p.amount = 28 if kind != "slime_roi" else 70
	p.lifetime = 0.9
	p.explosiveness = 0.95
	p.local_coords = false
	p.direction = Vector3.UP
	p.spread = 70.0
	var s: float = 1.0 if kind != "slime_roi" else 4.0
	p.initial_velocity_min = 1.5 * sqrt(s)
	p.initial_velocity_max = 3.5 * sqrt(s)
	p.gravity = Vector3(0, -9.0, 0)
	p.scale_amount_min = 0.5 * s
	p.scale_amount_max = 1.2 * s
	var sm := SphereMesh.new()
	sm.radius = 0.035
	sm.height = 0.07
	sm.radial_segments = 6
	sm.rings = 3
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(c.r, c.g, c.b, 0.75)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.05
	m.emission_enabled = true
	m.emission = c * 0.4
	sm.material = m
	p.mesh = sm
	p.position = Vector3(0, 0.25 * s, 0)
	add_child(p)


func _physics_process(delta: float) -> void:
	if not SPECS71.has(kind):
		super._physics_process(delta)
		return
	if manager == null:
		return
	if not _started:
		_started = true
		# spawn_extra met tout le monde en chasse : la mimique dort, le navet reste planté
		if kind == "mimique" and not _woken and state != "mort":
			state = "dort"
		elif kind == "navet" and state != "mort":
			state = "cache"
	_swallow_cd = maxf(_swallow_cd - delta, 0.0)
	if kind == "navet":
		_navet_tick(delta)
		return
	if state in ["dort", "reveil", "avale", "fuite", "tapi", "langue", "saut_roi"]:
		_special_tick(delta)
		return
	if kind == "mimique" and state == "veille" and Vector2(global_position.x - home.x, global_position.z - home.z).length() < 0.6:
		# revenue à sa place : elle se rendort, l'air de rien
		state = "dort"
		spec["vue"] = float(SPECS71["mimique"]["vue"])
		for n in _mim_awake:
			(n as Node3D).visible = false
	_pre_hop(delta)
	if kind in FROGS and state == "frappe":
		_frog_bite_check()
		if state == "avale":
			return
	if kind == "mimique" and state == "frappe" and not has_meta("claque"):
		set_meta("claque", true)
		_sfx71("mimique_morsure", global_position + Vector3.UP * 0.4)
	elif kind == "mimique" and state != "frappe" and has_meta("claque"):
		remove_meta("claque")
	super._physics_process(delta)


## Les bonds (slimes, grenouilles, mimique) : immobile pendant l'écrasement au sol, puis un saut.
func _pre_hop(delta: float) -> void:
	if not HOPS.has(kind):
		return
	var hp_: Array = HOPS[kind]
	var per: float = float(hp_[0])
	var gf: float = float(hp_[1])
	var from_home: float = Vector2(global_position.x - home.x, global_position.z - home.z).length()
	var want: bool = state == "chasse" or (state == "veille" and from_home > 1.0)
	if want or _hop_p > 0.0:
		var was_air: bool = _hop_air
		_hop_p += delta / per
		if _hop_p >= 1.0:
			_hop_p = fmod(_hop_p, 1.0) if want else 0.0
		_hop_air = _hop_p > gf
		if _hop_air and not was_air:
			_hop_snd -= 1.0
			if _near_player(16.0) and _hop_snd <= 0.0:
				_hop_snd = 2.0 if kind != "slime_roi" else 0.0
				if kind in SLIMES or kind == "slime_roi":
					_sfx71("slime_saut", global_position, -6.0 if kind != "slime_roi" else 0.0)
		elif not _hop_air and was_air and kind == "slime_roi" and _near_player(30.0):
			_sfx71("titan_pas", global_position, -4.0)
	else:
		_hop_air = false
	spec["vitesse"] = _base_speed / (1.0 - gf) if _hop_air else 0.0


func _frog_bite_check() -> void:
	if has_meta("mordu") or timer <= 0.08:
		return
	var p: Vector3 = _player()
	if manager.main.xr_active:
		p.y -= 1.5
	var to: Vector3 = p - global_position
	var dy: float = absf(to.y)
	to.y = 0.0
	# la gueule est au bout d'un long corps : elle mord loin devant le centre
	if to.length() < float(spec["rayon"]) + 0.9 + 0.5 * float(FROG_S.get(kind, 2.0)) and dy < 2.0:
		set_meta("mordu", true)
		if _can_swallow():
			_swallow()
		else:
			manager.hurt_player(int(spec["degats"]), global_position)


func _can_swallow() -> bool:
	if _swallow_cd > 0.0 or (_swallower != null and is_instance_valid(_swallower)):
		return false
	var mn: Node = manager.main
	var hero: Node = mn.get("hero_v28")
	if hero == null or str(hero.get("state")) in ["ko", "roulade"] or bool(hero.get("blocking")) or float(hero.get("hurt_cooldown")) > 0.0:
		return false
	if mn.get("boat_v29") != null and mn.boat_v29 != null and bool(mn.boat_v29.get("driving")):
		return false
	return randf() < float(spec.get("avale", 0.3))


# --------------------------------------------------------------- avalé !

func _player_feet() -> Vector3:
	var mn: Node = manager.main
	if mn.xr_active:
		if mn.get("vr_body") != null and mn.vr_body != null:
			return mn.vr_body.global_position
		return mn._player_pos_v27() + Vector3.DOWN * 1.6
	return mn.pc_root.global_position


func _swallow() -> void:
	var mn: Node = manager.main
	if has_meta("mordu"):
		remove_meta("mordu")
	state = "avale"
	_sw_t = 0.0
	timer = 3.0 if not mn.xr_active else 1.8
	_swallow_cd = 16.0
	_swallower = self
	_knock = Vector3.ZERO
	collision_layer = 0
	_sw_from = _player_feet()
	_sfx71("grenouille_avale", global_position + Vector3.UP)
	var hero: Node = mn.get("hero_v28")
	if not mn.xr_active:
		if mn.get("pc_hero") != null and mn.pc_hero != null:
			mn.pc_hero.visible = false
		mn.place_player_v35(global_position + Vector3.UP * 0.15, facing)
		_sw_from = mn.pc_root.global_position
		if hero != null:
			hero.state = "action"
			hero.action_time = 0.0
			hero.action_length = 99.0
		_sw_layer = CanvasLayer.new()
		_sw_layer.layer = 26
		manager.add_child(_sw_layer)
		_sw_rect = ColorRect.new()
		_sw_rect.color = Color(0.04, 0.07, 0.02, 0.0)
		_sw_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_sw_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_sw_layer.add_child(_sw_rect)
		var lb := Label.new()
		lb.text = "Beurk ! La grenouille t'a avalé…\n(Il fait tout noir, ça sent la vase, et c'est très, très gluant.)"
		lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lb.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		lb.add_theme_font_size_override("font_size", 34)
		lb.add_theme_color_override("font_color", Color(0.85, 1.0, 0.6))
		lb.add_theme_color_override("font_outline_color", Color(0.0, 0.05, 0.0))
		lb.add_theme_constant_override("outline_size", 10)
		_sw_rect.add_child(lb)
		create_tween().tween_property(_sw_rect, "color:a", 0.94, 0.25)
	else:
		# en VR : on ne déplace pas la tête du joueur ; l'écran s'assombrit, un message, on ne bouge plus
		_sw_vr = Node3D.new()
		mn.xr_camera.add_child(_sw_vr)
		var sph := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.25
		sm.height = 0.5
		sm.flip_faces = true
		sph.mesh = sm
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.no_depth_test = true
		m.render_priority = 98
		m.albedo_color = Color(0.04, 0.07, 0.02, 0.88)
		sph.material_override = m
		_sw_vr.add_child(sph)
		var l3 := Label3D.new()
		l3.text = "Beurk ! La grenouille t'a avalé…"
		l3.font_size = 48
		l3.pixel_size = 0.0011
		l3.outline_size = 10
		l3.modulate = Color(0.85, 1.0, 0.6)
		l3.no_depth_test = true
		l3.render_priority = 99
		l3.position = Vector3(0, 0, -0.2)
		_sw_vr.add_child(l3)
	var cm: Node = _compagnons()
	if cm != null and cm.has_method("on_player_swallowed"):
		cm.on_player_swallowed(self)


func _compagnons() -> Node:
	var mn: Node = manager.main
	var c: Node = mn.get("compagnons_v71") if mn != null else null
	if c == null and is_inside_tree():
		c = get_tree().get_first_node_in_group("compagnons_v71")
	return c


func _swallow_tick(delta: float) -> void:
	var mn: Node = manager.main
	var hero: Node = mn.get("hero_v28")
	_sw_t += delta
	timer -= delta
	if hero != null:
		hero.hurt_cooldown = maxf(float(hero.hurt_cooldown), 0.3)
	if not mn.xr_active:
		if hero != null:
			hero.state = "action"
			hero.action_time = 0.0
		if mn.pc_root.global_position.distance_to(_sw_from) > 0.4:
			mn.place_player_v35(_sw_from, facing)
			if hero != null:
				hero.state = "action"
	else:
		var f: Vector3 = _player_feet()
		if Vector2(f.x - _sw_from.x, f.z - _sw_from.z).length() > 0.08:
			mn.place_player_v35(_sw_from, facing)
	velocity = Vector3(0, -2.0 if not is_on_floor() else 0.0, 0)
	move_and_slide()
	if timer <= 0.0:
		_spit()


## Ptoui ! Le joueur est recraché à quelques mètres, couvert de bave.
func _spit() -> void:
	if _swallower != self:
		return
	var mn: Node = manager.main
	_swallower = null
	state = "souffle"
	timer = 2.4
	collision_layer = 1
	var hero: Node = mn.get("hero_v28")
	var s: float = float(FROG_S.get(kind, 2.0))
	var land: Vector3 = _sw_from
	if not mn.xr_active:
		var dirs: Array = [facing, facing.rotated(Vector3.UP, 0.8), facing.rotated(Vector3.UP, -0.8), -facing]
		for d in dirs:
			var cand: Vector3 = global_position + (d as Vector3) * (1.6 * s + 1.2)
			var gy: float = _ground_y71(cand, global_position.y)
			if gy > -1e8 and SEA71 - gy < 0.9:
				land = Vector3(cand.x, gy + 0.1, cand.z)
				break
		mn.place_player_v35(land, -facing)
		if mn.get("pc_hero") != null and mn.pc_hero != null:
			mn.pc_hero.visible = true
		if hero != null:
			hero.state = "sol"
	if _sw_rect != null and is_instance_valid(_sw_rect):
		var lay: CanvasLayer = _sw_layer
		var tw := _sw_rect.create_tween()
		tw.tween_property(_sw_rect, "color:a", 0.0, 0.35)
		tw.tween_callback(func(): if is_instance_valid(lay): lay.queue_free())
		for c in _sw_rect.get_children():
			c.queue_free()
	_sw_layer = null
	_sw_rect = null
	if _sw_vr != null and is_instance_valid(_sw_vr):
		_sw_vr.queue_free()
	_sw_vr = null
	_sfx71("grenouille_recrache", global_position + Vector3.UP)
	var lines: Array = ["Ptoui ! La grenouille te recrache… Tu es couvert de bave. Ça sent la vase.",
		"Pouah ! Recraché comme un noyau de cerise ! Tu dégoulines de bave verte.",
		"La grenouille fait la grimace et te recrache : visiblement, tu n'étais pas à son goût !",
		"Splortch ! Te revoilà dehors, gluant de la tête aux pieds. La grenouille a le hoquet."]
	if manager.donjon != null and manager.donjon.has_method("_say"):
		manager.donjon._say(lines[randi() % lines.size()], 4.5)
	_slobber(land if not mn.xr_active else _player_feet())
	if hero != null:
		hero.hurt_cooldown = 0.0
	manager.hurt_player(1, global_position)
	if hero != null:
		hero.hurt_cooldown = maxf(float(hero.hurt_cooldown), 1.2)


## De la bave qui dégouline du joueur pendant quelques secondes.
func _slobber(at: Vector3) -> void:
	var p := CPUParticles3D.new()
	p.amount = 30
	p.lifetime = 0.8
	p.local_coords = false
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(0.25, 0.7, 0.25)
	p.gravity = Vector3(0, -6.0, 0)
	p.initial_velocity_min = 0.0
	p.initial_velocity_max = 0.3
	var sm := SphereMesh.new()
	sm.radius = 0.02
	sm.height = 0.05
	sm.radial_segments = 6
	sm.rings = 3
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.7, 0.9, 0.45, 0.7)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.05
	sm.material = m
	p.mesh = sm
	var mn: Node = manager.main
	var holder: Node3D = mn.pc_root if not mn.xr_active else (mn.vr_body if mn.get("vr_body") != null else null)
	if holder == null:
		return
	holder.add_child(p)
	p.position = Vector3(0, 0.9, 0)
	get_tree().create_timer(4.0).timeout.connect(func(): if is_instance_valid(p): p.emitting = false)
	get_tree().create_timer(5.0).timeout.connect(func(): if is_instance_valid(p): p.queue_free())


func _exit_tree() -> void:
	if _swallower == self:
		_swallower = null
		var mn: Node = manager.main if manager != null else null
		if mn != null and not mn.xr_active and mn.get("pc_hero") != null and mn.pc_hero != null:
			mn.pc_hero.visible = true
			var hero: Node = mn.get("hero_v28")
			if hero != null and str(hero.state) == "action":
				hero.state = "sol"
	if _sw_layer != null and is_instance_valid(_sw_layer):
		_sw_layer.queue_free()
	if _sw_vr != null and is_instance_valid(_sw_vr):
		_sw_vr.queue_free()
	super._exit_tree()


func _ground_y71(at: Vector3, ref_y: float) -> float:
	if not is_inside_tree():
		return -1e9
	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(Vector3(at.x, ref_y + 2.5, at.z), Vector3(at.x, ref_y - 6.0, at.z), 1, [get_rid()])
	var hit := space.intersect_ray(q)
	if not hit.is_empty():
		return float((hit.position as Vector3).y)
	var mn: Node = _m71()
	if mn != null and mn.has_method("_height_at") and ref_y > -40.0:
		return float(mn._height_at(at.x, at.z))
	return -1e9


# --------------------------------------------------------------- états spéciaux

func _common71(delta: float) -> bool:
	_clock += delta
	if _flash > 0.0:
		_flash -= delta
	_apply_flash()
	if state == "mort":
		_death_tick(delta)
		return false
	if not manager.active:
		_animate63(delta, 0.0)
		return false
	return true


func _move71(move: Vector3, delta: float) -> void:
	if _knock.length() > 0.05:
		move += _knock
		_knock = _knock.move_toward(Vector3.ZERO, delta * 14.0)
	velocity.x = move.x
	velocity.z = move.z
	velocity.y = 0.0 if is_on_floor() else maxf(velocity.y - 18.0 * delta, -20.0)
	move_and_slide()
	rotation.y = atan2(facing.x, facing.z)
	_animate63(delta, Vector2(move.x, move.z).length())


func _special_tick(delta: float) -> void:
	if not _common71(delta):
		return
	if state == "avale":
		_swallow_tick(delta)
		_animate63(delta, 0.0)
		return
	var p: Vector3 = _player()
	if manager.main.xr_active:
		p.y -= 1.5
	var to_p: Vector3 = p - global_position
	var dy: float = absf(to_p.y)
	to_p.y = 0.0
	var dist: float = to_p.length()
	var dir_p: Vector3 = to_p / dist if dist > 0.01 else facing
	var move := Vector3.ZERO
	timer -= delta
	match state:
		"dort":
			_twitch -= delta
			if dist < float(spec["vue"]) and dy < 2.0:
				_wake(false)
		"reveil":
			facing = facing.lerp(dir_p, clampf(delta * 4.0, 0.0, 1.0)).normalized()
			if timer <= 0.0:
				state = "chasse"
		"fuite":
			var away: Vector3 = -dir_p
			var from_home := Vector3(home.x - global_position.x, 0, home.z - global_position.z)
			if from_home.length() > float(spec["laisse"]):
				away = (away + from_home.normalized() * 0.9).normalized()
			if _flee_dir == Vector3.ZERO:
				_flee_dir = away
			_flee_dir = _flee_dir.lerp(away, clampf(delta * 3.0, 0.0, 1.0)).normalized()
			if is_on_wall():
				_flee_dir = _flee_dir.rotated(Vector3.UP, PI * 0.5 * (1.0 if randf() < 0.5 else -1.0))
			move = _flee_dir * float(spec["vitesse"]) * 1.2
			facing = _flee_dir
			if timer <= 0.0 or dist > 17.0:
				state = "tapi"
				timer = 2.0
		"tapi":
			facing = facing.lerp(dir_p, clampf(delta * 3.0, 0.0, 1.0)).normalized()
			if dist < 6.0 and timer <= 0.0:
				_start_flee()
		"langue":
			_tongue_tick(delta, dist, dir_p)
		"saut_roi":
			_king_jump_tick(delta)
			return
	_move71(move, delta)


func _wake(by_hit: bool) -> void:
	if state != "dort":
		return
	_woken = true
	state = "reveil"
	timer = 0.75 if not by_hit else 0.35
	spec["vue"] = 9.0
	for n in _mim_awake:
		(n as Node3D).visible = true
	_sfx71("mimique_reveil", global_position + Vector3.UP * 0.4)
	manager.alert(self)


## La mimique se réveille (une interaction « ouvrir le coffre » peut l'appeler).
func wake() -> void:
	_woken = true
	_wake(false)


func _start_flee() -> void:
	state = "fuite"
	timer = randf_range(5.0, 7.0)
	_flee_dir = Vector3.ZERO
	_sfx71("gobelin_cri", global_position + Vector3.UP)
	if not _flee_said:
		_flee_said = true
		_hint70("Le gobelin lâche un cri aigu… et détale en couinant ! Quel courage.")


# --------------------------------------------------------------- la langue

func _tongue_tick(_delta: float, dist: float, dir_p: Vector3) -> void:
	var T: float = 0.8
	var t: float = T - timer
	facing = facing.lerp(dir_p, clampf(_delta * (6.0 if t < 0.2 else 1.0), 0.0, 1.0)).normalized()
	var reach: float = float(spec.get("langue", 6.0))
	var out: float = 0.0
	if t < 0.22:
		out = t / 0.22
	elif t < 0.34:
		out = 1.0
	else:
		out = clampf(1.0 - (t - 0.34) / 0.4, 0.0, 1.0)
	var L: float = minf(reach, dist + 0.3) * out
	if _tongue != null:
		_tongue.visible = out > 0.02
		var s: float = float(FROG_S.get(kind, 2.0))
		var ll: float = maxf(L / s - 0.05, 0.01)
		_tongue_mesh.scale = Vector3(1, 1, ll)
		_tongue_tip.position = Vector3(0, 0, ll)
		_tongue.rotation.x = -atan2(0.45, maxf(L, 0.5))
	if t >= 0.22 and not _tongue_hit:
		_tongue_hit = true
		if dist <= reach + 0.3 and facing.dot(dir_p) > 0.85:
			manager.hurt_player(int(spec["degats"]), global_position)
	if timer <= 0.0:
		state = "souffle"
		timer = float(spec["repos"]) * 0.8
		if _tongue != null:
			_tongue.visible = false


# --------------------------------------------------------------- le Roi Gélatineux

func _king_jump_tick(delta: float) -> void:
	var T: float = 1.35
	var t: float = T - timer
	var air0: float = 0.3
	var air1: float = 1.1
	if t >= air0 and t <= air1:
		var k: float = (t - air0) / (air1 - air0)
		var pos: Vector3 = _jump_from.lerp(_jump_to, k)
		velocity = Vector3((pos.x - global_position.x) / maxf(delta, 1e-4), 0.0, (pos.z - global_position.z) / maxf(delta, 1e-4))
		velocity.y = 0.0
		move_and_slide()
		_visual.position.y = sin(k * PI) * 2.6
	else:
		velocity = Vector3(0, 0.0 if is_on_floor() else -9.0, 0)
		move_and_slide()
		_visual.position.y = lerpf(_visual.position.y, 0.0, clampf(delta * 12.0, 0.0, 1.0))
	if t > air1 and not has_meta("atterri"):
		set_meta("atterri", true)
		_quake(global_position, 5.5)
		_sfx71("slime_roi_cri", global_position + Vector3.UP * 2.0)
		_hint70("BLOUOP ! Le Roi Gélatineux retombe de tout son poids : le sol tremble !")
	rotation.y = atan2(facing.x, facing.z)
	_animate63(delta, 0.0)
	if timer <= 0.0:
		remove_meta("atterri")
		state = "souffle"
		timer = 1.2


## Une onde de choc d'un rayon donné (le Roi qui retombe).
func _quake(at: Vector3, radius: float) -> void:
	var p: Vector3 = _player()
	if manager.main.xr_active:
		p.y -= 1.5
	if Vector2(p.x - at.x, p.z - at.z).length() < radius and absf(p.y - at.y) < 1.6:
		manager.hurt_player(int(spec["degats"]), at)
	var cb: Node = _m71().get("combat_v28")
	if cb != null:
		for k in range(12):
			var a: float = TAU * k / 12.0
			cb.puff(at + Vector3(cos(a) * radius * 0.7, 0.3, sin(a) * radius * 0.7), Color(0.55, 0.85, 0.45))
	_sfx71("onde_choc", at)
	_splat()


func _king_split_check() -> void:
	var pv: int = int(spec["pv"])
	if not ((_phase71 == 0 and hp < pv * 2 / 3) or (_phase71 == 1 and hp < pv / 3)):
		return
	_phase71 += 1
	var n: int = 3 + (randi() % 2)
	var kinds: Array = ["slime", "slime", "slime_bleu", "slime_rose"]
	for k in range(n):
		var a: float = TAU * k / n + randf() * 0.4
		var d := Vector3(cos(a), 0, sin(a))
		var at: Vector3 = global_position + d * (hit_radius + 1.2) + Vector3.UP * 0.3
		var m: Node3D = manager.spawn_extra(str(kinds[randi() % kinds.size()]), at)
		m.home = at
		m.set("_knock", d * 4.0)
	_size_k *= 0.84
	hit_radius *= 0.86
	if _cs71 != null:
		_cs71.scale = Vector3.ONE * _size_k
		_cs71.position.y = 1.6 * _size_k
	_sfx71("slime_divise", global_position + Vector3.UP * 2.0)
	_hint70("Le Roi Gélatineux tremble de toute sa gelée… et se divise ! Des petits slimes s'en détachent !")
	_splat()


func _boss_tick(delta: float, dist: float) -> void:
	if not SPECS71.has(kind):
		super._boss_tick(delta, dist)
		return
	_special_t += delta
	match kind:
		"slime_roi":
			if _special_t > 5.5 and dist < 12.0 and dist > 2.0:
				_special_t = 0.0
				state = "saut_roi"
				timer = 1.35
				_jump_from = global_position
				var to: Vector3 = _player()
				if manager.main.xr_active:
					to.y -= 1.5
				var dd: Vector3 = Vector3(to.x - global_position.x, 0, to.z - global_position.z)
				_jump_to = global_position + dd.normalized() * minf(dd.length() - 0.5, 7.0)
				_sfx71("slime_roi_cri", global_position + Vector3.UP * 2.0)
		"grenouille_geante", "grenouille_reine":
			var reach: float = float(spec.get("langue", 6.0))
			if _special_t > 4.5 and dist > float(spec["portee"]) + 0.3 and dist < reach:
				_special_t = 0.0
				state = "langue"
				timer = 0.8
				_tongue_hit = false
				_sfx71("grenouille_langue", global_position + Vector3.UP)
		"gobelin_chef":
			var pv: int = int(spec["pv"])
			if _phase71 == 0 and hp < pv / 2:
				_phase71 = 1
				for k in range(2):
					var a: float = TAU * k / 2.0 + randf()
					var m: Node3D = manager.spawn_extra("gobelin", global_position + Vector3(cos(a) * 4.0, 0.2, sin(a) * 4.0))
					m.home = m.global_position
				_sfx71("gobelin_chef_cri", global_position + Vector3.UP * 1.6)
				_hint70("Le chef gobelin agite sa bannière en hurlant : « À moi, la bande ! » Deux gobelins sortent des fourrés !")
			if _special_t > 7.0 and dist > 3.0 and dist < 9.0:
				_special_t = 0.0
				_knock = facing * 8.5
				_sfx71("gobelin_chef_cri", global_position + Vector3.UP * 1.6)
				_hint70("Le chef gobelin baisse sa hampe… et charge en beuglant !")


# --------------------------------------------------------------- le navet fuyard

func _navet_tick(delta: float) -> void:
	if not _common71(delta):
		return
	var p: Vector3 = _player()
	if manager.main.xr_active:
		p.y -= 1.5
	var to_p: Vector3 = p - global_position
	var dy: float = absf(to_p.y)
	to_p.y = 0.0
	var dist: float = to_p.length()
	var dir_p: Vector3 = to_p / dist if dist > 0.01 else facing
	var move := Vector3.ZERO
	timer -= delta
	match state:
		"cache":
			if dist < float(spec["vue"]) and dy < 3.0 and timer <= 0.0:
				state = "sursaut"
				timer = 0.4
				facing = dir_p
				_sfx71("navet_cri", global_position + Vector3.UP * 0.4)
				manager.alert(self)
		"sursaut":
			if timer <= 0.0:
				state = "fuite"
				timer = randf_range(5.0, 8.0)
				_flee_dir = -dir_p
		"fuite":
			var away: Vector3 = -dir_p
			var back := Vector3(home.x - global_position.x, 0, home.z - global_position.z)
			if back.length() > float(spec["laisse"]) * 0.6:
				away = (away + back.normalized() * 1.1).normalized()
			away = away.rotated(Vector3.UP, sin(_clock * 4.3) * 0.55)
			_flee_dir = _flee_dir.lerp(away, clampf(delta * 3.5, 0.0, 1.0)).normalized()
			var ahead: Vector3 = global_position + _flee_dir * 1.2
			var gy: float = _ground_y71(ahead, global_position.y)
			var wet: bool = global_position.y > -30.0 and SEA71 - gy > 0.15
			if gy < -1e8 or wet or gy - global_position.y > 0.9:
				_flee_dir = _flee_dir.rotated(Vector3.UP, PI * 0.6 * (1.0 if sin(_clock) > 0.0 else -1.0))
			elif is_on_wall():
				_flee_dir = _flee_dir.rotated(Vector3.UP, PI * 0.5)
			move = _flee_dir * float(spec["vitesse"]) * (1.15 if dist < 3.0 else 1.0)
			facing = _flee_dir
			_hop_snd -= delta
			if _hop_snd <= 0.0 and dist < 12.0:
				_hop_snd = randf_range(1.6, 3.0)
				_sfx71("navet_cri", global_position + Vector3.UP * 0.4, -4.0)
			if timer <= 0.0 or dist > 15.0:
				state = "terre"
				timer = 0.55
		"terre":
			if timer <= 0.0:
				state = "cache"
				timer = 1.8
	_move71(move, delta)


# =================================================================== animation

func _animate63(delta: float, speed: float) -> void:
	if not SPECS71.has(kind):
		super._animate63(delta, speed)
		return
	var moving: bool = speed > 0.2
	var crouch: float = 0.0
	if state == "armer":
		crouch = 1.0 - clampf(timer / float(spec["armer"]), 0.0, 1.0)
	match kind:
		"slime", "slime_bleu", "slime_rose", "slime_roi":
			_anim_slime(delta, crouch)
		"grenouille_geante", "grenouille_reine":
			_anim_frog(delta, crouch)
		"gobelin", "gobelin_chef":
			if _anim != null and not (state in ["armer", "frappe", "mort", "recul"]):
				if state == "tapi":
					_play("v28/sit", 0.3)
				elif state == "fuite" or (moving and speed > 2.6):
					_play("Running", 0.2, maxf(speed / (3.2 if kind == "gobelin" else 4.5), 0.7))
				elif moving:
					_play("Walking", 0.2, maxf(speed / (0.75 if kind == "gobelin" else 1.2), 0.6))
				else:
					_play("v28/idle", 0.3)
			if state == "tapi":
				# il tremble comme une feuille
				_visual.position.x = sin(_clock * 40.0) * 0.012
			else:
				_visual.position.x = 0.0
		"navet":
			_anim_navet(delta, speed)
		"mimique":
			_anim_mimic(delta, crouch)
	if _stars != null and _stars.visible:
		_stars.rotation.y += delta * 4.0


func _hop_curve() -> Array:
	# [hauteur 0..1, écrasement -1..1 (+ = écrasé, - = étiré)]
	if not HOPS.has(kind):
		return [0.0, 0.0]
	var gf: float = float(HOPS[kind][1])
	if _hop_p <= 0.0:
		return [0.0, 0.0]
	if _hop_p < gf:
		var k: float = _hop_p / gf
		return [0.0, sin(k * PI) * 0.9]
	var k2: float = (_hop_p - gf) / (1.0 - gf)
	return [sin(k2 * PI), -0.55 * (1.0 - k2 * 2.0) * (1.0 if k2 < 0.5 else 0.6)]


func _anim_slime(delta: float, crouch: float) -> void:
	if _gel == null:
		return
	var hc: Array = _hop_curve()
	var h: float = float(hc[0]) * float(HOPS[kind][2])
	var sq: float = float(hc[1])
	if state == "armer":
		sq = crouch * 0.8
		h = 0.0
	elif state == "frappe":
		h = float(HOPS[kind][2]) * 1.6 * sin(clampf(1.0 - timer / 0.34, 0.0, 1.0) * PI)
		sq = -0.5
	elif state == "souffle" or state == "veille" and _hop_p <= 0.0:
		sq = sin(_clock * 3.0) * 0.06
	elif state == "recul":
		sq = 0.5
	# le dernier écrasement : on lisse
	var sy: float = clampf(1.0 - sq * 0.35, 0.55, 1.4)
	var sxz: float = 1.0 / sqrt(sy)
	var base_s: float = (1.0 if kind != "slime_roi" else 6.6) * _size_k
	_gel.scale = _gel.scale.lerp(Vector3(sxz, sy, sxz) * base_s, clampf(delta * 18.0, 0.0, 1.0))
	if state != "saut_roi":
		_visual.position.y = lerpf(_visual.position.y, h * (_size_k if kind == "slime_roi" else 1.0), clampf(delta * 20.0, 0.0, 1.0))
	else:
		var t: float = 1.35 - timer
		var sy2: float = 1.0
		if t < 0.3:
			sy2 = 1.0 - 0.35 * sin(t / 0.3 * PI * 0.5)
		elif t < 1.1:
			sy2 = 1.18
		else:
			sy2 = 1.0 - 0.4 * sin(clampf((t - 1.1) / 0.25, 0.0, 1.0) * PI)
		var sxz2: float = 1.0 / sqrt(sy2)
		_gel.scale = Vector3(sxz2, sy2, sxz2) * 6.6 * _size_k
	_gel.rotation.z = sin(_clock * 2.3) * 0.03


func _anim_frog(delta: float, crouch: float) -> void:
	if _frog == null:
		return
	var s: float = float(FROG_S[kind])
	var hc: Array = _hop_curve()
	var h: float = float(hc[0]) * float(HOPS[kind][2])
	var ext: float = 0.0
	if _hop_air:
		ext = float(hc[0])
		var gf: float = float(HOPS[kind][1])
		var k2: float = (_hop_p - gf) / (1.0 - gf)
		ext = clampf(1.0 - k2 * 1.6, 0.0, 1.0)
	var pitch: float = 0.0
	if state == "armer":
		pitch = crouch * 0.15
		h = 0.0
	elif state == "frappe":
		var k3: float = clampf(1.0 - timer / 0.34, 0.0, 1.0)
		h = float(HOPS[kind][2]) * 1.4 * sin(k3 * PI)
		ext = 1.0 - k3
		pitch = -0.3 * (1.0 - k3)
	elif state == "avale":
		# la bedaine pleine : elle gonfle, ondule… elle a l'air très contente d'elle
		var w: float = sin(_clock * 9.0) * 0.06
		_frog.scale = _frog.scale.lerp(Vector3(1.18 + w, 1.12 - w, 1.08) * s, clampf(delta * 8.0, 0.0, 1.0))
	if state != "avale":
		_frog.scale = _frog.scale.lerp(Vector3.ONE * s, clampf(delta * 6.0, 0.0, 1.0))
	if _hop_air:
		pitch = -0.25 * (1.0 - float(hc[0])) + 0.1
	_visual.position.y = lerpf(_visual.position.y, h, clampf(delta * 20.0, 0.0, 1.0))
	_frog.rotation.x = lerpf(_frog.rotation.x, pitch, clampf(delta * 10.0, 0.0, 1.0))
	for hl in _hind:
		var hip: Node3D = hl[0]
		var knee: Node3D = hl[1]
		var ank: Node3D = hl[2]
		hip.rotation.x = lerpf(hip.rotation.x, ext * 1.25 + crouch * -0.15, clampf(delta * 18.0, 0.0, 1.0))
		knee.rotation.x = lerpf(knee.rotation.x, ext * -1.5, clampf(delta * 18.0, 0.0, 1.0))
		ank.rotation.x = lerpf(ank.rotation.x, ext * 1.1, clampf(delta * 18.0, 0.0, 1.0))
	for fl in _legs:
		(fl[0] as Node3D).rotation.x = lerpf((fl[0] as Node3D).rotation.x, (-0.5 if _hop_air else 0.0), clampf(delta * 10.0, 0.0, 1.0))
	# coasser : le sac vocal gonfle comme un ballon
	_croak_t -= delta
	if _croak_t <= 0.0 and state in ["veille", "chasse", "souffle"]:
		_croak_t = randf_range(4.5, 9.0)
		_croak = 1.0
		if _near_player(30.0):
			_sfx71("grenouille_coasse", global_position + Vector3.UP * 0.6 * s)
	var sac: float = 0.0
	if _croak > 0.0:
		_croak = maxf(_croak - delta * 0.9, 0.0)
		sac = sin((1.0 - _croak) * PI)
	if _sac != null:
		var sz: float = 0.4 + 1.5 * sac
		_sac.scale = _sac.scale.lerp(Vector3(sz, sz * 0.95, sz), clampf(delta * 14.0, 0.0, 1.0))
	if _fjaw != null:
		var open: float = 0.0
		if state == "armer":
			open = crouch * 0.35
		elif state == "frappe" or state == "langue":
			open = 0.42
		elif state == "avale":
			open = 0.0
		_fjaw.rotation.x = lerpf(_fjaw.rotation.x, open, clampf(delta * 14.0, 0.0, 1.0))


func _anim_navet(delta: float, speed: float) -> void:
	if _nav == null:
		return
	var target_y: float = 0.135
	match state:
		"cache":
			target_y = -0.17
		"sursaut":
			target_y = 0.135 + 0.2 * sin(clampf(1.0 - timer / 0.4, 0.0, 1.0) * PI)
		"terre":
			target_y = lerpf(-0.17, 0.135, clampf(timer / 0.55, 0.0, 1.0))
	var bounce: float = absf(sin(_clock * 14.0)) * 0.05 if speed > 0.3 else 0.0
	_nav.position.y = lerpf(_nav.position.y, target_y + bounce, clampf(delta * 14.0, 0.0, 1.0))
	_nav.rotation.z = sin(_clock * 14.0) * 0.12 if speed > 0.3 else (sin(_clock * 30.0) * 0.06 if state == "terre" else 0.0)
	_nav.rotation.x = 0.2 if speed > 0.3 else 0.0
	var run: bool = speed > 0.3
	for l in _nav_legs:
		(l[0] as Node3D).rotation.x = sin(_clock * 18.0 + (0.0 if float(l[1]) > 0.0 else PI)) * 0.9 if run else 0.0
	for a in _nav_arms:
		(a[0] as Node3D).rotation.z = (float(a[1]) * (0.9 + sin(_clock * 20.0) * 0.4)) if run or state == "sursaut" else float(a[1]) * 0.2
	for lf in _nav_leaves:
		var lp: Node3D = lf[0]
		lp.rotation.x = (sin(_clock * 16.0 + float(lf[1])) * 0.25 - 0.35) if run else sin(_clock * 1.3 + float(lf[1])) * 0.05
	if _nav_mouth != null:
		var o: float = 2.2 if (run or state == "sursaut") else 1.0
		_nav_mouth.scale = _nav_mouth.scale.lerp(Vector3(o * 0.7, o * 1.6 if o > 1.0 else 1.0, 1.0), clampf(delta * 10.0, 0.0, 1.0))


func _anim_mimic(delta: float, crouch: float) -> void:
	if _lid == null:
		return
	var open: float = 0.0
	var h: float = 0.0
	match state:
		"dort":
			# un petit frisson du couvercle, de temps en temps (les plus attentifs le remarqueront)
			if _twitch <= 0.0:
				_twitch = randf_range(6.0, 11.0)
			open = 0.05 * sin(_twitch * 25.0) if _twitch < 0.25 else 0.0
		"reveil":
			open = 0.35 + 0.08 * sin(_clock * 30.0)
		"armer":
			open = 0.25 + crouch * 0.85
		"frappe":
			open = 0.05
		"mort":
			open = 1.2
		_:
			var hc: Array = _hop_curve()
			h = float(hc[0]) * float(HOPS[kind][2])
			open = 0.15 + 0.45 * float(hc[0]) + 0.05 * sin(_clock * 8.0)
	if state == "frappe":
		h = 0.35 * sin(clampf(1.0 - timer / 0.34, 0.0, 1.0) * PI)
	_lid.rotation.x = lerpf(_lid.rotation.x, -open, clampf(delta * (25.0 if state == "frappe" else 12.0), 0.0, 1.0))
	_visual.position.y = lerpf(_visual.position.y, h, clampf(delta * 20.0, 0.0, 1.0))
	if _mim_tongue != null and _mim_tongue.visible:
		_mim_tongue.rotation.x = sin(_clock * 5.0) * 0.12 + (0.3 if state == "mort" else 0.0)
		_mim_tongue.rotation.y = sin(_clock * 3.1) * 0.15


func _death_tick(delta: float) -> void:
	if not SPECS71.has(kind):
		super._death_tick(delta)
		return
	timer += delta
	var end_t: float = 2.6
	match kind:
		"slime", "slime_bleu", "slime_rose", "slime_roi":
			var bs: float = (1.0 if kind != "slime_roi" else 6.6) * _size_k
			var k: float = clampf(timer / (0.25 if kind != "slime_roi" else 1.4), 0.0, 1.0)
			if _gel != null:
				_gel.scale = Vector3(1.0 + 0.8 * k, 1.0 - 0.88 * k, 1.0 + 0.8 * k) * bs
			_visual.position.y = lerpf(_visual.position.y, 0.0, clampf(delta * 10.0, 0.0, 1.0))
			end_t = 1.6 if kind != "slime_roi" else 3.2
		"grenouille_geante", "grenouille_reine":
			# sur le dos, les pattes en l'air
			_visual.rotation.z = lerpf(_visual.rotation.z, PI, clampf(delta * 5.0, 0.0, 1.0))
			_visual.position.y = sin(clampf(timer * 2.0, 0.0, 1.0) * PI) * 0.4 + clampf(timer * 2.0, 0.0, 1.0) * 0.55 * float(FROG_S[kind])
			for hl in _hind:
				(hl[0] as Node3D).rotation.x = 0.4 + sin(timer * 14.0) * 0.3 * maxf(1.0 - timer, 0.0)
		"navet":
			var k2: float = clampf(timer / 0.35, 0.0, 1.0)
			_visual.scale = Vector3.ONE * (1.0 + sin(k2 * PI) * 0.5) * (1.0 - k2 * 0.95)
			end_t = 0.4
		"mimique":
			_anim_mimic(delta, 0.0)
			_visual.rotation.z = minf(timer * 0.8, 0.25)
	if timer > end_t - 0.7 and kind != "navet":
		_visual.scale = Vector3.ONE * clampf(1.0 - (timer - (end_t - 0.7)) / 0.7, 0.01, 1.0)
	if timer > end_t:
		visible = false
		set_physics_process(false)


func _puff_color() -> Color:
	match kind:
		"slime", "slime_bleu", "slime_rose", "slime_roi":
			return GELEE[kind]
		"grenouille_geante", "grenouille_reine":
			return Color(0.55, 0.7, 0.35)
		"gobelin", "gobelin_chef":
			return Color(0.6, 0.65, 0.4)
		"navet":
			return Color(0.55, 0.42, 0.28)
		"mimique":
			return Color(0.65, 0.5, 0.32)
	return super._puff_color()


## Le butin (monstres_v36._on_died) ; « butin_extra » (méta) s'y ajoute.
func loot(rng: RandomNumberGenerator) -> Array:
	var g: Array = []
	match kind:
		"slime":
			g = [["piece", rng.randi_range(0, 2)]]
			if rng.randf() < 0.7:
				g.append(["gelee_slime", 1])
		"slime_bleu":
			g = [["piece", rng.randi_range(1, 3)], ["gelee_slime", 1]]
		"slime_rose":
			g = [["piece", rng.randi_range(2, 4)], ["gelee_slime", rng.randi_range(1, 2)]]
		"slime_roi":
			g = [["piece", rng.randi_range(50, 70)], ["piece_or", 2], ["gelee_slime", 3]]
		"grenouille_geante":
			g = [["piece", rng.randi_range(1, 3)]]
			if rng.randf() < 0.6:
				g.append(["cuisse_grenouille", 1])
		"grenouille_reine":
			g = [["piece", rng.randi_range(15, 25)], ["cuisse_grenouille", 2]]
		"gobelin":
			g = [["piece", rng.randi_range(1, 4)]]
			if rng.randf() < 0.4:
				g.append(["croc_gobelin", 1])
		"gobelin_chef":
			g = [["piece", rng.randi_range(20, 30)], ["croc_gobelin", 2], ["banniere_gobelin", 1]]
		"navet":
			g = [["navet_dore", 1]]
		"mimique":
			g = [["piece", rng.randi_range(10, 20)]]
			if rng.randf() < 0.3:
				g.append(["piece_or", 1])
		_:
			return super.loot(rng)
	for e in get_meta("butin_extra", []):
		g.append(e)
	return g


func alert_text() -> String:
	match kind:
		"slime", "slime_bleu", "slime_rose":
			return "Un slime ! Une petite gelée qui rebondit. Quand il s'écrase tout plat, il va te sauter dessus : écarte-toi, puis frappe. Les bleus et les roses sont plus coriaces."
		"slime_roi":
			return "LE ROI GÉLATINEUX ! Quatre mètres de gelée… et une couronne minuscule. Quand il bondit, éloigne-toi : il retombe de tout son poids. Et méfie-toi, il se divise !"
		"grenouille_geante":
			return "Une grenouille géante ! Elle bondit, fouette de la langue… et elle avale tout rond ce qui passe. Garde tes distances, pare (F) ses bonds, et frappe-la quand elle se pose."
		"grenouille_reine":
			return "LA GRENOUILLE REINE, la plus grosse du lac ! Sa langue porte très loin, et elle a un sacré appétit. Ne reste pas devant sa bouche !"
		"gobelin":
			return "Des gobelins ! Petits, rapides, une lance de silex. Quand il recule sa lance, pare (F) ou roule (Ctrl). Rassure-toi : à la première égratignure, il détale."
		"gobelin_chef":
			return "LE CHEF GOBELIN ! Un casque d'os, et sa bannière en guise de gourdin. Il charge en beuglant, et il appelle sa bande. Écarte-toi de ses charges, frappe-le ensuite."
		"navet":
			return "Un navet fuyard ! Il ne mord pas… il court. Rattrape-le en courant (Maj) et donne-lui une petite tape : il est à toi."
		"mimique":
			return "Ce coffre a des dents ! UNE MIMIQUE ! Quand le couvercle s'ouvre tout grand, elle va bondir : écarte-toi, puis frappe-la."
	return super.alert_text()
