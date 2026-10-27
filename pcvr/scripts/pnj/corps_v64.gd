extends RefCounted
## V64 : les vrais corps des habitants — un maillage humain complet (MakeHuman, CC0),
## propre à chaque personnage (visage, silhouette, âge, carrure), posé sur le squelette
## du héros : mêmes os, mêmes rotations de repos, mais longueurs d'os du personnage.
## Les animations du héros (clips du modèle et poses construites) s'appliquent telles
## quelles ; la hauteur du bassin suit l'échelle de mouvement du squelette.
## Données : assets/models/pnj64/base.bin (topologie, UV, poids) + <id>.bin (forme).

const DIR := "res://assets/models/pnj64/"

static var _base: Dictionary = {}
static var _stripped: bool = false


static func read_bin(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var hdr: PackedByteArray = f.get_buffer(8)
	if hdr.size() < 8 or hdr.slice(0, 4).get_string_from_ascii() != "IM64":
		return {}
	var size: int = hdr.decode_u32(4)
	var comp: PackedByteArray = f.get_buffer(f.get_length() - 8)
	var raw: PackedByteArray = comp.decompress(size, FileAccess.COMPRESSION_DEFLATE)
	if raw.size() != size:
		return {}
	var v = bytes_to_var(raw)
	return v if v is Dictionary else {}


static func base() -> Dictionary:
	if _base.is_empty():
		_base = read_bin(DIR + "base.bin")
	return _base


static func has_body(id: String) -> bool:
	return FileAccess.file_exists(DIR + id + ".bin") and not base().is_empty()


## Positions des sommets soudés : base + écarts (entiers 16 bits, 0,1 mm, octets séparés).
static func positions(d: Dictionary) -> PackedVector3Array:
	var basev: PackedVector3Array = base()["base"]
	var dq: PackedByteArray = d["dq"]
	var n: int = basev.size()
	var out := PackedVector3Array()
	out.resize(n)
	var h: int = 3 * n
	var n2: int = 2 * n
	for i in range(n):
		var x: int = dq[i] | (dq[h + i] << 8)
		var y: int = dq[n + i] | (dq[h + n + i] << 8)
		var z: int = dq[n2 + i] | (dq[h + n2 + i] << 8)
		if x >= 32768:
			x -= 65536
		if y >= 32768:
			y -= 65536
		if z >= 32768:
			z -= 65536
		out[i] = basev[i] + Vector3(x, y, z) * 0.0001
	return out


## Quelques positions seulement (les autres restent à zéro) : de quoi mesurer la tête et le buste.
static func positions_at(d: Dictionary, ids: Array) -> PackedVector3Array:
	var basev: PackedVector3Array = base()["base"]
	var dq: PackedByteArray = d["dq"]
	var n: int = basev.size()
	var out := PackedVector3Array()
	out.resize(n)
	var h: int = 3 * n
	for i0 in ids:
		var i: int = int(i0)
		var c := [0, 0, 0]
		for a in 3:
			var v: int = dq[a * n + i] | (dq[h + a * n + i] << 8)
			c[a] = v - 65536 if v >= 32768 else v
		out[i] = basev[i] + Vector3(c[0], c[1], c[2]) * 0.0001
	return out


## Normales (octaèdre, 8 bits) des sommets soudés.
static func normals(d: Dictionary) -> PackedVector3Array:
	var nq: PackedByteArray = d["nq"]
	var n: int = nq.size() / 2
	var out := PackedVector3Array()
	out.resize(n)
	for i in range(n):
		var a: int = nq[i]
		var b: int = nq[n + i]
		var ox: float = float(a - 256 if a > 127 else a) / 127.0
		var oy: float = float(b - 256 if b > 127 else b) / 127.0
		var z: float = 1.0 - absf(ox) - absf(oy)
		var x: float = ox
		var y: float = oy
		if z < 0.0:
			x = (1.0 - absf(oy)) * (1.0 if ox >= 0.0 else -1.0)
			y = (1.0 - absf(ox)) * (1.0 if oy >= 0.0 else -1.0)
		out[i] = Vector3(x, y, z).normalized()
	return out


## Les clips du modèle portent une piste de position pour chaque os (valeurs du héros) :
## on ne garde que celle du bassin, sinon les longueurs d'os du personnage seraient écrasées.
static func strip_position_tracks(anim: AnimationPlayer) -> void:
	for lib_name in anim.get_animation_library_list():
		var lib: AnimationLibrary = anim.get_animation_library(lib_name)
		for an in lib.get_animation_list():
			var a: Animation = lib.get_animation(an)
			for t in range(a.get_track_count() - 1, -1, -1):
				if a.track_get_type(t) == Animation.TYPE_POSITION_3D and not str(a.track_get_path(t)).ends_with(":Hips"):
					a.remove_track(t)


## Squelette du personnage : rotations de repos du héros, origines (longueurs d'os) du personnage.
## Seules les origines changent : on peut l'appeler plusieurs fois.
static func setup_skeleton(skel: Skeleton3D, anim: AnimationPlayer, d: Dictionary) -> void:
	if anim != null:
		strip_position_tracks(anim)
	var rest: PackedVector3Array = d["rest"]
	var names: Array = base()["bone_names"]
	for i in range(names.size()):
		var bi2: int = skel.find_bone(str(names[i]))
		if bi2 < 0 or skel.get_bone_parent(bi2) < 0:
			continue
		var r: Transform3D = skel.get_bone_rest(bi2)
		r.origin = rest[i]
		skel.set_bone_rest(bi2, r)
		skel.set_bone_pose_position(bi2, rest[i])
	skel.motion_scale = float(d["motion_scale"])


## Prépare un habitant sans ses maillages : squelette à ses mesures, apparence, taille et
## repères de la tête et du buste (pour poser les accessoires). Les maillages viennent
## ensuite (build_full), quand le joueur approche.
static func prepare(skel: Skeleton3D, anim: AnimationPlayer, id: String) -> Dictionary:
	var d: Dictionary = read_bin(DIR + id + ".bin")
	if base().is_empty() or d.is_empty() or skel == null:
		return {}
	setup_skeleton(skel, anim, d)
	var b: Dictionary = base()
	var pw: PackedVector3Array = positions_at(d, Array(b.get("head_ids", [])) + Array(b.get("torso_ids", [])))
	return {"id": id, "look": d.get("look", {}), "scale": float(d.get("scale", 1.0)), "scales": scales(pw)}


## Libère les maillages d'un habitant (le squelette et les accessoires restent).
static func free_meshes(parts: Dictionary) -> void:
	for k in parts.keys():
		var v: Variant = parts[k]
		if v is MeshInstance3D:
			if is_instance_valid(v):
				(v as Node).queue_free()
			parts.erase(k)
	for k2 in ["shells", "amples"]:
		for e in parts.get(k2, []):
			if is_instance_valid(e[0]):
				(e[0] as Node).queue_free()
		parts.erase(k2)
	parts.erase("skin")
	parts.erase("positions")
	parts.erase("normals")


## Construit le corps du personnage <id> sur le modèle du héros déjà instancié.
## Renvoie le MeshInstance3D de la peau (ou null si les données manquent).
static func build(model: Node3D, skel: Skeleton3D, anim: AnimationPlayer, id: String, outfit: Array = []) -> Dictionary:
	var b: Dictionary = base()
	var d: Dictionary = read_bin(DIR + id + ".bin")
	if b.is_empty() or d.is_empty() or skel == null:
		return {}
	var pw: PackedVector3Array = positions(d)
	setup_skeleton(skel, anim, d)
	var joints: PackedVector3Array = d["joints"]
	var names: Array = b["bone_names"]
	var gbasis: Array = []
	for i in range(names.size()):
		var bi: int = skel.find_bone(str(names[i]))
		gbasis.append(skel.get_bone_global_rest(bi).basis.orthonormalized())
	var skin := Skin.new()
	for i in range(names.size()):
		var g := Transform3D(gbasis[i], joints[i] * 100.0)
		skin.add_named_bind(str(names[i]), g.affine_inverse() * Transform3D(Basis.from_scale(Vector3.ONE * 100.0), Vector3.ZERO))
	if skel.get_node_or_null("Epaules64") == null:
		var ep := Epaules.new()
		ep.name = "Epaules64"
		ep.setup(skel)
		skel.add_child(ep)
	# vêtements « coques » : chaque triangle de peau appartient à la couche la plus externe
	var nw: PackedVector3Array = normals(d)
	var out := {"positions": pw, "normals": nw, "skin": skin, "shells": []}
	var shells := []
	var amples := []
	for g in outfit:
		var gd: Dictionary = garment(str((g as Dictionary).get("v", "")))
		if gd.is_empty():
			continue
		if gd.has("tri_skin"):
			shells.append([int(gd["layer"]), g, gd])
		else:
			amples.append([g, gd])
	shells.sort_custom(func(x, y): return x[0] < y[0])
	var ip: PackedInt32Array = b["i_peau"]
	var nts: int = ip.size() / 3
	var owner := PackedInt32Array()
	owner.resize(nts)
	owner.fill(-1)
	for k in range(shells.size()):
		var ts: PackedInt32Array = shells[k][2]["tri_skin"]
		for t in ts:
			if t >= 0:
				owner[t] = k
	# le visage (paupières, bouche) est une surface à part, avec ses expressions
	var face_mark := PackedByteArray()
	face_mark.resize(nts)
	if b.has("visage_tris"):
		for t0 in (b["visage_tris"] as PackedInt32Array):
			face_mark[t0] = 1
	var skin_idx := PackedInt32Array()
	for t in range(nts):
		if owner[t] < 0 and face_mark[t] == 0:
			skin_idx.append(ip[3 * t])
			skin_idx.append(ip[3 * t + 1])
			skin_idx.append(ip[3 * t + 2])
	var sc: Array = scales(pw)
	out["scales"] = sc
	var occ := PackedFloat32Array()
	occ.resize(pw.size())
	for k in range(shells.size()):
		var mi_s: MeshInstance3D = add_shell(skel, skin, shells[k][2], pw, nw, owner, k, sc[1], "Habit_" + str(shells[k][1].get("v", "")), occ)
		if mi_s != null:
			(out["shells"] as Array).append([mi_s, shells[k][1]])
	out["amples"] = []
	for e in amples:
		var mi_a: MeshInstance3D = add_proxy(skel, skin, e[1], pw, sc, null, "Habit_" + str(e[0].get("v", "")))
		if mi_a != null:
			(out["amples"] as Array).append([mi_a, e[0]])
	for sname in b["surfaces"]:
		var wid: PackedInt32Array = b["w_" + sname]
		var ns: int = wid.size()
		var ps := PackedVector3Array()
		ps.resize(ns)
		var nn := PackedVector3Array()
		nn.resize(ns)
		for i in range(ns):
			var w: int = wid[i]
			ps[i] = pw[w]
			nn[i] = nw[w]
		var arr := []
		arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = ps
		arr[Mesh.ARRAY_NORMAL] = nn
		arr[Mesh.ARRAY_TANGENT] = b["t_" + sname]
		arr[Mesh.ARRAY_TEX_UV] = b["uv_" + sname]
		arr[Mesh.ARRAY_BONES] = b["b_" + sname]
		arr[Mesh.ARRAY_WEIGHTS] = b["p_" + sname]
		arr[Mesh.ARRAY_INDEX] = skin_idx if sname == "peau" else b["i_" + sname]
		var am := ArrayMesh.new()
		var shapes := []
		var exprs: Array = b.get("expressions", [])
		if b.has("bs_%s_%s" % [sname, "cligne"]):
			am.blend_shape_mode = Mesh.BLEND_SHAPE_MODE_RELATIVE
			var zn := PackedVector3Array()
			zn.resize(ns)
			var zt := PackedFloat32Array()
			zt.resize(ns * 4)
			for en in exprs:
				am.add_blend_shape(str(en))
				var bs := []
				bs.resize(Mesh.ARRAY_MAX)
				bs[Mesh.ARRAY_VERTEX] = b["bs_%s_%s" % [sname, en]]
				bs[Mesh.ARRAY_NORMAL] = zn
				bs[Mesh.ARRAY_TANGENT] = zt
				shapes.append(bs)
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr, shapes)
		var mi := MeshInstance3D.new()
		mi.name = "Corps64_" + str(sname)
		mi.mesh = am
		mi.skin = skin
		skel.add_child(mi)
		mi.skeleton = mi.get_path_to(skel)
		out[str(sname)] = mi
	return out


# =================================================================== matières

const TEX := "res://assets/textures/pnj64/"
static var _shared: Dictionary = {}


static func _tex(name: String) -> Texture2D:
	if not _shared.has(name):
		var p: String = TEX + name
		_shared[name] = load(p) if ResourceLoader.exists(p) else null
	return _shared[name]


static func _col(v: Variant, fallback: Color) -> Color:
	if v is Color:
		return v
	if v is Array and (v as Array).size() >= 3:
		return Color(float(v[0]), float(v[1]), float(v[2]))
	return fallback


## look : peau, levres, sourcils, sourcils_epais, poils, barbe [m, c, j], cheveux, crane,
## age, iris, fard, fard_force, rose.
static func skin_material(look: Dictionary) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/peau_v64.gdshader")
	m.set_shader_parameter("teint", _tex("peau_teint.png"))
	m.set_shader_parameter("masques1", _tex("peau_masques1.png"))
	m.set_shader_parameter("masques2", _tex("peau_masques2.png"))
	m.set_shader_parameter("grain_n", _tex("peau_grain_n.png"))
	m.set_shader_parameter("rides_n", _tex("peau_rides_n.png"))
	m.set_shader_parameter("peau", _col(look.get("peau"), Color(0.86, 0.66, 0.54)))
	m.set_shader_parameter("levres", _col(look.get("levres"), Color(0.72, 0.38, 0.36)))
	m.set_shader_parameter("levres_force", float(look.get("levres_force", 0.7)))
	m.set_shader_parameter("sourcils", _col(look.get("sourcils"), Color(0.18, 0.11, 0.07)))
	m.set_shader_parameter("sourcils_epais", float(look.get("sourcils_epais", 0.5)))
	m.set_shader_parameter("poils", _col(look.get("poils"), Color(0.12, 0.08, 0.05)))
	var b: Array = look.get("barbe", [0.0, 0.0, 0.0])
	m.set_shader_parameter("barbe", Vector3(float(b[0]), float(b[1]), float(b[2])))
	m.set_shader_parameter("cheveux", _col(look.get("cheveux"), Color(0.12, 0.08, 0.05)))
	m.set_shader_parameter("crane", float(look.get("crane", 0.0)))
	m.set_shader_parameter("age", float(look.get("age", 0.0)))
	m.set_shader_parameter("fard", _col(look.get("fard"), Color(0.45, 0.32, 0.4)))
	m.set_shader_parameter("fard_force", float(look.get("fard_force", 0.0)))
	m.set_shader_parameter("rose", float(look.get("rose", 0.25)))
	return m


static func eye_material(look: Dictionary) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/oeil_v64.gdshader")
	m.set_shader_parameter("tex", _tex("yeux.png"))
	m.set_shader_parameter("iris", _col(look.get("iris"), Color(0.35, 0.25, 0.15)))
	return m


static func lash_material(look: Dictionary) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = _tex("cils.png")
	m.albedo_color = _col(look.get("cils"), Color(0.06, 0.045, 0.035))
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m.alpha_scissor_threshold = 0.35
	m.alpha_antialiasing_mode = BaseMaterial3D.ALPHA_ANTIALIASING_ALPHA_TO_COVERAGE
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.roughness = 0.6
	return m


static func mouth_material(c: Color, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	return m


static func apply_materials(parts: Dictionary, look: Dictionary) -> void:
	if parts.has("peau"):
		var sm := skin_material(look)
		(parts["peau"] as MeshInstance3D).material_override = sm
		if parts.has("visage"):
			(parts["visage"] as MeshInstance3D).material_override = sm
	if parts.has("yeux"):
		(parts["yeux"] as MeshInstance3D).material_override = eye_material(look)
	if parts.has("cils"):
		(parts["cils"] as MeshInstance3D).material_override = lash_material(look)
		(parts["cils"] as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if parts.has("dents"):
		(parts["dents"] as MeshInstance3D).material_override = mouth_material(Color(0.86, 0.82, 0.72), 0.3)
	if parts.has("langue"):
		(parts["langue"] as MeshInstance3D).material_override = mouth_material(Color(0.62, 0.3, 0.3), 0.4)


# =================================================================== proxies (cheveux, barbes, vêtements amples)

static var _proxies: Dictionary = {}


static func proxy(path: String) -> Dictionary:
	if not _proxies.has(path):
		_proxies[path] = read_bin(DIR + path + ".bin")
	return _proxies[path]


## Échelles (x, y, z) de la tête et du buste du personnage par rapport au corps neutre.
static func scales(pw: PackedVector3Array) -> Array:
	var b: Dictionary = base()
	var out := []
	for k in ["head", "torso"]:
		var ids: Array = b.get(k + "_ids", [])
		var ref: Array = b.get(k + "_ref", [])
		if ids.size() < 6:
			out.append(Vector3.ONE)
			continue
		out.append(Vector3(absf(pw[int(ids[0])].x - pw[int(ids[1])].x) / float(ref[0]),
			absf(pw[int(ids[2])].y - pw[int(ids[3])].y) / float(ref[1]),
			absf(pw[int(ids[4])].z - pw[int(ids[5])].z) / float(ref[2])))
	return out


static func fit(a: Dictionary, pw: PackedVector3Array, sc: Array) -> PackedVector3Array:
	var refs: PackedInt32Array = a["refs"]
	var bary: PackedFloat32Array = a["bary"]
	var off: PackedVector3Array = a["off"]
	var reg: PackedByteArray = a["reg"]
	var sh: Vector3 = sc[0]
	var st: Vector3 = sc[1]
	var n: int = off.size()
	var out := PackedVector3Array()
	out.resize(n)
	for i in range(n):
		var j: int = i * 3
		var p: Vector3 = pw[refs[j]] * bary[j] + pw[refs[j + 1]] * bary[j + 1] + pw[refs[j + 2]] * bary[j + 2]
		out[i] = p + off[i] * (sh if reg[i] == 0 else st)
	return out


## Ajoute un proxy (cartes) au squelette ; renvoie le MeshInstance3D.
static func add_proxy(skel: Skeleton3D, skin: Skin, a: Dictionary, pw: PackedVector3Array, sc: Array, mat: Material, name: String) -> MeshInstance3D:
	if a.is_empty():
		return null
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = fit(a, pw, sc)
	arr[Mesh.ARRAY_NORMAL] = a["nrm"]
	arr[Mesh.ARRAY_TANGENT] = a["tan"]
	arr[Mesh.ARRAY_TEX_UV] = a["uv"]
	if a.has("col"):
		arr[Mesh.ARRAY_COLOR] = a["col"]
	arr[Mesh.ARRAY_BONES] = a["bones"]
	arr[Mesh.ARRAY_WEIGHTS] = a["weights"]
	arr[Mesh.ARRAY_INDEX] = a["idx"]
	var flags: int = 0
	if not a.has("hem"):
		var pv0: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var ry := PackedFloat32Array()
		ry.resize(pv0.size())
		for i in range(pv0.size()):
			ry[i] = pv0[i].y
		arr[Mesh.ARRAY_CUSTOM0] = ry
		flags = Mesh.ARRAY_CUSTOM_R_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT
	if a.has("hem"):
		var pv: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var c1 := PackedFloat32Array()
		c1.resize(pv.size() * 3)
		for i in range(pv.size()):
			c1[3 * i] = pv[i].x
			c1[3 * i + 1] = pv[i].y
			c1[3 * i + 2] = pv[i].z
		arr[Mesh.ARRAY_CUSTOM0] = a["hem"]
		arr[Mesh.ARRAY_CUSTOM1] = c1
		flags = (Mesh.ARRAY_CUSTOM_R_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT) | (Mesh.ARRAY_CUSTOM_RGB_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM1_SHIFT)
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr, [], {}, flags)
	var mi := MeshInstance3D.new()
	mi.name = name
	mi.mesh = am
	mi.skin = skin
	mi.material_override = mat
	skel.add_child(mi)
	mi.skeleton = mi.get_path_to(skel)
	return mi


static func hair_material(c: Color) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/cheveux_v64.gdshader")
	m.set_shader_parameter("tex", _tex("meches.png"))
	m.set_shader_parameter("couleur", c)
	return m



# =================================================================== vêtements

static var _garments: Dictionary = {}


static func garment(name: String) -> Dictionary:
	if name == "":
		return {}
	if not _garments.has(name):
		_garments[name] = read_bin(DIR + "habits/" + name + ".bin")
	return _garments[name]


## Coque : sommets du corps poussés le long de leur normale (épaisseur du tissu), ourlets lissés.
static func add_shell(skel: Skeleton3D, skin: Skin, g: Dictionary, pw: PackedVector3Array, nw: PackedVector3Array, owner: PackedInt32Array, k: int, st: Vector3, name: String, occ: PackedFloat32Array) -> MeshInstance3D:
	var w: PackedInt32Array = g["w"]
	var off: PackedFloat32Array = g["off"]
	var shift: PackedVector3Array = g["shift"]
	var hem: PackedFloat32Array = g["hem"]
	var n: int = w.size()
	var ps := PackedVector3Array()
	ps.resize(n)
	var nn := PackedVector3Array()
	nn.resize(n)
	var c0 := PackedFloat32Array()
	c0.resize(n)
	var c1 := PackedFloat32Array()
	c1.resize(n * 3)
	# épaisseur : toujours au-dessus des couches déjà posées (occ), bande d'ourlet jusqu'à elles
	var occ0 := occ.duplicate()
	for i in range(n):
		var wi: int = w[i]
		var o: float = off[i]
		if o < 0.0:
			o = maxf(o, occ0[wi] - 0.0005)
		else:
			o = maxf(o, occ0[wi] + 0.0035)
			occ[wi] = maxf(occ[wi], o)
		var p: Vector3 = pw[wi] + nw[wi] * o + shift[i] * st
		ps[i] = p
		nn[i] = nw[wi]
		c0[i] = hem[i]
		c1[3 * i] = p.x
		c1[3 * i + 1] = p.y
		c1[3 * i + 2] = p.z
	var tri: PackedInt32Array = g["tri"]
	var ts: PackedInt32Array = g["tri_skin"]
	var idx := PackedInt32Array()
	for t in range(ts.size()):
		var o: int = ts[t]
		if o < 0 or owner[o] == k:
			idx.append(tri[3 * t])
			idx.append(tri[3 * t + 1])
			idx.append(tri[3 * t + 2])
	if idx.is_empty():
		return null
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = ps
	arr[Mesh.ARRAY_NORMAL] = nn
	arr[Mesh.ARRAY_TANGENT] = g["tan"]
	arr[Mesh.ARRAY_TEX_UV] = g["uv"]
	arr[Mesh.ARRAY_BONES] = g["bones"]
	arr[Mesh.ARRAY_WEIGHTS] = g["weights"]
	arr[Mesh.ARRAY_CUSTOM0] = c0
	arr[Mesh.ARRAY_CUSTOM1] = c1
	arr[Mesh.ARRAY_INDEX] = idx
	var am := ArrayMesh.new()
	var flags: int = (Mesh.ARRAY_CUSTOM_R_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT) | (Mesh.ARRAY_CUSTOM_RGB_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM1_SHIFT)
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr, [], {}, flags)
	var mi := MeshInstance3D.new()
	mi.name = name
	mi.mesh = am
	mi.skin = skin
	skel.add_child(mi)
	mi.skeleton = mi.get_path_to(skel)
	return mi


## g : {"v": vêtement, "c": [r,g,b], "c2": [r,g,b], "motif": 0..4, "echelle": m, "tissu": "coton"…}
static func cloth_material(g: Dictionary, ample: bool = false) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/tissu_ample_v64.gdshader" if ample else "res://shaders/tissu_v64.gdshader")
	m.set_shader_parameter("couleur", _col(g.get("c"), Color(0.5, 0.5, 0.5)))
	m.set_shader_parameter("couleur2", _col(g.get("c2"), Color(0.9, 0.9, 0.88)))
	m.set_shader_parameter("motif", int(g.get("motif", 0)))
	m.set_shader_parameter("echelle", float(g.get("echelle", 0.04)))
	var t: String = str(g.get("tissu", "coton"))
	m.set_shader_parameter("trame", _tex("tissu_" + t + ".png"))
	m.set_shader_parameter("rugosite", {"coton": 0.85, "lin": 0.9, "laine": 0.95, "jean": 0.85, "cuir": 0.5, "soie": 0.35, "toile": 0.9, "paille": 0.8, "metal": 0.32}.get(t, 0.85))
	m.set_shader_parameter("lustre", {"cuir": 0.5, "soie": 0.6}.get(t, 0.0))
	m.set_shader_parameter("metal", 0.6 if t == "metal" else 0.0)
	if t == "metal":
		m.set_shader_parameter("trame", _tex("tissu_cuir.png"))
		m.set_shader_parameter("trame_rep", 12.0)
	m.set_shader_parameter("details", _tex("habits_details.png"))
	m.set_shader_parameter("plis", _tex("habits_plis_n.png"))
	m.set_shader_parameter("coutures", Vector3(float(g.get("coutures", 1.0)), float(g.get("boutons", 0.0)), float(g.get("poches", 0.0))))
	return m


# =================================================================== assemblage complet

## Construit tout le personnage <id> : corps, visage, cheveux, barbe, tenue, matières.
## opts : "coupe_cheveux" (hauteur, au-dessus de la tête, où un chapeau coupe les cheveux, m),
##        "sans_barbe", "tenue" (remplace celle de la fiche).
## Renvoie {} si les données manquent (le personnage garde alors l'ancien corps).
static func build_full(model: Node3D, skel: Skeleton3D, anim: AnimationPlayer, id: String, opts: Dictionary = {}) -> Dictionary:
	var d: Dictionary = read_bin(DIR + id + ".bin")
	if d.is_empty():
		return {}
	var look: Dictionary = d.get("look", {})
	var outfit: Array = opts.get("tenue", look.get("tenue", []))
	var parts: Dictionary = build(model, skel, anim, id, outfit)
	if parts.is_empty():
		return {}
	parts["look"] = look
	parts["scale"] = float(d.get("scale", 1.0))
	apply_materials(parts, look)
	for sh in parts["shells"]:
		(sh[0] as MeshInstance3D).material_override = cloth_material(sh[1])
	for am in parts["amples"]:
		(am[0] as MeshInstance3D).material_override = cloth_material(am[1], true)
	var pw: PackedVector3Array = parts["positions"]
	var sc: Array = parts["scales"]
	var skin: Skin = parts["skin"]
	var hcol: Color = _col(look.get("cheveux"), Color(0.2, 0.13, 0.08))
	var head_y: float = 0.0
	var b: Dictionary = base()
	if b.has("head_ids"):
		head_y = pw[int(b["head_ids"][2])].y
	var hs: String = str(look.get("cheveux_style", ""))
	if hs != "":
		var hm := hair_material(hcol)
		var cut: float = float(opts.get("coupe_cheveux", look.get("coupe", 99.0)))
		if cut < 10.0:
			hm.set_shader_parameter("coupe", head_y + cut)
		parts["cheveux"] = add_proxy(skel, skin, proxy("cheveux/" + hs), pw, sc, hm, "Cheveux")
	var bs: String = str(look.get("barbe_style", ""))
	if bs != "" and not bool(opts.get("sans_barbe", false)):
		parts["barbe"] = add_proxy(skel, skin, proxy("cheveux/" + bs), pw, sc, hair_material(_col(look.get("poils"), hcol)), "Barbe")
	# ombres : les cils et les petites pièces n'en projettent pas
	for k in ["dents", "langue", "yeux"]:
		if parts.has(k):
			(parts[k] as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# les mèches ne projettent pas d'ombre : des cartes alpha donneraient des taches dures sur le visage
	for k3 in ["cheveux", "barbe"]:
		if parts.get(k3) != null:
			(parts[k3] as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# de loin, les petites pièces du visage ne se voient plus : on ne les dessine pas
	for k2 in ["cils", "dents", "langue"]:
		if parts.has(k2):
			(parts[k2] as MeshInstance3D).visibility_range_end = 14.0
	if parts.has("yeux"):
		(parts["yeux"] as MeshInstance3D).visibility_range_end = 45.0
	return parts



## V77 : les épaules suivent le bras. Quand le bras se lève au-delà de 40° (danse, salut, poing
## en l'air), la clavicule monte avec lui (la moitié de l'élévation en plus, 55° au plus),
## comme chez un vrai danseur ; le bras est recompensé pour garder exactement sa direction.
## Le haut du bras ne pivote plus seul de 170° contre le buste : l'épaule reste attachée.
## Agit après toutes les animations (clips du modèle comme poses construites).
class Epaules extends SkeletonModifier3D:
	const K: float = 0.5
	const START: float = 40.0
	const MAX: float = 55.0
	var sides: Array = []

	func setup(sk: Skeleton3D) -> void:
		for s in [["Left", 1.0], ["Right", -1.0]]:
			var sh: int = sk.find_bone(str(s[0]) + "Shoulder")
			var arm: int = sk.find_bone(str(s[0]) + "Arm")
			if sh < 0 or arm < 0 or sk.get_bone_parent(arm) != sh or sk.get_bone_parent(sh) < 0:
				continue
			sides.append([sh, arm, sk.get_bone_parent(sh), float(s[1])])

	func _process_modification_with_delta(_delta: float) -> void:
		var sk: Skeleton3D = get_skeleton()
		if sk == null or not sk.is_visible_in_tree():
			return
		for e in sides:
			var sh: int = e[0]
			var arm: int = e[1]
			var gp_rest: Quaternion = sk.get_bone_global_rest(e[2]).basis.get_rotation_quaternion()
			var gp: Quaternion = sk.get_bone_global_pose(e[2]).basis.get_rotation_quaternion()
			var garm: Quaternion = sk.get_bone_global_pose(arm).basis.get_rotation_quaternion()
			# direction du bras dans le repère du buste au repos (Y vers le haut)
			var a: Vector3 = gp_rest * (gp.inverse() * (garm * Vector3.UP))
			var elev: float = rad_to_deg(acos(clampf(-a.y, -1.0, 1.0)))
			var lift: float = minf(MAX, K * maxf(0.0, elev - START))
			if lift < 0.05:
				continue
			var c := Quaternion(Vector3(0, 0, 1), deg_to_rad(lift) * float(e[3]))
			var shl: Quaternion = (gp_rest.inverse() * c * gp_rest * sk.get_bone_pose_rotation(sh)).normalized()
			sk.set_bone_pose_rotation(sh, shl)
			sk.set_bone_pose_rotation(arm, ((gp * shl).inverse() * garm).normalized())


## Expressions : cligne (paupières), bouche (ouverte), sourire. w : 0..1.
static func set_expression(parts: Dictionary, name: String, w: float) -> void:
	for k in ["visage", "cils", "dents", "langue"]:
		var mi: MeshInstance3D = parts.get(k)
		if mi == null or mi.mesh == null:
			continue
		var i: int = mi.find_blend_shape_by_name(name)
		if i >= 0:
			mi.set_blend_shape_value(i, w)
