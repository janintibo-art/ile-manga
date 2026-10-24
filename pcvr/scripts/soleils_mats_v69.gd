extends RefCounted
## V69 : les matières de l'Île des Trois Soleils, partagées par le kit des villages
## (soleils_kit_v69.gd) et celui des donjons (donjon_kit_v69.gd). Une clé « genre69_variante »
## (« enduit69_ocre », « fresque69_pesee », « sym69_ibis »…) ; null si la clé n'est pas d'ici.
## Les matières sont gardées une fois faites (les deux kits partagent les mêmes).

const S := "res://assets/textures/soleils/"
const TEINTES := {
	"": Color(1, 1, 1), "blanc": Color(1.04, 1.03, 1.0), "ocre": Color(1.0, 0.82, 0.58), "rouge": Color(0.86, 0.36, 0.28),
	"bleu": Color(0.42, 0.66, 0.78), "vert": Color(0.55, 0.72, 0.5), "jaune": Color(1.05, 0.88, 0.5), "rose": Color(1.0, 0.76, 0.7),
	"sombre": Color(0.62, 0.58, 0.54), "noir": Color(0.32, 0.3, 0.3), "turquoise": Color(0.36, 0.74, 0.72), "terre": Color(0.78, 0.6, 0.45), "dore": Color(0.9, 0.79, 0.63), "granit": Color(0.74, 0.44, 0.38),
}
static var _cache: Dictionary = {}


static func _t(name: String) -> Texture2D:
	var p: String = S + name
	return load(p) if ResourceLoader.exists(p) else null


static func _surface(name: String, tint: Color, rough: float, nscale: float = 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = _t(name + ".png")
	var n: Texture2D = _t(name + "_n.png")
	if n != null:
		m.normal_enabled = true
		m.normal_texture = n
		m.normal_scale = nscale
	m.albedo_color = tint
	m.roughness = rough
	return m


static func _panel(name: String, tint: Color = Color(1, 1, 1), alpha: bool = false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = _t(name + ".png")
	m.albedo_color = tint
	m.roughness = 0.9
	if alpha:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		m.alpha_scissor_threshold = 0.4
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


static func _flat(c: Color, rough: float, metal: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	return m


static func _glow(c: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	m.roughness = 0.4
	return m


static func make(key: String) -> Material:
	if _cache.has(key):
		return _cache[key]
	var parts: PackedStringArray = key.split("_", true, 1)
	var kind: String = parts[0]
	if not kind.ends_with("69"):
		return null
	var v: String = parts[1] if parts.size() > 1 else ""
	var tint: Color = TEINTES.get(v, Color(1, 1, 1))
	var m: Material = null
	match kind:
		"calc69":
			m = _surface("calcaire", tint, 0.78, 0.9)
		"gres69":
			m = _surface("gres", tint, 0.86, 1.1)
		"statue69":
			# une pierre d'un seul bloc, polie puis usée (les statues, sans joints d'appareil)
			m = _surface("enduit", tint, 0.6, 0.35)
		"brique69":
			m = _surface("brique", tint, 0.93, 1.1)
		"enduit69":
			m = _surface("enduit", tint, 0.92, 0.7)
		"hiero69":
			m = _surface("hieroglyphes", tint, 0.86, 0.9)
		"pmaya69":
			m = _surface("pierre_maya", tint, 0.9, 1.15)
		"stucr69":
			m = _surface("stuc_rouge", tint, 0.88, 0.8)
		"glyphm69":
			m = _surface("glyphes_maya", tint, 0.9, 1.2)
		"tezo69":
			# (la pierre volcanique est sombre : on la relève un peu pour qu'elle prenne la lumière)
			m = _surface("tezontle", tint * Color(1.35, 1.32, 1.3), 0.94, 1.3)
		"frise69":
			m = _surface("frise_azteque", tint, 0.88, 0.7)
		"dalles69":
			m = _surface("dalles_soleil", tint, 0.82, 1.0)
		"psombre69":
			m = _surface("pierre_sombre", tint * Color(1.45, 1.42, 1.4), 0.9, 1.2)
		"roche69":
			var r: StandardMaterial3D = _surface("roche", tint, 0.9, 1.2)
			r.uv1_triplanar = true
			r.uv1_scale = Vector3.ONE * 0.22
			m = r
		"sable69":
			var sa: StandardMaterial3D = _surface("sable", tint, 0.96, 0.8)
			sa.uv1_triplanar = true
			sa.uv1_scale = Vector3.ONE * 0.25
			m = sa
		"limon69":
			var li: StandardMaterial3D = _surface("limon", tint, 0.9, 0.9)
			li.uv1_triplanar = true
			li.uv1_scale = Vector3.ONE * 0.3
			m = li
		"herbe69":
			var he: StandardMaterial3D = _surface("herbe", tint, 0.95, 0.9)
			he.uv1_triplanar = true
			he.uv1_scale = Vector3.ONE * 0.3
			m = he
		"fresque69":
			m = _panel("fresque_" + v)
		"codex69":
			m = _panel("codex_" + v)
		"papyrus69":
			m = _panel("papyrus_" + v)
		"stele69":
			m = _panel("stele_" + v)
		"sym69":
			m = _panel("sym_" + v, Color(1, 1, 1), true)
		"psoleil69":
			m = _panel("pierre_soleil", Color(1, 1, 1), true)
		"enseigne69":
			m = _panel("enseigne_" + v)
		"or69":
			m = _flat(Color(1.0, 0.77, 0.32), 0.28, 0.85)
		"bronze69":
			var b: StandardMaterial3D = _flat(Color(0.72, 0.5, 0.26), 0.32, 0.75)
			m = b
		"miroir69":
			m = _flat(Color(0.95, 0.82, 0.58), 0.08, 1.0)
		"jade69":
			var j := StandardMaterial3D.new()
			j.albedo_color = Color(0.2, 0.55, 0.38)
			j.roughness = 0.22
			j.metallic_specular = 0.8
			j.subsurf_scatter_enabled = false
			m = j
		"turq69":
			m = _flat(Color(0.25, 0.7, 0.68), 0.35)
		"lapis69":
			m = _flat(Color(0.12, 0.2, 0.62), 0.3)
		"obsid69":
			m = _flat(Color(0.05, 0.05, 0.06), 0.06, 0.2)
		"noir69":
			var nr := StandardMaterial3D.new()
			nr.albedo_color = Color(0.025, 0.022, 0.02)
			nr.roughness = 1.0
			nr.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
			m = nr
		"lin69":
			var l := StandardMaterial3D.new()
			l.albedo_color = Color(0.94, 0.91, 0.82) * tint
			l.roughness = 0.97
			l.cull_mode = BaseMaterial3D.CULL_DISABLED
			m = l
		"plume69":
			var p := StandardMaterial3D.new()
			p.albedo_color = {"": Color(0.1, 0.55, 0.3), "rouge": Color(0.75, 0.12, 0.08), "bleu": Color(0.1, 0.35, 0.75), "jaune": Color(0.95, 0.75, 0.15)}.get(v, Color(0.1, 0.55, 0.3))
			p.roughness = 0.5
			p.metallic_specular = 0.7
			p.cull_mode = BaseMaterial3D.CULL_DISABLED
			m = p
		"argile69":
			m = _flat(Color(0.66, 0.4, 0.26) * tint, 0.88)
		"bois69":
			var w := StandardMaterial3D.new()
			w.albedo_texture = load("res://assets/textures/pirates/rondins.png")
			w.normal_enabled = true
			w.normal_texture = load("res://assets/textures/pirates/rondins_n.png")
			w.albedo_color = Color(0.8, 0.68, 0.52) * tint
			w.roughness = 0.9
			m = w
		"palme69":
			var pa := StandardMaterial3D.new()
			pa.albedo_texture = load("res://assets/textures/pirates/palmes.png")
			pa.normal_enabled = true
			pa.normal_texture = load("res://assets/textures/pirates/palmes_n.png")
			pa.albedo_color = Color(0.92, 0.86, 0.68) * tint
			pa.roughness = 0.96
			pa.cull_mode = BaseMaterial3D.CULL_DISABLED
			m = pa
		"eau69":
			m = _water(v)
		"feu69":
			m = _glow(Color(1.0, 0.55, 0.18), 3.0)
		"lueur69":
			m = _glow({"": Color(1.0, 0.82, 0.4), "bleu": Color(0.45, 0.75, 1.0), "vert": Color(0.4, 1.0, 0.6), "rouge": Color(1.0, 0.25, 0.15), "or": Color(1.0, 0.8, 0.3)}.get(v, Color(1.0, 0.82, 0.4)), 2.4)
		"rayon69":
			var ry := StandardMaterial3D.new()
			ry.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			ry.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			ry.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
			ry.albedo_color = Color(1.0, 0.86, 0.5, 0.55)
			ry.cull_mode = BaseMaterial3D.CULL_DISABLED
			m = ry
	if m != null:
		_cache[key] = m
	return m


## L'eau douce : le lac (vert-bleu, calme), le cénote (vert émeraude), les bassins des donjons.
static func _water(v: String) -> Material:
	var sh: Shader = load("res://shaders/eau_douce_v69.gdshader")
	var m := ShaderMaterial.new()
	m.shader = sh
	var n: Texture2D = load("res://assets/textures/water/water_n.png")
	m.set_shader_parameter("ripple_n", n)
	match v:
		"cenote":
			m.set_shader_parameter("deep", Color(0.02, 0.2, 0.16))
			m.set_shader_parameter("shallow", Color(0.1, 0.5, 0.4))
		"sombre":
			m.set_shader_parameter("deep", Color(0.01, 0.04, 0.05))
			m.set_shader_parameter("shallow", Color(0.05, 0.14, 0.16))
		_:
			m.set_shader_parameter("deep", Color(0.04, 0.18, 0.24))
			m.set_shader_parameter("shallow", Color(0.16, 0.42, 0.42))
	return m
