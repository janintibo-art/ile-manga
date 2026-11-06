extends RefCounted
## V114 : les matières des Strates et de la Fronde (fantastique-vapeur, sous terre ; punk à vapeur) :
## le fer forgé noir, le fer rouillé, les rails, le bois sombre des traverses, la tôle peinte des
## conteneurs et des chaudières, les globes des lampes de mine (toujours allumés), la lampe à arc du
## Soleil de Laiton, les cristaux, les chapeaux des champignons lumineux, l'eau noire, les toiles et
## bâches, les enseignes, la bannière et les fresques de la Fronde. Une clé « genre114_variante » ;
## null si la clé n'est pas d'ici. Gardées une fois faites.

const S := "res://assets/textures/strates/"
static var _cache: Dictionary = {}


static func _t(name: String) -> Texture2D:
	var p: String = S + name
	return load(p) if ResourceLoader.exists(p) else null


static func _metal(c: Color, rough: float, metal: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	m.metallic_specular = 0.55
	return m


static func _glow(c: Color, albedo: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = albedo
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	m.roughness = 0.3
	return m


static func _tex_or(path: String) -> Texture2D:
	return load(path) if ResourceLoader.exists(path) else null


static func make(key: String) -> Material:
	if _cache.has(key):
		return _cache[key]
	var parts: PackedStringArray = key.split("_", true, 1)
	var kind: String = parts[0]
	if not kind.ends_with("114"):
		return null
	var v: String = parts[1] if parts.size() > 1 else ""
	var m: Material = null
	match kind:
		"fer114":
			# le fer forgé noir (piliers, garde-corps, passerelles) ; « rouille » : le fer de la Fronde
			if v == "rouille":
				var ru := StandardMaterial3D.new()
				var rt: Texture2D = _tex_or("res://assets/textures/boucan/acier_rouille.png")
				ru.albedo_texture = rt
				ru.albedo_color = Color(1, 1, 1) if rt != null else Color(0.42, 0.24, 0.14)
				var rn: Texture2D = _tex_or("res://assets/textures/boucan/acier_rouille_n.png")
				if rn != null:
					ru.normal_enabled = true
					ru.normal_texture = rn
				ru.uv1_triplanar = true
				ru.uv1_world_triplanar = true
				ru.uv1_scale = Vector3(0.35, 0.35, 0.35)
				ru.roughness = 0.82
				ru.metallic = 0.35
				m = ru
			else:
				m = _metal(Color(0.1, 0.1, 0.11), 0.5, 0.8)
		"rail114":
			m = _metal(Color(0.5, 0.48, 0.46), 0.32, 0.92)
		"traverse114":
			var tr := StandardMaterial3D.new()
			var tt: Texture2D = _tex_or("res://assets/textures/montjoie/bois_planches.png")
			tr.albedo_texture = tt
			tr.albedo_color = Color(0.38, 0.28, 0.2) if tt != null else Color(0.24, 0.17, 0.11)
			tr.roughness = 0.9
			m = tr
		"tole114":
			# la tôle peinte (conteneurs, chaudières, cabanes de la Fronde), un peu usée
			var col: Color = {"rouge": Color(0.62, 0.18, 0.14), "bleu": Color(0.16, 0.32, 0.5), "vert": Color(0.2, 0.42, 0.3),
				"jaune": Color(0.86, 0.66, 0.16), "orange": Color(0.84, 0.42, 0.14), "violet": Color(0.4, 0.24, 0.5),
				"turquoise": Color(0.12, 0.5, 0.52), "creme": Color(0.84, 0.8, 0.68), "noir": Color(0.12, 0.12, 0.13)}.get(v, Color(0.5, 0.5, 0.5))
			var to := StandardMaterial3D.new()
			var tx: Texture2D = _tex_or("res://assets/textures/boucan/bardage.png")
			to.albedo_texture = tx
			to.albedo_color = col * 1.35 if tx != null else col
			var tn: Texture2D = _tex_or("res://assets/textures/boucan/bardage_n.png")
			if tn != null:
				to.normal_enabled = true
				to.normal_texture = tn
			to.roughness = 0.62
			to.metallic = 0.3
			m = to
		"lampe114":
			# les globes des lampes des Strates : toujours allumés (« froid » : une lampe à cristal)
			if v == "froid":
				m = _glow(Color(0.62, 0.84, 1.0), Color(0.86, 0.94, 1.0), 2.4)
			else:
				m = _glow(Color(1.0, 0.76, 0.46), Color(1.0, 0.9, 0.7), 2.6)
		"soleil114":
			# le cœur du Soleil de Laiton : une lampe à arc, très forte le jour, ambrée la nuit
			var so := _glow(Color(1.0, 0.92, 0.76), Color(1.0, 0.97, 0.9), 14.0)
			so.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			m = so
		"cristal114":
			var c: Color = Color(0.3, 0.64, 1.0) if v != "violet" else Color(0.62, 0.38, 1.0)
			var cr := _glow(c, Color(c.r * 0.35, c.g * 0.45, c.b * 0.6), 0.9)
			cr.roughness = 0.08
			cr.metallic_specular = 1.0
			m = cr
		"champi114":
			# le chapeau d'un champignon lumineux (bleu, vert, rose, ambre)
			var cc: Color = {"bleu": Color(0.35, 0.7, 1.0), "vert": Color(0.4, 1.0, 0.6), "rose": Color(1.0, 0.5, 0.78), "ambre": Color(1.0, 0.7, 0.3)}.get(v, Color(0.4, 1.0, 0.6))
			var ch := _glow(cc, Color(cc.r * 0.55, cc.g * 0.55, cc.b * 0.55), 1.3)
			ch.roughness = 0.45
			ch.rim_enabled = true
			ch.rim = 0.4
			m = ch
		"pied114":
			var pi := StandardMaterial3D.new()
			pi.albedo_color = Color(0.86, 0.84, 0.76)
			pi.roughness = 0.7
			pi.emission_enabled = true
			pi.emission = Color(0.4, 0.8, 0.7)
			pi.emission_energy_multiplier = 0.12
			m = pi
		"eau114":
			# l'eau noire et calme de l'étang (elle reflète les champignons)
			var ea := StandardMaterial3D.new()
			ea.albedo_color = Color(0.04, 0.1, 0.12, 0.82)
			ea.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			ea.roughness = 0.02
			ea.metallic_specular = 1.0
			ea.normal_enabled = true
			ea.normal_texture = _tex_or("res://assets/textures/water/water_n.png")
			ea.normal_scale = 0.2
			ea.uv1_scale = Vector3(0.12, 0.12, 0.12)
			m = ea
		"riviere114":
			# la rivière du fond du Gouffre : on ne voit que sa lueur bleue, très loin
			var ri := _glow(Color(0.2, 0.55, 0.7), Color(0.05, 0.12, 0.16), 0.6)
			ri.roughness = 0.1
			m = ri
		"toile114":
			var tc: Color = {"rouge": Color(0.66, 0.16, 0.12), "bleu": Color(0.2, 0.3, 0.55), "jaune": Color(0.88, 0.7, 0.24),
				"vert": Color(0.26, 0.46, 0.3), "violet": Color(0.42, 0.26, 0.52), "orange": Color(0.86, 0.44, 0.16),
				"parachute": Color(0.9, 0.86, 0.78)}.get(v, Color(0.8, 0.76, 0.66))
			var ti := StandardMaterial3D.new()
			ti.albedo_color = tc
			ti.roughness = 0.88
			ti.cull_mode = BaseMaterial3D.CULL_DISABLED
			m = ti
		"enseigne114":
			var en := StandardMaterial3D.new()
			en.albedo_texture = _t("enseigne_" + v + ".png")
			en.albedo_color = Color(1, 1, 1) if en.albedo_texture != null else Color(0.3, 0.26, 0.2)
			en.roughness = 0.6
			en.emission_enabled = true
			en.emission_texture = en.albedo_texture
			en.emission = Color(1, 1, 1)
			en.emission_energy_multiplier = 0.12
			m = en
		"banniere114":
			var bn := StandardMaterial3D.new()
			bn.albedo_texture = _t("banniere_" + (v if v != "" else "fronde") + ".png")
			bn.albedo_color = Color(1, 1, 1) if bn.albedo_texture != null else Color(0.12, 0.12, 0.14)
			bn.roughness = 0.9
			bn.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			bn.alpha_scissor_threshold = 0.4
			bn.cull_mode = BaseMaterial3D.CULL_DISABLED
			m = bn
		"fresque114":
			# une fresque de la Fronde, peinte sur un grand panneau (un peu de lumière propre : on la voit)
			var fr := StandardMaterial3D.new()
			fr.albedo_texture = _t("fresque_" + v + ".png")
			fr.albedo_color = Color(1, 1, 1) if fr.albedo_texture != null else Color(0.5, 0.3, 0.5)
			fr.roughness = 0.8
			m = fr
		"guirlande114":
			var gc: Color = {"rouge": Color(1.0, 0.3, 0.25), "bleu": Color(0.35, 0.55, 1.0), "jaune": Color(1.0, 0.8, 0.3),
				"vert": Color(0.4, 1.0, 0.45), "violet": Color(0.8, 0.4, 1.0)}.get(v, Color(1.0, 0.85, 0.55))
			var gl := _glow(gc, gc, 3.2)
			gl.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			m = gl
		"braise114":
			# le feu d'un four, d'un brasero : une lueur orange
			var br := _glow(Color(1.0, 0.45, 0.12), Color(1.0, 0.5, 0.2), 4.0)
			br.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			m = br
		"vitre114":
			# les vitres des wagons et des cabines : un verre un peu sale
			var vi := StandardMaterial3D.new()
			vi.albedo_color = Color(0.6, 0.66, 0.62, 0.25)
			vi.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			vi.cull_mode = BaseMaterial3D.CULL_DISABLED
			vi.roughness = 0.1
			vi.metallic_specular = 0.9
			m = vi
	if m != null:
		_cache[key] = m
	return m


## Le Soleil de Laiton baisse le soir (k = 1 : la nuit).
static func night(k: float) -> void:
	var so: StandardMaterial3D = make("soleil114") as StandardMaterial3D
	if so != null:
		so.emission_energy_multiplier = lerpf(14.0, 3.0, k)
		so.emission = Color(1.0, 0.92, 0.76).lerp(Color(1.0, 0.62, 0.32), k)
	var lm: StandardMaterial3D = make("lampe114") as StandardMaterial3D
	if lm != null:
		lm.emission_energy_multiplier = lerpf(2.0, 3.4, k)
