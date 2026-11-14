extends SceneTree
## V146 : relève le relief de l'Île Perchée (pour la peindre sur la carte de l'archipel :
## tools/carte_v146.py). Écrit, dans le dossier donné : perchee_h.bin (253 x 253 hauteurs locales,
## float32, une tous les 2 m, de -252 à +252 autour du centre ; -1000 hors de l'île) et perchee_biome.png.
##     godot --headless --path pcvr -s res://tools/carte_perchee_v146.gd -- /tmp/carte

const Ile = preload("res://scripts/ile_perchee_v146.gd")


func _initialize() -> void:
	var out: String = str(OS.get_cmdline_user_args()[0]) if OS.get_cmdline_user_args().size() > 0 else "/tmp/carte"
	DirAccess.make_dir_recursive_absolute(out)
	var ile = Ile.new()
	root.add_child(ile)
	ile._rng.seed = 14600
	ile._setup_noise()
	ile._bake_biome()
	var n: int = 253
	var h := PackedFloat32Array()
	h.resize(n * n)
	for zi in range(n):
		for xi in range(n):
			var lx: float = -252.0 + xi * 2.0
			var lz: float = -252.0 + zi * 2.0
			var r: float = Vector2(lx, lz).length()
			h[zi * n + xi] = ile.top_local(lx, lz) if r <= ile.coast_radius(atan2(lz, lx)) else -1000.0
	var f := FileAccess.open(out.path_join("perchee_h.bin"), FileAccess.WRITE)
	f.store_buffer(h.to_byte_array())
	f.close()
	ile.biome.save_png(out.path_join("perchee_biome.png"))
	print("V146 : relief relevé (%d x %d) dans %s" % [n, n, out])
	quit()
