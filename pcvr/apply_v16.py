"""Applies V16 scenery as a minimal, idempotent update to a V15 checkout."""
from pathlib import Path
import re
root = Path(__file__).resolve().parent.parent
main = root / 'pcvr/scripts/main.gd'
s = main.read_text(encoding='utf-8')
anchor = '\t_create_scenery_v15()\n'
assert anchor in s, 'V15 source missing: pull main before applying V16'
call = '\t_create_scenery_v16()\n'
if call not in s:
    s = s.replace(anchor, anchor + call, 1)
function = '''func _create_scenery_v16() -> void:
	var scenic := preload("res://scripts/scenery_v16.gd").new()
	scenic.name = "Forets_feeriques_v16"
	add_child(scenic)
	scenic.build(Callable(self, "_height_at"), OS.has_feature("ile_manga_pc"))


'''
if 'func _create_scenery_v16() -> void:' not in s:
    insertion_point = s.index('func _create_scenery_v13() -> void:')
    s = s[:insertion_point] + function + s[insertion_point:]
main.write_text(s, encoding='utf-8')
for path in (root / '.github/workflows/build-pcvr-native.yml', root / 'pcvr/export_presets.cfg'):
    t = path.read_text(encoding='utf-8')
    t = re.sub(r'v1[345]([_.\-])', r'v16\1', t, flags=re.I)
    t = t.replace('15.0.0.0', '16.0.0.0')
    if path.name == 'build-pcvr-native.yml':
        # Keep function-name assertions and existing V11 physics controls untouched.
        assert 'Ile_Manga_PC_v16.exe' in t and 'Ile_Manga_VR_v16.exe' in t
    path.write_text(t, encoding='utf-8')
p = root / 'pcvr/project.godot'
t = p.read_text(encoding='utf-8').replace('Ile Manga VR V15', 'Ile Manga VR V16')
p.write_text(t, encoding='utf-8')
assert s.count('func _create_scenery_v16() -> void:') == 1
assert s.count('_create_scenery_v16()\n') == 1
print('V16 installed: forests, original physics intact, PC/VR export filenames updated.')
