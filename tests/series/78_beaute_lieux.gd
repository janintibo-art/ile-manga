## La beauté des lieux (V161) : la Citadelle des Nuées sur l'île flottante (la pierre vieillie : les
## coulures, la mousse, les lichens ; le trône sculpté et le lutrin au grand livre ; les vitraux sertis
## de plomb ; les racines et les lianes sous l'île) ; l'Île des Géants (le bois peint qui s'écaille, le
## zinc galvanisé, le fer forgé, le caoutchouc des bottes, la terre cuite, les géraniums en fleurs, le
## bout des balles rondes en spirale, la corde, la toile, le tweed) ; Néopolis (les feux tricolores des
## carrefours, les bornes, les poubelles, les bancs et les bacs du Boulevard ; les conteneurs en tôle
## ondulée ; le sol : les plaques d'égout, les avaloirs, les bandes podotactiles).
const NOM := "beaute_lieux"
const KitG := preload("res://scripts/geants_kit_v142.gd")
const KitN := preload("res://scripts/neo_kit_v94.gd")


func _tex(m: Material, nom: String) -> bool:
	var s: StandardMaterial3D = m as StandardMaterial3D
	return s != null and s.albedo_texture != null and s.albedo_texture.resource_path.ends_with("beau161/" + nom + ".png")


func _serie() -> void:
	# --- la Citadelle des Nuées
	var Cv: Node = ciel_v54
	_ok(Cv != null and Cv.chateau != null and Cv.ile != null, "l'île flottante et sa Citadelle sont là")
	if Cv != null and Cv.chateau != null:
		var K: Node = Cv.chateau
		var pierre: ShaderMaterial = K._mat("pierre") as ShaderMaterial
		_ok(pierre != null and pierre.shader.code.contains("mousse") and pierre.get_shader_parameter("tex_albedo") != null, "la pierre de la Citadelle, vieillie (les coulures, la mousse, les lichens)")
		var trone: Node = K.get_node_or_null("Trone_v161")
		var lutrin: Node = K.get_node_or_null("Lutrin_v161")
		_ok(trone != null and trone.get_child_count() >= 3, "le trône sculpté des Rois-Ciel (%d matières)" % (trone.get_child_count() if trone != null else 0))
		_ok(lutrin != null and (K._mats_mobilier()["papier"] as StandardMaterial3D).albedo_texture != null, "le lutrin et le grand livre ouvert")
		_ok(_tex(K._mat("vitrail"), "vitrail"), "les vitraux sertis de plomb")
		_ok(Cv.ile.get_node_or_null("Racines_v161_ecorce") != null and Cv.ile.get_node_or_null("Racines_v161_feuilles") != null, "les racines et les lianes sous l'île")
	# --- l'Île des Géants
	_ok(_tex(KitG.mat("blanc"), "bois_peint") and _tex(KitG.mat("zinc"), "zinc_galva"), "le bois peint qui s'écaille, le zinc galvanisé")
	_ok(_tex(KitG.mat("caoutchouc"), "caoutchouc") and _tex(KitG.mat("pneu"), "caoutchouc") and _tex(KitG.mat("terre_cuite"), "terre_cuite"), "le caoutchouc des bottes et du pneu, la terre cuite")
	_ok(_tex(KitG.mat("foin_rond"), "foin_rond") and _tex(KitG.mat("corde"), "corde") and _tex(KitG.mat("toile"), "toile_lin") and _tex(KitG.mat("veste"), "tweed"), "la balle ronde en spirale, la corde, la toile, le tweed")
	var ge: ShaderMaterial = KitG.mat("geranium") as ShaderMaterial
	_ok(ge != null and (KitG.mat("feuille") as ShaderMaterial) != null and float((KitG.mat("feuille") as ShaderMaterial).get_shader_parameter("feuille")) > 0.5, "les géraniums en fleurs et leurs feuilles")
	var fer: StandardMaterial3D = KitG.mat("fer") as StandardMaterial3D
	_ok(fer != null and fer.roughness_texture != null, "le fer forgé des géants")
	# --- Néopolis
	var N: Node = neo_v94
	_ok(N != null and int(N.nb_feux) >= 150, "les feux tricolores des carrefours (%d)" % (int(N.nb_feux) if N != null else 0))
	var f0: ShaderMaterial = KitN.mat("feux_ns_0") as ShaderMaterial
	var f1: ShaderMaterial = KitN.mat("feux_ew_2") as ShaderMaterial
	_ok(f0 != null and f1 != null and float(f1.get_shader_parameter("phase")) > 0.5 and int(f1.get_shader_parameter("feu")) == 2, "les feux marchent (une rue au vert, l'autre au rouge)")
	_ok(_tex(KitN.mat("conteneur_bleu"), "conteneur") and (KitN.mat("metal") as StandardMaterial3D).roughness_texture != null, "les conteneurs en tôle ondulée, le métal brossé")
	var rue: Node = N.get_node_or_null("Neo_rue_v161") if N != null else null
	_ok(rue != null, "la rue meublée (bornes, poubelles, bancs, bacs à cerisiers)")
	var sol: Shader = load("res://shaders/neo_sol_v94.gdshader")
	_ok(sol != null and sol.code.contains("podo") and sol.code.contains("avaloirs"), "le sol : les plaques d'égout, les avaloirs, les bandes podotactiles")
