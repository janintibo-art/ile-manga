extends Node
## V70 : le Tournoi des Cornes, à l'Arène des Cornes de Pandémonia (la quête de Madame Hurla).
## Quatre manches sur le sable, l'une après l'autre (on frappe le gong pour commencer) :
##  1. trois diablotins ; 2. deux chiens d'enfer ; 3. deux automates de bronze et deux
##  diablotins ; 4. Gorgoth le Cornu, le champion, en personne (il s'avoue vaincu avant de
##  tomber). Madame Hurla annonce dans son porte-voix, la foule des gradins acclame. Sortir du
##  sable pendant une manche, c'est l'abandon ; s'évanouir aussi (on se réveille à la porte).

const ROUNDS := [
	[["diablotin", 5.0, 0.0], ["diablotin", -4.0, 3.0], ["diablotin", -2.0, -4.5]],
	[["chien_enfer", 5.0, 2.0], ["chien_enfer", -5.0, -2.0]],
	[["automate", 5.5, 0.0], ["automate", -5.5, 0.0], ["diablotin", 0.0, 5.0], ["diablotin", 0.0, -5.0]],
	[["gorgoth", 0.0, -5.5]],
]
const ROUND_TXT := [
	"Madame Hurla, dans son porte-voix : « MESDAMES ET MESSIEURS LES DÉMONS ! Première manche du Tournoi des Cornes : TROIS DIABLOTINS, plus agaçants que méchants ! »",
	"Madame Hurla : « DEUXIÈME MANCHE ! Ils ont des crocs, ils ont des flammes, ils n'ont pas de manières : DEUX CHIENS D'ENFER ! »",
	"Madame Hurla : « TROISIÈME MANCHE ! Du bronze qui marche et des diablotins qui ricanent : DEUX AUTOMATES ET DEUX DIABLOTINS ! »",
	"Madame Hurla : « LA FINALE ! Sept ans invaincu, deux mètres quarante de cornes, un cœur d'artichaut : GORGOTH LE CORNU ! » La foule se lève d'un bond.",
]
const PRIZES := [15, 25, 35, 80]

var main: Node
var braise: Node
var arena: Dictionary = {}
var center := Vector3.ZERO
var radius: float = 10.2
var current: int = -1                    # la manche en cours (-1 : pas de combat)
var monsters: Array = []
var _start_t: float = -1.0
var _clock: float = 0.0
var _gong: Node3D
var _crowd_t: float = 0.0
var _boss: Node3D
var _bar_on: bool = false
var _out_t: float = 0.0


func setup(main_node: Node, braise_node: Node) -> void:
	main = main_node
	braise = braise_node
	if braise.city == null or braise.city.basse == null:
		return
	arena = braise.city.basse.arena
	center = arena["c"]
	radius = float(arena.get("r", 10.2))
	_build_gong()


## Le gong (un grand disque de bronze sur un portique), au bord du sable, près de la porte.
func _build_gong() -> void:
	var xf: Transform3D = arena["xf"]
	var at: Vector3 = xf * Vector3(6.5, 0.05, 6.5)
	_gong = Node3D.new()
	_gong.name = "Gong_arene"
	add_child(_gong)
	_gong.global_transform = Transform3D(xf.basis * Basis(Vector3.UP, PI * 0.25), at)
	var iron := StandardMaterial3D.new()
	iron.albedo_color = Color(0.15, 0.13, 0.13)
	iron.metallic = 0.7
	iron.roughness = 0.45
	var bronze := StandardMaterial3D.new()
	bronze.albedo_color = Color(0.78, 0.52, 0.22)
	bronze.metallic = 0.9
	bronze.roughness = 0.28
	for s in [-1.0, 1.0]:
		var post := MeshInstance3D.new()
		var pm := BoxMesh.new()
		pm.size = Vector3(0.14, 2.6, 0.14)
		post.mesh = pm
		post.material_override = iron
		post.position = Vector3(s * 0.95, 1.3, 0)
		_gong.add_child(post)
	var bar := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(2.1, 0.14, 0.14)
	bar.mesh = bm
	bar.material_override = iron
	bar.position = Vector3(0, 2.55, 0)
	_gong.add_child(bar)
	var disc := MeshInstance3D.new()
	var dm := CylinderMesh.new()
	dm.top_radius = 0.75
	dm.bottom_radius = 0.75
	dm.height = 0.06
	dm.radial_segments = 32
	disc.mesh = dm
	disc.material_override = bronze
	disc.rotation.x = PI * 0.5
	disc.position = Vector3(0, 1.55, 0)
	disc.name = "Disque"
	_gong.add_child(disc)


func register_interactions(d: Node) -> void:
	if _gong == null:
		return
	var me = self
	var it := {"id": "braise_gong", "pos": _gong.global_position + Vector3.UP * 0.5, "radius": 2.4,
		"text": "E : frapper le gong (Tournoi des Cornes)", "vr": "Gâchette : frapper le gong", "call": func(): me._gong_hit(),
		"when": func(): return me.current < 0 and int(me.braise.state.get("tournoi", 0)) < 4}
	d._interactions.append(it)
	var it2 := {"id": "braise_gong_fini", "pos": _gong.global_position + Vector3.UP * 0.5, "radius": 2.4,
		"text": "E : frapper le gong (pour le plaisir)", "vr": "Gâchette : le gong", "call": func(): me._gong_fun(),
		"when": func(): return me.current < 0 and int(me.braise.state.get("tournoi", 0)) >= 4}
	d._interactions.append(it2)


func register_services(journal: Node) -> void:
	journal.lieux["arene_sable"] = center


func is_fighting() -> bool:
	return current >= 0


func _say(t: String, s: float = 6.0) -> void:
	braise._say(t, s)


func _gong_fun() -> void:
	_sfx("arene_gong", _gong.global_position + Vector3.UP * 1.5)
	_say("BOOONG. Quelque part dans les gradins, quelqu'un crie : « ENCORE ! » (Le champion a le droit.)", 4.0)


func _gong_hit() -> void:
	var j: Node = main.get("journal_v56")
	if j != null and str(j.state("br_tournoi")) == "" and int(braise.state.get("tournoi", 0)) == 0:
		_say("Le gong ne veut rien dire tant qu'on n'est pas inscrit. Madame Hurla tient le guichet de l'arène : elle inscrit les concurrents (et elle crie très fort).", 6.0)
		return
	var n: int = int(braise.state.get("tournoi", 0))
	_sfx("arene_gong", _gong.global_position + Vector3.UP * 1.5)
	current = n
	_start_t = 3.5
	_say(ROUND_TXT[n], 7.0)
	_sfx("arene_foule", center + Vector3.UP * 6.0)
	if n == 3:
		_hide_gorgoth(true)


## Gorgoth descend dans l'arène : celui des gradins (l'habitant) disparaît pendant le combat.
func _hide_gorgoth(on: bool) -> void:
	var g: Node = braise.by_id.get("gorgoth", null)
	if g == null or not is_instance_valid(g):
		return
	if on:
		g.call("_set_hidden", true)
		g.set_process(false)
	else:
		g.set_process(true)
		g.set("slot", -2)


func _spawn_round() -> void:
	var ms: Node = main.get("monstres_v36")
	if ms == null:
		current = -1
		return
	monsters.clear()
	var xf: Transform3D = arena["xf"]
	for e in ROUNDS[current]:
		var at: Vector3 = xf * Vector3(float(e[1]), 0.1, float(e[2]))
		at.y = center.y + 0.1
		var m: Node3D = ms.spawn_extra(str(e[0]), at)
		if m == null:
			continue
		m.set("home", center)
		m.set("state", "chasse")
		var sp: Dictionary = m.get("spec")
		var sp2: Dictionary = sp.duplicate()
		sp2["laisse"] = 30.0
		sp2["vue"] = 30.0
		m.set("spec", sp2)
		monsters.append(m)
		if main.combat_v28 != null:
			main.combat_v28.puff(at + Vector3.UP, Color(1.0, 0.5, 0.2))
	if current == 3 and not monsters.is_empty():
		_boss = monsters[0]
		_show_bar("Gorgoth le Cornu", int(_boss.spec["pv"]))


func _process(delta: float) -> void:
	if main == null or arena.is_empty():
		return
	_clock += delta
	if current < 0:
		return
	if _start_t > 0.0:
		_start_t -= delta
		if _start_t <= 0.0:
			_spawn_round()
		return
	var p: Vector3 = main._player_pos_v27()
	var flat: float = Vector2(p.x - center.x, p.z - center.z).length()
	# sortir du sable : l'abandon (un peu de patience : on peut reculer contre le mur)
	if flat > radius + 2.5 or absf(p.y - center.y) > 6.0:
		_out_t += delta
		if _out_t > 2.0:
			_abandon("Madame Hurla : « ABANDON ! Il a quitté le sable ! » La foule siffle (gentiment). On recommencera la manche quand tu voudras.")
			return
	else:
		_out_t = 0.0
	_crowd_t -= delta
	if _crowd_t <= 0.0:
		_crowd_t = randf_range(5.0, 9.0)
		_sfx("arene_foule", center + Vector3(randf_range(-12, 12), 6.0, randf_range(-12, 12)))
	if _bar_on and _boss != null and is_instance_valid(_boss):
		main.donjon_v35._update_bar(maxi(int(_boss.hp), 0), int(_boss.spec["pv"]))
	var alive: int = 0
	for m in monsters:
		if is_instance_valid(m) and not (str(m.get("state")) in ["mort", "rendu"]):
			alive += 1
	if alive == 0:
		_win()


func _win() -> void:
	var n: int = current
	current = -1
	_hide_bar()
	braise.state["tournoi"] = maxi(int(braise.state.get("tournoi", 0)), n + 1)
	main.inventory_v28.add("piece", PRIZES[n])
	_sfx("arene_foule", center + Vector3.UP * 6.0)
	if main.has_method("jingle"):
		main.jingle("victoire")
	if n < 3:
		_say("Madame Hurla : « VICTOIRE ! » La foule tape des pieds et des queues sur les gradins. (+%d pièces.) Frappe le gong pour la manche suivante." % PRIZES[n], 7.0)
	else:
		braise.state["champion"] = true
		var inv: Node = main.inventory_v28
		if inv.add("corne_or", 1) <= 0:
			inv.spawn_pickup("braise_corne_or", "corne_or", 1, center + Vector3.UP * 0.5)
		_say("Gorgoth pose un genou dans le sable et lève sa grosse main : « Je… je m'avoue vaincu. Quel combat ! Tu as le cœur d'un poète. » Madame Hurla hurle : « NOUVEAU CHAMPION DES CORNES ! » et te tend la Corne d'or. (+%d pièces.)" % PRIZES[n], 10.0)
		await get_tree().create_timer(6.0).timeout
		for m in monsters:
			if is_instance_valid(m):
				(m as Node).queue_free()
		monsters.clear()
		_hide_gorgoth(false)


func _abandon(t: String) -> void:
	var was: int = current
	current = -1
	_start_t = -1.0
	_hide_bar()
	for m in monsters:
		if is_instance_valid(m):
			var ms: Node = main.get("monstres_v36")
			if ms != null:
				ms.monsters.erase(m)
			(m as Node).queue_free()
	monsters.clear()
	if was == 3:
		_hide_gorgoth(false)
	_say(t, 7.0)


## Évanoui sur le sable : on se réveille à la porte de l'arène (la manche est perdue).
func on_faint(p: Vector3) -> bool:
	if current < 0 and Vector2(p.x - center.x, p.z - center.z).length() > radius + 4.0:
		return false
	_abandon("Madame Hurla : « K.O. ! On le ramasse ! » Deux démons te portent jusqu'à la porte de l'arène, et Bulle t'apporte un grog de soufre. On recommencera la manche quand tu voudras.")
	var door: Vector3 = arena["porte"]
	main.place_player_v35(door + Vector3.UP * 0.2, (center - door).normalized())
	var hero: Node = main.get("hero_v28")
	if hero != null:
		hero.set_health(int(hero.HP_MAX))
	return true


func _show_bar(label: String, hp_max: int) -> void:
	var d: Node = main.get("donjon_v35")
	if d == null:
		return
	d._bar_name = label
	d._bar_label.text = label
	d._bar_layer.visible = not main.xr_active
	d._update_bar(hp_max, hp_max)
	_bar_on = true


func _hide_bar() -> void:
	if not _bar_on:
		return
	_bar_on = false
	var d: Node = main.get("donjon_v35")
	if d != null:
		d._bar_layer.visible = false
	_boss = null


func _sfx(n: String, at: Vector3) -> void:
	if main != null and main.has_method("sfx"):
		main.sfx(n, at)


func trouvailles() -> Dictionary:
	return {"arene_manche_1": 1 if int(braise.state.get("tournoi", 0)) >= 1 else 0}


func apply_state() -> void:
	current = -1
	monsters.clear()
	_hide_bar()
