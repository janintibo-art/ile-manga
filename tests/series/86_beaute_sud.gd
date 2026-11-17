## La beauté d'Al Dente, de l'Île Crayonnée et de Sombreval (V168) : à Al Dente, le four à pain à la
## napolitaine (la coupole, l'avant-four voûté et son arc, la bouche, la cheminée, la réserve de bois, la
## pelle), les vraies feuilles à cinq lobes de la treille, les tomates rondes et leur calice ; l'Île
## Crayonnée garde son coloriage (un troisième sens de hachures dans le noir, la main qui appuie plus ou
## moins, le grain du papier) ; à Sombreval, les tombes sculptées du vieux cimetière (stèles, croix,
## croix celtiques, obélisques, dalles, entourages de fer) et la fontaine à sec de la place du marché.
const NOM := "beaute_sud"


func _n(n: Node, motif: String) -> int:
	return n.find_children(motif, "MeshInstance3D", true, false).size() if n != null else 0


func _sans(n: Node, motif: String) -> int:
	var k: int = 0
	for mi in n.find_children(motif, "MeshInstance3D", true, false):
		if (mi as MeshInstance3D).mesh == null or (mi as MeshInstance3D).material_override == null:
			k += 1
	return k


func _serie() -> void:
	# --- Al Dente
	var A: Node = pasta_v97
	_ok(A != null and A.ville != null, "Al Dente est là")
	if A != null and A.ville != null:
		var V: Node = A.ville
		_ok(V.hd_v168, "Al Dente en haute définition")
		_ok(_n(V, "Four_v168_terre_cuite_*") == 1 and _n(V, "Four_v168_suie_*") == 1 and _n(V, "Four_v168_bois_*") >= 1, "le four à pain (la coupole, la bouche, les bûches)")
		_ok(_sans(V, "Four_v168_*") == 0, "le four a son maillage et ses matières")
		var tom: String = FileAccess.get_file_as_string("res://scripts/pasta_flore_v97.gd")
		_ok(tom.contains("V168 : la tomate plus ronde"), "les tomates rondes et leur calice")
	# --- l'Île Crayonnée
	var inc: String = FileAccess.get_file_as_string("res://shaders/crayon_v99.gdshaderinc")
	_ok(inc.contains("V168") and inc.contains("press") and inc.contains("grain"), "le coloriage : les hachures du noir, la pression du crayon, le grain du papier")
	# --- Sombreval
	var S: Node = sombreval_v121
	_ok(S != null, "Sombreval est là")
	if S != null:
		_ok(S.hd_v168, "Sombreval en haute définition")
		_ok(S.tombes_v168 >= 20, "les tombes sculptées du vieux cimetière (%d)" % S.tombes_v168)
		_ok(_n(S, "Tombes_v168_pierre_tombe_*") == 1 and _n(S, "Tombes_v168_mousse_*") == 1, "les tombes : la pierre, la mousse")
		_ok(_n(S, "Fontaine_v168_pierre_tombe_*") == 1, "la fontaine à sec de la place du marché")
		_ok(_sans(S, "Tombes_v168_*") + _sans(S, "Fontaine_v168_*") == 0, "les pièces sculptées de Sombreval ont leur maillage et leur matière")
