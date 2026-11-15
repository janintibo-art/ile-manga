extends RefCounted
## V148 : les cartes à jouer de Pile-ou-Face (le blackjack ; plus tard le poker). Un jeu français : as, 2 à
## 10, valet (V), dame (D), roi (R) ; pique, cœur, carreau, trèfle. Une carte : un rectangle aux coins
## arrondis, sa face (le papier crème, la couleur dessinée ici, au centre et dans les coins) et son dos
## (le losange rouge et or du Tripot) ; la valeur est écrite dans les coins.
## Une carte : {"r": 1..13, "c": 0..3} (c : 0 pique, 1 cœur, 2 carreau, 3 trèfle).

const W: float = 0.064
const H: float = 0.09
const RANGS := ["", "A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "V", "D", "R"]
const NOMS_COULEURS := ["pique", "cœur", "carreau", "trèfle"]
const SYMBOLES := ["♠", "♥", "♦", "♣"]

static var _faces: Dictionary = {}
static var _dos: StandardMaterial3D
static var _quad: QuadMesh


static func rouge(c: int) -> bool:
	return c == 1 or c == 2


static func nom(carte: Dictionary) -> String:
	return "%s%s" % [RANGS[int(carte["r"])], SYMBOLES[int(carte["c"])]]


# =================================================================== les dessins

## La forme d'une couleur en (x, y) dans [-1, 1] (y vers le haut) : dedans ?
static func _dedans(c: int, x: float, y: float) -> bool:
	match c:
		1:
			# le cœur (la courbe du cœur, un peu agrandie)
			var hx: float = x * 1.25
			var hy: float = y * 1.25 + 0.2
			var a: float = hx * hx + hy * hy - 1.0
			return a * a * a - hx * hx * hy * hy * hy <= 0.0
		2:
			return absf(x) * 1.25 + absf(y) * 0.95 <= 0.95
		0:
			# le pique : un cœur renversé, et sa tige
			var px: float = x * 1.3
			var py: float = -(y - 0.12) * 1.3 + 0.2
			var b: float = px * px + py * py - 1.0
			if b * b * b - px * px * py * py * py <= 0.0 and y > -0.55:
				return true
			return y < -0.25 and y > -0.95 and absf(x) < 0.08 + (-0.25 - y) * 0.45
		_:
			# le trèfle : trois ronds, et sa tige
			for ctr in [Vector2(0, 0.42), Vector2(-0.44, -0.08), Vector2(0.44, -0.08)]:
				if Vector2(x, y).distance_to(ctr) < 0.38:
					return true
			if absf(x) < 0.12 and y > -0.2 and y < 0.3:
				return true
			return y < -0.2 and y > -0.95 and absf(x) < 0.07 + (-0.2 - y) * 0.42


## Dessine une couleur dans l'image (centre cx, cy ; demi-taille s ; antialiasé par sur-échantillonnage).
static func _symbole(img: Image, c: int, cx: float, cy: float, s: float, col: Color) -> void:
	var fond: Color
	for py in range(int(cy - s - 1), int(cy + s + 2)):
		for px in range(int(cx - s - 1), int(cx + s + 2)):
			if px < 0 or py < 0 or px >= img.get_width() or py >= img.get_height():
				continue
			var n: int = 0
			for sy in range(3):
				for sx in range(3):
					var x: float = (px + (sx + 0.5) / 3.0 - cx) / s
					var y: float = -(py + (sy + 0.5) / 3.0 - cy) / s
					if _dedans(c, x, y):
						n += 1
			if n > 0:
				fond = img.get_pixel(px, py)
				img.set_pixel(px, py, fond.lerp(col, n / 9.0))


static func _papier(w: int, h: int) -> Image:
	var img := Image.create(w, h, true, Image.FORMAT_RGBA8)
	img.fill(Color(0.97, 0.95, 0.9))
	var rng := RandomNumberGenerator.new()
	rng.seed = 148
	for k in range(w * h / 6):
		var x: int = rng.randi() % w
		var y: int = rng.randi() % h
		img.set_pixel(x, y, img.get_pixel(x, y).darkened(rng.randf_range(0.0, 0.04)))
	# un liseré gris au bord, les coins arrondis (transparents)
	var r: float = w * 0.09
	for y2 in range(h):
		for x2 in range(w):
			var dx: float = maxf(maxf(r - x2, x2 - (w - 1 - r)), 0.0)
			var dy: float = maxf(maxf(r - y2, y2 - (h - 1 - r)), 0.0)
			var d: float = Vector2(dx, dy).length()
			if d > r:
				img.set_pixel(x2, y2, Color(0, 0, 0, 0))
			elif d > r - 1.5 or x2 < 1 or y2 < 1 or x2 > w - 2 or y2 > h - 2:
				img.set_pixel(x2, y2, Color(0.6, 0.58, 0.55))
	return img


## La face (une par couleur et par sorte : « chiffre » ou « figure ») : la couleur au centre (une grande),
## une petite sous chaque coin.
static func face(c: int, figure: bool) -> StandardMaterial3D:
	var key: String = "%d_%s" % [c, "f" if figure else "n"]
	if _faces.has(key):
		return _faces[key]
	var w: int = 128
	var h: int = 180
	var img: Image = _papier(w, h)
	var col: Color = Color(0.75, 0.08, 0.08) if rouge(c) else Color(0.08, 0.07, 0.07)
	if figure:
		# un cadre doré, la couleur au milieu (le portrait : la lettre, posée dessus)
		for y in range(26, h - 26):
			for x in range(22, w - 22):
				if x < 25 or x > w - 26 or y < 29 or y > h - 30:
					img.set_pixel(x, y, Color(0.8, 0.6, 0.2))
		_symbole(img, c, w * 0.5, h * 0.62, 16.0, col)
	else:
		_symbole(img, c, w * 0.5, h * 0.52, 30.0, col)
	_symbole(img, c, 17.0, 46.0, 9.0, col)
	_symbole(img, c, w - 17.0, h - 46.0, 9.0, col)
	img.generate_mipmaps()
	var m := StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(img)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m.alpha_scissor_threshold = 0.5
	m.roughness = 0.55
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_faces[key] = m
	return m


static func dos() -> StandardMaterial3D:
	if _dos != null:
		return _dos
	var w: int = 128
	var h: int = 180
	var img: Image = _papier(w, h)
	var rouge_d := Color(0.55, 0.06, 0.08)
	var or_d := Color(0.85, 0.66, 0.3)
	for y in range(8, h - 8):
		for x in range(8, w - 8):
			if img.get_pixel(x, y).a < 0.5:
				continue
			# des losanges rouges sur un fond crème, un double filet doré
			var u: float = fposmod((x + y) * 0.12, 2.0)
			var v: float = fposmod((x - y) * 0.12, 2.0)
			var c: Color = rouge_d if (u < 1.0) != (v < 1.0) else rouge_d.darkened(0.25)
			if x < 12 or x > w - 13 or y < 12 or y > h - 13:
				c = or_d
			img.set_pixel(x, y, c)
	# au milieu : un pique d'or (la Dame de Pique)
	_symbole(img, 0, w * 0.5, h * 0.5, 20.0, or_d)
	img.generate_mipmaps()
	_dos = StandardMaterial3D.new()
	_dos.albedo_texture = ImageTexture.create_from_image(img)
	_dos.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	_dos.alpha_scissor_threshold = 0.5
	_dos.roughness = 0.5
	_dos.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return _dos


## Une couleur seule, en grand (une enseigne, un tapis) : une texture transparente.
static func texture_symbole(c: int, col: Color, taille: int = 128) -> ImageTexture:
	var img := Image.create(taille, taille, true, Image.FORMAT_RGBA8)
	img.fill(Color(col.r, col.g, col.b, 0.0))
	var tmp := Image.create(taille, taille, false, Image.FORMAT_RGBA8)
	tmp.fill(Color(0, 0, 0, 0))
	_symbole(tmp, c, taille * 0.5, taille * 0.5, taille * 0.46, Color(1, 1, 1, 1))
	for y in range(taille):
		for x in range(taille):
			img.set_pixel(x, y, Color(col.r, col.g, col.b, tmp.get_pixel(x, y).a))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


# =================================================================== une carte

## Une carte (un nœud, posé à plat, face visible ou non) ; son axe +Y local sort de la face.
static func carte(parent: Node3D, c: Dictionary, at: Vector3, yaw: float = 0.0, visible: bool = true) -> Node3D:
	if _quad == null:
		_quad = QuadMesh.new()
		_quad.size = Vector2(W, H)
	var n := Node3D.new()
	n.name = "Carte"
	parent.add_child(n)
	var col: int = int(c["c"])
	var rg: int = int(c["r"])
	var f := MeshInstance3D.new()
	f.mesh = _quad
	f.material_override = face(col, rg >= 11)
	f.rotation.x = -PI * 0.5
	f.position.y = 0.0004
	n.add_child(f)
	var b := MeshInstance3D.new()
	b.mesh = _quad
	b.material_override = dos()
	b.rotation.x = PI * 0.5
	b.position.y = -0.0004
	n.add_child(b)
	var couleur: Color = Color(0.72, 0.06, 0.06) if rouge(col) else Color(0.06, 0.05, 0.05)
	for k in range(2):
		var l := Label3D.new()
		l.text = RANGS[rg]
		l.font_size = 64 if rg != 10 else 54
		l.pixel_size = 0.00028
		l.modulate = couleur
		l.outline_size = 0
		l.double_sided = false
		l.shaded = true
		l.no_depth_test = false
		l.rotation = Vector3(-PI * 0.5, PI if k == 1 else 0.0, 0)
		l.position = Vector3(-W * 0.36, 0.0008, -H * 0.37) if k == 0 else Vector3(W * 0.36, 0.0008, H * 0.37)
		n.add_child(l)
	if rg >= 11:
		var g := Label3D.new()
		g.text = RANGS[rg]
		g.font_size = 120
		g.pixel_size = 0.00028
		g.modulate = couleur
		g.double_sided = false
		g.shaded = true
		g.rotation = Vector3(-PI * 0.5, 0, 0)
		g.position = Vector3(0, 0.0008, -H * 0.08)
		n.add_child(g)
	n.set_meta("carte", c)
	n.global_transform = Transform3D(Basis(Vector3.UP, yaw) * (Basis() if visible else Basis(Vector3.BACK, PI)), at)
	return n


## La distribuer : de « depuis » (le sabot) jusqu'à « vers », en glissant, puis la retourner si « montrer ».
static func distribuer(n: Node3D, depuis: Vector3, vers: Vector3, yaw: float, montrer: bool, duree: float = 0.45) -> Tween:
	var dos_b: Basis = Basis(Vector3.UP, yaw) * Basis(Vector3.BACK, PI)
	var fin_b: Basis = Basis(Vector3.UP, yaw) * (Basis() if montrer else Basis(Vector3.BACK, PI))
	n.global_transform = Transform3D(dos_b, depuis)
	var tw: Tween = n.create_tween()
	tw.tween_method(func(t: float) -> void:
		var p: Vector3 = depuis.lerp(vers, 1.0 - pow(1.0 - t, 2.2))
		p.y += sin(t * PI) * 0.05
		var k: float = smoothstep(0.55, 1.0, t)
		n.global_transform = Transform3D(Basis(Quaternion(dos_b).slerp(Quaternion(fin_b), k)), p), 0.0, 1.0, duree)
	return tw


## Retourner une carte posée face cachée.
static func retourner(n: Node3D, duree: float = 0.35) -> Tween:
	var b0: Basis = n.global_transform.basis
	var b1: Basis = b0 * Basis(Vector3.BACK, PI)
	var p0: Vector3 = n.global_position
	var tw: Tween = n.create_tween()
	tw.tween_method(func(t: float) -> void:
		n.global_transform = Transform3D(Basis(Quaternion(b0).slerp(Quaternion(b1), t)), p0 + Vector3.UP * sin(t * PI) * 0.04), 0.0, 1.0, duree)
	return tw
