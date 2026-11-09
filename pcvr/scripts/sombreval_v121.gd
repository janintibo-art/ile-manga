extends Node3D
## V121 : Sombreval, la ville morte, tout au sud de l'archipel. Une grande ville abandonnée : ses
## immeubles crevés, leurs fenêtres noires, les toits effondrés, les carcasses de voitures et
## d'autobus, les réverbères tordus, les barricades de sacs de sable… et la nature qui a tout
## repris (des arbres au milieu des rues, l'herbe haute, le lierre jusqu'aux toits). Une brume
## gris-vert, une lumière blafarde, l'orage qui gronde au loin.
## Les quartiers : le Port des Brumes (au nord, où l'on accoste), la Place du Marché et son vieux
## beffroi (l'horloge arrêtée à minuit), la Vieille Ville (la brique), le Centre (les grands
## immeubles autour de la Butte), le Quartier de la Gare (à l'est), les Faubourgs (au sud), le
## Vieux Cimetière (au sud-est), et la grève grise tout autour.
## Au centre, la Butte du Comte : une colline de roche noire, une route pavée qui monte en
## spirale, et le château du comte Dracula (ses remparts, ses tours aux toits d'ardoise, le grand
## donjon aux fenêtres rouges, les chauves-souris). Sa grande porte est fermée… pour l'instant.
## Les morts-vivants (monstre_v121) rôdent partout : par petits groupes dans les rues, couchés
## par terre comme morts, et parfois… juste derrière toi. C'est le comte qui les tient sous son
## pouvoir. Cinq pages du journal du docteur Vasseur, dispersées dans la ville, racontent ce qui
## s'est passé.

const IleScript = preload("res://scripts/ile_sombreval_v121.gd")
const Kit = preload("res://scripts/sombreval_kit_v121.gd")
const Public = preload("res://scripts/public_v111.gd")
const FLORE := "res://scripts/sombreval_flore_v121.gd"

const Y0: float = IleScript.Y0
const TOP: float = IleScript.TOP
const PLACES := {"port": "le Port des Brumes", "marche": "la Place du Marché", "vieille_ville": "la Vieille Ville",
	"centre": "le Centre", "gare": "le Quartier de la Gare", "faubourg": "les Faubourgs", "cimetiere": "le Vieux Cimetière",
	"butte": "la Butte du Comte", "chateau": "le château du comte", "greve": "la grève", "ville": "la ville"}
const MESSAGES := {
	"marche": "La Place du Marché — le vieux beffroi, son horloge arrêtée à minuit… et pas un bruit",
	"vieille_ville": "La Vieille Ville — des rues de brique, des volets arrachés, du lierre jusqu'aux toits",
	"centre": "Le Centre — les grands immeubles crevés tout autour de la Butte du Comte",
	"gare": "Le Quartier de la Gare — l'horloge de la gare, des wagons rouillés… plus aucun train ne viendra",
	"faubourg": "Les Faubourgs — des petites maisons, des jardins devenus forêts",
	"cimetiere": "Le Vieux Cimetière — des tombes penchées, de la brume… et la terre est fraîchement retournée",
	"butte": "La Butte du Comte — la route pavée monte en tournant jusqu'au château. Tout là-haut, des fenêtres rouges.",
}
## Les quartiers des îlots particuliers (i, j de -4 à 3) ; les autres : voir _district()
const ILOTS := {"-1,-3": "marche", "2,2": "cimetiere", "2,-1": "gare"}
## Les cinq pages du journal du docteur Vasseur : [id, position (repère île), texte]
const NOTES := [
	["n1", Vector2(9.0, -214.0), "Journal du docteur Vasseur, page 1 — « Le brouillard est arrivé avec lui, il y a trois hivers. Un comte, disait-on, venu de très loin, qui avait acheté le vieux château de la Butte. Le premier soir, toutes les horloges de la ville se sont arrêtées à minuit. »"],
	["n2", Vector2(-24.0, -122.0), "Journal du docteur Vasseur, page 2 — « Les gens ont commencé à disparaître. Puis ils sont revenus… mais ce n'étaient plus eux. La peau grise, les yeux vides. Ils ne parlent plus. Ils grognent. Ils marchent toute la nuit vers le château, comme appelés. »"],
	["n3", Vector2(125.0, -20.0), "Journal du docteur Vasseur, page 3 — « J'ai compris : ce sont ses pantins. Le comte les tient par sa seule volonté, depuis son donjon. Le soir, ses fenêtres rougeoient, et ils se mettent tous à marcher en même temps. »"],
	["n4", Vector2(132.0, 140.0), "Journal du docteur Vasseur, page 4 — « Ceux qui ont résisté, il les a fait enfermer sous le château, dans les vieux souterrains. Je les entends parfois, quand le vent tombe : ils appellent à l'aide. Il garde la clé sur lui. »"],
	["n5", Vector2(-8.0, -104.0), "Journal du docteur Vasseur, dernière page — « Si le comte tombe, ses pantins s'endormiront pour toujours. Mais il faudra d'abord passer ses enfants, les vampires… Moi, je n'ai plus la force. Que celui qui lira ces lignes ait plus de courage que moi. »"],
]
## Les groupes de morts-vivants : [id, centre (repère île), rayon de réveil, [[sorte, x, z, couché]]]
const HORDES := [
	["port_ouest", Vector2(-60.0, -200.0), 55.0, [["zombie", -64, -196, false], ["zombie", -56, -204, false], ["zombie", -70, -208, true]]],
	["port_est", Vector2(70.0, -205.0), 55.0, [["zombie", 66, -200, false], ["zombie", 75, -210, false], ["zombie_coureur", 85, -198, false]]],
	["marche", Vector2(-25.0, -125.0), 50.0, [["zombie", -30, -118, true], ["zombie", -18, -130, false], ["zombie", -36, -132, false], ["zombie", -12, -116, true]]],
	["avenue_nord", Vector2(0.0, -160.0), 50.0, [["zombie", 2, -165, false], ["zombie", -3, -150, false]]],
	["vieille_n", Vector2(-125.0, -90.0), 55.0, [["zombie", -120, -100, false], ["zombie", -130, -95, false], ["zombie", -110, -75, true], ["zombie_coureur", -140, -80, false]]],
	["vieille_s", Vector2(-125.0, 60.0), 55.0, [["zombie", -125, 50, false], ["zombie", -118, 62, false], ["zombie_lourd", -132, 70, false], ["zombie", -110, 75, true]]],
	["centre_o", Vector2(-100.0, -10.0), 50.0, [["zombie", -100, -2, false], ["zombie", -98, -18, false], ["zombie", -104, 6, true]]],
	["centre_e", Vector2(100.0, 10.0), 50.0, [["zombie", 100, 2, false], ["zombie", 96, 16, false], ["zombie_coureur", 104, -8, false]]],
	["gare", Vector2(125.0, -25.0), 50.0, [["zombie", 120, -30, false], ["zombie", 130, -18, true], ["zombie", 115, -12, false], ["zombie_lourd", 135, -35, false]]],
	["gare_n", Vector2(130.0, -110.0), 55.0, [["zombie", 125, -100, false], ["zombie", 138, -115, false], ["zombie_coureur", 120, -125, false]]],
	["faubourg_o", Vector2(-70.0, 150.0), 55.0, [["zombie", -75, 150, false], ["zombie", -60, 140, true], ["zombie", -85, 160, false]]],
	["faubourg_e", Vector2(60.0, 160.0), 55.0, [["zombie", 55, 155, false], ["zombie_coureur", 70, 165, false], ["zombie", 50, 170, true]]],
	["cimetiere", Vector2(125.0, 125.0), 45.0, [["zombie", 115, 115, true], ["zombie", 122, 128, true], ["zombie", 132, 118, true], ["zombie", 128, 136, true], ["zombie", 116, 135, true], ["zombie_lourd", 136, 130, true]]],
	["butte_n", Vector2(0.0, -95.0), 45.0, [["zombie", 6, -100, false], ["zombie", -8, -97, true], ["zombie", 12, -92, false]]],
	["butte_e", Vector2(80.0, 25.0), 45.0, [["zombie", 78, 30, false], ["zombie", 84, 18, false]]],
	["butte_s", Vector2(10.0, 75.0), 45.0, [["zombie_coureur", 12, 72, false], ["zombie", 4, 78, false], ["zombie", 18, 70, true]]],
	["butte_o", Vector2(-55.0, -10.0), 40.0, [["zombie_lourd", -52, -6, false], ["zombie", -56, 4, false], ["zombie", -58, -16, false]]],
	["ceinture_o", Vector2(-175.0, -20.0), 50.0, [["zombie", -176, -24, false], ["zombie", -178, -10, false]]],
	["ceinture_e", Vector2(175.0, 60.0), 50.0, [["zombie", 176, 56, false], ["zombie_coureur", 178, 70, false]]],
]
const MAX_ZOMBIES: int = 16
const REVIENT_S: float = 240.0

var main: Node
var ile: Node3D
var flore: Node3D
var pc: bool = true
var state: Dictionary = {}
var objets: Dictionary = {}
var batiments: Array = []                 # {"rect": [x0, z0, x1, z1] (île), "h", "quartier"}
var tree_spots: Array = []
var nb_boites: int = 0
var ruine_mat: ShaderMaterial
var porte_chateau := Vector3.ZERO
var _cols: StaticBody3D
var _rng := RandomNumberGenerator.new()
var _xfs: Array = []
var _customs: Array = []
var _blocked: Dictionary = {}             # cellules de 2 m (repère île) occupées (les immeubles, le château)
var _ivy: Array = []                      # Transform3D des rideaux de lierre
var _interactions: Array = []
var _registered: bool = false
var _hordes: Dictionary = {}              # id -> {"monstres": [], "vide_t": float}
var _clock: float = 0.0
var _zone_t: float = 0.0
var _hordes_t: float = 0.0
var _peur_t: float = 40.0
var _coeur_t: float = 0.0
var _eclair_t: float = 25.0
var _eclair: DirectionalLight3D
var _eclair_seq: Array = []
var _tonnerre_t: float = -1.0
var _brume: CPUParticles3D
var _bats: Array = []                     # [Node3D, rayon, vitesse, phase, hauteur]
var _wing_l: Array = []
var _castle_lights: Array = []            # [OmniLight3D, énergie]
var _derriere: Array = []                 # les zombies « dans le dos » : [monstre, déjà senti]
var _cloche_h: int = -1
var _note_mi: Dictionary = {}
var sombre: float = 0.0


func setup(main_node: Node) -> void:
	main = main_node
	pc = OS.has_feature("ile_manga_pc")
	_rng.seed = 12121
	state = _fresh_state()


func _fresh_state() -> Dictionary:
	return {"visite": false, "visites": {}, "notes": {}, "vaincus": 0, "porte": false, "beffroi": false, "cimetiere": false}


# =================================================================== construction

func build_island() -> void:
	ile = IleScript.new()
	ile.name = "Ile_sombreval_v121"
	add_child(ile)
	ile.build(pc)


func dock() -> Array:
	return [IleScript.W(IleScript.DOCK_A.x, IleScript.DOCK_A.y), IleScript.W(IleScript.DOCK_B.x, IleScript.DOCK_B.y)]


func build_town() -> void:
	var t0: int = Time.get_ticks_msec()
	ruine_mat = ShaderMaterial.new()
	ruine_mat.shader = load("res://shaders/ruine_v121.gdshader")
	var texs := {"brique_tex": "res://assets/textures/boucan/brique.png", "brique_n": "res://assets/textures/boucan/brique_n.png",
		"beton_tex": "res://assets/textures/boucan/beton_brut.png", "beton_n": "res://assets/textures/boucan/beton_brut_n.png",
		"feuilles_tex": "res://assets/textures/flora/leaves.png", "bois_tex": "res://assets/textures/doors/wood_plain.png"}
	for k in texs:
		if ResourceLoader.exists(texs[k]):
			ruine_mat.set_shader_parameter(k, load(texs[k]))
	ruine_mat.set_shader_parameter("sol_y", Y0)
	_block_castle()
	_layout()
	_maisons_cote()
	_place_marche()
	_cimetiere()
	_gare()
	_port()
	_rues()
	_chateau()
	_ruines_mm()
	_lierre()
	_traces()
	_notes()
	_atmosphere()
	objets["port"] = _ground(0.0, -232.0)
	objets["marche"] = _ground(-26.0, -112.0)
	objets["cimetiere"] = _ground(118.0, 104.0)
	objets["gare"] = _ground(125.0, -2.0)
	objets["butte"] = _ground(0.0, -95.0)
	objets["chateau"] = porte_chateau
	if ResourceLoader.exists(FLORE):
		flore = load(FLORE).new()
		flore.name = "Flore_sombreval_v121"
		add_child(flore)
		for c in _blocked:
			flore._blocked[c] = true
		flore.build_sombreval(ile, pc, {"arbres": tree_spots})
	print("ILE_MANGA_V121: Sombreval est prête (%d immeubles, %d boîtes, %d ms)" % [batiments.size(), nb_boites, Time.get_ticks_msec() - t0])


func _ground(x: float, z: float) -> Vector3:
	var w: Vector3 = IleScript.W(x, z)
	w.y = ile.height(w.x, w.z)
	return w


func _col(xf: Transform3D, size: Vector3) -> void:
	if _cols == null:
		_cols = StaticBody3D.new()
		_cols.name = "Sombreval_collisions_v121"
		_cols.collision_layer = 1
		_cols.collision_mask = 0
		add_child(_cols)
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	_cols.add_child(cs)
	cs.global_transform = xf


func _block(x0: float, z0: float, x1: float, z1: float) -> void:
	for xi in range(int(floor(x0 / 2.0)), int(ceil(x1 / 2.0))):
		for zi in range(int(floor(z0 / 2.0)), int(ceil(z1 / 2.0))):
			_blocked[Vector2i(xi, zi)] = true


func _block_castle() -> void:
	var r: float = IleScript.HILL_R0 - 4.0
	_block(-r, -r, r, r)


## Une boîte de ruine (repère île ; du bas y0 au haut y1) ; mat : 0 brique, 0,5 béton, 1 enduit
func _boite(c: Vector3, s: Vector3, yaw: float, mat: float, ivy: float, tint: float, col: bool = true) -> void:
	var xf := Transform3D(Basis(Vector3.UP, yaw).scaled(s), c)
	_xfs.append(xf)
	_customs.append(Color(_rng.randf(), mat, ivy, tint))
	if col:
		_col(Transform3D(Basis(Vector3.UP, yaw), c), s)
	nb_boites += 1


func _boite_rect(x0: float, z0: float, x1: float, z1: float, y0: float, y1: float, mat: float, ivy: float, tint: float) -> void:
	_boite(IleScript.W((x0 + x1) * 0.5, (z0 + z1) * 0.5, (y0 + y1) * 0.5), Vector3(x1 - x0, y1 - y0, z1 - z0), 0.0, mat, ivy, tint)


## Le quartier d'un îlot
func _district(i: int, j: int) -> String:
	var k: String = "%d,%d" % [i, j]
	if ILOTS.has(k):
		return str(ILOTS[k])
	if j <= -4 or (j == -3 and absf(i + 0.5) > 1.0):
		return "port"
	if i <= -3:
		return "vieille_ville"
	if i >= 2:
		return "gare"
	if j >= 2:
		return "faubourg"
	return "centre"


# =================================================================== les immeubles en ruine

var _det: Kit.Batch


func _layout() -> void:
	_det = Kit.Batch.new()
	for i in range(-4, 4):
		for j in range(-4, 4):
			var q: String = _district(i, j)
			if ILOTS.has("%d,%d" % [i, j]):
				continue
			var r: Array = IleScript.block_rect(i, j)
			if float(r[2]) - float(r[0]) < 6.0 or float(r[3]) - float(r[1]) < 6.0:
				continue
			var lots: Array = _perimeter_lots(r, 13.0 if q != "port" else 18.0)
			for lot in lots:
				var lr: Array = lot[0]
				if _in_hill(lr):
					continue
				var floors: int
				match q:
					"port":
						floors = _rng.randi_range(2, 4)
					"vieille_ville":
						floors = _rng.randi_range(3, 5)
					"faubourg":
						floors = _rng.randi_range(2, 3)
					"gare":
						floors = _rng.randi_range(4, 7)
					_:
						var dc: float = Vector2((float(lr[0]) + float(lr[2])) * 0.5, (float(lr[1]) + float(lr[3])) * 0.5).length()
						floors = clampi(int(lerpf(10.0, 5.0, clampf((dc - 100.0) / 80.0, 0.0, 1.0))) + _rng.randi_range(-1, 1), 4, 10)
				_lot(lr, floors, q, lot[1])
			# la cour au milieu de l'îlot : un arbre ou deux
			var cx: float = (float(r[0]) + float(r[2])) * 0.5
			var cz: float = (float(r[1]) + float(r[3])) * 0.5
			if Vector2(cx, cz).length() > IleScript.HILL_R1 + 6.0 and float(r[2]) - float(r[0]) > 28.0:
				for k in range(_rng.randi_range(1, 2)):
					var tp: Vector3 = _ground(cx + _rng.randf_range(-3.0, 3.0), cz + _rng.randf_range(-3.0, 3.0))
					tree_spots.append(tp)
	_det.commit(self, "Sombreval_details_ruines", true, 260.0)


func _in_hill(lr: Array) -> bool:
	for c in [Vector2(lr[0], lr[1]), Vector2(lr[2], lr[1]), Vector2(lr[0], lr[3]), Vector2(lr[2], lr[3])]:
		if (c as Vector2).length() < IleScript.HILL_R1 + 3.0:
			return true
		if ile.coast_q((c as Vector2).x, (c as Vector2).y) > 0.97:
			return true
	return false


## Les parcelles le long des quatre rues d'un îlot (une cour au milieu) : [[rect], normale vers la rue]
func _perimeter_lots(r: Array, depth: float) -> Array:
	var x0: float = r[0]
	var z0: float = r[1]
	var x1: float = r[2]
	var z1: float = r[3]
	var out: Array = []
	var d: float = minf(depth, minf(x1 - x0, z1 - z0) * 0.5)
	# nord et sud (sur toute la largeur)
	for side in [[z0, z0 + d, Vector2(0, -1)], [z1 - d, z1, Vector2(0, 1)]]:
		var x: float = x0
		while x < x1 - 4.0:
			var w: float = minf(_rng.randf_range(8.0, 15.0), x1 - x)
			if x1 - (x + w) < 5.0:
				w = x1 - x
			out.append([[x, side[0], x + w, side[1]], side[2]])
			x += w
	# est et ouest (entre les deux)
	for side2 in [[x0, x0 + d, Vector2(-1, 0)], [x1 - d, x1, Vector2(1, 0)]]:
		var z: float = z0 + d
		while z < z1 - d - 4.0:
			var w2: float = minf(_rng.randf_range(8.0, 15.0), z1 - d - z)
			if z1 - d - (z + w2) < 5.0:
				w2 = z1 - d - z
			out.append([[side2[0], z, side2[1], z + w2], side2[2]])
			z += w2
	return out


## Un immeuble (ou ce qu'il en reste) sur une parcelle
func _lot(r: Array, floors: int, q: String, face: Vector2) -> void:
	var x0: float = float(r[0]) + 0.3
	var z0: float = float(r[1]) + 0.3
	var x1: float = float(r[2]) - 0.3
	var z1: float = float(r[3]) - 0.3
	var w: float = x1 - x0
	var dpt: float = z1 - z0
	if w < 3.0 or dpt < 3.0:
		return
	var cx: float = (x0 + x1) * 0.5
	var cz: float = (z0 + z1) * 0.5
	var roll: float = _rng.randf()
	var mat: float = 0.5
	match q:
		"vieille_ville":
			mat = 0.0 if _rng.randf() < 0.75 else 1.0
		"faubourg":
			mat = 1.0 if _rng.randf() < 0.7 else 0.0
		"port":
			mat = 0.5 if _rng.randf() < 0.6 else 0.0
		_:
			mat = [0.5, 0.5, 1.0, 0.0][_rng.randi() % 4]
	var ivy: float = _rng.randf_range(0.0, 0.6) + (0.3 if q == "faubourg" else 0.0)
	var tint: float = _rng.randf()
	if roll < 0.09:
		# effondré : un grand tas de gravats, des pans de murs
		Kit.rubble(_det, _ground(cx, cz), minf(w, dpt) * 0.45, _rng)
		_col(Transform3D(Basis(), IleScript.W(cx, cz, Y0 + 0.6)), Vector3(w * 0.7, 1.6, dpt * 0.7))
		var hw: float = _rng.randf_range(1.5, 5.0)
		if absf(face.x) > 0.5:
			var xe: float = x0 if face.x < 0.0 else x1 - 0.5
			_boite_rect(xe, z0, xe + 0.5, z0 + dpt * _rng.randf_range(0.4, 0.9), Y0 - 1.0, Y0 + hw, mat, ivy, tint)
		else:
			var ze: float = z0 if face.y < 0.0 else z1 - 0.5
			_boite_rect(x0, ze, x0 + w * _rng.randf_range(0.4, 0.9), ze + 0.5, Y0 - 1.0, Y0 + hw, mat, ivy, tint)
		_block(x0, z0, x1, z1)
		batiments.append({"rect": [x0, z0, x1, z1], "h": hw, "quartier": q, "ruine": "effondre"})
		return
	if roll < 0.15:
		# un terrain vague : des arbres, des gravats
		tree_spots.append(_ground(cx + _rng.randf_range(-2.0, 2.0), cz + _rng.randf_range(-2.0, 2.0)))
		if _rng.randf() < 0.5:
			Kit.rubble(_det, _ground(cx + _rng.randf_range(-3.0, 3.0), cz + _rng.randf_range(-3.0, 3.0)), 1.6, _rng)
		return
	_block(x0, z0, x1, z1)
	var hf: float = floors * 3.2 + 0.4
	var keep: int = maxi(1, floors - (_rng.randi_range(0, 2) if _rng.randf() < 0.7 else 0))
	var hm: float = keep * 3.2 + 0.4
	# V122 : près d'un immeuble sur deux, le rez-de-chaussée est ouvert : on y entre par la porte
	# défoncée (une pièce sombre, des meubles renversés, des gravats ; parfois une bougie)
	var ouvert: bool = w >= 6.0 and dpt >= 6.0 and _rng.randf() < 0.5
	if ouvert:
		_rez_ouvert(x0, z0, x1, z1, face, mat, ivy, tint)
		_boite_rect(x0, z0, x1, z1, Y0 + 3.3, Y0 + hm, mat, ivy, tint)
	else:
		_boite_rect(x0, z0, x1, z1, Y0 - 1.0, Y0 + hm, mat, ivy, tint)
	batiments.append({"rect": [x0, z0, x1, z1], "h": hm, "quartier": q, "ruine": "casse" if keep < floors else "entier", "ouvert": ouvert})
	var top: float = Y0 + hm
	if keep < floors:
		# le haut est cassé : des pans de façade, un coin de poteau, une dalle qui pend
		var hmax: float = hf - hm
		if absf(face.y) > 0.5:
			var ze2: float = z0 if face.y < 0.0 else z1 - 0.45
			var a: float = _rng.randf_range(0.0, 0.4)
			var b: float = _rng.randf_range(0.55, 1.0)
			_boite_rect(x0 + w * a, ze2, x0 + w * b, ze2 + 0.45, top - 0.2, top + _rng.randf_range(0.4, 1.0) * hmax, mat, ivy, tint)
		else:
			var xe2: float = x0 if face.x < 0.0 else x1 - 0.45
			var a2: float = _rng.randf_range(0.0, 0.4)
			var b2: float = _rng.randf_range(0.55, 1.0)
			_boite_rect(xe2, z0 + dpt * a2, xe2 + 0.45, z0 + dpt * b2, top - 0.2, top + _rng.randf_range(0.4, 1.0) * hmax, mat, ivy, tint)
		var corner := Vector2(x0 if _rng.randf() < 0.5 else x1 - 0.7, z0 if _rng.randf() < 0.5 else z1 - 0.7)
		_boite_rect(corner.x, corner.y, corner.x + 0.7, corner.y + 0.7, top - 0.2, top + hmax * _rng.randf_range(0.6, 1.0), mat, ivy * 0.5, tint)
		# une dalle d'étage qui dépasse, penchée
		if _rng.randf() < 0.55:
			var fc: Vector3 = IleScript.W(cx + face.x * (w * 0.5 + 0.4), cz + face.y * (dpt * 0.5 + 0.4), top + 0.1)
			var along: float = atan2(face.x, face.y)
			var tilt := Basis(Vector3.UP, along) * Basis(Vector3.RIGHT, _rng.randf_range(0.05, 0.3))
			var sz := Vector3(minf(w, dpt) * 0.6, 0.25, 2.2)
			_xfs.append(Transform3D(tilt.scaled(sz), fc))
			_customs.append(Color(_rng.randf(), 0.5, 0.0, tint))
			nb_boites += 1
		# des fers à béton tordus
		for k in range(_rng.randi_range(2, 5)):
			var rp: Vector3 = IleScript.W(_rng.randf_range(x0 + 0.5, x1 - 0.5), _rng.randf_range(z0 + 0.5, z1 - 0.5), top)
			_det.tube("rouille", rp, rp + Vector3(_rng.randf_range(-0.5, 0.5), _rng.randf_range(0.8, 2.0), _rng.randf_range(-0.5, 0.5)), 0.025, 4)
		Kit.rubble(_det, IleScript.W(cx, cz, top), minf(w, dpt) * 0.3, _rng)
	else:
		# le toit : une petite cabane d'escalier, une citerne rouillée
		if w > 8.0 and dpt > 8.0 and _rng.randf() < 0.6:
			_boite_rect(cx - 1.5, cz - 1.5, cx + 1.5, cz + 1.5, top, top + 2.6, mat, ivy, tint)
		if _rng.randf() < 0.35:
			_det.cyl_at("rouille", IleScript.W(cx + w * 0.25, cz - dpt * 0.2, top), 1.0, 1.0, 1.8, 10)
		if _rng.randf() < 0.3:
			tree_spots.append(IleScript.W(cx - w * 0.2, cz + dpt * 0.2, top))
	# des fenêtres du bas murées de planches, une porte d'entrée défoncée : seulement des détails
	if _rng.randf() < 0.25 and q != "port" and not ouvert:
		var bp: Vector3 = IleScript.W(cx + face.x * (w * 0.5 + 0.06), cz + face.y * (dpt * 0.5 + 0.06), Y0)
		_det.box("bois_pourri", Transform3D(Basis(Vector3.UP, atan2(face.x, face.y)), bp + Vector3.UP * 1.2), Vector3(1.4, 2.2, 0.06))
	# du lierre qui pend du haut de la façade sur la rue
	if _rng.randf() < 0.45 + ivy * 0.4:
		for k2 in range(_rng.randi_range(1, 3)):
			var along2: float = _rng.randf_range(-0.4, 0.4)
			if ouvert and absf(along2) < 0.25:
				along2 = 0.3 if along2 >= 0.0 else -0.3
			var p: Vector3
			if absf(face.y) > 0.5:
				p = IleScript.W(cx + along2 * w, cz + face.y * (dpt * 0.5 + 0.08), 0.0)
			else:
				p = IleScript.W(cx + face.x * (w * 0.5 + 0.08), cz + along2 * dpt, 0.0)
			var hh: float = _rng.randf_range(3.0, minf(hm, 14.0))
			var ww: float = _rng.randf_range(1.6, 4.5)
			var y_top: float = Y0 + hm if _rng.randf() < 0.6 else Y0 + hh
			p.y = y_top - hh * 0.5
			_ivy.append(Transform3D(Basis(Vector3.UP, atan2(face.x, face.y)).scaled(Vector3(ww, hh, 1.0)), p))


## V122 : un rez-de-chaussée ouvert (repère île) : quatre murs, la porte défoncée sur la rue (et
## parfois une autre sur la cour), le plafond porté par l'étage ; dedans, le désordre d'une
## maison abandonnée en hâte.
const MUR_EP: float = 0.35
const PORTE_L: float = 1.8
const PORTE_H: float = 2.5
const PLAFOND: float = 3.3
var portes: Array = []                    # V122 : le seuil des rez-de-chaussée ouverts (monde)
var _bougies: int = 0

func _rez_ouvert(x0: float, z0: float, x1: float, z1: float, face: Vector2, mat: float, ivy: float, tint: float) -> void:
	var yb: float = Y0 - 1.0
	var yt: float = Y0 + PLAFOND
	var t: float = MUR_EP
	var back: bool = _rng.randf() < 0.5
	# le lierre ne pousse pas dedans : les murs du rez-de-chaussée en ont peu
	ivy *= 0.2
	# les murs le long de x (nord, sud) puis le long de z (ouest, est) ; ouverts sur la rue (face)
	for side in [-1, 1]:
		var zf: float = z0 if side < 0 else z1 - t
		var porte_z: bool = (absf(face.y) > 0.5 and int(signf(face.y)) == side) or (back and absf(face.y) > 0.5 and int(signf(face.y)) == -side)
		if porte_z:
			var dc: float = (x0 + x1) * 0.5 + (_rng.randf_range(-1.0, 1.0) if int(signf(face.y)) != side else 0.0)
			_boite_rect(x0, zf, dc - PORTE_L * 0.5, zf + t, yb, yt, mat, ivy, tint)
			_boite_rect(dc + PORTE_L * 0.5, zf, x1, zf + t, yb, yt, mat, ivy, tint)
			_boite_rect(dc - PORTE_L * 0.5, zf, dc + PORTE_L * 0.5, zf + t, Y0 + PORTE_H, yt, mat, ivy * 0.5, tint)
			portes.append(IleScript.W(dc, zf + t * 0.5 + side * 0.8, ile.height(IleScript.W(dc, zf).x, IleScript.W(dc, zf).z)))
		else:
			_boite_rect(x0, zf, x1, zf + t, yb, yt, mat, ivy, tint)
	for side2 in [-1, 1]:
		var xf: float = x0 if side2 < 0 else x1 - t
		var porte_x: bool = (absf(face.x) > 0.5 and int(signf(face.x)) == side2) or (back and absf(face.x) > 0.5 and int(signf(face.x)) == -side2)
		if porte_x:
			var dc2: float = (z0 + z1) * 0.5 + (_rng.randf_range(-1.0, 1.0) if int(signf(face.x)) != side2 else 0.0)
			_boite_rect(xf, z0 + t, xf + t, dc2 - PORTE_L * 0.5, yb, yt, mat, ivy, tint)
			_boite_rect(xf, dc2 + PORTE_L * 0.5, xf + t, z1 - t, yb, yt, mat, ivy, tint)
			_boite_rect(xf, dc2 - PORTE_L * 0.5, xf + t, dc2 + PORTE_L * 0.5, Y0 + PORTE_H, yt, mat, ivy * 0.5, tint)
			portes.append(IleScript.W(xf + t * 0.5 + side2 * 0.8, dc2, ile.height(IleScript.W(xf, dc2).x, IleScript.W(xf, dc2).z)))
		else:
			_boite_rect(xf, z0 + t, xf + t, z1 - t, yb, yt, mat, ivy, tint)
	# le chambranle arraché qui pend, la porte elle-même par terre
	var cx: float = (x0 + x1) * 0.5
	var cz: float = (z0 + z1) * 0.5
	var fw: Vector3 = IleScript.W(cx + face.x * ((x1 - x0) * 0.5 - 1.4), cz + face.y * ((z1 - z0) * 0.5 - 1.4), 0.0)
	fw.y = ile.height(fw.x, fw.z) + 0.05
	_det.box("bois_pourri", Transform3D(Basis(Vector3.UP, atan2(face.x, face.y) + _rng.randf_range(-0.5, 0.5)), fw), Vector3(0.95, 0.06, 2.05))
	# dedans : le sol couvert de carreaux cassés et de plâtre tombé du plafond
	var ix0: float = x0 + t + 0.2
	var iz0: float = z0 + t + 0.2
	var ix1: float = x1 - t - 0.2
	var iz1: float = z1 - t - 0.2
	# le sol de béton poussiéreux, posé sur le relief (il le suit : on ne s'y enfonce pas), troué par endroits
	var fx0: float = x0 + t
	var fz0: float = z0 + t
	var nx: int = maxi(1, int(ceil((x1 - t - fx0) / 1.2)))
	var nz: int = maxi(1, int(ceil((z1 - t - fz0) / 1.2)))
	var sx: float = (x1 - t - fx0) / nx
	var sz: float = (z1 - t - fz0) / nz
	for a in range(nx):
		for b in range(nz):
			if _rng.randf() < 0.12:
				continue
			var cs: Array = []
			var uvs: Array = []
			for c in [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]:
				var wv: Vector3 = IleScript.W(fx0 + (a + c.x) * sx, fz0 + (b + c.y) * sz, 0.0)
				wv.y = ile.height(wv.x, wv.z) + 0.025
				cs.append(wv)
				uvs.append(Vector2(wv.x, wv.z) * 0.35)
			_det.quad("beton", cs, Vector3.UP, uvs)
	for k in range(int((ix1 - ix0) * (iz1 - iz0) / 6.0)):
		var px: float = _rng.randf_range(ix0, ix1)
		var pz: float = _rng.randf_range(iz0, iz1)
		var g: Vector3 = _ground(px, pz)
		_det.box("beton_clair" if _rng.randf() < 0.6 else "beton", Transform3D(Basis(Vector3.UP, _rng.randf() * TAU) * Basis(Vector3.RIGHT, _rng.randf_range(-0.08, 0.08)), g + Vector3.UP * 0.045), Vector3(_rng.randf_range(0.3, 1.1), 0.03, _rng.randf_range(0.3, 0.9)))
	# un tas de gravats dans un coin (le plafond s'est ouvert au-dessus)
	var corner := Vector2(ix0 + 1.0 if _rng.randf() < 0.5 else ix1 - 1.0, iz0 + 1.0 if _rng.randf() < 0.5 else iz1 - 1.0)
	Kit.rubble(_det, _ground(corner.x, corner.y), _rng.randf_range(0.8, 1.4), _rng)
	# des meubles : une table renversée, des chaises, une armoire tombée, un matelas éventré
	var spots: Array = []
	for k2 in range(6):
		spots.append(Vector2(_rng.randf_range(ix0 + 0.6, ix1 - 0.6), _rng.randf_range(iz0 + 0.6, iz1 - 0.6)))
	var a0: float = _rng.randf() * TAU
	var tb: Vector3 = _ground(spots[0].x, spots[0].y)
	if _rng.randf() < 0.5:
		# debout, de travers
		_det.box_at("bois_sombre", tb + Vector3.UP * 0.76, Vector3(1.6, 0.06, 0.9), a0)
		for lx in [-0.7, 0.7]:
			for lz in [-0.35, 0.35]:
				var lp: Vector3 = tb + Basis(Vector3.UP, a0) * Vector3(lx, 0.37, lz)
				_det.box_at("bois_sombre", lp, Vector3(0.07, 0.74, 0.07), a0)
		_col(Transform3D(Basis(Vector3.UP, a0), tb + Vector3.UP * 0.4), Vector3(1.6, 0.8, 0.9))
	else:
		# renversée sur le côté, les pieds en l'air
		var bt := Basis(Vector3.UP, a0) * Basis(Vector3.RIGHT, PI * 0.5)
		_det.box("bois_sombre", Transform3D(bt, tb + Vector3.UP * 0.45), Vector3(1.6, 0.06, 0.9))
		for lx2 in [-0.7, 0.7]:
			for lz2 in [0.06, 0.06]:
				var lp2: Vector3 = tb + Vector3.UP * 0.45 + bt * Vector3(lx2, 0.4, 0.0) + Basis(Vector3.UP, a0) * Vector3(0, 0, lz2)
				_det.box("bois_sombre", Transform3D(Basis(Vector3.UP, a0), lp2), Vector3(0.07, 0.07, 0.74))
		_col(Transform3D(Basis(Vector3.UP, a0), tb + Vector3.UP * 0.45), Vector3(1.6, 0.9, 0.3))
	for k3 in range(_rng.randi_range(1, 3)):
		var cp: Vector3 = _ground(spots[1 + k3].x, spots[1 + k3].y)
		var ca: float = _rng.randf() * TAU
		if _rng.randf() < 0.5:
			_det.box_at("bois_sombre", cp + Vector3.UP * 0.45, Vector3(0.45, 0.05, 0.45), ca)
			_det.box_at("bois_sombre", cp + Basis(Vector3.UP, ca) * Vector3(0, 0.75, -0.2), Vector3(0.45, 0.6, 0.05), ca)
			for c4 in [Vector2(-0.18, -0.18), Vector2(0.18, -0.18), Vector2(-0.18, 0.18), Vector2(0.18, 0.18)]:
				_det.box_at("bois_sombre", cp + Basis(Vector3.UP, ca) * Vector3(c4.x, 0.22, c4.y), Vector3(0.04, 0.44, 0.04), ca)
		else:
			# une chaise par terre
			var bc := Basis(Vector3.UP, ca) * Basis(Vector3.RIGHT, PI * 0.5)
			_det.box("bois_sombre", Transform3D(bc, cp + Vector3.UP * 0.25), Vector3(0.45, 0.05, 0.45))
			_det.box("bois_sombre", Transform3D(bc, cp + Vector3.UP * 0.25 + bc * Vector3(0, 0.3, 0.2)), Vector3(0.45, 0.05, 0.6))
	if _rng.randf() < 0.6:
		# l'armoire tombée face contre terre
		var ap: Vector3 = _ground(spots[4].x, spots[4].y)
		var aa: float = _rng.randf() * TAU
		_det.box_at("bois_sombre", ap + Vector3.UP * 0.3, Vector3(1.0, 0.6, 2.0), aa)
		_col(Transform3D(Basis(Vector3.UP, aa), ap + Vector3.UP * 0.3), Vector3(1.0, 0.6, 2.0))
	if _rng.randf() < 0.5:
		var mp: Vector3 = _ground(spots[5].x, spots[5].y)
		var ma: float = _rng.randf() * TAU
		_det.box_at("tissu_rouge_sombre", mp + Vector3.UP * 0.1, Vector3(1.4, 0.2, 1.9), ma)
		_det.blob("sac_sable", mp + Vector3.UP * 0.22 + Basis(Vector3.UP, ma) * Vector3(0.2, 0, 0.3), Vector3(0.35, 0.12, 0.3), 6)
	# une poutre tombée du plafond, en travers
	if _rng.randf() < 0.55:
		var b0 := Vector3(_rng.randf_range(ix0, ix1), 0.0, iz0)
		var b1 := Vector3(_rng.randf_range(ix0, ix1), 0.0, iz1)
		var wa: Vector3 = IleScript.W(b0.x, b0.z, 0.0)
		wa.y = ile.height(wa.x, wa.z) + 0.15
		var wb: Vector3 = IleScript.W(b1.x, b1.z, Y0 + PLAFOND - 0.3)
		_det.tube("bois_sombre", wa, wb, 0.12, 4)
	# quelques maisons gardent une bougie allumée : quelqu'un est passé il n'y a pas longtemps
	if _bougies < 14 and _rng.randf() < 0.12:
		_bougies += 1
		var bp: Vector3 = _ground(spots[0].x, spots[0].y)
		bp.y += 0.79 if _rng.randf() < 0.5 else 0.02
		_det.cyl_at("bougie", bp, 0.03, 0.03, 0.14, 6)
		var li := OmniLight3D.new()
		li.light_color = Color(1.0, 0.62, 0.3)
		li.light_energy = 0.9
		li.omni_range = 6.0
		li.shadow_enabled = false
		li.distance_fade_enabled = true
		li.distance_fade_begin = 30.0
		li.distance_fade_length = 10.0
		add_child(li)
		li.global_position = bp + Vector3.UP * 0.3
		_castle_lights.append([li, 0.9])


## Les petites maisons entre la rue du tour de ville et la grève
func _maisons_cote() -> void:
	var n: int = 0
	for attempt in range(500):
		if n >= 70:
			break
		var a: float = _rng.randf() * TAU
		var rr: float = _rng.randf_range(IleScript.ANNEAU + 14.0, IleScript.RS - 8.0)
		var l := Vector2(cos(a), sin(a)) * rr
		if ile.coast_q(l.x, l.y) > 0.93 or (absf(l.x) < 22.0 and l.y < 0.0):
			continue
		var w: float = _rng.randf_range(7.0, 11.0)
		var d: float = _rng.randf_range(7.0, 10.0)
		var x0: float = l.x - w * 0.5
		var z0: float = l.y - d * 0.5
		var free: bool = true
		for xi in range(int(floor((x0 - 4.0) / 2.0)), int(ceil((x0 + w + 4.0) / 2.0))):
			for zi in range(int(floor((z0 - 4.0) / 2.0)), int(ceil((z0 + d + 4.0) / 2.0))):
				if _blocked.has(Vector2i(xi, zi)):
					free = false
		if not free:
			continue
		var face: Vector2 = (-l).normalized()
		face = Vector2(signf(face.x), 0.0) if absf(face.x) > absf(face.y) else Vector2(0.0, signf(face.y))
		_lot([x0, z0, x0 + w, z0 + d], _rng.randi_range(1, 3), "faubourg", face)
		n += 1


# =================================================================== les lieux

func _place_marche() -> void:
	var r: Array = IleScript.block_rect(-1, -3)
	var cx: float = (float(r[0]) + float(r[2])) * 0.5
	var cz: float = (float(r[1]) + float(r[3])) * 0.5
	var b := Kit.Batch.new()
	# le beffroi (une tour de brique, l'horloge arrêtée à minuit, la cloche)
	var bx: float = float(r[0]) + 6.0
	var bz: float = cz
	_boite_rect(bx - 3.5, bz - 3.5, bx + 3.5, bz + 3.5, Y0 - 1.0, Y0 + 22.0, 0.0, 0.5, 0.3)
	_boite_rect(bx - 3.0, bz - 3.0, bx + 3.0, bz + 3.0, Y0 + 22.0, Y0 + 23.0, 0.0, 0.0, 0.3)
	_block(bx - 3.5, bz - 3.5, bx + 3.5, bz + 3.5)
	var bt: Vector3 = IleScript.W(bx, bz, Y0 + 23.0)
	for c in [Vector3(-2.7, 0, -2.7), Vector3(2.7, 0, -2.7), Vector3(-2.7, 0, 2.7), Vector3(2.7, 0, 2.7)]:
		b.box("pierre_chateau", Transform3D(Basis(), bt + c + Vector3.UP * 2.0), Vector3(0.6, 4.0, 0.6))
	b.cyl("ardoise", Transform3D(Basis(Vector3.UP, PI * 0.25), bt + Vector3.UP * 4.0), 4.6, 0.05, 6.0, 4)
	b.cyl("rouille", Transform3D(Basis(), bt + Vector3.UP * 1.0), 0.75, 0.45, 1.3, 12)
	b.cyl("fer_noir", Transform3D(Basis(), bt + Vector3.UP * 2.3), 0.06, 0.06, 1.7, 6)
	# le cadran (vers l'est, vers la place)
	var cad: Vector3 = IleScript.W(bx + 3.56, bz, Y0 + 18.0)
	b.cyl("beton_clair", Transform3D(Basis(Vector3.FORWARD, PI * 0.5), cad), 1.7, 1.7, 0.08, 20)
	b.box("fer_noir", Transform3D(Basis(), cad + Vector3(0.09, 0.55, 0)), Vector3(0.04, 1.1, 0.1))
	b.box("fer_noir", Transform3D(Basis(), cad + Vector3(0.1, 0.4, 0)), Vector3(0.04, 0.8, 0.14))
	objets["beffroi"] = IleScript.W(bx + 5.0, bz, ile.height(IleScript.W(bx + 5.0, bz).x, IleScript.W(bx + 5.0, bz).z))
	# la fontaine à sec, au milieu
	var fc: Vector3 = _ground(cx + 4.0, cz)
	b.cyl("pierre_tombe", Transform3D(Basis(), fc), 4.0, 4.0, 0.8, 24)
	b.cyl("interieur", Transform3D(Basis(), fc + Vector3.UP * 0.05), 3.6, 3.6, 0.8, 24)
	b.cyl("pierre_tombe", Transform3D(Basis(), fc), 0.5, 0.35, 2.6, 10)
	b.blob("pierre_tombe", fc + Vector3.UP * 2.7, Vector3(0.8, 0.25, 0.8), 10)
	_col(Transform3D(Basis(), fc + Vector3.UP * 0.4), Vector3(7.6, 0.8, 7.6))
	# les squelettes des étals du marché (des cadres de fer rouillé, des bâches déchirées)
	for k in range(6):
		var sp: Vector3 = _ground(cx + _rng.randf_range(-8.0, 14.0), cz + (-12.0 if k % 2 == 0 else 12.0) + _rng.randf_range(-2.0, 2.0))
		var yaw: float = _rng.randf_range(-0.3, 0.3)
		var bs := Basis(Vector3.UP, yaw)
		for c2 in [Vector3(-1.4, 0, -0.9), Vector3(1.4, 0, -0.9), Vector3(-1.4, 0, 0.9), Vector3(1.4, 0, 0.9)]:
			b.tube("rouille", sp + bs * c2, sp + bs * c2 + Vector3.UP * 2.2, 0.035, 5)
		if _rng.randf() < 0.6:
			b.box("tissu_rouge_sombre", Transform3D(bs * Basis(Vector3.RIGHT, _rng.randf_range(0.1, 0.6)), sp + Vector3.UP * 2.1), Vector3(3.0, 0.02, 1.4))
		b.box("bois_pourri", Transform3D(bs * Basis(Vector3.FORWARD, _rng.randf_range(-0.4, 0.4)), sp + Vector3.UP * 0.6), Vector3(2.6, 0.06, 1.6))
	b.commit(self, "Place_du_marche_v121")


func _cimetiere() -> void:
	var r: Array = IleScript.block_rect(2, 2)
	var x0: float = r[0]
	var z0: float = r[1]
	var x1: float = r[2]
	var z1: float = r[3]
	var b := Kit.Batch.new()
	# le petit mur, et sa grille d'entrée (au nord)
	for e in [[x0, z0, x1, z0], [x0, z1, x1, z1], [x0, z0, x0, z1], [x1, z0, x1, z1]]:
		var a := Vector2(e[0], e[1])
		var c := Vector2(e[2], e[3])
		var l: float = a.distance_to(c)
		var mid: Vector2 = (a + c) * 0.5
		var yaw: float = atan2(c.x - a.x, c.y - a.y)
		if e[1] == z0 and e[3] == z0:
			# la grille au milieu du mur nord
			for side in [-1.0, 1.0]:
				var segl: float = l * 0.5 - 2.0
				var sm: Vector2 = mid + Vector2(side * (2.0 + segl * 0.5), 0)
				b.box("pierre_tombe", Transform3D(Basis(Vector3.UP, yaw), _ground(sm.x, sm.y) + Vector3.UP * 0.7), Vector3(0.5, 1.6, segl))
				_col(Transform3D(Basis(Vector3.UP, yaw), _ground(sm.x, sm.y) + Vector3.UP * 0.8), Vector3(0.5, 1.6, segl))
			for k in range(9):
				var gx: float = mid.x - 1.8 + k * 0.45
				var gp: Vector3 = _ground(gx, mid.y)
				b.tube("fer_noir", gp, gp + Vector3.UP * (2.2 + 0.25 * sin(k * 0.7)), 0.025, 5)
			b.tube("fer_noir", _ground(mid.x - 2.0, mid.y) + Vector3.UP * 2.0, _ground(mid.x + 2.0, mid.y) + Vector3.UP * 2.0, 0.03, 5)
			objets["cimetiere_grille"] = _ground(mid.x, mid.y - 2.0)
			continue
		b.box("pierre_tombe", Transform3D(Basis(Vector3.UP, yaw), _ground(mid.x, mid.y) + Vector3.UP * 0.7), Vector3(0.5, 1.6, l))
		_col(Transform3D(Basis(Vector3.UP, yaw), _ground(mid.x, mid.y) + Vector3.UP * 0.8), Vector3(0.5, 1.6, l))
	# les tombes, en rangées un peu de travers
	for row in range(6):
		for k in range(8):
			if _rng.randf() < 0.15:
				continue
			var gx2: float = x0 + 4.0 + k * ((x1 - x0 - 8.0) / 7.0) + _rng.randf_range(-0.4, 0.4)
			var gz: float = z0 + 6.0 + row * ((z1 - z0 - 14.0) / 5.0) + _rng.randf_range(-0.4, 0.4)
			if absf(gx2 - (x0 + x1) * 0.5) < 2.2:
				continue
			Kit.grave(b, _ground(gx2, gz), _rng.randf_range(-0.15, 0.15), _rng)
	# le mausolée, au fond
	var mx: float = (x0 + x1) * 0.5
	var mz: float = z1 - 6.0
	_boite_rect(mx - 3.0, mz - 3.0, mx + 3.0, mz + 3.0, Y0 - 1.0, Y0 + 4.5, 1.0, 0.7, 0.2)
	b.cyl("pierre_tombe", Transform3D(Basis(Vector3.UP, PI * 0.25), _ground(mx, mz) + Vector3.UP * 4.5), 4.6, 0.3, 2.4, 4)
	b.box("fer_noir", Transform3D(Basis(), _ground(mx, mz - 3.05) + Vector3.UP * 1.3), Vector3(1.6, 2.6, 0.08))
	_block(x0, z0, x1, z1)
	# des arbres morts
	for k3 in range(5):
		tree_spots.append(_ground(_rng.randf_range(x0 + 3.0, x1 - 3.0), _rng.randf_range(z0 + 3.0, z1 - 10.0)))
	b.commit(self, "Vieux_cimetiere_v121")


func _gare() -> void:
	var r: Array = IleScript.block_rect(2, -1)
	var x0: float = r[0]
	var z0: float = r[1]
	var x1: float = r[2]
	var z1: float = r[3]
	var b := Kit.Batch.new()
	# le bâtiment des voyageurs (au nord), la grande halle (la verrière crevée)
	_boite_rect(x0, z0, x1, z0 + 9.0, Y0 - 1.0, Y0 + 10.0, 0.0, 0.4, 0.6)
	_boite_rect(x0 + 13.0, z0 + 0.5, x0 + 21.0, z0 + 8.5, Y0 + 10.0, Y0 + 15.0, 0.0, 0.2, 0.6)
	_block(x0, z0, x1, z0 + 9.0)
	var clk: Vector3 = IleScript.W(x0 + 17.0, z0 - 0.05, Y0 + 12.8)
	b.cyl("beton_clair", Transform3D(Basis(Vector3.RIGHT, PI * 0.5), clk), 1.5, 1.5, 0.1, 20)
	b.box("fer_noir", Transform3D(Basis(), clk + Vector3(0, 0.45, -0.1)), Vector3(0.08, 0.9, 0.04))
	b.box("fer_noir", Transform3D(Basis(Vector3.FORWARD, 1.0), clk + Vector3(0.25, 0.15, -0.1)), Vector3(0.08, 0.6, 0.04))
	var hz0: float = z0 + 9.0
	for k in range(6):
		var z: float = hz0 + 2.0 + k * ((z1 - hz0 - 4.0) / 5.0)
		for xx in [x0 + 1.0, x1 - 1.0]:
			b.tube("rouille", _ground(xx, z), _ground(xx, z) + Vector3.UP * 9.0, 0.18, 8)
		# les arcs de fer de la verrière (quelques-uns sont tombés)
		if k != 3:
			var prev: Vector3 = _ground(x0 + 1.0, z) + Vector3.UP * 9.0
			for s in range(1, 9):
				var u: float = s / 8.0
				var p: Vector3 = IleScript.W(lerpf(x0 + 1.0, x1 - 1.0, u), z, Y0 + 9.0 + sin(u * PI) * 5.0)
				b.tube("rouille", prev, p, 0.12, 6)
				prev = p
	# deux wagons rouillés sur leurs rails
	for k2 in range(2):
		var wx: float = x0 + 10.0 + k2 * 14.0
		var wb: Vector3 = _ground(wx, (hz0 + z1) * 0.5)
		for rx in [-0.75, 0.75]:
			b.box("rouille", Transform3D(Basis(), IleScript.W(wx + rx, (hz0 + z1) * 0.5, Y0 + 0.08)), Vector3(0.1, 0.12, z1 - hz0 - 2.0))
		var ww: Vector3 = wb + Vector3(0, 0.0, 6.0 * (k2 - 0.5))
		b.box("rouille_verte", Transform3D(Basis(), ww + Vector3.UP * 2.0), Vector3(2.8, 2.8, 12.0))
		b.box("interieur", Transform3D(Basis(), ww + Vector3.UP * 2.5), Vector3(2.82, 0.9, 10.5))
		b.box("rouille", Transform3D(Basis(), ww + Vector3.UP * 3.5), Vector3(2.9, 0.2, 12.2))
		_col(Transform3D(Basis(), ww + Vector3.UP * 2.0), Vector3(2.8, 2.8, 12.0))
	b.commit(self, "Gare_v121")


func _port() -> void:
	var b := Kit.Batch.new()
	# la jetée de bois, les pieux
	var jz0: float = float(IleScript.JETEE[2])
	var jz1: float = float(IleScript.JETEE[3])
	for k in range(int((jz1 - jz0) / 3.0) + 1):
		var z: float = jz0 + k * 3.0
		for x in [-4.6, 4.6]:
			var p: Vector3 = IleScript.W(x, z, -3.0)
			b.cyl("bois_sombre", Transform3D(Basis(), p), 0.22, 0.2, ile.height(p.x, p.z) + 4.4, 8)
	# des conteneurs rouillés, empilés de travers
	for k2 in range(14):
		var side: float = -1.0 if k2 % 2 == 0 else 1.0
		var cx: float = side * _rng.randf_range(25.0, 130.0)
		var cz: float = _rng.randf_range(-228.0, -205.0)
		if ile.coast_q(cx, cz) > 0.97:
			continue
		var yaw: float = _rng.randf_range(-0.4, 0.4) + (PI * 0.5 if _rng.randf() < 0.3 else 0.0)
		var key: String = ["rouille_rouge", "rouille_bleue", "rouille_verte", "rouille"][_rng.randi() % 4]
		var base: Vector3 = _ground(cx, cz)
		b.box(key, Transform3D(Basis(Vector3.UP, yaw), base + Vector3.UP * 1.3), Vector3(2.44, 2.6, 6.06))
		_col(Transform3D(Basis(Vector3.UP, yaw), base + Vector3.UP * 1.3), Vector3(2.44, 2.6, 6.06))
		if _rng.randf() < 0.35:
			var yaw2: float = yaw + _rng.randf_range(-0.3, 0.3)
			var key2: String = ["rouille_rouge", "rouille_bleue", "rouille_verte"][_rng.randi() % 3]
			b.box(key2, Transform3D(Basis(Vector3.UP, yaw2), base + Vector3.UP * 3.9), Vector3(2.44, 2.6, 6.06))
			_col(Transform3D(Basis(Vector3.UP, yaw2), base + Vector3.UP * 3.9), Vector3(2.44, 2.6, 6.06))
	# un chalutier échoué sur la grève, penché
	var wreck: Vector3 = _ground(-38.0, -246.0)
	var bs := Basis(Vector3.UP, 0.6) * Basis(Vector3.FORWARD, 0.35)
	b.box("rouille_bleue", Transform3D(bs, wreck + Vector3.UP * 1.0), Vector3(4.2, 2.6, 14.0))
	b.box("rouille_creme", Transform3D(bs, wreck + bs * Vector3(0, 3.0, -2.0)), Vector3(3.0, 2.2, 4.0))
	b.box("interieur", Transform3D(bs, wreck + bs * Vector3(0, 3.2, -2.0)), Vector3(3.05, 0.7, 3.4))
	b.tube("rouille", wreck + bs * Vector3(0, 2.0, 3.0), wreck + bs * Vector3(0, 9.0, 3.5), 0.12, 6)
	_col(Transform3D(bs, wreck + Vector3.UP * 1.0), Vector3(4.2, 2.6, 14.0))
	# la barricade des derniers défenseurs du port (un passage au milieu)
	Kit.barricade(b, _ground(-9.0, -206.0), 0.0, 8.0, _rng)
	Kit.barricade(b, _ground(9.0, -206.0), 0.0, 8.0, _rng)
	for bx in [-9.0, 9.0]:
		_col(Transform3D(Basis(), _ground(bx, -206.0) + Vector3.UP * 0.8), Vector3(8.0, 1.6, 0.8))
	# un panneau rouillé, à l'entrée de la ville
	var pn: Vector3 = _ground(10.0, -224.0)
	b.tube("fer_noir", pn, pn + Vector3.UP * 3.0, 0.05, 6)
	b.box("rouille_creme", Transform3D(Basis(Vector3.UP, 0.15), pn + Vector3(0, 2.6, 0.08)), Vector3(2.4, 0.9, 0.04))
	var lb := Label3D.new()
	lb.text = "SOMBREVAL\nBienvenue"
	lb.font_size = 64
	lb.pixel_size = 0.006
	lb.modulate = Color(0.22, 0.12, 0.08)
	lb.outline_size = 0
	add_child(lb)
	lb.global_position = pn + Vector3(0, 2.65, 0.11)
	lb.global_rotation = Vector3(0, PI + 0.15, 0)
	b.commit(self, "Port_des_brumes_v121")


## Les rues : les carcasses de voitures et d'autobus, les réverbères tordus, les poubelles, les gravats
func _rues() -> void:
	var b := Kit.Batch.new()
	var nb_car: int = 0
	for axis in range(2):
		for k in range(-3, 4):
			var along: float = -IleScript.ANNEAU + 6.0
			while along < IleScript.ANNEAU - 6.0:
				along += _rng.randf_range(7.0, 13.0)
				var m: float = absf(along - round(along / IleScript.PAS) * IleScript.PAS)
				if m < 9.0:
					continue
				var lane: float = (2.4 if _rng.randf() < 0.5 else -2.4)
				var x: float = k * IleScript.PAS + lane if axis == 0 else along
				var z: float = along if axis == 0 else k * IleScript.PAS + lane
				if Vector2(x, z).length() < IleScript.HILL_R1 + 4.0:
					continue
				if absf(x) < 8.0 and z < -170.0:
					continue
				var dir_yaw: float = 0.0 if axis == 0 else PI * 0.5
				var r: float = _rng.randf()
				if r < 0.3:
					var roll: float = 0.0
					var yaw: float = dir_yaw + (PI if _rng.randf() < 0.5 else 0.0) + _rng.randf_range(-0.15, 0.15)
					var rr: float = _rng.randf()
					if rr < 0.15:
						yaw += _rng.randf_range(-1.2, 1.2)
					elif rr < 0.21:
						roll = PI * 0.5 * (1.0 if _rng.randf() < 0.5 else -1.0)
					elif rr < 0.24:
						roll = PI
					var at: Vector3 = _ground(x, z)
					Kit.car(b, at, yaw, Kit.CAR_PAINTS[_rng.randi() % Kit.CAR_PAINTS.size()], roll, _rng)
					_col(Transform3D(Basis(Vector3.UP, yaw), at + Vector3.UP * 0.8), Vector3(1.8, 1.6, 4.2))
					nb_car += 1
					_block(x - 2.6, z - 2.6, x + 2.6, z + 2.6)
				elif r < 0.36:
					_block(x - 2.5, z - 2.5, x + 2.5, z + 2.5)
					Kit.rubble(b, _ground(x + _rng.randf_range(-2.0, 2.0), z + _rng.randf_range(-2.0, 2.0)), _rng.randf_range(1.0, 2.2), _rng)
				elif r < 0.46:
					var side: float = 1.0 if _rng.randf() < 0.5 else -1.0
					var off: float = IleScript.largeur(k).x + 1.4
					var tx: float = k * IleScript.PAS + side * off if axis == 0 else along
					var tz: float = along if axis == 0 else k * IleScript.PAS + side * off
					Kit.trash(b, _ground(tx, tz), _rng.randf() * TAU, _rng)
	# les réverbères (le long des trottoirs), certains tordus, certains tombés
	for axis2 in range(2):
		for k2 in range(-3, 4):
			var along2: float = -IleScript.ANNEAU + 10.0
			while along2 < IleScript.ANNEAU - 6.0:
				along2 += 26.0
				for side2 in [-1.0, 1.0]:
					var off2: float = IleScript.largeur(k2).x + 1.0
					var lx: float = k2 * IleScript.PAS + side2 * off2 if axis2 == 0 else along2
					var lz: float = along2 if axis2 == 0 else k2 * IleScript.PAS + side2 * off2
					if Vector2(lx, lz).length() < IleScript.HILL_R1 + 2.0:
						continue
					var face: Vector3 = Vector3(-side2, 0, 0) if axis2 == 0 else Vector3(0, 0, -side2)
					var bend: float = 0.0
					var rb: float = _rng.randf()
					if rb < 0.3:
						bend = _rng.randf_range(0.08, 0.35)
					elif rb < 0.4:
						bend = _rng.randf_range(1.2, 1.45)
					elif rb < 0.5:
						continue
					Kit.lamp(b, _ground(lx, lz), face, bend * (1.0 if _rng.randf() < 0.5 else -1.0))
	# trois autobus abandonnés
	for e in [[-2.4, -185.0, 0.1], [102.4, 2.0, PI * 0.5 + 0.2], [-60.0, 148.0, -0.3]]:
		var at2: Vector3 = _ground(e[0], e[1])
		Kit.bus(b, at2, e[2])
		_block(float(e[0]) - 6.5, float(e[1]) - 6.5, float(e[0]) + 6.5, float(e[1]) + 6.5)
		_col(Transform3D(Basis(Vector3.UP, e[2]), at2 + Vector3.UP * 1.7), Vector3(2.5, 3.2, 11.0))
	b.commit(self, "Rues_v121", true, 300.0)
	print("ILE_MANGA_V121: Sombreval, %d carcasses de voitures" % nb_car)


# =================================================================== le château du comte

func _chateau() -> void:
	var b := Kit.Batch.new()
	var c0: Vector3 = IleScript.W(0.0, 0.0, TOP)
	var R: float = 37.0
	var corners: Array = []
	for k in range(8):
		var a: float = deg_to_rad(22.5 + 45.0 * k)
		corners.append(c0 + Vector3(cos(a), 0, sin(a)) * R)
	# les remparts (le mur ouest a la grande porte)
	for k2 in range(8):
		var a3: Vector3 = corners[k2]
		var c3: Vector3 = corners[(k2 + 1) % 8]
		var mid: Vector3 = (a3 + c3) * 0.5
		if mid.x < c0.x - 30.0:
			# deux moitiés, et la porte au milieu
			var dz: Vector3 = (c3 - a3).normalized()
			Kit.rampart(b, a3, mid - dz * 3.2, 13.0, 3.2)
			Kit.rampart(b, mid + dz * 3.2, c3, 13.0, 3.2)
			_wall_col(a3, mid - dz * 3.2, 13.0, 3.2)
			_wall_col(mid + dz * 3.2, c3, 13.0, 3.2)
			_gatehouse(b, mid, dz)
			continue
		Kit.rampart(b, a3, c3, 13.0, 3.2)
		_wall_col(a3, c3, 13.0, 3.2)
	for k3 in range(8):
		var tw: Vector3 = corners[k3]
		for lp in Kit.tower(b, tw, 4.4, 22.0, 9.0, true, _rng):
			_castle_light(lp, 1.6)
		_col(Transform3D(Basis(), tw + Vector3.UP * 10.0), Vector3(8.0, 24.0, 8.0))
	# le grand donjon : une tour carrée, ses quatre tourelles, son grand toit pointu
	var dj: Vector3 = c0 + Vector3(4.0, 0, 0)
	b.box("pierre_chateau", Transform3D(Basis(), dj + Vector3.UP * 17.0), Vector3(18.0, 36.0, 18.0))
	b.box("pierre_chateau_claire", Transform3D(Basis(), dj + Vector3.UP * 34.4), Vector3(19.2, 1.2, 19.2))
	b.cyl("ardoise", Transform3D(Basis(Vector3.UP, PI * 0.25), dj + Vector3.UP * 35.0), 13.2, 0.1, 16.0, 4)
	b.tube("fer_noir", dj + Vector3.UP * 50.5, dj + Vector3.UP * 55.0, 0.08, 6)
	_col(Transform3D(Basis(), dj + Vector3.UP * 17.0), Vector3(18.0, 36.0, 18.0))
	for cx in [-9.0, 9.0]:
		for cz in [-9.0, 9.0]:
			for lp2 in Kit.tower(b, dj + Vector3(cx, 0, cz), 2.6, 40.0, 7.0, true, _rng):
				_castle_light(lp2, 1.4)
	# les hautes fenêtres du donjon, toutes rouges, et la grande rosace qui regarde la ville
	for side in [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]:
		for fl in range(4):
			for k4 in [-1, 1]:
				var t3: Vector3 = side.cross(Vector3.UP)
				var wp: Vector3 = dj + side * 9.05 + t3 * (k4 * 3.6) + Vector3.UP * (10.0 + fl * 6.5)
				var key: String = "fenetre_rouge" if (fl + k4) % 3 != 0 else "interieur"
				b.box(key, Transform3D(Basis(Vector3.UP, atan2(side.x, side.z)), wp), Vector3(1.0, 2.6, 0.12))
				b.cyl("pierre_chateau_claire", Transform3D(Basis(Vector3.UP, atan2(side.x, side.z)) * Basis(Vector3.RIGHT, PI * 0.5), wp + Vector3.UP * 1.3 - side * 0.05), 0.55, 0.55, 0.2, 8)
	var ros: Vector3 = dj + Vector3(-9.08, 28.0, 0)
	b.cyl("fenetre_rouge", Transform3D(Basis(Vector3.FORWARD, PI * 0.5), ros), 2.6, 2.6, 0.1, 24)
	b.cyl("pierre_chateau_claire", Transform3D(Basis(Vector3.FORWARD, PI * 0.5), ros + Vector3(-0.02, 0, 0)), 2.9, 2.9, 0.06, 24)
	_castle_light(ros + Vector3(-3.0, 0, 0), 3.0)
	# de grandes bannières rouge sombre sur le donjon
	for zz in [-5.0, 5.0]:
		b.box("tissu_rouge_sombre", Transform3D(Basis(), dj + Vector3(-9.15, 19.0, zz)), Vector3(0.04, 9.0, 2.4))
	b.commit(self, "Chateau_du_comte_v121", true)
	_chauves_souris(dj)


func _wall_col(a: Vector3, c: Vector3, h: float, ep: float) -> void:
	var d: Vector3 = c - a
	d.y = 0.0
	var mid: Vector3 = (a + c) * 0.5
	_col(Transform3D(Basis(Vector3.UP, atan2(d.x, d.z)), mid + Vector3.UP * (h * 0.5)), Vector3(ep, h + 2.0, d.length()))


## La grande porte : deux tours, la herse baissée, les battants de chêne noir
func _gatehouse(b: Kit.Batch, mid: Vector3, along: Vector3) -> void:
	var out: Vector3 = along.cross(Vector3.UP).normalized()
	if out.x > 0.0:
		out = -out
	for s in [-1.0, 1.0]:
		var tp: Vector3 = mid + along * (s * 5.2) + out * 1.0
		for lp in Kit.tower(b, tp, 3.0, 18.0, 7.0, true, _rng):
			_castle_light(lp, 1.2)
		_col(Transform3D(Basis(), tp + Vector3.UP * 9.0), Vector3(6.0, 20.0, 6.0))
	var yaw: float = atan2(along.x, along.z)
	b.box("pierre_chateau", Transform3D(Basis(Vector3.UP, yaw), mid + Vector3.UP * 10.5), Vector3(3.4, 5.0, 6.4))
	# les battants
	b.box("bois_sombre", Transform3D(Basis(Vector3.UP, yaw), mid + out * 0.2 + Vector3.UP * 4.0), Vector3(0.3, 8.0, 6.2))
	# la herse
	for k in range(9):
		var p: Vector3 = mid + out * 1.0 + along * (-2.8 + k * 0.7)
		b.tube("fer_noir", p, p + Vector3.UP * 8.0, 0.06, 6)
	for k2 in range(6):
		var p2: Vector3 = mid + out * 1.0 + Vector3.UP * (0.8 + k2 * 1.4)
		b.tube("fer_noir", p2 - along * 3.0, p2 + along * 3.0, 0.05, 6)
	_col(Transform3D(Basis(Vector3.UP, yaw), mid + Vector3.UP * 4.0), Vector3(1.2, 8.0, 6.4))
	# deux torches de part et d'autre (elles brûlent rouge)
	for s2 in [-1.0, 1.0]:
		var tc: Vector3 = mid + out * 1.4 + along * (s2 * 3.6) + Vector3.UP * 4.5
		b.cyl("fer_noir", Transform3D(Basis(), tc - Vector3.UP * 0.5), 0.06, 0.12, 0.5, 6)
		b.blob("fenetre_orange", tc + Vector3.UP * 0.15, Vector3(0.14, 0.24, 0.14), 6)
		_castle_light(tc + out * 0.4, 1.4, Color(1.0, 0.42, 0.12))
	porte_chateau = mid + out * 3.5
	porte_chateau.y = ile.height(porte_chateau.x, porte_chateau.z)
	_interactions.append({"id": "sv_porte_chateau", "pos": porte_chateau, "radius": 3.2, "text": "E : frapper à la grande porte du château",
		"vr": "Gâchette : frapper à la porte du château", "call": _frapper_porte})


func _castle_light(at: Vector3, energy: float, col: Color = Color(1.0, 0.2, 0.08)) -> void:
	if _castle_lights.size() >= (24 if pc else 12):
		return
	var l := OmniLight3D.new()
	l.light_color = col
	l.light_energy = energy
	l.omni_range = 9.0
	l.omni_attenuation = 1.3
	l.shadow_enabled = false
	add_child(l)
	l.global_position = at
	_castle_lights.append([l, energy])


func _chauves_souris(dj: Vector3) -> void:
	var body := BoxMesh.new()
	body.size = Vector3(0.12, 0.08, 0.22)
	var wing := BoxMesh.new()
	wing.size = Vector3(0.36, 0.01, 0.18)
	var mt := StandardMaterial3D.new()
	mt.albedo_color = Color(0.03, 0.025, 0.03)
	mt.roughness = 0.8
	for k in range(16 if pc else 10):
		var n := Node3D.new()
		var bm := MeshInstance3D.new()
		bm.mesh = body
		bm.material_override = mt
		n.add_child(bm)
		var wl := MeshInstance3D.new()
		wl.mesh = wing
		wl.material_override = mt
		wl.position = Vector3(-0.2, 0, 0)
		n.add_child(wl)
		var wr := MeshInstance3D.new()
		wr.mesh = wing
		wr.material_override = mt
		wr.position = Vector3(0.2, 0, 0)
		n.add_child(wr)
		n.scale = Vector3.ONE * _rng.randf_range(1.6, 2.4)
		add_child(n)
		_bats.append([n, _rng.randf_range(14.0, 34.0), _rng.randf_range(0.35, 0.8) * (1.0 if _rng.randf() < 0.7 else -1.0), _rng.randf() * TAU, _rng.randf_range(38.0, 62.0)])
		_wing_l.append([wl, wr])
	objets["donjon"] = dj


# =================================================================== les ruines : le MultiMesh

func _ruines_mm() -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	var bm := BoxMesh.new()
	bm.size = Vector3.ONE
	mm.mesh = bm
	mm.instance_count = _xfs.size()
	for k in range(_xfs.size()):
		mm.set_instance_transform(k, _xfs[k])
		mm.set_instance_custom_data(k, _customs[k])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Sombreval_ruines"
	mmi.multimesh = mm
	mmi.material_override = ruine_mat
	add_child(mmi)
	_xfs.clear()
	_customs.clear()


## Les rideaux de lierre qui pendent des façades
func _lierre() -> void:
	if _ivy.is_empty():
		return
	var mat := StandardMaterial3D.new()
	if ResourceLoader.exists("res://assets/textures/flora/leaves.png"):
		mat.albedo_texture = load("res://assets/textures/flora/leaves.png")
	if ResourceLoader.exists("res://assets/textures/flora/leaves_n.png"):
		mat.normal_enabled = true
		mat.normal_texture = load("res://assets/textures/flora/leaves_n.png")
	mat.albedo_color = Color(0.36, 0.48, 0.26)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	mat.alpha_scissor_threshold = 0.45
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.roughness = 0.85
	mat.uv1_scale = Vector3(2.5, 4.0, 1.0)
	var qm := QuadMesh.new()
	qm.size = Vector2.ONE
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = qm
	mm.instance_count = _ivy.size()
	for k in range(_ivy.size()):
		mm.set_instance_transform(k, _ivy[k])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Sombreval_lierre"
	mmi.multimesh = mm
	mmi.material_override = mat
	mmi.visibility_range_end = 260.0
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)


## Des traces sur les murs : des mains de sang (Public averti) ou de suie (Tout public)
var _traces_mat: StandardMaterial3D


func _traces() -> void:
	_traces_mat = StandardMaterial3D.new()
	_traces_mat.albedo_color = Color(0.3, 0.02, 0.02) if Public.averti() else Color(0.05, 0.045, 0.04)
	_traces_mat.roughness = 0.4
	var b := Kit.Batch.new()
	var n: int = 0
	for e in batiments:
		if n >= 40 or _rng.randf() > 0.12 or str(e["ruine"]) == "effondre":
			continue
		var r: Array = e["rect"]
		var side: int = _rng.randi() % 4
		var p: Vector3
		var yaw: float
		match side:
			0:
				p = IleScript.W(_rng.randf_range(float(r[0]) + 1.0, float(r[2]) - 1.0), float(r[1]) - 0.31, 0.0)
				yaw = 0.0
			1:
				p = IleScript.W(_rng.randf_range(float(r[0]) + 1.0, float(r[2]) - 1.0), float(r[3]) + 0.31, 0.0)
				yaw = 0.0
			2:
				p = IleScript.W(float(r[0]) - 0.31, _rng.randf_range(float(r[1]) + 1.0, float(r[3]) - 1.0), 0.0)
				yaw = PI * 0.5
			_:
				p = IleScript.W(float(r[2]) + 0.31, _rng.randf_range(float(r[1]) + 1.0, float(r[3]) - 1.0), 0.0)
				yaw = PI * 0.5
		p.y = Y0 + _rng.randf_range(0.9, 1.7)
		for k in range(_rng.randi_range(2, 5)):
			var o := Vector3(_rng.randf_range(-0.6, 0.6), _rng.randf_range(-0.4, 0.4), 0)
			var bs := Basis(Vector3.UP, yaw)
			b.box("ordures", Transform3D(bs * Basis(Vector3.FORWARD, _rng.randf_range(-0.4, 0.4)), p + bs * o), Vector3(0.14, 0.2, 0.012))
			b.box("ordures", Transform3D(bs, p + bs * o + Vector3.DOWN * _rng.randf_range(0.1, 0.5)), Vector3(0.03, _rng.randf_range(0.2, 0.7), 0.012))
		n += 1
	var mi: MeshInstance3D = b.commit(self, "Sombreval_traces_v121", false, 120.0)
	if mi != null:
		for s in range(mi.mesh.get_surface_count()):
			mi.set_surface_override_material(s, _traces_mat)


## Les cinq pages du journal du docteur Vasseur (une feuille qui luit à peine)
func _notes() -> void:
	var pm := StandardMaterial3D.new()
	pm.albedo_color = Color(0.85, 0.8, 0.66)
	pm.emission_enabled = true
	pm.emission = Color(0.9, 0.85, 0.65)
	pm.emission_energy_multiplier = 0.35
	var qm := QuadMesh.new()
	qm.size = Vector2(0.22, 0.3)
	for e in NOTES:
		var l: Vector2 = e[1]
		var at: Vector3 = _ground(l.x, l.y)
		var mi := MeshInstance3D.new()
		mi.mesh = qm
		mi.material_override = pm
		add_child(mi)
		mi.global_position = at + Vector3.UP * 0.03
		mi.global_rotation = Vector3(-PI * 0.5, _rng.randf() * TAU, 0)
		var id: String = str(e[0])
		_note_mi[id] = mi
		_interactions.append({"id": "sv_note_" + id, "pos": at, "radius": 1.8, "text": "E : ramasser la page de journal",
			"vr": "Gâchette : lire la page", "call": _lire_note.bind(id, mi)})
	# le beffroi
	if objets.has("beffroi"):
		_interactions.append({"id": "sv_beffroi", "pos": objets["beffroi"], "radius": 3.0, "text": "E : regarder l'horloge du beffroi",
			"vr": "Gâchette : regarder l'horloge", "call": _beffroi})


# =================================================================== l'atmosphère

func _atmosphere() -> void:
	# l'éclair (une deuxième lumière, bleutée, qui ne sert que pendant l'orage)
	_eclair = DirectionalLight3D.new()
	_eclair.name = "Eclair_sombreval_v121"
	_eclair.light_color = Color(0.75, 0.82, 1.0)
	_eclair.light_energy = 0.0
	_eclair.shadow_enabled = false
	_eclair.rotation_degrees = Vector3(-60.0, 30.0, 0.0)
	_eclair.visible = false
	add_child(_eclair)
	# la brume au ras du sol, qui suit le joueur
	_brume = CPUParticles3D.new()
	_brume.name = "Brume_sombreval_v121"
	_brume.amount = 34 if pc else 20
	_brume.lifetime = 14.0
	_brume.preprocess = 14.0
	_brume.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_brume.emission_box_extents = Vector3(38.0, 1.2, 38.0)
	_brume.direction = Vector3(1, 0, 0.3)
	_brume.spread = 40.0
	_brume.initial_velocity_min = 0.2
	_brume.initial_velocity_max = 0.6
	_brume.gravity = Vector3.ZERO
	_brume.scale_amount_min = 7.0
	_brume.scale_amount_max = 13.0
	_brume.local_coords = false
	var qm := QuadMesh.new()
	qm.size = Vector2.ONE
	_brume.mesh = qm
	var mt := StandardMaterial3D.new()
	mt.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mt.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mt.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mt.albedo_color = Color(0.62, 0.67, 0.63, 0.09)
	mt.vertex_color_use_as_albedo = true
	mt.proximity_fade_enabled = true
	mt.proximity_fade_distance = 3.0
	mt.distance_fade_mode = BaseMaterial3D.DISTANCE_FADE_PIXEL_ALPHA
	mt.distance_fade_min_distance = 1.0
	mt.distance_fade_max_distance = 6.0
	var tex := _puff_tex()
	if tex != null:
		mt.albedo_texture = tex
	_brume.material_override = mt
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 0.0))
	g.add_point(0.3, Color(1, 1, 1, 1.0))
	g.add_point(0.7, Color(1, 1, 1, 1.0))
	g.set_color(g.get_point_count() - 1, Color(1, 1, 1, 0.0))
	_brume.color_ramp = g
	_brume.emitting = false
	add_child(_brume)


func _puff_tex() -> Texture2D:
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in range(64):
		for x in range(64):
			var d: float = Vector2(x - 31.5, y - 31.5).length() / 31.5
			var a: float = clampf(1.0 - d, 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, a * a))
	return ImageTexture.create_from_image(img)


# =================================================================== les interactions

func say(text: String, seconds: float = 6.0) -> void:
	var d: Node = main.get("donjon_v35")
	if d != null and d.has_method("_say"):
		d._say(text, seconds)
	else:
		main._show_message_v28(text)


func sfx(name: String, at: Variant, db: float = 0.0) -> void:
	if main.has_method("sfx"):
		main.sfx(name, at, db)


func _lire_note(id: String, mi: MeshInstance3D) -> void:
	for e in NOTES:
		if str(e[0]) == id:
			say(str(e[2]), 12.0)
	var notes: Dictionary = state["notes"]
	if not notes.has(id):
		notes[id] = true
		sfx("ramasse", main._player_pos_v27())
		if is_instance_valid(mi):
			mi.visible = false
		if notes.size() >= NOTES.size():
			get_tree().create_timer(12.5).timeout.connect(func(): say("Les cinq pages du journal du docteur Vasseur… Le comte, là-haut, tient les morts-vivants sous son pouvoir. Il faudra monter au château.", 7.0))


func _beffroi() -> void:
	state["beffroi"] = true
	say("L'horloge du beffroi est arrêtée sur minuit. Les aiguilles sont rouillées… et pourtant, on dirait qu'elles ont bougé.", 7.0)
	sfx("cloche_cathedrale", objets.get("beffroi", null), -8.0)


func _frapper_porte() -> void:
	sfx("grande_porte", porte_chateau, 2.0)
	_orage(true)
	state["porte"] = true
	for k in range(_bats.size()):
		_bats[k][2] = float(_bats[k][2]) * 2.0
	get_tree().create_timer(1.6).timeout.connect(func():
		say("Une voix glacée tombe du haut des remparts : « Quelle audace… Mes enfants n'ont pas fini de jouer avec toi, petit voyageur. Reviens quand tu seras digne de me rencontrer. » La grande porte ne s'ouvre pas.", 10.0)
		sfx("demon_rire", porte_chateau + Vector3.UP * 14.0, -2.0))
	get_tree().create_timer(9.0).timeout.connect(func():
		for k in range(_bats.size()):
			_bats[k][2] = float(_bats[k][2]) * 0.5)


func register_services(journal: Node) -> void:
	for k in objets:
		journal.lieux["sombreval_" + str(k)] = objets[k]
	journal.lieux["sombreval"] = respawn_point()[0]
	_register_interactions()


func _register_interactions() -> void:
	if _registered:
		return
	var d: Node = main.get("donjon_v35")
	if d == null:
		return
	_registered = true
	for e in _interactions:
		d._interactions.append(e)


## Les manettes tremblent (réalité virtuelle), la manette de jeu aussi
func haptique(amp: float, dur: float) -> void:
	if main == null:
		return
	if bool(main.get("xr_active")):
		for h in [main.get("left_hand"), main.get("right_hand")]:
			if h != null and h.has_method("trigger_haptic_pulse"):
				h.trigger_haptic_pulse("haptic", 0.0, amp, dur, 0.0)
	for dev in Input.get_connected_joypads():
		Input.start_joy_vibration(dev, amp * 0.6, amp, dur)


# =================================================================== lecture

func contains(p: Vector3) -> bool:
	return ile != null and ile.contains(p.x, p.z) and p.y > -45.0


func walkable(p: Vector3) -> bool:
	if not contains(p):
		return false
	# V122 : jusque dans l'eau peu profonde (là où l'on n'a plus assez d'eau pour nager, on marche)
	# (la mer est à -0,42 m : la nage s'arrête là où le fond est à -1,02 m ; on recouvre largement)
	return ile.height(p.x, p.z) > -1.3 or p.y > 1.0


func owns_point(p: Vector3) -> bool:
	return contains(p)


## Les morts-vivants rôdent partout sur l'île (sauf sur l'eau)
func hostile_zone(p: Vector3) -> bool:
	return contains(p) and ile.height(p.x, p.z) > -0.6


func zone_at(p: Vector3) -> String:
	if not contains(p):
		return ""
	var l: Vector2 = IleScript.L(p.x, p.z)
	var r: float = l.length()
	if r < IleScript.HILL_R0 + 2.0 and p.y > TOP - 3.0:
		return "chateau"
	if r < IleScript.HILL_R1:
		return "butte"
	if ile.coast_q(l.x, l.y) > 1.0:
		return "greve"
	if maxf(absf(l.x), absf(l.y)) > IleScript.ANNEAU + 6.0:
		return "port" if l.y < -150.0 else "faubourg"
	var i: int = clampi(int(floor(l.x / IleScript.PAS)), -4, 3)
	var j: int = clampi(int(floor(l.y / IleScript.PAS)), -4, 3)
	return _district(i, j)


func place_name(p: Vector3) -> String:
	return "Sombreval, " + str(PLACES.get(zone_at(p), "la ville"))


func village_point(_id: String) -> Array:
	return respawn_point()


func respawn_point() -> Array:
	var p: Vector3 = _ground(0.0, -236.0) + Vector3.UP * 0.3
	return [p, Vector3(0, 0, 1)]


func on_faint(_p: Vector3) -> void:
	var at: Array = respawn_point()
	main.place_player_v35(at[0], at[1])


func hour() -> float:
	var t: Node = main.get("temps_v56")
	return float(t.hour) if t != null else 12.0


# =================================================================== la vie (et la peur)

func _process(delta: float) -> void:
	if main == null or ile == null:
		return
	_clock += delta
	var p: Vector3 = main._player_pos_v27()
	var d: float = Vector2(p.x - IleScript.CENTER.x, p.z - IleScript.CENTER.z).length()
	# la brume, la lumière blafarde : de plus en plus fortes en approchant
	var want: float = 1.0 - smoothstep(330.0, 470.0, d)
	sombre = move_toward(sombre, want, delta * 0.25)
	var tm: Node = main.get("temps_v56")
	if tm != null and tm.get("sombre") != null:
		tm.sombre = sombre
	_fog(sombre)
	if d > 900.0:
		if _brume.emitting:
			_brume.emitting = false
		return
	_bats_tick(delta)
	_orage_tick(delta, d < 480.0)
	var inside: bool = ile.contains(p.x, p.z) and ile.height(p.x, p.z) > -1.0
	var on_land: bool = inside and bool(main.get("game_started"))
	if _brume.emitting != on_land:
		_brume.emitting = on_land
	if on_land:
		_brume.global_position = Vector3(p.x, ile.height(p.x, p.z) + 0.6, p.z)
	_lights_flicker()
	if not on_land:
		return
	if not bool(state["visite"]) and ile.height(p.x, p.z) > 0.5:
		state["visite"] = true
		main._show_message_v28("Sombreval — la ville morte. Pas une lumière, pas une voix… seulement le vent. Et, tout là-haut, le château.")
		if main.has_method("jingle"):
			main.jingle("decouverte")
	_hordes_t -= delta
	if _hordes_t <= 0.0:
		_hordes_t = 1.0
		_hordes_tick(p)
	_peur_tick(delta, p)
	_beffroi_tick()
	_zone_t -= delta
	if _zone_t > 0.0:
		return
	_zone_t = 1.0
	var z: String = zone_at(p)
	var vis: Dictionary = state["visites"]
	if MESSAGES.has(z) and not bool(vis.get(z, false)):
		vis[z] = true
		main._show_message_v28(str(MESSAGES[z]))
	if z == "cimetiere":
		state["cimetiere"] = true
	if z == "chateau" or (porte_chateau != Vector3.ZERO and p.distance_to(porte_chateau) < 14.0 and not bool(vis.get("porte_vue", false))):
		if not bool(vis.get("porte_vue", false)):
			vis["porte_vue"] = true
			main._show_message_v28("Le château du comte — des remparts noirs, la herse baissée. Des fenêtres rouges partout… et quelque chose t'observe.")
	var mer: Node = main.get("mer_v55")
	if mer != null and mer.get("_underside") != null:
		(mer._underside as Node3D).global_position = Vector3(snappedf(p.x, 40.0), (mer._underside as Node3D).global_position.y, snappedf(p.z, 40.0))


var _env: Environment
var _fog0: float = -1.0
var _vfog0: float = -1.0


func _fog(k: float) -> void:
	if _env == null:
		for c in main.get_children():
			if c is WorldEnvironment:
				_env = (c as WorldEnvironment).environment
		if _env == null:
			return
	var tm: Node = main.get("temps_v56")
	if tm != null and tm.has_method("outdoor") and not bool(tm.outdoor()):
		return
	if _fog0 < 0.0:
		_fog0 = _env.fog_density
		_vfog0 = _env.volumetric_fog_density
	if k <= 0.001 and absf(_env.fog_density - _fog0) < 0.00001:
		return
	_env.fog_density = lerpf(_fog0, 0.0065, k)
	if _env.volumetric_fog_enabled:
		_env.volumetric_fog_density = lerpf(_vfog0, 0.012, k)


func _lights_flicker() -> void:
	for e in _castle_lights:
		var l: OmniLight3D = e[0]
		l.light_energy = float(e[1]) * (0.75 + 0.25 * sin(_clock * 7.0 + l.position.x) * sin(_clock * 3.1 + l.position.z))


func _bats_tick(delta: float) -> void:
	if not objets.has("donjon"):
		return
	var c: Vector3 = objets["donjon"]
	for k in range(_bats.size()):
		var e: Array = _bats[k]
		var n: Node3D = e[0]
		var a: float = float(e[3]) + _clock * float(e[2])
		var r: float = float(e[1]) + sin(_clock * 0.7 + float(e[3])) * 4.0
		var pos: Vector3 = c + Vector3(cos(a) * r, float(e[4]) + sin(_clock * 1.3 + float(e[3])) * 3.0, sin(a) * r)
		var tang: Vector3 = Vector3(-sin(a), 0, cos(a)) * signf(float(e[2]))
		n.global_position = pos
		n.global_rotation = Vector3(0, atan2(tang.x, tang.z), 0)
		var f: float = sin(_clock * 18.0 + k) * 0.9
		(_wing_l[k][0] as Node3D).rotation.z = f
		(_wing_l[k][1] as Node3D).rotation.z = -f


## L'orage : un éclair de temps en temps (deux flashs), puis le tonnerre qui roule
func _orage_tick(delta: float, near: bool) -> void:
	if not _eclair_seq.is_empty():
		var s: Array = _eclair_seq[0]
		s[0] = float(s[0]) - delta
		if float(s[0]) <= 0.0:
			_eclair.visible = float(s[1]) > 0.0
			_eclair.light_energy = float(s[1])
			_eclair_seq.pop_front()
	if _tonnerre_t > 0.0:
		_tonnerre_t -= delta
		if _tonnerre_t <= 0.0:
			sfx("tonnerre", main._player_pos_v27() + Vector3(_rng.randf_range(-60, 60), 40, _rng.randf_range(-60, 60)), -2.0)
	if not near:
		return
	_eclair_t -= delta
	if _eclair_t <= 0.0:
		_orage(false)


func _orage(fort: bool) -> void:
	_eclair_t = _rng.randf_range(18.0, 45.0)
	var e: float = 3.2 if fort else _rng.randf_range(1.6, 2.6)
	_eclair.rotation_degrees = Vector3(-_rng.randf_range(35.0, 70.0), _rng.randf() * 360.0, 0.0)
	_eclair_seq = [[0.0, e], [0.07, 0.0], [0.1, e * 0.7], [0.08, 0.0]]
	_tonnerre_t = 0.3 if fort else _rng.randf_range(1.0, 3.0)


## Le beffroi sonne minuit (une seule fois par nuit, pour qui est en ville)
func _beffroi_tick() -> void:
	var h: int = int(hour())
	if h == 0 and _cloche_h != 0 and objets.has("beffroi"):
		for k in range(12):
			get_tree().create_timer(k * 2.4).timeout.connect(func(): sfx("cloche_cathedrale", objets["beffroi"], -4.0))
	_cloche_h = h


# ------------------------------------------------------------------- les groupes de morts-vivants

func _manager() -> Node:
	return main.get("monstres_v36")


func _alive(arr: Array) -> int:
	var n: int = 0
	for m in arr:
		if is_instance_valid(m) and str(m.state) != "mort":
			n += 1
	return n


func zombies_vivants() -> int:
	var n: int = 0
	for id in _hordes:
		n += _alive((_hordes[id] as Dictionary)["monstres"])
	for e in _derriere:
		if is_instance_valid(e[0]) and str(e[0].state) != "mort":
			n += 1
	return n


func _hordes_tick(p: Vector3) -> void:
	var mg: Node = _manager()
	if mg == null or not mg.has_method("spawn_extra"):
		return
	var l: Vector2 = IleScript.L(p.x, p.z)
	var total: int = zombies_vivants()
	for h in HORDES:
		var id: String = str(h[0])
		var c: Vector2 = h[1]
		var dist: float = l.distance_to(c)
		var st: Dictionary = _hordes.get(id, {"monstres": [], "vide_t": -1.0})
		_hordes[id] = st
		var arr: Array = st["monstres"]
		arr = arr.filter(func(m): return is_instance_valid(m))
		st["monstres"] = arr
		if not arr.is_empty():
			# trop loin : on les range (ils reviendront)
			if dist > float(h[2]) + 110.0:
				var chasing: bool = false
				for m in arr:
					if str(m.state) in ["chasse", "armer", "frappe"]:
						chasing = true
				if not chasing:
					for m2 in arr:
						if str(m2.state) != "mort":
							m2.queue_free()
					st["monstres"] = []
			elif _alive(arr) == 0 and float(st["vide_t"]) < 0.0:
				st["vide_t"] = _clock
			continue
		if dist > float(h[2]) + 25.0 or dist < 12.0:
			continue
		if float(st["vide_t"]) >= 0.0 and _clock - float(st["vide_t"]) < REVIENT_S:
			continue
		if total >= MAX_ZOMBIES:
			continue
		var spawned: Array = []
		for z in h[3]:
			var fl: Vector2 = _free_spot(float(z[1]), float(z[2]))
			var at: Vector3 = _ground(fl.x, fl.y) + Vector3.UP * 0.3
			var m: Node3D = mg.spawn_extra(str(z[0]), at)
			if m == null:
				continue
			m.set("home", at)
			if bool(z[3]):
				m.call("lie_down")
			else:
				m.set("state", "veille")
			m.died.connect(_on_zombie_died)
			spawned.append(m)
			total += 1
		st["monstres"] = spawned
		st["vide_t"] = -1.0


## Un point libre (pas dans un immeuble) près de (x, z), repère île
func _free_spot(x: float, z: float) -> Vector2:
	for r in range(0, 14):
		for k in range(maxi(1, r * 6)):
			var a: float = TAU * k / maxf(1.0, r * 6.0)
			var p := Vector2(x, z) + Vector2(cos(a), sin(a)) * r * 2.0
			if not _blocked.has(Vector2i(int(floor(p.x / 2.0)), int(floor(p.y / 2.0)))):
				return p
	return Vector2(x, z)


func _on_zombie_died(_m: Node3D) -> void:
	state["vaincus"] = int(state.get("vaincus", 0)) + 1
	var n: int = int(state["vaincus"])
	if n == 10:
		say("Dix morts-vivants repoussés… mais il en revient toujours. Tant que le comte règnera sur Sombreval, ils ne s'arrêteront pas.", 7.0)


# ------------------------------------------------------------------- la peur

func _cam() -> Node3D:
	if bool(main.get("xr_active")) and main.get("xr_camera") != null:
		return main.xr_camera
	var c: Node = main.get("pc_camera")
	if c is Node3D:
		return c
	var vp: Camera3D = get_viewport().get_camera_3d()
	return vp


## Un mort-vivant arrive dans ton dos : il apparaît hors de ta vue, à quelques mètres, il approche
## sans un bruit… puis il grogne, tout près. Le cœur bat de plus en plus fort quand ils approchent.
func _peur_tick(delta: float, p: Vector3) -> void:
	var mg: Node = _manager()
	if mg == null:
		return
	var feet: Vector3 = p - (Vector3.UP * 1.5 if bool(main.get("xr_active")) else Vector3.ZERO)
	var cam: Node3D = _cam()
	var fwd: Vector3 = Vector3(0, 0, -1)
	if cam != null:
		fwd = -cam.global_basis.z
	fwd.y = 0.0
	fwd = fwd.normalized() if fwd.length() > 0.01 else Vector3(0, 0, -1)
	# le cœur qui bat
	var nearest: float = INF
	for m in get_tree().get_nodes_in_group("monstres_v36"):
		if not is_instance_valid(m) or not (m is Node3D) or not SPEC_OK(m):
			continue
		if str(m.state) in ["mort", "gisant"]:
			continue
		nearest = minf(nearest, (m as Node3D).global_position.distance_to(feet))
	_coeur_t -= delta
	if nearest < 9.0 and _coeur_t <= 0.0:
		_coeur_t = lerpf(0.55, 1.1, clampf((nearest - 2.0) / 7.0, 0.0, 1.0))
		sfx("coeur_peur", null, lerpf(0.0, -9.0, clampf((nearest - 2.0) / 7.0, 0.0, 1.0)))
	# ceux qui viennent par-derrière : quand ils sont tout près, un grognement et un frisson
	for e in _derriere:
		var zm: Node3D = e[0]
		if not is_instance_valid(zm) or bool(e[1]):
			continue
		var to: Vector3 = zm.global_position - feet
		to.y = 0.0
		if to.length() < 3.2 and fwd.dot(to.normalized()) < 0.2:
			e[1] = true
			sfx("zombie_grogne", zm.global_position + Vector3.UP * 1.6, 6.0)
			haptique(0.55, 0.25)
	_derriere = _derriere.filter(func(e2): return is_instance_valid(e2[0]))
	_peur_t -= delta
	if _peur_t > 0.0:
		return
	_peur_t = _rng.randf_range(30.0, 60.0) * (0.7 if hour() >= 20.0 or hour() < 5.0 else 1.0)
	if zombies_vivants() >= MAX_ZOMBIES + 2:
		return
	# pas pendant un dialogue, ni dans une maison
	if main.get("dialogue_v31") != null and main.dialogue_v31 != null and bool(main.dialogue_v31.opened):
		return
	for k in range(10):
		var a: float = _rng.randf_range(-0.6, 0.6)
		var dir: Vector3 = (-fwd).rotated(Vector3.UP, a)
		var at: Vector3 = feet + dir * _rng.randf_range(7.0, 11.0)
		var l: Vector2 = IleScript.L(at.x, at.z)
		if _blocked.has(Vector2i(int(floor(l.x / 2.0)), int(floor(l.y / 2.0)))):
			continue
		var h: float = ile.height(at.x, at.z)
		if h < 0.3 or absf(h - feet.y) > 1.6:
			continue
		at.y = h + 0.3
		var kind: String = "zombie_coureur" if _rng.randf() < (0.45 if hour() >= 20.0 or hour() < 5.0 else 0.25) else "zombie"
		var m: Node3D = mg.spawn_extra(kind, at)
		if m == null:
			return
		m.set("home", at)
		m.set("state", "chasse")
		m.set("_seen121", true)
		m.set("_groan121", 9.0)
		m.died.connect(_on_zombie_died)
		_derriere.append([m, false])
		return


static func SPEC_OK(m: Node) -> bool:
	return str(m.get("kind")).begins_with("zombie")


# =================================================================== sauvegarde, trouvailles

func trouvailles() -> Dictionary:
	var vis: Dictionary = state.get("visites", {})
	return {"sombreval": 1 if bool(state.get("visite", false)) else 0,
		"sv_beffroi": 1 if bool(state.get("beffroi", false)) else 0,
		"sv_zombies": 1 if int(state.get("vaincus", 0)) >= 10 else 0,
		"sv_notes": 1 if (state.get("notes", {}) as Dictionary).size() >= NOTES.size() else 0,
		"sv_cimetiere": 1 if bool(state.get("cimetiere", false)) else 0,
		"sv_butte": 1 if bool(vis.get("butte", false)) else 0,
		"sv_porte": 1 if bool(state.get("porte", false)) else 0}


func serialize() -> Dictionary:
	return state.duplicate(true)


func load_data(d: Dictionary) -> void:
	state = _fresh_state()
	for k in state:
		if d.has(k):
			state[k] = d[k] if not (d[k] is Dictionary) else (d[k] as Dictionary).duplicate(true)
	# les pages déjà lues ne sont plus par terre
	for id0 in _note_mi:
		if is_instance_valid(_note_mi[id0]):
			(_note_mi[id0] as Node3D).visible = not (state["notes"] as Dictionary).has(id0)
	for id in _hordes:
		for m in (_hordes[id] as Dictionary)["monstres"]:
			if is_instance_valid(m):
				m.queue_free()
	_hordes.clear()
	for e in _derriere:
		if is_instance_valid(e[0]):
			e[0].queue_free()
	_derriere.clear()
