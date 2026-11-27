extends RefCounted
## V209 : les matières de l'Île Foraine (l'acier peint du grand huit, le bois, la toile rayée des
## baraques, les ampoules) et son lot de formes (les boîtes, les tubes : un seul maillage par matière).

const GK = preload("res://scripts/geants_kit_v142.gd")
const MetalKit = preload("res://scripts/metal_kit_v160.gd")
const MJ := "res://assets/textures/montjoie/"
const B161 := "res://assets/textures/beau161/"

static var _cache: Dictionary = {}


static func _peint(c: Color, rough: float = 0.34) -> StandardMaterial3D:
	# l'acier peint : un vernis qui brille, le grain du métal dessous
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = 0.25
	m.clearcoat_enabled = true
	m.clearcoat = 0.5
	m.clearcoat_roughness = 0.25
	MetalKit.habille(m, "brosse", 1.2)
	m.albedo_color = c
	return m


static func _toile(c: Color) -> StandardMaterial3D:
	var m: StandardMaterial3D = GK._surface(B161 + "toile_lin.png", B161 + "toile_lin_n.png", c, 0.92, 1.2, 0.7, c)
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


static func mat(key: String) -> Material:
	if _cache.has(key):
		return _cache[key]
	var m: Material = null
	match key:
		"rail":
			m = _peint(Color(0.82, 0.08, 0.07))
		"poutre":
			m = _peint(Color(0.9, 0.9, 0.88), 0.4)
		"acier":
			var a := StandardMaterial3D.new()
			a.albedo_color = Color(0.62, 0.64, 0.67)
			a.metallic = 0.9
			a.roughness = 0.35
			m = MetalKit.habille(a, "brosse")
		"fer":
			var f := StandardMaterial3D.new()
			f.albedo_color = Color(0.16, 0.16, 0.18)
			f.metallic = 0.7
			f.roughness = 0.55
			m = MetalKit.habille(f, "fer")
		"basalte":
			# V213 : le basalte des orgues et des arches
			m = GK._surface("res://assets/textures/braise/basalte.png", "res://assets/textures/braise/basalte_n.png", Color(0.82, 0.8, 0.84), 0.86, 4.0, 1.0, Color(0.2, 0.2, 0.22))
		"jaune":
			m = _peint(Color(0.96, 0.74, 0.08))
		"bleu":
			m = _peint(Color(0.1, 0.24, 0.62))
		"wagon":
			m = _peint(Color(0.86, 0.1, 0.1), 0.26)
		"siege":
			m = GK._surface(B161 + "caoutchouc.png", B161 + "caoutchouc_n.png", Color(0.5, 0.5, 0.52), 0.7, 0.6, 0.8, Color(0.1, 0.1, 0.11))
		"planches":
			m = GK._surface(MJ + "bois_planches.png", MJ + "bois_planches_n.png", Color(0.96, 0.9, 0.82), 0.84, 3.0, 1.0, Color(0.55, 0.4, 0.28))
		"bois_blanc":
			m = GK._surface(B161 + "bois_peint.png", B161 + "bois_peint_n.png", Color(1, 1, 1), 0.7, 3.0, 0.8, Color(0.92, 0.9, 0.86))
		"bois_rouge":
			m = GK._surface(B161 + "bois_peint.png", B161 + "bois_peint_n.png", Color(0.86, 0.16, 0.14), 0.68, 3.0, 0.8, Color(0.8, 0.16, 0.14))
		"bois_bleu":
			m = GK._surface(B161 + "bois_peint.png", B161 + "bois_peint_n.png", Color(0.16, 0.34, 0.7), 0.68, 3.0, 0.8, Color(0.16, 0.3, 0.66))
		"dalles":
			m = GK._surface(MJ + "dalles.png", MJ + "dalles_n.png", Color(1.0, 0.98, 0.95), 0.86, 4.0, 1.0, Color(0.6, 0.58, 0.55))
		"toile_rouge":
			m = _toile(Color(0.85, 0.13, 0.12))
		"toile_blanche":
			m = _toile(Color(0.96, 0.94, 0.88))
		"toile_jaune":
			m = _toile(Color(0.98, 0.78, 0.16))
		"toile_bleue":
			m = _toile(Color(0.16, 0.36, 0.74))
		"ampoule":
			var e := StandardMaterial3D.new()
			e.albedo_color = Color(1.0, 0.86, 0.55)
			e.emission_enabled = true
			e.emission = Color(1.0, 0.78, 0.4)
			e.emission_energy_multiplier = 2.2
			m = e
		"lampion_rouge", "lampion_jaune", "lampion_bleu", "lampion_vert", "lampion_orange":
			# V214 : les lampions des allées (ils éclairent de leur couleur, jour et nuit)
			var teinte: Color = {"lampion_rouge": Color(1.0, 0.18, 0.14), "lampion_jaune": Color(1.0, 0.82, 0.16), "lampion_bleu": Color(0.2, 0.5, 1.0), "lampion_vert": Color(0.25, 0.9, 0.35), "lampion_orange": Color(1.0, 0.5, 0.1)}[key]
			var lp := StandardMaterial3D.new()
			lp.albedo_color = teinte
			lp.emission_enabled = true
			lp.emission = teinte
			lp.emission_energy_multiplier = 0.55
			m = lp
		"vitre":
			var g := StandardMaterial3D.new()
			g.albedo_color = Color(0.6, 0.75, 0.8, 0.35)
			g.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			g.roughness = 0.08
			g.metallic_specular = 0.9
			m = g
		_:
			m = GK._flat(Color(0.8, 0.2, 0.8), 0.8)
	_cache[key] = m
	return m


## Le lot : les formes du kit des géants, avec les matières d'ici.
class Lot extends "res://scripts/geants_kit_v142.gd".Batch:
	func commit(parent: Node3D, label: String, shadows: bool = true, vis_end: float = 0.0) -> MeshInstance3D:
		if sts.is_empty():
			return null
		var mesh := ArrayMesh.new()
		for k in sts:
			var st: SurfaceTool = sts[k]
			st.index()
			st.generate_tangents()
			st.commit(mesh)
			mesh.surface_set_material(mesh.get_surface_count() - 1, load("res://scripts/foraine_kit_v209.gd").mat(str(k)))
		var mi := MeshInstance3D.new()
		mi.name = label
		mi.mesh = mesh
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if vis_end > 0.0:
			mi.visibility_range_end = vis_end
			mi.visibility_range_end_margin = 20.0
			mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		parent.add_child(mi)
		sts.clear()
		return mi
