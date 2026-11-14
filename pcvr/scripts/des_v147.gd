extends RefCounted
## V147 : les dés de Pile-ou-Face. Un dé (un cube aux coins arrondis, ses points peints : la texture est
## faite ici), et le lancer : le dé part de la main, vole en tournant, rebondit sur le tapis, roule un peu
## et s'arrête sur la face tirée (tirée d'avance : l'animation ne fait que la montrer).
## Faces : +Y 1, -Y 6, +X 2, -X 5, +Z 3, -Z 4 (les faces opposées font sept).

static var _mesh_cache: Dictionary = {}


## La rotation qui met la face « v » vers le haut (puis un quart de tour au hasard autour de Y).
static func rot_face(v: int, yaw: float = 0.0) -> Basis:
	var b := Basis()
	match v:
		6:
			b = Basis(Vector3.RIGHT, PI)
		2:
			b = Basis(Vector3.BACK, PI * 0.5)
		5:
			b = Basis(Vector3.BACK, -PI * 0.5)
		3:
			b = Basis(Vector3.RIGHT, -PI * 0.5)
		4:
			b = Basis(Vector3.RIGHT, PI * 0.5)
	return Basis(Vector3.UP, yaw) * b


## La face qui regarde vers le haut (pour vérifier).
static func face_haut(b: Basis) -> int:
	var best: int = 1
	var bd: float = -2.0
	for e in [[1, Vector3.UP], [6, Vector3.DOWN], [2, Vector3.RIGHT], [5, Vector3.LEFT], [3, Vector3.BACK], [4, Vector3.FORWARD]]:
		var d: float = (b * (e[1] as Vector3)).dot(Vector3.UP)
		if d > bd:
			bd = d
			best = int(e[0])
	return best


## La texture : six faces côte à côte (1 à 6), ivoire, points noirs (rouge pour le 1, à l'ancienne).
static func _atlas(fond: Color, point: Color, un: Color) -> ImageTexture:
	var s: int = 64
	var img := Image.create(s * 6, s, true, Image.FORMAT_RGBA8)
	img.fill(fond)
	var pos := {1: [[0.5, 0.5]], 2: [[0.27, 0.27], [0.73, 0.73]], 3: [[0.25, 0.25], [0.5, 0.5], [0.75, 0.75]],
		4: [[0.27, 0.27], [0.73, 0.27], [0.27, 0.73], [0.73, 0.73]], 5: [[0.25, 0.25], [0.75, 0.25], [0.5, 0.5], [0.25, 0.75], [0.75, 0.75]],
		6: [[0.27, 0.22], [0.73, 0.22], [0.27, 0.5], [0.73, 0.5], [0.27, 0.78], [0.73, 0.78]]}
	for v in range(1, 7):
		var r: float = 0.11 * s if v != 1 else 0.17 * s
		for p in pos[v]:
			var cx: float = (v - 1) * s + float(p[0]) * s
			var cy: float = float(p[1]) * s
			for y in range(int(cy - r - 2), int(cy + r + 3)):
				for x in range(int(cx - r - 2), int(cx + r + 3)):
					var d: float = Vector2(x + 0.5 - cx, y + 0.5 - cy).length()
					if d < r + 1.0:
						var a: float = clampf(r + 0.5 - d, 0.0, 1.0)
						var c: Color = un if v == 1 else point
						img.set_pixel(x, y, fond.lerp(c, a))
		# un liseré plus sombre au bord (les arêtes usées)
		for k in range(s):
			for e in [[k, 0], [k, s - 1], [0, k], [s - 1, k]]:
				img.set_pixel((v - 1) * s + int(e[0]), int(e[1]), fond.darkened(0.25))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


## Un dé de côté « c » (le maillage, gardé en cache par couleur).
static func mesh(c: float = 0.05, genre: String = "ivoire") -> ArrayMesh:
	var key: String = "%s_%.3f" % [genre, c]
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var faces := {1: Vector3.UP, 6: Vector3.DOWN, 2: Vector3.RIGHT, 5: Vector3.LEFT, 3: Vector3.BACK, 4: Vector3.FORWARD}
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var h: float = c * 0.5
	for v in range(1, 7):
		var n: Vector3 = faces[v]
		# deux axes dans le plan de la face
		var u: Vector3 = (Vector3.UP if absf(n.y) < 0.9 else Vector3.BACK).cross(n).normalized()
		var w: Vector3 = n.cross(u).normalized()
		var bev: float = c * 0.08
		var corners := [n * h + (-u - w) * (h - bev), n * h + (u - w) * (h - bev), n * h + (u + w) * (h - bev), n * h + (-u + w) * (h - bev)]
		var uv0: float = (v - 1) / 6.0
		var uvs := [Vector2(uv0, 1), Vector2(uv0 + 1.0 / 6.0, 1), Vector2(uv0 + 1.0 / 6.0, 0), Vector2(uv0, 0)]
		for idx in [0, 1, 2, 0, 2, 3]:
			st.set_normal(n)
			st.set_uv(uvs[idx])
			st.add_vertex(corners[idx])
		# les chanfreins (les arêtes arrondies, en une facette) vers les quatre voisines
		for e in range(4):
			var a: Vector3 = corners[e]
			var b: Vector3 = corners[(e + 1) % 4]
			var out: Vector3 = ((a + b) * 0.5 - n * h).normalized()
			var a2: Vector3 = a + out * bev - n * bev
			var b2: Vector3 = b + out * bev - n * bev
			var nn: Vector3 = (n + out).normalized()
			for p in [a, b2, b, a, a2, b2]:
				st.set_normal(nn)
				st.set_uv(Vector2(uv0 + 0.5 / 6.0, 0.02))
				st.add_vertex(p)
	st.generate_tangents()
	var m := st.commit()
	var mat := StandardMaterial3D.new()
	match genre:
		"rouge":
			mat.albedo_texture = _atlas(Color(0.72, 0.1, 0.1), Color(0.97, 0.95, 0.9), Color(0.97, 0.95, 0.9))
		"or":
			mat.albedo_texture = _atlas(Color(0.95, 0.76, 0.32), Color(0.2, 0.12, 0.05), Color(0.2, 0.12, 0.05))
			mat.metallic = 0.7
		_:
			mat.albedo_texture = _atlas(Color(0.95, 0.91, 0.82), Color(0.08, 0.06, 0.05), Color(0.72, 0.08, 0.06))
	mat.roughness = 0.35
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	m.surface_set_material(0, mat)
	_mesh_cache[key] = m
	return m


## Un dé (un nœud), posé.
static func de(parent: Node3D, at: Vector3, v: int, c: float = 0.05, genre: String = "ivoire") -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh(c, genre)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(mi)
	mi.global_transform = Transform3D(rot_face(v, randf() * TAU), at + Vector3.UP * c * 0.5)
	mi.set_meta("valeur", v)
	return mi


## Le lancer : de « depuis » jusqu'à « vers » (sur le tapis), en « duree » secondes ; le dé finit sur la
## face « v ». Rend le Tween (on peut l'attendre).
static func lancer(d: MeshInstance3D, depuis: Vector3, vers: Vector3, v: int, duree: float = 1.0, c: float = 0.05) -> Tween:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var fin_b: Basis = rot_face(v, rng.randf() * TAU)
	var axe: Vector3 = Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.3, 0.3), rng.randf_range(-1, 1)).normalized()
	var tours: float = rng.randf_range(3.0, 5.0) * TAU
	var rebond: Vector3 = depuis.lerp(vers, 0.62) + Vector3(rng.randf_range(-0.06, 0.06), 0, rng.randf_range(-0.06, 0.06))
	rebond.y = vers.y
	d.global_position = depuis
	d.set_meta("valeur", v)
	var tw: Tween = d.create_tween()
	var b0: Basis = d.global_transform.basis.orthonormalized()
	tw.tween_method(func(t: float) -> void:
		var p: Vector3
		var y0: float = vers.y + c * 0.5
		if t < 0.55:
			var u: float = t / 0.55
			p = depuis.lerp(rebond, u)
			p.y = lerpf(depuis.y, y0, u) + sin(u * PI) * 0.22
		else:
			var u2: float = (t - 0.55) / 0.45
			var e: float = 1.0 - pow(1.0 - u2, 2.0)
			p = rebond.lerp(vers, e)
			p.y = y0 + absf(sin(u2 * PI * 2.0)) * 0.05 * (1.0 - u2)
		var spin: Basis = Basis(axe, tours * (1.0 - pow(1.0 - t, 2.5)))
		var bb: Basis = (spin * b0).orthonormalized()
		var k: float = smoothstep(0.62, 0.97, t)
		var q: Quaternion = Quaternion(bb).slerp(Quaternion(fin_b), k)
		d.global_transform = Transform3D(Basis(q), p), 0.0, 1.0, duree)
	return tw
