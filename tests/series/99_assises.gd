## Le grand contrôle des bugs visuels, V181 : les gens assis dehors. Beaucoup d'habitants s'asseyaient
## dans le vide (leur lieu à côté du banc, devant la chaise, au-delà du bord du quai, ou rien pour
## s'asseoir) ; pnj/assises_v181.gd les corrige d'après l'audit des lieux (tests/outils/audit_dehors.py
## --assises). On envoie des habitants à des lieux corrigés de chaque sorte (« siege » : sur le banc d'à
## côté ; « bord » : au bord du quai ; « tabouret » : un siège posé) et à des lieux qui allaient déjà bien,
## puis on regarde, sous le bassin, ce qu'on voit (les maillages d'à côté changés en triangles) : quelque
## chose le porte, entre 2 et 25 cm sous l'os du bassin (ni dans le vide, ni enfoncé dedans).
const NOM := "assises181"
const COUCHE99 := 1 << 19
const Tab99 = preload("res://scripts/pnj/assises_table_v181.gd")
const Bancs99 = preload("res://scripts/pnj/bancs_v183.gd")


## Les maillages autour de p, en triangles (sur COUCHE99) ; les personnages exclus.
func _triangles99(p: Vector3) -> Array:
	var zone := AABB(p - Vector3(1.5, 1.2, 1.5), Vector3(3.0, 3.0, 3.0))
	var faits: Array = []
	var gens: Array = []
	for nn in npcs_v31:
		if is_instance_valid(nn):
			gens.append(nn)
	for mi in get_tree().root.find_children("*", "MeshInstance3D", true, false):
		var m: MeshInstance3D = mi
		if m.mesh == null or m.skin != null or m.get_parent() is Skeleton3D or not m.is_visible_in_tree():
			continue
		var bx: AABB = m.global_transform * m.get_aabb()
		if not bx.intersects(zone) or bx.size.length() > 600.0:
			continue
		var sous: bool = false
		var q: Node = m
		while q != null:
			if q in gens:
				sous = true
				break
			q = q.get_parent()
		if sous:
			continue
		faits.append(_corps99(m.global_transform * m.mesh.get_faces(), m))
	for mmi in get_tree().root.find_children("*", "MultiMeshInstance3D", true, false):
		var mm: MultiMesh = (mmi as MultiMeshInstance3D).multimesh
		if mm == null or mm.mesh == null or not (mmi as Node3D).is_visible_in_tree():
			continue
		var f0: PackedVector3Array = mm.mesh.get_faces()
		var tout := PackedVector3Array()
		var n2: int = mm.visible_instance_count if mm.visible_instance_count >= 0 else mm.instance_count
		for k in range(n2):
			var t: Transform3D = (mmi as Node3D).global_transform * mm.get_instance_transform(k)
			if (t * mm.mesh.get_aabb()).intersects(zone):
				tout.append_array(t * f0)
		if not tout.is_empty():
			faits.append(_corps99(tout, mmi))
	return faits


func _corps99(faces: PackedVector3Array, quoi: Node) -> StaticBody3D:
	var sb := StaticBody3D.new()
	sb.collision_layer = COUCHE99
	sb.collision_mask = 0
	var cs := CollisionShape3D.new()
	var sh := ConcavePolygonShape3D.new()
	sh.backface_collision = true
	sh.set_faces(faces)
	cs.shape = sh
	sb.add_child(cs)
	sb.set_meta("quoi", str(quoi.name) + "<" + str(quoi.get_parent().name))
	add_child(sb)
	return sb


## Envoyer l'habitant au lieu (comme s'il y arrivait), puis regarder sous son bassin.
func _assis99(npc: Node3D, lieu: String, quoi: String) -> void:
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
	if not _note(sk != null and sk.find_bone("Hips") >= 0, "%s (%s) : le squelette" % [lieu, quoi]):
		return
	var hb: Vector3 = sk.global_transform * sk.get_bone_global_pose(sk.find_bone("Hips")).origin
	var faits: Array = _triangles99(hb)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var space := get_world_3d().direct_space_state
	var dessous: float = 9.0
	var porte: String = ""
	for dp in [Vector3.ZERO, Vector3(0.1, 0, 0), Vector3(-0.1, 0, 0), Vector3(0, 0, 0.1), Vector3(0, 0, -0.1)]:
		var q := PhysicsRayQueryParameters3D.create(hb + dp + Vector3.UP * 0.1, hb + dp + Vector3.DOWN * 0.8, COUCHE99)
		var r: Dictionary = space.intersect_ray(q)
		if not r.is_empty() and hb.y - (r["position"] as Vector3).y < dessous:
			dessous = hb.y - (r["position"] as Vector3).y
			porte = str((r["collider"] as Node).get_meta("quoi", ""))
	var ech: float = (npc.get("model") as Node3D).global_transform.basis.get_scale().x if npc.get("model") is Node3D else 1.0
	_ok(dessous > 0.02 * ech and dessous < 0.25 * ech, "%s, %s (%s) : quelque chose le porte, %.2f m sous le bassin (%s)" % [str(npc.get("display_name")), lieu, quoi, dessous, porte])
	if quoi == "tabouret":
		_ok(porte.contains("Assise_posee"), "%s : assis sur le siège qu'on a posé (%s)" % [lieu, porte])
	for sb in faits:
		sb.queue_free()


func _serie() -> void:
	# les lieux de chaque sorte, et quelques lieux qui allaient déjà bien
	var voulus: Dictionary = {"siege": 4, "bord": 4, "tabouret": 4, "bien": 3}
	var faits: Dictionary = {}
	var nb: Dictionary = {}
	for e in testeur_v78._npcs():
		var npc: Node3D = e[1]
		if npc.get("azur") == null or not (npc.get("agenda") is Array):
			continue
		var az: Object = npc.get("azur")
		var ville: String = (az.get_script() as Script).resource_path.get_file()
		for a in npc.get("agenda"):
			var lieu: String = str(a[2]) if (a is Array and (a as Array).size() > 2) else ""
			if lieu == "" or lieu == "maison" or lieu.begins_with("course:") or faits.has(ville + ":" + lieu):
				continue
			var sp: Dictionary = az.call("spot", lieu)
			if sp.is_empty() or str(sp.get("pose", "")) != "assis":
				continue
			# (V183 : les bancs de Hautefond, que l'audit ne voyait pas, ont leur propre série : 58_corps)
			if not Bancs99.sous(sp["pos"]).is_empty():
				continue
			var quoi: String = str(Tab99.TABLE[ville + ":" + lieu][0]) if Tab99.TABLE.has(ville + ":" + lieu) else "bien"
			if int(nb.get(quoi, 0)) >= int(voulus.get(quoi, 0)):
				continue
			faits[ville + ":" + lieu] = true
			nb[quoi] = int(nb.get(quoi, 0)) + 1
			await _assis99(npc, lieu, quoi)
	_ok(int(nb.get("siege", 0)) > 0 and int(nb.get("bord", 0)) > 0 and int(nb.get("tabouret", 0)) > 0, "des lieux de chaque sorte : %s" % str(nb))
	_ok(Tab99.TABLE.size() > 50, "la table des corrections : %d lieux" % Tab99.TABLE.size())
