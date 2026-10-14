extends Node3D
## V34 : un arbre qu'on peut abattre (jeune arbre ou cocotier). Il suit la règle des cibles
## de combat (groupe « cibles_v28 », hit_radius, hit_height, is_hittable, take_hit) ;
## tout le reste (coups de hache, chute, butin, repousse) est géré par bucheron_v34.gd.

var manager: Node
var index: int = 0
var hit_radius: float = 0.3
var hit_height: float = 1.0


func is_hittable() -> bool:
	return manager != null and manager.standing(index)


func take_hit(damage: int, from_pos: Vector3) -> void:
	if manager != null:
		manager.hit(index, damage, from_pos)
