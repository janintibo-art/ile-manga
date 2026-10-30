extends Node3D
## V87 : l'Île aux Moaïs — le chef d'orchestre. Il construit l'île (ile_moai_v87 : le triangle
## et ses trois volcans, la Plage Blanche, le Plateau des Anciens), y dresse les Moaïs
## (moai_statue_v87) : le Grand Moaï au milieu du plateau, la ronde des Moaïs habités autour de
## lui (une porte ronde dans le ventre de pierre : derrière, les petits Moaïs, farceurs, qui
## répondent quand on frappe), les rangées sur leurs ahu (l'Ahu du Couchant, l'Ahu du Levant,
## l'Ahu de la Plage), le Gardien du Lac sur le bord du cratère, les têtes à moitié enterrées de
## la Butte de la Carrière, le Moaï tombé ; il plante la végétation (moai_flore_v87), tient les
## lanternes la nuit, les messages de découverte, les lieux pour le carnet, la téléportation et
## la sauvegarde.
## (V88 : on entre chez les petits Moaïs ; V89 : la grande porte s'ouvre sur l'escalier et le
## souterrain.)

const IleScript = preload("res://scripts/ile_moai_v87.gd")
const Statue = preload("res://scripts/moai_statue_v87.gd")
const FLORE := "res://scripts/moai_flore_v87.gd"
const Kit = preload("res://scripts/azur_kit_v56.gd")
const Moais = preload("res://scripts/maisons_moai_v88.gd")

## La ronde des Moaïs habités autour du Plateau des Anciens : [angle (degrés ; 0 = est, 90 = sud),
## rayon, hauteur, variante, chignon]. Le sud (le chemin de la plage) reste libre.
const VILLAGE := [[130.0, 27.0, 9.0, 0, false], [165.0, 26.0, 8.5, 1, true], [200.0, 27.0, 9.5, 0, false],
	[235.0, 26.5, 8.0, 2, false], [270.0, 27.5, 10.0, 1, true], [305.0, 26.5, 8.5, 0, false],
	[340.0, 27.0, 9.0, 2, true], [15.0, 26.0, 8.5, 1, false], [50.0, 27.0, 9.5, 0, false]]
## Les ahu : [centre x, z (repère île), vers où regardent les Moaïs (x, z), nombre, hauteur, chignons]
const AHUS := {
	"ahu_couchant": [-118.0, -12.0, Vector2(1.0, 0.1), 5, 7.5, [1, 3]],
	"ahu_levant": [86.0, -22.0, Vector2(-1.0, 0.2), 7, 8.0, [0, 2, 4, 6]],
	"ahu_plage": [-34.0, 96.0, Vector2(0.15, -1.0), 3, 7.0, [0, 1, 2]],
}
## Les têtes à moitié enterrées de la Butte de la Carrière : [x, z, hauteur, angle (degrés), penché]
const TETES := [[78.0, 64.0, 10.0, 200.0, 6.0], [84.0, 74.0, 9.0, 230.0, -8.0], [92.0, 66.0, 11.0, 190.0, 4.0],
	[98.0, 76.0, 9.5, 250.0, 10.0], [72.0, 74.0, 8.5, 215.0, -5.0], [90.0, 58.0, 10.5, 180.0, 0.0], [104.0, 68.0, 9.0, 235.0, -10.0]]

const PLACES := {"plage": "la Plage Blanche", "plateau": "le Plateau des Anciens", "lac": "le Cratère du Lac",
	"venteux": "le Mont Venteux", "carriere": "la Butte de la Carrière", "ahu_couchant": "l'Ahu du Couchant",
	"ahu_levant": "l'Ahu du Levant", "ahu_plage": "l'Ahu de la Plage", "prairie": "la prairie"}

## Ce que répondent les petits Moaïs quand on frappe (V88 : on pourra entrer).
const TOC := [
	["Qui est là ? … Un visiteur ! Désolé, je ne peux pas ouvrir : je suis en pierre, ça prend du temps de se lever. Repasse dans cent ans !"],
	["C'est qui ?", "Tu sais pourquoi les Moaïs ne jouent jamais à cache-cache ? … Parce qu'on les trouve tout de suite ! Hi hi hi !"],
	["Toc toc toc ? Hé, c'est MOI qui fais les blagues, ici !", "Bon, d'accord : qu'est-ce qui est gris, très grand, et qui ne bouge pas ? … Moi quand je dors. Et moi quand je suis réveillé. Hi hi !"],
	["Il n'y a personne !", "… Ah, zut. J'ai répondu."],
	["Entrez ! … Ah non, c'est fermé à clé.", "Et la clé, c'est un caillou. Comme tous les cailloux de l'île. Bonne chance ! Hi hi !"],
	["Chuuut ! Je fais la sieste.", "Ça fait huit cents ans que je fais la sieste. C'est une très, très grosse sieste."],
	["Qu'est-ce qu'un Moaï dit à un autre Moaï ?", "… Rien. On est en pierre : on parle très, très lentement. Reviens demain pour la fin de la phrase."],
	["Tu as vu le Grand Moaï, au milieu ? Il a un escalier dans le ventre !", "Moi, je n'ai que des papillons. … Des papillons de pierre. Ils ne volent pas très bien."],
	["Toc toc ! … Ah non, c'est toi qui frappes. On recommence ?", "Qui est là ? … Ha ! Je le savais. C'est toujours toi."],
	["Pourquoi le Grand Moaï ne dit jamais rien ?", "Parce qu'il a la bouche pleine ! … De pierre. Hi hi ! (On ne lui répète pas, d'accord ?)"],
]

var main: Node
var ile: Node3D
var flore: Node3D
var pc: bool = true
var state: Dictionary = {}
var objets: Dictionary = {}               # lieux pour le carnet (nom -> Vector3 monde)
var maisons: Array = []                   # {"node", "door" (monde), "out", "nom"}
var grand: Node3D
var moais: Array = []
var promeneurs: Array = []                # V88 : les petits Moaïs qui se promènent sur le plateau
var _clock: float = 0.0
var _zone_t: float = 0.0
var _registered: bool = false
var _rng := RandomNumberGenerator.new()


func setup(main_node: Node) -> void:
	main = main_node
	pc = OS.has_feature("ile_manga_pc")
	_rng.seed = 8790
	state = _fresh_state()


func _fresh_state() -> Dictionary:
	return {"visite": false, "visites": {}, "toc": 0, "grande_porte": false, "legende": false}


# =================================================================== construction

func build_island() -> void:
	ile = IleScript.new()
	ile.name = "Ile_moai_v87"
	add_child(ile)
	ile.build(pc)


func dock() -> Array:
	return [IleScript.W(IleScript.DOCK_A.x, IleScript.DOCK_A.y), IleScript.W(IleScript.DOCK_B.x, IleScript.DOCK_B.y)]


## Après le relief et l'heure du jour : les Moaïs, la végétation.
func build_town() -> void:
	var t0: int = Time.get_ticks_msec()
	var avoid: Array = []
	# --- le Grand Moaï, au milieu du Plateau des Anciens, qui regarde la mer du sud
	var pc0: Vector3 = _ground(0.0, -4.0)
	grand = Statue.make(self, pc0, Vector3(0, 0, 1), {"h": 30.0, "v": 1, "pukao": true, "nom": "Grand_Moai"})
	_grand_door(grand)
	avoid.append([Vector2(pc0.x, pc0.z), 14.0])
	objets["grand_moai"] = pc0 + Vector3(0, 0, 8.0)
	# --- la ronde des Moaïs habités
	for i in range(VILLAGE.size()):
		var e: Array = VILLAGE[i]
		var a: float = deg_to_rad(float(e[0]))
		var l := Vector2(cos(a), sin(a)) * float(e[1])
		var at: Vector3 = _ground(l.x, l.y)
		var face: Vector3 = Vector3(-l.x, 0, -l.y).normalized()
		var m: Node3D = Statue.make(self, at, face, {"h": float(e[2]), "v": int(e[3]), "pukao": bool(e[4]), "porte": true,
			"nom": "Moai_habite_%d" % i, "bois": [Color(0.72, 0.52, 0.32), Color(0.55, 0.35, 0.22), Color(0.78, 0.6, 0.38)][i % 3]})
		moais.append(m)
		var door: Vector3 = m.global_transform * (m.get_meta("porte") as Vector3)
		door.y = ile.height(door.x, door.z) + 0.05
		maisons.append({"node": m, "door": door, "out": face, "nom": "Moai_%d" % i})
		# V88 : on entre chez les petits Moaïs (maisons_v81) ; chaque porte a son histoire
		Kit.PORTES_V81.append({"door": door, "out": face, "w": 7.0, "d": 6.4, "style": "moai", "floors": 1, "owner": "",
			"histoire": str(Moais.HISTOIRES[i % Moais.HISTOIRES.size()])})
		avoid.append([Vector2(at.x, at.z), 6.0])
	# --- les ahu et leurs rangées
	for k in AHUS:
		_ahu(str(k), AHUS[k], avoid)
	# --- le Gardien du Lac, sur le bord du cratère, qui regarde l'eau
	var lv: Array = IleScript.VOLCANS["lac"]
	var gp: Vector3 = _ground(-96.0, 24.0)
	moais.append(Statue.make(self, gp, Vector3(0, 0, 1), {"h": 7.0, "v": 2, "yeux": true, "nom": "Gardien_du_lac"}))
	avoid.append([Vector2(gp.x, gp.z), 6.0])
	objets["lac"] = IleScript.W(float(lv[0]), float(lv[1]), IleScript.LAC_Y)
	# --- les têtes de la Butte de la Carrière
	for t in TETES:
		var tp: Vector3 = _ground(float(t[0]), float(t[1]))
		var hd: Node3D = Statue.make(self, tp, Vector3(sin(deg_to_rad(float(t[3]))), 0, cos(deg_to_rad(float(t[3])))), {"h": float(t[2]), "v": 2, "enfoui": float(t[2]) * 0.52, "nom": "Tete"})
		hd.rotate_object_local(Vector3.RIGHT, deg_to_rad(float(t[4])))
		moais.append(hd)
		avoid.append([Vector2(tp.x, tp.z), 5.0])
	objets["carriere"] = _ground(86.0, 70.0)
	# --- le Moaï tombé, face contre terre, près de l'Ahu du Couchant
	var fp: Vector3 = _ground(-100.0, -34.0)
	var fallen: Node3D = Statue.make(self, fp, Vector3(0.8, 0, -0.6), {"h": 8.0, "v": 2, "nom": "Moai_tombe"})
	fallen.rotate_object_local(Vector3.RIGHT, PI * 0.5)
	fallen.global_position += Vector3.UP * 0.9
	moais.append(fallen)
	avoid.append([Vector2(fp.x, fp.z), 9.0])
	# --- la végétation
	if ResourceLoader.exists(FLORE):
		flore = load(FLORE).new()
		flore.name = "Flore_moai_v87"
		add_child(flore)
		for a2 in avoid:
			flore.avoid.append(a2)
		flore.build_moai(ile, pc)
	_promeneurs()
	objets["plage"] = _ground(8.0, 92.0)
	objets["venteux"] = _ground(0.0, -112.0)
	print("ILE_MANGA_V87: l'Île aux Moaïs est prête (%d Moaïs, %d ms)" % [moais.size() + 1, Time.get_ticks_msec() - t0])


func _ground(x: float, z: float) -> Vector3:
	var w: Vector3 = IleScript.W(x, z)
	w.y = ile.height(w.x, w.z)
	return w


## V88 : quatre petits Moaïs se promènent sur le Plateau des Anciens, entre le Grand Moaï et la
## ronde ; ils sautillent, s'arrêtent, racontent des blagues à qui veut les entendre.
func _promeneurs() -> void:
	var Mini = load("res://scripts/pnj/mini_moai_v88.gd")
	var noms: Array = ["Gravillon", "Pépite", "Silex", "Ponce"]
	for i in range(4):
		var a: float = TAU * (float(i) + 0.3) / 4.0
		var at: Vector3 = _ground(cos(a) * 15.0, sin(a) * 15.0)
		var m: Node3D = Mini.spawn(self, main, str(noms[i]), at, Vector3(-cos(a), 0, -sin(a)), "debout", {"parure": ["fleurs", "lunettes", "chignon", "coquillages"][i]})
		m.lines = []
		for t in TOC:
			m.lines.append(str(t[0]))
		m.line_every = Vector2(9.0, 18.0)
		promeneurs.append({"m": m, "cible": at, "pause": _rng.randf_range(1.0, 4.0)})


func _promeneurs_tick(delta: float) -> void:
	for e in promeneurs:
		var m: Node3D = e["m"]
		if not is_instance_valid(m) or bool(m.get("talking")):
			continue
		var p: Vector3 = m.global_position
		var c: Vector3 = e["cible"]
		var to: Vector3 = c - p
		to.y = 0.0
		if to.length() < 0.3:
			e["pause"] = float(e["pause"]) - delta
			if float(e["pause"]) <= 0.0:
				var a: float = _rng.randf() * TAU
				e["cible"] = _ground(cos(a) * _rng.randf_range(11.0, 20.0), sin(a) * _rng.randf_range(11.0, 20.0))
				e["pause"] = _rng.randf_range(2.0, 6.0)
			continue
		var step: Vector3 = to.normalized() * minf(to.length(), delta * 0.9)
		var np: Vector3 = p + step
		np.y = ile.height(np.x, np.z)
		m.global_position = np
		m.face_dir = to.normalized()
		if e.has("it"):
			e["it"]["pos"] = np


## Parler à un petit Moaï du plateau : une blague, toujours une autre.
func _talk_promeneur(i: int) -> void:
	var m: Node3D = promeneurs[i]["m"]
	var n: int = int(state.get("toc", 0))
	var b: Array = Moais.BLAGUES[(n + i * 2) % Moais.BLAGUES.size()]
	state["toc"] = n + 1
	m.begin_talk()
	main.ask_v69(m, str(m.display_name), "farceur", str(b[0]) + " … " + str(b[1]), [{"id": "encore", "label": "Ha ha ! Une autre !"}, {"id": "fermer", "label": "Au revoir !"}], func(id):
		m.gesture("rire", 2.0)
		if id == "encore":
			_talk_promeneur(i)
		else:
			main._close_dialogue_v31()
			m.end_talk())


## Un ahu : la plateforme de grosses pierres ajustées, sa rampe de galets devant, et ses Moaïs
## debout, le dos à la mer, qui regardent l'intérieur de l'île.
func _ahu(id: String, e: Array, avoid: Array) -> void:
	var c: Vector3 = _ground(float(e[0]), float(e[1]))
	var f2: Vector2 = (e[2] as Vector2).normalized()
	var face := Vector3(f2.x, 0, f2.y)
	var side: Vector3 = face.cross(Vector3.UP).normalized()
	var n: int = int(e[3])
	var h: float = float(e[4])
	var gap: float = h * 0.46
	var length: float = n * gap + 2.4
	var root := Node3D.new()
	root.name = "Ahu_" + id
	add_child(root)
	root.global_transform = Transform3D(Basis(side, Vector3.UP, -face), c)
	var stone: Material = Statue.stone_mat("ahu")
	var plat := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(length, 1.6, 4.2)
	plat.mesh = bm
	plat.material_override = stone
	root.add_child(plat)
	plat.position = Vector3(0, 0.55, 0)
	# la rampe de galets, en pente douce vers l'intérieur de l'île
	var ramp := MeshInstance3D.new()
	var rb := BoxMesh.new()
	rb.size = Vector3(length - 0.6, 0.25, 4.6)
	ramp.mesh = rb
	ramp.material_override = Statue.stone_mat("ahu", Color(0.85, 0.82, 0.78))
	root.add_child(ramp)
	ramp.position = Vector3(0, 0.55, -4.0)
	ramp.rotation = Vector3(deg_to_rad(-13.0), 0, 0)
	var sb := StaticBody3D.new()
	sb.collision_layer = 1
	sb.collision_mask = 0
	root.add_child(sb)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(length, 1.6, 4.2)
	cs.shape = bs
	cs.position = Vector3(0, 0.55, 0)
	sb.add_child(cs)
	var pk: Array = e[5]
	for i in range(n):
		var off: float = (float(i) - (n - 1) * 0.5) * gap
		var at: Vector3 = c + side * off + Vector3.UP * 1.35
		moais.append(Statue.make(self, at, face, {"h": h * (0.92 + 0.16 * _rng.randf()), "v": (i + n) % 3, "pukao": i in pk, "nom": "Moai_" + id}))
	avoid.append([Vector2(c.x, c.z), length * 0.5 + 4.0])
	objets[id] = c - face * 7.0


## La grande porte du Grand Moaï : une dalle de pierre, scellée, et un cercle de signes qui luisent
## faiblement (V89 : elle s'ouvrira sur l'escalier).
func _grand_door(m: Node3D) -> void:
	var fz: float = float(m.get_meta("front"))
	var slab := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(3.4, 4.6, 0.5)
	slab.mesh = bm
	slab.material_override = Statue.stone_mat("ahu", Color(0.9, 0.86, 0.8))
	m.add_child(slab)
	slab.position = Vector3(0, 2.3, fz + 0.1)
	var glow := StandardMaterial3D.new()
	glow.albedo_color = Color(0.4, 0.85, 0.95)
	glow.emission_enabled = true
	glow.emission = Color(0.35, 0.85, 1.0)
	glow.emission_energy_multiplier = 0.9
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.95
	tm.outer_radius = 1.05
	ring.mesh = tm
	ring.material_override = glow
	m.add_child(ring)
	ring.rotation = Vector3(PI * 0.5, 0, 0)
	ring.position = Vector3(0, 2.6, fz + 0.37)
	for k in range(8):
		var a: float = TAU * k / 8.0
		var g := MeshInstance3D.new()
		var gb := BoxMesh.new()
		gb.size = Vector3(0.12, 0.3 if k % 2 == 0 else 0.18, 0.04)
		g.mesh = gb
		g.material_override = glow
		m.add_child(g)
		g.position = Vector3(cos(a) * 0.72, 2.6 + sin(a) * 0.72, fz + 0.37)
		g.rotation = Vector3(0, 0, a)
	var eye := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.2
	sm.height = 0.3
	eye.mesh = sm
	eye.material_override = glow
	m.add_child(eye)
	eye.position = Vector3(0, 2.6, fz + 0.38)
	m.set_meta("grande_porte", m.global_transform * Vector3(0, 0.05, fz + 1.6))
	m.set_meta("glow", glow)


## Les interactions (quand donjon_v35 existe) : frapper chez les petits Moaïs, la grande porte.
func _register_interactions() -> void:
	if _registered:
		return
	var d: Node = main.get("donjon_v35")
	if d == null:
		return
	_registered = true
	# (V88 : les portes des petits Moaïs s'ouvrent : c'est maisons_v81 qui les tient)
	for i2 in range(promeneurs.size()):
		var idx: int = i2
		var m2: Node3D = promeneurs[i2]["m"]
		var it := {"id": "moai_promeneur_%d" % i2, "pos": m2.global_position, "radius": 1.8,
			"text": "E : parler à " + str(m2.display_name), "vr": "Gâchette : parler à " + str(m2.display_name), "call": func(): _talk_promeneur(idx)}
		d._interactions.append(it)
		promeneurs[i2]["it"] = it
	if grand != null:
		d._interactions.append({"id": "moai_grande_porte", "pos": grand.get_meta("grande_porte"), "radius": 2.6,
			"text": "E : examiner la grande porte", "vr": "Gâchette : examiner la grande porte", "call": _grand_porte})


## Toc toc ! Une petite voix de pierre répond (une blague, toujours une autre).
func _knock(i: int) -> void:
	var n: int = int(state.get("toc", 0))
	state["toc"] = n + 1
	var lines: Array = TOC[(n + i * 3) % TOC.size()]
	sfx("touche_bois", maisons[i]["door"])
	say("Toc, toc, toc. Une petite voix, derrière la porte : « " + str(lines[0]) + " »", 5.0)
	if lines.size() > 1:
		await get_tree().create_timer(4.5).timeout
		say("« " + str(lines[1]) + " »", 6.0)
	if n + 1 == 5:
		await get_tree().create_timer(6.5).timeout
		say("Derrière toutes les portes, on rit. Les petits Moaïs ont l'air très farceurs… et très curieux de toi.", 6.0)


func _grand_porte() -> void:
	var first: bool = not bool(state.get("grande_porte", false))
	state["grande_porte"] = true
	sfx("touche_pierre", grand.get_meta("grande_porte"))
	if first:
		say("Une immense dalle de pierre ferme le ventre du Grand Moaï. Au milieu, un cercle de signes luit faiblement, comme s'il respirait. On entend, très loin dessous, de l'eau qui coule… et quelque chose qui chante.", 8.0)
	else:
		if bool(state.get("legende", false)):
			say("Tu repenses à la légende de Mamie Basalte : rendre ses deux yeux au Grand Moaï. Un dans « l'eau qui regarde le ciel », l'autre « sous les têtes qui regardent les nuages ».", 7.0)
		else:
			say("La dalle ne bouge pas d'un cheveu. Il manque quelque chose pour l'ouvrir. Les petits Moaïs savent peut-être…", 6.0)


func say(text: String, seconds: float = 6.0) -> void:
	var d: Node = main.get("donjon_v35")
	if d != null and d.has_method("_say"):
		d._say(text, seconds)
	else:
		main._show_message_v28(text)


func sfx(name: String, at: Vector3) -> void:
	if main.has_method("sfx"):
		main.sfx(name, at)


# =================================================================== services du jeu

func register_services(journal: Node) -> void:
	for k in objets:
		journal.lieux[str(k)] = objets[k]
	journal.lieux["moai"] = respawn_point()[0]
	_register_interactions()


func contains(p: Vector3) -> bool:
	return ile != null and ile.contains(p.x, p.z) and p.y > -45.0


## À pied : on peut marcher ici (la terre ferme) ? Pas dans la mer, pas au fond du lac.
func walkable(p: Vector3) -> bool:
	if not contains(p):
		return false
	return ile.height(p.x, p.z) > -0.3 or p.y > 1.0


func owns_point(p: Vector3) -> bool:
	return contains(p)


func zone_at(p: Vector3) -> String:
	if not contains(p):
		return ""
	var l: Vector2 = IleScript.L(p.x, p.z)
	if l.distance_to(IleScript.PLATEAU) < IleScript.PLATEAU_R + 8.0:
		return "plateau"
	for k in IleScript.VOLCANS:
		var v: Array = IleScript.VOLCANS[k]
		if l.distance_to(Vector2(float(v[0]), float(v[1]))) < float(v[2]) * 0.75:
			return str(k)
	for k2 in AHUS:
		var e: Array = AHUS[k2]
		if l.distance_to(Vector2(float(e[0]), float(e[1]))) < 22.0:
			return str(k2)
	if IleScript.beach_k(l.x, l.y) > 0.4 and IleScript.coast_q(l.x, l.y) > 0.75:
		return "plage"
	return "prairie"


func place_name(p: Vector3) -> String:
	return "L'Île aux Moaïs, " + str(PLACES.get(zone_at(p), "l'île"))


## Pour la téléportation : on arrive sur la Plage Blanche, face à l'île.
func village_point(_id: String) -> Array:
	return respawn_point()


func respawn_point() -> Array:
	var p: Vector3 = _ground(8.0, 92.0) + Vector3.UP * 0.3
	return [p, Vector3(0, 0, -1)]


func on_faint(_p: Vector3) -> void:
	var at: Array = respawn_point()
	main.place_player_v35(at[0], at[1])


func hour() -> float:
	var t: Node = main.get("temps_v56")
	return float(t.hour) if t != null else 12.0


func _process(delta: float) -> void:
	if main == null or ile == null:
		return
	_clock += delta
	# la grande porte respire
	if grand != null and grand.has_meta("glow"):
		var g: StandardMaterial3D = grand.get_meta("glow")
		g.emission_energy_multiplier = 0.7 + 0.45 * (0.5 + 0.5 * sin(_clock * 1.3))
	var p: Vector3 = main._player_pos_v27()
	if not ile.contains(p.x, p.z):
		return
	if p.distance_to(IleScript.W(0.0, 0.0, p.y)) < 120.0:
		_promeneurs_tick(delta)
	if not bool(state["visite"]) and ile.height(p.x, p.z) > -0.2 and bool(main.get("game_started")):
		state["visite"] = true
		main._show_message_v28("L'Île aux Moaïs — des géants de pierre qui regardent l'île… et qui, paraît-il, rigolent quand on a le dos tourné")
		if main.has_method("jingle"):
			main.jingle("decouverte")
	_zone_t -= delta
	if _zone_t > 0.0:
		return
	_zone_t = 1.0
	var z: String = zone_at(p)
	var vis: Dictionary = state["visites"]
	if z in ["plateau", "lac", "carriere", "ahu_levant", "ahu_couchant"] and not bool(vis.get(z, false)):
		vis[z] = true
		match z:
			"plateau":
				main._show_message_v28("Le Plateau des Anciens — le Grand Moaï, et la ronde des Moaïs qui ont une porte")
			"lac":
				main._show_message_v28("Le Cratère du Lac — une eau immobile, couleur de ciel, au fond du volcan")
			"carriere":
				main._show_message_v28("La Butte de la Carrière — des têtes de pierre qui sortent de l'herbe, comme pour voir passer les nuages")
			"ahu_levant":
				main._show_message_v28("L'Ahu du Levant — sept Moaïs alignés, le dos à la mer, qui regardent l'île")
			"ahu_couchant":
				main._show_message_v28("L'Ahu du Couchant — ils regardent le soleil se lever sur l'île, chaque matin, depuis toujours")
	# la surface vue d'en dessous suit le plongeur (la mer de l'île est loin du centre du monde)
	var mer: Node = main.get("mer_v55")
	if mer != null and mer.get("_underside") != null:
		(mer._underside as Node3D).global_position = Vector3(snappedf(p.x, 40.0), (mer._underside as Node3D).global_position.y, snappedf(p.z, 40.0))


func trouvailles() -> Dictionary:
	var vis: Dictionary = state.get("visites", {})
	return {"moai": 1 if bool(state.get("visite", false)) else 0, "moai_plateau": 1 if bool(vis.get("plateau", false)) else 0,
		"moai_lac": 1 if bool(vis.get("lac", false)) else 0, "moai_carriere": 1 if bool(vis.get("carriere", false)) else 0,
		"moai_blagues": 1 if int(state.get("toc", 0)) >= 5 else 0, "moai_legende": 1 if bool(state.get("legende", false)) else 0}


func serialize() -> Dictionary:
	return state.duplicate(true)


func load_data(d: Dictionary) -> void:
	state = _fresh_state()
	for k in state:
		if d.has(k):
			state[k] = d[k] if not (d[k] is Dictionary) else (d[k] as Dictionary).duplicate(true)
