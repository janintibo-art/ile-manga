extends Node3D
## V67 : les sorts d'Arcanelle. Chaque maître de l'île en enseigne un, au bout d'une quête :
##  - Lumière (Aurélien Lumen) : une boule de lumière qui suit le héros une minute ; elle
##    éclaire les endroits sombres et réveille les runes qui dorment (la Crypte aux Runes) ;
##  - Boule de feu (Pyra Flammèche) : la Flamme des sceaux (pouvoirs_v63.gd) : elle brûle les
##    ennemis, allume les braseros, enflamme les mannequins de paille ;
##  - Gel (Borée Givrelin) : un souffle glacé en éventail ; les ennemis se figent ; sur l'eau du
##    Lac Miroir, un chemin de glace où l'on peut marcher (il fond au bout de quarante secondes) ;
##  - Lévitation (Zéphyrine Plume) : on s'élève de cinq à six mètres, on plane, on redescend
##    doucement ;
##  - Télékinésie (Théophraste Filandre) : l'objet visé, même hors de portée (un livre coincé sur
##    un toit, une pièce au fond d'un trou), vole jusqu'à la main ;
##  - Soin (Mère Sauge) : deux cœurs ; il soigne aussi les créatures blessées (la chouette).
## La magie : 10 points (15 avec le diplôme d'Arcanelle), qui reviennent d'eux-mêmes (un point
## toutes les deux secondes et demie) ; une potion de magie en rend 6, un élixir d'étoile tout.
## Le bâton de sorcier, en main, fait coûter chaque sort un point de moins.
## PC : 5, 6, 7, 8, 9, 0 choisissent le sort, V le lance, B passe au suivant.
## VR : gâchette gauche = lancer ; gâchette gauche maintenue = sort suivant.
## Les objets du monde qui réagissent aux sorts s'inscrivent avec register() :
##   {id, sort, pos (Vector3 ou Callable), radius, call (Callable), when (Callable)}

const ORDRE := ["lumiere", "feu", "gel", "levitation", "telekinesie", "soin"]
const INFO := {
	"lumiere": {"nom": "Lumière", "cout": 2, "touche": "5", "maitre": "Aurélien Lumen", "couleur": Color(1.0, 0.9, 0.55),
		"desc": "Une boule de lumière te suit une minute. Elle éclaire le noir et réveille les runes qui dorment."},
	"feu": {"nom": "Boule de feu", "cout": 3, "touche": "6", "maitre": "Pyra Flammèche", "couleur": Color(1.0, 0.5, 0.15),
		"desc": "Une boule de feu qui file droit devant : elle brûle les ennemis et allume braseros et torches."},
	"gel": {"nom": "Gel", "cout": 3, "touche": "7", "maitre": "Borée Givrelin", "couleur": Color(0.6, 0.85, 1.0),
		"desc": "Un souffle glacé : les ennemis se figent ; sur l'eau d'un lac, un chemin de glace."},
	"levitation": {"nom": "Lévitation", "cout": 3, "touche": "8", "maitre": "Zéphyrine Plume", "couleur": Color(0.85, 1.0, 0.95),
		"desc": "Tu t'élèves de cinq ou six mètres, tu planes un instant, tu redescends en douceur."},
	"telekinesie": {"nom": "Télékinésie", "cout": 2, "touche": "9", "maitre": "Théophraste Filandre", "couleur": Color(0.78, 0.6, 1.0),
		"desc": "L'objet que tu vises, même hors de portée, vole jusqu'à ta main."},
	"soin": {"nom": "Soin", "cout": 4, "touche": "0", "maitre": "Mère Sauge", "couleur": Color(0.55, 1.0, 0.6),
		"desc": "Deux cœurs rendus ; le sort soigne aussi les créatures blessées."},
}
const COOLDOWN := {"lumiere": 1.0, "feu": 0.9, "gel": 1.5, "levitation": 1.5, "telekinesie": 0.8, "soin": 2.5}
const MANA_BASE: int = 10
const MANA_DIPLOME: int = 5
const REGEN: float = 2.5
const LUMIERE_TEMPS: float = 60.0
const LEV_MONTE: float = 1.9
const LEV_PLANE: float = 2.2
const GLACE_TEMPS: float = 40.0

var main: Node
var known: Dictionary = {}
var choisi: String = ""
var mana: float = 10.0
var targets: Array = []
var casts: Dictionary = {}              # sort -> nombre de lancers (tests)
var last_hits: Array = []
var lev_t: float = -1.0                 # temps écoulé depuis le début de la lévitation (-1 : rien)
var light_t: float = 0.0
var ice: Array = []                      # {node, t}
var _cd: Dictionary = {}
var _regen: float = 0.0
var _orb: Node3D
var _orb_light: OmniLight3D
var _lit: Dictionary = {}
var _flying: Array = []                  # {node, from, uid, t}
var _vr_trig: float = -1.0
var _vr_label: Label3D
var _hud: Control
var _hud_bar: Control
var _clock: float = 0.0


func setup(main_node: Node) -> void:
	main = main_node


func knows(id: String) -> bool:
	return known.has(id)


func any_known() -> bool:
	return not known.is_empty()


func mana_max() -> int:
	var j: Node = main.get("journal_v56") if main != null else null
	return MANA_BASE + (MANA_DIPLOME if j != null and bool(j.flags.get("diplome_arc", false)) else 0)


func register(t: Dictionary) -> void:
	unregister(str(t.get("id", "")))
	targets.append(t)


func unregister(id: String) -> void:
	for i in range(targets.size() - 1, -1, -1):
		if str(targets[i].get("id", "")) == id:
			targets.remove_at(i)


func _tpos(t: Dictionary) -> Vector3:
	var p: Variant = t.get("pos", null)
	if p is Callable:
		return (p as Callable).call()
	if p is Vector3:
		return p
	return Vector3.INF


func _alive(t: Dictionary) -> bool:
	return not t.has("when") or bool((t["when"] as Callable).call())


## Un sort appris (au bout de la quête d'un maître) : il devient le sort choisi.
func learn(id: String) -> void:
	if not INFO.has(id) or known.has(id):
		return
	known[id] = true
	choisi = id
	mana = float(mana_max())
	var inf: Dictionary = INFO[id]
	main._show_message_v28("✦ Nouveau sort : %s ! (touche %s pour le choisir, V pour le lancer ; en VR, gâchette gauche)" % [str(inf["nom"]), str(inf["touche"])])
	main.sfx("sceau_eveil", _origin())
	_refresh()


func select(id: String) -> bool:
	if not known.has(id):
		return false
	choisi = id
	main.sfx("ui_clic")
	_refresh()
	return true


func next_spell() -> void:
	var owned: Array = []
	for s in ORDRE:
		if known.has(s):
			owned.append(s)
	if owned.is_empty():
		return
	var i: int = owned.find(choisi)
	select(str(owned[(i + 1) % owned.size()]))
	main._show_message_v28("Sort choisi : %s (%d de magie)" % [str(INFO[choisi]["nom"]), cost(choisi)])


func cost(id: String) -> int:
	var c: int = int(INFO[id]["cout"])
	if _staff():
		c = maxi(1, c - 1)
	return c


## Le bâton de sorcier en main ?
func _staff() -> bool:
	var inv: Node = main.get("inventory_v28") if main != null else null
	return inv != null and str(inv.equipped) == "baton_sorcier"


func add_mana(n: float) -> void:
	mana = minf(mana + n, float(mana_max()))
	_refresh()


# =================================================================== lancer

func _origin() -> Vector3:
	if main.xr_active and main.vr_body != null:
		return main.vr_body.global_position + Vector3.UP * 1.2
	if main.pc_body != null:
		return main.pc_body.global_position + Vector3.UP * 1.2
	return main._player_pos_v27() + Vector3.UP * 1.2


func _aim(flat: bool = true) -> Vector3:
	var d: Vector3
	if main.xr_active:
		d = -main.right_hand.global_basis.z
	else:
		d = main.hero_v28.facing if main.hero_v28 != null else Vector3.FORWARD
	if flat:
		d.y = 0.0
	return d.normalized() if d.length() > 0.01 else Vector3.FORWARD


## Lance le sort choisi (ou celui donné). Renvoie false s'il n'a pas pu partir.
func cast(id: String = "") -> bool:
	if id == "":
		id = choisi
	if main == null or not bool(main.game_started):
		return false
	if id == "" or not known.has(id):
		if known.is_empty():
			main._show_message_v28("Tu ne connais encore aucun sort. Les maîtres d'Arcanelle, l'île des sorciers, en enseignent six.")
		return false
	if float(_cd.get(id, 0.0)) > 0.0:
		return false
	var hero: Node = main.get("hero_v28")
	if hero != null and not main.xr_active and not (str(hero.state) in ["sol", "air", "charge"]):
		return false
	var m: Node = main.get("mer_v55")
	if m != null and bool(m.get("swimming")):
		main._show_message_v28("Pas de magie sous l'eau : les sorts se noient.")
		return false
	var c: int = cost(id)
	if mana < float(c):
		main.sfx("ui_erreur")
		main._show_message_v28("Plus assez de magie (%d / %d). Elle revient toute seule ; une potion de magie de Gustave la rend tout de suite." % [int(mana), c])
		return false
	last_hits = []
	var ok: bool = true
	match id:
		"lumiere":
			_lumiere()
		"feu":
			ok = _feu()
		"gel":
			_gel()
		"levitation":
			ok = _levitation()
		"telekinesie":
			ok = _telekinesie()
		"soin":
			_soin()
	if not ok:
		return false
	mana -= float(c)
	_cd[id] = float(COOLDOWN[id])
	casts[id] = int(casts.get(id, 0)) + 1
	if hero != null and not main.xr_active and str(hero.state) == "sol" and id != "levitation":
		hero.play_action("push", _origin() + _aim() * 3.0)
		hero.action_length = 0.42
	_refresh()
	return true


func _lumiere() -> void:
	light_t = LUMIERE_TEMPS
	main.sfx("sort_lumiere", _origin())
	if _orb == null:
		_orb = Node3D.new()
		_orb.name = "Orbe_de_lumiere_v67"
		add_child(_orb)
		var core := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.13
		sm.height = 0.26
		core.mesh = sm
		var cm := StandardMaterial3D.new()
		cm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		cm.albedo_color = Color(1.0, 0.95, 0.75)
		cm.emission_enabled = true
		cm.emission = Color(1.0, 0.88, 0.55)
		cm.emission_energy_multiplier = 4.0
		core.material_override = cm
		core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_orb.add_child(core)
		_orb_light = OmniLight3D.new()
		_orb_light.light_color = Color(1.0, 0.9, 0.65)
		_orb_light.omni_range = 11.0
		_orb_light.light_energy = 2.0
		_orb_light.shadow_enabled = not main.xr_active
		_orb.add_child(_orb_light)
		var motes := CPUParticles3D.new()
		motes.amount = 24
		motes.lifetime = 1.4
		motes.local_coords = false
		motes.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		motes.emission_sphere_radius = 0.25
		motes.gravity = Vector3(0, 0.3, 0)
		motes.initial_velocity_min = 0.05
		motes.initial_velocity_max = 0.2
		var q := QuadMesh.new()
		q.size = Vector2(0.05, 0.05)
		var mm := StandardMaterial3D.new()
		mm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		mm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		mm.albedo_color = Color(1.0, 0.92, 0.6, 0.9)
		if main.has_method("_soft_dot_v24"):
			mm.albedo_texture = main._soft_dot_v24()
		q.material = mm
		motes.mesh = q
		_orb.add_child(motes)
		_orb.global_position = _origin() + Vector3.UP * 0.6
	_orb.visible = true
	_tick_light(0.0)


func _feu() -> bool:
	var pw: Node = main.get("pouvoirs_v63")
	if pw == null:
		return false
	pw._flamme()
	return true


func _gel() -> void:
	var o: Vector3 = _origin()
	var dir: Vector3 = _aim()
	main.sfx("sort_gel", o)
	_frost_fx(o, dir)
	var pw: Node = main.get("pouvoirs_v63")
	if pw != null:
		for mo in pw._monsters():
			var n3: Node3D = mo
			if not pw._in_cone(o, dir, n3.global_position + Vector3.UP * 0.6, 10.0, 35.0):
				continue
			if mo.has_method("stun"):
				mo.stun(3.5)
			else:
				mo.set("state", "recul")
				mo.set("timer", 3.5)
			if mo.has_method("take_hit"):
				mo.take_hit(1, o)
			if main.combat_v28 != null:
				main.combat_v28.float_text(n3.global_position + Vector3.UP * 2.2, "Gelé !", Color(0.65, 0.85, 1.0))
	# sur l'eau d'un lac : un chemin de glace devant soi
	for t in targets.duplicate():
		if str(t.get("sort", "")) != "gel":
			continue
		var p: Vector3 = _tpos(t)
		if p == Vector3.INF or Vector2(p.x - o.x, p.z - o.z).length() > float(t.get("radius", 4.0)):
			continue
		if bool(t.get("lake", false)):
			_ice_path(o, dir)
		elif _alive(t):
			last_hits.append(str(t["id"]))
			(t["call"] as Callable).call()


func _ice_path(o: Vector3, dir: Vector3) -> void:
	var arc: Node = main.get("arcanelle_v67")
	if arc == null or arc.ile == null:
		return
	var ile: Node3D = arc.ile
	var y: float = ile.LAKE_Y
	var made: int = 0
	for k in range(9):
		var p: Vector3 = o + dir * (1.2 + k * 2.3)
		if not ile.in_lake(p.x, p.z):
			if made > 0:
				break
			continue
		var node := StaticBody3D.new()
		node.name = "Glace_v67"
		node.collision_layer = 1
		node.collision_mask = 0
		var cs := CollisionShape3D.new()
		var shp := CylinderShape3D.new()
		shp.radius = 1.55
		shp.height = 0.3
		cs.shape = shp
		node.add_child(cs)
		var mi := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 1.55
		cm.bottom_radius = 1.4
		cm.height = 0.3
		cm.radial_segments = 9
		mi.mesh = cm
		var mat: Material = arc.bourg.kit.mat("glace") if arc.bourg != null else null
		mi.material_override = mat
		node.add_child(mi)
		add_child(node)
		node.global_position = Vector3(p.x, y + 0.0, p.z)
		node.rotation.y = randf() * TAU
		ice.append({"node": node, "t": GLACE_TEMPS})
		made += 1
	while ice.size() > 24:
		var old: Dictionary = ice.pop_front()
		if is_instance_valid(old["node"]):
			(old["node"] as Node).queue_free()
	if made > 0:
		last_hits.append("glace_%d" % made)


func _frost_fx(o: Vector3, dir: Vector3) -> void:
	var fx := CPUParticles3D.new()
	fx.name = "Souffle_de_givre_v67"
	fx.amount = 70
	fx.lifetime = 0.9
	fx.one_shot = true
	fx.explosiveness = 0.85
	fx.local_coords = false
	fx.direction = dir
	fx.spread = 30.0
	fx.initial_velocity_min = 6.0
	fx.initial_velocity_max = 11.0
	fx.damping_min = 4.0
	fx.damping_max = 6.0
	fx.gravity = Vector3(0, -0.5, 0)
	fx.scale_amount_min = 0.5
	fx.scale_amount_max = 1.4
	var q := QuadMesh.new()
	q.size = Vector2(0.14, 0.14)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.albedo_color = Color(0.75, 0.9, 1.0, 0.8)
	if main.has_method("_soft_dot_v24"):
		m.albedo_texture = main._soft_dot_v24()
	q.material = m
	fx.mesh = q
	add_child(fx)
	fx.global_position = o + dir * 0.6
	fx.emitting = true
	get_tree().create_timer(1.5).timeout.connect(fx.queue_free)


func _levitation() -> bool:
	if lev_t >= 0.0:
		return false
	lev_t = 0.0
	main.sfx("sort_levitation", _origin())
	_sparkle(_origin() + Vector3.DOWN * 0.9, Color(0.85, 1.0, 0.95), 40)
	return true


## La lévitation en cours ?
func levitating() -> bool:
	return lev_t >= 0.0


## La vitesse verticale voulue pendant la lévitation (main : _move_player et le corps VR).
func lev_vy(vy: float, dt: float, on_floor: bool) -> float:
	if lev_t < LEV_MONTE:
		return 3.0
	if lev_t < LEV_MONTE + LEV_PLANE:
		return sin(lev_t * 3.0) * 0.25
	if on_floor:
		lev_t = -1.0
		return -0.05
	return maxf(vy - 3.0 * dt, -1.6)


func _telekinesie() -> bool:
	var inv: Node = main.get("inventory_v28")
	if inv == null:
		return false
	var o: Vector3 = _origin()
	var dir: Vector3 = _aim(false)
	var flat: Vector3 = _aim()
	var best: int = -1
	var best_s: float = INF
	for i in range(inv.pickups.size()):
		var pk: Dictionary = inv.pickups[i]
		if not is_instance_valid(pk["node"]):
			continue
		var p: Vector3 = pk["pos"]
		var off: Vector3 = p - o
		var d: float = off.length()
		if d > 26.0 or d < 0.5:
			continue
		var fo := Vector3(off.x, 0, off.z)
		var ang: float = rad_to_deg(flat.angle_to(fo.normalized())) if fo.length() > 0.3 else 0.0
		if ang > 28.0:
			continue
		var score: float = d * 0.15 + ang * (0.6 if main.xr_active and absf(dir.y) > 0.1 else 0.25)
		if str(pk["id"]) == "livre_envole":
			score -= 4.0
		for f in _flying:
			if str(f["uid"]) == str(pk["uid"]):
				score = INF
		if score < best_s:
			best_s = score
			best = i
	if best < 0:
		main._show_message_v28("La télékinésie ne trouve rien à attraper par là.")
		main.sfx("ui_erreur")
		return false
	var pk2: Dictionary = inv.pickups[best]
	main.sfx("sort_telekinesie", pk2["pos"])
	_flying.append({"node": pk2["node"], "from": pk2["pos"], "uid": str(pk2["uid"]), "t": 0.0})
	last_hits.append(str(pk2["uid"]))
	return true


func _tick_flying(delta: float) -> void:
	var inv: Node = main.get("inventory_v28")
	for i in range(_flying.size() - 1, -1, -1):
		var f: Dictionary = _flying[i]
		var node: Node3D = f["node"]
		if not is_instance_valid(node) or inv == null:
			_flying.remove_at(i)
			continue
		f["t"] = float(f["t"]) + delta
		var k: float = clampf(float(f["t"]) / 1.1, 0.0, 1.0)
		var to: Vector3 = _origin() + Vector3.DOWN * 0.3
		var from: Vector3 = f["from"]
		var p: Vector3 = from.lerp(to, smoothstep(0.0, 1.0, k)) + Vector3.UP * sin(k * PI) * 1.2
		node.global_position = p
		node.rotation.y += delta * 8.0
		for j in range(inv.pickups.size()):
			if str(inv.pickups[j]["uid"]) == str(f["uid"]):
				inv.pickups[j]["pos"] = p
				if k >= 1.0:
					inv.collect(j)
				break
		if k >= 1.0:
			_flying.remove_at(i)


func _soin() -> void:
	var o: Vector3 = _origin()
	main.sfx("sort_soin", o)
	var hero: Node = main.get("hero_v28")
	if hero != null:
		hero.heal(4)
	_sparkle(o, Color(0.55, 1.0, 0.6), 50)
	for t in targets.duplicate():
		if str(t.get("sort", "")) != "soin" or not _alive(t):
			continue
		var p: Vector3 = _tpos(t)
		if p != Vector3.INF and p.distance_to(o) < float(t.get("radius", 3.0)) + 1.0:
			last_hits.append(str(t["id"]))
			_sparkle(p, Color(0.55, 1.0, 0.6), 30)
			(t["call"] as Callable).call()


func _sparkle(at: Vector3, col: Color, n: int) -> void:
	var fx := CPUParticles3D.new()
	fx.amount = n
	fx.lifetime = 1.4
	fx.one_shot = true
	fx.explosiveness = 0.6
	fx.local_coords = false
	fx.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	fx.emission_sphere_radius = 0.6
	fx.direction = Vector3.UP
	fx.spread = 60.0
	fx.gravity = Vector3(0, 0.8, 0)
	fx.initial_velocity_min = 0.3
	fx.initial_velocity_max = 1.2
	var q := QuadMesh.new()
	q.size = Vector2(0.08, 0.08)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.albedo_color = Color(col.r, col.g, col.b, 0.9)
	if main.has_method("_soft_dot_v24"):
		m.albedo_texture = main._soft_dot_v24()
	q.material = m
	fx.mesh = q
	add_child(fx)
	fx.global_position = at
	fx.emitting = true
	get_tree().create_timer(2.0).timeout.connect(fx.queue_free)


# =================================================================== chaque image

func _process(delta: float) -> void:
	if main == null:
		return
	_clock += delta
	for k in _cd:
		_cd[k] = maxf(float(_cd[k]) - delta, 0.0)
	if bool(main.get("game_started")) and float(mana) < float(mana_max()):
		_regen += delta
		if _regen >= REGEN:
			_regen = 0.0
			mana = minf(mana + 1.0, float(mana_max()))
			_refresh()
	if lev_t >= 0.0:
		lev_t += delta
		if lev_t > 12.0:
			lev_t = -1.0
	_tick_light(delta)
	_tick_flying(delta)
	for i in range(ice.size() - 1, -1, -1):
		var e: Dictionary = ice[i]
		e["t"] = float(e["t"]) - delta
		var n: Node3D = e["node"]
		if not is_instance_valid(n):
			ice.remove_at(i)
			continue
		if float(e["t"]) < 2.0:
			n.scale = Vector3.ONE * clampf(float(e["t"]) / 2.0, 0.05, 1.0)
		if float(e["t"]) <= 0.0:
			n.queue_free()
			ice.remove_at(i)
	if _hud != null:
		_hud.visible = any_known() and not main.xr_active and bool(main.get("game_started"))
		if _hud.visible and _hud_bar != null:
			_hud_bar.queue_redraw()
	if main.xr_active and any_known():
		_vr_wrist()


func _tick_light(delta: float) -> void:
	if light_t <= 0.0 and _lit.is_empty():
		if _orb != null:
			_orb.visible = false
		return
	light_t = maxf(light_t - delta, 0.0)
	var o: Vector3 = _origin()
	if _orb != null:
		var right: Vector3 = _aim().cross(Vector3.UP).normalized()
		var want: Vector3 = o + Vector3.UP * 0.75 + right * 0.55 + Vector3(0, sin(_clock * 2.0) * 0.08, 0)
		_orb.global_position = _orb.global_position.lerp(want, clampf(delta * 6.0, 0.0, 1.0)) if delta > 0.0 else want
		_orb_light.light_energy = 2.0 * clampf(light_t / 1.5, 0.0, 1.0)
		_orb.visible = light_t > 0.0
	for t in targets.duplicate():
		if str(t.get("sort", "")) != "lumiere":
			continue
		var id: String = str(t["id"])
		var p: Vector3 = _tpos(t)
		var inside: bool = light_t > 0.0 and p != Vector3.INF and p.distance_to(o) < float(t.get("radius", 6.0))
		if inside and not _lit.has(id) and _alive(t):
			_lit[id] = true
			last_hits.append(id)
			(t["call"] as Callable).call()
		elif not inside and _lit.has(id):
			_lit.erase(id)


# =================================================================== touches et VR

## PC : 5 à 0 choisissent le sort, V le lance, B passe au suivant.
func handle_key(k: Key) -> bool:
	match k:
		KEY_V:
			if known.is_empty():
				return false
			cast()
			return true
		KEY_B:
			if known.is_empty():
				return false
			next_spell()
			return true
		KEY_5, KEY_KP_5, KEY_6, KEY_KP_6, KEY_7, KEY_KP_7, KEY_8, KEY_KP_8, KEY_9, KEY_KP_9, KEY_0, KEY_KP_0:
			var i: int = {KEY_5: 0, KEY_KP_5: 0, KEY_6: 1, KEY_KP_6: 1, KEY_7: 2, KEY_KP_7: 2, KEY_8: 3, KEY_KP_8: 3, KEY_9: 4, KEY_KP_9: 4, KEY_0: 5, KEY_KP_0: 5}[k]
			var sid: String = str(ORDRE[i])
			if not known.has(sid):
				return false
			if select(sid):
				main._show_message_v28("Sort choisi : %s (V pour le lancer, %d de magie)" % [str(INFO[sid]["nom"]), cost(sid)])
			return true
	return false


## VR : gâchette gauche = lancer ; maintenue 0,6 s = sort suivant.
func vr_tick(delta: float) -> void:
	if main == null or not main.xr_active or known.is_empty():
		return
	var m: Node = main.get("mer_v55")
	var c: Node = main.get("ciel_v54")
	if (m != null and bool(m.get("swimming"))) or (c != null and bool(c.get("riding"))):
		_vr_trig = -1.0
		return
	var down: bool = main.left_hand.get_float("trigger") > 0.7
	if down:
		if _vr_trig < 0.0:
			_vr_trig = 0.0
		_vr_trig += delta
		if _vr_trig >= 0.6 and _vr_trig - delta < 0.6:
			next_spell()
	elif _vr_trig >= 0.0:
		if _vr_trig < 0.6:
			cast()
		_vr_trig = -1.0


func _vr_wrist() -> void:
	if main.get("left_hand") == null:
		return
	if _vr_label == null:
		_vr_label = Label3D.new()
		_vr_label.font_size = 36
		_vr_label.pixel_size = 0.001
		_vr_label.outline_size = 8
		_vr_label.no_depth_test = true
		_vr_label.modulate = Color(0.75, 0.85, 1.0)
		_vr_label.position = Vector3(0, -0.02, 0.12)
		_vr_label.rotation_degrees = Vector3(-60, 0, 0)
		main.left_hand.add_child(_vr_label)
	var t: String = ""
	if choisi != "":
		t = "✦ %s  %d/%d" % [str(INFO[choisi]["nom"]), int(mana), mana_max()]
	_vr_label.text = t


# =================================================================== l'écran (PC)

func make_hud(layer: CanvasLayer) -> void:
	if layer == null:
		return
	_hud = Control.new()
	_hud.name = "Sorts_v67"
	_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_hud.offset_left = -330.0
	_hud.offset_right = -20.0
	_hud.offset_top = 150.0
	_hud.offset_bottom = 215.0
	layer.add_child(_hud)
	_hud_bar = Control.new()
	_hud_bar.position = Vector2(0, 0)
	_hud_bar.size = Vector2(310, 64)
	_hud_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_bar.draw.connect(_draw_hud)
	_hud.add_child(_hud_bar)
	_hud.visible = false


func _draw_hud() -> void:
	var w: float = _hud_bar.size.x
	var mm: int = mana_max()
	# la jauge de magie
	var bw: float = 200.0
	var x0: float = w - bw
	_hud_bar.draw_rect(Rect2(Vector2(x0, 2), Vector2(bw, 10)), Color(0, 0, 0, 0.55))
	var r: float = clampf(mana / float(mm), 0.0, 1.0)
	_hud_bar.draw_rect(Rect2(Vector2(x0 + 1, 3), Vector2((bw - 2) * r, 8)), Color(0.45, 0.62, 1.0))
	for k in range(1, mm):
		var xx: float = x0 + bw * float(k) / float(mm)
		_hud_bar.draw_line(Vector2(xx, 3), Vector2(xx, 11), Color(0, 0, 0, 0.35), 1.0)
	_hud_bar.draw_string(ThemeDB.fallback_font, Vector2(x0 - 80, 12), "Magie %d" % int(mana), HORIZONTAL_ALIGNMENT_RIGHT, 75, 13, Color(0.8, 0.88, 1.0, 0.95))
	# les sorts connus
	var x: float = w
	for i in range(ORDRE.size() - 1, -1, -1):
		var sid: String = ORDRE[i]
		if not known.has(sid):
			continue
		var big: bool = sid == choisi
		var rr: float = 15.0 if big else 10.0
		x -= rr + 3.0
		var c := Vector2(x, 36.0)
		x -= rr + 2.0
		var col: Color = INFO[sid]["couleur"]
		_hud_bar.draw_circle(c, rr + 2.0, Color(0, 0, 0, 0.6))
		var ready: bool = float(_cd.get(sid, 0.0)) <= 0.0 and mana >= float(cost(sid))
		_hud_bar.draw_circle(c, rr, col if ready else col.darkened(0.6))
		_hud_bar.draw_string(ThemeDB.fallback_font, c + Vector2(-4, 5), str(INFO[sid]["touche"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 13 if big else 10, Color(0.05, 0.05, 0.1))
	if choisi != "":
		_hud_bar.draw_string(ThemeDB.fallback_font, Vector2(x - 170, 42), "%s  [V]" % str(INFO[choisi]["nom"]), HORIZONTAL_ALIGNMENT_RIGHT, 165, 14, Color(1, 1, 1, 0.9))


func _refresh() -> void:
	if _hud_bar != null:
		_hud_bar.queue_redraw()


## La page du héros (carnet, touche H) : la magie et les sorts appris.
func page_text() -> String:
	var r: String = "[font_size=24][color=#ffd27a][b]Les sorts d'Arcanelle[/b][/color][/font_size]\n"
	r += "[b]Magie :[/b] %d / %d%s\n" % [int(mana), mana_max(), "  (bâton de sorcier en main : chaque sort coûte 1 de moins)" if _staff() else ""]
	for sid in ORDRE:
		var inf: Dictionary = INFO[sid]
		var col: String = (inf["couleur"] as Color).to_html(false)
		if known.has(sid):
			r += "[color=#%s]●[/color] [b]%s[/b] — touche %s, %d de magie%s\n[color=#9aa7b0]%s[/color]\n" % [col, str(inf["nom"]), str(inf["touche"]), cost(sid), ", choisi" if sid == choisi else "", str(inf["desc"])]
		else:
			r += "[color=#3a4a55]●[/color] [color=#9aa7b0]%s — à apprendre à Arcanelle[/color]\n" % str(inf["nom"])
	r += "[color=#9aa7b0][i]PC : 5 à 0 pour choisir un sort, V pour le lancer, B pour passer au suivant. VR : gâchette gauche pour lancer, maintenue pour changer.[/i][/color]\n"
	return r


# =================================================================== sauvegarde

func serialize() -> Dictionary:
	return {"sorts": known.keys(), "choisi": choisi, "magie": mana}


func load_data(d: Dictionary) -> void:
	known.clear()
	var v: Variant = d.get("sorts", [])
	if v is Array:
		for s in v:
			if INFO.has(str(s)):
				known[str(s)] = true
	choisi = str(d.get("choisi", ""))
	if not known.has(choisi):
		choisi = ""
		for s2 in ORDRE:
			if known.has(s2):
				choisi = s2
				break
	mana = clampf(float(d.get("magie", mana_max())), 0.0, float(mana_max()))
	reset()


## Chargement d'une partie : plus de lumière, de glace, d'objet en vol, de lévitation.
func reset() -> void:
	light_t = 0.0
	lev_t = -1.0
	_lit.clear()
	for e in ice:
		if is_instance_valid(e["node"]):
			(e["node"] as Node).queue_free()
	ice.clear()
	_flying.clear()
	_cd.clear()
	if _orb != null:
		_orb.visible = false
	_refresh()
