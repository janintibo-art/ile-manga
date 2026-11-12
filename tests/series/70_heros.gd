## Le héros : marcher (ZQSD), sauter, courir (l'endurance baisse), nager, tomber de haut,
## lever les yeux au ciel, se relever après un évanouissement, et le niveau qui donne du souffle.
const NOM := "heros"


func _sol() -> void:
	for k in range(60):
		if str(hero_v28.state) == "sol":
			return
		await _att(0.05)


func _mer_proche() -> Vector3:
	var c: Vector3 = _pos()
	for d in range(30, 400, 10):
		for a in range(0, 360, 20):
			var q := Vector3(c.x + cos(deg_to_rad(a)) * d, 0, c.z + sin(deg_to_rad(a)) * d)
			if _height_at(q.x, q.z) < -4.0 and mer_v55.is_sea(q):
				return q
	return Vector3.INF


func _serie() -> void:
	testeur_v78._list = testeur_v78._islands()
	testeur_v78._go(0)
	await _att(0.5)
	await _sol()
	# --- marcher : Z (clavier AZERTY)
	var p0: Vector3 = _pos()
	_touche(KEY_Z, true)
	await _att(1.2)
	_touche(KEY_Z, false)
	await _att(0.3)
	var d: float = Vector2(_pos().x - p0.x, _pos().z - p0.z).length()
	_ok(d > 2.0, "Z : le héros avance (%.1f m)" % d)
	# --- sauter
	await _sol()
	var y0: float = _pos().y
	var haut: float = y0
	var air: bool = false
	_touche(KEY_SPACE, true)
	for k in range(30):
		await _images(1)
		haut = maxf(haut, _pos().y)
		air = air or str(hero_v28.state) == "air"
	_touche(KEY_SPACE, false)
	_ok(air and haut > y0 + 0.4, "espace : le héros saute (%.2f m)" % (haut - y0))
	await _att(1.0)
	await _sol()
	# --- courir : l'endurance baisse
	hero_v28.stamina = float(hero_v28.STAMINA_MAX)
	_touche(KEY_SHIFT, true)
	_touche(KEY_Z, true)
	await _att(1.5)
	_touche(KEY_Z, false)
	_touche(KEY_SHIFT, false)
	_ok(float(hero_v28.stamina) < float(hero_v28.STAMINA_MAX) - 0.5, "Maj + Z : il court, l'endurance baisse (%.1f / %.1f)" % [float(hero_v28.stamina), float(hero_v28.STAMINA_MAX)])
	await _att(0.5)
	# --- lever les yeux au ciel (clic droit + souris vers le haut)
	var mb := InputEventMouseButton.new()
	mb.button_index = MOUSE_BUTTON_RIGHT
	mb.pressed = true
	Input.parse_input_event(mb)
	await _images(2)
	for k in range(6):
		var mm := InputEventMouseMotion.new()
		mm.relative = Vector2(0, -60)
		mm.button_mask = MOUSE_BUTTON_MASK_RIGHT
		Input.parse_input_event(mm)
		await _images(2)
	mb = InputEventMouseButton.new()
	mb.button_index = MOUSE_BUTTON_RIGHT
	mb.pressed = false
	Input.parse_input_event(mb)
	await _images(2)
	_ok(float(hero_v28.cam_pitch) < -0.2, "clic droit + souris : le regard se lève (%.2f)" % float(hero_v28.cam_pitch))
	hero_v28.cam_pitch = 0.0
	# --- nager
	var mer: Vector3 = _mer_proche()
	if _ok(mer != Vector3.INF, "une mer près du village"):
		await _poser(Vector3(mer.x, 0.3, mer.z))
		await _att(1.2)
		_ok(bool(mer_v55.swimming) and str(hero_v28.state) == "nage", "dans la mer, le héros nage (%s)" % str(hero_v28.state))
	# --- tomber de haut : ça fait mal
	testeur_v78._go(0)
	await _att(0.6)
	await _sol()
	testeur_v78.invincible = false
	hero_v28.hp = hero_v28.HP_MAX
	var q: Vector3 = _pos()
	place_player_v35(q + Vector3.UP * 16.0, hero_v28.facing)
	await _att(3.0)
	_ok(hero_v28.hp < hero_v28.HP_MAX, "chute de 16 m : le héros a mal (%d / %d)" % [hero_v28.hp, hero_v28.HP_MAX])
	# --- évanoui, il se relève
	hero_v28.hurt(999, _pos() + Vector3(1, 0, 0))
	await _att(6.0)
	_ok(hero_v28.hp > 0 and str(hero_v28.state) != "ko", "évanoui, il se relève (vie %d, %s)" % [hero_v28.hp, str(hero_v28.state)])
	testeur_v78.invincible = true
	hero_v28.heal(999)
	# --- le niveau donne de l'endurance et du souffle
	var e0: float = float(hero_v28.STAMINA_MAX)
	var a0: float = float(mer_v55.AIR_MAX)
	testeur_v78._level_up(true)
	await _att(0.3)
	_ok(float(hero_v28.STAMINA_MAX) > e0 and float(mer_v55.AIR_MAX) > a0, "niveau maximum : endurance %.0f -> %.0f, souffle %.0f -> %.0f s" % [e0, float(hero_v28.STAMINA_MAX), a0, float(mer_v55.AIR_MAX)])
