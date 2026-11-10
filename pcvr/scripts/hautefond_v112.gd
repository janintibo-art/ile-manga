extends Node3D
## V127 : on marche jusque dans l'eau peu profonde (le rivage n'est plus un mur : on y entre et on en sort à la nage).
const RIVE_V127: float = -1.3
## V112 : l'Île de Hautefond, la cité-colonne — le chef d'orchestre. Il construit l'île
## (ile_hautefond_v112), la ville en terrasses autour de la Grande Colonne (hautefond_ville_v112, ses
## grands lieux hautefond_lieux_v112, la Colonne et son ascenseur hautefond_colonne_v112), ce qu'il y a
## dehors (hautefond_dehors_v112 : le port, le phare, le moulin, les vergers, la plage, les falaises,
## les arches, la cascade) et la végétation (hautefond_flore_v112) ; il tient les feux, les fumées,
## les panaches de vapeur, la lueur des fenêtres et des globes à la nuit, les ailes du moulin, les
## engrenages qui tournent, l'Albatros qui se balance à son mât, le marteau-pilon de la forge, les
## dirigeables qui croisent au-dessus de la ville ; il fait vivre les habitants selon l'heure (et les
## fait monter au Belvédère par la cabine) et les passants.
## V113 : la CITÉ DES NUÉES, l'île flottante, deux cents mètres au-dessus de la ville (ile_nuees_v113 :
## le plateau, le dessous, les sustentateurs, les nuages, la cascade ; nuees_ville_v113 : la ville,
## la Ligne des Nuées et sa capsule qui part du Belvédère ; nuees_flore_v113 : les jardins) ; ses
## quatorze habitants (pnj/nuees_habitants_v113, au costume de Néopolis : pnj_neo_v95) et ses passants.
## V114 : les STRATES, la ville sous la ville, une centaine de mètres sous la Place (strates_roche_v114 :
## les cavernes de grès en couches ; strates_ville_v114 : la Colonne Renversée, le Soleil de Laiton, la
## Gare, la Place des Rouages, la Grande Forge, La Marmite, l'Atelier des Lumières, les Galeries, les
## Mines de Cristaux, les Jardins des Champignons, le Petit Train ; fronde_v114 : la FRONDE, le quartier
## libre, au-delà du Pont des Frondeurs ; strates_ligne_v114 : le pavillon de la Ligne des Strates, sur
## la Place, et sa cabine) ; neuf habitants des Strates (pnj/strates_habitants_v114, comme ceux d'en
## haut), neuf Frondeurs (pnj/fronde_habitants_v114, au costume de Port-Boucan : pnj_boucan_v75) et
## leurs passants. Sous terre (y < -40), le jeu passe en lumière d'intérieur (donjon_v35).
## V115 : le DÔME D'AZUR, au fond de la mer, à cent quarante mètres sous la surface, au pied des falaises
## du sud (fosse_azur_v115 : la Fosse ; dome_azur_v115 : le Grand Dôme, le Dôme des Serres, le Dôme de
## l'Institut, leurs galeries de verre, la bouée-phare de la Cheminée d'Air à la surface ; dome_ligne_v115 :
## la Ligne du Dôme d'Azur, de la cage de laiton de la Gare des Strates à la bulle du Funiculaire ;
## dome_vie_v115 : les poissons, les méduses, les raies et la Grande Chanteuse, dehors) ; les habitants
## du Dôme (pnj/dome_habitants_v115, au costume des Nuées : pnj_neo_v95) et leurs passants.

const IleScript = preload("res://scripts/ile_hautefond_v112.gd")
const CityScript = preload("res://scripts/hautefond_ville_v112.gd")
const DehorsScript = preload("res://scripts/hautefond_dehors_v112.gd")
const Mats = preload("res://scripts/hautefond_mats_v112.gd")
const Mats71 = preload("res://scripts/montjoie_mats_v71.gd")
const FLORE := "res://scripts/hautefond_flore_v112.gd"
const HABITANTS := "res://scripts/pnj/hautefond_habitants_v112.gd"
const PNJ := "res://scripts/pnj/pnj_montjoie_v71.gd"
const Gens = preload("res://scripts/pnj/maisons_habitants_v81.gd")
const Figurant = preload("res://scripts/pnj/figurant_v81.gd")
## V113 : la Cité des Nuées
const NueesIle = preload("res://scripts/ile_nuees_v113.gd")
const NueesVille = preload("res://scripts/nuees_ville_v113.gd")
const MatsN = preload("res://scripts/nuees_mats_v113.gd")
const FLORE_N := "res://scripts/nuees_flore_v113.gd"
const HABITANTS_N := "res://scripts/pnj/nuees_habitants_v113.gd"
const PNJ_N := "res://scripts/pnj/pnj_neo_v95.gd"
const PASSANTS_N := "res://scripts/pnj/nuees_passants_v113.gd"
## V114 : les Strates et la Fronde
const StratesRoche = preload("res://scripts/strates_roche_v114.gd")
const StratesVille = preload("res://scripts/strates_ville_v114.gd")
const MatsS = preload("res://scripts/strates_mats_v114.gd")
const HABITANTS_S := "res://scripts/pnj/strates_habitants_v114.gd"
const HABITANTS_F := "res://scripts/pnj/fronde_habitants_v114.gd"
const PNJ_F := "res://scripts/pnj/pnj_boucan_v75.gd"
const PASSANTS_S := "res://scripts/pnj/strates_passants_v114.gd"
const PASSANTS_F := "res://scripts/pnj/fronde_passants_v114.gd"
## V115 : le Dôme d'Azur
const DomeFosse = preload("res://scripts/fosse_azur_v115.gd")
const DomeVille = preload("res://scripts/dome_azur_v115.gd")
const MatsD = preload("res://scripts/dome_mats_v115.gd")
const HABITANTS_D := "res://scripts/pnj/dome_habitants_v115.gd"
const PASSANTS_D := "res://scripts/pnj/dome_passants_v115.gd"
## Les prénoms des passants du Dôme
const PRENOMS_D := {"h": ["Marin", "Loïc", "Erwan", "Gabin", "Corentin", "Yann", "Nolan", "Téo", "Malo", "Bastien", "Ewen", "Titouan"],
	"f": ["Océane", "Marine", "Nacre", "Ondine", "Perle", "Coralie", "Morgane", "Azilis", "Maïwenn", "Léna", "Nolwenn", "Rozenn"]}
## Les prénoms des passants des Nuées
const PRENOMS_N := {"h": ["Aurèle", "Cyrus", "Élian", "Orion", "Sacha", "Noé", "Thélo", "Zéphyr", "Ilan", "Maël", "Nils", "Adrien"],
	"f": ["Alizée", "Célia", "Nuée", "Brume", "Iris", "Maëlys", "Azalée", "Solène", "Line", "Elsa", "Livia", "Aube"]}

## Les passants : [style, rôle, phrases] (leurs lieux : les bancs des promenades, des coins de rue)
const PASSANTS := [
	["montjoie", "homme", ["Trois quarts d'heure de queue pour la cabine, et encore autant pour la capsule des Nuées ! Bon, la vue vaut le coup.", "Par la Colonne, j'ai oublié mon parapluie au cinquième. Il n'y a pas de cinquième. Je ne comprends rien."]],
	["montjoie", "femme", ["Le chocolat de Firmin a sifflé : il est seize heures. Pas besoin de montre, ici.", "Le marché est plein, aujourd'hui. Rosalie a dû annoncer un nouveau potin."]],
	["montjoie", "vieux", ["De mon temps, on montait à la Colonne par l'escalier. Mille marches. Et on disait merci.", "Huile tes rouages, jeune homme. Et tes genoux aussi, tant que tu y es."]],
	["montjoie", "vieille", ["J'ai connu la Colonne quand la cabine était en bois. Elle grinçait comme mon mari. Je les regrette tous les deux.", "Regarde l'Albatros, là-haut ! Cette Héloïse, elle va finir par décrocher la lune."]],
	["montjoie", "enfant", ["Tu as vu les engrenages de l'horloger ? Il y en a un qui tourne à l'envers, exprès !", "Quand je serai grand, je serai liftier. Ou dirigeable. Je n'ai pas encore choisi."]],
	["montjoie", "homme", ["La ligne des Nuées a rouvert ! Mon beau-frère l'annonçait depuis trois ans. Il est insupportable, maintenant.", "Attention, ça souffle ! Le tuyau de la Forge vient de lâcher sa vapeur."]],
	["montjoie", "femme", ["Au Belvédère, on voit l'île flottante juste au-dessus. Si près ! On a envie de tendre la main.", "Mon chapeau s'est envolé au Belvédère. Il doit être à la Cité des Nuées, maintenant. Veinard."]],
	["montjoie", "enfant", ["J'ai fait un vœu dans la fontaine de Dame Ysolde. Je ne te dis pas lequel. Ça a un rapport avec des boulons.", "Barnabé a fermé les yeux pendant toute la montée ! Moi, je les avais grands ouverts !"]],
	["montjoie", "vieux", ["Le vent tourne à l'ouest : le moulin d'Augustin va se mettre à chanter.", "Tu entends cette musique qui monte de la cage du bas ? Hm. De mon temps, les travaux faisaient moins de bruit."]],
	["montjoie", "vieille", ["J'ai acheté des dattes chez Rosalie, et elle m'a raconté la vie de tout le quartier. Gratuitement.", "Le Bourgmestre fait un discours sur la Place. Vite, prenons la rue de derrière."]],
	["montjoie", "homme", ["Là-haut, au-dessus des nuages, il fait toujours beau, paraît-il. Ici, il fait beau aussi. Mais en dessous.", "Ma montre avance de trois secondes. Si Gaspard le sait, je suis perdu."]],
	["montjoie", "femme", ["Un dirigeable, un bateau, une cabine… À Hautefond, on ne marche jamais. Enfin, si : on fait la queue.", "Ces bijoux de boulons, au marché, j'en voulais un. Mais ma voisine me regarde. Je reviendrai demain."]],
	["montjoie", "enfant", ["Il y a une baleine qui passe au-dessus du Dôme d'Azur, au fond de la mer ! Mon oncle l'a vue !", "Tout le monde descend ! … Non, je rigole. C'est ce que dit Barnabé quand il a peur."]],
	["montjoie", "homme", ["J'ai monté trois fois au Belvédère, aujourd'hui. Je n'ai rien vu : il y avait un nuage. Le même, trois fois.", "Le pavé est glissant près du lavoir. La vapeur, toujours la vapeur."]],
	["montjoie", "vieille", ["Ici, il y a plus d'horloges que d'habitants. Et elles ne sont jamais d'accord, sauf chez Gaspard.", "Une limonade à la vapeur, chez Firmin. Ça pique le nez, ça réchauffe le cœur."]],
	["montjoie", "femme", ["Il fait frais, sur la Haute-Ville. Le vent monte de la mer et redescend par les escaliers.", "Je travaille au lavoir. Avec toute cette vapeur, le linge sèche avant d'être lavé."]],
	["montjoie", "vieux", ["J'ai été liftier pendant trente ans. Je n'ai jamais eu le vertige. Seulement le mal de mer. Dans une tour.", "Ça monte, ça descend… Moi, je reste assis. C'est ma façon de voyager."]],
	["montjoie", "enfant", ["Maman dit que si je suis sage, on ira voir les poissons qui brillent au Dôme d'Azur. La ligne a rouvert : je suis sage depuis trois jours !", "J'ai trouvé un engrenage par terre ! Je vais l'échanger à Pimprenelle contre deux boulons."]],
	["montjoie", "homme", ["Je suis venu par le bateau de ligne pour voir la Colonne. Elle est plus haute que sur les cartes postales.", "Les cabines sont dorées, les rampes sont dorées… Même le guichet brille. Je n'ose pas toucher."]],
	["montjoie", "femme", ["Les pommes des Vergers sont arrivées au marché. Le Père Bastien leur a parlé toute la semaine : elles sont aux anges.", "Avec ce soleil, la Colonne brille tellement qu'il faut des lunettes pour la regarder."]],
	["montjoie", "vieux", ["Le soir, quand les réverbères s'allument, toute la ville ronronne. C'est la vapeur dans les tuyaux. Ou mon ventre.", "Par tous les pistons, ce que ça grimpe, ces rues ! Hautefond, c'est une ville pour les mollets."]],
	["montjoie", "vieille", ["On dit qu'il y a de la musique dans les Strates, sous nos pieds. Moi, j'entends surtout mes genoux.", "Dame Ysolde a construit la première cabine avec un panier à salade. Moi, j'ai encore le même panier à salade. Il n'a jamais monté nulle part."]],
	["montjoie", "homme", ["L'Albatros est amarré au Mât. Quand le vent tourne, il se balance comme un gros poisson rouge.", "Il paraît qu'au Phare de la Pointe, chaque mouette a un prénom. Celle qui m'a volé ma tartine s'appelle Firmin."]],
	["montjoie", "femme", ["J'ai pris le thé fumé au Piston Joyeux. La machine a sifflé, j'en ai renversé la moitié. Ça fait partie du charme.", "Cette nuit, il y avait une étoile qui clignait au-dessus du Phare. Le Professeur Lunette était tout excité."]],
]

var main: Node
var ile: Node3D
var city: Node3D                         # Hautefond (hautefond_ville_v112)
var dehors: Node3D
var flore: Node3D
var pc: bool = true
var habitants: Array = []
var by_id: Dictionary = {}
var state := {}
var crowd: Array = []                    # [figurant, heure de début, heure de fin, position]
var ships: Array = []                    # [Node3D, centre, rayon, hauteur, vitesse, phase] : les dirigeables qui croisent
var _claims: Dictionary = {}
var _clock: float = 0.0
var _rng := RandomNumberGenerator.new()
var _fires: Array = []
var _smoke: Array = []
var _steam: Array = []
var _sails: Array = []
var _night: float = 0.0
var _night_t: float = 0.0
var _crowd_t: float = 0.0
var _crowd_spawned: bool = false
var _interactions: Array = []
var _hammer_t: float = 0.0
var nuees_ile: Node3D                    # V113 : l'île flottante (ile_nuees_v113)
var nuees: Node3D                        # V113 : la Cité des Nuées (nuees_ville_v113)
var nuees_flore: Node3D
var _crowd_n_spawned: bool = false
var _last_safe_n := Vector3.ZERO
var strates_roche: Node3D                # V114 : la roche des Strates (strates_roche_v114)
var strates: Node3D                      # V114 : les Strates et la Fronde (strates_ville_v114, fronde_v114)
var strates_ligne: Node3D                # V114 : la Ligne des Strates (strates_ligne_v114)
var _crowd_s_spawned: bool = false
var _under: bool = false                 # le joueur est sous terre (on cache la surface, on montre les Strates)
var _last_safe_s := Vector3.ZERO
var dome_fosse: Node3D                   # V115 : la Fosse d'Azur (fosse_azur_v115)
var dome: Node3D                         # V115 : le Dôme d'Azur (dome_azur_v115)
var dome_ligne: Node3D                   # V115 : la Ligne du Dôme d'Azur (dome_ligne_v115)
var dome_vie: Node3D                     # V115 : la vie autour des dômes (dome_vie_v115)
var dome_surface: Node3D                 # V115 : la bouée-phare (à la surface)
var activite: Node3D                     # V116 : la vie dans les lieux ouverts (hautefond_activite_v116)
var activite_nu: Node3D                  # V117 : la vie dans les lieux ouverts de la Cité des Nuées
var activite_st: Node3D                  # V118 : la vie dans les lieux ouverts des Strates et de la Fronde
var activite_da: Node3D                  # V119 : la vie dans les lieux ouverts du Dôme d'Azur
var _crowd_d_spawned: bool = false
var _dome_vis: int = -1                  # 1 : on montre le Dôme (et pas les Strates) ; 0 : l'inverse
var _whale_seen_pass: int = 0


func setup(main_node: Node) -> void:
	main = main_node
	pc = OS.has_feature("ile_manga_pc")
	_rng.seed = 11290
	state = _fresh_state()


func _fresh_state() -> Dictionary:
	return {"visite": false, "visites": {}, "montees": 0, "nuees": false, "capsule": 0, "strates": false, "fronde": false, "descentes": 0, "dome": false, "funiculaire": 0, "baleine": false}


# =================================================================== construction

func build_island() -> void:
	ile = IleScript.new()
	ile.name = "Ile_hautefond_v112"
	add_child(ile)
	ile.build(pc)
	nuees_ile = NueesIle.new()
	nuees_ile.name = "Ile_nuees_v113"
	add_child(nuees_ile)
	nuees_ile.build(pc)
	strates_roche = StratesRoche.new()
	strates_roche.name = "Roche_strates_v114"
	add_child(strates_roche)
	strates_roche.build(pc)
	strates_roche.visible = false
	dome_fosse = DomeFosse.new()
	dome_fosse.name = "Fosse_d_Azur_v115"
	add_child(dome_fosse)
	dome_fosse.build(pc, main._soft_dot_v24() if main != null and main.has_method("_soft_dot_v24") else null)
	dome_fosse.visible = false


## Après le relief et l'heure du jour : la ville, le dehors, la végétation, les feux, les fumées, la
## vapeur, les dirigeables.
func build_town() -> void:
	var t0: int = Time.get_ticks_msec()
	city = CityScript.new()
	city.name = "Hautefond_v112"
	add_child(city)
	city.build(main, ile, pc)
	nuees = NueesVille.new()
	nuees.name = "Cite_des_Nuees_v113"
	add_child(nuees)
	nuees.build(main, nuees_ile, city, pc)
	strates = StratesVille.new()
	strates.name = "Strates_v114"
	add_child(strates)
	strates.build(main, strates_roche, city, pc)
	strates.visible = false
	strates_ligne = load("res://scripts/strates_ligne_v114.gd").new()
	strates_ligne.name = "Ligne_des_Strates_v114"
	add_child(strates_ligne)
	strates_ligne.build(main, strates.kit, city.colonne, strates, pc)
	strates.ligne = strates_ligne
	# V115 : le Dôme d'Azur, sa Ligne, la vie autour
	dome_surface = Node3D.new()
	dome_surface.name = "Dome_surface_v115"
	add_child(dome_surface)
	dome = DomeVille.new()
	dome.name = "Dome_d_Azur_v115"
	add_child(dome)
	dome.build(main, dome_fosse, city, pc, dome_surface)
	dome.visible = false
	dome_ligne = load("res://scripts/dome_ligne_v115.gd").new()
	dome_ligne.name = "Ligne_du_Dome_v115"
	add_child(dome_ligne)
	dome_ligne.build(main, dome, strates, pc)
	dome.ligne = dome_ligne
	dome_ligne.visible = false
	dome_vie = load("res://scripts/dome_vie_v115.gd").new()
	dome_vie.name = "Vie_du_Dome_v115"
	add_child(dome_vie)
	dome_vie.build(main, pc)
	dome_vie.visible = false
	dehors = DehorsScript.new()
	dehors.name = "Hautefond_dehors_v112"
	add_child(dehors)
	dehors.build(self)
	# V116 : les grands lieux qu'on visite (l'atelier de l'horloger, l'Observatoire, le Phare…)
	var p116: Dictionary = city.portes116.duplicate()
	p116.merge(dehors.portes116)
	print("ILE_MANGA_V116: %d grands lieux de Hautefond à visiter" % int(load("res://scripts/lieux_hautefond_v116.gd").register(p116)))
	# V116 : la vie dans les lieux ouverts (les commis, les clients, les dockers…)
	activite = load("res://scripts/hautefond_activite_v116.gd").new()
	add_child(activite)
	activite.build(self)
	# V117 : les grands lieux de la Cité des Nuées (le Café Cumulus, la Tour du Zénith…), et la vie dans
	# ses lieux ouverts
	print("ILE_MANGA_V117: %d grands lieux de la Cité des Nuées à visiter" % int(load("res://scripts/lieux_nuees_v117.gd").register(nuees.portes117)))
	activite_nu = load("res://scripts/nuees_activite_v117.gd").new()
	add_child(activite_nu)
	activite_nu.build(self)
	# V118 : les grands lieux des Strates et de la Fronde (La Marmite, la Maison de la Guilde, le Troc…), et
	# la vie dans leurs lieux ouverts
	print("ILE_MANGA_V118: %d grands lieux des Strates et de la Fronde à visiter" % int(load("res://scripts/lieux_strates_v118.gd").register(strates.portes118, strates.fronde.portes118)))
	activite_st = load("res://scripts/strates_activite_v118.gd").new()
	add_child(activite_st)
	activite_st.build(self)
	# V119 : les grands lieux du Dôme d'Azur (le Petit Plongeon, la Salle des Marées…), les maisons-bulles
	# où l'on entre, et la vie dans ses lieux ouverts
	if dome != null:
		print("ILE_MANGA_V119: %d grands lieux du Dôme d'Azur à visiter" % int(load("res://scripts/lieux_dome_v119.gd").register(dome.portes119)))
		activite_da = load("res://scripts/dome_activite_v119.gd").new()
		add_child(activite_da)
		activite_da.build(self)
	if ResourceLoader.exists(FLORE):
		flore = load(FLORE).new()
		flore.name = "Flore_hautefond_v112"
		add_child(flore)
		for a in city.flora_avoid:
			flore.avoid.append(a)
		for a2 in dehors.flora_avoid:
			flore.avoid.append(a2)
		flore.build_hautefond(ile, pc, {"arbres": city.tree_spots, "vergers": dehors.orchard_spots})
	if ResourceLoader.exists(FLORE_N):
		nuees_flore = load(FLORE_N).new()
		nuees_flore.name = "Flore_nuees_v113"
		add_child(nuees_flore)
		for a3 in nuees.flora_avoid:
			nuees_flore.avoid.append(a3)
		nuees_flore.build_nuees(nuees_ile, pc, {"arbres": nuees.kit.tree_spots, "serre": nuees.serre_spots})
	for f in city.fire_spots:
		_fires.append(_make_fire(f[0], float(f[1])))
	for f2 in dehors.fire_spots:
		_fires.append(_make_fire(f2[0], float(f2[1])))
	var n_smoke: int = 0
	for sp in city.smoke_spots:
		if n_smoke < (40 if pc else 16):
			_smoke.append(_make_smoke(sp, Color(0.55, 0.54, 0.53, 0.22)))
			n_smoke += 1
	var n_steam: int = 0
	for sp2 in city.steam_spots + dehors.kit.steam_spots:
		if n_steam < (30 if pc else 12):
			_steam.append(_make_smoke(sp2, Color(0.95, 0.95, 0.97, 0.3), 0.7))
			n_steam += 1
	# V114 : la vapeur des Strates (les évents de la Place, la Marmite, la Forge, l'orgue des Soupapes)
	if strates != null:
		for sp3 in strates.steam + strates.fronde.steam + strates.fronde.organ_steam:
			var sm: CPUParticles3D = _make_smoke(sp3, Color(0.95, 0.93, 0.9, 0.28), 0.6)
			sm.reparent(strates)
	for k in [city.kit, dehors.kit]:
		for s in k.sails:
			_sails.append(s)
	_ships()
	_glows()
	print("ILE_MANGA_V112: l'Île de Hautefond est prête (%d ms)" % (Time.get_ticks_msec() - t0))


## Deux dirigeables qui tournent lentement au-dessus de la ville (pas de collision).
func _ships() -> void:
	var c: Vector3 = IleScript.W(0.0, 0.0)
	for e in [[150.0, 92.0, 0.018, 0.0, "tissu112_creme", 26.0], [230.0, 128.0, -0.012, 2.4, "tissu112_rouge", 20.0]]:
		var n := Node3D.new()
		n.name = "Dirigeable"
		add_child(n)
		var k = load("res://scripts/hautefond_kit_v112.gd").new()
		k.setup(n, null)
		k.airship112(Transform3D.IDENTITY, float(e[5]), str(e[4]))
		k.commit()
		for ch in n.get_children():
			if ch is GeometryInstance3D:
				(ch as GeometryInstance3D).visibility_range_end = 2200.0
		ships.append([n, c, float(e[0]), float(e[1]), float(e[2]), float(e[3])])
	_ships_tick(0.0)


func _ships_tick(_delta: float) -> void:
	for s in ships:
		var n: Node3D = s[0]
		var a: float = _clock * float(s[4]) + float(s[5])
		var c: Vector3 = s[1]
		var r: float = float(s[2])
		var p := Vector3(c.x + cos(a) * r, float(s[3]) + sin(_clock * 0.2 + float(s[5])) * 2.0, c.z + sin(a) * r)
		var tang := Vector3(-sin(a), 0, cos(a)) * signf(float(s[4]))
		n.global_position = p
		n.global_basis = Basis.looking_at(tang, Vector3.UP) * Basis(Vector3.UP, PI * 0.5) * Basis(Vector3.BACK, sin(_clock * 0.3 + float(s[5])) * 0.03)


## La nuit : les fenêtres, les globes, les cadrans, le phare s'allument.
func _glows() -> void:
	var t: Node = main.get("temps_v56") if main != null else null
	if t == null or not t.has_method("register_glow"):
		Mats.night(0.0)
		MatsN.night(0.0)
		return
	t.register_glow(Mats71.make("vitre71_on"), 2.4, 0.12)
	t.register_glow(Mats.make("lampe112"), 4.0, 0.6)
	t.register_glow(Mats.make("cadran112"), 1.2, 0.05)
	t.register_glow(Mats.make("phare112"), 8.0, 1.0)
	t.register_glow(MatsN.make("led113"), 3.6, 0.4)
	t.register_glow(MatsN.make("led113_chaud"), 3.0, 0.3)
	t.register_glow(MatsN.make("facade113"), 1.6, 0.0)
	if flore != null and flore.get("glow_mats") != null:
		for g in flore.glow_mats:
			t.register_glow(g[0], float(g[1]), float(g[2]))


func _register_interactions() -> void:
	var d: Node = main.get("donjon_v35")
	if d == null:
		return
	if city != null and city.colonne != null:
		city.colonne.register(d, self)
	if nuees != null and nuees.ligne != null:
		nuees.ligne.register(d, self)
	if strates_ligne != null:
		strates_ligne.register(d, self)
	if dome_ligne != null:
		dome_ligne.register(d, self)
	var col: Node3D = city.colonne
	var me = self
	# les lignes rouvertes : un panneau à chaque portail (est et ouest)
	_ia(d, {"id": "hf_ligne_nuees", "pos": col.foot + Vector3(col.R_SOCLE + 3.2, 1.0, 0.0), "radius": 2.6, "text": "E : lire le panneau (Ligne des Nuées)",
		"vr": "Gâchette : lire le panneau (Ligne des Nuées)", "call": func(): me.say("« LIGNE DES NUÉES — ROUVERTE ! Prenez la cabine jusqu'au Belvédère, puis la capsule de verre jusqu'à la Gare des Nuées. La Confrérie des Liftiers vous souhaite bon vent (et pas de vertige). »", 8.0), "when": func(): return true})
	_ia(d, {"id": "hf_ligne_strates", "pos": col.foot + Vector3(-col.R_SOCLE - 3.2, 1.0, 0.0), "radius": 2.6, "text": "E : lire le panneau (Ligne des Strates)",
		"vr": "Gâchette : lire le panneau (Ligne des Strates)", "call": func(): me.say("« LIGNE DES STRATES — ROUVERTE ! Le pavillon est juste derrière : entrez, tirez le levier, et descendez cent mètres sous la ville. LIGNE DU DÔME D'AZUR — ROUVERTE ! À la Gare des Strates, la cage de laiton vous emmène au fond de la mer. » En dessous, quelqu'un a griffonné : « Bienvenue en bas ! Bisous de la Fronde. » Et, plus bas encore, d'une écriture ronde : « Et bienvenue tout en bas ! Le Dôme. »", 8.0), "when": func(): return true})

func _ia(d: Node, it: Dictionary) -> void:
	d._interactions.append(it)
	_interactions.append(it)


func say(text: String, seconds: float = 6.0) -> void:
	if main != null and main.get("donjon_v35") != null:
		main.donjon_v35._say(text, seconds)
	elif main != null:
		main._show_message_v28(text)


func sfx(name: String, at: Vector3) -> void:
	if main != null and main.has_method("sfx"):
		main.sfx(name, at)


# =================================================================== les repères des autres

func dock() -> Array:
	return [IleScript.W(IleScript.DOCK_A.x, IleScript.DOCK_A.y), IleScript.W(IleScript.DOCK_B.x, IleScript.DOCK_B.y)]


func contains(p: Vector3) -> bool:
	return ile != null and ile.contains(p.x, p.z) and p.y > -45.0


## V114 : dans les Strates (ou la Fronde) ?
func in_strates(p: Vector3) -> bool:
	return strates != null and StratesRoche.contains(p)


## V115 : au Dôme d'Azur (ses dômes, ses galeries, la bulle du Funiculaire) ?
func in_dome(p: Vector3) -> bool:
	return dome != null and DomeFosse.contains(p)


func on_structure(p: Vector3) -> bool:
	return (city != null and city.on_structure(p)) or (nuees != null and nuees.on_structure(p))


## V113 : sur la Cité des Nuées (le plateau, ses ponts, la capsule en haut) ?
func on_nuees(p: Vector3) -> bool:
	if nuees_ile == null:
		return false
	if nuees != null and nuees.ligne != null and nuees.ligne.inside(p) and p.y > nuees.ligne.foot.y + 6.0:
		return true
	return p.y > NueesIle.Y0 - 12.0 and nuees_ile.near_xz(p.x, p.z, 10.0)


## À pied : on peut marcher ici (la terre ferme, les quais, la Colonne, le Belvédère) ?
func walkable(p: Vector3) -> bool:
	if not contains(p):
		return false
	if on_structure(p):
		return true
	return ile.height(p.x, p.z) > RIVE_V127 or p.y > 1.0


func blocks_boat(_p: Vector3) -> bool:
	return false


## La zone du joueur (pour la musique, les ambiances, le carnet).
func zone_at(p: Vector3) -> String:
	if in_dome(p):
		return dome.zone_at(p)
	if in_strates(p):
		return strates.zone_at(p)
	if strates_ligne != null and strates_ligne.in_kiosk(p):
		return "hf_colonne"
	if ile == null or not ile.contains(p.x, p.z) or p.y < -20.0:
		return ""
	if nuees != null and on_nuees(p):
		var nz: String = nuees.zone_at(p)
		if nz != "":
			return nz
	if nuees != null and nuees.ligne != null and nuees.ligne.walkable(p) and p.y < nuees.ligne.foot.y + 4.0:
		return "hf_belvedere"
	var cz: String = city.zone_at(p) if city != null else ""
	if cz != "":
		return cz
	var l: Vector2 = IleScript.L(p.x, p.z)
	var h: float = ile.height(p.x, p.z)
	if l.distance_to(IleScript.HARBOR) < IleScript.HARBOR_R + 40.0:
		return "hf_port"
	if l.distance_to(IleScript.PHARE) < 26.0:
		return "hf_phare"
	if h < -0.42 and p.y < 2.0 and not on_structure(p):
		return "" if IleScript.coast_q(l.x, l.y) > 1.12 else "hf_rivage"
	if l.distance_to(IleScript.MILL) < IleScript.HILL_R:
		return "hf_moulin"
	var tp: Vector2 = IleScript.town_polar(l.x, l.y)
	if IleScript.in_arc(tp.x, IleScript.ORCH_A.x, IleScript.ORCH_A.y) and tp.y > IleScript.ORCH_R0 - 6.0 and IleScript.coast_q(l.x, l.y) < 0.95:
		return "hf_vergers"
	if IleScript.cliff_k(tp.x) > 0.5 and IleScript.coast_q(l.x, l.y) > 0.86:
		return "hf_falaises"
	if IleScript.coast_q(l.x, l.y) > 0.9:
		return "hf_plage" if absf(IleScript._adiff(tp.x, 20.0)) < 30.0 else "hf_rivage"
	return "hf_campagne"


func people_at(p: Vector3) -> String:
	var z: String = zone_at(p)
	if z == "":
		return ""
	if z in ["hf_rivage", "hf_campagne", "hf_falaises", "hf_vergers", "hf_moulin", "hf_plage", "hf_phare", "nu_capsule", "st_ligne", "st_grotte", "st_pont", "da_funiculaire"]:
		return "sauvage"
	return "ville"


func village_point(id: String) -> Array:
	match id:
		"hautefond":
			return respawn_point()
		"hautefond_port":
			var q: Vector3 = city.points.get("port_q3", dock()[0])
			return [q + Vector3.UP * 0.3, Vector3(0, 0, 1)]
		"nuees":
			return respawn_nuees()
		"strates":
			return respawn_strates()
		"fronde":
			return respawn_fronde()
		"dome":
			return respawn_dome()
	return []


const PLACES := {"hf_colonne": "la Place de la Colonne", "hf_belvedere": "le Belvédère de la Grande Colonne", "hf_cabine": "la cabine de la Grande Colonne",
	"hf_haute": "Hautefond, la Haute-Ville", "hf_observatoire": "l'Observatoire", "hf_mairie": "l'Hôtel de Ville", "hf_bibliotheque": "la Bibliothèque des Cartes",
	"hf_moyenne": "Hautefond, la Ville-Moyenne", "hf_marche": "le Grand Marché", "hf_taverne": "la taverne « Le Piston Joyeux »", "hf_mat": "le Mât des dirigeables",
	"hf_basse": "Hautefond, la Basse-Ville", "hf_forge": "la Forge à vapeur", "hf_port": "le Port des Cordages", "hf_phare": "le Phare de la Pointe",
	"hf_moulin": "le Moulin des Quatre Vents", "hf_vergers": "les Vergers en terrasses", "hf_falaises": "les Falaises", "hf_plage": "la Plage des Galets Blonds",
	"hf_rivage": "le rivage", "hf_campagne": "la campagne",
	"nu_gare": "la Gare des Nuées", "nu_capsule": "la capsule de la Ligne des Nuées", "nu_belvedere": "le Belvédère de Verre",
	"nu_esplanade": "l'Esplanade du Ciel", "nu_cafe": "le Café Cumulus", "nu_atelier": "l'Atelier des Inventeurs",
	"nu_conseil": "la Maison du Conseil", "nu_serres": "les Serres d'Altitude", "nu_institut": "l'Institut des Vents",
	"nu_port": "le Port des Nuées", "nu_residences": "les Résidences des Terrasses", "nu_parc": "le Parc des Brumes",
	"nu_promenade": "la Promenade du bord", "nu_ville": "les rues",
	"st_gare": "la Gare des Strates", "st_ligne": "la cabine de la Ligne des Strates", "st_place": "la Place des Rouages",
	"st_forge": "la Grande Forge des Strates", "st_marmite": "La Marmite", "st_lumieres": "l'Atelier des Lumières",
	"st_train": "la gare du Petit Train", "st_galeries": "les Galeries", "st_guilde": "la Maison de la Guilde",
	"st_mines": "les Mines de Cristaux", "st_grotte": "la Grotte aux Cristaux", "st_jardins": "les Jardins des Champignons",
	"st_pont": "le Pont des Frondeurs", "st_bord": "le pied des parois", "st_ville": "les rues",
	"fr_entree": "l'entrée", "fr_place": "la Place Libre", "fr_scene": "la Scène des Soupapes", "fr_cantine": "la Cantine Libre",
	"fr_atelier": "l'Atelier Libre", "fr_troc": "le Troc", "fr_assemblee": "l'Assemblée", "fr_skate": "le Skatepark",
	"fr_fresques": "le Mur des Fresques",
	"da_gare": "la Gare d'Azur", "da_funiculaire": "la bulle du Funiculaire d'Azur", "da_place": "la Place de la Perle", "da_conque": "La Conque",
	"da_comptoir": "le Comptoir des Courants", "da_atelier": "l'Atelier des Scaphandres", "da_ecole": "l'École des Abysses",
	"da_conseil": "la Maison du Conseil des Marées", "da_jardin": "le Jardin des Coraux", "da_hublots": "la Promenade des Hublots",
	"da_belvedere": "le Belvédère des Abysses", "da_ville": "les allées", "da_galerie": "les galeries de verre", "da_serres": "le Dôme des Serres",
	"da_institut": "l'Institut des Abysses", "da_aquarium": "le Grand Aquarium", "da_bassin": "le Bassin des Bathyscaphes"}


func place_name(p: Vector3) -> String:
	var z: String = zone_at(p)
	if z.begins_with("nu_"):
		return "Cité des Nuées, " + str(PLACES.get(z, "les rues"))
	if z.begins_with("st_"):
		return "Les Strates, " + str(PLACES.get(z, "les rues"))
	if z.begins_with("fr_"):
		return "La Fronde, " + str(PLACES.get(z, "la Place Libre"))
	if z.begins_with("da_"):
		return "Le Dôme d'Azur, " + str(PLACES.get(z, "les allées"))
	return "Île de Hautefond, " + str(PLACES.get(z, "l'île"))


func respawn_point() -> Array:
	var sp: Dictionary = spot("place_fontaine")
	if sp.is_empty():
		return [city.points.values()[0] + Vector3.UP * 0.3, Vector3(0, 0, 1)]
	return [(sp["pos"] as Vector3) + Vector3.UP * 0.3, sp["face"]]


## V113 : le point de retour sur la Cité des Nuées (devant le miroir d'eau de l'Esplanade).
func respawn_nuees() -> Array:
	var sp: Dictionary = spot("esplanade_fontaine")
	if sp.is_empty():
		return [NueesIle.W(0.0, 14.0, 0.4), Vector3(0, 0, -1)]
	return [(sp["pos"] as Vector3) + Vector3.UP * 0.3 + (sp["face"] as Vector3) * -1.2, sp["face"]]


## V114 : le point de retour dans les Strates (sur le quai de la Gare) et dans la Fronde.
func respawn_strates() -> Array:
	var sp: Dictionary = spot("st_gare_quai")
	if sp.is_empty():
		return [StratesRoche.W(0.0, 7.0, StratesRoche.F0 + 0.3), Vector3(0, 0, 1)]
	return [(sp["pos"] as Vector3) + Vector3.UP * 0.3 + Vector3(0, 0, 1.5), Vector3(0, 0, 1)]


## V115 : le point de retour au Dôme d'Azur (devant la Fontaine des Bulles).
func respawn_dome() -> Array:
	var c: Vector3 = DomeVille.PR(-75.0, 9.0) if dome != null else DomeFosse.W(0.0, -9.0, 0.0)
	return [c + Vector3.UP * 0.3, (DomeVille.P(0, 0) - c).normalized() if dome != null else Vector3(0, 0, 1)]


func respawn_fronde() -> Array:
	var p: Vector3 = city.points.get("fr_p_0", StratesRoche.W(112.0, 23.0, -98.0))
	return [p + Vector3.UP * 0.3, Vector3(1, 0, 0.2).normalized()]


## V114 : les Soupapes jouent chaque soir, de 20 h à 23 h (pour pnj_boucan_v75 : la scène, la fosse).
func concert_on() -> bool:
	var h: float = hour()
	return h >= 20.0 and h < 23.0


func hostile_zone(_p: Vector3) -> bool:
	return false


func hour() -> float:
	return float(main.temps_v56.hour) if main != null and main.get("temps_v56") != null and main.temps_v56 != null else 12.0


# =================================================================== les habitants

func spot(name: String) -> Dictionary:
	if city != null and (city.spots as Dictionary).has(name):
		return city.spots[name]
	return {}


func spot_free(name: String, who: Node) -> bool:
	var c: Variant = _claims.get(name, null)
	return c == null or c == who or not is_instance_valid(c)


func claim_spot(name: String, who: Node) -> void:
	_claims[name] = who


func release_spot(name: String, who: Node) -> void:
	if _claims.get(name, null) == who:
		_claims.erase(name)


func spawn_npcs() -> void:
	if not habitants.is_empty() or city == null or not ResourceLoader.exists(HABITANTS) or not ResourceLoader.exists(PNJ):
		return
	var H = load(HABITANTS)
	var P = load(PNJ)
	for data in H.all_profiles():
		var home: String = str(data.get("maison", ""))
		var start: String = home if city.points.has(home) else str(city.points.keys()[0])
		var npc: Node3D = P.new()
		main.add_child(npc)
		npc.setup(main, data, city.points, city.graph, start)
		npc.setup_azur(self, data)
		var saved: Variant = main.pending_pnj_v31.get(str(data["id"]), {})
		if saved is Dictionary and not (saved as Dictionary).is_empty():
			npc.load_data(saved)
		main.npcs_v31.append(npc)
		habitants.append(npc)
		by_id[str(data["id"])] = npc
	print("ILE_MANGA_V112: %d habitants à Hautefond" % habitants.size())
	if nuees != null and ResourceLoader.exists(HABITANTS_N) and ResourceLoader.exists(PNJ_N):
		var HN = load(HABITANTS_N)
		var PN = load(PNJ_N)
		var n0: int = habitants.size()
		for data2 in HN.all_profiles():
			var home2: String = str(data2.get("maison", ""))
			var start2: String = home2 if city.points.has(home2) else "nu_es_0"
			var npc2: Node3D = PN.new()
			main.add_child(npc2)
			npc2.setup(main, data2, city.points, city.graph, start2)
			npc2.setup_azur(self, data2)
			var saved2: Variant = main.pending_pnj_v31.get(str(data2["id"]), {})
			if saved2 is Dictionary and not (saved2 as Dictionary).is_empty():
				npc2.load_data(saved2)
			main.npcs_v31.append(npc2)
			habitants.append(npc2)
			by_id[str(data2["id"])] = npc2
		print("ILE_MANGA_V113: %d habitants dans la Cité des Nuées" % (habitants.size() - n0))
	# V114 : les gens des Strates (comme ceux d'en haut) et les Frondeurs (comme ceux de Port-Boucan)
	if strates != null:
		for spec in [[HABITANTS_S, PNJ, "st_p_gare", "Strates"], [HABITANTS_F, PNJ_F, "fr_p_0", "Fronde"]]:
			if not ResourceLoader.exists(str(spec[0])) or not ResourceLoader.exists(str(spec[1])):
				continue
			var HS = load(str(spec[0]))
			var PS = load(str(spec[1]))
			var n1: int = habitants.size()
			for data3 in HS.all_profiles():
				var home3: String = str(data3.get("maison", ""))
				var start3: String = home3 if city.points.has(home3) else str(spec[2])
				var npc3: Node3D = PS.new()
				main.add_child(npc3)
				npc3.setup(main, data3, city.points, city.graph, start3)
				npc3.setup_azur(self, data3)
				var saved3: Variant = main.pending_pnj_v31.get(str(data3["id"]), {})
				if saved3 is Dictionary and not (saved3 as Dictionary).is_empty():
					npc3.load_data(saved3)
				main.npcs_v31.append(npc3)
				habitants.append(npc3)
				by_id[str(data3["id"])] = npc3
			print("ILE_MANGA_V114: %d habitants dans %s" % [habitants.size() - n1, "les Strates" if spec[3] == "Strates" else "la Fronde"])
	# V115 : les gens du Dôme d'Azur (le costume des Nuées)
	if dome != null and ResourceLoader.exists(HABITANTS_D) and ResourceLoader.exists(PNJ_N):
		var HD = load(HABITANTS_D)
		var PD = load(PNJ_N)
		var n2: int = habitants.size()
		for data4 in HD.all_profiles():
			var home4: String = str(data4.get("maison", ""))
			var start4: String = home4 if city.points.has(home4) else "da_p_pl_0"
			var npc4: Node3D = PD.new()
			main.add_child(npc4)
			npc4.setup(main, data4, city.points, city.graph, start4)
			npc4.setup_azur(self, data4)
			var saved4: Variant = main.pending_pnj_v31.get(str(data4["id"]), {})
			if saved4 is Dictionary and not (saved4 as Dictionary).is_empty():
				npc4.load_data(saved4)
			main.npcs_v31.append(npc4)
			habitants.append(npc4)
			by_id[str(data4["id"])] = npc4
		print("ILE_MANGA_V115: %d habitants au Dôme d'Azur" % (habitants.size() - n2))


## Les habitants prennent la cabine : quand l'un d'eux arrive au pied (ou en haut) de la cage et
## repart vers l'autre bout, il est monté (ou descendu) avec elle.
func _npc_lift() -> void:
	if city == null or not city.points.has("cab_haut"):
		return
	for pair in [["cab_bas", "cab_haut"], ["nu_cab_bas", "nu_cab_haut"]]:
		if not city.points.has(pair[1]):
			continue
		var top_y: float = (city.points[pair[1]] as Vector3).y
		var low_y: float = (city.points[pair[0]] as Vector3).y
		for npc in habitants:
			if not is_instance_valid(npc):
				continue
			var ap: String = str(npc.get("at_point"))
			var y: float = (npc as Node3D).global_position.y
			if ap == pair[1] and y < top_y - 5.0:
				(npc as Node3D).global_position.y += top_y - low_y
			elif ap == pair[0] and y > low_y + 5.0:
				(npc as Node3D).global_position.y -= top_y - low_y


## Les services (les comptoirs, les lieux pour le carnet et les quêtes à venir).
func register_services(journal: Node) -> void:
	for k in city.objets:
		journal.lieux["hf_" + str(k)] = city.objets[k]
	if dehors != null:
		for k2 in dehors.objets:
			journal.lieux["hf_" + str(k2)] = dehors.objets[k2]
	journal.lieux["hautefond"] = respawn_point()[0]
	journal.lieux["hf_colonne"] = city.colonne.foot
	journal.lieux["hf_belvedere"] = city.colonne.top
	if nuees != null:
		for k3 in nuees.objets:
			journal.lieux["nu_" + str(k3)] = nuees.objets[k3]
		journal.lieux["nuees"] = respawn_nuees()[0]
	if strates != null:
		for k4 in strates.objets:
			journal.lieux["st_" + str(k4)] = strates.objets[k4]
		for k5 in strates.fronde.objets:
			journal.lieux["fr_" + str(k5)] = strates.fronde.objets[k5]
		journal.lieux["strates"] = respawn_strates()[0]
		journal.lieux["fronde"] = respawn_fronde()[0]
		journal.lieux["st_pavillon"] = strates_ligne.kiosk
	if dome != null:
		for k6 in dome.objets:
			journal.lieux["da_" + str(k6)] = dome.objets[k6]
		journal.lieux["dome"] = respawn_dome()[0]
		if dome_ligne != null:
			journal.lieux["da_cage"] = dome_ligne.cage_pos
	_register_interactions()


func after_reply(_r: Dictionary, _npc: Node) -> void:
	pass


# =================================================================== les passants

func _spawn_crowd() -> void:
	_crowd_spawned = true
	var names: Array = []
	for s in city.crowd_spots:
		names.append(str(s))
	var rng := RandomNumberGenerator.new()
	rng.seed = 112000
	names.shuffle()
	var n: int = mini(PASSANTS.size() if pc else 10, names.size())
	for i in range(n):
		var e: Array = PASSANTS[i]
		var sname: String = str(names[i])
		var sp: Dictionary = city.spots.get(sname, {})
		if sp.is_empty():
			continue
		var prof: Dictionary = Gens.pick(str(e[0]), str(e[1]), rng)
		if prof.is_empty():
			continue
		prof["nom"] = Gens.prenom(str(e[0]), str(e[1]), rng)
		var f: Node = Figurant.spawn(self, main, prof, sp["pos"], sp["face"], str(sp["pose"]))
		if f == null:
			continue
		f.set("lines", e[2])
		claim_spot(sname, f)
		var h0: float = [7.0, 8.0, 9.0, 10.0, 14.0, 16.0][i % 6]
		var h1: float = [18.0, 20.0, 21.0, 19.0, 22.0, 23.0][i % 6]
		crowd.append([f, h0, h1, sp["pos"]])
	_crowd_vis(true)


## V113 : les passants de la Cité des Nuées (des gens de Néopolis, habillés de clair, sans implant).
func _spawn_crowd_n() -> void:
	_crowd_n_spawned = true
	if nuees == null or not ResourceLoader.exists(PASSANTS_N):
		return
	var list: Array = load(PASSANTS_N).PASSANTS
	var names: Array = nuees.crowd_spots.duplicate()
	var rng := RandomNumberGenerator.new()
	rng.seed = 113000
	names.shuffle()
	var clairs: Array = [[0.92, 0.92, 0.9], [0.86, 0.88, 0.9], [0.78, 0.84, 0.9], [0.86, 0.8, 0.68], [0.62, 0.72, 0.64], [0.7, 0.72, 0.76], [0.94, 0.9, 0.84]]
	var douces: Array = [[0.42, 0.62, 0.8], [0.56, 0.7, 0.58], [0.86, 0.66, 0.5], [0.7, 0.62, 0.82], [0.9, 0.8, 0.46]]
	var n: int = mini(list.size() if pc else 8, names.size())
	for i in range(n):
		var e: Array = list[i]
		var sname: String = str(names[i])
		var sp: Dictionary = city.spots.get(sname, {})
		if sp.is_empty():
			continue
		var role: String = str(e[1])
		var prof: Dictionary = Gens.pick("neo", role, rng)
		if prof.is_empty():
			continue
		prof = prof.duplicate(true)
		var ne: Dictionary = prof.get("neo", {})
		ne.erase("implant")
		ne.erase("circuit")
		ne.erase("props")
		ne["c"] = clairs[rng.randi() % clairs.size()]
		ne["c2"] = douces[rng.randi() % douces.size()]
		if not role in ["enfant", "garcon", "fille"]:
			ne["tenue"] = ["tailleur", "techwear", "sweat", "jardinier", "tailleur"][rng.randi() % 5]
		ne.erase("chapeau")
		prof["neo"] = ne
		var az: Dictionary = prof.get("azur", {})
		if az.has("cheveux") and rng.randf() < 0.8:
			az["cheveux"] = [[0.2, 0.14, 0.1], [0.5, 0.36, 0.22], [0.82, 0.7, 0.46], [0.1, 0.08, 0.07], [0.86, 0.86, 0.84]][rng.randi() % 5]
		var lst: Array = PRENOMS_N["f" if Gens.femme(role) else "h"]
		prof["nom"] = str(lst[rng.randi() % lst.size()])
		var f: Node = Figurant.spawn(self, main, prof, sp["pos"], sp["face"], str(sp["pose"]))
		if f == null:
			continue
		f.set("lines", e[2])
		claim_spot(sname, f)
		var h0: float = [7.0, 8.0, 9.0, 10.0, 13.0, 15.0][i % 6]
		var h1: float = [19.0, 21.0, 22.0, 18.0, 23.0, 20.0][i % 6]
		crowd.append([f, h0, h1, sp["pos"]])
	_crowd_vis(true)


## V114 : les passants des Strates (comme ceux d'en haut) et de la Fronde (des Frondeurs, comme les gens
## de Port-Boucan).
func _spawn_crowd_s() -> void:
	_crowd_s_spawned = true
	if strates == null:
		return
	var list: Array = []
	if ResourceLoader.exists(PASSANTS_S):
		list += load(PASSANTS_S).PASSANTS
	var list_f: Array = load(PASSANTS_F).PASSANTS if ResourceLoader.exists(PASSANTS_F) else []
	var names_s: Array = []
	var names_f: Array = []
	for nm in strates.crowd_spots:
		if str(nm).begins_with("fr_"):
			names_f.append(str(nm))
		else:
			names_s.append(str(nm))
	var rng := RandomNumberGenerator.new()
	rng.seed = 114000
	names_s.shuffle()
	names_f.shuffle()
	for pack in [[list, names_s, 12 if pc else 6], [list_f, names_f, 8 if pc else 4]]:
		var lst: Array = pack[0]
		var nms: Array = pack[1]
		var n: int = mini(mini(lst.size(), int(pack[2])), nms.size())
		for i in range(n):
			var e: Array = lst[i]
			var sname: String = str(nms[i])
			var sp: Dictionary = city.spots.get(sname, {})
			if sp.is_empty():
				continue
			var style: String = "boucan" if str(e[0]) == "fronde" else str(e[0])
			var role: String = str(e[1])
			if role == "enfant":
				role = "garcon" if rng.randf() < 0.5 else "fille"
			var prof: Dictionary = Gens.pick(style, role, rng)
			if prof.is_empty():
				continue
			prof["nom"] = Gens.prenom(style, role, rng)
			var f: Node = Figurant.spawn(self, main, prof, sp["pos"], sp["face"], str(sp["pose"]))
			if f == null:
				continue
			f.set("lines", e[2])
			claim_spot(sname, f)
			var h0: float = [6.0, 7.0, 8.0, 10.0, 12.0, 15.0][i % 6]
			var h1: float = [19.0, 21.0, 23.0, 20.0, 22.0, 18.0][i % 6]
			crowd.append([f, h0, h1, sp["pos"]])
	_crowd_vis(true)


## V115 : les passants du Dôme d'Azur (le costume des Nuées, aux couleurs du Dôme : nacre, aigue-marine,
## bleu nuit, corail doux).
func _spawn_crowd_d() -> void:
	_crowd_d_spawned = true
	if dome == null or not ResourceLoader.exists(PASSANTS_D):
		return
	var list: Array = load(PASSANTS_D).PASSANTS
	var names: Array = dome.crowd_spots.duplicate()
	var rng := RandomNumberGenerator.new()
	rng.seed = 115000
	names.shuffle()
	var clairs: Array = [[0.95, 0.94, 0.92], [0.86, 0.92, 0.94], [0.9, 0.88, 0.84], [0.8, 0.86, 0.9], [0.92, 0.9, 0.94]]
	var douces: Array = [[0.25, 0.62, 0.66], [0.12, 0.24, 0.38], [0.88, 0.55, 0.5], [0.4, 0.7, 0.78], [0.55, 0.5, 0.72]]
	var n: int = mini(list.size() if pc else 8, names.size())
	for i in range(n):
		var e: Array = list[i]
		var sname: String = str(names[i])
		var sp: Dictionary = city.spots.get(sname, {})
		if sp.is_empty():
			continue
		var role: String = str(e[1])
		var prof: Dictionary = Gens.pick("neo", role, rng)
		if prof.is_empty():
			continue
		prof = prof.duplicate(true)
		var ne: Dictionary = prof.get("neo", {})
		ne.erase("implant")
		ne.erase("circuit")
		ne.erase("props")
		ne["c"] = clairs[rng.randi() % clairs.size()]
		ne["c2"] = douces[rng.randi() % douces.size()]
		if not role in ["enfant", "garcon", "fille"]:
			ne["tenue"] = ["combinaison", "techwear", "tailleur", "jardinier", "mecano"][rng.randi() % 5]
		ne.erase("chapeau")
		prof["neo"] = ne
		var az: Dictionary = prof.get("azur", {})
		if az.has("cheveux") and rng.randf() < 0.8:
			az["cheveux"] = [[0.2, 0.14, 0.1], [0.5, 0.36, 0.22], [0.82, 0.7, 0.46], [0.1, 0.08, 0.07], [0.86, 0.86, 0.84], [0.62, 0.3, 0.18]][rng.randi() % 6]
		var lst: Array = PRENOMS_D["f" if Gens.femme(role) else "h"]
		prof["nom"] = str(lst[rng.randi() % lst.size()])
		var f: Node = Figurant.spawn(self, main, prof, sp["pos"], sp["face"], str(sp["pose"]))
		if f == null:
			continue
		f.set("lines", e[2])
		claim_spot(sname, f)
		var h0: float = [7.0, 8.0, 9.0, 10.0, 12.0, 14.0][i % 6]
		var h1: float = [19.0, 21.0, 22.0, 18.0, 23.0, 20.0][i % 6]
		crowd.append([f, h0, h1, sp["pos"]])
	_crowd_vis(true)


static func _in_hours(h: float, a: float, b: float) -> bool:
	return (a <= b and h >= a and h < b) or (a > b and (h >= a or h < b))


func _crowd_vis(force: bool = false) -> void:
	var p: Vector3 = main._player_pos_v27()
	var h: float = hour()
	for c in crowd:
		var f: Node = c[0]
		if not is_instance_valid(f):
			continue
		var npc: Node3D = f.get("npc")
		if npc == null:
			continue
		var want: bool = _in_hours(h, float(c[1]), float(c[2])) and (c[3] as Vector3).distance_to(p) < 240.0
		if want != npc.visible or force:
			npc.visible = want
			f.process_mode = Node.PROCESS_MODE_INHERIT if want else Node.PROCESS_MODE_DISABLED
			for k in npc.get_children():
				if k is PhysicsBody3D:
					for cs in k.get_children():
						if cs is CollisionShape3D:
							(cs as CollisionShape3D).disabled = not want


# =================================================================== la vie de l'île

func _process(delta: float) -> void:
	if main == null or ile == null:
		return
	_clock += delta
	for s in _sails:
		if is_instance_valid(s):
			(s as Node3D).rotate_object_local(Vector3.BACK, delta * 0.55)
	var p: Vector3 = main._player_pos_v27()
	var dist: float = Vector2(p.x - IleScript.CENTER.x, p.z - IleScript.CENTER.z).length()
	if dist > 1600.0:
		return
	_ships_tick(delta)
	_night_t -= delta
	if _night_t <= 0.0:
		_night_t = 1.0
		var h: float = hour()
		_night = 1.0 if (h >= 20.0 or h < 5.5) else (smoothstep(18.5, 20.0, h) if h > 12.0 else 1.0 - smoothstep(5.5, 7.0, h))
		if city != null and city.colonne != null:
			city.colonne.set_night(_night)
		if nuees_ile != null:
			nuees_ile.set_night(_night)
		if nuees != null and nuees.ligne != null:
			nuees.ligne.set_night(_night)
		if strates != null:
			MatsS.night(_night)
		if dome != null:
			MatsD.night(_night)
			dome.night_glass(_night)
			_dome_env(_night)
	_under_vis(p)
	if dome != null and _dome_vis == 1:
		dome.tick(delta, _night, true)
	if dome_vie != null:
		dome_vie.tick(delta, _dome_vis == 1)
	if strates != null and _under:
		strates.tick(delta, _night, true)
		strates_roche.tick(delta)
	if dehors != null:
		dehors.tick(delta, _clock, _night)
	if nuees_ile != null:
		nuees_ile.tick(delta, dist < 900.0)
	if nuees != null:
		nuees.tick(delta, _night, dist < 700.0)
	if dist > 700.0:
		return
	if city != null and city.colonne != null:
		city.colonne.spin_gears(delta)
	_npc_lift()
	var lx = city.lieux if city != null else null
	if lx != null and lx.airship != null:
		lx.airship.transform = lx.airship_base * Transform3D(Basis(Vector3.UP, sin(_clock * 0.17) * 0.06) * Basis(Vector3.RIGHT, sin(_clock * 0.31) * 0.02), Vector3(0, sin(_clock * 0.4) * 0.25, 0))
	if lx != null and lx.steam_hammer != null:
		_hammer_t += delta
		var ph: float = fmod(_hammer_t, 2.4)
		var y: float = 1.2 if ph < 1.6 else lerpf(1.2, 0.0, smoothstep(1.6, 1.75, ph)) + lerpf(0.0, 1.2, smoothstep(1.9, 2.4, ph))
		(lx.steam_hammer as Node3D).global_position = lx.hammer_base + Vector3.UP * (y - 0.6)
		if ph - delta < 1.75 and ph >= 1.75 and p.distance_to(lx.hammer_base) < 30.0:
			sfx("enclume", lx.hammer_base)
	_crowd_t -= delta
	if _crowd_t <= 0.0:
		_crowd_t = 1.5
		if not _crowd_spawned:
			if dist < 420.0 and bool(main.get("game_started")):
				_spawn_crowd()
		else:
			if not _crowd_n_spawned and nuees != null and on_nuees(p) and bool(main.get("game_started")):
				_spawn_crowd_n()
			if not _crowd_s_spawned and in_strates(p) and bool(main.get("game_started")):
				_spawn_crowd_s()
			if not _crowd_d_spawned and in_dome(p) and bool(main.get("game_started")):
				_spawn_crowd_d()
			_crowd_vis()
	_dome_tick(p)
	if not ile.contains(p.x, p.z):
		return
	_nuees_tick(p)
	_strates_tick(p)
	if not bool(state["visite"]) and (ile.height(p.x, p.z) > -0.2 or on_structure(p)) and bool(main.get("game_started")):
		state["visite"] = true
		main._show_message_v28("L'Île de Hautefond — la cité-colonne (ça monte !)")
		if main.has_method("jingle"):
			main.jingle("decouverte")
	if city == null:
		return
	var z: String = zone_at(p)
	var vis: Dictionary = state["visites"]
	if z == "hf_belvedere" and not bool(vis.get("belvedere", false)):
		vis["belvedere"] = true
		main._show_message_v28("Le Belvédère de la Grande Colonne : toute l'île à vos pieds")
	elif people_at(p) == "ville" and not bool(vis.get("ville", false)):
		vis["ville"] = true
		main._show_message_v28("Hautefond, la ville de pierre blonde, autour de sa Grande Colonne")
	for key in ["marche", "port", "phare", "moulin", "vergers", "falaises", "observatoire", "bibliotheque", "taverne", "mat"]:
		if z == "hf_" + key and not bool(vis.get(key, false)):
			vis[key] = true
	var mer: Node = main.get("mer_v55")
	if mer != null and mer.get("_underside") != null:
		(mer._underside as Node3D).global_position = Vector3(snappedf(p.x, 40.0), (mer._underside as Node3D).global_position.y, snappedf(p.z, 40.0))
	state["montees"] = int(city.colonne.rides)
	if nuees != null and nuees.ligne != null:
		state["capsule"] = int(nuees.ligne.rides)
	if strates_ligne != null:
		state["descentes"] = int(strates_ligne.rides)
	if dome_ligne != null:
		state["funiculaire"] = int(dome_ligne.rides)


## V115 : au Dôme, le soir, la lumière baisse avec la Grande Perle (elle passe au bleu nuit et au violet) :
## la lumière ambiante que donjon_v35 a posée en entrant (0,5) descend doucement, et bleuit.
func _dome_env(k: float) -> void:
	if _dome_vis != 1 or main == null:
		return
	for c in main.get_children():
		if c is WorldEnvironment and (c as WorldEnvironment).environment != null:
			var env: Environment = (c as WorldEnvironment).environment
			env.ambient_light_energy = lerpf(0.5, 0.26, k)
			env.ambient_light_color = Color(0.58, 0.68, 0.78).lerp(Color(0.46, 0.44, 0.72), k)
			return


## V114 : sous terre, on cache la surface (la ville, le dehors, la végétation, la Cité des Nuées : on ne
## les verrait pas à travers la roche) et l'on montre les Strates ; et l'inverse en remontant.
func _under_vis(p: Vector3) -> void:
	if strates == null:
		return
	var deep: bool = in_strates(p) or in_dome(p) or (strates_ligne != null and strates_ligne.carrying and p.y < -20.0) or (dome_ligne != null and dome_ligne.carrying)
	var want: bool = _under
	if not _under and (deep or p.y < -35.0) and p.distance_to(StratesRoche.O) < 420.0:
		want = true
	elif _under and (p.y > -20.0 or p.distance_to(StratesRoche.O) > 460.0):
		want = false
	# V115 : au Dôme d'Azur, on montre le Dôme (pas les Strates) ; aux Strates, l'inverse
	var dv: int = 1 if (want and dome != null and in_dome(p)) else 0
	if want == _under and dv == _dome_vis:
		return
	var changed: bool = want != _under
	_under = want
	_dome_vis = dv
	strates.visible = _under and dv == 0
	strates_roche.visible = _under and dv == 0
	if dome != null:
		dome.visible = dv == 1
		dome_fosse.visible = dv == 1
		dome_vie.visible = dv == 1
		dome_ligne.visible = _under
	if not changed:
		# des Strates au Dôme (ou l'inverse) sans passer par la surface : la lumière change aussi
		var dj: Node = main.get("donjon_v35")
		if dj != null and _under and dj.has_method("update_inside"):
			dj.update_inside(true)
			_dome_env(_night)
		return
	for n in [city, dehors, flore, nuees, nuees_ile, nuees_flore, ile]:
		if n != null:
			(n as Node3D).visible = not _under
	for sm in _smoke + _fires:
		if is_instance_valid(sm):
			(sm as Node3D).visible = not _under


## V114 : les Strates et la Fronde : la découverte, les lieux visités ; le Gouffre (on vous repêche) ;
## le tube de la Colonne Renversée (on n'y reste pas en l'air).
func _strates_tick(p: Vector3) -> void:
	if strates == null or not in_strates(p):
		return
	var l: Vector3 = StratesRoche.L(p)
	if strates_ligne != null and strates_ligne.in_shaft(p) and not strates_ligne.carrying and not strates_ligne.in_deep_cabin(p):
		var at0: Array = respawn_strates()
		main.place_player_v35(at0[0], at0[1])
		return
	if l.y < -112.0 and l.x > 88.0 and l.x < 104.0:
		var east: bool = l.x > (StratesRoche.GOUFFRE_X0 + StratesRoche.GOUFFRE_X1) * 0.5
		var at: Vector3 = city.points.get("fr_p_0" if east else "st_p_fr_1", StratesRoche.W(110.0, 23.0, -98.0))
		main.place_player_v35(at + Vector3.UP * 0.3, Vector3(1, 0, 0.3).normalized() if east else Vector3(-1, 0, -0.3).normalized())
		main._show_message_v28("Plouf ! La rivière du Gouffre vous emporte… et le filet des cheminots vous repêche au bout du Pont. Brasero vous tend une couverture : « On ne se penche pas, on regarde. »")
		return
	if not bool(main.get("game_started")):
		return
	var z: String = zone_at(p)
	var vis: Dictionary = state["visites"]
	if z.begins_with("st_") and not bool(state.get("strates", false)):
		state["strates"] = true
		main._show_message_v28("Les Strates — la ville sous la ville, sous son Soleil de Laiton")
		if main.has_method("jingle"):
			main.jingle("decouverte")
	if z.begins_with("fr_") and not bool(state.get("fronde", false)):
		state["fronde"] = true
		main._show_message_v28("La Fronde — le quartier libre (ici, tout se décide en Assemblée)")
		if main.has_method("jingle"):
			main.jingle("decouverte")
	for key in ["st_forge", "st_mines", "st_grotte", "st_jardins", "st_galeries", "st_guilde", "st_train", "st_marmite", "st_lumieres", "st_pont",
			"fr_scene", "fr_cantine", "fr_atelier", "fr_troc", "fr_assemblee", "fr_skate", "fr_fresques"]:
		if z == key and not bool(vis.get(key, false)):
			vis[key] = true
			if key == "st_grotte":
				main._show_message_v28("La Grotte aux Cristaux : la roche s'allume en bleu, tout doucement")
			elif key == "st_pont":
				main._show_message_v28("Le Pont des Frondeurs : sous vos pieds, le Gouffre (et, très loin, une rivière qui luit)")


## V115 : le Dôme d'Azur : la découverte, les lieux visités, la baleine ; et si l'on se retrouve hors
## des dômes (dans l'eau, hors du verre) ou au fond du puits des bathyscaphes, on vous repêche.
func _dome_tick(p: Vector3) -> void:
	if dome == null or not in_dome(p):
		return
	var l: Vector3 = DomeFosse.L(p)
	if dome_ligne != null and (dome_ligne.carrying or dome_ligne.in_cabin(p)):
		return
	var bc: Vector3 = dome.objets.get("bassin", Vector3.INF)
	if bc != Vector3.INF and l.y < -1.6 and Vector2(p.x - bc.x, p.z - bc.z).length() < DomeVille.POOL_R + 0.5:
		var at: Array = [bc + DomeVille.dirv(300.0) * (DomeVille.POOL_R + 2.4) + Vector3.UP * 0.3, Vector3(0, 0, 1)]
		main.place_player_v35(at[0], at[1])
		main._show_message_v28("Plouf ! L'eau du puits est glacée… Une perche vous repêche : « Le Bassin des Bathyscaphes, c'est pour les bathyscaphes ! » Ça réveille.")
		return
	if not dome.inside_air(p):
		var at2: Array = respawn_dome()
		main.place_player_v35(at2[0], at2[1])
		main._show_message_v28("Ouh là… Vous voilà de retour sur la Place de la Perle, tout étourdi. Ici, on reste à l'abri du verre !")
		return
	if not bool(main.get("game_started")):
		return
	var z: String = zone_at(p)
	var vis: Dictionary = state["visites"]
	if not bool(state.get("dome", false)) and z != "da_funiculaire":
		state["dome"] = true
		main._show_message_v28("Le Dôme d'Azur — la ville au fond de la mer (respirez : l'air vient de la surface)")
		if main.has_method("jingle"):
			main.jingle("decouverte")
	for key in ["da_serres", "da_institut", "da_aquarium", "da_bassin", "da_belvedere", "da_conque", "da_jardin", "da_hublots", "da_ecole"]:
		if z == key and not bool(vis.get(key, false)):
			vis[key] = true
			if key == "da_belvedere":
				main._show_message_v28("Le Belvédère des Abysses : sous le verre, la Faille plonge dans le noir… Écoutez : parfois, la Grande Chanteuse chante.")
			elif key == "da_bassin":
				main._show_message_v28("Le Bassin des Bathyscaphes : un puits ouvert sur la mer, au ras du sol. La pression garde l'eau dehors. Magique ? Non : physique !")
	if dome_vie != null and int(dome_vie.passes) > _whale_seen_pass and dome_vie.whale.visible:
		_whale_seen_pass = int(dome_vie.passes)
		if not bool(state.get("baleine", false)):
			state["baleine"] = true
			main._show_message_v28("Là-haut, au-dessus des dômes… une ombre immense passe dans le bleu : la Grande Chanteuse !")


## V113 : la Cité des Nuées : la découverte, les lieux visités, et le filet qui rattrape ceux qui
## passent par-dessus bord (sauf en aéronef).
func _nuees_tick(p: Vector3) -> void:
	if nuees == null or nuees_ile == null:
		return
	if nuees.ligne != null and nuees.ligne.inside(p):
		_last_safe_n = Vector3.ZERO
		return
	var on_top: bool = nuees_ile.on_top(p) or (nuees.on_structure(p) and p.y > NueesIle.Y0 - 6.0)
	if on_top:
		_last_safe_n = p
		if not bool(state.get("nuees", false)) and bool(main.get("game_started")):
			state["nuees"] = true
			main._show_message_v28("La Cité des Nuées — au-dessus des nuages (bon vent !)")
			if main.has_method("jingle"):
				main.jingle("decouverte")
		var z: String = zone_at(p)
		var vis: Dictionary = state["visites"]
		for key in ["esplanade", "gare", "belvedere", "serres", "institut", "port", "parc", "cafe", "atelier", "conseil", "residences"]:
			if z == "nu_" + key and not bool(vis.get("nu_" + key, false)):
				vis["nu_" + key] = true
				if key == "belvedere":
					main._show_message_v28("Le Belvédère de Verre : deux cents mètres de vide sous vos pieds (le verre est très solide)")
	elif _last_safe_n != Vector3.ZERO and p.y < NueesIle.Y0 - 25.0 and p.y > NueesIle.Y0 - 260.0:
		var flying: bool = main.get("aeronef_v76") != null and main.aeronef_v76 != null and bool(main.aeronef_v76.get("riding"))
		if not flying:
			var at: Array = respawn_nuees()
			main.place_player_v35(at[0], at[1])
			main._show_message_v28("Oups ! Le filet anti-chute de la Cité vous rattrape au vol et vous dépose doucement sur l'Esplanade. Plumeau vous tend un mouchoir : « Bonjour. Vous êtes tombé. Ça arrive. »")
		_last_safe_n = Vector3.ZERO

func _make_smoke(at: Vector3, col: Color, scale_k: float = 1.0) -> CPUParticles3D:
	var s := CPUParticles3D.new()
	s.name = "Fumee"
	s.amount = 10
	s.lifetime = 5.0
	s.emitting = true
	s.direction = Vector3(0.2, 1, 0.1)
	s.spread = 12.0
	s.initial_velocity_min = 0.5
	s.initial_velocity_max = 0.9
	s.gravity = Vector3(0.25, 0.12, 0.05)
	s.scale_amount_min = 0.6 * scale_k
	s.scale_amount_max = 1.4 * scale_k
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.3))
	curve.add_point(Vector2(1.0, 1.6))
	s.scale_amount_curve = curve
	var qm := QuadMesh.new()
	qm.size = Vector2(0.9, 0.9)
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	if main != null and main.has_method("_soft_dot_v24"):
		m.albedo_texture = main._soft_dot_v24()
	qm.material = m
	s.mesh = qm
	s.visibility_aabb = AABB(Vector3(-3, -1, -3), Vector3(6, 12, 6))
	s.visibility_range_end = 160.0
	add_child(s)
	s.position = at
	return s


func _make_fire(at: Vector3, s: float) -> Node3D:
	var root := Node3D.new()
	root.name = "Feu"
	add_child(root)
	root.position = at
	var p := CPUParticles3D.new()
	p.amount = int(22 * s) + 8
	p.lifetime = 0.8
	p.direction = Vector3.UP
	p.spread = 15.0
	p.initial_velocity_min = 0.6 * s
	p.initial_velocity_max = 1.4 * s
	p.gravity = Vector3(0, 1.2, 0)
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.2 * s
	p.scale_amount_min = 0.5 * s
	p.scale_amount_max = 1.0 * s
	var grad := Gradient.new()
	grad.set_color(0, Color(1.0, 0.85, 0.4, 1.0))
	grad.set_color(1, Color(0.9, 0.2, 0.05, 0.0))
	p.color_ramp = grad
	var qm := QuadMesh.new()
	qm.size = Vector2(0.35, 0.45)
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	if main != null and main.has_method("_soft_dot_v24"):
		m.albedo_texture = main._soft_dot_v24()
	qm.material = m
	p.mesh = qm
	p.visibility_aabb = AABB(Vector3(-2, -1, -2), Vector3(4, 5, 4))
	root.add_child(p)
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.6, 0.25)
	l.light_energy = 1.5 * s
	l.omni_range = 6.0 * s + 2.0
	l.shadow_enabled = false
	l.position = Vector3.UP * 0.4
	l.distance_fade_enabled = true
	l.distance_fade_begin = 60.0
	l.distance_fade_length = 12.0
	root.add_child(l)
	return root


# =================================================================== s'évanouir, carnet, sauvegarde

func owns_point(p: Vector3) -> bool:
	return contains(p) or in_strates(p) or in_dome(p)


func on_faint(_p: Vector3) -> void:
	if in_dome(_p):
		var at4: Array = respawn_dome()
		main.place_player_v35(at4[0], at4[1])
		main._show_message_v28("Vous vous êtes évanoui… On vous a porté jusqu'à la Fontaine des Bulles, et quelqu'un vous a apporté une limonade bleue de la Conque. Ça pétille !")
		return
	if in_strates(_p):
		var fr: bool = zone_at(_p).begins_with("fr_")
		var at3: Array = respawn_fronde() if fr else respawn_strates()
		main.place_player_v35(at3[0], at3[1])
		main._show_message_v28("Vous vous êtes évanoui… Gamelle vous a porté jusqu'à l'entrée de la Fronde et vous a fait avaler une louche de potée. Ça requinque !" if fr else "Vous vous êtes évanoui… Des mineurs vous ont porté jusqu'à la Gare des Strates, et Honorine vous a apporté un chocolat du mineur. Ça remonte !")
		return
	if on_nuees(_p):
		var at2: Array = respawn_nuees()
		main.place_player_v35(at2[0], at2[1])
		main._show_message_v28("Vous vous êtes évanoui… Plumeau, le robot jardinier, vous a porté jusqu'au miroir d'eau, et Gustave vous a apporté un lait de nuage. Ça plane !")
		return
	var at: Array = respawn_point()
	main.place_player_v35(at[0], at[1])
	main._show_message_v28("Vous vous êtes évanoui… Des passants vous ont porté jusqu'à la fontaine de Dame Ysolde, et Firmin vous a apporté un chocolat chaud. Ça remonte !")


func trouvailles() -> Dictionary:
	var vis: Dictionary = state["visites"]
	return {"hautefond": 1 if bool(state["visite"]) else 0, "hautefond_ville": 1 if bool(vis.get("ville", false)) else 0,
		"hautefond_belvedere": 1 if bool(vis.get("belvedere", false)) else 0, "hautefond_marche": 1 if bool(vis.get("marche", false)) else 0,
		"hautefond_port": 1 if bool(vis.get("port", false)) else 0, "hautefond_phare": 1 if bool(vis.get("phare", false)) else 0,
		"hautefond_moulin": 1 if bool(vis.get("moulin", false)) else 0, "hautefond_vergers": 1 if bool(vis.get("vergers", false)) else 0,
		"hautefond_falaises": 1 if bool(vis.get("falaises", false)) else 0, "hautefond_observatoire": 1 if bool(vis.get("observatoire", false)) else 0,
		"nuees": 1 if bool(state.get("nuees", false)) else 0, "nuees_belvedere": 1 if bool(vis.get("nu_belvedere", false)) else 0,
		"nuees_serres": 1 if bool(vis.get("nu_serres", false)) else 0, "nuees_institut": 1 if bool(vis.get("nu_institut", false)) else 0,
		"nuees_port": 1 if bool(vis.get("nu_port", false)) else 0, "nuees_parc": 1 if bool(vis.get("nu_parc", false)) else 0,
		"strates": 1 if bool(state.get("strates", false)) else 0, "strates_forge": 1 if bool(vis.get("st_forge", false)) else 0,
		"strates_mines": 1 if bool(vis.get("st_grotte", false)) else 0, "strates_jardins": 1 if bool(vis.get("st_jardins", false)) else 0,
		"strates_galeries": 1 if bool(vis.get("st_guilde", false)) or bool(vis.get("st_galeries", false)) else 0,
		"fronde": 1 if bool(state.get("fronde", false)) else 0, "fronde_scene": 1 if bool(vis.get("fr_scene", false)) else 0,
		"dome": 1 if bool(state.get("dome", false)) else 0, "dome_funiculaire": 1 if int(state.get("funiculaire", 0)) > 0 else 0,
		"dome_serres": 1 if bool(vis.get("da_serres", false)) else 0, "dome_institut": 1 if bool(vis.get("da_institut", false)) or bool(vis.get("da_aquarium", false)) else 0,
		"dome_belvedere": 1 if bool(vis.get("da_belvedere", false)) else 0, "dome_baleine": 1 if bool(state.get("baleine", false)) else 0}


func serialize() -> Dictionary:
	return state.duplicate(true)


func load_data(d: Dictionary) -> void:
	state = _fresh_state()
	for k in state:
		if d.has(k):
			state[k] = d[k] if not (d[k] is Dictionary) else (d[k] as Dictionary).duplicate(true)
	_claims.clear()
