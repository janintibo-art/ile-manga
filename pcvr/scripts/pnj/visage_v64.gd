extends Node
## V64 : un visage vivant — les paupières clignent, la bouche bouge quand l'habitant parle
## (bulle affichée ou discussion avec le joueur), un léger sourire quand il est de bonne humeur.
## Il construit aussi les maillages du corps quand le joueur approche (un habitant par image,
## pour ne pas saccader) et les libère quand il s'éloigne.

const Corps64 = preload("res://scripts/pnj/corps_v64.gd")

var npc: Node3D
var parts: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _next_blink: float = 2.0
var _blink_t: float = -1.0
var _double: bool = false
var _t: float = 0.0
var _mouth: float = 0.0
var _smile: float = 0.0
var _last := Vector3(-1, -1, -1)
var _flux: float = 0.0
static var _build_frame: int = -1
const LOIN_SANS_VEILLE := 150.0     # habitants toujours éveillés (Barnabé, Octave, Lyra…)
const MARGE_CONSTRUIRE := 25.0
const MARGE_LIBERER := 60.0


func setup(owner_npc: Node3D, p: Dictionary) -> void:
	npc = owner_npc
	parts = p
	_rng.seed = hash(str(npc.name))
	_next_blink = _rng.randf_range(0.5, 4.0)
	_flux = _rng.randf_range(0.0, 0.2)


func _process(delta: float) -> void:
	if npc == null or parts.is_empty():
		return
	_stream(delta)
	var mdl: Node3D = npc.get("model")
	if mdl == null or not mdl.is_visible_in_tree():
		return
	# loin de la caméra : rien à animer
	var cam: Camera3D = get_viewport().get_camera_3d()
	if cam != null and cam.global_position.distance_to(npc.global_position) > 22.0:
		return
	_t += delta
	# clignement : 0,07 s pour fermer, 0,1 s pour rouvrir ; parfois deux de suite
	_next_blink -= delta
	if _next_blink <= 0.0 and _blink_t < 0.0:
		_blink_t = 0.0
		_double = _rng.randf() < 0.18
		_next_blink = _rng.randf_range(2.2, 6.0)
	var blink: float = 0.0
	if _blink_t >= 0.0:
		_blink_t += delta
		blink = clampf(_blink_t / 0.07, 0.0, 1.0) if _blink_t < 0.07 else clampf(1.0 - (_blink_t - 0.07) / 0.1, 0.0, 1.0)
		if _blink_t > 0.17:
			_blink_t = 0.0 if _double else -1.0
			_double = false
	# la bouche suit le débit de la parole (syllabes irrégulières)
	var bub: Label3D = npc.get("bubble")
	var talking: bool = str(npc.get("state")) == "parle" or (bub != null and bub.visible and bub.modulate.a > 0.5)
	var target: float = 0.0
	if talking:
		var syl: float = absf(sin(_t * 11.0) * 0.6 + sin(_t * 17.3 + 1.3) * 0.4)
		target = 0.05 + 0.2 * syl
	_mouth = lerpf(_mouth, target, clampf(delta * 18.0, 0.0, 1.0))
	# un peu de sourire selon l'humeur
	var smile_t: float = 0.0
	var br = npc.get("brain")
	if br != null and br.has_method("humeur_famille"):
		smile_t = 0.35 if str(br.humeur_famille()) == "joie" else 0.0
	_smile = lerpf(_smile, smile_t, clampf(delta * 2.0, 0.0, 1.0))
	var v := Vector3(blink, _mouth, _smile)
	if v.distance_to(_last) > 0.004:
		_last = v
		Corps64.set_expression(parts, "cligne", blink)
		Corps64.set_expression(parts, "bouche", _mouth)
		Corps64.set_expression(parts, "sourire", _smile)


## Maillages selon la distance au joueur : construits en deçà de la distance de veille
## (+ 25 m), libérés au-delà (+ 85 m). Un seul habitant construit par image.
func _stream(delta: float) -> void:
	var main: Node = npc.get("main")
	if main == null or not main.has_method("_player_pos_v27"):
		return
	_flux -= delta
	if _flux > 0.0:
		return
	_flux = 0.3 + _rng.randf() * 0.2
	var d: float = npc.global_position.distance_to(main._player_pos_v27())
	var sf: float = float(npc.get("sleep_far"))
	var r_in: float = (sf if sf > 0.0 else LOIN_SANS_VEILLE) + MARGE_CONSTRUIRE
	var built: bool = parts.has("peau")
	if not built and d < r_in:
		var f: int = Engine.get_process_frames()
		if _build_frame == f:
			_flux = 0.0          # un autre habitant s'est construit à cette image : au suivant
			return
		_build_frame = f
		npc.call("body64_build")
		_last = Vector3(-1, -1, -1)
	elif built and d > r_in + MARGE_LIBERER:
		npc.call("body64_free")
