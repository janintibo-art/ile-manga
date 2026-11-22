extends "res://scripts/neo/tour_kumo_v187.gd"
## V197 : la Tour Orion, le siège d'Orion Biotech, au sud de la Tour Hikari (entre elle et le boulevard). Le
## quatrième immeuble de Néopolis fait à la main (il reprend les outils de la Tour Kumo : le repère des
## façades, les vitres à pièce en profondeur). C'est la maison du vivant : du verre clair, des ailettes de
## bronze vert, et des jardins à tous les étages.
##   - les façades : un mur de verre rythmé d'ailettes de bronze vert ; à chaque plancher, une jardinière
##     qui court tout autour de la tour, ses arbustes et le lierre qui en retombe (un jardin vertical) ;
##   - le pied : deux étages de verre, le grand hall et son mur végétal (on le voit à travers la vitre) ;
##   - l'entrée (à l'ouest) : l'auvent blanc en feuille, ORION BIOTECH au-dessus ;
##   - devant la façade de l'ouest : l'Hélice, une double hélice de l'ADN haute de 26 m, ses deux brins
##     blancs et ses barreaux de quatre couleurs (les quatre lettres du vivant) ; elle tourne lentement
##     et luit doucement la nuit ;
##   - les étages des laboratoires, leur lumière froide ; l'étage du jardin, ses plantes derrière le verre ;
##   - le retrait (à 37 m) : la terrasse de bois, ses bacs d'arbres, son garde-corps de verre ;
##   - sur le toit : la serre de verre et ses plantes ; au-dessus de la façade nord, la Ceinture d'Orion :
##     trois étoiles alignées (Alnitak, Alnilam, Mintaka), plus vives la nuit.
## L'intérieur (tours_v153) n'a pas changé : on y entre par la même porte.

const SORTES_O := ["hangar", "bureaux", "cafeteria", "labo", "bureaux", "serveurs", "bureaux", "jardin", "cafeteria",
	"bureaux", "bureaux", "labo", "bureaux", "bureaux", "direction"]
const BASES := [Color(0.95, 0.35, 0.3), Color(1.0, 0.85, 0.3), Color(0.35, 0.95, 0.5), Color(0.35, 0.6, 1.0)]
const H_HELICE: float = 26.0          # la hauteur de l'Hélice
const R_HELICE: float = 0.6           # son rayon
const S_HELICE: float = 4.8           # (V198) sa place le long de la façade de l'ouest, entre deux points du trottoir
const D_HELICE: float = 1.15          # (V198) et sa distance au mur : le trottoir reste libre (le chemin des habitants, à 2,25 m)

var RO: Array = []
var RR: Array = []
var NEO: int = 15
var nb_jardinieres: int = 0
var nb_plantes: int = 0
var nb_barreaux: int = 0
var helice: Node3D                     # l'Hélice (elle tourne)
var _etoiles: StandardMaterial3D
var _brins: StandardMaterial3D
var _nuit_o: float = -1.0
var _pl: Array = [[], [], []]          # les arbustes des jardinières (trois sortes), en Transform3D


func build(neo: Node3D, batiment: Dictionary) -> void:
	N = neo
	bt = batiment
	name = "Tour_Orion_v197"
	Y0 = IleScript.Y0
	var segs: Array = bt["segs"]
	RO = [float(segs[0][0]), float(segs[0][1]), float(segs[0][2]), float(segs[0][3])]
	RR = [float(segs[1][0]), float(segs[1][1]), float(segs[1][2]), float(segs[1][3])] if segs.size() > 1 else RO
	R0 = RO
	R1 = RR
	YT = float(segs[0][5])
	YH = maxf(float(segs[segs.size() - 1][5]), _yo(NEO))
	_rng.seed = 19700
	_matieres()
	_matieres_o()
	b = Kit.Batch.new()
	bd = Kit.Batch.new()
	_vt = SurfaceTool.new()
	_vt.begin(Mesh.PRIMITIVE_TRIANGLES)
	_vtd = SurfaceTool.new()
	_vtd.begin(Mesh.PRIMITIVE_TRIANGLES)
	dedans = Node3D.new()
	dedans.name = "Orion_dedans"
	add_child(dedans)
	var F0: Array = _faces(RO)
	var F1: Array = _faces(RR)
	for f in range(4):
		_pied_o(F0[f], f)
		for k in range(2, NEO - 1):
			_etage_o(F0[f] if k < 10 else F1[f], k, f)
		_retrait_o(F0[f], F1[f])
		_direction_o(F1[f], f)
	_entree_o(F0[3])
	_helice_o(F0[3])
	_terrasse_o()
	_toit_o(F1[0])
	_plantes_o()
	b.commit(self, "Orion_dehors")
	bd.commit(dedans, "Orion_dedans_mesh")
	_pose_vitres(_vt, self, "Orion_vitres")
	_pose_vitres(_vtd, dedans, "Orion_vitres_dedans")
	_lumieres_o(F0)
	print("ILE_MANGA_V197: la Tour Orion (%d vitres, %d jardinières, %d plantes, %d barreaux d'hélice)" % [nb_vitres, nb_jardinieres, nb_plantes, nb_barreaux])


## La hauteur d'un plancher : le socle jusqu'au 9e, puis le retrait, posé sur la terrasse.
func _yo(k: int) -> float:
	return _yk(k) if k < 10 else YT + float(k - 10) * E


# =================================================================== les matières

func _matieres_o() -> void:
	if not Kit._mcache.has("k197_blanc"):
		var bl := StandardMaterial3D.new()
		bl.albedo_color = Color(0.9, 0.92, 0.9)
		bl.roughness = 0.4
		bl.metallic = 0.05
		Kit._mcache["k197_blanc"] = bl
		var br := StandardMaterial3D.new()
		br.albedo_color = Color(0.3, 0.38, 0.32)
		br.metallic = 0.75
		br.roughness = 0.35
		Kit._mcache["k197_bronze"] = br
		var al := StandardMaterial3D.new()
		al.albedo_color = Color(0.62, 0.66, 0.64)
		al.metallic = 0.6
		al.roughness = 0.42
		Kit._mcache["k197_alu"] = al
		var ja := StandardMaterial3D.new()
		ja.albedo_color = Color(0.2, 0.21, 0.2)
		ja.roughness = 0.75
		Kit._mcache["k197_jardiniere"] = ja
		var te := StandardMaterial3D.new()
		te.albedo_color = Color(0.2, 0.14, 0.09)
		te.roughness = 1.0
		Kit._mcache["k197_terre"] = te
		for def in [["k197_lierre", Color(0.13, 0.3, 0.1)], ["k197_lierre_clair", Color(0.25, 0.42, 0.14)]]:
			var li := StandardMaterial3D.new()
			li.albedo_color = def[1]
			li.roughness = 0.85
			Kit._mcache[def[0]] = li
		var bo := StandardMaterial3D.new()
		bo.albedo_color = Color(0.52, 0.36, 0.22)
		bo.roughness = 0.7
		Kit._mcache["k197_bois"] = bo
		var vv := StandardMaterial3D.new()
		vv.albedo_color = Color(0.75, 0.9, 0.85, 0.22)
		vv.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		vv.metallic = 0.2
		vv.roughness = 0.05
		vv.cull_mode = BaseMaterial3D.CULL_DISABLED
		Kit._mcache["k197_verre_serre"] = vv
		var hb := StandardMaterial3D.new()
		hb.albedo_color = Color(0.92, 0.96, 0.97)
		hb.roughness = 0.25
		hb.emission_enabled = true
		hb.emission = Color(0.6, 0.95, 1.0)
		hb.emission_energy_multiplier = 0.15
		Kit._mcache["k197_brin"] = hb
		for i in range(BASES.size()):
			Kit._mcache["k197_base_%d" % i] = Kit._glow(BASES[i], 0.6)
		Kit._mcache["k197_etoile"] = Kit._glow(Color(0.8, 0.9, 1.0), 2.0)
		Kit._mcache["k197_mur_vegetal"] = Kit._mcache["k197_lierre"]
	_brins = Kit._mcache["k197_brin"]
	_etoiles = Kit._mcache["k197_etoile"]


func _travees_o(f: Dictionary) -> int:
	return maxi(4, int(round(float(f["l"]) / 1.6)))


## Une jardinière le long d'une façade (de s0 à s1), au niveau du plancher y : le bac, la terre, les
## arbustes (posés à la fin, en lots), le lierre qui retombe.
func _jardiniere(f: Dictionary, s0: float, s1: float, y: float) -> void:
	_fb(b, "k197_jardiniere", f, s0, s1, y - 0.35, y + 0.42, 0.25, 0.95)
	_fb(b, "k197_terre", f, s0 + 0.05, s1 - 0.05, y + 0.42, y + 0.44, 0.3, 0.9)
	nb_jardinieres += 1
	var s: float = s0 + _rng.randf_range(0.3, 0.9)
	while s < s1 - 0.3:
		var sc: float = _rng.randf_range(0.45, 0.65)
		var v: int = _rng.randi() % 3
		var at: Vector3 = _p(f, s, y + 0.42, 0.6)
		(_pl[v] as Array).append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(sc, sc * _rng.randf_range(0.8, 1.1), sc)), at))
		nb_plantes += 1
		if _rng.randf() < 0.55:
			# le lierre qui retombe sur l'allège de l'étage du dessous
			# (V198 : des brins de feuilles en petits paquets décalés, qui s'affinent vers le bas, plutôt
			# qu'une plaque verte)
			var lg: float = _rng.randf_range(0.5, 1.7)
			var key: String = "k197_lierre" if _rng.randf() < 0.6 else "k197_lierre_clair"
			for _brin in range(_rng.randi_range(2, 3)):
				var sx: float = s + _rng.randf_range(-0.25, 0.25)
				var yy: float = y - 0.3
				var fin: float = y - 0.35 - lg * _rng.randf_range(0.6, 1.0)
				var lw: float = _rng.randf_range(0.09, 0.14)
				while yy > fin:
					var h: float = _rng.randf_range(0.14, 0.24)
					var d0: float = _rng.randf_range(0.93, 0.99)
					_fb(b, key, f, sx - lw, sx + lw, yy - h, yy, d0, d0 + _rng.randf_range(0.05, 0.1))
					yy -= h * 0.8
					sx += _rng.randf_range(-0.05, 0.05)
					lw = maxf(0.035, lw * 0.88)
		s += _rng.randf_range(0.7, 1.3)


# =================================================================== le pied (les deux premiers étages)

func _pied_o(f: Dictionary, face: int) -> void:
	var l: float = f["l"]
	var nt: int = _travees_o(f)
	var w: float = l / float(nt)
	var yh: float = Y0 + 2.0 * E
	_fb(b, "k197_bronze", f, 0.0, l, Y0, Y0 + 0.2, 0.0, 0.12)
	_fb(b, "k197_blanc", f, -0.15, l + 0.15, yh - 0.5, yh, 0.0, 0.45)
	var porte: Vector2 = Vector2(l * 0.5 - 2.2, l * 0.5 + 2.2) if face == 3 else Vector2(-9.0, -9.0)
	for i in range(nt + 1):
		var c: float = clampf(w * i, 0.1, l - 0.1)
		if c > porte.x and c < porte.y:
			continue
		_fb(b, "k197_bronze", f, c - 0.05, c + 0.05, Y0 + 0.2, yh - 0.5, 0.0, 0.35)
	for i2 in range(nt):
		var s0: float = w * i2 + 0.07
		var s1: float = w * (i2 + 1) - 0.07
		if s1 > porte.x and s0 < porte.y:
			continue
		_vitre(_vtd, f, s0, s1, Y0 + 0.2, yh - 0.5, -0.05, 0.55, 0.95, 0.1)
		bd.box("lampe_blanche", Transform3D(_base(f), _p(f, (s0 + s1) * 0.5, yh - 0.56, -1.2)), Vector3(w * 0.5, 0.03, 0.35))
	# le mur végétal du hall (dans le volume de la tour : on le voit à travers la vitre)
	if face == 3:
		for sg in [-1.0, 1.0]:
			var a: float = l * 0.5 + sg * 3.0
			var c2: float = l * 0.5 + sg * 6.5
			_fb(bd, "k197_mur_vegetal", f, minf(a, c2), maxf(a, c2), Y0 + 0.4, yh - 0.9, -2.6, -2.5)
			for j in range(14):
				var s3: float = lerpf(minf(a, c2) + 0.3, maxf(a, c2) - 0.3, _rng.randf())
				_fb(bd, "k197_lierre_clair", f, s3 - 0.25, s3 + 0.25, Y0 + 0.6 + _rng.randf() * (2.0 * E - 1.8), Y0 + 0.9 + _rng.randf() * (2.0 * E - 1.8), -2.5, -2.38)
	# la jardinière du premier étage (au-dessus du bandeau)
	_jardiniere(f, 0.3, l - 0.3, yh)


# =================================================================== les étages

func _etage_o(f: Dictionary, k: int, face: int) -> void:
	var l: float = f["l"]
	var nt: int = _travees_o(f)
	var w: float = l / float(nt)
	var y: float = _yo(k)
	var sorte: String = SORTES_O[k]
	# le nez du plancher, l'allège
	_fb(b, "k197_blanc", f, 0.0, l, y - 0.35, y + 0.15, 0.0, 0.2)
	_fb(b, "k197_alu", f, 0.0, l, y + 0.15, y + 0.85, -0.04, 0.02)
	for i in range(nt + 1):
		var c: float = clampf(w * i, 0.05, l - 0.05)
		# les ailettes de bronze, plus profondes une sur deux
		_fb(b, "k197_bronze", f, c - 0.04, c + 0.04, y + 0.15, y + E - 0.35, 0.0, 0.5 if i % 2 == 0 else 0.28)
	for i2 in range(nt):
		var s0: float = w * i2 + 0.05
		var s1: float = w * (i2 + 1) - 0.05
		if sorte == "serveurs":
			_fb(b, "k187_leds", f, s0, s1, y + 0.3, y + E - 0.45, -0.1, 0.02)
			continue
		var chaud: float = 0.35
		var p: float = 0.55
		if sorte == "labo":
			chaud = 0.05
			p = 0.8
		elif sorte == "cafeteria":
			chaud = 0.85
			p = 0.85
		elif sorte == "jardin":
			chaud = 0.6
			p = 0.75
		elif sorte == "direction":
			chaud = 0.7
			p = 0.9
		_vitre(_vt, f, s0, s1, y + 0.85, y + E - 0.35, 0.0, chaud, p, 0.5)
	if sorte == "jardin":
		for j in range(nt):
			if j % 2 == 0:
				_plante(Flora.bush(1970 + j), _p(f, w * (j + 0.5), y + 0.2, -0.9), Vector3(0.7, 0.8, 0.7), dedans)
	# la jardinière de cet étage (pas devant l'Hélice ni au-dessus de la porte)
	if face == 3 and k < 10:
		_jardiniere(f, 0.3, S_HELICE - 2.2, y)
		_jardiniere(f, S_HELICE + 2.2, l - 0.3, y)
	else:
		_jardiniere(f, 0.3, l - 0.3, y)


## Le dessus du socle (la terrasse, à 37 m) : la corniche, le garde-corps de verre, ses montants.
func _retrait_o(f0: Dictionary, _f1: Dictionary) -> void:
	var l: float = f0["l"]
	var y: float = _yk(10) - 0.35
	_fb(b, "k197_blanc", f0, -0.1, l + 0.1, y, YT + 0.05, 0.0, 0.5)
	_fb(b, "k197_verre_serre", f0, 0.0, l, YT + 0.05, YT + 1.15, 0.3, 0.33)
	_fb(b, "k197_alu", f0, 0.0, l, YT + 1.12, YT + 1.18, 0.27, 0.36)
	var n: int = int(l / 1.6)
	for i in range(n + 1):
		_fb(b, "k197_alu", f0, l * float(i) / float(n) - 0.025, l * float(i) / float(n) + 0.025, YT + 0.05, YT + 1.12, 0.29, 0.34)


## L'étage de la direction (le dernier) : du verre du sol au plafond ; la corniche, l'acrotère.
func _direction_o(f: Dictionary, face: int) -> void:
	var l: float = f["l"]
	var nt: int = _travees_o(f)
	var w: float = l / float(nt)
	var y: float = _yo(NEO - 1)
	_fb(b, "k197_blanc", f, 0.0, l, y - 0.35, y + 0.15, 0.0, 0.2)
	for i2 in range(nt):
		_vitre(_vt, f, w * i2 + 0.05, w * (i2 + 1) - 0.05, y + 0.15, y + E - 0.2, 0.0, 0.7, 0.9, 0.3)
	for i in range(nt + 1):
		_fb(b, "k197_bronze", f, clampf(w * i, 0.05, l - 0.05) - 0.04, clampf(w * i, 0.05, l - 0.05) + 0.04, y + 0.15, YH + 1.2, 0.0, 0.5)
	var yc: float = y + E - 0.2
	_fb(b, "k197_blanc", f, -0.3, l + 0.3, yc, yc + 0.35, 0.0, 0.7)
	_fb(b, "k197_alu", f, 0.0, l, yc + 0.35, YH + 1.2, -0.2, 0.0)
	_jardiniere(f, 0.3, l - 0.3, yc + 0.35)
	if face == 2:
		# le nom, face au boulevard
		_lettres_o("ORION", _p(f, l * 0.5, yc + 0.55, 0.75), _n3(f), 1.2, Color(0.85, 1.0, 0.9))


## Des lettres (le nom de la maison), tournées vers « face ».
func _lettres_o(txt: String, at: Vector3, face: Vector3, haut: float, col: Color) -> Label3D:
	var lb := Label3D.new()
	lb.text = txt
	lb.font_size = 128
	lb.outline_size = 0
	lb.pixel_size = haut / 128.0
	lb.modulate = col
	lb.shaded = false
	lb.double_sided = false
	lb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(lb)
	lb.global_transform = Transform3D(Basis(Vector3.UP, atan2(face.x, face.z)), at)
	return lb


# =================================================================== l'entrée (à l'ouest) : l'auvent en feuille

func _entree_o(f: Dictionary) -> void:
	var l: float = f["l"]
	var m: float = l * 0.5
	var yh: float = Y0 + 2.0 * E
	# le cadre, les portes de verre, le sas
	_fb(bd, "k197_bronze", f, m - 2.2, m - 1.8, Y0, yh - 0.5, -0.4, 0.1)
	_fb(bd, "k197_bronze", f, m + 1.8, m + 2.2, Y0, yh - 0.5, -0.4, 0.1)
	_fb(bd, "k197_bronze", f, m - 1.8, m + 1.8, Y0 + 3.6, yh - 0.5, -0.4, 0.05)
	_vitre(_vtd, f, m - 1.8, m + 1.8, Y0 + 3.7, yh - 0.55, -0.1, 0.5, 1.0, 0.0)
	for sg in [-1.0, 1.0]:
		_fb(bd, "verre", f, m + sg * 0.9 - 0.86, m + sg * 0.9 + 0.86, Y0, Y0 + 3.55, -0.32, -0.28)
		_fb(bd, "chrome", f, m + sg * 0.08 - 0.02, m + sg * 0.08 + 0.02, Y0 + 0.9, Y0 + 2.4, -0.27, -0.24)
	_fb(bd, "lampe_blanche", f, m - 1.5, m + 1.5, Y0 + 3.5, Y0 + 3.55, -2.0, -0.4)
	# l'auvent : une feuille blanche, sa nervure, posée sur deux bras de bronze
	var ya: float = Y0 + 4.2
	var nseg: int = 10
	for i in range(nseg):
		var t0: float = float(i) / float(nseg)
		var t1: float = float(i + 1) / float(nseg)
		var w0: float = 2.6 * sin(t0 * PI) + 0.15
		var w1: float = 2.6 * sin(t1 * PI) + 0.15
		var d0: float = 0.2 + t0 * 2.4
		var d1: float = 0.2 + t1 * 2.4
		var y0: float = ya + 0.25 * sin(t0 * PI)
		var y1: float = ya + 0.25 * sin(t1 * PI)
		b.quad("k197_blanc", [_p(f, m - w0, y0, d0), _p(f, m - w1, y1, d1), _p(f, m + w1, y1, d1), _p(f, m + w0, y0, d0)], Vector3.UP,
			[Vector2(0, 0), Vector2(0, 1), Vector2(1, 1), Vector2(1, 0)])
		b.quad("k197_blanc", [_p(f, m + w0, y0 - 0.04, d0), _p(f, m + w1, y1 - 0.04, d1), _p(f, m - w1, y1 - 0.04, d1), _p(f, m - w0, y0 - 0.04, d0)], Vector3.DOWN,
			[Vector2(0, 0), Vector2(0, 1), Vector2(1, 1), Vector2(1, 0)])
	b.tube("k197_bronze", _p(f, m, ya + 0.02, 0.2), _p(f, m, ya + 0.26, 1.4), 0.05, 6)
	b.tube("k197_bronze", _p(f, m, ya + 0.26, 1.4), _p(f, m, ya + 0.02, 2.6), 0.05, 6)
	for sg2 in [-1.0, 1.0]:
		b.tube("k197_bronze", _p(f, m + sg2 * 1.9, Y0 + 3.6, 0.15), _p(f, m + sg2 * 1.2, ya, 1.3), 0.045, 6)
	_fb(b, "lampe_blanche", f, m - 1.2, m + 1.2, ya - 0.06, ya - 0.04, 0.8, 1.9)
	# le nom de la maison, au-dessus de l'auvent
	_lettres_o("ORION BIOTECH", _p(f, m, Y0 + 5.3, 0.14), _n3(f), 0.55, Color(0.82, 1.0, 0.88))
	# deux grands bacs, de part et d'autre de la porte, leur arbre
	for sg3 in [-1.0, 1.0]:
		var c: Vector3 = _p(f, m + sg3 * 3.4, Y0, 1.3)
		b.box("k197_jardiniere", Transform3D(_base(f), c + Vector3.UP * 0.3), Vector3(1.2, 0.6, 1.2))
		b.box("k197_terre", Transform3D(_base(f), c + Vector3.UP * 0.61), Vector3(1.1, 0.02, 1.1))
		N._col(Transform3D(_base(f), c + Vector3.UP * 0.3), Vector3(1.2, 0.6, 1.2))
		var ar := MeshInstance3D.new()
		ar.mesh = Flora.tree(19700 + int(sg3 + 1.0), 3.0, 140)
		ar.visibility_range_end = 220.0
		add_child(ar)
		ar.global_transform = Transform3D(Basis(Vector3.UP, sg3), c + Vector3.UP * 0.6)


# =================================================================== l'Hélice (la double hélice de l'ADN)

func _helice_o(f: Dictionary) -> void:
	var s: float = S_HELICE
	var d: float = D_HELICE
	var c: Vector3 = _p(f, s, Y0, d)
	# le socle : un disque de pierre sombre, sa plaque
	b.cyl_at("k197_jardiniere", c, 0.7, 0.75, 0.45, 24)
	b.cyl_at("k197_bronze", c + Vector3.UP * 0.45, 0.68, 0.68, 0.04, 24)
	b.cyl_at("lampe_blanche", c + Vector3.UP * 0.49, 0.32, 0.32, 0.02, 16)
	N._col(Transform3D(Basis(), c + Vector3.UP * 3.0), Vector3(1.4, 6.0, 1.4))
	_lettres_o("L'HÉLICE", _p(f, s, Y0 + 0.26, d + 0.76), _n3(f), 0.13, Color(0.9, 1.0, 0.95))
	# les deux brins et leurs barreaux, dans leur nœud (il tourne)
	var lot := Kit.Batch.new()
	var pas: float = 0.34
	var n: int = int(H_HELICE / pas)
	var tours: float = 4.5
	var p_a: Vector3 = Vector3.ZERO
	var p_b: Vector3 = Vector3.ZERO
	for i in range(n + 1):
		var t: float = float(i) / float(n)
		var an: float = t * tours * TAU
		var y: float = t * H_HELICE
		var a := Vector3(cos(an) * R_HELICE, y, sin(an) * R_HELICE)
		var bb := Vector3(cos(an + PI * 0.8) * R_HELICE, y, sin(an + PI * 0.8) * R_HELICE)
		if i > 0:
			lot.tube("k197_brin", p_a, a, 0.075, 6)
			lot.tube("k197_brin", p_b, bb, 0.075, 6)
		if i % 2 == 1:
			# le barreau : deux moitiés de couleurs qui vont ensemble (A avec T, G avec C)
			var paire: int = int(float(i) * 0.5) % 4
			var k0: int = [0, 1, 2, 3][paire]
			var k1: int = [1, 0, 3, 2][paire]
			var mil: Vector3 = (a + bb) * 0.5
			lot.tube("k197_base_%d" % k0, a, mil, 0.045, 5)
			lot.tube("k197_base_%d" % k1, mil, bb, 0.045, 5)
			nb_barreaux += 1
		p_a = a
		p_b = bb
	# les sphères au bout des brins
	lot.blob("k197_brin", p_a, Vector3(0.14, 0.14, 0.14), 8)
	lot.blob("k197_brin", p_b, Vector3(0.14, 0.14, 0.14), 8)
	helice = MeshInstance3D.new()
	helice.name = "Orion_helice"
	(helice as MeshInstance3D).mesh = _maillage(lot)
	(helice as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(helice)
	helice.global_position = c + Vector3.UP * 0.5


# =================================================================== la terrasse (à 37 m)

func _terrasse_o() -> void:
	var x0: float = RO[0]
	var z0: float = RO[1]
	var x1: float = RO[2]
	var z1: float = RO[3]
	b.box("k197_bois", Transform3D(Basis(), IleScript.W((x0 + x1) * 0.5, (z0 + z1) * 0.5, YT - 0.05)), Vector3(x1 - x0 - 0.3, 0.1, z1 - z0 - 0.3))
	# les bacs d'arbres, aux quatre coins de la terrasse
	for q in [Vector2(x0 + 1.0, z0 + 1.0), Vector2(x1 - 1.0, z0 + 1.0), Vector2(x1 - 1.0, z1 - 1.0), Vector2(x0 + 1.0, z1 - 1.0)]:
		var c: Vector3 = IleScript.W(q.x, q.y, YT)
		b.box("k197_jardiniere", Transform3D(Basis(), c + Vector3.UP * 0.35), Vector3(1.3, 0.7, 1.3))
		var ar := MeshInstance3D.new()
		ar.mesh = Flora.tree(19710 + int(q.x * 3.0 + q.y), 3.2, 120)
		ar.visibility_range_end = 400.0
		add_child(ar)
		ar.global_transform = Transform3D(Basis(Vector3.UP, q.x), c + Vector3.UP * 0.7)


# =================================================================== le toit : la serre, la Ceinture d'Orion

func _toit_o(fn: Dictionary) -> void:
	var cx: float = (float(RR[0]) + float(RR[2])) * 0.5
	var cz: float = (float(RR[1]) + float(RR[3])) * 0.5
	var yt: float = YH
	b.box("beton", Transform3D(Basis(), IleScript.W(cx, cz, yt - 0.05)), Vector3(float(RR[2]) - float(RR[0]) - 0.6, 0.1, float(RR[3]) - float(RR[1]) - 0.6))
	# la serre : une nef de verre à deux pentes, sa charpente blanche, ses plantes
	var lx: float = minf(9.0, float(RR[2]) - float(RR[0]) - 4.0)
	var lz: float = 5.0
	var hm: float = 2.4
	var hf: float = 3.8
	var o: Vector3 = IleScript.W(cx, cz + 1.5, yt)
	var hx: float = lx * 0.5
	var hz: float = lz * 0.5
	for sg in [-1.0, 1.0]:
		b.quad("k197_verre_serre", [o + Vector3(-hx, 0, sg * hz), o + Vector3(hx, 0, sg * hz), o + Vector3(hx, hm, sg * hz), o + Vector3(-hx, hm, sg * hz)], Vector3(0, 0, sg),
			[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])
		b.quad("k197_verre_serre", [o + Vector3(-hx, hm, sg * hz), o + Vector3(hx, hm, sg * hz), o + Vector3(hx, hf, 0), o + Vector3(-hx, hf, 0)], Vector3(0, 1, sg).normalized(),
			[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])
		b.quad("k197_verre_serre", [o + Vector3(sg * hx, 0, -hz), o + Vector3(sg * hx, 0, hz), o + Vector3(sg * hx, hm, hz), o + Vector3(sg * hx, hm, -hz)], Vector3(sg, 0, 0),
			[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])
		b.tri("k197_verre_serre", [o + Vector3(sg * hx, hm, -hz), o + Vector3(sg * hx, hm, hz), o + Vector3(sg * hx, hf, 0)], [Vector3(sg, 0, 0), Vector3(sg, 0, 0), Vector3(sg, 0, 0)],
			[Vector2(0, 1), Vector2(1, 1), Vector2(0.5, 0)])
	var nf: int = int(lx / 1.5)
	for i in range(nf + 1):
		var x: float = -hx + lx * float(i) / float(nf)
		for sg2 in [-1.0, 1.0]:
			b.tube("k197_blanc", o + Vector3(x, 0, sg2 * hz), o + Vector3(x, hm, sg2 * hz), 0.04, 4)
			b.tube("k197_blanc", o + Vector3(x, hm, sg2 * hz), o + Vector3(x, hf, 0), 0.04, 4)
	b.tube("k197_blanc", o + Vector3(-hx, hf, 0), o + Vector3(hx, hf, 0), 0.05, 4)
	for j in range(7):
		(_pl[j % 3] as Array).append(Transform3D(Basis(Vector3.UP, float(j)).scaled(Vector3(0.9, 1.1, 0.9)), o + Vector3(-hx + 0.8 + float(j) * (lx - 1.6) / 6.0, 0.0, -0.8 + 1.6 * float(j % 2))))
		nb_plantes += 1
	# la Ceinture d'Orion : trois étoiles alignées, au-dessus de la façade nord (le mât, ses bras)
	var l: float = fn["l"]
	for i2 in range(3):
		var s: float = l * (0.32 + 0.18 * float(i2))
		var y: float = YH + 1.6 + 0.55 * float(i2)
		var e: Vector3 = _p(fn, s, y, -0.6)
		b.tube("k197_alu", _p(fn, s, YH + 1.2, -0.6), e + Vector3.DOWN * 0.22, 0.04, 5)
		b.blob("k197_etoile", e, Vector3(0.22, 0.22, 0.22), 10)
	# l'antenne et son feu rouge ; les machines
	var an: Vector3 = IleScript.W(float(RR[2]) - 1.5, float(RR[3]) - 1.5, yt)
	b.cyl_at("in_inox", an, 0.1, 0.04, 7.0, 8)
	b.blob("neon_rouge", an + Vector3.UP * 7.1, Vector3(0.11, 0.11, 0.11), 6)
	Kit.ac_unit(b, IleScript.W(float(RR[0]) + 2.0, float(RR[3]) - 2.0, yt), 0.0)
	Kit.ac_unit(b, IleScript.W(float(RR[0]) + 3.6, float(RR[3]) - 2.0, yt), 0.0)


## Les arbustes des jardinières, en trois lots (un par sorte d'arbuste) : peu d'objets à dessiner.
func _plantes_o() -> void:
	for v in range(3):
		var xs: Array = _pl[v]
		if xs.is_empty():
			continue
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = Flora.bush(1975 + v)
		mm.instance_count = xs.size()
		var inv: Transform3D = global_transform.affine_inverse()
		for i in range(xs.size()):
			mm.set_instance_transform(i, inv * (xs[i] as Transform3D))
		var mi := MultiMeshInstance3D.new()
		mi.name = "Orion_jardins_%d" % v
		mi.multimesh = mm
		add_child(mi)


func _lumieres_o(F: Array) -> void:
	var fw: Dictionary = F[3]
	N._light(_p(fw, float(fw["l"]) * 0.5, Y0 + 3.6, 2.0), Color(0.95, 1.0, 0.92), 2.2, 9.0)
	N._light(_p(fw, S_HELICE, Y0 + 1.2, 2.4), Color(0.6, 0.95, 1.0), 1.8, 8.0)
	N._light(_p(F[2], float(F[2]["l"]) * 0.5, Y0 + 2.8, 1.2), Color(1.0, 0.95, 0.85), 1.6, 8.0)


func _process(delta: float) -> void:
	super._process(delta)
	if helice != null:
		helice.rotate_y(delta * 0.12)
	# (l'heure du jeu : les étoiles et l'Hélice se voient de loin, même quand on n'est pas à Néopolis)
	var nuit: float = float(N.night_k(N.hour())) if N.has_method("night_k") else 0.0
	if absf(nuit - _nuit_o) > 0.004:
		_nuit_o = nuit
		var k: float = smoothstep(0.25, 0.8, nuit)
		if _etoiles != null:
			_etoiles.emission_energy_multiplier = lerpf(1.2, 6.0, k)
		if _brins != null:
			_brins.emission_energy_multiplier = lerpf(0.15, 1.1, k)
		for i in range(BASES.size()):
			var m: Variant = Kit._mcache.get("k197_base_%d" % i)
			if m is StandardMaterial3D:
				(m as StandardMaterial3D).emission_energy_multiplier = lerpf(0.6, 2.2, k)
