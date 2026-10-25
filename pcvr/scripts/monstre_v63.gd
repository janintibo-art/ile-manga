extends "res://scripts/monstre_v36.gd"
## V63 : les créatures de la grande enquête et du Cœur-de-Pierre. Même règle que les monstres
## de la V36 (groupe « cibles_v28 », take_hit, butin, conseil à la première rencontre) ; elles
## réagissent en plus aux pouvoirs des sceaux (on_power, stun, set_moonlit) :
##  - le scorpion des sables : la queue se dresse, puis pique (1/2 cœur) ;
##  - l'automate de bronze : un soldat mécanique, clé de remontage dans le dos ; le Rouage le fige ;
##  - le spectre des brumes : un fantôme ; les coups le traversent, sauf dans la Lueur de lune ;
##  - l'ondin : un élémentaire d'eau qui bondit ; la Bourrasque le disperse (dégâts doublés) ;
## et les quatre gardiens des ailes du Cœur-de-Pierre :
##  - le Garde-Marée : un crabe géant ; sa carapace arrête tout, la Bourrasque le renverse ;
##  - le Scorpion-Roi : cuirassé d'or ; la Flamme en plein visage l'étourdit ;
##  - le Colosse à vapeur : le Rouage bloque sa chaudière et ouvre son foyer ;
##  - le Grand Loup des Brumes : invisible et intouchable, sauf dans la Lueur de lune.

const SPECS63 := {
	"scorpion": {"pv": 14, "vitesse": 2.6, "degats": 1, "portee": 1.7, "armer": 0.55, "repos": 1.2, "vue": 10.0, "laisse": 14.0,
		"rayon": 0.6, "haut": 0.35, "nom": "Scorpion des sables"},
	"automate": {"pv": 26, "vitesse": 1.6, "degats": 2, "portee": 1.9, "armer": 0.8, "repos": 1.4, "vue": 12.0, "laisse": 14.0,
		"rayon": 0.42, "haut": 1.0, "nom": "Automate de bronze"},
	"spectre": {"pv": 12, "vitesse": 2.2, "degats": 1, "portee": 2.6, "armer": 0.8, "repos": 1.6, "vue": 13.0, "laisse": 18.0,
		"rayon": 0.45, "haut": 1.2, "nom": "Spectre des brumes", "bond": 7.0},
	"ondin": {"pv": 14, "vitesse": 2.3, "degats": 1, "portee": 2.3, "armer": 0.7, "repos": 1.5, "vue": 11.0, "laisse": 14.0,
		"rayon": 0.5, "haut": 0.6, "nom": "Ondin", "bond": 7.0},
	"garde_maree": {"pv": 70, "vitesse": 1.7, "degats": 2, "portee": 2.9, "armer": 0.9, "repos": 1.5, "vue": 22.0, "laisse": 40.0,
		"rayon": 1.4, "haut": 0.9, "nom": "le Garde-Marée", "boss": true},
	"scorpion_roi": {"pv": 80, "vitesse": 2.1, "degats": 2, "portee": 3.6, "armer": 0.85, "repos": 1.3, "vue": 22.0, "laisse": 40.0,
		"rayon": 1.5, "haut": 1.0, "nom": "le Scorpion-Roi", "boss": true},
	"colosse": {"pv": 90, "vitesse": 1.3, "degats": 3, "portee": 3.3, "armer": 1.05, "repos": 1.7, "vue": 22.0, "laisse": 40.0,
		"rayon": 1.0, "haut": 2.2, "nom": "le Colosse à vapeur", "boss": true},
	"loup_brumes": {"pv": 70, "vitesse": 4.0, "degats": 2, "portee": 3.4, "armer": 0.6, "repos": 1.4, "vue": 24.0, "laisse": 40.0,
		"rayon": 0.9, "haut": 0.9, "nom": "le Grand Loup des Brumes", "boss": true, "bond": 12.0},
	# V72 : le loup gris des bois de Montjoie (en chair et en os, lui)
	"loup": {"pv": 14, "vitesse": 3.6, "degats": 1, "portee": 1.9, "armer": 0.5, "repos": 1.2, "vue": 14.0, "laisse": 24.0,
		"rayon": 0.45, "haut": 0.45, "nom": "Loup gris", "bond": 7.0},
}
const LEAPERS := ["spectre", "ondin", "loup_brumes", "loup"]
const SOUNDS63 := {
	"scorpion": ["scorpion_menace", "scorpion_mort"], "scorpion_roi": ["scorpion_menace", "boss_coeur_cri"],
	"automate": ["automate_menace", "automate_mort"], "colosse": ["automate_menace", "boss_coeur_cri"],
	"spectre": ["spectre_menace", "spectre_mort"], "loup_brumes": ["loup_menace", "spectre_mort"], "loup": ["loup_menace", "loup_menace"],
	"ondin": ["ondin_menace", "ondin_mort"], "garde_maree": ["crabe_menace", "boss_coeur_cri"], "gardien_coeur": ["boss_coeur_cri", "boss_coeur_cri"],
}

var moonlit: bool = false
var vulnerable_t: float = 0.0           # boss : ouvert aux coups (renversé, étourdi, bloqué)
var _stun: float = 0.0
var _stars: Node3D
var _tail: Array = []                   # [Node3D articulation, angle de repos]
var _pincers: Array = []
var _shader_mats: Array = []
var _special_t: float = 0.0
var _summoned: bool = false
var _key_node: Node3D
var _steam: CPUParticles3D
var _furnace: StandardMaterial3D
var _eyes_mat: StandardMaterial3D
var _through_t: float = 0.0
var _body_node: Node3D
var _last_hint: float = -10.0


func setup(m: Node, k: String, at: Vector3) -> void:
	if not SPECS63.has(k):
		super.setup(m, k, at)
		return
	manager = m
	kind = k
	spec = SPECS63[k]
	home = at
	hp = int(spec["pv"])
	hit_radius = float(spec["rayon"])
	hit_height = float(spec["haut"])
	name = "Monstre_%s_%d" % [k, get_instance_id()]
	collision_layer = 1
	collision_mask = 1
	var cs := CollisionShape3D.new()
	match k:
		"scorpion":
			var b := BoxShape3D.new()
			b.size = Vector3(0.9, 0.5, 1.1)
			cs.shape = b
			cs.position.y = 0.3
		"scorpion_roi":
			var b2 := BoxShape3D.new()
			b2.size = Vector3(2.4, 1.3, 3.0)
			cs.shape = b2
			cs.position.y = 0.75
		"garde_maree":
			var b3 := BoxShape3D.new()
			b3.size = Vector3(2.8, 1.4, 2.2)
			cs.shape = b3
			cs.position.y = 0.8
		"spectre", "ondin":
			var sph := SphereShape3D.new()
			sph.radius = 0.4 if k == "spectre" else 0.45
			cs.shape = sph
			cs.position.y = 1.2 if k == "spectre" else 0.5
		"loup_brumes", "loup":
			var cap := CapsuleShape3D.new()
			cap.radius = 0.6 if k == "loup_brumes" else 0.3
			cap.height = 2.4 if k == "loup_brumes" else 1.2
			cs.shape = cap
			cs.rotation.x = PI * 0.5
			cs.position.y = 0.9 if k == "loup_brumes" else 0.45
		"colosse":
			var cap2 := CapsuleShape3D.new()
			cap2.radius = 0.85
			cap2.height = 3.8
			cs.shape = cap2
			cs.position.y = 1.9
		_:
			var cap3 := CapsuleShape3D.new()
			cap3.radius = 0.34
			cap3.height = 1.8
			cs.shape = cap3
			cs.position.y = 0.9
	add_child(cs)
	_visual = Node3D.new()
	add_child(_visual)
	match k:
		"scorpion":
			_build_scorpion(1.0, false)
		"scorpion_roi":
			_build_scorpion(2.6, true)
		"automate":
			_build_automate(1.0)
		"colosse":
			_build_automate(2.15)
		"spectre":
			_build_spectre()
		"ondin":
			_build_ondin()
		"garde_maree":
			_build_garde()
		"loup_brumes":
			_build_loup()
		"loup":
			_build_loup(false)
	add_to_group("cibles_v28")
	add_to_group("monstres_v36")
	global_position = at
	facing = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()


func is_boss() -> bool:
	return bool(spec.get("boss", false))


## V68 : les créatures de l'Île de la Balafre (monstre_v68.gd) suivent les mêmes règles :
## ces petites méthodes leur permettent de se glisser dans la mécanique des créatures V63.
func _v63() -> bool:
	return SPECS63.has(kind)


func _leaper() -> bool:
	return kind in LEAPERS


func _sound_pair() -> Array:
	return SOUNDS63.get(kind, ["monstre_menace", "monstre_mort"])


func _armer_anim() -> void:
	if kind in ["automate", "colosse"]:
		_play("v28/slash3", 0.1, 0.55 if kind == "automate" else 0.45)


# =================================================================== réactions aux pouvoirs

func on_power(p: String, _from: Vector3) -> void:
	match kind:
		"garde_maree":
			if p == "vent" and state != "renverse":
				state = "renverse"
				timer = 5.0
				vulnerable_t = 5.0
				_hint("Le Garde-Marée bascule sur le dos ! Vite, frappe-le !")
		"scorpion_roi":
			if p == "flamme":
				stun(3.5)
				vulnerable_t = 3.5
				_hint("La Flamme l'aveugle ! Le Scorpion-Roi est étourdi : frappe !")
		"colosse":
			if p == "rouage":
				stun(4.5)
				vulnerable_t = 4.5
				if _steam != null:
					_steam.emitting = false
				_hint("Les engrenages du Colosse se bloquent ! Son foyer s'ouvre : frappe !")
		"ondin":
			if p == "vent":
				take_hit(4, _from)


func _hint(t: String) -> void:
	if _clock - _last_hint < 3.0:
		return
	_last_hint = _clock
	if manager != null and manager.donjon != null:
		manager.donjon._say(t, 3.5)


## Étourdi (parade parfaite, Rouage, Flamme…) : immobile, des étoiles tournent au-dessus.
func stun(t: float) -> void:
	if state == "mort":
		return
	if not _v63():
		state = "recul"
		timer = t
		return
	_stun = maxf(_stun, t)
	state = "etourdi"
	timer = t
	if _stars == null:
		_stars = Node3D.new()
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = Color(1.0, 0.92, 0.4)
		for i in range(3):
			var s := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = 0.06 * maxf(1.0, hit_height)
			sm.height = sm.radius * 2.0
			s.mesh = sm
			s.material_override = m
			var a: float = TAU * i / 3.0
			s.position = Vector3(cos(a), 0, sin(a)) * (0.3 + hit_radius * 0.4)
			_stars.add_child(s)
		add_child(_stars)
		_stars.position = Vector3.UP * (hit_height * 2.0 + 0.4)
	_stars.visible = true


func set_moonlit(on: bool) -> void:
	if moonlit == on:
		return
	moonlit = on
	if kind in ["spectre", "loup_brumes"]:
		for sm in _shader_mats:
			(sm as ShaderMaterial).set_shader_parameter("lune", 1.0 if on else 0.0)


func take_hit(damage: int, from_pos: Vector3) -> void:
	if not _v63():
		super.take_hit(damage, from_pos)
		return
	if state == "mort":
		return
	var cb: Node = manager.main.combat_v28
	# les fantômes : les coups passent à travers, sauf dans la Lueur de lune
	if kind in ["spectre", "loup_brumes"] and not moonlit:
		if _clock - _through_t > 1.5 and cb != null:
			_through_t = _clock
			cb.float_text(global_position + Vector3.UP * 2.0, "Le coup passe au travers…", Color(0.7, 0.8, 1.0))
		if kind == "spectre" or randf() < 0.5:
			_hint("Tes coups le traversent ! Il faudrait une lumière qui montre ce qui se cache… (la Lueur de lune)")
		return
	# les gardiens cuirassés : presque rien, sauf quand ils sont ouverts
	if is_boss() and kind != "loup_brumes" and vulnerable_t <= 0.0:
		damage = 0 if kind == "garde_maree" else maxi(int(damage / 4), 1)
		if cb != null and _clock - _through_t > 1.2:
			_through_t = _clock
			cb.float_text(global_position + Vector3.UP * (hit_height * 2.0 + 0.6), "Clang !" if damage == 0 else "La cuirasse résiste", Color(0.85, 0.85, 0.9))
		if manager.main.has_method("sfx"):
			manager.main.sfx("touche_carapace", global_position + Vector3.UP * hit_height)
		match kind:
			"garde_maree":
				_hint("Sa carapace arrête tout ! Un vent assez fort pourrait le renverser…")
			"scorpion_roi":
				_hint("Sa cuirasse d'or est trop dure. Ses yeux, eux, craignent le feu…")
			"colosse":
				_hint("Tes coups rebondissent sur le bronze ! Si ses engrenages se bloquaient…")
		if damage == 0:
			_flash = 0.06
			return
	elif is_boss() and vulnerable_t > 0.0:
		damage = int(round(damage * 1.5))
	hp -= damage
	_flash = 0.18
	var away: Vector3 = global_position - from_pos
	away.y = 0.0
	away = away.normalized() if away.length() > 0.01 else -facing
	_knock = away * (3.0 if kind in ["scorpion", "spectre", "ondin"] else (1.2 if kind == "automate" else 0.4))
	if cb != null:
		var at: Vector3 = global_position + Vector3.UP * (hit_height * 2.0 + 0.3)
		if bool(cb.get("critical")):
			cb.damage_number_color(at, damage, Color(1.0, 0.55, 0.2), " !")
		else:
			cb.damage_number(at, damage)
		cb.puff(global_position + Vector3.UP * hit_height, _puff_color())
	if hp <= 0:
		_die63()
		return
	if is_boss() or state in ["etourdi", "renverse"]:
		return
	state = "recul"
	timer = 0.25
	if kind == "automate":
		_play("v28/hurt", 0.05)


func _puff_color() -> Color:
	match kind:
		"scorpion", "scorpion_roi":
			return Color(0.8, 0.65, 0.4)
		"automate", "colosse":
			return Color(0.95, 0.8, 0.45)
		"spectre", "loup_brumes":
			return Color(0.75, 0.85, 1.0)
		"ondin":
			return Color(0.5, 0.8, 1.0)
	return Color(0.8, 0.7, 0.6)


func _die63() -> void:
	var pair: Array = _sound_pair()
	if manager.main.has_method("sfx"):
		manager.main.sfx(str(pair[1]), global_position + Vector3.UP * hit_height)
	state = "mort"
	timer = 0.0
	collision_layer = 0
	collision_mask = 0
	if _stars != null:
		_stars.visible = false
	if kind in ["automate", "colosse"]:
		_play("Knock_Down", 0.1)
		if _steam != null:
			_steam.emitting = false
	died.emit(self)


func _sound63(what: String) -> void:
	if manager == null or manager.main == null or not manager.main.has_method("sfx"):
		return
	var pair: Array = _sound_pair()
	manager.main.sfx(str(pair[0] if what == "menace" else pair[1]), global_position + Vector3.UP * hit_height)


## Le butin (monstres_v36._on_died).
func loot(rng: RandomNumberGenerator) -> Array:
	var g: Array = []
	match kind:
		"scorpion":
			g.append(["piece", rng.randi_range(2, 5)])
			if rng.randf() < 0.15:
				g.append(["rubis", 1])
		"automate":
			g.append(["piece", rng.randi_range(4, 8)])
			if rng.randf() < 0.35:
				g.append(["minerai_fer", 1])
		"spectre":
			g.append(["piece", rng.randi_range(2, 5)])
			if rng.randf() < 0.25:
				g.append(["eclat_cristal", 1])
		"ondin":
			g.append(["piece", rng.randi_range(2, 5)])
			if rng.randf() < 0.2:
				g.append(["perle", 1])
		"loup":
			g.append(["piece", rng.randi_range(2, 5)])
		_:
			g.append(["piece", rng.randi_range(25, 40)])
			g.append(["piece_or", 1])
			match kind:
				"garde_maree":
					g.append(["perle", 2])
				"scorpion_roi":
					g.append(["rubis", 2])
				"colosse":
					g.append(["minerai_fer", 3])
					g.append(["rune_golem", 1])
				"loup_brumes":
					g.append(["eclat_cristal", 3])
	return g


func alert_text() -> String:
	match kind:
		"scorpion":
			return "Des scorpions des sables ! Quand la queue se dresse au-dessus de la tête, la piqûre arrive : recule, roule (Ctrl) ou pare (F), puis frappe."
		"automate":
			return "Un automate de bronze ! Il lève sa hallebarde avant de frapper : pare ou roule. Le Rouage (touche 3) le fige un long moment."
		"spectre":
			return "Des spectres ! Les coups les traversent… La Lueur de lune (touche 4 puis X ; en VR, B) les rend visibles, et vulnérables."
		"ondin":
			return "Un ondin, un esprit de l'eau ! Il se gonfle avant de bondir : écarte-toi. La Bourrasque (touche 1) le disperse."
		"garde_maree":
			return "LE GARDE-MARÉE ! Un crabe grand comme une barque, une carapace couverte de coraux. Rien ne la perce… mais un vent assez fort pourrait le renverser."
		"scorpion_roi":
			return "LE SCORPION-ROI ! Cuirassé d'or, une queue longue comme un mât. Sa cuirasse arrête l'acier… mais ses yeux craignent la flamme."
		"colosse":
			return "LE COLOSSE À VAPEUR ! Un automate haut comme une maison, une chaudière qui gronde dans le dos. Il faudrait bloquer ses engrenages…"
		"loup_brumes":
			return "Deux yeux d'argent dans la brume… LE GRAND LOUP DES BRUMES ! On ne le voit pas, on ne le touche pas. Sauf, peut-être, à la lumière de la lune."
	return ""


# =================================================================== comportement

func _physics_process(delta: float) -> void:
	if not _v63():
		super._physics_process(delta)
		return
	if manager == null:
		return
	_clock += delta
	if _flash > 0.0:
		_flash -= delta
	_apply_flash()
	vulnerable_t = maxf(vulnerable_t - delta, 0.0)
	if state == "mort":
		_death_tick(delta)
		return
	if not manager.active:
		_animate63(delta, 0.0)
		return
	var p: Vector3 = _player()
	if manager.main.xr_active:
		p.y -= 1.5
	var to_p: Vector3 = p - global_position
	var dy: float = absf(to_p.y)
	to_p.y = 0.0
	var dist: float = to_p.length()
	var dir_p: Vector3 = to_p / dist if dist > 0.01 else facing
	var from_home: float = Vector2(global_position.x - home.x, global_position.z - home.z).length()
	var move := Vector3.ZERO
	timer -= delta
	var leap: bool = _leaper()
	match state:
		"etourdi":
			if timer <= 0.0:
				_stun = 0.0
				state = "chasse"
				if _stars != null:
					_stars.visible = false
				if kind == "colosse" and _steam != null:
					_steam.emitting = true
		"renverse":
			if timer <= 0.0:
				state = "chasse"
				_hint("Le Garde-Marée se remet sur ses pattes !")
		"veille":
			if dist < float(spec["vue"]) and dy < 4.0:
				state = "chasse"
				manager.alert(self)
				if is_boss():
					_sound63("menace")
			elif from_home > 1.0:
				var back: Vector3 = home - global_position
				back.y = 0.0
				move = back.normalized() * float(spec["vitesse"]) * 0.5
				facing = facing.lerp(back.normalized(), delta * 4.0).normalized()
		"chasse":
			if not is_boss() and (dist > float(spec["vue"]) * 1.6 or from_home > float(spec["laisse"]) or dy > 4.0):
				state = "veille"
			elif dist <= float(spec["portee"]):
				state = "armer"
				_sound63("menace")
				timer = float(spec["armer"])
				_armer_anim()
			else:
				move = dir_p * float(spec["vitesse"])
				if from_home > float(spec["laisse"]):
					move *= 0.0
			facing = facing.lerp(dir_p, clampf(delta * (8.0 if not is_boss() else 3.0), 0.0, 1.0)).normalized()
			_boss_tick(delta, dist)
		"armer":
			facing = facing.lerp(dir_p, clampf(delta * (5.0 if not is_boss() else 2.5), 0.0, 1.0)).normalized()
			if timer <= 0.0:
				state = "frappe"
				timer = 0.2
				if leap:
					timer = 0.34
					_knock = facing * float(spec.get("bond", 7.0))
				else:
					_strike(dist, dir_p)
					if is_boss():
						_shockwave(global_position + facing * float(spec["portee"]) * 0.7)
		"frappe":
			if leap and timer > 0.1 and dist < float(spec["rayon"]) + 0.9 and not has_meta("mordu"):
				set_meta("mordu", true)
				manager.hurt_player(int(spec["degats"]), global_position)
			if timer <= 0.0:
				if has_meta("mordu"):
					remove_meta("mordu")
				state = "souffle"
				timer = float(spec["repos"])
		"souffle":
			if timer <= 0.0:
				state = "chasse"
		"recul":
			if timer <= 0.0:
				state = "chasse"
	if _knock.length() > 0.05:
		move += _knock
		_knock = _knock.move_toward(Vector3.ZERO, delta * 14.0)
	velocity.x = move.x
	velocity.z = move.z
	if kind == "spectre":
		velocity.y = (home.y + 0.3 + sin(_clock * 1.7) * 0.15 - global_position.y) * 4.0
	else:
		velocity.y = 0.0 if is_on_floor() else maxf(velocity.y - 18.0 * delta, -20.0)
	move_and_slide()
	if not (state in ["renverse", "etourdi"]) or kind == "loup_brumes":
		rotation.y = atan2(facing.x, facing.z)
	_animate63(delta, Vector2(move.x, move.z).length())


## Les gardiens : coups spéciaux (le Scorpion-Roi appelle ses petits, le Colosse crache de la
## vapeur, le Loup disparaît et reparaît ailleurs).
func _boss_tick(delta: float, dist: float) -> void:
	if not is_boss():
		return
	_special_t += delta
	match kind:
		"scorpion_roi":
			if not _summoned and hp < int(spec["pv"]) / 2:
				_summoned = true
				for k in range(3):
					var a: float = TAU * k / 3.0
					var m: Node3D = manager.spawn_extra("scorpion", global_position + Vector3(cos(a) * 3.0, 0.1, sin(a) * 3.0))
					m.home = m.global_position
				_hint("Le Scorpion-Roi frappe le sol de sa queue : des scorpions sortent du sable !")
		"colosse":
			if _special_t > 7.0 and dist < 6.0:
				_special_t = 0.0
				_shockwave(global_position)
				_hint("Le Colosse lâche un jet de vapeur brûlante tout autour de lui !")
		"garde_maree":
			if _special_t > 6.0 and dist > 5.0 and dist < 14.0:
				_special_t = 0.0
				_knock = facing * 9.0
				_hint("Le Garde-Marée charge !")
		"loup_brumes":
			if _special_t > 8.0 and not moonlit:
				_special_t = 0.0
				var p: Vector3 = _player()
				var a2: float = randf() * TAU
				var to: Vector3 = Vector3(p.x + cos(a2) * 6.0, global_position.y, p.z + sin(a2) * 6.0)
				if to.distance_to(home) < float(spec["laisse"]):
					global_position = to
					if manager.main.has_method("sfx"):
						manager.main.sfx("loup_menace", to + Vector3.UP)


## Une onde de choc autour d'un point : le joueur proche est touché (1/2 cœur).
func _shockwave(at: Vector3) -> void:
	var p: Vector3 = _player()
	if manager.main.xr_active:
		p.y -= 1.5
	if Vector2(p.x - at.x, p.z - at.z).length() < 3.2 and absf(p.y - at.y) < 2.0:
		manager.hurt_player(1, at)
	var cb: Node = manager.main.combat_v28
	if cb != null:
		for k in range(8):
			var a: float = TAU * k / 8.0
			cb.puff(at + Vector3(cos(a) * 2.2, 0.3, sin(a) * 2.2), Color(0.85, 0.82, 0.78) if kind != "colosse" else Color(0.95, 0.95, 1.0))
	if manager.main.has_method("sfx"):
		manager.main.sfx("onde_choc", at)


func _death_tick(delta: float) -> void:
	timer += delta
	match kind:
		"scorpion", "scorpion_roi", "garde_maree":
			_visual.rotation.z = minf(timer * 4.0, PI)
			_visual.position.y = sin(minf(timer * 4.0, PI)) * 0.4 * hit_radius
		"spectre", "loup_brumes", "ondin":
			_visual.scale = Vector3.ONE * clampf(1.0 - timer * 1.2, 0.01, 1.0)
			_visual.position.y += delta * 0.6
	if timer > 1.8:
		_visual.scale = Vector3.ONE * clampf(1.0 - (timer - 1.8) / 0.8, 0.01, 1.0)
	if timer > 2.6:
		visible = false
		set_physics_process(false)


# =================================================================== animation

func _animate63(delta: float, speed: float) -> void:
	var walk: float = _clock * (6.0 + speed * 3.0)
	var moving: bool = speed > 0.2
	match kind:
		"scorpion", "scorpion_roi":
			for l in _legs:
				var leg: Node3D = l[0]
				var ph: float = float(l[2]) * 1.7 + (0.0 if float(l[1]) > 0.0 else PI)
				leg.rotation.x = sin(walk + ph) * (0.35 if moving else 0.05)
			var curl: float = 0.0
			if state == "armer":
				curl = 1.0 - clampf(timer / float(spec["armer"]), 0.0, 1.0)
			elif state == "frappe":
				curl = -0.6
			for i in range(_tail.size()):
				var j: Node3D = _tail[i][0]
				j.rotation.x = float(_tail[i][1]) - curl * 0.28 + sin(_clock * 2.0 + i * 0.6) * 0.04
			for pc in _pincers:
				(pc[0] as Node3D).rotation.y = float(pc[1]) * (0.25 + 0.25 * sin(_clock * (9.0 if state == "armer" else 3.0)))
			if state == "etourdi" and _stars != null:
				_stars.rotation.y += delta * 4.0
		"garde_maree":
			for l in _legs:
				var leg2: Node3D = l[0]
				var ph2: float = float(l[2]) * 1.3 + (0.0 if float(l[1]) > 0.0 else PI)
				leg2.rotation.z = float(l[1]) * (0.2 + (sin(walk * 0.7 + ph2) * 0.25 if moving else 0.0) + (sin(_clock * 10.0 + ph2) * 0.6 if state == "renverse" else 0.0))
			var up: float = 1.0 if state == "renverse" else 0.0
			_body_node.rotation.z = lerpf(_body_node.rotation.z, PI * up, clampf(delta * 5.0, 0.0, 1.0))
			_body_node.position.y = lerpf(_body_node.position.y, 1.6 * up, clampf(delta * 5.0, 0.0, 1.0))
			for pc2 in _pincers:
				(pc2[0] as Node3D).rotation.x = -0.5 * (1.0 - clampf(timer / float(spec["armer"]), 0.0, 1.0)) if state == "armer" else 0.1 * sin(_clock * 2.0)
		"automate", "colosse":
			if _anim != null and not (state in ["armer", "frappe", "mort"]):
				if state == "etourdi":
					_anim.pause()
				elif moving:
					_play("Walking", 0.2, maxf(speed / 1.2, 0.6))
				else:
					_play("v28/idle", 0.3)
			if _key_node != null and state != "etourdi":
				_key_node.rotation.z += delta * 3.0
			if _furnace != null:
				_furnace.emission_energy_multiplier = 4.0 if state == "etourdi" else 1.2 + sin(_clock * 3.0) * 0.3
		"spectre":
			_visual.position.y = sin(_clock * 2.2) * 0.08
			var charge: float = 0.0
			if state == "armer":
				charge = 1.0 - clampf(timer / float(spec["armer"]), 0.0, 1.0)
			_visual.rotation.x = lerpf(_visual.rotation.x, 0.5 if state == "frappe" else -0.2 * charge, clampf(delta * 8.0, 0.0, 1.0))
			for sm in _shader_mats:
				(sm as ShaderMaterial).set_shader_parameter("charge", charge)
		"ondin":
			var c2: float = 0.0
			if state == "armer":
				c2 = 1.0 - clampf(timer / float(spec["armer"]), 0.0, 1.0)
			_visual.scale = Vector3(1.0 + c2 * 0.25, 1.0 - c2 * 0.2 + sin(_clock * 6.0) * 0.04, 1.0 + c2 * 0.25)
		"loup_brumes", "loup":
			for l in _legs:
				var leg3: Node3D = l[0]
				var ph3: float = (0.0 if int(l[2]) % 2 == 0 else PI) + (0.0 if float(l[1]) > 0.0 else PI * 0.5)
				leg3.rotation.x = sin(walk * 0.9 + ph3) * (0.6 if moving else 0.04)
			for i in range(_tail.size()):
				(_tail[i][0] as Node3D).rotation.y = sin(_clock * 3.0 + i * 0.5) * 0.15
			var crouch: float = 0.0
			if state == "armer":
				crouch = 1.0 - clampf(timer / float(spec["armer"]), 0.0, 1.0)
			_body_node.position.y = 0.0 - crouch * (0.25 if kind == "loup_brumes" else 0.12)
	if _stars != null and _stars.visible:
		_stars.rotation.y += delta * 4.0


# =================================================================== modèles

func _chitin(c: Color) -> StandardMaterial3D:
	var m := _mat(c, 0.32)
	m.clearcoat_enabled = true
	m.clearcoat = 0.6
	m.clearcoat_roughness = 0.25
	m.metallic_specular = 0.6
	return m


## Le scorpion (et le Scorpion-Roi, en géant cuirassé d'or).
func _build_scorpion(s: float, roi: bool) -> void:
	var shell := _chitin(Color(0.38, 0.24, 0.12) if not roi else Color(0.22, 0.13, 0.07))
	var dark := _chitin(Color(0.16, 0.1, 0.06))
	var gold: StandardMaterial3D = null
	if roi:
		gold = _mat(Color(1.0, 0.76, 0.32), 0.25)
		gold.metallic = 1.0
	var root := Node3D.new()
	root.scale = Vector3.ONE * s
	_visual.add_child(root)
	# céphalothorax et anneaux
	_mesh(root, _sphere(0.24), shell, Vector3(0, 0.27, 0.22), Vector3(1.0, 0.42, 1.15))
	if roi:
		_mesh(root, _sphere(0.25), gold, Vector3(0, 0.31, 0.22), Vector3(0.9, 0.3, 1.0))
		for k in range(5):
			_mesh(root, _cyl(0.0, 0.025, 0.12), gold, Vector3(-0.12 + k * 0.06, 0.4, 0.3), Vector3.ONE, Vector3(-0.3, 0, 0))
	for k in range(5):
		var w: float = 0.22 - k * 0.012
		_mesh(root, _sphere(w), shell, Vector3(0, 0.27, 0.0 - k * 0.12), Vector3(1.0, 0.4, 0.55))
		if roi and k % 2 == 0:
			_mesh(root, _sphere(w * 0.9), gold, Vector3(0, 0.31, 0.0 - k * 0.12), Vector3(1.0, 0.25, 0.5))
	# yeux
	var eye := _mat(Color(0.05, 0.03, 0.02), 0.1)
	if roi:
		eye = _mat(Color(1.0, 0.25, 0.1), 0.2, 3.0)
	for sx in [-1.0, 1.0]:
		_mesh(root, _sphere(0.022), eye, Vector3(sx * 0.05, 0.38, 0.33))
	# la queue : cinq anneaux articulés, l'aiguillon
	var parent: Node3D = root
	var pos := Vector3(0, 0.3, -0.56)
	for i in range(6):
		var j := Node3D.new()
		j.position = pos
		parent.add_child(j)
		var rest: float = -0.55 if i == 0 else -0.42
		j.rotation.x = rest
		_tail.append([j, rest])
		if i < 5:
			_mesh(j, _sphere(0.085 - i * 0.006), shell, Vector3(0, 0, -0.08), Vector3(1.0, 0.9, 1.25))
			if roi:
				_mesh(j, _sphere(0.07 - i * 0.005), gold, Vector3(0, 0.035, -0.08), Vector3(1.0, 0.5, 1.1))
			pos = Vector3(0, 0, -0.16)
		else:
			_mesh(j, _sphere(0.09), dark, Vector3(0, 0, -0.07), Vector3(1.0, 0.9, 1.3))
			_mesh(j, _cyl(0.0, 0.03, 0.18), dark, Vector3(0, -0.06, -0.13), Vector3.ONE, Vector3(-2.3, 0, 0))
		parent = j
	# les pinces
	for sx in [-1.0, 1.0]:
		var arm := Node3D.new()
		arm.position = Vector3(sx * 0.18, 0.27, 0.36)
		arm.rotation.y = sx * 0.5
		root.add_child(arm)
		_mesh(arm, _cyl(0.04, 0.05, 0.3), shell, Vector3(0, 0, 0.13), Vector3.ONE, Vector3(PI * 0.5, 0, 0))
		var hand := Node3D.new()
		hand.position = Vector3(0, 0, 0.3)
		hand.rotation.y = -sx * 0.9
		arm.add_child(hand)
		_mesh(hand, _sphere(0.09), shell, Vector3(0, 0, 0.08), Vector3(1.0, 0.7, 1.5))
		var claw := Node3D.new()
		claw.position = Vector3(0, 0, 0.2)
		hand.add_child(claw)
		_mesh(claw, _cyl(0.0, 0.045, 0.2), dark, Vector3(sx * 0.03, 0, 0.08), Vector3(1, 1, 0.7), Vector3(PI * 0.5, 0, 0))
		var claw2 := Node3D.new()
		claw2.position = Vector3(-sx * 0.04, 0, 0.18)
		hand.add_child(claw2)
		_mesh(claw2, _cyl(0.0, 0.035, 0.17), dark, Vector3(0, 0, 0.07), Vector3(1, 1, 0.7), Vector3(PI * 0.5, 0, 0))
		_pincers.append([claw2, sx])
	# huit pattes
	for sx2 in [-1.0, 1.0]:
		for k2 in range(4):
			var leg := Node3D.new()
			leg.position = Vector3(sx2 * 0.15, 0.27, 0.16 - k2 * 0.11)
			leg.rotation.y = sx2 * (0.4 - k2 * 0.35)
			root.add_child(leg)
			_mesh(leg, _cyl(0.016, 0.022, 0.26), shell, Vector3(sx2 * 0.12, 0.05, 0), Vector3.ONE, Vector3(0, 0, sx2 * -1.0))
			_mesh(leg, _cyl(0.008, 0.016, 0.32), dark, Vector3(sx2 * 0.29, -0.1, 0), Vector3.ONE, Vector3(0, 0, sx2 * 0.5))
			_legs.append([leg, sx2, k2])


## L'automate de bronze (et le Colosse à vapeur, en géant) : la silhouette du héros en laiton,
## heaume rond à fente lumineuse, chaudière et clé de remontage dans le dos, hallebarde.
func _build_automate(s: float) -> void:
	var packed: PackedScene = load("res://assets/models/characters/hero.glb")
	var model: Node3D = packed.instantiate()
	model.scale = Vector3.ONE * 1.05 * s
	_visual.add_child(model)
	_anim = model.find_child("AnimationPlayer", true, false)
	var found := model.find_children("*", "Skeleton3D", true, false)
	var skel: Skeleton3D = found[0] if found.size() > 0 else null
	if _anim != null and skel != null:
		var lib = HeroLib.new()
		lib.hero = model
		lib.anim = _anim
		lib.skel = skel
		lib._build_animations()
		lib.free()
	var brass := StandardMaterial3D.new()
	brass.albedo_color = Color(0.86, 0.66, 0.36)
	brass.metallic = 0.9
	brass.roughness = 0.35
	var tex: Texture2D = load("res://assets/textures/cliquetis/laiton.png") if ResourceLoader.exists("res://assets/textures/cliquetis/laiton.png") else null
	brass.albedo_texture = tex
	brass.uv1_scale = Vector3(3, 3, 3)
	_flash_mats.append(brass)
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		var m: MeshInstance3D = mi
		for k in range(m.mesh.get_surface_count()):
			m.set_surface_override_material(k, brass)
	var dark := _mat(Color(0.12, 0.1, 0.08), 0.5)
	dark.metallic = 0.6
	var copper := _mat(Color(0.75, 0.4, 0.25), 0.35)
	copper.metallic = 0.9
	_eyes_mat = _mat(Color(1.0, 0.7, 0.25), 0.2, 4.0)
	if skel == null:
		return
	# heaume rond, fente lumineuse, petite cheminée
	var helm := Node3D.new()
	_mesh(helm, _sphere(0.16), brass, Vector3(0, 0.02, 0), Vector3(1.05, 1.1, 1.05))
	_mesh(helm, _box_mesh_g(Vector3(0.2, 0.025, 0.04)), _eyes_mat, Vector3(0, 0.03, 0.155))
	_mesh(helm, _cyl(0.025, 0.03, 0.12), copper, Vector3(0.06, 0.2, -0.04))
	_attach(skel, "Head", Vector3(0, 12, 2), helm)
	# épaulières en engrenages
	for side in [["LeftShoulder", -1.0], ["RightShoulder", 1.0]]:
		var pad := Node3D.new()
		var g := MeshInstance3D.new()
		g.mesh = load("res://scripts/pouvoirs_v63.gd").gear_mesh()
		g.material_override = copper
		g.scale = Vector3.ONE * 0.55
		g.rotation.z = PI * 0.5
		pad.add_child(g)
		_attach(skel, str(side[0]), Vector3(float(side[1]) * 10.0, 6, 0), pad)
	# la chaudière, la clé de remontage
	var back := Node3D.new()
	_mesh(back, _cyl(0.13, 0.13, 0.36), copper, Vector3(0, 0, -0.16))
	for k in range(3):
		_mesh(back, _cyl(0.135, 0.135, 0.02), dark, Vector3(0, -0.12 + k * 0.12, -0.16))
	_key_node = Node3D.new()
	_key_node.position = Vector3(0, 0.02, -0.32)
	back.add_child(_key_node)
	_mesh(_key_node, _cyl(0.015, 0.015, 0.16), brass, Vector3(0, 0, -0.07), Vector3.ONE, Vector3(PI * 0.5, 0, 0))
	_mesh(_key_node, _box_mesh_g(Vector3(0.22, 0.07, 0.02)), brass, Vector3(0, 0, -0.16))
	_attach(skel, "Spine02", Vector3(0, 0, 0), back)
	if s > 1.5:
		# le Colosse : un foyer qui rougeoie sur la poitrine, de la vapeur
		_furnace = _mat(Color(1.0, 0.45, 0.12), 0.4, 1.2)
		var chest := Node3D.new()
		_mesh(chest, _cyl(0.11, 0.11, 0.04), dark, Vector3(0, 0, 0.14), Vector3.ONE, Vector3(PI * 0.5, 0, 0))
		_mesh(chest, _cyl(0.085, 0.085, 0.05), _furnace, Vector3(0, 0, 0.15), Vector3.ONE, Vector3(PI * 0.5, 0, 0))
		_attach(skel, "Spine02", Vector3(0, 4, 2), chest)
		_steam = CPUParticles3D.new()
		_steam.amount = 26
		_steam.lifetime = 1.6
		_steam.direction = Vector3.UP
		_steam.spread = 18.0
		_steam.initial_velocity_min = 0.8
		_steam.initial_velocity_max = 1.6
		_steam.gravity = Vector3(0, 0.6, 0)
		_steam.scale_amount_min = 1.0
		_steam.scale_amount_max = 2.4
		var q := QuadMesh.new()
		q.size = Vector2(0.35, 0.35)
		var sm := StandardMaterial3D.new()
		sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		sm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		sm.albedo_color = Color(0.92, 0.92, 0.95, 0.35)
		if manager.main.has_method("_soft_dot_v24"):
			sm.albedo_texture = manager.main._soft_dot_v24()
		q.material = sm
		_steam.mesh = q
		_visual.add_child(_steam)
		_steam.position = Vector3(0.15 * s, 1.9 * s, -0.35 * s)
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.5, 0.2)
		l.light_energy = 1.4
		l.omni_range = 5.0
		_visual.add_child(l)
		l.position = Vector3(0, 1.3 * s, 0.5 * s)
	# la hallebarde
	_spear = Node3D.new()
	_mesh(_spear, _cyl(0.022, 0.022, 2.0), dark, Vector3(0, 0.3, 0))
	_mesh(_spear, _box_mesh_g(Vector3(0.26, 0.2, 0.02)), brass, Vector3(0.1, 1.2, 0))
	_mesh(_spear, _cyl(0.0, 0.035, 0.28), brass, Vector3(0, 1.42, 0))
	var att := BoneAttachment3D.new()
	att.bone_name = "RightHand"
	skel.add_child(att)
	var hold := Node3D.new()
	hold.position = Vector3(0, 8.5, 2.5)
	hold.rotation_degrees = Vector3(90, 0, 0)
	hold.scale = Vector3.ONE * 100.0
	att.add_child(hold)
	hold.add_child(_spear)
	_play("v28/idle")


static var _ghost_sh: Shader


static func ghost_shader() -> Shader:
	if _ghost_sh != null:
		return _ghost_sh
	_ghost_sh = Shader.new()
	_ghost_sh.code = """shader_type spatial;
render_mode blend_add, unshaded, cull_disabled, depth_draw_never;
uniform vec4 teinte : source_color = vec4(0.6, 0.75, 1.0, 1.0);
uniform float lune = 0.0;
uniform float charge = 0.0;
uniform float base_alpha = 0.22;
varying vec3 lp;
float h3(vec3 p) { return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453); }
float n3(vec3 p) {
	vec3 i = floor(p); vec3 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(h3(i), h3(i + vec3(1,0,0)), f.x), mix(h3(i + vec3(0,1,0)), h3(i + vec3(1,1,0)), f.x), f.y),
		mix(mix(h3(i + vec3(0,0,1)), h3(i + vec3(1,0,1)), f.x), mix(h3(i + vec3(0,1,1)), h3(i + vec3(1,1,1)), f.x), f.y), f.z);
}
void vertex() {
	lp = VERTEX;
	float sway = sin(TIME * 2.0 + VERTEX.y * 3.0) * 0.04 * (1.0 - clamp(VERTEX.y + 0.5, 0.0, 1.0));
	VERTEX.x += sway;
	VERTEX.z += cos(TIME * 1.7 + VERTEX.y * 2.5) * 0.03;
}
void fragment() {
	float fres = pow(1.0 - abs(dot(NORMAL, VIEW)), 2.2);
	float n = n3(lp * 5.0 + vec3(0.0, -TIME * 0.8, TIME * 0.3)) * 0.6 + n3(lp * 11.0 - vec3(0.0, TIME * 1.3, 0.0)) * 0.4;
	float a = (base_alpha + 0.5 * lune) * (0.35 + 0.65 * fres) * smoothstep(0.15, 0.6, n + 0.25);
	a += charge * 0.25 * fres;
	ALBEDO = teinte.rgb * (0.6 + 0.8 * lune + charge);
	ALPHA = clamp(a, 0.0, 1.0);
}
"""
	return _ghost_sh


func _ghost_mat(c: Color, base_alpha: float) -> ShaderMaterial:
	var sm := ShaderMaterial.new()
	sm.shader = ghost_shader()
	sm.set_shader_parameter("teinte", c)
	sm.set_shader_parameter("base_alpha", base_alpha)
	_shader_mats.append(sm)
	return sm


## Le spectre des brumes : une cape de brume qui flotte, un capuchon vide, deux yeux.
func _build_spectre() -> void:
	var cloak := _ghost_mat(Color(0.62, 0.74, 1.0), 0.22)
	var body := Node3D.new()
	_visual.add_child(body)
	_mesh(body, _cyl(0.16, 0.5, 1.5), cloak, Vector3(0, 0.95, 0))
	_mesh(body, _sphere(0.24), cloak, Vector3(0, 1.75, -0.02), Vector3(1.0, 1.15, 1.1))
	for sx in [-1.0, 1.0]:
		_mesh(body, _cyl(0.05, 0.14, 0.75), cloak, Vector3(sx * 0.32, 1.25, 0.18), Vector3.ONE, Vector3(-0.9, 0, sx * 0.35))
	var hole := _mat(Color(0.0, 0.0, 0.02), 1.0)
	_mesh(body, _sphere(0.15), hole, Vector3(0, 1.72, 0.12), Vector3(1.0, 1.2, 0.6))
	_eyes_mat = _mat(Color(0.6, 0.95, 1.0), 0.2, 6.0)
	for sx2 in [-1.0, 1.0]:
		_mesh(body, _sphere(0.028), _eyes_mat, Vector3(sx2 * 0.06, 1.74, 0.2), Vector3(1.0, 0.6, 0.5))
	var l := OmniLight3D.new()
	l.light_color = Color(0.55, 0.75, 1.0)
	l.light_energy = 0.7
	l.omni_range = 4.0
	l.position = Vector3(0, 1.5, 0.3)
	body.add_child(l)
	_mist_trail(body, Color(0.75, 0.85, 1.0, 0.25))


func _mist_trail(parent: Node3D, c: Color) -> void:
	var p := CPUParticles3D.new()
	p.amount = 22
	p.lifetime = 1.4
	p.local_coords = false
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.35
	p.gravity = Vector3(0, 0.3, 0)
	p.initial_velocity_min = 0.05
	p.initial_velocity_max = 0.2
	p.scale_amount_min = 1.0
	p.scale_amount_max = 2.2
	var q := QuadMesh.new()
	q.size = Vector2(0.4, 0.4)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.albedo_color = c
	if manager.main.has_method("_soft_dot_v24"):
		m.albedo_texture = manager.main._soft_dot_v24()
	q.material = m
	p.mesh = q
	p.position = Vector3(0, 0.6, 0)
	parent.add_child(p)


static var _water_sh: Shader


static func water_shader() -> Shader:
	if _water_sh != null:
		return _water_sh
	_water_sh = Shader.new()
	_water_sh.code = """shader_type spatial;
render_mode cull_back;
uniform float flash = 0.0;
varying vec3 lp;
float h3(vec3 p) { return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453); }
float n3(vec3 p) {
	vec3 i = floor(p); vec3 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(h3(i), h3(i + vec3(1,0,0)), f.x), mix(h3(i + vec3(0,1,0)), h3(i + vec3(1,1,0)), f.x), f.y),
		mix(mix(h3(i + vec3(0,0,1)), h3(i + vec3(1,0,1)), f.x), mix(h3(i + vec3(0,1,1)), h3(i + vec3(1,1,1)), f.x), f.y), f.z);
}
void vertex() {
	lp = VERTEX;
	float w = n3(VERTEX * 4.0 + vec3(0.0, TIME * 1.5, TIME)) - 0.5;
	VERTEX += NORMAL * w * 0.08;
}
void fragment() {
	float fres = pow(1.0 - abs(dot(NORMAL, VIEW)), 3.0);
	float foam = smoothstep(0.62, 0.8, n3(lp * 9.0 + vec3(0.0, -TIME * 2.0, 0.0)));
	ALBEDO = mix(vec3(0.05, 0.22, 0.3), vec3(0.85, 0.95, 1.0), foam * 0.7 + fres * 0.4) + vec3(flash);
	ROUGHNESS = 0.05;
	METALLIC = 0.1;
	SPECULAR = 0.9;
	ALPHA = clamp(0.55 + fres * 0.4 + foam * 0.3, 0.0, 1.0);
	EMISSION = vec3(0.05, 0.25, 0.35) * fres + vec3(flash);
}
"""
	return _water_sh


## L'ondin : une boule d'eau vivante qui ondule, écume et deux yeux bleus.
func _build_ondin() -> void:
	var w := ShaderMaterial.new()
	w.shader = water_shader()
	var body := Node3D.new()
	body.position = Vector3(0, 0.5, 0)
	_visual.add_child(body)
	_mesh(body, _sphere(0.46), w, Vector3.ZERO, Vector3(1.0, 0.95, 1.0))
	_mesh(body, _sphere(0.22), w, Vector3(0.2, 0.35, -0.1))
	_mesh(body, _sphere(0.16), w, Vector3(-0.22, 0.32, 0.05))
	_eyes_mat = _mat(Color(0.7, 1.0, 1.0), 0.2, 5.0)
	for sx in [-1.0, 1.0]:
		_mesh(body, _sphere(0.055), _eyes_mat, Vector3(sx * 0.14, 0.12, 0.4), Vector3(1.0, 0.7, 0.5))
	var l := OmniLight3D.new()
	l.light_color = Color(0.35, 0.8, 1.0)
	l.light_energy = 0.9
	l.omni_range = 4.0
	body.add_child(l)
	var drip := CPUParticles3D.new()
	drip.amount = 18
	drip.lifetime = 0.7
	drip.local_coords = false
	drip.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	drip.emission_sphere_radius = 0.4
	drip.gravity = Vector3(0, -6.0, 0)
	drip.initial_velocity_min = 0.0
	drip.initial_velocity_max = 0.4
	var q := QuadMesh.new()
	q.size = Vector2(0.05, 0.05)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(0.7, 0.9, 1.0, 0.7)
	q.material = m
	drip.mesh = q
	body.add_child(drip)


## Le Garde-Marée : un crabe géant, carapace couverte de coraux et de bernacles, deux pinces
## énormes (une plus grosse), des yeux sur des pédoncules.
func _build_garde() -> void:
	_body_node = Node3D.new()
	_visual.add_child(_body_node)
	var shell := _chitin(Color(0.55, 0.2, 0.12))
	var tex: Texture2D = load("res://assets/textures/coeur/corail.png") if ResourceLoader.exists("res://assets/textures/coeur/corail.png") else null
	if tex != null:
		shell.albedo_texture = tex
		shell.albedo_color = Color(0.85, 0.42, 0.3)
		shell.uv1_scale = Vector3(2, 2, 2)
	var belly := _chitin(Color(0.85, 0.7, 0.55))
	var dark := _chitin(Color(0.18, 0.08, 0.06))
	_mesh(_body_node, _sphere(1.0), shell, Vector3(0, 0.95, 0), Vector3(1.45, 0.55, 1.1))
	_mesh(_body_node, _sphere(0.95), belly, Vector3(0, 0.8, 0), Vector3(1.35, 0.35, 1.0))
	var coral := _mat(Color(0.95, 0.5, 0.45), 0.7)
	var bar := _mat(Color(0.78, 0.76, 0.7), 0.85)
	var rng := RandomNumberGenerator.new()
	rng.seed = 6363
	for k in range(14):
		var a: float = rng.randf() * TAU
		var r: float = rng.randf_range(0.2, 1.1)
		var p := Vector3(cos(a) * r * 1.3, 1.45 - r * r * 0.25, sin(a) * r)
		if k % 2 == 0:
			_mesh(_body_node, _cyl(0.03, 0.09, 0.3), coral, p + Vector3.UP * 0.12, Vector3.ONE, Vector3(rng.randf_range(-0.4, 0.4), 0, rng.randf_range(-0.4, 0.4)))
		else:
			_mesh(_body_node, _cyl(0.05, 0.09, 0.08), bar, p)
	# yeux sur pédoncules
	for sx in [-1.0, 1.0]:
		_mesh(_body_node, _cyl(0.03, 0.04, 0.35), dark, Vector3(sx * 0.25, 1.4, 0.95))
		_mesh(_body_node, _sphere(0.07), _mat(Color(0.02, 0.02, 0.02), 0.05), Vector3(sx * 0.25, 1.6, 0.95))
	# les pinces
	for sx2 in [-1.0, 1.0]:
		var big: float = 1.3 if sx2 > 0.0 else 1.0
		var arm := Node3D.new()
		arm.position = Vector3(sx2 * 1.0, 0.95, 0.85)
		arm.rotation.y = sx2 * 0.4
		_body_node.add_child(arm)
		_mesh(arm, _cyl(0.12, 0.16, 0.8), shell, Vector3(0, 0, 0.35), Vector3.ONE, Vector3(PI * 0.5, 0, 0))
		var claw := Node3D.new()
		claw.position = Vector3(0, 0, 0.8)
		arm.add_child(claw)
		_mesh(claw, _sphere(0.32 * big), shell, Vector3(0, 0, 0.2), Vector3(0.9, 0.7, 1.4))
		_mesh(claw, _cyl(0.0, 0.14 * big, 0.6 * big), dark, Vector3(sx2 * 0.06, 0.05, 0.6 * big), Vector3(1, 1, 0.6), Vector3(PI * 0.5, 0, 0))
		_mesh(claw, _cyl(0.0, 0.1 * big, 0.45 * big), dark, Vector3(-sx2 * 0.08, -0.08, 0.5 * big), Vector3(1, 1, 0.6), Vector3(PI * 0.5, 0, 0))
		_pincers.append([claw, sx2])
	# huit pattes
	for sx3 in [-1.0, 1.0]:
		for k2 in range(4):
			var leg := Node3D.new()
			leg.position = Vector3(sx3 * 1.1, 0.85, 0.45 - k2 * 0.35)
			leg.rotation.y = sx3 * (0.3 - k2 * 0.25)
			_body_node.add_child(leg)
			_mesh(leg, _cyl(0.06, 0.08, 0.9), shell, Vector3(sx3 * 0.38, 0.12, 0), Vector3.ONE, Vector3(0, 0, sx3 * -1.1))
			_mesh(leg, _cyl(0.02, 0.06, 1.0), dark, Vector3(sx3 * 0.9, -0.3, 0), Vector3.ONE, Vector3(0, 0, sx3 * 0.45))
			_legs.append([leg, sx3, k2])


## Le Grand Loup des Brumes : un loup immense fait de brume, deux yeux d'argent.
func _build_loup(ghost: bool = true) -> void:
	_body_node = Node3D.new()
	_visual.add_child(_body_node)
	if not ghost:
		# V72 : le loup gris ordinaire, moitié moins grand, en vraie fourrure
		_body_node.scale = Vector3.ONE * 0.5
	var fur: Material
	if ghost:
		fur = _ghost_mat(Color(0.55, 0.62, 0.85), 0.14)
	else:
		fur = _mat(Color(0.36, 0.34, 0.33), 0.92)
	_mesh(_body_node, _sphere(0.55), fur, Vector3(0, 1.05, -0.2), Vector3(0.9, 0.85, 1.7))
	_mesh(_body_node, _sphere(0.55), fur, Vector3(0, 1.15, 0.55), Vector3(1.0, 1.0, 1.0))
	var neck := Node3D.new()
	neck.position = Vector3(0, 1.35, 0.95)
	_body_node.add_child(neck)
	_mesh(neck, _sphere(0.32), fur, Vector3(0, 0.15, 0.25), Vector3(1.0, 0.95, 1.15))
	_mesh(neck, _cyl(0.08, 0.2, 0.45), fur, Vector3(0, 0.08, 0.6), Vector3(1.0, 0.8, 1.0), Vector3(PI * 0.5, 0, 0))
	for sx in [-1.0, 1.0]:
		_mesh(neck, _cyl(0.0, 0.09, 0.26), fur, Vector3(sx * 0.15, 0.48, 0.15), Vector3.ONE, Vector3(-0.2, 0, sx * -0.25))
	_eyes_mat = _mat(Color(0.85, 0.92, 1.0), 0.2, 7.0) if ghost else _mat(Color(1.0, 0.75, 0.25), 0.2, 3.0)
	for sx2 in [-1.0, 1.0]:
		_mesh(neck, _sphere(0.04), _eyes_mat, Vector3(sx2 * 0.12, 0.24, 0.48), Vector3(1.3, 0.7, 0.6))
	for i in range(4):
		var leg := Node3D.new()
		var sx3: float = -1.0 if i % 2 == 0 else 1.0
		leg.position = Vector3(sx3 * 0.35, 1.0, 0.6 if i < 2 else -0.75)
		_body_node.add_child(leg)
		_mesh(leg, _cyl(0.09, 0.14, 0.6), fur, Vector3(0, -0.3, 0))
		_mesh(leg, _cyl(0.06, 0.08, 0.55), fur, Vector3(0, -0.75, 0.05))
		_legs.append([leg, sx3, i])
	var parent: Node3D = _body_node
	var pos := Vector3(0, 1.2, -1.05)
	for k in range(4):
		var j := Node3D.new()
		j.position = pos
		parent.add_child(j)
		_mesh(j, _sphere(0.16 + k * 0.02), fur, Vector3(0, -0.05, -0.15), Vector3(1.0, 1.0, 1.4))
		_tail.append([j, 0.0])
		parent = j
		pos = Vector3(0, -0.05, -0.28)
	if not ghost:
		return
	var l := OmniLight3D.new()
	l.light_color = Color(0.7, 0.8, 1.0)
	l.light_energy = 0.6
	l.omni_range = 5.0
	l.position = Vector3(0, 1.6, 1.2)
	_body_node.add_child(l)
	_mist_trail(_body_node, Color(0.7, 0.78, 1.0, 0.18))
