extends SceneTree
## V203 : fabrique les versions « casque » des modèles lourds (plus de 200 000 triangles).
## Godot calcule déjà, à l'import, des versions allégées de chaque modèle ; on prend celle dont
## l'écart avec l'original ne dépasse pas ECART (en mètres, à la taille du modèle dans le jeu), on
## retire les points devenus inutiles et on l'enregistre dans res://allege/, avec les versions
## encore plus légères pour la distance.
## Lancement : godot --headless --path pcvr --script res://tools/alleger_v203.gd
## À relancer si un modèle lourd change. Les tailles viennent de main.gd (_add_glb).

const ECART := 0.025
const LOURD := 200000
const MODELES := {
	"res://assets/models/buildings/Petite_maison.glb": 4.15,
	"res://assets/models/buildings/Maison.glb": 4.5,
	"res://assets/models/buildings/Ile_flottante.glb": 12.0,
	"res://assets/models/props/Mur_de_son.glb": 6.0,
	"res://assets/models/props/Feu.glb": 1.2,
	"res://assets/models/props/Distributeur_8_6.glb": 1.8,
	"res://assets/models/props/Table_de_mixage.glb": 2.5,
}


func _indices(octets: PackedByteArray, grand: bool) -> PackedInt32Array:
	if grand:
		return octets.to_int32_array()
	var r := PackedInt32Array()
	var n: int = octets.size() / 2
	r.resize(n)
	for i in n:
		r[i] = octets.decode_u16(i * 2)
	return r


func _triangles(m: ArrayMesh) -> int:
	var t := 0
	for s in m.get_surface_count():
		var il: int = m.surface_get_array_index_len(s)
		t += (il if il > 0 else m.surface_get_array_len(s)) / 3
	return t


func _alleger(m: ArrayMesh, taille: float, echelle_noeud: float) -> ArrayMesh:
	var leger := ArrayMesh.new()
	for s in m.get_surface_count():
		var arr: Array = m.surface_get_arrays(s)
		var d: Dictionary = RenderingServer.mesh_get_surface(m.get_rid(), s)
		var nv: int = (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
		var grand: bool = nv > 65535
		var lods: Array = d.get("lods", [])
		# l'écart d'une version est donné à la taille du fichier : on le ramène à la taille du jeu
		var k := -1
		for i in lods.size():
			if float(lods[i]["edge_length"]) * taille * echelle_noeud <= ECART:
				k = i
		var base: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if k < 0 else _indices(lods[k]["index_data"], grand)
		var suite: Array = []
		for i in range(k + 1, lods.size()):
			suite.append([float(lods[i]["edge_length"]), _indices(lods[i]["index_data"], grand)])
		# les points encore utilisés, renumérotés
		var nouveau := PackedInt32Array()
		nouveau.resize(nv)
		nouveau.fill(-1)
		var garde := PackedInt32Array()
		var listes: Array = [base]
		for l in suite:
			listes.append(l[1])
		for l in listes:
			for idx in (l as PackedInt32Array):
				if nouveau[idx] < 0:
					nouveau[idx] = garde.size()
					garde.append(idx)
		var sortie: Array = []
		sortie.resize(Mesh.ARRAY_MAX)
		for a in Mesh.ARRAY_MAX:
			if a == Mesh.ARRAY_INDEX or arr[a] == null:
				continue
			var src: Variant = arr[a]
			var par: int = src.size() / nv
			var dst: Variant = src.duplicate()
			dst.resize(garde.size() * par)
			for i in garde.size():
				for j in par:
					dst[i * par + j] = src[garde[i] * par + j]
			sortie[a] = dst
		var bi := PackedInt32Array()
		bi.resize(base.size())
		for i in base.size():
			bi[i] = nouveau[base[i]]
		sortie[Mesh.ARRAY_INDEX] = bi
		var dl: Dictionary = {}
		for l in suite:
			var li := PackedInt32Array()
			var srcl: PackedInt32Array = l[1]
			li.resize(srcl.size())
			for i in srcl.size():
				li[i] = nouveau[srcl[i]]
			dl[l[0]] = li
		leger.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, sortie, [], dl)
		leger.surface_set_name(leger.get_surface_count() - 1, m.surface_get_name(s))
	return leger


func _init() -> void:
	DirAccess.make_dir_recursive_absolute("res://allege")
	for chemin in MODELES:
		var ps: PackedScene = load(chemin)
		if ps == null:
			print("ALLEGER absent ", chemin)
			continue
		var n: Node = ps.instantiate()
		for mi in n.find_children("*", "MeshInstance3D", true, false):
			var m: ArrayMesh = (mi as MeshInstance3D).mesh as ArrayMesh
			if m == null:
				continue
			var t: int = _triangles(m)
			if t <= LOURD:
				continue
			# l'échelle propre au nœud dans le fichier
			var ech := 1.0
			var p: Node = mi
			while p != null and p is Node3D:
				ech *= (p as Node3D).scale.x
				p = p.get_parent()
			var leger: ArrayMesh = _alleger(m, MODELES[chemin], ech)
			var cle := "%s_%d" % [str(chemin).get_file().get_basename(), t]
			var err: int = ResourceSaver.save(leger, "res://allege/%s.res" % cle, ResourceSaver.FLAG_COMPRESS)
			print("ALLEGER %s : %d k -> %d k triangles, échelle %.3f, %d surface(s), enregistrement %d" % [cle, t / 1000, _triangles(leger) / 1000, ech, leger.get_surface_count(), err])
		n.free()
	quit()
