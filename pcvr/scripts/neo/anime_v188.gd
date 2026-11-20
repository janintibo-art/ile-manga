extends Node3D
## V188 : ce qui bouge dans un étage de la Tour Kumo (les colis d'un tapis roulant, un hologramme qui tourne, un
## drone qui flotte). L'étage y range ses objets ; tout disparaît avec lui.
##   tapis : [nœud, départ, direction, longueur, phase, vitesse]
##   tourne : [nœud, vitesse (rad/s)]
##   flotte : [nœud, centre, hauteur du va-et-vient, vitesse, phase]
var tapis: Array = []
var tourne: Array = []
var flotte: Array = []
##   vrille : [nœud, vitesse (rad/s)] — il tourne sur son axe z (une hélice de face)
var vrille: Array = []
var _t: float = 0.0


func _process(delta: float) -> void:
	_t += delta
	for q in tapis:
		var t: float = fposmod(float(q[4]) + _t * float(q[5]) / maxf(float(q[3]), 0.1), 1.0)
		(q[0] as Node3D).global_position = (q[1] as Vector3) + (q[2] as Vector3) * float(q[3]) * t
	for q2 in tourne:
		(q2[0] as Node3D).rotate_y(delta * float(q2[1]))
	for q3 in flotte:
		(q3[0] as Node3D).global_position = (q3[1] as Vector3) + Vector3.UP * sin(_t * float(q3[3]) + float(q3[4])) * float(q3[2])
	for q4 in vrille:
		(q4[0] as Node3D).rotate_object_local(Vector3(0, 0, 1), delta * float(q4[1]))
