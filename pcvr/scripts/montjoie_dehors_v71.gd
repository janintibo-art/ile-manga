extends Node3D
## V71 : le dehors de l'Île de Montjoie (hors des remparts) :
##  - le Port des Mouettes (au nord-ouest) : le quai, la capitainerie, l'étal du poisson, le phare,
##    des barques ;
##  - les Champs du Sud : la ferme de Père Gaubert (la maison, la grange, les champs de navets,
##    l'épouvantail… qui porte le chapeau du Baron), le moulin de Clovis ;
##  - le Lac des Grenouilles : l'eau, le ponton de pêche, la cabane d'Yvon ;
##  - le Bois des Lutins : le camp des gobelins (tentes, feu, totem, bannière du chef) ;
##  - les Crocs : les cristaux d'orage aux trois sommets ; à leur pied, l'entrée du Donjon des
##    Mille Marches (la vieille tour en ruine, l'escalier qui descend) et la cabane d'Odon ;
##  - des poteaux indicateurs aux carrefours.
## Ses lieux (spots) et ses points s'ajoutent au réseau des rues de la ville (montjoie_ville_v71).

const R = preload("res://scripts/ile_montjoie_v71.gd")

var main: Node
var manager: Node                        # montjoie_v71
var ile: Node3D
var city: Node3D
var kit
var objets: Dictionary = {}
var fire_spots: Array = []
var flora_avoid: Array = []
var lake_water: MeshInstance3D
var crops: Array = []                    # Vector3 : les navets plantés (les champs)
var dungeon_door := Vector3.ZERO         # devant l'escalier du donjon
var scarecrow_hat: Node3D                # le chapeau du Baron, sur l'épouvantail
var field_center := Vector3.ZERO
var _rng := RandomNumberGenerator.new()


func T(x: float, y: float, z: float) -> Transform3D:
	return Transform3D(Basis(), Vector3(x, y, z))


## Un point au sol (repère île).
func G(x: float, z: float, dy: float = 0.0) -> Vector3:
	var w: Vector3 = R.W(x, z)
	w.y = ile.height(w.x, w.z) + dy
	return w


func GX(x: float, z: float, toward: Vector3) -> Transform3D:
	var p: Vector3 = G(x, z)
	var d := Vector3(toward.x - p.x, 0, toward.z - p.z).normalized()
	return Transform3D(Basis.looking_at(-d, Vector3.UP), p)


func build(owner: Node) -> void:
	manager = owner
	main = owner.main
	ile = owner.ile
	city = owner.city
	kit = load("res://scripts/montjoie_kit_v71.gd").new()
	kit.setup(self, main.get("temps_v56") if main != null else null)
	kit.main = main
	kit.pc = owner.pc
	kit.rng.seed = 7181
	kit.light_every = 1
	_rng.seed = 7182
	_port()
	_ferme()
	_moulin()
	_lac()
	_camp()
	_crocs()
	_donjon()
	_panneaux()
	kit.commit()
	for f in kit.fires70:
		fire_spots.append(f)
	_graph()


# =================================================================== le Port des Mouettes

func _port() -> void:
	var hc: Vector3 = R.W(R.HARBOR.x, R.HARBOR.y, R.QUAY_Y)
	var town: Vector3 = R.W(R.TOWN.x, R.TOWN.y)
	var to_town: Vector3 = Vector3(town.x - hc.x, 0, town.z - hc.z).normalized()
	var a_town: float = atan2(to_town.z, to_town.x)
	# le quai : un anneau de pierre autour du bassin, du côté de la terre
	kit.arc_ring(Vector3(hc.x, -6.0, hc.z), R.HARBOR_R - 0.2, R.HARBOR_R + 1.2, R.QUAY_Y + 6.0, a_town - 1.4, a_town + 1.4, "rempart71", 40, true, 15)
	for k in range(28):
		var a: float = a_town - 1.35 + 2.7 * k / 27.0
		var p: Vector3 = hc + Vector3(cos(a), 0, sin(a)) * (R.HARBOR_R + 0.4)
		if k % 3 == 0:
			kit.cyl(Transform3D(Basis(), p + Vector3.UP * 0.0), 0.16, 0.12, 0.55, "fer71", 8)
	# la capitainerie : une maison de pierre face au bassin
	var cap: Transform3D = GX(R.HARBOR.x + to_town.x * 58.0 + 6.0, R.HARBOR.y + to_town.z * 58.0 - 8.0, hc)
	var door: Vector3 = kit.house71(cap, 8.0, 7.0, {"floors": 2, "base": "moellons71", "wall": "enduit71_bleu", "roof": "tuiles71_ardoise", "gable": true, "lit": 0.6, "volet": "bleu"})
	objets["capitainerie"] = door
	city.doors["porte_isidore"] = city._pt("porte_isidore", door)
	city._pt("port_cap", cap * Vector3(2.4, 0.05, 3.0))
	city._spot("port_capitainerie", cap * Vector3(2.6, 0.05, 1.6), cap.basis * Vector3(0, 0, 1), "bras_croises", "port_cap")
	city._link("porte_isidore", "port_cap")
	# l'étal du poisson, des caisses, des tonneaux, des filets
	var fs: Transform3D = Transform3D(Basis.looking_at(to_town, Vector3.UP), hc + to_town * (R.HARBOR_R + 6.5) + Vector3(-to_town.z, 0, to_town.x) * 9.0)
	kit.stall71(fs, 2.8, 1.4, "bleu")
	city._pt("port_etal", fs * Vector3(1.9, 0.05, 1.0))
	city._spot("port_poisson", fs * Vector3(0, 0.05, -1.95), fs.basis * Vector3(0, 0, 1), "comptoir", "port_etal")
	for k2 in range(6):
		var q: Vector3 = hc + to_town * (R.HARBOR_R + 4.0) + Vector3(-to_town.z, 0, to_town.x) * (-12.0 + k2 * 3.4)
		q.y = R.QUAY_Y
		if k2 % 2 == 0:
			kit.barrel71(q)
		else:
			kit.crate71(q, k2 * 0.7)
	city._pt("port_q1", hc + to_town * (R.HARBOR_R + 2.5) + Vector3(-to_town.z, 0, to_town.x) * -6.0 + Vector3.UP * 0.05)
	city._pt("port_q2", hc + to_town * (R.HARBOR_R + 2.5) + Vector3(-to_town.z, 0, to_town.x) * 6.0 + Vector3.UP * 0.05)
	city._spot("port_quai_1", (city.points["port_q1"] as Vector3) - to_town * 1.4, -to_town, "pecher", "port_q1")
	city._spot("port_quai_2", (city.points["port_q2"] as Vector3) - to_town * 1.4, -to_town, "observer", "port_q2")
	city._chain(["port_q1", "port_etal", "port_q2", "port_cap"])
	objets["port"] = hc + to_town * (R.HARBOR_R + 4.0)
	# des barques amarrées
	for k3 in range(3):
		var a3: float = a_town + PI + (k3 - 1) * 0.5
		var bp: Vector3 = hc + Vector3(cos(a3), 0, sin(a3)) * (R.HARBOR_R * 0.55)
		_rowboat(Transform3D(Basis(Vector3.UP, a3 + 0.4), Vector3(bp.x, R.WATER + 0.05, bp.z)))
	# le phare, sur son îlot
	var ph: Vector3 = ile.pads_world["phare"]
	var top: Vector3 = kit.tower70(ph, 2.4, 14.0, {"roof": "cone", "roof_key": "tuiles71_rouge", "roof_h": 3.0, "windows": [4.0, 9.0], "nwin": 2, "lit": 0.8, "wall": "enduit71_blanc", "trim": "dalles71"})
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.86, 0.6)
	l.light_energy = 3.0
	l.omni_range = 26.0
	kit.root.add_child(l)
	l.position = top + Vector3.DOWN * 1.2
	if kit.temps != null and kit.temps.has_method("register_lamp"):
		kit.temps.register_lamp(l, 3.0)
	flora_avoid.append([Vector2(hc.x, hc.z), R.HARBOR_R + 14.0])


func _rowboat(xf: Transform3D) -> void:
	for s in [-1.0, 1.0]:
		kit.box(xf * Transform3D(Basis(Vector3.BACK, s * 0.25), Vector3(s * 0.62, 0.3, 0)), Vector3(0.08, 0.55, 3.6), "planches71", 1.0)
	kit.box(xf * T(0, 0.08, 0), Vector3(1.1, 0.08, 3.4), "planches71_sombre", 1.0)
	kit.box(xf * T(0, 0.35, 0.3), Vector3(1.2, 0.06, 0.3), "planches71", 1.0)
	kit.box(xf * T(0, 0.3, 1.75), Vector3(0.7, 0.5, 0.1), "planches71", 1.0)


# =================================================================== la ferme, le moulin

func _ferme() -> void:
	var fp: Vector3 = ile.pads_world["ferme"]
	var town: Vector3 = R.W(R.TOWN.x, R.TOWN.y)
	var fl: Vector2 = R.L(fp.x, fp.z)
	var hx: Transform3D = GX(fl.x - 6.0, fl.y - 8.0, town)
	var door: Vector3 = kit.house71(hx, 10.0, 8.0, {"floors": 2, "base": "moellons71", "wall": "enduit71_creme", "roof": "chaume71", "gable": false, "lit": 0.6, "volet": "vert", "flowers": true})
	city.doors["porte_gaubert"] = city._pt("porte_gaubert", door)
	city.doors["porte_germaine"] = city._pt("porte_germaine", door)
	# la grange
	var gx: Transform3D = GX(fl.x + 12.0, fl.y - 4.0, R.W(fl.x, fl.y))
	kit.box(gx * T(0, 2.4, -5.0), Vector3(9.0, 4.8, 10.0), "planches71_sombre", 2.0, 63 - 8)
	kit.col_box(gx * T(0, 2.4, -5.0), Vector3(9.0, 4.8, 10.0))
	kit.roof_gable(gx * Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(0, 4.8, -5.0)), 10.0, 9.0, 45.0, 0.4, "tuiles71_brun", "planches71_sombre")
	kit.box(gx * T(0, 1.6, 0.02), Vector3(3.6, 3.2, 0.08), "volet71_rouge", 1.0)
	kit.haystack71(gx * Vector3(5.8, 0, -1.5), 1.3)
	kit.haystack71(gx * Vector3(6.4, 0, -5.0), 1.1)
	kit.cart71(Transform3D(Basis(Vector3.UP, 0.6), G(fl.x + 2.0, fl.y + 8.0)), true)
	city._pt("ferme_cour_pt", G(fl.x, fl.y, 0.05))
	city._link("porte_gaubert", "ferme_cour_pt")
	city._link("porte_germaine", "ferme_cour_pt")
	city._spot("ferme_cour", G(fl.x + 2.0, fl.y + 1.0, 0.05), Vector3(0, 0, 1), "bras_croises", "ferme_cour_pt")
	# les champs de navets : des rangées de fanes ; la clôture ; l'épouvantail
	field_center = R.W(R.FIELDS.get_center().x, R.FIELDS.get_center().y)
	var rows: int = 0
	for zi in range(int(R.FIELDS.size.y / 3.0)):
		var z: float = R.FIELDS.position.y + 2.5 + zi * 3.0
		for xi in range(int(R.FIELDS.size.x / 1.6)):
			var x: float = R.FIELDS.position.x + 2.5 + xi * 1.6
			if Vector2(x, z).distance_to(R.FARM) < 30.0 or Vector2(x, z).distance_to(R.MILL) < 12.0:
				continue
			if fposmod(x - R.FIELDS.position.x, 40.0) < 2.5 or fposmod(z - R.FIELDS.position.y, 28.0) < 2.0:
				continue
			crops.append(G(x + _rng.randf_range(-0.2, 0.2), z + _rng.randf_range(-0.2, 0.2)))
			rows += 1
	_crop_mesh()
	var fr: Rect2 = R.FIELDS
	for e in [[Vector2(fr.position.x, fr.position.y), Vector2(fr.end.x, fr.position.y)], [Vector2(fr.position.x, fr.end.y), Vector2(fr.end.x, fr.end.y)], [Vector2(fr.position.x, fr.position.y), Vector2(fr.position.x, fr.end.y)]]:
		var a: Vector2 = e[0]
		var b: Vector2 = e[1]
		var n: int = int(a.distance_to(b) / 12.0)
		for k in range(n):
			if k % 5 == 2:
				continue
			var p0: Vector2 = a.lerp(b, float(k) / n)
			var p1: Vector2 = a.lerp(b, float(k + 1) / n)
			kit.fence71(G(p0.x, p0.y), G(p1.x, p1.y))
	var sc: Vector3 = G(fl.x - 10.0, fl.y + 30.0)
	kit.box(Transform3D(Basis(), sc + Vector3.UP * 1.1), Vector3(0.1, 2.2, 0.1), "poutre71", 1.0)
	kit.box(Transform3D(Basis(), sc + Vector3.UP * 1.65), Vector3(1.6, 0.08, 0.08), "poutre71", 1.0)
	kit.box(Transform3D(Basis(), sc + Vector3.UP * 1.45), Vector3(0.6, 0.8, 0.3), "tissu71_brun", 1.0)
	kit.ball(Transform3D(Basis(), sc + Vector3.UP * 2.15), 0.22, "foin71", 8, 5)
	kit.col_box(Transform3D(Basis(), sc + Vector3.UP * 1.1), Vector3(0.4, 2.2, 0.4))
	# le chapeau du Baron, coincé sur la tête de l'épouvantail (une vraie plume !)
	scarecrow_hat = Node3D.new()
	scarecrow_hat.name = "Chapeau_du_Baron"
	add_child(scarecrow_hat)
	scarecrow_hat.position = sc + Vector3.UP * 2.32
	_hat_mesh(scarecrow_hat)
	objets["chapeau_baron"] = sc + Vector3(0.9, 0.3, 0.0)
	city._pt("champ_1_pt", G(fl.x - 20.0, fl.y + 14.0, 0.05))
	city._pt("champ_2_pt", G(fl.x + 22.0, fl.y + 22.0, 0.05))
	city._chain(["champ_1_pt", "ferme_cour_pt", "champ_2_pt"])
	city._spot("ferme_champ_1", G(fl.x - 20.5, fl.y + 16.5, 0.05), Vector3(0, 0, 1), "jardiner", "champ_1_pt")
	city._spot("ferme_champ_2", G(fl.x + 22.5, fl.y + 24.5, 0.05), Vector3(0, 0, 1), "jardiner", "champ_2_pt")
	objets["ferme"] = G(fl.x, fl.y)
	flora_avoid.append([Vector2(fp.x, fp.z), 26.0])


## Le chapeau du Baron : un grand feutre violet, une plume blanche.
func _hat_mesh(parent: Node3D) -> void:
	var mi := MeshInstance3D.new()
	var saved: Dictionary = kit.batch
	kit.batch = {}
	kit.cyl(Transform3D.IDENTITY, 0.32, 0.32, 0.03, "tissu71_violet", 16)
	kit.cyl(T(0, 0.02, 0), 0.17, 0.15, 0.24, "tissu71_violet", 14)
	kit.cyl(T(0, 0.04, 0), 0.172, 0.172, 0.05, "or71", 14, false)
	kit.beam(Vector3(0.12, 0.08, 0.05), Vector3(0.36, 0.5, -0.12), 0.04, "tissu71_blanc")
	var mesh := ArrayMesh.new()
	for key in kit.batch:
		(kit.batch[key] as SurfaceTool).commit(mesh)
		mesh.surface_set_material(mesh.get_surface_count() - 1, kit.mat(str(key)))
	kit.batch = saved
	mi.mesh = mesh
	parent.add_child(mi)


## Les fanes des navets : un MultiMesh (une touffe de feuilles).
func _crop_mesh() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in range(5):
		var a: float = TAU * k / 5.0
		var d := Vector3(cos(a), 0, sin(a))
		var side := Vector3(-d.z, 0, d.x) * 0.07
		var tip: Vector3 = d * 0.24 + Vector3.UP * 0.32
		var n: Vector3 = (d + Vector3.UP).normalized()
		for v in [Vector3.ZERO + side, tip, Vector3.ZERO - side, Vector3.ZERO - side, tip, Vector3.ZERO + side]:
			st.set_normal(n)
			st.add_vertex(v)
	# la tête du navet, qui dépasse un peu de la terre
	var top := SphereMesh.new()
	top.radius = 0.07
	top.height = 0.1
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.25, 0.48, 0.16)
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.roughness = 0.75
	var mesh: ArrayMesh = st.commit()
	mesh.surface_set_material(0, m)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = crops.size()
	for i in range(crops.size()):
		mm.set_instance_transform(i, Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * _rng.randf_range(0.8, 1.3)), crops[i]))
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Fanes_des_navets"
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.visibility_range_end = 220.0
	add_child(mmi)


func _moulin() -> void:
	var mp: Vector3 = ile.pads_world["moulin"]
	var ml: Vector2 = R.L(mp.x, mp.z)
	var town: Vector3 = R.W(R.TOWN.x, R.TOWN.y)
	var mx: Transform3D = GX(ml.x, ml.y, town)
	kit.windmill71(mx)
	var door: Vector3 = mx * Vector3(0, 0.25, -3.6)
	city.doors["porte_clovis"] = city._pt("porte_clovis", door)
	city._pt("moulin_pt", mx * Vector3(3.4, 0.05, -3.0))
	city._link("porte_clovis", "moulin_pt")
	city._spot("moulin", mx * Vector3(2.2, 0.05, -4.2), mx.basis * Vector3(0, 0, -1), "bricoler", "moulin_pt")
	for k in range(3):
		kit.crate71(mx * Vector3(-3.6 - k * 0.6, 0, -2.0 + k * 0.4), k * 0.4, 0.6)
	objets["moulin"] = mx.origin
	flora_avoid.append([Vector2(mp.x, mp.z), 9.0])


# =================================================================== le lac

func _lac() -> void:
	var c: Vector3 = R.W(R.LAKE.x, R.LAKE.y, R.LAKE_Y)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n: int = 96
	var rings: int = 6
	for ri in range(rings):
		var r0: float = float(ri) / rings
		var r1: float = float(ri + 1) / rings
		for i in range(n):
			var a0: float = TAU * i / n
			var a1: float = TAU * (i + 1) / n
			var q: Array = []
			for pr in [[r0, a0], [r1, a0], [r1, a1], [r0, a1]]:
				var rr: float = float(pr[0]) * 1.12
				q.append(Vector3(cos(float(pr[1])) * R.LAKE_AX.x * rr, 0.0, sin(float(pr[1])) * R.LAKE_AX.y * rr))
			for v in [q[0], q[2], q[1], q[0], q[3], q[2]]:
				st.set_normal(Vector3.UP)
				st.set_uv(Vector2((v as Vector3).x, (v as Vector3).z) * 0.1)
				st.add_vertex(v)
	lake_water = MeshInstance3D.new()
	lake_water.name = "Lac_des_Grenouilles"
	lake_water.mesh = st.commit()
	lake_water.material_override = kit.mat("eau71")
	lake_water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(lake_water)
	lake_water.position = c
	# le ponton de pêche (du rivage ouest vers le milieu du lac)
	var town: Vector3 = R.W(R.TOWN.x, R.TOWN.y)
	var dirl: Vector3 = Vector3(c.x - town.x, 0, c.z - town.z).normalized()
	var shore: Vector3 = c - dirl * (R.LAKE_AX.x * 0.98)
	var a: Vector3 = Vector3(shore.x, R.LAKE_Y + 0.55, shore.z) - dirl * 3.0
	var b: Vector3 = Vector3(shore.x, R.LAKE_Y + 0.55, shore.z) + dirl * 12.0
	var len: float = a.distance_to(b)
	var px := Transform3D(Basis.looking_at(-dirl, Vector3.UP), (a + b) * 0.5)
	kit.box(px * T(0, 0, 0), Vector3(2.2, 0.14, len), "planches71", 1.4)
	kit.col_box(px * T(0, -0.05, 0), Vector3(2.2, 0.2, len))
	for k in range(int(len / 2.5) + 1):
		for s in [-1.0, 1.0]:
			kit.cyl(Transform3D(Basis(), px * Vector3(s * 1.0, -2.5, -len * 0.5 + k * 2.5)), 0.12, 0.12, 2.7, "poutre71", 8)
	city.kit.walk_boxes.append([px.affine_inverse(), Vector3(1.2, 2.5, len * 0.5 + 0.4)])
	var tip: Vector3 = b + Vector3.UP * 0.05
	city._pt("lac_ponton_pt", (a + b) * 0.5 + Vector3.UP * 0.12)
	city._pt("lac_bord", Vector3(a.x, 0, a.z) + Vector3(0, ile.height(a.x, a.z) + 0.05, 0) - dirl * 2.0)
	city._chain(["lac_bord", "lac_ponton_pt"])
	city._spot("lac_ponton", tip - dirl * 0.6 + Vector3.UP * 0.07, dirl, "pecher", "lac_ponton_pt")
	objets["lac_ponton"] = tip
	# la cabane d'Yvon, sur la rive
	var side := Vector3(-dirl.z, 0, dirl.x)
	var hp: Vector3 = shore - dirl * 12.0 + side * 9.0
	var hl: Vector2 = R.L(hp.x, hp.z)
	var hx: Transform3D = GX(hl.x, hl.y, c)
	var door: Vector3 = kit.house71(hx, 6.0, 5.0, {"floors": 1, "base": "planches71", "wall": "planches71", "roof": "chaume71", "gable": true, "lit": 0.6, "volet": "bleu", "chimney": true})
	city.doors["porte_yvon"] = city._pt("porte_yvon", door)
	city._link("porte_yvon", "lac_bord")
	city._spot("lac_rive", shore - dirl * 1.5 - side * 4.0 + Vector3(0, ile.height(shore.x - dirl.x * 1.5 - side.x * 4.0, shore.z - dirl.z * 1.5 - side.z * 4.0) - shore.y + 0.05, 0), dirl, "observer", "lac_bord")
	_rowboat(Transform3D(Basis(Vector3.UP, 0.8), Vector3(tip.x + side.x * 3.0, R.LAKE_Y + 0.02, tip.z + side.z * 3.0)))
	objets["lac"] = c
	flora_avoid.append([Vector2(hp.x, hp.z), 6.0])


# =================================================================== le camp des gobelins

func _camp() -> void:
	var cp: Vector3 = ile.pads_world["camp"]
	var cl: Vector2 = R.L(cp.x, cp.z)
	# le feu au milieu, des tentes en cercle, le totem, la bannière du chef
	kit.ring(Transform3D(Basis(), cp), 0.8, 1.1, 0.25, "moellons71_sombre", 10)
	kit.fires70.append([cp + Vector3.UP * 0.3, 0.55])
	for k in range(5):
		var a: float = TAU * k / 5.0 + 0.3
		var tp: Vector3 = G(cl.x + cos(a) * 9.0, cl.y + sin(a) * 9.0)
		kit.cyl(Transform3D(Basis(Vector3.UP, a), tp), 2.0, 0.1, 3.0, ["tissu71_brun", "cuir71", "tissu71_vert"][k % 3], 6, false, 1.4)
		kit.cyl(Transform3D(Basis(), tp + Vector3.UP * 2.6), 0.05, 0.05, 1.0, "poutre71", 4)
		kit.col_cyl(tp, 1.6, 2.4)
	var to: Vector3 = G(cl.x - 3.0, cl.y - 4.0)
	kit.cyl(Transform3D(Basis(), to), 0.3, 0.25, 3.4, "poutre71", 8)
	for k2 in range(3):
		kit.ball(Transform3D(Basis(), to + Vector3.UP * (1.2 + k2 * 0.9)), 0.36, ["tissu71_rouge", "foin71", "tissu71_jaune"][k2], 8, 5)
	kit.col_cyl(to, 0.4, 3.4)
	var bp: Vector3 = G(cl.x + 4.0, cl.y - 3.0)
	kit.cyl(Transform3D(Basis(), bp), 0.08, 0.06, 4.2, "poutre71", 6)
	kit.box(Transform3D(Basis(), bp + Vector3(0.7, 3.4, 0)), Vector3(1.3, 1.1, 0.04), "tissu71_rouge", 1.0)
	for k3 in range(4):
		kit.crate71(G(cl.x - 6.0 + k3 * 1.0, cl.y + 5.0), k3 * 0.5, 0.65)
	objets["camp"] = cp
	city._pt("foret_lis_pt", G(R.FOREST.x - 10.0, R.FOREST.y + 70.0, 0.05))
	city._spot("foret_lisiere", G(R.FOREST.x - 12.0, R.FOREST.y + 72.0, 0.05), Vector3(0, 0, -1), "observer", "foret_lis_pt")
	flora_avoid.append([Vector2(cp.x, cp.z), 14.0])


# =================================================================== les Crocs, le donjon

func _crocs() -> void:
	for i in range(3):
		var p: Vector3 = ile.pads_world["croc_%d" % (i + 1)]
		# une couronne de cristaux d'orage : ils grésillent, violets, sur le sommet
		for k in range(6):
			var a: float = TAU * k / 6.0 + i
			var q: Vector3 = p + Vector3(cos(a) * 1.6, 0, sin(a) * 1.6)
			q.y = ile.height(q.x, q.z) - 0.1
			var tilt := Basis(Vector3(sin(a), 0, -cos(a)), 0.35)
			kit.cyl(Transform3D(tilt, q), 0.14, 0.0, _rng.randf_range(0.8, 1.5), "orage71", 6, false)
		var l := OmniLight3D.new()
		l.light_color = Color(0.7, 0.6, 1.0)
		l.light_energy = 1.4
		l.omni_range = 7.0
		kit.root.add_child(l)
		l.position = p + Vector3.UP * 1.2
		objets["cristal_orage_%d" % (i + 1)] = p + Vector3(0, 0.3, 0)
		flora_avoid.append([Vector2(p.x, p.z), 4.0])


func _donjon() -> void:
	var dp: Vector3 = ile.pads_world["donjon"]
	var dl: Vector2 = R.L(dp.x, dp.z)
	var town: Vector3 = R.W(R.TOWN.x, R.TOWN.y)
	var dx: Transform3D = GX(dl.x, dl.y, town)
	# la vieille tour en ruine : un fût éventré, sans toit, des pierres tombées
	var c: Vector3 = dx * Vector3(0, 0, -4.0)
	kit.cyl(Transform3D(Basis(), c + Vector3.DOWN * 0.6), 5.4, 5.2, 1.0, "rempart71_sombre", 20, false)
	for k in range(20):
		var a: float = TAU * k / 20.0
		var hh: float = 9.0 + sin(k * 1.7) * 3.5 + (4.0 if k % 5 == 0 else 0.0)
		if absf(wrapf(a - atan2((dx.basis * Vector3(0, 0, 1)).z, (dx.basis * Vector3(0, 0, 1)).x), -PI, PI)) < 0.32:
			hh = 0.0
		if hh <= 0.0:
			continue
		var p: Vector3 = c + Vector3(cos(a), 0, sin(a)) * 5.0
		kit.box(Transform3D(Basis(Vector3.UP, -a), p + Vector3.UP * hh * 0.5), Vector3(1.2, hh, 1.62), "rempart71_mousse", 2.0)
		kit.col_box(Transform3D(Basis(Vector3.UP, -a), p + Vector3.UP * hh * 0.5), Vector3(1.2, hh, 1.62))
	# l'escalier qui descend dans le noir (une trappe de pierre au milieu de la tour)
	kit.box(Transform3D(dx.basis, c + Vector3.UP * 0.05), Vector3(3.0, 0.1, 3.6), "moellons71_sombre", 1.0)
	kit.box(Transform3D(dx.basis, c + Vector3(0, 0.07, 0) + dx.basis * Vector3(0, 0, -0.3)), Vector3(2.0, 0.04, 2.4), "terre71", 1.0)
	for k2 in range(4):
		kit.box(Transform3D(dx.basis, c + dx.basis * Vector3(0, 0.08 - k2 * 0.01, -0.9 + k2 * 0.5)), Vector3(1.8, 0.05, 0.42), "dalles71", 1.0)
	for s in [-1.0, 1.0]:
		kit.torch(kit.root, c + dx.basis * Vector3(s * 1.6, 2.2, 1.2), dx.basis * Vector3(0, 0, 1), 1.4, true)
	dungeon_door = c + dx.basis * Vector3(0, 0.1, 2.2)
	objets["donjon_porte"] = dungeon_door
	# des blocs tombés autour
	for k3 in range(7):
		var a3: float = TAU * k3 / 7.0 + 0.4
		var q: Vector3 = c + Vector3(cos(a3), 0, sin(a3)) * _rng.randf_range(7.0, 10.0)
		q.y = ile.height(q.x, q.z)
		kit.box(Transform3D(Basis(Vector3.UP, a3).rotated(Vector3.RIGHT, 0.2), q + Vector3.UP * 0.4), Vector3(1.2, 0.8, 1.0) * _rng.randf_range(0.7, 1.3), "rempart71_mousse", 1.0)
	# la cabane d'Odon et son enseigne « Donjon : registre, potions, cordes »
	var ox: Transform3D = dx * Transform3D(Basis(Vector3.UP, 0.5), Vector3(-11.0, 0, 3.0))
	ox.origin.y = ile.height(ox.origin.x, ox.origin.z)
	var door: Vector3 = kit.house71(ox, 5.6, 5.0, {"floors": 1, "base": "planches71_sombre", "wall": "planches71", "roof": "tuiles71_brun", "gable": true, "lit": 0.8, "volet": "rouge"})
	city.doors["porte_odon"] = city._pt("porte_odon", door)
	kit.counter71(dx * T(-5.0, ile.height(c.x, c.z) - dx.origin.y, 4.0), 2.0)
	city._pt("donjon_pt", dx * Vector3(-3.0, 0.05, 6.5))
	city._link("porte_odon", "donjon_pt")
	city._spot("donjon_entree", dx * Vector3(-5.0, 0.05, 2.8), dx.basis * Vector3(0, 0, 1), "comptoir", "donjon_pt")
	objets["odon"] = dx * Vector3(-5.0, 0.05, 5.2)
	flora_avoid.append([Vector2(c.x, c.z), 13.0])


## Des poteaux indicateurs aux carrefours (le port, la ville, les champs, le lac, la forêt, le donjon).
func _panneaux() -> void:
	for spec in [[-8.0, 178.0], [-104.0, 150.0], [184.0, 20.0], [-120.0, -172.0]]:
		var p: Vector3 = G(float(spec[0]) + 2.5, float(spec[1]) + 2.5)
		kit.box(Transform3D(Basis(), p + Vector3.UP * 1.2), Vector3(0.12, 2.4, 0.12), "poutre71", 1.0)
		for k in range(3):
			var a: float = k * 2.1 + float(spec[0]) * 0.01
			kit.box(Transform3D(Basis(Vector3.UP, a), p + Vector3.UP * (2.1 - k * 0.32) + Vector3(cos(a), 0, -sin(a)) * 0.0), Vector3(1.1, 0.22, 0.05), "planches71_clair", 1.0)
		kit.col_box(Transform3D(Basis(), p + Vector3.UP * 1.2), Vector3(0.3, 2.4, 0.3))


# =================================================================== le réseau

## Les chemins : une suite de points (tous les ~11 m) reliés aux portes de la ville et aux lieux.
func _graph() -> void:
	var starts := {"port": "dehors_nord", "champs": "dehors_sud", "lac": "dehors_est", "foret": "dehors_est", "moulin": "", "donjon": "", "crocs": "", "croc_sud": "", "croc_ouest": "", "plage": ""}
	var ends := {"port": "port_cap", "champs": "ferme_cour_pt", "moulin": "moulin_pt", "donjon": "donjon_pt", "lac": "lac_bord"}
	for k in ile.paths_world:
		var pts: Array = ile.paths_world[k]
		if pts.size() < 2:
			continue
		var prev: String = ""
		var acc: float = 0.0
		for i in range(pts.size()):
			if i > 0:
				acc += (pts[i] as Vector3).distance_to(pts[i - 1])
			if i == 0 or i == pts.size() - 1 or acc > 11.0:
				acc = 0.0
				var nm: String = city._pt("ch_%s_%d" % [str(k), i], (pts[i] as Vector3) + Vector3.UP * 0.05)
				if prev != "":
					city._link(prev, nm)
				elif str(starts.get(k, "")) != "" and city.points.has(str(starts[k])):
					city._link(str(starts[k]), nm)
				else:
					city._link(city._nearest_point(pts[i] as Vector3, "ch_" + str(k)), nm)
				prev = nm
		if ends.has(k) and city.points.has(str(ends[k])):
			city._link(prev, str(ends[k]))
	if city.points.has("foret_lis_pt"):
		city._link("foret_lis_pt", city._nearest_point(city.points["foret_lis_pt"], "foret_lis"))
	city._link("port_q1", city._nearest_point(city.points["port_q1"], "port_"))
