extends Node
## V52 : la lumière sous les grands arbres.
## Au cœur de la jungle, la canopée arrêtait presque tout : on n'y voyait plus rien.
## Comme l'œil qui s'habitue à la pénombre, on augmente progressivement (2 s) :
##  - l'exposition et la lumière ambiante du ciel,
##  - la lumière rebondie (SDFGI, sur PC),
## on adoucit l'occlusion ambiante, et une lumière douce et verte, sans ombres, tombe de
## la canopée (la lumière du ciel filtrée par les feuilles).
## Dans les souterrains, c'est le temple qui règle l'éclairage : on n'y touche pas.

const ADAPT_TIME: float = 2.0

var main: Node
var env: Environment
var base: Dictionary = {}
var fill: DirectionalLight3D
var k: float = 0.0                  # 0 : à découvert, 1 : au cœur de la forêt
var target: float = 0.0
var _written: float = -1.0


func setup(main_node: Node) -> void:
	main = main_node
	for c in main.get_children():
		if c is WorldEnvironment:
			env = (c as WorldEnvironment).environment
	if env == null:
		return
	base = {"exp": env.tonemap_exposure, "amb": env.ambient_light_energy, "sdfgi": env.sdfgi_energy, "ssao": env.ssao_intensity}
	fill = DirectionalLight3D.new()
	fill.name = "Lumiere_sous_bois_v52"
	fill.rotation_degrees = Vector3(-72, -35, 0)
	fill.light_color = Color(0.82, 0.95, 0.78)
	fill.light_energy = 0.0
	fill.shadow_enabled = false
	fill.light_specular = 0.15
	fill.light_volumetric_fog_energy = 0.4
	fill.sky_mode = DirectionalLight3D.SKY_MODE_LIGHT_ONLY
	fill.visible = false
	main.add_child.call_deferred(fill)


## Pénombre sous les arbres (0..1) au point p : feuillage au-dessus (moyenne sur ~12 m,
## l'œil ne s'adapte pas à chaque arbre), et seulement à l'intérieur des forêts.
func forest_depth(p: Vector3) -> float:
	var j: Node = main.get("jungle_v29")
	if j != null and j.contains(p.x, p.z):
		return _shade(main.get("flora_v30"), p, 1.0)
	var el: Node = main.get("elfes_v41")
	if el != null and el.ile != null and el.ile.contains(p.x, p.z):
		return _shade(el.flora, p, 0.7)
	return 0.0


func _shade(flora: Node, p: Vector3, strength: float) -> float:
	if flora == null or not flora.has_method("canopy_at"):
		return 0.0
	var sum: float = 0.0
	for o in [Vector2.ZERO, Vector2(6, 0), Vector2(-6, 0), Vector2(0, 6), Vector2(0, -6)]:
		sum += float(flora.canopy_at(p.x + o.x, p.z + o.y))
	return strength * smoothstep(0.35, 1.3, sum / 5.0)


func _process(delta: float) -> void:
	if env == null or main == null:
		return
	var d: Node = main.get("donjon_v35")
	if d != null and bool(d.inside):
		return          # sous terre : le temple règle la lumière
	target = forest_depth(main._player_pos_v27()) if bool(main.game_started) else 0.0
	k = move_toward(k, target, delta / ADAPT_TIME)
	if absf(k - _written) < 0.002:
		return
	_written = k
	env.tonemap_exposure = float(base["exp"]) * (1.0 + 0.45 * k)
	env.ambient_light_energy = float(base["amb"]) * (1.0 + 1.6 * k)
	if env.sdfgi_enabled:
		env.sdfgi_energy = float(base["sdfgi"]) * (1.0 + 0.8 * k)
	env.ssao_intensity = float(base["ssao"]) * (1.0 - 0.4 * k)
	if fill != null:
		fill.light_energy = 0.55 * k
		fill.visible = k > 0.01
