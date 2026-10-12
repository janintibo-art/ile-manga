# V11 stabilization: stable physical locomotion; no ground-height teleport each tick.
from pathlib import Path
import re
p=Path(__file__).resolve().parent/'scripts/main.gd'
s=p.read_text(encoding='utf-8')

def replace(name, source):
    global s
    rx=re.compile(r'(?m)^func '+re.escape(name)+r'\([^\n]*\)(?: -> [^:\n]+)?:\n[\s\S]*?(?=^func |\Z)')
    match=rx.search(s)
    if match is None: raise SystemExit('Fonction introuvable: '+name)
    s=s[:match.start()]+source.rstrip()+'\n\n\n'+s[match.end():]

replace('_move_player', '''func _move_player(origin: Node3D, offset: Vector3) -> void:
	# Corps physique unique : aucune teleportation verticale a chaque image.
	var body: CharacterBody3D = vr_body if origin == xr_origin else pc_body
	if body == null:
		return
	var dt: float = maxf(get_physics_process_delta_time(), 0.001)
	body.velocity.x = offset.x / dt
	body.velocity.z = offset.z / dt
	if body.is_on_floor():
		body.velocity.y = 0.0
	else:
		body.velocity.y -= GRAVITY_V11 * dt
	body.move_and_slide()
	# Secours uniquement si chute sous la carte (jamais proche du sol).
	var ground: float = _height_at(body.position.x, body.position.z)
	if body.position.y < ground - 2.5:
		body.global_position = Vector3(body.position.x, ground + 0.16, body.position.z)
		body.velocity = Vector3.ZERO
	body.position.x = clampf(body.position.x, -72.0, 72.0)
	body.position.z = clampf(body.position.z, -72.0, 72.0)
	origin.position = body.position - Vector3.UP * 0.09''')
# Use physics ticks for movement, but camera smoothing on render frames.
# Godot physics interpolation for visible player origin avoids 90 Hz micro-stutter.
if 'physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON' not in s:
    s=s.replace('pc_root.name = "Joueur_ecran"', 'pc_root.name = "Joueur_ecran"\n\tpc_root.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON')
# Fix spawn collisions initially overlapping and reset after a save load.
if 'body.floor_snap_length = 0.32' in s:
    s=s.replace('body.floor_snap_length = 0.32','body.floor_snap_length = 0.18')
# Camera in PC follows player origin and model faces travel direction.
old='''\tif pc_hero != null:
		pc_hero.position = pc_root.position'''
new='''\tif pc_hero != null:
		pc_hero.position = pc_root.position
		if axis.length() > 0.05:
			var facing: Vector3 = pc_root.global_basis.x * axis.x + pc_root.global_basis.z * axis.y
			pc_hero.rotation.y = atan2(-facing.x, -facing.z)'''
if old in s: s=s.replace(old,new,1)
# Protect VR comfort: physics cameras should not have duplicate active controllers.
assert s.count('func _move_player(')==1
assert s.count('body.move_and_slide()')==1
assert 'if body.position.y < ground - 2.5:' in s
assert '(right * stick.x + forward * stick.y)' in s
p.write_text(s,encoding='utf-8')
print('V11 stabilite: correction sol/gravite et rotation PC appliquees.')
