## V184 : le grand contrôle des bugs visuels, les chemins des habitants. Un habitant va de point en point
## du plan de sa ville, en ligne droite ; des bouts de chemin passaient à travers une maison, un mur, un
## arbre, un étal, ou montaient sur un comptoir, une table (le sol pris d'en haut). L'audit des chemins
## (tests/outils/audit_dehors.py --chemins --detours --table) en a fait une table de détours
## (pnj/chemins_table_v184.gd), appliquée aux plans des villes (pnj/chemins_v184.gd) :
##   - chaque détour de la table est dans le plan de sa ville : le lien direct n'y est plus, la chaîne
##     (a, les points du détour, b) est complète ;
##   - le long d'un détour, le sol ne saute pas (comme l'habitant le prend : un rayon de 2 m au-dessus),
##     sauf à 75 cm des deux bouts (un bout posé sur une estrade : le détour n'y peut rien) ;
##   - le long d'un détour, le corps (trois boules) reste hors du décor qu'on voit (les maillages proches,
##     changés en triangles), sauf à 75 cm des deux bouts (1,5 m pour un détour « souple ») ;
##   - un habitant qui va de a à b passe par le détour (il ne coupe pas tout droit).
const NOM := "41_chemins"
const CH_COUCHE := 1 << 19
const CH_RAYON := 0.18
const CH_HAUTEURS := [0.5, 1.0, 1.45]
var _ch_faits: Dictionary = {}


func _serie() -> void:
	# (à 14 h, l'heure de l'audit : les étals, les chaises des terrasses ne sont pas les mêmes à toute heure)
	temps_v56.set_hour(14.0)
	var C = load("res://scripts/pnj/chemins_v184.gd")
	var T = load("res://scripts/pnj/chemins_table_v184.gd")
	_ok(not T.TABLE.is_empty(), "la table des détours n'est pas vide (%d bouts de chemin)" % T.TABLE.size())
	# les plans des villes (partagés par leurs habitants)
	var graphes: Array = []
	for nn in npcs_v31:
		if not is_instance_valid(nn):
			continue
		var pts: Variant = nn.get("points")
		var lk: Variant = nn.get("links")
		if not (pts is Dictionary) or not (lk is Dictionary) or (lk as Dictionary).is_empty():
			continue
		var deja: bool = false
		for g in graphes:
			if is_same(g[1], lk):
				deja = true
				(g[2] as Array).append(nn)
				break
		if not deja:
			graphes.append([pts, lk, [nn]])
	# 1) chaque détour est dans le plan de sa ville
	var n: int = 0
	var bons: int = 0
	var sans_objet: int = 0          # le lien direct n'est pas dans le plan du jeu (d'autres détours l'ont changé)
	var mauvais: Array = []
	var detours: Array = []          # [a, b, [a, les points du détour…, b], n° du plan]
	for cle in T.TABLE:
		var ab: PackedStringArray = str(cle).split("|")
		for v in T.TABLE[cle]:
			n += 1
			var trouve: bool = false
			for gi in range(graphes.size()):
				var g: Array = graphes[gi]
				var pts: Dictionary = g[0]
				var lk: Dictionary = g[1]
				if not pts.has(ab[0]) or not pts.has(ab[1]):
					continue
				var pa: Vector3 = pts[ab[0]]
				if Vector2(pa.x - float(v[0]), pa.z - float(v[1])).length() > 1.0:
					continue
				var chaine: Array = [ab[0]]
				var k: int = 0
				while pts.has(C.nom(ab[0], ab[1], k)):
					chaine.append(C.nom(ab[0], ab[1], k))
					k += 1
				chaine.append(ab[1])
				var direct: bool = (lk.get(ab[0], []) as Array).has(ab[1]) or (lk.get(ab[1], []) as Array).has(ab[0])
				if k == 0 and not direct:
					# (ex. : chez Larsen, la maison d'un habitant est reliée aux voisins de la porte de sa
					# yourte ; la porte a déjà son détour : la maison est reliée au point du détour)
					sans_objet += 1
					trouve = true
					break
				var ok: bool = k == (v[2] as Array).size() / 3 and k > 0
				var aller: bool = (lk.get(ab[0], []) as Array).has(chaine[1])
				var retour: bool = (lk.get(ab[1], []) as Array).has(chaine[-2])
				ok = ok and (aller or retour)
				ok = ok and not (lk.get(ab[0], []) as Array).has(ab[1]) and not (lk.get(ab[1], []) as Array).has(ab[0])
				for i in range(chaine.size() - 1):
					if aller and not (lk.get(chaine[i], []) as Array).has(chaine[i + 1]):
						ok = false
					if retour and not (lk.get(chaine[i + 1], []) as Array).has(chaine[i]):
						ok = false
				if ok:
					trouve = true
					var pp: Array = []
					for nm in chaine:
						pp.append(pts[nm])
					detours.append([ab[0], ab[1], pp, gi, 1.5 if (v as Array).size() > 3 and int(v[3]) == 1 else 0.75])
				break
			if trouve:
				bons += 1
			elif mauvais.size() < 6:
				mauvais.append(str(cle))
	_ok(n > 0 and bons == n, "chaque détour de la table est dans le plan de sa ville, la chaîne complète (%d sur %d, dont %d sans objet : le lien direct n'y est plus)%s" % [bons, n, sans_objet, "" if mauvais.is_empty() else " ; pas : " + ", ".join(PackedStringArray(mauvais))])
	# 2) et 3) des détours de plusieurs villes : on y va, on les parcourt comme un habitant
	var choisis: Array = []
	var villes_vues: Dictionary = {}
	for d in detours:
		var gk: int = int(d[3])
		if int(villes_vues.get(gk, 0)) >= 2:
			continue
		villes_vues[gk] = int(villes_vues.get(gk, 0)) + 1
		choisis.append(d)
	var sauts: Array = []
	var dedans: Array = []
	for d in choisis:
		var pp: Array = d[2]
		var A: Vector3 = pp[0]
		place_player_v35(A + Vector3.UP * 0.3, (pp[1] as Vector3) - A)
		await _att(1.3)
		var res: Array = await _ch_parcourir(pp, float(d[4]))
		if float(res[0]) > 0.6:
			sauts.append("%s—%s (%.1f m)" % [d[0], d[1], res[0]])
		# (l'audit garde l'axe du corps à 10 cm du décor ; ici, d'autres pas de 25 cm : 5 cm de tolérance)
		if float(res[1]) < 0.05:
			dedans.append("%s—%s (%.2f m, %s)" % [d[0], d[1], res[1], res[2]])
	_ok(sauts.is_empty(), "le long de %d détours (dans %d villes), le sol ne saute pas%s" % [choisis.size(), villes_vues.size(), "" if sauts.is_empty() else " : " + ", ".join(PackedStringArray(sauts.slice(0, 5)))])
	_ok(dedans.is_empty(), "le long de ces détours, le corps reste hors du décor (l'axe à plus de 5 cm)%s" % ["" if dedans.is_empty() else " : " + ", ".join(PackedStringArray(dedans.slice(0, 5)))])
	# 4) un habitant qui va de a à b passe par le détour
	var essai: Array = []
	for d in choisis:
		for nn in (graphes[int(d[3])] as Array)[2]:
			if is_instance_valid(nn) and nn.get("azur") != null:
				essai = [d, nn]
				break
		if not essai.is_empty():
			break
	if _ok(not essai.is_empty(), "un habitant d'une ville où il y a un détour"):
		var d2: Array = essai[0]
		var npc: Node3D = essai[1]
		var pp2: Array = d2[2]
		npc.set("_flane", [])
		npc.set("_run_loop", [])
		npc.set("_check", 999.0)
		npc.call("_set_hidden", false)
		npc.set("at_point", str(d2[0]))
		npc.global_position = pp2[0]
		npc.call("_snap_to_floor")
		var route: Array = npc.call("_route_to", str(d2[1]))
		var coupe: bool = false
		var prec: String = str(d2[0])
		for r in route:
			if (prec == str(d2[0]) and str(r) == str(d2[1])) or (prec == str(d2[1]) and str(r) == str(d2[0])):
				coupe = true
			prec = str(r)
		_ok(not route.is_empty() and not coupe, "%s, de %s à %s : son chemin ne coupe plus tout droit (%d étapes)" % [npc.get("display_name"), d2[0], d2[1], route.size()])
		# il marche (le joueur à côté : il ne saute pas à l'arrivée) ; il reste sur son chemin
		var trace: Array = [pp2[0]]
		for r2 in route:
			trace.append((npc.get("points") as Dictionary)[r2])
		place_player_v35((pp2[0] as Vector3) + Vector3(1.5, 0.3, 1.5), Vector3.FORWARD)
		npc.set("route", route)
		npc.set("target_spot", "")
		npc.set("state", "marche")
		npc.set("_check", 999.0)
		var ecart: float = 0.0
		var t0: int = Time.get_ticks_msec()
		while Time.get_ticks_msec() - t0 < 25000 and str(npc.get("state")) == "marche":
			place_player_v35(npc.global_position + Vector3(1.6, 0.3, 1.6), Vector3.FORWARD)
			await _att(0.25)
			ecart = maxf(ecart, _ch_ecart(npc.global_position, trace))
		_ok(ecart < 0.6, "%s suit son chemin, détour compris (au plus %.2f m de la ligne)" % [npc.get("display_name"), ecart])


## Le plus loin qu'est p de la ligne brisée (à plat).
func _ch_ecart(p: Vector3, trace: Array) -> float:
	var best: float = INF
	for i in range(trace.size() - 1):
		var a := Vector2((trace[i] as Vector3).x, (trace[i] as Vector3).z)
		var b := Vector2((trace[i + 1] as Vector3).x, (trace[i + 1] as Vector3).z)
		var q := Vector2(p.x, p.z)
		var ab: Vector2 = b - a
		var t: float = clampf((q - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
		best = minf(best, q.distance_to(a + ab * t))
	return best


## On parcourt la ligne brisée pp comme un habitant (tous les 25 cm, le sol pris comme lui) : [le plus
## grand saut du sol, la place libre la plus petite autour de l'axe du corps (loin des deux bouts), ce
## qui la prend].
func _ch_parcourir(pp: Array, bout: float = 0.75) -> Array:
	_ch_triangles(pp)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var space := get_world_3d().direct_space_state
	var corps: Array = []
	for hb in [pc_body, vr_body]:
		if hb != null:
			corps.append((hb as CollisionObject3D).get_rid())
	for nn in npcs_v31:
		if is_instance_valid(nn) and (nn as Node).get("_body") is CollisionObject3D:
			corps.append(((nn as Node).get("_body") as CollisionObject3D).get_rid())
	var A: Vector3 = pp[0]
	var B: Vector3 = pp[-1]
	var y: float = _ch_sol(space, A, corps)
	var saut: float = 0.0
	var libre: float = 9.0
	var quoi: String = ""
	for i in range(pp.size() - 1):
		var P: Vector3 = pp[i]
		var Q: Vector3 = pp[i + 1]
		var n: int = maxi(1, ceili(Vector2(Q.x - P.x, Q.z - P.z).length() / 0.25))
		for k in range(1, n + 1):
			var t: float = float(k) / float(n)
			var p := Vector3(lerpf(P.x, Q.x, t), y, lerpf(P.z, Q.z, t))
			var y2: float = _ch_sol(space, p, corps)
			var pres: bool = Vector2(p.x - A.x, p.z - A.z).length() < bout or Vector2(p.x - B.x, p.z - B.z).length() < bout
			# (près des deux bouts, on y arrive comme avant : un bout posé sur une estrade, le détour n'y peut rien)
			if not pres:
				saut = maxf(saut, absf(y2 - y))
			y = y2
			p.y = y
			if pres:
				continue
			for h in CH_HAUTEURS:
				var hit: Dictionary = _ch_boule(space, p + Vector3.UP * float(h), CH_RAYON)
				if hit.is_empty():
					continue
				var lo: float = 0.0
				var hi: float = CH_RAYON
				for s in range(5):
					var m: float = (lo + hi) * 0.5
					if _ch_boule(space, p + Vector3.UP * float(h), m).is_empty():
						lo = m
					else:
						hi = m
				if lo < libre:
					libre = lo
					var col: Object = hit.get("collider")
					quoi = str((col.get_meta("ch_mi") as Node).name) if col != null and col.has_meta("ch_mi") else "?"
	return [saut, libre, quoi]


func _ch_sol(space: PhysicsDirectSpaceState3D, p: Vector3, corps: Array) -> float:
	var q := PhysicsRayQueryParameters3D.create(p + Vector3.UP * 2.0, p + Vector3.DOWN * 3.0, 1, corps)
	var hit: Dictionary = space.intersect_ray(q)
	if not hit.is_empty():
		return (hit["position"] as Vector3).y
	var g: float = _height_at(p.x, p.z)
	return g if p.y - g < 1.5 and p.y - g > -3.0 else p.y


func _ch_boule(space: PhysicsDirectSpaceState3D, c: Vector3, r: float) -> Dictionary:
	var q := PhysicsShapeQueryParameters3D.new()
	var sp := SphereShape3D.new()
	sp.radius = r
	q.shape = sp
	q.transform = Transform3D(Basis(), c)
	q.collision_mask = CH_COUCHE
	var res: Array = space.intersect_shape(q, 1)
	return res[0] if not res.is_empty() else {}


## Les maillages qu'on voit le long de la ligne brisée (à moins de 3 m), changés en triangles (couche à
## part) ; pas les personnages, ni le héros, ni les bêtes.
func _ch_triangles(pp: Array) -> void:
	var lo := Vector3(INF, INF, INF)
	var hi := Vector3(-INF, -INF, -INF)
	for q in pp:
		lo = Vector3(minf(lo.x, (q as Vector3).x), minf(lo.y, (q as Vector3).y), minf(lo.z, (q as Vector3).z))
		hi = Vector3(maxf(hi.x, (q as Vector3).x), maxf(hi.y, (q as Vector3).y), maxf(hi.z, (q as Vector3).z))
	var zone := AABB(lo - Vector3(3, 1, 3), hi - lo + Vector3(6, 4, 6))
	var sauf: Array = npcs_v31.duplicate()
	for x in [pc_hero, pc_root, monstres_v36, faune_v132, trafic_v103, oiseaux_v103]:
		if x != null:
			sauf.append(x)
	for mi in get_tree().root.find_children("*", "MeshInstance3D", true, false):
		var m: MeshInstance3D = mi
		if m.mesh == null or m.skin != null or m.get_parent() is Skeleton3D or not m.is_visible_in_tree():
			continue
		var bx: AABB = m.global_transform * m.get_aabb()
		if not bx.intersects(zone) or bx.size.length() > 4000.0 or _ch_faits.has(m.get_instance_id()):
			continue
		var p: Node = m
		var exclu: bool = false
		while p != null:
			if p in sauf or p.is_in_group("cibles_v28") or p.is_in_group("faune_v132"):
				exclu = true
				break
			p = p.get_parent()
		if exclu:
			continue
		var faces: PackedVector3Array = m.mesh.get_faces()
		if faces.is_empty() or faces.size() > 900000:
			continue
		var sb := StaticBody3D.new()
		sb.collision_layer = CH_COUCHE
		sb.collision_mask = 0
		var cs := CollisionShape3D.new()
		var sh := ConcavePolygonShape3D.new()
		sh.backface_collision = true
		sh.set_faces(m.global_transform * faces)
		cs.shape = sh
		sb.add_child(cs)
		sb.set_meta("ch_mi", m)
		add_child(sb)
		_ch_faits[m.get_instance_id()] = sb
