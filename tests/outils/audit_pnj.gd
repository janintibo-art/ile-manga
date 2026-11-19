## V178 : le grand contrôle des bugs visuels, les personnages (lancé par tests/outils/audit_pnj.py, collé
## à la fin de main.gd comme une série). On construit, l'une après l'autre, les vraies maisons du jeu (les
## 1768 portes : maisons, boutiques, lieux), avec leur vraie histoire, le jour puis la nuit ; on laisse
## chacun prendre sa pose, puis on regarde, pour chaque personnage :
##   - sa tête, son cou, son buste, son bassin, ses genoux, ses mains : une petite boule au cœur de chaque
##     morceau (plus petite que le morceau lui-même) ne doit toucher ni le décor qu'on voit (chaque maillage
##     de la pièce, en triangles) ni un meuble solide (les formes de collision) ;
##   - ses pieds : debout, ils touchent le sol (ni en l'air, ni dans le plancher) ;
##   - les autres : deux personnages ne se rentrent pas dedans.
## Chaque cas : une ligne « AUDIT » (la maison, l'heure, le personnage, sa pose, le morceau, la distance
## libre autour du morceau, ce qu'il touche et où) ; chaque maison : une ligne « AUDIT_MAISON » (de quoi la
## reconstruire à l'identique pour la photographier).
const NOM := "audit_pnj"
const AU_COUCHE := 1 << 19
## [os, os2 (milieu des deux, ou ""), rayon (m, à l'échelle 1), nom]
const AU_MORCEAUX := [
	["Head", "head_end", 0.075, "tête"], ["neck", "", 0.045, "cou"], ["Spine", "", 0.09, "buste"],
	["Spine01", "", 0.085, "ventre"], ["Hips", "", 0.075, "bassin"], ["LeftLeg", "", 0.05, "genou_g"],
	["RightLeg", "", 0.05, "genou_d"], ["LeftHand", "", 0.03, "main_g"], ["RightHand", "", 0.03, "main_d"],
]
const AU_ASSIS := ["assis", "rire_assis", "tricot", "lire", "manger", "guitare", "dormir_assis", "dormir", "allonge", "cache", "pompes", "bain", "prier", "leviter"]
var _au_args: Dictionary = {}
var _au_n: int = 0
var _au_cas: int = 0
var _au_sans_os: int = 0
var _au_pnj: int = 0


func _serie() -> void:
	var f := FileAccess.open("res://audit_args.json", FileAccess.READ)
	if f != null:
		_au_args = JSON.parse_string(f.get_as_text())
	var de: int = int(_au_args.get("de", 0))
	var a: int = mini(int(_au_args.get("a", maisons_v81.portes.size())), maisons_v81.portes.size())
	var heures: Array = _au_args.get("heures", [14.0, 22.0])
	var seuls: Array = _au_args.get("ids", [])
	var filtre: String = str(_au_args.get("filtre", ""))
	print("AUDIT_DEBUT %d portes, de %d à %d, heures %s" % [maisons_v81.portes.size(), de, a, str(heures)])
	Engine.time_scale = 3.0
	for i in range(de, a):
		var e: Dictionary = maisons_v81.portes[i]
		if not seuls.is_empty() and not (str(e["id"]) in seuls):
			continue
		if filtre != "" and not (filtre in str(e.get("style", "")) or filtre in str(e.get("histoire", "")) or filtre in str(e.get("metier", ""))):
			continue
		for h in heures:
			await _au_maison(i, float(h))
	Engine.time_scale = 1.0
	print("AUDIT_FIN %d maisons, %d personnages (%d sans squelette), %d cas" % [_au_n, _au_pnj, _au_sans_os, _au_cas])


func _au_maison(i: int, heure: float) -> void:
	var M = maisons_v81
	if M.room != null:
		M._teardown()
	temps_v56.hour = heure
	M.cur = M.portes[i]
	M.force_scenario = ""
	M.inside = true
	var arr: Array = M._build()
	# on arrive comme dans le jeu (à la porte, de l'intérieur) : ceux qui se tournent vers le héros le font
	place_player_v35(arr[0], arr[1])
	_au_n += 1
	# chacun prend sa pose (les fondus d'animation, ce qui bouge un peu)
	await _att(0.9)
	var room: Node3D = M.room
	if room == null:
		return
	var o: Vector3 = M.R.P(0, 0, 0)
	# de quoi reconstruire la maison ailleurs (tests/outils/rendu_maisons.gd, « audit ») : sa porte, et
	# l'habitant chez qui l'on est (sa fiche)
	var desc: Dictionary = {}
	for k in M.cur:
		if not (M.cur[k] is Object):
			desc[k] = M.cur[k]
	var ow: Variant = M.cur.get("owner_node", null)
	if ow is Node and is_instance_valid(ow):
		desc["owner_fake"] = {"profile": (ow as Node).get("profile"), "display_name": str((ow as Node).get("display_name")),
			"hidden_home": (ow as Node).get("hidden_home") == true, "script": str(((ow as Node).get_script() as Script).resource_path)}
	print("AUDIT_MAISON\t%d\t%s\t%.1f\t%s\t%s" % [i, str(M.cur["id"]), heure, str(M.scenario), var_to_str(desc).replace("\n", " ")])
	# les personnages
	var gens: Array = []
	for sk in room.find_children("*", "Skeleton3D", true, false):
		if (sk as Skeleton3D).find_bone("Head") < 0 or (sk as Skeleton3D).find_bone("Hips") < 0:
			continue
		var r: Node = sk.get_parent()
		while r != null and r != room and r.get("skel") != sk:
			r = r.get_parent()
		if r == null or r == room or not (r as Node3D).is_visible_in_tree():
			continue
		gens.append([r, sk])
	for ctl in M.people:
		if is_instance_valid(ctl) and ctl.get("npc") != null and is_instance_valid(ctl.npc):
			var trouve: bool = false
			for g in gens:
				if g[0] == ctl.npc:
					trouve = true
			if not trouve and (ctl.npc as Node3D).is_visible_in_tree():
				_au_sans_os += 1
	_au_pnj += gens.size()
	if gens.is_empty():
		return
	# le décor qu'on voit, en triangles (sur une couche à part), sauf les personnages
	var racines: Array = []
	for g in gens:
		racines.append(g[0])
	var corps: Array = []
	for hb in [pc_body, vr_body]:
		if hb != null:
			corps.append((hb as CollisionObject3D).get_rid())
	for g in gens:
		var b: Variant = (g[0] as Node).get("_body")
		if b is CollisionObject3D:
			corps.append((b as CollisionObject3D).get_rid())
	var mis: Array = room.find_children("*", "MeshInstance3D", true, false)
	for mi in mis:
		var m3: MeshInstance3D = mi
		if m3.mesh == null or not m3.is_visible_in_tree() or _au_sous(m3, racines):
			continue
		var faces: PackedVector3Array = m3.mesh.get_faces()
		if faces.is_empty():
			continue
		faces = m3.global_transform * faces
		var sb := StaticBody3D.new()
		sb.collision_layer = AU_COUCHE
		sb.collision_mask = 0
		var cs := CollisionShape3D.new()
		var sh := ConcavePolygonShape3D.new()
		sh.backface_collision = true
		sh.set_faces(faces)
		cs.shape = sh
		sb.add_child(cs)
		sb.set_meta("au_mi", m3)
		room.add_child(sb)
	for mmi in room.find_children("*", "MultiMeshInstance3D", true, false):
		var mm: MultiMesh = (mmi as MultiMeshInstance3D).multimesh
		if mm == null or mm.mesh == null or not (mmi as Node3D).is_visible_in_tree() or _au_sous(mmi, racines):
			continue
		var f0: PackedVector3Array = mm.mesh.get_faces()
		var tout := PackedVector3Array()
		for k in range(mini(mm.visible_instance_count if mm.visible_instance_count >= 0 else mm.instance_count, 400)):
			tout.append_array(((mmi as Node3D).global_transform * mm.get_instance_transform(k)) * f0)
		if tout.is_empty():
			continue
		var sb2 := StaticBody3D.new()
		sb2.collision_layer = AU_COUCHE
		sb2.collision_mask = 0
		var cs2 := CollisionShape3D.new()
		var sh2 := ConcavePolygonShape3D.new()
		sh2.backface_collision = true
		sh2.set_faces(tout)
		cs2.shape = sh2
		sb2.add_child(cs2)
		sb2.set_meta("au_mi", mmi)
		room.add_child(sb2)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var space := get_world_3d().direct_space_state
	var pts_tous: Array = []
	for g in gens:
		var npc: Node3D = g[0]
		var sk: Skeleton3D = g[1]
		# la taille du personnage (un enfant, un nain : plus petit) ; pas celle du squelette (en cm dans le modèle)
		var mdl: Variant = npc.get("model")
		var ech: float = (mdl as Node3D).global_transform.basis.get_scale().x if mdl is Node3D else 1.0
		var nom: String = str(npc.get("display_name"))
		var pose: String = "?"
		var ctl: Node = npc.get_node_or_null("Figurant_v81")
		if ctl != null:
			pose = str(ctl.get("pose"))
		var pts: Dictionary = {}
		for mo in AU_MORCEAUX:
			var b1: int = sk.find_bone(str(mo[0]))
			if b1 < 0:
				continue
			var p: Vector3 = sk.global_transform * sk.get_bone_global_pose(b1).origin
			if str(mo[1]) != "" and sk.find_bone(str(mo[1])) >= 0:
				p = p.lerp(sk.global_transform * sk.get_bone_global_pose(sk.find_bone(str(mo[1]))).origin, 0.5)
			var r0: float = float(mo[2]) * ech
			pts[str(mo[3])] = [p, r0]
			# le décor qu'on voit
			var hit: Dictionary = _au_boule(space, p, r0, AU_COUCHE, [])
			if not hit.is_empty():
				var libre: float = _au_libre(space, p, r0, AU_COUCHE, [])
				_au_dire(i, heure, nom, pose, str(mo[3]), "vu", libre, r0, hit, p - o)
			# un meuble solide (les collisions de la pièce ; pas les personnages) : seulement la tête et le cou
			# (les formes de collision sont des boîtes grossières : un genou sous la table, un bassin sur la
			# chaise, des mains sur le comptoir y sont toujours)
			var hit2: Dictionary = _au_boule(space, p, r0, 1, corps) if str(mo[3]) in ["tête", "cou"] else {}
			if not hit2.is_empty():
				var libre2: float = _au_libre(space, p, r0, 1, corps)
				_au_dire(i, heure, nom, pose, str(mo[3]), "solide", libre2, r0, hit2, p - o)
		# assis : la hauteur du bassin au-dessus du siège (ce qu'on voit juste dessous), et des pieds au-dessus du sol
		if pose in AU_ASSIS.slice(0, 7) and pts.has("bassin"):
			var hb: Vector3 = pts["bassin"][0]
			var q3 := PhysicsRayQueryParameters3D.create(hb + Vector3.UP * 0.2, hb + Vector3.DOWN * 0.8, AU_COUCHE)
			var r3: Dictionary = space.intersect_ray(q3)
			var bas3: float = INF
			for pied3 in ["LeftToeBase", "RightToeBase"]:
				var bp3: int = sk.find_bone(pied3)
				if bp3 >= 0:
					bas3 = minf(bas3, (sk.global_transform * sk.get_bone_global_pose(bp3).origin).y)
			print("AUDIT_ASSIS\t%d\t%s\t%s\t%.2f\t%.3f\t%.3f\t%.3f\t%s" % [i, nom, pose, ech, hb.y - o.y,
				((r3["position"] as Vector3).y - o.y) if not r3.is_empty() else -1.0, bas3 - o.y, str((r3["collider"] as Node).get_meta("au_mi").name) if not r3.is_empty() else ""])
		# les pieds : debout, sur le sol (les fantômes de la Citadelle flottent : c'est voulu)
		if not (pose in AU_ASSIS) and not (ctl != null and ctl.has_meta("fantome173")):
			var bas: float = INF
			var sol: float = -INF
			for pied in ["LeftToeBase", "RightToeBase", "LeftFoot", "RightFoot"]:
				var bp: int = sk.find_bone(pied)
				if bp < 0:
					continue
				var pp: Vector3 = sk.global_transform * sk.get_bone_global_pose(bp).origin
				bas = minf(bas, pp.y)
				var q := PhysicsRayQueryParameters3D.create(pp + Vector3.UP * 0.3, pp + Vector3.DOWN * 1.5, AU_COUCHE)
				q.hit_back_faces = false
				var rr: Dictionary = space.intersect_ray(q)
				if not rr.is_empty():
					sol = maxf(sol, (rr["position"] as Vector3).y)
			if bas < INF and sol > -INF:
				var ecart: float = bas - sol
				if ecart > 0.09 * ech:
					# ce qui le porte (une forme de collision sans rien de visible dessus ?)
					var q1 := PhysicsRayQueryParameters3D.create(npc.global_position + Vector3.UP * 0.5, npc.global_position + Vector3.DOWN * 0.5, 1, corps)
					var r1: Dictionary = space.intersect_ray(q1)
					_au_dire(i, heure, nom, pose, "pieds", "en_l_air", ecart, 0.0, r1, Vector3(npc.global_position - o))
				elif ecart < -0.07 * ech:
					_au_dire(i, heure, nom, pose, "pieds", "dans_le_sol", ecart, 0.0, {}, Vector3(npc.global_position - o))
		pts_tous.append([nom, pose, pts])
	# deux personnages qui se rentrent dedans
	for x in range(pts_tous.size()):
		for y in range(x + 1, pts_tous.size()):
			var pa: Dictionary = pts_tous[x][2]
			var pb: Dictionary = pts_tous[y][2]
			for ka in ["tête", "buste", "bassin"]:
				for kb in ["tête", "buste", "bassin"]:
					if not pa.has(ka) or not pb.has(kb):
						continue
					var dd: float = (pa[ka][0] as Vector3).distance_to(pb[kb][0])
					if dd < float(pa[ka][1]) + float(pb[kb][1]):
						_au_dire(i, heure, str(pts_tous[x][0]), str(pts_tous[x][1]), ka, "personne:" + str(pts_tous[y][0]) + ":" + kb, dd, float(pa[ka][1]) + float(pb[kb][1]), {}, (pa[ka][0] as Vector3) - o)


func _au_sous(n: Node, racines: Array) -> bool:
	var p: Node = n
	while p != null:
		if p in racines:
			return true
		p = p.get_parent()
	return false


func _au_boule(space: PhysicsDirectSpaceState3D, c: Vector3, r: float, masque: int, sauf: Array) -> Dictionary:
	var q := PhysicsShapeQueryParameters3D.new()
	var sp := SphereShape3D.new()
	sp.radius = r
	q.shape = sp
	q.transform = Transform3D(Basis(), c)
	q.collision_mask = masque
	q.exclude = sauf
	var res: Array = space.intersect_shape(q, 4)
	return res[0] if not res.is_empty() else {}


## La distance libre autour de c (à 4 mm près), entre 0 et r.
func _au_libre(space: PhysicsDirectSpaceState3D, c: Vector3, r: float, masque: int, sauf: Array) -> float:
	var lo: float = 0.0
	var hi: float = r
	for k in range(5):
		var m: float = (lo + hi) * 0.5
		if _au_boule(space, c, m, masque, sauf).is_empty():
			lo = m
		else:
			hi = m
	return lo


func _au_dire(i: int, heure: float, nom: String, pose: String, morceau: String, quoi: String, libre: float, r0: float, hit: Dictionary, p: Vector3) -> void:
	_au_cas += 1
	var qui: String = ""
	if not hit.is_empty():
		var col: Object = hit.get("collider")
		if col != null and col.has_meta("au_mi"):
			var mi: Node = col.get_meta("au_mi")
			qui = "%s<%s" % [mi.name, mi.get_parent().name]
			if mi is MeshInstance3D and (mi as MeshInstance3D).mesh != null:
				var mat: Material = (mi as MeshInstance3D).get_active_material(0)
				if mat != null:
					qui += "|" + (mat.resource_name if mat.resource_name != "" else mat.resource_path.get_file())
					if mat is BaseMaterial3D and (mat as BaseMaterial3D).transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
						qui += "|transparent"
		elif col is Node:
			qui = "%s<%s" % [(col as Node).name, (col as Node).get_parent().name]
	var e: Dictionary = maisons_v81.portes[i]
	print("AUDIT\t%d\t%s\t%s\t%s\t%s\t%.1f\t%s\t%s\t%s\t%s\t%.3f\t%.3f\t%s\t%.2f,%.2f,%.2f" % [i, str(e["id"]), str(e.get("style", "")),
		str(maisons_v81.scenario), str(e.get("metier", "")), heure, nom, pose, morceau, quoi, libre, r0, qui, p.x, p.y, p.z])
