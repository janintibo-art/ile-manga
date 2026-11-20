## Le grand contrôle des bugs visuels, V183 : les vrais corps des habitants de l'île de Hautefond (la ville,
## la Cité des Nuées, les Strates, la Fronde, le Dôme d'Azur). Ses 58 habitants gardaient le corps du héros
## (en dessin animé) : leurs corps ont été fabriqués sur le PC de l'auteur (tests/outils/corps_pc.py, avec
## MakeHuman et MPFB2, licence CC0). Chaque fiche a son corps (pnj64/<id>.bin), l'habitant du jeu le prend,
## une femme a un corps de femme. Et des retouches vues sur les photos du PC : le bureau de l'intendante du
## château de Montjoie n'est plus pris dans une colonne, le potier d'Aztlán n'est plus dans le mur, le
## titane du Dôme n'est plus un métal presque pur (sous la mer, il rendait noir).
const NOM := "corps183"
const FICHES58 := ["hautefond_habitants_v112", "nuees_habitants_v113", "strates_habitants_v114", "fronde_habitants_v114", "dome_habitants_v115"]
const CORPS58 = preload("res://scripts/pnj/corps_v64.gd")
const BANCS58 = preload("res://scripts/pnj/bancs_v183.gd")


## L'habitant arrive à son lieu (sur un banc), comme s'il y venait, et l'on fige sa pose assise (son emploi
## du temps, à cette heure-ci, l'enverrait peut-être ailleurs) ; on regarde son bassin : entre 4 et 17 cm
## au-dessus de l'assise, et là où on l'attend (au milieu de l'assise). Rend "" si tout va bien.
func _banc58(npc: Node3D, lieu: String, bc: Dictionary) -> String:
	npc.set("slot", npc.call("_slot_now"))
	npc.call("_set_hidden", false)
	npc.set("state", "repos")
	npc.set("target_spot", lieu)
	npc.call("_arrive")
	var av: Vector3 = bc["avant"]
	place_player_v35(npc.global_position + av * 4.0 + Vector3.UP * 0.3, -av)
	# (loin du joueur, il dort : son corps caché, ses animations arrêtées ; on le laisse se réveiller)
	await _att(1.0)
	npc.set_process(false)
	npc.set_physics_process(false)
	var ap: AnimationPlayer = npc.get("anim")
	var clip: String = "v56/lire" if str(npc.get("pose")) == "lire" else "v28/sit"
	if ap != null and ap.has_animation(clip):
		ap.play(clip, 0.0)
		ap.seek(1.0, true)
		ap.pause()
	await _att(0.3)
	var r: String = _bassin58(npc, str(npc.get("display_name")) + ", " + lieu, bc)
	if ap != null:
		ap.play()
	npc.set_process(true)
	npc.set_physics_process(true)
	return r


func _bassin58(npc: Node3D, qui: String, bc: Dictionary) -> String:
	var sk: Skeleton3D = npc.get("skel")
	if sk == null or sk.find_bone("Hips") < 0:
		return qui + " : pas de squelette"
	var hb: Vector3 = sk.global_transform * sk.get_bone_global_pose(sk.find_bone("Hips")).origin
	var s: float = (npc.get("model") as Node3D).global_transform.basis.get_scale().y if npc.get("model") is Node3D else 1.0
	var dh: float = hb.y - float(bc["y"])
	var dxz: float = Vector2(hb.x - bc["pos"].x, hb.z - bc["pos"].z).length()
	if dh > 0.04 * s and dh < 0.17 * s and dxz < 0.2:
		return ""
	return "%s : le bassin %.2f m au-dessus de l'assise, à %.2f m du milieu" % [qui, dh, dxz]


## Ce qui touche une boîte (dimensions t, centre au, axes de b) : le décor solide (ni le joueur, ni les gens).
func _touche58(au: Vector3, b: Basis, t: Vector3) -> Array:
	var q := PhysicsShapeQueryParameters3D.new()
	var bx := BoxShape3D.new()
	bx.size = t
	q.shape = bx
	q.transform = Transform3D(b, au)
	var out: Array = []
	for h in get_world_3d().direct_space_state.intersect_shape(q, 16):
		var c: Object = h.get("collider")
		# (le corps d'un habitant, « Corps_collision », ne compte pas : le potier lui-même est peut-être là)
		if c is Node and not (c is CharacterBody3D) and str((c as Node).name) != "Corps_collision":
			out.append(str((c as Node).name))
	return out


func _pnj58(id: String) -> Node3D:
	for e in testeur_v78._npcs():
		var pr: Variant = (e[1] as Node).get("profile")
		if pr is Dictionary and str((pr as Dictionary).get("id", "")) == id:
			return e[1]
	return null


func _serie() -> void:
	# 1. chaque fiche de Hautefond a son corps ; une femme, un corps de femme
	var fiches := {}
	for k in FICHES58:
		for d in load("res://scripts/pnj/%s.gd" % k).all_profiles():
			fiches[str(d["id"])] = bool((d as Dictionary).get("femme", false))
	var sans: Array = []
	var genre: Array = []
	var femmes: int = 0
	for id in fiches:
		if not CORPS58.has_body(id):
			sans.append(id)
			continue
		var lk: Dictionary = CORPS58.read_bin(CORPS58.DIR + id + ".bin").get("look", {})
		if bool(lk.get("femme", false)):
			femmes += 1
		if fiches[id] and not bool(lk.get("femme", false)):
			genre.append(id)
	_ok(fiches.size() == 58 and sans.is_empty(), "les %d habitants de Hautefond ont leur corps (sans corps : %s)" % [fiches.size(), str(sans)])
	_ok(genre.is_empty() and femmes >= 25, "les femmes de Hautefond ont un corps de femme (%d femmes ; un corps d'homme : %s)" % [femmes, str(genre)])
	# 2. dans le jeu, l'habitant prend son corps (v64), plus celui du héros
	var vus: int = 0
	var anciens: Array = []
	for e in testeur_v78._npcs():
		var pr2: Variant = (e[1] as Node).get("profile")
		if not (pr2 is Dictionary) or not fiches.has(str((pr2 as Dictionary).get("id", ""))):
			continue
		vus += 1
		var v64: Variant = (e[1] as Node).get("v64")
		if not (v64 is Dictionary) or (v64 as Dictionary).is_empty():
			anciens.append(str(e[0]))
	_ok(vus == fiches.size() and anciens.is_empty(), "dans le jeu, %d habitants de Hautefond sur %d ont leur vrai corps (encore l'ancien : %s)" % [vus - anciens.size(), fiches.size(), str(anciens)])
	# 3. le titane du Dôme : moins métallique (0,92 rendait noir sous la mer, sans ciel à refléter)
	var ti: Material = load("res://scripts/dome_mats_v115.gd").make("titane115")
	_ok(ti is BaseMaterial3D and (ti as BaseMaterial3D).metallic <= 0.6, "le titane du Dôme : métallique %.2f (avant 0,92)" % ((ti as BaseMaterial3D).metallic if ti is BaseMaterial3D else -1.0))
	# le titane sombre (les socles des bancs, les disques des places) : à 0,55, il restait noir
	var ts: Material = load("res://scripts/dome_mats_v115.gd").make("titane115_sombre")
	var ts_m: float = (ts as BaseMaterial3D).metallic if ts is BaseMaterial3D else -1.0
	var ts_v: float = (ts as BaseMaterial3D).albedo_color.v if ts is BaseMaterial3D else -1.0
	_ok(ts_m >= 0.0 and ts_m <= 0.35 and ts_v >= 0.5, "le titane sombre du Dôme : métallique %.2f, clarté %.2f (avant 0,92 et 0,35)" % [ts_m, ts_v])
	# 4. Montjoie : le bureau de l'intendante, devant la rangée de colonnes (il était pris dans la première)
	var aurore: Node3D = _pnj58("aurore")
	if _ok(aurore != null and aurore.get("azur") != null, "Aurore, l'intendante du château de Montjoie"):
		var sp: Dictionary = (aurore.get("azur") as Object).call("spot", "chateau_salon")
		if _ok(not sp.is_empty(), "le lieu du bureau (chateau_salon)"):
			var fa: Vector3 = Vector3(sp["face"]).normalized()
			var bx := Basis(Vector3.UP.cross(fa).normalized(), Vector3.UP, fa)
			var bureau: Vector3 = Vector3(sp["pos"]) + fa * 0.98 - Vector3.UP * 0.05
			place_player_v35(bureau + fa * 4.0 + Vector3.UP * 0.3, -fa)
			await _att(4.0)
			# au-dessus du plateau (de 0,9 à 1,9 m) : rien ; là où il était (1,9 m plus à droite) : la colonne
			var ici: Array = _touche58(bureau + Vector3.UP * 1.4, bx, Vector3(1.7, 1.0, 0.8))
			var avant: Array = _touche58(bureau + bx.x * 1.9 + Vector3.UP * 1.4, bx, Vector3(1.7, 1.0, 0.8))
			_ok(ici.is_empty() and not avant.is_empty(), "le bureau du château : rien au-dessus du plateau (%s) ; à l'ancienne place, la colonne (%s)" % [str(ici), str(avant)])
	# 5. Aztlán : le potier Coyotl, à genoux, plus dans le mur
	var coy: Node3D = _pnj58("coyotl")
	if _ok(coy != null and coy.get("azur") != null, "Coyotl, le potier d'Aztlán"):
		var sp2: Dictionary = (coy.get("azur") as Object).call("spot", "potier_az")
		if _ok(not sp2.is_empty(), "le lieu du potier (potier_az)"):
			var p2: Vector3 = sp2["pos"]
			var f2: Vector3 = Vector3(sp2["face"]).normalized()
			place_player_v35(p2 + f2 * 4.0 + Vector3.UP * 0.3, -f2)
			await _att(4.0)
			var mur: Array = _touche58(p2 + Vector3.UP * 0.65, Basis(Vector3.UP.cross(f2).normalized(), Vector3.UP, f2), Vector3(0.5, 0.6, 0.5))
			_ok(mur.is_empty(), "le potier à genoux : rien autour de lui (%s)" % str(mur))
	# 6. les bancs de Hautefond (bancs_v183) : les habitants s'assoient dessus (avant : un tabouret devant
	# le banc, ou dans l'assise ; Doyenne Agathe Basalte, sur la Place des Strates, assise devant le banc)
	_ok(BANCS58.nombre() >= 40, "les bancs de Hautefond qui s'inscrivent : %d" % BANCS58.nombre())
	var faits := {}
	var mal: Array = []
	for e in testeur_v78._npcs():
		var npc: Node3D = e[1]
		var pr3: Variant = npc.get("profile")
		if not (pr3 is Dictionary) or not fiches.has(str((pr3 as Dictionary).get("id", ""))) or not (npc.get("agenda") is Array):
			continue
		var az: Object = npc.get("azur")
		for a in npc.get("agenda"):
			if not (a is Array) or (a as Array).size() < 3:
				continue
			for lieu in (a[2] if a[2] is Array else [a[2]]):
				var sp3: Dictionary = az.call("spot", str(lieu)) if az != null else {}
				if faits.has(str(lieu)) or sp3.is_empty() or not (str(sp3.get("pose", "")) in ["assis", "lire"]):
					continue
				var bc: Dictionary = BANCS58.sous(sp3["pos"])
				if bc.is_empty():
					continue
				faits[str(lieu)] = true
				var r: String = await _banc58(npc, str(lieu), bc)
				if r != "":
					mal.append(r)
	_ok(faits.size() >= 8 and mal.is_empty(), "les habitants de Hautefond sur les bancs : %d lieux, le bassin posé sur l'assise (sinon : %s)" % [faits.size(), str(mal)])
	# 7. les passants assis sur les bancs du Dôme d'Azur (avant : 45 cm trop haut, sur le dossier)
	var hf: Object = null
	for e2 in testeur_v78._npcs():
		var pr4: Variant = (e2[1] as Node).get("profile")
		if pr4 is Dictionary and fiches.has(str((pr4 as Dictionary).get("id", ""))):
			hf = (e2[1] as Node).get("azur")
			break
	if _ok(hf != null and hf.get("crowd") is Array, "les passants de Hautefond"):
		var sp5: Dictionary = hf.call("spot", "da_place_banc_1")
		if _ok(not sp5.is_empty(), "la Place du Dôme (da_place_banc_1)"):
			place_player_v35(Vector3(sp5["pos"]) + Vector3(0, 0.3, 0) + BANCS58.sous(sp5["pos"]).get("avant", Vector3.FORWARD) * 3.0, Vector3.FORWARD)
			await _att(5.0)
			var vus2: int = 0
			var mal2: Array = []
			for c in hf.get("crowd"):
				var ctl: Node = c[0]
				if not is_instance_valid(ctl) or not (ctl.get("npc") is Node3D):
					continue
				var fn: Node3D = ctl.get("npc")
				var bc2: Dictionary = BANCS58.sous(fn.global_position)
				if bc2.is_empty() or not fn.is_visible_in_tree():
					continue
				vus2 += 1
				var r2: String = _bassin58(fn, "le passant " + str(fn.get("display_name")), bc2)
				if r2 != "":
					mal2.append(r2)
			_ok(vus2 >= 1 and mal2.is_empty(), "les passants assis sur les bancs : %d, le bassin posé sur l'assise (sinon : %s)" % [vus2, str(mal2)])
