extends Node3D
## V61 : les robots de Cliquetis, et Achille, l'homme volant.
## Des automates de cuivre et de laiton qui vaquent à leurs occupations :
##  - les balayeurs (une cloche sur roue, une brosse qui tourne devant) ;
##  - les porteurs (deux jambes, deux bras, une caisse sur le dos) ;
##  - le majordome du café (long cou, plateau, deux tasses) ;
##  - les drones de livraison (une sphère, quatre hélices, un petit colis) ;
##  - Boulon, le chien-robot de la foire ;
##  - le Colosse, l'automate géant qui patrouille sur la promenade des falaises.
## On peut leur parler (E) : ils répondent comme ils peuvent.
## Achille Plumevent tourne au-dessus de la cité avec ses ailes à vapeur ; parfois sa machine
## tousse, il plonge, et repart.

const LINES := {
	"balayeur": ["BIP. Surface propre à 97 %. Les 3 % restants, ce sont vos chaussures.", "Bzzz… Veuillez soulever les pieds. Merci. BIP.", "J'ai balayé 14 kilomètres aujourd'hui. Je n'ai trouvé qu'une pièce. Je l'ai gardée."],
	"porteur": ["CHARGE : 40 KILOS. DESTINATION : INCONNUE. MORAL : EXCELLENT.", "Je porte. Tu portes. Il porte. Je suis le seul à porter, en fait.", "Attention, je ne m'arrête pas. Mes freins sont en option."],
	"majordome": ["Monsieur désire un café ? Il est brûlant. Je le sais, je l'ai goûté avec mon doigt.", "Je sers depuis 1 247 jours sans renverser une tasse. Enfin, 1 246.", "Gaston dit que je suis le meilleur serveur de l'île. Je suis le seul robot serveur de l'île."],
	"drone": ["Livraison pour… erreur. Livraison pour personne. Bzz.", "Altitude : idéale. Colis : intact. Pigeon : agaçant.", "Ne pas toucher les hélices. Elles mordent."],
	"chien": ["OUAF. OUAF. (Ses yeux clignotent de bonheur.)", "Ouaf ? (Il vous tend une patte de laiton.)", "(Boulon remue sa queue en ressort, qui fait « boïng, boïng ».)"],
	"colosse": ["JE… SUIS… LE… COLOSSE. JE… PATROUILLE. LA… FALAISE… EST… SÛRE.", "BONJOUR… PETIT… HUMAIN. ATTENTION… À… MES… PIEDS.", "MAÎTRE RIVET… M'A… CONSTRUIT. IL… ÉTAIT… TRÈS… FIER."],
}

var main: Node
var robots: Array = []                 # {node, kind, path, i, speed, wait, parts, anim, inter}
var achille: Dictionary = {}
var _clock: float = 0.0
var _mats: Dictionary = {}
var _rng := RandomNumberGenerator.new()


func setup(main_node: Node) -> void:
	main = main_node
	_rng.seed = 6161


func _mat(key: String) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	match key:
		"cuivre":
			m.albedo_texture = load("res://assets/textures/cliquetis/cuivre.png")
			m.metallic = 0.6
			m.roughness = 0.4
		"laiton":
			m.albedo_texture = load("res://assets/textures/cliquetis/laiton.png")
			m.metallic = 0.85
			m.roughness = 0.3
		"acier":
			m.albedo_color = Color(0.58, 0.6, 0.62)
			m.metallic = 0.85
			m.roughness = 0.35
		"fer":
			m.albedo_color = Color(0.1, 0.1, 0.11)
			m.metallic = 0.6
			m.roughness = 0.5
		"oeil":
			m.albedo_color = Color(0.4, 0.9, 1.0)
			m.emission_enabled = true
			m.emission = Color(0.4, 0.9, 1.0)
			m.emission_energy_multiplier = 2.5
		"oeil_rouge":
			m.albedo_color = Color(1.0, 0.3, 0.2)
			m.emission_enabled = true
			m.emission = Color(1.0, 0.3, 0.2)
			m.emission_energy_multiplier = 2.5
		"brosse":
			m.albedo_color = Color(0.7, 0.55, 0.3)
			m.roughness = 1.0
		"bois":
			m.albedo_texture = load("res://assets/textures/doors/wood_plain.png")
		"porcelaine":
			m.albedo_color = Color(0.95, 0.95, 0.93)
			m.roughness = 0.2
		"toile":
			m.albedo_color = Color(0.86, 0.8, 0.66)
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
		"peau":
			m.albedo_color = Color(0.95, 0.78, 0.64)
		"veste":
			m.albedo_color = Color(0.36, 0.22, 0.14)
	_mats[key] = m
	return m


func _mi(parent: Node3D, mesh: Mesh, key: String, at: Vector3, rot: Vector3 = Vector3.ZERO, scl: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = _mat(key)
	mi.position = at
	mi.rotation = rot
	mi.scale = scl
	parent.add_child(mi)
	return mi


func _box(x: float, y: float, z: float) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = Vector3(x, y, z)
	return b


func _cyl(r0: float, r1: float, h: float, seg: int = 14) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = r1
	c.bottom_radius = r0
	c.height = h
	c.radial_segments = seg
	return c


func _sph(r: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = 14
	s.rings = 8
	return s


func _pivot(parent: Node3D, at: Vector3) -> Node3D:
	var p := Node3D.new()
	p.position = at
	parent.add_child(p)
	return p


# =================================================================== les modèles

func _make(kind: String) -> Dictionary:
	var n := Node3D.new()
	n.name = "Robot_" + kind
	var parts: Dictionary = {}
	match kind:
		"balayeur":
			_mi(n, _cyl(0.45, 0.3, 0.7), "cuivre", Vector3(0, 0.55, 0))
			_mi(n, _sph(0.3), "laiton", Vector3(0, 0.95, 0))
			_mi(n, _sph(0.06), "oeil", Vector3(0.12, 1.0, -0.26))
			_mi(n, _sph(0.06), "oeil", Vector3(-0.12, 1.0, -0.26))
			_mi(n, _cyl(0.22, 0.22, 0.12), "fer", Vector3(0, 0.2, 0), Vector3(0, 0, PI * 0.5))
			var brush := _pivot(n, Vector3(0, 0.15, -0.55))
			_mi(brush, _cyl(0.15, 0.15, 0.8), "brosse", Vector3.ZERO, Vector3(0, 0, PI * 0.5))
			_mi(n, _box(0.06, 0.06, 0.5), "acier", Vector3(0.3, 0.3, -0.3))
			_mi(n, _box(0.06, 0.06, 0.5), "acier", Vector3(-0.3, 0.3, -0.3))
			parts["brosse"] = brush
			_mi(n, _cyl(0.02, 0.02, 0.4), "acier", Vector3(0, 1.38, 0))
			_mi(n, _sph(0.05), "oeil_rouge", Vector3(0, 1.6, 0))
		"porteur":
			var body := _pivot(n, Vector3(0, 1.2, 0))
			_mi(body, _box(0.8, 0.9, 0.55), "cuivre", Vector3.ZERO)
			_mi(body, _box(0.5, 0.35, 0.4), "laiton", Vector3(0, 0.62, 0))
			_mi(body, _box(0.32, 0.08, 0.02), "oeil", Vector3(0, 0.64, -0.21))
			_mi(body, _box(0.7, 0.55, 0.6), "bois", Vector3(0, 0.25, 0.55))
			for s in [-1.0, 1.0]:
				var arm := _pivot(body, Vector3(s * 0.48, 0.3, 0))
				_mi(arm, _cyl(0.07, 0.06, 0.8, 8), "acier", Vector3(0, -0.4, 0))
				_mi(arm, _sph(0.1), "laiton", Vector3(0, -0.82, 0))
				parts["bras_%d" % int(s)] = arm
				var leg := _pivot(n, Vector3(s * 0.22, 0.78, 0))
				_mi(leg, _cyl(0.09, 0.08, 0.75, 8), "acier", Vector3(0, -0.38, 0))
				_mi(leg, _box(0.22, 0.08, 0.34), "fer", Vector3(0, -0.76, -0.06))
				parts["jambe_%d" % int(s)] = leg
			parts["corps"] = body
		"majordome":
			_mi(n, _sph(0.28), "fer", Vector3(0, 0.28, 0))
			_mi(n, _cyl(0.3, 0.2, 1.1), "cuivre", Vector3(0, 1.0, 0))
			_mi(n, _cyl(0.05, 0.05, 0.4, 8), "acier", Vector3(0, 1.7, 0))
			var head := _pivot(n, Vector3(0, 2.0, 0))
			_mi(head, _cyl(0.2, 0.2, 0.3), "laiton", Vector3.ZERO)
			_mi(head, _cyl(0.2, 0.23, 0.04), "fer", Vector3(0, 0.2, 0))
			_mi(head, _cyl(0.13, 0.13, 0.25), "fer", Vector3(0, 0.34, 0))
			_mi(head, _sph(0.05), "oeil", Vector3(0.08, 0.02, -0.19))
			_mi(head, _sph(0.05), "oeil", Vector3(-0.08, 0.02, -0.19))
			_mi(head, _box(0.12, 0.02, 0.02), "fer", Vector3(0, -0.08, -0.2))
			parts["tete"] = head
			var arm2 := _pivot(n, Vector3(0.32, 1.4, 0))
			_mi(arm2, _cyl(0.05, 0.05, 0.6, 8), "acier", Vector3(0, 0, -0.3), Vector3(PI * 0.5, 0, 0))
			_mi(arm2, _cyl(0.32, 0.32, 0.03, 18), "acier", Vector3(0, 0.05, -0.62))
			_mi(arm2, _cyl(0.05, 0.04, 0.09, 10), "porcelaine", Vector3(0.1, 0.12, -0.6))
			_mi(arm2, _cyl(0.05, 0.04, 0.09, 10), "porcelaine", Vector3(-0.08, 0.12, -0.68))
			parts["plateau"] = arm2
		"drone":
			var core := _pivot(n, Vector3(0, 0, 0))
			_mi(core, _sph(0.3), "cuivre", Vector3.ZERO)
			_mi(core, _sph(0.08), "oeil", Vector3(0, -0.05, -0.27))
			_mi(core, _box(0.3, 0.25, 0.3), "bois", Vector3(0, -0.42, 0))
			var props: Array = []
			for k in range(4):
				var a: float = TAU * k / 4.0 + PI * 0.25
				var off := Vector3(cos(a) * 0.55, 0.12, sin(a) * 0.55)
				_mi(core, _box(0.5, 0.04, 0.04), "acier", off * 0.5, Vector3(0, -a, 0))
				var pr := _pivot(core, off)
				_mi(pr, _box(0.42, 0.01, 0.06), "laiton", Vector3.ZERO)
				props.append(pr)
			parts["helices"] = props
			parts["corps"] = core
		"chien":
			var b2 := _pivot(n, Vector3(0, 0.5, 0))
			_mi(b2, _box(0.36, 0.3, 0.7), "cuivre", Vector3.ZERO)
			var hd := _pivot(b2, Vector3(0, 0.22, -0.42))
			_mi(hd, _box(0.3, 0.26, 0.32), "laiton", Vector3.ZERO)
			_mi(hd, _sph(0.05), "oeil", Vector3(0.08, 0.04, -0.17))
			_mi(hd, _sph(0.05), "oeil", Vector3(-0.08, 0.04, -0.17))
			for s2 in [-1.0, 1.0]:
				_mi(hd, _box(0.06, 0.2, 0.12), "fer", Vector3(s2 * 0.12, 0.2, 0.05), Vector3(0, 0, s2 * 0.3))
			parts["tete"] = hd
			var tail := _pivot(b2, Vector3(0, 0.12, 0.36))
			for k2 in range(5):
				_mi(tail, _cyl(0.04, 0.04, 0.03, 8), "acier", Vector3(0, k2 * 0.05, k2 * 0.03), Vector3(0.6, 0, 0))
			parts["queue"] = tail
			for lx in [-0.13, 0.13]:
				for lz in [-0.26, 0.26]:
					var lg := _pivot(b2, Vector3(lx, -0.12, lz))
					_mi(lg, _cyl(0.04, 0.035, 0.38, 8), "acier", Vector3(0, -0.19, 0))
					parts["patte_%d_%d" % [int(sign(lx)), int(sign(lz))]] = lg
			parts["corps"] = b2
		"colosse":
			var bc := _pivot(n, Vector3(0, 3.2, 0))
			_mi(bc, _cyl(0.8, 1.0, 1.8, 16), "cuivre", Vector3(0, 0.2, 0))
			_mi(bc, _sph(0.9), "cuivre", Vector3(0, 1.1, 0), Vector3.ZERO, Vector3(1, 0.6, 1))
			var hc := _pivot(bc, Vector3(0, 1.75, 0))
			_mi(hc, _box(0.7, 0.55, 0.6), "laiton", Vector3.ZERO)
			_mi(hc, _box(0.5, 0.12, 0.02), "oeil", Vector3(0, 0.05, -0.31))
			_mi(hc, _cyl(0.03, 0.03, 0.5, 6), "acier", Vector3(0.2, 0.5, 0))
			_mi(hc, _sph(0.07), "oeil_rouge", Vector3(0.2, 0.78, 0))
			parts["tete"] = hc
			_mi(bc, _cyl(0.25, 0.25, 1.4, 10), "fer", Vector3(-0.3, 1.6, 0.7))
			for s3 in [-1.0, 1.0]:
				var ac := _pivot(bc, Vector3(s3 * 1.15, 0.8, 0))
				_mi(ac, _sph(0.32), "laiton", Vector3.ZERO)
				_mi(ac, _cyl(0.18, 0.16, 1.6, 10), "acier", Vector3(0, -0.85, 0))
				_mi(ac, _box(0.4, 0.4, 0.4), "fer", Vector3(0, -1.75, 0))
				parts["bras_%d" % int(s3)] = ac
				var lc := _pivot(n, Vector3(s3 * 0.5, 2.3, 0))
				_mi(lc, _cyl(0.24, 0.2, 2.1, 10), "acier", Vector3(0, -1.05, 0))
				_mi(lc, _box(0.6, 0.25, 0.9), "fer", Vector3(0, -2.15, -0.15))
				parts["jambe_%d" % int(s3)] = lc
			parts["corps"] = bc
	add_child(n)
	return {"node": n, "parts": parts}


# =================================================================== la troupe

## Ajoute un robot qui suit en boucle une liste de points du monde (au sol, ou en l'air pour
## les drones). wait : pause à chaque point (secondes).
func add_robot(kind: String, path: Array, speed: float, wait: float = 0.0, label: String = "") -> Dictionary:
	var m: Dictionary = _make(kind)
	var r := {"node": m["node"], "parts": m["parts"], "kind": kind, "path": path, "i": 1 % path.size(), "speed": speed, "wait": wait, "pause": _rng.randf() * wait, "ph": _rng.randf() * TAU}
	(r["node"] as Node3D).position = path[0]
	robots.append(r)
	if main != null and main.get("donjon_v35") != null and main.donjon_v35 != null:
		var who: String = {"balayeur": "le robot balayeur", "porteur": "le robot porteur", "majordome": "le majordome mécanique", "drone": "le drone", "chien": "Boulon, le chien-robot", "colosse": "le Colosse"}.get(kind, "le robot")
		var it := {"id": "robot_%d" % robots.size(), "pos": path[0], "radius": 2.4 if kind != "colosse" else 4.0, "text": "E : parler à " + who + label, "vr": "Gâchette : parler à " + who,
			"call": func(): _talk(r)}
		if kind == "drone":
			it["radius"] = 0.0
		main.donjon_v35._interactions.append(it)
		r["inter"] = it
	return r


func _talk(r: Dictionary) -> void:
	var lines: Array = LINES.get(str(r["kind"]), ["BIP."])
	r["pause"] = 4.0
	if main.get("sfx_v50") != null:
		main.sfx_v50.play("bip", (r["node"] as Node3D).global_position)
	main.donjon_v35._say(str(lines[_rng.randi() % lines.size()]), 5.0)


func _process(delta: float) -> void:
	if main == null:
		return
	_clock += delta
	var p: Vector3 = main._player_pos_v27()
	for r in robots:
		var n: Node3D = r["node"]
		if n.global_position.distance_to(p) > 260.0:
			continue
		_tick(r, delta, p)
		if r.has("inter"):
			(r["inter"] as Dictionary)["pos"] = n.global_position
	if not achille.is_empty():
		_tick_achille(delta)


func _tick(r: Dictionary, delta: float, player: Vector3) -> void:
	var n: Node3D = r["node"]
	var kind: String = r["kind"]
	var parts: Dictionary = r["parts"]
	var t: float = _clock + float(r["ph"])
	var moving: bool = false
	if float(r["pause"]) > 0.0:
		r["pause"] = float(r["pause"]) - delta
		# on s'est arrêté pour parler : on regarde le joueur
		var tp: Vector3 = player - n.global_position
		tp.y = 0.0
		if tp.length() < 5.0 and tp.length() > 0.1:
			n.rotation.y = lerp_angle(n.rotation.y, atan2(-tp.x, -tp.z), delta * 3.0)
	else:
		var path: Array = r["path"]
		var tgt: Vector3 = path[int(r["i"])]
		var to: Vector3 = tgt - n.global_position
		var flat := Vector3(to.x, 0, to.z)
		# on ne marche pas sur le joueur
		var near_player: bool = kind != "drone" and Vector2(player.x - n.global_position.x, player.z - n.global_position.z).length() < (1.4 if kind != "colosse" else 3.0)
		if to.length() < 0.15:
			r["i"] = (int(r["i"]) + 1) % path.size()
			r["pause"] = float(r["wait"])
		elif not near_player:
			moving = true
			var step: Vector3 = to.normalized() * minf(float(r["speed"]) * delta, to.length())
			n.global_position += step
			if flat.length() > 0.05:
				n.rotation.y = lerp_angle(n.rotation.y, atan2(-flat.x, -flat.z), delta * 4.0)
	match kind:
		"balayeur":
			(parts["brosse"] as Node3D).rotation.x += delta * (12.0 if moving else 2.0)
		"porteur", "colosse":
			var sp: float = 6.0 if kind == "porteur" else 2.4
			var sw: float = sin(t * sp) * (0.45 if moving else 0.0)
			(parts["jambe_1"] as Node3D).rotation.x = sw
			(parts["jambe_-1"] as Node3D).rotation.x = -sw
			(parts["bras_1"] as Node3D).rotation.x = -sw * 0.6
			(parts["bras_-1"] as Node3D).rotation.x = sw * 0.6
			(parts["corps"] as Node3D).position.y = (1.2 if kind == "porteur" else 3.2) + absf(sin(t * sp)) * (0.05 if moving else 0.0)
			if kind == "colosse":
				(parts["tete"] as Node3D).rotation.y = sin(t * 0.3) * 0.6
		"majordome":
			(parts["tete"] as Node3D).rotation.y = sin(t * 0.7) * 0.4
			(parts["plateau"] as Node3D).rotation.z = sin(t * 2.0) * 0.03
			n.rotation.z = sin(t * 3.0) * (0.04 if moving else 0.0)
		"drone":
			for pr in parts["helices"]:
				(pr as Node3D).rotation.y += delta * 40.0
			(parts["corps"] as Node3D).position.y = sin(t * 1.3) * 0.15
			(parts["corps"] as Node3D).rotation.z = sin(t * 0.9) * 0.08
		"chien":
			(parts["queue"] as Node3D).rotation.y = sin(t * 14.0) * 0.6
			(parts["tete"] as Node3D).rotation.x = sin(t * 1.3) * 0.2
			var sw2: float = sin(t * 10.0) * (0.5 if moving else 0.0)
			(parts["patte_1_1"] as Node3D).rotation.x = sw2
			(parts["patte_-1_-1"] as Node3D).rotation.x = sw2
			(parts["patte_1_-1"] as Node3D).rotation.x = -sw2
			(parts["patte_-1_1"] as Node3D).rotation.x = -sw2


# =================================================================== Achille, l'homme volant

## Achille tourne en huit au-dessus de la cité (centre c, rayons rx, rz, à l'altitude y).
func add_achille(c: Vector3, rx: float, rz: float, y: float) -> void:
	var n := Node3D.new()
	n.name = "Achille_homme_volant"
	add_child(n)
	# le pilote, allongé, casque de cuir et lunettes
	_mi(n, _cyl(0.24, 0.22, 1.2, 10), "veste", Vector3(0, 0, 0.1), Vector3(PI * 0.5, 0, 0))
	_mi(n, _sph(0.2), "peau", Vector3(0, 0.1, -0.62))
	_mi(n, _sph(0.21), "veste", Vector3(0, 0.18, -0.6), Vector3.ZERO, Vector3(1, 0.6, 1))
	_mi(n, _box(0.32, 0.08, 0.06), "laiton", Vector3(0, 0.13, -0.8))
	for s in [-1.0, 1.0]:
		_mi(n, _cyl(0.08, 0.07, 0.8, 8), "veste", Vector3(s * 0.16, -0.1, 0.95), Vector3(PI * 0.5, 0, 0))
	# la chaudière dorsale et sa cheminée
	_mi(n, _cyl(0.22, 0.22, 0.7, 12), "cuivre", Vector3(0, 0.32, 0.15), Vector3(PI * 0.5, 0, 0))
	_mi(n, _cyl(0.06, 0.06, 0.4, 8), "fer", Vector3(0, 0.6, 0.38))
	# les ailes de toile sur des baleines de laiton
	var wings: Array = []
	for s2 in [-1.0, 1.0]:
		var w := _pivot(n, Vector3(s2 * 0.25, 0.3, 0.0))
		var q := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(2.8, 1.2)
		q.mesh = qm
		q.material_override = _mat("toile")
		q.position = Vector3(s2 * 1.4, 0, 0.1)
		q.rotation.x = -PI * 0.5
		w.add_child(q)
		for k in range(4):
			_mi(w, _box(0.03, 0.03, 1.2), "laiton", Vector3(s2 * (0.3 + k * 0.8), 0.01, 0.1))
		wings.append(w)
	var prop := _pivot(n, Vector3(0, 0.32, 0.6))
	_mi(prop, _box(1.2, 0.08, 0.04), "bois", Vector3.ZERO)
	var puff := CPUParticles3D.new()
	puff.amount = 24
	puff.lifetime = 2.5
	puff.local_coords = false
	puff.direction = Vector3(0, 1, 0)
	puff.spread = 20.0
	puff.initial_velocity_min = 0.3
	puff.initial_velocity_max = 0.8
	puff.gravity = Vector3(0, 0.2, 0)
	puff.scale_amount_min = 0.4
	puff.scale_amount_max = 1.2
	var sm := SphereMesh.new()
	sm.radius = 0.25
	sm.height = 0.5
	var pm := StandardMaterial3D.new()
	pm.albedo_color = Color(0.9, 0.9, 0.9, 0.35)
	pm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.material = pm
	puff.mesh = sm
	puff.position = Vector3(0, 0.82, 0.38)
	n.add_child(puff)
	achille = {"node": n, "wings": wings, "prop": prop, "puff": puff, "c": c, "rx": rx, "rz": rz, "y": y, "a": 0.0, "cough": 0.0, "dip": 0.0}


func _tick_achille(delta: float) -> void:
	var a: Dictionary = achille
	var n: Node3D = a["node"]
	a["a"] = float(a["a"]) + delta * 0.16
	var th: float = float(a["a"])
	# la toux du moteur : de temps en temps, il plonge de quelques mètres puis remonte
	if float(a["cough"]) <= 0.0 and _rng.randf() < delta * 0.025:
		a["cough"] = 3.0
		if main.get("sfx_v50") != null:
			main.sfx_v50.play("vapeur", n.global_position)
	if float(a["cough"]) > 0.0:
		a["cough"] = float(a["cough"]) - delta
		a["dip"] = move_toward(float(a["dip"]), 7.0, delta * 6.0)
	else:
		a["dip"] = move_toward(float(a["dip"]), 0.0, delta * 2.0)
	var c: Vector3 = a["c"]
	var pos := Vector3(c.x + sin(th) * float(a["rx"]), float(a["y"]) + sin(th * 3.0) * 3.0 - float(a["dip"]), c.z + sin(th * 2.0) * float(a["rz"]))
	var nxt := Vector3(c.x + sin(th + 0.02) * float(a["rx"]), pos.y, c.z + sin((th + 0.02) * 2.0) * float(a["rz"]))
	n.global_position = pos
	n.look_at(nxt, Vector3.UP)
	n.rotation.z = -cos(th * 2.0) * 0.35
	var flap: float = sin(_clock * (5.0 if float(a["cough"]) <= 0.0 else 11.0)) * 0.35
	(a["wings"][0] as Node3D).rotation.z = flap
	(a["wings"][1] as Node3D).rotation.z = -flap
	(a["prop"] as Node3D).rotation.z += delta * (30.0 if float(a["cough"]) <= 0.0 else 6.0)
