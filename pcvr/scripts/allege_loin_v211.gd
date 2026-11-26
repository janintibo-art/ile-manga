extends Node
## V211 : le détail qui s'allège avec la distance, progressivement.
## Les grands maillages fabriqués par le jeu (le sol des îles, les villes, les falaises…) n'avaient
## qu'une seule version : une île à 2 km était dessinée triangle pour triangle comme si l'on
## marchait dessus. Ici, chaque gros maillage reçoit ses versions allégées (les mêmes sommets, de
## moins en moins de triangles, les bords gardés) ; c'est ensuite le moteur qui choisit, objet par
## objet et image par image, la version dont l'écart avec l'original reste sous un pixel à l'écran.
## Rien ne disparaît, rien ne change de près, et le passage se fait par paliers trop fins pour se
## voir. Le calcul se fait à part (un fil de travail), après le chargement, sans bloquer le jeu :
## les maillages reçoivent leurs paliers au fur et à mesure, dans la minute qui suit.

const MINI_TRIANGLES: int = 1500          # en dessous, ça ne vaut pas la peine
const ANGLE_FUSION: float = 25.0
const ANGLE_COUPE: float = 60.0
const BUDGET_US: int = 3000               # par image, pour recopier et poser (millionièmes de seconde)

var main: Node
var _maillages: Array = []                # les ArrayMesh à traiter (une fois chacun)
var _porteurs: Dictionary = {}            # id du maillage -> [MeshInstance3D…]
var _a_faire: Array = []                  # [maillage d'origine, atelier, triangles avant] : pour le fil
var _prets: Array = []                    # les mêmes, simplifiés par le fil
var _en_cours: int = 0
var _verrou := Mutex.new()
var _jeton := Semaphore.new()
var _fil: Thread
var _stop: bool = false
var faits: int = 0
var gagnes: int = 0                       # maillages qui ont vraiment reçu des paliers
var tri_avant: int = 0
var tri_loin: int = 0                     # les triangles de la version la plus légère
var ms_total: float = 0.0
var fini: bool = true
var _t0: int = 0


func setup(main_node: Node) -> void:
	main = main_node
	name = "Allege_loin_v211"
	process_mode = Node.PROCESS_MODE_ALWAYS


## Recense tous les gros maillages sous « racine » (à appeler quand le monde est construit)
func recenser(racine: Node) -> int:
	var pile: Array = [racine]
	while not pile.is_empty():
		var n: Node = pile.pop_back()
		for c in n.get_children():
			pile.append(c)
		if not (n is MeshInstance3D):
			continue
		var m: Mesh = (n as MeshInstance3D).mesh
		if not (m is ArrayMesh) or m.has_meta("allege_v211"):
			continue
		var id: int = m.get_instance_id()
		if _porteurs.has(id):
			(_porteurs[id] as Array).append(n)
			continue
		if triangles(m as ArrayMesh) < MINI_TRIANGLES or deja_paliers(m as ArrayMesh):
			continue
		_porteurs[id] = [n]
		_maillages.append(m)
	fini = _maillages.is_empty()
	return _maillages.size()


## Les modèles importés (ils viennent d'un fichier) ont déjà leurs paliers : on ne les refait pas.
## Ceux que le jeu fabrique lui-même n'ont pas de fichier.
static func deja_paliers(m: ArrayMesh) -> bool:
	return m.resource_path != ""


static func triangles(m: ArrayMesh) -> int:
	var total: int = 0
	for s in range(m.get_surface_count()):
		if m.surface_get_primitive_type(s) != Mesh.PRIMITIVE_TRIANGLES:
			continue
		var n: int = m.surface_get_array_index_len(s)
		if n <= 0:
			n = m.surface_get_array_len(s)
		total += n / 3
	return total


## Fabrique la version à paliers d'un maillage ; rend null s'il n'y a rien à gagner
static func alleger(m: ArrayMesh) -> ArrayMesh:
	var imp: ImporterMesh = preparer(m)
	if imp == null:
		return null
	imp.generate_lods(ANGLE_FUSION, ANGLE_COUPE, [])
	return conclure(m, imp)


## 1. (dans le jeu) recopie le maillage dans un atelier ; null si ce maillage n'est pas pour nous
static func preparer(m: ArrayMesh) -> ImporterMesh:
	if m.get_blend_shape_count() > 0:
		return null
	var imp := ImporterMesh.new()
	for s in range(m.get_surface_count()):
		if m.surface_get_primitive_type(s) != Mesh.PRIMITIVE_TRIANGLES:
			return null
		var format: int = m.surface_get_format(s)
		# les maillages qu'on réécrit en route, ceux qui ont un squelette : on n'y touche pas
		if format & (Mesh.ARRAY_FLAG_USE_DYNAMIC_UPDATE | Mesh.ARRAY_FORMAT_BONES):
			return null
		var arrays: Array = m.surface_get_arrays(s)
		if arrays.size() <= Mesh.ARRAY_INDEX or arrays[Mesh.ARRAY_INDEX] == null or arrays[Mesh.ARRAY_NORMAL] == null:
			return null
		imp.add_surface(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, m.surface_get_material(s), m.surface_get_name(s), format)
	if imp.get_surface_count() != m.get_surface_count():
		return null
	return imp


## 3. (dans le jeu) sort de l'atelier le maillage à paliers ; null s'il n'y a rien à gagner
static func conclure(m: ArrayMesh, imp: ImporterMesh) -> ArrayMesh:
	var paliers: int = 0
	var leger: int = 0
	for s2 in range(imp.get_surface_count()):
		var np: int = imp.get_surface_lod_count(s2)
		paliers += np
		if np > 0:
			leger += imp.get_surface_lod_indices(s2, np - 1).size() / 3
		else:
			leger += (imp.get_surface_arrays(s2)[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3
	if paliers == 0:
		return null
	var out: ArrayMesh = imp.get_mesh()
	if out == null or out.get_surface_count() != m.get_surface_count():
		return null
	out.resource_name = m.resource_name
	out.custom_aabb = m.custom_aabb
	out.set_meta("allege_v211", true)
	out.set_meta("leger_v211", leger)
	return out


## Pose un maillage allégé sur tous ceux qui portaient l'original
func _poser(m: ArrayMesh, neuf: ArrayMesh, avant: int) -> void:
	faits += 1
	tri_avant += avant
	if neuf == null:
		tri_loin += avant
		return
	gagnes += 1
	tri_loin += int(neuf.get_meta("leger_v211", avant))
	for mi in _porteurs.get(m.get_instance_id(), []):
		# entre-temps l'objet a pu disparaître, ou changer de maillage : on le laisse
		if is_instance_valid(mi) and (mi as MeshInstance3D).mesh == m:
			(mi as MeshInstance3D).mesh = neuf


## Le calcul à part (2.) : le fil ne fait que simplifier, dans son atelier ; il ne touche ni aux
## maillages du jeu ni à la scène. Recopier (1.) et poser (3.) se font ici, quelques-uns par image.
func demarrer() -> void:
	if _maillages.is_empty() or _fil != null:
		return
	fini = false
	_stop = false
	_t0 = Time.get_ticks_msec()
	_fil = Thread.new()
	_fil.start(_travail)


func _travail() -> void:
	while true:
		_jeton.wait()
		if _stop:
			return
		_verrou.lock()
		var tache: Array = _a_faire.pop_front() if not _a_faire.is_empty() else []
		_verrou.unlock()
		if tache.is_empty():
			continue
		(tache[1] as ImporterMesh).generate_lods(ANGLE_FUSION, ANGLE_COUPE, [])
		_verrou.lock()
		_prets.append(tache)
		_verrou.unlock()


func _process(_delta: float) -> void:
	if fini or _fil == null:
		return
	var t0: int = Time.get_ticks_usec()
	# 3. poser ce qui est prêt
	while Time.get_ticks_usec() - t0 < BUDGET_US:
		_verrou.lock()
		var r: Array = _prets.pop_front() if not _prets.is_empty() else []
		_verrou.unlock()
		if r.is_empty():
			break
		_en_cours -= 1
		_poser(r[0], conclure(r[0], r[1]), int(r[2]))
	# 1. préparer les suivants (le fil en a toujours quelques-uns d'avance)
	while not _maillages.is_empty() and _en_cours < 6 and Time.get_ticks_usec() - t0 < BUDGET_US:
		var m: ArrayMesh = _maillages.pop_back()
		var avant: int = triangles(m)
		var imp: ImporterMesh = preparer(m)
		if imp == null:
			_poser(m, null, avant)
			continue
		_en_cours += 1
		_verrou.lock()
		_a_faire.append([m, imp, avant])
		_verrou.unlock()
		_jeton.post()
	if _maillages.is_empty() and _en_cours == 0:
		_arreter()
		fini = true
		_porteurs.clear()
		ms_total = float(Time.get_ticks_msec() - _t0)
		print("ILE_MANGA_V211: détail allégé de loin : %d gros maillages, %d ont leurs paliers, de %d k à %d k triangles au plus léger, en %.0f s" % [faits, gagnes, tri_avant / 1000, tri_loin / 1000, ms_total / 1000.0])


func _arreter() -> void:
	if _fil != null:
		_stop = true
		_jeton.post()
		_fil.wait_to_finish()
		_fil = null


## Tout traiter sur place, d'un coup (les tests, les outils)
func tout() -> void:
	var t0: int = Time.get_ticks_msec()
	for m in _maillages:
		_poser(m, alleger(m as ArrayMesh), triangles(m as ArrayMesh))
	_maillages.clear()
	_porteurs.clear()
	ms_total = float(Time.get_ticks_msec() - t0)
	fini = true


func _exit_tree() -> void:
	_arreter()
