extends RefCounted
## V113 : les matières de la Cité des Nuées (futuriste et lumineuse) : le béton blanc, le panneau
## composite blanc satiné (les nacelles, la capsule), l'acier brossé, le verre clair des garde-corps et
## de la cage, le mur-rideau des immeubles (et ses fenêtres allumées le soir), le bois blond des
## platelages, les dalles claires, les panneaux solaires, la roche grise du dessous, l'anneau bleuté des
## sustentateurs et leur voile, les lampes à diodes, l'eau des bassins, les toiles tendues, les
## enseignes. Une clé « genre113_variante » ; null si la clé n'est pas d'ici. Gardées une fois faites.

const S := "res://assets/textures/nuees/"
static var _cache: Dictionary = {}


static func _t(name: String) -> Texture2D:
	var p: String = S + name
	return load(p) if ResourceLoader.exists(p) else null


static func _surface(name: String, tint: Color, rough: float, nscale: float = 1.0, base := Color(0.8, 0.8, 0.8)) -> StandardMaterial3D:
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
	if not kind.ends_with("113"):
		return null
	var v: String = parts[1] if parts.size() > 1 else ""
	var m: Material = null
	match kind:
		"beton113":
			m = _surface("beton_blanc", Color(1.02, 1.02, 1.0) if v != "gris" else Color(0.82, 0.83, 0.84), 0.82, 0.8, Color(0.88, 0.88, 0.86))
		"composite113":
			var c := _surface("composite", Color(1, 1, 1), 0.32, 0.6, Color(0.93, 0.94, 0.94))
			c.metallic_specular = 0.7
			c.clearcoat_enabled = true
			c.clearcoat = 0.4
			c.clearcoat_roughness = 0.2
			m = c
		"dalle113":
			m = _surface("dalle_claire", Color(1, 1, 1), 0.62, 0.8, Color(0.76, 0.75, 0.72))
		"bois113":
			m = _surface("bois_blond", Color(1, 1, 1) if v != "sombre" else Color(0.7, 0.62, 0.55), 0.55, 0.9, Color(0.76, 0.6, 0.44))
		"acier113":
			m = _metal(Color(0.72, 0.74, 0.76) if v != "sombre" else Color(0.32, 0.34, 0.37), 0.28, 0.9)
		"alu113":
			m = _metal(Color(0.84, 0.86, 0.88), 0.36, 0.75)
		"verre113":
			# le verre des garde-corps et de la cage : clair, à peine bleuté, il reflète le ciel
			var vg := StandardMaterial3D.new()
			vg.albedo_color = Color(0.78, 0.9, 0.96, 0.12) if v != "fume" else Color(0.5, 0.6, 0.66, 0.35)
			vg.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			vg.cull_mode = BaseMaterial3D.CULL_DISABLED
			vg.roughness = 0.03
			vg.metallic = 0.25
			vg.metallic_specular = 1.0
			vg.rim_enabled = true
			vg.rim = 0.35
			vg.rim_tint = 0.7
			m = vg
		"sol113":
			# le plancher de verre du Belvédère : on voit à travers, un léger dépoli blanc sur les bords
			var sg := StandardMaterial3D.new()
			sg.albedo_color = Color(0.82, 0.92, 0.97, 0.22)
			sg.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			sg.cull_mode = BaseMaterial3D.CULL_DISABLED
			sg.roughness = 0.05
			sg.metallic_specular = 1.0
			m = sg
		"facade113":
			# le mur-rideau : opaque (pour la nuit et pour le casque), mais qui a l'air de verre
			var fa := StandardMaterial3D.new()
			fa.albedo_texture = _t("facade.png")
			fa.albedo_color = Color(1, 1, 1) if fa.albedo_texture != null else Color(0.55, 0.66, 0.74)
			fa.roughness = 0.12
			fa.metallic = 0.35
			fa.metallic_specular = 0.9
			var lum: Texture2D = _t("facade_lum.png")
			if lum != null:
				fa.emission_enabled = true
				fa.emission_texture = lum
				fa.emission = Color(1, 1, 1)
				fa.emission_energy_multiplier = 0.0
			m = fa
		"solaire113":
			var so := StandardMaterial3D.new()
			so.albedo_texture = _t("solaire.png")
			so.albedo_color = Color(1, 1, 1) if so.albedo_texture != null else Color(0.1, 0.14, 0.26)
			so.roughness = 0.18
			so.metallic = 0.4
			so.metallic_specular = 0.9
			m = so
		"roche113":
			# la roche du dessous : grise, un peu dorée par endroits (une texture des Crocs, en triplanaire)
			var ro := StandardMaterial3D.new()
			var rt: Texture2D = load("res://assets/textures/montjoie/roche_crocs.png") if ResourceLoader.exists("res://assets/textures/montjoie/roche_crocs.png") else null
			ro.albedo_texture = rt
			ro.albedo_color = Color(1.3, 1.25, 1.18) if rt != null else Color(0.55, 0.52, 0.48)
			var rn: Texture2D = load("res://assets/textures/montjoie/roche_crocs_n.png") if ResourceLoader.exists("res://assets/textures/montjoie/roche_crocs_n.png") else null
			if rn != null:
				ro.normal_enabled = true
				ro.normal_texture = rn
				ro.normal_scale = 1.2
			ro.uv1_triplanar = true
			ro.uv1_scale = Vector3(0.09, 0.09, 0.09)
			ro.roughness = 0.92
			m = ro
		"anneau113":
			var an := StandardMaterial3D.new()
			an.albedo_color = Color(0.82, 0.93, 1.0)
			an.emission_enabled = true
			an.emission = Color(0.55, 0.82, 1.0)
			an.emission_energy_multiplier = 1.4
			an.roughness = 0.2
			m = an
		"voile113":
			var vo := StandardMaterial3D.new()
			vo.albedo_color = Color(0.6, 0.85, 1.0, 0.035)
			vo.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			vo.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
			vo.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			vo.cull_mode = BaseMaterial3D.CULL_DISABLED
			vo.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
			vo.disable_receive_shadows = true
			m = vo
		"led113":
			# les diodes (lampadaires, liserés) : un blanc neutre, plus fort à la nuit
			var le := StandardMaterial3D.new()
			le.albedo_color = Color(0.96, 0.98, 1.0)
			le.emission_enabled = true
			le.emission = Color(0.92, 0.96, 1.0) if v != "chaud" else Color(1.0, 0.86, 0.66)
			le.emission_energy_multiplier = 0.4
			le.roughness = 0.3
			m = le
		"eau113":
			var ea := StandardMaterial3D.new()
			ea.albedo_color = Color(0.36, 0.56, 0.62, 0.72)
			ea.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			ea.roughness = 0.03
			ea.metallic_specular = 1.0
			ea.normal_enabled = true
			ea.normal_texture = load("res://assets/textures/water/water_n.png") if ResourceLoader.exists("res://assets/textures/water/water_n.png") else null
			ea.normal_scale = 0.3
			ea.uv1_scale = Vector3(0.15, 0.15, 0.15)
			m = ea
		"toile113":
			var to := StandardMaterial3D.new()
			to.albedo_color = {"": Color(0.95, 0.95, 0.93), "bleu": Color(0.55, 0.72, 0.84), "sable": Color(0.88, 0.8, 0.66), "vert": Color(0.56, 0.7, 0.56)}.get(v, Color(0.95, 0.95, 0.93))
			to.roughness = 0.85
			to.cull_mode = BaseMaterial3D.CULL_DISABLED
			m = to
		"peint113":
			m = _metal({"bleu": Color(0.42, 0.6, 0.76), "vert": Color(0.42, 0.58, 0.46), "sable": Color(0.82, 0.74, 0.6), "gris": Color(0.5, 0.52, 0.55), "rouge": Color(0.72, 0.3, 0.26)}.get(v, Color(0.9, 0.9, 0.9)), 0.45, 0.2)
		"gazon113":
			var gz := StandardMaterial3D.new()
			var gt: Texture2D = load("res://assets/textures/montjoie/prairie.png") if ResourceLoader.exists("res://assets/textures/montjoie/prairie.png") else null
			gz.albedo_texture = gt
			gz.albedo_color = Color(0.92, 1.0, 0.88) if gt != null else Color(0.3, 0.45, 0.2)
			gz.roughness = 0.95
			gz.uv1_scale = Vector3(0.5, 0.5, 0.5)
			m = gz
		"miroir113":
			# l'acier poli de la Plume de Séraphin : un miroir qui reflète le ciel
			var mi := _metal(Color(0.9, 0.92, 0.95), 0.06, 1.0)
			mi.metallic_specular = 1.0
			mi.cull_mode = BaseMaterial3D.CULL_DISABLED
			m = mi
		"filet113":
			# les filets des capteurs de brume : une maille fine, gris clair, presque transparente
			var fi := StandardMaterial3D.new()
			fi.albedo_color = Color(0.82, 0.84, 0.86, 0.38)
			fi.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			fi.cull_mode = BaseMaterial3D.CULL_DISABLED
			fi.roughness = 0.8
			m = fi
		"haie113":
			m = _surface("haie", Color(1, 1, 1), 0.9, 1.2, Color(0.22, 0.36, 0.14))
		"terre113":
			var te := StandardMaterial3D.new()
			te.albedo_color = Color(0.27, 0.2, 0.14)
			te.roughness = 1.0
			m = te
		"enseigne113":
			var en := StandardMaterial3D.new()
			en.albedo_texture = _t("enseigne_" + v + ".png")
			en.albedo_color = Color(1, 1, 1) if en.albedo_texture != null else Color(0.88, 0.9, 0.92)
			en.roughness = 0.4
			en.metallic = 0.2
			m = en
	if m != null:
		_cache[key] = m
	return m


## La nuit tombe (k = 1) ou le jour se lève (k = 0) : les diodes, les fenêtres, les anneaux.
static func night(k: float) -> void:
	var le: StandardMaterial3D = make("led113") as StandardMaterial3D
	if le != null:
		le.emission_energy_multiplier = lerpf(0.4, 3.6, k)
	var lc: StandardMaterial3D = make("led113_chaud") as StandardMaterial3D
	if lc != null:
		lc.emission_energy_multiplier = lerpf(0.3, 3.0, k)
	var fa: StandardMaterial3D = make("facade113") as StandardMaterial3D
	if fa != null and fa.emission_enabled:
		fa.emission_energy_multiplier = lerpf(0.0, 1.6, k)
