extends SceneTree
## V146 : les corps des habitants de Pile-ou-Face (l'Île Perchée). Comme les géants (V142) : chacun est un
## mélange de deux corps d'habitants déjà faits (formes MakeHuman, V64) ; l'apparence (teint, cheveux,
## barbe, tenue de Far West : gilets, cravates, bottes, stetsons de feutre, voilettes, tabliers de cuir) est
## choisie ici.
## Lancement (depuis la racine du dépôt, la copie de travail ayant les corps dans assets/) :
##     godot --headless --path pcvr -s res://tools/generate_perchee_v146.gd -- <dossier www/assets/models/pnj64>

const Corps = preload("res://scripts/pnj/corps_v64.gd")

const GENS := {
	# la Veuve Clou : petite, les cheveux blancs en chignon, tout en noir (le deuil), le châle violet
	"veuve_clou_pp": {"de": ["f81_carene_3", "f81_tazira_3"], "t": 0.5, "look": {
		"peau": [0.93, 0.8, 0.7], "rose": 0.45, "cheveux": [0.94, 0.93, 0.9], "poils": [0.94, 0.93, 0.9], "sourcils": [0.8, 0.78, 0.76],
		"iris": [0.42, 0.48, 0.55], "levres": [0.62, 0.38, 0.38], "cheveux_style": "chignon", "barbe_style": "",
		"tenue": [{"v": "corsage_long", "c": [0.08, 0.07, 0.08], "tissu": "soie", "boutons": 1.0}, {"v": "jupe_longue", "c": [0.09, 0.08, 0.09], "tissu": "laine"},
			{"v": "chale", "c": [0.36, 0.22, 0.42], "tissu": "laine"}, {"v": "chaussures", "c": [0.1, 0.08, 0.07], "tissu": "cuir"},
			{"v": "ch_capeline", "c": [0.07, 0.06, 0.07], "tissu": "soie"}]}},
	# Bartholomé, le patron du saloon : grand, la moustache cirée, le haut-de-forme, le gilet rouge
	"bartholome_pp": {"de": ["f81_carene_0", "f81_boucan_6"], "t": 0.5, "look": {
		"peau": [0.86, 0.66, 0.52], "rose": 0.5, "age": 0.3, "cheveux": [0.08, 0.06, 0.05], "poils": [0.08, 0.06, 0.05], "sourcils": [0.08, 0.06, 0.05],
		"iris": [0.32, 0.2, 0.12], "barbe": [0.08, 0.06, 0.05], "cheveux_style": "court", "barbe_style": "barbe_moustache",
		"tenue": [{"v": "chemise_longue", "c": [0.95, 0.94, 0.9], "tissu": "lin"}, {"v": "gilet", "c": [0.6, 0.1, 0.08], "c2": [0.8, 0.6, 0.2], "motif": 3, "echelle": 0.03, "tissu": "soie", "boutons": 1.0},
			{"v": "pantalon", "c": [0.12, 0.1, 0.1], "tissu": "laine"}, {"v": "bottes", "c": [0.15, 0.09, 0.05], "tissu": "cuir"},
			{"v": "cravate", "c": [0.08, 0.07, 0.07], "tissu": "soie"}, {"v": "ch_haut_de_forme", "c": [0.08, 0.07, 0.07], "tissu": "laine"}]}},
	# Madame Pique : tout en noir et rouge sombre, les cheveux longs, la capeline (la voilette)
	"dame_pique_pp": {"de": ["f81_montjoie_1", "f81_azur_1"], "t": 0.5, "look": {
		"peau": [0.97, 0.85, 0.76], "rose": 0.35, "cheveux": [0.06, 0.05, 0.05], "poils": [0.06, 0.05, 0.05], "sourcils": [0.06, 0.05, 0.05],
		"iris": [0.25, 0.5, 0.3], "levres": [0.55, 0.08, 0.12], "levres_force": 0.9, "fard_force": 0.4, "cheveux_style": "long", "barbe_style": "",
		"tenue": [{"v": "corsage_long", "c": [0.06, 0.05, 0.06], "tissu": "soie", "boutons": 1.0}, {"v": "jupe_longue", "c": [0.35, 0.04, 0.08], "tissu": "soie"},
			{"v": "chale", "c": [0.05, 0.04, 0.05], "tissu": "soie"}, {"v": "chaussures", "c": [0.06, 0.05, 0.05], "tissu": "cuir"},
			{"v": "ch_capeline", "c": [0.05, 0.04, 0.05], "tissu": "soie"}]}},
	# Cornélius « Grand-Dé » : petit, très large, roux, la barbe courte, la chemise à carreaux, le bandana
	"grand_de_pp": {"de": ["f81_nain_1", "f81_boucan_0"], "t": 0.45, "look": {
		"peau": [0.96, 0.8, 0.68], "rose": 0.75, "age": 0.35, "cheveux": [0.78, 0.3, 0.1], "poils": [0.78, 0.3, 0.1], "sourcils": [0.6, 0.24, 0.08],
		"iris": [0.25, 0.45, 0.7], "barbe": [0.75, 0.3, 0.1], "cheveux_style": "court", "barbe_style": "barbe_courte",
		"tenue": [{"v": "chemise_rentree", "c": [0.7, 0.12, 0.1], "c2": [0.9, 0.86, 0.76], "motif": 2, "echelle": 0.05, "tissu": "coton"},
			{"v": "pantalon", "c": [0.36, 0.24, 0.14], "tissu": "toile"}, {"v": "tablier_court", "c": [0.36, 0.22, 0.12], "tissu": "cuir"},
			{"v": "bottes", "c": [0.18, 0.1, 0.06], "tissu": "cuir"}, {"v": "ceinture", "c": [0.15, 0.09, 0.05], "tissu": "cuir"},
			{"v": "ch_bandana", "c": [0.18, 0.28, 0.6], "c2": [0.95, 0.95, 0.9], "motif": 4, "echelle": 0.03, "tissu": "coton"}]}},
	# Doc Cornemuse : long et maigre, la barbe blanche, la veste de tartan, le haut-de-forme vert
	"cornemuse_pp": {"de": ["f81_azur_2", "f81_pirate_2"], "t": 0.5, "look": {
		"peau": [0.95, 0.8, 0.7], "rose": 0.55, "age": 0.75, "cheveux": [0.92, 0.91, 0.88], "poils": [0.92, 0.91, 0.88], "sourcils": [0.85, 0.84, 0.8],
		"iris": [0.42, 0.48, 0.55], "barbe": [0.92, 0.91, 0.88], "cheveux_style": "court", "barbe_style": "barbe_longue",
		"tenue": [{"v": "chemise_longue", "c": [0.92, 0.9, 0.84], "tissu": "lin"}, {"v": "veste", "c": [0.18, 0.32, 0.22], "c2": [0.62, 0.12, 0.1], "motif": 6, "echelle": 0.08, "tissu": "laine"},
			{"v": "pantalon", "c": [0.2, 0.22, 0.2], "tissu": "laine"}, {"v": "chaussures", "c": [0.12, 0.08, 0.05], "tissu": "cuir"},
			{"v": "ch_haut_de_forme", "c": [0.18, 0.28, 0.2], "tissu": "laine"}]}},
	# la Shérif Plomb : la cuirasse d'acier (le gilet de métal), le foulard rouge, le feutre brun
	"sherif_plomb_pp": {"de": ["f81_tazira_7", "f81_montjoie_1"], "t": 0.5, "look": {
		"peau": [0.82, 0.6, 0.45], "rose": 0.4, "cheveux": [0.45, 0.3, 0.17], "poils": [0.45, 0.3, 0.17], "sourcils": [0.38, 0.25, 0.14],
		"iris": [0.32, 0.2, 0.12], "levres": [0.62, 0.36, 0.3], "cheveux_style": "queue", "barbe_style": "",
		"tenue": [{"v": "chemise_rentree", "c": [0.82, 0.78, 0.66], "tissu": "coton"}, {"v": "gilet", "c": [0.62, 0.64, 0.68], "tissu": "metal"},
			{"v": "pantalon", "c": [0.22, 0.28, 0.42], "tissu": "jean"}, {"v": "bottes_hautes", "c": [0.32, 0.2, 0.1], "tissu": "cuir"},
			{"v": "foulard", "c": [0.72, 0.12, 0.1], "tissu": "coton"}, {"v": "ceinture", "c": [0.25, 0.15, 0.08], "tissu": "cuir"},
			{"v": "ch_paille", "c": [0.42, 0.3, 0.18], "tissu": "laine"}]}},
	# Gédéon Tic, l'horloger : les boucles, le tablier de cuir, les lunettes d'aviateur (ses loupes)
	"gedeon_tic_pp": {"de": ["f81_montjoie_0", "f81_cliquetis_0"], "t": 0.5, "look": {
		"peau": [0.92, 0.72, 0.56], "rose": 0.5, "age": 0.2, "cheveux": [0.45, 0.3, 0.17], "poils": [0.45, 0.3, 0.17], "sourcils": [0.38, 0.25, 0.14],
		"iris": [0.3, 0.5, 0.28], "cheveux_style": "boucles", "barbe_style": "",
		"tenue": [{"v": "chemise_rentree", "c": [0.8, 0.72, 0.56], "tissu": "lin"}, {"v": "tablier", "c": [0.32, 0.2, 0.12], "tissu": "cuir"},
			{"v": "pantalon", "c": [0.3, 0.26, 0.2], "tissu": "toile"}, {"v": "chaussures", "c": [0.2, 0.12, 0.07], "tissu": "cuir"},
			{"v": "ch_casque_aviateur", "c": [0.42, 0.28, 0.15], "tissu": "cuir"}]}},
	# le vieil Abélard Pépite : la longue barbe grise, la chemise délavée, le feutre cabossé
	"pepite_pp": {"de": ["f81_carene_2", "f81_tazira_2"], "t": 0.5, "look": {
		"peau": [0.82, 0.6, 0.45], "rose": 0.55, "age": 0.85, "cheveux": [0.62, 0.6, 0.58], "poils": [0.7, 0.68, 0.64], "sourcils": [0.55, 0.53, 0.5],
		"iris": [0.25, 0.45, 0.7], "barbe": [0.7, 0.68, 0.64], "cheveux_style": "court", "barbe_style": "barbe_longue",
		"tenue": [{"v": "chemise_longue", "c": [0.62, 0.42, 0.28], "tissu": "toile"}, {"v": "pantalon", "c": [0.3, 0.34, 0.45], "tissu": "jean"},
			{"v": "gilet", "c": [0.35, 0.28, 0.2], "tissu": "laine"}, {"v": "bottes", "c": [0.3, 0.2, 0.12], "tissu": "cuir"},
			{"v": "ch_paille", "c": [0.5, 0.42, 0.3], "tissu": "laine"}]}},
	# Fanchon Fil-d'Or, la chapelière : les boucles roses, la jupe vert d'eau, la grande capeline orange
	"fanchon_pp": {"de": ["f81_azur_1", "f81_boucan_1"], "t": 0.5, "look": {
		"peau": [0.66, 0.46, 0.34], "rose": 0.5, "cheveux": [0.85, 0.35, 0.5], "poils": [0.85, 0.35, 0.5], "sourcils": [0.3, 0.18, 0.12],
		"iris": [0.3, 0.5, 0.28], "levres": [0.75, 0.3, 0.4], "levres_force": 0.7, "cheveux_style": "boucles", "barbe_style": "",
		"tenue": [{"v": "corsage", "c": [0.95, 0.85, 0.6], "tissu": "coton", "boutons": 1.0}, {"v": "jupe", "c": [0.3, 0.55, 0.5], "c2": [0.95, 0.9, 0.8], "motif": 3, "echelle": 0.06, "tissu": "coton"},
			{"v": "collant", "c": [0.95, 0.92, 0.88], "tissu": "coton"}, {"v": "chaussures", "c": [0.6, 0.15, 0.2], "tissu": "cuir"},
			{"v": "ch_capeline", "c": [0.92, 0.52, 0.18], "tissu": "paille"}]}},
	# Hilda Enclume, la forgeronne : immense, la tresse blonde, le tablier de cuir, le bandana rouge
	"hilda_pp": {"de": ["f81_boucan_8", "f81_montjoie_1"], "t": 0.4, "look": {
		"peau": [0.97, 0.82, 0.7], "rose": 0.65, "cheveux": [0.86, 0.68, 0.32], "poils": [0.86, 0.68, 0.32], "sourcils": [0.7, 0.52, 0.24],
		"iris": [0.25, 0.45, 0.7], "levres": [0.7, 0.4, 0.36], "cheveux_style": "tresse", "barbe_style": "",
		"tenue": [{"v": "chemise_courte", "c": [0.78, 0.74, 0.66], "tissu": "lin"}, {"v": "tablier", "c": [0.28, 0.17, 0.1], "tissu": "cuir"},
			{"v": "pantalon", "c": [0.25, 0.22, 0.2], "tissu": "toile"}, {"v": "bottes", "c": [0.15, 0.1, 0.07], "tissu": "cuir"},
			{"v": "ch_bandana", "c": [0.62, 0.1, 0.08], "tissu": "coton"}]}},
	# Rosemonde Confiture, l'épicière : ronde, le foulard framboise, le grand tablier blanc
	"rosemonde_pp": {"de": ["f81_tazira_1", "f81_boucan_1"], "t": 0.5, "look": {
		"peau": [0.5, 0.34, 0.24], "rose": 0.4, "cheveux": [0.12, 0.08, 0.06], "poils": [0.12, 0.08, 0.06], "sourcils": [0.1, 0.07, 0.05],
		"iris": [0.32, 0.2, 0.12], "levres": [0.5, 0.25, 0.25], "cheveux_style": "chignon", "barbe_style": "",
		"tenue": [{"v": "corsage_long", "c": [0.95, 0.86, 0.82], "tissu": "coton", "boutons": 1.0}, {"v": "jupe_longue", "c": [0.6, 0.22, 0.32], "c2": [0.95, 0.9, 0.85], "motif": 2, "echelle": 0.06, "tissu": "coton"},
			{"v": "tablier_sur_longue", "c": [0.96, 0.95, 0.9], "tissu": "lin"}, {"v": "chaussures", "c": [0.25, 0.15, 0.1], "tissu": "cuir"},
			{"v": "ch_foulard_tete", "c": [0.62, 0.2, 0.32], "tissu": "coton"}]}},
	# Pistache, dix ans, le crieur : roux, des taches de son, la casquette, les bretelles
	"pistache_pp": {"de": ["f81_montjoie_4", "f81_carene_4"], "t": 0.5, "look": {
		"peau": [0.98, 0.84, 0.74], "rose": 0.75, "cheveux": [0.8, 0.32, 0.1], "poils": [0.8, 0.32, 0.1], "sourcils": [0.65, 0.25, 0.08],
		"iris": [0.3, 0.5, 0.28], "cheveux_style": "court", "barbe_style": "",
		# (V186 : un enfant : la chemise sortie, ample sur les hanches)
		"tenue": [{"v": "chemise_courte", "c": [0.86, 0.82, 0.72], "tissu": "coton"}, {"v": "tunique_bas", "c": [0.86, 0.82, 0.72], "tissu": "coton"},
			{"v": "bermuda", "c": [0.4, 0.3, 0.2], "tissu": "toile"},
			{"v": "chaussures", "c": [0.3, 0.18, 0.1], "tissu": "cuir"}, {"v": "ch_casquette", "c": [0.42, 0.32, 0.2], "c2": [0.3, 0.22, 0.14], "motif": 2, "echelle": 0.03, "tissu": "laine"}]}},
	# Marius Maillon, le gardien de la Chaîne : vieux marin, la barbe grise, le pull bleu, le bonnet de marin
	"maillon_pp": {"de": ["f81_pirate_2", "f81_nain_0"], "t": 0.4, "look": {
		"peau": [0.86, 0.64, 0.5], "rose": 0.6, "age": 0.75, "cheveux": [0.6, 0.6, 0.58], "poils": [0.66, 0.66, 0.62], "sourcils": [0.55, 0.55, 0.52],
		"iris": [0.42, 0.48, 0.55], "barbe": [0.66, 0.66, 0.62], "cheveux_style": "court", "barbe_style": "barbe_longue",
		"tenue": [{"v": "pull", "c": [0.18, 0.22, 0.34], "tissu": "laine"}, {"v": "pantalon", "c": [0.15, 0.17, 0.25], "tissu": "laine"},
			{"v": "bottes", "c": [0.1, 0.09, 0.08], "tissu": "cuir"}, {"v": "ch_marin", "c": [0.14, 0.18, 0.3], "tissu": "laine"}]}},
	# Zoé Nuée, l'aviatrice : la veste de cuir, l'écharpe blanche, le casque à lunettes
	"zoe_pp": {"de": ["f81_tazira_7", "f81_azur_1"], "t": 0.5, "look": {
		"peau": [0.66, 0.46, 0.34], "rose": 0.45, "cheveux": [0.08, 0.06, 0.05], "poils": [0.08, 0.06, 0.05], "sourcils": [0.08, 0.06, 0.05],
		"iris": [0.32, 0.2, 0.12], "levres": [0.6, 0.32, 0.3], "cheveux_style": "court_f", "barbe_style": "",
		"tenue": [{"v": "chemise_rentree", "c": [0.9, 0.88, 0.82], "tissu": "coton"}, {"v": "veste", "c": [0.42, 0.26, 0.14], "tissu": "cuir"},
			{"v": "pantalon", "c": [0.4, 0.36, 0.26], "tissu": "toile"}, {"v": "bottes_hautes", "c": [0.2, 0.12, 0.07], "tissu": "cuir"},
			{"v": "echarpe", "c": [0.96, 0.95, 0.92], "tissu": "soie"}, {"v": "ch_casque_aviateur", "c": [0.38, 0.24, 0.12], "tissu": "cuir"}]}},
}


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var out_dir: String = args[0] if args.size() > 0 else Corps.DIR
	for id in GENS:
		var g: Dictionary = GENS[id]
		var a: Dictionary = Corps.read_bin(Corps.DIR + str(g["de"][0]) + ".bin")
		var b: Dictionary = Corps.read_bin(Corps.DIR + str(g["de"][1]) + ".bin")
		if a.is_empty() or b.is_empty():
			push_error("V146 : corps introuvable pour " + id)
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
		print("V146 : ", id, " (", g["de"][0], " + ", g["de"][1], ") hauteur ", snappedf(float(look.get("hauteur", 0.0)) * float(d["scale"]), 0.01), " m")
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
		push_error("V146 : impossible d'écrire " + path)
		return
	f.store_buffer("IM64".to_ascii_buffer())
	f.store_32(raw.size())
	f.store_buffer(comp)
	f.close()
