## Tous les habitants : on va près de chacun, il parle, il a des sujets de conversation.
## Un sur quatre est repris en anglais, un sur quatre en espagnol.
const NOM := "habitants"
const Langue := preload("res://scripts/langue_v104.gd")


func _parler(n: Node3D, quoi: String) -> bool:
	if not is_instance_valid(n):
		return true
	var f: Vector3 = -n.global_transform.basis.z
	f.y = 0.0
	f = f.normalized() if f.length() > 0.01 else Vector3.FORWARD
	place_player_v35(n.global_position + f * 1.6 + Vector3.UP * 0.1, -f)
	await _images(2)
	_talk_v31(n)
	await _images(3)
	var ok: bool = _note(dialogue_v31.opened, "%s : le dialogue s'ouvre" % quoi)
	if ok and dialogue_v31._text != null:
		ok = _note(dialogue_v31._text.text.strip_edges() != "", "%s : il ne dit rien" % quoi) and ok
	if n.get("brain") != null and n.brain.has_method("topics"):
		ok = _note(not n.brain.topics(_npc_ctx_v31()).is_empty(), "%s : aucun sujet de conversation" % quoi) and ok
	_close_dialogue_v31()
	await _images(1)
	return ok


func _serie() -> void:
	var liste: Array = testeur_v78._npcs()
	_ok(liste.size() > 300, "habitants : %d" % liste.size())
	var n_ok: int = 0
	var t0: int = Time.get_ticks_msec()
	for i in liste.size():
		if await _parler(liste[i][1], str(liste[i][0])):
			n_ok += 1
		if i % 50 == 49:
			print("  … habitants : %d / %d (%.0f s)" % [i + 1, liste.size(), (Time.get_ticks_msec() - t0) / 1000.0])
	_ok(n_ok == liste.size(), "en français : %d sur %d parlent" % [n_ok, liste.size()])
	for code in ["en", "es"]:
		Langue.choisir(code, false)
		var n2: int = 0
		var tot: int = 0
		for i in range(1 if code == "en" else 3, liste.size(), 4):
			tot += 1
			if await _parler(liste[i][1], "%s (%s)" % [str(liste[i][0]), code]):
				n2 += 1
		_ok(n2 == tot, "en %s : %d sur %d parlent" % [code, n2, tot])
	Langue.choisir("fr", false)
	_ranger()
