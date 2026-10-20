extends Node3D
## V50 : les bruitages d'action.
## play("nom", position) joue une variante au hasard d'un bruitage (www/assets/sons/sfx/
## nom_1.ogg, nom_2.ogg…), placé dans le monde (son 3D) ou non (interface) si on ne donne
## pas de position. Hauteur légèrement variée à chaque fois pour éviter l'effet « disque
## rayé ». Les pas suivent la marche du joueur et changent selon le sol (herbe, sable, pierre,
## bois, cendre, eau) ; la barque fait clapoter l'eau quand elle avance.
## Tous les sons passent par le bus « Bruitages ».

const DIR := "res://assets/sons/sfx/"
## Volume (dB) de chaque famille de bruitages ; 0 par défaut.
const DB := {
	"pas_herbe": -15.0, "pas_sable": -16.0, "pas_pierre": -15.0, "pas_bois": -13.0, "pas_cendre": -14.0, "pas_eau": -14.0,
	"atterrissage": -8.0, "fendre_air": -8.0, "fendre_lourd": -6.0, "touche_chair": -4.0, "touche_lourd": -3.0,
	"touche_pierre": -4.0, "touche_carapace": -4.0, "touche_bois": -5.0, "parade": -4.0, "jarre_casse": -4.0,
	"joueur_blesse": -6.0, "ramasse": -8.0, "ramasse_pieces": -8.0, "ramasse_gemme": -9.0, "ramasse_pierre": -8.0,
	"ramasse_bois": -8.0, "manger": -6.0, "jeter": -8.0, "equiper": -10.0, "coffre": -3.0, "porte_ouvre": -5.0,
	"porte_ferme": -5.0, "grille": -3.0, "pierre_glisse": -2.0, "serrure": -6.0, "hache": -4.0, "arbre_tombe": -2.0,
	"pelle": -6.0, "lancer": -10.0, "plouf": -6.0, "gros_plouf": -5.0, "moulinet": -14.0, "ferrage": -8.0, "rame": -14.0,
	"ui_ouvrir": -12.0, "ui_fermer": -12.0, "ui_choix": -14.0, "ui_clic": -14.0, "ui_dialogue": -12.0, "ui_erreur": -10.0,
	"ui_quete": -8.0, "boss_cri": 0.0,
	"plongeon": -4.0, "nage": -8.0, "nage_sous": -9.0, "bulles": -10.0, "respiration": -6.0, "suffoque": -4.0,
	"requin_menace": -3.0, "requin_morsure": -2.0, "requin_mort": -3.0, "meduse_pique": -5.0, "dauphin": -6.0,
	"perle": -4.0, "cristal_eveil": 0.0,
	"cloche": -3.0, "cloche_bateau": -5.0, "corne_brume": -2.0,
}
const STRIDE: float = 0.72          # un pas tous les 72 cm

var main: Node
var variants: Dictionary = {}       # nom -> [AudioStream]
var _pool3d: Array = []
var _pool2d: Array = []
var _i3: int = 0
var _i2: int = 0
var _rng := RandomNumberGenerator.new()
var _walked: float = 0.0
var _last_pos: Vector3 = Vector3.INF
var _paddle: float = 0.0
var last_played: String = ""        # pour les tests
var played: Dictionary = {}         # nom -> nombre de fois joué (pour les tests)
var surface: String = ""


func setup(main_node: Node) -> void:
	main = main_node
	_rng.randomize()
	var bus: int = AudioServer.get_bus_index("Bruitages")
	if bus < 0:
		AudioServer.add_bus()
		bus = AudioServer.bus_count - 1
		AudioServer.set_bus_name(bus, "Bruitages")
		AudioServer.set_bus_send(bus, "Master")
	for i in range(16):
		var p := AudioStreamPlayer3D.new()
		p.name = "Bruitage3D_%d" % i
		p.bus = "Bruitages"
		p.unit_size = 4.0
		p.max_distance = 45.0
		p.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		add_child(p)
		_pool3d.append(p)
	for i in range(6):
		var q := AudioStreamPlayer.new()
		q.name = "Bruitage2D_%d" % i
		q.bus = "Bruitages"
		add_child(q)
		_pool2d.append(q)
	for name in DB:
		_variants(str(name))


func _variants(name: String) -> Array:
	if variants.has(name):
		return variants[name]
	var list: Array = []
	for k in range(1, 9):
		var path: String = DIR + "%s_%d.ogg" % [name, k]
		if not ResourceLoader.exists(path):
			break
		list.append(load(path))
	variants[name] = list
	return list


## Joue un bruitage. at = position dans le monde (null : son d'interface, sans position).
func play(name: String, at: Variant = null, db: float = 0.0, pitch_spread: float = 0.08) -> void:
	var list: Array = _variants(name)
	if list.is_empty():
		return
	var stream: AudioStream = list[_rng.randi() % list.size()]
	var vol: float = float(DB.get(name, 0.0)) + db
	var pitch: float = 1.0 + _rng.randf_range(-pitch_spread, pitch_spread)
	last_played = name
	played[name] = int(played.get(name, 0)) + 1
	if at == null:
		var q: AudioStreamPlayer = _pool2d[_i2]
		_i2 = (_i2 + 1) % _pool2d.size()
		q.stream = stream
		q.volume_db = vol
		q.pitch_scale = pitch
		q.play()
		return
	var p: AudioStreamPlayer3D = _pool3d[_i3]
	_i3 = (_i3 + 1) % _pool3d.size()
	p.global_position = at
	p.stream = stream
	p.volume_db = vol
	p.pitch_scale = pitch
	var d: Node = main.get("donjon_v35")
	p.bus = "Ambiance_grotte" if d != null and d.is_inside(at) and AudioServer.get_bus_index("Ambiance_grotte") >= 0 else "Bruitages"
	p.play()


## Joué à la position du joueur.
func here(name: String, db: float = 0.0) -> void:
	play(name, main._player_pos_v27() + Vector3.UP * 0.8, db)


# =================================================================== pas et barque

func _process(delta: float) -> void:
	if main == null or not bool(main.game_started):
		_last_pos = Vector3.INF
		return
	# V54 : en vol sur Ventaile, pas de pas (les ailes s'entendent, voir ciel_v54.gd)
	var sky: Node = main.get("ciel_v54")
	if sky != null and bool(sky.riding):
		_last_pos = Vector3.INF
		return
	# V55 : en nageant, pas de pas (les brasses s'entendent, voir mer_v55.gd)
	var sea: Node = main.get("mer_v55")
	if sea != null and bool(sea.swimming):
		_last_pos = Vector3.INF
		return
	var boat: Node = main.get("boat_v29")
	if boat != null and bool(boat.driving):
		_last_pos = Vector3.INF
		# La rame : un clapotis à chaque coup de rame, plus rapproché quand on va vite.
		var spd: float = absf(float(boat.speed))
		if spd > 0.4:
			_paddle -= delta * clampf(spd / 3.0, 0.4, 1.4)
			if _paddle <= 0.0:
				_paddle = 1.1
				play("rame", boat.hull.global_position + Vector3.UP * 0.2)
		return
	var body: CharacterBody3D = main.vr_body if bool(main.xr_active) else main.pc_body
	if body == null:
		return
	var pos: Vector3 = body.global_position
	if _last_pos == Vector3.INF or pos.distance_to(_last_pos) > 3.0:
		_last_pos = pos
		return
	var step: float = Vector2(pos.x - _last_pos.x, pos.z - _last_pos.z).length()
	_last_pos = pos
	# L'image peut être plus rapide que la physique : une image sans déplacement ne remet
	# pas le compteur à zéro ; seul le saut (pieds en l'air) le fait.
	if not body.is_on_floor():
		_walked = minf(_walked, STRIDE * 0.5)
		return
	if step < 0.0005:
		return
	_walked += step
	if _walked >= STRIDE:
		_walked = 0.0
		surface = _surface(body)
		play("pas_" + surface, pos + Vector3.UP * 0.05, 0.0, 0.1)


## La matière sous les pieds : d'après le corps physique touché, sinon l'altitude.
func _surface(body: CharacterBody3D) -> String:
	var pos: Vector3 = body.global_position
	var space := body.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(pos + Vector3.UP * 0.4, pos + Vector3.DOWN * 1.2, 1, [body.get_rid()])
	var hit := space.intersect_ray(q)
	var name: String = str(hit.collider.name) if not hit.is_empty() and hit.collider != null else ""
	var d: Node = main.get("donjon_v35")
	if d != null and d.is_inside(pos):
		return "pierre"
	if name.contains("Ponton") or name.begins_with("Interieur_") or name.begins_with("Elfes_collision") or name.contains("Tronc"):
		return "bois"
	# V54 : la Citadelle (pierre), le nid (pierre), la prairie de l'île flottante (herbe)
	if name.begins_with("Ciel_chateau") or name.begins_with("Nid_collision"):
		return "pierre"
	if name.begins_with("Ciel_sol"):
		return "herbe"
	# V55 : sous le dôme de l'Atlantide, tout est marbre et mosaïque
	var sea2: Node = main.get("mer_v55")
	if sea2 != null and sea2.atl != null and sea2.atl.in_dome(pos + Vector3.UP * 0.9):
		return "pierre"
	if name.begins_with("Donjon") or name.begins_with("Nains_collision") or name.begins_with("Falaise") or name.begins_with("Village_collision") or name.begins_with("Royaume"):
		return "pierre"
	var h: float = main._height_at(pos.x, pos.z)
	if h < -0.12:
		return "eau"
	if name.begins_with("Sol_nains"):
		# Le dallage de la terrasse de Forgefer est posé sur le sol de l'île.
		var n: Node = main.get("nains_v46")
		if n != null and n.forge_root != null:
			var c: Vector3 = (n.forge_root as Node3D).global_position
			if Vector2(pos.x - c.x, pos.z - c.z).length() < float(n.ile.TERRACE_SIZE) - 1.0 and absf(pos.y - c.y) < 2.5:
				return "pierre"
		return "sable" if h < 1.2 else "cendre"
	if h < 1.4:
		return "sable"
	return "herbe"
