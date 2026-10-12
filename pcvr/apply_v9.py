from pathlib import Path
import re
root=Path(__file__).resolve().parent
path=root/'scripts/menu_v8.gd'
s=path.read_text(encoding='utf-8')
if 'ILE_MANGA_MENU_V9' not in s:
    needle='\tcard.custom_minimum_size = Vector2(580, 440)\n\tcenter.add_child(card)'
    replacement='''\tcard.custom_minimum_size = Vector2(650, 510)
\t# ILE_MANGA_MENU_V9 : panneau aux couleurs de l'aventure.
\tvar style := StyleBoxFlat.new()
\tstyle.bg_color = Color(0.035, 0.11, 0.16, 0.98)
\tstyle.border_color = Color(0.89, 0.71, 0.36)
\tstyle.set_border_width_all(2)
\tstyle.set_corner_radius_all(18)
\tstyle.set_content_margin_all(24)
\tstyle.shadow_color = Color(0, 0, 0, 0.45)
\tstyle.shadow_size = 16
\tcard.add_theme_stylebox_override("panel", style)
\tcenter.add_child(card)'''
    if s.count(needle)!=1: raise SystemExit('Version V8 de menu inattendue (panneau)')
    s=s.replace(needle,replacement)
    old='\theading.text = "ÎLE MANGA  •  AVENTURE"'
    new='''\theading.text = "✦  ÎLE MANGA  ✦"
\theading.add_theme_color_override("font_color", Color(1.0, 0.82, 0.47))'''
    if s.count(old)!=1: raise SystemExit('Version V8 de menu inattendue (titre)')
    s=s.replace(old,new)
    old='\t\t\tbutton.custom_minimum_size.y = 38'
    new='''\t\t\tbutton.custom_minimum_size.y = 45
\t\t\tbutton.add_theme_font_size_override("font_size", 17)
\t\t\tvar normal := StyleBoxFlat.new()
\t\t\tnormal.bg_color = Color(0.12, 0.25, 0.32)
\t\t\tnormal.border_color = Color(0.43, 0.47, 0.37)
\t\t\tnormal.set_border_width_all(1)
\t\t\tnormal.set_corner_radius_all(9)
\t\t\tbutton.add_theme_stylebox_override("normal", normal)
\t\t\tvar hover := normal.duplicate() as StyleBoxFlat
\t\t\thover.bg_color = Color(0.24, 0.43, 0.43)
\t\t\thover.border_color = Color(0.99, 0.76, 0.32)
\t\t\tbutton.add_theme_stylebox_override("hover", hover)
\t\t\tbutton.add_theme_stylebox_override("focus", hover)'''
    if s.count(old)!=1: raise SystemExit('Version V8 de menu inattendue (boutons)')
    s=s.replace(old,new)
    old='info = str(data.get("saved_at", "date inconnue")) + " - " + str(int(float(data.get("play_seconds", 0.0)) / 60.0)) + " min"'
    new='info = "%s  •  %s  •  %d min" % [str(data.get("zone", "Île Manga")), str(data.get("saved_at", "date inconnue")), int(float(data.get("play_seconds", 0.0)) / 60.0)]'
    if s.count(old)!=1: raise SystemExit('Version V8 de menu inattendue (sauvegardes)')
    s=s.replace(old,new).replace('"ÎLE MANGA  •  V8"','"ÎLE MANGA  •  V9"')
    path.write_text(s,encoding='utf-8')
    print('Menu V9 applique ; aucun format de sauvegarde modifie')
else: print('Menu V9 déjà présent')
project=root/'project.godot'
t=project.read_text(encoding='utf-8')
t=re.sub(r'(config/name="Ile Manga VR V)\d+',r'\g<1>9',t)
project.write_text(t,encoding='utf-8')
export=root/'export_presets.cfg'
t=export.read_text(encoding='utf-8')
t=re.sub(r'(Ile_Manga_(?:VR|PC)_v)\d+',r'\g<1>9',t)
t=re.sub(r'(application/(?:file_version|product_version)=")\d+\.0\.0\.0',r'\g<1>9.0.0.0',t)
export.write_text(t,encoding='utf-8')
workflow=root.parent/'.github/workflows/build-pcvr-native.yml'
t=workflow.read_text(encoding='utf-8')
t=re.sub(r'(Ile_Manga_(?:VR|PC)_v)\d+',r'\g<1>9',t)
t=re.sub(r'(Ile-Manga-(?:VR|PC)-v)\d+',r'\g<1>9',t)
t=re.sub(r'(ile_manga_v)\d+(_(?:vr|pc)\.log)',r'\g<1>9\2',t)
workflow.write_text(t,encoding='utf-8')
print('Deux exports V9 configures')
