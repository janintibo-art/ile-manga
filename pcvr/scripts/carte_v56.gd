extends Control
## V56 : la carte du carnet. Deux vues : l'archipel entier (relief ombré, fonds marins,
## noms des lieux découverts) et le plan de Port-Azur (rues, maisons, boutiques).
## Les images sont préparées une fois pour toutes (tools/carte_v56.py, à partir du relief
## réel du jeu) ; par-dessus, on dessine en direct le joueur, le bateau de ligne, les
## objectifs des quêtes en cours et, si on le demande, un personnage.
## Glisser pour déplacer, molette (ou + / −) pour zoomer.

const ARCH_TEX := "res://assets/textures/carte/archipel.png"
const AZUR_TEX := "res://assets/textures/carte/port_azur.png"
## Rectangle du monde couvert par la carte de l'archipel (x0, z0, x1, z1)
## (V59 : la carte s'étend à l'est jusqu'à la grande île)
## (V68 : au nord jusqu'à la Balafre ; V69 : à l'ouest jusqu'à l'Île des Trois Soleils ;
## V70 : au sud jusqu'à l'Île de Braise)
const ARCH_RECT := Rect2(-1320.0, -960.0, 2580.0, 1960.0)
## Rectangle du plan de Port-Azur, dans le repère de la ville (x0, z0 = côté collines… voir _to_map)
const AZUR_X0: float = -180.0
const AZUR_X1: float = 140.0
const AZUR_Z0: float = -110.0
const AZUR_Z1: float = 170.0

const PLACES := [
	["Île du village", Vector2(0, 4), ""],
	["Île de la jungle", Vector2(0, -330), "vu_jungle"],
	["Bois-Doré", Vector2(330, -165), "vu_elfes"],
	["Montagne de Feu", Vector2(-330, -160), "vu_nains"],
	["Port-Azur", Vector2(300, 200), ""],
	["Île flottante", Vector2(40, 400), "ventaile"],
	["Atlantide", Vector2(-220, 260), "atlantide"],
	["Jardin de corail", Vector2(-150, 205), "masque"],
	["Épave de la Sirène Noire", Vector2(-300, 330), "masque"],
	["Fosse aux Méduses", Vector2(-154, 360), "masque"],
	["Temple oublié", Vector2(-18, -30), "temple"],
	["Carène", Vector2(690, -128), "grande_ile"],
	["La grande île de l'est", Vector2(1130, 70), "grande_ile"],
	["Tazira", Vector2(935, 118), "tazira"],
	["Cliquetis", Vector2(960, -342), "cliquetis"],
	["Ramure", Vector2(1112, -152), "ramure"],
	["Hautes terres", Vector2(1080, -300), "grande_ile"],
	["Forêt des brumes", Vector2(1150, -60), "grande_ile"],
	["Désert du sud", Vector2(1010, 10), "grande_ile"],
	["Cœur-de-Pierre", Vector2(940, -170), "grande_ile"],
	["Porte aux Quatre Sceaux", Vector2(862, -138), "porte_sceaux"],
	# V63 : la grande enquête
	["Tombeau de la Dune qui Marche", Vector2(1032, -70), "tombeau_dune"],
	["Bergerie du Vent", Vector2(1021, -242), "bergerie_vent"],
	# V67 : l'île des sorciers
	["Arcanelle", Vector2(-300, -545), "arcanelle"],
	# V68 : l'île des pirates
	["Port-Coutelas", Vector2(410, -610), "balafre"],
	["Rocher du Crâne", Vector2(440, -768), "tresor_crane"],
	["Fort Maudit", Vector2(550, -642), "balafre"],
	# V69 : l'Île des Trois Soleils
	["Per-Hâpy", Vector2(-764, -175), "soleils_egypte"],
	["Pyramide de Rê", Vector2(-760, 40), "soleils_egypte"],
	["Yaxché", Vector2(-965, -268), "soleils_maya"],
	["Cénote sacré", Vector2(-1044, -392), "soleils_maya"],
	["Aztlán", Vector2(-1085, -2), "soleils_azteque"],
	["Mont Fumant", Vector2(-1198, -212), "soleils"],
	["Autel des Trois Soleils", Vector2(-918, -222), "soleils"],
	# V70 : l'Île de Braise
	["Pandémonia", Vector2(-810, 540), "pandemonia"],
	["Port de Cendre", Vector2(-619, 349), "pandemonia"],
	["Grand Brasier", Vector2(-1040, 770), "braise"],
	["Ruines de l'Ancien Pandémonium", Vector2(-1106, 410), "braise"],
	["Bois de Cendre", Vector2(-694, 796), "braise"],
	["Champ de lave", Vector2(-932, 814), "braise"],
	["Sources de soufre", Vector2(-891, 765), "braise"],
	# V71 : l'Île de Montjoie
	["Montjoie", Vector2(790, 590), "montjoie_ville"],
	["Port des Mouettes", Vector2(568, 408), "montjoie"],
	["Lac des Grenouilles", Vector2(1028, 698), "montjoie"],
	["Bois des Lutins", Vector2(968, 424), "montjoie"],
	["Les Crocs", Vector2(560, 790), "montjoie"],
	["Champs du Sud", Vector2(774, 850), "montjoie"],
	["Donjon des Mille Marches", Vector2(622, 736), "montjoie"],
]

var main: Node
var carnet: Node
var mode: String = "archipel"
var zoom: float = 1.0
var center: Vector2 = Vector2(540, 540)       # pixel de la carte au centre de la vue
var _tex: Dictionary = {}
var _drag: bool = false
var _focus_npc: String = ""
var _focus_quest: String = ""
var _font: Font
var _font_b: Font


func setup(main_node: Node, carnet_node: Node) -> void:
	main = main_node
	carnet = carnet_node
	mouse_filter = Control.MOUSE_FILTER_STOP
	if ResourceLoader.exists(ARCH_TEX):
		_tex["archipel"] = load(ARCH_TEX)
	if ResourceLoader.exists(AZUR_TEX):
		_tex["azur"] = load(AZUR_TEX)
	_font = carnet._font("Italic")
	_font_b = carnet._font("BoldItalic")
	set_mode("archipel")


func _tex_size() -> Vector2:
	var t: Texture2D = _tex.get(mode, null)
	return Vector2(t.get_width(), t.get_height()) if t != null else (Vector2(2580, 1440) if mode == "archipel" else Vector2(960, 840))


func set_mode(m: String) -> void:
	mode = m
	var ts: Vector2 = _tex_size()
	center = ts * 0.5
	zoom = 0.0
	if mode == "azur":
		var j: Node = main.get("journal_v56") if main != null else null
		if j != null and not bool(j.flags.get("carte_azur", false)):
			pass
	queue_redraw()


func _fit_zoom() -> float:
	var ts: Vector2 = _tex_size()
	return minf(size.x / ts.x, size.y / ts.y)


func _z() -> float:
	if zoom <= 0.0:
		zoom = maxf(_fit_zoom(), 0.05)
	return zoom


func zoom_by(k: float) -> void:
	zoom = clampf(_z() * k, _fit_zoom() * 0.8, 6.0)
	queue_redraw()


## Monde -> pixel de l'image de la carte.
func _to_map(w: Vector3) -> Vector2:
	var ts: Vector2 = _tex_size()
	if mode == "archipel":
		return Vector2((w.x - ARCH_RECT.position.x) / ARCH_RECT.size.x * ts.x, (w.z - ARCH_RECT.position.y) / ARCH_RECT.size.y * ts.y)
	var t: Vector2 = preload("res://scripts/ile_azur_v56.gd").to_town(w.x, w.z)
	return Vector2((t.x - AZUR_X0) / (AZUR_X1 - AZUR_X0) * ts.x, (AZUR_Z1 - t.y) / (AZUR_Z1 - AZUR_Z0) * ts.y)


## Pixel de la carte -> écran.
func _to_screen(mp: Vector2) -> Vector2:
	return size * 0.5 + (mp - center) * _z()


func _w2s(w: Vector3) -> Vector2:
	return _to_screen(_to_map(w))


func center_on_player() -> void:
	if main == null:
		return
	var p: Vector3 = main._player_pos_v27()
	if mode == "azur" and not _in_azur_map(p):
		set_mode("archipel")
	center = _to_map(p)
	zoom = maxf(_z(), _fit_zoom() * 2.0)
	queue_redraw()


func _in_azur_map(p: Vector3) -> bool:
	var t: Vector2 = preload("res://scripts/ile_azur_v56.gd").to_town(p.x, p.z)
	return t.x > AZUR_X0 and t.x < AZUR_X1 and t.y > AZUR_Z0 and t.y < AZUR_Z1


func focus_npc(id: String) -> void:
	_focus_npc = id
	var n: Node = _npc(id)
	if n != null:
		set_mode("azur" if _in_azur_map(n.global_position) else "archipel")
		center = _to_map(n.global_position)
		zoom = _fit_zoom() * 2.0
	queue_redraw()


func focus_quest(id: String) -> void:
	_focus_quest = id
	var pts: Array = _quest_targets(id)
	if not pts.is_empty():
		var p: Vector3 = pts[0]
		set_mode("azur" if _in_azur_map(p) else "archipel")
		center = _to_map(p)
		zoom = _fit_zoom() * 1.8
	queue_redraw()


func _npc(id: String) -> Node:
	for n in main.npcs_v31:
		if is_instance_valid(n) and str(n.profile.get("id", "")) == id:
			return n
	return null


## Où aller pour avancer une quête (positions monde).
func _quest_targets(id: String) -> Array:
	var j: Node = main.get("journal_v56")
	if j == null:
		return []
	var out: Array = []
	var q: Dictionary = j.quest(id)
	if q.is_empty():
		if id.begins_with("pnj_"):
			var n0: Node = _npc(id.substr(4))
			if n0 != null:
				out.append(n0.global_position)
		return out
	var st: String = j.state(id)
	if st in ["", "connue"]:
		var g: Node = _npc(str(q["donneur"]))
		if g != null:
			out.append(g.global_position)
		return out
	if st != "en_cours":
		return out
	var e: Dictionary = j._step(id)
	match str(e.get("type", "")):
		"parler", "objets", "rendre", "un_de":
			var n: Node = _npc(str(e.get("pnj", "")))
			if n != null:
				out.append(n.global_position)
		"ramasser":
			for where in e.get("lieux", []):
				if not main.inventory_v28.taken.has("q56_%s_%s" % [id, str(where)]) and j.lieux.has(str(where)):
					out.append(j.lieux[str(where)])
		"creuser":
			if j.lieux.has(str(e["lieu"])):
				out.append(j.lieux[str(e["lieu"])])
		"course":
			for k in ["fontaine", "phare_porte"]:
				if j.lieux.has(k):
					out.append(j.lieux[k])
		"etat":
			if str(e.get("cle", "")) == "cristal":
				out.append(Vector3(-220, -30, 260))
			if str(e.get("cle", "")) in ["porte_sceaux", "porte_ouverte"]:
				var gr: Node = main.get("grande_v59")
				if gr != null and gr.get("ile") != null and gr.ile != null:
					out.append(gr.ile.door_pos)
			# V63 : les sites des quatre sceaux
			var sc: Node = main.get("sceaux_v63")
			if sc != null:
				match str(e.get("cle", "")):
					"sceau_sables":
						out.append(sc.tomb_door_xf.origin)
					"sceau_airain":
						out.append(Vector3(sc.BERG.x, 0, sc.BERG.y))
					"sceau_brumes":
						if sc.pond_c != Vector3.INF:
							out.append(sc.pond_c)
					"sceau_embruns":
						if sc.proue_at != Vector3.INF:
							out.append(sc.proue_at)
			# V71 : l'Île de Montjoie (le donjon, le camp des gobelins, le lac, la Chaumière, la Guilde)
			var mj: Node = main.get("montjoie_v71")
			if mj != null and mj.get("city") != null and mj.city != null:
				match str(e.get("cle", "")):
					"roi_gelatineux", "donjon_5", "mille_marches":
						if mj.dehors != null:
							out.append(mj.dehors.dungeon_door)
					"chef_gobelin":
						out.append(mj.ile.W(206.0, -236.0))
					"grenouilles_lac":
						out.append(mj.ile.W(238.0, 78.0))
					"chaumiere":
						out.append(mj.city.lieux.chaumiere_door)
					"inscription", "rang_d", "compagnon":
						out.append(mj.city.lieux.guild_counter)
			# V70 : l'Île de Braise (la porte des Neuf Cercles, le Cœur-Brasier, Pépin, l'arène, les lanternes, les repaires)
			var br: Node = main.get("braise_v70")
			if br != null and br.get("city") != null and br.city != null:
				match str(e.get("cle", "")):
					"cercles", "porte_cercles", "titan_givre", "coeur_vif":
						out.append(br.city.lieux.porte_cercles)
					"pepin_trouve":
						if br.dehors != null:
							out.append(br.dehors.pepin_hide)
					"tournoi":
						out.append(br.city.basse.arena["c"])
					"sept_lanternes":
						for k in br.city.lanterns:
							if not bool((br.state.get("lanternes", {}) as Dictionary).get(k, false)):
								out.append(br.city.lanterns[k]["pos"])
					"fete_lanternes":
						if br.fete != null:
							out.append(br.fete.ctr)
					"chiens_champ":
						out.append(br.lairs[0]["c"] if not br.lairs.is_empty() else br.ile.W(-60.0, 214.0))
					"gargouilles_ruines":
						out.append(br.lairs[1]["c"] if br.lairs.size() > 1 else br.ile.W(-236.0, -190.0))
			# V69 : l'Île des Trois Soleils (le Sphinx, Miou, les trois temples, les jaguars, l'autel)
			var so: Node = main.get("soleils_v69")
			if so != null and so.get("egypte") != null and so.egypte != null:
				match str(e.get("cle", "")):
					"sphinx":
						out.append(so.egypte.sphinx_talk)
					"chat_trouve":
						out.append(so.egypte.objets["mastaba_chat"])
					"pyramide", "apophis":
						out.append(so.egypte.pyramid_door)
					"calendrier", "xibalba", "camazotz":
						out.append(so.maya.temple_door)
					"offrandes", "cinq_soleils", "cipactli":
						out.append(so.azteque.temple_gate)
					"jaguars_volcan":
						out.append(so.ile.W(-190.0, -90.0))
					"trois_soleils":
						out.append(so.ile.pads_world["autel"])
			# V68 : la Balafre (le perchoir de Rhubarbe, Vieille-Dent, le Cirque du Crâne, le trésor)
			var pv: Node = main.get("pirates_v68")
			if pv != null and pv.get("port") != null and pv.port != null:
				match str(e.get("cle", "")):
					"perroquet_trouve":
						out.append(pv.port.perch_pos)
					"vieille_dent":
						out.append(pv.ile.W(pv.VIEILLE_DENT.x, pv.VIEILLE_DENT.y))
					"capitaine_os":
						out.append(pv.port.cirque_center)
					"tresor_crane":
						out.append(pv.port.treasure_pos)
					"champions_3":
						for cid in pv.CHAMPIONS:
							var cn: Node = _npc(str(cid))
							if cn != null and not bool((pv.state["champions"] as Dictionary).get(cid, false)):
								out.append(cn.global_position)
	if e.has("apparait"):
		for w2 in e["apparait"]:
			if j.lieux.has(str(w2)) and not main.inventory_v28.taken.has("q56_%s_%s" % [id, str(w2)]):
				out.append(j.lieux[str(w2)])
	return out


# =================================================================== entrées

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.button_index == MOUSE_BUTTON_LEFT:
			_drag = mb.pressed
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_at(mb.position, 1.2)
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_at(mb.position, 1.0 / 1.2)
		accept_event()
	elif event is InputEventMouseMotion and _drag:
		center -= (event as InputEventMouseMotion).relative / _z()
		queue_redraw()
		accept_event()


func _zoom_at(screen: Vector2, k: float) -> void:
	var before: Vector2 = center + (screen - size * 0.5) / _z()
	zoom = clampf(_z() * k, _fit_zoom() * 0.8, 6.0)
	center = before - (screen - size * 0.5) / zoom
	queue_redraw()


# =================================================================== dessin

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.16, 0.24))
	var t: Texture2D = _tex.get(mode, null)
	var ts: Vector2 = _tex_size()
	var tl: Vector2 = _to_screen(Vector2.ZERO)
	if t != null:
		draw_texture_rect(t, Rect2(tl, ts * _z()), false)
	else:
		draw_rect(Rect2(tl, ts * _z()), Color(0.16, 0.36, 0.48))
		draw_string(ThemeDB.fallback_font, size * 0.5, "(carte en préparation)", HORIZONTAL_ALIGNMENT_CENTER, -1, 20)
	var j: Node = main.get("journal_v56")
	var tr: Dictionary = main._npc_ctx_v31().get("trouvailles", {})
	# les lieux
	if mode == "archipel":
		for pl in PLACES:
			var key: String = str(pl[2])
			var known: bool = key == "" or int(tr.get(key, 0)) > 0 or (j != null and bool(j.flags.get(key, false)))
			var sp: Vector2 = _w2s(Vector3(pl[1].x, 0, pl[1].y))
			var txt: String = str(pl[0]) if known else "?"
			var fs: int = int(clampf(17.0 * sqrt(_z() / maxf(_fit_zoom(), 0.01)), 14.0, 30.0))
			var f: Font = _font_b if _font_b != null else ThemeDB.fallback_font
			var w: float = f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			var pos: Vector2 = sp + Vector2(-w * 0.5, -10)
			draw_string_outline(f, pos, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 5, Color(0.98, 0.95, 0.85, 0.9))
			draw_string(f, pos, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.22, 0.14, 0.08) if known else Color(0.35, 0.35, 0.4))
		# la ligne du bateau de ligne
		var az: Node = main.get("azur_v56")
		if az != null and az.ferry != null:
			var a: Vector2 = _w2s(az.ferry.berth_v.origin)
			var b: Vector2 = _w2s(az.ferry.berth_a.origin)
			_dashed(a, b, Color(0.95, 0.95, 1.0, 0.8), 2.0)
	# le bateau de ligne
	var az2: Node = main.get("azur_v56")
	if az2 != null and az2.ferry != null:
		var fp: Vector2 = _w2s(az2.ferry.pos)
		_glyph(fp, "⚓", Color(0.12, 0.2, 0.4), 22)
	# les objectifs des quêtes en cours (et la quête demandée)
	if j != null:
		var ids: Array = []
		for q in j.QUETES:
			if j.state(str(q["id"])) == "en_cours":
				ids.append(str(q["id"]))
		if _focus_quest != "" and not ids.has(_focus_quest):
			ids.append(_focus_quest)
		for qid in ids:
			for w in _quest_targets(str(qid)):
				var sp2: Vector2 = _w2s(w)
				var big: bool = str(qid) == _focus_quest
				draw_circle(sp2, 13.0 if big else 9.0, Color(1.0, 0.8, 0.25, 0.35))
				_glyph(sp2, "★", Color(0.85, 0.5, 0.05) if big else Color(0.95, 0.65, 0.1), 26 if big else 20)
	# le personnage cherché
	if _focus_npc != "":
		var n: Node = _npc(_focus_npc)
		if n != null:
			var sp3: Vector2 = _w2s(n.global_position)
			draw_circle(sp3, 11.0, Color(0.3, 0.8, 1.0, 0.4))
			draw_circle(sp3, 5.0, Color(0.1, 0.4, 0.8))
			var nm: String = str(n.display_name)
			var f2: Font = _font_b if _font_b != null else ThemeDB.fallback_font
			draw_string_outline(f2, sp3 + Vector2(12, 6), nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, 5, Color(1, 1, 1, 0.9))
			draw_string(f2, sp3 + Vector2(12, 6), nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.05, 0.2, 0.45))
	# le joueur : une flèche dans le sens du regard
	var p: Vector3 = main._player_pos_v27()
	var look: Vector3 = Vector3.FORWARD
	if main.xr_active and main.xr_camera != null:
		look = -main.xr_camera.global_basis.z
	elif main.get("hero_v28") != null:
		look = main.hero_v28.facing
	var ps: Vector2 = _w2s(p)
	var dir2: Vector2 = (_w2s(p + Vector3(look.x, 0, look.z).normalized() * 10.0) - ps).normalized()
	if dir2.length() < 0.5:
		dir2 = Vector2.UP
	var side: Vector2 = Vector2(-dir2.y, dir2.x)
	var tip: Vector2 = ps + dir2 * 15.0
	var pts := PackedVector2Array([tip, ps - dir2 * 9.0 + side * 9.0, ps - dir2 * 4.0, ps - dir2 * 9.0 - side * 9.0])
	draw_colored_polygon(pts, Color(0.85, 0.1, 0.1))
	draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]]), Color(1, 1, 1), 2.0)


func _glyph(at: Vector2, g: String, c: Color, s: int) -> void:
	var f: Font = ThemeDB.fallback_font
	var w: float = f.get_string_size(g, HORIZONTAL_ALIGNMENT_LEFT, -1, s).x
	draw_string_outline(f, at + Vector2(-w * 0.5, s * 0.35), g, HORIZONTAL_ALIGNMENT_LEFT, -1, s, 4, Color(1, 1, 1, 0.95))
	draw_string(f, at + Vector2(-w * 0.5, s * 0.35), g, HORIZONTAL_ALIGNMENT_LEFT, -1, s, c)


func _dashed(a: Vector2, b: Vector2, c: Color, w: float) -> void:
	var L: float = a.distance_to(b)
	var n: int = int(L / 12.0)
	for i in range(n):
		if i % 2 == 0:
			draw_line(a.lerp(b, float(i) / n), a.lerp(b, float(i + 1) / n), c, w)
