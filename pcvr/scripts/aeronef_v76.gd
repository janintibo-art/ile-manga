extends Node3D
## V76 : l'aéronef qui évolue — le moyen de voler du héros (Ventaile, l'aigle, reste à part).
##
## Quatre niveaux, construits par Philibert Vis à l'Atelier des Ailes de Cliquetis (1 à 3,
## voir atelier_ailes_v76.gd) puis par Ionie au Spatioport d'Astralys (4) :
##  1. l'Alouette, un deltaplane : on ne la déploie que d'un point haut (12 m de vide sous soi,
##     le bord d'une falaise, l'aire d'envol de l'Atelier, ou en pleine chute) ; elle plane
##     (1 m de descente pour 8 m parcourus), vire, se pose en douceur ;
##  2. l'Alouette à hélice : la même, avec un pédalier et une hélice propulsive : on peut
##     décoller d'un terrain plat (on pédale pour rouler), monter un peu en pédalant (cela
##     consomme l'endurance du héros), puis planer ;
##  3. l'Albatros, un petit aéronef (ballon allongé, nacelle, deux hélices) : vol libre lent,
##     on monte et on descend, plafond 300 m ;
##  4. le Glisseur stellaire, une petite soucoupe de nacre des Lumens : rapide, plafond 600 m,
##     des lumières, se pose partout (Astralys, l'île flottante…).
## On l'appelle avec N (PC), la croix haute maintenue (manette), X maintenu (VR). Les deux
## Alouettes sont pliables (dans le sac) ; l'Albatros et le Glisseur arrivent du ciel et se
## posent près du joueur : E (gâchette) pour monter ; en vol, E (A en VR) pour se poser.
## Commandes de vol (comme l'aigle) : Z / S vitesse, Q / D virer, Espace monter (ou pédaler),
## Ctrl descendre (ou piquer), E se poser ; VR : stick gauche (virer, monter / descendre),
## gâchettes (accélérer / freiner), A se poser.
##
## Collisions : le relief (main._height_at), la mer, tout ce qui a une collision (calque 1,
## balayage de sphères), et le dessous des îles flottantes (l'île céleste, le royaume des fées,
## Astralys) qui n'a pas de collision : profil analytique.

signal level_changed(n: int)

const SFX_DIR := "res://assets/sons/sfx/"
const NAMES := ["", "l'Alouette", "l'Alouette à hélice", "l'Albatros", "le Glisseur stellaire"]
const LAUNCH_H: float = 12.0              # vide sous soi pour déployer le deltaplane
const GLIDE: float = 8.0                  # finesse : 8 m parcourus pour 1 m de descente
const SEA_Y: float = -0.42
const WORLD := Rect2(-1400.0, -1150.0, 2850.0, 2350.0)
const ASTRALYS_C := Vector3(-820.0, 380.0, -760.0)
const ASTRALYS_R: float = 205.0
const ASTRALYS_DEPTH: float = 240.0       # profondeur de la montagne renversée (si astralys_v76.solid n'existe pas)
const PEDAL_AGL: float = 70.0             # au-delà, le pédalier ne fait presque plus monter
const PEDAL_COST: float = 1.1             # endurance par seconde de pédalage
const TUNE := {
	1: {"cruise": 9.0, "min": 6.5, "max": 15.0, "turn": 0.8, "climb": 0.0, "ceil": 1500.0, "bank": 0.42},
	2: {"cruise": 8.5, "min": 6.0, "max": 13.5, "turn": 0.75, "climb": 3.6, "ceil": 1500.0, "bank": 0.38},
	3: {"cruise": 9.0, "min": 0.0, "max": 13.0, "turn": 0.5, "climb": 4.0, "ceil": 300.0, "bank": 0.1},
	4: {"cruise": 24.0, "min": 0.0, "max": 42.0, "turn": 1.25, "climb": 12.0, "ceil": 600.0, "bank": 0.5},
}
const TOP := {1: 2.6, 2: 2.6, 3: 10.0, 4: 2.9}          # hauteur du véhicule au-dessus de « pos »
const GROUND_R := {1: 3.0, 2: 3.0, 3: 6.0, 4: 3.6}      # place libre nécessaire pour se poser

var main: Node
var pc: bool = true
var lvl: int = 0
var riding: bool = false
## range : plié dans le sac (1, 2) ou rentré au hangar (3, 4) ; pose : posé, on peut monter ;
## arrive : vient vers le joueur ; sol : roule (2) ; envol, vol, atterrit, replie
var state: String = "range"
var pos := Vector3.ZERO                   # le bas du véhicule (pieds, roues, patins, pieds de la soucoupe)
var yaw: float = 0.0
var speed: float = 0.0
var vspeed: float = 0.0
var bank: float = 0.0
var pitch: float = 0.0
var alt_max: float = 0.0
var vols: int = 0
var rig: Node3D
var parts: Dictionary = {}
var _mats: Dictionary = {}
var _clock: float = 0.0
var _t: float = 0.0                        # minuterie de l'état en cours
var _path: Array = []
var _land_from := Vector3.ZERO
var _land_to := Vector3.ZERO
var _land_water: bool = false
var _prone: float = 0.0                    # 0 debout, 1 couché sous l'aile
var _pedal: float = 0.0                    # 0..1 effort au pédalier
var _prop_a: float = 0.0
var _vr_a: bool = false
var _warn_t: float = 0.0
var _warned: String = ""
var _cam_pos := Vector3.INF
var _cam_orbit: float = 0.0
var _loop: AudioStreamPlayer3D
var _loop_name: String = ""
var _hud: CanvasLayer
var _hud_label: Label
var _mount_it: Dictionary = {}
var _poses_done: bool = false
var _anim_now: String = ""
var _turn_in: float = 0.0
var _lift_in: float = 0.0
var _thr_in: float = 0.0
var _bump_t: float = 0.0
var _air_t: float = 0.0                   # depuis quand on a quitté le sol
var _sphere := SphereShape3D.new()
var _forced_level: int = -1               # pour les essais


func setup(main_node: Node) -> void:
	main = main_node
	pc = OS.has_feature("ile_manga_pc") or not bool(main.get("xr_active"))
	name = "Aeronef_v76"


func build() -> void:
	_build_model()
	_make_hud()
	print("ILE_MANGA_V76: aéronef prêt (niveau ", lvl, ")")


func level() -> int:
	return lvl


func vehicle_name(n: int = -1) -> String:
	var k: int = lvl if n < 0 else n
	return NAMES[clampi(k, 0, 4)]


## Nouveau niveau (atelier, Spatioport, sauvegarde). ceremony : la musique et le message.
func set_level(n: int, ceremony: bool = false) -> void:
	n = clampi(n, 0, 4)
	if riding:
		_end_ride(false)
	var old: int = lvl
	lvl = n
	if n != old:
		state = "range"
		_build_model()
		level_changed.emit(n)
	if ceremony and n > 0:
		main.sfx("aeronef_evolue", _player_pos() + Vector3.UP * 1.0)
		main.jingle("victoire")
		_say(_how_text(n), 11.0)


func _how_text(n: int) -> String:
	var vr: bool = bool(main.xr_active)
	var call: String = "maintiens le bouton X (main gauche)" if vr else "appuie sur N (ou maintiens la croix haute de la manette)"
	match n:
		1:
			return "L'Alouette est à toi ! Un deltaplane de toile et de frêne, plié dans ton sac. Pour t'envoler, il faut un point haut : le bord d'une falaise, une tour, l'aire d'envol de l'Atelier… ou en pleine chute ! Là, %s. %s" % [call, "Stick gauche pour virer et piquer, A pour te poser." if vr else "Q / D : virer, Z : piquer (plus vite), S : cabrer (plus lent), E : se poser."]
		2:
			return "L'Alouette à hélice ! Un pédalier, une chaîne, une hélice : tu peux maintenant décoller d'un terrain plat (pédale pour rouler) et remonter un peu en pédalant — %s. Pédaler fatigue : quand tu n'as plus de souffle, plane." % ("stick gauche vers l'avant" if vr else "Espace pour pédaler")
		3:
			return "L'Albatros ! Un ballon allongé, une nacelle de bois et de laiton, deux hélices qui ronronnent. Il monte, il descend, il flâne jusqu'à trois cents mètres. Pour l'appeler, %s : il vient se poser près de toi." % call
		4:
			return "Le Glisseur stellaire ! Une petite soucoupe de nacre qui file comme une étoile, monte jusqu'à six cents mètres et se pose partout : sur Astralys, sur l'île flottante… Pour l'appeler, %s." % call
	return ""


# =================================================================== matériaux

func _mat(key: String) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.roughness = 0.6
	match key:
		"alu":
			m.albedo_color = Color(0.78, 0.79, 0.82)
			m.metallic = 0.85
			m.roughness = 0.32
		"alu_sombre":
			m.albedo_color = Color(0.16, 0.17, 0.19)
			m.metallic = 0.7
			m.roughness = 0.38
		"cable":
			m.albedo_color = Color(0.1, 0.1, 0.11)
			m.metallic = 0.6
			m.roughness = 0.45
		"sangle":
			m.albedo_color = Color(0.18, 0.2, 0.28)
			m.roughness = 0.85
		"voile":
			m.albedo_texture = _sail_texture()
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
			m.roughness = 0.62
			m.backlight_enabled = true
			m.backlight = Color(0.42, 0.36, 0.28)
			m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		"poche":
			m.albedo_color = Color(0.1, 0.16, 0.36)
			m.roughness = 0.35
			m.metallic_specular = 0.7
		"latte":
			m.albedo_color = Color(0.32, 0.32, 0.35)
			m.roughness = 0.5
		"pneu":
			m.albedo_color = Color(0.07, 0.07, 0.07)
			m.roughness = 0.9
		"bois":
			m.albedo_texture = _tex("res://assets/textures/carene/planches_cabane.png")
			m.albedo_color = Color(0.86, 0.66, 0.46)
			m.roughness = 0.75
			if _tex("res://assets/textures/carene/planches_cabane_n.png") != null:
				m.normal_enabled = true
				m.normal_texture = _tex("res://assets/textures/carene/planches_cabane_n.png")
		"bois_clair":
			m.albedo_color = Color(0.74, 0.56, 0.36)
			m.roughness = 0.55
		"laiton":
			m.albedo_texture = _tex("res://assets/textures/cliquetis/laiton.png")
			m.albedo_color = Color(1, 0.92, 0.75)
			m.metallic = 0.85
			m.roughness = 0.28
		"cuivre":
			m.albedo_texture = _tex("res://assets/textures/cliquetis/cuivre.png")
			m.metallic = 0.6
			m.roughness = 0.4
		"fer":
			m.albedo_color = Color(0.13, 0.13, 0.14)
			m.metallic = 0.7
			m.roughness = 0.5
		"helice":
			m.albedo_color = Color(0.55, 0.36, 0.2)
			m.roughness = 0.35
			m.metallic_specular = 0.7
		"ballon":
			m.albedo_texture = _envelope_texture()
			m.roughness = 0.7
			m.backlight_enabled = true
			m.backlight = Color(0.3, 0.27, 0.22)
			m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		"empennage":
			m.albedo_color = Color(0.1, 0.17, 0.3)
			m.roughness = 0.6
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
		"corde":
			m.albedo_color = Color(0.55, 0.46, 0.32)
			m.roughness = 0.95
		"lanterne":
			m.albedo_color = Color(1.0, 0.8, 0.45)
			m.emission_enabled = true
			m.emission = Color(1.0, 0.7, 0.35)
			m.emission_energy_multiplier = 2.0
		"verre":
			m.albedo_color = Color(0.7, 0.85, 1.0, 0.16)
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.metallic = 0.2
			m.roughness = 0.04
			m.metallic_specular = 1.0
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
		"siege":
			m.albedo_color = Color(0.35, 0.24, 0.42)
			m.roughness = 0.8
		"nacre_sombre":
			m.albedo_color = Color(0.32, 0.34, 0.42)
			m.metallic = 0.85
			m.roughness = 0.22
		"lueur":
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			m.albedo_color = Color(0.55, 0.85, 1.0)
			m.emission_enabled = true
			m.emission = Color(0.4, 0.8, 1.0)
			m.emission_energy_multiplier = 3.0
		"lueur_violette":
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			m.albedo_color = Color(0.8, 0.6, 1.0)
			m.emission_enabled = true
			m.emission = Color(0.75, 0.5, 1.0)
			m.emission_energy_multiplier = 2.5
		"halo":
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			var gt := GradientTexture2D.new()
			gt.fill = GradientTexture2D.FILL_RADIAL
			gt.fill_from = Vector2(0.5, 0.5)
			gt.fill_to = Vector2(1.0, 0.5)
			var gr := Gradient.new()
			gr.set_color(0, Color(1, 1, 1, 1))
			gr.set_color(1, Color(1, 1, 1, 0))
			gt.gradient = gr
			m.albedo_texture = gt
			m.albedo_color = Color(0.5, 0.85, 1.0, 0.5)
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
		"manche":
			m.albedo_color = Color(1.0, 0.45, 0.15)
			m.roughness = 0.8
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mats[key] = m
	return m


func _tex(path: String) -> Texture2D:
	return load(path) if ResourceLoader.exists(path) else null


## La nacre de la soucoupe : un reflet irisé (couches minces) qui change avec l'angle.
func _pearl() -> Material:
	if _mats.has("nacre"):
		return _mats["nacre"]
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
uniform vec3 base : source_color = vec3(0.9, 0.91, 0.95);
uniform float seams = 18.0;
varying vec3 lp;
void vertex() { lp = VERTEX; }
void fragment() {
	float f = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 1.6);
	vec3 irid = 0.5 + 0.5 * cos(6.2831 * (f * 1.15 + lp.y * 0.35 + vec3(0.0, 0.33, 0.67)) + 0.6);
	float ang = atan(lp.z, lp.x);
	float s = abs(fract(ang * seams / 6.2831) - 0.5);
	float seam = smoothstep(0.0, 0.025, s);
	float ring = smoothstep(0.0, 0.03, abs(fract(length(lp.xz) * 1.25) - 0.5));
	vec3 c = mix(base, base * irid * 1.08, 0.24 * f + 0.05);
	ALBEDO = c * mix(0.78, 1.0, seam * ring);
	METALLIC = 0.72;
	ROUGHNESS = 0.14 + 0.1 * (1.0 - seam * ring);
	SPECULAR = 0.7;
	EMISSION = irid * f * 0.06;
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	_mats["nacre"] = m
	return m


## La toile de l'Alouette : des lés colorés (crème, safran, vermillon, bleu nuit), coutures,
## surpiqûres, grain du tissu ; bord d'attaque en mylar bleu.
func _sail_texture() -> Texture2D:
	var w: int = 512
	var h: int = 256
	var img := Image.create(w, h, true, Image.FORMAT_RGB8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7601
	var creme := Color(0.93, 0.89, 0.8)
	var safran := Color(0.96, 0.69, 0.16)
	var verm := Color(0.86, 0.27, 0.16)
	var nuit := Color(0.12, 0.2, 0.42)
	for y in range(h):
		var v: float = float(y) / h
		for x in range(w):
			var u: float = float(x) / (w - 1)
			var s: float = absf(u - 0.5) * 2.0
			var c: Color
			if s < 0.1:
				c = creme
			elif s < 0.34:
				c = safran
			elif s < 0.5:
				c = creme
			elif s < 0.74:
				c = verm
			elif s < 0.86:
				c = creme
			else:
				c = nuit
			if v < 0.13:
				c = Color(0.11, 0.17, 0.38)
			# coutures (doubles) entre les lés, surpiqûres pointillées
			for b in [0.1, 0.34, 0.5, 0.74, 0.86]:
				var d: float = absf(s - b) * w * 0.5
				if d < 1.2:
					c = c.darkened(0.35)
				elif d < 3.0 and int(y / 3) % 2 == 0:
					c = c.darkened(0.12)
			# grain du tissu
			var g: float = rng.randf_range(-0.025, 0.025) + (0.015 if (x + y) % 2 == 0 else -0.015)
			c = Color(clampf(c.r + g, 0, 1), clampf(c.g + g, 0, 1), clampf(c.b + g, 0, 1))
			# bord de fuite ourlé
			if v > 0.965:
				c = c.darkened(0.25)
			img.set_pixel(x, y, c)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


## L'enveloppe de l'Albatros : 16 fuseaux ivoire, coutures, bandes bleu nuit, sangle de charge.
func _envelope_texture() -> Texture2D:
	var w: int = 512
	var h: int = 256
	var img := Image.create(w, h, true, Image.FORMAT_RGB8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7602
	for y in range(h):
		var v: float = float(y) / h
		for x in range(w):
			var u: float = float(x) / w
			var gore: int = int(u * 16.0)
			var c: Color = Color(0.94, 0.91, 0.83) if gore % 2 == 0 else Color(0.89, 0.85, 0.76)
			var fu: float = fmod(u * 16.0, 1.0)
			if fu < 0.03 or fu > 0.97:
				c = c.darkened(0.3)
			if (v > 0.1 and v < 0.13) or (v > 0.87 and v < 0.9):
				c = Color(0.1, 0.17, 0.32)
			if v > 0.135 and v < 0.145:
				c = Color(0.75, 0.6, 0.25)
			# la sangle de charge, de part et d'autre (u = 0,25 et 0,75 : les flancs)
			var side: float = minf(absf(u - 0.25), absf(u - 0.75)) * w
			if side < 2.5 and v > 0.2 and v < 0.8:
				c = Color(0.55, 0.42, 0.26)
			var g: float = rng.randf_range(-0.02, 0.02)
			c = Color(clampf(c.r + g, 0, 1), clampf(c.g + g, 0, 1), clampf(c.b + g, 0, 1))
			img.set_pixel(x, y, c)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


# =================================================================== petites pièces

func st_set(st: SurfaceTool, n: Vector3, uv: Vector2) -> void:
	st.set_normal(n)
	st.set_uv(uv)


func _mi(parent: Node3D, mesh: Mesh, mat: Material, xf: Transform3D = Transform3D()) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.transform = xf
	parent.add_child(mi)
	return mi


## Un tube entre deux points (repère de parent).
func _tube(parent: Node3D, a: Vector3, b: Vector3, r: float, key: String, seg: int = 8) -> MeshInstance3D:
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = maxf(a.distance_to(b), 0.001)
	cm.radial_segments = seg
	cm.rings = 1
	var d: Vector3 = (b - a).normalized()
	var up: Vector3 = d
	var side: Vector3 = up.cross(Vector3.FORWARD if absf(up.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
	var fwd: Vector3 = side.cross(up).normalized()
	var bas := Basis(side, up, fwd)
	var mi := _mi(parent, cm, _mat(key) if key != "nacre" else _pearl(), Transform3D(bas, (a + b) * 0.5))
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if r < 0.012 else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	return mi


func _ball(parent: Node3D, at: Vector3, r: float, key: String, seg: int = 10) -> MeshInstance3D:
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	sm.radial_segments = seg
	sm.rings = maxi(seg / 2, 4)
	return _mi(parent, sm, _mat(key) if key != "nacre" else _pearl(), Transform3D(Basis(), at))


func _boxm(parent: Node3D, size: Vector3, xf: Transform3D, key: String) -> MeshInstance3D:
	var bm := BoxMesh.new()
	bm.size = size
	return _mi(parent, bm, _mat(key), xf)


## Une pale d'hélice (vrillée, effilée), le long de +X, à plat dans le plan XY.
func _blade_mesh(length: float, chord: float, twist: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n: int = 8
	var rows: Array = []
	for i in range(n + 1):
		var t: float = float(i) / n
		var x: float = 0.06 + t * length
		var c: float = chord * (0.55 + 0.9 * sin(minf(t * 1.25, 1.0) * PI * 0.5)) * (1.0 - 0.75 * t * t)
		var tw: float = twist * (1.0 - t)
		var lead := Vector3(x, cos(tw) * c * 0.5, sin(tw) * c * 0.5)
		var trail := Vector3(x, -cos(tw) * c * 0.5, -sin(tw) * c * 0.5)
		var mid := Vector3(x, 0, 0) + Vector3(0, -sin(tw), cos(tw)) * c * 0.08
		rows.append([lead, mid, trail])
	for i in range(n):
		for k in range(2):
			var a: Vector3 = rows[i][k]
			var b: Vector3 = rows[i][k + 1]
			var c2: Vector3 = rows[i + 1][k]
			var d: Vector3 = rows[i + 1][k + 1]
			for tri in [[a, c2, b], [b, c2, d], [a, b, c2], [b, d, c2]]:
				var nn: Vector3 = (tri[1] - tri[0]).cross(tri[2] - tri[0]).normalized()
				for v in tri:
					st.set_normal(nn)
					st.add_vertex(v)
	return st.commit()


## Une hélice (moyeu + pales), qui tourne autour de son axe local Z.
func _propeller(parent: Node3D, at: Vector3, radius: float, blades: int, key: String = "helice") -> Node3D:
	var hub := Node3D.new()
	hub.position = at
	parent.add_child(hub)
	var spin := Node3D.new()
	spin.name = "Rotor"
	hub.add_child(spin)
	var bm: ArrayMesh = _blade_mesh(radius, radius * 0.2, 0.55)
	for k in range(blades):
		var b := _mi(spin, bm, _mat(key), Transform3D(Basis(Vector3.BACK, TAU * k / blades), Vector3.ZERO))
		b.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = radius * 0.09
	cone.height = radius * 0.22
	cone.radial_segments = 12
	_mi(spin, cone, _mat("laiton"), Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), Vector3(0, 0, -radius * 0.08)))
	# le disque flou (visible quand elle tourne vite)
	var disc := CylinderMesh.new()
	disc.top_radius = radius
	disc.bottom_radius = radius
	disc.height = 0.005
	disc.radial_segments = 32
	var dm := StandardMaterial3D.new()
	dm.albedo_color = Color(0.62, 0.48, 0.32, 0.0)
	dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dm.cull_mode = BaseMaterial3D.CULL_DISABLED
	var dmi := _mi(hub, disc, dm, Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO))
	dmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	dmi.name = "Flou"
	if not parts.has("props"):
		parts["props"] = []
	parts["props"].append(hub)
	return hub


# =================================================================== les modèles

func _build_model() -> void:
	if rig != null:
		rig.queue_free()
	parts = {}
	rig = Node3D.new()
	rig.name = "Aeronef_niveau_%d" % lvl
	add_child(rig)
	rig.visible = false
	match lvl:
		1:
			_build_glider(false)
		2:
			_build_glider(true)
		3:
			_build_albatros()
		4:
			_build_glisseur()
	_make_loop()


## Un modèle immobile (pour la vitrine de l'Atelier) : le même que le véhicule du niveau n.
func make_display(n: int) -> Node3D:
	var keep_rig: Node3D = rig
	var keep_parts: Dictionary = parts
	var keep_lvl: int = lvl
	lvl = n
	parts = {}
	rig = Node3D.new()
	rig.name = "Maquette_%d" % n
	match n:
		1:
			_build_glider(false)
		2:
			_build_glider(true)
		3:
			_build_albatros()
		4:
			_build_glisseur()
	var out: Node3D = rig
	rig = keep_rig
	parts = keep_parts
	lvl = keep_lvl
	return out


## L'aile delta (repère : origine au pied du pilote debout, -Z vers l'avant). Le point
## d'accroche (quille) est 2,05 m au-dessus.
func _build_glider(pedal: bool) -> void:
	var wing := Node3D.new()
	wing.name = "Aile"
	wing.position = Vector3(0, 2.05, 0)
	rig.add_child(wing)
	parts["aile"] = wing
	var nose := Vector3(0, 0.06, -1.75)
	var tip_r := Vector3(5.1, 0.32, 0.7)
	var tip_l := Vector3(-5.1, 0.32, 0.7)
	var tipte_r := Vector3(4.95, 0.4, 1.65)
	var tipte_l := Vector3(-4.95, 0.4, 1.65)
	var keel_end := Vector3(0, 0.0, 1.55)
	# la toile : une surface gonflée entre le bord d'attaque et le bord de fuite festonné
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ns: int = 28
	var nc: int = 10
	var grid: Array = []
	for i in range(ns + 1):
		var s: float = -1.0 + 2.0 * i / ns
		var a: float = absf(s)
		var tip: Vector3 = tip_r if s >= 0.0 else tip_l
		var le: Vector3 = nose.lerp(tip, a)
		var te: Vector3 = keel_end.lerp(tipte_r if s >= 0.0 else tipte_l, a)
		# festons entre les lattes
		var batt: float = absf(sin(a * PI * 4.5))
		te += Vector3(0, 0.02, -0.1 * batt * (1.0 - a))
		te.y += 0.16 * a                           # vrillage en bout d'aile
		var row: Array = []
		for j in range(nc + 1):
			var v: float = float(j) / nc
			var p: Vector3 = le.lerp(te, v)
			p.y += 0.24 * sin(PI * pow(v, 0.8)) * (1.0 - pow(a, 1.6)) + 0.04 * (1.0 - a)
			p.y -= 0.05 * a * v
			row.append(p)
		grid.append(row)
	for i in range(ns):
		for j in range(nc):
			var p00: Vector3 = grid[i][j]
			var p10: Vector3 = grid[i + 1][j]
			var p01: Vector3 = grid[i][j + 1]
			var p11: Vector3 = grid[i + 1][j + 1]
			var u0: float = float(i) / ns
			var u1: float = float(i + 1) / ns
			var v0: float = float(j) / nc
			var v1: float = float(j + 1) / nc
			for tri in [[p00, p01, p10, Vector2(u0, v0), Vector2(u0, v1), Vector2(u1, v0)], [p10, p01, p11, Vector2(u1, v0), Vector2(u0, v1), Vector2(u1, v1)]]:
				var nn: Vector3 = (tri[2] - tri[0]).cross(tri[1] - tri[0]).normalized()
				if nn.y < 0.0:
					nn = -nn
				for k in range(3):
					st.set_normal(nn)
					st.set_uv(tri[3 + k])
					st.add_vertex(tri[k])
	var sail := _mi(wing, st.commit(), _mat("voile"))
	sail.name = "Toile"
	# bords d'attaque (le tube dans sa poche de mylar), quille, transversale, mât et haubans
	for tip in [tip_l, tip_r]:
		_tube(wing, nose, tip, 0.055, "poche", 10)
		var cross_at: Vector3 = nose.lerp(tip, 0.52)
		_tube(wing, Vector3(0, 0.05, 0.12), cross_at + Vector3(0, -0.03, 0), 0.03, "alu", 8)
	_tube(wing, nose + Vector3(0, -0.04, 0), keel_end + Vector3(0, -0.04, 0.12), 0.032, "alu", 8)
	var king := Vector3(0, 1.18, 0.1)
	_tube(wing, Vector3(0, 0.0, 0.1), king, 0.022, "alu", 8)
	for tip in [tip_l, tip_r]:
		_tube(wing, king, tip, 0.005, "cable", 4)
	_tube(wing, king, nose, 0.005, "cable", 4)
	_tube(wing, king, keel_end, 0.005, "cable", 4)
	# les lattes, sur le dessus de la toile
	for i in [2, 4, 6, 8, 10, 12, 16, 18, 20, 22, 24, 26]:
		var row2: Array = grid[i]
		for j in range(nc - 1):
			var a2: Vector3 = row2[j] + Vector3(0, 0.012, 0)
			var b2: Vector3 = row2[j + 1] + Vector3(0, 0.012, 0)
			_tube(wing, a2, b2, 0.007, "latte", 4)
	# le trapèze (barre de contrôle) et les câbles inférieurs
	var bar_l := Vector3(-0.72, -1.42, -0.6)
	var bar_r := Vector3(0.72, -1.42, -0.6)
	_tube(wing, Vector3(0, -0.05, 0.05), bar_l, 0.022, "alu", 8)
	_tube(wing, Vector3(0, -0.05, 0.05), bar_r, 0.022, "alu", 8)
	_tube(wing, bar_l, bar_r, 0.02, "alu_sombre", 8)
	_ball(wing, bar_l, 0.03, "alu_sombre", 6)
	_ball(wing, bar_r, 0.03, "alu_sombre", 6)
	for b in [bar_l, bar_r]:
		_tube(wing, b, nose, 0.005, "cable", 4)
		_tube(wing, b, keel_end, 0.005, "cable", 4)
		_tube(wing, b, tip_l if b.x < 0 else tip_r, 0.005, "cable", 4)
		_tube(wing, b, tipte_l if b.x < 0 else tipte_r, 0.004, "cable", 4)
	# le point d'accroche et la sangle du harnais (l'autre bout suit le dos du pilote)
	_ball(wing, Vector3(0, -0.06, 0.08), 0.04, "alu_sombre", 6)
	var strap := _tube(wing, Vector3(0, -0.06, 0.08), Vector3(0, -0.9, 0.08), 0.018, "sangle", 6)
	parts["sangle"] = strap
	parts["accroche"] = Vector3(0, -0.06, 0.08)
	parts["barre"] = (bar_l + bar_r) * 0.5
	# un petit fanion au bout de la quille
	var fl := MeshInstance3D.new()
	var pm := ArrayMesh.new()
	var parr: Array = []
	parr.resize(Mesh.ARRAY_MAX)
	parr[Mesh.ARRAY_VERTEX] = PackedVector3Array([Vector3(-0.2, 0.09, 0), Vector3(0.25, 0.0, 0), Vector3(-0.2, -0.09, 0)])
	parr[Mesh.ARRAY_NORMAL] = PackedVector3Array([Vector3.BACK, Vector3.BACK, Vector3.BACK])
	pm.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, parr)
	fl.mesh = pm
	fl.material_override = _mat("manche")
	fl.position = keel_end + Vector3(0, 0.12, 0.22)
	fl.rotation.y = PI * 0.5
	wing.add_child(fl)
	parts["fanion"] = fl
	if pedal:
		_build_pedal_frame(wing)
	else:
		# le cocon du harnais (les jambes y sont allongées en vol)
		var pod := MeshInstance3D.new()
		var cm := CapsuleMesh.new()
		cm.radius = 0.23
		cm.height = 1.3
		pod.mesh = cm
		pod.material_override = _mat("sangle")
		pod.transform = Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0.78, 0.55))
		rig.add_child(pod)
		parts["cocon"] = pod


## Le pédalier de l'Alouette à hélice : siège allongé, manivelle, chaîne, hélice propulsive,
## trois petites roues.
func _build_pedal_frame(wing: Node3D) -> void:
	var f := Node3D.new()
	f.name = "Pedalier"
	rig.add_child(f)
	# la poutre (de la quille jusqu'au train), en tubes
	var hang := Vector3(0, 1.98, 0.08)
	var seat := Vector3(0, 0.62, 0.12)
	var crank := Vector3(0, 0.62, -1.05)
	var rear := Vector3(0, 0.5, 0.95)
	_tube(f, hang, seat + Vector3(0, 0.3, 0.1), 0.028, "alu", 8)
	_tube(f, seat, crank, 0.03, "alu_sombre", 8)
	_tube(f, seat, rear, 0.03, "alu_sombre", 8)
	_tube(f, rear, Vector3(0, 1.62, 1.45), 0.026, "alu_sombre", 8)
	_tube(f, Vector3(0, 1.62, 1.45), Vector3(0, 2.0, 1.4), 0.022, "alu", 8)
	_tube(f, Vector3(0, 1.62, 1.45), hang + Vector3(0, -0.08, 0.3), 0.02, "alu", 8)
	# le siège (toile tendue sur un cadre)
	var sb := _boxm(f, Vector3(0.42, 0.05, 0.55), Transform3D(Basis(Vector3.RIGHT, -0.12), seat + Vector3(0, 0.06, 0.05)), "siege")
	sb.name = "Siege"
	_boxm(f, Vector3(0.42, 0.6, 0.05), Transform3D(Basis(Vector3.RIGHT, 0.55), seat + Vector3(0, 0.32, 0.36)), "siege")
	# le pédalier : plateau, manivelles, pédales
	var crank_n := Node3D.new()
	crank_n.position = crank
	f.add_child(crank_n)
	var plate := CylinderMesh.new()
	plate.top_radius = 0.11
	plate.bottom_radius = 0.11
	plate.height = 0.012
	plate.radial_segments = 20
	_mi(crank_n, plate, _mat("laiton"), Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(0.05, 0, 0)))
	var arms := Node3D.new()
	arms.name = "Manivelles"
	crank_n.add_child(arms)
	for s in [-1.0, 1.0]:
		_tube(arms, Vector3(s * 0.07, 0, 0), Vector3(s * 0.07, 0.17 * s, 0), 0.012, "alu_sombre", 6)
		_boxm(arms, Vector3(0.1, 0.02, 0.06), Transform3D(Basis(), Vector3(s * 0.12, 0.17 * s, 0)), "fer")
	parts["manivelles"] = arms
	# la chaîne jusqu'à l'arbre de l'hélice, à l'arrière
	var shaft := Vector3(0, 1.62, 1.55)
	_tube(f, crank + Vector3(0.05, 0.1, 0), shaft + Vector3(0.05, 0.05, -0.05), 0.006, "fer", 4)
	_tube(f, crank + Vector3(0.05, -0.1, 0), shaft + Vector3(0.05, -0.05, -0.05), 0.006, "fer", 4)
	_propeller(f, shaft + Vector3(0, 0, 0.12), 0.82, 2)
	# le train : une roue avant, deux arrière
	for w in [Vector3(0, 0.17, -1.2), Vector3(-0.48, 0.17, 0.7), Vector3(0.48, 0.17, 0.7)]:
		var wm := CylinderMesh.new()
		wm.top_radius = 0.17
		wm.bottom_radius = 0.17
		wm.height = 0.07
		wm.radial_segments = 16
		_mi(f, wm, _mat("pneu"), Transform3D(Basis(Vector3.BACK, PI * 0.5), w))
		_tube(f, w, (crank if w.z < 0.0 else seat) + Vector3(0, -0.02, 0), 0.016, "alu", 6)
	parts["siege"] = seat


## L'Albatros (repère : origine sous les patins de la nacelle, -Z vers l'avant).
func _build_albatros() -> void:
	var env := Node3D.new()
	env.name = "Enveloppe"
	env.position = Vector3(0, 7.3, 0)
	rig.add_child(env)
	parts["enveloppe"] = env
	# le ballon : un fuseau plus plein vers l'avant
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var nl: int = 40
	var nr: int = 32
	var length: float = 15.0
	var rmax: float = 2.75
	var rings: Array = []
	for i in range(nl + 1):
		var t: float = float(i) / nl
		var z: float = -length * 0.5 + t * length
		var tt: float = t * 2.0 - 1.0
		var shape: float = pow(maxf(1.0 - tt * tt, 0.0), 0.5) * (1.0 - 0.22 * maxf(tt, 0.0)) * (1.0 + 0.06 * (1.0 - tt))
		if t > 0.98:
			shape *= 0.6
		var r: float = rmax * shape
		var row: Array = []
		for k in range(nr + 1):
			var a: float = TAU * k / nr
			# fuseaux : léger gonflement entre les coutures
			var g: float = 1.0 + 0.012 * absf(sin(a * 8.0))
			row.append(Vector3(cos(a) * r * g, sin(a) * r * g * 0.98, z))
		rings.append(row)
	for i in range(nl):
		for k in range(nr):
			var a0: Vector3 = rings[i][k]
			var a1: Vector3 = rings[i][k + 1]
			var b0: Vector3 = rings[i + 1][k]
			var b1: Vector3 = rings[i + 1][k + 1]
			var uv_a0 := Vector2(float(k) / nr, float(i) / nl)
			var uv_a1 := Vector2(float(k + 1) / nr, float(i) / nl)
			var uv_b0 := Vector2(float(k) / nr, float(i + 1) / nl)
			var uv_b1 := Vector2(float(k + 1) / nr, float(i + 1) / nl)
			for tri in [[a0, b0, a1, uv_a0, uv_b0, uv_a1], [a1, b0, b1, uv_a1, uv_b0, uv_b1]]:
				for m in range(3):
					var vtx: Vector3 = tri[m]
					var cz: float = clampf(vtx.z, -length * 0.5, length * 0.5)
					var nrm := Vector3(vtx.x, vtx.y, (cz / (length * 0.5)) * 1.4).normalized()
					st.set_normal(nrm)
					st.set_uv(tri[3 + m])
					st.add_vertex(vtx)
	var em := _mi(env, st.commit(), _mat("ballon"))
	em.name = "Ballon"
	# l'empennage : quatre ailerons en croix, encadrés de laiton
	for k2 in range(4):
		var ang: float = PI * 0.25 + PI * 0.5 * k2
		var fin := Node3D.new()
		fin.position = Vector3(0, 0, length * 0.36)
		fin.rotation.z = ang
		env.add_child(fin)
		var fm := ArrayMesh.new()
		var arr: Array = []
		arr.resize(Mesh.ARRAY_MAX)
		var pts := PackedVector3Array([Vector3(1.2, 0, -1.4), Vector3(3.1, 0, 0.6), Vector3(3.0, 0, 1.6), Vector3(1.0, 0, 1.9)])
		var vv := PackedVector3Array([pts[0], pts[1], pts[2], pts[0], pts[2], pts[3]])
		var nn := PackedVector3Array()
		for _i in range(6):
			nn.append(Vector3.UP)
		arr[Mesh.ARRAY_VERTEX] = vv
		arr[Mesh.ARRAY_NORMAL] = nn
		fm.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		_mi(fin, fm, _mat("empennage"))
		for e in [[pts[0], pts[1]], [pts[1], pts[2]], [pts[2], pts[3]]]:
			_tube(fin, e[0], e[1], 0.03, "laiton", 6)
	# le nez : une coiffe de laiton ; la queue : un cône
	_ball(env, Vector3(0, 0, -length * 0.5 + 0.12), 0.38, "laiton", 12)
	# la sangle de charge et les suspentes jusqu'à la nacelle
	var gon := Node3D.new()
	gon.name = "Nacelle"
	rig.add_child(gon)
	parts["nacelle"] = gon
	var gl: float = 3.6
	var gw: float = 1.45
	var gh: float = 0.95
	# la coque : un petit bateau de bois (fuseau en U, proue et poupe relevées), liston de laiton
	var hs := SurfaceTool.new()
	hs.begin(Mesh.PRIMITIVE_TRIANGLES)
	var nzs: int = 18
	var nth: int = 10
	var secs: Array = []
	for i in range(nzs + 1):
		var z: float = -gl * 0.5 + gl * float(i) / nzs
		var e: float = absf(z) / (gl * 0.5)
		var hw: float = gw * 0.5 * sqrt(maxf(1.0 - pow(e, 3.0), 0.0)) + 0.02
		var bot: float = 0.3 + 0.18 * e * e
		var top: float = 0.3 + gh + 0.14 * e * e
		var row: Array = []
		for k in range(nth + 1):
			var th: float = PI * float(k) / nth
			row.append(Vector3(hw * cos(th) * (1.0 - 0.12 * sin(th)), top - (top - bot) * pow(sin(th), 0.55), z))
		secs.append(row)
	for i in range(nzs):
		for k in range(nth):
			var q00: Vector3 = secs[i][k]
			var q01: Vector3 = secs[i][k + 1]
			var q10: Vector3 = secs[i + 1][k]
			var q11: Vector3 = secs[i + 1][k + 1]
			for tri in [[q00, q10, q01], [q01, q10, q11]]:
				var nn: Vector3 = (tri[1] - tri[0]).cross(tri[2] - tri[0]).normalized()
				var cc: Vector3 = (tri[0] + tri[1] + tri[2]) / 3.0
				if nn.dot(Vector3(cc.x, cc.y - 0.9, 0)) < 0.0:
					nn = -nn
				for v in tri:
					st_set(hs, nn, Vector2(v.z * 1.2, (atan2(v.y - 1.0, v.x) + PI) * 0.8))
					hs.add_vertex(v)
	var hull_m: StandardMaterial3D = (_mat("bois") as StandardMaterial3D).duplicate()
	hull_m.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mi(gon, hs.commit(), hull_m).name = "Coque"
	_boxm(gon, Vector3(gw * 0.8, 0.05, gl * 0.7), Transform3D(Basis(), Vector3(0, 0.33, 0)), "bois_clair")
	for side in [0, nth]:
		for i2 in range(nzs):
			_tube(gon, (secs[i2][side] as Vector3) + Vector3(0, 0.02, 0), (secs[i2 + 1][side] as Vector3) + Vector3(0, 0.02, 0), 0.03, "laiton", 6)
	# les patins
	for s2 in [-0.5, 0.5]:
		_boxm(gon, Vector3(0.12, 0.1, gl * 0.9), Transform3D(Basis(), Vector3(s2, 0.05, 0)), "bois_clair")
		for z2 in [-1.1, 1.1]:
			_tube(gon, Vector3(s2, 0.08, z2), Vector3(s2 * 0.8, 0.32, z2), 0.03, "laiton", 6)
	# la barre (roue de gouvernail) à l'avant, sur son pied
	var wheel_at := Vector3(0, 1.32, -1.25)
	_tube(gon, Vector3(0, 0.35, -1.35), wheel_at + Vector3(0, -0.05, 0.05), 0.05, "laiton", 8)
	var wheel := Node3D.new()
	wheel.position = wheel_at
	wheel.rotation.x = -0.5
	gon.add_child(wheel)
	var tor := TorusMesh.new()
	tor.inner_radius = 0.24
	tor.outer_radius = 0.28
	tor.rings = 20
	tor.ring_segments = 6
	_mi(wheel, tor, _mat("bois_clair"), Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO))
	for k3 in range(8):
		var a3: float = TAU * k3 / 8.0
		_tube(wheel, Vector3.ZERO, Vector3(cos(a3) * 0.36, sin(a3) * 0.36, 0), 0.018, "bois_clair", 5)
	parts["roue"] = wheel
	# le moteur à l'arrière : un caisson de cuivre, une petite cheminée
	_boxm(gon, Vector3(0.9, 0.55, 0.6), Transform3D(Basis(), Vector3(0, 0.68, 1.25)), "cuivre")
	_tube(gon, Vector3(0.25, 0.95, 1.35), Vector3(0.25, 1.75, 1.45), 0.07, "fer", 8)
	parts["cheminee"] = Vector3(0.25, 1.8, 1.45)
	# deux bras porteurs et leurs hélices, de part et d'autre
	for s3 in [-1.0, 1.0]:
		var root := Vector3(s3 * gw * 0.5, 1.05, 0.9)
		var tipp := Vector3(s3 * 1.95, 1.35, 0.95)
		_tube(gon, root, tipp, 0.045, "fer", 8)
		_tube(gon, root + Vector3(0, -0.45, 0), tipp, 0.03, "fer", 6)
		var nac := CylinderMesh.new()
		nac.top_radius = 0.13
		nac.bottom_radius = 0.16
		nac.height = 0.55
		nac.radial_segments = 12
		_mi(gon, nac, _mat("laiton"), Transform3D(Basis(Vector3.RIGHT, PI * 0.5), tipp + Vector3(0, 0, 0.1)))
		_propeller(gon, tipp + Vector3(0, 0, 0.42), 0.68, 3)
	# la lanterne de proue
	_ball(gon, Vector3(0, 1.62, -gl * 0.5 - 0.05), 0.11, "lanterne", 10)
	_tube(gon, Vector3(0, 1.5, -gl * 0.5 - 0.05), Vector3(0, 0.3 + gh + 0.1, -gl * 0.5 + 0.15), 0.015, "laiton", 6)
	# les suspentes : de la sangle de charge du ballon aux coins de la nacelle
	var top_y: float = 7.3 - 2.2
	for s4 in [-1.0, 1.0]:
		for zz in [-1.4, -0.4, 0.6, 1.5]:
			var a4 := Vector3(s4 * 2.15, top_y + 0.15 + 0.2 * (1.0 - absf(zz) / 1.5), zz * 2.6)
			var b4 := Vector3(s4 * gw * 0.5, 0.32 + gh, clampf(zz, -1.4, 1.4))
			_tube(rig, a4, b4, 0.012, "corde", 4)
	# le nom, peint de chaque côté
	for s5 in [-1.0, 1.0]:
		var lab := Label3D.new()
		lab.text = "ALBATROS"
		lab.font_size = 160
		lab.pixel_size = 0.006
		lab.modulate = Color(0.1, 0.17, 0.32)
		lab.outline_size = 0
		lab.double_sided = false
		lab.position = Vector3(s5 * 2.97, 7.3, -0.8)
		lab.rotation.y = s5 * PI * 0.5
		rig.add_child(lab)
	parts["siege"] = Vector3(0, 0.36, -0.6)


## Le Glisseur stellaire (repère : origine au sol sous les pieds dépliés).
func _build_glisseur() -> void:
	var body := Node3D.new()
	body.name = "Soucoupe"
	body.position = Vector3(0, 1.25, 0)
	rig.add_child(body)
	parts["corps"] = body
	var R: float = 2.65
	# la lentille : dessus bombé, dessous plus plat, profil de révolution
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ns: int = 48
	var prof: Array = []
	var nk: int = 14
	for i in range(nk + 1):
		var t: float = float(i) / nk
		var r: float = R * sin(t * PI * 0.5)
		var y: float = 0.62 * pow(cos(t * PI * 0.5), 0.9) + 0.02
		prof.append(Vector2(r, y))
	prof.append(Vector2(R + 0.06, 0.0))
	for i2 in range(nk, -1, -1):
		var t2: float = float(i2) / nk
		var r2: float = R * sin(t2 * PI * 0.5) * 0.98
		var y2: float = -0.42 * pow(cos(t2 * PI * 0.5), 0.8) - 0.02
		prof.append(Vector2(r2, y2))
	for j in range(prof.size() - 1):
		var p0: Vector2 = prof[j]
		var p1: Vector2 = prof[j + 1]
		for k in range(ns):
			var a0: float = TAU * k / ns
			var a1: float = TAU * (k + 1) / ns
			var v00 := Vector3(cos(a0) * p0.x, p0.y, sin(a0) * p0.x)
			var v01 := Vector3(cos(a1) * p0.x, p0.y, sin(a1) * p0.x)
			var v10 := Vector3(cos(a0) * p1.x, p1.y, sin(a0) * p1.x)
			var v11 := Vector3(cos(a1) * p1.x, p1.y, sin(a1) * p1.x)
			for tri in [[v00, v10, v01], [v01, v10, v11]]:
				var nn: Vector3 = (tri[1] - tri[0]).cross(tri[2] - tri[0])
				if nn.length() < 1e-6:
					nn = Vector3(tri[0].x, 0.0, tri[0].z)
				nn = nn.normalized()
				var c: Vector3 = (tri[0] + tri[1] + tri[2]) / 3.0
				if nn.dot(Vector3(c.x, c.y * 2.0, c.z)) < 0.0:
					nn = -nn
				for v in tri:
					st.set_normal(nn)
					st.add_vertex(v)
	st.generate_normals()
	var hull := _mi(body, st.commit(), _pearl())
	hull.name = "Coque"
	# l'anneau du bord : une couronne de nacre sombre, et seize feux qui tournent
	var tor := TorusMesh.new()
	tor.inner_radius = R - 0.07
	tor.outer_radius = R + 0.11
	tor.rings = 64
	tor.ring_segments = 10
	_mi(body, tor, _mat("nacre_sombre"))
	var lights: Array = []
	var cols: Array = [Color(0.45, 0.85, 1.0), Color(0.85, 0.55, 1.0), Color(1.0, 0.75, 0.45)]
	for k2 in range(16):
		var a2: float = TAU * k2 / 16.0
		var lm := StandardMaterial3D.new()
		lm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		var c2: Color = cols[k2 % 3]
		lm.albedo_color = c2
		lm.emission_enabled = true
		lm.emission = c2
		lm.emission_energy_multiplier = 2.0
		var sm := SphereMesh.new()
		sm.radius = 0.075
		sm.height = 0.15
		sm.radial_segments = 8
		sm.rings = 4
		var li := _mi(body, sm, lm, Transform3D(Basis(), Vector3(cos(a2) * (R + 0.13), 0.0, sin(a2) * (R + 0.13))))
		li.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		lights.append(lm)
	parts["feux"] = lights
	# la verrière : une bulle de verre, son cerclage de nacre sombre
	var dome := SphereMesh.new()
	dome.radius = 1.12
	dome.height = 2.24
	dome.is_hemisphere = true
	dome.radial_segments = 32
	dome.rings = 12
	var dmi := _mi(body, dome, _mat("verre"), Transform3D(Basis().scaled(Vector3(1, 0.95, 1.12)), Vector3(0, 0.42, 0.05)))
	dmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	dmi.name = "Verriere"
	var rim := TorusMesh.new()
	rim.inner_radius = 1.1
	rim.outer_radius = 1.2
	rim.rings = 40
	rim.ring_segments = 8
	_mi(body, rim, _mat("nacre_sombre"), Transform3D(Basis().scaled(Vector3(1, 1, 1.12)), Vector3(0, 0.43, 0.05)))
	# le siège et le pupitre (deux sphères de commande qui luisent)
	_boxm(body, Vector3(0.62, 0.12, 0.6), Transform3D(Basis(), Vector3(0, 0.5, 0.3)), "siege")
	_boxm(body, Vector3(0.62, 0.6, 0.1), Transform3D(Basis(Vector3.RIGHT, 0.25), Vector3(0, 0.82, 0.62)), "siege")
	_boxm(body, Vector3(0.9, 0.08, 0.34), Transform3D(Basis(Vector3.RIGHT, -0.5), Vector3(0, 0.85, -0.55)), "nacre_sombre")
	_ball(body, Vector3(-0.28, 0.93, -0.5), 0.07, "lueur", 10)
	_ball(body, Vector3(0.28, 0.93, -0.5), 0.07, "lueur_violette", 10)
	# le dessous : un anneau de lumière, un cœur de cristal
	var ring := TorusMesh.new()
	ring.inner_radius = 1.25
	ring.outer_radius = 1.42
	ring.rings = 48
	ring.ring_segments = 6
	var ri := _mi(body, ring, _mat("lueur"), Transform3D(Basis().scaled(Vector3(1, 0.4, 1)), Vector3(0, -0.4, 0)))
	ri.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parts["anneau"] = ri
	var core := _ball(body, Vector3(0, -0.43, 0), 0.32, "lueur_violette", 14)
	core.scale = Vector3(1, 0.4, 1)
	core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# un halo additif sous la coque (la « portance » lumineuse)
	var hq := QuadMesh.new()
	hq.size = Vector2(4.2, 4.2)
	var halo := _mi(body, hq, _mat("halo"), Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), Vector3(0, -0.55, 0)))
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parts["halo"] = halo
	var light := OmniLight3D.new()
	light.light_color = Color(0.55, 0.8, 1.0)
	light.light_energy = 1.2
	light.omni_range = 7.0
	light.shadow_enabled = false
	light.position = Vector3(0, -0.9, 0)
	body.add_child(light)
	parts["lumiere"] = light
	# trois pieds télescopiques (dépliés au sol)
	var legs: Array = []
	for k3 in range(3):
		var a3: float = TAU * k3 / 3.0 + PI / 6.0
		var leg := Node3D.new()
		leg.position = Vector3(cos(a3) * 1.3, -0.3, sin(a3) * 1.3)
		body.add_child(leg)
		_tube(leg, Vector3.ZERO, Vector3(cos(a3) * 0.35, -0.9, sin(a3) * 0.35), 0.05, "nacre_sombre", 8)
		var foot := CylinderMesh.new()
		foot.top_radius = 0.1
		foot.bottom_radius = 0.18
		foot.height = 0.06
		foot.radial_segments = 12
		_mi(leg, foot, _mat("nacre_sombre"), Transform3D(Basis(), Vector3(cos(a3) * 0.35, -0.93, sin(a3) * 0.35)))
		legs.append(leg)
	parts["pieds"] = legs
	parts["siege"] = Vector3(0, 1.25 + 0.56, 0.28)


# =================================================================== sons

func _make_loop() -> void:
	if _loop != null:
		_loop.queue_free()
		_loop = null
	_loop_name = {1: "deltaplane_vent", 2: "helice_pedale", 3: "aeronef_moteur", 4: "soucoupe_vol"}.get(lvl, "")
	if _loop_name == "" or rig == null:
		return
	var path: String = SFX_DIR + _loop_name + "_1.ogg"
	_loop = AudioStreamPlayer3D.new()
	_loop.name = "Son_" + _loop_name
	_loop.bus = "Bruitages" if AudioServer.get_bus_index("Bruitages") >= 0 else "Master"
	_loop.unit_size = 6.0
	_loop.max_distance = 90.0
	_loop.volume_db = -60.0
	_loop.position = Vector3(0, 1.5, 0)
	if ResourceLoader.exists(path):
		var s: AudioStream = load(path)
		if s is AudioStreamOggVorbis:
			(s as AudioStreamOggVorbis).loop = true
		elif s is AudioStreamWAV:
			(s as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
		_loop.stream = s
	rig.add_child(_loop)


func _tick_sound(delta: float) -> void:
	if _loop == null or _loop.stream == null:
		return
	var on: bool = rig.visible and state in ["vol", "envol", "atterrit", "arrive", "sol"]
	var want_db: float = -60.0
	var pitch: float = 1.0
	if on:
		match lvl:
			1:
				want_db = lerpf(-22.0, -6.0, clampf((speed - 5.0) / 12.0, 0.0, 1.0))
				pitch = lerpf(0.85, 1.25, clampf((speed - 5.0) / 12.0, 0.0, 1.0))
			2:
				want_db = lerpf(-30.0, -5.0, _pedal) if state != "sol" or _pedal > 0.05 else -40.0
				pitch = lerpf(0.7, 1.2, _pedal)
			3:
				want_db = -8.0
				pitch = lerpf(0.8, 1.15, clampf(speed / 13.0, 0.0, 1.0))
			4:
				want_db = -7.0
				pitch = lerpf(0.9, 1.35, clampf(speed / 42.0, 0.0, 1.0))
	_loop.volume_db = move_toward(_loop.volume_db, want_db, delta * 40.0)
	_loop.pitch_scale = lerpf(_loop.pitch_scale, pitch, clampf(delta * 3.0, 0.0, 1.0))
	if _loop.volume_db > -58.0 and not _loop.playing:
		_loop.play()
	elif _loop.volume_db <= -59.5 and _loop.playing:
		_loop.stop()


# =================================================================== le monde : sol, plafond, roche

func _player_pos() -> Vector3:
	return main._player_pos_v27()


func _excludes() -> Array:
	var ex: Array = []
	for b in [main.get("pc_body"), main.get("vr_body")]:
		if b != null and b is CollisionObject3D:
			ex.append((b as CollisionObject3D).get_rid())
	return ex


## Les îles flottantes (pour le dessous, qui n'a pas de collision) :
## [[centre, sommet (Y0), profondeur, objet île (coast_radius, height)], …]
func _floating() -> Array:
	var out: Array = []
	var c: Node = main.get("ciel_v54")
	if c != null and c.get("ile") != null and c.ile != null:
		out.append([c.ile.CENTER, float(c.ile.Y0), float(c.ile.DEPTH), c.ile])
	var f: Node = main.get("feerie_v58")
	if f != null and f.get("ile") != null and f.ile != null:
		out.append([f.ile.CENTER, float(f.ile.Y0), float(f.ile.DEPTH), f.ile])
	return out


func _astralys() -> Node:
	var a: Variant = main.get("astralys_v76")
	return a if a is Node else null


## Le dessous rocheux d'une île flottante au-dessus de (x, z) : [bas, haut] (vide si rien).
func _rock_span(x: float, z: float) -> Array:
	for fl in _floating():
		var cc: Vector3 = fl[0]
		var y0: float = fl[1]
		var depth: float = fl[2]
		var ile: Object = fl[3]
		var lx: float = x - cc.x
		var lz: float = z - cc.z
		var r: float = Vector2(lx, lz).length()
		if r > 130.0:
			continue
		var rr: float = float(ile.coast_radius(atan2(lz, lx))) * 1.12 + 2.5
		if r >= rr:
			continue
		var bottom: float = y0 - 4.0 - depth * (1.0 - pow(r / rr, 4.0 / 3.0)) - 2.0
		var top: float = float(ile.height(x, z))
		if top < -1e6:
			top = y0 + 1.0
		return [bottom, top]
	var a: Node = _astralys()
	if a != null and a.has_method("rock_span"):
		return a.rock_span(x, z)
	if a != null:
		var r2: float = Vector2(x - ASTRALYS_C.x, z - ASTRALYS_C.z).length()
		var ra: float = ASTRALYS_R + 8.0
		if r2 < ra:
			var top2: float = ASTRALYS_C.y
			if a.has_method("height"):
				var hh: float = float(a.height(x, z))
				if hh > -1e6:
					top2 = hh
			var bottom2: float = ASTRALYS_C.y - 6.0 - ASTRALYS_DEPTH * (1.0 - pow(r2 / ra, 4.0 / 3.0)) - 2.0
			return [bottom2, top2]
	return []


## Dans la roche d'une île flottante ?
func _in_rock(p: Vector3) -> bool:
	var a: Node = _astralys()
	if a != null and a.has_method("solid") and Vector2(p.x - ASTRALYS_C.x, p.z - ASTRALYS_C.z).length() < ASTRALYS_R + 60.0:
		return bool(a.solid(p))
	var sp: Array = _rock_span(p.x, p.z)
	return not sp.is_empty() and p.y > float(sp[0]) and p.y < float(sp[1]) - 0.6


## Le sol sous p : [hauteur, "sol" | "eau"] (le relief, la mer, le dessus des îles flottantes,
## et tout ce qui a une collision : toits, quais, ponts, la nacelle…).
func ground_below(p: Vector3) -> Array:
	var land: float = main._height_at(p.x, p.z)
	var y: float = land
	var kind: String = "sol"
	if land < SEA_Y:
		y = SEA_Y
		kind = "eau"
	var sp: Array = _rock_span(p.x, p.z)
	if not sp.is_empty() and float(sp[1]) <= p.y + 0.8 and float(sp[1]) > y:
		y = float(sp[1])
		kind = "sol"
	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(p + Vector3.UP * 0.8, p + Vector3.DOWN * 600.0, 1, _excludes())
	var hit: Dictionary = space.intersect_ray(q)
	if not hit.is_empty() and float(hit.position.y) > y:
		y = float(hit.position.y)
		kind = "sol"
	return [y, kind]


## Le relief le plus haut sous l'empreinte du véhicule (coins de la nacelle, bord de la
## soucoupe) : sur une pente, rien ne s'enfonce dans le sol.
func _footprint_floor(p: Vector3) -> float:
	var pts: Array = []
	match lvl:
		3:
			pts = [Vector3(-0.7, 0, -1.8), Vector3(0.7, 0, -1.8), Vector3(-0.7, 0, 1.8), Vector3(0.7, 0, 1.8)]
		4:
			for k in range(6):
				pts.append(Vector3(cos(TAU * k / 6.0) * 2.4, 0, sin(TAU * k / 6.0) * 2.4))
		_:
			return -INF
	var bas := Basis(Vector3.UP, yaw)
	var top: float = -INF
	for o in pts:
		var q: Vector3 = p + bas * (o as Vector3)
		top = maxf(top, float(main._height_at(q.x, q.z)))
	return top


## Le plafond au-dessus de p (ce qui a une collision, et le dessous des îles flottantes).
func ceiling_above(p: Vector3, reach: float) -> float:
	var c: float = INF
	var sp: Array = _rock_span(p.x, p.z)
	if not sp.is_empty() and float(sp[0]) > p.y:
		c = float(sp[0])
	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(p + Vector3.UP * 0.3, p + Vector3.UP * (reach + 0.3), 1 | 256, _excludes())
	var hit: Dictionary = space.intersect_ray(q)
	if not hit.is_empty():
		c = minf(c, float(hit.position.y))
	return c


## Les formes de collision du véhicule : [[décalage (repère du véhicule), forme, base locale]].
func _hull() -> Array:
	if parts.has("coque"):
		return parts["coque"]
	var out: Array = []
	match lvl:
		1, 2:
			var s := SphereShape3D.new()
			s.radius = 0.75
			out.append([Vector3(0, 1.0, 0), s, Basis()])
			var bx := BoxShape3D.new()
			bx.size = Vector3(8.4, 0.6, 2.0)
			out.append([Vector3(0, 2.3, 0.35), bx, Basis()])
		3:
			var s3 := SphereShape3D.new()
			s3.radius = 1.2
			out.append([Vector3(0, 0.95, 0), s3, Basis()])
			var cp := CapsuleShape3D.new()
			cp.radius = 2.55
			cp.height = 14.5
			out.append([Vector3(0, 7.3, -0.2), cp, Basis(Vector3.RIGHT, PI * 0.5)])
		4:
			var cy := CylinderShape3D.new()
			cy.radius = 2.75
			cy.height = 1.15
			out.append([Vector3(0, 1.25, 0), cy, Basis()])
			var s4 := SphereShape3D.new()
			s4.radius = 1.0
			out.append([Vector3(0, 1.9, 0.05), s4, Basis()])
	parts["coque"] = out
	return out


## Balaye les formes du véhicule le long de « step » ; renvoie [pas permis (on glisse le long
## des parois), normale du dernier choc (ou ZERO)].
func _sweep(p0: Vector3, step: Vector3) -> Array:
	var space := get_world_3d().direct_space_state
	var bas := Basis(Vector3.UP, yaw)
	var p: Vector3 = p0
	var normal := Vector3.ZERO
	var hull: Array = _hull()
	var ex: Array = _excludes()
	for it in range(3):
		if step.length() < 0.0005:
			step = Vector3.ZERO
			break
		var best: float = 1.0
		var best_i: int = -1
		for i in range(hull.size()):
			var h: Array = hull[i]
			var prm := PhysicsShapeQueryParameters3D.new()
			prm.shape = h[1]
			prm.transform = Transform3D(bas * (h[2] as Basis), p + bas * (h[0] as Vector3))
			prm.motion = step
			prm.collision_mask = 1
			prm.exclude = ex
			var res: PackedFloat32Array = space.cast_motion(prm)
			if res.size() == 2 and res[0] < best:
				best = res[0]
				best_i = i
		if best_i < 0:
			p += step
			step = Vector3.ZERO
			break
		var hh: Array = hull[best_i]
		var prm2 := PhysicsShapeQueryParameters3D.new()
		prm2.shape = hh[1]
		prm2.transform = Transform3D(bas * (hh[2] as Basis), p + bas * (hh[0] as Vector3) + step * minf(best + 0.05, 1.0))
		prm2.collision_mask = 1
		prm2.exclude = ex
		var info: Dictionary = space.get_rest_info(prm2)
		var n: Vector3 = info.get("normal", Vector3.ZERO)
		if n.length() < 0.1:
			n = -step.normalized()
		normal = n
		var done: Vector3 = step * maxf(best - 0.03, 0.0)
		p += done
		if best <= 0.0001:
			p += n * 0.03                       # déjà au contact : on se dégage un peu
		var rest: Vector3 = step - done
		rest -= n * minf(rest.dot(n), 0.0)
		step = rest
	if step != Vector3.ZERO:
		step = Vector3.ZERO
	return [p - p0, normal]


## Avance d'un pas en respectant les collisions ; renvoie la normale du choc (ou ZERO).
func _move(step: Vector3) -> Vector3:
	var r: Array = _sweep(pos, step)
	var allowed: Vector3 = r[0]
	var n: Vector3 = r[1]
	var q: Vector3 = pos + allowed
	# la roche des îles flottantes (pas de collision dessous) : on n'y entre pas
	var hc: Vector3 = Vector3.UP * (0.8 if lvl < 3 else 1.0)
	if _in_rock(q + hc) or (lvl == 3 and _in_rock(q + Vector3.UP * 7.3)):
		var qh := Vector3(q.x, pos.y, q.z)
		var qv := Vector3(pos.x, q.y, pos.z)
		if not _in_rock(qh + hc) and not (lvl == 3 and _in_rock(qh + Vector3.UP * 7.3)):
			q = qh
		elif not _in_rock(qv + hc):
			q = qv
		else:
			q = pos
		var away := Vector3(pos.x - q.x, 0, pos.z - q.z)
		n = Vector3.DOWN if vspeed > 0.0 else (away.normalized() if away.length() > 0.01 else Vector3.UP)
		vspeed = minf(vspeed, 0.0) if n == Vector3.DOWN else vspeed
	pos = q
	return n


# =================================================================== appel

## Peut-on appeler l'aéronef ici ? "" si oui, sinon la raison (texte du jeu).
func _blocked_reason(p: Vector3) -> String:
	if lvl <= 0:
		return "Tu n'as pas encore de machine volante. À Cliquetis, Philibert Vis, « l'inventeur sans invention », rêve d'en construire une…"
	var c: Node = main.get("ciel_v54")
	if c != null and bool(c.riding):
		return "Tu voles déjà sur le dos de Ventaile !"
	var b: Node = main.get("boat_v29")
	if b != null and bool(b.driving):
		return "Pas depuis la barque : accoste d'abord."
	var gr: Node = main.get("grande_v59")
	if gr != null and gr.has_method("riding") and bool(gr.riding()):
		return "Pas pendant le trajet ! Attends d'être arrivé."
	var az: Node = main.get("azur_v56")
	if az != null and az.get("ferry") != null and az.ferry != null and bool(az.ferry.riding):
		return "Pas à bord de L'Hirondelle !"
	var f: Node = main.get("feerie_v58")
	if f != null and f.has_method("contains") and bool(f.contains(p)):
		return "Au royaume des fées, la magie de l'Arbre-Monde garde le ciel : %s ne s'y déploie pas." % vehicle_name()
	var d: Node = main.get("donjon_v35")
	if d != null and d.has_method("is_inside") and bool(d.is_inside(p)):
		return "Sous terre, impossible de voler !"
	if main.has_method("_in_dungeon_v35") and bool(main._in_dungeon_v35(p)):
		return "Sous terre, impossible de voler !"
	if c != null and c.has_method("_in_castle_zone") and c.get("chateau") != null and c.chateau != null and bool(c._in_castle_zone(p, 4.0)):
		return "Le vent tourbillonne trop fort au-dessus de la Citadelle. Va sur l'Aire des Vents."
	var m: Node = main.get("mer_v55")
	if m != null and bool(m.get("swimming")):
		return "Sors de l'eau d'abord !"
	if _roofed(p):
		return "Pas sous un toit : sors à l'air libre pour %s." % ("déployer l'Alouette" if lvl <= 2 else "appeler " + vehicle_name())
	return ""


func _roofed(p: Vector3) -> bool:
	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(p + Vector3.UP * 2.2, p + Vector3.UP * 40.0, 1 | 256, _excludes())
	return not space.intersect_ray(q).is_empty()


func _facing() -> Vector3:
	var f := Vector3.FORWARD
	if bool(main.xr_active):
		f = -main.xr_camera.global_transform.basis.z
	elif main.get("hero_v28") != null and main.hero_v28 != null:
		f = main.hero_v28.facing
	f.y = 0.0
	return f.normalized() if f.length() > 0.01 else Vector3.FORWARD


## Les pieds du joueur.
func _feet() -> Vector3:
	if bool(main.xr_active):
		return main.vr_body.global_position
	return main.pc_body.global_position if main.get("pc_body") != null else _player_pos()


## Un point haut pour le deltaplane : [ok, élan (direction)].
## (a) assez de vide sous soi (en pleine chute, ou sur un toit au-dessus du vide) ;
## (b) le bord d'une falaise devant soi (ou de côté) : 12 m de vide à moins de 8 m.
func launch_check(feet: Vector3, face: Vector3) -> Array:
	var g: Array = ground_below(feet + Vector3.DOWN * 0.35)
	if feet.y - float(g[0]) >= LAUNCH_H:
		return [true, face, "vide", 0.0]
	var space := get_world_3d().direct_space_state
	var dirs: Array = [face]
	for k in range(1, 8):
		dirs.append(face.rotated(Vector3.UP, float((k + 1) / 2) * 0.45 * (1.0 if k % 2 == 1 else -1.0)))
	for d in dirs:
		var dd: Vector3 = d
		for dist in [2.0, 3.5, 5.0, 6.5, 8.0]:
			var q: Vector3 = feet + dd * dist
			var g2: Array = ground_below(Vector3(q.x, feet.y + 0.5, q.z))
			if feet.y - float(g2[0]) >= LAUNCH_H:
				# rien entre nous et le vide (un mur, un arbre) ?
				var hit: Dictionary = space.intersect_ray(PhysicsRayQueryParameters3D.create(feet + Vector3.UP * 1.6, q + Vector3.UP * 1.6, 1, _excludes()))
				if hit.is_empty():
					return [true, dd, "falaise", float(dist)]
				break
			if float(g2[0]) > feet.y + 1.5:
				break
	return [false, face, "", 0.0]


## La touche N (croix haute maintenue, X maintenu en VR).
func call_vehicle() -> void:
	if main == null or not bool(main.game_started):
		return
	if riding:
		return
	var p: Vector3 = _player_pos()
	var why: String = _blocked_reason(p)
	if why != "":
		_say(why, 4.5)
		return
	if main.get("inventory_v28") != null and main.inventory_v28 != null and main.inventory_v28.opened:
		main.inventory_v28.close()
	var feet: Vector3 = _feet()
	var face: Vector3 = _facing()
	if lvl <= 2:
		var lc: Array = launch_check(feet, face)
		if bool(lc[0]):
			_deploy_glider(feet, lc[1], str(lc[2]), float(lc[3]))
			return
		if lvl == 1:
			_say("Trop bas pour t'envoler : l'Alouette ne décolle que d'un point haut. Il faut douze mètres de vide sous toi : le bord d'une falaise, une tour, l'aire d'envol de l'Atelier des Ailes… ou saute d'abord, et déploie-la en pleine chute !", 7.0)
			return
		# l'Alouette à hélice, sur le plat : on s'installe, il faut pédaler pour rouler
		var g: Array = ground_below(feet + Vector3.UP * 0.5)
		if str(g[1]) != "sol" or not _clear_spot(Vector3(feet.x, float(g[0]), feet.z), 2.6):
			_say("Pas assez de place pour déplier l'Alouette à hélice ici (il lui faut un terrain dégagé).", 4.5)
			return
		pos = Vector3(feet.x, float(g[0]), feet.z)
		yaw = atan2(-face.x, -face.z)
		speed = 0.0
		vspeed = 0.0
		state = "sol"
		_show(true)
		_begin_ride()
		main.sfx("helice_pedale", pos + Vector3.UP, -6.0)
		_say("Tu déplies l'Alouette à hélice et tu t'installes. %s pour pédaler : elle roule, prend de la vitesse… et décolle !" % ("Stick gauche vers l'avant" if bool(main.xr_active) else "Espace"), 6.0)
		return
	# l'Albatros, le Glisseur : ils viennent se poser près de toi
	if state == "pose" and rig.visible and pos.distance_to(p) < 30.0:
		_say("%s t'attend déjà, juste là. E pour monter à bord." % vehicle_name().capitalize() if not bool(main.xr_active) else "%s t'attend déjà, juste là. Gâchette pour monter à bord." % vehicle_name().capitalize(), 3.5)
		return
	var spot: Variant = _landing_spot(feet)
	if spot == null:
		_say("Pas assez de place ici pour que %s se pose. Va sur un terrain dégagé." % vehicle_name(), 4.5)
		return
	_arrive(spot as Vector3, feet)


## Une place dégagée autour du joueur.
func _landing_spot(feet: Vector3) -> Variant:
	var need: float = float(GROUND_R.get(lvl, 3.0))
	for ring in [need + 2.5, need + 5.0, need + 8.0]:
		for k in range(12):
			var a: float = TAU * k / 12.0 + 0.3
			var q: Vector3 = feet + Vector3(cos(a), 0, sin(a)) * float(ring)
			var g: Array = ground_below(Vector3(q.x, feet.y + 4.0, q.z))
			if str(g[1]) != "sol" or absf(float(g[0]) - feet.y) > 3.5:
				continue
			var at := Vector3(q.x, float(g[0]), q.z)
			if _clear_spot(at, need) and not _roofed(at):
				return at
	return null


func _clear_spot(at: Vector3, r: float) -> bool:
	var space := get_world_3d().direct_space_state
	_sphere.radius = r
	var prm := PhysicsShapeQueryParameters3D.new()
	prm.shape = _sphere
	prm.collision_mask = 1
	prm.exclude = _excludes()
	for h in ([1.2 + r, 7.0] if lvl == 3 else [0.6 + r]):
		prm.transform = Transform3D(Basis(), at + Vector3.UP * float(h))
		if not space.intersect_shape(prm, 1).is_empty():
			return false
	# le sol à peu près plat
	for k in range(4):
		var a: float = TAU * k / 4.0
		var g: Array = ground_below(at + Vector3(cos(a), 0, sin(a)) * minf(r, 2.5) + Vector3.UP * 2.0)
		if absf(float(g[0]) - at.y) > 1.2:
			return false
	return true


func _arrive(to: Vector3, feet: Vector3) -> void:
	var from_dir := Vector3(to.x - feet.x, 0, to.z - feet.z)
	from_dir = from_dir.normalized() if from_dir.length() > 0.1 else Vector3.FORWARD
	from_dir = from_dir.rotated(Vector3.UP, randf_range(-0.6, 0.6))
	var far: float = 140.0 if lvl == 3 else 220.0
	var start: Vector3 = to + from_dir * far + Vector3.UP * (60.0 if lvl == 3 else 110.0)
	var ctrl: Vector3 = to + from_dir * far * 0.25 + Vector3.UP * 18.0
	_path = [start, ctrl, to]
	_t = 0.0
	pos = start
	var tan: Vector3 = ctrl - start
	yaw = atan2(-tan.x, -tan.z)
	state = "arrive"
	_show(true)
	if lvl == 3:
		_say("Tu agites ton mouchoir rouge vers le ciel… Un ronronnement d'hélices répond, très loin. L'Albatros arrive !", 4.5)
	else:
		_say("Tu effleures ta Clé d'étoile… Une lueur file à travers le ciel : le Glisseur stellaire arrive !", 4.5)
		main.sfx("soucoupe_vol", to + from_dir * 40.0 + Vector3.UP * 20.0)


func _deploy_glider(feet: Vector3, dir: Vector3, how: String, edge: float = 0.0) -> void:
	yaw = atan2(-dir.x, -dir.z)
	pos = feet
	if how == "falaise":
		# l'élan : quelques pas jusqu'au bord, et le vide
		var r: Array = _sweep(feet + Vector3.UP * 0.4, dir * edge)
		pos = feet + Vector3.UP * 0.4 + (r[0] as Vector3)
	_air_t = 0.0
	speed = 7.5 if how == "falaise" else 9.0
	vspeed = 0.6 if how == "falaise" else -1.0
	_prone = 0.0 if how == "falaise" else 0.6
	state = "vol"
	_t = 0.0
	_show(true)
	_begin_ride()
	vols += 1
	main.sfx("deltaplane_vent", pos + Vector3.UP * 1.5)
	if how == "vide":
		_say("Clac-clac-FLOP ! L'Alouette se déplie au-dessus de toi en pleine chute… et la toile se gonfle. Tu planes !", 5.0)
	else:
		_say("Tu déplies l'Alouette, tu prends ton élan… trois pas… et le vide te porte. Tu planes !", 5.0)


# =================================================================== monter, descendre

func register_interactions(d: Node) -> void:
	if d == null:
		return
	var I: Array = d._interactions
	_mount_it = {"id": "aeronef_monter", "pos": Vector3.INF, "radius": 3.6, "text": "E : monter à bord", "vr": "Gâchette : monter à bord",
		"call": mount, "when": func(): return not riding and state == "pose" and lvl >= 3}
	I.append(_mount_it)


func mount() -> void:
	if riding or state != "pose" or lvl < 3:
		return
	var why: String = _blocked_reason(pos + Vector3.UP * 1.0)
	if why != "" and lvl > 0 and not why.begins_with("Pas sous un toit"):
		_say(why, 4.0)
		return
	state = "envol"
	_t = 0.0
	speed = 0.0
	vspeed = 0.0
	_begin_ride()
	vols += 1
	if lvl == 3:
		main.sfx("aeronef_moteur", pos + Vector3.UP * 1.5)
		_say("À bord de l'Albatros ! " + ("Stick gauche : virer, monter, descendre ; gâchette droite : plus vite, gauche : freiner ; A : se poser." if bool(main.xr_active) else "Z / S : plus vite / plus lent (S arrête), Q / D : virer, Espace : monter, Ctrl : descendre, E : se poser."), 8.0)
	else:
		main.sfx("soucoupe_vol", pos + Vector3.UP * 1.5)
		_say("Dans le Glisseur stellaire ! La coque vibre doucement, les feux s'allument un à un. " + ("Stick gauche : virer, monter, descendre ; gâchettes : vitesse ; A : se poser." if bool(main.xr_active) else "Z / S : vitesse (S : sur place), Q / D : virer, Espace / Ctrl : monter / descendre, E : se poser."), 8.0)


func _begin_ride() -> void:
	riding = true
	_cam_pos = Vector3.INF
	_cam_orbit = 0.0
	_vr_a = true
	_ensure_poses()
	var fi: Node = main.get("fishing_v32")
	if fi != null and fi.has_method("cancel"):
		fi.cancel("")
	if main.get("inventory_v28") != null and main.inventory_v28 != null and main.inventory_v28.opened:
		main.inventory_v28.close()
	var h: Node = main.get("hero_v28")
	if h != null and not bool(main.xr_active):
		h.state = "bateau"
	if bool(main.xr_active):
		main.xr_origin.rotation.y = yaw
	_place_rider(0.0)


## E (A en VR) en vol : se poser.
func request_landing() -> void:
	if not riding:
		return
	var g: Array = ground_below(pos + Vector3.UP * 0.5)
	var agl: float = pos.y - float(g[0])
	match state:
		"sol":
			_dismount_here()
		"vol":
			if lvl <= 2:
				if agl <= 4.0:
					_touchdown(str(g[1]) == "eau")
				else:
					_say("Une Alouette ne se pose pas d'un coup : descends en planant jusqu'au sol (%s). Elle se posera toute seule en douceur." % ("stick gauche vers l'arrière pour piquer" if bool(main.xr_active) else "Ctrl ou Z pour piquer"), 5.0)
				return
			if lvl == 3 and agl > 70.0:
				_say("Trop haut pour se poser : l'Albatros descend lentement. Descends d'abord un peu (%s)." % ("stick gauche vers l'arrière" if bool(main.xr_active) else "Ctrl"), 4.5)
				return
			_start_landing(Vector3(pos.x, float(g[0]), pos.z), str(g[1]) == "eau")


func _start_landing(to: Vector3, water: bool) -> void:
	_land_from = pos
	_land_to = to + (Vector3.UP * 1.6 if water else Vector3.ZERO)
	_land_water = water
	_t = 0.0
	state = "atterrit"
	if water:
		_say("Pas de terre ferme ici… %s descend au ras des vagues : tu sauteras dans l'eau." % vehicle_name().capitalize() if not _boat_near(to) else "Ta barque est juste là : %s descend tout près." % vehicle_name(), 4.0)


func _boat_near(p: Vector3) -> bool:
	var b: Node = main.get("boat_v29")
	if b == null or b.get("hull") == null or b.hull == null:
		return false
	var c: Vector3 = b.hull.global_position
	return Vector2(p.x - c.x, p.z - c.z).length() < 18.0


## L'Alouette touche terre (ou l'eau).
func _touchdown(water: bool) -> void:
	if water:
		_splash_down()
		return
	state = "atterrit"
	_t = 0.0
	_land_water = false
	if lvl == 2:
		main.sfx("atterrissage", pos)
	else:
		main.sfx("atterrissage", pos, -4.0)


func _splash_down() -> void:
	var at: Vector3 = pos
	_end_ride(false)
	var b: Node = main.get("boat_v29")
	if _boat_near(at) and main.has_method("_board_boat_v29"):
		main.place_player_v35(b.hull.global_position + Vector3.UP * 0.6, Vector3(-sin(yaw), 0, -cos(yaw)))
		main._board_boat_v29()
		_say("Tu lâches tout juste au-dessus de ta barque… et tu atterris dedans ! L'Alouette se replie dans ton sac.", 5.0)
	else:
		main.place_player_v35(Vector3(at.x, SEA_Y - 1.1, at.z), Vector3(-sin(yaw), 0, -cos(yaw)))
		var h: Node = main.get("hero_v28")
		if h != null and not bool(main.xr_active):
			h.state = "air"
			h.body.velocity = Vector3(0, -3.0, 0)
		main.sfx("plongeon", Vector3(at.x, SEA_Y, at.z))
		_say("Plouf ! Tu te poses dans l'eau. L'Alouette, trempée, se replie dans ton sac. À la nage !" if lvl <= 2 else "Tu sautes dans l'eau ! %s remonte dans le ciel : rappelle-le quand tu seras sur la terre ferme." % vehicle_name().capitalize(), 5.0)
	_fold_away()


func _dismount_here() -> void:
	var at: Vector3 = pos
	_end_ride(true)
	if lvl <= 2:
		_fold_away()
		_say("Tu replies l'Alouette dans ton sac. Clic, clac.", 3.0)


func _fold_away() -> void:
	if lvl >= 3 and state != "pose":
		# l'aéronef remonte et repart (on le rappellera)
		state = "depart"
		_t = 0.0
		return
	state = "replie"
	_t = 0.0


func _end_ride(place: bool) -> void:
	if not riding:
		return
	riding = false
	_set_hud("")
	var h: Node = main.get("hero_v28")
	var face := Vector3(-sin(yaw), 0, -cos(yaw))
	if place:
		var spot: Vector3 = pos
		var side := Vector3(cos(yaw), 0, -sin(yaw))
		var off: float = {1: 0.0, 2: 1.2, 3: 2.4, 4: 3.3}.get(lvl, 1.0)
		if off > 0.0:
			for s in [1.0, -1.0, 0.0]:
				var q: Vector3 = pos + side * off * float(s) + (face * 3.5 if s == 0.0 else Vector3.ZERO)
				var g: Array = ground_below(q + Vector3.UP * 3.0)
				if str(g[1]) == "sol" and absf(float(g[0]) - pos.y) < 2.0:
					spot = Vector3(q.x, float(g[0]) + 0.05, q.z)
					break
		main.place_player_v35(spot, face)
		main.sfx("atterrissage", spot, -6.0)
	if h != null and not bool(main.xr_active):
		h.leave_ride()
		h.cam_distance = 1.0
		if h.hero != null:
			h.hero.rotation = Vector3(0, h.hero.rotation.y, 0)
	_anim_now = ""


## Le joueur s'évanouit, se téléporte, charge une partie… : on descend sans histoire.
func force_end() -> void:
	if riding:
		_end_ride(false)
	if lvl <= 2:
		state = "range"
		_show(false)
	elif state != "pose":
		state = "range"
		_show(false)


func _show(on: bool) -> void:
	if rig != null:
		rig.visible = on
	if not on:
		_set_hud("")


# =================================================================== chaque image

func _physics_process(delta: float) -> void:
	if main == null or rig == null:
		return
	_clock += delta
	_warn_t = maxf(_warn_t - delta, 0.0)
	_bump_t = maxf(_bump_t - delta, 0.0)
	if not _mount_it.is_empty():
		_mount_it["pos"] = pos + Vector3.UP * (0.6 if lvl == 4 else 0.4)
		_mount_it["radius"] = 3.4 if lvl == 4 else 3.0
	if riding:
		return                          # main appelle ride_tick
	match state:
		"arrive":
			_tick_arrive(delta)
		"depart":
			_t += delta
			pos += Vector3(-sin(yaw), 0.35, -cos(yaw)).normalized() * (14.0 if lvl == 3 else 40.0) * delta
			if _t > 6.0:
				state = "range"
				_show(false)
		"replie":
			_t += delta
			rig.scale = Vector3.ONE * maxf(1.0 - _t * 2.2, 0.02)
			if _t > 0.45:
				state = "range"
				rig.scale = Vector3.ONE
				_show(false)
		"pose":
			_idle_anim(delta)
	_apply_xform(delta)
	_tick_sound(delta)


func _idle_anim(delta: float) -> void:
	match lvl:
		3:
			speed = 0.0
			bank = lerpf(bank, sin(_clock * 0.6) * 0.015, delta)
		4:
			_tick_lights(delta, 0.4)
			for leg in parts.get("pieds", []):
				(leg as Node3D).scale = (leg as Node3D).scale.move_toward(Vector3.ONE, delta * 2.0)


func _tick_arrive(delta: float) -> void:
	var dur: float = 9.0 if lvl == 3 else 3.6
	_t = minf(_t + delta / dur, 1.0)
	var t: float = smoothstep(0.0, 1.0, _t)
	var a: Vector3 = _path[0]
	var b: Vector3 = _path[1]
	var c: Vector3 = _path[2]
	pos = a.lerp(b, t).lerp(b.lerp(c, t), t)
	var tan: Vector3 = (b - a).lerp(c - b, t)
	tan.y = 0.0
	if tan.length() > 0.01 and _t < 0.9:
		var want: float = atan2(-tan.x, -tan.z)
		bank = lerpf(bank, clampf(angle_difference(yaw, want) * -4.0, -0.4, 0.4), delta * 2.0)
		yaw = want
	speed = 20.0 * (1.0 - _t)
	bank = lerpf(bank, 0.0, delta * (2.0 if _t > 0.8 else 0.2))
	pitch = lerpf(pitch, 0.0, delta * 2.0)
	if lvl == 4:
		_tick_lights(delta, 1.0)
		for leg in parts.get("pieds", []):
			(leg as Node3D).scale = Vector3.ONE * maxf(smoothstep(0.75, 1.0, _t), 0.05)
	if _t >= 1.0:
		state = "pose"
		speed = 0.0
		bank = 0.0
		pitch = 0.0
		if lvl == 4:
			main.sfx("soucoupe_pose", pos + Vector3.UP)
		else:
			main.sfx("atterrissage", pos)
		_say("%s s'est posé près de toi. %s pour monter à bord." % [vehicle_name().capitalize(), "Gâchette" if bool(main.xr_active) else "E"], 4.0)


func _apply_xform(delta: float) -> void:
	if not rig.visible:
		return
	var wob := Vector3.ZERO
	if lvl == 3 and state in ["vol", "pose", "arrive", "envol"]:
		wob.y = sin(_clock * 0.9) * 0.08
	if lvl == 4 and state in ["vol", "arrive", "envol", "atterrit"]:
		wob.y = sin(_clock * 1.7) * 0.06
	rig.global_transform = Transform3D(Basis.from_euler(Vector3(pitch, yaw, bank)), pos + wob)
	# les hélices
	var spin: float = 0.0
	match lvl:
		2:
			spin = _pedal * 32.0 + (speed * 0.4 if state == "vol" else 0.0)
		3:
			spin = 0.0 if state in ["pose", "range"] else 24.0 + speed * 2.0
	_prop_a += spin * delta
	for hub in parts.get("props", []):
		var r: Node3D = (hub as Node3D).get_node("Rotor")
		r.rotation.z = _prop_a
		var flou: MeshInstance3D = (hub as Node3D).get_node("Flou")
		(flou.material_override as StandardMaterial3D).albedo_color.a = clampf((spin - 12.0) / 30.0, 0.0, 0.16)
		r.visible = spin < 30.0 or fmod(_clock * 60.0, 2.0) < 1.0
	if parts.has("manivelles"):
		(parts["manivelles"] as Node3D).rotation.x = _prop_a / 3.2
	if parts.has("cocon"):
		(parts["cocon"] as Node3D).visible = _prone > 0.85 and state in ["vol", "atterrit"]
	if parts.has("fanion"):
		(parts["fanion"] as Node3D).rotation.y = PI * 0.5 + sin(_clock * 9.0) * 0.25 * clampf(speed / 9.0, 0.2, 1.0)


func _tick_lights(delta: float, power: float) -> void:
	var lights: Array = parts.get("feux", [])
	for k in range(lights.size()):
		var m: StandardMaterial3D = lights[k]
		var ph: float = fmod(_clock * 3.0 - float(k) / lights.size() * 2.0, 2.0)
		m.emission_energy_multiplier = lerpf(0.6, 4.0, maxf(0.0, 1.0 - absf(ph - 1.0) * 3.0)) * power + 0.4
	if parts.has("lumiere"):
		var night: bool = false
		var tv: Node = main.get("temps_v56")
		if tv != null and tv.has_method("is_night"):
			night = bool(tv.is_night())
		(parts["lumiere"] as OmniLight3D).light_energy = (1.6 if night else 0.7) * power
	if parts.has("halo"):
		(parts["halo"] as Node3D).scale = Vector3.ONE * (0.9 + 0.1 * sin(_clock * 4.0)) * (0.4 + 0.6 * power)


# =================================================================== en vol (appelé par main.gd)

func ride_tick(delta: float) -> void:
	if not riding:
		return
	var turn: float = 0.0
	var lift: float = 0.0
	var thr: float = 0.0
	if bool(main.xr_active):
		var stv: Vector2 = main.left_hand.get_vector2("primary")
		if stv.length() > 0.2:
			turn = stv.x
			lift = stv.y
		thr = main.right_hand.get_float("trigger") - main.left_hand.get_float("trigger")
		var a_now: bool = main.right_hand.is_button_pressed("ax_button")
		if a_now and not _vr_a:
			request_landing()
		_vr_a = a_now
	else:
		var free: bool = main.get("inventory_v28") == null or main.inventory_v28 == null or not main.inventory_v28.opened
		if free:
			if Input.is_key_pressed(KEY_Z) or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
				thr += 1.0
			if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
				thr -= 1.0
			if Input.is_key_pressed(KEY_Q) or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
				turn -= 1.0
			if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
				turn += 1.0
			if main.has_method("pad_move_v74"):
				var pad: Vector2 = main.pad_move_v74()
				thr = clampf(thr - pad.y, -1.0, 1.0)
				turn = clampf(turn + pad.x, -1.0, 1.0)
			if Input.is_key_pressed(KEY_SPACE):
				lift += 1.0
			if Input.is_key_pressed(KEY_CTRL) or Input.is_key_pressed(KEY_SHIFT):
				lift -= 1.0
	steer(turn, lift, thr)
	tick(delta)
	if riding:
		_place_rider(delta)
		_hud_tick()


## Les commandes (-1..1), puis un pas de vol (les essais s'en servent directement).
func steer(turn: float, lift: float, thr: float) -> void:
	_turn_in = clampf(turn, -1.0, 1.0)
	_lift_in = clampf(lift, -1.0, 1.0)
	_thr_in = clampf(thr, -1.0, 1.0)


func tick(delta: float) -> void:
	match state:
		"vol":
			_tick_flight(delta)
		"sol":
			_tick_ground(delta)
		"envol":
			_tick_takeoff(delta)
		"atterrit":
			_tick_landing(delta)
	if pos.y > alt_max and state == "vol":
		alt_max = pos.y
	_apply_xform(delta)
	_tick_sound(delta)
	if lvl == 4:
		_tick_lights(delta, 1.0)
		for leg in parts.get("pieds", []):
			(leg as Node3D).scale = (leg as Node3D).scale.move_toward(Vector3.ONE * (0.05 if state == "vol" else 1.0), delta * 1.5)


func _hero() -> Node:
	return main.get("hero_v28")


func _tick_flight(delta: float) -> void:
	var T: Dictionary = TUNE[lvl]
	var turn: float = _turn_in
	var p: Vector3 = pos
	# rester dans le monde
	if not WORLD.has_point(Vector2(p.x, p.z)):
		var home: float = atan2(-(WORLD.get_center().x - p.x), -(WORLD.get_center().y - p.z))
		turn = clampf(-angle_difference(yaw, home) * 2.0, -1.0, 1.0)
		_warn("bord", "Au-delà, il n'y a plus que la mer et les nuages : demi-tour !")
	# la Citadelle des Nuées : le vent y est furieux
	var c: Node = main.get("ciel_v54")
	if c != null and c.get("chateau") != null and c.chateau != null and bool(c._in_castle_zone(p)):
		var cc: Vector3 = c.chateau.global_position
		var out := Vector3(p.x - cc.x, 0, p.z - cc.z)
		out = out.normalized() if out.length() > 0.1 else Vector3.BACK
		pos += out * 14.0 * delta
		turn = clampf(-angle_difference(yaw, atan2(-out.x, -out.z)) * 2.0, -1.0, 1.0)
		_warn("citadelle", "Un vent furieux tourbillonne autour de la Citadelle : impossible d'en approcher. Pose-toi sur l'Aire des Vents, au sud de l'île.")
	var g: Array = ground_below(p + Vector3.UP * 0.4)
	var agl: float = p.y - float(g[0])
	var fwd := Vector3(-sin(yaw), 0, -cos(yaw))
	_air_t += delta
	match lvl:
		1, 2:
			var target: float = float(T["cruise"])
			if _thr_in > 0.05:
				target = lerpf(float(T["cruise"]), float(T["max"]), _thr_in)
			elif _thr_in < -0.05:
				target = lerpf(float(T["cruise"]), float(T["min"]), -_thr_in)
			if _lift_in < -0.1:
				target = maxf(target, lerpf(float(T["cruise"]), float(T["max"]), -_lift_in))
			speed = move_toward(speed, target, delta * 2.2)
			var sink: float = speed / _ratio(speed) * (1.0 + 0.45 * absf(turn))
			var vs: float = -sink
			if _lift_in < -0.1:
				vs -= 1.8 * -_lift_in
			_pedal = move_toward(_pedal, 0.0, delta * 2.0)
			if lvl == 2:
				vs += _pedal_lift(delta, agl)
			else:
				_regen(delta, 0.35)
			vspeed = move_toward(vspeed, vs, delta * 2.5)
			_prone = move_toward(_prone, 1.0, delta * 1.4)
		3, 4:
			var target2: float = float(T["cruise"])
			if _thr_in > 0.05:
				target2 = lerpf(float(T["cruise"]), float(T["max"]), _thr_in)
			elif _thr_in < -0.05:
				target2 = lerpf(float(T["cruise"]), 0.0, -_thr_in)
			speed = move_toward(speed, target2, delta * (2.0 if lvl == 3 else 9.0))
			var want_v: float = _lift_in * float(T["climb"])
			# on ralentit la montée à l'approche du plafond (pas de dépassement)
			want_v = minf(want_v, maxf((float(T["ceil"]) - p.y) * 1.2, 0.0))
			if p.y >= float(T["ceil"]) - 0.5 and _lift_in > 0.1:
				want_v = 0.0
				_warn("plafond", "%s ne peut pas monter plus haut (%d m) : l'air est trop léger." % [vehicle_name().capitalize(), int(T["ceil"])] if lvl == 3 else "Six cents mètres : le Glisseur plafonne. Au-dessus, c'est le domaine des étoiles.")
			if p.y > float(T["ceil"]) + 1.0:
				want_v = -2.0
			vspeed = move_toward(vspeed, want_v, delta * (3.0 if lvl == 3 else 14.0))
	var turn_rate: float = float(T["turn"])
	if lvl == 4:
		turn_rate *= lerpf(1.2, 0.8, clampf(speed / 42.0, 0.0, 1.0))
	yaw -= turn * turn_rate * delta
	var step: Vector3 = fwd * speed * delta + Vector3.UP * vspeed * delta
	var n: Vector3 = _move(step)
	if n != Vector3.ZERO:
		_on_bump(n, fwd)
		if not riding or state != "vol":
			return
	# le plafond (toits, dessous des îles flottantes)
	var top: float = float(TOP[lvl])
	var ceil_y: float = ceiling_above(pos + Vector3.UP * (top - 0.4), 4.0)
	if pos.y + top > ceil_y - 0.2:
		pos.y = ceil_y - 0.2 - top
		vspeed = minf(vspeed, 0.0)
	# le sol, la mer
	g = ground_below(pos + Vector3.UP * 0.4)
	var floor_y: float = float(g[0])
	if lvl <= 2:
		if pos.y - floor_y < 0.25 and (_air_t > 0.8 or vspeed < -0.5):
			pos.y = floor_y
			_touchdown(str(g[1]) == "eau")
			return
		if pos.y < floor_y:
			pos.y = floor_y
	else:
		var clear: float = 0.5 if str(g[1]) == "sol" else 1.6
		floor_y = maxf(floor_y, _footprint_floor(pos))
		if pos.y < floor_y + clear:
			pos.y = maxf(move_toward(pos.y, floor_y + clear, delta * 10.0), floor_y + clear - 0.25)
			vspeed = maxf(vspeed, 0.0)
	# sous terre : on n'y vole pas
	var d: Node = main.get("donjon_v35")
	if d != null and d.has_method("is_inside") and bool(d.is_inside(pos + Vector3.UP)):
		_say("Ici, sous terre, impossible de voler : tu te poses.", 3.5)
		_end_ride(true)
		_fold_away()
		return
	# l'allure
	var want_bank: float = -turn * float(T["bank"])
	bank = lerpf(bank, want_bank, clampf(delta * 2.2, 0.0, 1.0))
	var want_pitch: float = 0.0
	match lvl:
		1, 2:
			want_pitch = clampf(-(speed - float(T["cruise"])) * 0.035, -0.18, 0.12) + clampf(vspeed * 0.04, -0.1, 0.12)
		3:
			want_pitch = clampf(vspeed * 0.02, -0.06, 0.06) - clampf(speed / 13.0, 0.0, 1.0) * 0.02
		4:
			want_pitch = -clampf(speed / 42.0, 0.0, 1.0) * 0.12 + clampf(vspeed * 0.01, -0.08, 0.08)
	pitch = lerpf(pitch, want_pitch, clampf(delta * 2.0, 0.0, 1.0))


## Finesse de l'aile selon la vitesse (8 à la vitesse de croisière).
func _ratio(v: float) -> float:
	var T: Dictionary = TUNE[maxi(lvl, 1) if lvl <= 2 else 1]
	var cr: float = float(T["cruise"])
	if v >= cr:
		return GLIDE - 2.2 * pow((v - cr) / (float(T["max"]) - cr), 2.0)
	return GLIDE - 1.2 * (cr - v) / (cr - float(T["min"]))


## Le pédalier : de la portance tant qu'il reste de l'endurance (de moins en moins en altitude).
func _pedal_lift(delta: float, agl: float) -> float:
	var h: Node = _hero()
	var can: bool = true
	if h != null:
		can = float(h.stamina) > 0.05 and not bool(h.stamina_lock)
	if _lift_in > 0.2 and can:
		_pedal = move_toward(_pedal, 1.0, delta * 4.0)
		if h != null:
			h._spend(PEDAL_COST * delta)
			if bool(h.stamina_lock):
				_warn("souffle", "Ouf… plus de souffle ! Plane un peu pour récupérer, puis repédale.")
	else:
		_regen(delta, 0.6)
		if _lift_in > 0.2 and not can:
			_warn("souffle", "Ouf… plus de souffle ! Plane un peu pour récupérer, puis repédale.")
	var eff: float = clampf(1.0 - agl / PEDAL_AGL, 0.12, 1.0)
	return _pedal * 3.6 * eff


func _regen(delta: float, rate: float) -> void:
	var h: Node = _hero()
	if h == null:
		return
	h.stamina = minf(float(h.stamina) + rate * delta, float(h.STAMINA_MAX))
	if bool(h.stamina_lock) and float(h.stamina) >= float(h.STAMINA_MAX) * 0.35:
		h.stamina_lock = false


## Un choc (falaise, mur, arbre) : on rebondit et on s'écarte ; trop fort, une Alouette se
## pose en catastrophe (sans mal : le harnais a un ressort de Cliquetis).
func _on_bump(n: Vector3, fwd: Vector3) -> void:
	var head_on: float = -n.dot(fwd)
	if n.y > 0.65:
		return                                  # on frôle le sol : c'est le sol qui commande
	if lvl <= 2 and head_on > 0.55 and speed > 6.0:
		main.sfx("touche_bois", pos + Vector3.UP * 2.0)
		_say("BONK ! L'Alouette heurte l'obstacle et se replie d'un coup… Le ressort du harnais t'a déposé en douceur. Rien de cassé !", 5.0)
		var g: Array = ground_below(pos + Vector3.UP * 0.5)
		if str(g[1]) == "eau":
			_splash_down()
			return
		pos.y = float(g[0])
		_end_ride(true)
		_fold_away()
		return
	speed = maxf(speed * (1.0 - 0.6 * maxf(head_on, 0.0)), float(TUNE[lvl]["min"]))
	var side: float = signf(fwd.cross(n).y + 0.001)
	yaw -= side * 1.2 * get_physics_process_delta_time()
	if _bump_t <= 0.0:
		_bump_t = 1.2
		_warn("obstacle", "Attention, un obstacle !")


func _tick_ground(delta: float) -> void:
	# l'Alouette à hélice qui roule (pédaler pour prendre de la vitesse)
	var h: Node = _hero()
	var can: bool = h == null or (float(h.stamina) > 0.05 and not bool(h.stamina_lock))
	if _lift_in > 0.2 and can:
		_pedal = move_toward(_pedal, 1.0, delta * 4.0)
		if h != null:
			h._spend(PEDAL_COST * 0.6 * delta)
		speed = move_toward(speed, 9.0, delta * 2.4)
	else:
		_pedal = move_toward(_pedal, 0.0, delta * 3.0)
		speed = move_toward(speed, 0.0, delta * (4.0 if _thr_in < -0.1 else 1.2))
		_regen(delta, 1.5)
	yaw -= _turn_in * 0.9 * delta * clampf(speed / 3.0, 0.3, 1.0)
	var fwd := Vector3(-sin(yaw), 0, -cos(yaw))
	var n: Vector3 = _move(fwd * speed * delta + Vector3.UP * 0.3 * delta)
	if n != Vector3.ZERO and -n.dot(fwd) > 0.5:
		speed = 0.0
	var g: Array = ground_below(pos + Vector3.UP * 0.6)
	if str(g[1]) == "eau":
		_splash_down()
		return
	if pos.y - float(g[0]) > 0.6 and speed > 5.5:
		# le sol se dérobe (bord d'une falaise) : on vole !
		state = "vol"
		vspeed = 0.0
		_air_t = 0.0
		return
	pos.y = float(g[0])
	pitch = lerpf(pitch, 0.0, delta * 3.0)
	bank = lerpf(bank, 0.0, delta * 3.0)
	_prone = 0.0
	if speed >= 7.0 and _lift_in > 0.2:
		state = "vol"
		vspeed = 1.5
		_air_t = 0.0
		pos.y += 0.15
		main.sfx("helice_pedale", pos + Vector3.UP, -4.0)


func _tick_takeoff(delta: float) -> void:
	_t += delta
	var dur: float = 2.0 if lvl == 3 else 1.0
	vspeed = 2.2 if lvl == 3 else 4.0
	var n: Vector3 = _move(Vector3.UP * vspeed * delta)
	if n != Vector3.ZERO:
		_t = dur
	if _t >= dur:
		state = "vol"
		speed = 0.0


func _tick_landing(delta: float) -> void:
	_t += delta
	if lvl <= 2:
		# la course à l'atterrissage : on se redresse, on court, on s'arrête
		_prone = move_toward(_prone, 0.0, delta * 3.0)
		speed = move_toward(speed, 0.0, delta * 9.0)
		var fwd := Vector3(-sin(yaw), 0, -cos(yaw))
		_move(fwd * speed * delta)
		var g: Array = ground_below(pos + Vector3.UP * 0.6)
		pos.y = float(g[0])
		pitch = lerpf(pitch, 0.25, delta * 4.0)
		bank = lerpf(bank, 0.0, delta * 4.0)
		if speed <= 0.05 and _t > 0.6:
			if lvl == 2:
				state = "sol"
				speed = 0.0
				pitch = 0.0
				_say("Posé ! E pour replier l'Alouette, Espace pour repartir en pédalant.", 3.5)
			else:
				_end_ride(true)
				_fold_away()
				_say("Posé en douceur ! L'Alouette se replie dans ton sac.", 3.0)
		return
	# l'Albatros, le Glisseur : descente verticale jusqu'au sol
	var rate: float = 4.0 if lvl == 3 else 14.0
	var dist: float = _land_from.y - _land_to.y
	var dur: float = maxf(dist / rate, 1.2)
	var t: float = smoothstep(0.0, 1.0, minf(_t / dur, 1.0))
	speed = move_toward(speed, 0.0, delta * 6.0)
	pos.y = lerpf(_land_from.y, _land_to.y, t)
	pos.x = lerpf(pos.x, _land_to.x, clampf(delta * 2.0, 0.0, 1.0))
	pos.z = lerpf(pos.z, _land_to.z, clampf(delta * 2.0, 0.0, 1.0))
	bank = lerpf(bank, 0.0, delta * 3.0)
	pitch = lerpf(pitch, 0.0, delta * 3.0)
	if _t >= dur:
		if _land_water:
			_splash_down()
			return
		pos = _land_to
		state = "pose"
		if lvl == 4:
			main.sfx("soucoupe_pose", pos + Vector3.UP)
		_end_ride(true)


# =================================================================== le pilote

## Les poses du pilote (ajoutées au lecteur d'animations du héros, bibliothèque « v76 »).
func _ensure_poses() -> void:
	if _poses_done:
		return
	var h: Node = _hero()
	if h == null or h.anim == null or h.skel == null:
		return
	var ap: AnimationPlayer = h.anim
	if ap.has_animation_library("v76"):
		_poses_done = true
		return
	var lib := AnimationLibrary.new()
	# couché sous l'aile, les mains sur la barre, le regard devant
	var hang := {"LeftArm": Vector3(-150, 0, 24), "RightArm": Vector3(-150, 0, -24), "LeftForeArm": Vector3(-14, 0, 0), "RightForeArm": Vector3(-14, 0, 0),
		"LeftHand": Vector3(-25, 0, 0), "RightHand": Vector3(-25, 0, 0),
		"Spine02": Vector3(-14, 0, 0), "Head": Vector3(-52, 0, 0), "LeftUpLeg": Vector3(4, 0, 3), "RightUpLeg": Vector3(4, 0, -3),
		"LeftLeg": Vector3(8, 0, 0), "RightLeg": Vector3(12, 0, 0), "LeftFoot": Vector3(38, 0, 0), "RightFoot": Vector3(38, 0, 0)}
	var hang_b: Dictionary = hang.duplicate()
	hang_b["Head"] = Vector3(-48, 6, 0)
	hang_b["RightLeg"] = Vector3(18, 0, 0)
	hang_b["LeftLeg"] = Vector3(5, 0, 0)
	lib.add_animation("suspendu", h._clip(3.0, true, [[0.0, hang, Vector3.ZERO], [1.5, hang_b, Vector3.ZERO], [3.0, hang, Vector3.ZERO]]))
	# debout, les mains sur les montants du trapèze (décollage, atterrissage)
	var stand := {"LeftArm": Vector3(-78, 0, 26), "RightArm": Vector3(-78, 0, -26), "LeftForeArm": Vector3(-62, 0, 0), "RightForeArm": Vector3(-62, 0, 0),
		"Spine02": Vector3(6, 0, 0), "LeftUpLeg": Vector3(-12, 0, 0), "LeftLeg": Vector3(14, 0, 0), "RightUpLeg": Vector3(4, 0, 0)}
	lib.add_animation("trapeze", h._clip(1.0, true, [[0.0, stand, Vector3(0, -2, 0)], [1.0, stand, Vector3(0, -2, 0)]]))
	# allongé sur le siège, les pieds aux pédales (quatre temps)
	var arms := {"LeftArm": Vector3(-62, 0, 14), "RightArm": Vector3(-62, 0, -14), "LeftForeArm": Vector3(-38, 0, 0), "RightForeArm": Vector3(-38, 0, 0), "Spine02": Vector3(10, 0, 0), "Head": Vector3(-18, 0, 0)}
	var pk: Array = []
	for i in range(5):
		var ph: float = TAU * float(i) / 4.0
		var d: Dictionary = arms.duplicate()
		var l: float = sin(ph)
		var r: float = sin(ph + PI)
		d["LeftUpLeg"] = Vector3(-82 - 22 * l, 0, 5)
		d["LeftLeg"] = Vector3(62 + 40 * l, 0, 0)
		d["LeftFoot"] = Vector3(-10 + 10 * cos(ph), 0, 0)
		d["RightUpLeg"] = Vector3(-82 - 22 * r, 0, -5)
		d["RightLeg"] = Vector3(62 + 40 * r, 0, 0)
		d["RightFoot"] = Vector3(-10 + 10 * cos(ph + PI), 0, 0)
		pk.append([0.25 * i, d, Vector3(0, -38, 0)])
	lib.add_animation("pedaler", h._clip(1.0, true, pk))
	# debout à la barre de l'Albatros
	var helm := {"LeftArm": Vector3(-48, 0, 12), "RightArm": Vector3(-48, 0, -12), "LeftForeArm": Vector3(-58, 0, 0), "RightForeArm": Vector3(-58, 0, 0),
		"LeftHand": Vector3(0, 0, -20), "RightHand": Vector3(0, 0, 20), "Spine02": Vector3(4, 0, 0), "LeftUpLeg": Vector3(-4, 0, 4), "RightUpLeg": Vector3(2, 0, -4)}
	var helm_b: Dictionary = helm.duplicate()
	helm_b["Head"] = Vector3(-4, 12, 0)
	helm_b["Spine02"] = Vector3(3, 4, 0)
	lib.add_animation("barre", h._clip(5.0, true, [[0.0, helm, Vector3.ZERO], [2.5, helm_b, Vector3(0, -0.6, 0)], [5.0, helm, Vector3.ZERO]]))
	# assis aux commandes du Glisseur
	var seat := {"LeftUpLeg": Vector3(-80, 0, 6), "RightUpLeg": Vector3(-80, 0, -6), "LeftLeg": Vector3(70, 0, 0), "RightLeg": Vector3(70, 0, 0),
		"Spine02": Vector3(2, 0, 0), "LeftArm": Vector3(-48, 0, 16), "RightArm": Vector3(-48, 0, -16), "LeftForeArm": Vector3(-42, 0, 0), "RightForeArm": Vector3(-42, 0, 0)}
	var seat_b: Dictionary = seat.duplicate()
	seat_b["Head"] = Vector3(-6, -10, 0)
	lib.add_animation("pilote", h._clip(4.0, true, [[0.0, seat, Vector3(0, -38, 0)], [2.0, seat_b, Vector3(0, -38, 0)], [4.0, seat, Vector3(0, -38, 0)]]))
	ap.add_animation_library("v76", lib)
	_poses_done = true


var _anim_spd: float = 1.0

func _play_pose(name: String, blend: float = 0.3, spd: float = 1.0) -> void:
	var h: Node = _hero()
	if h == null or h.anim == null:
		return
	if _anim_now != name or str(h.current_anim) != "v76/" + name:
		h._play("v76/" + name, blend, spd)
		_anim_now = name
		_anim_spd = spd
	elif absf(_anim_spd - spd) > 0.05:
		(h.anim as AnimationPlayer).play("v76/" + name, blend, spd)
		_anim_spd = spd


## Le transform du héros (pieds) et la tête du pilote, selon le niveau.
func rider_transform() -> Transform3D:
	var vb := Basis.from_euler(Vector3(pitch, yaw, bank))
	var x := Transform3D(vb, pos)
	match lvl:
		1, 2:
			if lvl == 2 and state in ["sol", "vol", "atterrit"]:
				var seat: Vector3 = parts.get("siege", Vector3(0, 0.62, 0.12))
				var b2: Basis = vb * Basis(Vector3.UP, PI) * Basis(Vector3.RIGHT, -0.42)
				return Transform3D(b2, x * (seat + Vector3(0, -0.3, 0.12)))
			# du debout (0) au couché sous l'aile (1)
			var k: float = smoothstep(0.0, 1.0, _prone)
			var prone := Basis(Vector3(-1, 0, 0), Vector3(0, 0, -1), Vector3(0, -1, 0))
			var stand := Basis(Vector3.UP, PI)
			var bb: Basis = stand.slerp(prone, k)
			var feet_stand := Vector3(0, 0.0, 0.05)
			var feet_prone := Vector3(0, 0.8, 1.08)
			return Transform3D(vb * bb, x * feet_stand.lerp(feet_prone, k))
		3:
			return Transform3D(vb * Basis(Vector3.UP, PI), x * Vector3(0, 0.36, -0.55))
		4:
			var sp: Vector3 = parts.get("siege", Vector3(0, 1.8, 0.28))
			return Transform3D(vb * Basis(Vector3.UP, PI), x * (sp + Vector3(0, -0.37, 0)))
	return x


func eye_point() -> Vector3:
	var vb := Basis.from_euler(Vector3(pitch, yaw, bank))
	match lvl:
		1:
			return pos + vb * Vector3(0, 0.9 + 0.75 * (1.0 - _prone), -0.6 * _prone)
		2:
			return pos + vb * Vector3(0, 1.45, -0.05)
		3:
			return pos + vb * Vector3(0, 2.0, -0.6)
		4:
			return pos + vb * Vector3(0, 2.45, 0.2)
	return pos + Vector3.UP * 1.6


func _place_rider(delta: float) -> void:
	var rt: Transform3D = rider_transform()
	if bool(main.xr_active):
		main.xr_origin.rotation.y = yaw
		var eye: Vector3 = eye_point()
		var cam_local: Vector3 = main.xr_camera.position
		var offset: Vector3 = Basis(Vector3.UP, main.xr_origin.rotation.y) * Vector3(cam_local.x, 0.0, cam_local.z)
		main.xr_origin.position = Vector3(eye.x - offset.x, eye.y - cam_local.y, eye.z - offset.z)
		main.vr_body.global_position = pos + Vector3.UP * 0.5
		main.vr_body.velocity = Vector3.ZERO
		return
	main.pc_root.rotation.y = yaw
	main.pc_root.position = pos
	main.pc_body.global_position = pos + Vector3.UP * 0.5
	main.pc_body.velocity = Vector3.ZERO
	var h: Node = _hero()
	if h == null:
		return
	h.state = "bateau"
	h.facing = Vector3(-sin(yaw), 0, -cos(yaw))
	h.fall_top = pos.y
	if h.hero != null:
		h.hero.global_transform = rt
	# la pose
	match lvl:
		1:
			_play_pose("suspendu" if _prone > 0.5 else "trapeze", 0.4)
		2:
			_play_pose("pedaler", 0.3, lerpf(0.15, 1.6, _pedal) if (_pedal > 0.02 or state == "sol") else 0.0)
		3:
			_play_pose("barre", 0.4)
		4:
			_play_pose("pilote", 0.4)
	# la sangle du harnais suit le dos du pilote
	if parts.has("sangle") and h.skel != null and lvl == 1:
		var sk: Skeleton3D = h.skel
		var bi: int = sk.find_bone("Spine02")
		if bi >= 0:
			var back: Vector3 = (sk.global_transform * sk.get_bone_global_pose(bi)).origin
			var wing: Node3D = parts["aile"]
			var a: Vector3 = parts["accroche"]
			var b: Vector3 = wing.to_local(back)
			var strap: MeshInstance3D = parts["sangle"]
			var L: float = maxf(a.distance_to(b), 0.05)
			(strap.mesh as CylinderMesh).height = L
			var up: Vector3 = (b - a) / L
			var side: Vector3 = up.cross(Vector3.FORWARD if absf(up.z) < 0.9 else Vector3.RIGHT).normalized()
			strap.transform = Transform3D(Basis(side, up, side.cross(up)), (a + b) * 0.5)
	_camera(delta)


func _unhandled_input(event: InputEvent) -> void:
	if riding and event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		_cam_orbit = wrapf(_cam_orbit - (event as InputEventMouseMotion).relative.x * 0.005, -PI, PI)


## La caméra de poursuite (PC) : derrière et un peu au-dessus, selon le niveau.
func _camera(delta: float) -> void:
	var h: Node = _hero()
	if h == null or h.camera == null or not (h.camera as Camera3D).current:
		return
	var cam: Camera3D = h.camera
	var zoom: float = clampf(float(h.cam_distance), 0.6, 1.6)
	var off: Vector3
	var look_h: float
	match lvl:
		1, 2:
			off = Vector3(0, 1.2, 8.0)
			look_h = 1.4
		3:
			off = Vector3(0, 5.5, 19.0)
			look_h = 4.5
		_:
			off = Vector3(0, 3.0, 10.5)
			look_h = 1.4
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		_cam_orbit = lerpf(_cam_orbit, 0.0, clampf(delta * 0.8, 0.0, 1.0))
	var target: Vector3 = pos + Vector3.UP * look_h
	var wanted: Vector3 = target + Basis(Vector3.UP, yaw + _cam_orbit) * (off * zoom - Vector3(0, look_h * 0.0, 0))
	var space := get_world_3d().direct_space_state
	var hit: Dictionary = space.intersect_ray(PhysicsRayQueryParameters3D.create(target, wanted, 1 | 256, _excludes()))
	if not hit.is_empty():
		wanted = (hit.position as Vector3) + (target - (hit.position as Vector3)).normalized() * 0.4
	var g: Array = ground_below(wanted + Vector3.UP * 0.5)
	wanted.y = maxf(wanted.y, float(g[0]) + 0.8)
	if _cam_pos == Vector3.INF or delta <= 0.0:
		_cam_pos = wanted
	else:
		_cam_pos = _cam_pos.lerp(wanted, clampf(delta * 5.0, 0.0, 1.0))
	cam.global_position = _cam_pos
	if _cam_pos.distance_to(target) > 0.1:
		cam.look_at(target, Vector3.UP)


# =================================================================== l'affichage

func _make_hud() -> void:
	if _hud != null:
		return
	_hud = CanvasLayer.new()
	_hud.layer = 6
	add_child(_hud)
	_hud_label = Label.new()
	_hud_label.anchor_left = 0.5
	_hud_label.anchor_right = 0.5
	_hud_label.offset_left = -260
	_hud_label.offset_right = 260
	_hud_label.offset_top = 14
	_hud_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hud_label.add_theme_font_size_override("font_size", 18)
	_hud_label.add_theme_color_override("font_color", Color(1.0, 0.96, 0.86))
	_hud_label.add_theme_color_override("font_outline_color", Color(0.05, 0.08, 0.12))
	_hud_label.add_theme_constant_override("outline_size", 6)
	_hud.add_child(_hud_label)
	_hud.visible = false


func _set_hud(text: String) -> void:
	if _hud == null:
		return
	_hud.visible = text != "" and not bool(main.xr_active)
	_hud_label.text = text


func _hud_tick() -> void:
	if _hud == null or bool(main.xr_active):
		return
	var g: Array = ground_below(pos + Vector3.UP * 0.5)
	var txt: String = "%s  —  altitude %d m (sol à %d m)" % [vehicle_name().capitalize(), int(round(pos.y)), int(round(maxf(pos.y - float(g[0]), 0.0)))]
	if lvl >= 3:
		txt += "  ·  plafond %d m" % int(TUNE[lvl]["ceil"])
	var h: Node = _hero()
	if lvl == 2 and h != null:
		var n: int = int(round(float(h.stamina) / float(h.STAMINA_MAX) * 10.0))
		txt += "  ·  souffle " + "●".repeat(n) + "○".repeat(10 - n)
	_set_hud(txt)


func _say(text: String, seconds: float = 4.0) -> void:
	var d: Node = main.get("donjon_v35")
	if d != null and d.has_method("_say"):
		d._say(text, seconds)
	elif main.has_method("_show_message_v28"):
		main._show_message_v28(text)
	else:
		print("AERONEF: ", text)


func _warn(kind: String, text: String) -> void:
	if _warn_t > 0.0 and _warned == kind:
		return
	_warned = kind
	_warn_t = 6.0
	_say(text, 4.0)


# =================================================================== sauvegarde, trouvailles

func serialize() -> Dictionary:
	var d := {"niveau": lvl, "alt_max": snappedf(alt_max, 0.1), "vols": vols, "pose": [], "en_vol": []}
	if riding and state in ["vol", "envol", "atterrit"]:
		d["en_vol"] = [pos.x, pos.y, pos.z, yaw, speed]
	elif lvl >= 3 and state in ["pose", "arrive"]:
		var at: Vector3 = _path[2] if state == "arrive" else pos
		d["pose"] = [at.x, at.y, at.z, yaw]
	return d


func load_data(d: Dictionary) -> void:
	if riding:
		_end_ride(false)
	riding = false
	var n: int = clampi(int(d.get("niveau", 0)), 0, 4)
	lvl = -1
	set_level(n, false)
	alt_max = float(d.get("alt_max", 0.0))
	vols = int(d.get("vols", 0))
	state = "range"
	_show(false)
	var p: Array = d.get("pose", []) if d.get("pose", []) is Array else []
	if lvl >= 3 and p.size() == 4:
		pos = Vector3(float(p[0]), float(p[1]), float(p[2]))
		yaw = float(p[3])
		state = "pose"
		speed = 0.0
		_show(true)
		_apply_xform(0.0)
	var f: Array = d.get("en_vol", []) if d.get("en_vol", []) is Array else []
	if lvl > 0 and f.size() >= 4:
		pos = Vector3(float(f[0]), float(f[1]), float(f[2]))
		yaw = float(f[3])
		speed = float(f[4]) if f.size() > 4 else float(TUNE[lvl]["cruise"])
		vspeed = 0.0
		_prone = 1.0
		state = "vol"
		_show(true)
		_begin_ride()


func trouvailles() -> Dictionary:
	return {"aeronef_1": 1 if lvl >= 1 else 0, "aeronef_2": 1 if lvl >= 2 else 0, "aeronef_3": 1 if lvl >= 3 else 0,
		"aeronef_4": 1 if lvl >= 4 else 0, "vol_haut": 1 if alt_max > 250.0 else 0}


## Le joueur peut-il se tenir là (pour main._limit_on_foot_v29) : jamais en vol.
func riding_now() -> bool:
	return riding


## Ce que main.gd doit afficher en vol (invite PC).
func ride_prompt() -> String:
	if not riding:
		return ""
	if state == "sol":
		return "Espace : pédaler   E : replier l'Alouette"
	if lvl <= 2:
		return "E : se poser (près du sol)"
	return "E : se poser"
