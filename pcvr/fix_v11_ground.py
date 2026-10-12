"""V11 patch: recover players stuck below the procedural terrain, PC + XR.
Idempotent and intentionally confined to three V11 functions.
"""
from pathlib import Path
import re

p = Path(__file__).resolve().parent / 'scripts' / 'main.gd'
s = p.read_text(encoding='utf-8')

def replace_function(name, source):
    global s
    pattern = re.compile(r'(?m)^func ' + re.escape(name) + r'\([^\n]*\) -> void:\n[\s\S]*?(?=^func |\Z)')
    m = pattern.search(s)
    if not m:
        raise SystemExit('Fonction V11 introuvable : ' + name)
    s = s[:m.start()] + source.rstrip() + '\n\n\n' + s[m.end():]

if 'ILE_MANGA_V11_SOL_CORRECTION' not in s:
    replace_function('_move_player', '''func _move_player(origin: Node3D, offset: Vector3) -> void:
	# ILE_MANGA_V11_SOL_CORRECTION: recuperation si capsule sous le terrain.
	var body: CharacterBody3D = vr_body if origin == xr_origin else pc_body
	if body == null:
		return
	var step: float = maxf(get_physics_process_delta_time(), 0.001)
	var ground_before: float = _height_at(body.position.x, body.position.z)
	if body.position.y < ground_before - 0.12:
		body.position.y = ground_before + 0.22
		body.velocity.y = 0.0
	body.velocity.x = offset.x / step
	body.velocity.z = offset.z / step
	if body.is_on_floor():
		body.velocity.y = -0.2
	else:
		body.velocity.y -= GRAVITY_V11 * step
	body.move_and_slide()
	body.position.x = clampf(body.position.x, -72.0, 72.0)
	body.position.z = clampf(body.position.z, -72.0, 72.0)
	# Filet de securite: evite une chute indefinie si un triangle
	# de collision est absent/inverse ou si une sauvegarde est ancienne.
	var ground_after: float = _height_at(body.position.x, body.position.z)
	if body.position.y < ground_after + 0.02:
		body.position.y = ground_after + 0.12
		body.velocity.y = maxf(0.0, body.velocity.y)
	origin.position = body.position - Vector3.UP * 0.09''')
    replace_function('_sync_physics_after_load_v11', '''func _sync_physics_after_load_v11() -> void:
	# Place le joueur sur le relief, meme pour une sauvegarde creee avant V11.
	if vr_body != null:
		var start_vr: Vector3 = xr_origin.position
		start_vr.y = maxf(start_vr.y, _height_at(start_vr.x, start_vr.z) + 0.04)
		xr_origin.position = start_vr
		vr_body.position = start_vr + Vector3.UP * 0.18
		vr_body.velocity = Vector3.ZERO
	if pc_body != null:
		var start_pc: Vector3 = pc_root.position
		start_pc.y = maxf(start_pc.y, _height_at(start_pc.x, start_pc.z) + 0.04)
		pc_root.position = start_pc
		pc_body.position = start_pc + Vector3.UP * 0.18
		pc_body.velocity = Vector3.ZERO''')
    # Lift initial spawn slightly, but don't change the terrain, controllers or obstacle sizes.
    old = 'body.position = spawn + Vector3.UP * 0.09'
    assert s.count(old) == 1, 'Initialisation du corps modifiee; correction manuelle requise'
    s = s.replace(old, 'body.position = spawn + Vector3.UP * 0.22')
    p.write_text(s, encoding='utf-8')
    print('V11 collision: correction du sol installee.')
else:
    print('V11 collision: correctif deja applique.')

s = p.read_text(encoding='utf-8')
assert s.count('ILE_MANGA_V11_SOL_CORRECTION') == 1
assert s.count('func _move_player(') == 1
assert s.count('func _sync_physics_after_load_v11(') == 1
assert '(right * stick.x + forward * stick.y)' in s
print('V11 : controles statiques OK. Compilation Godot a verifier sur GitHub.')
