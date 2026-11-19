extends "res://scripts/pnj/pnj_arcanelle_v67.gd"
## V69 : un habitant de l'Île des Trois Soleils (Per-Hâpy, Yaxché, Aztlán). Même vie réglée par
## l'heure que les autres (pnj_azur_v56.gd, et les postures d'Arcanelle, de Cliquetis, de
## Tazira), avec en plus :
##  - prier : à genoux, les bras levés vers le soleil, puis le front vers le sol ;
##  - moudre : à genoux devant la pierre à moudre, les deux mains qui vont et viennent ;
##  - tisser : assis, le métier tendu entre la taille et les mains, la navette qui passe ;
##  - scribe : assis en tailleur, la palette sur les genoux, le calame qui écrit ;
##  - potier : assis devant le tour, les mains qui montent la terre.
## Et les parures (fiche « sol ») : le large collier ousekh, la coiffe de plumes, les ornements
## de jade, le bâton (ankh ou serpent), l'éventail de plumes, le bouclier rond, le casque de
## jaguar du guerrier, la palette du scribe.

var _sol: Dictionary = {}


func setup_azur(manager: Node, data: Dictionary) -> void:
	super.setup_azur(manager, data)
	_sol = data.get("sol", {})
	_build_sol_poses()
	_sol_accessories(_sol)


func _build_sol_poses() -> void:
	if anim == null or skel == null or anim.has_animation_library("sol"):
		return
	var lib = HeroLib.new()
	lib.hero = model
	lib.anim = anim
	lib.skel = skel
	var poses := AnimationLibrary.new()
	# V182 : les jambes posées par directions (lib._jambes2, lib._pied) et le bassin calculé pour que la pose
	# touche le sol (« genoux », « fesses » : lib._au_sol). Avant : à genoux, les jambes remontaient derrière
	# (les pieds en l'air, le corps à 9 cm du sol) ; en tailleur, les jambes plongeaient dans le sol (30 cm).
	# à genoux : les cuisses droites, les jambes à plat derrière, le dessus des pieds au sol
	var kneel: Dictionary = lib._jambes2({}, Vector3(0.1, -0.97, 0.2), Vector3(0.02, -0.05, -1.0))
	kneel = lib._pied(lib._pied(kneel, "Left", Vector3(0.0, -0.3, -0.95)), "Right", Vector3(0.0, -0.3, -0.95))
	# prier : à genoux, bras levés (on salue le soleil), puis prosterné
	# (V179 : les bras posés par des cibles et des directions, lib._main / lib._bras ; avant, des angles qui
	# envoyaient les bras sur les côtés)
	var pr_a := lib._bras2(lib._merge(kneel, {"Head": Vector3(-22, 0, 0), "Spine02": Vector3(-8, 0, 0)}), Vector3(0.3, 0.85, 0.43), Vector3(0.2, 0.93, 0.3))
	var pr_b := lib._bras2(lib._merge(kneel, {"Head": Vector3(10, 0, 0), "Spine01": Vector3(36, 0, 0), "Spine02": Vector3(30, 0, 0)}), Vector3(0.15, 0.6, 0.79), Vector3(0.1, 0.65, 0.75))
	poses.add_animation("prier", lib._clip(9.0, true, [[0.0, pr_a, Vector3.ZERO, "genoux"], [3.0, pr_a, Vector3.ZERO, "genoux"], [4.4, pr_b, Vector3(0, 0, -6), "genoux"], [6.6, pr_b, Vector3(0, 0, -6), "genoux"],
		[8.0, pr_a, Vector3.ZERO, "genoux"], [9.0, pr_a, Vector3.ZERO, "genoux"]]))
	# moudre : penché sur la pierre, les deux mains poussent la molette en avant, puis la ramènent
	var mo_a := lib._bras2(lib._merge(kneel, {"Spine01": Vector3(26, 0, 0), "Spine02": Vector3(20, 0, 0), "Head": Vector3(8, 0, 0)}), Vector3(0.1, -0.55, 0.83), Vector3(0.0, -0.45, 0.89))
	var mo_b := lib._bras2(lib._merge(mo_a, {"Spine01": Vector3(38, 0, 0), "Spine02": Vector3(26, 0, 0)}), Vector3(0.08, -0.3, 0.95), Vector3(0.03, -0.25, 0.97))
	poses.add_animation("moudre", lib._clip(1.6, true, [[0.0, mo_a, Vector3.ZERO, "genoux"], [0.8, mo_b, Vector3(0, 0, 3), "genoux"], [1.6, mo_a, Vector3.ZERO, "genoux"]]))
	# assis en tailleur (scribe, tisser, potier)
	# (V182 : les cuisses ouvertes vers l'avant, les genoux près du sol, chaque jambe repliée sous la cuisse d'en
	# face, les pieds couchés)
	var cross: Dictionary = lib._jambe("Left", Vector3(0.6, -0.1, 0.79), Vector3(-0.86, -0.03, -0.5))
	cross = lib._merge(cross, lib._jambe("Right", Vector3(-0.6, -0.1, 0.79), Vector3(0.88, 0.02, -0.46)))
	cross = lib._pied(lib._pied(cross, "Left", Vector3(-0.55, -0.15, 0.82)), "Right", Vector3(0.55, -0.15, 0.82))
	cross["Spine02"] = Vector3(8, 0, 0)
	var sc_a := lib._merge(lib._merge(lib._merge(cross, {"Head": Vector3(22, 0, 0)}), lib._main("Right", "Spine02", Vector3(-6, 2, 26), Vector3(-1, -1, 0))), lib._main("Left", "Spine02", Vector3(8, 4, 24), Vector3(1, -1, 0)))
	var sc_b := lib._merge(sc_a, lib._main("Right", "Spine02", Vector3(-2, 2, 27), Vector3(-1, -1, 0)))
	var sc_c := lib._merge(sc_a, {"Head": Vector3(0, 14, 0)})
	poses.add_animation("scribe", lib._clip(8.0, true, [[0.0, sc_a, Vector3.ZERO, "fesses"], [0.6, sc_b, Vector3.ZERO, "fesses"], [1.2, sc_a, Vector3.ZERO, "fesses"], [1.8, sc_b, Vector3.ZERO, "fesses"], [3.0, sc_a, Vector3.ZERO, "fesses"],
		[4.4, sc_c, Vector3.ZERO, "fesses"], [5.6, sc_c, Vector3.ZERO, "fesses"], [6.4, sc_a, Vector3.ZERO, "fesses"], [7.2, sc_b, Vector3.ZERO, "fesses"], [8.0, sc_a, Vector3.ZERO, "fesses"]]))
	var ti_a := lib._mains(lib._merge(cross, {"Spine02": Vector3(-10, 0, 0), "Head": Vector3(16, 0, 0)}), "Spine02", Vector3(12, 6, 28), Vector3(1, -1, 0))
	var ti_b := lib._merge(lib._merge(ti_a, lib._main("Right", "Spine02", Vector3(-4, 6, 30), Vector3(-1, -1, 0))), lib._main("Left", "Spine02", Vector3(20, 4, 26), Vector3(1, -1, 0)))
	var ti_c := lib._merge(lib._merge(ti_a, lib._main("Left", "Spine02", Vector3(4, 6, 30), Vector3(1, -1, 0))), lib._main("Right", "Spine02", Vector3(-20, 4, 26), Vector3(-1, -1, 0)))
	poses.add_animation("tisser", lib._clip(3.2, true, [[0.0, ti_a, Vector3.ZERO, "fesses"], [0.8, ti_b, Vector3.ZERO, "fesses"], [1.6, ti_a, Vector3(0, 0, -2), "fesses"], [2.4, ti_c, Vector3.ZERO, "fesses"], [3.2, ti_a, Vector3.ZERO, "fesses"]]))
	var po_a := lib._mains(lib._merge(cross, {"Spine02": Vector3(22, 0, 0), "Head": Vector3(18, 0, 0)}), "Spine02", Vector3(8, -2, 30), Vector3(1, -1, 0))
	var po_b := lib._mains(lib._merge(po_a, {"Spine02": Vector3(16, 0, 0)}), "Spine02", Vector3(7, 0, 32), Vector3(1, -1, 0))
	poses.add_animation("potier", lib._clip(2.4, true, [[0.0, po_a, Vector3.ZERO, "fesses"], [1.2, po_b, Vector3.ZERO, "fesses"], [2.4, po_a, Vector3.ZERO, "fesses"]]))
	anim.add_animation_library("sol", poses)
	lib.free()


func _activity(delta: float, dist: float, to_player: Vector3) -> void:
	match pose:
		"prier", "moudre", "tisser", "scribe", "potier":
			# on lève les yeux quand le joueur approche (un salut, puis on reprend)
			if dist < 2.4 and pose != "prier":
				_play("v28/idle", 0.4)
				_face(to_player, delta, 3.0)
			else:
				_play("sol/" + pose, 0.5)
		_:
			super._activity(delta, dist, to_player)


func _arrive() -> void:
	super._arrive()
	if pose in ["prier", "moudre", "tisser", "scribe", "potier"] and not hidden_home:
		var sp: Dictionary = azur.spot(target_spot)
		if not sp.is_empty():
			global_position = sp["pos"]


# =================================================================== les parures

func _sol_accessories(t: Dictionary) -> void:
	if skel == null or t.is_empty():
		return
	var gold := _mat(Color(0.95, 0.72, 0.28), 0.3)
	gold.metallic = 0.85
	var jade := _mat(Color(0.2, 0.55, 0.38), 0.22)
	jade.metallic_specular = 0.8
	# le large collier (ousekh) : des rangs de perles qui tombent du cou sur les épaules et la
	# poitrine (un col évasé en trois bandes : or, couleur, or)
	if t.has("usekh"):
		var c: Array = t["usekh"]
		var col := Node3D.new()
		var cm := _mat(Color(float(c[0]), float(c[1]), float(c[2])), 0.35)
		cm.cull_mode = BaseMaterial3D.CULL_DISABLED
		var gm := _mat(Color(0.95, 0.72, 0.28), 0.3)
		gm.metallic = 0.85
		gm.cull_mode = BaseMaterial3D.CULL_DISABLED
		var bands := [[0.078, 0.104, gm], [0.104, 0.142, cm], [0.142, 0.158, gm], [0.158, 0.178, cm]]
		var y: float = 0.012
		for b in bands:
			var hb: float = (float(b[1]) - float(b[0])) * 0.9
			var cy := CylinderMesh.new()
			cy.top_radius = float(b[0])
			cy.bottom_radius = float(b[1])
			cy.height = hb
			cy.cap_top = false
			cy.cap_bottom = false
			cy.radial_segments = 28
			cy.rings = 1
			_part(col, cy, b[2], Vector3(0, y - hb * 0.5, 0.0), Vector3(1.0, 1.0, 0.82))
			y -= hb
		_attach("Spine02", Vector3(0, 26.0, 1.0), col, Vector3(-8, 0, 0))
	# la coiffe de plumes : un éventail de longues plumes au-dessus de la tête
	if t.has("plumes"):
		var c2: Array = t["plumes"]
		var pm := _mat(Color(float(c2[0]), float(c2[1]), float(c2[2])), 0.45)
		pm.cull_mode = BaseMaterial3D.CULL_DISABLED
		pm.metallic_specular = 0.7
		var crest := Node3D.new()
		var n: int = 9
		for i in range(n):
			var a: float = lerpf(-62.0, 62.0, float(i) / (n - 1))
			var f := _box_mesh_np(Vector3(0.045, 0.34, 0.006))
			_part(crest, f, pm if i % 2 == 0 else _mat(Color(float(c2[0]) * 0.6 + 0.3, float(c2[1]) * 0.6 + 0.2, float(c2[2]) * 0.6), 0.45), Vector3(sin(deg_to_rad(a)) * 0.12, 0.17 + cos(deg_to_rad(a)) * 0.12, -0.04), Vector3.ONE, Vector3(-10, 0, -a))
		_part(crest, _cyl(0.1, 0.11, 0.05), gold if bool(t.get("jade", false)) == false else jade, Vector3(0, 0.02, 0.0))
		_attach("Head", Vector3(0, 16.0, 1.0), crest)
	# les ornements de jade : de gros disques aux oreilles
	if bool(t.get("jade", false)):
		for s in [-1.0, 1.0]:
			var ear := Node3D.new()
			_part(ear, _cyl(0.022, 0.022, 0.012), jade, Vector3.ZERO, Vector3.ONE, Vector3(0, 0, 90))
			_attach("Head", Vector3(s * 7.6, 6.0, 0.0), ear)
	# le bâton : une croix ankh d'or (Égypte) ou un serpent à plumes (Mayas, Aztèques)
	match str(t.get("baton", "")):
		"ankh":
			var st := Node3D.new()
			_part(st, _cyl(0.014, 0.016, 1.3), gold, Vector3(0, 0.1, 0))
			var loop := TorusMesh.new()
			loop.inner_radius = 0.045
			loop.outer_radius = 0.065
			_part(st, loop, gold, Vector3(0, 0.86, 0), Vector3(1.0, 1.35, 1.0), Vector3(90, 0, 0))
			_part(st, _box_mesh_np(Vector3(0.18, 0.025, 0.025)), gold, Vector3(0, 0.76, 0))
			_attach("LeftHand", Vector3(0, -8, 3), st, Vector3(90, 0, 0))
			staff_node = st
		"serpent":
			var st2 := Node3D.new()
			var wood := _mat(Color(0.32, 0.2, 0.12), 0.8)
			_part(st2, _cyl(0.018, 0.024, 1.5), wood, Vector3(0, 0.2, 0))
			_part(st2, _sphere(0.05), jade, Vector3(0, 0.98, 0.02), Vector3(1.0, 0.8, 1.4))
			for k in range(5):
				_part(st2, _box_mesh_np(Vector3(0.02, 0.16, 0.004)), _mat(Color(0.1, 0.55, 0.3), 0.45), Vector3(0, 1.04 + k * 0.01, -0.04 - k * 0.012), Vector3.ONE, Vector3(-30 - k * 10, 0, (k - 2) * 14))
			_attach("LeftHand", Vector3(0, -8, 3), st2, Vector3(90, 0, 0))
			staff_node = st2
	# l'éventail de plumes (le marchand)
	if bool(t.get("eventail", false)):
		var fan := Node3D.new()
		var fm := _mat(Color(0.2, 0.6, 0.65), 0.45)
		fm.cull_mode = BaseMaterial3D.CULL_DISABLED
		_part(fan, _cyl(0.008, 0.01, 0.18), _mat(Color(0.35, 0.22, 0.12), 0.7), Vector3(0, 0.05, 0))
		for k2 in range(7):
			var a2: float = lerpf(-40.0, 40.0, k2 / 6.0)
			_part(fan, _box_mesh_np(Vector3(0.035, 0.2, 0.004)), fm, Vector3(sin(deg_to_rad(a2)) * 0.08, 0.22, 0), Vector3.ONE, Vector3(0, 0, -a2))
		_attach("RightHand", Vector3(0, -8, 3), fan, Vector3(90, 0, 0))
	# le bouclier rond du guerrier, sur le bras gauche ; ses franges de plumes
	if bool(t.get("bouclier", false)):
		var sh := Node3D.new()
		_part(sh, _cyl(0.24, 0.24, 0.025), _mat(Color(0.85, 0.65, 0.2), 0.6), Vector3.ZERO, Vector3.ONE, Vector3(90, 0, 0))
		_part(sh, _cyl(0.12, 0.12, 0.03), _mat(Color(0.2, 0.45, 0.5), 0.5), Vector3(0, 0, 0.004), Vector3.ONE, Vector3(90, 0, 0))
		for k3 in range(6):
			_part(sh, _box_mesh_np(Vector3(0.05, 0.14, 0.004)), _mat(Color(0.75, 0.15, 0.1), 0.5), Vector3(-0.15 + k3 * 0.06, -0.3, 0), Vector3.ONE, Vector3(0, 0, 0))
		_attach("LeftForeArm", Vector3(0, 12, -6), sh, Vector3(0, 90, 0))
	# le casque de jaguar : la tête de la bête au-dessus du visage, les oreilles, le museau
	if bool(t.get("jaguar", false)):
		var jh := Node3D.new()
		var fur := _mat(Color(0.86, 0.62, 0.2), 0.8)
		var spot := _mat(Color(0.12, 0.08, 0.05), 0.8)
		_part(jh, _sphere(0.15), fur, Vector3(0, 0.05, -0.01), Vector3(1.05, 0.75, 1.15))
		_part(jh, _sphere(0.08), fur, Vector3(0, 0.03, 0.15), Vector3(1.0, 0.7, 1.0))
		_part(jh, _box_mesh_np(Vector3(0.1, 0.02, 0.04)), _mat(Color(0.95, 0.92, 0.86), 0.6), Vector3(0, -0.02, 0.2))
		for s2 in [-1.0, 1.0]:
			_part(jh, _cyl(0.0, 0.04, 0.07), fur, Vector3(s2 * 0.1, 0.15, -0.02))
			_part(jh, _sphere(0.02), spot, Vector3(s2 * 0.06, 0.1, 0.1))
		for k4 in range(8):
			var a3: float = TAU * k4 / 8.0
			_part(jh, _sphere(0.022), spot, Vector3(cos(a3) * 0.13, 0.08 + sin(a3 * 2.0) * 0.02, sin(a3) * 0.12), Vector3(1.0, 0.4, 1.0))
		_attach("Head", Vector3(0, 13.0, 1.0), jh)
	# la palette du scribe (dans la main gauche) et le calame
	if bool(t.get("palette", false)):
		var pal := Node3D.new()
		_part(pal, _box_mesh_np(Vector3(0.05, 0.28, 0.012)), _mat(Color(0.55, 0.42, 0.26), 0.7), Vector3(0, 0.1, 0))
		_part(pal, _cyl(0.008, 0.008, 0.004), _mat(Color(0.7, 0.12, 0.08), 0.6), Vector3(0, 0.22, 0.008), Vector3.ONE, Vector3(90, 0, 0))
		_part(pal, _cyl(0.008, 0.008, 0.004), _mat(Color(0.05, 0.05, 0.05), 0.6), Vector3(0, 0.19, 0.008), Vector3.ONE, Vector3(90, 0, 0))
		_attach("LeftHand", Vector3(0, -8, 3), pal, Vector3(90, 0, 0))
