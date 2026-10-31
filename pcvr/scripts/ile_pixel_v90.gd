extends Node3D
## V90 : le relief de l'Île Pixelithique, à l'est de la Balafre : TOUT est en petits cubes. Le sol est
## fait de blocs de 50 cm (comme une grande île de pixels), peints de pixels fins (6 cm) par le
## shader pixel_terrain_v90 : l'herbe, le sable, la terre, la pierre, le basalte et la lave du volcan.
## Le maillage (les carrés, déjà fusionnés), les hauteurs aux coins des blocs (collision, height())
## et la matière de chaque bloc viennent de tools/generate_pixel_v90.py (relief.bin).
## Repère « île » : origine au CENTRE, axes du monde (x vers l'est, z vers le sud) ; les lieux
## ci-dessous sont gardés en accord avec l'outil (pixel_v90/terrain.py).

const Corps = preload("res://scripts/pnj/corps_v64.gd")
const BIN := "res://assets/models/pixel90/relief.bin"
const SHADER := "res://shaders/pixel_terrain_v90.gdshader"
const EAU_SHADER := "res://shaders/pixel_eau_v90.gdshader"

const CENTER := Vector3(1000.0, 0.0, -750.0)
const HALF: float = 180.0
const BLOC: float = 0.5
const LEVEL: float = 0.5
const WATER: float = -0.42
## La mer autour de l'île, et un couloir qui la relie à la mer de la grande île (au sud).
const SEA_R: float = 235.0
const SEA_LANE := Rect2(-130.0, 140.0, 140.0, 180.0)

## Les matières des blocs
enum { SABLE, HERBE, JUNGLE, TERRE, PIERRE, BASALTE, LAVE, CENDRE, BOUE, MOUSSE, ARENE, PRAIRIE }

## Les lieux (repère île) — comme dans l'outil
const VOLCAN := [72.0, -72.0, 62.0, 40.0, 13.0, 31.0]     # x, z, rayon, hauteur, rayon du cratère, lave
const PLATEAU := [-108.0, 0.0, 34.0, 62.0, 17.0]
const FALAISE_X: float = -74.0
const CAMP := [-50.0, 6.0, 20.0, 3.0]
const LAC := [-42.0, 78.0, 28.0, 1.5]
const CIRQUE := [-8.0, -118.0, 26.0, 6.0, 14.0]
const PLAGE_Z: float = 112.0
const DOCK_A := Vector2(22.0, 128.0)
const DOCK_B := Vector2(22.0, 148.0)

var n: int = 720
var coins := PackedFloat32Array()        # hauteurs aux coins des blocs, en blocs (× BLOC = mètres)
var mats := PackedByteArray()
var terrain_mat: ShaderMaterial
var water_mat: ShaderMaterial
var ok: bool = false


static func W(x: float, z: float, y: float = 0.0) -> Vector3:
	return Vector3(CENTER.x + x, y, CENTER.z + z)


static func L(wx: float, wz: float) -> Vector2:
	return Vector2(wx - CENTER.x, wz - CENTER.z)


func build(high_quality: bool) -> void:
	var t0: int = Time.get_ticks_msec()
	name = "Ile_pixel_v90"
	global_position = CENTER
	var d: Dictionary = Corps.read_bin(BIN)
	if d.is_empty():
		push_warning("V90 : le relief de l'Île Pixelithique manque (" + BIN + ")")
		return
	n = int(d["n"])
	coins = d["coins"]
	mats = d["mats"]
	terrain_mat = ShaderMaterial.new()
	terrain_mat.shader = load(SHADER)
	terrain_mat.set_shader_parameter("detail", high_quality)
	var quads: int = 0
	for ch in d["chunks"]:
		var mi: MeshInstance3D = _chunk(ch)
		if mi != null:
			add_child(mi)
			quads += (ch["tops"] as PackedInt32Array).size() / 6 + (ch["sides"] as PackedInt32Array).size() / 7
	_build_collision()
	_build_lake()
	ok = true
	print("ILE_MANGA_V90: relief de l'Île Pixelithique : %d carrés en %d ms" % [quads, Time.get_ticks_msec() - t0])


## Un morceau de relief (32 m) : les dessus, puis les côtés ; la matière dans COLOR.r, le haut de la
## colonne (pour la frange d'herbe des côtés) dans UV.x.
func _chunk(ch: Dictionary) -> MeshInstance3D:
	var tops: PackedInt32Array = ch["tops"]
	var sides: PackedInt32Array = ch["sides"]
	var nt: int = tops.size() / 6
	var ns: int = sides.size() / 7
	if nt + ns == 0:
		return null
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var cols := PackedColorArray()
	var uvs := PackedVector2Array()
	var idx := PackedInt32Array()
	verts.resize((nt + ns) * 4)
	norms.resize((nt + ns) * 4)
	cols.resize((nt + ns) * 4)
	uvs.resize((nt + ns) * 4)
	idx.resize((nt + ns) * 6)
	var k: int = 0
	var o: float = -HALF
	for q in range(nt):
		var j: int = q * 6
		var x0: float = o + tops[j] * BLOC
		var z0: float = o + tops[j + 1] * BLOC
		var x1: float = o + tops[j + 2] * BLOC
		var z1: float = o + tops[j + 3] * BLOC
		var y: float = tops[j + 4] * LEVEL
		var c := Color((tops[j + 5] + 0.5) / 16.0, 1.0, 0.0, 1.0)
		_put(verts, norms, cols, uvs, idx, k, Vector3(x0, y, z0), Vector3(x0, y, z1), Vector3(x1, y, z1), Vector3(x1, y, z0), Vector3.UP, c, y)
		k += 1
	for q2 in range(ns):
		var j2: int = q2 * 7
		var sens: int = sides[j2]
		var a0: float = o + sides[j2 + 1] * BLOC
		var a1: float = o + sides[j2 + 2] * BLOC
		var f: float = o + sides[j2 + 3] * BLOC
		var y0: float = sides[j2 + 4] * LEVEL
		var y1: float = sides[j2 + 5] * LEVEL
		var c2 := Color((sides[j2 + 6] + 0.5) / 16.0, 0.0, 0.0, 1.0)
		match sens:
			0:
				_put(verts, norms, cols, uvs, idx, k, Vector3(f, y0, a0), Vector3(f, y1, a0), Vector3(f, y1, a1), Vector3(f, y0, a1), Vector3.RIGHT, c2, y1)
			1:
				_put(verts, norms, cols, uvs, idx, k, Vector3(f, y0, a0), Vector3(f, y0, a1), Vector3(f, y1, a1), Vector3(f, y1, a0), Vector3.LEFT, c2, y1)
			2:
				_put(verts, norms, cols, uvs, idx, k, Vector3(a0, y0, f), Vector3(a1, y0, f), Vector3(a1, y1, f), Vector3(a0, y1, f), Vector3.BACK, c2, y1)
			_:
				_put(verts, norms, cols, uvs, idx, k, Vector3(a0, y0, f), Vector3(a0, y1, f), Vector3(a1, y1, f), Vector3(a1, y0, f), Vector3.FORWARD, c2, y1)
		k += 1
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = norms
	arr[Mesh.ARRAY_COLOR] = cols
	arr[Mesh.ARRAY_TEX_UV] = uvs
	arr[Mesh.ARRAY_INDEX] = idx
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	var mi := MeshInstance3D.new()
	mi.name = "Relief_%d_%d" % [int(ch["x"]), int(ch["z"])]
	mi.mesh = am
	mi.material_override = terrain_mat
	return mi


## Un carré a b c d (sens inverse des aiguilles d'une montre vu de devant) ; écrit pour Godot.
static func _put(verts: PackedVector3Array, norms: PackedVector3Array, cols: PackedColorArray, uvs: PackedVector2Array, idx: PackedInt32Array,
		k: int, a: Vector3, b: Vector3, c: Vector3, d: Vector3, nrm: Vector3, col: Color, top: float) -> void:
	var v: int = k * 4
	verts[v] = a
	verts[v + 1] = b
	verts[v + 2] = c
	verts[v + 3] = d
	for t in range(4):
		norms[v + t] = nrm
		cols[v + t] = col
		uvs[v + t] = Vector2(top, 0.0)
	var i: int = k * 6
	idx[i] = v
	idx[i + 1] = v + 2
	idx[i + 2] = v + 1
	idx[i + 3] = v
	idx[i + 4] = v + 3
	idx[i + 5] = v + 2


func _build_collision() -> void:
	var body := StaticBody3D.new()
	body.name = "Relief_collision"
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := HeightMapShape3D.new()
	shape.map_width = n + 1
	shape.map_depth = n + 1
	shape.map_data = coins
	var cs := CollisionShape3D.new()
	cs.shape = shape
	cs.scale = Vector3.ONE * BLOC
	body.add_child(cs)
	add_child(body)


## Le Lac des Long-Cous : une eau calme, en pixels elle aussi.
func _build_lake() -> void:
	var mi := MeshInstance3D.new()
	mi.name = "Lac_des_Long_Cous"
	var pm := PlaneMesh.new()
	pm.size = Vector2((float(LAC[2]) + 12.0) * 2.0, (float(LAC[2]) + 12.0) * 2.0)
	mi.mesh = pm
	water_mat = ShaderMaterial.new()
	water_mat.shader = load(EAU_SHADER)
	water_mat.set_shader_parameter("rayon", float(LAC[2]) + 3.0)
	mi.material_override = water_mat
	add_child(mi)
	mi.position = Vector3(float(LAC[0]), float(LAC[3]), float(LAC[1]))
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


# =================================================================== lecture

func contains(wx: float, wz: float) -> bool:
	return absf(wx - CENTER.x) < HALF and absf(wz - CENTER.z) < HALF


## La hauteur du sol (mètres, monde), comme la collision (les coins des blocs).
func height(wx: float, wz: float) -> float:
	if coins.is_empty():
		return WATER - 3.0
	var fx: float = clampf((wx - CENTER.x + HALF) / BLOC, 0.0, float(n) - 0.001)
	var fz: float = clampf((wz - CENTER.z + HALF) / BLOC, 0.0, float(n) - 0.001)
	var ix: int = int(fx)
	var iz: int = int(fz)
	var tx: float = fx - ix
	var tz: float = fz - iz
	var w1: int = n + 1
	var h00: float = coins[iz * w1 + ix]
	var h10: float = coins[iz * w1 + ix + 1]
	var h01: float = coins[(iz + 1) * w1 + ix]
	var h11: float = coins[(iz + 1) * w1 + ix + 1]
	return lerpf(lerpf(h00, h10, tx), lerpf(h01, h11, tx), tz) * BLOC


## Le dessus du bloc (ce qu'on voit), en mètres.
func block_top(wx: float, wz: float) -> float:
	return height(wx, wz)


func mat_at(wx: float, wz: float) -> int:
	if mats.is_empty() or not contains(wx, wz):
		return SABLE
	var ix: int = clampi(int((wx - CENTER.x + HALF) / BLOC), 0, n - 1)
	var iz: int = clampi(int((wz - CENTER.z + HALF) / BLOC), 0, n - 1)
	return mats[iz * n + ix]


func in_lake(wx: float, wz: float) -> bool:
	var l: Vector2 = L(wx, wz)
	return l.distance_to(Vector2(float(LAC[0]), float(LAC[1]))) < float(LAC[2]) + 2.0 and height(wx, wz) < float(LAC[3]) - 0.05


func in_lava(wx: float, wz: float) -> bool:
	return mat_at(wx, wz) == LAVE


## La mer de l'île (un cercle et un couloir vers la mer de la grande île, au sud) : on y nage, on y navigue.
static func sea_contains(wx: float, wz: float) -> bool:
	var l: Vector2 = L(wx, wz)
	return l.length() < SEA_R or SEA_LANE.has_point(l)


static func sea_clamp(wx: float, wz: float) -> Vector2:
	var c := Vector2(CENTER.x, CENTER.z)
	var a: Vector2 = c + (Vector2(wx, wz) - c).limit_length(SEA_R - 0.5)
	var l: Vector2 = L(wx, wz)
	var lc := Vector2(clampf(l.x, SEA_LANE.position.x + 0.5, SEA_LANE.end.x - 0.5), clampf(l.y, SEA_LANE.position.y + 0.5, SEA_LANE.end.y - 0.5))
	var b: Vector2 = c + lc
	var p := Vector2(wx, wz)
	return a if p.distance_to(a) < p.distance_to(b) else b
