extends SceneTree
## V64 : squelette de repos du héros (hero_skel.json) — les habitants reprennent ses os et ses rotations.
## godot --headless --path pcvr -s res://tools/habitants_v64/extraire_squelette.gd
func _initialize() -> void:
	var model: Node3D = (load("res://assets/models/characters/hero.glb") as PackedScene).instantiate()
	root.add_child(model)
	var skel: Skeleton3D = model.find_children("*", "Skeleton3D", true, false)[0]
	var bones := []
	for i in skel.get_bone_count():
		var r: Transform3D = skel.get_bone_rest(i)
		var g: Transform3D = skel.get_bone_global_rest(i)
		var q: Quaternion = r.basis.get_rotation_quaternion()
		var gq: Quaternion = g.basis.get_rotation_quaternion()
		bones.append({"name": skel.get_bone_name(i), "parent": skel.get_bone_parent(i),
			"o": [r.origin.x, r.origin.y, r.origin.z], "q": [q.x, q.y, q.z, q.w],
			"go": [g.origin.x, g.origin.y, g.origin.z], "gq": [gq.x, gq.y, gq.z, gq.w],
			"gb": [g.basis.x.x, g.basis.x.y, g.basis.x.z, g.basis.y.x, g.basis.y.y, g.basis.y.z, g.basis.z.x, g.basis.z.y, g.basis.z.z]})
	var mi: MeshInstance3D = model.find_child("char1", true, false)
	var binds := []
	for b in mi.skin.get_bind_count():
		var bp: Transform3D = mi.skin.get_bind_pose(b)
		binds.append({"name": mi.skin.get_bind_name(b), "basis": [bp.basis.x.x, bp.basis.x.y, bp.basis.x.z, bp.basis.y.x, bp.basis.y.y, bp.basis.y.z, bp.basis.z.x, bp.basis.z.y, bp.basis.z.z], "o": [bp.origin.x, bp.origin.y, bp.origin.z]})
	var f := FileAccess.open(_cache() + "/hero_skel.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"bones": bones, "binds": binds}, " "))
	f.close()
	print("SQUELETTE ", bones.size())
	quit()


static func _cache() -> String:
	var d: String = OS.get_environment("V64_CACHE")
	if d == "":
		d = OS.get_environment("HOME") + "/.cache/ile_manga_v64"
	DirAccess.make_dir_recursive_absolute(d)
	return d
