## La beauté de la mer et de la jungle (V162) : l'Atlantide (les colonnes ioniques sculptées, la
## mosaïque romaine, les portes de bronze des maisons, l'or patiné, la tour cannelée et ses
## arcs-boutants, les caustiques qui ondulent sur le sol) ; l'île de la jungle
## (le calcaire des pitons : les cannelures de la pluie, les coulures noires, les lichens).
const NOM := "beaute_mer"


func _serie() -> void:
	# --- l'Atlantide
	var A: Node = mer_v55.atl if mer_v55 != null else null
	_ok(A != null, "l'Atlantide est là")
	if A != null:
		var cols: Array = A.find_children("Colonne_sculptee_*", "MeshInstance3D", true, false)
		_ok(cols.size() >= 20, "les colonnes sculptées (%d)" % cols.size())
		var brisees: int = 0
		for c in cols:
			if (c as MeshInstance3D).mesh.get_surface_count() == 1:
				brisees += 1
		_ok(brisees >= 2, "des colonnes brisées le long de l'avenue (%d)" % brisees)
		var mo: StandardMaterial3D = A.mat("mosaique")
		_ok(mo.albedo_texture != null and mo.albedo_texture.resource_path.ends_with("beau162/mosaique.png"), "la mosaïque romaine de la place")
		_ok(A.mat("or").roughness_texture != null and A.mat("bronze_porte").roughness_texture != null, "l'or patiné, les portes de bronze")
		var ca: MeshInstance3D = A.get_node_or_null("Caustiques_v162")
		_ok(ca != null and (ca.material_override as ShaderMaterial).get_shader_parameter("caustic_tex") != null, "les caustiques qui ondulent sur le sol")
	# --- la jungle
	var J: Node = jungle_v29
	_ok(J != null, "l'île de la jungle est là")
	if J != null:
		var sol: ShaderMaterial = null
		for ch2 in J.get_children():
			if ch2 is MeshInstance3D and str(ch2.name).begins_with("Jungle_sol"):
				sol = (ch2 as MeshInstance3D).material_override
				break
		var rt: Texture2D = sol.get_shader_parameter("rock_tex") if sol != null else null
		_ok(sol != null and bool(sol.get_shader_parameter("karst")) and rt != null and rt.resource_path.ends_with("beau162/karst.png"), "le calcaire des pitons (les cannelures, les coulures, les lichens)")
