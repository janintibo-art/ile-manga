extends "res://scripts/pnj/pnj_lumen_v76.gd"
## V92 : un habitant de l'Île de Larsen. Même vie réglée par l'heure que les autres (et toutes les
## postures des îles d'avant : jouer de la guitare, de la basse, de la batterie, chanter, faire du
## skate, peindre — les bus —, méditer au bord de la mare, tisser…), avec en plus ce qui fait un
## habitant de Larsen (fiche « larsen ») : la couronne de fleurs des gens du Camp des Fleurs
## (tournesols, marguerites ou coquelicots), posée sur la vraie tête (repères V64). Le reste (la
## chemise à carreaux, le tie-dye, le jean troué, le bonnet) est cousu dans le corps (V64).

var _larsen: Dictionary = {}
var _couronne: Node3D


func setup_azur(manager: Node, data: Dictionary) -> void:
	super.setup_azur(manager, data)
	larsen_props(data.get("larsen", {}))


func larsen_props(lz: Dictionary) -> void:
	if skel == null or lz.is_empty() or not _larsen.is_empty():
		return
	_larsen = lz
	var kind: String = str(lz.get("couronne", ""))
	if kind == "":
		return
	_couronne = Node3D.new()
	_couronne.name = "Couronne_de_fleurs"
	var cols: Array
	match kind:
		"tournesol":
			cols = [Color(0.98, 0.78, 0.12), Color(1.0, 0.85, 0.2)]
		"coquelicots":
			cols = [Color(0.88, 0.12, 0.08), Color(0.95, 0.25, 0.15)]
		_:
			cols = [Color(0.97, 0.96, 0.92), Color(0.98, 0.95, 0.85)]
	var coeur := _mat(Color(0.95, 0.75, 0.15) if kind != "tournesol" else Color(0.3, 0.18, 0.06), 0.8)
	var feuille := _mat(Color(0.2, 0.42, 0.14), 0.8)
	var hw: float = 0.08
	var hd: float = 0.098
	var zc: float = 0.0
	var top: float = 0.12
	if not _tete64.is_empty():
		hw = float(_tete64.get("cote", 0.075)) + 0.012
		hd = (float(_tete64.get("avant", 0.1)) - float(_tete64.get("arriere", -0.09))) * 0.5 + 0.012
		zc = (float(_tete64.get("avant", 0.1)) + float(_tete64.get("arriere", -0.09))) * 0.5
		top = float(_tete64.get("haut", 0.14))
	# la tresse de tiges (un anneau vert), et les fleurs tout autour
	var band := TorusMesh.new()
	band.inner_radius = 0.94
	band.outer_radius = 1.06
	band.rings = 24
	band.ring_segments = 6
	_part(_couronne, band, feuille, Vector3.ZERO, Vector3(hw, hw * 0.9, hd))
	var n: int = 11
	for i in range(n):
		var a: float = TAU * float(i) / n
		var p := Vector3(cos(a) * hw, 0.006, sin(a) * hd)
		var fm := _mat(cols[i % cols.size()], 0.75)
		var fl := Node3D.new()
		fl.position = p
		_couronne.add_child(fl)
		var pr: float = 0.017 if kind != "tournesol" else 0.022
		for k in range(5):
			var b: float = TAU * float(k) / 5.0 + a
			_part(fl, _sphere(pr * 0.55), fm, Vector3(cos(b) * pr * 0.7, 0.004, sin(b) * pr * 0.7), Vector3(1.0, 0.35, 1.0))
		_part(fl, _sphere(pr * 0.42), coeur, Vector3(0, 0.008, 0), Vector3(1.0, 0.5, 1.0))
		if i % 2 == 0:
			_part(fl, _sphere(0.012), feuille, Vector3(cos(a + 0.4) * 0.012, -0.004, sin(a + 0.4) * 0.012), Vector3(1.6, 0.3, 0.7))
	var y: float = top - 0.035
	if not v64.is_empty():
		_attach("Head", Vector3(0, y * 100.0, zc * 100.0), _couronne, Vector3(-8, 0, 0), true)
	else:
		_attach("Head", Vector3(0, 18.0, 1.0), _couronne, Vector3(-8, 0, 0))
