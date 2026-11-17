## La beauté de la Grande Île (V164) : la Porte aux Quatre Sceaux sculptée (les vantaux gravés, la frise
## du linteau, la pierre de taille vieillie, les deux braseros aux flammes bleues ; elle s'enfonce
## toujours d'un bloc) ; Carène (le vieux pont de chêne, les métaux vieillis, le feu de camp refait,
## l'ancre de fer, le poêle de fonte et le fauteuil club) ; Tazira (le pisé, la chaux vieillie) ;
## Cliquetis (le monorail en poutre rivetée sur ses colonnes de fonte, les métaux) ; Ramure (le
## sous-bois : la litière, la mousse ; le feu du Cercle de la Lune, les bancs de rondins).
const NOM := "beaute_grande"


func _tex(m: Material, fin: String) -> bool:
	var s: StandardMaterial3D = m as StandardMaterial3D
	return s != null and s.albedo_texture != null and s.albedo_texture.resource_path.ends_with(fin)


func _shader(m: Material, nom: String) -> bool:
	var s: ShaderMaterial = m as ShaderMaterial
	return s != null and s.shader != null and s.shader.resource_path.ends_with(nom)


func _serie() -> void:
	var G: Node = grande_v59
	_ok(G != null and G.ile != null, "la Grande Île est là")
	if G == null or G.ile == null:
		return
	# --- la Porte aux Quatre Sceaux
	var I: Node = G.ile
	var faces: int = 0
	for leaf in I.door_leaves:
		var f: MeshInstance3D = (leaf as Node).get_node_or_null("Face_sculptee")
		if f != null and _tex(f.material_override, "beau164/porte_sceaux.png") and (f.material_override as StandardMaterial3D).normal_texture != null:
			faces += 1
	_ok(faces == 2, "les deux vantaux sculptés (le cercle, les runes, les quatre symboles)")
	var fr: MeshInstance3D = I.door_gate.get_node_or_null("Frise_sceaux") if I.door_gate != null else null
	_ok(fr != null and _tex(fr.material_override, "beau164/frise_sceaux.png"), "la frise du linteau")
	var pierre: int = 0
	for c in I.door_gate.get_children():
		if c is MeshInstance3D and _shader((c as MeshInstance3D).material_override, "pierre_chateau_v161.gdshader"):
			pierre += 1
	_ok(pierre >= 6, "la pierre de taille vieillie des piliers et du linteau (%d)" % pierre)
	_ok(I.door_braseros.size() == 2 and (I.door_braseros[0] as Node).find_children("Flamme_bleue_*", "MeshInstance3D", false, false).size() == 3, "les deux braseros aux flammes bleues")
	_ok(I.door_glow is StandardMaterial3D and I.door_mobile != null and I.door_leaves.size() == 2, "la porte s'enfonce toujours d'un bloc (le cercle, les vantaux)")
	# --- Carène
	var C: Node = G.carene
	_ok(C != null, "Carène est là")
	if C != null:
		_ok(_tex(C.E.mat("pont"), "beau164/pont_leviathan.png") and (C.E.mat("pont") as StandardMaterial3D).roughness_texture != null, "le vieux pont de chêne du Léviathan")
		_ok(C.kit.hd_v164 and _tex(C.kit.mat("pont"), "beau164/pont_leviathan.png"), "les pontons du même chêne")
		var can: StandardMaterial3D = C.kit.mat("canon") as StandardMaterial3D
		_ok(can != null and can.roughness_texture != null, "les canons et le fer vieillis")
		var feu: MeshInstance3D = C.get_node_or_null("Feu_de_camp")
		_ok(feu != null and _shader(feu.material_override, "flamme_v163.gdshader") and C.get_node_or_null("Cendres_feu_v164") != null, "le feu de camp (les braises, la flamme qui danse)")
		_ok(C.find_children("Rondin_v164_*", "MeshInstance3D", false, false).size() == 3, "les trois bancs de rondins")
		_ok(C.get_node_or_null("Ancre_v164_fer") != null and C.get_node_or_null("Ancre_v164_bois") != null, "l'ancre de fer et son jas de bois")
		_ok(C.get_node_or_null("Poele_v164_canon") != null and C.get_node_or_null("Fauteuil_v164_tissu_bordeaux") != null, "le poêle de fonte et le fauteuil club")
		# la nuit, le feu s'allume
		var t: Node = temps_v56
		var avant: bool = t.lamps_on
		t.lamps_on = true
		C._process(0.016)
		var g1: float = float(C.fire_flamme_v164.get_shader_parameter("glow"))
		t.lamps_on = false
		C._process(0.016)
		var g0: float = float(C.fire_flamme_v164.get_shader_parameter("glow"))
		t.lamps_on = avant
		_ok(g1 > 0.5 and g0 < 0.01, "la flamme du feu de camp s'allume la nuit")
	# --- Tazira
	var T: Node = G.tazira
	_ok(T != null, "Tazira est là")
	if T != null:
		_ok(T.kit.hd_v164 and _tex(T.kit.mat("pise"), "beau164/pise_tazira.png"), "le pisé (les banchées, les cailloux, les trous de boulin)")
		var ch: Material = T.kit.mat("chaux_blanc")
		_ok(_shader(ch, "enduit_v163.gdshader") and str((ch as ShaderMaterial).get_shader_parameter("tex_pierre").resource_path).ends_with("beau164/pise_tazira.png"), "la chaux vieillie qui laisse voir le pisé")
	# --- Cliquetis
	var Q: Node = G.cliquetis
	_ok(Q != null, "Cliquetis est là")
	if Q != null:
		var cols: int = Q.find_children("Colonne_fonte_v164_*", "MeshInstance3D", false, false).size()
		_ok(cols >= 20, "le monorail sur ses colonnes de fonte cannelées (%d)" % cols)
		var fn: StandardMaterial3D = Q.kit.mat("fer_noir") as StandardMaterial3D
		_ok(Q.kit.hd_v164 and fn != null and fn.roughness_texture != null, "la fonte noire vieillie")
	# --- Ramure
	var R: Node = G.ramure
	_ok(R != null, "Ramure est là")
	if R != null:
		_ok(R.find_children("*Pierre_feu_v164*", "MeshInstance3D", true, false).size() >= 13, "le feu du Cercle de la Lune : les pierres rondes")
		_ok(R.find_children("*Buche_v164*", "MeshInstance3D", true, false).size() >= 7, "les bûches en tipi")
		_ok(_tex(R.kit.mat("mousse"), "beau164/mousse_foret.png") and _tex(R.kit.mat("cerne"), "beau164/cerne.png"), "la mousse, les bouts des rondins")
		var sol: ShaderMaterial = null
		for c2 in I.get_children():
			if c2 is MeshInstance3D and (c2 as MeshInstance3D).material_override is ShaderMaterial and _shader((c2 as MeshInstance3D).material_override, "grande_ile_v59.gdshader"):
				sol = (c2 as MeshInstance3D).material_override
				break
		_ok(sol != null and bool(sol.get_shader_parameter("sous_bois")), "le sous-bois de la forêt des brumes (la litière, la mousse)")
