extends RefCounted
## V115 : les matières du Dôme d'Azur (au fond de la mer, futuriste et lumineux) : le verre des dômes
## et des tubes (verre_abysse_v115 : l'eau profonde derrière lui), la nacre (les façades blanches,
## satinées, au reflet perlé ; rose ou aigue-marine), le terrazzo du sol (des éclats de coquillages
## dans un béton blanc poli), le titane brossé des résilles et des pylônes, les diodes (aigue-marine,
## ambre, rose, violet, blanc), la Grande Perle, l'eau qui luit (la Fontaine des Bulles, les cuves), le
## mur des algues, les lampes de culture, les coraux et la vie du fond (éponges de verre, anémones, lys
## de mer, gorgones, vers géants), le bathyscaphe jaune, les hublots, les enseignes. Une clé
## « genre115_variante » ; null si la clé n'est pas d'ici. Gardées une fois faites.

const S := "res://assets/textures/dome115/"
const SN := "res://assets/textures/nuees/"
const VERRE := "res://shaders/verre_abysse_v115.gdshader"
static var _cache: Dictionary = {}
static var facade: StandardMaterial3D = null      # la copie de la façade des tours (dome_kit_v115)


static func _t(path: String) -> Texture2D:
	return load(path) if ResourceLoader.exists(path) else null


static func _metal(c: Color, rough: float, metal: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	m.metallic_specular = 0.6
	return m


static func _glow(c: Color, energy: float, albedo := Color(-1, 0, 0)) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = albedo if albedo.r >= 0.0 else c.lerp(Color(1, 1, 1), 0.35)
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	m.roughness = 0.35
	return m


const LED := {"cyan": Color(0.35, 0.95, 1.0), "ambre": Color(1.0, 0.72, 0.38), "rose": Color(1.0, 0.45, 0.72), "violet": Color(0.62, 0.42, 1.0),
	"blanc": Color(0.92, 0.97, 1.0), "vert": Color(0.4, 1.0, 0.6)}
const CORAIL := {"rose": Color(1.0, 0.4, 0.62), "orange": Color(1.0, 0.55, 0.25), "violet": Color(0.7, 0.4, 1.0), "cyan": Color(0.3, 0.9, 1.0),
	"jaune": Color(1.0, 0.85, 0.3), "blanc": Color(0.9, 0.95, 1.0)}


static func make(key: String) -> Material:
	if _cache.has(key):
		return _cache[key]
	var parts: PackedStringArray = key.split("_", true, 1)
	var kind: String = parts[0]
	if not kind.ends_with("115"):
		return null
	var v: String = parts[1] if parts.size() > 1 else ""
	var m: Material = null
	match kind:
		"verre115":
			var sm := ShaderMaterial.new()
			sm.shader = load(VERRE)
			sm.render_priority = 1
			sm.set_shader_parameter("caustic_tex", _t("res://assets/textures/mer/caustiques.png"))
			m = sm
		"nacre115":
			# la nacre : un panneau blanc satiné (les joints du composite), un reflet perlé sur les bords
			var na := StandardMaterial3D.new()
			na.albedo_texture = _t(SN + "composite.png")
			var tint: Color = {"": Color(0.97, 0.96, 0.94), "rose": Color(0.98, 0.86, 0.84), "bleu": Color(0.82, 0.93, 0.95), "sable": Color(0.93, 0.88, 0.8),
				"gris": Color(0.78, 0.8, 0.82)}.get(v, Color(0.97, 0.96, 0.94))
			na.albedo_color = tint if na.albedo_texture != null else tint * 0.92
			var nn: Texture2D = _t(SN + "composite_n.png")
			if nn != null:
				na.normal_enabled = true
				na.normal_texture = nn
				na.normal_scale = 0.6
			na.roughness = 0.24
			na.metallic = 0.04
			na.clearcoat_enabled = true
			na.clearcoat = 0.55
			na.clearcoat_roughness = 0.2
			na.rim_enabled = true
			na.rim = 0.35
			na.rim_tint = 0.65
			m = na
		"terrazzo115":
			var te := StandardMaterial3D.new()
			te.albedo_texture = _t(S + "terrazzo.png")
			te.albedo_color = Color(1, 1, 1) if te.albedo_texture != null else Color(0.86, 0.87, 0.86)
			var tn: Texture2D = _t(S + "terrazzo_n.png")
			if tn != null:
				te.normal_enabled = true
				te.normal_texture = tn
				te.normal_scale = 0.5
			te.roughness = 0.3 if v != "mat" else 0.6
			te.metallic_specular = 0.7
			if v == "bleu":
				te.albedo_color = Color(0.72, 0.84, 0.9)
			m = te
		"titane115":
			m = _metal(Color(0.66, 0.69, 0.72) if v == "" else (Color(0.3, 0.32, 0.35) if v == "sombre" else Color(0.86, 0.88, 0.9)), 0.3, 0.92)
		"joint115":
			var jo := StandardMaterial3D.new()
			jo.albedo_color = Color(0.12, 0.13, 0.14)
			jo.roughness = 0.7
			m = jo
		"led115":
			m = _glow(LED.get(v, LED["blanc"]), 1.2)
		"perle115":
			# la Grande Perle : une nacre qui luit (blanc doré le jour, bleu nuit et violet le soir)
			var pe := StandardMaterial3D.new()
			pe.albedo_color = Color(1.0, 0.98, 0.95)
			pe.emission_enabled = true
			pe.emission = Color(1.0, 0.95, 0.85)
			pe.emission_energy_multiplier = 5.0
			pe.roughness = 0.15
			pe.rim_enabled = true
			pe.rim = 0.6
			pe.rim_tint = 0.3
			m = pe
		"eau115":
			# l'eau qui luit (la Fontaine des Bulles, les cuves de l'Aquarium, le bassin des Serres)
			var ea := StandardMaterial3D.new()
			ea.albedo_color = {"": Color(0.3, 0.75, 0.85, 0.55), "aquarium": Color(0.16, 0.45, 0.6, 0.3), "bassin": Color(0.2, 0.4, 0.38, 0.75),
				"puits": Color(0.03, 0.14, 0.22, 0.9)}.get(v, Color(0.3, 0.75, 0.85, 0.55))
			ea.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			ea.cull_mode = BaseMaterial3D.CULL_DISABLED
			ea.roughness = 0.04
			ea.metallic_specular = 1.0
			ea.emission_enabled = true
			ea.emission = {"": Color(0.25, 0.8, 0.95), "aquarium": Color(0.1, 0.35, 0.6), "bassin": Color(0.1, 0.25, 0.2), "puits": Color(0.0, 0.12, 0.25)}.get(v, Color(0.25, 0.8, 0.95))
			ea.emission_energy_multiplier = {"": 0.9, "aquarium": 0.25, "bassin": 0.15, "puits": 0.35}.get(v, 0.9)
			var wn: Texture2D = _t("res://assets/textures/water/water_n.png")
			if wn != null and v != "aquarium":
				ea.normal_enabled = true
				ea.normal_texture = wn
				ea.normal_scale = 0.35
				ea.uv1_scale = Vector3(0.2, 0.2, 0.2)
			m = ea
		"bulle115":
			var bu := StandardMaterial3D.new()
			bu.albedo_texture = _t("res://assets/textures/mer/bulle.png")
			bu.albedo_color = Color(0.85, 0.97, 1.0, 0.7)
			bu.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			bu.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
			bu.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			bu.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
			bu.billboard_keep_scale = true
			bu.vertex_color_use_as_albedo = true
			m = bu
		"algue115":
			# le mur des algues : des tubes de verre pleins d'une eau verte qui luit
			var al := StandardMaterial3D.new()
			al.albedo_color = Color(0.3, 0.8, 0.3, 0.75)
			al.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			al.emission_enabled = true
			al.emission = Color(0.35, 0.95, 0.4)
			al.emission_energy_multiplier = 1.4
			al.roughness = 0.08
			al.rim_enabled = true
			al.rim = 0.5
			m = al
		"culture115":
			# les lampes de culture : un rose-violet très franc
			m = _glow(Color(1.0, 0.3, 0.85), 2.4, Color(0.9, 0.5, 0.85))
		"feuille115":
			var fe := StandardMaterial3D.new()
			fe.albedo_color = {"": Color(0.35, 0.62, 0.22), "salade": Color(0.5, 0.78, 0.3), "rouge": Color(0.55, 0.16, 0.2), "fonce": Color(0.18, 0.36, 0.14)}.get(v, Color(0.35, 0.62, 0.22))
			fe.roughness = 0.75
			fe.cull_mode = BaseMaterial3D.CULL_DISABLED
			m = fe
		"fruit115":
			var fr := StandardMaterial3D.new()
			fr.albedo_color = {"": Color(1.0, 0.6, 0.1), "fraise": Color(0.9, 0.12, 0.15), "citron": Color(0.98, 0.88, 0.2)}.get(v, Color(1.0, 0.6, 0.1))
			fr.roughness = 0.4
			m = fr
		"corail115":
			# un corail qui luit (bioluminescence) : une couleur franche, une lueur douce
			m = _glow(CORAIL.get(v, CORAIL["rose"]), 0.9, CORAIL.get(v, CORAIL["rose"]) * 0.8)
		"eponge115":
			var ep := StandardMaterial3D.new()
			if v == "":
				# la corbeille de verre : un treillis de silice (transparent entre les baguettes)
				ep.albedo_texture = _t(S + "eponge.png")
				ep.albedo_color = Color(0.95, 0.92, 0.85)
				ep.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
				ep.alpha_scissor_threshold = 0.5
				ep.roughness = 0.6
				ep.emission_enabled = true
				ep.emission = Color(0.5, 0.6, 0.66)
				ep.emission_energy_multiplier = 0.1
			else:
				# l'éponge-tonneau : épaisse, poreuse, ocre ou jaune
				ep.albedo_color = Color(0.78, 0.44, 0.22) if v == "baril" else Color(0.86, 0.7, 0.28)
				ep.normal_enabled = true
				ep.normal_texture = _t("res://assets/textures/terrain/rock_n.png")
				ep.normal_scale = 1.4
				ep.roughness = 0.95
				ep.emission_enabled = true
				ep.emission = ep.albedo_color
				ep.emission_energy_multiplier = 0.06
			ep.cull_mode = BaseMaterial3D.CULL_DISABLED
			m = ep
		"lueur115":
			# une bête qui luit, dans le noir (bioluminescence) : rien qu'une lumière
			var lu := StandardMaterial3D.new()
			var lc: Color = {"bleu": Color(0.3, 0.55, 1.0), "cyan": Color(0.3, 1.0, 0.95), "violet": Color(0.7, 0.4, 1.0), "vert": Color(0.45, 1.0, 0.55)}.get(v, Color(0.3, 0.55, 1.0))
			lu.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			lu.albedo_color = lc * 2.2
			m = lu
		"anemone115":
			m = _glow(CORAIL.get(v, CORAIL["violet"]), 1.4, CORAIL.get(v, CORAIL["violet"]) * 0.7)
		"lys115":
			var ly := StandardMaterial3D.new()
			ly.albedo_color = Color(0.86, 0.7, 0.45) if v == "" else Color(0.75, 0.3, 0.35)
			ly.roughness = 0.7
			ly.emission_enabled = true
			ly.emission = ly.albedo_color
			ly.emission_energy_multiplier = 0.18
			ly.cull_mode = BaseMaterial3D.CULL_DISABLED
			m = ly
		"gorgone115":
			# un éventail de mer : le filet de rameaux (transparent entre les mailles), teinté
			var go := StandardMaterial3D.new()
			go.albedo_texture = _t(S + "gorgone.png")
			go.albedo_color = {"": Color(0.72, 0.36, 0.88), "jaune": Color(1.0, 0.8, 0.26), "rouge": Color(0.95, 0.22, 0.2), "orange": Color(1.0, 0.5, 0.2)}.get(v, Color(0.72, 0.36, 0.88))
			go.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			go.alpha_scissor_threshold = 0.5
			go.roughness = 0.8
			go.cull_mode = BaseMaterial3D.CULL_DISABLED
			go.emission_enabled = true
			go.emission = go.albedo_color
			go.emission_energy_multiplier = 0.16
			m = go
		"ver115":
			if v == "rouge":
				m = _glow(Color(0.95, 0.12, 0.12), 0.5, Color(0.85, 0.1, 0.12))
			else:
				var ve := StandardMaterial3D.new()
				ve.albedo_color = Color(0.92, 0.9, 0.84)
				ve.roughness = 0.6
				m = ve
		"jaune115":
			# le bathyscaphe : une peinture jaune, épaisse, un peu brillante
			var ja := _metal(Color(0.96, 0.74, 0.1), 0.35, 0.25)
			ja.clearcoat_enabled = true
			ja.clearcoat = 0.6
			m = ja
		"hublot115":
			# un hublot : un verre épais, bleu-vert, qui s'allume le soir
			var hu := StandardMaterial3D.new()
			hu.albedo_color = Color(0.18, 0.32, 0.38)
			hu.roughness = 0.06
			hu.metallic = 0.4
			hu.metallic_specular = 1.0
			hu.emission_enabled = true
			hu.emission = Color(1.0, 0.82, 0.55) if v != "froid" else Color(0.55, 0.85, 1.0)
			hu.emission_energy_multiplier = 0.25
			m = hu
		"vitre115":
			# le verre intérieur (les cuves, les garde-corps, les cabines) : clair, à peine bleuté
			var vi := StandardMaterial3D.new()
			vi.albedo_color = Color(0.75, 0.9, 0.95, 0.14) if v == "" else Color(0.5, 0.62, 0.68, 0.32)
			vi.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			vi.cull_mode = BaseMaterial3D.CULL_DISABLED
			vi.roughness = 0.03
			vi.metallic = 0.2
			vi.metallic_specular = 1.0
			vi.rim_enabled = true
			vi.rim = 0.4
			vi.rim_tint = 0.6
			m = vi
		"sable115":
			var sa := StandardMaterial3D.new()
			sa.albedo_texture = _t("res://assets/textures/mer/sable_fond.png")
			sa.albedo_color = Color(0.8, 0.78, 0.72)
			sa.uv1_triplanar = true
			sa.uv1_scale = Vector3(0.25, 0.25, 0.25)
			sa.roughness = 0.95
			m = sa
		"roche115":
			var ro := StandardMaterial3D.new()
			ro.albedo_texture = _t("res://assets/textures/mer/roche_recif.png")
			ro.albedo_color = Color(0.5, 0.55, 0.6)
			var rn: Texture2D = _t("res://assets/textures/mer/roche_recif_n.png")
			if rn != null:
				ro.normal_enabled = true
				ro.normal_texture = rn
			ro.uv1_triplanar = true
			ro.uv1_scale = Vector3(0.3, 0.3, 0.3)
			ro.roughness = 0.9
			m = ro
		"tissu115":
			var ti := StandardMaterial3D.new()
			ti.albedo_color = {"": Color(0.12, 0.3, 0.42), "corail": Color(0.86, 0.45, 0.4), "sable": Color(0.85, 0.78, 0.64), "blanc": Color(0.92, 0.93, 0.92)}.get(v, Color(0.12, 0.3, 0.42))
			ti.roughness = 0.9
			ti.cull_mode = BaseMaterial3D.CULL_DISABLED
			m = ti
		"ecran115":
			# un écran de l'Institut, un tableau de l'École : une lueur bleue, des courbes
			m = _glow(Color(0.25, 0.7, 1.0), 1.1, Color(0.06, 0.14, 0.22))
		"enseigne115":
			var en := StandardMaterial3D.new()
			en.albedo_texture = _t(S + "enseigne_" + v + ".png")
			en.albedo_color = Color(1, 1, 1) if en.albedo_texture != null else Color(0.1, 0.2, 0.3)
			en.roughness = 0.35
			en.emission_enabled = true
			en.emission_texture = en.albedo_texture
			en.emission = Color(1, 1, 1)
			en.emission_energy_multiplier = 0.6
			m = en
	if m != null:
		_cache[key] = m
	return m


## Le soir (k = 1) ou le jour (k = 0) : la Perle, les diodes, les hublots, les enseignes.
static func night(k: float) -> void:
	var pe: StandardMaterial3D = make("perle115") as StandardMaterial3D
	if pe != null:
		pe.emission = Color(1.0, 0.95, 0.85).lerp(Color(0.5, 0.45, 1.0), k)
		pe.emission_energy_multiplier = lerpf(6.0, 2.6, k)
	for c in LED:
		var le: StandardMaterial3D = make("led115_" + str(c)) as StandardMaterial3D
		if le != null:
			le.emission_energy_multiplier = lerpf(1.0, 3.4, k)
	for h in ["hublot115", "hublot115_froid"]:
		var hu: StandardMaterial3D = make(h) as StandardMaterial3D
		if hu != null:
			hu.emission_energy_multiplier = lerpf(0.25, 2.4, k)
	for key in _cache:
		if str(key).begins_with("enseigne115"):
			(_cache[key] as StandardMaterial3D).emission_energy_multiplier = lerpf(0.5, 0.85, k)
	if facade != null and facade.emission_enabled:
		facade.emission_energy_multiplier = lerpf(0.0, 0.55, k)
