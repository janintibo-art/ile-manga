extends SceneTree
## V24 : pré-calcule des collisions simplifiées pour les gros modèles GLB.
## Les modèles font 0,6 à 2 millions de triangles : les transformer en collision au lancement
## coûtait près d'une minute. On regroupe ici les sommets sur une grille de quelques
## centimètres (taille réelle dans le jeu), ce qui garde murs, portes et marches.
## Lancement : godot --headless --path pcvr --script res://tools/bake_collisions_v24.gd

const MODELS := {
	"Maison_village": ["res://assets/models/buildings/Maison.glb", 4.5],
	"Petite_maison": ["res://assets/models/buildings/Petite_maison.glb", 4.15],
	"Mur_de_son": ["res://assets/models/props/Mur_de_son.glb", 6.0],
	"Table_de_mixage": ["res://assets/models/props/Table_de_mixage.glb", 2.5],
	"Distributeur_8_6": ["res://assets/models/props/Distributeur_8_6.glb", 1.8],
}
const CELL_WORLD: float = 0.1
# V27 : ouvertures des portes (repère du modèle), retirées des collisions.
const Houses = preload("res://scripts/houses_v27.gd")


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://collision"))
	for label in MODELS.keys():
		var info: Array = MODELS[label]
		var packed: PackedScene = load(info[0])
		var root: Node3D = packed.instantiate()
		# Faces mises à l'échelle du jeu : la collision n'a jamais besoin d'être agrandie.
		var faces := _collect_faces(root)
		faces = _without_doorway(faces, Houses.hole_for(label))
		var scale_factor: float = float(info[1])
		for i in range(faces.size()):
			faces[i] *= scale_factor
		var simple := _cluster(faces, CELL_WORLD)
		var shape := ConcavePolygonShape3D.new()
		shape.set_faces(simple)
		shape.backface_collision = true
		var path := "res://collision/%s.res" % label
		ResourceSaver.save(shape, path, ResourceSaver.FLAG_COMPRESS)
		print("BAKE ", label, " : ", faces.size() / 3, " -> ", simple.size() / 3, " triangles")
		root.queue_free()
	quit()


# Toutes les faces, exprimées dans le repère de la racine du modèle.
func _collect_faces(root: Node3D) -> PackedVector3Array:
	var out := PackedVector3Array()
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children():
			stack.append(c)
		if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
			# Le script tourne avant l'arbre de scène : on cumule les transformations à la main.
			var xf := Transform3D.IDENTITY
			var walk: Node = n
			while walk != root and walk != null:
				xf = (walk as Node3D).transform * xf if walk is Node3D else xf
				walk = walk.get_parent()
			var f := (n as MeshInstance3D).mesh.get_faces()
			for i in range(f.size()):
				f[i] = xf * f[i]
			out.append_array(f)
	return out


# Regroupement de sommets : chaque sommet est ramené au centre de sa cellule,
# les triangles devenus plats ou en double disparaissent.
func _cluster(faces: PackedVector3Array, cell: float) -> PackedVector3Array:
	var out := PackedVector3Array()
	var seen := {}
	for i in range(0, faces.size(), 3):
		var a := Vector3i((faces[i] / cell).round())
		var b := Vector3i((faces[i + 1] / cell).round())
		var c := Vector3i((faces[i + 2] / cell).round())
		if a == b or b == c or a == c:
			continue
		var key := [a, b, c]
		key.sort()
		if seen.has(key):
			continue
		seen[key] = true
		out.append(Vector3(a) * cell)
		out.append(Vector3(b) * cell)
		out.append(Vector3(c) * cell)
	return out


# V27 : retire les triangles dont le centre tombe dans l'ouverture de la porte.
func _without_doorway(faces: PackedVector3Array, hole: Dictionary) -> PackedVector3Array:
	if hole.is_empty():
		return faces
	var out := PackedVector3Array()
	var removed: int = 0
	for i in range(0, faces.size(), 3):
		var c: Vector3 = (faces[i] + faces[i + 1] + faces[i + 2]) / 3.0
		if _in_hole(c, hole):
			removed += 1
			continue
		out.append(faces[i])
		out.append(faces[i + 1])
		out.append(faces[i + 2])
	print("  ouverture de porte : ", removed, " triangles retirés")
	return out


func _in_hole(p: Vector3, h: Dictionary) -> bool:
	var hx: Vector2 = h["hole_x"]
	var hz: Vector2 = h["hole_z"]
	if p.z < hz.x or p.z > hz.y or p.x < hx.x or p.x > hx.y or p.y < float(h["bottom"]) or p.y > float(h["apex"]):
		return false
	if p.y <= float(h["spring"]):
		return true
	var u: float = (p.x - (hx.x + hx.y) * 0.5) / ((hx.y - hx.x) * 0.5)
	var v: float = (p.y - float(h["spring"])) / (float(h["apex"]) - float(h["spring"]))
	return u * u + v * v < 1.0
