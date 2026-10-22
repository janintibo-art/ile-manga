extends Node3D
## V63 : la géométrie du donjon du Cœur-de-Pierre (coeur_v63.gd en a les règles).
## Repère : O, sous le centre du massif, à 120 m sous la mer ; X vers l'est, Z vers le sud.
##  - le Vestibule des Quatre Peuples (on y arrive de la grande porte), en balcon à l'ouest ;
##  - la Rose des Sceaux : la grande salle centrale ; quatre portes, un sceau rond au sol ;
##  - quatre ailes, une par peuple, chacune : un couloir, une salle d'énigme (A), une galerie
##    de pièges (B), l'arène de son gardien (C) avec son cristal et son cercle de retour :
##      · l'Aile des Marées (ouest, plus bas) : les écluses, les vagues, le Garde-Marée ;
##      · l'Aile des Sables (sud) : les braseros du soleil, les lames, le Scorpion-Roi ;
##      · l'Aile des Rouages (nord) : les plates-formes, les pistons, le Colosse à vapeur ;
##      · l'Aile de la Lune (est) : les ponts invisibles, les ombres, le Grand Loup des Brumes ;
##  - la Salle du Cœur, sous la Rose des Sceaux : le cristal géant, le Gardien du Cœur.
## Dans le repère d'une aile, +Z s'éloigne de la Rose des Sceaux, l'origine est au pied de sa
## porte ; u (Z) = distance à la porte, v (X) = de côté.

const Kit = preload("res://scripts/coeur_kit_v63.gd")
const O := Vector3(940.0, -120.0, -150.0)
const HUB: float = 18.0
const HEART_Y: float = -24.0
const HEART_R: float = 22.0
const WING_DEF := {
	"marees": {"yaw": -PI * 0.5, "L": 16.0, "wy": -8.0, "mur": "corail", "sol": "corail", "voute": "granit_sombre", "deco": "argent_c", "couleur": Color(0.35, 0.95, 0.9), "nom": "l'Aile des Marées"},
	"sables": {"yaw": 0.0, "L": 8.0, "wy": 0.0, "mur": "gres", "sol": "dalles_c", "voute": "gres_sombre", "deco": "or_c", "couleur": Color(1.0, 0.6, 0.2), "nom": "l'Aile des Sables"},
	"rouages": {"yaw": PI, "L": 8.0, "wy": 0.0, "mur": "laiton_c", "sol": "fonte_c", "voute": "fonte_c", "deco": "cuivre_c", "couleur": Color(1.0, 0.8, 0.35), "nom": "l'Aile des Rouages"},
	"lune": {"yaw": PI * 0.5, "L": 8.0, "wy": 0.0, "mur": "ardoise_c", "sol": "ardoise_c", "voute": "granit_sombre", "deco": "argent_c", "couleur": Color(0.72, 0.82, 1.0), "nom": "l'Aile de la Lune"},
}
const WING_ORDER := ["marees", "sables", "rouages", "lune"]

var main: Node
var kit
var pc: bool = true
var points: Dictionary = {}                  # repères (monde)
var wings: Dictionary = {}                   # nom -> {xf, L, wy, root, …}
var hub_root: Node3D
var vest_root: Node3D
var heart_root: Node3D
var hub_crystals: Dictionary = {}            # aile -> {node, mat, light}
var hub_seal: Node3D
var hub_heart_light: OmniLight3D
var heart_crystal: Node3D
var heart_light: OmniLight3D
var heart_mat: StandardMaterial3D
var gates: Dictionary = {}                   # id -> Node3D (portes et herses mobiles)
var water_shader: Shader


# =================================================================== repères

func wxf(name: String) -> Transform3D:
	return wings[name]["xf"]


## Un point du repère d'une aile, en monde.
func W(name: String, local: Vector3) -> Vector3:
	return (wings[name]["xf"] as Transform3D) * local


func H(local: Vector3) -> Vector3:
	return O + local


## Une pointe de cristal (pyramide à six pans), centrée comme un PrismMesh.
static func crystal_mesh(w: float, h: float) -> CylinderMesh:
	var cm := CylinderMesh.new()
	cm.top_radius = 0.0
	cm.bottom_radius = w * 0.5
	cm.height = h
	cm.radial_segments = 6
	cm.rings = 1
	return cm


# =================================================================== construction

func build(main_node: Node, high_quality: bool) -> void:
	main = main_node
	pc = high_quality
	kit = Kit.new()
	kit.setup63(self, main, pc)
	kit.body.set_meta("lisse", true)
	for n in WING_ORDER:
		var d: Dictionary = WING_DEF[n]
		var b := Basis(Vector3.UP, float(d["yaw"]))
		var out: Vector3 = b * Vector3(0, 0, 1)
		wings[n] = {"xf": Transform3D(b, O + out * HUB), "L": float(d["L"]), "wy": float(d["wy"])}
	_water_shader()
	_build_vestibule()
	_build_hub()
	for n2 in WING_ORDER:
		_wing_shell(n2)
	_build_marees()
	_build_sables()
	_build_rouages()
	_build_lune()
	_build_heart()


func _root(label: String) -> Node3D:
	var n := Node3D.new()
	n.name = label
	add_child(n)
	kit.root = n
	return n


func _water_shader() -> void:
	water_shader = Shader.new()
	water_shader.code = """shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_opaque;
uniform vec4 teinte : source_color = vec4(0.04, 0.2, 0.24, 0.86);
uniform float vagues = 1.0;
float h2(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float n2(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h2(i), h2(i + vec2(1, 0)), f.x), mix(h2(i + vec2(0, 1)), h2(i + vec2(1, 1)), f.x), f.y); }
varying vec3 wp;
void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	VERTEX.y += (sin(wp.x * 0.7 + TIME * 1.3) + sin(wp.z * 0.9 - TIME * 1.1)) * 0.03 * vagues;
}
void fragment() {
	vec2 uv = wp.xz * 0.35;
	float a = n2(uv + vec2(TIME * 0.12, TIME * 0.07));
	float b = n2(uv * 2.3 - vec2(TIME * 0.18, -TIME * 0.11));
	vec3 nrm = normalize(vec3((a - 0.5) * 0.6 + (b - 0.5) * 0.3, 1.0, (b - 0.5) * 0.6 - (a - 0.5) * 0.2));
	NORMAL = normalize((VIEW_MATRIX * vec4(nrm, 0.0)).xyz);
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 4.0);
	ALBEDO = mix(teinte.rgb, vec3(0.5, 0.75, 0.8), fres * 0.6);
	ROUGHNESS = 0.04;
	METALLIC = 0.1;
	SPECULAR = 0.8;
	ALPHA = clamp(teinte.a + fres * 0.2, 0.0, 1.0);
}
"""


## Un plan d'eau (monde : centre, taille).
func water_plane(parent: Node3D, center: Vector3, size: Vector2, tint: Color = Color(0.07, 0.29, 0.33, 0.82)) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = size
	pm.subdivide_width = int(size.x / 1.5)
	pm.subdivide_depth = int(size.y / 1.5)
	mi.mesh = pm
	var sm := ShaderMaterial.new()
	sm.shader = water_shader
	sm.set_shader_parameter("teinte", tint)
	mi.material_override = sm
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	mi.global_position = center
	return mi


## Un mur droit (repère xf) entre deux points de son axe, de y0 à y1.
func wall_seg(xf: Transform3D, along_x: bool, fixed: float, a: float, b: float, y0: float, y1: float, key: String, t: float = 0.8) -> void:
	if b - a < 0.01 or y1 - y0 < 0.01:
		return
	var mid: float = (a + b) * 0.5
	if along_x:
		kit.solid(xf * Transform3D(Basis(), Vector3(mid, (y0 + y1) * 0.5, fixed)), Vector3(b - a, y1 - y0, t), key, 3.0)
	else:
		kit.solid(xf * Transform3D(Basis(), Vector3(fixed, (y0 + y1) * 0.5, mid)), Vector3(t, y1 - y0, b - a), key, 3.0)


## Une herse ou une porte de pierre qui monte (repère xf : ouverture centrée, +Z le passage).
func gate(id: String, parent: Node3D, xf: Transform3D, w: float, h: float, key: String, bars: bool) -> Node3D:
	var g := Node3D.new()
	g.name = "Porte_" + id
	parent.add_child(g)
	g.global_transform = xf
	var body := StaticBody3D.new()
	body.set_meta("lisse", true)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(w, h, 0.4)
	cs.shape = bs
	cs.position = Vector3(0, h * 0.5, 0)
	body.add_child(cs)
	g.add_child(body)
	if bars:
		var m: Material = kit.mat("fonte_c")
		var n: int = int(w / 0.45)
		for i in range(n + 1):
			var bar := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.05
			cm.bottom_radius = 0.05
			cm.height = h
			cm.radial_segments = 6
			bar.mesh = cm
			bar.material_override = m
			bar.position = Vector3(-w * 0.5 + w * i / n, h * 0.5, 0)
			g.add_child(bar)
		for k in range(3):
			var cross := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(w, 0.12, 0.12)
			cross.mesh = bm
			cross.material_override = m
			cross.position = Vector3(0, h * (0.2 + 0.3 * k), 0)
			g.add_child(cross)
	else:
		var slab := MeshInstance3D.new()
		var sb := BoxMesh.new()
		sb.size = Vector3(w, h, 0.5)
		slab.mesh = sb
		slab.material_override = kit.mat(key)
		slab.position = Vector3(0, h * 0.5, 0)
		g.add_child(slab)
	g.set_meta("bas", g.position.y)
	gates[id] = g
	return g


# =================================================================== le Vestibule

func _build_vestibule() -> void:
	vest_root = _root("Vestibule_v63")
	var xf := Transform3D(Basis(), O)
	# la salle haute, au-dessus du couloir des Marées
	kit.room(xf, -36.0, -18.0, -5.0, 5.0, 5.0, 8.0, "granit", "dalles_c", [], "granit_sombre", 0.8, 3.0)
	# l'escalier qui remonte vers la grande porte (il se perd dans le noir)
	kit.ramp(xf, Vector3(-36.0, 5.0, 0), Vector3(-44.0, 11.0, 0), 4.0, "granit_sombre")
	kit.solid(xf * Transform3D(Basis(), Vector3(-45.0, 11.0, 0)), Vector3(1.0, 8.0, 5.0), "noir", 1.0)
	for s in [-1.0, 1.0]:
		kit.solid(xf * Transform3D(Basis(), Vector3(-40.0, 11.0, s * 2.4)), Vector3(9.0, 12.0, 0.8), "granit", 2.0)
	kit.solid(xf * Transform3D(Basis(), Vector3(-40.0, 17.4, 0)), Vector3(9.0, 0.8, 5.6), "granit_sombre", 2.0)
	# les quatre peuples : statues sur leurs socles
	var people := [["embruns", Vector3(-31.5, 5.0, -3.6)], ["sables", Vector3(-24.5, 5.0, -3.6)], ["airain", Vector3(-31.5, 5.0, 3.6)], ["brumes", Vector3(-24.5, 5.0, 3.6)]]
	for p in people:
		kit.solid(xf * Transform3D(Basis(), (p[1] as Vector3) + Vector3(0, 0.4, 0)), Vector3(1.6, 0.8, 1.2), "granit_sombre", 1.0)
	# la fresque des quatre peuples, au-dessus de l'entrée
	kit.quad(xf * Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3(-35.5, 9.6, 0)), 8.0, 3.6, "img_fresque_peuples")
	kit.commit()
	for p2 in people:
		_statue(vest_root, O + (p2[1] as Vector3) + Vector3(0, 0.8, 0), str(p2[0]), Vector3(0, 0, -signf((p2[1] as Vector3).z)))
	for z in [-4.3, 4.3]:
		kit.torch(vest_root, O + Vector3(-28.0, 8.4, z), Vector3(0, 0, -signf(z)), 1.3)
	kit.glow_light(vest_root, O + Vector3(-27.0, 11.0, 0), Color(0.75, 0.8, 0.9), 0.8, 14.0)
	points["arrivee"] = O + Vector3(-33.0, 5.1, 0)
	points["sortie"] = O + Vector3(-34.5, 5.0, 0)


## Une statue d'un des quatre peuples (la silhouette du héros, en pierre, un attribut).
func _statue(parent: Node3D, at: Vector3, who: String, face: Vector3) -> void:
	var packed: PackedScene = load("res://assets/models/characters/hero.glb")
	var model: Node3D = packed.instantiate()
	model.scale = Vector3.ONE * 1.25
	parent.add_child(model)
	model.global_position = at
	model.rotation.y = atan2(face.x, face.z)
	var stone := StandardMaterial3D.new()
	stone.albedo_texture = load("res://assets/textures/coeur/pierre.png") if ResourceLoader.exists("res://assets/textures/coeur/pierre.png") else null
	stone.albedo_color = Color(0.78, 0.76, 0.72)
	stone.roughness = 0.9
	stone.uv1_scale = Vector3(2, 2, 2)
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		var m: MeshInstance3D = mi
		for k in range(m.mesh.get_surface_count()):
			m.set_surface_override_material(k, stone)
	var anim: AnimationPlayer = model.find_child("AnimationPlayer", true, false)
	var found := model.find_children("*", "Skeleton3D", true, false)
	if anim != null and found.size() > 0:
		var lib = load("res://scripts/hero_v28.gd").new()
		lib.hero = model
		lib.anim = anim
		lib.skel = found[0]
		lib._build_animations()
		lib.free()
		anim.play("v28/idle")
		anim.seek(0.8, true)
		anim.pause()
	# l'attribut de chaque peuple, en bronze, devant le socle
	var tag := MeshInstance3D.new()
	var col: Color = WING_DEF[{"embruns": "marees", "sables": "sables", "airain": "rouages", "brumes": "lune"}[who]]["couleur"]
	var gm := StandardMaterial3D.new()
	gm.albedo_color = col
	gm.emission_enabled = true
	gm.emission = col
	gm.emission_energy_multiplier = 0.8
	gm.metallic = 0.6
	var cm := CylinderMesh.new()
	cm.top_radius = 0.28
	cm.bottom_radius = 0.28
	cm.height = 0.05
	tag.mesh = cm
	tag.material_override = gm
	parent.add_child(tag)
	tag.global_position = at + face * 0.62 + Vector3(0, -0.45, 0)
	tag.rotation.x = PI * 0.5
	tag.rotation.y = atan2(face.x, face.z)


# =================================================================== la Rose des Sceaux

func _build_hub() -> void:
	hub_root = _root("Rose_des_sceaux_v63")
	var xf := Transform3D(Basis(), O)
	var R: float = HUB
	var h: float = 14.0
	# sol, voûte
	kit.solid(xf * Transform3D(Basis(), Vector3(0, -0.3, 0)), Vector3(2 * R + 1.6, 0.6, 2 * R + 1.6), "dalles_c", 3.0, 4)
	kit.solid(xf * Transform3D(Basis(), Vector3(0, h + 0.4, 0)), Vector3(2 * R + 1.6, 0.8, 2 * R + 1.6), "granit_sombre", 3.0, 8)
	# murs nord, sud, est : une porte au milieu
	for side in ["n", "s", "e"]:
		var along_x: bool = side != "e"
		var fixed: float = -R - 0.4 if side == "n" else R + 0.4
		wall_seg(xf, along_x, fixed, -R - 0.8, -2.5, 0.0, h, "granit")
		wall_seg(xf, along_x, fixed, 2.5, R + 0.8, 0.0, h, "granit")
		wall_seg(xf, along_x, fixed, -2.5, 2.5, 5.0, h, "granit")
	# mur ouest : la porte des Marées en bas, le passage du balcon au-dessus
	wall_seg(xf, false, -R - 0.4, -R - 0.8, -3.0, 0.0, h, "granit")
	wall_seg(xf, false, -R - 0.4, 3.0, R + 0.8, 0.0, h, "granit")
	wall_seg(xf, false, -R - 0.4, -3.0, -2.5, 0.0, 5.0, "granit")
	wall_seg(xf, false, -R - 0.4, 2.5, 3.0, 0.0, 5.0, "granit")
	wall_seg(xf, false, -R - 0.4, -3.0, 3.0, 4.4, 5.0, "granit")
	wall_seg(xf, false, -R - 0.4, -3.0, 3.0, 10.0, h, "granit")
	# le balcon et ses deux escaliers, le long du mur ouest
	kit.solid(xf * Transform3D(Basis(), Vector3(-15.5, 4.7, 0)), Vector3(5.0, 0.6, 7.0), "dalles_c", 2.0)
	for s in [-1.0, 1.0]:
		kit.column(xf * Transform3D(Basis(), Vector3(-13.6, 0, s * 3.0)), 0.35, 4.4, "granit", "granit_sombre")
		kit.ramp(xf, Vector3(-16.4, 0.0, s * 13.0), Vector3(-16.4, 5.0, s * 3.5), 3.0, "dalles_c", "granit_sombre")
		kit.solid(xf * Transform3D(Basis(), Vector3(-14.2, 2.5, s * 8.25)), Vector3(0.4, 5.0, 9.5), "granit", 2.0)
	kit.box(xf * Transform3D(Basis(), Vector3(-13.15, 5.45, 0)), Vector3(0.3, 0.9, 7.0), "granit_sombre", 1.0)
	kit.box(xf * Transform3D(Basis(), Vector3(-13.15, 5.93, 0)), Vector3(0.42, 0.08, 7.1), "or_c", 1.0)
	kit.col_box(xf * Transform3D(Basis(), Vector3(-13.15, 5.6, 0)), Vector3(0.3, 1.2, 7.0))
	# quatre grandes colonnes
	for cx in [-11.0, 11.0]:
		for cz in [-11.0, 11.0]:
			kit.column(xf * Transform3D(Basis(), Vector3(cx, 0, cz)), 1.1, h, "granit", "granit_sombre")
	# les encadrements des portes des ailes, leurs emblèmes
	for n in WING_ORDER:
		var wt: Transform3D = wxf(n)
		kit.arch(wt * Transform3D(Basis(), Vector3(0, 0, -0.3)), 5.0, 4.2, 1.4, "granit_sombre", false)
		kit.cyl(wt * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 7.6, -0.75)), 0.9, 0.9, 0.12, "img_emblem_" + n, 24)
	kit.commit()
	# la rose au sol, le sceau du Cœur au centre
	var rose := MeshInstance3D.new()
	var rpm := PlaneMesh.new()
	rpm.size = Vector2(16.0, 16.0)
	rose.mesh = rpm
	var rmat := StandardMaterial3D.new()
	rmat.albedo_texture = load("res://assets/textures/coeur/rose_sceaux.png") if ResourceLoader.exists("res://assets/textures/coeur/rose_sceaux.png") else null
	rmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	rmat.alpha_scissor_threshold = 0.5
	rmat.roughness = 0.6
	rmat.metallic = 0.2
	rose.material_override = rmat
	hub_root.add_child(rose)
	rose.global_position = O + Vector3(0, 0.012, 0)
	rose.visible = rmat.albedo_texture != null
	hub_seal = Node3D.new()
	hub_seal.name = "Sceau_du_coeur"
	hub_root.add_child(hub_seal)
	hub_seal.global_position = O + Vector3(0, 0.0, 0)
	var disc := MeshInstance3D.new()
	var dm := CylinderMesh.new()
	dm.top_radius = 3.0
	dm.bottom_radius = 3.1
	dm.height = 0.3
	dm.radial_segments = 40
	disc.mesh = dm
	disc.material_override = kit.mat("granit_sombre")
	disc.position.y = 0.05
	hub_seal.add_child(disc)
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 2.75
	tm.outer_radius = 2.95
	tm.rings = 48
	ring.mesh = tm
	ring.material_override = kit.mat("or_c")
	ring.position.y = 0.2
	ring.scale = Vector3(1, 0.4, 1)
	hub_seal.add_child(ring)
	for i in range(WING_ORDER.size()):
		var n2: String = WING_ORDER[i]
		var dir: Vector3 = (wxf(n2).basis * Vector3(0, 0, 1))
		var c: Color = WING_DEF[n2]["couleur"]
		var cm := StandardMaterial3D.new()
		cm.albedo_color = c.darkened(0.75)
		cm.metallic = 0.3
		cm.roughness = 0.15
		cm.emission_enabled = true
		cm.emission = c
		cm.emission_energy_multiplier = 0.0
		var crystal := MeshInstance3D.new()
		crystal.mesh = crystal_mesh(0.45, 0.9)
		crystal.material_override = cm
		hub_seal.add_child(crystal)
		crystal.position = dir * 2.1 + Vector3(0, 0.65, 0)
		var cl := OmniLight3D.new()
		cl.light_color = c
		cl.light_energy = 0.0
		cl.omni_range = 6.0
		hub_seal.add_child(cl)
		cl.position = dir * 2.1 + Vector3(0, 1.2, 0)
		hub_crystals[n2] = {"node": crystal, "mat": cm, "light": cl}
	var sb := StaticBody3D.new()
	sb.set_meta("lisse", true)
	var cs := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 3.0
	cyl.height = 0.3
	cs.shape = cyl
	cs.position.y = 0.05
	sb.add_child(cs)
	hub_seal.add_child(sb)
	# le cœur du massif, qui bat sous la voûte : un cristal suspendu (deux pointes, des éclats)
	heart_mat = StandardMaterial3D.new()
	heart_mat.albedo_color = Color(0.62, 0.1, 0.06, 0.92)
	heart_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	heart_mat.roughness = 0.08
	heart_mat.metallic_specular = 1.0
	heart_mat.emission_enabled = true
	heart_mat.emission = Color(1.0, 0.2, 0.08)
	heart_mat.emission_energy_multiplier = 0.55
	var hang := Node3D.new()
	hang.name = "Coeur_suspendu"
	hub_root.add_child(hang)
	hang.global_position = O + Vector3(0, 10.5, 0)
	for k in range(5):
		var sc: float = 1.0 if k == 0 else 0.5
		var a: float = TAU * k / 4.0
		for up in [1.0, -1.0]:
			if k > 0 and up < 0.0:
				continue
			var pr := MeshInstance3D.new()
			pr.mesh = crystal_mesh(1.1 * sc, 1.6 * sc)
			pr.material_override = heart_mat
			pr.position = Vector3(0, 0.8 * up, 0) if k == 0 else Vector3(cos(a) * 0.55, 0.3, sin(a) * 0.55)
			pr.rotation = Vector3(0.0 if k == 0 else cos(a) * 0.45, a + 0.4, (0.0 if up > 0.0 else PI) if k == 0 else sin(a) * 0.45)
			hang.add_child(pr)
	for k in range(4):
		var a: float = TAU * k / 4.0 + PI * 0.25
		var chain := MeshInstance3D.new()
		var ccm := CylinderMesh.new()
		ccm.top_radius = 0.04
		ccm.bottom_radius = 0.04
		ccm.height = 4.6
		chain.mesh = ccm
		chain.material_override = kit.mat("fonte_c")
		hub_root.add_child(chain)
		chain.global_position = O + Vector3(cos(a) * 1.4, 12.4, sin(a) * 1.4)
		chain.rotation = Vector3(sin(a) * 0.3, 0, -cos(a) * 0.3)
	for cx2 in [-11.0, 11.0]:
		for cz2 in [-11.0, 11.0]:
			kit.glow_light(hub_root, O + Vector3(cx2 * 0.8, 9.0, cz2 * 0.8), Color(1.0, 0.82, 0.62), 1.1, 16.0)
	hub_heart_light = OmniLight3D.new()
	hub_heart_light.light_color = Color(1.0, 0.3, 0.15)
	hub_heart_light.light_energy = 1.2
	hub_heart_light.omni_range = 24.0
	hub_root.add_child(hub_heart_light)
	hub_heart_light.global_position = O + Vector3(0, 9.0, 0)
	# deux braseros par porte
	for n3 in WING_ORDER:
		var wt2: Transform3D = wxf(n3)
		for s2 in [-1.0, 1.0]:
			kit.brazier(hub_root, wt2 * Vector3(s2 * 4.6, 0, -1.6), true)
		points["hub_" + n3] = wt2 * Vector3(0, 0.1, -4.0)
	points["hub_centre"] = O + Vector3(0, 0.1, 5.0)


# =================================================================== la coque des ailes

func _wing_shell(n: String) -> void:
	var d: Dictionary = WING_DEF[n]
	var w: Dictionary = wings[n]
	var root := _root("Aile_" + n + "_v63")
	w["root"] = root
	var xf: Transform3D = w["xf"]
	var L: float = float(w["L"])
	var wy: float = float(w["wy"])
	var wall: String = d["mur"]
	var fl: String = d["sol"]
	var ce: String = d["voute"]
	# le couloir depuis la Rose des Sceaux (en pente pour les Marées)
	if wy < 0.0:
		for s in [-1.0, 1.0]:
			kit.solid(xf * Transform3D(Basis(), Vector3(s * 3.0, (wy + 4.4) * 0.5 - 0.0, L * 0.5)), Vector3(1.0, 4.4 - wy + 0.4, L), wall, 3.0)
		kit.solid(xf * Transform3D(Basis(), Vector3(0, 4.4 + 0.3, L * 0.5)), Vector3(7.0, 0.6, L), ce, 3.0, 8)
		kit.solid(xf * Transform3D(Basis(), Vector3(0, 2.7, L - 0.4)), Vector3(7.0, 3.4, 0.8), wall, 3.0)
		kit.solid(xf * Transform3D(Basis(), Vector3(0, -0.3, 1.0)), Vector3(5.0, 0.6, 2.0), fl, 2.0)
		kit.ramp(xf, Vector3(0, wy, L - 1.0), Vector3(0, 0.0, 2.0), 5.0, fl)
		kit.solid(xf * Transform3D(Basis(), Vector3(0, wy - 0.3, L - 0.5)), Vector3(5.0, 0.6, 1.0), fl, 2.0)
	else:
		kit.room(xf, -2.5, 2.5, 0.0, L, 0.0, 4.6, wall, fl, [["n", 0.0, 5.0, 4.6], ["s", 0.0, 5.0, 4.6]], ce, 0.8, 2.5)
	# la salle A (les Marées et les Rouages ont un gouffre : leur sol est plus bas)
	var pit: float = {"marees": 5.0, "rouages": 10.0, "lune": 12.0}.get(n, 0.0)
	var ha: float = 9.0 + pit
	kit.room(xf, -13.0, 13.0, L, L + 30.0, wy - pit, ha, wall, fl, [["n", 0.0, 5.0, 4.6 + pit], ["s", 0.0, 4.0, 4.4 + pit]], ce, 0.8, 3.0)
	if pit > 0.0:
		# les deux rebords (entrée et sortie), pleins jusqu'au fond du gouffre
		kit.solid(xf * Transform3D(Basis(), Vector3(0, wy - pit * 0.5, L + 2.0)), Vector3(26.0, pit, 4.0), fl, 3.0)
		kit.solid(xf * Transform3D(Basis(), Vector3(0, wy - pit * 0.5, L + 28.0)), Vector3(26.0, pit, 4.0), fl, 3.0)
	# couloir A → B (la porte de l'énigme), salle B, couloir B → C, l'arène C
	kit.room(xf, -2.0, 2.0, L + 30.0, L + 36.0, wy, 4.4, wall, fl, [["n", 0.0, 4.0, 4.4], ["s", 0.0, 4.0, 4.4]], ce, 0.8, 2.5)
	if n != "marees":
		kit.room(xf, -5.0, 5.0, L + 36.0, L + 74.0, wy, 7.0, wall, fl, [["n", 0.0, 4.0, 4.4], ["s", 0.0, 4.0, 4.4]], ce, 0.8, 3.0)
	kit.room(xf, -2.0, 2.0, L + 74.0, L + 78.0, wy, 4.4, wall, fl, [["n", 0.0, 4.0, 4.4], ["s", 0.0, 4.0, 4.4]], ce, 0.8, 2.5)
	kit.room(xf, -13.0, 13.0, L + 78.0, L + 104.0, wy, 11.0, wall, fl, [["n", 0.0, 4.0, 4.4]], ce, 0.8, 3.5)
	# des colonnes dans l'arène
	for cx in [-8.5, 8.5]:
		for cz in [L + 84.0, L + 98.0]:
			kit.column(xf * Transform3D(Basis(), Vector3(cx, wy, cz)), 0.8, 11.0, wall, ce)
	# l'estrade du cristal, au fond de l'arène ; le cercle de retour
	kit.solid(xf * Transform3D(Basis(), Vector3(0, wy + 0.2, L + 100.5)), Vector3(5.0, 0.4, 3.0), d["deco"], 1.0)
	kit.commit()
	# les portes : A → B (énigme), C (le gardien, derrière soi)
	gate(n + "_a", root, xf * Transform3D(Basis(), Vector3(0, wy, L + 30.6)), 4.0, 4.4, wall, n == "rouages")
	gate(n + "_c", root, xf * Transform3D(Basis(), Vector3(0, wy, L + 77.6)), 4.0, 4.4, wall, true)
	(gates[n + "_c"] as Node3D).position.y += 4.6
	# les torches du couloir et de l'arène
	for z in [L * 0.5]:
		var ty: float = wy + 2.6 if wy >= 0.0 else -1.6
		for s2 in [-1.0, 1.0]:
			kit.torch(root, xf * Vector3(s2 * (2.35 if wy >= 0.0 else 2.85), ty, z), xf.basis * Vector3(-s2, 0, 0), 1.2)
	for z2 in [L + 84.0, L + 98.0]:
		for s3 in [-1.0, 1.0]:
			kit.torch(root, xf * Vector3(s3 * 12.55, wy + 3.0, z2), xf.basis * Vector3(-s3, 0, 0), 1.6)
	kit.glow_light(root, xf * Vector3(0, wy + 9.0, L + 91.0), d["couleur"], 1.0, 22.0, true)
	# un peu de lumière d'appoint (sans ombres) : on doit lire les salles, même sans éclairage global
	var fill: Color = (d["couleur"] as Color).lerp(Color(1.0, 0.9, 0.8), 0.55)
	for zf in [L + 5.0, L + 15.0, L + 25.0]:
		kit.glow_light(root, xf * Vector3(0, wy + 7.0, zf), fill, 1.7, 18.0)
	for zf2 in [L + 45.0, L + 64.0]:
		kit.glow_light(root, xf * Vector3(0, wy + 5.5, zf2), fill, 0.9, 12.0)
	for zf3 in [L + 84.0, L + 98.0]:
		kit.glow_light(root, xf * Vector3(0, wy + 8.0, zf3), fill, 1.8, 18.0)
	# repères
	var pts: Dictionary = {}
	pts["entree_a"] = xf * Vector3(0, wy + 0.1, L + 2.0)
	pts["entree_b"] = xf * Vector3(0, wy + 0.1, L + 37.5)
	pts["entree_c"] = xf * Vector3(0, wy + 0.1, L + 80.0)
	pts["boss"] = xf * Vector3(0, wy + 0.1, L + 92.0)
	pts["cristal"] = xf * Vector3(0, wy + 0.4, L + 100.5)
	pts["retour"] = xf * Vector3(4.5, wy + 0.1, L + 100.5)
	w["pts"] = pts
	w["pit"] = pit


## Le cristal de l'aile (il monte de l'estrade quand le gardien est tombé).
func wing_crystal(n: String) -> Dictionary:
	var w: Dictionary = wings[n]
	var c: Color = WING_DEF[n]["couleur"]
	var node := Node3D.new()
	node.name = "Cristal_" + n
	(w["root"] as Node3D).add_child(node)
	node.global_position = (w["pts"]["cristal"] as Vector3)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(c.r, c.g, c.b, 0.8)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.05
	m.metallic_specular = 1.0
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = 1.5
	for k in range(5):
		var p := MeshInstance3D.new()
		var s: float = 1.0 if k == 0 else 0.55
		p.mesh = crystal_mesh(0.6 * s, 1.8 * s)
		p.material_override = m
		var a: float = TAU * k / 4.0
		p.position = Vector3(0, 0.9, 0) if k == 0 else Vector3(cos(a) * 0.45, 0.5, sin(a) * 0.45)
		p.rotation = Vector3(0, a, 0.0 if k == 0 else 0.35)
		node.add_child(p)
	var l := OmniLight3D.new()
	l.light_color = c
	l.light_energy = 2.0
	l.omni_range = 9.0
	l.position = Vector3(0, 1.2, 0)
	node.add_child(l)
	return {"node": node, "mat": m}


## Le cercle de retour (vers la Rose des Sceaux).
func return_circle(parent: Node3D, at: Vector3, c: Color) -> Node3D:
	var n := Node3D.new()
	n.name = "Cercle_retour"
	parent.add_child(n)
	n.global_position = at
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 1.0
	tm.outer_radius = 1.15
	tm.rings = 40
	ring.mesh = tm
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	ring.material_override = m
	ring.scale = Vector3(1, 0.2, 1)
	ring.position.y = 0.05
	n.add_child(ring)
	var motes := CPUParticles3D.new()
	motes.amount = 24
	motes.lifetime = 1.6
	motes.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	motes.emission_ring_axis = Vector3.UP
	motes.emission_ring_radius = 1.05
	motes.emission_ring_inner_radius = 0.9
	motes.emission_ring_height = 0.05
	motes.direction = Vector3.UP
	motes.spread = 5.0
	motes.gravity = Vector3(0, 0.8, 0)
	motes.initial_velocity_min = 0.3
	motes.initial_velocity_max = 0.8
	var q := QuadMesh.new()
	q.size = Vector2(0.06, 0.06)
	var qm := StandardMaterial3D.new()
	qm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	qm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	qm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	qm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	qm.albedo_color = Color(c.r, c.g, c.b, 0.9)
	q.material = qm
	motes.mesh = q
	n.add_child(motes)
	var l := OmniLight3D.new()
	l.light_color = c
	l.light_energy = 1.0
	l.omni_range = 4.0
	l.position = Vector3(0, 0.6, 0)
	n.add_child(l)
	return n


# =================================================================== l'Aile des Marées (ouest)

func _build_marees() -> void:
	var n: String = "marees"
	var w: Dictionary = wings[n]
	var xf: Transform3D = w["xf"]
	var L: float = w["L"]
	var wy: float = w["wy"]
	var root: Node3D = w["root"]
	kit.root = root
	# --- A : les écluses. Un bassin de 5 m, quatre radeaux, un pilier au trésor, une roue
	# des marées sur le rebord d'entrée, un moulin et son pont-levis au-dessus du rebord du fond.
	kit.solid(xf * Transform3D(Basis(), Vector3(9.0, wy - 3.5, L + 8.0)), Vector3(3.0, 3.0, 3.0), "corail", 1.5)
	kit.solid(xf * Transform3D(Basis(), Vector3(9.0, wy - 1.9, L + 8.0)), Vector3(3.2, 0.2, 3.2), "dalles_c", 1.5)
	kit.solid(xf * Transform3D(Basis(), Vector3(9.0, wy - 1.75, L + 8.6)), Vector3(1.2, 0.5, 0.7), "bois_c", 1.0)
	# la roue des marées (un grand volant de bronze sur un socle)
	kit.solid(xf * Transform3D(Basis(), Vector3(-9.5, wy + 0.55, L + 2.0)), Vector3(1.2, 1.1, 1.0), "granit_sombre", 1.0)
	# des piliers de corail qui sortent du bassin (décor)
	for p in [Vector3(-10.5, 0, L + 14.0), Vector3(10.5, 0, L + 20.0), Vector3(-10.5, 0, L + 24.0)]:
		kit.cyl(xf * Transform3D(Basis(), p + Vector3(0, wy - 5.0, 0)), 0.8, 0.6, 8.0, "corail", 10, true, 2.0)
	kit.commit()
	w["roue_marees"] = xf * Vector3(-9.5, wy + 1.2, L + 2.0)
	var wheel := Node3D.new()
	wheel.name = "Roue_des_marees"
	root.add_child(wheel)
	wheel.global_transform = xf * Transform3D(Basis(), Vector3(-9.5, wy + 1.55, L + 2.0))
	var wm := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.55
	tm.outer_radius = 0.66
	wm.mesh = tm
	wm.material_override = kit.mat("bronze")
	wm.rotation.x = PI * 0.5
	wheel.add_child(wm)
	for k in range(4):
		var spoke := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(1.2, 0.06, 0.06)
		spoke.mesh = bm
		spoke.material_override = kit.mat("bronze")
		spoke.rotation.z = k * PI * 0.25
		wheel.add_child(spoke)
	w["roue_node"] = wheel
	# l'eau du bassin
	w["eau"] = water_plane(root, xf * Vector3(0, wy - 0.3, L + 15.0), Vector2(26.0, 22.0))
	(w["eau"] as Node3D).global_basis = xf.basis
	# les radeaux (le quatrième mène au pilier du coffre)
	var rafts: Array = []
	for rp in [Vector3(0.0, 0, L + 8.0), Vector3(-4.0, 0, L + 13.0), Vector3(1.5, 0, L + 18.0), Vector3(5.0, 0, L + 7.0)]:
		var raft := AnimatableBody3D.new()
		raft.name = "Radeau"
		raft.set_meta("lisse", true)
		root.add_child(raft)
		# un corps animé suit le serveur physique : on garde son repère d'origine à part
		# (relire sa position dans la même image renverrait l'ancienne)
		raft.set_meta("base_xf", xf * Transform3D(Basis(), rp + Vector3(0, wy, 0)))
		raft.global_transform = raft.get_meta("base_xf")
		var rcs := CollisionShape3D.new()
		var rbs := BoxShape3D.new()
		rbs.size = Vector3(3.2, 0.5, 3.2)
		rcs.shape = rbs
		raft.add_child(rcs)
		for k2 in range(5):
			var plank := MeshInstance3D.new()
			var pbm := BoxMesh.new()
			pbm.size = Vector3(0.6, 0.18, 3.2)
			plank.mesh = pbm
			plank.material_override = kit.mat("bois_c")
			plank.position = Vector3(-1.28 + k2 * 0.64, 0.16, 0)
			raft.add_child(plank)
		for s in [-1.0, 1.0]:
			var log := MeshInstance3D.new()
			var lcm := CylinderMesh.new()
			lcm.top_radius = 0.22
			lcm.bottom_radius = 0.22
			lcm.height = 3.3
			log.mesh = lcm
			log.material_override = kit.mat("poutre_c")
			log.rotation.x = PI * 0.5
			log.position = Vector3(s * 1.2, -0.12, 0)
			raft.add_child(log)
		rafts.append(raft)
	w["radeaux"] = rafts
	# le moulin (au-dessus du rebord du fond) et le pont-levis
	var mill := Node3D.new()
	mill.name = "Moulin"
	root.add_child(mill)
	mill.global_transform = xf * Transform3D(Basis(), Vector3(4.0, wy + 6.0, L + 29.2))
	for k3 in range(4):
		var blade := MeshInstance3D.new()
		var bbm := BoxMesh.new()
		bbm.size = Vector3(0.5, 2.8, 0.06)
		blade.mesh = bbm
		blade.material_override = kit.mat("bois_c")
		var arm := Node3D.new()
		arm.rotation.z = k3 * PI * 0.5
		mill.add_child(arm)
		arm.add_child(blade)
		blade.position = Vector3(0.25, 1.6, 0)
	var hubm := MeshInstance3D.new()
	var hcm := CylinderMesh.new()
	hcm.top_radius = 0.3
	hcm.bottom_radius = 0.3
	hcm.height = 0.3
	hubm.mesh = hcm
	hubm.material_override = kit.mat("bronze")
	hubm.rotation.x = PI * 0.5
	mill.add_child(hubm)
	w["moulin"] = mill
	var bridge := AnimatableBody3D.new()
	bridge.name = "Pont_levis"
	bridge.set_meta("lisse", true)
	root.add_child(bridge)
	bridge.set_meta("base_xf", xf * Transform3D(Basis(), Vector3(0, wy, L + 26.0)))
	bridge.global_transform = (bridge.get_meta("base_xf") as Transform3D) * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO)
	var bcs := CollisionShape3D.new()
	var bbs := BoxShape3D.new()
	bbs.size = Vector3(3.0, 0.3, 7.0)
	bcs.shape = bbs
	bcs.position = Vector3(0, -0.15, -3.5)
	bridge.add_child(bcs)
	var bmesh := MeshInstance3D.new()
	var bbx := BoxMesh.new()
	bbx.size = Vector3(3.0, 0.3, 7.0)
	bmesh.mesh = bbx
	bmesh.material_override = kit.mat("bois_c")
	bmesh.position = Vector3(0, -0.15, -3.5)
	bridge.add_child(bmesh)
	w["pont"] = bridge
	# les deux geysers (des grilles dans le bassin)
	w["geysers"] = [xf * Vector3(-1.8, wy - 5.0, L + 10.8), xf * Vector3(0.0, wy - 5.0, L + 15.7)]
	# --- B : la galerie des vagues : un canal, des niches pour s'abriter
	var b0: float = L + 36.0
	kit.solid(xf * Transform3D(Basis(), Vector3(0, wy - 0.3, b0 + 19.0)), Vector3(11.6, 0.6, 38.0), "corail", 3.0, 4)
	kit.solid(xf * Transform3D(Basis(), Vector3(0, wy + 7.4, b0 + 19.0)), Vector3(11.6, 0.8, 38.0), "granit_sombre", 3.0, 8)
	var niches := [b0 + 8.0, b0 + 16.0, b0 + 24.0, b0 + 32.0]
	for s4 in [-1.0, 1.0]:
		var cur: float = b0
		for zc in niches:
			wall_seg(xf, false, s4 * 5.4, cur, zc - 1.6, wy, wy + 7.0, "corail")
			# la niche : trois murs
			wall_seg(xf, false, s4 * 7.6, zc - 1.6, zc + 1.6, wy, wy + 3.6, "corail")
			var xa: float = minf(s4 * 5.0, s4 * 7.6)
			var xb: float = maxf(s4 * 5.0, s4 * 7.6)
			wall_seg(xf, true, zc - 2.0, xa, xb, wy, wy + 3.6, "corail")
			wall_seg(xf, true, zc + 2.0, xa, xb, wy, wy + 3.6, "corail")
			kit.solid(xf * Transform3D(Basis(), Vector3(s4 * 6.3, wy + 3.9, zc)), Vector3(2.6, 0.6, 4.4), "granit_sombre", 1.5)
			kit.solid(xf * Transform3D(Basis(), Vector3(s4 * 6.3, wy - 0.3, zc)), Vector3(2.6, 0.6, 4.0), "corail", 1.5)
			wall_seg(xf, false, s4 * 5.4, zc - 1.6, zc + 1.6, wy + 3.6, wy + 7.0, "corail")
			cur = zc + 1.6
		wall_seg(xf, false, s4 * 5.4, cur, b0 + 38.0, wy, wy + 7.0, "corail")
	# les murs du bout de la galerie (portes vers A et vers C)
	for zz in [b0, b0 + 38.0]:
		wall_seg(xf, true, zz + (-0.4 if zz == b0 else 0.4), -5.8, -2.0, wy, wy + 7.0, "corail")
		wall_seg(xf, true, zz + (-0.4 if zz == b0 else 0.4), 2.0, 5.8, wy, wy + 7.0, "corail")
		wall_seg(xf, true, zz + (-0.4 if zz == b0 else 0.4), -2.0, 2.0, wy + 4.4, wy + 7.0, "corail")
	kit.commit()
	w["niches"] = niches
	w["canal"] = water_plane(root, xf * Vector3(0, wy + 0.05, b0 + 19.0), Vector2(3.0, 37.0), Color(0.05, 0.22, 0.26, 0.7))
	(w["canal"] as Node3D).global_basis = xf.basis
	# la vague : un mur d'eau qui balaie la galerie
	var wave := Node3D.new()
	wave.name = "Vague"
	root.add_child(wave)
	wave.global_transform = xf * Transform3D(Basis(), Vector3(0, wy, b0 + 37.0))
	# un rouleau d'eau qui déferle (un demi-cylindre couché en travers de la galerie)
	var wmi := MeshInstance3D.new()
	var wbm := CylinderMesh.new()
	wbm.top_radius = 1.7
	wbm.bottom_radius = 1.7
	wbm.height = 10.6
	wbm.radial_segments = 24
	wbm.rings = 6
	wmi.mesh = wbm
	wmi.rotation.z = PI * 0.5
	wmi.scale = Vector3(1.0, 1.0, 0.75)
	var wsm := ShaderMaterial.new()
	wsm.shader = water_shader
	wsm.set_shader_parameter("teinte", Color(0.12, 0.42, 0.48, 0.75))
	wsm.set_shader_parameter("vagues", 4.0)
	wmi.material_override = wsm
	wmi.position = Vector3(0, 1.6, 0)
	wave.add_child(wmi)
	var foam := CPUParticles3D.new()
	foam.amount = 50
	foam.lifetime = 0.8
	foam.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	foam.emission_box_extents = Vector3(5.2, 0.3, 0.6)
	foam.direction = Vector3(0, 1, -0.6)
	foam.spread = 25.0
	foam.initial_velocity_min = 1.5
	foam.initial_velocity_max = 3.5
	var fq := QuadMesh.new()
	fq.size = Vector2(0.25, 0.25)
	var fqm := StandardMaterial3D.new()
	fqm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fqm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	fqm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fqm.albedo_color = Color(0.9, 0.97, 1.0, 0.7)
	if main.has_method("_soft_dot_v24"):
		fqm.albedo_texture = main._soft_dot_v24()
	fq.material = fqm
	foam.mesh = fq
	foam.position = Vector3(0, 3.2, 0)
	wave.add_child(foam)
	wave.visible = false
	w["vague"] = wave
	# lumières
	for z3 in [L + 6.0, L + 24.0]:
		for s5 in [-1.0, 1.0]:
			kit.torch(root, xf * Vector3(s5 * 12.55, wy + 3.2, z3), xf.basis * Vector3(-s5, 0, 0), 1.4)
	kit.glow_light(root, xf * Vector3(0, wy + 6.0, L + 15.0), Color(0.3, 0.8, 0.85), 1.8, 22.0, true)
	for gp in [Vector3(-10.5, 0, L + 14.0), Vector3(10.5, 0, L + 20.0), Vector3(-10.5, 0, L + 24.0)]:
		kit.glow_light(root, xf * (gp + Vector3(0, wy + 0.6, 0)), Color(0.35, 0.95, 0.85), 1.0, 9.0)
	for zc2 in niches:
		kit.glow_light(root, xf * Vector3(0, wy + 5.5, zc2), Color(0.35, 0.85, 0.9), 0.9, 10.0)
	# le bassin peu profond de l'arène
	w["arene_eau"] = water_plane(root, xf * Vector3(0, wy + 0.06, L + 91.0), Vector2(24.0, 24.0), Color(0.05, 0.22, 0.26, 0.55))
	(w["arene_eau"] as Node3D).global_basis = xf.basis


# =================================================================== l'Aile des Sables (sud)

func _build_sables() -> void:
	var n: String = "sables"
	var w: Dictionary = wings[n]
	var xf: Transform3D = w["xf"]
	var L: float = w["L"]
	var wy: float = w["wy"]
	var root: Node3D = w["root"]
	kit.root = root
	# --- A : la salle du soleil : quatre braseros sur des estrades, des sables mouvants au
	# milieu, des chemins de dalles, une stèle au centre.
	var qs := Rect2(-9.0, L + 6.0, 18.0, 18.0)
	w["sables_mouvants"] = [qs]
	var paths: Array = [Rect2(-1.0, L + 6.0, 2.0, 7.0), Rect2(-1.0, L + 13.0, 7.0, 2.0), Rect2(5.0, L + 13.0, 2.0, 7.0), Rect2(-7.0, L + 18.0, 12.0, 2.0),
		Rect2(-7.0, L + 20.0, 2.0, 4.0), Rect2(-3.0, L + 13.0, 2.0, 5.0)]
	w["chemins_a"] = paths
	for r in paths:
		var rr: Rect2 = r
		kit.solid(xf * Transform3D(Basis(), Vector3(rr.get_center().x, wy + 0.02, rr.get_center().y)), Vector3(rr.size.x, 0.12, rr.size.y), "dalles_c", 1.0)
	var braz := {"est": Vector3(11.0, 0, L + 15.0), "sud": Vector3(0.0, 0, L + 27.0), "ouest": Vector3(-11.0, 0, L + 15.0), "nord": Vector3(0.0, 0, L + 3.5)}
	var braziers: Dictionary = {}
	for k in braz:
		var p: Vector3 = braz[k]
		if k in ["est", "ouest"]:
			kit.solid(xf * Transform3D(Basis(), p + Vector3(0, wy + 0.3, 0)), Vector3(3.0, 0.6, 4.0), "gres_sombre", 1.0)
	kit.solid(xf * Transform3D(Basis(), Vector3(0, wy + 0.6, L + 15.0)), Vector3(1.4, 1.2, 0.5), "gres", 1.0)
	kit.box(xf * Transform3D(Basis(), Vector3(0, wy + 0.95, L + 14.73)), Vector3(1.2, 0.8, 0.02), "img_stele_soleil", 1.0)
	kit.commit()
	var qmi := MeshInstance3D.new()
	var qpm := PlaneMesh.new()
	qpm.size = Vector2(qs.size.x, qs.size.y)
	qmi.mesh = qpm
	var qmat := StandardMaterial3D.new()
	qmat.albedo_texture = load("res://assets/textures/terrain/sand.jpg")
	qmat.albedo_color = Color(0.92, 0.72, 0.48)
	qmat.uv1_scale = Vector3(4, 4, 4)
	qmat.roughness = 0.95
	qmi.material_override = qmat
	root.add_child(qmi)
	qmi.global_transform = xf * Transform3D(Basis(), Vector3(qs.get_center().x, wy + 0.01, qs.get_center().y))
	for k2 in braz:
		var p2: Vector3 = braz[k2]
		var lift: float = 0.6 if k2 in ["est", "ouest"] else 0.0
		braziers[k2] = kit.brazier(root, xf * (p2 + Vector3(0, wy + lift, 0)), false, "or_c", 2.6)
	w["braseros"] = braziers
	w["braseros_pos"] = {}
	for k3 in braz:
		w["braseros_pos"][k3] = xf * (braz[k3] + Vector3(0, wy + 1.4 + (0.6 if k3 in ["est", "ouest"] else 0.0), 0))
	w["stele"] = xf * Vector3(0, wy, L + 13.8)
	# --- B : le couloir des lames : quatre lames qui balancent, des dalles piégées (dards),
	# des sables mouvants au bout, avec des pierres de gué.
	var b0: float = L + 36.0
	var blades: Array = []
	for i in range(4):
		var z: float = b0 + 7.0 + i * 7.0
		var piv := Node3D.new()
		piv.name = "Lame_%d" % i
		root.add_child(piv)
		piv.global_transform = xf * Transform3D(Basis(), Vector3(0, wy + 6.6, z))
		var rod := MeshInstance3D.new()
		var rcm := CylinderMesh.new()
		rcm.top_radius = 0.07
		rcm.bottom_radius = 0.07
		rcm.height = 5.2
		rod.mesh = rcm
		rod.material_override = kit.mat("fonte_c")
		rod.position = Vector3(0, -2.6, 0)
		piv.add_child(rod)
		var blade := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 1.3
		cyl.bottom_radius = 1.3
		cyl.height = 0.06
		cyl.radial_segments = 24
		blade.mesh = cyl
		var steel := StandardMaterial3D.new()
		steel.albedo_color = Color(0.72, 0.73, 0.76)
		steel.metallic = 0.5
		steel.roughness = 0.28
		blade.material_override = steel
		blade.rotation.x = PI * 0.5
		blade.position = Vector3(0, -5.5, 0)
		blade.scale = Vector3(1.0, 1.0, 0.55)
		piv.add_child(blade)
		piv.set_meta("phase", i * 0.9)
		blades.append(piv)
		kit.box(xf * Transform3D(Basis(), Vector3(0, wy + 6.85, z)), Vector3(10.0, 0.3, 0.3), "fonte_c", 1.0)
	w["lames"] = blades
	var plates: Array = []
	for zp in [b0 + 10.5, b0 + 17.5, b0 + 24.5]:
		for xp in [-3.0, 0.0, 3.0]:
			if int(zp + xp * 3.0) % 2 == 0:
				continue
			plates.append(xf * Vector3(xp, wy + 0.03, zp))
	w["dalles_dards"] = plates
	for pp in plates:
		var pmi := MeshInstance3D.new()
		var pbm := BoxMesh.new()
		pbm.size = Vector3(1.6, 0.06, 1.6)
		pmi.mesh = pbm
		pmi.material_override = kit.mat("gres_sombre")
		root.add_child(pmi)
		pmi.global_position = pp
		pmi.global_basis = xf.basis
	var qs2 := Rect2(-5.0, b0 + 31.0, 10.0, 5.0)
	(w["sables_mouvants"] as Array).append(qs2)
	var q2 := MeshInstance3D.new()
	var q2pm := PlaneMesh.new()
	q2pm.size = Vector2(10.0, 5.0)
	q2.mesh = q2pm
	q2.material_override = qmat
	root.add_child(q2)
	q2.global_transform = xf * Transform3D(Basis(), Vector3(0, wy + 0.01, b0 + 33.5))
	var stones: Array = []
	for sp in [Vector3(-2.0, 0, b0 + 31.8), Vector3(0.6, 0, b0 + 33.0), Vector3(-1.2, 0, b0 + 34.6), Vector3(1.0, 0, b0 + 35.6)]:
		stones.append(Rect2(sp.x - 0.6, sp.z - 0.6, 1.2, 1.2))
		kit.solid(xf * Transform3D(Basis(), sp + Vector3(0, wy + 0.08, 0)), Vector3(1.2, 0.2, 1.2), "gres_sombre", 1.0)
	w["gues"] = stones
	kit.commit()
	for z4 in [L + 6.0, L + 24.0]:
		for s in [-1.0, 1.0]:
			kit.torch(root, xf * Vector3(s * 12.55, wy + 3.0, z4), xf.basis * Vector3(-s, 0, 0), 1.2)
	for z5 in [b0 + 4.0, b0 + 18.0, b0 + 32.0]:
		for s2 in [-1.0, 1.0]:
			kit.torch(root, xf * Vector3(s2 * 4.55, wy + 3.0, z5), xf.basis * Vector3(-s2, 0, 0), 1.3)
	# le sable de l'arène, des obélisques
	var ar := MeshInstance3D.new()
	var apm := PlaneMesh.new()
	apm.size = Vector2(25.0, 25.0)
	ar.mesh = apm
	ar.material_override = qmat
	root.add_child(ar)
	ar.global_transform = xf * Transform3D(Basis(), Vector3(0, wy + 0.02, L + 91.0))


# =================================================================== l'Aile des Rouages (nord)

func _build_rouages() -> void:
	var n: String = "rouages"
	var w: Dictionary = wings[n]
	var xf: Transform3D = w["xf"]
	var L: float = w["L"]
	var wy: float = w["wy"]
	var root: Node3D = w["root"]
	kit.root = root
	# --- A : le gouffre et ses trois plates-formes mécaniques ; le moteur sur le rebord
	kit.solid(xf * Transform3D(Basis(), Vector3(-11.4, wy + 1.4, L + 2.0)), Vector3(2.2, 2.8, 2.6), "fonte_c", 1.0)
	kit.commit()
	var motor := Node3D.new()
	motor.name = "Moteur"
	root.add_child(motor)
	motor.global_transform = xf * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(-10.1, wy + 2.0, L + 2.0))
	for k in range(2):
		var g := MeshInstance3D.new()
		g.mesh = load("res://scripts/pouvoirs_v63.gd").gear_mesh()
		g.material_override = kit.mat("laiton_c")
		g.scale = Vector3.ONE * (3.6 if k == 0 else 2.2)
		g.position = Vector3(0.0 if k == 0 else 0.9, 0, 0.0 if k == 0 else 0.9)
		motor.add_child(g)
	w["moteur"] = motor
	w["moteur_pos"] = xf * Vector3(-10.6, wy + 2.0, L + 2.0)
	var plats: Array = []
	var defs := [[Vector3(-6.0, 0, L + 5.5), Vector3(-6.0, 0, L + 12.5)], [Vector3(-6.0, 0, L + 15.5), Vector3(6.0, 0, L + 15.5)], [Vector3(6.0, 0, L + 18.5), Vector3(6.0, 0, L + 22.5)]]
	for dfn in defs:
		var pl := AnimatableBody3D.new()
		pl.name = "Plateforme"
		pl.set_meta("lisse", true)
		root.add_child(pl)
		pl.global_transform = xf * Transform3D(Basis(), (dfn[0] as Vector3) + Vector3(0, wy - 0.3, 0))
		var pcs := CollisionShape3D.new()
		var pbs := BoxShape3D.new()
		pbs.size = Vector3(3.0, 0.6, 3.0)
		pcs.shape = pbs
		pl.add_child(pcs)
		var pm := MeshInstance3D.new()
		var pbm := BoxMesh.new()
		pbm.size = Vector3(3.0, 0.6, 3.0)
		pm.mesh = pbm
		pm.material_override = kit.mat("fonte_c")
		pl.add_child(pm)
		var trim := MeshInstance3D.new()
		var tbm := BoxMesh.new()
		tbm.size = Vector3(3.1, 0.12, 3.1)
		trim.mesh = tbm
		trim.material_override = kit.mat("laiton_c")
		trim.position.y = 0.3
		pl.add_child(trim)
		var under := MeshInstance3D.new()
		under.mesh = load("res://scripts/pouvoirs_v63.gd").gear_mesh()
		under.material_override = kit.mat("cuivre_c")
		under.scale = Vector3.ONE * 3.2
		under.position.y = -0.45
		pl.add_child(under)
		plats.append({"body": pl, "a": xf * ((dfn[0] as Vector3) + Vector3(0, wy - 0.3, 0)), "b": xf * ((dfn[1] as Vector3) + Vector3(0, wy - 0.3, 0)), "gear": under})
	w["plates_formes"] = plats
	# des rails de laiton au-dessus du gouffre (où passent les plates-formes)
	for dfn2 in defs:
		var a: Vector3 = dfn2[0]
		var b: Vector3 = dfn2[1]
		var mid: Vector3 = (a + b) * 0.5
		var len3: float = a.distance_to(b) + 3.0
		var along_z: bool = absf(b.z - a.z) > 0.1
		kit.box(xf * Transform3D(Basis(), mid + Vector3(0, wy - 1.0, 0)), Vector3(0.4 if along_z else len3, 0.3, len3 if along_z else 0.4), "laiton_c", 1.0)
	kit.commit()
	# --- B : la forge des pistons : quatre pistons pleine largeur, des tapis roulants
	var b0: float = L + 36.0
	var pistons: Array = []
	for i in range(4):
		var z: float = b0 + 8.0 + i * 7.0
		var head := AnimatableBody3D.new()
		head.name = "Piston_%d" % i
		head.set_meta("lisse", true)
		root.add_child(head)
		head.global_transform = xf * Transform3D(Basis(), Vector3(0, wy + 5.6, z))
		var hcs := CollisionShape3D.new()
		var hbs := BoxShape3D.new()
		hbs.size = Vector3(9.8, 1.2, 2.4)
		hcs.shape = hbs
		hcs.position.y = 0.6
		head.add_child(hcs)
		var hm := MeshInstance3D.new()
		var hbm := BoxMesh.new()
		hbm.size = Vector3(9.8, 1.2, 2.4)
		hm.mesh = hbm
		hm.material_override = kit.mat("fonte_c")
		hm.position.y = 0.6
		head.add_child(hm)
		for s in [-1.0, 1.0]:
			var rod := MeshInstance3D.new()
			var rcm := CylinderMesh.new()
			rcm.top_radius = 0.25
			rcm.bottom_radius = 0.25
			rcm.height = 6.0
			rod.mesh = rcm
			rod.material_override = kit.mat("laiton_c")
			rod.position = Vector3(s * 3.0, 4.2, 0)
			head.add_child(rod)
		head.set_meta("phase", i * 0.85)
		pistons.append(head)
		kit.box(xf * Transform3D(Basis(), Vector3(0, wy + 0.02, z)), Vector3(9.8, 0.04, 2.4), "fonte_c", 1.0)
	w["pistons"] = pistons
	var belts: Array = []
	for i2 in range(3):
		var zc: float = b0 + 11.5 + i2 * 7.0
		belts.append(Rect2(-5.0, zc - 1.6, 10.0, 3.2))
		kit.box(xf * Transform3D(Basis(), Vector3(0, wy + 0.03, zc)), Vector3(9.8, 0.06, 3.2), "img_tapis", 1.0)
	w["tapis"] = belts
	kit.commit()
	for z4 in [L + 6.0, L + 24.0]:
		for s2 in [-1.0, 1.0]:
			kit.torch(root, xf * Vector3(s2 * 12.55, wy + 3.0, z4), xf.basis * Vector3(-s2, 0, 0), 1.3)
	for z5 in [b0 + 4.0, b0 + 33.0]:
		for s3 in [-1.0, 1.0]:
			kit.torch(root, xf * Vector3(s3 * 4.55, wy + 3.0, z5), xf.basis * Vector3(-s3, 0, 0), 1.3)
	kit.glow_light(root, xf * Vector3(0, wy + 6.0, b0 + 19.0), Color(1.0, 0.7, 0.35), 1.2, 22.0)


# =================================================================== l'Aile de la Lune (est)

func _build_lune() -> void:
	var n: String = "lune"
	var w: Dictionary = wings[n]
	var xf: Transform3D = w["xf"]
	var L: float = w["L"]
	var wy: float = w["wy"]
	var root: Node3D = w["root"]
	kit.root = root
	# --- A : le gouffre aux ponts : une île au milieu ; des ponts vrais (invisibles, sauf à
	# la Lueur de lune) et des ponts faux (visibles… qui s'effacent à la Lueur).
	kit.solid(xf * Transform3D(Basis(), Vector3(0, wy - 6.0, L + 16.0)), Vector3(8.0, 12.0, 4.0), "ardoise_c", 2.0)
	kit.commit()
	var true_paths := [
		[Vector3(-6.0, 0, L + 4.0), Vector3(-6.0, 0, L + 9.0)], [Vector3(-6.0, 0, L + 9.0), Vector3(-2.5, 0, L + 9.0)], [Vector3(-2.5, 0, L + 9.0), Vector3(-2.5, 0, L + 14.0)],
		[Vector3(2.5, 0, L + 18.0), Vector3(2.5, 0, L + 21.0)], [Vector3(2.5, 0, L + 21.0), Vector3(7.0, 0, L + 21.0)], [Vector3(7.0, 0, L + 21.0), Vector3(7.0, 0, L + 26.0)],
	]
	var fake_paths := [[Vector3(1.5, 0, L + 4.0), Vector3(1.5, 0, L + 14.0)], [Vector3(-3.0, 0, L + 18.0), Vector3(-3.0, 0, L + 26.0)]]
	var moon_mat := StandardMaterial3D.new()
	moon_mat.albedo_color = Color(0.62, 0.74, 1.0, 0.42)
	moon_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	moon_mat.emission_enabled = true
	moon_mat.emission = Color(0.6, 0.75, 1.0)
	moon_mat.emission_energy_multiplier = 0.55
	moon_mat.roughness = 0.1
	var true_nodes: Array = []
	for tp in true_paths:
		var body := StaticBody3D.new()
		body.set_meta("lisse", true)
		root.add_child(body)
		var a: Vector3 = tp[0]
		var b: Vector3 = tp[1]
		var mid: Vector3 = (a + b) * 0.5
		var along_z: bool = absf(b.z - a.z) > 0.1
		var size := Vector3(1.8, 0.3, b.z - a.z + 1.8) if along_z else Vector3(absf(b.x - a.x) + 1.8, 0.3, 1.8)
		body.global_transform = xf * Transform3D(Basis(), mid + Vector3(0, wy - 0.15, 0))
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = size
		cs.shape = bs
		body.add_child(cs)
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = size
		mi.mesh = bm
		mi.material_override = moon_mat
		mi.visible = false
		mi.name = "Lumiere"
		body.add_child(mi)
		true_nodes.append(body)
	w["ponts_vrais"] = true_nodes
	var fake_nodes: Array = []
	for fp in fake_paths:
		var a2: Vector3 = fp[0]
		var b2: Vector3 = fp[1]
		var mid2: Vector3 = (a2 + b2) * 0.5
		var mi2 := MeshInstance3D.new()
		var bm2 := BoxMesh.new()
		bm2.size = Vector3(2.0, 0.3, b2.z - a2.z + 2.0)
		mi2.mesh = bm2
		mi2.material_override = kit.mat("ardoise_c")
		root.add_child(mi2)
		mi2.global_transform = xf * Transform3D(Basis(), mid2 + Vector3(0, wy - 0.15, 0))
		fake_nodes.append(mi2)
	w["ponts_faux"] = fake_nodes
	# l'écriture de lune sur la porte, les quatre cadrans des phases
	var ink := MeshInstance3D.new()
	var iq := QuadMesh.new()
	iq.size = Vector2(4.0, 1.4)
	ink.mesh = iq
	var im := StandardMaterial3D.new()
	im.albedo_texture = load("res://assets/textures/coeur/encre_lune.png") if ResourceLoader.exists("res://assets/textures/coeur/encre_lune.png") else null
	im.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	im.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	im.albedo_color = Color(0.75, 0.85, 1.0, 1.0)
	ink.material_override = im
	root.add_child(ink)
	ink.global_transform = xf * Transform3D(Basis(Vector3.UP, PI), Vector3(0, wy + 6.0, L + 29.55))
	ink.visible = false
	w["encre"] = ink
	var dial_mat := StandardMaterial3D.new()
	dial_mat.albedo_texture = load("res://assets/textures/coeur/phases_lune.png") if ResourceLoader.exists("res://assets/textures/coeur/phases_lune.png") else null
	dial_mat.albedo_color = Color(1, 1, 1) if dial_mat.albedo_texture != null else Color(0.6, 0.65, 0.8)
	dial_mat.metallic = 0.6
	dial_mat.roughness = 0.3
	var dials: Array = []
	for i in range(4):
		var dn := Node3D.new()
		dn.name = "Cadran_%d" % i
		root.add_child(dn)
		dn.global_transform = xf * Transform3D(Basis(Vector3.UP, PI), Vector3(-3.0 + i * 2.0, wy + 2.2, L + 29.5))
		var disc := MeshInstance3D.new()
		var dm := CylinderMesh.new()
		dm.top_radius = 0.7
		dm.bottom_radius = 0.7
		dm.height = 0.08
		dm.radial_segments = 32
		disc.mesh = dm
		disc.material_override = dial_mat
		disc.rotation.x = PI * 0.5
		dn.add_child(disc)
		dials.append(dn)
		kit.box(xf * Transform3D(Basis(), Vector3(-3.0 + i * 2.0, wy + 3.05, L + 29.45)), Vector3(0.14, 0.12, 0.05), "argent_c", 0.5)
	w["cadrans"] = dials
	# --- B : la galerie des ombres : des dalles noires d'où montent des mains d'ombre
	var b0: float = L + 36.0
	var dark: Array = []
	for i2 in range(8):
		for j in range(3):
			if (i2 + j) % 2 == 0:
				continue
			var r := Rect2(-5.0 + j * 3.34, b0 + 3.0 + i2 * 4.0, 3.34, 4.0)
			dark.append(r)
			kit.box(xf * Transform3D(Basis(), Vector3(r.get_center().x, wy + 0.015, r.get_center().y)), Vector3(r.size.x, 0.03, r.size.y), "noir", 1.0)
	w["ombres"] = dark
	kit.commit()
	# des fenêtres de lune (lumière bleue) dans la voûte, les torches bleues
	for z4 in [L + 6.0, L + 24.0]:
		for s in [-1.0, 1.0]:
			kit.glow_light(root, xf * Vector3(s * 11.0, wy + 7.0, z4), Color(0.55, 0.65, 1.0), 1.0, 14.0)
	for z5 in [b0 + 6.0, b0 + 20.0, b0 + 34.0]:
		kit.glow_light(root, xf * Vector3(0, wy + 6.0, z5), Color(0.45, 0.55, 0.95), 0.7, 11.0)
	var moon := SpotLight3D.new()
	moon.light_color = Color(0.7, 0.8, 1.0)
	moon.light_energy = 5.0
	moon.spot_range = 16.0
	moon.spot_angle = 26.0
	moon.shadow_enabled = pc
	root.add_child(moon)
	moon.global_transform = xf * Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), Vector3(0, wy + 10.8, L + 91.0))


# =================================================================== la Salle du Cœur

func _build_heart() -> void:
	heart_root = _root("Salle_du_coeur_v63")
	var c: Vector3 = O + Vector3(0, HEART_Y, 0)
	var xf := Transform3D(Basis(), c)
	var R: float = HEART_R
	var hgt: float = 20.0
	kit.solid(xf * Transform3D(Basis(), Vector3(0, -0.3, 0)), Vector3(2 * R + 2.0, 0.6, 2 * R + 2.0), "granit_sombre", 3.0, 4)
	kit.solid(xf * Transform3D(Basis(), Vector3(0, hgt + 0.4, 0)), Vector3(2 * R + 2.0, 0.8, 2 * R + 2.0), "granit_sombre", 4.0, 8)
	var seg: int = 28
	for i in range(seg):
		var a: float = TAU * (i + 0.5) / seg
		var dir := Vector3(cos(a), 0, sin(a))
		var w: float = TAU * R / seg + 0.4
		if absf(a - PI * 0.5) < 0.12:
			# l'arrivée de l'escalier, au sud
			kit.solid(Transform3D(Basis(Vector3.UP, -a + PI * 0.5), c + dir * (R + 0.5) + Vector3(0, (hgt + 5.0) * 0.5, 0)), Vector3(w, hgt - 5.0, 1.0), "granit", 3.0)
			continue
		kit.solid(Transform3D(Basis(Vector3.UP, -a + PI * 0.5), c + dir * (R + 0.5) + Vector3(0, hgt * 0.5, 0)), Vector3(w, hgt, 1.0), "granit", 3.0)
	# l'escalier d'arrivée (il remonte vers la Rose des Sceaux, dans le noir)
	kit.ramp(xf, Vector3(0, 0, R - 0.5), Vector3(0, 4.0, R + 6.0), 4.0, "dalles_c")
	for s in [-1.0, 1.0]:
		kit.solid(xf * Transform3D(Basis(), Vector3(s * 2.5, 3.0, R + 3.5)), Vector3(1.0, 6.0, 7.0), "granit", 2.0)
	kit.solid(xf * Transform3D(Basis(), Vector3(0, 6.4, R + 3.5)), Vector3(6.0, 0.8, 7.0), "granit_sombre", 2.0)
	kit.solid(xf * Transform3D(Basis(), Vector3(0, 4.0, R + 7.0)), Vector3(4.0, 8.0, 0.6), "noir", 1.0)
	for s4 in [-1.0, 1.0]:
		kit.solid(xf * Transform3D(Basis(), Vector3(s4 * 4.3, 2.5, R + 0.6)), Vector3(2.6, 5.0, 1.4), "granit", 2.0)
	# des veines de feu dans le sol, en étoile
	for k in range(12):
		var a2: float = TAU * k / 12.0
		var d2 := Vector3(cos(a2), 0, sin(a2))
		kit.box(Transform3D(Basis(Vector3.UP, -a2), c + d2 * 11.5 + Vector3(0, 0.02, 0)), Vector3(16.0, 0.03, 0.18), "glow_rouge", 2.0)
	# quatre piliers aux glyphes des peuples
	for i2 in range(4):
		var n: String = WING_ORDER[i2]
		var dir2: Vector3 = wxf(n).basis * Vector3(0, 0, 1)
		var p: Vector3 = c + dir2 * 15.0
		kit.column(Transform3D(Basis(), p), 1.3, hgt, "granit", "granit_sombre")
		kit.cyl(Transform3D(Basis(Vector3.UP, atan2(-dir2.x, -dir2.z)) * Basis(Vector3.RIGHT, PI * 0.5), p - dir2 * 1.32 + Vector3(0, 4.5, 0)), 0.8, 0.8, 0.1, "img_emblem_" + n, 24)
	kit.commit()
	for i3 in range(4):
		var n2: String = WING_ORDER[i3]
		var dir3: Vector3 = wxf(n2).basis * Vector3(0, 0, 1)
		kit.glow_light(heart_root, c + dir3 * 13.0 + Vector3(0, 6.0, 0), WING_DEF[n2]["couleur"], 1.2, 14.0)
	# le cristal du Cœur, suspendu au milieu
	heart_crystal = Node3D.new()
	heart_crystal.name = "Cristal_du_coeur"
	heart_root.add_child(heart_crystal)
	heart_crystal.global_position = c + Vector3(0, 13.0, 0)
	var cm := StandardMaterial3D.new()
	cm.albedo_color = Color(0.6, 0.08, 0.05, 0.9)
	cm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cm.roughness = 0.08
	cm.emission_enabled = true
	cm.emission = Color(1.0, 0.22, 0.08)
	cm.emission_energy_multiplier = 1.1
	for k2 in range(7):
		var pr := MeshInstance3D.new()
		var sc: float = 1.0 if k2 == 0 else 0.6
		var pm: Mesh = crystal_mesh(2.2 * sc, 4.6 * sc)
		pr.mesh = pm
		pr.material_override = cm
		var a3: float = TAU * k2 / 6.0
		pr.position = Vector3.ZERO if k2 == 0 else Vector3(cos(a3) * 1.3, -0.8, sin(a3) * 1.3)
		pr.rotation = Vector3(0.0 if k2 == 0 else cos(a3) * 0.5, a3, 0.0 if k2 == 0 else sin(a3) * 0.5)
		heart_crystal.add_child(pr)
		var low := MeshInstance3D.new()
		low.mesh = pm
		low.material_override = cm
		low.rotation.z = PI
		low.position = Vector3(0, -4.4 * sc * 0.75, 0) if k2 == 0 else Vector3(cos(a3) * 1.3, -2.4, sin(a3) * 1.3)
		if k2 == 0:
			heart_crystal.add_child(low)
	heart_light = OmniLight3D.new()
	heart_light.light_color = Color(1.0, 0.28, 0.12)
	heart_light.light_energy = 3.0
	heart_light.omni_range = 34.0
	heart_light.shadow_enabled = pc
	heart_crystal.add_child(heart_light)
	w_heart_mat = cm
	for k3 in range(6):
		var a4: float = TAU * k3 / 6.0
		var chain := MeshInstance3D.new()
		var ccm := CylinderMesh.new()
		ccm.top_radius = 0.08
		ccm.bottom_radius = 0.08
		ccm.height = 9.0
		chain.mesh = ccm
		chain.material_override = kit.mat("fonte_c")
		heart_root.add_child(chain)
		chain.global_position = c + Vector3(cos(a4) * 3.0, 16.5, sin(a4) * 3.0)
		chain.rotation = Vector3(sin(a4) * 0.35, 0, -cos(a4) * 0.35)
	points["coeur_arrivee"] = c + Vector3(0, 0.1, R - 1.5)
	points["coeur_centre"] = c + Vector3(0, 0.1, 0)
	points["coeur_retour"] = c + Vector3(0, 0.1, -12.0)


var w_heart_mat: StandardMaterial3D
