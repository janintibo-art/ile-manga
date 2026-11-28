## V219 : la magie spectaculaire. Les trois sorts d'attaque passent par magie_v219 (des flammes, de la fumée,
## du givre, des éclairs calculés par la carte graphique) : la boule de feu et son explosion, le souffle de
## givre et ses bouquets de cristaux (jamais alignés, ils volent en poussière), la foudre ; l'ennemi en feu,
## pris par la glace, électrisé ; les réactions (vapeur, éclats, arcs) ; le ménage (rien ne reste, dix
## marques au sol au plus) ; le processeur n'anime rien image par image ; et sans le module, les effets
## d'avant servent encore.
const NOM := "63_magie"


func _vider() -> void:
	for b in faune_v132.betes.duplicate():
		if is_instance_valid(b):
			b.queue_free()
	faune_v132.betes.clear()
	elements_v143.reset()


## Une bête immobile devant le héros (à « avant » mètres, décalée de « cote » mètres).
func _bete(kind: String, avant: float = 2.5, cote: float = 0.0) -> Node3D:
	var f: Vector3 = hero_v28.facing
	var q: Vector3 = _pos() + f * avant + f.cross(Vector3.UP) * cote
	q.y = _height_at(q.x, q.z) + 0.1
	var b: Node3D = faune_v132.spawn(kind, q)
	b.set_physics_process(false)
	return b


## Un coin bien plat et dégagé autour du héros : on s'y pose, tourné vers le nord (comme 63_elements).
func _plat() -> bool:
	var o: Vector3 = _pos()
	var best: Vector3 = o
	var bd: float = INF
	var libre: Vector3 = Vector3.INF
	var ld: float = 0.5
	for r in range(0, 90, 3):
		for k in range(16):
			var a: float = TAU * k / 16.0 + r * 0.37
			var c := Vector3(o.x + cos(a) * r, 0, o.z + sin(a) * r)
			var h0: float = _height_at(c.x, c.z)
			if h0 < 1.0:
				continue
			var d: float = 0.0
			for dz in [0.0, -3.0, -6.0, -9.0, -12.0]:
				for dx in [-3.0, 0.0, 3.0]:
					d = maxf(d, absf(_height_at(c.x + dx, c.z + dz) - h0))
			if d < bd:
				bd = d
				best = Vector3(c.x, h0, c.z)
			if d < ld and _degage(Vector3(c.x, h0, c.z)):
				ld = d
				libre = Vector3(c.x, h0, c.z)
		if libre != Vector3.INF and ld < 0.3:
			break
	if libre != Vector3.INF:
		best = libre
		bd = ld
	_poser(best + Vector3.UP * 0.2, Vector3.FORWARD)
	return bd < 0.5


func _degage(c: Vector3) -> bool:
	var space := get_world_3d().direct_space_state
	var sauf: Array = []
	if pc_body != null:
		sauf.append(pc_body.get_rid())
	for h in [0.7, 1.3]:
		for vers in [Vector3(0, 0, -13.0), Vector3(-2.2, 0, -12.0), Vector3(2.2, 0, -12.0)]:
			var b: Vector3 = c + vers
			b.y = _height_at(b.x, b.z) + h
			var q := PhysicsRayQueryParameters3D.create(c + Vector3.UP * h, b, 1)
			q.exclude = sauf
			if not space.intersect_ray(q).is_empty():
				return false
	return true


func _sol() -> void:
	for k in range(40):
		if str(hero_v28.state) == "sol":
			return
		await _att(0.05)


func _pret() -> void:
	sorts_v67.mana = float(sorts_v67.mana_max())
	sorts_v67._cd.clear()
	pouvoirs_v63._cd.clear()
	await _sol()


## Combien d'enfants de cette sorte sous ce nœud (sans ceux qui sont en train de disparaître) ?
func _combien219(racine219: Node, sorte219: String) -> int:
	var n219: int = 0
	for c219 in racine219.get_children():
		if c219.is_queued_for_deletion():
			continue
		if c219.is_class(sorte219):
			n219 += 1
	return n219


func _compte219(cle219: String) -> int:
	return int(magie_v219.lances.get(cle219, 0))


## La boule de feu qui vole (ou null).
func _boule219() -> Node3D:
	for c219 in pouvoirs_v63.get_children():
		if str(c219.name).begins_with("Flamme_v63") and not c219.is_queued_for_deletion():
			return c219
	return null


func _serie() -> void:
	testeur_v78._faune_v132("elfes")
	await _att(0.5)
	faune_v132.enabled = false
	var plat219: bool = _plat()
	await _att(0.6)
	await _sol()
	_ok(plat219, "un coin plat pour l'essai")
	var mg219: Node3D = magie_v219
	var el219: Node = elements_v143
	_ok(mg219 != null and mg219.is_inside_tree(), "le module de la magie existe")
	var manque219: Array = []
	for nom219 in mg219.MATIERES:
		if mg219._shader(str(nom219)) == null:
			manque219.append(nom219)
	_ok(mg219.MATIERES.size() == 10 and manque219.is_empty(), "les dix matières de la magie se chargent (manque : %s)" % str(manque219))
	_ok(bool(mg219.prechauffe), "elles ont été préparées au chargement")
	_ok(mg219.bruit != null and mg219.cristaux != null, "le bruit des flammes et les cristaux du givre sont prêts")
	_ok(not mg219.is_processing() and not mg219.is_physics_processing(), "le module ne calcule rien image par image (la carte graphique anime tout)")
	_vider()
	await _images(2)
	testeur_v78._pick("h_tout")
	await _att(0.3)
	_close_dialogue_v31()
	await _att(0.2)
	inventory_v28.equip_item("")
	await _att(0.3)

	# --- la boule de feu en vol
	await _pret()
	var b0_219: int = _compte219("boule")
	var fx0_219: int = int(combat_fx_v129.count.get("boule", 0))
	_ok(sorts_v67.cast("feu"), "la boule de feu part")
	await _images(2)
	var boule219: Node3D = _boule219()
	_ok(boule219 != null, "la boule vole")
	if boule219 != null:
		_ok(_compte219("boule") == b0_219 + 1 and int(combat_fx_v129.count.get("boule", 0)) == fx0_219 + 1, "elle est habillée par la magie (%d)" % _compte219("boule"))
		_ok(boule219.has_node("Coeur_en_fusion"), "elle a son cœur en fusion")
		_ok(_combien219(boule219, "CPUParticles3D") == 0, "plus de points lumineux calculés par le processeur sur la boule (%d)" % _combien219(boule219, "CPUParticles3D"))
		_ok(_combien219(boule219, "RemoteTransform3D") == 3, "trois jets la suivent : les flammes, les braises, la fumée (%d attaches)" % _combien219(boule219, "RemoteTransform3D"))
		var lampe219: float = 0.0
		for c219 in boule219.get_children():
			if c219 is OmniLight3D:
				lampe219 = (c219 as OmniLight3D).light_energy
		_ok(lampe219 > 3.0, "sa lumière est plus forte (%.1f)" % lampe219)
		var jets219: Array = mg219.dernier.get("boule", [])
		var suivent219: bool = jets219.size() == 4
		await _images(3)
		if suivent219 and is_instance_valid(boule219):
			for i219 in range(1, 4):
				var j219: GPUParticles3D = jets219[i219] as GPUParticles3D
				if j219 == null or not j219.emitting or j219.get_parent() != mg219 or j219.global_position.distance_to(boule219.global_position) > 0.6:
					suivent219 = false
		_ok(suivent219, "les jets sont des particules de la carte graphique, et ils suivent la boule")
		# --- elle explose
		var e0_219: int = _compte219("explosion")
		var t219: float = 0.0
		while _compte219("explosion") == e0_219 and t219 < 3.5:
			await _att(0.1)
			t219 += 0.1
		_ok(_compte219("explosion") == e0_219 + 1, "la boule explose au bout de sa course (%.1f s)" % t219)
		await _images(2)
		_ok(_boule219() == null, "la boule a disparu")
		var eteints219: bool = true
		for i219 in range(1, jets219.size()):
			if is_instance_valid(jets219[i219]) and (jets219[i219] as GPUParticles3D).emitting:
				eteints219 = false
		_ok(eteints219, "ses flammes cessent d'émettre (elles finissent leur vie au lieu de disparaître d'un coup)")
	await _att(2.2)

	# --- l'explosion au sol : la boule de flammes, les braises, la fumée, la marque
	var f219: Vector3 = hero_v28.facing
	var ici219: Vector3 = _pos() + f219 * 6.0
	ici219.y = _height_at(ici219.x, ici219.z) + 0.25
	var cpu0_219: int = _combien219(pouvoirs_v63, "CPUParticles3D")
	var e1_219: int = _compte219("explosion")
	pouvoirs_v63._explode(ici219)
	await _images(2)
	_ok(_compte219("explosion") == e1_219 + 1, "une explosion au sol")
	_ok(_combien219(pouvoirs_v63, "CPUParticles3D") == cpu0_219, "plus de points lumineux par-dessus la vraie explosion")
	var ex219: Array = mg219.dernier.get("explosion", [])
	var jets_ex219: int = 0
	var marque219: MeshInstance3D = null
	for o219 in ex219:
		if o219 is GPUParticles3D:
			jets_ex219 += 1
		elif o219 is MeshInstance3D and mg219.marques.has(o219):
			marque219 = o219
	_ok(jets_ex219 == 3, "trois gerbes : les flammes, les braises, la fumée (%d)" % jets_ex219)
	_ok(marque219 != null and str(marque219.name).begins_with("Brulure_magie"), "le sol est noirci, des braises y rougeoient")
	if marque219 != null:
		var haut219: float = marque219.global_position.y - _height_at(marque219.global_position.x, marque219.global_position.z)
		_ok(absf(haut219) < 0.4, "la marque est posée sur le sol (%.2f m)" % haut219)
	var particules219: int = 0
	for o219 in ex219:
		if o219 is GPUParticles3D:
			particules219 += (o219 as GPUParticles3D).amount
	_ok(particules219 > 40 and particules219 <= 90, "une explosion : %d particules (assez pour le spectacle, pas trop pour le casque)" % particules219)
	await _att(5.6)
	var reste219: int = 0
	for c219 in mg219.get_children():
		if not c219.is_queued_for_deletion() and not mg219.marques.has(c219) and not mg219.givres.has(c219):
			reste219 += 1
	_ok(reste219 == 0, "six secondes après, il ne reste que les marques au sol (%d autres objets)" % reste219)

	# --- dix marques au plus
	for k219 in range(13):
		var p219: Vector3 = _pos() + f219 * (4.0 + k219 * 0.7) + f219.cross(Vector3.UP) * (float(k219 % 3) - 1.0) * 1.5
		p219.y = _height_at(p219.x, p219.z) + 0.25
		mg219.explosion(p219)
		await _images(1)
	# (les plus vieilles s'effacent en une demi-seconde, pas d'un coup)
	await _att(0.9)
	var vives219: int = 0
	for c219 in mg219.get_children():
		if str(c219.name).begins_with("Brulure_magie") and not c219.is_queued_for_deletion():
			vives219 += 1
	_ok(mg219.marques.size() == mg219.MARQUES_MAX and vives219 == mg219.MARQUES_MAX, "treize explosions : dix marques au sol, les plus vieilles se sont effacées (%d)" % vives219)
	await _att(1.2)

	# --- le souffle de givre
	await _pret()
	var b219: Node3D = _bete("sanglier", 3.0)
	b219.hp = 60
	var g0_219: int = _compte219("givre")
	var s0_219: int = _compte219("saisi")
	var pics0_219: int = int(combat_fx_v129.count.get("glace", 0))
	_ok(sorts_v67.cast("gel"), "le gel part")
	await _images(2)
	_ok(_compte219("givre") == g0_219 + 1, "le souffle de givre passe par la magie")
	_ok(not sorts_v67.has_node("Souffle_de_givre_v67"), "plus de points lumineux pour le souffle")
	var pics219: int = 0
	for e219 in combat_fx_v129._fx:
		if str((e219 as Dictionary).get("alpha", "")) == "pic":
			pics219 += 1
	_ok(int(combat_fx_v129.count.get("glace", 0)) == pics0_219 + 1 and pics219 == 0, "le gel est compté comme avant, sans ses pics alignés (%d)" % pics219)
	var bouquets219: Array = mg219.dernier.get("givre_bouquets", [])
	var gauche219: float = INF
	var droite219: float = -INF
	for bq219 in bouquets219:
		var de_cote219: float = ((bq219 as Node3D).global_position - _pos()).dot(f219.cross(Vector3.UP))
		gauche219 = minf(gauche219, de_cote219)
		droite219 = maxf(droite219, de_cote219)
	_ok(bouquets219.size() >= 6, "des bouquets de cristaux jaillissent du sol (%d)" % bouquets219.size())
	_ok(droite219 - gauche219 > 0.6, "… en éventail, jamais alignés (%.1f m de large)" % (droite219 - gauche219))
	var plaques219: Array = mg219.dernier.get("givre_plaques", [])
	var posees219: int = 0
	for pl219 in plaques219:
		if is_instance_valid(pl219) and absf((pl219 as Node3D).global_position.y - _height_at((pl219 as Node3D).global_position.x, (pl219 as Node3D).global_position.z)) < 0.5:
			posees219 += 1
	_ok(posees219 >= 6, "le givre prend sur le sol, de proche en proche (%d plaques posées)" % posees219)
	_ok(el219.etat(b219) == "gele" and b219.has_node("Glace_v143"), "l'ennemi est pris dans la glace (%s)" % el219.etat(b219))
	_ok(_compte219("saisi") == s0_219 + 1, "… avec son souffle de brume, ses éclats, le givre à ses pieds")
	await _att(2.6)
	var brises219: bool = true
	for bq219 in bouquets219:
		if is_instance_valid(bq219) and not (bq219 as Node).is_queued_for_deletion():
			brises219 = false
	_ok(brises219, "les bouquets de cristaux ont volé en poussière")

	# --- la vapeur, les éclats (on regèle d'abord : la glace du sort a pu fondre entre-temps)
	b219.hp = 60
	el219.geler(b219)
	var v0_219: int = _compte219("vapeur")
	el219.hit(b219, "feu", 2, _pos())
	_ok(_compte219("vapeur") == v0_219 + 1 and el219.last_reaction == "vapeur", "le feu sur la glace : un nuage de vapeur")
	b219.hp = 60
	el219.geler(b219)
	var c0_219: int = _compte219("eclats")
	el219.hit(b219, "foudre", 2, _pos())
	_ok(_compte219("eclats") == c0_219 + 1 and el219.last_reaction == "eclats", "la foudre sur la glace : elle vole en éclats")
	b219.hp = 60
	el219._efface(b219)
	el219.tremper(b219)
	var a0_219: int = _compte219("arcs")
	el219.hit(b219, "foudre", 2, _pos())
	_ok(_compte219("arcs") == a0_219 + 1 and el219.last_reaction == "electrocute", "la foudre sur un ennemi trempé : des arcs courent autour de lui")
	_vider()
	await _images(2)

	# --- l'ennemi en feu
	b219 = _bete("sanglier", 3.0)
	b219.hp = 60
	var m0_219: int = _compte219("embrase")
	var cpu1_219: int = _combien219(b219, "CPUParticles3D")
	el219.enflammer(b219)
	await _images(2)
	_ok(_compte219("embrase") == m0_219 + 1 and el219.etat(b219) == "brule", "l'ennemi prend feu")
	_ok(_combien219(b219, "CPUParticles3D") == cpu1_219 and _combien219(b219, "RemoteTransform3D") == 3, "de vraies flammes l'enveloppent : trois jets de la carte graphique, aucun du processeur (%d attaches)" % _combien219(b219, "RemoteTransform3D"))
	var feux219: Array = mg219.dernier.get("embrase", [])
	b219.global_position += f219.cross(Vector3.UP) * 2.0
	await _images(3)
	var avec219: bool = feux219.size() == 3
	for fe219 in feux219:
		var jet219: GPUParticles3D = fe219 as GPUParticles3D
		if jet219 == null or not jet219.emitting:
			avec219 = false
		elif Vector2(jet219.global_position.x - b219.global_position.x, jet219.global_position.z - b219.global_position.z).length() > 0.1:
			avec219 = false
	_ok(avec219, "les flammes suivent l'ennemi quand il bouge")
	el219._efface(b219)
	await _images(3)
	var finis219: bool = true
	for fe219 in feux219:
		if is_instance_valid(fe219) and (fe219 as GPUParticles3D).emitting:
			finis219 = false
	_ok(finis219 and el219.etat(b219) == "", "le feu éteint : les flammes cessent d'émettre")
	await _att(2.6)
	var partis219: bool = true
	for fe219 in feux219:
		if is_instance_valid(fe219) and not (fe219 as Node).is_queued_for_deletion():
			partis219 = false
	_ok(partis219, "… puis elles disparaissent")
	_vider()
	await _images(2)

	# --- la foudre
	await _pret()
	var f1_219: Node3D = _bete("sanglier", 5.0)
	var f2_219: Node3D = _bete("sanglier", 8.0, 1.5)
	var f3_219: Node3D = _bete("sanglier", 11.0, -1.0)
	for fo219 in [f1_219, f2_219, f3_219]:
		fo219.hp = 60
	var ec0_219: int = _compte219("eclair")
	var fr0_219: int = _compte219("frappe")
	var el0_219: int = _compte219("electrise")
	var fxf0_219: int = int(combat_fx_v129.count.get("foudre", 0))
	_ok(sorts_v67.cast("foudre"), "la Foudre part")
	await _images(2)
	_ok(el219.last_chain.size() == 3, "l'éclair saute sur trois ennemis (%d)" % el219.last_chain.size())
	_ok(_compte219("eclair") >= ec0_219 + 3 and _compte219("frappe") >= fr0_219 + 1, "trois éclairs et une frappe passent par la magie (%d, %d)" % [_compte219("eclair") - ec0_219, _compte219("frappe") - fr0_219])
	_ok(_compte219("electrise") == el0_219 + 3, "les trois ennemis sont électrisés : des arcs courent sur eux (%d)" % (_compte219("electrise") - el0_219))
	_ok(int(combat_fx_v129.count.get("foudre", 0)) > fxf0_219, "la frappe est comptée comme avant")
	var ecl219: Array = mg219.dernier.get("eclair", [])
	var points219: int = 0
	if ecl219.size() == 1 and is_instance_valid(ecl219[0]) and (ecl219[0] as MeshInstance3D).mesh != null and (ecl219[0] as MeshInstance3D).mesh.get_surface_count() > 0:
		points219 = ((ecl219[0] as MeshInstance3D).mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	_ok(points219 > 60, "l'éclair a un tronc et des branches (%d sommets)" % points219)
	await _att(0.8)
	_ok(ecl219.size() == 1 and (not is_instance_valid(ecl219[0]) or (ecl219[0] as Node).is_queued_for_deletion()), "l'éclair s'éteint en moins d'une seconde")
	_vider()
	await _images(2)

	# --- sans le module, les effets d'avant servent encore
	magie_v219 = null
	await _pret()
	var av0_219: int = int(combat_fx_v129.count.get("boule", 0))
	_ok(sorts_v67.cast("feu"), "sans le module : la boule de feu part quand même")
	await _images(2)
	var vieille219: Node3D = _boule219()
	_ok(vieille219 != null and _combien219(vieille219, "CPUParticles3D") >= 1 and not vieille219.has_node("Coeur_en_fusion") and int(combat_fx_v129.count.get("boule", 0)) == av0_219 + 1,
		"… avec ses effets d'avant")
	await _pret()
	_ok(sorts_v67.cast("gel"), "sans le module : le gel part")
	await _images(2)
	var vieux_pics219: int = 0
	for e219 in combat_fx_v129._fx:
		if str((e219 as Dictionary).get("alpha", "")) == "pic":
			vieux_pics219 += 1
	_ok(sorts_v67.has_node("Souffle_de_givre_v67") and vieux_pics219 >= 1, "… avec son souffle et ses pics d'avant (%d)" % vieux_pics219)
	await _pret()
	_ok(sorts_v67.cast("foudre"), "sans le module : la Foudre part")
	await _att(2.6)
	magie_v219 = mg219

	await _att(0.5)
	var debout219: bool = await _debout("après la magie")
	_ok(debout219, "le héros tient debout")
	_ranger()
