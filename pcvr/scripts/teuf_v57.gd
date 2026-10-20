extends Node3D
## V57 : la teuf de la plage, sur l'île du village. Devant le mur de son, une quinzaine de
## teufeurs dansent (pnj_teuf_v57.gd, profils dans pnj/teufeurs_v57.gd) ; derrière la table
## de mixage, DJ Mistral mixe sur une estrade de planches qui le met à la bonne hauteur :
## la hauteur des platines est mesurée dans le jeu (un rayon sur la table), celle des mains
## du DJ dans sa posture, et l'estrade comble la différence.
## La sono joue « Marée Basse » (tools/compose_teuf_v57.py) en continu ; on l'entend de loin
## (la musique du lieu se tait quand on est à la fête). La nuit, des projecteurs de couleur
## battent au rythme du kick.

const PnjTeuf = preload("res://scripts/pnj/pnj_teuf_v57.gd")
const Profiles = preload("res://scripts/pnj/teufeurs_v57.gd")
const MUSIC := "res://assets/sons/musique/teuf.ogg"
const BEAT: float = 60.0 / 145.0
const WALL := Vector3(0.0, 0.0, 60.0)        # le mur de son (face à la terre, vers -Z)
const TABLE := Vector3(9.0, 0.0, 60.0)       # la table de mixage
const PISTE := Vector2(2.0, 51.5)            # centre de la piste de danse (x, z)
## Hauteur des mains du DJ au-dessus de ses pieds, dans la posture « dj » (mesurée).
const DJ_HANDS: float = 0.79
const DJ_Z: float = 61.3                    # où se tient le DJ, derrière la table (côté mer)

var main: Node
var music: AudioStreamPlayer3D
var dancers: Array = []
var dj: Node3D
var deck_y: float = 2.0
var riser_top: float = 1.0
var heard: bool = false
var ramp_foot: Vector3 = Vector3.ZERO
var lights: Array = []
var floor_light: OmniLight3D
var _t0: int = 0


func setup(main_node: Node) -> void:
	main = main_node
	_t0 = Time.get_ticks_msec()
	deck_y = _deck_height()
	var feet_ground: float = main._height_at(TABLE.x, DJ_Z)
	riser_top = maxf(deck_y - DJ_HANDS, feet_ground + 0.2)
	_build_riser(feet_ground)
	_build_music()
	_build_lights()
	print("ILE_MANGA_V57: teuf de la plage, platines à %.2f m, estrade du DJ à %.2f m (sol %.2f)" % [deck_y, riser_top, feet_ground])


## Le dessus des platines : on lance des rayons vers le bas sur la table.
func _deck_height() -> float:
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var best: float = -100.0
	for x in [7.3, 8.3, 9.0, 9.7, 10.7]:
		for z in [59.8, 60.2, 60.6]:
			var q := PhysicsRayQueryParameters3D.create(Vector3(x, 6.0, z), Vector3(x, -2.0, z))
			var hit: Dictionary = space.intersect_ray(q)
			if not hit.is_empty():
				best = maxf(best, float(hit["position"].y))
	if best < -50.0:
		best = main._height_at(TABLE.x, TABLE.z) + 1.9
	# les platines dépassent la table de quelques centimètres : les mains se posent dessus
	return best


func music_time() -> float:
	if music != null and music.playing:
		return music.get_playback_position() + AudioServer.get_time_since_last_mix()
	return float(Time.get_ticks_msec() - _t0) / 1000.0


# =================================================================== l'estrade du DJ

func _wood() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	var p: String = "res://assets/textures/azur/planches.png"
	if ResourceLoader.exists(p):
		m.albedo_texture = load(p)
		m.uv1_triplanar = true
		m.uv1_scale = Vector3.ONE * 0.6
	m.albedo_color = Color(0.86, 0.74, 0.6)
	m.roughness = 0.88
	return m


func _box(parent: Node3D, center: Vector3, size: Vector3, mat: Material, solid: bool) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = center
	parent.add_child(mi)
	if solid:
		var body := StaticBody3D.new()
		body.position = center
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = size
		cs.shape = sh
		body.add_child(cs)
		parent.add_child(body)


func _box_xf(parent: Node3D, xf: Transform3D, size: Vector3, mat: Material, solid: bool) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.transform = xf
	parent.add_child(mi)
	if solid:
		var body := StaticBody3D.new()
		body.transform = xf
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = size
		cs.shape = sh
		body.add_child(cs)
		parent.add_child(body)


func _build_riser(ground: float) -> void:
	var root := Node3D.new()
	root.name = "Estrade_DJ_v57"
	add_child(root)
	var wood := _wood()
	var dark := _wood()
	dark.albedo_color = Color(0.5, 0.4, 0.32)
	var x0: float = TABLE.x - 2.1
	var x1: float = TABLE.x + 4.0          # l'estrade dépasse la table à droite : la rampe y arrive
	var z0: float = 61.2
	var z1: float = 62.9
	var low: float = minf(ground, main._height_at(TABLE.x, z1)) - 0.4
	var h: float = riser_top - low
	# le plancher et sa jupe de planches sombres
	_box(root, Vector3((x0 + x1) * 0.5, riser_top - 0.06, (z0 + z1) * 0.5), Vector3(x1 - x0, 0.12, z1 - z0), wood, true)
	_box(root, Vector3((x0 + x1) * 0.5, low + (h - 0.12) * 0.5, z1 - 0.04), Vector3(x1 - x0, h - 0.12, 0.08), dark, false)
	for sx in [x0 + 0.04, x1 - 0.04]:
		_box(root, Vector3(sx, low + (h - 0.12) * 0.5, (z0 + z1) * 0.5), Vector3(0.08, h - 0.12, z1 - z0), dark, false)
	for px in [x0 + 0.15, x1 - 0.15]:
		for pz in [z0 + 0.15, z1 - 0.15]:
			_box(root, Vector3(px, low + h * 0.5, pz), Vector3(0.14, h, 0.14), dark, false)
	# un garde-corps à l'arrière (côté mer)
	for px2 in [x0 + 0.1, (x0 + x1) * 0.5, x1 - 0.1]:
		_box(root, Vector3(px2, riser_top + 0.5, z1 - 0.1), Vector3(0.07, 1.0, 0.07), dark, false)
	_box(root, Vector3((x0 + x1) * 0.5, riser_top + 1.0, z1 - 0.1), Vector3(x1 - x0, 0.07, 0.07), dark, true)
	# la rampe : à droite de la table, elle descend vers la plage (vers -Z, côté terre)
	var rx: float = x1 - 0.55
	var rise_h: float = riser_top - main._height_at(rx, z0 - 3.0)
	var run: float = maxf(rise_h / tan(deg_to_rad(17.0)), 1.0)
	var foot: float = main._height_at(rx, z0 - run)
	rise_h = riser_top - foot
	run = maxf(rise_h / tan(deg_to_rad(17.0)), 1.0)
	foot = main._height_at(rx, z0 - run)
	rise_h = riser_top - foot
	var ang: float = atan2(rise_h, run)
	var hyp: float = sqrt(run * run + rise_h * rise_h)
	var mid := Vector3(rx, (riser_top + foot) * 0.5 - 0.06, z0 - run * 0.5)
	var xf := Transform3D(Basis(Vector3(1, 0, 0), -ang), mid)
	_box_xf(root, xf, Vector3(1.1, 0.12, hyp + 0.15), wood, true)
	var u: float = 0.4
	while u < hyp - 0.2:
		_box_xf(root, xf * Transform3D(Basis(), Vector3(0, 0.07, -hyp * 0.5 + u)), Vector3(1.0, 0.03, 0.05), dark, false)
		u += 0.45
	ramp_foot = Vector3(rx, foot, z0 - run - 0.6)
	# un tapis sous les pieds du DJ
	var rug := StandardMaterial3D.new()
	rug.albedo_color = Color(0.12, 0.12, 0.14)
	rug.roughness = 0.95
	_box(root, Vector3(TABLE.x, riser_top + 0.005, DJ_Z), Vector3(1.6, 0.01, 0.9), rug, false)


# =================================================================== la sono

func _build_music() -> void:
	music = AudioStreamPlayer3D.new()
	music.name = "Sono_teuf_v57"
	if ResourceLoader.exists(MUSIC):
		var st: AudioStream = load(MUSIC)
		if st is AudioStreamOggVorbis:
			st = (st as AudioStreamOggVorbis).duplicate()
			(st as AudioStreamOggVorbis).loop = true
		music.stream = st
	music.bus = "Musique" if AudioServer.get_bus_index("Musique") >= 0 else "Master"
	music.unit_size = 16.0
	music.max_distance = 140.0
	music.volume_db = -3.0
	music.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	music.position = WALL + Vector3(0, 3.5, -2.6)
	add_child(music)


func _build_lights() -> void:
	var cols := [Color(1.0, 0.15, 0.7), Color(0.1, 0.8, 1.0), Color(0.3, 1.0, 0.3), Color(1.0, 0.65, 0.1)]
	for i in range(4):
		var l := OmniLight3D.new()
		l.name = "Projecteur_teuf_%d" % i
		l.light_color = cols[i]
		l.omni_range = 24.0
		l.light_energy = 0.0
		l.shadow_enabled = false
		l.position = WALL + Vector3(-4.5 + i * 3.0, 6.8, -3.2)
		add_child(l)
		lights.append(l)
	# une lumière douce au-dessus de la piste (guirlande), pour voir danser les gens
	floor_light = OmniLight3D.new()
	floor_light.name = "Lumiere_piste_v57"
	floor_light.light_color = Color(1.0, 0.72, 0.45)
	floor_light.omni_range = 13.0
	floor_light.light_energy = 0.0
	floor_light.shadow_enabled = false
	floor_light.position = Vector3(PISTE.x, main._height_at(PISTE.x, PISTE.y) + 6.0, PISTE.y)
	add_child(floor_light)


# =================================================================== les teufeurs

func spawn_people() -> void:
	if not dancers.is_empty():
		return
	var face_point := Vector3(WALL.x + 2.0, 2.0, WALL.z)
	for data in Profiles.all_profiles():
		var pos: Vector3
		var look: Vector3 = face_point
		if bool(data.get("dj", false)):
			pos = Vector3(TABLE.x, riser_top + 0.3, DJ_Z)
			look = Vector3(TABLE.x, riser_top, DJ_Z - 10.0)
		else:
			var pl: Array = data.get("place", [0.0, 0.0])
			var x: float = PISTE.x + float(pl[0])
			var z: float = PISTE.y - float(pl[1])
			pos = Vector3(x, main._height_at(x, z) + 0.3, z)
		var npc: Node3D = PnjTeuf.new()
		main.add_child(npc)
		npc.setup(main, data, {"piste": pos}, {"piste": []}, "piste")
		npc.setup_teuf(self, data, look)
		var saved: Variant = main.pending_pnj_v31.get(str(data["id"]), {})
		if saved is Dictionary and not (saved as Dictionary).is_empty():
			npc.load_data(saved)
		main.npcs_v31.append(npc)
		dancers.append(npc)
		if bool(data.get("dj", false)):
			dj = npc


func _process(_delta: float) -> void:
	if main == null or music == null:
		return
	var p: Vector3 = main._player_pos_v27()
	var d: float = Vector2(p.x - WALL.x, p.z - WALL.z).length()
	if music.stream != null and not music.playing and d < 160.0:
		music.play()
	elif music.playing and d > 180.0:
		music.stop()
	heard = music.playing and d < 32.0 and bool(main.game_started)
	# les projecteurs, la nuit, au rythme du kick
	var t: Node = main.get("temps_v56")
	var night: bool = t != null and bool(t.lamps_on)
	var ph: float = fmod(music_time(), BEAT) / BEAT
	var bar: int = int(music_time() / (BEAT * 4.0))
	if floor_light != null:
		floor_light.light_energy = 0.9 if night and d < 120.0 else 0.0
	for i in range(lights.size()):
		var l: OmniLight3D = lights[i]
		if not night or d > 120.0:
			l.light_energy = 0.0
			continue
		var on: bool = (bar + i) % 2 == 0 or i == bar % 4
		l.light_energy = (3.5 * exp(-ph * 5.0) + 0.4) if on else 0.25
