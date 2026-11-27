extends Node3D
## Extension « Le Château d'Ombrelac » (v18) : les créatures du château.
##  - Mistigri, le chat de l'Académie : le jour, il se promène dans la Cour d'Honneur ; le soir et la nuit,
##    il dort devant la cheminée de la Grande Salle. On le caresse (E) ; avec une sardine dans le sac, on
##    la lui donne, et une fois par jour il rapporte un petit cadeau ;
##  - Minerve, la chouette de l'Observatoire : le jour, elle dort sur la terrasse de la Tour de
##    l'Astrolabe ; la nuit, elle tourne autour de la tour, puis revient se poser. Posée, la nuit, on lui
##    parle (E) : une fois par nuit, elle laisse une plume ;
##  - les chauves-souris : la nuit, une nuée tourne autour du clocher de la Tour de l'Horloge ; d'autres
##    vivent toujours dans les caves de la Maison de Minuit ;
##  - Séraphine, le fantôme de la dernière préfète de la Maison de Minuit : la nuit, une dame pâle erre
##    sous les galeries du cloître. Gaspard Herse, le portier, l'a vue. Tant qu'on ne connaît pas la
##    Minuit, elle s'efface quand on approche ; après, on lui parle : « Le repos de Séraphine » (dans le
##    carnet, chez Gaspard) : retrouver la nuit son ruban (Salle Commune), sa plume d'argent (une table de
##    lecture de la Bibliothèque) et sa lanterne (Salle du Trésor des caves), et les lui rendre.
## Tout est dans ombrelac.state["creatures"] (enregistré avec la partie). Les objets (E) passent par
## objets_ombrelac.gd (ajouter) ; les sujets de Gaspard par les services que tiennent les quêtes.

const Societe = preload("res://scripts/pnj/societe_v65.gd")
const Animaux = preload("res://scripts/animaux_v75.gd")
## Mistigri : un tigré brun (le chat du jeu, animaux_v75.gd), le ventre et le menton crème
const MISTIGRI := {"taille": 0.95, "base": Color(0.46, 0.36, 0.25), "tigre": 0.9, "rayure": Color(0.14, 0.1, 0.06),
	"ventre": Color(0.82, 0.74, 0.6), "museau_c": Color(0.85, 0.78, 0.66), "museau_k": 0.6, "oeil": Color(0.62, 0.78, 0.22), "seed": 18}

## La Cour d'Honneur (repère château) : là où Mistigri se promène le jour
const COUR := Vector3(0.0, 0.0, 44.0)
const COUR_R := 11.0
## Devant la cheminée de la Grande Salle (Mère Fournil se tient à 24,6 ; le feu est à l'est)
const CHEMINEE := Vector3(25.5, 0.0, 5.1)
## La ronde de Séraphine : sous les galeries du cloître, à 2 m du mur
const RONDE := [Vector3(-16.0, 0.2, -35.0), Vector3(36.0, 0.2, -35.0), Vector3(36.0, 0.2, -11.0), Vector3(-16.0, 0.2, -11.0)]
## Le clocher de la Tour de l'Horloge (les chauves-souris tournent autour)
const CLOCHER := Vector3(36.0, 47.0, 34.0)
## La Tour de l'Astrolabe (Minerve tourne autour, la nuit)
const DONJON := Vector3(-44.0, 61.0, -26.0)
const CADEAUX := [["coquillage", 1, "un coquillage nacré"], ["plume_corbeau", 1, "une plume de corbeau"], ["piece", 3, "trois pièces de cuivre"],
	["champignon", 1, "un champignon des bois"], ["baies", 2, "des baies sauvages"], ["caillou", 1, "un joli caillou rond"]]
const SOUVENIRS := {
	"ruban": {"nom": "le ruban de Séraphine", "lieu": "la Salle Commune",
		"trouve": "Sur la table de l'échiquier, un ruban de velours couleur de nuit, brodé d'une petite lune d'argent. Il est froid comme la rosée. Le ruban de Séraphine."},
	"plume": {"nom": "la plume d'argent", "lieu": "la Bibliothèque",
		"trouve": "Sur une table de lecture, juste derrière Dame Reliure, une plume d'argent qui n'était pas là ce matin. Quand tu la prends, elle écrit toute seule un mot dans l'air : « merci »."},
	"lanterne": {"nom": "la lanterne de la Minuit", "lieu": "les caves de la Minuit",
		"trouve": "Dans la Salle du Trésor, près de la lettre, une petite lanterne de fer noir. Quand tu la soulèves, une flamme bleue s'allume toute seule à l'intérieur."},
}
## Les souvenirs sont posés sur des tables : leur objet (E) est compté au niveau du sol
const BAS := 0.75
const ETAPES := ["Parler à la dame pâle du cloître, la nuit", "Retrouver, la nuit, le ruban, la plume d'argent et la lanterne de Séraphine (%d / 3)",
	"Rendre ses souvenirs à Séraphine, la nuit, dans le cloître"]

var main: Node
var ombrelac: Node
var chateau: Node3D
var vie: Node
var objets: Node
var quetes: Node
var chat: Node3D
var chat_modele: Node3D                   # le chat du jeu (animaux_v75.gd), dans le nœud de Mistigri
var chouette: Node3D
var _plumes: Dictionary = {}
var _sphere: SphereMesh
var fantome: Node3D
var nuee: Node3D                          # les chauves-souris du clocher
var caves: Node3D                         # celles des caves
var souvenirs: Dictionary = {}            # id -> Node3D (la nuit, pendant la quête)
var _chat: Dictionary = {}                # {cible, etat, t, pas}
var _vol: Dictionary = {}                 # {etat : « posee » / « vole », t, a}
var _fant: Dictionary = {"i": 0, "f": 0.0, "alpha": 0.0, "fuit": 0.0}
var _places_ok: bool = false
var perchoir: Vector3
var _dit_fuite: int = -99
var _t: float = 0.0
var _rng := RandomNumberGenerator.new()
var fantome_mat: StandardMaterial3D
var fantome_mat2: StandardMaterial3D


# =================================================================== construire

func build(the_main: Node, the_ombrelac: Node, the_chateau: Node3D, the_vie: Node, the_objets: Node, the_quetes: Node) -> void:
	main = the_main
	ombrelac = the_ombrelac
	chateau = the_chateau
	vie = the_vie
	objets = the_objets
	quetes = the_quetes
	top_level = true
	_rng.randomize()
	chat = _chat_corps()
	chat.position = monde(COUR + Vector3(3.0, 0.12, -4.0))
	chouette = _chouette_corps()
	var lieux: Variant = chateau.get("lieux")
	var ter: Vector3 = Vector3(-44.0, 54.0, -17.9)
	if lieux is Dictionary and (lieux as Dictionary).has("terrasse_astrolabe"):
		ter = (lieux as Dictionary)["terrasse_astrolabe"]
	perchoir = monde(ter + Vector3(1.6, 0.0, 0.6))
	chouette.position = perchoir
	fantome = _fantome_corps()
	fantome.position = monde(RONDE[0])
	fantome.visible = false
	nuee = _nuee(12, monde(CLOCHER), 7.5, 3.0)
	nuee.visible = false
	caves = Node3D.new()
	caves.name = "Chauves_souris_caves"
	add_child(caves)
	var mn: Node = quetes.get("minuit") if quetes != null else null
	var fy: float = float(mn.FY) if mn != null else -100.0
	for c in [[Vector3(10.0, fy + 3.6, -23.0), 2.0], [Vector3(25.0, fy + 3.5, -24.0), 2.4]]:
		var n: Node3D = _nuee(4, monde(c[0]), float(c[1]), 0.6)
		n.reparent(caves, false)
	for id in SOUVENIRS:
		souvenirs[id] = _souvenir(str(id))
		(souvenirs[id] as Node3D).visible = false
	if quetes != null:
		quetes.set("creatures", self)
	_objets()
	_decor()


func _xf() -> Transform3D:
	return chateau.global_transform if chateau.is_inside_tree() else chateau.transform


func monde(p: Vector3) -> Vector3:
	return _xf() * p


func _mat(c: Color, e: float = 0.0, a: float = 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(c.r, c.g, c.b, a)
	m.roughness = 0.85
	if a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if e > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = e
	return m


func _boule(parent: Node3D, r: float, p: Vector3, m: Material, s: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	sm.radial_segments = 14
	sm.rings = 7
	var mi := MeshInstance3D.new()
	mi.mesh = sm
	mi.material_override = m
	mi.position = p
	mi.scale = s
	parent.add_child(mi)
	return mi


func _boite(parent: Node3D, sz: Vector3, p: Vector3, m: Material, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var bm := BoxMesh.new()
	bm.size = sz
	var mi := MeshInstance3D.new()
	mi.mesh = bm
	mi.material_override = m
	mi.position = p
	mi.rotation = rot
	parent.add_child(mi)
	return mi


## Mistigri : le chat du jeu (animaux_v75.gd, celui de Port-Boucan et de Brioche), en tigré brun
func _chat_corps() -> Node3D:
	var n := Node3D.new()
	n.name = "Mistigri"
	add_child(n)
	chat_modele = Animaux.build("chat", MISTIGRI)
	n.add_child(chat_modele)
	Animaux.animate(chat_modele, 0.0, 0.0, "assis", 0.0, 1.0)
	return n


## Une matière de plumes (celle des oiseaux du jeu), d'une couleur
func _plume(c: Color) -> StandardMaterial3D:
	var k: String = c.to_html(false)
	if _plumes.has(k):
		return _plumes[k]
	var m: StandardMaterial3D = (Animaux.feather_mat() as StandardMaterial3D).duplicate()
	m.vertex_color_use_as_albedo = false
	m.albedo_color = c
	m.roughness = 0.85
	_plumes[k] = m
	return m


func _piece(parent: Node3D, mesh: Mesh, m: Material, p: Vector3 = Vector3.ZERO, sc: Vector3 = Vector3.ONE, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = m
	mi.position = p
	mi.scale = sc
	mi.rotation = rot
	parent.add_child(mi)
	return mi


func _sphere_lisse() -> SphereMesh:
	if _sphere == null:
		_sphere = SphereMesh.new()
		_sphere.radius = 1.0
		_sphere.height = 2.0
		_sphere.radial_segments = 24
		_sphere.rings = 14
	return _sphere


## Minerve : une chouette hulotte (38 cm) : un corps en œuf, la grosse tête ronde sans aigrettes, le
## disque de la face, les grands yeux noirs, le bec crochu, les ailes repliées (ouvertes en vol)
func _chouette_corps() -> Node3D:
	var n := Node3D.new()
	n.name = "Minerve"
	add_child(n)
	var sp: SphereMesh = _sphere_lisse()
	var brun := _plume(Color(0.47, 0.32, 0.2))
	var fauve := _plume(Color(0.62, 0.45, 0.28))
	var ventre := _plume(Color(0.78, 0.64, 0.46))
	var disque := _plume(Color(0.72, 0.56, 0.38))
	var sombre := _plume(Color(0.3, 0.2, 0.12))
	var noir := _mat(Color(0.03, 0.025, 0.02))
	noir.roughness = 0.08
	noir.metallic_specular = 0.9
	var corne := _mat(Color(0.78, 0.74, 0.58))
	corne.roughness = 0.4
	var corps := Node3D.new()
	corps.name = "corps"
	n.add_child(corps)
	_piece(corps, sp, fauve, Vector3(0, 0.15, -0.01), Vector3(0.105, 0.145, 0.098))
	_piece(corps, sp, ventre, Vector3(0, 0.13, 0.035), Vector3(0.085, 0.12, 0.07))
	_piece(corps, sp, brun, Vector3(0, 0.2, -0.04), Vector3(0.09, 0.1, 0.07))
	# la queue, courte, et les pattes emplumées aux serres sombres
	_piece(corps, Animaux.tube([Vector3(0, 0.07, -0.07), Vector3(0, 0.03, -0.12), Vector3(0, 0.0, -0.15)], 0.045, 0.03, 6, 10), brun, Vector3.ZERO, Vector3(1.0, 0.45, 1.0))
	for sx in [-1.0, 1.0]:
		_piece(corps, sp, ventre, Vector3(sx * 0.035, 0.025, 0.04), Vector3(0.028, 0.03, 0.03))
		for k in range(3):
			var a: float = (float(k) - 1.0) * 0.45
			_piece(corps, Animaux.tube([Vector3(0, 0, 0), Vector3(0, -0.004, 0.018), Vector3(0, -0.014, 0.026)], 0.0045, 0.0015, 4, 6), sombre,
				Vector3(sx * 0.035 + sin(a) * 0.012, 0.012, 0.055), Vector3.ONE, Vector3(0, a, 0))
	# la tête
	var tete := Node3D.new()
	tete.name = "tete"
	n.add_child(tete)
	tete.position = Vector3(0, 0.29, 0.0)
	_piece(tete, sp, fauve, Vector3.ZERO, Vector3(0.09, 0.08, 0.085))
	_piece(tete, sp, brun, Vector3(0, 0.03, -0.015), Vector3(0.08, 0.05, 0.07))
	for sx in [-1.0, 1.0]:
		_piece(tete, sp, disque, Vector3(sx * 0.03, -0.004, 0.058), Vector3(0.042, 0.047, 0.024))
		_piece(tete, sp, sombre, Vector3(sx * 0.031, -0.002, 0.066), Vector3(0.024, 0.026, 0.012))
		var oeil := _piece(tete, sp, noir, Vector3(sx * 0.031, 0.0, 0.073), Vector3(0.017, 0.018, 0.01))
		oeil.name = "oeil"
		_piece(tete, sp, _mat(Color(1, 1, 1), 0.6), Vector3(sx * 0.034, 0.006, 0.081), Vector3.ONE * 0.003)
	# le sourcil clair en V, le bec crochu
	_piece(tete, sp, ventre, Vector3(0, 0.022, 0.068), Vector3(0.012, 0.03, 0.012), Vector3(0.4, 0, 0))
	_piece(tete, Animaux.tube([Vector3(0, -0.006, 0.072), Vector3(0, -0.018, 0.086), Vector3(0, -0.032, 0.083)], 0.009, 0.002, 6, 8), corne)
	# les ailes repliées le long des flancs
	var plie := Node3D.new()
	plie.name = "ailes_pliees"
	n.add_child(plie)
	for sx in [-1.0, 1.0]:
		var w := Node3D.new()
		plie.add_child(w)
		w.position = Vector3(sx * 0.085, 0.235, -0.01)
		w.scale = Vector3(0.5, 1.0, 1.0)
		_piece(w, Animaux.tube([Vector3.ZERO, Vector3(sx * 0.02, -0.09, -0.035), Vector3(-sx * 0.01, -0.19, -0.085), Vector3(-sx * 0.03, -0.24, -0.13)], 0.06, 0.02, 10, 12), brun)
	# les ailes ouvertes (en vol) : le bras, puis les rémiges en éventail
	for sx in [-1.0, 1.0]:
		var aile := Node3D.new()
		aile.name = "aile_g" if sx < 0 else "aile_d"
		n.add_child(aile)
		aile.position = Vector3(sx * 0.075, 0.22, -0.01)
		var bras := Node3D.new()
		aile.add_child(bras)
		bras.scale = Vector3(1.0, 0.2, 1.0)
		_piece(bras, Animaux.tube([Vector3.ZERO, Vector3(sx * 0.14, 0.01, -0.03), Vector3(sx * 0.3, 0.0, -0.05)], 0.085, 0.06, 8, 12), brun)
		for k in range(6):
			var b0 := Vector3(sx * (0.26 - float(k) * 0.01), 0.0, -0.01 - float(k) * 0.022)
			var b1 := Vector3(sx * (0.48 - float(k) * 0.035), -0.004, -0.04 - float(k) * 0.045)
			var f := _piece(aile, Animaux.tube([b0, (b0 + b1) * 0.5, b1], 0.03, 0.012, 5, 8), fauve if k % 2 == 0 else brun)
			f.scale = Vector3(1.0, 0.25, 1.0)
		aile.visible = false
	return n


## Séraphine : une dame pâle et lumineuse (la robe longue, le buste, la tête et son chignon, la lueur)
func _fantome_corps() -> Node3D:
	var n := Node3D.new()
	n.name = "Seraphine"
	add_child(n)
	fantome_mat = _mat(Color(0.75, 0.88, 1.0), 1.2, 0.5)
	fantome_mat2 = _mat(Color(0.88, 0.95, 1.0), 1.6, 0.55)
	var robe := CylinderMesh.new()
	robe.top_radius = 0.17
	robe.bottom_radius = 0.48
	robe.height = 1.15
	var r := MeshInstance3D.new()
	r.mesh = robe
	r.material_override = fantome_mat
	r.position = Vector3(0, 0.6, 0)
	r.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	n.add_child(r)
	_boule(n, 0.2, Vector3(0, 1.3, 0), fantome_mat, Vector3(1.0, 1.2, 0.75))
	_boule(n, 0.12, Vector3(0, 1.62, 0.0), fantome_mat2)
	_boule(n, 0.07, Vector3(0, 1.72, -0.08), fantome_mat2)
	for sx in [-1.0, 1.0]:
		_boite(n, Vector3(0.06, 0.55, 0.06), Vector3(0.2 * sx, 1.15, 0.06), fantome_mat, Vector3(0.35, 0, 0.18 * sx))
	var l := OmniLight3D.new()
	l.name = "lueur"
	l.light_color = Color(0.7, 0.85, 1.0)
	l.light_energy = 0.9
	l.omni_range = 4.0
	l.position = Vector3(0, 1.2, 0)
	l.shadow_enabled = false
	n.add_child(l)
	for c in n.get_children():
		if c is GeometryInstance3D:
			(c as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return n


## Une nuée de chauves-souris qui tournent autour d'un point (rayon r, hauteur ± h)
func _nuee(nb: int, c: Vector3, r: float, h: float) -> Node3D:
	var n := Node3D.new()
	n.name = "Nuee"
	add_child(n)
	n.position = c
	n.set_meta("r", r)
	n.set_meta("h", h)
	var noir := _mat(Color(0.2, 0.15, 0.16))
	var aile_m := _mat(Color(0.28, 0.2, 0.22))
	for i in range(nb):
		var b := Node3D.new()
		b.name = "chauve_souris_%d" % i
		n.add_child(b)
		b.set_meta("a", TAU * i / nb + _rng.randf() * 0.4)
		b.set_meta("v", _rng.randf_range(0.8, 1.4) * (1.0 if i % 3 != 0 else -1.0))
		b.set_meta("dy", _rng.randf_range(-1.0, 1.0))
		b.set_meta("dr", _rng.randf_range(0.75, 1.15))
		_boule(b, 0.06, Vector3.ZERO, noir, Vector3(1.0, 0.9, 1.4))
		for sx in [-1.0, 1.0]:
			var a := Node3D.new()
			a.name = "aile"
			b.add_child(a)
			_boite(a, Vector3(0.22, 0.01, 0.12), Vector3(0.11 * sx, 0, 0), aile_m)
			a.set_meta("s", sx)
	return n


## Un souvenir de Séraphine : il luit d'un bleu pâle, la nuit
func _souvenir(id: String) -> Node3D:
	var n := Node3D.new()
	n.name = "Souvenir_" + id
	add_child(n)
	var bleu := _mat(Color(0.65, 0.8, 1.0), 1.5)
	match id:
		"ruban":
			_boite(n, Vector3(0.32, 0.01, 0.05), Vector3(0, 0.01, 0), _mat(Color(0.12, 0.1, 0.3), 0.6), Vector3(0, 0.5, 0))
			_boule(n, 0.025, Vector3(0, 0.02, 0), bleu)
		"plume":
			_boite(n, Vector3(0.03, 0.01, 0.28), Vector3(0, 0.01, 0), _mat(Color(0.85, 0.88, 0.95), 1.2), Vector3(0, 0.6, 0))
		"lanterne":
			# une cage de fer noir, des vitres pâles, une petite flamme bleue qui dort
			var fer := _mat(Color(0.1, 0.1, 0.12))
			_boite(n, Vector3(0.16, 0.02, 0.16), Vector3(0, 0.01, 0), fer)
			_boite(n, Vector3(0.16, 0.02, 0.16), Vector3(0, 0.21, 0), fer)
			for cx in [-0.07, 0.07]:
				for cz in [-0.07, 0.07]:
					_boite(n, Vector3(0.018, 0.2, 0.018), Vector3(cx, 0.11, cz), fer)
			_boite(n, Vector3(0.13, 0.18, 0.13), Vector3(0, 0.11, 0), _mat(Color(0.7, 0.8, 0.95), 0.2, 0.3))
			_boule(n, 0.03, Vector3(0, 0.09, 0), _mat(Color(0.4, 0.6, 1.0), 3.0), Vector3(1.0, 1.6, 1.0))
			_boite(n, Vector3(0.05, 0.05, 0.05), Vector3(0, 0.245, 0), fer)
	var l := OmniLight3D.new()
	l.light_color = Color(0.6, 0.75, 1.0)
	l.light_energy = 0.6
	l.omni_range = 2.0
	l.position = Vector3(0, 0.25, 0)
	n.add_child(l)
	return n


## Les endroits qu'il faut trouver d'un rayon (le dessus des meubles) : la première fois qu'on a la physique
func _places() -> void:
	if _places_ok or not is_inside_tree():
		return
	_places_ok = true
	var ech: Dictionary = {}
	for o in objets.objets:
		if str(o.get("sorte", "")) == "echecs":
			ech = o
			break
	if not ech.is_empty():
		(souvenirs["ruban"] as Node3D).position = _dessus((ech["a"] as Vector3) + Vector3(0.3, 0, 0.15), 1.8)
	var sp: Dictionary = (vie.spots as Dictionary).get("biblio_comptoir", {}) if vie != null and vie.get("spots") != null else {}
	if not sp.is_empty():
		# sur la table de lecture derrière elle (repère monde : la Bibliothèque n'est pas tournée)
		(souvenirs["plume"] as Node3D).position = _dessus((sp["pos"] as Vector3) + Vector3(1.4, 0.0, -1.4), 1.8)
	var mn: Node = quetes.get("minuit") if quetes != null else null
	if mn != null:
		(souvenirs["lanterne"] as Node3D).position = _dessus(mn.monde(Vector3(22.5, mn.FY, -23.6)), 1.6)
	perchoir = _dessus(perchoir, 3.0)
	if str(_vol.get("etat", "posee")) == "posee":
		chouette.position = perchoir


## Le dessus de ce qui est sous p (un rayon de haut en bas, depuis p + h)
func _dessus(p: Vector3, h: float) -> Vector3:
	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(p + Vector3.UP * h, p + Vector3.DOWN * 1.0)
	var pc: Variant = main.get("pc_body") if main != null else null
	if pc != null:
		q.exclude = [(pc as CollisionObject3D).get_rid()]
	var r: Dictionary = space.intersect_ray(q)
	return (r["position"] as Vector3) + Vector3.UP * 0.005 if not r.is_empty() else p


# =================================================================== l'état (enregistré avec la partie)

func st() -> Dictionary:
	if ombrelac == null:
		return {}
	var s: Dictionary = ombrelac.state
	if not s.has("creatures") or not (s["creatures"] is Dictionary):
		s["creatures"] = {}
	var c: Dictionary = s["creatures"]
	if not c.has("souvenirs") or not (c["souvenirs"] is Array):
		c["souvenirs"] = []
	return c


## -1 : pas commencée ; 0 : parler à la dame pâle ; 1 : les souvenirs ; 2 : les rendre ; 3 : accomplie
func etape() -> int:
	return int(st().get("seraphine", -1))


func _fixer(e: int) -> void:
	st()["seraphine"] = e
	_decor()
	_sync()


func trouves() -> int:
	return (st()["souvenirs"] as Array).size()


# =================================================================== le jeu autour

func _dire(txt: String, s: float = 8.0) -> void:
	if objets != null and objets.has_method("say"):
		objets.say(txt, s)
	elif main != null and main.has_method("_show_message_v28"):
		main._show_message_v28(txt)


func _sfx(nom: String, at: Variant = null) -> void:
	if main != null and main.has_method("sfx"):
		main.sfx(nom, at)


func _heure() -> float:
	return float(objets.call("_heure")) if objets != null and objets.has_method("_heure") else 12.0


func _jour() -> int:
	return int(objets.call("_jour")) if objets != null and objets.has_method("_jour") else 0


func _nuit() -> bool:
	return objets.call("_nuit") if objets != null and objets.has_method("_nuit") else false


## La nuit en cours (une nuit compte du soir au matin)
func _nuit_n() -> int:
	return _jour() if _heure() >= 12.0 else _jour() - 1


func _joueur() -> Vector3:
	return main._player_pos_v27() if main != null and main.has_method("_player_pos_v27") else Vector3(0, -9999, 0)


func _inv() -> Node:
	return main.get("inventory_v28") if main != null else null


func _npc(id: String) -> Node:
	if vie == null or vie.get("by_id") == null:
		return null
	var n: Variant = (vie.by_id as Dictionary).get(id)
	return n if n != null and is_instance_valid(n) else null


func _minuit_connue() -> bool:
	return quetes != null and quetes.has_method("finie") and quetes.finie("minuit")


## Le chat dort-il à la Grande Salle (le soir et la nuit) ?
func chat_dedans() -> bool:
	var h: float = _heure()
	return h >= 19.0 or h < 6.5


func fantome_la() -> bool:
	return _nuit() and etape() < 3


# =================================================================== les objets (E)

func _objets() -> void:
	if objets == null or not objets.has_method("ajouter"):
		return
	var me = self
	objets.ajouter({"id": "chat", "a": chat.position, "portee": 1.1, "prio": 2.0,
		"verbe": func(): return me._verbe_chat(), "call": func(): me.caresser()})
	objets.ajouter({"id": "chouette", "a": chouette.position, "portee": 1.4, "prio": 2.0,
		"si": func(): return str(me._vol.get("etat", "posee")) == "posee",
		"verbe": func(): return "parler à Minerve, la chouette" if me._nuit() else "regarder Minerve, la chouette (elle dort)",
		"call": func(): me.parler_chouette()})
	objets.ajouter({"id": "seraphine", "a": fantome.position, "portee": 2.2, "prio": 3.0,
		"si": func(): return me.fantome_la() and me._minuit_connue() and me._fant["alpha"] > 0.3,
		"verbe": "parler à la dame pâle", "call": func(): me.parler_fantome()})
	for id in SOUVENIRS:
		var sid: String = str(id)
		objets.ajouter({"id": "souvenir_" + sid, "a": (souvenirs[sid] as Node3D).position - Vector3.UP * BAS, "portee": 1.3, "prio": 2.5,
			"si": func(): return me._souvenir_la(sid),
			"verbe": "prendre " + str(SOUVENIRS[sid]["nom"]), "call": func(): me.prendre(sid)})


func _verbe_chat() -> String:
	var inv: Node = _inv()
	if inv != null and int(inv.count("sardine")) > 0 and int(st().get("chat_jour", -99)) != _jour():
		return "donner une sardine à Mistigri"
	return "caresser Mistigri" if not chat_dedans() else "caresser Mistigri (il dort)"


func _souvenir_la(id: String) -> bool:
	return etape() == 1 and _nuit() and not (st()["souvenirs"] as Array).has(id)


## La position des objets qui bougent (le chat, la chouette, la dame pâle), à chaque image
func _suivre_objets() -> void:
	if objets == null or not objets.has_method("objet"):
		return
	for e in [["chat", chat], ["chouette", chouette], ["seraphine", fantome]]:
		var o: Dictionary = objets.objet(str(e[0]))
		if not o.is_empty():
			o["a"] = (e[1] as Node3D).position
			o["b"] = o["a"]
	for id in SOUVENIRS:
		var o2: Dictionary = objets.objet("souvenir_" + str(id))
		if not o2.is_empty():
			o2["a"] = (souvenirs[id] as Node3D).position - Vector3.UP * BAS
			o2["b"] = o2["a"]


func caresser() -> void:
	var c: Dictionary = st()
	c["caresses"] = int(c.get("caresses", 0)) + 1
	var inv: Node = _inv()
	if inv != null and int(inv.count("sardine")) > 0 and int(c.get("chat_jour", -99)) != _jour():
		var cad: Array = CADEAUX[(_jour() + int(c["caresses"])) % CADEAUX.size()]
		if inv.has_method("can_accept") and not bool(inv.can_accept([[cad[0], cad[1]]], [["sardine", 1]])):
			_dire("Mistigri renifle la sardine… mais ton sac est trop plein pour ce qu'il voudrait te rapporter. Fais un peu de place !", 5.0)
			return
		inv.remove("sardine", 1)
		inv.add(str(cad[0]), int(cad[1]))
		c["chat_jour"] = _jour()
		_chat["etat"] = "assis"
		_chat["t"] = 0.0
		if main != null and main.has_method("_show_message_v28"):
			main._show_message_v28("+ " + str(inv.ITEMS[str(cad[0])]["name"]) + ("" if int(cad[1]) == 1 else " ×%d" % int(cad[1])))
		_dire("Mistigri croque la sardine en trois bouchées, se lèche les moustaches… puis file sous un banc et revient avec %s, qu'il pose fièrement à tes pieds. Un cadeau ! (Un par jour.)" % str(cad[2]), 7.0)
		_sfx("ui_quete")
		return
	if chat_dedans():
		_dire(["Mistigri dort en boule devant la cheminée. Quand tu le caresses, il ronronne sans ouvrir les yeux. Rrrrr…", "Mistigri s'étire, te regarde d'un œil, et se rendort. Le feu crépite. Rrrrr…"][int(c["caresses"]) % 2], 5.0)
	else:
		_chat["etat"] = "assis"
		_chat["t"] = 0.0
		_dire(["Mistigri se frotte contre tes jambes et ronronne. Rrrrr… Il a l'air d'aimer les sardines, dit-on.", "Mistigri fait le dos rond sous ta main. Rrrrr… Puis il repart, la queue bien droite.", "Mistigri s'assoit et te regarde, très digne. C'est lui, le vrai maître de la cour."][int(c["caresses"]) % 3], 5.0)


func parler_chouette() -> void:
	if not _nuit():
		_dire("Minerve dort, perchée sur la terrasse, une patte repliée sous les plumes. Un œil s'entrouvre… et se referme. Elle chasse la nuit : reviens quand les étoiles seront levées.", 6.0)
		return
	var c: Dictionary = st()
	var inv: Node = _inv()
	if int(c.get("chouette_nuit", -99)) != _nuit_n() and inv != null:
		if int(inv.count("chouette_plume")) == 0 and (not inv.has_method("can_accept") or bool(inv.can_accept([["chouette_plume", 1]]))):
			inv.add("chouette_plume", 1)
			c["chouette_nuit"] = _nuit_n()
			if main != null and main.has_method("_show_message_v28"):
				main._show_message_v28("+ " + str(inv.ITEMS["chouette_plume"]["name"]))
			_dire("« Hou-hou. » Minerve tourne la tête presque à l'envers, te fixe de ses grands yeux noirs… et une plume se détache de son aile. Elle te la laisse. Un cadeau de chouette, une fois par nuit.", 7.0)
			return
	_dire("« Hou-hou. » Minerve te regarde sans cligner. Puis elle tourne la tête vers le lac, très loin, comme pour te montrer quelque chose que toi, tu ne vois pas.", 6.0)


func parler_fantome() -> void:
	if not fantome_la():
		return
	match etape():
		-1, 0:
			_fixer(1)
			_sfx("ui_quete")
			_dire("La dame pâle s'arrête et te regarde. Sa voix est un souffle : « Tu as trouvé la Maison de Minuit… Je suis Séraphine, la dernière préfète. J'ai fermé la porte, il y a deux cents ans, et je n'ai jamais pu partir. Il me manque trois souvenirs : mon ruban, dans la Salle Commune ; ma plume d'argent, à la Bibliothèque ; ma lanterne, en bas, dans la Salle du Trésor. On ne les voit que la nuit. Rapporte-les-moi, et je pourrai enfin me reposer. »  (Carnet : %s.)" % _objectif(), 16.0)
		1:
			_dire("Séraphine murmure : « Mon ruban, dans la Salle Commune ; ma plume d'argent, à la Bibliothèque ; ma lanterne, dans la Salle du Trésor… On ne les voit que la nuit. »  (%d / 3)" % trouves(), 8.0)
		2:
			var inv: Node = _inv()
			var gives: Array = [["lanterne_fee", 1], ["piece_or", 5]]
			if inv != null and inv.has_method("can_accept") and not bool(inv.can_accept(gives)):
				_dire("Séraphine sourit : « Fais un peu de place dans ton sac, voyageur. Je voudrais te laisser quelque chose. »", 6.0)
				return
			if inv != null:
				for g in gives:
					inv.add(str(g[0]), int(g[1]))
			_fixer(3)
			var pr: Variant = main.get("progression_v63") if main != null else null
			var xp: String = ""
			if pr != null and pr.has_method("quest_xp"):
				xp = "  (+%d XP)" % int(pr.quest_xp("om_seraphine", 3))
			if pr != null and pr.has_method("on_quest"):
				pr.on_quest("om_seraphine", 3)
			if main != null and main.has_method("_show_message_v28"):
				main._show_message_v28("Quête accomplie : Le repos de Séraphine" + xp)
			if main != null and main.has_method("jingle"):
				main.jingle("victoire")
			var j: Variant = main.get("journal_v56") if main != null else null
			var now: float = float(j._now()) if j != null and j.has_method("_now") else 0.0
			Societe.noter("quete", "herse_om", now, {"titre": "Le repos de Séraphine"})
			_partir()
			_dire("Tu tends le ruban, la plume et la lanterne. Séraphine les prend un à un ; ils deviennent aussi pâles qu'elle. « Merci. La Maison de Minuit veillera sans moi, maintenant. Garde cette lanterne de fée : elle éclaire ceux qui marchent la nuit. Et ces pièces : les dernières de notre trésor. » Elle sourit… et s'efface en une pluie de petites lumières bleues, qui montent vers les étoiles.", 16.0)


func prendre(id: String) -> void:
	if not _souvenir_la(id):
		return
	(st()["souvenirs"] as Array).append(id)
	(souvenirs[id] as Node3D).visible = false
	_sfx("ui_quete", (souvenirs[id] as Node3D).position)
	var fin: String = ""
	if trouves() >= SOUVENIRS.size():
		_fixer(2)
		fin = "  Les trois souvenirs ! Séraphine t'attend dans le cloître, la nuit."
	else:
		_sync()
		fin = "  (%d / 3)" % trouves()
	_dire(str(SOUVENIRS[id]["trouve"]) + fin, 9.0)


## Séraphine s'en va : une pluie de lumières bleues
func _partir() -> void:
	if fantome == null or not fantome.is_inside_tree():
		return
	for i in range(14):
		var p := _boule(self, 0.04, fantome.position + Vector3(_rng.randf_range(-0.4, 0.4), _rng.randf_range(0.2, 1.7), _rng.randf_range(-0.4, 0.4)), _mat(Color(0.7, 0.85, 1.0), 3.0, 0.9))
		var tw := create_tween()
		tw.tween_property(p, "position", p.position + Vector3(_rng.randf_range(-0.6, 0.6), _rng.randf_range(3.0, 6.0), _rng.randf_range(-0.6, 0.6)), _rng.randf_range(2.0, 3.5))
		tw.tween_callback(p.queue_free)


# =================================================================== le carnet (chez Gaspard Herse)

func _objectif() -> String:
	var e: int = etape()
	if e < 0 or e >= ETAPES.size():
		return "Le repos de Séraphine"
	var t: String = str(ETAPES[e])
	return t % trouves() if t.contains("%d") else t


func _sync() -> void:
	var n: Node = _npc("herse_om")
	if n == null or not (n.get("profile") is Dictionary) or n.get("brain") == null:
		return
	var pr: Dictionary = n.profile
	var e: int = etape()
	# tant que la Minuit n'est pas trouvée, Gaspard n'a qu'une rumeur (pas de quête au carnet)
	if e < 0 and not _minuit_connue():
		pr.erase("quete")
		n.brain.memoire["quete"] = ""
		return
	pr["quete"] = {"sujet": "Le repos de Séraphine", "objets": {_objectif(): 1}, "note": "m'a parlé de la dame pâle du cloître",
		"souvenir": "Et la dame pâle ne revient plus. Ma moustache en frémit encore.", "affinite": 0.0}
	var rep: Dictionary = pr.get("repliques", {})
	var rap: Array = ["Elle erre sous les galeries du cloître, la nuit. Parlez-lui doucement : elle a l'air si triste.",
		"Un ruban, une plume d'argent, une lanterne… On ne les voit que la nuit, dites-vous ? Ma ronde passe par la Salle Commune et la Bibliothèque. Je n'ai jamais rien vu. Mais je n'ai pas vos yeux.",
		"Vous avez ses trois souvenirs ? Alors allez la trouver, cette nuit, dans le cloître."]
	rep["quete_manque"] = [{"t": str(rap[clampi(e, 0, rap.size() - 1)]), "si": {}}]
	rep["quete_fin"] = [{"t": "Elle ne revient plus, la dame pâle. Je crois qu'elle est heureuse, maintenant. Ma moustache aussi.", "si": {}}]
	pr["repliques"] = rep
	n.brain.memoire["quete"] = "" if e < 0 else ("finie" if e >= 3 else "demandee")


func _id(action: String) -> String:
	return "q56:service:omk_" + action


func sujets(npc: Node) -> Array:
	var out: Array = []
	if str(npc.profile.get("id", "")) != "herse_om":
		return out
	if etape() < 0:
		out.append({"id": _id("fantome"), "label": "★ On dit qu'une dame pâle erre la nuit dans le cloître ?"})
	return out


func choisir(npc: Node, quoi: String) -> Dictionary:
	match quoi:
		"fantome":
			if etape() >= 0:
				return {}
			if not _minuit_connue():
				return {"texte": "Vous l'avez vue aussi ? Une dame pâle, la nuit, sous les galeries du cloître. Pendant ma ronde, je l'aperçois, mais dès que j'approche, pfft ! Elle s'efface. Elle a une petite lune d'argent sur sa robe… comme sur la bannière d'une vieille maison de l'Académie dont plus personne ne parle. Anatole, lui, en parle. Il en parle même beaucoup.", "geste": "parle"}
			_fixer(0)
			return {"texte": "Vous l'avez vue aussi ? Une dame pâle, la nuit, sous les galeries du cloître, avec une petite lune d'argent sur sa robe. La lune de la Maison de Minuit ! Et vous, vous avez trouvé la Minuit… Alors peut-être qu'elle ne s'effacera pas devant vous. Allez lui parler, cette nuit. Doucement. Et revenez me raconter.", "geste": "parle"}
	return {}


# =================================================================== chaque image

func _decor() -> void:
	var e: int = etape()
	for id in SOUVENIRS:
		(souvenirs[id] as Node3D).visible = e == 1 and _nuit() and not (st()["souvenirs"] as Array).has(id)
	if e >= 3 and fantome != null:
		fantome.visible = false


func _process(delta: float) -> void:
	if main == null:
		return
	_places()
	var tt: float = Time.get_ticks_msec() * 0.001
	_chat_tick(delta, tt)
	_chouette_tick(delta, tt)
	_chauves_souris_tick(delta, tt)
	_fantome_tick(delta, tt)
	_suivre_objets()
	_t += delta
	if _t < 0.5:
		return
	_t = 0.0
	_decor()
	_sync()


## Mistigri : il marche d'un point à l'autre de la cour, s'assoit, repart ; le soir, il dort au coin du feu
func _chat_tick(delta: float, tt: float) -> void:
	var j: Vector3 = _joueur()
	var dedans: bool = chat_dedans()
	var ou: Vector3 = monde(CHEMINEE) if dedans else monde(COUR)
	# il change de lieu quand personne ne le voit (loin du joueur)
	if chat.position.distance_to(ou) > COUR_R + 4.0 and chat.position.distance_to(j) > 18.0 and ou.distance_to(j) > 12.0:
		chat.position = _dessus(ou + (Vector3(0.0, 0.0, 0.0) if dedans else Vector3(_rng.randf_range(-6, 6), 0, _rng.randf_range(-6, 6))), 1.5)
		_chat = {"etat": "dort" if dedans else "assis", "t": 0.0}
	var etat: String = str(_chat.get("etat", "assis"))
	_chat["t"] = float(_chat.get("t", 0.0)) + delta
	if dedans and chat.position.distance_to(ou) < 3.0:
		etat = "dort"
		_chat["etat"] = "dort"
	var vitesse: float = 0.0
	var pose: String = "assis"
	match etat:
		"dort":
			pose = "dort"
			if not dedans:
				_chat["etat"] = "assis"
		"assis":
			if float(_chat["t"]) > 4.0 and not dedans:
				_cible_chat()
		"marche":
			pose = ""
			var cible: Vector3 = _chat["cible"]
			var d: Vector3 = cible - chat.position
			d.y = 0.0
			if d.length() < 0.15 or float(_chat["t"]) > 20.0:
				_chat = {"etat": "assis", "t": 0.0}
			else:
				var v: Vector3 = d.normalized()
				vitesse = 0.7
				chat.position += v * minf(vitesse * delta, d.length())
				chat.position.y = lerpf(chat.position.y, cible.y, 0.1)
				chat.rotation.y = lerp_angle(chat.rotation.y, atan2(v.x, v.z), 0.15)
	# le chat du jeu : la marche, assis (la queue autour des pattes), couché en rond pour dormir
	Animaux.animate(chat_modele, tt, vitesse, pose, 0.0, delta)


func _cible_chat() -> void:
	var c: Vector3 = monde(COUR)
	for k in range(6):
		var a: float = _rng.randf() * TAU
		var p: Vector3 = c + Vector3(cos(a), 0, sin(a)) * _rng.randf_range(2.0, COUR_R)
		var sol: Vector3 = _dessus(p, 1.5)
		if absf(sol.y - c.y) > 0.6:
			continue
		var space := get_world_3d().direct_space_state
		var q := PhysicsRayQueryParameters3D.create(chat.position + Vector3.UP * 0.25, sol + Vector3.UP * 0.25)
		var pc: Variant = main.get("pc_body") if main != null else null
		if pc != null:
			q.exclude = [(pc as CollisionObject3D).get_rid()]
		if space.intersect_ray(q).is_empty():
			_chat = {"etat": "marche", "t": 0.0, "cible": sol}
			return
	_chat = {"etat": "assis", "t": 0.0}


## Minerve : posée le jour (elle dort) ; la nuit, elle part tourner autour de la tour et revient
func _chouette_tick(delta: float, tt: float) -> void:
	var etat: String = str(_vol.get("etat", "posee"))
	_vol["t"] = float(_vol.get("t", 0.0)) + delta
	var ag: Node3D = chouette.get_node("aile_g")
	var ad: Node3D = chouette.get_node("aile_d")
	var tete: Node3D = chouette.get_node("tete")
	var plie: Node3D = chouette.get_node("ailes_pliees")
	var c: Vector3 = monde(DONJON)
	match etat:
		"posee":
			chouette.position = chouette.position.lerp(perchoir, 0.2)
			ag.visible = false
			ad.visible = false
			plie.visible = true
			tete.rotation.y = 0.8 * sin(tt * 0.4) if _nuit() else 0.0
			tete.scale = Vector3.ONE
			# la nuit, elle repart de temps en temps (sauf si on est tout près d'elle)
			if _nuit() and float(_vol["t"]) > 25.0 and chouette.position.distance_to(_joueur()) > 3.0:
				var dp: Vector3 = perchoir - c
				_vol = {"etat": "vole", "t": 0.0, "a": atan2(dp.z, dp.x)}
		"vole":
			var a: float = float(_vol["a"]) + delta * 0.35
			_vol["a"] = a
			var r: float = 16.0
			var p: Vector3 = c + Vector3(cos(a) * r, 2.0 * sin(a * 2.0), sin(a) * r)
			var dvol: Vector3 = Vector3(-sin(a), 0, cos(a))
			var fin: bool = float(_vol["t"]) > 40.0 or not _nuit()
			if fin:
				p = chouette.position.move_toward(perchoir, delta * 6.0)
				dvol = (perchoir - chouette.position)
				dvol.y = 0.0
				if chouette.position.distance_to(perchoir) < 0.3:
					_vol = {"etat": "posee", "t": 0.0}
			else:
				p = chouette.position.lerp(p, 0.05)
			chouette.position = p
			if dvol.length() > 0.01:
				chouette.rotation.y = lerp_angle(chouette.rotation.y, atan2(dvol.x, dvol.z), 0.1)
			# en vol : les grandes ailes ouvertes, de lents battements, puis un plané
			ag.visible = true
			ad.visible = true
			plie.visible = false
			var b: float = 0.55 * sin(tt * 5.5) if fmod(tt, 4.0) < 2.4 else 0.08
			ag.rotation.z = b
			ad.rotation.z = -b


## Les chauves-souris : la nuit autour du clocher ; toujours dans les caves
func _chauves_souris_tick(_delta: float, tt: float) -> void:
	nuee.visible = _nuit()
	for n in [nuee, caves]:
		if not (n as Node3D).visible:
			continue
		var groupes: Array = [n] if n == nuee else (n as Node3D).get_children()
		for g in groupes:
			var r: float = float(g.get_meta("r", 2.0))
			var h: float = float(g.get_meta("h", 0.5))
			for b in (g as Node3D).get_children():
				var a: float = float(b.get_meta("a")) + tt * float(b.get_meta("v"))
				var rr: float = r * float(b.get_meta("dr"))
				(b as Node3D).position = Vector3(cos(a) * rr, h * sin(tt * 1.3 + float(b.get_meta("dy")) * 3.0) * float(b.get_meta("dy")), sin(a) * rr)
				var v: float = float(b.get_meta("v"))
				(b as Node3D).rotation.y = -a + (0.0 if v > 0 else PI)
				for w in (b as Node3D).get_children():
					if w.has_meta("s"):
						(w as Node3D).rotation.z = float(w.get_meta("s")) * 0.8 * sin(tt * 18.0 + float(b.get_meta("dy")) * 5.0)


## Séraphine : la nuit, elle fait le tour des galeries ; elle s'efface si on approche (tant qu'on ne
## connaît pas la Minuit), et s'arrête pour nous écouter (après)
func _fantome_tick(delta: float, tt: float) -> void:
	var la: bool = fantome_la()
	var cible_alpha: float = 1.0 if la else 0.0
	var j: Vector3 = _joueur()
	var pres: bool = fantome.position.distance_to(j) < 4.5
	if la and pres and not _minuit_connue():
		cible_alpha = 0.0
		if _dit_fuite != _nuit_n():
			_dit_fuite = _nuit_n()
			_dire("Une silhouette pâle, sous les arcades… Quand tu t'approches, elle s'efface comme une buée sur une vitre. Gaspard, le portier, en saurait peut-être plus.", 7.0)
	_fant["alpha"] = move_toward(float(_fant["alpha"]), cible_alpha, delta * 0.8)
	var al: float = float(_fant["alpha"])
	fantome.visible = al > 0.02 and etape() < 3
	fantome_mat.albedo_color.a = 0.5 * al
	fantome_mat2.albedo_color.a = 0.55 * al
	(fantome.get_node("lueur") as OmniLight3D).light_energy = 0.9 * al
	if not la:
		return
	# elle avance le long des galeries (sauf si on lui parle, tout près)
	var arret: bool = pres and _minuit_connue()
	if not arret:
		var i: int = int(_fant["i"])
		var a: Vector3 = monde(RONDE[i])
		var b: Vector3 = monde(RONDE[(i + 1) % RONDE.size()])
		var lg: float = a.distance_to(b)
		_fant["f"] = float(_fant["f"]) + delta * 0.45 / maxf(lg, 0.1)
		if float(_fant["f"]) >= 1.0:
			_fant["f"] = 0.0
			_fant["i"] = (i + 1) % RONDE.size()
		var p: Vector3 = a.lerp(b, float(_fant["f"]))
		fantome.position = p + Vector3.UP * (0.12 + 0.06 * sin(tt * 1.4))
		var d: Vector3 = b - a
		fantome.rotation.y = lerp_angle(fantome.rotation.y, atan2(d.x, d.z), 0.05)
	else:
		var vj: Vector3 = j - fantome.position
		fantome.rotation.y = lerp_angle(fantome.rotation.y, atan2(vj.x, vj.z), 0.05)
		fantome.position.y = fantome.position.y + 0.0006 * sin(tt * 1.4)


## Pour les tests et les photos : mettre la dame pâle devant un point de sa ronde
func placer_fantome(i: int, f: float = 0.5) -> void:
	_fant["i"] = i % RONDE.size()
	_fant["f"] = f
	var a: Vector3 = monde(RONDE[_fant["i"]])
	var b: Vector3 = monde(RONDE[(int(_fant["i"]) + 1) % RONDE.size()])
	fantome.position = a.lerp(b, f) + Vector3.UP * 0.12


func apres_chargement() -> void:
	_decor()
	_sync()
