extends "res://scripts/donjon_kit_v69.gd"
## V70 : la boîte à outils de Pandémonia, la cité des démons (et des Neuf Cercles, sous la
## Cathédrale-Forge). Même principe que les autres kits : la géométrie regroupée par matière
## (un maillage par matière et par quartier : commit() après chaque quartier), les collisions
## dans un seul corps statique ; les matières « …70 » viennent de braise_mats_v70.gd, les autres
## des kits précédents (fer, poutre, toile…).
##  - l'arc brisé : ogive() (son contour), ogive_face() (une baie, une porte, un vitrail),
##    ogive_frame() (son encadrement mouluré ; en grand, l'arche d'un pont ou d'une porte) ;
##  - les façades : gothic_window(), gothic_door(), rose_window(), shop_sign(), banner70(),
##    balcony70() ;
##  - house70() : la maison gothique de Pandémonia (rez-de-chaussée de pierre sombre, étages
##    d'enduit rouge ou de brique noire en encorbellement, pignon pointu sur rue, ardoises,
##    cheminées, tourelle d'angle, enseigne…) ;
##  - tower70(), turret70(), spire70(), pinnacle(), buttress(), crenels(), wall_line(),
##    parapet70(), railing70(), bridge70(), arch_gate() ;
##  - lamp70() (un réverbère), wall_lamp70(), great_lantern() (une des sept Grandes Lanternes),
##    demon_statue(), gargoyle(), fire_fountain(), bench70(), ball(), horn().
## Repères : comme les autres kits, une façade « xf » regarde +Z local (XZ() des villages).

const Mats70 = preload("res://scripts/braise_mats_v70.gd")
## Les pièces répétées des milliers de fois (fenêtres, portes, lanternes, merlons) ne sont pas
## recopiées dans les maillages : elles sont dessinées une fois (un « prototype ») et posées en
## MultiMesh, un par quartier (place() puis commit()).
const NO_SHADOW := ["fen_d1", "fen_d0", "fen_s1", "fen_s0", "lanterne", "rose"]

var lamps70: Array = []                  # OmniLight3D des réverbères (la nuit : temps_v56)
var chimneys70: Array = []               # Vector3 : le haut des cheminées (la fumée)
var fires70: Array = []                  # [Vector3, taille] : des feux (statues, fontaines, braseros)
var lights70_budget: int = 400           # au-delà, les réverbères n'ont plus de vraie lumière
var light_every: int = 1                 # une vraie lumière tous les n réverbères
var inst: Dictionary = {}                # prototype -> [Transform3D]
var protos: Dictionary = {}              # prototype -> ArrayMesh
var inst_count: int = 0


func mat(key: String) -> Material:
	if mats.has(key):
		return mats[key]
	var m: Material = Mats70.make(key)
	if m != null:
		mats[key] = m
		return m
	return super.mat(key)


## Pose une pièce répétée (prototype « genre|matière » : fen_d1|pgoth70, porte|pgoth70,
## lanterne, merlon|pgoth70…).
func place(key: String, xf: Transform3D) -> void:
	if not inst.has(key):
		inst[key] = []
	(inst[key] as Array).append(xf)
	inst_count += 1


## Le maillage d'un prototype (dessiné une fois, à l'origine).
func proto(key: String) -> ArrayMesh:
	if protos.has(key):
		return protos[key]
	var saved: Dictionary = batch
	batch = {}
	var parts: PackedStringArray = key.split("|")
	var kind: String = parts[0]
	var mk: String = parts[1] if parts.size() > 1 else "pgoth70"
	var I := Transform3D.IDENTITY
	match kind:
		"fen_d1", "fen_d0", "fen_s1", "fen_s0":
			_win_geo(I, 1.0, 2.1, kind.ends_with("1"), mk, kind.begins_with("fen_d"))
		"porte":
			_door_geo(I, 1.3, 2.75, "boisb70", mk, true)
		"lanterne":
			_lantern_geo(Vector3.ZERO, 1.0)
		"merlon":
			box(T(0, 0.5, 0), Vector3.ONE, mk, 1.0, 63 - 8)
		"barreau":
			box(T(0, 0.5, 0), Vector3(0.025, 1.0, 0.025), "fer70", 1.0, 1 | 2 | 16 | 32)
			cyl(T(0, 1.0, 0), 0.025, 0.0, 0.14, "fer70", 4, false)
		"reverbere":
			_lamp_geo(3.9)
	var mesh := ArrayMesh.new()
	for k in batch:
		var st: SurfaceTool = batch[k]
		var m: Material = mat(str(k))
		if m is StandardMaterial3D and (m as StandardMaterial3D).normal_enabled:
			st.generate_tangents()
		st.commit(mesh)
		mesh.surface_set_material(mesh.get_surface_count() - 1, m)
	batch = saved
	protos[key] = mesh
	return mesh


## Les maillages du quartier (une matière, un maillage) et ses pièces répétées (des MultiMesh).
func commit() -> void:
	super.commit()
	for k in inst:
		var arr: Array = inst[k]
		if arr.is_empty():
			continue
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = proto(str(k))
		mm.instance_count = arr.size()
		for i in range(arr.size()):
			mm.set_instance_transform(i, arr[i])
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "Pieces_" + str(k).replace("|", "_")
		mmi.multimesh = mm
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if NO_SHADOW.has(str(k).split("|")[0]) else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		mmi.visibility_range_end = 900.0
		root.add_child(mmi)
	inst.clear()


func T(x: float, y: float, z: float) -> Transform3D:
	return Transform3D(Basis(), Vector3(x, y, z))


## Un repère posé sur un mur rond (centre c, rayon r, angle a), à la hauteur y, qui regarde
## dehors (+Z local vers l'extérieur).
func face_out(c: Vector3, r: float, a: float, y: float) -> Transform3D:
	var out := Vector3(cos(a), 0.0, sin(a))
	return Transform3D(Basis.looking_at(-out, Vector3.UP), c + out * r + Vector3.UP * y)


# =================================================================== l'arc brisé

## Le contour d'une baie en arc brisé (plan XY local, le bas en y = 0) : du bas à gauche au bas
## à droite, puis la pointe. w : la largeur, h : la hauteur totale.
static func ogive(w: float, h: float, seg: int = 4) -> PackedVector2Array:
	var hw: float = w * 0.5
	var ah: float = minf(w * 0.866, h * 0.62)
	var hs: float = h - ah
	var r: float = (hw * hw + ah * ah) / (2.0 * hw)
	var ta: float = atan2(ah, r - hw)
	var pts := PackedVector2Array([Vector2(-hw, 0.0), Vector2(hw, 0.0)])
	for i in range(seg + 1):
		var t: float = ta * float(i) / seg
		pts.append(Vector2(hw - r + r * cos(t), hs + r * sin(t)))
	for i2 in range(seg - 1, -1, -1):
		var t2: float = ta * float(i2) / seg
		pts.append(Vector2(-(hw - r + r * cos(t2)), hs + r * sin(t2)))
	return pts


## La hauteur du contour d'une baie en arc brisé (w × h, le bas en y = 0) à l'abscisse x.
static func ogive_y(w: float, h: float, x: float) -> float:
	var hw: float = w * 0.5
	if absf(x) >= hw:
		return 0.0
	var ah: float = minf(w * 0.866, h * 0.62)
	var hs: float = h - ah
	var r: float = (hw * hw + ah * ah) / (2.0 * hw)
	var cx: float = hw - r
	var dx: float = absf(x) - cx
	return hs + sqrt(maxf(r * r - dx * dx, 0.0))


## Une baie pleine en arc brisé (vitre, vantail, vitrail) qui regarde +Z ; la texture couvre
## le rectangle w × h (uv : la part de la texture).
func ogive_face(xf: Transform3D, w: float, h: float, key: String, seg: int = 4, uv := Rect2(0, 0, 1, 1)) -> void:
	var pts: PackedVector2Array = ogive(w, h, seg)
	var n: Vector3 = (xf.basis * Vector3(0, 0, 1)).normalized()
	var c := Vector2(0.0, h * 0.45)
	var cu := Vector2(uv.position.x + uv.size.x * 0.5, uv.position.y + uv.size.y * (1.0 - c.y / h))
	for i in range(pts.size()):
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[(i + 1) % pts.size()]
		var ua := Vector2(uv.position.x + uv.size.x * (a.x / w + 0.5), uv.position.y + uv.size.y * (1.0 - a.y / h))
		var ub := Vector2(uv.position.x + uv.size.x * (b.x / w + 0.5), uv.position.y + uv.size.y * (1.0 - b.y / h))
		tri(key, xf * Vector3(c.x, c.y, 0.0), xf * Vector3(a.x, a.y, 0.0), xf * Vector3(b.x, b.y, 0.0), n, cu, ua, ub)


## L'encadrement mouluré d'une baie en arc brisé (fw : sa largeur, depth : sa saillie) ; en
## grand, l'arche d'un pont ou d'une porte de ville (depth : l'épaisseur du mur).
func ogive_frame(xf: Transform3D, w: float, h: float, fw: float, depth: float, key: String, seg: int = 4, back: bool = false) -> void:
	var pts: PackedVector2Array = ogive(w, h, seg)
	var cnt: int = pts.size()
	var mid0 := Vector2(0.0, h * 0.45)
	for i in range(1, cnt):
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[(i + 1) % cnt]
		var m: Vector2 = (a + b) * 0.5
		var dir: Vector2 = (b - a).normalized()
		var out := Vector2(dir.y, -dir.x)
		if out.dot(m - mid0) < 0.0:
			out = -out
		var len: float = a.distance_to(b) + fw * 0.55
		var c2: Vector2 = m + out * fw * 0.5
		var z: float = depth * 0.5 - 0.02 if not back else 0.0
		box(xf * Transform3D(Basis(Vector3(0, 0, 1), atan2(dir.y, dir.x)), Vector3(c2.x, c2.y, z)), Vector3(len, fw, depth), key, 1.2, 63 if back else 31)


# =================================================================== façades

## Une fenêtre gothique (xf : le bas-milieu de la baie, sur le nu du mur qui regarde +Z) ; lit :
## allumée le soir (la vitre « fenetre70 » s'éclaire avec les réverbères) ; detail : l'encadrement
## mouluré (sinon un simple appui). Posée en pièce répétée (le prototype fait 1 × 2,1 m).
func gothic_window(xf: Transform3D, w: float, h: float, lit: bool, frame_key: String = "pgoth70", detail: bool = true) -> void:
	var k: String = ("fen_d" if detail else "fen_s") + ("1" if lit else "0") + "|" + frame_key
	place(k, xf * Transform3D(Basis.from_scale(Vector3(w, h / 2.1, 1.0)), Vector3.ZERO))


func _win_geo(xf: Transform3D, w: float, h: float, lit: bool, frame_key: String, detail: bool) -> void:
	ogive_face(xf * T(0, 0, 0.015), w, h, "fenetre70" if lit else "fenetrenoire70", 4 if detail else 3, Rect2(0.08, 0.02, 0.84, 0.94))
	if detail:
		ogive_frame(xf, w, h, 0.13, 0.12, frame_key, 3)
		box(xf * T(0, -0.07, 0.1), Vector3(w + 0.42, 0.14, 0.24), frame_key, 1.0, 31)
	else:
		box(xf * T(0, -0.05, 0.06), Vector3(w + 0.24, 0.1, 0.14), frame_key, 1.0, 31)


## Une porte gothique en arc brisé : vantail de bois sombre, pentures de fer, encadrement de
## pierre, une marche. xf : le bas-milieu, sur le nu du mur. Les portes ordinaires (1,3 × 2,75 m)
## sont des pièces répétées.
func gothic_door(xf: Transform3D, w: float, h: float, wood: String = "boisb70", frame_key: String = "pgoth70", step: bool = true) -> void:
	if wood == "boisb70" and step and absf(w - 1.3) < 0.01 and absf(h - 2.75) < 0.01:
		place("porte|" + frame_key, xf)
		return
	_door_geo(xf, w, h, wood, frame_key, step)


func _door_geo(xf: Transform3D, w: float, h: float, wood: String, frame_key: String, step: bool) -> void:
	ogive_face(xf * T(0, 0, 0.02), w, h, wood, 4)
	var rect_h: float = h - minf(w * 0.866, h * 0.62)
	for k in range(3):
		box(xf * T(0, 0.42 + k * (rect_h - 0.5) * 0.5, 0.05), Vector3(w * 0.92, 0.07, 0.03), "fer70", 1.0, 31)
	box(xf * T(w * 0.27, rect_h * 0.55, 0.08), Vector3(0.05, 0.16, 0.06), "fer70", 1.0, 31)
	cyl(Transform3D(xf.basis * Basis(Vector3.RIGHT, PI * 0.5), xf * Vector3(-w * 0.2, rect_h * 0.55, 0.06)), 0.07, 0.07, 0.02, "fer70", 8)
	ogive_frame(xf, w, h, 0.26, 0.26, frame_key, 4)
	if step:
		box(xf * T(0, 0.07, 0.42), Vector3(w + 0.9, 0.14, 0.84), frame_key, 1.0, 63 - 8)


## Une rose (un vitrail rond) : xf au centre, qui regarde +Z ; son anneau de pierre.
func rose_window(xf: Transform3D, r: float, key: String = "vitrail70_rosace", frame_key: String = "pgoth70") -> void:
	var n: Vector3 = (xf.basis * Vector3(0, 0, 1)).normalized()
	var seg: int = 28
	for i in range(seg):
		var a0: float = TAU * i / seg
		var a1: float = TAU * (i + 1) / seg
		tri(key, xf * Vector3(0, 0, 0.02), xf * Vector3(cos(a0) * r, sin(a0) * r, 0.02), xf * Vector3(cos(a1) * r, sin(a1) * r, 0.02), n,
			Vector2(0.5, 0.5), Vector2(0.5 + cos(a0) * 0.5, 0.5 - sin(a0) * 0.5), Vector2(0.5 + cos(a1) * 0.5, 0.5 - sin(a1) * 0.5))
	ring(xf * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0, -0.1)), r, r + 0.35, 0.34, frame_key, seg)


## Une enseigne pendue à une potence de fer, perpendiculaire à la façade (xf : le point
## d'accroche sur le mur ; la potence avance vers +Z).
func shop_sign(xf: Transform3D, sign_key: String, w: float = 1.2, h: float = 0.6) -> void:
	box(xf * T(0, 0, 0.6), Vector3(0.05, 0.05, 1.2), "fer70", 1.0)
	beam(xf * Vector3(0, -0.5, 0.02), xf * Vector3(0, -0.02, 0.75), 0.035, "fer70")
	box(xf * T(0, 0.05, 0.02), Vector3(0.14, 0.24, 0.04), "fer70", 1.0)
	var sx: Transform3D = xf * Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(0, -h * 0.5 - 0.1, 0.65))
	box(sx, Vector3(w + 0.08, h + 0.08, 0.04), "boisb70", 0.6)
	quadz(sx * T(0, 0, 0.024), w, h, sign_key)
	quad(sx * T(0, 0, -0.024), w, h, sign_key)
	for s in [-1.0, 1.0]:
		cyl(Transform3D(Basis(), xf * Vector3(0, -0.1, 0.65 + s * w * 0.42)), 0.008, 0.008, 0.1, "fer70", 4, false)


## Une bannière de Pandémonia, pendue à une hampe de fer contre la façade (xf : le haut-milieu).
func banner70(xf: Transform3D, w: float = 0.9, h: float = 2.4, key: String = "banniere70") -> void:
	cyl(Transform3D(xf.basis * Basis(Vector3.BACK, PI * 0.5), xf * Vector3(w * 0.5 + 0.12, 0.05, 0.12)), 0.03, 0.03, w + 0.24, "fer70", 6, true)
	for s in [-1.0, 1.0]:
		cyl(Transform3D(Basis(), xf * Vector3(s * (w * 0.5 + 0.12), 0.05, 0.12)), 0.05, 0.0, 0.12, "or70", 6)
	quadz(xf * T(0, -h * 0.5, 0.12), w, h, key)


## Un balcon de fer forgé (xf : le milieu du bord du mur, au niveau du plancher ; il avance vers +Z).
func balcony70(xf: Transform3D, w: float, depth: float = 0.8) -> void:
	box(xf * T(0, -0.1, depth * 0.5), Vector3(w, 0.2, depth), "pgoth70", 1.0)
	for k in range(3):
		var cx: float = -w * 0.35 + k * w * 0.35
		cyl(Transform3D(xf.basis * Basis(Vector3.RIGHT, PI * 0.5), xf * Vector3(cx, -0.2, 0.05)), 0.12, 0.02, depth * 0.85, "pgoth70", 6)
	box(xf * T(0, 1.0, depth - 0.02), Vector3(w, 0.05, 0.05), "fer70", 1.0)
	for s in [-1.0, 1.0]:
		box(xf * T(s * (w * 0.5 - 0.02), 1.0, depth * 0.5), Vector3(0.05, 0.05, depth), "fer70", 1.0)
	var nb: int = int(w / 0.16)
	for i in range(nb + 1):
		place("barreau", xf * T(-w * 0.5 + w * i / nb, 0.0, depth - 0.02))
	for s2 in [-1.0, 1.0]:
		for j in range(int(depth / 0.16)):
			place("barreau", xf * T(s2 * (w * 0.5 - 0.02), 0.0, 0.1 + j * 0.16))


# =================================================================== la maison gothique

## La maison de Pandémonia. xf : le milieu de la façade au sol, la façade regarde +Z ; la maison
## s'étend vers -Z sur d mètres. opts :
##  floors (rez compris), gf / uf (hauteurs d'étage), base (pierre du rez), wall (étages),
##  trim (encadrements), roof (ardoise70, tuile70, cuivre70), pitch, jet (encorbellement),
##  gable (pignon sur rue), lit (part des fenêtres allumées), door_x, door (false : pas de porte),
##  shop (« taverne »… : une enseigne et une grande vitrine), back (fenêtres derrière),
##  sides (1 : à gauche, 2 : à droite, 3 : les deux), chimney, turret (-1 / 1 : à gauche /
##  à droite), balcony (étage), banner, finial.
## Renvoie le point devant la porte.
func house70(xf: Transform3D, w: float, d: float, opts: Dictionary = {}) -> Vector3:
	var floors: int = maxi(int(opts.get("floors", 3)), 1)
	var gf: float = float(opts.get("gf", 3.6))
	var uf: float = float(opts.get("uf", 3.1))
	var H: float = gf + uf * (floors - 1)
	var base: String = str(opts.get("base", "pgoth70_sombre"))
	var wall: String = str(opts.get("wall", "erouge70"))
	var trim: String = str(opts.get("trim", "pgoth70"))
	var roof: String = str(opts.get("roof", "ardoise70"))
	var pitch: float = float(opts.get("pitch", 56.0))
	var jet: float = float(opts.get("jet", 0.3)) if floors > 1 else 0.0
	var lit_k: float = float(opts.get("lit", 0.55))
	var dx: float = float(opts.get("door_x", 0.0))
	var sides: int = int(opts.get("sides", 0))
	var gable: bool = bool(opts.get("gable", true))
	var shop: String = str(opts.get("shop", ""))
	# le soubassement de basalte, le rez-de-chaussée de pierre
	box(xf * T(0, 0.05, -d * 0.5), Vector3(w + 0.14, 0.7, d + 0.14), "basalte70", 1.6, 63 - 8)
	box(xf * T(0, gf * 0.5, -d * 0.5), Vector3(w, gf, d), base, 2.4, 63 - 8 - 4)
	col_box(xf * T(0, H * 0.5, -d * 0.5), Vector3(w, H, d))
	# les étages, en encorbellement sur la rue
	if floors > 1:
		var uh: float = H - gf
		box(xf * T(0, gf + uh * 0.5, (jet - d) * 0.5), Vector3(w, uh, d + jet), wall, 2.6, 63 - 8 - 4)
		box(xf * T(0, gf - 0.02, (jet - d) * 0.5), Vector3(w + 0.16, 0.26, d + jet + 0.16), trim, 1.4)
		for k in range(1, floors - 1):
			box(xf * T(0, gf + k * uf, (jet - d) * 0.5), Vector3(w + 0.1, 0.14, d + jet + 0.1), trim, 1.4, 63 - 8 - 4)
	box(xf * T(0, H - 0.1, (jet - d) * 0.5), Vector3(w + 0.3, 0.32, d + jet + 0.3), trim, 1.4)
	# les fenêtres de la façade : des baies gothiques à encadrement, allumées ou non
	var n: int = clampi(int((w - 0.6) / 1.9), 1, 4)
	var ww: float = minf(1.0, w / n * 0.48)
	var wh: float = minf(2.15, uf * 0.68)
	for f in range(1, floors):
		var y: float = gf + (f - 1) * uf + uf * 0.2
		for i in range(n):
			var x: float = -w * 0.5 + (i + 0.5) * w / n
			gothic_window(xf * T(x, y, jet), ww, wh, rng.randf() < lit_k, trim, true)
	# le rez-de-chaussée : la porte, une vitrine (boutique) ou de petites fenêtres
	if bool(opts.get("door", true)):
		gothic_door(xf * T(dx, 0.0, 0.0), 1.3, 2.75, "boisb70", trim)
	for i2 in range(n):
		var x2: float = -w * 0.5 + (i2 + 0.5) * w / n
		if absf(x2 - dx) < 1.5:
			continue
		if shop != "":
			gothic_window(xf * T(x2, 0.55, 0.0), minf(1.6, w / n * 0.7), 2.4, true, trim, true)
		else:
			gothic_window(xf * T(x2, 1.0, 0.0), ww * 0.85, 1.7, rng.randf() < lit_k * 0.8, trim, false)
	if shop != "":
		shop_sign(xf * T(w * 0.5 - 0.5, gf - 0.2, 0.0), "enseigne70_" + shop)
	# derrière (et sur les côtés si la maison est seule) : des baies simples
	if bool(opts.get("back", true)):
		var bx: Transform3D = xf * Transform3D(Basis(Vector3.UP, PI), Vector3(0, 0, -d))
		for f2 in range(1, floors):
			for i3 in range(n):
				var x3: float = -w * 0.5 + (i3 + 0.5) * w / n
				gothic_window(bx * T(x3, gf + (f2 - 1) * uf + uf * 0.2, 0.0), ww * 0.9, wh * 0.9, rng.randf() < lit_k * 0.8, trim, false)
	for sd in [1, 2]:
		if (sides & sd) == 0:
			continue
		var sgn: float = -1.0 if sd == 1 else 1.0
		var sx: Transform3D = xf * Transform3D(Basis(Vector3.UP, sgn * PI * 0.5), Vector3(sgn * w * 0.5, 0, -d * 0.5))
		var ns: int = clampi(int((d - 0.6) / 2.2), 1, 4)
		for f3 in range(1, floors):
			for i4 in range(ns):
				var x4: float = -d * 0.5 + (i4 + 0.5) * d / ns
				gothic_window(sx * T(x4, gf + (f3 - 1) * uf + uf * 0.2, 0.0), ww * 0.9, wh * 0.9, rng.randf() < lit_k * 0.8, trim, false)
	# le toit : un pignon pointu sur la rue (ou un long pan et des lucarnes)
	var rise: float
	if gable:
		rise = roof_gable(xf * Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(0, H, (jet - d) * 0.5)), d + jet, w, pitch, 0.35, roof, wall)
		if rise > 2.4:
			gothic_window(xf * T(0, H + 0.45, jet + 0.01), minf(0.75, w * 0.14), minf(1.7, rise * 0.42), rng.randf() < lit_k, trim, false)
		if bool(opts.get("finial", true)):
			cyl(xf * T(0, H + rise - 0.1, jet + 0.2), 0.06, 0.0, 1.1, "fer70", 6)
			ball(xf * T(0, H + rise + 0.25, jet + 0.2), 0.09, "or70", 6, 3)
	else:
		rise = roof_gable(xf * T(0, H, (jet - d) * 0.5), w, d + jet, pitch * 0.85, 0.35, roof, wall)
		var nd: int = clampi(int(w / 3.4), 1, 3)
		for i5 in range(nd):
			var x5: float = -w * 0.5 + (i5 + 0.5) * w / nd
			dormer70(xf * T(x5, H + 0.15, jet - 0.35 - (d + jet) * 0.12), 1.0, 1.5, roof, wall, trim, rng.randf() < lit_k)
	# la cheminée
	if bool(opts.get("chimney", rng.randf() < 0.65)):
		var cxs: float = (w * 0.22) * (1.0 if rng.randf() < 0.5 else -1.0)
		var ch_h: float = rise + 1.6
		box(xf * T(cxs, H + ch_h * 0.5, -d * 0.62), Vector3(0.7, ch_h, 0.7), "bnoire70", 1.2, 63 - 8)
		box(xf * T(cxs, H + ch_h + 0.07, -d * 0.62), Vector3(0.92, 0.14, 0.92), trim, 1.0)
		for s in [-1.0, 1.0]:
			box(xf * T(cxs + s * 0.16, H + ch_h + 0.3, -d * 0.62), Vector3(0.16, 0.32, 0.4), "bnoire70", 1.0, 63 - 8)
		chimneys70.append(xf * Vector3(cxs, H + ch_h + 0.45, -d * 0.62))
	# une tourelle d'angle en encorbellement
	var tur: int = int(opts.get("turret", 0))
	if tur != 0 and floors >= 3:
		turret70(xf * T(float(tur) * (w * 0.5 + 0.15), gf + uf * 0.6, jet + 0.15), 1.05, H - gf - uf * 0.6 + 1.2, 3.8, wall, roof, trim, rng.randf() < lit_k)
	var bal: int = int(opts.get("balcony", 0))
	if bal > 0 and bal < floors:
		balcony70(xf * T(0, gf + (bal - 1) * uf, jet), minf(w * 0.55, 3.0))
	if bool(opts.get("banner", false)) and floors >= 3:
		banner70(xf * T(-w * 0.5 + 0.75 if n > 1 else 0.0, H - 0.4, jet), 0.8, minf(2.6, uf * 1.1))
	if bool(opts.get("door", true)) and bool(opts.get("v81", false)):
		porte_v81(xf, Vector3(dx, 0.0, 1.2), w, d, "braise", floors)
	return xf * Vector3(dx, 0.0, 1.2)


## Une grande salle gothique où l'on entre (la taverne, la salle du trône, la bibliothèque…).
## xf : le milieu de la façade au sol, la façade regarde +Z, la salle s'étend vers -Z sur d.
## opts : h (hauteur des murs), t (épaisseur), wall (dehors), inner (dedans), floor_key,
## door_w, door_h (la baie rectangulaire ; l'arc brisé et son tympan au-dessus), door_x, roof
## (ardoise70, tuile70, cuivre70 ; "" : pas de toit), pitch, windows (fenêtres sur les côtés),
## back_door, side_doors ([gauche, droite] : la position z de chaque porte, ou null), lights,
## energy, light_color, ceiling (bool), buttresses (bool).
## Renvoie {door (devant la porte, dehors), inside (le milieu de la salle), top (haut des murs)}.
func hall70(xf: Transform3D, w: float, d: float, opts: Dictionary = {}) -> Dictionary:
	var h: float = float(opts.get("h", 6.5))
	var t: float = float(opts.get("t", 0.7))
	var wall: String = str(opts.get("wall", "pgoth70"))
	var inner: String = str(opts.get("inner", "pgoth70_clair"))
	var floor_k: String = str(opts.get("floor_key", "paves70"))
	var dw: float = float(opts.get("door_w", 2.4))
	var dh: float = float(opts.get("door_h", 3.2))
	var dx: float = float(opts.get("door_x", 0.0))
	var trim: String = str(opts.get("trim", "pgoth70_sombre"))
	# le sol, sa collision
	box(xf * T(0, 0.05, -d * 0.5), Vector3(w - t, 0.1, d - t), floor_k, 2.0, 4)
	box(xf * T(0, -0.35, -d * 0.5), Vector3(w + 0.2, 0.7, d + 0.2), "basalte70", 2.0, 63 - 4)
	col_box(xf * T(0, -0.2, -d * 0.5), Vector3(w, 0.5, d))
	# les quatre murs, percés de leurs portes
	var walls := [
		[Transform3D(Basis(), Vector3(0, 0, -t * 0.5)), w, [[dx, dw, dh]]],
		[Transform3D(Basis(Vector3.UP, PI), Vector3(0, 0, -d + t * 0.5)), w, [[0.0, dw, dh]] if bool(opts.get("back_door", false)) else []],
	]
	var sd: Array = opts.get("side_doors", [null, null])
	for s in [-1.0, 1.0]:
		var zpos: Variant = sd[0] if s < 0 else sd[1]
		var gaps: Array = []
		if zpos != null:
			# la position le long du mur : x local du mur de côté = z de la salle
			gaps.append([(float(zpos) + d * 0.5) * (-s), 2.0, 3.0])
		walls.append([Transform3D(Basis(Vector3.UP, s * PI * 0.5), Vector3(s * (w * 0.5 - t * 0.5), 0, -d * 0.5)), d - t * 2.0, gaps])
	for wd in walls:
		var wx: Transform3D = xf * (wd[0] as Transform3D)
		var len: float = float(wd[1])
		var cur: float = -len * 0.5
		var gaps2: Array = (wd[2] as Array).duplicate()
		gaps2.sort_custom(func(p, q): return float(p[0]) < float(q[0]))
		for g in gaps2:
			var g0: float = float(g[0]) - float(g[1]) * 0.5
			var g1: float = float(g[0]) + float(g[1]) * 0.5
			_wall_piece(wx, cur, g0, 0.0, h, t, wall, inner)
			_wall_piece(wx, g0, g1, float(g[2]), h, t, wall, inner)
			cur = g1
		_wall_piece(wx, cur, len * 0.5, 0.0, h, t, wall, inner)
	# la porte : l'arc brisé, son tympan, ses vantaux ouverts
	var fx: Transform3D = xf * T(dx, 0, 0.0)
	var arch_h: float = dw * 0.866
	ogive_frame(fx, dw + 0.3, dh + arch_h, 0.4, 0.4, trim, 5)
	for s2 in [-1.0, 1.0]:
		box(fx * Transform3D(Basis(Vector3.UP, s2 * 1.35), Vector3(s2 * (dw * 0.5 - 0.05), dh * 0.5, -t - 0.55)), Vector3(dw * 0.5, dh, 0.08), "boisb70", 1.0)
	box(fx * T(0, 0.08, 0.5), Vector3(dw + 1.2, 0.16, 1.0), trim, 1.0, 63 - 8)
	# les fenêtres : dehors des baies allumées, dedans des vitraux
	if bool(opts.get("windows", true)):
		var nwin: int = maxi(1, int((d - 3.0) / 3.6))
		for s3 in [-1.0, 1.0]:
			for k in range(nwin):
				var wz: float = -d * 0.5 + (float(k) - (nwin - 1) * 0.5) * (d - 3.0) / nwin
				var skip: bool = false
				if sd[0 if s3 < 0 else 1] != null and absf(float(sd[0 if s3 < 0 else 1]) - wz) < 2.4:
					skip = true
				if skip:
					continue
				var oxf: Transform3D = xf * Transform3D(Basis(Vector3.UP, s3 * PI * 0.5), Vector3(s3 * w * 0.5, h * 0.3, wz))
				gothic_window(oxf, 1.1, minf(h * 0.55, 3.6), true, wall, true)
				var ixf: Transform3D = xf * Transform3D(Basis(Vector3.UP, -s3 * PI * 0.5), Vector3(s3 * (w * 0.5 - t - 0.01), h * 0.3, wz))
				ogive_face(ixf, 1.1, minf(h * 0.55, 3.6), "vitrailin70_lancette", 4, Rect2(0.13, 0.06, 0.74, 0.92))
		if bool(opts.get("buttresses", true)):
			for s4 in [-1.0, 1.0]:
				for k2 in range(nwin + 1):
					var bz: float = -d * 0.5 + (float(k2) - nwin * 0.5) * (d - 3.0) / nwin
					buttress(xf * Transform3D(Basis(Vector3.UP, s4 * PI * 0.5), Vector3(s4 * w * 0.5, 0, bz)), h, 1.3, 0.8, wall)
	# le plafond à poutres, le toit
	if bool(opts.get("ceiling", true)):
		box(xf * T(0, h - 0.1, -d * 0.5), Vector3(w - t, 0.2, d - t), inner, 2.4, 8)
		for k3 in range(int((d - 1.0) / 2.2)):
			box(xf * T(0, h - 0.4, -1.2 - k3 * 2.2), Vector3(w - t * 2.0, 0.4, 0.3), "boisb70", 1.5, 63 - 4)
	box(xf * T(0, h + 0.1, -d * 0.5), Vector3(w + 0.4, 0.3, d + 0.4), trim, 1.6)
	var roof: String = str(opts.get("roof", "ardoise70"))
	if roof != "":
		roof_gable(xf * Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(0, h + 0.25, -d * 0.5)), d, w, float(opts.get("pitch", 52.0)), 0.4, roof, wall)
	# les lustres
	var nl: int = int(opts.get("lights", 2))
	for k4 in range(nl):
		var lz: float = -d * (0.5 if nl == 1 else (0.25 + 0.5 * float(k4) / float(nl - 1)))
		var lp: Vector3 = xf * Vector3(0, h - 1.6, lz)
		chandelier(lp, h - 1.6, opts.get("light_color", Color(1.0, 0.66, 0.36)), float(opts.get("energy", 1.6)), maxf(w, d) * 0.7)
	return {"door": xf * Vector3(dx, 0, 1.4), "inside": xf * Vector3(0, 0, -d * 0.5), "top": h}


## Un pan de mur (pour hall70) : dans le repère du mur (x le long du mur, +Z dehors), de a à b,
## de y0 à h ; le dehors en « wall », le dedans en « inner ».
func _wall_piece(wx: Transform3D, a: float, b: float, y0: float, h: float, t: float, wall: String, inner: String) -> void:
	if b - a < 0.02 or h - y0 < 0.02:
		return
	var c := Vector3((a + b) * 0.5, (y0 + h) * 0.5, 0.0)
	box(wx * Transform3D(Basis(), c), Vector3(b - a, h - y0, t), wall, 2.6, 63 - 32 - (8 if y0 < 0.01 else 0))
	box(wx * Transform3D(Basis(), c + Vector3(0, 0, -t * 0.5 - 0.003)), Vector3(b - a, h - y0, 0.0), inner, 2.6, 32)
	col_box(wx * Transform3D(Basis(), c), Vector3(b - a, h - y0, t))


## Un lustre de fer (une couronne de bougies) pendu à sa chaîne, et sa lumière.
func chandelier(p: Vector3, chain: float, c: Color, energy: float, rng_m: float) -> OmniLight3D:
	cyl(Transform3D(Basis(), p), 0.015, 0.015, minf(chain, 1.6), "fer70", 4, false)
	ring(Transform3D(Basis(), p), 0.7, 0.78, 0.06, "fer70", 16)
	for k in range(8):
		var a: float = TAU * k / 8.0
		var q: Vector3 = p + Vector3(cos(a) * 0.74, 0.06, sin(a) * 0.74)
		cyl(Transform3D(Basis(), q), 0.025, 0.025, 0.14, "corne70", 6)
		cyl(Transform3D(Basis(), q + Vector3.UP * 0.14), 0.012, 0.0, 0.07, "lueur70_feu", 4)
		beam(q, p + Vector3.UP * 0.6, 0.012, "fer70")
	var l := OmniLight3D.new()
	l.light_color = c
	l.light_energy = energy
	l.omni_range = rng_m
	l.omni_attenuation = 1.15
	l.shadow_enabled = pc
	l.distance_fade_enabled = true
	l.distance_fade_begin = 45.0
	l.distance_fade_length = 12.0
	l.distance_fade_shadow = 25.0
	root.add_child(l)
	l.position = p + Vector3.UP * 0.2
	return l


## Une lucarne à pignon sur un pan de toit (xf : le bas-milieu de sa façade, qui regarde +Z).
func dormer70(xf: Transform3D, w: float, h: float, roof: String, wall: String, trim: String, lit: bool) -> void:
	box(xf * T(0, h * 0.5, -0.6), Vector3(w + 0.3, h, 1.2), wall, 1.4, 63 - 8 - 4)
	gothic_window(xf * T(0, 0.2, 0.0), w * 0.6, h * 0.8, lit, trim, false)
	roof_gable(xf * Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(0, h, -0.6)), 1.3, w + 0.3, 55.0, 0.12, roof, wall)


# =================================================================== tours, flèches, remparts

## Une tour ronde. opts : wall, trim, roof ("cone", "spire", "flat"), roof_key, roof_h,
## windows (Array de hauteurs), nwin, lit, crown (mâchicoulis et créneaux), door_dir
## (Vector3 : la porte), collide, seg.
func tower70(c: Vector3, r: float, h: float, opts: Dictionary = {}) -> Vector3:
	var wall: String = str(opts.get("wall", "pgoth70"))
	var trim: String = str(opts.get("trim", "pgoth70_sombre"))
	var seg: int = int(opts.get("seg", 18))
	var roof_key: String = str(opts.get("roof_key", "ardoise70"))
	cyl(Transform3D(Basis(), c + Vector3.DOWN * 0.8), r + 0.35, r + 0.18, 1.4, "basalte70", seg, false, 2.0)
	cyl(Transform3D(Basis(), c), r, r, h, wall, seg, false, 3.0)
	var y: float = 5.0
	while y < h - 2.0:
		cyl(Transform3D(Basis(), c + Vector3.UP * y), r + 0.08, r + 0.08, 0.2, trim, seg, false, 2.0)
		y += 5.5
	var dd: Vector3 = opts.get("door_dir", Vector3.ZERO)
	var door_a: float = atan2(dd.z, dd.x) if dd.length() > 0.01 else 0.0
	if dd.length() > 0.01:
		gothic_door(face_out(c, r, door_a, 0.0), minf(1.5, r * 0.6), 2.9, "boisb70", trim)
	var nwin: int = int(opts.get("nwin", 4))
	var lit_k: float = float(opts.get("lit", 0.5))
	for lv in opts.get("windows", []):
		for k in range(nwin):
			var a: float = door_a + TAU * (k + 0.5) / nwin + float(lv) * 0.31
			gothic_window(face_out(c, r, a, float(lv)), minf(0.7, r * 0.3), 1.7, rng.randf() < lit_k, trim, r > 2.5)
	var top: float = h
	if bool(opts.get("crown", true)):
		# les mâchicoulis : des consoles, puis le parapet en surplomb et ses merlons
		for k2 in range(seg):
			var a2: float = TAU * (k2 + 0.5) / seg
			box(Transform3D(Basis(Vector3.UP, -a2), c + Vector3(cos(a2), 0, sin(a2)) * (r + 0.22) + Vector3.UP * (h - 0.45)), Vector3(0.44, 0.7, 0.26), trim, 1.0)
		ring(Transform3D(Basis(), c + Vector3.UP * (h - 0.05)), r - 0.2, r + 0.5, 1.0, wall, seg)
		disc(Transform3D(Basis(), c + Vector3.UP * (h + 0.9)), r - 0.15, "pgoth70_sombre", seg, 2.0)
		for k3 in range(seg):
			if k3 % 2 == 0:
				var a3: float = TAU * k3 / seg
				box(Transform3D(Basis(Vector3.UP, -a3), c + Vector3(cos(a3), 0, sin(a3)) * (r + 0.3) + Vector3.UP * (h + 1.4)), Vector3(0.4, 1.0, r * TAU / seg * 0.9), wall, 1.4)
		top = h + 0.95
	var roof_h: float = float(opts.get("roof_h", r * 2.6))
	match str(opts.get("roof", "cone")):
		"cone":
			var rr: float = r + (0.1 if bool(opts.get("crown", true)) else 0.45)
			var base_y: float = top + (0.9 if bool(opts.get("crown", true)) else 0.0)
			cyl(Transform3D(Basis(), c + Vector3.UP * base_y), rr, 0.0, roof_h, roof_key, seg, false, 2.0)
			cyl(Transform3D(Basis(), c + Vector3.UP * (base_y - 0.02)), rr, rr, 0.02, trim, seg, true)
			_finial(c + Vector3.UP * (base_y + roof_h - 0.15), 1.0)
		"spire":
			spire70(c + Vector3.UP * top, r * 0.92, roof_h, roof_key)
	if bool(opts.get("collide", true)):
		col_cyl(c + Vector3.DOWN * 0.8, r + 0.1, h + 0.8)
	return c + Vector3.UP * top


## Une tourelle en encorbellement à l'angle d'une maison (xf : son axe, au haut de la console ;
## +Z : la rue) : la console de pierre, le fût, deux petites baies, le toit en poivrière.
func turret70(xf: Transform3D, r: float, h: float, roof_h: float, wall: String, roof: String, trim: String, lit: bool) -> void:
	cyl(xf * T(0, -1.2, 0), 0.22, r + 0.06, 1.2, trim, 12, true, 1.0)
	cyl(xf, r, r, h, wall, 12, false, 2.0)
	cyl(xf * T(0, h - 0.22, 0), r + 0.08, r + 0.08, 0.22, trim, 12, false, 1.0)
	for a in [PI * 0.5, PI * 0.5 + 1.2, PI * 0.5 - 1.2]:
		var out := Vector3(cos(a), 0, sin(a))
		var wxf: Transform3D = xf * Transform3D(Basis.looking_at(-out, Vector3.UP), out * r + Vector3.UP * h * 0.35)
		gothic_window(wxf, 0.5, minf(1.4, h * 0.35), lit and a == PI * 0.5, trim, false)
	cyl(xf * T(0, h, 0), r + 0.28, 0.0, roof_h, roof, 12, false, 1.6)
	cyl(xf * T(0, h - 0.02, 0), r + 0.28, r + 0.28, 0.02, trim, 12, true)
	cyl(xf * T(0, h + roof_h - 0.15, 0), 0.05, 0.0, 1.0, "fer70", 6)
	ball(xf * T(0, h + roof_h + 0.15, 0), 0.08, "or70", 6, 3)


## Une flèche octogonale (et quatre petites lucarnes à sa base), un épi d'or au sommet.
func spire70(c: Vector3, r: float, h: float, key: String = "ardoise70", lucarnes: bool = true) -> void:
	cyl(Transform3D(Basis(Vector3.UP, PI / 8.0), c), r, 0.0, h, key, 8, false, 2.2)
	cyl(Transform3D(Basis(Vector3.UP, PI / 8.0), c + Vector3.DOWN * 0.02), r, r, 0.02, "pgoth70_sombre", 8, true)
	if lucarnes and r > 1.2:
		for k in range(4):
			var a: float = TAU * k / 4.0
			var out := Vector3(cos(a), 0, sin(a))
			var p: Vector3 = c + out * r * 0.55 + Vector3.UP * (h * 0.12)
			var xf := Transform3D(Basis.looking_at(-out, Vector3.UP), p)
			box(xf * T(0, 0.55, -0.4), Vector3(0.7, 1.1, 0.8), key, 1.0, 63 - 8 - 32)
			roof_gable(xf * Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(0, 1.1, -0.4)), 0.9, 0.7, 58.0, 0.08, key, key)
			ogive_face(xf * T(0, 0.15, 0.01), 0.36, 0.8, "fenetrenoire70", 3)
	_finial(c + Vector3.UP * (h - 0.2), maxf(1.0, r * 0.45))


## L'épi de faîtage : une boule et une pointe d'or, deux petites cornes (le blason de la ville).
func _finial(p: Vector3, s: float) -> void:
	cyl(Transform3D(Basis(), p), 0.06 * s, 0.05 * s, 1.0 * s, "fer70", 6)
	ball(Transform3D(Basis(), p + Vector3.UP * 0.75 * s), 0.16 * s, "or70", 8, 4)
	cyl(Transform3D(Basis(), p + Vector3.UP * 0.85 * s), 0.05 * s, 0.0, 0.9 * s, "or70", 6)
	for sd in [-1.0, 1.0]:
		horn(p + Vector3(sd * 0.1 * s, 0.75 * s, 0), Vector3(sd, 0.5, 0).normalized(), 0.45 * s, 0.06 * s, 1.2, "or70", 4)


## Un pinacle (sur un contrefort, un angle de toit) : un petit fût et sa pointe.
func pinnacle(p: Vector3, s: float = 1.0, key: String = "pgoth70") -> void:
	box(Transform3D(Basis(), p + Vector3.UP * 0.8 * s), Vector3(0.55 * s, 1.6 * s, 0.55 * s), key, 1.0, 63 - 8)
	cyl(Transform3D(Basis(Vector3.UP, PI / 4.0), p + Vector3.UP * 1.6 * s), 0.42 * s, 0.0, 1.6 * s, key, 4, false, 1.0)
	cyl(Transform3D(Basis(), p + Vector3.UP * 3.1 * s), 0.03 * s, 0.0, 0.4 * s, "or70", 4)


## Un contrefort à ressauts contre un mur (xf : au pied du mur, regardant dehors ; h : la hauteur).
func buttress(xf: Transform3D, h: float, depth: float = 1.6, w: float = 0.9, key: String = "pgoth70", pin: bool = true) -> void:
	var parts := [[0.0, 0.45, 1.0], [0.45, 0.3, 0.72], [0.75, 0.25, 0.46]]
	for p in parts:
		var y0: float = float(p[0]) * h
		var hh: float = float(p[1]) * h
		var dd: float = float(p[2]) * depth
		box(xf * T(0, y0 + hh * 0.5, dd * 0.5), Vector3(w, hh, dd), key, 2.0, 63 - 32)
		# le larmier : un glacis incliné en haut de chaque ressaut
		box(xf * Transform3D(Basis(Vector3.RIGHT, -0.6), Vector3(0, y0 + hh, dd * 0.6)), Vector3(w + 0.06, 0.16, dd * 0.75), key, 1.0)
	col_box(xf * T(0, h * 0.25, depth * 0.5), Vector3(w, h * 0.5, depth))
	if pin:
		pinnacle(xf * Vector3(0, h, depth * 0.23), 0.8, key)


## Des créneaux de a à b (au sommet d'un mur, côté extérieur ; y : le haut du mur).
func crenels(a: Vector3, b: Vector3, t: float, key: String, mh: float = 0.95, step: float = 1.3) -> void:
	var d: Vector3 = b - a
	var len: float = Vector2(d.x, d.z).length()
	var yaw: float = atan2(d.x, d.z)
	var n: int = maxi(int(len / step), 1)
	for i in range(n):
		var p: Vector3 = a.lerp(b, (i + 0.5) / n)
		place("merlon|" + key, Transform3D(Basis(Vector3.UP, yaw) * Basis.from_scale(Vector3(t, mh, len / n * 0.55)), p))


## Un pan de mur droit de a à b (a et b : au pied), épais de t, haut de h ; ses créneaux (côté
## « out » : +1 à droite de a→b, -1 à gauche), sa collision.
func wall_line(a: Vector3, b: Vector3, h: float, t: float, key: String, crenel: bool = true, out: float = 1.0, cap_key: String = "pgoth70_sombre") -> void:
	var d: Vector3 = b - a
	var len: float = Vector2(d.x, d.z).length()
	var yaw: float = atan2(d.x, d.z)
	var bs := Basis(Vector3.UP, yaw)
	var mid: Vector3 = (a + b) * 0.5
	var y0: float = minf(a.y, b.y)
	box(Transform3D(bs, Vector3(mid.x, y0 + h * 0.5 - 0.6, mid.z)), Vector3(t, h + 1.2, len + 0.05), key, 2.6, 63 - 8)
	col_box(Transform3D(bs, Vector3(mid.x, y0 + h * 0.5, mid.z)), Vector3(t, h, len))
	box(Transform3D(bs, Vector3(mid.x, y0 + h - 0.08, mid.z)), Vector3(t + 0.24, 0.18, len + 0.06), cap_key, 1.4)
	if crenel:
		var side: Vector3 = bs * Vector3(out * (t * 0.5 - 0.22), 0, 0)
		crenels(Vector3(a.x, y0 + h, a.z) + side, Vector3(b.x, y0 + h, b.z) + side, 0.44, key)
		col_box(Transform3D(bs, Vector3(mid.x, y0 + h + 0.5, mid.z) + side), Vector3(0.44, 1.0, len))


## Un morceau d'anneau épais (des gradins, un mur rond) : centre c (au sol), rayons, hauteur, de
## l'angle a0 à a1 (radians, sens de x vers z) ; faces : 1 dessus, 2 dehors, 4 dedans, 8 bouts.
func arc_ring(c: Vector3, r_in: float, r_out: float, h: float, a0: float, a1: float, key: String, seg: int, collide: bool = true, faces: int = 15, tile: float = 2.0) -> void:
	var up := Vector3.UP
	for i in range(seg):
		var t0: float = lerpf(a0, a1, float(i) / seg)
		var t1: float = lerpf(a0, a1, float(i + 1) / seg)
		var d0 := Vector3(cos(t0), 0, sin(t0))
		var d1 := Vector3(cos(t1), 0, sin(t1))
		var u0: float = t0 * r_out / tile
		var u1: float = t1 * r_out / tile
		if faces & 1:
			quad4(key, c + d0 * r_in + up * h, c + d1 * r_in + up * h, c + d1 * r_out + up * h, c + d0 * r_out + up * h, up, Vector2(u0, 0), Vector2(u1, 0), Vector2(u1, (r_out - r_in) / tile), Vector2(u0, (r_out - r_in) / tile))
		var nm: Vector3 = ((d0 + d1) * 0.5).normalized()
		if faces & 2:
			quad4(key, c + d0 * r_out, c + d1 * r_out, c + d1 * r_out + up * h, c + d0 * r_out + up * h, nm, Vector2(u0, h / tile), Vector2(u1, h / tile), Vector2(u1, 0), Vector2(u0, 0))
		if faces & 4:
			quad4(key, c + d0 * r_in, c + d1 * r_in, c + d1 * r_in + up * h, c + d0 * r_in + up * h, -nm, Vector2(u0, h / tile), Vector2(u1, h / tile), Vector2(u1, 0), Vector2(u0, 0))
		if collide:
			var tm: float = (t0 + t1) * 0.5
			var chord: float = 2.0 * r_out * sin((t1 - t0) * 0.5) + 0.06
			col_box(Transform3D(Basis(Vector3.UP, -tm), c + Vector3(cos(tm), 0, sin(tm)) * (r_in + r_out) * 0.5 + up * h * 0.5), Vector3(r_out - r_in, h, chord))
	if faces & 8:
		for t in [a0, a1]:
			var d := Vector3(cos(t), 0, sin(t))
			var side := Vector3(-sin(t), 0, cos(t)) * (-1.0 if t == a0 else 1.0)
			quad4(key, c + d * r_in, c + d * r_out, c + d * r_out + up * h, c + d * r_in + up * h, side, Vector2(0, h / tile), Vector2((r_out - r_in) / tile, h / tile), Vector2((r_out - r_in) / tile, 0), Vector2(0, 0))


## Un parapet bas (a, b : au sol), sa tablette, sa collision.
func parapet70(a: Vector3, b: Vector3, h: float = 1.0, t: float = 0.5, key: String = "pgoth70", cap_key: String = "pgoth70_sombre") -> void:
	var d: Vector3 = b - a
	var len: float = Vector2(d.x, d.z).length()
	if len < 0.05:
		return
	var bs := Basis(Vector3.UP, atan2(d.x, d.z))
	var mid: Vector3 = (a + b) * 0.5
	box(Transform3D(bs, mid + Vector3.UP * (h * 0.5 - 0.15)), Vector3(t, h + 0.3, len + 0.02), key, 1.6, 63 - 8)
	box(Transform3D(bs, mid + Vector3.UP * (h + 0.06)), Vector3(t + 0.16, 0.14, len + 0.06), cap_key, 1.2, 63 - 8)
	col_box(Transform3D(bs, mid + Vector3.UP * (h * 0.5 + 0.1)), Vector3(t, h + 0.2, len))


## Une grille de fer forgé (a, b : au sol) : des barreaux à pointes de lance.
func railing70(a: Vector3, b: Vector3, h: float = 1.1) -> void:
	var d: Vector3 = b - a
	var len: float = Vector2(d.x, d.z).length()
	if len < 0.05:
		return
	var bs := Basis(Vector3.UP, atan2(d.x, d.z))
	var mid: Vector3 = (a + b) * 0.5
	for y in [0.12, h - 0.1]:
		box(Transform3D(bs, mid + Vector3.UP * y), Vector3(0.05, 0.05, len), "fer70", 1.0)
	var n: int = maxi(int(len / 0.22), 1)
	for i in range(n + 1):
		var p: Vector3 = a.lerp(b, float(i) / n)
		var big: bool = i % 8 == 0
		place("barreau", Transform3D(bs * Basis.from_scale(Vector3(2.4 if big else 1.0, h, 2.4 if big else 1.0)), p))
	col_box(Transform3D(bs, mid + Vector3.UP * h * 0.5), Vector3(0.12, h, len))


## Un pont de pierre de a à b (les deux bouts du tablier, à sa hauteur) : le tablier, ses
## parapets, deux piles qui plongent jusqu'à « foot », l'arche brisée sous le tablier.
func bridge70(a: Vector3, b: Vector3, w: float, foot: float, key: String = "pgoth70", deck_key: String = "paves70") -> void:
	var d: Vector3 = b - a
	var len: float = Vector2(d.x, d.z).length()
	var yaw: float = atan2(d.x, d.z)
	var bs := Basis(Vector3.UP, yaw)
	var mid: Vector3 = (a + b) * 0.5
	var y: float = a.y
	box(Transform3D(bs, Vector3(mid.x, y - 0.6, mid.z)), Vector3(w + 0.6, 1.2, len), key, 2.0, 63 - 4)
	box(Transform3D(bs, Vector3(mid.x, y - 0.03, mid.z)), Vector3(w, 0.06, len), deck_key, 2.0, 4)
	col_box(Transform3D(bs, Vector3(mid.x, y - 0.6, mid.z)), Vector3(w + 0.6, 1.2, len))
	for s in [-1.0, 1.0]:
		var off: Vector3 = bs * Vector3(s * (w * 0.5 + 0.1), 0, 0)
		parapet70(a + off, b + off, 1.0, 0.45, key)
	# les piles et l'arche (vue des deux côtés du pont)
	var span: float = len * 0.62
	var drop: float = y - 1.2 - foot
	for s2 in [-1.0, 1.0]:
		var pp: Vector3 = mid + bs * Vector3(0, 0, s2 * (span * 0.5 + (len - span) * 0.25))
		box(Transform3D(bs, Vector3(pp.x, foot + drop * 0.5, pp.z)), Vector3(w + 0.6, drop, (len - span) * 0.5), key, 2.0, 63 - 4 - 8)
	if drop > 2.0:
		var axf := Transform3D(bs * Basis(Vector3.UP, PI * 0.5), Vector3(mid.x, foot, mid.z))
		ogive_frame(axf, span, minf(drop + 0.6, span * 0.9), 0.9, w + 0.6, key, 5, true)


## Une porte de ville en arc brisé dans l'épaisseur d'un mur (xf : au sol, au milieu du passage,
## qui regarde +Z) : les deux piédroits, l'arc, le mur au-dessus jusqu'à « top » ; une herse levée.
func arch_gate(xf: Transform3D, span: float, h: float, depth: float, top: float, key: String = "pgoth70") -> void:
	for s in [-1.0, 1.0]:
		box(xf * T(s * (span * 0.5 + 0.9), top * 0.5, 0), Vector3(1.8, top, depth), key, 2.2, 63 - 8)
		col_box(xf * T(s * (span * 0.5 + 0.9), top * 0.5, 0), Vector3(1.8, top, depth))
	ogive_frame(xf * T(0, 0, -depth * 0.5), span, h, 0.8, depth, "pgoth70_sombre", 5, true)
	box(xf * T(0, h + (top - h) * 0.5 + 0.3, 0), Vector3(span + 0.2, top - h - 0.6, depth), key, 2.2)
	col_box(xf * T(0, h + (top - h) * 0.5 + 0.3, 0), Vector3(span, top - h - 0.6, depth))
	# la herse, levée (on ne voit que ses dents sous l'arc)
	for i in range(int(span / 0.5)):
		var x: float = -span * 0.5 + 0.25 + i * 0.5
		box(xf * T(x, h - 0.5, 0), Vector3(0.08, 1.0, 0.08), "fer70", 1.0)
		cyl(Transform3D(Basis(Vector3.RIGHT, PI), xf * Vector3(x, h - 1.0, 0)), 0.05, 0.0, 0.25, "fer70", 4, false)
	box(xf * T(0, h - 0.2, 0), Vector3(span, 0.08, 0.08), "fer70", 1.0)


# =================================================================== réverbères, lanternes

## Un réverbère de fer forgé (une ou deux lanternes) ; sa lumière s'allume avec la nuit.
func lamp70(pos: Vector3, h: float = 3.9, with_light: bool = true, double: bool = false, yaw: float = 0.0) -> void:
	var xf := Transform3D(Basis(Vector3.UP, yaw), pos)
	place("reverbere", xf * Transform3D(Basis.from_scale(Vector3(1.0, h / 3.9, 1.0)), Vector3.ZERO))
	col_cyl(pos, 0.18, h)
	var heads: Array = [Vector3(0, h + 0.05, 0)]
	if double:
		heads = [Vector3(-0.62, h - 0.2, 0), Vector3(0.62, h - 0.2, 0)]
		for s in [-1.0, 1.0]:
			beam(xf * Vector3(0, h - 0.5, 0), xf * Vector3(s * 0.62, h - 0.05, 0), 0.04, "fer70")
	var light_here: bool = with_light and (lamps70.size() % maxi(light_every, 1) == 0)
	for hp in heads:
		place("lanterne", Transform3D(Basis(), xf * (hp as Vector3)))
	if with_light:
		var c: Vector3 = xf * (heads[0] as Vector3) + Vector3.UP * 0.25
		if double:
			c = xf * Vector3(0, h, 0)
		_lamp_light(c, 1.5 if double else 1.15, 11.0 if double else 9.5, light_here)


## Le fût d'un réverbère (le prototype, sans sa lanterne).
func _lamp_geo(h: float) -> void:
	var xf := Transform3D.IDENTITY
	cyl(xf, 0.22, 0.16, 0.45, "fer70", 8)
	cyl(xf * T(0, 0.45, 0), 0.08, 0.055, h - 0.45, "fer70", 8, false)
	for y in [1.2, h - 0.5]:
		cyl(xf * T(0, y, 0), 0.1, 0.1, 0.08, "fer70", 8)
	for k in range(4):
		var a: float = TAU * k / 4.0
		horn(Vector3(cos(a) * 0.1, h - 0.45, sin(a) * 0.1), Vector3(cos(a), 0.6, sin(a)).normalized(), 0.28, 0.025, 2.2, "fer70", 3)


## Une lanterne contre un mur (xf : le point d'accroche, la potence avance vers +Z).
func wall_lamp70(xf: Transform3D, with_light: bool = true) -> void:
	box(xf * T(0, 0, 0.0), Vector3(0.16, 0.3, 0.04), "fer70", 1.0)
	beam(xf * Vector3(0, -0.12, 0.02), xf * Vector3(0, 0.12, 0.5), 0.035, "fer70")
	box(xf * T(0, 0.12, 0.27), Vector3(0.04, 0.04, 0.5), "fer70", 1.0)
	place("lanterne", Transform3D(Basis.from_scale(Vector3.ONE * 0.85), xf * Vector3(0, -0.35, 0.5)))
	if with_light:
		_lamp_light(xf * Vector3(0, -0.15, 0.55), 0.9, 7.5, lamps70.size() % maxi(light_every, 1) == 0)


## La cage d'une lanterne (p : le bas de la cage) — le prototype des lanternes.
func _lantern_geo(p: Vector3, s: float) -> void:
	var xf := Transform3D(Basis(), p)
	cyl(xf, 0.12 * s, 0.17 * s, 0.06 * s, "fer70", 6)
	cyl(xf * T(0, 0.06 * s, 0), 0.15 * s, 0.15 * s, 0.4 * s, "verre70", 6, false)
	for k in range(6):
		var a: float = TAU * k / 6.0
		box(xf * T(cos(a) * 0.155 * s, 0.26 * s, sin(a) * 0.155 * s), Vector3(0.025 * s, 0.42 * s, 0.025 * s), "fer70", 1.0, 1 | 2 | 16 | 32)
	cyl(xf * T(0, 0.46 * s, 0), 0.2 * s, 0.03 * s, 0.22 * s, "fer70", 6)
	cyl(xf * T(0, 0.66 * s, 0), 0.025 * s, 0.0, 0.2 * s, "fer70", 4)


func _lamp_light(at: Vector3, energy: float, rng_m: float, real: bool) -> void:
	if not real or lamps70.size() >= lights70_budget:
		lamps70.append(null)
		return
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.6, 0.3)
	l.light_energy = energy
	l.omni_range = rng_m
	l.omni_attenuation = 1.35
	l.shadow_enabled = false
	l.light_volumetric_fog_energy = 0.5
	l.distance_fade_enabled = true
	l.distance_fade_begin = 70.0
	l.distance_fade_length = 20.0
	l.light_specular = 0.6
	root.add_child(l)
	l.position = at
	if temps != null and temps.has_method("register_lamp"):
		temps.register_lamp(l, energy)
	lamps70.append(l)


## Une des sept Grandes Lanternes de la Nuit des Lanternes : un socle octogonal, une colonne de
## fer, une grande cage de verre (éteinte tant qu'on ne l'a pas allumée). Renvoie {glass, light,
## flame (le point du feu), pos}.
func great_lantern(pos: Vector3, yaw: float = 0.0) -> Dictionary:
	var xf := Transform3D(Basis(Vector3.UP, yaw), pos)
	cyl(Transform3D(Basis(Vector3.UP, PI / 8.0), pos), 1.25, 1.15, 0.35, "pgoth70_sombre", 8)
	cyl(Transform3D(Basis(Vector3.UP, PI / 8.0), pos + Vector3.UP * 0.35), 0.95, 0.8, 0.9, "pgoth70", 8)
	cyl(Transform3D(Basis(Vector3.UP, PI / 8.0), pos + Vector3.UP * 1.25), 0.95, 0.95, 0.14, "pgoth70_sombre", 8)
	col_cyl(pos, 1.2, 1.4)
	cyl(xf * T(0, 1.39, 0), 0.32, 0.2, 0.5, "fer70", 10)
	cyl(xf * T(0, 1.89, 0), 0.16, 0.12, 3.9, "fer70", 10, false)
	col_cyl(pos + Vector3.UP * 1.4, 0.25, 4.0)
	for y in [2.6, 3.6, 4.6]:
		ring(xf * T(0, y, 0), 0.12, 0.22, 0.1, "or70", 12)
	# quatre consoles de fer qui portent la cage
	for k in range(4):
		var a: float = TAU * k / 4.0 + PI / 4.0
		var o := Vector3(cos(a), 0, sin(a))
		beam(xf * Vector3(0, 4.9, 0), xf * (o * 0.7 + Vector3.UP * 5.75), 0.07, "fer70")
		horn(xf * (o * 0.18 + Vector3.UP * 4.4), (o + Vector3.UP * 0.3).normalized(), 0.6, 0.06, 1.5, "fer70", 4)
	var cage := Transform3D(Basis(Vector3.UP, yaw + PI / 8.0), pos + Vector3.UP * 5.8)
	cyl(cage, 0.95, 0.95, 0.16, "fer70", 8)
	for k2 in range(8):
		var a2: float = TAU * k2 / 8.0 + PI / 8.0
		beam(cage * Vector3(cos(a2) * 0.86, 0.1, sin(a2) * 0.86), cage * Vector3(cos(a2) * 0.86, 1.9, sin(a2) * 0.86), 0.06, "fer70")
	cyl(cage * T(0, 1.9, 0), 1.08, 0.12, 1.0, "fer70", 8)
	cyl(cage * T(0, 2.85, 0), 0.06, 0.0, 0.7, "or70", 6)
	ball(cage * T(0, 2.95, 0), 0.16, "or70", 8, 4)
	var glass := MeshInstance3D.new()
	glass.name = "Grande_lanterne_verre"
	var gm := CylinderMesh.new()
	gm.top_radius = 0.8
	gm.bottom_radius = 0.8
	gm.height = 1.72
	gm.radial_segments = 8
	gm.rings = 1
	glass.mesh = gm
	glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(glass)
	glass.transform = cage * T(0, 1.0, 0)
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.62, 0.3)
	light.light_energy = 0.0
	light.omni_range = 24.0
	light.omni_attenuation = 1.2
	light.shadow_enabled = false
	light.light_volumetric_fog_energy = 1.2
	root.add_child(light)
	light.position = cage * Vector3(0, 1.0, 0)
	return {"glass": glass, "light": light, "flame": cage * Vector3(0, 0.55, 0), "pos": pos}


# =================================================================== statues, gargouilles

## Une boule (une sphère à facettes) : xf au centre.
func ball(xf: Transform3D, r: float, key: String, seg: int = 10, rings: int = 5) -> void:
	for i in range(rings):
		var a0: float = -PI * 0.5 + PI * i / rings
		var a1: float = -PI * 0.5 + PI * (i + 1) / rings
		cyl(xf * T(0, sin(a0) * r, 0), cos(a0) * r, cos(a1) * r, (sin(a1) - sin(a0)) * r, key, seg, false, 1.0)


## Une corne qui s'enroule : de « base » vers « dir », longueur len, rayon r à la base ; curl :
## combien elle se recourbe (radians sur toute la longueur, vers le haut puis vers l'arrière).
func horn(base: Vector3, dir: Vector3, len: float, r: float, curl: float, key: String, n: int = 5) -> void:
	var d: Vector3 = dir.normalized()
	var side: Vector3 = d.cross(Vector3.UP)
	if side.length() < 0.01:
		side = Vector3.RIGHT
	side = side.normalized()
	var p: Vector3 = base
	for i in range(n):
		var t0: float = float(i) / n
		var step: float = len / n
		var dd: Vector3 = d.rotated(side, -curl * (t0 + 0.5 / n))
		var q: Vector3 = p + dd * step
		cyl(axis_xf(p, q), r * (1.0 - t0 * 0.9), r * (1.0 - (t0 + 1.0 / n) * 0.9) + 0.004, step + 0.01, key, 6, false, 0.6)
		p = q


## Une statue de démon sur son socle (xf : au sol, la statue regarde +Z) : une grande robe,
## les ailes ouvertes, des cornes de bélier, une torche levée (un feu, voir fires70). s : l'échelle
## (s = 1 : une statue de 3 m).
func demon_statue(xf: Transform3D, s: float = 1.0, key: String = "bronze70", base_key: String = "pgoth70") -> void:
	box(xf * T(0, 0.15 * s, 0), Vector3(2.2 * s, 0.3 * s, 2.2 * s), "pgoth70_sombre", 1.2)
	box(xf * T(0, 1.0 * s, 0), Vector3(1.6 * s, 1.4 * s, 1.6 * s), base_key, 1.2)
	box(xf * T(0, 1.78 * s, 0), Vector3(1.85 * s, 0.18 * s, 1.85 * s), "pgoth70_sombre", 1.2)
	col_box(xf * T(0, 0.95 * s, 0), Vector3(2.2 * s, 1.9 * s, 2.2 * s))
	var b: Transform3D = xf * T(0, 1.87 * s, 0)
	# la robe, le buste
	cyl(b, 0.62 * s, 0.34 * s, 1.55 * s, key, 12, true, 1.0)
	cyl(b * T(0, 1.55 * s, 0), 0.34 * s, 0.42 * s, 0.6 * s, key, 12, true, 1.0)
	cyl(Transform3D(b.basis * Basis(Vector3.BACK, PI * 0.5), b * Vector3(0.55 * s, 2.08 * s, 0)), 0.17 * s, 0.17 * s, 1.1 * s, key, 8, true, 1.0)
	# la tête, les cornes de bélier
	cyl(b * T(0, 2.15 * s, 0), 0.1 * s, 0.1 * s, 0.14 * s, key, 8, false)
	ball(b * T(0, 2.42 * s, 0.03 * s), 0.2 * s, key, 10, 5)
	for sd in [-1.0, 1.0]:
		horn(b * Vector3(sd * 0.13 * s, 2.55 * s, 0), b.basis * Vector3(sd * 0.7, 0.7, -0.2), 0.62 * s, 0.07 * s, 2.6, key, 6)
	# les ailes : trois baleines et la membrane tendue entre elles
	for sd2 in [-1.0, 1.0]:
		var sh: Vector3 = b * Vector3(sd2 * 0.32 * s, 1.95 * s, -0.25 * s)
		var tips: Array = [b * Vector3(sd2 * 1.9 * s, 3.1 * s, -0.7 * s), b * Vector3(sd2 * 2.2 * s, 2.0 * s, -0.75 * s), b * Vector3(sd2 * 1.5 * s, 0.9 * s, -0.6 * s)]
		var elbow: Vector3 = b * Vector3(sd2 * 1.05 * s, 2.75 * s, -0.5 * s)
		beam(sh, elbow, 0.08 * s, key)
		for tp in tips:
			beam(elbow, tp, 0.05 * s, key)
		var nrm: Vector3 = (b.basis * Vector3(0, 0, -1)).normalized()
		for i in range(tips.size() - 1):
			tri(key, elbow, tips[i], tips[i + 1], nrm, Vector2(0, 0), Vector2(1, 0), Vector2(1, 1))
			tri(key, elbow, tips[i], tips[i + 1], -nrm, Vector2(0, 0), Vector2(1, 0), Vector2(1, 1))
		tri(key, sh, elbow, tips[2], nrm, Vector2(0, 0), Vector2(1, 0), Vector2(1, 1))
		tri(key, sh, elbow, tips[2], -nrm, Vector2(0, 0), Vector2(1, 0), Vector2(1, 1))
	# le bras levé et sa torche
	var hand: Vector3 = b * Vector3(0.62 * s, 3.05 * s, 0.25 * s)
	beam(b * Vector3(0.5 * s, 2.05 * s, 0), b * Vector3(0.66 * s, 2.6 * s, 0.15 * s), 0.13 * s, key)
	beam(b * Vector3(0.66 * s, 2.6 * s, 0.15 * s), hand, 0.11 * s, key)
	cyl(Transform3D(Basis(), hand + Vector3.DOWN * 0.15 * s), 0.05 * s, 0.07 * s, 0.4 * s, key, 6)
	cyl(Transform3D(Basis(), hand + Vector3.UP * 0.25 * s), 0.08 * s, 0.17 * s, 0.18 * s, "or70", 8)
	fires70.append([hand + Vector3.UP * 0.5 * s, 0.45 * s])
	# l'autre main sur un livre (le Grand Contrat)
	beam(b * Vector3(-0.5 * s, 2.05 * s, 0), b * Vector3(-0.45 * s, 1.5 * s, 0.35 * s), 0.12 * s, key)
	box(Transform3D(b.basis * Basis(Vector3.RIGHT, -0.5), b * Vector3(-0.4 * s, 1.45 * s, 0.45 * s)), Vector3(0.42 * s, 0.08 * s, 0.32 * s), key, 1.0)
	# la queue qui s'enroule au pied
	var prev: Vector3 = b * Vector3(0, 0.25 * s, -0.5 * s)
	for k in range(7):
		var a: float = PI * 0.5 + k * 0.5
		var q: Vector3 = b * Vector3(cos(a) * (0.75 + k * 0.03) * s, 0.12 * s, sin(a) * (0.75 + k * 0.03) * s - 0.1 * s)
		cyl(axis_xf(prev, q), 0.07 * s * (1.0 - k * 0.1), 0.065 * s * (1.0 - k * 0.1), prev.distance_to(q) + 0.02, key, 6, false)
		prev = q
	tri(key, prev + Vector3.UP * 0.02, prev + (b.basis * Vector3(0.25, 0.02, 0.1)) * s, prev + (b.basis * Vector3(0.1, 0.02, 0.3)) * s, Vector3.UP, Vector2(0, 0), Vector2(1, 0), Vector2(0, 1))


## Une gargouille accroupie au bord d'une corniche (xf : sur le bord, elle regarde +Z, penchée
## vers la rue), la gueule ouverte.
func gargoyle(xf: Transform3D, s: float = 1.0, key: String = "pgoth70") -> void:
	var g: Transform3D = xf * Transform3D(Basis(Vector3.RIGHT, 0.35), Vector3.ZERO)
	cyl(Transform3D(g.basis * Basis(Vector3.RIGHT, PI * 0.5), g * Vector3(0, 0.3 * s, -0.4 * s)), 0.26 * s, 0.2 * s, 0.75 * s, key, 8, true, 1.0)
	ball(g * T(0, 0.42 * s, 0.45 * s), 0.2 * s, key, 8, 4)
	box(g * T(0, 0.32 * s, 0.68 * s), Vector3(0.22 * s, 0.07 * s, 0.3 * s), key, 1.0)
	box(Transform3D(g.basis * Basis(Vector3.RIGHT, 0.45), g * Vector3(0, 0.46 * s, 0.68 * s)), Vector3(0.24 * s, 0.07 * s, 0.3 * s), key, 1.0)
	for sd in [-1.0, 1.0]:
		horn(g * Vector3(sd * 0.1 * s, 0.58 * s, 0.4 * s), g.basis * Vector3(sd * 0.5, 0.8, -0.4), 0.32 * s, 0.05 * s, 1.8, key, 4)
		beam(g * Vector3(sd * 0.16 * s, 0.25 * s, 0.25 * s), g * Vector3(sd * 0.2 * s, -0.05 * s, 0.4 * s), 0.08 * s, key)
		beam(g * Vector3(sd * 0.2 * s, 0.25 * s, -0.55 * s), g * Vector3(sd * 0.24 * s, -0.05 * s, -0.4 * s), 0.1 * s, key)
		var w0: Vector3 = g * Vector3(sd * 0.2 * s, 0.5 * s, -0.2 * s)
		var w1: Vector3 = g * Vector3(sd * 0.55 * s, 0.95 * s, -0.55 * s)
		var w2: Vector3 = g * Vector3(sd * 0.3 * s, 0.3 * s, -0.85 * s)
		var nn: Vector3 = ((w1 - w0).cross(w2 - w0)).normalized()
		tri(key, w0, w1, w2, nn, Vector2(0, 0), Vector2(1, 0), Vector2(0, 1))
		tri(key, w0, w1, w2, -nn, Vector2(0, 0), Vector2(1, 0), Vector2(0, 1))


## Une fontaine de feu (la Grand-Place) : une vasque de marbre noir pleine de lave, une colonne
## à deux coupes de bronze, un feu au sommet. xf : au sol, au centre.
func fire_fountain(xf: Transform3D, r: float = 3.2) -> Vector3:
	ring(xf, r - 0.45, r, 0.75, "mnoir70", 36)
	cyl(xf, r + 0.4, r + 0.3, 0.12, "pgoth70_sombre", 36, true, 2.0)
	disc(xf * T(0, 0.45, 0), r - 0.44, "lave70", 32, 1.0)
	col_cyl(xf.origin, r, 0.75)
	cyl(Transform3D(Basis(Vector3.UP, PI / 8.0), xf.origin), 0.75, 0.6, 1.3, "mnoir70", 8)
	cyl(xf * T(0, 1.3, 0), 0.4, 1.35, 0.4, "bronze70", 16)
	disc(xf * T(0, 1.66, 0), 1.25, "lave70", 16, 1.0)
	cyl(xf * T(0, 1.7, 0), 0.3, 0.24, 1.2, "bronze70", 12)
	cyl(xf * T(0, 2.9, 0), 0.22, 0.75, 0.3, "bronze70", 12)
	disc(xf * T(0, 3.17, 0), 0.68, "lave70", 12, 1.0)
	col_cyl(xf.origin, 0.8, 3.2)
	# quatre têtes de démon de bronze sur le bord de la coupe
	for k in range(4):
		var a: float = TAU * k / 4.0
		var o := Vector3(cos(a), 0, sin(a))
		ball(xf * Transform3D(Basis(), o * 1.3 + Vector3.UP * 1.72), 0.16, "bronze70", 8, 4)
		for sd in [-1.0, 1.0]:
			horn(xf * (o * 1.3 + Vector3.UP * 1.82) + (o.cross(Vector3.UP) * sd * 0.1), (o.cross(Vector3.UP) * sd + Vector3.UP).normalized(), 0.25, 0.04, 2.0, "bronze70", 4)
	var top: Vector3 = xf * Vector3(0, 3.35, 0)
	fires70.append([top, 0.7])
	return top


## Un brasero de bronze sur pied (le feu est allumé par l'île : fires70). Renvoie le point du feu.
func brazier70(pos: Vector3, h: float = 1.1, key: String = "bronze70", foot: String = "pgoth70_sombre", size: float = 0.5) -> Vector3:
	cyl(Transform3D(Basis(Vector3.UP, PI / 8.0), pos), 0.34, 0.26, 0.2, foot, 8)
	cyl(Transform3D(Basis(), pos + Vector3.UP * 0.2), 0.12, 0.09, h - 0.45, foot, 8)
	cyl(Transform3D(Basis(), pos + Vector3.UP * (h - 0.25)), 0.18, 0.46, 0.3, key, 14)
	ring(Transform3D(Basis(), pos + Vector3.UP * (h + 0.05)), 0.42, 0.5, 0.06, key, 16)
	disc(Transform3D(Basis(), pos + Vector3.UP * (h - 0.02)), 0.42, "braise70", 14, 1.0)
	col_cyl(pos, 0.4, h + 0.1)
	var f: Vector3 = pos + Vector3.UP * (h + 0.05)
	fires70.append([f, size])
	return f


## Un banc de fer et de bois brûlé (xf : au sol, on s'y assied face à +Z).
func bench70(xf: Transform3D) -> void:
	box(xf * T(0, 0.46, 0), Vector3(1.7, 0.07, 0.48), "boisb70", 0.8)
	box(xf * Transform3D(Basis(Vector3.RIGHT, -0.18), Vector3(0, 0.82, -0.24)), Vector3(1.7, 0.4, 0.05), "boisb70", 0.8)
	for sx in [-0.72, 0.72]:
		box(xf * T(sx, 0.23, 0), Vector3(0.06, 0.46, 0.44), "fer70", 1.0)
		box(xf * T(sx, 0.62, -0.22), Vector3(0.06, 0.8, 0.06), "fer70", 1.0)
		horn(xf * Vector3(sx, 0.5, 0.2), xf.basis * Vector3(0, 0.3, 1), 0.2, 0.03, 2.4, "fer70", 3)
	col_box(xf * T(0, 0.4, -0.05), Vector3(1.7, 0.8, 0.55))
