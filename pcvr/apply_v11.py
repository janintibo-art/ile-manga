from pathlib import Path
import re
root=Path(__file__).resolve().parents[1]
p=root/'pcvr/scripts/main.gd'
s=p.read_text(encoding='utf-8')
if 'ILE_MANGA_PHYSICS_V11' in s:
 print('V11 déjà appliquée'); raise SystemExit(0)

def replace_once(old,new):
 global s
 n=s.count(old)
 if n!=1: raise RuntimeError(f'V11 : attendu exactement 1 ancrage, trouvé {n}: {old[:100]!r}')
 s=s.replace(old,new,1)

replace_once('var game_started: bool = false', '''var game_started: bool = false
# ILE_MANGA_PHYSICS_V11 : locomotion par CharacterBody3D et obstacles statiques.
var vr_body: CharacterBody3D
var pc_body: CharacterBody3D
const GRAVITY_V11: float = 18.0
const COLLISION_LAYER_V11: int = 1
''')
replace_once('\t_create_players()\n\t_init_native_xr()', '\t_create_players()\n\t_build_physical_world_v11()\n\t_init_native_xr()')
replace_once('\tadd_child(terrain)\n\n\nfunc _create_water()', '''\tadd_child(terrain)
	# Le relief est un corps statique triangulé pour la gravité et les pentes.
	var terrain_body := StaticBody3D.new()
	terrain_body.name = "Sol_collision_v11"
	terrain_body.collision_layer = COLLISION_LAYER_V11
	terrain_body.collision_mask = 0
	var collision := CollisionShape3D.new()
	collision.shape = terrain.mesh.create_trimesh_shape()
	terrain_body.add_child(collision)
	add_child(terrain_body)


func _create_water()''')
# replace part of tree once after trunk child
replace_once('\tadd_child(trunk)\n\t# Trois couronnes', '''\tadd_child(trunk)
	_add_obstacle_cylinder_v11("Tronc_collision", Vector3(x, y + height * 0.5, z), 0.34, height)
	# Trois couronnes''')
# Replace movement function with physics based mover and helpers, before unhandled input
start=s.index('func _move_player(origin: Node3D, offset: Vector3) -> void:')
end=s.index('\n\nfunc _unhandled_input(',start)
new_motion='''func _build_physical_world_v11() -> void:
	vr_body = _new_player_body_v11("Physique_Quest3", xr_origin.position)
	pc_body = _new_player_body_v11("Physique_PC", pc_root.position)
	# Les maisons ont quatre murs de collision avec une entrée libre côté village.
	# Ce sont des proxys simples ; les maillages détaillés viendront plus tard.
	_add_obstacle_box_v11("Maison_fond", Vector3(9, _height_at(9, 4) + 2.0, 7.3), Vector3(7.0, 4.0, 0.45))
	_add_obstacle_box_v11("Maison_gauche", Vector3(5.5, _height_at(5.5, 4) + 2.0, 4), Vector3(0.45, 4, 6.6))
	_add_obstacle_box_v11("Maison_droite", Vector3(12.5, _height_at(12.5, 4) + 2.0, 4), Vector3(0.45, 4, 6.6))
	_add_obstacle_box_v11("Maison_facade_gauche", Vector3(6.5, _height_at(6.5, 1) + 2.0, 1), Vector3(3.0, 4, 0.45))
	_add_obstacle_box_v11("Maison_facade_droite", Vector3(11.5, _height_at(11.5, 1) + 2.0, 1), Vector3(3.0, 4, 0.45))
	_add_obstacle_box_v11("Petite_maison_fond", Vector3(-11, _height_at(-11, 9) + 1.5, 11.4), Vector3(5, 3, 0.4))
	_add_obstacle_box_v11("Petite_maison_cote_1", Vector3(-13.5, _height_at(-13.5, 9) + 1.5, 9), Vector3(0.4, 3, 5))
	_add_obstacle_box_v11("Petite_maison_cote_2", Vector3(-8.5, _height_at(-8.5, 9) + 1.5, 9), Vector3(0.4, 3, 5))
	# Le feu et les installations du DJ sont solides, contrairement aux fleurs.
	_add_obstacle_cylinder_v11("Feu_collision", Vector3(0, _height_at(0, 4) + 0.55, 4), 0.9, 1.1)
	_add_obstacle_box_v11("DJ_mur_collision", Vector3(0, _height_at(0, 60) + 2.0, 60), Vector3(7.0, 4.0, 1.5))
	_add_obstacle_box_v11("DJ_table_collision", Vector3(9, _height_at(9, 60) + 0.8, 60), Vector3(2.6, 1.6, 1.7))
	print("ILE_MANGA_PHYSICS_V11: terrain, maisons, arbres et props solides")


func _new_player_body_v11(label: String, spawn: Vector3) -> CharacterBody3D:
	var body := CharacterBody3D.new()
	body.name = label
	body.collision_layer = 2
	body.collision_mask = COLLISION_LAYER_V11
	body.floor_snap_length = 0.32
	body.floor_max_angle = deg_to_rad(45.0)
	body.safe_margin = 0.03
	body.position = spawn + Vector3.UP * 0.09
	var shape := CollisionShape3D.new()
	shape.name = "Capsule_joueur"
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.32
	capsule.height = 1.7
	shape.shape = capsule
	shape.position.y = 0.87
	body.add_child(shape)
	add_child(body)
	return body


func _add_obstacle_box_v11(label: String, pos: Vector3, dimensions: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = label
	body.position = pos
	body.collision_layer = COLLISION_LAYER_V11
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = dimensions
	shape.shape = box
	body.add_child(shape)
	add_child(body)


func _add_obstacle_cylinder_v11(label: String, pos: Vector3, radius: float, height: float) -> void:
	var body := StaticBody3D.new()
	body.name = label
	body.position = pos
	body.collision_layer = COLLISION_LAYER_V11
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = radius
	cylinder.height = height
	shape.shape = cylinder
	body.add_child(shape)
	add_child(body)


func _move_player(origin: Node3D, offset: Vector3) -> void:
	var body: CharacterBody3D = vr_body if origin == xr_origin else pc_body
	if body == null:
		return
	# Mouvement physique avec glissement sur les murs et gravité réelle.
	# L'autre personnage (PC/VR) est sur une couche indépendante.
	var step: float = maxf(get_physics_process_delta_time(), 0.001)
	body.velocity.x = offset.x / step
	body.velocity.z = offset.z / step
	if body.is_on_floor():
		body.velocity.y = -0.2
	else:
		body.velocity.y -= GRAVITY_V11 * step
	body.move_and_slide()
	body.position.x = clampf(body.position.x, -72.0, 72.0)
	body.position.z = clampf(body.position.z, -72.0, 72.0)
	origin.position = body.position - Vector3.UP * 0.09


func _sync_physics_after_load_v11() -> void:
	if vr_body != null:
		vr_body.position = xr_origin.position + Vector3.UP * 0.09
		vr_body.velocity = Vector3.ZERO
	if pc_body != null:
		pc_body.position = pc_root.position + Vector3.UP * 0.09
		pc_body.velocity = Vector3.ZERO
'''
s=s[:start]+new_motion+s[end:]
# main process physics rather than rendering
replace_once('func _process(delta: float) -> void:', 'func _physics_process(delta: float) -> void:')
# XR motion always integrates gravity when stick idle
replace_once('''		_move_player(xr_origin, move * minf(stick.length(), 1.0) * WALK_SPEED * delta)
	var turn: float''','''		_move_player(xr_origin, move * minf(stick.length(), 1.0) * WALK_SPEED * delta)
	else:
		_move_player(xr_origin, Vector3.ZERO)
	var turn: float''')
# PC always integrates gravity
replace_once('''		if pc_hero != null:
			pc_hero.position = pc_root.position


func _build_physical_world_v11()''','''	else:
		_move_player(pc_root, Vector3.ZERO)
	if pc_hero != null:
		pc_hero.position = pc_root.position


func _build_physical_world_v11()''')
# save loading synchronizes physics
replace_once('\tautosave_clock = 0.0\n\n\nfunc _delete_slot', '\t_sync_physics_after_load_v11()\n\tautosave_clock = 0.0\n\n\nfunc _delete_slot')
# present as version 11
s=s.replace('ÎLE MANGA VR V6', 'ÎLE MANGA VR V11').replace('ÎLE MANGA PC V6','ÎLE MANGA PC V11')
p.write_text(s,encoding='utf-8')
# keep both exe and exports versioned without touching menu
preset=root/'pcvr/export_presets.cfg'
t=preset.read_text(encoding='utf-8')
t=re.sub(r'Ile_Manga_(VR|PC)_v\d+\.exe',lambda m:f'Ile_Manga_{m.group(1)}_v11.exe',t)
t=re.sub(r'(?m)^application/(file_version|product_version)="\d+\.0\.0\.0"',r'application/\1="11.0.0.0"',t)
preset.write_text(t,encoding='utf-8')
proj=root/'pcvr/project.godot'
t=proj.read_text(encoding='utf-8');t=re.sub(r'config/name="Ile Manga VR V\d+"','config/name="Ile Manga VR V11"',t);proj.write_text(t,encoding='utf-8')
workflow=root/'.github/workflows/build-pcvr-native.yml'
t=workflow.read_text(encoding='utf-8')
t=re.sub(r'(Ile_Manga_(?:VR|PC)_v)\d+\.exe',r'\g<1>11.exe',t)
t=re.sub(r'(Ile-Manga-(?:VR|PC)-v)\d+',r'\g<1>11',t)
t=re.sub(r'(ile_manga_v)\d+_',r'\g<1>11_',t)
# additionally fail build if physics not present
needle='      - name: Controle GDScript (VR)'
assert needle in t
t=t.replace(needle,'''      - name: Controler la physique V11
        run: |
          python3 - <<'PYTEST'
          from pathlib import Path
          s = Path('pcvr/scripts/main.gd').read_text()
          for name in ('CharacterBody3D.new()', 'move_and_slide()', 'create_trimesh_shape()', 'CapsuleShape3D.new()', '_sync_physics_after_load_v11()'):
              assert name in s, f'Physique manquante: {name}'
          assert s.count('func _physics_process(delta: float) -> void:') == 1
          print('Contrôles statiques physique OK')
          PYTEST

'''+needle,1)
workflow.write_text(t,encoding='utf-8')
print('V11 appliquée : collisions, gravité, deux exports.')
