## Le grand contrôle des bugs visuels, V179 : les bras des personnages. Les poses construites (bras
## croisés, assis, en colère, les mains dans le dos, au comptoir…) s'écrivaient en angles qui, sur ce
## squelette (au repos les bras en A, l'avant-bras qui part en dehors), envoyaient les bras sur les côtés :
## les bras croisés de Clovis au moulin étaient des bras levés, paumes au ciel. Elles posent maintenant le
## poignet à un endroit du corps (hero_v28._main) ou les bras par directions (hero_v28._bras).
## Un habitant (trois corps : un homme, une femme, un garçon) prend chaque pose ; on regarde où sont ses
## coudes et ses poignets, dans le repère de son corps, en longueurs de haut du bras (L) :
##   - les bras croisés : chaque poignet de l'autre côté de la poitrine, devant elle, entre la taille et
##     les épaules ;
##   - assis : les mains au-dessus des cuisses ;
##   - en colère : les poings sur les hanches ; les mains dans le dos : derrière le dos ;
##   - applaudir : les mains l'une contre l'autre, devant soi ; au comptoir : devant soi, sous les épaules ;
##   - aucune pose (toutes celles des habitants) n'a plus le défaut d'avant : le coude pendant le long du
##     corps, la main remontée au-dessus du coude et partie en dehors.
const NOM := "bras179"
const Fig98 = preload("res://scripts/pnj/figurant_v81.gd")
const Gens98 = preload("res://scripts/pnj/maisons_habitants_v81.gd")
const POSES98 := ["debout", "bras_croises", "colere", "rire", "comptoir", "mains_dos", "applaudir", "pointer",
	"peindre", "bricoler", "cuisiner", "danse", "violon", "cache", "mime", "boire", "guitare_bo",
	"basse_bo", "leviter", "mediter", "forger", "jardiner", "enseigner", "observer", "holo", "crier", "moudre",
	"prier", "chanter", "assis", "manger", "rire_assis", "tricot", "bain", "lire", "guitare",
	"dormir_assis"]


## Les os du corps (dans le repère du squelette : X vers sa gauche, Y vers le haut, Z vers l'avant).
func _os98(sk: Skeleton3D, nom: String) -> Vector3:
	return sk.get_bone_global_pose(sk.find_bone(nom)).origin


func _serie() -> void:
	var lieu := Node3D.new()
	lieu.name = "Bras98"
	add_child(lieu)
	lieu.global_position = _pos() + Vector3(0, 0, 4)
	for corps in ["montjoie:0", "montjoie:1", "montjoie:4"]:
		var p: Dictionary = Gens98.profile("f81_%s_%d" % [str(corps).get_slice(":", 0), int(str(corps).get_slice(":", 1))])
		var gens: Array = []
		for k in POSES98.size():
			var f: Node = Fig98.spawn(lieu, self, p.duplicate(true), lieu.global_position + Vector3(k * 2.5 - 40.0, 0, 0), Vector3(0, 0, 1), str(POSES98[k]))
			f.follow = false
			f.lines = []
			gens.append(f)
		await _att(1.6)
		var defaut: Array = []
		for k in POSES98.size():
			var pose: String = str(POSES98[k])
			var sk: Skeleton3D = gens[k].npc.get("skel")
			if not _note(sk != null and sk.find_bone("LeftHand") >= 0, "%s %s : le squelette" % [corps, pose]):
				continue
			var l: float = (sk.get_bone_rest(sk.find_bone("LeftForeArm")).origin).length()
			var m: Dictionary = {}
			for c in ["Left", "Right"]:
				m[c + "S"] = _os98(sk, c + "Arm")
				m[c + "E"] = _os98(sk, c + "ForeArm")
				m[c + "W"] = _os98(sk, c + "Hand")
			var ch: Vector3 = _os98(sk, "Spine")
			var ve: Vector3 = _os98(sk, "Spine02")
			var hi: Vector3 = _os98(sk, "Hips")
			# le défaut d'avant : le coude le long du corps, la main au-dessus du coude et en dehors
			for c2 in ["Left", "Right"]:
				var s: Vector3 = m[c2 + "S"]
				var e: Vector3 = m[c2 + "E"]
				var w: Vector3 = m[c2 + "W"]
				if e.y < s.y - 0.5 * l and w.y > e.y + 0.4 * l and absf(w.x - ch.x) > absf(e.x - ch.x) + 0.3 * l:
					defaut.append("%s (%s)" % [pose, c2])
			var wl: Vector3 = m["LeftW"]
			var wr: Vector3 = m["RightW"]
			match pose:
				"bras_croises":
					_ok(wl.x < ch.x - 0.1 * l and wr.x > ch.x + 0.1 * l, "%s, bras croisés : chaque main de l'autre côté de la poitrine (%.2f, %.2f L)" % [corps, (wl.x - ch.x) / l, (wr.x - ch.x) / l])
					_ok(wl.z > ch.z + 0.3 * l and wr.z > ch.z + 0.3 * l, "%s, bras croisés : devant la poitrine (%.2f, %.2f L)" % [corps, (wl.z - ch.z) / l, (wr.z - ch.z) / l])
					_ok(wl.y < m["LeftS"].y and wl.y > m["LeftS"].y - 1.3 * l and wr.y < m["RightS"].y and wr.y > m["RightS"].y - 1.3 * l, "%s, bras croisés : entre la taille et les épaules" % corps)
				"assis":
					var ok_a: bool = true
					for c3 in ["Left", "Right"]:
						var cu: Vector3 = _os98(sk, c3 + "UpLeg")
						var w3: Vector3 = m[c3 + "W"]
						ok_a = ok_a and w3.z > cu.z + 0.4 * l and w3.y > cu.y - 0.15 * l and w3.y < cu.y + 0.9 * l and absf(w3.x - cu.x) < 0.5 * l
					_ok(ok_a, "%s, assis : les mains sur les cuisses" % corps)
				"colere":
					var ok_c: bool = absf(wl.y - hi.y) < 0.6 * l and absf(wr.y - hi.y) < 0.6 * l and absf(wl.z - hi.z) < 0.45 * l and absf(wr.z - hi.z) < 0.45 * l
					ok_c = ok_c and wl.x - hi.x > 0.35 * l and hi.x - wr.x > 0.35 * l
					_ok(ok_c, "%s, en colère : les poings sur les hanches (gauche %s L)" % [corps, str(((wl - hi) / l).snapped(Vector3.ONE * 0.01))])
				"mains_dos":
					_ok(wl.z < ve.z - 0.3 * l and wr.z < ve.z - 0.3 * l and absf(wl.x - ve.x) < 0.6 * l and absf(wr.x - ve.x) < 0.6 * l, "%s, les mains dans le dos (%.2f, %.2f L)" % [corps, (wl.z - ve.z) / l, (wr.z - ve.z) / l])
				"applaudir":
					_ok(wl.distance_to(wr) < 0.8 * l and wl.z > ch.z + 0.5 * l, "%s, applaudir : les mains ensemble devant soi (%.2f L)" % [corps, wl.distance_to(wr) / l])
				"comptoir":
					_ok(wl.z > ch.z + 0.5 * l and wr.z > ch.z + 0.5 * l and wl.y < m["LeftS"].y and wr.y < m["RightS"].y, "%s, au comptoir : les avant-bras devant soi" % corps)
		_ok(defaut.is_empty(), "%s : aucune pose n'a le bras pendant et la main levée en dehors (%s)" % [corps, str(defaut)])
		for f2 in gens:
			f2.npc.queue_free()
		await _images(3)
	lieu.queue_free()
