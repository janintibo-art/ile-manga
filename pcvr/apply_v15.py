"""Safe, repeatable V15 visual-only patch for ile-manga checkout."""
from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]
main = root / 'pcvr/scripts/main.gd'
scene = root / 'pcvr/scripts/scenery_v15.gd'
workflow = root / '.github/workflows/build-pcvr-native.yml'
presets = root / 'pcvr/export_presets.cfg'
project = root / 'pcvr/project.godot'
assert scene.is_file(), 'Missing V15 scenic resource'
s = main.read_text(encoding='utf-8')
assert 'func _create_scenery_v13() -> void:' in s, 'V13 missing: update local repo first'
assert '_sync_physics_after_load_v11()' in s, 'Physics code changed; aborting'
if '\t_create_scenery_v15()' not in s:
    anchor = '\t_create_scenery_v13()\n'
    assert s.count(anchor) == 1, 'Unexpected main initialization'
    s = s.replace(anchor, anchor + '\t_create_scenery_v15()\n')
if 'func _create_scenery_v15() -> void:' not in s:
    s += '''\n\nfunc _create_scenery_v15() -> void:
\tvar scenic := preload("res://scripts/scenery_v15.gd").new()
\tscenic.name = "Paysages_v15"
\tadd_child(scenic)
\tscenic.build(Callable(self, "_height_at"), OS.has_feature("ile_manga_pc"))
'''
assert s.count('func _create_scenery_v15() -> void:') == 1
main.write_text(s, encoding='utf-8')

for path in (workflow, presets):
    text = path.read_text(encoding='utf-8')
    text = re.sub(r'Ile_Manga_(VR|PC)_v\d+\.exe', r'Ile_Manga_\1_v15.exe', text)
    text = re.sub(r'Ile-Manga-(VR|PC)-v\d+', r'Ile-Manga-\1-v15', text)
    text = re.sub(r'ile_manga_v\d+_', 'ile_manga_v15_', text)
    if path == presets:
        text = re.sub(r'(application/(?:file|product)_version=")\d+\.0\.0\.0', r'\g<1>15.0.0.0', text)
    path.write_text(text, encoding='utf-8')

text = project.read_text(encoding='utf-8')
text = re.sub(r'config/name="Ile Manga VR V\d+"', 'config/name="Ile Manga VR V15"', text)
project.write_text(text, encoding='utf-8')

assert 'Ile_Manga_VR_v15.exe' in workflow.read_text()
assert 'Ile_Manga_PC_v15.exe' in workflow.read_text()
assert "'_sync_physics_after_load_v11()'" in workflow.read_text(), 'Physics CI test unexpectedly changed'
print('V15 graphique installée : aucune modification des mouvements ni collisions.')
