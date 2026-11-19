extends RefCounted
## V174 : on entre chez les Géants (l'Île des Géants, la ferme des Grandpré). À hauteur de Petit, tout
## est sept fois et demie plus grand :
##  - par la chatière, la salle commune de la maison des Grandpré : la table haute comme une maison et
##    l'escalier de livres pour y monter (le pain, le fromage et sa souris, les bols où l'on pourrait se
##    baigner), la grande cheminée et son chaudron, l'horloge comtoise dont le balancier bat lentement,
##    Pompon le chat qui dort sur le tapis tressé, l'écharpe sans fin de Grand-mère Ernestine qui passe
##    sous la porte, le vaisselier ; et dessous, chez Tante Brindille, une Petite qui habite là (son lit
##    est une boîte de sardines, sa table une tasse retournée) ;
##  - par un trou de souris, le Moulin de la Butte : la meule dans sa cuve, la trémie, le grand rouet qui
##    tourne sous le plafond, les sacs de farine hauts comme des maisons ; dans un coin, le fournil de
##    Pépin, le boulanger des Petits (son four est un pot de fleurs retourné).
## V177 : le donjon du château de sable de Pâquerette, sur la grève (à hauteur de Petit, cette fois :
## c'est un château pour nous) : des murs de sable mouillé modelés à la main, où Firmin, le gardien,
## met le coquillage que Pâquerette pose chaque matin devant la porte ; trois hublots de verre de mer ;
## un escalier taillé dans le mur jusqu'à la galerie et sa meurtrière (la mer) ; le lit d'algues et la
## chaussette de Pâquerette pour sac de couchage ; la table (un couvercle de confiture sur trois galets),
## le sablier des marées, l'ardoise ; la grande conque où l'on écoute la mer ; la cuillère avec laquelle
## Pâquerette a creusé le donjon ; les sept bougies de son anniversaire ; Sire Bernard, le
## bernard-l'ermite, qui rentre dans sa coquille quand on approche.
## Comme lieux_v171 à lieux_v173 (boutiques_v170 délègue ici les métiers qu'il ne connaît pas) ; en plus,
## la coque (le sol, les murs épais et leurs fenêtres, le plafond et ses solives) est faite ici, à
## l'échelle des géants (coque, appelée par boutiques_v170.shell).
## M : maisons_v81 ; R : la pièce ; B : les boutiques ; L3 : les aides de lieux_v173.

const B = preload("res://scripts/boutiques_v170.gd")
const L1 = preload("res://scripts/lieux_v171.gd")
const L3 = preload("res://scripts/lieux_v173.gd")
const Sud = preload("res://scripts/maisons_sud_v169.gd")
const Animaux = preload("res://scripts/animaux_v75.gd")
const Kit142 = preload("res://scripts/geants_kit_v142.gd")

const HISTOIRE := "b174"
const T := "beau174/"

const METIERS := {
	"maison_grandpre": [Vector2(76.0, 48.0), 20.0],
	"moulin_butte": [Vector2(23.4, 23.4), 22.0],
	"donjon_paquerette": [Vector2(8.2, 8.2), 10.2],
}

## Les pièces rondes (le moulin).
const RONDS := ["moulin_butte", "donjon_paquerette"]

## Les lieux où personne ne vit (on y entre seul).
const SEULS: Array = []

## id (celui de la ville) → [métier, la vraie personne, « E : entrer … », enseigne].
const VILLES := {
	"geants": {
		"maison": ["maison_grandpre", "", "dans la maison des Grandpré (par la chatière)", "Maison des Grandpré"],
		"moulin": ["moulin_butte", "", "dans le Moulin de la Butte (par le trou de souris)", "Moulin de la Butte"],
		"donjon": ["donjon_paquerette", "", "dans le donjon du château de sable", "Château des Petits"],
	},
}

## Des vues pour l'outil d'images (rendu_maisons.sh … boutiques geants) : [nom, d'où, vers où], en
## repère de la pièce.
const VUES := {
	"maison_grandpre": [
		["table", Vector3(-4.5, 7.5, -0.5), Vector3(8.0, 6.2, -3.0)],
		["livres", Vector3(-3.0, 1.7, 9.5), Vector3(-7.6, 3.0, -1.5)],
		["entree", Vector3(0.0, 1.65, 21.6), Vector3(3.0, 5.0, -10.0)],
		["cheminee", Vector3(-19.0, 2.4, -15.0), Vector3(-37.0, 5.0, -12.0)],
		["brindille", Vector3(2.0, 1.6, -15.5), Vector3(0.0, 1.0, -22.5)],
		["horloge", Vector3(28.0, 1.7, -4.0), Vector3(37.0, 9.0, -12.0)],
		["vaisselier", Vector3(4.0, 1.7, -8.0), Vector3(0.0, 9.0, -24.0)],
	],
	"moulin_butte": [
		["meule", Vector3(4.0, 1.7, 6.0), Vector3(0.0, 6.0, -3.2)],
		["rouet", Vector3(-2.0, 1.6, 7.0), Vector3(0.0, 15.0, 0.0)],
		["pepin", Vector3(-2.5, 1.6, 9.0), Vector3(-6.5, 0.8, 4.6)],
		["sacs", Vector3(2.0, 1.7, 2.0), Vector3(8.0, 3.0, -6.0)],
	],
	"donjon_paquerette": [
		["entree", Vector3(0.0, 1.65, 3.0), Vector3(0.0, 1.4, -3.0)],
		["escalier", Vector3(-1.6, 1.6, 1.2), Vector3(2.6, 2.4, -1.2)],
		["firmin", Vector3(0.4, 1.6, 0.6), Vector3(-0.6, 1.0, -1.9)],
		["lit", Vector3(-0.4, 1.5, 0.9), Vector3(-3.0, 0.5, -0.5)],
		["conque", Vector3(0.6, 1.3, 0.2), Vector3(0.8, 0.3, -3.0)],
		["galerie", Vector3(-2.2, 5.8, -2.2), Vector3(0.6, 2.0, 0.6)],
		["meurtriere", Vector3(0.0, 5.8, 2.4), Vector3(0.0, 5.75, 4.4)],
	],
}


static func porte_ville(style: String, id: String, door: Vector3, out: Vector3) -> bool:
	var v: Dictionary = VILLES.get(style, {})
	if not v.has(id):
		return false
	var e: Array = v[id]
	return B.porte(door, out, style, str(e[0]), str(e[1]), str(e[2]), str(e[3]), HISTOIRE)


static func has_metier(met: String) -> bool:
	return METIERS.has(met)


static func _pal(_st: String, met: String) -> Dictionary:
	if met == "donjon_paquerette":
		# V177 : tout en sable : le sol tassé (plus clair), les murs mouillés, le bas plus sombre
		return {"sol": ["montjoie/sable_lac.png", Color(1.04, 0.98, 0.86), 2.4], "mur": ["montjoie/sable_lac.png", Color(0.9, 0.84, 0.72), 2.6],
			"bas": ["montjoie/sable_lac.png", Color(0.7, 0.64, 0.54), 2.6], "plafond": ["montjoie/sable_lac.png", Color(0.92, 0.87, 0.76), 2.6],
			"fenetre": "aucune", "sans_poutres": true, "sans_lampe": true}
	if met == "moulin_butte":
		return {"sol": ["montjoie/bois_planches.png", Color(0.9, 0.84, 0.74), 12.0], "mur": ["montjoie/enduit.png", Color(1.0, 0.99, 0.96), 14.0],
			"bas": ["montjoie/moellons.png", Color(0.82, 0.79, 0.74), 9.0], "plafond": ["montjoie/bois_planches.png", Color(0.62, 0.5, 0.4), 12.0],
			"fenetre": "aucune", "sans_poutres": true, "sans_lampe": true}
	return {"sol": ["maisons/tomettes.png", Color(0.95, 0.86, 0.8), 5.0], "mur": ["montjoie/enduit.png", Color(0.99, 0.96, 0.9), 16.0],
		"bas": ["montjoie/moellons.png", Color(0.8, 0.76, 0.7), 9.0], "plafond": ["montjoie/bois_planches.png", Color(0.56, 0.44, 0.34), 12.0],
		"fenetre": "aucune", "sans_poutres": true, "sans_lampe": true}


static func build(M) -> void:
	match str(M.cur.get("metier", "")):
		"maison_grandpre":
			_maison_grandpre(M)
		"moulin_butte":
			_moulin_butte(M)
		"donjon_paquerette":
			_donjon_paquerette(M)


# =================================================================== la coque, à l'échelle des géants

## La coque d'un lieu de géants (à la place de R.shell) : vrai si ce module l'a faite.
static func coque(M) -> bool:
	var met: String = str(M.cur.get("metier", ""))
	if not METIERS.has(met):
		return false
	if met == "moulin_butte":
		_coque_moulin(M)
	elif met == "donjon_paquerette":
		_coque_donjon(M)
	else:
		_coque_maison(M)
	return true


## Le sol et le plafond (et leurs collisions).
static func _sol_plafond(M) -> void:
	var R = M.R
	var k = R.kit
	var ts: float = float((R.pal["sol"] as Array)[2])
	var tp: float = float((R.pal["plafond"] as Array)[2])
	k.box(R.L(0, -0.1, 0), Vector3(R.W, 0.2, R.D), "sol", ts, 4)
	k.col_box(R.L(0, -0.5, 0), Vector3(R.W + 4.0, 1.0, R.D + 4.0))
	k.box(R.L(0, R.H + 0.2, 0), Vector3(R.W, 0.4, R.D), "plafond", tp, 8)
	k.col_box(R.L(0, R.H + 1.0, 0), Vector3(R.W + 4.0, 1.0, R.D + 4.0))


## Un quadrilatère (en repère xf), sa normale (repère xf) ; la texture posée en mètres (tile) selon
## les deux axes (ua, va) du plan.
static func _q4(R, key: String, xf: Transform3D, a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3, ua: Vector3, va: Vector3, tile: float) -> void:
	var nw: Vector3 = (xf.basis * n).normalized()
	R.kit.quad4(key, xf * a, xf * b, xf * c, xf * d, nw,
		Vector2(a.dot(ua), -a.dot(va)) / tile, Vector2(b.dot(ua), -b.dot(va)) / tile, Vector2(c.dot(ua), -c.dot(va)) / tile, Vector2(d.dot(ua), -d.dot(va)) / tile)


## Un pan de mur (xf : le pied du mur, +Z vers la pièce) : de (x0, y0) à (x1, y1).
static func _pan(R, key: String, xf: Transform3D, x0: float, x1: float, y0: float, y1: float, tile: float) -> void:
	if x1 - x0 < 0.01 or y1 - y0 < 0.01:
		return
	_q4(R, key, xf, Vector3(x0, y0, 0), Vector3(x1, y0, 0), Vector3(x1, y1, 0), Vector3(x0, y1, 0), Vector3(0, 0, 1), Vector3.RIGHT, Vector3.UP, tile)


## [[y0, y1]…] moins [a, b].
static func _sans(parts: Array, a: float, b: float) -> Array:
	var out: Array = []
	for p in parts:
		var p0: float = p[0]
		var p1: float = p[1]
		if b <= p0 or a >= p1:
			out.append([p0, p1])
			continue
		if a > p0:
			out.append([p0, a])
		if b < p1:
			out.append([b, p1])
	return out


## Un mur droit de la pièce (xf : le pied du mur, au milieu, +Z vers la pièce ; sa longueur) ; ses
## ouvertures [cx, largeur, y0, hauteur, profondeur, sorte] (repère du mur ; sorte : « fenetre » ou
## « foyer ») : l'enduit autour (la texture continue d'un pan à l'autre), l'ébrasement ; la plinthe de
## chêne (sauf aux trous « plinthe_sans » : [[x0, x1]…]) ; la collision derrière.
static func _mur(M, xf: Transform3D, longueur: float, ouv: Array, plinthe_sans: Array = []) -> void:
	var R = M.R
	var k = R.kit
	var H: float = R.H
	var tm: float = float((R.pal["mur"] as Array)[2])
	var hl: float = longueur * 0.5
	var xs: Array = [-hl, hl]
	for o in ouv:
		xs.append(float(o[0]) - float(o[1]) * 0.5)
		xs.append(float(o[0]) + float(o[1]) * 0.5)
	xs.sort()
	for i in range(xs.size() - 1):
		var a: float = xs[i]
		var b: float = xs[i + 1]
		if b - a < 0.01:
			continue
		var mid: float = (a + b) * 0.5
		var parts: Array = [[0.0, H]]
		for o in ouv:
			if absf(mid - float(o[0])) < float(o[1]) * 0.5:
				parts = _sans(parts, float(o[2]), float(o[2]) + float(o[3]))
		for yp in parts:
			_pan(R, "mur", xf, a, b, float(yp[0]), float(yp[1]), tm)
	for o2 in ouv:
		_ebrasement(M, xf, o2)
	# la plinthe de chêne
	var bords: Array = [[-hl, hl]]
	for ps in plinthe_sans:
		var nb: Array = []
		for bd in bords:
			for q in _sans([bd], float(ps[0]), float(ps[1])):
				nb.append(q)
		bords = nb
	for o3 in ouv:
		if float(o3[2]) < 0.5:
			var nb2: Array = []
			for bd2 in bords:
				for q2 in _sans([bd2], float(o3[0]) - float(o3[1]) * 0.5 - 1.8, float(o3[0]) + float(o3[1]) * 0.5 + 1.8):
					nb2.append(q2)
			bords = nb2
	var chene: String = _chene(R, true)
	for bd3 in bords:
		var l: float = float(bd3[1]) - float(bd3[0])
		if l > 0.2:
			k.box(xf * B.T3((float(bd3[0]) + float(bd3[1])) * 0.5, 0.55, 0.14), Vector3(l, 1.1, 0.28), chene, 6.0)
	k.col_box(xf * B.T3(0, H * 0.5, -1.0), Vector3(longueur + 4.0, H + 2.0, 2.0))


## Derrière un mur (le côté du soleil) : un écran qui ne fait que de l'ombre, troué aux fenêtres (le mur
## de la pièce n'a qu'une face : sans lui, le soleil passerait à travers) ; le soleil dessine alors les
## fenêtres et leurs croisées sur le carrelage.
static func _ecran_ombre(M, xf: Transform3D, longueur: float, ouv: Array) -> void:
	var R = M.R
	var hl: float = longueur * 0.5
	var xs: Array = [-hl, hl]
	for o in ouv:
		xs.append(float(o[0]) - float(o[1]) * 0.5)
		xs.append(float(o[0]) + float(o[1]) * 0.5)
	xs.sort()
	for i in range(xs.size() - 1):
		var a: float = xs[i]
		var b: float = xs[i + 1]
		if b - a < 0.01:
			continue
		var parts: Array = [[0.0, R.H + 1.0]]
		for o2 in ouv:
			if absf((a + b) * 0.5 - float(o2[0])) < float(o2[1]) * 0.5:
				parts = _sans(parts, float(o2[2]), float(o2[2]) + float(o2[3]))
		for yp in parts:
			var mi := MeshInstance3D.new()
			mi.mesh = B._boitem(b - a, float(yp[1]) - float(yp[0]), 0.4)
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
			M.room.add_child(mi)
			mi.global_transform = xf * B.T3((a + b) * 0.5, (float(yp[0]) + float(yp[1])) * 0.5, -3.6)


## L'ébrasement d'une ouverture : les tableaux (côtés), l'appui, le linteau ; la fenêtre au fond (ou le
## contrecœur noirci de suie, pour un foyer).
static func _ebrasement(M, xf: Transform3D, o: Array) -> void:
	var R = M.R
	var cx: float = o[0]
	var w: float = o[1]
	var y0: float = o[2]
	var h: float = o[3]
	var e: float = o[4]
	var sorte: String = str(o[5]) if o.size() > 5 else "fenetre"
	var x0: float = cx - w * 0.5
	var x1: float = cx + w * 0.5
	var y1: float = y0 + h
	var tm: float = float((R.pal["mur"] as Array)[2])
	var key: String = "mur"
	if sorte == "foyer":
		key = B._tex(R, "suie174", "montjoie/moellons.png", Color(0.2, 0.17, 0.15), 0.95)
		tm = 6.0
	_q4(R, key, xf, Vector3(x0, y0, 0), Vector3(x0, y0, -e), Vector3(x0, y1, -e), Vector3(x0, y1, 0), Vector3(1, 0, 0), Vector3(0, 0, -1), Vector3.UP, tm)
	_q4(R, key, xf, Vector3(x1, y0, -e), Vector3(x1, y0, 0), Vector3(x1, y1, 0), Vector3(x1, y1, -e), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3.UP, tm)
	_q4(R, key, xf, Vector3(x0, y1, 0), Vector3(x1, y1, 0), Vector3(x1, y1, -e), Vector3(x0, y1, -e), Vector3(0, -1, 0), Vector3.RIGHT, Vector3(0, 0, 1), tm)
	if sorte == "foyer":
		_q4(R, key, xf, Vector3(x0, y0, -e), Vector3(x1, y0, -e), Vector3(x1, y1, -e), Vector3(x0, y1, -e), Vector3(0, 0, 1), Vector3.RIGHT, Vector3.UP, tm)
		R.kit.box(xf * B.T3(cx, 0.05, -e * 0.5), Vector3(w, 0.1, e), key, 4.0, 4)
		return
	_q4(R, key, xf, Vector3(x0, y0, -e), Vector3(x1, y0, -e), Vector3(x1, y0, 0), Vector3(x0, y0, 0), Vector3(0, 1, 0), Vector3.RIGHT, Vector3(0, 0, -1), tm)
	_fenetre(M, xf, cx, y0, w, h, e, str(o[6]) if o.size() > 6 else "", o.size() > 7 and bool(o[7]))


## Une grande fenêtre de géant, au fond de son ébrasement (xf : le mur) : la vue (le jour, la nuit),
## le dormant et la croisée peints en blanc, les petits bois (les petits carreaux), l'espagnolette,
## l'appui de chêne, les rideaux de vichy rouge.
static func _fenetre(M, xf: Transform3D, cx: float, y0: float, w: float, h: float, e: float, vue: String, rai: bool) -> void:
	var R = M.R
	var k = R.kit
	var blanc: String = B._tex(R, "blanc174", "beau161/bois_peint.png", Color(0.97, 0.96, 0.92), 0.6)
	var zg: float = -e + 0.35
	# la vue
	var mi := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(w, h)
	mi.mesh = qm
	var vm := StandardMaterial3D.new()
	vm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var chemin: String = "res://assets/textures/" + T + vue + ("_jour.png" if R.day else "_nuit.png")
	if vue != "" and ResourceLoader.exists(chemin):
		vm.albedo_texture = load(chemin)
	else:
		vm.albedo_color = Color(0.72, 0.84, 0.95) if R.day else Color(0.03, 0.04, 0.09)
	mi.material_override = vm
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	M.room.add_child(mi)
	mi.global_transform = xf * B.T3(cx, y0 + h * 0.5, zg - 0.05)
	# un reflet léger sur le verre (des carreaux un peu bleutés)
	k.box(xf * B.T3(cx, y0 + h * 0.5, zg), Vector3(w, h, 0.02), B._verre(R, "carreau174", Color(0.82, 0.9, 0.96), 0.12), 1.0, 16)
	# le dormant
	for s in [-1.0, 1.0]:
		k.box(xf * B.T3(cx + s * (w * 0.5 - 0.25), y0 + h * 0.5, zg + 0.2), Vector3(0.5, h, 0.5), blanc, 3.0)
	k.box(xf * B.T3(cx, y0 + h - 0.25, zg + 0.2), Vector3(w, 0.5, 0.5), blanc, 3.0)
	k.box(xf * B.T3(cx, y0 + 0.25, zg + 0.2), Vector3(w, 0.5, 0.5), blanc, 3.0)
	# la croisée : le meneau, la traverse
	var yt: float = y0 + h * 0.66
	k.box(xf * B.T3(cx, y0 + h * 0.5, zg + 0.22), Vector3(0.45, h, 0.45), blanc, 3.0)
	k.box(xf * B.T3(cx, yt, zg + 0.22), Vector3(w, 0.42, 0.45), blanc, 3.0)
	# les petits bois : trois carreaux de large par battant, quatre de haut en bas, deux en haut
	for s2 in [-1.0, 1.0]:
		var bx: float = cx + s2 * w * 0.25
		var bw: float = w * 0.5 - 0.5
		for c in [-1.0, 1.0]:
			k.box(xf * B.T3(bx + c * bw / 6.0, y0 + h * 0.5, zg + 0.12), Vector3(0.13, h - 0.6, 0.16), blanc, 3.0)
		for r in range(1, 4):
			k.box(xf * B.T3(bx, y0 + 0.5 + (yt - y0 - 0.7) * r / 4.0, zg + 0.12), Vector3(bw, 0.13, 0.16), blanc, 3.0)
		k.box(xf * B.T3(bx, yt + (y0 + h - yt) * 0.5, zg + 0.12), Vector3(bw, 0.13, 0.16), blanc, 3.0)
	# l'espagnolette (la tige de fer, la poignée)
	k.cyl(xf * B.T3(cx + 0.32, y0 + 0.6, zg + 0.5), 0.07, 0.07, h - 1.2, "fer", 6)
	k.box(xf * Transform3D(Basis(Vector3.BACK, 0.3), Vector3(cx + 0.36, y0 + h * 0.45, zg + 0.62)), Vector3(0.14, 1.1, 0.14), "fer", 1.0)
	# l'appui de chêne (il déborde dans la pièce)
	k.box(xf * B.T3(cx, y0 - 0.15, -e * 0.5 + 0.35), Vector3(w + 1.4, 0.35, e + 0.7), _chene(R, false), 5.0)
	# les rideaux de vichy rouge, de part et d'autre (des plis), et leur tringle
	var vichy: String = B._tex(R, "vichy174", T + "vichy_rouge.png", Color(1, 1, 1), 0.92)
	var yb: float = y0 - 1.2
	var yh: float = y0 + h + 1.1
	k.cyl(xf * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(cx + w * 0.5 + 3.6, yh + 0.25, 0.75)), 0.13, 0.13, w + 7.2, "fer", 8)
	for s3 in [-1.0, 1.0]:
		for p in range(6):
			var px: float = cx + s3 * (w * 0.5 + 0.35 + p * 0.52)
			var pz: float = 0.75 + (0.18 if p % 2 == 0 else -0.05)
			k.box(xf * Transform3D(Basis(Vector3.UP, s3 * (0.35 if p % 2 == 0 else -0.35)), Vector3(px, (yb + yh) * 0.5, pz)), Vector3(0.62, yh - yb, 0.08), vichy, 0.9)
	# le jour, un rai de lumière (un cône très léger) et sa poussière, par les fenêtres du soleil
	if R.day and rai:
		var a: Vector3 = _loc(R, xf, Vector3(cx, y0 + h * 0.55, zg))
		var b: Vector3 = _loc(R, xf, Vector3(cx + w * 0.35, 0.0, zg + h * 1.35))
		L3._rai(M, a, b, w * 1.1)
		_poussiere_rai(M, a, b, w * 0.3, 90)


## Un point (repère xf) en repère de la pièce.
static func _loc(R, xf: Transform3D, p: Vector3) -> Vector3:
	return R.xf0.affine_inverse() * (xf * p)


## Le chêne des meubles des Grandpré (clair : la table, les chaises ; sombre : les plinthes, les pieds).
static func _chene(R, sombre: bool) -> String:
	if sombre:
		return B._tex(R, "chene174_s", "maisons/bois_meuble.png", Color(0.48, 0.34, 0.24), 0.7)
	return B._tex(R, "chene174", "maisons/bois_meuble.png", Color(0.86, 0.68, 0.5), 0.66)


## Une lumière (repère de la pièce) ; l'ombre seulement sur PC (et pas en VR).
static func _omni(M, p: Vector3, c: Color, e: float, portee: float, ombre: bool = false) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.light_color = c
	l.light_energy = e
	l.omni_range = portee
	l.omni_attenuation = 1.0
	l.light_specular = 0.25
	l.shadow_enabled = ombre and bool(M.R.pc) and not bool(M.main.get("xr_active"))
	M.room.add_child(l)
	l.global_position = M.R.P(p.x, p.y, p.z)
	(M.R.lights as Array).append(l)
	return l


## Un rayon de soleil qui entre par une fenêtre (de, vers : repère de la pièce) : une lumière en cône,
## et ses ombres (les croisées dessinées sur le sol).
static func _soleil(M, de: Vector3, vers: Vector3, angle: float, e: float) -> SpotLight3D:
	var s := SpotLight3D.new()
	s.light_color = Color(1.0, 0.92, 0.78)
	s.light_energy = e
	s.spot_range = de.distance_to(vers) * 1.25
	s.spot_angle = angle
	s.spot_attenuation = 0.5
	s.spot_angle_attenuation = 0.7
	s.light_specular = 0.3
	s.shadow_enabled = bool(M.R.pc) and not bool(M.main.get("xr_active"))
	M.room.add_child(s)
	var a: Vector3 = M.R.P(de.x, de.y, de.z)
	var b: Vector3 = M.R.P(vers.x, vers.y, vers.z)
	s.global_transform = Transform3D(Basis.looking_at(b - a, Vector3.UP), a)
	(M.R.lights as Array).append(s)
	return s


## La poussière qui danse dans un rayon de soleil (de a vers b, repère de la pièce).
static func _poussiere_rai(M, a: Vector3, b: Vector3, r: float, n: int) -> void:
	var p := CPUParticles3D.new()
	p.amount = n
	p.lifetime = 14.0
	p.preprocess = 14.0
	p.direction = Vector3.UP
	p.spread = 180.0
	p.initial_velocity_min = 0.02
	p.initial_velocity_max = 0.09
	p.gravity = Vector3(0, -0.01, 0)
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(r, r, a.distance_to(b) * 0.5)
	p.scale_amount_min = 0.4
	p.scale_amount_max = 1.0
	var q := QuadMesh.new()
	q.size = Vector2(0.09, 0.09)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.albedo_color = Color(1.0, 0.92, 0.75, 0.55)
	m.albedo_texture = M.R.dot_texture()
	q.material = m
	p.mesh = q
	M.room.add_child(p)
	var pa: Vector3 = M.R.P(a.x, a.y, a.z)
	var pb: Vector3 = M.R.P(b.x, b.y, b.z)
	p.global_transform = Transform3D(Basis.looking_at(pb - pa, Vector3.UP), (pa + pb) * 0.5)


## Un feu de géant (at : repère de la pièce ; s : sa taille) : les flammes, la lumière qui vacille.
static func _feu(M, at: Vector3, s: float, e: float, portee: float) -> void:
	var R = M.R
	var p := CPUParticles3D.new()
	p.amount = 44
	p.lifetime = 0.9
	p.direction = Vector3.UP
	p.spread = 10.0
	p.initial_velocity_min = 0.3 * s
	p.initial_velocity_max = 0.7 * s
	p.gravity = Vector3(0, 0.5 * s, 0)
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(0.55 * s, 0.1 * s, 0.18 * s)
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.25
	var curve := Curve.new()
	curve.add_point(Vector2(0, 0.6))
	curve.add_point(Vector2(0.3, 1.0))
	curve.add_point(Vector2(1, 0.0))
	p.scale_amount_curve = curve
	var grad := Gradient.new()
	grad.set_color(0, Color(1.0, 0.86, 0.42, 1.0))
	grad.set_color(1, Color(0.9, 0.24, 0.04, 0.0))
	p.color_ramp = grad
	var q := QuadMesh.new()
	q.size = Vector2(0.24, 0.34) * s
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = R.dot_texture()
	q.material = m
	p.mesh = q
	M.room.add_child(p)
	p.global_position = R.P(at.x, at.y, at.z)
	var l: OmniLight3D = _omni(M, at + Vector3(1.6, 1.4, 0), Color(1.0, 0.6, 0.3), e, portee, true)
	(R.flames as Array).append([l, e])


## De la vapeur (une marmite, une cheminée de pot de fleurs) : at en repère de la pièce.
static func _vapeur(M, at: Vector3, r: float, haut: float, c: Color, n: int = 16) -> void:
	var p := CPUParticles3D.new()
	p.amount = n
	p.lifetime = 4.0
	p.preprocess = 4.0
	p.direction = Vector3.UP
	p.spread = 14.0
	p.initial_velocity_min = haut * 0.18
	p.initial_velocity_max = haut * 0.3
	p.gravity = Vector3(0, 0.02, 0)
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = r
	var curve := Curve.new()
	curve.add_point(Vector2(0, 0.4))
	curve.add_point(Vector2(1, 1.6))
	p.scale_amount_curve = curve
	var grad := Gradient.new()
	grad.set_color(0, Color(c.r, c.g, c.b, 0.0))
	grad.add_point(0.25, Color(c.r, c.g, c.b, c.a))
	grad.set_color(grad.get_point_count() - 1, Color(c.r, c.g, c.b, 0.0))
	p.color_ramp = grad
	var q := QuadMesh.new()
	q.size = Vector2(r * 2.2, r * 2.2)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = M.R.dot_texture()
	q.material = m
	p.mesh = q
	M.room.add_child(p)
	p.global_position = M.R.P(at.x, at.y, at.z)


## Une boule (repère de la pièce), d'un matériau de la pièce.
static func _boule(M, key: String, p: Vector3, r: float, scl: Vector3 = Vector3.ONE) -> MeshInstance3D:
	return Sud._boule(M.room, M.R.mat(key), M.R.P(p.x, p.y, p.z), r, scl)


## Un objet qui s'anime (sa racine) : un nœud posé en repère de la pièce.
static func _noeud(M, nom: String, xf: Transform3D) -> Node3D:
	var n := Node3D.new()
	n.name = nom
	M.room.add_child(n)
	n.global_transform = xf
	return n


## Une pièce d'un nœud qui s'anime (repère du nœud).
static func _bout(n: Node3D, mesh: Mesh, m: Material, at: Vector3, basis: Basis = Basis()) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = m
	n.add_child(mi)
	mi.transform = Transform3D(basis, at)
	return mi


## Une bête de la pièce (Animaux) qui respire, remue la queue… (repère de la pièce) ; pose : « dort »,
## « assis », « content »…
static func _bete(M, espece: String, v: Dictionary, p: Vector3, yaw: float, pose: String) -> Node3D:
	var a: Node3D = Animaux.build(espece, v)
	M.room.add_child(a)
	a.global_transform = Transform3D(Basis(Vector3.UP, deg_to_rad(yaw)), M.R.P(p.x, p.y, p.z))
	if not M.ctx.has("betes174"):
		M.ctx["betes174"] = []
	(M.ctx["betes174"] as Array).append([a, pose])
	return a


## Ce qui bouge à chaque image (les bêtes, l'horloge ; le reste passe par anims170).
static func _tick(M, delta: float) -> void:
	var t: float = float(M.ctx.get("t170", 0.0))
	for e in M.ctx.get("betes174", []):
		if is_instance_valid(e[0]):
			Animaux.animate(e[0], t, 0.0, str(e[1]), 0.0, delta)
	var ag: Variant = M.ctx.get("aiguilles174", null)
	if ag is Array and (ag as Array).size() == 2 and is_instance_valid(ag[0]) and is_instance_valid(ag[1]):
		var tp: Node = M.main.get("temps_v56")
		var hr: float = float(tp.hour) if tp != null else float(M.ctx.get("hour", 12.0))
		(ag[0] as Node3D).rotation.z = -fposmod(hr, 12.0) / 12.0 * TAU
		(ag[1] as Node3D).rotation.z = -fposmod(hr, 1.0) * TAU


## Un livre couché (repère de la pièce : le centre du dessous ; taille : longueur (x), épaisseur, largeur
## (z) ; yaw en degrés) : les plats de toile, le bloc des pages, le dos ; et sa collision.
static func _livre(M, x: float, y: float, z: float, taille: Vector3, yaw: float, c: Color, titre: String = "") -> void:
	var R = M.R
	var k = R.kit
	var key: String = B._tex(R, "toile174_%s" % c.to_html(false), "beau161/toile_lin.png", c, 0.85)
	var pages: String = B._c(R, "pages174", Color(0.93, 0.89, 0.78), 0.9)
	var xf: Transform3D = R.L(x, y, z, yaw)
	var e: float = 0.07
	k.box(xf * B.T3(0, e * 0.5, 0), Vector3(taille.x, e, taille.z), key, 2.0)
	k.box(xf * B.T3(0, taille.y - e * 0.5, 0), Vector3(taille.x, e, taille.z), key, 2.0)
	k.box(xf * B.T3(0.06, taille.y * 0.5, 0), Vector3(taille.x - 0.2, taille.y - e * 2.0, taille.z - 0.12), pages, 1.0)
	k.box(xf * B.T3(-taille.x * 0.5 + e * 0.5, taille.y * 0.5, 0), Vector3(e, taille.y, taille.z), key, 2.0)
	k.col_box(xf * B.T3(0, taille.y * 0.5, 0), taille)
	if titre != "" and taille.y > 0.3:
		var lb: Label3D = B._ecrit(M, x, y + taille.y * 0.5, z, yaw - 90.0, titre, 64, Color(0.95, 0.85, 0.55), 0.0045, 0.0)
		lb.global_transform = xf * Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3(-taille.x * 0.5 - 0.01, taille.y * 0.5, 0))


# =================================================================== la maison des Grandpré : la coque

## La salle commune (76 × 48 m ; 20 m sous les solives) : les tomettes, les murs chaulés et leurs dix
## fenêtres (quatre devant, quatre au fond, une à chaque pignon), le foyer de la cheminée dans le
## pignon de gauche ; les solives et la poutre maîtresse ; la grande porte (et la chatière, par où l'on
## est entré) ; les lumières (le jour : les fenêtres, deux rayons de soleil par les fenêtres du sud ;
## la nuit : la lune, les braises).
static func _coque_maison(M) -> void:
	var R = M.R
	var k = R.kit
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	_sol_plafond(M)
	var poutre: String = B._tex(R, "poutre174", "montjoie/bois_planches.png", Color(0.5, 0.38, 0.28), 0.8)
	var n: int = 13
	for i in range(n + 1):
		var x: float = -hw + 2.4 + i * (R.W - 4.8) / n
		k.box(R.L(x, R.H - 0.95, 0), Vector3(1.3, 1.9, R.D), poutre, 8.0)
	k.box(R.L(0, R.H - 3.1, -2.0), Vector3(R.W, 2.4, 2.6), poutre, 9.0)
	for sx in [-1.0, 1.0]:
		k.box(R.L(sx * (hw - 1.2), R.H - 5.4, -2.0), Vector3(2.4, 2.6, 2.4), poutre, 6.0)
	# les murs : [cx, largeur, y0, hauteur, profondeur, sorte, vue, rayon de soleil]
	var fy: float = 6.8
	var fh: float = 10.5
	var devant: Array = []
	var fond: Array = []
	var i2: int = 0
	for fx in [-31.0, -16.0, 16.0, 31.0]:
		i2 += 1
		devant.append([fx, 8.0, fy, fh, 3.2, "fenetre", "vue_nord_%d" % i2, false])
		fond.append([-fx, 8.0, fy, fh, 3.2, "fenetre", "vue_sud_%d" % i2, absf(fx) < 20.0])
	_mur(M, R.L(0, 0, -hd, 0), R.W, fond, [[-6.4, 6.4]])
	_ecran_ombre(M, R.L(0, 0, -hd, 0), R.W, fond)
	_mur(M, R.L(0, 0, hd, 180), R.W, devant, [[-3.2, 6.4]])
	_mur(M, R.L(-hw, 0, 0, 90), R.D, [[-6.0, 8.0, fy, fh, 3.2, "fenetre", "vue_est", false], [12.0, 11.4, 0.0, 9.2, 3.4, "foyer"]])
	_mur(M, R.L(hw, 0, 0, -90), R.D, [[6.0, 8.0, fy, fh, 3.2, "fenetre", "vue_ouest", false]], [[-14.6, -9.4]])
	_porte_grandpre(M)
	# les lumières
	if R.day:
		_omni(M, Vector3(4.0, 14.0, -2.0), Color(1.0, 0.95, 0.88), 0.75, 52.0)
		for sx2 in [-1.0, 1.0]:
			_omni(M, Vector3(sx2 * 23.0, 12.0, 17.0), Color(0.88, 0.92, 1.0), 0.7, 28.0)
			_omni(M, Vector3(sx2 * 23.0, 12.0, -17.0), Color(1.0, 0.95, 0.86), 0.85, 28.0)
		for fx2 in [-16.0, 16.0]:
			_soleil(M, Vector3(fx2 - 6.0, 34.0, -hd - 20.0), Vector3(fx2 + 4.0, 0.0, -hd + 16.0), 15.0, 7.0)
	else:
		_omni(M, Vector3(4.0, 14.0, -2.0), Color(0.6, 0.66, 0.85), 0.16, 52.0)
		for sx3 in [-1.0, 1.0]:
			_omni(M, Vector3(sx3 * 23.0, 12.0, 17.0), Color(0.55, 0.62, 0.9), 0.22, 26.0)
			_omni(M, Vector3(sx3 * 23.0, 12.0, -17.0), Color(0.55, 0.62, 0.9), 0.18, 26.0)


## La grande porte verte, vue de dedans (sa barre en Z, ses pentures, le loquet, la grosse clé dans la
## serrure), et la chatière en bas, entrouverte, par où entre un peu du dehors ; la lumière sous la porte.
static func _porte_grandpre(M) -> void:
	var R = M.R
	var k = R.kit
	var hd: float = R.D * 0.5
	var dx: float = -1.6
	var vert: String = B._tex(R, "porte174", "beau161/bois_peint.png", Color(0.42, 0.66, 0.48), 0.7)
	var dz: float = hd - 0.45
	k.box(R.L(dx, 8.6, dz), Vector3(8.0, 17.2, 0.9), vert, 4.0, 47)
	# les planches (des joints sombres), les trois traverses et la barre en écharpe
	for j in range(1, 6):
		k.box(R.L(dx - 4.0 + j * 8.0 / 6.0, 8.6, dz - 0.46), Vector3(0.06, 17.2, 0.02), "noir", 1.0)
	for yb in [3.3, 8.8, 14.8]:
		k.box(R.L(dx, yb, dz - 0.62), Vector3(7.6, 1.0, 0.35), vert, 4.0)
	for seg in [[3.3, 8.8], [8.8, 14.8]]:
		var ya: float = seg[0]
		var yb2: float = seg[1]
		var ang: float = atan2(yb2 - ya, 6.6)
		k.box(R.L(dx, (ya + yb2) * 0.5, dz - 0.62) * Transform3D(Basis(Vector3.BACK, ang), Vector3.ZERO), Vector3(sqrt(6.6 * 6.6 + (yb2 - ya) * (yb2 - ya)), 0.9, 0.33), vert, 4.0)
	# les pentures (côté gonds : à droite vu de dedans) et les gonds
	for yp in [3.3, 14.8]:
		k.box(R.L(dx - 1.2, yp, dz - 0.82), Vector3(5.2, 0.42, 0.06), "fer", 1.0)
		k.cyl(R.L(dx - 4.1, yp - 0.6, dz - 0.5), 0.2, 0.2, 1.2, "fer", 8)
	# le loquet, sa poignée, la serrure et la grosse clé
	k.box(R.L(dx + 2.6, 8.4, dz - 0.82), Vector3(1.6, 0.28, 0.12), "fer", 1.0)
	k.box(R.L(dx + 3.3, 7.6, dz - 0.9), Vector3(0.22, 1.2, 0.22), "fer", 1.0)
	k.box(R.L(dx + 3.0, 6.4, dz - 0.6), Vector3(1.1, 1.5, 0.3), "fer", 1.0)
	var laiton: String = B._c(R, "laiton174", Color(0.8, 0.62, 0.3), 0.32, 0.85)
	k.cyl(R.L(dx + 3.0, 6.4, dz - 0.75) * Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), Vector3.ZERO), 0.08, 0.08, 1.0, laiton, 8)
	k.ring(R.L(dx + 3.0, 6.4, dz - 1.75) * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 0.25, 0.45, 0.08, laiton, 14)
	# le chambranle (le cadre de bois autour)
	var chene: String = _chene(R, true)
	for s in [-1.0, 1.0]:
		k.box(R.L(dx + s * 4.45, 8.9, hd - 0.2), Vector3(0.9, 17.8, 0.4), chene, 5.0)
	k.box(R.L(dx, 17.65, hd - 0.2), Vector3(9.8, 0.9, 0.4), chene, 5.0)
	# la chatière (en bas, à côté : x = 0), entrouverte ; derrière, un peu du dehors
	var dehors: String = B._c(R, "dehors174_j" if R.day else "dehors174_n", Color(1.0, 0.94, 0.8) if R.day else Color(0.1, 0.13, 0.25), 0.9, 0.0, 1.6 if R.day else 0.6)
	k.box(R.L(0.0, 1.25, dz - 0.47), Vector3(1.8, 1.7, 0.02), dehors, 1.0, 32)
	k.box(R.L(0.0, 2.15, dz - 0.6) * Transform3D(Basis(Vector3.RIGHT, 0.22), Vector3(0, -0.85, 0)), Vector3(1.8, 1.7, 0.12), B._tex(R, "chatiere174", "beau161/bois_peint.png", Color(0.86, 0.74, 0.56), 0.7), 1.0)
	k.box(R.L(0.0, 2.2, dz - 0.62), Vector3(2.1, 0.16, 0.2), "fer", 1.0)
	for s2 in [-1.0, 1.0]:
		k.box(R.L(s2 * 0.98, 1.25, dz - 0.5), Vector3(0.16, 1.9, 0.12), "fer", 1.0)
	# le jour qui passe sous la porte
	k.box(R.L(dx, 0.04, hd - 0.9), Vector3(8.0, 0.02, 0.4), dehors, 1.0, 4)
	# le seuil de chêne
	k.box(R.L(dx, 0.08, hd - 0.4), Vector3(9.6, 0.16, 1.0), chene, 4.0)


# =================================================================== la maison des Grandpré : dedans

static func _maison_grandpre(M) -> void:
	M.ctx["tick170"] = func(delta: float) -> void:
		_tick(M, delta)
	_cheminee(M)
	_pompon(M)
	_table(M)
	_escalier_livres(M)
	_sur_la_table(M)
	_vaisselier(M)
	_chez_brindille(M)
	_comtoise(M)
	_evier(M)
	_petrin(M)
	_cote_porte(M)
	_fauteuil_echarpe(M)
	_aux_murs(M)
	_au_plafond(M)
	_par_terre(M)
	_brindille(M)


## La cheminée, dans le pignon de gauche : les piédroits de pierre, le manteau de chêne et sa tablette,
## la hotte chaulée ; dans le foyer, les chenets, les bûches, les braises et le feu (la nuit, il couve),
## la crémaillère et le chaudron de soupe qui fume ; sur la tablette, les chandeliers, le moulin à café,
## la boîte à sel ; au-dessus, le tableau du Moulin de la Butte ; le soufflet, le panier à bûches.
static func _cheminee(M) -> void:
	var R = M.R
	var k = R.kit
	var x0: float = -R.W * 0.5
	var cz: float = -12.0
	var taille: String = B._tex(R, "taille174", "montjoie/pierre_rempart.png", Color(1.0, 0.96, 0.88), 0.88)
	var chene: String = _chene(R, true)
	for s in [-1.0, 1.0]:
		k.box(R.L(x0 + 1.5, 4.6, cz + s * 6.6), Vector3(3.0, 9.2, 1.8), taille, 4.0)
		k.col_box(R.L(x0 + 1.5, 4.6, cz + s * 6.6), Vector3(3.0, 9.2, 1.8))
		# la console sous le manteau
		k.box(R.L(x0 + 2.4, 8.6, cz + s * 6.6), Vector3(1.6, 1.2, 1.5), taille, 3.0)
	k.box(R.L(x0 + 1.7, 10.0, cz), Vector3(3.4, 1.6, 15.6), chene, 6.0)
	k.box(R.L(x0 + 2.0, 10.98, cz), Vector3(4.0, 0.36, 16.8), chene, 6.0)
	k.box(R.L(x0 + 1.4, 11.16 + (R.H - 11.16) * 0.5, cz), Vector3(2.8, R.H - 11.16, 13.6), "mur", float((R.pal["mur"] as Array)[2]))
	k.box(R.L(x0 + 2.9, 11.35, cz), Vector3(0.3, 0.38, 13.8), taille, 3.0)
	k.col_box(R.L(x0 + 1.7, 15.0, cz), Vector3(3.4, 10.0, 15.6))
	# l'âtre (la dalle devant le foyer)
	k.box(R.L(x0 + 2.6, 0.1, cz), Vector3(5.2, 0.2, 15.0), taille, 4.0)
	# dans le foyer : les chenets, les bûches, les braises
	var fx: float = x0 - 1.6
	for s2 in [-1.0, 1.0]:
		var cz2: float = cz + s2 * 2.5
		k.cyl(R.L(x0 - 0.1, 0.1, cz2), 0.2, 0.16, 2.2, "fer", 10)
		_boule(M, "fer", Vector3(x0 - 0.1, 2.45, cz2), 0.3)
		k.box(R.L(fx, 0.95, cz2), Vector3(3.2, 0.26, 0.3), "fer", 1.0)
		k.box(R.L(fx - 1.4, 0.45, cz2), Vector3(0.3, 0.9, 0.3), "fer", 1.0)
	var ecorce: String = B._tex(R, "ecorce174", "beau164/ecorce_buche.png", Color(0.82, 0.72, 0.62), 0.95)
	for b in [[1.15, 0.5, 0.0, 0.0], [1.2, 0.46, -0.9, 0.06], [2.0, 0.42, -0.45, -0.05]]:
		k.cyl(R.L(fx + float(b[2]), float(b[0]), cz - 3.4) * Transform3D(Basis(Vector3.RIGHT, PI * 0.5) * Basis(Vector3.FORWARD, float(b[3])), Vector3.ZERO), float(b[1]), float(b[1]) * 0.95, 6.8, ecorce, 12, true, 2.0)
	var braise: String = B._c(R, "braise174", Color(1.0, 0.42, 0.12), 0.9, 0.0, 2.4 if R.day else 3.2)
	k.box(R.L(fx, 0.25, cz), Vector3(2.4, 0.3, 6.0), braise, 1.0)
	for j in range(9):
		_boule(M, braise, Vector3(fx - 1.0 + (j % 3) * 0.9, 0.42, cz - 2.4 + floorf(j / 3.0) * 2.2 + 0.3 * float(j % 2)), 0.22 + 0.05 * float(j % 3), Vector3(1.4, 0.6, 1.0))
	if R.day:
		_feu(M, Vector3(fx, 1.5, cz), 5.0, 4.2, 32.0)
	else:
		_feu(M, Vector3(fx, 1.1, cz), 2.2, 2.0, 24.0)
	# la crémaillère et le chaudron de soupe
	for c in range(16):
		k.ring(R.L(fx, 5.9 + c * 0.32, cz) * Transform3D(Basis(Vector3.UP, PI * 0.5 * float(c % 2)) * Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 0.1, 0.17, 0.07, "fer", 8)
	var fonte: String = B._c(R, "fonte174", Color(0.09, 0.085, 0.08), 0.55, 0.5)
	k.cyl(R.L(fx, 3.0, cz), 1.05, 1.5, 1.2, fonte, 20)
	k.cyl(R.L(fx, 4.2, cz), 1.5, 1.38, 1.3, fonte, 20)
	k.ring(R.L(fx, 5.45, cz), 1.28, 1.48, 0.14, fonte, 20)
	k.cyl(R.L(fx, 5.25, cz), 1.3, 1.3, 0.05, B._c(R, "soupe174", Color(0.62, 0.42, 0.18), 0.35), 20)
	for s3 in [-1.0, 1.0]:
		k.box(R.L(fx, 5.75, cz + s3 * 1.0) * Transform3D(Basis(Vector3.RIGHT, s3 * 0.6), Vector3.ZERO), Vector3(0.1, 1.1, 0.1), "fer", 1.0)
	_vapeur(M, Vector3(fx, 5.6, cz), 0.6, 6.0, Color(0.95, 0.95, 0.95, 0.35), 12)
	# sur la tablette : les chandeliers, le moulin à café, la boîte à sel, un pichet de fleurs séchées
	var laiton: String = B._c(R, "laiton174", Color(0.8, 0.62, 0.3), 0.32, 0.85)
	var ty: float = 11.16
	for zc in [cz - 6.4, cz + 6.4]:
		k.cyl(R.L(x0 + 2.4, ty, zc), 0.55, 0.45, 0.22, laiton, 16)
		k.cyl(R.L(x0 + 2.4, ty + 0.22, zc), 0.14, 0.18, 1.8, laiton, 12)
		k.cyl(R.L(x0 + 2.4, ty + 2.0, zc), 0.26, 0.32, 0.22, laiton, 12)
		k.cyl(R.L(x0 + 2.4, ty + 2.2, zc), 0.22, 0.22, 1.5, B._c(R, "cire174", Color(0.96, 0.93, 0.84), 0.6), 12)
		k.cyl(R.L(x0 + 2.4, ty + 3.7, zc), 0.02, 0.02, 0.18, "noir", 4)
	var mc: Transform3D = R.L(x0 + 2.3, ty, cz - 3.4, 90.0)
	k.box(mc * B.T3(0, 0.6, 0), Vector3(1.2, 1.2, 1.2), _chene(R, false), 2.0)
	k.box(mc * B.T3(0, 0.35, 0.62), Vector3(0.8, 0.3, 0.06), chene, 1.0)
	_boule(M, laiton, _loc(R, mc, Vector3(0, 0.35, 0.68)), 0.07)
	k.cyl(mc * B.T3(0, 1.2, 0), 0.42, 0.55, 0.45, laiton, 14)
	k.cyl(mc * B.T3(0, 1.65, 0), 0.06, 0.06, 0.5, "fer", 6)
	k.box(mc * B.T3(0.35, 2.15, 0), Vector3(0.8, 0.08, 0.1), "fer", 1.0)
	_boule(M, chene, _loc(R, mc, Vector3(0.75, 2.3, 0)), 0.14)
	var email: String = B._c(R, "email174", Color(0.93, 0.93, 0.9), 0.28)
	var bleu: String = B._c(R, "bleu174", Color(0.2, 0.36, 0.64), 0.3)
	k.cyl(R.L(x0 + 2.3, ty, cz + 3.2), 0.6, 0.6, 1.5, email, 16)
	k.ring(R.L(x0 + 2.3, ty + 0.9, cz + 3.2), 0.58, 0.62, 0.22, bleu, 16)
	k.cyl(R.L(x0 + 2.3, ty + 1.5, cz + 3.2), 0.64, 0.64, 0.12, bleu, 16)
	k.cyl(R.L(x0 + 2.4, ty, cz), 0.35, 0.5, 1.0, B._tex(R, "terre174", "beau161/terre_cuite.png", Color(1, 1, 1), 0.85), 14)
	for f in range(7):
		var a: float = TAU * f / 7.0
		var tige := Vector3(x0 + 2.4 + cos(a) * 0.35, ty + 2.4, cz + sin(a) * 0.5)
		k.cyl(R.L(x0 + 2.4, ty + 0.9, cz) * Transform3D(Basis(Vector3(sin(a), 0, -cos(a)).normalized(), 0.25), Vector3.ZERO), 0.03, 0.03, 1.6, B._c(R, "sec174", Color(0.55, 0.45, 0.3), 0.9), 4)
		_boule(M, B._c(R, "fleur_seche174_%d" % (f % 3), [Color(0.72, 0.5, 0.62), Color(0.86, 0.78, 0.55), Color(0.6, 0.62, 0.78)][f % 3], 0.9), tige, 0.22, Vector3(1, 0.7, 1))
	# le tableau du Moulin de la Butte, sur la hotte, dans son cadre doré
	var tab: String = B._img(R, "tableau174", T + "tableau_moulin.png")
	var tx: Transform3D = R.L(x0 + 2.82, 16.0, cz, 90.0)
	k.quad(tx * Transform3D(Basis(Vector3.UP, PI), Vector3(0, 0, 0.02)), 6.2, 4.65, tab)
	for sy in [-1.0, 1.0]:
		k.box(tx * B.T3(0, sy * 2.5, 0.12), Vector3(6.9, 0.35, 0.24), laiton, 2.0)
	for sx in [-1.0, 1.0]:
		k.box(tx * B.T3(sx * 3.28, 0, 0.12), Vector3(0.35, 5.35, 0.24), laiton, 2.0)
	# le soufflet, contre le piédroit ; le panier à bûches de l'autre côté
	var cuir: String = B._c(R, "cuir174", Color(0.36, 0.22, 0.14), 0.75)
	var sf: Transform3D = R.L(x0 + 3.4, 0.0, cz + 8.6, 90.0) * Transform3D(Basis(Vector3.RIGHT, -0.28), Vector3.ZERO)
	k.box(sf * B.T3(0, 1.6, 0), Vector3(1.1, 2.4, 0.12), _chene(R, false), 2.0)
	k.box(sf * B.T3(0, 1.6, 0.3), Vector3(1.0, 2.2, 0.5), cuir, 1.0)
	k.box(sf * B.T3(0, 1.6, 0.6), Vector3(1.1, 2.4, 0.12), _chene(R, false), 2.0)
	k.cyl(sf * B.T3(0, 2.8, 0.3), 0.12, 0.05, 0.9, laiton, 8)
	var osier: String = B._tex(R, "osier174", "beau161/corde.png", Color(0.78, 0.6, 0.38), 0.95)
	k.cyl(R.L(x0 + 3.6, 0.0, cz - 9.6), 1.5, 1.8, 2.1, osier, 18, true, 0.8)
	k.col_cyl(R.P(x0 + 3.6, 0.0, cz - 9.6), 1.8, 2.1)
	for j2 in range(5):
		var a2: float = TAU * j2 / 5.0
		k.cyl(R.L(x0 + 3.6 + cos(a2) * 0.7, 1.4, cz - 9.6 + sin(a2) * 0.7) * Transform3D(Basis(Vector3.RIGHT, PI * 0.5 - 0.35) * Basis(Vector3.FORWARD, a2), Vector3(0, -1.2, 0)), 0.36, 0.36, 3.2, ecorce, 10, true, 2.0)
	# le pique-feu, appuyé
	k.cyl(R.L(x0 + 3.4, 0.0, cz - 7.9) * Transform3D(Basis(Vector3.BACK, 0.12), Vector3.ZERO), 0.07, 0.07, 6.4, "fer", 6)
	R.reserve(x0 + 3.0, cz, 6.0, 17.0)


## Pompon, le chat des Grandpré (un chat de géant : quatre mètres du nez à la queue), qui dort sur le
## tapis tressé devant la cheminée ; on peut le caresser (il ronronne : le sol en vibre).
static func _pompon(M) -> void:
	var R = M.R
	var k = R.kit
	var cx: float = -29.5
	var cz: float = -12.0
	k.cyl(R.L(cx, 0.0, cz), 5.2, 5.2, 0.08, B._c(R, "tapis174_bord", Color(0.55, 0.36, 0.28), 0.95), 32)
	var tap: String = B._img(R, "tapis174", T + "tapis_tresse.png", 1)
	k.quad(R.L(cx, 0.095, cz) * Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), Vector3.ZERO) * Transform3D(Basis(Vector3.UP, PI), Vector3.ZERO), 10.6, 10.6, tap)
	var chat: Node3D = _bete(M, "chat", {"taille": 7.5, "base": Color(0.86, 0.52, 0.24), "tigre": 0.85, "ventre": Color(0.97, 0.9, 0.8),
		"chaussettes": true, "bout_blanc": true, "tache": Color(0.97, 0.93, 0.86), "oeil": Color(0.62, 0.78, 0.25), "seed": 174}, Vector3(cx + 0.4, 0.09, cz + 0.6), -100.0, "dort")
	chat.name = "Pompon"
	k.col_cyl(R.P(cx + 0.4, 0.0, cz + 0.6), 1.9, 1.9)
	var caresser := func() -> void:
		M.say("Tu caresses Pompon : sa fourrure est une prairie tiède. Il ouvre un œil grand comme une assiette… et se met à ronronner. Le sol vibre sous tes pieds.", 7.0)
		for e in M.ctx.get("betes174", []):
			if e[0] == chat:
				e[1] = "content"
		await M.timer(5.0)
		for e2 in M.ctx.get("betes174", []):
			if is_instance_valid(e2[0]) and e2[0] == chat:
				e2[1] = "dort"
	M.act(R.P(cx + 3.6, 0.0, cz + 1.5), "E : caresser Pompon", caresser, 2.4)


## Un pied tourné (de table, de vaisselier) : le dé carré en haut, les bagues, le fuseau, la boule, le
## pied ; h : sa hauteur ; s : son épaisseur ; et sa collision.
static func _pied(M, x: float, z: float, h: float, s: float, key: String) -> void:
	var R = M.R
	var k = R.kit
	var de: float = minf(1.6, h * 0.28)
	k.box(R.L(x, h - de * 0.5, z), Vector3(s, de, s), key, 3.0)
	var y: float = 0.0
	k.box(R.L(x, s * 0.25, z), Vector3(s * 0.92, s * 0.5, s * 0.92), key, 3.0)
	y = s * 0.5
	var corps: float = h - de - y
	var prof := [[0.0, 0.42, 0.36, 0.12], [0.12, 0.36, 0.44, 0.1], [0.22, 0.44, 0.3, 0.38], [0.6, 0.3, 0.38, 0.12], [0.72, 0.38, 0.3, 0.16], [0.88, 0.3, 0.42, 0.12]]
	for p in prof:
		k.cyl(R.L(x, y + corps * float(p[0]), z), s * float(p[1]), s * float(p[2]), corps * float(p[3]), key, 14, true, 2.0)
	k.col_box(R.L(x, h * 0.5, z), Vector3(s, h, s))


## La grande table de ferme (19,5 × 7,5 m ; le plateau à 5,85 m) : le plateau épais, la ceinture, le
## tiroir, les quatre pieds tournés ; et la chaise paillée tirée au bout (son dossier à barreaux).
static func _table(M) -> void:
	var R = M.R
	var k = R.kit
	var tx: float = 4.0
	var tz: float = -2.0
	var tw: float = 19.5
	var td: float = 7.5
	var ty: float = 5.85
	var chene: String = _chene(R, false)
	k.box(R.L(tx, ty - 0.225, tz), Vector3(tw, 0.45, td), chene, 6.0)
	k.col_box(R.L(tx, ty - 0.225, tz), Vector3(tw, 0.45, td))
	for sz in [-1.0, 1.0]:
		k.box(R.L(tx, ty - 1.0, tz + sz * (td * 0.5 - 0.75)), Vector3(tw - 1.8, 1.1, 0.3), chene, 6.0)
	for sx in [-1.0, 1.0]:
		k.box(R.L(tx + sx * (tw * 0.5 - 0.75), ty - 1.0, tz), Vector3(0.3, 1.1, td - 1.8), chene, 6.0)
	# le tiroir (au bout, côté fenêtres)
	k.box(R.L(tx + tw * 0.5 - 0.58, ty - 1.0, tz), Vector3(0.08, 0.8, 3.0), _chene(R, true), 2.0)
	_boule(M, B._c(R, "laiton174", Color(0.8, 0.62, 0.3), 0.32, 0.85), Vector3(tx + tw * 0.5 - 0.48, ty - 1.0, tz), 0.16)
	for sx2 in [-1.0, 1.0]:
		for sz2 in [-1.0, 1.0]:
			_pied(M, tx + sx2 * (tw * 0.5 - 0.8), tz + sz2 * (td * 0.5 - 0.8), ty - 0.45, 0.8, chene)
	R.reserve(tx, tz, tw, td)
	# la chaise paillée, tirée au bout de la table (le dossier loin de la table)
	var cx: float = -7.6
	var sy: float = 3.4
	var paille: String = B._tex(R, "paille174", "montjoie/chaume.png", Color(1.25, 1.1, 0.72), 0.95)
	var sombre: String = _chene(R, true)
	k.box(R.L(cx, sy - 0.15, tz), Vector3(3.4, 0.3, 3.4), paille, 1.2)
	k.col_box(R.L(cx, sy - 0.2, tz), Vector3(3.4, 0.4, 3.4))
	for e in [[0, 1.7], [0, -1.7], [1.7, 0], [-1.7, 0]]:
		var ex: float = e[0]
		var ez: float = e[1]
		var l: float = 3.4 if ex == 0 else 3.4
		k.box(R.L(cx + ex, sy - 0.2, tz + ez), Vector3(0.3 if ex != 0 else l, 0.36, l if ex != 0 else 0.3), sombre, 3.0)
	for lx in [-1.45, 1.45]:
		for lz in [-1.45, 1.45]:
			var hh: float = sy - 0.3 if lx > 0.0 else 7.8
			k.box(R.L(cx + lx, hh * 0.5, tz + lz), Vector3(0.42, hh, 0.42), sombre, 3.0)
			k.col_box(R.L(cx + lx, hh * 0.5, tz + lz), Vector3(0.42, hh, 0.42))
			if lx < 0.0:
				_boule(M, sombre, Vector3(cx + lx, 8.0, tz + lz), 0.3)
	for yb in [0.9, 1.6]:
		for sz3 in [-1.45, 1.45]:
			k.cyl(R.L(cx + 1.45, yb, tz + sz3) * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3.ZERO), 0.12, 0.12, 2.9, sombre, 8)
		for sx3 in [-1.45, 1.45]:
			k.cyl(R.L(cx + sx3, yb, tz - 1.45) * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 0.12, 0.12, 2.9, sombre, 8)
	# le dossier : trois barreaux plats, un peu cintrés
	for yd in [4.9, 5.9, 6.9]:
		k.box(R.L(cx - 1.45, yd, tz), Vector3(0.28, 0.55, 2.9), sombre, 3.0)
	k.col_box(R.L(cx - 1.45, 5.7, tz), Vector3(0.42, 4.6, 3.3))


## L'escalier de livres de Tante Brindille : neuf livres empilés en marches, du carrelage jusqu'à la
## paille de la chaise ; puis six autres sur la chaise, jusqu'au plateau de la table (chaque marche fait
## moins de 0,42 m : on y monte en marchant).
static func _escalier_livres(M) -> void:
	var tz: float = -2.0
	var cx: float = -7.6
	var couleurs := [Color(0.5, 0.12, 0.1), Color(0.18, 0.3, 0.2), Color(0.16, 0.22, 0.42), Color(0.42, 0.3, 0.18), Color(0.55, 0.42, 0.2),
		Color(0.3, 0.12, 0.25), Color(0.12, 0.28, 0.32), Color(0.62, 0.2, 0.12), Color(0.24, 0.24, 0.26)]
	var titres := ["ALMANACH", "LA BONNE CUISINE", "DICTIONNAIRE", "CONTES", "LE JARDIN", "", "HERBIER", "", ""]
	# du sol à la chaise (on monte vers -Z) : les dos alignés contre le bord de la paille
	for i in range(9):
		var y: float = i * 0.38
		var avant: float = -0.25 + (9 - i) * 0.78
		var l: float = avant + 0.42
		_livre(M, cx + 0.05 * float(i % 3) - 0.05, y, (avant - 0.42) * 0.5, Vector3(l, 0.38, 2.4 + 0.12 * float(i % 2)), 90.0, couleurs[i], titres[i])
	# sur la chaise, jusqu'à la table (on monte vers +X)
	for j in range(6):
		var y2: float = 3.4 + j * 0.4
		var arriere: float = -8.8 + j * 0.48
		var l2: float = -5.72 - arriere
		_livre(M, (arriere - 5.72) * 0.5, y2, tz - 0.15 + 0.06 * float(j % 2), Vector3(l2, 0.4, 2.5), 0.0, couleurs[(j + 4) % 9], "")


## Sur la table (le plateau à 5,85 m) : le chemin de table en vichy, la miche et son couteau, les
## miettes, la planche à fromage (la meule, la part coupée, et la souris qui grignote), le pichet de
## lait, les bols de café au lait, le pot de confiture, le beurrier, le panier de pommes, le bouquet de
## pâquerettes, le sucrier et ses morceaux de sucre, la lampe à pétrole.
static func _sur_la_table(M) -> void:
	var R = M.R
	var k = R.kit
	var y: float = 5.85
	var tz: float = -2.0
	var vichy: String = B._tex(R, "vichy174", T + "vichy_rouge.png", Color(1, 1, 1), 0.92)
	k.box(R.L(5.0, y + 0.012, tz), Vector3(14.0, 0.024, 2.8), vichy, 1.2, 4)
	var email: String = B._c(R, "email174", Color(0.93, 0.93, 0.9), 0.28)
	var bleu: String = B._c(R, "bleu174", Color(0.2, 0.36, 0.64), 0.3)
	var faience: String = B._img(R, "faience174", T + "faience.png", 1)
	# la miche (fendue, farinée), une tranche, le couteau, les miettes
	var croute: String = B._tex(R, "croute174", T + "croute.png", Color(1, 1, 1), 0.85)
	_boule(M, croute, Vector3(0.6, y + 0.78, tz - 1.6), 1.3, Vector3(1.0, 0.6, 1.0))
	k.col_cyl(R.P(0.6, y, tz - 1.6), 1.25, 1.6)
	var mie: String = B._c(R, "mie174", Color(0.96, 0.9, 0.76), 0.95)
	k.cyl(R.L(2.6, y, tz - 3.1) * Transform3D(Basis(Vector3.BACK, 0.08), Vector3.ZERO), 1.0, 1.0, 0.2, mie, 22)
	k.ring(R.L(2.6, y, tz - 3.1) * Transform3D(Basis(Vector3.BACK, 0.08), Vector3.ZERO), 0.94, 1.06, 0.21, croute, 22)
	var acier: String = B._c(R, "acier174", Color(0.72, 0.74, 0.76), 0.25, 0.9)
	k.box(R.L(1.6, y + 0.04, tz + 0.2, 12.0), Vector3(2.0, 0.05, 0.34), acier, 1.0)
	k.cyl(R.L(2.6, y + 0.12, tz + 0.4, 12.0) * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3.ZERO), 0.13, 0.13, 1.0, _chene(R, true), 8)
	var miette: String = B._c(R, "miette174", Color(0.86, 0.68, 0.42), 0.95)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1741
	for i in range(16):
		var mx: float = rng.randf_range(-2.0, 4.0)
		var mz: float = tz + rng.randf_range(-2.8, 1.8)
		_boule(M, miette if i % 4 != 0 else mie, Vector3(mx, y + 0.05, mz), rng.randf_range(0.06, 0.2), Vector3(1.0, 0.7, 0.9))
	# la planche à fromage : la meule entamée, la part, et la souris
	var planche: String = _chene(R, false)
	k.box(R.L(10.6, y + 0.1, tz - 2.0), Vector3(3.6, 0.2, 2.6), planche, 2.0)
	var croute_f: String = B._c(R, "croute_fromage174", Color(0.88, 0.62, 0.24), 0.7)
	var fromage: String = B._tex(R, "fromage174", T + "fromage.png", Color(1, 1, 1), 0.65)
	_meule(M, Vector3(10.0, y + 0.2, tz - 2.1), 1.2, 0.85, 300.0, croute_f, fromage)
	k.col_cyl(R.P(10.0, y, tz - 2.1), 1.2, 1.1)
	_part(M, Vector3(11.4, y + 0.2, tz - 1.4), 1.0, 0.8, 50.0, 200.0, croute_f, fromage)
	_bete(M, "rat", {"taille": 3.4, "base": Color(0.52, 0.46, 0.4), "ventre": Color(0.85, 0.8, 0.74), "seed": 9}, Vector3(11.9, y + 0.2, tz - 2.6), -40.0, "assis")
	# le pichet de lait (faïence blanche, filet bleu)
	var px: float = 7.6
	var pz: float = tz + 1.5
	k.cyl(R.L(px, y, pz), 0.7, 0.86, 0.9, email, 18)
	k.cyl(R.L(px, y + 0.9, pz), 0.86, 0.58, 0.8, email, 18)
	k.cyl(R.L(px, y + 1.7, pz), 0.58, 0.7, 0.35, email, 18)
	k.ring(R.L(px, y + 1.2, pz), 0.78, 0.84, 0.16, bleu, 18)
	k.cyl(R.L(px, y + 1.95, pz), 0.62, 0.62, 0.05, B._c(R, "lait174", Color(0.97, 0.96, 0.92), 0.4), 16)
	k.box(R.L(px + 0.72, y + 1.9, pz) * Transform3D(Basis(Vector3.BACK, -0.5), Vector3.ZERO), Vector3(0.4, 0.12, 0.3), email, 1.0)
	for s in range(5):
		var ang: float = -1.1 + s * 0.55
		k.box(R.L(px - 0.86 - 0.35 * cos(ang), y + 1.2 + 0.45 * sin(ang), pz), Vector3(0.14, 0.32, 0.18), email, 1.0)
	k.col_cyl(R.P(px, y, pz), 0.86, 2.0)
	# les bols de café au lait (on pourrait s'y baigner), une cuillère dans l'un
	var cafe: String = B._c(R, "cafe174", Color(0.58, 0.4, 0.24), 0.18)
	for bx in [[3.2, tz + 2.3], [5.4, tz + 2.6], [12.4, tz + 2.2], [-3.4, tz + 2.2]]:
		k.cyl(R.L(float(bx[0]), y, float(bx[1])), 0.5, 0.74, 0.62, email, 20)
		k.ring(R.L(float(bx[0]), y + 0.42, float(bx[1])), 0.69, 0.72, 0.1, bleu, 20)
		k.cyl(R.L(float(bx[0]), y + 0.5, float(bx[1])), 0.68, 0.68, 0.04, cafe, 20)
		k.col_cyl(R.P(float(bx[0]), y, float(bx[1])), 0.74, 0.62)
	var argent: String = "argent"
	k.box(R.L(5.9, y + 0.75, tz + 2.6) * Transform3D(Basis(Vector3.BACK, 0.7), Vector3.ZERO), Vector3(1.4, 0.06, 0.16), argent, 1.0)
	k.box(R.L(-1.6, y + 0.03, tz + 2.6, 80.0), Vector3(1.4, 0.05, 0.15), argent, 1.0)
	_boule(M, argent, Vector3(-1.5, y + 0.06, tz + 1.9), 0.24, Vector3(0.8, 0.25, 1.3))
	# le pot de confiture (le couvercle de vichy, sa ficelle), le beurrier
	var jx: float = 6.2
	var jz: float = tz - 2.4
	k.cyl(R.L(jx, y, jz), 0.46, 0.46, 0.9, B._verre(R, "verre174", Color(0.86, 0.92, 0.95), 0.28), 18)
	k.cyl(R.L(jx, y + 0.05, jz), 0.42, 0.42, 0.72, B._verre(R, "confiture174", Color(0.72, 0.1, 0.16), 0.88), 18)
	k.cyl(R.L(jx, y + 0.9, jz), 0.62, 0.56, 0.08, vichy, 18, true, 0.6)
	k.ring(R.L(jx, y + 0.78, jz), 0.47, 0.5, 0.06, B._tex(R, "corde174", "beau161/corde.png", Color(0.8, 0.7, 0.5), 0.9), 18)
	k.col_cyl(R.P(jx, y, jz), 0.5, 1.0)
	k.box(R.L(8.6, y + 0.04, tz - 2.9), Vector3(1.6, 0.08, 1.0), email, 1.0)
	k.box(R.L(8.6, y + 0.28, tz - 2.9), Vector3(1.1, 0.4, 0.62), B._c(R, "beurre174", Color(0.98, 0.88, 0.5), 0.5), 1.0)
	# le panier de pommes
	var osier: String = B._tex(R, "osier174", "beau161/corde.png", Color(0.78, 0.6, 0.38), 0.95)
	k.cyl(R.L(12.2, y, tz + 0.2), 1.25, 1.5, 0.9, osier, 20, true, 0.5)
	k.col_cyl(R.P(12.2, y, tz + 0.2), 1.5, 1.4)
	for a in range(7):
		var aa: float = TAU * a / 7.0
		var rr: float = 0.0 if a == 6 else 0.75
		_boule(M, B._c(R, "pomme174_%d" % (a % 3), [Color(0.78, 0.14, 0.1), Color(0.62, 0.78, 0.25), Color(0.88, 0.5, 0.15)][a % 3], 0.45), Vector3(12.2 + cos(aa) * rr, y + 1.1 + (0.3 if a == 6 else 0.0), tz + 0.2 + sin(aa) * rr), 0.42)
	# le bouquet de pâquerettes (cueilli par Pâquerette), dans un petit vase de faïence
	var vx: float = 4.6
	var vz: float = tz - 0.1
	k.cyl(R.L(vx, y, vz), 0.32, 0.46, 1.0, email, 16)
	k.cyl(R.L(vx, y + 1.0, vz), 0.46, 0.3, 0.4, email, 16)
	var tige: String = B._c(R, "tige174", Color(0.3, 0.5, 0.22), 0.8)
	var blanc_f: String = B._c(R, "petale174", Color(0.98, 0.97, 0.95), 0.7)
	var coeur: String = B._c(R, "coeur174", Color(0.98, 0.78, 0.12), 0.6)
	for f in range(9):
		var af: float = TAU * f / 9.0 + 0.3
		var inc: float = 0.25 + 0.12 * float(f % 3)
		var ax := Vector3(sin(af), 0, -cos(af))
		var xt: Transform3D = R.L(vx, y + 1.1, vz) * Transform3D(Basis(ax, inc), Vector3.ZERO)
		var lt: float = 1.6 + 0.35 * float(f % 4)
		k.cyl(xt, 0.035, 0.03, lt, tige, 5)
		var tete: Transform3D = xt * Transform3D(Basis(Vector3.RIGHT, -0.4), Vector3(0, lt, 0))
		k.cyl(tete, 0.34, 0.34, 0.03, blanc_f, 16)
		k.cyl(tete * B.T3(0, 0.02, 0), 0.11, 0.09, 0.08, coeur, 10)
	k.col_cyl(R.P(vx, y, vz), 0.46, 1.4)
	# le sucrier, et trois morceaux de sucre sortis (des pavés pour un Petit)
	k.cyl(R.L(9.4, y, tz + 0.9), 0.5, 0.56, 0.6, email, 16)
	k.cyl(R.L(9.4, y + 0.6, tz + 0.9), 0.58, 0.2, 0.22, email, 16)
	_boule(M, bleu, Vector3(9.4, y + 0.88, tz + 0.9), 0.1)
	var sucre: String = B._c(R, "sucre174", Color(0.98, 0.98, 0.97), 0.65)
	for q in [[10.2, tz + 1.8, 10.0], [10.5, tz + 1.4, 35.0], [-0.6, tz + 0.9, 60.0]]:
		k.box(R.L(float(q[0]), y + 0.06, float(q[1]), float(q[2])), Vector3(0.12, 0.12, 0.12), sucre, 1.0)
	# deux assiettes (des miettes dedans)
	for pa in [[-2.6, tz - 2.3], [1.2, tz + 2.4]]:
		k.cyl(R.L(float(pa[0]), y, float(pa[1])), 1.0, 1.15, 0.12, email, 24)
		k.quad(R.L(float(pa[0]), y + 0.125, float(pa[1])) * Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), Vector3.ZERO) * Transform3D(Basis(Vector3.UP, PI), Vector3.ZERO), 2.2, 2.2, faience)
	# la lampe à pétrole (éteinte : la maison dort, ou le soleil suffit)
	var laiton: String = B._c(R, "laiton174", Color(0.8, 0.62, 0.3), 0.32, 0.85)
	var lx: float = 13.0
	var lz: float = tz - 2.9
	k.cyl(R.L(lx, y, lz), 0.55, 0.5, 0.18, laiton, 18)
	k.cyl(R.L(lx, y + 0.18, lz), 0.18, 0.24, 0.5, laiton, 12)
	_boule(M, B._verre(R, "petrole174", Color(0.6, 0.75, 0.55), 0.55), Vector3(lx, y + 0.98, lz), 0.46, Vector3(1, 0.85, 1))
	k.cyl(R.L(lx, y + 1.36, lz), 0.3, 0.3, 0.2, laiton, 12)
	k.cyl(R.L(lx, y + 1.56, lz), 0.26, 0.18, 1.6, B._verre(R, "verre174", Color(0.86, 0.92, 0.95), 0.28), 14)
	k.col_cyl(R.P(lx, y, lz), 0.55, 3.0)
	# on goûte une miette
	var gouter := func() -> void:
		M.say("Tu croques une miette de la miche des Grandpré : elle est grosse comme ton poing, croustillante, et encore tiède. De quoi tenir jusqu'au soir.", 6.0)
	M.act(R.P(-0.6, y, tz - 0.4), "E : goûter une miette de pain", gouter, 2.2)


## Une meule de fromage entamée (centre du dessous, rayon, hauteur ; « coupe » : l'angle de la part
## qui manque, en degrés) : la croûte, le dessus, les deux faces de la coupe (les trous).
static func _meule(M, c: Vector3, r: float, h: float, plein: float, croute: String, pate: String) -> void:
	var R = M.R
	var k = R.kit
	var n: int = 24
	var a1: float = deg_to_rad(plein)
	var top: String = B._c(R, "dessus_fromage174", Color(0.92, 0.7, 0.32), 0.7)
	for i in range(n):
		var t0: float = a1 * i / n
		var t1: float = a1 * (i + 1) / n
		var p0 := Vector3(cos(t0) * r, 0, sin(t0) * r)
		var p1 := Vector3(cos(t1) * r, 0, sin(t1) * r)
		var nm := Vector3(cos((t0 + t1) * 0.5), 0, sin((t0 + t1) * 0.5))
		k.quad4(croute, R.P(c.x + p0.x, c.y, c.z + p0.z), R.P(c.x + p1.x, c.y, c.z + p1.z), R.P(c.x + p1.x, c.y + h, c.z + p1.z), R.P(c.x + p0.x, c.y + h, c.z + p0.z), nm, Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0))
		k.tri(top, R.P(c.x, c.y + h, c.z), R.P(c.x + p0.x, c.y + h, c.z + p0.z), R.P(c.x + p1.x, c.y + h, c.z + p1.z), Vector3.UP, Vector2(0.5, 0.5), Vector2(0.5 + p0.x / r * 0.5, 0.5 + p0.z / r * 0.5), Vector2(0.5 + p1.x / r * 0.5, 0.5 + p1.z / r * 0.5))
	for a in [0.0, a1]:
		var d := Vector3(cos(a), 0, sin(a))
		var nrm := Vector3(sin(a), 0, -cos(a)) * (1.0 if a == 0.0 else -1.0)
		k.quad4(pate, R.P(c.x, c.y, c.z), R.P(c.x + d.x * r, c.y, c.z + d.z * r), R.P(c.x + d.x * r, c.y + h, c.z + d.z * r), R.P(c.x, c.y + h, c.z), nrm,
			Vector2(0, h / 1.2), Vector2(r / 1.2, h / 1.2), Vector2(r / 1.2, 0), Vector2(0, 0))


## La part coupée (un coin de fromage, couché) : at, rayon, hauteur, angle (degrés), orientation.
static func _part(M, c: Vector3, r: float, h: float, angle: float, yaw: float, croute: String, pate: String) -> void:
	var R = M.R
	var k = R.kit
	var xf: Transform3D = R.L(c.x, c.y, c.z, yaw)
	var a1: float = deg_to_rad(angle)
	var p1 := Vector3(r, 0, 0)
	var p2 := Vector3(cos(a1) * r, 0, sin(a1) * r)
	var up := Vector3(0, h, 0)
	k.quad4(croute, xf * p1, xf * p2, xf * (p2 + up), xf * (p1 + up), xf.basis * Vector3(cos(a1 * 0.5), 0, sin(a1 * 0.5)), Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0))
	k.quad4(pate, xf * Vector3.ZERO, xf * p1, xf * (p1 + up), xf * up, xf.basis * Vector3(0, 0, -1), Vector2(0, h), Vector2(r, h), Vector2(r, 0), Vector2(0, 0))
	k.quad4(pate, xf * Vector3.ZERO, xf * p2, xf * (p2 + up), xf * up, xf.basis * Vector3(sin(a1), 0, -cos(a1)) * -1.0, Vector2(0, h), Vector2(r, h), Vector2(r, 0), Vector2(0, 0))
	var top: String = B._c(R, "dessus_fromage174", Color(0.92, 0.7, 0.32), 0.7)
	k.tri(top, xf * up, xf * (p1 + up), xf * (p2 + up), Vector3.UP, Vector2(0, 0), Vector2(1, 0), Vector2(0, 1))


## Le vaisselier, contre le mur du fond (12 m de large ; le buffet sur ses hauts pieds tournés : dessous,
## 2,4 m de vide, où habite Tante Brindille) : les portes à panneaux, les tiroirs et leurs boutons de
## laiton, le plan de chêne (la soupière, la cafetière bleue, le bol d'œufs) ; au-dessus, les étagères et
## leurs assiettes de faïence dressées, les tasses pendues, la corniche.
static func _vaisselier(M) -> void:
	var R = M.R
	var k = R.kit
	var zf: float = -R.D * 0.5
	var chene: String = _chene(R, false)
	var sombre: String = _chene(R, true)
	var laiton: String = B._c(R, "laiton174", Color(0.8, 0.62, 0.3), 0.32, 0.85)
	var email: String = B._c(R, "email174", Color(0.93, 0.93, 0.9), 0.28)
	var bleu: String = B._c(R, "bleu174", Color(0.2, 0.36, 0.64), 0.3)
	var faience: String = B._img(R, "faience174", T + "faience.png", 1)
	var pz: float = zf + 1.875
	for sx in [-5.6, 5.6]:
		for sz in [zf + 0.4, zf + 3.35]:
			_pied(M, sx, sz, 2.4, 0.6, sombre)
	# le buffet
	k.box(R.L(0, 4.7, pz), Vector3(12.0, 4.6, 3.75), chene, 5.0)
	k.col_box(R.L(0, 4.7, pz), Vector3(12.0, 4.6, 3.75))
	var fz: float = zf + 3.75
	for d in [-1.0, 1.0]:
		var dx: float = d * 3.0
		k.box(R.L(dx, 3.75, fz + 0.04), Vector3(5.4, 2.7, 0.08), chene, 3.0)
		k.box(R.L(dx, 3.75, fz + 0.1), Vector3(4.2, 1.9, 0.08), sombre, 3.0)
		k.box(R.L(dx, 3.75, fz + 0.15), Vector3(3.8, 1.5, 0.06), chene, 3.0)
		k.box(R.L(dx, 6.15, fz + 0.04), Vector3(5.4, 1.1, 0.08), chene, 3.0)
		_boule(M, laiton, Vector3(dx, 6.15, fz + 0.2), 0.16)
		_boule(M, laiton, Vector3(dx - d * 2.1, 3.75, fz + 0.2), 0.14)
		k.box(R.L(dx + d * 0.0, 3.75, fz + 0.12), Vector3(0.05, 2.5, 0.02), "noir", 1.0)
	k.box(R.L(0, 3.75, fz + 0.06), Vector3(0.3, 2.9, 0.12), sombre, 2.0)
	k.box(R.L(0, 7.18, pz + 0.12), Vector3(12.6, 0.36, 4.1), chene, 5.0)
	k.box(R.L(0, 2.45, pz + 0.05), Vector3(12.2, 0.2, 3.85), sombre, 4.0)
	# le haut : le dos, les côtés, les étagères, la corniche
	var hz: float = zf + 0.95
	k.box(R.L(0, 11.95, zf + 0.15), Vector3(12.0, 9.2, 0.3), chene, 5.0)
	for s in [-1.0, 1.0]:
		k.box(R.L(s * 5.83, 11.95, hz), Vector3(0.35, 9.2, 1.7), chene, 5.0)
	for ye in [9.9, 12.8, 15.6]:
		k.box(R.L(0, ye, hz), Vector3(11.4, 0.3, 1.7), chene, 5.0)
		k.cyl(R.L(5.6, ye + 0.55, hz + 0.65) * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3.ZERO), 0.06, 0.06, 11.2, laiton, 6)
	k.box(R.L(0, 16.95, hz + 0.15), Vector3(12.8, 0.9, 2.2), sombre, 5.0)
	k.box(R.L(0, 17.5, hz + 0.25), Vector3(13.2, 0.25, 2.5), chene, 5.0)
	k.col_box(R.L(0, 12.2, hz), Vector3(12.0, 10.2, 1.8))
	# les assiettes dressées (deux étagères), les tasses pendues sous la troisième
	for ye2 in [9.9, 12.8]:
		for i in range(4):
			var ax: float = -4.2 + i * 2.8
			var xp: Transform3D = R.L(ax, ye2 + 0.15 + 1.05, zf + 0.45) * Transform3D(Basis(Vector3.RIGHT, -0.16), Vector3.ZERO)
			k.cyl(xp * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0, 0.0)), 1.05, 1.05, 0.08, email, 24)
			k.quad(xp * Transform3D(Basis(Vector3.UP, PI), Vector3(0, 0, 0.1)), 2.08, 2.08, faience)
	for i2 in range(6):
		var cxp: float = -4.6 + i2 * 1.84
		k.cyl(R.L(cxp, 15.1, hz + 0.4), 0.03, 0.03, 0.35, "fer", 4)
		k.cyl(R.L(cxp, 14.2, hz + 0.4), 0.32, 0.42, 0.7, email if i2 % 2 == 0 else bleu, 14)
		k.ring(R.L(cxp + 0.42, 14.55, hz + 0.4) * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 0.14, 0.22, 0.08, email if i2 % 2 == 0 else bleu, 10)
	# sur le plan : la soupière, la cafetière bleue, le bol d'œufs
	var yp: float = 7.36
	k.cyl(R.L(0, yp, pz + 0.3), 0.8, 1.4, 0.4, email, 22)
	k.cyl(R.L(0, yp + 0.4, pz + 0.3), 1.4, 1.3, 0.9, email, 22)
	k.ring(R.L(0, yp + 0.9, pz + 0.3), 1.36, 1.42, 0.14, bleu, 22)
	_boule(M, email, Vector3(0, yp + 1.3, pz + 0.3), 1.25, Vector3(1, 0.4, 1))
	_boule(M, bleu, Vector3(0, yp + 1.85, pz + 0.3), 0.22)
	for s2 in [-1.0, 1.0]:
		k.box(R.L(s2 * 1.5, yp + 1.05, pz + 0.3), Vector3(0.35, 0.18, 0.5), email, 1.0)
	k.cyl(R.L(-3.8, yp, pz + 0.3), 0.75, 0.6, 1.6, bleu, 18)
	k.cyl(R.L(-3.8, yp + 1.6, pz + 0.3), 0.6, 0.35, 0.3, bleu, 18)
	_boule(M, "noir", Vector3(-3.8, yp + 2.0, pz + 0.3), 0.12)
	k.cyl(R.L(-3.1, yp + 0.6, pz + 0.3) * Transform3D(Basis(Vector3.BACK, -0.9), Vector3.ZERO), 0.12, 0.07, 1.0, bleu, 8)
	k.cyl(R.L(3.8, yp, pz + 0.3), 0.6, 1.0, 0.65, B._tex(R, "terre174", "beau161/terre_cuite.png", Color(1, 1, 1), 0.85), 18)
	for o in range(5):
		var ao: float = TAU * o / 5.0
		_boule(M, B._c(R, "oeuf174", Color(0.86, 0.7, 0.52), 0.6), Vector3(3.8 + cos(ao) * 0.42, yp + 0.75, pz + 0.3 + sin(ao) * 0.42), 0.32, Vector3(0.85, 1.15, 0.85))


## Chez Tante Brindille, sous le vaisselier : son lit (une boîte de sardines, le couvercle roulé, un
## mouchoir pour couverture), sa table (une tasse retournée, sur un sous-verre de liège), ses tabourets
## (des bobines de fil), sa lampe (une bougie d'anniversaire sur une capsule), un timbre encadré, une
## boîte d'allumettes pour commode, Gustave (la bille bleue de Pâquerette) sur son coussin, le rideau
## (un mouchoir), et l'écriteau sur une pince à linge.
static func _chez_brindille(M) -> void:
	var R = M.R
	var k = R.kit
	var zf: float = -R.D * 0.5
	var fer_blanc: String = B._c(R, "fer_blanc174", Color(0.78, 0.8, 0.82), 0.3, 0.9)
	var email: String = B._c(R, "email174", Color(0.93, 0.93, 0.9), 0.28)
	var bleu: String = B._c(R, "bleu174", Color(0.2, 0.36, 0.64), 0.3)
	var vichy: String = B._tex(R, "vichy174", T + "vichy_rouge.png", Color(1, 1, 1), 0.92)
	var toile: String = B._tex(R, "lin174", "beau161/toile_lin.png", Color(0.98, 0.96, 0.9), 0.95)
	# le lit : la boîte de sardines (2,1 × 0,85 m), son étiquette, le couvercle roulé et sa clé
	var bx: float = -3.0
	var bz: float = zf + 1.6
	k.box(R.L(bx, 0.03, bz), Vector3(2.1, 0.06, 0.85), fer_blanc, 1.0)
	for s in [-1.0, 1.0]:
		k.box(R.L(bx, 0.17, bz + s * 0.41), Vector3(2.1, 0.3, 0.03), fer_blanc, 1.0)
		k.box(R.L(bx + s * 1.035, 0.17, bz), Vector3(0.03, 0.3, 0.85), fer_blanc, 1.0)
	var eti: String = B._img(R, "sardines174", T + "etiquette_sardines.png")
	k.quad(R.L(bx, 0.17, bz + 0.43) * Transform3D(Basis(Vector3.UP, PI), Vector3.ZERO), 2.0, 0.27, eti)
	k.cyl(R.L(bx + 1.2, 0.36, bz - 0.43) * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 0.13, 0.13, 0.86, fer_blanc, 12)
	k.box(R.L(bx + 1.2, 0.36, bz - 0.55), Vector3(0.05, 0.05, 0.3), fer_blanc, 1.0)
	k.ring(R.L(bx + 1.2, 0.36, bz - 0.75) * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 0.05, 0.1, 0.03, fer_blanc, 10)
	k.box(R.L(bx - 0.05, 0.22, bz), Vector3(1.95, 0.12, 0.75), toile, 0.6)
	k.box(R.L(bx + 0.25, 0.32, bz) * Transform3D(Basis(Vector3.BACK, 0.03), Vector3.ZERO), Vector3(1.35, 0.08, 0.82), vichy, 0.5)
	_boule(M, toile, Vector3(bx - 0.72, 0.36, bz), 0.24, Vector3(1.3, 0.55, 1.4))
	k.col_box(R.L(bx, 0.2, bz), Vector3(2.1, 0.4, 0.85))
	# la table (une tasse retournée) sur son sous-verre de liège ; dessus, un bouton pour assiette, un
	# dé à coudre pour gobelet, une miette
	var tx: float = 0.4
	var tz: float = zf + 2.3
	k.cyl(R.L(tx, 0.0, tz), 0.75, 0.75, 0.03, B._c(R, "liege174", Color(0.72, 0.56, 0.38), 0.95), 24)
	k.cyl(R.L(tx, 0.03, tz), 0.44, 0.34, 0.62, email, 20)
	k.ring(R.L(tx, 0.4, tz), 0.36, 0.4, 0.06, bleu, 20)
	k.ring(R.L(tx + 0.42, 0.33, tz) * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 0.12, 0.18, 0.05, email, 10)
	k.col_cyl(R.P(tx, 0.0, tz), 0.44, 0.65)
	k.cyl(R.L(tx - 0.1, 0.65, tz), 0.16, 0.16, 0.025, B._c(R, "bouton174", Color(0.75, 0.16, 0.18), 0.4), 16)
	for h in range(4):
		_boule(M, "noir", Vector3(tx - 0.1 + (0.04 if h % 2 == 0 else -0.04), 0.676, tz + (0.04 if h < 2 else -0.04)), 0.015)
	k.cyl(R.L(tx + 0.17, 0.65, tz - 0.08), 0.07, 0.08, 0.14, B._c(R, "laiton174", Color(0.8, 0.62, 0.3), 0.32, 0.85), 12)
	_boule(M, B._c(R, "miette174", Color(0.86, 0.68, 0.42), 0.95), Vector3(tx - 0.1, 0.71, tz), 0.06, Vector3(1, 0.7, 0.9))
	# les tabourets : deux bobines de fil
	for sp in [[tx - 0.75, tz + 0.35, Color(0.72, 0.16, 0.2)], [tx + 0.8, tz - 0.3, Color(0.2, 0.36, 0.64)]]:
		var fil: String = B._c(R, "fil174_%s" % (sp[2] as Color).to_html(false), sp[2], 0.85)
		k.cyl(R.L(float(sp[0]), 0.0, float(sp[1])), 0.18, 0.18, 0.05, _chene(R, false), 14)
		k.cyl(R.L(float(sp[0]), 0.05, float(sp[1])), 0.14, 0.14, 0.27, fil, 14)
		k.cyl(R.L(float(sp[0]), 0.32, float(sp[1])), 0.18, 0.18, 0.05, _chene(R, false), 14)
	# la lampe : une bougie d'anniversaire torsadée sur une capsule ; sa petite flamme (toujours allumée)
	var lx: float = 2.0
	var lz: float = zf + 1.3
	k.cyl(R.L(lx, 0.0, lz), 0.14, 0.14, 0.05, B._c(R, "capsule174", Color(0.75, 0.6, 0.2), 0.3, 0.8), 14)
	k.cyl(R.L(lx, 0.05, lz), 0.035, 0.035, 0.32, B._c(R, "bougie174", Color(0.95, 0.55, 0.7), 0.6), 8)
	k.cyl(R.L(lx, 0.37, lz), 0.004, 0.004, 0.03, "noir", 4)
	k.cyl(R.L(lx, 0.38, lz), 0.018, 0.0, 0.07, "flamme", 6, false)
	_omni(M, Vector3(lx, 0.6, lz + 0.3), Color(1.0, 0.72, 0.42), 0.9 if R.day else 1.6, 7.0)
	# la commode : une boîte d'allumettes (un tiroir entrouvert)
	k.box(R.L(3.6, 0.06, zf + 1.0), Vector3(0.37, 0.12, 0.26), B._c(R, "allumettes174", Color(0.86, 0.3, 0.16), 0.7), 1.0)
	k.box(R.L(3.6, 0.2, zf + 1.0), Vector3(0.37, 0.12, 0.26), B._c(R, "allumettes174_b", Color(0.92, 0.8, 0.4), 0.7), 1.0)
	# Gustave, la bille bleue de Pâquerette, sur son coussin (un dé à coudre renversé)
	var gx: float = 3.0
	var gz: float = zf + 2.6
	k.cyl(R.L(gx, 0.0, gz), 0.11, 0.09, 0.14, B._c(R, "laiton174", Color(0.8, 0.62, 0.3), 0.32, 0.85), 12)
	_boule(M, B._verre(R, "bille174", Color(0.25, 0.5, 0.95), 0.62), Vector3(gx, 0.36, gz), 0.22)
	_boule(M, B._c(R, "spirale174", Color(0.92, 0.95, 1.0), 0.3, 0.0, 0.3), Vector3(gx, 0.36, gz), 0.12, Vector3(1.6, 0.35, 0.6))
	# le timbre encadré, au mur du fond (sous le buffet)
	var tim: String = B._img(R, "timbre174", T + "timbre.png", 1)
	k.quad(R.L(-0.8, 1.15, zf + 0.04) * Transform3D(Basis(Vector3.UP, PI), Vector3.ZERO), 0.36, 0.45, tim)
	# le rideau (un mouchoir de lin), attaché sur le côté
	k.box(R.L(-4.9, 1.2, zf + 3.7) * Transform3D(Basis(Vector3.BACK, 0.12), Vector3.ZERO), Vector3(1.0, 2.3, 0.03), toile, 0.7)
	k.cyl(R.L(-4.9, 1.0, zf + 3.7), 0.4, 0.3, 0.12, B._tex(R, "corde174", "beau161/corde.png", Color(0.8, 0.7, 0.5), 0.9), 10)
	# l'écriteau sur sa pince à linge
	var pince: String = _chene(R, false)
	k.box(R.L(4.6, 0.28, zf + 4.35), Vector3(0.09, 0.56, 0.12), pince, 1.0)
	k.box(R.L(4.75, 0.28, zf + 4.35), Vector3(0.09, 0.56, 0.12), pince, 1.0)
	k.box(R.L(4.68, 0.32, zf + 4.35), Vector3(0.24, 0.05, 0.14), "fer", 1.0)
	k.box(R.L(4.68, 0.62, zf + 4.39), Vector3(0.7, 0.3, 0.03), _chene(R, false), 1.0)
	B._ecrit(M, 4.68, 0.62, zf + 4.41, 0.0, "Chez Brindille", 44, Color(0.98, 0.92, 0.78), 0.0028, 0.0)


## L'horloge comtoise, contre le pignon de droite (17 m de haut) : la caisse de pin peinte (le socle, la
## gaine et son ventre vitré, la tête), le cadran émaillé et ses aiguilles (elles donnent l'heure du
## jeu), le fronton de laiton repoussé ; derrière la vitre, le grand balancier qui bat lentement (une
## seconde de géant : presque six des nôtres) et les deux poids.
static func _comtoise(M) -> void:
	var R = M.R
	var k = R.kit
	var xf: Transform3D = R.L(R.W * 0.5 - 1.5, 0.0, -12.0, -90.0)
	var pin: String = B._tex(R, "pin174", "beau161/bois_peint.png", Color(0.62, 0.72, 0.66), 0.65)
	var laiton: String = B._c(R, "laiton174", Color(0.8, 0.62, 0.3), 0.32, 0.85)
	var verre: String = B._verre(R, "vitre_horloge174", Color(0.85, 0.9, 0.95), 0.16)
	k.box(xf * B.T3(0, 0.9, 0), Vector3(4.2, 1.8, 2.8), pin, 3.0)
	k.box(xf * B.T3(0, 1.85, 0.05), Vector3(4.4, 0.25, 2.9), pin, 3.0)
	# la gaine : le dos, les côtés, le ventre ; la vitre devant
	k.box(xf * B.T3(0, 6.5, -1.15), Vector3(3.6, 9.0, 0.2), pin, 3.0)
	for s in [-1.0, 1.0]:
		k.box(xf * B.T3(s * 1.7, 6.5, 0), Vector3(0.25, 9.0, 2.4), pin, 3.0)
		k.box(xf * B.T3(s * 1.55, 6.5, 1.15), Vector3(0.55, 9.0, 0.22), pin, 3.0)
	k.box(xf * B.T3(0, 2.3, 1.15), Vector3(3.6, 0.6, 0.22), pin, 3.0)
	k.box(xf * B.T3(0, 6.5, 1.12), Vector3(2.6, 7.8, 0.05), verre, 1.0, 16)
	# des fleurs peintes sur le ventre (des boules de couleur, quelques feuilles)
	for f in range(5):
		var c: Color = [Color(0.82, 0.24, 0.24), Color(0.95, 0.75, 0.25), Color(0.32, 0.45, 0.75)][f % 3]
		_boule(M, B._c(R, "fleur174_%d" % (f % 3), c, 0.6), _loc(R, xf, Vector3(-1.55 + (f % 2) * 3.1, 3.0 + f * 1.4, 1.27)), 0.16, Vector3(1, 1, 0.3))
	# la tête : la boîte, le cadran, sa lunette de laiton, le fronton, la corniche
	k.box(xf * B.T3(0, 13.5, 0), Vector3(4.2, 4.6, 2.8), pin, 3.0)
	var cad: String = B._img(R, "cadran174", T + "cadran_comtoise.png", 1)
	var cx: Transform3D = xf * B.T3(0, 13.4, 1.42)
	k.quad(cx * Transform3D(Basis(Vector3.UP, PI), Vector3(0, 0, 0.01)), 2.9, 2.9, cad)
	k.ring(cx * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 1.42, 1.62, 0.18, laiton, 32)
	k.box(xf * B.T3(0, 15.5, 1.38), Vector3(3.6, 0.7, 0.1), laiton, 1.0)
	for j in range(7):
		_boule(M, laiton, _loc(R, xf, Vector3(-1.5 + j * 0.5, 15.5 + 0.15 * sin(j * 1.3), 1.45)), 0.16, Vector3(1, 1, 0.4))
	k.box(xf * B.T3(0, 16.05, 0.1), Vector3(4.7, 0.5, 3.1), pin, 3.0)
	_boule(M, laiton, _loc(R, xf, Vector3(0, 16.6, 0.3)), 0.32)
	k.col_box(xf * B.T3(0, 8.2, 0), Vector3(4.4, 16.4, 2.9))
	# les aiguilles (un pivot qui tourne, deux aiguilles)
	var noir: Material = R.mat("noir")
	var ph := _noeud(M, "Aiguille_heures", cx * B.T3(0, 0, 0.06))
	_bout(ph, B._boitem(0.16, 0.85, 0.03), noir, Vector3(0, 0.36, 0))
	var pm := _noeud(M, "Aiguille_minutes", cx * B.T3(0, 0, 0.1))
	_bout(pm, B._boitem(0.1, 1.2, 0.03), noir, Vector3(0, 0.52, 0))
	_bout(pm, B._cylm(0.1, 0.1, 0.06, 10), R.mat(laiton), Vector3.ZERO, Basis(Vector3.RIGHT, PI * 0.5))
	M.ctx["aiguilles174"] = [ph, pm]
	# le balancier (la lyre, la lentille de laiton) et les poids
	var bal := _noeud(M, "Balancier", xf * B.T3(0, 11.0, 0.2))
	var ml: Material = R.mat(laiton)
	_bout(bal, B._boitem(0.12, 7.4, 0.05), ml, Vector3(0, -3.7, 0))
	for s2 in [-1.0, 1.0]:
		_bout(bal, B._boitem(0.06, 3.2, 0.04), ml, Vector3(s2 * 0.32, -5.4, 0), Basis(Vector3.BACK, -s2 * 0.12))
	_bout(bal, B._cylm(1.0, 1.0, 0.12, 32), ml, Vector3(0, -7.5, 0), Basis(Vector3.RIGHT, PI * 0.5))
	_bout(bal, B._cylm(0.7, 0.7, 0.16, 32), ml, Vector3(0, -7.5, 0.02), Basis(Vector3.RIGHT, PI * 0.5))
	(M.ctx["anims170"] as Array).append([bal, "balance", 0.11, TAU / 5.5])
	for s3 in [-1.0, 1.0]:
		k.cyl(xf * B.T3(s3 * 0.9, 8.4 + s3 * 0.8, -0.6), 0.03, 0.03, 2.6 - s3 * 0.8, "fer", 4)
		k.cyl(xf * B.T3(s3 * 0.9, 6.9 + s3 * 0.8, -0.6), 0.28, 0.28, 1.5, laiton, 14)
	var ecouter := func() -> void:
		M.say("Tic… … … tac. Le balancier passe, lent comme une respiration de géant. Entre deux battements, on a le temps de compter jusqu'à cinq.", 6.0)
	M.act(_loc(R, xf, Vector3(0, 0, 3.6)), "E : écouter l'horloge", ecouter, 2.4)


## L'évier de grès sous la fenêtre du fond (à droite), la pompe à bras, le seau de zinc, le torchon ; le
## grand balai de bruyère contre le mur.
static func _evier(M) -> void:
	var R = M.R
	var k = R.kit
	var zf: float = -R.D * 0.5
	var ex: float = 31.0
	var ez: float = zf + 2.1
	var gres: String = B._tex(R, "gres174", "montjoie/pierre_rempart.png", Color(0.86, 0.8, 0.7), 0.8)
	for s in [-1.0, 1.0]:
		k.box(R.L(ex + s * 3.7, 2.6, ez), Vector3(1.3, 5.2, 3.8), gres, 4.0)
	k.box(R.L(ex, 5.6, ez), Vector3(9.5, 0.8, 4.2), gres, 4.0)
	k.box(R.L(ex, 6.02, ez), Vector3(7.2, 0.04, 2.9), B._c(R, "eau174", Color(0.18, 0.24, 0.26), 0.08, 0.2), 1.0, 4)
	for s2 in [-1.0, 1.0]:
		k.box(R.L(ex, 6.2, ez + s2 * 1.75), Vector3(9.5, 0.36, 0.7), gres, 4.0)
		k.box(R.L(ex + s2 * 4.0, 6.2, ez), Vector3(1.5, 0.36, 4.2), gres, 4.0)
	k.col_box(R.L(ex, 3.2, ez), Vector3(9.5, 6.4, 4.2))
	# la pompe à bras
	var fonte: String = B._c(R, "fonte174", Color(0.09, 0.085, 0.08), 0.55, 0.5)
	k.cyl(R.L(ex - 3.4, 6.38, zf + 0.9), 0.42, 0.46, 3.2, fonte, 14)
	k.box(R.L(ex - 3.4, 8.6, zf + 1.7), Vector3(0.36, 0.36, 1.6), fonte, 1.0)
	k.cyl(R.L(ex - 3.4, 9.6, zf + 0.9) * Transform3D(Basis(Vector3.RIGHT, 1.2), Vector3.ZERO), 0.12, 0.08, 3.4, fonte, 8)
	_boule(M, fonte, Vector3(ex - 3.4, 9.75, zf + 0.9), 0.5)
	# le torchon
	var vichy: String = B._tex(R, "vichy174", T + "vichy_rouge.png", Color(1, 1, 1), 0.92)
	k.box(R.L(ex + 2.2, 5.1, ez + 2.18), Vector3(1.6, 2.2, 0.05), vichy, 0.6)
	# le seau de zinc, plein d'eau, et son anse
	var zinc: String = B._tex(R, "zinc174", "beau161/zinc_galva.png", Color(1, 1, 1), 0.45)
	k.cyl(R.L(ex - 2.0, 0.0, zf + 6.0), 1.05, 1.25, 2.3, zinc, 22)
	k.cyl(R.L(ex - 2.0, 2.0, zf + 6.0), 1.2, 1.2, 0.04, B._c(R, "eau174", Color(0.18, 0.24, 0.26), 0.08, 0.2), 22)
	k.ring(R.L(ex - 2.0, 2.24, zf + 6.0), 1.2, 1.3, 0.08, zinc, 22)
	k.ring(R.L(ex - 2.0, 2.3, zf + 6.0) * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3.ZERO), 1.15, 1.22, 0.08, "fer", 22)
	k.col_cyl(R.P(ex - 2.0, 0.0, zf + 6.0), 1.25, 2.3)
	# le balai de bruyère
	var bt: Transform3D = R.L(ex + 6.3, 0.0, zf + 0.9) * Transform3D(Basis(Vector3.RIGHT, -0.06), Vector3.ZERO)
	k.cyl(bt * B.T3(0, 2.0, 0), 0.22, 0.2, 8.2, _chene(R, false), 10)
	k.cyl(bt, 0.95, 0.35, 2.4, B._tex(R, "bruyere174", "montjoie/chaume.png", Color(0.75, 0.62, 0.45), 0.95), 14)


## Le pétrin sous la fenêtre du fond (à gauche) : la huche sur ses pieds, le couvercle ; dessus, la
## jatte de terre où lève la pâte, sous un linge.
static func _petrin(M) -> void:
	var R = M.R
	var k = R.kit
	var zf: float = -R.D * 0.5
	var px: float = -31.0
	var pz: float = zf + 2.1
	var sombre: String = _chene(R, true)
	var chene: String = _chene(R, false)
	for sx in [-4.6, 4.6]:
		for sz in [-1.5, 1.5]:
			k.box(R.L(px + sx, 1.7, pz + sz), Vector3(0.7, 3.4, 0.7), sombre, 3.0)
	k.box(R.L(px, 4.7, pz), Vector3(10.5, 2.6, 3.8), chene, 5.0)
	k.box(R.L(px, 6.15, pz), Vector3(10.8, 0.3, 4.0), sombre, 5.0)
	k.col_box(R.L(px, 3.15, pz), Vector3(10.8, 6.3, 4.0))
	k.cyl(R.L(px - 1.5, 6.3, pz), 1.0, 1.35, 1.1, B._tex(R, "terre174", "beau161/terre_cuite.png", Color(1, 1, 1), 0.85), 20)
	_boule(M, B._c(R, "pate174", Color(0.96, 0.9, 0.76), 0.95), Vector3(px - 1.5, 7.35, pz), 1.2, Vector3(1, 0.4, 1))
	k.box(R.L(px - 1.2, 7.55, pz) * Transform3D(Basis(Vector3.BACK, 0.18), Vector3.ZERO), Vector3(2.6, 0.04, 2.8), B._tex(R, "lin174", "beau161/toile_lin.png", Color(0.98, 0.96, 0.9), 0.95), 0.8)
	B._sac(R, px + 2.6, pz + 2.6, Color(0.95, 0.93, 0.88), 7.5)


## Du côté de la porte : le portemanteau (le châle de Mère Mathurine, la veste d'Eustache, le chapeau
## de paille de Pâquerette), les sabots (on dormirait dedans), le parapluie ; sous les fenêtres, le banc
## et le panier de linge plié, le tas de bûches, et les jouets de Pâquerette (des cubes, une toupie).
static func _cote_porte(M) -> void:
	var R = M.R
	var k = R.kit
	var zd: float = R.D * 0.5
	var chene: String = _chene(R, false)
	var sombre: String = _chene(R, true)
	# le portemanteau
	k.box(R.L(7.6, 13.0, zd - 0.15), Vector3(7.0, 0.8, 0.3), sombre, 3.0)
	for i in range(4):
		k.cyl(R.L(5.2 + i * 1.6, 13.0, zd - 0.3) * Transform3D(Basis(Vector3.RIGHT, -PI * 0.5 + 0.35), Vector3.ZERO), 0.16, 0.12, 1.0, chene, 8)
	var tweed: String = B._tex(R, "tweed174", "beau161/tweed.png", Color(0.75, 0.62, 0.5), 0.95)
	var chale: String = B._tex(R, "chale174", "maisons/tissu.png", Color(0.42, 0.22, 0.32), 0.95)
	k.box(R.L(5.2, 9.6, zd - 0.9) * Transform3D(Basis(Vector3.RIGHT, 0.06), Vector3.ZERO), Vector3(3.0, 6.6, 0.7), tweed, 2.0)
	k.box(R.L(5.2, 12.6, zd - 0.95), Vector3(2.2, 0.8, 0.9), tweed, 2.0)
	k.box(R.L(8.4, 10.6, zd - 0.7) * Transform3D(Basis(Vector3.BACK, 0.1), Vector3.ZERO), Vector3(2.4, 4.8, 0.35), chale, 1.5)
	var paille: String = B._tex(R, "paille174", "montjoie/chaume.png", Color(1.25, 1.1, 0.72), 0.95)
	var ch: Transform3D = R.L(10.0, 12.2, zd - 1.4) * Transform3D(Basis(Vector3.RIGHT, 1.25), Vector3.ZERO)
	k.cyl(ch, 1.7, 1.7, 0.08, paille, 24)
	k.cyl(ch, 0.85, 0.75, 0.9, paille, 18)
	k.ring(ch * B.T3(0, 0.12, 0), 0.84, 0.88, 0.3, B._c(R, "ruban174", Color(0.86, 0.22, 0.4), 0.6), 18)
	# les sabots (2,2 m de long), devant la porte
	var sabot: String = B._tex(R, "sabot174", "maisons/bois_meuble.png", Color(1.0, 0.8, 0.58), 0.6)
	for sb in [[5.6, zd - 3.2, 8.0], [7.6, zd - 3.6, -14.0]]:
		var sx: Transform3D = R.L(float(sb[0]), 0.0, float(sb[1]), float(sb[2]))
		k.box(sx * B.T3(0, 0.45, -0.25), Vector3(0.95, 0.9, 1.6), sabot, 2.0)
		_boule(M, sabot, _loc(R, sx, Vector3(0, 0.42, 0.55)), 0.5, Vector3(0.95, 0.85, 1.25))
		k.box(sx * B.T3(0, 0.91, -0.35), Vector3(0.7, 0.02, 1.0), "noir", 1.0, 4)
		k.col_box(sx * B.T3(0, 0.45, 0.0), Vector3(0.95, 0.9, 2.2))
	# le parapluie fermé, appuyé contre le mur
	var pt: Transform3D = R.L(-8.6, 0.0, zd - 0.9) * Transform3D(Basis(Vector3.RIGHT, 0.08), Vector3.ZERO)
	k.cyl(pt * B.T3(0, 0.2, 0), 0.05, 0.5, 6.0, B._c(R, "parapluie174", Color(0.16, 0.2, 0.3), 0.7), 8)
	k.cyl(pt, 0.04, 0.04, 0.2, "fer", 4)
	k.cyl(pt * B.T3(0, 6.2, 0), 0.07, 0.07, 1.2, sombre, 6)
	k.ring(pt * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(-0.25, 7.4, 0)), 0.22, 0.32, 0.1, sombre, 12)
	# le banc sous la fenêtre de droite, le panier de linge plié
	k.box(R.L(-16.0, 3.3, zd - 2.6), Vector3(9.0, 0.3, 2.4), chene, 4.0)
	for sx2 in [-1.0, 1.0]:
		k.box(R.L(-16.0 + sx2 * 3.8, 1.6, zd - 2.6), Vector3(0.45, 3.2, 2.0), sombre, 3.0)
	k.col_box(R.L(-16.0, 1.7, zd - 2.6), Vector3(9.0, 3.45, 2.4))
	var osier: String = B._tex(R, "osier174", "beau161/corde.png", Color(0.78, 0.6, 0.38), 0.95)
	k.box(R.L(-17.2, 4.2, zd - 2.6), Vector3(3.6, 1.5, 2.2), osier, 0.6)
	for j in range(3):
		k.box(R.L(-17.2, 5.0 + j * 0.22, zd - 2.6), Vector3(3.1 - j * 0.3, 0.2, 1.8 - j * 0.2), "tissu_" + ["blanc", "bleu", "creme"][j], 1.5)
	# le tas de bûches, sous la fenêtre de gauche
	var ecorce: String = B._tex(R, "ecorce174", "beau164/ecorce_buche.png", Color(0.82, 0.72, 0.62), 0.95)
	var rang: int = 0
	for nb in [5, 4, 3]:
		for b in range(nb):
			var bx2: float = -33.5 + (b - (nb - 1) * 0.5) * 1.05
			k.cyl(R.L(bx2, 0.5 + rang * 0.9, zd - 3.8) * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 0.5, 0.48, 3.6, ecorce, 10, true, 2.0)
		rang += 1
	k.col_box(R.L(-33.5, 1.4, zd - 2.0), Vector3(5.6, 2.8, 3.6))
	# les jouets de Pâquerette : des cubes de bois peints, une toupie
	var couleurs := [Color(0.85, 0.2, 0.15), Color(0.2, 0.45, 0.8), Color(0.95, 0.75, 0.2), Color(0.3, 0.62, 0.3)]
	var cubes := [[14.0, zd - 4.0, 0.0, 10.0], [14.66, zd - 4.1, 0.0, -5.0], [14.3, zd - 4.05, 0.62, 20.0], [15.9, zd - 5.4, 0.0, 33.0], [13.2, zd - 6.2, 0.0, 47.0]]
	for i3 in range(cubes.size()):
		var cu: Array = cubes[i3]
		k.box(R.L(float(cu[0]), float(cu[2]) + 0.31, float(cu[1]), float(cu[3])), Vector3(0.62, 0.62, 0.62), B._c(R, "cube174_%d" % (i3 % 4), couleurs[i3 % 4], 0.5), 1.0)
		k.col_box(R.L(float(cu[0]), float(cu[2]) + 0.31, float(cu[1]), float(cu[3])), Vector3(0.62, 0.62, 0.62))
	var tp: Transform3D = R.L(17.2, 0.0, zd - 7.0) * Transform3D(Basis(Vector3.BACK, 0.35), Vector3.ZERO)
	k.cyl(tp, 0.02, 0.7, 0.55, B._c(R, "toupie174", Color(0.86, 0.3, 0.2), 0.4), 16)
	k.cyl(tp * B.T3(0, 0.55, 0), 0.7, 0.45, 0.25, B._c(R, "toupie174_b", Color(0.95, 0.85, 0.3), 0.4), 16)
	k.cyl(tp * B.T3(0, 0.8, 0), 0.06, 0.06, 0.45, chene, 6)


## Le fauteuil à oreilles de Grand-mère Ernestine, près du feu ; le panier à tricot et ses pelotes ;
## et l'écharpe sans fin, qui descend du fauteuil, traverse la salle en serpentant et sort sous la
## porte (« elle fait le tour de la maison, deux fois ») : chaque rang a sa couleur (le rang rouge, le
## jour où Pâquerette est née ; le bleu, le jour où tu es arrivé).
static func _fauteuil_echarpe(M) -> void:
	var R = M.R
	var k = R.kit
	var fx: Transform3D = R.L(-24.0, 0.0, -1.0, -115.0)
	var velours: String = B._tex(R, "velours174", "maisons/tissu.png", Color(0.62, 0.3, 0.26), 0.95)
	var sombre: String = _chene(R, true)
	for lx in [-2.4, 2.4]:
		for lz in [-2.2, 2.2]:
			k.cyl(fx * B.T3(lx, 0.0, lz), 0.22, 0.3, 2.2, sombre, 8)
	k.box(fx * B.T3(0, 2.8, 0), Vector3(6.0, 1.2, 5.4), velours, 2.0)
	k.box(fx * B.T3(0, 3.75, 0.3), Vector3(5.0, 0.7, 4.6), velours, 2.0)
	k.box(fx * B.T3(0, 6.4, -2.2), Vector3(6.0, 6.0, 1.2), velours, 2.0)
	for s in [-1.0, 1.0]:
		k.box(fx * B.T3(s * 2.65, 7.7, -1.3), Vector3(0.9, 3.4, 2.4), velours, 2.0)
		k.box(fx * B.T3(s * 2.75, 4.3, 0.2), Vector3(0.9, 1.8, 5.0), velours, 2.0)
		_boule(M, velours, _loc(R, fx, Vector3(s * 2.75, 5.2, 2.5)), 0.55, Vector3(0.9, 0.5, 0.6))
	# les arrondis : le bord du siège, le haut du dossier, le capitonnage
	k.cyl(fx * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(3.0, 2.8, 2.7)), 0.6, 0.6, 6.0, velours, 14)
	k.cyl(fx * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(3.0, 9.35, -2.2)), 0.62, 0.62, 6.0, velours, 14)
	var bouton: String = B._c(R, "bouton_velours174", Color(0.42, 0.18, 0.16), 0.7)
	for bx in [-1.8, 0.0, 1.8]:
		for by in [5.0, 6.6, 8.2]:
			_boule(M, bouton, _loc(R, fx, Vector3(bx + (0.9 if by == 6.6 else 0.0), by, -1.58)), 0.12, Vector3(1, 1, 0.5))
	k.col_box(fx * B.T3(0, 4.0, -0.2), Vector3(6.4, 8.0, 5.6))
	var cols := {"rouge": Color(0.72, 0.16, 0.16), "creme": Color(0.94, 0.88, 0.74), "bleu": Color(0.22, 0.38, 0.72), "vert": Color(0.3, 0.52, 0.32),
		"ocre": Color(0.86, 0.6, 0.22), "rose": Color(0.9, 0.55, 0.62), "violet": Color(0.46, 0.3, 0.55)}
	var laines: Dictionary = {}
	for c in cols:
		laines[c] = B._tex(R, "laine174_" + c, T + "laine.png", cols[c], 0.98)
	# les pelotes sur le coussin, les aiguilles plantées dans la rouge
	for pl in [[-1.2, 4.55, 0.6, "creme", 0.8], [0.9, 4.5, 1.0, "rouge", 0.75], [0.0, 4.4, -0.6, "vert", 0.6]]:
		_boule(M, str(laines[str(pl[3])]), _loc(R, fx, Vector3(float(pl[0]), float(pl[1]), float(pl[2]))), float(pl[4]))
	for s2 in [-1.0, 1.0]:
		k.cyl(fx * Transform3D(Basis(Vector3.BACK, s2 * 0.5) * Basis(Vector3.RIGHT, 0.3), Vector3(0.9, 4.6, 1.0)), 0.07, 0.05, 3.0, "argent", 6)
	# le panier à tricot, ses pelotes ; une pelote qui a roulé, et son fil
	var osier: String = B._tex(R, "osier174", "beau161/corde.png", Color(0.78, 0.6, 0.38), 0.95)
	var px: Vector3 = _loc(R, fx, Vector3(-4.9, 0.0, 1.2))
	k.cyl(R.L(px.x, 0.0, px.z), 1.5, 1.7, 1.8, osier, 18, true, 0.5)
	k.col_cyl(R.P(px.x, 0.0, px.z), 1.7, 1.8)
	var ip: int = 0
	for c2 in ["bleu", "ocre", "rose", "violet"]:
		var ap: float = TAU * ip / 4.0
		_boule(M, str(laines[c2]), Vector3(px.x + cos(ap) * 0.65, 2.15, px.z + sin(ap) * 0.65), 0.7)
		ip += 1
	var roule := Vector3(px.x + 4.5, 0.62, px.z + 2.4)
	_boule(M, str(laines["ocre"]), roule, 0.62)
	var d: Vector3 = roule - Vector3(px.x, 2.0, px.z)
	k.cyl(R.L(px.x, 2.0, px.z) * Transform3D(Basis.looking_at(d.normalized(), Vector3.UP) * Basis(Vector3.RIGHT, -PI * 0.5), Vector3.ZERO), 0.03, 0.03, d.length(), str(laines["ocre"]), 4)
	# l'écharpe : du coussin au sol, puis en serpentant jusque sous la porte
	var p_seat: Vector3 = _loc(R, fx, Vector3(0.0, 4.15, 2.1))
	var p_bas: Vector3 = _loc(R, fx, Vector3(0.0, 0.07, 4.2))
	var pts: Array = [p_seat, p_bas, Vector3(-30.6, 0.07, 0.6), Vector3(-29.0, 0.07, 5.8), Vector3(-22.0, 0.07, 8.8), Vector3(-15.0, 0.07, 10.8), Vector3(-9.6, 0.07, 13.6),
		Vector3(-6.4, 0.07, 17.6), Vector3(-4.6, 0.07, 21.0), Vector3(-4.2, 0.07, 24.2)]
	var lisse: Array = []
	for i in range(pts.size() - 1):
		var p0: Vector3 = pts[maxi(i - 1, 0)]
		var p1: Vector3 = pts[i]
		var p2: Vector3 = pts[i + 1]
		var p3: Vector3 = pts[mini(i + 2, pts.size() - 1)]
		var nseg: int = maxi(2, int(p1.distance_to(p2) / 0.9))
		for j in range(nseg):
			var t: float = float(j) / nseg
			var t2: float = t * t
			var t3: float = t2 * t
			lisse.append(0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3))
	lisse.append(pts[pts.size() - 1])
	var bandes := ["creme", "rouge", "creme", "vert", "ocre", "creme", "bleu", "rose", "creme", "violet", "vert", "creme", "ocre", "rouge"]
	var long: float = 0.0
	for i2 in range(lisse.size() - 1):
		var a: Vector3 = lisse[i2]
		var b: Vector3 = lisse[i2 + 1]
		var dl: Vector3 = b - a
		var lg: float = dl.length()
		if lg < 0.01:
			continue
		var bs: Basis = Basis.looking_at(dl / lg, Vector3.UP)
		var cle: String = str(laines[bandes[int(long / 2.6) % bandes.size()]])
		k.box(Transform3D(bs, R.P((a.x + b.x) * 0.5, (a.y + b.y) * 0.5, (a.z + b.z) * 0.5)), Vector3(2.4, 0.14, lg + 0.12), cle, 0.7)
		long += lg
	var regarder := func() -> void:
		M.say("L'écharpe de Grand-mère Ernestine : elle descend du fauteuil, traverse la salle et passe sous la porte. Une maille à l'endroit, une maille à l'envers… Le rang bleu, là, c'est le jour où tu es arrivé.", 8.0)
	M.act(R.P(-30.4, 0.0, 3.4), "E : regarder l'écharpe de Grand-mère", regarder, 2.6)


## Aux murs : le calendrier de la ferme, le dessin de Pâquerette punaisé à sa hauteur (« MON TOUT PETIT
## AMI »), l'étagère des confitures, les casseroles de cuivre pendues, le trou de souris dans la plinthe.
static func _aux_murs(M) -> void:
	var R = M.R
	var k = R.kit
	var hw: float = R.W * 0.5
	var zf: float = -R.D * 0.5
	var cal: String = B._img(R, "calendrier174", T + "calendrier.png")
	var cx: Transform3D = R.L(hw - 0.05, 10.5, 14.0, -90.0)
	k.quad(cx * Transform3D(Basis(Vector3.UP, PI), Vector3.ZERO), 2.6, 3.9, cal)
	k.cyl(cx * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 1.75, 0)), 0.06, 0.06, 0.3, "fer", 6)
	var des: String = B._img(R, "dessin174", T + "dessin_paquerette.png")
	var dx: Transform3D = R.L(-9.0, 6.2, zf + 0.04, 0.0)
	k.quad(dx * Transform3D(Basis(Vector3.UP, PI), Vector3.ZERO), 3.8, 2.77, des)
	for p in [[-1.75, 1.25], [1.75, 1.25], [-1.75, -1.25], [1.75, -1.25]]:
		_boule(M, B._c(R, "punaise174", Color(0.86, 0.2, 0.2), 0.3, 0.3), _loc(R, dx, Vector3(float(p[0]), float(p[1]), 0.06)), 0.11, Vector3(1, 1, 0.5))
	var voir := func() -> void:
		M.say("Un dessin aux craies grasses : la maison au toit rouge, la famille Grandpré qui sourit, le soleil… et, tout petit dans l'herbe, avec une flèche rouge : « MON TOUT PETIT AMI ». C'est toi.", 7.0)
	M.act(R.P(-9.0, 0.0, zf + 3.6), "E : regarder le dessin de Pâquerette", voir, 2.2)
	# l'étagère des confitures (au pignon de droite)
	var ex: Transform3D = R.L(hw - 0.95, 11.0, -3.5, -90.0)
	var chene: String = _chene(R, false)
	k.box(ex, Vector3(7.5, 0.3, 1.9), chene, 4.0)
	for s in [-1.0, 1.0]:
		k.box(ex * Transform3D(Basis(Vector3.RIGHT, 0.8), Vector3(s * 3.2, -0.8, -0.3)), Vector3(0.3, 1.8, 0.3), chene, 2.0)
	var vichy: String = B._tex(R, "vichy174", T + "vichy_rouge.png", Color(1, 1, 1), 0.92)
	var confs := [Color(0.72, 0.1, 0.16), Color(0.95, 0.55, 0.12), Color(0.42, 0.12, 0.3), Color(0.86, 0.72, 0.2), Color(0.72, 0.1, 0.16)]
	for j in range(5):
		var jx: Transform3D = ex * B.T3(-3.0 + j * 1.5, 0.15, 0.0)
		k.cyl(jx, 0.46, 0.46, 0.9, B._verre(R, "confiture174_%d" % j, confs[j], 0.88), 16)
		k.cyl(jx * B.T3(0, 0.9, 0), 0.6, 0.55, 0.07, vichy, 16, true, 0.6)
	# les casseroles de cuivre, au pignon de gauche (près de la porte)
	var cu: Transform3D = R.L(-hw + 0.3, 12.5, 16.0, 90.0)
	k.box(cu, Vector3(8.0, 0.3, 0.3), "fer", 1.0)
	for c in range(4):
		var r: float = 0.85 + 0.15 * c
		var hx: Transform3D = cu * B.T3(-2.8 + c * 1.9, -0.2, 0.25)
		k.cyl(hx * B.T3(0, -0.5, 0), 0.04, 0.04, 0.5, "fer", 4)
		k.box(hx * B.T3(0, -1.7 - r * 0.0, 0.0), Vector3(0.25, 2.2, 0.1), "cuivre", 1.0)
		k.cyl(hx * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, -2.8 - r, 0.05)), r, r, 0.45, "cuivre", 20)
	# le trou de souris, dans la plinthe du pignon de droite
	var tr: Transform3D = R.L(hw - 0.3, 0.0, zf + 3.5, -90.0)
	k.box(tr * B.T3(0, 0.3, 0.02), Vector3(0.9, 0.6, 0.02), "noir", 1.0, 16)
	k.cyl(tr * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0.6, 0.02)), 0.45, 0.45, 0.02, "noir", 14)


## Au plafond : la suspension émaillée au-dessus de la table, les tresses d'oignons et d'ail, les
## bouquets d'herbes qui sèchent.
static func _au_plafond(M) -> void:
	var R = M.R
	var k = R.kit
	var email: String = B._c(R, "email174", Color(0.93, 0.93, 0.9), 0.28)
	var ys: float = R.H - 4.3
	for c in range(10):
		k.ring(R.L(4.0, ys - 0.6 - c * 0.4, -2.0) * Transform3D(Basis(Vector3.UP, PI * 0.5 * float(c % 2)) * Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 0.1, 0.16, 0.06, "fer", 8)
	k.cyl(R.L(4.0, ys - 5.6, -2.0), 2.3, 0.45, 1.2, email, 24)
	k.cyl(R.L(4.0, ys - 4.6, -2.0), 0.3, 0.3, 0.45, "fer", 10)
	_boule(M, B._verre(R, "ampoule174", Color(0.98, 0.95, 0.85), 0.5), Vector3(4.0, ys - 5.45, -2.0), 0.45)
	var oignon: String = B._c(R, "oignon174", Color(0.78, 0.52, 0.26), 0.6)
	var ail: String = B._c(R, "ail174", Color(0.95, 0.92, 0.85), 0.7)
	var corde: String = B._tex(R, "corde174", "beau161/corde.png", Color(0.8, 0.7, 0.5), 0.9)
	for t in range(3):
		var ox: float = -30.0 + t * 2.6
		var oz: float = -2.0 + 1.6
		k.cyl(R.L(ox, R.H - 9.5, oz), 0.06, 0.06, 6.4, corde, 5)
		for o in range(8):
			_boule(M, oignon if t != 1 else ail, Vector3(ox + 0.28 * float(o % 2) - 0.14, R.H - 9.0 + o * 0.62, oz + 0.2 * float(o % 3 - 1)), 0.4 if t != 1 else 0.32, Vector3(1, 1.15, 1))
	var herbe: String = B._c(R, "herbes174", Color(0.42, 0.48, 0.28), 0.9)
	for h in range(4):
		var hx: float = 12.0 + h * 4.5
		k.cyl(R.L(hx, R.H - 6.2, -0.7), 0.05, 0.05, 2.2, corde, 4)
		k.cyl(R.L(hx, R.H - 8.6, -0.7), 0.85, 0.25, 2.4, herbe, 10)


## Par terre : des miettes sous la table, un bouton perdu, une épingle, trois billes.
static func _par_terre(M) -> void:
	var R = M.R
	var k = R.kit
	var miette: String = B._c(R, "miette174", Color(0.86, 0.68, 0.42), 0.95)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1742
	for i in range(14):
		_boule(M, miette, Vector3(rng.randf_range(-4.0, 12.0), 0.08, rng.randf_range(-5.0, 1.0)), rng.randf_range(0.08, 0.24), Vector3(1.0, 0.7, 0.9))
	k.cyl(R.L(9.0, 0.0, -14.5), 0.36, 0.36, 0.07, B._c(R, "bouton174_b", Color(0.2, 0.3, 0.5), 0.4), 18)
	for h in range(4):
		_boule(M, "noir", Vector3(9.0 + (0.08 if h % 2 == 0 else -0.08), 0.075, -14.5 + (0.08 if h < 2 else -0.08)), 0.03)
	k.cyl(R.L(-12.0, 0.03, 4.0) * Transform3D(Basis(Vector3.BACK, PI * 0.5) * Basis(Vector3.RIGHT, 0.6), Vector3.ZERO), 0.012, 0.012, 0.55, "argent", 4)
	_boule(M, B._c(R, "tete_epingle174", Color(0.2, 0.62, 0.3), 0.3), Vector3(-12.0, 0.04, 4.0), 0.05)
	for b in [[13.6, 3.2, Color(0.9, 0.3, 0.2)], [15.1, 4.6, Color(0.3, 0.75, 0.4)], [12.4, 5.0, Color(0.95, 0.85, 0.3)]]:
		_boule(M, B._verre(R, "bille174_%s" % (b[2] as Color).to_html(false), b[2], 0.7), Vector3(float(b[0]), 0.15, float(b[1])), 0.15)


## Tante Brindille, une Petite qui habite sous le vaisselier (les Grandpré le savent) : elle reçoit,
## raconte, offre une miette ; le soir, toute la maison dort (on entend ronfler là-haut).
static func _brindille(M) -> void:
	var R = M.R
	var miette := func() -> void:
		M.say("Tante Brindille te tend une miette de brioche sur un bouton de nacre : « La part du jour. Mère Mathurine en laisse une au bord de la table chaque matin. Une, c'est ma semaine ! »", 7.0)
	var bille := func() -> void:
		M.say("Gustave brille sous le vaisselier, bleu comme un bout de ciel, avec sa spirale blanche dedans. « Elle a roulé jusqu'ici. Je la garde au chaud : Pâquerette viendra la chercher. »", 7.0)
	B._marchand(M, 1.4, -R.D * 0.5 + 4.7, 0.0, "debout", "femme", "Tante Brindille",
		["Les Grandpré savent que je suis là. Mère Mathurine me laisse une miette chaque matin, au bord de la table.",
			"Pompon ne me mange pas : il me trouve trop petite pour être un repas, et trop bavarde pour être une souris.",
			"L'escalier de livres, contre la chaise, c'est moi qui l'ai fait. Monte sur la table : de là-haut, la vue est belle.",
			"Écoute l'horloge : tic… … tac. Ici, une seconde, c'est le temps de faire trois pas."],
		{"bonjour": "Oh ! Un Petit ! Entre, entre… et parle doucement : ici, un éternuement fait trembler la vaisselle.",
			"services": [{"label": "Prendre une miette de brioche", "cb": miette}, {"label": "Voir Gustave, la bille de Pâquerette", "cb": bille}],
			"infos": ["Je suis arrivée par le ponton, il y a des années. Je me suis perdue dans le potager ; Pâquerette m'a trouvée dans un chou. Depuis, j'habite sous le vaisselier.",
				"Mon lit ? Une boîte de sardines. Mère Mathurine déteste les sardines : elle a jeté la boîte, je l'ai gardée. Avec un mouchoir pour couverture, j'y dors comme une reine.",
				"L'écharpe de Grand-mère sort sous la porte et fait le tour de la maison. Deux fois. Chaque rang est un souvenir.",
				"Le moulin d'Eustache ? Va voir Pépin : il habite dedans, près de la meule. Il fait le meilleur pain des Petits, avec la farine qui tombe des sacs."]})
	M.ctx["cloche170"] = false
	M.ctx["bonjour170"] = ["Bienvenue chez les Grandpré ! Enfin… chez moi, en dessous.", "Tu as vu la taille des bols ? Je m'y suis baignée, une fois. Chut."]
	M.ctx["bonjour_nuit170"] = ["Chut… toute la maison dort. Tu entends ? C'est Père Eustache qui ronfle, là-haut. Les vitres tremblent.", "Tu viens tard ! Moi, je ne dors pas avant que Pompon ronronne."]
	if R.day:
		M.ctx["entree"] = "La maison des Grandpré, à hauteur de Petit : la table haute comme une maison, des bols où l'on pourrait se baigner, la grande cheminée, l'horloge qui bat lentement, Pompon le chat qui dort devant le feu… et, sous le vaisselier, chez Tante Brindille."
	else:
		M.ctx["entree"] = "La maison des Grandpré, la nuit : les braises rougeoient, l'horloge bat lentement, et là-haut, toute la famille ronfle. Sous le vaisselier, une petite flamme : Tante Brindille veille."


# =================================================================== le Moulin de la Butte

## La coque du moulin : une tour ronde (11,4 m de rayon ; 22 m jusqu'au plancher du dessus), le
## soubassement de moellons, l'enduit blanchi (et farineux) ; le plancher, le plafond et ses solives
## (la trappe aux sacs) ; le trou de souris par où l'on entre ; la grande porte verte, vue de dedans (le
## jour passe autour) ; la fenêtre haute et son rayon de soleil.
static func _coque_moulin(M) -> void:
	var R = M.R
	var k = R.kit
	_sol_plafond(M)
	var r: float = 11.4
	var n: int = 40
	var tm: float = float((R.pal["mur"] as Array)[2])
	var tb: float = float((R.pal["bas"] as Array)[2])
	var yb: float = 2.6
	# la fenêtre haute : son angle, sa demi-largeur (en angle), sa hauteur
	var af: float = deg_to_rad(-140.0) + TAU
	var fw: float = (3.6 * 0.5) / r
	var fy0: float = 14.5
	var fy1: float = 19.5
	for i in range(n):
		var a0: float = TAU * i / n
		var a1: float = TAU * (i + 1) / n
		var p0 := Vector3(sin(a0) * r, 0, cos(a0) * r)
		var p1 := Vector3(sin(a1) * r, 0, cos(a1) * r)
		var nm := -Vector3(sin((a0 + a1) * 0.5), 0, cos((a0 + a1) * 0.5))
		# (le morceau de mur où s'ouvre la fenêtre : coupé autour d'elle)
		var morceaux: Array = [[a0, a1, false]]
		if a1 > af - fw and a0 < af + fw:
			morceaux = []
			if a0 < af - fw:
				morceaux.append([a0, af - fw, false])
			morceaux.append([maxf(a0, af - fw), minf(a1, af + fw), true])
			if a1 > af + fw:
				morceaux.append([af + fw, a1, false])
		for mo in morceaux:
			var b0: float = mo[0]
			var b1: float = mo[1]
			var q0: Vector3 = p0.lerp(p1, (b0 - a0) / (a1 - a0))
			var q1: Vector3 = p0.lerp(p1, (b1 - a0) / (a1 - a0))
			var u0: float = b0 * r
			var u1: float = b1 * r
			var bandes: Array = [[0.0, yb, "bas", tb], [yb, R.H, "mur", tm]]
			if bool(mo[2]):
				bandes = [[0.0, yb, "bas", tb], [yb, fy0, "mur", tm], [fy1, R.H, "mur", tm]]
			for band in bandes:
				var y0: float = band[0]
				var y1: float = band[1]
				var key: String = band[2]
				var tile: float = band[3]
				k.quad4(key, R.P(q0.x, y0, q0.z), R.P(q1.x, y0, q1.z), R.P(q1.x, y1, q1.z), R.P(q0.x, y1, q0.z), nm,
					Vector2(u0 / tile, -y0 / tile), Vector2(u1 / tile, -y0 / tile), Vector2(u1 / tile, -y1 / tile), Vector2(u0 / tile, -y1 / tile))
		var am: float = (a0 + a1) * 0.5
		k.col_box(R.L(sin(am) * (r + 0.6), R.H * 0.5, cos(am) * (r + 0.6), rad_to_deg(am)), Vector3(2.0 * (r + 0.6) * tan(PI / n) + 0.3, R.H + 2.0, 1.2))
	# la corniche du soubassement
	k.ring(R.L(0, yb - 0.1, 0), r - 0.25, r + 0.01, 0.2, "bas", n)
	# le plafond : les solives (deux grosses poutres en croix, des solives), la trappe aux sacs
	var poutre: String = B._tex(R, "poutre174", "montjoie/bois_planches.png", Color(0.5, 0.38, 0.28), 0.8)
	k.box(R.L(0, R.H - 1.3, 0), Vector3(r * 2.0, 2.4, 2.2), poutre, 8.0)
	for j in range(-4, 5):
		if j == 0:
			continue
		var zj: float = j * 2.5
		var lj: float = 2.0 * sqrt(maxf(0.0, r * r - zj * zj))
		k.box(R.L(0, R.H - 0.6, zj), Vector3(lj, 1.1, 0.9), poutre, 6.0)
	k.box(R.L(6.4, R.H - 0.02, -0.6), Vector3(3.6, 0.04, 3.6), "noir", 1.0, 8)
	for s in [-1.0, 1.0]:
		k.box(R.L(6.4 + s * 1.8, R.H - 0.9, -0.6) * Transform3D(Basis(Vector3.BACK, s * 0.5), Vector3.ZERO), Vector3(0.2, 1.8, 3.6), poutre, 3.0)
	# le trou de souris (par où l'on est entré) : une arche sombre, le jour au bout
	var trou: Transform3D = R.L(0, 0, r - 0.03, 180.0)
	var jour: String = B._c(R, "dehors174_j" if R.day else "dehors174_n", Color(1.0, 0.94, 0.8) if R.day else Color(0.1, 0.13, 0.25), 0.9, 0.0, 1.6 if R.day else 0.6)
	k.box(trou * B.T3(0, 0.55, 0.0), Vector3(1.2, 1.1, 0.02), jour, 1.0, 16)
	k.cyl(trou * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 1.1, -0.01)), 0.6, 0.6, 0.02, jour, 16)
	var rong: String = B._c(R, "ronge174", Color(0.86, 0.82, 0.74), 0.95)
	for g in range(9):
		var ag: float = PI * (0.1 + 0.8 * g / 8.0)
		_boule(M, rong, _loc(R, trou, Vector3(cos(ag) * 0.66, 1.1 + sin(ag) * 0.66 - (0.0 if g > 0 and g < 8 else 0.4), -0.05)), 0.12, Vector3(1.2, 0.8, 0.5))
	# la grande porte verte (vue de dedans), le jour qui passe autour
	var ap: float = deg_to_rad(68.0)
	var porte: Transform3D = R.L(sin(ap) * (r - 0.35), 0, cos(ap) * (r - 0.35), rad_to_deg(ap) + 180.0)
	var vert: String = B._tex(R, "porte174", "beau161/bois_peint.png", Color(0.42, 0.66, 0.48), 0.7)
	k.box(porte * B.T3(0, 6.2, 0), Vector3(6.4, 12.4, 0.6), vert, 4.0)
	for yv in [2.0, 6.2, 10.4]:
		k.box(porte * B.T3(0, yv, 0.42), Vector3(6.0, 0.9, 0.3), vert, 4.0)
	k.box(porte * B.T3(2.4, 6.2, 0.62), Vector3(0.25, 1.2, 0.25), "fer", 1.0)
	if R.day:
		k.box(porte * B.T3(0, 12.45, 0.31), Vector3(6.4, 0.1, 0.02), jour, 1.0, 16)
		for s2 in [-1.0, 1.0]:
			k.box(porte * B.T3(s2 * 3.22, 6.2, 0.31), Vector3(0.06, 12.4, 0.02), jour, 1.0, 16)
		k.box(porte * B.T3(0, 0.03, 0.9), Vector3(6.4, 0.02, 1.0), jour, 1.0, 4)
	# la fenêtre haute (la vue sur la ferme), son ébrasement, son rayon de soleil
	var fen: Transform3D = R.L(sin(af) * (r - 0.02), 0, cos(af) * (r - 0.02), rad_to_deg(af) + 180.0)
	_ebrasement(M, fen, [0.0, 3.6, fy0, fy1 - fy0, 1.6, "fenetre", "vue_moulin", true])
	# les lumières
	if R.day:
		_omni(M, Vector3(0, 12.0, 0), Color(1.0, 0.96, 0.88), 0.7, 32.0)
		_omni(M, Vector3(sin(ap) * (r - 3.0), 4.0, cos(ap) * (r - 3.0)), Color(1.0, 0.94, 0.82), 0.55, 14.0)
		var fp: Vector3 = _loc(R, fen, Vector3(0, 17.0, -6.0))
		_soleil(M, fp, Vector3(fp.x * -0.25, 0.0, fp.z * -0.25), 13.0, 6.0)
	else:
		_omni(M, Vector3(0, 12.0, 0), Color(0.6, 0.66, 0.85), 0.15, 32.0)
		_omni(M, _loc(R, fen, Vector3(0, 16.0, 3.0)), Color(0.55, 0.62, 0.9), 0.3, 18.0)


## Dedans : la meule dans sa cuve, la trémie et l'auget, le grand arbre et son rouet, la lanterne ; la
## huche à farine et la farine qui coule ; les sacs de géant, debout et couchés ; l'échelle de meunier ;
## la chaîne du monte-sacs ; la farine et le grain par terre, les souris ; le fournil de Pépin.
static func _moulin_butte(M) -> void:
	var R = M.R
	var k = R.kit
	M.ctx["tick170"] = func(delta: float) -> void:
		_tick(M, delta)
	var chene: String = _chene(R, false)
	var sombre: String = _chene(R, true)
	var poutre: String = B._tex(R, "poutre174", "montjoie/bois_planches.png", Color(0.5, 0.38, 0.28), 0.8)
	var farine: String = B._c(R, "farine174", Color(0.97, 0.96, 0.93), 0.98)
	var ble: String = B._c(R, "ble174", Color(0.86, 0.68, 0.34), 0.7)
	# la cuve de la meule (l'archure à douze pans), son couvercle, l'œil
	var mz: float = -3.6
	k.cyl(R.L(0, 0, mz), 4.4, 4.4, 4.2, chene, 12, true, 3.0)
	for yc in [0.6, 2.2, 3.9]:
		k.ring(R.L(0, yc, mz), 4.38, 4.52, 0.22, "fer", 12)
	k.col_cyl(R.P(0, 0, mz), 4.5, 4.3)
	k.cyl(R.L(0, 4.2, mz), 0.9, 0.9, 0.06, "noir", 16)
	# le chevalet et la trémie, l'auget (il tremble : le « babillard »)
	var hx: float = -2.6
	var hz: float = -6.0
	for lx in [-1.6, 1.6]:
		for lz in [-1.6, 1.6]:
			k.box(R.L(hx + lx, 5.3, hz + lz), Vector3(0.4, 2.2, 0.4), sombre, 2.0)
	k.box(R.L(hx, 6.4, hz), Vector3(3.8, 0.3, 3.8), sombre, 3.0)
	for side in range(4):
		var rot: Basis = Basis(Vector3.UP, PI * 0.5 * side)
		var a := rot * Vector3(-0.45, 6.6, 0.45)
		var b := rot * Vector3(0.45, 6.6, 0.45)
		var c := rot * Vector3(2.3, 10.4, 2.3)
		var d := rot * Vector3(-2.3, 10.4, 2.3)
		var nn: Vector3 = (rot * Vector3(0, -0.43, 0.9)).normalized()
		k.quad4(chene, R.P(hx + a.x, a.y, hz + a.z), R.P(hx + b.x, b.y, hz + b.z), R.P(hx + c.x, c.y, hz + c.z), R.P(hx + d.x, d.y, hz + d.z), nn, Vector2(0, 1.4), Vector2(0.3, 1.4), Vector2(1.6, 0), Vector2(-1.0, 0))
		k.quad4(chene, R.P(hx + a.x, a.y, hz + a.z), R.P(hx + b.x, b.y, hz + b.z), R.P(hx + c.x, c.y, hz + c.z), R.P(hx + d.x, d.y, hz + d.z), -nn, Vector2(0, 1.4), Vector2(0.3, 1.4), Vector2(1.6, 0), Vector2(-1.0, 0))
	k.box(R.L(hx, 10.2, hz), Vector3(4.4, 0.04, 4.4), ble, 1.0, 4)
	var auget := _noeud(M, "Auget", R.L(hx + 0.4, 6.3, hz + 0.5))
	var dir_a: Vector3 = Vector3(-0.4 - (hx + 0.4), 4.7 - 6.3, mz - 0.2 - (hz + 0.5))
	var aug_mesh := MeshInstance3D.new()
	aug_mesh.mesh = B._boitem(0.8, 0.25, dir_a.length())
	aug_mesh.material_override = R.mat(chene)
	auget.add_child(aug_mesh)
	aug_mesh.transform = Transform3D(Basis.looking_at(dir_a.normalized(), Vector3.UP), dir_a * 0.5)
	(M.ctx["anims170"] as Array).append([auget, "balance", 0.025, 13.0])
	_grains(M, R.P(-0.4, 4.75, mz - 0.2), 4.4, ble)
	# l'arbre et le rouet (un nœud qui tourne) ; la lanterne et le fer de meule (plus vite, à l'envers)
	var ax: float = 0.0
	var az: float = 2.6
	var rouet := _noeud(M, "Rouet", R.L(ax, 0, az))
	var mp: Material = R.mat(poutre)
	var mf: Material = R.mat("fer")
	_bout(rouet, B._cylm(1.1, 1.1, R.H, 8), mp, Vector3(0, R.H * 0.5, 0))
	for yf in [1.0, 6.0, 13.6, 16.4, 20.0]:
		_bout(rouet, B._cylm(1.16, 1.16, 0.3, 8), mf, Vector3(0, yf, 0))
	var yr: float = 15.0
	var rr: float = 5.0
	var nseg: int = 24
	for i in range(nseg):
		var t: float = TAU * (i + 0.5) / nseg
		var seg := _bout(rouet, B._boitem(2.0 * rr * sin(PI / nseg) + 0.05, 1.0, 0.8), mp, Vector3(cos(t) * rr, yr, sin(t) * rr))
		seg.rotation.y = -t + PI * 0.5
	for j in range(4):
		var tb: float = PI * 0.25 * j
		var bras := _bout(rouet, B._boitem(rr * 2.0, 0.7, 0.55), mp, Vector3(0, yr - 0.1, 0))
		bras.rotation.y = tb
	var ndent: int = 44
	for i2 in range(ndent):
		var t2: float = TAU * i2 / ndent
		var dent := _bout(rouet, B._boitem(0.5, 0.75, 0.32), mp, Vector3(cos(t2) * (rr + 0.62), yr + 0.15, sin(t2) * (rr + 0.62)))
		dent.rotation.y = -t2
	(M.ctx["anims170"] as Array).append([rouet, "tourne", Vector3.UP, 0.15])
	var lant := _noeud(M, "Lanterne", R.L(0, 0, mz))
	_bout(lant, B._cylm(0.2, 0.2, 16.2 - 4.2, 8), mf, Vector3(0, 4.2 + (16.2 - 4.2) * 0.5, 0))
	var ly: float = yr + 0.15
	for yd in [ly - 0.55, ly + 0.55]:
		_bout(lant, B._cylm(1.05, 1.05, 0.22, 20), mp, Vector3(0, yd, 0))
	for f in range(10):
		var tf: float = TAU * f / 10.0
		_bout(lant, B._cylm(0.1, 0.1, 1.1, 8), mp, Vector3(cos(tf) * 0.86, ly, sin(tf) * 0.86))
	(M.ctx["anims170"] as Array).append([lant, "tourne", Vector3.UP, -0.15 * (rr + 0.62) / 0.86])
	# la huche à farine, l'anche (le bec) et la farine qui coule
	var hu: Vector3 = Vector3(7.2, 0, mz)
	k.box(R.L(hu.x, 1.3, hu.z), Vector3(3.2, 2.6, 3.4), chene, 3.0)
	k.box(R.L(hu.x, 2.62, hu.z), Vector3(2.8, 0.04, 3.0), farine, 1.0, 4)
	_boule(M, farine, Vector3(hu.x - 0.2, 2.6, hu.z), 1.2, Vector3(1.0, 0.35, 1.0))
	k.col_box(R.L(hu.x, 1.3, hu.z), Vector3(3.2, 2.6, 3.4))
	var bec_a := Vector3(4.3, 3.4, mz)
	var bec_b := Vector3(6.4, 3.0, mz)
	var db: Vector3 = bec_b - bec_a
	k.box(Transform3D(Basis.looking_at(db.normalized(), Vector3.UP), R.P((bec_a.x + bec_b.x) * 0.5, (bec_a.y + bec_b.y) * 0.5, mz)), Vector3(0.7, 0.5, db.length()), sombre, 1.0)
	_farine_qui_coule(M, R.P(bec_b.x + 0.1, bec_b.y - 0.1, mz), 0.35)
	# les sacs de géant (5,6 m), debout et couchés
	for sg in [[7.4, 5.6, 20.0], [9.2, 0.6, 140.0], [4.2, -8.2, -30.0], [-6.9, -6.0, 70.0]]:
		_sac_geant(M, Vector3(float(sg[0]), 0, float(sg[1])), float(sg[2]), false)
	_sac_geant(M, Vector3(-8.9, 0, 0.4), 180.0, true)
	# l'échelle de meunier, contre le mur, jusqu'à la trappe du plancher du dessus
	var ex: Transform3D = R.L(sin(deg_to_rad(205.0)) * 8.5, 0, cos(deg_to_rad(205.0)) * 8.5, 205.0) * Transform3D(Basis(Vector3.RIGHT, 0.12), Vector3.ZERO)
	k.box(R.L(sin(deg_to_rad(205.0)) * 10.0, R.H - 0.02, cos(deg_to_rad(205.0)) * 10.0, 205.0), Vector3(4.4, 0.04, 2.6), "noir", 1.0, 8)
	for s in [-1.6, 1.6]:
		k.box(ex * B.T3(s, R.H * 0.52, 0), Vector3(0.5, R.H * 1.05, 0.35), sombre, 3.0)
	for e in range(9):
		k.box(ex * B.T3(0, 1.6 + e * 2.3, 0), Vector3(3.2, 0.3, 0.6), sombre, 2.0)
	k.col_box(ex * B.T3(0, R.H * 0.5, 0), Vector3(3.8, R.H, 0.6))
	# la chaîne du monte-sacs, qui pend de la trappe, et son crochet
	for c in range(30):
		k.ring(R.L(6.4, R.H - 0.5 - c * 0.42, -0.6) * Transform3D(Basis(Vector3.UP, PI * 0.5 * float(c % 2)) * Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 0.12, 0.2, 0.08, "fer", 8)
	k.ring(R.L(6.4, R.H - 13.4, -0.6) * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3.ZERO), 0.4, 0.62, 0.2, "fer", 14)
	# la farine et le grain par terre
	var rng := RandomNumberGenerator.new()
	rng.seed = 1743
	for i3 in range(16):
		var a3: float = rng.randf() * TAU
		var d3: float = rng.randf_range(4.6, 10.0)
		var px: float = sin(a3) * d3
		var pz: float = cos(a3) * d3
		if Vector2(px, pz - 10.6).length() < 2.0:
			continue
		var tf: float = rng.randf_range(1.6, 4.2)
		k.quad(R.L(px, 0.03 + i3 * 0.002, pz, rng.randf() * 360.0) * Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), Vector3.ZERO) * Transform3D(Basis(Vector3.UP, PI), Vector3.ZERO), tf, tf * rng.randf_range(0.5, 0.9), _farine_sol(R))
	for i4 in range(70):
		var a4: float = rng.randf() * TAU
		var d4: float = rng.randf_range(4.5, 6.2)
		_boule(M, ble, Vector3(sin(a4) * d4, 0.05, mz + cos(a4) * d4), 0.045, Vector3(1.0, 0.7, 1.7))
	for i5 in range(24):
		_boule(M, ble, Vector3(hu.x - 2.0 + rng.randf_range(-0.8, 0.8), 0.05, hu.z + rng.randf_range(-1.5, 1.5)), 0.045, Vector3(1.0, 0.7, 1.7))
	# les souris qui grignotent le grain
	_bete(M, "rat", {"taille": 3.4, "base": Color(0.5, 0.45, 0.4), "ventre": Color(0.85, 0.8, 0.74), "seed": 11}, Vector3(2.4, 0.0, 1.4), 150.0, "assis")
	_bete(M, "rat", {"taille": 3.2, "base": Color(0.58, 0.5, 0.42), "ventre": Color(0.88, 0.82, 0.76), "seed": 12}, Vector3(-4.0, 0.0, 0.6), -140.0, "assis")
	# la poussière de farine dans l'air
	_poussiere_moulin(M)
	_fournil_pepin(M)
	_pepin(M)


## Une traînée de farine par terre (une tache douce, plus épaisse au milieu).
static func _farine_sol(R) -> String:
	if R.mat("farine_sol174") == null:
		var m := StandardMaterial3D.new()
		m.albedo_texture = R.dot_texture()
		m.albedo_color = Color(0.93, 0.91, 0.86, 0.7)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.roughness = 1.0
		R._put("farine_sol174", m)
	return "farine_sol174"


## Des grains qui tombent de l'auget dans l'œil de la meule.
static func _grains(M, at: Vector3, _haut: float, key: String) -> void:
	var p := CPUParticles3D.new()
	p.amount = 18
	p.lifetime = 0.45
	p.direction = Vector3.DOWN
	p.spread = 6.0
	p.initial_velocity_min = 0.5
	p.initial_velocity_max = 0.9
	p.gravity = Vector3(0, -9.8, 0)
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.1
	var sm := SphereMesh.new()
	sm.radius = 0.045
	sm.height = 0.09
	sm.radial_segments = 6
	sm.rings = 3
	sm.material = M.R.mat(key)
	p.mesh = sm
	M.room.add_child(p)
	p.global_position = at


## La farine qui coule du bec dans la huche : un filet blanc, un nuage léger.
static func _farine_qui_coule(M, at: Vector3, r: float) -> void:
	var p := CPUParticles3D.new()
	p.amount = 40
	p.lifetime = 0.5
	p.direction = Vector3.DOWN
	p.spread = 4.0
	p.initial_velocity_min = 0.3
	p.initial_velocity_max = 0.6
	p.gravity = Vector3(0, -2.5, 0)
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = r * 0.4
	var q := QuadMesh.new()
	q.size = Vector2(r, r)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(0.98, 0.97, 0.95, 0.75)
	m.albedo_texture = M.R.dot_texture()
	q.material = m
	p.mesh = q
	M.room.add_child(p)
	p.global_position = at
	_vapeur(M, M.R.xf0.affine_inverse() * (at + Vector3.DOWN * 0.5), 0.6, 1.2, Color(1, 1, 1, 0.25), 10)


## La farine en suspens dans tout le moulin.
static func _poussiere_moulin(M) -> void:
	var p := CPUParticles3D.new()
	p.amount = 220
	p.lifetime = 16.0
	p.preprocess = 16.0
	p.direction = Vector3.UP
	p.spread = 180.0
	p.initial_velocity_min = 0.02
	p.initial_velocity_max = 0.08
	p.gravity = Vector3(0, -0.008, 0)
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(9.0, 9.0, 9.0)
	p.scale_amount_min = 0.4
	p.scale_amount_max = 1.0
	var q := QuadMesh.new()
	q.size = Vector2(0.07, 0.07)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(1.0, 0.98, 0.94, 0.5)
	m.albedo_texture = M.R.dot_texture()
	q.material = m
	p.mesh = q
	M.room.add_child(p)
	p.global_position = M.R.P(0, 9.5, 0)


## Un sac de farine de géant (5,6 m de haut ; la toile tamponnée « FARINE de la Butte »), debout ou
## couché (p : repère de la pièce ; yaw : où regarde l'étiquette).
static func _sac_geant(M, p: Vector3, yaw: float, couche: bool) -> void:
	var R = M.R
	var key: String = "sac_geant174"
	if R.mat(key) == null:
		var m := StandardMaterial3D.new()
		if ResourceLoader.exists("res://assets/textures/" + T + "sac_farine.png"):
			m.albedo_texture = load("res://assets/textures/" + T + "sac_farine.png")
		m.albedo_color = Color(1, 1, 1)
		m.roughness = 0.95
		R._put(key, m)
	var toile: Material = R.mat(key)
	var dessus: Material = R.mat(B._tex(R, "toile_sac174", "beau161/toile_lin.png", Color(0.86, 0.8, 0.66), 0.95))
	var corde: Material = R.mat(B._tex(R, "corde174", "beau161/corde.png", Color(0.8, 0.7, 0.5), 0.9))
	var r: float = 1.9
	var h: float = 4.6
	var xf: Transform3D = R.L(p.x, 0, p.z, yaw)
	if couche:
		xf = R.L(p.x, r * 0.85, p.z, yaw) * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0, -h * 0.5))
	var n := _noeud(M, "Sac_geant", xf)
	var corps := _bout(n, B._cylm(r * 0.94, r, h, 20), toile, Vector3(0, h * 0.5, 0), Basis(Vector3.UP, PI * 0.5))
	corps.scale = Vector3(1.0, 1.0, 0.86 if couche else 1.0)
	_bout(n, B._cylm(r * 0.6, r * 0.94, 0.8, 20), dessus, Vector3(0, h + 0.4, 0))
	_bout(n, B._cylm(0.42, 0.62, 0.7, 14), dessus, Vector3(0, h + 1.15, 0))
	_bout(n, B._cylm(0.48, 0.48, 0.22, 14), corde, Vector3(0, h + 1.05, 0))
	for t in range(5):
		var at: float = TAU * t / 5.0
		_bout(n, B._cylm(0.02, 0.22, 0.7, 6), dessus, Vector3(cos(at) * 0.3, h + 1.75, sin(at) * 0.3), Basis(Vector3(sin(at), 0, -cos(at)), 0.5))
	if couche:
		R.kit.col_box(xf * B.T3(0, h * 0.5 + 0.3, 0), Vector3(r * 1.9, h + 0.8, r * 1.65))
	else:
		R.kit.col_cyl(R.P(p.x, 0, p.z), r, h + 1.0)


## Le fournil de Pépin, le boulanger des Petits, près du trou de souris : son four (un pot de fleurs
## de géant retourné ; la porte du four, les braises ; le trou du fond fait la cheminée), son plan de
## travail (une tasse retournée : la pâte, le rouleau), sa vitrine (une cuillère de bois posée sur deux
## bobines : les baguettes, les boules), ses sacs de farine à lui (cousus dans un mouchoir de vichy),
## son enseigne.
static func _fournil_pepin(M) -> void:
	var R = M.R
	var k = R.kit
	var terre: String = B._tex(R, "terre174", "beau161/terre_cuite.png", Color(1, 1, 1), 0.85)
	var email: String = B._c(R, "email174", Color(0.93, 0.93, 0.9), 0.28)
	var bleu: String = B._c(R, "bleu174", Color(0.2, 0.36, 0.64), 0.3)
	var croute: String = B._tex(R, "croute174", T + "croute.png", Color(1, 1, 1), 0.85)
	var chene: String = _chene(R, false)
	# le four : le pot retourné (le bord sur le sol), la bouche du four et ses braises, la porte (une capsule)
	var ox: float = -7.6
	var oz: float = 6.4
	k.cyl(R.L(ox, 0.0, oz), 0.86, 0.64, 1.15, terre, 22, true, 1.2)
	k.ring(R.L(ox, 0.0, oz), 0.8, 0.92, 0.2, terre, 22)
	var fo: Transform3D = R.L(ox, 0.0, oz, 55.0)
	k.box(fo * B.T3(0, 0.28, 0.79), Vector3(0.48, 0.42, 0.04), "noir", 1.0, 16)
	k.cyl(fo * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0.49, 0.79)), 0.24, 0.24, 0.04, "noir", 12)
	var braise: String = B._c(R, "braise174", Color(1.0, 0.42, 0.12), 0.9, 0.0, 2.4 if R.day else 3.2)
	k.box(fo * B.T3(0, 0.12, 0.62), Vector3(0.36, 0.06, 0.3), braise, 1.0)
	k.cyl(fo * Transform3D(Basis(Vector3.RIGHT, PI * 0.5 + 0.3), Vector3(0.45, 0.25, 0.95)), 0.22, 0.22, 0.04, B._c(R, "capsule174", Color(0.75, 0.6, 0.2), 0.3, 0.8), 14)
	k.col_cyl(R.P(ox, 0.0, oz), 0.9, 1.2)
	_vapeur(M, Vector3(ox, 1.2, oz), 0.12, 1.4, Color(0.55, 0.52, 0.5, 0.3), 10)
	var l: OmniLight3D = _omni(M, _loc(R, fo, Vector3(0, 0.5, 1.3)), Color(1.0, 0.6, 0.3), 1.2 if R.day else 1.8, 7.0)
	(R.flames as Array).append([l, l.light_energy])
	# la pelle à enfourner, contre le pot
	k.cyl(R.L(ox - 0.9, 0.0, oz - 0.2) * Transform3D(Basis(Vector3.BACK, 0.3), Vector3.ZERO), 0.02, 0.02, 1.4, chene, 5)
	k.box(R.L(ox - 0.95, 0.12, oz - 0.2) * Transform3D(Basis(Vector3.BACK, 0.3), Vector3.ZERO), Vector3(0.05, 0.25, 0.22), chene, 1.0)
	# le plan de travail : une tasse de géant retournée ; dessus, la pâte, le rouleau, la farine
	var tx: float = -5.2
	var tz: float = 7.8
	k.cyl(R.L(tx, 0.0, tz), 0.46, 0.35, 0.7, email, 20)
	k.ring(R.L(tx, 0.42, tz), 0.36, 0.42, 0.08, bleu, 20)
	k.ring(R.L(tx + 0.48, 0.32, tz) * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 0.13, 0.19, 0.06, email, 10)
	k.col_cyl(R.P(tx, 0.0, tz), 0.46, 0.72)
	_boule(M, B._c(R, "pate174", Color(0.96, 0.9, 0.76), 0.95), Vector3(tx - 0.08, 0.76, tz + 0.05), 0.12, Vector3(1.2, 0.6, 1.0))
	k.cyl(R.L(tx + 0.1, 0.73, tz - 0.12) * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(0.15, 0, 0)), 0.025, 0.025, 0.3, chene, 6)
	k.cyl(R.L(tx, 0.705, tz), 0.3, 0.3, 0.01, B._c(R, "farine174", Color(0.97, 0.96, 0.93), 0.98), 14)
	# la vitrine : une cuillère de bois de géant sur deux bobines ; les pains
	var vx: float = -9.0
	var vz: float = 3.6
	for bz in [-0.6, 0.6]:
		k.cyl(R.L(vx, 0.0, vz + bz), 0.18, 0.18, 0.05, chene, 14)
		k.cyl(R.L(vx, 0.05, vz + bz), 0.13, 0.13, 0.26, B._c(R, "fil174_vert", Color(0.3, 0.55, 0.32), 0.85), 14)
		k.cyl(R.L(vx, 0.31, vz + bz), 0.18, 0.18, 0.05, chene, 14)
	k.box(R.L(vx, 0.38, vz - 0.2), Vector3(0.24, 0.05, 1.7), chene, 1.0)
	_boule(M, chene, Vector3(vx, 0.38, vz + 0.9), 0.25, Vector3(0.9, 0.25, 1.3))
	for p in range(3):
		k.cyl(R.L(vx - 0.03 + p * 0.03, 0.44, vz - 0.75 + p * 0.38) * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, -0.3, 0)), 0.035, 0.035, 0.6, croute, 8)
	for p2 in range(2):
		_boule(M, croute, Vector3(vx, 0.5, vz + 0.35 + p2 * 0.3), 0.09, Vector3(1, 0.75, 1))
	# ses sacs de farine à lui (cousus dans un mouchoir de vichy)
	var vichy: String = B._tex(R, "vichy174", T + "vichy_rouge.png", Color(1, 1, 1), 0.92)
	for sp in [[-9.6, 5.4], [-9.3, 6.2], [-6.4, 8.8]]:
		k.cyl(R.L(float(sp[0]), 0.0, float(sp[1])), 0.22, 0.2, 0.55, vichy, 12, true, 0.4)
		_boule(M, vichy, Vector3(float(sp[0]), 0.6, float(sp[1])), 0.12, Vector3(1, 0.6, 1))
	# l'enseigne (sur une planchette, contre un sac de géant)
	var ens: String = B._img(R, "enseigne174", T + "enseigne_pepin.png")
	var et: Transform3D = R.L(-4.2, 0.0, 9.6, 150.0) * Transform3D(Basis(Vector3.RIGHT, -0.18), Vector3.ZERO)
	k.box(et * B.T3(0, 0.5, -0.03), Vector3(1.2, 0.62, 0.05), chene, 1.0)
	k.quad(et * Transform3D(Basis(Vector3.UP, PI), Vector3(0, 0.5, 0.0)), 1.1, 0.55, ens)
	for s in [-0.45, 0.45]:
		k.box(et * B.T3(s, 0.2, -0.06), Vector3(0.05, 0.4, 0.05), chene, 1.0)


## Pépin, le boulanger des Petits : il ramasse la farine qui tombe des sacs d'Eustache et fait le pain
## de tous les Petits de la ferme.
static func _pepin(M) -> void:
	var gouter := func() -> void:
		M.say("Pépin te tend un petit pain encore chaud : la croûte dorée craque, la mie est blanche comme la farine de la Butte. « Une poignée de farine d'Eustache, et voilà cent pains ! »", 7.0)
	var regarder := func() -> void:
		M.say("Tout là-haut, le grand rouet tourne, ses dents de bois attrapent la lanterne, et la meule ronronne dans sa cuve. Le moulin entier chante, et la farine tombe en neige.", 7.0)
	B._marchand(M, -5.6, 5.2, 42.0, "debout", "homme", "Pépin",
		["Quand les ailes tournent, tout tourne : le grand rouet, la lanterne, la meule. Écoute : le moulin chante.",
			"Une poignée de la farine d'Eustache, c'est cent pains pour les Petits. Un de ses sacs, c'est un village nourri pour un an.",
			"Mon four ? Un pot de fleurs retourné. Le trou du fond fait la cheminée. Les géants jettent tout ce qui est fêlé : nous, on en fait des maisons.",
			"Attention aux souris : elles sont gentilles, mais elles ont la taille d'un chien, et elles adorent mon pain."],
		{"bonjour": "Bienvenue au Moulin de la Butte ! Attention à la farine : ici, il neige toute l'année.",
			"services": [{"label": "Goûter un pain de Pépin", "cb": gouter}],
			"infos": ["Je suis arrivé par le ponton, comme toi. Eustache m'a trouvé endormi sur un sac de farine. Il a dit : « Un boulanger dans un moulin, c'est dans l'ordre des choses. » Depuis, je suis chez moi.",
				"Le trou de souris, c'est ma porte. Les souris l'ont creusé, je l'ai arrangé, et maintenant on se le partage. Elles passent le matin, moi l'après-midi.",
				"Tante Brindille, sous le vaisselier de la maison ? Je lui porte une petite miche chaque semaine. En échange, elle me raconte ce que disent les géants à table.",
				"Le soir, quand Eustache arrête le moulin, on entend la meule tourner encore un peu, toute seule. Puis plus rien. C'est le plus beau silence du monde."]})
	M.ctx["cloche170"] = false
	M.ctx["bonjour170"] = ["Entre, entre ! Le pain sort du four.", "Tiens, un Petit ! Tu as de la farine plein les cheveux, déjà."]
	M.ctx["bonjour_nuit170"] = ["Chut, Eustache est rentré dormir. Moi, je pétris la pâte du matin.", "La nuit, le moulin se repose. Pas le boulanger !"]
	M.act(M.R.P(1.6, 0.0, 6.6), "E : regarder tourner le rouet", regarder, 2.4)
	M.ctx["entree"] = "Le Moulin de la Butte, vu d'en bas : la meule dans sa cuve, la trémie, le grand rouet qui tourne sous le plafond, les sacs de farine hauts comme des maisons… et près du trou de souris, le fournil de Pépin, le boulanger des Petits."


# =================================================================== V177 : le donjon de Pâquerette

## Le donjon du château de sable, à hauteur de Petit : son rayon dedans ; la hauteur du mur rond (le toit
## pointu au-dessus, jusqu'à R.H) ; le dessus de la galerie ; son bord côté vide (celui de l'escalier
## aussi) ; l'escalier taillé dans le mur (l'angle de la première marche, en degrés : 0 à la porte, en
## tournant vers la droite quand on entre ; l'angle d'une marche ; leur nombre) ; la largeur de la porte
## (une arche : 1,6 m tout droit, puis le demi-cercle) ; la meurtrière au-dessus de la porte, évasée (le
## bas, le haut, la demi-largeur côté pièce ; puis côté dehors) ; le rayon où se promène Sire Bernard.
const DJ_R: float = 3.9
const DJ_MUR: float = 7.6
const DJ_GAL: float = 4.2
const DJ_BORD: float = 2.6
const DJ_ESC0: float = 38.0
const DJ_PAS: float = 7.0
const DJ_MARCHES: int = 17
const DJ_PORTE: float = 1.4
const DJ_MEU := [4.95, 6.55, 0.55, 5.05, 6.45, 0.225]
const DJ_BERNARD: float = 2.25
## La table (un couvercle de confiture sur trois galets) et Firmin, le gardien.
const DJ_TABLE := Vector2(-1.0, -1.0)
const DJ_FIRMIN := Vector2(0.2, -1.9)


## Un point du donjon (repère de la pièce) : un angle (degrés), un rayon, une hauteur.
static func _dj(a: float, r: float, y: float = 0.0) -> Vector3:
	var t: float = deg_to_rad(a)
	return Vector3(sin(t) * r, y, cos(t) * r)


## Le dessus de l'escalier à un angle (degrés) : 0 avant la première marche, la galerie après la dernière.
static func _dj_marche(a: float) -> float:
	var i: int = int(floor((a - DJ_ESC0 + DJ_PAS * 0.5) / DJ_PAS))
	if i < 0:
		return 0.0
	if i >= DJ_MARCHES:
		return DJ_GAL
	return DJ_GAL * float(i + 1) / DJ_MARCHES


## Le début et la fin de la galerie (degrés ; la fin passe 360 : elle fait le tour par la porte).
static func _dj_galerie() -> Vector2:
	return Vector2(DJ_ESC0 + DJ_PAS * (DJ_MARCHES - 0.5), 360.0 + DJ_ESC0 - DJ_PAS * 0.5)


## Un pan tout droit (z fixe, il regarde la pièce : -z), de (x0, y0) à (x1, y1).
static func _dj_pan(R, key: String, x0: float, x1: float, y0: float, y1: float, z: float, tile: float) -> void:
	if x1 - x0 < 0.01 or y1 - y0 < 0.01:
		return
	R.kit.quad4(key, R.P(x0, y0, z), R.P(x1, y0, z), R.P(x1, y1, z), R.P(x0, y1, z), Vector3(0, 0, -1),
		Vector2(-x0 / tile, -y0 / tile), Vector2(-x1 / tile, -y0 / tile), Vector2(-x1 / tile, -y1 / tile), Vector2(-x0 / tile, -y1 / tile))


## Un triangle lisse (une normale par sommet), retourné au besoin comme ceux du kit.
static func _tri_lisse(st: SurfaceTool, p: Array, n: Array, uv: Array) -> void:
	var face: Vector3 = ((p[1] as Vector3) - (p[0] as Vector3)).cross((p[2] as Vector3) - (p[0] as Vector3))
	var navg: Vector3 = (n[0] as Vector3) + (n[1] as Vector3) + (n[2] as Vector3)
	var order: Array = [0, 2, 1] if face.dot(navg) > 0.0 else [0, 1, 2]
	for k in order:
		st.set_normal(n[k])
		st.set_uv(uv[k])
		st.add_vertex(p[k])


## Une boule déformée (repère de la pièce : son centre, ses trois rayons, son orientation), fondue dans
## la pièce : un galet, un coquillage, une bosse de sable.
static func _galet(R, key: String, c: Vector3, r: Vector3, bs: Basis = Basis(), seg: int = 10) -> void:
	var st: SurfaceTool = R.kit._st(key)
	var half: int = maxi(2, int(seg / 2.0))
	var o: Vector3 = R.P(c.x, c.y, c.z)
	for j in range(half):
		var t0: float = PI * j / half
		var t1: float = PI * (j + 1) / half
		for i in range(seg):
			var a0: float = TAU * i / seg
			var a1: float = TAU * (i + 1) / seg
			var q: Array = []
			var nn: Array = []
			var uv: Array = []
			for tc in [[t0, a0], [t0, a1], [t1, a1], [t1, a0]]:
				var dd := Vector3(sin(tc[0]) * cos(tc[1]), cos(tc[0]), sin(tc[0]) * sin(tc[1]))
				q.append(o + bs * (dd * r))
				nn.append((bs * Vector3(dd.x / r.x, dd.y / r.y, dd.z / r.z)).normalized())
				uv.append(Vector2(float(tc[1]) * maxf(r.x, r.z) * 1.5, float(tc[0]) * r.y * 1.5))
			_tri_lisse(st, [q[0], q[1], q[2]], [nn[0], nn[1], nn[2]], [uv[0], uv[1], uv[2]])
			_tri_lisse(st, [q[0], q[2], q[3]], [nn[0], nn[2], nn[3]], [uv[0], uv[2], uv[3]])


## Un cylindre (ou un cône) de a à b (repère de la pièce).
static func _tube(R, key: String, a: Vector3, b: Vector3, r0: float, r1: float, seg: int = 8, tile: float = 1.0) -> void:
	var d: Vector3 = b - a
	var l: float = d.length()
	if l < 0.001:
		return
	var y: Vector3 = d / l
	var x: Vector3 = y.cross(Vector3.UP if absf(y.y) < 0.95 else Vector3.RIGHT).normalized()
	var z: Vector3 = x.cross(y)
	R.kit.cyl(Transform3D(Basis(x, y, z), R.P(a.x, a.y, a.z)), r0, r1, l, key, seg, true, tile)


## Une orientation contre le mur rond (à l'angle a) : x le long du mur, y vers le haut, z vers la pièce.
static func _dj_mur(a: float) -> Basis:
	var t: float = deg_to_rad(a)
	var zz := Vector3(-sin(t), 0, -cos(t))
	var xx := Vector3(-cos(t), 0, sin(t))
	return Basis(xx, Vector3.UP, zz)


## La coque du donjon : le sol de sable tassé ; le mur rond (le bas plus mouillé) ; la porte en arche et
## son passage dans l'épaisseur du mur (le jour au bout) ; la meurtrière évasée et la mer au bout ; le
## toit pointu, et le bâtonnet du drapeau qui le traverse ; les collisions.
static func _coque_donjon(M) -> void:
	var R = M.R
	var k = R.kit
	var r: float = DJ_R
	var tm: float = float((R.pal["mur"] as Array)[2])
	var tb: float = float((R.pal["bas"] as Array)[2])
	var ts: float = float((R.pal["sol"] as Array)[2])
	var tp: float = float((R.pal["plafond"] as Array)[2])
	k.box(R.L(0, -0.1, 0.4), Vector3(R.W + 0.4, 0.2, R.D + 1.2), "sol", ts, 4)
	k.col_box(R.L(0, -0.5, 0), Vector3(R.W + 4.0, 1.0, R.D + 4.0))
	k.col_box(R.L(0, R.H + 1.0, 0), Vector3(R.W + 4.0, 1.0, R.D + 4.0))
	# le mur rond (sans le morceau de la porte, à part)
	var dh: float = asin(DJ_PORTE * 0.5 / r)
	var n: int = 46
	var yb: float = 0.9
	var pas: float = (TAU - 2.0 * dh) / n
	for i in range(n):
		var a0: float = dh + pas * i
		var a1: float = dh + pas * (i + 1)
		var p0 := Vector3(sin(a0) * r, 0, cos(a0) * r)
		var p1 := Vector3(sin(a1) * r, 0, cos(a1) * r)
		var am: float = (a0 + a1) * 0.5
		var nm := -Vector3(sin(am), 0, cos(am))
		for band in [[0.0, yb, "bas", tb], [yb, DJ_MUR, "mur", tm]]:
			var y0: float = band[0]
			var y1: float = band[1]
			var tile: float = band[3]
			k.quad4(str(band[2]), R.P(p0.x, y0, p0.z), R.P(p1.x, y0, p1.z), R.P(p1.x, y1, p1.z), R.P(p0.x, y1, p0.z), nm,
				Vector2(a0 * r / tile, -y0 / tile), Vector2(a1 * r / tile, -y0 / tile), Vector2(a1 * r / tile, -y1 / tile), Vector2(a0 * r / tile, -y1 / tile))
		k.col_box(R.L(sin(am) * (r + 0.6), R.H * 0.5, cos(am) * (r + 0.6), rad_to_deg(am)), Vector3(2.0 * (r + 0.6) * tan(pas * 0.5) + 0.3, R.H + 2.0, 1.2))
	# le morceau de la porte : tout droit (z = zc), l'arche, la meurtrière au-dessus
	var zc: float = r * cos(dh)
	var zt: float = zc + 0.55
	var hw: float = DJ_PORTE * 0.5
	var mq: Array = DJ_MEU
	_dj_pan(R, "mur", -hw, hw, 2.3, float(mq[0]), zc, tm)
	_dj_pan(R, "mur", -hw, -float(mq[2]), float(mq[0]), float(mq[1]), zc, tm)
	_dj_pan(R, "mur", float(mq[2]), hw, float(mq[0]), float(mq[1]), zc, tm)
	_dj_pan(R, "mur", -hw, hw, float(mq[1]), DJ_MUR, zc, tm)
	for s in [-1.0, 1.0]:
		var cc: Vector3 = R.P(s * hw, 2.3, zc)
		for j in range(10):
			var t0: float = PI * 0.5 * j / 10.0
			var t1: float = PI * 0.5 * (j + 1) / 10.0
			var q0 := Vector3(s * cos(t0) * hw, 1.6 + sin(t0) * hw, zc)
			var q1 := Vector3(s * cos(t1) * hw, 1.6 + sin(t1) * hw, zc)
			k.tri("mur", cc, R.P(q0.x, q0.y, q0.z), R.P(q1.x, q1.y, q1.z), Vector3(0, 0, -1),
				Vector2(-s * hw / tm, -2.3 / tm), Vector2(-q0.x / tm, -q0.y / tm), Vector2(-q1.x / tm, -q1.y / tm))
	# le passage dans l'épaisseur du mur : les côtés, la voûte ; le jour au bout
	for s2 in [-1.0, 1.0]:
		k.quad4("mur", R.P(s2 * hw, 0, zc), R.P(s2 * hw, 0, zt), R.P(s2 * hw, 1.6, zt), R.P(s2 * hw, 1.6, zc), Vector3(-s2, 0, 0),
			Vector2(zc / tm, 0), Vector2(zt / tm, 0), Vector2(zt / tm, -1.6 / tm), Vector2(zc / tm, -1.6 / tm))
	var jour: String = B._c(R, "dehors174_j" if R.day else "dehors174_n", Color(1.0, 0.94, 0.8) if R.day else Color(0.1, 0.13, 0.25), 0.9, 0.0, 1.6 if R.day else 0.6)
	k.quad4(jour, R.P(-hw, 0, zt), R.P(hw, 0, zt), R.P(hw, 1.6, zt), R.P(-hw, 1.6, zt), Vector3(0, 0, -1), Vector2(0, 1), Vector2(1, 1), Vector2(1, 0.3), Vector2(0, 0.3))
	for j2 in range(12):
		var t2: float = PI * j2 / 12.0
		var t3: float = PI * (j2 + 1) / 12.0
		var a := Vector3(cos(t2) * hw, 1.6 + sin(t2) * hw, 0)
		var b := Vector3(cos(t3) * hw, 1.6 + sin(t3) * hw, 0)
		var nn := -Vector3(cos((t2 + t3) * 0.5), sin((t2 + t3) * 0.5), 0)
		k.quad4("mur", R.P(a.x, a.y, zc), R.P(b.x, b.y, zc), R.P(b.x, b.y, zt), R.P(a.x, a.y, zt), nn,
			Vector2(t2 * hw / tm, zc / tm), Vector2(t3 * hw / tm, zc / tm), Vector2(t3 * hw / tm, zt / tm), Vector2(t2 * hw / tm, zt / tm))
		k.tri(jour, R.P(0, 1.6, zt), R.P(a.x, a.y, zt), R.P(b.x, b.y, zt), Vector3(0, 0, -1), Vector2(0.5, 0.3), Vector2(0.5, 0), Vector2(0.5, 0))
	k.col_box(R.L(0, 1.5, zt + 0.3), Vector3(2.4, 3.0, 0.6))
	for s3 in [-1.0, 1.0]:
		k.col_box(R.L(s3 * (hw + 0.5), 1.5, (zc + zt) * 0.5), Vector3(1.0, 3.0, zt - zc + 0.4))
	k.col_box(R.L(0, (2.3 + R.H) * 0.5, zc + 0.6), Vector3(DJ_PORTE + 0.4, R.H - 2.3, 1.2))
	# la meurtrière : évasée vers la pièce ; la mer au bout
	var ci: Array = [Vector3(-float(mq[2]), float(mq[0]), zc), Vector3(float(mq[2]), float(mq[0]), zc), Vector3(float(mq[2]), float(mq[1]), zc), Vector3(-float(mq[2]), float(mq[1]), zc)]
	var co: Array = [Vector3(-float(mq[5]), float(mq[3]), zt), Vector3(float(mq[5]), float(mq[3]), zt), Vector3(float(mq[5]), float(mq[4]), zt), Vector3(-float(mq[5]), float(mq[4]), zt)]
	var axe := Vector3(0, (float(mq[0]) + float(mq[1])) * 0.5, (zc + zt) * 0.5)
	for e in range(4):
		var pa: Vector3 = ci[e]
		var pb: Vector3 = ci[(e + 1) % 4]
		var pc: Vector3 = co[(e + 1) % 4]
		var pd: Vector3 = co[e]
		var nf: Vector3 = (pb - pa).cross(pd - pa).normalized()
		if nf.dot(axe - (pa + pb + pc + pd) * 0.25) < 0.0:
			nf = -nf
		k.quad4("mur", R.P(pa.x, pa.y, pa.z), R.P(pb.x, pb.y, pb.z), R.P(pc.x, pc.y, pc.z), R.P(pd.x, pd.y, pd.z), nf,
			Vector2((pa.x + pa.z) / tm, -pa.y / tm), Vector2((pb.x + pb.z) / tm, -pb.y / tm), Vector2((pc.x + pc.z) / tm, -pc.y / tm), Vector2((pd.x + pd.z) / tm, -pd.y / tm))
	# (la vue est un grand tableau posé à 3 m derrière la meurtrière, à la taille de ce qu'on verrait
	# d'ici : en bougeant la tête, on voit plus à gauche, plus à droite, comme par une vraie meurtrière)
	var vue := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(2.7, 3.46)
	vue.mesh = qm
	var vm := StandardMaterial3D.new()
	vm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var chemin: String = "res://assets/textures/" + T + ("vue_donjon_jour.png" if R.day else "vue_donjon_nuit.png")
	if ResourceLoader.exists(chemin):
		vm.albedo_texture = load(chemin)
	else:
		vm.albedo_color = Color(0.62, 0.8, 0.95) if R.day else Color(0.03, 0.05, 0.12)
	vue.material_override = vm
	vue.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	M.room.add_child(vue)
	vue.global_transform = Transform3D(Basis(Vector3.UP, PI), R.P(0, (float(mq[3]) + float(mq[4])) * 0.5, zt + 3.0))
	# le toit pointu (le dedans du cône), le bâtonnet du drapeau qui passe par la pointe
	var hc: float = R.H - DJ_MUR
	var nc: int = 48
	for i2 in range(nc):
		var b0: float = TAU * i2 / nc
		var b1: float = TAU * (i2 + 1) / nc
		var bm: float = (b0 + b1) * 0.5
		var nn2 := Vector3(-sin(bm) * hc, -r, -cos(bm) * hc).normalized()
		k.tri("plafond", R.P(sin(b0) * r, DJ_MUR, cos(b0) * r), R.P(sin(b1) * r, DJ_MUR, cos(b1) * r), R.P(0, R.H, 0), nn2,
			Vector2(b0 * r / tp, 0), Vector2(b1 * r / tp, 0), Vector2(bm * r / tp, -sqrt(hc * hc + r * r) / tp))
	k.cyl(R.L(0, R.H - 1.5, 0), 0.08, 0.08, 1.6, _chene(R, false), 8)
	k.ring(R.L(0, DJ_MUR - 0.12, 0), r - 0.16, r + 0.01, 0.16, "bas", 48)


## Dedans : l'escalier et la galerie ; les bosses du sable modelé à la main ; les coquillages ; les
## hublots ; chez Firmin (le lit, la table, les seaux, la cuillère, l'étoile de mer, l'ardoise) ; la
## conque ; Sire Bernard ; les bougies ; les lumières ; Firmin.
static func _donjon_paquerette(M) -> void:
	var R = M.R
	M.ctx["tick170"] = func(delta: float) -> void:
		_tick(M, delta)
		_tick_donjon(M, delta)
	_escalier_donjon(M)
	_galerie_donjon(M)
	_bosses_donjon(M)
	_coquillages_donjon(M)
	_hublots_donjon(M)
	_chez_firmin(M)
	_conque_donjon(M)
	_sablier_donjon(M)
	_bernard(M)
	_bougies_donjon(M)
	_lumieres_donjon(M)
	_firmin(M)
	if R.day:
		M.ctx["entree"] = "Le donjon du château de sable de Pâquerette, à hauteur de Petit : des murs de sable mouillé où brillent des coquillages, des hublots de verre de mer, un escalier taillé dans le mur jusqu'à la meurtrière… Firmin, le gardien, y habite avec Sire Bernard."
	else:
		M.ctx["entree"] = "Le donjon, la nuit : les bougies d'anniversaire de Pâquerette brûlent sur la galerie, les hublots luisent à peine, et l'on entend la mer à travers les murs."


## L'escalier taillé dans le mur (des blocs de sable mouillé, du sol à chaque marche) et son parapet,
## côté vide, dès qu'on est un peu haut.
static func _escalier_donjon(M) -> void:
	var R = M.R
	var k = R.kit
	var tb: float = float((R.pal["bas"] as Array)[2])
	var tm: float = float((R.pal["mur"] as Array)[2])
	var rc: float = (DJ_BORD + DJ_R + 0.15) * 0.5
	var lr: float = DJ_R + 0.15 - DJ_BORD
	var lt: float = rc * deg_to_rad(DJ_PAS) * 1.2
	for i in range(DJ_MARCHES):
		var a: float = DJ_ESC0 + DJ_PAS * i
		var top: float = DJ_GAL * float(i + 1) / DJ_MARCHES
		var c: Vector3 = _dj(a, rc)
		var xf: Transform3D = R.L(c.x, top * 0.5, c.z, a)
		k.box(xf, Vector3(lt, top, lr), "mur", tm)
		k.col_box(xf, Vector3(lt, top, lr))
		if i >= 3:
			var pc: Vector3 = _dj(a, DJ_BORD + 0.11)
			var xp: Transform3D = R.L(pc.x, top + 0.45, pc.z, a)
			k.box(xp, Vector3(lt, 0.9, 0.22), "mur", tm)
			k.col_box(xp, Vector3(lt, 0.9, 0.22))


## La galerie (de la dernière marche jusqu'au-dessus de la porte, et la meurtrière) : le dessus, le
## dessous, le parapet côté vide ; le bout fermé (au-dessus de la première marche).
static func _galerie_donjon(M) -> void:
	var R = M.R
	var k = R.kit
	var tm: float = float((R.pal["mur"] as Array)[2])
	var ts: float = float((R.pal["sol"] as Array)[2])
	var g: Vector2 = _dj_galerie()
	var ng: int = 32
	var ep: float = 0.35
	var yh: float = DJ_GAL + 0.95
	var rc: float = (DJ_BORD + DJ_R + 0.15) * 0.5
	var lr: float = DJ_R + 0.15 - DJ_BORD
	var rp: float = DJ_BORD + 0.22
	for j in range(ng):
		var b0: float = lerpf(g.x, g.y, float(j) / ng)
		var b1: float = lerpf(g.x, g.y, float(j + 1) / ng)
		var bm: float = (b0 + b1) * 0.5
		var i0: Vector3 = _dj(b0, DJ_BORD)
		var i1: Vector3 = _dj(b1, DJ_BORD)
		var o0: Vector3 = _dj(b0, DJ_R + 0.02)
		var o1: Vector3 = _dj(b1, DJ_R + 0.02)
		var p0: Vector3 = _dj(b0, rp)
		var p1: Vector3 = _dj(b1, rp)
		var vers: Vector3 = _dj(bm, 1.0)
		# le dessus (de la galerie, et du parapet), le dessous
		k.quad4("sol", R.P(p0.x, DJ_GAL, p0.z), R.P(p1.x, DJ_GAL, p1.z), R.P(o1.x, DJ_GAL, o1.z), R.P(o0.x, DJ_GAL, o0.z), Vector3.UP,
			Vector2(p0.x / ts, p0.z / ts), Vector2(p1.x / ts, p1.z / ts), Vector2(o1.x / ts, o1.z / ts), Vector2(o0.x / ts, o0.z / ts))
		k.quad4("mur", R.P(i0.x, DJ_GAL - ep, i0.z), R.P(i1.x, DJ_GAL - ep, i1.z), R.P(o1.x, DJ_GAL - ep, o1.z), R.P(o0.x, DJ_GAL - ep, o0.z), Vector3.DOWN,
			Vector2(i0.x / tm, i0.z / tm), Vector2(i1.x / tm, i1.z / tm), Vector2(o1.x / tm, o1.z / tm), Vector2(o0.x / tm, o0.z / tm))
		k.quad4("mur", R.P(i0.x, yh, i0.z), R.P(i1.x, yh, i1.z), R.P(p1.x, yh, p1.z), R.P(p0.x, yh, p0.z), Vector3.UP,
			Vector2(i0.x / tm, i0.z / tm), Vector2(i1.x / tm, i1.z / tm), Vector2(p1.x / tm, p1.z / tm), Vector2(p0.x / tm, p0.z / tm))
		# le parapet : côté vide (jusqu'au dessous de la galerie), côté galerie
		var u0: float = deg_to_rad(b0) * DJ_BORD / tm
		var u1: float = deg_to_rad(b1) * DJ_BORD / tm
		k.quad4("mur", R.P(i0.x, DJ_GAL - ep, i0.z), R.P(i1.x, DJ_GAL - ep, i1.z), R.P(i1.x, yh, i1.z), R.P(i0.x, yh, i0.z), -vers,
			Vector2(u0, -(DJ_GAL - ep) / tm), Vector2(u1, -(DJ_GAL - ep) / tm), Vector2(u1, -yh / tm), Vector2(u0, -yh / tm))
		k.quad4("mur", R.P(p0.x, DJ_GAL, p0.z), R.P(p1.x, DJ_GAL, p1.z), R.P(p1.x, yh, p1.z), R.P(p0.x, yh, p0.z), vers,
			Vector2(u0, -DJ_GAL / tm), Vector2(u1, -DJ_GAL / tm), Vector2(u1, -yh / tm), Vector2(u0, -yh / tm))
		# les collisions : la dalle, le parapet
		var cm: Vector3 = _dj(bm, rc)
		var corde: float = 2.0 * (DJ_R + 0.15) * sin(deg_to_rad((b1 - b0) * 0.5)) + 0.06
		k.col_box(R.L(cm.x, DJ_GAL - ep * 0.5, cm.z, bm), Vector3(corde, ep, lr))
		var pm: Vector3 = _dj(bm, DJ_BORD + 0.11)
		k.col_box(R.L(pm.x, DJ_GAL + 0.475, pm.z, bm), Vector3(2.0 * rp * sin(deg_to_rad((b1 - b0) * 0.5)) + 0.06, 0.95, 0.22))
	# le bout de la galerie (au-dessus du pied de l'escalier) : la tranche, un petit mur
	var ge: float = g.y
	var e0: Vector3 = _dj(ge, DJ_BORD)
	var e1: Vector3 = _dj(ge, DJ_R + 0.02)
	var tg: Vector3 = Vector3(cos(deg_to_rad(ge)), 0, -sin(deg_to_rad(ge)))
	k.quad4("mur", R.P(e0.x, DJ_GAL - ep, e0.z), R.P(e1.x, DJ_GAL - ep, e1.z), R.P(e1.x, DJ_GAL, e1.z), R.P(e0.x, DJ_GAL, e0.z), tg,
		Vector2(0, 0), Vector2(1.3 / tm, 0), Vector2(1.3 / tm, -ep / tm), Vector2(0, -ep / tm))
	var am: float = ge - rad_to_deg(0.11 / rc)
	var cb: Vector3 = _dj(am, rc)
	k.box(R.L(cb.x, DJ_GAL + 0.475, cb.z, am), Vector3(0.22, 0.95, lr), "mur", tm)
	k.col_box(R.L(cb.x, DJ_GAL + 0.475, cb.z, am), Vector3(0.22, 0.95, lr))


## Le sable modelé à la main : des bosses douces sur le mur (pas sur les coquillages, les hublots,
## l'ardoise, l'étoile de mer, ni autour de la porte).
static func _bosses_donjon(M) -> void:
	var R = M.R
	var rng := RandomNumberGenerator.new()
	rng.seed = 1771
	var pris: Array = [[205.0, 1.9, 3.0], [282.0, 2.0, 3.2], [270.0, 5.7, 6.6]]
	for hb in Kit142.HUBLOTS:
		pris.append([float(hb[0]), float(hb[1]) - 0.6, float(hb[1]) + 0.6])
	var n: int = 0
	var essais: int = 0
	while n < 70 and essais < 400:
		essais += 1
		var a: float = rng.randf_range(20.0, 340.0)
		var y: float = rng.randf_range(0.35, DJ_MUR - 0.4)
		if absf(y - 1.45) < 0.3 or absf(y - (_dj_marche(a) + 1.2)) < 0.3 or absf(y - (DJ_GAL + 1.25)) < 0.3:
			continue
		var libre: bool = true
		for p in pris:
			if absf(a - float(p[0])) < 11.0 and y > float(p[1]) - 0.2 and y < float(p[2]) + 0.2:
				libre = false
		if not libre:
			continue
		var bs: Basis = _dj_mur(a) * Basis(Vector3.BACK, rng.randf() * TAU)
		var key: String = "bas" if y < 0.9 else "mur"
		_galet(R, key, _dj(a, DJ_R + 0.02, y), Vector3(rng.randf_range(0.22, 0.42), rng.randf_range(0.16, 0.3), 0.12), bs, 8)
		n += 1


## Les coquillages que Pâquerette pose chaque matin devant la porte (Firmin les met dans le mur) : une
## frise tout autour, une qui monte le long de l'escalier, une sur la galerie.
static func _coquillages_donjon(M) -> void:
	var R = M.R
	var rng := RandomNumberGenerator.new()
	rng.seed = 1772
	var places: Array = []
	var a: float = 157.0
	while a < 344.0:
		places.append([a, 1.45])
		a += 6.0
	a = 40.0
	while a < 152.0:
		places.append([a, _dj_marche(a) + 1.2])
		a += 6.0
	var g: Vector2 = _dj_galerie()
	a = g.x + 4.0
	while a < g.y - 2.0:
		places.append([a, DJ_GAL + 1.25])
		a += 7.0
	var cles: Array = [B._c(R, "nacre177", Color(0.95, 0.93, 0.88), 0.35, 0.1), B._c(R, "rose177", Color(0.96, 0.66, 0.68), 0.45),
		B._c(R, "saumon177", Color(0.96, 0.62, 0.42), 0.5), B._c(R, "creme177", Color(0.94, 0.86, 0.7), 0.6)]
	var moule: String = B._c(R, "moule177", Color(0.12, 0.13, 0.2), 0.3, 0.3)
	var n: int = 0
	for pl in places:
		var ap: float = fposmod(float(pl[0]), 360.0)
		var trop: bool = ap < 14.0 or ap > 346.0
		for hb in Kit142.HUBLOTS:
			if absf(ap - float(hb[0])) < 7.0 and absf(float(pl[1]) - float(hb[1])) < 0.6:
				trop = true
		if absf(ap - 270.0) < 9.0 and float(pl[1]) > DJ_GAL:
			trop = true
		if trop:
			continue
		var y: float = float(pl[1]) + rng.randf_range(-0.05, 0.05)
		var bs: Basis = _dj_mur(ap) * Basis(Vector3.BACK, rng.randf_range(-0.5, 0.5))
		var c: Vector3 = _dj(ap, DJ_R - 0.01, y)
		var sorte: int = n % 4
		var key: String = cles[rng.randi() % cles.size()]
		match sorte:
			0:
				# une coquille Saint-Jacques : l'éventail, ses côtes, les deux oreilles
				_galet(R, key, c, Vector3(0.13, 0.11, 0.035), bs, 10)
				for j in range(5):
					var aj: float = deg_to_rad(-50.0 + 25.0 * j)
					_galet(R, key, c + bs * Vector3(sin(aj) * 0.06, cos(aj) * 0.05 - 0.01, 0.025), Vector3(0.012, 0.06, 0.012), bs * Basis(Vector3.BACK, -aj), 6)
				R.kit.box(Transform3D(bs, R.P(c.x, c.y, c.z) + bs * Vector3(0, -0.1, 0.01)), Vector3(0.09, 0.03, 0.02), key, 1.0)
			1:
				# une coque, bombée
				_galet(R, key, c, Vector3(0.085, 0.08, 0.06), bs, 10)
			2:
				# un bigorneau (une spirale pointue)
				_galet(R, key, c, Vector3(0.065, 0.06, 0.05), bs, 8)
				_tube(R, key, c + bs * Vector3(0, 0.03, 0.02), c + bs * Vector3(0.02, 0.15, 0.03), 0.045, 0.0, 8)
			_:
				# une moule, bleu nuit, nacrée
				_galet(R, moule, c, Vector3(0.05, 0.12, 0.03), bs * Basis(Vector3.BACK, 0.6), 8)
		n += 1
	M.ctx["coquillages177"] = n


## Les hublots de verre de mer (le même tour que dehors : Kit142.HUBLOTS) : le verre dépoli qui laisse
## passer la lumière, le rebord de sable mouillé ; une lumière colorée devant.
static func _hublots_donjon(M) -> void:
	var R = M.R
	var k = R.kit
	for hb in Kit142.HUBLOTS:
		var a: float = float(hb[0])
		var y: float = float(hb[1])
		var col: Color = {"verre_mer_vert": Color(0.3, 0.8, 0.45), "verre_mer_bleu": Color(0.3, 0.55, 0.98), "verre_mer_ambre": Color(1.0, 0.6, 0.15)}[str(hb[2])]
		var key: String = B._c(R, str(hb[2]) + ("177_j" if R.day else "177_n"), col, 0.4, 0.0, 0.85 if R.day else 0.2)
		var bs: Basis = _dj_mur(a)
		var c: Vector3 = _dj(a, DJ_R + 0.01, y)
		for v in Kit142.MOSAIQUE:
			var vv: Vector2 = v
			_galet(R, key, c + bs.x * vv.x + Vector3.UP * vv.y, Vector3(0.13, 0.12, 0.07), bs * Basis(Vector3.BACK, vv.x * 7.0), 10)
		k.ring(Transform3D(bs * Basis(Vector3.RIGHT, PI * 0.5), R.P(c.x, c.y, c.z)), 0.4, 0.52, 0.07, "bas", 22)
		if R.day:
			var l: OmniLight3D = _omni(M, _dj(a, DJ_R - 0.6, y), col, 0.55, 3.2)
			l.light_specular = 0.1


## Chez Firmin : le mouchoir de Pâquerette pour tapis ; la table (un couvercle de confiture sur trois
## galets) et deux bobines pour s'asseoir ; le lit d'algues sèches, la chaussette de Pâquerette pour sac de
## couchage, une boule de coton pour oreiller ; les seaux d'eau de mer ; la cuillère à café de
## Pâquerette, contre le mur ; l'étoile de mer ; l'ardoise des marées ; sur la galerie, la papillote, la
## boîte d'allumettes aux trésors, un galet pour s'asseoir devant la meurtrière.
static func _chez_firmin(M) -> void:
	var R = M.R
	var k = R.kit
	var chene: String = _chene(R, false)
	var sombre: String = _chene(R, true)
	var galet: String = B._c(R, "galet177", Color(0.6, 0.6, 0.58), 0.75)
	# le mouchoir (vichy rouge et blanc), par terre
	var vichy: String = B._tex(R, "vichy174", T + "vichy_rouge.png", Color(1, 1, 1), 0.92)
	k.box(R.L(0.25, 0.006, -0.1, 14.0), Vector3(2.3, 0.012, 2.3), vichy, 0.55, 4)
	# la table
	var tx: float = DJ_TABLE.x
	var tz: float = DJ_TABLE.y
	_galet(R, galet, Vector3(tx, 0.11, tz), Vector3(0.38, 0.12, 0.32), Basis(Vector3.UP, 0.3), 12)
	_galet(R, B._c(R, "galet177_b", Color(0.72, 0.68, 0.62), 0.7), Vector3(tx + 0.02, 0.32, tz - 0.02), Vector3(0.32, 0.11, 0.27), Basis(Vector3.UP, 1.2), 12)
	_galet(R, galet, Vector3(tx, 0.51, tz + 0.01), Vector3(0.28, 0.1, 0.24), Basis(Vector3.UP, 2.1), 12)
	var rouge: String = B._c(R, "couvercle177", Color(0.72, 0.1, 0.1), 0.35, 0.4)
	var dore: String = B._c(R, "dore177", Color(0.86, 0.68, 0.3), 0.3, 0.9)
	k.cyl(R.L(tx, 0.58, tz), 0.52, 0.52, 0.1, rouge, 32)
	k.ring(R.L(tx, 0.58, tz), 0.5, 0.535, 0.11, dore, 32)
	k.col_cyl(R.P(tx, 0.0, tz), 0.52, 0.69)
	# sur la table : le dé à coudre (une tasse : du thé dedans), le bouton (une assiette)
	k.cyl(R.L(tx - 0.24, 0.68, tz + 0.12), 0.075, 0.068, 0.14, "argent", 14, false)
	k.cyl(R.L(tx - 0.24, 0.68, tz + 0.12), 0.07, 0.07, 0.11, B._c(R, "the177", Color(0.42, 0.22, 0.1), 0.1), 14)
	for dd in range(8):
		var ad: float = TAU * dd / 8.0
		k.cyl(R.L(tx - 0.24 + cos(ad) * 0.072, 0.74, tz + 0.12 + sin(ad) * 0.072), 0.008, 0.008, 0.06, "fer", 4)
	var os_key: String = B._c(R, "bouton177", Color(0.93, 0.9, 0.82), 0.3)
	k.cyl(R.L(tx + 0.05, 0.68, tz - 0.22), 0.12, 0.12, 0.016, os_key, 20)
	for bt in range(4):
		var ab: float = PI * 0.5 * bt + 0.4
		k.cyl(R.L(tx + 0.05 + cos(ab) * 0.03, 0.692, tz - 0.22 + sin(ab) * 0.03), 0.009, 0.009, 0.006, "noir", 6)
	# deux bobines de fil (pour s'asseoir), côté pièce
	for bb in [[tx + 0.15, tz + 0.82, Color(0.35, 0.5, 0.85)], [tx + 0.82, tz - 0.12, Color(0.4, 0.7, 0.42)]]:
		var bx: float = bb[0]
		var bz: float = bb[1]
		var fil: String = B._tex(R, "fil177_%d" % int(bx * 100.0), T + "laine.png", bb[2], 0.9)
		k.cyl(R.L(bx, 0.0, bz), 0.27, 0.27, 0.05, chene, 18)
		k.cyl(R.L(bx, 0.05, bz), 0.2, 0.2, 0.36, fil, 18, true, 0.3)
		k.cyl(R.L(bx, 0.41, bz), 0.27, 0.27, 0.05, chene, 18)
		k.col_cyl(R.P(bx, 0.0, bz), 0.27, 0.46)
	# le lit : des algues sèches, la chaussette, la boule de coton
	var al: float = 262.0
	var lc: Vector3 = _dj(al, 3.0)
	var xb: Transform3D = R.L(lc.x, 0, lc.z, al + 90.0)
	var algue: String = B._c(R, "algue177", Color(0.28, 0.27, 0.14), 0.95)
	var algue2: String = B._c(R, "algue177_b", Color(0.36, 0.3, 0.16), 0.95)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1773
	for j in range(8):
		var pz: float = -0.95 + 1.9 * j / 7.0
		var q: Vector3 = R.xf0.affine_inverse() * (xb * Vector3(rng.randf_range(-0.12, 0.12), 0.12, pz))
		_galet(R, algue if j % 2 == 0 else algue2, q, Vector3(0.42, 0.15, 0.3), xb.basis * Basis(Vector3.UP, rng.randf_range(-0.4, 0.4)), 10)
	var laine: String = B._tex(R, "chaussette177", T + "laine.png", Color(0.95, 0.32, 0.3), 0.95)
	var blanc_l: String = B._tex(R, "chaussette177_b", T + "laine.png", Color(1.0, 0.97, 0.92), 0.95)
	var pl := func(v: Vector3) -> Vector3:
		return R.xf0.affine_inverse() * (xb * v)
	_tube(R, laine, pl.call(Vector3(0.05, 0.42, -0.8)), pl.call(Vector3(0.05, 0.42, 0.6)), 0.28, 0.27, 16, 0.35)
	_galet(R, laine, pl.call(Vector3(-0.02, 0.43, 0.72)), Vector3(0.29, 0.28, 0.3), xb.basis, 12)
	_tube(R, laine, pl.call(Vector3(0.0, 0.42, 0.75)), pl.call(Vector3(-0.5, 0.38, 0.95)), 0.25, 0.21, 16, 0.35)
	_galet(R, laine, pl.call(Vector3(-0.55, 0.38, 0.97)), Vector3(0.22, 0.2, 0.22), xb.basis, 12)
	k.ring(Transform3D(xb.basis * Basis(Vector3.RIGHT, PI * 0.5), xb * Vector3(0.05, 0.42, -0.86)), 0.2, 0.3, 0.14, blanc_l, 20)
	_galet(R, B._c(R, "coton177", Color(0.98, 0.97, 0.95), 1.0), pl.call(Vector3(0.0, 0.55, -1.12)), Vector3(0.3, 0.2, 0.24), xb.basis, 12)
	k.col_box(xb * B.T3(0.1, 0.3, -0.1), Vector3(0.95, 0.6, 2.2))
	# les seaux d'eau de mer
	var douelles: String = B._tex(R, "seau177", "montjoie/bois_planches.png", Color(0.82, 0.66, 0.5), 0.8)
	var eau: String = B._c(R, "eau177", Color(0.2, 0.42, 0.46), 0.05, 0.1)
	for sa in [300.0, 313.0]:
		var sp: Vector3 = _dj(sa, 3.25)
		k.cyl(R.L(sp.x, 0, sp.z), 0.2, 0.24, 0.38, douelles, 16, false, 0.6)
		k.cyl(R.L(sp.x, 0.01, sp.z), 0.2, 0.2, 0.01, douelles, 16)
		k.cyl(R.L(sp.x, 0.3, sp.z), 0.225, 0.225, 0.01, eau, 16)
		for yr in [0.07, 0.29]:
			k.ring(R.L(sp.x, yr, sp.z), 0.205 + yr * 0.1, 0.225 + yr * 0.1, 0.035, "fer", 16)
		k.col_cyl(R.P(sp.x, 0, sp.z), 0.24, 0.38)
	# la cuillère à café de Pâquerette (grande comme une pelle), contre le mur
	var cb: Vector3 = _dj(335.0, 3.3, 0.05)
	var ch: Vector3 = _dj(335.0, DJ_R - 0.05, 1.05)
	var dc: Vector3 = (ch - cb).normalized()
	var bsc: Basis = Basis(_dj_mur(335.0).x, dc, _dj_mur(335.0).x.cross(dc).normalized())
	_galet(R, "argent", cb + dc * 0.12, Vector3(0.14, 0.2, 0.05), bsc, 12)
	k.box(Transform3D(bsc, R.P(0, 0, 0) + (cb + dc * 0.66)), Vector3(0.07, 0.9, 0.022), "argent", 1.0)
	_galet(R, "argent", cb + dc * 1.1, Vector3(0.05, 0.06, 0.016), bsc, 8)
	# l'étoile de mer, au mur au-dessus du lit
	var et: Vector3 = _dj(282.0, DJ_R - 0.05, 2.6)
	var bse: Basis = _dj_mur(282.0)
	var orange: String = B._c(R, "etoile177", Color(0.9, 0.5, 0.26), 0.85)
	_galet(R, orange, et, Vector3(0.13, 0.13, 0.05), bse, 10)
	for j2 in range(5):
		var aj: float = PI * 0.5 + TAU * j2 / 5.0 + 0.15
		var dj: Vector3 = bse * Vector3(cos(aj), sin(aj), 0)
		_tube(R, orange, et + dj * 0.05, et + dj * 0.4 + bse.z * 0.01, 0.07, 0.018, 8)
	# l'ardoise des marées (dans son cadre de bois flotté)
	var ar: Vector3 = _dj(205.0, DJ_R - 0.05, 2.45)
	var xa: Transform3D = R.L(ar.x, ar.y, ar.z, 205.0)
	k.box(xa * B.T3(0, 0, 0.02), Vector3(1.0, 0.7, 0.04), sombre, 1.0)
	k.quad(xa * B.T3(0, 0, -0.005), 0.9, 0.6, B._img(R, "marees177", T + "marees.png"))
	# sur la galerie : la papillote (un papier de bonbon, au mur), la boîte d'allumettes aux trésors, le
	# galet devant la meurtrière
	var pp: Vector3 = _dj(270.0, DJ_R - 0.04, 6.15)
	var bsp: Basis = _dj_mur(270.0)
	var papi: String = B._c(R, "papillote177", Color(0.95, 0.32, 0.58), 0.22, 0.75)
	var papi_o: String = B._c(R, "papillote177_o", Color(0.95, 0.78, 0.25), 0.22, 0.8)
	k.box(Transform3D(bsp, R.P(pp.x, pp.y, pp.z)), Vector3(0.8, 0.5, 0.02), papi, 0.5)
	for sg in [-1.0, 1.0]:
		var bout: Vector3 = R.P(pp.x, pp.y, pp.z) + bsp.x * sg * 0.4 + bsp.z * 0.01
		k.tri(papi_o, bout, bout + bsp.x * sg * 0.32 + bsp.y * 0.24, bout + bsp.x * sg * 0.32 - bsp.y * 0.24, bsp.z, Vector2(0, 0), Vector2(1, 0), Vector2(1, 1))
	var bo: Vector3 = _dj(26.0, 3.45, DJ_GAL)
	var xbo: Transform3D = R.L(bo.x, DJ_GAL, bo.z, 26.0 + 90.0)
	var boite: String = B._c(R, "boite177", Color(0.85, 0.2, 0.15), 0.6)
	var frotte: String = B._c(R, "frotte177", Color(0.36, 0.22, 0.14), 0.95)
	k.box(xbo * B.T3(0, 0.11, -0.12), Vector3(0.5, 0.22, 0.62), boite, 1.0)
	k.box(xbo * B.T3(0.252, 0.11, -0.12), Vector3(0.01, 0.16, 0.56), frotte, 1.0)
	k.box(xbo * B.T3(0, 0.1, 0.3), Vector3(0.46, 0.18, 0.4), chene, 1.0)
	var verres: Array = [Color(0.42, 0.85, 0.58), Color(0.42, 0.66, 0.98), Color(1.0, 0.68, 0.26), Color(0.95, 0.95, 0.9), Color(0.5, 0.8, 0.85)]
	for vg in range(9):
		var cv: Color = verres[vg % verres.size()]
		var gk: String = B._c(R, "verre_mer177_%d" % (vg % verres.size()), cv, 0.35, 0.0, 0.4)
		var gp: Vector3 = R.xf0.affine_inverse() * (xbo * Vector3(rng.randf_range(-0.15, 0.15), 0.21, 0.3 + rng.randf_range(-0.13, 0.13)))
		_galet(R, gk, gp, Vector3(0.05, 0.025, 0.04), Basis(Vector3.UP, rng.randf() * TAU), 8)
	k.col_box(xbo * B.T3(0, 0.11, 0.0), Vector3(0.5, 0.22, 0.95))
	var gs: Vector3 = _dj(13.0, 3.35, DJ_GAL)
	_galet(R, galet, gs + Vector3(0, 0.14, 0), Vector3(0.36, 0.16, 0.3), Basis(Vector3.UP, 0.8), 12)
	k.col_cyl(R.P(gs.x, DJ_GAL, gs.z), 0.34, 0.28)
	# ce qu'on fait ici
	M.act(R.P(_dj(205.0, 2.9).x, 0, _dj(205.0, 2.9).z), "E : lire l'ardoise des marées", func(): M.say("Sur l'ardoise, à la craie : la courbe de la mer, deux hautes, deux basses. En bas, souligné deux fois : « arroser les murs : matin et soir ». Dans le coin, un crabe : Sire Bernard a voulu son portrait.", 7.0), 1.0)
	M.act(R.P(_dj(335.0, 2.75).x, 0, _dj(335.0, 2.75).z), "E : regarder la cuillère de Pâquerette", func(): M.say("Une cuillère à café de géant, grande comme une pelle. C'est avec elle que Pâquerette a creusé le donjon, de l'intérieur, grain par grain, sans le faire tomber. Sur le manche, il y a encore la trace de ses doigts.", 7.0), 0.9)
	M.act(R.P(_dj(24.0, 3.0).x, DJ_GAL, _dj(24.0, 3.0).z), "E : regarder le trésor de Firmin", func(): M.say("Dans la boîte d'allumettes, des bouts de verre de mer : vert bouteille, bleu, ambre, blanc de lune. La mer les a polis pendant des années. « Pâquerette dit que ce sont des bonbons de sirène. Moi, je ne dis rien. »", 7.0), 1.0)
	M.act(R.P(_dj(290.0, 3.2).x, DJ_GAL, _dj(290.0, 3.2).z), "E : compter les coquillages de Pâquerette", func(): M.say("Un coquillage par matin, tout autour du donjon, de la porte jusqu'en haut : %d. « Elle les pose devant la porte en disant bonjour. Je n'en ai jamais raté un. »" % int(M.ctx.get("coquillages177", 0)), 7.0), 1.0)
	M.act(R.P(0, DJ_GAL, 3.2), "E : regarder la mer par la meurtrière", func():
		if R.day:
			M.say("Par la meurtrière : la mer à perte de vue, bleue jusqu'au ciel, et tout en bas le bout de la grève, où Pâquerette vient jouer. Le vent sent le sel. C'est d'ici que Firmin guette les bateaux des Petits.", 7.0)
		else:
			M.say("La nuit, la mer brille sous la lune, et l'on entend les vagues se coucher sur la grève, une à une.", 6.0), 1.1)


## La grande conque (un buccin de géant, couché par terre) : on y écoute la mer.
static func _conque_donjon(M) -> void:
	var R = M.R
	var creme: String = B._c(R, "conque177", Color(0.93, 0.85, 0.72), 0.45)
	var brun: String = B._c(R, "conque177_b", Color(0.66, 0.46, 0.3), 0.5)
	var rose: String = B._c(R, "conque177_r", Color(0.96, 0.62, 0.55), 0.3)
	var ca: float = 168.0
	var c0: Vector3 = _dj(ca, 3.05, 0.0)
	var ax: Vector3 = Vector3(cos(deg_to_rad(ca)), 0, -sin(deg_to_rad(ca)))
	var up := Vector3.UP
	var side: Vector3 = ax.cross(up).normalized()
	for j in range(22):
		var t: float = j / 21.0
		var rr: float = lerpf(0.3, 0.03, pow(t, 0.8))
		var tour: float = t * TAU * 3.2
		var p: Vector3 = c0 + ax * lerpf(-0.3, 0.62, t) + (up * cos(tour) + side * sin(tour)) * rr * 0.28 + up * (0.27 - t * 0.2)
		_galet(R, brun if (j % 4 == 2) else creme, p, Vector3(rr, rr * 0.92, rr * 1.15), Basis(side, tour).orthonormalized(), 12)
	_tube(R, creme, c0 + ax * 0.62 + up * 0.07, c0 + ax * 0.8 + up * 0.06, 0.035, 0.0, 8)
	# l'ouverture (rose nacré dedans), le bord retourné
	var fz: Vector3 = (-ax - side * 0.7).normalized()
	var fx: Vector3 = up.cross(fz).normalized()
	var bo: Basis = Basis(fx, fz.cross(fx), fz)
	var ou: Vector3 = c0 - ax * 0.36 + up * 0.25 - side * 0.1
	_galet(R, rose, ou, Vector3(0.2, 0.25, 0.05), bo, 12)
	_galet(R, creme, ou - fz * 0.02 + fx * 0.16, Vector3(0.06, 0.27, 0.12), bo, 10)
	R.kit.col_box(R.L(c0.x + ax.x * 0.1, 0.3, c0.z + ax.z * 0.1, ca + 90.0), Vector3(0.6, 0.6, 1.1))
	M.act(R.P(_dj(ca, 2.45).x, 0, _dj(ca, 2.45).z), "E : écouter la mer dans le grand coquillage", func():
		M.main.sfx("vague", R.P(c0.x, 0.4, c0.z), -6.0)
		M.say("Tu colles l'oreille contre la conque : chhhh… la mer, tout entière, qui roule et se retire, comme si la grève était dedans.", 6.0), 1.1)


## Le sablier des marées (sur la table) : le sable coule ; on le retourne.
static func _sablier_donjon(M) -> void:
	var R = M.R
	var n := _noeud(M, "Sablier", R.L(DJ_TABLE.x + 0.18, 0.69 + 0.18, DJ_TABLE.y - 0.02))
	var bois: Material = R.mat(_chene(R, true))
	var verre: Material = R.mat(B._verre(R, "verre177", Color(0.85, 0.92, 0.95), 0.25))
	var sable: Material = R.mat(B._c(R, "sable_sablier177", Color(0.95, 0.85, 0.6), 0.9))
	for sy in [-0.17, 0.17]:
		_bout(n, B._cylm(0.1, 0.1, 0.025, 16), bois, Vector3(0, sy, 0))
	for sp in range(3):
		var ap: float = TAU * sp / 3.0
		_bout(n, B._cylm(0.008, 0.008, 0.34, 6), bois, Vector3(cos(ap) * 0.085, 0, sin(ap) * 0.085))
	_bout(n, B._cylm(0.012, 0.075, 0.15, 14), verre, Vector3(0, 0.08, 0))
	_bout(n, B._cylm(0.075, 0.012, 0.15, 14), verre, Vector3(0, -0.08, 0))
	var haut := _bout(n, B._cylm(0.01, 0.06, 0.08, 12), sable, Vector3(0, 0.07, 0))
	var bas := _bout(n, B._cylm(0.008, 0.065, 0.07, 12), sable, Vector3(0, -0.12, 0))
	var filet := CPUParticles3D.new()
	filet.amount = 24
	filet.lifetime = 0.25
	filet.direction = Vector3.DOWN
	filet.spread = 2.0
	filet.initial_velocity_min = 0.3
	filet.initial_velocity_max = 0.4
	filet.gravity = Vector3(0, -2.0, 0)
	var sm := SphereMesh.new()
	sm.radius = 0.004
	sm.height = 0.008
	sm.radial_segments = 4
	sm.rings = 2
	sm.material = sable
	filet.mesh = sm
	M.room.add_child(filet)
	filet.global_position = n.global_position
	M.ctx["sablier177"] = {"n": n, "haut": haut, "bas": bas, "filet": filet, "t": 20.0, "tourne": 0.0, "sens": 0.0}
	M.act(R.P(DJ_TABLE.x + 0.5, 0, DJ_TABLE.y + 0.5), "E : retourner le sablier des marées", func():
		var sb: Dictionary = M.ctx["sablier177"]
		if float(sb["tourne"]) > 0.0:
			return
		sb["tourne"] = 0.8
		sb["sens"] = float(sb["sens"]) + PI
		M.main.sfx("sable_effondre", n.global_position, -14.0)
		M.say("Tu retournes le sablier : le sable recommence à couler. « Une heure de sable, une heure de mer », dit Firmin.", 5.0), 1.0)


## Sire Bernard, le bernard-l'ermite (gros comme un chat, pour un Petit) : il se promène devant les
## meubles, s'arrête près de sa conque ; si l'on approche, il rentre dans sa coquille.
static func _bernard(M) -> void:
	var R = M.R
	var root := Node3D.new()
	root.name = "Bernard"
	M.room.add_child(root)
	var sph := SphereMesh.new()
	sph.radius = 1.0
	sph.height = 2.0
	sph.radial_segments = 14
	sph.rings = 7
	var coq: Material = R.mat(B._c(R, "coquille_bernard177", Color(0.88, 0.8, 0.66), 0.45))
	var bande: Material = R.mat(B._c(R, "coquille_bernard177_b", Color(0.62, 0.42, 0.28), 0.5))
	var rouge: Material = R.mat(B._c(R, "crabe177", Color(0.86, 0.3, 0.16), 0.5))
	var noir: Material = R.mat("noir")
	for j in range(6):
		var t: float = j / 5.0
		var rr: float = lerpf(0.17, 0.035, t)
		var tour: float = t * TAU * 1.8
		_bout(root, sph, bande if j % 2 == 1 else coq, Vector3(sin(tour) * rr * 0.3, 0.16 + t * 0.12 + cos(tour) * rr * 0.25, -0.04 - t * 0.26), Basis().scaled(Vector3(rr, rr * 0.9, rr)))
	var corps := Node3D.new()
	corps.name = "Corps"
	root.add_child(corps)
	corps.position = Vector3(0, 0, 0.1)
	_bout(corps, sph, rouge, Vector3(0, 0.1, 0.03), Basis().scaled(Vector3(0.09, 0.065, 0.085)))
	var pattes: Array = []
	for s in [-1.0, 1.0]:
		var gros: float = 1.0 if s > 0.0 else 0.72
		_bout(corps, sph, rouge, Vector3(s * 0.08, 0.1, 0.13), Basis().scaled(Vector3(0.06, 0.05, 0.08) * gros))
		_bout(corps, sph, rouge, Vector3(s * 0.08, 0.1, 0.2), Basis().scaled(Vector3(0.035, 0.03, 0.05) * gros))
		for l in range(3):
			var pa := Node3D.new()
			corps.add_child(pa)
			pa.position = Vector3(s * 0.07, 0.08, 0.06 - l * 0.06)
			_bout(pa, B._cylm(0.012, 0.018, 0.16, 6), rouge, Vector3(s * 0.06, -0.04, 0), Basis(Vector3.BACK, s * 1.0))
			pattes.append([pa, l * 1.3 + (0.0 if s > 0.0 else 0.7)])
		_bout(corps, B._cylm(0.008, 0.008, 0.09, 6), rouge, Vector3(s * 0.03, 0.18, 0.1), Basis(Vector3.RIGHT, 0.3))
		_bout(corps, sph, noir, Vector3(s * 0.03, 0.225, 0.115), Basis().scaled(Vector3.ONE * 0.016))
	var a0: float = 250.0
	M.ctx["bernard177"] = {"n": root, "corps": corps, "pattes": pattes, "a": a0, "sens": 1.0, "pause": 3.0, "cache": 0.0, "t": 0.0}
	var it: Dictionary = M.act(R.P(_dj(a0, DJ_BERNARD).x, 0, _dj(a0, DJ_BERNARD).z), "E : dire bonjour à Sire Bernard", func():
		(M.ctx["bernard177"] as Dictionary)["cache"] = 5.0
		M.say("« Bonjour, Sire Bernard ! » Clac : il rentre dans sa coquille. On voit juste deux yeux au bout de leurs tiges, qui te regardent de travers. « Il est timide, dit Firmin. Et il boude, parce qu'on ne l'a pas salué d'abord. »", 7.0), 1.0)
	(M.ctx["bernard177"] as Dictionary)["it"] = it
	_tick_donjon(M, 0.0)


## Les sept bougies de l'anniversaire de Pâquerette (elle a sept ans), sur le parapet de la galerie ;
## allumées la nuit.
static func _bougies_donjon(M) -> void:
	var R = M.R
	var k = R.kit
	var cols: Array = [Color(0.95, 0.5, 0.7), Color(0.45, 0.65, 0.95), Color(0.98, 0.85, 0.3), Color(0.5, 0.8, 0.45), Color(0.98, 0.98, 0.95), Color(0.98, 0.6, 0.25), Color(0.7, 0.5, 0.9)]
	var blanc: String = B._c(R, "bougie177_b", Color(0.98, 0.97, 0.94), 0.5)
	var angles: Array = [172.0, 202.0, 232.0, 262.0, 292.0, 322.0, 352.0]
	var y0: float = DJ_GAL + 0.95
	for i in range(7):
		var a: float = angles[i]
		var p: Vector3 = _dj(a, DJ_BORD + 0.11, y0)
		var key: String = B._c(R, "bougie177_%d" % i, cols[i], 0.5)
		for sg in range(4):
			k.cyl(R.L(p.x, y0 + sg * 0.1, p.z), 0.045, 0.045, 0.1, key if sg % 2 == 0 else blanc, 10)
		k.cyl(R.L(p.x, y0 + 0.4, p.z), 0.006, 0.006, 0.04, "noir", 4)
		if not R.day:
			k.cyl(R.L(p.x, y0 + 0.44, p.z), 0.02, 0.0, 0.07, "flamme", 6, false)
	if not R.day:
		for la in [217.0, 307.0]:
			var l: OmniLight3D = _omni(M, _dj(la, DJ_BORD + 0.3, y0 + 0.6), Color(1.0, 0.68, 0.38), 0.9, 5.0)
			(R.flames as Array).append([l, l.light_energy])
		R.bougie(DJ_TABLE.x - 0.05, 0.69, DJ_TABLE.y + 0.2, true)


## Les lumières : le jour, par la porte et la meurtrière (et les hublots : _hublots_donjon) ; la nuit, la
## lune par la porte, les bougies.
static func _lumieres_donjon(M) -> void:
	var R = M.R
	if R.day:
		_omni(M, Vector3(0, 6.5, 0), Color(1.0, 0.95, 0.86), 0.55, 12.0)
		_soleil(M, Vector3(0, 1.9, DJ_R + 0.35), Vector3(0, 0, -1.2), 26.0, 3.2)
		_soleil(M, Vector3(0, 5.75, DJ_R + 0.4), Vector3(0, DJ_GAL, 2.2), 22.0, 2.0)
	else:
		_omni(M, Vector3(0, 6.5, 0), Color(0.55, 0.62, 0.85), 0.12, 12.0)
		var s: SpotLight3D = _soleil(M, Vector3(0, 1.9, DJ_R + 0.35), Vector3(0, 0, -1.2), 26.0, 0.6)
		s.light_color = Color(0.6, 0.7, 1.0)


## Ce qui bouge dans le donjon : Sire Bernard (il marche, il rentre dans sa coquille), le sablier.
static func _tick_donjon(M, delta: float) -> void:
	var R = M.R
	if R == null:
		return
	var b: Variant = M.ctx.get("bernard177", null)
	if b is Dictionary and is_instance_valid((b as Dictionary)["n"]):
		var n: Node3D = b["n"]
		var corps: Node3D = b["corps"]
		var p: Vector3 = M.main._player_pos_v27()
		if p.distance_to(n.global_position) < 1.3:
			b["cache"] = maxf(float(b["cache"]), 2.5)
		b["cache"] = maxf(0.0, float(b["cache"]) - delta)
		var cache: bool = float(b["cache"]) > 0.0
		var sc: float = lerpf(corps.scale.x, 0.12 if cache else 1.0, clampf(delta * 7.0, 0.0, 1.0))
		corps.scale = Vector3.ONE * sc
		corps.position.z = lerpf(-0.06, 0.1, sc)
		b["t"] = float(b["t"]) + delta
		var marche: bool = false
		if not cache:
			if float(b["pause"]) > 0.0:
				b["pause"] = float(b["pause"]) - delta
			else:
				marche = true
				var a: float = float(b["a"]) + float(b["sens"]) * delta * rad_to_deg(0.13 / DJ_BERNARD)
				if a > 330.0 or a < 188.0:
					a = clampf(a, 188.0, 330.0)
					b["sens"] = -float(b["sens"])
					b["pause"] = 4.0 + fposmod(float(b["t"]) * 1.7, 4.0)
				b["a"] = a
		for pa in b["pattes"]:
			(pa[0] as Node3D).rotation.x = 0.45 * sin(float(b["t"]) * 13.0 + float(pa[1])) if marche else 0.0
		var a2: float = float(b["a"])
		var ou: Vector3 = _dj(a2, DJ_BERNARD)
		var tg: Vector3 = Vector3(cos(deg_to_rad(a2)), 0, -sin(deg_to_rad(a2))) * float(b["sens"])
		n.global_transform = Transform3D(Basis.looking_at(-tg, Vector3.UP), R.P(ou.x, 0.0, ou.z))
		if b.has("it"):
			(b["it"] as Dictionary)["pos"] = n.global_position
	var sb: Variant = M.ctx.get("sablier177", null)
	if sb is Dictionary and is_instance_valid((sb as Dictionary)["n"]):
		var sn: Node3D = sb["n"]
		if float(sb["tourne"]) > 0.0:
			sb["tourne"] = maxf(0.0, float(sb["tourne"]) - delta)
			var f: float = 1.0 - float(sb["tourne"]) / 0.8
			sn.rotation.x = float(sb["sens"]) - PI * (1.0 - smoothstep(0.0, 1.0, f))
			if float(sb["tourne"]) <= 0.0:
				sb["t"] = 0.0
				sn.rotation.x = float(sb["sens"])
		else:
			sb["t"] = float(sb["t"]) + delta
		var niveau: float = clampf(float(sb["t"]) / 60.0, 0.0, 1.0)
		var h: MeshInstance3D = sb["haut"]
		var bs: MeshInstance3D = sb["bas"]
		var dessus: MeshInstance3D = h if h.global_position.y > bs.global_position.y else bs
		var dessous: MeshInstance3D = bs if dessus == h else h
		dessus.scale = Vector3(1.0, maxf(0.02, 1.0 - niveau), 1.0)
		dessous.scale = Vector3(1.0, maxf(0.02, niveau), 1.0)
		(sb["filet"] as CPUParticles3D).emitting = niveau < 1.0 and float(sb["tourne"]) <= 0.0


## Firmin, le gardien du château (un Petit) : il arrose les murs, range les coquillages de Pâquerette.
static func _firmin(M) -> void:
	var ecouter := func() -> void:
		M.main.sfx("vague", M.R.P(0.0, 1.0, 0.0), -8.0)
		M.say("Firmin te tend la grande conque : « Écoute. » Chhhh… la mer, tout entière, qui roule et se retire. « Pâquerette dit que c'est la mer qui habite dedans. Je crois qu'elle a raison. »", 7.0)
	var arroser := func() -> void:
		M.say("Firmin plonge un gobelet dans le seau et arrose le mur, à petits coups : le sable boit l'eau de mer et fonce. « Voilà. Un château, ça a soif, comme un jardin. Le sable sec s'écroule ; le sable mouillé tient. »", 7.0)
	# (Firmin est un vieux marin de Port-Azur, arrivé par le ponton : il en a gardé l'allure)
	var style0: String = str(M.ctx.get("style", ""))
	M.ctx["style"] = "azur"
	B._marchand(M, DJ_FIRMIN.x, DJ_FIRMIN.y, 0.0, "debout", "vieux", "Firmin",
		["Chut… écoute. On entend la mer à travers les murs. Le sable laisse passer les bruits doux.",
			"Pâquerette passe tous les matins. Elle se met à genoux, colle un œil à la porte et dit : « Bonjour, Monsieur Firmin ! » Les tours en tremblent.",
			"Le sable sec s'écroule, le sable mouillé tient. Tout le secret d'un château, c'est ça.",
			"Ne marche pas sur Sire Bernard. Il est petit, il se vexe pour un rien, et il pince."],
		{"bonjour": "Bienvenue au Château des Petits ! Essuie tes pieds… enfin, non : ici, tout est en sable.",
			"services": [{"label": "Écouter la mer dans la conque", "cb": ecouter}, {"label": "Aider Firmin à arroser les murs", "cb": arroser}],
			"infos": ["Pâquerette l'a construit pour les Petits, un matin d'été, avec son seau rouge et sa cuillère à café. Le donjon, elle l'a creusé de l'intérieur, grain par grain, pour qu'on puisse y habiter. Puis elle a attendu que quelqu'un vienne. Je suis venu.",
				"Chaque matin, elle pose un coquillage devant la porte. Je les mets dans le mur, tout autour. Un par jour. Compte-les, si tu as le temps : moi, j'ai arrêté à deux cents.",
				"Deux fois par jour, je monte l'eau de mer et j'arrose les murs. Regarde l'ardoise : la marée, l'arrosage, tout est noté.",
				"Sire Bernard ? Le bernard-l'ermite. Il était là avant moi : il dit que c'est son château. Je le laisse dire. Le soir, il dort près de la grande conque.",
				"Mon sac de couchage, c'est une chaussette de Pâquerette. Le vent l'a emportée de la corde à linge ; elle est tombée sur la grève. Elle sent encore le savon."]})
	M.ctx["style"] = style0
	M.ctx["cloche170"] = false
	M.ctx["bonjour170"] = ["Tiens, de la visite ! Entre, il fait frais dedans.", "Attention dans l'escalier : les marches du haut s'effritent un peu."]
	M.ctx["bonjour_nuit170"] = ["Tu tombes bien : j'ai allumé les bougies d'anniversaire de Pâquerette. Sept, parce qu'elle a sept ans.", "Chut… la mer monte. Écoute : on l'entend à travers le sable."]
