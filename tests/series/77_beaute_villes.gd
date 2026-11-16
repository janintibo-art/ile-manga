## La beauté des villes (V160) : le kit des métaux (le grain, le relief, la rugosité : brossé, patiné,
## vert-de-gris, fer forgé) à Hautefond, à la Cité des Nuées, aux Strates, au Dôme d'Azur et à l'Île
## Perchée ; le mur-rideau en profondeur (des pièces derrière les vitres) dans les tours des Nuées et du
## Dôme (où la vitre reflète la mer, et où des pièces sont allumées même le jour) ; les toiles tendues
## qui laissent passer le soleil ; le soir, les pièces s'allument ; les champignons lumineux des Strates ;
## les coraux du Dôme et leurs polypes.
const NOM := "beaute_villes"
const MatsH := preload("res://scripts/hautefond_mats_v112.gd")
const MatsN := preload("res://scripts/nuees_mats_v113.gd")
const MatsS := preload("res://scripts/strates_mats_v114.gd")
const MatsD := preload("res://scripts/dome_mats_v115.gd")
const KitP := preload("res://scripts/perchee_kit_v146.gd")


## Un métal habillé par le kit : la texture (beau160/<nom>), le relief, la rugosité, en triplanaire.
func _metal_hd(m: Material, nom: String) -> bool:
	var s: StandardMaterial3D = m as StandardMaterial3D
	if s == null or s.albedo_texture == null or s.normal_texture == null or s.roughness_texture == null:
		return false
	return s.albedo_texture.resource_path.ends_with("beau160/" + nom + ".png") and s.uv1_triplanar


func _facade_trouvee(n: Node, sm: Material) -> bool:
	var pile: Array = [n]
	var vus: int = 0
	while not pile.is_empty() and vus < 40000:
		var c: Node = pile.pop_back()
		vus += 1
		if c is MeshInstance3D and (c as MeshInstance3D).mesh != null:
			var mi: MeshInstance3D = c
			for i in range(mi.mesh.get_surface_count()):
				if mi.get_active_material(i) == sm:
					return true
		for ch in c.get_children():
			pile.append(ch)
	return false


func _serie() -> void:
	# --- les métaux
	_ok(_metal_hd(MatsH.make("laiton112"), "metal_patine") and _metal_hd(MatsH.make("acier112"), "fer_noir") and _metal_hd(MatsH.make("verdigris112"), "verdigris"), "Hautefond : le laiton patiné, l'acier en fer forgé, le cuivre vert-de-gris")
	_ok(_metal_hd(MatsN.make("acier113"), "metal_brosse") and _metal_hd(MatsN.make("alu113"), "metal_brosse"), "la Cité des Nuées : l'acier et l'aluminium brossés")
	_ok(_metal_hd(MatsS.make("rail114"), "metal_brosse"), "les Strates : les rails d'acier")
	_ok(_metal_hd(MatsD.make("titane115"), "metal_brosse"), "le Dôme d'Azur : le titane brossé")
	_ok(_metal_hd(KitP.mat("laiton"), "metal_patine") and _metal_hd(KitP.mat("fer"), "fer_noir"), "l'Île Perchée : le laiton patiné, le fer forgé")
	var miroir: StandardMaterial3D = MatsN.make("peint113_bleu") as StandardMaterial3D
	_ok(miroir != null and miroir.roughness_texture == null, "les peintures restent lisses (le kit ne prend que les métaux)")
	# --- le mur-rideau
	var fa: ShaderMaterial = MatsN.make("facade113") as ShaderMaterial
	_ok(fa != null and fa.shader != null and fa.shader.code.contains("vec3 piece(") and fa.shader.code.contains("ciel("), "le mur-rideau des Nuées : des pièces derrière les vitres, le ciel dans les vitres")
	var H: Node = hautefond_v112
	_ok(H != null and H.nuees != null, "la Cité des Nuées est là")
	if H != null and H.nuees != null and fa != null:
		_ok(_facade_trouvee(H.nuees, fa), "les tours des Nuées ont le mur-rideau en profondeur")
		MatsN.night(1.0)
		_ok(float(fa.get_shader_parameter("glow")) > 1.0 and float(fa.get_shader_parameter("nuit")) > 0.9, "le soir, les pièces s'allument")
		MatsN.night(0.0)
		_ok(float(fa.get_shader_parameter("glow")) < 0.01, "le jour, les lampes s'éteignent")
	if H != null and H.dome != null:
		var fd: ShaderMaterial = MatsD.facade as ShaderMaterial
		_ok(fd != null and fd != fa and float(fd.get_shader_parameter("eau")) > 0.9 and float(fd.get_shader_parameter("lampes_jour")) > 0.2, "sous le Dôme : la vitre reflète la mer, des pièces allumées le jour")
	# --- les champignons lumineux des Strates
	var chp: ShaderMaterial = MatsS.make("champi114_bleu") as ShaderMaterial
	var lam: ShaderMaterial = MatsS.make("lamelles114_bleu") as ShaderMaterial
	_ok(chp != null and chp.shader.code.contains("tache") and lam != null and float(lam.get_shader_parameter("lamelles")) > 0.5, "les champignons lumineux des Strates : le bord translucide, les taches, les lamelles")
	# --- les coraux du Dôme
	var co: ShaderMaterial = MatsD.make("corail115_rose") as ShaderMaterial
	_ok(co != null and co.shader.code.contains("polype"), "les coraux du Dôme : les polypes qui luisent")
	# --- les toiles
	var to: StandardMaterial3D = MatsN.make("toile113_bleu") as StandardMaterial3D
	_ok(to != null and to.backlight_enabled, "les toiles tendues laissent passer le soleil")
