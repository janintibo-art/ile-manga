extends Node3D
## V129 : l'« âme » d'une arme (voir armes_v129.gd) : ce qui bouge et luit sur elle.
##  - souffle (épée naine) : les runes respirent comme des braises qu'on attise ;
##  - eclair (Épée des Nuées) : la veine crépite, des arcs bleus sautent d'un bord à l'autre ;
##  - vague (Trident) : la pierre de mer monte et descend comme la houle ;
##  - coeur (Lame du Cœur) : le cristal bat, « toum-toum », une soixantaine de fois par minute ;
##  - arcane (Bâton) : le cristal flotte et tourne, l'anneau de runes tourne en sens inverse ;
##  - un reflet glisse le long du fil des lames d'acier, de temps en temps.
## Tout est réglé sur l'horloge commune : deux exemplaires de la même arme battent ensemble.

var genre: String = ""
var arme: String = ""
var couleur: Color = Color.WHITE
var couleur2: Color = Color.WHITE
var mode: String = ""
var pulse: Array = []
var lumiere: OmniLight3D
var cristal: Node3D
var orbite: Node3D
var reflet: MeshInstance3D
var fil_bas: float = 0.1
var fil_haut: float = 0.8
var courbe: float = 0.0

var _rng := RandomNumberGenerator.new()
var _arc_t: float = 0.0
var _arc_next: float = 0.4
var _arcs: MeshInstance3D
var _arc_mesh: ImmediateMesh
var _glint_t: float = -1.0
var _glint_next: float = 2.0
var _l0: float = -1.0


func _ready() -> void:
	_rng.randomize()
	_glint_next = _rng.randf_range(1.5, 5.0)
	if lumiere != null:
		_l0 = lumiere.light_energy
	if mode == "eclair":
		_arc_mesh = ImmediateMesh.new()
		_arcs = MeshInstance3D.new()
		_arcs.name = "Arcs"
		_arcs.mesh = _arc_mesh
		_arcs.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.vertex_color_use_as_albedo = true
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		_arcs.material_override = m
		add_child(_arcs)


## La pulsation (0..~2) selon le mode, à l'instant t.
func force(t: float) -> float:
	match mode:
		"souffle":
			return 0.55 + 0.45 * (0.5 + 0.5 * sin(t * 2.2)) + 0.08 * sin(t * 17.0) * sin(t * 5.3)
		"vague":
			return 0.65 + 0.35 * sin(t * 1.6)
		"coeur":
			var x: float = fmod(t, 0.92)
			var beat: float = exp(-pow(x / 0.055, 2.0)) + 0.65 * exp(-pow((x - 0.21) / 0.055, 2.0))
			return 0.6 + 1.1 * beat
		"arcane":
			return 0.75 + 0.25 * sin(t * 2.6)
		"eclair":
			return 0.7 + 0.15 * sin(t * 31.0) + (1.2 if _arc_t > 0.0 else 0.0)
	return 1.0


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	var t: float = Time.get_ticks_msec() / 1000.0
	var f: float = force(t)
	for mi in pulse:
		if mi == null or not is_instance_valid(mi):
			continue
		var m: Material = (mi as MeshInstance3D).material_override
		if m is StandardMaterial3D and m.has_meta("e0"):
			(m as StandardMaterial3D).emission_energy_multiplier = float(m.get_meta("e0")) * f
	if lumiere != null and _l0 >= 0.0:
		lumiere.light_energy = _l0 * f if mode != "eclair" else (1.1 if _arc_t > 0.0 else 0.0)
	if cristal != null:
		cristal.position.y = 1.115 + sin(t * 1.7) * 0.008
		cristal.rotation.y = t * 0.9
	if orbite != null:
		orbite.rotation = Vector3(0.35, -t * 0.6, 0.0)
	if mode == "eclair":
		_tick_arcs(delta)
	if reflet != null:
		_tick_glint(delta)


func _tick_arcs(delta: float) -> void:
	if _arc_t > 0.0:
		_arc_t -= delta
		if _arc_t <= 0.0:
			_arc_mesh.clear_surfaces()
		return
	_arc_next -= delta
	if _arc_next > 0.0:
		return
	_arc_next = _rng.randf_range(0.25, 1.1)
	_arc_t = 0.07
	_arc_mesh.clear_surfaces()
	_arc_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in range(_rng.randi_range(1, 2)):
		var y0: float = _rng.randf_range(fil_bas + 0.05, fil_haut - 0.12)
		var y1: float = y0 + _rng.randf_range(0.04, 0.16)
		var side: float = -1.0 if _rng.randf() < 0.5 else 1.0
		var a := Vector3(side * 0.02, y0, 0)
		var b := Vector3(-side * _rng.randf_range(0.0, 0.03), y1, _rng.randf_range(-0.02, 0.02))
		var pts: Array = [a]
		for i in range(1, 6):
			var p: Vector3 = a.lerp(b, i / 6.0)
			pts.append(p + Vector3(_rng.randf_range(-0.012, 0.012), _rng.randf_range(-0.006, 0.006), _rng.randf_range(-0.012, 0.012)))
		pts.append(b)
		for i in range(pts.size() - 1):
			_ribbon(pts[i], pts[i + 1], 0.0035, couleur2)
			_ribbon(pts[i], pts[i + 1], 0.009, Color(couleur.r, couleur.g, couleur.b, 0.35))
	_arc_mesh.surface_end()


func _ribbon(a: Vector3, b: Vector3, w: float, c: Color) -> void:
	var d: Vector3 = (b - a).normalized()
	for side in [Vector3(0, 0, 1), Vector3(1, 0, 0)]:
		var o: Vector3 = d.cross(side).normalized() * w * 0.5
		if o.length() < 1e-5:
			continue
		_arc_mesh.surface_set_color(c)
		_arc_mesh.surface_add_vertex(a - o)
		_arc_mesh.surface_add_vertex(a + o)
		_arc_mesh.surface_add_vertex(b + o)
		_arc_mesh.surface_add_vertex(a - o)
		_arc_mesh.surface_add_vertex(b + o)
		_arc_mesh.surface_add_vertex(b - o)


func _tick_glint(delta: float) -> void:
	var mat: StandardMaterial3D = (reflet.mesh as QuadMesh).material
	if _glint_t < 0.0:
		_glint_next -= delta
		if _glint_next <= 0.0:
			_glint_t = 0.0
			reflet.visible = true
		return
	_glint_t += delta
	var u: float = clampf(_glint_t / 0.55, 0.0, 1.0)
	var y: float = lerpf(fil_bas, fil_haut, u)
	var uu: float = (y - fil_bas) / maxf(fil_haut - fil_bas, 0.01)
	var x: float = courbe * uu * uu - (0.018 if courbe > 0.0 else -0.018)
	if arme == "hache":
		reflet.position = Vector3(0, lerpf(0.71, 0.5, u), 0.185 + 0.02 * sin(PI * u))
	else:
		reflet.position = Vector3(x, y, 0.0)
	var a: float = sin(u * PI)
	mat.albedo_color = Color(1, 1, 1, a * 0.9)
	reflet.scale = Vector3.ONE * (0.6 + 0.6 * a)
	if u >= 1.0:
		_glint_t = -1.0
		reflet.visible = false
		_glint_next = _rng.randf_range(2.5, 7.0)
