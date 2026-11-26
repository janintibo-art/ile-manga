## Le détail allégé de loin, V211 : après le chargement, les gros maillages fabriqués par le jeu reçoivent
## leurs paliers (calcul à part, sans bloquer) ; le travail se termine ; la plupart y gagnent, et beaucoup
## (au plus léger, moins du tiers des triangles) ; un maillage allégé garde ses sommets, ses surfaces et ses
## matières ; les modèles importés ne sont pas refaits ; un maillage déjà allégé n'est pas repris ; le sol
## porte toujours le héros ; le seuil du moteur est resté celui de la qualité.
const NOM := "31_allege_loin"


func _serie() -> void:
	_ok(allege_v211 != null, "le jeu allège le détail de loin")
	if allege_v211 == null:
		return
	var garde211: int = 0
	while not allege_v211.fini and garde211 < 1200:
		await _att(0.5)
		garde211 += 1
	_ok(allege_v211.fini, "le calcul à part se termine (%.0f s)" % (float(allege_v211.ms_total) / 1000.0))
	_ok(int(allege_v211.faits) > 800, "les gros maillages sont passés en revue (%d)" % int(allege_v211.faits))
	_ok(int(allege_v211.gagnes) > int(allege_v211.faits) / 2, "la plupart ont reçu leurs paliers (%d sur %d)" % [int(allege_v211.gagnes), int(allege_v211.faits)])
	_ok(int(allege_v211.tri_loin) * 3 < int(allege_v211.tri_avant), "au plus léger, moins du tiers des triangles (de %d k à %d k)" % [int(allege_v211.tri_avant) / 1000, int(allege_v211.tri_loin) / 1000])
	_ok(allege_v211._fil == null and allege_v211._porteurs.is_empty(), "le fil de travail est rendu, rien n'est gardé en mémoire")
	# un maillage fabriqué par le jeu : allégé, il garde ses sommets, ses surfaces, ses matières
	var Al211 = load("res://scripts/allege_loin_v211.gd")
	var st211 := SurfaceTool.new()
	st211.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n211: int = 60
	for j211 in range(n211 + 1):
		for i211 in range(n211 + 1):
			st211.set_normal(Vector3.UP)
			st211.set_uv(Vector2(i211, j211) / float(n211))
			st211.add_vertex(Vector3(i211, sin(i211 * 0.3) * cos(j211 * 0.2) * 2.0, j211))
	for j2_211 in range(n211):
		for i2_211 in range(n211):
			var a211: int = j2_211 * (n211 + 1) + i2_211
			st211.add_index(a211)
			st211.add_index(a211 + 1)
			st211.add_index(a211 + n211 + 1)
			st211.add_index(a211 + 1)
			st211.add_index(a211 + n211 + 2)
			st211.add_index(a211 + n211 + 1)
	st211.generate_normals()
	var m211: ArrayMesh = st211.commit()
	var mat211 := StandardMaterial3D.new()
	m211.surface_set_material(0, mat211)
	var l211: ArrayMesh = Al211.alleger(m211)
	_ok(l211 != null and l211.has_meta("allege_v211"), "un sol de 7 200 triangles reçoit ses paliers")
	if l211 != null:
		_ok(l211.get_surface_count() == 1 and l211.surface_get_material(0) == mat211, "il garde sa surface et sa matière")
		_ok(l211.surface_get_array_len(0) == m211.surface_get_array_len(0) and l211.surface_get_array_index_len(0) == m211.surface_get_array_index_len(0), "de près, c'est le même maillage (mêmes sommets, mêmes triangles)")
		_ok(int(l211.get_meta("leger_v211", 99999)) < 2400, "au plus léger, il n'a plus que %d triangles" % int(l211.get_meta("leger_v211", 0)))
		_ok(l211.get_aabb().is_equal_approx(m211.get_aabb()), "il occupe la même place")
		# déjà allégé : le recensement ne le reprend pas
		var mi211 := MeshInstance3D.new()
		mi211.mesh = l211
		var racine211 := Node3D.new()
		racine211.add_child(mi211)
		var al2_211: Node = Al211.new()
		_ok(al2_211.recenser(racine211) == 0, "un maillage déjà allégé n'est pas repris")
		mi211.mesh = m211
		_ok(al2_211.recenser(racine211) == 1, "un maillage neuf est recensé")
		al2_211.tout()
		_ok(mi211.mesh != m211 and mi211.mesh.has_meta("allege_v211") and al2_211.gagnes == 1, "sur place, il est remplacé par sa version à paliers")
		al2_211.free()
		racine211.free()
	# un petit maillage : on le laisse
	var petit211 := BoxMesh.new()
	var ap211: ArrayMesh = ArrayMesh.new()
	ap211.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, petit211.get_mesh_arrays())
	_ok(Al211.triangles(ap211) == 12, "une boîte fait 12 triangles : trop petite pour être reprise")
	# le monde tient toujours : le héros est debout au village, le seuil est celui de la qualité
	_ranger()
	var sp211: Array = teleport_v58.spot("village")
	await _poser(sp211[0], sp211[1])
	_ok(await _debout("village"), "au village, le sol porte toujours le héros")
	_ok(absf(get_viewport().mesh_lod_threshold - 0.6) < 0.001, "le seuil du moteur reste celui de la qualité : un écart de moins d'un pixel (%.1f)" % get_viewport().mesh_lod_threshold)
	_ranger()
