extends Node3D
## V76 : les événements des quêtes d'Astralys et des compagnons animaux.
##  - Cache-cache (as_cache_cache) : Pixel et Quark se cachent dans deux des cachettes de la cité ;
##    on les trouve en s'approchant (Quark fredonne) → « cache_cache_trouves ».
##  - Plume-de-Nuage (as_meduse) : une petite méduse de ciel attend au Jardin des Apesanteurs ; elle
##    suit le héros s'il reste près d'elle, jusqu'à la Serre des Espèces → « meduse_rendue ».
##  - La course des anneaux (as_course) : onze anneaux de lumière dans le ciel autour d'Astralys ;
##    on passe l'anneau de départ (au-dessus du Spatioport) en vol, et Comète part dans sa soucoupe ;
##    il faut passer tous les anneaux et revenir avant elle → « course_comete ».
##  - Le Cœur de la Flèche (as_coeur) : on monte en vol jusqu'au Cœur (72 m) → « fleche_coeur ».
##  - Les compagnons : Brioche (Port-Azur, sur la poutre de la halle aux poissons, avec la pelote de
##    laine), Biscotte (Port-Coutelas, au ponton du Requin Borgne, avec le fromage affiné), Truffe
##    (Montjoie, au bord des Champs du Sud, avec la clochette) attendent à l'étape « etat » de leur
##    quête ; on s'approche avec l'objet et ils viennent : compagnons_animaux_v76.adopt(id).

const ANIMAUX := "res://scripts/animaux_v75.gd"
const IleS = preload("res://scripts/ile_astrale_v76.gd")
const COMET_V: float = 20.0               # la vitesse de Comète (le Glisseur : 24 en croisière, 42 au plus)
const RING_R: float = 7.0
const PASS_R: float = 9.0

var main: Node
var ast: Node                             # astrale_v76
var state := {}
var _rng := RandomNumberGenerator.new()
var _t: float = 0.0
var _clock: float = 0.0

# cache-cache
var _hum_t: float = 0.0
const CACHES := ["cache_jardin", "cache_serre", "cache_spatioport", "cache_musee"]

# la méduse
var _jelly: Node3D
var _jelly_follow: bool = false
var _jelly_lost_said: bool = false

# la course
var _rings: Array = []                    # [MeshInstance3D, pos, axe]
var _ring_root: Node3D
var _ring_mats: Array = []                # [prochain, autres, passés]
var _saucer: Node3D
var _race: String = "attente"             # attente, course
var _next: int = 0
var _comet_s: float = 0.0
var _path_len: Array = []
var _race_t: float = 0.0
var _hint_t: float = 0.0

# les compagnons qui attendent
var _pets: Dictionary = {}                # id -> {node, clock, jump}
var _pet_hint_t: float = 0.0
const PETS := {
	"brioche": {"quete": "pet_brioche", "cle": "brioche_adoptee", "objet": "pelote_laine", "mgr": "azur_v56", "sous": "port", "at": "brioche_attente", "sol": "brioche_sol",
		"espece": "chat", "pose": "assis", "cri": "miaou",
		"sans": "Une chatte rousse et blanche te regarde de tout en haut de la poutre, la queue enroulée sur les pattes. Elle ne descendra pas pour n'importe qui… Il te faudrait de quoi l'intéresser : la pelote de laine de Pauline !",
		"avec": "Tu sors la pelote de laine et tu la fais rouler doucement sur les pavés. Là-haut, deux oreilles se dressent. Brioche hésite… s'étire… et saute, légère comme un chiffon, à côté de la pelote. Elle la pousse d'une patte, puis vient se frotter contre tes jambes. C'est elle qui a choisi : c'est toi."},
	"biscotte": {"quete": "pet_biscotte", "cle": "biscotte_adoptee", "objet": "fromage_affine", "mgr": "pirates_v68", "sous": "port", "at": "biscotte_attente", "sol": "biscotte_attente",
		"espece": "rat", "pose": "assis", "cri": "couinement_rat",
		"sans": "Un petit museau rose sort d'entre les planches du ponton, contre la coque du Requin Borgne… et rentre aussitôt. Il faudrait poser quelque chose qui sente très, très bon : le fromage affiné !",
		"avec": "Tu poses un morceau de fromage affiné sur les planches, contre la coque. Un museau. Des moustaches. Biscotte sort de son trou, grignote, te regarde… puis grimpe le long de ta jambe, de ton bras, et s'installe sur ton épaule. C'est gagné !"},
	"truffe": {"quete": "pet_truffe", "cle": "truffe_adoptee", "objet": "clochette_cochon", "mgr": "montjoie_v71", "sous": "dehors", "at": "truffe_attente", "sol": "truffe_attente",
		"espece": "cochon", "pose": "renifle", "cri": "grouik",
		"sans": "Ça remue dans les bosquets… un groin rose et noir apparaît, renifle, et disparaît. Truffe est là, mais il est timide. Avec sa clochette, il te reconnaîtrait !",
		"avec": "Tu fais tinter la clochette : ding, ding ! Les bosquets s'agitent, et Truffe en sort au petit trot, les oreilles qui ballottent, la queue en tire-bouchon. Il colle son groin contre ta main. Grouik ! Il te suit maintenant."},
}


func setup(main_node: Node, manager: Node) -> void:
	main = main_node
	ast = manager
	_rng.randomize()
	state = _fresh()
	name = "Evenements_v76"


func _fresh() -> Dictionary:
	return {"caches": [], "pixel": false, "quark": false, "meduse": false, "course": false, "course_meilleur": 0.0, "coeur": false, "glisseur": false}


func serialize() -> Dictionary:
	return state.duplicate(true)


func load_data(d: Dictionary) -> void:
	state = _fresh()
	for k in state:
		if d.has(k):
			state[k] = d[k]
	if typeof(state["caches"]) != TYPE_ARRAY:
		state["caches"] = []
	_end_race(true)
	if _jelly != null:
		_jelly.queue_free()
		_jelly = null
	_jelly_follow = false


func trouvailles() -> Dictionary:
	return {"cache_cache_trouves": 1 if bool(state["pixel"]) and bool(state["quark"]) else 0, "meduse_rendue": 1 if bool(state["meduse"]) else 0,
		"course_comete": 1 if bool(state["course"]) else 0, "fleche_coeur": 1 if bool(state["coeur"]) else 0, "glisseur": 1 if bool(state["glisseur"]) else 0}


# =================================================================== outils

func _journal() -> Node:
	return main.get("journal_v56") if main != null else null


func _quest(id: String) -> String:
	var j: Node = _journal()
	return str(j.state(id)) if j != null else ""


## La quête est-elle à l'étape « etat » de cette clé ?
func _at_step(qid: String, cle: String) -> bool:
	var j: Node = _journal()
	if j == null or _quest(qid) != "en_cours":
		return false
	var st: Dictionary = (j.states as Dictionary).get(qid, {})
	var q: Dictionary = j.quest(qid)
	var steps: Array = q.get("etapes", [])
	var i: int = int(st.get("etape", 0))
	return i >= 0 and i < steps.size() and str((steps[i] as Dictionary).get("cle", "")) == cle


func _player() -> Vector3:
	return main._player_pos_v27()


func _say(t: String, s: float = 8.0) -> void:
	ast.say(t, s)


func _sfx(n: String, at: Vector3) -> void:
	ast.sfx(n, at)


var test_flying: bool = false             # pour les essais automatiques

func _flying() -> bool:
	if test_flying:
		return true
	var a: Node = main.get("aeronef_v76")
	return a != null and bool(a.get("riding"))


func _glow_mat(c: Color, energy: float, alpha: float = 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(c.r, c.g, c.b, alpha)
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	if alpha < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


func _process(delta: float) -> void:
	if main == null or ast == null or ast.get("city") == null:
		return
	_clock += delta
	_t -= delta
	var slow: bool = _t <= 0.0
	if slow:
		_t = 0.25
	var p: Vector3 = _player()
	var near_ast: bool = ast.contains(p) or Vector2(p.x - IleS.CENTER.x, p.z - IleS.CENTER.z).length() < 520.0
	if near_ast:
		if slow:
			_cache_tick(0.25, p)
			_coeur_tick(p)
		_jelly_tick(delta, p)
		_race_tick(delta, p)
	elif _race == "course":
		_end_race(false)
	_pets_tick(delta, p)
	if slow:
		_glisseur_tick()


# =================================================================== le Glisseur stellaire (as_glisseur)

## Ionie construit le Glisseur quand on lui a tout apporté (étape « etat » glisseur) ; il faut
## ensuite l'essayer en vol.
func _glisseur_tick() -> void:
	var ae: Node = main.get("aeronef_v76")
	if ae == null:
		return
	var j: Node = _journal()
	if j != null and _quest("as_glisseur") in ["en_cours", "finie"] and (_quest("as_glisseur") == "finie" or int(j.step_of("as_glisseur")) >= 4) and int(ae.level()) < 4:
		var at: Node = main.get("atelier_ailes_v76")
		if at != null and at.has_method("unlock_glisseur"):
			at.unlock_glisseur()
		else:
			ae.set_level(4, true)
	if not bool(state["glisseur"]) and bool(ae.get("riding")) and int(ae.level()) >= 4:
		state["glisseur"] = true


# =================================================================== cache-cache

func _cache_tick(dt: float, p: Vector3) -> void:
	var on: bool = _at_step("as_cache_cache", "cache_cache_trouves") and not (bool(state["pixel"]) and bool(state["quark"]))
	if not on:
		return
	var caches: Array = state["caches"]
	if caches.size() < 2:
		var pool: Array = []
		for c in CACHES:
			if not ast.spot(c).is_empty():
				pool.append(c)
		pool.shuffle()
		if pool.size() < 2:
			return
		state["caches"] = [pool[0], pool[1]]
		caches = state["caches"]
	var who := ["pixel", "quark"]
	for i in range(2):
		var id: String = who[i]
		if bool(state[id]):
			continue
		var n: Node = ast.by_id.get(id, null)
		if n == null or not is_instance_valid(n):
			continue
		var sp_name: String = str(caches[i])
		_force(n, sp_name)
		var at: Vector3 = ast.spot(sp_name).get("pos", Vector3.ZERO)
		if id == "quark":
			_hum_t -= dt
			if _hum_t <= 0.0 and p.distance_to(at) < 30.0:
				_hum_t = 6.0
				_sfx("cristal_chante", at)
		if p.distance_to(at) < 3.2:
			state[id] = true
			n.call("_free_spot")
			_sfx("lumen_salut", at)
			var both: bool = bool(state["pixel"]) and bool(state["quark"])
			if id == "pixel":
				_say("« Oh non ! Trouvée ! » Pixel sort de sa cachette en riant, ses antennes toutes clignotantes. « Tu as des yeux de télescope ! »" + ("" if both else " Il reste Quark… écoute bien : il fredonne quand il se cache."), 8.0)
			else:
				_say("« Mmmm-mmm-mmm… oh. » Quark s'arrête de fredonner. « Comment tu as su ? » (Il ne s'est jamais rendu compte qu'il fredonnait.)" + ("" if both else " Il reste Pixel, quelque part dans la cité…"), 8.0)
			if both:
				get_tree().create_timer(8.5).timeout.connect(func(): _say("Tu as trouvé Pixel et Quark ! Va dire à Pixel que la partie est finie.", 6.0))


func _force(n: Node, sp_name: String) -> void:
	if str(n.get("target_spot")) == sp_name:
		return
	var sp: Dictionary = ast.spot(sp_name)
	if sp.is_empty():
		return
	n.call("_free_spot")
	n.set("target_spot", sp_name)
	ast.claim_spot(sp_name, n)
	n.call("_set_hidden", false)
	n.call("_jump_to", str(sp.get("node", "")))
	n.call("_arrive")


# =================================================================== Plume-de-Nuage, la méduse

func _jelly_home() -> Vector3:
	var top: Vector3 = ast.ile.islet_tops.get("apesanteur", Vector3.ZERO)
	return top + Vector3(-6.0, 2.6, -5.0)


func _build_jelly() -> Node3D:
	var root := Node3D.new()
	root.name = "Plume_de_Nuage"
	var bell := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.55
	sm.height = 0.7
	sm.is_hemisphere = true
	sm.radial_segments = 24
	sm.rings = 10
	bell.mesh = sm
	bell.material_override = _glow_mat(Color(1.0, 0.62, 0.86), 1.6, 0.72)
	bell.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(bell)
	var core := MeshInstance3D.new()
	var cm := SphereMesh.new()
	cm.radius = 0.2
	cm.height = 0.3
	core.mesh = cm
	core.position = Vector3(0, 0.12, 0)
	core.material_override = _glow_mat(Color(1.0, 0.9, 0.97), 3.0)
	root.add_child(core)
	var tm: Material = _glow_mat(Color(1.0, 0.7, 0.92), 1.2, 0.6)
	for k in range(8):
		var a: float = TAU * k / 8.0
		var t := MeshInstance3D.new()
		var cy := CylinderMesh.new()
		cy.top_radius = 0.03
		cy.bottom_radius = 0.008
		cy.height = 0.9 + 0.25 * (k % 3)
		cy.radial_segments = 5
		t.mesh = cy
		t.material_override = tm
		t.position = Vector3(cos(a) * 0.36, -cy.height * 0.5, sin(a) * 0.36)
		t.name = "Tentacule_%d" % k
		t.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(t)
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.7, 0.9)
	l.light_energy = 1.2
	l.omni_range = 5.0
	l.shadow_enabled = false
	root.add_child(l)
	var lbl := Label3D.new()
	lbl.text = "Plume-de-Nuage"
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.font_size = 36
	lbl.pixel_size = 0.004
	lbl.outline_size = 8
	lbl.position = Vector3(0, 0.75, 0)
	lbl.modulate = Color(1.0, 0.85, 0.95)
	root.add_child(lbl)
	return root


func _jelly_tick(delta: float, p: Vector3) -> void:
	var on: bool = _at_step("as_meduse", "meduse_rendue") and not bool(state["meduse"])
	if not on:
		if _jelly != null:
			_jelly.queue_free()
			_jelly = null
		return
	if _jelly == null:
		_jelly = _build_jelly()
		ast.add_child(_jelly)
		_jelly.global_position = _jelly_home()
		_jelly_follow = false
	var jp: Vector3 = _jelly.global_position
	# les tentacules ondulent, la cloche respire
	var s: float = 1.0 + sin(_clock * 2.4) * 0.07
	(_jelly.get_child(0) as Node3D).scale = Vector3(s, 2.0 - s, s)
	for k in range(8):
		var t: Node3D = _jelly.get_node_or_null("Tentacule_%d" % k)
		if t != null:
			t.rotation = Vector3(sin(_clock * 2.0 + k) * 0.25, 0, cos(_clock * 1.7 + k * 1.3) * 0.25)
	var d: float = p.distance_to(jp)
	if not _jelly_follow:
		jp.y += sin(_clock * 1.3) * 0.004
		_jelly.global_position = jp
		if d < 5.0:
			_jelly_follow = true
			_jelly_lost_said = false
			_sfx("cristal_chante", jp)
			_say("Une petite méduse rose flotte là, toute tremblante. Plume-de-Nuage ! Elle te regarde… et vient se poser au-dessus de ton épaule. Elle te suit : ramène-la doucement à la Serre des Espèces (à l'est de la cité), sans courir trop loin devant !", 9.0)
		return
	if d > 28.0:
		_jelly_follow = false
		if not _jelly_lost_said:
			_jelly_lost_said = true
			_say("Plume-de-Nuage s'est arrêtée : tu vas trop vite, elle a peur de se perdre. Retourne la chercher !", 6.0)
		return
	var back: Vector3 = jp - p
	back.y = 0.0
	back = back.normalized() * 1.8 if back.length() > 0.1 else Vector3(0, 0, 1.8)
	var target: Vector3 = p + back + Vector3(0, 2.3 + sin(_clock * 1.6) * 0.25, 0)
	_jelly.global_position = jp.lerp(target, clampf(delta * 1.6, 0.0, 1.0))
	var serre: Vector3 = ast.city.objets.get("serre", Vector3.ZERO)
	if serre != Vector3.ZERO and _jelly.global_position.distance_to(serre + Vector3(0, 2.0, 0)) < 9.0:
		state["meduse"] = true
		_sfx("cristal_chante", serre)
		_say("Plume-de-Nuage file sous la grande verrière de la Serre, fait trois tours de joie au milieu des autres créatures du ciel, et revient te frôler la joue. Elle est rentrée à la maison ! Va le dire à Nova.", 9.0)
		var j: Node3D = _jelly
		_jelly = null
		var tw := create_tween()
		tw.tween_property(j, "global_position", serre + Vector3(0, 6.0, 0), 4.0)
		tw.tween_callback(j.queue_free)


# =================================================================== la course des anneaux

func _ring_points() -> Array:
	var C: Vector3 = Vector3(IleS.CENTER.x, IleS.Y0, IleS.CENTER.z)
	var falls: Array = ast.ile.falls
	var fall_at := func(i: int, fallback: Vector3) -> Vector3:
		if i < falls.size():
			var top: Vector3 = falls[i][0]
			var out := Vector3(top.x - C.x, 0, top.z - C.z).normalized()
			return Vector3(top.x, C.y - 45.0, top.z) + out * 8.0
		return C + fallback
	# les chutes : 105° (sud), 200° (ouest), 318° (nord-est)
	return [
		C + Vector3(150.0, 30.0, 95.0),        # le départ, au-dessus du Spatioport
		C + Vector3(95.0, 10.0, 225.0),
		fall_at.call(0, Vector3(-52.0, -45.0, 198.0)),
		C + Vector3(-170.0, -15.0, 215.0),
		C + Vector3(-265.0, -55.0, 60.0),      # sous le bord du plateau
		fall_at.call(1, Vector3(-190.0, -45.0, -68.0)),
		C + Vector3(-180.0, -20.0, -215.0),
		C + Vector3(-40.0, 12.0, -280.0),       # au large de l'Observatoire
		C + Vector3(60.0, 12.0, -275.0),
		fall_at.call(2, Vector3(150.0, -45.0, -135.0)),
		C + Vector3(240.0, 5.0, -40.0),
	]


func _build_rings() -> void:
	_ring_root = Node3D.new()
	_ring_root.name = "Anneaux_course_v76"
	ast.add_child(_ring_root)
	_ring_mats = [_glow_mat(Color(1.0, 0.82, 0.3), 4.0), _glow_mat(Color(0.45, 0.85, 1.0), 1.4, 0.55), _glow_mat(Color(0.6, 1.0, 0.7), 1.0, 0.25)]
	var pts: Array = _ring_points()
	_path_len = [0.0]
	for i in range(pts.size()):
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[(i + 1) % pts.size()]
		var prev: Vector3 = pts[(i - 1 + pts.size()) % pts.size()]
		var axis: Vector3 = (b - prev).normalized()
		var mi := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = RING_R - 0.45
		tm.outer_radius = RING_R + 0.45
		tm.rings = 48
		tm.ring_segments = 10
		mi.mesh = tm
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_ring_root.add_child(mi)
		var bs := Basis.looking_at(axis, Vector3.UP if absf(axis.y) < 0.95 else Vector3.RIGHT) * Basis(Vector3.RIGHT, PI * 0.5)
		mi.global_transform = Transform3D(bs, a)
		_rings.append([mi, a, axis])
		if i > 0:
			_path_len.append(_path_len[i - 1] + pts[i - 1].distance_to(a))
	_path_len.append(_path_len[pts.size() - 1] + pts[pts.size() - 1].distance_to(pts[0]))
	# Comète, dans sa soucoupe
	_saucer = Node3D.new()
	_saucer.name = "Soucoupe_Comete"
	var body := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 1.8
	sm.height = 0.9
	body.mesh = sm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(1.0, 0.55, 0.75)
	m.metallic = 0.8
	m.roughness = 0.2
	m.emission_enabled = true
	m.emission = Color(1.0, 0.4, 0.7)
	m.emission_energy_multiplier = 0.6
	body.material_override = m
	_saucer.add_child(body)
	var dome := MeshInstance3D.new()
	var dm := SphereMesh.new()
	dm.radius = 0.75
	dm.height = 0.75
	dm.is_hemisphere = true
	dome.mesh = dm
	dome.position = Vector3(0, 0.3, 0)
	dome.material_override = _glow_mat(Color(0.7, 0.95, 1.0), 1.5, 0.5)
	_saucer.add_child(dome)
	var trail := MeshInstance3D.new()
	var cy := CylinderMesh.new()
	cy.top_radius = 0.9
	cy.bottom_radius = 0.05
	cy.height = 9.0
	trail.mesh = cy
	trail.material_override = _glow_mat(Color(1.0, 0.75, 0.4), 2.0, 0.35)
	trail.rotation = Vector3(-PI * 0.5, 0, 0)
	trail.position = Vector3(0, 0, 5.0)
	trail.name = "Traine"
	_saucer.add_child(trail)
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.6, 0.8)
	l.light_energy = 2.5
	l.omni_range = 14.0
	l.shadow_enabled = false
	_saucer.add_child(l)
	var lbl := Label3D.new()
	lbl.text = "Comète"
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.font_size = 48
	lbl.pixel_size = 0.006
	lbl.outline_size = 10
	lbl.position = Vector3(0, 1.8, 0)
	_saucer.add_child(lbl)
	_ring_root.add_child(_saucer)
	_park_saucer()


func _park_saucer() -> void:
	if _saucer == null or _rings.is_empty():
		return
	var a: Vector3 = _rings[0][1]
	_saucer.global_position = a + Vector3(10.0, 1.0, 0)
	_saucer.get_node("Traine").visible = false


func _paint_rings() -> void:
	for i in range(_rings.size()):
		var mi: MeshInstance3D = _rings[i][0]
		var want: int = 1
		if _race == "attente":
			want = 0 if i == 0 else 1
		else:
			var nx: int = _next % _rings.size()
			want = 0 if i == nx else (2 if i < _next and i != 0 else 1)
		mi.material_override = _ring_mats[want]


func _comet_pos(s: float) -> Vector3:
	var n: int = _rings.size()
	s = clampf(s, 0.0, float(_path_len[n]))
	for i in range(n):
		if s <= float(_path_len[i + 1]):
			var a: Vector3 = _rings[i][1]
			var b: Vector3 = _rings[(i + 1) % n][1]
			var seg: float = maxf(0.001, float(_path_len[i + 1]) - float(_path_len[i]))
			return a.lerp(b, (s - float(_path_len[i])) / seg)
	return _rings[0][1]


func _end_race(remove: bool) -> void:
	_race = "attente"
	_next = 0
	_comet_s = 0.0
	if remove:
		if _ring_root != null:
			_ring_root.queue_free()
		_ring_root = null
		_rings.clear()
		_saucer = null
	else:
		_park_saucer()
		if not _rings.is_empty():
			_paint_rings()


func _race_tick(delta: float, p: Vector3) -> void:
	var on: bool = _at_step("as_course", "course_comete") and not bool(state["course"])
	if not on:
		if _ring_root != null:
			_end_race(true)
		return
	if _ring_root == null:
		_build_rings()
		_end_race(false)
	# les anneaux tournent doucement
	for r in _rings:
		var mi: MeshInstance3D = r[0]
		mi.global_transform.basis = mi.global_transform.basis.rotated(r[2], delta * 0.6)
	_hint_t -= delta
	if _race == "attente":
		if _saucer != null:
			_saucer.global_position.y += sin(_clock * 2.0) * 0.01
		var start: Vector3 = _rings[0][1]
		if p.distance_to(start) < PASS_R:
			if not _flying():
				if _hint_t <= 0.0:
					_hint_t = 6.0
					_say("Comète, depuis sa soucoupe : « Vziiiou ! Pas à pied ! Monte dans ton Glisseur stellaire (touche N) et passe l'anneau d'or ! »", 6.0)
				return
			_race = "course"
			_next = 1
			_comet_s = 0.0
			_race_t = 0.0
			_saucer.get_node("Traine").visible = true
			_sfx("anneau_passe", start)
			_sfx("soucoupe_vol", start)
			_say("« Trois… deux… un… VZIIIOU ! » Comète démarre en trombe ! Passe tous les anneaux (le prochain brille en or) et reviens à l'anneau de départ avant elle !", 6.0)
			_paint_rings()
		elif _hint_t <= 0.0 and p.distance_to(start) < 140.0 and _flying():
			_hint_t = 12.0
			_say("Comète t'attend près de l'anneau d'or, au-dessus du Spatioport. Passe dedans pour donner le départ !", 5.0)
		return
	# la course
	_race_t += delta
	if not _flying():
		_say("Tu t'es posé : la course s'arrête. Comète fait demi-tour en riant : « Revanche ? Je t'attends à l'anneau d'or ! »", 7.0)
		_end_race(false)
		return
	var n: int = _rings.size()
	_comet_s += COMET_V * delta
	var cp: Vector3 = _comet_pos(_comet_s)
	var ahead: Vector3 = _comet_pos(_comet_s + 4.0)
	_saucer.global_position = cp + Vector3(0, sin(_clock * 3.0) * 0.6, 0)
	if ahead.distance_to(cp) > 0.1:
		_saucer.look_at(ahead, Vector3.UP)
	var target: Vector3 = _rings[_next % n][1]
	if p.distance_to(target) < PASS_R:
		_sfx("anneau_passe", target)
		_next += 1
		if _next > n:
			_win()
			return
		_paint_rings()
	if _comet_s >= float(_path_len[n]):
		_say("Comète repasse l'anneau d'or la première : « VZIIIOU ! Gagné ! » Elle fait un looping de joie. « Allez, revanche ! Repasse dans l'anneau d'or quand tu veux ! »", 8.0)
		_end_race(false)


func _win() -> void:
	state["course"] = true
	var best: float = float(state["course_meilleur"])
	if best <= 0.0 or _race_t < best:
		state["course_meilleur"] = _race_t
	_say("Tu repasses l'anneau d'or AVANT Comète ! (%d secondes.) Elle arrive juste derrière toi, bouche bée : « Personne ne m'avait jamais battue ! » Va la retrouver au Spatioport." % int(_race_t), 9.0)
	_sfx("anneau_passe", _rings[0][1])
	if main.has_method("jingle"):
		main.call("jingle", "victoire")
	_end_race(true)


# =================================================================== le Cœur de la Flèche

func _coeur_tick(p: Vector3) -> void:
	if bool(state["coeur"]) or not _at_step("as_coeur", "fleche_coeur"):
		return
	var h: Vector3 = ast.city.heart
	if p.distance_to(h) < 11.0:
		state["coeur"] = true
		_sfx("cristal_chante", h)
		_say("Tu t'approches du Cœur de la Flèche. Les trois éclats s'échappent de ton sac, flottent jusqu'au grand cristal… et s'y fondent dans un éclair bleu. Le Cœur se remet à battre, fort, régulier, joyeux. Tout en bas, les ponts de lumière cessent de clignoter. Retourne voir la Doyenne Astrée !", 10.0)
		var inv: Node = main.get("inventory_v28")
		if inv != null and inv.count("coeur_fleche") > 0:
			inv.remove("coeur_fleche", inv.count("coeur_fleche"))


## Le Cœur bat plus fort une fois soigné.
func heart_boost() -> float:
	return 1.6 if bool(state.get("coeur", false)) else 1.0


# =================================================================== les compagnons qui attendent

func _pets_mgr() -> Node:
	return main.get("compagnons_animaux_v76") if main != null else null


func _pet_points(id: String) -> Array:
	var d: Dictionary = PETS[id]
	var m: Node = main.get(str(d["mgr"]))
	if m == null:
		return []
	var sub: Node = m.get(str(d["sous"]))
	if sub == null:
		return []
	var ob: Dictionary = sub.get("objets") if sub.get("objets") is Dictionary else {}
	if not ob.has(str(d["at"])):
		return []
	return [ob[str(d["at"])], ob.get(str(d["sol"]), ob[str(d["at"])])]


func _pets_tick(delta: float, p: Vector3) -> void:
	var pm: Node = _pets_mgr()
	if pm == null:
		return
	_pet_hint_t -= delta
	for id in PETS:
		var d: Dictionary = PETS[id]
		var waiting: bool = _at_step(str(d["quete"]), str(d["cle"])) and not bool(pm.is_adopted(id))
		var pts: Array = _pet_points(id) if waiting else []
		if pts.is_empty():
			if _pets.has(id):
				var e0: Dictionary = _pets[id]
				if is_instance_valid(e0["node"]):
					(e0["node"] as Node).queue_free()
				_pets.erase(id)
			continue
		var at: Vector3 = pts[0]
		var sol: Vector3 = pts[1]
		if not _pets.has(id):
			if p.distance_to(sol) > 120.0 or not ResourceLoader.exists(ANIMAUX):
				continue
			var A = load(ANIMAUX)
			var var_d: Dictionary = {}
			var spec: Variant = (pm.get_script().get_script_constant_map() as Dictionary).get("PETS", {})
			if spec is Dictionary and (spec as Dictionary).has(id):
				var_d = ((spec as Dictionary)[id] as Dictionary).get("variante", {})
			var node: Node3D = A.build(str(d["espece"]), var_d)
			if node == null:
				continue
			add_child(node)
			node.global_position = at
			_pets[id] = {"node": node, "clock": 0.0, "jump": -1.0}
		var e: Dictionary = _pets[id]
		var nd: Node3D = e["node"]
		e["clock"] = float(e["clock"]) + delta
		var to_p: Vector3 = p - nd.global_position
		to_p.y = 0.0
		if to_p.length() > 0.1:
			nd.rotation.y = lerp_angle(nd.rotation.y, atan2(to_p.x, to_p.z), clampf(delta * 3.0, 0.0, 1.0))
		var A2 = load(ANIMAUX)
		var jumping: float = float(e["jump"])
		if jumping >= 0.0:
			# Brioche saute de la poutre (les autres trottinent jusqu'au héros)
			jumping += delta
			e["jump"] = jumping
			var k: float = clampf(jumping / 1.0, 0.0, 1.0)
			var dest: Vector3 = p + (nd.global_position - p).normalized() * 0.9
			dest.y = sol.y
			nd.global_position = at.lerp(Vector3(dest.x, sol.y, dest.z), k) + Vector3(0, sin(k * PI) * 0.8, 0)
			A2.animate(nd, float(e["clock"]), 2.5, "", 0.0, delta)
			if k >= 1.0:
				nd.queue_free()
				_pets.erase(id)
				pm.adopt(id, true)
			continue
		A2.animate(nd, float(e["clock"]), 0.0, str(d["pose"]) if fmod(float(e["clock"]), 7.0) < 5.0 else "assis", 0.0, delta)
		if fmod(float(e["clock"]), 9.0) < delta and p.distance_to(at) < 25.0:
			_sfx(str(d["cri"]), at)
		var near: bool = Vector2(p.x - sol.x, p.z - sol.z).length() < 4.0 and absf(p.y - sol.y) < 3.0
		if not near:
			continue
		var inv: Node = main.get("inventory_v28")
		var has: bool = inv != null and int(inv.count(str(d["objet"]))) > 0
		if has:
			_say(str(d["avec"]), 9.0)
			_sfx(str(d["cri"]), at)
			if inv != null:
				inv.remove(str(d["objet"]), 1)
			e["jump"] = 0.0
		elif _pet_hint_t <= 0.0:
			_pet_hint_t = 12.0
			_say(str(d["sans"]), 8.0)
