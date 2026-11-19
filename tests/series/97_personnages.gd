## Le grand contrôle des bugs visuels, V178 : les personnages des maisons ne rentrent plus dans le décor
## (ce que tests/outils/audit_pnj.py a relevé, puis vu en photo). Pour chaque histoire, une vraie maison
## de la bonne ville, l'histoire imposée, on entre ; une petite boule au cœur du morceau regardé (tête,
## genou…) ne touche pas le décor qu'on voit (chaque maillage de la pièce, en triangles) :
##   - les chats : la personne qui tricote n'a plus de chat dans le ventre, ni les jambes dans le fauteuil ;
##   - le yoga des yourtes de Larsen : ceux qui méditent sont assis sur le tapis, pas enfoncés dans le sol ;
##   - la dispute : celui qui se fâche n'a plus la jambe dans une chaise ;
##   - le petit démon peureux de Pandémonia : caché sous la table, la tête ne passe plus au travers ;
##   - la fête surprise : ceux qui se cachent derrière la table n'y ont pas la tête ;
##   - le pianola de Hautefond : les jambes de ceux qui sont sur le canapé ne le traversent plus ;
##   - les fantômes de la Citadelle : translucides, même une fois leur corps construit (quand on approche).
const NOM := "personnages178"
const COUCHE := 1 << 19


func _porte(ok: Callable) -> int:
	for i in range(maisons_v81.portes.size()):
		if ok.call(maisons_v81.portes[i]):
			return i
	return -1


## On entre pour de vrai (comme le joueur), l'histoire imposée.
func _entrer97(i: int, sc: String, heure: float = 14.0) -> bool:
	_ranger()
	await _images(2)
	temps_v56.hour = heure
	var p: Dictionary = maisons_v81.portes[i]
	place_player_v35((p["door"] as Vector3) + Vector3.UP * 0.1, -(p["out"] as Vector3))
	await _att(0.3)
	maisons_v81.force_scenario = sc
	maisons_v81.enter(i)
	for k in range(60):
		await _att(0.1)
		if maisons_v81.inside and not maisons_v81.busy:
			break
	await _att(1.2)
	return maisons_v81.inside and maisons_v81.room != null


## Construire la maison sans y entrer par la porte (comme tests/outils/audit_pnj.gd) : ce qui se passe à
## l'entrée (la fête surprise : tout le monde sort de sa cachette) n'a pas encore eu lieu.
func _bati97(i: int, sc: String, heure: float = 14.0) -> bool:
	_ranger()
	await _images(2)
	temps_v56.hour = heure
	maisons_v81.cur = maisons_v81.portes[i]
	maisons_v81.force_scenario = sc
	maisons_v81.inside = true
	var arr: Array = maisons_v81._build()
	place_player_v35(arr[0], arr[1])
	await _att(1.2)
	return maisons_v81.room != null


## Le décor qu'on voit, en triangles, sur une couche à part (sauf les personnages).
func _decor97() -> void:
	var room: Node3D = maisons_v81.room
	var gens: Array = []
	for f in maisons_v81.people:
		if is_instance_valid(f) and f.get("npc") != null:
			gens.append(f.npc)
	for mi in room.find_children("*", "MeshInstance3D", true, false):
		var m3: MeshInstance3D = mi
		if m3.mesh == null or not m3.is_visible_in_tree():
			continue
		var sous: bool = false
		var p: Node = m3
		while p != null:
			if p in gens:
				sous = true
				break
			p = p.get_parent()
		if sous:
			continue
		var faces: PackedVector3Array = m3.mesh.get_faces()
		if faces.is_empty():
			continue
		var sb := StaticBody3D.new()
		sb.collision_layer = COUCHE
		sb.collision_mask = 0
		var cs := CollisionShape3D.new()
		var sh := ConcavePolygonShape3D.new()
		sh.backface_collision = true
		sh.set_faces(m3.global_transform * faces)
		cs.shape = sh
		sb.add_child(cs)
		sb.set_meta("mi97", m3)
		room.add_child(sb)
	await get_tree().physics_frame
	await get_tree().physics_frame


## La distance libre (m) autour du cœur d'un morceau (un os, ou le milieu de deux), jusqu'à r.
func _libre97(npc: Node3D, os1: String, os2: String, r: float) -> float:
	var sk: Skeleton3D = npc.get("skel")
	if sk == null or sk.find_bone(os1) < 0:
		return r
	var c: Vector3 = sk.global_transform * sk.get_bone_global_pose(sk.find_bone(os1)).origin
	if os2 != "" and sk.find_bone(os2) >= 0:
		c = c.lerp(sk.global_transform * sk.get_bone_global_pose(sk.find_bone(os2)).origin, 0.5)
	var space := get_world_3d().direct_space_state
	var lo: float = 0.0
	var hi: float = r
	var q := PhysicsShapeQueryParameters3D.new()
	var sp := SphereShape3D.new()
	q.shape = sp
	q.collision_mask = COUCHE
	q.transform = Transform3D(Basis(), c)
	sp.radius = r
	if space.intersect_shape(q, 1).is_empty():
		return r
	for k in range(6):
		sp.radius = (lo + hi) * 0.5
		if space.intersect_shape(q, 1).is_empty():
			lo = sp.radius
		else:
			hi = sp.radius
	return lo


func _ech97(npc: Node3D) -> float:
	var mdl: Variant = npc.get("model")
	return (mdl as Node3D).global_transform.basis.get_scale().x if mdl is Node3D else 1.0


func _pose97(pose: String) -> Array:
	var out: Array = []
	for f in maisons_v81.people:
		if is_instance_valid(f) and str(f.get("pose")) == pose:
			out.append(f.npc)
	return out


func _serie() -> void:
	# --- les chats : la personne qui tricote (trois villes)
	for st in ["montjoie", "braise", "hautefond"]:
		var i: int = _porte(func(e): return str(e.get("style", "")) == st and str(e.get("histoire", "")) == "" and str(e.get("owner", "")) == "")
		if not _ok(i >= 0 and await _entrer97(i, "chats"), "chats (%s) : on entre" % st):
			continue
		await _decor97()
		var tr: Array = _pose97("tricot")
		_ok(tr.size() == 1, "chats (%s) : quelqu'un tricote dans le fauteuil" % st)
		for n in tr:
			var s: float = _ech97(n)
			var chat: float = INF
			for c in maisons_v81.room.find_children("*Chat*", "Node3D", true, false):
				chat = minf(chat, Vector2((c as Node3D).global_position.x - n.global_position.x, (c as Node3D).global_position.z - n.global_position.z).length())
			_ok(chat > 0.4, "chats (%s) : pas de chat dans le ventre de qui tricote (le plus proche à %.2f m)" % [st, chat])
			var lv: float = _libre97(n, "Spine01", "", 0.085 * s)
			var lg: float = minf(_libre97(n, "LeftLeg", "", 0.05 * s), _libre97(n, "RightLeg", "", 0.05 * s))
			_ok(lv > 0.03 * s and lg > 0.02 * s, "chats (%s) : ni le ventre ni les genoux dans le fauteuil (%.3f, %.3f)" % [st, lv, lg])
	# --- le yoga des yourtes (Larsen) : assis sur le tapis
	var iy: int = _porte(func(e): return str(e.get("style", "")) == "yourte_fleurs")
	if _ok(iy >= 0 and await _entrer97(iy, "yoga"), "yoga : on entre dans une yourte"):
		var med: Array = _pose97("mediter")
		_ok(med.size() == 2, "yoga : deux personnes méditent")
		for n2 in med:
			var sk2: Skeleton3D = n2.get("skel")
			var hy: float = (sk2.global_transform * sk2.get_bone_global_pose(sk2.find_bone("Hips")).origin).y - maisons_v81.R.P(0, 0, 0).y
			_ok(hy > 0.085 * _ech97(n2), "yoga : %s est assis(e) sur son tapis, pas dans le sol (bassin à %.2f m)" % [str(n2.get("display_name")), hy])
	# --- la dispute : la jambe hors de la chaise
	var idp: int = _porte(func(e): return str(e.get("style", "")) == "hautefond" and str(e.get("histoire", "")) == "" and str(e.get("owner", "")) == "")
	if _ok(idp >= 0 and await _entrer97(idp, "dispute"), "dispute : on entre"):
		await _decor97()
		for n3 in _pose97("colere"):
			var s3: float = _ech97(n3)
			var g3: float = minf(_libre97(n3, "LeftLeg", "", 0.05 * s3), _libre97(n3, "RightLeg", "", 0.05 * s3))
			_ok(g3 > 0.02 * s3, "dispute : %s n'a pas la jambe dans une chaise (%.3f)" % [str(n3.get("display_name")), g3])
	# --- le petit démon peureux (Pandémonia) : sous la table, la tête sous le plateau
	var idm: int = _porte(func(e): return str(e.get("style", "")) == "braise" and str(e.get("histoire", "")) == "" and str(e.get("owner", "")) == "")
	if _ok(idm >= 0 and await _entrer97(idm, "demon_peureux"), "le petit démon peureux : on entre"):
		await _decor97()
		var ca: Array = _pose97("cache")
		_ok(ca.size() == 1, "le petit démon peureux : il se cache")
		for n4 in ca:
			var s4: float = _ech97(n4)
			var t4: float = _libre97(n4, "Head", "head_end", 0.075 * s4)
			_ok(t4 > 0.06 * s4, "le petit démon peureux : la tête sous la table, pas dedans (%.3f)" % t4)
	# --- la fête surprise : cachés derrière les meubles
	var isu: int = _porte(func(e): return str(e.get("style", "")) == "boucan" and str(e.get("histoire", "")) == "" and str(e.get("owner", "")) == "" and float(e.get("w", 0)) >= 7.0 and float(e.get("d", 0)) >= 6.6)
	if _ok(isu >= 0 and await _bati97(isu, "surprise"), "la fête surprise : la maison est prête"):
		await _decor97()
		var cs: Array = _pose97("cache")
		_ok(cs.size() >= 3, "la fête surprise : on se cache (%d)" % cs.size())
		for n5 in cs:
			var s5: float = _ech97(n5)
			var t5: float = _libre97(n5, "Head", "head_end", 0.075 * s5)
			_ok(t5 > 0.06 * s5, "la fête surprise : %s n'a pas la tête dans un meuble (%.3f)" % [str(n5.get("display_name")), t5])
	# --- le pianola (Hautefond) : la berceuse, la grand-mère et l'enfant endormis sur le canapé (l'air est tiré
	# au sort pour chaque maison : on en cherche une où c'est la berceuse)
	var trouve: bool = false
	for i6 in range(maisons_v81.portes.size()):
		var e6: Dictionary = maisons_v81.portes[i6]
		if str(e6.get("style", "")) != "hautefond" or str(e6.get("histoire", "")) != "" or str(e6.get("owner", "")) != "":
			continue
		if not await _bati97(i6, "hf_pianola"):
			continue
		var sofa: Array = _pose97("dormir_assis")
		if sofa.size() < 2:
			continue
		trouve = true
		await _decor97()
		for n6 in sofa:
			var s6: float = _ech97(n6)
			var g6: float = minf(_libre97(n6, "LeftLeg", "", 0.05 * s6), _libre97(n6, "RightLeg", "", 0.05 * s6))
			var v6: float = _libre97(n6, "Spine01", "", 0.085 * s6)
			_ok(g6 > 0.02 * s6 and v6 > 0.03 * s6, "le pianola : %s, sur le canapé, n'a ni les jambes ni le ventre dedans (%.3f, %.3f)" % [str(n6.get("display_name")), g6, v6])
		break
	_ok(trouve, "le pianola : une maison où l'on s'endort sur le canapé")
	# --- les fantômes de la Citadelle : translucides, corps compris
	var ig: int = _porte(func(e): return str(e.get("histoire", "")) == "b173" and str(e.get("metier", "")) == "corps_garde")
	if _ok(ig >= 0 and await _entrer97(ig, ""), "la tour de la garde (Citadelle) : on entre"):
		await _att(2.5)
		var nf: int = 0
		var nmi: int = 0
		var voile: int = 0
		for f7 in maisons_v81.people:
			if not (f7 as Node).has_meta("fantome173"):
				continue
			nf += 1
			for g in (f7.npc as Node).find_children("*", "MeshInstance3D", true, false):
				nmi += 1
				if (g as MeshInstance3D).material_overlay != null and (g as MeshInstance3D).transparency > 0.3:
					voile += 1
		_ok(nf >= 3, "la tour de la garde : les gardes fantômes (%d)" % nf)
		_ok(nmi > nf * 3, "la tour de la garde : leurs corps sont construits (%d morceaux)" % nmi)
		_ok(voile == nmi, "la tour de la garde : les fantômes sont translucides, corps compris (%d / %d)" % [voile, nmi])
	_ranger()
