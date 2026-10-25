extends Node
## V71 : les événements comiques de Montjoie.
##  - LA GRANDE ALERTE AUX NAVETS : de temps en temps, le jour, quand on est sur l'île, Mélusine
##    sonne sa cloche sur la Grand-Place : « LES NAVETS SE SONT RÉVEILLÉS ! » Une vingtaine de
##    navets fuyards courent dans les Champs du Sud pendant deux minutes ; une tape les attrape
##    (un navet doré chacun, que la Guilde rachète) ; à la fin, des points de guilde ;
##  - LA CHAUMIÈRE DES GLYCINES : une fois achetée chez Monsieur Prosper (la quête mj_maison, ou
##    le Titre de propriété), sa porte s'ouvre ; on y dort (le lit : jusqu'au matin, les cœurs
##    pleins) ; on s'y réveille quand on s'évanouit sur l'île ; l'étagère à trophées montre les
##    reliques qu'on possède ;
##  - LE CHAPEAU DU BARON : il est coincé sur la tête de l'épouvantail de Père Gaubert (une vraie
##    plume !) ; il disparaît de là quand on l'a ramassé ;
##  - les grenouilles qui avalent le joueur : on les compte (pour le carnet, et pour les rires).

const RM = preload("res://scripts/ile_montjoie_v71.gd")
const ALERT_TIME: float = 120.0
const NAVETS: int = 20
## Les reliques (et les souvenirs) qui se posent sur l'étagère de la Chaumière.
const TROPHEES := ["coeur_gelee", "flamme_eternelle", "oeil_horus", "masque_jade", "plume_quetzal", "graine_yggdrasil", "cristal_orage",
	"banniere_gobelin", "carte_aventurier", "navet_dore"]

var main: Node
var mj: Node
var state := {}
var alert_on: bool = false
var _alert_left: float = 0.0
var _alert_wait: float = 420.0
var _navets: Array = []
var _caught_now: int = 0
var _tick_t: float = 0.0
var _gate_open: bool = false
var _shelf_root: Node3D
var _shelf_key: String = ""
var _rng := RandomNumberGenerator.new()


func setup(main_node: Node, manager: Node) -> void:
	main = main_node
	mj = manager
	_rng.randomize()
	state = _fresh()
	_alert_wait = _rng.randf_range(360.0, 600.0)


func _fresh() -> Dictionary:
	return {"alertes": 0, "navets": 0, "record": 0, "avale": 0, "nuits_chaumiere": 0, "trophees": []}


func serialize() -> Dictionary:
	return state.duplicate(true)


func load_data(d: Dictionary) -> void:
	state = _fresh()
	for k in state:
		if d.has(k):
			state[k] = d[k]
	if typeof(state["trophees"]) != TYPE_ARRAY:
		state["trophees"] = []
	_end_alert(true)
	_gate_open = false
	_shelf_key = ""


func trouvailles() -> Dictionary:
	return {"alerte_navets": 1 if int(state["alertes"]) > 0 else 0, "navets_5": 1 if int(state["record"]) >= 5 else 0,
		"navets_attrapes": int(state["navets"]), "chaumiere": 1 if owns_house() else 0, "avale_grenouille": 1 if int(state["avale"]) > 0 else 0}


# =================================================================== la Chaumière des Glycines

func owns_house() -> bool:
	var j: Node = main.get("journal_v56") if main != null else null
	if j != null and str(j.state("mj_maison")) == "finie":
		return true
	return main != null and main.get("inventory_v28") != null and main.inventory_v28.count("titre_propriete") > 0


## Le point de réveil (le lit de la Chaumière, si elle est à nous).
func home_point() -> Array:
	if not owns_house() or mj.city == null:
		return []
	var l = mj.city.lieux
	var inside: Vector3 = l.chaumiere_inside
	var to_door: Vector3 = l.chaumiere_door - inside
	to_door.y = 0.0
	return [inside + Vector3.UP * 0.3, to_door.normalized() if to_door.length() > 0.01 else Vector3(0, 0, 1)]


func _apply_house() -> void:
	var own: bool = owns_house()
	if own == _gate_open or mj.city == null:
		return
	_gate_open = own
	var g: Node3D = mj.city.lieux.chaumiere_gate
	if g != null and is_instance_valid(g):
		# la porte s'ouvre : le vantail pivote contre le mur, la collision s'en va
		g.rotate_object_local(Vector3.UP, -PI * 0.5 if own else PI * 0.5)
		g.translate_object_local(Vector3(-0.6, 0, -0.6) if own else Vector3(0.6, 0, 0.6))
		for c in g.get_children():
			if c is StaticBody3D:
				for cs in c.get_children():
					if cs is CollisionShape3D:
						(cs as CollisionShape3D).set_deferred("disabled", own)


func _sleep() -> void:
	if main.get("temps_v56") == null:
		return
	state["nuits_chaumiere"] = int(state["nuits_chaumiere"]) + 1
	mj.sfx("lit_dodo", mj.city.lieux.chaumiere_bed)
	var h: float = mj.hour()
	main.temps_v56.sleep_until(7.0 if (h >= 17.0 or h < 6.0) else 19.0)
	mj.say("Vous vous glissez sous la couette bleue de la Chaumière. Les glycines sentent bon. Quelque part, une grenouille coasse. Zzz…", 5.0)


## L'étagère à trophées : une icône par relique qu'on possède (mise à jour de temps en temps).
## V72 : une relique reste sur l'étagère même après avoir été rendue à son destinataire.
func _note_trophies() -> void:
	var inv: Node = main.get("inventory_v28")
	if inv == null:
		return
	var got: Array = state["trophees"]
	for id in TROPHEES:
		if not got.has(str(id)) and inv.count(str(id)) > 0:
			got.append(str(id))


func _apply_shelf() -> void:
	_note_trophies()
	if mj.city == null or not owns_house():
		return
	var have: Array = []
	for id in TROPHEES:
		if (state["trophees"] as Array).has(str(id)):
			have.append(str(id))
	var key: String = ",".join(have)
	if key == _shelf_key:
		return
	_shelf_key = key
	if _shelf_root != null:
		_shelf_root.queue_free()
	_shelf_root = Node3D.new()
	_shelf_root.name = "Etagere_trophees"
	mj.add_child(_shelf_root)
	var xf: Transform3D = mj.city.lieux.chaumiere_shelf
	for i in range(have.size()):
		var path: String = "res://assets/textures/items/%s.png" % have[i]
		if not ResourceLoader.exists(path):
			_shelf_gem(have[i], xf * Transform3D(Basis(), Vector3(-1.0 + (i % 5) * 0.5, 1.37 + (i / 5) * 0.7, 0.22)))
			continue
		var s := Sprite3D.new()
		s.texture = load(path)
		s.pixel_size = 0.0035
		s.shaded = true
		s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
		var row: int = i / 5
		var col: int = i % 5
		_shelf_root.add_child(s)
		s.global_transform = xf * Transform3D(Basis(), Vector3(-1.0 + col * 0.5, 1.37 + row * 0.7, 0.22))


## V72 : les reliques sans image : un petit objet qui luit, avec son nom sur une étiquette.
const GEM_COLORS := {"coeur_gelee": Color(0.4, 0.9, 0.35), "flamme_eternelle": Color(1.0, 0.45, 0.1), "oeil_horus": Color(0.2, 0.45, 1.0),
	"masque_jade": Color(0.2, 0.75, 0.45), "plume_quetzal": Color(0.25, 0.85, 0.6), "graine_yggdrasil": Color(0.85, 0.75, 0.3),
	"cristal_orage": Color(0.55, 0.6, 1.0), "banniere_gobelin": Color(0.75, 0.2, 0.15), "carte_aventurier": Color(0.9, 0.8, 0.55),
	"navet_dore": Color(1.0, 0.82, 0.25)}

func _shelf_gem(id: String, xf: Transform3D) -> void:
	var c: Color = GEM_COLORS.get(id, Color(0.9, 0.85, 0.6))
	var holder := Node3D.new()
	_shelf_root.add_child(holder)
	holder.global_transform = xf
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.08
	sm.height = 0.16
	mi.mesh = sm
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.25
	m.metallic = 0.3
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = 0.6
	mi.material_override = m
	mi.position = Vector3(0, 0.1, 0)
	holder.add_child(mi)
	var lb := Label3D.new()
	var inv: Node = main.get("inventory_v28")
	lb.text = str(inv.ITEMS.get(id, {}).get("name", id)) if inv != null else id
	lb.pixel_size = 0.0009
	lb.font_size = 32
	lb.outline_size = 6
	lb.modulate = Color(1.0, 0.95, 0.8)
	lb.position = Vector3(0, -0.04, 0.06)
	holder.add_child(lb)

# =================================================================== la grande alerte aux navets

func _start_alert() -> void:
	var ms: Node = main.get("monstres_v36")
	if ms == null or alert_on:
		return
	alert_on = true
	_alert_left = ALERT_TIME
	_caught_now = 0
	state["alertes"] = int(state["alertes"]) + 1
	var bell: Vector3 = mj.city.lieux.crier_bell
	mj.sfx("alerte_cloche", bell)
	mj.sfx("alerte_cloche", main._player_pos_v27())
	mj.say("DING DING DING ! Mélusine hurle depuis la Grand-Place : « ALERTE ! ALERTE ! Tous les aventuriers aux Champs du Sud : LES NAVETS SE SONT RÉVEILLÉS ! Attrapez-les avant qu'ils ne se replantent ! »", 9.0)
	var fr: Rect2 = RM.FIELDS
	for i in range(NAVETS):
		var l := Vector2(_rng.randf_range(fr.position.x + 4.0, fr.end.x - 4.0), _rng.randf_range(fr.position.y + 4.0, fr.end.y - 4.0))
		var at: Vector3 = RM.W(l.x, l.y)
		at.y = mj.ile.height(at.x, at.z) + 0.2
		var m: Node3D = ms.spawn_extra("navet", at)
		if m != null:
			m.set("home", at)
			_navets.append(m)


func _tick_alert(delta: float) -> void:
	_alert_left -= delta
	var alive: Array = []
	for m in _navets:
		if is_instance_valid(m) and str(m.get("state")) != "mort":
			alive.append(m)
		else:
			_caught_now += 1
			state["navets"] = int(state["navets"]) + 1
	_navets = alive
	if _alert_left <= 0.0 or _navets.is_empty():
		_end_alert(false)


func _end_alert(silent: bool) -> void:
	for m in _navets:
		if is_instance_valid(m):
			m.queue_free()
	_navets.clear()
	if not alert_on:
		return
	alert_on = false
	_alert_wait = _rng.randf_range(900.0, 1500.0)
	if silent:
		return
	state["record"] = maxi(int(state["record"]), _caught_now)
	if _caught_now <= 0:
		mj.say("Fin de l'alerte : les navets se sont tous replantés, l'air innocent. Père Gaubert soupire : « Ils recommenceront. Ils recommencent toujours. »", 7.0)
		return
	mj.say("Fin de l'alerte ! Vous avez attrapé %d navet%s. Mélusine, enrouée : « Bravo… (tousse) … à tous… (tousse) ! » Les navets dorés se revendent à la Guilde." % [_caught_now, "s" if _caught_now > 1 else ""], 7.0)
	if mj.guilde != null:
		mj.guilde.add_points(mini(_caught_now * 2, 20), "alerte aux navets")


## Pendant l'alerte, les Champs du Sud sont « hostiles » (les navets sont éveillés).
func hostile_zone(p: Vector3) -> bool:
	if not alert_on:
		return false
	return RM.FIELDS.grow(30.0).has_point(RM.L(p.x, p.z))


func zone_override(p: Vector3) -> String:
	if alert_on and RM.FIELDS.grow(20.0).has_point(RM.L(p.x, p.z)):
		return "mj_alerte"
	return ""


# =================================================================== les invites, les services

func register_interactions(d: Node) -> void:
	var me = self
	var l = mj.city.lieux
	mj._ia(d, {"id": "mj_lit", "pos": l.chaumiere_bed, "radius": 1.8, "text": "E : dormir dans votre lit", "vr": "Gâchette : dormir",
		"call": func(): me._sleep(), "when": func(): return me.owns_house()})
	mj._ia(d, {"id": "mj_porte_chaumiere", "pos": l.chaumiere_door, "radius": 1.6, "text": "E : la porte est fermée à clé (« À vendre — voir Monsieur Prosper »)",
		"vr": "Gâchette : la porte est fermée à clé", "call": func(): me._locked(), "when": func(): return not me.owns_house()})


func _locked() -> void:
	mj.say("Fermé à clé. Une pancarte : « À VENDRE. Chaumière des Glycines, vue imprenable, glycine incluse, grenouilles en option. S'adresser à Monsieur Prosper, Haute-Ville. »", 6.0)


func register_services(journal: Node) -> void:
	journal.lieux["chaumiere"] = mj.city.lieux.chaumiere_door


func after_reply(_r: Dictionary, _npc: Node) -> void:
	_apply_house()


## La grenouille a avalé le joueur (appelé par compagnons_v71 / monstre_v71, s'ils le veulent).
func on_swallowed() -> void:
	state["avale"] = int(state["avale"]) + 1


func _process(delta: float) -> void:
	if main == null or mj == null or mj.ile == null:
		return
	_tick_t -= delta
	if _tick_t <= 0.0:
		_tick_t = 1.0
		_apply_house()
		_apply_shelf()
		_apply_hat()
	if alert_on:
		_tick_alert(delta)
		return
	# l'alerte ne sonne que le jour, quand on est sur l'île (et pas dans le donjon)
	var p: Vector3 = main._player_pos_v27()
	if not mj.ile.contains(p.x, p.z) or p.y < -20.0 or not bool(main.get("game_started")):
		return
	var h: float = mj.hour()
	if h < 8.0 or h > 18.0:
		return
	_alert_wait -= delta
	if _alert_wait <= 0.0:
		_start_alert()


## Le chapeau du Baron disparaît de l'épouvantail quand on l'a ramassé (ou rendu).
func _apply_hat() -> void:
	var hat: Node3D = mj.dehors.scarecrow_hat if mj.dehors != null else null
	if hat == null:
		return
	var j: Node = main.get("journal_v56")
	var inv: Node = main.get("inventory_v28")
	var gone: bool = false
	if inv != null and (inv.count("chapeau_baron") > 0 or (inv.taken as Dictionary).has("q56_mj_chapeau_chapeau_baron")):
		gone = true
	if j != null and str(j.state("mj_chapeau")) == "finie":
		gone = true
	hat.visible = not gone
