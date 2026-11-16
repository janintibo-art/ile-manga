## La beauté des îles (V159) : le Bois-Doré (le village regroupé par matière, le toit d'écailles,
## le bois et la pierre en relief, les lampadaires) ; la Montagne de Feu (les sols volcaniques et
## leur relief, les orgues de basalte, les deux rois sculptés, la lave vivante, le bord du lac de
## lave) ; Forgefer (la pierre taillée, les dalles, le fer martelé, les bannières brodées, la sonde
## de reflets) ; l'Île aux Moaïs (l'eau du lac du cratère, ses roselières) ; on tient debout.
const NOM := "beaute_iles"


func _compte_meshes(n: Node) -> int:
	var c: int = 0
	for ch in n.get_children():
		if ch is MeshInstance3D:
			c += 1
	return c


func _serie() -> void:
	# --- le Bois-Doré
	var E: Node = elfes_v41
	_ok(E != null and E.ile != null, "le Bois-Doré est là")
	if E != null and E.ile != null:
		var lots: int = 0
		for ch in E.get_children():
			if ch is MeshInstance3D and str(ch.name).begins_with("Village_elfe_v159"):
				lots += 1
		var n: int = _compte_meshes(E)
		_ok(lots >= 5 and n < 400, "le village regroupé par matière : %d maillages regroupés, %d en tout" % [lots, n])
		var toit: StandardMaterial3D = E._mat("toit")
		var bois: StandardMaterial3D = E._mat("bois")
		_ok(toit.albedo_texture != null and toit.normal_texture != null, "le toit d'écailles en feuilles")
		_ok(bois.normal_texture != null and E._mat("pierre").normal_texture != null and E._mat("mur").normal_texture != null, "le bois, la pierre, les murs en relief")
		var G: Vector3 = E.ile.glade_world()
		place_player_v35(G + Vector3(5.5, 0.4, -1.5), Vector3.FORWARD)
		await _att(1.0)
		_ok(await _debout("au Bois-Doré", 0.8), "on tient debout sur la place du Bois-Doré")
	# --- la Montagne de Feu
	var Nn: Node = nains_v46
	_ok(Nn != null and Nn.ile != null, "la Montagne de Feu est là")
	if Nn != null and Nn.ile != null:
		var rois: int = 0
		var fa: Node = Nn.forge_root.get_node_or_null("Grande_porte")
		if fa != null:
			for ch2 in fa.get_children():
				if str(ch2.name).begins_with("Roi_de_pierre_v159"):
					rois += 1
		_ok(rois == 2, "les deux rois de pierre sculptés devant la Grande Porte (%d)" % rois)
		var og: MultiMeshInstance3D = Nn.get_node_or_null("Orgues_de_basalte_v159")
		_ok(og != null and og.multimesh.instance_count >= 40, "les orgues de basalte (%d colonnes)" % (og.multimesh.instance_count if og != null else 0))
		_ok(Nn.get_node_or_null("Bord_du_lac_de_lave_v159") != null and str(Nn._lava_mat.shader.code).contains("vor("), "la lave vivante et le bord du lac de lave")
		var sol: ShaderMaterial = null
		for ch3 in Nn.ile.get_children():
			if ch3 is MeshInstance3D and (ch3 as MeshInstance3D).material_override is ShaderMaterial:
				sol = (ch3 as MeshInstance3D).material_override
				break
		var rn: Texture2D = sol.get_shader_parameter("rock_n") if sol != null else null
		var sn: Texture2D = sol.get_shader_parameter("soil_n") if sol != null else null
		_ok(rn != null and rn.resource_path.ends_with("basalte_n.png") and sn != null and sn.resource_path.ends_with("cendre_n.png"), "les sols volcaniques ont leur propre relief")
		var p: Material = Nn._mat("pierre")
		var fer: Material = Nn._mat("fer")
		_ok((p as StandardMaterial3D).albedo_texture.resource_path.ends_with("pierre_naine.png") and (fer as StandardMaterial3D).albedo_texture.resource_path.ends_with("fer_martele.png"), "la pierre taillée et le fer martelé des nains")
		place_player_v35(Nn.gate_front + Vector3.UP * 0.3, Vector3.FORWARD)
		await _att(1.0)
		_ok(await _debout("devant la Grande Porte", 0.8), "on tient debout devant la Grande Porte")
		# Forgefer
		var F: Node = Nn.get("forgefer")
		_ok(F != null and F.s != null, "Forgefer est là")
		if F != null and F.s != null:
			_ok(F.s.get_node_or_null("Sonde_halle_v159") is ReflectionProbe, "la sonde de reflets de la Grande Halle")
			var draps: int = 0
			for ch4 in F.s.get_children():
				if ch4 is MeshInstance3D and (ch4 as MeshInstance3D).mesh is QuadMesh and (ch4 as MeshInstance3D).material_override == F._drap_mat:
					draps += 1
			_ok(draps >= 20, "les bannières brodées de Forgefer (%d)" % draps)
	# --- l'Île aux Moaïs : le lac du cratère
	var M: Node = moai_v87
	_ok(M != null and M.ile != null, "l'Île aux Moaïs est là")
	if M != null and M.ile != null:
		var lac: MeshInstance3D = M.ile.get_node_or_null("Lac_du_cratere")
		_ok(lac != null and lac.material_override is ShaderMaterial, "l'eau du lac du cratère")
		var to: MultiMeshInstance3D = M.ile.get_node_or_null("Totoras_v159")
		_ok(to != null and to.multimesh.instance_count >= 100 and M.ile.get_node_or_null("Totoras_tapis_v159") != null, "les roselières du lac (%d touffes)" % (to.multimesh.instance_count if to != null else 0))
