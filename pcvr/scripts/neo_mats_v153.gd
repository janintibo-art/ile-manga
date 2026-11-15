extends RefCounted
## V153 : les matières des intérieurs des tours de Néopolis (les clés « in_… » de neo_kit_v94.mat) :
## les sols (le terrazzo des halls, la moquette des bureaux, le parquet des appartements, le béton
## ciré), les murs (la peinture claire, le béton, le bois des accueils), les vitres (des fenêtres, des
## cloisons des salles de réunion), les bureaux, les écrans qui brillent, les plafonniers, les plantes.
## Les textures sont faites ici (du bruit) quand le jeu n'en a pas.

static var _cache: Dictionary = {}


static func _bruit(couleur: Color, ecart: float, freq: float, graine: int) -> NoiseTexture2D:
	var n := FastNoiseLite.new()
	n.seed = graine
	n.frequency = freq
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX
	var g := Gradient.new()
	g.set_color(0, couleur.darkened(ecart))
	g.set_color(1, couleur.lightened(ecart))
	var t := NoiseTexture2D.new()
	t.width = 256
	t.height = 256
	t.seamless = true
	t.noise = n
	t.color_ramp = g
	t.generate_mipmaps = true
	return t


static func _std(c: Color, rough: float, metal: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	return m


static func _tex(path: String, tint: Color, rough: float, echelle: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	if ResourceLoader.exists(path):
		m.albedo_texture = load(path)
	m.albedo_color = tint
	m.roughness = rough
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE * echelle
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return m


static func _bruite(c: Color, ecart: float, freq: float, graine: int, rough: float, echelle: float) -> StandardMaterial3D:
	var m := _std(Color.WHITE, rough)
	m.albedo_texture = _bruit(c, ecart, freq, graine)
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE * echelle
	return m


static func _glow(c: Color, e: float) -> StandardMaterial3D:
	var m := _std(c * 0.4, 0.4)
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = e
	return m


static func mat(key: String) -> Material:
	if _cache.has(key):
		return _cache[key]
	var m: Material
	match key:
		"in_terrazzo":
			m = _tex("res://assets/textures/dome115/terrazzo.png", Color(0.92, 0.92, 0.94), 0.25, 0.35)
		"in_marbre_noir":
			m = _bruite(Color(0.07, 0.07, 0.08), 0.5, 0.05, 11, 0.12, 0.2)
		"in_moquette":
			m = _bruite(Color(0.24, 0.27, 0.32), 0.25, 0.4, 3, 0.95, 0.5)
		"in_moquette_bleue":
			m = _bruite(Color(0.12, 0.2, 0.34), 0.25, 0.4, 5, 0.95, 0.5)
		"in_parquet":
			m = _tex("res://assets/textures/maisons/parquet_chevron_clair.png", Color(0.95, 0.9, 0.85), 0.5, 0.45)
		"in_beton_cire":
			m = _bruite(Color(0.55, 0.55, 0.56), 0.18, 0.08, 7, 0.4, 0.15)
		"in_mur":
			m = _bruite(Color(0.86, 0.87, 0.88), 0.05, 0.2, 13, 0.8, 0.3)
		"in_mur_gris":
			m = _bruite(Color(0.42, 0.44, 0.47), 0.08, 0.2, 17, 0.75, 0.3)
		"in_mur_couloir":
			m = _bruite(Color(0.7, 0.68, 0.64), 0.06, 0.2, 19, 0.8, 0.3)
		"in_plafond":
			var pl := _std(Color(0.93, 0.93, 0.92), 0.9)
			pl.emission_enabled = true
			pl.emission = Color(0.9, 0.9, 0.88)
			pl.emission_energy_multiplier = 0.45
			m = pl
		"in_sol_technique":
			m = _bruite(Color(0.3, 0.32, 0.35), 0.1, 0.6, 41, 0.6, 0.6)
		"in_plafonnier":
			m = _glow(Color(0.95, 0.97, 1.0), 2.2)
		"in_plafonnier_chaud":
			m = _glow(Color(1.0, 0.85, 0.65), 1.8)
		"in_vitre":
			var v := _std(Color(0.55, 0.7, 0.8, 0.18), 0.03, 0.4)
			v.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			v.cull_mode = BaseMaterial3D.CULL_DISABLED
			m = v
		"in_cloison_verre":
			var cv := _std(Color(0.75, 0.88, 0.95, 0.12), 0.02, 0.2)
			cv.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			cv.cull_mode = BaseMaterial3D.CULL_DISABLED
			m = cv
		"in_menuiserie":
			m = _std(Color(0.12, 0.13, 0.15), 0.4, 0.6)
		"in_bureau":
			m = _std(Color(0.93, 0.93, 0.92), 0.35)
		"in_bois":
			m = _bruite(Color(0.45, 0.3, 0.18), 0.2, 0.9, 23, 0.5, 0.8)
		"in_bois_clair":
			m = _bruite(Color(0.78, 0.66, 0.5), 0.15, 0.9, 29, 0.5, 0.8)
		"in_noir":
			m = _std(Color(0.05, 0.05, 0.06), 0.4)
		"in_chaise":
			m = _std(Color(0.12, 0.12, 0.14), 0.6)
		"in_tissu_gris":
			m = _std(Color(0.4, 0.42, 0.46), 0.95)
		"in_tissu_rouge":
			m = _std(Color(0.6, 0.12, 0.14), 0.9)
		"in_cuir":
			m = _std(Color(0.1, 0.08, 0.07), 0.45)
		"in_inox":
			m = _std(Color(0.78, 0.8, 0.82), 0.25, 0.9)
		"in_ecran":
			m = _glow(Color(0.35, 0.65, 1.0), 1.4)
		"in_ecran_vert":
			m = _glow(Color(0.3, 1.0, 0.55), 1.2)
		"in_ecran_rose":
			m = _glow(Color(1.0, 0.35, 0.8), 1.4)
		"in_led_bleue":
			m = _glow(Color(0.2, 0.55, 1.0), 4.0)
		"in_led_verte":
			m = _glow(Color(0.2, 1.0, 0.4), 4.0)
		"in_led_ambre":
			m = _glow(Color(1.0, 0.6, 0.1), 4.0)
		"in_feuille":
			m = _std(Color(0.18, 0.42, 0.2), 0.8)
		"in_pot":
			m = _std(Color(0.85, 0.85, 0.83), 0.5)
		"in_terre":
			m = _std(Color(0.22, 0.15, 0.1), 0.95)
		"in_ascenseur":
			m = _std(Color(0.7, 0.72, 0.75), 0.18, 0.95)
		"in_porte":
			m = _bruite(Color(0.3, 0.32, 0.36), 0.08, 0.3, 31, 0.5, 0.4)
		"in_porte_bois":
			m = _bruite(Color(0.42, 0.27, 0.16), 0.15, 0.9, 37, 0.5, 0.8)
		"in_baie":
			m = _std(Color(0.2, 0.22, 0.25), 0.3, 0.8)
		"in_neon_accueil":
			m = _glow(Color(0.15, 0.85, 1.0), 3.0)
		"in_neon_rose":
			m = _glow(Color(1.0, 0.2, 0.7), 3.0)
		"in_rack":
			m = _std(Color(0.18, 0.19, 0.21), 0.35, 0.7)
		_:
			m = _std(Color(0.6, 0.6, 0.6), 0.6)
	_cache[key] = m
	return m
