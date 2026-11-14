extends SceneTree
## V142 : les corps des géants de l'Île des Géants (la famille Grandpré). Chacun est un mélange de
## deux corps d'habitants déjà faits (formes MakeHuman, V64) : la forme (sommets, normales, longueurs
## d'os, taille) est une moyenne pondérée des deux, ce qui donne un visage nouveau ; l'apparence (teint,
## cheveux, barbe, tenue) est choisie ici. Le géant lui-même est ce corps, agrandi par le jeu.
## Lancement (depuis la racine du dépôt, la copie de travail ayant les corps dans assets/) :
##     godot --headless --path pcvr -s res://tools/generate_geants_v142.gd -- <dossier www/assets/models/pnj64>

const Corps = preload("res://scripts/pnj/corps_v64.gd")

const GEANTS := {
	# Mère Mathurine, la fermière : solide, les joues roses, un foulard rouge, le tablier
	"mathurine_gt": {"de": ["f81_montjoie_1", "f81_boucan_9"], "t": 0.45, "look": {
		"peau": [0.9, 0.7, 0.57], "rose": 0.62, "age": 0.32, "cheveux": [0.5, 0.24, 0.12], "poils": [0.5, 0.24, 0.12], "sourcils": [0.4, 0.2, 0.1],
		"iris": [0.28, 0.45, 0.25], "levres": [0.74, 0.36, 0.33], "levres_force": 0.6, "fard_force": 0.0, "cheveux_style": "chignon", "barbe_style": "",
		"tenue": [{"v": "corsage_long", "c": [0.42, 0.55, 0.72], "tissu": "toile"}, {"v": "jupe_longue", "c": [0.36, 0.25, 0.17], "tissu": "laine"},
			{"v": "tablier_sur_longue", "c": [0.93, 0.9, 0.82], "tissu": "lin"}, {"v": "bottes", "c": [0.2, 0.28, 0.18], "tissu": "cuir"},
			{"v": "ch_foulard_tete", "c": [0.72, 0.12, 0.1], "tissu": "coton"}]}},
	# Père Eustache, le meunier : immense, la barbe en broussaille, enfariné
	"eustache_gt": {"de": ["f81_carene_0", "f81_yourte_rainville_0"], "t": 0.5, "look": {
		"peau": [0.86, 0.64, 0.5], "rose": 0.48, "age": 0.45, "cheveux": [0.42, 0.33, 0.25], "poils": [0.5, 0.42, 0.34], "sourcils": [0.36, 0.28, 0.2],
		"iris": [0.35, 0.25, 0.15], "barbe": [0.6, 0.6, 0.5], "cheveux_style": "court", "barbe_style": "barbe_longue",
		"tenue": [{"v": "chemise_longue", "c": [0.94, 0.92, 0.86], "tissu": "lin"}, {"v": "pantalon", "c": [0.42, 0.33, 0.22], "tissu": "toile"},
			{"v": "gilet", "c": [0.3, 0.24, 0.18], "tissu": "laine"}, {"v": "bottes", "c": [0.24, 0.16, 0.1], "tissu": "cuir"},
			{"v": "ceinture", "c": [0.2, 0.13, 0.08], "tissu": "cuir"}, {"v": "ch_bonnet", "c": [0.92, 0.9, 0.84], "tissu": "laine"}]}},
	# Grand-mère Ernestine : les cheveux blancs en chignon, le châle de laine, toujours à tricoter
	"ernestine_gt": {"de": ["f81_carene_3", "f81_boucan_3"], "t": 0.5, "look": {
		"peau": [0.92, 0.76, 0.66], "rose": 0.55, "cheveux": [0.94, 0.93, 0.9], "poils": [0.94, 0.93, 0.9], "sourcils": [0.82, 0.8, 0.78],
		"iris": [0.3, 0.42, 0.6], "levres": [0.7, 0.42, 0.4], "cheveux_style": "chignon", "barbe_style": "",
		"tenue": [{"v": "corsage_long", "c": [0.55, 0.45, 0.62], "tissu": "coton"}, {"v": "jupe_longue", "c": [0.3, 0.2, 0.3], "tissu": "laine"},
			{"v": "chale", "c": [0.9, 0.84, 0.7], "tissu": "laine"}, {"v": "chaussures", "c": [0.2, 0.14, 0.1], "tissu": "cuir"},
			{"v": "tablier_sur_longue", "c": [0.86, 0.8, 0.88], "tissu": "coton"}]}},
	# Pâquerette, sept ans : les tresses blondes, la robe jaune, les souliers rouges
	"paquerette_gt": {"de": ["f81_montjoie_5", "f81_carene_5"], "t": 0.5, "look": {
		"peau": [0.95, 0.78, 0.66], "rose": 0.7, "cheveux": [0.88, 0.7, 0.36], "poils": [0.88, 0.7, 0.36], "sourcils": [0.66, 0.5, 0.26],
		"iris": [0.25, 0.48, 0.75], "cheveux_style": "tresse", "barbe_style": "",
		"tenue": [{"v": "corsage", "c": [0.98, 0.8, 0.22], "tissu": "coton", "boutons": 1.0}, {"v": "jupe", "c": [0.98, 0.8, 0.22], "tissu": "coton"},
			{"v": "tablier_court_sur_jupe", "c": [0.96, 0.95, 0.92], "tissu": "lin"}, {"v": "chaussures", "c": [0.75, 0.12, 0.1], "tissu": "cuir"},
			{"v": "collant", "c": [0.94, 0.93, 0.9], "tissu": "coton"}]}},
	# Oncle Théophile, le jardinier : long et sec, le chapeau de paille, le tablier de jardin
	"theophile_gt": {"de": ["f81_tazira_6", "f81_azur_2"], "t": 0.45, "look": {
		"peau": [0.84, 0.6, 0.45], "rose": 0.42, "age": 0.55, "cheveux": [0.6, 0.58, 0.55], "poils": [0.55, 0.5, 0.45], "sourcils": [0.45, 0.4, 0.35],
		"iris": [0.4, 0.5, 0.3], "barbe": [0.5, 0.45, 0.3], "cheveux_style": "court", "barbe_style": "barbe_courte",
		"tenue": [{"v": "chemise_rentree", "c": [0.5, 0.62, 0.4], "tissu": "coton"}, {"v": "pantalon", "c": [0.2, 0.28, 0.42], "tissu": "jean"},
			{"v": "tablier", "c": [0.45, 0.36, 0.24], "tissu": "toile"}, {"v": "bottes", "c": [0.18, 0.24, 0.16], "tissu": "cuir"},
			{"v": "ch_paille", "c": [0.86, 0.74, 0.46], "tissu": "paille"}]}},
}


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var out_dir: String = args[0] if args.size() > 0 else Corps.DIR
	for id in GEANTS:
		var g: Dictionary = GEANTS[id]
		var a: Dictionary = Corps.read_bin(Corps.DIR + str(g["de"][0]) + ".bin")
		var b: Dictionary = Corps.read_bin(Corps.DIR + str(g["de"][1]) + ".bin")
		if a.is_empty() or b.is_empty():
			push_error("V142 : corps introuvable pour " + id)
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
		print("V142 : ", id, " (", g["de"][0], " + ", g["de"][1], ") hauteur ", snappedf(float(look.get("hauteur", 0.0)) * float(d["scale"]), 0.01), " m")
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
		push_error("V142 : impossible d'écrire " + path)
		return
	f.store_buffer("IM64".to_ascii_buffer())
	f.store_32(raw.size())
	f.store_buffer(comp)
	f.close()
