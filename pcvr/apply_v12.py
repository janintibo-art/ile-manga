from pathlib import Path
import re
root=Path(__file__).resolve().parents[1]
main=root/'pcvr/scripts/main.gd'
s=main.read_text(encoding='utf8')
marker='\t_create_village_details_v7()\n'
addition='\t_create_scenery_v12()\n'
if addition not in s:
    if s.count(marker)!=1: raise SystemExit('V12: emplacement de scene introuvable')
    s=s.replace(marker,marker+addition)
    method='''# Details uniquement visuels. Aucun changement des collisions ni des commandes VR.
func _create_scenery_v12() -> void:
	var visuals := preload("res://scripts/visuals_v12.gd").new()
	visuals.name = "Paysages_fantasy_V12"
	add_child(visuals)
	visuals.build(Callable(self, "_height_at"), OS.has_feature("ile_manga_pc"))


'''
    anchor='func _create_village_details_v7() -> void:\n'
    if s.count(anchor)!=1: raise SystemExit('V12: fonction decor V7 introuvable')
    s=s.replace(anchor,method+anchor)
    main.write_text(s,encoding='utf8')

visuals=root/'pcvr/scripts/visuals_v12.gd'
visuals.write_text('''extends Node3D
## Île Manga V12 : décors supplémentaires exclusivement visuels et instanciés.
## Ne crée aucune collision et ne modifie aucun déplacement.

func build(height_fn: Callable, high_quality: bool) -> void:
	_create_flower_beds(height_fn, high_quality)
	_create_shore_pebbles(height_fn, high_quality)
	_create_village_planters(height_fn, high_quality)

func _create_flower_beds(height_fn: Callable, high_quality: bool) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 12102026
	var petals := SphereMesh.new()
	petals.radius = 0.16
	petals.height = 0.21
	petals.radial_segments = 6
	petals.rings = 3
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.94, 0.68, 0.79)
	mat.roughness = 0.9
	petals.material = mat
	var quantity: int = 920 if high_quality else 340
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = petals
	mm.instance_count = quantity
	var placed: int = 0
	for _trial in range(quantity * 12):
		if placed >= quantity:
			break
		var x: float = rng.randf_range(-67.0, 67.0)
		var z: float = rng.randf_range(-67.0, 67.0)
		var y: float = float(height_fn.call(x, z))
		if y < 1.5 or y > 6.2:
			continue
		if Vector2(x - 9.0, z - 4.0).length() < 9.0:
			continue
		if Vector2(x + 11.0, z - 9.0).length() < 7.0:
			continue
		var size: float = rng.randf_range(0.7, 1.25)
		var basis := Basis(Vector3.UP, rng.randf_range(-PI, PI)).scaled(Vector3.ONE * size)
		mm.set_instance_transform(placed, Transform3D(basis, Vector3(x, y + 0.12, z)))
		var palette: Array[Color] = [Color(1.0, 0.68, 0.75), Color(0.98, 0.81, 0.38), Color(0.67, 0.72, 1.0), Color(0.94, 0.87, 0.95)]
		mm.set_instance_color(placed, palette[rng.randi_range(0, palette.size() - 1)])
		placed += 1
	mm.visible_instance_count = placed
	var batch := MultiMeshInstance3D.new()
	batch.name = "Fleurs_prairie_V12"
	batch.multimesh = mm
	batch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	batch.visibility_range_end = 95.0 if high_quality else 60.0
	add_child(batch)

func _create_shore_pebbles(height_fn: Callable, high_quality: bool) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 120612
	var mesh := SphereMesh.new()
	mesh.radius = 0.46
	mesh.height = 0.24
	mesh.radial_segments = 8
	mesh.rings = 4
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.72, 0.70, 0.66)
	mat.roughness = 0.96
	mesh.material = mat
	var amount: int = 520 if high_quality else 180
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = amount
	var placed: int = 0
	for _trial in range(amount * 22):
		if placed >= amount:
			break
		var x: float = rng.randf_range(-77.0, 77.0)
		var z: float = rng.randf_range(-77.0, 77.0)
		var y: float = float(height_fn.call(x, z))
		if y < -0.18 or y > 1.35:
			continue
		var size: float = rng.randf_range(0.35, 1.45)
		var basis := Basis(Vector3.UP, rng.randf_range(-PI, PI)).scaled(Vector3(size, size, size * 0.8))
		mm.set_instance_transform(placed, Transform3D(basis, Vector3(x, y + 0.07, z)))
		var tint: float = rng.randf_range(0.76, 1.13)
		mm.set_instance_color(placed, Color(tint, tint * 0.99, tint * 0.94))
		placed += 1
	mm.visible_instance_count = placed
	var batch := MultiMeshInstance3D.new()
	batch.name = "Galets_rivage_V12"
	batch.multimesh = mm
	batch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	batch.visibility_range_end = 105.0 if high_quality else 65.0
	add_child(batch)

func _create_village_planters(height_fn: Callable, high_quality: bool) -> void:
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.42, 0.27, 0.17)
	var green := StandardMaterial3D.new()
	green.albedo_color = Color(0.25, 0.58, 0.28)
	var flower := StandardMaterial3D.new()
	flower.albedo_color = Color(0.96, 0.72, 0.34)
	var pot_mesh := CylinderMesh.new()
	pot_mesh.top_radius = 0.35
	pot_mesh.bottom_radius = 0.26
	pot_mesh.height = 0.42
	var bush_mesh := SphereMesh.new()
	bush_mesh.radius = 0.42
	bush_mesh.height = 0.7
	bush_mesh.radial_segments = 8
	bush_mesh.rings = 4
	var bud_mesh := SphereMesh.new()
	bud_mesh.radius = 0.11
	bud_mesh.height = 0.2
	bud_mesh.radial_segments = 6
	bud_mesh.rings = 3
	var coords: Array[Vector2] = [Vector2(4, 10), Vector2(-5, 10), Vector2(0, -3), Vector2(14, 8), Vector2(-15, 5), Vector2(12, -4)]
	for i in range(coords.size()):
		if not high_quality and i >= 4:
			break
		var pos: Vector2 = coords[i]
		var y: float = float(height_fn.call(pos.x, pos.y))
		var pot := MeshInstance3D.new()
		pot.name = "Jardiniere_V12"
		pot.mesh = pot_mesh
		pot.material_override = wood
		pot.position = Vector3(pos.x, y + 0.21, pos.y)
		add_child(pot)
		var bush := MeshInstance3D.new()
		bush.name = "Plante_village_V12"
		bush.mesh = bush_mesh
		bush.material_override = green
		bush.position = Vector3(pos.x, y + 0.67, pos.y)
		add_child(bush)
		var bud := MeshInstance3D.new()
		bud.name = "Fleurs_jardiniere_V12"
		bud.mesh = bud_mesh
		bud.material_override = flower
		bud.position = Vector3(pos.x, y + 1.07, pos.y)
		add_child(bud)
''',encoding='utf8')

terrain=root/'pcvr/shaders/terrain.gdshader'
t=terrain.read_text()
if '// ILE_MANGA_V12_TERRAIN' not in t:
    t=t.replace('    ground *= mix(0.91, 1.08, noise2(world_position.xz * 0.18));', '''    // ILE_MANGA_V12_TERRAIN: larges variations douces de teinte (sans changer le relief).
    float broad = noise2(world_position.xz * 0.025);
    ground *= mix(0.87, 1.11, broad);
    ground *= mix(0.94, 1.04, noise2(world_position.xz * 0.18));''')
    terrain.write_text(t)

water=root/'pcvr/shaders/water.gdshader'
t=water.read_text()
if '// ILE_MANGA_V12_WATER' not in t:
    t=t.replace('    ROUGHNESS = 0.27 + ripple.x * 0.04;', '''    // ILE_MANGA_V12_WATER: micro variations de surface sobres et peu couteuses.
    float micro = sin(uv.x * 0.82 + t * 0.45) * cos(uv.y * 0.77 - t * 0.51);
    ALBEDO *= mix(0.97, 1.045, 0.5 + 0.5 * micro);
    ROUGHNESS = 0.25 + ripple.x * 0.04;''')
    water.write_text(t)

project=root/'pcvr/project.godot'
p=project.read_text().replace('Ile Manga VR V11','Ile Manga VR V12')
project.write_text(p)
export=root/'pcvr/export_presets.cfg'
e=export.read_text().replace('_v11.exe','_v12.exe').replace('"11.0.0.0"','"12.0.0.0"')
export.write_text(e)
workflow=root/'.github/workflows/build-pcvr-native.yml'
w=workflow.read_text().replace('_v11','_v12').replace('-v11','-v12')
workflow.write_text(w)
assert (root/'pcvr/scripts/main.gd').read_text().count('func _create_scenery_v12() -> void:')==1
assert 'func _move_player(' in (root/'pcvr/scripts/main.gd').read_text()
assert '_v12.exe' in workflow.read_text()
print('V12 appliquee (decor, shaders, exports PC/VR). Physique et sauvegardes non modifies.')
