## La beauté d'Arcanelle, de Port-Coutelas et de l'Île des Trois Soleils (V165) : Arcanelle (les neuf
## menhirs de vraie pierre, les ruches de paille tressée, l'autel de la Pierre-Lune sculpté, le lambris et
## le colombage du Chaudron Fumant) ; Port-Coutelas (les planches des cabanes grises de sel, la peinture
## qui s'écaille ; la vraie enclume sur son billot ; le foyer de la forge, sa hotte, le soufflet et le
## baquet) ; les Trois Soleils (les murs de terre et de chaux vieillis, le stuc rouge des Mayas, l'enduit
## tombé par plaques sur les briques crues ou sur la pierre ; les jarres tournées, les fours à pain, le
## metate ; la terre cuite, la pierre volcanique rouge d'Aztlán, le dallage des places). Les donjons
## gardent leurs matières.
const NOM := "beaute_iles"
const Mats69 := preload("res://scripts/soleils_mats_v69.gd")


func _tex(m: Material, fin: String) -> bool:
	var s: StandardMaterial3D = m as StandardMaterial3D
	return s != null and s.albedo_texture != null and s.albedo_texture.resource_path.ends_with(fin)


func _shader(m: Material, nom: String) -> bool:
	var s: ShaderMaterial = m as ShaderMaterial
	return s != null and s.shader != null and s.shader.resource_path.ends_with(nom)


func _sous(m: Material, fin: String) -> bool:
	var s: ShaderMaterial = m as ShaderMaterial
	if s == null:
		return false
	var t: Texture2D = s.get_shader_parameter("tex_pierre")
	return t != null and t.resource_path.ends_with(fin)


func _n(n: Node, motif: String) -> int:
	return n.find_children(motif, "MeshInstance3D", true, false).size() if n != null else 0


func _serie() -> void:
	# --- Arcanelle
	var A: Node = arcanelle_v67
	_ok(A != null and A.bourg != null, "Arcanelle est là")
	if A != null and A.bourg != null:
		var B: Node = A.bourg
		_ok(B.kit.hd_v165, "Arcanelle en haute définition")
		var men: int = _n(B, "Menhir_v165_*")
		_ok(men == 9, "les neuf menhirs du cercle, de vraie pierre (%d)" % men)
		var ru: Array = B.find_children("Ruche_v165_paille_*", "MeshInstance3D", true, false)
		_ok(ru.size() == 3 and _tex((ru[0] as MeshInstance3D).material_override, "beau165/paille_tressee.png"), "les trois ruches de paille tressée en boudins")
		_ok(B.taverne_v165 > 80, "le Chaudron Fumant : le lambris, la cimaise, le colombage et ses croix (%d pièces)" % B.taverne_v165)
		_ok(B.get_node_or_null("Autel_v165_pierrelune") != null and B.get_node_or_null("Autel_v165_runes_or") != null, "l'autel de la Pierre-Lune sculpté (le filet d'or)")
	# --- Port-Coutelas
	var P: Node = pirates_v68
	_ok(P != null and P.port != null, "Port-Coutelas est là")
	if P != null and P.port != null:
		var K = P.port.kit
		_ok(K.hd_v165, "Port-Coutelas en haute définition")
		var pl: StandardMaterial3D = K.mat("planchesp") as StandardMaterial3D
		_ok(_tex(pl, "beau165/planches_pirate.png") and pl.roughness_texture != null, "les planches grises de sel des cabanes (la peinture qui s'écaille)")
		_ok(_n(P.port, "Enclume_v165_fer_*") >= 1 and _n(P.port, "Enclume_v165_bois_*") >= 1, "la vraie enclume sur son billot")
		_ok(_n(P.port, "Forge_v165_braise_*") == 1 and _n(P.port, "Forge_v165_charbon_*") == 1, "le foyer de la forge : le lit de braises et de charbons")
		_ok(_n(P.port, "Forge_v165_cuir_*") == 1 and _n(P.port, "Forge_v165_eau_*") == 1, "le soufflet de cuir, le baquet d'eau")
	# --- les Trois Soleils
	var S: Node = soleils_v69
	_ok(S != null and S.egypte != null and S.maya != null and S.azteque != null, "les trois villages des Soleils sont là")
	if S == null or S.egypte == null or S.maya == null or S.azteque == null:
		return
	var E = S.egypte.kit
	var M = S.maya.kit
	var Z = S.azteque.kit
	_ok(E.hd_v165 and M.hd_v165 and Z.hd_v165, "Per-Hâpy, Yaxché et Aztlán en haute définition")
	_ok(E.climat_v165 == "egypte" and M.climat_v165 == "maya" and Z.climat_v165 == "azteque", "chacun son climat")
	var en: Material = E.mat("enduit69_ocre")
	_ok(_shader(en, "enduit_v163.gdshader") and _sous(en, "beau165/adobe.png"), "Per-Hâpy : l'enduit de terre vieilli, tombé par plaques sur les briques crues")
	_ok(absf(float((en as ShaderMaterial).get_shader_parameter("sol_y")) - E.sol_v165) < 0.01 if en is ShaderMaterial else false, "l'humidité monte du sol du village")
	var st: Material = M.mat("stucr69_blanc")
	_ok(_shader(st, "enduit_v163.gdshader") and _sous(st, "soleils/pierre_maya.png"), "Yaxché : le stuc rouge, tombé par plaques sur la pierre")
	var tr: Color = (st as ShaderMaterial).get_shader_parameter("teinte") if st is ShaderMaterial else Color.WHITE
	_ok(tr.r > tr.g * 2.0, "le stuc des Mayas est rouge")
	_ok(_shader(Z.mat("enduit69_blanc"), "enduit_v163.gdshader"), "Aztlán : les maisons d'adobe blanchies")
	_ok(_tex(E.mat("brique69"), "beau165/adobe.png"), "les briques crues (la paille, les arêtes usées)")
	_ok(_tex(E.mat("argile69_terre"), "beau165/terre_cuite.png"), "la terre cuite des jarres et des fours")
	_ok(_tex(Z.mat("tezo69"), "beau165/tezontle.png"), "la pierre volcanique rouge d'Aztlán")
	_ok(_tex(Z.mat("dalles69"), "beau165/dallage_soleils.png"), "le dallage des places")
	var jarres: int = _n(S.egypte, "Sculpt_v165_argile69*")
	_ok(jarres >= 2, "Per-Hâpy : les jarres tournées (%d matières)" % jarres)
	_ok(_n(S.egypte, "Sculpt_v165_suie165") == 1 and _n(S.egypte, "Sculpt_v165_cendre165") == 1, "les fours à pain (la suie, la cendre)")
	_ok(_n(S.maya, "Sculpt_v165_mais165") == 1 and _n(S.maya, "Sculpt_v165_psombre69") == 1, "Yaxché : le metate, sa mano, la pâte et les épis")
	_ok(_n(S.azteque, "Sculpt_v165_argile69*") >= 1, "Aztlán : les jarres tournées")
	# aucun maillage sculpté vide, chacun a sa matière
	var vides: int = 0
	for V in [S.egypte, S.maya, S.azteque]:
		for mi in (V as Node).find_children("Sculpt_v165_*", "MeshInstance3D", true, false):
			if (mi as MeshInstance3D).mesh == null or (mi as MeshInstance3D).mesh.get_surface_count() == 0 or (mi as MeshInstance3D).material_override == null:
				vides += 1
	_ok(vides == 0, "les pièces sculptées ont leur maillage et leur matière")
	# le sol : le dallage des places et des chaussées
	var sol: ShaderMaterial = null
	for c in S.ile.get_children():
		if c is MeshInstance3D and _shader((c as MeshInstance3D).material_override, "soleils_terrain_v69.gdshader"):
			sol = (c as MeshInstance3D).material_override
			break
	var dt: Texture2D = sol.get_shader_parameter("dalles_soleil_tex") if sol != null else null
	_ok(dt != null and dt.resource_path.ends_with("beau165/dallage_soleils.png"), "le sol des places : les dalles de calcaire en rangs")
	# les donjons gardent leurs matières (le cache partagé n'est pas touché)
	_ok(Mats69.make("enduit69_ocre") is StandardMaterial3D and _tex(Mats69.make("enduit69_ocre"), "soleils/enduit.png"), "les donjons gardent leurs matières")
