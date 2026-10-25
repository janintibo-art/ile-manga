extends RefCounted
## V71 : les matières de l'Île de Montjoie, la ville des aventuriers, partagées par le kit de la
## ville (montjoie_kit_v71.gd), le dehors et le Donjon des Mille Marches. Une clé
## « genre71_variante » (« enduit71_ocre », « tuiles71_ardoise », « enseigne71_guilde »…) ; null si
## la clé n'est pas d'ici. Les matières sont gardées une fois faites ; les fenêtres allumées, les
## vitraux et les verres des lanternes montent à la nuit tombée (night(), temps_v56).
## Si une texture manque, la matière garde une couleur plausible (la teinte de base).

const S := "res://assets/textures/montjoie/"
## Les teintes des enduits : la ville est colorée (crème, ocre, rose, bleu pâle, vert d'eau, blanc).
const ENDUITS := {
	"": Color(1.0, 0.97, 0.9), "creme": Color(1.0, 0.95, 0.82), "ocre": Color(1.0, 0.84, 0.6), "rose": Color(1.0, 0.82, 0.78),
	"bleu": Color(0.84, 0.9, 1.0), "vert": Color(0.84, 0.95, 0.84), "blanc": Color(1.06, 1.05, 1.02), "gris": Color(0.82, 0.82, 0.8),
	"jaune": Color(1.04, 0.95, 0.66), "saumon": Color(1.0, 0.78, 0.66),
}
const TOITS := {
	"": Color(1, 1, 1), "rouge": Color(1.0, 0.86, 0.82), "orange": Color(1.1, 0.9, 0.7), "brun": Color(0.74, 0.62, 0.55),
	"ardoise": Color(0.5, 0.56, 0.66), "vert": Color(0.62, 0.78, 0.66), "sombre": Color(0.66, 0.6, 0.58),
}
const TEINTES := {
	"": Color(1, 1, 1), "sombre": Color(0.66, 0.65, 0.63), "clair": Color(1.12, 1.1, 1.08), "mousse": Color(0.8, 0.9, 0.74),
	"chaud": Color(1.06, 0.97, 0.86), "vieux": Color(0.86, 0.82, 0.74),
}
const CLOTHS := {
	"rouge": Color(0.62, 0.1, 0.08), "bleu": Color(0.12, 0.22, 0.52), "vert": Color(0.16, 0.38, 0.18), "jaune": Color(0.86, 0.64, 0.14),
	"blanc": Color(0.9, 0.88, 0.82), "brun": Color(0.36, 0.24, 0.14), "violet": Color(0.36, 0.16, 0.44), "orange": Color(0.88, 0.42, 0.12),
}
const VOLETS := {"rouge": Color(0.55, 0.12, 0.1), "vert": Color(0.18, 0.36, 0.2), "bleu": Color(0.2, 0.32, 0.55), "brun": Color(0.32, 0.2, 0.12), "jaune": Color(0.78, 0.6, 0.18)}
const FLEURS := {"rouge": Color(0.85, 0.12, 0.12), "rose": Color(0.95, 0.45, 0.62), "jaune": Color(0.98, 0.82, 0.18), "blanc": Color(0.96, 0.95, 0.9), "violet": Color(0.55, 0.32, 0.8)}
static var _cache: Dictionary = {}


static func _t(name: String) -> Texture2D:
	var p: String = S + name
	return load(p) if ResourceLoader.exists(p) else null


static func _surface(name: String, tint: Color, rough: float, nscale: float = 1.0, tri: float = 0.0, base := Color(0.7, 0.68, 0.64)) -> StandardMaterial3D:
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
	if tri > 0.0:
		m.uv1_triplanar = true
		m.uv1_scale = Vector3.ONE * tri
	return m


static func _panel(name: String, tint: Color = Color(1, 1, 1), alpha: bool = false, glow: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = _t(name + ".png")
	m.albedo_color = tint
	m.roughness = 0.86
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
	if not kind.ends_with("71"):
		return null
	var v: String = parts[1] if parts.size() > 1 else ""
	var tint: Color = TEINTES.get(v, Color(1, 1, 1))
	var m: Material = null
	match kind:
		"enduit71":
			m = _surface("enduit", ENDUITS.get(v, ENDUITS[""]), 0.92, 0.7, 0.0, Color(0.86, 0.82, 0.74))
		"poutre71":
			# les pans de bois : du chêne vieilli, presque noir, ou plus clair (« clair »)
			var po: StandardMaterial3D = _surface("bois_planches", Color(0.42, 0.3, 0.22) if v != "clair" else Color(0.7, 0.54, 0.38), 0.86, 0.8, 0.0, Color(0.6, 0.45, 0.32))
			m = po
		"moellons71":
			m = _surface("moellons", tint, 0.9, 1.1, 0.0, Color(0.62, 0.58, 0.52))
		"rempart71":
			m = _surface("pierre_rempart", tint, 0.9, 1.2, 0.0, Color(0.6, 0.58, 0.54))
		"tuiles71":
			m = _surface("tuiles", TOITS.get(v, TOITS[""]), 0.82, 1.2, 0.0, Color(0.66, 0.3, 0.2))
		"chaume71":
			m = _surface("chaume", tint, 0.96, 1.2, 0.0, Color(0.62, 0.5, 0.3))
		"planches71":
			m = _surface("bois_planches", tint, 0.84, 0.9, 0.0, Color(0.55, 0.4, 0.28))
		"paves71":
			m = _surface("paves", tint, 0.78, 1.0, 0.0, Color(0.55, 0.53, 0.5))
		"dalles71":
			m = _surface("dalles", tint, 0.72, 0.8, 0.0, Color(0.74, 0.72, 0.66))
		"colombage71":
			m = _surface("colombage_motif", tint, 0.92, 0.8, 0.0, Color(0.84, 0.8, 0.72))
		"donjon71":
			m = _surface("pierre_donjon", tint, 0.9, 1.2, 0.0, Color(0.5, 0.48, 0.45))
		"dallesd71":
			m = _surface("dalles_donjon", tint, 0.8, 1.0, 0.0, Color(0.46, 0.44, 0.42))
		"moussed71":
			m = _surface("mousse_donjon", tint, 0.95, 1.0, 0.0, Color(0.32, 0.4, 0.26))
		"roche71":
			m = _surface("roche_crocs", tint, 0.9, 1.2, 0.14, Color(0.56, 0.52, 0.46))
		"gelee71":
			var ge: StandardMaterial3D = _surface("gelee", Color(0.7, 1.0, 0.6, 0.86), 0.12, 0.6, 0.0, Color(0.4, 0.85, 0.35))
			ge.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			ge.metallic_specular = 0.9
			ge.emission_enabled = true
			ge.emission = Color(0.25, 0.7, 0.2)
			ge.emission_energy_multiplier = 0.25
			m = ge
		"vitre71":
			# « on » : une fenêtre où il y a de la lumière (elle s'allume à la nuit : night()) ;
			# « off » : une vitre sombre, qui reflète le ciel
			if v == "on":
				var vo: StandardMaterial3D = _panel("fenetre_plomb", Color(1, 1, 1), false, 0.0)
				vo.emission_enabled = true
				var nt: Texture2D = _t("fenetre_plomb_nuit.png")
				vo.emission_texture = nt if nt != null else vo.albedo_texture
				vo.emission = Color(1.0, 0.78, 0.45)
				vo.emission_energy_multiplier = 0.05
				vo.roughness = 0.18
				vo.metallic_specular = 0.8
				m = vo
			else:
				var vf: StandardMaterial3D = _panel("fenetre_plomb", Color(0.62, 0.66, 0.72))
				vf.roughness = 0.14
				vf.metallic_specular = 0.9
				m = vf
		"vitrail71":
			var vt: StandardMaterial3D = _panel("vitrail_aube", Color(1, 1, 1), false, 0.3)
			vt.roughness = 0.2
			m = vt
		"vitrailin71":
			var vti: StandardMaterial3D = _panel("vitrail_aube", Color(1, 1, 1), false, 0.9)
			vti.roughness = 0.2
			m = vti
		"enseigne71":
			m = _panel("enseigne_" + v, Color(1, 1, 1), true)
		"affiche71":
			var af: StandardMaterial3D = _panel("affiche_" + v)
			af.cull_mode = BaseMaterial3D.CULL_DISABLED
			m = af
		"liege71":
			m = _panel("tableau_liege")
		"banniere71":
			var bn: StandardMaterial3D = _panel("banniere_montjoie", Color(1, 1, 1), true)
			if bn.albedo_texture == null:
				bn.albedo_color = Color(0.14, 0.26, 0.6)
			m = bn
		"blason71":
			var bl: StandardMaterial3D = _panel("blason_guilde", Color(1, 1, 1), true)
			m = bl
		"tissu71":
			var ti := _flat(CLOTHS.get(v, CLOTHS["rouge"]), 0.92)
			ti.cull_mode = BaseMaterial3D.CULL_DISABLED
			m = ti
		"volet71":
			m = _flat(VOLETS.get(v, VOLETS["vert"]), 0.78)
		"fleur71":
			m = _flat(FLEURS.get(v, FLEURS["rouge"]), 0.7)
		"feuille71":
			m = _flat(Color(0.2, 0.4, 0.14), 0.8)
		"fer71":
			m = _flat(Color(0.12, 0.12, 0.13), 0.45, 0.7)
		"laiton71":
			m = _flat(Color(0.78, 0.6, 0.3), 0.32, 0.85)
		"or71":
			m = _flat(Color(1.0, 0.78, 0.32), 0.26, 0.9)
		"cuir71":
			m = _flat(Color(0.36, 0.22, 0.12), 0.62)
		"terre71":
			m = _flat(Color(0.36, 0.26, 0.17), 0.95)
		"foin71":
			m = _flat(Color(0.82, 0.68, 0.36), 0.95)
		"verre71":
			# le verre des lanternes : une lueur chaude, plus forte la nuit (night())
			var lg := _glow(Color(1.0, 0.74, 0.4), 0.4)
			lg.albedo_color = Color(1.0, 0.86, 0.6)
			m = lg
		"cristal71":
			var cr := _glow(Color(0.5, 0.8, 1.0), 1.4)
			cr.roughness = 0.1
			cr.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			cr.albedo_color = Color(0.6, 0.85, 1.0, 0.75)
			m = cr
		"orage71":
			var og := _glow(Color(0.65, 0.55, 1.0), 2.4)
			og.roughness = 0.1
			m = og
		"eau71":
			var ea := StandardMaterial3D.new()
			ea.albedo_color = Color(0.22, 0.36, 0.34, 0.78) if v != "claire" else Color(0.5, 0.66, 0.72, 0.6)
			ea.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			ea.roughness = 0.06
			ea.metallic_specular = 0.9
			ea.normal_enabled = true
			ea.normal_texture = load("res://assets/textures/water/water_n.png") if ResourceLoader.exists("res://assets/textures/water/water_n.png") else null
			ea.normal_scale = 0.35
			ea.uv1_scale = Vector3(0.12, 0.12, 0.12)
			m = ea
	if m != null:
		_cache[key] = m
	return m


## La nuit tombe (k = 1) ou le jour se lève (k = 0) : les fenêtres et les lanternes s'allument.
static func night(k: float) -> void:
	var fw: StandardMaterial3D = make("vitre71_on") as StandardMaterial3D
	if fw != null:
		fw.emission_energy_multiplier = lerpf(0.05, 2.2, k)
	var vt: StandardMaterial3D = make("vitrail71") as StandardMaterial3D
	if vt != null:
		vt.emission_energy_multiplier = lerpf(0.3, 1.6, k)
	var lg: StandardMaterial3D = make("verre71") as StandardMaterial3D
	if lg != null:
		lg.emission_energy_multiplier = lerpf(0.4, 3.2, k)
