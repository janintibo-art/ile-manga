extends "res://scripts/pnj/pnj_braise_v70.gd"
## V71 : un habitant de Montjoie (l'Île de Montjoie, la ville fortifiée sur la Butte). Même vie
## réglée par l'heure que les autres (pnj_azur_v56 et toutes les postures des îles d'avant : jouer
## de la musique, forger, danser, pêcher, jardiner, bricoler…), sans rien de démoniaque ; et ce qui
## fait un habitant de Montjoie (fiche « mj » : tenue, objet, chapeau) :
##  - les chapeaux : le chapeau pointu du mage, le bonnet, le chaperon, le feutre à plume, le
##    casque du garde, la toque du cuisinier ;
##  - les objets : l'épée (au côté), la masse de la prêtresse, l'arc (dans le dos), le bâton du
##    mage, le tampon de la réceptionniste, la louche, le plateau, le panier, le filet, la canne à
##    pêche, la cloche de la crieuse, le luth du barde ; et ceux des démons de Braise (la lanterne,
##    le livre, le marteau, la canne).

var _mj: Dictionary = {}
var _lute: Node3D
var _hand_prop: Node3D                  # ce qu'on tient à la main (rangé quand on est occupé)


func setup_azur(manager: Node, data: Dictionary) -> void:
	super.setup_azur(manager, data)
	mj_props(data.get("mj", {}))


## Les habits de la fiche « mj » : le chapeau et l'objet (appelé aussi par allie_v71 pour les
## compagnons).
func mj_props(mj: Dictionary) -> void:
	if skel == null or mj.is_empty() or not _mj.is_empty():
		return
	_mj = mj
	var tenue: String = str(mj.get("tenue", ""))
	_hat(str(mj.get("chapeau", "")), tenue)
	var obj: String = str(mj.get("objet", ""))
	match obj:
		"lanterne", "livre", "marteau":
			_make_object(obj, tenue)
		"baton":
			_make_object("baton", "savant" if tenue == "mage" else tenue)
		"canne":
			_make_object("baton", "")
		_:
			_mj_object(obj, tenue)


func _m(c: Color, rough: float = 0.7, metal: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	return m


func _cone(r0: float, r1: float, h: float) -> CylinderMesh:
	var cm := CylinderMesh.new()
	cm.top_radius = r1
	cm.bottom_radius = r0
	cm.height = h
	cm.radial_segments = 16
	cm.rings = 1
	return cm


# =================================================================== les chapeaux

func _hat(kind: String, tenue: String) -> void:
	if kind == "":
		return
	# les chapeaux du vrai corps (V64 : le chapeau pointu, le bonnet, le casque, le chaperon, la
	# toque) sont cousus avec les habits (appearance.py, les cheveux coupés dessous) ; seul le feutre
	# à plume est posé ici
	if not v64.is_empty() and kind != "plume":
		return
	var hb: Dictionary = _head_box()
	var k: float = float(hb["k"])
	var top: float = float(hb["haut"])
	var side: float = float(hb["cote"])
	var zf: float = float(hb["avant"])
	var zb: float = float(hb["arriere"])
	var zc: float = (zf + zb) * 0.5
	var rr: float = maxf(side, (zf - zb) * 0.5) * 1.08
	var h := Node3D.new()
	h.name = "Chapeau_" + kind
	var col: Color = _hat_color(kind, tenue)
	var cloth := _m(col, 0.85)
	match kind:
		"mage":
			# le grand chapeau pointu (un peu cassé au bout), le large bord, le ruban d'étoiles
			_part(h, _cone(rr * 2.3, rr * 2.3, 0.012 * k), cloth, Vector3(0, top - 0.025 * k, zc))
			_part(h, _cone(rr * 1.02, rr * 0.55, 0.16 * k), cloth, Vector3(0, top + 0.06 * k, zc))
			var tip := Node3D.new()
			tip.position = Vector3(0, top + 0.14 * k, zc)
			tip.rotation_degrees = Vector3(-28, 0, 8)
			h.add_child(tip)
			_part(tip, _cone(rr * 0.55, 0.004, 0.16 * k), cloth, Vector3(0, 0.07 * k, 0))
			var band := _m(Color(0.95, 0.78, 0.3), 0.35, 0.7)
			_part(h, _cone(rr * 1.03, rr * 1.0, 0.025 * k), band, Vector3(0, top + 0.0 * k, zc))
		"bonnet":
			# le bonnet de laine, rond, qui retombe un peu
			_part(h, _sphere(rr * 1.06), cloth, Vector3(0, top - 0.025 * k, zc - 0.005 * k), Vector3(1.0, 0.72, 1.06))
			_part(h, _cone(rr * 1.08, rr * 1.06, 0.03 * k), _m(col.darkened(0.25), 0.9), Vector3(0, top - 0.045 * k, zc))
		"chaperon":
			# le chaperon de feutre, à cornette qui pend sur le côté
			_part(h, _sphere(rr * 1.08), cloth, Vector3(0, top - 0.03 * k, zc), Vector3(1.0, 0.65, 1.05))
			_part(h, _cone(rr * 1.12, rr * 1.12, 0.035 * k), _m(col.darkened(0.2), 0.85), Vector3(0, top - 0.04 * k, zc))
			_part(h, _cone(0.025 * k, 0.015 * k, 0.2 * k), cloth, Vector3(side * 1.05, top - 0.1 * k, zb * 0.6), Vector3.ONE, Vector3(0, 0, -12))
		"plume":
			# le feutre à large bord et sa grande plume
			_part(h, _cone(rr * 1.5, rr * 1.5, 0.012 * k), cloth, Vector3(0, top - 0.02 * k, zc), Vector3(1.0, 1.0, 0.92))
			_part(h, _cone(rr * 0.98, rr * 0.9, 0.08 * k), cloth, Vector3(0, top + 0.02 * k, zc))
			_part(h, _cone(rr * 1.0, rr * 1.0, 0.018 * k), _m(Color(0.75, 0.15, 0.12), 0.6), Vector3(0, top - 0.005 * k, zc))
			var fe := Node3D.new()
			fe.position = Vector3(rr * 0.8, top + 0.03 * k, zc - 0.02 * k)
			fe.rotation_degrees = Vector3(-55, 0, -25)
			h.add_child(fe)
			_part(fe, _sphere(0.03 * k), _m(Color(0.95, 0.94, 0.9), 0.9), Vector3(0, 0.11 * k, 0), Vector3(0.45, 4.0, 0.12))
		"casque":
			# le casque rond (un « chapeau de fer ») à bord, du garde
			var iron := _m(Color(0.55, 0.56, 0.58), 0.35, 0.85)
			_part(h, _sphere(rr * 1.1), iron, Vector3(0, top - 0.035 * k, zc), Vector3(1.0, 0.7, 1.05))
			_part(h, _cone(rr * 1.6, rr * 1.5, 0.012 * k), iron, Vector3(0, top - 0.045 * k, zc))
			_part(h, _sphere(0.012 * k), _m(Color(0.8, 0.62, 0.28), 0.3, 0.9), Vector3(0, top + 0.035 * k, zc))
		"toque":
			# la toque blanche, haute et bouffante
			var white := _m(Color(0.96, 0.95, 0.93), 0.9)
			_part(h, _cone(rr * 1.02, rr * 1.0, 0.05 * k), white, Vector3(0, top - 0.01 * k, zc))
			_part(h, _sphere(rr * 1.2), white, Vector3(0, top + 0.08 * k, zc), Vector3(1.0, 0.75, 1.0))
	_attach_raw_head(h)


func _hat_color(kind: String, tenue: String) -> Color:
	var r := RandomNumberGenerator.new()
	r.seed = hash(str(profile.get("id", "")) + kind)
	match kind:
		"mage":
			return [Color(0.22, 0.12, 0.38), Color(0.1, 0.12, 0.3), Color(0.35, 0.1, 0.16)][r.randi() % 3]
		"plume":
			return [Color(0.12, 0.1, 0.18), Color(0.3, 0.12, 0.08), Color(0.12, 0.22, 0.14)][r.randi() % 3]
		"chaperon":
			return [Color(0.55, 0.14, 0.1), Color(0.18, 0.3, 0.16), Color(0.45, 0.32, 0.12)][r.randi() % 3]
		"bonnet":
			return Color(0.2, 0.25, 0.42) if tenue == "marin" else [Color(0.6, 0.55, 0.42), Color(0.5, 0.18, 0.12), Color(0.3, 0.36, 0.22)][r.randi() % 3]
	return Color(0.4, 0.3, 0.2)


# =================================================================== les objets

func _mj_object(obj: String, tenue: String) -> void:
	var wood := _m(Color(0.34, 0.22, 0.12), 0.75)
	var dark := _m(Color(0.18, 0.11, 0.07), 0.6)
	var steel := _m(Color(0.72, 0.73, 0.76), 0.25, 0.9)
	var brass := _m(Color(0.85, 0.64, 0.3), 0.3, 0.9)
	var leather := _m(Color(0.32, 0.18, 0.09), 0.65)
	match obj:
		"epee":
			# l'épée au fourreau, sur la hanche gauche
			var sw := Node3D.new()
			_part(sw, _cyl(0.022, 0.03, 0.72), leather, Vector3(0, -0.36, 0))
			_part(sw, _cyl(0.024, 0.024, 0.03), brass, Vector3(0, -0.72, 0))
			_part(sw, _box_mesh_np(Vector3(0.17, 0.022, 0.03)), brass, Vector3(0, 0.02, 0))
			_part(sw, _cyl(0.016, 0.016, 0.13), leather, Vector3(0, 0.1, 0))
			_part(sw, _sphere(0.022), brass, Vector3(0, 0.18, 0))
			_attach("Hips", Vector3(-15, -4, -2), sw, Vector3(-18, 0, -12))
		"masse":
			var ms := Node3D.new()
			_part(ms, _cyl(0.014, 0.017, 0.48), wood, Vector3(0, -0.2, 0))
			_part(ms, _sphere(0.055), brass, Vector3(0, -0.47, 0))
			for kk in range(6):
				var a: float = TAU * kk / 6.0
				_part(ms, _box_mesh_np(Vector3(0.012, 0.07, 0.03)), brass, Vector3(cos(a) * 0.05, -0.47, sin(a) * 0.05), Vector3.ONE, Vector3(0, -rad_to_deg(a), 0))
			_attach("Hips", Vector3(14, -4, -2), ms, Vector3(-10, 0, 10))
		"arc":
			# l'arc et le carquois dans le dos
			var bw := Node3D.new()
			for s in [-1.0, 1.0]:
				_part(bw, _cyl(0.008, 0.013, 0.62), dark, Vector3(0, s * 0.3, -0.04), Vector3.ONE, Vector3(-s * 12, 0, 0))
			_part(bw, _box_mesh_np(Vector3(0.003, 1.18, 0.003)), _m(Color(0.9, 0.88, 0.8), 0.9), Vector3(0, 0, 0.03))
			_part(bw, _cyl(0.045, 0.04, 0.5), leather, Vector3(0.14, 0.05, -0.06), Vector3.ONE, Vector3(0, 0, -14))
			for kk2 in range(5):
				_part(bw, _cyl(0.004, 0.004, 0.2), wood, Vector3(0.1 + kk2 * 0.016, 0.34, -0.06), Vector3.ONE, Vector3(0, 0, -14))
				_part(bw, _box_mesh_np(Vector3(0.002, 0.05, 0.02)), _m(Color(0.8, 0.2, 0.15), 0.8), Vector3(0.11 + kk2 * 0.016, 0.42, -0.06), Vector3.ONE, Vector3(0, 0, -14))
			_attach("Spine02", Vector3(0, 4, -14), bw, Vector3(0, 0, 30))
		"luth":
			_lute = Node3D.new()
			var lw := _m(Color(0.6, 0.36, 0.14), 0.35)
			_part(_lute, _sphere(0.13), lw, Vector3.ZERO, Vector3(1.0, 0.45, 1.25))
			_part(_lute, _cyl(0.035, 0.035, 0.005), dark, Vector3(0, 0.06, 0.02), Vector3.ONE, Vector3(90, 0, 0))
			_part(_lute, _box_mesh_np(Vector3(0.045, 0.025, 0.32)), dark, Vector3(0, 0.03, 0.3))
			_part(_lute, _box_mesh_np(Vector3(0.05, 0.03, 0.09)), dark, Vector3(0, 0.0, 0.48), Vector3.ONE, Vector3(-30, 0, 0))
			_attach("Spine02", Vector3(0, 2, -16), _lute, Vector3(70, 0, 40))
		"tampon":
			_hand_prop = Node3D.new()
			_part(_hand_prop, _cyl(0.022, 0.028, 0.08), dark, Vector3(0, 0.04, 0))
			_part(_hand_prop, _sphere(0.03), dark, Vector3(0, 0.09, 0))
			_part(_hand_prop, _box_mesh_np(Vector3(0.07, 0.02, 0.045)), brass, Vector3(0, -0.005, 0))
			_attach("RightHand", Vector3(0, -6, 3), _hand_prop, Vector3(180, 0, 0))
		"louche":
			_hand_prop = Node3D.new()
			_part(_hand_prop, _cyl(0.008, 0.008, 0.36), steel, Vector3(0, 0.1, 0))
			_part(_hand_prop, _sphere(0.05), steel, Vector3(0, 0.29, 0.025), Vector3(1.0, 0.6, 1.0))
			_attach("RightHand", Vector3(0, -6, 3), _hand_prop, Vector3(90, 0, 0))
		"plateau":
			_hand_prop = Node3D.new()
			_part(_hand_prop, _cyl(0.17, 0.17, 0.012), brass, Vector3.ZERO)
			_part(_hand_prop, _cyl(0.035, 0.03, 0.12), _m(Color(0.75, 0.5, 0.15), 0.2), Vector3(-0.06, 0.06, 0.02))
			_part(_hand_prop, _cyl(0.035, 0.03, 0.12), _m(Color(0.75, 0.5, 0.15), 0.2), Vector3(0.05, 0.06, -0.03))
			_attach("LeftHand", Vector3(0, -4, 8), _hand_prop, Vector3(0, 0, 90))
		"panier":
			_hand_prop = Node3D.new()
			var wicker := _m(Color(0.62, 0.46, 0.24), 0.9)
			_part(_hand_prop, _cyl(0.13, 0.1, 0.13), wicker, Vector3(0, -0.2, 0))
			var tm := TorusMesh.new()
			tm.inner_radius = 0.1
			tm.outer_radius = 0.115
			_part(_hand_prop, tm, wicker, Vector3(0, -0.12, 0), Vector3.ONE, Vector3(0, 0, 90))
			for kk3 in range(3):
				_part(_hand_prop, _sphere(0.04), _m([Color(0.75, 0.15, 0.1), Color(0.95, 0.85, 0.4), Color(0.4, 0.6, 0.2)][kk3], 0.5), Vector3(-0.05 + kk3 * 0.05, -0.13, 0.02))
			_attach("LeftHand", Vector3(0, -6, 2), _hand_prop)
		"filet":
			_hand_prop = Node3D.new()
			_part(_hand_prop, _cyl(0.012, 0.014, 1.1), wood, Vector3(0, 0.2, 0))
			var net := _m(Color(0.75, 0.7, 0.55, 0.7), 0.9)
			net.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			_part(_hand_prop, _sphere(0.16), net, Vector3(0, 0.82, 0), Vector3(1.0, 1.2, 0.5))
			_attach("LeftHand", Vector3(0, -8, 3), _hand_prop)
		"canne_peche":
			_hand_prop = Node3D.new()
			_part(_hand_prop, _cyl(0.006, 0.014, 1.7), dark, Vector3(0, 0.6, 0))
			_part(_hand_prop, _cyl(0.025, 0.025, 0.04), steel, Vector3(0, -0.1, 0.03), Vector3.ONE, Vector3(0, 0, 90))
			_attach("LeftHand", Vector3(0, -8, 3), _hand_prop, Vector3(-20, 0, 0))
		"cloche":
			_hand_prop = Node3D.new()
			_part(_hand_prop, _cyl(0.012, 0.012, 0.12), wood, Vector3(0, 0.04, 0))
			_part(_hand_prop, _cyl(0.025, 0.07, 0.11), brass, Vector3(0, -0.07, 0))
			_attach("RightHand", Vector3(0, -6, 3), _hand_prop, Vector3(180, 0, 0))


func _br_props(which: String) -> void:
	super._br_props(which)
	var busy: bool = pose in HOLD_POSES
	if _hand_prop != null:
		_hand_prop.visible = not busy or pose == "comptoir"
	# le luth : dans le dos ; devant soi quand on joue (la posture du violon)
	if _lute != null:
		_lute.visible = true


func _activity(delta: float, dist: float, to_player: Vector3) -> void:
	if pose == "violon" and _lute != null:
		# le barde joue du luth : même posture que la violoniste de Braise, le luth à la place
		_br_props("")
		_play("br/violon", 0.4, 0.8)
		return
	super._activity(delta, dist, to_player)
