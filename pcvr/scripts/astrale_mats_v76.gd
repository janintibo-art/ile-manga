extends RefCounted
## V76 : les matières d'Astralys, la cité de cristal et de lumière des Lumens (l'île flottante),
## partagées par le kit de la ville (astrale_kit_v76.gd), l'île et la végétation. Une clé
## « genre76_variante » (« cristal76_bleu », « nacre76_rose », « holo76_3 », « enseigne76_cafe »…) ;
## null si la clé n'est pas d'ici. Les matières lumineuses montent à la nuit tombée (night()).
## Si une texture manque, la matière garde une couleur plausible.

const S := "res://assets/textures/astralys/"
## Les couleurs des Lumens : leurs cristaux, leurs lumières, leurs tissus.
const LUEURS := {
	"bleu": Color(0.35, 0.7, 1.0), "violet": Color(0.68, 0.45, 1.0), "rose": Color(1.0, 0.55, 0.85), "turquoise": Color(0.3, 0.95, 0.9),
	"or": Color(1.0, 0.82, 0.45), "blanc": Color(0.92, 0.95, 1.0), "vert": Color(0.45, 1.0, 0.65), "ambre": Color(1.0, 0.65, 0.3),
}
const TEINTES := {
	"": Color(1, 1, 1), "rose": Color(1.04, 0.94, 1.0), "bleu": Color(0.92, 0.98, 1.06), "or": Color(1.06, 1.0, 0.9),
	"lavande": Color(0.96, 0.94, 1.06), "sombre": Color(0.7, 0.72, 0.8),
}
static var _cache: Dictionary = {}


static func _t(name: String) -> Texture2D:
	var p: String = S + name
	return load(p) if ResourceLoader.exists(p) else null


static func _surface(name: String, tint: Color, rough: float, nscale: float = 1.0, tri: float = 0.0, base := Color(0.8, 0.8, 0.84), metal: float = 0.0) -> StandardMaterial3D:
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


## La carte d'émission « _e » d'une texture (les filets, les veines, les motifs qui luisent).
static func _emis(m: StandardMaterial3D, name: String, c: Color, energy: float) -> void:
	var e: Texture2D = _t(name + "_e.png")
	if e == null:
		return
	m.emission_enabled = true
	m.emission_texture = e
	m.emission = c
	m.emission_energy_multiplier = energy


static func _glow(c: Color, energy: float, alpha: float = 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(c.r, c.g, c.b, alpha)
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	m.roughness = 0.3
	if alpha < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


static func _panel(name: String, glow: float, alpha: bool) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	var tex: Texture2D = _t(name + ".png")
	m.albedo_texture = tex
	m.roughness = 0.5
	if alpha:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
	if glow > 0.0:
		m.emission_enabled = true
		m.emission_texture = tex
		m.emission = Color(1, 1, 1)
		m.emission_energy_multiplier = glow
	if tex == null:
		m.albedo_color = Color(0.4, 0.6, 0.9, 0.6 if alpha else 1.0)
	return m


static func make(key: String) -> Material:
	if _cache.has(key):
		return _cache[key]
	var parts: PackedStringArray = key.split("_", true, 1)
	var kind: String = parts[0]
	if not kind.ends_with("76"):
		return null
	var v: String = parts[1] if parts.size() > 1 else ""
	var tint: Color = TEINTES.get(v, Color(1, 1, 1))
	var lueur: Color = LUEURS.get(v, LUEURS["bleu"])
	var m: Material = null
	match kind:
		"nacre76":
			# les panneaux nacrés des murs : blanc perle, un reflet qui change avec l'angle
			var na: StandardMaterial3D = _surface("nacre_mur", tint, 0.28, 0.6, 0.0, Color(0.9, 0.9, 0.94))
			na.clearcoat_enabled = true
			na.clearcoat = 0.7
			na.clearcoat_roughness = 0.2
			na.rim_enabled = true
			na.rim = 0.35
			na.rim_tint = 0.8
			_emis(na, "nacre_mur", Color(0.8, 0.9, 1.0), 0.4)
			m = na
		"nacresol76":
			var ns: StandardMaterial3D = _surface("nacre", tint, 0.3, 0.7, 0.0, Color(0.86, 0.86, 0.9))
			ns.clearcoat_enabled = true
			ns.clearcoat = 0.5
			_emis(ns, "nacre", Color(0.8, 0.9, 1.0), 0.3)
			m = ns
		"cristal76":
			# un cristal : translucide, coloré, il luit doucement (plus fort la nuit)
			var cr: StandardMaterial3D = _surface("cristal_" + (v if v in ["bleu", "violet", "rose"] else "bleu"), Color(lueur, 0.78), 0.06, 0.5, 0.0, lueur)
			cr.albedo_color = Color(cr.albedo_color.r, cr.albedo_color.g, cr.albedo_color.b, 0.78)
			cr.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
			cr.metallic_specular = 0.9
			cr.emission_enabled = true
			cr.emission = lueur
			cr.emission_energy_multiplier = 0.35
			cr.rim_enabled = true
			cr.rim = 0.6
			_emis(cr, "cristal_" + (v if v in ["bleu", "violet", "rose"] else "bleu"), lueur, 0.35)
			m = cr
		"cristalsol76":
			var cs: StandardMaterial3D = _surface("cristal_sol", Color(1, 1, 1), 0.12, 0.6, 0.0, Color(0.7, 0.8, 0.95))
			cs.metallic_specular = 0.8
			cs.emission_enabled = true
			cs.emission = LUEURS["bleu"]
			cs.emission_energy_multiplier = 0.05
			_emis(cs, "cristal_sol", LUEURS["bleu"], 0.05)
			m = cs
		"metal76":
			# le métal blanc perle des Lumens (« or » : doré ; « bleu » : bleu nuit)
			var mc: Color = {"or": Color(1.0, 0.85, 0.55), "bleu": Color(0.35, 0.45, 0.7), "sombre": Color(0.35, 0.36, 0.42)}.get(v, Color(0.92, 0.92, 0.95))
			var me: StandardMaterial3D = _surface("metal_lumen", mc, 0.22, 0.5, 0.0, mc, 0.85)
			_emis(me, "metal_lumen", Color(0.6, 0.85, 1.0), 0.8)
			m = me
		"verre76":
			# le verre irisé des dômes et des baies
			var vg: StandardMaterial3D = _surface("verre_holo", Color(0.85, 0.92, 1.0, 0.28), 0.04, 0.3, 0.0, Color(0.8, 0.9, 1.0))
			vg.albedo_color = Color(vg.albedo_color.r, vg.albedo_color.g, vg.albedo_color.b, 0.28)
			vg.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			vg.cull_mode = BaseMaterial3D.CULL_DISABLED
			vg.metallic_specular = 1.0
			vg.rim_enabled = true
			vg.rim = 0.7
			m = vg
		"lumiere76":
			m = _glow(lueur, 2.4)
		"motif76":
			# des motifs lumineux gravés (les frises, les seuils, les marches)
			var mo: StandardMaterial3D = _surface("lumiere_motif", Color(1, 1, 1), 0.35, 0.5, 0.0, Color(0.2, 0.22, 0.3))
			mo.emission_enabled = true
			mo.emission_texture = mo.albedo_texture
			mo.emission = lueur
			mo.emission_energy_multiplier = 0.6
			m = mo
		"holo76":
			# un hologramme : flottant, transparent, lumineux, sans ombre
			var ho: StandardMaterial3D = _panel("holo_" + v, 1.8, true)
			ho.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			ho.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
			m = ho
		"enseigne76":
			var en: StandardMaterial3D = _panel("enseigne_" + v, 1.2, true)
			m = en
		"fresque76":
			m = _panel("fresque_lumen_" + v, 0.25, false)
		"soucoupe76":
			var so: StandardMaterial3D = _surface("coque_soucoupe", Color(1, 1, 1), 0.2, 0.6, 0.0, Color(0.85, 0.86, 0.9), 0.75)
			so.clearcoat_enabled = true
			so.clearcoat = 0.9
			_emis(so, "coque_soucoupe", Color(1.0, 0.9, 0.7), 1.2)
			m = so
		"roche76":
			# la roche sombre du dessous de l'île, veinée de cristaux
			var ro: StandardMaterial3D = _surface("roche_astrale", tint, 0.85, 1.0, 0.06, Color(0.26, 0.24, 0.32))
			ro.emission_enabled = ro.albedo_texture != null
			ro.emission_texture = ro.albedo_texture
			ro.emission = Color(0.5, 0.45, 1.0)
			ro.emission_energy_multiplier = 0.08
			_emis(ro, "roche_astrale", Color(0.55, 0.45, 1.0), 0.08)
			m = ro
		"mousse76":
			var mo2: StandardMaterial3D = _surface("mousse_astrale", tint, 0.9, 0.8, 0.0, Color(0.36, 0.42, 0.62))
			mo2.emission_enabled = mo2.albedo_texture != null
			mo2.emission_texture = mo2.albedo_texture
			mo2.emission_energy_multiplier = 0.2
			m = mo2
		"sable76":
			m = _surface("sable_stellaire", tint, 0.8, 0.8, 0.0, Color(0.8, 0.8, 0.86))
		"feuille76":
			# les feuilles lumineuses des plantes géantes
			var fe: StandardMaterial3D = _panel("feuille_lumineuse", 0.6, true)
			fe.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			fe.alpha_scissor_threshold = 0.4
			fe.albedo_color = Color(1, 1, 1) if fe.albedo_texture != null else Color(0.3, 0.8, 0.9)
			fe.emission = LUEURS.get(v, LUEURS["turquoise"]) if fe.albedo_texture == null else Color(1, 1, 1)
			m = fe
		"petale76":
			var pe: StandardMaterial3D = _panel("petale_lumineux", 0.9, true)
			pe.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			pe.alpha_scissor_threshold = 0.4
			pe.albedo_color = Color(lueur.r * 1.1, lueur.g * 1.1, lueur.b * 1.1)
			pe.emission = lueur
			m = pe
		"tige76":
			var ti := StandardMaterial3D.new()
			ti.albedo_color = Color(0.32, 0.5, 0.62)
			ti.roughness = 0.6
			ti.emission_enabled = true
			ti.emission = Color(0.2, 0.5, 0.7)
			ti.emission_energy_multiplier = 0.15
			ti.rim_enabled = true
			m = ti
		"tissu76":
			var tc: Color = LUEURS.get(v, Color(0.85, 0.85, 0.95))
			var tx := StandardMaterial3D.new()
			tx.albedo_color = Color(tc.r * 0.8 + 0.15, tc.g * 0.8 + 0.15, tc.b * 0.8 + 0.15)
			tx.roughness = 0.6
			tx.metallic_specular = 0.7
			tx.rim_enabled = true
			tx.cull_mode = BaseMaterial3D.CULL_DISABLED
			m = tx
		"pont76":
			# un pont de lumière : une dalle translucide qui luit
			var po := _glow(LUEURS.get(v, LUEURS["turquoise"]), 1.6, 0.45)
			po.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			m = po
		"eau76":
			var ea := StandardMaterial3D.new()
			ea.albedo_color = Color(0.45, 0.75, 0.95, 0.55)
			ea.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			ea.roughness = 0.03
			ea.metallic_specular = 1.0
			ea.emission_enabled = true
			ea.emission = Color(0.3, 0.6, 1.0)
			ea.emission_energy_multiplier = 0.3
			m = ea
		"vitre76":
			# une baie : « on » (une lumière douce derrière), « off »
			var vi := StandardMaterial3D.new()
			vi.albedo_color = Color(0.3, 0.36, 0.48)
			vi.roughness = 0.08
			vi.metallic_specular = 0.9
			if v == "on":
				vi.emission_enabled = true
				vi.emission = Color(0.75, 0.85, 1.0)
				vi.emission_energy_multiplier = 0.15
			m = vi
	if m != null:
		_cache[key] = m
	return m


## Les matières qui s'allument la nuit (pour temps_v56.register_glow) : [clé, énergie nuit, énergie jour].
const NIGHT_GLOWS := [["cristal76_bleu", 1.4, 0.35], ["cristal76_violet", 1.4, 0.35], ["cristal76_rose", 1.4, 0.35], ["cristal76_blanc", 1.2, 0.3],
	["cristal76_turquoise", 1.4, 0.35], ["vitre76_on", 1.6, 0.15], ["motif76_bleu", 1.8, 0.6], ["motif76_or", 1.8, 0.6], ["motif76_violet", 1.8, 0.6],
	["feuille76_", 1.2, 0.5], ["petale76_rose", 2.0, 0.9], ["petale76_bleu", 2.0, 0.9], ["petale76_or", 2.0, 0.9], ["petale76_violet", 2.0, 0.9],
	["cristalsol76", 0.3, 0.05], ["roche76", 0.6, 0.08], ["nacre76_", 0.9, 0.25], ["nacre76_bleu", 0.9, 0.25], ["nacre76_rose", 0.9, 0.25],
	["nacre76_lavande", 0.9, 0.25], ["nacre76_or", 0.9, 0.25], ["nacresol76", 0.7, 0.15], ["metal76_", 1.4, 0.5], ["soucoupe76", 2.0, 1.0], ["mousse76", 0.8, 0.2]]


static func night(k: float) -> void:
	for g in NIGHT_GLOWS:
		var m: StandardMaterial3D = make(str(g[0])) as StandardMaterial3D
		if m != null:
			m.emission_energy_multiplier = lerpf(float(g[2]), float(g[1]), k)
