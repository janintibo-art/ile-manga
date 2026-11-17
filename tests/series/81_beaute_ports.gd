## La beauté de Port-Azur, de la teuf et du royaume des fées (V163) : Port-Azur (l'enduit vieilli des
## façades, les fenêtres en profondeur, les dalles de calcaire blond, la pierre fine ; les autres villes du
## kit gardent leurs matières) ; la teuf de la plage (le portique et ses lyres qui suivent les
## projecteurs, les faisceaux la nuit, les guirlandes guinguette, les fanions, les flambeaux, la banderole,
## les flight-cases, les canapés de palettes ; rien ne gêne les danseurs) ; le royaume des fées (la
## prairie et le trèfle, l'herbe plus drue, les fleurs en touffes, les ruisseaux clairs, les racines
## d'Yggdrasil tournées vers dehors, les cristaux).
const NOM := "beaute_ports"
const Kit := preload("res://scripts/azur_kit_v56.gd")


func _chemin(m: Material, fin: String) -> bool:
	var s: StandardMaterial3D = m as StandardMaterial3D
	return s != null and s.albedo_texture != null and s.albedo_texture.resource_path.ends_with(fin)


func _shader(m: Material, nom: String) -> bool:
	var s: ShaderMaterial = m as ShaderMaterial
	return s != null and s.shader != null and s.shader.resource_path.ends_with(nom)


func _serie() -> void:
	# --- Port-Azur
	var A: Node = azur_v56
	_ok(A != null and A.port != null, "Port-Azur est là")
	if A != null and A.port != null:
		var K = A.port.kit
		_ok(K.hd_v163, "Port-Azur en haute définition")
		var en: Material = K.mat("enduit_rose")
		_ok(_shader(en, "enduit_v163.gdshader") and (en as ShaderMaterial).get_shader_parameter("tex_pierre") != null, "l'enduit vieilli des façades (les coulures, l'humidité, les plaques tombées)")
		_ok(_shader(K.mat("fenetre"), "fenetre_v163.gdshader") and _shader(K.mat("fenetre_nuit"), "fenetre_v163.gdshader"), "les fenêtres en profondeur (la menuiserie, la pièce derrière, les rideaux)")
		_ok(_chemin(K.mat("dalles"), "beau163/dalles_azur.png") and (K.mat("dalles") as StandardMaterial3D).roughness_texture != null, "les dalles de calcaire blond du quai et de la place")
		_ok(_chemin(K.mat("pierre"), "beau163/pierre_fine.png"), "la pierre fine des encadrements")
		var fac: int = 0
		for mi in A.port.find_children("Ville_enduit_*", "MeshInstance3D", true, false):
			if _shader((mi as MeshInstance3D).material_override, "enduit_v163.gdshader"):
				fac += 1
		_ok(fac >= 5, "les façades de toutes les couleurs ont leur enduit vieilli (%d)" % fac)
		var autre = Kit.new()
		_ok(autre.mat("enduit_rose") is StandardMaterial3D and not _chemin(autre.mat("dalles"), "beau163/dalles_azur.png"), "les autres villes du kit gardent leurs matières")
	# --- la teuf de la plage
	var T: Node = teuf_v57
	_ok(T != null and T.decor_v163 != null, "le décor de la teuf est là")
	if T != null and T.decor_v163 != null:
		var D: Node = T.decor_v163
		_ok(D.lentilles.size() == 4 and D.faisceaux.size() == 4, "les quatre lyres sous le portique")
		_ok(D.nb_ampoules >= 60 and D.nb_fanions >= 80, "les guirlandes guinguette (%d ampoules) et les fanions (%d)" % [D.nb_ampoules, D.nb_fanions])
		_ok(D.nb_flambeaux == 6 and D.nb_mats == 5, "les flambeaux de bambou et les mâts de bois flotté")
		var ban: MeshInstance3D = D.get_node_or_null("Banderole_Mistral")
		_ok(ban != null and _chemin(ban.material_override, "beau163/banderole.png"), "la banderole « DJ MISTRAL » devant les platines")
		_ok(D.get_node_or_null("Teuf_flight") != null and D.get_node_or_null("Teuf_palette") != null and D.get_node_or_null("Teuf_coussin") != null, "les flight-cases, les canapés de palettes et leurs coussins")
		# les lentilles et les faisceaux suivent les projecteurs
		var l0: OmniLight3D = T.lights[0]
		var e0: float = l0.light_energy
		l0.light_energy = 3.0
		D.suivre(T.lights, true)
		var vu: bool = (D.faisceaux[0][1] as MeshInstance3D).visible
		var em: float = (D.lentilles[0] as StandardMaterial3D).emission_energy_multiplier
		D.suivre(T.lights, false)
		var cache: bool = not (D.faisceaux[0][1] as MeshInstance3D).visible
		l0.light_energy = e0
		_ok(vu and em > 4.0 and cache, "la lentille s'allume avec son projecteur, le faisceau seulement la nuit")
		# rien ne gêne les danseurs ; les mâts et les palettes sont sur le sable, pas dans l'eau
		var gene: int = 0
		for p in T.dancers:
			var pp: Vector3 = (p as Node3D).global_position
			for cs in D.get_node("Decor_teuf_collisions").get_children():
				var c3: Vector3 = (cs as CollisionShape3D).global_position
				if Vector2(pp.x - c3.x, pp.z - c3.z).length() < 1.2:
					gene += 1
		_ok(gene == 0, "aucun mât, aucun flambeau sur la piste (%d)" % gene)
		var P: Vector2 = T.PISTE
		var bas: float = 99.0
		for o in [Vector2(-15.5, 3.0), Vector2(-15.0, -3.2), Vector2(-11.5, -4.5), Vector2(11.5, -4.5), Vector2(0.0, -13.5)]:
			bas = minf(bas, _height_at(P.x + o.x, P.y + o.y))
		_ok(bas > 0.05, "le décor est posé sur la plage (le plus bas : %.2f m)" % bas)
	# --- le royaume des fées
	var F: Node = feerie_v58
	_ok(F != null and F.ile != null, "le royaume des fées est là")
	if F != null and F.ile != null:
		var I: Node = F.ile
		var pr: MeshInstance3D = I.get_node_or_null("Fees_prairie")
		var pm: ShaderMaterial = pr.material_override as ShaderMaterial if pr != null else null
		var mt: Texture2D = pm.get_shader_parameter("moss_tex") if pm != null else null
		var st: Texture2D = pm.get_shader_parameter("soil_tex") if pm != null else null
		_ok(mt != null and mt.resource_path.ends_with("beau163/prairie_fees.png") and st != null and st.resource_path.ends_with("beau163/trefle_fees.png"), "la prairie en fleurs et le tapis de trèfle")
		var herbe: MultiMeshInstance3D = I.get_node_or_null("Herbe_fees")
		var n_h: int = herbe.multimesh.instance_count if herbe != null else 0
		_ok(n_h >= (5000 if I.pc else 1800), "l'herbe plus drue (%d touffes)" % n_h)
		var fl: MultiMeshInstance3D = I.get_node_or_null("Fleurs_fees_0")
		_ok(fl != null and fl.multimesh.instance_count >= (330 if I.pc else 130), "les fleurs en touffes (%d)" % (fl.multimesh.instance_count if fl != null else 0))
		var rui: int = 0
		for r in I.find_children("*Ruisseau_fees*", "MeshInstance3D", false, false):
			var rm: Material = (r as MeshInstance3D).material_override
			if _shader(rm, "ruisseau_v163.gdshader") and float((rm as ShaderMaterial).get_shader_parameter("longueur")) > 5.0:
				rui += 1
		_ok(rui >= 3, "les ruisseaux clairs sur leur lit de galets (%d)" % rui)
		var cri: int = 0
		for c in I.get_children():
			if c is MeshInstance3D and (c as MeshInstance3D).material_override is StandardMaterial3D and ((c as MeshInstance3D).material_override as StandardMaterial3D).rim_enabled:
				cri += 1
		_ok(cri >= 8, "les cristaux de verre coloré (%d)" % cri)
		# les racines d'Yggdrasil : leurs faces regardent dehors
		var Y: Node = F.ygg
		var ra: MeshInstance3D = Y.get_node_or_null("Racines_Yggdrasil") if Y != null else null
		var dehors: int = 0
		var total: int = 0
		if ra != null:
			var arr: Array = ra.mesh.surface_get_arrays(0)
			var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var ns: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
			var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
			for t in range(0, mini(idx.size(), 3000), 3):
				var a: Vector3 = vs[idx[t]]
				var b: Vector3 = vs[idx[t + 1]]
				var c2: Vector3 = vs[idx[t + 2]]
				var n: Vector3 = ns[idx[t]] + ns[idx[t + 1]] + ns[idx[t + 2]]
				total += 1
				if (b - a).cross(c2 - a).dot(n) < 0.0:
					dehors += 1
		_ok(total > 0 and dehors > total * 0.95, "les racines d'Yggdrasil regardent dehors (%d / %d)" % [dehors, total])
