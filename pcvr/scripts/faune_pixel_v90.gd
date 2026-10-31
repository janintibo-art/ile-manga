extends Node3D
## V90 : les bêtes paisibles de l'Île Pixelithique (on ne les combat pas) : trois Long-Cous
## (des brachiosaures de seize mètres) qui marchent lentement autour du Lac des Long-Cous, broutent
## la cime des araucarias et se rappellent d'un long cri ; des Grand-Becs (ptéranodons) qui planent
## en rond dans l'air chaud au-dessus du Mont Fumant ; et, une fois vaincu, Grosse-Dent qui dort
## dans son cirque (il ronfle).

const Vox = preload("res://scripts/vox_v90.gd")
const IleScript = preload("res://scripts/ile_pixel_v90.gd")

var main: Node
var pixel: Node
var longcous: Array = []                 # {"root", "parts", "a" (angle sur le tour), "r", "v", "brout"}
var becs: Array = []                     # {"root", "parts", "a", "r", "h", "v"}
var _t: float = 0.0
var _cri_t: float = 20.0


func setup(main_node: Node, pixel_node: Node) -> void:
	main = main_node
	pixel = pixel_node
	name = "Faune_pixel_v90"
	var lc: Array = IleScript.LAC
	for i in range(3):
		var root := Node3D.new()
		root.name = "Long_Cou_%d" % i
		add_child(root)
		var parts: Dictionary = Vox.rig(root, "brachiosaure")
		var s: float = [1.0, 0.85, 0.62][i]
		root.scale = Vector3.ONE * s
		longcous.append({"root": root, "parts": parts, "a": TAU * i / 3.0, "r": float(lc[2]) + 13.0 + i * 5.0, "v": 0.012 + i * 0.002,
			"brout": 0.0, "s": s})
	var v: Array = IleScript.VOLCAN
	for k in range(6):
		var r2 := Node3D.new()
		r2.name = "Grand_Bec_%d" % k
		add_child(r2)
		var p2: Dictionary = Vox.rig(r2, "pteranodon")
		r2.scale = Vector3.ONE * 1.2
		becs.append({"root": r2, "parts": p2, "a": TAU * k / 6.0, "r": 26.0 + (k % 3) * 9.0, "h": float(v[3]) + 22.0 + (k % 2) * 8.0,
			"v": 0.25 + (k % 3) * 0.05})


## Grosse-Dent endormi (couché sur le flanc, il ronfle) : une fois vaincu, il reste dans son cirque.
static func trex_endormi(parent: Node3D, at: Vector3) -> Node3D:
	var root := Node3D.new()
	root.name = "Grosse_Dent_dort"
	parent.add_child(root)
	var parts: Dictionary = Vox.rig(root, "trex")
	root.global_position = at + Vector3.UP * 1.2
	root.rotation = Vector3(0, 0.8, 1.35)
	for k in ["cuisseG", "cuisseD"]:
		if parts.has(k):
			(parts[k] as Node3D).rotation.x = -0.5
	if parts.has("machoire"):
		(parts["machoire"] as Node3D).rotation.x = 0.12
	var z := Label3D.new()
	z.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	z.text = "Z z z…"
	z.font_size = 96
	z.pixel_size = 0.01
	z.outline_size = 18
	z.modulate = Color(0.9, 0.95, 1.0)
	parent.add_child(z)
	z.global_position = at + Vector3(0, 5.5, 0)
	z.set_meta("zzz", true)
	root.set_meta("zzz", z)
	root.set_meta("parts", parts)
	root.tree_exiting.connect(func(): if is_instance_valid(z): z.queue_free())
	return root


func _process(delta: float) -> void:
	_t += delta
	if main == null or pixel == null or pixel.ile == null:
		return
	var p: Vector3 = main._player_pos_v27()
	var near: bool = pixel.ile.contains(p.x, p.z) or p.distance_to(IleScript.CENTER) < 420.0
	if not near:
		return
	var lc: Array = IleScript.LAC
	for e in longcous:
		var root: Node3D = e["root"]
		var parts: Dictionary = e["parts"]
		var a: float = float(e["a"])
		var brout: float = float(e["brout"])
		if brout > 0.0:
			e["brout"] = brout - delta
		else:
			e["a"] = a + float(e["v"]) * delta
			if randf() < delta * 0.02:
				e["brout"] = randf_range(6.0, 12.0)
		var r: float = float(e["r"])
		var x: float = float(lc[0]) + cos(a) * r
		var z: float = float(lc[1]) + sin(a) * r * 0.85
		var w: Vector3 = IleScript.W(x, z)
		w.y = maxf(pixel.ile.height(w.x, w.z), float(lc[3]) - 0.6)
		root.global_position = w
		var tang := Vector3(-sin(a), 0, cos(a) * 0.85).normalized()
		root.rotation.y = atan2(tang.x, tang.z)
		var walk: float = 0.0 if brout > 0.0 else 1.0
		var ph: float = _t * 1.6
		for k in ["patteavG", "pattearD"]:
			if parts.has(k):
				(parts[k] as Node3D).rotation.x = sin(ph) * 0.22 * walk
		for k2 in ["patteavD", "pattearG"]:
			if parts.has(k2):
				(parts[k2] as Node3D).rotation.x = -sin(ph) * 0.22 * walk
		if parts.has("cou"):
			(parts["cou"] as Node3D).rotation = Vector3(sin(_t * 0.4 + a) * 0.08 + (0.25 if brout > 0.0 else 0.0), sin(_t * 0.3 + a * 2.0) * 0.15, 0)
		if parts.has("tete"):
			(parts["tete"] as Node3D).rotation.x = (0.4 + sin(_t * 3.0) * 0.12) if brout > 0.0 else sin(_t * 0.7) * 0.05
		if parts.has("queue"):
			(parts["queue"] as Node3D).rotation.y = sin(_t * 0.9 + a) * 0.18
		if parts.has("queue2"):
			(parts["queue2"] as Node3D).rotation.y = sin(_t * 0.9 + a - 0.6) * 0.25
	# un long cri, de temps en temps (on l'entend de loin)
	_cri_t -= delta
	if _cri_t <= 0.0 and not longcous.is_empty():
		_cri_t = randf_range(25.0, 50.0)
		var e2: Dictionary = longcous[randi() % longcous.size()]
		if main.has_method("sfx") and p.distance_to((e2["root"] as Node3D).global_position) < 160.0:
			main.sfx("longcou_cri", (e2["root"] as Node3D).global_position + Vector3.UP * 14.0)
	var v: Array = IleScript.VOLCAN
	for b in becs:
		var a2: float = float(b["a"]) + float(b["v"]) * delta * 0.4
		b["a"] = a2
		var c: Vector3 = IleScript.W(float(v[0]) + cos(a2) * float(b["r"]), float(v[1]) + sin(a2) * float(b["r"]), float(b["h"]) + sin(_t * 0.5 + a2) * 3.0)
		var root2: Node3D = b["root"]
		root2.global_position = c
		var tg := Vector3(-sin(a2), 0, cos(a2))
		root2.rotation = Vector3(0, atan2(tg.x, tg.z), -0.35)
		var pp: Dictionary = b["parts"]
		var flap: float = sin(_t * 2.2 + a2 * 3.0) * 0.25 * (0.3 + 0.7 * maxf(0.0, sin(_t * 0.3 + a2)))
		if pp.has("aileG"):
			(pp["aileG"] as Node3D).rotation.z = flap
		if pp.has("aileD"):
			(pp["aileD"] as Node3D).rotation.z = -flap
		if pp.has("boutG"):
			(pp["boutG"] as Node3D).rotation.z = flap * 0.6
		if pp.has("boutD"):
			(pp["boutD"] as Node3D).rotation.z = -flap * 0.6
	# Grosse-Dent ronfle
	var dodo: Node3D = pixel.get("dodo")
	if dodo != null and is_instance_valid(dodo):
		var parts3: Dictionary = dodo.get_meta("parts", {})
		var br: float = 0.5 + 0.5 * sin(_t * 0.9)
		if parts3.has("corps"):
			(parts3["corps"] as Node3D).scale = Vector3(1.0 + br * 0.04, 1.0 + br * 0.05, 1.0)
		if parts3.has("machoire"):
			(parts3["machoire"] as Node3D).rotation.x = 0.08 + br * 0.08
		var zl: Node3D = dodo.get_meta("zzz")
		if zl != null and is_instance_valid(zl):
			(zl as Label3D).modulate.a = 0.4 + br * 0.6
		if fmod(_t, 4.0) < delta and main.has_method("sfx") and p.distance_to(dodo.global_position) < 40.0:
			main.sfx("trex_ronfle", dodo.global_position)
