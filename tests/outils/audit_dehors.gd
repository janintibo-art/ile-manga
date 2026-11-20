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
var _ad_grille_gros: Dictionary = {}  # V184 : case de 64 m -> les très grands maillages (plus de 160 m)
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
	if _ad_args.get("chemins", false):
		temps_v56.hour = float((_ad_args.get("heures", [14.0]) as Array)[0])
		await _ad_chemins()
		# (et les plans de quelques bouts de chemin, dans le même lancement)
		if _ad_args.has("radar_chemins"):
			await _ad_radars_chemins(_ad_args["radar_chemins"], str(_ad_args.get("dossier", "/tmp")))
		return
	if _ad_args.has("radar_chemins"):
		temps_v56.hour = 14.0
		await _ad_radars_chemins(_ad_args["radar_chemins"], str(_ad_args.get("dossier", "/tmp")))
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
func _ad_ranger(ici: Vector3, force: bool = false) -> void:
	var n: int = get_tree().get_node_count()
	# (V184 : force, à chaque nouvel endroit des chemins : les maisons d'à côté finissent de se construire
	# quand on arrive, avec moins de 300 nœuds parfois ; sans elles, l'audit ne voyait pas leurs murs)
	if not force and absi(n - _ad_noeuds) < 300 and ici.distance_to(_ad_ou) < 150.0:
		return
	_ad_noeuds = n
	_ad_ou = ici
	_ad_grille.clear()
	_ad_grille_gros.clear()
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
		# très grand : V184, dans une grille à part, de cases de 64 m (avant : rangé seulement au milieu ;
		# un maillage qui réunit tout le verre ou tout le décor d'une ville — plus de 160 m — n'était vu
		# qu'en son centre : l'audit des chemins passait à travers sans le voir)
		for gx in range(floori(bx.position.x / 64.0), floori(bx.end.x / 64.0) + 1):
			for gz in range(floori(bx.position.z / 64.0), floori(bx.end.z / 64.0) + 1):
				var cg := Vector2i(gx, gz)
				if not _ad_grille_gros.has(cg):
					_ad_grille_gros[cg] = []
				(_ad_grille_gros[cg] as Array).append([quoi, bx])
		return
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
	var listes: Array = []
	for x in range(floori(zone.position.x / 8.0), floori(zone.end.x / 8.0) + 1):
		for z in range(floori(zone.position.z / 8.0), floori(zone.end.z / 8.0) + 1):
			listes.append(_ad_grille.get(Vector2i(x, z), []))
	for gx in range(floori(zone.position.x / 64.0), floori(zone.end.x / 64.0) + 1):
		for gz in range(floori(zone.position.z / 64.0), floori(zone.end.z / 64.0) + 1):
			listes.append(_ad_grille_gros.get(Vector2i(gx, gz), []))
	for liste in listes:
		if true:
			for e in liste:
				if not (e[1] as AABB).intersects(zone):
					continue
				# (V184 : un maillage rangé a pu être libéré depuis : un quartier qu'on a quitté)
				var multi: bool = typeof(e[0]) == TYPE_ARRAY
				var obj: Variant = (e[0] as Array)[0] if multi else e[0]
				if not is_instance_valid(obj):
					continue
				var nd: Node3D = obj
				var cle: String = str(nd.get_instance_id()) + (":" + str((e[0] as Array)[1]) if multi else "")
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
func _ad_oublier(p: Vector3, rayon: float = 150.0) -> void:
	for cle in _ad_faits.keys():
		var sb: Variant = _ad_faits[cle]
		if sb is StaticBody3D and is_instance_valid(sb) and ((sb as Node).get_meta("ad_pos") as Vector3).distance_to(p) > rayon:
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


## V184 : le grand contrôle des bugs visuels, les chemins des habitants (audit_dehors.py --chemins). Un
## habitant va d'un lieu à l'autre en ligne droite, de point en point du plan de sa ville (« points » et
## « links », partagés par les habitants de la ville) ; on parcourt chaque bout de chemin comme lui, tous
## les 25 cm, le sol pris comme il le prend (pnj_v31._snap_to_floor : un rayon de 2 m au-dessus à 3 m
## dessous, ou le relief), et l'on regarde si son corps (trois boules de 18 cm, aux genoux, au ventre, à
## la poitrine) passe dans le décor qu'on voit (les maillages, changés en triangles). Une ligne « CHEMIN »
## par bout de chemin qui touche quelque chose : les pas qui touchent (à quelle fraction du chemin, la
## place libre autour de l'axe du corps, ce qui est touché, à quelle hauteur) et les sauts du sol (plus de
## 60 cm d'un pas à l'autre : on monte sur une table, un toit, ou l'on tombe d'un mur).
const AC_PAS := 0.25
const AC_RAYON := 0.18
const AC_HAUTEURS := [0.5, 1.0, 1.45]


## Les plans des villes : [[ville (le script), points, links, [habitants]], …] (les habitants d'une ville
## partagent les mêmes dictionnaires).
func _ad_graphes() -> Array:
	var out: Array = []
	for nn in npcs_v31:
		if not is_instance_valid(nn):
			continue
		var pts: Variant = nn.get("points")
		var lk: Variant = nn.get("links")
		if not (pts is Dictionary) or not (lk is Dictionary) or (lk as Dictionary).is_empty():
			continue
		# (certains habitants ont chacun leur copie du même plan : on ne le parcourt qu'une fois)
		var sig: int = hash(str(pts) + str(lk))
		var g: Array = []
		for e in out:
			if is_same(e[2], lk) or int(e[4]) == sig:
				g = e
				break
		if g.is_empty():
			var ville: Variant = nn.get("azur")
			var src: Object = ville if ville is Object else nn
			var sc: Script = src.get_script()
			var cle: String = sc.resource_path.get_file() if sc != null else str(src)
			if not (ville is Object):
				cle += ":" + str(nn.get("display_name"))
			g = [cle, pts, lk, [], sig]
			out.append(g)
		(g[3] as Array).append(str(nn.get("display_name")))
	return out


## Ce qui n'est pas du décor : les personnages, le héros, les bêtes, les bateaux qui passent.
func _ad_sauf() -> Array:
	var sauf: Array = []
	for nn in npcs_v31:
		if is_instance_valid(nn):
			sauf.append(nn)
	for x in [pc_hero, pc_root, monstres_v36, faune_v132, trafic_v103, oiseaux_v103, compagnons_animaux_v76]:
		if x != null and is_instance_valid(x):
			sauf.append(x)
	for gr in ["cibles_v28", "faune_v132", "monstres_v36"]:
		for x2 in get_tree().get_nodes_in_group(gr):
			sauf.append(x2)
	return sauf


func _ad_corps() -> Array:
	var corps: Array = []
	for hb in [pc_body, vr_body]:
		if hb != null:
			corps.append((hb as CollisionObject3D).get_rid())
	for nn in npcs_v31:
		if is_instance_valid(nn):
			var b: Variant = (nn as Node).get("_body")
			if b is CollisionObject3D:
				corps.append((b as CollisionObject3D).get_rid())
	return corps


## Le sol sous un habitant qui est en p (comme pnj_v31._snap_to_floor).
func _ac_sol(space: PhysicsDirectSpaceState3D, p: Vector3, corps: Array) -> float:
	var q := PhysicsRayQueryParameters3D.create(p + Vector3.UP * 2.0, p + Vector3.DOWN * 3.0, 1, corps)
	var hit: Dictionary = space.intersect_ray(q)
	if not hit.is_empty():
		return (hit["position"] as Vector3).y
	var g: float = _height_at(p.x, p.z)
	var dessus: float = p.y - g
	return g if dessus < 1.5 and dessus > -3.0 else p.y


func _ac_nom(hit: Dictionary) -> String:
	var col: Object = hit.get("collider")
	if col != null and col.has_meta("au_mi"):
		var mi: Node = col.get_meta("au_mi")
		var s: String = str(mi.name)
		var p: Node = mi.get_parent()
		for k in range(2):
			if p == null:
				break
			s += "<" + str(p.name)
			p = p.get_parent()
		return s.replace("\t", " ").replace(";", ",").replace("/", "-")
	return str(col.get("name")) if col != null else "?"


## Autour d'un vrai bout de chemin, ce qu'on laisse libre (m) : 0,75 ; 1,5 sur un détour « souple » de la table.
func _ac_bout(nom: String, e: Array) -> float:
	for nm in [str(e[1]), str(e[2])]:
		if nm.begins_with("ch184|"):
			var pp: PackedStringArray = nm.split("|")
			var T = load("res://scripts/pnj/chemins_table_v184.gd")
			var cle: String = pp[1] + "|" + pp[2]
			for v in T.TABLE.get(cle, []):
				if (v as Array).size() > 3 and int(v[3]) == 1:
					return 1.5
	return AC_APPROCHE


## Un bout de chemin d'un détour (ses points : « ch184|a|b|k ») dont le bout de chemin d'origine a-b est demandé.
func _ac_du_detour(voulues: Dictionary, ville: String, a: String, b: String) -> bool:
	for nm in [a, b]:
		if nm.begins_with("ch184|"):
			var pp: PackedStringArray = nm.split("|")
			if pp.size() >= 3 and voulues.has("%s|%s|%s" % [ville, pp[1], pp[2]]):
				return true
	return false


func _ac_apres(apres: Array, pa: Vector3, pb: Vector3, a: String, b: String) -> bool:
	if apres.is_empty():
		return false
	var m: Vector3 = (pa + pb) * 0.5
	var cx: int = floori(m.x / 64.0)
	var cz: int = floori(m.z / 64.0)
	if cx != int(apres[0]):
		return cx > int(apres[0])
	if cz != int(apres[1]):
		return cz > int(apres[1])
	return a + b > str(apres[2])


func _ac_ordre(x: Array, y: Array) -> bool:
	var mx: Vector3 = ((x[3] as Vector3) + (x[4] as Vector3)) * 0.5
	var my: Vector3 = ((y[3] as Vector3) + (y[4] as Vector3)) * 0.5
	var cx := Vector2i(floori(mx.x / 64.0), floori(mx.z / 64.0))
	var cy := Vector2i(floori(my.x / 64.0), floori(my.z / 64.0))
	if cx.x != cy.x:
		return cx.x < cy.x
	if cx.y != cy.y:
		return cx.y < cy.y
	return str(x[1]) + str(x[2]) < str(y[1]) + str(y[2])


func _ad_chemins() -> void:
	var graphes: Array = _ad_graphes()
	var villes: Array = _ad_args.get("villes", [])
	# (--aretes : seulement ces bouts de chemin, [[ville, a, b], …], en plus des villes demandées)
	var voulues: Dictionary = {}
	for w in _ad_args.get("aretes", []):
		voulues["%s|%s|%s" % [w[0], w[1], w[2]]] = true
		voulues["%s|%s|%s" % [w[0], w[2], w[1]]] = true
	# (--apres : les bouts de chemin rangés après celui-là, [case x, case z, a + b] : reprendre un audit)
	var apres: Array = _ad_args.get("apres", [])
	var tout: bool = villes.is_empty() and voulues.is_empty() and apres.is_empty()
	var aretes: Array = []
	for gi in range(graphes.size()):
		var g: Array = graphes[gi]
		var pts: Dictionary = g[1]
		var lk: Dictionary = g[2]
		print("CHEMIN_PLAN\t%s\t%d points\t%d habitants\t%s" % [g[0], pts.size(), (g[3] as Array).size(), ", ".join(PackedStringArray((g[3] as Array).slice(0, 6)))])
		var ville_ok: bool = tout or str(g[0]) in villes or str(g[0]).get_slice(":", 0) in villes
		for a in lk:
			for b in lk[a]:
				if not pts.has(a) or not pts.has(b) or str(a) == str(b):
					continue
				# chaque bout une seule fois (dans les deux sens)
				if str(a) > str(b) and (lk.get(b, []) as Array).has(a):
					continue
				# un ascenseur, une échelle (on monte plus qu'on n'avance) : on n'y marche pas
				var pa: Vector3 = pts[a]
				var pb: Vector3 = pts[b]
				var dy: float = absf(pb.y - pa.y)
				if dy > 2.5 and dy > Vector2(pb.x - pa.x, pb.z - pa.z).length():
					print("CHEMIN_VERTICAL\t%s\t%s\t%s\t%.1f" % [g[0], a, b, dy])
					continue
				if not ville_ok and not voulues.has("%s|%s|%s" % [g[0], a, b]) and not _ac_apres(apres, pa, pb, str(a), str(b)) and not _ac_du_detour(voulues, str(g[0]), str(a), str(b)):
					continue
				aretes.append([str(g[0]), str(a), str(b), pa, pb])
	# les tours de course (en ligne droite d'un point de la boucle au suivant) et les jeux des enfants
	# (d'un lieu de jeu à l'autre, en ligne droite) : pas par le plan
	var vus_dir: Dictionary = {}
	for nn in npcs_v31:
		if not is_instance_valid(nn) or not (nn.get("agenda") is Array) or nn.get("azur") == null:
			continue
		var az: Object = nn.get("azur")
		var pts2: Dictionary = nn.get("points")
		var nom_v: String = (az.get_script() as Script).resource_path.get_file()
		if not tout and not (nom_v in villes) and apres.is_empty():
			continue
		for en in nn.get("agenda"):
			if not (en is Array) or (en as Array).size() < 3:
				continue
			var cible: Variant = en[2]
			var segs: Array = []
			if str(cible).begins_with("course:"):
				var boucle: Array = Array(str(cible).substr(7).split(","))
				# (V184 : la boucle passe par le plan de la ville : seuls comptent les pas d'un point à un
				# autre qui n'est pas son voisin dans le plan)
				if nn.has_method("_boucle_v184"):
					boucle = nn.call("_boucle_v184", str(cible).substr(7).split(","))
				var lk2: Dictionary = nn.get("links")
				for k in range(boucle.size()):
					var b0: String = str(boucle[k])
					var b1: String = str(boucle[(k + 1) % boucle.size()])
					if not (lk2.get(b0, []) as Array).has(b1):
						segs.append([b0, b1, "course"])
			elif (en as Array).size() > 3 and en[3] is Array:
				var lieux_j: Array = (en[3] as Array).duplicate()
				lieux_j.append(cible)
				var noeuds: Array = []
				for lj in lieux_j:
					var sp: Dictionary = az.call("spot", str(lj))
					if not sp.is_empty() and str(sp.get("pose", "")) == "jouer":
						noeuds.append(str(sp.get("node", "")))
				# (V184 : d'un lieu de jeu à l'autre par le plan, quand il les relie ; sinon en ligne droite)
				var relie: bool = nn.has_method("_boucle_v184")
				for k1 in range(noeuds.size()):
					for k2 in range(k1 + 1, noeuds.size()):
						if not relie or (nn.call("_boucle_v184", PackedStringArray([noeuds[k1], noeuds[k2]])) as Array).size() <= 2:
							segs.append([noeuds[k1], noeuds[k2], "jeu"])
			for sg in segs:
				var sa: String = str(sg[0])
				var sb: String = str(sg[1])
				if sa == sb or not pts2.has(sa) or not pts2.has(sb):
					continue
				var cle_d: String = nom_v + ":" + (sa + "|" + sb if sa < sb else sb + "|" + sa)
				if vus_dir.has(cle_d):
					continue
				if not tout and not (nom_v in villes) and not _ac_apres(apres, pts2[sa], pts2[sb], sa, sb):
					continue
				vus_dir[cle_d] = true
				aretes.append([nom_v + ":" + str(sg[2]), sa, sb, pts2[sa], pts2[sb]])
	# rangés par cases de 64 m (on se déplace le moins possible)
	aretes.sort_custom(_ac_ordre)
	var de: int = int(_ad_args.get("de", 0))
	var a2: int = mini(int(_ad_args.get("a", aretes.size())), aretes.size())
	print("CHEMINS_DEBUT %d plans, %d bouts de chemin, de %d à %d" % [graphes.size(), aretes.size(), de, a2])
	var cellule := Vector2i(1 << 30, 0)
	var ici := Vector3(1e9, 0, 0)
	var n_cas: int = 0
	for i in range(de, a2):
		var e: Array = aretes[i]
		var A: Vector3 = e[3]
		var B: Vector3 = e[4]
		var mil: Vector3 = (A + B) * 0.5
		var c := Vector2i(floori(mil.x / 64.0), floori(mil.z / 64.0))
		if c != cellule or ici.distance_to(mil) > 80.0:
			cellule = c
			ici = mil
			place_player_v35(A + Vector3.UP * 0.3, B - A)
			await _att(2.0)
			_ad_ranger(A, true)
			# (V184 : on rend les triangles plus tôt : à garder ceux de tout le jeu, la mémoire n'y suffit pas)
			_ad_oublier(A, 100.0)
		if (i - de) % 200 == 199:
			print("CHEMINS_MEMOIRE %d bouts, %d Mo, %d maillages en triangles" % [i - de + 1, OS.get_static_memory_usage() / 1048576, _ad_faits.size()])
		var cas: bool = await _ad_arete(i, e)
		if cas:
			n_cas += 1
	print("CHEMINS_FIN %d bouts de chemin regardés, %d touchent le décor" % [a2 - de, n_cas])


## Un bout de chemin : vrai s'il touche le décor qu'on voit (ou si le sol saute).
func _ad_arete(i: int, e: Array) -> bool:
	var A: Vector3 = e[3]
	var B: Vector3 = e[4]
	var plat := Vector3(B.x - A.x, 0.0, B.z - A.z)
	var L: float = plat.length()
	var n: int = maxi(1, ceili(L / AC_PAS))
	var sauf: Array = _ad_sauf()
	var s: float = 0.0
	while true:
		_ad_triangles(A.lerp(B, clampf(s / maxf(L, 0.01), 0.0, 1.0)), sauf)
		if s >= L:
			break
		s = minf(s + 2.4, L)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var space := get_world_3d().direct_space_state
	var corps: Array = _ad_corps()
	var y: float = _ac_sol(space, A, corps)
	var pas: Array = []            # les pas qui touchent : "t/libre/quoi@hauteur"
	var sauts: Array = []
	var libre_min: float = AC_RAYON
	var grave: bool = false        # l'axe du corps à moins de 10 cm du décor, loin des deux bouts
	for k in range(n + 1):
		var t: float = float(k) / float(n)
		var p := Vector3(lerpf(A.x, B.x, t), y, lerpf(A.z, B.z, t))
		var y2: float = _ac_sol(space, p, corps)
		if absf(y2 - y) > 0.6:
			sauts.append("%.2f/%.2f/%.2f" % [t, y, y2])
			grave = true
		y = y2
		p.y = y
		var lib: float = AC_RAYON
		var nom: String = ""
		for h in AC_HAUTEURS:
			var cc: Vector3 = p + Vector3.UP * float(h)
			var hit: Dictionary = _au_boule(space, cc, AC_RAYON, AD_COUCHE, [])
			if hit.is_empty():
				continue
			var lb: float = _au_libre(space, cc, AC_RAYON, AD_COUCHE, [])
			if nom == "" or lb < lib:
				lib = minf(lib, lb)
				nom = _ac_nom(hit) + "@" + str(h)
		if nom != "":
			pas.append("%.2f/%.3f/%s" % [t, lib, nom])
			libre_min = minf(libre_min, lib)
			# (près d'un vrai bout de chemin, on y arrive comme avant ; près d'un point de détour, non : le
			# détour doit être libre tout du long ; un détour « souple » : 1,5 m libres autour des vrais bouts)
			if lib < AC_SEUIL and (t * L > _ac_bout(str(e[1]), e) or e[1].begins_with("ch184|")) and ((1.0 - t) * L > _ac_bout(str(e[2]), e) or e[2].begins_with("ch184|")):
				grave = true
	if pas.is_empty() and sauts.is_empty():
		return false
	print("CHEMIN\t%d\t%s\t%s\t%s\t%.1f\t%d/%d\t%.3f\t%.2f,%.2f,%.2f\t%.2f,%.2f,%.2f\t%s\t%s" % [i, e[0], e[1], e[2], L, pas.size(), n + 1, libre_min,
		A.x, A.y, A.z, B.x, B.y, B.z, ";".join(PackedStringArray(pas)), ";".join(PackedStringArray(sauts))])
	if grave and _ad_args.get("detours", false):
		var det: Array = []
		var souple: bool = false
		for essai in range(2):
			souple = essai == 1
			_ac_marge = 0.15 if souple else AC_MARGE
			_ac_marche = 0.5 if souple else 0.35
			_ac_approche = 1.5 if souple else AC_APPROCHE
			for large in [4.0, 9.0, 15.0]:
				det = await _ac_detour(A, B, large, corps)
				if not det.is_empty():
					break
			if not det.is_empty():
				break
		_ac_marge = AC_MARGE
		_ac_marche = 0.35
		_ac_approche = AC_APPROCHE
		if det.is_empty():
			print("CHEMIN_DETOUR_ECHEC\t%d\t%s\t%s\t%s" % [i, e[0], e[1], e[2]])
		else:
			var long: float = 0.0
			var prec: Vector3 = A
			var txt: Array = []
			for w in det:
				long += Vector2((w as Vector3).x - prec.x, (w as Vector3).z - prec.z).length()
				prec = w
				txt.append("%.2f,%.2f,%.2f" % [(w as Vector3).x, (w as Vector3).y, (w as Vector3).z])
			long += Vector2(B.x - prec.x, B.z - prec.z).length()
			print("CHEMIN_DETOUR\t%d\t%s\t%s\t%s\t%.2f,%.2f\t%.2f,%.2f\t%.1f\t%.1f\t%s\t%s" % [i, e[0], e[1], e[2], A.x, A.z, B.x, B.z, L, long, ";".join(PackedStringArray(txt)), "souple" if souple else ""])
	return true


## Les détours (audit_dehors.py --chemins --detours) : pour un bout de chemin où l'axe du corps passe à
## moins de 10 cm du décor (loin des deux bouts), une grille de 30 cm le long du chemin (« large » m de
## chaque côté, 1,8 m avant et après) ; une case est libre si le corps y tient (trois boules de 22 cm) ;
## près des deux bouts (75 cm), on passe toujours (on y arrive comme avant) ; d'une case à l'autre, le sol
## ne saute pas de plus de 35 cm. Le plus court chemin (A*), puis tendu : le moins de points possible,
## chaque ligne droite gardant le corps hors du décor. Les points du détour (sans A ni B), ou [].
const AC_SEUIL := 0.1
const AC_CASE := 0.3
const AC_MARGE := 0.22
const AC_APPROCHE := 0.75
var _ac_marge: float = AC_MARGE
var _ac_marche: float = 0.35
var _ac_approche: float = AC_APPROCHE


func _ac_libre_ici(space: PhysicsDirectSpaceState3D, p: Vector3) -> bool:
	for h in AC_HAUTEURS:
		if not _au_boule(space, p + Vector3.UP * float(h), _ac_marge, AD_COUCHE, []).is_empty():
			return false
	return true


func _ac_pres(p: Vector3, A: Vector3, B: Vector3) -> bool:
	return Vector2(p.x - A.x, p.z - A.z).length() < _ac_approche or Vector2(p.x - B.x, p.z - B.z).length() < _ac_approche


func _ac_ligne_libre(space: PhysicsDirectSpaceState3D, P: Vector3, Q: Vector3, A: Vector3, B: Vector3, corps: Array) -> bool:
	var d := Vector3(Q.x - P.x, 0.0, Q.z - P.z)
	var n: int = maxi(1, ceili(d.length() / 0.15))
	var y: float = P.y
	for k in range(1, n + 1):
		var t: float = float(k) / float(n)
		var p := Vector3(lerpf(P.x, Q.x, t), y, lerpf(P.z, Q.z, t))
		var y2: float = _ac_sol(space, p, corps)
		if absf(y2 - y) > _ac_marche - 0.05:
			return false
		y = y2
		p.y = y
		if not _ac_pres(p, A, B) and not _ac_libre_ici(space, p):
			return false
	return true


func _ac_detour(A: Vector3, B: Vector3, large: float, corps: Array) -> Array:
	var plat := Vector3(B.x - A.x, 0.0, B.z - A.z)
	var L: float = plat.length()
	if L < 0.3:
		return []
	var u: Vector3 = plat / L
	var v := Vector3(-u.z, 0.0, u.x)
	var h: float = AC_CASE
	var u0: float = -6.0 * h
	var nu: int = ceili((L - 2.0 * u0) / h) + 1
	var nv: int = ceili(2.0 * large / h) + 1
	var v0: float = -float(nv - 1) * 0.5 * h
	# les triangles du décor de toute la zone
	var sauf: Array = _ad_sauf()
	var su: float = u0 - 1.0
	while su <= L - u0 + 1.0:
		var sv: float = v0 - 1.0
		while sv <= -v0 + 1.0:
			_ad_triangles(Vector3(A.x, lerpf(A.y, B.y, clampf(su / L, 0.0, 1.0)), A.z) + u * su + v * sv, sauf)
			sv += 2.4
		su += 2.4
	await get_tree().physics_frame
	await get_tree().physics_frame
	var space := get_world_3d().direct_space_state
	var n: int = nu * nv
	# chaque case n'est regardée que si le chemin y passe (0 : pas encore regardée, 1 : libre, 2 : prise)
	var sol := PackedFloat32Array()
	sol.resize(n)
	var etat := PackedByteArray()
	etat.resize(n)
	var s: int = roundi(-u0 / h) * nv + roundi(-v0 / h)
	var but: int = roundi((L - u0) / h) * nv + roundi(-v0 / h)
	if s < 0 or s >= n or but < 0 or but >= n:
		return []
	for c0 in [s, but]:
		var p0: Vector3 = Vector3(A.x, 0.0, A.z) + u * (u0 + (c0 / nv) * h) + v * (v0 + (c0 % nv) * h)
		p0.y = A.y if c0 == s else B.y
		sol[c0] = _ac_sol(space, p0, corps)
		etat[c0] = 1
	var g := PackedFloat32Array()
	g.resize(n)
	g.fill(INF)
	var prev := PackedInt32Array()
	prev.resize(n)
	prev.fill(-1)
	var ferme := PackedByteArray()
	ferme.resize(n)
	var hf: Array = []
	var hi: Array = []
	g[s] = 0.0
	var bu: int = but / nv
	var bv: int = but % nv
	hf.append(0.0)
	hi.append(s)
	var dirs := [[1, 0], [-1, 0], [0, 1], [0, -1], [1, 1], [1, -1], [-1, 1], [-1, -1]]
	var trouve: bool = false
	var vus: int = 0
	while not hi.is_empty():
		var cur: int = hi[0]
		var lf: float = hf.pop_back()
		var li: int = hi.pop_back()
		if not hi.is_empty():
			hf[0] = lf
			hi[0] = li
			var j: int = 0
			while true:
				var l: int = 2 * j + 1
				if l >= hi.size():
					break
				var m: int = l
				if l + 1 < hi.size() and float(hf[l + 1]) < float(hf[l]):
					m = l + 1
				if float(hf[m]) < float(hf[j]):
					var tf: float = hf[m]
					hf[m] = hf[j]
					hf[j] = tf
					var ti: int = hi[m]
					hi[m] = hi[j]
					hi[j] = ti
					j = m
				else:
					break
		if ferme[cur] == 1:
			continue
		ferme[cur] = 1
		if cur == but:
			trouve = true
			break
		var cu: int = cur / nv
		var cv: int = cur % nv
		# les voisines, regardées au besoin (le sol pris depuis la case où l'on est)
		for dd in dirs:
			var nu2: int = cu + int(dd[0])
			var nv2: int = cv + int(dd[1])
			if nu2 < 0 or nu2 >= nu or nv2 < 0 or nv2 >= nv:
				continue
			var nb: int = nu2 * nv + nv2
			if etat[nb] == 0:
				var p: Vector3 = Vector3(A.x, sol[cur], A.z) + u * (u0 + nu2 * h) + v * (v0 + nv2 * h)
				var y: float = _ac_sol(space, p, corps)
				p.y = y
				sol[nb] = y
				etat[nb] = 1 if (_ac_pres(p, A, B) or _ac_libre_ici(space, p)) else 2
				vus += 1
		for dd in dirs:
			var nu3: int = cu + int(dd[0])
			var nv3: int = cv + int(dd[1])
			if nu3 < 0 or nu3 >= nu or nv3 < 0 or nv3 >= nv:
				continue
			var nb3: int = nu3 * nv + nv3
			if etat[nb3] != 1 or ferme[nb3] == 1:
				continue
			var diag: bool = int(dd[0]) != 0 and int(dd[1]) != 0
			if absf(sol[nb3] - sol[cur]) > (_ac_marche + 0.1 if diag else _ac_marche):
				continue
			if diag and (etat[cu * nv + nv3] != 1 or etat[nu3 * nv + cv] != 1):
				continue
			# (le sol au milieu du pas aussi : en coupant le coin d'un comptoir, d'un muret, on montait dessus)
			var pmil: Vector3 = Vector3(A.x, sol[cur], A.z) + u * (u0 + (cu + nu3) * 0.5 * h) + v * (v0 + (cv + nv3) * 0.5 * h)
			var ymil: float = _ac_sol(space, pmil, corps)
			if absf(ymil - sol[cur]) > _ac_marche or absf(sol[nb3] - ymil) > _ac_marche:
				continue
			var ng: float = g[cur] + h * (1.4142 if diag else 1.0)
			if ng < g[nb3]:
				g[nb3] = ng
				prev[nb3] = cur
				hf.append(ng + h * Vector2(nu3 - bu, nv3 - bv).length())
				hi.append(nb3)
				var j2: int = hf.size() - 1
				while j2 > 0:
					var p2: int = (j2 - 1) / 2
					if float(hf[p2]) > float(hf[j2]):
						var tf2: float = hf[p2]
						hf[p2] = hf[j2]
						hf[j2] = tf2
						var ti2: int = hi[p2]
						hi[p2] = hi[j2]
						hi[j2] = ti2
						j2 = p2
					else:
						break
	if not trouve:
		return []
	# les cases du chemin, de A à B
	var cases: Array = []
	var c: int = but
	while c != -1:
		cases.push_front(c)
		c = prev[c]
	var pts: Array = [A]
	for k in range(1, cases.size() - 1):
		var ck: int = cases[k]
		var q: Vector3 = Vector3(A.x, 0.0, A.z) + u * (u0 + (ck / nv) * h) + v * (v0 + (ck % nv) * h)
		q.y = sol[ck]
		pts.append(q)
	pts.append(B)
	# tendu : de point en point, aussi loin qu'on peut aller en ligne droite
	var out: Array = []
	var i: int = 0
	var der: int = pts.size() - 1
	while i < der:
		var j3: int = i + 1
		while j3 + 1 <= der and _ac_ligne_libre(space, pts[i], pts[j3 + 1], A, B, corps):
			j3 += 1
		if j3 < der:
			out.append(pts[j3])
		i = j3
	return out


## Les plans des chemins (audit_dehors.py --radar_chemins liste.json --dossier DOSSIER) : vu de dessus, une
## coupe du décor à hauteur d'homme (des rayons qui descendent de 1,7 m au-dessus du chemin) : le sol en
## gris (plus clair plus haut), ce qu'on coupe (un mur, un tronc) en brun foncé, rien en noir. Une image
## par bout de chemin (et un fichier .json : où est l'image dans le monde) ; audit_dehors.py y trace le
## chemin d'avant (rouge) et le détour (vert). liste.json : [{"nom", "A": [x, y, z], "B": [x, y, z],
## "detour": [[x, y, z], …]}, …].
func _ad_radars_chemins(items: Array, dossier: String) -> void:
	var sauf: Array = _ad_sauf()
	for it in items:
		var A := Vector3(float(it["A"][0]), float(it["A"][1]), float(it["A"][2]))
		var B := Vector3(float(it["B"][0]), float(it["B"][1]), float(it["B"][2]))
		var tous: Array = [A, B]
		for w in it.get("detour", []):
			tous.append(Vector3(float(w[0]), float(w[1]), float(w[2])))
		var lo := Vector2(1e9, 1e9)
		var hi := Vector2(-1e9, -1e9)
		for q in tous:
			lo = Vector2(minf(lo.x, (q as Vector3).x), minf(lo.y, (q as Vector3).z))
			hi = Vector2(maxf(hi.x, (q as Vector3).x), maxf(hi.y, (q as Vector3).z))
		lo -= Vector2(4.0, 4.0)
		hi += Vector2(4.0, 4.0)
		var taille: Vector2 = hi - lo
		var ech: float = minf(420.0 / taille.x, 320.0 / taille.y)
		var w_px: int = maxi(40, int(taille.x * ech))
		var h_px: int = maxi(40, int(taille.y * ech))
		var mil: Vector3 = (A + B) * 0.5
		place_player_v35(mil + Vector3.UP * 0.3, B - A)
		await _att(1.4)
		_ad_ranger(mil)
		_ad_oublier(mil)
		_ad_sieges_poses()
		sauf = _ad_sauf()
		var y_moy: float = (A.y + B.y) * 0.5
		var sx: float = lo.x
		while sx <= hi.x + 2.4:
			var sz: float = lo.y
			while sz <= hi.y + 2.4:
				_ad_triangles(Vector3(sx, y_moy, sz), sauf)
				sz += 2.4
			sx += 2.4
		await get_tree().physics_frame
		await get_tree().physics_frame
		var space := get_world_3d().direct_space_state
		var img := Image.create(w_px, h_px, false, Image.FORMAT_RGB8)
		var ab := Vector2(B.x - A.x, B.z - A.z)
		var L2: float = maxf(ab.length_squared(), 0.0001)
		for py in range(h_px):
			for px in range(w_px):
				var x: float = lo.x + (float(px) + 0.5) / ech
				var z: float = lo.y + (float(py) + 0.5) / ech
				var t: float = clampf(Vector2(x - A.x, z - A.z).dot(ab) / L2, 0.0, 1.0)
				var y0: float = lerpf(A.y, B.y, t)
				var q := PhysicsRayQueryParameters3D.create(Vector3(x, y0 + 1.7, z), Vector3(x, y0 - 2.5, z), AD_COUCHE | 1)
				q.hit_back_faces = true
				var r: Dictionary = space.intersect_ray(q)
				var col := Color(0.05, 0.05, 0.07)
				if not r.is_empty():
					var nrm: Vector3 = r["normal"]
					var hy: float = (r["position"] as Vector3).y - y0
					var vu: bool = (r["collider"] as Object).has_meta("au_mi")
					if nrm.y < 0.35:
						col = Color(0.42, 0.22, 0.12) if vu else Color(0.3, 0.25, 0.3)
					elif hy > 0.3:
						col = Color(0.85, 0.62, 0.3).lerp(Color(0.95, 0.85, 0.6), clampf((hy - 0.3) / 1.4, 0.0, 1.0))
					else:
						col = Color(0.5, 0.52, 0.5).lerp(Color(0.8, 0.82, 0.8), clampf((hy + 0.6) / 0.9, 0.0, 1.0))
						if not vu:
							col = col * Color(0.85, 0.9, 1.0)
				img.set_pixel(px, py, col)
		var base: String = "%s/%s" % [dossier, str(it["nom"]).replace("/", "_").replace("|", "_").replace(" ", "_")]
		img.save_png(base + ".png")
		var f := FileAccess.open(base + ".json", FileAccess.WRITE)
		f.store_string(JSON.stringify({"lo": [lo.x, lo.y], "ech": ech, "w": w_px, "h": h_px}))
		f.close()
		print("RADAR_CHEMIN ", it["nom"])
