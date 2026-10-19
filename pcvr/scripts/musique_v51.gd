extends Node
## V51 : la musique (compositions orchestrales originales, pcvr/tools/compose_musique_v51.py).
##  - Un morceau par lieu, choisi d'après la zone des ambiances (village, jungle, île des elfes,
##    île des nains et Forgefer, grand large, souterrains, Royaume des Racines).
##    Le morceau est joué une fois, puis on laisse respirer les ambiances (40 à 90 s de
##    silence) avant de le rejouer. Changement de lieu : fondu enchaîné.
##  - Le thème de l'île boucle sur le menu.
##  - Le morceau de combat prend le relais pendant les combats de boss et quand des monstres
##    attaquent ; il s'efface quelques secondes après le dernier coup.
##  - Deux jingles : « victoire » (boss vaincu) et « découverte » (grand coffre, porte
##    monumentale). La musique baisse pendant qu'ils sonnent.
##  - Réglages de volume (musique, bruitages, ambiances) enregistrés dans user://reglages_son.cfg.
## Tout passe par le bus « Musique ».

const DIR := "res://assets/sons/musique/"
const SETTINGS := "user://reglages_son.cfg"
const ZONE_TRACK := {
	"menu": "theme_ile", "village": "village", "jungle": "jungle", "elfes": "elfes", "nains": "nains",
	"forgefer": "nains", "large": "large", "souterrain": "souterrain", "racines": "racines",
	"ciel": "ciel", "chateau": "ciel", "vol": "ciel",
	"sous_marin": "atlantide", "atlantide": "atlantide",
}
## Volume de chaque morceau (dB) quand il est à fond.
const TRACK_DB := {
	"theme_ile": -5.0, "village": -9.0, "jungle": -10.0, "elfes": -8.0, "nains": -9.0, "large": -8.0,
	"souterrain": -8.0, "racines": -8.0, "combat": -7.0, "victoire": -4.0, "decouverte": -5.0, "ciel": -8.0, "atlantide": -8.0,
}
const LOOPED := ["theme_ile", "combat"]
const FADE := 0.4                    # vitesse des fondus (part du volume par seconde)
const END_FADE := 4.0                # un morceau joué une fois s'éteint sur ses 4 dernières secondes
const COMBAT_RANGE := 20.0
const COMBAT_HOLD := 6.0

var main: Node
var tracks: Dictionary = {}          # nom -> {player, cur, target}
var current: String = ""             # morceau voulu (ou "" pendant un silence)
var zone_track: String = ""
var combat: bool = false
var rest: float = 0.0                # silence avant de rejouer le morceau du lieu
var volumes: Dictionary = {"musique": 1.0, "bruitages": 1.0, "ambiances": 1.0}
var plays: Dictionary = {}           # nom -> nombre de lancements (pour les tests)
var _jingle: AudioStreamPlayer
var _tick: float = 0.0
var _pending: String = ""            # lieu en attente de confirmation (anti-va-et-vient)
var _pending_t: float = 0.0
var _combat_t: float = 0.0           # depuis quand des monstres attaquent
var _combat_hold: float = 0.0
var _rng := RandomNumberGenerator.new()
var bus: int = -1


func setup(main_node: Node) -> void:
	main = main_node
	_rng.randomize()
	bus = AudioServer.get_bus_index("Musique")
	if bus < 0:
		AudioServer.add_bus()
		bus = AudioServer.bus_count - 1
		AudioServer.set_bus_name(bus, "Musique")
		AudioServer.set_bus_send(bus, "Master")
	for name in TRACK_DB:
		if name in ["victoire", "decouverte"]:
			continue
		var p := AudioStreamPlayer.new()
		p.name = "Musique_" + str(name)
		p.bus = "Musique"
		p.volume_db = -80.0
		var s: AudioStream = _load(str(name))
		if s is AudioStreamOggVorbis:
			s = (s as AudioStreamOggVorbis).duplicate()
			(s as AudioStreamOggVorbis).loop = str(name) in LOOPED
		p.stream = s
		add_child(p)
		tracks[name] = {"player": p, "cur": 0.0, "target": 0.0}
	_jingle = AudioStreamPlayer.new()
	_jingle.name = "Musique_jingle"
	_jingle.bus = "Musique"
	add_child(_jingle)
	load_settings()


func _load(name: String) -> AudioStream:
	var path: String = DIR + name + ".ogg"
	return load(path) if ResourceLoader.exists(path) else null


# =================================================================== réglages

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS) == OK:
		for k in volumes:
			volumes[k] = clampf(float(cfg.get_value("volume", k, 1.0)), 0.0, 1.0)
	apply_volumes()


func save_settings() -> void:
	var cfg := ConfigFile.new()
	for k in volumes:
		cfg.set_value("volume", k, volumes[k])
	cfg.save(SETTINGS)


func apply_volumes() -> void:
	var base := {"musique": ["Musique", 0.0], "bruitages": ["Bruitages", 0.0], "ambiances": ["Ambiance", -2.0]}
	for k in base:
		var i: int = AudioServer.get_bus_index(str(base[k][0]))
		if i < 0:
			continue
		var v: float = float(volumes[k])
		AudioServer.set_bus_mute(i, v <= 0.001)
		AudioServer.set_bus_volume_db(i, float(base[k][1]) + (linear_to_db(v) if v > 0.001 else -60.0))


## Menu Paramètres : 100 % -> 75 -> 50 -> 25 -> 0 -> 100 %.
func cycle_volume(k: String) -> void:
	var v: float = float(volumes.get(k, 1.0))
	v = 1.0 if v <= 0.001 else snappedf(v - 0.25, 0.25)
	volumes[k] = clampf(v, 0.0, 1.0)
	apply_volumes()
	save_settings()


func volume_label(k: String) -> String:
	var names := {"musique": "Musique", "bruitages": "Bruitages", "ambiances": "Ambiances"}
	var v: int = int(round(float(volumes.get(k, 1.0)) * 100.0))
	return "%s : %s" % [names[k], ("coupée" if v == 0 else "%d %%" % v)]


# =================================================================== jingles

func jingle(name: String) -> void:
	var s: AudioStream = _load(name)
	if s == null:
		return
	_jingle.stream = s
	_jingle.volume_db = float(TRACK_DB.get(name, -5.0))
	_jingle.play()
	plays[name] = int(plays.get(name, 0)) + 1


# =================================================================== chaque image

func _process(delta: float) -> void:
	if main == null:
		return
	_tick -= delta
	if _tick <= 0.0:
		_decide(0.25 - _tick)
		_tick = 0.25
	var duck: float = 0.3 if _jingle.playing else 1.0
	for k in tracks:
		var t: Dictionary = tracks[k]
		var p: AudioStreamPlayer = t["player"]
		var target: float = float(t["target"])
		# un morceau joué une fois s'éteint doucement avant sa fin
		if p.playing and not (str(k) in LOOPED) and p.stream != null:
			var left: float = p.stream.get_length() - p.get_playback_position()
			if left < END_FADE:
				target = minf(target, clampf(left / END_FADE, 0.0, 1.0))
		var cur: float = move_toward(float(t["cur"]), target, delta * FADE)
		t["cur"] = cur
		if cur > 0.001 and p.playing:
			p.volume_db = float(TRACK_DB[k]) + linear_to_db(cur * duck)
		elif cur <= 0.001 and p.playing and target <= 0.001:
			p.stop()


func _decide(dt: float) -> void:
	var running: bool = bool(main.game_started)
	var amb: Node = main.get("ambiance_v49")
	var z: String = "menu" if not running else (str(amb.zone) if amb != null and str(amb.zone) != "" else "village")
	var want_zone: String = str(ZONE_TRACK.get(z, ""))
	# --- combat
	var fighting: bool = running and _fighting()
	if fighting:
		_combat_t += dt
		_combat_hold = COMBAT_HOLD
	else:
		_combat_t = 0.0
		_combat_hold = maxf(0.0, _combat_hold - dt)
	var boss: bool = running and _boss_fight()
	if boss:
		_combat_hold = COMBAT_HOLD
	var was_combat: bool = combat
	combat = boss or (combat and _combat_hold > 0.0) or (fighting and _combat_t >= 1.0)
	if combat:
		_switch("combat")
		return
	if was_combat:
		# après le combat : un court silence, puis la musique du lieu reprend
		zone_track = want_zone
		_pending = ""
		_switch("")
		rest = 4.0
		return
	# --- lieu : on attend que le changement soit confirmé (4 s) avant de changer de morceau
	if want_zone != zone_track:
		if _pending != want_zone:
			_pending = want_zone
			_pending_t = 0.0
		_pending_t += dt
		if _pending_t >= 4.0 or zone_track == "" or not running or zone_track == "theme_ile":
			zone_track = want_zone
			_pending = ""
			rest = 0.0
			_switch(zone_track)
			return
	else:
		_pending = ""
	# --- le morceau du lieu est fini : silence, puis on le rejoue
	if current != "" and current == zone_track and not (current in LOOPED):
		var p: AudioStreamPlayer = tracks[current]["player"]
		if not p.playing:
			current = ""
			rest = _rng.randf_range(40.0, 90.0)
	if current == "":
		rest -= dt
		if rest <= 0.0 and zone_track != "":
			_switch(zone_track)


## Fondu vers un morceau (relancé depuis le début s'il était éteint) ; "" : silence.
func _switch(name: String) -> void:
	if name == current:
		if name != "" and not (tracks[name]["player"] as AudioStreamPlayer).playing:
			_start(name)
		return
	for k in tracks:
		tracks[k]["target"] = 0.0
	current = name
	if name != "" and tracks.has(name):
		_start(name)


func _start(name: String) -> void:
	var t: Dictionary = tracks[name]
	var p: AudioStreamPlayer = t["player"]
	t["target"] = 1.0
	if p.stream == null:
		return
	if not p.playing:
		t["cur"] = 0.25
		p.volume_db = float(TRACK_DB[name]) + linear_to_db(0.25)
		p.play(0.0)
		plays[name] = int(plays.get(name, 0)) + 1


## Des monstres attaquent le joueur tout près ?
func _fighting() -> bool:
	var ms: Node = main.get("monstres_v36")
	if ms == null:
		return false
	var p: Vector3 = main._player_pos_v27()
	for m in ms.monsters:
		if is_instance_valid(m) and str(m.state) in ["chasse", "armer", "frappe", "souffle"] and m.global_position.distance_to(p) < COMBAT_RANGE:
			return true
	return false


## Un combat de boss est-il en cours (Karkinos, Nâga, la Reine des Ronces) ?
func _boss_fight() -> bool:
	var d: Node = main.get("donjon_v35")
	if d != null:
		if bool(d.fight):
			return true
		if d.antre != null and bool(d.antre.fight):
			return true
	var el: Node = main.get("elfes_v41")
	if el != null and el.feerique != null and el.feerique.ronces != null and bool(el.feerique.ronces.fight):
		return true
	# V54 : Sire Orage, au sommet de la Tour des Tempêtes
	var sky: Node = main.get("ciel_v54")
	if sky != null and bool(sky.fight):
		return true
	return false
