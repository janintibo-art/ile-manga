#!/usr/bin/env python3
# Applique la V10 au code V9. Refuse les ancres inattendues.
from pathlib import Path
import re
P=Path(__file__).resolve().parent

def replace(path, old, new, expected=1):
    file=P/path
    text=file.read_text(encoding='utf-8')
    n=text.count(old)
    if n == expected:
        file.write_text(text.replace(old,new),encoding='utf-8')
        return
    if n == 0 and new in text:
        print(f"Déjà appliqué : {path}")
        return
    raise SystemExit(f"V10: {path}: remplacement non reconnu (ancien={n}; nouveau={new in text}) : {old[:60]!r}")

# La V10 s'applique uniquement à la V9 non modifiée : ne pas casser les scripts du jeu.
main=Path('scripts/main.gd')
replace(main,'var game_menu: Node\n','var game_menu: Node\nvar menu_panorama: Camera3D\nvar panorama_seconds: float = 0.0\n')
replace(main, '\tgame_menu.setup(xr_active, xr_camera, right_hand)\n', '''\tgame_menu.setup(xr_active, xr_camera, right_hand)
\t# Caméra cinématique PC indépendante du joueur. En VR le monde reste stable.
\tif OS.has_feature("ile_manga_pc"):
\t\tmenu_panorama = Camera3D.new()
\t\tmenu_panorama.name = "Panorama_menu_V10"
\t\tmenu_panorama.fov = 66.0
\t\tadd_child(menu_panorama)
\t\tmenu_panorama.position = Vector3(-26.0, 17.0, 35.0)
\t\tmenu_panorama.look_at(Vector3(0, 4, 0), Vector3.UP)
\t\tmenu_panorama.current = true
''')
replace(main,'func _process(delta: float) -> void:\n\tif game_menu != null and xr_active', '''func _process(delta: float) -> void:
\t# Défilement contemplatif seulement pendant un menu PC.
\tif menu_panorama != null and game_menu != null:
\t\tif game_menu.opened:
\t\t\tpanorama_seconds += delta
\t\t\tvar angle: float = panorama_seconds * 0.055
\t\t\tmenu_panorama.position = Vector3(-26.0 + sin(angle) * 6.0, 16.5 + sin(angle * 1.3) * 1.2, 33.0 + cos(angle) * 4.0)
\t\t\tmenu_panorama.look_at(Vector3(0, 4.5, 0), Vector3.UP)
\t\t\tif not menu_panorama.current:
\t\t\t\tmenu_panorama.current = true
\t\telif menu_panorama.current:
\t\t\tpc_camera.current = true
\tif game_menu != null and xr_active''')

menu=Path('scripts/menu_v8.gd')
replace(menu,'var heading: Label\n', 'var heading: Label\nvar menu_glow_time: float = 0.0\n')
replace(menu,'frame.color = Color(0.035, 0.08, 0.15, 0.94)', 'frame.color = Color(0.018, 0.047, 0.085, 0.42)')
replace(menu,'card.custom_minimum_size = Vector2(650, 510)','card.custom_minimum_size = Vector2(690, 540)')
replace(menu,'style.bg_color = Color(0.035, 0.11, 0.16, 0.98)','style.bg_color = Color(0.025, 0.095, 0.145, 0.93)')
replace(menu,'style.border_color = Color(0.89, 0.71, 0.36)','style.border_color = Color(0.98, 0.76, 0.32)')
replace(menu,'\tinner.add_child(heading)\n\tlist_box = VBoxContainer.new()', '''\tinner.add_child(heading)
\tvar top_line := Label.new()
\ttop_line.text = "✦  LES ÎLES DE L'AVENTURE  ✦"
\ttop_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
\ttop_line.add_theme_color_override("font_color", Color(0.74, 0.92, 1.0))
\ttop_line.add_theme_font_size_override("font_size", 15)
\tinner.add_child(top_line)
\tvar logo_file := load("res://assets/ui/ile_manga_icon.png") as Texture2D
\tif logo_file != null:
\t\tvar logo := TextureRect.new()
\t\tlogo.texture = logo_file
\t\tlogo.custom_minimum_size = Vector2(0, 94)
\t\tlogo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
\t\tlogo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
\t\tinner.add_child(logo)
\tlist_box = VBoxContainer.new()''')
replace(menu, '"ÎLE MANGA  •  V9"','"ÎLE MANGA  •  V10"')
replace(menu,'\t\theading.text = "ÎLE MANGA  •  " + view.to_upper()', '''\t\theading.text = "✦ ÎLE MANGA ✦  ·  " + view.to_upper()
\t\tframe.modulate.a = 0.84''')
replace(menu,'\t\t\tbutton.text = choice', '''\t\t\tbutton.text = ("✧  " if view == "home" else "▸  ") + choice''')
replace(menu, '\t\tif (view == "load" or view == "save") and playing:', '''\t\tif view in ["load", "save", "new", "delete"]:
\t\t\tvar footer := Label.new()
\t\t\tfooter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
\t\t\tfooter.text = "6 emplacements  •  Sauvegardes compatibles V8 / V9"
\t\t\tfooter.add_theme_color_override("font_color", Color(0.82, 0.79, 0.64))
\t\t\tlist_box.add_child(footer)
\t\tif (view == "load" or view == "save") and playing:''')
replace(menu, '''func _process(delta: float) -> void:
\tif playing''', '''func _process(delta: float) -> void:
\tif opened and not xr_mode and frame != null:
\t\tframe.modulate.a = move_toward(frame.modulate.a, 1.0, delta * 2.3)
\t\tmenu_glow_time += delta
\t\tif heading != null:
\t\t\theading.modulate.a = 0.91 + 0.09 * sin(menu_glow_time * 1.45)
\tif playing''')

project=Path('project.godot')
replace(project, 'Ile Manga VR V9', 'Ile Manga VR V10')
presets=Path('export_presets.cfg')
replace(presets, '_v9.exe', '_v10.exe', 2)
replace(presets, '9.0.0.0', '10.0.0.0', 4)

workflow=P.parent/'.github/workflows/build-pcvr-native.yml'
if not workflow.exists():
    raise SystemExit('Workflow manquant. Lance le script à la racine via pcvr/apply_v10.py')
w=workflow.read_text(encoding='utf-8')
if w.count('_v9.exe') not in (0, 4):
    raise SystemExit(f'Workflow V9 non reconnu : {w.count("_v9.exe")} references')
w=w.replace('_v9.exe','_v10.exe').replace('Ile-Manga-VR-v9','Ile-Manga-VR-v10').replace('Ile-Manga-PC-v9','Ile-Manga-PC-v10').replace('ile_manga_v9_','ile_manga_v10_')
# Ajoute un contrôle du panorama sans modifier les autres garanties CI.
if 'Verifier le menu panoramique V10' not in w:
    w=w.replace('      - name: Controle GDScript (VR)', '''      - name: Verifier le menu panoramique V10
        run: |
          python3 - <<'PYTEST'
          from pathlib import Path
          main = Path('pcvr/scripts/main.gd').read_text()
          menu = Path('pcvr/scripts/menu_v8.gd').read_text()
          assert 'Panorama_menu_V10' in main
          assert 'menu_panorama.look_at' in main
          assert 'frame.modulate.a = move_toward' in menu
          assert 'Saves.read_slot(i)' in menu
          assert 'right_hand.get_float("trigger")' in menu
          print('Panorama et six sauvegardes : OK')
          PYTEST

      - name: Controle GDScript (VR)''',1)
workflow.write_text(w,encoding='utf-8')
print('V10 appliquee : deux EXE, panorama anime PC, VR stable, 6 sauvegardes conservees.')
