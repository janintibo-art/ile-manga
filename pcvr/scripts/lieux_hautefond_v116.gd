extends RefCounted
## V116 : les grands lieux fermés de Hautefond, qu'on visite comme les maisons (maisons_v81 : devant la
## porte, « E : entrer… », un fondu, et l'on est dedans). Chacun a son intérieur à lui, des gens au
## travail, ce qui bouge, et ce qu'on peut y faire :
##  - l'Horloger : l'atelier de Gaspard Ressort, derrière sa boutique (le mur des pendules, l'établi et
##    sa loupe, le coucou qui sort, l'apprentie, un client qui attend ; le soir, Gaspard lui-même) ;
##  - l'Observatoire : la salle de l'orrerie (les planètes de laiton qui tournent autour d'un petit
##    soleil, les cartes du ciel, le registre du Professeur Lunette, une classe en visite) ; en haut, la
##    coupole et la grande lunette (la nuit : la Lune, Saturne, une comète ; le jour : le Soleil, à
##    travers le filtre), et la coupole qu'on fait tourner ;
##  - le Beffroi de l'Hôtel de Ville (par une petite porte au fond de la grande salle) : les roues de
##    l'horloge, l'échappement qui bat, le grand balancier, les trois cadrans vus de dedans (ils donnent
##    l'heure du jeu, à l'envers), la corde de la cloche, le gardien qui graisse les engrenages ;
##  - la Capitainerie du Port des Cordages : la table des cartes et ses petits bateaux, la longue-vue,
##    les pavillons, la cloche du port, le commis qui tamponne, les marins qui attendent ;
##  - le Phare de la Pointe : la salle du gardien (l'escalier qui tourne le long du mur, le journal, la
##    corne de brume) ; en haut, la lanterne : la grande lentille qui tourne (doucement le jour) et
##    brille la nuit ;
##  - le Moulin des Quatre Vents (chez Augustin Meule) : l'arbre qui tourne, la grande roue dentée, la
##    meule qui chante, la farine qui neige, l'apprenti qui porte les sacs, le frein qu'on lâche ;
##  - l'abri du jardinier, aux Vergers : les outils, les cagettes, le tri des pommes ;
##  - l'Albatros, le dirigeable de la Capitaine Héloïse Nimbus, amarré au Mât : la nacelle, ses
##    fauteuils face aux hublots, ses passagers, le steward et son chocolat, la barre.
## Les portes : register() (appelé par hautefond_v112 une fois la ville bâtie) les note dans
## azur_kit_v56.PORTES_V81, avec le style « hautefond_lieu », leur « histoire » (le lieu) et ce qui
## s'affiche devant (« entrer ») ; la maison de Margot, la gardienne du phare, devient une maison de
## Hautefond comme les autres.
## M : maisons_v81 ; I : maisons_iles_v82 (les petites pièces qui bougent).

const Kit = preload("res://scripts/azur_kit_v56.gd")
const I = preload("res://scripts/maisons_iles_v82.gd")

const STYLE := "hautefond_lieu"
## L'étage (la coupole de l'Observatoire, la lanterne du Phare) : bâti à côté de la pièce, on y va par
## un fondu (comme la cave des maisons).
const UPZ: float = -36.0
## lieu -> taille de la pièce (repère de la pièce : la porte au milieu du mur +Z)
const TAILLES := {"hf_horloger": Vector2(8.0, 6.5), "hf_observatoire": Vector2(12.8, 12.8), "hf_beffroi": Vector2(9.0, 9.0),
	"hf_capitainerie": Vector2(9.5, 7.5), "hf_phare": Vector2(6.8, 6.8), "hf_moulin": Vector2(9.0, 9.0), "hf_abri": Vector2(6.0, 4.8),
	"hf_albatros": Vector2(4.6, 13.0)}
## Ce qui s'affiche devant la porte.
const ENTRER := {"hf_horloger": "E : entrer dans l'atelier de l'horloger", "hf_observatoire": "E : entrer dans l'Observatoire",
	"hf_beffroi": "E : monter au beffroi", "hf_capitainerie": "E : entrer dans la Capitainerie", "hf_phare": "E : entrer dans le phare",
	"hf_moulin": "E : entrer dans le moulin", "hf_abri": "E : entrer dans l'abri du jardinier", "hf_albatros": "E : monter à bord de l'Albatros"}


static func is_lieu(style: String) -> bool:
	return style == STYLE


static func taille(cur: Dictionary) -> Vector2:
	return TAILLES.get(str(cur.get("histoire", "")), Vector2(8.0, 7.0))


static func has(sc: String) -> bool:
	return TAILLES.has(sc)


## Les portes des grands lieux : « lieu » -> [porte, dehors] (hf_horloger… ; maison_margot).
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
	# la maison de Margot, la gardienne du phare : une maison de Hautefond (« chez Margot » quand elle y est)
	var mg: Variant = portes.get("maison_margot", null)
	if mg is Array and (mg as Array).size() >= 2:
		var o2: Vector3 = mg[1]
		o2.y = 0.0
		if o2.length() > 0.01:
			Kit.PORTES_V81.append({"door": mg[0], "out": o2.normalized(), "w": 6.0, "d": 5.0, "style": "hautefond", "floors": 1, "owner": ""})
			n += 1
	return n


# =================================================================== la coque de la pièce

static func shell(M) -> void:
	var R = M.R
	R.pal = (R.pal as Dictionary).duplicate()
	match str(M.ctx.get("scenario", "")):
		"hf_horloger":
			R.H = 3.2
			_mur(M, "mur", "maisons/pp_rayures_sauge.png", Color(1, 1, 1), 2.2)
			R.shell()
		"hf_observatoire":
			R.H = 3.6
			_rond(M, 6.4, 3.6, 28)
		"hf_beffroi":
			R.H = 6.0
			R.pal["fenetre"] = "aucune"
			_mur(M, "sol", "montjoie/bois_planches.png", Color(0.85, 0.78, 0.7), 2.0)
			_mur(M, "bas", "montjoie/moellons.png", Color(0.85, 0.82, 0.78), 1.6)
			R.shell()
		"hf_capitainerie":
			R.H = 3.3
			_mur(M, "mur", "maisons/chaux_bleu.png", Color(1, 1, 1), 3.0)
			_mur(M, "sol", "carene/pont.png", Color(0.95, 0.92, 0.85), 2.0)
			R.shell()
		"hf_phare":
			R.H = 3.0
			_mur(M, "mur", "hautefond/pierre_blonde.png", Color(1.0, 0.98, 0.94), 2.0)
			_mur(M, "sol", "hautefond/pave_blond.png", Color(0.95, 0.93, 0.9), 2.0)
			_rond(M, 3.4, 3.0, 16)
		"hf_moulin":
			R.H = 3.6
			_mur(M, "mur", "montjoie/moellons.png", Color(0.95, 0.92, 0.86), 1.8)
			_mur(M, "sol", "montjoie/bois_planches.png", Color(0.9, 0.84, 0.76), 2.0)
			_mur(M, "plafond", "montjoie/bois_planches.png", Color(0.62, 0.52, 0.42), 2.0)
			_rond(M, 4.5, 3.6, 20)
		"hf_abri":
			R.H = 2.6
			_mur(M, "mur", "ramure/planches.png", Color(0.95, 0.88, 0.78), 1.8)
			_mur(M, "bas", "ramure/planches.png", Color(0.8, 0.72, 0.62), 1.8)
			_mur(M, "sol", "terrain/sand.jpg", Color(0.62, 0.5, 0.38), 2.0)
			_mur(M, "plafond", "ramure/planches.png", Color(0.6, 0.5, 0.4), 1.8)
			# une couronne de bougies, pas un lustre de laiton, dans l'abri
			R.style = "cave"
			R.rideaux = false
			R.shell()
			R.rideaux = true
			R.style = STYLE
		"hf_albatros":
			R.H = 2.6
			R.pal["fenetre"] = "aucune"
			_mur(M, "mur", "carene/bordage_int.png", Color(1.0, 0.95, 0.88), 2.0)
			_mur(M, "bas", "carene/bordage_int.png", Color(0.72, 0.6, 0.48), 2.0)
			_mur(M, "sol", "carene/pont.png", Color(0.95, 0.9, 0.82), 2.0)
			_mur(M, "plafond", "carene/bordage_int.png", Color(0.62, 0.52, 0.42), 2.0)
			R.shell()
		_:
			R.shell()


## Remplace une matière de la pièce (avant de bâtir).
static func _mur(M, key: String, tex: String, tint: Color, tile: float) -> void:
	var R = M.R
	R._put(key, R._texmat(tex, tint, 0.9))
	R.pal[key] = [tex, tint, tile]


## Une pièce ronde (centre au milieu de la pièce) : le sol, le plafond, un mur à facettes, la porte au
## milieu du côté +Z (la facette n° 0 est centrée sur +Z), les collisions, une lampe.
static func _rond(M, r: float, h: float, seg: int) -> void:
	var R = M.R
	var k = R.kit
	var cw: Vector3 = R.P(0, 0, 0)
	k.disc(Transform3D(Basis(), cw), r + 0.35, "sol", seg, float((R.pal["sol"] as Array)[2]))
	k.col_box(Transform3D(Basis(), cw + Vector3.DOWN * 0.25), Vector3(2.0 * r + 1.0, 0.5, 2.0 * r + 1.0))
	k.disc(Transform3D(Basis(Vector3.RIGHT, PI), cw + Vector3.UP * h), r + 0.35, "plafond", seg, float((R.pal["plafond"] as Array)[2]))
	k.col_box(Transform3D(Basis(), cw + Vector3.UP * (h + 0.35)), Vector3(2.0 * r + 1.0, 0.5, 2.0 * r + 1.0))
	var chord: float = 2.0 * r * sin(PI / seg) + 0.06
	for i in range(seg):
		var am: float = PI * 0.5 + TAU * i / seg
		var dirv := Vector3(cos(am), 0, sin(am))
		var xf := Transform3D(Basis.looking_at(-dirv, Vector3.UP), cw + dirv * (r + 0.15))
		if i == 0:
			# au-dessus et autour de la porte (la porte elle-même : _entry_door de la pièce)
			k.box(xf * Transform3D(Basis(), Vector3(0, (h + 2.2) * 0.5, 0)), Vector3(chord, h - 2.2, 0.3), "mur", 2.0)
			var side: float = (chord - 1.1) * 0.5
			if side > 0.04:
				for sx in [-1.0, 1.0]:
					k.box(xf * Transform3D(Basis(), Vector3(sx * (0.55 + side * 0.5), 1.1, 0)), Vector3(side, 2.2, 0.3), "mur", 2.0)
		else:
			k.box(xf * Transform3D(Basis(), Vector3(0, h * 0.5, 0)), Vector3(chord, h, 0.3), "mur", 2.0)
			# le soubassement
			k.box(xf * Transform3D(Basis(), Vector3(0, 0.45, -0.16)), Vector3(chord, 0.9, 0.03), "bas", 1.4)
			k.box(xf * Transform3D(Basis(), Vector3(0, 0.9, -0.18)), Vector3(chord, 0.05, 0.05), "bois_sombre", 1.0)
		k.col_box(xf * Transform3D(Basis(), Vector3(0, h * 0.5, 0)), Vector3(chord, h + 0.4, 0.3))
	R._entry_door(1.1, 2.2, r + 0.1)
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.9, 0.74)
	l.light_energy = 1.2
	l.omni_range = r * 2.2
	l.omni_attenuation = 0.9
	l.shadow_enabled = R.pc and not M.main.xr_active
	l.light_specular = 0.3
	M.room.add_child(l)
	l.global_position = cw + Vector3.UP * (h - 0.6)
	R.lights.append(l)


## L'angle (en degrés) de la facette la plus proche (90 : la porte).
static func _facette(deg: float, seg: int) -> float:
	var step: float = 360.0 / seg
	return 90.0 + roundf((deg - 90.0) / step) * step


## Une fenêtre sur un mur rond (angle en degrés), qui regarde l'intérieur.
static func _fenetre_ronde(M, c: Vector3, r: float, seg: int, deg: float, y: float, kind: String) -> void:
	var R = M.R
	var a: float = deg_to_rad(_facette(deg, seg))
	var out := Vector3(cos(a), 0, sin(a))
	R.window(Transform3D(Basis.looking_at(out, Vector3.UP), R.P(c.x, y, c.z) + out * (r - 0.02)), kind)


## Une place contre un mur rond : (x, z, yaw) ; le yaw tourne le meuble (ou la personne) vers le centre.
static func _contre(deg: float, rr: float) -> Vector3:
	var a: float = deg_to_rad(deg)
	var x: float = cos(a) * rr
	var z: float = sin(a) * rr
	return Vector3(x, z, rad_to_deg(atan2(-x, -z)))


# =================================================================== les aides

static func _r(M) -> RandomNumberGenerator:
	return M.ctx["rng"]


static func _pick(M, a: Array) -> Variant:
	return a[_r(M).randi() % a.size()]


static func _nuit(M) -> bool:
	var h: float = float(M.ctx.get("hour", 12.0))
	return h >= 20.5 or h < 6.5


## Une matière simple (gardée pour la pièce).
static func _m(M, key: String, c: Color, rough: float = 0.6, metal: float = 0.0, emit: float = 0.0, cull_off: bool = false) -> StandardMaterial3D:
	if not M.ctx.has("mats116"):
		M.ctx["mats116"] = {}
	var cache: Dictionary = M.ctx["mats116"]
	if cache.has(key):
		return cache[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = Color(c.r, c.g, c.b)
		m.emission_energy_multiplier = emit
	if c.a < 0.99:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if cull_off:
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
	cache[key] = m
	return m


static func _laiton(M) -> StandardMaterial3D:
	return _m(M, "laiton", Color(0.9, 0.7, 0.34), 0.38, 0.55, 0.0, true)


static func _fer(M) -> StandardMaterial3D:
	return _m(M, "fer", Color(0.24, 0.24, 0.25), 0.55, 0.4, 0.0, true)


## Un maillage posé dans un nœud (xf : en local du nœud).
static func _mesh(parent: Node3D, mesh: Mesh, mat: Material, xf: Transform3D = Transform3D.IDENTITY) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.transform = xf
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


## Un sac debout (de farine, de blé) : le ventre de toile, les épaules tassées, le col serré par une
## ficelle et la touffe au-dessus ; centré sur l'origine du nœud (de -h/2 à +h/2).
static func _sac(n: Node3D, mat: Material, r: float, h: float) -> void:
	var sq := Basis.from_scale(Vector3(1.0, 1.0, 0.78))
	_mesh(n, _cylm(r * 0.94, r, h * 0.62, 12), mat, Transform3D(sq, Vector3(0, -h * 0.19, 0)))
	var sm := SphereMesh.new()
	sm.radius = r * 0.94
	sm.height = h * 0.5
	sm.radial_segments = 12
	sm.rings = 6
	_mesh(n, sm, mat, Transform3D(sq, Vector3(0, h * 0.12, 0)))
	var ficelle: StandardMaterial3D = StandardMaterial3D.new()
	ficelle.albedo_color = Color(0.55, 0.42, 0.26)
	ficelle.roughness = 1.0
	_mesh(n, _cylm(r * 0.17, r * 0.2, 0.05, 8), ficelle, Transform3D(Basis(), Vector3(0, h * 0.37 + 0.015, 0)))
	_mesh(n, _cylm(r * 0.36, r * 0.15, 0.08, 8), mat, Transform3D(Basis(), Vector3(0, h * 0.37 + 0.075, 0)))


## Un sac couché (pour les piles) : un gros coussin de toile, la ficelle et la touffe au bout (+Z) ;
## centré sur l'origine du nœud.
static func _sac_couche(n: Node3D, mat: Material, w: float, hh: float, l: float) -> void:
	var sm := SphereMesh.new()
	sm.radius = 0.5
	sm.height = 1.0
	sm.radial_segments = 14
	sm.rings = 8
	_mesh(n, sm, mat, Transform3D(Basis.from_scale(Vector3(w, hh, l)), Vector3.ZERO))
	var ficelle: StandardMaterial3D = StandardMaterial3D.new()
	ficelle.albedo_color = Color(0.55, 0.42, 0.26)
	ficelle.roughness = 1.0
	var axe := Basis(Vector3.RIGHT, PI * 0.5)
	_mesh(n, _cylm(0.05, 0.06, 0.05, 8), ficelle, Transform3D(axe, Vector3(0, 0.0, l * 0.5 - 0.01)))
	_mesh(n, _cylm(0.1, 0.04, 0.08, 8), mat, Transform3D(axe, Vector3(0, 0.0, l * 0.5 + 0.05)))


static func _cylm(rt: float, rb: float, h: float, seg: int = 16, caps: bool = true) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = rt
	c.bottom_radius = rb
	c.height = h
	c.radial_segments = seg
	c.cap_top = caps
	c.cap_bottom = caps
	return c


## Une roue dentée (un disque à dents, plat, l'axe sur Z local) : un seul maillage.
static func _gear_mesh(r: float, teeth: int, thick: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rr: float = r * 0.84
	var pts: Array = []
	for i in range(teeth):
		var a0: float = TAU * i / teeth
		var da: float = TAU / teeth
		pts.append(Vector2(cos(a0), sin(a0)) * rr)
		pts.append(Vector2(cos(a0 + da * 0.18), sin(a0 + da * 0.18)) * r)
		pts.append(Vector2(cos(a0 + da * 0.5), sin(a0 + da * 0.5)) * r)
		pts.append(Vector2(cos(a0 + da * 0.68), sin(a0 + da * 0.68)) * rr)
	var hz: float = thick * 0.5
	for s in [1.0, -1.0]:
		var n := Vector3(0, 0, s)
		for i2 in range(pts.size()):
			var p0: Vector2 = pts[i2]
			var p1: Vector2 = pts[(i2 + 1) % pts.size()]
			for v in [Vector3(0, 0, hz * s), Vector3(p1.x, p1.y, hz * s), Vector3(p0.x, p0.y, hz * s)]:
				st.set_normal(n)
				st.add_vertex(v)
	for i3 in range(pts.size()):
		var q0: Vector2 = pts[i3]
		var q1: Vector2 = pts[(i3 + 1) % pts.size()]
		var nn := Vector3(q1.y - q0.y, -(q1.x - q0.x), 0).normalized()
		for v2 in [Vector3(q0.x, q0.y, hz), Vector3(q1.x, q1.y, -hz), Vector3(q1.x, q1.y, hz), Vector3(q0.x, q0.y, hz), Vector3(q0.x, q0.y, -hz), Vector3(q1.x, q1.y, -hz)]:
			st.set_normal(nn)
			st.add_vertex(v2)
	return st.commit()


## Une roue dentée dans la pièce (pos : le centre dans le monde, axe : la direction de son arbre),
## avec son moyeu ; renvoie le nœud qui tourne (autour de son Z local).
static func _roue(M, pos: Vector3, axe: Vector3, r: float, teeth: int, thick: float, mat: Material) -> Node3D:
	var n := Node3D.new()
	M.room.add_child(n)
	var a: Vector3 = axe.normalized()
	var up: Vector3 = Vector3.UP if absf(a.dot(Vector3.UP)) < 0.95 else Vector3.FORWARD
	n.global_transform = Transform3D(Basis.looking_at(-a, up), pos)
	_mesh(n, _gear_mesh(r, teeth, thick), mat)
	_mesh(n, _cylm(r * 0.16, r * 0.16, thick * 2.4, 12), mat, Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO))
	return n


## Un anneau (une roue de gouvernail, un volant) : un tore, dans le plan XY local.
static func _tore(r_in: float, r_out: float) -> TorusMesh:
	var t := TorusMesh.new()
	t.inner_radius = r_in
	t.outer_radius = r_out
	t.rings = 32
	t.ring_segments = 8
	return t


## Les choses qui bougent : une liste dans le contexte de la pièce, et le tick (un seul par pièce).
static func _anims(M) -> Array:
	if not M.ctx.has("anims116"):
		M.ctx["anims116"] = []
		M.ctx["t116"] = 0.0
		M.ctx["vite116"] = 1.0
		M.ctx["tick"] = func(delta: float) -> void: _tick(M, delta)
	return M.ctx["anims116"]


## Tourner sans fin autour d'un axe local ; « moteur » : suit la vitesse de la pièce (le frein du moulin).
static func _tourne(M, n: Node3D, axe_local: Vector3, vitesse: float, moteur: bool = false) -> void:
	_anims(M).append(["tourne", n, axe_local.normalized(), vitesse, moteur])


## Se balancer (un balancier, une lampe) autour d'un axe local.
static func _balance(M, n: Node3D, axe_local: Vector3, amp: float, periode: float, phase: float = 0.0) -> void:
	_anims(M).append(["balance", n, axe_local.normalized(), amp, periode, phase, n.transform.basis])


## Appeler cb de temps en temps (entre lo et hi secondes).
static func _souvent(M, lo: float, hi: float, cb: Callable) -> void:
	_anims(M).append(["souvent", lo, hi, cb, _r(M).randf_range(lo * 0.3, hi)])


## Appeler cb(delta, t) à chaque image.
static func _chaque(M, cb: Callable) -> void:
	_anims(M).append(["chaque", cb])


## Un habitant qui fait des allers-retours (a <-> b, au sol), en marchant ; il s'arrête aux deux bouts ;
## porte : un nœud qu'il ne porte qu'à l'aller (un sac, un plateau).
static func _va_et_vient(M, f: Node, a: Vector3, b: Vector3, vitesse: float, pause: float, porte: Node3D = null) -> void:
	f.set_pose("marcher", b - a)
	f.follow = false
	_anims(M).append(["marche", f, a, b, vitesse, pause, 0.0, 1, porte])


static func _tick(M, delta: float) -> void:
	if not M.inside or not M.ctx.has("anims116"):
		return
	M.ctx["t116"] = float(M.ctx["t116"]) + delta
	var t: float = M.ctx["t116"]
	var vite: float = float(M.ctx.get("vite116", 1.0))
	for a in M.ctx["anims116"]:
		match str(a[0]):
			"tourne":
				var n: Node3D = a[1]
				if is_instance_valid(n):
					n.rotate_object_local(a[2], float(a[3]) * delta * (vite if bool(a[4]) else 1.0))
			"balance":
				var n2: Node3D = a[1]
				if is_instance_valid(n2):
					n2.transform.basis = (a[6] as Basis) * Basis(a[2], float(a[3]) * sin(TAU * t / float(a[4]) + float(a[5])))
			"souvent":
				a[4] = float(a[4]) - delta
				if float(a[4]) <= 0.0:
					a[4] = _r(M).randf_range(float(a[1]), float(a[2]))
					(a[3] as Callable).call()
			"chaque":
				(a[1] as Callable).call(delta, t)
			"marche":
				_marche(a, delta)


static func _marche(a: Array, delta: float) -> void:
	var f: Node = a[1]
	if f == null or not is_instance_valid(f) or f.npc == null or not is_instance_valid(f.npc) or bool(f.talking):
		return
	var to: Vector3 = a[3] if int(a[7]) == 1 else a[2]
	if float(a[6]) > 0.0:
		a[6] = float(a[6]) - delta
		if float(a[6]) <= 0.0:
			f.set_pose("marcher", to - (f.npc.global_position as Vector3))
			f.follow = false
		return
	var p: Vector3 = f.npc.global_position
	var d := Vector3(to.x - p.x, 0, to.z - p.z)
	var step: float = float(a[4]) * delta
	if d.length() <= step:
		f.npc.global_position = Vector3(to.x, p.y, to.z)
		a[7] = 1 - int(a[7])
		a[6] = float(a[5])
		var carried: Variant = a[8]
		if carried is Node3D and is_instance_valid(carried):
			(carried as Node3D).visible = int(a[7]) == 1
		f.set_pose("debout")
		f._play("v28/pickup", 0.2)
		f._gest = 1.0
		return
	f.npc.global_position = p + d.normalized() * step
	f.face_dir = d.normalized()
	var it: Variant = f.get_meta("it116", null)
	if it is Dictionary:
		(it as Dictionary)["pos"] = (f.npc.global_position as Vector3) + Vector3.UP * 0.05


## Une petite bulle qui flotte (un coucou, un « BONG »).
static func _etiquette(M, pos: Vector3, text: String) -> Label3D:
	var lab := Label3D.new()
	lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lab.font_size = 40
	lab.pixel_size = 0.0028
	lab.outline_size = 10
	lab.no_depth_test = true
	lab.modulate = Color(1, 0.96, 0.82)
	lab.text = text
	lab.visible = false
	M.room.add_child(lab)
	lab.global_position = pos
	return lab


static func _montrer(M, lab: Label3D, secondes: float) -> void:
	lab.visible = true
	await M.get_tree().create_timer(secondes).timeout
	if is_instance_valid(lab):
		lab.visible = false


## De la poussière qui flotte dans la lumière (la farine du moulin, la poussière du beffroi).
static func _poussiere(M, at: Vector3, ext: Vector3, n: int, c: Color, size: float = 0.03) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = n
	p.lifetime = 6.0
	p.preprocess = 6.0
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = ext
	p.direction = Vector3.DOWN
	p.spread = 70.0
	p.gravity = Vector3(0, -0.03, 0)
	p.initial_velocity_min = 0.02
	p.initial_velocity_max = 0.08
	p.scale_amount_min = size * 0.6
	p.scale_amount_max = size * 1.4
	var qm := QuadMesh.new()
	qm.size = Vector2.ONE
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.billboard_keep_scale = true
	m.albedo_color = c
	m.albedo_texture = M.R.dot_texture()
	qm.material = m
	p.mesh = qm
	M.room.add_child(p)
	p.global_position = at
	return p


## Une lampe de la pièce.
static func _lampe(M, at: Vector3, c: Color, e: float, rng_m: float) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.light_color = c
	l.light_energy = e
	l.omni_range = rng_m
	l.omni_attenuation = 1.1
	l.shadow_enabled = false
	M.room.add_child(l)
	l.global_position = at
	M.R.lights.append(l)
	return l


## Un travailleur (un habitant sans nom fixe, à l'allure de Hautefond).
static func _gens(M, role: String, x: float, z: float, yaw: float, pose: String, lignes: Array) -> Node:
	var f: Node = M.person(role, x, z, yaw, pose)
	f.lines = lignes
	return f


## Le maître des lieux, s'il est chez lui (l'horloger, le meunier) : comme dans « chez » (maisons_scenes).
static func _patron(M, x: float, z: float, yaw: float, pose: String, bonjour: Array) -> Node:
	var owner: Variant = M.ctx.get("owner_node", null)
	if owner == null or not is_instance_valid(owner) or not bool(owner.get("hidden_home")):
		return null
	var prof: Dictionary = (owner.get("profile") as Dictionary).duplicate(true)
	var cls: String = "lumen"
	var scr: String = str((owner.get_script() as Script).resource_path)
	if scr.contains("pirate"):
		cls = "pirate"
	elif scr.contains("ramure"):
		cls = "ramure"
	prof["classe"] = cls
	var Fig = load("res://scripts/pnj/figurant_v81.gd")
	var f: Node = Fig.spawn(M.room, M.main, prof, M.R.P(x, 0, z), Basis(Vector3.UP, deg_to_rad(yaw)) * Vector3(0, 0, 1), pose)
	M.people.append(f)
	var acc: Array = []
	for l in (prof.get("repliques", {}) as Dictionary).get("lui", []):
		var tx: String = str((l as Dictionary).get("t", "")) if l is Dictionary else str(l)
		if tx != "" and not tx.contains("{"):
			acc.append(tx)
	M.talk_spot(f, func() -> void:
		var choices: Array = []
		if not acc.is_empty():
			choices.append({"id": "lui", "label": "Parle-moi un peu de toi."})
		choices.append({"id": "fermer", "label": "Je ne te dérange pas plus longtemps."})
		M.talk(f, str(_pick(M, bonjour)), choices, func(id):
			if str(id) == "lui":
				M.talk(f, str(acc[_r(M).randi() % acc.size()]), [{"id": "fermer", "label": "Merci de m'avoir raconté."}], func(_i): M.close_talk())
			else:
				M.close_talk()))
	return f


## Une conversation simple : quelques sujets (une réponse piochée chacun, ou un Callable), puis au revoir.
static func _causer(M, f: Node, accueil: Array, sujets: Array, humeur: String = "de bonne humeur") -> void:
	var it: Dictionary = M.talk_spot(f, func() -> void:
		var choices: Array = []
		for s in sujets:
			choices.append({"id": str(s[0]), "label": str(s[1])})
		choices.append({"id": "fermer", "label": "Au revoir !"})
		M.talk(f, str(_pick(M, accueil)), choices, func(id):
			for s2 in sujets:
				if str(s2[0]) == str(id):
					var rep: Variant = s2[2]
					if rep is Callable:
						(rep as Callable).call()
						return
					M.talk(f, str(_pick(M, rep)), [{"id": "fermer", "label": "Merci !"}], func(_i): M.close_talk())
					return
			M.close_talk(), humeur))
	# (pour ceux qui marchent : l'endroit où l'on parle les suit)
	f.set_meta("it116", it)


# =================================================================== construire

static func build(M, sc: String) -> void:
	match sc:
		"hf_horloger":
			_horloger(M)
		"hf_observatoire":
			_observatoire(M)
		"hf_beffroi":
			_beffroi(M)
		"hf_capitainerie":
			_capitainerie(M)
		"hf_phare":
			_phare(M)
		"hf_moulin":
			_moulin(M)
		"hf_abri":
			_abri(M)
		"hf_albatros":
			_albatros(M)


# =================================================================== l'Horloger

static func _horloger(M) -> void:
	var R = M.R
	var k = R.kit
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var nuit: bool = _nuit(M)
	var face := Basis(Vector3.RIGHT, PI * 0.5)
	# le mur des pendules (au fond) : des cadrans de toutes les tailles, des aiguilles à toutes les heures
	var cad: Array = [[-0.6, 1.5, 0.22], [0.2, 1.78, 0.3], [1.1, 1.45, 0.2], [1.9, 1.82, 0.26], [2.55, 1.35, 0.16], [-0.3, 2.45, 0.18],
		[0.6, 2.62, 0.24], [1.5, 2.5, 0.2], [2.4, 2.6, 0.22], [-1.4, 2.72, 0.16], [-2.3, 2.75, 0.2], [-0.9, 0.98, 0.15], [2.05, 0.95, 0.18]]
	for i in range(cad.size()):
		var c: Array = cad[i]
		var x: float = c[0]
		var y: float = c[1]
		var rr: float = c[2]
		var at: Vector3 = R.P(x, y, -hd + 0.03)
		k.cyl(Transform3D(face, at), rr, rr, 0.04, "ceramique", 20, true)
		k.ring(Transform3D(face, at + Vector3(0, 0, 0.005)), rr, rr + 0.035, 0.06, "or" if i % 2 == 0 else "bois_sombre", 20)
		for hnd in range(2):
			var ang: float = _r(M).randf() * TAU
			var ln: float = rr * (0.55 if hnd == 0 else 0.8)
			var hb := Basis(Vector3.BACK, ang)
			k.box(Transform3D(hb, at + Vector3(0, 0, 0.048) + hb * Vector3(0, ln * 0.5, 0)), Vector3(0.018, ln, 0.008), "noir", 1.0)
		R.mark_wall(x, y, -hd, rr + 0.05)
		# trois d'entre elles ont un petit balancier
		if i in [1, 3, 6]:
			var pv: Node3D = I._node(M, at + Vector3(0, -rr - 0.02, 0.05))
			I._part(pv, I._cyl(0.004, 0.004, 0.32), Color(0.85, 0.66, 0.3), Vector3(0, -0.16, 0), Vector3.ONE, Vector3.ZERO, 0.0, 0.5)
			I._part(pv, I._cyl(0.045, 0.045, 0.012), Color(0.9, 0.7, 0.32), Vector3(0, -0.33, 0), Vector3.ONE, Vector3(PI * 0.5, 0, 0), 0.0, 0.5)
			_balance(M, pv, Vector3.BACK, 0.25, 1.1 + 0.15 * (i % 3), float(i))
	# deux grandes pendules, de part et d'autre (leur balancier bat derrière la vitre)
	var grandes: Array = []
	for sx in [-1.0, 1.0]:
		var gx: float = sx * (hw - 0.7)
		var gz: float = -hd + 0.25
		k.box(R.L(gx, 1.05, gz), Vector3(0.62, 2.1, 0.36), "bois_sombre", 1.0)
		k.box(R.L(gx, 2.17, gz), Vector3(0.7, 0.16, 0.42), "bois", 1.0)
		k.cyl(Transform3D(face, R.P(gx, 1.78, gz + 0.18)), 0.21, 0.21, 0.02, "ceramique", 20, true)
		k.ring(Transform3D(face, R.P(gx, 1.78, gz + 0.18)), 0.21, 0.25, 0.04, "or", 20)
		for hnd2 in range(2):
			var hb2 := Basis(Vector3.BACK, _r(M).randf() * TAU)
			var ln2: float = 0.12 if hnd2 == 0 else 0.17
			k.box(Transform3D(hb2, R.P(gx, 1.78, gz + 0.205) + hb2 * Vector3(0, ln2 * 0.5, 0)), Vector3(0.014, ln2, 0.006), "noir", 1.0)
		k.box(R.L(gx, 0.95, gz + 0.185), Vector3(0.38, 0.8, 0.01), "verre", 1.0)
		k.col_box(R.L(gx, 1.05, gz), Vector3(0.62, 2.1, 0.36))
		R.reserve(gx, gz, 0.8, 0.6)
		var pv2: Node3D = I._node(M, R.P(gx, 1.42, gz + 0.12))
		I._part(pv2, I._cyl(0.008, 0.008, 0.62), Color(0.85, 0.66, 0.3), Vector3(0, -0.31, 0), Vector3.ONE, Vector3.ZERO, 0.0, 0.5)
		I._part(pv2, I._cyl(0.09, 0.09, 0.02), Color(0.92, 0.72, 0.34), Vector3(0, -0.64, 0), Vector3.ONE, Vector3(PI * 0.5, 0, 0), 0.0, 0.5)
		_balance(M, pv2, Vector3.BACK, 0.18, 2.0, 1.4 if sx > 0 else 0.0)
		grandes.append(R.P(gx, 0, gz + 0.75))
	# l'établi sous la fenêtre de gauche, sa loupe et sa lampe, les petites pièces
	R.etabli(-hw + 0.5, -0.5, 90, 2.4)
	var lp: Vector3 = R.P(-hw + 0.4, 0.92, 0.25)
	k.cyl(Transform3D(Basis(), lp), 0.07, 0.08, 0.03, "fer", 10)
	k.cyl(Transform3D(Basis(Vector3.BACK, -0.5), lp), 0.012, 0.012, 0.55, "or", 6, false)
	var lens: Vector3 = lp + Vector3(0.26, 0.47, 0)
	k.ring(Transform3D(Basis(Vector3.BACK, 0.9), lens), 0.09, 0.115, 0.02, "or", 18)
	k.cyl(Transform3D(Basis(Vector3.BACK, 0.9), lens), 0.09, 0.09, 0.005, "verre", 18, true)
	_lampe(M, lens + Vector3(0.1, -0.15, 0), Color(1.0, 0.86, 0.6), 0.7, 2.6)
	for j in range(9):
		var pp: Vector3 = R.P(-hw + 0.5 + _r(M).randf_range(-0.2, 0.25), 0.92, -1.5 + j * 0.16)
		var pr: float = _r(M).randf_range(0.012, 0.045)
		k.cyl(Transform3D(Basis(), pp), pr, pr, 0.012, ["or", "cuivre", "metal", "argent"][j % 4], 10)
	_mesh(M.room, I._sph(0.12), _m(M, "cloche_verre", Color(0.8, 0.9, 1.0, 0.28), 0.05), Transform3D(Basis.from_scale(Vector3(1, 1.3, 1)), R.P(-hw + 0.5, 0.97, -1.45)))
	# des étagères de montres, à droite
	R.etagere(hw - 0.35, 1.6, -90, 1.3, 1.8, false, 4)
	var cote := Basis(Vector3.BACK, PI * 0.5)
	for j2 in range(12):
		var row: int = j2 % 3
		var col: int = floori(j2 / 3.0)
		var wr: float = 0.05 if j2 % 2 == 0 else 0.04
		var sp: Vector3 = R.P(hw - 0.33, 0.515 + row * 0.42 + wr, 1.1 + col * 0.27)
		k.cyl(Transform3D(cote, sp), wr, wr, 0.02, "or" if j2 % 3 else "argent", 12, true)
		k.cyl(Transform3D(cote, sp + Vector3(-0.02, 0, 0)), wr * 0.85, wr * 0.85, 0.004, "ceramique", 12, true)
	# la vitrine du milieu : des montres, des réveils, une boîte à musique, sous le verre ; un tapis
	R.tapis(0.4, 0.6, 0, 3.4, 2.2, 0)
	var vt: Transform3D = R.L(0.5, 0, 0.1)
	k.box(vt * Transform3D(Basis(), Vector3(0, 0.42, 0)), Vector3(1.8, 0.84, 0.7), "bois_clair", 1.0)
	k.box(vt * Transform3D(Basis(), Vector3(0, 0.86, 0)), Vector3(1.9, 0.04, 0.78), "bois", 1.0)
	k.box(vt * Transform3D(Basis(), Vector3(0, 0.05, 0)), Vector3(1.84, 0.1, 0.74), "bois_sombre", 1.0)
	for sv in [-1.0, 1.0]:
		k.box(vt * Transform3D(Basis(), Vector3(0, 0.8, sv * 0.353)), Vector3(1.8, 0.025, 0.012), "or", 1.0)
		k.box(vt * Transform3D(Basis(), Vector3(0, 0.45, sv * 0.353)), Vector3(1.5, 0.5, 0.012), "bois", 1.0)
	for e in [[-0.6, 0.0, "or"], [-0.25, 0.12, "argent"], [0.1, -0.1, "or"], [0.45, 0.1, "cuivre"], [0.72, -0.12, "argent"]]:
		k.cyl(Transform3D(face, vt * Vector3(float(e[0]), 0.98, float(e[1]) - 0.01)), 0.07, 0.07, 0.02, str(e[2]), 14, true)
		k.box(vt * Transform3D(Basis(), Vector3(float(e[0]), 0.9, float(e[1]))), Vector3(0.06, 0.04, 0.05), "bois_sombre", 1.0)
	k.box(vt * Transform3D(Basis(), Vector3(-0.85, 0.94, -0.15)), Vector3(0.16, 0.12, 0.12), "bois", 1.0)
	k.cyl(vt * Transform3D(Basis(), Vector3(-0.85, 1.0, 0.1)), 0.05, 0.05, 0.03, "or", 10)
	k.box(vt * Transform3D(Basis(), Vector3(0, 1.08, 0)), Vector3(1.86, 0.4, 0.74), "verre", 1.0, 63 - 8)
	k.col_box(vt * Transform3D(Basis(), Vector3(0, 0.62, 0)), Vector3(1.9, 1.24, 0.78))
	R.reserve(0.5, 0.1, 2.0, 0.9)
	# le coucou (mur de droite) : sa maisonnette, son toit, ses pommes de pin ; l'oiseau qui sort
	var cb: Transform3D = R.L(hw - 0.12, 2.3, -1.6, -90)
	k.box(cb, Vector3(0.32, 0.38, 0.18), "bois", 1.0)
	for s2 in [-1.0, 1.0]:
		k.box(cb * Transform3D(Basis(Vector3.BACK, s2 * 0.75), Vector3(s2 * 0.1, 0.24, 0)), Vector3(0.26, 0.03, 0.22), "bois_sombre", 1.0)
	k.cyl(Transform3D(cb.basis * face, cb * Vector3(0, -0.05, 0.09)), 0.08, 0.08, 0.01, "ceramique", 14, true)
	k.box(cb * Transform3D(Basis(), Vector3(0, 0.1, 0.092)), Vector3(0.08, 0.09, 0.01), "bois_sombre", 1.0)
	for s3 in [-1.0, 1.0]:
		k.cyl(Transform3D(Basis(), cb * Vector3(s3 * 0.07, -0.85, 0.05)), 0.004, 0.004, 0.65, "fer", 4, false)
		k.cyl(Transform3D(Basis(), cb * Vector3(s3 * 0.07, -1.0, 0.05)), 0.03, 0.025, 0.14, "or", 8)
	R.mark_wall(hw, 2.3, -1.6, 0.4)
	var nid: Vector3 = cb * Vector3(0, 0.1, 0.0)
	var dehors: Vector3 = cb * Vector3(0, 0.1, 0.2)
	var oiseau: Node3D = I._node(M, nid, -90)
	I._part(oiseau, I._sph(0.045), Color(0.55, 0.36, 0.2), Vector3.ZERO)
	I._part(oiseau, I._cyl(0.0, 0.016, 0.05), Color(0.95, 0.75, 0.2), Vector3(0, 0.0, 0.05), Vector3.ONE, Vector3(PI * 0.5, 0, 0))
	I._part(oiseau, I._boxm(Vector3(0.012, 0.05, 0.07)), Color(0.4, 0.26, 0.15), Vector3(0, 0.0, -0.05))
	oiseau.visible = false
	var bulle: Label3D = _etiquette(M, cb * Vector3(0, 0.45, 0.25), "Cou-cou ! Cou-cou !")
	# les gens : le soir, Gaspard à son établi ; le jour, l'apprentie, et un client qui attend
	var patron: Node = _patron(M, -hw + 1.25, -1.0, -90, "bricoler", ["Ah, de la visite ! Entre, entre, mais marche doucement : elles écoutent tout.",
		"Bonsoir ! Je règle les pendules du quartier. Le soir, elles sont plus sages : on s'entend mieux.",
		"Te voilà dans mon atelier ! Attention au coucou de droite : il n'aime pas les inconnus. Ni les connus, d'ailleurs."])
	var appr: Node = null
	if patron == null:
		appr = _gens(M, "femme", -hw + 1.25, -1.0, -90, "bricoler", ["Ce ressort-là a sauté trois fois. Il a du caractère.", "Chut… J'écoute si elle bat juste.",
			"Un engrenage de trop, et c'est une horloge qui chante. Un de moins, et c'est une horloge qui boude.", "Monsieur Gaspard dit qu'une montre, ça s'écoute avant de se réparer."])
		_causer(M, appr, ["Bonjour ! Tu viens pour une réparation ? Monsieur Gaspard est au comptoir, devant. Moi, je suis l'apprentie : je fais les petites roues.",
			"Ah, bonjour ! Ne fais pas attention au bruit : ici, il y a cent pendules, et elles ont toutes quelque chose à dire."],
			[["quoi", "Qu'est-ce que tu répares ?", ["Une montre de gousset qui avance le lundi et retarde le mardi. Le mercredi, elle hésite.",
				"Le réveil du Bourgmestre. Il sonne au milieu des discours. Le réveil, pas le Bourgmestre.",
				"Une boîte à musique qui joue la marche des liftiers… à l'envers. On dirait une berceuse. C'est presque mieux."]],
			["coucou", "Et ce coucou, là ?", ["Il a cent ans et il n'a jamais été à l'heure. Monsieur Gaspard dit qu'il est en avance sur son temps.",
				"Il sort quand il veut. Si tu attends, il ne sort pas. Si tu tournes le dos, coucou !"]]])
		if not nuit:
			R.chaise(hw - 1.6, 0.9, -105)
			var client: Node = _gens(M, "vieux", hw - 1.6, 0.9, -105, "assis", ["Elle avance de douze minutes par jour. Moi, je recule de douze. On s'entend bien.",
				"Ma pendule a le hoquet. Tic-tic. Tac. Tic-tic. Tac.", "J'attends depuis une heure. Enfin, d'après ma pendule. Donc vingt minutes."])
			I._part(client.npc, I._boxm(Vector3(0.16, 0.22, 0.09)), Color(0.45, 0.28, 0.16), Vector3(0, 0.62, 0.3))
			_causer(M, client, ["Bonjour, jeune homme… ou jeune fille ? Ma vue retarde un peu, comme ma pendule. J'attends qu'on me la répare."],
				[["pendule", "Qu'est-ce qu'elle a, votre pendule ?", ["Elle sonne treize coups à midi. Le treizième, c'est pour la chance, dit-elle. Moi, je dis que c'est pour m'embêter.",
					"Elle a le hoquet. Tic-tic, tac. Gaspard dit qu'elle a avalé une seconde de travers."]]])
	# le coucou sort de temps en temps
	_souvent(M, 20.0, 32.0, func() -> void:
		if not is_instance_valid(oiseau):
			return
		M.main.sfx("clochette", oiseau.global_position)
		oiseau.visible = true
		oiseau.global_position = nid
		var tw: Tween = M.room.create_tween()
		tw.tween_property(oiseau, "global_position", dehors, 0.25)
		tw.tween_interval(1.4)
		tw.tween_property(oiseau, "global_position", nid, 0.25)
		tw.tween_callback(func() -> void: oiseau.visible = false)
		_montrer(M, bulle, 1.8)
		var qui: Node = appr if appr != null else patron
		if qui != null and is_instance_valid(qui) and _r(M).randf() < 0.5:
			qui.gesture("sursaut", 1.0))
	# le tic-tac de l'atelier
	_souvent(M, 5.0, 9.0, func() -> void: M.main.sfx("mecanisme", R.P(0.6, 1.8, -hd + 0.3), -10.0))
	# ce qu'on peut faire
	M.act(grandes[0], "E : remonter la grande pendule", func() -> void:
		M.main.sfx("mecanisme", grandes[0])
		if not bool(M.state().get("pendule116", false)):
			M.state()["pendule116"] = true
			M.give([["ressort", 1]], "Tu remontes la grande pendule : quarante tours de clé. Elle te remercie d'un tic plus appuyé, et un petit ressort tombe de sa caisse. « Garde-le », dit-on derrière toi." + "\n")
		else:
			M.say("Elle est remontée pour huit jours. Elle bat, fière comme un tambour.", 4.0), 1.3)
	M.act(R.P(-hw + 1.3, 0, 0.55), "E : regarder à la loupe", func() -> void:
		M.say(str(_pick(M, ["Dans la loupe, une montre ouverte : cent vingt pièces… et une fourmi qui fait la sieste sur le balancier.",
			"Sous la loupe, une roue grande comme un grain de sel. Elle a quarante dents. Plus que toi.",
			"Tu regardes dans la loupe : un œil énorme te regarde de l'autre côté. C'est le tien, dans le verre de la montre."])), 6.0), 1.0)
	if patron != null:
		M.ctx["entree"] = "Tu entres dans l'atelier de Gaspard. Il travaille tard, la loupe vissée à l'œil, au milieu de ses cent pendules."
	elif nuit:
		M.ctx["entree"] = "L'atelier dort, mais les pendules, elles, ne dorment jamais. L'apprentie finit une dernière montre à la lueur de la loupe."
	else:
		M.ctx["entree"] = str(_pick(M, ["Tic, tac, tic, tac… cent pendules battent ensemble dans l'atelier de l'horloger.",
			"L'atelier de Gaspard : des pendules du sol au plafond, et toutes à l'heure. Sauf une, qui fait exprès.",
			"Ça sent l'huile fine et le laiton. Partout, des balanciers vont et viennent, comme une forêt qui respire."]))


# =================================================================== l'Observatoire

static func _observatoire(M) -> void:
	var R = M.R
	var k = R.kit
	var nuit: bool = _nuit(M)
	var h: float = float(M.ctx.get("hour", 12.0))
	var rw: float = 6.4
	# les fenêtres en meurtrières
	for deg in [30.0, 150.0, 250.0, 330.0]:
		_fenetre_ronde(M, Vector3.ZERO, rw, 28, deg, 1.7, "fente")
	# l'orrerie, au milieu : son socle, sa colonne, le petit soleil, les planètes sur leurs bras
	k.cyl(R.L(0, 0, 0), 0.72, 0.78, 0.75, "bois_sombre", 24)
	k.cyl(R.L(0, 0.75, 0), 0.8, 0.8, 0.04, "or", 24)
	k.cyl(R.L(0, 0.79, 0), 0.05, 0.05, 0.55, "or", 8, false)
	k.col_cyl(R.P(0, 0, 0), 1.6, 1.5)
	var soleil: Node3D = I._node(M, R.P(0, 1.38, 0))
	I._part(soleil, I._sph(0.2), Color(1.0, 0.72, 0.25), Vector3.ZERO, Vector3.ONE, Vector3.ZERO, 3.0)
	_lampe(M, R.P(0, 1.38, 0), Color(1.0, 0.8, 0.5), 0.8, 3.2)
	_tourne(M, soleil, Vector3.UP, 0.2)
	var planetes: Array = [[0.42, 0.035, Color(0.6, 0.58, 0.55), 1.1], [0.6, 0.05, Color(0.95, 0.85, 0.6), 0.75], [0.8, 0.055, Color(0.3, 0.5, 0.9), 0.52],
		[0.98, 0.045, Color(0.85, 0.35, 0.22), 0.4], [1.22, 0.11, Color(0.86, 0.7, 0.5), 0.24], [1.48, 0.09, Color(0.92, 0.8, 0.52), 0.17]]
	for i in range(planetes.size()):
		var pl: Array = planetes[i]
		var ra: float = pl[0]
		var y: float = 1.36 - i * 0.025
		var piv: Node3D = I._node(M, R.P(0, 0, 0), _r(M).randf() * 360.0)
		I._part(piv, I._cyl(0.005, 0.005, ra), Color(0.85, 0.66, 0.3), Vector3(ra * 0.5, y, 0), Vector3.ONE, Vector3(0, 0, PI * 0.5), 0.0, 0.5)
		I._part(piv, I._cyl(0.005, 0.005, 0.06), Color(0.85, 0.66, 0.3), Vector3(ra, y + 0.03, 0), Vector3.ONE, Vector3.ZERO, 0.0, 0.5)
		var py: float = y + 0.06 + float(pl[1])
		I._part(piv, I._sph(pl[1]), pl[2], Vector3(ra, py, 0))
		if i == 2:
			var lune := Node3D.new()
			piv.add_child(lune)
			lune.position = Vector3(ra, py, 0)
			I._part(lune, I._sph(0.018), Color(0.85, 0.85, 0.82), Vector3(0.11, 0, 0))
			_tourne(M, lune, Vector3.UP, 2.4)
		if i == 5:
			_mesh(piv, _tore(0.11, 0.19), _m(M, "anneaux", Color(0.9, 0.82, 0.6), 0.5), Transform3D(Basis(Vector3.RIGHT, 0.35) * Basis.from_scale(Vector3(1.0, 0.12, 1.0)), Vector3(ra, py, 0)))
		_tourne(M, piv, Vector3.UP, float(pl[3]))
	# l'escalier en colimaçon (au fond à gauche), qui monte à la coupole
	var es := Vector3(-3.7, 0, -3.7)
	k.cyl(R.L(es.x, 0, es.z), 0.07, 0.07, 3.6, "fer", 8, false)
	for j in range(13):
		var ang: float = deg_to_rad(40.0 + j * 28.0)
		var sp := Vector3(es.x + cos(ang) * 0.5, 0.26 * (j + 1), es.z + sin(ang) * 0.5)
		k.box(Transform3D(Basis(Vector3.UP, -ang), R.P(sp.x, sp.y, sp.z)), Vector3(0.95, 0.05, 0.34), "fer", 1.0)
	k.col_cyl(R.P(es.x, 0, es.z), 1.05, 3.6)
	# les rayonnages d'atlas du ciel, le globe céleste, les cartes aux murs
	for deg2 in [165.0, 270.0, 300.0]:
		var c3: Vector3 = _contre(_facette(deg2, 28), 6.12)
		R.etagere(c3.x, c3.y, c3.z, 1.4, 2.2, true, 5)
	for deg3 in [15.0, 120.0, 195.0, 345.0]:
		var c4: Vector3 = _contre(_facette(deg3, 28), rw - 0.02)
		R.tableau(c4.x, 2.15, c4.y, c4.z, 1.1, 0.8, 4)
	var gl: Vector3 = _contre(130.0, 4.9)
	k.cyl(R.L(gl.x, 0, gl.y), 0.18, 0.12, 0.9, "bois_sombre", 10)
	var globe: Node3D = I._node(M, R.P(gl.x, 1.25, gl.y))
	I._part(globe, I._sph(0.32), Color(0.12, 0.18, 0.42), Vector3.ZERO, Vector3.ONE, Vector3.ZERO, 0.25)
	for j3 in range(14):
		var u := Vector3(_r(M).randf_range(-1, 1), _r(M).randf_range(-1, 1), _r(M).randf_range(-1, 1)).normalized()
		I._part(globe, I._sph(0.012), Color(1.0, 0.92, 0.6), u * 0.322, Vector3.ONE, Vector3.ZERO, 2.0)
	k.ring(Transform3D(Basis(Vector3.RIGHT, 0.4), R.P(gl.x, 1.25, gl.y)), 0.34, 0.37, 0.02, "or", 24)
	_tourne(M, globe, Vector3(0, 1, 0.35), 0.15)
	k.col_cyl(R.P(gl.x, 0, gl.y), 0.4, 1.6)
	# le bureau et le registre du Professeur Lunette
	R.table(4.3, 1.4, -90, 1.4, 0.8)
	k.box(R.L(4.25, 0.775, 1.5, -90), Vector3(0.5, 0.03, 0.36), "papier", 1.0)
	k.box(R.L(4.25, 0.78, 1.15, -90), Vector3(0.24, 0.04, 0.3), "cuir", 1.0)
	k.cyl(R.L(4.35, 0.76, 0.9), 0.05, 0.05, 0.12, "noir", 8)
	M.act(R.P(3.45, 0, 1.4), "E : lire le registre", func() -> void:
		M.main.sfx("ui_ouvrir", R.P(4.25, 0.8, 1.4))
		M.say(str(_pick(M, ["« 3 mars : compté 312 étoiles. Hier, 313. Enquête en cours. » — O. Lunette",
			"« Nuit claire. Saturne magnifique. Une mouette posée sur la lunette : vue sur Saturne cachée par une mouette. »",
			"« Vu la Cité des Nuées passer devant la Lune. Fait coucou. Personne n'a répondu. Normal : c'était la Lune. »",
			"« Nouvelle comète ! Baptisée Lunette-3. (Lunette-1 et Lunette-2 étaient des mouettes.) »",
			"« Pluie. Pas d'étoiles. Compté les gouttes sur la coupole : 4 812. Record battu. »"])), 7.0), 1.2)
	# les gens : le jour, l'assistante à son bureau et une classe en visite ; la nuit, un apprenti qui dort
	R.chaise(5.05, 1.4, -90)
	if not nuit:
		var assistante: Node = _gens(M, "femme", 5.05, 1.4, -90, "lire", ["Saturne a encore pris de l'avance. Il faudra lui parler.",
			"Une étoile filante cette nuit ! J'ai fait un vœu. Je ne te dis pas lequel : sinon, il tombe.", "Chut… je compte. Trois cent onze, trois cent douze…"])
		_causer(M, assistante, ["Bonjour ! Bienvenue à l'Observatoire. Le Professeur Lunette est sur la terrasse : il compte les nuages. Il dit que c'est de l'astronomie à l'envers.",
			"Ah, un visiteur ! Tu peux monter à la coupole, par l'escalier : la grande lunette t'attend. Ne touche pas aux planètes, elles sont réglées."],
			[["orrerie", "Comment marche l'orrerie ?", ["Un mécanisme de Gaspard l'horloger : deux cents roues. Chaque planète fait son tour à la bonne vitesse… à peu près. Mercure triche un peu.",
				"Le petit soleil, c'est une lampe. Le Professeur l'allume en premier le matin. Il lui dit « Bonjour, Soleil ». Le vrai ne répond pas, celui-ci non plus."]],
			["nuit", "On voit quoi, la nuit ?", ["La Lune, Saturne et ses anneaux, et la Cité des Nuées qui passe devant les étoiles. Reviens la nuit : la coupole s'ouvre en grand.",
				"Des milliers d'étoiles. Le Professeur en compte trois cent douze. Il dit que les autres ne comptent pas."]]])
		if h >= 8.0 and h < 17.5:
			var maitre: Node = _gens(M, "homme", 1.7, 1.9, -135, "enseigner", ["Les enfants, on ne touche pas aux planètes.",
				"Mercure fait le tour en trois minutes. Ici. En vrai, c'est plus long.", "Qui peut me dire comment s'appelle la planète aux anneaux ?"])
			maitre.follow = false
			_gens(M, "garcon", 0.4, 2.25, 175, "pointer", ["Elle tourne vite, la petite planète !", "Monsieur, c'est laquelle, la nôtre ?", "Je veux voir la Lune ! Maintenant !"])
			_gens(M, "fille", -0.8, 1.95, 160, "debout", ["Saturne ! C'est Saturne !", "Quand je serai grande, je compterai les étoiles. Toutes.", "Le soleil, il est tout petit, en vrai ?"])
	else:
		_gens(M, "garcon", 5.05, 1.4, -90, "dormir_assis", ["Zzz… Orion… à gauche… zzz…", "Trois cent douze… zzz…", "Encore cinq minutes, Professeur…"])
	# l'étage : la coupole, la grande lunette
	_coupole(M, nuit)
	M.act(R.P(es.x + 1.1, 0, es.z + 1.1), "E : monter à la coupole", func() -> void:
		M.main.sfx("pas_bois")
		M.go(R.P(-2.6, 0.05, -2.4 + UPZ), Vector3(1, 0, 1).normalized()), 1.4)
	if nuit:
		M.ctx["entree"] = "La nuit, l'Observatoire chuchote : on n'entend que le tic-tac de l'orrerie et, là-haut, la coupole qui grince."
	else:
		M.ctx["entree"] = str(_pick(M, ["Au milieu de la salle ronde, l'orrerie de laiton fait tourner ses planètes autour d'un petit soleil qui brille.",
			"Des cartes du ciel couvrent les murs. Au milieu, les planètes tournent, chacune à son rythme.",
			"L'Observatoire : des atlas du ciel jusqu'au plafond, un globe constellé d'étoiles, et l'orrerie qui ronronne."]))


## L'étage de l'Observatoire : la salle ronde sous la coupole, la fente, la grande lunette.
static func _coupole(M, nuit: bool) -> void:
	var R = M.R
	var k = R.kit
	var cw: Vector3 = R.P(0, 0, UPZ)
	var r: float = 6.4
	var seg: int = 28
	# le sol, le mur bas (2,4 m), la couronne de fer
	k.disc(Transform3D(Basis(), cw), r + 0.35, "sol", seg, float((R.pal["sol"] as Array)[2]))
	k.col_box(Transform3D(Basis(), cw + Vector3.DOWN * 0.25), Vector3(2.0 * r + 1.0, 0.5, 2.0 * r + 1.0))
	var chord: float = 2.0 * r * sin(PI / seg) + 0.06
	for i in range(seg):
		var am: float = PI * 0.5 + TAU * i / seg
		var dv := Vector3(cos(am), 0, sin(am))
		var xf := Transform3D(Basis.looking_at(-dv, Vector3.UP), cw + dv * (r + 0.15))
		k.box(xf * Transform3D(Basis(), Vector3(0, 1.2, 0)), Vector3(chord, 2.4, 0.3), "mur", 2.0)
		k.box(xf * Transform3D(Basis(), Vector3(0, 0.45, -0.16)), Vector3(chord, 0.9, 0.03), "bas", 1.4)
		k.col_box(xf * Transform3D(Basis(), Vector3(0, 2.0, 0)), Vector3(chord, 4.0, 0.3))
	k.ring(Transform3D(Basis(), cw + Vector3.UP * 2.32), r - 0.08, r + 0.2, 0.16, "fer", 40)
	# le haut de l'escalier : la trémie, sa rambarde
	var tr: Vector3 = R.P(-3.7, 0, -3.7 + UPZ)
	k.disc(Transform3D(Basis(), tr + Vector3.UP * 0.01), 1.02, "noir", 20)
	k.ring(Transform3D(Basis(), tr), 1.04, 1.1, 0.95, "fer", 24)
	k.col_cyl(tr, 1.1, 1.0)
	# le pied de la lunette (il ne tourne pas)
	k.cyl(Transform3D(Basis(), cw), 0.45, 0.32, 1.1, "fer", 16)
	k.cyl(Transform3D(Basis(), cw + Vector3.UP * 1.1), 0.5, 0.5, 0.06, "or", 20)
	k.col_cyl(cw, 0.5, 1.2)
	# la coupole et sa fente, la lunette : dans un pivot (on peut faire tourner la coupole)
	var piv: Node3D = I._node(M, cw)
	var rd: float = r + 0.1
	_mesh(piv, _hemi(rd, rd, 40, 14), _m(M, "coupole", Color(0.78, 0.77, 0.73), 0.7, 0.05, 0.0, true), Transform3D(Basis(), Vector3(0, 2.4, 0)))
	for lat in [0.3, 0.55, 0.78]:
		var y: float = sin(lat * PI * 0.5) * (rd - 0.06)
		var rr: float = cos(lat * PI * 0.5) * (rd - 0.06)
		var rg := TorusMesh.new()
		rg.inner_radius = rr - 0.06
		rg.outer_radius = rr
		rg.rings = 40
		rg.ring_segments = 6
		_mesh(piv, rg, _m(M, "nervure", Color(0.25, 0.25, 0.27), 0.5, 0.7), Transform3D(Basis(), Vector3(0, 2.4 + y, 0)))
	# la fente : une bande de ciel, de l'horizon jusqu'en haut (vers -Z)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n_s: int = 16
	var rs: float = r - 0.05
	for j in range(n_s):
		var e0: float = deg_to_rad(5.0 + 82.0 * j / n_s)
		var e1: float = deg_to_rad(5.0 + 82.0 * (j + 1) / n_s)
		var w2: float = 0.75
		var p00 := Vector3(-w2, 2.4 + sin(e0) * rs, -cos(e0) * rs)
		var p10 := Vector3(w2, 2.4 + sin(e0) * rs, -cos(e0) * rs)
		var p01 := Vector3(-w2, 2.4 + sin(e1) * rs, -cos(e1) * rs)
		var p11 := Vector3(w2, 2.4 + sin(e1) * rs, -cos(e1) * rs)
		var v0: float = float(j) / n_s
		var v1: float = float(j + 1) / n_s
		for v in [[p00, Vector2(0, v0)], [p10, Vector2(1, v0)], [p11, Vector2(1, v1)], [p00, Vector2(0, v0)], [p11, Vector2(1, v1)], [p01, Vector2(0, v1)]]:
			st.set_normal(Vector3(0, -0.3, 1).normalized())
			st.set_uv(v[1])
			st.add_vertex(v[0])
	var ciel := StandardMaterial3D.new()
	ciel.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ciel.cull_mode = BaseMaterial3D.CULL_DISABLED
	if nuit:
		ciel.albedo_texture = _etoiles()
		ciel.albedo_color = Color(1, 1, 1)
	else:
		ciel.albedo_color = Color(0.55, 0.74, 0.95)
	_mesh(piv, st.commit(), ciel)
	# la grande lunette : la fourche, l'axe, le tube (vers la fente), l'oculaire, le chercheur
	var bs := Basis(Vector3.RIGHT, deg_to_rad(-40.0))
	var d: Vector3 = bs * Vector3.UP
	var pa := Vector3(0, 2.15, 0)
	for s in [-1.0, 1.0]:
		_mesh(piv, BoxMesh.new(), _fer(M), Transform3D(Basis.from_scale(Vector3(0.08, 1.05, 0.16)), Vector3(s * 0.5, 1.625, 0)))
	_mesh(piv, _cylm(0.05, 0.05, 1.1, 10), _laiton(M), Transform3D(Basis(Vector3.BACK, PI * 0.5), pa))
	_mesh(piv, _cylm(0.34, 0.42, 5.2, 24), _laiton(M), Transform3D(bs, pa + d * 1.6))
	_mesh(piv, _cylm(0.44, 0.44, 0.12, 24), _fer(M), Transform3D(bs, pa + d * 4.15))
	_mesh(piv, _cylm(0.05, 0.07, 0.3, 10), _fer(M), Transform3D(bs, pa - d * 1.1))
	_mesh(piv, _cylm(0.06, 0.06, 0.8, 10), _laiton(M), Transform3D(bs, pa + d * 0.6 + Vector3(0.38, 0.12, 0)))
	var oculaire: Vector3 = pa - d * 1.25
	# la lumière : rouge sombre la nuit (pour garder les yeux habitués au noir), dorée le jour
	_lampe(M, cw + Vector3(0, 2.2, 1.5), Color(1.0, 0.45, 0.35) if nuit else Color(1.0, 0.9, 0.75), 1.2 if nuit else 1.4, 9.0)
	_lampe(M, cw + Vector3(-3.0, 1.8, -2.0), Color(1.0, 0.6, 0.45) if nuit else Color(0.9, 0.95, 1.0), 0.6, 6.0)
	# le volant qui fait tourner la coupole (à droite)
	var kp: Vector3 = R.P(3.6, 0, -1.4 + UPZ)
	k.cyl(Transform3D(Basis(), kp), 0.12, 0.09, 1.0, "fer", 10)
	var volant: Node3D = I._node(M, kp + Vector3(0, 1.05, 0), -60.0)
	_mesh(volant, _tore(0.3, 0.36), _fer(M), Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0, 0.14)))
	for sp in range(4):
		_mesh(volant, BoxMesh.new(), _fer(M), Transform3D(Basis(Vector3.BACK, TAU * sp / 4.0) * Basis.from_scale(Vector3(0.03, 0.62, 0.03)), Vector3(0, 0, 0.14)))
	k.col_cyl(kp, 0.25, 1.2)
	# les gens
	if nuit:
		var astro: Node = _gens(M, "femme", 0.9, 1.4 + UPZ, -150, "observer", ["Chut… Elle passe. La comète. Enfin, je crois. Ou c'est une mouette très loin.",
			"Trois cent douze étoiles comptées. Il en manque une. Elle doit être en retard.", "Regarde, si tu veux. Mais ne respire pas sur l'oculaire : ça fait des nuages."])
		astro.follow = false
	else:
		_gens(M, "homme", 2.4, 1.6 + UPZ, -120, "bricoler", ["Je cire le tube. Le Professeur dit qu'une lunette qui brille voit plus loin.",
			"Il y a eu une mouette dans la lunette, hier. On l'a appelée Comète.", "La fente s'ouvre en grand le soir. Le jour, on la laisse entrebâillée pour la mouette."])
	var it_lunette: Dictionary = M.act(piv.global_transform * (oculaire + Vector3(0, 0, 0.6)), "E : regarder dans la lunette", func() -> void:
		M.main.sfx("ui_clic")
		if nuit:
			M.say(str(_pick(M, ["La Lune, toute ronde : ses cratères, ses mers grises… et, au bord, un petit drapeau que le Professeur jure ne pas avoir planté.",
				"Saturne et ses anneaux, nets comme un dessin. Le Professeur l'appelle « la reine du bal ».",
				"La Cité des Nuées passe devant la Lune : ses lumières font une couronne. On voit même la capsule qui monte.",
				"Une comète, avec sa longue queue blanche ! Elle s'appelle Lunette-3. Lunette-1 et Lunette-2 étaient des mouettes."])), 7.0)
		else:
			M.say(str(_pick(M, ["Le Soleil, à travers le filtre fumé : trois taches, que le Professeur a baptisées Pim, Pam et Poum.",
				"De jour, on voit… le ciel. Et un pigeon, tout près, qui te regarde dans l'autre sens.",
				"La Cité des Nuées, en plein jour : on distingue les gens sur l'Esplanade du Ciel. Quelqu'un fait coucou. Tu fais coucou."])), 7.0), 1.1)
	# l'oculaire tourne avec la coupole : l'endroit où l'on regarde suit
	_chaque(M, func(_delta: float, _t: float) -> void:
		if is_instance_valid(piv):
			it_lunette["pos"] = piv.global_transform * (oculaire + Vector3(0, 0, 0.6)))
	M.act(kp + Vector3(-0.55, 0, 0.55), "E : faire tourner la coupole", func() -> void:
		if bool(M.ctx.get("coupole116", false)):
			return
		M.ctx["coupole116"] = true
		M.main.sfx("rouage", cw + Vector3.UP * 3.0)
		M.main.sfx("mecanisme", kp)
		var tw: Tween = M.room.create_tween()
		tw.set_parallel(true)
		tw.tween_property(piv, "rotation:y", piv.rotation.y + deg_to_rad(45.0), 3.0).set_trans(Tween.TRANS_SINE)
		tw.tween_property(volant, "rotation:z", volant.rotation.z + TAU, 3.0).set_trans(Tween.TRANS_SINE)
		tw.chain().tween_callback(func() -> void: M.ctx["coupole116"] = false)
		M.say("La coupole tourne en grondant, comme un gros chat qui se retourne dans son panier. La fente glisse sur le ciel.", 5.0), 1.0)
	M.act(R.P(-2.85, 0, -2.85 + UPZ), "E : redescendre", func() -> void:
		M.main.sfx("pas_bois")
		M.go(R.P(-2.4, 0.05, -2.4), Vector3(1, 0, 1).normalized()), 1.2)


## Une demi-sphère (une coupole) sans fond : rayon r, hauteur h, les normales vers l'intérieur.
static func _hemi(r: float, h: float, segs: int, rings: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in range(rings):
		var a0: float = PI * 0.5 * j / rings
		var a1: float = PI * 0.5 * (j + 1) / rings
		for i in range(segs):
			var b0: float = TAU * i / segs
			var b1: float = TAU * (i + 1) / segs
			var p00 := Vector3(cos(b0) * cos(a0) * r, sin(a0) * h, sin(b0) * cos(a0) * r)
			var p10 := Vector3(cos(b1) * cos(a0) * r, sin(a0) * h, sin(b1) * cos(a0) * r)
			var p01 := Vector3(cos(b0) * cos(a1) * r, sin(a1) * h, sin(b0) * cos(a1) * r)
			var p11 := Vector3(cos(b1) * cos(a1) * r, sin(a1) * h, sin(b1) * cos(a1) * r)
			for v in [p00, p10, p11, p00, p11, p01]:
				st.set_normal(-Vector3(v.x / r, v.y / h, v.z / r).normalized())
				st.add_vertex(v)
	return st.commit()


## Un ciel de nuit (des étoiles) pour la fente de la coupole.
static func _etoiles() -> ImageTexture:
	var img := Image.create(64, 512, false, Image.FORMAT_RGB8)
	img.fill(Color(0.02, 0.03, 0.08))
	var r := RandomNumberGenerator.new()
	r.seed = 116116
	for i in range(220):
		var x: int = r.randi() % 64
		var y: int = r.randi() % 512
		var b: float = r.randf_range(0.5, 1.0)
		img.set_pixel(x, y, Color(b, b, b * 0.95))
		if r.randf() < 0.15 and x < 63:
			img.set_pixel(x + 1, y, Color(b * 0.6, b * 0.6, b * 0.6))
	return ImageTexture.create_from_image(img)


# =================================================================== le Beffroi

static func _beffroi(M) -> void:
	var R = M.R
	var k = R.kit
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var nuit: bool = _nuit(M)
	# les trois cadrans, vus de dedans : du verre qui laisse passer le jour, les aiguilles qui tournent
	# à l'envers (on les voit de dos), à l'heure du jeu
	var verre: StandardMaterial3D = _m(M, "cadran", Color(1.0, 0.95, 0.82), 0.4, 0.0, 0.35 if nuit else 1.1)
	var aig: Array = []
	for spec in [[Vector3(0, 3.9, -hd + 0.06), Basis()], [Vector3(-hw + 0.06, 3.9, 0), Basis(Vector3.UP, PI * 0.5)], [Vector3(hw - 0.06, 3.9, 0), Basis(Vector3.UP, -PI * 0.5)]]:
		var lp: Vector3 = spec[0]
		var at: Vector3 = R.P(lp.x, lp.y, lp.z)
		var b: Basis = spec[1]
		var holder := Node3D.new()
		M.room.add_child(holder)
		holder.global_transform = Transform3D(b, at)
		_mesh(holder, _cylm(1.45, 1.45, 0.03, 40), verre, Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO))
		k.ring(Transform3D(b * Basis(Vector3.RIGHT, PI * 0.5), at + b * Vector3(0, 0, 0.02)), 1.45, 1.6, 0.06, "fer", 40)
		for hr in range(12):
			var a: float = TAU * hr / 12.0
			var mb := Basis(Vector3.BACK, a)
			k.box(Transform3D(b * mb, at + b * (Vector3(0, 0, 0.03) + mb * Vector3(0, 1.22, 0))), Vector3(0.06, 0.2 if hr % 3 == 0 else 0.12, 0.01), "noir", 1.0)
		var piv := Node3D.new()
		holder.add_child(piv)
		piv.position = Vector3(0, 0, 0.05)
		I._part(piv, I._boxm(Vector3(0.09, 0.78, 0.02)), Color(0.05, 0.05, 0.06), Vector3(0, 0.32, 0))
		var piv2 := Node3D.new()
		holder.add_child(piv2)
		piv2.position = Vector3(0, 0, 0.07)
		I._part(piv2, I._boxm(Vector3(0.06, 1.15, 0.02)), Color(0.05, 0.05, 0.06), Vector3(0, 0.5, 0))
		I._part(holder, I._cyl(0.06, 0.06, 0.06), Color(0.85, 0.66, 0.3), Vector3(0, 0, 0.08), Vector3.ONE, Vector3(PI * 0.5, 0, 0), 0.0, 0.5)
		aig.append([piv, piv2])
		R.mark_wall(lp.x, lp.y, lp.z, 1.6)
		# l'arbre de transmission, de la boîte de renvoi jusqu'au cadran
		var from: Vector3 = R.P(0, 3.9, 0)
		var dd: Vector3 = at - from
		var len: float = dd.length() - 0.25
		k.cyl(Transform3D(Basis.looking_at(dd.normalized(), Vector3.UP) * Basis(Vector3.RIGHT, -PI * 0.5), from), 0.03, 0.03, len, "fer", 6, false)
	k.box(R.L(0, 3.9, 0), Vector3(0.4, 0.4, 0.4), "fer", 1.0)
	k.cyl(R.L(0, 3.0, 0), 0.035, 0.035, 0.75, "fer", 6, false)
	_lampe(M, R.P(0, 3.6, -hd + 1.6), Color(1.0, 0.92, 0.75), 0.5 if nuit else 1.4, 6.0)
	_lampe(M, R.P(0.6, 2.6, 2.7), Color(1.0, 0.88, 0.68), 1.3, 7.5)
	_chaque(M, func(_delta: float, _t: float) -> void:
		var hh: float = float(M.main.temps_v56.hour) if M.main.get("temps_v56") != null else 12.0
		var a_m: float = fmod(hh, 1.0) * TAU
		var a_h: float = fmod(hh, 12.0) / 12.0 * TAU
		for p in aig:
			if is_instance_valid(p[0]):
				(p[0] as Node3D).transform.basis = Basis(Vector3.BACK, a_h)
				(p[1] as Node3D).transform.basis = Basis(Vector3.BACK, a_m))
	# le mécanisme, au milieu : un bâti de fer, les roues, l'échappement, l'ancre
	for e in [[-1.2, -0.5], [1.2, -0.5], [-1.2, 0.5], [1.2, 0.5]]:
		k.box(R.L(float(e[0]), 1.5, float(e[1])), Vector3(0.12, 3.0, 0.12), "fer", 1.0)
	for e2 in [[3.0, -0.5], [3.0, 0.5], [1.0, -0.5], [1.0, 0.5]]:
		k.box(R.L(0, float(e2[0]), float(e2[1])), Vector3(2.5, 0.1, 0.1), "fer", 1.0)
	k.col_box(R.L(0, 1.5, 0.2), Vector3(2.6, 3.0, 1.6))
	var laiton: StandardMaterial3D = _laiton(M)
	var fer: StandardMaterial3D = _fer(M)
	var grande: Node3D = _roue(M, R.P(-0.3, 1.55, 0.0), Vector3.BACK, 0.85, 36, 0.06, laiton)
	var moyenne: Node3D = _roue(M, R.P(0.83, 1.89, 0.0), Vector3.BACK, 0.4, 17, 0.06, fer)
	var petite: Node3D = _roue(M, R.P(0.62, 2.72, 0.06), Vector3.BACK, 0.28, 15, 0.04, laiton)
	_tourne(M, grande, Vector3.BACK, 0.12)
	_tourne(M, moyenne, Vector3.BACK, -0.255)
	# la roue d'échappement avance d'une dent à chaque battement ; l'ancre bascule
	var ancre: Node3D = I._node(M, R.P(0.62, 3.12, 0.1))
	I._part(ancre, I._boxm(Vector3(0.5, 0.05, 0.03)), Color(0.2, 0.2, 0.22), Vector3.ZERO, Vector3.ONE, Vector3.ZERO, 0.0, 0.45)
	for s in [-1.0, 1.0]:
		I._part(ancre, I._boxm(Vector3(0.04, 0.14, 0.03)), Color(0.2, 0.2, 0.22), Vector3(s * 0.22, -0.07, 0), Vector3.ONE, Vector3(0, 0, s * 0.3), 0.0, 0.45)
	_balance(M, ancre, Vector3.BACK, 0.12, 3.6)
	_souvent(M, 1.8, 1.8, func() -> void:
		if is_instance_valid(petite):
			petite.rotate_object_local(Vector3.BACK, -TAU / 30.0)
		M.main.sfx("ui_clic", R.P(0.62, 2.72, 0.2), -18.0))
	# le grand balancier, devant le mécanisme, et son portique
	var bal: Node3D = I._node(M, R.P(0, 5.0, 0.9))
	I._part(bal, I._cyl(0.025, 0.025, 3.3), Color(0.2, 0.2, 0.22), Vector3(0, -1.65, 0), Vector3.ONE, Vector3.ZERO, 0.0, 0.45)
	I._part(bal, I._cyl(0.3, 0.3, 0.06), Color(0.86, 0.66, 0.3), Vector3(0, -3.35, 0), Vector3.ONE, Vector3(PI * 0.5, 0, 0), 0.0, 0.5)
	_balance(M, bal, Vector3.BACK, 0.1, 3.6)
	k.box(R.L(0, 5.06, 0.9), Vector3(1.7, 0.14, 0.22), "fer", 1.0)
	for s4 in [-1.0, 1.0]:
		k.box(R.L(s4 * 0.78, 2.53, 0.9), Vector3(0.12, 5.06, 0.12), "fer", 1.0)
	# deux pigeons sur le portique
	for pg in [[-0.5, 1.0], [0.3, -1.0]]:
		var pn: Node3D = I._node(M, R.P(float(pg[0]), 5.13, 0.9), 90.0 * float(pg[1]))
		I._part(pn, I._sph(0.07), Color(0.55, 0.57, 0.6), Vector3(0, 0.06, 0), Vector3(1, 0.85, 1.4))
		I._part(pn, I._sph(0.045), Color(0.45, 0.5, 0.55), Vector3(0, 0.14, 0.08))
		I._part(pn, I._cyl(0.0, 0.012, 0.03), Color(0.9, 0.7, 0.3), Vector3(0, 0.14, 0.14), Vector3.ONE, Vector3(PI * 0.5, 0, 0))
		_balance(M, pn, Vector3.RIGHT, 0.15, 1.6, float(pg[0]) * 3.0)
	_souvent(M, 14.0, 25.0, func() -> void: M.main.sfx("pigeon", R.P(0, 5.1, 0.9), -6.0))
	# la poussière dans la lumière des cadrans
	_poussiere(M, R.P(0, 3.4, 0), Vector3(3.6, 1.6, 3.6), 36, Color(1.0, 0.95, 0.85, 0.35), 0.02)
	# la corde de la cloche (la cloche est au-dessus, dans le campanile)
	var corde := Vector3(hw - 1.2, 0, hd - 1.6)
	k.cyl(R.L(corde.x, 1.1, corde.z), 0.025, 0.025, R.H - 1.1, "tissu_creme", 6, false)
	k.cyl(R.L(corde.x, 0.85, corde.z), 0.05, 0.05, 0.3, "bois", 8)
	var tremble: CPUParticles3D = _poussiere(M, R.P(0, R.H - 0.3, 0), Vector3(3.5, 0.2, 3.5), 40, Color(0.85, 0.8, 0.7, 0.6), 0.025)
	tremble.preprocess = 0.0
	tremble.one_shot = true
	tremble.emitting = false
	M.ctx["cloche116"] = -100.0
	# le gardien du beffroi
	var gardien: Node = _gens(M, "vieux", 1.75, 1.3, -125, "bricoler", ["Tic. Tac. Tic. Tac. On s'habitue. Au bout de quarante ans.",
		"Je graisse les roues tous les matins. Elles me disent merci en grinçant moins fort.", "L'horloge avance de trois secondes par an. Je les lui reprends à Noël.",
		"Ne touche pas au balancier : il a horreur qu'on le pousse."])
	_causer(M, gardien, ["Bienvenue dans le ventre de l'horloge ! Cent douze marches pour monter, ça se mérite. Je suis le gardien du beffroi : je donne l'heure à toute la ville.",
		"Ah, un visiteur ! Attention au balancier, il passe tout près. Et ne siffle pas : la grande roue croit qu'on l'appelle."],
		[["comment", "Comment ça marche ?", ["Le poids descend, il tire la grande roue ; la grande roue tourne les autres ; l'échappement les retient, une dent à chaque battement. Tic, tac. Et les aiguilles avancent, sur les trois cadrans.",
			"Le balancier bat les secondes. L'ancre, en haut, laisse passer une dent de la petite roue à chaque fois. Sans elle, tout partirait d'un coup : la ville vivrait une journée en une minute."]],
		["heure", "Elle est à l'heure ?", ["Elle EST l'heure. Toutes les horloges de Hautefond se règlent sur elle. Même celles de Gaspard. Surtout celles de Gaspard.",
			"À la seconde près. Sauf le jour de la fête : ce jour-là, je la retarde de cinq minutes, pour que la fête dure plus longtemps."]],
		["cadeau", "Je peux t'aider ?", func() -> void:
			if not bool(M.state().get("roue116", false)):
				M.state()["roue116"] = true
				M.talk(gardien, "Tu viens de le faire : tu m'as écouté. Tiens, une petite roue qui a pris sa retraite. Elle a tourné trente ans ; elle a bien mérité de voyager.", [{"id": "fermer", "label": "Merci !"}], func(_i):
					M.give([["engrenage", 1]], "")
					M.close_talk())
			else:
				M.talk(gardien, "Reviens à midi, quand les trois cadrans montrent la même chose. C'est le seul moment où ils sont d'accord.", [{"id": "fermer", "label": "Promis !"}], func(_i): M.close_talk())]])
	M.act(R.P(corde.x - 0.45, 0, corde.z), "E : tirer la corde de la cloche", func() -> void:
		var t: float = float(M.ctx.get("t116", 0.0))
		if t - float(M.ctx.get("cloche116", -100.0)) < 12.0:
			M.say("La cloche vibre encore. Laisse-la souffler un peu.", 3.0)
			return
		M.ctx["cloche116"] = t
		M.main.sfx("cloche_cathedrale", R.P(0, R.H + 2.0, 0))
		if is_instance_valid(tremble):
			tremble.restart()
		for f in M.people:
			if is_instance_valid(f):
				f.gesture("sursaut", 1.2)
		M.say(str(_pick(M, ["BONG ! … BONG ! Tout le beffroi tremble. Quelque part en bas, le Bourgmestre lâche sa plume.",
			"BOOONG ! La poussière tombe des poutres. Les pigeons font semblant de ne rien avoir entendu.",
			"BONG ! Toute la ville lève le nez. Le gardien soupire : « Encore un qui a tiré la corde. »"])), 5.0), 1.2)
	M.ctx["entree"] = str(_pick(M, ["Cent douze marches plus haut : te voilà dans la salle de l'horloge. Ça tourne, ça bat, ça cliquette.",
		"Dans le beffroi, tout respire au rythme du grand balancier. Tic… tac… Les cadrans, vus de dos, laissent passer la lumière.",
		"La salle de l'horloge : des roues de laiton grandes comme des tables, un balancier qui va et vient, et un gardien qui chantonne en mesure."]))


# =================================================================== la Capitainerie

static func _capitainerie(M) -> void:
	var R = M.R
	var k = R.kit
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	# la table des cartes et sa carte des mers, les petits bateaux du port
	R.table(0, -0.4, 0, 2.6, 1.5, 0.9)
	k.box(R.L(0, 0.903, -0.4), Vector3(2.4, 0.006, 1.32), "tableau_3", 2.4, 4)
	var flotte: Array = []
	for i in range(7):
		var bt: Node3D = I._node(M, R.P(_r(M).randf_range(-1.0, 1.0), 0.906, -0.4 + _r(M).randf_range(-0.5, 0.5)), _r(M).randf() * 360.0)
		var col: Color = [Color(0.8, 0.2, 0.15), Color(0.2, 0.35, 0.7), Color(0.95, 0.85, 0.3), Color(0.25, 0.55, 0.3), Color(0.95, 0.95, 0.9)][i % 5]
		I._part(bt, I._boxm(Vector3(0.06, 0.035, 0.15)), col, Vector3(0, 0.018, 0))
		I._part(bt, I._boxm(Vector3(0.005, 0.08, 0.06)), Color(0.96, 0.94, 0.88), Vector3(0, 0.07, 0))
		flotte.append(bt)
	k.box(R.L(0.75, 0.905, -0.75, 25), Vector3(0.36, 0.01, 0.04), "or", 1.0)
	# la longue-vue, devant la fenêtre de gauche
	var lv := Vector3(-hw + 0.9, 0, -hd + R.D * 0.25)
	for j in range(3):
		var a: float = TAU * j / 3.0
		k.cyl(Transform3D(Basis(Vector3(cos(a + PI * 0.5), 0, sin(a + PI * 0.5)), 0.22), R.P(lv.x + cos(a) * 0.3, 0, lv.z + sin(a) * 0.3)), 0.015, 0.015, 1.3, "bois_sombre", 6, false)
	k.cyl(Transform3D(Basis(Vector3.BACK, 1.35), R.P(lv.x + 0.35, 1.3, lv.z)), 0.05, 0.035, 0.9, "or", 12)
	k.col_cyl(R.P(lv.x, 0, lv.z), 0.4, 1.4)
	# les pavillons de signaux, en guirlande sur le mur de droite (entre les deux fenêtres)
	var pav: Array = ["tissu_rouge", "tissu_jaune", "tissu_bleu", "tissu_blanc", "tissu_noir", "tissu_vert", "tissu_rouge"]
	k.cyl(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), R.P(hw - 0.12, 2.45, -1.0)), 0.006, 0.006, 2.0, "tissu_creme", 4, false)
	for j2 in range(7):
		var pz: float = -0.86 + j2 * 0.28
		k.box(R.L(hw - 0.12, 2.29, pz), Vector3(0.012, 0.3, 0.22), str(pav[j2]), 1.0)
		if j2 % 2 == 0:
			k.box(R.L(hw - 0.11, 2.29, pz), Vector3(0.014, 0.12, 0.09), str(pav[(j2 + 3) % 7]), 1.0)
	R.mark_wall(hw, 2.3, 0.0, 1.1)
	# la marée et le baromètre, au fond
	var mar: Vector3 = R.P(1.6, 2.1, -hd + 0.03)
	k.cyl(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), mar), 0.32, 0.32, 0.04, "ceramique", 24, true)
	k.ring(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), mar + Vector3(0, 0, 0.005)), 0.32, 0.37, 0.06, "or", 24)
	var aig_m: Node3D = I._node(M, mar + Vector3(0, 0, 0.05))
	I._part(aig_m, I._boxm(Vector3(0.025, 0.26, 0.01)), Color(0.1, 0.15, 0.4), Vector3(0, 0.11, 0))
	_tourne(M, aig_m, Vector3.BACK, -0.02)
	R.mark_wall(1.6, 2.1, -hd, 0.45)
	var baro: Vector3 = R.P(2.5, 2.0, -hd + 0.03)
	k.box(Transform3D(Basis(), baro), Vector3(0.22, 0.7, 0.05), "bois_sombre", 1.0)
	k.cyl(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), baro + Vector3(0, 0.15, 0.025)), 0.09, 0.09, 0.02, "ceramique", 16, true)
	# la bouée de sauvetage au mur de gauche, le banc des marins dessous ; la maquette du bateau de ligne
	var bo: Vector3 = R.P(-hw + 0.04, 1.75, 0.0)
	k.ring(Transform3D(Basis(Vector3.BACK, -PI * 0.5), bo), 0.17, 0.3, 0.1, "tissu_rouge", 20)
	for q in range(4):
		var qa: float = TAU * q / 4.0 + PI * 0.25
		k.box(Transform3D(Basis(Vector3.RIGHT, qa), bo + Vector3(0.05, 0, 0) + Basis(Vector3.RIGHT, qa) * Vector3(0, 0.235, 0)), Vector3(0.11, 0.14, 0.13), "tissu_blanc", 1.0)
	R.mark_wall(-hw, 1.75, 0.0, 0.4)
	R.banc(-hw + 0.3, 0.0, 90, 1.7)
	var mq: Transform3D = R.L(hw - 0.7, 0, hd - 0.75, 180)
	k.box(mq * Transform3D(Basis(), Vector3(0, 0.45, 0)), Vector3(1.2, 0.9, 0.5), "bois_sombre", 1.0)
	k.box(mq * Transform3D(Basis(), Vector3(0, 0.08, 0)), Vector3(1.0, 0.03, 0.12), "bois", 1.0)
	k.box(mq * Transform3D(Basis(), Vector3(0, 1.02, 0)), Vector3(0.75, 0.14, 0.16), "noir", 1.0)
	k.box(mq * Transform3D(Basis(), Vector3(0.15, 1.16, 0)), Vector3(0.3, 0.14, 0.12), "tissu_blanc", 1.0)
	k.cyl(mq * Transform3D(Basis(), Vector3(-0.1, 1.09, 0)), 0.03, 0.03, 0.35, "tissu_rouge", 8)
	k.box(mq * Transform3D(Basis(), Vector3(0, 1.15, 0)), Vector3(1.0, 0.5, 0.42), "verre", 1.0, 63 - 8)
	k.col_box(mq * Transform3D(Basis(), Vector3(0, 0.7, 0)), Vector3(1.2, 1.4, 0.5))
	R.reserve(hw - 0.7, hd - 0.75, 1.4, 0.7)
	# la cloche du port, près de la porte
	var cl := Vector3(1.9, 2.05, hd)
	k.box(R.L(cl.x, cl.y + 0.25, cl.z - 0.2), Vector3(0.06, 0.06, 0.4), "fer", 1.0)
	k.box(R.L(cl.x, cl.y + 0.1, cl.z - 0.02), Vector3(0.16, 0.4, 0.03), "bois_sombre", 1.0)
	var cloche: Node3D = I._node(M, R.P(cl.x, cl.y + 0.22, cl.z - 0.35))
	I._part(cloche, I._cyl(0.09, 0.16, 0.24), Color(0.78, 0.55, 0.25), Vector3(0, -0.14, 0), Vector3.ONE, Vector3.ZERO, 0.0, 0.5)
	I._part(cloche, I._sph(0.03), Color(0.5, 0.35, 0.2), Vector3(0, -0.28, 0))
	M.act(R.P(cl.x - 0.3, 0, cl.z - 1.0), "E : sonner la cloche du port", func() -> void:
		M.main.sfx("cloche_bateau", cloche.global_position)
		var tw: Tween = M.room.create_tween()
		for k2 in range(3):
			tw.tween_property(cloche, "rotation:x", 0.5, 0.15)
			tw.tween_property(cloche, "rotation:x", -0.5, 0.2)
		tw.tween_property(cloche, "rotation:x", 0.0, 0.2)
		M.say(str(_pick(M, ["Ding ! Ding ! Dehors, trois mouettes s'envolent et un marin crie : « Déjà la soupe ? »",
			"La cloche du port sonne clair. Le commis ne lève même pas les yeux : « C'est la quatrième fois aujourd'hui. »"])), 4.5), 1.1)
	# le bureau du commis, ses registres, son tampon ; les clés des quais
	R.table(2.9, -hd + 1.25, 0, 1.4, 0.75)
	R.chaise(2.9, -hd + 0.6, 0)
	for rg in range(3):
		k.box(R.L(2.45, 0.785 + rg * 0.05, -hd + 1.3, 8.0 * rg), Vector3(0.3, 0.045, 0.22), ["tissu_rouge", "tissu_vert", "cuir"][rg], 1.0)
	k.box(R.L(2.95, 0.765, -hd + 1.35, -5), Vector3(0.32, 0.01, 0.24), "papier", 1.0)
	var tampon: Node3D = I._node(M, R.P(3.35, 0.76, -hd + 1.3))
	I._part(tampon, I._cyl(0.035, 0.035, 0.08), Color(0.35, 0.22, 0.14), Vector3(0, 0.08, 0))
	I._part(tampon, I._cyl(0.05, 0.05, 0.02), Color(0.15, 0.15, 0.16), Vector3(0, 0.02, 0))
	for kk in range(8):
		k.box(R.L(-1.5 + kk * 0.18, 1.7, -hd + 0.03), Vector3(0.05, 0.12, 0.02), "or", 1.0)
	k.box(R.L(-0.87, 1.8, -hd + 0.02), Vector3(1.5, 0.05, 0.03), "bois_sombre", 1.0)
	R.mark_wall(-0.9, 1.7, -hd, 0.8)
	var commis: Node = _gens(M, "homme", 2.9, -hd + 0.6, 0, "lire", ["Bateau de ligne : à l'heure. Les mouettes : en avance.", "Tamponné. Contre-tamponné. Re-tamponné.",
		"Le maître du port est sur le quai : il compte les mouettes. Il en trouve toujours une de trop."])
	_causer(M, commis, ["Capitainerie du Port des Cordages, bonjour. Un bateau à déclarer ? Une mouette à signaler ? Un tampon à faire tamponner ?",
		"Bonjour ! Prends un numéro. Ah non, il n'y a pas de numéros. Prends… une chaise, alors."],
		[["port", "Qu'est-ce qui se passe au port ?", ["Le bateau de ligne arrive à l'heure, l'Albatros part en retard, et la barque de Léon n'est toujours pas une barque : c'est une baignoire à rames.",
			"Trois bateaux de pêche, un bateau de ligne, un dirigeable au-dessus, et une mouette qui se prend pour un navire. Je l'ai inscrite au registre. Elle était contente."]],
		["leon", "Où est Léon, le maître du port ?", ["Sur le quai, avec sa longue-vue. Il dit qu'il surveille la mer. Moi, je crois qu'il surveille les gâteaux de la boulangère.",
			"Sur le quai. Il revient quand il pleut. Ou quand il faut signer quelque chose. C'est-à-dire quand il pleut."]]])
	_souvent(M, 6.0, 10.0, func() -> void:
		if not is_instance_valid(tampon):
			return
		var y0: float = tampon.position.y
		var tw2: Tween = M.room.create_tween()
		tw2.tween_property(tampon, "position:y", y0 + 0.08, 0.15)
		tw2.tween_property(tampon, "position:y", y0, 0.08)
		M.main.sfx("tampon_bureau", tampon.global_position, -6.0))
	# une pêcheuse qui réclame, un marin qui attend
	if not _nuit(M):
		var pecheuse: Node = _gens(M, "femme", 2.6, -hd + 2.3, 170, "pointer", ["Ma barque a été rangée à la place de celle de Léon !",
			"Je veux voir le maître du port ! Ou au moins son chapeau !", "Trois heures que j'attends. Mes sardines, elles, n'attendent pas."])
		_causer(M, pecheuse, ["Tu travailles ici ? Non ? Dommage. Ma barque a été rangée à la place de celle de Léon. Léon n'a pas de barque. Il a une baignoire à rames !"],
			[["calme", "Tout va s'arranger, non ?", ["Tu as raison. Le commis va tamponner quelque chose, et tout ira mieux. Ça marche toujours, les tampons.",
				"Peut-être. En attendant, mes sardines regardent l'heure."]]], "agacée")
	_gens(M, "homme", -hw + 1.2, hd - 1.9, 70, "bras_croises", ["Ça mord pas, aujourd'hui. Même les poissons font la grève.", "Le vent tourne. Le café aussi, d'ailleurs : il tourne froid.",
		"J'ai vu l'Albatros raser la Colonne, ce matin. Il y avait un passager qui faisait coucou."])
	# le commis pousse un petit bateau sur la carte, de temps en temps
	_souvent(M, 9.0, 15.0, func() -> void:
		var bt2: Node3D = flotte[_r(M).randi() % flotte.size()]
		if not is_instance_valid(bt2):
			return
		var to: Vector3 = R.P(_r(M).randf_range(-1.0, 1.0), 0.906, -0.4 + _r(M).randf_range(-0.5, 0.5))
		var tw3: Tween = M.room.create_tween()
		tw3.tween_property(bt2, "global_position", to, 1.6).set_trans(Tween.TRANS_SINE))
	M.act(R.P(lv.x + 0.9, 0, lv.z + 0.35), "E : regarder par la longue-vue", func() -> void:
		M.say(str(_pick(M, ["Le bateau de ligne double la Pointe. Son capitaine fait coucou. Ou il chasse une mouette.",
			"Là-haut, l'Albatros longe la Colonne, ses hélices tournent tout doucement.", "Un phoque dort sur les rochers du phare. Margot lui a donné un nom : Monsieur Galet.",
			"Trois barques de pêche rentrent, chargées de sardines qui brillent. Et une baignoire à rames : Léon."])), 6.0), 1.2)
	M.act(R.P(-0.6, 0, 0.75), "E : regarder la carte des mers", func() -> void:
		M.say(str(_pick(M, ["Sur la carte, chaque bateau du port a sa petite maquette de bois. On les pousse au fil des marées.",
			"La carte des mers de Hautefond : les courants dessinés à l'encre bleue, et, dans un coin, « Ici, des baleines (gentilles) »."])), 6.0), 1.1)
	M.ctx["entree"] = str(_pick(M, ["La Capitainerie : une grande carte des mers sur la table, des petits bateaux de bois qu'on pousse au fil des marées.",
		"Ça sent le sel, l'encre et le café froid. Le commis tamponne, les marins attendent.",
		"Sur la table des cartes, chaque bateau du port a sa petite maquette. Il y en a même une pour la baignoire à rames de Léon."]))


# =================================================================== le Phare

static func _phare(M) -> void:
	var R = M.R
	var k = R.kit
	var nuit: bool = _nuit(M)
	var rw: float = 3.4
	# l'escalier qui tourne le long du mur, au fond, et monte à la lanterne
	for j in range(12):
		var deg: float = 200.0 + j * 15.0
		var ang: float = deg_to_rad(deg)
		var sp := Vector3(cos(ang) * 2.95, 0.24 * (j + 1), sin(ang) * 2.95)
		var sb := Basis(Vector3.UP, -ang)
		k.box(Transform3D(sb, R.P(sp.x, sp.y - 0.03, sp.z)), Vector3(0.8, 0.06, 0.82), "bois_sombre", 1.0)
		k.box(Transform3D(sb, R.P(sp.x, (sp.y - 0.06) * 0.5, sp.z)), Vector3(0.78, sp.y - 0.06, 0.8), "mur", 2.0)
		k.col_box(Transform3D(sb, R.P(sp.x, R.H * 0.5, sp.z)), Vector3(0.8, R.H, 0.8))
	var tops: Array = []
	for j0 in range(12):
		var ang2: float = deg_to_rad(200.0 + j0 * 15.0)
		k.cyl(R.L(cos(ang2) * 2.55, 0.24 * (j0 + 1), sin(ang2) * 2.55), 0.015, 0.015, 0.9, "fer", 4, false)
		tops.append(R.P(cos(ang2) * 2.55, 0.24 * (j0 + 1) + 0.9, sin(ang2) * 2.55))
	for j1 in range(tops.size() - 1):
		var ta: Vector3 = tops[j1]
		var tb2: Vector3 = tops[j1 + 1]
		var dd: Vector3 = tb2 - ta
		k.cyl(Transform3D(Basis.looking_at(dd.normalized(), Vector3.UP) * Basis(Vector3.RIGHT, -PI * 0.5), ta), 0.02, 0.02, dd.length(), "bois_sombre", 6, false)
	# les fenêtres
	for deg2 in [40.0, 140.0]:
		_fenetre_ronde(M, Vector3.ZERO, rw, 16, deg2, 1.6, "rond")
	# le coin du gardien : la table, le journal, la lampe-tempête
	var tb: Vector3 = _contre(165.0, 2.55)
	R.table(tb.x, tb.y, tb.z, 1.1, 0.65)
	var ch: Vector3 = _contre(165.0, 1.75)
	R.chaise(ch.x, ch.y, ch.z + 180.0)
	k.box(R.L(tb.x + 0.1, 0.775, tb.y - 0.1, tb.z), Vector3(0.42, 0.03, 0.3), "cuir", 1.0)
	k.cyl(R.L(tb.x - 0.05, 0.76, tb.y + 0.35), 0.08, 0.08, 0.25, "cuivre", 10)
	k.cyl(R.L(tb.x - 0.05, 0.86, tb.y + 0.35), 0.05, 0.05, 0.1, "lumiere", 8)
	_lampe(M, R.P(tb.x, 1.2, tb.y + 0.3), Color(1.0, 0.8, 0.5), 0.8, 3.0)
	# les bidons d'huile et la corne de brume (à droite)
	for j2 in range(4):
		var bd: Vector3 = _contre(35.0 + j2 * 9.0, 2.9)
		k.cyl(R.L(bd.x, 0, bd.y), 0.15, 0.15, 0.45, "tissu_rouge" if j2 % 2 == 0 else "cuivre", 12)
		k.col_cyl(R.P(bd.x, 0, bd.y), 0.17, 0.5)
	var cb: Vector3 = _contre(22.0, 2.95)
	var cbw: Vector3 = R.P(cb.x, 1.2, cb.y)
	k.box(R.L(cb.x, 1.2, cb.y, cb.z), Vector3(0.35, 0.5, 0.2), "fer", 1.0)
	k.cyl(Transform3D(Basis(Vector3.UP, deg_to_rad(cb.z)) * Basis(Vector3.RIGHT, PI * 0.5), cbw + Basis(Vector3.UP, deg_to_rad(cb.z)) * Vector3(0, 0.1, 0.1)), 0.05, 0.16, 0.3, "cuivre", 12, false)
	var levier: Node3D = I._node(M, cbw + Vector3(0, -0.15, 0), cb.z)
	I._part(levier, I._cyl(0.02, 0.02, 0.4), Color(0.7, 0.15, 0.12), Vector3(0, 0.2, 0.15), Vector3.ONE, Vector3(0.5, 0, 0))
	k.col_box(R.L(cb.x, 0.6, cb.y, cb.z), Vector3(0.5, 1.2, 0.4))
	# l'apprenti gardien, et la lanterne de cuivre qu'il fait briller
	R.tabouret(0.4, -0.15)
	k.cyl(R.L(0.4, 0.44, -0.15), 0.09, 0.09, 0.05, "cuivre", 10)
	k.cyl(R.L(0.4, 0.49, -0.15), 0.07, 0.07, 0.18, "verre", 10)
	k.cyl(R.L(0.4, 0.67, -0.15), 0.09, 0.03, 0.08, "cuivre", 10)
	var app: Node = _gens(M, "garcon", 0.7, 0.4, -150, "bricoler", ["Je fais briller le cuivre. Margot dit qu'un phare, ça se voit aussi de jour.",
		"La nuit, je compte les bateaux qui passent. Hier, sept. Et une baleine.", "Cent quarante-quatre marches. Je les monte en courant. Enfin, les quarante premières."])
	_causer(M, app, ["Bonjour ! Tu viens voir la lanterne ? L'escalier est là, au fond. Ne regarde pas en bas, ça tourne un peu.",
		"Salut ! Je suis l'apprenti de Margot. Elle est dehors, sur les rochers : elle parle au phoque."],
		[["margot", "Comment est Margot ?", ["Margot ? Elle connaît le nom de chaque vague. Elle dit qu'elles se ressemblent, mais pas tout à fait, comme des sœurs.",
			"Elle parle peu, mais quand elle parle, même le vent se tait pour écouter."]],
		["nuit", "Tu n'as pas peur, la nuit ?", ["Avec la lanterne ? Jamais. La nuit, c'est nous qui éclairons tout le monde. Même la Lune nous dit merci.",
			"Un peu, quand la corne de brume souffle toute seule. Mais c'est juste le vent qui veut chanter."]]])
	M.act(R.P(tb.x * 0.62, 0, tb.y * 0.62), "E : lire le journal du phare", func() -> void:
		M.main.sfx("ui_ouvrir")
		M.say(str(_pick(M, ["« Nuit calme. Lanterne allumée à 19 h 58. Un bateau de pêche a fait trois appels de lumière. J'ai répondu. »",
			"« Brume épaisse. Corne de brume toute la nuit. Le phoque, Monsieur Galet, a chanté avec. Faux. »",
			"« L'Albatros est passé si bas qu'on s'est dit bonsoir, la capitaine et moi. » — Margot",
			"« Tempête. Trois vagues par-dessus la Pointe. Un apprenti mouillé. Zéro problème. »"])), 7.0), 1.1)
	M.act(R.P(cb.x * 0.7, 0, cb.y * 0.7), "E : actionner la corne de brume", func() -> void:
		M.main.sfx("corne_brume", cbw)
		var tw: Tween = M.room.create_tween()
		tw.tween_property(levier, "rotation:x", -0.9, 0.2)
		tw.tween_interval(1.2)
		tw.tween_property(levier, "rotation:x", 0.0, 0.4)
		if is_instance_valid(app):
			app.gesture("sursaut", 1.2)
			app.say("WAH ! Préviens, la prochaine fois !", 3.0)
		M.say("BOOOOUUUH ! La corne de brume fait trembler les vitres. Dehors, quelque part, un phoque répond.", 5.0), 1.1)
	# l'étage : la lanterne
	_lanterne(M, nuit)
	var bas: Vector3 = _contre(188.0, 2.2)
	M.act(R.P(bas.x, 0, bas.y), "E : monter à la lanterne", func() -> void:
		M.main.sfx("pas_bois")
		M.go(R.P(-1.6, 0.05, 1.2 + UPZ), Vector3(1, 0, -1).normalized()), 1.1)
	M.ctx["entree"] = str(_pick(M, ["Au pied du phare : un escalier qui tourne le long du mur, des bidons d'huile, et le journal du gardien ouvert sur la table.",
		"Le vent siffle dans les vitres, tout en haut. Ici, en bas, ça sent l'huile, le cuivre et le café."]))


## La lanterne du phare (l'étage) : la salle de verre, la grande lentille qui tourne.
static func _lanterne(M, nuit: bool) -> void:
	var R = M.R
	var k = R.kit
	var cw: Vector3 = R.P(0, 0, UPZ)
	var r: float = 3.0
	var seg: int = 16
	k.disc(Transform3D(Basis(), cw), r + 0.3, "sol", seg, 2.0)
	k.col_box(Transform3D(Basis(), cw + Vector3.DOWN * 0.25), Vector3(2.0 * r + 1.0, 0.5, 2.0 * r + 1.0))
	var chord: float = 2.0 * r * sin(PI / seg) + 0.04
	for i in range(seg):
		var am: float = TAU * i / seg
		var dv := Vector3(cos(am), 0, sin(am))
		var xf := Transform3D(Basis.looking_at(-dv, Vector3.UP), cw + dv * (r + 0.05))
		k.box(xf * Transform3D(Basis(), Vector3(0, 0.45, 0)), Vector3(chord, 0.9, 0.12), "mur", 1.6)
		k.box(xf * Transform3D(Basis(), Vector3(0, 1.85, 0)), Vector3(chord - 0.06, 1.9, 0.02), "vitre", 1.0, 16 | 32)
		k.col_box(xf * Transform3D(Basis(), Vector3(0, 1.6, 0)), Vector3(chord, 3.2, 0.2))
		var a2: float = am + PI / seg
		var dv2 := Vector3(cos(a2), 0, sin(a2))
		var mx := Transform3D(Basis.looking_at(-dv2, Vector3.UP), cw + dv2 * (r + 0.05))
		k.box(mx * Transform3D(Basis(), Vector3(0, 1.85, 0)), Vector3(0.06, 1.9, 0.08), "fer", 1.0)
	k.ring(Transform3D(Basis(), cw + Vector3.UP * 2.8), r - 0.05, r + 0.15, 0.12, "fer", 32)
	k.ring(Transform3D(Basis(), cw + Vector3.UP * 0.9), r - 0.1, r + 0.1, 0.05, "fer", 32)
	var tn := Node3D.new()
	M.room.add_child(tn)
	tn.global_position = cw + Vector3.UP * 2.85
	_mesh(tn, _hemi(r + 0.1, (r + 0.1) * 0.7, 24, 8), _m(M, "toit_phare", Color(0.62, 0.2, 0.16), 0.6, 0.4, 0.0, true))
	k.col_box(Transform3D(Basis(), cw + Vector3.UP * 3.4), Vector3(2.0 * r + 1.0, 0.5, 2.0 * r + 1.0))
	# la grande lentille : son socle, ses anneaux de verre, ses quatre yeux, la flamme ; tout ce qui tourne
	k.cyl(Transform3D(Basis(), cw), 0.55, 0.65, 0.95, "fer", 16)
	k.col_cyl(cw, 1.2, 2.6)
	var piv: Node3D = I._node(M, cw + Vector3.UP * 0.95)
	var verre: StandardMaterial3D = _m(M, "lentille", Color(0.82, 0.95, 1.0, 0.45), 0.05, 0.2, 1.6 if nuit else 0.15, true)
	for j in range(7):
		var rb: float = 0.9 if j % 2 == 0 else 0.84
		_mesh(piv, _cylm(rb, rb, 0.2, 24, false), verre, Transform3D(Basis(), Vector3(0, 0.12 + j * 0.21, 0)))
	for s in range(4):
		var a: float = TAU * s / 4.0
		_mesh(piv, _cylm(0.32, 0.32, 0.04, 20), verre, Transform3D(Basis(Vector3.UP, -a) * Basis(Vector3.BACK, PI * 0.5), Vector3(cos(a), 0, sin(a)) * 0.92 + Vector3.UP * 0.75))
	_mesh(piv, I._sph(0.18), _m(M, "flamme_phare", Color(1.0, 0.85, 0.5), 0.2, 0.0, 4.0 if nuit else 0.3), Transform3D(Basis(), Vector3(0, 0.75, 0)))
	_mesh(piv, _cylm(0.95, 0.95, 0.06, 24), _laiton(M), Transform3D(Basis(), Vector3(0, 1.62, 0)))
	_tourne(M, piv, Vector3.UP, 0.55 if nuit else 0.18)
	_lampe(M, cw + Vector3.UP * 1.7, Color(1.0, 0.86, 0.55), 3.5 if nuit else 0.6, 7.0)
	M.act(R.P(-1.7, 0, 0.6 + UPZ), "E : polir la lentille", func() -> void:
		M.main.sfx("verser")
		if not bool(M.state().get("lentille116", false)):
			M.state()["lentille116"] = true
			M.give([["piece", 3]], "Tu frottes la lentille avec un chiffon doux : elle brille comme un sou neuf. L'apprenti te donne trois sous neufs : « Pour la peine ! »" + "\n")
		else:
			M.say("La lentille brille déjà. Tu y vois ton reflet, coupé en sept tranches.", 4.0), 1.1)
	M.act(R.P(1.6, 0, 1.6 + UPZ), "E : regarder la mer", func() -> void:
		if nuit:
			M.say(str(_pick(M, ["La nuit, le faisceau balaie la mer : un bateau de pêche, une bouée, puis plus rien que l'eau noire qui brille.",
				"Tout en bas, Hautefond s'allume étage par étage, et la Colonne brille comme une aiguille d'or."])), 6.0)
		else:
			M.say(str(_pick(M, ["La mer, à perte de vue. Le bateau de ligne trace un trait blanc. Plus loin, les Vergers font des taches vertes.",
				"D'ici, on voit le Port des Cordages, la grue qui tourne, et les mouettes qui volent en dessous de toi."])), 6.0), 1.2)
	M.act(R.P(-2.1, 0, 1.5 + UPZ), "E : redescendre", func() -> void:
		M.main.sfx("pas_bois")
		M.go(R.P(_contre(188.0, 1.9).x, 0.05, _contre(188.0, 1.9).y), Vector3(1, 0, 0)), 1.1)


# =================================================================== le Moulin

static func _moulin(M) -> void:
	var R = M.R
	var k = R.kit
	var mc := Vector3(-0.2, 0, -0.9)
	var nuit: bool = _nuit(M)
	R.rideaux = false
	for deg in [25.0, 155.0, 290.0]:
		_fenetre_ronde(M, Vector3.ZERO, 4.5, 20, deg, 1.7, "plomb")
	R.rideaux = true
	# l'arbre (vertical, du sol au plafond), la grande roue dentée, le rouet et la meule
	var arbre: Node3D = I._node(M, R.P(mc.x, 0, mc.z))
	I._part(arbre, I._cyl(0.2, 0.22, R.H), Color(0.38, 0.26, 0.16), Vector3(0, R.H * 0.5, 0))
	for j in range(4):
		I._part(arbre, I._boxm(Vector3(0.48, 0.06, 0.06)), Color(0.15, 0.15, 0.16), Vector3(0, 0.6 + j * 0.8, 0), Vector3.ONE, Vector3(0, j * 0.7, 0), 0.0, 0.6)
	_tourne(M, arbre, Vector3.UP, 0.45, true)
	k.col_cyl(R.P(mc.x, 0, mc.z), 0.3, R.H)
	var bois_roue: StandardMaterial3D = _m(M, "bois_roue", Color(0.48, 0.32, 0.2), 0.8, 0.0, 0.0, true)
	var roue: Node3D = _roue(M, R.P(mc.x, 2.9, mc.z), Vector3.UP, 1.3, 32, 0.12, bois_roue)
	_tourne(M, roue, Vector3.BACK, 0.45, true)
	var mp := Vector3(mc.x + 1.66, 0, mc.z)
	var rouet: Node3D = _roue(M, R.P(mp.x, 2.9, mp.z), Vector3.UP, 0.38, 10, 0.14, bois_roue)
	_tourne(M, rouet, Vector3.BACK, -0.45 * 1.3 / 0.38, true)
	# la meule : l'estrade, la cuve de bois, la meule du dessus (qui tourne), la trémie, l'auget
	k.box(R.L(mp.x, 0.25, mp.z), Vector3(2.3, 0.5, 2.3), "bois_sombre", 1.0)
	k.col_box(R.L(mp.x, 0.25, mp.z), Vector3(2.3, 0.5, 2.3))
	k.ring(Transform3D(Basis(), R.P(mp.x, 0.5, mp.z)), 0.92, 1.02, 0.5, "bois", 28)
	var meule: Node3D = I._node(M, R.P(mp.x, 0.82, mp.z))
	I._part(meule, I._cyl(0.88, 0.88, 0.22), Color(0.62, 0.6, 0.56), Vector3.ZERO)
	I._part(meule, I._cyl(0.15, 0.15, 0.24), Color(0.3, 0.3, 0.3), Vector3.ZERO)
	I._part(meule, I._boxm(Vector3(1.5, 0.03, 0.05)), Color(0.5, 0.48, 0.45), Vector3(0, 0.115, 0))
	_tourne(M, meule, Vector3.UP, -0.45 * 1.3 / 0.38, true)
	k.cyl(R.L(mp.x, 0.95, mp.z), 0.05, 0.05, 1.95, "fer", 6, false)
	k.cyl(R.L(mp.x + 0.2, 1.45, mp.z), 0.12, 0.55, 0.6, "bois", 4)
	k.disc(Transform3D(Basis(), R.P(mp.x + 0.2, 2.04, mp.z)), 0.5, "pain", 4, 1.0)
	k.box(R.L(mp.x, 0.62, mp.z + 1.1), Vector3(0.22, 0.12, 0.45), "bois", 1.0)
	k.col_box(R.L(mp.x + 0.2, 1.7, mp.z), Vector3(1.1, 0.8, 1.1))
	# la farine qui neige autour de la meule
	var farine: CPUParticles3D = _poussiere(M, R.P(mp.x, 1.6, mp.z), Vector3(1.4, 0.9, 1.4), 70, Color(1, 1, 0.97, 0.7), 0.03)
	# les sacs : de farine (blancs), de blé (bruns), contre le mur
	var sacs_blancs: StandardMaterial3D = _m(M, "farine", Color(0.94, 0.92, 0.86), 0.95)
	var sacs_bruns: StandardMaterial3D = _m(M, "jute", Color(0.6, 0.46, 0.3), 0.95)
	# (une pile de sacs couchés : quatre, puis trois, puis deux)
	var tas := Vector3(-2.9, 0, 1.6)
	var j2: int = 0
	for couche in range(3):
		var n_c: int = 4 - couche
		for i_c in range(n_c):
			var sn := Node3D.new()
			M.room.add_child(sn)
			var sx: float = tas.x + (i_c - (n_c - 1) * 0.5) * 0.5
			var yaw: float = sin(j2 * 2.3) * 0.12 + (PI if j2 % 2 == 1 else 0.0)
			sn.global_transform = Transform3D(Basis(Vector3.UP, yaw), R.P(sx, 0.15 + couche * 0.27, tas.z + sin(j2 * 1.7) * 0.05))
			_sac_couche(sn, sacs_blancs if j2 % 3 != 1 else sacs_bruns, 0.5, 0.32, 0.8)
			j2 += 1
	k.col_box(R.L(tas.x, 0.43, tas.z), Vector3(2.1, 0.86, 0.95))
	var bl: Vector3 = _contre(330.0, 3.9)
	for j3 in range(3):
		var bn := Node3D.new()
		M.room.add_child(bn)
		bn.global_transform = Transform3D(Basis(Vector3.UP, j3), R.P(bl.x + (j3 - 1) * 0.3, 0.33, bl.y + (j3 - 1) * 0.5))
		_sac(bn, sacs_bruns, 0.27, 0.65)
	k.col_box(R.L(bl.x, 0.35, bl.y, bl.z), Vector3(1.6, 0.7, 0.7))
	var ec: Vector3 = _contre(250.0, 4.15)
	R.echelle(ec.x, ec.y, ec.z, R.H)
	k.box(R.L(ec.x * 0.98, R.H - 0.02, ec.y * 0.98), Vector3(0.9, 0.04, 0.9), "noir", 1.0, 8)
	# les gens : le meunier s'il est chez lui ; sinon l'apprenti (qui porte les sacs) et un fermier
	var augustin: Node = _patron(M, 2.4, 2.0, -135, "assis", ["Bonsoir ! Entre, le moulin tourne tout seul, ce soir : le vent connaît le chemin.",
		"Ah, de la visite ! Assieds-toi sur un sac, ils sont plus doux qu'ils n'en ont l'air.", "Bienvenue chez moi ! Ici, tout tourne, sauf moi : moi, je me repose."])
	var app: Node = null
	if augustin != null:
		R.tabouret(2.4, 2.0)
		R.table_ronde(2.95, 1.45, 0.45)
		k.cyl(R.L(2.95, 0.75, 1.45), 0.12, 0.1, 0.06, "pain", 10)
	elif not nuit:
		app = _gens(M, "garcon", 1.1, 0.9, 0, "debout", ["Un sac… deux sacs… trois sacs… mon dos, quatre sacs.", "On ne parle pas trop fort près de la meule : elle chante, il faut l'écouter.",
			"Le blé entre en haut, la farine sort en bas. Et moi, je deviens blanc au milieu."])
		var sac2 := Node3D.new()
		app.npc.add_child(sac2)
		sac2.position = Vector3(0.16, 1.38, -0.04)
		var sac2b := Node3D.new()
		sac2.add_child(sac2b)
		sac2b.transform = Transform3D(Basis(Vector3.BACK, 1.3), Vector3.ZERO)
		_sac(sac2b, sacs_blancs, 0.17, 0.5)
		_va_et_vient(M, app, R.P(1.1, 0.0, 0.5), R.P(-2.3, 0.0, 0.5), 0.9, 2.0, sac2)
		_causer(M, app, ["Salut ! Je suis l'apprenti d'Augustin. Il est dehors, il parle au vent. Ils ont des choses à se dire.",
			"Bonjour ! Fais attention à ta tête : la grande roue ne s'arrête pour personne."],
			[["comment", "Comment ça marche ?", ["Le vent fait tourner les ailes, les ailes font tourner l'arbre, l'arbre fait tourner la grande roue, la grande roue fait tourner la petite, et la petite fait tourner la meule. Et moi, je tourne autour de tout ça.",
				"Le blé tombe de la trémie entre les deux meules. Celle du haut tourne, celle du bas ne bouge pas : entre les deux, le blé devient farine. Comme par magie, mais en plus lourd."]],
			["augustin", "Comment est Augustin ?", ["Il sait de quel côté vient le vent rien qu'en goûtant l'air. Il dit que le vent d'ouest a un goût de pomme.",
				"Il ne dit pas grand-chose, mais il siffle tout le temps. Les ailes tournent en mesure. Je te jure."]]])
		k.cyl(R.L(-2.7, 0, -1.5), 0.25, 0.3, 0.42, "tissu_brun", 10)
		k.col_cyl(R.P(-2.7, 0, -1.5), 0.3, 0.42)
		_gens(M, "homme", -2.7, -1.5, 60, "assis", ["Mon blé, il est beau, hein ? Je l'ai regardé pousser tous les jours.",
			"J'attends ma farine. Ma femme fait une tarte ce soir. Si je rentre sans farine, c'est moi qu'on met au four.",
			"Ça tourne, ça tourne… on se croirait dans la tête d'un horloger."])
	else:
		R.chat(-2.9, 1.5, 120, Color(0.25, 0.22, 0.2), true, 0.84)
		k.cyl(R.L(-1.9, 0, 0.75), 0.25, 0.3, 0.42, "tissu_brun", 10)
		k.col_cyl(R.P(-1.9, 0, 0.75), 0.3, 0.42)
		var dormeur: Node = _gens(M, "garcon", -1.9, 0.75, 150, "dormir_assis", ["Zzz… un sac… deux sacs… zzz…", "Zzz… Monsieur Augustin… le vent tourne… zzz…",
			"Mmh… encore un peu de farine… zzz…"])
		M.talk_spot(dormeur, func() -> void:
			M.talk(dormeur, str(_pick(M, ["Hein ? Quoi ? Je ne dormais pas ! Je… j'écoutais la meule. Elle chante mieux la nuit.",
				"Oh ! Bonsoir… Monsieur Augustin est allé se coucher. Moi, je garde le moulin. Les yeux fermés, mais je le garde."])),
				[{"id": "fermer", "label": "Bonne nuit !"}], func(_i): M.close_talk(), "endormi"))
	_souvent(M, 7.0, 11.0, func() -> void: M.main.sfx("moulin", R.P(mc.x, 2.9, mc.z), -8.0))
	# le frein du moulin : on le lâche, et tout s'emballe un moment
	var lv := Vector3(mc.x - 0.9, 0, mc.z + 0.9)
	k.box(R.L(lv.x, 0.5, lv.z), Vector3(0.12, 1.0, 0.12), "bois_sombre", 1.0)
	k.cyl(Transform3D(Basis(Vector3.BACK, 0.6), R.P(lv.x, 1.0, lv.z)), 0.03, 0.03, 0.7, "fer", 6, false)
	k.col_box(R.L(lv.x, 0.5, lv.z), Vector3(0.2, 1.0, 0.2))
	M.act(R.P(lv.x + 0.55, 0, lv.z + 0.55), "E : lâcher le frein du moulin", func() -> void:
		if float(M.ctx.get("vite116", 1.0)) > 1.5:
			return
		M.ctx["vite116"] = 3.2
		M.main.sfx("rouage", R.P(mc.x, 2.9, mc.z))
		M.main.sfx("bourrasque", R.P(mc.x, 2.9, mc.z))
		if is_instance_valid(farine):
			farine.speed_scale = 3.0
		M.say("Tu lâches le frein : les ailes prennent tout le vent ! L'arbre ronfle, la meule chante plus fort, et il neige de la farine.", 5.0)
		await M.get_tree().create_timer(2.5).timeout
		if not M.inside or not M.ctx.has("anims116"):
			return
		if app != null and is_instance_valid(app):
			M.main.sfx("eternuement", app.npc.global_position)
			app.say("Atchoum ! … Atchoum !", 2.5)
		await M.get_tree().create_timer(5.5).timeout
		if not M.inside or not M.ctx.has("anims116"):
			return
		M.ctx["vite116"] = 1.0
		if is_instance_valid(farine):
			farine.speed_scale = 1.0
		M.main.sfx("levier", R.P(lv.x, 1.0, lv.z))
		if not bool(M.state().get("pain116", false)):
			M.state()["pain116"] = true
			M.give([["pain_miel", 1]], "Le moulin se calme. On te tend un pain de miel tout chaud : « Fait avec la farine d'hier. On ne repart pas d'un moulin les mains vides ! »" + "\n"), 1.1)
	if augustin != null:
		M.ctx["entree"] = "Tu entres chez Augustin Meule, au cœur de son moulin. Il se repose près de la meule, au rythme des ailes."
	elif nuit:
		M.ctx["entree"] = "La nuit, le moulin tourne tout seul, doucement. Un chat dort sur les sacs ; la meule chante pour lui."
	else:
		M.ctx["entree"] = str(_pick(M, ["Dans le moulin, tout tourne : le grand arbre, la roue dentée, la meule qui chante. Il neige de la farine.",
			"Ça sent le blé chaud. La grande roue de bois grince au-dessus de ta tête, comme un vieux bateau.",
			"Les murs tremblent doucement au rythme des ailes. Un apprenti passe, un sac sur l'épaule, blanc des pieds à la tête."]))


# =================================================================== l'abri du jardinier

static func _abri(M) -> void:
	var R = M.R
	var k = R.kit
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	# les outils pendus au mur du fond : un râteau, une bêche, une houe, un sécateur, une scie
	k.box(R.L(-0.2, 1.75, -hd + 0.05), Vector3(4.0, 0.08, 0.06), "bois_sombre", 1.0)
	for j in range(5):
		var x: float = -1.8 + j * 0.8
		k.cyl(R.L(x, 0.3, -hd + 0.09), 0.02, 0.02, 1.5, "bois", 6, false)
		match j:
			0:
				k.box(R.L(x, 1.82, -hd + 0.09), Vector3(0.45, 0.04, 0.05), "fer", 1.0)
				for t in range(6):
					k.box(R.L(x - 0.2 + t * 0.08, 1.88, -hd + 0.09), Vector3(0.012, 0.1, 0.012), "fer", 1.0)
			1:
				k.box(R.L(x, 0.22, -hd + 0.09), Vector3(0.2, 0.28, 0.02), "fer", 1.0)
			2:
				k.box(R.L(x, 1.82, -hd + 0.11), Vector3(0.18, 0.06, 0.12), "fer", 1.0)
			3:
				k.box(R.L(x, 1.2, -hd + 0.09), Vector3(0.08, 0.3, 0.02), "metal", 1.0)
			_:
				k.box(R.L(x, 1.4, -hd + 0.09), Vector3(0.5, 0.12, 0.01), "metal", 1.0)
	R.mark_wall(0, 1.2, -hd, 2.2)
	# les cagettes de pommes et de poires (à droite), la brouette (à gauche), les sachets de graines
	var fruits_r: Array = []
	var fruits_j: Array = []
	for c in range(3):
		var cz: float = -1.4 + c * 0.75
		R.caisse(hw - 0.45, cz, 0.6)
		for a in range(6):
			var fp: Vector3 = R.P(hw - 0.45 + _r(M).randf_range(-0.18, 0.18), 0.64, cz + _r(M).randf_range(-0.18, 0.18))
			if c == 1:
				fruits_j.append(fp)
			else:
				fruits_r.append(fp)
	k.box(R.L(-hw + 0.7, 0.45, 0.4), Vector3(0.6, 0.35, 1.1), "bois", 1.0)
	k.cyl(Transform3D(Basis(Vector3.BACK, PI * 0.5), R.P(-hw + 0.66, 0.2, 1.0)), 0.18, 0.18, 0.08, "fer", 14)
	for s in [-1.0, 1.0]:
		k.box(R.L(-hw + 0.7 + s * 0.22, 0.4, -0.35), Vector3(0.04, 0.04, 0.6), "bois_sombre", 1.0)
	k.col_box(R.L(-hw + 0.7, 0.4, 0.4), Vector3(0.7, 0.8, 1.4))
	R.etagere_murale(-hw + 0.05, 1.5, -1.55, 90, 1.2, "papier", 6)
	# l'arrosoir, les pots de terre empilés, un sac de graines ouvert
	var ar: Vector3 = R.P(hw - 0.6, 0, hd - 1.3)
	k.cyl(Transform3D(Basis(), ar), 0.14, 0.12, 0.3, "metal", 12)
	k.cyl(Transform3D(Basis(Vector3.BACK, -0.9), ar + Vector3(0.08, 0.12, 0)), 0.015, 0.025, 0.36, "metal", 6)
	k.box(Transform3D(Basis(), ar + Vector3(-0.0, 0.36, 0)), Vector3(0.02, 0.1, 0.18), "metal", 1.0)
	for q in range(4):
		k.cyl(R.L(hw - 0.55, 0.0 + q * 0.12, hd - 0.75), 0.12, 0.16, 0.16, "terre_cuite", 10, false)
	k.cyl(R.L(hw - 1.3, 0, hd - 0.6), 0.22, 0.26, 0.45, "tissu_creme", 10)
	k.cyl(R.L(hw - 1.3, 0.45, hd - 0.6), 0.2, 0.2, 0.02, "terreau", 10)
	# la table de tri, ses deux paniers : « pour le marché », « pour la compote »
	R.table(0, -1.1, 0, 1.8, 0.8)
	for b in [-0.6, 0.6]:
		k.cyl(R.L(b, 0.76, -1.1), 0.17, 0.2, 0.2, "bois_clair", 12)
	for a2 in range(8):
		fruits_r.append(R.P(_r(M).randf_range(-0.3, 0.3), 0.82, -1.1 + _r(M).randf_range(-0.25, 0.25)))
	_fruits(M, fruits_r, Color(0.75, 0.12, 0.1), 0.065)
	_fruits(M, fruits_j, Color(0.78, 0.8, 0.3), 0.06)
	k.cyl(R.L(-hw + 1.4, 0, -hd + 0.7), 0.28, 0.3, 0.3, "tissu_brun", 10)
	R.chat(-hw + 1.4, -hd + 0.7, 30, Color(0.85, 0.55, 0.25), true, 0.3)
	_souvent(M, 10.0, 18.0, func() -> void: M.main.sfx("ronron", R.P(-hw + 1.4, 0.4, -hd + 0.7), -10.0))
	# l'aide du jardinier
	var aide: Node = _gens(M, "femme", 0.0, -1.75, 0, "bricoler", ["Une pour le marché… une pour la compote… une pour moi.", "Le Père Bastien dit qu'une pomme, ça se trie avec le nez.",
		"Celle-ci a un ver. Il a l'air content. On la lui laisse."])
	M.talk_spot(aide, func() -> void:
		var choices: Array = [{"id": "trier", "label": "Je peux t'aider à trier ?"}, {"id": "bastien", "label": "Où est le Père Bastien ?"}, {"id": "fermer", "label": "Au revoir !"}]
		M.talk(aide, str(_pick(M, ["Bonjour ! On trie la récolte du jour : les belles pour le marché, les cabossées pour la compote. Rien ne se perd !",
			"Ah, de l'aide ? Il y a trois cagettes à trier, et le chat ne m'aide pas du tout."])), choices, func(id):
			if str(id) == "trier":
				_tri(M, aide, 0)
			elif str(id) == "bastien":
				M.talk(aide, "Il taille les pommiers, là-haut, sur la troisième terrasse. Il leur parle. Il dit que ça les fait pousser droit.", [{"id": "fermer", "label": "Merci !"}], func(_i): M.close_talk())
			else:
				M.close_talk()))
	M.ctx["entree"] = str(_pick(M, ["L'abri du jardinier : des outils pendus aux planches, des cagettes de pommes qui sentent bon, et un chat qui dort sur un sac de graines.",
		"Ça sent la pomme, la terre et le bois mouillé. On trie la récolte du jour."]))


## Trier les pommes avec l'aide du jardinier (trois pommes, deux paniers).
static func _tri(M, aide: Node, n: int) -> void:
	if n >= 3:
		if not bool(M.state().get("pommes116", false)):
			M.state()["pommes116"] = true
			M.talk(aide, "Bravo, tu as l'œil ! Tiens, prends-en trois : ce sont les meilleures. Le Père Bastien dirait que tu as un nez de jardinier.", [{"id": "fermer", "label": "Merci beaucoup !"}], func(_i):
				M.give([["pomme", 3]], "")
				M.close_talk())
		else:
			M.talk(aide, "Encore merci ! À ce rythme-là, on aura fini avant le goûter.", [{"id": "fermer", "label": "Avec plaisir !"}], func(_i): M.close_talk())
		return
	var pommes: Array = ["Celle-ci a une petite tache, mais elle sent bon. Pour le marché, ou pour la compote ?",
		"Celle-là est parfaite, toute rouge, toute ronde. Pour le marché, ou pour la compote ?",
		"Celle-ci a un ver qui te dit bonjour. Pour le marché, ou pour la compote ?",
		"Celle-là est cabossée d'un côté, mais sucrée comme un bonbon. Pour le marché, ou pour la compote ?"]
	var p: String = str(pommes[(n + _r(M).randi()) % pommes.size()])
	M.talk(aide, p, [{"id": "marche", "label": "Pour le marché !"}, {"id": "compote", "label": "Pour la compote !"}], func(_id):
		M.main.sfx("ramasse")
		var rep: String = str(_pick(M, ["Bien vu.", "D'accord !", "Si tu le dis… Oui, tu as raison.", "Hop, dans le panier !"]))
		M.talk(aide, rep, [{"id": "suite", "label": "La suivante !"}], func(_i): _tri(M, aide, n + 1)))


## Des fruits (de petites boules), d'un seul maillage multiple.
static func _fruits(M, pts: Array, c: Color, r: float) -> void:
	if pts.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	sm.radial_segments = 10
	sm.rings = 6
	mm.mesh = sm
	mm.instance_count = pts.size()
	for i in range(pts.size()):
		mm.set_instance_transform(i, Transform3D(Basis(), pts[i]))
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.material_override = _m(M, "fruit_%d_%d" % [int(c.r * 100.0), int(c.g * 100.0)], c, 0.45)
	M.room.add_child(mi)


# =================================================================== l'Albatros

static func _albatros(M) -> void:
	var R = M.R
	var k = R.kit
	var hw: float = R.W * 0.5
	var nuit: bool = _nuit(M)
	# les hublots, tout le long des deux flancs (on voit le ciel)
	for z in [-4.4, -2.4, -0.4, 1.6, 3.6]:
		R.window(R.L(-hw + 0.02, 1.45, z, 90), "hublot")
		R.window(R.L(hw - 0.02, 1.45, z, -90), "hublot")
	# les porte-bagages, au-dessus
	for s in [-1.0, 1.0]:
		k.box(R.L(s * (hw - 0.25), 2.3, -0.4), Vector3(0.45, 0.05, 9.5), "bois_sombre", 1.0)
		for j in range(6):
			k.box(R.L(s * (hw - 0.25), 2.395, -4.0 + j * 1.5), Vector3(0.36, 0.14, 0.5), ["tissu_rouge", "cuir", "tissu_vert", "cuir", "tissu_bleu", "carton"][j], 1.0)
	# les fauteuils face aux hublots, le tapis de l'allée
	for z2 in [-2.4, -0.4, 1.6]:
		R.fauteuil(-hw + 0.75, z2, -90, "vert")
		R.fauteuil(hw - 0.75, z2, 90, "vert")
	k.box(R.L(0, 0.006, -0.4), Vector3(1.1, 0.012, 10.0), "tapis_0", 2.0, 4)
	# la passerelle de commandement (à l'avant) : la rambarde, la barre, les instruments, le porte-voix
	for seg2 in [[-1.35, 1.5], [1.35, 1.5]]:
		k.box(R.L(float(seg2[0]), 1.0, -4.85), Vector3(float(seg2[1]), 0.05, 0.05), "or", 1.0)
	for x in [-2.05, -0.62, 0.62, 2.05]:
		k.cyl(R.L(x, 0, -4.85), 0.025, 0.025, 1.0, "or", 6, false)
	k.cyl(R.L(0, 0, -5.7), 0.12, 0.14, 1.0, "bois_sombre", 10)
	var barre: Node3D = I._node(M, R.P(0, 1.18, -5.55))
	_mesh(barre, _tore(0.38, 0.44), _m(M, "barre", Color(0.45, 0.28, 0.16), 0.6), Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO))
	I._part(barre, I._cyl(0.07, 0.07, 0.1), Color(0.75, 0.58, 0.28), Vector3.ZERO, Vector3.ONE, Vector3(PI * 0.5, 0, 0), 0.0, 0.5)
	for sp in range(8):
		var a: float = TAU * sp / 8.0
		I._part(barre, I._cyl(0.018, 0.012, 0.6), Color(0.5, 0.32, 0.18), Vector3(cos(a), sin(a), 0) * 0.3, Vector3.ONE, Vector3(0, 0, a - PI * 0.5))
	k.box(R.L(-1.4, 0.5, -6.3), Vector3(1.2, 1.0, 0.35), "bois_sombre", 1.0)
	for d in range(3):
		k.cyl(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), R.P(-1.75 + d * 0.35, 0.8, -6.125)), 0.11, 0.11, 0.02, "ceramique", 16, true)
		k.ring(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), R.P(-1.75 + d * 0.35, 0.8, -6.125)), 0.11, 0.13, 0.035, "or", 16)
	k.col_box(R.L(-1.4, 0.5, -6.3), Vector3(1.2, 1.0, 0.35))
	k.cyl(R.L(1.6, 0, -6.3), 0.04, 0.04, 1.9, "or", 8, false)
	k.cyl(Transform3D(Basis(Vector3.RIGHT, 0.9), R.P(1.6, 1.75, -6.3)), 0.05, 0.1, 0.2, "or", 10)
	for sx in [-0.95, 0.95]:
		R.window(R.L(sx, 1.75, -R.D * 0.5 + 0.02, 0), "hublot")
	_lampe(M, R.P(0, 2.1, -5.6), Color(1.0, 0.86, 0.62), 0.8, 4.5)
	R.table(1.35, -3.9, 90, 1.0, 0.7)
	k.box(R.L(1.35, 0.763, -3.9, 90), Vector3(0.9, 0.006, 0.6), "tableau_3", 0.9, 4)
	# les lampes suspendues qui se balancent doucement
	for z3 in [-3.0, 0.0, 3.0]:
		var lp: Node3D = I._node(M, R.P(0, R.H - 0.05, z3))
		I._part(lp, I._cyl(0.006, 0.006, 0.45), Color(0.2, 0.2, 0.2), Vector3(0, -0.22, 0))
		I._part(lp, I._sph(0.12), Color(1.0, 0.88, 0.6), Vector3(0, -0.52, 0), Vector3.ONE, Vector3.ZERO, 2.0 if nuit else 0.8)
		_balance(M, lp, Vector3.RIGHT, 0.06, 4.2, z3)
		_lampe(M, R.P(0, R.H - 0.7, z3), Color(1.0, 0.86, 0.62), 0.9 if nuit else 0.5, 4.5)
	# les gens : le timonier à la barre, des passagers aux hublots, le steward qui passe avec son plateau
	var timonier: Node = _gens(M, "homme", 0.6, -5.3, -100, "debout", ["Cap au nord ! … On est amarrés, mais je m'entraîne.",
		"Altitude : vingt-six mètres. Le mât compte, je suppose.", "La Capitaine Nimbus veut que la barre brille. Elle brille. Elle se voit dedans."])
	timonier.follow = false
	_causer(M, timonier, ["Bienvenue sur la passerelle ! Je suis le timonier de l'Albatros. La Capitaine Nimbus est en bas, au kiosque : elle choisit elle-même ses passagers.",
		"Ah, un passager ! Ne touche pas au porte-voix, il est relié à la cuisine : la dernière fois, on a commandé quarante crêpes."],
		[["voler", "Quand est-ce qu'on vole ?", ["Dès que le vent est d'accord. La Capitaine dit que le vent, c'est comme un chat : il vient quand il veut, mais il vient toujours.",
			"Quand la Capitaine le dira. Elle sent le vent mieux que les girouettes. Les girouettes lui demandent conseil."]],
		["capitaine", "Comment est la Capitaine ?", ["Héloïse Nimbus ? Elle a fait le tour des nuages trois fois. La quatrième, les nuages lui ont fait une place.",
			"Elle ne crie jamais. Elle lève un sourcil, et tout l'équipage court. Même le chat du bord."]]])
	var pas_lignes: Array = ["Regarde, on voit la Colonne !", "J'ai le vertige… mais seulement du côté gauche.", "Le chocolat d'altitude, il est meilleur, non ?", "Tout est si petit, en bas. Même les gens importants."]
	# (la nuit, un seul passager lit encore ; les autres sont rentrés dormir)
	_gens(M, "vieux", hw - 0.75, -0.4, 90, "lire", pas_lignes)
	if not nuit:
		_gens(M, "femme", -hw + 0.75, -2.4, -90, "assis", pas_lignes)
		_gens(M, "homme", -hw + 0.75, 1.6, -90, "assis", pas_lignes)
		var enfant: Node = _gens(M, "fille", hw - 0.55, 3.6, 90, "observer", ["On est haut ! On est hauuut !", "Je vois ma maison ! Non, c'est la mairie.", "Maman, on peut rester ici pour toujours ?"])
		enfant.follow = false
	var steward: Node = _gens(M, "homme", 0, 3.2, 180, "debout", ["Chocolat ? Thé ? Nuage de lait ?", "Pardon, pardon… attention, plateau chaud !", "Le service est compris. La vue aussi."])
	var plateau := Node3D.new()
	steward.npc.add_child(plateau)
	plateau.position = Vector3(0.0, 1.05, 0.35)
	_mesh(plateau, _cylm(0.18, 0.18, 0.03, 20), _m(M, "plateau", Color(0.85, 0.86, 0.88), 0.25, 0.9))
	for t in range(2):
		_mesh(plateau, _cylm(0.035, 0.03, 0.07, 10), _m(M, "tasse", Color(0.96, 0.95, 0.92), 0.3), Transform3D(Basis(), Vector3(-0.08 + t * 0.16, 0.05, 0)))
	_va_et_vient(M, steward, R.P(0, 0, 3.6), R.P(0, 0, -3.6), 0.75, 3.0, plateau)
	var it_st: Dictionary = M.talk_spot(steward, func() -> void:
		M.talk(steward, str(_pick(M, ["Bienvenue à bord de l'Albatros ! Aujourd'hui, nous sommes amarrés. Mais on peut faire semblant. Un chocolat d'altitude ?",
			"Bonjour ! Le chocolat d'altitude, c'est le même qu'en bas, mais servi plus haut. Ça change tout."])),
			[{"id": "choco", "label": "Oui, un chocolat, s'il te plaît !"}, {"id": "fermer", "label": "Non merci, je regarde la vue."}], func(id):
			if str(id) == "choco":
				if not bool(M.state().get("choco116", false)):
					M.state()["choco116"] = true
					M.main.sfx("verser", steward.npc.global_position)
					M.talk(steward, "Voilà ! Avec de la mousse en forme de nuage. Si tu le bois vite, tu as une moustache de nuage. C'est la tradition.", [{"id": "fermer", "label": "Merci !"}], func(_i):
						M.give([["chocolat_chaud", 1]], "")
						M.close_talk())
				else:
					M.talk(steward, "Encore un ? Tu vas finir par flotter ! Reviens au prochain vol : on fera des crêpes. Quarante, d'après le porte-voix.", [{"id": "fermer", "label": "Ha ha, d'accord !"}], func(_i): M.close_talk())
			else:
				M.close_talk()))
	steward.set_meta("it116", it_st)
	M.act(R.P(-0.55, 0, -5.1), "E : prendre la barre", func() -> void:
		M.main.sfx("aeronef_moteur", R.P(0, 1.2, -5.5))
		var tw: Tween = M.room.create_tween()
		tw.tween_property(barre, "rotation:z", 0.9, 0.6).set_trans(Tween.TRANS_SINE)
		tw.tween_property(barre, "rotation:z", -0.6, 0.8).set_trans(Tween.TRANS_SINE)
		tw.tween_property(barre, "rotation:z", 0.0, 0.6).set_trans(Tween.TRANS_SINE)
		M.say(str(_pick(M, ["Tu fais tourner la barre. L'Albatros ne bouge pas d'un pouce : il est amarré. Le timonier rit : « On ne vole pas aujourd'hui ! On répète. »",
			"Tu tiens la barre à deux mains. Quelque part, très loin, une hélice tousse. Le timonier applaudit : « Un vrai capitaine ! »"])), 6.0)
		if is_instance_valid(timonier):
			timonier.gesture("applaudir", 2.0), 0.9)
	for wz in [-4.4, 3.6]:
		var sx: float = -1.0 if wz < 0.0 else 1.0
		M.act(R.P(sx * (hw - 0.85), 0, wz), "E : regarder par le hublot", func() -> void:
			if nuit:
				M.say(str(_pick(M, ["La nuit, Hautefond brille tout en bas, étage par étage ; la Colonne est une aiguille d'or plantée dans l'île.",
					"Des lumières partout en dessous : les rues, le port, le phare qui tourne. Et au-dessus, les étoiles, si près."])), 6.0)
			else:
				M.say(str(_pick(M, ["Hautefond, tout en bas : les toits d'ardoise bleue, le Grand Marché et ses toiles de couleur, la Colonne qui brille.",
					"La mer, les Vergers en terrasses, le moulin qui tourne. Et au-dessus de tout, la Cité des Nuées qui flotte.",
					"Une mouette passe juste devant le hublot. Elle te regarde, l'air de dire : « Toi aussi, tu voles ? »"])), 6.0), 1.0)
	_souvent(M, 7.0, 12.0, func() -> void: M.main.sfx("pas_bois", R.P(0, 1.0, _r(M).randf_range(-4.0, 4.0)), -14.0))
	M.ctx["entree"] = str(_pick(M, ["Tu montes à bord de l'Albatros : une longue nacelle de bois verni, des fauteuils face aux hublots, et la barre tout au bout.",
		"Dans la nacelle, ça grince doucement, comme un bateau qui rêve de nuages. Les passagers ont le nez collé aux hublots.",
		"À bord de l'Albatros ! Ça sent le bois ciré et le chocolat chaud. Le steward passe avec son plateau ; à l'avant, le timonier astique la barre."]))
