extends RefCounted
## V181 : le grand contrôle des bugs visuels, les gens assis dehors. Sur les places, aux terrasses, au bord
## des quais, beaucoup d'habitants s'asseyaient… dans le vide : leur lieu était à côté du banc (devant, ou
## derrière), à côté de la chaise, ou il n'y avait rien pour s'asseoir. L'audit des lieux
## (tests/outils/audit_dehors.py --lieux) a regardé chaque lieu où l'on s'assied et dit quoi faire
## (assises_table_v181.gd, qu'il écrit : --assises) :
##   - « siege » : un banc, une chaise, un rondin, une caisse tout près : on y glisse le bassin ;
##   - « bord » : le bord du quai, de la jetée devant soi : on s'y assied, les jambes dans le vide ;
##   - « tabouret » : rien pour s'asseoir : les pieds au sol, et l'on pose un siège sous le bassin (un
##     tabouret, une caisse, une souche, un pouf, un bloc de pierre : selon la ville).
## pnj_azur_v56._arrive l'appelle quand un habitant arrive à un lieu où il s'assied.

const Table = preload("res://scripts/pnj/assises_table_v181.gd")
const BOIS := "res://assets/textures/beau163/bois_flotte"
const PLANCHES := "res://assets/textures/beau165/planches_pirate"
const ECORCE := "res://assets/textures/beau164/ecorce_buche"
const PIERRE := "res://assets/textures/beau163/pierre_fine"
const KILIM := "res://assets/textures/beau175/kilim"
const LIN := "res://assets/textures/beau161/toile_lin"

## Le siège de chaque ville, quand il faut en poser un (par le nom du script de la ville).
const STYLE := {
	"tazira_v60.gd": "pouf_kilim", "grande_v59.gd": "tabouret", "cliquetis_v61.gd": "tabouret", "carene_v59.gd": "caisse",
	"ramure_v62.gd": "souche", "arcanelle_v67.gd": "tabouret", "pirates_v68.gd": "caisse", "port_coutelas_v68.gd": "caisse",
	"soleils_v69.gd": "pierre", "braise_v70.gd": "pierre", "pandemonia_v70.gd": "pierre", "montjoie_v71.gd": "tabouret",
	"boucan_v75.gd": "caisse", "astrale_v76.gd": "pierre", "larsen_ville_v92.gd": "souche", "neo_ville_v95.gd": "pouf_lin",
	"pasta_ville_v98.gd": "tabouret", "crayon_vie_v101.gd": "tabouret", "hautefond_v112.gd": "tabouret",
	"perchee_v146.gd": "tabouret", "azur_v56.gd": "tabouret",
}

## Les retouches à la main (elles passent avant la table de l'audit) : les bancs du Dôme d'Azur et du ponton
## des Nuées (leur lieu était sur l'assise : assis 45 cm trop haut ; l'audit ne voit pas ces bancs, pris
## dans un très grand maillage) ; null : le lieu a été corrigé dans le script de sa ville (le quai de
## Cliquetis, la jetée de Tazira), ou il va bien tel quel (le feu de la grève : sur le rondin).
const RETOUCHES := {
	"hautefond_v112.gd:da_gare_banc_1": ["siege", 0.0, -0.27, 0.0], "hautefond_v112.gd:da_gare_banc_2": ["siege", 0.0, -0.27, 0.0],
	"hautefond_v112.gd:da_ecole_banc_1": ["siege", 0.0, -0.27, 0.0], "hautefond_v112.gd:da_ecole_banc_2": ["siege", 0.0, -0.27, 0.0],
	"hautefond_v112.gd:ponton_banc": ["siege", 0.0, -0.35, 0.0],
	"cliquetis_v61.gd:port_peche_1": null, "cliquetis_v61.gd:port_peche_2": null,
	"tazira_v60.gd:jetee_peche_1": null, "tazira_v60.gd:jetee_peche_2": null,
	"pirates_v68.gd:feu_greve_1": null,
}

static var actif: bool = true             # faux : l'audit regarde les lieux tels qu'ils sont écrits
static var _poses: Dictionary = {}        # les sièges déjà posés (une fois par lieu)
static var _mats: Dictionary = {}


## La correction du lieu « lieu » de la ville « ville » (rien si ce lieu va bien) : on déplace l'habitant,
## et l'on pose le tabouret s'il le faut. Rend vrai si l'on a corrigé quelque chose.
static func corriger(npc: Node3D, ville: Object, lieu: String) -> bool:
	if not actif or ville == null or ville.get_script() == null:
		return false
	var nom_ville: String = (ville.get_script() as Script).resource_path.get_file()
	var cle: String = nom_ville + ":" + lieu
	var e: Array = []
	if RETOUCHES.has(cle):
		if RETOUCHES[cle] == null:
			return false
		e = RETOUCHES[cle]
	elif Table.TABLE.has(cle):
		e = Table.TABLE[cle]
	else:
		return false
	npc.global_position += Vector3(float(e[1]), float(e[2]), float(e[3]))
	if str(e[0]) == "tabouret" and e.size() > 7:
		if not _poses.has(cle) or not is_instance_valid(_poses[cle]):
			var parent: Node = ville as Node if ville is Node3D else npc.get_parent()
			_poses[cle] = siege(parent, Vector3(float(e[4]), float(e[5]), float(e[6])), float(e[7]), style(nom_ville, lieu), npc.rotation.y)
	return true


## Le siège qu'on pose : autour d'un feu, une souche ; sur un quai, un pont, une caisse ; ailleurs, celui de
## la ville.
static func style(nom_ville: String, lieu: String) -> String:
	if lieu.contains("feu"):
		return "souche"
	if lieu.contains("quai") or lieu.contains("pont") or lieu.contains("cargo") or lieu.contains("jetee"):
		return "caisse"
	return str(STYLE.get(nom_ville, "tabouret"))


## Un siège posé au sol en « bas » (le haut du siège à « haut » au-dessus), tourné de « lacet ».
static func siege(parent: Node, bas: Vector3, haut: float, style: String, lacet: float) -> Node3D:
	var s := Node3D.new()
	s.name = "Assise_posee"
	parent.add_child(s, true)
	s.global_position = bas
	s.rotation.y = lacet
	haut = clampf(haut, 0.2, 0.75)
	match style:
		"caisse":
			# une caisse de planches, ses montants d'angle plus sombres
			_bloc(s, "boite", Vector3(0.48, haut, 0.4), Vector3(0, haut * 0.5, 0), _mat(PLANCHES, Color(0.85, 0.75, 0.62)))
			for sx in [-1.0, 1.0]:
				for sz in [-1.0, 1.0]:
					_bloc(s, "boite", Vector3(0.05, haut + 0.005, 0.05), Vector3(sx * 0.225, haut * 0.5, sz * 0.18), _mat(PLANCHES, Color(0.55, 0.45, 0.35)))
		"souche":
			# une souche, l'écorce autour, le bois clair dessus
			_bloc(s, "cylindre", Vector3(0.2, haut - 0.01, 0.22), Vector3(0, (haut - 0.01) * 0.5, 0), _mat(ECORCE, Color(1, 1, 1)))
			_bloc(s, "cylindre", Vector3(0.19, 0.012, 0.19), Vector3(0, haut - 0.006, 0), _mat(BOIS, Color(1.0, 0.9, 0.75)))
		"pierre":
			# un bloc de pierre taillée
			_bloc(s, "boite", Vector3(0.5, haut, 0.38), Vector3(0, haut * 0.5, 0), _mat(PIERRE, Color(0.92, 0.88, 0.8)))
		"pouf_kilim", "pouf_lin":
			# un pouf rond, son coussin un peu bombé
			var tissu: String = KILIM if style == "pouf_kilim" else LIN
			var mt: Material = _mat(tissu, Color(1, 1, 1) if style == "pouf_kilim" else Color(0.75, 0.78, 0.82))
			_bloc(s, "cylindre", Vector3(0.23, haut - 0.04, 0.24), Vector3(0, (haut - 0.04) * 0.5, 0), mt)
			_bloc(s, "sphere", Vector3(0.23, 0.05, 0.23), Vector3(0, haut - 0.04, 0), mt)
		_:
			# un tabouret de bois : l'assise ronde, trois pieds écartés, un barreau
			var mb: Material = _mat(BOIS, Color(0.9, 0.78, 0.62))
			_bloc(s, "cylindre", Vector3(0.18, 0.04, 0.18), Vector3(0, haut - 0.02, 0), mb)
			for k in range(3):
				var a: float = TAU * k / 3.0
				var haut_p := Vector3(cos(a) * 0.1, haut - 0.04, sin(a) * 0.1)
				var bas_p := Vector3(cos(a) * 0.17, 0.0, sin(a) * 0.17)
				var pied := _bloc(s, "cylindre", Vector3(0.018, haut_p.distance_to(bas_p), 0.022), (haut_p + bas_p) * 0.5, mb)
				pied.basis = Basis(Quaternion(Vector3.UP, (haut_p - bas_p).normalized()))
	return s


## Un morceau : taille = (rayon du haut, hauteur, rayon du bas) pour un cylindre ; (rayon, demi-hauteur,
## rayon) pour une sphère ; (x, y, z) pour une boîte.
static func _bloc(parent: Node3D, sorte: String, taille: Vector3, pos: Vector3, m: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	if sorte == "cylindre":
		var c := CylinderMesh.new()
		c.top_radius = taille.x
		c.height = taille.y
		c.bottom_radius = taille.z
		c.radial_segments = 14
		c.rings = 1
		mi.mesh = c
	elif sorte == "sphere":
		var sp := SphereMesh.new()
		sp.radius = taille.x
		sp.height = taille.y * 2.0
		sp.radial_segments = 16
		sp.rings = 6
		mi.mesh = sp
	else:
		var b := BoxMesh.new()
		b.size = taille
		mi.mesh = b
	mi.material_override = m
	mi.position = pos
	parent.add_child(mi)
	return mi


static func _mat(tex: String, teinte: Color) -> Material:
	var cle: String = tex + str(teinte)
	if _mats.has(cle):
		return _mats[cle]
	var m := StandardMaterial3D.new()
	m.albedo_color = teinte
	m.roughness = 0.85
	if ResourceLoader.exists(tex + ".png"):
		m.albedo_texture = load(tex + ".png")
		m.uv1_triplanar = true
		m.uv1_scale = Vector3(1.6, 1.6, 1.6)
	if ResourceLoader.exists(tex + "_n.png"):
		m.normal_enabled = true
		m.normal_texture = load(tex + "_n.png")
	_mats[cle] = m
	return m
