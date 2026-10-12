"""Add V13 scenery without touching VR locomotion or V11 physics. Safe to rerun."""
from pathlib import Path
import re
root = Path(__file__).resolve().parents[1]
main = root / 'pcvr/scripts/main.gd'
s = main.read_text(encoding='utf-8')
marker = '\t_create_scenery_v12()'
assert s.count(marker) == 1, 'V12 scenery hook not found exactly once'
if '_create_scenery_v13()' not in s:
    s = s.replace(marker, marker+'\n\t_create_scenery_v13()', 1)
if 'func _create_scenery_v13() -> void:' not in s:
    anchor = 'func _create_village_details_v7() -> void:'
    assert s.count(anchor) == 1
    s = s.replace(anchor, '''func _create_scenery_v13() -> void:
\tvar scenic := preload("res://scripts/scenery_v13.gd").new()
\tscenic.name = "Falaises_cascades_v13"
\tadd_child(scenic)
\tscenic.build(Callable(self, "_height_at"), OS.has_feature("ile_manga_pc"))


'''+anchor, 1)
main.write_text(s, encoding='utf-8')
assert s.count('func _create_scenery_v13() -> void:') == 1
assert s.count('\t_create_scenery_v13()') == 1
for f in ['pcvr/export_presets.cfg', '.github/workflows/build-pcvr-native.yml', 'pcvr/project.godot']:
    p = root / f
    raw = p.read_text(encoding='utf-8')
    raw = raw.replace('Ile_Manga_VR_v12.exe', 'Ile_Manga_VR_v13.exe').replace('Ile_Manga_PC_v12.exe','Ile_Manga_PC_v13.exe')
    raw = raw.replace('Ile-Manga-VR-v12','Ile-Manga-VR-v13').replace('Ile-Manga-PC-v12','Ile-Manga-PC-v13')
    raw = raw.replace('ile_manga_v12_', 'ile_manga_v13_')
    raw = raw.replace('Ile Manga VR V12','Ile Manga VR V13').replace('"12.0.0.0"','"13.0.0.0"')
    p.write_text(raw, encoding='utf-8')
print('V13 installed: scenery, PC/VR build labels; physics unchanged.')
