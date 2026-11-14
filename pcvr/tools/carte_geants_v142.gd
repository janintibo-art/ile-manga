extends SceneTree
## V142 : relève le relief de l'Île des Géants (pour la peindre sur la carte de l'archipel :
## tools/carte_v142.py). Écrit, dans le dossier donné : geants_h.bin (301 x 301 hauteurs, float32,
## une tous les 2 m, de x0 = 500 à 1100, de z0 = 1800 à 2400) et geants_biome.png (la carte des sols).
##     godot --headless --path pcvr -s res://tools/carte_geants_v142.gd -- /tmp/carte

const Ile = preload("res://scripts/ile_geants_v142.gd")


func _initialize() -> void:
	var out: String = str(OS.get_cmdline_user_args()[0]) if OS.get_cmdline_user_args().size() > 0 else "/tmp/carte"
	DirAccess.make_dir_recursive_absolute(out)
	var ile = Ile.new()
	root.add_child(ile)
	ile.build(false)
	var f := FileAccess.open(out.path_join("geants_h.bin"), FileAccess.WRITE)
	f.store_buffer((ile.heights as PackedFloat32Array).to_byte_array())
	f.close()
	ile.biome.save_png(out.path_join("geants_biome.png"))
	print("V142 : relief relevé (%d x %d) dans %s" % [ile.count, ile.count, out])
	quit()
