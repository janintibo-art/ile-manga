extends Node3D
## V76 : l'Atelier des Ailes, à Cliquetis — Philibert Vis, « l'inventeur sans invention », a
## enfin trouvé son idée : faire voler les Pieds-Lourds. Un hangar de brique et de fer à
## voûte de verre, sur une terrasse en bastion au bord ouest de la cité, une aire d'envol en
## planches qui s'avance au-dessus de la falaise (pour l'Alouette), une manche à air.
## On y achète les évolutions 1 → 3 de l'aéronef (aeronef_v76.gd) : à l'établi (E) ou en
## parlant à Philibert (service du carnet). La 4 (le Glisseur stellaire) se fait au Spatioport
## d'Astralys, chez Ionie : unlock_glisseur(), ou le service glisseur_topics / glisseur_choose.
## Repère « cité » de Cliquetis : monde = (960 + x, y, -315 + z), la terrasse de la cité à y = 30.

const R = preload("res://scripts/cliquetis_relief_v61.gd")
const Kit = preload("res://scripts/cliquetis_kit_v61.gd")
const Y: float = 30.0
## La terrasse de l'Atelier (repère cité) et le hangar.
const TERRACE := Rect2(-124.0, -40.0, 24.0, 34.0)
const HANGAR := Rect2(-121.0, -29.0, 16.0, 14.0)      # ouverture côté nord (z = -29)
const HANGAR_H: float = 6.2
const RAMP_X0: float = -115.0
const RAMP_X1: float = -110.0
const RAMP_Z1: float = -53.0                            # le bout de la piste, au-dessus du vide
const RAMP_DROP: float = 0.9
const QUEST := "ailes_philibert"
const BUILDER := "philibert"
## Les évolutions : ce que coûte chacune (pièces + matériaux).
const COSTS := {
	1: {"piece": 60, "toile_voile": 3, "buche": 4, "boulon": 2},
	2: {"piece": 120, "engrenage": 2, "ressort": 2, "toile_voile": 1, "boulon": 3},
	3: {"piece": 300, "toile_voile": 6, "engrenage": 4, "ressort": 3, "boulon": 6, "buche": 6, "fragment_meteorite": 1},
	4: {"piece": 200, "cristal_astral": 3, "fragment_meteorite": 2},
}
const SELL := {"toile_voile": 15, "engrenage": 20}
const SELL_MATERIALS: bool = true

var main: Node
var aeronef: Node3D
var kit
var points: Dictionary = {}
var state := {"visite": false, "achats": 0}
var _speaker: Node3D
var _sock: Node3D
var _clock: float = 0.0
var _flag_t: float = 0.0


func setup(main_node: Node, aeronef_node: Node3D) -> void:
	main = main_node
	aeronef = aeronef_node
	name = "Atelier_des_Ailes_v76"


func T(x: float, z: float, dy: float = 0.0) -> Vector3:
	return R.to_world(x, z, Y + dy)


func _ile() -> Node:
	var g: Node = main.get("grande_v59")
	return g.ile if g != null and g.get("ile") != null else null


func _ground(x: float, z: float) -> float:
	var w: Vector3 = R.to_world(x, z)
	var il: Node = _ile()
	return float(il.height(w.x, w.z)) if il != null else float(main._height_at(w.x, w.z))


func build() -> void:
	var t0: int = Time.get_ticks_msec()
	kit = Kit.new()
	kit.setup(self, main.get("temps_v56"))
	kit.rng.seed = 7610
	_terrace()
	_hangar()
	_ramp()
	_props()
	kit.commit()
	_windsock()
	_display()
	_paths()
	print("ILE_MANGA_V76: Atelier des Ailes (", T(-113.0, -22.0), ") en ", Time.get_ticks_msec() - t0, " ms")


# =================================================================== la terrasse en bastion

func _terrace() -> void:
	var r: Rect2 = TERRACE
	# le dallage (comme les rues de la cité)
	var step: float = 4.0
	var x: float = r.position.x
	while x < r.end.x - 0.01:
		var z: float = r.position.y
		while z < r.end.y - 0.01:
			var x1: float = minf(x + step, r.end.x)
			var z1: float = minf(z + step, r.end.y)
			kit.quad4("paves_cq", T(x, z, 0.03), T(x1, z, 0.03), T(x1, z1, 0.03), T(x, z1, 0.03), Vector3.UP,
				Vector2(x, z) * 0.28, Vector2(x1, z) * 0.28, Vector2(x1, z1) * 0.28, Vector2(x, z1) * 0.28)
			z = z1
		x += step
	# la dalle porteuse (collision), sous le dallage
	kit.col_box(Transform3D(Basis(), T(r.get_center().x, r.get_center().y, -0.5)), Vector3(r.size.x, 1.0, r.size.y))
	# les murs du bastion : brique, contreforts, corniche de pierre — ouest, nord, sud
	var sides: Array = [
		[Vector2(r.position.x, r.position.y), Vector2(r.position.x, r.end.y), Vector2(-1, 0)],
		[Vector2(r.position.x, r.position.y), Vector2(r.end.x, r.position.y), Vector2(0, -1)],
		[Vector2(r.position.x, r.end.y), Vector2(r.end.x, r.end.y), Vector2(0, 1)],
	]
	for sd in sides:
		var a: Vector2 = sd[0]
		var b: Vector2 = sd[1]
		var out: Vector2 = sd[2]
		var L: float = a.distance_to(b)
		var n: int = int(ceil(L / 4.0))
		for i in range(n):
			var p0: Vector2 = a.lerp(b, float(i) / n)
			var p1: Vector2 = a.lerp(b, float(i + 1) / n)
			var c: Vector2 = (p0 + p1) * 0.5 + out * 0.6
			var base: float = Y - 1.0
			for q in [p0, c, p1, p0 + out * 1.2, p1 + out * 1.2]:
				base = minf(base, _ground((q as Vector2).x, (q as Vector2).y) - 1.4)
			if Y - base < 0.8:
				continue
			var hh: float = Y + 0.05 - base
			var seg_len: float = p0.distance_to(p1) + 0.02
			var size := Vector3(seg_len if out.x == 0.0 else 1.2, hh, 1.2 if out.x == 0.0 else seg_len)
			var xf := Transform3D(Basis(), R.to_world(c.x, c.y, base + hh * 0.5))
			kit.box(xf, size, "brique", 2.5, 63 - 4)
			kit.col_box(xf, size)
			# la corniche de pierre
			kit.box(Transform3D(Basis(), R.to_world(c.x + out.x * 0.15, c.y + out.y * 0.15, Y + 0.12)), Vector3(size.x + (0.0 if out.x == 0.0 else 0.4), 0.3, size.z + (0.4 if out.x == 0.0 else 0.0)), "pierre", 1.5)
			# un contrefort tous les 8 m, s'il y a de la hauteur
			if i % 2 == 0 and hh > 6.0:
				var bc: Vector2 = p0.lerp(p1, 0.5) + out * 1.6
				var gb: float = _ground(bc.x, bc.y) - 1.0
				var h2: float = Y - 1.5 - gb
				if h2 > 3.0:
					kit.box(Transform3D(Basis(), R.to_world(bc.x, bc.y, gb + h2 * 0.5)), Vector3(2.0 if out.x == 0.0 else 2.2, h2, 2.2 if out.x == 0.0 else 2.0), "brique_sombre", 2.5)
					kit.box(Transform3D(Basis(Vector3.RIGHT if out.x == 0.0 else Vector3.BACK, -0.55 * (out.y if out.x == 0.0 else -out.x)), R.to_world(bc.x - out.x * 0.4, bc.y - out.y * 0.4, Y - 1.3)), Vector3(2.0 if out.x == 0.0 else 2.6, 0.4, 2.6 if out.x == 0.0 else 2.0), "pierre", 1.5)
	# les garde-corps : au nord (de part et d'autre de la piste), à l'ouest, au sud
	kit.iron_rail(T(r.position.x + 0.4, r.position.y + 0.5), T(RAMP_X0 - 0.3, r.position.y + 0.5))
	kit.iron_rail(T(RAMP_X1 + 0.3, r.position.y + 0.5), T(r.end.x - 0.6, r.position.y + 0.5))
	kit.iron_rail(T(r.position.x + 0.5, r.position.y + 0.4), T(r.position.x + 0.5, r.end.y - 0.4))
	kit.iron_rail(T(r.position.x + 0.4, r.end.y - 0.5), T(r.end.x - 0.6, r.end.y - 0.5))
	# deux réverbères à globe devant le hangar
	for lx in [HANGAR.position.x - 1.2, HANGAR.end.x + 1.2]:
		kit.globe_lamp(T(lx, HANGAR.position.y - 1.5))


# =================================================================== le hangar

func _hangar() -> void:
	var h: Rect2 = HANGAR
	var x0: float = h.position.x
	var x1: float = h.end.x
	var z0: float = h.position.y           # l'ouverture (nord)
	var z1: float = h.end.y                # le mur du fond (sud)
	var cx: float = (x0 + x1) * 0.5
	var w: float = x1 - x0
	var d: float = z1 - z0
	var hh: float = HANGAR_H
	var t: float = 0.5
	# le plancher de bois
	kit.quad4("planches", T(x0 + t, z0, 0.06), T(x1 - t, z0, 0.06), T(x1 - t, z1 - t, 0.06), T(x0 + t, z1 - t, 0.06), Vector3.UP,
		Vector2(0, 0), Vector2(w / 2.0, 0), Vector2(w / 2.0, d / 2.0), Vector2(0, d / 2.0))
	# le mur du fond et les murs de côté (brique), un socle de pierre
	var back := Transform3D(Basis(), T(cx, z1 - t * 0.5, hh * 0.5))
	kit.box(back, Vector3(w, hh, t), "brique", 3.0)
	kit.col_box(back, Vector3(w, hh, t))
	for sx in [x0 + t * 0.5, x1 - t * 0.5]:
		var side := Transform3D(Basis(), T(sx, (z0 + z1) * 0.5, hh * 0.5))
		kit.box(side, Vector3(t, hh, d), "brique", 3.0)
		kit.col_box(side, Vector3(t, hh, d))
		kit.box(Transform3D(Basis(), T(sx, (z0 + z1) * 0.5, 0.35)), Vector3(t + 0.14, 0.7, d + 0.1), "pierre", 1.5, 63 - 12)
		# des baies cintrées sur les côtés (vers l'extérieur)
		var out: float = -1.0 if sx < cx else 1.0
		for k in range(3):
			var wz: float = z0 + 2.5 + k * (d - 5.0) / 2.0
			var wxf := Transform3D(Basis(Vector3.UP, -out * PI * 0.5), T(sx + out * (t * 0.5 + 0.01), wz, 1.4))
			kit.shop_window(wxf, 1.6, 2.2, true)
	kit.box(Transform3D(Basis(), T(cx, z1 - t * 0.5, 0.35)), Vector3(w + 0.1, 0.7, t + 0.14), "pierre", 1.5, 63 - 12)
	# la corniche
	kit.box(Transform3D(Basis(), T(cx, (z0 + z1) * 0.5, hh)), Vector3(w + 0.3, 0.28, d + 0.3), "pierre", 1.5, 63 - 4 - 8)
	# la voûte : un berceau de verre et de cuivre sur des arcs de fer
	var rise: float = 3.2
	var nseg: int = 12
	var half: float = w * 0.5
	var arc: Array = []
	for i in range(nseg + 1):
		var a: float = PI * float(i) / nseg
		arc.append(Vector2(cos(a) * half, sin(a) * rise))
	for i in range(nseg):
		var a0: Vector2 = arc[i]
		var a1: Vector2 = arc[i + 1]
		var key: String = "verriere" if i in [3, 4, 7, 8] else "cuivre_sombre"
		var nrm: Vector3 = Vector3((a0.x + a1.x) * 0.5 / half, (a0.y + a1.y) * 0.5 / rise, 0).normalized()
		var L: float = a0.distance_to(a1)
		kit.quad4(key, T(cx + a0.x, z0 - 0.3, hh + 0.14 + a0.y), T(cx + a1.x, z0 - 0.3, hh + 0.14 + a1.y), T(cx + a1.x, z1 + 0.3, hh + 0.14 + a1.y), T(cx + a0.x, z1 + 0.3, hh + 0.14 + a0.y), nrm,
			Vector2(0, 0), Vector2(L / 1.5, 0), Vector2(L / 1.5, (d + 0.6) / 1.5), Vector2(0, (d + 0.6) / 1.5))
		if key != "verriere":
			# le dessous (vu de l'intérieur)
			kit.quad4("bois_sombre", T(cx + a0.x, z1 + 0.3, hh + 0.1 + a0.y), T(cx + a1.x, z1 + 0.3, hh + 0.1 + a1.y), T(cx + a1.x, z0 - 0.3, hh + 0.1 + a1.y), T(cx + a0.x, z0 - 0.3, hh + 0.1 + a0.y), -nrm,
				Vector2(0, 0), Vector2(L / 1.5, 0), Vector2(L / 1.5, (d + 0.6) / 1.5), Vector2(0, (d + 0.6) / 1.5))
	# les arcs de fer (et les tirants), tous les 3,5 m
	var nz: int = 5
	for k2 in range(nz):
		var zz: float = z0 + 0.1 + k2 * (d - 0.2) / (nz - 1)
		for i2 in range(nseg):
			var b0: Vector2 = arc[i2]
			var b1: Vector2 = arc[i2 + 1]
			var m: Vector2 = (b0 + b1) * 0.5
			var ang: float = atan2(b1.y - b0.y, b1.x - b0.x)
			kit.box(Transform3D(Basis(Vector3.BACK, ang), T(cx + m.x, zz, hh + 0.05 + m.y)), Vector3(b0.distance_to(b1) + 0.05, 0.22, 0.16), "fer_noir", 1.0)
		kit.box(Transform3D(Basis(), T(cx, zz, hh - 0.1)), Vector3(w - 0.2, 0.08, 0.08), "fer_noir", 1.0)
	# le pignon arrière, fermé (brique), et le pignon de l'ouverture : une grande lunette vitrée
	for i3 in range(nseg):
		var c0: Vector2 = arc[i3]
		var c1: Vector2 = arc[i3 + 1]
		kit.tri("brique", T(cx, z1 - 0.05, hh + 0.14), T(cx + c0.x, z1 - 0.05, hh + 0.14 + c0.y), T(cx + c1.x, z1 - 0.05, hh + 0.14 + c1.y), Vector3(0, 0, -1),
			Vector2(0, 0), Vector2(c0.x / 2.5, c0.y / 2.5), Vector2(c1.x / 2.5, c1.y / 2.5))
		kit.tri("brique", T(cx, z1 + 0.05, hh + 0.14), T(cx + c1.x, z1 + 0.05, hh + 0.14 + c1.y), T(cx + c0.x, z1 + 0.05, hh + 0.14 + c0.y), Vector3(0, 0, 1),
			Vector2(0, 0), Vector2(c1.x / 2.5, c1.y / 2.5), Vector2(c0.x / 2.5, c0.y / 2.5))
		kit.tri("verriere", T(cx, z0 + 0.05, hh + 0.14), T(cx + c1.x, z0 + 0.05, hh + 0.14 + c1.y), T(cx + c0.x, z0 + 0.05, hh + 0.14 + c0.y), Vector3(0, 0, -1),
			Vector2(0.5, 1), Vector2(0.5 + c1.x / w, 1 - c1.y / rise), Vector2(0.5 + c0.x / w, 1 - c0.y / rise))
	# les rayons de fer de la lunette
	for k3 in range(1, 6):
		var a3: float = PI * k3 / 6.0
		var tip := Vector2(cos(a3) * half, sin(a3) * rise)
		var mid: Vector2 = tip * 0.5
		kit.box(Transform3D(Basis(Vector3.BACK, atan2(tip.y, tip.x)), T(cx + mid.x, z0 - 0.02, hh + 0.14 + mid.y)), Vector3(tip.length(), 0.08, 0.08), "fer_noir", 1.0)
	# le linteau de fer riveté de la grande ouverture, et les deux portes coulissantes, ouvertes
	kit.box(Transform3D(Basis(), T(cx, z0 - 0.1, hh - 0.25)), Vector3(w + 0.2, 0.5, 0.3), "fer_noir", 1.0)
	kit.box(Transform3D(Basis(), T(cx, z0 - 0.3, hh + 0.05)), Vector3(w + 0.6, 0.12, 0.12), "laiton", 1.0)
	for s in [-1.0, 1.0]:
		var door_c := T(cx + s * (half + 2.2), z0 - 0.45, 2.7)
		kit.box(Transform3D(Basis(), door_c), Vector3(4.6, 5.4, 0.16), "planches", 1.4)
		for yy in [0.6, 2.7, 4.8]:
			kit.box(Transform3D(Basis(), door_c + Vector3(0, yy - 2.7, -0.1)), Vector3(4.6, 0.14, 0.06), "fer_noir", 1.0)
		kit.box(Transform3D(Basis(Vector3.BACK, s * 0.9), door_c + Vector3(0, 0, -0.1)), Vector3(0.12, 6.4, 0.06), "fer_noir", 1.0)
		kit.col_box(Transform3D(Basis(), door_c), Vector3(4.6, 5.4, 0.3))
	# le rail des portes
	kit.box(Transform3D(Basis(), T(cx, z0 - 0.45, 5.5)), Vector3(w + 9.6, 0.12, 0.2), "fer_noir", 1.0)
	# l'enseigne : une planche peinte, le nom en lettres de laiton
	var sign_xf := Transform3D(Basis(), T(cx, z0 - 0.35, hh + 1.15))
	kit.box(sign_xf, Vector3(7.4, 1.1, 0.12), "bois_sombre", 1.0)
	kit.box(sign_xf * Transform3D(Basis(), Vector3(0, 0, -0.07)), Vector3(7.6, 1.25, 0.04), "laiton", 1.0)
	var lab := Label3D.new()
	lab.text = "ATELIER DES AILES"
	lab.font_size = 96
	lab.pixel_size = 0.0075
	lab.modulate = Color(1.0, 0.86, 0.5)
	lab.outline_size = 10
	lab.outline_modulate = Color(0.2, 0.12, 0.05)
	lab.position = sign_xf.origin + Vector3(0, 0.12, -0.12)
	lab.rotation.y = PI
	add_child(lab)
	var lab2 := Label3D.new()
	lab2.text = "Ph. Vis, inventeur (enfin !)"
	lab2.font_size = 48
	lab2.pixel_size = 0.0075
	lab2.modulate = Color(0.95, 0.9, 0.78)
	lab2.outline_size = 6
	lab2.outline_modulate = Color(0.15, 0.1, 0.05)
	lab2.position = sign_xf.origin + Vector3(0, -0.33, -0.12)
	lab2.rotation.y = PI
	add_child(lab2)
	# deux lampes d'atelier sous la voûte
	for lz in [z0 + 4.0, z1 - 4.0]:
		var bulb: Vector3 = T(cx, lz, hh - 0.6)
		kit.pipe(T(cx, lz, hh - 0.1), bulb + Vector3.UP * 0.2, 0.02, "fer_noir", false)
		kit.cyl(Transform3D(Basis(), bulb), 0.42, 0.12, 0.3, "cuivre", 12, false)
		kit.cyl(Transform3D(Basis(), bulb + Vector3.DOWN * 0.18), 0.12, 0.12, 0.2, "globe", 10)
		var tv: Node = main.get("temps_v56")
		if tv != null:
			var l := OmniLight3D.new()
			l.light_color = Color(1.0, 0.82, 0.55)
			l.omni_range = 9.0
			l.position = bulb + Vector3.DOWN * 0.4
			l.distance_fade_enabled = true
			l.distance_fade_begin = 50.0
			l.distance_fade_length = 15.0
			add_child(l)
			tv.register_lamp(l, 1.4)


# =================================================================== l'aire d'envol

func _ramp() -> void:
	var z0: float = TERRACE.position.y
	var z1: float = RAMP_Z1
	var xc: float = (RAMP_X0 + RAMP_X1) * 0.5
	var w: float = RAMP_X1 - RAMP_X0
	var L: float = z0 - z1
	var ang: float = atan2(RAMP_DROP, L)
	var mid := T(xc, (z0 + z1) * 0.5, -RAMP_DROP * 0.5 - 0.1)
	var bas := Basis(Vector3.RIGHT, -ang)
	# le tablier de planches (et sa collision), les longerons
	kit.box(Transform3D(bas, mid), Vector3(w, 0.2, L + 0.2), "planches", 1.2)
	kit.col_box(Transform3D(bas, mid + Vector3.DOWN * 0.15), Vector3(w, 0.5, L + 0.2))
	for s in [-1.0, 1.0]:
		kit.box(Transform3D(bas, mid + Vector3(s * (w * 0.5 - 0.1), -0.25, 0)), Vector3(0.22, 0.35, L + 0.2), "bois_sombre", 1.0)
	# les chevalets : des poteaux jusqu'à la pente, contreventés
	for k in range(1, 4):
		var zk: float = z0 - L * float(k) / 3.6
		var yk: float = Y - RAMP_DROP * (z0 - zk) / L - 0.4
		for s2 in [-1.0, 1.0]:
			var xk: float = xc + s2 * (w * 0.5 - 0.3)
			var gk: float = _ground(xk, zk) - 0.5
			if yk - gk > 0.5:
				kit.box(Transform3D(Basis(), R.to_world(xk, zk, (yk + gk) * 0.5)), Vector3(0.3, yk - gk, 0.3), "bois_sombre", 1.0)
				kit.col_box(Transform3D(Basis(), R.to_world(xk, zk, (yk + gk) * 0.5)), Vector3(0.3, yk - gk, 0.3))
		var gm: float = _ground(xc, zk)
		if yk - gm > 4.0:
			var hy: float = lerpf(gm, yk, 0.55)
			var dx: float = w - 0.6
			kit.box(Transform3D(Basis(Vector3.BACK, atan2(yk - hy, dx)), R.to_world(xc, zk, (yk + hy) * 0.5)), Vector3(Vector2(dx, yk - hy).length(), 0.16, 0.16), "bois_sombre", 1.0)
	# les rambardes (cordes et poteaux) et le bout de la piste, peint en damier
	for s3 in [-1.0, 1.0]:
		var xs: float = xc + s3 * (w * 0.5 - 0.08)
		var n: int = 6
		for i in range(n + 1):
			var zz: float = z0 - L * float(i) / n
			var yy: float = Y - RAMP_DROP * (z0 - zz) / L
			kit.box(Transform3D(Basis(), R.to_world(xs, zz, yy + 0.5)), Vector3(0.1, 1.0, 0.1), "bois_sombre", 1.0)
			if i < n:
				var zz2: float = z0 - L * float(i + 1) / n
				var yy2: float = Y - RAMP_DROP * (z0 - zz2) / L
				kit.pipe(R.to_world(xs, zz, yy + 0.95), R.to_world(xs, zz2, yy2 + 0.95), 0.025, "corde", false)
		kit.col_box(Transform3D(bas, mid + Vector3(s3 * (w * 0.5 - 0.08), 0.6, 0)), Vector3(0.12, 1.0, L))
	for i2 in range(5):
		var c: Vector3 = T(RAMP_X0 + 0.5 + i2 * 1.0, z1 + 0.6, -RAMP_DROP + 0.02)
		kit.box(Transform3D(bas, c), Vector3(1.0, 0.02, 1.0), "peinture_jaune" if i2 % 2 == 0 else "peinture_noir", 1.0)
	points["piste_bout"] = T(xc, z1 + 1.2, -RAMP_DROP + 0.05)
	points["piste_pied"] = T(xc, z0 + 1.0, 0.0)
	# un panneau sur son poteau
	var pxf := Transform3D(Basis(Vector3.UP, PI), T(RAMP_X1 + 1.3, z0 + 0.9))
	kit.box(pxf * Transform3D(Basis(), Vector3(0, 1.1, 0)), Vector3(0.12, 2.2, 0.12), "bois_sombre", 1.0)
	kit.box(pxf * Transform3D(Basis(), Vector3(0, 2.15, 0)), Vector3(1.7, 0.6, 0.06), "bois", 1.0)
	var lab := Label3D.new()
	lab.text = "AIRE D'ENVOL\nAu bout de la piste,\ndéplie l'Alouette !"
	lab.font_size = 40
	lab.pixel_size = 0.0055
	lab.modulate = Color(0.2, 0.12, 0.06)
	lab.outline_size = 0
	lab.position = (pxf * Vector3(0, 2.15, 0.05))
	lab.rotation.y = 0.0
	add_child(lab)
	var lab_b := lab.duplicate() as Label3D
	lab_b.position = (pxf * Vector3(0, 2.15, -0.05))
	lab_b.rotation.y = PI
	add_child(lab_b)
	points["panneau"] = pxf.origin


# =================================================================== l'intérieur : établi, plans, caisses

func _props() -> void:
	var h: Rect2 = HANGAR
	# l'établi, contre le mur du fond
	var bxf := Transform3D(Basis(), T(-113.0, h.end.y - 1.6))
	kit.box(bxf * Transform3D(Basis(), Vector3(0, 0.92, 0)), Vector3(3.6, 0.1, 1.1), "bois", 1.0)
	for sx in [-1.65, 1.65]:
		for sz in [-0.45, 0.45]:
			kit.box(bxf * Transform3D(Basis(), Vector3(sx, 0.45, sz)), Vector3(0.1, 0.9, 0.1), "bois_sombre", 1.0)
	kit.box(bxf * Transform3D(Basis(), Vector3(0, 0.25, 0)), Vector3(3.4, 0.05, 1.0), "bois_sombre", 1.0)
	kit.col_box(bxf * Transform3D(Basis(), Vector3(0, 0.5, 0)), Vector3(3.6, 1.0, 1.1))
	# des outils : un étau, une burette, des engrenages, un rouleau de toile
	kit.box(bxf * Transform3D(Basis(), Vector3(-1.3, 1.07, -0.3)), Vector3(0.25, 0.2, 0.18), "fer", 1.0)
	kit.cyl(bxf * Transform3D(Basis(), Vector3(-0.6, 0.97, 0.1)), 0.08, 0.03, 0.24, "laiton", 10)
	kit.gear(bxf * Transform3D(Basis(Vector3.RIGHT, 0.0), Vector3(0.4, 0.99, -0.1)), 0.22, 0.04, 12, "laiton")
	kit.gear(bxf * Transform3D(Basis(), Vector3(0.75, 0.99, 0.2)), 0.14, 0.04, 9, "cuivre")
	kit.cyl(Transform3D(Basis(Vector3.BACK, PI * 0.5), bxf * Vector3(1.4, 1.12, -0.05)), 0.16, 0.16, 0.9, "tissu_creme", 12)
	# le tableau des plans, au-dessus de l'établi
	var pb := Transform3D(Basis(Vector3.UP, PI), T(-113.0, h.end.y - 0.55, 2.6))
	kit.box(pb, Vector3(3.2, 1.8, 0.06), "bois_sombre", 1.0)
	var plan := Label3D.new()
	plan.text = "PLAN N° 7 — L'ALOUETTE\n(les six premiers n'ont pas volé)\n\n   /\\   envergure : 10 m\n  /  \\  finesse : 8\n /____\\ « elle plane ! » — Ph. V."
	plan.font_size = 30
	plan.pixel_size = 0.005
	plan.modulate = Color(0.85, 0.92, 1.0)
	plan.outline_size = 0
	plan.position = pb.origin + Vector3(0, 0, -0.05)
	plan.rotation.y = PI
	add_child(plan)
	var blue := MeshInstance3D.new()
	var bq := QuadMesh.new()
	bq.size = Vector2(3.0, 1.6)
	blue.mesh = bq
	var bm := StandardMaterial3D.new()
	bm.albedo_color = Color(0.1, 0.22, 0.42)
	bm.roughness = 0.9
	blue.material_override = bm
	add_child(blue)
	blue.transform = Transform3D(Basis(Vector3.UP, PI), pb.origin + Vector3(0, 0, -0.035))
	# des caisses, des tonneaux, un rouleau de toile, un ballon replié
	for c in [[-119.5, h.end.y - 1.4, 0.0], [-119.6, h.end.y - 2.5, 0.6], [-106.5, h.end.y - 1.3, 0.3]]:
		kit.crate(T(float(c[0]), float(c[1])), float(c[2]), 0.8, true)
	kit.barrel(T(-106.8, h.end.y - 2.7), true)
	kit.barrel(T(-106.2, h.end.y - 3.6), true)
	# un grand engrenage accroché au mur de côté
	kit.gear(Transform3D(Basis(Vector3.BACK, PI * 0.5), T(h.position.x + 0.55, h.position.y + 7.0, 3.2)), 1.1, 0.12, 18, "cuivre")
	# devant le hangar : un établi de plein air (l'endroit où l'on parle affaires)
	var oxf := Transform3D(Basis(), T(-109.0, h.position.y - 3.2))
	kit.crate(oxf.origin, 0.2, 0.9, true)
	kit.barrel(T(-107.5, h.position.y - 2.4), true)
	points["etabli"] = bxf * Vector3(0, 0, -1.0)
	points["etabli_face"] = bxf.origin
	_speaker = Node3D.new()
	_speaker.name = "Etabli_parole"
	add_child(_speaker)
	_speaker.position = bxf.origin + Vector3.UP * 1.4      # (l'atelier est à l'origine du monde)


## La manche à air, au pied de la piste : elle se gonfle et tourne avec le vent.
func _windsock() -> void:
	var at: Vector3 = T(RAMP_X0 - 1.4, TERRACE.position.y + 0.8)
	var root := Node3D.new()
	root.name = "Manche_a_air"
	add_child(root)
	root.position = at
	var pole := MeshInstance3D.new()
	var pc := CylinderMesh.new()
	pc.top_radius = 0.04
	pc.bottom_radius = 0.06
	pc.height = 5.0
	pole.mesh = pc
	pole.material_override = kit.mat("fer_noir")
	pole.position.y = 2.5
	root.add_child(pole)
	_sock = Node3D.new()
	_sock.position = Vector3(0, 4.85, 0)
	root.add_child(_sock)
	var cone := CylinderMesh.new()
	cone.top_radius = 0.3
	cone.bottom_radius = 0.14
	cone.height = 1.6
	cone.radial_segments = 14
	cone.cap_top = false
	cone.cap_bottom = false
	var stripes := ImageTexture.create_from_image(_stripes())
	var sm := StandardMaterial3D.new()
	sm.albedo_texture = stripes
	sm.cull_mode = BaseMaterial3D.CULL_DISABLED
	sm.roughness = 0.85
	var mi := MeshInstance3D.new()
	mi.mesh = cone
	mi.material_override = sm
	mi.rotation.x = PI * 0.5
	mi.position = Vector3(0, 0, 0.82)
	_sock.add_child(mi)
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.28
	tm.outer_radius = 0.32
	ring.mesh = tm
	ring.material_override = kit.mat("laiton")
	ring.rotation.x = PI * 0.5
	ring.position = Vector3(0, 0, 0.02)
	_sock.add_child(ring)


func _stripes() -> Image:
	var img := Image.create(8, 64, false, Image.FORMAT_RGB8)
	for y in range(64):
		var c: Color = Color(0.95, 0.42, 0.12) if (y / 13) % 2 == 0 else Color(0.95, 0.93, 0.88)
		for x in range(8):
			img.set_pixel(x, y, c)
	return img


## L'Alouette (un prototype, toile tendue) accrochée sous la voûte, au-dessus de l'établi.
func _display() -> void:
	if aeronef == null or not aeronef.has_method("make_display"):
		return
	var proto: Node3D = aeronef.make_display(1)
	if proto == null:
		return
	proto.name = "Prototype_Alouette"
	add_child(proto)
	var c := T((HANGAR.position.x + HANGAR.end.x) * 0.5, (HANGAR.position.y + HANGAR.end.y) * 0.5 + 0.6, 2.2)
	proto.transform = Transform3D(Basis(Vector3.UP, PI * 0.08) * Basis(Vector3.BACK, 0.05), c)
	# les suspentes jusqu'aux arcs
	for p in [Vector3(-3.0, 2.3, 0.5), Vector3(3.0, 2.3, 0.5), Vector3(0, 2.1, -1.6)]:
		var a: Vector3 = proto.transform * p
		var b := Vector3(a.x, T(0, 0, HANGAR_H + 0.4).y, a.z)
		var cm := CylinderMesh.new()
		cm.top_radius = 0.006
		cm.bottom_radius = 0.006
		cm.height = b.y - a.y
		var mi := MeshInstance3D.new()
		mi.mesh = cm
		mi.material_override = kit.mat("fer_noir")
		add_child(mi)
		mi.position = (a + b) * 0.5


# =================================================================== les chemins des habitants

## Les lieux « atelier_ailes_etabli » et « atelier_ailes_piste », reliés aux rues de Cliquetis
## (pour l'agenda de Philibert, voir le rapport).
func _paths() -> void:
	var g: Node = main.get("grande_v59")
	var cq: Node = g.cliquetis if g != null and g.get("cliquetis") != null else null
	if cq == null:
		return
	var pts: Array = [["aa0", T(-99.0, -34.0)], ["aa1", T(-106.0, -33.0)], ["aa2", T(-112.5, -31.5)], ["aa3", T(-112.5, -26.0)], ["aa4", T(-112.5, -37.5)]]
	for e in pts:
		cq.points[str(e[0])] = e[1]
	cq._link("aa0", cq._nearest(T(-99.0, -34.0), ["pr"]))
	cq._link("aa0", "aa1")
	cq._link("aa1", "aa2")
	cq._link("aa2", "aa3")
	cq._link("aa2", "aa4")
	var bench_at: Vector3 = points["etabli"]
	cq._spot_w("atelier_ailes_etabli", bench_at, points["etabli_face"], "bricoler", "")
	cq._spot_w("atelier_ailes_piste", T(-111.0, -39.0), T(-111.0, -60.0), "observer", "")
	for s in ["atelier_ailes_etabli", "atelier_ailes_piste"]:
		var nm: String = "@" + s
		cq.points[nm] = cq.spots[s]["pos"]
		cq._link(nm, "aa3" if s == "atelier_ailes_etabli" else "aa4")
		cq.spots[s]["node"] = nm


# =================================================================== les interactions (E)

func register_interactions(d: Node) -> void:
	if d == null:
		return
	var I: Array = d._interactions
	I.append({"id": "atelier_ailes_etabli", "pos": points.get("etabli", Vector3.INF), "radius": 2.4,
		"text": "E : l'établi de l'Atelier des Ailes", "vr": "Gâchette : l'établi de l'Atelier des Ailes", "call": open_workbench})
	I.append({"id": "atelier_ailes_piste", "pos": points.get("piste_bout", Vector3.INF), "radius": 2.6,
		"text": "E : déplier l'Alouette et s'élancer", "vr": "Gâchette : déplier l'Alouette et s'élancer", "call": _launch_from_ramp,
		"when": func(): return aeronef != null and int(aeronef.lvl) in [1, 2] and not bool(aeronef.riding)})
	if aeronef != null and aeronef.has_method("register_interactions"):
		aeronef.register_interactions(d)


func _launch_from_ramp() -> void:
	var h: Node = main.get("hero_v28")
	if h != null and not bool(main.xr_active):
		h.facing = Vector3(0, 0, -1)
	aeronef.call_vehicle()


# =================================================================== acheter une évolution

func _lvl() -> int:
	return int(aeronef.lvl) if aeronef != null else 0


func _journal() -> Node:
	return main.get("journal_v56")


## La quête d'introduction existe-t-elle dans le carnet (ajoutée par l'intégrateur) ?
func _quest_exists() -> bool:
	var j: Node = _journal()
	return j != null and j.has_method("quest") and not (j.quest(QUEST) as Dictionary).is_empty()


func _cost_text(n: int) -> String:
	var c: Dictionary = COSTS[n]
	var parts: Array = []
	if int(c.get("piece", 0)) > 0:
		parts.append("%d pièces" % int(c["piece"]))
	var inv: Node = main.get("inventory_v28")
	for k in c:
		if str(k) == "piece":
			continue
		var nm: String = str(k)
		if inv != null:
			nm = str(inv.ITEMS.get(str(k), {"name": str(k)})["name"]).to_lower()
		parts.append("%d × %s" % [int(c[k]), nm])
	return ", ".join(parts)


func _missing(n: int) -> String:
	var inv: Node = main.get("inventory_v28")
	if inv == null:
		return "tout"
	var c: Dictionary = COSTS[n]
	var miss: Array = []
	for k in c:
		var have: int = int(inv.count(str(k)))
		if have < int(c[k]):
			var nm: String = "pièces" if str(k) == "piece" else str(inv.ITEMS.get(str(k), {"name": str(k)})["name"]).to_lower()
			miss.append("%d × %s" % [int(c[k]) - have, nm] if str(k) != "piece" else "%d pièces" % (int(c[k]) - have))
	return ", ".join(miss)


func _pay(n: int) -> void:
	var inv: Node = main.get("inventory_v28")
	var c: Dictionary = COSTS[n]
	for k in c:
		inv.remove(str(k), int(c[k]))


## Ce que Philibert peut construire maintenant (0 : rien).
func next_level() -> int:
	var l: int = _lvl()
	if l == 0:
		return 0 if _quest_exists() else 1
	if l < 3:
		return l + 1
	return 0


const PITCH := {
	1: "L'Alouette ! Un deltaplane : de la toile tendue sur une armature de frêne et d'aluminium. On saute d'un point haut, et on plane. Il me faut %s.",
	2: "Un pédalier, une chaîne de vélo, une hélice en bois de poirier : l'Alouette pourra décoller du plat et remonter un peu. Il me faut %s.",
	3: "L'Albatros : un ballon allongé, une nacelle, deux hélices, un petit moteur à vapeur. Et pour le gaz… un fragment de météorite : ça flotte tout seul, c'est très pratique. Il me faut %s.",
}
const DONE := {
	1: "Et voilà ! L'Alouette. Toile tendue, haubans réglés, harnais à ressort. J'ai inventé quelque chose ! Bon, le deltaplane existait peut-être déjà ailleurs… mais pas à Cliquetis ! Va au bout de la piste, et envole-toi !",
	2: "Clic, clac, cliquetis ! L'hélice tourne, la chaîne chante. Pédale, et elle monte ! Un peu. Ce n'est pas une fusée, c'est une Alouette.",
	3: "Regarde-le… l'Albatros ! Il flotte, il ronronne, il est magnifique. Je crois que je vais pleurer. Non. Si. Un peu. Appelle-le où tu veux : il viendra se poser près de toi.",
}


## L'établi (E) : le même menu que chez Philibert.
func open_workbench() -> void:
	state["visite"] = true
	var choices: Array = []
	var n: int = next_level()
	if n > 0:
		choices.append({"id": "aa:construire:%d" % n, "label": "✦ Construire %s (%s)" % [aeronef.vehicle_name(n), _cost_text(n)]})
	if SELL_MATERIALS:
		for k in SELL:
			var inv: Node = main.get("inventory_v28")
			var nm: String = str(inv.ITEMS.get(str(k), {"name": str(k)})["name"]) if inv != null else str(k)
			choices.append({"id": "aa:acheter:" + str(k), "label": "◆ Acheter : %s (%d pièces)" % [nm, int(SELL[k])]})
	choices.append({"id": "aa:fermer", "label": "(Laisser l'établi)"})
	main.ask_v69(_speaker, "L'Atelier des Ailes", "", _bench_text(n), choices, Callable(self, "_bench_pick"))


func _bench_text(n: int) -> String:
	var l: int = _lvl()
	if l == 0 and n == 0:
		return "L'établi de Philibert : des croquis d'ailes partout, des bouts de toile, une burette, une tasse de café froid. Une note : « IDÉE ! Faire voler les gens. Demander de l'aide (toile, bûches, boulons). » Philibert doit traîner en ville : parle-lui."
	if n == 0:
		return "L'établi de Philibert. Sur le mur, une photo de l'Albatros, encadrée. En dessous, une note : « Et après ? Les Lumens d'Astralys, paraît-il, font des machines qui volent jusqu'aux étoiles… »"
	return "L'établi de Philibert, couvert de plans. Sur le plan du dessus : %s. " % aeronef.vehicle_name(n).capitalize() + PITCH[n] % _cost_text(n)


func _bench_pick(id: String) -> void:
	if main.has_method("_close_dialogue_v31"):
		main._close_dialogue_v31()
	if id == "aa:fermer":
		return
	var parts: PackedStringArray = id.split(":")
	if parts.size() < 3:
		return
	if parts[1] == "construire":
		var r: Dictionary = try_build(int(parts[2]))
		_say(str(r["texte"]), 7.0)
	elif parts[1] == "acheter":
		var t: String = _buy(parts[2])
		_say(t, 4.0)


## Construire le niveau n : renvoie {ok, texte} ; paie et monte l'aéronef si possible.
func try_build(n: int) -> Dictionary:
	if n != next_level() and not (n == 4 and _lvl() == 3):
		return {"ok": false, "texte": "Ce n'est pas encore le moment pour celui-là."}
	var miss: String = _missing(n)
	if miss != "":
		return {"ok": false, "texte": "Il manque encore : %s." % miss}
	_pay(n)
	state["achats"] = int(state["achats"]) + 1
	aeronef.set_level(n, true)
	return {"ok": true, "texte": DONE.get(n, "")}


func _buy(id: String) -> String:
	var inv: Node = main.get("inventory_v28")
	var price: int = int(SELL.get(id, 0))
	if inv == null or price <= 0:
		return ""
	if int(inv.count("piece")) < price:
		return "Il te faut %d pièces." % price
	if not inv.can_accept([[id, 1]], [["piece", price]]):
		return "Ton sac est plein !"
	inv.remove("piece", price)
	inv.add(id, 1)
	main.sfx("ramasse_pieces")
	return "+ %s" % str(inv.ITEMS.get(id, {"name": id})["name"])


# =================================================================== le service de Philibert (carnet)

func register_services(journal: Node) -> void:
	if journal == null:
		return
	journal.add_service(BUILDER, Callable(self, "_topics"), Callable(self, "_choose"))
	journal.lieux["atelier_ailes"] = points.get("etabli", Vector3.ZERO)
	journal.lieux["aire_envol"] = points.get("piste_bout", Vector3.ZERO)


func _topics(_npc: Node) -> Array:
	var out: Array = []
	var n: int = next_level()
	if n > 0:
		out.append({"id": "q56:service:aa_construire_%d" % n, "label": "✦ Construire %s (%s)" % [aeronef.vehicle_name(n), _cost_text(n)]})
	if SELL_MATERIALS and _lvl() >= 1:
		out.append({"id": "q56:service:aa_toile", "label": "◆ Une toile à voile (%d pièces)" % int(SELL["toile_voile"])})
		out.append({"id": "q56:service:aa_engrenage", "label": "◆ Un engrenage (%d pièces)" % int(SELL["engrenage"])})
	return out


func _choose(_npc: Node, choice: String) -> Dictionary:
	var key: String = choice.split(":")[2] if choice.split(":").size() > 2 else ""
	if key.begins_with("aa_construire_"):
		var n: int = int(key.trim_prefix("aa_construire_"))
		var miss: String = _missing(n) if n > 0 else "tout"
		if n <= 0 or n != next_level():
			return {"texte": "Hmm ? J'ai perdu le fil. Ça m'arrive. Souvent.", "geste": "parle"}
		if miss != "":
			return {"texte": PITCH[n] % _cost_text(n) + " Il te manque encore %s. Je t'attends ! Je ne bouge pas. Enfin, si, je bouge, mais je reviens." % miss, "geste": "parle"}
		# on paie (main retire « prendre ») et l'aéronef évolue tout de suite
		var take: Array = []
		for k in COSTS[n]:
			take.append([str(k), int(COSTS[n][k])])
		state["achats"] = int(state["achats"]) + 1
		aeronef.set_level(n, true)
		return {"texte": DONE[n], "geste": "salut", "prendre": take}
	if key == "aa_toile" or key == "aa_engrenage":
		var id: String = "toile_voile" if key == "aa_toile" else "engrenage"
		var price: int = int(SELL[id])
		if int(main.inventory_v28.count("piece")) < price:
			return {"texte": "%d pièces, s'il te plaît. Les inventeurs aussi mangent. Surtout des biscuits." % price, "geste": "parle"}
		return {"texte": "Tiens ! De la bonne %s, de chez Bricolette." % ("toile, solide comme une voile de Carène" if id == "toile_voile" else "denture, bien huilée"), "geste": "salut", "prendre": [["piece", price]], "donner": [[id, 1]]}
	return {}


# =================================================================== le Glisseur (Ionie, au Spatioport)

## Pour le gestionnaire d'Astralys : la quête as_glisseur est finie -> le Glisseur stellaire.
func unlock_glisseur() -> void:
	if aeronef != null and int(aeronef.lvl) < 4:
		aeronef.set_level(4, true)


## Un service possible chez Ionie (si la quête ne suffit pas) : à fusionner avec ses propres
## sujets (journal.add_service écrase : appeler ces deux fonctions depuis le service d'Ionie).
func glisseur_topics(_npc: Node) -> Array:
	if _lvl() != 3:
		return []
	return [{"id": "q56:service:as_glisseur_monter", "label": "✦ Transformer l'Albatros en Glisseur stellaire (%s)" % _cost_text(4)}]


func glisseur_choose(_npc: Node, choice: String) -> Dictionary:
	if not choice.ends_with("as_glisseur_monter"):
		return {}
	if _lvl() != 3:
		return {"texte": "Reviens avec ton petit ballon, Pied-Lourd ! Je ne transforme que ce qui vole déjà.", "geste": "parle"}
	var miss: String = _missing(4)
	if miss != "":
		return {"texte": "Pour la coque de nacre, il me faut %s. Il te manque %s. Les pièces ? Je ne sais pas à quoi elles servent, mais je les accepte, par politesse." % [_cost_text(4), miss], "geste": "parle"}
	var take: Array = []
	for k in COSTS[4]:
		take.append([str(k), int(COSTS[4][k])])
	aeronef.set_level(4, true)
	return {"texte": "Zip, zoum, scintille ! Ton Albatros a fait une mue : voici le Glisseur stellaire. Il file comme une pensée heureuse. Ne dépasse pas la vitesse de la lumière, c'est très mal vu par ici.", "geste": "salut", "prendre": take}


# =================================================================== chaque image

func _process(delta: float) -> void:
	if main == null or not bool(main.game_started):
		return
	_clock += delta
	if _sock != null:
		_sock.rotation.y = -0.5 + sin(_clock * 0.31) * 0.35 + sin(_clock * 1.7) * 0.06
		_sock.rotation.x = -0.15 + sin(_clock * 2.3) * 0.05
	# la quête d'introduction : son drapeau « alouette » donne l'Alouette
	_flag_t -= delta
	if _flag_t <= 0.0:
		_flag_t = 1.0
		var j: Node = _journal()
		if j != null and aeronef != null and int(aeronef.lvl) == 0 and bool((j.get("flags") as Dictionary).get("alouette", false)):
			aeronef.set_level(1, true)


func _say(text: String, seconds: float = 4.0) -> void:
	var d: Node = main.get("donjon_v35")
	if d != null and d.has_method("_say"):
		d._say(text, seconds)
	elif main.has_method("_show_message_v28"):
		main._show_message_v28(text)


## On marche sur la terrasse et sur la piste (pour main._limit_on_foot_v29, si besoin).
func walkable(p: Vector3) -> bool:
	var t: Vector2 = R.to_city(p.x, p.z)
	if TERRACE.grow(0.2).has_point(t) and absf(p.y - Y) < 3.0:
		return true
	return t.x > RAMP_X0 - 0.2 and t.x < RAMP_X1 + 0.2 and t.y < TERRACE.position.y + 0.5 and t.y > RAMP_Z1 - 0.2 and absf(p.y - Y) < 4.0


func serialize() -> Dictionary:
	return state.duplicate()


func load_data(d: Dictionary) -> void:
	state = {"visite": bool(d.get("visite", false)), "achats": int(d.get("achats", 0))}


func trouvailles() -> Dictionary:
	return {"atelier_ailes": 1 if bool(state["visite"]) else 0}
