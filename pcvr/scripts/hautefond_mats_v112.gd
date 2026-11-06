extends RefCounted
## V112 : les matières de Hautefond, la cité-colonne (fantastique-vapeur) : la pierre blonde, l'ardoise
## bleue, les dalles des places, le laiton, le cuivre (neuf ou vert-de-gris), l'acier riveté, le verre
## de la Grande Colonne et de ses cabines, les globes des lampes, les enseignes, la bannière.
## Une clé « genre112_variante » (« pierre112_clair », « enseigne112_horloger »…) ; null si la clé
## n'est pas d'ici. Gardées une fois faites ; les globes et les vitres allumées montent à la nuit
## (night(), temps_v56). Si une texture manque, la matière garde une couleur plausible.

const S := "res://assets/textures/hautefond/"
const TEINTES := {
	"": Color(1.06, 1.0, 0.9), "clair": Color(1.14, 1.08, 0.98), "sombre": Color(0.72, 0.69, 0.64), "chaud": Color(1.06, 0.97, 0.86),
	"rose": Color(1.06, 0.92, 0.86), "gris": Color(0.9, 0.9, 0.88), "vieux": Color(0.86, 0.82, 0.74),
}
static var _cache: Dictionary = {}


static func _t(name: String) -> Texture2D:
	var p: String = S + name
	return load(p) if ResourceLoader.exists(p) else null


static func _surface(name: String, tint: Color, rough: float, nscale: float = 1.0, base := Color(0.7, 0.68, 0.64)) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	var tex: Texture2D = _t(name + ".png")
	m.albedo_texture = tex
	var n: Texture2D = _t(name + "_n.png")
	if n != null:
		m.normal_enabled = true
		m.normal_texture = n
		m.normal_scale = nscale
	m.albedo_color = tint if tex != null else Color(base.r * tint.r, base.g * tint.g, base.b * tint.b)
	m.roughness = rough
	return m


static func _panel(name: String, alpha: bool = false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = _t(name + ".png")
	m.roughness = 0.82
	if alpha:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		m.alpha_scissor_threshold = 0.4
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


static func _metal(c: Color, rough: float, metal: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	m.metallic_specular = 0.6
	return m


static func make(key: String) -> Material:
	if _cache.has(key):
		return _cache[key]
	var parts: PackedStringArray = key.split("_", true, 1)
	var kind: String = parts[0]
	if not kind.ends_with("112"):
		return null
	var v: String = parts[1] if parts.size() > 1 else ""
	var tint: Color = TEINTES.get(v, Color(1, 1, 1))
	var m: Material = null
	match kind:
		"pierre112":
			m = _surface("pierre_blonde", tint, 0.86, 1.0, Color(0.8, 0.7, 0.52))
		"ardoise112":
			m = _surface("ardoise_hf", tint, 0.5, 1.1, Color(0.3, 0.33, 0.38))
		"pave112":
			m = _surface("pave_blond", Color(tint.r * 1.06, tint.g * 1.0, tint.b * 0.86), 0.74, 0.9, Color(0.72, 0.66, 0.54))
		"laiton112":
			m = _metal(Color(0.86, 0.66, 0.32) if v != "vieux" else Color(0.62, 0.48, 0.26), 0.3 if v != "vieux" else 0.46, 0.9)
		"bronze112":
			m = _metal(Color(0.36, 0.25, 0.15), 0.42, 0.85)
		"or112":
			m = _metal(Color(1.0, 0.8, 0.38), 0.24, 0.95)
		"cuivre112":
			m = _metal(Color(0.9, 0.52, 0.34), 0.34, 0.9)
		"verdigris112":
			m = _metal(Color(0.34, 0.58, 0.5), 0.62, 0.35)
		"acier112":
			m = _metal(Color(0.2, 0.21, 0.23) if v != "clair" else Color(0.42, 0.43, 0.45), 0.42, 0.85)
		"bois112":
			var bo := StandardMaterial3D.new()
			var bt: Texture2D = load("res://assets/textures/montjoie/bois_planches.png") if ResourceLoader.exists("res://assets/textures/montjoie/bois_planches.png") else null
			bo.albedo_texture = bt
			bo.albedo_color = Color(0.52, 0.34, 0.22) if bt != null else Color(0.3, 0.2, 0.13)
			bo.roughness = 0.5
			m = bo
		"verre112":
			# le verre de la Colonne : bleuté, presque transparent, qui reflète le ciel
			var vg := StandardMaterial3D.new()
			vg.albedo_color = Color(0.62, 0.8, 0.92, 0.16) if v != "cabine" else Color(0.85, 0.92, 1.0, 0.1)
			vg.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			vg.cull_mode = BaseMaterial3D.CULL_DISABLED
			vg.roughness = 0.04
			vg.metallic = 0.2
			vg.metallic_specular = 1.0
			vg.rim_enabled = true
			vg.rim = 0.4
			vg.rim_tint = 0.6
			m = vg
		"lampe112":
			# les globes des lampes et des cabines : une lueur chaude, plus forte la nuit (night())
			var lg := StandardMaterial3D.new()
			lg.albedo_color = Color(1.0, 0.88, 0.62)
			lg.emission_enabled = true
			lg.emission = Color(1.0, 0.74, 0.42)
			lg.emission_energy_multiplier = 0.6
			lg.roughness = 0.3
			m = lg
		"phare112":
			var ph := StandardMaterial3D.new()
			ph.albedo_color = Color(1.0, 0.96, 0.8)
			ph.emission_enabled = true
			ph.emission = Color(1.0, 0.9, 0.62)
			ph.emission_energy_multiplier = 1.0
			m = ph
		"enseigne112":
			m = _panel("enseigne_" + v, true)
		"banniere112":
			var bn := _panel("banniere_hautefond", true)
			if bn.albedo_texture == null:
				bn.albedo_color = Color(0.1, 0.14, 0.34)
			m = bn
		"tissu112":
			var ti := StandardMaterial3D.new()
			ti.albedo_color = {"bleu": Color(0.14, 0.2, 0.46), "rouge": Color(0.6, 0.12, 0.1), "or": Color(0.86, 0.64, 0.2),
				"creme": Color(0.9, 0.86, 0.74), "vert": Color(0.18, 0.36, 0.24)}.get(v, Color(0.14, 0.2, 0.46))
			ti.roughness = 0.9
			ti.cull_mode = BaseMaterial3D.CULL_DISABLED
			m = ti
		"cadran112":
			# le cadran de la grande horloge : crème, un peu lumineux la nuit
			var cd := StandardMaterial3D.new()
			cd.albedo_color = Color(0.95, 0.9, 0.78)
			cd.emission_enabled = true
			cd.emission = Color(1.0, 0.86, 0.6)
			cd.emission_energy_multiplier = 0.05
			cd.roughness = 0.5
			m = cd
		"eau112":
			var ea := StandardMaterial3D.new()
			ea.albedo_color = Color(0.3, 0.5, 0.56, 0.7)
			ea.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			ea.roughness = 0.05
			ea.metallic_specular = 0.9
			ea.normal_enabled = true
			ea.normal_texture = load("res://assets/textures/water/water_n.png") if ResourceLoader.exists("res://assets/textures/water/water_n.png") else null
			ea.normal_scale = 0.35
			ea.uv1_scale = Vector3(0.14, 0.14, 0.14)
			m = ea
	if m != null:
		_cache[key] = m
	return m


## La nuit tombe (k = 1) ou le jour se lève (k = 0) : les globes, le phare, les cadrans s'allument.
static func night(k: float) -> void:
	var lg: StandardMaterial3D = make("lampe112") as StandardMaterial3D
	if lg != null:
		lg.emission_energy_multiplier = lerpf(0.6, 4.0, k)
	var cd: StandardMaterial3D = make("cadran112") as StandardMaterial3D
	if cd != null:
		cd.emission_energy_multiplier = lerpf(0.05, 1.2, k)
	var ph: StandardMaterial3D = make("phare112") as StandardMaterial3D
	if ph != null:
		ph.emission_energy_multiplier = lerpf(1.0, 8.0, k)
