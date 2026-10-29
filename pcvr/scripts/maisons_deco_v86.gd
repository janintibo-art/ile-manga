extends RefCounted
## V86 : l'habillage des maisons. Une fois l'histoire de la maison installée, on remplit ce qui
## reste de place : des objets du quotidien (portemanteau, panier à linge, bûches, plante,
## horloge, miroir, cadres, casseroles, herbes qui sèchent…) et ceux de la ville (le rouet de
## Montjoie, les poufs et la lanterne ajourée de Tazira, la barre de navire des pirates, la
## bouée de Carène, le chaudron d'Arcanelle, l'enclume des nains…). Toujours les mêmes pour une
## maison donnée. Et selon la date du vrai calendrier : des citrouilles fin octobre, un sapin et
## une couronne en décembre.
## On évite les meubles déjà posés (R.is_free), les murs déjà pris (fenêtres, tableaux), les
## habitants, les endroits où l'on appuie sur E et le passage de la porte.

const Iles = preload("res://scripts/maisons_iles_v82.gd")
const Echoppes = preload("res://scripts/maisons_echoppes_v85.gd")

## Les histoires qui ont tout leur décor à elles (rien à ajouter).
const RIEN := ["envers", "abandon", "fantome", "apesanteur", "fee"]
## Celles où le sol est déjà occupé par l'histoire : seulement les murs et le plafond.
const LEGER := ["chats", "cache_cache", "travaux", "surprise", "coucou", "sportif", "boutique"]

## Au sol, contre un mur : [nom, largeur, profondeur]
const SOL := [["porte_manteau", 0.5, 0.5], ["panier", 0.5, 0.45], ["bois_feu", 0.95, 0.45], ["plante_haute", 0.6, 0.6],
	["coffre", 1.0, 0.7], ["seau_balai", 0.5, 0.45], ["gueridon", 0.6, 0.6], ["bottes", 0.55, 0.4], ["caisses", 0.8, 0.7]]
const SOL_VILLE := {
	"montjoie": [["rouet", 0.9, 0.6], ["coffre", 1.0, 0.7]], "braise": [["lampe_lave", 0.45, 0.45], ["bois_feu", 0.95, 0.45]],
	"boucan": [["ampli", 0.7, 0.5], ["caisses", 0.8, 0.7]], "tazira": [["poufs", 1.1, 0.7], ["jarre", 0.5, 0.5]],
	"astralys": [["cristal", 0.5, 0.5], ["globe", 0.5, 0.5]], "cliquetis": [["globe", 0.5, 0.5], ["caisses", 0.8, 0.7]],
	"ramure": [["bonsai", 0.5, 0.5], ["paravent", 1.3, 0.4]], "arcanelle": [["chaudron", 0.7, 0.7], ["globe", 0.5, 0.5]],
	"pirate": [["tonneau", 0.75, 0.75], ["coffre", 1.0, 0.7]], "carene": [["casier_homard", 0.75, 0.55], ["tonneau", 0.75, 0.75]],
	"egypte": [["jarre", 0.5, 0.5], ["jarre", 0.5, 0.5]], "maya": [["jarre", 0.5, 0.5], ["tambour", 0.5, 0.5]],
	"azteque": [["tambour", 0.5, 0.5], ["jarre", 0.5, 0.5]], "elfe": [["harpe", 0.6, 0.5], ["plante_haute", 0.6, 0.6]],
	"atlante": [["corail", 0.55, 0.55], ["jarre", 0.5, 0.5]], "nain": [["enclume", 0.65, 0.45], ["tonneau", 0.75, 0.75]],
}
## Sur un mur : [nom, demi-largeur]
const MUR := [["horloge", 0.3], ["miroir", 0.35], ["patere", 0.45], ["cadres", 0.5], ["etagere_bocaux", 0.6], ["applique", 0.15],
	["casseroles", 0.5], ["assiettes", 0.5]]
const MUR_VILLE := {
	"montjoie": [["bouclier", 0.45], ["tapisserie", 0.55]], "braise": [["applique", 0.15], ["assiettes", 0.5]],
	"boucan": [["guitare", 0.35], ["disques", 0.55]], "tazira": [["assiettes", 0.5], ["miroir_orient", 0.35]],
	"astralys": [["globe_mural", 0.35], ["cadres", 0.5]], "cliquetis": [["engrenages", 0.55], ["barometre", 0.25]],
	"ramure": [["eventail", 0.45], ["kakemono", 0.3]], "arcanelle": [["fioles", 0.6], ["miroir", 0.35]],
	"pirate": [["barre", 0.5], ["filet", 0.6]], "carene": [["bouee", 0.38], ["rames", 0.6]],
	"egypte": [["papyrus", 0.4], ["assiettes", 0.5]], "maya": [["masque", 0.28], ["natte", 0.5]],
	"azteque": [["masque", 0.28], ["natte", 0.5]], "elfe": [["couronne", 0.32], ["miroir", 0.35]],
	"atlante": [["coquillages", 0.5], ["bouee", 0.38]], "nain": [["marteaux", 0.45], ["chopes", 0.55]],
}
## Au plafond
const HAUT := ["herbes", "ail", "cage"]
const HAUT_VILLE := {"tazira": ["lanterne_ajouree"], "ramure": ["lanterne_papier"], "astralys": ["mobile_cristaux"],
	"arcanelle": ["bougies_flottantes"], "elfe": ["lianes"], "egypte": ["lanterne_ajouree"], "nain": ["herbes"], "pirate": ["cage"]}


# =================================================================== placer

static func habiller(M) -> void:
	var sc: String = str(M.ctx.get("scenario", ""))
	if sc in RIEN:
		return
	var R = M.R
	var style: String = str(R.style)
	var leger: bool = sc in LEGER or Iles.has(sc) or Echoppes.has(sc)
	var r := RandomNumberGenerator.new()
	r.seed = hash(str(M.ctx.get("id", "")) + "deco")
	_mats(R)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var inv: Transform3D = R.xf0.affine_inverse()
	var avoid: Array = []
	for f in M.people:
		if is_instance_valid(f) and f.npc != null:
			avoid.append(inv * (f.npc.global_position as Vector3))
	for it in M._its:
		avoid.append(inv * (it["pos"] as Vector3))
	# --- au sol, contre les murs
	var slots: Array = []
	var step: float = 0.95
	var nx: int = int((R.W - 1.2) / step)
	var nz: int = int((R.D - 1.2) / step)
	for i in range(nx + 1):
		var x: float = -hw + 0.6 + i * (R.W - 1.2) / maxf(1.0, nx)
		slots.append([x, -hd + 0.32, 0.0])
		if absf(x - R.door_x) > 1.3:
			slots.append([x, hd - 0.32, 180.0])
	for j in range(nz + 1):
		var z: float = -hd + 0.6 + j * (R.D - 1.2) / maxf(1.0, nz)
		slots.append([-hw + 0.32, z, 90.0])
		slots.append([hw - 0.32, z, -90.0])
	_shuffle(slots, r)
	var pool: Array = SOL.duplicate()
	for e in SOL_VILLE.get(style, []):
		pool.insert(0, e)
		pool.insert(0, e)
	var nsol: int = 0 if leger else clampi(int(R.W * R.D / 11.0), 2, 5)
	var used: Dictionary = {}
	var placed: int = 0
	for s in slots:
		if placed >= nsol:
			break
		var x2: float = float(s[0])
		var z2: float = float(s[1])
		if _near(avoid, x2, z2, 1.05):
			continue
		for tries in range(4):
			var e2: Array = pool[r.randi() % pool.size()]
			if used.has(str(e2[0])) and str(e2[0]) != "jarre":
				continue
			var along_x: bool = absf(float(s[2])) < 1.0 or absf(float(s[2]) - 180.0) < 1.0
			var sx: float = float(e2[1]) if along_x else float(e2[2])
			var sz: float = float(e2[2]) if along_x else float(e2[1])
			if not R.is_free(x2, z2, sx, sz):
				continue
			used[str(e2[0])] = true
			_sol(R, str(e2[0]), x2, z2, float(s[2]), r)
			R.reserve(x2, z2, sx, sz)
			placed += 1
			break
	# --- sur les murs
	var wslots: Array = []
	for i2 in range(nx + 1):
		var x3: float = -hw + 0.6 + i2 * (R.W - 1.2) / maxf(1.0, nx)
		wslots.append([x3, -hd + 0.02, 0.0])
		if absf(x3 - R.door_x) > 1.4:
			wslots.append([x3, hd - 0.02, 180.0])
	for j2 in range(nz + 1):
		var z3: float = -hd + 0.6 + j2 * (R.D - 1.2) / maxf(1.0, nz)
		wslots.append([-hw + 0.02, z3, 90.0])
		wslots.append([hw - 0.02, z3, -90.0])
	_shuffle(wslots, r)
	var wpool: Array = MUR.duplicate()
	for e3 in MUR_VILLE.get(style, []):
		wpool.insert(0, e3)
		wpool.insert(0, e3)
	var nmur: int = clampi(int(R.W * R.D / 14.0), 2, 4)
	var wused: Dictionary = {}
	var wplaced: int = 0
	var wy: float = minf(1.6, R.H - 1.0)
	for ws in wslots:
		if wplaced >= nmur:
			break
		var x4: float = float(ws[0])
		var z4: float = float(ws[1])
		for tries2 in range(4):
			var e4: Array = wpool[r.randi() % wpool.size()]
			if wused.has(str(e4[0])):
				continue
			var half: float = float(e4[1])
			if not R.wall_free(x4, wy, z4, half):
				continue
			# rien de haut posé devant (armoire, cheminée, étagère, horloge…)
			var fx: float = x4 + sin(deg_to_rad(float(ws[2]))) * 0.25
			var fz: float = z4 + cos(deg_to_rad(float(ws[2]))) * 0.25
			var along: bool = absf(float(ws[2])) < 1.0 or absf(float(ws[2]) - 180.0) < 1.0
			if not R.is_free(fx, fz, half * 2.0 if along else 0.3, 0.3 if along else half * 2.0):
				continue
			wused[str(e4[0])] = true
			_mur(R, str(e4[0]), x4, wy, z4, float(ws[2]), r)
			R.mark_wall(x4, wy, z4, half)
			wplaced += 1
			break
	# --- au plafond
	var hpool: Array = HAUT.duplicate()
	for e5 in HAUT_VILLE.get(style, []):
		hpool.insert(0, e5)
		hpool.insert(0, e5)
	var nhaut: int = 1 + (1 if R.W * R.D > 40.0 else 0)
	var hused: Dictionary = {}
	for k in range(nhaut * 3):
		if hused.size() >= nhaut:
			break
		var name: String = str(hpool[r.randi() % hpool.size()])
		if hused.has(name):
			continue
		var hx: float = r.randf_range(-hw + 0.7, hw - 0.7)
		var hz: float = r.randf_range(-hd + 0.7, hd - 1.4)
		if Vector2(hx, hz).length() < 1.0:
			continue
		hused[name] = true
		_haut(R, name, hx, hz, r)
	# --- les fêtes
	_saison(M, R, slots, avoid, r)


static func _shuffle(a: Array, r: RandomNumberGenerator) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j: int = r.randi() % (i + 1)
		var t: Variant = a[i]
		a[i] = a[j]
		a[j] = t


static func _near(avoid: Array, x: float, z: float, d: float) -> bool:
	for p in avoid:
		if Vector2((p as Vector3).x - x, (p as Vector3).z - z).length() < d:
			return true
	return false


# =================================================================== matériaux en plus

static func _mats(R) -> void:
	if R.kit.mats.has("deco_flamme"):
		return
	var e := func(c: Color, energy: float) -> StandardMaterial3D:
		var m := StandardMaterial3D.new()
		m.albedo_color = c
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = energy
		return m
	R._put("deco_flamme", e.call(Color(1.0, 0.62, 0.22), 3.0))
	R._put("deco_lueur", e.call(Color(1.0, 0.72, 0.32), 2.0))
	R._put("deco_cristal", e.call(Color(0.45, 0.85, 1.0), 1.6))
	R._put("deco_cristal_rose", e.call(Color(1.0, 0.5, 0.85), 1.4))
	R._put("deco_lave", e.call(Color(1.0, 0.35, 0.08), 2.4))
	R._put("deco_citrouille", R._col(Color(0.95, 0.48, 0.08), 0.6))
	R._put("deco_tige", R._col(Color(0.3, 0.38, 0.14), 0.8))
	R._put("deco_osier", R._col(Color(0.72, 0.56, 0.32), 0.95))
	# un miroir sans reflet calculé : clair et brillant (en métal pur, il paraîtrait noir)
	var mir: StandardMaterial3D = R._col(Color(0.72, 0.78, 0.84), 0.12, 0.25)
	mir.emission_enabled = true
	mir.emission = Color(0.55, 0.6, 0.66)
	mir.emission_energy_multiplier = 0.25
	R._put("deco_miroir", mir)
	R._put("deco_sapin", R._col(Color(0.1, 0.32, 0.16), 0.9))
	R._put("deco_boule", R._col(Color(0.85, 0.1, 0.12), 0.2, 0.6))
	R._put("deco_boule_or", R._col(Color(0.95, 0.75, 0.25), 0.2, 0.8))
	R._put("deco_herbe", R._col(Color(0.48, 0.56, 0.28), 0.9))
	R._put("deco_lavande", R._col(Color(0.55, 0.45, 0.75), 0.9))
	R._put("deco_ail", R._col(Color(0.94, 0.91, 0.84), 0.7))
	R._put("deco_oignon", R._col(Color(0.78, 0.45, 0.2), 0.6))
	R._put("deco_corde", R._col(Color(0.72, 0.6, 0.42), 0.95))
	R._put("deco_corail", R._col(Color(0.95, 0.42, 0.38), 0.7))
	R._put("deco_jade", R._col(Color(0.2, 0.55, 0.42), 0.4))
	R._put("deco_sable", R._col(Color(0.86, 0.74, 0.52), 0.9))
	R._put("deco_bleu_nuit", R._col(Color(0.12, 0.16, 0.32), 0.5))
	R._put("deco_vinyle", R._col(Color(0.05, 0.05, 0.06), 0.25))


# =================================================================== petites aides

static func _x(T: Transform3D, p: Vector3, rot: Vector3 = Vector3.ZERO) -> Transform3D:
	return T * Transform3D(Basis.from_euler(rot * (PI / 180.0)), p)


static func _b(R, T: Transform3D, p: Vector3, s: Vector3, k: String, rot: Vector3 = Vector3.ZERO) -> void:
	R.kit.box(_x(T, p, rot), s, k, 1.0)


static func _c(R, T: Transform3D, p: Vector3, r0: float, r1: float, h: float, k: String, seg: int = 12, rot: Vector3 = Vector3.ZERO) -> void:
	R.kit.cyl(_x(T, p, rot), r0, r1, h, k, seg)


## Une boule (maillage à part : citrouilles, boules de Noël, globes).
static func _boule(R, T: Transform3D, p: Vector3, rad: float, k: String, scl: Vector3 = Vector3.ONE) -> void:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = rad
	sm.height = rad * 2.0
	sm.radial_segments = 14
	sm.rings = 8
	mi.mesh = sm
	mi.material_override = R.kit.mat(k)
	R.root.add_child(mi)
	mi.global_transform = _x(T, p) * Transform3D(Basis().scaled(scl), Vector3.ZERO)


# =================================================================== au sol

static func _sol(R, name: String, x: float, z: float, yaw: float, r: RandomNumberGenerator) -> void:
	var T: Transform3D = R.L(x, 0, z, yaw)
	match name:
		"porte_manteau":
			_c(R, T, Vector3.ZERO, 0.18, 0.2, 0.04, "bois_sombre", 12)
			_c(R, T, Vector3(0, 0.04, 0), 0.025, 0.025, 1.7, "bois", 8)
			for k in range(4):
				var a: float = k * 90.0 + 45.0
				_b(R, T, Vector3(sin(deg_to_rad(a)) * 0.08, 1.62, cos(deg_to_rad(a)) * 0.08), Vector3(0.02, 0.02, 0.18), "bois", Vector3(-30, a, 0))
			_c(R, T, Vector3(0.1, 1.48, 0.05), 0.11, 0.09, 0.09, "tissu_" + ["brun", "noir", "rouge", "gris"][r.randi() % 4], 14)
			_c(R, T, Vector3(0.1, 1.57, 0.05), 0.15, 0.15, 0.01, "tissu_brun", 14)
			_b(R, T, Vector3(-0.08, 1.2, -0.04), Vector3(0.1, 0.75, 0.05), "tissu_" + ["rouge", "vert", "bleu", "jaune"][r.randi() % 4], Vector3(0, 0, -6))
		"panier":
			_c(R, T, Vector3.ZERO, 0.2, 0.24, 0.4, "deco_osier", 16)
			_c(R, T, Vector3(0, 0.4, 0), 0.25, 0.25, 0.03, "deco_osier", 16)
			for k2 in range(3):
				_b(R, T, Vector3(-0.08 + k2 * 0.08, 0.43, r.randf_range(-0.05, 0.05)), Vector3(0.2, 0.06, 0.16), "tissu_" + ["blanc", "bleu", "rose", "creme"][(k2 + r.randi()) % 4], Vector3(r.randf_range(-15, 15), r.randf_range(0, 90), 10))
		"bois_feu":
			for row in range(3):
				for k3 in range(4 - row):
					_c(R, T, Vector3(-0.36 + k3 * 0.2 + row * 0.1, 0.07 + row * 0.13, -0.2), 0.07, 0.07, 0.4, "bois", 7, Vector3(90, 0, 0))
			_b(R, T, Vector3(0.38, 0.25, 0), Vector3(0.04, 0.5, 0.04), "fer", Vector3(0, 0, 8))
		"plante_haute":
			R.plante(x, z, 0.0, 1.55)
			R.occupied.pop_back()
		"coffre":
			R.coffre_deco(x, z, yaw)
			R.occupied.pop_back()
		"seau_balai":
			_c(R, T, Vector3(-0.1, 0, 0), 0.13, 0.11, 0.26, "metal", 14)
			_c(R, T, Vector3(-0.1, 0.25, 0), 0.13, 0.13, 0.01, "noir", 14)
			_c(R, T, Vector3(0.15, 0.0, -0.08), 0.018, 0.018, 1.3, "bois", 6, Vector3(-10, 0, -8))
			_c(R, T, Vector3(0.13, 0.0, -0.06), 0.09, 0.04, 0.28, "deco_osier", 10, Vector3(-10, 0, -8))
		"gueridon":
			_c(R, T, Vector3.ZERO, 0.18, 0.22, 0.03, "bois_sombre", 14)
			_c(R, T, Vector3(0, 0.03, 0), 0.03, 0.04, 0.65, "bois_sombre", 10)
			_c(R, T, Vector3(0, 0.68, 0), 0.26, 0.26, 0.03, "bois", 18)
			# la lampe à huile et son abat-jour
			_c(R, T, Vector3(0, 0.71, 0), 0.07, 0.09, 0.14, "cuivre", 12)
			_c(R, T, Vector3(0, 0.85, 0), 0.02, 0.02, 0.1, "cuivre", 8)
			_c(R, T, Vector3(0, 0.92, 0), 0.06, 0.16, 0.16, "tissu_creme", 14)
			_c(R, T, Vector3(0, 0.9, 0), 0.03, 0.03, 0.04, "deco_lueur", 8)
		"bottes":
			for k4 in range(2):
				var bx: float = -0.12 + k4 * 0.24
				var c: String = ["cuir", "noir", "tissu_brun"][(k4 + r.randi()) % 3]
				for s in [-0.05, 0.05]:
					_b(R, T, Vector3(bx + s, 0.18, -0.04), Vector3(0.08, 0.36, 0.1), c)
					_b(R, T, Vector3(bx + s, 0.04, 0.03), Vector3(0.08, 0.08, 0.22), c)
		"caisses":
			R.caisse(x - 0.1, z, 0.55)
			R.occupied.pop_back()
			R.caisse(x + 0.12, z + 0.05, 0.38, 0.55)
		"tonneau":
			R.tonneau(x, z)
			R.occupied.pop_back()
		"rouet":
			_b(R, T, Vector3(0, 0.3, 0), Vector3(0.75, 0.08, 0.25), "bois")
			for sx in [-0.3, 0.3]:
				_c(R, T, Vector3(sx, 0, -0.08), 0.02, 0.02, 0.3, "bois", 6, Vector3(10, 0, 0))
				_c(R, T, Vector3(sx, 0, 0.08), 0.02, 0.02, 0.3, "bois", 6, Vector3(-10, 0, 0))
			R.kit.ring(_x(T, Vector3(-0.15, 0.62, 0), Vector3(90, 0, 0)), 0.26, 0.29, 0.03, "bois", 24)
			for k5 in range(6):
				_b(R, T, Vector3(-0.15, 0.62, 0), Vector3(0.012, 0.52, 0.012), "bois", Vector3(0, 0, k5 * 30.0))
			_c(R, T, Vector3(0.25, 0.34, 0), 0.015, 0.015, 0.45, "bois", 6, Vector3(0, 0, -20))
			_c(R, T, Vector3(0.38, 0.72, 0), 0.05, 0.03, 0.12, "deco_ail", 10)
		"lampe_lave":
			_c(R, T, Vector3.ZERO, 0.12, 0.16, 0.12, "fer", 12)
			_c(R, T, Vector3(0, 0.12, 0), 0.08, 0.12, 0.45, "verre", 14)
			_boule(R, T, Vector3(0, 0.24, 0), 0.06, "deco_lave", Vector3(1, 1.4, 1))
			_boule(R, T, Vector3(0.01, 0.42, 0), 0.04, "deco_lave", Vector3(1, 1.3, 1))
			_c(R, T, Vector3(0, 0.57, 0), 0.06, 0.08, 0.06, "fer", 12)
		"ampli":
			_b(R, T, Vector3(0, 0.33, 0), Vector3(0.6, 0.66, 0.35), "noir")
			_b(R, T, Vector3(0, 0.3, 0.18), Vector3(0.5, 0.48, 0.01), "tissu_gris")
			_b(R, T, Vector3(0, 0.6, 0.18), Vector3(0.5, 0.06, 0.01), "or")
			# la guitare appuyée contre l'ampli
			_boule(R, T, Vector3(0.45, 0.25, 0.08), 0.15, "tissu_rouge", Vector3(1, 1.2, 0.3))
			_b(R, T, Vector3(0.45, 0.62, 0.05), Vector3(0.05, 0.6, 0.03), "bois_sombre", Vector3(0, 0, -6))
		"poufs":
			for k6 in range(2):
				var px: float = -0.28 + k6 * 0.56
				_c(R, T, Vector3(px, 0, 0), 0.25, 0.26, 0.32, "tissu_" + ["orange", "turquoise", "rouge", "jaune"][(k6 * 2 + r.randi()) % 4], 16)
				R.kit.ring(_x(T, Vector3(px, 0.16, 0)), 0.25, 0.27, 0.03, "or", 16)
			_c(R, T, Vector3(0, 0, 0.3), 0.18, 0.18, 0.04, "cuivre", 16)
		"jarre":
			_c(R, T, Vector3.ZERO, 0.12, 0.2, 0.25, "terre_cuite", 14)
			_c(R, T, Vector3(0, 0.25, 0), 0.2, 0.08, 0.3, "terre_cuite", 14)
			_c(R, T, Vector3(0, 0.55, 0), 0.08, 0.1, 0.06, "terre_cuite", 14)
			R.kit.ring(_x(T, Vector3(0, 0.3, 0)), 0.19, 0.205, 0.04, "tissu_noir", 14)
		"cristal":
			_c(R, T, Vector3.ZERO, 0.2, 0.22, 0.12, "argent", 8)
			for k7 in range(5):
				var a2: float = k7 * 72.0 + r.randf_range(-10, 10)
				_c(R, T, Vector3(sin(deg_to_rad(a2)) * 0.07, 0.1, cos(deg_to_rad(a2)) * 0.07), 0.045, 0.0, r.randf_range(0.25, 0.5), "deco_cristal" if k7 % 2 == 0 else "deco_cristal_rose", 6, Vector3(cos(deg_to_rad(a2)) * 12.0, 0, -sin(deg_to_rad(a2)) * 12.0))
		"globe":
			_c(R, T, Vector3.ZERO, 0.12, 0.15, 0.04, "bois_sombre", 12)
			_c(R, T, Vector3(0, 0.04, 0), 0.02, 0.03, 0.7, "bois_sombre", 8)
			R.kit.ring(_x(T, Vector3(0, 0.96, 0), Vector3(90, 0, 23)), 0.21, 0.23, 0.02, "cuivre", 24)
			_boule(R, T, Vector3(0, 0.96, 0), 0.19, "deco_bleu_nuit" if R.style in ["astralys", "arcanelle"] else "deco_sable")
		"bonsai":
			_b(R, T, Vector3(0, 0.12, 0), Vector3(0.42, 0.24, 0.3), "ceramique")
			_b(R, T, Vector3(0, 0.25, 0), Vector3(0.38, 0.02, 0.26), "terreau")
			_c(R, T, Vector3(0, 0.25, 0), 0.03, 0.02, 0.22, "bois_sombre", 6, Vector3(0, 0, 18))
			_c(R, T, Vector3(0.06, 0.44, 0), 0.02, 0.012, 0.2, "bois_sombre", 6, Vector3(0, 0, -50))
			_boule(R, T, Vector3(-0.06, 0.5, 0), 0.12, "feuillage", Vector3(1.3, 0.55, 1))
			_boule(R, T, Vector3(0.17, 0.56, 0.02), 0.09, "feuillage", Vector3(1.3, 0.55, 1))
		"paravent":
			for k8 in range(3):
				var a3: float = (-1 + k8) * 25.0
				var px2: float = -0.42 + k8 * 0.42
				_b(R, T, Vector3(px2, 0.85, (k8 % 2) * 0.08), Vector3(0.4, 1.6, 0.02), "papier", Vector3(0, a3 * 0.3, 0))
				_b(R, T, Vector3(px2, 0.85, (k8 % 2) * 0.08 + 0.012), Vector3(0.42, 1.62, 0.01), "bois_sombre", Vector3(0, a3 * 0.3, 0))
		"chaudron":
			_c(R, T, Vector3(0, 0.08, 0), 0.25, 0.3, 0.35, "fer", 16)
			_c(R, T, Vector3(0, 0.43, 0), 0.27, 0.27, 0.02, "deco_cristal", 16)
			for k9 in range(3):
				var a4: float = k9 * 120.0
				_c(R, T, Vector3(sin(deg_to_rad(a4)) * 0.2, 0, cos(deg_to_rad(a4)) * 0.2), 0.03, 0.03, 0.1, "fer", 6)
			_c(R, T, Vector3(0.1, 0.4, 0), 0.015, 0.015, 0.5, "bois", 6, Vector3(0, 0, -25))
		"casier_homard":
			_b(R, T, Vector3(0, 0.02, 0), Vector3(0.65, 0.04, 0.45), "bois")
			for k10 in range(4):
				var cx: float = -0.28 + k10 * 0.187
				_b(R, T, Vector3(cx, 0.2, 0.2), Vector3(0.025, 0.36, 0.025), "bois")
				_b(R, T, Vector3(cx, 0.2, -0.2), Vector3(0.025, 0.36, 0.025), "bois")
			_b(R, T, Vector3(0, 0.38, 0), Vector3(0.65, 0.025, 0.45), "deco_corde")
			_boule(R, T, Vector3(0.45, 0.15, 0.05), 0.13, "tissu_rouge", Vector3(1, 1, 1))
		"tambour":
			_c(R, T, Vector3.ZERO, 0.2, 0.22, 0.55, "bois", 14)
			_c(R, T, Vector3(0, 0.55, 0), 0.21, 0.21, 0.01, "cuir", 14)
			for k11 in range(8):
				var a5: float = k11 * 45.0
				_b(R, T, Vector3(sin(deg_to_rad(a5)) * 0.21, 0.3, cos(deg_to_rad(a5)) * 0.21), Vector3(0.012, 0.45, 0.012), "deco_corde", Vector3(0, a5, 12))
		"harpe":
			_b(R, T, Vector3(0, 0.04, 0), Vector3(0.45, 0.08, 0.25), "bois")
			_c(R, T, Vector3(-0.18, 0.05, 0), 0.03, 0.025, 1.2, "bois", 8, Vector3(0, 0, -8))
			_b(R, T, Vector3(0.05, 1.12, 0), Vector3(0.55, 0.07, 0.05), "or", Vector3(0, 0, -18))
			_b(R, T, Vector3(0.18, 0.5, 0), Vector3(0.06, 0.95, 0.06), "bois", Vector3(0, 0, 22))
			for k12 in range(7):
				_b(R, T, Vector3(-0.12 + k12 * 0.045, 0.6 + k12 * 0.02, 0), Vector3(0.004, 0.9 - k12 * 0.06, 0.004), "ceramique")
		"corail":
			_c(R, T, Vector3.ZERO, 0.18, 0.22, 0.12, "pierre_lisse", 10)
			for k13 in range(6):
				var a6: float = k13 * 60.0 + r.randf_range(0, 30)
				_c(R, T, Vector3(0, 0.1, 0), 0.025, 0.012, r.randf_range(0.35, 0.6), "deco_corail", 6, Vector3(cos(deg_to_rad(a6)) * 30.0, 0, sin(deg_to_rad(a6)) * 30.0))
		"enclume":
			_c(R, T, Vector3.ZERO, 0.16, 0.2, 0.35, "bois_sombre", 10)
			_b(R, T, Vector3(0, 0.42, 0), Vector3(0.22, 0.14, 0.18), "fer")
			_b(R, T, Vector3(0, 0.52, 0), Vector3(0.5, 0.08, 0.2), "fer")
			_c(R, T, Vector3(-0.25, 0.48, 0), 0.0, 0.07, 0.24, "fer", 8, Vector3(0, 0, 90))
			_c(R, T, Vector3(0.12, 0.56, 0.02), 0.015, 0.015, 0.35, "bois", 6, Vector3(90, 30, 0))
			_b(R, T, Vector3(0.12, 0.58, 0.02), Vector3(0.12, 0.06, 0.06), "fer")


# =================================================================== sur les murs

static func _mur(R, name: String, x: float, y: float, z: float, yaw: float, r: RandomNumberGenerator) -> void:
	var T: Transform3D = R.L(x, y, z, yaw)
	match name:
		"horloge":
			_c(R, T, Vector3(0, 0, 0.01), 0.24, 0.24, 0.06, "bois_sombre", 20, Vector3(90, 0, 0))
			_c(R, T, Vector3(0, 0, 0.07), 0.2, 0.2, 0.005, "ceramique", 20, Vector3(90, 0, 0))
			for k in range(12):
				var a: float = k * 30.0
				_b(R, T, Vector3(sin(deg_to_rad(a)) * 0.17, cos(deg_to_rad(a)) * 0.17, 0.078), Vector3(0.012, 0.03, 0.004), "noir", Vector3(0, 0, -a))
			_b(R, T, Vector3(0.0, 0.05, 0.082), Vector3(0.012, 0.11, 0.004), "noir")
			_b(R, T, Vector3(0.05, 0.0, 0.084), Vector3(0.14, 0.01, 0.004), "noir", Vector3(0, 0, 20))
		"miroir", "miroir_orient":
			if name == "miroir_orient":
				_b(R, T, Vector3(0, 0, 0.02), Vector3(0.55, 0.75, 0.02), "or")
				_c(R, T, Vector3(0, 0.37, 0.02), 0.27, 0.27, 0.02, "or", 18, Vector3(90, 0, 0))
				_b(R, T, Vector3(0, 0, 0.035), Vector3(0.45, 0.65, 0.01), "deco_miroir")
				_c(R, T, Vector3(0, 0.37, 0.035), 0.22, 0.22, 0.01, "deco_miroir", 18, Vector3(90, 0, 0))
			else:
				_c(R, T, Vector3(0, 0, 0.01), 0.32, 0.32, 0.03, "bois_sombre" if r.randf() < 0.5 else "or", 24, Vector3(90, 0, 0))
				_c(R, T, Vector3(0, 0, 0.04), 0.28, 0.28, 0.005, "deco_miroir", 24, Vector3(90, 0, 0))
		"patere":
			_b(R, T, Vector3(0, 0, 0.015), Vector3(0.8, 0.1, 0.03), "bois")
			for k2 in range(4):
				_c(R, T, Vector3(-0.3 + k2 * 0.2, 0.0, 0.03), 0.012, 0.016, 0.08, "cuivre", 6, Vector3(70, 0, 0))
			_b(R, T, Vector3(-0.3, -0.3, 0.07), Vector3(0.12, 0.55, 0.04), "tissu_" + ["rouge", "vert", "bleu"][r.randi() % 3], Vector3(0, 0, 4))
			_c(R, T, Vector3(0.1, -0.12, 0.1), 0.12, 0.1, 0.1, "tissu_brun", 14, Vector3(-80, 0, 0))
			_b(R, T, Vector3(0.3, -0.22, 0.07), Vector3(0.22, 0.26, 0.08), "cuir")
			_b(R, T, Vector3(0.3, -0.05, 0.05), Vector3(0.02, 0.15, 0.02), "cuir", Vector3(0, 0, 30))
		"cadres":
			var cs: Array = [[-0.28, 0.08, 0.26, 0.32], [0.05, 0.14, 0.22, 0.26], [0.3, -0.02, 0.2, 0.28], [0.02, -0.2, 0.3, 0.18]]
			for c in cs:
				_b(R, T, Vector3(float(c[0]), float(c[1]), 0.012), Vector3(float(c[2]) + 0.04, float(c[3]) + 0.04, 0.02), "or" if r.randf() < 0.4 else "bois_sombre")
				_b(R, T, Vector3(float(c[0]), float(c[1]), 0.024), Vector3(float(c[2]), float(c[3]), 0.005), "tissu_" + ["creme", "bleu", "vert", "rose", "jaune", "turquoise"][r.randi() % 6])
				_boule(R, T, Vector3(float(c[0]), float(c[1]) + 0.02, 0.028), minf(float(c[2]), float(c[3])) * 0.22, "gateau", Vector3(1, 1.2, 0.15))
		"etagere_bocaux":
			R.etagere_murale(x + sin(deg_to_rad(yaw)) * 0.13, y - 0.05, z + cos(deg_to_rad(yaw)) * 0.13, yaw, 1.1, ["ceramique", "terre_cuite", "verre", "cuivre"][r.randi() % 4], 5)
		"applique":
			_b(R, T, Vector3(0, 0, 0.01), Vector3(0.1, 0.2, 0.02), "cuivre" if R.style != "nain" else "fer")
			_c(R, T, Vector3(0, -0.04, 0.02), 0.012, 0.012, 0.14, "cuivre", 6, Vector3(90, 0, 0))
			_c(R, T, Vector3(0, -0.06, 0.14), 0.05, 0.035, 0.03, "cuivre", 10)
			_c(R, T, Vector3(0, -0.03, 0.14), 0.02, 0.02, 0.12, "ceramique", 8)
			_boule(R, T, Vector3(0, 0.12, 0.14), 0.018, "deco_flamme", Vector3(1, 1.8, 1))
		"casseroles":
			_b(R, T, Vector3(0, 0.25, 0.04), Vector3(0.9, 0.025, 0.025), "fer")
			for k3 in range(4):
				var cx: float = -0.33 + k3 * 0.22
				var rr: float = r.randf_range(0.07, 0.11)
				_b(R, T, Vector3(cx, 0.16, 0.05), Vector3(0.015, 0.16, 0.015), "fer")
				_c(R, T, Vector3(cx, 0.08 - rr, 0.05), rr, rr, 0.03, "cuivre", 14, Vector3(90, 0, 0))
		"assiettes":
			for k4 in range(5):
				var px: float = -0.4 + k4 * 0.2
				var py: float = 0.12 if k4 % 2 == 0 else -0.08
				_c(R, T, Vector3(px, py, 0.005), 0.085, 0.085, 0.015, "ceramique", 18, Vector3(90, 0, 0))
				R.kit.ring(_x(T, Vector3(px, py, 0.021), Vector3(90, 0, 0)), 0.055, 0.075, 0.003, "tissu_" + ["bleu", "turquoise", "rouge", "jaune"][(k4 + r.randi()) % 4], 18)
		"bouclier":
			_c(R, T, Vector3(0, 0, 0.01), 0.32, 0.32, 0.04, "tissu_" + ["rouge", "bleu", "vert"][r.randi() % 3], 6, Vector3(90, 0, 0))
			R.kit.ring(_x(T, Vector3(0, 0, 0.05), Vector3(90, 0, 0)), 0.29, 0.33, 0.01, "argent", 6)
			_c(R, T, Vector3(0, 0, 0.05), 0.06, 0.05, 0.03, "or", 10, Vector3(90, 0, 0))
			for s in [-1.0, 1.0]:
				_b(R, T, Vector3(0, 0, 0.0), Vector3(0.04, 1.0, 0.012), "argent", Vector3(0, 0, s * 40.0))
				_b(R, T, Vector3(s * 0.33, -0.38, 0.01), Vector3(0.16, 0.03, 0.03), "or", Vector3(0, 0, s * 40.0))
		"tapisserie":
			_c(R, T, Vector3(-0.55, 0.45, 0.04), 0.02, 0.02, 1.1, "bois_sombre", 8, Vector3(0, 0, -90))
			_b(R, T, Vector3(0, -0.05, 0.03), Vector3(1.0, 1.0, 0.01), "tissu_" + ["rouge", "bleu", "vert"][r.randi() % 3])
			_b(R, T, Vector3(0, -0.05, 0.036), Vector3(0.8, 0.8, 0.004), "tissu_creme")
			_b(R, T, Vector3(0, -0.05, 0.04), Vector3(0.4, 0.5, 0.004), "or")
		"guitare":
			_boule(R, T, Vector3(0, -0.25, 0.06), 0.17, "tissu_" + ["rouge", "noir", "jaune", "bleu"][r.randi() % 4], Vector3(0.9, 1.15, 0.28))
			_boule(R, T, Vector3(0, -0.05, 0.06), 0.12, "tissu_noir", Vector3(0.9, 1.0, 0.28))
			_b(R, T, Vector3(0, 0.3, 0.06), Vector3(0.05, 0.6, 0.03), "bois_sombre")
			_b(R, T, Vector3(0, 0.63, 0.06), Vector3(0.08, 0.12, 0.03), "noir")
		"disques":
			for k5 in range(3):
				var px2: float = -0.38 + k5 * 0.38
				_b(R, T, Vector3(px2, 0, 0.01), Vector3(0.32, 0.32, 0.01), "tissu_" + ["orange", "violet", "turquoise", "jaune"][(k5 + r.randi()) % 4])
				_c(R, T, Vector3(px2 + 0.06, 0.0, 0.016), 0.14, 0.14, 0.004, "deco_vinyle", 20, Vector3(90, 0, 0))
				_c(R, T, Vector3(px2 + 0.06, 0.0, 0.021), 0.04, 0.04, 0.002, "tissu_rouge", 12, Vector3(90, 0, 0))
		"globe_mural":
			_c(R, T, Vector3(0, 0, 0.0), 0.05, 0.05, 0.12, "argent", 10, Vector3(90, 0, 0))
			_boule(R, T, Vector3(0, 0, 0.3), 0.2, "deco_cristal")
			R.kit.ring(_x(T, Vector3(0, 0, 0.3), Vector3(20, 0, 30)), 0.26, 0.28, 0.01, "argent", 24)
		"engrenages":
			var gs: Array = [[-0.25, 0.05, 0.22], [0.12, 0.15, 0.15], [0.2, -0.2, 0.12], [-0.05, -0.22, 0.09]]
			for g in gs:
				_c(R, T, Vector3(float(g[0]), float(g[1]), 0.0), float(g[2]), float(g[2]), 0.03, "cuivre" if r.randf() < 0.5 else "metal", 12, Vector3(90, 0, 0))
				for t in range(12):
					var a2: float = t * 30.0
					_b(R, T, Vector3(float(g[0]) + sin(deg_to_rad(a2)) * float(g[2]), float(g[1]) + cos(deg_to_rad(a2)) * float(g[2]), 0.015), Vector3(0.035, 0.04, 0.03), "cuivre", Vector3(0, 0, -a2))
				_c(R, T, Vector3(float(g[0]), float(g[1]), 0.03), 0.025, 0.025, 0.02, "fer", 8, Vector3(90, 0, 0))
		"barometre":
			_b(R, T, Vector3(0, 0, 0.015), Vector3(0.2, 0.7, 0.03), "bois_sombre")
			_c(R, T, Vector3(0, 0.15, 0.03), 0.09, 0.09, 0.01, "ceramique", 16, Vector3(90, 0, 0))
			_b(R, T, Vector3(0, -0.12, 0.035), Vector3(0.015, 0.3, 0.01), "verre")
			_b(R, T, Vector3(0, -0.18, 0.04), Vector3(0.008, 0.18, 0.006), "tissu_rouge")
		"eventail":
			for k6 in range(9):
				var a3: float = -60.0 + k6 * 15.0
				_b(R, T, Vector3(sin(deg_to_rad(a3)) * 0.22, cos(deg_to_rad(a3)) * 0.22 - 0.15, 0.01), Vector3(0.09, 0.45, 0.005), "papier" if k6 % 2 == 0 else "tissu_rouge", Vector3(0, 0, -a3))
		"kakemono":
			_c(R, T, Vector3(-0.22, 0.42, 0.03), 0.015, 0.015, 0.44, "bois_sombre", 8, Vector3(0, 0, -90))
			_b(R, T, Vector3(0, 0.0, 0.02), Vector3(0.36, 0.8, 0.005), "papier")
			_b(R, T, Vector3(0, 0.1, 0.024), Vector3(0.05, 0.4, 0.002), "noir")
			_boule(R, T, Vector3(0.08, -0.22, 0.024), 0.05, "tissu_rouge", Vector3(1, 1, 0.1))
			_c(R, T, Vector3(-0.22, -0.42, 0.03), 0.018, 0.018, 0.44, "bois_sombre", 8, Vector3(0, 0, -90))
		"fioles":
			R.etagere_murale(x + sin(deg_to_rad(yaw)) * 0.13, y - 0.15, z + cos(deg_to_rad(yaw)) * 0.13, yaw, 1.1, "verre", 1)
			for k7 in range(6):
				var px3: float = -0.42 + k7 * 0.17
				var c: String = ["deco_cristal", "deco_cristal_rose", "deco_lave", "deco_jade", "deco_lueur", "deco_cristal"][(k7 + r.randi()) % 6]
				_c(R, T, Vector3(px3, -0.135, 0.13), 0.035, 0.035, r.randf_range(0.08, 0.14), c, 8)
				_c(R, T, Vector3(px3, -0.0, 0.13), 0.012, 0.01, 0.04, "bois", 6)
		"barre":
			R.kit.ring(_x(T, Vector3(0, 0, 0.04), Vector3(90, 0, 0)), 0.26, 0.3, 0.05, "bois", 24)
			_c(R, T, Vector3(0, 0, 0.0), 0.06, 0.06, 0.09, "bois_sombre", 12, Vector3(90, 0, 0))
			for k8 in range(8):
				var a4: float = k8 * 45.0
				_b(R, T, Vector3(sin(deg_to_rad(a4)) * 0.22, cos(deg_to_rad(a4)) * 0.22, 0.065), Vector3(0.035, 0.44 if k8 < 4 else 0.0, 0.035), "bois", Vector3(0, 0, -a4))
				_c(R, T, Vector3(sin(deg_to_rad(a4)) * 0.3, cos(deg_to_rad(a4)) * 0.3, 0.065), 0.022, 0.018, 0.13, "bois", 6, Vector3(0, 0, -a4))
		"filet":
			for k9 in range(7):
				_b(R, T, Vector3(-0.5 + k9 * 0.166, -0.05, 0.01), Vector3(0.012, 0.9, 0.006), "deco_corde", Vector3(0, 0, (k9 % 2) * 4.0 - 2.0))
				_b(R, T, Vector3(0, -0.45 + k9 * 0.14, 0.012), Vector3(1.05, 0.012, 0.006), "deco_corde")
			_boule(R, T, Vector3(-0.2, -0.15, 0.05), 0.08, "verre")
			_boule(R, T, Vector3(0.25, 0.1, 0.05), 0.065, "deco_cristal")
			_b(R, T, Vector3(0.1, -0.3, 0.03), Vector3(0.18, 0.12, 0.02), "deco_corail", Vector3(0, 0, 20))
		"bouee":
			R.kit.ring(_x(T, Vector3(0, 0, 0.04), Vector3(90, 0, 0)), 0.18, 0.32, 0.1, "tissu_blanc", 24)
			for k10 in range(4):
				_b(R, T, Vector3(sin(deg_to_rad(k10 * 90.0 + 45.0)) * 0.25, cos(deg_to_rad(k10 * 90.0 + 45.0)) * 0.25, 0.1), Vector3(0.13, 0.1, 0.03), "tissu_rouge", Vector3(0, 0, -(k10 * 90.0 + 45.0)))
			R.kit.ring(_x(T, Vector3(0, 0, 0.1), Vector3(90, 0, 0)), 0.33, 0.35, 0.02, "deco_corde", 24)
		"rames":
			for s2 in [-1.0, 1.0]:
				_b(R, T, Vector3(0, 0, 0.02 + (s2 + 1.0) * 0.02), Vector3(0.045, 1.2, 0.03), "bois", Vector3(0, 0, s2 * 60.0))
				_b(R, T, Vector3(s2 * 0.44, -0.25, 0.03 + (s2 + 1.0) * 0.02), Vector3(0.14, 0.38, 0.02), "bois_clair", Vector3(0, 0, s2 * 60.0))
		"papyrus":
			_b(R, T, Vector3(0, 0, 0.01), Vector3(0.6, 0.85, 0.005), "deco_sable")
			_c(R, T, Vector3(-0.32, 0.43, 0.02), 0.025, 0.025, 0.64, "bois", 8, Vector3(0, 0, -90))
			_c(R, T, Vector3(-0.32, -0.43, 0.02), 0.025, 0.025, 0.64, "bois", 8, Vector3(0, 0, -90))
			for k11 in range(5):
				_b(R, T, Vector3(-0.15 + (k11 % 3) * 0.15, 0.25 - k11 * 0.11, 0.014), Vector3(0.08 + (k11 % 2) * 0.06, 0.06, 0.002), "noir")
			_b(R, T, Vector3(0.12, -0.25, 0.014), Vector3(0.14, 0.18, 0.002), "tissu_turquoise")
		"masque":
			_b(R, T, Vector3(0, 0, 0.03), Vector3(0.36, 0.46, 0.05), "deco_jade" if R.style == "maya" else "or")
			for s3 in [-1.0, 1.0]:
				_b(R, T, Vector3(s3 * 0.08, 0.06, 0.06), Vector3(0.09, 0.04, 0.02), "noir")
				_b(R, T, Vector3(s3 * 0.22, 0.0, 0.03), Vector3(0.06, 0.2, 0.03), "tissu_turquoise")
			_b(R, T, Vector3(0, -0.12, 0.06), Vector3(0.14, 0.03, 0.02), "tissu_rouge")
			_b(R, T, Vector3(0, -0.0, 0.07), Vector3(0.05, 0.12, 0.03), "deco_jade" if R.style != "maya" else "or")
			for k12 in range(5):
				_b(R, T, Vector3(-0.2 + k12 * 0.1, 0.3, 0.02), Vector3(0.05, 0.2, 0.01), "tissu_" + ["rouge", "vert", "jaune", "turquoise", "orange"][k12], Vector3(0, 0, -20 + k12 * 10))
		"natte":
			for k13 in range(10):
				_b(R, T, Vector3(0, -0.4 + k13 * 0.09, 0.01), Vector3(0.9, 0.09, 0.006), "tissu_" + ["rouge", "jaune", "noir", "turquoise", "creme"][k13 % 5])
			_b(R, T, Vector3(0, 0.0, 0.016), Vector3(0.2, 0.2, 0.004), "or", Vector3(0, 0, 45))
		"couronne":
			R.kit.ring(_x(T, Vector3(0, 0, 0.03), Vector3(90, 0, 0)), 0.18, 0.25, 0.05, "feuillage", 20)
			for k14 in range(6):
				var a5: float = k14 * 60.0
				_boule(R, T, Vector3(sin(deg_to_rad(a5)) * 0.22, cos(deg_to_rad(a5)) * 0.22, 0.06), 0.03, "deco_lueur")
		"coquillages":
			for k15 in range(7):
				var px4: float = -0.4 + k15 * 0.135
				var py2: float = r.randf_range(-0.2, 0.2)
				_boule(R, T, Vector3(px4, py2, 0.03), r.randf_range(0.04, 0.07), ["ceramique", "deco_corail", "deco_sable", "gateau"][k15 % 4], Vector3(1, 0.8, 0.4))
		"marteaux":
			for s4 in [-1.0, 1.0]:
				_b(R, T, Vector3(0, 0, 0.02 + (s4 + 1.0) * 0.02), Vector3(0.04, 0.8, 0.035), "bois", Vector3(0, 0, s4 * 35.0))
				_b(R, T, Vector3(s4 * -0.22, 0.32, 0.03 + (s4 + 1.0) * 0.02), Vector3(0.26, 0.13, 0.12), "fer", Vector3(0, 0, s4 * 35.0))
			_c(R, T, Vector3(0, 0, 0.0), 0.16, 0.16, 0.03, "bois_sombre", 6, Vector3(90, 0, 0))
		"chopes":
			R.etagere_murale(x + sin(deg_to_rad(yaw)) * 0.13, y - 0.15, z + cos(deg_to_rad(yaw)) * 0.13, yaw, 1.1, "verre", 1)
			for k16 in range(5):
				var px5: float = -0.4 + k16 * 0.2
				_c(R, T, Vector3(px5, -0.135, 0.13), 0.055, 0.06, 0.14, "bois" if k16 % 2 == 0 else "fer", 12)
				R.kit.ring(_x(T, Vector3(px5, -0.07, 0.13)), 0.055, 0.065, 0.02, "fer", 12)
				_b(R, T, Vector3(px5 + 0.07, -0.07, 0.13), Vector3(0.02, 0.09, 0.02), "bois_sombre")


# =================================================================== au plafond

static func _haut(R, name: String, x: float, z: float, r: RandomNumberGenerator) -> void:
	var top: float = R.H - 0.02
	var T: Transform3D = R.L(x, top, z, r.randf_range(0, 180))
	match name:
		"herbes":
			_b(R, T, Vector3(0, -0.25, 0), Vector3(0.9, 0.03, 0.03), "bois")
			for s in [-0.4, 0.4]:
				_b(R, T, Vector3(s, -0.12, 0), Vector3(0.01, 0.25, 0.01), "deco_corde")
			for k in range(5):
				var px: float = -0.32 + k * 0.16
				var c: String = ["deco_herbe", "deco_lavande", "deco_herbe", "tissu_rouge", "deco_herbe"][(k + r.randi()) % 5]
				# un bouquet tête en bas : des tiges qui s'écartent sous le lien
				for t in range(6):
					var a: float = t * 60.0 + k * 17.0
					_b(R, T, Vector3(px + sin(deg_to_rad(a)) * 0.025, -0.45, cos(deg_to_rad(a)) * 0.025), Vector3(0.018, 0.3, 0.006), c, Vector3(cos(deg_to_rad(a)) * 9.0, a, -sin(deg_to_rad(a)) * 9.0))
				_b(R, T, Vector3(px, -0.29, 0), Vector3(0.025, 0.05, 0.025), "deco_corde")
		"ail":
			_b(R, T, Vector3(0, -0.04, 0), Vector3(0.05, 0.05, 0.05), "fer")
			for s2 in [-0.12, 0.12]:
				_b(R, T, Vector3(s2, -0.4, 0), Vector3(0.015, 0.7, 0.015), "deco_corde")
				for k2 in range(6):
					_boule(R, T, Vector3(s2 + (0.03 if k2 % 2 == 0 else -0.03), -0.18 - k2 * 0.1, 0), 0.045, "deco_ail" if s2 < 0.0 else "deco_oignon", Vector3(1, 0.9, 1))
		"cage":
			_b(R, T, Vector3(0, -0.3, 0), Vector3(0.01, 0.6, 0.01), "fer")
			R.kit.ring(_x(T, Vector3(0, -1.05, 0)), 0.17, 0.19, 0.02, "cuivre", 16)
			for k3 in range(10):
				var a: float = k3 * 36.0
				_b(R, T, Vector3(sin(deg_to_rad(a)) * 0.18, -0.85, cos(deg_to_rad(a)) * 0.18), Vector3(0.008, 0.4, 0.008), "cuivre")
			_c(R, T, Vector3(0, -0.66, 0), 0.18, 0.02, 0.1, "cuivre", 12)
			_c(R, T, Vector3(0, -1.05, 0), 0.19, 0.19, 0.01, "bois", 14)
			_b(R, T, Vector3(0, -0.9, 0), Vector3(0.3, 0.01, 0.01), "bois")
			# l'oiseau sur son perchoir
			_boule(R, T, Vector3(0, -0.84, 0), 0.05, "tissu_" + ["jaune", "bleu", "vert", "rouge"][r.randi() % 4], Vector3(1, 1.1, 1.4))
			_boule(R, T, Vector3(0, -0.78, 0.04), 0.03, "tissu_" + ["jaune", "bleu", "vert"][r.randi() % 3])
			_c(R, T, Vector3(0, -0.78, 0.07), 0.0, 0.01, 0.025, "or", 6, Vector3(90, 0, 0))
		"lanterne_ajouree":
			_b(R, T, Vector3(0, -0.2, 0), Vector3(0.01, 0.4, 0.01), "fer")
			_c(R, T, Vector3(0, -0.85, 0), 0.06, 0.16, 0.25, "cuivre", 8)
			_c(R, T, Vector3(0, -0.6, 0), 0.16, 0.03, 0.2, "cuivre", 8)
			_c(R, T, Vector3(0, -0.84, 0), 0.05, 0.13, 0.22, "deco_lueur", 8)
			_c(R, T, Vector3(0, -0.4, 0), 0.03, 0.0, 0.06, "cuivre", 6)
		"lanterne_papier":
			_b(R, T, Vector3(0, -0.25, 0), Vector3(0.01, 0.5, 0.01), "noir")
			_boule(R, T, Vector3(0, -0.72, 0), 0.22, "deco_lueur", Vector3(1, 1.25, 1))
			R.kit.ring(_x(T, Vector3(0, -0.47, 0)), 0.1, 0.13, 0.03, "noir", 12)
			R.kit.ring(_x(T, Vector3(0, -1.0, 0)), 0.1, 0.13, 0.03, "noir", 12)
			_b(R, T, Vector3(0, -1.12, 0), Vector3(0.03, 0.18, 0.03), "tissu_rouge")
		"mobile_cristaux":
			_b(R, T, Vector3(0, -0.2, 0), Vector3(0.01, 0.4, 0.01), "argent")
			R.kit.ring(_x(T, Vector3(0, -0.42, 0)), 0.36, 0.38, 0.015, "argent", 24)
			for k4 in range(6):
				var a2: float = k4 * 60.0
				var hy: float = 0.25 + (k4 % 3) * 0.12
				_b(R, T, Vector3(sin(deg_to_rad(a2)) * 0.37, -0.42 - hy * 0.5, cos(deg_to_rad(a2)) * 0.37), Vector3(0.004, hy, 0.004), "argent")
				_c(R, T, Vector3(sin(deg_to_rad(a2)) * 0.37, -0.42 - hy - 0.16, cos(deg_to_rad(a2)) * 0.37), 0.0, 0.04, 0.16, "deco_cristal" if k4 % 2 == 0 else "deco_cristal_rose", 6)
		"bougies_flottantes":
			for k5 in range(7):
				var bx: float = r.randf_range(-0.6, 0.6)
				var bz: float = r.randf_range(-0.6, 0.6)
				var by: float = r.randf_range(-0.9, -0.55)
				_c(R, T, Vector3(bx, by, bz), 0.025, 0.025, r.randf_range(0.1, 0.2), "ceramique", 8)
				_boule(R, T, Vector3(bx, by + 0.24, bz), 0.016, "deco_flamme", Vector3(1, 1.8, 1))
		"lianes":
			for k6 in range(6):
				var lx: float = r.randf_range(-0.7, 0.7)
				var lz: float = r.randf_range(-0.5, 0.5)
				var ln: float = r.randf_range(0.5, 1.0)
				_b(R, T, Vector3(lx, -ln * 0.5, lz), Vector3(0.015, ln, 0.015), "deco_tige")
				for k7 in range(4):
					_b(R, T, Vector3(lx + 0.03, -ln * (0.2 + k7 * 0.22), lz), Vector3(0.08, 0.05, 0.005), "feuillage", Vector3(0, k7 * 70.0, 30))
				_boule(R, T, Vector3(lx, -ln - 0.03, lz), 0.035, "deco_lueur")


# =================================================================== les fêtes (le vrai calendrier)

static func _saison(M, R, slots: Array, avoid: Array, r: RandomNumberGenerator) -> void:
	var d: Dictionary = Time.get_date_dict_from_system()
	var mois: int = int(d.get("month", 1))
	var jour: int = int(d.get("day", 1))
	var halloween: bool = (mois == 10 and jour >= 18) or (mois == 11 and jour <= 2)
	var noel: bool = mois == 12 or (mois == 1 and jour <= 6)
	if not halloween and not noel:
		return
	if r.randf() > 0.7:
		return
	var n: int = 0
	for s in slots:
		if n >= (2 if halloween else 1):
			break
		var x: float = float(s[0])
		var z: float = float(s[1])
		var sz: float = 0.5 if halloween else 1.0
		if _near(avoid, x, z, 1.05) or not R.is_free(x, z, sz, sz):
			continue
		R.reserve(x, z, sz, sz)
		var T: Transform3D = R.L(x, 0, z, float(s[2]))
		if halloween:
			# une citrouille sculptée qui sourit, une bougie dedans
			var k: float = r.randf_range(0.85, 1.2)
			_boule(R, T, Vector3(0, 0.15 * k, 0), 0.2 * k, "deco_citrouille", Vector3(1.15, 0.8, 1.15))
			for a in [0.0, 60.0, 120.0]:
				_boule(R, T * Transform3D(Basis(Vector3.UP, deg_to_rad(a)), Vector3.ZERO), Vector3(0, 0.15 * k, 0), 0.2 * k, "deco_citrouille", Vector3(0.6, 0.82, 1.18))
			_c(R, T, Vector3(0, 0.28 * k, 0), 0.025, 0.018, 0.08, "deco_tige", 6, Vector3(0, 0, 12))
			for sx in [-1.0, 1.0]:
				_b(R, T, Vector3(sx * 0.07 * k, 0.2 * k, 0.215 * k), Vector3(0.05 * k, 0.04 * k, 0.02), "deco_lueur", Vector3(0, 0, sx * 20))
			_b(R, T, Vector3(0, 0.1 * k, 0.225 * k), Vector3(0.14 * k, 0.03 * k, 0.02), "deco_lueur")
		else:
			# un petit sapin, ses boules et son étoile
			_c(R, T, Vector3(0, 0, 0), 0.16, 0.18, 0.25, "tissu_rouge", 12)
			_c(R, T, Vector3(0, 0.22, 0), 0.04, 0.04, 0.12, "bois_sombre", 6)
			for k2 in range(4):
				var y0: float = 0.32 + k2 * 0.32
				_c(R, T, Vector3(0, y0, 0), 0.48 - k2 * 0.1, 0.08, 0.45, "deco_sapin", 10)
			for k3 in range(10):
				var a2: float = k3 * 37.0
				var yy: float = 0.42 + (k3 % 4) * 0.3
				var rr: float = 0.4 - (k3 % 4) * 0.09
				_boule(R, T, Vector3(sin(deg_to_rad(a2)) * rr, yy, cos(deg_to_rad(a2)) * rr), 0.035, "deco_boule" if k3 % 2 == 0 else "deco_boule_or")
			_boule(R, T, Vector3(0, 1.62, 0), 0.06, "deco_lueur", Vector3(1, 1.3, 0.4))
		n += 1
