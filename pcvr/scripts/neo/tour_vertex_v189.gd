extends "res://scripts/neo/tour_kumo_v187.gd"
## V189 : la Tour Vertex, la banque Vertex Finances, de l'autre côté du Boulevard des Néons : avec la Tour Kumo,
## elle fait la porte de la ville quand on débarque. Le deuxième immeuble de Néopolis fait à la main (il reprend
## les outils de la Tour Kumo : le repère des façades, les vitres à pièce en profondeur). Tout l'oppose à sa
## voisine : la pierre claire, le bronze et l'or, la lumière chaude.
##   - sur le quai et sur la rue de l'entrée : une colonnade haute de deux étages, et derrière, les grandes
##     baies de la salle des guichets ; la balustrade entre les colonnes ;
##   - l'entrée (à l'est) : les deux portes de bronze, le tapis rouge, la grande pièce d'or qui tourne ;
##   - sur le boulevard : les guichets automatiques dans leurs niches de bronze ;
##   - dans la ruelle : la porte blindée de la salle des coffres, le fourgon, les caméras ;
##   - autour de l'immeuble : le bandeau lumineux des cours, qui défile ;
##   - les étages : des piles de pierre, des lames d'or sur toute la hauteur, des allèges de marbre vert ;
##     l'étage des serveurs ; le jardin d'hiver (une grande loge vitrée de deux étages, ses arbres) ;
##   - l'étage de la direction, en retrait derrière sa terrasse ; la corniche ; le grand V d'or ;
##   - à l'angle du quai et du boulevard : l'horloge (elle donne l'heure du jeu) ;
##   - sur le toit : la verrière en pyramide, les drapeaux, l'aire de l'hélicoptère.
## L'intérieur (tours_v153) n'a pas changé : on y entre par la même porte.

const TEX9 := "res://assets/textures/neo189/"
const NE: int = 11                    # onze étages
const SORTES9 := ["hangar", "bureaux", "cafeteria", "bureaux", "bureaux", "serveurs", "bureaux", "jardin", "cafeteria", "bureaux", "direction"]

var R: Array = []
var YS: float = 0.0                   # le dessus du dernier étage
var _piece: Node3D                    # la pièce d'or de l'entrée
var _aiguilles: Array = []            # les aiguilles de l'horloge : [nœud, sa base, grande ?]
var _ticker: ShaderMaterial
var _verriere: StandardMaterial3D
var _nuit9: float = -1.0


func _tex(nom: String) -> Texture2D:
	if ResourceLoader.exists(TEX9 + nom):
		return load(TEX9 + nom)
	return super._tex(nom)


func build(neo: Node3D, batiment: Dictionary) -> void:
	N = neo
	bt = batiment
	name = "Tour_Vertex_v189"
	Y0 = IleScript.Y0
	var segs: Array = bt["segs"]
	R = [float(segs[0][0]), float(segs[0][1]), float(segs[0][2]), float(segs[0][3])]
	R0 = R
	R1 = R
	YS = Y0 + float(NE) * E
	YT = YS
	YH = float(segs[0][5])
	_rng.seed = 18900
	_matieres()
	_matieres9()
	b = Kit.Batch.new()
	bd = Kit.Batch.new()
	_vt = SurfaceTool.new()
	_vt.begin(Mesh.PRIMITIVE_TRIANGLES)
	_vtd = SurfaceTool.new()
	_vtd.begin(Mesh.PRIMITIVE_TRIANGLES)
	dedans = Node3D.new()
	dedans.name = "Vertex_dedans"
	add_child(dedans)
	var F: Array = _faces(R)
	for f in range(4):
		_pied9(F[f], f)
		for k in range(2, NE - 1):
			_etage9(F[f], k, f)
		_direction9(F[f], f)
		# le bandeau des cours
		var l: float = F[f]["l"]
		_fb(b, "metal_noir", F[f], 0.0, l, Y0 + 2.0 * E - 0.42, Y0 + 2.0 * E + 0.42, 0.0, 0.34)
		_panneau("k189_ticker", F[f], 0.0, l, Y0 + 2.0 * E - 0.3, Y0 + 2.0 * E + 0.3, 0.345, Vector2(l / 26.0, 1.0))
		_fb(b, "k189_or", F[f], 0.0, l, Y0 + 2.0 * E + 0.42, Y0 + 2.0 * E + 0.47, 0.0, 0.4)
		_fb(b, "k189_or", F[f], 0.0, l, Y0 + 2.0 * E - 0.47, Y0 + 2.0 * E - 0.42, 0.0, 0.4)
	_entree9(F[1])
	_guichets9(F[3])
	_ruelle9(F[2])
	_horloge9(F[0], F[3])
	_toit9()
	b.commit(self, "Vertex_dehors")
	bd.commit(dedans, "Vertex_dedans_mesh")
	_pose_vitres(_vt, self, "Vertex_vitres")
	_pose_vitres(_vtd, dedans, "Vertex_vitres_dedans")
	_lumieres9(F)
	print("ILE_MANGA_V189: la Tour Vertex (%d vitres)" % nb_vitres)


func _matieres9() -> void:
	if Kit._mcache.has("k189_pierre"):
		_ticker = Kit._mcache["k189_ticker"]
		_verriere = Kit._mcache["k189_verriere"]
		return
	var pan: String = "res://assets/textures/neo156/panneaux_metal.png"
	for def in [["k189_pierre", Color(0.9, 0.86, 0.76), 0.0, 0.8], ["k189_pierre_sombre", Color(0.6, 0.56, 0.5), 0.0, 0.75], ["k189_vert", Color(0.07, 0.26, 0.2), 0.3, 0.25]]:
		var m := StandardMaterial3D.new()
		m.albedo_color = def[1]
		m.metallic = def[2]
		m.roughness = def[3]
		# (pas l'image des panneaux d'acier, qui assombrit tout : seulement ses joints, en relief)
		if ResourceLoader.exists(pan.replace(".png", "_n.png")):
			m.normal_enabled = true
			m.normal_texture = load(pan.replace(".png", "_n.png"))
			m.normal_scale = 0.6
			m.uv1_scale = Vector3(0.3, 0.3, 0.3)
		Kit._mcache[def[0]] = m
	for def2 in [["k189_or", Color(1.0, 0.76, 0.3), 0.28], ["k189_bronze", Color(0.42, 0.27, 0.13), 0.42]]:
		var m2 := StandardMaterial3D.new()
		m2.albedo_color = def2[1]
		m2.metallic = 1.0
		m2.roughness = def2[2]
		Kit._mcache[def2[0]] = m2
	_ticker = ShaderMaterial.new()
	_ticker.shader = load("res://shaders/ticker_v189.gdshader")
	_ticker.set_shader_parameter("image", _tex("ticker.png"))
	Kit._mcache["k189_ticker"] = _ticker
	var dab := StandardMaterial3D.new()
	dab.albedo_texture = _tex("dab.png")
	dab.emission_enabled = true
	dab.emission_texture = _tex("dab.png")
	dab.emission_energy_multiplier = 1.6
	Kit._mcache["k189_dab"] = dab
	_verriere = StandardMaterial3D.new()
	_verriere.albedo_color = Color(0.55, 0.75, 0.8, 0.55)
	_verriere.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_verriere.metallic = 0.6
	_verriere.roughness = 0.1
	_verriere.cull_mode = BaseMaterial3D.CULL_DISABLED
	_verriere.emission_enabled = true
	_verriere.emission = Color(1.0, 0.8, 0.45)
	_verriere.emission_energy_multiplier = 0.1
	Kit._mcache["k189_verriere"] = _verriere


## Une colonne ronde, debout sur une façade.
func _colonne9(lot: Kit.Batch, f: Dictionary, s: float, d: float, y0: float, y1: float, r: float) -> void:
	lot.cyl_at("k189_pierre_sombre", _p(f, s, y0, d), r * 1.35, r * 1.35, 0.3, 16)
	lot.cyl_at("k189_pierre", _p(f, s, y0 + 0.3, d), r, r * 0.9, y1 - y0 - 0.7, 16)
	lot.cyl_at("k189_or", _p(f, s, y1 - 0.4, d), r * 0.95, r * 1.25, 0.12, 16)
	lot.cyl_at("k189_pierre", _p(f, s, y1 - 0.28, d), r * 1.3, r * 1.3, 0.28, 16)


func _travees(f: Dictionary) -> int:
	return 11 if float(f["l"]) > 30.0 else 5


# =================================================================== le pied (les deux premiers étages)

func _pied9(f: Dictionary, face: int) -> void:
	var l: float = f["l"]
	var nt: int = _travees(f)
	var w: float = l / float(nt)
	var y1: float = Y0 + 2.0 * E - 0.47
	if face <= 1:
		# la colonnade (le quai, la rue de l'entrée) : le mur en retrait, les grandes baies, les colonnes
		_fb(bd, "k189_pierre", f, 0.0, l, y1 - 0.5, y1, -2.0, 0.0)                              # (le plafond de la galerie)
		_fb(bd, "k189_pierre_sombre", f, 0.0, l, Y0, Y0 + 0.9, -2.2, -2.0)
		for i in range(nt + 1):
			var c: float = clampf(w * i, 0.55, l - 0.55)
			_colonne9(bd, f, c, -0.55, Y0, y1 - 0.5, 0.42)
			_fb(bd, "k189_pierre", f, c - 0.3, c + 0.3, Y0 + 0.9, y1 - 0.5, -2.2, -2.0)
		for i2 in range(nt):
			var s0: float = w * i2 + 0.3
			var s1: float = w * (i2 + 1) - 0.3
			var porte: bool = face == 1 and i2 == (nt >> 1)
			if not porte:
				_vitre(_vtd, f, s0, s1, Y0 + 0.9, y1 - 1.1, -2.05, 0.85, 0.92, 0.25)
				_fb(bd, "k189_bronze", f, (s0 + s1) * 0.5 - 0.04, (s0 + s1) * 0.5 + 0.04, Y0 + 0.9, y1 - 1.1, -2.1, -1.95)
				_fb(bd, "k189_bronze", f, s0, s1, Y0 + 3.6, Y0 + 3.68, -2.1, -1.95)
				# la balustrade, entre deux colonnes
				_fb(b, "k189_pierre_sombre", f, w * i2 + 0.6, w * (i2 + 1) - 0.6, Y0, Y0 + 0.16, 0.0, 0.3)
				_fb(b, "k189_pierre", f, w * i2 + 0.6, w * (i2 + 1) - 0.6, Y0 + 0.78, Y0 + 0.92, 0.0, 0.3)
				var nb: int = 7
				for j in range(nb):
					b.cyl_at("k189_pierre", _p(f, w * i2 + 0.8 + (w - 1.6) * float(j) / float(nb - 1), Y0 + 0.16, 0.15), 0.07, 0.05, 0.62, 8)
			_fb(bd, "k189_pierre", f, s0 - 0.3, s1 + 0.3, y1 - 1.1, y1 - 0.5, -2.2, -2.0)
			bd.box("lampe_chaude", Transform3D(_base(f), _p(f, (s0 + s1) * 0.5, y1 - 0.52, -1.0)), Vector3(0.5, 0.03, 0.5))
		# l'architrave, son filet d'or
		_fb(b, "k189_pierre", f, 0.0, l, y1 - 0.5, y1, 0.0, 0.22)
		_fb(b, "k189_or", f, 0.0, l, y1 - 0.56, y1 - 0.5, 0.0, 0.26)
	else:
		# le boulevard, la ruelle : un soubassement de pierre sombre, le mur de pierre, les fenêtres du 1er
		_fb(b, "k189_pierre_sombre", f, 0.0, l, Y0, Y0 + 1.1, 0.0, 0.22)
		_fb(b, "k189_pierre", f, 0.0, l, Y0 + 1.1, Y0 + E + 0.9, 0.0, 0.12)
		_fb(b, "k189_or", f, 0.0, l, Y0 + 1.1, Y0 + 1.16, 0.0, 0.26)
		for i3 in range(nt + 1):
			var c2: float = clampf(w * i3, 0.3, l - 0.3)
			_fb(b, "k189_pierre", f, c2 - 0.3, c2 + 0.3, Y0 + 1.1, y1, 0.0, 0.3)
		for i4 in range(nt):
			var t0: float = w * i4 + 0.3
			var t1: float = w * (i4 + 1) - 0.3
			_vitre(_vt, f, t0 + 0.2, t1 - 0.2, Y0 + E + 0.9, y1 - 0.35, 0.03, 0.8, 0.7)
			_fb(b, "k189_bronze", f, (t0 + t1) * 0.5 - 0.04, (t0 + t1) * 0.5 + 0.04, Y0 + E + 0.9, y1 - 0.35, 0.0, 0.1)
			_fb(b, "k189_pierre", f, t0, t0 + 0.2, Y0 + E + 0.9, y1 - 0.35, 0.0, 0.12)
			_fb(b, "k189_pierre", f, t1 - 0.2, t1, Y0 + E + 0.9, y1 - 0.35, 0.0, 0.12)
			_fb(b, "k189_pierre", f, t0, t1, y1 - 0.35, y1, 0.0, 0.12)


# =================================================================== les étages (2 à 9)

func _etage9(f: Dictionary, k: int, face: int) -> void:
	var l: float = f["l"]
	var nt: int = _travees(f)
	var w: float = l / float(nt)
	var y: float = _yk(k)
	var sorte: String = SORTES9[k]
	for i in range(nt + 1):
		var c: float = clampf(w * i, 0.3, l - 0.3)
		_fb(b, "k189_pierre", f, c - 0.3, c + 0.3, y, y + E, 0.0, 0.3)
	for i2 in range(nt):
		var s0: float = w * i2 + 0.3
		var s1: float = w * (i2 + 1) - 0.3
		var m: float = (s0 + s1) * 0.5
		# le jardin d'hiver : au milieu du quai, une loge vitrée de deux étages (7 et 8)
		if face == 0 and (k == 7 or k == 8) and i2 >= 4 and i2 <= 6:
			if k == 7:
				_loge9(f, s0 - 0.3, s1 + 0.3, y, i2)
			continue
		if sorte == "serveurs":
			_fb(b, "k187_leds", f, s0, s1, y + 0.1, y + E - 0.1, -0.1, 0.05)
			_fb(b, "k189_bronze", f, s0, s1, y, y + 0.1, 0.0, 0.12)
			_fb(b, "k189_bronze", f, m - 0.05, m + 0.05, y, y + E, 0.0, 0.42)
			continue
		# l'allège de marbre vert, son filet d'or ; deux vitres ; la lame d'or entre elles
		_fb(b, "k189_vert", f, s0, s1, y, y + 0.95, -0.1, 0.08)
		_fb(b, "k189_or", f, s0, s1, y + 0.9, y + 0.95, 0.08, 0.12)
		var chaud: float = 0.45
		var p: float = 0.45
		if sorte == "cafeteria":
			chaud = 0.9
			p = 0.85
		elif sorte == "jardin":
			chaud = 0.7
			p = 0.7
		_vitre(_vt, f, s0, m - 0.05, y + 0.95, y + E, 0.02, chaud, p)
		_vitre(_vt, f, m + 0.05, s1, y + 0.95, y + E, 0.02, chaud, p)
		_fb(b, "k189_or", f, m - 0.05, m + 0.05, y, y + E, 0.0, 0.42)


## La loge du jardin d'hiver (une travée) : le vitrage en retrait, haut de deux étages, un arbre, le garde-corps.
func _loge9(f: Dictionary, s0: float, s1: float, y: float, i: int) -> void:
	var yh: float = y + 2.0 * E
	_fb(bd, "bois", f, s0, s1, y, y + 0.06, -2.6, 0.0)
	_fb(bd, "k189_pierre", f, s0, s1, yh - 0.25, yh, -2.6, 0.0)
	_vitre(_vtd, f, s0 + 0.05, s1 - 0.05, y + 0.06, yh - 0.25, -2.6, 0.85, 0.95, 0.0)
	_fb(bd, "k189_bronze", f, s0, s1, y + E - 0.05, y + E + 0.05, -2.65, -2.55)
	_fb(b, "verre", f, s0, s1, y + 0.1, y + 1.1, 0.0, 0.04)
	_fb(b, "k189_or", f, s0, s1, y + 1.1, y + 1.15, -0.02, 0.06)
	_fb(bd, "k189_pierre_sombre", f, s0 + 0.4, s1 - 0.4, y + 0.06, y + 0.5, -1.9, -0.7)
	_fb(bd, "terre_bac", f, s0 + 0.5, s1 - 0.5, y + 0.5, y + 0.52, -1.8, -0.8)
	_plante(Flora.tree(1890 + i, 7.0, 260), _p(f, (s0 + s1) * 0.5, y + 0.5, -1.3), Vector3(0.75, 0.72, 0.75), dedans)
	_plante(Flora.bush(1893 + i), _p(f, s0 + 0.9, y + 0.5, -1.0), Vector3(0.7, 0.7, 0.7), dedans)
	_plante(Flora.bush(1896 + i), _p(f, s1 - 0.9, y + 0.5, -1.5), Vector3(0.6, 0.6, 0.6), dedans)
	bd.box("lampe_chaude", Transform3D(_base(f), _p(f, (s0 + s1) * 0.5, yh - 0.27, -1.3)), Vector3(0.6, 0.03, 0.6))


# =================================================================== l'étage de la direction, la corniche

func _direction9(f: Dictionary, face: int) -> void:
	var l: float = f["l"]
	var nt: int = _travees(f)
	var w: float = l / float(nt)
	var y: float = _yk(NE - 1)
	# la terrasse : sa dalle, son garde-corps de verre ; le vitrage en retrait, les fines colonnes d'or
	_fb(b, "k189_pierre", f, 0.0, l, y - 0.12, y + 0.1, 0.0, 0.5)
	_fb(b, "k189_or", f, 0.0, l, y + 0.1, y + 0.15, 0.3, 0.52)
	_fb(b, "verre", f, 0.0, l, y + 0.15, y + 1.1, 0.4, 0.44)
	_fb(bd, "k189_pierre_sombre", f, 0.0, l, y, y + 0.05, -1.4, 0.0)
	for i in range(nt + 1):
		var c: float = clampf(w * i, 0.2, l - 0.2)
		bd.cyl_at("k189_or", _p(f, c, y, -0.3), 0.1, 0.1, E - 0.3, 10)
	for i2 in range(nt):
		_vitre(_vtd, f, w * i2 + 0.08, w * (i2 + 1) - 0.08, y + 0.05, y + E - 0.3, -1.4, 0.75, 0.85, 0.2)
		_fb(bd, "k189_bronze", f, w * i2 - 0.08, w * i2 + 0.08, y, y + E - 0.3, -1.45, -1.35)
	# la corniche, l'acrotère
	_fb(b, "k189_pierre", f, -0.5, l + 0.5, YS - 0.3, YS + 0.25, -1.4, 0.7)
	_fb(b, "k189_or", f, -0.5, l + 0.5, YS - 0.36, YS - 0.3, -0.2, 0.74)
	_fb(b, "k189_pierre", f, 0.0, l, YS + 0.25, YH, -0.5, 0.0)
	_fb(b, "k189_pierre_sombre", f, 0.0, l, YH, YH + 0.12, -0.6, 0.1)
	if face == 0:
		# le grand V d'or, au milieu du quai ; le nom de la maison, sous la corniche
		var m: float = l * 0.5
		for sg in [-1.0, 1.0]:
			b.box("k189_or", Transform3D(_base(f) * Basis(Vector3(0, 0, 1), -sg * 0.32), _p(f, m + sg * 0.95, YH + 2.85, -0.2)), Vector3(0.55, 5.6, 0.3))
		_fb(b, "k189_pierre_sombre", f, m - 1.2, m + 1.2, YH, YH + 0.3, -0.6, 0.1)
		_image("vertex_enseigne.png", _p(f, m - 10.0, (YS + 0.25 + YH) * 0.5, 0.03), _n3(f), Vector2(8.6, 1.07), false, 1.5)
	if face == 3:
		_image("vertex_enseigne.png", _p(f, l * 0.5, (YS + 0.25 + YH) * 0.5, 0.03), _n3(f), Vector2(8.6, 1.07), false, 1.5)


# =================================================================== l'entrée (à l'est)

func _entree9(f: Dictionary) -> void:
	var l: float = f["l"]
	var m: float = l * 0.5
	# le tapis rouge, de la porte au trottoir ; les potelets et leur cordon
	_fb(b, "tissu_rouge", f, m - 1.3, m + 1.3, Y0 + 0.004, Y0 + 0.02, -2.0, 3.2)
	for sg in [-1.55, 1.55]:
		for d in [0.6, 1.9, 3.2]:
			b.cyl_at("k189_or", _p(f, m + sg, Y0, d), 0.13, 0.13, 0.03, 10)
			b.cyl_at("k189_or", _p(f, m + sg, Y0, d), 0.025, 0.025, 0.95, 8)
			b.blob("k189_or", _p(f, m + sg, Y0 + 0.98, d), Vector3(0.05, 0.05, 0.05), 6)
		b.tube("tissu_rouge", _p(f, m + sg, Y0 + 0.9, 0.6), _p(f, m + sg, Y0 + 0.9, 3.2), 0.025, 5)
	# les deux portes de bronze (l'une entrouverte), leurs panneaux, le linteau et son médaillon
	_fb(bd, "k189_pierre", f, m - 2.2, m - 1.7, Y0, Y0 + 5.6, -2.2, -1.9)
	_fb(bd, "k189_pierre", f, m + 1.7, m + 2.2, Y0, Y0 + 5.6, -2.2, -1.9)
	_fb(bd, "k189_pierre", f, m - 2.2, m + 2.2, Y0 + 4.9, Y0 + 5.6, -2.2, -1.9)
	_fb(bd, "k189_bronze", f, m - 1.7, m - 0.02, Y0, Y0 + 4.9, -2.1, -2.0)
	bd.box("k189_bronze", Transform3D(_base(f) * Basis(Vector3.UP, 0.5), _p(f, m + 0.95, Y0 + 2.45, -1.75)), Vector3(1.68, 4.9, 0.1))
	for hh in [0.5, 1.9, 3.3]:
		_fb(bd, "k189_or", f, m - 1.5, m - 0.22, Y0 + hh, Y0 + hh + 1.2, -2.0, -1.97)
		_fb(bd, "k189_bronze", f, m - 1.42, m - 0.3, Y0 + hh + 0.08, Y0 + hh + 1.12, -1.97, -1.95)
	bd.cyl("k189_or", Transform3D(_base(f) * Basis(Vector3(1, 0, 0), PI * 0.5), _p(f, m, Y0 + 5.25, -1.86)), 0.3, 0.3, 0.06, 20)
	_fb(bd, "lampe_chaude", f, m - 1.6, m + 1.6, Y0 + 4.8, Y0 + 4.86, -1.9, -1.6)
	# la pièce d'or, sur son socle, au-dessus de l'entrée : elle tourne
	_fb(b, "k189_pierre_sombre", f, m - 1.0, m + 1.0, Y0 + 2.0 * E + 0.47, Y0 + 2.0 * E + 1.0, 0.0, 0.9)
	var lot := Kit.Batch.new()
	lot.cyl("k189_or", Transform3D(Basis(Vector3(1, 0, 0), PI * 0.5), Vector3.ZERO), 1.5, 1.5, 0.22, 36)
	for sg2 in [-1.0, 1.0]:
		lot.cyl("k189_bronze", Transform3D(Basis(Vector3(1, 0, 0), PI * 0.5), Vector3(0, 0, sg2 * 0.115)), 1.25, 1.25, 0.012, 36)
		for sv in [-1.0, 1.0]:
			lot.box("k189_or", Transform3D(Basis(Vector3(0, 0, 1), -sv * 0.32), Vector3(sv * 0.3, 0.0, sg2 * 0.13)), Vector3(0.2, 1.7, 0.03))
	_piece = MeshInstance3D.new()
	(_piece as MeshInstance3D).mesh = _maillage(lot)
	add_child(_piece)
	_piece.global_position = _p(f, m, Y0 + 2.0 * E + 2.6, 0.45)
	# les deux lanternes de bronze
	for sg3 in [-2.6, 2.6]:
		_fb(b, "k189_bronze", f, m + sg3 - 0.05, m + sg3 + 0.05, Y0 + 3.0, Y0 + 3.1, 0.0, 0.5)
		b.cyl_at("k189_bronze", _p(f, m + sg3, Y0 + 2.45, 0.45), 0.14, 0.18, 0.08, 8)
		b.cyl_at("lampe_chaude", _p(f, m + sg3, Y0 + 2.53, 0.45), 0.13, 0.13, 0.4, 8)
		b.cyl_at("k189_bronze", _p(f, m + sg3, Y0 + 2.93, 0.45), 0.2, 0.04, 0.14, 8)


# =================================================================== le boulevard : les guichets automatiques

func _guichets9(f: Dictionary) -> void:
	var l: float = f["l"]
	var w: float = l / 5.0
	for i in range(1, 4):
		var m: float = w * (i + 0.5)
		# la niche de bronze, l'écran, le clavier, la fente ; l'auvent de verre et sa lumière
		_fb(b, "k189_bronze", f, m - 1.2, m + 1.2, Y0 + 0.2, Y0 + 2.7, 0.12, 0.3)
		for q in [-0.6, 0.6]:
			_fb(b, "metal_noir", f, m + q - 0.42, m + q + 0.42, Y0 + 0.75, Y0 + 2.2, 0.3, 0.34)
			_panneau("k189_dab", f, m + q - 0.3, m + q + 0.3, Y0 + 1.35, Y0 + 1.95, 0.345)
			b.box("in_inox", Transform3D(_base(f) * Basis(Vector3(1, 0, 0), -0.5), _p(f, m + q, Y0 + 1.12, 0.42)), Vector3(0.5, 0.03, 0.26))
			_fb(b, "lampe_blanche", f, m + q - 0.2, m + q + 0.2, Y0 + 0.9, Y0 + 0.93, 0.34, 0.35)
		_fb(b, "verre", f, m - 1.4, m + 1.4, Y0 + 2.85, Y0 + 2.89, 0.0, 1.2)
		_fb(b, "k189_or", f, m - 1.4, m + 1.4, Y0 + 2.89, Y0 + 2.93, 1.16, 1.2)
		_fb(b, "lampe_chaude", f, m - 1.0, m + 1.0, Y0 + 2.8, Y0 + 2.84, 0.3, 0.42)
	_image("vertex_enseigne.png", _p(f, l * 0.5, Y0 + 3.75, 0.34), _n3(f), Vector2(7.0, 0.88), false, 1.3)


# =================================================================== la ruelle : la salle des coffres, le fourgon

func _ruelle9(f: Dictionary) -> void:
	var l: float = f["l"]
	# la porte blindée (ronde, comme celle d'un coffre), son volant, ses verrous
	var pm: float = l * 0.5
	_fb(b, "k189_pierre_sombre", f, pm - 2.5, pm + 2.5, Y0, Y0 + 4.6, 0.12, 0.36)
	_fb(b, "metal_noir", f, pm - 2.1, pm + 2.1, Y0, Y0 + 4.3, 0.12, 0.4)
	var rond := _base(f) * Basis(Vector3(1, 0, 0), PI * 0.5)
	b.cyl("k189_bronze", Transform3D(rond, _p(f, pm, Y0 + 2.2, 0.5)), 1.9, 1.9, 0.2, 40)
	b.cyl("chrome", Transform3D(rond, _p(f, pm, Y0 + 2.2, 0.62)), 1.5, 1.5, 0.06, 40)
	b.cyl("k189_or", Transform3D(rond, _p(f, pm, Y0 + 2.2, 0.66)), 0.95, 0.95, 0.03, 32)
	b.cyl("chrome", Transform3D(rond, _p(f, pm, Y0 + 2.2, 0.68)), 0.85, 0.85, 0.03, 32)
	b.cyl("k189_bronze", Transform3D(rond, _p(f, pm, Y0 + 2.2, 0.72)), 0.25, 0.25, 0.14, 16)
	for a in range(6):
		var an: float = a * TAU / 6.0
		var dir: Vector3 = _u3(f) * cos(an) + Vector3.UP * sin(an)
		b.tube("chrome", _p(f, pm, Y0 + 2.2, 0.76), _p(f, pm, Y0 + 2.2, 0.76) + dir * 0.75, 0.04, 6)
		b.blob("k189_or", _p(f, pm, Y0 + 2.2, 0.76) + dir * 0.78, Vector3(0.07, 0.07, 0.07), 6)
		b.cyl("k189_or", Transform3D(rond, _p(f, pm, Y0 + 2.2, 0.62) + dir * 1.7), 0.09, 0.09, 0.1, 8)
	_fb(b, "k187_danger", f, pm - 2.6, pm + 2.6, Y0 + 0.004, Y0 + 0.02, 0.4, 0.8)
	# le fourgon blindé : la caisse verte et sa bande d'or, la cabine et son pare-brise, les passages de roue,
	# le pare-chocs, les phares, les portes de l'arrière, le gyrophare
	var fs: float = l * 0.5 + 8.0
	_fb(b, "k189_vert", f, fs - 2.6, fs + 1.3, Y0 + 0.5, Y0 + 2.65, 0.8, 2.9)
	_fb(b, "k189_or", f, fs - 2.61, fs + 1.31, Y0 + 1.35, Y0 + 1.5, 0.79, 2.91)
	_fb(b, "k189_vert", f, fs - 2.5, fs + 1.2, Y0 + 2.65, Y0 + 2.72, 0.9, 2.8)
	_fb(b, "k189_vert", f, fs + 1.3, fs + 2.9, Y0 + 0.5, Y0 + 1.45, 0.86, 2.84)
	b.box("k189_vert", Transform3D(_base(f), _p(f, fs + 1.85, Y0 + 1.85, 1.85)), Vector3(1.1, 0.8, 1.98))
	b.box("verre_fume", Transform3D(_base(f) * Basis(Vector3(0, 0, 1), 0.5), _p(f, fs + 2.62, Y0 + 1.83, 1.85)), Vector3(0.06, 0.95, 1.8))
	for wd0 in [0.855, 2.845]:
		_fb(b, "verre_fume", f, fs + 1.45, fs + 2.25, Y0 + 1.55, Y0 + 2.15, wd0 - 0.01, wd0 + 0.01)
		_fb(b, "k189_or", f, fs + 1.4, fs + 2.3, Y0 + 0.6, Y0 + 1.4, wd0 - 0.005, wd0 + 0.005)
		_fb(b, "k189_vert", f, fs + 1.43, fs + 2.27, Y0 + 0.63, Y0 + 1.37, wd0 - 0.01, wd0 + 0.01)
	_fb(b, "metal_noir", f, fs - 2.7, fs + 3.05, Y0 + 0.32, Y0 + 0.52, 0.9, 2.8)
	_fb(b, "in_inox", f, fs + 2.9, fs + 3.1, Y0 + 0.36, Y0 + 0.6, 0.84, 2.86)
	_fb(b, "metal_noir", f, fs + 2.9, fs + 2.93, Y0 + 0.75, Y0 + 1.2, 1.35, 2.35)
	for gy2 in range(4):
		_fb(b, "in_inox", f, fs + 2.93, fs + 2.94, Y0 + 0.8 + gy2 * 0.1, Y0 + 0.84 + gy2 * 0.1, 1.4, 2.3)
	for wx in [fs - 1.7, fs + 2.0]:
		for wd in [0.92, 2.78]:
			b.cyl("plastique_noir", Transform3D(_base(f) * Basis(Vector3(1, 0, 0), PI * 0.5), _p(f, wx, Y0 + 0.42, wd)), 0.42, 0.42, 0.26, 18)
			b.cyl("in_inox", Transform3D(_base(f) * Basis(Vector3(1, 0, 0), PI * 0.5), _p(f, wx, Y0 + 0.42, wd)), 0.2, 0.2, 0.28, 10)
			_fb(b, "metal_noir", f, wx - 0.55, wx + 0.55, Y0 + 0.85, Y0 + 0.95, wd - 0.16, wd + 0.16)
	for ld in [1.05, 2.65]:
		_fb(b, "lampe_blanche", f, fs + 2.9, fs + 2.93, Y0 + 0.85, Y0 + 1.05, ld - 0.14, ld + 0.14)
		_fb(b, "neon_rouge", f, fs - 2.62, fs - 2.6, Y0 + 0.85, Y0 + 1.05, ld - 0.1, ld + 0.1)
	_fb(b, "k189_or", f, fs - 2.62, fs - 2.6, Y0 + 0.6, Y0 + 2.5, 1.84, 1.86)                   # (les deux portes de l'arrière)
	for pd in [1.55, 2.15]:
		_fb(b, "in_inox", f, fs - 2.64, fs - 2.6, Y0 + 1.5, Y0 + 1.6, pd - 0.03, pd + 0.03)
	b.cyl_at("k187_orange", _p(f, fs + 1.8, Y0 + 2.25, 1.85), 0.09, 0.07, 0.12, 10)
	N._col(Transform3D(_base(f), _p(f, fs + 0.15, Y0 + 1.4, 1.85)), Vector3(5.7, 2.6, 2.2))
	# les caméras, les climatiseurs, les gaines
	for cs in [pm - 3.4, pm + 3.4, 4.0, l - 4.0]:
		_fb(b, "metal_noir", f, cs - 0.04, cs + 0.04, Y0 + 4.9, Y0 + 5.0, 0.12, 0.5)
		b.box("peinture_blanche", Transform3D(_base(f) * Basis(Vector3(1, 0, 0), 0.5), _p(f, cs, Y0 + 4.85, 0.6)), Vector3(0.16, 0.16, 0.4))
		b.blob("neon_rouge", _p(f, cs, Y0 + 4.78, 0.8), Vector3(0.025, 0.025, 0.025), 5)
	for i in range(5):
		Kit.ac_unit(b, _p(f, 6.0 + i * 1.5, Y0 + 2.0 * E + 0.6 + (i % 2) * 3.5, 0.5), atan2(_n3(f).x, _n3(f).z))
	for gs in [2.0, l - 2.0]:
		_fb(b, "in_inox", f, gs - 0.3, gs + 0.3, Y0 + 1.1, YS, 0.3, 0.8)
		for gy in range(8):
			_fb(b, "metal_noir", f, gs - 0.33, gs + 0.33, Y0 + 3.0 + gy * 4.5, Y0 + 3.1 + gy * 4.5, 0.28, 0.83)


# =================================================================== l'horloge, à l'angle du quai et du boulevard

func _horloge9(fq: Dictionary, fb2: Dictionary) -> void:
	for q in [[fq, float(fq["l"]) - 2.4], [fb2, 2.4]]:
		var f: Dictionary = q[0]
		var s: float = q[1]
		var yc: float = _yk(9) + 0.4
		var rond := _base(f) * Basis(Vector3(1, 0, 0), PI * 0.5)
		_fb(b, "k189_pierre", f, s - 2.0, s + 2.0, yc - 2.0, yc + 2.0, 0.0, 0.5)
		b.cyl("k189_or", Transform3D(rond, _p(f, s, yc, 0.56)), 1.75, 1.75, 0.12, 40)
		b.cyl("peinture_blanche", Transform3D(rond, _p(f, s, yc, 0.63)), 1.55, 1.55, 0.02, 40)
		for h in range(12):
			var an: float = h * TAU / 12.0
			var dir: Vector3 = _u3(f) * sin(an) + Vector3.UP * cos(an)
			b.box("metal_noir", Transform3D(_base(f) * Basis(Vector3(0, 0, 1), -an), _p(f, s, yc, 0.65) + dir * 1.3), Vector3(0.09 if h % 3 == 0 else 0.05, 0.34 if h % 3 == 0 else 0.2, 0.02))
		b.cyl("k189_or", Transform3D(rond, _p(f, s, yc, 0.68)), 0.1, 0.1, 0.06, 12)
		for grande in [false, true]:
			var lot := Kit.Batch.new()
			var lg: float = 1.25 if grande else 0.85
			lot.box("metal_noir", Transform3D(Basis(), Vector3(0, lg * 0.5 - 0.12, 0)), Vector3(0.07 if grande else 0.11, lg, 0.02))
			var mi := MeshInstance3D.new()
			mi.mesh = _maillage(lot)
			add_child(mi)
			var base := Transform3D(_base(f), _p(f, s, yc, 0.67 + (0.02 if grande else 0.0)))
			mi.global_transform = base
			_aiguilles.append([mi, base, grande])


# =================================================================== le toit

func _toit9() -> void:
	var cx: float = (float(R[0]) + float(R[2])) * 0.5
	var cz: float = (float(R[1]) + float(R[3])) * 0.5
	var yt: float = YS + 0.25
	b.box("beton", Transform3D(Basis(), IleScript.W(cx, cz, yt - 0.05)), Vector3(float(R[2]) - float(R[0]) - 0.8, 0.1, float(R[3]) - float(R[1]) - 0.8))
	# la verrière en pyramide, ses arêtes d'or, sa lumière
	var px: float = cx - 8.0
	var hx: float = 7.0
	var hz: float = 5.5
	var haut: float = 6.5
	var s: Vector3 = IleScript.W(px, cz, yt + haut)
	var c: Array = [IleScript.W(px - hx, cz - hz, yt + 0.4), IleScript.W(px + hx, cz - hz, yt + 0.4), IleScript.W(px + hx, cz + hz, yt + 0.4), IleScript.W(px - hx, cz + hz, yt + 0.4)]
	b.box("k189_pierre", Transform3D(Basis(), IleScript.W(px, cz, yt + 0.2)), Vector3(hx * 2.0 + 0.6, 0.4, hz * 2.0 + 0.6))
	for i in range(4):
		var p0: Vector3 = c[i]
		var p1: Vector3 = c[(i + 1) % 4]
		var nrm: Vector3 = (p1 - p0).cross(s - p0).normalized()
		if nrm.y < 0.0:
			nrm = -nrm
		b.tri("k189_verriere", [p0, p1, s], [nrm, nrm, nrm], [Vector2(0, 1), Vector2(1, 1), Vector2(0.5, 0)])
		b.tube("k189_or", p0, s, 0.09, 6)
		b.tube("k189_or", p0, p1, 0.07, 6)
		for j in [0.33, 0.66]:
			b.tube("k189_or", p0.lerp(s, j), p1.lerp(s, j), 0.04, 5)
			b.tube("k189_or", p0.lerp(p1, j), s, 0.035, 5)
	b.blob("k189_or", s, Vector3(0.25, 0.4, 0.25), 8)
	# l'aire de l'hélicoptère
	var hxp: float = cx + 11.0
	b.cyl_at("beton_clair", IleScript.W(hxp, cz, yt), 6.5, 6.5, 0.12, 40)
	b.cyl_at("peinture_jaune", IleScript.W(hxp, cz, yt + 0.12), 5.9, 5.9, 0.01, 40)
	b.cyl_at("beton_clair", IleScript.W(hxp, cz, yt + 0.125), 5.5, 5.5, 0.01, 40)
	for sg in [-1.0, 1.0]:
		b.box("peinture_blanche", Transform3D(Basis(), IleScript.W(hxp + sg * 1.2, cz, yt + 0.14)), Vector3(0.5, 0.01, 4.0))
	b.box("peinture_blanche", Transform3D(Basis(), IleScript.W(hxp, cz, yt + 0.14)), Vector3(2.4, 0.01, 0.5))
	for a in range(8):
		b.blob("neon_rouge" if a % 2 == 0 else "lampe_blanche", IleScript.W(hxp + cos(a * TAU / 8.0) * 6.2, cz + sin(a * TAU / 8.0) * 6.2, yt + 0.2), Vector3(0.1, 0.1, 0.1), 5)
	# les drapeaux (aux deux coins du quai), les machines
	for fx in [float(R[0]) + 1.5, float(R[2]) - 1.5]:
		var pied: Vector3 = IleScript.W(fx, float(R[1]) + 1.5, yt)
		b.cyl_at("in_inox", pied, 0.06, 0.04, 7.0, 8)
		b.blob("k189_or", pied + Vector3.UP * 7.05, Vector3(0.1, 0.1, 0.1), 6)
		for k in range(5):
			b.box("k189_vert" if k % 2 == 0 else "k189_or", Transform3D(Basis(Vector3.UP, 0.2 * sin(k * 1.3)), pied + Vector3(0.28 + k * 0.5, 6.1 + 0.06 * sin(k * 1.9), 0.0)), Vector3(0.5, 1.4, 0.03))
	Kit.ac_unit(b, IleScript.W(cx + 1.0, cz - 6.5, yt), 0.0)
	Kit.ac_unit(b, IleScript.W(cx + 2.6, cz - 6.5, yt), 0.0)
	Kit.water_tank(b, IleScript.W(cx + 1.8, cz + 6.0, yt))


func _lumieres9(F: Array) -> void:
	var fq: Dictionary = F[0]
	var fe: Dictionary = F[1]
	var lq: float = fq["l"]
	for s in [6.0, lq * 0.5, lq - 6.0]:
		N._light(_p(fq, s, Y0 + 3.2, 0.6), Color(1.0, 0.82, 0.55), 2.0, 11.0)
	N._light(_p(fe, float(fe["l"]) * 0.5, Y0 + 3.0, 1.6), Color(1.0, 0.85, 0.6), 2.4, 10.0)
	N._light(_p(F[3], float(F[3]["l"]) * 0.5, Y0 + 2.4, 1.2), Color(1.0, 0.9, 0.7), 1.8, 9.0)
	N._light(_p(F[2], lq * 0.5, Y0 + 3.4, 2.4), Color(1.0, 0.95, 0.85), 1.6, 9.0)


func _process(delta: float) -> void:
	super._process(delta)
	if _piece != null:
		_piece.rotate_y(delta * 0.5)
	# l'horloge : l'heure du jeu
	var h: float = float(N.call("hour")) if N.has_method("hour") else 0.0
	for q in _aiguilles:
		var tour: float = fposmod(h, 1.0) if bool(q[2]) else fposmod(h, 12.0) / 12.0
		(q[0] as Node3D).global_transform = (q[1] as Transform3D) * Transform3D(Basis(Vector3(0, 0, 1), -tour * TAU), Vector3.ZERO)
	var nuit: float = float(N.get("night")) if N.get("night") != null else 0.0
	if absf(nuit - _nuit9) > 0.004:
		_nuit9 = nuit
		if _ticker != null:
			_ticker.set_shader_parameter("nuit", nuit)
		if _verriere != null:
			_verriere.emission_energy_multiplier = lerpf(0.1, 2.2, nuit)
