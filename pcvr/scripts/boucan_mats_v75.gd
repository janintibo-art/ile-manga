extends RefCounted
## V75 : les matières de l'Île du Boucan (Port-Boucan, la ville-friche des punks), partagées par le
## kit de la ville (boucan_kit_v75.gd), le dehors et la végétation. Une clé « genre75_variante »
## (« brique75_suie », « tolep75_bleu », « fresque75_3 », « enseigne75_halle »…) ; null si la clé n'est
## pas d'ici. Les matières sont gardées une fois faites ; les fenêtres allumées, les néons, les
## chapeaux des champignons géants montent à la nuit tombée (night()).
## Si une texture manque, la matière garde une couleur plausible (la teinte de base).

const S := "res://assets/textures/boucan/"
## Les peintures : les briques peintes, les tôles, les conteneurs, les volets…
const PEINTURES := {
	"": Color(1, 1, 1), "rouge": Color(0.78, 0.2, 0.16), "bleu": Color(0.22, 0.42, 0.72), "vert": Color(0.26, 0.56, 0.32),
	"jaune": Color(0.95, 0.76, 0.2), "orange": Color(0.92, 0.46, 0.14), "blanc": Color(0.94, 0.93, 0.9), "gris": Color(0.58, 0.6, 0.62),
	"rose": Color(0.94, 0.5, 0.66), "violet": Color(0.5, 0.32, 0.66), "turquoise": Color(0.2, 0.66, 0.66), "noir": Color(0.14, 0.14, 0.15),
	"creme": Color(0.93, 0.87, 0.72), "brun": Color(0.45, 0.3, 0.2), "kaki": Color(0.46, 0.48, 0.3),
}
const TEINTES := {
	"": Color(1, 1, 1), "sombre": Color(0.66, 0.64, 0.62), "clair": Color(1.12, 1.1, 1.08), "suie": Color(0.55, 0.5, 0.48),
	"vieux": Color(0.86, 0.8, 0.72), "chaud": Color(1.06, 0.96, 0.86), "mousse": Color(0.82, 0.92, 0.76),
}
## Les champignons géants : la couleur de la lueur de leurs chapeaux.
const LUEURS := {"bleu": Color(0.3, 0.7, 1.0), "violet": Color(0.72, 0.4, 1.0), "orange": Color(1.0, 0.56, 0.2)}
const NEONS := {"rose": Color(1.0, 0.3, 0.7), "bleu": Color(0.3, 0.6, 1.0), "vert": Color(0.3, 1.0, 0.5), "rouge": Color(1.0, 0.2, 0.15),
	"jaune": Color(1.0, 0.85, 0.3), "blanc": Color(1.0, 0.97, 0.9), "violet": Color(0.66, 0.36, 1.0)}
static var _cache: Dictionary = {}


static func _t(name: String) -> Texture2D:
	var p: String = S + name
	return load(p) if ResourceLoader.exists(p) else null


static func _surface(name: String, tint: Color, rough: float, nscale: float = 1.0, tri: float = 0.0, base := Color(0.7, 0.68, 0.64), metal: float = 0.0) -> StandardMaterial3D:
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
	m.metallic = metal
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
		m.alpha_scissor_threshold = 0.35
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
	if not kind.ends_with("75"):
		return null
	var v: String = parts[1] if parts.size() > 1 else ""
	var tint: Color = TEINTES.get(v, Color(1, 1, 1))
	var paint: Color = PEINTURES.get(v, Color(1, 1, 1))
	var m: Material = null
	match kind:
		"brique75":
			m = _surface("brique", tint, 0.9, 1.1, 0.0, Color(0.56, 0.28, 0.2))
		"briquep75":
			# la brique peinte (blanchie, puis teintée)
			m = _surface("brique_peinte", paint, 0.9, 1.0, 0.0, Color(0.86, 0.84, 0.8))
		"beton75":
			m = _surface("beton_brut", tint, 0.92, 1.0, 0.0, Color(0.62, 0.62, 0.6))
		"tole75":
			m = _surface("tole_rouille", tint, 0.78, 1.2, 0.0, Color(0.46, 0.28, 0.18), 0.35)
		"tolep75":
			m = _surface("tole_peinte", paint, 0.62, 1.1, 0.0, Color(0.7, 0.7, 0.7), 0.3)
		"bardage75":
			m = _surface("bardage", tint, 0.86, 0.9, 0.0, Color(0.55, 0.42, 0.3))
		"acier75":
			m = _surface("acier_rouille", tint, 0.66, 1.0, 0.0, Color(0.4, 0.26, 0.18), 0.55)
		"rivete75":
			m = _surface("metal_rivete", paint if PEINTURES.has(v) and v != "" else tint, 0.55, 1.0, 0.0, Color(0.42, 0.44, 0.46), 0.6)
		"carrelage75":
			m = _surface("carrelage_usine", tint, 0.32, 0.8, 0.0, Color(0.9, 0.9, 0.86))
		"pavesp75":
			m = _surface("paves_port", tint, 0.8, 1.0, 0.0, Color(0.5, 0.5, 0.5))
		"coque75":
			m = _surface("coque_cargo", tint, 0.7, 1.1, 0.0, Color(0.55, 0.16, 0.12), 0.4)
		"betonsol75":
			m = _surface("beton", tint, 0.9, 1.0, 0.0, Color(0.6, 0.6, 0.58))
		"asphalte75":
			m = _surface("asphalte", tint, 0.86, 1.0, 0.0, Color(0.22, 0.22, 0.23))
		"fresque75":
			m = _panel("fresque_" + v)
		"graffiti75":
			var gr: StandardMaterial3D = _panel("graffiti_" + v, Color(1, 1, 1), true)
			gr.roughness = 0.7
			m = gr
		"affiche75":
			var af: StandardMaterial3D = _panel("affiche_concert_" + v)
			af.cull_mode = BaseMaterial3D.CULL_DISABLED
			m = af
		"panneau75":
			m = _panel("panneau_" + v)
		"enseigne75":
			m = _panel("enseigne_" + v, Color(1, 1, 1), true)
		"fanzine75":
			m = _panel("fanzine_couverture")
		"chapeau75":
			# le dessus des chapeaux des champignons géants : il luit (plus fort la nuit : night())
			var ch: StandardMaterial3D = _surface("chapeau_" + v, Color(1, 1, 1), 0.55, 0.8, 0.0, LUEURS.get(v, Color(0.5, 0.6, 1.0)))
			ch.emission_enabled = true
			ch.emission_texture = ch.albedo_texture
			ch.emission = LUEURS.get(v, Color(0.5, 0.6, 1.0))
			ch.emission_energy_multiplier = 0.25
			ch.rim_enabled = true
			ch.rim = 0.4
			m = ch
		"lamelles75":
			var la: StandardMaterial3D = _surface("lamelles", Color(1, 1, 1), 0.8, 0.8, 0.0, Color(0.85, 0.82, 0.74))
			la.emission_enabled = true
			la.emission_texture = la.albedo_texture
			la.emission = LUEURS.get(v, Color(0.6, 0.8, 1.0))
			la.emission_energy_multiplier = 0.15
			la.cull_mode = BaseMaterial3D.CULL_DISABLED
			m = la
		"pied75":
			var pi: StandardMaterial3D = _surface("pied_champi", Color(1, 1, 1), 0.72, 0.8, 0.0, Color(0.88, 0.86, 0.8))
			pi.subsurf_scatter_enabled = true
			pi.subsurf_scatter_strength = 0.3
			m = pi
		"vitre75":
			# « on » : une fenêtre où il y a de la lumière (night()) ; « off » : une vitre sombre ;
			# « usine » : le verre dépoli des verrières (on voit le ciel au travers, un peu)
			if v == "on":
				var vo := _flat(Color(0.32, 0.3, 0.26), 0.16)
				vo.emission_enabled = true
				vo.emission = Color(1.0, 0.78, 0.48)
				vo.emission_energy_multiplier = 0.04
				vo.metallic_specular = 0.8
				m = vo
			elif v == "usine":
				var vu := _flat(Color(0.7, 0.78, 0.76, 0.42), 0.3)
				vu.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				vu.cull_mode = BaseMaterial3D.CULL_DISABLED
				vu.metallic_specular = 0.7
				m = vu
			else:
				var vf := _flat(Color(0.2, 0.24, 0.27), 0.12)
				vf.metallic_specular = 0.9
				m = vf
		"neon75":
			m = _glow(NEONS.get(v, NEONS["blanc"]), 2.6)
		"peint75":
			# une peinture lisse (les volets, les portes, le mobilier)
			m = _flat(paint, 0.6)
		"metal75":
			m = _flat(Color(0.5, 0.52, 0.54) * (paint if v != "" else Color(1, 1, 1)), 0.4, 0.75)
		"caoutchouc75":
			m = _flat(Color(0.07, 0.07, 0.07), 0.9)
		"palette75":
			m = _surface("bardage", Color(1.18, 1.1, 0.96), 0.88, 0.8, 0.0, Color(0.72, 0.6, 0.42))
		"tissu75":
			var ti := _flat(PEINTURES.get(v, PEINTURES["rouge"]), 0.92)
			ti.cull_mode = BaseMaterial3D.CULL_DISABLED
			m = ti
		"feuille75":
			m = _flat(Color(0.24, 0.42, 0.16), 0.8)
		"terre75":
			m = _flat(Color(0.24, 0.18, 0.13), 0.96)
		"chrome75":
			m = _flat(Color(0.86, 0.86, 0.88), 0.18, 0.95)
		"lampe75":
			# une ampoule (guirlandes, projecteurs, lampes)
			var lp := _glow(Color(1.0, 0.82, 0.55), 1.2)
			m = lp
		"spore75":
			var sp := _glow(LUEURS.get(v, LUEURS["bleu"]), 3.0)
			sp.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			sp.albedo_color = Color(LUEURS.get(v, LUEURS["bleu"]), 0.8)
			sp.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			m = sp
	if m != null:
		_cache[key] = m
	return m


## La nuit tombe (k = 1) ou le jour se lève (k = 0).
static func night(k: float) -> void:
	var fw: StandardMaterial3D = make("vitre75_on") as StandardMaterial3D
	if fw != null:
		fw.emission_energy_multiplier = lerpf(0.04, 2.2, k)
	for c in LUEURS:
		var ch: StandardMaterial3D = make("chapeau75_" + str(c)) as StandardMaterial3D
		if ch != null:
			ch.emission_energy_multiplier = lerpf(0.25, 1.6, k)
		var la: StandardMaterial3D = make("lamelles75_" + str(c)) as StandardMaterial3D
		if la != null:
			la.emission_energy_multiplier = lerpf(0.15, 1.2, k)
