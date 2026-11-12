

# ======================= OUTILS COMMUNS DES SÉRIES (tests/series/_commun.gd)
# Chaque série est collée à la fin de main.gd (elle voit donc tout le jeu) ; elle définit
# NOM et _serie(). Ce fichier lance la partie, compte les échecs et termine proprement.
var _af := 0
var _errs: Array = []
var _t_serie := 0


func _process(_d: float) -> void:
	_af += 1
	if _af == 3:
		_lancer()


func _lancer() -> void:
	_t_serie = Time.get_ticks_msec()
	await _att(1.0)
	game_menu._load_or_create(1, true)
	await _att(6.0)
	game_started = true
	testeur_v78.invincible = true
	await _att(1.0)
	await _serie()
	print("SERIE_FINIE %s erreurs %s (%.0f s)" % [NOM, str(_errs), (Time.get_ticks_msec() - _t_serie) / 1000.0])
	get_tree().quit()


func _att(t: float) -> void:
	await get_tree().create_timer(t).timeout


func _images(n: int) -> void:
	for i in n:
		await get_tree().process_frame


## Une vérification : OK ou FAIL, et l'échec est retenu pour le bilan.
func _ok(cond: bool, quoi: String) -> bool:
	print(("OK   " if cond else "FAIL ") + quoi)
	if not cond:
		_errs.append(quoi)
	return cond


## Pour les grands passages en revue : on note sans afficher chaque réussite.
func _note(cond: bool, quoi: String) -> bool:
	if not cond:
		print("FAIL " + quoi)
		_errs.append(quoi)
	return cond


func _pos() -> Vector3:
	return _player_pos_v27()


func _poser(p: Vector3, face: Vector3 = Vector3.FORWARD) -> void:
	place_player_v35(p, face)
	await _att(0.3)


func _touche(k: Key, bas: bool) -> void:
	var ev := InputEventKey.new()
	ev.keycode = k
	ev.physical_keycode = k
	ev.pressed = bas
	Input.parse_input_event(ev)


func _appui(k: Key) -> void:
	_touche(k, true)
	await _images(2)
	_touche(k, false)
	await _images(2)


## Ferme tout ce qui peut être ouvert (dialogue, sac, maison, monture) et remet le héros en forme.
func _ranger() -> void:
	_close_dialogue_v31()
	if inventory_v28 != null and inventory_v28.opened:
		inventory_v28.close()
	if maisons_v81 != null and maisons_v81.inside:
		maisons_v81._teardown()
	if aeronef_v76 != null and bool(aeronef_v76.get("riding")) and aeronef_v76.has_method("force_end"):
		aeronef_v76.force_end()
	if hero_v28 != null:
		hero_v28.heal(999)
	get_tree().paused = false


## Le héros tient-il debout là où il est (pas tombé sous le monde, pas en chute sans fin) ?
func _debout(quoi: String, attente: float = 1.2) -> bool:
	# (certaines villes sont sous terre ou sous la mer : on regarde la chute, pas l'altitude ;
	# une petite marche à l'arrivée est normale, une chute qui continue ne l'est pas)
	# (on peut aussi arriver sur un décor et retomber sur le sol juste dessous : c'est noté, pas un échec)
	var p0: Vector3 = _pos()
	await _att(attente)
	var p1: Vector3 = _pos()
	if p0.y - p1.y < 3.0:
		return true
	var prev: Vector3 = p1
	for k in range(3):
		await _att(1.5)
		var p: Vector3 = _pos()
		if prev.y - p.y < 1.0 and p.y > -400.0:
			print("  note : %s, chute de %.0f m à l'arrivée (%.1f -> %.1f)" % [quoi, p0.y - p.y, p0.y, p.y])
			return true
		prev = p
	return _note(false, "%s : le héros tombe sans fin (%.1f -> %.1f)" % [quoi, p0.y, prev.y])
