## V207 : le grand contrôle de la fluidité (lancé par tests/outils/audit_fluidite.py, collé à la fin de
## main.gd comme une série). À chaque endroit demandé, on pose le joueur, on laisse le monde se charger,
## puis on compte tout ce que la carte graphique aurait à dessiner autour de lui : chaque objet visible
## (ni caché, ni au-delà de sa distance d'affichage, ni au-delà de la vue de la caméra), ses triangles
## (version entière, sans allègement de loin) et ses « appels » (une surface = un appel). On range par
## famille (le fichier du modèle, ou le morceau du jeu qui l'a fabriqué) et on donne les plus lourdes.
## Ce n'est pas une mesure de temps : c'est la liste de qui pèse, pour savoir où alléger.
## Lignes : FLU_LIEU (le total d'un endroit), FLU_TRI et FLU_APP (les familles, par triangles, par appels).
const NOM := "audit_fluidite"
var _fl7_args: Dictionary = {}
var _fl7_poids: Dictionary = {}
var _fl7_vus: Dictionary = {}


func _fl7_tri(m: Mesh) -> int:
	if m == null:
		return 0
	if _fl7_poids.has(m):
		return _fl7_poids[m]
	var t := 0
	for s in m.get_surface_count():
		var arr: Array = m.surface_get_arrays(s) if not (m is ArrayMesh) else []
		if m is ArrayMesh:
			var il: int = (m as ArrayMesh).surface_get_array_index_len(s)
			t += (il if il > 0 else (m as ArrayMesh).surface_get_array_len(s)) / 3
		elif arr.size() > Mesh.ARRAY_INDEX and arr[Mesh.ARRAY_INDEX] != null:
			t += (arr[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3
		elif arr.size() > 0 and arr[Mesh.ARRAY_VERTEX] != null:
			t += (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
	_fl7_poids[m] = t
	return t


## La famille d'un objet : le fichier de son modèle, sinon le morceau du jeu qui le porte.
func _fl7_famille(g: Node, m: Mesh) -> String:
	if m != null and m.resource_path != "":
		return m.resource_path.get_slice("::", 0).get_file()
	var n: Node = g
	var noms: Array = []
	while n != null and n != self:
		noms.push_front(str(n.name))
		n = n.get_parent()
	var cle: String = "/".join(noms.slice(0, 2))
	var net := ""
	for c in cle:
		if not (c >= "0" and c <= "9") and c != "@":
			net += c
	return net


## Avec un écran (sur le PC) : ce que la carte graphique dessine vraiment, en regardant dans quatre directions
## (les appels, les triangles, les objets de l'image, et le temps de la carte graphique pour l'image).
func _fl7_vues(nom: String, ou: Vector3) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var vp: RID = get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(vp, true)
	var caps: Array = [["nord", Vector3(0, 0, -1)], ["est", Vector3(1, 0, 0)], ["sud", Vector3(0, 0, 1)], ["ouest", Vector3(-1, 0, 0)]]
	for c in caps:
		place_player_v35(ou, c[1])
		await _att(1.2)
		var gpu := 0.0
		var cpu := 0.0
		for i in 20:
			await get_tree().process_frame
			gpu += RenderingServer.viewport_get_measured_render_time_gpu(vp)
			cpu += RenderingServer.viewport_get_measured_render_time_cpu(vp)
		print("FLU_VUE\t%s\t%s\t%d\t%d\t%d\t%.2f\t%.2f\t%d" % [nom, c[0],
			int(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)),
			int(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)),
			int(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME)),
			gpu / 20.0, cpu / 20.0, int(Engine.get_frames_per_second())])
		# V211 "paliers" : la même vue sans le détail allégé de loin (tout à plein détail), pour comparer ;
		# et, aux endroits demandés, les deux photos (avec / sans) à mettre côte à côte
		if not bool(_fl7_args.get("paliers", false)):
			continue
		var veut_photo: bool = (_fl7_args.get("photos", []) as Array).has(nom)
		if veut_photo:
			_fl7_photo("%s_%s_avec" % [nom, c[0]])
		var seuil7: float = get_viewport().mesh_lod_threshold
		get_viewport().mesh_lod_threshold = 0.0
		await _att(0.6)
		var gpu2 := 0.0
		for i2 in 20:
			await get_tree().process_frame
			gpu2 += RenderingServer.viewport_get_measured_render_time_gpu(vp)
		print("FLU_VUE_SANS\t%s\t%s\t%d\t%d\t%d\t%.2f" % [nom, c[0],
			int(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)),
			int(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)),
			int(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME)), gpu2 / 20.0])
		if veut_photo:
			_fl7_photo("%s_%s_sans" % [nom, c[0]])
		get_viewport().mesh_lod_threshold = seuil7


func _fl7_photo(nom: String) -> void:
	var dossier: String = ProjectSettings.globalize_path("res://").path_join("../photos/paliers")
	DirAccess.make_dir_recursive_absolute(dossier)
	var img: Image = get_viewport().get_texture().get_image()
	if img != null:
		img.save_png(dossier.path_join(nom + ".png"))


func _fl7_lieu(nom: String, ou: Vector3, poser: bool = true) -> void:
	if poser:
		place_player_v35(ou, Vector3.FORWARD)
	await _att(float(_fl7_args.get("attente", 7.0)))
	if not poser:
		ou = _player_pos_v27()
	await _fl7_vues(nom, ou)
	var cam: Camera3D = get_viewport().get_camera_3d()
	var oeil: Vector3 = cam.global_position if cam != null else ou
	var loin: float = cam.far if cam != null else 4000.0
	var fam: Dictionary = {}          # famille -> [triangles, appels, objets, plus proche, ombre, triangles avec ombre]
	var tot_t := 0
	var tot_a := 0
	var tot_o := 0
	var tot_omb := 0
	# ce qui resterait si un objet disparaissait dès qu'il est plus loin que K fois sa taille (K = 150, 250, 400)
	var regles: Array = [150.0, 250.0, 400.0]
	var reste_t: Array = [0, 0, 0]
	var reste_a: Array = [0, 0, 0]
	var loin_a: Array = [0, 0, 0, 0, 0]  # appels à moins de 100 m, 100-300, 300-800, au-delà, nappes à la place inconnue
	var inc_t := 0
	for g in find_children("*", "GeometryInstance3D", true, false):
		var gi: GeometryInstance3D = g
		if not gi.is_visible_in_tree():
			continue
		var m: Mesh = null
		var fois := 1
		if gi is MeshInstance3D:
			m = (gi as MeshInstance3D).mesh
		elif gi is MultiMeshInstance3D:
			var mm: MultiMesh = (gi as MultiMeshInstance3D).multimesh
			if mm == null:
				continue
			m = mm.mesh
			fois = mm.visible_instance_count if mm.visible_instance_count >= 0 else mm.instance_count
		if m == null or fois <= 0:
			continue
		var boite: AABB = gi.global_transform * gi.get_aabb()
		# Sans écran, Godot ne sait pas où sont les objets d'une nappe (MultiMesh) : si son nœud est au point
		# zéro du monde, sa place est inconnue. On la compte à part (« nappes à la place inconnue »).
		var inconnue: bool = gi is MultiMeshInstance3D and gi.global_position.length() < 0.5 and boite.size.length() < 0.01
		var d: float = maxf(0.0, (boite.get_center() - oeil).length() - boite.size.length() * 0.5)
		if d > loin and not inconnue:
			continue
		if inconnue:
			pass
		elif gi.visibility_range_end > 0.0 and (boite.get_center() - oeil).length() > gi.visibility_range_end + gi.visibility_range_end_margin:
			continue
		elif gi.visibility_range_begin > 0.0 and (boite.get_center() - oeil).length() < gi.visibility_range_begin - gi.visibility_range_begin_margin:
			continue
		var t: int = _fl7_tri(m) * fois
		var a: int = m.get_surface_count()
		var ombre: bool = gi.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var cle: String = _fl7_famille(gi, m)
		if not fam.has(cle):
			fam[cle] = [0, 0, 0, 1e9, 0, 0, 0, 0, 0, 0, 0]
		var f: Array = fam[cle]
		f[0] += t
		f[1] += a
		f[2] += 1
		f[3] = minf(f[3], d)
		if ombre:
			f[4] += 1
			f[5] += t
			tot_omb += t
		tot_t += t
		tot_a += a
		tot_o += 1
		var dc: float = (boite.get_center() - oeil).length()
		var taille: float = boite.size.length()
		for k in regles.size():
			if inconnue or dc <= float(regles[k]) * taille:
				reste_t[k] += t
				reste_a[k] += a
		var bande: int = 4 if inconnue else (0 if dc < 100.0 else (1 if dc < 300.0 else (2 if dc < 800.0 else 3)))
		if inconnue:
			inc_t += t
		# "detail" : des exemples d'une famille, à moins de 100 m (qui est là, où, quelle taille)
		for motif in _fl7_args.get("detail", []):
			if bande == 0 and cle.contains(str(motif)) and int(_fl7_vus.get(nom + cle, 0)) < 12:
				_fl7_vus[nom + cle] = int(_fl7_vus.get(nom + cle, 0)) + 1
				print("FLU_DETAIL\t%s\t%s\t%s\tpos %s\tboîte %s taille %s\t%d tri\t%s" % [nom, cle, str(gi.get_path()).right(110), str(gi.global_position.snapped(Vector3.ONE)), str(boite.position.snapped(Vector3.ONE)), str(boite.size.snapped(Vector3.ONE * 0.1)), t, gi.get_class()])
		loin_a[bande] += a
		f[6 + bande] += a
	print("FLU_LIEU\t%s\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d" % [nom, int(ou.x), int(ou.y), int(ou.z), tot_t, tot_a, tot_o, tot_omb, fam.size()])
	print("FLU_REGLE\t%s\t%s\t%s\t%s\t%d" % [nom, str(reste_t), str(reste_a), str(loin_a), inc_t])
	var cles: Array = fam.keys()
	cles.sort_custom(func(x, y): return fam[x][0] > fam[y][0])
	for c in cles.slice(0, int(_fl7_args.get("top", 14))):
		print("FLU_TRI\t%s\t%s\t%d\t%d\t%d\t%.0f\t%d" % [nom, c, fam[c][0], fam[c][1], fam[c][2], fam[c][3], fam[c][4]])
	cles.sort_custom(func(x, y): return fam[x][1] > fam[y][1])
	for c in cles.slice(0, int(_fl7_args.get("top", 14))):
		print("FLU_APP\t%s\t%s\t%d\t%d\t%d\t%.0f\t%d\t%d\t%d\t%d\t%d\t%d" % [nom, c, fam[c][0], fam[c][1], fam[c][2], fam[c][3], fam[c][4], fam[c][6], fam[c][7], fam[c][8], fam[c][9], fam[c][10]])


func _serie() -> void:
	var fa := FileAccess.open("res://audit_args.json", FileAccess.READ)
	if fa != null:
		_fl7_args = JSON.parse_string(fa.get_as_text())
	if temps_v56 != null:
		temps_v56.hour = float(_fl7_args.get("heure", 14.0))
	# V211 : on attend que le détail allégé de loin soit prêt partout
	var garde7: int = 0
	while get("allege_v211") != null and allege_v211 != null and not allege_v211.fini and garde7 < 900:
		await _att(0.5)
		garde7 += 1
	if get("allege_v211") != null and allege_v211 != null:
		print("FLU_PALIERS\t%d\t%d\t%d\t%d\t%.0f" % [allege_v211.faits, allege_v211.gagnes, allege_v211.tri_avant, allege_v211.tri_loin, allege_v211.ms_total])
	var lieux: Array = []
	for l in _fl7_args.get("lieux", []):
		lieux.append([str(l[0]), Vector3(float(l[1]), float(l[2]), float(l[3]))])
	if bool(_fl7_args.get("iles", true)) and teleport_v58 != null:
		for pl in teleport_v58.PLACES:
			var sp: Array = teleport_v58.spot(str(pl[0]))
			if sp.size() >= 1 and sp[0] is Vector3:
				lieux.append([str(pl[0]), sp[0]])
	for l in lieux:
		await _fl7_lieu(l[0], l[1])
	# "dedans" : dans le hall de la plus grande tour de bureaux de Néopolis (ce que le dehors coûte quand on est dedans)
	if bool(_fl7_args.get("dedans", false)) and neo_v94 != null and neo_v94.get("tours") != null:
		var tt: Node = neo_v94.tours
		var id7: int = -1
		for t in tt.tours:
			if str(t["type"]) == "bureaux" and (id7 < 0 or (t["etages"] as Array).size() > (tt.tours[id7]["etages"] as Array).size()):
				id7 = int(t["id"])
		if id7 >= 0:
			var t7: Dictionary = tt.tours[id7]
			await _fl7_lieu("neo_devant_la_tour", (t7["sortie"] as Vector3) + Vector3.UP * 0.3)
			tt.test_mode = true
			tt.enter(id7)
			await _att(3.0)
			await _fl7_lieu("neo_hall_de_la_tour", Vector3.ZERO, false)
			tt.sortir_vite()
			await _att(1.0)
	print("FLU_FIN %d lieux" % lieux.size())
