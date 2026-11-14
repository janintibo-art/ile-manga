extends Node3D
## V143 : la magie élémentaire. Le feu, la glace, la foudre et l'eau laissent une trace sur
## l'ennemi qu'ils touchent, et ces traces réagissent entre elles :
##  - en feu (boule de feu, épée naine) : il brûle quelques secondes (un point par seconde) ;
##  - gelé (sort de gel) : pris dans la glace, il ne bouge plus ; un coup d'arme le « brise »
##    (dégâts doublés) ;
##  - trempé (trident des marées) : la foudre le traverse (dégâts doublés), le gel le prend
##    « à cœur » (plus longtemps), le feu ne prend pas ;
##  - le feu sur la glace (ou la glace sur le feu) : « Vapeur ! », un nuage brûlant qui touche
##    tout autour ; la foudre sur la glace : « Éclats ! » ; la foudre sur le feu :
##    « Surcharge ! » ; la Bourrasque des sceaux sur un ennemi en feu : « Attisé ! », le feu
##    saute sur ses voisins.
## Chaque famille de créatures a ses faiblesses (dégâts × 1,5) et ses résistances (× 0,5) :
## les plantes et les ombres craignent le feu, les bêtes de l'eau, les machines et tout ce qui
## vole craignent la foudre, les créatures de feu craignent la glace et l'eau…
## Le septième sort, la Foudre (l'archimage d'Arcanelle, après le diplôme), part d'ici :
## un éclair qui saute d'un ennemi à l'autre.

const FAMILLES := {
	"feu": ["salamandre", "magma", "phalene_braise", "molosse_cendre", "chien_enfer", "diablotin", "gorgoth", "cerbere", "feu_follet", "furie", "tomate_kamikaze"],
	"glace": ["spectre_givre", "titan_givre"],
	"eau": ["crabe", "crabe_plage", "crabe_cocotier", "ondin", "garde_maree", "crocodile", "vieille_dent", "grenouille_geante", "grenouille_reine", "crapaud_vase",
		"slime", "slime_bleu", "slime_rose", "slime_roi", "axolotl", "tortue_verte", "iguane_marin", "meduse_celeste", "raie_celeste", "canard", "heron", "cipactli"],
	"plante": ["plante", "plante_mere", "ronceux", "ronceux_sauvage", "champignard", "champignard_roi", "navet", "spaghetti_sauvage"],
	"metal": ["armure", "automate", "colosse", "gardien", "robot_demenageur", "drone_huissier", "robot_soudeur", "pelleteuse_mini", "grande_pelleteuse"],
	"pierre": ["golem", "gargouille", "jaguar_pierre"],
	"ombre": ["spectre", "ombre", "squelette", "capitaine_os", "momie", "zombie", "zombie_coureur", "zombie_lourd", "vampire", "vampire_garde", "ilona", "sigismund",
		"radu", "mortimer", "dracula", "loup_brumes"],
	"vol": ["follet", "chauve_souris", "camazotz", "pteranodon"],
}
## famille -> élément -> multiplicateur des dégâts
const AFFINITES := {
	"feu": {"feu": 0.5, "glace": 1.5, "eau": 1.5},
	"glace": {"feu": 1.5, "glace": 0.5},
	"eau": {"foudre": 1.5, "feu": 0.5},
	"plante": {"feu": 1.5},
	"metal": {"foudre": 1.5, "feu": 0.5},
	"pierre": {"foudre": 0.5, "feu": 0.5, "glace": 1.5},
	"ombre": {"feu": 1.5, "glace": 0.5},
	"vol": {"foudre": 1.5},
}
const COULEURS := {"feu": Color(1.0, 0.55, 0.2), "glace": Color(0.65, 0.88, 1.0), "foudre": Color(0.8, 0.82, 1.0), "eau": Color(0.35, 0.8, 1.0)}
const NOMS := {"feu": "feu", "glace": "glace", "foudre": "foudre", "eau": "eau"}
## les âmes des armes (armes_v129) qui portent un élément
const AMES := {"forge": "feu", "foudre": "foudre", "maree": "eau"}
const BRULE_COUPS: int = 4
const GEL_TEMPS: float = 3.5
const TREMPE_TEMPS: float = 7.0
const CONSEILS := {
	"vapeur": "Vapeur ! Le feu sur un ennemi gelé (ou la glace sur un ennemi en feu) fait un nuage brûlant qui touche tout autour.",
	"brise": "Brisé ! Un ennemi gelé frappé avec une arme prend le double.",
	"eclats": "Éclats ! La foudre fait voler la glace en morceaux : ceux qui sont autour sont touchés.",
	"surcharge": "Surcharge ! La foudre sur un ennemi en feu fait tout sauter autour de lui.",
	"electrocute": "Électrocuté ! La foudre fait deux fois plus mal à un ennemi trempé.",
	"attise": "Attisé ! Le vent pousse le feu : il saute sur les ennemis voisins.",
	"gel_coeur": "Gelé à cœur ! Un ennemi trempé gèle bien plus longtemps.",
	"faible": "Faiblesse ! Chaque créature craint un élément : le feu pour les plantes et les ombres, la foudre pour les bêtes de l'eau, les machines et ce qui vole, la glace pour les créatures de feu.",
}

var main: Node
var vus: Dictionary = {}                 # conseils déjà donnés (sauvegardé)
var reactions: Dictionary = {}           # tests : réaction -> nombre
var last_reaction: String = ""
var last_mult: float = 1.0
var last_chain: Array = []               # tests : les ennemis touchés par le dernier éclair
var _st: Dictionary = {}                 # id d'instance -> {node, genre, t, tick, coups, fx}
var _famille: Dictionary = {}

static var _coque_mat: StandardMaterial3D


func setup(main_node: Node) -> void:
	main = main_node
	for f in FAMILLES:
		for k in FAMILLES[f]:
			_famille[str(k)] = str(f)


# =================================================================== familles et affinités

func famille(m: Node) -> String:
	if m == null or not is_instance_valid(m):
		return ""
	var k: String = str(m.get("kind"))
	if _famille.has(k):
		return str(_famille[k])
	var sp: Variant = m.get("spec")
	if sp is Dictionary and bool((sp as Dictionary).get("vol", false)):
		return "vol"
	return ""


func affinite(m: Node, element: String) -> float:
	return float((AFFINITES.get(famille(m), {}) as Dictionary).get(element, 1.0))


## La faiblesse d'une créature (pour l'afficher) : "" si elle n'en a pas.
func faiblesse(m: Node) -> String:
	var a: Dictionary = AFFINITES.get(famille(m), {})
	for e in a:
		if float(a[e]) > 1.0:
			return str(e)
	return ""


func etat(m: Node) -> String:
	if m == null or not is_instance_valid(m):
		return ""
	return str((_st.get(m.get_instance_id(), {}) as Dictionary).get("genre", ""))


func _vivant(m: Variant) -> bool:
	return m != null and is_instance_valid(m) and str((m as Node).get("state")) != "mort"


func _boss(m: Node) -> bool:
	if m.has_method("is_boss") and bool(m.is_boss()):
		return true
	var sp: Variant = m.get("spec")
	return sp is Dictionary and bool((sp as Dictionary).get("boss", false))


func _centre(m: Node3D) -> Vector3:
	return m.global_position + Vector3.UP * maxf(float(m.get("hit_height")), 0.3)


func _monstres() -> Array:
	var out: Array = []
	for g in ["monstres_v36", "faune_v132"]:
		for m in get_tree().get_nodes_in_group(g):
			if _vivant(m) and not out.has(m):
				out.append(m)
	return out


func _texte(m: Node3D, t: String, col: Color, haut: float = 1.0) -> void:
	var cb: Node = main.get("combat_v28")
	if cb != null:
		cb.float_text(_centre(m) + Vector3.UP * (float(m.get("hit_height")) + haut), t, col)


func _compte(r: String) -> void:
	reactions[r] = int(reactions.get(r, 0)) + 1
	last_reaction = r
	if CONSEILS.has(r) and not vus.has(r):
		vus[r] = true
		main._show_message_v28(str(CONSEILS[r]))


func _coup(m: Node, dmg: int, from: Vector3, fort: bool) -> void:
	var cb: Node = main.get("combat_v28")
	var old: bool = bool(cb.critical) if cb != null else false
	if cb != null and fort:
		cb.critical = true
	m.take_hit(dmg, from)
	if cb != null:
		cb.critical = old


# =================================================================== un coup élémentaire

## Un sort (ou une arme) touche m avec un élément. Renvoie les dégâts portés.
func hit(m: Node3D, element: String, dmg: int, from: Vector3, arme: bool = false) -> int:
	if not _vivant(m):
		return 0
	var mult: float = affinite(m, element)
	var e0: String = etat(m)
	var reac: String = ""
	match element:
		"feu":
			if e0 == "gele":
				reac = "vapeur"
				mult *= 1.5
			elif e0 == "trempe":
				reac = "seche"
				mult *= 0.5
		"glace":
			if e0 == "brule":
				reac = "vapeur"
			elif e0 == "trempe":
				reac = "gel_coeur"
		"foudre":
			if e0 == "trempe":
				reac = "electrocute"
				mult *= 2.0
			elif e0 == "gele":
				reac = "eclats"
				mult *= 1.5
			elif e0 == "brule":
				reac = "surcharge"
	last_mult = mult
	var total: int = maxi(1, roundi(float(dmg) * mult))
	var at: Vector3 = _centre(m)
	var aff: float = affinite(m, element)
	_coup(m, total, from, mult > 1.01)
	var col: Color = COULEURS.get(element, Color.WHITE)
	# (le mot ne revient pas à chaque coup d'une arme : toutes les trois secondes au plus)
	var now: int = Time.get_ticks_msec()
	var dit: bool = now - int(m.get_meta("el_dit_v143", -99999)) > 3000
	if aff > 1.01:
		_compte("faible")
		if dit:
			m.set_meta("el_dit_v143", now)
			_texte(m, "Faiblesse !", col, 0.75)
	elif aff < 0.99:
		reactions["resiste"] = int(reactions.get("resiste", 0)) + 1
		if dit:
			m.set_meta("el_dit_v143", now)
			_texte(m, "Résiste…", Color(0.72, 0.72, 0.72), 0.75)
	# la réaction (elle a lieu même si le coup l'a achevé)
	match reac:
		"vapeur":
			_efface(m)
			_vapeur(at, m)
		"seche":
			_efface(m)
			_bouffee(at, Color(0.9, 0.95, 1.0, 0.3), 5)
		"eclats":
			_efface(m)
			_eclats(at, m)
		"surcharge":
			_surcharge(at, m)
		"electrocute":
			_compte("electrocute")
			_arcs(at, 7)
			main.sfx("electrocute", at)
			if _vivant(m):
				_texte(m, "Électrocuté !", COULEURS["foudre"])
	if not _vivant(m):
		_efface(m)
		return total
	match element:
		"feu":
			if reac == "" and famille(m) != "feu":
				enflammer(m)
		"glace":
			if reac == "vapeur":
				pass
			elif famille(m) == "glace":
				_texte(m, "Insensible au froid", Color(0.72, 0.72, 0.72), 0.4)
			else:
				geler(m, GEL_TEMPS * (1.7 if reac == "gel_coeur" else 1.0))
				if reac == "gel_coeur":
					_compte("gel_coeur")
					_texte(m, "Gelé à cœur !", col)
				else:
					_texte(m, "Gelé !", col)
		"foudre":
			if not arme:
				_secouer(m, 0.8)
		"eau":
			if e0 == "brule":
				_efface(m)
				_bouffee(at, Color(0.9, 0.95, 1.0, 0.3), 5)
				main.sfx("vapeur_feu", at)
			elif e0 == "":
				tremper(m)
	return total


func _secouer(m: Node, t: float) -> void:
	if _boss(m):
		t *= 0.5
	if m.has_method("stun"):
		m.stun(t)
	else:
		m.set("state", "recul")
		m.set("timer", t)


# =================================================================== les états

func _pose(m: Node3D, genre: String, t: float) -> Dictionary:
	_efface(m)
	var e := {"node": m, "genre": genre, "t": t, "tick": 1.0, "coups": 0, "fx": [], "image": Engine.get_process_frames()}
	_st[m.get_instance_id()] = e
	return e


func _efface(m: Variant) -> void:
	if m == null or not is_instance_valid(m):
		return
	var id: int = (m as Node).get_instance_id()
	if not _st.has(id):
		return
	for n in (_st[id]["fx"] as Array):
		if is_instance_valid(n):
			(n as Node).queue_free()
	_st.erase(id)


func enflammer(m: Node3D, coups: int = BRULE_COUPS) -> void:
	if not _vivant(m) or famille(m) == "feu":
		return
	if etat(m) == "brule":
		var e0: Dictionary = _st[m.get_instance_id()]
		e0["coups"] = maxi(int(e0["coups"]), coups)
		return
	var fam: String = famille(m)
	if fam == "plante":
		coups += 2
	elif fam == "eau":
		coups = maxi(coups - 2, 1)
	var e: Dictionary = _pose(m, "brule", 999.0)
	e["coups"] = coups
	var fx: Node = main.get("combat_fx_v129")
	var r: float = maxf(float(m.get("hit_radius")), 0.3)
	var h: float = maxf(float(m.get("hit_height")), 0.3)
	if fx != null:
		var f1: Node = fx._burst(Vector3.UP * h * 0.8, {"amount": 44, "life": 0.7, "v0": 0.5, "v1": 1.6, "dir": Vector3.UP, "spread": 30.0, "radius": r * 1.05,
			"grav": Vector3(0, 3.5, 0), "size": 0.5 * clampf(r * 1.6, 0.7, 2.4), "explo": 0.0, "loop": true, "parent": m,
			"cols": [Color(1, 0.95, 0.6), Color(1.0, 0.6, 0.15, 0.9), Color(0.9, 0.25, 0.05, 0.5), Color(0.3, 0.08, 0.03, 0.0)]})
		var f2: Node = fx._burst(Vector3.UP * h, {"amount": 14, "life": 0.9, "v0": 0.6, "v1": 1.8, "dir": Vector3.UP, "spread": 40.0, "radius": r * 0.6,
			"grav": Vector3(0, 1.0, 0), "size": 0.07, "mesh": "streak", "explo": 0.0, "loop": true, "parent": m,
			"cols": [Color(1, 0.9, 0.5), Color(1.0, 0.45, 0.1), Color(1.0, 0.3, 0.05, 0.0)]})
		(e["fx"] as Array).append_array([f1, f2])
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.55, 0.2)
	l.light_energy = 1.4
	l.omni_range = 3.5 + r * 2.0
	l.shadow_enabled = false
	m.add_child(l)
	l.position = Vector3.UP * h
	(e["fx"] as Array).append(l)
	main.sfx("brulure", _centre(m))
	_texte(m, "En feu !", COULEURS["feu"])


func geler(m: Node3D, t: float = GEL_TEMPS) -> void:
	if not _vivant(m) or famille(m) == "glace":
		return
	if _boss(m):
		t *= 0.5
	var e: Dictionary = _pose(m, "gele", t)
	if m.has_method("stun"):
		m.stun(t)
	else:
		m.set("state", "recul")
		m.set("timer", t)
	(e["fx"] as Array).append(_coque(m))


## La gangue de glace : une coque translucide et des cristaux plantés tout autour.
func _coque(m: Node3D) -> Node3D:
	var root := Node3D.new()
	root.name = "Glace_v143"
	var r: float = maxf(float(m.get("hit_radius")), 0.3)
	var h: float = maxf(float(m.get("hit_height")), 0.3)
	if _coque_mat == null:
		_coque_mat = StandardMaterial3D.new()
		_coque_mat.albedo_color = Color(0.7, 0.9, 1.0, 0.34)
		_coque_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_coque_mat.roughness = 0.04
		_coque_mat.metallic_specular = 0.9
		_coque_mat.rim_enabled = true
		_coque_mat.rim = 1.0
		_coque_mat.rim_tint = 0.3
		_coque_mat.emission_enabled = true
		_coque_mat.emission = Color(0.3, 0.6, 1.0)
		_coque_mat.emission_energy_multiplier = 0.35
		_coque_mat.cull_mode = BaseMaterial3D.CULL_BACK
	var shell := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 1.0
	sm.height = 2.0
	sm.radial_segments = 10
	sm.rings = 5
	shell.mesh = sm
	shell.material_override = _coque_mat
	shell.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	shell.scale = Vector3(r * 1.3, h * 0.72 + 0.12, r * 1.3)
	shell.position = Vector3.UP * (h * 0.68 + 0.05)
	root.add_child(shell)
	var fx: Node = main.get("combat_fx_v129")
	if fx != null:
		var mesh: ArrayMesh = fx.ice_mesh()
		var n: int = 7
		for k in range(n):
			var a: float = TAU * k / n + randf_range(-0.25, 0.25)
			var mi := MeshInstance3D.new()
			mi.mesh = mesh
			mi.material_override = fx._ice_mat
			var sz: float = randf_range(0.55, 0.95) * clampf(r * 1.3 + h * 0.4, 0.5, 2.6)
			mi.scale = Vector3(sz, sz * randf_range(0.8, 1.3), sz)
			mi.position = Vector3(cos(a), 0, sin(a)) * r * 1.1
			mi.rotation = Vector3(sin(a) * 0.35, randf() * TAU, -cos(a) * 0.35)
			root.add_child(mi)
	m.add_child(root)
	return root


func tremper(m: Node3D, t: float = TREMPE_TEMPS) -> void:
	if not _vivant(m):
		return
	var e: Dictionary = _pose(m, "trempe", t)
	var fx: Node = main.get("combat_fx_v129")
	var r: float = maxf(float(m.get("hit_radius")), 0.3)
	var h: float = maxf(float(m.get("hit_height")), 0.3)
	if fx != null:
		var f: Node = fx._burst(Vector3.UP * h * 1.5, {"amount": 22, "life": 0.6, "v0": 0.0, "v1": 0.3, "dir": Vector3.DOWN, "spread": 30.0, "radius": r * 1.0,
			"grav": Vector3(0, -7.0, 0), "size": 0.13, "mesh": "streak", "explo": 0.0, "loop": true, "parent": m,
			"cols": [Color(0.75, 0.95, 1.0), Color(0.35, 0.8, 1.0, 0.8), Color(0.3, 0.7, 1.0, 0.0)]})
		(e["fx"] as Array).append(f)
	_texte(m, "Trempé !", COULEURS["eau"])


# =================================================================== les réactions

func _bouffee(at: Vector3, col: Color, n: int) -> void:
	var fx: Node = main.get("combat_fx_v129")
	if fx != null:
		fx._puffs(at, n, col, 0.4, 1.6, 1.2, 0.5, 1.6, 0.8, 0.3)


func _autour(at: Vector3, sauf: Node, rayon: float, dmg: int) -> int:
	var n: int = 0
	for o in _monstres():
		if o == sauf:
			continue
		var c: Vector3 = _centre(o)
		if Vector2(c.x - at.x, c.z - at.z).length() - float(o.get("hit_radius")) <= rayon and absf(c.y - at.y) < 3.0:
			_coup(o, dmg, at, false)
			n += 1
	return n


func _vapeur(at: Vector3, m: Node3D) -> void:
	_compte("vapeur")
	main.sfx("vapeur_feu", at)
	var fx: Node = main.get("combat_fx_v129")
	if fx != null:
		fx._n("vapeur")
		fx._puffs(at, 16, Color(0.95, 0.97, 1.0, 0.42), 0.6, 2.6, 1.5, 1.2, 3.2, 0.6, 0.4)
		var rg: MeshInstance3D = fx._flat(Vector3(at.x, fx._ground_y(at, at.y - 1.0) + 0.06, at.z), Vector3.UP, fx.ring_tex(), Color(0.9, 0.96, 1.0, 0.45), 1.0)
		fx._add(rg, 0.5, Color(0.9, 0.96, 1.0, 0.45), rg.get_meta("mat"), 0.5, 5.5)
		fx._light(at, Color(0.9, 0.95, 1.0), 2.0, 6.0, 0.4)
	_autour(at, m, 3.5, 2)
	if _vivant(m):
		_texte(m, "Vapeur !", Color(0.92, 0.97, 1.0))
	else:
		var cb: Node = main.get("combat_v28")
		if cb != null:
			cb.float_text(at + Vector3.UP * 1.2, "Vapeur !", Color(0.92, 0.97, 1.0))


func _eclats(at: Vector3, m: Node3D) -> void:
	_compte("eclats")
	main.sfx("brise_glace", at)
	var fx: Node = main.get("combat_fx_v129")
	if fx != null:
		fx._n("eclats")
		fx._burst(at, {"amount": 26, "life": 0.8, "v0": 4.0, "v1": 9.0, "dir": Vector3.UP, "spread": 110.0, "grav": Vector3(0, -9.0, 0),
			"size": 0.09, "mesh": "box", "add": false, "cols": [Color(0.85, 0.95, 1.0), Color(0.7, 0.88, 1.0)]})
		fx._light(at, Color(0.7, 0.85, 1.0), 4.0, 7.0, 0.35)
	_autour(at, m, 3.0, 2)
	if _vivant(m):
		_texte(m, "Éclats !", COULEURS["glace"])


func _surcharge(at: Vector3, m: Node3D) -> void:
	_compte("surcharge")
	main.sfx("explosion_feu", at)
	var fx: Node = main.get("combat_fx_v129")
	if fx != null:
		fx.explosion(at)
	_arcs(at, 6)
	_autour(at, m, 3.0, 2)
	if _vivant(m):
		_texte(m, "Surcharge !", Color(1.0, 0.8, 0.5))


func _arcs(at: Vector3, n: int) -> void:
	var fx: Node = main.get("combat_fx_v129")
	if fx != null:
		fx._bolts(at, Color(1, 1, 1), Color(0.55, 0.7, 1.0), n)


## La Bourrasque des sceaux passe sur m : le feu s'attise et saute sur les voisins.
func on_wind(m: Node3D, _from: Vector3) -> void:
	if etat(m) != "brule" or not _vivant(m):
		return
	var e: Dictionary = _st[m.get_instance_id()]
	# (celui que le vent vient d'enflammer à l'instant ne rallume pas les autres)
	if int(e["image"]) == Engine.get_process_frames():
		return
	e["coups"] = int(e["coups"]) + 2
	var n: int = 0
	var at: Vector3 = _centre(m)
	for o in _monstres():
		if o == m or etat(o) != "" or famille(o) == "feu":
			continue
		if _centre(o).distance_to(at) <= 5.5:
			enflammer(o, 3)
			n += 1
	_compte("attise")
	_texte(m, "Attisé !", COULEURS["feu"])
	var fx: Node = main.get("combat_fx_v129")
	if fx != null:
		fx._burst(at, {"amount": 20, "life": 0.6, "v0": 3.0, "v1": 7.0, "grav": Vector3(0, 1.0, 0), "size": 0.14, "mesh": "streak", "damping": 2.0,
			"cols": [Color(1, 0.95, 0.6), Color(1.0, 0.5, 0.1), Color(1.0, 0.3, 0.05, 0.0)]})


# =================================================================== les armes

## Un coup d'arme sur target (combat_v28) : la glace se brise, l'âme de l'arme porte son élément.
func weapon_hit(target: Node3D, damage: int, from: Vector3) -> void:
	if not (target.is_in_group("monstres_v36") or target.is_in_group("faune_v132")) or not _vivant(target):
		target.take_hit(damage, from)
		return
	var inv: Node = main.get("inventory_v28")
	var arme: String = str(inv.equipped) if inv != null else ""
	var genre: String = str(preload("res://scripts/armes_v129.gd").ame(arme).get("genre", ""))
	var element: String = str(AMES.get(genre, ""))
	if etat(target) == "gele":
		var at: Vector3 = _centre(target)
		_efface(target)
		_compte("brise")
		main.sfx("brise_glace", at)
		var fx: Node = main.get("combat_fx_v129")
		if fx != null:
			fx._n("brise")
			fx._burst(at, {"amount": 22, "life": 0.8, "v0": 3.0, "v1": 7.0, "dir": Vector3.UP, "spread": 100.0, "grav": Vector3(0, -9.0, 0),
				"size": 0.08, "mesh": "box", "add": false, "cols": [Color(0.85, 0.95, 1.0), Color(0.7, 0.88, 1.0)]})
		_texte(target, "Brisé !", COULEURS["glace"])
		_coup(target, damage * 2, from, true)
		return
	if element == "":
		target.take_hit(damage, from)
		return
	hit(target, element, damage, from, true)
	# l'épée des nuées : un arc saute sur l'ennemi le plus proche
	if element == "foudre" and _vivant(target):
		var o: Node3D = _voisin(_centre(target), [target], 4.5)
		if o != null:
			eclair(_centre(target), _centre(o), 0.6)
			hit(o, "foudre", 1, _centre(target), true)


func _voisin(at: Vector3, sauf: Array, rayon: float) -> Node3D:
	var best: Node3D = null
	var bd: float = rayon
	for o in _monstres():
		if sauf.has(o):
			continue
		var d: float = _centre(o).distance_to(at) - float(o.get("hit_radius"))
		if d < bd:
			bd = d
			best = o
	return best


# =================================================================== la Foudre (le sort)

## L'éclair part de o vers dir : il frappe l'ennemi visé (5), puis saute sur deux voisins (3, 2).
## Sans ennemi, il frappe le sol devant soi. Renvoie le point frappé.
func foudre(o: Vector3, dir: Vector3) -> Vector3:
	last_chain = []
	var best: Node3D = null
	var bs: float = INF
	for m in _monstres():
		var c: Vector3 = _centre(m)
		var off: Vector3 = c - o
		var d: float = off.length()
		if d > 18.0:
			continue
		var ang: float = rad_to_deg(dir.angle_to(off.normalized())) if d > 0.8 else 0.0
		if ang > 32.0:
			continue
		var s: float = d + ang * 0.35
		if s < bs:
			bs = s
			best = m
	var at: Vector3
	if best == null:
		at = o + dir * 11.0
		var q := PhysicsRayQueryParameters3D.create(o, o + dir * 16.0 + Vector3.DOWN * 4.0, 1)
		var ex: Array = []
		for b in [main.get("pc_body"), main.get("vr_body")]:
			if b != null and is_instance_valid(b):
				ex.append(b.get_rid())
		q.exclude = ex
		var hit_d: Dictionary = get_world_3d().direct_space_state.intersect_ray(q)
		if not hit_d.is_empty():
			at = hit_d.position
		eclair(o, at, 1.0)
		_frappe_fx(at)
		return at
	at = _centre(best)
	eclair(o, at, 1.0)
	_frappe_fx(at)
	var prev: Vector3 = at
	var touches: Array = [best]
	last_chain.append(best)
	hit(best, "foudre", 5, o)
	for dmg in [3, 2]:
		var nx: Node3D = _voisin(prev, touches, 7.0)
		if nx == null:
			break
		var c2: Vector3 = _centre(nx)
		eclair(prev, c2, 0.7)
		touches.append(nx)
		last_chain.append(nx)
		hit(nx, "foudre", dmg, prev)
		prev = c2
	return at


func _frappe_fx(at: Vector3) -> void:
	var fx: Node = main.get("combat_fx_v129")
	if fx == null:
		return
	fx._n("foudre")
	var fl: MeshInstance3D = fx._quad(at, preload("res://scripts/armes_v129.gd").dot(), Color(0.85, 0.9, 1.0), 1.0)
	fx._add(fl, 0.22, Color(0.85, 0.9, 1.0), fl.get_meta("mat"), 0.6, 2.6)
	fx._bolts(at, Color(1, 1, 1), Color(0.55, 0.7, 1.0), 6)
	fx._burst(at, {"amount": 16, "life": 0.45, "v0": 3.0, "v1": 8.0, "grav": Vector3(0, -6.0, 0), "size": 0.12, "mesh": "streak", "damping": 2.0,
		"cols": [Color(1, 1, 1), Color(0.7, 0.8, 1.0), Color(0.5, 0.6, 1.0, 0.0)]})
	fx._light(at, Color(0.75, 0.82, 1.0), 7.0, 11.0, 0.3)
	var d: float = at.distance_to(fx._player_pos())
	if d < 16.0:
		fx.shake(0.06 * (1.0 - d / 16.0) + 0.015)
		fx.haptic(0.6, 0.1)


## Un éclair brisé de a à b : un cœur blanc, un halo bleu, deux ou trois branches.
func eclair(a: Vector3, b: Vector3, gros: float = 1.0) -> void:
	var fx: Node = main.get("combat_fx_v129")
	var im := ImmediateMesh.new()
	var mi := MeshInstance3D.new()
	mi.mesh = im
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = m
	add_child(mi)
	mi.global_position = Vector3.ZERO
	var lg: float = a.distance_to(b)
	var n: int = clampi(int(lg / 0.7), 4, 22)
	var axe: Vector3 = (b - a).normalized() if lg > 0.01 else Vector3.FORWARD
	var s1: Vector3 = axe.cross(Vector3.UP if absf(axe.y) < 0.9 else Vector3.RIGHT).normalized()
	var s2: Vector3 = axe.cross(s1).normalized()
	var pts: Array = [a]
	for i in range(1, n):
		var k: float = float(i) / n
		var amp: float = minf(lg * 0.07, 0.55) * sin(k * PI) + 0.05
		pts.append(a.lerp(b, k) + s1 * randf_range(-amp, amp) + s2 * randf_range(-amp, amp))
	pts.append(b)
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	_ruban(im, pts, 0.028 * gros, Color(1, 1, 1, 1))
	_ruban(im, pts, 0.1 * gros, Color(0.5, 0.65, 1.0, 0.4))
	for br in range(2 + int(lg / 6.0)):
		var i0: int = randi_range(1, pts.size() - 2)
		var p: Vector3 = pts[i0]
		var d: Vector3 = (axe + s1 * randf_range(-1.2, 1.2) + s2 * randf_range(-1.2, 1.2)).normalized()
		var bp: Array = [p]
		for j in range(1, 5):
			p += d * randf_range(0.2, 0.45) + Vector3(randf_range(-0.12, 0.12), randf_range(-0.12, 0.12), randf_range(-0.12, 0.12))
			bp.append(p)
		_ruban(im, bp, 0.018 * gros, Color(0.9, 0.95, 1.0, 0.9))
		_ruban(im, bp, 0.07 * gros, Color(0.5, 0.65, 1.0, 0.25))
	im.surface_end()
	if fx != null:
		fx._fx.append({"node": mi, "t": 0.0, "life": 0.16, "alpha": "none"})
	else:
		get_tree().create_timer(0.16).timeout.connect(mi.queue_free)


func _ruban(im: ImmediateMesh, pts: Array, w: float, col: Color) -> void:
	for i in range(1, pts.size()):
		var p0: Vector3 = pts[i - 1]
		var p1: Vector3 = pts[i]
		for ax in [Vector3.UP, Vector3.RIGHT, Vector3.FORWARD]:
			var o: Vector3 = (p1 - p0).cross(ax)
			if o.length() < 1e-4:
				continue
			o = o.normalized() * w
			im.surface_set_color(col)
			for v in [p0 - o, p0 + o, p1 + o, p0 - o, p1 + o, p1 - o]:
				im.surface_add_vertex(v)


# =================================================================== chaque image

func _process(delta: float) -> void:
	if _st.is_empty():
		return
	for id in _st.keys():
		var e: Dictionary = _st[id]
		var m: Variant = e["node"]
		if not _vivant(m):
			_efface(m)
			_st.erase(id)
			continue
		e["t"] = float(e["t"]) - delta
		match str(e["genre"]):
			"brule":
				e["tick"] = float(e["tick"]) - delta
				if float(e["tick"]) <= 0.0:
					e["tick"] = 1.0
					e["coups"] = int(e["coups"]) - 1
					var n3: Node3D = m
					var kn: Variant = n3.get("_knock")
					var st0: Variant = n3.get("state")
					var tm0: Variant = n3.get("timer")
					n3.take_hit(1, n3.global_position)
					# la brûlure ne repousse pas et ne coupe pas son élan
					if _vivant(n3):
						if kn != null:
							n3.set("_knock", kn)
						if st0 != null and str(n3.get("state")) == "recul" and str(st0) != "recul":
							n3.set("state", st0)
							n3.set("timer", tm0)
					if not _vivant(n3) or int(e["coups"]) <= 0:
						_efface(n3)
			"gele":
				if float(e["t"]) <= 0.0:
					var at: Vector3 = _centre(m)
					_efface(m)
					var fx: Node = main.get("combat_fx_v129")
					if fx != null:
						fx._shatter(at)
			_:
				if float(e["t"]) <= 0.0:
					_efface(m)


func reset() -> void:
	for id in _st.keys():
		_efface(_st[id]["node"])
	_st.clear()
	reactions.clear()
	last_reaction = ""


func serialize() -> Dictionary:
	return {"vus": vus.keys()}


func load_data(d: Dictionary) -> void:
	vus.clear()
	var v: Variant = d.get("vus", [])
	if v is Array:
		for k in v:
			vus[str(k)] = true
	reset()
