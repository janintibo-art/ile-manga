## La beauté de Pandémonia, de Montjoie et de Port-Boucan (V166) : les étals sculptés (les poteaux
## tournés, le comptoir de planches, la toile rayée tissée et ses festons) et leurs marchandises (les
## fioles qui luisent, les jattes d'épices, les pains ; les corbeilles de fruits) ; à Pandémonia, la
## fontaine de feu tournée, le Cœur-Brasier à godrons, les braseros ; à Montjoie, la fontaine du
## Fondateur, le puits et son treuil, le foyer et l'enclume de la forge ; à Port-Boucan, la brique peinte
## vieillie, la baignoire-fontaine en fonte, les potagers (salades, choux, tomates), le faisceau du phare
## levé.
const NOM := "beaute_cites"


func _shader(m: Material, nom: String) -> bool:
	var s: ShaderMaterial = m as ShaderMaterial
	return s != null and s.shader != null and s.shader.resource_path.ends_with(nom)


func _tex(m: Material, fin: String) -> bool:
	var s: StandardMaterial3D = m as StandardMaterial3D
	return s != null and s.albedo_texture != null and s.albedo_texture.resource_path.ends_with(fin)


func _sculpt(n: Node, cle: String) -> int:
	if n == null:
		return 0
	return n.find_children("Sculpt_v166_%s_*" % cle, "MeshInstance3D", true, false).size()


func _bons(n: Node) -> int:
	var mauvais: int = 0
	for mi in n.find_children("Sculpt_v166_*", "MeshInstance3D", true, false):
		var m: MeshInstance3D = mi
		if m.mesh == null or m.mesh.get_surface_count() == 0 or m.material_override == null:
			mauvais += 1
	return mauvais


func _serie() -> void:
	# --- Pandémonia
	var B: Node = braise_v70
	_ok(B != null and B.city != null, "Pandémonia est là")
	if B != null and B.city != null:
		var C: Node = B.city
		_ok(C.kit.hd_v166, "Pandémonia en haute définition")
		_ok(C.kit.etals166 >= 10, "les étals sculptés de Pandémonia (%d)" % C.kit.etals166)
		var toiles: int = 0
		for k in C.kit.mats:
			if str(k).begins_with("t166") and _tex(C.kit.mats[k], "beau166/toile.png"):
				toiles += 1
		_ok(toiles >= 2, "la toile tissée des étals, rayée de deux couleurs (%d)" % toiles)
		_ok(_sculpt(C, "lueur70_vert") >= 1 and _sculpt(C, "cuir70") >= 1, "les fioles qui luisent et leurs bouchons")
		_ok(_sculpt(C, "lave70") >= 1 and _sculpt(C, "mnoir70") >= 1, "la fontaine de feu tournée (le marbre noir, la lave)")
		_ok(_sculpt(C, "or70") >= 1 and _sculpt(C, "braise70") >= 1, "le Cœur-Brasier : la lèvre d'or, les braises")
		_ok(_bons(C) == 0, "les pièces sculptées de Pandémonia ont leur maillage et leur matière")
	# --- Montjoie
	var M: Node = montjoie_v71
	_ok(M != null and M.city != null, "Montjoie est là")
	if M != null and M.city != null:
		var V: Node = M.city
		_ok(V.kit.hd_v166, "Montjoie en haute définition")
		_ok(V.kit.etals166 >= 3, "les étals sculptés du marché (%d)" % V.kit.etals166)
		_ok(_sculpt(V, "foin71") >= 1, "les corbeilles d'osier des étals")
		_ok(_sculpt(V, "dalles71_clair") >= 1 and _sculpt(V, "eau71_claire") >= 1, "la fontaine du Fondateur tournée, son eau")
		_ok(_sculpt(V, "moellons71") >= 1 and _sculpt(V, "cuir71") >= 1, "le puits : la margelle, la corde du treuil")
		_ok(V.find_children("Forge_v165_braise_*", "MeshInstance3D", true, false).size() >= 1 and V.find_children("Enclume_v165_fer_*", "MeshInstance3D", true, false).size() >= 1, "la forge : le lit de braises, la vraie enclume")
		_ok(_bons(V) == 0, "les pièces sculptées de Montjoie ont leur maillage et leur matière")
	# --- Port-Boucan
	var P: Node = boucan_v75
	_ok(P != null and P.city != null, "Port-Boucan est là")
	if P != null and P.city != null:
		var W: Node = P.city
		_ok(W.kit.hd_v166, "Port-Boucan en haute définition")
		var bp: Material = W.kit.mat("briquep75_rose")
		_ok(_shader(bp, "enduit_v163.gdshader") and str((bp as ShaderMaterial).get_shader_parameter("tex_pierre").resource_path).ends_with("boucan/brique.png"), "la brique peinte vieillie (la peinture tombée sur la vraie brique)")
		_ok(_sculpt(W, "peint75_rouge") >= 1 and _sculpt(W, "laiton71") >= 1, "la baignoire-fontaine en fonte sur ses pieds de lion")
		_ok(_sculpt(W, "salade166") + _sculpt(W, "chou166") + _sculpt(W, "tomate166") >= 2, "les potagers : salades, choux, tomates")
		_ok(_bons(W) == 0, "les pièces sculptées de Port-Boucan ont leur maillage et leur matière")
		if P.dehors != null and P.dehors.phare_light != null:
			_ok((-P.dehors.phare_light.transform.basis.z).y > 0.03, "le faisceau du phare passe au-dessus de la ville")
