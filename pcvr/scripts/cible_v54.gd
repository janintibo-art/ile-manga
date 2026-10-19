extends Node3D
## V54 : une cible simple pour l'épée (règle des cibles de combat_v28.gd) : la rune qui
## scelle la chaîne de Ventaile, par exemple. Chaque coup émet « touched ».

signal touched(damage: int, from_pos: Vector3)

var hit_radius: float = 0.6
var hit_height: float = 0.6
var active: bool = true


func _ready() -> void:
	add_to_group("cibles_v28")


func is_hittable() -> bool:
	return active and is_visible_in_tree()


func take_hit(damage: int, from_pos: Vector3) -> void:
	if active:
		touched.emit(damage, from_pos)
