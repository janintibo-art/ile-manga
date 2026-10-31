extends RefCounted
## V90 : les modèles en petits cubes de l'Île Pixelithique (tools/generate_pixel_v90.py →
## modeles.bin) : plantes, rochers, décor, dinosaures et hommes des cavernes. On les lit une fois ;
## chaque modèle devient un ArrayMesh (couleurs dans les sommets : les « pixels » et leurs ombres
## douces sont déjà peints). Les bêtes et les gens sont en pièces articulées : rig() les assemble
## (chaque pièce sur son articulation, les enfants sur leurs parents).

const Corps = preload("res://scripts/pnj/corps_v64.gd")
const BIN := "res://assets/models/pixel90/modeles.bin"

## Qui tient à qui (sinon : au corps)
const PARENTS := {
	"raptor": {"machoire": "cou", "queue2": "queue", "jambeG": "cuisseG", "jambeD": "cuisseD"},
	"trex": {"machoire": "tete", "queue2": "queue", "queue3": "queue2", "jambeG": "cuisseG", "jambeD": "cuisseD"},
	"brachiosaure": {"cou2": "cou", "tete": "cou2", "queue2": "queue"},
	"pteranodon": {"boutG": "aileG", "boutD": "aileD"},
}

static var _data: Dictionary = {}
static var _meshes: Dictionary = {}
static var _mat: StandardMaterial3D


static func data() -> Dictionary:
	if _data.is_empty():
		_data = Corps.read_bin(BIN)
	return _data


static func has(nom: String) -> bool:
	return data().get("modeles", {}).has(nom)


static func mesh(nom: String) -> ArrayMesh:
	if _meshes.has(nom):
		return _meshes[nom]
	var m: Dictionary = data().get("modeles", {}).get(nom, {})
	if m.is_empty():
		return null
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = m["v"]
	arr[Mesh.ARRAY_NORMAL] = m["n"]
	arr[Mesh.ARRAY_COLOR] = m["c"]
	arr[Mesh.ARRAY_INDEX] = m["i"]
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	_meshes[nom] = am
	return am


## Le matériau des petits cubes (la couleur est dans les sommets).
static func material() -> StandardMaterial3D:
	if _mat == null:
		_mat = make_material()
	return _mat


static func make_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.vertex_color_is_srgb = true
	m.roughness = 0.85
	m.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	return m


static func rig_data(bete: String) -> Dictionary:
	return data().get("rigs", {}).get(bete, {})


static func plantes() -> Dictionary:
	return data().get("plantes", {})


## Un objet simple (un rocher, un totem…) dans parent.
static func objet(parent: Node3D, nom: String, at: Vector3, yaw: float = 0.0, s: float = 1.0, mat: Material = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nom
	mi.mesh = mesh(nom)
	mi.material_override = mat if mat != null else material()
	parent.add_child(mi)
	mi.global_transform = Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3.ONE * s), at)
	return mi


## Une bête ou un habitant en pièces : renvoie {pièce: Node3D (l'articulation)} ; la racine est root.
static func rig(root: Node3D, bete: String, mat: Material = null) -> Dictionary:
	var r: Dictionary = rig_data(bete)
	var par: Dictionary = PARENTS.get(bete, {})
	if r.has("tronc"):
		par = {"tete": "tronc", "brasG": "tronc", "brasD": "tronc"}
	var nodes: Dictionary = {}
	var m: Material = mat if mat != null else material()
	# d'abord le corps (ou le tronc), puis les autres dans l'ordre des parents
	var order: Array = []
	for k in r:
		if str(k) == "taille":
			continue
		order.append(str(k))
	var done: Dictionary = {}
	var guard: int = 0
	while done.size() < order.size() and guard < 10:
		guard += 1
		for k in order:
			if done.has(k):
				continue
			var p: String = str(par.get(k, ""))
			if p != "" and not done.has(p):
				continue
			var j := Node3D.new()
			j.name = k
			var pos := Vector3(float(r[k][0]), float(r[k][1]), float(r[k][2]))
			if p != "":
				var pp: Array = r[p]
				pos -= Vector3(float(pp[0]), float(pp[1]), float(pp[2]))
				(nodes[p] as Node3D).add_child(j)
			else:
				root.add_child(j)
			j.position = pos
			j.set_meta("repos", pos)
			var mi := MeshInstance3D.new()
			mi.name = "Pixels"
			mi.mesh = mesh(bete + "." + k)
			mi.material_override = m
			j.add_child(mi)
			nodes[k] = j
			done[k] = true
	return nodes
