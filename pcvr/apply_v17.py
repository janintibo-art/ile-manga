"""Applique la V17 à une copie locale à jour d'Île Manga. Idempotent."""
from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]
main = root / 'pcvr/scripts/main.gd'
workflow = root / '.github/workflows/build-pcvr-native.yml'
project = root / 'pcvr/project.godot'
exports = root / 'pcvr/export_presets.cfg'
scenery = root / 'pcvr/scripts/scenery_v17.gd'
assert scenery.is_file(), 'Décor V17 introuvable'
s = main.read_text()
if '\t_create_scenery_v17()' not in s:
    anchor = '\t_create_scenery_v16()'
    assert s.count(anchor) == 1, 'Point insertion V16 non unique'
    s = s.replace(anchor, anchor + '\n\t_create_scenery_v17()', 1)
if 'func _create_scenery_v17() -> void:' not in s:
    s += '''\n\nfunc _create_scenery_v17() -> void:
\tvar scenic := preload("res://scripts/scenery_v17.gd").new()
\tscenic.name = "Sentiers_et_clairieres_v17"
\tadd_child(scenic)
\tscenic.build(Callable(self, "_height_at"), OS.has_feature("ile_manga_pc"))
'''
assert s.count('func _create_scenery_v17() -> void:') == 1
assert '_sync_physics_after_load_v11()' in s
main.write_text(s)
for p in (workflow, exports):
    s = p.read_text()
    s = s.replace('v16', 'v17').replace('v15', 'v17') if p == workflow else s.replace('v16.exe', 'v17.exe').replace('"16.0.0.0"', '"17.0.0.0"')
    if p == workflow:
        assert 'Ile_Manga_VR_v17.exe' in s and 'Ile_Manga_PC_v17.exe' in s
        assert 'Ile-Manga-VR-v17' in s and 'Ile-Manga-PC-v17' in s
        assert '_sync_physics_after_load_v11()' in s
    p.write_text(s)
s = project.read_text()
s, n = re.subn(r'config/name="Ile Manga VR V\d+"', 'config/name="Ile Manga VR V17"', s)
assert n == 1
project.write_text(s)
print('V17 appliquée : décors visuels, deux exports, sauvegardes et physique V11 inchangées.')
