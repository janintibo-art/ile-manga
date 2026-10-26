extends "res://scripts/enigmes_v69.gd"
## V75 : l'Usine Grise, le donjon sous l'usine de Lisse & Fils (au sud-est de l'Île du Boucan).
## Monsieur Lisse y fabrique ses robots déménageurs ; tout en bas, son ordinateur OPTIMUS-LISSE
## pilote la Grande Pelleteuse. Cinq étages, de plus en plus bas :
##  1. les Bureaux : un open-space gris (bureaux en rangs, plantes en plastique, fontaine à eau,
##     photocopieuses, affiches absurdes) ; des drones-huissiers ; l'énigme des tampons : trois
##     formulaires (bleu, jaune, rose) à tamponner dans l'ordre de la note de service (« le ciel
##     avant le soleil, le soleil avant la barbe à papa ») pour ouvrir le tourniquet ; sinon, la
##     photocopieuse imprime « FORMULAIRE REFUSÉ » et tout recommence ;
##  2. la Chaîne de Montage : une fosse (le bac des pièces détachées), trois tapis roulants qui
##     emportent le joueur, trois leviers d'aiguillage (câblés n'importe comment par le stagiaire),
##     des bras robots qui assemblent des robots déménageurs (certains se réveillent) ;
##  3. la Chaufferie : un couloir en lacets, des jets de vapeur qui soufflent en rythme (ils
##     repoussent et piquent un peu : on passe entre deux bouffées), des robots soudeurs ; trois
##     vannes à tourner pour faire baisser la pression et ouvrir la porte ;
##  4. l'Entrepôt Automatique : de hauts rayonnages, des chariots élévateurs robots (ils passent,
##     klaxonnent et bousculent), des caisses à pousser (une case de 2 m par poussée) pour monter
##     sur le quai de chargement, puis sur la mezzanine où dort le badge de l'usine ; le badge
##     ouvre la porte du bas ;
##  5. la Fosse du Président : une arène sous le bureau vitré de Monsieur Lisse, le grand écran
##     d'OPTIMUS-LISSE (il parle !), la Grande Pelleteuse ; les Plans du Lisse-Center, 200 pièces,
##     un titre, un cœur, puis le monte-charge vers la surface.
## À chaque étage, un terminal de sortie (E : remonter au portail de l'usine). L'étage le plus
## profond atteint est noté (state["profond"]) ; à l'accueil, l'ascenseur de service y descend
## directement (dès l'étage 2).
## Repère : O, loin sous l'île (y < -40 : « sous terre » pour donjon_v35) ; l'étage k est à
## y = -14 × (k - 1) (local) ; les escaliers de service sont tous en x = 12, de 4 m de large.
## Le gestionnaire de l'île (boucan_v75) : setup(main, bo), enter(), contains(p), near(p),
## ensure_built(), respawn(), register(journal), serialize(), load_data(d), state, room, fight ;
## et, pour lui : trouvailles(), music(), ambience(), deepest(), tour_shot(m, plan).

const T := 0.8
const IC := Vector3(-30.0, 0.0, 790.0)          # le centre de l'Île du Boucan (monde)
const TB := "res://assets/textures/boucan/"
## l'étage de chaque salle (les escaliers comptent pour l'étage du haut)
const FLOOR := {"accueil": 1, "bureaux": 1, "esc1": 1, "chaine": 2, "esc2": 2, "chaufferie": 3, "esc3": 3,
	"entrepot": 4, "esc4": 4, "fosse": 5}
const FLOOR_NAMES := ["", "les Bureaux", "la Chaîne de Montage", "la Chaufferie", "l'Entrepôt Automatique", "la Fosse du Président"]
## l'arrivée de chaque étage (au pied de l'escalier), le terminal de sortie [position, regard]
const ARRIVE := [Vector3(0, 0, 3.0), Vector3(0, 0, 3.0), Vector3(12, -14, 80.5), Vector3(12, -28, 152.5), Vector3(12, -42, 226.5), Vector3(12, -56, 302.5)]
const TERMINALS := [[Vector3.ZERO, Vector3(0, 0, 1)], [Vector3(5.6, 0, 12.4), Vector3(0, 0, -1)], [Vector3(6.6, -14, 79.4), Vector3(0, 0, 1)],
	[Vector3(6.6, -28, 151.0), Vector3(0, 0, 1)], [Vector3(6.6, -42, 225.4), Vector3(0, 0, 1)], [Vector3(6.6, -56, 301.4), Vector3(0, 0, 1)]]
const ELEVATOR := Vector3(-7.95, 0, 8.5)
## les Bureaux : les trois formulaires [bureau, couleur, nom, service], l'ordre de la note de service
const FORMS := [[Vector3(10.5, 0, 32.0), "bleu", "la Demande de demande", "SERVICE DES DEMANDES DE DEMANDES"],
	[Vector3(-5.0, 0, 44.0), "jaune", "l'Accusé de réception de la demande de demande", "BUREAU DES ACCUSÉS DE RÉCEPTION"],
	[Vector3(-16.0, 0, 20.0), "rose", "l'Autorisation de commencer à envisager d'autoriser", "CELLULE DES AUTORISATIONS ÉVENTUELLES"]]
const STAMP_ORDER := [0, 1, 2]
const DESK_X := [-16.0, -10.5, -5.0, 5.0, 10.5, 16.0]
const DESK_Z := [20.0, 26.0, 32.0, 38.0, 44.0]
const COPIERS := [Vector3(18.9, 0, 24.0), Vector3(18.9, 0, 38.0)]
const MEMO := Vector3(6.5, 0, 14.0)
## la Chaîne de Montage : la fosse, les tapis [x0, x1, z0, z1, sens « aller »], les plates-formes,
## les leviers (et les tapis que chacun bascule)
const PIT := -18.5
const BELT_V := 5.6
const BELTS := [[-14.2, -11.8, 86.0, 96.0, Vector3(0, 0, 1)], [-8.0, 8.0, 98.8, 101.2, Vector3(1, 0, 0)], [11.8, 14.2, 104.0, 114.0, Vector3(0, 0, 1)]]
const PLATS := [[-24.0, 24.0, 78.0, 86.0], [-18.0, -8.0, 96.0, 104.0], [8.0, 18.0, 96.0, 104.0], [-24.0, 24.0, 114.0, 122.0]]
const LEVER_LINKS := [[0], [0, 1], [1, 2]]
const LEVERS := [Vector3(-5.2, -14, 83.7), Vector3(-4.0, -14, 83.7), Vector3(-2.8, -14, 83.7)]
## la Chaufferie : les jets [x, z0, z1, couloir, décalage], les vannes [position au mur, vers la salle]
const JETS := [[4.0, 150.0, 161.6, 0, 0.0], [-6.0, 150.0, 161.6, 0, 1.5], [-6.0, 162.4, 175.6, 1, 0.0], [2.0, 162.4, 175.6, 1, 1.0],
	[10.0, 162.4, 175.6, 1, 2.0], [2.0, 176.4, 196.0, 2, 0.5], [-8.0, 176.4, 196.0, 2, 2.0]]
const JET_PERIOD := 3.0
const JET_ON := 1.2
const VALVES := [[Vector3(-19.95, -28, 156.0), Vector3(1, 0, 0)], [Vector3(23.95, -28, 169.0), Vector3(-1, 0, 0)], [Vector3(-19.95, -28, 186.0), Vector3(1, 0, 0)]]
## l'Entrepôt : la zone des caisses (cases de 2 m), les piles fixes, les caisses au départ, le quai
const GX0 := -18.0
const GZ0 := 240.0
const GC := 2.0
const GNI := 8
const GNJ := 12
const OBST := [Vector2i(1, 7), Vector2i(2, 9), Vector2i(1, 10), Vector2i(4, 4)]
const CRATES0 := [Vector2i(3, 7), Vector2i(5, 10), Vector2i(6, 3)]
const QUAI_J := [7, 8, 9, 10]
const BADGE_AT := Vector3(-21.0, -39.0, 268.0)
const RESET_BTN := Vector3(-1.0, -42, 237.5)
const FORKS := [[Vector3(12.0, -42, 233.0), Vector3(12.0, -42, 262.0), 0.0], [Vector3(0.5, -42, 248.0), Vector3(19.8, -42, 248.0), 4.0]]
## la Fosse : la Grande Pelleteuse, le monte-charge
const BOSS_AT := Vector3(12, -56, 324.0)
const LIFT := Vector3(28.0, -56, 305.0)
## en attendant que les monstres V75 soient branchés dans monstres_v36 : des remplaçants
const STANDIN := {"robot_demenageur": "automate", "drone_huissier": "chauve_souris", "robot_soudeur": "automate",
	"pelleteuse_mini": "colosse", "grande_pelleteuse": "colosse", "champignard": "slime"}
## les bruitages V75 et ceux qui les remplacent tant qu'ils manquent
const SND_FB := {"tampon_bureau": "guilde_tampon", "robot_bip": "bip", "robot_servo": "piston", "vanne": "levier", "porte_usine": "porte_donjon",
	"tourniquet": "levier", "photocopieuse": "bip", "alarme_usine": "alerte_cloche", "monte_charge": "porte_donjon", "durite": "vapeur",
	"tapis_roulant": "", "pelleteuse_cri": "boum", "pelleteuse_frappe": "onde_choc", "drone_zap": "tesla", "soudure": "tesla"}
const OPTIMUS_TAUNTS := ["« VOTRE COLÈRE A ÉTÉ ENREGISTRÉE. ELLE SERA TRAITÉE SOUS QUARANTE-HUIT MOIS. »",
	"« LE SAVIEZ-VOUS ? UN PARKING, C'EST UN JARDIN QUI A RÉUSSI. »",
	"« VEUILLEZ RESTER IMMOBILE POUR UNE DÉMOLITION PLUS CONFORTABLE. »",
	"« CONSEIL DU JOUR : LES DURITES QUI BRILLENT NE SONT PAS DES POINTS FAIBLES. (CECI EST UN MENSONGE.) »",
	"« CALCUL EN COURS… PROBABILITÉ DE VICTOIRE : 99,9 %. ARRONDIE À 100 %. ARRONDIE À 1 000 %. »",
	"« CE COMBAT VOUS EST OFFERT PAR LISSE & FILS. ON RASE. ON BÂTIT. ON ENCAISSE. »"]

var bo: Node                              # boucan_v75 (le gestionnaire de l'île)
var missing_tex: Array = []               # les textures boucan/ qui manquaient (remplacées)
var _shortcut_ia: Dictionary = {}
var _term_screens: Array = []             # Label3D des terminaux
var _ticket: int = 8431
# les Bureaux
var _stamps: Array = []                   # les formulaires tamponnés (dans l'ordre)
var _stamp_marks: Array = []              # MeshInstance3D : le « VU » rouge sur chaque formulaire
var _copier_sheets: Array = []            # Node3D : la feuille qui sort de chaque photocopieuse
var _turnstile_arm: Node3D
var _turnstile_lamp: StandardMaterial3D
var _cooler_used: bool = false
# la Chaîne
var _belt_mats: Array = []
var _lever_arms: Array = []
var _lever_lamps: Array = []              # [StandardMaterial3D] une lampe par tapis (synoptique)
var _synoptic: Label3D
var _arms: Array = []                     # [épaule, bras, avant-bras, phase, étincelles]
var _gears: Array = []
var _belt_snd: float = 0.0
var _on_belt: int = -1
# la Chaufferie
var _jet_fx: Array = []                   # CPUParticles3D par jet
var _jet_was: Array = []
var _jet_cd: float = 0.0
var _valve_wheels: Array = []
var _gauge_needle: Node3D
var _gauge_label: Label3D
var _boiler_lights: Array = []
# l'Entrepôt
var _crates: Array = []                   # StaticBody3D
var _crate_ia: Array = []
var _crate_busy: bool = false
var _badge_node: Node3D
var _reader_led: StandardMaterial3D
var _forks: Array = []                    # [AnimatableBody3D, a, b, phase, gyrophare]
var _fork_cd: float = 0.0
# la Fosse
var _screen_face: Node3D
var _screen_mouth: Node3D
var _screen_eyes: Array = []
var _screen_bsod: Node3D
var _screen_light: OmniLight3D
var _beacons: Array = []                  # [Node3D tournant, OmniLight3D]
var _lift_lamp: StandardMaterial3D
var _talk_t: float = 0.0
var _phase: int = 0
var _taunt_t: float = 0.0
var _strays_t: float = 0.0


func _init() -> void:
	key = "usine_grise"
	titre = "l'Usine Grise"
	O = Vector3(70.0, -90.0, 640.0)
	bbox = AABB(Vector3(-30.0, -62.0, -4.0), Vector3(66.0, 72.0, 350.0))
	room_spawns = {
		"bureaux": [[_k("drone_huissier"), -8.0, 0.0, 29.0], [_k("drone_huissier"), 8.0, 0.0, 23.0], [_k("drone_huissier"), 2.0, 0.0, 41.0]],
		"chaine": [[_k("robot_demenageur"), -2.0, -14.0, 82.5], [_k("robot_demenageur"), 18.0, -14.0, 82.5], [_k("robot_demenageur"), -13.0, -14.0, 101.5],
			[_k("robot_demenageur"), 13.0, -14.0, 101.0], [_k("robot_demenageur"), 0.0, -14.0, 118.0]],
		"chaufferie": [[_k("robot_soudeur"), -6.0, -28.0, 168.0], [_k("robot_soudeur"), 8.0, -28.0, 170.0], [_k("robot_soudeur"), -12.0, -28.0, 184.0],
			[_k("robot_soudeur"), 4.0, -28.0, 186.0]],
		"entrepot": [[_k("robot_demenageur"), 12.0, -42.0, 240.0], [_k("drone_huissier"), -8.0, -42.0, 232.0], [_k("robot_demenageur"), 20.0, -42.0, 256.0],
			[_k("pelleteuse_mini"), 1.0, -42.0, 262.0]],
	}


## Le nom d'une espèce de monstre : la vraie si monstre_v75 est là et branché dans monstres_v36,
## sinon un remplaçant (pour que le donjon reste jouable pendant le développement).
static func _k(kind: String) -> String:
	var route := "res://scripts/monstres_v36.gd"
	var path := "res://scripts/monstre_v75.gd"
	if ResourceLoader.exists(path) and ResourceLoader.exists(route):
		var rs: Script = load(route)
		var s: Script = load(path)
		if rs != null and s != null and rs.get_script_constant_map().has("Monster75"):
			for c in s.get_script_constant_map().values():
				if c is Dictionary and (c as Dictionary).has(kind) and (c as Dictionary)[kind] is Dictionary and ((c as Dictionary)[kind] as Dictionary).has("pv"):
					return kind
	return str(STANDIN.get(kind, kind))


func setup(main_node: Node, manager: Node) -> void:
	super.setup(main_node, manager)
	bo = manager


func _defaults() -> Dictionary:
	return {"profond": 0, "leviers": [false, false, false], "vannes": [false, false, false], "caisses": [], "badge": false}


func ensure_built() -> void:
	if built:
		return
	built = true
	var t0: int = Time.get_ticks_msec()
	kit = Kit.new()
	kit.setup69(self, main, pc)
	kit.body.name = "Collisions_donjon_" + key
	_own_materials()
	_build()
	_register()
	_apply_state()
	_hide_all(false)
	print("ILE_MANGA_V75: %s construit en %d ms (%d salles)%s" % [titre, Time.get_ticks_msec() - t0, rooms.size(),
		"" if missing_tex.is_empty() else " ; textures boucan/ absentes (remplacées) : " + ", ".join(missing_tex)])


func entry() -> Array:
	return [W(ARRIVE[1]), Vector3(0, 0, 1)]


## On ressort devant le portail de l'usine grise, dans le sens que donne le dehors.
func exit_point() -> Array:
	var dh: Node = bo.get("dehors") if bo != null else null
	var dd: Variant = dh.get("dungeon_door") if dh != null else null
	var df: Variant = dh.get("dungeon_face") if dh != null else null
	if not (dd is Vector3) or dd == Vector3.ZERO:
		return [IC + Vector3(112.0, 4.0, 100.0), Vector3(0, 0, -1)]
	var face := Vector3(0, 0, -1)
	if df is Vector3 and Vector3((df as Vector3).x, 0, (df as Vector3).z).length() > 0.01:
		face = Vector3((df as Vector3).x, 0, (df as Vector3).z).normalized()
	return [(dd as Vector3) + face * 1.2 + Vector3.UP * 0.1, face]


func deepest() -> int:
	return int(state.get("profond", 0))


## Pour la musique : l'usine, ou le combat contre la Grande Pelleteuse.
func music() -> String:
	return "grande_pelleteuse" if fight else "usine_grise"


## Pour les ambiances : les machines de l'usine (partout).
func ambience() -> String:
	return "usine"


## Ce que le carnet (journal_v56, quêtes « etat ») et la carte doivent savoir.
func trouvailles() -> Dictionary:
	return {"usine_grise_visite": 1 if bool(state["visite"]) else 0, "usine_grise": 1 if bool(state["fini"]) else 0,
		"grande_pelleteuse": 1 if bool(state["boss"]) else 0, "usine_2": 1 if deepest() >= 2 else 0, "usine_3": 1 if deepest() >= 3 else 0,
		"usine_4": 1 if deepest() >= 4 else 0, "usine_5": 1 if deepest() >= 5 else 0,
		"usine_tampons": 1 if gate_open("bureaux") else 0, "usine_vannes": 1 if gate_open("chaufferie") else 0,
		"badge_usine": 1 if bool(state["badge"]) else 0}


func register(journal: Node) -> void:
	journal.lieux["usine_grise"] = W(ARRIVE[1])


# =================================================================== matières

func _tex75(path: String) -> Texture2D:
	return load(path) if ResourceLoader.exists(path) else null


## Une matière texturée de Port-Boucan (boucan/<nom>.png et <nom>_n.png) ; si elle manque encore :
## une texture voisine d'une autre île (teintée) ou une image faite ici (gen).
func _surf(k: String, name: String, tint: Color, rough: float, fb: String, fb_tint: Color, metal: float = 0.0, nscale: float = 1.0, gen: Texture2D = null) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	var tex: Texture2D = _tex75(TB + name + ".png")
	var nrm: Texture2D = _tex75(TB + name + "_n.png")
	if tex == null:
		if not missing_tex.has(name):
			missing_tex.append(name)
		if gen != null:
			tex = gen
		elif fb != "":
			tex = _tex75("res://assets/textures/" + fb + ".png")
			nrm = _tex75("res://assets/textures/" + fb + "_n.png")
		m.albedo_color = fb_tint
	else:
		m.albedo_color = tint
	m.albedo_texture = tex
	if nrm != null:
		m.normal_enabled = true
		m.normal_texture = nrm
		m.normal_scale = nscale
	m.roughness = rough
	m.metallic = metal
	kit.mats[k] = m
	return m


func _flat(k: String, c: Color, rough: float, metal: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	kit.mats[k] = m
	return m


func _glowm(k: String, c: Color, energy: float, base: Color = Color(0, 0, 0, 0)) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = base if base.a > 0.0 else c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	m.roughness = 0.3
	kit.mats[k] = m
	return m


## Des images faites ici (en attendant les textures, ou pour les rayures de sécurité).
func _gen(kind: String) -> ImageTexture:
	var n: int = 128
	var img := Image.create(n, n, false, Image.FORMAT_RGB8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7500 + kind.length() * 31
	for y in range(n):
		for x in range(n):
			var c := Color(0.5, 0.5, 0.5)
			match kind:
				"moquette":
					var v: float = 0.34 + rng.randf() * 0.12 + (0.03 if (((x >> 1) + (y >> 1)) & 1) == 0 else 0.0)
					c = Color(v * 0.85, v * 0.9, v * 1.06)
				"plafond":
					var edge: bool = (x & 63) < 2 or (y & 63) < 2
					var v2: float = 0.88 - rng.randf() * 0.05 - (0.1 if rng.randf() < 0.04 else 0.0)
					c = Color(0.5, 0.5, 0.52) if edge else Color(v2, v2, v2 * 0.98)
				"tapis":
					var rib: bool = (y & 15) < 4
					var v3: float = (0.15 if rib else 0.08) + rng.randf() * 0.03
					c = Color(v3, v3, v3 * 1.05)
				"hachures":
					var s: bool = (((x + y) >> 5) & 1) == 0
					c = (Color(0.95, 0.72, 0.08) if s else Color(0.06, 0.06, 0.06)).darkened(rng.randf() * 0.12)
			img.set_pixel(x, y, c)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


func _own_materials() -> void:
	_surf("beton75u", "beton_usine", Color(1, 1, 1), 0.92, "braise/cendre", Color(0.86, 0.86, 0.85), 0.0, 1.0)
	_surf("betonc75u", "beton_usine", Color(1.08, 1.08, 1.1), 0.9, "braise/cendre", Color(1.0, 1.0, 1.02), 0.0, 0.6)
	_surf("brut75u", "beton_brut", Color(1, 1, 1), 0.95, "azur/calcaire", Color(0.62, 0.62, 0.62), 0.0, 1.0)
	_surf("moquette75u", "moquette_bureau", Color(1, 1, 1), 0.98, "", Color(1, 1, 1), 0.0, 1.0, _gen("moquette"))
	_surf("plafond75u", "faux_plafond", Color(1, 1, 1), 0.9, "", Color(1, 1, 1), 0.0, 0.5, _gen("plafond"))
	_surf("carrelage75u", "carrelage_bureau", Color(1, 1, 1), 0.4, "coeur/dalles", Color(0.88, 0.89, 0.9), 0.0, 0.6)
	_surf("carrelageu75u", "carrelage_usine", Color(1, 1, 1), 0.7, "azur/dalles", Color(0.58, 0.58, 0.58), 0.0, 1.0)
	_surf("rivete75u", "metal_rivete", Color(1, 1, 1), 0.5, "coeur/tapis", Color(1, 1, 1), 0.6, 1.0)
	_surf("rouille75u", "acier_rouille", Color(1, 1, 1), 0.75, "cliquetis/fonte", Color(1.0, 0.9, 0.82), 0.4, 1.0)
	_surf("tole75u", "tole_peinte", Color(1, 1, 1), 0.6, "coeur/tapis", Color(0.55, 0.62, 0.7), 0.3, 1.0)
	_surf("tapis75u", "tapis_roulant", Color(1, 1, 1), 0.85, "", Color(1, 1, 1), 0.0, 1.0, _gen("tapis"))
	_belt_mats.clear()
	for i in range(3):
		var bm: StandardMaterial3D = (kit.mats["tapis75u"] as StandardMaterial3D).duplicate()
		kit.mats["tapis75u_%d" % i] = bm
		_belt_mats.append(bm)
	var ha := StandardMaterial3D.new()
	ha.albedo_texture = _gen("hachures")
	ha.roughness = 0.6
	kit.mats["hachures75u"] = ha
	var wood: Texture2D = _tex75("res://assets/textures/interior/floor.png")
	var bw := _flat("bois75u", Color(0.95, 0.85, 0.7) if wood != null else Color(0.62, 0.48, 0.32), 0.85)
	bw.albedo_texture = wood
	_flat("acier75u", Color(0.56, 0.58, 0.6), 0.32, 0.85)
	_flat("jaune75u", Color(0.92, 0.68, 0.06), 0.5, 0.1)
	_flat("rouge75u", Color(0.68, 0.07, 0.05), 0.45, 0.1)
	_flat("bleu75u", Color(0.1, 0.26, 0.58), 0.5, 0.3)
	_flat("orange75u", Color(0.93, 0.4, 0.05), 0.45, 0.2)
	_flat("noir75u", Color(0.045, 0.045, 0.05), 0.55)
	_flat("blanc75u", Color(0.86, 0.86, 0.84), 0.35)
	_flat("gris75u", Color(0.6, 0.61, 0.62), 0.5)
	_flat("grisf75u", Color(0.3, 0.31, 0.33), 0.6)
	_flat("papier75u", Color(0.94, 0.94, 0.9), 0.9)
	_flat("papier_bleu75u", Color(0.45, 0.66, 0.98), 0.9)
	_flat("papier_jaune75u", Color(0.98, 0.86, 0.3), 0.9)
	_flat("papier_rose75u", Color(0.98, 0.58, 0.74), 0.9)
	_flat("encre75u", Color(0.8, 0.05, 0.08), 0.7)
	_flat("plante75u", Color(0.15, 0.48, 0.17), 0.22)
	_flat("pot75u", Color(0.82, 0.82, 0.8), 0.4)
	_flat("carton75u", Color(0.62, 0.46, 0.28), 0.95)
	_flat("caoutchouc75u", Color(0.06, 0.06, 0.06), 0.9)
	_flat("cuivre75u", Color(0.72, 0.42, 0.24), 0.35, 0.85)
	_flat("liege75u", Color(0.62, 0.45, 0.28), 0.95)
	var sc := _flat("ecran75u", Color(0.02, 0.02, 0.025), 0.12)
	sc.metallic_specular = 0.9
	_glowm("ecranon75u", Color(0.32, 0.55, 0.95), 0.9, Color(0.1, 0.16, 0.26))
	_glowm("neon75u", Color(0.92, 0.96, 1.0), 3.2)
	_glowm("vert75u", Color(0.2, 1.0, 0.35), 2.4)
	_glowm("rougeon75u", Color(1.0, 0.1, 0.06), 3.0)
	_glowm("braise75u", Color(1.0, 0.45, 0.1), 3.5)
	_glowm("jour75u", Color(0.95, 0.97, 1.0), 1.4)
	_glowm("term75u", Color(0.15, 0.85, 0.35), 1.2, Color(0.02, 0.08, 0.04))
	_glowm("optimus75u", Color(1.0, 0.06, 0.04), 4.0)
	_glowm("bsod75u", Color(0.08, 0.28, 0.95), 1.8)
	_glowm("gyro75u", Color(1.0, 0.55, 0.05), 3.0)
	var gl := _flat("verre75u", Color(0.7, 0.82, 0.88, 0.22), 0.04)
	gl.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gl.metallic_specular = 0.9
	gl.cull_mode = BaseMaterial3D.CULL_DISABLED
	var wa := _flat("eau75u", Color(0.5, 0.72, 1.0, 0.5), 0.05)
	wa.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA


# =================================================================== outils

func _xf() -> Transform3D:
	return Transform3D(Basis(), O)


func _root(n: String) -> Node3D:
	return rooms[n]["root"]


func _m(k: String) -> Material:
	return kit.mat(k)


func _block(a: Vector3, b: Vector3, k: String, tile: float = 3.0) -> void:
	kit.solid(X((a + b) * 0.5), (b - a).abs(), k, tile)


func _deco(a: Vector3, b: Vector3, k: String, tile: float = 2.0) -> void:
	kit.box(X((a + b) * 0.5), (b - a).abs(), k, tile)


## Une boîte dans un repère (xf : un repère du monde), centrée en p (local).
func _bx(xf: Transform3D, p: Vector3, s: Vector3, k: String, tile: float = 1.0) -> void:
	kit.box(xf * Transform3D(Basis(), p), s, k, tile)


func _cy(xf: Transform3D, p: Vector3, r0: float, r1: float, h: float, k: String, seg: int = 12) -> void:
	kit.cyl(xf * Transform3D(Basis(), p), r0, r1, h, k, seg, true, 1.0)


## Un tube (cylindre) de a à b (local).
func _tube(a: Vector3, b: Vector3, r: float, k: String, seg: int = 10) -> void:
	var d: Vector3 = b - a
	var ln: float = d.length()
	if ln < 0.001:
		return
	var y: Vector3 = d / ln
	var x: Vector3 = y.cross(Vector3.UP if absf(y.y) < 0.95 else Vector3.RIGHT).normalized()
	var z: Vector3 = x.cross(y)
	kit.cyl(Transform3D(Basis(x, y, z), W(a)), r, r, ln, k, seg, false, 1.0)


func _mesh(parent: Node3D, mesh: Mesh, k: String, pos: Vector3, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = _m(k)
	parent.add_child(mi)
	mi.position = pos
	mi.rotation = rot
	return mi


func _sphere(r: float, h: float = -1.0) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = h if h > 0.0 else r * 2.0
	s.radial_segments = 18
	s.rings = 9
	return s


func _cylm(r0: float, r1: float, h: float, seg: int = 14) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = r1
	c.bottom_radius = r0
	c.height = h
	c.radial_segments = seg
	return c


func _boxm(s: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = s
	return b


## Une salle : murs (kit.room), sol et plafond à part (chacun sa répétition de texture).
func _room75(x0: float, x1: float, z0: float, z1: float, y0: float, h: float, wall: String, floor_k: String, ceil_k: String, openings: Array, wtile: float = 3.0, ftile: float = 2.0, ctile: float = 1.2) -> void:
	kit.room(_xf(), x0, x1, z0, z1, y0, h, wall, "", openings, "", T, wtile)
	var c := Vector3((x0 + x1) * 0.5, 0, (z0 + z1) * 0.5)
	if floor_k != "":
		kit.solid(X(Vector3(c.x, y0 - 0.3, c.z)), Vector3(x1 - x0 + 2 * T, 0.6, z1 - z0 + 2 * T), floor_k, ftile, 4)
	if ceil_k != "":
		kit.solid(X(Vector3(c.x, y0 + h + 0.4, c.z)), Vector3(x1 - x0 + 2 * T, 0.8, z1 - z0 + 2 * T), ceil_k, ctile, 8)


func _light(n: String, l: Vector3, c: Color, e: float, r: float, shadow: bool = false, att: float = 0.8) -> OmniLight3D:
	var li := OmniLight3D.new()
	li.name = "Lumiere"
	li.light_color = c
	li.light_energy = e
	li.light_specular = 0.25
	li.omni_range = r
	li.omni_attenuation = att
	li.shadow_enabled = shadow and pc
	_root(n).add_child(li)
	li.global_position = W(l)
	return li


func _label(n: String, l: Vector3, yaw: float, text: String, font: int, col: Color, width_m: float = 0.0, px: float = 0.004) -> Label3D:
	var lb := Label3D.new()
	lb.text = text
	lb.font_size = font
	lb.pixel_size = px
	lb.modulate = col
	lb.outline_size = 0
	lb.double_sided = false
	if width_m > 0.0:
		lb.width = width_m / px
		lb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root(n).add_child(lb)
	lb.global_transform = Transform3D(Basis(Vector3.UP, yaw), W(l))
	return lb


## Un panneau imprimé (fond bg, texte ink) au mur : l = le centre, yaw : il regarde +Z tourné.
func _sign(n: String, l: Vector3, yaw: float, w: float, h: float, text: String, font: int, bg: String, ink: Color, shaded: bool = true, frame: String = "") -> Label3D:
	var bs := Basis(Vector3.UP, yaw)
	kit.box(Transform3D(bs, W(l + bs * Vector3(0, 0, -0.02))), Vector3(w, h, 0.03), bg, 1.0)
	if frame != "":
		for s in [-1.0, 1.0]:
			kit.box(Transform3D(bs, W(l + bs * Vector3(s * (w * 0.5 + 0.02), 0, -0.02))), Vector3(0.04, h + 0.08, 0.05), frame, 1.0)
			kit.box(Transform3D(bs, W(l + bs * Vector3(0, s * (h * 0.5 + 0.02), -0.02))), Vector3(w + 0.08, 0.04, 0.05), frame, 1.0)
	var lb := _label(n, l + bs * Vector3(0, 0, 0.004), yaw, text, font, ink, w * 0.9)
	lb.shaded = shaded
	return lb


## Une affiche de motivation (cadre noir, papier de couleur, slogan absurde).
func _poster(n: String, l: Vector3, yaw: float, text: String, paper: String = "papier75u", ink: Color = Color(0.12, 0.13, 0.16)) -> void:
	_sign(n, l, yaw, 1.1, 1.5, text, 44, paper, ink, true, "noir75u")
	var bs := Basis(Vector3.UP, yaw)
	var lo := _label(n, l + bs * Vector3(0, -0.6, 0.006), yaw, "LISSE & FILS", 22, Color(0.45, 0.46, 0.5))
	lo.shaded = true


## Une plaque d'étage (métal, lettres blanches).
func _plaque(n: String, l: Vector3, yaw: float, w: float, text: String) -> void:
	_sign(n, l, yaw, w, 0.7, text, 44, "grisf75u", Color(0.95, 0.95, 0.92), true, "jaune75u")


## Les tubes néon d'un faux plafond (en lot) : rangées en z, pas en x.
func _neons(y: float, x0: float, x1: float, zs: Array, step: float) -> void:
	for z in zs:
		var x: float = x0
		while x <= x1 + 0.01:
			kit.box(X(Vector3(x, y - 0.02, float(z))), Vector3(1.24, 0.04, 0.34), "blanc75u", 1.0)
			kit.box(X(Vector3(x, y - 0.045, float(z))), Vector3(1.18, 0.02, 0.28), "neon75u", 1.0)
			x += step


## Une rambarde jaune (poteaux, deux lisses) de a à b (au sol, local) ; elle arrête le joueur.
func _rail(a: Vector3, b: Vector3, h: float = 1.05) -> void:
	var d: Vector3 = b - a
	var ln: float = d.length()
	if ln < 0.05:
		return
	var n: int = maxi(int(ln / 1.6), 1)
	for i in range(n + 1):
		kit.cyl(X(a.lerp(b, float(i) / n)), 0.028, 0.028, h, "jaune75u", 8, true, 1.0)
	_tube(a + Vector3.UP * h, b + Vector3.UP * h, 0.03, "jaune75u")
	_tube(a + Vector3.UP * h * 0.5, b + Vector3.UP * h * 0.5, 0.022, "jaune75u")
	kit.col_box(Transform3D(Basis(Vector3.UP, atan2(d.x, d.z)), W((a + b) * 0.5 + Vector3.UP * h * 0.6)), Vector3(0.1, h * 1.2, ln))


## Une bande de rayures jaunes et noires au sol (rect local).
func _stripes(x0: float, x1: float, z0: float, z1: float, y: float) -> void:
	kit.box(X(Vector3((x0 + x1) * 0.5, y + 0.006, (z0 + z1) * 0.5)), Vector3(x1 - x0, 0.012, z1 - z0), "hachures75u", 0.8, 4)


# =================================================================== mobilier

## Un bureau d'open-space (plateau, écran, clavier, papiers, tasse, fauteuil) ; il regarde +Z
## (le fauteuil est devant, en +Z).
func _desk(c: Vector3, yaw: float, seed_i: int) -> void:
	var xf: Transform3D = X(c, yaw)
	_bx(xf, Vector3(0, 0.74, 0), Vector3(1.6, 0.04, 0.8), "gris75u")
	for s in [-1.0, 1.0]:
		_bx(xf, Vector3(s * 0.77, 0.36, 0), Vector3(0.04, 0.72, 0.72), "acier75u")
	_bx(xf, Vector3(0, 0.46, -0.37), Vector3(1.5, 0.5, 0.02), "gris75u")
	_bx(xf, Vector3(0, 0.77, -0.24), Vector3(0.22, 0.02, 0.16), "noir75u")
	_bx(xf, Vector3(0, 0.86, -0.26), Vector3(0.05, 0.16, 0.04), "noir75u")
	_bx(xf, Vector3(0, 1.1, -0.24), Vector3(0.6, 0.36, 0.035), "noir75u")
	kit.quadz(xf * Transform3D(Basis(), Vector3(0, 1.1, -0.221)), 0.56, 0.32, "ecran75u" if seed_i % 3 == 0 else "ecranon75u")
	_bx(xf, Vector3(0, 0.77, 0.1), Vector3(0.44, 0.02, 0.14), "noir75u")
	_bx(xf, Vector3(0.33, 0.77, 0.12), Vector3(0.06, 0.02, 0.1), "noir75u")
	for k in range(1 + seed_i % 3):
		kit.box(xf * Transform3D(Basis(Vector3.UP, 0.1 * k - 0.1), Vector3(-0.52, 0.765 + 0.012 * k, 0.02)), Vector3(0.21, 0.01, 0.3), "papier75u", 1.0)
	if seed_i % 2 == 0:
		_cy(xf, Vector3(0.6, 0.76, -0.05), 0.04, 0.04, 0.1, "blanc75u", 10)
	_chair(xf * Transform3D(Basis(Vector3.UP, 0.25 * sin(seed_i * 1.7)), Vector3(0.05, 0, 0.8)))
	kit.col_box(xf * Transform3D(Basis(), Vector3(0, 0.38, 0)), Vector3(1.6, 0.76, 0.8))


## Un fauteuil de bureau à roulettes (le dossier en +Z).
func _chair(xf: Transform3D, k: String = "noir75u") -> void:
	for i in range(5):
		var b := Basis(Vector3.UP, TAU * i / 5.0)
		kit.box(xf * Transform3D(b, b * Vector3(0, 0.06, 0.17)), Vector3(0.05, 0.04, 0.34), "acier75u", 1.0)
	kit.cyl(xf * Transform3D(Basis(), Vector3(0, 0.06, 0)), 0.03, 0.03, 0.4, "acier75u", 8, false)
	_bx(xf, Vector3(0, 0.5, 0), Vector3(0.48, 0.08, 0.46), k)
	_bx(xf, Vector3(0, 0.86, 0.22), Vector3(0.46, 0.56, 0.06), k)


## Une plante verte (en plastique) dans un pot blanc.
func _plant(l: Vector3, s: float, seed_i: int) -> void:
	var xf: Transform3D = X(l)
	kit.cyl(xf, 0.2 * s, 0.25 * s, 0.45 * s, "pot75u", 14)
	kit.disc(xf * Transform3D(Basis(), Vector3(0, 0.44 * s, 0)), 0.24 * s, "noir75u", 12)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_i
	for k in range(11):
		var b := Basis(Vector3.UP, TAU * k / 11.0 + rng.randf() * 0.4) * Basis(Vector3.RIGHT, -0.5 - rng.randf() * 0.7)
		var ln: float = s * rng.randf_range(0.5, 0.85)
		kit.box(Transform3D(b, W(l + Vector3(0, 0.45 * s, 0)) + b * Vector3(0, 0, ln * 0.5)), Vector3(0.13 * s, 0.012, ln), "plante75u", 1.0)
	kit.col_cyl(W(l), 0.25 * s, 0.6 * s)


## Une photocopieuse (elle regarde +Z tourné) : renvoie la feuille qui peut en sortir.
func _copier(n: String, l: Vector3, yaw: float) -> Node3D:
	var xf: Transform3D = X(l, yaw)
	_bx(xf, Vector3(0, 0.5, 0), Vector3(1.0, 1.0, 0.68), "blanc75u")
	_bx(xf, Vector3(0, 1.02, -0.05), Vector3(0.9, 0.05, 0.56), "grisf75u")
	_bx(xf, Vector3(0.28, 0.96, 0.3), Vector3(0.36, 0.06, 0.12), "grisf75u")
	_bx(xf, Vector3(0.18, 0.99, 0.31), Vector3(0.08, 0.01, 0.05), "vert75u")
	for y in [0.2, 0.45]:
		_bx(xf, Vector3(0, y, 0.345), Vector3(0.8, 0.18, 0.01), "gris75u")
	_bx(xf, Vector3(-0.62, 0.72, 0), Vector3(0.26, 0.02, 0.4), "grisf75u")
	kit.col_box(xf * Transform3D(Basis(), Vector3(0, 0.5, 0)), Vector3(1.0, 1.0, 0.68))
	var sheet := Node3D.new()
	sheet.name = "Feuille"
	_root(n).add_child(sheet)
	sheet.global_transform = xf * Transform3D(Basis(), Vector3(-0.3, 0.74, 0))
	_mesh(sheet, _boxm(Vector3(0.3, 0.004, 0.21)), "papier75u", Vector3.ZERO)
	var lb := Label3D.new()
	lb.text = "FORMULAIRE\nREFUSÉ"
	lb.font_size = 22
	lb.pixel_size = 0.003
	lb.modulate = Color(0.85, 0.06, 0.06)
	lb.outline_size = 0
	sheet.add_child(lb)
	lb.position = Vector3(0, 0.004, 0)
	lb.rotation = Vector3(-PI * 0.5, PI * 0.5, 0)
	sheet.visible = false
	sheet.set_meta("x0", sheet.transform)
	return sheet


## Un terminal de sortie : une vieille console grise à écran vert (elle regarde « face »).
func _terminal(n: String, l: Vector3, face: Vector3) -> void:
	var yaw: float = atan2(face.x, face.z)
	var xf: Transform3D = X(l, yaw)
	_bx(xf, Vector3(0, 0.5, 0), Vector3(0.8, 1.0, 0.6), "gris75u")
	_bx(xf, Vector3(0, 1.02, 0.05), Vector3(0.84, 0.04, 0.66), "grisf75u")
	kit.box(xf * Transform3D(Basis(Vector3.RIGHT, 0.25), Vector3(0, 1.0, 0.24)), Vector3(0.6, 0.04, 0.22), "noir75u", 1.0)
	_bx(xf, Vector3(0, 1.38, -0.05), Vector3(0.7, 0.6, 0.5), "gris75u")
	kit.quadz(xf * Transform3D(Basis(Vector3.RIGHT, -0.08), Vector3(0, 1.4, 0.205)), 0.52, 0.4, "term75u")
	_bx(xf, Vector3(0.28, 0.12, 0.31), Vector3(0.12, 0.08, 0.01), "rougeon75u")
	kit.col_box(xf * Transform3D(Basis(), Vector3(0, 0.75, 0)), Vector3(0.8, 1.5, 0.6))
	var lb := Label3D.new()
	lb.text = "TERMINAL DE SORTIE\n> REMONTER ? [O/N]_"
	lb.font_size = 26
	lb.pixel_size = 0.0016
	lb.modulate = Color(0.5, 1.0, 0.6)
	lb.outline_size = 0
	lb.double_sided = false
	_root(n).add_child(lb)
	lb.global_transform = xf * Transform3D(Basis(Vector3.RIGHT, -0.08), Vector3(0, 1.4, 0.212))
	_term_screens.append(lb)
	_sign(n, l + face * 0.0 + Vector3(0, 2.25, 0) + Basis(Vector3.UP, yaw) * Vector3(0, 0, -0.1), yaw, 1.2, 0.28, "SORTIE — SURFACE", 34, "vert75u", Color(0.02, 0.15, 0.04), false)


## Un levier de pupitre (la poignée pivote autour de x : -0.6 vers l'avant, +0.6 vers l'arrière).
func _lever75(n: String, l: Vector3) -> Node3D:
	kit.box(X(l + Vector3(0, 1.02, 0)), Vector3(0.22, 0.04, 0.3), "grisf75u", 1.0)
	var piv := Node3D.new()
	piv.name = "Levier"
	_root(n).add_child(piv)
	piv.global_position = W(l + Vector3(0, 1.05, 0))
	var arm := Node3D.new()
	piv.add_child(arm)
	_mesh(arm, _cylm(0.025, 0.025, 0.5, 8), "acier75u", Vector3(0, 0.25, 0))
	_mesh(arm, _sphere(0.06), "rouge75u", Vector3(0, 0.52, 0))
	arm.rotation.x = -0.6
	return arm


## Une vanne (un volant rouge sur un tuyau qui sort du mur) ; renvoie le volant.
func _valve(n: String, l: Vector3, inward: Vector3) -> Node3D:
	var yaw: float = atan2(inward.x, inward.z)
	var bs := Basis(Vector3.UP, yaw)
	var c: Vector3 = l + Vector3(0, 1.3, 0)
	_tube(c, c + inward * 0.45, 0.09, "rouille75u")
	_tube(c + Vector3(0, -1.3, 0) + inward * 0.25, c + Vector3(0, 2.8, 0) + inward * 0.25, 0.14, "rouille75u")
	kit.box(Transform3D(bs, W(c + inward * 0.25)), Vector3(0.36, 0.36, 0.36), "acier75u", 1.0)
	var w := Node3D.new()
	w.name = "Volant"
	_root(n).add_child(w)
	w.global_transform = Transform3D(bs, W(c + inward * 0.5))
	w.set_meta("b0", w.transform.basis)
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.26
	tm.outer_radius = 0.32
	tm.rings = 24
	tm.ring_segments = 8
	ring.mesh = tm
	ring.material_override = _m("rouge75u")
	ring.rotation.x = PI * 0.5
	w.add_child(ring)
	for k in range(3):
		_mesh(w, _boxm(Vector3(0.56, 0.035, 0.035)), "rouge75u", Vector3.ZERO, Vector3(0, 0, PI * k / 3.0))
	_mesh(w, _cylm(0.06, 0.06, 0.08, 10), "acier75u", Vector3.ZERO, Vector3(PI * 0.5, 0, 0))
	return w


## Un bras robot d'assemblage (socle, épaule, bras, avant-bras, chalumeau) : animé dans _tick.
func _arm(n: String, l: Vector3, yaw: float, ph: float, sparks: bool) -> void:
	var base := Node3D.new()
	base.name = "Bras_robot"
	_root(n).add_child(base)
	base.global_transform = X(l, yaw)
	_mesh(base, _cylm(0.42, 0.36, 0.5, 18), "jaune75u", Vector3(0, 0.25, 0))
	var sh := Node3D.new()
	base.add_child(sh)
	sh.position = Vector3(0, 0.5, 0)
	_mesh(sh, _cylm(0.26, 0.26, 0.34, 16), "orange75u", Vector3(0, 0.17, 0))
	var up := Node3D.new()
	sh.add_child(up)
	up.position = Vector3(0, 0.36, 0)
	_mesh(up, _sphere(0.2), "acier75u", Vector3.ZERO)
	_mesh(up, _boxm(Vector3(0.2, 1.3, 0.22)), "orange75u", Vector3(0, 0.65, 0))
	var fo := Node3D.new()
	up.add_child(fo)
	fo.position = Vector3(0, 1.3, 0)
	_mesh(fo, _sphere(0.15), "acier75u", Vector3.ZERO)
	_mesh(fo, _boxm(Vector3(0.15, 0.15, 1.05)), "orange75u", Vector3(0, 0, 0.52))
	_mesh(fo, _cylm(0.07, 0.03, 0.3, 10), "acier75u", Vector3(0, -0.12, 1.02))
	var sp: CPUParticles3D = null
	if sparks:
		sp = _sparks(fo, Vector3(0, -0.3, 1.02))
	_arms.append([sh, up, fo, ph, sp])


## Des étincelles (soudure).
func _sparks(parent: Node3D, pos: Vector3) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = 28
	p.lifetime = 0.55
	p.explosiveness = 0.2
	p.direction = Vector3.DOWN
	p.spread = 70.0
	p.initial_velocity_min = 1.5
	p.initial_velocity_max = 3.5
	p.gravity = Vector3(0, -9.0, 0)
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.0
	var q := QuadMesh.new()
	q.size = Vector2(0.035, 0.035)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	q.material = m
	p.mesh = q
	var g := Gradient.new()
	g.set_color(0, Color(1.0, 0.95, 0.7, 1.0))
	g.set_color(1, Color(1.0, 0.4, 0.05, 0.0))
	p.color_ramp = g
	parent.add_child(p)
	p.position = pos
	p.emitting = false
	return p


## Un jet de vapeur (des bouffées blanches qui partent de la buse, vers +Z tourné).
func _steam(parent: Node3D, pos: Vector3, dir: Vector3, reach: float) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = 46
	p.lifetime = 0.8
	p.direction = dir
	p.spread = 9.0
	p.initial_velocity_min = reach * 1.2
	p.initial_velocity_max = reach * 1.6
	p.damping_min = reach * 0.7
	p.damping_max = reach * 1.0
	p.gravity = Vector3(0, 1.4, 0)
	p.scale_amount_min = 0.7
	p.scale_amount_max = 1.2
	var curve := Curve.new()
	curve.add_point(Vector2(0, 0.25))
	curve.add_point(Vector2(1, 1.0))
	p.scale_amount_curve = curve
	var q := QuadMesh.new()
	q.size = Vector2(1.3, 1.3)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	m.disable_receive_shadows = true
	if main != null and main.has_method("_soft_dot_v24"):
		m.albedo_texture = main._soft_dot_v24()
	q.material = m
	p.mesh = q
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 0.55))
	g.set_color(1, Color(0.9, 0.92, 0.95, 0.0))
	p.color_ramp = g
	parent.add_child(p)
	p.global_position = pos
	p.emitting = false
	return p


## Une chaudière (cuve rivetée, cerclages, dôme, porte du foyer qui rougeoie, une lumière).
func _boiler(n: String, l: Vector3, r: float, h: float) -> void:
	kit.cyl(X(l), r, r, h, "rivete75u", 28, false, 2.0)
	kit.cyl(X(l + Vector3(0, h, 0)), r, r * 0.25, r * 0.7, "rouille75u", 28, true, 2.0)
	for y in [0.5, h * 0.5, h - 0.4]:
		kit.ring(X(l + Vector3(0, y, 0)), r - 0.02, r + 0.07, 0.18, "acier75u", 28)
	var fx: Transform3D = X(l + Vector3(0, 0, -r), PI)
	_bx(fx, Vector3(0, 0.95, 0.04), Vector3(1.1, 0.9, 0.14), "noir75u")
	for y2 in [0.78, 0.95, 1.12]:
		_bx(fx, Vector3(0, y2, 0.115), Vector3(0.8, 0.07, 0.01), "braise75u")
	_tube(l + Vector3(0, h + r * 0.6, 0), l + Vector3(0, 10.0, 0), 0.32, "rouille75u", 14)
	kit.disc(Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), W(l + Vector3(0.6, 2.4, -r - 0.06))), 0.22, "blanc75u", 16)
	kit.col_cyl(W(l), r, h + r * 0.6)
	var li := _light(n, l + Vector3(0, 1.0, -r - 1.0), Color(1.0, 0.52, 0.2), 1.8, 9.0, false, 1.2)
	_boiler_lights.append(li)


## Un rayonnage d'entrepôt le long de z (x0..x1 = sa profondeur) : montants bleus, lisses orange,
## planchers, palettes et cartons ; un seul bloc de collision.
func _rack(x0: float, x1: float, z0: float, z1: float, y0: float, h: float, levels: int, seed_i: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_i
	var bays: int = maxi(int(round((z1 - z0) / 2.7)), 1)
	var bay: float = (z1 - z0) / bays
	for i in range(bays + 1):
		var z: float = z0 + bay * i
		for x in [x0 + 0.06, x1 - 0.06]:
			kit.box(X(Vector3(x, y0 + h * 0.5, clampf(z, z0 + 0.05, z1 - 0.05))), Vector3(0.09, h, 0.09), "bleu75u", 1.0)
	var lh: float = h / levels
	for lv in range(1, levels + 1):
		var y: float = y0 + lh * lv - 0.12
		if lv == levels:
			y = y0 + h - 0.1
		for x2 in [x0 + 0.06, x1 - 0.06]:
			kit.box(X(Vector3(x2, y, (z0 + z1) * 0.5)), Vector3(0.07, 0.14, z1 - z0), "orange75u", 1.0)
		kit.box(X(Vector3((x0 + x1) * 0.5, y + 0.08, (z0 + z1) * 0.5)), Vector3(x1 - x0 - 0.1, 0.03, z1 - z0), "acier75u", 2.0)
	for lv2 in range(levels):
		var yb: float = y0 + (0.0 if lv2 == 0 else lh * lv2 - 0.12 + 0.095)
		for i2 in range(bays):
			if rng.randf() < 0.18:
				continue
			var zc: float = z0 + bay * (i2 + 0.5)
			var w: float = minf(x1 - x0 - 0.3, 1.1)
			kit.box(X(Vector3((x0 + x1) * 0.5, yb + 0.07, zc)), Vector3(w, 0.14, bay - 0.5), "bois75u", 1.0)
			var stack: int = 1 + rng.randi() % 3
			var hh: float = minf(lh - 0.5, 1.4)
			for s in range(stack):
				var bw: float = rng.randf_range(0.45, 0.6)
				kit.box(X(Vector3((x0 + x1) * 0.5 + rng.randf_range(-0.1, 0.1), yb + 0.14 + hh * 0.5, zc + (s - (stack - 1) * 0.5) * (bay - 0.6) / maxf(stack, 1))),
					Vector3(w * 0.9, hh * rng.randf_range(0.55, 1.0), bw * 1.4), "carton75u", 1.0)
	kit.col_box(X(Vector3((x0 + x1) * 0.5, y0 + h * 0.5, (z0 + z1) * 0.5)), Vector3(x1 - x0, h, z1 - z0))


## Une pile fixe (palettes et cartons filmés), trop haute pour qu'on grimpe dessus.
func _pallet_stack(c: Vector3, seed_i: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_i
	kit.box(X(c + Vector3(0, 0.07, 0)), Vector3(1.8, 0.14, 1.8), "bois75u", 1.0)
	var y: float = 0.14
	for k in range(3):
		var hh: float = rng.randf_range(0.6, 0.8)
		kit.box(X(c + Vector3(rng.randf_range(-0.05, 0.05), y + hh * 0.5, rng.randf_range(-0.05, 0.05)), rng.randf_range(-0.1, 0.1)), Vector3(1.7, hh, 1.7), "carton75u", 1.0)
		y += hh
	kit.box(X(c + Vector3(0, y + 0.01, 0)), Vector3(1.6, 0.02, 1.6), "papier75u", 1.0)
	kit.col_box(X(c + Vector3(0, 1.4, 0)), Vector3(1.9, 2.8, 1.9))


## Un chariot élévateur robot (le corps mobile, la collision, un gyrophare).
func _forklift(n: String) -> Array:
	var b := AnimatableBody3D.new()
	b.name = "Chariot_robot"
	b.sync_to_physics = false
	_root(n).add_child(b)
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(1.3, 2.1, 2.9)
	cs.shape = sh
	cs.position = Vector3(0, 1.05, 0.25)
	b.add_child(cs)
	_mesh(b, _boxm(Vector3(1.25, 0.75, 1.7)), "orange75u", Vector3(0, 0.62, -0.15))
	_mesh(b, _boxm(Vector3(1.2, 0.6, 0.5)), "noir75u", Vector3(0, 0.55, -1.0))
	_mesh(b, _boxm(Vector3(1.0, 0.9, 0.8)), "grisf75u", Vector3(0, 1.4, -0.35))
	_mesh(b, _boxm(Vector3(0.8, 0.45, 0.02)), "ecran75u", Vector3(0, 1.5, 0.06))
	for s in [-1.0, 1.0]:
		_mesh(b, _boxm(Vector3(0.14, 0.09, 0.02)), "vert75u", Vector3(s * 0.18, 1.55, 0.075))
		_mesh(b, _boxm(Vector3(0.08, 2.4, 0.1)), "acier75u", Vector3(s * 0.45, 1.25, 0.75))
		_mesh(b, _boxm(Vector3(0.12, 0.05, 1.1)), "acier75u", Vector3(s * 0.3, 0.12, 1.35))
		for z in [-0.75, 0.5]:
			_mesh(b, _cylm(0.27, 0.27, 0.22, 16), "caoutchouc75u", Vector3(s * 0.6, 0.27, z), Vector3(0, 0, PI * 0.5))
	_mesh(b, _boxm(Vector3(1.0, 0.08, 0.1)), "acier75u", Vector3(0, 2.4, 0.75))
	_mesh(b, _boxm(Vector3(1.1, 0.12, 1.1)), "bois75u", Vector3(0, 0.22, 1.35))
	_mesh(b, _boxm(Vector3(0.9, 0.7, 0.9)), "carton75u", Vector3(0, 0.64, 1.35))
	var lb := Label3D.new()
	lb.text = "PRIORITÉ\nAUX CHARIOTS"
	lb.font_size = 30
	lb.pixel_size = 0.004
	lb.modulate = Color(0.1, 0.1, 0.1)
	lb.outline_size = 0
	lb.shaded = true
	b.add_child(lb)
	lb.position = Vector3(0.64, 0.7, -0.2)
	lb.rotation.y = PI * 0.5
	var gy := Node3D.new()
	b.add_child(gy)
	gy.position = Vector3(0, 1.95, -0.35)
	_mesh(gy, _cylm(0.1, 0.1, 0.16, 12), "gyro75u", Vector3(0, 0.08, 0))
	return [b, gy]


## Une caisse à pousser (corps statique, 1,8 × 1 × 1,8).
func _crate75(n: String, i: int) -> StaticBody3D:
	var sb := StaticBody3D.new()
	sb.name = "Caisse_%d" % i
	_root(n).add_child(sb)
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(1.8, 1.0, 1.8)
	cs.shape = sh
	cs.position = Vector3(0, 0.5, 0)
	sb.add_child(cs)
	_mesh(sb, _boxm(Vector3(1.78, 0.98, 1.78)), "bois75u", Vector3(0, 0.5, 0))
	for s in [-1.0, 1.0]:
		_mesh(sb, _boxm(Vector3(1.82, 0.1, 0.1)), "grisf75u", Vector3(0, 0.5 + s * 0.38, 0.88))
		_mesh(sb, _boxm(Vector3(1.82, 0.1, 0.1)), "grisf75u", Vector3(0, 0.5 + s * 0.38, -0.88))
		_mesh(sb, _boxm(Vector3(0.1, 0.1, 1.82)), "grisf75u", Vector3(0.88, 0.5 + s * 0.38, 0))
		_mesh(sb, _boxm(Vector3(0.1, 0.1, 1.82)), "grisf75u", Vector3(-0.88, 0.5 + s * 0.38, 0))
	var texts := ["FRAGILE\nContient du vide", "LISSE & FILS\nHaut (ou bas)", "NE PAS POUSSER\n(sauf toi)"]
	for k in range(2):
		var lb := Label3D.new()
		lb.text = texts[(i + k) % 3]
		lb.font_size = 40
		lb.pixel_size = 0.004
		lb.modulate = Color(0.22, 0.12, 0.06)
		lb.outline_size = 0
		lb.shaded = true
		lb.double_sided = false
		sb.add_child(lb)
		lb.position = Vector3(0, 0.55, 0.9 if k == 0 else -0.9)
		lb.rotation.y = 0.0 if k == 0 else PI
	return sb


# =================================================================== construction

func _build() -> void:
	add_room("accueil", Vector3(-8, 0, 0), Vector3(8, 5, 14), Vector3(0, 0, 3.0), Vector3(0, 0, 1), ["bureaux"])
	add_room("bureaux", Vector3(-20, 0, 14), Vector3(20, 4.2, 50), Vector3(0, 0, 15.5), Vector3(0, 0, 1), ["accueil", "esc1"])
	add_room("esc1", Vector3(10, -14, 50), Vector3(14, 5, 78), Vector3(12, 0, 51.2), Vector3(0, 0, 1), ["bureaux", "chaine"])
	add_room("chaine", Vector3(-24, -14, 78), Vector3(24, -5, 122), ARRIVE[2], Vector3(0, 0, 1), ["esc1", "esc2"])
	add_room("esc2", Vector3(10, -28, 122), Vector3(14, -9, 150), Vector3(12, -14, 123.2), Vector3(0, 0, 1), ["chaine", "chaufferie"])
	add_room("chaufferie", Vector3(-20, -28, 150), Vector3(24, -18, 196), ARRIVE[3], Vector3(0, 0, 1), ["esc2", "esc3"])
	add_room("esc3", Vector3(10, -42, 196), Vector3(14, -23, 224), Vector3(12, -28, 197.2), Vector3(0, 0, 1), ["chaufferie", "entrepot"])
	add_room("entrepot", Vector3(-24, -42, 224), Vector3(24, -30, 272), ARRIVE[4], Vector3(0, 0, 1), ["esc3", "esc4"])
	add_room("esc4", Vector3(10, -56, 272), Vector3(14, -37, 300), Vector3(12, -42, 273.2), Vector3(0, 0, 1), ["entrepot", "fosse"])
	add_room("fosse", Vector3(-8, -56, 300), Vector3(32, -38, 340), ARRIVE[5], Vector3(0, 0, 1), ["esc4"])
	_build_accueil()
	_build_bureaux()
	_build_stairs("esc1", 50.0, 0.0, 1)
	_build_chaine()
	_build_stairs("esc2", 122.0, -14.0, 2)
	_build_chaufferie()
	_build_stairs("esc3", 196.0, -28.0, 3)
	_build_entrepot()
	_build_stairs("esc4", 272.0, -42.0, 4)
	_build_fosse()
	kit.commit()


## Un escalier de service de l'étage du haut (yu) vers celui du bas (yu - 14), de z0 à z0 + 28,
## en x = 12 : marches de tôle rivetée, murs de béton, plafond en gradins, deux lampes grillagées.
func _build_stairs(n: String, z0: float, yu: float, floor_k: int) -> void:
	_in_room(n)
	var yl: float = yu - 14.0
	kit.solid(X(Vector3(12, yu - 0.3, z0 + 1.0)), Vector3(4.0 + 2 * T, 0.6, 2.0), "carrelageu75u", 4.0)
	kit.ramp(_xf(), Vector3(12, yl, z0 + 25.0), Vector3(12, yu, z0 + 2.0), 4.0, "rivete75u")
	kit.solid(X(Vector3(12, yl - 0.3, z0 + 26.5)), Vector3(4.0 + 2 * T, 0.6, 3.0), "carrelageu75u", 4.0)
	for x in [10.0 - T * 0.5, 14.0 + T * 0.5]:
		_block(Vector3(x - T * 0.5, yl - 0.6, z0 + T * 0.5), Vector3(x + T * 0.5, yu + 5.0, z0 + 28.0 - T * 0.5), "beton75u")
	for i in range(14):
		var zs: float = z0 + 2.0 * i
		var f: float = yu if zs <= z0 + 2.0 else maxf(yu - (zs - z0 - 2.0) / 23.0 * 14.0, yl)
		kit.solid(X(Vector3(12, f + 4.6 + 1.25, zs + 1.0)), Vector3(4.0 + 2 * T, 2.5, 2.0), "brut75u", 3.0)
	# la main courante, les lampes grillagées, une bande de sécurité en haut et en bas
	_tube(Vector3(10.08, yu + 1.0, z0 + 2.0), Vector3(10.08, yl + 1.0, z0 + 25.0), 0.03, "jaune75u")
	_tube(Vector3(13.92, yu + 1.0, z0 + 2.0), Vector3(13.92, yl + 1.0, z0 + 25.0), 0.03, "jaune75u")
	_stripes(10.0, 14.0, z0 + 1.6, z0 + 2.0, yu)
	_stripes(10.0, 14.0, z0 + 25.0, z0 + 25.4, yl)
	for k in range(2):
		var z: float = z0 + 8.0 + k * 10.0
		var fy: float = maxf(yu - (z - z0 - 2.0) / 23.0 * 14.0, yl)
		var side: float = 10.02 if k == 0 else 13.98
		var xf: Transform3D = X(Vector3(side, fy + 3.0, z), PI * 0.5 if k == 0 else -PI * 0.5)
		_bx(xf, Vector3(0, 0, 0.08), Vector3(0.3, 0.2, 0.16), "grisf75u")
		_bx(xf, Vector3(0, 0, 0.12), Vector3(0.22, 0.12, 0.1), "neon75u")
	var counts := ["Marche 1 sur 64. Veuillez compter.", "Escalier B : réservé aux robots polis.", "Attention : marches optimisées (plus petites, plus nombreuses).",
		"Dernière ligne droite. (Elle descend.)"]
	var zm: float = z0 + 12.5
	var ym: float = yu - (zm - z0 - 2.0) / 23.0 * 14.0
	_sign(n, Vector3(13.97, ym + 1.8, zm), -PI * 0.5, 1.6, 0.6, counts[clampi(floor_k - 1, 0, 3)], 30, "blanc75u", Color(0.12, 0.13, 0.16), true, "grisf75u")
	_light(n, Vector3(12, (yu + yl) * 0.5 + 3.0, z0 + 14.0), Color(0.86, 0.92, 1.0), 0.9, 16.0, false, 0.7)


func _build_accueil() -> void:
	_in_room("accueil")
	# (pas de mur au sud : c'est le mur nord des Bureaux, avec sa porte, qui sépare les deux salles)
	_room75(-8, 8, 0, 14, 0, 5, "betonc75u", "carrelage75u", "plafond75u", [["s", 0, 16.0 + 2 * T, 5.0]], 3.0, 2.0, 2.4)
	# les portes vitrées du portail (on voit le jour derrière), le panneau SORTIE
	kit.quadz(X(Vector3(0, 1.4, 0.01)), 2.6, 2.8, "jour75u")
	for s in [-1.0, 1.0]:
		_deco(Vector3(s * 1.35 - 0.06, 0, 0.0), Vector3(s * 1.35 + 0.06, 2.9, 0.12), "acier75u")
		_deco(Vector3(s * 0.65 - 0.7, 0.0, 0.04), Vector3(s * 0.65 + 0.7, 2.8, 0.08), "verre75u")
	_deco(Vector3(-1.45, 2.8, 0.0), Vector3(1.45, 2.95, 0.12), "acier75u")
	_deco(Vector3(-0.02, 0.0, 0.03), Vector3(0.02, 2.8, 0.1), "acier75u")
	_sign("accueil", Vector3(0, 3.3, 0.04), 0.0, 1.0, 0.3, "SORTIE", 50, "vert75u", Color(0.02, 0.16, 0.05), false)
	# le comptoir d'accueil et l'Accueillotron
	var dxf: Transform3D = X(Vector3(-3.6, 0, 9.4), 0.0)
	_bx(dxf, Vector3(0, 0.53, 0), Vector3(3.2, 1.06, 0.7), "blanc75u")
	_bx(dxf, Vector3(0, 1.08, 0.05), Vector3(3.4, 0.05, 0.85), "gris75u")
	_bx(dxf, Vector3(0, 0.55, -0.36), Vector3(3.0, 0.6, 0.02), "grisf75u")
	kit.col_box(dxf * Transform3D(Basis(), Vector3(0, 0.53, 0)), Vector3(3.4, 1.06, 0.8))
	var al: Label3D = _label("accueil", Vector3(-3.6, 0.6, 8.99), PI, "LISSE & FILS — ACCUEIL", 36, Color(0.2, 0.22, 0.26), 2.8)
	al.shaded = true
	var rb: Transform3D = X(Vector3(-3.6, 0, 10.4), PI)
	_cy(rb, Vector3(0, 0, 0), 0.28, 0.24, 1.1, "acier75u", 16)
	_bx(rb, Vector3(0, 1.3, 0), Vector3(0.5, 0.36, 0.4), "blanc75u")
	_bx(rb, Vector3(0, 1.3, 0.205), Vector3(0.4, 0.22, 0.01), "ecran75u")
	for s2 in [-1.0, 1.0]:
		_bx(rb, Vector3(s2 * 0.09, 1.33, 0.212), Vector3(0.07, 0.04, 0.005), "ecranon75u")
		_bx(rb, Vector3(s2 * 0.34, 0.95, 0.0), Vector3(0.08, 0.5, 0.08), "acier75u")
	_bx(rb, Vector3(0, 1.26, 0.212), Vector3(0.14, 0.015, 0.005), "ecranon75u")
	_sign("accueil", Vector3(-2.2, 1.35, 8.99), PI, 0.5, 0.3, "Prenez un ticket.\nPuis attendez.\nPuis attendez encore.", 18, "papier75u", Color(0.15, 0.15, 0.2))
	# le distributeur de tickets, les chaises d'attente, les plantes
	var tk: Transform3D = X(Vector3(3.8, 0, 5.0), -PI * 0.5)
	_cy(tk, Vector3.ZERO, 0.05, 0.05, 1.1, "acier75u", 8)
	_bx(tk, Vector3(0, 1.25, 0), Vector3(0.32, 0.32, 0.22), "rouge75u")
	_bx(tk, Vector3(0, 1.18, 0.112), Vector3(0.12, 0.02, 0.01), "noir75u")
	_label("accueil", Vector3(3.68, 1.34, 5.0), -PI * 0.5, "TICKETS", 22, Color(1, 1, 1), 0.3, 0.003)
	kit.col_cyl(W(Vector3(3.8, 0, 5.0)), 0.2, 1.4)
	for z in [3.0, 4.0, 5.0]:
		_chair(X(Vector3(7.2, 0, z + 2.6), PI * 0.5), "bleu75u")
	_plant(Vector3(-7.2, 0, 1.0), 1.1, 751)
	_plant(Vector3(7.2, 0, 1.0), 1.0, 752)
	_plant(Vector3(-7.2, 0, 12.6), 0.9, 753)
	# l'ascenseur de service (mur ouest), le plan des étages, l'affiche
	var ex: Transform3D = X(ELEVATOR, PI * 0.5)
	_bx(ex, Vector3(0, 1.5, 0.05), Vector3(2.6, 3.0, 0.1), "acier75u")
	for s3 in [-1.0, 1.0]:
		_bx(ex, Vector3(s3 * 0.55, 1.25, 0.11), Vector3(1.08, 2.5, 0.03), "rivete75u")
	_bx(ex, Vector3(0, 1.25, 0.125), Vector3(0.02, 2.5, 0.01), "noir75u")
	_bx(ex, Vector3(0, 2.75, 0.11), Vector3(0.5, 0.22, 0.02), "noir75u")
	_label("accueil", ELEVATOR + Vector3(0.13, 2.75, 0), PI * 0.5, "-1", 40, Color(1.0, 0.35, 0.15), 0.0, 0.003)
	_bx(ex, Vector3(1.55, 1.2, 0.04), Vector3(0.16, 0.3, 0.05), "acier75u")
	_bx(ex, Vector3(1.55, 1.2, 0.07), Vector3(0.06, 0.06, 0.02), "rougeon75u")
	_sign("accueil", ELEVATOR + Vector3(0.05, 3.5, 0), PI * 0.5, 2.6, 0.5, "ASCENSEUR DE SERVICE\nne descend qu'aux étages déjà visités (il est prudent)", 24, "blanc75u", Color(0.12, 0.13, 0.16))
	_sign("accueil", Vector3(7.97, 1.7, 10.2), -PI * 0.5, 1.6, 1.8,
		"LISSE & FILS\nPLAN DES ÉTAGES\n\n-1  Les Bureaux\n-2  La Chaîne de Montage\n-3  La Chaufferie\n-4  L'Entrepôt Automatique\n-5  La Fosse du Président\n(accès interdit, surtout à vous)", 24, "blanc75u", Color(0.12, 0.13, 0.16), true, "acier75u")
	_poster("accueil", Vector3(7.97, 1.8, 2.4), -PI * 0.5, "OPTIMISER,\nC'EST AIMER.", "papier_bleu75u")
	_poster("accueil", Vector3(-7.97, 1.8, 3.5), PI * 0.5, "ON RASE.\nON BÂTIT.\nON ENCAISSE.", "papier75u", Color(0.6, 0.06, 0.05))
	_plaque("accueil", Vector3(0, 3.6, 13.17), PI, 4.0, "ÉTAGE 1 — LES BUREAUX")
	_deco(Vector3(-8.8, 4.15, 13.16), Vector3(8.8, 5.05, 13.2), "betonc75u", 3.0)
	_terminal("accueil", TERMINALS[1][0], TERMINALS[1][1])
	# le plafond : quatre dalles lumineuses ; deux lumières
	for p in [Vector3(-3.6, 0, 4.0), Vector3(3.6, 0, 4.0), Vector3(-3.6, 0, 10.0), Vector3(3.6, 0, 10.0)]:
		kit.box(X(p + Vector3(0, 4.98, 0)), Vector3(1.2, 0.04, 0.6), "neon75u", 1.0)
	_light("accueil", Vector3(0, 3.8, 4.0), Color(0.92, 0.95, 1.0), 1.3, 14.0, true)
	_light("accueil", Vector3(0, 3.8, 11.0), Color(0.92, 0.95, 1.0), 0.9, 12.0)


func _build_bureaux() -> void:
	_in_room("bureaux")
	_room75(-20, 20, 14, 50, 0, 4.2, "betonc75u", "moquette75u", "plafond75u", [["n", 0, 4.0, 3.0], ["s", 12, 3.4, 3.0]], 3.0, 2.0, 2.4)
	gate("bureaux", "bureaux", Vector3(12, 0, 50.4), 3.4, 3.0, 0.4, 0.0, "tole75u")
	# les plinthes, les néons du faux plafond
	for s in [-1.0, 1.0]:
		_deco(Vector3(s * 20.0 - 0.02, 0, 14.0), Vector3(s * 20.0 + 0.02, 0.1, 50.0), "grisf75u")
	_neons(4.2, -18.0, 18.0, [17.0, 23.0, 29.0, 35.0, 41.0, 47.0], 4.0)
	# les bureaux en rangs (trois sont ceux des formulaires)
	var k: int = 0
	for x in DESK_X:
		for z in DESK_Z:
			k += 1
			_desk(Vector3(x, 0, z), 0.0, k)
	# les cloisons basses entre les rangées de bureaux (gris feutré)
	for x2 in [-13.25, -7.75, 7.75, 13.25]:
		for z2 in DESK_Z:
			_block(Vector3(x2 - 0.03, 0, z2 - 0.4), Vector3(x2 + 0.03, 1.15, z2 + 0.4), "grisf75u", 1.0)
	_stamp_marks.clear()
	for i2 in range(FORMS.size()):
		_form_desk(i2)
	# la note de service sur le tableau de liège, l'horloge
	var mx: Transform3D = X(MEMO + Vector3(0, 1.6, 0.03), 0.0)
	_bx(mx, Vector3(0, 0, 0), Vector3(1.8, 1.1, 0.04), "liege75u")
	_bx(mx, Vector3(0, 0, -0.01), Vector3(1.9, 1.2, 0.03), "bois75u")
	for p in [Vector3(-0.6, 0.25, 0.025), Vector3(0.62, -0.28, 0.025), Vector3(-0.55, -0.3, 0.025)]:
		kit.box(mx * Transform3D(Basis(Vector3.BACK, p.x * 0.2), p), Vector3(0.3, 0.3, 0.005), "papier_jaune75u", 1.0)
	_sign("bureaux", MEMO + Vector3(0.05, 1.62, 0.07), 0.0, 0.8, 0.95,
		"NOTE DE SERVICE\nn° 4 512-B\n\nPour descendre, tamponner les formulaires dans l'ordre réglementaire :\nLE CIEL avant LE SOLEIL,\nLE SOLEIL avant LA BARBE À PAPA.\n\n(Ne demandez pas pourquoi. C'est la procédure.)\n— La Direction", 13, "papier75u", Color(0.1, 0.1, 0.14))
	kit.cyl(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), W(Vector3(-8.0, 3.1, 14.02))), 0.32, 0.32, 0.06, "blanc75u", 24)
	var cl: Label3D = _label("bureaux", Vector3(-8.0, 3.1, 14.09), 0.0, "IL EST L'HEURE\nDE TRAVAILLER", 16, Color(0.1, 0.1, 0.1), 0.5, 0.0025)
	cl.shaded = true
	# la fontaine à eau, les photocopieuses, les plantes, les armoires de classement
	var cx: Transform3D = X(Vector3(-19.4, 0, 30.0), PI * 0.5)
	_bx(cx, Vector3(0, 0.5, 0), Vector3(0.36, 1.0, 0.36), "blanc75u")
	_bx(cx, Vector3(0, 0.82, 0.19), Vector3(0.1, 0.06, 0.03), "bleu75u")
	_cy(cx, Vector3(0, 1.0, 0), 0.15, 0.15, 0.42, "eau75u", 16)
	kit.col_box(cx * Transform3D(Basis(), Vector3(0, 0.6, 0)), Vector3(0.4, 1.2, 0.4))
	_copier_sheets.clear()
	for cp in COPIERS:
		_copier_sheets.append(_copier("bureaux", cp, -PI * 0.5))
	for pp in [Vector3(-19.2, 0, 15.0), Vector3(19.2, 0, 15.0), Vector3(-19.2, 0, 49.0), Vector3(2.4, 0, 35.0), Vector3(-2.4, 0, 23.0)]:
		_plant(pp, 1.0, int(pp.z * 7 + pp.x))
	_sign("bureaux", Vector3(2.4, 0.42, 35.26), 0.0, 0.3, 0.12, "Plante verte (en plastique).\nNe pas arroser. Ne pas aimer.", 9, "papier75u", Color(0.1, 0.1, 0.1))
	for x3 in [-18.4, -17.4, -16.4, -6.0, -5.0]:
		var ax: Transform3D = X(Vector3(x3, 0, 49.6), PI)
		_bx(ax, Vector3(0, 0.75, 0), Vector3(0.9, 1.5, 0.6), "gris75u")
		for y in [0.3, 0.75, 1.2]:
			_bx(ax, Vector3(0, y, 0.305), Vector3(0.84, 0.38, 0.01), "grisf75u")
			_bx(ax, Vector3(0, y + 0.1, 0.315), Vector3(0.2, 0.03, 0.02), "acier75u")
		kit.col_box(ax * Transform3D(Basis(), Vector3(0, 0.75, 0)), Vector3(0.9, 1.5, 0.6))
	chest("fournitures", "bureaux", Vector3(-11.0, 0, 49.5), PI, [["piece", 30], ["potion_seve", 1]],
		"L'armoire à fournitures ! Dedans : des trombones, un agrafeur triste, quelques pièces… et une fiole oubliée par un stagiaire.")
	_paint_chest("fournitures", "gris75u", "acier75u")
	# les affiches de motivation
	_poster("bureaux", Vector3(-19.97, 1.9, 22.0), PI * 0.5, "OPTIMISER,\nC'EST AIMER.", "papier_bleu75u")
	_poster("bureaux", Vector3(-19.97, 1.9, 36.0), PI * 0.5, "UN SOURIRE\n=\n0,03 € DE\nPRODUCTIVITÉ", "papier_jaune75u")
	_poster("bureaux", Vector3(-19.97, 1.9, 44.0), PI * 0.5, "LE CAFÉ EST\nUNE PERTE\nDE TEMPS\nLIQUIDE.", "papier75u")
	_poster("bureaux", Vector3(19.97, 1.9, 31.0), -PI * 0.5, "ICI, ON PENSE\nÀ L'INTÉRIEUR\nDES CASES.", "papier_rose75u")
	_poster("bureaux", Vector3(19.97, 1.9, 45.0), -PI * 0.5, "VOTRE CHAISE\nVOUS OBSERVE.\nSOYEZ\nPRODUCTIF.", "papier75u")
	_poster("bureaux", Vector3(0.0, 1.9, 49.97), PI, "LES PAUSES\nSONT DES\nDÉMISSIONS\nMINIATURES.", "papier_bleu75u")
	_poster("bureaux", Vector3(-14.0, 1.9, 14.03), 0.0, "LE BONHEUR\nEST DANS\nLE TABLEUR.", "papier_jaune75u")
	# le tourniquet (bras qui tombe quand le rideau s'ouvre), son panneau
	var tx: Transform3D = X(Vector3(10.15, 0, 49.4), 0.0)
	_bx(tx, Vector3(0, 0.5, 0), Vector3(0.3, 1.0, 0.9), "acier75u")
	_bx(tx, Vector3(0, 1.01, 0), Vector3(0.32, 0.03, 0.92), "noir75u")
	kit.col_box(tx * Transform3D(Basis(), Vector3(0, 0.5, 0)), Vector3(0.3, 1.0, 0.9))
	_turnstile_arm = Node3D.new()
	_turnstile_arm.name = "Tourniquet"
	_root("bureaux").add_child(_turnstile_arm)
	_turnstile_arm.global_position = W(Vector3(10.32, 0.9, 49.4))
	_mesh(_turnstile_arm, _cylm(0.03, 0.03, 1.4, 8), "acier75u", Vector3(0.7, 0, 0), Vector3(0, 0, PI * 0.5))
	_turnstile_lamp = StandardMaterial3D.new()
	_turnstile_lamp.emission_enabled = true
	_turnstile_lamp.albedo_color = Color(0.3, 0.05, 0.05)
	_turnstile_lamp.emission = Color(1.0, 0.1, 0.06)
	_turnstile_lamp.emission_energy_multiplier = 2.5
	var tl := MeshInstance3D.new()
	tl.mesh = _boxm(Vector3(0.12, 0.08, 0.2))
	tl.material_override = _turnstile_lamp
	_root("bureaux").add_child(tl)
	tl.global_position = W(Vector3(10.15, 1.08, 49.4))
	_sign("bureaux", Vector3(12, 3.45, 49.97), PI, 3.4, 0.6, "SORTIE DU PERSONNEL — TOURNIQUET\nformulaires tamponnés obligatoires", 26, "blanc75u", Color(0.12, 0.13, 0.16), true, "acier75u")
	_plaque("bureaux", Vector3(0, 3.55, 14.03), 0.0, 4.0, "OPEN-SPACE — ON NE COURT PAS")
	# la lumière : trois plafonniers sans ombre, un avec (sur PC)
	_light("bureaux", Vector3(-10, 3.6, 24.0), Color(0.9, 0.95, 1.0), 1.0, 17.0, true)
	_light("bureaux", Vector3(10, 3.6, 24.0), Color(0.9, 0.95, 1.0), 0.9, 17.0)
	_light("bureaux", Vector3(0, 3.6, 41.0), Color(0.9, 0.95, 1.0), 1.0, 19.0)


## Le bureau d'un formulaire : la feuille de couleur, le gros tampon, le tampon encreur, la plaque.
func _form_desk(i: int) -> void:
	var fp: Vector3 = FORMS[i][0]
	var col: String = FORMS[i][1]
	var xf: Transform3D = X(fp, 0.0)
	_bx(xf, Vector3(0.15, 0.768, 0.12), Vector3(0.3, 0.008, 0.42), "papier_%s75u" % col)
	_bx(xf, Vector3(-0.42, 0.775, 0.16), Vector3(0.16, 0.02, 0.1), "noir75u")
	_bx(xf, Vector3(-0.42, 0.786, 0.16), Vector3(0.13, 0.004, 0.07), "encre75u")
	_bx(xf, Vector3(-0.2, 0.8, 0.22), Vector3(0.1, 0.06, 0.07), "noir75u")
	_cy(xf, Vector3(-0.2, 0.83, 0.22), 0.02, 0.02, 0.1, "bois75u", 8)
	kit.cyl(xf * Transform3D(Basis(), Vector3(-0.2, 0.93, 0.22)), 0.04, 0.04, 0.05, "rouge75u", 12)
	var mark := MeshInstance3D.new()
	mark.mesh = _boxm(Vector3(0.12, 0.002, 0.08))
	mark.material_override = _m("encre75u")
	_root("bureaux").add_child(mark)
	mark.global_position = W(fp + Vector3(0.15, 0.774, 0.05))
	mark.rotation.y = 0.2
	mark.visible = false
	var lb := Label3D.new()
	lb.text = "VU"
	lb.font_size = 32
	lb.pixel_size = 0.002
	lb.modulate = Color(0.8, 0.05, 0.08)
	lb.outline_size = 0
	lb.shaded = true
	mark.add_child(lb)
	lb.position = Vector3(0, 0.002, 0)
	lb.rotation.x = -PI * 0.5
	_stamp_marks.append(mark)
	# une plaque de service, debout sur le bureau, et un petit drapeau de la couleur
	_sign("bureaux", fp + Vector3(0.5, 0.92, -0.1), 0.0, 0.5, 0.26, str(FORMS[i][3]) + "\nformulaire " + col.to_upper(), 11, "papier_%s75u" % col, Color(0.1, 0.1, 0.12))
	_cy(xf, Vector3(0.75, 0.76, -0.25), 0.01, 0.01, 0.9, "acier75u", 6)
	kit.box(xf * Transform3D(Basis(), Vector3(0.88, 1.52, -0.25)), Vector3(0.26, 0.18, 0.005), "papier_%s75u" % col, 1.0)


## Recolore un coffre (le coffre de bois du socle) : ici, une armoire ou une caisse à outils de métal.
func _paint_chest(n: String, body_k: String, trim_k: String) -> void:
	for r in rooms:
		var c: Node = (rooms[r]["root"] as Node3D).get_node_or_null("Coffre_" + n)
		if c == null:
			continue
		for mi in c.find_children("*", "MeshInstance3D", true, false):
			var cur: Material = (mi as MeshInstance3D).material_override
			(mi as MeshInstance3D).material_override = _m(body_k) if cur == _m("bois69") else _m(trim_k)


func _build_chaine() -> void:
	_in_room("chaine")
	kit.room(_xf(), -24, 24, 78, 122, -14, 9, "brut75u", "", [["n", 12, 3.4, 4.4], ["s", 12, 3.4, 4.4]], "", T, 3.0)
	kit.solid(X(Vector3(0, -14 + 9 + 0.4, 100)), Vector3(48 + 2 * T, 0.8, 44 + 2 * T), "rouille75u", 3.0, 8)
	# la fosse (le bac des pièces détachées) : son fond, ses murs sous les plates-formes
	kit.solid(X(Vector3(0, PIT - 0.3, 100)), Vector3(48 + 2 * T, 0.6, 44 + 2 * T), "carrelageu75u", 4.0, 4)
	_block(Vector3(-24 - T, PIT, 78 - T), Vector3(24 + T, -14, 78), "brut75u")
	_block(Vector3(-24 - T, PIT, 122), Vector3(24 + T, -14, 122 + T), "brut75u")
	_block(Vector3(-24 - T, PIT, 78), Vector3(-24, -14, 122), "brut75u")
	_block(Vector3(24, PIT, 78), Vector3(24 + T, -14, 122), "brut75u")
	for pl in PLATS:
		_plat(float(pl[0]), float(pl[1]), float(pl[2]), float(pl[3]))
	# le fond de la fosse : des boulons, des ressorts, des engrenages qui tournent
	var rng := RandomNumberGenerator.new()
	rng.seed = 7521
	for k in range(140):
		var p := Vector3(rng.randf_range(-22.0, 22.0), PIT, rng.randf_range(88.0, 112.0))
		if rng.randf() < 0.5:
			kit.cyl(Transform3D(Basis(Vector3(rng.randf() + 0.1, 0, rng.randf()).normalized() if rng.randf() < 0.6 else Vector3.UP, rng.randf() * 3.0), W(p)), 0.05, 0.05, 0.22, "acier75u", 6, true, 1.0)
		else:
			kit.box(Transform3D(Basis(Vector3.UP, rng.randf() * TAU), W(p + Vector3(0, 0.05, 0))), Vector3(0.12, 0.1, 0.12), "rouille75u", 1.0)
	_gears.clear()
	for g in [[Vector3(-4.0, PIT + 1.6, 90.0), 1.5], [Vector3(2.0, PIT + 1.3, 110.0), 1.2], [Vector3(20.0, PIT + 1.6, 100.0), 1.5], [Vector3(-21.0, PIT + 1.2, 108.0), 1.1]]:
		var gn := Node3D.new()
		_root("chaine").add_child(gn)
		gn.global_position = W(g[0])
		var r: float = float(g[1])
		_mesh(gn, _cylm(r, r, 0.25, 24), "rouille75u", Vector3.ZERO, Vector3(PI * 0.5, 0, 0))
		for t in range(12):
			var a: float = TAU * t / 12.0
			_mesh(gn, _boxm(Vector3(0.3, 0.3, 0.25)), "rouille75u", Vector3(cos(a) * (r + 0.12), sin(a) * (r + 0.12), 0), Vector3(0, 0, a))
		_mesh(gn, _cylm(0.2, 0.2, 0.4, 12), "acier75u", Vector3.ZERO, Vector3(PI * 0.5, 0, 0))
		_gears.append(gn)
	# les tapis roulants : la bande (sa propre matière, qui défile), le cadre, les rouleaux, les pieds
	for i in range(BELTS.size()):
		var b: Array = BELTS[i]
		var x0: float = b[0]
		var x1: float = b[1]
		var z0: float = b[2]
		var z1: float = b[3]
		var along_x: bool = (b[4] as Vector3).x != 0.0
		kit.solid(X(Vector3((x0 + x1) * 0.5, -14.2, (z0 + z1) * 0.5)), Vector3(x1 - x0, 0.4, z1 - z0), "tapis75u_%d" % i, 1.0)
		if along_x:
			for s in [z0 - 0.08, z1 + 0.08]:
				_deco(Vector3(x0, -14.55, s - 0.08), Vector3(x1, -13.99, s + 0.08), "jaune75u")
				_rail(Vector3(x0, -14, s + (-0.1 if s < z0 else 0.1)), Vector3(x1, -14, s + (-0.1 if s < z0 else 0.1)))
			var xx: float = x0 + 1.0
			while xx < x1:
				_tube(Vector3(xx, -14.55, z0), Vector3(xx, -14.55, z1), 0.12, "acier75u")
				xx += 1.0
			var xp: float = x0 + 2.0
			while xp < x1 - 0.5:
				_block(Vector3(xp - 0.15, PIT, (z0 + z1) * 0.5 - 0.15), Vector3(xp + 0.15, -14.6, (z0 + z1) * 0.5 + 0.15), "acier75u", 1.0)
				xp += 5.0
		else:
			for s2 in [x0 - 0.08, x1 + 0.08]:
				_deco(Vector3(s2 - 0.08, -14.55, z0), Vector3(s2 + 0.08, -13.99, z1), "jaune75u")
				_rail(Vector3(s2 + (-0.1 if s2 < x0 else 0.1), -14, z0), Vector3(s2 + (-0.1 if s2 < x0 else 0.1), -14, z1))
			var zz: float = z0 + 1.0
			while zz < z1:
				_tube(Vector3(x0, -14.55, zz), Vector3(x1, -14.55, zz), 0.12, "acier75u")
				zz += 1.0
			_block(Vector3((x0 + x1) * 0.5 - 0.15, PIT, (z0 + z1) * 0.5 - 0.15), Vector3((x0 + x1) * 0.5 + 0.15, -14.6, (z0 + z1) * 0.5 + 0.15), "acier75u", 1.0)
		_sign("chaine", Vector3((x0 + x1) * 0.5 if along_x else x0 - 0.3, -14 + 2.4, (z0 + z1) * 0.5 if not along_x else z0 - 0.3), PI * 0.5 if not along_x else 0.0,
			0.9, 0.4, "TAPIS %d" % (i + 1), 40, "jaune75u", Color(0.08, 0.08, 0.08))
		_tube(Vector3((x0 + x1) * 0.5 if along_x else x0 - 0.3, -14 + 2.2, (z0 + z1) * 0.5 if not along_x else z0 - 0.3), Vector3((x0 + x1) * 0.5 if along_x else x0 - 0.3, -5.0, (z0 + z1) * 0.5 if not along_x else z0 - 0.3), 0.02, "acier75u")
	# les rambardes au bord des plates-formes (on laisse la bouche des tapis)
	_rail(Vector3(-24, -14, 86.1), Vector3(-14.35, -14, 86.1))
	_rail(Vector3(-11.65, -14, 86.1), Vector3(24, -14, 86.1))
	_rail(Vector3(-18.1, -14, 96), Vector3(-14.35, -14, 96))
	_rail(Vector3(-11.65, -14, 96), Vector3(-8.1, -14, 96))
	_rail(Vector3(-18.1, -14, 96), Vector3(-18.1, -14, 104))
	_rail(Vector3(-18.1, -14, 104.1), Vector3(-8.1, -14, 104.1))
	_rail(Vector3(-8.1, -14, 96), Vector3(-8.1, -14, 98.65))
	_rail(Vector3(-8.1, -14, 101.35), Vector3(-8.1, -14, 104))
	_rail(Vector3(8.1, -14, 95.9), Vector3(18.1, -14, 95.9))
	_rail(Vector3(18.1, -14, 96), Vector3(18.1, -14, 104))
	_rail(Vector3(8.1, -14, 104.1), Vector3(11.65, -14, 104.1))
	_rail(Vector3(14.35, -14, 104.1), Vector3(18.1, -14, 104.1))
	_rail(Vector3(8.1, -14, 96), Vector3(8.1, -14, 98.65))
	_rail(Vector3(8.1, -14, 101.35), Vector3(8.1, -14, 104))
	_rail(Vector3(-24, -14, 113.9), Vector3(11.65, -14, 113.9))
	_rail(Vector3(14.35, -14, 113.9), Vector3(24, -14, 113.9))
	for pl2 in PLATS:
		var a0: float = float(pl2[0])
		var a1: float = float(pl2[1])
		_stripes(a0, a1, float(pl2[2]), float(pl2[2]) + 0.25, -14.0)
		_stripes(a0, a1, float(pl2[3]) - 0.25, float(pl2[3]), -14.0)
	# le pupitre d'aiguillage, ses trois leviers, le synoptique au mur
	_block(Vector3(-6.0, -14, 83.3), Vector3(-2.0, -13.0, 84.1), "jaune75u", 1.0)
	_deco(Vector3(-6.05, -13.02, 83.25), Vector3(-1.95, -12.98, 84.15), "grisf75u")
	_sign("chaine", Vector3(-4.0, -13.55, 84.12), 0.0, 3.8, 0.8, "AIGUILLAGE DES TAPIS\nLevier 1 : tapis 1 — Levier 2 : tapis 1 et 2 — Levier 3 : tapis 2 et 3\n(Le stagiaire a câblé ça un vendredi.)", 18, "noir75u", Color(1.0, 0.85, 0.2), false)
	_lever_arms.clear()
	for li in range(3):
		_lever_arms.append(_lever75("chaine", LEVERS[li] + Vector3(0, 0, 0)))
		_label("chaine", LEVERS[li] + Vector3(0, 1.08, 0.2), -PI * 0.5 * 0.0, str(li + 1), 40, Color(1, 1, 1), 0.0, 0.004)
	_deco(Vector3(-8.0, -14 + 3.0, 78.0), Vector3(0.0, -14 + 6.4, 78.12), "noir75u")
	_deco(Vector3(-8.1, -14 + 2.9, 77.98), Vector3(0.1, -14 + 6.5, 78.04), "acier75u")
	_synoptic = _label("chaine", Vector3(-3.6, -14 + 4.7, 78.14), 0.0, "", 88, Color(0.4, 1.0, 0.5), 7.0, 0.004)
	_lever_lamps.clear()
	for t in range(3):
		var lm := StandardMaterial3D.new()
		lm.emission_enabled = true
		lm.albedo_color = Color(0.1, 0.1, 0.1)
		lm.emission = Color(1.0, 0.1, 0.06)
		lm.emission_energy_multiplier = 3.0
		var bulb := MeshInstance3D.new()
		bulb.mesh = _sphere(0.12)
		bulb.material_override = lm
		_root("chaine").add_child(bulb)
		bulb.global_position = W(Vector3(-7.4, -14 + 5.6 - t * 0.8, 78.2))
		_lever_lamps.append(lm)
	# les chaînes d'assemblage : des robots déménageurs à moitié montés, des bras robots
	_deco(Vector3(-23.0, -14, 79.6), Vector3(-9.0, -13.1, 80.8), "grisf75u")
	_deco(Vector3(-23.0, -13.1, 79.7), Vector3(-9.0, -13.06, 80.7), "tapis75u")
	kit.col_box(X(Vector3(-16.0, -13.55, 80.2)), Vector3(14.0, 0.9, 1.2))
	_deco(Vector3(-23.0, -14, 119.2), Vector3(-6.0, -13.1, 120.4), "grisf75u")
	_deco(Vector3(-23.0, -13.1, 119.3), Vector3(-6.0, -13.06, 120.3), "tapis75u")
	kit.col_box(X(Vector3(-14.5, -13.55, 119.8)), Vector3(17.0, 0.9, 1.2))
	var built_k: int = 0
	for rz in [80.2, 119.8]:
		var xr: float = -21.5
		while xr < -9.0:
			_robot_shell(Vector3(xr, -13.06, rz), built_k)
			built_k += 1
			xr += 2.6
	_arms.clear()
	_arm("chaine", Vector3(-19.0, -14, 78.6), 0.0, 0.0, true)
	_arm("chaine", Vector3(-13.0, -14, 78.6), 0.0, 1.7, false)
	_arm("chaine", Vector3(-17.0, -14, 121.4), PI, 0.9, true)
	_arm("chaine", Vector3(-10.0, -14, 121.4), PI, 2.6, true)
	# panneaux, affiches, plaque d'étage
	_plaque("chaine", Vector3(12, -14 + 5.1, 78.03), 0.0, 5.0, "ÉTAGE 2 — LA CHAÎNE DE MONTAGE")
	_sign("chaine", Vector3(20.0, -14 + 2.2, 78.03), 0.0, 3.0, 1.2, "OBJECTIF DU JOUR :\n500 ROBOTS DÉMÉNAGEURS\n(et un sourire)", 30, "blanc75u", Color(0.12, 0.13, 0.16), true, "acier75u")
	_sign("chaine", Vector3(-23.97, -14 + 2.2, 100.0), PI * 0.5, 3.2, 1.0, "BAC DES PIÈCES DÉTACHÉES\nNe pas tomber dedans.\n(Le robot-trieur vous rangerait dans « Divers ».)", 26, "jaune75u", Color(0.08, 0.08, 0.08))
	_poster("chaine", Vector3(23.97, -14 + 2.2, 118.0), -PI * 0.5, "UN ROBOT\nPOLI EST\nUN ROBOT\nRENTABLE.", "papier_jaune75u")
	# la lumière : des suspensions industrielles (lampes émissives) et trois lumières
	for lp in [Vector3(-12, 0, 90), Vector3(12, 0, 90), Vector3(-12, 0, 110), Vector3(12, 0, 110), Vector3(0, 0, 100)]:
		_tube(lp + Vector3(0, -5.0, 0), lp + Vector3(0, -8.4, 0), 0.015, "noir75u")
		kit.cyl(X(lp + Vector3(0, -8.8, 0)), 0.55, 0.12, 0.4, "grisf75u", 16, false)
		kit.disc(Transform3D(Basis(Vector3.RIGHT, PI), W(lp + Vector3(0, -8.79, 0))), 0.5, "neon75u", 16)
	_light("chaine", Vector3(-10, -6.5, 92.0), Color(1.0, 0.92, 0.8), 1.2, 22.0, true)
	_light("chaine", Vector3(10, -6.5, 92.0), Color(1.0, 0.92, 0.8), 1.0, 22.0)
	_light("chaine", Vector3(0, -6.5, 114.0), Color(1.0, 0.92, 0.8), 1.1, 24.0)
	_terminal("chaine", TERMINALS[2][0], TERMINALS[2][1])


## Une plate-forme de la Chaîne (de la fosse jusqu'à y = -14), carrelée dessus.
func _plat(x0: float, x1: float, z0: float, z1: float) -> void:
	var c := Vector3((x0 + x1) * 0.5, (PIT - 14.0) * 0.5, (z0 + z1) * 0.5)
	var s := Vector3(x1 - x0, -14.0 - PIT, z1 - z0)
	kit.box(X(c), s, "brut75u", 3.0, 1 | 2 | 16 | 32)
	kit.box(X(c), s, "carrelageu75u", 4.0, 4)
	kit.col_box(X(c), s)


## Un robot déménageur à moitié monté (une carcasse sur la chaîne).
func _robot_shell(l: Vector3, k: int) -> void:
	var xf: Transform3D = X(l, 0.3 * sin(k * 2.1))
	_bx(xf, Vector3(0, 0.35, 0), Vector3(0.7, 0.7, 0.55), "orange75u" if k % 3 != 0 else "grisf75u")
	if k % 2 == 0:
		_bx(xf, Vector3(0, 0.86, 0), Vector3(0.44, 0.32, 0.4), "grisf75u")
		_bx(xf, Vector3(0, 0.88, 0.205), Vector3(0.32, 0.14, 0.01), "ecran75u")
	if k % 3 == 1:
		for s in [-1.0, 1.0]:
			_bx(xf, Vector3(s * 0.46, 0.45, 0), Vector3(0.14, 0.5, 0.14), "acier75u")
	_bx(xf, Vector3(0, 0.02, 0), Vector3(0.8, 0.04, 0.6), "caoutchouc75u")


func _build_chaufferie() -> void:
	_in_room("chaufferie")
	_room75(-20, 24, 150, 196, -28, 10, "brut75u", "carrelageu75u", "rouille75u", [["n", 12, 3.4, 4.4], ["s", 12, 3.4, 4.4]], 3.0, 4.0, 3.0)
	gate("chaufferie", "chaufferie", Vector3(12, -28, 196.4), 3.4, 4.4, 0.6, 0.0, "rivete75u")
	# les deux murs intérieurs (le couloir en lacets), une bande rivetée en bas
	_block(Vector3(-12, -28, 161.6), Vector3(24, -18, 162.4), "brut75u")
	_block(Vector3(-20, -28, 175.6), Vector3(16, -18, 176.4), "brut75u")
	for w in [[-12.0, 24.0, 161.55], [-12.0, 24.0, 162.45], [-20.0, 16.0, 175.55], [-20.0, 16.0, 176.45]]:
		_deco(Vector3(float(w[0]), -28, float(w[2]) - 0.02), Vector3(float(w[1]), -27.0, float(w[2]) + 0.02), "rivete75u")
	# les jets de vapeur : la conduite, la buse, la bande peinte au sol
	_jet_fx.clear()
	_jet_was.clear()
	for j in JETS:
		var jx: float = j[0]
		var z0: float = j[1]
		var z1: float = j[2]
		var nz: Vector3 = Vector3(jx, -28 + 1.3, z0 + 0.05)
		_tube(Vector3(jx, -28 + 1.3, z0), Vector3(jx, -28 + 1.3, z0 + 0.45), 0.12, "rouille75u")
		kit.cyl(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), W(Vector3(jx, -28 + 1.3, z0 + 0.4))), 0.17, 0.1, 0.25, "acier75u", 12, false, 1.0)
		_tube(Vector3(jx, -28 + 1.3, z0 + 0.1), Vector3(jx, -28 + 7.5, z0 + 0.1), 0.1, "rouille75u")
		_stripes(jx - 0.9, jx + 0.9, z0 + 0.1, z1 - 0.1, -28.0)
		_jet_fx.append(_steam(_root("chaufferie"), W(nz + Vector3(0, 0, 0.6)), Vector3(0, 0, 1), (z1 - z0) * 0.9))
		_jet_was.append(false)
	# des conduites au plafond, le long des couloirs
	for zz in [151.2, 160.6, 163.4, 174.6, 177.4, 194.6]:
		_tube(Vector3(-19.5, -28 + 7.5, zz), Vector3(23.5, -28 + 7.5, zz), 0.16 if int(zz) % 2 == 0 else 0.22, "rouille75u")
	# les vannes, le grand manomètre près de la porte
	_valve_wheels.clear()
	for vi in range(VALVES.size()):
		_valve_wheels.append(_valve("chaufferie", VALVES[vi][0], VALVES[vi][1]))
		var vy: float = atan2((VALVES[vi][1] as Vector3).x, (VALVES[vi][1] as Vector3).z)
		_sign("chaufferie", (VALVES[vi][0] as Vector3) + Vector3(0, 2.3, 0) + (VALVES[vi][1] as Vector3) * 0.02, vy, 0.9, 0.3, "VANNE %d" % (vi + 1), 36, "rouge75u", Color(1, 1, 1))
	var gc := Vector3(16.6, -28 + 2.4, 195.96)
	kit.cyl(Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), W(gc)), 0.85, 0.85, 0.12, "acier75u", 28)
	kit.disc(Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), W(gc + Vector3(0, 0, -0.125))), 0.78, "blanc75u", 28)
	for t in range(9):
		var a: float = lerpf(-2.3, 2.3, t / 8.0)
		var red: bool = t >= 6
		kit.box(Transform3D(Basis(Vector3.BACK, -a), W(gc + Vector3(sin(a) * 0.62, cos(a) * 0.62, -0.13))), Vector3(0.05, 0.14, 0.01), "rouge75u" if red else "noir75u", 1.0)
	_gauge_needle = Node3D.new()
	_root("chaufferie").add_child(_gauge_needle)
	_gauge_needle.global_position = W(gc + Vector3(0, 0, -0.14))
	_mesh(_gauge_needle, _boxm(Vector3(0.04, 0.6, 0.01)), "rouge75u", Vector3(0, 0.28, 0))
	_mesh(_gauge_needle, _cylm(0.06, 0.06, 0.02, 12), "noir75u", Vector3.ZERO, Vector3(PI * 0.5, 0, 0))
	_gauge_label = _label("chaufferie", gc + Vector3(0, -1.05, -0.03), PI, "", 30, Color(0.1, 0.1, 0.1), 1.8)
	_gauge_label.shaded = true
	_sign("chaufferie", gc + Vector3(0, -1.05, 0.0), PI, 1.9, 0.5, "", 10, "blanc75u", Color(0, 0, 0))
	_gauge_label.global_position = W(gc + Vector3(0, -1.05, -0.03))
	# les deux chaudières du dernier couloir, leurs foyers
	_boiler_lights.clear()
	_boiler("chaufferie", Vector3(-12.0, -28, 192.0), 2.0, 6.5)
	_boiler("chaufferie", Vector3(-3.0, -28, 192.0), 2.0, 6.5)
	chest("outils", "chaufferie", Vector3(-18.6, -28, 160.0), PI * 0.5, [["piece", 40], ["potion_seve", 1]],
		"La caisse à outils du chauffagiste ! Une clé à molette, des rustines… et des pièces. Sur le couvercle : « Ne pas ouvrir pendant les bouffées. »")
	_paint_chest("outils", "rouge75u", "acier75u")
	_plaque("chaufferie", Vector3(12, -28 + 5.1, 150.03), 0.0, 4.4, "ÉTAGE 3 — LA CHAUFFERIE")
	_sign("chaufferie", Vector3(20.0, -28 + 2.4, 150.03), 0.0, 3.4, 1.2, "ATTENTION : JETS DE VAPEUR\nPasser entre les bouffées.\n(Ou pas. Mais plutôt oui.)", 28, "jaune75u", Color(0.08, 0.08, 0.08))
	_sign("chaufferie", Vector3(10.0, -28 + 2.6, 195.97), PI, 2.4, 1.0, "PORTE DE SÉCURITÉ\ns'ouvre quand la pression\nest « CHAUSSONS »", 24, "blanc75u", Color(0.12, 0.13, 0.16), true, "acier75u")
	_poster("chaufferie", Vector3(-19.97, -28 + 2.2, 170.0), PI * 0.5, "LA CHALEUR\nHUMAINE\nCOÛTE CHER.\nCHAUFFEZ\nLES MACHINES.", "papier_rose75u")
	for lp in [Vector3(-8, -28, 156.0), Vector3(14, -28, 156.0), Vector3(-10, -28, 169.0), Vector3(8, -28, 169.0), Vector3(6, -28, 186.0)]:
		var lx: Transform3D = X(lp + Vector3(0, 9.6, 0))
		_bx(lx, Vector3(0, 0, 0), Vector3(1.3, 0.12, 0.3), "grisf75u")
		_bx(lx, Vector3(0, -0.07, 0), Vector3(1.2, 0.02, 0.22), "neon75u")
	_light("chaufferie", Vector3(4, -28 + 6.0, 156.0), Color(1.0, 0.82, 0.62), 1.0, 20.0)
	_light("chaufferie", Vector3(0, -28 + 6.0, 169.0), Color(1.0, 0.82, 0.62), 1.0, 22.0, true)
	_light("chaufferie", Vector3(10, -28 + 6.0, 186.0), Color(1.0, 0.8, 0.6), 0.8, 18.0)
	_terminal("chaufferie", TERMINALS[3][0], TERMINALS[3][1])


func _cell_center(c: Vector2i) -> Vector3:
	return Vector3(GX0 + GC * (c.x + 0.5), -42.0, GZ0 + GC * (c.y + 0.5))


func _build_entrepot() -> void:
	_in_room("entrepot")
	_room75(-24, 24, 224, 272, -42, 12, "tole75u", "beton75u", "rouille75u", [["n", 12, 3.4, 4.4], ["s", 12, 3.4, 4.4]], 3.0, 4.0, 3.0)
	gate("entrepot", "entrepot", Vector3(12, -42, 272.4), 3.4, 4.4, 0.6, 0.0, "tole75u")
	# les rayonnages (deux rangées, une le long du mur est), les marquages au sol
	_rack(6.0, 8.0, 232.0, 246.0, -42.0, 9.0, 4, 7541)
	_rack(6.0, 8.0, 250.0, 266.0, -42.0, 9.0, 4, 7542)
	_rack(16.0, 18.0, 232.0, 246.0, -42.0, 9.0, 4, 7543)
	_rack(16.0, 18.0, 250.0, 266.0, -42.0, 9.0, 4, 7544)
	_rack(22.2, 24.0, 228.0, 268.0, -42.0, 9.0, 4, 7545)
	_rack(-24.0, -18.0, 226.0, 254.0, -42.0, 7.0, 3, 7546)
	_rack(-18.0, -2.0, 266.0, 272.0, -42.0, 7.0, 3, 7547)
	for x in [5.4, 8.6, 15.4, 18.6]:
		_deco(Vector3(x - 0.05, -42, 230.0), Vector3(x + 0.05, -41.99, 268.0), "jaune75u")
	# la zone des caisses : son cadre peint, les piles fixes, le quai, la mezzanine du badge
	for s in [[GX0, GX0 + GC * GNI, GZ0 - 0.06, GZ0 + 0.06], [GX0, GX0 + GC * GNI, GZ0 + GC * GNJ - 0.06, GZ0 + GC * GNJ + 0.06],
			[GX0 + GC * GNI - 0.06, GX0 + GC * GNI + 0.06, GZ0, GZ0 + GC * GNJ]]:
		_deco(Vector3(float(s[0]), -42, float(s[2])), Vector3(float(s[1]), -41.99, float(s[3])), "jaune75u")
	for ci in range(GNI + 1):
		_deco(Vector3(GX0 + GC * ci - 0.015, -42, GZ0), Vector3(GX0 + GC * ci + 0.015, -41.995, GZ0 + GC * GNJ), "grisf75u")
	for cj in range(GNJ + 1):
		_deco(Vector3(GX0, -42, GZ0 + GC * cj - 0.015), Vector3(GX0 + GC * GNI, -41.995, GZ0 + GC * cj + 0.015), "grisf75u")
	for ob in OBST:
		_pallet_stack(_cell_center(ob), 7550 + ob.x * 13 + ob.y)
	_block(Vector3(-24, -42, 254), Vector3(-18, -40, 262), "beton75u", 2.0)
	_stripes(-18.3, -18.0, 254.0, 262.0, -40.0)
	_deco(Vector3(-18.02, -41.0, 254.0), Vector3(-17.98, -40.0, 262.0), "hachures75u", 0.8)
	_block(Vector3(-24, -42, 262), Vector3(-18, -39.0, 272), "grisf75u", 2.0)
	_deco(Vector3(-24, -39.0, 262), Vector3(-18, -38.985, 272), "bois75u", 1.5)
	for zr in [263.0, 266.0, 269.0, 271.9]:
		_deco(Vector3(-18.1, -42, zr - 0.05), Vector3(-17.98, -39.1, zr + 0.05), "bleu75u")
	_deco(Vector3(-18.1, -40.6, 262), Vector3(-17.98, -40.45, 272), "orange75u")
	_rail(Vector3(-18.2, -39.0, 264.2), Vector3(-18.2, -39.0, 272.0))
	_sign("entrepot", Vector3(-17.94, -40.6, 258.0), PI * 0.5, 1.8, 0.5, "QUAI DE CHARGEMENT\n(2 m : trop haut ? une caisse !)", 22, "jaune75u", Color(0.08, 0.08, 0.08))
	_sign("entrepot", Vector3(-1.8, -42 + 2.6, GZ0 + 0.05), 0.0, 3.0, 0.9, "ZONE DE STOCKAGE\nCaisses à pousser. Ne pas pousser les robots.", 24, "blanc75u", Color(0.12, 0.13, 0.16), true, "jaune75u")
	# le badge, là-haut, qui brille
	_badge_node = Node3D.new()
	_badge_node.name = "Badge"
	_root("entrepot").add_child(_badge_node)
	_badge_node.global_position = W(BADGE_AT + Vector3(0, 0.9, 0))
	_mesh(_badge_node, _boxm(Vector3(0.34, 0.22, 0.012)), "blanc75u", Vector3.ZERO)
	_mesh(_badge_node, _boxm(Vector3(0.1, 0.12, 0.014)), "bleu75u", Vector3(-0.09, 0.0, 0.0))
	_mesh(_badge_node, _boxm(Vector3(0.08, 0.05, 0.02)), "acier75u", Vector3(0, 0.13, 0))
	var bl := Label3D.new()
	bl.text = "BADGE\nACCÈS -5"
	bl.font_size = 18
	bl.pixel_size = 0.002
	bl.modulate = Color(0.1, 0.1, 0.15)
	bl.outline_size = 0
	_badge_node.add_child(bl)
	bl.position = Vector3(0.06, 0, 0.008)
	var bgl := OmniLight3D.new()
	bgl.light_color = Color(0.6, 0.85, 1.0)
	bgl.light_energy = 0.9
	bgl.omni_range = 3.5
	_badge_node.add_child(bgl)
	# les caisses à pousser, le gros bouton rouge
	_crates.clear()
	for ci2 in range(CRATES0.size()):
		_crates.append(_crate75("entrepot", ci2))
	var bx: Transform3D = X(RESET_BTN, 0.0)
	_bx(bx, Vector3(0, 0.55, 0), Vector3(0.4, 1.1, 0.4), "jaune75u")
	_cy(bx, Vector3(0, 1.1, 0), 0.16, 0.16, 0.08, "rouge75u", 16)
	kit.col_box(bx * Transform3D(Basis(), Vector3(0, 0.55, 0)), Vector3(0.4, 1.1, 0.4))
	_sign("entrepot", RESET_BTN + Vector3(0, 1.6, 0.21), 0.0, 0.9, 0.36, "RANGEMENT\nAUTOMATIQUE", 26, "rouge75u", Color(1, 1, 1))
	# les chariots élévateurs robots
	_forks.clear()
	for f in FORKS:
		var fk: Array = _forklift("entrepot")
		_forks.append([fk[0], W(f[0]), W(f[1]), float(f[2]), fk[1]])
		(fk[0] as Node3D).global_position = W(f[0])
	# la porte du bas et son lecteur de badge
	var rx: Transform3D = X(Vector3(14.5, -42, 271.95), PI)
	_bx(rx, Vector3(0, 1.3, 0.06), Vector3(0.3, 0.45, 0.1), "grisf75u")
	_bx(rx, Vector3(0, 1.32, 0.112), Vector3(0.2, 0.14, 0.01), "noir75u")
	_reader_led = StandardMaterial3D.new()
	_reader_led.emission_enabled = true
	_reader_led.albedo_color = Color(0.2, 0.05, 0.05)
	_reader_led.emission = Color(1.0, 0.1, 0.06)
	_reader_led.emission_energy_multiplier = 3.0
	var led := MeshInstance3D.new()
	led.mesh = _boxm(Vector3(0.08, 0.04, 0.02))
	led.material_override = _reader_led
	_root("entrepot").add_child(led)
	led.global_position = W(Vector3(14.5, -42 + 1.47, 271.84))
	_sign("entrepot", Vector3(12, -42 + 5.0, 271.97), PI, 3.4, 0.6, "ACCÈS -5 : BADGE OBLIGATOIRE", 30, "rouge75u", Color(1, 1, 1))
	_plaque("entrepot", Vector3(12, -42 + 5.1, 224.03), 0.0, 5.4, "ÉTAGE 4 — L'ENTREPÔT AUTOMATIQUE")
	_poster("entrepot", Vector3(-23.97, -42 + 2.0, 257.0), PI * 0.5, "RANGER,\nC'EST\nOPTIMISER\nL'ESPACE\nVIDE.", "papier_bleu75u")
	# les suspensions (lampes de hangar) et trois lumières
	for lp in [Vector3(-10, 0, 232), Vector3(12, 0, 232), Vector3(-10, 0, 252), Vector3(12, 0, 252), Vector3(1, 0, 266), Vector3(20, 0, 260)]:
		_tube(lp + Vector3(0, -30.0, 0), lp + Vector3(0, -32.6, 0), 0.015, "noir75u")
		kit.cyl(X(lp + Vector3(0, -33.0, 0)), 0.6, 0.15, 0.4, "grisf75u", 16, false)
		kit.disc(Transform3D(Basis(Vector3.RIGHT, PI), W(lp + Vector3(0, -32.99, 0))), 0.55, "neon75u", 16)
	_light("entrepot", Vector3(-9, -42 + 8.5, 244.0), Color(0.95, 0.96, 1.0), 1.2, 24.0, true)
	_light("entrepot", Vector3(12, -42 + 8.5, 236.0), Color(0.95, 0.96, 1.0), 1.0, 22.0)
	_light("entrepot", Vector3(10, -42 + 8.5, 262.0), Color(0.95, 0.96, 1.0), 1.0, 22.0)
	_light("entrepot", Vector3(-15, -42 + 7.0, 262.0), Color(0.95, 0.96, 1.0), 0.9, 16.0)
	_terminal("entrepot", TERMINALS[4][0], TERMINALS[4][1])


func _build_fosse() -> void:
	_in_room("fosse")
	_room75(-8, 32, 300, 340, -56, 18, "beton75u", "brut75u", "rouille75u", [["n", 12, 3.4, 4.4]], 3.0, 4.0, 3.0)
	# la bande rivetée en bas des murs, le cercle peint de l'arène, les piliers
	for s in [[-8.0, 32.0, 300.0, 300.06], [-8.0, 32.0, 339.94, 340.0], [-8.0, -7.94, 300.0, 340.0], [31.94, 32.0, 300.0, 340.0]]:
		_deco(Vector3(float(s[0]), -56, float(s[2])), Vector3(float(s[1]), -54.2, float(s[3])), "rivete75u")
	kit.ring(X(Vector3(12, -55.995, 322.0)), 13.6, 14.2, 0.01, "jaune75u", 64)
	_stripes(-8.0, 32.0, 300.0, 300.7, -56.0)
	for pp in [Vector3(-3.0, -56, 308.0), Vector3(27.0, -56, 308.0), Vector3(-3.0, -56, 334.0), Vector3(27.0, -56, 334.0)]:
		_block(pp + Vector3(-0.45, 0, -0.3), pp + Vector3(0.45, 18, 0.3), "rouille75u", 2.0)
		_deco(pp + Vector3(-0.12, 0, -0.32), pp + Vector3(0.12, 18, 0.32), "acier75u")
		_deco(pp + Vector3(-0.5, 0, -0.5), pp + Vector3(0.5, 1.2, 0.5), "hachures75u", 0.8)
	for zb in [306.0, 316.0, 326.0, 336.0]:
		_deco(Vector3(-8, -38.9, zb - 0.3), Vector3(32, -38.0, zb + 0.3), "rouille75u")
	# le bureau vitré du Président, en haut du mur sud
	_block(Vector3(2.0, -56 + 6.6, 335.0), Vector3(22.0, -56 + 7.0, 340.0), "acier75u", 2.0)
	_deco(Vector3(2.0, -56 + 7.0, 335.0), Vector3(22.0, -56 + 7.05, 340.0), "moquette75u")
	_deco(Vector3(2.0, -56 + 7.0, 335.0), Vector3(2.1, -56 + 10.5, 340.0), "acier75u")
	_deco(Vector3(21.9, -56 + 7.0, 335.0), Vector3(22.0, -56 + 10.5, 340.0), "acier75u")
	_deco(Vector3(2.0, -56 + 10.4, 335.0), Vector3(22.0, -56 + 10.6, 340.0), "acier75u")
	_deco(Vector3(2.1, -56 + 7.05, 334.95), Vector3(21.9, -56 + 10.4, 335.05), "verre75u")
	for xm in [7.0, 12.0, 17.0]:
		_deco(Vector3(xm - 0.04, -56 + 7.0, 334.9), Vector3(xm + 0.04, -56 + 10.4, 335.1), "acier75u")
	for k in range(5):
		var by: Transform3D = X(Vector3(5.0 + k * 3.6, -56 + 6.6, 335.0), 0.0)
		_tube(Vector3(5.0 + k * 3.6, -56, 335.3), Vector3(5.0 + k * 3.6, -56 + 6.6, 335.3), 0.12, "acier75u")
		kit.col_cyl(W(Vector3(5.0 + k * 3.6, -56, 335.3)), 0.14, 6.6)
		_bx(by, Vector3(0, -0.2, 0.0), Vector3(0.3, 0.4, 0.3), "acier75u")
	var ox: Transform3D = X(Vector3(12, -56 + 7.05, 337.6), PI)
	_bx(ox, Vector3(0, 0.74, 0), Vector3(2.6, 0.06, 1.1), "bois75u")
	_bx(ox, Vector3(0, 0.37, 0.4), Vector3(2.5, 0.72, 0.04), "bois75u")
	_bx(ox, Vector3(0, 1.4, 1.0), Vector3(0.8, 1.4, 0.2), "rouge75u")
	_bx(ox, Vector3(0, 0.5, 1.0), Vector3(0.7, 0.12, 0.7), "rouge75u")
	_bx(ox, Vector3(0.8, 0.95, -0.1), Vector3(0.3, 0.38, 0.03), "noir75u")
	for kx in [-7.0, 7.0]:
		var sx: Transform3D = X(Vector3(12 + kx, -56 + 7.05, 338.6), PI)
		_cy(sx, Vector3.ZERO, 0.3, 0.3, 0.6, "acier75u", 16)
		_cy(sx, Vector3(0, 0.6, 0), 0.22, 0.18, 1.3, "cuivre75u", 14)
		kit.box(sx * Transform3D(Basis(), Vector3(0, 2.05, 0)), Vector3(0.3, 0.32, 0.28), "cuivre75u", 1.0)
	_sign("fosse", Vector3(12, -56 + 6.2, 334.94), PI, 6.0, 0.6, "BUREAU DU PRÉSIDENT — M. ALDRIC LISSE", 34, "noir75u", Color(1.0, 0.82, 0.35), false)
	# le grand écran d'OPTIMUS-LISSE, au-dessus du bureau
	var sc := Vector3(12, -56 + 13.6, 339.9)
	_deco(sc + Vector3(-6.0, -3.2, -0.25), sc + Vector3(6.0, 3.2, 0.1), "noir75u")
	_deco(sc + Vector3(-5.6, -2.9, -0.27), sc + Vector3(5.6, 2.9, -0.255), "ecran75u")
	_screen_face = Node3D.new()
	_screen_face.name = "Optimus"
	_root("fosse").add_child(_screen_face)
	_screen_face.global_transform = X(sc + Vector3(0, 0, -0.29), PI)
	_screen_eyes.clear()
	for s2 in [-1.0, 1.0]:
		_screen_eyes.append(_mesh(_screen_face, _boxm(Vector3(1.5, 0.5, 0.02)), "optimus75u", Vector3(s2 * 1.9, 0.9, 0), Vector3(0, 0, s2 * 0.18)))
		_mesh(_screen_face, _boxm(Vector3(1.6, 0.12, 0.02)), "optimus75u", Vector3(s2 * 1.9, 1.55, 0), Vector3(0, 0, -s2 * 0.25))
	_screen_mouth = Node3D.new()
	_screen_face.add_child(_screen_mouth)
	_screen_mouth.position = Vector3(0, -1.2, 0)
	_mesh(_screen_mouth, _boxm(Vector3(4.2, 0.22, 0.02)), "optimus75u", Vector3.ZERO)
	var on := Label3D.new()
	on.text = "OPTIMUS-LISSE v9.99"
	on.font_size = 56
	on.pixel_size = 0.006
	on.modulate = Color(1.0, 0.2, 0.12)
	on.outline_size = 0
	on.double_sided = false
	_screen_face.add_child(on)
	on.position = Vector3(0, -2.45, 0)
	_screen_bsod = Node3D.new()
	_root("fosse").add_child(_screen_bsod)
	_screen_bsod.global_transform = X(sc + Vector3(0, 0, -0.29), PI)
	_mesh(_screen_bsod, _boxm(Vector3(11.1, 5.7, 0.01)), "bsod75u", Vector3.ZERO)
	var bs := Label3D.new()
	bs.text = ":(\n\nOPTIMUS-LISSE a rencontré un problème et doit redémarrer.\nNous récupérons quelques informations sur l'erreur…\n\n0 % effectué (pour toujours)"
	bs.font_size = 48
	bs.pixel_size = 0.006
	bs.width = 1700
	bs.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bs.modulate = Color(1, 1, 1)
	bs.outline_size = 0
	bs.double_sided = false
	_screen_bsod.add_child(bs)
	bs.position = Vector3(0, 0, 0.02)
	_screen_bsod.visible = false
	_screen_light = _light("fosse", sc + Vector3(0, -2.0, -3.0), Color(1.0, 0.15, 0.1), 1.6, 20.0, false, 1.0)
	# les gyrophares rouges (ils tournent pendant le combat)
	_beacons.clear()
	for bp in [Vector3(-7.6, -56 + 9.0, 320.0), Vector3(31.6, -56 + 9.0, 320.0)]:
		var inw := Vector3(1, 0, 0) if bp.x < 0 else Vector3(-1, 0, 0)
		_deco(bp + Vector3(-0.2, -0.25, -0.2) + inw * 0.2, bp + Vector3(0.2, -0.15, 0.2) + inw * 0.2, "acier75u")
		var bn := Node3D.new()
		_root("fosse").add_child(bn)
		bn.global_position = W(bp + inw * 0.2)
		_mesh(bn, _cylm(0.16, 0.14, 0.3, 14), "rougeon75u", Vector3(0, 0, 0))
		_mesh(bn, _boxm(Vector3(0.04, 0.26, 0.34)), "acier75u", Vector3(0, 0, 0))
		var bli := _light("fosse", bp + inw * 1.0, Color(1.0, 0.08, 0.05), 0.0, 22.0, false, 1.0)
		_beacons.append([bn, bli])
	# le monte-charge (coin nord-est) : plateau, cage, lampe (rouge, puis verte)
	_block(LIFT + Vector3(-3.0, -0.3, -3.0), LIFT + Vector3(3.0, 0.08, 3.0), "rivete75u", 2.0)
	_stripes(LIFT.x - 3.0, LIFT.x + 3.0, LIFT.z + 2.7, LIFT.z + 3.0, -55.92)
	for cp in [Vector3(-3, 0, -3), Vector3(3, 0, -3), Vector3(-3, 0, 3), Vector3(3, 0, 3)]:
		_deco(LIFT + cp + Vector3(-0.1, 0, -0.1), LIFT + cp + Vector3(0.1, 18, 0.1), "jaune75u")
	for y in [1.1, 2.2, 3.3]:
		_tube(LIFT + Vector3(-3, y, -3), LIFT + Vector3(-3, y, 3), 0.03, "jaune75u")
		_tube(LIFT + Vector3(-3, y, -3), LIFT + Vector3(3, y, -3), 0.03, "jaune75u")
		_tube(LIFT + Vector3(3, y, -3), LIFT + Vector3(3, y, 3), 0.03, "jaune75u")
	_deco(LIFT + Vector3(-3, 6.0, -3), LIFT + Vector3(3, 6.3, 3), "jaune75u")
	_lift_lamp = StandardMaterial3D.new()
	_lift_lamp.emission_enabled = true
	_lift_lamp.albedo_color = Color(0.2, 0.05, 0.05)
	_lift_lamp.emission = Color(1.0, 0.1, 0.06)
	_lift_lamp.emission_energy_multiplier = 3.0
	var ll := MeshInstance3D.new()
	ll.mesh = _sphere(0.18)
	ll.material_override = _lift_lamp
	_root("fosse").add_child(ll)
	ll.global_position = W(LIFT + Vector3(-2.6, 2.6, 3.05))
	_sign("fosse", LIFT + Vector3(0, 4.4, 3.1), PI, 4.0, 0.8, "MONTE-CHARGE\nRÉSERVÉ À LA DIRECTION", 34, "jaune75u", Color(0.08, 0.08, 0.08))
	_plaque("fosse", Vector3(12, -56 + 5.1, 300.03), 0.0, 5.4, "ÉTAGE 5 — LA FOSSE DU PRÉSIDENT")
	_light("fosse", Vector3(4, -56 + 12.0, 312.0), Color(1.0, 0.9, 0.82), 1.3, 30.0, true)
	_light("fosse", Vector3(20, -56 + 12.0, 328.0), Color(1.0, 0.9, 0.82), 1.1, 30.0)
	for lp in [Vector3(2, 0, 312), Vector3(22, 0, 312), Vector3(2, 0, 330), Vector3(22, 0, 330)]:
		kit.cyl(X(lp + Vector3(0, -38.6, 0)), 0.7, 0.2, 0.5, "grisf75u", 16, false)
		kit.disc(Transform3D(Basis(Vector3.RIGHT, PI), W(lp + Vector3(0, -38.59, 0))), 0.65, "neon75u", 16)
	_terminal("fosse", TERMINALS[5][0], TERMINALS[5][1])


# =================================================================== invites du donjon

func _register() -> void:
	var me = self
	ia("sortir", Vector3(0, 0, 1.3), 1.6, "E : ressortir (le portail de l'usine)", "Gâchette : ressortir",
		func(): me.leave("Les portes vitrées coulissent dans un « pschhh » poli. L'air de Port-Boucan sent la mer, la soupe et la peinture fraîche. Ça fait du bien."))
	_shortcut_ia = ia("ascenseur", ELEVATOR + Vector3(1.3, 0, 0), 1.6, "E : prendre l'ascenseur de service", "Gâchette : l'ascenseur de service",
		func(): me._shortcut(), func(): return me.deepest() >= 2)
	ia("ascenseur_hs", ELEVATOR + Vector3(1.3, 0, 0), 1.6, "E : appeler l'ascenseur de service", "Gâchette : appeler l'ascenseur",
		func(): me._say("Ding ! Une voix polie : « L'ascenseur de service ne dessert que les étages déjà visités. Vous n'avez rien visité. C'est triste. » Les portes restent fermées.", 7.0),
		func(): return me.deepest() < 2)
	ia("accueillotron", Vector3(-3.6, 0, 8.6), 1.4, "E : parler à l'Accueillotron", "Gâchette : l'Accueillotron", func(): me._accueillotron())
	ia("ticket", Vector3(2.9, 0, 5.0), 1.1, "E : prendre un ticket", "Gâchette : prendre un ticket", func(): me._take_ticket())
	ia("plan", Vector3(7.0, 0, 10.2), 1.2, "E : lire le plan des étages", "Gâchette : le plan des étages",
		func(): me._say("« LISSE & FILS — Plan des étages. -1 : les Bureaux. -2 : la Chaîne de Montage. -3 : la Chaufferie. -4 : l'Entrepôt Automatique. -5 : la Fosse du Président (accès interdit, surtout à vous). » Quelqu'un a ajouté au feutre : « et tout en bas : la machine qui veut raser le Boucan ».", 10.0))
	for k in range(1, 6):
		var kk: int = k
		var tp: Vector3 = TERMINALS[k][0]
		var tf: Vector3 = TERMINALS[k][1]
		ia("terminal_%d" % k, tp + tf * 1.0, 1.3, "E : terminal de sortie (remonter à la surface)", "Gâchette : terminal de sortie", func(): me._terminal_return(kk))
	# les Bureaux
	ia("note", MEMO + Vector3(0, 0, 1.0), 1.3, "E : lire la note de service", "Gâchette : la note de service", func(): me._read_memo())
	for i in range(FORMS.size()):
		var ii: int = i
		ia("tampon_%d" % i, (FORMS[i][0] as Vector3) + Vector3(0, 0, 1.05), 0.95, "E : tamponner le formulaire %s" % str(FORMS[i][1]),
			"Gâchette : tamponner le formulaire %s" % str(FORMS[i][1]), func(): me._stamp(ii), func(): return not me.gate_open("bureaux"))
	ia("fontaine", Vector3(-18.6, 0, 30.0), 1.2, "E : boire un verre d'eau", "Gâchette : boire un verre d'eau", func(): me._drink())
	# la Chaîne : les leviers d'aiguillage, le synoptique
	for li in range(3):
		var lj: int = li
		ia("levier_%d" % li, LEVERS[li] + Vector3(0, 0, 1.1), 0.6, "E : basculer le levier %d" % (li + 1), "Gâchette : levier %d" % (li + 1), func(): me._pull(lj))
	# la Chaufferie : les vannes
	for vi in range(3):
		var vj: int = vi
		ia("vanne_%d" % vi, (VALVES[vi][0] as Vector3) + (VALVES[vi][1] as Vector3) * 1.0, 1.4, "E : tourner la vanne %d" % (vi + 1), "Gâchette : tourner la vanne %d" % (vi + 1),
			func(): me._turn_valve(vj), func(): return not bool((me.state["vannes"] as Array)[vj]))
	# l'Entrepôt : les caisses, le bouton, le badge, la porte
	_crate_ia.clear()
	for ci in range(CRATES0.size()):
		var cj: int = ci
		_crate_ia.append(ia("caisse_%d" % ci, _cell_center(CRATES0[ci]), 1.75, "E : pousser la caisse", "Gâchette : pousser la caisse", func(): me._push_crate(cj),
			func(): return not me._crate_busy and me.L(me._feet()).y < -41.4))
	ia("rangement", RESET_BTN + Vector3(0, 0, 0.9), 1.1, "E : appuyer sur le gros bouton rouge", "Gâchette : le gros bouton rouge", func(): me._reset_crates())
	ia("badge", BADGE_AT, 1.6, "E : prendre le badge de l'usine", "Gâchette : prendre le badge", func(): me._take_badge(),
		func(): return not bool(me.state["badge"]) and me.L(me._feet()).y > -39.6)
	ia("porte_badge", Vector3(12, -42, 270.6), 2.0, "E : passer le badge", "Gâchette : passer le badge", func(): me._badge_door(), func(): return not me.gate_open("entrepot"))
	# la Fosse : le monte-charge
	ia("monte_charge", LIFT, 2.4, "E : prendre le monte-charge (vers la surface)", "Gâchette : le monte-charge", func(): me._take_lift(), func(): return bool(me.state["fini"]))
	ia("monte_charge_hs", LIFT, 2.4, "E : appuyer sur le bouton du monte-charge", "Gâchette : le monte-charge",
		func(): me._say("BZZT. Une lampe rouge clignote : « MONTE-CHARGE RÉSERVÉ À LA DIRECTION. Veuillez d'abord vaincre la direction. »", 6.0),
		func(): return not bool(me.state["fini"]))


## Le coffre ouvert : seulement les objets que le sac connaît.
func _known(id: String) -> bool:
	return (_inv().ITEMS as Dictionary).has(id)


func _open_chest(n: String, c: Node3D, contents: Array, text: String) -> void:
	var ok: Array = []
	for g in contents:
		if _known(str(g[0])):
			ok.append(g)
	super._open_chest(n, c, ok, text)


func _snd(n: String, at: Vector3) -> void:
	var s: Node = main.get("sfx_v50") if main != null else null
	var nn: String = n
	if s != null and s.has_method("_variants") and (s._variants(n) as Array).is_empty() and SND_FB.has(n):
		nn = str(SND_FB[n])
	if nn != "":
		_sfx(nn, at)


func _apply_state() -> void:
	super._apply_state()
	_stamps.clear()
	var stamped: bool = gate_open("bureaux")
	for mk in _stamp_marks:
		(mk as Node3D).visible = stamped
	if _turnstile_arm != null:
		_turnstile_arm.rotation.z = -PI * 0.5 if stamped else 0.0
	if _turnstile_lamp != null:
		_turnstile_lamp.emission = Color(0.2, 1.0, 0.35) if stamped else Color(1.0, 0.1, 0.06)
	var lv: Array = state["leviers"]
	for i in range(_lever_arms.size()):
		(_lever_arms[i] as Node3D).rotation.x = 0.6 if bool(lv[i]) else -0.6
	_update_belts()
	var va: Array = state["vannes"]
	for v in range(_valve_wheels.size()):
		var w: Node3D = _valve_wheels[v]
		var b0: Basis = w.get_meta("b0")
		w.transform.basis = b0 * Basis(Vector3(0, 0, 1), -TAU * 1.5) if bool(va[v]) else b0
	_update_gauge(false)
	for j in range(_jet_fx.size()):
		(_jet_fx[j] as CPUParticles3D).emitting = false
		_jet_was[j] = false
	var cells: Array = _crate_cells()
	for c in range(_crates.size()):
		var at: Vector3 = _cell_center(cells[c])
		(_crates[c] as Node3D).global_position = W(at)
		if c < _crate_ia.size():
			(_crate_ia[c] as Dictionary)["pos"] = W(at)
	_crate_busy = false
	if _badge_node != null:
		_badge_node.visible = not bool(state["badge"])
	if _reader_led != null:
		_reader_led.emission = Color(0.2, 1.0, 0.35) if gate_open("entrepot") else Color(1.0, 0.1, 0.06)
	_lift_ready(bool(state["fini"]))
	_screen_state()
	_beacons_on(false)


## Ce qui, dehors, dépend de l'état du donjon : rien ici (le gestionnaire lit state et trouvailles()).
func _apply_outdoor() -> void:
	pass


# =================================================================== l'accueil, les terminaux

func _terminal_return(k: int) -> void:
	var tp: Vector3 = TERMINALS[k][0]
	_snd("robot_bip", W(tp + Vector3(0, 1.4, 0)))
	if k == 1:
		leave("Le terminal clignote : « > REMONTER ? [O] ». Tu tapes « O ». Bip ! Les portes vitrées s'ouvrent… et te revoilà au grand jour, devant le portail de l'Usine Grise.")
		return
	leave("Le terminal clignote : « > REMONTER ? [O] ». Tu tapes « O ». L'écran devient tout vert, un panneau coulisse, un tapis secret t'emporte en zigzag… et te revoilà au grand jour, devant le portail de l'Usine Grise. (Le terminal a noté : étage %d.)" % deepest())


func _shortcut() -> void:
	var k: int = clampi(deepest(), 2, 5)
	_snd("monte_charge", W(ELEVATOR + Vector3(0.5, 1.5, 0)))
	_say("Ding ! « Ascenseur de service. Descente vers l'étage %d : %s. Veuillez patienter en écoutant cette musique d'attente optimisée. » Pouêt-pouêt-pouêêêt…" % [k, FLOOR_NAMES[k]], 6.0)
	await main.donjon_v35._travel(W(ARRIVE[k]), Vector3(0, 0, 1))
	checkpoint = [W(ARRIVE[k]), Vector3(0, 0, 1)]
	_mood(_room_of(_feet()))


func _accueillotron() -> void:
	var lines := ["L'Accueillotron tourne la tête (vrrr) : « Bonjour. Votre visite est importante pour nous. C'est pourquoi elle sera traitée dans l'ordre d'arrivée, en 2087. »",
		"L'Accueillotron : « Pour descendre, adressez-vous aux Bureaux. Pour remonter, adressez-vous aux terminaux. Pour vous plaindre, adressez-vous au mur. »",
		"L'Accueillotron : « Monsieur Lisse n'est pas disponible. Monsieur Lisse n'est jamais disponible. C'est ce qui fait son charme. »",
		"L'Accueillotron : « Puis-je vous proposer un verre d'eau ? Non ? Parfait : c'est plus optimal. »",
		"L'Accueillotron baisse la voix : « Entre nous… les punks d'en haut font de la très bonne soupe. Ne le répétez pas. Bip. »"]
	_snd("robot_bip", W(Vector3(-3.6, 1.3, 10.4)))
	_say(lines[randi() % lines.size()], 7.0)


func _take_ticket() -> void:
	_ticket += 1
	_snd("photocopieuse", W(Vector3(3.8, 1.2, 5.0)))
	_say("Bzzt ! Le distributeur crache un ticket : « N° %d. Numéro actuellement servi : 12. Temps d'attente estimé : 31 ans et 2 mois. Merci de votre patience. »" % _ticket, 6.0)


func _drink() -> void:
	_snd("boire", W(Vector3(-19.4, 1.2, 30.0)))
	var hero: Node = main.get("hero_v28")
	if not _cooler_used and hero != null and hero.has_method("heal"):
		_cooler_used = true
		hero.heal(2)
		_say("Glou, glou. L'eau a un goût de… rien du tout. Optimisé. Ça fait quand même du bien (un cœur de plus).", 5.0)
	else:
		_say("Le gobelet en plastique dit : « Un seul verre par visite. L'hydratation est un coût. »", 4.0)


# =================================================================== les Bureaux : les tampons

func _read_memo() -> void:
	_say("NOTE DE SERVICE n° 4 512-B. « Pour descendre, tamponner les formulaires dans l'ordre réglementaire : LE CIEL avant LE SOLEIL, LE SOLEIL avant LA BARBE À PAPA. (Ne demandez pas pourquoi. C'est la procédure.) — La Direction. » Trois bureaux ont un formulaire de couleur : un bleu, un jaune, un rose.", 12.0)


func _stamp(i: int) -> void:
	if gate_open("bureaux"):
		return
	if _stamps.has(i):
		_say("Ce formulaire est déjà tamponné. (Deux fois, ce serait du zèle. Le zèle est interdit le mardi.)", 4.0)
		return
	var at: Vector3 = W((FORMS[i][0] as Vector3) + Vector3(0, 0.9, 0))
	_snd("tampon_bureau", at)
	if i < _stamp_marks.size():
		(_stamp_marks[i] as Node3D).visible = true
	_stamps.append(i)
	var n: int = _stamps.size()
	if int(STAMP_ORDER[n - 1]) != i:
		_say("POF ! Tu tamponnes le formulaire %s… Quelque part, une photocopieuse se met à ronronner. Oh oh." % str(FORMS[i][1]), 3.0)
		await get_tree().create_timer(1.2).timeout
		_refuse(i)
		return
	if n < 3:
		_say(["POF ! « VU » en rouge sur %s (le formulaire %s). Le tourniquet fait « tic ». Encore deux.", "POF ! « VU » sur %s (le formulaire %s). Le tourniquet fait « tic-tic ». Plus qu'un !"][n - 1] % [str(FORMS[i][2]), str(FORMS[i][1])], 5.0)
		_snd("tourniquet", W(Vector3(10.3, 1.0, 49.4)))
		return
	_say("POF ! Le troisième « VU ». Les trois formulaires sont en règle : le ciel, le soleil, la barbe à papa. Quelque part, un fonctionnaire verse une larme de joie.", 5.0)
	await get_tree().create_timer(1.0).timeout
	_snd("tourniquet", W(Vector3(10.3, 1.0, 49.4)))
	if _turnstile_arm != null:
		create_tween().tween_property(_turnstile_arm, "rotation:z", -PI * 0.5, 0.5).set_trans(Tween.TRANS_BOUNCE)
	if _turnstile_lamp != null:
		_turnstile_lamp.emission = Color(0.2, 1.0, 0.35)
	open_gate("bureaux", "Clac ! Le bras du tourniquet tombe, la lampe passe au vert, et le rideau de fer s'enfonce dans le sol. « SORTIE DU PERSONNEL AUTORISÉE. BONNE DESCENTE. » L'escalier de service mène à la Chaîne de Montage.")


## Mauvais ordre : la photocopieuse la plus proche imprime « FORMULAIRE REFUSÉ », tout s'efface.
func _refuse(_i: int) -> void:
	var best: int = 0
	var bd: float = 1e9
	var me_p: Vector3 = L(_feet())
	for c in range(COPIERS.size()):
		var d: float = me_p.distance_to(COPIERS[c])
		if d < bd:
			bd = d
			best = c
	_snd("photocopieuse", W((COPIERS[best] as Vector3) + Vector3(0, 1.0, 0)))
	if best < _copier_sheets.size():
		var sh: Node3D = _copier_sheets[best]
		var x0: Transform3D = sh.get_meta("x0")
		sh.transform = x0
		sh.visible = true
		var out: Vector3 = x0.origin + x0.basis * Vector3(-0.42, 0, 0)
		var tw := create_tween()
		tw.tween_property(sh, "position", out, 0.8)
		tw.tween_interval(6.0)
		tw.tween_callback(func(): sh.visible = false)
	_stamps.clear()
	for mk in _stamp_marks:
		(mk as Node3D).visible = false
	_say("Brrrt-brrrt… La photocopieuse crache une feuille : « FORMULAIRE REFUSÉ. Ordre de tamponnage non conforme. Veuillez recommencer depuis le début. Merci de votre patience administrative. » Les « VU » rouges s'effacent tout seuls. (Relis la note de service, près de l'entrée.)", 9.0)


# =================================================================== la Chaîne : les tapis

func _belt_fwd(i: int) -> bool:
	var lv: Array = state["leviers"]
	var on: bool = false
	for l in range(3):
		if bool(lv[l]) and (LEVER_LINKS[l] as Array).has(i):
			on = not on
	return on


func _update_belts() -> void:
	var lines: Array = ["SYNOPTIQUE DES TAPIS", ""]
	var names := ["TAPIS 1 (départ → îlot ouest)", "TAPIS 2 (îlot ouest → îlot est)", "TAPIS 3 (îlot est → sortie)"]
	for i in range(3):
		var f: bool = _belt_fwd(i)
		lines.append("%s : %s" % [names[i], "ALLER  >>>" if f else "<<<  RETOUR"])
		if i < _lever_lamps.size():
			(_lever_lamps[i] as StandardMaterial3D).emission = Color(0.2, 1.0, 0.35) if f else Color(1.0, 0.1, 0.06)
	if _synoptic != null:
		_synoptic.text = "\n".join(lines)


func _pull(i: int) -> void:
	var lv: Array = state["leviers"]
	lv[i] = not bool(lv[i])
	if i < _lever_arms.size():
		create_tween().tween_property(_lever_arms[i], "rotation:x", 0.6 if bool(lv[i]) else -0.6, 0.3).set_trans(Tween.TRANS_BACK)
	_snd("levier", W(LEVERS[i] + Vector3(0, 1.1, 0)))
	_update_belts()
	var all_ok: bool = _belt_fwd(0) and _belt_fwd(1) and _belt_fwd(2)
	if all_ok:
		_once("tapis_ok", "Clonk ! Les trois lampes du synoptique passent au vert : TOUS LES TAPIS VONT VERS LA SORTIE. (Le stagiaire serait fier. Enfin, s'il comprenait.)", 7.0)
	else:
		var ch: Array = []
		for b in LEVER_LINKS[i]:
			ch.append("le tapis %d" % (int(b) + 1))
		_say("Clac ! Le levier %d bascule %s. Regarde le synoptique, au mur : vert = « aller », rouge = « retour »." % [i + 1, " et ".join(ch)], 5.0)


func _tick_belts(delta: float, l: Vector3) -> void:
	var step: float = BELT_V * delta
	_on_belt = -1
	for i in range(BELTS.size()):
		var b: Array = BELTS[i]
		var f: bool = _belt_fwd(i)
		var dir: Vector3 = (b[4] as Vector3) * (1.0 if f else -1.0)
		if i < _belt_mats.size():
			var m: StandardMaterial3D = _belt_mats[i]
			if dir.z != 0.0:
				m.uv1_offset.y = fposmod(m.uv1_offset.y + dir.z * step, 1.0)
			else:
				m.uv1_offset.x = fposmod(m.uv1_offset.x - dir.x * step, 1.0)
		if l.x > float(b[0]) - 0.1 and l.x < float(b[1]) + 0.1 and l.z > float(b[2]) and l.z < float(b[3]) and l.y > -14.4 and l.y < -13.3:
			_on_belt = i
			push_player(dir * step)
	if _on_belt >= 0:
		_belt_snd -= delta
		if _belt_snd <= 0.0:
			_belt_snd = 1.6
			_snd("tapis_roulant", _feet())
		if not _belt_fwd(_on_belt):
			_once("tapis_retour", "Whoooo ! Le tapis t'emporte à reculons, bien plus vite que tu ne cours. Il faut l'aiguiller : les leviers sont au pupitre, près de l'entrée.", 6.0)
	else:
		_belt_snd = 0.0


func _tick_arms(_delta: float) -> void:
	var t: float = _clock
	for a in _arms:
		var ph: float = float(a[3])
		(a[0] as Node3D).rotation.y = sin(t * 0.6 + ph) * 0.7
		(a[1] as Node3D).rotation.x = 0.35 + sin(t * 0.9 + ph) * 0.25
		(a[2] as Node3D).rotation.x = 0.7 + sin(t * 1.3 + ph) * 0.35
		var sp: CPUParticles3D = a[4]
		if sp != null:
			sp.emitting = sin(t * 2.3 + ph * 3.0) > 0.55
	for g in _gears:
		(g as Node3D).rotate_object_local(Vector3(0, 0, 1), 0.4 * get_physics_process_delta_time())


# =================================================================== la Chaufferie : jets, vannes

func _jet_active(i: int) -> bool:
	var j: Array = JETS[i]
	if bool((state["vannes"] as Array)[int(j[3])]):
		return false
	return fposmod(_clock - float(j[4]), JET_PERIOD) < JET_ON


func _tick_jets(delta: float, l: Vector3, r: String) -> void:
	_jet_cd = maxf(_jet_cd - delta, 0.0)
	for i in range(JETS.size()):
		var on: bool = _jet_active(i)
		if on != bool(_jet_was[i]):
			_jet_was[i] = on
			(_jet_fx[i] as CPUParticles3D).emitting = on
			var nz: Vector3 = Vector3(float(JETS[i][0]), -26.7, float(JETS[i][1]) + 0.5)
			if on and L(_feet()).distance_to(nz) < 16.0:
				_snd("vapeur", W(nz))
		if not on or r != "chaufferie" or _jet_cd > 0.0:
			continue
		var j: Array = JETS[i]
		var jx: float = j[0]
		if absf(l.x - jx) < 0.95 and l.z > float(j[1]) and l.z < float(j[2]) and l.y < -26.0:
			_jet_cd = 1.1
			var side: float = signf(l.x - jx)
			if side == 0.0:
				side = 1.0
			_hurt(1, W(Vector3(jx, -27.0, l.z)))
			push_player(Vector3(side * 2.4, 0, 0))
			_once("vapeur", "PSCHHHHT ! Un jet de vapeur brûlante te repousse ! Les jets soufflent en rythme : attends la fin d'une bouffée, puis fonce.", 6.0)


func _turn_valve(i: int) -> void:
	var va: Array = state["vannes"]
	if bool(va[i]):
		return
	va[i] = true
	var w: Node3D = _valve_wheels[i] if i < _valve_wheels.size() else null
	if w != null:
		var tw := create_tween()
		var b0: Basis = w.get_meta("b0")
		tw.tween_method(func(a: float): w.transform.basis = b0 * Basis(Vector3(0, 0, 1), -a), 0.0, TAU * 1.5, 1.6).set_trans(Tween.TRANS_SINE)
	_snd("vanne", W((VALVES[i][0] as Vector3) + Vector3(0, 1.3, 0)))
	_update_gauge(true)
	var n: int = 0
	for v in va:
		if bool(v):
			n += 1
	for j in range(JETS.size()):
		if int(JETS[j][3]) == i and j < _jet_fx.size():
			(_jet_fx[j] as CPUParticles3D).emitting = false
			_jet_was[j] = false
	if n < 3:
		_say(["Grrrrinc… Tu tournes le gros volant rouge. Les tuyaux soupirent, les jets de ce couloir se taisent. Le manomètre, près de la porte, descend d'un cran : « ÉLEVÉE ».",
			"Grrrrinc… Deuxième vanne. Les jets de ce couloir s'éteignent ; le manomètre affiche « MOYENNE ». Encore une !"][n - 1], 6.0)
		return
	_say("Grrrrinc… PFFFFSSSHHH ! Toute la chaufferie pousse un long soupir de soulagement. Le manomètre tombe sur « CHAUSSONS » (c'est le minimum).", 6.0)
	await get_tree().create_timer(1.6).timeout
	open_gate("chaufferie", "La porte de sécurité, au sud, s'enfonce dans le sol en sifflant. L'escalier descend vers l'Entrepôt Automatique.")


func _update_gauge(animate: bool) -> void:
	var n: int = 0
	for v in state["vannes"]:
		if bool(v):
			n += 1
	var a: float = [2.1, 1.0, -0.4, -2.0][n]
	if _gauge_needle != null:
		if animate:
			create_tween().tween_property(_gauge_needle, "rotation:z", -a, 1.4).set_trans(Tween.TRANS_ELASTIC)
		else:
			_gauge_needle.rotation.z = -a
	if _gauge_label != null:
		_gauge_label.text = "PRESSION : " + ["DANGER !", "ÉLEVÉE", "MOYENNE", "CHAUSSONS"][n]


# =================================================================== l'Entrepôt : caisses, badge, chariots

func _crate_cells() -> Array:
	var c: Array = state["caisses"]
	var out: Array = []
	if c.size() == CRATES0.size():
		for e in c:
			if e is Array and (e as Array).size() == 2:
				out.append(Vector2i(int(e[0]), int(e[1])))
			elif e is Vector2i:
				out.append(e)
	if out.size() != CRATES0.size():
		out = CRATES0.duplicate()
	return out


func _cell_free(cell: Vector2i, except: int) -> bool:
	if cell.x < 0 or cell.y < 0 or cell.x >= GNI or cell.y >= GNJ:
		return false
	if OBST.has(cell):
		return false
	var cells: Array = _crate_cells()
	for k in range(cells.size()):
		if k != except and cells[k] == cell:
			return false
	return true


func _push_crate(i: int) -> void:
	if _crate_busy or i >= _crates.size():
		return
	var cells: Array = _crate_cells()
	var c: Vector2i = cells[i]
	var cc: Vector3 = _cell_center(c)
	var l: Vector3 = L(_feet())
	var d := Vector2(cc.x - l.x, cc.z - l.z)
	var step := Vector2i(int(signf(d.x)), 0) if absf(d.x) >= absf(d.y) else Vector2i(0, int(signf(d.y)))
	if step == Vector2i.ZERO:
		return
	var to: Vector2i = c + step
	if not _cell_free(to, i):
		_snd("pierre_glisse", W(cc + Vector3(0, 0.5, 0)))
		_say("Hnnnngh… La caisse ne bouge pas : quelque chose la bloque de l'autre côté (ou c'est le bord de la zone de stockage).", 4.0)
		return
	cells[i] = to
	var saved: Array = []
	for e in cells:
		saved.append([(e as Vector2i).x, (e as Vector2i).y])
	state["caisses"] = saved
	_crate_busy = true
	var target: Vector3 = W(_cell_center(to))
	var tw := create_tween()
	tw.tween_property(_crates[i], "global_position", target, 0.55).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func(): _crate_busy = false)
	(_crate_ia[i] as Dictionary)["pos"] = target
	_snd("pierre_glisse", target + Vector3(0, 0.5, 0))
	if to.x == 0 and QUAI_J.has(to.y):
		_once("caisse_quai", "La caisse vient se caler contre le quai de chargement : une belle marche ! Saute dessus, puis sur le quai… puis sur la mezzanine.", 7.0)


func _reset_crates() -> void:
	state["caisses"] = []
	_snd("alarme_usine", W(RESET_BTN + Vector3(0, 1.2, 0)))
	_say("CLONK ! « RANGEMENT AUTOMATIQUE EN COURS. » Des pinces descendent du plafond et remettent chaque caisse à sa place, très poliment.", 5.0)
	var cells: Array = _crate_cells()
	for c in range(_crates.size()):
		var at: Vector3 = W(_cell_center(cells[c]))
		create_tween().tween_property(_crates[c], "global_position", at, 1.2).set_trans(Tween.TRANS_SINE)
		if c < _crate_ia.size():
			(_crate_ia[c] as Dictionary)["pos"] = at


func _take_badge() -> void:
	if bool(state["badge"]):
		return
	state["badge"] = true
	if _known("badge_usine") and _inv().count("badge_usine") <= 0:
		if _inv().add("badge_usine", 1) <= 0:
			_inv().spawn_pickup(key + "_badge", "badge_usine", 1, _feet() + Vector3(0, 0.3, 0))
	if _badge_node != null:
		_badge_node.visible = false
	_snd("robot_bip", W(BADGE_AT + Vector3(0, 1.0, 0)))
	if main.has_method("jingle"):
		main.jingle("decouverte")
	_say("Le BADGE DE L'USINE GRISE ! Une photo de robot qui sourit, et la mention : « ACCÈS TOUS ÉTAGES — même le -5 ». Avec ça, la porte du bas devrait s'ouvrir.", 7.0)


func _badge_door() -> void:
	var has: bool = bool(state["badge"]) or (_known("badge_usine") and _inv().count("badge_usine") > 0)
	if not has:
		_snd("robot_bip", W(Vector3(14.5, -40.6, 271.9)))
		_say("BIIIP. Le lecteur clignote en rouge : « BADGE NON DÉTECTÉ. Avez-vous essayé d'avoir un badge ? » (Là-haut, sur la mezzanine du fond, quelque chose brille…)", 7.0)
		return
	if _reader_led != null:
		_reader_led.emission = Color(0.2, 1.0, 0.35)
	_snd("robot_bip", W(Vector3(14.5, -40.6, 271.9)))
	_snd("porte_usine", W(Vector3(12, -40, 272.4)))
	open_gate("entrepot", "Bip-bip ! Le lecteur passe au vert : « BIENVENUE, ROBOT N° … ERREUR … BIENVENUE QUAND MÊME. » La porte s'enfonce dans le sol. En bas, quelque chose de très gros respire comme un moteur.")


func _tick_forks(delta: float, p: Vector3) -> void:
	_fork_cd = maxf(_fork_cd - delta, 0.0)
	for f in _forks:
		var b: AnimatableBody3D = f[0]
		var a: Vector3 = f[1]
		var z: Vector3 = f[2]
		var ln: float = a.distance_to(z)
		var v: float = 2.6
		var travel: float = ln / v
		var cyc: float = 2.0 * (travel + 1.5)
		var u: float = fposmod(_clock + float(f[3]), cyc)
		var s: float = 0.0
		var going: bool = true
		if u < travel:
			s = u / travel
		elif u < travel + 1.5:
			s = 1.0
			going = false
		elif u < 2.0 * travel + 1.5:
			s = 1.0 - (u - travel - 1.5) / travel
			going = false
		var pos: Vector3 = a.lerp(z, s)
		var dir: Vector3 = (z - a).normalized() if going else (a - z).normalized()
		b.global_transform = Transform3D(Basis(Vector3.UP, atan2(dir.x, dir.z)), pos)
		(f[4] as Node3D).rotate_y(delta * 6.0)
		if _fork_cd > 0.0:
			continue
		var rel: Vector3 = b.global_transform.basis.inverse() * (p - pos)
		if absf(rel.x) < 1.15 and rel.z > -1.65 and rel.z < 2.2 and rel.y < 2.2 and rel.y > -0.6:
			_fork_cd = 1.4
			_hurt(1, pos + Vector3.UP)
			var away: Vector3 = Vector3(p.x - pos.x, 0, p.z - pos.z)
			away = away.normalized() if away.length() > 0.05 else dir
			push_player(away * 1.8)
			_snd("robot_bip", pos + Vector3.UP * 1.5)
			_once("chariot", "BIP BIP ! Un chariot élévateur robot te bouscule : « PRIORITÉ AUX CHARIOTS. MERCI DE VOTRE COMPRÉHENSION. » Regarde bien avant de traverser les allées.", 6.0)


# =================================================================== la Fosse : la Grande Pelleteuse

func _optimus(text: String, seconds: float = 7.0) -> void:
	_talk_t = minf(seconds * 0.6, 5.0)
	_say("OPTIMUS-LISSE : " + text, seconds)


func _boss_intro() -> void:
	_phase = 0
	_taunt_t = 14.0
	_beacons_on(true)
	_snd("alarme_usine", W(Vector3(12, -50, 320)))
	_optimus("« BONJOUR, VISITEUR NON AUTORISÉ. VOTRE PRÉSENCE N'EST PAS OPTIMALE. LANCEMENT DU PROTOCOLE : DÉMOLITION COURTOISE. » Le sol tremble : la GRANDE PELLETEUSE se déplie, godet levé, chenilles grinçantes !", 9.0)
	_start_boss(_k("grande_pelleteuse"), BOSS_AT, "la Grande Pelleteuse", Callable(self, "_boss_dead"))
	_snd("pelleteuse_cri", W(BOSS_AT + Vector3(0, 3, 0)))


## Les phases : celles de la Grande Pelleteuse (monstre_v75 : _phase75, une durite éclate, elle
## l'annonce elle-même) ; à défaut, les tiers de sa vie. OPTIMUS-LISSE parle juste après.
func _tick_boss_fight(delta: float) -> void:
	if not fight or _boss == null or not is_instance_valid(_boss):
		return
	var want: int = _phase
	var bp: Variant = _boss.get("_phase75")
	if bp != null:
		want = int(bp)
	else:
		var pv: float = maxf(float(_boss.spec.get("pv", 1)), 1.0)
		var ratio: float = float(_boss.hp) / pv
		want = 2 if ratio <= 1.0 / 3.0 else (1 if ratio <= 2.0 / 3.0 else 0)
	if want > _phase:
		_phase = want
		_taunt_t = 16.0
		_phase_line(_phase)
	_taunt_t -= delta
	if _taunt_t <= 0.0:
		_taunt_t = 15.0
		_optimus(OPTIMUS_TAUNTS[randi() % OPTIMUS_TAUNTS.size()], 6.0)
	# les déménageurs appelés en renfort, s'ils tombent d'une plate-forme
	_strays_t -= delta
	if _strays_t <= 0.0:
		_strays_t = 1.0
		for m in _strays():
			if L((m as Node3D).global_position).y < -60.0:
				(m as Node3D).global_position = W(BOSS_AT + Vector3(0, 0.4, -8.0))


func _phase_line(ph: int) -> void:
	await get_tree().create_timer(3.8).timeout
	if not fight or _phase != ph:
		return
	if ph == 1:
		_optimus("« ALERTE : DURITE ENDOMMAGÉE. CECI N'ÉTAIT PAS DANS LE TABLEUR. » L'écran devient rouge vif : OPTIMUS-LISSE passe en mode « TRÈS FÂCHÉ (POLIMENT) ».", 7.0)
	else:
		_optimus("« ERREUR 404 : VICTOIRE INTROUVABLE. ACTIVATION DU MODE TURBO-BÉTON. MERCI DE VOTRE COMPRÉHENSION. » Des étincelles partout : elle fatigue ! Vise les durites quand le godet est planté !", 8.0)


## Les robots appelés en renfort par la Grande Pelleteuse (monstre_v75 les fait venir lui-même) :
## tous les monstres vivants de la Fosse qui ne sont pas d'une liste de salle, sauf la pelleteuse.
func _strays() -> Array:
	var out: Array = []
	var mo: Node = main.get("monstres_v36") if main != null else null
	if mo == null or not rooms.has("fosse"):
		return out
	var a: Vector3 = rooms["fosse"]["a"]
	var b: Vector3 = rooms["fosse"]["b"]
	for m in mo.monsters:
		if not is_instance_valid(m) or m == _boss or str(m.get("state")) == "mort":
			continue
		var l: Vector3 = L((m as Node3D).global_position)
		if l.x > a.x - 2.0 and l.x < b.x + 2.0 and l.z > a.z - 2.0 and l.z < b.z + 2.0 and l.y > a.y - 8.0 and l.y < b.y:
			out.append(m)
	return out


func _kill_strays() -> void:
	for m in _strays():
		m.take_hit(999, (m as Node3D).global_position + Vector3.UP)


func _free_strays() -> void:
	var mo: Node = main.get("monstres_v36") if main != null else null
	for m in _strays():
		if mo != null:
			mo.monsters.erase(m)
		(m as Node).queue_free()


func _boss_dead() -> void:
	state["boss"] = true
	_kill_strays()
	_beacons_on(false)
	_talk_t = 0.0
	_snd("durite", W(BOSS_AT + Vector3(0, 2, 0)))
	_say("OPTIMUS-LISSE : « ÉCHEC… DE… L'OPTI… MI… SA… TION… RETOUR… EN… MODE… VEILLE… » La Grande Pelleteuse s'affaisse dans un long soupir hydraulique (« pfffshhhhh »). Sur l'écran, le visage rouge devient un petit sablier… puis un écran tout bleu.", 10.0)
	_screen_state()
	await get_tree().create_timer(2.5).timeout
	state["fini"] = true
	_final_reward()
	_lift_ready(true)
	_snd("monte_charge", W(LIFT + Vector3(0, 2, 0)))


## La récompense : les Plans du Lisse-Center (s'ils ne sont pas déjà dans le sac), 200 pièces, un
## titre, un cœur de plus.
func _final_reward() -> void:
	var inv: Node = _inv()
	if _known("plans_lisse") and inv.count("plans_lisse") <= 0:
		if inv.add("plans_lisse", 1) <= 0:
			inv.spawn_pickup(key + "_plans", "plans_lisse", 1, W(BOSS_AT + Vector3(0, 0.5, -2.0)))
	var got_p: int = inv.add("piece", 200)
	if got_p < 200:
		inv.spawn_pickup(key + "_bourse", "piece", 200 - got_p, W(BOSS_AT + Vector3(0, 0.5, -2.5)))
	var title: String = "Démolisseur de démolisseuse"
	var j: Node = main.get("journal_v56")
	if j != null:
		if not (j.titres as Array).has(title):
			j.titres.append(title)
		j.bonus["coeur"] = int(j.bonus.get("coeur", 0)) + 1
		j.apply_bonuses()
	var hero: Node = main.get("hero_v28")
	if hero != null:
		hero.set_health(int(hero.HP_MAX))
	if main.has_method("jingle"):
		main.jingle("decouverte")
	main._show_message_v28("Les Plans du Lisse-Center ! 200 pièces, un cœur de plus, et un titre : « %s ». Dans le coin de la fosse, le monte-charge s'allume en vert : il remonte jusqu'à la surface. Mamie Barricade va adorer ces plans… pour en faire des confettis." % title)


func _take_lift() -> void:
	_snd("monte_charge", W(LIFT + Vector3(0, 1.5, 0)))
	leave("Le monte-charge grince, cliquette et monte… monte… (avec une petite musique d'ascenseur, très optimisée)… puis s'ouvre dans la cour de l'Usine Grise, au grand jour. Les Plans du Lisse-Center sont dans ton sac. Port-Boucan va faire la fête !")


func _lift_ready(on: bool) -> void:
	if _lift_lamp != null:
		_lift_lamp.emission = Color(0.2, 1.0, 0.35) if on else Color(1.0, 0.1, 0.06)


func _screen_state() -> void:
	var dead: bool = bool(state["boss"])
	if _screen_face != null:
		_screen_face.visible = not dead
	if _screen_bsod != null:
		_screen_bsod.visible = dead
	if _screen_light != null:
		_screen_light.light_color = Color(0.2, 0.4, 1.0) if dead else Color(1.0, 0.15, 0.1)


func _beacons_on(on: bool) -> void:
	for b in _beacons:
		(b[1] as OmniLight3D).light_energy = 0.0
		(b[1] as OmniLight3D).visible = on


func _tick_screen(delta: float) -> void:
	if _screen_face == null or not _screen_face.is_visible_in_tree():
		return
	_talk_t = maxf(_talk_t - delta, 0.0)
	var t: float = _clock
	if _screen_mouth != null:
		_screen_mouth.scale = Vector3(1.0, 1.0 + (absf(sin(t * 14.0)) * 5.0 if _talk_t > 0.0 else 0.0), 1.0)
	var blink: bool = fposmod(t, 4.3) < 0.12
	for e in _screen_eyes:
		(e as Node3D).scale = Vector3(1.0, 0.1 if blink else 1.0, 1.0)
	if fight:
		for b in _beacons:
			(b[0] as Node3D).rotate_y(delta * 7.0)
			(b[1] as OmniLight3D).light_energy = 1.4 + sin(t * 9.0) * 1.0
	if _screen_light != null:
		_screen_light.light_energy = (2.2 if fight else 1.4) + (sin(t * 11.0) * 0.4 if _talk_t > 0.0 else 0.0)


# =================================================================== chaque image

func _tick(delta: float, p: Vector3, r: String) -> void:
	var l: Vector3 = L(p)
	match r:
		"chaine":
			_tick_belts(delta, l)
			_tick_arms(delta)
			if l.y < -15.2 and _fall_cd <= 0.0:
				_fall_cd = 1.5
				_fall_back("Patatras ! Tu tombes dans le bac des pièces détachées. Un robot-trieur te ramasse, te tamponne « DIVERS » et te repose poliment au début de la chaîne.", 1)
		"esc1", "esc2":
			_tick_arms(delta)
		"chaufferie", "esc3":
			_tick_jets(delta, l, r)
			for li in _boiler_lights:
				(li as OmniLight3D).light_energy = 1.6 + sin(_clock * 7.3 + (li as Node3D).global_position.x) * 0.25
		"entrepot", "esc4":
			_tick_forks(delta, p)
			if _badge_node != null and _badge_node.visible:
				_badge_node.rotate_y(delta * 1.2)
		"fosse":
			if not bool(state["boss"]) and not fight and l.z > 310.0 and l.y < -50.0:
				_boss_intro()
			_tick_boss_fight(delta)
	if r in ["fosse", "esc4"]:
		_tick_screen(delta)
	if not _shortcut_ia.is_empty():
		_shortcut_ia["text"] = "E : prendre l'ascenseur de service (étage %d)" % clampi(deepest(), 2, 5)


## La lueur de chaque étage (donjon_v35 pose la pénombre en entrant).
func _mood(r: String) -> void:
	if main == null or main.get("donjon_v35") == null or not bool(main.donjon_v35.get("inside")):
		return
	for c in main.get_children():
		if c is WorldEnvironment:
			var env: Environment = (c as WorldEnvironment).environment
			var f: int = int(FLOOR.get(r, 1))
			match f:
				1:
					env.ambient_light_color = Color(0.6, 0.65, 0.72)
					env.ambient_light_energy = 1.25
					env.fog_light_color = Color(0.04, 0.045, 0.05)
					env.fog_density = 0.008
					env.tonemap_exposure = 1.25
				2:
					env.ambient_light_color = Color(0.62, 0.6, 0.56)
					env.ambient_light_energy = 1.3
					env.fog_light_color = Color(0.05, 0.045, 0.04)
					env.fog_density = 0.011
					env.tonemap_exposure = 1.3
				3:
					env.ambient_light_color = Color(0.7, 0.52, 0.4)
					env.ambient_light_energy = 1.3
					env.fog_light_color = Color(0.09, 0.06, 0.04)
					env.fog_density = 0.02
					env.tonemap_exposure = 1.3
				4:
					env.ambient_light_color = Color(0.58, 0.6, 0.63)
					env.ambient_light_energy = 1.25
					env.fog_light_color = Color(0.04, 0.045, 0.05)
					env.fog_density = 0.01
					env.tonemap_exposure = 1.3
				_:
					env.ambient_light_color = Color(0.66, 0.52, 0.5)
					env.ambient_light_energy = 1.3
					env.fog_light_color = Color(0.06, 0.03, 0.03)
					env.fog_density = 0.012
					env.tonemap_exposure = 1.3
			return


func _enter_room(_old: String, r: String) -> void:
	_mood(r)
	var f: int = int(FLOOR.get(r, 0))
	if not r.begins_with("esc") and f > deepest():
		state["profond"] = f
		if f >= 2:
			_say("Étage %d : %s ! (L'ascenseur de service de l'accueil le note : il pourra t'y descendre directement.)" % [f, FLOOR_NAMES[f]], 5.0)
			return
	match r:
		"bureaux":
			_once("bureaux", "Les Bureaux. Un open-space gris à perte de vue : des bureaux en rangs, des plantes en plastique, des néons qui grésillent… et des drones-huissiers qui lisent des avis d'expulsion à voix haute. Au fond, un tourniquet. Près de l'entrée, une note de service.", 9.0)
		"esc1", "esc2", "esc3", "esc4":
			_once(r, ["Un escalier de service, des marches de tôle qui résonnent. Sur le mur : « Marche 1 sur 64. Veuillez compter. »", "Encore des marches. Ça sent l'huile de machine et la vapeur.",
				"Des marches tièdes : en bas, ça chauffe… non, ça a FROID. Non, ça range. Bref, on descend.", "Les marches tremblent un peu. Tout en bas, un moteur énorme fait « vroum ». Poliment."][int(r.substr(3)) - 1], 6.0)
		"chaine":
			_once("chaine", "La Chaîne de Montage ! Des bras robots soudent des robots déménageurs, une fosse pleine de boulons, et trois tapis roulants qui filent vers la sortie… ou pas. Le pupitre d'aiguillage est juste là.", 9.0)
		"chaufferie":
			_once("chaufferie", "La Chaufferie. Il fait chaud, ça siffle, ça gronde : des jets de vapeur soufflent en rythme en travers du couloir. Le manomètre de la porte, au fond, est dans le rouge : il faut trouver les trois vannes.", 9.0)
		"entrepot":
			_once("entrepot", "L'Entrepôt Automatique. Des rayonnages jusqu'au plafond, des chariots élévateurs robots qui klaxonnent, et une zone de caisses à pousser à l'ouest. Tout au fond, sur une mezzanine, quelque chose brille.", 9.0)
		"fosse":
			if not bool(state["boss"]):
				_once("fosse", "La Fosse du Président. Une arène de béton sous un bureau vitré tout doré. Sur le mur, un écran géant s'allume : deux yeux rouges, une bouche en barre… OPTIMUS-LISSE te regarde.", 8.0)


func _on_enter(first: bool) -> void:
	_mood("accueil")
	if first:
		_say("Tu passes le portail de l'Usine Grise. Dedans, c'est propre, gris et silencieux, comme une salle d'attente géante. Un robot d'accueil te sourit avec un écran. Quelque part sous tes pieds, des machines ronronnent.", 9.0)
	elif deepest() >= 2:
		_say("L'Usine Grise. L'ascenseur de service t'attend à gauche : il descend directement à l'étage %d." % deepest(), 6.0)
	else:
		_say("L'Usine Grise. L'Accueillotron te fait un signe de la pince.", 3.0)


func respawn() -> void:
	super.respawn()
	_mood(_room_of(_feet()))


## La visite en images : place la caméra pour un plan du donjon (m._in71, m._cam56). Renvoie false
## si le plan n'est pas d'ici. Plans : u_accueil, u_bureaux, u_tampons, u_chaine, u_chaufferie,
## u_entrepot, u_badge, u_fosse.
const SHOTS := {
	"u_accueil": ["accueil", Vector3(3.5, 1.7, 12.6), Vector3(-3.0, 1.2, 4.0), "L'accueil de l'Usine Grise"],
	"u_bureaux": ["bureaux", Vector3(-1.0, 1.75, 15.2), Vector3(4.0, 0.9, 34.0), "Étage 1 : les Bureaux"],
	"u_tampons": ["bureaux", Vector3(12.0, 1.6, 34.2), Vector3(10.5, 0.8, 32.0), "Le formulaire bleu"],
	"u_chaine": ["chaine", Vector3(0.0, -11.5, 79.5), Vector3(0.0, -14.5, 104.0), "Étage 2 : la Chaîne de Montage"],
	"u_chaufferie": ["chaufferie", Vector3(20.0, -26.3, 168.5), Vector3(-6.0, -27.0, 169.0), "Étage 3 : la Chaufferie"],
	"u_entrepot": ["entrepot", Vector3(12.0, -40.2, 226.0), Vector3(4.0, -41.0, 256.0), "Étage 4 : l'Entrepôt Automatique"],
	"u_badge": ["entrepot", Vector3(-4.0, -38.5, 250.0), Vector3(-20.0, -40.0, 264.0), "Le quai et la mezzanine du badge"],
	"u_fosse": ["fosse", Vector3(12.0, -54.3, 302.0), Vector3(12.0, -45.0, 334.0), "Étage 5 : la Fosse du Président"],
}


func tour_shot(m: Node, shot: String) -> bool:
	if not SHOTS.has(shot):
		return false
	ensure_built()
	var s: Array = SHOTS[shot]
	var r: String = s[0]
	if m.has_method("_in71"):
		await m._in71(self, s[1])
	room = r
	_visibility(r)
	_mood(r)
	if m.has_method("_cam56"):
		await m._cam56(W(s[1]), W(s[2]), str(s[3]), 70.0, 10)
	return true


func _fall_text(_r: String) -> String:
	return "Tu tombes… Un robot-trieur te ramasse, te tamponne « RETOUR À L'ENVOYEUR » et te repose au début de la salle."


func _faint_text() -> String:
	return "Un petit robot-nettoyeur te passe la serpillière sur le front : « Veuillez ne pas vous évanouir dans les zones de circulation. Merci. »"


func _on_reset() -> void:
	_stamps.clear()
	if built:
		var stamped: bool = gate_open("bureaux")
		for mk in _stamp_marks:
			(mk as Node3D).visible = stamped
	_phase = 0
	_talk_t = 0.0
	_beacons_on(false)
	if built:
		_free_strays()
	_crate_busy = false
	_on_belt = -1
	for j in range(_jet_fx.size()):
		(_jet_fx[j] as CPUParticles3D).emitting = false
		_jet_was[j] = false
