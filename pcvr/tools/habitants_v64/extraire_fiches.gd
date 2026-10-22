extends SceneTree
## V64 : exporte toutes les fiches des habitants (pnj.json) pour le générateur de corps (generer.py).
## godot --headless --path pcvr -s res://tools/habitants_v64/extraire_fiches.gd
func _initialize() -> void:
	var out := {}
	var mods := {
		"azur": "res://scripts/pnj/azur_habitants_v56.gd", "carene": "res://scripts/pnj/carene_habitants_v59.gd",
		"cliquetis": "res://scripts/pnj/cliquetis_habitants_v61.gd", "tazira": "res://scripts/pnj/tazira_habitants_v60.gd",
		"ramure": "res://scripts/pnj/ramure_habitants_v62.gd", "teuf": "res://scripts/pnj/teufeurs_v57.gd",
	}
	for k in mods:
		var m = load(mods[k])
		for d in m.all_profiles():
			_add(out, k, d)
	var el = load("res://scripts/pnj/elfes_habitants_v42.gd")
	for e in el.NAMED:
		_add(out, "elfes", el.complete(e["data"]))
	for n in range(el.PASSANTS.size()):
		_add(out, "elfes", el.passant(n))
	var at = load("res://scripts/pnj/atlantes_habitants_v55.gd")
	for e in at.NAMED:
		_add(out, "atlantes", at.complete(e["data"]))
	for n in range(at.PASSANTS.size()):
		_add(out, "atlantes", at.passant(n))
	var na = load("res://scripts/pnj/nains_habitants_v47.gd")
	for e in na.DEHORS:
		_add(out, "nains", na.complete(e["data"]))
	for e in na.DEDANS:
		_add(out, "nains", na.complete(e["data"]))
	for n in range(7):
		_add(out, "nains", na.passant(n))
	for k2 in ["barnabe_v31", "octave_v33", "lyra_v41"]:
		var m2 = load("res://scripts/pnj/%s.gd" % k2)
		_add(out, k2.get_slice("_", 0), m2.DATA)
	var f := FileAccess.open(_cache() + "/pnj.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(out, "  "))
	f.close()
	print("PNJ ", out.size())
	quit()


func _add(out: Dictionary, village: String, d: Dictionary) -> void:
	var keep := {"village": village}
	for k in d:
		if k in ["repliques"]:
			var r: Dictionary = d[k]
			var t := []
			for kk in ["lui", "accueil", "humeur", "rumeur"]:
				for l in r.get(kk, []):
					if l is Dictionary:
						t.append(str(l.get("t", "")))
			keep["textes"] = t
		elif k in ["agenda", "aime", "deteste", "boutique", "vend", "achete", "quete", "sujets_speciaux", "refuse"]:
			continue
		else:
			keep[k] = d[k]
	var id := str(d.get("id", "?"))
	if out.has(id):
		print("DOUBLON ", id)
	out[id] = keep


static func _cache() -> String:
	var d: String = OS.get_environment("V64_CACHE")
	if d == "":
		d = OS.get_environment("HOME") + "/.cache/ile_manga_v64"
	DirAccess.make_dir_recursive_absolute(d)
	return d
