extends SceneTree
## Extension « Le Château d'Ombrelac » (v14) : les corps des habitants de l'Académie. Comme les gens
## de Pile-ou-Face (V146) : chacun est un mélange de deux corps d'habitants déjà faits (V64) ; l'apparence
## (teint, cheveux, barbe, tenue) est choisie ici. Les élèves : la chemise blanche, le gilet et la cravate
## aux couleurs de leur dortoir (l'Aube : bleu et or ; le Crépuscule : pourpre et vieil or), la cape noire.
## Lancement (depuis la racine du dépôt, la copie de travail ayant les corps dans assets/) :
##     godot --headless --path pcvr -s res://tools/ext_chateau_habitants.gd -- <dossier www/assets/models/pnj64>

const Corps = preload("res://scripts/pnj/corps_v64.gd")

const GENS := {
	# Lison, de l'Aube : rousse, les tresses, curieuse de tout
	"lison_om": {"de": ["f81_arcanelle_1", "f81_montjoie_5"], "t": 0.55, "look": {"peau": [0.98, 0.86, 0.76], "rose": 0.7, "cheveux": [0.72, 0.28, 0.1], "poils": [0.72, 0.28, 0.1], "sourcils": [0.6, 0.24, 0.08], "iris": [0.3, 0.5, 0.28], "cheveux_style": "tresse", "barbe_style": "", "tenue": [{"v": "chemise_rentree", "c": [0.92, 0.9, 0.86], "tissu": "coton"}, {"v": "gilet", "c": [0.14, 0.14, 0.16], "c2": [0.2, 0.32, 0.62], "motif": 3, "echelle": 0.04, "tissu": "laine", "boutons": 1.0}, {"v": "jupe", "c": [0.16, 0.16, 0.18], "c2": [0.2, 0.32, 0.62], "motif": 2, "echelle": 0.06, "tissu": "laine"}, {"v": "collant", "c": [0.12, 0.12, 0.13], "tissu": "coton"}, {"v": "cravate", "c": [0.2, 0.32, 0.62], "c2": [0.85, 0.75, 0.4], "motif": 1, "echelle": 0.03, "tissu": "soie"}, {"v": "chaussures", "c": [0.08, 0.07, 0.07], "tissu": "cuir"}, {"v": "cape", "c": [0.08, 0.08, 0.1], "tissu": "laine"}]}},
	# Barnabé, de l'Aube : grand et maigre, les boucles brunes, toujours un livre
	"barnabe_om": {"de": ["f81_arcanelle_0", "f81_carene_4"], "t": 0.45, "look": {"peau": [0.9, 0.72, 0.58], "rose": 0.5, "cheveux": [0.3, 0.2, 0.12], "poils": [0.3, 0.2, 0.12], "sourcils": [0.26, 0.17, 0.1], "iris": [0.32, 0.2, 0.12], "cheveux_style": "boucles", "barbe_style": "", "tenue": [{"v": "chemise_rentree", "c": [0.92, 0.9, 0.86], "tissu": "coton"}, {"v": "gilet", "c": [0.14, 0.14, 0.16], "c2": [0.2, 0.32, 0.62], "motif": 3, "echelle": 0.04, "tissu": "laine", "boutons": 1.0}, {"v": "pantalon", "c": [0.16, 0.16, 0.18], "tissu": "laine"}, {"v": "cravate", "c": [0.2, 0.32, 0.62], "c2": [0.85, 0.75, 0.4], "motif": 1, "echelle": 0.03, "tissu": "soie"}, {"v": "chaussures", "c": [0.08, 0.07, 0.07], "tissu": "cuir"}, {"v": "cape", "c": [0.08, 0.08, 0.1], "tissu": "laine"}]}},
	# Nour, de l'Aube : les cheveux noirs au carré, la meilleure en astres
	"nour_om": {"de": ["f81_tazira_1", "f81_tazira_5"], "t": 0.5, "look": {"peau": [0.7, 0.5, 0.38], "rose": 0.45, "cheveux": [0.06, 0.05, 0.05], "poils": [0.06, 0.05, 0.05], "sourcils": [0.06, 0.05, 0.05], "iris": [0.3, 0.2, 0.12], "cheveux_style": "court_f", "barbe_style": "", "tenue": [{"v": "chemise_rentree", "c": [0.92, 0.9, 0.86], "tissu": "coton"}, {"v": "gilet", "c": [0.14, 0.14, 0.16], "c2": [0.2, 0.32, 0.62], "motif": 3, "echelle": 0.04, "tissu": "laine", "boutons": 1.0}, {"v": "jupe", "c": [0.16, 0.16, 0.18], "c2": [0.2, 0.32, 0.62], "motif": 2, "echelle": 0.06, "tissu": "laine"}, {"v": "collant", "c": [0.12, 0.12, 0.13], "tissu": "coton"}, {"v": "cravate", "c": [0.2, 0.32, 0.62], "c2": [0.85, 0.75, 0.4], "motif": 1, "echelle": 0.03, "tissu": "soie"}, {"v": "chaussures", "c": [0.08, 0.07, 0.07], "tissu": "cuir"}, {"v": "cape", "c": [0.08, 0.08, 0.1], "tissu": "laine"}]}},
	# Tobie, de l'Aube : petit, blond, rieur, les chaussettes dépareillées
	"tobie_om": {"de": ["f81_azur_0", "f81_azur_4"], "t": 0.6, "look": {"peau": [0.98, 0.86, 0.76], "rose": 0.75, "cheveux": [0.9, 0.78, 0.45], "poils": [0.9, 0.78, 0.45], "sourcils": [0.75, 0.62, 0.35], "iris": [0.35, 0.55, 0.75], "cheveux_style": "court", "barbe_style": "", "tenue": [{"v": "chemise_rentree", "c": [0.92, 0.9, 0.86], "tissu": "coton"}, {"v": "gilet", "c": [0.14, 0.14, 0.16], "c2": [0.2, 0.32, 0.62], "motif": 3, "echelle": 0.04, "tissu": "laine", "boutons": 1.0}, {"v": "pantalon", "c": [0.16, 0.16, 0.18], "tissu": "laine"}, {"v": "cravate", "c": [0.2, 0.32, 0.62], "c2": [0.85, 0.75, 0.4], "motif": 1, "echelle": 0.03, "tissu": "soie"}, {"v": "chaussures", "c": [0.08, 0.07, 0.07], "tissu": "cuir"}, {"v": "cape", "c": [0.08, 0.08, 0.1], "tissu": "laine"}]}},
	# Ombeline, du Crépuscule : les cheveux longs très noirs, sérieuse, préfète
	"ombeline_om": {"de": ["f81_montjoie_1", "f81_carene_5"], "t": 0.5, "look": {"peau": [0.96, 0.84, 0.76], "rose": 0.4, "cheveux": [0.05, 0.04, 0.05], "poils": [0.05, 0.04, 0.05], "sourcils": [0.05, 0.04, 0.05], "iris": [0.25, 0.45, 0.3], "cheveux_style": "long", "barbe_style": "", "tenue": [{"v": "chemise_rentree", "c": [0.92, 0.9, 0.86], "tissu": "coton"}, {"v": "gilet", "c": [0.14, 0.14, 0.16], "c2": [0.4, 0.12, 0.36], "motif": 3, "echelle": 0.04, "tissu": "laine", "boutons": 1.0}, {"v": "jupe", "c": [0.16, 0.16, 0.18], "c2": [0.4, 0.12, 0.36], "motif": 2, "echelle": 0.06, "tissu": "laine"}, {"v": "collant", "c": [0.12, 0.12, 0.13], "tissu": "coton"}, {"v": "cravate", "c": [0.4, 0.12, 0.36], "c2": [0.78, 0.62, 0.3], "motif": 1, "echelle": 0.03, "tissu": "soie"}, {"v": "chaussures", "c": [0.08, 0.07, 0.07], "tissu": "cuir"}, {"v": "cape", "c": [0.08, 0.08, 0.1], "tissu": "laine"}]}},
	# Anatole, du Crépuscule : roux, les taches de rousseur, le farceur
	"anatole_om": {"de": ["f81_boucan_0", "f81_boucan_4"], "t": 0.55, "look": {"peau": [0.98, 0.84, 0.74], "rose": 0.8, "cheveux": [0.78, 0.32, 0.1], "poils": [0.78, 0.32, 0.1], "sourcils": [0.6, 0.24, 0.08], "iris": [0.3, 0.5, 0.28], "cheveux_style": "court", "barbe_style": "", "tenue": [{"v": "chemise_rentree", "c": [0.92, 0.9, 0.86], "tissu": "coton"}, {"v": "gilet", "c": [0.14, 0.14, 0.16], "c2": [0.4, 0.12, 0.36], "motif": 3, "echelle": 0.04, "tissu": "laine", "boutons": 1.0}, {"v": "pantalon", "c": [0.16, 0.16, 0.18], "tissu": "laine"}, {"v": "cravate", "c": [0.4, 0.12, 0.36], "c2": [0.78, 0.62, 0.3], "motif": 1, "echelle": 0.03, "tissu": "soie"}, {"v": "chaussures", "c": [0.08, 0.07, 0.07], "tissu": "cuir"}, {"v": "cape", "c": [0.08, 0.08, 0.1], "tissu": "laine"}]}},
	# Sidonie, du Crépuscule : les boucles châtain, timide, douée pour les élixirs
	"sidonie_om": {"de": ["f81_azur_1", "f81_montjoie_5"], "t": 0.5, "look": {"peau": [0.92, 0.76, 0.62], "rose": 0.55, "cheveux": [0.42, 0.28, 0.16], "poils": [0.42, 0.28, 0.16], "sourcils": [0.36, 0.24, 0.14], "iris": [0.42, 0.3, 0.15], "cheveux_style": "boucles", "barbe_style": "", "tenue": [{"v": "chemise_rentree", "c": [0.92, 0.9, 0.86], "tissu": "coton"}, {"v": "gilet", "c": [0.14, 0.14, 0.16], "c2": [0.4, 0.12, 0.36], "motif": 3, "echelle": 0.04, "tissu": "laine", "boutons": 1.0}, {"v": "jupe", "c": [0.16, 0.16, 0.18], "c2": [0.4, 0.12, 0.36], "motif": 2, "echelle": 0.06, "tissu": "laine"}, {"v": "collant", "c": [0.12, 0.12, 0.13], "tissu": "coton"}, {"v": "cravate", "c": [0.4, 0.12, 0.36], "c2": [0.78, 0.62, 0.3], "motif": 1, "echelle": 0.03, "tissu": "soie"}, {"v": "chaussures", "c": [0.08, 0.07, 0.07], "tissu": "cuir"}, {"v": "cape", "c": [0.08, 0.08, 0.1], "tissu": "laine"}]}},
	# Malo, du Crépuscule : costaud, les cheveux en brosse, le sportif
	"malo_om": {"de": ["f81_carene_0", "f81_tazira_4"], "t": 0.5, "look": {"peau": [0.6, 0.42, 0.3], "rose": 0.4, "cheveux": [0.08, 0.06, 0.05], "poils": [0.08, 0.06, 0.05], "sourcils": [0.08, 0.06, 0.05], "iris": [0.3, 0.2, 0.12], "cheveux_style": "court", "barbe_style": "", "tenue": [{"v": "chemise_rentree", "c": [0.92, 0.9, 0.86], "tissu": "coton"}, {"v": "gilet", "c": [0.14, 0.14, 0.16], "c2": [0.4, 0.12, 0.36], "motif": 3, "echelle": 0.04, "tissu": "laine", "boutons": 1.0}, {"v": "pantalon", "c": [0.16, 0.16, 0.18], "tissu": "laine"}, {"v": "cravate", "c": [0.4, 0.12, 0.36], "c2": [0.78, 0.62, 0.3], "motif": 1, "echelle": 0.03, "tissu": "soie"}, {"v": "chaussures", "c": [0.08, 0.07, 0.07], "tissu": "cuir"}, {"v": "cape", "c": [0.08, 0.08, 0.1], "tissu": "laine"}]}},
	# la Rectrice Aldegonde Vespérine : grande, les cheveux d'argent en chignon, la robe bleu nuit, la cape brodée d'or
	"vesperine_om": {"de": ["archimage", "f81_carene_3"], "t": 0.35, "look": {"cheveux": [0.86, 0.86, 0.9], "poils": [0.86, 0.86, 0.9], "sourcils": [0.7, 0.7, 0.74], "iris": [0.35, 0.45, 0.7], "cheveux_style": "chignon", "barbe_style": "", "age": 0.85, "tenue": [{"v": "corsage_long", "c": [0.07, 0.08, 0.2], "tissu": "soie", "boutons": 1.0}, {"v": "jupe_longue", "c": [0.07, 0.08, 0.2], "tissu": "soie"}, {"v": "ceinture_ample", "c": [0.78, 0.62, 0.3], "tissu": "cuir"}, {"v": "chaussures", "c": [0.08, 0.07, 0.08], "tissu": "cuir"}, {"v": "cape", "c": [0.1, 0.12, 0.3], "c2": [0.8, 0.65, 0.3], "motif": 4, "echelle": 0.12, "tissu": "soie"}, {"v": "ch_sorcier", "c": [0.07, 0.08, 0.2], "tissu": "laine"}]}},
	# Maître Orbel Fauconnier, l'astronome : la barbe grise en pointe, la robe semée d'étoiles
	"fauconnier_om": {"de": ["f81_arcanelle_2", "f81_azur_2"], "t": 0.4, "look": {"cheveux": [0.62, 0.62, 0.6], "poils": [0.62, 0.62, 0.6], "sourcils": [0.5, 0.5, 0.5], "barbe": [0.62, 0.62, 0.6], "iris": [0.4, 0.5, 0.6], "cheveux_style": "court", "barbe_style": "barbe_longue", "tenue": [{"v": "djellaba_haut", "c": [0.1, 0.12, 0.3], "c2": [0.85, 0.78, 0.45], "motif": 5, "echelle": 0.09, "tissu": "laine"}, {"v": "djellaba_bas", "c": [0.1, 0.12, 0.3], "c2": [0.85, 0.78, 0.45], "motif": 5, "echelle": 0.09, "tissu": "laine"}, {"v": "pantalon", "c": [0.1, 0.1, 0.14], "tissu": "laine"}, {"v": "bottes", "c": [0.2, 0.13, 0.08], "tissu": "cuir"}, {"v": "ch_sorcier", "c": [0.1, 0.12, 0.3], "tissu": "laine"}]}},
	# Maîtresse Ysaure Alambic, des élixirs : ronde, joyeuse, le tablier de cuir taché de toutes les couleurs
	"alambic_om": {"de": ["f81_arcanelle_3", "f81_boucan_3"], "t": 0.45, "look": {"cheveux": [0.55, 0.3, 0.15], "poils": [0.55, 0.3, 0.15], "sourcils": [0.45, 0.25, 0.12], "iris": [0.3, 0.5, 0.28], "cheveux_style": "chignon", "barbe_style": "", "rose": 0.8, "tenue": [{"v": "corsage_long", "c": [0.22, 0.36, 0.2], "tissu": "laine"}, {"v": "jupe_longue", "c": [0.22, 0.36, 0.2], "tissu": "laine"}, {"v": "tablier_sur_longue", "c": [0.4, 0.26, 0.14], "tissu": "cuir"}, {"v": "chaussures", "c": [0.18, 0.1, 0.06], "tissu": "cuir"}, {"v": "ch_foulard_tete", "c": [0.75, 0.5, 0.15], "c2": [0.3, 0.5, 0.25], "motif": 4, "echelle": 0.04, "tissu": "coton"}]}},
	# Maître Théodore Équerre, de géométrie : sec, droit comme un compas, les lunettes rondes
	"equerre_om": {"de": ["f81_montjoie_2", "f81_arcanelle_6"], "t": 0.4, "look": {"cheveux": [0.4, 0.38, 0.36], "poils": [0.4, 0.38, 0.36], "sourcils": [0.3, 0.28, 0.26], "iris": [0.32, 0.2, 0.12], "cheveux_style": "court", "barbe_style": "barbe_moustache", "barbe": [0.4, 0.38, 0.36], "age": 0.6, "tenue": [{"v": "chemise_longue", "c": [0.9, 0.88, 0.84], "tissu": "lin"}, {"v": "veste", "c": [0.14, 0.14, 0.16], "tissu": "laine", "boutons": 1.0}, {"v": "pantalon", "c": [0.12, 0.12, 0.14], "tissu": "laine"}, {"v": "chaussures", "c": [0.06, 0.05, 0.05], "tissu": "cuir"}, {"v": "cape", "c": [0.12, 0.12, 0.14], "tissu": "laine"}, {"v": "cravate", "c": [0.4, 0.12, 0.36], "tissu": "soie"}]}},
	# Dame Brunehaut Sortelame, des sortilèges : athlétique, les cheveux courts gris fer, la cape rouge
	"sortelame_om": {"de": ["f81_tazira_7", "f81_carene_3"], "t": 0.4, "look": {"cheveux": [0.5, 0.5, 0.52], "poils": [0.5, 0.5, 0.52], "sourcils": [0.35, 0.35, 0.37], "iris": [0.4, 0.48, 0.55], "cheveux_style": "court_f", "barbe_style": "", "age": 0.55, "tenue": [{"v": "tunique_haut", "c": [0.2, 0.18, 0.2], "tissu": "cuir"}, {"v": "tunique_bas", "c": [0.2, 0.18, 0.2], "tissu": "cuir"}, {"v": "pantalon", "c": [0.14, 0.12, 0.12], "tissu": "toile"}, {"v": "bottes_hautes", "c": [0.2, 0.12, 0.07], "tissu": "cuir"}, {"v": "ceinture", "c": [0.15, 0.09, 0.05], "tissu": "cuir"}, {"v": "cape", "c": [0.55, 0.1, 0.08], "tissu": "laine"}]}},
	# Dame Clémence Reliure, la bibliothécaire : menue, les lunettes au bout du nez, le châle vert
	"reliure_om": {"de": ["f81_carene_3", "f81_tazira_3"], "t": 0.5, "look": {"cheveux": [0.85, 0.84, 0.82], "poils": [0.85, 0.84, 0.82], "sourcils": [0.7, 0.7, 0.68], "iris": [0.35, 0.5, 0.4], "cheveux_style": "chignon", "barbe_style": "", "tenue": [{"v": "corsage_long", "c": [0.3, 0.22, 0.16], "tissu": "laine", "boutons": 1.0}, {"v": "jupe_longue", "c": [0.24, 0.18, 0.14], "tissu": "laine"}, {"v": "chale", "c": [0.2, 0.36, 0.24], "tissu": "laine"}, {"v": "chaussures", "c": [0.1, 0.08, 0.07], "tissu": "cuir"}]}},
	# Maître Anselme Rouage, le gardien de l'horloge : petit, voûté, les favoris blancs, le tablier de cuir
	"rouage_om": {"de": ["f81_nain_1", "f81_arcanelle_2"], "t": 0.45, "look": {"cheveux": [0.9, 0.9, 0.88], "poils": [0.9, 0.9, 0.88], "sourcils": [0.85, 0.85, 0.82], "barbe": [0.9, 0.9, 0.88], "iris": [0.32, 0.2, 0.12], "cheveux_style": "court", "barbe_style": "barbe_courte", "age": 0.85, "tenue": [{"v": "chemise_rentree", "c": [0.82, 0.76, 0.62], "tissu": "lin"}, {"v": "gilet", "c": [0.3, 0.2, 0.12], "tissu": "cuir", "boutons": 1.0}, {"v": "pantalon", "c": [0.25, 0.22, 0.18], "tissu": "toile"}, {"v": "tablier", "c": [0.32, 0.2, 0.12], "tissu": "cuir"}, {"v": "chaussures", "c": [0.12, 0.08, 0.05], "tissu": "cuir"}, {"v": "ch_beret", "c": [0.2, 0.18, 0.16], "tissu": "laine"}]}},
	# Gaspard Herse, le portier : massif, la moustache noire, la veste de garde, le képi
	"herse_om": {"de": ["f81_boucan_6", "f81_montjoie_8"], "t": 0.5, "look": {"peau": [0.84, 0.64, 0.5], "cheveux": [0.08, 0.06, 0.05], "poils": [0.08, 0.06, 0.05], "sourcils": [0.08, 0.06, 0.05], "barbe": [0.08, 0.06, 0.05], "iris": [0.32, 0.2, 0.12], "cheveux_style": "court", "barbe_style": "barbe_moustache", "tenue": [{"v": "chemise_rentree", "c": [0.85, 0.82, 0.74], "tissu": "coton"}, {"v": "veste", "c": [0.12, 0.16, 0.32], "c2": [0.8, 0.65, 0.3], "motif": 3, "echelle": 0.05, "tissu": "laine", "boutons": 1.0}, {"v": "pantalon", "c": [0.1, 0.1, 0.14], "tissu": "laine"}, {"v": "bottes_hautes", "c": [0.08, 0.07, 0.07], "tissu": "cuir"}, {"v": "ceinture", "c": [0.1, 0.08, 0.06], "tissu": "cuir"}, {"v": "ch_kepi", "c": [0.12, 0.16, 0.32], "tissu": "laine"}]}},
	# Mère Roseline Fournil, l'intendante : les joues rouges, le foulard, le grand tablier blanc
	"fournil_om": {"de": ["f81_carene_3", "f81_boucan_1"], "t": 0.5, "look": {"peau": [0.96, 0.8, 0.68], "rose": 0.85, "cheveux": [0.55, 0.52, 0.5], "poils": [0.55, 0.52, 0.5], "sourcils": [0.45, 0.42, 0.4], "iris": [0.42, 0.3, 0.15], "cheveux_style": "chignon", "barbe_style": "", "tenue": [{"v": "corsage_long", "c": [0.5, 0.18, 0.14], "tissu": "coton"}, {"v": "jupe_longue", "c": [0.3, 0.2, 0.16], "tissu": "laine"}, {"v": "tablier_sur_longue", "c": [0.95, 0.94, 0.9], "tissu": "lin"}, {"v": "chaussures", "c": [0.12, 0.08, 0.05], "tissu": "cuir"}, {"v": "ch_foulard_tete", "c": [0.9, 0.88, 0.84], "tissu": "lin"}]}},
	# Firmin Buis, le jardinier : grand, la barbe brune en broussaille, le chapeau de paille, les bottes crottées
	"buis_om": {"de": ["f81_carene_2", "f81_boucan_0"], "t": 0.45, "look": {"peau": [0.82, 0.6, 0.44], "rose": 0.6, "cheveux": [0.36, 0.24, 0.14], "poils": [0.36, 0.24, 0.14], "sourcils": [0.3, 0.2, 0.12], "barbe": [0.36, 0.24, 0.14], "iris": [0.3, 0.45, 0.25], "cheveux_style": "court", "barbe_style": "barbe_longue", "age": 0.5, "tenue": [{"v": "chemise_rentree", "c": [0.6, 0.55, 0.4], "tissu": "lin"}, {"v": "pantalon", "c": [0.32, 0.28, 0.18], "tissu": "toile"}, {"v": "tablier_court", "c": [0.25, 0.32, 0.18], "tissu": "toile"}, {"v": "bottes", "c": [0.2, 0.14, 0.08], "tissu": "cuir"}, {"v": "ch_paille", "c": [0.8, 0.68, 0.4], "tissu": "paille"}]}},
}


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var out_dir: String = args[0] if args.size() > 0 else Corps.DIR
	for id in GENS:
		var g: Dictionary = GENS[id]
		var a: Dictionary = Corps.read_bin(Corps.DIR + str(g["de"][0]) + ".bin")
		var b: Dictionary = Corps.read_bin(Corps.DIR + str(g["de"][1]) + ".bin")
		if a.is_empty() or b.is_empty():
			push_error("Ombrelac : corps introuvable pour " + id)
			continue
		var t: float = float(g["t"])
		var d: Dictionary = {}
		d["dq"] = _blend_dq(a["dq"], b["dq"], t)
		d["nq"] = _blend_nq(a["nq"], b["nq"], t)
		d["rest"] = _blend_v3(a["rest"], b["rest"], t)
		d["joints"] = _blend_v3(a["joints"], b["joints"], t)
		d["motion_scale"] = lerpf(float(a["motion_scale"]), float(b["motion_scale"]), t)
		d["scale"] = lerpf(float(a.get("scale", 1.0)), float(b.get("scale", 1.0)), t)
		var look: Dictionary = _blend_any(a.get("look", {}), b.get("look", {}), t)
		for k in g["look"]:
			look[k] = g["look"][k]
		d["look"] = look
		_save(out_dir.path_join(id + ".bin"), d)
		print("Ombrelac : ", id, " (", g["de"][0], " + ", g["de"][1], ") hauteur ", snappedf(float(look.get("hauteur", 0.0)) * float(d["scale"]), 0.01), " m")
	quit()


## Les écarts des sommets : entiers 16 bits, les octets faibles des 3 n valeurs puis les forts.
func _blend_dq(a: PackedByteArray, b: PackedByteArray, t: float) -> PackedByteArray:
	var m: int = a.size() / 2
	var out := PackedByteArray()
	out.resize(a.size())
	for k in range(m):
		var va: int = a[k] | (a[m + k] << 8)
		var vb: int = b[k] | (b[m + k] << 8)
		if va >= 32768:
			va -= 65536
		if vb >= 32768:
			vb -= 65536
		var v: int = clampi(int(round(lerpf(float(va), float(vb), t))), -32767, 32767)
		if v < 0:
			v += 65536
		out[k] = v & 255
		out[m + k] = (v >> 8) & 255
	return out


## Les normales, en octaèdre sur 8 bits (x puis y).
func _blend_nq(a: PackedByteArray, b: PackedByteArray, t: float) -> PackedByteArray:
	var n: int = a.size() / 2
	var out := PackedByteArray()
	out.resize(a.size())
	for i in range(n):
		var na: Vector3 = _oct_dec(a[i], a[n + i])
		var nb: Vector3 = _oct_dec(b[i], b[n + i])
		var nn: Vector3 = na.lerp(nb, t)
		nn = nn.normalized() if nn.length() > 0.0001 else na
		var e: Vector2i = _oct_enc(nn)
		out[i] = e.x & 255
		out[n + i] = e.y & 255
	return out


func _oct_dec(a: int, b: int) -> Vector3:
	var ox: float = float(a - 256 if a > 127 else a) / 127.0
	var oy: float = float(b - 256 if b > 127 else b) / 127.0
	var z: float = 1.0 - absf(ox) - absf(oy)
	var x: float = ox
	var y: float = oy
	if z < 0.0:
		x = (1.0 - absf(oy)) * (1.0 if ox >= 0.0 else -1.0)
		y = (1.0 - absf(ox)) * (1.0 if oy >= 0.0 else -1.0)
	return Vector3(x, y, z).normalized()


func _oct_enc(nv: Vector3) -> Vector2i:
	var s: float = absf(nv.x) + absf(nv.y) + absf(nv.z) + 1e-12
	var x: float = nv.x / s
	var y: float = nv.y / s
	var z: float = nv.z / s
	var ox: float = x
	var oy: float = y
	if z < 0.0:
		ox = (1.0 - absf(y)) * (1.0 if x >= 0.0 else -1.0)
		oy = (1.0 - absf(x)) * (1.0 if y >= 0.0 else -1.0)
	var ix: int = clampi(int(round(ox * 127.0)), -127, 127)
	var iy: int = clampi(int(round(oy * 127.0)), -127, 127)
	return Vector2i(ix + 256 if ix < 0 else ix, iy + 256 if iy < 0 else iy)


func _blend_v3(a: PackedVector3Array, b: PackedVector3Array, t: float) -> PackedVector3Array:
	var out := PackedVector3Array()
	out.resize(a.size())
	for i in range(a.size()):
		out[i] = a[i].lerp(b[i], t)
	return out


## Les nombres (et les listes de nombres) se mélangent ; le reste vient du premier corps.
func _blend_any(a: Variant, b: Variant, t: float) -> Variant:
	if (a is float or a is int) and (b is float or b is int) and not (a is bool):
		return lerpf(float(a), float(b), t)
	if a is Array and b is Array and (a as Array).size() == (b as Array).size():
		var out: Array = []
		for i in range((a as Array).size()):
			out.append(_blend_any(a[i], b[i], t))
		return out
	if a is Dictionary and b is Dictionary:
		var d: Dictionary = {}
		for k in a:
			d[k] = _blend_any(a[k], b[k], t) if (b as Dictionary).has(k) else a[k]
		return d
	return a


func _save(path: String, d: Dictionary) -> void:
	var raw: PackedByteArray = var_to_bytes(d)
	var comp: PackedByteArray = raw.compress(FileAccess.COMPRESSION_DEFLATE)
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("Ombrelac : impossible d'écrire " + path)
		return
	f.store_buffer("IM64".to_ascii_buffer())
	f.store_32(raw.size())
	f.store_buffer(comp)
	f.close()
