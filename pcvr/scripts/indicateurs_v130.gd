extends Node3D
## V130 : un petit signe au-dessus des personnages qui ont « un truc en plus ».
##  ! doré   : une quête à proposer (le carnet, ou une demande d'un habitant) ;
##  ? doré   : une quête en cours qui passe par lui (on a quelque chose à lui dire, à lui rendre) ;
##  ✦ rose   : un secret, un cadeau, un service spécial (les champignons de Lulu, la boule de
##             cristal d'Agathe, la vieille canne de Barnabé…) ;
##  ◆ vert   : un commerce, un passeur, une auberge (plus discret : visible de près seulement).
## Le signe flotte doucement au-dessus de la tête, et disparaît dès qu'il n'y a plus rien à
## prendre (le champignon dans le sac, la quête finie). Il se cache pendant qu'on lui parle,
## et quand il dort ; quand sa bulle de paroles est affichée, il monte au-dessus d'elle.
## Les personnages sont examinés quelques-uns à la fois, à chaque image (pas tous d'un coup).

const LOIN: float = 45.0          # portée des signes ! ? ✦
const PRES: float = 18.0          # portée du signe ◆
const PAR_IMAGE: int = 8
const GENRES := ["quete", "suite", "secret", "service"]
const COULEURS := {
	"quete": Color(1.0, 0.8, 0.22), "suite": Color(1.0, 0.86, 0.42),
	"secret": Color(1.0, 0.5, 0.92), "service": Color(0.42, 0.92, 0.82),
}
## Symboles des sujets des services (le premier caractère de l'intitulé).
const SYMBOLES_SECRET := ["✦", "♥", "☀"]

var main: Node
var actif: bool = true
var genres: Dictionary = {}       # pnj -> genre ("" : rien)
var signes: Dictionary = {}       # pnj -> Sprite3D
var _i: int = 0
var _ctx: Dictionary = {}
var _ctx_clock: float = 0.0
static var _tex: Dictionary = {}


func setup(main_node: Node) -> void:
	main = main_node


# =================================================================== ce qu'un personnage a en plus

## Le genre de signe d'un personnage : "quete", "suite", "secret", "service" ou "".
func genre_de(npc: Node) -> String:
	if npc == null or not is_instance_valid(npc) or npc.get("profile") == null:
		return ""
	var best: int = 99
	var j: Node = main.get("journal_v56")
	if j != null and j.has_method("topics_for"):
		for t in j.topics_for(npc):
			best = mini(best, _rang(_genre_sujet(t)))
	var brain = npc.get("brain")
	if brain != null:
		best = mini(best, _rang(_genre_cerveau(brain)))
	return GENRES[best] if best < GENRES.size() else ""


func _rang(g: String) -> int:
	var i: int = GENRES.find(g)
	return i if i >= 0 else 99


func _genre_sujet(t: Dictionary) -> String:
	var id: String = str(t.get("id", ""))
	var label: String = str(t.get("label", ""))
	if id.begins_with("q56:offre:"):
		return "quete"
	if id.begins_with("q56:etape:") or label.begins_with("★"):
		return "suite"
	var c: String = label.substr(0, 1)
	if c in SYMBOLES_SECRET:
		return "secret"
	if id.begins_with("q56:service:") or id == "boutique":
		return "service"
	return ""


func _genre_cerveau(brain) -> String:
	var data: Dictionary = brain.get("data") if brain.get("data") is Dictionary else {}
	var mem: Dictionary = brain.get("memoire") if brain.get("memoire") is Dictionary else {}
	var best: int = 99
	# l'ancienne quête d'un habitant (les coquillages de Barnabé, les champignons de l'elfe…)
	if data.has("quete") and mem.has("quete"):
		var st: String = str(mem["quete"])
		if st == "":
			best = mini(best, _rang("quete"))
		elif st == "demandee":
			best = mini(best, _rang("suite"))
	# les sujets du cerveau marqués d'une étoile (la dette de Jambe-de-Bois…) et la boutique
	if brain.has_method("topics"):
		for t in brain.topics(_ctx):
			var g: String = _genre_sujet(t)
			if str(t.get("id", "")) == "quete":
				g = "suite"
			best = mini(best, _rang(g))
	# un cadeau qu'il ne fait qu'une fois, et qu'il est prêt à faire
	var rep: Dictionary = data.get("repliques", {}) if data.get("repliques", {}) is Dictionary else {}
	for k in rep:
		if not (rep[k] is Array):
			continue
		for r in rep[k]:
			if not (r is Dictionary) or str(r.get("action", "")) != "donne":
				continue
			var pose: String = str(r.get("pose", ""))
			if pose == "" or brain._has_fact(pose):
				continue
			if brain.has_method("_ok") and not brain._ok(r.get("si", {}), _ctx):
				continue
			best = mini(best, _rang("secret"))
	return GENRES[best] if best < GENRES.size() else ""


# =================================================================== les signes

## L'image d'un signe : un halo, et le symbole cerné de sombre (calculé une fois).
static func texture(genre: String) -> Texture2D:
	if _tex.has(genre):
		return _tex[genre]
	var N: int = 128
	var img := Image.create(N, N, false, Image.FORMAT_RGBA8)
	var col: Color = COULEURS.get(genre, Color.WHITE)
	var px: float = 2.0 / N
	for y in range(N):
		for x in range(N):
			var p := Vector2((x + 0.5) / N * 2.0 - 1.0, (y + 0.5) / N * 2.0 - 1.0)
			var d: float = _sdf(genre, p)
			var r: float = p.length()
			# halo
			var halo: float = clampf(1.0 - r, 0.0, 1.0)
			halo = halo * halo * 0.55
			var c := Color(col.r, col.g, col.b, halo)
			# contour sombre (0,07 d'épaisseur) puis le symbole, lissés sur un pixel et demi
			var a_out: float = clampf(0.5 - (d - 0.075) / (px * 1.5), 0.0, 1.0)
			var a_in: float = clampf(0.5 - d / (px * 1.5), 0.0, 1.0)
			var dark := Color(0.12, 0.07, 0.03, 1.0) if genre != "service" else Color(0.03, 0.12, 0.1, 1.0)
			c = c.blend(Color(dark.r, dark.g, dark.b, a_out * 0.92))
			# le symbole : plus clair en haut, comme éclairé
			var light: Color = col.lightened(0.45 - p.y * 0.3)
			c = c.blend(Color(light.r, light.g, light.b, a_in))
			if genre == "service":
				var g2: float = clampf(0.5 - _grave(p) / (px * 1.5), 0.0, 1.0)
				c = c.blend(Color(dark.r, dark.g, dark.b, g2 * 0.6 * a_in))
			img.set_pixel(x, y, c)
	img.generate_mipmaps()
	var t := ImageTexture.create_from_image(img)
	_tex[genre] = t
	return t


static func _capsule(p: Vector2, a: Vector2, b: Vector2, r: float) -> float:
	var ab: Vector2 = b - a
	var t: float = clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	return p.distance_to(a + ab * t) - r


## Distance signée au symbole (négative dedans), repère [-1, 1], y vers le bas.
static func _sdf(genre: String, p: Vector2) -> float:
	match genre:
		"quete":
			var bar: float = _capsule(p, Vector2(0, -0.58), Vector2(0, 0.14), lerpf(0.15, 0.09, clampf((p.y + 0.58) / 0.72, 0.0, 1.0)))
			var dot: float = p.distance_to(Vector2(0, 0.46)) - 0.13
			return minf(bar, dot)
		"suite":
			var c := Vector2(0, -0.22)
			var r: float = 0.3
			var ang: float = atan2(p.y - c.y, p.x - c.x)
			# l'arc du « ? » : de la gauche, par le haut, jusqu'en bas à droite
			var arc: float = absf(p.distance_to(c) - r) - 0.11
			var inside_arc: bool = ang < 0.75 and ang > -PI or ang > 2.9
			if not inside_arc:
				arc = 9.0
			var end_a: float = 0.75
			var e := c + Vector2(cos(end_a), sin(end_a)) * r
			var stem: float = _capsule(p, e, Vector2(0, 0.17), 0.11)
			var l := c + Vector2(cos(2.9), sin(2.9)) * r
			var cap_l: float = p.distance_to(l) - 0.11
			var dot: float = p.distance_to(Vector2(0, 0.47)) - 0.12
			return minf(minf(arc, cap_l), minf(stem, dot))
		"secret":
			var r2: float = p.length()
			var th: float = atan2(p.y, p.x)
			var k: float = pow(absf(cos(2.0 * th)), 3.5)
			var rs: float = 0.22 + 0.46 * k
			return (r2 - rs) * (0.55 + 0.45 * (1.0 - k))
		"service":
			return p.length() - 0.42
	return 1.0


## Gravure de la pièce (le signe des commerces) : un anneau et un losange.
static func _grave(p: Vector2) -> float:
	var inner: float = absf(p.length() - 0.31) - 0.025
	var diamond: float = (absf(p.x) + absf(p.y) * 1.25 - 0.17) * 0.7
	return minf(inner, diamond)


func _signe(npc: Node3D) -> Sprite3D:
	if signes.has(npc) and is_instance_valid(signes[npc]):
		return signes[npc]
	var s := Sprite3D.new()
	s.name = "Signe_v130"
	s.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	s.shaded = false
	s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
	s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	s.render_priority = 2
	npc.add_child(s)
	signes[npc] = s
	return s


func _hauteur(npc: Node) -> float:
	var vl = npc.get("vr_label")
	if vl != null and is_instance_valid(vl):
		return (vl as Node3D).position.y + 0.34
	return 2.3


# =================================================================== chaque image

func _process(delta: float) -> void:
	if main == null or not bool(main.get("game_started")):
		return
	var npcs: Array = main.npcs_v31
	if npcs.is_empty():
		return
	_ctx_clock -= delta
	if _ctx_clock <= 0.0 or _ctx.is_empty():
		_ctx_clock = 1.5
		_ctx = main._npc_ctx_v31() if main.has_method("_npc_ctx_v31") else {}
	var pp: Vector3 = main._player_pos_v27() if main.has_method("_player_pos_v27") else Vector3.ZERO
	# quelques personnages examinés à chaque image
	for k in range(mini(PAR_IMAGE, npcs.size())):
		_i = (_i + 1) % npcs.size()
		var n = npcs[_i]
		if n == null or not is_instance_valid(n):
			continue
		var d: float = (n as Node3D).global_position.distance_to(pp)
		genres[n] = genre_de(n) if (actif and d < LOIN + 10.0) else ""
	# les signes : visibles, flottants, cachés quand il le faut
	var t: float = Time.get_ticks_msec() / 1000.0
	var parle: Node = main.get("talking_npc_v31")
	for n in genres.keys():
		if not is_instance_valid(n):
			genres.erase(n)
			signes.erase(n)
			continue
		var g: String = genres[n]
		var npc: Node3D = n
		if g == "":
			if signes.has(npc) and is_instance_valid(signes[npc]):
				(signes[npc] as Sprite3D).visible = false
			continue
		var d2: float = npc.global_position.distance_to(pp)
		var portee: float = PRES if g == "service" else LOIN
		var bub = npc.get("bubble")
		var cache: bool = d2 > portee or not npc.is_visible_in_tree() or npc == parle or npc.get("_asleep") == true
		# la bulle de paroles affichée : le signe monte au-dessus d'elle
		var dessus: float = 0.0
		if bub != null and is_instance_valid(bub) and (bub as Label3D).visible:
			var lb: Label3D = bub
			var lignes: int = maxi(1, int(ceil(lb.text.length() / 30.0)))
			dessus = (lb.position.y - _hauteur(npc)) + lignes * lb.font_size * 1.25 * lb.pixel_size * 0.5 + 0.22
		var s: Sprite3D = _signe(npc)
		if cache:
			s.visible = false
			continue
		if s.get_meta("genre", "") != g:
			s.texture = texture(g)
			s.set_meta("genre", g)
		s.visible = true
		var phase: float = float(npc.get_instance_id() % 97) * 0.21
		s.position = Vector3(0, _hauteur(npc) + maxf(dessus, 0.0) + sin(t * 2.2 + phase) * 0.045, 0)
		# un peu plus grand de loin (lisible), plus petit pour les commerces
		var taille: float = (0.0026 if g != "service" else 0.0019) * (1.0 + clampf(d2 / 30.0, 0.0, 1.2))
		s.pixel_size = taille
		var fade: float = clampf((portee - d2) / 6.0, 0.0, 1.0)
		var pulse: float = 0.85 + 0.15 * sin(t * 3.0 + phase) if g in ["quete", "secret"] else 1.0
		s.modulate = Color(1, 1, 1, fade * pulse)


## Combien de signes sont affichés (tests).
func visibles() -> Dictionary:
	var out: Dictionary = {}
	for n in signes:
		if is_instance_valid(n) and is_instance_valid(signes[n]) and (signes[n] as Sprite3D).visible:
			var g: String = str((signes[n] as Sprite3D).get_meta("genre", ""))
			out[g] = int(out.get(g, 0)) + 1
	return out
