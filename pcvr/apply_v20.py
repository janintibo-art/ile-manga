"""Ile Manga V20: rendu et harmonie des materiaux, sans toucher la physique.
Rejouable, avec verification des sources attendues et mise a jour coherente des exports.
"""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
P = ROOT / 'pcvr'
main = P / 'scripts/main.gd'
village = P / 'scripts/village_v19.gd'
terrain = P / 'shaders/terrain.gdshader'
water = P / 'shaders/water.gdshader'
workflow = ROOT / '.github/workflows/build-pcvr-native.yml'
preset = P / 'export_presets.cfg'
project = P / 'project.godot'
for p in (main, village, terrain, water, workflow, preset, project):
    if not p.exists():
        raise SystemExit('Fichier attendu absent : ' + str(p))

# Toutes les validations se font en memoire avant toute ecriture.
updates = {}
def replace_once(text, old, new, label):
    if new in text:
        return text
    count = text.count(old)
    if count != 1:
        raise SystemExit(f'{label}: attendu 1 occurrence, trouve {count}; aucun fichier modifie')
    return text.replace(old, new, 1)

s = main.read_text(encoding='utf-8')
s = replace_once(s, 'sky_mat.sky_top_color = Color(0.17, 0.42, 0.89)', 'sky_mat.sky_top_color = Color(0.24, 0.46, 0.82)', 'ciel haut')
s = replace_once(s, 'sky_mat.sky_horizon_color = Color(0.78, 0.90, 0.99)', 'sky_mat.sky_horizon_color = Color(0.87, 0.92, 0.98)', 'ciel horizon')
s = replace_once(s, 'env.fog_light_color = Color(0.73, 0.84, 0.93)', 'env.fog_light_color = Color(0.82, 0.86, 0.89)', 'brume')
s = replace_once(s, 'sun.light_color = Color(1.0, 0.95, 0.82)', 'sun.light_color = Color(1.0, 0.94, 0.84)', 'soleil couleur')
s = replace_once(s, 'sun.light_energy = 1.15', 'sun.light_energy = 1.08', 'soleil intensite')
updates[main] = s

s = village.read_text(encoding='utf-8')
s = replace_once(s, 'roof.albedo_color = Color(0.48, 0.23, 0.20)', 'roof.albedo_color = Color(0.52, 0.28, 0.22)', 'toiture')
s = replace_once(s, 'timber.albedo_color = Color(0.30, 0.19, 0.13)', 'timber.albedo_color = Color(0.32, 0.22, 0.16)', 'poutres')
s = replace_once(s, 'plaster.albedo_color = Color(0.91, 0.81, 0.63)', 'plaster.albedo_color = Color(0.93, 0.85, 0.70)', 'crepi')
s = replace_once(s, 'window_mat.albedo_color = Color(0.29, 0.63, 0.73)', 'window_mat.albedo_color = Color(0.33, 0.59, 0.68)', 'vitraux')
updates[village] = s

s = terrain.read_text(encoding='utf-8')
s = replace_once(s, 'grass * vec3(0.90, 1.07, 0.90)', 'grass * vec3(0.96, 1.06, 0.91)', 'teinte herbe')
s = replace_once(s, 'ground *= mix(0.91, 1.08, noise2(world_position.xz * 0.18));', 'ground *= mix(0.94, 1.07, noise2(world_position.xz * 0.18));', 'contraste terrain')
updates[terrain] = s

s = water.read_text(encoding='utf-8')
s = replace_once(s, 'vec3(0.13, 0.54, 0.75)', 'vec3(0.15, 0.57, 0.73)', 'eau turquoise')
updates[water] = s

s = workflow.read_text(encoding='utf-8')
if 'Ile_Manga_VR_v19.exe' not in s or 'Ile_Manga_PC_v19.exe' not in s:
    if 'Ile_Manga_VR_v20.exe' not in s or 'Ile_Manga_PC_v20.exe' not in s:
        raise SystemExit('Workflow non V19/V20, arret sans modification')
s = s.replace('Ile_Manga_VR_v19.exe', 'Ile_Manga_VR_v20.exe').replace('Ile_Manga_PC_v19.exe', 'Ile_Manga_PC_v20.exe')
s = s.replace('Ile-Manga-VR-v19', 'Ile-Manga-VR-v20').replace('Ile-Manga-PC-v19', 'Ile-Manga-PC-v20')
s = s.replace('ile_manga_v19_', 'ile_manga_v20_')
updates[workflow] = s

s = preset.read_text(encoding='utf-8')
s = s.replace('v19.exe', 'v20.exe').replace('"19.0.0.0"', '"20.0.0.0"')
updates[preset] = s
s = project.read_text(encoding='utf-8')
s = s.replace('Ile Manga VR V19', 'Ile Manga VR V20')
updates[project] = s

assert 'func _sync_physics_after_load_v11() -> void:' in updates[main]
assert 'func _move_player(' in updates[main]
assert 'Ile_Manga_PC_v20.exe' in updates[workflow]
assert 'Ile_Manga_VR_v20.exe' in updates[workflow]
assert 'Ile-Manga-PC-v20' in updates[workflow]
assert 'Ile-Manga-VR-v20' in updates[workflow]
for path, txt in updates.items():
    if path.read_text(encoding='utf-8') != txt:
        path.write_text(txt, encoding='utf-8')
        print('Mis a jour :', path.relative_to(ROOT))
print('V20 preparee. Compilation Godot et test VR encore necessaires.')
