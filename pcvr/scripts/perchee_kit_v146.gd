extends RefCounted
## V146 : la boîte à outils de Pile-ou-Face (l'Île Perchée), un bourg du Far West bâti sur de vieilles
## fondations médiévales et rafistolé à la vapeur :
##  - les matières (le bardage peint qui s'écaille, les planches des trottoirs, la tôle ondulée rouillée,
##    les moellons de grès rouge, la brique, le cuivre, le laiton, le fer riveté, les toiles rayées) ;
##  - le générateur de bâtiments : un rez-de-chaussée sur un soubassement de grès rouge (ou tout en
##    pierre, avec une porte en arc, pour les plus anciens), des étages de bois, la grande fausse façade
##    qui cache le toit (droite, à gradins ou arrondie) et son enseigne, le porche sur le trottoir de
##    planches, le balcon des saloons, les fenêtres à guillotine, les portes battantes ; et la vapeur :
##    des tuyaux de cuivre, des vannes, des manomètres, des rouages qui tournent, des cheminées qui
##    fument, une horloge, des tôles rivetées ;
##  - les objets de la rue : les tonneaux, les caisses, l'abreuvoir, la barre d'attache, les réverbères
##    à gaz, les chariots, les poteaux du télégraphe, les panneaux.
## Tout est fusionné par matière (Lot) ; les collisions sont des boîtes (Cols de geants_kit_v142).

const MetalKit = preload("res://scripts/metal_kit_v160.gd")
const GK = preload("res://scripts/geants_kit_v142.gd")
const MJ := "res://assets/textures/montjoie/"
const BC := "res://assets/textures/boucan/"
const SO := "res://assets/textures/soleils/"
const ST := "res://assets/textures/strates/"
const BR := "res://assets/textures/braise/"
const FONT := "res://assets/fonts/Lora-Bold.ttf"

## Les couleurs des bardages peints (la peinture a passé au soleil).
const PEINTURES := {
	"rouge": Color(1.25, 0.62, 0.52), "bleu": Color(0.68, 0.9, 1.15), "vert": Color(0.78, 1.05, 0.78),
	"creme": Color(1.35, 1.25, 1.05), "jaune": Color(1.4, 1.18, 0.7), "brut": Color(1.0, 0.94, 0.86),
	"gris": Color(0.95, 0.95, 0.95), "brun": Color(0.82, 0.66, 0.54), "turquoise": Color(0.7, 1.12, 1.08),
	"rose": Color(1.3, 0.86, 0.82),
}
static var _cache: Dictionary = {}
static var _font: FontVariation
static var _gear_cache: Dictionary = {}


static func _t(path: String) -> Texture2D:
	return load(path) if ResourceLoader.exists(path) else null


static func _surface(tex: String, normal: String, tint: Color, rough: float, tile: float, nscale: float = 1.0, base := Color(0.7, 0.68, 0.64), metal: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	var t: Texture2D = _t(tex)
	m.albedo_texture = t
	m.albedo_color = tint if t != null else Color(base.r * tint.r, base.g * tint.g, base.b * tint.b)
	var n: Texture2D = _t(normal) if normal != "" else null
	if n != null:
		m.normal_enabled = true
		m.normal_texture = n
		m.normal_scale = nscale
	m.roughness = rough
	m.metallic = metal
	m.uv1_scale = Vector3.ONE / tile
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return m


static func _flat(c: Color, rough: float, metal: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	# V160 : le grain des métaux (le cuivre, le laiton, le fer : metal_kit_v160)
	if metal >= 0.5 and rough >= 0.15:
		MetalKit.habille(m, MetalKit.genre_de(c))
	return m


## Une toile rayée (les auvents) : l'image est faite ici.
static func _rayures(a: Color, b: Color) -> ImageTexture:
	var img := Image.create(64, 8, true, Image.FORMAT_RGB8)
	for x in range(64):
		var c: Color = a if (x / 8) % 2 == 0 else b
		for y in range(8):
			img.set_pixel(x, y, c)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


static func mat(key: String) -> Material:
	if _cache.has(key):
		return _cache[key]
	var m: Material = null
	if key.begins_with("bardage_"):
		var c: Color = PEINTURES.get(key.substr(8), Color(1, 1, 1))
		m = _surface(BC + "bardage.png", BC + "bardage_n.png", c, 0.88, 3.2, 1.0)
	elif key.begins_with("clins_"):
		# des planches posées à l'horizontale (les maisons, les étages)
		var c2: Color = PEINTURES.get(key.substr(6), Color(1, 1, 1))
		m = _surface(MJ + "bois_planches.png", MJ + "bois_planches_n.png", c2 * Color(1.1, 1.08, 1.06), 0.86, 3.0, 1.0)
	elif key.begins_with("toile_"):
		var cols: Dictionary = {"toile_rouge": [Color(0.72, 0.16, 0.12), Color(0.94, 0.9, 0.82)], "toile_verte": [Color(0.22, 0.42, 0.28), Color(0.94, 0.9, 0.82)],
			"toile_bleue": [Color(0.2, 0.32, 0.55), Color(0.94, 0.9, 0.82)], "toile_jaune": [Color(0.9, 0.66, 0.16), Color(0.5, 0.22, 0.12)]}
		var pair: Array = cols.get(key, [Color(0.7, 0.2, 0.15), Color(0.95, 0.9, 0.8)])
		var tm := StandardMaterial3D.new()
		tm.albedo_texture = _rayures(pair[0], pair[1])
		tm.roughness = 0.9
		tm.cull_mode = BaseMaterial3D.CULL_DISABLED
		tm.uv1_scale = Vector3(0.25, 1.0, 1.0)
		# V160 : la toile laisse passer le soleil (vue de dessous, elle luit)
		tm.backlight_enabled = true
		tm.backlight = Color(0.5, 0.5, 0.47)
		m = tm
	else:
		match key:
			"planches":
				m = _surface(MJ + "bois_planches.png", MJ + "bois_planches_n.png", Color(0.92, 0.8, 0.66), 0.9, 2.4, 1.1)
			"planches_sombres":
				m = _surface(MJ + "bois_planches.png", MJ + "bois_planches_n.png", Color(0.58, 0.46, 0.36), 0.9, 2.4, 1.1)
			"poutre":
				m = _surface(MJ + "bois_planches.png", MJ + "bois_planches_n.png", Color(0.6, 0.46, 0.34), 0.86, 2.0, 0.9)
			"bois_peint":
				m = _flat(Color(0.88, 0.84, 0.74), 0.7)
			"bois_vert":
				m = _flat(Color(0.2, 0.36, 0.26), 0.7)
			"bois_rouge":
				m = _flat(Color(0.5, 0.12, 0.08), 0.7)
			"moellons":
				# le grès rouge des vieilles fondations
				m = _surface(MJ + "moellons.png", MJ + "moellons_n.png", Color(1.08, 0.86, 0.74), 0.9, 3.6, 1.3)
			"pierre":
				m = _surface(ST + "gres.png", ST + "gres_n.png", Color(1.12, 0.84, 0.7), 0.86, 4.0, 1.0)
			"pierre_taille":
				m = _surface(ST + "dalles_gres.png", ST + "dalles_gres_n.png", Color(1.15, 0.92, 0.78), 0.82, 3.0, 1.0)
			"brique":
				m = _surface(BC + "brique.png", BC + "brique_n.png", Color(1.0, 0.9, 0.86), 0.88, 3.0, 1.0)
			"adobe":
				m = _surface(SO + "enduit.png", SO + "enduit_n.png", Color(0.98, 0.76, 0.58), 0.95, 4.0, 1.0)
			"stuc_rouge":
				m = _surface(SO + "stuc_rouge.png", SO + "stuc_rouge_n.png", Color(1.0, 0.92, 0.88), 0.9, 4.0, 1.0)
			"tole":
				m = _surface(BC + "tole_rouille.png", BC + "tole_rouille_n.png", Color(1.0, 1.0, 1.0), 0.6, 3.0, 1.2, Color(0.6, 0.4, 0.3), 0.35)
			"tole_peinte":
				m = _surface(BC + "tole_peinte.png", BC + "tole_peinte_n.png", Color(1.0, 1.0, 1.0), 0.6, 3.0, 1.2, Color(0.3, 0.5, 0.5), 0.3)
			"rivets":
				m = _surface(BC + "metal_rivete.png", BC + "metal_rivete_n.png", Color(0.9, 0.86, 0.82), 0.5, 2.0, 1.2, Color(0.4, 0.42, 0.42), 0.6)
			"bardeaux":
				m = _surface(BR + "ardoise.png", BR + "ardoise_n.png", Color(0.85, 0.66, 0.52), 0.85, 2.5, 1.3, Color(0.4, 0.3, 0.25))
			"tuiles":
				m = _surface(BR + "tuiles_rouges.png", BR + "tuiles_rouges_n.png", Color(1.0, 0.9, 0.82), 0.82, 3.0, 1.2, Color(0.6, 0.3, 0.2))
			"cuivre":
				m = _flat(Color(0.86, 0.5, 0.3), 0.32, 0.92)
			"cuivre_vert":
				m = _surface(BR + "cuivre_vert.png", BR + "cuivre_vert_n.png", Color(1, 1, 1), 0.5, 1.5, 1.0, Color(0.3, 0.6, 0.5), 0.5)
			"laiton":
				m = _flat(Color(0.9, 0.72, 0.36), 0.26, 0.95)
			"fer":
				m = _flat(Color(0.13, 0.12, 0.12), 0.45, 0.8)
			"fer_rouille":
				m = _surface(BC + "acier_rouille.png", BC + "acier_rouille_n.png", Color(1, 1, 1), 0.7, 2.0, 1.0, Color(0.45, 0.3, 0.22), 0.4)
			"vanne":
				m = _flat(Color(0.7, 0.1, 0.08), 0.45, 0.4)
			"cadran":
				var cd := _flat(Color(0.95, 0.92, 0.84), 0.4)
				cd.emission_enabled = true
				cd.emission = Color(1.0, 0.95, 0.8)
				cd.emission_energy_multiplier = 0.15
				m = cd
			"vitre":
				var v := _flat(Color(0.2, 0.24, 0.26), 0.08)
				v.metallic_specular = 0.95
				m = v
			"vitre_on":
				var vo := _flat(Color(0.32, 0.27, 0.2), 0.12)
				vo.metallic_specular = 0.9
				vo.emission_enabled = true
				vo.emission = Color(1.0, 0.72, 0.4)
				vo.emission_energy_multiplier = 0.05
				m = vo
			"lampe":
				var lp := _flat(Color(1.0, 0.86, 0.6), 0.3)
				lp.emission_enabled = true
				lp.emission = Color(1.0, 0.78, 0.45)
				lp.emission_energy_multiplier = 0.4
				m = lp
			"sombre":
				m = _flat(Color(0.05, 0.04, 0.035), 1.0)
			"rideau":
				m = _flat(Color(0.55, 0.12, 0.12), 0.9)
			"blanc":
				m = _flat(Color(0.9, 0.88, 0.82), 0.6)
			"or":
				m = _flat(Color(0.95, 0.75, 0.3), 0.25, 1.0)
			"enseigne_fond":
				m = _flat(Color(0.12, 0.09, 0.07), 0.8)
			"enseigne_creme":
				m = _flat(Color(0.88, 0.8, 0.62), 0.8)
			"enseigne_rouge":
				m = _flat(Color(0.48, 0.1, 0.07), 0.75)
			"enseigne_verte":
				m = _flat(Color(0.13, 0.26, 0.18), 0.75)
			"tonneau":
				m = _surface(MJ + "bois_planches.png", MJ + "bois_planches_n.png", Color(0.9, 0.68, 0.5), 0.8, 1.2, 1.0)
			"corde":
				m = _flat(Color(0.62, 0.52, 0.36), 0.95)
			"foin":
				m = GK.mat("foin")
			"eau":
				var e := _flat(Color(0.12, 0.22, 0.2), 0.05)
				e.metallic_specular = 0.9
				m = e
			"cristal":
				var cr := _flat(Color(0.45, 0.75, 1.0), 0.1)
				cr.emission_enabled = true
				cr.emission = Color(0.3, 0.65, 1.0)
				cr.emission_energy_multiplier = 1.2
				m = cr
			"cuir":
				m = _flat(Color(0.36, 0.2, 0.12), 0.75)
			"feuille":
				m = _flat(Color(0.3, 0.42, 0.2), 0.85)
			"cactus":
				m = _flat(Color(0.3, 0.46, 0.28), 0.7)
			"terre_cuite":
				m = _flat(Color(0.72, 0.38, 0.24), 0.86)
	if m == null:
		m = GK.mat(key)
	_cache[key] = m
	return m


## Le lot de maillages de Pile-ou-Face (les matières viennent d'ici).
class Lot:
	extends GK.Batch

	func commit(parent: Node3D, label: String, shadows: bool = true, vis_end: float = 0.0) -> MeshInstance3D:
		if sts.is_empty():
			return null
		var mesh := ArrayMesh.new()
		var kit = load("res://scripts/perchee_kit_v146.gd")
		for k in sts:
			var st: SurfaceTool = sts[k]
			st.index()
			st.generate_tangents()
			st.commit(mesh)
			mesh.surface_set_material(mesh.get_surface_count() - 1, kit.mat(str(k)))
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


# =================================================================== les enseignes

static func police() -> FontVariation:
	if _font == null:
		_font = FontVariation.new()
		var base: Font = load(FONT) if ResourceLoader.exists(FONT) else null
		if base != null:
			_font.base_font = base
		_font.spacing_glyph = 3
		_font.variation_embolden = 0.35
	return _font


## Un texte peint (Label3D, traduit par langue_v104), posé sur un panneau ; « xf » : le centre du
## panneau, Z vers le lecteur.
static func texte(parent: Node3D, txt: String, xf: Transform3D, hauteur: float, col: Color = Color(0.95, 0.85, 0.55), largeur: float = 0.0) -> Label3D:
	var l := Label3D.new()
	l.text = txt
	l.font = police()
	l.font_size = 96
	l.pixel_size = hauteur / 96.0
	l.outline_size = 10
	l.outline_modulate = Color(0.08, 0.05, 0.03, 0.9)
	l.modulate = col
	l.double_sided = false
	l.shaded = true
	l.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	l.visibility_range_end = 140.0
	if largeur > 0.0:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.width = largeur / l.pixel_size
	parent.add_child(l)
	l.global_transform = xf.translated_local(Vector3(0, 0, 0.04))
	return l


## Un panneau peint : une planche, son cadre, et le texte.
static func panneau(b: Lot, parent: Node3D, xf: Transform3D, w: float, h: float, txt: String, fond: String = "enseigne_fond", col: Color = Color(0.95, 0.82, 0.5)) -> void:
	b.box(fond, xf, Vector3(w, h, 0.08))
	for s in [-1.0, 1.0]:
		b.box("poutre", xf * Transform3D(Basis(), Vector3(0, s * (h * 0.5 + 0.04), 0.03)), Vector3(w + 0.16, 0.1, 0.1))
		b.box("poutre", xf * Transform3D(Basis(), Vector3(s * (w * 0.5 + 0.04), 0, 0.03)), Vector3(0.1, h + 0.16, 0.1))
	if txt != "":
		var lignes: int = txt.count("\n") + 1
		texte(parent, txt, xf.translated_local(Vector3(0, 0, 0.05)), minf(h * 0.62 / lignes, w / maxf(float(_plus_longue(txt)), 1.0) * 1.45), col)


static func _plus_longue(txt: String) -> int:
	var n: int = 0
	for l in txt.split("\n"):
		n = maxi(n, l.length())
	return n


# =================================================================== les morceaux

## Une fenêtre à guillotine : cadre blanc, deux châssis, la vitre (allumée la nuit), un appui ; « at » :
## le bas de la fenêtre, au nu du mur ; Z sortant.
static func fenetre(b: Lot, xf: Transform3D, w: float, h: float, allumee: bool, cadre: String = "blanc", volets: String = "") -> void:
	b.box("vitre_on" if allumee else "vitre", xf * Transform3D(Basis(), Vector3(0, h * 0.5, 0.02)), Vector3(w, h, 0.04))
	b.box(cadre, xf * Transform3D(Basis(), Vector3(0, h + 0.07, 0.06)), Vector3(w + 0.3, 0.14, 0.12))
	b.box(cadre, xf * Transform3D(Basis(), Vector3(0, -0.06, 0.1)), Vector3(w + 0.36, 0.1, 0.2))
	for s in [-1.0, 1.0]:
		b.box(cadre, xf * Transform3D(Basis(), Vector3(s * (w * 0.5 + 0.06), h * 0.5, 0.06)), Vector3(0.12, h, 0.12))
	b.box(cadre, xf * Transform3D(Basis(), Vector3(0, h * 0.5, 0.05)), Vector3(w, 0.08, 0.08))
	b.box(cadre, xf * Transform3D(Basis(), Vector3(0, h * 0.25, 0.04)), Vector3(0.05, h * 0.5, 0.05))
	b.box(cadre, xf * Transform3D(Basis(), Vector3(0, h * 0.75, 0.04)), Vector3(0.05, h * 0.5, 0.05))
	# le fronton au-dessus (une petite corniche)
	b.box("poutre", xf * Transform3D(Basis(), Vector3(0, h + 0.2, 0.1)), Vector3(w + 0.5, 0.1, 0.22))
	if volets != "":
		for s2 in [-1.0, 1.0]:
			b.box(volets, xf * Transform3D(Basis(Vector3.UP, s2 * 0.25), Vector3(s2 * (w * 0.5 + 0.12 + w * 0.26), h * 0.5, 0.18)), Vector3(w * 0.5, h, 0.05))


## Une porte : « double » (deux battants), « battantes » (les portes de saloon, à mi-hauteur),
## « arche » (une porte en arc dans la pierre), « simple ». xf : le seuil, au nu du mur.
static func porte(b: Lot, xf: Transform3D, genre: String, w: float = 1.8, h: float = 2.6) -> void:
	match genre:
		"battantes":
			b.box("sombre", xf * Transform3D(Basis(), Vector3(0, h * 0.5, -0.05)), Vector3(w, h, 0.1))
			for s in [-1.0, 1.0]:
				var bx: Transform3D = xf * Transform3D(Basis(), Vector3(s * w * 0.25, 1.35, 0.06))
				b.box("bois_rouge", bx, Vector3(w * 0.48, 1.1, 0.05))
				for k in range(4):
					b.box("bois_peint", bx * Transform3D(Basis(), Vector3(-w * 0.18 + k * w * 0.12, 0.05, 0.03)), Vector3(0.04, 0.7, 0.03))
		"arche":
			b.box("sombre", xf * Transform3D(Basis(), Vector3(0, h * 0.5, -0.05)), Vector3(w, h, 0.1))
			for s2 in [-1.0, 1.0]:
				b.box("planches_sombres", xf * Transform3D(Basis(), Vector3(s2 * w * 0.25, h * 0.42, 0.02)), Vector3(w * 0.48, h * 0.84, 0.08))
				for yy in [0.5, 1.6]:
					b.box("fer", xf * Transform3D(Basis(), Vector3(s2 * w * 0.25, yy, 0.08)), Vector3(w * 0.44, 0.08, 0.04))
			# l'arc : des claveaux
			for k2 in range(9):
				var a: float = PI * k2 / 8.0
				var c := Vector3(cos(a) * (w * 0.5 + 0.18), h * 0.82 + sin(a) * (w * 0.5 + 0.1) * 0.6, 0.08)
				b.box("pierre_taille", xf * Transform3D(Basis(Vector3.BACK, a - PI * 0.5), c), Vector3(0.4, 0.5, 0.24))
		_:
			b.box("planches_sombres" if genre == "simple" else "bois_vert", xf * Transform3D(Basis(), Vector3(0, h * 0.5, 0.0)), Vector3(w, h, 0.1))
			if genre == "double":
				b.box("poutre", xf * Transform3D(Basis(), Vector3(0, h * 0.5, 0.06)), Vector3(0.06, h, 0.04))
				for s3 in [-1.0, 1.0]:
					b.box("vitre", xf * Transform3D(Basis(), Vector3(s3 * w * 0.25, h * 0.68, 0.06)), Vector3(w * 0.3, h * 0.4, 0.03))
			b.box("laiton", xf * Transform3D(Basis(), Vector3(w * 0.36 if genre == "simple" else 0.12, 1.1, 0.09)), Vector3(0.06, 0.18, 0.06))
	# l'encadrement et le linteau
	if genre != "arche":
		for s4 in [-1.0, 1.0]:
			b.box("poutre", xf * Transform3D(Basis(), Vector3(s4 * (w * 0.5 + 0.08), h * 0.5, 0.06)), Vector3(0.16, h, 0.14))
		b.box("poutre", xf * Transform3D(Basis(), Vector3(0, h + 0.1, 0.06)), Vector3(w + 0.5, 0.2, 0.16))


## Une lanterne murale (allumée la nuit).
static func lanterne(b: Lot, xf: Transform3D) -> void:
	b.box("fer", xf * Transform3D(Basis(), Vector3(0, 0, 0.18)), Vector3(0.04, 0.04, 0.36))
	b.cyl("fer", xf * Transform3D(Basis(), Vector3(0, -0.34, 0.36)), 0.1, 0.12, 0.06, 6)
	b.cyl("lampe", xf * Transform3D(Basis(), Vector3(0, -0.28, 0.36)), 0.11, 0.13, 0.3, 6, false)
	b.cyl("fer", xf * Transform3D(Basis(), Vector3(0, 0.02, 0.36)), 0.16, 0.02, 0.14, 6)


## Un rouage (le maillage, gardé en cache) : on le fait tourner.
static func rouage_mesh(r: float, dents: int, ep: float) -> ArrayMesh:
	var key: String = "%.2f_%d_%.2f" % [r, dents, ep]
	if _gear_cache.has(key):
		return _gear_cache[key]
	var b := Lot.new()
	var n: int = dents * 2
	var pts: Array = []
	for i in range(n * 2):
		var a: float = TAU * i / (n * 2)
		var tooth: bool = (i / 2) % 2 == 0
		pts.append(Vector2(cos(a), sin(a)) * (r if tooth else r * 0.86))
	var hz: float = ep * 0.5
	for i2 in range(pts.size()):
		var p0: Vector2 = pts[i2]
		var p1: Vector2 = pts[(i2 + 1) % pts.size()]
		var ri: float = r * 0.32
		var q0: Vector2 = p0.normalized() * ri
		var q1: Vector2 = p1.normalized() * ri
		for z in [hz, -hz]:
			var nn := Vector3(0, 0, signf(z))
			b.quad("laiton", [Vector3(q0.x, q0.y, z), Vector3(p0.x, p0.y, z), Vector3(p1.x, p1.y, z), Vector3(q1.x, q1.y, z)], nn, [q0, p0, p1, q1])
		var sn: Vector3 = Vector3((p0 + p1).x, (p0 + p1).y, 0).normalized()
		b.quad("laiton", [Vector3(p0.x, p0.y, hz), Vector3(p1.x, p1.y, hz), Vector3(p1.x, p1.y, -hz), Vector3(p0.x, p0.y, -hz)], sn, [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)])
	# le moyeu et les rayons
	b.cyl("fer", Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0, -hz * 1.6)), r * 0.16, r * 0.16, ep * 1.6, 10)
	var mesh := ArrayMesh.new()
	for k in b.sts:
		var st: SurfaceTool = b.sts[k]
		st.index()
		st.commit(mesh)
		mesh.surface_set_material(mesh.get_surface_count() - 1, mat(str(k)))
	_gear_cache[key] = mesh
	return mesh


## Un rouage qui tourne (rend le nœud : le bourg le fait tourner).
static func rouage(parent: Node3D, xf: Transform3D, r: float, dents: int = 12, ep: float = 0.18, vitesse: float = 0.4) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = rouage_mesh(r, dents, ep)
	mi.set_meta("vitesse", vitesse)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.visibility_range_end = 120.0
	parent.add_child(mi)
	mi.global_transform = xf
	return mi


## Des tuyaux de cuivre : une colonne le long du mur, des coudes, une vanne, un manomètre.
static func tuyaux(b: Lot, xf: Transform3D, h: float, rng: RandomNumberGenerator) -> void:
	var x0: float = 0.0
	b.tube("cuivre", xf * Vector3(x0, 0.2, 0.22), xf * Vector3(x0, h, 0.22), 0.11, 8)
	b.tube("cuivre", xf * Vector3(x0 + 0.32, 0.2, 0.22), xf * Vector3(x0 + 0.32, h * 0.7, 0.22), 0.08, 8)
	for k in range(int(h / 1.2)):
		var y: float = 0.6 + k * 1.2
		b.cyl("laiton", Transform3D(Basis(), xf * Vector3(x0, y, 0.22)), 0.14, 0.14, 0.08, 8)
		b.box("fer", xf * Transform3D(Basis(), Vector3(x0 + 0.16, y + 0.04, 0.1)), Vector3(0.6, 0.06, 0.06))
	# le coude du haut qui rentre dans le mur
	b.tube("cuivre", xf * Vector3(x0, h, 0.22), xf * Vector3(x0, h, -0.1), 0.11, 8)
	b.blob("cuivre", xf * Vector3(x0, h, 0.22), Vector3(0.13, 0.13, 0.13), 6)
	# la vanne rouge
	var vy: float = rng.randf_range(1.1, 1.6)
	b.tube("laiton", xf * Vector3(x0, vy, 0.22), xf * Vector3(x0, vy, 0.5), 0.04, 6)
	var vxf: Transform3D = Transform3D(xf.basis * Basis(Vector3.RIGHT, PI * 0.5), xf * Vector3(x0, vy, 0.5))
	b.cyl("vanne", vxf, 0.2, 0.2, 0.04, 10, true)
	b.cyl("sombre", vxf.translated_local(Vector3(0, 0.045, 0)), 0.12, 0.12, 0.01, 10, true)
	# le manomètre
	var my: float = vy + 0.6
	var mxf: Transform3D = Transform3D(xf.basis * Basis(Vector3.RIGHT, PI * 0.5), xf * Vector3(x0 + 0.32, my, 0.3))
	b.cyl("laiton", mxf, 0.17, 0.17, 0.08, 12)
	b.cyl("cadran", mxf.translated_local(Vector3(0, 0.081, 0)), 0.14, 0.14, 0.005, 12, true)
	b.box("vanne", Transform3D(xf.basis * Basis(Vector3.BACK, rng.randf_range(-1.2, 1.2)), xf * Vector3(x0 + 0.32, my, 0.4)) * Transform3D(Basis(), Vector3(0, 0.05, 0)), Vector3(0.02, 0.11, 0.01))


# =================================================================== le bâtiment

## Un bâtiment du bourg. « xf » : le pied de la façade, au milieu (le sol du trottoir), Z vers la rue ;
## le bâtiment s'étend vers -Z sur « d ». Clés de « s » :
##  w, d : largeur, profondeur ; etages : 1 à 3 ; h1 : hauteur du rez-de-chaussée ; mur, haut : les
##  matières du rez-de-chaussée et des étages ; base : le soubassement (moellons) ; vieux : tout le
##  rez-de-chaussée en pierre (une porte en arc) ; fronton : « droit », « gradins », « arrondi »,
##  « aucun » (un pignon) ; toit : « tole », « bardeaux », « tuiles » ; porche, balcon : bool ;
##  enseigne : le texte ; porte : « double », « battantes », « arche », « simple » ; vitrine : bool ;
##  auvent : la toile rayée ; vapeur : [« tuyaux », « rouage », « cheminee », « horloge », « rivets »].
## Rend {porte (dehors, monde), out (la sortie), haut (le haut de la façade), cheminees, rouages}.
static func batiment(b: Lot, cols: GK.Cols, parent: Node3D, xf: Transform3D, s: Dictionary, rng: RandomNumberGenerator, nuit: bool = true) -> Dictionary:
	var w: float = float(s.get("w", 10.0))
	var d: float = float(s.get("d", 12.0))
	var etages: int = int(s.get("etages", 1))
	var h1: float = float(s.get("h1", 4.2))
	var he: float = 3.3
	var mur: String = str(s.get("mur", "bardage_brut"))
	var haut: String = str(s.get("haut", mur))
	var vieux: bool = bool(s.get("vieux", false))
	var fronton: String = str(s.get("fronton", "droit"))
	var toit: String = str(s.get("toit", "tole"))
	var H: float = h1 + he * (etages - 1)
	var res := {"rouages": [], "cheminees": [], "lampes": []}
	var hw: float = w * 0.5
	var back: float = -d
	# le soubassement (il descend sous le sol, pour les terrains qui penchent)
	b.box("moellons", xf * Transform3D(Basis(), Vector3(0, -0.6, back * 0.5)), Vector3(w + 0.3, 1.9, d + 0.3))
	# le rez-de-chaussée
	var rdc: String = "moellons" if vieux else mur
	b.box(rdc, xf * Transform3D(Basis(), Vector3(0, 0.35 + (h1 - 0.35) * 0.5, back * 0.5)), Vector3(w, h1 - 0.35, d))
	if vieux:
		# les chaînes d'angle en pierre de taille
		for sx in [-1.0, 1.0]:
			for k in range(int(h1 / 0.7)):
				var long: bool = k % 2 == 0
				b.box("pierre_taille", xf * Transform3D(Basis(), Vector3(sx * (hw - (0.4 if long else 0.25)), 0.35 + k * 0.7 + 0.35, 0.04)), Vector3(0.84 if long else 0.54, 0.66, 0.12))
	# les étages
	if etages > 1:
		b.box(haut, xf * Transform3D(Basis(), Vector3(0, h1 + (H - h1) * 0.5, back * 0.5)), Vector3(w, H - h1, d))
		# le cordon entre les étages
		for e in range(1, etages):
			b.box("poutre", xf * Transform3D(Basis(), Vector3(0, h1 + he * (e - 1), 0.06)), Vector3(w + 0.2, 0.22, 0.18))
	cols.box(xf * Transform3D(Basis(), Vector3(0, H * 0.5, back * 0.5)), Vector3(w, H + 0.6, d))
	# la façade : la porte au milieu, les fenêtres de part et d'autre
	var genre: String = str(s.get("porte", "double"))
	var dw: float = 2.0 if genre in ["double", "battantes", "arche"] else 1.2
	var dh: float = minf(2.7, h1 - 0.9)
	var door_x: float = float(s.get("porte_x", 0.0))
	porte(b, xf * Transform3D(Basis(), Vector3(door_x, 0.35, 0.02)), genre, dw, dh)
	var vitrine: bool = bool(s.get("vitrine", false))
	for side in [-1.0, 1.0]:
		var span0: float = door_x + side * (dw * 0.5 + 0.6)
		var span1: float = side * (hw - 0.6)
		var span: float = (span1 - span0) * side
		if span < 1.2:
			continue
		var mid: float = (span0 + span1) * 0.5
		if vitrine:
			var vw: float = minf(span - 0.4, 4.2)
			fenetre(b, xf * Transform3D(Basis(), Vector3(mid, 1.0, 0.02)), vw, minf(2.2, h1 - 1.8), nuit and rng.randf() < 0.7, "bois_peint")
			b.box("poutre", xf * Transform3D(Basis(), Vector3(mid, 0.68, 0.1)), Vector3(vw + 0.4, 0.66, 0.16))
		else:
			var nf: int = maxi(1, int(span / 2.6))
			for k2 in range(nf):
				var fx: float = span0 + side * (span / nf) * (k2 + 0.5)
				fenetre(b, xf * Transform3D(Basis(), Vector3(fx, 1.25, 0.02)), 1.0, 1.7, nuit and rng.randf() < 0.55, "blanc", "bois_vert" if vieux else "")
	for e2 in range(1, etages):
		var y: float = h1 + he * (e2 - 1) + 0.9
		var nf2: int = maxi(2, int(w / 2.8))
		for k3 in range(nf2):
			var fx2: float = -hw + w * (k3 + 0.5) / nf2
			fenetre(b, xf * Transform3D(Basis(), Vector3(fx2, y, 0.02)), 1.0, 1.75, nuit and rng.randf() < 0.5, "blanc")
	# les fenêtres des côtés (un peu, sur les murs qu'on voit des ruelles)
	for sx2 in [-1.0, 1.0]:
		var sxf: Transform3D = xf * Transform3D(Basis(Vector3.UP, sx2 * PI * 0.5), Vector3(sx2 * hw, 0, back * 0.5))
		for e3 in range(etages):
			var yy: float = 1.25 if e3 == 0 else h1 + he * (e3 - 1) + 0.9
			fenetre(b, sxf * Transform3D(Basis(), Vector3(0, yy, 0.02)), 0.9, 1.5, nuit and rng.randf() < 0.4, "blanc")
	# le toit (à deux pentes, du devant vers l'arrière) et la fausse façade
	var pente: float = minf(w * 0.32, 3.2)
	_toit(b, xf, w, d, H, pente, toit, mur if etages == 1 else haut)
	var top: float = H
	if fronton != "aucun":
		top = _fronton(b, parent, xf, w, H, pente, fronton, mur if etages == 1 else haut)
	# l'enseigne
	var ens: String = str(s.get("enseigne", ""))
	if ens != "":
		var eh: float = 1.2 if fronton != "aucun" else 0.9
		var ey: float = (H + (top - H) * 0.45) if fronton != "aucun" else h1 - 0.55
		if fronton != "aucun" and top - H < 1.0:
			ey = H - 0.8
		var fond: String = str(s.get("enseigne_fond", "enseigne_fond"))
		panneau(b, parent, xf * Transform3D(Basis(), Vector3(0, ey, 0.16)), minf(w - 1.2, maxf(4.0, ens.length() * 0.42)), eh, ens, fond,
			Color(0.95, 0.82, 0.5) if fond in ["enseigne_fond", "enseigne_rouge", "enseigne_verte"] else Color(0.3, 0.12, 0.06))
	res["haut"] = xf * Vector3(0, top, 0)
	# le porche sur le trottoir, ou un auvent
	if bool(s.get("porche", true)):
		_porche(b, cols, xf, w, h1, toit, rng)
		for sx3 in [-1.0, 1.0]:
			lanterne(b, xf * Transform3D(Basis(), Vector3(sx3 * (dw * 0.5 + 0.45) + door_x, dh + 0.6, 0.02)))
			res["lampes"].append(xf * Vector3(sx3 * (dw * 0.5 + 0.45) + door_x, dh + 0.3, 0.4))
	elif str(s.get("auvent", "")) != "":
		_auvent(b, xf, w, h1, str(s.get("auvent", "")))
	if bool(s.get("balcon", false)) and etages > 1:
		_balcon(b, cols, xf, w, h1)
	# la vapeur
	var vap: Array = s.get("vapeur", [])
	if "tuyaux" in vap:
		var tx: float = -hw + 0.5 if rng.randf() < 0.5 else hw - 0.9
		tuyaux(b, xf * Transform3D(Basis(), Vector3(tx, 0.0, 0.0)), H + 0.4, rng)
	if "rivets" in vap:
		b.box("rivets", xf * Transform3D(Basis(), Vector3(0, 0.55, 0.05)), Vector3(w + 0.1, 0.8, 0.1))
		for sx4 in [-1.0, 1.0]:
			b.box("rivets", xf * Transform3D(Basis(), Vector3(sx4 * (hw + 0.02), H * 0.5, -0.3)), Vector3(0.12, H, 0.7))
	if "rouage" in vap and fronton != "aucun":
		var gr: float = minf(1.3, w * 0.12)
		var gx: float = hw - gr - 0.4
		var gy: float = top - gr - 0.3
		res["rouages"].append(rouage(parent, xf * Transform3D(Basis(), Vector3(gx, gy, 0.2)), gr, 12, 0.2, 0.35))
		res["rouages"].append(rouage(parent, xf * Transform3D(Basis(), Vector3(gx - gr * 1.62, gy - gr * 0.55, 0.26)), gr * 0.7, 9, 0.18, -0.35 * 12.0 / 9.0))
	if "horloge" in vap and fronton != "aucun":
		var cy: float = top - 1.1
		var cxf: Transform3D = xf * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, cy, 0.18))
		b.cyl("laiton", cxf, 0.95, 0.95, 0.14, 24)
		b.cyl("cadran", cxf.translated_local(Vector3(0, 0.141, 0)), 0.8, 0.8, 0.01, 24)
		for k4 in range(12):
			var a: float = TAU * k4 / 12.0
			b.box("fer", xf * Transform3D(Basis(Vector3.BACK, a), Vector3(cos(a) * 0.66, cy + sin(a) * 0.66, 0.34)), Vector3(0.12, 0.05, 0.02))
		b.box("fer", xf * Transform3D(Basis(Vector3.BACK, 1.1), Vector3(0.16, cy + 0.22, 0.35)), Vector3(0.05, 0.5, 0.02))
		b.box("fer", xf * Transform3D(Basis(Vector3.BACK, -0.5), Vector3(-0.08, cy + 0.14, 0.36)), Vector3(0.04, 0.34, 0.02))
	if "cheminee" in vap:
		var chx: float = hw * 0.55 * (1.0 if rng.randf() < 0.5 else -1.0)
		var chz: float = back * 0.62
		var chy: float = H + pente * (1.0 - absf(chx) / hw)
		b.cyl("brique", xf * Transform3D(Basis(), Vector3(chx, chy - 1.6, chz)), 0.5, 0.45, 3.4, 10)
		b.cyl("fer", xf * Transform3D(Basis(), Vector3(chx, chy + 1.75, chz)), 0.55, 0.62, 0.3, 10)
		b.cyl("fer_rouille", xf * Transform3D(Basis(), Vector3(chx, chy + 2.05, chz)), 0.3, 0.4, 0.8, 10)
		res["cheminees"].append(xf * Vector3(chx, chy + 2.9, chz))
	res["porte"] = xf * Vector3(door_x, 0.35, 1.3)
	res["out"] = (xf.basis * Vector3.BACK).normalized()
	res["seuil"] = xf * Vector3(door_x, 0.35, 0.3)
	return res


static func _toit(b: Lot, xf: Transform3D, w: float, d: float, H: float, pente: float, toit: String, mur: String) -> void:
	var hw: float = w * 0.5 + 0.35
	var z0: float = 0.0
	var z1: float = -d - 0.4
	var ridge := Vector3(0, H + pente, 0)
	for sx in [-1.0, 1.0]:
		var eave := Vector3(sx * hw, H - 0.15, 0)
		var n: Vector3 = (xf.basis * Vector3(sx * pente, hw, 0)).normalized()
		var p := [xf * (eave + Vector3(0, 0, z0)), xf * (ridge + Vector3(0, 0, z0)), xf * (ridge + Vector3(0, 0, z1)), xf * (eave + Vector3(0, 0, z1))]
		var sl: float = Vector2(hw, pente).length()
		b.quad(toit, p, n, [Vector2(0, 0), Vector2(0, sl), Vector2(-z1, sl), Vector2(-z1, 0)])
		# le dessous du toit (on le voit en levant la tête)
		b.quad("planches_sombres", [p[0] + Vector3.DOWN * 0.08, p[3] + Vector3.DOWN * 0.08, p[2] + Vector3.DOWN * 0.08, p[1] + Vector3.DOWN * 0.08], -n,
			[Vector2(0, 0), Vector2(-z1, 0), Vector2(-z1, sl), Vector2(0, sl)])
	# le pignon arrière
	b.prism(mur, xf * Vector3(-w * 0.5, H, -d + 0.02), xf * Vector3(w * 0.5, H, -d + 0.02), xf * Vector3(0, H + pente - 0.1, -d + 0.02), xf.basis * Vector3(0, 0, 0.2))
	b.tube("poutre", xf * (ridge + Vector3(0, 0.04, z0)), xf * (ridge + Vector3(0, 0.04, z1)), 0.12, 6)


## La fausse façade : le mur de devant monte plus haut que le toit (droite, à gradins, arrondie) ;
## une corniche et ses consoles. Rend la hauteur du sommet.
static func _fronton(b: Lot, parent: Node3D, xf: Transform3D, w: float, H: float, pente: float, genre: String, mur: String) -> float:
	var extra: float = pente + 1.6
	var top: float = H + extra
	match genre:
		"gradins":
			b.box(mur, xf * Transform3D(Basis(), Vector3(0, H + extra * 0.35, 0.0)), Vector3(w, extra * 0.7, 0.3))
			b.box(mur, xf * Transform3D(Basis(), Vector3(0, H + extra * 0.7 + extra * 0.15, 0.0)), Vector3(w * 0.66, extra * 0.3, 0.3))
			b.box(mur, xf * Transform3D(Basis(), Vector3(0, top + 0.4, 0.0)), Vector3(w * 0.32, 0.8, 0.3))
			for c in [[w, H + extra * 0.7], [w * 0.66, H + extra], [w * 0.32, top + 0.8]]:
				b.box("poutre", xf * Transform3D(Basis(), Vector3(0, float(c[1]) + 0.06, 0.12)), Vector3(float(c[0]) + 0.3, 0.16, 0.42))
			top += 0.8
		"arrondi":
			b.box(mur, xf * Transform3D(Basis(), Vector3(0, H + extra * 0.4, 0.0)), Vector3(w, extra * 0.8, 0.3))
			var n: int = 14
			for k in range(n):
				var a0: float = PI * k / n
				var a1: float = PI * (k + 1) / n
				var r: float = w * 0.36
				var cy: float = H + extra * 0.8
				var p0 := Vector3(-cos(a0) * r, cy + sin(a0) * r * 0.55, 0)
				var p1 := Vector3(-cos(a1) * r, cy + sin(a1) * r * 0.55, 0)
				b.prism(mur, xf * Vector3(p0.x, cy, 0.15), xf * Vector3(p1.x, cy, 0.15), xf * Vector3((p0.x + p1.x) * 0.5, maxf(p0.y, p1.y), 0.15), xf.basis * Vector3(0, 0, -0.3))
				b.box(mur, xf * Transform3D(Basis(), Vector3((p0.x + p1.x) * 0.5, cy + (minf(p0.y, p1.y) - cy) * 0.5, 0)), Vector3(absf(p1.x - p0.x) + 0.02, maxf(minf(p0.y, p1.y) - cy, 0.01), 0.3))
				b.tube("poutre", xf * (p0 + Vector3(0, 0.05, 0.12)), xf * (p1 + Vector3(0, 0.05, 0.12)), 0.1, 6)
			b.box("poutre", xf * Transform3D(Basis(), Vector3(0, H + extra * 0.8 + 0.05, 0.12)), Vector3(w + 0.3, 0.14, 0.4))
			top = H + extra * 0.8 + w * 0.36 * 0.55
		_:
			b.box(mur, xf * Transform3D(Basis(), Vector3(0, H + extra * 0.5, 0.0)), Vector3(w, extra, 0.3))
			b.box("poutre", xf * Transform3D(Basis(), Vector3(0, top + 0.1, 0.12)), Vector3(w + 0.5, 0.22, 0.5))
			b.box("poutre", xf * Transform3D(Basis(), Vector3(0, top - 0.12, 0.2)), Vector3(w + 0.3, 0.14, 0.34))
			var nc: int = int(w / 1.2)
			for k2 in range(nc + 1):
				var cx: float = -w * 0.5 + 0.2 + (w - 0.4) * k2 / nc
				b.box("poutre", xf * Transform3D(Basis(), Vector3(cx, top - 0.35, 0.22)), Vector3(0.14, 0.34, 0.3))
	# les montants d'angle (le bois de la façade)
	for sx in [-1.0, 1.0]:
		b.box("poutre", xf * Transform3D(Basis(), Vector3(sx * (w * 0.5 - 0.08), H * 0.5 + 0.35, 0.1)), Vector3(0.2, H - 0.7, 0.18))
	return top


## Le porche : le trottoir de planches (déjà posé par la rue), les poteaux, le toit en pente douce.
static func _porche(b: Lot, cols: GK.Cols, xf: Transform3D, w: float, h1: float, toit: String, rng: RandomNumberGenerator) -> void:
	var dz: float = 2.9
	var y: float = h1 - 0.25
	var n: int = maxi(2, int(w / 3.2) + 1)
	for k in range(n):
		var x: float = -w * 0.5 + 0.2 + (w - 0.4) * k / (n - 1)
		b.box("poutre", xf * Transform3D(Basis(), Vector3(x, (y - 0.4) * 0.5 + 0.35, dz)), Vector3(0.2, y - 0.4 - 0.35, 0.2))
		# les consoles (des aisseliers)
		b.box("poutre", xf * Transform3D(Basis(Vector3.RIGHT, 0.785), Vector3(x, y - 0.75, dz - 0.32)), Vector3(0.12, 0.7, 0.12))
		cols.box(xf * Transform3D(Basis(), Vector3(x, y * 0.5, dz)), Vector3(0.24, y, 0.24))
	b.box("poutre", xf * Transform3D(Basis(), Vector3(0, y - 0.32, dz)), Vector3(w, 0.22, 0.22))
	var roof_n: Vector3 = (xf.basis * Vector3(0, 1.0, 0.18)).normalized()
	var p := [xf * Vector3(-w * 0.5 - 0.15, y - 0.12, dz + 0.4), xf * Vector3(w * 0.5 + 0.15, y - 0.12, dz + 0.4), xf * Vector3(w * 0.5 + 0.15, y + 0.5, 0.0), xf * Vector3(-w * 0.5 - 0.15, y + 0.5, 0.0)]
	b.quad(toit if toit == "tole" else "tole_peinte" if rng.randf() < 0.3 else toit, p, roof_n, [Vector2(0, 0), Vector2(w, 0), Vector2(w, 3.0), Vector2(0, 3.0)])
	b.quad("planches_sombres", [p[0] + Vector3.DOWN * 0.06, p[3] + Vector3.DOWN * 0.06, p[2] + Vector3.DOWN * 0.06, p[1] + Vector3.DOWN * 0.06], -roof_n,
		[Vector2(0, 0), Vector2(0, 3.0), Vector2(w, 3.0), Vector2(w, 0)])


static func _auvent(b: Lot, xf: Transform3D, w: float, h1: float, toile: String) -> void:
	var y: float = h1 - 0.5
	var n: Vector3 = (xf.basis * Vector3(0, 1.0, 0.6)).normalized()
	var p := [xf * Vector3(-w * 0.45, y - 1.0, 1.8), xf * Vector3(w * 0.45, y - 1.0, 1.8), xf * Vector3(w * 0.45, y, 0.05), xf * Vector3(-w * 0.45, y, 0.05)]
	b.quad(toile, p, n, [Vector2(0, 1), Vector2(w * 2.0, 1), Vector2(w * 2.0, 0), Vector2(0, 0)])
	# le lambrequin (la bordure qui pend)
	for k in range(int(w * 0.9 / 0.5)):
		var x: float = -w * 0.45 + 0.25 + k * 0.5
		b.prism(toile, xf * Vector3(x - 0.25, y - 1.0, 1.8), xf * Vector3(x + 0.25, y - 1.0, 1.8), xf * Vector3(x, y - 1.35, 1.8), xf.basis * Vector3(0, 0, 0.02))
	for s in [-1.0, 1.0]:
		b.tube("fer", xf * Vector3(s * w * 0.45, y, 0.05), xf * Vector3(s * w * 0.45, y - 1.0, 1.8), 0.03, 4)


## Le balcon des saloons : un plancher sur le porche, une balustrade tournée.
static func _balcon(b: Lot, cols: GK.Cols, xf: Transform3D, w: float, h1: float) -> void:
	var y: float = h1 + 0.35
	b.box("planches", xf * Transform3D(Basis(), Vector3(0, y, 1.45)), Vector3(w + 0.2, 0.16, 2.9))
	b.box("poutre", xf * Transform3D(Basis(), Vector3(0, y + 1.0, 2.85)), Vector3(w + 0.2, 0.1, 0.12))
	var n: int = int(w / 0.3)
	for k in range(n + 1):
		var x: float = -w * 0.5 + w * k / n
		b.box("bois_peint", xf * Transform3D(Basis(), Vector3(x, y + 0.5, 2.85)), Vector3(0.05, 0.92, 0.05))
	for s in [-1.0, 1.0]:
		b.box("poutre", xf * Transform3D(Basis(), Vector3(s * (w * 0.5 + 0.05), y + 0.5, 1.45)), Vector3(0.1, 1.0, 2.9))


# =================================================================== la rue

## Le trottoir de planches devant une rangée de façades : un plancher sur des solives, ses marches.
static func trottoir(b: Lot, cols: GK.Cols, xf: Transform3D, longueur: float, prof: float = 3.1, marches: Array = []) -> void:
	var y: float = 0.35
	b.box("planches", xf * Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(0, y - 0.06, prof * 0.5)), Vector3(prof, 0.12, longueur))
	b.box("poutre", xf * Transform3D(Basis(), Vector3(0, y - 0.3, prof - 0.1)), Vector3(longueur, 0.5, 0.2))
	b.box("moellons", xf * Transform3D(Basis(), Vector3(0, -0.5, prof * 0.5)), Vector3(longueur, 1.2, prof - 0.2))
	cols.box(xf * Transform3D(Basis(), Vector3(0, y * 0.5 - 0.6, prof * 0.5)), Vector3(longueur, y + 1.2, prof))
	for mx in marches:
		for k in range(2):
			var mz: float = prof + 0.2 + k * 0.32
			b.box("planches", xf * Transform3D(Basis(), Vector3(float(mx), y - 0.15 - k * 0.14, mz)), Vector3(1.8, 0.1, 0.34))
			b.box("poutre", xf * Transform3D(Basis(), Vector3(float(mx), (y - 0.2 - k * 0.14) * 0.5 - 0.2, mz)), Vector3(1.8, y - 0.2 - k * 0.14 + 0.4, 0.3))


static func tonneau(b: Lot, cols: GK.Cols, at: Vector3, couche: bool = false, yaw: float = 0.0) -> void:
	if couche:
		var xf := Transform3D(Basis(Vector3.UP, yaw) * Basis(Vector3.BACK, PI * 0.5), at + Vector3(0.45, 0.42, 0).rotated(Vector3.UP, yaw))
		b.cyl("tonneau", xf, 0.38, 0.38, 0.9, 12)
		b.cyl("fer", xf.translated_local(Vector3(0, 0.15, 0)), 0.4, 0.4, 0.06, 12, false)
		b.cyl("fer", xf.translated_local(Vector3(0, 0.69, 0)), 0.4, 0.4, 0.06, 12, false)
	else:
		b.cyl_at("tonneau", at, 0.36, 0.42, 0.5, 12)
		b.cyl_at("tonneau", at + Vector3.UP * 0.5, 0.42, 0.36, 0.5, 12)
		for yy in [0.12, 0.85]:
			b.cyl("fer", Transform3D(Basis(), at + Vector3.UP * yy), 0.41, 0.41, 0.06, 12, false)
		cols.cyl(at, 0.42, 1.0)


static func caisse(b: Lot, cols: GK.Cols, at: Vector3, s: float, yaw: float) -> void:
	b.box_at("planches", at, Vector3(s, s, s), yaw)
	for k in [-1.0, 1.0]:
		b.box("poutre", Transform3D(Basis(Vector3.UP, yaw), at + Vector3(0, s * 0.5, 0) + Vector3(k * s * 0.5, 0, 0).rotated(Vector3.UP, yaw)), Vector3(0.06, s + 0.02, s + 0.02))
	cols.box_at(at, Vector3(s, s, s), yaw)


static func abreuvoir(b: Lot, cols: GK.Cols, at: Vector3, yaw: float) -> void:
	var xf := Transform3D(Basis(Vector3.UP, yaw), at)
	b.box("planches_sombres", xf * Transform3D(Basis(), Vector3(0, 0.1, 0)), Vector3(2.6, 0.2, 0.9))
	for s in [-1.0, 1.0]:
		b.box("planches_sombres", xf * Transform3D(Basis(), Vector3(0, 0.45, s * 0.42)), Vector3(2.6, 0.7, 0.08))
		b.box("planches_sombres", xf * Transform3D(Basis(), Vector3(s * 1.27, 0.45, 0)), Vector3(0.08, 0.7, 0.9))
	b.box("eau", xf * Transform3D(Basis(), Vector3(0, 0.66, 0)), Vector3(2.48, 0.02, 0.78))
	b.box("fer", xf * Transform3D(Basis(), Vector3(-0.9, 0.82, 0)), Vector3(0.1, 0.05, 0.94))
	# la pompe à bras
	b.cyl("fer", xf * Transform3D(Basis(), Vector3(1.6, 0, 0)), 0.1, 0.08, 1.4, 8)
	b.tube("fer", xf * Vector3(1.6, 1.2, 0), xf * Vector3(1.25, 1.2, 0), 0.05, 6)
	b.tube("fer", xf * Vector3(1.6, 1.4, 0), xf * Vector3(2.2, 1.7, 0), 0.03, 4)
	cols.box(xf * Transform3D(Basis(), Vector3(0, 0.4, 0)), Vector3(2.6, 0.8, 0.9))


static func barre_attache(b: Lot, cols: GK.Cols, xf: Transform3D, l: float) -> void:
	for s in [-1.0, 1.0]:
		b.box("poutre", xf * Transform3D(Basis(), Vector3(s * l * 0.5, 0.5, 0)), Vector3(0.16, 1.2, 0.16))
	b.tube("poutre", xf * Vector3(-l * 0.5 - 0.1, 1.05, 0), xf * Vector3(l * 0.5 + 0.1, 1.05, 0), 0.07, 6)
	cols.box(xf * Transform3D(Basis(), Vector3(0, 0.55, 0)), Vector3(l, 1.1, 0.2))


## Un réverbère à gaz en fonte et laiton (rend la place de la flamme).
static func reverbere(b: Lot, cols: GK.Cols, at: Vector3, yaw: float = 0.0) -> Vector3:
	var xf := Transform3D(Basis(Vector3.UP, yaw), at)
	b.cyl("fer", xf, 0.22, 0.16, 0.6, 8)
	b.cyl("fer", xf * Transform3D(Basis(), Vector3(0, 0.6, 0)), 0.08, 0.06, 3.3, 8)
	b.cyl("laiton", xf * Transform3D(Basis(), Vector3(0, 1.4, 0)), 0.11, 0.11, 0.12, 8)
	b.cyl("laiton", xf * Transform3D(Basis(), Vector3(0, 3.85, 0)), 0.14, 0.18, 0.1, 6)
	b.cyl("lampe", xf * Transform3D(Basis(), Vector3(0, 3.95, 0)), 0.18, 0.24, 0.45, 6, false)
	b.cyl("fer", xf * Transform3D(Basis(), Vector3(0, 4.4, 0)), 0.3, 0.02, 0.28, 6)
	b.box("fer", xf * Transform3D(Basis(), Vector3(0, 3.6, 0)), Vector3(0.8, 0.05, 0.05))
	cols.cyl(at, 0.18, 3.8)
	return at + Vector3(0, 4.15, 0)


## Un chariot bâché (les roues, la caisse, les arceaux, la toile).
static func chariot(b: Lot, cols: GK.Cols, at: Vector3, yaw: float, bache: bool = true) -> void:
	var xf := Transform3D(Basis(Vector3.UP, yaw), at)
	b.box("planches", xf * Transform3D(Basis(), Vector3(0, 1.0, 0)), Vector3(1.7, 0.7, 3.6))
	b.box("planches_sombres", xf * Transform3D(Basis(), Vector3(0, 0.66, 0)), Vector3(1.5, 0.1, 3.8))
	for zz in [-1.25, 1.25]:
		for s in [-1.0, 1.0]:
			var r: float = 0.62 if zz < 0 else 0.5
			var wxf := Transform3D(Basis(Vector3.BACK, PI * 0.5), xf * Vector3(s * 0.95, r, zz))
			wxf.basis = xf.basis * Basis(Vector3.BACK, PI * 0.5)
			b.cyl("fer", wxf.translated_local(Vector3(0, -0.04, 0)), r, r, 0.08, 16, false)
			b.cyl("poutre", wxf.translated_local(Vector3(0, -0.06, 0)), r - 0.06, r - 0.06, 0.12, 16, true)
			b.cyl("fer", wxf.translated_local(Vector3(0, -0.12, 0)), 0.1, 0.1, 0.24, 8)
	b.tube("poutre", xf * Vector3(0, 0.6, 1.8), xf * Vector3(0, 0.4, 3.6), 0.06, 6)
	if bache:
		var n: int = 10
		for k in range(n):
			var a0: float = PI * k / n
			var a1: float = PI * (k + 1) / n
			var p0 := Vector3(-cos(a0) * 0.92, 1.35 + sin(a0) * 1.2, 0)
			var p1 := Vector3(-cos(a1) * 0.92, 1.35 + sin(a1) * 1.2, 0)
			var nn: Vector3 = xf.basis * Vector3(-cos((a0 + a1) * 0.5), sin((a0 + a1) * 0.5), 0)
			b.quad("toile", [xf * (p0 + Vector3(0, 0, -1.7)), xf * (p1 + Vector3(0, 0, -1.7)), xf * (p1 + Vector3(0, 0, 1.5)), xf * (p0 + Vector3(0, 0, 1.5))], nn,
				[Vector2(k * 0.4, 0), Vector2((k + 1) * 0.4, 0), Vector2((k + 1) * 0.4, 3.2), Vector2(k * 0.4, 3.2)])
	cols.box(xf * Transform3D(Basis(), Vector3(0, 1.2, 0)), Vector3(1.9, 2.4, 3.8))


## Un poteau du télégraphe (rend le haut, pour tendre les fils).
static func poteau(b: Lot, at: Vector3, yaw: float) -> Vector3:
	var xf := Transform3D(Basis(Vector3.UP, yaw), at)
	b.cyl("poutre", xf, 0.14, 0.11, 7.0, 8)
	b.box("poutre", xf * Transform3D(Basis(), Vector3(0, 6.4, 0)), Vector3(1.6, 0.14, 0.14))
	for s in [-0.65, 0.65]:
		b.cyl("blanc", xf * Transform3D(Basis(), Vector3(s, 6.47, 0)), 0.06, 0.04, 0.16, 6)
	return at + Vector3(0, 6.55, 0)


static func fil(b: Lot, a: Vector3, c: Vector3, mou: float = 0.6) -> void:
	var n: int = 8
	for k in range(n):
		var t0: float = float(k) / n
		var t1: float = float(k + 1) / n
		var p0: Vector3 = a.lerp(c, t0) + Vector3.DOWN * mou * 4.0 * t0 * (1.0 - t0)
		var p1: Vector3 = a.lerp(c, t1) + Vector3.DOWN * mou * 4.0 * t1 * (1.0 - t1)
		b.tube("fer", p0, p1, 0.015, 3)


## Un cactus en pot (sur les trottoirs).
static func pot_cactus(b: Lot, at: Vector3, rng: RandomNumberGenerator) -> void:
	b.cyl_at("terre_cuite", at, 0.22, 0.3, 0.45, 10)
	var h: float = rng.randf_range(0.6, 1.1)
	b.cyl_at("cactus", at + Vector3.UP * 0.4, 0.12, 0.1, h, 8)
	b.blob("cactus", at + Vector3.UP * (0.4 + h), Vector3(0.1, 0.08, 0.1), 6)
	if rng.randf() < 0.6:
		var s: float = 1.0 if rng.randf() < 0.5 else -1.0
		b.tube("cactus", at + Vector3(0, 0.4 + h * 0.5, 0), at + Vector3(s * 0.22, 0.4 + h * 0.5, 0), 0.07, 6)
		b.tube("cactus", at + Vector3(s * 0.22, 0.4 + h * 0.5, 0), at + Vector3(s * 0.22, 0.4 + h * 0.85, 0), 0.07, 6)
