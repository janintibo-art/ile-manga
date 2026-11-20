extends RefCounted
## V183 : les bancs des villes de l'île de Hautefond (la ville, la Cité des Nuées, les Strates, le Dôme
## d'Azur). Pris dans de très grands maillages, l'audit des lieux de la V181 ne les voyait pas : il posait
## un tabouret sous ceux qui s'y asseyaient (devant le banc, ou dedans, les jambes dans l'assise), et les
## passants restaient assis 45 cm trop haut (sur le dossier). Chaque banc s'inscrit ici quand on le
## construit (hautefond_kit_v112.bench112, nuees_kit_v113.bench113, dome_kit_v115.bench115, les tabourets
## de la Conque) : son repère (+Z : devant), le dessus de son assise, sa largeur, l'avant et l'arrière de
## l'assise. Qui s'assied dessus, ou juste devant, y pose le bassin, 10 cm au-dessus de l'assise
## (pnj_azur_v56._arrive pour les habitants, figurant_v81._assise pour les passants).

static var _bancs: Dictionary = {}     # position arrondie -> [repère, dessus, demi-largeur, arrière, avant]


static func ajouter(xf: Transform3D, dessus: float, largeur: float, arriere: float, avant: float) -> void:
	_bancs[Vector3i((xf.origin * 10.0).round())] = [xf.orthonormalized(), dessus, largeur * 0.5, arriere, avant]


static func nombre() -> int:
	return _bancs.size()


## Le banc sous p (ou devant, à moins de 40 cm de l'assise ; p à la hauteur du sol ou de l'assise) :
## {"y" : le dessus de l'assise (dans le monde), "pos" : p ramené sur l'assise (au sol du banc),
## "avant" : la direction où l'on regarde, assis} ; {} s'il n'y en a pas.
static func sous(p: Vector3) -> Dictionary:
	var best: Dictionary = {}
	var bd: float = INF
	for b in _bancs.values():
		var xf: Transform3D = b[0]
		var l: Vector3 = xf.affine_inverse() * p
		var dessus: float = float(b[1])
		if l.y < -0.3 or l.y > dessus + 0.4:
			continue
		if absf(l.x) > float(b[2]) or l.z < float(b[3]) - 0.1 or l.z > float(b[4]) + 0.4:
			continue
		# le plus proche du milieu de l'assise (deux bancs dos à dos : celui de devant)
		var mz: float = (float(b[3]) + float(b[4])) * 0.5
		var d: float = absf(l.z - mz) + absf(l.x) * 0.1
		if d >= bd:
			continue
		bd = d
		# le bassin au milieu de l'assise, un peu vers l'arrière (le dos près du dossier) ; on garde sa place
		# le long du banc (deux personnes sur un long banc), sans dépasser les bouts
		var lx: float = clampf(l.x, -float(b[2]) + 0.3, float(b[2]) - 0.3) if float(b[2]) > 0.3 else 0.0
		var lz: float = lerpf(float(b[3]), float(b[4]), 0.42)
		best = {"y": (xf * Vector3(0, dessus, 0)).y, "pos": xf * Vector3(lx, 0, lz), "avant": (xf.basis * Vector3(0, 0, 1)).normalized()}
	return best


## La hauteur du bassin au-dessus de la racine de l'habitant, dans la pose assise « clip » (la piste du
## bassin, à l'échelle de son squelette et de son corps) ; NAN si l'on ne sait pas.
static func bassin(npc: Node3D, clip: String) -> float:
	var anim: AnimationPlayer = npc.get("anim")
	var skel: Skeleton3D = npc.get("skel")
	if anim == null or skel == null or not anim.has_animation(clip):
		return NAN
	var a: Animation = anim.get_animation(clip)
	for t in range(a.get_track_count()):
		if a.track_get_type(t) == Animation.TYPE_POSITION_3D and str(a.track_get_path(t)).ends_with(":Hips"):
			var v: Vector3 = a.position_track_interpolate(t, 0.0) * skel.motion_scale
			return (skel.global_transform * v).y - npc.global_position.y
	return NAN
