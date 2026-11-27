## La Cascade Arrabbiata et la sauce sur le personnage, V217 (l'Île Al Dente). La cascade était un ruban
## couché sur la pente, qui s'arrêtait loin au-dessus de la mer : elle passe sur le Bec de la Saucière,
## tombe en nappe et finit dans la mer. Qui passe dessous, ou tombe dans la sauce, en ressort couvert :
## une couche de sauce sur son corps, des gouttes, des taches derrière lui ; ça s'en va tout seul, ou
## d'un coup dans la mer.
const NOM := "sauce217"


func _serie() -> void:
	var pa217: Node = pasta_v97
	_ok(pa217 != null and pa217.ile != null, "l'Île Al Dente est construite")
	if pa217 == null or pa217.ile == null:
		return
	var ch217: Array = pa217.chute_v217
	_ok(ch217.size() > 12, "la cascade a sa nappe (%d points)" % ch217.size())
	if ch217.size() < 3:
		return
	var haut217: Vector3 = ch217[0]
	var bas217: Vector3 = ch217[-1]
	_ok(haut217.y - bas217.y > 6.0, "elle tombe de haut (%.1f m)" % (haut217.y - bas217.y))
	_ok(bas217.y <= pa217.ile.WATER + 0.01, "elle finit dans la mer (%.2f m)" % bas217.y)
	_ok(pa217.ile.height(bas217.x, bas217.z) < pa217.ile.WATER, "son pied est au-dessus de l'eau, pas sur la roche (fond à %.1f m)" % pa217.ile.height(bas217.x, bas217.z))
	# une vraie chute : quelque part, la nappe est à plus de 2 m au-dessus de la roche
	var vide217: float = 0.0
	for c217 in ch217:
		var cp217: Vector3 = c217
		vide217 = maxf(vide217, cp217.y - maxf(pa217.ile.height(cp217.x, cp217.z), pa217.ile.WATER))
	_ok(vide217 > 2.0, "la nappe décolle de la falaise (jusqu'à %.1f m de vide)" % vide217)
	_ok(pa217.get_node_or_null("Bec_de_la_Sauciere_v217") != null and pa217.get_node_or_null("Cascade_Arrabbiata") != null and pa217.get_node_or_null("Gouttes_de_la_cascade_v217") != null, "le bec de pierre, la nappe et ses gouttes sont là")
	_ok(Vector2(pa217.cascade_at.x - bas217.x, pa217.cascade_at.z - bas217.z).length() < 0.5, "l'écume est au pied de la nappe")
	# la sauce sur le personnage
	var sh217: Node = pa217.sauce_heros_v217
	_ok(sh217 != null, "le personnage peut recevoir de la sauce")
	if sh217 == null:
		return
	_ranger()
	var dessus217: Vector3 = pa217.respawn_point()[0]
	await _poser(dessus217, Vector3.FORWARD)
	await _att(0.5)
	_ok(float(sh217.quantite) == 0.0 and sh217._habilles.is_empty(), "sur la plage, il est propre")
	# sous la cascade : au pied de la nappe
	var sous217: Vector3 = ch217[ch217.size() - 4]
	place_player_v35(Vector3(sous217.x, sous217.y - 0.9, sous217.z), Vector3.FORWARD)
	await _images(4)
	_ok(float(sh217.quantite) > 0.9, "sous la cascade, il est couvert de sauce (%.2f)" % float(sh217.quantite))
	_ok(int(sh217.bains) == 1, "c'est compté une fois (%d)" % int(sh217.bains))
	await _poser(dessus217, Vector3.FORWARD)
	await _att(2.4)
	_ok(sh217._habilles.size() > 0, "son corps porte la couche de sauce (%d maillages)" % sh217._habilles.size())
	var bon217: bool = sh217._habilles.size() > 0
	var noms217: Array = []
	for m217 in sh217._habilles:
		noms217.append(str((m217 as MeshInstance3D).name))
		if (m217 as MeshInstance3D).material_overlay != sh217._mat and not sh217._mains.values().has((m217 as MeshInstance3D).material_overlay):
			bon217 = false
	print("SAUCE217 maillages couverts : ", noms217)
	_ok(bon217, "la couche est bien posée par-dessus sa matière")
	var corps217: bool = false
	for m217 in sh217._habilles:
		if (m217 as MeshInstance3D).skin != null:
			corps217 = true
	_ok(corps217, "le corps du héros lui-même est couvert")
	_ok(float(sh217._mat.get_shader_parameter("quantite")) > 0.85, "la couche est épaisse au début (%.2f)" % float(sh217._mat.get_shader_parameter("quantite")))
	_ok(sh217._gouttes.emitting, "il goutte")
	# ça sèche tout seul
	var q0217: float = float(sh217.quantite)
	await _att(3.0)
	_ok(float(sh217.quantite) < q0217 - 0.03 and float(sh217.quantite) > 0.7, "ça s'en va doucement (%.2f -> %.2f)" % [q0217, float(sh217.quantite)])
	# une goutte du volcan, le pied dans la sauce : on garde le plus fort
	sh217.quantite = 0.2
	sh217.couvrir(0.45, "bord")
	_ok(absf(float(sh217.quantite) - 0.45) < 0.01, "le pied dans la sauce : jusqu'aux genoux (%.2f)" % float(sh217.quantite))
	sh217.couvrir(0.3, "bord")
	_ok(absf(float(sh217.quantite) - 0.45) < 0.01, "une petite éclaboussure n'enlève rien")
	# dans le lac de sauce
	sh217.quantite = 0.0
	var lac217: Vector3 = pa217.ile.W(float(pa217.ile.LAC[0]), float(pa217.ile.LAC[1]))
	var niv217: float = pa217.ile.sauce_level(lac217.x, lac217.z)
	_ok(niv217 > -INF, "le Lac Napolitain a sa sauce")
	place_player_v35(Vector3(lac217.x, niv217 - 0.2, lac217.z), Vector3.FORWARD)
	await _images(4)
	_ok(float(sh217.quantite) > 0.9, "tombé dans le lac, il est couvert (%.2f)" % float(sh217.quantite))
	# la mer rince
	var large217: Vector3 = (ch217[-1] as Vector3) + ((ch217[-1] as Vector3) - (ch217[0] as Vector3)).normalized() * Vector3(1, 0, 1) * 60.0
	place_player_v35(Vector3(large217.x, -2.0, large217.z), Vector3.FORWARD)
	var t217: int = 0
	while float(sh217.quantite) > 0.0 and t217 < 400:
		place_player_v35(Vector3(large217.x, -2.0, large217.z), Vector3.FORWARD)
		await _images(1)
		t217 += 1
	_ok(float(sh217.quantite) == 0.0 and t217 < 400, "un bain de mer et il est propre (%d images)" % t217)
	await _images(3)
	_ok(sh217._habilles.is_empty() and not sh217._gouttes.emitting, "la couche est retirée, il ne goutte plus")
	_ok(int(sh217.rinces) >= 1, "le bain est compté")
	_ranger()
