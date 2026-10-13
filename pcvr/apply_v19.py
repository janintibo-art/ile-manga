"""Patch idempotent V19 de la branche V17/V18, sans modifier la physique."""
from pathlib import Path
import re
root=Path(__file__).resolve().parent.parent
pc=root/'pcvr'
main=pc/'scripts/main.gd'
s=main.read_text()
if '_create_village_v19()' not in s:
    anchor='\t_create_structures()'
    assert s.count(anchor)==1, 'Point insertion du decor non unique'
    s=s.replace(anchor,anchor+'\n\t_create_village_v19()',1)
if 'func _create_village_v19() -> void:' not in s:
    s+='\n\nfunc _create_village_v19() -> void:\n\tvar details := preload("res://scripts/village_v19.gd").new()\n\tdetails.name = "Facades_toitures_v19"\n\tadd_child(details)\n\tdetails.build(Callable(self, "_height_at"), OS.has_feature("ile_manga_pc"))\n'
main.write_text(s)
for name in ('export_presets.cfg','project.godot'):
    p=pc/name
    t=p.read_text()
    t=re.sub(r'Ile Manga VR V\d+','Ile Manga VR V19',t)
    t=re.sub(r'Ile_Manga_(VR|PC)_v\d+\.exe',lambda m:f'Ile_Manga_{m.group(1)}_v19.exe',t)
    t=re.sub(r'(?m)(application/(?:file_version|product_version)=)"\d+\.0\.0\.0"',r'\g<1>"19.0.0.0"',t)
    p.write_text(t)
w=root/'.github/workflows/build-pcvr-native.yml'
t=w.read_text()
t=re.sub(r'Ile_Manga_(VR|PC)_v\d+\.exe',lambda m:f'Ile_Manga_{m.group(1)}_v19.exe',t)
t=re.sub(r'Ile-Manga-(VR|PC)-v\d+',lambda m:f'Ile-Manga-{m.group(1)}-v19',t)
t=re.sub(r'ile_manga_v\d+_(vr|pc)\.log',lambda m:f'ile_manga_v19_{m.group(1)}.log',t)
w.write_text(t)
assert s.count('func _create_village_v19() -> void:')==1
assert 'func _sync_physics_after_load_v11()' in s
assert (pc/'scripts/village_v19.gd').exists()
print('V19 prête : finitions graphiques et exports PC/VR.')
