from pathlib import Path
import re
root=Path(__file__).resolve().parents[1]
main=root/'pcvr/scripts/main.gd'
menu=root/'pcvr/scripts/menu_v8.gd'
a=main.read_text(encoding='utf-8')
b=menu.read_text(encoding='utf-8')
for declaration in ('var menu_panorama: Camera3D','var panorama_seconds: float = 0.0'):
    lines=a.splitlines(keepends=True)
    seen=False
    out=[]
    for line in lines:
        if line.strip()==declaration:
            if seen: continue
            seen=True
        out.append(line)
    a=''.join(out)
# Keep exactly one of the repeated V10 panorama setup blocks, without touching surrounding menu setup.
start=a.index('\t# Caméra cinématique PC indépendante du joueur. En VR le monde reste stable.',a.index('func _create_game_menu_v8()'))
end=a.index('\n\nfunc _start_save_slot',start)
block='''\t# Caméra cinématique PC indépendante du joueur. En VR le monde reste stable.
\tif OS.has_feature("ile_manga_pc"):
\t\tmenu_panorama = Camera3D.new()
\t\tmenu_panorama.name = "Panorama_menu_V10"
\t\tmenu_panorama.fov = 66.0
\t\tadd_child(menu_panorama)
\t\tmenu_panorama.position = Vector3(-26.0, 17.0, 35.0)
\t\tmenu_panorama.look_at(Vector3(0, 4, 0), Vector3.UP)
\t\tmenu_panorama.current = true'''
a=a[:start]+block+a[end:]
assert a.count('var menu_panorama: Camera3D')==1
assert a.count('var panorama_seconds: float = 0.0')==1
assert a.count('menu_panorama = Camera3D.new()')==1
assert a.count('func _process(delta: float) -> void:')==1
b=b.replace('var menu_glow_time: float = 0.0\nvar menu_glow_time: float = 0.0','var menu_glow_time: float = 0.0')
# duplicate footer block only
footer='''\t\tif view in ["load", "save", "new", "delete"]:
\t\t\tvar footer := Label.new()
\t\t\tfooter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
\t\t\tfooter.text = "6 emplacements  •  Sauvegardes compatibles V8 / V9"
\t\t\tfooter.add_theme_color_override("font_color", Color(0.82, 0.79, 0.64))
\t\t\tlist_box.add_child(footer)
'''
b=b.replace(footer+footer,footer)
assert b.count('var menu_glow_time: float = 0.0')==1
assert b.count('var footer := Label.new()')==1
main.write_text(a,encoding='utf-8')
menu.write_text(b,encoding='utf-8')
print('V10 nettoyée : déclarations, caméras et menu sans doublons')
