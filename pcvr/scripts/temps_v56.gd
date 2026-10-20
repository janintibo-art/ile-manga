extends Node
## V56 : l'heure qui passe. Une journée de jeu dure une vingtaine de minutes : une minute
## par heure le jour, trente secondes la nuit. Le soleil se lève à l'est vers 6 h, passe
## haut vers 13 h et se couche vers 20 h ; la nuit, la lune prend sa place (la même lumière
## directionnelle, bleutée et faible) et le ciel s'étoile (sky_v56.gdshader).
## Les lampes et les fenêtres inscrites (register_lamp / register_glow) s'allument au
## crépuscule. Les autres systèmes qui assombrissent le monde (souterrains, plongée) gardent
## la main : tant que le soleil est caché ou que la mer impose son brouillard, on ne touche
## qu'à la position du soleil.

signal hour_changed(h: int)

const DAY_SPEED: float = 60.0          # secondes réelles par heure de jeu, de 5 h à 21 h
const NIGHT_SPEED: float = 30.0        # de 21 h à 5 h
const SUN_ENERGY: float = 1.35
const MOON_ENERGY: float = 0.5
const FOG_DAY := Color(0.66, 0.77, 0.9)
const FOG_DUSK := Color(0.84, 0.62, 0.5)
const FOG_NIGHT := Color(0.045, 0.06, 0.1)

var main: Node
var hour: float = 9.0
var day_count: int = 1
var frozen: bool = false               # pour les tests et les photos
var sun: DirectionalLight3D
var env: Environment
var sky_mat: ShaderMaterial
var sun_elev: float = 45.0             # degrés
var moon_elev: float = -20.0
var w_day: float = 1.0
var w_dusk: float = 0.0
var w_night: float = 0.0
var lamps_on: bool = false
var _lamps: Array = []                 # [Light3D, énergie]
var _glows: Array = []                 # [Material, énergie allumée, énergie éteinte]
var _last_hour: int = -1
var _fade_layer: CanvasLayer
var _fade_rect: ColorRect
var _fade_sphere: MeshInstance3D
var _sleeping: bool = false
var _amb_base: float = 1.0


func setup(main_node: Node) -> void:
	main = main_node
	for c in main.get_children():
		if c is WorldEnvironment:
			env = (c as WorldEnvironment).environment
	if env != null:
		_amb_base = env.ambient_light_energy
	sun = main.get_node_or_null("Soleil_v24") as DirectionalLight3D
	if env != null and env.sky != null:
		var old: ShaderMaterial = env.sky.sky_material as ShaderMaterial
		sky_mat = ShaderMaterial.new()
		sky_mat.shader = load("res://shaders/sky_v56.gdshader")
		if old != null:
			sky_mat.set_shader_parameter("cloud_octaves", old.get_shader_parameter("cloud_octaves"))
		env.sky.sky_material = sky_mat
	_build_fade()
	apply()


# =================================================================== l'horloge

func _process(delta: float) -> void:
	if not frozen and _running():
		var speed: float = NIGHT_SPEED if (hour >= 21.0 or hour < 5.0) else DAY_SPEED
		hour += delta / speed
		if hour >= 24.0:
			hour -= 24.0
			day_count += 1
	apply()
	var hi: int = int(hour)
	if hi != _last_hour:
		_last_hour = hi
		hour_changed.emit(hi)


func _running() -> bool:
	if main == null or not bool(main.get("game_started")):
		return false
	var gm: Node = main.get("game_menu")
	return gm == null or not bool(gm.get("opened"))


func set_hour(h: float) -> void:
	hour = wrapf(h, 0.0, 24.0)
	apply()


func hour_text() -> String:
	var m: int = int(floor((hour - floor(hour)) * 60.0))
	return "%02d:%02d" % [int(hour), m]


## Le moment de la journée, en toutes lettres.
func period() -> String:
	if hour < 5.0 or hour >= 22.0:
		return "nuit"
	if hour < 7.0:
		return "aube"
	if hour < 12.0:
		return "matin"
	if hour < 14.0:
		return "midi"
	if hour < 19.0:
		return "après-midi"
	if hour < 20.5:
		return "soir"
	return "crépuscule"


func is_night() -> bool:
	return hour >= 21.0 or hour < 6.0


func serialize() -> Dictionary:
	return {"heure": hour, "jour": day_count}


func load_data(d: Dictionary) -> void:
	hour = wrapf(float(d.get("heure", 9.0)), 0.0, 24.0)
	day_count = maxi(1, int(d.get("jour", 1)))
	_last_hour = -1
	apply()


# =================================================================== soleil, lune, ciel

static func _sun_angles(h: float) -> Vector2:
	var elev: float
	if h >= 6.0 and h <= 20.0:
		elev = 62.0 * sin(PI * (h - 6.0) / 14.0)
	else:
		elev = -28.0 * sin(PI * wrapf(h - 20.0, 0.0, 24.0) / 10.0)
	var yaw: float = -35.0 - (h - 13.0) * 12.0
	return Vector2(elev, yaw)


static func _moon_angles(h: float) -> Vector2:
	var n: float = wrapf(h - 19.0, 0.0, 24.0) / 12.0          # 19 h -> 7 h
	var elev: float = 48.0 * sin(PI * n) if n <= 1.0 else -20.0
	var yaw: float = 55.0 - n * 170.0
	return Vector2(elev, yaw)


static func _dir(elev: float, yaw: float) -> Vector3:
	return Basis.from_euler(Vector3(deg_to_rad(-elev), deg_to_rad(yaw), 0.0)).z


## Le monde est-il « dehors » (personne d'autre ne règle la lumière) ?
func outdoor() -> bool:
	if sun == null or not sun.visible:
		return false
	var mer: Node = main.get("mer_v55") if main != null else null
	if mer != null and not (mer.get("_env_base") as Dictionary).is_empty():
		return false
	return true


func apply() -> void:
	var sa: Vector2 = _sun_angles(hour)
	var ma: Vector2 = _moon_angles(hour)
	sun_elev = sa.x
	moon_elev = ma.x
	w_day = smoothstep(2.0, 14.0, sun_elev)
	w_dusk = smoothstep(-13.0, -1.0, sun_elev) * (1.0 - smoothstep(5.0, 17.0, sun_elev))
	w_night = 1.0 - smoothstep(-15.0, -3.0, sun_elev)
	var sun_k: float = smoothstep(-1.0, 10.0, sun_elev)
	var moon_k: float = (1.0 - smoothstep(-8.0, -1.0, sun_elev)) * smoothstep(0.0, 12.0, moon_elev)
	var warm: float = smoothstep(2.0, 25.0, sun_elev)
	var sun_tint: Color = Color(1.0, 0.56, 0.3).lerp(Color(1.0, 0.95, 0.86), warm)
	if sun != null:
		var use_sun: bool = sun_k >= moon_k * 0.25
		var a: Vector2 = sa if use_sun else ma
		sun.rotation_degrees = Vector3(-maxf(a.x, 1.0), a.y, 0.0)
		if outdoor():
			if use_sun:
				sun.light_energy = SUN_ENERGY * sun_k
				sun.light_color = sun_tint
			else:
				sun.light_energy = MOON_ENERGY * moon_k
				sun.light_color = Color(0.62, 0.72, 1.0)
			if env != null:
				var fog: Color = (FOG_DAY * w_day + FOG_DUSK * w_dusk + FOG_NIGHT * w_night) / maxf(w_day + w_dusk + w_night, 0.001)
				env.fog_light_color = fog
				# la nuit, le ciel éclaire peu : on garde assez de lumière pour se promener
				var fk: float = 0.0
				var fo: Node = main.get("foret_v52")
				if fo != null:
					fk = float(fo.k)
				env.ambient_light_energy = _amb_base * (1.0 + 1.6 * fk) * (1.0 + 2.4 * w_night + 0.6 * w_dusk)
	if sky_mat != null:
		sky_mat.set_shader_parameter("day", w_day)
		sky_mat.set_shader_parameter("dusk", w_dusk)
		sky_mat.set_shader_parameter("night", w_night)
		sky_mat.set_shader_parameter("sun_dir", _dir(sa.x, sa.y))
		sky_mat.set_shader_parameter("moon_dir", _dir(ma.x, ma.y))
		sky_mat.set_shader_parameter("sun_tint", Vector3(sun_tint.r, sun_tint.g, sun_tint.b))
		sky_mat.set_shader_parameter("star_rot", hour / 24.0 * TAU)
	var want: bool = sun_elev < 4.0
	if want != lamps_on:
		lamps_on = want
		_apply_lamps()


# =================================================================== lampes et fenêtres

func register_lamp(light: Light3D, energy: float) -> void:
	_lamps.append([light, energy])
	light.visible = lamps_on
	light.light_energy = energy


func register_glow(mat: Material, energy_on: float, energy_off: float = 0.0) -> void:
	_glows.append([mat, energy_on, energy_off])
	_set_glow(mat, energy_on if lamps_on else energy_off)


func _set_glow(mat: Material, e: float) -> void:
	if mat is StandardMaterial3D:
		(mat as StandardMaterial3D).emission_energy_multiplier = e
	elif mat is ShaderMaterial:
		(mat as ShaderMaterial).set_shader_parameter("glow", e)


func _apply_lamps() -> void:
	for l in _lamps:
		if is_instance_valid(l[0]):
			(l[0] as Light3D).visible = lamps_on
	for g in _glows:
		_set_glow(g[0], float(g[1]) if lamps_on else float(g[2]))


# =================================================================== dormir

func _build_fade() -> void:
	_fade_layer = CanvasLayer.new()
	_fade_layer.layer = 30
	add_child(_fade_layer)
	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(0, 0, 0, 0)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade_layer.add_child(_fade_rect)


func _fade_to(a: float, seconds: float) -> void:
	var tw := create_tween()
	tw.tween_property(_fade_rect, "color:a", a, seconds)
	if main != null and bool(main.get("xr_active")) and main.get("xr_camera") != null:
		if _fade_sphere == null:
			_fade_sphere = MeshInstance3D.new()
			var s := SphereMesh.new()
			s.radius = 0.3
			s.height = 0.6
			s.flip_faces = true
			_fade_sphere.mesh = s
			var m := StandardMaterial3D.new()
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.no_depth_test = true
			m.render_priority = 120
			m.albedo_color = Color(0, 0, 0, 0)
			_fade_sphere.material_override = m
			main.xr_camera.add_child(_fade_sphere)
		var tw2 := create_tween()
		tw2.tween_property(_fade_sphere.material_override, "albedo_color:a", a, seconds)
	await get_tree().create_timer(seconds).timeout


## Dormir jusqu'à l'heure dite (le lendemain si elle est déjà passée).
func sleep_until(target: float) -> void:
	if _sleeping:
		return
	_sleeping = true
	await _fade_to(1.0, 0.9)
	if target <= hour:
		day_count += 1
	hour = target
	apply()
	if main != null and main.has_method("_on_slept_v56"):
		main._on_slept_v56()
	await get_tree().create_timer(0.8).timeout
	await _fade_to(0.0, 1.1)
	_sleeping = false
