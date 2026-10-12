from pathlib import Path
import re
p=Path(__file__).resolve().parent/'scripts'/'main.gd'
s=p.read_text(encoding='utf-8')

def replace_func(name, code):
 global s
 m=re.search(r'(?m)^func '+re.escape(name)+r'\([^\n]*\) -> void:\n[\s\S]*?(?=^func |\Z)',s)
 if not m: raise SystemExit('Fonction introuvable: '+name)
 s=s[:m.start()]+code.strip('\n')+'\n\n\n'+s[m.end():]

# IMPORTANT: floor collider triangles must be accessible from above; protect against bad mesh winding.
key='collision.shape = terrain.mesh.create_trimesh_shape()'
if key not in s: raise SystemExit('Collision terrain introuvable; rien modifie.')
# Godot ConcavePolygonShape3D double-sided physics avoids one-sided triangle fallthrough.
s=s.replace(key, key+'\n\tif collision.shape is ConcavePolygonShape3D:\n\t\t(collision.shape as ConcavePolygonShape3D).backface_collision = true',1) if 'backface_collision = true' not in s else s

# Control offset used to keep the imported hero feet on ground. Mesh contents can have a different pivot.
if 'var hero_mesh_floor_offset_v11:' not in s:
 anchor='var pc_hero: Node3D\n'
 if s.count(anchor)!=1: raise SystemExit('Declaration PC hero inattendue')
 s=s.replace(anchor,anchor+'var hero_mesh_floor_offset_v11: float = 0.0\n',1)

# Foot offset read from the actual AABB of the imported meshes (in world coordinates at time of setup).
helper='''func _hero_foot_offset_v11() -> float:
\tif pc_hero == null:
\t\treturn 0.0
\tvar found: bool = false
\tvar min_y: float = 1e20
\tvar pending: Array[Node] = [pc_hero]
\twhile not pending.is_empty():
\t\tvar n: Node = pending.pop_back()
\t\tif n is MeshInstance3D:
\t\t\tvar visual: MeshInstance3D = n as MeshInstance3D
\t\t\tif visual.mesh != null:
\t\t\t\tvar bounds: AABB = visual.get_aabb()
\t\t\t\tfor xx in [0.0, 1.0]:
\t\t\t\t\tfor yy in [0.0, 1.0]:
\t\t\t\t\t\tfor zz in [0.0, 1.0]:
\t\t\t\t\t\t\tvar pt: Vector3 = bounds.position + bounds.size * Vector3(xx, yy, zz)
\t\t\t\t\t\t\tmin_y = minf(min_y, (visual.global_transform * pt).y)
\t\t\t\t\t\t\tfound = true
\t\tfor c in n.get_children():
\t\t\tpending.append(c)
\treturn pc_hero.global_position.y - min_y if found else 0.0
'''
if 'func _hero_foot_offset_v11()' not in s:
 s=s.rstrip()+'\n\n'+helper+'\n'
# Sync hero foot placement, and face away from screen when walking forward.
replace_func('_move_desktop', '''func _move_desktop(delta: float) -> void:
\tvar axis := Vector2.ZERO
\tif Input.is_key_pressed(KEY_Z) or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
\t\taxis.y -= 1.0
\tif Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
\t\taxis.y += 1.0
\tif Input.is_key_pressed(KEY_Q) or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
\t\taxis.x -= 1.0
\tif Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
\t\taxis.x += 1.0
\tif axis.length() > 0.0:
\t\taxis = axis.normalized()
\tvar direction: Vector3 = pc_root.global_basis.x * axis.x + pc_root.global_basis.z * axis.y
\t_move_player(pc_root, direction * WALK_SPEED * delta)
\tif pc_hero != null:
\t\tpc_hero.position = pc_root.position + Vector3.UP * hero_mesh_floor_offset_v11
\t\tif axis.length() > 0.05:
\t\t\t# Mesh GLB is oriented opposite to the old visual rotation.
\t\t\tpc_hero.rotation.y = atan2(-direction.x, -direction.z) + PI
''')
# Only use actual physics for wall interaction. Rescue if stuck underground, once, avoid teleport oscillation near floor.
replace_func('_move_player', '''func _move_player(origin: Node3D, offset: Vector3) -> void:
\tvar body: CharacterBody3D = vr_body if origin == xr_origin else pc_body
\tif body == null:
\t\treturn
\tvar dt: float = maxf(get_physics_process_delta_time(), 0.001)
\tvar ground: float = _height_at(body.position.x, body.position.z)
\tif body.position.y < ground - 0.7:
\t\t# Single rescue outside the surface; capsule must start above the terrain.
\t\tbody.global_position = Vector3(body.position.x, ground + 1.15, body.position.z)
\t\tbody.velocity = Vector3.ZERO
\tbody.velocity.x = offset.x / dt
\tbody.velocity.z = offset.z / dt
\tif body.is_on_floor():
\t\tbody.velocity.y = -0.05
\telse:
\t\tbody.velocity.y = maxf(body.velocity.y - GRAVITY_V11 * dt, -24.0)
\tbody.move_and_slide()
\tbody.position.x = clampf(body.position.x, -72.0, 72.0)
\tbody.position.z = clampf(body.position.z, -72.0, 72.0)
\t# Body origin represents the feet; avoid the old -0.09 m offset.
\torigin.position = body.position
''')
replace_func('_sync_physics_after_load_v11', '''func _sync_physics_after_load_v11() -> void:
\tif vr_body != null:
\t\tvar pos_vr: Vector3 = xr_origin.position
\t\tpos_vr.y = maxf(pos_vr.y, _height_at(pos_vr.x, pos_vr.z) + 0.9)
\t\tvr_body.global_position = pos_vr
\t\tvr_body.velocity = Vector3.ZERO
\t\txr_origin.position = pos_vr
\tif pc_body != null:
\t\tvar pos_pc: Vector3 = pc_root.position
\t\tpos_pc.y = maxf(pos_pc.y, _height_at(pos_pc.x, pos_pc.z) + 0.9)
\t\tpc_body.global_position = pos_pc
\t\tpc_body.velocity = Vector3.ZERO
\t\tpc_root.position = pos_pc
\tif pc_hero != null:
\t\tpc_hero.position = pc_root.position + Vector3.UP * hero_mesh_floor_offset_v11
''')

# Use floor of model automatically, compute after model instance has entered tree.
anchor='pc_hero = _add_glb("res://assets/models/characters/hero.glb", "Heros_PC", pc_root.position, 1.0, 0.0)'
if s.count(anchor)!=1:raise SystemExit('Creation modele hero introuvable')
s=s.replace(anchor,anchor+'\n\thero_mesh_floor_offset_v11 = _hero_foot_offset_v11()',1)
# Snapshot guard
assert s.count('func _move_player(')==1 and s.count('func _move_desktop(')==1
assert s.count('func _sync_physics_after_load_v11(')==1
assert '(right * stick.x + forward * stick.y)' in s
p.write_text(s, encoding='utf-8')
print('V11 stabilisation pieds / mouvement / sens hero appliquee.')
