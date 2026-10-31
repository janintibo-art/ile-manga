extends "res://scripts/monstre_v75.gd"
## V90 : les dinosaures de l'Île Pixelithique, en petits cubes (vox_v90 : des pièces articulées).
## Même règle que les autres monstres (groupe « cibles_v28 », take_hit, butin, un conseil à la
## première rencontre). Tout public : vaincus, ils ne saignent pas ; les petits détalent dans les
## fougères, les gros se couchent et s'endorment (« Z z z… »).
##  - le raptor : en bande ; il tourne autour, se baisse en sifflant… puis BONDIT. Après le saut, il
##    est tout étourdi un instant : c'est le moment de frapper ;
##  - le tricératops (Corne-Sur-Nez) : il gratte la terre, puis il FONCE tout droit. S'il cogne un
##    rocher ou un arbre, il voit des étoiles (coups doublés) ;
##  - l'ankylosaure (Queue-Massue) : son dos est dur comme la pierre (les coups de dos ne font
##    presque rien) ; sa queue-massue tourne… puis BAM ; après, il souffle (frappe la tête !) ;
##  - le ptéranodon (Grand-Bec) : il tourne en l'air, crie, puis pique sur toi ; il remonte lentement,
##    tout bas : frappe-le à ce moment-là ;
##  - GROSSE-DENT (le tyrannosaure, le boss du Cirque des Os) : il mord (la gueule s'ouvre avant),
##    balaie avec sa queue quand on passe derrière lui, RUGIT… puis charge. S'il cogne la roche du
##    cirque, il est assommé quatre secondes : coups doublés. À la moitié de ses forces, il va plus
##    vite et deux raptors arrivent. Vaincu, il s'endort.

const Vox = preload("res://scripts/vox_v90.gd")

const SPECS90 := {
	"raptor": {"pv": 10, "vitesse": 4.4, "degats": 1, "portee": 4.6, "armer": 0.55, "repos": 1.1, "vue": 16.0, "laisse": 40.0,
		"rayon": 0.45, "haut": 0.5, "nom": "Raptor"},
	"triceratops": {"pv": 42, "vitesse": 2.0, "degats": 2, "portee": 15.0, "armer": 1.2, "repos": 1.6, "vue": 18.0, "laisse": 36.0,
		"rayon": 1.4, "haut": 1.0, "nom": "Corne-Sur-Nez", "chef": true},
	"ankylosaure": {"pv": 34, "vitesse": 1.5, "degats": 2, "portee": 3.6, "armer": 1.0, "repos": 1.9, "vue": 12.0, "laisse": 26.0,
		"rayon": 1.25, "haut": 0.6, "nom": "Queue-Massue", "chef": true},
	"pteranodon": {"pv": 8, "vitesse": 5.0, "degats": 1, "portee": 9.0, "armer": 0.8, "repos": 1.6, "vue": 22.0, "laisse": 45.0,
		"rayon": 0.65, "haut": 0.25, "nom": "Grand-Bec", "vol": 6.5},
	"trex": {"pv": 240, "vitesse": 3.0, "degats": 2, "portee": 5.6, "armer": 0.9, "repos": 1.2, "vue": 60.0, "laisse": 80.0,
		"rayon": 2.4, "haut": 2.4, "nom": "Grosse-Dent", "boss": true},
}
const SOUNDS90 := {"raptor": ["raptor_cri", "raptor_fuite"], "triceratops": ["trice_grogne", "trice_fuite"],
	"ankylosaure": ["anky_grogne", "anky_fuite"], "pteranodon": ["ptero_cri", "ptero_cri"], "trex": ["trex_rugit", "trex_ronfle"]}
const ECHELLE := {"raptor": 1.0, "triceratops": 1.0, "ankylosaure": 1.0, "pteranodon": 1.15, "trex": 1.0}

var _p90: Dictionary = {}                 # les pièces (articulations)
var _mat90: StandardMaterial3D
var _lock90 := Vector3.ZERO                 # la cible verrouillée (saut, charge, piqué)
var _dir90 := Vector3.ZERO
var _orbit90: float = 0.0
var _alt90: float = 6.5
var _roar90: float = 6.0
var _phase90: int = 0
var _hit90: bool = false
var _gait90: float = 0.0
var _step90: float = 0.0
var _jaw90: float = 0.0
var _flee90: Vector3 = Vector3.ZERO


# =================================================================== aiguillage

func _v63() -> bool:
	return SPECS90.has(kind) or super._v63()


func _leaper() -> bool:
	return false if SPECS90.has(kind) else super._leaper()


func _sound_pair() -> Array:
	return SOUNDS90.get(kind, super._sound_pair())


func is_boss() -> bool:
	if SPECS90.has(kind):
		return bool(spec.get("boss", false))
	return super.is_boss()


func is_chef() -> bool:
	if SPECS90.has(kind):
		return bool(spec.get("chef", false))
	return super.is_chef()


func is_hittable() -> bool:
	if SPECS90.has(kind):
		if state == "mort":
			return false
		if kind == "pteranodon":
			return global_position.y - _ground90(global_position) < 3.2
		return true
	return super.is_hittable()


func setup(m: Node, k: String, at: Vector3) -> void:
	if not SPECS90.has(k):
		super.setup(m, k, at)
		return
	manager = m
	kind = k
	spec = (SPECS90[k] as Dictionary).duplicate()
	_base_speed = float(spec["vitesse"])
	home = at
	hp = int(spec["pv"])
	hit_radius = float(spec["rayon"])
	hit_height = float(spec["haut"])
	name = "Monstre_%s_%d" % [k, get_instance_id()]
	collision_layer = 1
	collision_mask = 1
	var cs := CollisionShape3D.new()
	match k:
		"raptor":
			var c := CapsuleShape3D.new()
			c.radius = 0.38
			c.height = 1.3
			cs.shape = c
			cs.position.y = 0.75
		"triceratops":
			var b := BoxShape3D.new()
			b.size = Vector3(2.0, 2.4, 4.2)
			cs.shape = b
			cs.position = Vector3(0, 1.3, 0.3)
		"ankylosaure":
			var b2 := BoxShape3D.new()
			b2.size = Vector3(1.9, 1.3, 3.2)
			cs.shape = b2
			cs.position.y = 0.75
		"pteranodon":
			var sp := SphereShape3D.new()
			sp.radius = 0.45
			cs.shape = sp
		"trex":
			var b3 := BoxShape3D.new()
			b3.size = Vector3(2.8, 5.0, 6.5)
			cs.shape = b3
			cs.position = Vector3(0, 2.7, 0.4)
	add_child(cs)
	_cs71 = cs
	_visual = Node3D.new()
	add_child(_visual)
	_mat90 = Vox.make_material()
	_flash_mats.append(_mat90)
	_p90 = Vox.rig(_visual, k, _mat90)
	_visual.scale = Vector3.ONE * float(ECHELLE.get(k, 1.0))
	add_to_group("cibles_v28")
	add_to_group("monstres_v36")
	global_position = at
	facing = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
	_say_next = randf_range(3.0, 9.0)
	_orbit90 = randf() * TAU
	if k == "pteranodon":
		_alt90 = float(spec["vol"]) + randf_range(-0.5, 1.0)
		global_position = at + Vector3.UP * _alt90


func _ground90(at: Vector3) -> float:
	var mn: Node = _m71()
	var px: Node = mn.get("pixel_v90") if mn != null else null
	if px != null and px.get("ile") != null and px.ile != null and px.ile.contains(at.x, at.z):
		return float(px.ile.height(at.x, at.z))
	var g: float = _ground_y71(at, at.y)
	return g if g > -1e8 else home.y


# =================================================================== la vie

func _physics_process(delta: float) -> void:
	if not SPECS90.has(kind):
		super._physics_process(delta)
		return
	if manager == null:
		return
	_clock += delta
	if _flash > 0.0:
		_flash -= delta
	_apply_flash()
	_bubble75_tick(delta)
	_push_tick(delta)
	if state == "mort":
		_death_tick(delta)
		return
	if not _active75():
		_anim90(delta, 0.0)
		return
	if state == "etourdi":
		timer -= delta
		if timer <= 0.0:
			state = "chasse"
			vulnerable_t = 0.0
			if _stars != null:
				_stars.visible = false
		elif _stars != null:
			_stars.rotation.y += delta * 4.0
		if kind == "pteranodon":
			_fly_to(global_position + Vector3.DOWN * delta * 2.0, delta)
		else:
			_move90(Vector3.ZERO, delta)
		return
	match kind:
		"raptor":
			_raptor_tick(delta)
		"triceratops":
			_trice_tick(delta)
		"ankylosaure":
			_anky_tick(delta)
		"pteranodon":
			_ptero_tick(delta)
		"trex":
			_trex_tick(delta)


func _to_player() -> Array:
	var p: Vector3 = _player_feet75()
	var to_p: Vector3 = p - global_position
	var dy: float = absf(to_p.y)
	to_p.y = 0.0
	var dist: float = to_p.length()
	return [p, to_p / dist if dist > 0.01 else facing, dist, dy]


## veille / chasse : commun (retour à la maison, laisse, vue)
func _watch(dist: float, dy: float, alert_snd: bool = true) -> bool:
	var from_home: float = Vector2(global_position.x - home.x, global_position.z - home.z).length()
	if state == "veille":
		if dist < float(spec["vue"]) and dy < 4.0:
			state = "chasse"
			manager.alert(self)
			if alert_snd:
				_sound63("menace")
			return true
		return false
	if state == "chasse" and (dist > float(spec["vue"]) * 1.7 or from_home > float(spec["laisse"])):
		state = "veille"
	return state != "veille"


func _home_move(speed_k: float) -> Vector3:
	var back: Vector3 = home - global_position
	back.y = 0.0
	if back.length() < 1.0:
		return Vector3.ZERO
	facing = facing.lerp(back.normalized(), 0.08).normalized()
	return back.normalized() * float(spec["vitesse"]) * speed_k


func _hit_player(dist_max: float, cone: float, dmg: int, push: float) -> bool:
	var tp: Array = _to_player()
	if float(tp[2]) <= dist_max and (cone <= -1.0 or facing.dot(tp[1]) > cone) and float(tp[3]) < 3.0:
		manager.hurt_player(dmg, global_position)
		if push > 0.0:
			_push_player(tp[1], push)
		return true
	return false


# ------------------------------------------------------------------- le raptor

func _raptor_tick(delta: float) -> void:
	var tp: Array = _to_player()
	var dir_p: Vector3 = tp[1]
	var dist: float = tp[2]
	var move := Vector3.ZERO
	timer -= delta
	match state:
		"veille":
			if not _watch(dist, tp[3]):
				move = _home_move(0.4)
		"chasse":
			if not _watch(dist, tp[3]):
				pass
			elif dist <= float(spec["portee"]) and dist > 2.0:
				state = "armer"
				timer = float(spec["armer"])
				_sfx71("raptor_cri", global_position + Vector3.UP, -2.0)
			else:
				# il tourne autour en s'approchant (une bande, ça encercle)
				var side: Vector3 = dir_p.cross(Vector3.UP) * (1.0 if get_instance_id() % 2 == 0 else -1.0)
				var want: Vector3 = (dir_p + side * (0.8 if dist < 7.0 else 0.25)).normalized()
				if dist <= 2.0:
					want = -dir_p
				move = want * float(spec["vitesse"])
				facing = facing.lerp(dir_p, clampf(delta * 6.0, 0.0, 1.0)).normalized()
		"armer":
			facing = facing.lerp(dir_p, clampf(delta * 8.0, 0.0, 1.0)).normalized()
			if timer <= 0.0:
				state = "frappe"
				timer = 0.45
				_lock90 = tp[0]
				_dir90 = dir_p
				_hit90 = false
		"frappe":
			move = _dir90 * 10.0
			if not _hit90 and _hit_player(1.3, 0.2, int(spec["degats"]), 3.0):
				_hit90 = true
			if timer <= 0.0:
				# après le saut : tout étourdi un instant
				stun(0.9)
				vulnerable_t = 0.9
				return
		"souffle", "recul":
			if timer <= 0.0:
				state = "chasse"
	_move90(move, delta)


# ------------------------------------------------------------------- le tricératops

func _trice_tick(delta: float) -> void:
	var tp: Array = _to_player()
	var dir_p: Vector3 = tp[1]
	var dist: float = tp[2]
	var move := Vector3.ZERO
	timer -= delta
	match state:
		"veille":
			if not _watch(dist, tp[3]):
				move = _home_move(0.3)
		"chasse":
			if not _watch(dist, tp[3]):
				pass
			elif dist <= 3.6:
				state = "coup"
				timer = 0.7
				_hit90 = false
			elif dist <= float(spec["portee"]):
				state = "armer"
				timer = float(spec["armer"])
				_sfx71("trice_grogne", global_position + Vector3.UP, 0.0)
			else:
				move = dir_p * float(spec["vitesse"])
			facing = facing.lerp(dir_p, clampf(delta * 2.5, 0.0, 1.0)).normalized()
		"armer":
			# il gratte la terre (de la poussière)
			facing = facing.lerp(dir_p, clampf(delta * 5.0, 0.0, 1.0)).normalized()
			if timer <= 0.0:
				state = "charge"
				timer = 2.4
				_dir90 = facing
				_hit90 = false
		"charge":
			move = _dir90 * 9.0
			if not _hit90 and _hit_player(2.2, 0.0, int(spec["degats"]), 6.0):
				_hit90 = true
			if is_on_wall() and timer < 2.2:
				_bong()
				return
			if timer <= 0.0:
				state = "souffle"
				timer = float(spec["repos"])
		"coup":
			if timer < 0.35 and not _hit90:
				_hit90 = true
				_hit_player(3.8, 0.3, 1, 4.0)
			if timer <= 0.0:
				state = "souffle"
				timer = 0.8
		"souffle", "recul":
			if timer <= 0.0:
				state = "chasse"
	_move90(move, delta)


## Il a foncé dans un rocher (ou un arbre) : bong ! des étoiles.
func _bong() -> void:
	_sfx71("touche_pierre", global_position + Vector3.UP * 1.5, 2.0)
	var cb: Node = _m71().get("combat_v28") if _m71() != null else null
	if cb != null:
		cb.float_text(global_position + Vector3.UP * (hit_height * 2.0 + 1.0), "BONG !", Color(1.0, 0.9, 0.4))
	stun(3.0 if kind == "triceratops" else 4.0)
	vulnerable_t = 4.0
	_knock = -_dir90 * 2.0


# ------------------------------------------------------------------- l'ankylosaure

func _anky_tick(delta: float) -> void:
	var tp: Array = _to_player()
	var dir_p: Vector3 = tp[1]
	var dist: float = tp[2]
	var move := Vector3.ZERO
	timer -= delta
	match state:
		"veille":
			if not _watch(dist, tp[3]):
				move = _home_move(0.3)
		"chasse":
			if not _watch(dist, tp[3]):
				pass
			elif dist <= float(spec["portee"]):
				state = "armer"
				timer = float(spec["armer"])
				_sfx71("anky_grogne", global_position + Vector3.UP, 0.0)
			else:
				move = dir_p * float(spec["vitesse"])
				facing = facing.lerp(dir_p, clampf(delta * 3.0, 0.0, 1.0)).normalized()
		"armer":
			if timer <= 0.0:
				state = "frappe"
				timer = 0.75
				_hit90 = false
		"frappe":
			# la queue tourne (un tour complet)
			rotation.y += delta * TAU / 0.75
			facing = Vector3(sin(rotation.y), 0, cos(rotation.y))
			if not _hit90 and timer < 0.5:
				if _hit_player(float(spec["portee"]) + 0.6, -2.0, int(spec["degats"]), 5.0):
					_hit90 = true
			if timer <= 0.0:
				state = "souffle"
				timer = float(spec["repos"])
				vulnerable_t = float(spec["repos"])
				_sfx71("anky_grogne", global_position + Vector3.UP, -6.0)
		"souffle", "recul":
			facing = facing.lerp(dir_p, clampf(delta * 1.5, 0.0, 1.0)).normalized()
			if timer <= 0.0:
				state = "chasse"
				vulnerable_t = 0.0
	if state == "frappe":
		_move90(move, delta, false)
	else:
		_move90(move, delta)


# ------------------------------------------------------------------- le ptéranodon

func _fly_to(target: Vector3, delta: float) -> void:
	var g: float = _ground90(target)
	target.y = maxf(target.y, g + 0.8)
	global_position = global_position.move_toward(target, maxf(0.01, global_position.distance_to(target)) * minf(1.0, delta * 3.0) + delta * 0.5)
	rotation.y = atan2(facing.x, facing.z)
	_anim90(delta, 1.0)


func _ptero_tick(delta: float) -> void:
	var tp: Array = _to_player()
	var p: Vector3 = tp[0]
	var dist: float = tp[2]
	timer -= delta
	match state:
		"veille":
			_orbit90 += delta * 0.4
			var c: Vector3 = home + Vector3(cos(_orbit90) * 7.0, _alt90, sin(_orbit90) * 7.0)
			facing = Vector3(-sin(_orbit90), 0, cos(_orbit90))
			_fly_to(c, delta)
			if dist < float(spec["vue"]) and float(tp[3]) < 14.0:
				state = "chasse"
				manager.alert(self)
				_sfx71("ptero_cri", global_position, 0.0)
				timer = randf_range(2.5, 4.0)
		"chasse":
			_orbit90 += delta * 0.9
			var c2: Vector3 = p + Vector3(cos(_orbit90) * 6.5, _alt90, sin(_orbit90) * 6.5)
			facing = Vector3(-sin(_orbit90), 0, cos(_orbit90))
			_fly_to(c2, delta)
			var from_home: float = Vector2(global_position.x - home.x, global_position.z - home.z).length()
			if from_home > float(spec["laisse"]) or dist > float(spec["vue"]) * 1.8:
				state = "veille"
			elif timer <= 0.0:
				state = "armer"
				timer = float(spec["armer"])
				_sfx71("ptero_cri", global_position, 2.0)
		"armer":
			facing = facing.lerp(tp[1], clampf(delta * 6.0, 0.0, 1.0)).normalized()
			_fly_to(global_position + Vector3.UP * delta * 1.5, delta)
			if timer <= 0.0:
				state = "frappe"
				timer = 0.9
				_lock90 = p + Vector3.UP * 0.9
				_hit90 = false
		"frappe":
			var to: Vector3 = _lock90 - global_position
			facing = Vector3(to.x, 0, to.z).normalized() if Vector2(to.x, to.z).length() > 0.1 else facing
			global_position += to.normalized() * minf(to.length(), delta * 14.0)
			rotation.y = atan2(facing.x, facing.z)
			_anim90(delta, 2.0)
			if not _hit90 and global_position.distance_to(_player()) < 1.5:
				_hit90 = true
				manager.hurt_player(int(spec["degats"]), global_position)
			if timer <= 0.0 or to.length() < 0.4:
				state = "souffle"
				timer = float(spec["repos"])
		"souffle", "recul":
			# il remonte lentement, tout bas : c'est le moment de frapper
			_fly_to(global_position + Vector3.UP * delta * 1.2, delta)
			if timer <= 0.0:
				state = "chasse"
				timer = randf_range(2.5, 4.0)


# ------------------------------------------------------------------- Grosse-Dent

func _trex_tick(delta: float) -> void:
	var tp: Array = _to_player()
	var dir_p: Vector3 = tp[1]
	var dist: float = tp[2]
	var move := Vector3.ZERO
	var k: float = 1.25 if _phase90 >= 1 else 1.0
	timer -= delta
	_roar90 -= delta
	match state:
		"veille":
			if dist < float(spec["vue"]) and float(tp[3]) < 8.0:
				state = "rugir"
				timer = 2.2
				manager.alert(self)
				_sfx71("trex_rugit", global_position + Vector3.UP * 4.0, 4.0)
				_say75("GRROOOAAARRR !", 2.0)
			else:
				move = _home_move(0.3)
		"chasse":
			var behind: bool = facing.dot(dir_p) < -0.35
			if dist > float(spec["vue"]) * 1.6:
				state = "veille"
			elif behind and dist < 7.5:
				state = "queue"
				timer = 0.9
				_hit90 = false
				_sfx71("fendre_lourd", global_position + Vector3.UP * 2.0, 2.0)
			elif dist <= float(spec["portee"]):
				state = "armer"
				timer = float(spec["armer"]) / k
				_hit90 = false
			elif _roar90 <= 0.0 and dist > 9.0 and dist < 30.0:
				state = "rugir"
				timer = 1.8
				_roar90 = randf_range(7.0, 10.0) / k
				_sfx71("trex_rugit", global_position + Vector3.UP * 4.0, 3.0)
				_say75(["GRAAAOOORR !", "GRRRR…", "ROOOAAARR !"][randi() % 3], 1.6)
			else:
				move = dir_p * float(spec["vitesse"]) * k
				facing = facing.lerp(dir_p, clampf(delta * 2.2, 0.0, 1.0)).normalized()
		"rugir":
			facing = facing.lerp(dir_p, clampf(delta * 3.0, 0.0, 1.0)).normalized()
			if timer <= 0.0:
				if dist > 8.0:
					state = "charge"
					timer = 2.6
					_dir90 = facing
					_hit90 = false
				else:
					state = "chasse"
		"charge":
			move = _dir90 * 11.0 * k
			if not _hit90 and _hit_player(3.4, -0.2, int(spec["degats"]), 8.0):
				_hit90 = true
			# il cogne la roche du cirque : assommé
			if (is_on_wall() and timer < 2.4) or _out_of_arena():
				_bong()
				_sfx71("trex_rugit", global_position + Vector3.UP * 4.0, -4.0)
				_hint70("Grosse-Dent s'est cogné la tête contre la roche ! Il voit des étoiles : FRAPPE-LE MAINTENANT !")
				return
			if timer <= 0.0:
				state = "souffle"
				timer = float(spec["repos"])
		"armer":
			facing = facing.lerp(dir_p, clampf(delta * 3.0, 0.0, 1.0)).normalized()
			if timer <= 0.0:
				state = "frappe"
				timer = 0.35
				_sfx71("trex_rugit", global_position + Vector3.UP * 4.0, -6.0)
		"frappe":
			if not _hit90:
				_hit90 = true
				_hit_player(float(spec["portee"]) + 0.8, 0.45, int(spec["degats"]), 5.0)
			if timer <= 0.0:
				state = "souffle"
				timer = float(spec["repos"]) / k
		"queue":
			rotation.y += delta * 2.6
			facing = Vector3(sin(rotation.y), 0, cos(rotation.y))
			if not _hit90 and timer < 0.55:
				var back: Vector3 = -facing
				var tp2: Array = _to_player()
				if float(tp2[2]) < 8.0 and back.dot(tp2[1]) > 0.0:
					_hit90 = true
					manager.hurt_player(int(spec["degats"]), global_position)
					_push_player(tp2[1], 7.0)
			if timer <= 0.0:
				state = "souffle"
				timer = 0.6
		"souffle", "recul":
			facing = facing.lerp(dir_p, clampf(delta * 1.2, 0.0, 1.0)).normalized()
			if timer <= 0.0:
				state = "chasse"
	_move90(move, delta, state != "queue")
	if state in ["chasse", "charge"]:
		_step90 -= delta * (2.0 if state == "charge" else 1.0)
		if _step90 <= 0.0:
			_step90 = 0.55
			_sfx71("trex_pas", global_position, -4.0)


func _out_of_arena() -> bool:
	var mn: Node = _m71()
	var px: Node = mn.get("pixel_v90") if mn != null else null
	if px == null:
		return false
	var a: Array = px.IleScript.CIRQUE
	var c: Vector3 = px.IleScript.W(float(a[0]), float(a[1]))
	return Vector2(global_position.x - c.x, global_position.z - c.z).length() > float(a[2]) - 1.5


func _phase_check90() -> void:
	if kind != "trex" or _phase90 >= 1:
		return
	if hp <= int(spec["pv"]) / 2:
		_phase90 = 1
		_say75("GRRRAAAAOOOOOORRR !!!", 2.4)
		_sfx71("trex_rugit", global_position + Vector3.UP * 4.0, 6.0)
		_hint70("Grosse-Dent est furieux : il va plus vite… et il appelle ses copains raptors !")
		for i in range(2):
			var a: float = randf() * TAU
			var at: Vector3 = global_position + Vector3(cos(a) * 8.0, 0.5, sin(a) * 8.0)
			at.y = _ground90(at) + 0.3
			var m: Node3D = manager.spawn_extra("raptor", at)
			if m != null:
				m.set("home", at)


# =================================================================== déplacement, coups, fin

func _move90(move: Vector3, delta: float, turn: bool = true) -> void:
	if _knock.length() > 0.05:
		move += _knock
		_knock = _knock.move_toward(Vector3.ZERO, delta * 12.0)
	velocity.x = move.x
	velocity.z = move.z
	velocity.y = 0.0 if is_on_floor() else maxf(velocity.y - 18.0 * delta, -24.0)
	move_and_slide()
	if turn:
		rotation.y = lerp_angle(rotation.y, atan2(facing.x, facing.z), clampf(delta * 10.0, 0.0, 1.0))
	_anim90(delta, Vector2(move.x, move.z).length())


func take_hit(damage: int, from_pos: Vector3) -> void:
	if not SPECS90.has(kind):
		super.take_hit(damage, from_pos)
		return
	if state == "mort":
		return
	var cb: Node = _m71().get("combat_v28") if _m71() != null else null
	var away: Vector3 = global_position - from_pos
	away.y = 0.0
	away = away.normalized() if away.length() > 0.01 else -facing
	# l'ankylosaure : le dos est dur (sauf quand il souffle, ou si l'on frappe la tête)
	if kind == "ankylosaure" and vulnerable_t <= 0.0 and facing.dot(-away) < 0.5:
		damage = maxi(1, damage / 3)
		_sfx71("touche_pierre", global_position + Vector3.UP, -2.0)
		if cb != null and _clock - _through_t > 1.0:
			_through_t = _clock
			cb.float_text(global_position + Vector3.UP * 2.2, "Bong ! Dos tout dur", Color(0.85, 0.85, 0.8))
		_hint70("Son dos est dur comme la pierre ! Frappe la tête… ou attends qu'il souffle, après son coup de queue.")
	# Grosse-Dent : la peau est épaisse, sauf quand il est assommé
	if kind == "trex":
		if state == "etourdi":
			damage = int(round(damage * 2.0))
		else:
			damage = maxi(1, int(round(damage * 0.6)))
			if _clock - _last_hint > 10.0:
				_hint70("Sa peau est très épaisse… Quand il RUGIT, il va charger : esquive, et laisse-le cogner la roche du cirque !")
	elif kind == "triceratops" and state == "etourdi":
		damage = int(round(damage * 2.0))
	hp -= damage
	_flash = 0.18
	var kb: float = {"raptor": 3.0, "pteranodon": 2.5, "ankylosaure": 0.3, "triceratops": 0.4, "trex": 0.0}.get(kind, 1.0)
	if state != "charge":
		_knock = away * kb
	if cb != null:
		var at: Vector3 = global_position + Vector3.UP * (hit_height * 2.0 + 0.4)
		if cb.get("critical") == true:
			cb.damage_number_color(at, damage, Color(1.0, 0.55, 0.2), " !")
		else:
			cb.damage_number(at, damage)
		cb.puff(global_position + Vector3.UP * hit_height, Color(0.75, 0.68, 0.5))
	_phase_check90()
	if hp <= 0:
		_die63()
		return
	match kind:
		"raptor":
			if state in ["chasse", "armer"]:
				state = "recul"
				timer = 0.3
		"pteranodon":
			if state != "etourdi":
				stun(0.7)
		"triceratops", "ankylosaure", "trex":
			pass


func _die63() -> void:
	if not SPECS90.has(kind):
		super._die63()
		return
	var pair: Array = _sound_pair()
	_sfx71(str(pair[1]), global_position + Vector3.UP * hit_height)
	state = "mort"
	timer = 0.0
	collision_layer = 0
	collision_mask = 0
	if _stars != null:
		_stars.visible = false
	var away: Vector3 = global_position - _player()
	away.y = 0.0
	_flee90 = away.normalized() if away.length() > 0.1 else -facing
	if kind in ["raptor", "pteranodon"]:
		_say75(["Iiih !", "Couic !", "Kiiii !"][randi() % 3], 1.2)
	else:
		_say75("Z z z…", 3.0)
	died.emit(self)


## Vaincu : les petits s'enfuient (et disparaissent dans les fougères), les gros s'endorment.
func _death_tick(delta: float) -> void:
	if not SPECS90.has(kind):
		super._death_tick(delta)
		return
	timer += delta
	var end_t: float = 2.2
	match kind:
		"raptor":
			global_position += _flee90 * delta * 7.0
			rotation.y = atan2(_flee90.x, _flee90.z)
			_anim90(delta, 7.0)
			end_t = 1.6
		"pteranodon":
			global_position += (_flee90 + Vector3.UP * 0.8).normalized() * delta * 8.0
			rotation.y = atan2(_flee90.x, _flee90.z)
			_anim90(delta, 2.0)
			end_t = 2.0
		_:
			# il se couche sur le flanc, et il dort
			_visual.rotation.z = lerpf(_visual.rotation.z, 1.25, clampf(delta * 1.8, 0.0, 1.0))
			_visual.position.y = lerpf(_visual.position.y, 0.35 * hit_height, clampf(delta * 1.8, 0.0, 1.0))
			end_t = 5.0 if kind == "trex" else 4.0
	if timer > end_t - 0.8:
		_visual.scale = Vector3.ONE * float(ECHELLE.get(kind, 1.0)) * clampf(1.0 - (timer - (end_t - 0.8)) / 0.8, 0.01, 1.0)
	if timer > end_t:
		visible = false
		set_physics_process(false)


# =================================================================== animation

func _r90(k: String, r: Vector3) -> void:
	if _p90.has(k):
		(_p90[k] as Node3D).rotation = r


func _anim90(delta: float, speed: float) -> void:
	var run: float = clampf(speed / maxf(0.5, float(spec.get("vitesse", 2.0))), 0.0, 2.2)
	_gait90 += delta * (2.0 + run * 5.0)
	var g: float = _gait90
	var w: float = clampf(run, 0.0, 1.0)
	var breath: float = sin(_clock * 2.0) * 0.03
	var jaw_open: bool = state in ["armer", "frappe", "rugir"]
	_jaw90 = move_toward(_jaw90, 0.55 if jaw_open else (0.08 + absf(sin(_clock * 1.3)) * 0.06), delta * 3.0)
	match kind:
		"raptor":
			var crouch: float = 0.25 if state == "armer" else 0.0
			_r90("cuisseG", Vector3(sin(g) * 0.7 * w - crouch, 0, 0))
			_r90("cuisseD", Vector3(-sin(g) * 0.7 * w - crouch, 0, 0))
			_r90("jambeG", Vector3(maxf(0.0, -sin(g)) * 0.8 * w + crouch * 1.4, 0, 0))
			_r90("jambeD", Vector3(maxf(0.0, sin(g)) * 0.8 * w + crouch * 1.4, 0, 0))
			_r90("corps", Vector3(0.05 * w + crouch * 0.5 + breath, 0, sin(g) * 0.05 * w))
			_r90("cou", Vector3(-0.15 * w + crouch * 0.6 + sin(_clock * 1.7) * 0.05, sin(_clock * 0.9) * 0.15 * (1.0 - w), 0))
			_r90("machoire", Vector3(_jaw90 * 0.9, 0, 0))
			_r90("queue", Vector3(-0.05, sin(g * 0.5) * 0.25 * w + sin(_clock * 1.3) * 0.15, 0))
			_r90("queue2", Vector3(0.05, sin(g * 0.5 - 0.8) * 0.3 * w + sin(_clock * 1.3 - 0.6) * 0.2, 0))
			_r90("brasG", Vector3(-0.3 + sin(g) * 0.2 * w, 0, 0))
			_r90("brasD", Vector3(-0.3 - sin(g) * 0.2 * w, 0, 0))
			_visual.position.y = absf(sin(g)) * 0.06 * w - crouch * 0.15 + (0.25 if state == "frappe" else 0.0)
		"triceratops", "ankylosaure":
			var amp: float = 0.45 if kind == "triceratops" else 0.35
			if state == "charge":
				amp = 0.75
			_r90("patteavG", Vector3(sin(g) * amp * w, 0, 0))
			_r90("pattearD", Vector3(sin(g) * amp * w, 0, 0))
			_r90("patteavD", Vector3(-sin(g) * amp * w, 0, 0))
			_r90("pattearG", Vector3(-sin(g) * amp * w, 0, 0))
			var scrape: float = sin(_clock * 14.0) * 0.5 if state == "armer" and kind == "triceratops" else 0.0
			if scrape != 0.0:
				_r90("patteavD", Vector3(scrape, 0, 0))
			var head_down: float = 0.35 if state in ["charge", "armer"] and kind == "triceratops" else 0.0
			_r90("tete", Vector3(head_down + (sin(_clock * 18.0) * 0.25 if state == "coup" else 0.0) + breath, sin(_clock * 0.7) * 0.12 * (1.0 - w), 0))
			var tail_spin: float = sin(_clock * 3.0) * 0.2
			_r90("queue", Vector3(0.05, tail_spin + sin(g * 0.5) * 0.15 * w + (0.9 if state == "armer" and kind == "ankylosaure" else 0.0), 0))
			_r90("corps", Vector3(breath, 0, sin(g) * 0.03 * w))
			_visual.position.y = absf(sin(g)) * 0.04 * w
		"pteranodon":
			var flap_k: float = 1.0 if state != "frappe" else 0.15
			var f: float = sin(_clock * 6.0) * 0.55 * flap_k
			_r90("aileG", Vector3(0, 0, f))
			_r90("aileD", Vector3(0, 0, -f))
			_r90("boutG", Vector3(0, 0, f * 0.5 + (0.6 if state == "frappe" else 0.0)))
			_r90("boutD", Vector3(0, 0, -f * 0.5 - (0.6 if state == "frappe" else 0.0)))
			_r90("tete", Vector3(sin(_clock * 1.5) * 0.1 + (0.4 if state == "frappe" else 0.0), sin(_clock * 0.8) * 0.2, 0))
			_visual.rotation.x = 0.5 if state == "frappe" else 0.0
		"trex":
			var stunned: bool = state == "etourdi"
			_r90("cuisseG", Vector3(sin(g) * 0.55 * w, 0, 0))
			_r90("cuisseD", Vector3(-sin(g) * 0.55 * w, 0, 0))
			_r90("jambeG", Vector3(maxf(0.0, -sin(g)) * 0.6 * w, 0, 0))
			_r90("jambeD", Vector3(maxf(0.0, sin(g)) * 0.6 * w, 0, 0))
			var roar: float = 0.3 if state == "rugir" else 0.0
			_r90("corps", Vector3(0.04 * w - roar * 0.3 + breath, 0, sin(g) * 0.04 * w + (sin(_clock * 6.0) * 0.06 if stunned else 0.0)))
			_r90("tete", Vector3(-roar + (0.25 if state == "frappe" else 0.0) + sin(_clock * 1.1) * 0.05, (sin(_clock * 5.0) * 0.25 if stunned else sin(_clock * 0.6) * 0.1), 0))
			_r90("machoire", Vector3(_jaw90 * (1.2 if state == "rugir" else 1.0), 0, 0))
			var sweep: float = sin(_clock * 9.0) * 0.6 if state == "queue" else 0.0
			_r90("queue", Vector3(0.05, sin(g * 0.5) * 0.12 * w + sin(_clock * 0.9) * 0.1 + sweep, 0))
			_r90("queue2", Vector3(0.03, sin(g * 0.5 - 0.6) * 0.15 * w + sin(_clock * 0.9 - 0.5) * 0.14 + sweep * 0.7, 0))
			_r90("queue3", Vector3(0.02, sin(g * 0.5 - 1.2) * 0.2 * w + sin(_clock * 0.9 - 1.0) * 0.18 + sweep * 0.5, 0))
			_r90("brasG", Vector3(-0.3 + sin(_clock * 3.0) * 0.15, 0, 0))
			_r90("brasD", Vector3(-0.3 - sin(_clock * 3.0) * 0.15, 0, 0))
			_visual.position.y = absf(sin(g)) * 0.08 * w


func _animate63(delta: float, speed: float) -> void:
	if not SPECS90.has(kind):
		super._animate63(delta, speed)
		return
	_anim90(delta, speed)


func _animate75(delta: float, speed: float) -> void:
	if not SPECS90.has(kind):
		super._animate75(delta, speed)
		return
	_anim90(delta, speed)


func loot(rng: RandomNumberGenerator) -> Array:
	if not SPECS90.has(kind):
		return super.loot(rng)
	var g: Array = []
	match kind:
		"raptor":
			g.append(["piece", rng.randi_range(2, 5)])
		"pteranodon":
			g.append(["piece", rng.randi_range(2, 4)])
			if rng.randf() < 0.3:
				g.append(["plume_perroquet", 1])
		"triceratops":
			g.append(["piece", rng.randi_range(10, 18)])
			if rng.randf() < 0.3:
				g.append(["piece_or", 1])
		"ankylosaure":
			g.append(["piece", rng.randi_range(9, 16)])
			if rng.randf() < 0.3:
				g.append(["piece_or", 1])
		"trex":
			g.append(["piece", rng.randi_range(80, 110)])
			g.append(["piece_or", 3])
			g.append(["dent_grosse_dent", 1])
	for e in get_meta("butin_extra", []):
		g.append(e)
	return g


func alert_text() -> String:
	match kind:
		"raptor":
			return "Des raptors ! Ils tournent autour de toi… Quand l'un se baisse en sifflant, il va BONDIR : écarte-toi ! Après son saut, il est étourdi un instant : frappe."
		"triceratops":
			return "Un tricératops (Corne-Sur-Nez) ! Quand il gratte la terre avec son pied, il va FONCER tout droit : écarte-toi… et s'il cogne un rocher ou un arbre, il voit des étoiles. Frappe à ce moment-là !"
		"ankylosaure":
			return "Un ankylosaure (Queue-Massue) ! Son dos est dur comme la pierre. Quand sa queue se lève, recule : elle va tourner. Après son coup, il souffle : frappe-le à la tête !"
		"pteranodon":
			return "Un ptéranodon (Grand-Bec) ! Il tourne au-dessus de toi, crie… puis pique. Roule sur le côté ! Il remonte lentement, tout bas : c'est le moment de le frapper."
		"trex":
			return "GROSSE-DENT ! Le roi du Cirque des Os. Sa peau est épaisse… Quand il RUGIT, il va charger : esquive au dernier moment, et laisse-le se cogner contre la roche du cirque. Assommé, il prend des coups doublés ! Ne reste pas derrière lui : sa queue balaie tout."
	return super.alert_text()
