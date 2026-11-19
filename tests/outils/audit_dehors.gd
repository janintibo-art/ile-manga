## V181 : le grand contrôle des bugs visuels, les personnages dehors (lancé par tests/outils/audit_dehors.py,
## collé à la fin de main.gd comme une série). On va voir chaque habitant du jeu (main.npcs_v31 : ceux des
## îles, des villes, des quais), à l'heure demandée, là où son emploi du temps l'a mené ; on le laisse se
## réveiller (son corps se construit quand on approche) et prendre sa pose, puis on regarde :
##   - sa tête, son cou, son buste, son ventre, son bassin, ses genoux, ses mains : une petite boule au
##     cœur de chaque morceau (plus petite que le morceau) ne doit toucher ni le décor qu'on voit (les
##     maillages proches, en triangles) ni, pour la tête et le cou, un obstacle solide ;
##   - ses pieds : debout, ils touchent le sol qu'on voit (ni en l'air, ni dedans) ;
##   - assis : son bassin est posé sur quelque chose qu'on voit (pas assis dans le vide).
## Chaque cas : une ligne « AUDIT » ; chaque habitant regardé : une ligne « AUDIT_PNJ » (de quoi revenir
## le regarder en « radar »).
const NOM := "audit_dehors"
const AD_COUCHE := 1 << 19
## [os, os2 (milieu des deux, ou ""), rayon (m, à l'échelle 1), nom]
const AD_MORCEAUX := [
	["Head", "head_end", 0.075, "tête"], ["neck", "", 0.045, "cou"], ["Spine", "", 0.09, "buste"],
	["Spine01", "", 0.085, "ventre"], ["Hips", "", 0.075, "bassin"], ["LeftLeg", "", 0.05, "genou_g"],
	["RightLeg", "", 0.05, "genou_d"], ["LeftHand", "", 0.03, "main_g"], ["RightHand", "", 0.03, "main_d"],
]
const AD_MAX_FACES := 900000          # un maillage plus gros (le relief d'une île) : le sol solide suffit
var _ad_args: Dictionary = {}
var _ad_n: int = 0
var _ad_cas: int = 0
var _ad_grille: Dictionary = {}       # case de 8 m -> [[maillage, boîte], …]
var _ad_noeuds: int = -1
var _ad_ou: Vector3 = Vector3(1e9, 0, 0)  # où l'on a rangé les maillages la dernière fois
var _ad_faits: Dictionary = {}        # maillage -> le corps de triangles déjà fait (ou null)


func _serie() -> void:
	var f := FileAccess.open("res://audit_args.json", FileAccess.READ)
	if f != null:
		_ad_args = JSON.parse_string(f.get_as_text())
	var liste: Array = testeur_v78._npcs()
	if _ad_args.has("radar"):
		await _ad_radars(liste)
		return
	if _ad_args.get("sans_assises", false):
		var As = load("res://scripts/pnj/assises_v181.gd")
		As.actif = false
		print("AUDIT_SANS_ASSISES ", As.actif)
	if _ad_args.get("lieux", false):
		for h in _ad_args.get("heures", [14.0]):
			temps_v56.hour = float(h)
			await _ad_lieux(liste, float(h))
		print("AUDIT_FIN %d lieux regardés, %d cas" % [_ad_n, _ad_cas])
		return
	var de: int = int(_ad_args.get("de", 0))
	var a: int = mini(int(_ad_args.get("a", liste.size())), liste.size())
	var heures: Array = _ad_args.get("heures", [14.0])
	var seuls: Array = _ad_args.get("ids", [])
	print("AUDIT_DEBUT %d habitants, de %d à %d, heures %s" % [liste.size(), de, a, str(heures)])
	for h in heures:
		temps_v56.hour = float(h)
		for i in range(de, a):
			if not seuls.is_empty() and not (str(liste[i][0]) in seuls):
				continue
			await _ad_pnj(i, liste[i][1], float(h))
	print("AUDIT_FIN %d habitants regardés, %d cas" % [_ad_n, _ad_cas])


## Les maillages qu'on voit, rangés par cases de 8 m (refait quand le monde a changé : les villes, les
## maisons se construisent quand on approche).
func _ad_ranger(ici: Vector3) -> void:
	var n: int = get_tree().get_node_count()
	if absi(n - _ad_noeuds) < 300 and ici.distance_to(_ad_ou) < 150.0:
		return
	_ad_noeuds = n
	_ad_ou = ici
	_ad_grille.clear()
	for mi in get_tree().root.find_children("*", "MeshInstance3D", true, false):
		var m: MeshInstance3D = mi
		# pas les corps des personnages (des maillages déformés par un squelette)
		if m.mesh == null or m.skin != null or m.get_parent() is Skeleton3D:
			continue
		var bx: AABB = m.global_transform * m.get_aabb()
		if bx.size.length() > 4000.0:
			continue
		_ad_mettre(m, bx)
	for mmi in get_tree().root.find_children("*", "MultiMeshInstance3D", true, false):
		var mm: MultiMesh = (mmi as MultiMeshInstance3D).multimesh
		if mm == null or mm.mesh == null:
			continue
		# l'herbe, les fleurs (petites touffes de moins de 40 cm) : on marche dedans ; pas les lattes d'un banc
		var sc: Vector3 = (mmi as Node3D).global_transform.basis.get_scale()
		var ta: Vector3 = mm.mesh.get_aabb().size * sc
		if ta.y < 0.4 and maxf(ta.x, ta.z) < 0.35:
			continue
		var n2: int = mm.visible_instance_count if mm.visible_instance_count >= 0 else mm.instance_count
		for k in range(n2):
			var t: Transform3D = (mmi as Node3D).global_transform * mm.get_instance_transform(k)
			_ad_mettre([mmi, k], t * mm.mesh.get_aabb())


func _ad_mettre(quoi: Variant, bx: AABB) -> void:
	var x0: int = floori(bx.position.x / 8.0)
	var x1: int = floori(bx.end.x / 8.0)
	var z0: int = floori(bx.position.z / 8.0)
	var z1: int = floori(bx.end.z / 8.0)
	if (x1 - x0 + 1) * (z1 - z0 + 1) > 400:
		# très grand (le relief, la mer) : rangé seulement au milieu (le sol solide le remplace au besoin)
		x0 = floori(bx.get_center().x / 8.0)
		x1 = x0
		z0 = floori(bx.get_center().z / 8.0)
		z1 = z0
	for x in range(x0, x1 + 1):
		for z in range(z0, z1 + 1):
			var c := Vector2i(x, z)
			if not _ad_grille.has(c):
				_ad_grille[c] = []
			(_ad_grille[c] as Array).append([quoi, bx])


## Les maillages autour de p (une boîte de 3 m de côté), changés en triangles sur la couche AD_COUCHE.
func _ad_triangles(p: Vector3, sauf: Array) -> void:
	var zone := AABB(p - Vector3(1.6, 0.6, 1.6), Vector3(3.2, 3.2, 3.2))
	var vus: Dictionary = {}
	for x in range(floori(zone.position.x / 8.0), floori(zone.end.x / 8.0) + 1):
		for z in range(floori(zone.position.z / 8.0), floori(zone.end.z / 8.0) + 1):
			for e in _ad_grille.get(Vector2i(x, z), []):
				if not (e[1] as AABB).intersects(zone):
					continue
				var obj: Variant = e[0] if e[0] is Object else (e[0] as Array)[0]
				if not is_instance_valid(obj):
					continue
				var nd: Node3D = obj
				var cle: String = str(nd.get_instance_id()) + ("" if e[0] is Object else ":" + str((e[0] as Array)[1]))
				if vus.has(cle) or _ad_faits.has(cle):
					continue
				vus[cle] = true
				if not nd.is_visible_in_tree() or _ad_sous(nd, sauf):
					continue
				var faces := PackedVector3Array()
				if nd is MeshInstance3D:
					faces = (nd as MeshInstance3D).mesh.get_faces()
					if faces.size() > AD_MAX_FACES:
						_ad_faits[cle] = null
						if _ad_args.get("debug", false):
							print("AUDIT_TROP_GROS ", nd.name, " ", faces.size())
						continue
					faces = nd.global_transform * faces
				else:
					var mm: MultiMesh = (nd as MultiMeshInstance3D).multimesh
					faces = (nd.global_transform * mm.get_instance_transform(int((e[0] as Array)[1]))) * mm.mesh.get_faces()
				if faces.is_empty():
					_ad_faits[cle] = null
					continue
				var sb := StaticBody3D.new()
				sb.collision_layer = AD_COUCHE
				sb.collision_mask = 0
				var cs := CollisionShape3D.new()
				var sh := ConcavePolygonShape3D.new()
				sh.backface_collision = true
				sh.set_faces(faces)
				cs.shape = sh
				sb.add_child(cs)
				sb.set_meta("au_mi", nd)
				sb.set_meta("ad_pos", p)
				add_child(sb)
				_ad_faits[cle] = sb


## On rend les triangles des endroits qu'on a quittés (plus de 150 m).
func _ad_oublier(p: Vector3) -> void:
	for cle in _ad_faits.keys():
		var sb: Variant = _ad_faits[cle]
		if sb is StaticBody3D and is_instance_valid(sb) and ((sb as Node).get_meta("ad_pos") as Vector3).distance_to(p) > 150.0:
			(sb as Node).queue_free()
			_ad_faits.erase(cle)


func _ad_sous(n: Node, racines: Array) -> bool:
	var p: Node = n
	while p != null:
		if p in racines:
			return true
		p = p.get_parent()
	return false


func _ad_pnj(i: int, npc: Node3D, heure: float) -> void:
	if not is_instance_valid(npc) or not npc.is_inside_tree():
		return
	# on arrive à 4 m, devant lui (comme le joueur qui vient lui parler)
	var fw: Vector3 = npc.global_transform.basis.z
	fw.y = 0.0
	fw = fw.normalized() if fw.length() > 0.01 else Vector3.FORWARD
	place_player_v35(npc.global_position + fw * 4.0 + Vector3.UP * 0.2, -fw)
	await _att(1.2)
	await _ad_mesurer(i, npc, heure)


## Les lieux (audit_dehors.py --lieux) : chaque lieu où l'on s'assied (assis, lire, la guitare), de
## l'emploi du temps de chaque habitant ; on l'y envoie (comme s'il y arrivait), puis on regarde.
func _ad_lieux(liste: Array, heure: float) -> void:
	var faits: Dictionary = {}
	var de: int = int(_ad_args.get("de", 0))
	var a: int = mini(int(_ad_args.get("a", liste.size())), liste.size())
	for i in range(de, a):
		var npc: Node3D = liste[i][1]
		if not is_instance_valid(npc) or npc.get("azur") == null or not (npc.get("agenda") is Array):
			continue
		var az: Object = npc.get("azur")
		for e in npc.get("agenda"):
			var nm: String = str(e[2]) if (e is Array and (e as Array).size() > 2) else ""
			if nm == "" or nm == "maison" or nm.begins_with("course:"):
				continue
			var sp: Dictionary = az.call("spot", nm)
			if sp.is_empty() or not (str(sp.get("pose", "")) in ["assis", "lire", "guitare"]):
				continue
			var cle: String = str(az.get_instance_id()) + ":" + nm
			if faits.has(cle):
				continue
			faits[cle] = true
			npc.set("slot", npc.call("_slot_now"))
			npc.call("_set_hidden", false)
			npc.set("state", "repos")
			npc.set("target_spot", nm)
			npc.call("_arrive")
			var fw: Vector3 = npc.global_transform.basis.z
			fw.y = 0.0
			fw = fw.normalized() if fw.length() > 0.01 else Vector3.FORWARD
			place_player_v35(npc.global_position + fw * 4.0 + Vector3.UP * 0.2, -fw)
			await _att(1.4)
			await _ad_mesurer(i, npc, heure)


func _ad_mesurer(i: int, npc: Node3D, heure: float) -> void:
	if not is_instance_valid(npc) or not npc.is_visible_in_tree():
		return
	var fw: Vector3 = npc.global_transform.basis.z
	var mdl: Variant = npc.get("model")
	if mdl is Node3D and not (mdl as Node3D).is_visible_in_tree():
		return
	var sk: Skeleton3D = npc.get("skel")
	if sk == null or sk.find_bone("Head") < 0 or sk.find_bone("Hips") < 0:
		return
	_ad_n += 1
	_ad_ranger(npc.global_position)
	_ad_oublier(npc.global_position)
	_ad_sieges_poses()
	# ce qui n'est pas du décor : les personnages, le héros
	var sauf: Array = []
	for nn in npcs_v31:
		if is_instance_valid(nn):
			sauf.append(nn)
	for hr in [pc_hero, pc_root]:
		if hr != null:
			sauf.append(hr)
	_ad_triangles(npc.global_position, sauf)
	var corps: Array = []
	for hb in [pc_body, vr_body]:
		if hb != null:
			corps.append((hb as CollisionObject3D).get_rid())
	for nn in npcs_v31:
		if is_instance_valid(nn):
			var b: Variant = (nn as Node).get("_body")
			if b is CollisionObject3D:
				corps.append((b as CollisionObject3D).get_rid())
	await get_tree().physics_frame
	await get_tree().physics_frame
	var space := get_world_3d().direct_space_state
	var ech: float = (mdl as Node3D).global_transform.basis.get_scale().x if mdl is Node3D else 1.0
	var nom: String = str(npc.get("display_name"))
	var etat: String = str(npc.get("state"))
	if npc.get("target_spot") != null and str(npc.get("target_spot")) != "":
		etat += "@" + str(npc.get("target_spot"))
	var anim_n: String = str(npc.get("current_anim"))
	var assis: bool = anim_n.contains("sit") or anim_n.contains("assis") or anim_n.contains("lire") or anim_n.contains("tricot") or anim_n.contains("dormir") or anim_n == "v56/guitare"
	# assis par terre (en tailleur, à genoux), allongé : ni les pieds, ni le siège
	var par_terre: bool = anim_n.contains("scribe") or anim_n.contains("mediter") or anim_n.contains("prier") or anim_n.contains("potier") or anim_n.contains("genou") or anim_n.begins_with("Lie_") or anim_n.contains("moudre") or anim_n.contains("tisser") or anim_n.contains("leviter")
	var o: Vector3 = npc.global_position
	print("AUDIT_PNJ\t%d\t%s\t%.1f\t%s\t%s\t%.2f,%.2f,%.2f\t%.3f,%.3f,%.3f\t%.2f" % [i, nom, heure, etat, anim_n, o.x, o.y, o.z, fw.x, fw.y, fw.z, ech])
	var pts: Dictionary = {}
	for mo in AD_MORCEAUX:
		var b1: int = sk.find_bone(str(mo[0]))
		if b1 < 0:
			continue
		var p: Vector3 = sk.global_transform * sk.get_bone_global_pose(b1).origin
		if str(mo[1]) != "" and sk.find_bone(str(mo[1])) >= 0:
			p = p.lerp(sk.global_transform * sk.get_bone_global_pose(sk.find_bone(str(mo[1]))).origin, 0.5)
		var r0: float = float(mo[2]) * ech
		pts[str(mo[3])] = p
		var hit: Dictionary = _au_boule(space, p, r0, AD_COUCHE, [])
		if not hit.is_empty():
			_ad_dire(i, heure, nom, etat, anim_n, str(mo[3]), "vu", _au_libre(space, p, r0, AD_COUCHE, []), r0, hit, p)
		var hit2: Dictionary = _au_boule(space, p, r0, 1, corps) if str(mo[3]) in ["tête", "cou"] else {}
		if not hit2.is_empty():
			_ad_dire(i, heure, nom, etat, anim_n, str(mo[3]), "solide", _au_libre(space, p, r0, 1, corps), r0, hit2, p)
	if assis and pts.has("bassin"):
		# assis : sur quoi ? (ce qu'on voit juste sous le bassin)
		var hb: Vector3 = pts["bassin"]
		# le plus haut de cinq rayons (le milieu, et à 10 cm autour : les lattes d'un banc), sur ce qu'on
		# voit et sur ce qui est solide (le relief)
		var r3: Dictionary = {}
		var d3: float = 9.0
		for dp in [Vector3.ZERO, Vector3(0.1, 0, 0), Vector3(-0.1, 0, 0), Vector3(0, 0, 0.1), Vector3(0, 0, -0.1)]:
			var y3: float = _ad_dessous(space, hb + dp, 0.1, 0.6, corps)
			if y3 > -INF and hb.y - y3 < d3:
				d3 = hb.y - y3
		if d3 > 0.3 * ech:
			_ad_dire(i, heure, nom, etat, anim_n, "bassin", "assis_dans_le_vide", d3, 0.0, r3, hb)
			_ad_siege(i, heure, nom, etat, anim_n, npc, hb, space)
			_ad_assise(npc, hb, ech, space, corps)
		else:
			# assis trop bas (le bassin dans l'assise qu'on voit) ?
			var bas_vu: float = 9.0
			for dp2 in [Vector3.ZERO, Vector3(0.1, 0, 0), Vector3(-0.1, 0, 0), Vector3(0, 0, 0.1), Vector3(0, 0, -0.1)]:
				var q4 := PhysicsRayQueryParameters3D.create(hb + dp2 + Vector3.UP * 0.1, hb + dp2 + Vector3.DOWN * 0.6, AD_COUCHE)
				var r4: Dictionary = space.intersect_ray(q4)
				if not r4.is_empty():
					bas_vu = minf(bas_vu, hb.y - (r4["position"] as Vector3).y)
			if bas_vu < 0.05 * ech:
				_ad_dire(i, heure, nom, etat, anim_n, "bassin", "assis_trop_bas", bas_vu, 0.0, {}, hb)
				_ad_assise(npc, hb, ech, space, corps)
	elif not assis and not par_terre:
		var bas: float = INF
		var sol_vu: float = -INF
		var sol_dur: float = -INF
		for pied in ["LeftToeBase", "RightToeBase", "LeftFoot", "RightFoot"]:
			var bp: int = sk.find_bone(pied)
			if bp < 0:
				continue
			var pp: Vector3 = sk.global_transform * sk.get_bone_global_pose(bp).origin
			bas = minf(bas, pp.y)
			var q := PhysicsRayQueryParameters3D.create(pp + Vector3.UP * 0.4, pp + Vector3.DOWN * 1.5, AD_COUCHE)
			q.hit_back_faces = false
			var rr: Dictionary = space.intersect_ray(q)
			if not rr.is_empty():
				sol_vu = maxf(sol_vu, (rr["position"] as Vector3).y)
			var q2 := PhysicsRayQueryParameters3D.create(pp + Vector3.UP * 0.4, pp + Vector3.DOWN * 1.5, 1, corps)
			var r2: Dictionary = space.intersect_ray(q2)
			if not r2.is_empty():
				sol_dur = maxf(sol_dur, (r2["position"] as Vector3).y)
		# le sol qu'on voit (ou, s'il n'a pas été changé en triangles, le sol solide : le relief)
		var sol: float = sol_vu if sol_vu > -INF else sol_dur
		if bas < INF and sol > -INF:
			var ecart: float = bas - sol
			if ecart > 0.1 * ech:
				_ad_dire(i, heure, nom, etat, anim_n, "pieds", "en_l_air" + ("" if sol_vu > -INF else "_dur"), ecart, 0.0, {}, o)
			elif ecart < -0.08 * ech:
				_ad_dire(i, heure, nom, etat, anim_n, "pieds", "dans_le_sol" + ("" if sol_vu > -INF else "_dur"), ecart, 0.0, {}, o)
		elif bas < INF:
			_ad_dire(i, heure, nom, etat, anim_n, "pieds", "pas_de_sol", 0.0, 0.0, {}, o)


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


func _ad_dire(i: int, heure: float, nom: String, etat: String, anim_n: String, morceau: String, quoi: String, libre: float, r0: float, hit: Dictionary, p: Vector3) -> void:
	_ad_cas += 1
	var qui: String = ""
	if not hit.is_empty():
		var col: Object = hit.get("collider")
		if col != null and col.has_meta("au_mi"):
			var mi: Node = col.get_meta("au_mi")
			qui = "%s<%s<%s" % [mi.name, mi.get_parent().name, mi.get_parent().get_parent().name if mi.get_parent().get_parent() != null else ""]
			if mi is MeshInstance3D and (mi as MeshInstance3D).mesh != null:
				var mat: Material = (mi as MeshInstance3D).get_active_material(0)
				if mat != null:
					qui += "|" + (mat.resource_name if mat.resource_name != "" else mat.resource_path.get_file())
					if mat is BaseMaterial3D and (mat as BaseMaterial3D).transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
						qui += "|transparent"
		elif col is Node:
			qui = "%s<%s" % [(col as Node).name, (col as Node).get_parent().name]
	print("AUDIT\t%d\t%s\t%.1f\t%s\t%s\t%s\t%s\t%.3f\t%.3f\t%s\t%.2f,%.2f,%.2f" % [i, nom, heure, etat, anim_n, morceau, quoi, libre, r0, qui, p.x, p.y, p.z])


## Assis dans le vide : où est le siège le plus proche ? (une surface à plat, de 30 à 75 cm au-dessus du
## sol, à moins d'un mètre du bassin) ; ligne « AUDIT_SIEGE » : le décalage du siège dans le repère du
## personnage (x vers sa gauche, z devant lui), sa hauteur au-dessus du sol, le sol sous le bassin, ce que c'est.
func _ad_siege(i: int, heure: float, nom: String, etat: String, anim_n: String, npc: Node3D, hb: Vector3, space: PhysicsDirectSpaceState3D) -> void:
	var q0 := PhysicsRayQueryParameters3D.create(hb + Vector3.UP * 0.1, hb + Vector3.DOWN * 8.0, AD_COUCHE | 1)
	var r0: Dictionary = space.intersect_ray(q0)
	var sol_b: float = (hb.y - (r0["position"] as Vector3).y) if not r0.is_empty() else 99.0
	var sol: float = hb.y - sol_b
	var meilleur: Vector3 = Vector3.INF
	var quoi: String = ""
	for dx in range(-10, 11):
		for dz in range(-10, 11):
			var d := Vector3(dx * 0.1, 0, dz * 0.1)
			if d.length() > 1.0:
				continue
			var q := PhysicsRayQueryParameters3D.create(hb + d + Vector3.UP * 0.4, hb + d + Vector3.DOWN * 1.2, AD_COUCHE)
			q.hit_back_faces = false
			var r: Dictionary = space.intersect_ray(q)
			if r.is_empty() or (r["normal"] as Vector3).y < 0.85:
				continue
			var h: float = (r["position"] as Vector3).y - sol
			if h < 0.3 or h > 0.75:
				continue
			if meilleur == Vector3.INF or d.length() < Vector3(meilleur.x, 0, meilleur.z).length():
				meilleur = Vector3(d.x, h, d.z)
				var mi: Variant = (r["collider"] as Node).get_meta("au_mi") if (r["collider"] as Node).has_meta("au_mi") else null
				quoi = str((mi as Node).name) + "<" + str((mi as Node).get_parent().name) if mi is Node else ""
	var bz: Vector3 = npc.global_transform.basis.z.normalized()
	var bx: Vector3 = npc.global_transform.basis.x.normalized()
	if meilleur == Vector3.INF:
		print("AUDIT_SIEGE\t%d\t%s\t%.1f\t%s\taucun\tsol sous le bassin %.2f" % [i, nom, heure, etat, sol_b])
	else:
		var dd := Vector3(meilleur.x, 0, meilleur.z)
		print("AUDIT_SIEGE\t%d\t%s\t%.1f\t%s\tgauche %.2f devant %.2f haut %.2f\tsol sous le bassin %.2f\t%s" % [i, nom, heure, etat, dd.dot(bx), dd.dot(bz), meilleur.y, sol_b, quoi])


## Les « radars » (audit_dehors.py --radar liste.json --dossier DOSSIER) : sans écran (le jeu tourne sans
## rendu, comme les séries), une image faite de rayons : le décor qu'on voit autour du personnage (ses
## maillages changés en triangles, en gris clair ; le relief, s'il est trop gros, en brun), et le
## personnage en petites boules rouges le long de ses os (bleues à gauche). Deux vues : de trois quarts
## devant, et de profil. liste.json : [[n° d'habitant, heure, lieu (ou "")], …] ; avec un lieu, on l'y
## envoie (comme --lieux).
const AD_SILHOUETTE := 1 << 18
const AD_OS := [["Head", "head_end"], ["neck", "Head"], ["Spine", "neck"], ["Spine01", "Spine"], ["Spine02", "Spine01"], ["Hips", "Spine02"],
	["LeftUpLeg", "LeftLeg"], ["LeftLeg", "LeftFoot"], ["LeftFoot", "LeftToeBase"], ["RightUpLeg", "RightLeg"], ["RightLeg", "RightFoot"],
	["RightFoot", "RightToeBase"], ["LeftArm", "LeftForeArm"], ["LeftForeArm", "LeftHand"], ["RightArm", "RightForeArm"], ["RightForeArm", "RightHand"],
	["LeftShoulder", "LeftArm"], ["RightShoulder", "RightArm"], ["Hips", "LeftUpLeg"], ["Hips", "RightUpLeg"]]


func _ad_radars(liste: Array) -> void:
	var dossier: String = str(_ad_args.get("dossier", "/tmp"))
	if _ad_args.get("brut", false):
		var As = load("res://scripts/pnj/assises_v181.gd")
		As.actif = false
	for ph in _ad_args["radar"]:
		var i: int = int(ph[0])
		if i < 0 or i >= liste.size():
			continue
		var npc: Node3D = liste[i][1]
		temps_v56.hour = float(ph[1])
		var lieu: String = str(ph[2]) if (ph as Array).size() > 2 else ""
		if lieu != "" and npc.get("azur") != null:
			npc.set("slot", npc.call("_slot_now"))
			npc.call("_set_hidden", false)
			npc.set("state", "repos")
			npc.set("target_spot", lieu)
			npc.call("_arrive")
		var fw: Vector3 = npc.global_transform.basis.z
		fw.y = 0.0
		fw = fw.normalized() if fw.length() > 0.01 else Vector3.FORWARD
		place_player_v35(npc.global_position + fw * 4.0 + Vector3.UP * 0.2, -fw)
		await _att(1.4)
		var sk: Skeleton3D = npc.get("skel")
		if sk == null:
			continue
		_ad_ranger(npc.global_position)
		_ad_oublier(npc.global_position)
		_ad_sieges_poses()
		var sauf: Array = []
		for nn in npcs_v31:
			if is_instance_valid(nn):
				sauf.append(nn)
		for hr in [pc_hero, pc_root]:
			if hr != null:
				sauf.append(hr)
		_ad_triangles(npc.global_position, sauf)
		# la silhouette : des boules le long des os
		var sil := StaticBody3D.new()
		sil.collision_layer = AD_SILHOUETTE
		sil.collision_mask = 0
		add_child(sil)
		for paire in AD_OS:
			var b1: int = sk.find_bone(str(paire[0]))
			var b2: int = sk.find_bone(str(paire[1]))
			if b1 < 0 or b2 < 0:
				continue
			var p1: Vector3 = sk.global_transform * sk.get_bone_global_pose(b1).origin
			var p2: Vector3 = sk.global_transform * sk.get_bone_global_pose(b2).origin
			var n: int = maxi(1, int(p1.distance_to(p2) / 0.04))
			var r: float = 0.075 if str(paire[0]) in ["Head", "Spine", "Spine01", "Spine02"] else 0.045
			for k in range(n + 1):
				var cs := CollisionShape3D.new()
				var sp := SphereShape3D.new()
				sp.radius = r
				cs.shape = sp
				cs.position = p1.lerp(p2, float(k) / float(n))
				cs.set_meta("gauche", str(paire[0]).begins_with("Left"))
				sil.add_child(cs)
		await get_tree().physics_frame
		await get_tree().physics_frame
		var c: Vector3 = sk.global_transform * sk.get_bone_global_pose(sk.find_bone("Hips")).origin + Vector3.UP * 0.1
		var droite: Vector3 = fw.cross(Vector3.UP).normalized()
		var k2: int = 0
		for v in [fw * 0.8 + droite * 0.6, droite, -fw * 0.8 + droite * 0.6]:
			var eye: Vector3 = c + (v as Vector3).normalized() * 2.4 + Vector3.UP * 0.6
			var img := _ad_image(eye, c, sil)
			img.save_png("%s/%03d_%s_%s_%d.png" % [dossier, i, str(liste[i][0]).replace(" ", "_").replace("/", "_"), lieu, k2])
			k2 += 1
		sil.queue_free()
		print("RADAR ", i, " ", liste[i][0], " ", lieu)


func _ad_image(eye: Vector3, cible: Vector3, sil: StaticBody3D) -> Image:
	var w: int = 240
	var h: int = 180
	var img := Image.create(w, h, false, Image.FORMAT_RGB8)
	var space := get_world_3d().direct_space_state
	var fwd: Vector3 = (cible - eye).normalized()
	var dr: Vector3 = fwd.cross(Vector3.UP).normalized()
	var up: Vector3 = dr.cross(fwd).normalized()
	var tf: float = tan(deg_to_rad(28.0))
	var lum: Vector3 = Vector3(0.4, 1.0, 0.3).normalized()
	for y in range(h):
		for x in range(w):
			var u: float = (float(x) / float(w) * 2.0 - 1.0) * tf * float(w) / float(h)
			var vv: float = (1.0 - float(y) / float(h) * 2.0) * tf
			var d: Vector3 = (fwd + dr * u + up * vv).normalized()
			var q := PhysicsRayQueryParameters3D.create(eye, eye + d * 7.0, AD_COUCHE | AD_SILHOUETTE)
			var r: Dictionary = space.intersect_ray(q)
			var col := Color(0.55, 0.7, 0.85)
			if r.is_empty():
				var q2 := PhysicsRayQueryParameters3D.create(eye, eye + d * 7.0, 1)
				var r2: Dictionary = space.intersect_ray(q2)
				if not r2.is_empty() and not ((r2["collider"] as Object) is CollisionObject3D and (r2["collider"] as Node).get_parent() in npcs_v31):
					var nl: float = clampf(absf((r2["normal"] as Vector3).dot(lum)), 0.0, 1.0)
					col = Color(0.45, 0.35, 0.25) * (0.45 + 0.55 * nl)
			else:
				var nl2: float = clampf(absf((r["normal"] as Vector3).dot(lum)), 0.0, 1.0)
				if r["collider"] == sil:
					var gauche: bool = false
					var sh_i: int = int(r.get("shape", 0))
					if sh_i >= 0 and sh_i < sil.get_child_count():
						gauche = bool(sil.get_child(sh_i).get_meta("gauche", false))
					col = (Color(0.2, 0.35, 1.0) if gauche else Color(1.0, 0.15, 0.1)) * (0.5 + 0.5 * nl2)
				else:
					var dist: float = eye.distance_to(r["position"])
					col = Color(0.92, 0.9, 0.86) * (0.35 + 0.65 * nl2) * clampf(1.25 - dist * 0.08, 0.5, 1.0)
			img.set_pixel(x, y, col)
	return img


## V181 : de quoi corriger un lieu où l'on s'assied dans le vide (lu par audit_dehors.py --assises, qui en
## fait pcvr/scripts/pnj/assises_v181.gd) : une ligne « AUDIT_ASSISE » : la ville (son script), le lieu,
## la sorte de correction, le décalage du personnage (m, dans le monde), et pour un tabouret sa place et
## sa hauteur.
##   - « siege » : un siège (banc, chaise, rondin, caisse) à moins d'un mètre : on y glisse le bassin ;
##   - « bord » : un bord de quai, de jetée devant soi : on s'y assied, les jambes dans le vide ;
##   - « tabouret » : rien pour s'asseoir : les pieds au sol, et un tabouret sous le bassin.
func _ad_assise(npc: Node3D, hb: Vector3, ech: float, space: PhysicsDirectSpaceState3D, corps: Array) -> void:
	var ville: Variant = npc.get("azur")
	var lieu: String = str(npc.get("target_spot"))
	if not (ville is Object) or lieu == "" or lieu.begins_with("course:"):
		return
	var cle: String = str(((ville as Object).get_script() as Script).resource_path.get_file()) + ":" + lieu
	var racine: Vector3 = npc.global_position
	var h_bassin: float = hb.y - racine.y
	var marge: float = 0.1 * ech
	var fw0: Vector3 = npc.global_transform.basis.z
	fw0.y = 0.0
	fw0 = fw0.normalized()
	# ce qui porte le bassin (le plus haut de cinq rayons, jusqu'à 80 cm dessous) : ce qu'on voit (s_vu ;
	# pas les formes de collision, plus hautes que l'assise d'un banc), ou aussi le relief (s_y)
	var s_y: float = -INF
	var s_vu: float = -INF
	for dp in [Vector3.ZERO, Vector3(0.1, 0, 0), Vector3(-0.1, 0, 0), Vector3(0, 0, 0.1), Vector3(0, 0, -0.1)]:
		s_y = maxf(s_y, _ad_dessous(space, hb + dp, 0.1, 0.8, corps))
		var qv := PhysicsRayQueryParameters3D.create(hb + dp + Vector3.UP * 0.1, hb + dp + Vector3.DOWN * 0.8, AD_COUCHE)
		var rv: Dictionary = space.intersect_ray(qv)
		if not rv.is_empty():
			s_vu = maxf(s_vu, (rv["position"] as Vector3).y)
	if s_vu > -INF and hb.y - s_vu < 0.06 * ech:
		s_y = s_vu
		# assis trop bas (le bassin dans le siège) : on remonte
		print("AUDIT_ASSISE\t%s\tsiege\t0.000,%.3f,0.000\t\t" % [cle, s_y + marge - hb.y])
		return
	if s_y == -INF:
		# le bassin au-dessus du vide (au-delà du bord du quai) : on recule jusqu'au quai (un sol à la
		# hauteur des pieds), et l'on s'assied au bord
		for k in range(1, 30):
			var pb: Vector3 = Vector3(hb.x, racine.y, hb.z) - fw0 * (k * 0.05)
			var yb: float = _ad_dessous(space, pb, 0.4, 0.4, corps)
			if yb > -INF:
				var cible: Vector3 = Vector3(hb.x, yb + marge, hb.z) - fw0 * (k * 0.05 + 0.14)
				var offb: Vector3 = cible - hb
				print("AUDIT_ASSISE\t%s\tbord\t%.3f,%.3f,%.3f\t\t" % [cle, offb.x, offb.y, offb.z])
				return
	# le sol : sous les pieds (pas sous le bassin : c'est peut-être déjà le siège, un rondin, un muret) ;
	# pour affiner (--affiner), sous le bassin
	var sk: Skeleton3D = npc.get("skel")
	var sol: float = -INF
	var pieds_sol: Array = [] if _ad_args.get("affiner", false) else ["LeftToeBase", "RightToeBase"]
	for pied in pieds_sol:
		var bp: int = sk.find_bone(pied) if sk != null else -1
		if bp >= 0:
			var pp0: Vector3 = sk.global_transform * sk.get_bone_global_pose(bp).origin
			sol = maxf(sol, _ad_dessous(space, pp0, 0.3, 2.0, corps))
	if sol == -INF:
		var sol0: float = _ad_dessous(space, hb, 0.05, 3.0, corps)
		sol = sol0 if sol0 > -INF else racine.y
	# ce qui est sous le bassin est un siège (à hauteur de siège au-dessus du sol) : on s'y pose
	var sous: float = -INF
	for dp3 in [Vector3.ZERO, Vector3(0.1, 0, 0), Vector3(-0.1, 0, 0), Vector3(0, 0, 0.1), Vector3(0, 0, -0.1)]:
		var q5 := PhysicsRayQueryParameters3D.create(hb + dp3 + Vector3.UP * 0.1, hb + dp3 + Vector3.DOWN * 1.2, AD_COUCHE)
		var r5: Dictionary = space.intersect_ray(q5)
		if not r5.is_empty():
			sous = maxf(sous, (r5["position"] as Vector3).y)
	if not _ad_args.get("affiner", false) and sous > -INF and sous - sol >= 0.22 and sous - sol <= 0.7:
		print("AUDIT_ASSISE\t%s\tsiege\t0.000,%.3f,0.000\t\t" % [cle, sous + marge - hb.y])
		return
	# 1) un siège : les points à plat, de 28 à 62 cm au-dessus du sol, à moins d'un mètre
	var pts: Array = []
	for dx in range(-20, 21):
		for dz in range(-20, 21):
			var d := Vector3(dx * 0.05, 0, dz * 0.05)
			if d.length() > 1.0:
				continue
			var q := PhysicsRayQueryParameters3D.create(Vector3(hb.x, sol + 0.75, hb.z) + d, Vector3(hb.x, sol + 0.2, hb.z) + d, AD_COUCHE)
			q.hit_back_faces = false
			var r: Dictionary = space.intersect_ray(q)
			if r.is_empty() or (r["normal"] as Vector3).y < 0.85:
				continue
			var hh: float = (r["position"] as Vector3).y - sol
			if hh >= 0.28 and hh <= 0.62:
				pts.append(r["position"])
	if not pts.is_empty():
		var n0: Vector3 = pts[0]
		for p in pts:
			if Vector2(p.x - hb.x, p.z - hb.z).length() < Vector2(n0.x - hb.x, n0.z - hb.z).length():
				n0 = p
		var somme := Vector3.ZERO
		var nb: int = 0
		for p in pts:
			if Vector2(p.x - n0.x, p.z - n0.z).length() < 0.4 and absf(p.y - n0.y) < 0.05:
				somme += p
				nb += 1
		var c: Vector3 = somme / float(nb)
		# pas plus loin que 0,25 m au-delà du point le plus proche (un long banc : on reste de son côté)
		var vers: Vector3 = Vector3(c.x - n0.x, 0, c.z - n0.z)
		if vers.length() > 0.25:
			c = Vector3(n0.x, c.y, n0.z) + vers.normalized() * 0.25
		var off: Vector3 = Vector3(c.x - hb.x, n0.y + marge - hb.y, c.z - hb.z)
		# plus loin que 70 cm : ce n'est sans doute pas son siège (celui du voisin, d'une autre table)
		if Vector2(off.x, off.z).length() <= 0.7:
			print("AUDIT_ASSISE\t%s\tsiege\t%.3f,%.3f,%.3f\t\t" % [cle, off.x, off.y, off.z])
			return
	# 2) un bord devant soi (le quai, la jetée) : là où le sol tombe de plus de 35 cm
	var fw: Vector3 = npc.global_transform.basis.z
	fw.y = 0.0
	fw = fw.normalized()
	var avant: float = sol
	for k in range(1, 25):
		var pp: Vector3 = Vector3(hb.x, sol, hb.z) + fw * (k * 0.05)
		var ici: float = _ad_dessous(space, pp, 0.3, 2.0, corps)
		# un vrai bord : le sol tombe d'un coup (pas une pente douce, une plage)
		var tombe: bool = ici < avant - 0.3
		avant = maxf(ici, avant - 0.06)
		if tombe:
			var bord: Vector3 = Vector3(hb.x, sol, hb.z) + fw * maxf(k * 0.05 - 0.16, 0.0)
			var off2: Vector3 = Vector3(bord.x - hb.x, sol + marge - hb.y, bord.z - hb.z)
			print("AUDIT_ASSISE\t%s\tbord\t%.3f,%.3f,%.3f\t\t" % [cle, off2.x, off2.y, off2.z])
			return
	# 3) rien : les pieds au sol, un tabouret sous le bassin
	var off3: Vector3 = Vector3(0, sol - racine.y, 0)
	var haut: float = h_bassin - marge
	print("AUDIT_ASSISE\t%s\ttabouret\t%.3f,%.3f,%.3f\t%.2f,%.3f,%.2f\t%.3f" % [cle, off3.x, off3.y, off3.z, hb.x, sol, hb.z, haut])


## Le plus haut de ce qu'on voit sous le point p (jusqu'à « bas » dessous) ; à défaut, le relief (les
## formes de collision des villes, des boîtes invisibles souvent plus grandes que les meubles, ne
## comptent pas). -INF : rien.
func _ad_dessous(space: PhysicsDirectSpaceState3D, p: Vector3, haut: float, bas: float, corps: Array) -> float:
	var q := PhysicsRayQueryParameters3D.create(p + Vector3.UP * haut, p + Vector3.DOWN * bas, AD_COUCHE)
	var r: Dictionary = space.intersect_ray(q)
	if not r.is_empty():
		return (r["position"] as Vector3).y
	var sauf: Array = corps.duplicate()
	for k in range(4):
		var q2 := PhysicsRayQueryParameters3D.create(p + Vector3.UP * haut, p + Vector3.DOWN * bas, 1, sauf)
		var r2: Dictionary = space.intersect_ray(q2)
		if r2.is_empty():
			return -INF
		var col: Object = r2["collider"]
		if col is Node and (str((col as Node).name).to_lower().contains("collision") or (col as Node).get_parent() != null and str((col as Node).get_parent().name).to_lower().contains("collision")):
			sauf.append((col as CollisionObject3D).get_rid())
			continue
		return (r2["position"] as Vector3).y
	return -INF


## Les sièges posés par assises_v181 (créés après le dernier rangement des maillages) : dans la grille.
func _ad_sieges_poses() -> void:
	var As = load("res://scripts/pnj/assises_v181.gd")
	if _ad_args.get("debug", false):
		print("AUDIT_SIEGES_POSES ", As._poses.size())
	for st in As._poses.values():
		if is_instance_valid(st) and not (st as Node).has_meta("ad_range"):
			(st as Node).set_meta("ad_range", true)
			for mi in (st as Node).find_children("*", "MeshInstance3D", true, false):
				_ad_mettre(mi, (mi as MeshInstance3D).global_transform * (mi as MeshInstance3D).get_aabb())
