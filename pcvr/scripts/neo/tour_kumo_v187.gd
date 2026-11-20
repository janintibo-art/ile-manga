extends Node3D
## V187 : la Tour Kumo, le siège de Kumo Logistique, à l'angle du Quai des Drones et du Boulevard des Néons.
## Le premier immeuble de Néopolis fait à la main (avant : deux boîtes empilées, et un seul matériau qui
## peignait les fenêtres, le rideau de fer et la vitrine de toute la ville). C'est l'immeuble que l'on voit en
## débarquant : la maison des drones livreurs.
##   - au pied, sur le quai : le dépôt des drones (une porte ouverte sur les rayonnages de colis et un drone
##     en charge, l'autre rideau baissé aux deux tiers, peint au nuage de Kumo), et l'entrée de la tour ;
##   - sur le boulevard : le mur de casiers à colis de Kumo Express, la vitrine où les colis défilent sur un
##     tapis roulant, le guichet et son auvent rayé ;
##   - derrière : le quai de chargement, les palettes, l'escalier de secours qui zigzague jusqu'à la terrasse ;
##     dans la ruelle : les gaines, les climatiseurs, la grande fresque du nuage ;
##   - les étages : de vraies vitres, avec une pièce en profondeur derrière chacune (shaders/vitre_v187) ;
##     l'étage des serveurs et ses lumières qui clignotent ; le jardin suspendu, en loggia, d'où pendent les
##     plantes ; les nids où les drones se posent ;
##   - la terrasse du retrait, ses parasols ; tout en haut, l'enseigne KUMO au néon et la plate-forme des
##     drones ; et six drones qui tournent autour de la tour, leurs colis sous le ventre.
## L'intérieur (tours_v153) n'a pas changé : on y entre par la même porte.

const IleScript = preload("res://scripts/ile_neo_v94.gd")
const Kit = preload("res://scripts/neo_kit_v94.gd")
const TEX := "res://assets/textures/neo187/"
const E: float = 3.5                  # la hauteur d'un étage
const SORTES := ["hangar", "bureaux", "cafeteria", "bureaux", "bureaux", "serveurs", "bureaux", "jardin", "cafeteria", "bureaux", "bureaux", "bureaux", "direction"]

var N: Node3D
var bt: Dictionary
var Y0: float = 1.4
var R0: Array = []                    # le socle (étages 0 à 8) : [x0, z0, x1, z1], repère de la ville
var R1: Array = []                    # le retrait (étages 9 à 12)
var YT: float = 0.0                   # la terrasse du retrait
var YH: float = 0.0                   # le toit
var b: Kit.Batch
var bd: Kit.Batch                     # ce qui est dans le volume de la tour (caché quand on est dedans)
var _vt: SurfaceTool                  # les vitres
var _vtd: SurfaceTool                 # les vitres du fond des loggias
var _rng := RandomNumberGenerator.new()
var dedans: Node3D
var tid: int = -1
var _mats_nuit: Array = []
var _drones: Array = []               # {n, c, rx, rz, y, v, ph, bob}
var _colis: Array = []                # les colis du tapis roulant : [nœud, départ, direction, longueur, phase]
var _t: float = 0.0
var _nuit_vue: float = -1.0
var nb_vitres: int = 0


func build(neo: Node3D, batiment: Dictionary) -> void:
	N = neo
	bt = batiment
	name = "Tour_Kumo_v187"
	Y0 = IleScript.Y0
	var segs: Array = bt["segs"]
	R0 = [float(segs[0][0]), float(segs[0][1]), float(segs[0][2]), float(segs[0][3])]
	R1 = [float(segs[1][0]), float(segs[1][1]), float(segs[1][2]), float(segs[1][3])]
	YT = float(segs[0][5])
	YH = float(segs[1][5])
	_rng.seed = 18700
	_matieres()
	b = Kit.Batch.new()
	bd = Kit.Batch.new()
	_vt = SurfaceTool.new()
	_vt.begin(Mesh.PRIMITIVE_TRIANGLES)
	_vtd = SurfaceTool.new()
	_vtd.begin(Mesh.PRIMITIVE_TRIANGLES)
	dedans = Node3D.new()
	dedans.name = "Kumo_dedans"
	add_child(dedans)
	var F0: Array = _faces(R0)
	var F1: Array = _faces(R1)
	for f in range(4):
		_colonnes(F0[f], Y0, YT, true)
		_colonnes(F1[f], YT, Y0 + 13.0 * E, false)
		for k in range(1, 13):
			_etage(F0[f] if k < 9 else F1[f], k, f)
		_couronne(F1[f], f)
	_pied_quai(F0[0])
	_pied_boulevard(F0[1])
	_pied_ruelle(F0[2])
	_pied_service(F0[3])
	_ecran_et_enseignes(F0, F1)
	_nids(F0)
	_terrasse(F0)
	_toit()
	b.commit(self, "Kumo_dehors")
	bd.commit(dedans, "Kumo_dedans_mesh")
	_pose_vitres(_vt, self, "Kumo_vitres")
	_pose_vitres(_vtd, dedans, "Kumo_vitres_loggia")
	_vole()
	_lumieres(F0)
	print("ILE_MANGA_V187: la Tour Kumo (%d vitres, %d drones en vol)" % [nb_vitres, _drones.size()])


# =================================================================== le repère des façades

## Les quatre façades d'un rectangle : 0 le nord (le quai), 1 l'est (le boulevard), 2 le sud (la ruelle),
## 3 l'ouest (le service). o : le coin de gauche (vu du dehors) ; u : vers la droite ; n : vers le dehors.
func _faces(r: Array) -> Array:
	var x0: float = r[0]
	var z0: float = r[1]
	var x1: float = r[2]
	var z1: float = r[3]
	return [
		{"o": Vector2(x1, z0), "u": Vector2(-1, 0), "n": Vector2(0, -1), "l": x1 - x0},
		{"o": Vector2(x1, z1), "u": Vector2(0, -1), "n": Vector2(1, 0), "l": z1 - z0},
		{"o": Vector2(x0, z1), "u": Vector2(1, 0), "n": Vector2(0, 1), "l": x1 - x0},
		{"o": Vector2(x0, z0), "u": Vector2(0, 1), "n": Vector2(-1, 0), "l": z1 - z0}]


## Un point d'une façade : s le long du mur (m), y la hauteur (absolue), d vers le dehors.
func _p(f: Dictionary, s: float, y: float, d: float) -> Vector3:
	var q: Vector2 = (f["o"] as Vector2) + (f["u"] as Vector2) * s + (f["n"] as Vector2) * d
	return IleScript.W(q.x, q.y, y)


func _u3(f: Dictionary) -> Vector3:
	return Vector3((f["u"] as Vector2).x, 0.0, (f["u"] as Vector2).y)


func _n3(f: Dictionary) -> Vector3:
	return Vector3((f["n"] as Vector2).x, 0.0, (f["n"] as Vector2).y)


func _base(f: Dictionary) -> Basis:
	return Basis(_u3(f), Vector3.UP, _n3(f))


## Une boîte posée sur une façade : de s0 à s1 le long du mur, de y0 à y1, de d0 à d1 vers le dehors.
func _fb(lot: Kit.Batch, key: String, f: Dictionary, s0: float, s1: float, y0: float, y1: float, d0: float, d1: float) -> void:
	lot.box(key, Transform3D(_base(f), _p(f, (s0 + s1) * 0.5, (y0 + y1) * 0.5, (d0 + d1) * 0.5)), Vector3(absf(s1 - s0), absf(y1 - y0), absf(d1 - d0)))


## Une vitre : sa pièce en profondeur (shaders/vitre_v187). chaud : la couleur de sa lumière ; p_allume : la
## chance qu'elle soit allumée la nuit.
func _vitre(st: SurfaceTool, f: Dictionary, s0: float, s1: float, y0: float, y1: float, d: float, chaud: float, p_allume: float, store_max: float = 0.7) -> void:
	var col := Color(_rng.randf(), clampf(chaud + _rng.randf_range(-0.12, 0.12), 0.0, 1.0),
		0.0 if _rng.randf() < 0.45 else _rng.randf_range(0.1, store_max), 1.0 if _rng.randf() < p_allume else 0.0)
	var n: Vector3 = _n3(f)
	var tg := Plane(_u3(f), 1.0)
	var sz := Vector2(s1 - s0, y1 - y0)
	var pts: Array = [_p(f, s0, y0, d), _p(f, s1, y0, d), _p(f, s1, y1, d), _p(f, s0, y1, d)]
	var uvs: Array = [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]
	for i in [0, 2, 1, 0, 3, 2]:
		st.set_normal(n)
		st.set_tangent(tg)
		st.set_color(col)
		st.set_uv(uvs[i])
		st.set_uv2(sz)
		st.add_vertex(pts[i])
	nb_vitres += 1


## Un panneau à plat sur une façade, son image dans le bon sens (de gauche à droite vue du dehors) ;
## rep : combien de fois l'image se répète (en largeur, en hauteur).
func _panneau(key: String, f: Dictionary, s0: float, s1: float, y0: float, y1: float, d: float, rep: Vector2 = Vector2.ONE) -> void:
	b.quad(key, [_p(f, s0, y0, d), _p(f, s1, y0, d), _p(f, s1, y1, d), _p(f, s0, y1, d)], _n3(f),
		[Vector2(0, rep.y), Vector2(rep.x, rep.y), Vector2(rep.x, 0), Vector2(0, 0)])


func _pose_vitres(st: SurfaceTool, parent: Node3D, nom: String) -> void:
	var mesh: ArrayMesh = st.commit()
	if mesh == null or mesh.get_surface_count() == 0:
		return
	mesh.surface_set_material(0, Kit.mat("k187_vitre"))
	var mi := MeshInstance3D.new()
	mi.name = nom
	mi.mesh = mesh
	parent.add_child(mi)


# =================================================================== les matières

func _tex(nom: String) -> Texture2D:
	var chemin: String = TEX + nom
	return load(chemin) if ResourceLoader.exists(chemin) else null


func _matieres() -> void:
	if Kit._mcache.has("k187_bardage"):
		for k in ["k187_vitre", "k187_leds"]:
			_mats_nuit.append(Kit._mcache[k])
		return
	var pan: String = "res://assets/textures/neo156/panneaux_metal.png"
	for def in [["k187_bardage", Color(0.4, 0.44, 0.51), 0.55, 0.45], ["k187_allege", Color(0.56, 0.61, 0.68), 0.5, 0.5], ["k187_clair", Color(0.74, 0.77, 0.8), 0.3, 0.6]]:
		var m := StandardMaterial3D.new()
		m.albedo_color = def[1]
		m.metallic = def[2]
		m.roughness = def[3]
		if ResourceLoader.exists(pan):
			m.albedo_texture = load(pan)
			m.uv1_scale = Vector3(0.5, 0.5, 0.5)
			if ResourceLoader.exists(pan.replace(".png", "_n.png")):
				m.normal_enabled = true
				m.normal_texture = load(pan.replace(".png", "_n.png"))
		Kit._mcache[def[0]] = m
	var orange := StandardMaterial3D.new()
	orange.albedo_color = Color(0.95, 0.42, 0.06)
	orange.roughness = 0.45
	orange.metallic = 0.2
	Kit._mcache["k187_orange"] = orange
	for def2 in [["k187_rideau", "rideau_kumo.png", Vector3(1.0, 1.0, 1.0), 0.6, 0.5], ["k187_danger", "danger.png", Vector3(1.0, 1.0, 1.0), 0.0, 0.7],
			["k187_carton", "carton.png", Vector3(1.6, 1.6, 1.6), 0.0, 0.85]]:
		var m2 := StandardMaterial3D.new()
		m2.albedo_texture = _tex(def2[1])
		m2.uv1_scale = def2[2]
		m2.metallic = def2[3]
		m2.roughness = def2[4]
		Kit._mcache[def2[0]] = m2
	var cas := StandardMaterial3D.new()
	cas.albedo_texture = _tex("casiers.png")
	cas.metallic = 0.5
	cas.roughness = 0.4
	cas.emission_enabled = true
	cas.emission_texture = _tex("casiers_e.png")
	cas.emission_energy_multiplier = 2.5
	Kit._mcache["k187_casiers"] = cas
	for def3 in [["k187_feuillage", Color(0.13, 0.42, 0.16)], ["k187_feuillage_clair", Color(0.3, 0.56, 0.2)], ["k187_fleurs", Color(0.95, 0.5, 0.65)]]:
		var m3 := StandardMaterial3D.new()
		m3.albedo_color = def3[1]
		m3.roughness = 0.85
		Kit._mcache[def3[0]] = m3
	var vit := ShaderMaterial.new()
	vit.shader = load("res://shaders/vitre_v187.gdshader")
	Kit._mcache["k187_vitre"] = vit
	var leds := ShaderMaterial.new()
	leds.shader = load("res://shaders/leds_v187.gdshader")
	Kit._mcache["k187_leds"] = leds
	_mats_nuit = [vit, leds]


## Une image lumineuse (une enseigne au néon, ou l'écran) : un panneau tourné vers « face ».
func _image(nom: String, at: Vector3, face: Vector3, size: Vector2, ecran: bool = false, force: float = 2.8) -> MeshInstance3D:
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/ecran_v94.gdshader")
	m.set_shader_parameter("image", _tex(nom))
	m.set_shader_parameter("ecran", ecran)
	m.set_shader_parameter("force", force)
	m.set_shader_parameter("graine", float(_mats_nuit.size()) * 0.41)
	if ecran:
		m.set_shader_parameter("pages", 4.0)
		m.set_shader_parameter("duree_page", 7.0)
	if N.get("ecran_mats") != null:
		(N.get("ecran_mats") as Array).append(m)
	var q := QuadMesh.new()
	q.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = q
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	mi.global_transform = Transform3D(Basis(Vector3.UP, atan2(face.x, face.z)), at)
	return mi


## Une image peinte sur un mur (la fresque), sans lumière propre.
func _peinture(nom: String, at: Vector3, face: Vector3, size: Vector2) -> void:
	var m := StandardMaterial3D.new()
	m.albedo_texture = _tex(nom)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.9
	var q := QuadMesh.new()
	q.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = q
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	mi.global_transform = Transform3D(Basis(Vector3.UP, atan2(face.x, face.z)), at)


# =================================================================== les étages

func _yk(k: int) -> float:
	return Y0 + float(k) * E


## Les poteaux d'une façade (un toutes les travées), sur toute la hauteur d'un volume.
func _colonnes(f: Dictionary, y0: float, y1: float, socle: bool) -> void:
	var l: float = f["l"]
	for i in range(5):
		var c: float = l * float(i) / 4.0
		_fb(b, "k187_bardage", f, c - 0.26, c + 0.26, y0 + (E if socle else 0.0), y1, 0.0, 0.26)
		if i > 0 and i < 4:
			# un fin couvre-joint clair sur le nez du poteau
			_fb(b, "k187_clair", f, c - 0.05, c + 0.05, y0 + (E if socle else 0.0), y1, 0.26, 0.3)


## Un étage courant d'une façade : le bandeau du plancher, les allèges, les vitres et leurs montants.
func _etage(f: Dictionary, k: int, face: int) -> void:
	var l: float = f["l"]
	var y: float = _yk(k)
	var sorte: String = SORTES[k]
	_fb(b, "k187_bardage", f, 0.0, l, y - 0.22, y + 0.22, 0.0, 0.14)
	# la ruelle : sous la fresque, le mur est plein (étages 1 à 3, les deux travées du milieu)
	for i in range(4):
		var s0: float = l * float(i) / 4.0 + 0.26
		var s1: float = l * float(i + 1) / 4.0 - 0.26
		if face == 2 and k >= 1 and k <= 3 and (i == 1 or i == 2):
			_fb(b, "k187_allege", f, s0 - 0.26, s1 + 0.26, y + 0.22, y + E - 0.22, -0.1, 0.02)
			continue
		if sorte == "serveurs":
			# des persiennes, et derrière, les lumières des machines
			_fb(b, "k187_leds", f, s0, s1, y + 0.22, y + E - 0.22, -0.1, 0.05)
			_fb(b, "k187_orange", f, s0, s1, y + 0.22, y + 0.3, 0.05, 0.09)
			continue
		if sorte == "jardin" and face <= 1:
			_loggia(f, s0, s1, y)
			continue
		# l'allège, puis trois vitres
		_fb(b, "k187_allege", f, s0, s1, y + 0.22, y + 0.95, -0.1, 0.06)
		var chaud: float = 0.2
		var p: float = 0.42
		if sorte == "cafeteria":
			chaud = 0.9
			p = 0.85
		elif sorte == "direction":
			chaud = 0.7
			p = 0.7
		elif sorte == "jardin":
			chaud = 0.6
			p = 0.6
		var nv: int = 3
		var w: float = (s1 - s0) / float(nv)
		for j in range(nv):
			_vitre(_vt, f, s0 + w * j + 0.035, s0 + w * (j + 1) - 0.035, y + 0.95, y + E - 0.22, 0.02, chaud, p)
			if j > 0:
				_fb(b, "metal_noir", f, s0 + w * j - 0.035, s0 + w * j + 0.035, y + 0.95, y + E - 0.22, -0.02, 0.1)
		if sorte == "direction":
			_fb(b, "k187_orange", f, s0, s1, y + 0.9, y + 0.95, 0.06, 0.09)


## Le jardin suspendu (7e) : une loggia ouverte sur le quai et le boulevard, ses bacs, ses plantes qui pendent.
func _loggia(f: Dictionary, s0: float, s1: float, y: float) -> void:
	var prof: float = 2.6
	var yb: float = y + 0.22
	var yh: float = y + E - 0.22
	_fb(bd, "bois", f, s0 - 0.26, s1 + 0.26, yb - 0.04, yb, -prof, 0.0)
	_fb(bd, "beton_clair", f, s0 - 0.26, s1 + 0.26, yh, yh + 0.04, -prof, 0.0)
	# le fond : des baies vitrées (la serre du jardin), une lumière chaude
	var nv: int = 3
	var w: float = (s1 - s0 + 0.52) / float(nv)
	for j in range(nv):
		_vitre(_vtd, f, s0 - 0.26 + w * j + 0.04, s0 - 0.26 + w * (j + 1) - 0.04, yb, yh, -prof, 0.75, 0.9, 0.0)
	# le bac, en garde-corps, et ce qui y pousse
	_fb(b, "metal_noir", f, s0, s1, yb, yb + 0.55, -0.5, 0.0)
	_fb(bd, "terre_bac", f, s0 + 0.05, s1 - 0.05, yb + 0.5, yb + 0.56, -0.45, -0.05)
	_fb(b, "verre", f, s0, s1, yb + 0.55, yb + 1.1, -0.04, 0.0)
	var n: int = int((s1 - s0) / 0.55)
	for i in range(n):
		var s: float = s0 + (float(i) + 0.5) * (s1 - s0) / float(n)
		var r: float = _rng.randf_range(0.28, 0.5)
		var key: String = "k187_feuillage" if _rng.randf() < 0.6 else "k187_feuillage_clair"
		b.blob(key, _p(f, s, yb + 0.6 + r * 0.5, -0.2 + _rng.randf_range(-0.1, 0.2)), Vector3(r * 1.1, r * 0.8, r), 6)
		if _rng.randf() < 0.55:
			# une liane qui pend le long de la façade
			var ll: float = _rng.randf_range(0.6, 2.4)
			_fb(b, key, f, s - 0.07, s + 0.07, yb - ll, yb + 0.4, 0.14, 0.2)
			b.blob(key, _p(f, s, yb - ll, 0.2), Vector3(0.16, 0.2, 0.12), 5)
		if _rng.randf() < 0.3:
			b.blob("k187_fleurs", _p(f, s + 0.1, yb + 0.75 + r * 0.6, 0.05), Vector3(0.12, 0.1, 0.12), 5)
	# deux petits arbres, et des lanternes
	for sa in [s0 + 0.9, s1 - 0.9]:
		bd.cyl_at("ecorce", _p(f, sa, yb, -1.5), 0.07, 0.05, 1.5, 6)
		bd.blob("k187_feuillage_clair", _p(f, sa, yb + 1.9, -1.5), Vector3(0.75, 0.6, 0.75), 7)
	b.blob("lampe_chaude", _p(f, (s0 + s1) * 0.5, yh - 0.35, -0.9), Vector3(0.16, 0.16, 0.16), 6)


## Le haut du retrait : l'étage technique, plein, ses persiennes, son liseré de lumière.
func _couronne(f: Dictionary, _face: int) -> void:
	var l: float = f["l"]
	var y0: float = _yk(13)
	_fb(b, "k187_bardage", f, 0.0, l, y0 - 0.22, YH, -0.3, 0.1)
	var y: float = y0 + 0.5
	while y < YH - 0.7:
		_fb(b, "metal_noir", f, 0.5, l - 0.5, y, y + 0.1, 0.1, 0.2)
		y += 0.32
	_fb(b, "neon_cyan", f, 0.0, l, YH - 0.28, YH - 0.2, 0.1, 0.16)
	_fb(b, "k187_clair", f, -0.1, l + 0.1, YH - 0.12, YH + 0.25, -0.3, 0.2)


# =================================================================== le pied, côté quai (le dépôt, l'entrée)

func _pied_quai(f: Dictionary) -> void:
	var l: float = f["l"]
	var yl: float = Y0 + 2.75                 # le haut des portes
	var yh: float = Y0 + E - 0.22
	var mid: float = l * 0.5
	# le linteau, son liseré, les poteaux
	_fb(b, "k187_bardage", f, 0.0, l, yl, yh, -0.3, 0.14)
	_fb(b, "neon_cyan", f, 0.3, l - 0.3, yl + 0.02, yl + 0.07, 0.14, 0.19)
	for pr in [[0.0, 0.6], [7.0, mid - 1.8], [mid + 1.8, l - 7.0], [l - 0.6, l]]:
		_fb(b, "k187_bardage", f, pr[0], pr[1], Y0, yl, -0.3, 0.2)
	for s in [7.0 + (mid - 1.8 - 7.0) * 0.5, mid + 1.8 + (l - 7.0 - mid - 1.8) * 0.5]:
		# sur chaque trumeau : une borne d'appel, son écran
		_fb(b, "in_ecran", f, s - 0.3, s + 0.3, Y0 + 1.2, Y0 + 1.75, 0.2, 0.24)
		_fb(b, "k187_orange", f, s - 0.36, s + 0.36, Y0 + 1.12, Y0 + 1.83, 0.19, 0.21)
	# ---- l'entrée de la tour : le sas en retrait, les portes de verre, l'auvent
	_fb(b, "k187_bardage", f, mid - 1.8, mid - 1.6, Y0, yl, -1.1, -0.3)
	_fb(b, "k187_bardage", f, mid + 1.6, mid + 1.8, Y0, yl, -1.1, -0.3)
	_fb(b, "in_plafonnier", f, mid - 1.6, mid + 1.6, yl - 0.05, yl, -1.1, -0.3)
	for sg in [-1.0, 1.0]:
		_fb(b, "verre_fume", f, mid + sg * 0.05, mid + sg * 1.6, Y0, yl - 0.05, -1.08, -1.04)
		_fb(b, "chrome", f, mid + sg * 0.16, mid + sg * 0.2, Y0 + 0.9, Y0 + 1.6, -1.04, -0.99)
	_fb(b, "metal_noir", f, mid - 0.05, mid + 0.05, Y0, yl - 0.05, -1.1, -1.02)
	_fb(b, "metal_noir", f, mid - 1.4, mid + 1.4, Y0, Y0 + 0.012, -1.0, 1.4)
	_fb(b, "metal_noir", f, mid - 2.6, mid + 2.6, yl + 0.1, yl + 0.24, 0.0, 2.0)
	_fb(b, "neon_cyan", f, mid - 2.6, mid + 2.6, yl + 0.12, yl + 0.18, 2.0, 2.05)
	for sg2 in [-1.0, 1.0]:
		_fb(b, "lampe_blanche", f, mid + sg2 * 1.3 - 0.4, mid + sg2 * 1.3 + 0.4, yl + 0.07, yl + 0.1, 0.5, 1.2)
		b.tube("chrome", _p(f, mid + sg2 * 2.5, yl + 0.24, 1.9), _p(f, mid + sg2 * 2.5, yl + 1.5, 0.15), 0.03, 6)
	# ---- le dépôt ouvert (à gauche, vu du quai) : les rayonnages, le drone en charge
	var a0: float = 0.6
	var a1: float = 7.0
	var prof: float = 5.0
	_fb(bd, "beton", f, a0, a1, Y0 - 0.02, Y0 + 0.01, -prof, -0.3)
	_fb(b, "k187_danger", f, a0, a1, Y0 + 0.012, Y0 + 0.02, -0.3, 0.3)
	_fb(bd, "beton_clair", f, a0, a1, Y0, yl, -prof - 0.1, -prof)
	_fb(bd, "beton_clair", f, a0 - 0.1, a0, Y0, yl, -prof, -0.3)
	_fb(bd, "beton_clair", f, a1, a1 + 0.1, Y0, yl, -prof, -0.3)
	_fb(bd, "metal_noir", f, a0, a1, yl - 0.06, yl, -prof, -0.3)
	for d in [-1.4, -3.4]:
		_fb(bd, "lampe_blanche", f, a0 + 0.8, a1 - 0.8, yl - 0.09, yl - 0.06, d - 0.12, d + 0.12)
	# les rayonnages du fond, et leurs colis
	for niv in range(4):
		var ys: float = Y0 + 0.25 + float(niv) * 0.62
		_fb(bd, "metal", f, a0 + 0.3, a1 - 0.3, ys, ys + 0.04, -prof + 0.05, -prof + 0.75)
		var s: float = a0 + 0.4
		while s < a1 - 0.9:
			var w: float = _rng.randf_range(0.3, 0.7)
			if _rng.randf() < 0.85:
				var h: float = _rng.randf_range(0.2, 0.5)
				_fb(bd, "k187_carton", f, s, s + w, ys + 0.04, ys + 0.04 + h, -prof + 0.12, -prof + 0.12 + _rng.randf_range(0.3, 0.55))
			s += w + _rng.randf_range(0.04, 0.2)
	for s2 in [a0 + 0.3, (a0 + a1) * 0.5, a1 - 0.3]:
		_fb(bd, "k187_orange", f, s2 - 0.04, s2 + 0.04, Y0, Y0 + 2.5, -prof + 0.7, -prof + 0.78)
	# le socle de charge et son drone ; l'établi, un drone ouvert dessus
	bd.cyl_at("metal_noir", _p(f, a0 + 1.7, Y0, -2.2), 0.8, 0.8, 0.1, 20)
	bd.cyl_at("neon_cyan", _p(f, a0 + 1.7, Y0 + 0.1, -2.2), 0.72, 0.72, 0.015, 20)
	_drone(bd, _p(f, a0 + 1.7, Y0 + 0.34, -2.2), 0.6, false, 1.5)
	_fb(bd, "metal", f, a1 - 2.6, a1 - 0.5, Y0 + 0.85, Y0 + 0.9, -3.0, -2.1)
	for sg3 in [a1 - 2.5, a1 - 0.6]:
		_fb(bd, "metal_noir", f, sg3 - 0.04, sg3 + 0.04, Y0, Y0 + 0.85, -2.95, -2.15)
	_drone(bd, _p(f, a1 - 1.5, Y0 + 1.02, -2.55), 2.2, false, 1.2)
	# une pile de colis, un diable
	for q in [[a1 - 1.6, 0.0, 0.6], [a1 - 1.0, 0.0, 0.5], [a1 - 1.35, 0.6, 0.45]]:
		_fb(bd, "k187_carton", f, q[0] - q[2] * 0.5, q[0] + q[2] * 0.5, Y0 + q[1], Y0 + q[1] + q[2] * 0.9, -1.3 - q[2] * 0.5, -1.3 + q[2] * 0.5)
	# la barrière : deux potelets jaunes, la lisse rayée
	for sp in [a0 + 0.15, a1 - 0.15]:
		b.cyl_at("peinture_jaune", _p(f, sp, Y0, 0.12), 0.07, 0.07, 1.05, 8)
	_fb(b, "k187_danger", f, a0 + 0.15, a1 - 0.15, Y0 + 0.92, Y0 + 1.02, 0.09, 0.15)
	# ---- l'autre porte : le rideau baissé aux deux tiers, peint au nuage ; dessous, la lumière de l'atelier
	var c0: float = l - 7.0
	var c1: float = l - 0.6
	_fb(b, "metal", f, c0, c1, Y0 + 0.75, yl, -0.2, -0.15)
	_panneau("k187_rideau", f, c0, c1, Y0 + 0.75, yl, -0.14, Vector2(1.0, 0.63))
	_fb(b, "metal_noir", f, c0, c1, Y0 + 0.7, Y0 + 0.78, -0.22, -0.1)
	_fb(bd, "beton", f, c0, c1, Y0 - 0.02, Y0 + 0.01, -3.0, -0.3)
	_fb(bd, "metal_noir", f, c0, c1, Y0, yl, -3.05, -3.0)
	_fb(bd, "lampe_chaude", f, c0 + 0.5, c1 - 0.5, Y0 + 0.02, Y0 + 0.06, -1.3, -1.1)
	for q2 in [c0 + 1.0, c0 + 2.3, c1 - 1.2]:
		_fb(bd, "k187_carton", f, q2 - 0.3, q2 + 0.3, Y0, Y0 + 0.5, -1.0, -0.45)
	_fb(b, "k187_danger", f, c0, c1, Y0 + 0.012, Y0 + 0.02, -0.3, 0.3)


# =================================================================== le pied, côté boulevard (Kumo Express)

func _pied_boulevard(f: Dictionary) -> void:
	var l: float = f["l"]
	var yl: float = Y0 + 2.75
	var yh: float = Y0 + E - 0.22
	_fb(b, "k187_bardage", f, 0.0, l, yl, yh, -0.3, 0.14)
	_fb(b, "neon_cyan", f, 0.3, l - 0.3, yl + 0.02, yl + 0.07, 0.14, 0.19)
	for pr in [[0.0, 0.6], [5.0, 5.6], [11.6, 12.2], [l - 0.6, l]]:
		_fb(b, "k187_bardage", f, pr[0], pr[1], Y0, yl, -0.3, 0.2)
	# ---- le guichet (à gauche, vu du boulevard) : le mur, la fenêtre, la tablette, l'auvent rayé
	_fb(b, "k187_allege", f, 0.6, 5.0, Y0, Y0 + 1.0, -0.3, 0.06)
	_fb(b, "k187_allege", f, 0.6, 1.5, Y0 + 1.0, yl, -0.3, 0.06)
	_fb(b, "k187_allege", f, 4.1, 5.0, Y0 + 1.0, yl, -0.3, 0.06)
	_fb(b, "k187_allege", f, 1.5, 4.1, Y0 + 2.2, yl, -0.3, 0.06)
	_fb(b, "bois", f, 1.4, 4.2, Y0 + 0.96, Y0 + 1.02, -0.3, 0.4)
	_fb(bd, "in_mur", f, 1.5, 4.1, Y0 + 1.0, Y0 + 2.2, -1.9, -1.85)
	_fb(bd, "in_plafonnier_chaud", f, 1.9, 3.7, Y0 + 2.14, Y0 + 2.18, -1.2, -0.6)
	for niv in range(2):
		_fb(bd, "bois_clair", f, 1.6, 4.0, Y0 + 1.25 + niv * 0.42, Y0 + 1.28 + niv * 0.42, -1.85, -1.5)
		for q in range(5):
			if _rng.randf() < 0.8:
				var s: float = 1.7 + q * 0.46
				_fb(bd, "k187_carton", f, s, s + _rng.randf_range(0.22, 0.38), Y0 + 1.28 + niv * 0.42, Y0 + 1.28 + niv * 0.42 + _rng.randf_range(0.14, 0.3), -1.82, -1.55)
	_fb(b, "in_ecran_vert", f, 4.25, 4.85, Y0 + 1.5, Y0 + 1.95, 0.06, 0.1)
	for k in range(7):
		# l'auvent : des bandes orange et blanches, en pente
		var s0: float = 1.1 + k * 0.5
		var xf := Transform3D(_base(f) * Basis(Vector3.RIGHT, deg_to_rad(18.0)), _p(f, s0 + 0.25, Y0 + 2.42, 0.62))
		b.box("k187_orange" if k % 2 == 0 else "peinture_blanche", xf, Vector3(0.5, 0.04, 1.3))
	for sp in [1.1, 4.6]:
		b.tube("chrome", _p(f, sp, Y0 + 2.2, 1.2), _p(f, sp, Y0 + 2.7, 0.08), 0.02, 6)
	# ---- la vitrine : les colis défilent sur le tapis roulant
	_fb(b, "k187_allege", f, 5.6, 11.6, Y0, Y0 + 0.5, -0.3, 0.06)
	_fb(b, "verre", f, 5.6, 11.6, Y0 + 0.5, yl, -0.03, 0.0)
	for sm in [7.6, 9.6]:
		_fb(b, "metal_noir", f, sm - 0.03, sm + 0.03, Y0 + 0.5, yl, -0.05, 0.05)
	_fb(bd, "in_sol_technique", f, 5.6, 11.6, Y0 + 0.46, Y0 + 0.5, -2.6, -0.03)
	_fb(bd, "in_mur_gris", f, 5.6, 11.6, Y0 + 0.5, yl, -2.65, -2.6)
	_fb(bd, "in_plafonnier", f, 6.2, 11.0, yl - 0.05, yl - 0.02, -1.5, -1.0)
	for niv in range(3):
		_fb(bd, "metal", f, 5.8, 8.6, Y0 + 1.2 + niv * 0.5, Y0 + 1.23 + niv * 0.5, -2.6, -2.25)
		for q in range(6):
			if _rng.randf() < 0.8:
				var sq2: float = 5.9 + q * 0.45
				_fb(bd, "k187_carton", f, sq2, sq2 + _rng.randf_range(0.2, 0.38), Y0 + 1.23 + niv * 0.5, Y0 + 1.23 + niv * 0.5 + _rng.randf_range(0.15, 0.38), -2.56, -2.3)
	_image("kumo_enseigne.png", _p(f, 10.0, Y0 + 1.9, -2.58), _n3(f), Vector2(2.6, 0.65), false, 1.6).reparent(dedans)
	_fb(bd, "plastique_noir", f, 5.6, 11.6, Y0 + 1.02, Y0 + 1.1, -1.55, -0.85)
	_fb(bd, "metal", f, 5.6, 11.6, Y0 + 0.5, Y0 + 1.02, -1.5, -0.9)
	_fb(bd, "k187_orange", f, 5.6, 11.6, Y0 + 1.0, Y0 + 1.14, -1.6, -1.55)
	_fb(bd, "k187_orange", f, 5.6, 11.6, Y0 + 1.0, Y0 + 1.14, -0.85, -0.8)
	# le bras qui trie (immobile), le portique de lecture et sa lumière
	bd.cyl_at("k187_orange", _p(f, 10.4, Y0 + 0.5, -2.1), 0.16, 0.13, 1.3, 10)
	bd.tube("k187_orange", _p(f, 10.4, Y0 + 1.75, -2.1), _p(f, 9.9, Y0 + 2.1, -1.5), 0.08, 8)
	bd.tube("metal", _p(f, 9.9, Y0 + 2.1, -1.5), _p(f, 9.75, Y0 + 1.5, -1.2), 0.05, 8)
	for sq in [7.2, 7.5]:
		_fb(bd, "metal_noir", f, sq - 0.04, sq + 0.04, Y0 + 1.1, Y0 + 2.0, -1.65, -1.57)
		_fb(bd, "metal_noir", f, sq - 0.04, sq + 0.04, Y0 + 1.1, Y0 + 2.0, -0.83, -0.75)
	_fb(bd, "metal_noir", f, 7.1, 7.6, Y0 + 1.95, Y0 + 2.05, -1.65, -0.75)
	_fb(bd, "neon_rouge", f, 7.3, 7.4, Y0 + 1.92, Y0 + 1.95, -1.6, -0.8)
	# les colis du tapis : ils avancent (voir _process)
	var boite := Kit.Batch.new()
	boite.box("k187_carton", Transform3D(Basis(), Vector3(0, 0.5, 0)), Vector3.ONE)
	var mesh: ArrayMesh = _maillage(boite)
	for i in range(7):
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		var sz := Vector3(_rng.randf_range(0.28, 0.5), _rng.randf_range(0.18, 0.4), _rng.randf_range(0.28, 0.45))
		mi.scale = sz
		dedans.add_child(mi)
		_colis.append([mi, _p(f, 5.75, Y0 + 1.1, -1.2), _u3(f), 5.7, float(i) / 7.0 + _rng.randf_range(-0.03, 0.03)])
	# ---- les casiers à colis, sous leur auvent, et la borne
	_fb(b, "metal_noir", f, 12.2, l - 0.6, Y0, Y0 + 0.25, -0.45, -0.3)
	_fb(b, "metal_noir", f, 12.2, l - 0.6, Y0 + 0.25, Y0 + 2.65, -0.45, -0.39)
	_panneau("k187_casiers", f, 12.2, l - 0.6, Y0 + 0.25, Y0 + 2.65, -0.38, Vector2((l - 12.8) / 4.0, 1.2))
	_fb(b, "k187_bardage", f, 12.2, l - 0.6, Y0 + 2.65, yl, -0.45, -0.3)
	var cb: float = (12.2 + l - 0.6) * 0.5
	_fb(b, "metal_noir", f, cb - 0.35, cb + 0.35, Y0 + 0.25, Y0 + 2.2, -0.38, -0.3)
	_fb(b, "in_ecran", f, cb - 0.28, cb + 0.28, Y0 + 1.25, Y0 + 1.75, -0.3, -0.28)
	_fb(b, "k187_orange", f, cb - 0.28, cb + 0.28, Y0 + 0.95, Y0 + 1.1, -0.3, -0.26)
	_fb(b, "metal_noir", f, 12.0, l - 0.4, yl + 0.1, yl + 0.2, 0.0, 1.15)
	_fb(b, "neon_cyan", f, 12.0, l - 0.4, yl + 0.11, yl + 0.16, 1.15, 1.2)
	_fb(b, "lampe_blanche", f, 12.6, l - 1.0, yl + 0.07, yl + 0.1, 0.3, 0.6)


# =================================================================== le pied, côté ruelle (les gaines, la fresque)

func _pied_ruelle(f: Dictionary) -> void:
	var l: float = f["l"]
	var yh: float = Y0 + E - 0.22
	_fb(b, "k187_bardage", f, 0.0, l, Y0, yh, -0.3, 0.1)
	# la porte de service, sa lampe
	_fb(b, "in_porte", f, 3.6, 4.6, Y0, Y0 + 2.1, 0.1, 0.14)
	_fb(b, "metal_noir", f, 3.5, 4.7, Y0 + 2.1, Y0 + 2.2, 0.1, 0.2)
	b.blob("lampe_chaude", _p(f, 4.1, Y0 + 2.45, 0.22), Vector3(0.12, 0.09, 0.1), 6)
	# les grilles d'aération, les armoires électriques
	for g in [[6.0, 8.2], [8.6, 10.8]]:
		_fb(b, "metal_noir", f, g[0], g[1], Y0 + 0.4, Y0 + 2.0, 0.1, 0.16)
		var y: float = Y0 + 0.5
		while y < Y0 + 1.95:
			_fb(b, "metal", f, g[0] + 0.06, g[1] - 0.06, y, y + 0.05, 0.16, 0.2)
			y += 0.13
	for a in [12.0, 12.9]:
		_fb(b, "k187_clair", f, a, a + 0.75, Y0 + 0.15, Y0 + 1.75, 0.1, 0.5)
		_fb(b, "peinture_jaune", f, a + 0.25, a + 0.5, Y0 + 1.2, Y0 + 1.4, 0.5, 0.51)
	# les gaines qui montent jusqu'à la terrasse, leurs colliers ; le chemin de câbles
	for g2 in [[1.2, 0.34], [2.05, 0.24]]:
		b.cyl_at("metal", _p(f, g2[0], Y0, 0.14 + g2[1]), g2[1], g2[1], YT - Y0 + 0.9, 12)
		var y2: float = Y0 + 2.0
		while y2 < YT:
			b.cyl_at("metal_noir", _p(f, g2[0], y2, 0.14 + g2[1]), g2[1] + 0.03, g2[1] + 0.03, 0.08, 12)
			y2 += 3.5
	_fb(b, "metal_noir", f, 14.6, 14.9, Y0 + 2.2, YT - 0.3, 0.1, 0.2)
	# les climatiseurs sur leurs consoles
	for q in [[16.5, 2], [17.4, 4], [16.2, 6], [5.5, 4], [5.2, 6], [17.0, 8]]:
		var yc: float = _yk(q[1]) + 0.3
		_fb(b, "metal_noir", f, q[0] - 0.55, q[0] + 0.55, yc - 0.06, yc, 0.1, 0.9)
		Kit.ac_unit(b, _p(f, q[0], yc, 0.5), atan2((f["n"] as Vector2).x, (f["n"] as Vector2).y))
	# les bennes
	for d in [[15.6, "plastique_bleu"], [17.4, "plastique_rouge"]]:
		_fb(b, d[1], f, d[0], d[0] + 1.5, Y0 + 0.12, Y0 + 1.1, 0.35, 1.25)
		_fb(b, "plastique_noir", f, d[0] - 0.03, d[0] + 1.53, Y0 + 1.1, Y0 + 1.17, 0.32, 1.28)
		for w in [d[0] + 0.2, d[0] + 1.3]:
			b.cyl("plastique_noir", Transform3D(Basis(_u3(f).cross(Vector3.UP), PI * 0.5) , _p(f, w, Y0 + 0.08, 1.15)), 0.08, 0.08, 0.06, 8)
	# la fresque : le grand nuage de Kumo, peint sur le mur, trois projecteurs au-dessus
	var cy: float = _yk(1) + 0.22 + 4.9
	_peinture("fresque_kumo.png", _p(f, l * 0.5, cy, 0.04), _n3(f), Vector2(9.6, 9.6))
	for sp in [l * 0.5 - 3.0, l * 0.5, l * 0.5 + 3.0]:
		b.tube("metal_noir", _p(f, sp, cy + 5.1, 0.02), _p(f, sp, cy + 5.2, 0.9), 0.03, 6)
		b.blob("lampe_blanche", _p(f, sp, cy + 5.15, 0.92), Vector3(0.14, 0.1, 0.14), 6)


# =================================================================== le pied, côté service (le quai de chargement)

func _pied_service(f: Dictionary) -> void:
	var l: float = f["l"]
	var yh: float = Y0 + E - 0.22
	_fb(b, "k187_bardage", f, 0.0, l, Y0, yh, -0.3, 0.1)
	# le quai : une dalle d'un mètre, ses butoirs de caoutchouc, son nez jaune
	_fb(b, "beton", f, 3.0, 17.0, Y0, Y0 + 1.0, 0.1, 1.7)
	_fb(b, "peinture_jaune", f, 3.0, 17.0, Y0 + 0.9, Y0 + 1.0, 1.7, 1.72)
	N._col(Transform3D(Basis(), _p(f, 10.0, Y0 + 0.5, 0.9)), Vector3(1.6 if absf((f["u"] as Vector2).x) < 0.5 else 14.0, 1.0, 14.0 if absf((f["u"] as Vector2).x) < 0.5 else 1.6))
	for sb in [4.2, 8.2, 11.8, 15.8]:
		_fb(b, "plastique_noir", f, sb - 0.15, sb + 0.15, Y0 + 0.45, Y0 + 0.95, 1.7, 1.8)
	# les deux portes du quai : l'une fermée, l'autre levée sur des palettes
	_fb(b, "metal", f, 4.6, 7.8, Y0 + 1.0, Y0 + 3.1, 0.1, 0.15)
	_panneau("k187_rideau", f, 4.6, 7.8, Y0 + 1.0, Y0 + 3.1, 0.16, Vector2(1.0, 1.0))
	_fb(b, "metal_noir", f, 4.5, 7.9, Y0 + 3.1, Y0 + 3.2, 0.1, 0.2)
	_fb(b, "metal", f, 12.2, 15.4, Y0 + 2.5, Y0 + 3.1, 0.1, 0.16)
	_fb(b, "metal_noir", f, 12.1, 15.5, Y0 + 3.1, Y0 + 3.2, 0.1, 0.2)
	_fb(b, "in_noir", f, 12.2, 15.4, Y0 + 1.0, Y0 + 2.5, 0.08, 0.1)
	_fb(b, "lampe_chaude", f, 12.6, 15.0, Y0 + 2.42, Y0 + 2.46, 0.1, 0.14)
	# les palettes et leurs colis, sur le quai et au pied
	for pal in [[13.0, 1.0, 0.9], [14.6, 1.0, 0.9], [9.6, 1.0, 0.9], [1.6, 0.0, 1.2]]:
		_palette(f, pal[0], Y0 + pal[1], pal[2])
	# l'escalier du quai
	for m in range(5):
		_fb(b, "beton", f, 17.0 + m * 0.3, 17.3 + m * 0.3, Y0, Y0 + 1.0 - m * 0.2, 0.1, 1.3)
	# l'escalier de secours : un palier par étage, des volées qui vont et viennent, jusqu'à la terrasse
	var sa: float = 8.6
	var sbb: float = 11.6
	for k in range(1, 9):
		var y: float = _yk(k)
		_fb(b, "metal_noir", f, sa - 1.0, sbb + 1.0, y - 0.05, y, 0.1, 1.25)
		b.tube("metal_noir", _p(f, sa - 1.0, y + 1.0, 1.22), _p(f, sbb + 1.0, y + 1.0, 1.22), 0.025, 6)
		for sp in [sa - 1.0, (sa + sbb) * 0.5, sbb + 1.0]:
			b.tube("metal_noir", _p(f, sp, y, 1.22), _p(f, sp, y + 1.0, 1.22), 0.02, 6)
		for cb in [sa - 0.9, sbb + 0.9]:
			b.tube("metal_noir", _p(f, cb, y - 0.05, 1.1), _p(f, cb, y - 0.7, 0.12), 0.03, 6)
		var monte: bool = k % 2 == 1
		var s_bas: float = sa if monte else sbb
		var s_haut: float = sbb if monte else sa
		if k == 8:
			# la dernière volée, plus courte : elle arrive sur la terrasse
			s_haut = lerpf(s_bas, s_haut, (YT - y) / E)
		var y_haut: float = _yk(k + 1) if k < 8 else YT
		var nm: int = 12
		for m2 in range(nm):
			var t: float = (float(m2) + 0.5) / float(nm)
			var sm: float = lerpf(s_bas, s_haut, t)
			_fb(b, "metal", f, sm - 0.14, sm + 0.14, lerpf(y, y_haut, t) - 0.02, lerpf(y, y_haut, t) + 0.02, 0.15, 0.72)
		for dd in [0.14, 0.73]:
			b.tube("metal_noir", _p(f, s_bas, y, dd), _p(f, s_haut, y_haut, dd), 0.035, 6)
		b.tube("metal_noir", _p(f, s_bas, y + 1.0, 0.73), _p(f, s_haut, y_haut + 1.0, 0.73), 0.022, 6)
	# l'échelle rabattue du premier palier, et sa lampe de secours
	for dd2 in [0.4, 0.9]:
		b.tube("metal_noir", _p(f, sa - 0.8, _yk(1) - 0.05, dd2), _p(f, sa - 0.8, _yk(1) - 2.2, dd2), 0.025, 6)
	for m3 in range(6):
		b.tube("metal_noir", _p(f, sa - 0.8, _yk(1) - 0.35 - m3 * 0.34, 0.4), _p(f, sa - 0.8, _yk(1) - 0.35 - m3 * 0.34, 0.9), 0.018, 5)
	b.blob("neon_rouge", _p(f, sbb + 1.4, Y0 + 3.4, 0.2), Vector3(0.09, 0.09, 0.09), 6)


func _palette(f: Dictionary, s: float, y: float, w: float) -> void:
	_fb(b, "bois", f, s, s + w, y, y + 0.12, 0.3, 0.3 + w)
	var h: float = y + 0.12
	for niv in range(_rng.randi_range(1, 3)):
		var c: float = w * _rng.randf_range(0.42, 0.5)
		for i in range(2):
			for j in range(2):
				if niv == 0 or _rng.randf() < 0.7:
					_fb(b, "k187_carton", f, s + i * c + 0.02, s + i * c + c - 0.02, h, h + c * 0.8, 0.32 + j * c, 0.3 + j * c + c - 0.02)
		h += w * 0.38


# =================================================================== l'écran, les enseignes, les nids

func _ecran_et_enseignes(F0: Array, F1: Array) -> void:
	var fn: Dictionary = F0[0]
	var fe: Dictionary = F0[1]
	var l: float = fn["l"]
	# le grand écran, au-dessus de l'entrée (2e et 3e étages)
	var cy: float = _yk(2) + 3.3
	_fb(b, "metal_noir", fn, l * 0.5 - 6.3, l * 0.5 + 6.3, cy - 3.3, cy + 3.3, 0.14, 0.42)
	_image("kumo_ecran.png", _p(fn, l * 0.5, cy, 0.44), _n3(fn), Vector2(12.0, 6.0), true, 1.9)
	for sg in [-1.0, 1.0]:
		_fb(b, "k187_orange", fn, l * 0.5 + sg * 6.3 - 0.06, l * 0.5 + sg * 6.3 + 0.06, cy - 3.3, cy + 3.3, 0.14, 0.46)
	# les enseignes du pied : sur le quai, sur le boulevard
	_image("kumo_depot.png", _p(fn, 3.8, Y0 + 3.95, 0.32), _n3(fn), Vector2(6.8, 0.85))
	_image("kumo_enseigne.png", _p(fn, l * 0.5, Y0 + 4.05, 2.06), _n3(fn), Vector2(4.4, 1.1))
	_image("kumo_express.png", _p(fe, (12.2 + float(fe["l"]) - 0.6) * 0.5, Y0 + 4.0, 0.32), _n3(fe), Vector2(8.4, 1.05))
	# l'enseigne en drapeau, à l'angle du boulevard : KUMO, de haut en bas, lisible des deux côtés
	var le: float = fe["l"]
	var cyd: float = _yk(5) + 1.75
	var at: Vector3 = _p(fe, le - 0.9, cyd, 1.45)
	b.box("metal_noir", Transform3D(_base(fe), at), Vector3(0.14, 9.2, 2.4))
	for sg2 in [1.0, -1.0]:
		_image("kumo_vertical.png", at + _u3(fe) * 0.08 * sg2, _u3(fe) * sg2, Vector2(2.2, 8.8))
	for yy in [cyd - 3.8, cyd, cyd + 3.8]:
		b.tube("metal_noir", _p(fe, le - 0.9, yy, 0.2), _p(fe, le - 0.9, yy, 0.4), 0.05, 6)
	# le toit : KUMO en lettres de néon, vers la mer et vers le boulevard, sur leur charpente
	var f1n: Dictionary = F1[0]
	var f1e: Dictionary = F1[1]
	for q in [[f1n, 11.0], [f1e, 9.0]]:
		var ff: Dictionary = q[0]
		var w: float = q[1]
		var lm: float = float(ff["l"]) * 0.5
		var ys: float = YH + 0.25
		_image("kumo_enseigne.png", _p(ff, lm, ys + 0.6 + w * 0.125, -0.5), _n3(ff), Vector2(w, w * 0.25), false, 3.4)
		for s in [lm - w * 0.5, lm - w * 0.17, lm + w * 0.17, lm + w * 0.5]:
			b.tube("metal_noir", _p(ff, s, ys, -0.6), _p(ff, s, ys + 0.7 + w * 0.25, -0.6), 0.05, 6)
			b.tube("metal_noir", _p(ff, s, ys, -2.0), _p(ff, s, ys + 0.5 + w * 0.2, -0.62), 0.04, 6)
		for yy2 in [ys + 0.55, ys + 0.65 + w * 0.25]:
			b.tube("metal_noir", _p(ff, lm - w * 0.5, yy2, -0.6), _p(ff, lm + w * 0.5, yy2, -0.6), 0.04, 6)


## Les nids des drones, à l'étage des serveurs : une plate-forme en porte-à-faux, son anneau de lumière.
func _nids(F0: Array) -> void:
	var y: float = _yk(5) + 0.45
	for fi in [0, 1]:
		var f: Dictionary = F0[fi]
		var l: float = f["l"]
		for i in [0, 1, 2, 3]:
			if fi == 0 and (i == 1 or i == 2):
				continue                # (au-dessus du grand écran : rien)
			var s: float = l * (float(i) + 0.5) / 4.0
			_fb(b, "metal_noir", f, s - 0.95, s + 0.95, y - 0.1, y, 0.05, 1.9)
			_fb(b, "k187_orange", f, s - 0.95, s + 0.95, y - 0.1, y - 0.02, 1.9, 1.94)
			b.cyl_at("neon_cyan", _p(f, s, y, 1.05), 0.62, 0.62, 0.02, 18)
			b.cyl_at("metal_noir", _p(f, s, y + 0.005, 1.05), 0.54, 0.54, 0.02, 18)
			for sg in [-0.85, 0.85]:
				b.tube("metal_noir", _p(f, s + sg, y - 0.1, 1.8), _p(f, s + sg, y - 1.3, 0.12), 0.035, 6)
			# la trappe par où passent les colis
			_fb(b, "k187_orange", f, s - 0.55, s + 0.55, y + 0.02, y + 1.1, 0.05, 0.08)
			_fb(b, "metal_noir", f, s - 0.48, s + 0.48, y + 0.06, y + 1.04, 0.08, 0.1)
			if (fi + i) % 2 == 0:
				_drone(b, _p(f, s, y + 0.22, 1.05), _rng.randf() * TAU, true, 1.5)


# =================================================================== la terrasse du retrait, le toit

func _terrasse(F0: Array) -> void:
	# le platelage, sur tout le socle (le retrait est posé dessus)
	var cx: float = (float(R0[0]) + float(R0[2])) * 0.5
	var cz: float = (float(R0[1]) + float(R0[3])) * 0.5
	b.box("bois", Transform3D(Basis(), IleScript.W(cx, cz, YT - 0.06)), Vector3(float(R0[2]) - float(R0[0]), 0.16, float(R0[3]) - float(R0[1])))
	for fi in range(4):
		var f: Dictionary = F0[fi]
		var l: float = f["l"]
		# le garde-corps de verre, sa main courante, ses potelets et leurs petites lampes
		_fb(b, "k187_clair", f, 0.0, l, YT - 0.2, YT + 0.12, -0.1, 0.16)
		_fb(b, "verre", f, 0.1, l - 0.1, YT + 0.12, YT + 1.05, -0.04, 0.0)
		b.tube("chrome", _p(f, 0.0, YT + 1.08, -0.02), _p(f, l, YT + 1.08, -0.02), 0.03, 6)
		var np: int = 6
		for i in range(np + 1):
			var s: float = l * float(i) / float(np)
			_fb(b, "metal_noir", f, s - 0.03, s + 0.03, YT + 0.12, YT + 1.08, -0.06, 0.0)
			if i % 2 == 1:
				b.blob("lampe_chaude", _p(f, s, YT + 0.25, -0.16), Vector3(0.07, 0.07, 0.07), 5)
	# les bacs aux angles, leurs arbustes
	for c in [[float(R0[0]) + 0.9, float(R0[1]) + 0.9], [float(R0[2]) - 0.9, float(R0[1]) + 0.9], [float(R0[0]) + 0.9, float(R0[3]) - 0.9], [float(R0[2]) - 0.9, float(R0[3]) - 0.9]]:
		var at: Vector3 = IleScript.W(c[0], c[1], YT)
		b.box_at("metal_noir", at, Vector3(1.3, 0.55, 1.3))
		b.box_at("terre_bac", at + Vector3.UP * 0.5, Vector3(1.2, 0.06, 1.2))
		b.cyl_at("ecorce", at + Vector3.UP * 0.5, 0.07, 0.05, 1.3, 6)
		b.blob("k187_feuillage", at + Vector3.UP * 2.1, Vector3(0.85, 0.7, 0.85), 7)
		b.blob("k187_feuillage_clair", at + Vector3(0.3, 1.7, 0.2), Vector3(0.5, 0.4, 0.5), 6)
	# côté quai : trois tables et leurs parasols (la pause, face à la mer)
	var zt: float = (float(R0[1]) + float(R1[1])) * 0.5
	for i2 in range(3):
		var xt: float = lerpf(float(R0[0]) + 4.0, float(R0[2]) - 4.0, float(i2) / 2.0)
		var at2: Vector3 = IleScript.W(xt, zt, YT)
		b.cyl_at("chrome", at2, 0.03, 0.03, 0.72, 6)
		b.cyl_at("peinture_blanche", at2 + Vector3.UP * 0.72, 0.42, 0.42, 0.03, 14)
		b.cyl_at("metal_noir", at2, 0.02, 0.02, 2.3, 6)
		b.cyl_at("k187_orange" if i2 != 1 else "peinture_blanche", at2 + Vector3.UP * 2.05, 1.05, 0.04, 0.32, 10)
		for a in [0.6, 2.7, 4.6]:
			var ch: Vector3 = at2 + Vector3(cos(a) * 0.75, 0.0, sin(a) * 0.4)
			b.cyl_at("metal_noir", ch, 0.17, 0.17, 0.45, 8)


func _toit() -> void:
	var cx: float = (float(R1[0]) + float(R1[2])) * 0.5
	var cz: float = (float(R1[1]) + float(R1[3])) * 0.5
	b.box("beton", Transform3D(Basis(), IleScript.W(cx, cz, YH - 0.05)), Vector3(float(R1[2]) - float(R1[0]), 0.12, float(R1[3]) - float(R1[1])))
	# la plate-forme des drones, sur son mât : l'anneau de lumière, les feux, trois drones posés
	var m: Vector3 = IleScript.W(float(R1[0]) + 4.2, float(R1[3]) - 4.4, YH)
	b.cyl_at("metal_noir", m, 0.3, 0.22, 6.4, 10)
	for a in range(4):
		var dir := Vector3(cos(a * PI * 0.5 + 0.4), 0.0, sin(a * PI * 0.5 + 0.4))
		b.tube("metal_noir", m + Vector3.UP * 4.2, m + Vector3.UP * 6.35 + dir * 2.6, 0.06, 6)
	b.cyl_at("metal", m + Vector3.UP * 6.4, 3.3, 3.3, 0.1, 28)
	b.cyl_at("neon_cyan", m + Vector3.UP * 6.5, 3.15, 3.15, 0.02, 28)
	b.cyl_at("metal_noir", m + Vector3.UP * 6.505, 2.95, 2.95, 0.02, 28)
	b.cyl_at("peinture_jaune", m + Vector3.UP * 6.51, 1.0, 1.0, 0.02, 20)
	b.cyl_at("metal_noir", m + Vector3.UP * 6.515, 0.85, 0.85, 0.02, 20)
	for a2 in range(3):
		var p: Vector3 = m + Vector3.UP * 6.72 + Vector3(cos(a2 * 2.1 + 0.7), 0.0, sin(a2 * 2.1 + 0.7)) * 2.0
		_drone(b, p, a2 * 1.3, a2 != 1, 1.5)
	for a3 in range(6):
		b.blob("neon_rouge", m + Vector3.UP * 6.5 + Vector3(cos(a3 * TAU / 6.0), 0.0, sin(a3 * TAU / 6.0)) * 3.3, Vector3(0.09, 0.09, 0.09), 5)
	# les antennes, leurs feux rouges
	for q in [[float(R1[2]) - 1.6, float(R1[3]) - 1.8, 7.5], [float(R1[2]) - 2.6, float(R1[3]) - 1.2, 4.6], [float(R1[2]) - 1.2, float(R1[3]) - 3.0, 3.4]]:
		var at: Vector3 = IleScript.W(q[0], q[1], YH)
		b.cyl_at("metal", at, 0.09, 0.03, q[2], 6)
		b.blob("neon_rouge", at + Vector3.UP * q[2], Vector3(0.12, 0.12, 0.12), 6)
		b.cyl_at("metal", at + Vector3.UP * q[2] * 0.6, 0.35, 0.35, 0.03, 8)


# =================================================================== les drones

## Un drone livreur : le corps blanc, quatre bras, quatre hélices, les feux ; le colis sous le ventre.
func _drone(lot: Kit.Batch, at: Vector3, yaw: float, colis: bool, s: float) -> void:
	var bs := Basis(Vector3.UP, yaw).scaled(Vector3(s, s, s))
	var xf := Transform3D(bs, at)
	lot.box("peinture_blanche", xf, Vector3(0.5, 0.13, 0.32) * 1.0)
	lot.box("k187_orange", xf * Transform3D(Basis(), Vector3(0.0, 0.075, 0.0)), Vector3(0.3, 0.03, 0.2))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var e: Vector3 = Vector3(sx * 0.42, 0.04, sz * 0.34)
			lot.tube("metal_noir", xf * Vector3(sx * 0.2, 0.0, sz * 0.12), xf * e, 0.022 * s, 5)
			lot.cyl("metal_noir", xf * Transform3D(Basis(), e), 0.04, 0.04, 0.06, 6)
			lot.cyl("verre_fume", xf * Transform3D(Basis(), e + Vector3(0, 0.065, 0)), 0.21, 0.21, 0.01, 12)
		lot.tube("metal_noir", xf * Vector3(sx * 0.16, -0.06, -0.1), xf * Vector3(sx * 0.2, -0.2, -0.1), 0.012 * s, 4)
		lot.tube("metal_noir", xf * Vector3(sx * 0.16, -0.06, 0.1), xf * Vector3(sx * 0.2, -0.2, 0.1), 0.012 * s, 4)
	lot.blob("neon_cyan", xf * Vector3(0.26, 0.0, 0.0), Vector3(0.035, 0.035, 0.05) * s, 5)
	lot.blob("neon_rouge", xf * Vector3(-0.26, 0.0, 0.0), Vector3(0.03, 0.03, 0.04) * s, 5)
	if colis:
		lot.box("k187_carton", xf * Transform3D(Basis(), Vector3(0.0, -0.2, 0.0)), Vector3(0.28, 0.22, 0.24))


## Un lot rassemblé en un maillage (une surface par matière), pour ce qui bouge.
func _maillage(lot: Kit.Batch) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	for k in lot.sts:
		var st: SurfaceTool = lot.sts[k]
		st.index()
		st.generate_tangents()
		st.commit(mesh)
		mesh.surface_set_material(mesh.get_surface_count() - 1, Kit.mat(str(k)))
	lot.sts.clear()
	return mesh


## Six drones tournent autour de la tour ; l'un d'eux fait la navette avec le large.
func _vole() -> void:
	var lot := Kit.Batch.new()
	_drone(lot, Vector3.ZERO, 0.0, true, 1.6)
	var plein: ArrayMesh = _maillage(lot)
	var lot2 := Kit.Batch.new()
	_drone(lot2, Vector3.ZERO, 0.0, false, 1.6)
	var vide: ArrayMesh = _maillage(lot2)
	var c: Vector3 = IleScript.W((float(R0[0]) + float(R0[2])) * 0.5, (float(R0[1]) + float(R0[3])) * 0.5, 0.0)
	var defs: Array = [[17.0, 17.5, 12.0, 0.22, 0.0, true], [19.5, 19.0, 21.0, -0.17, 1.3, false], [16.5, 18.0, 30.5, 0.2, 2.6, true],
		[14.0, 13.5, 41.0, -0.25, 4.0, true], [13.0, 12.0, 58.5, 0.3, 5.1, false], [22.0, 62.0, 34.0, 0.11, 0.6, true]]
	for d in defs:
		var mi := MeshInstance3D.new()
		mi.mesh = plein if bool(d[5]) else vide
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		var cc: Vector3 = c
		if float(d[1]) > 40.0:
			cc = c + Vector3(0.0, 0.0, -48.0)        # la navette : une longue boucle vers le large, par-dessus le quai
		_drones.append({"n": mi, "c": cc, "rx": float(d[0]), "rz": float(d[1]), "y": Y0 + float(d[2]), "v": float(d[3]), "ph": float(d[4])})
	_place_drones()


func _place_drones() -> void:
	for d in _drones:
		var a: float = float(d["ph"]) + _t * float(d["v"])
		var c: Vector3 = d["c"]
		var p := Vector3(c.x + cos(a) * float(d["rx"]), float(d["y"]) + sin(_t * 0.9 + float(d["ph"]) * 3.0) * 0.35, c.z + sin(a) * float(d["rz"]))
		var sens: float = signf(float(d["v"]))
		var av := Vector3(-sin(a) * float(d["rx"]), 0.0, cos(a) * float(d["rz"])).normalized() * sens
		# (le nez du drone est sur son axe x)
		var bs := Basis(av, Vector3.UP, av.cross(Vector3.UP))
		(d["n"] as Node3D).global_transform = Transform3D(bs, p)


func _process(delta: float) -> void:
	_t += delta
	_place_drones()
	# les colis du tapis roulant
	for q in _colis:
		var t: float = fposmod(float(q[4]) + _t * 0.055, 1.0)
		(q[0] as Node3D).global_position = (q[1] as Vector3) + (q[2] as Vector3) * float(q[3]) * t
	# la nuit, pour les vitres et l'étage des serveurs
	var nuit: float = float(N.get("night")) if N.get("night") != null else 0.0
	if absf(nuit - _nuit_vue) > 0.004:
		_nuit_vue = nuit
		for m in _mats_nuit:
			(m as ShaderMaterial).set_shader_parameter("nuit", nuit)
		var cas: Material = Kit._mcache.get("k187_casiers")
		if cas is StandardMaterial3D:
			(cas as StandardMaterial3D).emission_energy_multiplier = lerpf(1.2, 3.5, nuit)
	# dans la tour : on cache ce qui est dans son volume (les étages s'y construisent)
	var T: Node = N.get("tours")
	if T != null:
		if tid < 0:
			for t2 in T.get("tours"):
				if is_same((t2 as Dictionary)["b"], bt):
					tid = int((t2 as Dictionary)["id"])
		var ici: bool = tid >= 0 and int(T.get("inside")) == tid
		if dedans.visible == ici:
			dedans.visible = not ici


## Les lumières du pied (gérées par la ville : seules les plus proches s'allument).
func _lumieres(F0: Array) -> void:
	var fn: Dictionary = F0[0]
	var fe: Dictionary = F0[1]
	var l: float = fn["l"]
	N._light(_p(fn, l * 0.5, Y0 + 2.6, 1.2), Color(0.45, 0.9, 1.0), 2.2, 9.0)
	N._light(_p(fn, 3.8, Y0 + 2.3, -1.6), Color(1.0, 0.96, 0.9), 2.4, 9.0)
	N._light(_p(fn, l - 3.8, Y0 + 0.5, 0.4), Color(1.0, 0.75, 0.4), 1.4, 6.0)
	N._light(_p(fe, 16.0, Y0 + 2.4, 0.9), Color(0.8, 0.95, 1.0), 2.0, 9.0)
	N._light(_p(fe, 8.6, Y0 + 2.2, -1.0), Color(1.0, 0.97, 0.92), 2.0, 8.0)
	N._light(_p(fe, 2.8, Y0 + 1.9, -0.4), Color(1.0, 0.8, 0.5), 1.6, 6.0)
	N._light(_p(F0[3], 13.8, Y0 + 2.2, 1.0), Color(1.0, 0.8, 0.5), 1.5, 8.0)
	N._light(_p(F0[2], l * 0.5, _yk(3), 3.0), Color(1.0, 1.0, 1.0), 1.6, 14.0)
