extends RefCounted
## V70 : les matières de l'Île de Braise et de Pandémonia, partagées par le kit de la cité
## (braise_kit_v70.gd) et le donjon des Neuf Cercles. Une clé « genre70_variante »
## (« pgoth70_sombre », « enseigne70_taverne », « sym70_cercle_3 »…) ; null si la clé n'est pas
## d'ici. Les matières sont gardées une fois faites (les deux kits partagent les mêmes) : les
## fenêtres allumées et les verres des lanternes sont réglés d'un coup, la nuit (night()).

const S := "res://assets/textures/braise/"
const TEINTES := {
	"": Color(1, 1, 1), "sombre": Color(0.66, 0.64, 0.63), "clair": Color(1.14, 1.12, 1.1), "rouge": Color(1.0, 0.72, 0.66),
	"noir": Color(0.42, 0.4, 0.4), "or": Color(1.06, 0.92, 0.66), "pourpre": Color(0.84, 0.7, 0.92), "cendre": Color(0.88, 0.88, 0.9),
	"chaud": Color(1.06, 0.95, 0.84), "vert": Color(0.75, 0.9, 0.8), "bleu": Color(0.72, 0.82, 1.0),
}
const GLOWS := {
	"feu": Color(1.0, 0.45, 0.12), "rouge": Color(1.0, 0.18, 0.08), "or": Color(1.0, 0.78, 0.35), "bleu": Color(0.45, 0.72, 1.0),
	"vert": Color(0.35, 1.0, 0.55), "blanc": Color(1.0, 0.95, 0.88), "pourpre": Color(0.75, 0.35, 1.0), "givre": Color(0.65, 0.88, 1.0),
}
const CLOTHS := {
	"rouge": Color(0.58, 0.08, 0.06), "noir": Color(0.09, 0.08, 0.08), "or": Color(0.78, 0.58, 0.18), "pourpre": Color(0.34, 0.1, 0.42),
	"vert": Color(0.12, 0.3, 0.2), "bleu": Color(0.12, 0.16, 0.38), "cendre": Color(0.42, 0.4, 0.4),
}
static var _cache: Dictionary = {}


static func _t(name: String) -> Texture2D:
	var p: String = S + name
	return load(p) if ResourceLoader.exists(p) else null


static func _surface(name: String, tint: Color, rough: float, nscale: float = 1.0, tri: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = _t(name + ".png")
	var n: Texture2D = _t(name + "_n.png")
	if n != null:
		m.normal_enabled = true
		m.normal_texture = n
		m.normal_scale = nscale
	m.albedo_color = tint
	m.roughness = rough
	if tri > 0.0:
		m.uv1_triplanar = true
		m.uv1_scale = Vector3.ONE * tri
	return m


static func _panel(name: String, tint: Color = Color(1, 1, 1), alpha: bool = false, glow: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = _t(name + ".png")
	m.albedo_color = tint
	m.roughness = 0.88
	if alpha:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		m.alpha_scissor_threshold = 0.4
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
	if glow > 0.0:
		m.emission_enabled = true
		m.emission_texture = m.albedo_texture
		m.emission = Color(1, 1, 1)
		m.emission_energy_multiplier = glow
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
	if not kind.ends_with("70"):
		return null
	var v: String = parts[1] if parts.size() > 1 else ""
	var tint: Color = TEINTES.get(v, Color(1, 1, 1))
	var m: Material = null
	match kind:
		"pgoth70":
			m = _surface("pierre_gothique", tint, 0.86, 1.1)
		"bnoire70":
			m = _surface("brique_noire", tint, 0.9, 1.1)
		"erouge70":
			m = _surface("enduit_rouge", tint, 0.9, 0.8)
		"mrouge70":
			m = _surface("marbre_rouge", tint, 0.24, 0.5)
		"mnoir70":
			var mn: StandardMaterial3D = _surface("marbre_noir", tint, 0.18, 0.4)
			mn.metallic_specular = 0.7
			m = mn
		"ardoise70":
			m = _surface("ardoise", tint, 0.78, 1.2)
		"tuile70":
			m = _surface("tuiles_rouges", tint, 0.86, 1.2)
		"cuivre70":
			var cu: StandardMaterial3D = _surface("cuivre_vert", tint, 0.55, 0.9)
			cu.metallic = 0.35
			m = cu
		"boisb70":
			m = _surface("bois_brule", tint, 0.9, 1.0)
		"fer70":
			var fe: StandardMaterial3D = _surface("fer_forge", tint, 0.48, 0.8)
			fe.metallic = 0.65
			m = fe
		"palais70":
			var pa: StandardMaterial3D = _surface("dalles_palais", tint, 0.22, 0.4)
			pa.metallic_specular = 0.7
			m = pa
		"mosaique70":
			m = _surface("mosaique_feu", tint, 0.5, 0.6)
		"basalte70":
			m = _surface("basalte", tint, 0.88, 1.2, 0.16)
		"paves70":
			m = _surface("paves_basalte", tint, 0.78, 1.0)
		"abysse70":
			m = _surface("pierre_abyssale", tint, 0.82, 1.2)
		"glace70":
			var gl: StandardMaterial3D = _surface("glace", tint, 0.08, 0.6)
			gl.metallic_specular = 0.9
			gl.emission_enabled = true
			gl.emission = Color(0.35, 0.55, 0.75)
			gl.emission_energy_multiplier = 0.12
			m = gl
		"givre70":
			m = _surface("givre", tint, 0.5, 0.9)
		"boue70":
			m = _surface("boue", tint, 0.55, 1.0)
		"arene70":
			m = _surface("sable_arene", tint, 0.95, 0.8)
		"obsid70":
			var ob: StandardMaterial3D = _surface("obsidienne", tint, 0.1, 0.7)
			ob.metallic_specular = 0.9
			ob.metallic = 0.15
			m = ob
		"soufre70":
			m = _surface("soufre", tint, 0.7, 0.9)
		"cendre70":
			m = _surface("cendre", tint, 0.95, 0.9, 0.2)
		"roche70":
			m = _surface("roche_volcan", tint, 0.9, 1.2, 0.12)
		"sablen70":
			m = _surface("sable_noir", tint, 0.95, 0.8, 0.25)
		"enseigne70":
			m = _panel("enseigne_" + v)
		"fresque70":
			m = _panel("fresque_" + v, Color(0.95, 0.92, 0.88))
		"sym70":
			m = _panel(v, Color(1, 1, 1), true, 1.2)
		"affiche70":
			m = _panel("affiche_" + v)
		"banniere70":
			var bn: StandardMaterial3D = _panel("banniere_pandemonia", Color(1, 1, 1), true)
			m = bn
		"vitrail70":
			# les vitraux : la nuit, la lumière de dedans les traverse
			var vt: StandardMaterial3D = _panel("vitrail_" + v, Color(1, 1, 1), v == "rosace", 0.35)
			vt.roughness = 0.2
			m = vt
		"vitrailin70":
			# un vitrail vu du dedans : la lumière du jour (ou des lampes) le traverse toujours
			var vti: StandardMaterial3D = _panel("vitrail_" + v, Color(1, 1, 1), v == "rosace", 0.9)
			vti.roughness = 0.2
			m = vti
		"fenetre70":
			# les fenêtres allumées (leur lueur monte à la nuit tombée : night())
			var fw: StandardMaterial3D = _panel("fenetre_gothique", Color(1, 1, 1), false, 0.15)
			fw.roughness = 0.25
			m = fw
		"fenetrenoire70":
			var fn: StandardMaterial3D = _panel("fenetre_gothique", Color(0.24, 0.22, 0.24))
			fn.roughness = 0.2
			m = fn
		"plan70":
			m = _panel("plan_ville")
		"contrat70":
			m = _panel("contrat")
		"or70":
			m = _flat(Color(1.0, 0.76, 0.3), 0.26, 0.9)
		"bronze70":
			m = _flat(Color(0.62, 0.42, 0.22), 0.36, 0.8)
		"lueur70":
			m = _glow(GLOWS.get(v, GLOWS["feu"]), 2.6)
		"lave70":
			var lv := ShaderMaterial.new()
			lv.shader = load("res://shaders/lave_v70.gdshader")
			lv.set_shader_parameter("lave_tex", _t("lave.png"))
			lv.set_shader_parameter("croute_tex", _t("lave_croute.png"))
			lv.set_shader_parameter("croute_e", _t("lave_croute_e.png"))
			m = lv
		"vitre70":
			var vi := _flat(Color(0.06, 0.05, 0.07), 0.08, 0.2)
			vi.metallic_specular = 0.9
			m = vi
		"tissu70":
			var ti := _flat(CLOTHS.get(v, CLOTHS["rouge"]), 0.92)
			ti.cull_mode = BaseMaterial3D.CULL_DISABLED
			m = ti
		"cuir70":
			m = _flat(Color(0.24, 0.13, 0.08), 0.62)
		"corne70":
			m = _flat(Color(0.86, 0.8, 0.68), 0.45)
		"cristal70":
			var cr := _glow(Color(1.0, 0.88, 0.25), 0.6)
			cr.roughness = 0.15
			m = cr
		"verre70":
			# le verre des lanternes : une lueur chaude, plus forte la nuit (night())
			var lg := _glow(Color(1.0, 0.66, 0.3), 1.0)
			lg.albedo_color = Color(1.0, 0.8, 0.5)
			m = lg
		"braise70":
			m = _glow(Color(1.0, 0.35, 0.08), 2.2)
		"eau70":
			var ea := StandardMaterial3D.new()
			ea.albedo_color = Color(0.78, 0.7, 0.32, 0.82)
			ea.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			ea.roughness = 0.12
			ea.metallic_specular = 0.8
			ea.normal_enabled = true
			ea.normal_texture = load("res://assets/textures/water/water_n.png")
			ea.normal_scale = 0.4
			m = ea
	if m != null:
		_cache[key] = m
	return m


## La nuit tombe (k = 1) ou le jour se lève (k = 0) : les fenêtres et les lanternes s'allument.
static func night(k: float) -> void:
	var fw: StandardMaterial3D = make("fenetre70") as StandardMaterial3D
	if fw != null:
		fw.emission_energy_multiplier = lerpf(0.15, 2.4, k)
	var vt: StandardMaterial3D = make("vitrail70_rosace") as StandardMaterial3D
	if vt != null:
		vt.emission_energy_multiplier = lerpf(0.35, 1.8, k)
	var vl: StandardMaterial3D = make("vitrail70_lancette") as StandardMaterial3D
	if vl != null:
		vl.emission_energy_multiplier = lerpf(0.35, 1.8, k)
	var lg: StandardMaterial3D = make("verre70") as StandardMaterial3D
	if lg != null:
		lg.emission_energy_multiplier = lerpf(0.6, 3.4, k)
