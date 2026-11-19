## Le grand contrôle des bugs visuels, V182 : les pieds au sol. Des clips du modèle avaient le bassin trop
## haut (parler au comptoir, saluer, applaudir : les pieds à 8 cm du sol ; s'allonger : à un mètre du
## sable) ; des poses construites mettaient le bassin à l'œil (coups d'épée, ramasser, jardiner, la
## batterie : les pieds dans le sol ; à genoux : en l'air ; en tailleur : les jambes 30 cm sous le sol).
## hero_v28 descend la piste du bassin de ces clips (BASSIN_V182, une seule fois : ils sont partagés) et
## calcule la hauteur du bassin des poses (_au_sol : « pieds », « genoux », « fesses »).
## On fait jouer chaque clip, figé à quelques instants, à un habitant (un vrai corps, V64), et au héros :
## le plus bas des pieds reste à la hauteur du repos (à 3,5 cm près) ; à genoux, les genoux touchent le
## sol ; en tailleur, le bassin est posé ; allongé, le dos aussi.
const NOM := "pieds182"
const PIEDS59 := ["LeftToeBase", "RightToeBase", "LeftFoot", "RightFoot"]


## La hauteur (au-dessus de la racine du personnage) du plus bas de ces os.
func _bas59(sk: Skeleton3D, base: Node3D, os: Array) -> float:
	var m: float = INF
	for nm in os:
		var b: int = sk.find_bone(str(nm))
		if b >= 0:
			m = minf(m, (sk.global_transform * sk.get_bone_global_pose(b).origin).y - base.global_position.y)
	return m


## Le clip « nom » figé à l'instant t (le personnage ne joue plus rien d'autre).
func _fige59(ap: AnimationPlayer, nom: String, t: float) -> void:
	ap.play(nom, 0.0)
	ap.seek(t, true)
	ap.pause()
	await _images(2)


## Un habitant au vrai corps : le premier dont la classe a la pose « lib/… » (vide : n'importe lequel).
func _pnj59(lib: String) -> Node3D:
	for e in testeur_v78._npcs():
		var npc: Node3D = e[1]
		var v64: Variant = npc.get("v64")
		var ap: AnimationPlayer = npc.get("anim")
		if not (v64 is Dictionary) or (v64 as Dictionary).is_empty() or ap == null or npc.get("skel") == null:
			continue
		if absf(float((v64 as Dictionary).get("scale", 1.0)) - 1.0) > 0.05:
			continue
		if lib == "" or ap.has_animation_library(lib):
			return npc
	return null


func _clips59(npc: Node3D, base: Node3D, sk: Skeleton3D, ap: AnimationPlayer, qui: String, clips: Array) -> void:
	await _fige59(ap, "v28/idle", 0.0)
	var ref: float = _bas59(sk, base, PIEDS59)
	var ech: float = sk.global_transform.basis.get_scale().y * 100.0
	for c in clips:
		var nom: String = str(c[0])
		if not _note(ap.has_animation(nom), "%s : le clip %s" % [qui, nom]):
			continue
		var lo: float = INF
		var hi: float = -INF
		for t in c[1]:
			await _fige59(ap, nom, float(t))
			var b: float = _bas59(sk, base, PIEDS59) - ref
			lo = minf(lo, b)
			hi = maxf(hi, b)
		_ok(lo > -0.035 * ech and lo < 0.035 * ech, "%s, %s : les pieds au sol (le plus bas : %+.3f m, le plus haut : %+.3f m)" % [qui, nom, lo, hi])


func _serie() -> void:
	# 1. les clips du modèle : le bassin descendu une seule fois (ils sont partagés par tous)
	var npc: Node3D = _pnj59("v56")
	if not _ok(npc != null, "un habitant au vrai corps (V64)"):
		return
	var ap: AnimationPlayer = npc.get("anim")
	var sk: Skeleton3D = npc.get("skel")
	var talk: Animation = ap.get_animation("Talk_with_Right_Hand_Open")
	var y_min: float = INF
	for t in talk.get_track_count():
		if talk.track_get_type(t) == Animation.TYPE_POSITION_3D and str(talk.track_get_path(t)).ends_with(":Hips"):
			for k in talk.track_get_key_count(t):
				y_min = minf(y_min, (talk.track_get_key_value(t, k) as Vector3).y)
	_ok(talk.has_meta("bassin_v182") and y_min > 80.0 and y_min < 86.0, "parler : le bassin descendu une fois (le plus bas de la piste : %.1f, avant 89,7)" % y_min)
	# 2. un habitant fige chaque clip, devant le joueur (son corps se construit)
	place_player_v35(npc.global_position + Vector3(0, 0.3, 4.0), Vector3(0, 0, -1))
	await _att(1.5)
	npc.set_process(false)
	npc.set_physics_process(false)
	var nom_pnj: String = str(npc.get("display_name"))
	await _clips59(npc, npc, sk, ap, nom_pnj, [
		["Talk_with_Right_Hand_Open", [0.5, 1.2, 2.0, 2.6, 3.4]], ["Formal_Bow", [1.0, 3.0, 4.3, 6.0]],
		["Motivational_Cheer", [0.0, 0.4, 5.0]], ["v56/regarder", [1.0, 3.0, 4.6]], ["v28/slash1", [0.12, 0.17, 0.22]],
		["v28/slash3", [0.16, 0.22, 0.27]], ["v28/block", [0.0]], ["v28/pickup", [0.32, 0.45]], ["v28/creuser", [0.25, 0.55, 0.85]]])
	# regarder autour de soi : sur place (le clip de marche du modèle menait 4 m plus loin)
	var avant: Vector3 = sk.get_bone_global_pose(sk.find_bone("Hips")).origin
	await _fige59(ap, "v56/regarder", 5.0)
	var apres: Vector3 = sk.get_bone_global_pose(sk.find_bone("Hips")).origin
	_ok(Vector2(apres.x - avant.x, apres.z - avant.z).length() < 5.0, "regarder autour de soi : sur place (%.1f cm)" % Vector2(apres.x - avant.x, apres.z - avant.z).length())
	# allongé (la fin du clip, là où il s'arrête) : le dos sur le sol, rien dessous
	await _fige59(ap, "v28/idle", 0.0)
	var ref: float = _bas59(sk, npc, PIEDS59)
	await _fige59(ap, "Lie_Down_Hands_Spread", ap.get_animation("Lie_Down_Hands_Spread").length - 0.05)
	var dos: float = _bas59(sk, npc, ["Hips", "Spine01", "Spine", "Head"])
	var tout: float = minf(dos, _bas59(sk, npc, PIEDS59 + ["LeftHand", "RightHand", "LeftLeg", "RightLeg"]))
	_ok(dos > 0.04 and dos < 0.2 and tout > -0.02, "allongé : le dos posé (%.2f m), rien sous le sol (%.2f m) ; avant, à un mètre" % [dos, tout])
	npc.set_process(true)
	npc.set_physics_process(true)
	# 3. à genoux, en tailleur (un habitant des Trois Soleils)
	var sol: Node3D = _pnj59("sol")
	if _ok(sol != null, "un habitant des Trois Soleils"):
		var ap2: AnimationPlayer = sol.get("anim")
		var sk2: Skeleton3D = sol.get("skel")
		place_player_v35(sol.global_position + Vector3(0, 0.3, 4.0), Vector3(0, 0, -1))
		await _att(1.5)
		sol.set_process(false)
		sol.set_physics_process(false)
		await _fige59(ap2, "v28/idle", 0.0)
		var ref2: float = _bas59(sk2, sol, PIEDS59)
		for c in [["sol/prier", 0.0], ["sol/prier", 5.0], ["sol/moudre", 0.8]]:
			await _fige59(ap2, str(c[0]), float(c[1]))
			var genoux: float = _bas59(sk2, sol, ["LeftLeg", "RightLeg"])
			var pieds: float = _bas59(sk2, sol, PIEDS59)
			_ok(genoux > 0.0 and genoux < 0.1 and pieds > -0.02 and pieds < 0.08, "%s à %.1f s : à genoux, les genoux au sol (%.2f m), les pieds aussi (%.2f m)" % [c[0], c[1], genoux, pieds])
		for c in ["sol/scribe", "sol/tisser", "sol/potier"]:
			await _fige59(ap2, c, 0.0)
			var bassin: float = _bas59(sk2, sol, ["Hips"])
			var bas: float = _bas59(sk2, sol, PIEDS59 + ["LeftLeg", "RightLeg"])
			_ok(bassin > 0.05 and bassin < 0.2 and bas > -0.02, "%s : assis en tailleur, le bassin posé (%.2f m), ni jambe ni pied sous le sol (%.2f m)" % [c, bassin, bas])
		sol.set_process(true)
		sol.set_physics_process(true)
	# 4. le héros (son propre corps, hero.glb : la grosse tête, les jambes courtes) : les coups d'épée, la
	# parade, ramasser, creuser, la réception d'un saut
	var lieu := Node3D.new()
	add_child(lieu)
	lieu.global_position = _pos() + Vector3(0, 0, -8)
	var corps: Node3D = (load("res://assets/models/characters/hero.glb") as PackedScene).instantiate()
	lieu.add_child(corps)
	var ap3: AnimationPlayer = corps.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var sk3: Skeleton3D = corps.find_children("*", "Skeleton3D", true, false)[0]
	var hl = load("res://scripts/hero_v28.gd").new()
	hl.hero = corps
	hl.anim = ap3
	hl.skel = sk3
	hl._build_animations()
	hl.free()
	await _images(2)
	await _clips59(corps, corps, sk3, ap3, "le héros", [["v28/slash1", [0.12, 0.17, 0.22]], ["v28/slash2", [0.0, 0.12, 0.17, 0.22]],
		["v28/slash3", [0.16, 0.22, 0.27]], ["v28/plonge_frappe", [0.0, 0.22]], ["v28/block", [0.0]], ["v28/pickup", [0.32, 0.45]],
		["v28/creuser", [0.25, 0.55, 0.85]], ["v28/land", [0.0]], ["Talk_with_Right_Hand_Open", [1.2, 2.6]]])
	lieu.queue_free()
