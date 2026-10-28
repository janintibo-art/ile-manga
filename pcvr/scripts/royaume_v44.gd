extends Node3D
## V44 : le Royaume des Racines s'agrandit (étape 2 du donjon féerique).
##  - À l'ouest du Jardin des Fées : la Grotte des Champignons Sauteurs. Les gros champignons
##    rebondissants propulsent le joueur de plate-forme en corniche ; tout en haut, la
##    baguette perdue de Pimprenelle. Des araignées de cristal rôdent en bas.
##  - À l'est : la Salle des Clochettes. Le pupitre fait entendre une mélodie ; il faut la
##    rejouer sur les cinq clochettes de cristal. Une fausse note réveille des feux follets.
##    La bonne mélodie ouvre la grille de racines du Village des Fées.
##  - Le Village des Fées : une grande caverne, une cascade de lumière, des maisons dans des
##    champignons géants, des fleurs immenses, et ses habitants (fees_v44.gd).
##  - Six gouttes de rosée de lune sont semées dans le royaume (la quête de Brindille).

const FeeScript = preload("res://scripts/pnj/fee_v44.gd")
const Fees = preload("res://scripts/pnj/fees_v44.gd")
const MELODY := [1, 3, 0, 4, 2]
const NOTES := [523.25, 587.33, 659.25, 783.99, 880.0]
const BELL_COLORS := [Color(1.0, 0.55, 0.6), Color(1.0, 0.8, 0.45), Color(0.6, 1.0, 0.6), Color(0.5, 0.8, 1.0), Color(0.8, 0.6, 1.0)]
const VILLAGE_C := Vector3(31.0, 0.0, -80.0)
const DEW := [Vector3(-8.8, 0, -42.0), Vector3(-7.2, 0, -45.6), Vector3(-33.5, 8.6, -55.0), Vector3(-24.5, 4.2, -50.5), Vector3(31.0, 0, -44.2), Vector3(-1.3, 0, -12.0)]
# Champignons rebondissants [x, z, sommet] et la plate-forme du milieu [x, z, sommet, rayon]
const BOUNCERS := [[-21.5, -47.5, 0.7, 12.5], [-28.0, -54.5, 4.9, 14.0]]
const PLATFORM := [-24.5, -50.5, 4.2, 2.3]
const LEDGE_TOP: float = 8.6
const BOUNCE_V: float = 12.5

var f: Node3D                       # feerique_v43
var main: Node
var d: Node
var s: Node3D
var fairies: Array = []
var _bells: Array = []             # {node, light, mat, player}
var _bell_streams: Array = []
var _boing: AudioStreamWAV
var _boing_player: AudioStreamPlayer3D
var _played: Array = []
var _playing_melody: bool = false
var _fail_clock: float = 0.0
var _gate: Array = []              # deux moitiés
var _gate_body: CollisionShape3D
var _dews: Array = []
var _wand: Node3D
var _bouncer_caps: Array = []
var _bounce_cool: float = 0.0
var _fall_mat: ShaderMaterial
var _village_seen: bool = false
var _flyers: Array = []            # petites fées qui volent (décor)
var _clock: float = 0.0


func setup(feerique: Node3D) -> void:
	f = feerique
	main = f.main
	d = f.d
	s = f.s


# =================================================================== construction des salles

func build_rooms() -> void:
	_build_west()
	_build_east()
	_build_village()
	_build_dews()
	# Petites fées qui volent un peu partout (décor)
	_flyers_in(Vector3(31, 3.0, -80), Vector3(14, 3.5, 15), 14, 4450)
	_flyers_in(Vector3(0, 2.5, -51.5), Vector3(6, 1.5, 6), 5, 4451)
	_flyers_in(Vector3(0, 2.5, 0.5), Vector3(4, 1.5, 4), 3, 4452)
	_flyers_in(Vector3(-26, 4.0, -52), Vector3(8, 3.0, 10), 5, 4453)


func _cyl_body(pos: Vector3, radius: float, height: float) -> void:
	var cs := CollisionShape3D.new()
	var c := CylinderShape3D.new()
	c.radius = radius
	c.height = height
	cs.shape = c
	f._body.add_child(cs)
	cs.global_position = s.to_global(pos + Vector3.UP * height * 0.5)


## Un champignon géant « solide » : pied et chapeau sur lesquels on peut marcher.
func _solid_mushroom(x: float, z: float, top: float, r: float, c: Color, bouncy: bool) -> MeshInstance3D:
	var stem_r: float = maxf(r * 0.24, 0.22)
	f._mesh(s, f.gfx.stem_mesh(stem_r, top - 0.3, not bouncy), f.gfx.stem_mat(), Vector3(x, 0, z))
	_cyl_body(Vector3(x, 0, z), stem_r, top - 0.3)
	var cap: MeshInstance3D = f._mesh(s, f.gfx.cap_mesh(r, 0.34), f.gfx.cap_mat(c, true, 1.3 if bouncy else 0.8), Vector3(x, top - r * 0.38, z))
	cap.rotation.y = x
	_cyl_body(Vector3(x, top - 0.4, z), r * 0.95, 0.4)
	f._light(s, Vector3(x, top - 0.8, z), c, 1.6, 6.0 + r * 2.0)
	return cap


## La Grotte des Champignons Sauteurs, et son couloir depuis le jardin.
func _build_west() -> void:
	f._room(-16, -8, -53, -50, 4.0, [["e", -51.5, 3.0, 3.6], ["w", -51.5, 3.0, 3.6]])
	f._room(-36, -16, -66, -38, 16.0, [["e", -51.5, 3.0, 3.6]])
	# Champignons rebondissants et la plate-forme du milieu
	for b in BOUNCERS:
		var cap: MeshInstance3D = _solid_mushroom(float(b[0]), float(b[1]), float(b[2]), 1.25, Color(1.0, 0.45, 0.75), true)
		_bouncer_caps.append(cap)
		# Points blancs qui pulsent : « ça rebondit ! »
		f._sparkles(s, Vector3(float(b[0]), float(b[2]) + 0.4, float(b[1])), Vector3(0.8, 0.3, 0.8), 10, 0.1)
	_solid_mushroom(float(PLATFORM[0]), float(PLATFORM[1]), float(PLATFORM[2]), float(PLATFORM[3]), Color(0.45, 0.8, 1.0), false)
	# La corniche, tout en haut contre le mur ouest
	f._box(s, Vector3(5.5, 0.8, 9.0), Vector3(-33.25, LEDGE_TOP - 0.4, -57.5), f.gfx.rock("mur"))
	f._mesh(s, f.gfx.rock_face(Vector3(-33.25, LEDGE_TOP + 0.01, -57.5), Vector3.RIGHT, Vector3.BACK, 5.5, 9.0, Vector3.DOWN, 0.06, 0.4, [true, true, true, true], false, Vector3.UP), f.gfx.rock("sol"), Vector3.ZERO)
	f._mesh(s, f.gfx.rock_face(Vector3(-30.49, LEDGE_TOP - 0.4, -57.5), Vector3.BACK, Vector3.UP, 9.0, 0.8, Vector3.RIGHT, 0.25, 0.3, [true, true, false, false]), f.gfx.rock("mur"), Vector3.ZERO)
	for k in range(5):
		f._root(Vector3(-30.4, LEDGE_TOP - 0.2, -61.5 + k * 2.0), Vector3(-30.0, 0.0, -61.0 + k * 2.1), Vector3(0.8, -1.0, 0), 0.22, 0.12, 8)
	f._mesh(s, f._cyl(0.3, 0.3, 0.12, 12), f._mat("ecorce"), Vector3(-34.0, LEDGE_TOP + 0.06, -58.6))
	# La baguette de Pimprenelle
	_wand = Node3D.new()
	_wand.name = "Baguette_Pimprenelle"
	s.add_child(_wand)
	_wand.position = Vector3(-34.0, LEDGE_TOP + 0.2, -58.6)
	_wand.rotation.z = 1.3
	f._mesh(_wand, f._cyl(0.012, 0.018, 0.4, 8), f._glow(Color(0.8, 0.65, 0.45), 0.2), Vector3.ZERO)
	f._mesh(_wand, f._sphere(0.05, 8), f._glow(Color(1.0, 0.9, 0.6), 3.0), Vector3(0, 0.22, 0))
	f._light(_wand, Vector3(0, 0.3, 0), Color(1.0, 0.9, 0.6), 1.2, 4.0)
	d._interactions.append({"id": "baguette", "pos": s.to_global(Vector3(-33.6, LEDGE_TOP, -58.6)), "radius": 1.6,
		"text": "E : ramasser la baguette de fée", "vr": "Gâchette : ramasser la baguette", "call": _take_wand,
		"when": func(): return not bool(f.state["baguette"])})
	# Une liane pour redescendre
	for k in range(14):
		f._mesh(s, f._cyl(0.035, 0.035, 0.65, 5), f._glow(Color(0.35, 0.6, 0.3), 0.2), Vector3(-30.25 + sin(k * 0.7) * 0.04, LEDGE_TOP - 0.3 - k * 0.6, -61.5))
	for k in range(6):
		f._mesh(s, f._sphere(0.08, 6), f._glow(Color(0.4, 0.75, 0.35), 0.3), Vector3(-30.25, LEDGE_TOP - 1.0 - k * 1.3, -61.5), Vector3.ZERO, Vector3(1.4, 0.4, 0.8))
	d._interactions.append({"id": "liane", "pos": s.to_global(Vector3(-31.0, LEDGE_TOP, -61.3)), "radius": 1.3,
		"text": "E : redescendre par la liane", "vr": "Gâchette : redescendre", "call": _vine_down})
	d._interactions.append({"id": "liane_bas", "pos": s.to_global(Vector3(-29.6, 0.0, -61.5)), "radius": 1.2,
		"text": "E : grimper à la liane", "vr": "Gâchette : grimper", "call": _vine_up})
	# Décor : petits champignons, cristaux, spores lumineuses
	var cols := [Color(0.95, 0.55, 0.9), Color(0.55, 0.85, 1.0), Color(0.7, 1.0, 0.75)]
	var spots := [Vector3(-18, 0, -40), Vector3(-34, 0, -40), Vector3(-17.5, 0, -64), Vector3(-26, 0, -64.5), Vector3(-35, 0, -47), Vector3(-19, 0, -56)]
	for k in range(spots.size()):
		f._mushroom(spots[k], 0.8 + (k % 3) * 0.6, 0.5 + (k % 2) * 0.4, cols[k % 3], k % 2 == 0)
	f._crystal_cluster(Vector3(-35.0, 0, -42.0), Color(0.9, 0.55, 0.9), 9, 4400, 1.5)
	f._crystal_cluster(Vector3(-17.0, 0, -45.0), Color(0.9, 0.55, 0.9), 6, 4401, 1.1)
	f._crystal_cluster(Vector3(-27.0, 0, -65.0), Color(0.6, 0.9, 1.0), 7, 4402, 1.3)
	f._sparkles(s, Vector3(-26, 6.0, -52), Vector3(9, 6, 13), 90, 0.12)
	var shaft := SpotLight3D.new()
	shaft.light_color = Color(0.9, 0.8, 1.0)
	shaft.light_energy = 2.0
	shaft.spot_range = 20.0
	shaft.spot_angle = 22.0
	shaft.position = Vector3(-33.5, 15.8, -57.5)
	shaft.rotation.x = -PI * 0.5
	s.add_child(shaft)
	_boing = _tone(0.0, 0.45, true)
	_boing_player = AudioStreamPlayer3D.new()
	_boing_player.stream = _boing
	_boing_player.unit_size = 8.0
	_boing_player.volume_db = -4.0
	s.add_child(_boing_player)


## La Salle des Clochettes, et son couloir depuis le jardin.
func _build_east() -> void:
	f._room(8, 16, -53, -50, 4.0, [["w", -51.5, 3.0, 3.6], ["e", -51.5, 3.0, 3.6]])
	f._room(16, 32, -60, -43, 10.0, [["w", -51.5, 3.0, 3.6], ["n", 24.0, 3.2, 4.2]])
	for k in range(5):
		_bell_streams.append(_tone(float(NOTES[k]), 1.6, false))
	for k in range(5):
		var x: float = 18.5 + k * 2.75
		var bell := Node3D.new()
		bell.name = "Clochette_%d" % k
		s.add_child(bell)
		bell.position = Vector3(x, 2.15, -56.5)
		var c: Color = BELL_COLORS[k]
		f._root(Vector3(x, 10.0, -56.5), Vector3(x, 2.5, -56.5), Vector3(0.4 * (k % 2 * 2 - 1), 0, 0.3), 0.09, 0.04, 8)
		var mat: StandardMaterial3D = f._glow(c, 0.6, 0.8).duplicate() as StandardMaterial3D
		f._mesh(bell, f._cyl(0.11, 0.34, 0.5, 16), mat, Vector3(0, 0, 0))
		f._mesh(bell, f._sphere(0.11, 12), mat, Vector3(0, 0.25, 0), Vector3.ZERO, Vector3(1, 0.6, 1))
		f._mesh(bell, f._sphere(0.07, 8), f._mat("or"), Vector3(0, -0.3, 0))
		var l: OmniLight3D = f._light(bell, Vector3(0, -0.2, 0.2), c, 0.3, 5.0)
		var pl := AudioStreamPlayer3D.new()
		pl.stream = _bell_streams[k]
		pl.unit_size = 10.0
		pl.volume_db = -6.0
		bell.add_child(pl)
		_bells.append({"node": bell, "light": l, "mat": mat, "player": pl, "color": c})
		d._interactions.append({"id": "clochette_%d" % k, "pos": s.to_global(Vector3(x, 0, -55.6)), "radius": 1.2,
			"text": "E : faire tinter la clochette", "vr": "Gâchette : faire tinter", "call": ring_bell.bind(k),
			"when": func(): return not bool(f.state["clochettes"]) and not _playing_melody})
	# Le pupitre : une fleur de cristal qui « chante » la mélodie
	f._mesh(s, f._cyl(0.25, 0.4, 1.0, 10), f._mat("pierre"), Vector3(24, 0.5, -46.5))
	for k in range(5):
		var a: float = TAU * k / 5.0
		var pet: MeshInstance3D = f._mesh(s, f._sphere(0.22, 10), f._glow(BELL_COLORS[k], 1.4, 0.85), Vector3(24 + cos(a) * 0.2, 1.15, -46.5 + sin(a) * 0.2), Vector3.ZERO, Vector3(0.5, 0.25, 1.0))
		pet.rotation.y = -a
	f._light(s, Vector3(24, 1.6, -46.5), Color(1.0, 0.9, 0.8), 1.0, 5.0)
	d._interactions.append({"id": "pupitre", "pos": s.to_global(Vector3(24, 0, -45.6)), "radius": 1.5,
		"text": "E : écouter la mélodie des clochettes", "vr": "Gâchette : écouter la mélodie", "call": play_melody,
		"when": func(): return not bool(f.state["clochettes"]) and not _playing_melody})
	# La grille de racines du Village des Fées
	for side in [-1.0, 1.0]:
		var half := Node3D.new()
		half.position = Vector3(24.0 + side * 0.8, 0, -60.2)
		s.add_child(half)
		for k in range(4):
			var x0: float = side * (k * 0.2 - 0.3)
			var prev := Vector3(x0, 0, 0)
			for j in range(1, 7):
				var q := Vector3(x0 + sin(j * 1.3 + k) * 0.18, j * 0.72, sin(j * 0.9 + k) * 0.1)
				var seg: Vector3 = q - prev
				var m: MeshInstance3D = f._mesh(half, f._cyl(0.08, 0.1, seg.length() + 0.06, 6), f._mat("ecorce"), (prev + q) * 0.5)
				m.rotation = Vector3(atan2(seg.z, seg.y), 0, -atan2(seg.x, seg.y))
				prev = q
		_gate.append(half)
	f._mesh(s, f._sphere(0.25, 10), f._glow(Color(1.0, 0.85, 0.5), 2.5), Vector3(24, 3.8, -60.0))
	_gate_body = CollisionShape3D.new()
	var gb := BoxShape3D.new()
	gb.size = Vector3(3.2, 4.2, 0.6)
	_gate_body.shape = gb
	f._body.add_child(_gate_body)
	_gate_body.global_position = s.to_global(Vector3(24, 2.1, -60.0))
	f._mushroom(Vector3(17.2, 0, -44.2), 1.4, 0.8, Color(0.55, 0.85, 1.0), true)
	f._mushroom(Vector3(30.8, 0, -58.8), 1.8, 1.0, Color(0.95, 0.55, 0.9), true)
	f._crystal_cluster(Vector3(17.0, 0, -59.0), Color(0.8, 0.6, 1.0), 7, 4410, 1.2)
	f._sparkles(s, Vector3(24, 4.0, -51.5), Vector3(7, 4, 7), 50)


## Le Village des Fées : cascade de lumière, maisons-champignons, fleurs géantes.
func _build_village() -> void:
	f._room(12, 50, -100, -60, 18.0, [["s", 24.0, 3.2, 4.2]])
	# La cascade de lumière et son bassin
	var fall := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(4.5, 18.0)
	fall.mesh = q
	_fall_mat = ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = """shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;
uniform vec4 tint : source_color = vec4(0.55, 0.95, 1.0, 1.0);
void fragment() {
	float x = UV.x;
	float edge = smoothstep(0.0, 0.18, x) * smoothstep(1.0, 0.82, x);
	float streak = 0.5 + 0.5 * sin(x * 41.0 + sin(x * 13.0) * 2.0);
	float flow = fract(UV.y * 3.0 - TIME * 0.9 + sin(x * 23.0) * 0.3);
	float bright = mix(0.35, 1.0, streak) * (0.55 + 0.45 * smoothstep(0.0, 0.25, flow) * smoothstep(1.0, 0.6, flow));
	ALBEDO = tint.rgb * bright * 1.6;
	ALPHA = edge * 0.85;
}
"""
	_fall_mat.shader = sh
	fall.material_override = _fall_mat
	fall.position = Vector3(31.0, 9.0, -99.3)
	s.add_child(fall)
	var pool_c := Vector3(31.0, 0, -96.0)
	f._mesh(s, f._cyl(3.6, 3.6, 0.04, 32), f._water_mat(), pool_c + Vector3.UP * 0.05)
	var rim := TorusMesh.new()
	rim.inner_radius = 3.55
	rim.outer_radius = 4.0
	rim.rings = 40
	f._mesh(s, rim, f._mat("pierre"), pool_c + Vector3.UP * 0.05, Vector3.ZERO, Vector3(1, 0.5, 1))
	f._light(s, pool_c + Vector3(0, 1.5, 0), Color(0.5, 0.95, 1.0), 2.6, 14.0)
	var mist: CPUParticles3D = f._sparkles(s, pool_c + Vector3(0, 1.0, -1.5), Vector3(2.5, 1.0, 1.5), 50, 0.25)
	mist.gravity = Vector3(0, 0.3, 0)
	# Les maisons-champignons des fées
	var cap_cols := [Color(0.95, 0.45, 0.35), Color(0.55, 0.8, 1.0), Color(0.7, 0.5, 0.95), Color(1.0, 0.6, 0.8), Color(0.65, 0.5, 0.35)]
	for i in range(Fees.FEES.size()):
		_house(Fees.FEES[i]["maison"], cap_cols[i], i)
	# L'étal de Mélisse
	var mh: Vector3 = Fees.FEES[0]["maison"]
	var to_c: Vector3 = ((VILLAGE_C - mh) * Vector3(1, 0, 1)).normalized()
	var stall: Vector3 = mh + to_c * 4.9 - Vector3(-to_c.z, 0, to_c.x) * 1.2
	f._box(s, Vector3(1.8, 0.8, 0.6), stall + Vector3.UP * 0.4, f._mat("ecorce"))
	for k in range(6):
		f._mesh(s, f._sphere(0.07, 8), f._glow(Color(1.0, 0.8, 0.3), 1.2, 0.85), stall + Vector3(-0.7 + k * 0.28, 0.88, 0))
	# La place : un cercle de danse et des fleurs géantes
	for k in range(12):
		var a: float = TAU * k / 12.0
		f._mesh(s, f._sphere(0.18, 8), f._glow(Color(0.95, 0.85, 1.0), 1.5), VILLAGE_C + Vector3(cos(a) * 4.0, 0.1, sin(a) * 4.0), Vector3.ZERO, Vector3(1, 0.5, 1))
	f._mesh(s, f._cyl(4.4, 4.4, 0.04, 40), f._glow(Color(0.45, 0.6, 0.35), 0.2), VILLAGE_C + Vector3.UP * 0.02)
	var dancers: CPUParticles3D = f._sparkles(s, VILLAGE_C + Vector3(0, 1.6, 0), Vector3(3.0, 1.0, 3.0), 40, 0.14)
	dancers.orbit_velocity_min = 0.15
	dancers.orbit_velocity_max = 0.3
	var flowers := [[15.0, -64.0, 3.2], [47.0, -64.0, 2.6], [48.0, -77.0, 3.6], [14.0, -80.0, 2.8], [25.0, -97.0, 3.0], [46.5, -97.0, 2.4], [36.0, -66.0, 1.8], [24.5, -74.0, 1.5]]
	var fcols := [Color(1.0, 0.5, 0.7), Color(0.6, 0.7, 1.0), Color(1.0, 0.85, 0.4), Color(0.8, 0.5, 1.0)]
	for k in range(flowers.size()):
		var fl: Array = flowers[k]
		_flower(Vector3(float(fl[0]), 0, float(fl[1])), float(fl[2]), fcols[k % fcols.size()])
	f._crystal_cluster(Vector3(13.5, 0, -98.0), Color(0.6, 0.9, 1.0), 10, 4420, 1.8)
	f._crystal_cluster(Vector3(48.5, 0, -88.0), Color(0.9, 0.55, 0.9), 8, 4421, 1.6)
	f._sparkles(s, Vector3(31, 7.0, -80), Vector3(17, 7, 18), 160, 0.13)
	# De grosses racines qui traversent le plafond de la caverne
	for k in range(5):
		var x: float = 16.0 + k * 8.0
		f._root(Vector3(x, 18.0, -62.0), Vector3(x + 4.0, 18.0, -98.0), Vector3(0, -6.0 - (k % 2) * 3.0, 0), 0.6, 0.35, 14)


func _house(at: Vector3, cap_c: Color, i: int) -> void:
	var h: float = 5.0 + (i % 3) * 0.8
	var r: float = 3.2 + (i % 2) * 0.6
	var stem_r: float = 1.35
	f._mesh(s, f.gfx.stem_mesh(stem_r * 1.05, h, false), f.gfx.stem_mat(), at)
	_cyl_body(at, stem_r * 1.1, h)
	var capm: MeshInstance3D = f._mesh(s, f.gfx.cap_mesh(r, 0.5), f.gfx.cap_mat(cap_c, i % 2 == 0, 0.8), at + Vector3.UP * (h + 0.15))
	capm.rotation.y = i * 1.3
	# Porte ronde et fenêtres, tournées vers la place
	var to_c: Vector3 = ((VILLAGE_C - at) * Vector3(1, 0, 1)).normalized()
	var side := Vector3(-to_c.z, 0, to_c.x)
	var door_p: Vector3 = at + to_c * (stem_r * 1.2)
	var door := Node3D.new()
	s.add_child(door)
	door.position = door_p
	door.rotation.y = atan2(to_c.x, to_c.z)
	f._mesh(door, f._boxm(Vector3(0.9, 1.3, 0.12)), f._mat("ecorce"), Vector3(0, 0.65, 0))
	f._mesh(door, f._cyl(0.45, 0.45, 0.12, 16), f._mat("ecorce"), Vector3(0, 1.3, 0), Vector3(PI * 0.5, 0, 0))
	f._mesh(door, f._sphere(0.05, 8), f._mat("or"), Vector3(0.28, 0.75, 0.08))
	for w in [Vector3(0.55, 2.6, 0), Vector3(-0.5, 3.4, 0)]:
		var wp: Vector3 = at + to_c * (stem_r * 1.0) + side * w.x + Vector3.UP * w.y
		f._mesh(s, f._sphere(0.22, 10), f._glow(Color(1.0, 0.8, 0.45), 2.2), wp, Vector3(0, atan2(to_c.x, to_c.z), 0), Vector3(1.0, 1.0, 0.3))
	f._light(s, at + to_c * 2.2 + Vector3.UP * 2.8, Color(1.0, 0.8, 0.5), 1.2, 7.0)
	# V82 : on peut entrer chez la fée (une maison à sa taille… et à la nôtre, par magie)
	preload("res://scripts/azur_kit_v56.gd").note_v81(s.to_global(door_p + to_c * 0.9) + Vector3.UP * 0.05, s.global_transform.basis * to_c, 5.0, 5.0, "fee", 1, str((Fees.FEES[i]["data"] as Dictionary).get("id", "")))
	# Une petite lanterne-fleur devant la porte
	f._mesh(s, f._cyl(0.025, 0.03, 1.2, 6), f._glow(Color(0.35, 0.6, 0.3), 0.2), door_p + to_c * 0.9 + side * 0.9 + Vector3.UP * 0.6)
	f._mesh(s, f._sphere(0.12, 10), f._glow(Color(1.0, 0.85, 0.55), 2.5), door_p + to_c * 0.9 + side * 0.9 + Vector3.UP * 1.25, Vector3.ZERO, Vector3(1.0, 1.3, 1.0))


func _flower(at: Vector3, h: float, c: Color) -> void:
	var stem: Material = f._glow(Color(0.3, 0.55, 0.3), 0.15)
	var lean := Vector3(sin(at.x) * 0.12, 0, cos(at.z) * 0.12)
	f._mesh(s, f._cyl(0.06, 0.1, h, 8), stem, at + Vector3.UP * h * 0.5, lean)
	var top: Vector3 = at + Vector3.UP * h + Vector3(lean.z, 0, -lean.x) * h * 0.5
	for k in range(7):
		var a: float = TAU * k / 7.0
		var pet: MeshInstance3D = f._mesh(s, f._sphere(0.5, 12), f._glow(c, 0.55), top + Vector3(cos(a) * 0.45, 0.05, sin(a) * 0.45), Vector3.ZERO, Vector3(0.55, 0.12, 1.0))
		pet.rotation = Vector3(0.35, -a + PI * 0.5, 0)
	f._mesh(s, f._sphere(0.2, 12), f._glow(Color(1.0, 0.9, 0.5), 2.5), top + Vector3.UP * 0.12)
	for k in range(2):
		var la: float = k * PI + at.x
		var leaf: MeshInstance3D = f._mesh(s, f._sphere(0.4, 10), stem, at + Vector3(cos(la) * 0.35, h * 0.35, sin(la) * 0.35), Vector3.ZERO, Vector3(0.35, 0.06, 1.0))
		leaf.rotation = Vector3(0.4, -la, 0)
	f._light(s, top + Vector3.UP * 0.5, c, 0.9, 5.0)


func _flyers_in(center: Vector3, half: Vector3, n: int, seed_v: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var cols := [Color(1.0, 0.7, 0.9), Color(0.6, 0.9, 1.0), Color(1.0, 0.9, 0.55), Color(0.75, 1.0, 0.7), Color(0.85, 0.7, 1.0)]
	for k in range(n):
		var c: Color = cols[rng.randi() % cols.size()]
		var fl := Node3D.new()
		s.add_child(fl)
		var core := StandardMaterial3D.new()
		core.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		core.albedo_color = c.lightened(0.5)
		f._mesh(fl, f._sphere(0.035, 8), core, Vector3.ZERO, Vector3.ZERO, Vector3(0.8, 1.3, 0.8))
		var halo := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(0.35, 0.35)
		var hm := StandardMaterial3D.new()
		hm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		hm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		hm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		hm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		hm.albedo_color = Color(c.r, c.g, c.b, 0.6)
		hm.albedo_texture = main._soft_dot_v24()
		q.material = hm
		halo.mesh = q
		fl.add_child(halo)
		var wm := StandardMaterial3D.new()
		wm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		wm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		wm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		wm.cull_mode = BaseMaterial3D.CULL_DISABLED
		wm.albedo_color = Color(c.r, c.g, c.b, 0.5)
		var wings: Array = []
		for sx in [-1.0, 1.0]:
			var hinge := Node3D.new()
			fl.add_child(hinge)
			var w := MeshInstance3D.new()
			var wq := QuadMesh.new()
			wq.size = Vector2(0.08, 0.06)
			w.mesh = wq
			w.material_override = wm
			w.position = Vector3(sx * 0.045, 0.01, 0)
			hinge.add_child(w)
			wings.append(hinge)
		_flyers.append({"node": fl, "wings": wings, "c": center, "h": half, "ph": rng.randf() * TAU,
			"fx": rng.randf_range(0.12, 0.3), "fz": rng.randf_range(0.1, 0.28), "fy": rng.randf_range(0.4, 0.9)})


func _build_dews() -> void:
	for i in range(DEW.size()):
		var p: Vector3 = DEW[i]
		var n := Node3D.new()
		n.name = "Goutte_rosee_%d" % i
		s.add_child(n)
		n.position = p
		f._mesh(n, f._sphere(0.18, 10), f._glow(Color(0.35, 0.65, 0.35), 0.2), Vector3(0, 0.03, 0), Vector3.ZERO, Vector3(1.0, 0.12, 0.7))
		f._mesh(n, f._sphere(0.07, 12), f._glow(Color(0.75, 0.95, 1.0), 2.5, 0.85), Vector3(0, 0.12, 0), Vector3.ZERO, Vector3(1.0, 1.2, 1.0))
		f._light(n, Vector3(0, 0.3, 0), Color(0.7, 0.95, 1.0), 0.8, 3.0)
		_dews.append(n)
		d._interactions.append({"id": "rosee_%d" % i, "pos": s.to_global(p), "radius": 1.2,
			"text": "E : ramasser la goutte de rosée", "vr": "Gâchette : ramasser la rosée", "call": _take_dew.bind(i),
			"when": func(): return ((int(f.state["rosee"]) >> i) & 1) == 0})


# =================================================================== les fées

func spawn_fairies() -> void:
	for i in range(Fees.FEES.size()):
		var data: Dictionary = Fees.fiche(i)
		var home: Vector3 = Fees.FEES[i]["maison"]
		var to_c: Vector3 = ((VILLAGE_C - home) * Vector3(1, 0, 1)).normalized()
		var side := Vector3(-to_c.z, 0, to_c.x)
		var at: Vector3 = s.to_global(home + to_c * 3.8 - side * 1.2)
		var fee: Node3D = FeeScript.new()
		main.add_child(fee)
		fee.setup(main, data, at)
		var saved: Variant = main.pending_pnj_v31.get(str(data["id"]), {})
		if saved is Dictionary and not (saved as Dictionary).is_empty():
			fee.load_data(saved)
		main.npcs_v31.append(fee)
		fairies.append(fee)


func fairy(id: String) -> Node3D:
	for fe in fairies:
		if str(fe.profile["id"]) == id:
			return fe
	return null


# =================================================================== interactions

func _take_wand() -> void:
	var got: int = main.inventory_v28.add("baguette_fee", 1)
	if got <= 0:
		d._say("Ton sac est plein ! Fais de la place pour la baguette.", 3.0)
		return
	f.state["baguette"] = true
	apply_state()
	d._say("La baguette de Pimprenelle ! Son étoile de cristal crépite entre tes doigts. Elle sera ravie de la retrouver, au Village des Fées.", 6.0)


func _take_dew(i: int) -> void:
	var got: int = main.inventory_v28.add("goutte_rosee", 1)
	if got <= 0:
		d._say("Ton sac est plein !", 2.5)
		return
	f.state["rosee"] = int(f.state["rosee"]) | (1 << i)
	apply_state()
	d._say("Une goutte de rosée de lune. Elle reste ronde et fraîche au creux de ta main. (Brindille, au Village des Fées, en cherche cinq.)", 4.5)


func _vine_down() -> void:
	await d._travel(s.to_global(Vector3(-29.2, 0.05, -60.6)), s.to_global(Vector3(1, 0, 0)) - s.to_global(Vector3.ZERO))


func _vine_up() -> void:
	await d._travel(s.to_global(Vector3(-32.5, LEDGE_TOP + 0.05, -60.4)), s.to_global(Vector3(-1, 0, 0)) - s.to_global(Vector3.ZERO))


func ring_bell(k: int) -> void:
	_ring(k, true)
	if _playing_melody or bool(f.state["clochettes"]):
		return
	_played.append(k)
	var n: int = _played.size()
	if _played[n - 1] != MELODY[n - 1]:
		_played.clear()
		_fail()
		return
	if n == MELODY.size():
		_played.clear()
		_solve()


func _ring(k: int, sound: bool) -> void:
	var b: Dictionary = _bells[k]
	var node: Node3D = b["node"]
	var mat: StandardMaterial3D = b["mat"]
	var l: OmniLight3D = b["light"]
	if sound and (b["player"] as AudioStreamPlayer3D).is_inside_tree():
		(b["player"] as AudioStreamPlayer3D).play()
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(mat, "emission_energy_multiplier", 4.0, 0.08)
	tw.tween_property(l, "light_energy", 2.5, 0.08)
	tw.tween_property(node, "rotation:z", 0.25, 0.1)
	tw.chain().set_parallel(true)
	tw.tween_property(mat, "emission_energy_multiplier", 0.6, 0.9)
	tw.tween_property(l, "light_energy", 0.3, 0.9)
	tw.tween_property(node, "rotation:z", 0.0, 0.9).set_trans(Tween.TRANS_ELASTIC)


func play_melody() -> void:
	if _playing_melody:
		return
	_playing_melody = true
	_played.clear()
	d._say("La fleur de cristal frémit… et les clochettes se mettent à chanter toutes seules. Écoute bien, et regarde lesquelles brillent.", 5.0)
	for k in MELODY:
		await get_tree().create_timer(0.75).timeout
		_ring(int(k), true)
	await get_tree().create_timer(0.6).timeout
	_playing_melody = false


func _fail() -> void:
	d._say("Une fausse note ! Les clochettes grincent… et des feux follets surgissent en ricanant !", 4.0)
	for b in _bells:
		var mat: StandardMaterial3D = b["mat"]
		var c0: Color = b["color"]
		mat.emission = Color(1.0, 0.2, 0.2)
		var tw := create_tween()
		tw.tween_property(mat, "emission", c0, 1.0)
	if _fail_clock <= 0.0 and main.monstres_v36 != null:
		_fail_clock = 20.0
		for k in range(2):
			var m: Node3D = main.monstres_v36.spawn_extra("follet", s.to_global(Vector3(20.0 + k * 8.0, 0.05, -45.5)))
			m.home = s.to_global(Vector3(20.0 + k * 8.0, 0.05, -45.5))


func _solve() -> void:
	f.state["clochettes"] = true
	d._say("La mélodie entière résonne dans la salle ! Au nord, la grille de racines se dénoue lentement… et une lumière dorée passe par l'ouverture.", 6.0)
	for k in range(5):
		var tw := create_tween()
		tw.tween_interval(0.2 * k)
		tw.tween_callback(_ring.bind(k, false))
	_open_gate(false)


func _open_gate(instant: bool) -> void:
	if not instant and f.main.get("sfx_v50") != null:
		f.main.sfx_v50.here("grille")
	for i in range(_gate.size()):
		var half: Node3D = _gate[i]
		var side: float = -1.0 if i == 0 else 1.0
		var target_x: float = 24.0 + side * 2.6
		if instant:
			half.position.x = target_x
			half.scale = Vector3(0.5, 1, 1)
		else:
			var tw := create_tween()
			tw.set_parallel(true)
			tw.tween_property(half, "position:x", target_x, 3.0).set_trans(Tween.TRANS_SINE)
			tw.tween_property(half, "scale", Vector3(0.5, 1, 1), 3.0)
	_gate_body.set_deferred("disabled", true)


func _close_gate() -> void:
	for i in range(_gate.size()):
		var half: Node3D = _gate[i]
		half.position.x = 24.0 + (-1.0 if i == 0 else 1.0) * 0.8
		half.scale = Vector3.ONE
	_gate_body.set_deferred("disabled", false)


func apply_state() -> void:
	if _wand != null:
		_wand.visible = not bool(f.state["baguette"])
	for i in range(_dews.size()):
		(_dews[i] as Node3D).visible = ((int(f.state["rosee"]) >> i) & 1) == 0
	if _gate_body != null:
		if bool(f.state["clochettes"]):
			_open_gate(true)
		else:
			_close_gate()
	_played.clear()


# =================================================================== sons

## Sons fabriqués ici : la clochette (fondamentale et harmoniques qui s'éteignent), le
## « boïng » des champignons (une note qui glisse vers l'aigu).
func _tone(freq: float, seconds: float, boing: bool) -> AudioStreamWAV:
	var rate: int = 22050
	var n: int = int(rate * seconds)
	var data := PackedByteArray()
	data.resize(n * 2)
	var phase: float = 0.0
	for i in range(n):
		var t: float = float(i) / rate
		var v: float
		if boing:
			var fq: float = 140.0 + 380.0 * (1.0 - exp(-t * 7.0))
			phase += TAU * fq / rate
			v = sin(phase + 2.0 * sin(phase * 0.5)) * exp(-t * 6.0) * minf(t * 60.0, 1.0)
		else:
			v = (sin(TAU * freq * t) + 0.45 * sin(TAU * freq * 2.01 * t) * exp(-t * 2.0) + 0.2 * sin(TAU * freq * 3.98 * t) * exp(-t * 4.0)) * exp(-t * 2.6) * minf(t * 400.0, 1.0)
		data.encode_s16(i * 2, int(clampf(v * 0.4, -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	w.data = data
	return w


# =================================================================== chaque image

func _process(delta: float) -> void:
	if main == null or not main.game_started or s == null or not bool(f.in_zone):
		return
	_fail_clock = maxf(_fail_clock - delta, 0.0)
	_clock += delta
	for fy in _flyers:
		var t: float = _clock + float(fy["ph"])
		var c: Vector3 = fy["c"]
		var h: Vector3 = fy["h"]
		var node: Node3D = fy["node"]
		var np := Vector3(c.x + sin(t * float(fy["fx"]) * 2.0) * h.x, c.y + sin(t * float(fy["fy"])) * h.y * 0.5, c.z + sin(t * float(fy["fz"]) * 2.0 + 1.3) * h.z)
		var vel: Vector3 = np - node.position
		node.position = np
		if vel.length() > 0.0001:
			node.rotation.y = atan2(vel.x, vel.z)
		var flap: float = sin(t * 30.0) * 0.8
		(fy["wings"][0] as Node3D).rotation.z = flap
		(fy["wings"][1] as Node3D).rotation.z = -flap
	_bounce_cool = maxf(_bounce_cool - delta, 0.0)
	var p: Vector3 = main._player_pos_v27()
	var lp: Vector3 = s.to_local(p)
	# Les champignons rebondissants
	if _bounce_cool <= 0.0:
		for k in range(BOUNCERS.size()):
			var b: Array = BOUNCERS[k]
			if Vector2(lp.x - float(b[0]), lp.z - float(b[1])).length() < 1.15 and absf(lp.y - float(b[2])) < 0.35:
				_bounce(k)
				break
	if _wand != null and _wand.visible:
		_wand.rotation.y += delta * 0.8
	for i in range(_dews.size()):
		var dn: Node3D = _dews[i]
		if dn.visible:
			dn.get_child(1).position.y = 0.12 + sin(Time.get_ticks_msec() * 0.003 + i) * 0.03
	# Première visite du village
	if not bool(f.state["village"]) and lp.x > 13.0 and lp.z < -62.0:
		f.state["village"] = true
		d._say("Le Village des Fées ! Des maisons dans des champignons géants, une cascade de lumière, et partout de petites ailes qui scintillent…", 6.0)
		if f.lumi != null:
			f.lumi_say("Bienvenue chez moi ! Va dire bonjour à tout le monde. Même à Grommelot. Surtout à Grommelot : il adore qu'on l'ignore.", 7.0)


func _bounce(k: int) -> void:
	_bounce_cool = 0.6
	var cap: MeshInstance3D = _bouncer_caps[k]
	var tw := create_tween()
	tw.tween_property(cap, "scale", Vector3(1.25, 0.5, 1.25), 0.08)
	tw.tween_property(cap, "scale", Vector3.ONE, 0.5).set_trans(Tween.TRANS_ELASTIC)
	if _boing_player != null:
		_boing_player.global_position = cap.global_position
		_boing_player.play()
	var v: float = float(BOUNCERS[k][3])
	if main.xr_active:
		main.vr_body.velocity.y = v
	else:
		main.pc_body.velocity.y = v
		if main.hero_v28 != null:
			main.hero_v28.state = "air"
			main.hero_v28.fall_top = main.pc_body.position.y
	if main.combat_v28 != null:
		main.combat_v28.puff(cap.global_position + Vector3.UP * 0.3, Color(1.0, 0.6, 0.85))
