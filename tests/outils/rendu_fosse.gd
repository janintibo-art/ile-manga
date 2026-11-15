extends SceneTree
## Des images de la Fosse aux Dés (V147), pour juger l'effet (lancé par tests/outils/rendu_fosse.sh) :
## la salle (les trois tables, la Caisse, le Tableau des réputations, Monsieur Rouage), les habitués, puis
## assis aux tables : le tapis de jeu (PC), les dés lancés, une partie de Menteur.
## V148 : avec « tripot », le Tripot de la Dame de Pique (le salon, la table de blackjack, une main).

const Maisons = preload("res://scripts/maisons_v81.gd")
const Jeux = preload("res://scripts/jeux_v147.gd")
const Inv = preload("res://scripts/inventory_v28.gd")


class FakeInv:
	extends Node
	var ITEMS: Dictionary = Inv.ITEMS
	var opened: bool = false
	var sac: Dictionary = {}

	func count(id: String) -> int:
		return int(sac.get(id, 0))

	func add(id: String, n: int = 1) -> int:
		sac[id] = count(id) + n
		return n

	func remove(id: String, n: int = 1) -> int:
		sac[id] = maxi(0, count(id) - n)
		return n


class FakeMain:
	extends Node3D
	var xr_active: bool = false
	var cam: Camera3D
	var npcs_v31: Array = []
	var pending_pnj_v31: Dictionary = {}
	var game_started: bool = true
	var temps_v56: Node
	var inventory_v28: Node
	var jeux_v147: Node
	var maisons_v81: Node
	var dialogue_v31: Node = null

	func _player_pos_v27() -> Vector3:
		return cam.global_position if cam != null else Vector3.ZERO

	func _height_at(_x: float, _z: float) -> float:
		return -260.0

	func _npc_ctx_v31() -> Dictionary:
		return {"now": 0.0, "objets": {}, "vr": false}

	func sfx(_n: String, _at: Variant = null, _db: float = 0.0) -> void:
		pass

	func jingle(_n: String) -> void:
		pass

	func _show_message_v28(t: String) -> void:
		print("MESSAGE ", t)

	func place_player_v35(at: Vector3, facing: Vector3) -> void:
		facing.y = 0.0
		cam.global_position = at + Vector3.UP * 1.62 - facing.normalized() * 0.25
		cam.look_at(at + facing.normalized() * 1.2 + Vector3.UP * 0.75, Vector3.UP)


class FakeTemps:
	extends Node
	var hour: float = 21.0
	var day_count: int = 3
	var lamps_on: bool = true

	func register_glow(_m: Variant, _a: Variant = null, _b: Variant = null) -> void:
		pass

	func register_lamp(_l: Variant, _e: Variant = null) -> void:
		pass


var out: String = ""
var cam: Camera3D
var fm: FakeMain
var n_img: int = 0


func _photo(nom: String) -> void:
	for k in range(6):
		await process_frame
	var img: Image = root.get_viewport().get_texture().get_image()
	n_img += 1
	img.save_png("%s/%02d_%s.png" % [out, n_img, nom])
	print("RENDU ", nom)


func _vue(from: Vector3, to: Vector3) -> void:
	cam.global_position = from
	cam.look_at(to, Vector3.UP)


func _initialize() -> void:
	out = str(OS.get_cmdline_user_args()[0])
	var lieu: String = str(OS.get_cmdline_user_args()[1]) if OS.get_cmdline_user_args().size() > 1 else "fosse"
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.02, 0.02)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.42, 0.36)
	env.ambient_light_energy = 0.35
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	we.environment = env
	root.add_child(we)
	fm = FakeMain.new()
	root.add_child(fm)
	var tp := FakeTemps.new()
	fm.add_child(tp)
	fm.temps_v56 = tp
	fm.inventory_v28 = FakeInv.new()
	fm.add_child(fm.inventory_v28)
	cam = Camera3D.new()
	cam.fov = 70.0
	cam.near = 0.05
	root.add_child(cam)
	cam.current = true
	fm.cam = cam
	var J: Node = Jeux.new()
	fm.add_child(J)
	J.setup(fm)
	fm.jeux_v147 = J
	var M: Node = Maisons.new()
	fm.add_child(M)
	fm.maisons_v81 = M
	M.main = fm
	M.cur = {"id": "rendu_fosse", "style": "perchee_lieu", "histoire": "pp_" + lieu, "w": 15.0, "d": 13.0, "floors": 1, "owner": ""}
	M.inside = true
	for k in range(3):
		await process_frame
	var arr: Array = M._build()
	M.inside = true
	print("RENDU construit ", arr)
	for k in range(10):
		await process_frame
	var R = M.R
	if lieu == "tripot":
		await _tripot(J, R)
		quit()
		return
	_vue(R.P(0, 2.6, 6.0), R.P(0, 0.8, -3.0))
	await _photo("salle_depuis_porte")
	_vue(R.P(-6.6, 2.4, 5.6), R.P(1.5, 0.9, -3.0))
	await _photo("salle_coin")
	_vue(R.P(-4.2, 1.75, -1.4), R.P(-4.2, 0.9, -3.6))
	await _photo("grand_lancer")
	_vue(R.P(4.2, 1.75, -1.4), R.P(4.2, 1.1, -3.8))
	await _photo("sept_automate")
	_vue(R.P(0.6, 1.9, 3.4), R.P(0, 0.8, 0.9))
	await _photo("menteur")
	_vue(R.P(-3.6, 1.8, 3.2), R.P(-6.5, 1.0, 4.6))
	await _photo("caisse")
	_vue(R.P(4.4, 1.8, -0.9), R.P(7.5, 1.8, -0.9))
	await _photo("tableau")
	fm.inventory_v28.add("jeton", 0)
	J.asseoir("caisse")
	J._choix("jetons_jour", {})
	await _photo("tapis_caisse")
	J.lever()
	J.asseoir("lancer")
	J._choix("lancer", {})
	for k in range(150):
		await process_frame
	await _photo("tapis_lancer")
	_vue(R.P(-4.2, 1.45, -2.2), R.P(-4.2, 0.85, -3.3))
	await _photo("des_sur_tapis")
	J.lever()
	J.asseoir("sept")
	J._choix("lancer", {})
	for k in range(150):
		await process_frame
	await _photo("tapis_sept")
	J.lever()
	J.asseoir("menteur")
	J._choix("prendre_place", {})
	for k in range(200):
		await process_frame
	await _photo("menteur_partie")
	_vue(R.P(0.0, 1.55, 2.1), R.P(0, 0.85, 0.7))
	await _photo("menteur_des")
	quit()


func _tripot(J: Node, R) -> void:
	_vue(R.P(0, 2.4, 5.6), R.P(0, 0.9, -3.0))
	await _photo("tripot_salle")
	_vue(R.P(5.8, 2.2, 4.8), R.P(-2.0, 0.9, -2.0))
	await _photo("tripot_coin")
	_vue(R.P(-2.2, 1.8, 1.8), R.P(-6.5, 1.4, -1.0))
	await _photo("tripot_bar")
	_vue(R.P(0, 1.9, 0.2), R.P(0, 0.9, -3.0))
	await _photo("tripot_table")
	_vue(R.P(-2.5, 1.6, 2.6), R.P(-3.6, 0.8, 2.4))
	await _photo("tripot_habitues")
	fm.inventory_v28.add("jeton", 40)
	J.asseoir("blackjack")
	await _photo("tripot_assis")
	J._choix("distribuer", {})
	for k in range(260):
		await process_frame
	await _photo("tripot_main")
	_vue(R.P(0, 1.45, -1.55), R.P(0, 0.86, -2.55))
	await _photo("tripot_cartes")
	J.tapis.choisi.emit("rester", {})
	for k in range(400):
		await process_frame
	await _photo("tripot_fin")
	_vue(R.P(0, 1.45, -1.55), R.P(0, 0.86, -2.55))
	await _photo("tripot_cartes_fin")
