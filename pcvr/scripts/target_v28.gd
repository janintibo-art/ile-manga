extends Node3D
## V28 : une cible qu'on peut frapper (mannequin ou jarre).
## Règle commune à toutes les cibles : groupe « cibles_v28 », hit_radius, hit_height,
## is_hittable() et take_hit(dégâts, origine du coup).

var combat: Node
var kind: String = ""
var hit_radius: float = 0.3
var hit_height: float = 1.0
var total_damage: int = 0
var broken: bool = false
var respawn_in: float = 0.0
var tilt: Vector3 = Vector3.ZERO        # vecteur de rotation (axe × angle), horizontal
var tilt_vel: Vector3 = Vector3.ZERO
var _pivot: Node3D


func setup(c: Node, k: String, radius: float, height: float) -> void:
	combat = c
	kind = k
	hit_radius = radius
	hit_height = height
	_pivot = get_node_or_null("Pivot")
	add_to_group("cibles_v28")


func is_hittable() -> bool:
	return not broken


func take_hit(damage: int, from_pos: Vector3) -> void:
	if broken:
		return
	var d: Vector3 = global_position - from_pos
	d.y = 0.0
	d = d.normalized() if d.length() > 0.01 else -global_basis.z
	var local_d: Vector3 = global_basis.inverse() * d
	var center: Vector3 = global_position + Vector3.UP * hit_height
	if kind == "jarre":
		broken = true
		respawn_in = combat.jar_respawn_time
		if _pivot != null:
			_pivot.visible = false
		var body: StaticBody3D = get_node_or_null("Jarre_collision")
		if body != null:
			body.collision_layer = 0
		combat.puff(center, Color(0.66, 0.36, 0.22))
		combat.jar_broken(self)
		return
	total_damage += damage
	# Le mannequin bascule dans le sens du coup, puis revient sur son pied.
	tilt_vel += Vector3.UP.cross(local_d) * (2.2 + damage * 0.9)
	combat.damage_number(global_position + Vector3.UP * 2.0, damage)
	combat.puff(center + d * -0.2, Color(0.82, 0.7, 0.42))


func _process(delta: float) -> void:
	if broken:
		respawn_in -= delta
		if respawn_in <= 0.0 and _player_far():
			broken = false
			if _pivot != null:
				_pivot.visible = true
			var body: StaticBody3D = get_node_or_null("Jarre_collision")
			if body != null:
				body.collision_layer = 1
		return
	if _pivot == null:
		return
	# Ressort amorti.
	tilt_vel += (-tilt * 60.0 - tilt_vel * 5.5) * delta
	tilt += tilt_vel * delta
	var angle: float = tilt.length()
	_pivot.basis = Basis(tilt / angle, minf(angle, 0.7)) if angle > 0.0001 else Basis.IDENTITY


func _player_far() -> bool:
	if combat == null or combat.main == null:
		return true
	var p: Vector3 = combat.main._player_pos_v27()
	return Vector2(p.x - global_position.x, p.z - global_position.z).length() > 2.0
