extends Node
## V192 : la portée des petites choses. La mesure de fluidité (tests/outils/photos_pc.gd) l'a montré : du
## Boulevard des Néons, en regardant vers le quai, le jeu dessinait tout l'archipel jusqu'au moindre banc,
## au moindre caillou, à plus d'un kilomètre : 16 000 pièces, 21 millions de triangles, 33 images/s sur une
## RTX 4070 (le processeur débordé : 11,5 ms pour préparer l'image, contre 1,2 ms ailleurs).
## La règle : un objet de moins de TAILLE_MAX m (sa boîte, en diagonale) n'est plus dessiné au-delà d'une
## distance qui grandit avec lui : PORTEE_MIN m + PAR_METRE m par mètre de taille, PORTEE_MAX m au plus.
## Une poubelle (1,3 m) : 300 m ; un banc (2,2 m) : 340 m ; une maison (12 m) : 730 m ; une tour de 25 m :
## 1 200 m. À ces distances, l'objet tient en quelques points de l'écran. Les grandes masses (les îles, les
## tours, les falaises, les châteaux, les lots fusionnés de Kit.Batch) restent visibles de partout.
## Ce qui a déjà sa propre portée (l'herbe, les fleurs, les arbres des îles…) n'est pas touché. Un objet peut
## y échapper : set_meta("portee_libre", true) avant de l'ajouter à la scène.
## Posé au début de main._ready : il voit passer tout ce qui est construit, au chargement et ensuite.

const TAILLE_MAX := 30.0
const PORTEE_MIN := 250.0
const PAR_METRE := 40.0
const PORTEE_MAX := 1200.0

var reglees: int = 0              # combien d'objets ont reçu une portée


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().node_added.connect(_ajoute)


func _ajoute(n: Node) -> void:
	if n is GeometryInstance3D:
		_regler.call_deferred(n)


## La distance au-delà de laquelle un objet de cette taille n'est plus dessiné (0 : toujours dessiné)
static func portee(taille: float) -> float:
	if taille <= 0.01 or taille >= TAILLE_MAX:
		return 0.0
	return clampf(PORTEE_MIN + PAR_METRE * taille, PORTEE_MIN, PORTEE_MAX)


func _regler(n: Node) -> void:
	if not is_instance_valid(n) or not n.is_inside_tree():
		return
	var g := n as GeometryInstance3D
	if g.visibility_range_end > 0.0 or g.visibility_range_begin > 0.0 or g.has_meta("portee_libre"):
		return
	var ab: AABB = g.get_aabb()
	if ab.size == Vector3.ZERO:
		return
	var s: Vector3 = g.global_transform.basis.get_scale()
	var p: float = portee((ab.size * s.abs()).length())
	if p <= 0.0:
		return
	g.visibility_range_end = p
	reglees += 1
