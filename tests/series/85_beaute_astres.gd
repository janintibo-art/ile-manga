## La beauté d'Astralys, de Larsen et de l'Île Pixelithique (V167) : à Astralys, la fontaine de l'Agora
## tournée dans la nacre (le filet de lumière de la margelle, la colonne-vase, les trois anneaux d'or qui
## flottent) et le grand télescope (le pilier, la fourche, le tube bagué d'or, l'objectif, le
## chercheur) ; à Larsen, le métier à tisser, les tabourets, les djembés à cordes, les tables de
## bistrot sous leurs parasols, les chaises cintrées ; l'Île Pixelithique garde ses pixels : de loin, les
## blocs et les strates des falaises restent visibles.
const NOM := "beaute_astres"


func _n(n: Node, motif: String) -> int:
	return n.find_children(motif, "MeshInstance3D", true, false).size() if n != null else 0


func _serie() -> void:
	# --- Astralys
	var A: Node = astralys_v76
	_ok(A != null and A.city != null, "Astralys est là")
	if A != null and A.city != null:
		var C: Node = A.city
		_ok(C.kit.hd_v167, "Astralys en haute définition")
		_ok(_n(C, "Sculpt_v166_metal76_or_*") >= 1 and _n(C, "Sculpt_v166_lumiere76_turquoise_*") >= 1, "la fontaine de nacre, son filet de lumière, les anneaux d'or")
		_ok(_n(C, "Sculpt_v166_cristal76_bleu_*") >= 1 and _n(C, "Sculpt_v166_metal76_bleu_*") >= 1, "le grand télescope : le tube, l'objectif de cristal")
		var vides: int = 0
		for mi in C.find_children("Sculpt_v166_*", "MeshInstance3D", true, false):
			if (mi as MeshInstance3D).mesh == null or (mi as MeshInstance3D).material_override == null:
				vides += 1
		_ok(vides == 0, "les pièces sculptées d'Astralys ont leur maillage et leur matière")
	# --- Larsen
	var L: Node = larsen_v91
	_ok(L != null and L.ville != null, "Larsen est là")
	if L != null and L.ville != null:
		var V: Node = L.ville
		_ok(V.hd_v167, "Larsen en haute définition")
		_ok(_n(V, "Metier_v167_*") >= 3, "le métier à tisser (la toile rayée, les fils de chaîne)")
		_ok(_n(V, "Djembe_v167_*") >= 3 and _n(V, "Tabouret_v167_*") >= 1, "les djembés à cordes, les tabourets")
		_ok(_n(V, "Parasol_v167_*") >= 4 and _n(V, "Chaise_v167_*") >= 2, "les tables de bistrot sous leurs parasols, les chaises cintrées")
		var sans: int = 0
		for pat in ["Metier_v167_*", "Djembe_v167_*", "Tabouret_v167_*", "Parasol_v167_*", "Chaise_v167_*"]:
			for mi2 in V.find_children(pat, "MeshInstance3D", true, false):
				if (mi2 as MeshInstance3D).mesh == null or (mi2 as MeshInstance3D).material_override == null:
					sans += 1
		_ok(sans == 0, "le mobilier sculpté de Larsen a son maillage et sa matière")
		_ok(V.pieces_v167 >= 9, "le mobilier sculpté de Larsen (%d pièces)" % V.pieces_v167)
	# --- l'Île Pixelithique
	var P: Node = pixel_v90
	_ok(P != null and P.ile != null and P.ile.terrain_mat != null, "l'Île Pixelithique est là")
	if P != null and P.ile != null and P.ile.terrain_mat != null:
		var code: String = (P.ile.terrain_mat as ShaderMaterial).shader.code
		_ok(code.contains("V167") and code.contains("blocv"), "de loin, les blocs et les strates des falaises restent visibles")
