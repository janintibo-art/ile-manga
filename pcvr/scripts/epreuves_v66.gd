extends RefCounted
## V66 : les épreuves du jeu et ce qu'elles rapportent (l'évolution du héros passe par elles).
## Chaque épreuve est une « trouvaille » que le jeu suit déjà (main._npc_ctx_v31().trouvailles) :
## une énigme résolue, un boss vaincu, une porte ouverte, un lieu atteint. On y ajoute les quêtes
## du carnet, les quêtes des habitants et les coffres cachés.
## Le rythme est lent : finir tout ce qui existe aujourd'hui mène autour du niveau 13 sur 30.

## clé -> [nom, région, expérience]
const LISTE := {
	# --- l'île du village et la jungle
	"mouette": ["Le coffre de la Mouette", "village", 40],
	"trappe_village": ["La trappe du village", "village", 20],
	"trappe_jungle": ["La trappe de la jungle", "village", 20],
	"temple": ["Le temple englouti", "village", 30],
	"braseros": ["L'énigme des braseros", "village", 50],
	"fragment": ["Le premier fragment d'amulette", "village", 30],
	"grille": ["Les gardiens de corail", "village", 50],
	"tunnel": ["L'éboulement dégagé", "village", 25],
	"boss1": ["Le crabe géant", "village", 120],
	"serpents": ["L'énigme des serpents", "village", 60],
	"fragment3": ["Le dernier fragment", "village", 30],
	"porte_serpent": ["La porte du Serpent", "village", 40],
	"abysses": ["Le sceau des abysses", "village", 60],
	"lac": ["Le lac souterrain", "village", 40],
	"abime": ["L'abîme", "village", 60],
	"naga": ["Nâga, le Serpent des Abysses", "village", 200],
	"quete_elfe": ["La rencontre de Lyra", "village", 10],
	"arbre_sacre": ["L'Arbre sacré guéri", "village", 100],
	# --- le Bois-Doré et le Royaume des Racines
	"ile_elfes": ["Le Bois-Doré", "elfes", 20],
	"porte_racines": ["La porte des Racines", "elfes", 50],
	"royaume": ["Le Royaume des Racines", "elfes", 20],
	"prismes": ["L'énigme des prismes", "elfes", 60],
	"clochettes": ["L'air des clochettes", "elfes", 50],
	"village_fees": ["Le village des fées", "elfes", 20],
	"baguette": ["La baguette retrouvée", "elfes", 40],
	"ronces": ["Les ronces écartées", "elfes", 60],
	"reine": ["La Reine des Ronces", "elfes", 180],
	"carte_naine": ["La carte d'Églantine", "elfes", 30],
	# --- la Montagne de Feu
	"ile_nains": ["La Montagne de Feu", "nains", 20],
	"porte_forgefer": ["La porte de Forgefer", "nains", 60],
	"ville_naine": ["Forgefer, la cité sous la montagne", "nains", 30],
	"nains_aides_3": ["Ami des nains", "nains", 50],
	# --- le ciel
	"ventaile": ["Ventaile apprivoisé", "ciel", 80],
	"citadelle": ["La Citadelle des Nuées", "ciel", 40],
	"orage": ["Sire Orage", "ciel", 200],
	# --- la mer et l'Atlantide
	"masque": ["Le masque de plongée", "mer", 20],
	"atlantide": ["L'Atlantide", "mer", 40],
	"perles_1": ["La première Perle de Lumière", "mer", 40],
	"perles_3": ["Les trois Perles de Lumière", "mer", 80],
	"cristal": ["Le Grand Cristal rallumé", "mer", 120],
	# --- Port-Azur
	"azur": ["Port-Azur", "azur", 20],
	# --- le royaume des fées d'Yggdrasil
	"champignon": ["Le champignon de Lulu", "fees", 10],
	"royaume_fees": ["Le royaume des fées", "fees", 30],
	"porte_ygg": ["La porte d'Yggdrasil", "fees", 30],
	"lucioles": ["La salle des Lucioles", "fees", 60],
	"seve": ["La salle de la Sève", "fees", 60],
	"saisons": ["La salle des Saisons", "fees", 60],
	"mere_ronce": ["La Mère-Ronce", "fees", 180],
	"graine_ygg": ["La graine d'Yggdrasil", "fees", 60],
	# --- la grande île de l'est
	"grande_ile": ["La grande île", "grande", 20],
	"porte_sceaux": ["La Porte aux Quatre Sceaux", "grande", 30],
	"tazira": ["Tazira", "grande", 15],
	"tazira_fete": ["La fête de Tazira", "grande", 20],
	"cliquetis": ["Cliquetis", "grande", 15],
	"zephyr": ["Le voyage en Zéphyr", "grande", 20],
	"telepherique": ["Le téléphérique", "grande", 15],
	"ramure": ["Ramure", "grande", 15],
	"fete_lune": ["La fête de la lune", "grande", 20],
	"course_ramure": ["La Grande Course", "grande", 30],
	"nacelle": ["La nacelle de Bourru", "grande", 10],
	"tyrolienne": ["La tyrolienne", "grande", 15],
	"journal_lu": ["Le journal du Léviathan", "grande", 30],
	"tombeau_dune": ["Le tombeau des dunes", "grande", 50],
	"bergerie_vent": ["La bergerie du vent", "grande", 50],
	"sceau_embruns": ["Le Sceau des Embruns", "grande", 120],
	"sceau_sables": ["Le Sceau des Sables", "grande", 120],
	"sceau_airain": ["Le Sceau d'Airain", "grande", 120],
	"sceau_brumes": ["Le Sceau des Brumes", "grande", 120],
	"porte_ouverte": ["La Porte aux Quatre Sceaux ouverte", "grande", 150],
	"entree_coeur": ["Le Cœur-de-Pierre", "grande", 30],
	"aile_marees": ["L'aile des Marées", "grande", 100],
	"aile_sables": ["L'aile des Sables", "grande", 100],
	"aile_rouages": ["L'aile des Rouages", "grande", 100],
	"aile_lune": ["L'aile de la Lune", "grande", 100],
	"coeur_ouvert": ["Le cœur de la montagne", "grande", 60],
	"gardien_coeur": ["Le Gardien du Cœur", "grande", 300],
	# --- V67 : Arcanelle, l'île des sorciers
	"arcanelle": ["Arcanelle", "arcanelle", 20],
	"sort_lumiere": ["Le sort de lumière", "arcanelle", 35],
	"sort_feu": ["Le sort de feu", "arcanelle", 35],
	"sort_gel": ["Le sort de gel", "arcanelle", 35],
	"sort_levitation": ["Le sort de lévitation", "arcanelle", 35],
	"sort_telekinesie": ["Le sort de télékinésie", "arcanelle", 35],
	"sort_soin": ["Le sort de soin", "arcanelle", 35],
	"cloche_tour": ["La cloche de la Tour Penchée", "arcanelle", 20],
	"ceremonie": ["La cérémonie des Pierres-Lunes", "arcanelle", 80],
	# --- V68 : l'Île de la Balafre, Port-Coutelas et ses pirates
	"balafre": ["L'Île de la Balafre", "balafre", 20],
	"bagarre_gagnee": ["Une bagarre gagnée", "balafre", 25],
	"champion_1": ["Un champion du port au tapis", "balafre", 25],
	"champions_3": ["Les trois champions au tapis", "balafre", 60],
	"perroquet_trouve": ["Rhubarbe retrouvé", "balafre", 20],
	"tatouage": ["Le tatouage de Coralie", "balafre", 10],
	"vieille_dent": ["Vieille-Dent", "balafre", 120],
	"capitaine_os": ["Le Capitaine Sans-Chair", "balafre", 200],
	"tresor_crane": ["Le trésor de Barbe-Sanglante", "balafre", 80],
	# --- V69 : l'Île des Trois Soleils et ses trois grands donjons
	"soleils": ["L'Île des Trois Soleils", "soleils", 20],
	"sphinx": ["Les trois questions du Sphinx", "soleils", 40],
	"chat_trouve": ["Miou retrouvé", "soleils", 15],
	"apophis": ["Apophis, le serpent du chaos", "soleils", 150],
	"pyramide": ["L'Œil d'Horus", "soleils", 60],
	"calendrier": ["La date de la création du monde", "soleils", 30],
	"camazotz": ["Camazotz, la chauve-souris de la mort", "soleils", 150],
	"xibalba": ["Le Masque de Jade", "soleils", 60],
	"offrandes": ["Les offrandes du Grand Temple", "soleils", 20],
	"cipactli": ["Cipactli, le monstre de la Terre", "soleils", 150],
	"cinq_soleils": ["La Plume de Quetzalcóatl", "soleils", 60],
	"jaguars_volcan": ["Les jaguars du Mont Fumant", "soleils", 40],
	"trois_soleils": ["L'Autel des Trois Soleils", "soleils", 120],
	# --- V70 : l'Île de Braise, Pandémonia la cité des démons gentils, et les Neuf Cercles
	"braise": ["L'Île de Braise", "braise", 20],
	"pandemonia": ["Pandémonia, la cité des démons", "braise", 20],
	"coeur_vif": ["Le Cœur du Volcan rallumé", "braise", 60],
	"porte_cercles": ["La porte des Neuf Cercles", "braise", 20],
	"miroirs_limbes": ["Les miroirs des Limbes", "braise", 30],
	"minos": ["Les questions du juge Minos", "braise", 30],
	"cerbere": ["Cerbère endormi", "braise", 80],
	"poids_avares": ["Les poids des Avares", "braise", 30],
	"porte_dite": ["La porte de Dité", "braise", 40],
	"cercles": ["La Flamme Éternelle", "braise", 60],
	"titan_givre": ["Le Titan de Givre", "braise", 200],
	"chiens_champ": ["Les chiens du Champ de Lave", "braise", 40],
	"gargouilles_ruines": ["Les gargouilles des ruines", "braise", 40],
	"pepin_trouve": ["Pépin retrouvé", "braise", 15],
	"fusees_pretes": ["Les fusées de la fête", "braise", 20],
	"arene_manche_1": ["Une manche de l'Arène gagnée", "braise", 25],
	"tournoi": ["Champion de l'Arène", "braise", 120],
	"sept_lanternes": ["Les sept lanternes allumées", "braise", 30],
	"fete_lanternes": ["La Fête des Lanternes", "braise", 60],
	# --- V71 : l'Île de Montjoie, la Guilde des Aventuriers et le Donjon des Mille Marches
	"montjoie": ["L'Île de Montjoie", "montjoie", 20],
	"montjoie_ville": ["Montjoie, la ville sur la Butte", "montjoie", 20],
	"inscription": ["Inscrit à la Guilde des Aventuriers", "montjoie", 20],
	"compagnon": ["Un compagnon d'aventure", "montjoie", 30],
	"rang_d": ["Aventurier de rang D", "montjoie", 60],
	"rang_s": ["Aventurier de rang S, légende de la Guilde", "montjoie", 250],
	"slimes_pres": ["Les slimes des prés", "montjoie", 20],
	"grenouilles_lac": ["Les grenouilles du lac", "montjoie", 40],
	"chef_gobelin": ["Le chef gobelin", "montjoie", 60],
	"alerte_navets": ["La grande alerte aux navets", "montjoie", 20],
	"navets_5": ["Cinq navets en une alerte", "montjoie", 30],
	"avale_grenouille": ["Avalé par une grenouille (et recraché)", "montjoie", 15],
	"chaumiere": ["Une maison à soi : la Chaumière des Glycines", "montjoie", 60],
	"donjon_5": ["Le cinquième étage des Mille Marches", "montjoie", 80],
	"roi_gelatineux": ["Le Roi Gélatineux", "montjoie", 200],
	"mille_marches": ["Le Donjon des Mille Marches", "montjoie", 60],
	# V75 : l'Île du Boucan
	"boucan": ["L'Île du Boucan", "boucan", 20],
	# V87 : l'Île aux Moaïs
	"moai": ["L'Île aux Moaïs", "moai", 20],
	"moai_plateau": ["Le Plateau des Anciens et le Grand Moaï", "moai", 20],
	"moai_lac": ["Le Cratère du Lac", "moai", 20],
	"moai_carriere": ["La Butte de la Carrière", "moai", 20],
	"moai_blagues": ["Cinq blagues des petits Moaïs", "moai", 30],
	"moai_legende": ["La légende des yeux du Grand Moaï", "moai", 30],
	"moai_yeux": ["Les deux yeux de corail du Grand Moaï", "moai", 40],
	"moai_souterrain": ["L'escalier du Grand Moaï", "moai", 30],
	"moai_tresor": ["Le Cœur du Chant", "moai", 60],
	"pixel": ["L'Île Pixelithique", "pixel", 20],
	"pixel_clan": ["La rencontre avec le Clan", "pixel", 20],
	"pixel_volcan": ["Le Mont Fumant", "pixel", 20],
	"pixel_lac": ["Le Lac des Long-Cous", "pixel", 20],
	"pixel_cirque": ["Le Cirque des Os", "pixel", 20],
	"pixel_grottes": ["Les deux grottes du Clan", "pixel", 30],
	"pixel_portrait": ["Ton portrait par Ocre", "pixel", 30],
	"pixel_danse": ["La danse autour du feu", "pixel", 20],
	"pixel_trex": ["Grosse-Dent, vaincu", "pixel", 80],
	"boucan_ville": ["Port-Boucan, la ville libre", "boucan", 20],
	"boucan_concert": ["Un pogo à la Halle Hurlante", "boucan", 25],
	"boucan_champignon": ["Un champignon féerique", "boucan", 20],
	"champignons_5": ["Les cinq champignons féeriques", "boucan", 40],
	"sardine_trouvee": ["Sardine, le chien au bandana rouge", "boucan", 30],
	"grand_boucan": ["Le Grand Boucan", "boucan", 60],
	"graffitis_3": ["Trois graffitis sur les murs du Boucan", "boucan", 30],
	"descente_repoussee": ["La Descente des Déménageurs repoussée", "boucan", 60],
	"champignard_roi": ["Le Roi des Champignards", "boucan", 60],
	"robots_usine": ["Les robots de la cour de l'usine", "boucan", 30],
	"usine_5": ["Le cinquième étage de l'Usine Grise", "boucan", 80],
	"grande_pelleteuse": ["La Grande Pelleteuse", "boucan", 200],
	"usine_grise": ["L'Usine Grise", "boucan", 60],
	"gedeon_batteur": ["Un batteur pour les Rats de Cale", "boucan", 60],
	# V76 : Astralys, les compagnons, le chantier naval, l'aéronef
	"astralys": ["Astralys, l'île flottante des Lumens", "astralys", 30],
	"astralys_ville": ["La cité de cristal", "astralys", 20],
	"rayon_accueil": ["Le Rayon d'accueil", "astralys", 15],
	"aurores": ["La Nuit des Aurores", "astralys", 20],
	"apesanteur_record": ["Les sept anneaux des apesanteurs", "astralys", 40],
	"cache_cache_trouves": ["Pixel et Quark retrouvés", "astralys", 25],
	"meduse_rendue": ["La méduse de ciel ramenée à la Serre", "astralys", 30],
	"course_comete": ["La course de Comète", "astralys", 60],
	"fleche_coeur": ["Le Cœur de la Flèche", "astralys", 150],
	"brioche_adoptee": ["Brioche, la chatte", "compagnons", 30],
	"biscotte_adoptee": ["Biscotte, le rat", "compagnons", 30],
	"truffe_adoptee": ["Truffe, le cochon", "compagnons", 30],
	"compagnons_4": ["Les quatre compagnons", "compagnons", 80],
	"glisseur": ["Aux commandes du Glisseur stellaire", "astralys", 40],
	"bateau_sloop": ["Le sloop", "compagnons", 30],
	"bateau_goelette": ["La goélette", "compagnons", 50],
	"bateau_vapeur": ["Le moteur à vapeur", "compagnons", 40],
	"bateau_cristal": ["Le moteur à cristal", "compagnons", 60],
	"bateau_complet": ["Un bateau tout équipé", "compagnons", 80],
	"atelier_ailes": ["L'Atelier des Ailes", "grande", 15],
	"aeronef_1": ["L'Alouette", "compagnons", 30],
	"aeronef_2": ["L'Alouette à hélice", "compagnons", 40],
	"aeronef_3": ["L'Albatros", "compagnons", 60],
	"aeronef_4": ["Le Glisseur stellaire", "compagnons", 80],
	"vol_haut": ["Plus haut que les nuages (250 m)", "compagnons", 30],
}

## Compteurs : une première fois, puis un peu à chaque pas (pas les monstres : ils rapportent
## en tombant ; pas les nains aidés : leurs quêtes rapportent déjà).
const COMPTEURS := {
	"tresors": ["Chasseur de trésors", "village", 15, 4],
	"arbres": ["Bûcheron", "village", 10, 1],
	"esprits": ["Les esprits-lucioles", "elfes", 15, 8],
	"trocs": ["Le Grand Troc", "grande", 10, 3],
	"requins": ["Les requins repoussés", "mer", 15, 6],
}
## Trouvailles qui ne rapportent rien par elles-mêmes (une quête le fait déjà, ou rien à gagner).
const SANS_XP := ["monstres", "nains_aides", "bague_caelan", "baguette_rendue", "rosee_rendue", "palmes", "teleportation",
	"lecon_lumiere", "lecon_feu", "lecon_gel", "lecon_levitation", "lecon_telekinesie", "lecon_soin", "six_sorts"]
## Une trouvaille inconnue de la liste (une nouveauté) : un petit quelque chose.
const XP_INCONNUE: int = 10

const REGIONS := [["village", "L'île du village et la jungle"], ["elfes", "Le Bois-Doré et les Racines"], ["nains", "La Montagne de Feu"],
	["ciel", "Le ciel"], ["mer", "La mer et l'Atlantide"], ["azur", "Port-Azur"], ["fees", "Le royaume des fées"], ["grande", "La grande île de l'est"],
	["arcanelle", "Arcanelle, l'île des sorciers"], ["balafre", "L'Île de la Balafre"], ["soleils", "L'Île des Trois Soleils"], ["braise", "L'Île de Braise"], ["montjoie", "L'Île de Montjoie"], ["boucan", "L'Île du Boucan"], ["astralys", "Astralys, l'île flottante"], ["moai", "L'Île aux Moaïs"], ["pixel", "L'Île Pixelithique"], ["compagnons", "Les compagnons et les voyages"]]

## Quêtes des habitants (leur cerveau) : région et expérience (les autres : 50).
const QUETES_PNJ := {
	"barnabe": ["village", 50], "octave": ["village", 40], "lyra": ["village", 60],
	"aelwen": ["elfes", 40], "sylwen": ["elfes", 40], "thalion": ["elfes", 40], "nimiel": ["elfes", 40], "caelan": ["elfes", 50], "ilyria": ["elfes", 50],
	"brindille": ["elfes", 40], "pimprenelle": ["elfes", 50], "grommelot": ["elfes", 50],
	"bramm": ["nains", 50], "borin": ["nains", 50], "dagna": ["nains", 40], "grimli": ["nains", 60], "hilda": ["nains", 40], "ulfa": ["nains", 40], "nori": ["nains", 50],
	"nerea": ["mer", 80], "coralin": ["mer", 50],
}

## Les quêtes du carnet par région, d'après le début de leur lieu (décompte de la page Héros).
const REGION_CARNET := {"Port-Azur": "azur", "Le royaume des fées": "fees", "Carène": "grande", "Tazira": "grande", "Cliquetis": "grande", "Ramure": "grande", "Arcanelle": "arcanelle", "La Balafre": "balafre", "Trois Soleils": "soleils", "Île de Braise": "braise", "Île de Montjoie": "montjoie", "Île du Boucan": "boucan", "Astralys": "astralys"}

## Expérience d'un coffre ouvert.
const XP_COFFRE: int = 15


static func nom(key: String) -> String:
	if LISTE.has(key):
		return str(LISTE[key][0])
	if COMPTEURS.has(key):
		return str(COMPTEURS[key][0])
	return key


static func carnet_region(lieu: String) -> String:
	for k in REGION_CARNET:
		if lieu.begins_with(str(k)):
			return str(REGION_CARNET[k])
	return ""


static func region_nom(r: String) -> String:
	for e in REGIONS:
		if str(e[0]) == r:
			return str(e[1])
	return r
