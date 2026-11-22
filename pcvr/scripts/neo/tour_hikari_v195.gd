extends "res://scripts/neo/tour_kumo_v187.gd"
## V195 : la Tour Hikari, le siège de Hikari Systèmes (« hikari » : la lumière), à l'ouest de la Tour Kumo, sur
## le quai. Le troisième immeuble de Néopolis fait à la main (il reprend les outils de la Tour Kumo : le repère
## des façades, les vitres à pièce en profondeur). C'est la maison de la lumière : tout y est blanc, verre
## sombre et fibres qui brillent.
##   - les façades : un mur de verre bleu nuit, rythmé de lames blanches qui ondulent d'un étage à l'autre
##     (on dirait une vague qui monte le long de la tour) ; à chaque plancher, une fibre de lumière ; aux
##     quatre angles, des fibres sur toute la hauteur : des impulsions de lumière y montent sans fin
##     (shaders/fibre_v195), discrètes le jour, éclatantes la nuit ;
##   - le pied : deux étages de verre, la grande vitrine du laboratoire ;
##   - l'entrée (à l'ouest) : le tunnel de lumière, six portiques blancs de plus en plus grands, leurs fibres
##     qui filent vers la porte, le nom de la maison et son anneau de lumière au-dessus ;
##   - sur le quai : le Prisme, une sculpture de verre sur son socle noir ; un projecteur y envoie un rayon
##     blanc, qui en ressort en sept couleurs et vient peindre le spectre sur la façade ;
##   - dans la ruelle (vers la Tour Kumo) : les gaines de fibre, trois tuyaux de couleur qui montent au toit ;
##   - à l'angle sud-ouest : la grande lame noire, HIKARI en lettres de lumière ;
##   - l'étage des serveurs et ses lumières qui clignotent ; l'étage du jardin, ses plantes derrière le verre ;
##   - tout en haut : la couronne de lames blanches, son anneau de fibre ; sur le toit, le phare : la nuit,
##     un faisceau de lumière monte droit dans le ciel.
## L'intérieur (tours_v153) n'a pas changé : on y entre par la même porte.

const NEH: int = 12                    # douze étages
const SORTES_H := ["labo", "bureaux", "cafeteria", "bureaux", "bureaux", "serveurs", "bureaux", "jardin", "cafeteria", "bureaux", "bureaux", "direction"]
const SPECTRE := [Color(1.0, 0.12, 0.1), Color(1.0, 0.5, 0.05), Color(1.0, 0.92, 0.1), Color(0.15, 1.0, 0.25), Color(0.1, 0.85, 1.0), Color(0.15, 0.3, 1.0), Color(0.62, 0.2, 1.0)]

var RH: Array = []
var YSH: float = 0.0                   # le dessus du dernier étage
var _faisceau: StandardMaterial3D      # le phare du toit
var _anneau: Node3D                    # l'anneau de lumière de l'entrée (il tourne doucement)
var _nuit_h: float = -1.0
var nb_lames: int = 0
var nb_fibres: int = 0


func build(neo: Node3D, batiment: Dictionary) -> void:
	N = neo
	bt = batiment
	name = "Tour_Hikari_v195"
	Y0 = IleScript.Y0
	var segs: Array = bt["segs"]
	RH = [float(segs[0][0]), float(segs[0][1]), float(segs[0][2]), float(segs[0][3])]
	R0 = RH
	R1 = RH
	YSH = Y0 + float(NEH) * E
	YT = YSH
	YH = maxf(float(segs[0][5]), YSH + 0.4)
	_rng.seed = 19500
	_matieres()
	_matieres_h()
	b = Kit.Batch.new()
	bd = Kit.Batch.new()
	_vt = SurfaceTool.new()
	_vt.begin(Mesh.PRIMITIVE_TRIANGLES)
	_vtd = SurfaceTool.new()
	_vtd.begin(Mesh.PRIMITIVE_TRIANGLES)
	dedans = Node3D.new()
	dedans.name = "Hikari_dedans"
	add_child(dedans)
	var F: Array = _faces(RH)
	for f in range(4):
		_pied_h(F[f], f)
		for k in range(2, NEH - 1):
			_etage_h(F[f], k, f)
		_direction_h(F[f], f)
		_fibres_h(F[f])
	_entree_h(F[3])
	_prisme_h(F[0])
	_gaines_h(F[1])
	_lame_h(F[3])
	_toit_h()
	b.commit(self, "Hikari_dehors")
	bd.commit(dedans, "Hikari_dedans_mesh")
	_pose_vitres(_vt, self, "Hikari_vitres")
	_pose_vitres(_vtd, dedans, "Hikari_vitres_dedans")
	_lumieres_h(F)
	print("ILE_MANGA_V195: la Tour Hikari (%d vitres, %d lames, %d fibres)" % [nb_vitres, nb_lames, nb_fibres])


# =================================================================== les matières

func _matieres_h() -> void:
	if not Kit._mcache.has("k195_blanc"):
		var bl := StandardMaterial3D.new()
		bl.albedo_color = Color(0.9, 0.92, 0.94)
		bl.roughness = 0.32
		bl.metallic = 0.1
		bl.clearcoat_enabled = true
		bl.clearcoat = 0.4
		Kit._mcache["k195_blanc"] = bl
		var nv := StandardMaterial3D.new()
		nv.albedo_color = Color(0.035, 0.05, 0.1)
		nv.metallic = 0.65
		nv.roughness = 0.12
		Kit._mcache["k195_nuit"] = nv
		var gr := StandardMaterial3D.new()
		gr.albedo_color = Color(0.15, 0.16, 0.18)
		gr.metallic = 0.7
		gr.roughness = 0.38
		Kit._mcache["k195_graphite"] = gr
		var fi := ShaderMaterial.new()
		fi.shader = load("res://shaders/fibre_v195.gdshader")
		Kit._mcache["k195_fibre"] = fi
		var tu := ShaderMaterial.new()
		tu.shader = fi.shader
		tu.set_shader_parameter("couleur_a", Color(0.85, 0.95, 1.0))
		tu.set_shader_parameter("couleur_b", Color(0.2, 0.8, 1.0))
		tu.set_shader_parameter("axe", Vector3(1.0, 0.0, 0.0))        # (vers la porte, à l'ouest : vers l'est)
		tu.set_shader_parameter("periode", 3.2)
		tu.set_shader_parameter("vitesse", 2.6)
		tu.set_shader_parameter("largeur", 0.45)
		Kit._mcache["k195_tunnel"] = tu
		var pr := StandardMaterial3D.new()
		pr.albedo_color = Color(0.82, 0.94, 1.0, 0.28)
		pr.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		pr.metallic = 0.3
		pr.roughness = 0.03
		pr.rim_enabled = true
		pr.rim = 0.8
		pr.emission_enabled = true
		pr.emission = Color(0.7, 0.9, 1.0)
		pr.emission_energy_multiplier = 0.25
		pr.cull_mode = BaseMaterial3D.CULL_DISABLED
		Kit._mcache["k195_prisme"] = pr
		for i in range(SPECTRE.size()):
			Kit._mcache["k195_spectre_%d" % i] = Kit._glow(SPECTRE[i], 1.5)
		for def in [["k195_gaine_cyan", Color(0.1, 0.85, 1.0)], ["k195_gaine_rose", Color(1.0, 0.25, 0.7)], ["k195_gaine_ambre", Color(1.0, 0.62, 0.15)]]:
			Kit._mcache[def[0]] = Kit._glow(def[1], 0.7)
		var fa := StandardMaterial3D.new()
		fa.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		fa.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		fa.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		fa.cull_mode = BaseMaterial3D.CULL_DISABLED
		fa.albedo_color = Color(0, 0, 0)
		Kit._mcache["k195_faisceau"] = fa
	_faisceau = Kit._mcache["k195_faisceau"]
	for k in ["k195_fibre", "k195_tunnel"]:
		if not (Kit._mcache[k] in _mats_nuit):
			_mats_nuit.append(Kit._mcache[k])


## Des lettres de lumière (le nom de la maison), tournées vers « face ».
func _lettres(txt: String, at: Vector3, face: Vector3, haut: float, col: Color) -> Label3D:
	var l := Label3D.new()
	l.text = txt
	l.font_size = 128
	l.outline_size = 0
	l.pixel_size = haut / 128.0
	l.modulate = col
	l.shaded = false
	l.double_sided = false
	l.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(l)
	l.global_transform = Transform3D(Basis(Vector3.UP, atan2(face.x, face.z)), at)
	return l


func _travees_h(f: Dictionary) -> int:
	return maxi(4, int(round(float(f["l"]) / 1.75)))


## Une lame blanche, debout sur la façade (de y0 à y1), tournée d'un angle (l'onde).
func _lame(f: Dictionary, s: float, y0: float, y1: float, an: float, prof: float = 0.55) -> void:
	b.box("k195_blanc", Transform3D(_base(f) * Basis(Vector3.UP, an), _p(f, s, (y0 + y1) * 0.5, prof * 0.5)), Vector3(0.08, y1 - y0, prof))
	nb_lames += 1


func _onde(k: int, i: int) -> float:
	return 0.42 * sin(float(k) * 0.45 + float(i) * 0.6)


# =================================================================== le pied (les deux premiers étages)

func _pied_h(f: Dictionary, face: int) -> void:
	var l: float = f["l"]
	var nt: int = _travees_h(f)
	var w: float = l / float(nt)
	var yh: float = Y0 + 2.0 * E
	_fb(b, "k195_graphite", f, 0.0, l, Y0, Y0 + 0.25, 0.0, 0.15)
	_fb(b, "k195_blanc", f, -0.2, l + 0.2, yh - 0.6, yh, 0.0, 0.5)           # (le bandeau du laboratoire)
	_fb(b, "k195_graphite", f, 0.0, l, yh - 0.62, yh - 0.6, 0.0, 0.5)
	var porte: Vector2 = Vector2(l * 0.5 - 2.4, l * 0.5 + 2.4) if face == 3 else Vector2(-9.0, -9.0)
	for i in range(nt + 1):
		var c: float = clampf(w * i, 0.12, l - 0.12)
		if c > porte.x and c < porte.y:
			continue
		_fb(b, "k195_blanc", f, c - 0.06, c + 0.06, Y0 + 0.25, yh - 0.6, 0.0, 0.3)
	for i2 in range(nt):
		var s0: float = w * i2 + 0.08
		var s1: float = w * (i2 + 1) - 0.08
		if s1 > porte.x and s0 < porte.y:
			continue
		# le grand vitrage du laboratoire (deux étages), sa traverse
		_vitre(_vtd, f, s0, s1, Y0 + 0.25, yh - 0.6, -0.05, 0.25, 0.97, 0.15)
		_fb(b, "k195_graphite", f, s0, s1, Y0 + E - 0.04, Y0 + E + 0.04, -0.02, 0.06)
		bd.box("lampe_blanche", Transform3D(_base(f), _p(f, (s0 + s1) * 0.5, yh - 0.66, -1.2)), Vector3(w * 0.6, 0.03, 0.4))


# =================================================================== les étages (2 à 10)

func _etage_h(f: Dictionary, k: int, face: int) -> void:
	var l: float = f["l"]
	var nt: int = _travees_h(f)
	var w: float = l / float(nt)
	var y: float = _yk(k)
	var sorte: String = SORTES_H[k]
	# le nez du plancher (blanc), l'allège de verre bleu nuit
	_fb(b, "k195_blanc", f, 0.0, l, y, y + 0.32, 0.0, 0.18)
	_fb(b, "k195_nuit", f, 0.0, l, y + 0.32, y + 0.95, -0.02, 0.04)
	for i in range(nt + 1):
		_lame(f, clampf(w * i, 0.05, l - 0.05), y + 0.32, y + E, _onde(k, i))
	for i2 in range(nt):
		var s0: float = w * i2 + 0.06
		var s1: float = w * (i2 + 1) - 0.06
		if sorte == "serveurs":
			_fb(b, "k187_leds", f, s0, s1, y + 0.4, y + E - 0.1, -0.1, 0.02)
			continue
		var chaud: float = 0.25
		var p: float = 0.5
		if sorte == "cafeteria":
			chaud = 0.85
			p = 0.85
		elif sorte == "jardin":
			chaud = 0.6
			p = 0.75
		_vitre(_vt, f, s0, s1, y + 0.95, y + E, 0.02, chaud, p, 0.5)
	if sorte == "jardin" and face == 0:
		# les plantes, derrière le verre
		for j in range(1, nt, 2):
			_plante(Flora.bush(1950 + j), _p(f, w * (j + 0.5), y + 0.35, -0.9), Vector3(0.65, 0.65, 0.65), dedans)


## L'étage de la direction (le dernier) : du verre du sol au plafond ; la couronne de lames au-dessus.
func _direction_h(f: Dictionary, face: int) -> void:
	var l: float = f["l"]
	var nt: int = _travees_h(f)
	var w: float = l / float(nt)
	var y: float = _yk(NEH - 1)
	_fb(b, "k195_blanc", f, 0.0, l, y, y + 0.32, 0.0, 0.18)
	for i2 in range(nt):
		_vitre(_vt, f, w * i2 + 0.06, w * (i2 + 1) - 0.06, y + 0.32, y + E - 0.15, 0.02, 0.7, 0.9, 0.3)
	# la corniche, l'acrotère de verre sombre ; la couronne : les lames montent 3 m au-dessus du toit
	_fb(b, "k195_blanc", f, -0.25, l + 0.25, YSH - 0.15, YSH + 0.2, 0.0, 0.6)
	_fb(b, "k195_nuit", f, 0.0, l, YSH + 0.2, YH + 1.0, -0.3, 0.0)
	for i in range(nt + 1):
		var c: float = clampf(w * i, 0.05, l - 0.05)
		_lame(f, c, y + 0.32, YSH - 0.15, _onde(NEH - 1, i))
		_lame(f, c, YSH + 0.2, YH + 3.0 + 0.6 * sin(float(i) * 0.9 + float(face)), _onde(NEH, i), 0.45)
	_fb(b, "k195_fibre", f, 0.0, l, YH + 0.96, YH + 1.02, 0.0, 0.04)
	nb_fibres += 1
	if face == 0:
		# le nom, face au quai (on le voit en débarquant)
		_lettres("HIKARI", _p(f, l * 0.5, YH + 0.25, 0.05), _n3(f), 1.4, Color(0.75, 0.97, 1.0))


## Les fibres : une à chaque plancher, et aux deux angles de la façade, sur toute la hauteur.
func _fibres_h(f: Dictionary) -> void:
	var l: float = f["l"]
	for k in range(2, NEH):
		_fb(b, "k195_fibre", f, 0.0, l, _yk(k) + 0.03, _yk(k) + 0.08, 0.18, 0.2)
		nb_fibres += 1
	_fb(b, "k195_fibre", f, 0.0, l, Y0 + 2.0 * E - 0.7, Y0 + 2.0 * E - 0.64, 0.48, 0.52)
	for s in [0.16, l - 0.16]:
		_fb(b, "k195_fibre", f, s - 0.03, s + 0.03, Y0 + 2.0 * E, YH + 1.0, 0.56, 0.6)
		nb_fibres += 1


# =================================================================== l'entrée (à l'ouest) : le tunnel de lumière

func _entree_h(f: Dictionary) -> void:
	var l: float = f["l"]
	var m: float = l * 0.5
	var yh: float = Y0 + 2.0 * E
	# le cadre de la porte, les portes de verre, le sas éclairé
	_fb(bd, "k195_graphite", f, m - 2.4, m - 1.9, Y0, yh - 0.6, -0.4, 0.1)
	_fb(bd, "k195_graphite", f, m + 1.9, m + 2.4, Y0, yh - 0.6, -0.4, 0.1)
	_fb(bd, "k195_graphite", f, m - 1.9, m + 1.9, Y0 + 3.6, yh - 0.6, -0.4, 0.05)
	_vitre(_vtd, f, m - 1.9, m + 1.9, Y0 + 3.7, yh - 0.65, -0.1, 0.3, 1.0, 0.0)
	for sg in [-1.0, 1.0]:
		_fb(bd, "verre", f, m + sg * 0.95 - 0.9, m + sg * 0.95 + 0.9, Y0, Y0 + 3.55, -0.32, -0.28)
		_fb(bd, "chrome", f, m + sg * 0.08 - 0.02, m + sg * 0.08 + 0.02, Y0 + 0.9, Y0 + 2.4, -0.27, -0.24)
	_fb(bd, "k195_blanc", f, m - 1.9, m + 1.9, Y0, Y0 + 0.01, -2.2, -0.3)
	_fb(bd, "lampe_blanche", f, m - 1.6, m + 1.6, Y0 + 3.5, Y0 + 3.55, -2.0, -0.4)
	# le tunnel : six portiques, de plus en plus grands vers la rue ; leurs fibres filent vers la porte
	for j in range(6):
		var d: float = 0.35 + float(j) * 0.44
		var hw: float = 1.85 + float(j) * 0.1
		var hh: float = 3.5 + float(j) * 0.14
		for sg2 in [-1.0, 1.0]:
			_fb(b, "k195_blanc", f, m + sg2 * hw - 0.07, m + sg2 * hw + 0.07, Y0, Y0 + hh, d - 0.07, d + 0.07)
			_fb(b, "k195_tunnel", f, m + sg2 * (hw - 0.075) - 0.01, m + sg2 * (hw - 0.075) + 0.01, Y0 + 0.05, Y0 + hh - 0.08, d - 0.05, d + 0.05)
		_fb(b, "k195_blanc", f, m - hw - 0.07, m + hw + 0.07, Y0 + hh, Y0 + hh + 0.14, d - 0.07, d + 0.07)
		_fb(b, "k195_tunnel", f, m - hw + 0.08, m + hw - 0.08, Y0 + hh - 0.02, Y0 + hh, d - 0.05, d + 0.05)
	# le sol du tunnel : une dalle blanche, deux fibres qui mènent à la porte
	_fb(b, "k195_blanc", f, m - 1.8, m + 1.8, Y0, Y0 + 0.015, 0.0, 2.65)
	for sg3 in [-1.2, 1.2]:
		_fb(b, "k195_tunnel", f, m + sg3 - 0.03, m + sg3 + 0.03, Y0 + 0.015, Y0 + 0.02, 0.0, 2.65)
	# le nom de la maison, et son anneau de lumière (un rayon qui le traverse)
	_lettres("HIKARI SYSTÈMES", _p(f, m, Y0 + 5.15, 0.12), _n3(f), 0.5, Color(0.85, 0.97, 1.0))
	var lot := Kit.Batch.new()
	var r: float = 0.85
	for a in range(24):
		var a0: float = float(a) * TAU / 24.0
		var a1: float = float(a + 1) * TAU / 24.0
		lot.tube("neon_blanc", Vector3(cos(a0) * r, sin(a0) * r, 0.0), Vector3(cos(a1) * r, sin(a1) * r, 0.0), 0.045, 6)
	lot.box("neon_cyan", Transform3D(Basis(Vector3(0, 0, 1), 0.35), Vector3.ZERO), Vector3(2.6, 0.05, 0.05))
	_anneau = MeshInstance3D.new()
	(_anneau as MeshInstance3D).mesh = _maillage(lot)
	(_anneau as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_anneau)
	_anneau.global_transform = Transform3D(_base(f), _p(f, m, Y0 + 6.55, 0.35))


# =================================================================== sur le quai : le Prisme

func _prisme_h(f: Dictionary) -> void:
	var l: float = f["l"]
	var d: float = 1.7
	var sp: float = l - 6.0                # le Prisme (vers l'ouest)
	var sj: float = l - 2.2                # le projecteur
	# le socle noir, sa plaque
	var c: Vector3 = _p(f, sp, Y0, d)
	b.cyl_at("k195_graphite", c, 0.85, 0.85, 0.7, 6)
	b.cyl_at("k195_blanc", c + Vector3.UP * 0.7, 0.9, 0.9, 0.05, 6)
	N._col(Transform3D(Basis(), c + Vector3.UP * 0.45), Vector3(1.6, 0.9, 1.6))
	_lettres("LE PRISME", _p(f, sp, Y0 + 0.45, d + 0.86), _n3(f), 0.14, Color(0.9, 0.95, 1.0))
	# le prisme de verre (debout, à trois faces), ses arêtes
	var y0: float = Y0 + 0.75
	var y1: float = Y0 + 2.45
	var tri: Array = []
	for i in range(3):
		var an: float = float(i) * TAU / 3.0 + 0.5
		tri.append(Vector2(cos(an), sin(an)) * 0.62)
	for i2 in range(3):
		var p0: Vector2 = tri[i2]
		var p1: Vector2 = tri[(i2 + 1) % 3]
		var a: Vector3 = c + Vector3(p0.x, y0 - Y0, p0.y)
		var bb: Vector3 = c + Vector3(p1.x, y0 - Y0, p1.y)
		var nrm: Vector3 = Vector3(p0.x + p1.x, 0.0, p0.y + p1.y).normalized()
		b.quad("k195_prisme", [a, bb, bb + Vector3.UP * (y1 - y0), a + Vector3.UP * (y1 - y0)], nrm, [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])
		b.tube("chrome", a, a + Vector3.UP * (y1 - y0), 0.012, 4)
		b.tube("chrome", a + Vector3.UP * (y1 - y0), bb + Vector3.UP * (y1 - y0), 0.012, 4)
	for yy in [y0, y1]:
		b.tri("k195_prisme", [c + Vector3(tri[0].x, yy - Y0, tri[0].y), c + Vector3(tri[1].x, yy - Y0, tri[1].y), c + Vector3(tri[2].x, yy - Y0, tri[2].y)],
			[Vector3.UP, Vector3.UP, Vector3.UP], [Vector2(0, 0), Vector2(1, 0), Vector2(0.5, 1)])
	# le projecteur : sa borne, sa lentille ; le rayon blanc
	var pj: Vector3 = _p(f, sj, Y0, d)
	b.cyl_at("k195_graphite", pj, 0.22, 0.26, 1.2, 12)
	b.box("k195_graphite", Transform3D(_base(f), pj + Vector3.UP * 1.45), Vector3(0.55, 0.36, 0.36))
	var hy: float = Y0 + 1.6
	b.cyl("lampe_blanche", Transform3D(_base(f) * Basis(Vector3(0, 0, 1), PI * 0.5), _p(f, sj - 0.29, Y0 + 1.45, d)), 0.11, 0.11, 0.03, 12)
	N._col(Transform3D(Basis(), pj + Vector3.UP * 0.7), Vector3(0.6, 1.4, 0.6))
	var entree: Vector3 = _p(f, sp + 0.5, hy, d)
	b.tube("neon_blanc", _p(f, sj - 0.3, Y0 + 1.45, d), entree, 0.02, 6)
	# les sept couleurs : du prisme jusqu'à la façade, où elles peignent le spectre
	for i3 in range(SPECTRE.size()):
		var t: float = float(i3) / float(SPECTRE.size() - 1)
		var s_mur: float = sp - 1.6 - t * 2.4
		var sortie: Vector3 = _p(f, sp - 0.4, hy - 0.05 + t * 0.1, d - 0.12)
		var mur: Vector3 = _p(f, s_mur, Y0 + 1.35 + t * 0.5, 0.21)
		var key: String = "k195_spectre_%d" % i3
		b.tube(key, sortie, mur, 0.011, 4)
		_fb(b, key, f, s_mur - 0.11, s_mur + 0.11, Y0 + 1.0 + t * 0.5, Y0 + 1.7 + t * 0.5, 0.2, 0.205)


# =================================================================== la ruelle (vers la Tour Kumo) : les gaines de fibre

func _gaines_h(f: Dictionary) -> void:
	var l: float = f["l"]
	var keys: Array = ["k195_gaine_cyan", "k195_gaine_rose", "k195_gaine_ambre"]
	for i in range(3):
		var s: float = l - 3.0 - float(i) * 0.32
		b.tube(keys[i], _p(f, s, Y0 + 0.4, 0.35), _p(f, s, YH + 0.6, 0.35), 0.09, 8)
		b.tube(keys[i], _p(f, s, Y0 + 0.4, 0.35), _p(f, s, Y0 + 0.4, 1.2) + Vector3.DOWN * 0.3, 0.09, 8)
	_fb(b, "k195_graphite", f, l - 3.95, l - 2.05, Y0, Y0 + 0.7, 0.9, 1.5)            # (la chambre de tirage)
	for gy in range(10):
		_fb(b, "metal_noir", f, l - 3.95, l - 2.05, Y0 + 3.0 + gy * 4.2, Y0 + 3.08 + gy * 4.2, 0.1, 0.5)
	for i2 in range(4):
		Kit.ac_unit(b, _p(f, 3.0 + i2 * 1.6, Y0 + 2.0 * E + 0.5 + (i2 % 2) * 3.5, 0.5), atan2(_n3(f).x, _n3(f).z))


# =================================================================== à l'angle sud-ouest : la lame HIKARI

func _lame_h(f: Dictionary) -> void:
	var l: float = f["l"]
	var s: float = l - 1.2
	var y0: float = Y0 + 2.0 * E + 1.2
	var nb: int = 6
	var pas: float = 1.65
	var y1: float = y0 + float(nb) * pas + 0.6
	_fb(b, "k195_graphite", f, s - 0.14, s + 0.14, y0, y1, 0.2, 1.6)
	_fb(b, "k195_fibre", f, s - 0.15, s + 0.15, y0, y1, 1.6, 1.64)
	var lettres: String = "HIKARI"
	for sg in [-1.0, 1.0]:
		var face: Vector3 = _u3(f) * sg
		for i in range(nb):
			var yc: float = y1 - 0.3 - (float(i) + 0.5) * pas
			_lettres(lettres[i], _p(f, s + sg * 0.15, yc - 0.6, 0.9), face, 1.25, Color(0.6, 0.95, 1.0))


# =================================================================== le toit : le phare

func _toit_h() -> void:
	var cx: float = (float(RH[0]) + float(RH[2])) * 0.5
	var cz: float = (float(RH[1]) + float(RH[3])) * 0.5
	var yt: float = YH
	b.box("beton", Transform3D(Basis(), IleScript.W(cx, cz, yt - 0.05)), Vector3(float(RH[2]) - float(RH[0]) - 0.7, 0.1, float(RH[3]) - float(RH[1]) - 0.7))
	# le phare : le tambour, sa lentille, l'anneau de fibre ; le faisceau (la nuit)
	var ph: Vector3 = IleScript.W(cx, cz, yt)
	b.cyl_at("k195_graphite", ph, 1.4, 1.2, 1.1, 24)
	b.cyl_at("k195_blanc", ph + Vector3.UP * 1.1, 1.25, 1.25, 0.1, 24)
	b.cyl_at("lampe_blanche", ph + Vector3.UP * 1.2, 0.7, 0.55, 0.12, 20)
	b.cyl_at("k195_fibre", ph + Vector3.UP * 0.55, 1.42, 1.42, 0.06, 24)
	var fx := MeshInstance3D.new()
	var cy := CylinderMesh.new()
	cy.top_radius = 0.9
	cy.bottom_radius = 0.45
	cy.height = 150.0
	cy.radial_segments = 12
	cy.cap_top = false
	cy.cap_bottom = false
	fx.mesh = cy
	fx.material_override = _faisceau
	fx.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	fx.name = "Hikari_faisceau"
	add_child(fx)
	fx.global_position = ph + Vector3.UP * (1.3 + 75.0)
	# l'antenne et son feu rouge ; les machines
	var an: Vector3 = IleScript.W(float(RH[0]) + 2.0, float(RH[1]) + 2.0, yt)
	b.cyl_at("in_inox", an, 0.12, 0.05, 9.0, 8)
	b.blob("neon_rouge", an + Vector3.UP * 9.1, Vector3(0.12, 0.12, 0.12), 6)
	Kit.ac_unit(b, IleScript.W(cx + 5.0, cz - 5.5, yt), 0.0)
	Kit.ac_unit(b, IleScript.W(cx + 6.6, cz - 5.5, yt), 0.0)
	Kit.water_tank(b, IleScript.W(cx - 5.0, cz + 5.0, yt))


func _lumieres_h(F: Array) -> void:
	var fw: Dictionary = F[3]
	var fq: Dictionary = F[0]
	N._light(_p(fw, float(fw["l"]) * 0.5, Y0 + 3.0, 1.4), Color(0.8, 0.93, 1.0), 2.4, 10.0)
	N._light(_p(fq, float(fq["l"]) - 5.5, Y0 + 2.4, 2.2), Color(0.7, 0.9, 1.0), 1.8, 8.0)
	N._light(_p(fq, 5.0, Y0 + 3.0, 1.0), Color(0.85, 0.93, 1.0), 1.6, 9.0)
	N._light(_p(F[1], float(F[1]["l"]) - 3.0, Y0 + 2.6, 1.2), Color(1.0, 0.85, 0.7), 1.4, 7.0)


func _process(delta: float) -> void:
	super._process(delta)
	if _anneau != null:
		_anneau.rotate_object_local(Vector3(0, 0, 1), delta * 0.25)
	# (l'heure du jeu, et pas la nuit de la ville : le faisceau se voit de loin, même quand on n'est pas à Néopolis)
	var nuit: float = float(N.night_k(N.hour())) if N.has_method("night_k") else 0.0
	if absf(nuit - _nuit_h) > 0.004:
		_nuit_h = nuit
		if _faisceau != null:
			var k: float = smoothstep(0.25, 0.8, nuit) * 0.38
			_faisceau.albedo_color = Color(0.45 * k, 0.8 * k, 1.0 * k)
