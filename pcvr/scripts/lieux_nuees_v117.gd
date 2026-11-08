extends RefCounted
## V117 : les grands lieux de la Cité des Nuées qu'on visite (comme les maisons, maisons_v81 : devant
## la porte, « E : entrer dans… », un fondu, et l'on est dedans). Chacun a sa coque (shell), son
## décor, ses gens au travail, ce qui bouge et ce qu'on y fait ; certains changent la nuit :
##  - le Café Cumulus (la machine à nuages, les lustres-nuages, les chouquettes ; Gustave le soir) ;
##  - l'Atelier des Inventeurs (le parapluie-ascenseur, le petit drone, les plans ; Mireille le soir) ;
##  - la Maison du Conseil (l'hémicycle, la carte de l'île en hologramme, le Livre des Vents, le buste
##    de Séraphin Altaïr, le vote du jour) ;
##  - l'Institut des Vents (la soufflerie et ses rubans, la chambre à nuages, les écrans, le bulletin) ;
##  - la Tour du Zénith (le hall, l'ascenseur de verre ; au sommet, la salle panoramique et ses
##    longues-vues) ;
##  - le cœur des Sustentateurs (sous le pavillon : la grande salle creusée dans la roche, l'anneau qui
##    tourne autour du cœur de cristal, les pupitres) ;
##  - la Libellule (la nacelle du dirigeable de la Capitaine Zéphyrine : ses baies, ses fauteuils, la
##    passerelle) ;
##  - la Capitainerie du Port des Nuées (la radio, le tableau des départs, le coin des planeurs ;
##    Zéphyrine le soir).
## Les portes sont notées par la ville (nuees_ville_v113.portes117) dans azur_kit_v56.PORTES_V81, avec
## le style « nuees_lieu », leur « histoire » (le lieu) et ce qui s'affiche devant la porte (« entrer »).
## Les aides (matières, animations, gens, conversations) sont celles des grands lieux de Hautefond
## (lieux_hautefond_v116 : L).

const Kit = preload("res://scripts/azur_kit_v56.gd")
const I = preload("res://scripts/maisons_iles_v82.gd")
const L = preload("res://scripts/lieux_hautefond_v116.gd")

const STYLE := "nuees_lieu"
## L'étage (le sommet de la Tour du Zénith) : une deuxième pièce, plus loin derrière la première.
const UPZ: float = -40.0
## La taille de chaque lieu (largeur, profondeur).
const TAILLES := {"nu_cafe": Vector2(10.0, 8.0), "nu_atelier": Vector2(11.0, 8.5), "nu_conseil": Vector2(14.0, 11.0),
	"nu_institut": Vector2(13.0, 9.0), "nu_zenith": Vector2(12.0, 12.0), "nu_machines": Vector2(17.0, 17.0),
	"nu_libellule": Vector2(4.4, 12.0), "nu_capitainerie": Vector2(9.0, 7.0)}
## Ce qui s'affiche devant la porte.
const ENTRER := {"nu_cafe": "E : entrer au Café Cumulus", "nu_atelier": "E : entrer dans l'Atelier des Inventeurs",
	"nu_conseil": "E : entrer dans la Maison du Conseil", "nu_institut": "E : entrer à l'Institut des Vents",
	"nu_zenith": "E : entrer dans la Tour du Zénith", "nu_machines": "E : descendre au cœur des Sustentateurs",
	"nu_libellule": "E : monter à bord de la Libellule", "nu_capitainerie": "E : entrer dans la Capitainerie"}


static func is_lieu(style: String) -> bool:
	return style == STYLE


static func taille(cur: Dictionary) -> Vector2:
	return TAILLES.get(str(cur.get("histoire", "")), Vector2(8.0, 7.0))


static func has(sc: String) -> bool:
	return TAILLES.has(sc)


## Les portes des grands lieux : « lieu » -> [porte, dehors].
static func register(portes: Dictionary) -> int:
	var n: int = 0
	for lieu in TAILLES:
		var e: Variant = portes.get(lieu, null)
		if not (e is Array) or (e as Array).size() < 2:
			continue
		var out: Vector3 = e[1]
		out.y = 0.0
		if out.length() < 0.01:
			continue
		var tl: Vector2 = TAILLES[lieu]
		Kit.PORTES_V81.append({"door": e[0], "out": out.normalized(), "w": tl.x, "d": tl.y, "style": STYLE, "floors": 1, "owner": "",
			"histoire": str(lieu), "entrer": str(ENTRER[lieu])})
		n += 1
	return n


# =================================================================== la coque de la pièce

static func shell(M) -> void:
	var R = M.R
	R.pal = (R.pal as Dictionary).duplicate()
	match str(M.ctx.get("scenario", "")):
		"nu_cafe":
			R.H = 3.6
			L._mur(M, "sol", "nuees/bois_blond.png", Color(1, 1, 1), 2.6)
			L._mur(M, "mur", "nuees/enduit_blanc.png", Color(1.0, 0.99, 0.97), 3.0)
			L._mur(M, "bas", "nuees/enduit_blanc.png", Color(1.0, 0.99, 0.97), 3.0)
			R.shell()
		"nu_atelier":
			R.H = 4.0
			R.shell()
		"nu_conseil":
			R.H = 5.0
			R.shell()
		"nu_institut":
			R.H = 4.2
			R.shell()
		"nu_zenith":
			R.H = 4.4
			_rond117(M, 6.0, 4.4, 24, [4, 8, 16, 20], true)
		"nu_machines":
			R.H = 7.0
			L._mur(M, "mur", "montjoie/roche_crocs.png", Color(0.62, 0.64, 0.7), 3.0)
			L._mur(M, "sol", "nuees/dalle_claire.png", Color(0.5, 0.52, 0.56), 2.0)
			L._mur(M, "plafond", "montjoie/roche_crocs.png", Color(0.42, 0.44, 0.5), 3.0)
			R.pal["porte"] = "acier"          # sous la terre : une porte d'acier, pas de ciel derrière
			_rond117(M, 8.2, 7.0, 32, [], false)
		"nu_libellule":
			R.H = 2.7
			R.pal["fenetre"] = "aucune"
			L._mur(M, "sol", "nuees/bois_blond.png", Color(1, 1, 1), 2.0)
			L._mur(M, "mur", "nuees/composite.png", Color(1, 1, 1), 2.0)
			L._mur(M, "bas", "nuees/composite.png", Color(0.95, 0.95, 0.96), 2.0)
			L._mur(M, "plafond", "nuees/composite.png", Color(0.94, 0.94, 0.95), 2.0)
			R.shell()
		"nu_capitainerie":
			R.H = 3.4
			L._mur(M, "sol", "nuees/bois_blond.png", Color(1, 1, 1), 2.4)
			R.shell()
		_:
			R.shell()


## Une pièce ronde des Nuées (centre au milieu de la pièce) : le sol, le plafond, un mur à facettes (sans
## soubassement ; une plinthe blanche si « plinthe »), la porte au milieu du côté +Z, des baies vitrées
## sur les facettes « fenetres », les collisions, la lumière.
static func _rond117(M, r: float, h: float, seg: int, fenetres: Array, plinthe: bool) -> void:
	var R = M.R
	var k = R.kit
	var cw: Vector3 = R.P(0, 0, 0)
	k.disc(Transform3D(Basis(), cw), r + 0.35, "sol", seg, float((R.pal["sol"] as Array)[2]))
	k.col_box(Transform3D(Basis(), cw + Vector3.DOWN * 0.25), Vector3(2.0 * r + 1.0, 0.5, 2.0 * r + 1.0))
	k.disc(Transform3D(Basis(Vector3.RIGHT, PI), cw + Vector3.UP * h), r + 0.35, "plafond", seg, float((R.pal["plafond"] as Array)[2]))
	k.col_box(Transform3D(Basis(), cw + Vector3.UP * (h + 0.35)), Vector3(2.0 * r + 1.0, 0.5, 2.0 * r + 1.0))
	var chord: float = 2.0 * r * sin(PI / seg) + 0.06
	var tm: float = float((R.pal["mur"] as Array)[2])
	for i in range(seg):
		var am: float = PI * 0.5 + TAU * i / seg
		var dirv := Vector3(cos(am), 0, sin(am))
		var xf := Transform3D(Basis.looking_at(-dirv, Vector3.UP), cw + dirv * (r + 0.15))
		if i == 0:
			k.box(xf * Transform3D(Basis(), Vector3(0, (h + 2.2) * 0.5, 0)), Vector3(chord, h - 2.2, 0.3), "mur", tm)
			var side: float = (chord - 1.1) * 0.5
			if side > 0.04:
				for sx in [-1.0, 1.0]:
					k.box(xf * Transform3D(Basis(), Vector3(sx * (0.55 + side * 0.5), 1.1, 0)), Vector3(side, 2.2, 0.3), "mur", tm)
		else:
			k.box(xf * Transform3D(Basis(), Vector3(0, h * 0.5, 0)), Vector3(chord, h, 0.3), "mur", tm)
			if plinthe:
				k.box(xf * Transform3D(Basis(), Vector3(0, 0.06, -0.16)), Vector3(chord, 0.12, 0.03), "ceramique", 1.0)
		k.col_box(xf * Transform3D(Basis(), Vector3(0, h * 0.5, 0)), Vector3(chord, h + 0.4, 0.3))
	for fi in fenetres:
		L._fenetre_ronde(M, Vector3.ZERO, r + 0.02, seg, 90.0 + 360.0 * float(fi) / seg, 1.22, "baie")
	R._entry_door(1.1, 2.2, r + 0.1)
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.95, 0.88)
	l.light_energy = 1.2
	l.omni_range = r * 2.2
	l.omni_attenuation = 0.9
	l.shadow_enabled = R.pc and not M.main.xr_active
	l.light_specular = 0.3
	M.room.add_child(l)
	l.global_position = cw + Vector3.UP * (h - 0.6)
	R.lights.append(l)


# =================================================================== les aides des Nuées

## Toujours dans la même pièce ? (après un délai, on a pu sortir… ou entrer dans un autre lieu)
static func _la(M, room0) -> bool:
	return is_instance_valid(room0) and M.inside and M.room == room0


## Le composite blanc satiné (les meubles, les coques), l'acier brossé, une lumière (diodes).
static func _blanc(M) -> StandardMaterial3D:
	var m: StandardMaterial3D = L._m(M, "blanc117", Color(0.94, 0.95, 0.95), 0.3, 0.0)
	return m


static func _acier(M) -> StandardMaterial3D:
	return L._m(M, "acier117", Color(0.74, 0.76, 0.78), 0.3, 0.75)


static func _led(M, c: Color, e: float = 1.6) -> StandardMaterial3D:
	return L._m(M, "led117_%s_%d" % [c.to_html(false), int(e * 10.0)], c, 0.4, 0.0, e)


## Un écran (une image qui luit : une carte, un radar, des mesures).
static func _ecran(M, tex: String, e: float = 0.9) -> StandardMaterial3D:
	var key: String = "ecran117_" + tex
	if not M.ctx.has("mats116"):
		M.ctx["mats116"] = {}
	var cache: Dictionary = M.ctx["mats116"]
	if cache.has(key):
		return cache[key]
	var m := StandardMaterial3D.new()
	var p: String = "res://assets/textures/" + tex
	if ResourceLoader.exists(p):
		var t: Texture2D = load(p)
		m.albedo_texture = t
		m.emission_enabled = true
		m.emission_texture = t
		m.emission = Color(1, 1, 1)
		m.emission_energy_multiplier = e
	else:
		m.albedo_color = Color(0.1, 0.2, 0.35)
	m.roughness = 0.35
	cache[key] = m
	return m


## Un panneau plat (un écran, une affiche) : xf = son centre ; il regarde +Z.
static func _panneau(M, xf: Transform3D, size: Vector2, mat: Material) -> MeshInstance3D:
	var qm := QuadMesh.new()
	qm.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = qm
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	M.room.add_child(mi)
	mi.global_transform = xf
	return mi


## Une table ronde blanche sur un pied d'acier (x, z : repère de la pièce).
static func _table_blanche(M, x: float, z: float, r: float = 0.45, h: float = 0.74) -> void:
	var R = M.R
	var k = R.kit
	k.cyl(R.L(x, h - 0.03, z), r, r, 0.03, "ceramique", 22)
	k.cyl(R.L(x, 0.0, z), 0.04, 0.04, h - 0.03, "argent", 8, false)
	k.cyl(R.L(x, 0.0, z), 0.26, 0.28, 0.03, "argent", 16)
	k.col_box(R.L(x, h * 0.5, z), Vector3(r * 1.5, h, r * 1.5))
	R.reserve(x, z, r * 2.0 + 0.2, r * 2.0 + 0.2)


## Une chaise blanche (coque moulée, pieds d'acier) qui regarde yaw.
static func _chaise_blanche(M, x: float, z: float, yaw: float, renversee: bool = false, y: float = 0.0) -> void:
	var R = M.R
	var k = R.kit
	var xf: Transform3D = R.L(x, y, z, yaw)
	if renversee:
		xf = xf * Transform3D(Basis(Vector3.RIGHT, PI), Vector3(0, 0.95, 0))
	k.box(xf * Transform3D(Basis(), Vector3(0, 0.45, 0)), Vector3(0.44, 0.05, 0.42), "ceramique", 1.0)
	k.box(xf * Transform3D(Basis(Vector3.RIGHT, -0.12), Vector3(0, 0.76, -0.2)), Vector3(0.42, 0.5, 0.04), "ceramique", 1.0)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			k.box(xf * Transform3D(Basis(), Vector3(sx * 0.18, 0.22, sz * 0.17)), Vector3(0.025, 0.45, 0.025), "argent", 1.0)


## Un lustre-nuage : des boules blanches qui luisent doucement, pendues à un fil (le Café Cumulus).
static func _lustre_nuage(M, at: Vector3, s: float = 1.0) -> Node3D:
	var n: Node3D = I._node(M, at)
	var lum: StandardMaterial3D = L._m(M, "nuage117", Color(1.0, 0.99, 0.96), 0.9, 0.0, 0.9)
	for e in [[0.0, 0.0, 0.0, 0.26], [0.24, -0.04, 0.05, 0.2], [-0.25, -0.03, -0.04, 0.21], [0.1, 0.1, -0.12, 0.18], [-0.08, 0.08, 0.14, 0.17], [0.36, -0.08, -0.08, 0.13]]:
		L._mesh(n, I._sph(float(e[3]) * s), lum, Transform3D(Basis(), Vector3(float(e[0]), float(e[1]), float(e[2])) * s))
	L._mesh(n, L._cylm(0.004, 0.004, M.R.H, 4), _acier(M), Transform3D(Basis(), Vector3(0, M.R.H * 0.5, 0)))
	return n


## De petits nuages en particules (la machine à nuages, la chambre à nuages, la vapeur des boissons).
static func _brume(M, at: Vector3, ext: Vector3, n: int, monte: float, size: float = 0.12, vie: float = 3.0) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = n
	p.lifetime = vie
	p.preprocess = vie
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = ext
	p.direction = Vector3.UP
	p.spread = 25.0
	p.gravity = Vector3(0, monte, 0)
	p.initial_velocity_min = 0.02
	p.initial_velocity_max = 0.08
	p.scale_amount_min = size * 0.6
	p.scale_amount_max = size * 1.3
	var qm := QuadMesh.new()
	qm.size = Vector2.ONE
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.billboard_keep_scale = true
	m.albedo_color = Color(1, 1, 1, 0.55)
	m.albedo_texture = M.R.dot_texture()
	qm.material = m
	p.mesh = qm
	M.room.add_child(p)
	p.global_position = at
	return p


## Une bouffée : la brume crache un peu plus, puis se calme.
static func _bouffee(M, p: CPUParticles3D, n: int, secondes: float) -> void:
	if not is_instance_valid(p):
		return
	var n0: int = p.amount
	var v0: float = p.initial_velocity_max
	p.amount = n
	p.initial_velocity_max = v0 * 4.0
	var room0 = M.room
	await M.get_tree().create_timer(secondes).timeout
	if not _la(M, room0) or not is_instance_valid(p):
		return
	p.amount = n0
	p.initial_velocity_max = v0


## Une plante en pot blanc (dans les Nuées : des pots blancs, pas de terre cuite).
static func _plante(M, x: float, z: float, s: float = 1.0) -> void:
	var R = M.R
	var k = R.kit
	k.cyl(R.L(x, 0, z), 0.2 * s, 0.17 * s, 0.42 * s, "ceramique", 14)
	k.cyl(R.L(x, 0.41 * s, z), 0.19 * s, 0.19 * s, 0.01, "terreau", 14)
	var rng: RandomNumberGenerator = L._r(M)
	for i in range(9):
		var a: float = TAU * i / 9.0 + rng.randf()
		var lx: Transform3D = R.L(x, 0.4 * s, z) * Transform3D(Basis(Vector3.UP, -a) * Basis(Vector3.RIGHT, rng.randf_range(0.25, 0.75)), Vector3.ZERO)
		k.box(lx * Transform3D(Basis(), Vector3(0, 0.35 * s, 0)), Vector3(0.16 * s, 0.7 * s, 0.02), "feuillage", 1.0)
	k.col_box(R.L(x, 0.4 * s, z), Vector3(0.4 * s, 0.8 * s, 0.4 * s))
	R.reserve(x, z, 0.6 * s, 0.6 * s)


## Une barre (un pied, un bras, une tige) de a à b, de rayon r, dans une matière de la pièce.
static func _beam(M, a: Vector3, b: Vector3, r: float, key: String) -> void:
	var d: Vector3 = b - a
	if d.length() < 0.001:
		return
	var bs := Basis(Quaternion(Vector3.UP, d.normalized())) if absf(d.normalized().dot(Vector3.UP)) < 0.999 else Basis()
	M.R.kit.cyl(Transform3D(bs, a), r, r, d.length(), key, 8, false)


## Une boule (une chouquette, un micro), dans une matière de la pièce.
static func _ball(M, at: Vector3, r: float, key: String) -> void:
	L._mesh(I._node(M, at), I._sph(r), M.R.mat(key))


## Le panorama tout autour (le sommet du Zénith) : un ruban circulaire tourné vers l'intérieur, de la
## hauteur y0 à y1 autour de c, qui montre le ciel de v0 (en haut) à v1 (en bas) ; un tour = 360°.
static func _bande(M, c: Vector3, r: float, y0: float, y1: float, v0: float, v1: float, seg: int = 64) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(seg):
		var a0: float = TAU * i / seg
		var a1: float = TAU * (i + 1) / seg
		var p00 := Vector3(cos(a0) * r, y1, sin(a0) * r)
		var p10 := Vector3(cos(a1) * r, y1, sin(a1) * r)
		var p01 := Vector3(cos(a0) * r, y0, sin(a0) * r)
		var p11 := Vector3(cos(a1) * r, y0, sin(a1) * r)
		var u0: float = float(i) / seg
		var u1: float = float(i + 1) / seg
		for e in [[p00, Vector2(u0, 0)], [p10, Vector2(u1, 0)], [p01, Vector2(u0, 1)], [p10, Vector2(u1, 0)], [p11, Vector2(u1, 1)], [p01, Vector2(u0, 1)]]:
			st.set_normal(-Vector3((e[0] as Vector3).x, 0, (e[0] as Vector3).z).normalized())
			st.set_uv(e[1])
			st.add_vertex(e[0])
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	var m: StandardMaterial3D = M.R.vue_mat(0.0, 1.0, v0, v1)
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	M.room.add_child(mi)
	mi.global_position = c
	return mi


## Un plateau qu'on porte (le serveur, le steward) : un nœud sur le corps.
static func _plateau(f: Node, c: Color = Color(0.96, 0.95, 0.92)) -> Node3D:
	var n := Node3D.new()
	f.npc.add_child(n)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.85, 0.86, 0.88)
	m.metallic = 0.8
	m.roughness = 0.3
	L._mesh(n, L._cylm(0.18, 0.18, 0.02, 16), m, Transform3D(Basis(), Vector3(0.0, 1.05, 0.34)))
	var m2 := StandardMaterial3D.new()
	m2.albedo_color = c
	m2.roughness = 0.25
	for k2 in range(2):
		L._mesh(n, L._cylm(0.035, 0.03, 0.08, 10), m2, Transform3D(Basis(), Vector3(-0.07 + k2 * 0.14, 1.1, 0.34)))
	return n


# =================================================================== construire

static func build(M, sc: String) -> void:
	match sc:
		"nu_cafe":
			_cafe(M)
		"nu_atelier":
			_atelier(M)
		"nu_conseil":
			_conseil(M)
		"nu_institut":
			_institut(M)
		"nu_zenith":
			_zenith(M)
		"nu_machines":
			_machines(M)
		"nu_libellule":
			_libellule(M)
		"nu_capitainerie":
			_capitainerie(M)


# =================================================================== le Café Cumulus

const MENU_CUMULUS := "L'ARDOISE DU CAFÉ CUMULUS. Lait de nuage (avec sa moustache). Thé des sommets. Jus de soleil. Chocolat qui chuchote. Chouquettes du four solaire, croissants du matin. Pas une goutte d'alcool : ici, on se régale de la vue, et elle est offerte."


## Le Café Cumulus : le comptoir et sa machine à nuages (un globe de verre où tourne un petit nuage),
## la vitrine des chouquettes, les tables blanches, les lustres-nuages ; le jour, la serveuse, le
## serveur et les habitués ; la nuit, les chaises sur les tables, et Gustave qui fait ses comptes.
static func _cafe(M) -> void:
	var R = M.R
	var k = R.kit
	var nuit: bool = L._nuit(M)
	# le comptoir (le long du mur du fond, à droite), son plateau de bois blond, ses étagères
	k.box(R.L(1.8, 0.52, -3.0), Vector3(4.6, 1.04, 0.7), "ceramique", 1.0)
	k.box(R.L(1.8, 1.06, -2.98), Vector3(4.8, 0.05, 0.82), "bois", 1.0)
	k.box(R.L(1.8, 0.08, -2.62), Vector3(4.6, 0.16, 0.04), "argent", 1.0)
	k.col_box(R.L(1.8, 0.55, -3.0), Vector3(4.6, 1.1, 0.7))
	R.reserve(1.8, -3.2, 5.0, 1.6)
	for y in [1.55, 2.0, 2.45]:
		R.etagere_murale(2.2, y, -3.86, 0, 3.2, "ceramique", 9)
	R.tableau(4.95, 1.8, 0.0, -90, 1.0, 0.75, 0)
	# la machine à nuages : un socle d'acier, un globe de verre, le petit nuage qui tourne dedans
	var mc: Vector3 = R.P(0.0, 1.08, -3.0)
	k.cyl(Transform3D(Basis(), mc), 0.22, 0.26, 0.3, "argent", 18)
	k.cyl(Transform3D(Basis(), mc + Vector3(0, 0.3, 0)), 0.12, 0.12, 0.05, "cuivre", 14)
	for s in [-1.0, 1.0]:
		k.cyl(Transform3D(Basis(Vector3.BACK, s * 0.5), mc + Vector3(s * 0.2, 0.42, 0.0)), 0.025, 0.025, 0.4, "cuivre", 8, false)
	var verre: StandardMaterial3D = L._m(M, "globe117", Color(0.85, 0.95, 1.0, 0.22), 0.05, 0.0, 0.0, true)
	var globe: Node3D = I._node(M, mc + Vector3(0, 0.66, 0))
	L._mesh(globe, I._sph(0.32), verre)
	var petit: Node3D = I._node(M, mc + Vector3(0, 0.66, 0))
	var nm: StandardMaterial3D = L._m(M, "nuage117", Color(1.0, 0.99, 0.96), 0.9, 0.0, 0.9)
	for e in [[0.0, 0.0, 0.0, 0.11], [0.1, -0.02, 0.03, 0.08], [-0.1, -0.01, -0.02, 0.085], [0.04, 0.05, -0.06, 0.07]]:
		L._mesh(petit, I._sph(float(e[3])), nm, Transform3D(Basis(), Vector3(float(e[0]), float(e[1]), float(e[2]))))
	L._tourne(M, petit, Vector3.UP, 0.9)
	var brume: CPUParticles3D = _brume(M, mc + Vector3(0, 0.66, 0), Vector3(0.14, 0.1, 0.14), 14, 0.0, 0.07, 2.5)
	# la vitrine des chouquettes et des croissants
	var vt: Vector3 = R.P(2.9, 1.09, -3.0)
	k.box(Transform3D(Basis(), vt + Vector3(0, 0.2, 0)), Vector3(1.1, 0.4, 0.55), "verre", 1.0)
	k.box(Transform3D(Basis(), vt + Vector3(0, 0.005, 0)), Vector3(1.1, 0.01, 0.55), "ceramique", 1.0)
	for i in range(12):
		_ball(M, vt + Vector3(-0.42 + (i % 6) * 0.17, 0.06, -0.12 + floori(i / 6.0) * 0.18), 0.055, "pain")
	for j in range(4):
		k.cyl(Transform3D(Basis(Vector3.BACK, PI * 0.5) * Basis(Vector3.UP, j * 0.4), vt + Vector3(-0.3 + j * 0.2, 0.18, 0.1)), 0.035, 0.05, 0.16, "pain", 8)
	# l'ardoise du menu (mur de gauche, entre les deux baies)
	k.box(R.L(-4.94, 1.75, 0.0, 90), Vector3(1.2, 0.85, 0.03), "noir", 1.0)
	k.box(R.L(-4.92, 1.75, 0.0, 90) * Transform3D(Basis(), Vector3(0, 0, 0.02)), Vector3(1.3, 0.95, 0.02), "bois", 1.0, 32)
	for li in range(5):
		k.box(R.L(-4.915, 2.02 - li * 0.13, -0.1 + (li % 2) * 0.08, 90) * Transform3D(Basis(), Vector3(0, 0, 0.03)), Vector3(0.7 - (li % 3) * 0.15, 0.025, 0.005), "ceramique", 1.0)
	R.mark_wall(-5.0, 1.75, 0.0, 0.7)
	# les tables, les chaises (renversées sur les tables, la nuit), les lustres-nuages
	var tables: Array = [Vector2(-2.9, -1.3), Vector2(-3.0, 1.8), Vector2(2.6, -0.7), Vector2(3.2, 2.0)]
	for t in tables:
		_table_blanche(M, t.x, t.y)
		for s2 in [-1.0, 1.0]:
			if nuit:
				_chaise_blanche(M, t.x + s2 * 0.18, t.y, 90.0 * s2, true, 0.74)
			else:
				_chaise_blanche(M, t.x + s2 * 0.64, t.y, -90.0 * s2)
	for e2 in [Vector3(-2.9, 2.35, -1.3), Vector3(-3.0, 2.35, 1.8), Vector3(2.9, 2.35, 0.6), Vector3(0.0, 2.6, 0.2)]:
		var lu: Node3D = _lustre_nuage(M, R.P(e2.x, e2.y, e2.z), 1.0 if e2.x != 0.0 else 1.3)
		L._balance(M, lu, Vector3.FORWARD, 0.02, 5.0 + e2.x, e2.z)
	L._lampe(M, R.P(-2.9, 2.2, 0.2), Color(1.0, 0.93, 0.82), 0.8 if not nuit else 0.35, 5.0)
	L._lampe(M, R.P(2.9, 2.2, 0.6), Color(1.0, 0.93, 0.82), 0.8 if not nuit else 0.35, 5.0)
	_plante(M, -4.4, -3.4, 1.2)
	_plante(M, 4.45, 3.3, 1.1)
	_plante(M, -4.4, 3.3, 0.9)
	# les gens
	if nuit:
		var g: Node = L._patron(M, 1.4, -3.55, 0.0, "comptoir", ["Ah, de la visite ! Le café est fermé, mais pas pour les amis. Tu veux un fond de lait de nuage ?",
			"Bonsoir ! Je fais mes comptes : trois cent douze chouquettes aujourd'hui. Un record. Monsieur Pascal en a pris quarante."])
		if g == null:
			var boul: Node = L._gens(M, "homme", 1.4, -3.55, 0.0, "cuisiner", ["Je prépare la pâte des chouquettes de demain. Elle doit se reposer toute la nuit. Comme moi.",
				"Le four solaire dort, la nuit. Alors les chouquettes attendent le lever du soleil, comme tout le monde."])
			L._causer(M, boul, ["Chut… la pâte se repose. Bonsoir !", "Bonsoir ! Le café ouvre à sept heures. Les chouquettes, à sept heures et une minute."],
				[["four", "Un four solaire, la nuit ?", ["Il garde la chaleur du jour dans ses pierres. Mais pour les chouquettes, Gustave veut le vrai soleil. Il dit qu'elles le sentent."]]])
		R.chat(-3.0, 1.8, 40, Color(0.92, 0.9, 0.86), true, 0.0)
		M.ctx["entree"] = "Le Café Cumulus, la nuit : les chaises dorment sur les tables, les lustres-nuages luisent à peine, et la machine à nuages ronronne toute seule sur le comptoir."
	else:
		var bar: Node = L._gens(M, "femme", 1.4, -3.55, 0.0, "comptoir", ["Un lait de nuage, un ! Avec la moustache !", "Le chocolat d'ici chuchote. Celui d'en bas siffle, paraît-il. Chacun son caractère."])
		L._causer(M, bar, ["Bon vent ! Bienvenue au Café Cumulus ! Assieds-toi où tu veux, le ciel est pour tout le monde.", "Bonjour ! Gustave est à son kiosque, sur la terrasse. Moi, je garde la maison… et la machine à nuages."],
			[["machine", "C'est quoi, cette machine ?", ["La machine à nuages ! Elle mousse le lait comme un petit cumulus. L'Ingénieure Nova dit que c'est la même science que les Sustentateurs, en plus petit et en plus sucré."]],
			["gustave", "Gustave est là ?", ["Il est dehors, au kiosque de la terrasse, à vendre ses chouquettes à toute l'Esplanade. Il ne rentre qu'à la fermeture. Il dit que ses chouquettes ont besoin de voir du monde."]]])
		var cli: Node = L._gens(M, "femme", -3.54, -1.3, 90, "assis", ["Ici, je lis le journal du Plancher. Les nouvelles d'en bas arrivent avec la capsule. Toujours un peu essoufflées.", "Un lait de nuage, et la vue. Je ne demande rien d'autre à la vie."])
		L._causer(M, cli, ["Bonjour ! Prends la chaise d'en face, si tu veux. Elle ne sert qu'aux nuages, d'habitude.", "Chut… regarde par la baie : le nuage, là, a la forme d'une chouquette."],
			[["nouvelles", "Quelles nouvelles d'en bas ?", ["Le Dôme d'Azur a rouvert, au fond de la mer, et la Fronde joue encore toute la nuit dans les Strates. Ici, on entend la musique par le conduit de la Colonne. Monsieur Pascal a écrit sa quarantième réclamation."]]])
		L._gens(M, "homme", 2.56, 2.0, 90, "rire_assis", ["Ha ha ! Tu as une moustache de nuage ! … Moi aussi ? Depuis quand ?", "Le deuxième lait de nuage est toujours meilleur que le premier. Le troisième, je ne sais pas, je n'ai jamais osé."])
		var a2: Node = L._gens(M, "vieille", 3.84, 2.0, -90, "manger", ["Ces chouquettes… On dirait qu'elles ont été cuites par un nuage très gentil.", "Mon mari m'a demandée en mariage à cette table. Il y a cinquante ans. Il avait une moustache de lait de nuage. J'ai dit oui quand même."])
		L._causer(M, a2, ["Bonjour, mon petit ! Une chouquette ? Je les compte, mais je partage.", "Bon vent ! Tu as l'air d'avoir faim. Ça tombe bien : moi aussi, toujours."],
			[["chouquettes", "Elles sont bonnes ?", ["Les meilleures de tout l'archipel. Le four solaire de Gustave les cuit à la lumière du matin. Le soir, elles goûtent un peu le coucher de soleil. Je te jure."]]])
		var serv: Node = L._gens(M, "homme", 1.0, -1.9, 0, "marcher", ["Pardon, pardon ! Lait de nuage pour la table du fond !", "Attention, chouquettes brûlantes ! … Enfin, tièdes. Le four solaire est très poli."])
		var pl: Node3D = _plateau(serv)
		L._va_et_vient(M, serv, R.P(1.0, 0.0, -1.9), R.P(-1.9, 0.0, 0.3), 0.9, 2.5, pl)
		L._causer(M, serv, ["Pardon ! Je passe ! Tu veux commander ? Dis-le à ma collègue, au comptoir.", "Bon vent ! Attention au plateau, il est plein de nuages."], [])
		M.ctx["entree"] = str(L._pick(M, ["Le Café Cumulus : des tables blanches, des lustres en forme de nuages, et derrière le comptoir, dans un globe de verre, un petit nuage qui tourne doucement.",
			"Ça sent la chouquette chaude et le lait mousseux. Au Café Cumulus, tout le monde a une moustache blanche, et personne n'ose le dire aux autres.",
			"Par les grandes baies, le ciel entre dans le café. Les lustres-nuages se balancent un peu. Une machine, sur le comptoir, fait des nuages en lait."]))
	# ce qu'on fait : goûter le lait de nuage, regarder la machine, lire l'ardoise
	M.act(R.P(0.7, 1.0, -2.45), "E : goûter le lait de nuage", func() -> void:
		M.main.sfx("boire", R.P(0.7, 1.0, -2.45))
		var st: Dictionary = M.state()
		if not bool(st.get("lait117", false)):
			st["lait117"] = true
			M.bonne_action_v120()  ## V120 : un service rendu, l'île s'en souvient
			M.give([["lait_nuage", 1]], "« Goûte, c'est la maison qui offre ! » Une tasse de lait de nuage, tout mousseux. Tu as maintenant une moustache blanche, et une tasse à emporter :\n")
		else:
			M.say(str(L._pick(M, ["Mmm… On dirait de boire un petit nuage tiède. Ta moustache blanche est revenue.",
				"Un lait de nuage. Léger, sucré, avec un goût de ciel. Et une moustache offerte.",
				"Tu bois une gorgée. Quelque part, un nuage est très fier de toi."])), 5.0)
	, 1.5)
	M.act(mc + Vector3(0, 0.4, 0.4), "E : regarder la machine à nuages", func() -> void:
		M.main.sfx("vapeur", mc)
		_bouffee(M, brume, 40, 2.5)
		var tw: Tween = M.room.create_tween()
		tw.tween_property(petit, "scale", Vector3.ONE * 1.5, 0.5).set_trans(Tween.TRANS_BACK)
		tw.tween_property(petit, "scale", Vector3.ONE, 1.2)
		M.say(str(L._pick(M, ["Pfffouu… Le petit nuage gonfle, tourne trois fois sur lui-même et mousse dans une tasse. Puis il recommence à tourner, l'air satisfait.",
			"La machine souffle, siffle tout bas, et un petit cumulus de lait se pose dans une tasse. C'est la même science que les Sustentateurs, en plus sucré.",
			"Dans le globe de verre, le petit nuage fait une pirouette. On dirait qu'il te salue."])), 5.0)
	, 1.4)
	M.act(R.P(-4.6, 1.5, 0.0), "E : lire l'ardoise", func() -> void:
		M.say(MENU_CUMULUS, 7.0)
	, 1.4)


# =================================================================== l'Atelier des Inventeurs

const PLANS := ["Plan numéro 412 : le grille-pain qui chante l'heure. Problème : il chante faux. Solution envisagée : apprendre la musique au grille-pain.",
	"Plan numéro 413 : le parapluie-ascenseur, modèle « Ça monte ! » (merci à la Confrérie des Liftiers d'en bas pour le nom). Autonomie : un étage et demi. Atterrissage : à revoir.",
	"Plan numéro 414 : la tasse tourneuse. Elle mélange le sucre toute seule. Elle mélange aussi la nappe, la table, et parfois le chat. À régler.",
	"Plan numéro 415 : le bocal à nuage. Un petit nuage domestique, très calme, qui pleut sur les plantes quand on oublie de les arroser. Testé et approuvé par Flora."]


## L'Atelier des Inventeurs : l'établi et ses outils, la table à dessin et ses plans, les étagères
## d'inventions (des parapluies, des grille-pains, des bocaux à nuage, une tasse qui tourne), le
## parapluie-ascenseur sur son socle, un petit drone qui fait des ronds sous le plafond, un bras
## mécanique qui salue ; l'apprenti et une cliente le jour, Mireille elle-même le soir.
static func _atelier(M) -> void:
	var R = M.R
	var k = R.kit
	var nuit: bool = L._nuit(M)
	var room0 = M.room
	# l'établi (contre le mur de gauche), ses outils, le bras mécanique qui salue
	R.etabli(-4.75, -0.1, 90, 2.4)
	var bras: Node3D = I._node(M, R.P(-4.75, 0.92, -0.9))
	L._mesh(bras, L._cylm(0.1, 0.12, 0.08, 12), _acier(M))
	var coude: Node3D = Node3D.new()
	bras.add_child(coude)
	coude.position = Vector3(0, 0.05, 0)
	L._mesh(coude, I._boxm(Vector3(0.07, 0.5, 0.07)), _blanc(M), Transform3D(Basis(), Vector3(0, 0.25, 0)))
	L._mesh(coude, I._sph(0.05), _acier(M), Transform3D(Basis(), Vector3(0, 0.5, 0)))
	L._mesh(coude, I._boxm(Vector3(0.06, 0.35, 0.06)), _blanc(M), Transform3D(Basis(Vector3.BACK, 0.9), Vector3(0.13, 0.62, 0)))
	L._mesh(coude, I._boxm(Vector3(0.12, 0.05, 0.03)), _led(M, Color(0.4, 0.75, 1.0)), Transform3D(Basis(Vector3.BACK, 0.9), Vector3(0.27, 0.72, 0)))
	L._balance(M, coude, Vector3.FORWARD, 0.35, 2.8, 0.0)
	# la table à dessin (au fond, à gauche) et ses plans
	var dt: Transform3D = R.L(-2.6, 0, -3.3)
	for s in [-1.0, 1.0]:
		k.box(dt * Transform3D(Basis(), Vector3(s * 0.6, 0.45, 0)), Vector3(0.05, 0.9, 0.6), "argent", 1.0)
	k.box(dt * Transform3D(Basis(Vector3.RIGHT, 0.45), Vector3(0, 1.05, 0.05)), Vector3(1.4, 0.03, 0.9), "ceramique", 1.0)
	_panneau(M, dt * Transform3D(Basis(Vector3.RIGHT, 0.45 - PI * 0.5), Vector3(0, 1.075, 0.05)), Vector2(1.2, 0.8), _ecran(M, "nuees/plans_invention.png", 0.15))
	k.col_box(dt * Transform3D(Basis(), Vector3(0, 0.55, 0)), Vector3(1.4, 1.1, 0.9))
	R.reserve(-2.6, -3.3, 1.8, 1.2)
	R.tabouret(-2.6, -2.5)
	_panneau(M, R.L(-0.6, 2.4, -4.22), Vector2(1.6, 1.2), _ecran(M, "nuees/plans_invention.png", 0.1))
	R.mark_wall(-0.6, 2.4, -4.25, 0.9)
	# les étagères d'inventions (au fond, à droite) : parapluies, grille-pains, bocaux, la tasse tourneuse
	var et: Transform3D = R.L(2.9, 0, -3.85)
	for y in [0.0, 0.62, 1.24, 1.86]:
		k.box(et * Transform3D(Basis(), Vector3(0, y + 0.3, 0)), Vector3(3.2, 0.04, 0.5), "ceramique", 1.0)
	for s3 in [-1.0, 1.0]:
		k.box(et * Transform3D(Basis(), Vector3(s3 * 1.6, 1.1, 0)), Vector3(0.04, 2.2, 0.5), "argent", 1.0)
	k.col_box(et * Transform3D(Basis(), Vector3(0, 1.1, 0)), Vector3(3.2, 2.2, 0.5))
	R.reserve(2.9, -3.85, 3.4, 0.8)
	var cols: Array = [Color(0.85, 0.25, 0.25), Color(0.25, 0.5, 0.85), Color(0.95, 0.75, 0.2), Color(0.35, 0.7, 0.45)]
	for i in range(4):
		var px: float = -1.2 + i * 0.8
		var pr: Node3D = I._node(M, et * Vector3(px, 0.32, 0.05))
		L._mesh(pr, L._cylm(0.012, 0.012, 0.55, 6), _acier(M), Transform3D(Basis(), Vector3(0, 0.3, 0)))
		L._mesh(pr, L._cylm(0.02, 0.09, 0.42, 10), L._m(M, "toile117_%d" % i, cols[i], 0.7), Transform3D(Basis(), Vector3(0, 0.36, 0)))
	for i2 in range(3):
		k.box(et * Transform3D(Basis(), Vector3(-1.0 + i2 * 0.95, 1.06, 0)), Vector3(0.36, 0.22, 0.24), "argent", 1.0)
		k.box(et * Transform3D(Basis(), Vector3(-1.0 + i2 * 0.95, 1.18, 0)), Vector3(0.3, 0.02, 0.04), "noir", 1.0)
	for i3 in range(4):
		var bp: Vector3 = et * Vector3(-1.2 + i3 * 0.8, 1.54, 0.0)
		k.cyl(Transform3D(Basis(), bp + Vector3(0, 0.02, 0)), 0.11, 0.11, 0.3, "verre", 14, false)
		k.cyl(Transform3D(Basis(), bp + Vector3(0, 0.32, 0)), 0.115, 0.115, 0.04, "argent", 14)
		var bn: Node3D = I._node(M, bp + Vector3(0, 0.15, 0))
		var nm: StandardMaterial3D = L._m(M, "nuage117", Color(1.0, 0.99, 0.96), 0.9, 0.0, 0.9)
		L._mesh(bn, I._sph(0.06), nm)
		L._mesh(bn, I._sph(0.045), nm, Transform3D(Basis(), Vector3(0.05, -0.01, 0.0)))
		L._tourne(M, bn, Vector3.UP, 0.4 + i3 * 0.2)
	var tasse: Node3D = I._node(M, et * Vector3(0.6, 1.92, 0.05))
	L._mesh(tasse, L._cylm(0.09, 0.09, 0.012, 16), _blanc(M))
	L._mesh(tasse, L._cylm(0.055, 0.045, 0.08, 14), L._m(M, "tasse117", Color(0.3, 0.55, 0.9), 0.3), Transform3D(Basis(), Vector3(0, 0.05, 0)))
	L._tourne(M, tasse, Vector3.UP, 2.4)
	# le parapluie-ascenseur, sur son socle, au milieu de l'atelier
	var pc: Vector3 = R.P(1.2, 0, -0.4)
	k.cyl(Transform3D(Basis(), pc), 0.8, 0.85, 0.08, "argent", 24)
	k.ring(Transform3D(Basis(), pc + Vector3.UP * 0.08), 0.7, 0.8, 0.02, "lumiere", 24)
	k.col_cyl(pc, 0.85, 0.1)
	R.reserve(1.2, -0.4, 1.8, 1.8)
	var para: Node3D = I._node(M, pc + Vector3.UP * 0.08)
	var toile: StandardMaterial3D = L._m(M, "parapluie117", Color(0.95, 0.35, 0.3), 0.6, 0.0, 0.0, true)
	L._mesh(para, L._cylm(0.012, 0.012, 1.7, 6), _acier(M), Transform3D(Basis(), Vector3(0, 0.85, 0)))
	L._mesh(para, L._cylm(0.03, 0.85, 0.32, 16, false), toile, Transform3D(Basis(), Vector3(0, 1.62, 0)))
	L._mesh(para, L._tore(0.05, 0.07), _acier(M), Transform3D(Basis(Vector3.FORWARD, PI * 0.5), Vector3(0.06, 0.05, 0)))
	var helice: Node3D = Node3D.new()
	para.add_child(helice)
	helice.position = Vector3(0, 1.84, 0)
	for b in range(2):
		L._mesh(helice, I._boxm(Vector3(0.9, 0.012, 0.07)), _blanc(M), Transform3D(Basis(Vector3.UP, b * PI * 0.5), Vector3.ZERO))
	L._tourne(M, helice, Vector3.UP, 1.0, true)
	# le petit drone qui fait des ronds sous le plafond
	var piv: Node3D = I._node(M, R.P(0.6, 3.1, 0.6))
	var drone: Node3D = Node3D.new()
	piv.add_child(drone)
	drone.position = Vector3(2.0, 0, 0)
	L._mesh(drone, L._cylm(0.12, 0.12, 0.05, 14), _blanc(M))
	L._mesh(drone, I._sph(0.04), _led(M, Color(0.4, 0.75, 1.0), 2.2), Transform3D(Basis(), Vector3(0, -0.03, 0.1)))
	for a in range(4):
		var d4 := Vector3(cos(a * PI * 0.5 + PI * 0.25), 0, sin(a * PI * 0.5 + PI * 0.25)) * 0.17
		L._mesh(drone, L._cylm(0.07, 0.07, 0.006, 12), L._m(M, "rotor117", Color(0.6, 0.62, 0.65, 0.5), 0.4), Transform3D(Basis(), d4 + Vector3(0, 0.04, 0)))
	M.ctx["drone117"] = 1.0
	L._chaque(M, func(delta: float, t: float) -> void:
		if not is_instance_valid(piv):
			return
		piv.rotate_y(delta * 0.8 * float(M.ctx.get("drone117", 1.0)))
		drone.position.y = sin(t * 2.0) * 0.12)
	# un peu de lumière sur l'établi, et les lampes de travail
	L._lampe(M, R.P(-4.2, 2.2, -0.1), Color(1.0, 0.95, 0.85), 0.7, 4.5)
	L._lampe(M, R.P(2.9, 2.4, -2.6), Color(0.95, 0.97, 1.0), 0.6, 4.0)
	_plante(M, 4.6, 3.4, 1.0)
	# le panneau à outils (mur de droite, entre les baies) et son meuble bas
	var po: Transform3D = R.L(5.45, 0, 0.0, -90)
	R.mark_wall(5.45, 1.6, 0.0, 1.1)
	k.box(po * Transform3D(Basis(), Vector3(0, 1.6, 0.02)), Vector3(2.0, 1.1, 0.03), "ceramique", 1.0)
	for i5 in range(9):
		var ox: float = -0.8 + (i5 % 5) * 0.4
		var oy: float = 1.95 - int(i5 / 5) * 0.55
		k.box(po * Transform3D(Basis(Vector3.BACK, 0.25 * ((i5 % 3) - 1)), Vector3(ox, oy - 0.12, 0.06)), Vector3(0.04, 0.3, 0.02), ["argent", "noir"][i5 % 2], 1.0)
		k.box(po * Transform3D(Basis(), Vector3(ox, oy + 0.06, 0.06)), Vector3(0.09, 0.05, 0.02), ["argent", "noir"][i5 % 2], 1.0)
	k.box(po * Transform3D(Basis(), Vector3(0, 0.42, 0.3)), Vector3(2.0, 0.84, 0.55), "ceramique", 1.0)
	for i6 in range(4):
		k.box(po * Transform3D(Basis(), Vector3(-0.75 + i6 * 0.5, 0.42, 0.58)), Vector3(0.44, 0.78, 0.01), "argent", 1.0)
		k.box(po * Transform3D(Basis(), Vector3(-0.75 + i6 * 0.5, 0.7, 0.6)), Vector3(0.16, 0.02, 0.02), "noir", 1.0)
	k.col_box(po * Transform3D(Basis(), Vector3(0, 0.45, 0.3)), Vector3(2.0, 0.9, 0.55))
	R.reserve(5.1, 0.0, 0.8, 2.2)
	# la grande table du milieu : Plumeau 2 en pièces détachées (un robot jardinier qu'on répare)
	var tb: Transform3D = R.L(3.0, 0, 1.9)
	k.box(tb * Transform3D(Basis(), Vector3(0, 0.88, 0)), Vector3(2.0, 0.05, 0.95), "ceramique", 1.0)
	for s7 in [-1.0, 1.0]:
		for s8 in [-1.0, 1.0]:
			k.box(tb * Transform3D(Basis(), Vector3(s7 * 0.9, 0.43, s8 * 0.4)), Vector3(0.05, 0.86, 0.05), "argent", 1.0)
	k.col_box(tb * Transform3D(Basis(), Vector3(0, 0.45, 0)), Vector3(2.0, 0.9, 0.95))
	R.reserve(3.0, 1.9, 2.4, 1.4)
	var corps: Node3D = I._node(M, tb * Vector3(-0.35, 0.91, 0.0))
	L._mesh(corps, I._sph(0.24), _blanc(M), Transform3D(Basis().scaled(Vector3(1.0, 0.8, 1.0)), Vector3(0, 0.2, 0)))
	L._mesh(corps, L._cylm(0.2, 0.22, 0.06, 18), _acier(M), Transform3D(Basis(), Vector3(0, 0.03, 0)))
	L._mesh(corps, I._boxm(Vector3(0.16, 0.12, 0.02)), _led(M, Color(0.4, 0.8, 1.0), 1.4), Transform3D(Basis(), Vector3(0, 0.24, 0.235)))
	var tete: Node3D = I._node(M, tb * Vector3(0.45, 0.91, 0.12))
	L._mesh(tete, I._sph(0.13), _blanc(M), Transform3D(Basis(), Vector3(0, 0.11, 0)))
	for s9 in [-1.0, 1.0]:
		L._mesh(tete, I._sph(0.028), _led(M, Color(0.4, 0.8, 1.0), 2.0), Transform3D(Basis(), Vector3(s9 * 0.05, 0.13, 0.115)))
	L._mesh(tete, L._cylm(0.006, 0.006, 0.12, 6), _acier(M), Transform3D(Basis(), Vector3(0, 0.29, 0)))
	L._mesh(tete, I._sph(0.02), _led(M, Color(1.0, 0.5, 0.3), 2.0), Transform3D(Basis(), Vector3(0, 0.36, 0)))
	L._balance(M, tete, Vector3.UP, 0.25, 4.5, 0.0)
	k.box(tb * Transform3D(Basis(Vector3.UP, 0.4), Vector3(0.2, 0.93, -0.3)), Vector3(0.42, 0.05, 0.06), "argent", 1.0)
	k.box(tb * Transform3D(Basis(Vector3.UP, 0.4), Vector3(0.43, 0.93, -0.22)), Vector3(0.08, 0.06, 0.1), "argent", 1.0)
	k.box(tb * Transform3D(Basis(Vector3.UP, -0.3), Vector3(0.75, 0.94, -0.2)), Vector3(0.36, 0.08, 0.2), "noir", 1.0)
	k.box(tb * Transform3D(Basis(Vector3.UP, 0.9), Vector3(-0.85, 0.92, 0.3)), Vector3(0.16, 0.025, 0.025), "noir", 1.0)
	R.tabouret(3.0, 2.85)
	# une maquette de la Libellule pendue au plafond, qui se balance un peu
	var mq: Node3D = I._node(M, R.P(-1.6, 3.95, 1.4))
	L._balance(M, mq, Vector3.FORWARD, 0.06, 5.0, 0.4)
	for s10 in [-1.0, 1.0]:
		L._mesh(mq, L._cylm(0.004, 0.004, 0.6, 4), _acier(M), Transform3D(Basis(), Vector3(s10 * 0.35, -0.3, 0)))
	L._mesh(mq, I._sph(0.22), _blanc(M), Transform3D(Basis().scaled(Vector3(3.6, 1.0, 1.0)), Vector3(0, -0.72, 0)))
	L._mesh(mq, I._boxm(Vector3(0.36, 0.1, 0.14)), _acier(M), Transform3D(Basis(), Vector3(0, -0.98, 0)))
	for s11 in [-1.0, 1.0]:
		L._mesh(mq, I._boxm(Vector3(0.22, 0.012, 0.16)), _blanc(M), Transform3D(Basis(Vector3.RIGHT, s11 * 0.6), Vector3(-0.72, -0.72 + s11 * 0.1, s11 * 0.12)))
	var hel2: Node3D = Node3D.new()
	mq.add_child(hel2)
	hel2.position = Vector3(-0.82, -0.72, 0)
	for b2 in range(3):
		L._mesh(hel2, I._boxm(Vector3(0.012, 0.18, 0.04)), _acier(M), Transform3D(Basis(Vector3.RIGHT, b2 * TAU / 3.0), Vector3(0, 0.08, 0)))
	L._tourne(M, hel2, Vector3.RIGHT, 3.0, true)
	# des caisses de pièces détachées, près de l'entrée
	for c12 in range(3):
		var cx: Vector3 = Vector3(-4.75 + (c12 % 2) * 0.05, 0.27 + int(c12 / 2) * 0.55, 3.5 - (c12 % 2) * 0.62)
		k.box(R.L(cx.x, cx.y, cx.z, 8.0 * c12), Vector3(0.6, 0.54, 0.6), "bois", 1.0)
		k.box(R.L(cx.x, cx.y + 0.05, cx.z + 0.305, 8.0 * c12), Vector3(0.5, 0.06, 0.01), "noir", 1.0)
	k.col_box(R.L(-4.7, 0.5, 3.2), Vector3(0.75, 1.0, 1.3))
	R.reserve(-4.7, 3.2, 0.9, 1.5)
	# les gens
	var patronne: Node = null
	if nuit:
		patronne = L._patron(M, -2.6, -2.55, 180.0, "bricoler", ["Oh ! De la visite, à cette heure-ci ? Tant mieux : j'ai besoin de quelqu'un pour tenir la ficelle du parapluie.",
			"Bonsoir ! Ne marche pas sur le plan, il est encore humide. Oui, c'est de l'encre. Non, ce n'est pas grave."])
		if patronne == null:
			var veil: Node = L._gens(M, "femme", -2.6, -2.55, 180.0, "lire", ["Mireille m'a laissé les plans à recopier. Elle dessine plus vite qu'elle n'écrit. Je déchiffre.", "La nuit, l'atelier fait de petits bruits : tic, bip, frrr. Ce sont les inventions qui rêvent."])
			L._causer(M, veil, ["Bonsoir ! L'atelier est fermé, mais les inventions ne dorment jamais vraiment.", "Chut… le drone dort. Enfin, il fait semblant."], [])
		M.ctx["entree"] = "La nuit, l'Atelier des Inventeurs n'est jamais tout à fait noir : des diodes clignotent, le petit drone tourne encore sous le plafond, et quelqu'un dessine sous la lampe."
	else:
		var app: Node = L._gens(M, "garcon", -3.95, 0.4, -90, "bricoler", ["Je règle l'hélice du parapluie. Si elle tourne trop vite, on monte au plafond. Si elle tourne trop lentement, on reste un inventeur à pied.",
			"Mireille dit qu'une bonne invention rate au moins cent fois. J'en suis à quatre-vingt-dix-sept."])
		L._causer(M, app, ["Bon vent ! Tu viens essayer le parapluie-ascenseur ? Tout le monde vient pour ça.", "Bonjour ! Ne touche pas au bras mécanique, il serre la main un peu trop fort."],
			[["parapluie", "Il marche vraiment, ce parapluie ?", ["Il monte d'un étage et demi ! Le problème, c'est la descente : Mireille travaille sur la partie « atterrir ». Pour l'instant, on tient la ficelle."]],
			["mireille", "Où est Mireille ?", ["Au comptoir, dehors, sous l'auvent. Elle vend les inventions qui marchent. Celles qui marchent presque, on les garde ici, pour les améliorer."]]])
		var cli2: Node = L._gens(M, "femme", 2.5, -2.6, 180, "observer", ["Je cherche un grille-pain solaire qui ne boude pas la nuit. Celui-ci a l'air de bonne humeur.", "Un bocal à nuage ! Pour mes plantes. Je pars en vacances au Plancher, et elles ont toujours soif."])
		L._causer(M, cli2, ["Bonjour ! Tu crois que ce parapluie est remboursé s'il s'envole ?", "Bon vent ! Je n'arrive pas à choisir : le bocal à nuage ou la tasse qui tourne ?"],
			[["choix", "Je prendrais le bocal à nuage.", ["Tu as raison. La tasse qui tourne, j'en ai déjà une. Elle a mélangé mon thé, puis ma nappe, puis mon chat. Il ne vient plus prendre le thé avec moi."]]])
		M.ctx["entree"] = str(L._pick(M, ["L'Atelier des Inventeurs : des établis, des plans partout, des inventions sur les étagères, et au milieu, sur son socle, un parapluie avec une hélice sur la tête.",
			"Ça sent l'huile fine et le papier à dessin. Un petit drone fait des ronds sous le plafond ; un bras mécanique te fait signe depuis l'établi.",
			"Bip, frrr, clic. Tout bouge, tourne ou clignote, chez les inventeurs. Même la tasse, sur l'étagère, tourne toute seule sur sa soucoupe."]))
	# ce qu'on fait : essayer le parapluie-ascenseur, remonter le drone, lire les plans
	M.act(pc + Vector3(0, 1.0, 0.9), "E : essayer le parapluie-ascenseur", func() -> void:
		if bool(M.ctx.get("vol117", false)):
			return
		M.ctx["vol117"] = true
		M.main.sfx("ascenseur", pc)
		M.ctx["vite116"] = 6.0
		var b0: Vector3 = para.position
		var tw: Tween = M.room.create_tween()
		tw.tween_property(para, "position", b0 + Vector3(0, 1.55, 0), 2.2).set_trans(Tween.TRANS_SINE)
		tw.tween_interval(1.2)
		tw.tween_property(para, "position", b0, 2.6).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		var lab: Label3D = L._etiquette(M, pc + Vector3(0, 3.0, 0), "Ça monte !")
		L._montrer(M, lab, 2.4)
		M.say(str(L._pick(M, ["Tu tires sur la ficelle : l'hélice siffle, le parapluie décolle et monte jusqu'au plafond… puis redescend en rebondissant. « Atterrissage : à revoir », note l'apprenti.",
			"Frrrr… Le parapluie monte, tout droit, très fier, puis hésite, puis redescend en faisant des petits bonds. Tout le monde applaudit, par politesse.",
			"L'hélice tourne, le parapluie s'élève d'un étage et demi, fait un petit salut, et retombe sur son socle. « Presque ! », dit-on derrière toi."])), 6.0)
		await M.get_tree().create_timer(6.2).timeout
		if not _la(M, room0):
			return
		M.ctx["vite116"] = 1.0
		M.ctx["vol117"] = false
		var st: Dictionary = M.state()
		if not bool(st.get("parapluie117", false)):
			st["parapluie117"] = true
			M.bonne_action_v120()  ## V120 : un service rendu, l'île s'en souvient
			M.give([["boussole_nuages", 1]], "« Bravo, pilote d'essai ! Pour ton courage, une boussole à nuages : elle montre toujours le plus joli. » Tu reçois :\n")
	, 1.6)
	M.act(R.P(0.6, 1.4, 1.2), "E : remonter le petit drone", func() -> void:
		M.main.sfx("drone_vol", piv.global_position)
		M.ctx["drone117"] = 4.0
		M.say(str(L._pick(M, ["Tu tournes la petite clé : le drone file comme une hirondelle, fait trois tours de l'atelier à toute vitesse… puis ralentit, très content de lui.",
			"Bzzzz ! Le petit drone accélère, frôle le plafonnier, bip-bip, et reprend sa ronde tranquille. Il s'est cru pressé."])), 5.0)
		await M.get_tree().create_timer(4.0).timeout
		if _la(M, room0):
			M.ctx["drone117"] = 1.0
	, 1.6)
	M.act(dt * Vector3(0, 1.1, 0.6), "E : lire les plans", func() -> void:
		M.main.sfx("ui_ouvrir", dt.origin)
		var n: int = int(M.ctx.get("plan117", 0))
		M.ctx["plan117"] = n + 1
		M.say(str(PLANS[n % PLANS.size()]), 7.0)
	, 1.3)


# =================================================================== la Maison du Conseil

const LIVRE_VENTS := ["LE LIVRE DES VENTS, page un. « En l'an premier, Séraphin Altaïr, inventeur, posa quatre moteurs sous la Montagne Renversée. Le premier matin, elle ne bougea pas. Le deuxième non plus. Le troisième, elle monta d'un pouce, et toute la ville d'en bas applaudit. »",
	"LE LIVRE DES VENTS, page deux. « Il fallut quarante jours pour que la Montagne atteigne les nuages. Les gens montaient chaque soir par la Colonne et une longue échelle, pour voir. Séraphin leur servait du thé. Ainsi naquit la Cité des Nuées, et la coutume du thé des sommets. »",
	"LE LIVRE DES VENTS, page trois. « Il fut décidé que l'eau viendrait des nuages, la lumière du soleil, et les décisions du Conseil, où chacun peut parler. Il fut aussi décidé qu'on se saluerait par « Bon vent ». Ce fut la première loi votée, à l'unanimité moins une voix : celle de Séraphin, qui proposait « Bonne altitude ». »",
	"LE LIVRE DES VENTS, dernière page écrite. « Cette année, la Ligne des Nuées a rouvert après trois ans de révision. Le Conseil a voté une fête, et un nom pour le nouveau nuage du matin : « Chouquette ». Le Docteur Aurèle s'est abstenu. »"]
const PLAQUE_SERAPHIN := "SÉRAPHIN ALTAÏR, inventeur des Sustentateurs, fondateur de la Cité des Nuées. « Il suffit de quatre moteurs, d'une montagne, et de beaucoup de patience. » Sur l'épaule du buste, quelqu'un a posé une petite plume blanche. Il y en a une nouvelle chaque matin."
const VOTES := ["Proposition du jour : baptiser le nuage du matin « Chouquette ». Tu votes pour. Adopté, sous les applaudissements !",
	"Proposition du jour : une deuxième Navette, dans l'autre sens, pour ceux qui ont le tournis. Tu votes pour. Adopté ! Monsieur Pascal, au fond, vote contre par principe.",
	"Proposition du jour : un banc de plus au Belvédère de verre, pour ceux qui ont les jambes qui tremblent. Tu votes pour. Adopté à l'unanimité, même les jambes.",
	"Proposition du jour : le goûter obligatoire à seize heures, pour tous les âges. Tu votes pour. Adopté ! La classe en visite fait une ovation."]


## La Maison du Conseil : l'estrade et le bureau de la Première Conseillère, l'emblème de la plume,
## l'hémicycle de bancs blancs, la carte de l'île en hologramme sur sa table de verre, le Livre des
## Vents sur son lutrin, le buste de Séraphin Altaïr ; le jour, la séance (des conseillers, un orateur,
## le greffier) ; la nuit, le gardien et l'hologramme qui veille.
static func _conseil(M) -> void:
	var R = M.R
	var k = R.kit
	var nuit: bool = L._nuit(M)
	var room0 = M.room
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	# l'estrade, le bureau de la présidence, ses trois fauteuils
	k.box(R.L(0, 0.15, -hd + 0.9), Vector3(7.0, 0.3, 1.8), "ceramique", 1.0)
	k.col_box(R.L(0, 0.15, -hd + 0.9), Vector3(7.0, 0.3, 1.8))
	k.box(R.L(0, 0.15 + 0.5, -hd + 1.55), Vector3(4.0, 1.0, 0.5), "ceramique", 1.0)
	k.box(R.L(0, 1.18, -hd + 1.55), Vector3(4.2, 0.05, 0.6), "bois", 1.0)
	k.box(R.L(0, 0.7, -hd + 1.81), Vector3(3.6, 0.06, 0.02), "lumiere", 1.0)
	k.col_box(R.L(0, 0.7, -hd + 1.55), Vector3(4.0, 1.1, 0.5))
	for e in [[-1.2, 1.0], [0.0, 1.25], [1.2, 1.0]]:
		var cx: Transform3D = R.L(float(e[0]), 0.3, -hd + 0.8)
		k.box(cx * Transform3D(Basis(), Vector3(0, 0.45, 0)), Vector3(0.6, 0.08, 0.55), "tissu_bleu", 1.0)
		k.box(cx * Transform3D(Basis(), Vector3(0, 0.45 + float(e[1]) * 0.5, -0.25)), Vector3(0.6, float(e[1]), 0.08), "tissu_bleu", 1.0)
		k.box(cx * Transform3D(Basis(), Vector3(0, 0.22, 0)), Vector3(0.08, 0.44, 0.08), "argent", 1.0)
	R.reserve(0, -hd + 0.9, 7.4, 2.4)
	# l'emblème de la Cité : une grande plume (un axe d'acier, des barbes blanches), deux bannières
	var pl: Node3D = I._node(M, R.P(0, 3.3, -hd + 0.08))
	pl.rotation.z = -0.4
	L._mesh(pl, L._cylm(0.025, 0.045, 2.7, 8), _acier(M))
	for b in range(10):
		var t: float = float(b) / 9.0
		var w: float = sin(t * PI) * 0.5 + 0.08
		for s in [-1.0, 1.0]:
			L._mesh(pl, I._boxm(Vector3(w, 0.06, 0.015)), _blanc(M), Transform3D(Basis(Vector3.BACK, s * 0.7), Vector3(s * w * 0.42, -1.15 + t * 2.2 + w * 0.25, 0.0)))
	R.mark_wall(0, 3.3, -hd, 1.4)
	for s2 in [-1.0, 1.0]:
		k.box(R.L(s2 * 4.6, 3.0, -hd + 0.05), Vector3(1.0, 3.2, 0.03), "tissu_bleu", 1.0, 32)
		k.box(R.L(s2 * 4.6, 3.6, -hd + 0.07), Vector3(0.12, 1.2, 0.01), "tissu_blanc", 1.0, 32)
		k.box(R.L(s2 * 4.6, 3.8, -hd + 0.07), Vector3(0.5, 0.12, 0.01), "tissu_blanc", 1.0, 32)
		k.cyl(R.L(s2 * 4.6 - 0.6, 4.62, -hd + 0.06) * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3.ZERO), 0.02, 0.02, 1.2, "argent", 6, false)
		R.mark_wall(s2 * 4.6, 3.0, -hd, 0.6)
	# l'hémicycle : deux rangs de bancs blancs, en arc, tournés vers l'estrade
	var c := Vector2(0, -hd + 1.3)
	for rang in range(2):
		var rr: float = 4.4 + rang * 1.3
		var y0: float = 0.0 if rang == 0 else 0.3
		if rang == 1:
			for a0 in range(8):
				var am: float = deg_to_rad(28.0 + a0 * 17.7)
				k.box(Transform3D(Basis(Vector3.UP, -am + PI * 0.5), R.P(c.x + cos(am) * rr, 0.15, c.y + sin(am) * rr)), Vector3(1.75, 0.3, 1.0), "ceramique", 1.0)
		for a in range(7):
			var ab: float = deg_to_rad(32.0 + a * 19.3)
			var bp := Vector3(c.x + cos(ab) * rr, y0, c.y + sin(ab) * rr)
			var bb := Basis(Vector3.UP, -ab + PI * 0.5)
			k.box(Transform3D(bb, R.P(bp.x, bp.y + 0.43, bp.z)), Vector3(1.3, 0.06, 0.45), "ceramique", 1.0)
			k.box(Transform3D(bb, R.P(bp.x, bp.y + 0.2, bp.z)), Vector3(1.2, 0.4, 0.35), "argent", 1.0)
			k.box(Transform3D(bb, R.P(bp.x + cos(ab) * 0.24, bp.y + 0.75, bp.z + sin(ab) * 0.24)), Vector3(1.3, 0.6, 0.05), "tissu_bleu", 1.0)
			if rang == 0:
				k.box(Transform3D(bb, R.P(bp.x - cos(ab) * 0.55, 0.42, bp.z - sin(ab) * 0.55)), Vector3(1.25, 0.84, 0.05), "ceramique", 1.0)
				k.box(Transform3D(bb, R.P(bp.x - cos(ab) * 0.62, 0.86, bp.z - sin(ab) * 0.62)), Vector3(1.25, 0.04, 0.24), "bois", 1.0)
			k.col_box(Transform3D(bb, R.P(bp.x, bp.y + 0.3, bp.z)), Vector3(1.3, 0.6, 0.5))
	# la carte de l'île en hologramme, sur sa table de verre (au milieu de l'hémicycle)
	var hc: Vector3 = R.P(c.x, 0, c.y + 2.5)
	k.cyl(Transform3D(Basis(), hc), 0.5, 0.6, 0.85, "ceramique", 24)
	k.cyl(Transform3D(Basis(), hc + Vector3.UP * 0.85), 1.0, 1.0, 0.04, "verre", 28)
	k.ring(Transform3D(Basis(), hc + Vector3.UP * 0.86), 0.92, 1.0, 0.03, "lumiere", 28)
	k.col_cyl(hc, 1.0, 0.9)
	R.reserve(c.x, c.y + 2.5, 2.2, 2.2)
	var holo: Node3D = I._node(M, hc + Vector3.UP * 1.35)
	var hm: StandardMaterial3D = _ecran(M, "nuees/plan_ile.png", 1.4).duplicate()
	hm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hm.albedo_color = Color(1, 1, 1, 0.78)
	hm.cull_mode = BaseMaterial3D.CULL_DISABLED
	hm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var qm := QuadMesh.new()
	qm.size = Vector2(1.7, 1.7)
	L._mesh(holo, qm, hm, Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), Vector3.ZERO))
	var cone: StandardMaterial3D = L._m(M, "faisceau117", Color(0.45, 0.8, 1.0, 0.12), 0.9, 0.0, 0.8, true)
	L._mesh(holo, L._cylm(0.85, 0.3, 0.5, 24, false), cone, Transform3D(Basis(), Vector3(0, -0.25, 0)))
	M.ctx["holo117"] = 1.0
	L._chaque(M, func(delta: float, t: float) -> void:
		if is_instance_valid(holo):
			holo.rotate_y(delta * 0.25 * float(M.ctx.get("holo117", 1.0)))
			holo.position.y = hc.y + 1.35 + sin(t * 1.3) * 0.03)
	L._lampe(M, hc + Vector3.UP * 1.4, Color(0.5, 0.8, 1.0), 0.8, 4.0)
	# le Livre des Vents sur son lutrin (à droite), le buste de Séraphin Altaïr (à gauche)
	var lt: Transform3D = R.L(hw - 1.3, 0, -hd + 2.4, -120)
	k.box(lt * Transform3D(Basis(), Vector3(0, 0.55, 0)), Vector3(0.08, 1.1, 0.08), "argent", 1.0)
	k.box(lt * Transform3D(Basis(), Vector3(0, 0.02, 0)), Vector3(0.5, 0.04, 0.4), "argent", 1.0)
	k.box(lt * Transform3D(Basis(Vector3.RIGHT, 0.35), Vector3(0, 1.12, 0)), Vector3(0.6, 0.04, 0.45), "ceramique", 1.0)
	for s3 in [-1.0, 1.0]:
		k.box(lt * Transform3D(Basis(Vector3.RIGHT, 0.35) * Basis(Vector3.FORWARD, s3 * 0.08), Vector3(s3 * 0.15, 1.16, 0)), Vector3(0.29, 0.02, 0.38), "papier", 1.0)
	k.box(lt * Transform3D(Basis(Vector3.RIGHT, 0.35), Vector3(0, 1.145, 0)), Vector3(0.62, 0.012, 0.42), "tissu_bleu", 1.0)
	k.col_box(lt * Transform3D(Basis(), Vector3(0, 0.6, 0)), Vector3(0.6, 1.2, 0.5))
	R.reserve(hw - 1.3, -hd + 2.4, 1.0, 1.0)
	var bu: Vector3 = R.P(-hw + 1.3, 0, -hd + 2.4)
	k.box(Transform3D(Basis(), bu + Vector3.UP * 0.6), Vector3(0.55, 1.2, 0.55), "pierre_lisse", 1.0)
	var marbre: StandardMaterial3D = L._m(M, "marbre117", Color(0.93, 0.92, 0.9), 0.35)
	var buste: Node3D = I._node(M, bu + Vector3.UP * 1.2, 45.0)
	L._mesh(buste, L._cylm(0.16, 0.24, 0.28, 16), marbre, Transform3D(Basis.from_scale(Vector3(1.4, 1.0, 0.8)), Vector3(0, 0.14, 0)))
	L._mesh(buste, L._cylm(0.06, 0.07, 0.12, 10), marbre, Transform3D(Basis(), Vector3(0, 0.33, 0)))
	L._mesh(buste, I._sph(0.13), marbre, Transform3D(Basis.from_scale(Vector3(0.9, 1.1, 1.0)), Vector3(0, 0.5, 0)))
	L._mesh(buste, I._sph(0.03), marbre, Transform3D(Basis(), Vector3(0, 0.49, 0.125)))
	L._mesh(buste, I._sph(0.1), marbre, Transform3D(Basis.from_scale(Vector3(1.1, 0.5, 1.0)), Vector3(0, 0.44, -0.04)))
	L._mesh(buste, I._boxm(Vector3(0.012, 0.18, 0.04)), L._m(M, "plume117", Color(1, 1, 1), 0.8), Transform3D(Basis(Vector3.BACK, 0.4), Vector3(0.2, 0.32, 0.0)))
	k.col_box(Transform3D(Basis(), bu + Vector3.UP * 0.9), Vector3(0.6, 1.8, 0.6))
	R.reserve(-hw + 1.3, -hd + 2.4, 1.0, 1.0)
	# l'urne du vote (une borne près de l'entrée, côté public) et les plantes
	var ur: Vector3 = R.P(hw - 1.6, 0, hd - 1.8)
	k.box(Transform3D(Basis(), ur + Vector3.UP * 0.5), Vector3(0.5, 1.0, 0.4), "ceramique", 1.0)
	k.box(Transform3D(Basis(Vector3.RIGHT, -0.4), ur + Vector3(0, 1.05, 0.05)), Vector3(0.46, 0.04, 0.32), "noir", 1.0)
	for kb in range(2):
		k.cyl(Transform3D(Basis(Vector3.RIGHT, -0.4 + PI * 0.5), ur + Vector3(-0.1 + kb * 0.2, 1.08, 0.08)), 0.05, 0.05, 0.03, "lumiere" if kb == 0 else "tissu_rouge", 12)
	k.col_box(Transform3D(Basis(), ur + Vector3.UP * 0.5), Vector3(0.5, 1.0, 0.4))
	R.reserve(hw - 1.6, hd - 1.8, 0.8, 0.8)
	_plante(M, -hw + 0.6, hd - 0.7, 1.3)
	_plante(M, hw - 0.6, hd - 0.7, 1.3)
	L._lampe(M, R.P(-3.0, 3.6, -1.0), Color(1.0, 0.97, 0.92), 0.9, 7.0)
	L._lampe(M, R.P(3.0, 3.6, -1.0), Color(1.0, 0.97, 0.92), 0.9, 7.0)
	# les gens
	if nuit:
		var gard: Node = L._gens(M, "vieux", -4.5, hd - 2.0, 0, "mains_dos", ["La nuit, l'hologramme veille avec moi. Il tourne, je tourne. On se tient compagnie.",
			"Chut… Ici, même la nuit, on parle bas. Les murs ont entendu tellement de discours qu'ils ont besoin de repos."])
		L._va_et_vient(M, gard, R.P(-4.5, 0, hd - 2.0), R.P(4.0, 0, hd - 2.0), 0.6, 4.0)
		L._causer(M, gard, ["Bonsoir ! La séance est levée depuis longtemps, mais tu peux regarder. Sans voter, hein.", "Bon vent ! Tu viens voir l'hologramme ? La nuit, il est encore plus joli."],
			[["nuit", "Que fait le Conseil la nuit ?", ["Il dort ! Même la Première Conseillère. Enfin, je crois. Parfois, sa fenêtre reste allumée très tard. Elle relit les lettres des habitants, une par une."]]])
		M.ctx["entree"] = "La Maison du Conseil, la nuit : les bancs de l'hémicycle sont vides, et seule la carte de l'île, en hologramme, tourne doucement au milieu, d'un bleu de lune."
	else:
		var ora: Node = L._gens(M, "homme", c.x - 1.1, c.y + 2.3, -110, "enseigner", ["Chers conseillers ! Je propose qu'on ajoute un banc au Belvédère de verre. Pour ceux qui ont les jambes qui tremblent. Comme moi.",
			"Et ensuite, nous voterons pour le nom du nuage du matin. J'ai une proposition : « Chouquette »."])
		L._causer(M, ora, ["Bon vent ! Oh, un visiteur ! Bienvenue au Conseil : ici, tout le monde peut parler. Même toi. Surtout toi.", "Bonjour ! Tu tombes en pleine séance. Assieds-toi au fond, et lève la main si tu as une idée."],
			[["seance", "De quoi parle la séance ?", ["Des bancs du Belvédère, de l'eau des nuages pour les Serres, et de la fête pour la réouverture de la Ligne. Et du nom du nuage du matin. C'est le plus disputé."]],
			["celeste", "Où est la Première Conseillère ?", ["Céleste Altaïr ? Elle préside depuis son bureau, ou bien elle se promène sur l'Esplanade pour écouter les gens. Elle dit qu'on décide mieux avec les pieds sur le sol. Enfin, sur la Cité."]]])
		var places: Array = [[66.0, "lire", "femme", ["Je relis la proposition du nuage « Chouquette ». Je vote pour. Je crois que j'ai faim.",
				"Au Conseil des Nuées, on vote à main levée. Et quand on n'est pas d'accord, à main très levée."]],
			[90.0, "assis", "vieux", ["Je demande la parole ! … Ah, c'est déjà mon tour ? Alors je la rends.",
				"Je siège ici depuis quarante ans. J'ai voté pour tous les bancs du Belvédère. On aime s'asseoir, chez nous."]],
			[128.0, "rire_assis", "homme", ["Ha ha ! Un banc pour les jambes qui tremblent ! Je vote pour, des deux genoux.",
				"Ma proposition à moi : une fête des cerfs-volants tous les mardis. On en discute depuis trois mardis."]]]
		for pe in places:
			var ap: float = deg_to_rad(float(pe[0]))
			var sx2: float = c.x + cos(ap) * 4.4
			var sz2: float = c.y + sin(ap) * 4.4
			var cons: Node = L._gens(M, str(pe[2]), sx2, sz2, rad_to_deg(atan2(c.x - sx2, c.y - sz2)), str(pe[1]), pe[3])
			if pe[1] == "assis":
				L._causer(M, cons, ["Bonjour, jeune citoyen ! Tu as une idée à proposer ? Toutes les idées sont bienvenues. Surtout les idées de goûter.", "Bon vent ! Chut… l'orateur va bientôt finir. Dans une heure, à peu près."],
					[["vote", "Comment vote-t-on ?", ["Chacun peut proposer, chacun peut voter. Même les visiteurs, une fois par jour, à la borne, près de l'entrée. C'est une très vieille loi de Séraphin : « Celui qui monte jusqu'ici mérite d'être écouté. »"]]])
		var gre: Node = L._gens(M, "femme", 3.4, -hd + 2.3, 180, "lire", ["J'écris tout ce qui se dit. Tout. Même les éternuements. Surtout les éternuements de Monsieur Pascal, qui sont des opinions.", "Le Livre des Vents a mille pages. J'en suis à la mille-et-unième."])
		k.box(R.L(3.4, 0.45, -hd + 1.65), Vector3(1.1, 0.06, 0.6), "ceramique", 1.0)
		k.box(R.L(3.4, 0.22, -hd + 1.65), Vector3(1.0, 0.44, 0.5), "argent", 1.0)
		k.col_box(R.L(3.4, 0.25, -hd + 1.65), Vector3(1.1, 0.5, 0.6))
		_chaise_blanche(M, 3.4, -hd + 2.3, 180.0)
		L._causer(M, gre, ["Bonjour ! Je suis la greffière : j'écris l'histoire de la Cité, une séance après l'autre.", "Chut ! Je note. … Voilà. Bon vent !"],
			[["livre", "Qu'y a-t-il dans le Livre des Vents ?", ["Tout ! La fondation de la Cité par Séraphin, chaque loi, chaque fête, chaque nom de nuage. Le livre ouvert sur le lutrin, c'est la première page. Tu peux la lire."]]])
		M.ctx["entree"] = str(L._pick(M, ["La Maison du Conseil : un hémicycle de bancs blancs, une grande plume sur le mur du fond, et au milieu, sur une table de verre, la carte de l'île qui tourne en hologramme.",
			"« … et je propose donc un banc de plus au Belvédère ! » Tu entres en pleine séance. Les conseillers t'adressent un petit signe : ici, tout le monde peut écouter.",
			"Sous la grande plume de la Cité, les conseillers débattent. Le buste de Séraphin Altaïr, l'inventeur des Sustentateurs, a l'air de trouver le débat très intéressant."]))
	# ce qu'on fait : regarder la carte, lire le Livre des Vents, lire la plaque, voter
	M.act(hc + Vector3(0, 1.0, 1.1), "E : regarder la carte de l'île", func() -> void:
		M.main.sfx("hologramme", hc)
		M.ctx["holo117"] = 6.0
		M.say(str(L._pick(M, ["Tu effleures la table : la carte s'allume plus fort et tourne. Au milieu, l'Esplanade et la Plume ; au sud-est, la Gare ; à l'est, les trois dômes des Serres ; au nord, l'Institut des Vents ; à l'ouest, le Port ; au nord-ouest, le Parc des Brumes et sa Cascade.",
			"L'hologramme montre l'île vue de dessus, comme un oiseau la voit : un cercle de jardins et de toits blancs, la Navette tout autour, et sous l'île, quatre petits anneaux qui clignotent : les Sustentateurs.",
			"Un point doré clignote sur la carte : « Vous êtes ici ». Juste à côté, un autre point, plus petit : « Chouquettes chaudes ». Quelqu'un a dû le rajouter."])), 7.0)
		await M.get_tree().create_timer(4.0).timeout
		if _la(M, room0):
			M.ctx["holo117"] = 1.0
	, 1.6)
	M.act(lt * Vector3(0, 1.1, 0.5), "E : lire le Livre des Vents", func() -> void:
		M.main.sfx("ui_ouvrir", lt.origin)
		var n: int = int(M.ctx.get("livre117", 0))
		M.ctx["livre117"] = n + 1
		M.say(str(LIVRE_VENTS[n % LIVRE_VENTS.size()]), 9.0)
	, 1.3)
	M.act(bu + Vector3(0.5, 1.2, 0.5), "E : lire la plaque", func() -> void:
		M.say(PLAQUE_SERAPHIN, 8.0)
	, 1.3)
	M.act(ur + Vector3(0, 1.0, 0.45), "E : voter", func() -> void:
		var st: Dictionary = M.state()
		var n2: int = int(st.get("vote117", 0))
		st["vote117"] = n2 + 1
		M.main.sfx("ui_quete", ur)
		M.say(str(VOTES[n2 % VOTES.size()]), 7.0)
		for f in M.people:
			if is_instance_valid(f) and f.has_method("gesture"):
				f.gesture("applaudir", 2.5)
	, 1.3)


# =================================================================== l'Institut des Vents

const BULLETINS := {"matin": "BULLETIN DU MATIN. Vent d'ouest, doux. Brume au Parc jusqu'à neuf heures, puis soleil sur toute la Cité. Un nuage en forme de lapin passera au-dessus de la Gare vers dix heures. Il est en avance.",
	"jour": "BULLETIN DE L'APRÈS-MIDI. Ciel bleu, vent léger. Les cerfs-volants sont autorisés jusqu'à trois cents mètres. Les chapeaux, jusqu'à la tête. Risque de chouquettes en terrasse : élevé.",
	"soir": "BULLETIN DU SOIR. Le vent tombe avec le soleil. Coucher de soleil violet prévu au Belvédère ; Ombeline est déjà installée. Nuit claire : on verra les étoiles, et les lumières de Hautefond tout en bas.",
	"nuit": "BULLETIN DE NUIT. Calme plat. Quelques nuages dorment sous l'île. Merci de ne pas les réveiller : ils ont travaillé toute la journée."}


## L'Institut des Vents : la soufflerie (un long tunnel de verre, son hélice, ses rubans qui flottent,
## sa fumée), la chambre à nuages (un grand cylindre où tourne un nuage), les écrans des cartes de vent,
## les bureaux, un ballon-sonde sur son chariot ; les météorologues le jour, le veilleur de nuit.
static func _institut(M) -> void:
	var R = M.R
	var k = R.kit
	var nuit: bool = L._nuit(M)
	var room0 = M.room
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	# la soufflerie, le long du mur de gauche (de z = -3,8 à z = 1,6)
	var tx: float = -hw + 1.0
	var z0: float = -hd + 0.7
	var z1: float = 1.6
	var tl: float = z1 - z0
	var tm: float = (z0 + z1) * 0.5
	L._mesh(I._node(M, R.P(tx, 1.3, tm)), I._boxm(Vector3(1.0, 1.0, tl)), L._m(M, "tunnel117", Color(0.72, 0.86, 0.95, 0.3), 0.04, 0.0, 0.0, true))
	for e in [[0.5, 0.5], [-0.5, 0.5], [0.5, -0.5], [-0.5, -0.5]]:
		k.box(R.L(tx + float(e[0]), 1.3 + float(e[1]), tm), Vector3(0.04, 0.04, tl), "argent", 1.0)
	# les cadres du tunnel, tous les 90 cm, et son grand socle blanc
	var nf: int = maxi(2, int(tl / 0.9))
	for f2 in range(nf + 1):
		var zf: float = z0 + tl * f2 / nf
		for s2 in [-1.0, 1.0]:
			k.box(R.L(tx + s2 * 0.5, 1.3, zf), Vector3(0.05, 1.04, 0.05), "argent", 1.0)
			k.box(R.L(tx, 1.3 + s2 * 0.5, zf), Vector3(1.04, 0.05, 0.05), "argent", 1.0)
	k.box(R.L(tx, 0.4, tm), Vector3(0.9, 0.8, tl), "ceramique", 1.0)
	k.box(R.L(tx, 0.79, tm), Vector3(0.96, 0.03, tl + 0.04), "argent", 1.0)
	k.box(R.L(tx + 0.455, 0.45, tm), Vector3(0.01, 0.06, tl * 0.8), "lumiere", 1.0)
	k.col_box(R.L(tx, 1.0, tm), Vector3(1.1, 2.0, tl))
	R.reserve(tx, tm, 1.5, tl + 0.4)
	k.cyl(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), R.P(tx, 1.3, z0 - 0.05)), 0.62, 0.62, 0.4, "ceramique", 24, false)
	var fan: Node3D = I._node(M, R.P(tx, 1.3, z0 + 0.1))
	for b in range(5):
		L._mesh(fan, I._boxm(Vector3(0.1, 0.5, 0.02)), _acier(M), Transform3D(Basis(Vector3.BACK, TAU * b / 5.0) * Basis(Vector3.UP, 0.4), Vector3(cos(TAU * b / 5.0 + PI * 0.5), sin(TAU * b / 5.0 + PI * 0.5), 0) * 0.27))
	L._mesh(fan, I._sph(0.08), _blanc(M))
	L._tourne(M, fan, Vector3.BACK, 6.0, true)
	# la maquette dans le tunnel (une aile), les rubans qui flottent derrière
	var aile: Node3D = I._node(M, R.P(tx, 1.3, tm - 0.6))
	L._mesh(aile, L._cylm(0.012, 0.012, 0.5, 6), _acier(M), Transform3D(Basis(), Vector3(0, -0.25, 0)))
	L._mesh(aile, I._boxm(Vector3(0.7, 0.035, 0.18)), _blanc(M), Transform3D(Basis(Vector3.RIGHT, -0.12), Vector3.ZERO))
	L._balance(M, aile, Vector3.RIGHT, 0.05, 1.3)
	var rubans: Array = []
	var rc: Array = [Color(0.95, 0.3, 0.3), Color(0.98, 0.8, 0.25), Color(0.35, 0.75, 0.45), Color(0.3, 0.55, 0.95), Color(0.85, 0.45, 0.9)]
	for i in range(5):
		var ru: Node3D = I._node(M, R.P(tx - 0.3 + i * 0.15, 1.5 - (i % 2) * 0.35, tm + 0.3))
		L._mesh(ru, I._boxm(Vector3(0.025, 0.004, 0.9)), L._m(M, "ruban117_%d" % i, rc[i], 0.7, 0.0, 0.0, true), Transform3D(Basis(), Vector3(0, 0, 0.45)))
		rubans.append(ru)
	var fumee := CPUParticles3D.new()
	fumee.amount = 40
	fumee.lifetime = 2.2
	fumee.preprocess = 2.0
	fumee.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	fumee.emission_box_extents = Vector3(0.3, 0.3, 0.05)
	fumee.direction = Vector3(0, 0, 1)
	fumee.spread = 6.0
	fumee.gravity = Vector3.ZERO
	fumee.initial_velocity_min = 1.6
	fumee.initial_velocity_max = 2.2
	fumee.scale_amount_min = 0.03
	fumee.scale_amount_max = 0.06
	var fq := QuadMesh.new()
	var fmat := StandardMaterial3D.new()
	fmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fmat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	fmat.billboard_keep_scale = true
	fmat.albedo_color = Color(1, 1, 1, 0.5)
	fmat.albedo_texture = R.dot_texture()
	fq.material = fmat
	fumee.mesh = fq
	M.room.add_child(fumee)
	fumee.global_position = R.P(tx, 1.3, z0 + 0.4)
	M.ctx["vent117"] = 1.0
	L._chaque(M, func(_delta: float, t: float) -> void:
		var v: float = float(M.ctx.get("vent117", 1.0))
		for j in range(rubans.size()):
			var ru2: Node3D = rubans[j]
			if is_instance_valid(ru2):
				ru2.rotation = Vector3(sin(t * (5.0 + j) * v * 0.6) * 0.08 * v, sin(t * (7.0 + j * 1.3) * v * 0.6 + j) * 0.12 * v, 0.0)
		if is_instance_valid(fumee):
			fumee.initial_velocity_min = 1.6 * v
			fumee.initial_velocity_max = 2.2 * v)
	# la chambre à nuages (à droite) : un grand cylindre de verre où tourne un nuage
	var cc: Vector3 = R.P(hw - 1.3, 0, -0.6)
	k.cyl(Transform3D(Basis(), cc), 0.6, 0.65, 0.4, "ceramique", 24)
	k.cyl(Transform3D(Basis(), cc + Vector3.UP * 0.4), 0.48, 0.48, 2.0, "verre", 24, false)
	k.cyl(Transform3D(Basis(), cc + Vector3.UP * 2.4), 0.6, 0.55, 0.25, "ceramique", 24)
	k.ring(Transform3D(Basis(), cc + Vector3.UP * 0.41), 0.44, 0.5, 0.02, "lumiere", 24)
	k.col_cyl(cc, 0.65, 2.65)
	R.reserve(hw - 1.3, -0.6, 1.4, 1.4)
	var tourbillon: Node3D = I._node(M, cc + Vector3.UP * 1.4)
	var nm: StandardMaterial3D = L._m(M, "nuage117", Color(1.0, 0.99, 0.96), 0.9, 0.0, 0.9)
	for j2 in range(7):
		var a2: float = TAU * j2 / 7.0
		L._mesh(tourbillon, I._sph(0.12 + (j2 % 3) * 0.03), nm, Transform3D(Basis(), Vector3(cos(a2) * 0.22, -0.4 + j2 * 0.13, sin(a2) * 0.22)))
	L._tourne(M, tourbillon, Vector3.UP, 1.4, true)
	var brume: CPUParticles3D = _brume(M, cc + Vector3.UP * 1.3, Vector3(0.3, 0.7, 0.3), 24, 0.05, 0.1, 3.0)
	# les écrans du mur du fond, les bureaux et leurs chaises
	var ecrans: Array = [["nuees/isobares.png", 0.6, Vector2(1.9, 1.2)], ["nuees/radar.png", 2.75, Vector2(1.2, 1.2)], ["nuees/ecran_mesures.png", 4.75, Vector2(1.9, 1.2)]]
	for ec in ecrans:
		var ex: float = float(ec[1])
		var sz: Vector2 = ec[2]
		k.box(R.L(ex, 2.3, -hd + 0.04), Vector3(sz.x + 0.1, sz.y + 0.1, 0.04), "noir", 1.0)
		_panneau(M, R.L(ex, 2.3, -hd + 0.07), sz, _ecran(M, str(ec[0]), 1.0))
		R.mark_wall(ex, 2.3, -hd, sz.x * 0.5 + 0.1)
	for dx in [1.1, 3.9]:
		k.box(R.L(dx, 0.74, -hd + 1.6), Vector3(1.6, 0.05, 0.75), "ceramique", 1.0)
		for s in [-1.0, 1.0]:
			k.box(R.L(dx + s * 0.72, 0.37, -hd + 1.6), Vector3(0.05, 0.74, 0.7), "argent", 1.0)
		k.box(R.L(dx, 1.0, -hd + 1.35), Vector3(0.6, 0.38, 0.03), "noir", 1.0)
		_panneau(M, R.L(dx, 1.0, -hd + 1.37), Vector2(0.56, 0.34), _ecran(M, "nuees/ecran_mesures.png", 0.8))
		k.col_box(R.L(dx, 0.4, -hd + 1.6), Vector3(1.6, 0.8, 0.75))
		R.reserve(dx, -hd + 1.6, 1.8, 1.1)
		_chaise_blanche(M, dx, -hd + 2.35, 180.0)
	# le ballon-sonde (dégonflé, sur son chariot, près de l'entrée), la rose des vents au sol
	var bc: Vector3 = R.P(hw - 1.2, 0, hd - 1.6)
	k.box(Transform3D(Basis(), bc + Vector3.UP * 0.45), Vector3(0.9, 0.06, 0.6), "argent", 1.0)
	for s4 in [-1.0, 1.0]:
		k.cyl(Transform3D(Basis(Vector3.BACK, PI * 0.5), bc + Vector3(s4 * 0.4, 0.1, 0.25)), 0.1, 0.1, 0.05, "noir", 12)
		k.cyl(Transform3D(Basis(Vector3.BACK, PI * 0.5), bc + Vector3(s4 * 0.4, 0.1, -0.25)), 0.1, 0.1, 0.05, "noir", 12)
	var ballon: StandardMaterial3D = L._m(M, "ballon117", Color(0.97, 0.97, 0.95), 0.4)
	L._mesh(I._node(M, bc + Vector3.UP * 0.8), I._sph(0.42), ballon, Transform3D(Basis.from_scale(Vector3(1.0, 0.75, 1.0)), Vector3.ZERO))
	k.box(Transform3D(Basis(), bc + Vector3(0.0, 0.55, 0.0)), Vector3(0.2, 0.16, 0.2), "tissu_orange", 1.0)
	k.col_box(Transform3D(Basis(), bc + Vector3.UP * 0.6), Vector3(0.9, 1.2, 0.6))
	R.reserve(hw - 1.2, hd - 1.6, 1.2, 1.0)
	var rose: Vector3 = R.P(0.4, 0.012, 0.6)
	k.ring(Transform3D(Basis(), rose), 1.05, 1.15, 0.006, "argent", 32)
	for j3 in range(8):
		var a3: float = TAU * j3 / 8.0
		var ln: float = 1.0 if j3 % 2 == 0 else 0.6
		k.box(Transform3D(Basis(Vector3.UP, -a3), rose + Vector3(cos(a3), 0, sin(a3)) * ln * 0.5), Vector3(ln, 0.006, 0.08 if j3 % 2 == 0 else 0.05), "argent" if j3 % 2 == 0 else "cuivre", 1.0)
	L._lampe(M, R.P(-hw + 1.6, 2.5, -0.8), Color(0.92, 0.96, 1.0), 0.6, 4.5)
	L._lampe(M, R.P(2.5, 2.8, -hd + 1.8), Color(0.75, 0.88, 1.0), 0.7, 5.0)
	_plante(M, -hw + 0.6, hd - 0.7, 1.1)
	# les gens
	if nuit:
		var veil: Node = L._gens(M, "homme", 1.1, -hd + 2.35, 180, "lire", ["Veille de nuit : je surveille les nuages pendant qu'ils dorment. Ils ronflent un peu, à l'ouest.",
			"Le radar ne montre rien. C'est la meilleure nouvelle d'une nuit de veille."])
		L._causer(M, veil, ["Bonsoir ! Doucement, les écrans dorment à moitié.", "Bon vent ! Tu veux le bulletin de nuit ? Il est très court : « tout va bien »."],
			[["nuit", "Que surveille-t-on la nuit ?", ["Le vent, la brume, et les orages qui pourraient monter du Plancher. Si un orage approche, on prévient l'Ingénieure Nova : les Sustentateurs n'aiment pas les éclairs. Moi non plus."]]])
		M.ctx["entree"] = "L'Institut des Vents, la nuit : les écrans luisent en bleu, la chambre à nuages tourne toute seule, et le veilleur de nuit boit son thé en regardant le radar."
	else:
		var sa: Node = L._gens(M, "femme", 1.1, -hd + 2.35, 180, "lire", ["Pression : mille treize. Vent : d'ouest. Humeur du ciel : excellente.", "Je compare les nuages d'aujourd'hui à ceux d'il y a cent ans. Ils ont un peu grandi. Comme nous."])
		L._causer(M, sa, ["Bonjour ! Bienvenue à l'Institut des Vents. Ici, on écoute le ciel, et parfois il répond.", "Bon vent ! Au sens propre : le vent est bon, aujourd'hui. Je l'ai mesuré."],
			[["aurele", "Où est le Docteur Aurèle ?", ["Le Docteur Aurèle Brise ? Il est sur le terrain, c'est-à-dire sur la Promenade, en train de regarder le ciel avec ses jumelles. Il baptise les nouveaux nuages. Il en a nommé un « Gaston-du-Mardi »."]],
			["soufflerie", "À quoi sert la soufflerie ?", ["On y essaie les ailes des planeurs d'Icare, les hélices des parapluies de Mireille, et parfois des chapeaux. Le vent souffle toujours dans le même sens, dans la soufflerie. C'est reposant."]]])
		L._gens(M, "homme", 3.9, -hd + 2.35, 180, "lire", ["Le radar montre un nuage en forme de baleine. Le Docteur Aurèle voudra le baptiser. Je propose « Mathilde ».", "Si tu entends un bip, c'est un nouveau nuage qui entre dans la carte. Bip ! … Voilà."])
		var tech: Node = L._gens(M, "homme", tx + 1.0, -0.3, -90, "bricoler", ["Je règle la soufflerie pour l'aile du nouveau planeur d'Icare. Il la veut plus légère qu'une plume. On en est à plume et demie.", "Attention, si je mets la soufflerie à fond, les rubans font la fête."])
		L._causer(M, tech, ["Bonjour ! Tu veux lancer la soufflerie ? Le bouton est là. Pas trop longtemps : les rubans se fatiguent.", "Bon vent ! Ici, on fabrique du vent. Du vent bien droit, bien poli."], [])
		var st2: Node = L._gens(M, "femme", -1.6, hd - 1.4, 0, "marcher", ["Le bulletin de midi, pour l'affichage ! Pardon !", "Encore trois cartes à classer, et je vais lâcher le ballon-sonde avec l'équipe."])
		var dossier: Node3D = Node3D.new()
		st2.npc.add_child(dossier)
		var dm: StandardMaterial3D = L._m(M, "dossier117", Color(0.55, 0.7, 0.9), 0.8)
		L._mesh(dossier, I._boxm(Vector3(0.3, 0.05, 0.22)), dm, Transform3D(Basis(), Vector3(0, 1.0, 0.3)))
		L._va_et_vient(M, st2, R.P(-1.6, 0, hd - 1.4), R.P(2.5, 0, -hd + 2.9), 0.9, 3.0, dossier)
		M.ctx["entree"] = str(L._pick(M, ["L'Institut des Vents : des écrans pleins de cartes et de flèches, une longue soufflerie où des rubans dansent, et une colonne de verre où tourne un petit nuage.",
			"Ffffffff… La soufflerie souffle dans son tunnel de verre. Les météorologues, eux, chuchotent, comme s'ils avaient peur de réveiller un orage.",
			"« Bip ! » Un nouveau nuage vient d'entrer sur la carte. À l'Institut des Vents, on les compte, on les mesure, et on leur donne un nom."]))
	# ce qu'on fait : lancer la soufflerie, regarder la chambre à nuages, lire le bulletin
	M.act(R.P(tx + 0.8, 1.0, z1 + 0.4), "E : lancer la soufflerie", func() -> void:
		if float(M.ctx.get("vent117", 1.0)) > 1.5:
			return
		M.main.sfx("bourrasque", R.P(tx, 1.3, tm))
		M.ctx["vent117"] = 3.5
		M.ctx["vite116"] = 4.0
		M.say(str(L._pick(M, ["Tu appuies sur le gros bouton : l'hélice hurle, la fumée file dans le tunnel, les rubans claquent comme des drapeaux, et la petite aile tremble de tout son long.",
			"VRROUUM ! La soufflerie se déchaîne. Dans le tunnel, les rubans font la fête ; dehors, ta mèche de cheveux aussi."])), 5.0)
		await M.get_tree().create_timer(6.0).timeout
		if not _la(M, room0):
			return
		M.ctx["vent117"] = 1.0
		M.ctx["vite116"] = 1.0
		var st: Dictionary = M.state()
		if not bool(st.get("plume117", false)):
			st["plume117"] = true
			M.bonne_action_v120()  ## V120 : un service rendu, l'île s'en souvient
			M.give([["plume_vent", 1]], "Une plume blanche s'est envolée de la soufflerie et s'est posée sur ton épaule. « Garde-la, dit le technicien, c'est une plume de vent : elle porte chance aux pilotes. » Tu reçois :\n")
	, 1.6)
	M.act(cc + Vector3(-0.6, 1.2, 0.6), "E : regarder la chambre à nuages", func() -> void:
		M.main.sfx("cristal_chante", cc)
		_bouffee(M, brume, 60, 3.0)
		M.say(str(L._pick(M, ["Dans la colonne de verre, un petit nuage tourne sur lui-même. Il grossit, s'éclaircit, puis laisse tomber trois gouttes de pluie, très fier de lui. C'est ainsi qu'on étudie la naissance des nuages.",
			"Le nuage de la chambre tourne lentement, comme une toupie de coton. Une étiquette dit : « Ne pas tapoter le verre. Il est timide. »",
			"Pfff… La brume monte dans le cylindre et se change en nuage. Un météorologue te souffle : « C'est comme ça que naissent ceux du matin, sous l'île. »"])), 7.0)
	, 1.5)
	M.act(R.P(2.75, 1.4, -hd + 1.0), "E : lire le bulletin du jour", func() -> void:
		var h: float = float(M.ctx.get("hour", 12.0))
		var key: String = "nuit" if (h >= 21.0 or h < 6.0) else ("matin" if h < 12.0 else ("jour" if h < 18.0 else "soir"))
		M.say(str(BULLETINS[key]), 8.0)
	, 1.6)


# =================================================================== la Tour du Zénith

const VUES_ZENITH := [
	["Plein sud, tout en bas : Hautefond, la Grande Colonne qui brille comme une aiguille d'or, le Grand Marché, et le Phare de la Pointe. Une cabine dorée monte le long de la Colonne. On dirait une perle sur un fil.",
		"Plein sud, tout en bas : les lumières de Hautefond, la Colonne illuminée de haut en bas, et le Phare qui tourne. D'ici, la ville ressemble à un gâteau d'anniversaire."],
	["À l'est : la mer, à perte de vue, et sur l'eau, une petite bouée-phare. Juste en dessous, au fond de la mer, il y a le Dôme d'Azur. On ne le voit pas, mais on le sait. C'est presque pareil.",
		"À l'est : la mer est noire et calme. Une petite lumière clignote sur l'eau : la bouée-phare du Dôme d'Azur. Quelque part, très loin sous elle, une baleine chante."],
	["À l'ouest : le Parc des Brumes, l'étang, la Cascade des Nuées qui tombe dans le vide et se change en nuage ; et au bout du ponton, la Libellule, amarrée par le nez.",
		"À l'ouest : la Navette circulaire passe, toute éclairée, comme un collier de lanternes autour de l'île. Au-dessus, des milliers d'étoiles. Le guide dit qu'il en a compté trois cents. Il s'est arrêté pour dormir."],
]


## Le plan des étages du hall (on en lit un au hasard).
const ETAGES_ZENITH := ["PLAN DES ÉTAGES. Rez-de-chaussée : le hall. Du premier au cinquième : des appartements (et un chat qui prend l'ascenseur tout seul). Sixième : le jardin suspendu. Quatorzième : le sommet, ouvert à tous.",
	"PLAN DES ÉTAGES. Septième : les bureaux de l'Institut des Vents (pour les nuages trop grands pour l'Institut). Huitième : l'école de musique. Neuvième : silence, on y fait la sieste. Quatorzième : le sommet.",
	"PLAN DES ÉTAGES. Dixième : le club des tricoteuses de nuages. Onzième : un dentiste (il a la plus belle vue de la Cité, et personne ne la regarde). Douzième : complet. Treizième : il n'y a pas de treizième. Quatorzième : le sommet.",
	"Un mot, punaisé sous le plan : « Merci de ne pas faire de courses d'ascenseur. Signé : l'ascenseur. »"]


## La Tour du Zénith : le hall rond, l'ascenseur de verre au milieu, l'accueil, les bancs, les arbres en
## pots ; au sommet (l'étage : une deuxième pièce), la salle panoramique toute en verre, ses longues-vues
## (Hautefond, la mer et le Dôme, le Parc et la Libellule ; la nuit, les lumières et les étoiles).
static func _zenith(M) -> void:
	var R = M.R
	var k = R.kit
	var nuit: bool = L._nuit(M)
	# le puits de l'ascenseur, au milieu du hall
	_ascenseur(M, R.P(0, 0, 0), R.H)
	# l'accueil (à droite), les bancs, les arbres en pots, les photos de la Cité
	var ac: Transform3D = R.L(3.2, 0, -1.4, -60)
	k.box(ac * Transform3D(Basis(), Vector3(0, 0.55, 0)), Vector3(2.0, 1.1, 0.6), "ceramique", 1.0)
	k.box(ac * Transform3D(Basis(), Vector3(0, 1.12, 0.05)), Vector3(2.2, 0.05, 0.75), "bois", 1.0)
	k.box(ac * Transform3D(Basis(), Vector3(0, 0.55, 0.31)), Vector3(1.8, 0.04, 0.01), "lumiere", 1.0)
	k.col_box(ac * Transform3D(Basis(), Vector3(0, 0.55, 0)), Vector3(2.0, 1.1, 0.6))
	R.reserve(3.2, -1.4, 2.4, 1.6)
	for a in [150.0, 210.0]:
		var bp: Vector3 = L._contre(a, 4.9)
		var bx: Transform3D = R.L(bp.x, 0, bp.y, bp.z)
		k.box(bx * Transform3D(Basis(), Vector3(0, 0.43, 0)), Vector3(1.6, 0.06, 0.45), "bois", 1.0)
		for s in [-1.0, 1.0]:
			k.box(bx * Transform3D(Basis(), Vector3(s * 0.7, 0.2, 0)), Vector3(0.05, 0.4, 0.4), "argent", 1.0)
		k.col_box(bx * Transform3D(Basis(), Vector3(0, 0.25, 0)), Vector3(1.6, 0.5, 0.45))
	for a2 in [60.0, 120.0]:
		var pp: Vector3 = L._contre(a2, 4.7)
		_plante(M, pp.x, pp.y, 1.7)
	var ph: Vector3 = L._contre(270.0, 5.85)
	for e in [[-0.75, "nuees/tableau_cascade.png", Vector2(0.9, 1.2)], [0.75, "nuees/affiche_ligne.png", Vector2(0.9, 1.2)]]:
		_panneau(M, R.L(ph.x + float(e[0]), 1.8, ph.y, 0), e[2], _ecran(M, str(e[1]), 0.05))
	# les gens du hall
	var acc: Node = L._gens(M, "femme", 3.75, -2.0, -60, "comptoir", ["Bon vent ! L'ascenseur monte au sommet en vingt secondes. Le record, c'est Théo : il est monté à pied, en dix minutes, pour voir.",
		"Le sommet est ouvert jusqu'à minuit. Après, ce sont les étoiles qui le visitent."])
	L._causer(M, acc, ["Bienvenue à la Tour du Zénith ! Quatorze étages, et tout en haut, la plus belle vue de l'archipel.", "Bon vent ! Tu montes au sommet ? L'ascenseur est au milieu. Il est en verre : ne regarde pas tes pieds."],
		[["tour", "Qui habite dans la tour ?", ["Quatorze étages d'appartements, de jardins et de bureaux, qui tournent un peu à chaque étage : c'est la torsade. Tout en haut, la salle panoramique, ouverte à tout le monde. C'est la règle de la Cité : le plus haut appartient à tous."]],
		["sommet", "Qu'est-ce qu'on voit du sommet ?", ["Tout ! Hautefond et la Colonne tout en bas, la mer, la bouée du Dôme d'Azur, le Parc des Brumes, la Libellule… Prends le temps de regarder dans les longues-vues."]]])
	if not nuit:
		L._gens(M, "homme", -3.6, 1.6, 120, "observer", ["J'attends ma femme. Elle est montée au sommet il y a une heure. Elle dit qu'elle n'a pas encore fini de regarder.", "Quatorze étages qui tournent… Je me demande qui a eu le tournis le premier : l'architecte ou la tour."])
	# la cabine de l'ascenseur : elle descend du plafond, attend, remonte ; au-dessus du puits, l'étage où
	# elle est (des chiffres seulement) ; à côté, le bouton d'appel
	var cab: Node3D = I._node(M, R.P(0, 0.04, 0))
	L._mesh(cab, L._cylm(0.9, 0.9, 0.06, 24), _blanc(M))
	L._mesh(cab, L._cylm(0.9, 0.9, 0.05, 24), _blanc(M), Transform3D(Basis(), Vector3(0, 2.28, 0)))
	L._mesh(cab, L._tore(0.84, 0.88), _led(M, Color(0.75, 0.9, 1.0), 1.6), Transform3D(Basis(), Vector3(0, 2.24, 0)))
	for i3 in range(3):
		var a3: float = TAU * i3 / 3.0 + 0.5
		L._mesh(cab, L._cylm(0.02, 0.02, 2.25, 6), _acier(M), Transform3D(Basis(), Vector3(cos(a3) * 0.86, 1.15, sin(a3) * 0.86)))
	var et: Label3D = Label3D.new()
	et.text = "0"
	et.font_size = 64
	et.pixel_size = 0.004
	et.modulate = Color(0.55, 0.85, 1.0)
	et.outline_size = 0
	M.room.add_child(et)
	et.global_transform = R.L(0, R.H - 0.55, 1.13)
	k.box(R.L(0, R.H - 0.55, 1.1), Vector3(0.5, 0.32, 0.03), "noir", 1.0)
	var bt: Transform3D = R.L(1.4, 0, 0.8, -30)
	k.box(bt * Transform3D(Basis(), Vector3(0, 0.6, 0)), Vector3(0.12, 1.2, 0.12), "argent", 1.0)
	k.box(bt * Transform3D(Basis(), Vector3(0, 1.12, 0.065)), Vector3(0.08, 0.08, 0.02), "lumiere", 1.0)
	k.col_box(bt * Transform3D(Basis(), Vector3(0, 0.6, 0)), Vector3(0.15, 1.2, 0.15))
	# le cycle de la cabine (en secondes) : en bas, elle monte, en haut (cachée), elle redescend
	M.ctx["cab117"] = 0.0
	L._chaque(M, func(delta: float, _t: float) -> void:
		if not is_instance_valid(cab):
			return
		var phc: float = fmod(float(M.ctx.get("cab117", 0.0)) + delta, 26.0)
		M.ctx["cab117"] = phc
		var y: float = 0.04
		if phc < 7.0:
			y = 0.04
		elif phc < 11.0:
			y = lerpf(0.04, R.H + 0.4, smoothstep(7.0, 11.0, phc))
		elif phc < 20.0:
			y = R.H + 0.4
		elif phc < 24.0:
			y = lerpf(R.H + 0.4, 0.04, smoothstep(20.0, 24.0, phc))
		var p0: Vector3 = R.P(0, 0, 0)
		cab.global_position = Vector3(p0.x, p0.y + y, p0.z)
		var etage: int = 0
		if phc >= 7.0 and phc < 11.0:
			etage = int(round(14.0 * smoothstep(7.0, 11.0, phc)))
		elif phc >= 11.0 and phc < 20.0:
			etage = 14
		elif phc >= 20.0 and phc < 24.0:
			etage = int(round(14.0 * (1.0 - smoothstep(20.0, 24.0, phc))))
		et.text = str(etage))
	M.act(bt * Vector3(0, 1.1, 0.4), "E : appeler l'ascenseur", func() -> void:
		var ph2: float = float(M.ctx.get("cab117", 0.0))
		if ph2 < 7.0:
			M.say(str(L._pick(M, ["Tu appuies sur le bouton. « Ding ! » La cabine est déjà là : elle t'attendait.", "Le bouton s'allume en bleu. La cabine, juste devant toi, a l'air de dire : « Je suis là, voyons ! »"])), 4.0)
		else:
			M.ctx["cab117"] = 20.0 if ph2 < 20.0 else ph2
			M.say(str(L._pick(M, ["Tu appuies sur le bouton. Tout là-haut, la cabine t'a entendu : elle redescend des nuages.", "Le bouton s'allume en bleu. Quatorze, treize, douze… La cabine arrive, sans se presser."])), 4.0)
		M.main.sfx("holo_bip", bt.origin)
	, 0.9)
	# le plan des étages, au mur : qui habite où
	var pe: Vector3 = L._contre(300.0, 5.8)
	var pt: Transform3D = R.L(pe.x, 1.7, pe.y, pe.z)
	k.box(pt, Vector3(1.0, 1.4, 0.04), "ceramique", 1.0)
	for i4 in range(14):
		k.box(pt * Transform3D(Basis(), Vector3(-0.18, -0.6 + i4 * 0.09, 0.025)), Vector3(0.5, 0.025, 0.01), "argent", 1.0)
		k.box(pt * Transform3D(Basis(), Vector3(0.36, -0.6 + i4 * 0.09, 0.025)), Vector3(0.06, 0.04, 0.01), "lumiere" if i4 == 13 else "noir", 1.0)
	M.act(pt * Vector3(0, -0.5, 0.6), "E : lire le plan des étages", func() -> void:
		M.say(str(L._pick(M, ETAGES_ZENITH)), 9.0)
	, 1.2)
	# la maquette de la tour, sur son socle : ses quatorze étages qui tournent un peu chacun
	var mp: Vector3 = R.P(-3.0, 0, -2.2)
	k.cyl(Transform3D(Basis(), mp), 0.42, 0.48, 0.95, "ceramique", 20)
	k.col_cyl(mp, 0.5, 1.0)
	R.reserve(-3.0, -2.2, 1.2, 1.2)
	var tour: Node3D = I._node(M, mp + Vector3.UP * 0.95)
	var vt: StandardMaterial3D = L._m(M, "verre_tour117", Color(0.7, 0.86, 0.96, 0.55), 0.08)
	for i5 in range(14):
		L._mesh(tour, I._boxm(Vector3(0.32, 0.045, 0.32)), _blanc(M) if i5 % 2 == 0 else vt, Transform3D(Basis(Vector3.UP, i5 * 0.07), Vector3(0, 0.03 + i5 * 0.05, 0)))
	L._mesh(tour, L._cylm(0.17, 0.17, 0.07, 16), vt, Transform3D(Basis(), Vector3(0, 0.76, 0)))
	L._tourne(M, tour, Vector3.UP, 0.25)
	M.act(mp + Vector3(0.5, 1.1, 0.5), "E : regarder la maquette de la tour", func() -> void:
		M.say(str(L._pick(M, ["La Tour du Zénith en tout petit : quatorze étages, et chacun tourne un peu par rapport à celui du dessous. Vue d'en haut, elle ressemble à un escalier pour géant.",
			"Une petite plaque : « Maquette offerte par les élèves de l'école des Nuées. Échelle : un centimètre pour un mètre. Chaque étage a été collé par un enfant différent. »",
			"Tu fais tourner la maquette du doigt. Elle tourne déjà toute seule ; maintenant, elle tourne un peu plus vite, et a l'air ravie."])), 7.0)
	, 1.1)
	# l'étage : le sommet de la tour
	var top: Vector3 = R.P(0, 0, UPZ)
	_sommet(M, top, nuit)
	M.act(R.P(0, 1.1, 1.25), "E : monter au sommet", func() -> void:
		M.main.sfx("ascenseur_tour", R.P(0, 1.0, 0))
		M.go(top + Vector3(0, 0.05, 1.6), Vector3(0, 0, 1))
	, 1.4)
	M.act(top + Vector3(0, 1.1, 1.25), "E : redescendre", func() -> void:
		M.main.sfx("ascenseur_tour", top)
		M.go(R.P(0, 0.05, 1.6), Vector3(0, 0, 1))
	, 1.4)
	M.ctx["entree"] = "La Tour du Zénith : un grand hall rond et clair, des arbres en pots, et au milieu, un ascenseur de verre qui monte tout droit vers le ciel." if not nuit else "Le hall de la Tour du Zénith, le soir : les arbres en pots dorment, l'ascenseur de verre luit doucement. Au sommet, paraît-il, les étoiles sont toutes proches."


## Le puits de l'ascenseur de verre (au milieu d'une pièce ronde) : la cabine, les montants, les anneaux.
static func _ascenseur(M, c: Vector3, h: float) -> void:
	var R = M.R
	var k = R.kit
	k.cyl(Transform3D(Basis(), c), 1.0, 1.0, h, "verre", 24, false)
	for i in range(6):
		var a: float = TAU * i / 6.0
		k.box(Transform3D(Basis(), c + Vector3(cos(a) * 1.0, h * 0.5, sin(a) * 1.0)), Vector3(0.06, h, 0.06), "argent", 1.0)
	for y in [0.0, 2.3, h - 0.12]:
		k.ring(Transform3D(Basis(), c + Vector3.UP * y), 0.98, 1.08, 0.12, "argent", 24)
	k.disc(Transform3D(Basis(), c + Vector3.UP * 0.02), 0.95, "ceramique", 24)
	k.ring(Transform3D(Basis(), c + Vector3.UP * 0.9), 0.82, 0.86, 0.04, "argent", 24)
	k.ring(Transform3D(Basis(), c + Vector3.UP * 0.03), 1.1, 1.25, 0.02, "lumiere", 24)
	k.col_cyl(c, 1.08, h)
	R.reserve(c.x - R.origin.x, c.z - R.origin.z, 2.6, 2.6)


## Le sommet de la Tour du Zénith : une salle ronde, vitrée tout autour (un parapet blanc, le verre, un
## bandeau), l'ascenseur, trois longues-vues, des bancs ; le guide et les visiteurs (le jour), un couple
## qui regarde les étoiles (la nuit).
static func _sommet(M, c: Vector3, nuit: bool) -> void:
	var R = M.R
	var k = R.kit
	var r: float = 6.5
	var h: float = 4.0
	var seg: int = 28
	k.disc(Transform3D(Basis(), c), r + 0.35, "sol", seg, float((R.pal["sol"] as Array)[2]))
	k.col_box(Transform3D(Basis(), c + Vector3.DOWN * 0.25), Vector3(2.0 * r + 1.0, 0.5, 2.0 * r + 1.0))
	k.disc(Transform3D(Basis(Vector3.RIGHT, PI), c + Vector3.UP * h), r + 0.35, "plafond", seg, float((R.pal["plafond"] as Array)[2]))
	k.col_box(Transform3D(Basis(), c + Vector3.UP * (h + 0.35)), Vector3(2.0 * r + 1.0, 0.5, 2.0 * r + 1.0))
	var chord: float = 2.0 * r * sin(PI / seg) + 0.04
	for i in range(seg):
		var am: float = PI * 0.5 + TAU * i / seg
		var dirv := Vector3(cos(am), 0, sin(am))
		var xf := Transform3D(Basis.looking_at(-dirv, Vector3.UP), c + dirv * (r + 0.1))
		k.box(xf * Transform3D(Basis(), Vector3(0, 0.45, 0)), Vector3(chord, 0.9, 0.2), "ceramique", 1.0)
		k.box(xf * Transform3D(Basis(), Vector3(0, 2.3, 0.05)), Vector3(chord, 2.8, 0.02), "verre", 1.0, 32)
		k.box(xf * Transform3D(Basis(), Vector3(0, 3.85, 0)), Vector3(chord, 0.3, 0.2), "ceramique", 1.0)
		k.box(xf * Transform3D(Basis(), Vector3(chord * 0.5, 2.3, -0.06)), Vector3(0.05, 2.9, 0.06), "argent", 1.0)
		k.col_box(xf * Transform3D(Basis(), Vector3(0, h * 0.5, 0)), Vector3(chord, h + 0.4, 0.2))
	k.ring(Transform3D(Basis(), c + Vector3.UP * 0.9), r - 0.12, r - 0.02, 0.05, "bois", seg)
	# derrière le verre, tout autour : le ciel, l'horizon, la mer de nuages (ou les étoiles)
	var rb: float = r + 0.7
	_bande(M, c, rb, 0.85, 3.75, R.vue_v(rad_to_deg(atan((3.75 - 1.6) / rb))), R.vue_v(-10.0))
	_ascenseur(M, c, h)
	# trois longues-vues, tournées vers dehors (au sud, à l'est, à l'ouest)
	var lv: Array = []
	for e in [[90.0, 0], [330.0, 1], [210.0, 2]]:
		var a: float = deg_to_rad(float(e[0]))
		var p: Vector3 = c + Vector3(cos(a), 0, sin(a)) * (r - 1.1)
		var face := Vector3(cos(a), 0, sin(a))
		for j in range(3):
			var aj: float = TAU * j / 3.0
			_beam(M, p + Vector3(cos(aj), 0, sin(aj)) * 0.28, p + Vector3.UP * 1.15, 0.018, "argent")
		var tube: Node3D = I._node(M, p + Vector3.UP * 1.2, rad_to_deg(atan2(face.x, face.z)))
		L._mesh(tube, L._cylm(0.055, 0.075, 0.75, 14), L._laiton(M), Transform3D(Basis(Vector3.RIGHT, PI * 0.5 - 0.15), Vector3(0, 0.03, 0.15)))
		L._mesh(tube, L._cylm(0.03, 0.03, 0.12, 10), _acier(M), Transform3D(Basis(Vector3.RIGHT, PI * 0.5 - 0.15), Vector3(0, -0.03, -0.27)))
		k.col_cyl(p, 0.3, 1.3)
		lv.append([p, int(e[1])])
	# deux bancs face au ciel
	for a2 in [45.0, 135.0]:
		var bp: Vector3 = c + Vector3(cos(deg_to_rad(a2)), 0, sin(deg_to_rad(a2))) * 3.6
		var bx := Transform3D(Basis.looking_at(-(bp - c).normalized(), Vector3.UP), bp)
		k.box(bx * Transform3D(Basis(), Vector3(0, 0.43, 0)), Vector3(1.6, 0.06, 0.45), "bois", 1.0)
		k.box(bx * Transform3D(Basis(), Vector3(0, 0.2, 0)), Vector3(1.4, 0.4, 0.3), "ceramique", 1.0)
		k.col_box(bx * Transform3D(Basis(), Vector3(0, 0.25, 0)), Vector3(1.6, 0.5, 0.45))
	L._lampe(M, c + Vector3.UP * 3.2, Color(1.0, 0.96, 0.9) if not nuit else Color(0.6, 0.7, 1.0), 1.0 if not nuit else 0.35, 9.0)
	k.ring(Transform3D(Basis(), c + Vector3.UP * (h - 0.06)), 2.2, 2.35, 0.03, "lumiere", 32)
	# les gens du sommet
	var lc: Vector3 = R.origin
	if nuit:
		var f1: Node = L._gens(M, "femme", c.x - lc.x - 2.6, c.z - lc.z - 3.4, 200, "observer", ["Regarde : l'étoile qui clignote, là. Le Docteur Aurèle dit que c'est un phare, très loin. Moi, je préfère que ce soit une étoile.",
			"D'ici, on voit les lumières de Hautefond, tout en bas, et les étoiles, tout en haut. Et nous, au milieu. C'est une bonne place."])
		L._gens(M, "homme", c.x - lc.x - 1.9, c.z - lc.z - 3.9, 190, "observer", ["Chut… on regarde les étoiles filantes. Il en est passé trois. J'ai fait trois vœux. Le troisième, c'était d'avoir encore des vœux.", "On monte ici chaque soir depuis trente ans. Le ciel ne s'est jamais répété."])
		L._causer(M, f1, ["Bonsoir… Chut. Regarde le ciel.", "Bon vent ! Tu viens voir les étoiles ? Il y en a assez pour tout le monde."],
			[["etoiles", "On voit bien les étoiles, d'ici ?", ["Mieux que partout ailleurs ! On est au-dessus des nuages, et la Cité éteint ses lumières à minuit. Le Professeur Lunette, en bas, à l'Observatoire, nous envie un peu. On lui envoie des cartes postales."]]])
	else:
		var gd: Node = L._gens(M, "femme", c.x - lc.x + 0.6, c.z - lc.z + 4.3, 160, "enseigner", ["Mesdames, messieurs, à votre droite : la Grande Colonne de Hautefond. À votre gauche : la mer. Sous vos pieds : quatorze étages et une montagne qui flotte.",
			"Les longues-vues sont gratuites. Les nuages aussi. Profitez-en."])
		L._causer(M, gd, ["Bienvenue au sommet du Zénith ! Le plus haut point de la Cité des Nuées. Plus haut, il n'y a que les oiseaux. Et les ballons-sondes.", "Bon vent ! Approche, regarde dans une longue-vue : chacune montre un côté de l'archipel."],
			[["haut", "On est à quelle hauteur ?", ["Deux cents mètres au-dessus de la mer pour l'île, plus quatorze étages de tour. Les jours de grand vent, la tour se balance d'un centimètre. On ne le sent pas. Enfin, presque pas."]],
			["seraphin", "Séraphin venait ici ?", ["La tour n'existait pas encore ! Mais on raconte qu'il montait sur le plus haut rocher de l'île pour vérifier qu'elle était bien droite. Elle l'était. Elle l'est toujours."]]])
		L._gens(M, "homme", c.x - lc.x - 3.5, c.z - lc.z - 2.5, 230, "observer", ["Je vois ma maison ! … Non, c'est un nuage.", "Ma femme dit que j'ai le vertige. Je n'ai pas le vertige : j'ai beaucoup de respect pour le vide."])
		L._gens(M, "fille", c.x - lc.x + 2.7, c.z - lc.z - 3.5, 320, "pointer", ["La Libellule ! Elle passe sous nous ! Je vois le dessus d'un dirigeable !", "Je vais tout raconter à ma classe. Personne ne me croira. Alors je vais leur montrer mon dessin."])
	# ce qu'on fait : regarder par les longues-vues
	for e2 in lv:
		var p2: Vector3 = e2[0]
		var idx: int = e2[1]
		M.act(p2 + Vector3.UP * 1.0, "E : regarder par la longue-vue", func() -> void:
			M.say(str((VUES_ZENITH[idx] as Array)[1 if L._nuit(M) else 0]), 8.0)
		, 1.1)


# =================================================================== le cœur des Sustentateurs

const MESURES := ["Sustentateur numéro un : 99,8 %. Numéro deux : 99,9 %. Numéro trois : 99,8 %. Numéro quatre : 100 %. Une petite note, à côté, au crayon : « Le quatre fait le malin. »",
	"Altitude de l'île : deux cent trente-six mètres, et trois centimètres. Les trois centimètres, c'est Théo qui saute de joie dans sa capsule.",
	"Équilibre : parfait. Température du cœur : tiède. Humeur du cœur : ronronnante. (Cette dernière mesure a été ajoutée par l'Ingénieure Nova.)",
	"Heures de service sans panne : un million cinquante mille. Prochaine révision : quand il faudra. Le Sustentateur n'a pas l'air pressé."]


## Le cœur des Sustentateurs, sous la Salle des Sustentateurs : une grande salle ronde creusée dans la
## roche, le puits de lumière bleue, le grand anneau qui tourne autour d'un cœur de cristal (et un
## second anneau, en travers), les tuyaux, la passerelle, les pupitres ; les techniciens.
static func _machines(M) -> void:
	var R = M.R
	var k = R.kit
	var nuit: bool = L._nuit(M)
	var room0 = M.room
	var c: Vector3 = R.P(0, 0, -0.6)
	# le puits de lumière (un disque bleu qui luit), la rambarde de verre autour (et ses collisions)
	k.disc(Transform3D(Basis(), c + Vector3.UP * 0.015), 3.0, "cristal", 40)
	k.ring(Transform3D(Basis(), c + Vector3.UP * 0.01), 3.0, 3.5, 0.03, "argent", 40)
	var rr: float = 3.45
	for i in range(24):
		var a0: float = TAU * i / 24.0
		var a1: float = TAU * (i + 1) / 24.0
		var p0: Vector3 = c + Vector3(cos(a0), 0, sin(a0)) * rr
		var p1: Vector3 = c + Vector3(cos(a1), 0, sin(a1)) * rr
		var mid: Vector3 = (p0 + p1) * 0.5
		var bs := Basis(Vector3.UP, -(a0 + a1) * 0.5 + PI * 0.5)
		k.box(Transform3D(bs, mid + Vector3.UP * 0.55), Vector3(p0.distance_to(p1), 0.9, 0.02), "verre", 1.0)
		k.cyl(Transform3D(Basis(), p0), 0.03, 0.03, 1.05, "argent", 6, false)
		k.box(Transform3D(bs, mid + Vector3.UP * 1.05), Vector3(p0.distance_to(p1) + 0.02, 0.05, 0.07), "argent", 1.0)
		k.col_box(Transform3D(bs, mid + Vector3.UP * 0.6), Vector3(p0.distance_to(p1), 1.2, 0.15))
	R.reserve(c.x - R.origin.x, c.z - R.origin.z, 7.4, 7.4)
	# le Sustentateur : le cœur de cristal, le grand anneau, l'anneau en travers
	var anneau: StandardMaterial3D = L._m(M, "anneau117", Color(0.55, 0.78, 1.0), 0.25, 0.6, 0.9)
	var coeur_m: StandardMaterial3D = L._m(M, "coeur117", Color(0.6, 0.85, 1.0, 0.85), 0.1, 0.0, 2.4)
	var centre: Vector3 = c + Vector3.UP * 3.4
	var g1: Node3D = I._node(M, centre)
	L._mesh(g1, L._tore(2.35, 2.75), anneau, Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO))
	var g2: Node3D = Node3D.new()
	g1.add_child(g2)
	L._mesh(g2, L._tore(1.75, 2.05), anneau, Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3.ZERO))
	var coeur: Node3D = I._node(M, centre)
	L._mesh(coeur, I._sph(0.62), coeur_m)
	for j in range(6):
		var aj: float = TAU * j / 6.0
		L._mesh(coeur, L._cylm(0.0, 0.18, 0.6, 6), coeur_m, Transform3D(Basis(Vector3(cos(aj), 0, sin(aj)).cross(Vector3.UP).normalized(), 0.9), Vector3(cos(aj) * 0.35, 0.3, sin(aj) * 0.35)))
	L._tourne(M, g1, Vector3.UP, 0.35, true)
	L._tourne(M, g2, Vector3.RIGHT, -0.6, true)
	L._tourne(M, coeur, Vector3.UP, -0.2)
	# les attaches de l'anneau (quatre bras qui descendent du plafond)
	for b in range(4):
		var ab: float = TAU * b / 4.0 + PI * 0.25
		_beam(M, c + Vector3(cos(ab) * 5.5, R.H, sin(ab) * 5.5), centre + Vector3(cos(ab) * 0.9, 0.9, sin(ab) * 0.9), 0.12, "metal")
	var lum := OmniLight3D.new()
	lum.light_color = Color(0.5, 0.75, 1.0)
	lum.light_energy = 2.2
	lum.omni_range = 11.0
	lum.shadow_enabled = false
	M.room.add_child(lum)
	lum.global_position = centre
	R.lights.append(lum)
	M.ctx["pulse117"] = 1.0
	L._chaque(M, func(_delta: float, t: float) -> void:
		var pz: float = float(M.ctx.get("pulse117", 1.0))
		var s: float = 1.0 + sin(t * 2.2) * 0.05 * pz
		if is_instance_valid(coeur):
			coeur.scale = Vector3.ONE * s * (1.0 + (pz - 1.0) * 0.15)
		if is_instance_valid(lum):
			lum.light_energy = (2.0 + sin(t * 2.2) * 0.4) * pz)
	var etin: CPUParticles3D = L._poussiere(M, centre, Vector3(2.6, 2.0, 2.6), 50, Color(0.6, 0.85, 1.0, 0.8), 0.025)
	etin.gravity = Vector3(0, 0.02, 0)
	# les tuyaux le long des murs, la passerelle du haut (et sa rambarde)
	for a2 in [20.0, 55.0, 125.0, 160.0, 200.0, 235.0, 305.0, 340.0]:
		var pa: Vector3 = R.P(0, 0, 0) + Vector3(cos(deg_to_rad(a2)), 0, sin(deg_to_rad(a2))) * 7.75
		k.cyl(Transform3D(Basis(), pa), 0.14, 0.14, R.H, "cuivre" if int(a2) % 2 == 0 else "metal", 10, false)
		k.cyl(Transform3D(Basis(), pa + Vector3.UP * 0.6), 0.2, 0.2, 0.12, "argent", 10)
	k.ring(Transform3D(Basis(), R.P(0, 3.6, 0)), 6.6, 8.1, 0.12, "metal", 40)
	k.ring(Transform3D(Basis(), R.P(0, 4.6, 0)), 6.6, 6.66, 0.05, "argent", 40)
	for i2 in range(16):
		var a3: float = TAU * i2 / 16.0
		k.cyl(Transform3D(Basis(), R.P(cos(a3) * 6.63, 3.6, sin(a3) * 6.63)), 0.02, 0.02, 1.0, "argent", 6, false)
	k.ring(Transform3D(Basis(), R.P(0, 5.6, 0)), 7.7, 7.95, 0.25, "cuivre", 40)
	# les pupitres (à gauche et à droite) et leurs écrans
	var pupitres: Array = []
	for e in [[205.0, "nuees/ecran_mesures.png"], [335.0, "nuees/radar.png"]]:
		var pp: Vector3 = L._contre(float(e[0]), 6.1)
		var px: Transform3D = R.L(pp.x, 0, pp.y, pp.z)
		k.box(px * Transform3D(Basis(), Vector3(0, 0.5, 0)), Vector3(1.8, 1.0, 0.7), "ceramique", 1.0)
		k.box(px * Transform3D(Basis(Vector3.RIGHT, -0.5), Vector3(0, 1.05, 0.05)), Vector3(1.8, 0.05, 0.6), "noir", 1.0)
		_panneau(M, px * Transform3D(Basis(Vector3.RIGHT, -0.5 - PI * 0.5), Vector3(0, 1.08, 0.05)), Vector2(1.5, 0.5), _ecran(M, str(e[1]), 1.1))
		k.box(px * Transform3D(Basis(), Vector3(0, 1.75, -0.3)), Vector3(1.6, 0.9, 0.05), "noir", 1.0)
		_panneau(M, px * Transform3D(Basis(), Vector3(0, 1.75, -0.27)), Vector2(1.5, 0.82), _ecran(M, "nuees/plan_ile.png", 1.0))
		k.col_box(px * Transform3D(Basis(), Vector3(0, 0.6, 0)), Vector3(1.8, 1.2, 0.7))
		R.reserve(pp.x, pp.y, 2.2, 1.2)
		pupitres.append(px)
	L._lampe(M, R.P(0, 5.0, 4.5), Color(0.9, 0.95, 1.0), 0.6, 8.0)
	# le ronronnement
	L._souvent(M, 7.0, 13.0, func() -> void:
		M.main.sfx("ronron", centre, -6.0))
	# les gens
	var px0: Transform3D = pupitres[0]
	var t1: Node = L._gens(M, "femme", (px0 * Vector3(0, 0, 0.75)).x - R.origin.x, (px0 * Vector3(0, 0, 0.75)).z - R.origin.z, rad_to_deg(atan2(-(px0.basis * Vector3(0, 0, 1)).x, -(px0.basis * Vector3(0, 0, 1)).z)), "holo",
		["Cœur du Sustentateur numéro deux : tout va bien. Il ronronne en mi bémol. L'Ingénieure Nova dit que c'est la note du bonheur.", "Ne t'inquiète pas si le sol vibre un peu. C'est l'île qui respire."])
	L._causer(M, t1, ["Bon vent ! Bienvenue au cœur des Sustentateurs. Ne te penche pas au-dessus du puits : il est très profond, et très bleu.", "Bonjour ! Tu entends ? Ce ronronnement, c'est toute une ville qui flotte."],
		[["fonctionne", "Comment ça marche ?", ["Le cœur de cristal garde l'énergie du soleil ; l'anneau la fait tourner, et la pousse vers le bas, très loin, jusqu'à la mer. L'île s'appuie dessus, comme une main sur une table. Séraphin l'a calculé il y a cent vingt ans. Nous, on surveille."]],
		["quatre", "Il y en a quatre ?", ["Quatre Sustentateurs, aux quatre coins de l'île, sous la roche. Celui-ci est le numéro deux, le plus bavard. Si l'un d'eux s'arrête, les trois autres tiennent l'île sans souci. Mais aucun ne s'est jamais arrêté."]],
		["nova", "L'Ingénieure Nova vient ici ?", ["Tous les matins, avec son thé. Elle pose sa tasse sur la rambarde, écoute le ronronnement, et dit « bonjour, les gros ». Ils ronronnent plus fort quand elle est là. Je te jure."]]])
	var t2: Node = L._gens(M, "homme", -4.3, 2.0, 0, "marcher", ["Tour de ronde. Je vérifie la rambarde, les tuyaux, et mon pas. Tout est en ordre.", "Quand l'anneau accélère, c'est que Théo fait monter la capsule. On le sait toujours."])
	L._va_et_vient(M, t2, c + Vector3(-4.3, 0, 2.6), c + Vector3(4.3, 0, 2.6), 0.7, 3.0)
	if nuit:
		t2.lines = ["Ronde de nuit. Le cœur brille plus fort, la nuit. On dirait qu'il veille sur la ville.", "Chut… À cette heure-ci, on entend toute l'île respirer."]
	M.ctx["entree"] = str(L._pick(M, ["Tu descends l'escalier de service… et tu débouches dans une salle immense, creusée dans la roche. Au milieu, au-dessus d'un puits bleu, un anneau géant tourne lentement autour d'un cœur de cristal.",
		"Un ronronnement profond fait vibrer la rampe. Sous la Cité, dans la roche, le Sustentateur numéro deux tourne, depuis cent vingt ans, sans jamais s'arrêter.",
		"Bleu, partout. Le cœur de cristal pulse comme une respiration ; les deux anneaux tournent l'un dans l'autre. C'est donc ça, qui tient toute la Cité en l'air."]))
	# ce qu'on fait : écouter, lire les mesures, poser la main sur la rambarde
	M.act(c + Vector3(0, 1.0, 3.9), "E : poser la main sur la rambarde", func() -> void:
		M.main.sfx("cristal_chante", centre)
		M.ctx["pulse117"] = 2.2
		M.ctx["vite116"] = 1.8
		M.say(str(L._pick(M, ["Sous ta main, la rambarde vibre doucement. Le cœur de cristal s'illumine plus fort, comme s'il t'avait senti. Puis il reprend son rythme tranquille.",
			"Ça vibre, ça chante tout bas. Un technicien sourit : « Il t'aime bien. Il fait ça avec les gens qu'il aime bien. »"])), 6.0)
		await M.get_tree().create_timer(4.0).timeout
		if _la(M, room0):
			M.ctx["pulse117"] = 1.0
			M.ctx["vite116"] = 1.0
	, 1.6)
	for px2 in pupitres:
		M.act((px2 as Transform3D) * Vector3(0, 1.1, 0.7), "E : lire les mesures", func() -> void:
			M.main.sfx("holo_bip", (px2 as Transform3D).origin)
			var n: int = int(M.ctx.get("mesure117", 0))
			M.ctx["mesure117"] = n + 1
			M.say(str(MESURES[n % MESURES.size()]), 7.0)
		, 1.4)
	M.act(R.P(0, 1.2, R.D * 0.5 - 1.6), "E : écouter le ronronnement", func() -> void:
		M.main.sfx("ronron", centre)
		M.say(str(L._pick(M, ["Tu fermes les yeux. Un ronron profond, régulier, qui vient de partout à la fois : de la roche, de la rampe, de tes pieds. Cent vingt ans que ça dure. On a envie de dire merci.",
			"Rrrrrrrr… Le son est si grave qu'on le sent plus qu'on ne l'entend. Un peu comme un énorme chat qui dormirait sous toute la Cité."])), 7.0)
	, 1.6)


# =================================================================== la Libellule

const BAIES_LIBELLULE := ["Par la baie : le ciel, immense, et la Cité des Nuées vue de côté, avec sa montagne renversée qui flotte. Tout en bas, la mer brille. La Libellule tire un peu sur son amarre, comme un chien qui veut partir en promenade.",
	"Par la baie : des nuages qui passent tout près, si près qu'on pourrait les toucher. L'un d'eux a la forme d'une chouquette. Le Docteur Aurèle l'a sûrement déjà baptisé.",
	"Par la baie, la nuit : les lumières de la Cité, la Navette qui tourne, toute éclairée, et tout en bas, les lumières de Hautefond, comme une poignée d'étoiles tombée dans la mer."]
const CARTE_VENTS_NU := "LA CARTE DES VENTS DE LA LIBELLULE. Au nord, le vent des sommets, régulier : bon pour le tour de l'île. À l'ouest, la descente de la Cascade : interdite aux dirigeables (trop de brume, trop de surprises). Au sud, en bas, le Port des Cordages de Hautefond et, au crayon rouge : « Ne pas faire la course avec l'Albatros. (Sauf si Héloïse commence.) »"


## La Libellule (la nacelle du dirigeable de la Capitaine Zéphyrine, amarré au bout du Port des Nuées) :
## de longues baies sur le ciel, des fauteuils blancs face aux baies, la passerelle et sa console, la
## petite cuisine, des lampes qui se balancent ; le jour, la pilote, le steward et des passagers ; la
## nuit, le veilleur.
static func _libellule(M) -> void:
	var R = M.R
	var k = R.kit
	var nuit: bool = L._nuit(M)
	var room0 = M.room
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	# les baies : une longue bande de verre de chaque côté, et la grande baie de la passerelle
	for s in [-1.0, 1.0]:
		var xw: float = s * (hw - 0.02)
		# derrière les baies, le ciel et la mer de nuages (ou la nuit étoilée) : à bâbord, à tribord
		R.vue(R.L(xw - s * 0.012, 1.4, -0.7, -90.0 * s), Vector2(9.0, 1.3), 1.4, 0.0 if s < 0.0 else 0.5, 2.2)
		for zz in range(7):
			k.box(R.L(xw - s * 0.03, 1.4, -5.2 + zz * 1.5), Vector3(0.05, 1.36, 0.08), "ceramique", 1.0)
		k.box(R.L(xw - s * 0.05, 0.72, -0.7), Vector3(0.1, 0.05, 9.1), "argent", 1.0)
		k.box(R.L(xw - s * 0.05, 2.08, -0.7), Vector3(0.1, 0.05, 9.1), "argent", 1.0)
		R.mark_wall(xw, 1.4, -0.7, 4.6)
	R.vue(R.L(0, 1.45, -hd + 0.032), Vector2(3.6, 1.3), 1.45, 0.36, 3.0)
	k.box(R.L(0, 0.78, -hd + 0.05), Vector3(3.7, 0.05, 0.08), "argent", 1.0)
	k.box(R.L(0, 2.12, -hd + 0.05), Vector3(3.7, 0.05, 0.08), "argent", 1.0)
	R.mark_wall(0, 1.45, -hd, 1.9)
	# le bandeau lumineux du plafond, les lampes suspendues qui se balancent
	k.box(R.L(0, R.H - 0.02, -0.5), Vector3(0.3, 0.02, 9.5), "lumiere", 1.0)
	var lampes: Array = []
	for zl in [-3.6, -0.6, 2.4]:
		var lp: Node3D = I._node(M, R.P(0, R.H - 0.05, zl))
		L._mesh(lp, L._cylm(0.004, 0.004, 0.5, 4), _acier(M), Transform3D(Basis(), Vector3(0, -0.25, 0)))
		L._mesh(lp, I._sph(0.13), L._m(M, "globe_lum117", Color(1.0, 0.97, 0.9), 0.4, 0.0, 1.2), Transform3D(Basis(), Vector3(0, -0.55, 0)))
		L._balance(M, lp, Vector3.FORWARD, 0.06, 3.4 + zl * 0.1, zl)
		lampes.append(lp)
	# les fauteuils face aux baies, une table basse au milieu
	var sieges: Array = []
	for s2 in [-1.0, 1.0]:
		for zs in [-1.8, 0.2, 2.2]:
			var sx: float = s2 * (hw - 0.85)
			var fx: Transform3D = R.L(sx, 0, zs, 90.0 * s2)
			k.box(fx * Transform3D(Basis(), Vector3(0, 0.24, 0)), Vector3(0.7, 0.3, 0.68), "ceramique", 1.0)
			k.box(fx * Transform3D(Basis(), Vector3(0, 0.43, 0.04)), Vector3(0.6, 0.1, 0.58), "tissu_bleu", 1.0)
			k.box(fx * Transform3D(Basis(), Vector3(0, 0.72, -0.3)), Vector3(0.7, 0.6, 0.12), "ceramique", 1.0)
			for s3 in [-1.0, 1.0]:
				k.box(fx * Transform3D(Basis(), Vector3(s3 * 0.33, 0.52, 0.0)), Vector3(0.08, 0.22, 0.62), "ceramique", 1.0)
			k.cyl(fx, 0.2, 0.24, 0.1, "argent", 12)
			k.col_box(fx * Transform3D(Basis(), Vector3(0, 0.4, 0)), Vector3(0.7, 0.8, 0.7))
			sieges.append([sx, zs, 90.0 * s2])
	R.reserve(-hw + 0.85, 0.2, 1.0, 5.2)
	R.reserve(hw - 0.85, 0.2, 1.0, 5.2)
	_table_blanche(M, 0.0, 0.2, 0.32, 0.5)
	# la passerelle : la console, ses écrans, le manche ; la carte des vents sur sa table
	var cx: Transform3D = R.L(0, 0, -hd + 0.9)
	k.box(cx * Transform3D(Basis(), Vector3(0, 0.5, 0)), Vector3(3.0, 1.0, 0.6), "ceramique", 1.0)
	k.box(cx * Transform3D(Basis(Vector3.RIGHT, 0.5), Vector3(0, 1.02, 0.05)), Vector3(3.0, 0.05, 0.55), "noir", 1.0)
	for e in [[-0.9, "nuees/radar.png"], [0.9, "nuees/plan_ile.png"]]:
		_panneau(M, cx * Transform3D(Basis(Vector3.RIGHT, 0.5 - PI * 0.5), Vector3(float(e[0]), 1.05, 0.05)), Vector2(0.7, 0.45), _ecran(M, str(e[1]), 1.0))
	k.col_box(cx * Transform3D(Basis(), Vector3(0, 0.55, 0)), Vector3(3.0, 1.1, 0.6))
	R.reserve(0, -hd + 0.9, 3.4, 1.0)
	k.cyl(cx * Transform3D(Basis(), Vector3(0, 0.0, 0.55)), 0.06, 0.08, 0.95, "argent", 10)
	var manche: Node3D = I._node(M, cx * Vector3(0, 1.02, 0.58))
	L._mesh(manche, L._tore(0.14, 0.17), _blanc(M), Transform3D(Basis(Vector3.RIGHT, PI * 0.5 - 0.3), Vector3.ZERO))
	L._mesh(manche, I._boxm(Vector3(0.3, 0.03, 0.03)), _acier(M))
	var tc: Vector3 = R.P(1.2, 0, -2.6)
	k.box(Transform3D(Basis(), tc + Vector3.UP * 0.4), Vector3(0.8, 0.8, 0.6), "ceramique", 1.0)
	_panneau(M, Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), tc + Vector3.UP * 0.81), Vector2(0.75, 0.55), _ecran(M, "nuees/isobares.png", 0.5))
	k.col_box(Transform3D(Basis(), tc + Vector3.UP * 0.4), Vector3(0.8, 0.8, 0.6))
	R.reserve(1.2, -2.6, 1.0, 0.8)
	# la petite cuisine (au fond, près de la porte) : le comptoir, les jus de soleil
	var gx: Transform3D = R.L(hw - 0.45, 0, hd - 1.9, -90)
	k.box(gx * Transform3D(Basis(), Vector3(0, 0.5, 0)), Vector3(1.4, 1.0, 0.5), "ceramique", 1.0)
	k.box(gx * Transform3D(Basis(), Vector3(0, 1.02, 0)), Vector3(1.5, 0.04, 0.55), "bois", 1.0)
	for j in range(4):
		k.cyl(gx * Transform3D(Basis(), Vector3(-0.5 + j * 0.15, 1.04, 0.0)), 0.035, 0.035, 0.24, "tissu_orange", 10)
	for j2 in range(3):
		k.cyl(gx * Transform3D(Basis(), Vector3(0.25 + j2 * 0.14, 1.04, 0.05)), 0.035, 0.03, 0.08, "ceramique", 10)
	k.col_box(gx * Transform3D(Basis(), Vector3(0, 0.5, 0)), Vector3(1.4, 1.0, 0.5))
	R.reserve(hw - 0.45, hd - 1.9, 0.8, 1.6)
	L._lampe(M, R.P(0, 2.2, -1.5), Color(1.0, 0.96, 0.9), 0.8 if not nuit else 0.35, 6.0)
	L._lampe(M, R.P(0, 2.2, 2.4), Color(1.0, 0.96, 0.9), 0.7 if not nuit else 0.3, 5.0)
	# les gens
	if nuit:
		var veil: Node = L._gens(M, "vieux", float(sieges[1][0]), float(sieges[1][1]), float(sieges[1][2]), "lire", ["Je veille sur la Libellule pendant qu'elle dort. Elle tire un peu sur son amarre, la nuit. Elle rêve de voyages.",
			"La Capitaine Zéphyrine dort à la Capitainerie. Moi, je dors ici, d'un œil. L'autre regarde les étoiles."])
		L._causer(M, veil, ["Bonsoir ! Doucement, la Libellule dort.", "Bon vent ! Tu as raté le dernier tour de l'île. Reviens demain matin, à dix heures."],
			[["vol", "On vole la nuit ?", ["Jamais ! La Capitaine dit que la nuit appartient aux oiseaux et aux étoiles. Et puis, la Libellule a besoin de sommeil. Elle est très vieille, tu sais : quatre-vingts ans de ciel."]]])
		M.ctx["entree"] = "La Libellule, la nuit : la nacelle est sombre et silencieuse ; seule une lampe de lecture brille près d'un fauteuil, et par les baies, les lumières de la Cité."
	else:
		var pil: Node = L._gens(M, "femme", 0.0, -hd + 1.5, 180, "holo", ["Cap au nord, vent arrière. On fera le tour de l'île en quarante minutes. Ou en trente-neuf, si la Capitaine regarde.",
			"La Libellule a quatre-vingts ans. Elle grince un peu dans les virages. Comme moi."])
		L._causer(M, pil, ["Bon vent ! Bienvenue à bord de la Libellule ! Je suis la seconde de la Capitaine Zéphyrine. Ne touche pas au manche… sauf si je te le propose.", "Bonjour, passager ! Nous partons bientôt pour le tour de l'île. Installe-toi face à une baie."],
			[["zephyrine", "Où est la Capitaine Zéphyrine ?", ["À la Capitainerie, sur le ponton, en train de lire la météo du Docteur Aurèle à voix haute. Elle prend la barre pour les grands départs. Et pour les courses avec l'Albatros."]],
			["albatros", "Vous connaissez l'Albatros ?", ["Le dirigeable de la Capitaine Héloïse Nimbus, en bas, à Hautefond ! Elles font la course chaque fois qu'elles se croisent. Les deux disent qu'elles gagnent. Le ciel est grand : il y a de la place pour deux victoires."]]])
		L._gens(M, "femme", float(sieges[0][0]), float(sieges[0][1]), float(sieges[0][2]), "assis", ["Mon premier vol ! Je ne regarde pas en bas. Je regarde devant. Devant, c'est très bien aussi.", "Mon mari est resté au Café Cumulus. Il dit que le ciel, il le voit très bien depuis une chaise."])
		L._gens(M, "vieux", float(sieges[4][0]), float(sieges[4][1]), float(sieges[4][2]), "dormir_assis", ["Zzz… Plus haut… Zzz…", "Zzz… Je ne dors pas, je profite du paysage les yeux fermés… Zzz…"])
		L._gens(M, "garcon", hw - 0.55, 1.2, 90, "pointer", ["La Cascade ! Je vois la Cascade d'en dessous ! Elle tombe et elle devient un nuage !", "Quand je serai grand, je serai capitaine de dirigeable. Ou nuage. Je n'ai pas encore choisi."])
		var stw: Node = L._gens(M, "homme", 0.65, hd - 1.8, 0, "marcher", ["Jus de soleil, lait de nuage ! Pour les passagers qui ont la tête qui tourne : un thé des sommets.", "Attention, la Libellule penche un peu à gauche. Moi aussi. On s'équilibre."])
		var pl: Node3D = _plateau(stw, Color(1.0, 0.6, 0.15))
		L._va_et_vient(M, stw, R.P(0.65, 0, hd - 1.8), R.P(0.65, 0, -2.4), 0.8, 3.0, pl)
		L._causer(M, stw, ["Bon vent ! Un jus de soleil ? C'est offert à bord, pour le premier vol.", "Bonjour ! Attention au plateau : la Libellule danse un peu."],
			[["jus", "Je veux bien un jus de soleil !", func() -> void:
				var st: Dictionary = M.state()
				if bool(st.get("jus117", false)):
					M.talk(stw, "Tu en as déjà eu un ! Mais je te remets un peu de soleil dans le verre, pour la route. Voilà. Il est surtout fait de sourire.", I._bye("Merci !"), I._close(M))
					return
				st["jus117"] = true
				M.bonne_action_v120()  ## V120 : un service rendu, l'île s'en souvient
				M.close_talk()
				M.give([["jus_soleil", 1]], "« Un jus de soleil, pressé ce matin dans les Serres ! » Tu reçois :\n")]])
		M.ctx["entree"] = str(L._pick(M, ["Tu montes à bord de la Libellule : une longue nacelle blanche, des fauteuils face à de grandes baies sur le ciel, et tout au bout, la passerelle.",
			"La nacelle bouge à peine, comme une barque sur une eau très calme. Par les baies, le ciel. Rien que le ciel, et un peu de Cité.",
			"« Bienvenue à bord ! » Les lampes se balancent doucement au rythme du vent. La Libellule est amarrée, mais elle a déjà envie de partir."]))
	# ce qu'on fait : prendre la barre, regarder par la baie, consulter la carte des vents
	M.act(cx * Vector3(0, 1.1, 0.9), "E : prendre la barre", func() -> void:
		M.main.sfx("aeronef_moteur", cx.origin)
		var tw: Tween = M.room.create_tween()
		tw.tween_property(manche, "rotation:z", 0.5, 0.6)
		tw.tween_property(manche, "rotation:z", -0.5, 1.0)
		tw.tween_property(manche, "rotation:z", 0.0, 0.6)
		for lp2 in lampes:
			var tw2: Tween = M.room.create_tween()
			tw2.tween_property(lp2, "rotation:x", 0.25, 0.8).set_trans(Tween.TRANS_SINE)
			tw2.tween_property(lp2, "rotation:x", -0.2, 1.0).set_trans(Tween.TRANS_SINE)
			tw2.tween_property(lp2, "rotation:x", 0.0, 0.8).set_trans(Tween.TRANS_SINE)
		M.say(str(L._pick(M, ["Tu tournes le manche : la Libellule tire sur son amarre, la nacelle penche un peu, les lampes se balancent. « Doucement, dit la seconde, on est encore amarrés ! »",
			"Le manche est léger comme une plume. La Libellule répond aussitôt : elle se dandine au bout de son mât, ravie. « Elle t'aime bien, dit-on derrière toi. Elle ne fait ça qu'avec les vrais pilotes. »"])), 6.0)
	, 1.4)
	M.act(R.P(-hw + 0.5, 1.4, -0.9), "E : regarder par la baie", func() -> void:
		M.say(str(BAIES_LIBELLULE[2] if L._nuit(M) else BAIES_LIBELLULE[L._r(M).randi() % 2]), 7.0)
	, 1.4)
	M.act(tc + Vector3(0, 1.0, 0.5), "E : consulter la carte des vents", func() -> void:
		M.main.sfx("ui_ouvrir", tc)
		M.say(CARTE_VENTS_NU, 8.0)
	, 1.3)


# =================================================================== la Capitainerie du Port des Nuées

const RADIO := ["« Ici la Libellule, je tourne au-dessus de la Cascade, tout va bien. — Ici l'Albatros, je te vois, Zéphyrine ! — Tu vois surtout mon sillage, Héloïse ! » Puis des rires, et un grésillement.",
	"« Capitainerie des Nuées, ici le planeur numéro trois. Je cherche un courant ascendant. — Planeur trois, essayez au-dessus des Serres, ça monte bien après le déjeuner. — Merci ! … Ça monte ! »",
	"« Ici la Gare des Nuées : la capsule part dans deux minutes. Théo demande si quelqu'un a vu son chapeau. — Capitainerie : un chapeau bleu ciel vole vers l'ouest. Il a l'air heureux. »",
	"« Bulletin de l'Institut des Vents : vent d'ouest, doux, avec un nuage en forme de lapin au-dessus du Port. Je répète : un lapin. Fin du bulletin. »"]
const DEPARTS := ["La Libellule : tour de l'île, à dix heures", "La Libellule : tour de l'île, à quinze heures", "La Libellule : descente au Port des Cordages, le dimanche", "École de planeur d'Icare : selon le vent"]


## La Capitainerie du Port des Nuées : la grande baie sur le ponton, la radio et son micro, le tableau
## des départs, la carte des vents, la table des cartes, le coin des planeurs (une maquette suspendue
## qui tourne, des casques) ; le commis, une élève planeuse et une voyageuse le jour ; la Capitaine
## Zéphyrine elle-même le soir.
static func _capitainerie(M) -> void:
	var R = M.R
	var k = R.kit
	var nuit: bool = L._nuit(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	# la radio (le long du mur du fond, à droite) : le pupitre, le poste, le micro, l'écran
	var rx: Transform3D = R.L(2.2, 0, -hd + 0.45)
	k.box(rx * Transform3D(Basis(), Vector3(0, 0.74, 0)), Vector3(2.6, 0.05, 0.7), "ceramique", 1.0)
	for s in [-1.0, 1.0]:
		k.box(rx * Transform3D(Basis(), Vector3(s * 1.2, 0.37, 0)), Vector3(0.05, 0.74, 0.65), "argent", 1.0)
	k.box(rx * Transform3D(Basis(), Vector3(-0.6, 0.95, -0.1)), Vector3(0.8, 0.38, 0.35), "metal", 1.0)
	for j in range(4):
		k.cyl(rx * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(-0.9 + j * 0.2, 0.95, 0.08)), 0.04, 0.04, 0.03, "argent" if j % 2 == 0 else "noir", 10)
	k.box(rx * Transform3D(Basis(), Vector3(-0.6, 1.08, 0.08)), Vector3(0.5, 0.06, 0.01), "lumiere", 1.0)
	k.cyl(rx * Transform3D(Basis(), Vector3(0.3, 0.77, 0.1)), 0.06, 0.07, 0.03, "noir", 10)
	_beam(M, rx * Vector3(0.3, 0.8, 0.1), rx * Vector3(0.35, 1.05, 0.15), 0.01, "argent")
	_ball(M, rx * Vector3(0.35, 1.08, 0.16), 0.035, "noir")
	k.box(rx * Transform3D(Basis(), Vector3(0.6, 1.5, -0.3)), Vector3(1.0, 0.65, 0.04), "noir", 1.0)
	_panneau(M, rx * Transform3D(Basis(), Vector3(0.6, 1.5, -0.27)), Vector2(0.92, 0.58), _ecran(M, "nuees/radar.png", 1.0))
	k.col_box(rx * Transform3D(Basis(), Vector3(0, 0.45, 0)), Vector3(2.6, 0.9, 0.7))
	R.reserve(2.2, -hd + 0.45, 2.8, 1.0)
	_chaise_blanche(M, 2.0, -hd + 1.15, 180.0)
	# le tableau des départs (mur de gauche, entre les deux baies)
	var bx: Transform3D = R.L(-hw + 0.03, 1.75, 0.0, 90)
	k.box(bx, Vector3(1.5, 1.0, 0.03), "noir", 1.0)
	k.box(bx * Transform3D(Basis(), Vector3(0, 0, -0.01)), Vector3(1.6, 1.1, 0.02), "argent", 1.0)
	for li in range(DEPARTS.size()):
		var lab := Label3D.new()
		lab.text = str(DEPARTS[li])
		lab.font_size = 28
		lab.pixel_size = 0.0018
		lab.modulate = Color(1.0, 0.9, 0.55) if li < 2 else Color(0.85, 0.92, 1.0)
		lab.outline_size = 0
		lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		lab.width = 700
		lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		M.room.add_child(lab)
		lab.global_transform = bx * Transform3D(Basis(), Vector3(-0.06, 0.33 - li * 0.22, 0.02))
	R.mark_wall(-hw, 1.75, 0.0, 0.85)
	# la carte des vents (mur de droite, entre les baies), la table des cartes au milieu
	k.box(R.L(hw - 0.03, 1.75, 0.0, -90), Vector3(1.4, 0.9, 0.03), "argent", 1.0)
	_panneau(M, R.L(hw - 0.05, 1.75, 0.0, -90), Vector2(1.3, 0.8), _ecran(M, "nuees/isobares.png", 0.4))
	R.mark_wall(hw, 1.75, 0.0, 0.8)
	var mt: Vector3 = R.P(-0.6, 0, -0.3)
	k.box(Transform3D(Basis(), mt + Vector3.UP * 0.45), Vector3(1.6, 0.9, 0.9), "ceramique", 1.0)
	_panneau(M, Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), mt + Vector3.UP * 0.91), Vector2(1.5, 0.82), _ecran(M, "nuees/plan_ile.png", 0.6))
	k.col_box(Transform3D(Basis(), mt + Vector3.UP * 0.45), Vector3(1.6, 0.9, 0.9))
	R.reserve(-0.6, -0.3, 2.0, 1.3)
	# le coin des planeurs (devant, à droite) : la maquette suspendue qui tourne, les casques, la manche à air
	var mq: Node3D = I._node(M, R.P(2.2, R.H - 0.7, 1.6))
	L._mesh(mq, L._cylm(0.004, 0.004, 0.6, 4), _acier(M), Transform3D(Basis(), Vector3(0, 0.3, 0)))
	var planeur: Node3D = Node3D.new()
	mq.add_child(planeur)
	L._mesh(planeur, I._boxm(Vector3(2.2, 0.025, 0.2)), _blanc(M), Transform3D(Basis(), Vector3(0, 0, 0)))
	L._mesh(planeur, L._cylm(0.05, 0.03, 1.2, 10), _blanc(M), Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, -0.02, 0.15)))
	L._mesh(planeur, I._boxm(Vector3(0.5, 0.02, 0.1)), _blanc(M), Transform3D(Basis(), Vector3(0, 0.0, 0.7)))
	L._mesh(planeur, I._boxm(Vector3(0.02, 0.2, 0.12)), _blanc(M), Transform3D(Basis(), Vector3(0, 0.1, 0.72)))
	L._mesh(planeur, I._sph(0.045), L._m(M, "verriere117", Color(0.4, 0.6, 0.85, 0.7), 0.1), Transform3D(Basis.from_scale(Vector3(1, 0.8, 2.0)), Vector3(0, 0.03, -0.12)))
	L._tourne(M, mq, Vector3.UP, 0.25)
	var cq: Transform3D = R.L(hw - 0.05, 0, 2.6, -90)
	k.box(cq * Transform3D(Basis(), Vector3(0, 1.7, 0.02)), Vector3(1.2, 0.05, 0.08), "argent", 1.0)
	for j3 in range(3):
		var hp: Vector3 = cq * Vector3(-0.4 + j3 * 0.4, 1.52, 0.14)
		var hm: StandardMaterial3D = L._m(M, "casque117_%d" % j3, [Color(0.95, 0.95, 0.95), Color(0.3, 0.55, 0.9), Color(0.95, 0.75, 0.2)][j3], 0.3)
		L._mesh(I._node(M, hp), I._sph(0.14), hm, Transform3D(Basis.from_scale(Vector3(1.0, 0.85, 1.1)), Vector3.ZERO))
	R.mark_wall(hw, 1.6, 2.6, 0.7)
	k.cyl(R.L(hw - 0.6, 0, -2.4), 0.03, 0.03, 1.6, "argent", 6, false)
	var ma: Node3D = I._node(M, R.P(hw - 0.6, 1.55, -2.4))
	for k4 in range(3):
		L._mesh(ma, L._cylm(0.1 - k4 * 0.02, 0.1 - (k4 + 1) * 0.02, 0.18, 10), L._m(M, "manche117_%d" % (k4 % 2), Color(1.0, 0.45, 0.12) if k4 % 2 == 0 else Color(0.96, 0.96, 0.96), 0.6, 0.0, 0.0, true), Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(0.09 + k4 * 0.18, 0, 0)))
	L._balance(M, ma, Vector3.UP, 0.4, 4.0)
	_plante(M, -hw + 0.6, hd - 0.7, 1.0)
	L._lampe(M, R.P(1.8, 2.4, -1.6), Color(1.0, 0.96, 0.9), 0.7, 5.0)
	# les gens
	if nuit:
		var cap: Node = L._patron(M, 2.0, -hd + 1.15, 180.0, "lire", ["Tiens, un visiteur du soir ! J'écoute la radio : quelquefois, l'Albatros passe en bas, et Héloïse me souhaite bonne nuit. Avec beaucoup de mauvaise foi.",
			"Bonsoir ! La Libellule dort, le vent aussi. Moi, je lis la météo de demain. Elle dit « beau ». Elle dit toujours « beau ». Elle a raison."])
		if cap == null:
			var veil: Node = L._gens(M, "homme", 2.0, -hd + 1.15, 180, "lire", ["Veille radio. Tout est calme. Même l'Albatros, en bas, s'est tu.", "La Capitaine Zéphyrine est rentrée chez elle. Elle a laissé un mot : « Réveillez-moi s'il y a une course. »"])
			L._causer(M, veil, ["Bonsoir ! La Capitainerie est en veille. Comme le ciel.", "Bon vent ! Chut… j'écoute la radio."], [])
		M.ctx["entree"] = "La Capitainerie, le soir : la radio grésille tout bas, la maquette du planeur tourne au plafond, et par la grande baie, la Libellule dort au bout du ponton."
	else:
		var com: Node = L._gens(M, "homme", 2.0, -hd + 1.15, 180, "lire", ["« Capitainerie des Nuées, j'écoute ! » … Ah, c'est encore le pigeon qui tape sur l'antenne.", "Le prochain tour de l'île part à quinze heures. Il reste deux places. Et un strapontin pour les très courageux."])
		L._causer(M, com, ["Bon vent ! Capitainerie du Port des Nuées. Un départ, une réclamation, une météo ?", "Bonjour ! La Libellule part à quinze heures. Tu veux une place côté baie ? Elles sont toutes côté baie."],
			[["carte", "Vous avez un souvenir ?", func() -> void:
				var st: Dictionary = M.state()
				if bool(st.get("carte117", false)):
					M.talk(com, "Je t'en ai déjà donné une ! Il ne m'en reste que trois, et la Capitaine les garde pour les courses gagnées contre l'Albatros. C'est-à-dire pour toutes les courses.", I._bye("Ha ha !"), I._close(M))
					return
				st["carte117"] = true
				M.bonne_action_v120()  ## V120 : un service rendu, l'île s'en souvient
				M.close_talk()
				M.give([["carte_postale", 1]], "« Une carte postale de la Libellule, au-dessus de la Cascade. Envoie-la en bas, ça leur fera envie ! » Tu reçois :\n")],
			["icare", "Où est l'école de planeur ?", ["Au bout du ponton, avec Icare Plané ! Il part avec ses élèves quand le vent est bon. Il n'a pas marché depuis trois ans, paraît-il : il plane jusqu'à la boulangerie."]]])
		L._gens(M, "fille", 2.4, 2.4, 20, "pointer", ["Regarde, la maquette du planeur d'Icare ! Le vrai a des ailes de quinze mètres. Moi, j'ai les bras de un mètre. Il faut que je grandisse.", "Demain, c'est ma première leçon. J'ai déjà le casque. Je l'ai même mis pour dormir."])
		var voy: Node = L._gens(M, "vieille", -2.6, 1.6, 120, "observer", ["Je regarde le tableau des départs. La Libellule descend au Plancher le dimanche. Je vais voir ma sœur. En dirigeable ! Elle va être verte de jalousie.", "Il paraît que la Capitaine Zéphyrine n'a jamais perdu une course. Héloïse non plus. Quelle époque."])
		L._causer(M, voy, ["Bonjour ! Tu pars aussi ? J'ai pris mon plus beau chapeau. Il est attaché, cette fois.", "Bon vent ! On dit que le dimanche, la Libellule descend jusqu'au Port des Cordages. Tout en bas !"], [])
		M.ctx["entree"] = str(L._pick(M, ["La Capitainerie du Port des Nuées : une grande baie sur le ponton, une radio qui grésille, un tableau des départs, et une maquette de planeur qui tourne au plafond.",
			"« Capitainerie des Nuées, j'écoute ! » La radio grésille, le commis répond, et par la baie, au bout du ponton, la Libellule se dandine au bout de son mât.",
			"Ça sent le café des sommets et le papier des cartes. Sur le mur, un tableau annonce les départs ; au plafond, un petit planeur fait des ronds."]))
	# ce qu'on fait : écouter la radio, lire le tableau des départs, essayer un casque
	M.act(rx * Vector3(-0.6, 1.1, 0.6), "E : écouter la radio", func() -> void:
		M.main.sfx("radio_jingle", rx.origin)
		var n: int = int(M.ctx.get("radio117", 0))
		M.ctx["radio117"] = n + 1
		M.say(str(RADIO[n % RADIO.size()]), 8.0)
	, 1.4)
	M.act(bx * Vector3(0, -0.2, 0.6), "E : lire le tableau des départs", func() -> void:
		M.say("LES DÉPARTS DU PORT DES NUÉES. La Libellule : tour de l'île, à dix heures et à quinze heures. Le dimanche : descente au Port des Cordages, à Hautefond. L'école de planeur d'Icare : selon le vent. La Navette circulaire : toutes les dix minutes, dans les deux sens. (Dans un seul sens, en fait.)", 8.0)
	, 1.4)
	M.act(cq * Vector3(0, 1.4, 0.7), "E : essayer un casque de planeur", func() -> void:
		M.main.sfx("equiper", cq.origin)
		M.say(str(L._pick(M, ["Tu mets le casque jaune. Il est un peu grand. Tu as l'air d'un vrai pilote. Enfin, d'un vrai pilote un peu perdu.",
			"Le casque bleu te va très bien. Une élève planeuse te fait un salut militaire. Tu lui rends son salut. Le casque tombe sur ton nez."])), 5.0)
	, 1.3)
