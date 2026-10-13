"""Safe, repeatable V18 visual-only update for ile-manga GitHub checkout."""
from pathlib import Path
import re
root = Path(__file__).resolve().parent.parent
main = root / 'pcvr/scripts/main.gd'
s = main.read_text()
marker = '\t_create_scenery_v17()'
assert s.count(marker) == 1, 'V17 call must appear once; inspect main.gd'
if '\t_create_village_v18()' not in s:
    s = s.replace(marker, marker+'\n\t_create_village_v18()', 1)
if 'func _create_village_v18() -> void:' not in s:
    new_fn = '''func _create_village_v18() -> void:
	var details := preload("res://scripts/village_v18.gd").new()
	details.name = "Village_amenage_v18"
	add_child(details)
	details.build(Callable(self, "_height_at"), OS.has_feature("ile_manga_pc"))


'''
    anchor = 'func _create_structures() -> void:'
    assert s.count(anchor) == 1, 'Structure function anchor changed'
    s = s.replace(anchor, new_fn + anchor, 1)
assert s.count('func _create_village_v18() -> void:') == 1
assert s.count('\t_create_village_v18()') == 1
main.write_text(s)
w = root/'.github/workflows/build-pcvr-native.yml'
s = w.read_text()
for part in ['Ile_Manga_VR_v17.exe','Ile_Manga_PC_v17.exe','Ile-Manga-VR-v17','Ile-Manga-PC-v17','ile_manga_v17_']:
    s = s.replace(part,part.replace('v17','v18'))
assert 'Ile_Manga_VR_v18.exe' in s and 'Ile_Manga_PC_v18.exe' in s
w.write_text(s)
p = root/'pcvr/export_presets.cfg'
s = p.read_text().replace('v17.exe','v18.exe').replace('"17.0.0.0"','"18.0.0.0"')
p.write_text(s)
p = root/'pcvr/project.godot'
s = p.read_text().replace('Ile Manga VR V17','Ile Manga VR V18')
p.write_text(s)
print('V18 installed; physics and locomotion untouched; GitHub compilation to confirm.')
