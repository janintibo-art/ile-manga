extends RefCounted
## V85 : les boutiques qu'on trouve derrière certaines portes (une par ville, ou presque : un
## marchand derrière son comptoir, ses étagères pleines des produits du coin, et son caractère :
## l'honnête bavard, celui qui marchande contre lui-même, la collectionneuse qui ne veut rien
## vendre), et les histoires des maisons naines creusées dans la Grande Halle de Forgefer (le
## concours de barbe, le tunnel vers la cuisine de la sœur, la berceuse de l'enclume, la soupe
## aux cailloux).
## M : maisons_v81 ; S : maisons_scenes_v81 (les aides communes) ; I : maisons_iles_v82.

const S = preload("res://scripts/maisons_scenes_v81.gd")
const I = preload("res://scripts/maisons_iles_v82.gd")
const Inv = preload("res://scripts/inventory_v28.gd")

const VILLES := ["montjoie", "braise", "boucan", "tazira", "astralys", "azur", "cliquetis", "ramure", "arcanelle",
	"pirate", "carene", "egypte", "maya", "azteque", "elfe", "atlante", "nain"]

## [id, poids, {style: [...]}]
const SCENARIOS := [
	["boutique", 9, {"style": VILLES}],
	["barbe", 14, {"style": ["nain"]}], ["tunnel", 14, {"style": ["nain"]}],
	["berceuse", 12, {"style": ["nain"]}], ["soupe_cailloux", 12, {"style": ["nain"]}],
]

## Pas d'alcool dans les boutiques (on est en famille).
const ALCOOL := ["rhum", "biere", "cidre", "hydromel", "grog", "vin_"]

const ENSEIGNES := ["Au Bon Panier", "Tout à Deux Sous", "L'Échoppe du Coin", "Au Petit Bonheur", "La Caverne aux Merveilles",
	"Chez Nous, c'est Chez Vous", "Le Comptoir Doré", "Aux Mille Trucs", "La Bonne Affaire", "Le Panier Garni"]

const BAVARD := ["Excellent choix ! Ma grand-mère disait toujours… euh… je ne sais plus. Mais c'était à propos de ça, j'en suis sûr.",
	"Celui-là est arrivé ce matin. C'est le plus ancien de la boutique !",
	"Tu veux un sac ? Je n'ai pas de sac. Mais c'est gentil d'y avoir pensé.",
	"Avec ça, tu vas faire des jaloux. Surtout le voisin. Il fait des jaloux de tout, le voisin.",
	"Merci ! Reviens quand tu veux. Même pour rien. Surtout pour rien : je m'ennuie un peu."]

const REFUS := ["Ah non ! Pas celui-là. Il est à vendre, oui, mais… pas aujourd'hui. Ni demain, d'ailleurs.",
	"Celui-là ? Il est bien trop beau pour être vendu. C'est pour ça qu'il est en vitrine.",
	"C'est-à-dire que… si je te le vends, je ne l'aurai plus. Tu vois le problème ?"]


static func has(sc: String) -> bool:
	for e in SCENARIOS:
		if str(e[0]) == sc:
			return true
	return false


static func build(M, sc: String) -> void:
	match sc:
		"boutique":
			_boutique(M)
		"barbe":
			_barbe(M)
		"tunnel":
			_tunnel(M)
		"berceuse":
			_berceuse(M)
		"soupe_cailloux":
			_soupe(M)


static func _r(M) -> RandomNumberGenerator:
	return M.ctx["rng"]


static func _pick(M, a: Array) -> Variant:
	return a[_r(M).randi() % a.size()]


static func _nom_objet(id: String) -> String:
	return str((Inv.ITEMS.get(id, {}) as Dictionary).get("name", id))


static func _inv(M) -> Node:
	return M.main.get("inventory_v28")


# =================================================================== la boutique

## Ce qu'on vend dans cette ville (les produits du coin, sans alcool).
static func goods(style: String) -> Array:
	var ob = load("res://scripts/objets_v66.gd")
	var reg: String = S.region(style)
	var out: Array = []
	var table: Dictionary = ob.COFFRE_BUTIN
	var src: Array = (table.get(reg, table["village"]) as Array)[1]
	for id in S.food(style) + src:
		var bad: bool = not Inv.ITEMS.has(str(id)) or str(id) in out
		for a in ALCOOL:
			if str(id).begins_with(a) or str(id).contains("_" + a):
				bad = true
		if not bad:
			out.append(str(id))
	return out


static func _prix(id: String, r: RandomNumberGenerator) -> int:
	match str((Inv.ITEMS.get(id, {}) as Dictionary).get("kind", "")):
		"nourriture":
			return r.randi_range(5, 9)
		"materiau":
			return r.randi_range(4, 7)
		"tresor":
			return r.randi_range(14, 22)
	return r.randi_range(9, 14)


static func _boutique(M) -> void:
	var R = M.R
	var r := _r(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var style: String = str(M.ctx["style"])
	var hid: String = str(M.ctx["id"])
	var all: Array = goods(style)
	# toujours la même marchandise pour une boutique donnée
	all.sort_custom(func(x, y): return hash(hid + str(x)) < hash(hid + str(y)))
	var stock: Array = []
	for i in range(mini(4, all.size())):
		stock.append([str(all[i]), _prix(str(all[i]), r)])
	var achats: Array = []
	for id2 in ["coquillage", "perle", "rubis", "minerai_fer", "plume_ara", "dent_croco", "boulon", "caillou"]:
		if Inv.ITEMS.has(id2):
			achats.append(id2)
	achats.sort_custom(func(x, y): return hash(hid + str(x)) < hash(hid + str(y)))
	achats = achats.slice(0, 2)
	if not ("caillou" in achats) and r.randf() < 0.3:
		achats[achats.size() - 1] = "caillou"
	var perso: String = str(_pick(M, ["bavard", "bavard", "marchand", "collection"]))
	var enseigne: String = str(ENSEIGNES[absi(hash(hid + "enseigne")) % ENSEIGNES.size()])
	# le comptoir, en travers de la pièce
	var zc: float = -hd * 0.15
	var cw: float = minf(2.8, R.W - 2.4)
	var ch: float = 0.78 if style == "nain" else 1.0     # un comptoir à hauteur de nain
	R.kit.box(R.L(0, ch * 0.5, zc), Vector3(cw, ch, 0.6), "bois_sombre", 1.0)
	R.kit.box(R.L(0, ch + 0.03, zc), Vector3(cw + 0.12, 0.06, 0.72), "bois", 1.0)
	R.kit.col_box(R.L(0, ch * 0.5, zc), Vector3(cw, ch, 0.6))
	R.reserve(0, zc, cw + 0.4, 1.0)
	R.reserve(0, zc - 0.75, cw, 1.0)
	# les étagères du fond, pleines de marchandise
	var n: int = maxi(2, int((R.W - 1.2) / 1.35))
	var models: Array = []
	for i2 in range(n):
		var x: float = -hw + 0.75 + i2 * ((R.W - 1.5) / maxf(1.0, n - 1))
		var h: float = minf(2.1, R.H - 0.5)
		R.etagere(x, -hd + 0.22, 0, 1.2, h, false, 4)
		for row in range(4):
			var y: float = 0.08 + (h - 0.12) * float(row) / 4.0 + 0.016
			var id3: String = str(all[(i2 * 4 + row) % all.size()]) if not all.is_empty() else ""
			for k in range(3):
				models.append([id3, R.P(x - 0.36 + k * 0.36, y, -hd + 0.22), r.randf_range(-40, 40)])
	# sur le comptoir : ce qui est à vendre, avec son prix
	for j in range(stock.size()):
		var px: float = -cw * 0.5 + 0.35 + j * ((cw - 0.7) / maxf(1.0, stock.size() - 1))
		models.append([str(stock[j][0]), R.P(px, ch + 0.06, zc + 0.08), 20.0])
		var tag := Label3D.new()
		tag.text = "%d p." % int(stock[j][1])
		tag.pixel_size = 0.0022
		tag.font_size = 48
		tag.outline_size = 10
		tag.modulate = Color(1.0, 0.92, 0.6)
		tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		M.room.add_child(tag)
		tag.global_position = R.P(px, ch + 0.32, zc + 0.12)
	for e in models:
		if str(e[0]) != "":
			_show_item(M, str(e[0]), e[1], float(e[2]))
	# l'enseigne au-dessus des étagères
	var sign := Label3D.new()
	sign.text = enseigne
	sign.font_size = 64
	sign.pixel_size = 0.004
	sign.outline_size = 12
	sign.modulate = Color(1.0, 0.86, 0.45)
	M.room.add_child(sign)
	sign.global_position = R.P(0, minf(2.45, R.H - 0.3), -hd + 0.06)
	# un peu de bazar : des caisses, un tonneau, une plante, le chat du magasin
	R.caisse(hw - 0.55, hd - 1.2, 0.55)
	R.caisse(hw - 0.55, hd - 1.2, 0.4, 0.55)
	R.tonneau(-hw + 0.55, hd - 1.3)
	R.plante(-hw + 0.5, zc + 0.2)
	if r.randf() < 0.5:
		R.chat(cw * 0.5 - 0.25, zc, 90, Color(0.9, 0.55, 0.2) if r.randf() < 0.5 else Color(0.2, 0.2, 0.22), true, ch + 0.06)
	S._murs(M, 1)
	var f: Node = M.person(str(_pick(M, ["homme", "femme", "vieux", "vieille"])), 0.0, zc - 0.52, 0, "comptoir")
	var nm: String = str(f.npc.display_name).split(" ")[-1]
	f.lines = ["Bienvenue, bienvenue !", "Tout est de première qualité !", "On touche avec les yeux !", "Il y a des promotions… quelque part."]
	if perso == "collection":
		f.lines = ["Regarde, mais ne touche pas.", "Tout est à vendre ! … Enfin, presque.", "Ah, mes merveilles…"]
	var data := {"stock": stock, "achats": achats, "perso": perso, "enseigne": enseigne, "nom": nm}
	M.talk_spot(f, func(): _menu(M, f, data, ""))
	M.ctx["on_enter"] = func(first: bool) -> void:
		M.main.sfx("cloche")
		await M.get_tree().create_timer(0.6).timeout
		if M.inside:
			f.say(str(_pick(M, ["Bonjour, bonjour ! Entre !", "Ding-dong ! Un client !", "Bienvenue chez " + enseigne + " !"])) if first else "Re-bonjour ! Tu as oublié quelque chose ?", 3.5)
	M.ctx["entree"] = ""


## Un objet en vitrine : son modèle 3D s'il en a un, sinon son image (comme dans le sac).
static func _show_item(M, id: String, at: Vector3, yaw: float) -> void:
	var inv: Node = _inv(M)
	if inv != null and inv.has_method("make_model"):
		var mm: Node3D = inv.make_model(id)
		var has_mesh: bool = false
		for c in mm.get_children():
			if c is MeshInstance3D:
				has_mesh = true
		if has_mesh:
			M.room.add_child(mm)
			mm.global_transform = Transform3D(Basis(Vector3.UP, deg_to_rad(yaw)).scaled(Vector3.ONE * 1.5), at)
			return
		mm.free()
	var path: String = "res://assets/textures/items/%s.png" % id
	if not ResourceLoader.exists(path):
		return
	var sp := Sprite3D.new()
	sp.texture = load(path)
	sp.pixel_size = 0.2 / maxf(1.0, float(sp.texture.get_height()))
	sp.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sp.shaded = true
	M.room.add_child(sp)
	sp.global_position = at + Vector3.UP * 0.1
	sp.rotation.y = M.R.xf0.basis.get_euler().y


## Le comptoir : acheter, vendre, partir.
static func _menu(M, f: Node, data: Dictionary, msg: String) -> void:
	var st: Dictionary = M.state()
	var inv: Node = _inv(M)
	var coins: int = int(inv.count("piece")) if inv != null else 0
	var choices: Array = []
	for i in range((data["stock"] as Array).size()):
		var e: Array = data["stock"][i]
		var left: int = int(st.get("stock_" + str(e[0]), 3))
		if left > 0:
			choices.append({"id": "b:%d" % i, "label": "Acheter : %s — %d pièces" % [_nom_objet(str(e[0])), _prix_actuel(st, e)]})
	for id in data["achats"]:
		if inv != null and int(inv.count(str(id))) > 0:
			choices.append({"id": "v:" + str(id), "label": "Vendre : %s (tu en as %d)" % [_nom_objet(str(id)), int(inv.count(str(id)))]})
	choices.append({"id": "fermer", "label": "Au revoir !"})
	var text: String = msg
	if text == "":
		match str(data["perso"]):
			"marchand":
				text = "Bienvenue chez %s ! Ici, les prix sont fixes. Enfin… fixes-ish. Tu as %d pièces." % [data["enseigne"], coins]
			"collection":
				text = "Bienvenue chez %s. Tout ce que tu vois est à vendre. Théoriquement. Tu as %d pièces." % [data["enseigne"], coins]
			_:
				text = "Bienvenue chez %s ! Regarde, tout est frais, tout est beau, tout est d'ici ! Tu as %d pièces." % [data["enseigne"], coins]
	M.talk(f, text, choices, func(id): _choix(M, f, data, str(id)), "de bonne humeur")


static func _prix_actuel(st: Dictionary, e: Array) -> int:
	return int(st.get("prix_" + str(e[0]), int(e[1])))


static func _choix(M, f: Node, data: Dictionary, id: String) -> void:
	var st: Dictionary = M.state()
	var inv: Node = _inv(M)
	if id.begins_with("b:"):
		var e: Array = data["stock"][int(id.substr(2))]
		var item: String = str(e[0])
		var price: int = _prix_actuel(st, e)
		match str(data["perso"]):
			"collection":
				var n: int = int(st.get("refus_" + item, 0))
				if n < 2:
					st["refus_" + item] = n + 1
					f.gesture("colere", 1.5)
					_menu(M, f, data, str(REFUS[(n + item.length()) % REFUS.size()]))
					return
				st["refus_" + item] = 0
				st["stock_" + item] = int(st.get("stock_" + item, 3)) - 1
				f.gesture("rire", 2.0)
				M.give([[item, 1]], "")
				_menu(M, f, data, "Bon. BON ! Prends-le. Gratuitement. Tu m'as eu à l'usure. Mais ne le dis à personne : j'ai une réputation de commerçante, moi. Enfin, de commerçant. Bref.")
				return
			"marchand":
				if not st.has("prix_" + item):
					var p2: int = maxi(2, int(round(price * 0.8)))
					var p3: int = maxi(1, int(round(price * 0.6)))
					st["prix_" + item] = p3
					_menu(M, f, data, "%s ? Ça fait %d pièces. … Non, %d. … Allez, %d, mais c'est bien parce que c'est toi ! … Ne me regarde pas comme ça, sinon je baisse encore." % [_nom_objet(item), price, p2, p3])
					return
		if inv == null or int(inv.count("piece")) < price:
			var manque: int = price - (int(inv.count("piece")) if inv != null else 0)
			_menu(M, f, data, "Il te manque %d pièce%s. Je ne fais pas crédit… sauf aux chats. Tu n'es pas un chat ?" % [manque, "s" if manque > 1 else ""])
			return
		inv.remove("piece", price)
		st["stock_" + item] = int(st.get("stock_" + item, 3)) - 1
		M.main.sfx("obole")
		M.give([[item, 1]], "")
		f.gesture("salut", 1.5)
		var mots: String = str(BAVARD[(int(st.get("ventes", 0)) + item.length()) % BAVARD.size()]) if str(data["perso"]) == "bavard" else "Merci ! Et un client content, un !"
		st["ventes"] = int(st.get("ventes", 0)) + 1
		_menu(M, f, data, mots)
	elif id.begins_with("v:"):
		var it: String = id.substr(2)
		var pv: int = 1 if it == "caillou" else (3 if str((Inv.ITEMS.get(it, {}) as Dictionary).get("kind", "")) == "materiau" else 10)
		if inv == null or int(inv.count(it)) <= 0:
			_menu(M, f, data, "")
			return
		inv.remove(it, 1)
		M.give([["piece", pv]], "")
		var t: String = "Marché conclu ! %d pièces pour toi." % pv
		if it == "caillou":
			t = "Un caillou ? … Une pièce. Et c'est bien payé : je fais ça uniquement parce qu'il est joli. Il est joli, hein ?"
		_menu(M, f, data, t)
	else:
		M.close_talk()


# =================================================================== Forgefer : le concours de barbe

static func _barbe(M) -> void:
	var R = M.R
	var r := _r(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	S._salon(M, 2)
	# le grand miroir de bronze, contre le mur de gauche
	R.kit.box(R.L(-hw + 0.05, 1.3, 0.3, 90), Vector3(1.2, 1.7, 0.04), "cuivre", 1.0)
	R.kit.box(R.L(-hw + 0.03, 1.3, 0.3, 90), Vector3(1.36, 1.86, 0.03), "bois_sombre", 1.0)
	R.kit.box(R.L(-hw + 0.9, 0.38, 1.2), Vector3(0.5, 0.76, 0.4), "bois", 1.0)
	for k in range(4):
		R.kit.box(R.L(-hw + 0.8 + k * 0.08, 0.79, 1.15, 20 * k), Vector3(0.03, 0.02, 0.18), ["or", "argent", "bois_sombre", "cuivre"][k], 1.0)
	var noms: Array = ["Brokk", "Eitri", "Fjalar", "Regin", "Sindri", "Grimbald"]
	noms.shuffle()
	var a: Node = M.person("homme", -hw + 1.2, 0.0, -90, "mains_dos", str(noms[0]))
	var b: Node = M.person(str(_pick(M, ["homme", "vieux"])), -hw + 1.3, 0.8, -100, "bras_croises", str(noms[1]))
	a.lines = ["Admire ce tressage.", "Trois heures de peigne, chaque matin.", "Elle brille, hein ?"]
	b.lines = ["La mienne est plus longue.", "Ça, une barbe ? Un paillasson, oui !", "Hmpf."]
	var na: String = str(noms[0])
	var nb: String = str(noms[1])
	var cb := func() -> void:
		if bool(M.state().get("juge", false)):
			M.talk(a, "Tu as jugé, le grand. Un nain n'oublie jamais un jugement. Ni la personne qui l'a rendu. … Reviens quand même, va.", I._bye("Pierre et feu !"), I._close(M), "bourru mais content")
			return
		M.talk(a, "Toi, le grand ! Tu tombes bien. Demain, c'est le Grand Concours de la Barbe de Forgefer. %s et moi, on n'est pas d'accord. La plus belle barbe, c'est la mienne… ou la sienne ?" % nb,
			[{"id": "a", "label": "La vôtre, %s !" % na}, {"id": "b", "label": "Celle de %s !" % nb}, {"id": "deux", "label": "Les deux sont magnifiques."}], func(id):
			M.state()["juge"] = true
			var gagnant: Node = a if id == "a" else b
			var perdant: Node = b if id == "a" else a
			if id == "deux":
				a.gesture("colere", 1.5)
				b.gesture("colere", 1.5)
				M.talk(a, "« Les deux » ?! … Un diplomate. On a un DIPLOMATE dans la maison. … Bon. Tiens, pour le déplacement. Et va-t'en avant qu'on se dispute à nouveau.", I._bye("Bonne chance à tous les deux !"), func(_i):
					M.give([["piece", 8 + r.randi() % 6]], "")
					M.close_talk())
				return
			gagnant.gesture("joie", 2.5)
			perdant.gesture("colere", 2.0)
			S._say_late(M, perdant, "Hmpf. … Bon. D'accord. Le tressage est réussi. UN PEU.", 2.2, 4.0)
			M.talk(gagnant, "HA ! Tu as l'œil, le grand ! Tiens : le ragoût de ma mère. On ne le donne qu'aux connaisseurs de barbes.", I._bye("Merci !"), func(_i):
				M.give([["ragout_nain", 1], ["piece", 6]], "")
				M.close_talk())
		, "bourru mais content")
	M.talk_spot(a, cb)
	M.ctx["entree"] = str(_pick(M, ["Deux nains se tiennent devant un grand miroir de bronze. Ils se peignent la barbe en se lançant des regards noirs.", "Ça sent l'huile à barbe et la rivalité. Devant le miroir, deux nains comparent leurs tresses.", "« Plus longue ! » « Plus BELLE ! » Deux nains se disputent devant un miroir."]))


# =================================================================== Forgefer : le tunnel

static func _tunnel(M) -> void:
	var R = M.R
	var r := _r(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	R.foyer(R.W * 0.18, -hd + 0.38, 0, true)
	R.table(-0.6, 0.6, 0, 1.25, 0.8)
	R.chaise(-0.6, 1.3, 180)
	R.tapis(-0.4, 0.5, 0, 2.2, 1.6)
	R.armoire(hw - 0.35, hd * 0.2, -90)
	# le trou dans le mur de gauche, les gravats, la pioche, la brouette de cailloux
	var hz: float = -hd * 0.35
	R.kit.box(R.L(-hw + 0.03, 0.85, hz, 90), Vector3(1.1, 1.6, 0.03), "noir", 1.0, 16)
	for k in range(9):
		var gx: float = -hw + 0.3 + r.randf_range(0.0, 0.8)
		var gz: float = hz + r.randf_range(-0.7, 0.7)
		R.kit.cyl(R.L(gx, 0.0, gz, r.randf_range(0, 90)), r.randf_range(0.08, 0.18), r.randf_range(0.1, 0.2), r.randf_range(0.08, 0.16), "pierre", 7)
	# la pioche, appuyée contre le mur
	R.kit.cyl(Transform3D(Basis(Vector3.BACK, -0.28), R.P(-hw + 0.3, 0.5, hz + 0.95)), 0.025, 0.025, 1.0, "bois", 8)
	R.kit.box(Transform3D(Basis(Vector3.BACK, -0.28), R.P(-hw + 0.17, 0.98, hz + 0.95)), Vector3(0.08, 0.06, 0.55), "fer", 1.0)
	R.kit.box(R.L(-hw + 1.4, 0.25, hz - 1.0), Vector3(0.7, 0.4, 0.5), "bois", 1.0)
	for k2 in range(6):
		R.kit.cyl(R.L(-hw + 1.2 + (k2 % 3) * 0.2, 0.45, hz - 1.1 + (k2 / 3) * 0.2), 0.09, 0.1, 0.1, "pierre", 7)
	R.reserve(-hw + 1.0, hz, 1.6, 2.4)
	S._murs(M, 2)
	var d: Node = M.person(str(_pick(M, ["homme", "vieux"])), -hw + 1.7, hz + 0.2, -90, "bricoler")
	d.lines = ["Encore un mètre. Ou douze.", "Ça avance, ça avance !", "Tac. Tac. Tac."]
	var soeur: String = str(_pick(M, ["Gudrun", "Ragna", "Thyra", "Helka", "Dagny"]))
	var cb := func() -> void:
		if bool(M.state().get("perce", false)):
			M.talk(d, "Depuis que le mur est percé, %s vient manger chez moi tous les soirs. Tous. Les. Soirs. … Je rebouche le trou demain." % soeur, I._bye("Bon appétit !"), I._close(M), "bourru mais content")
			return
		M.talk(d, "Je creuse un tunnel jusqu'à la cuisine de ma sœur, %s. Elle habite juste à côté. Ça fait douze ans que je creuse." % soeur,
			[{"id": "porte", "label": "Pourquoi ne pas passer par la porte ?"}, {"id": "pioche", "label": "Je peux donner un coup de pioche ?"}, {"id": "fermer", "label": "Bon courage !"}], func(id):
			if id == "porte":
				d.gesture("colere", 1.5)
				M.talk(d, "Par la PORTE ?! Comme un elfe ?! Un nain ne passe pas par la porte quand il peut passer par la roche. C'est une question d'honneur. Et de dessert : elle fait des tartes.", I._bye("Je comprends."), I._close(M))
			elif id == "pioche":
				M.state()["perce"] = true
				M.main.sfx("touche_pierre")
				M.close_talk()
				_percee(M, d, soeur)
			else:
				M.close_talk()
		, "jovial")
	M.talk_spot(d, cb)
	M.ctx["entree"] = str(_pick(M, ["Tac. Tac. Tac. Un nain creuse dans le mur de son propre salon.", "Il y a un trou dans le mur. Et des cailloux partout. Et un nain très content de lui.", "Une maison naine bien rangée… à part le grand trou dans le mur, et la montagne de gravats devant."]))


static func _percee(M, d: Node, soeur: String) -> void:
	for k in range(3):
		await M.get_tree().create_timer(0.45).timeout
		if not M.inside:
			return
		M.main.sfx("caisse_casse" if k == 2 else "touche_pierre")
	M.say("CRAC ! Le mur s'ouvre. De l'autre côté : une cuisine, une tarte… et une naine, le rouleau à pâtisserie levé.", 5.0)
	await M.get_tree().create_timer(2.2).timeout
	if not M.inside:
		return
	M.say("« %s ?! ENFIN ! Douze ans ! Tu entres, tu t'essuies les pieds, et tu goûtes ma tarte. Ton ami aussi. »" % str(d.npc.display_name).split(" ")[-1], 6.0)
	d.gesture("joie", 3.0)
	await M.get_tree().create_timer(2.5).timeout
	if M.inside:
		M.give([["minerai_fer", 2], ["piece", 10 + randi() % 8]], "Pour le coup de pioche, une part de tarte… et la trouvaille du tunnel. ")


# =================================================================== Forgefer : la berceuse

static func _berceuse(M) -> void:
	var R = M.R
	var r := _r(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	R.foyer(R.W * 0.18, -hd + 0.38, 0, true)
	R.lit(hw - 0.7, -hd * 0.35, -90, 1.2, "rouge")
	R.tapis(-0.3, 0.0, 0, 2.2, 1.6)
	R.armoire(-hw + 0.35, -hd * 0.5, 90)
	S._murs(M, 2)
	# le berceau : une petite enclume de bois sur deux patins, et le bébé sous sa couverture
	var bx: float = -0.5
	var bz: float = -0.2
	# le fond, les quatre côtés (la tête plus haute, comme le bec d'une enclume), les patins
	R.kit.box(R.L(bx, 0.2, bz), Vector3(0.84, 0.04, 0.46), "bois", 1.0)
	for sz in [-1.0, 1.0]:
		R.kit.box(R.L(bx, 0.33, bz + sz * 0.22), Vector3(0.84, 0.26, 0.03), "bois", 1.0)
	R.kit.box(R.L(bx + 0.41, 0.33, bz), Vector3(0.03, 0.26, 0.46), "bois", 1.0)
	R.kit.box(R.L(bx - 0.41, 0.4, bz), Vector3(0.03, 0.4, 0.46), "bois", 1.0)
	R.kit.box(R.L(bx - 0.52, 0.56, bz), Vector3(0.22, 0.06, 0.3), "bois_sombre", 1.0)
	R.kit.box(R.L(bx, 0.1, bz), Vector3(0.36, 0.18, 0.26), "bois_sombre", 1.0)
	for sx in [-1.0, 1.0]:
		R.kit.box(R.L(bx + sx * 0.28, 0.02, bz), Vector3(0.06, 0.04, 0.6), "bois_sombre", 1.0)
	# le bébé : la couverture, la tête, le petit bonnet
	R.kit.box(R.L(bx + 0.06, 0.29, bz), Vector3(0.6, 0.12, 0.38), "tissu_bleu", 1.0)
	R.kit.cyl(R.L(bx - 0.27, 0.26, bz), 0.085, 0.085, 0.13, "gateau", 12)
	R.kit.cyl(R.L(bx - 0.3, 0.36, bz), 0.07, 0.09, 0.08, "tissu_rouge", 10)
	# la petite enclume de vrai fer, à côté (le jouet préféré)
	R.kit.box(R.L(bx + 0.7, 0.1, bz + 0.5), Vector3(0.24, 0.2, 0.14), "fer", 1.0)
	R.kit.box(R.L(bx + 0.7, 0.22, bz + 0.5), Vector3(0.34, 0.05, 0.14), "fer", 1.0)
	R.reserve(bx, bz, 1.4, 1.2)
	var mere: Node = M.person(str(_pick(M, ["femme", "vieille"])), bx + 0.1, bz - 0.85, 0, "tricot")
	mere.npc.global_position.y -= 0.27
	R.tabouret(bx + 0.1, bz - 0.85)
	mere.lines = ["Chuuut…", "Il dort… enfin.", "Pas un bruit, hein ?"]
	var cb := func() -> void:
		var dort: bool = bool(M.state().get("berce", false))
		var txt: String = "(Tout bas) Chuuut ! Le petit vient ENFIN de s'endormir. Trois heures que je chante. Si tu le réveilles, c'est toi qui le berces jusqu'à demain."
		if dort:
			txt = "(Tout bas) Il dort comme une pierre. Une toute petite pierre. Merci encore, le grand."
		M.talk(mere, txt, [{"id": "chanter", "label": "Lui chanter une berceuse naine"}, {"id": "enclume", "label": "Taper sur la petite enclume"}, {"id": "fermer", "label": "(Repartir sur la pointe des pieds)"}], func(id):
			if id == "chanter":
				M.close_talk()
				M.say("« Dors, petit marteau, dors, / la forge veille encore, / la pierre te tient chaud, / dors, petit marteau. »", 7.0)
				await M.get_tree().create_timer(3.5).timeout
				if M.inside:
					M.say("Dans le berceau : « Rrr… pfff… rrr… » Le bébé nain ronfle déjà comme une forge.", 5.0)
					if not bool(M.state().get("berce", false)):
						M.state()["berce"] = true
						await M.get_tree().create_timer(2.0).timeout
						if M.inside:
							M.give([["fromage_chevre", 1], ["piece", 6]], "La maman te glisse un petit cadeau, sans un bruit. ")
			elif id == "enclume":
				M.close_talk()
				M.main.sfx("touche_pierre")
				M.say("TING ! … Dans le berceau : « HIHIHI ! ENCORE ! ENCORE ! TING ! »", 4.5)
				mere.gesture("colere", 2.0)
				S._say_late(M, mere, "… Merci. Vraiment. Bon. Tu chantes, maintenant.", 1.8, 4.0)
			else:
				M.close_talk()
		, "fatigué")
	M.talk_spot(mere, cb)
	M.ctx["entree"] = str(_pick(M, ["Une chambre douce et chaude. Près du feu, un berceau en forme d'enclume. Une naine tricote, très, très doucement.", "Chuuut. Quelqu'un chantonne tout bas : « Dors, petit marteau… »", "Dans un coin, un berceau. Dedans, un tout petit nain qui dort, les poings serrés comme deux petits marteaux."]))


# =================================================================== Forgefer : la soupe aux cailloux

static func _soupe(M) -> void:
	var R = M.R
	var r := _r(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	R.foyer(0.0, -hd + 0.38, 0, true)
	# la grosse marmite devant le feu
	R.kit.cyl(R.L(0.0, 0.0, -hd + 1.25), 0.36, 0.3, 0.55, "fer", 16)
	R.kit.cyl(R.L(0.0, 0.53, -hd + 1.25), 0.33, 0.33, 0.02, "soupe", 16)
	R.kit.box(R.L(0.25, 0.75, -hd + 1.2, 30), Vector3(0.04, 0.6, 0.04), "bois", 1.0)
	R.reserve(0, -hd + 1.25, 1.0, 1.0)
	S._table(M, -0.6, 0.9, 3, "")
	R.etagere_murale(hw - 0.15, 1.5, -0.2, -90, 1.4, "terre_cuite", 6)
	S._murs(M, 2)
	var vieux: Node = M.person(str(_pick(M, ["vieux", "vieille"])), 0.65, -hd + 1.3, -90, "cuisiner")
	vieux.lines = ["Ça mijote…", "Il ne manque presque rien.", "Hmm, ça sent bon, hein ?"]
	var cb := func() -> void:
		var inv: Node = _inv(M)
		if bool(M.state().get("soupe", false)):
			M.talk(vieux, "La soupe aux cailloux, c'est surtout les légumes autour. Le caillou, c'est pour le goût. Et pour la tradition. Reviens demain, j'en refais.", I._bye("Merci !"), I._close(M), "jovial")
			return
		var ch: Array = []
		if inv != null and int(inv.count("caillou")) > 0:
			ch.append({"id": "caillou", "label": "Donner un caillou"})
		if inv != null and int(inv.count("champignon_braise")) > 0:
			ch.append({"id": "braise", "label": "Donner un champignon de braise"})
		ch.append({"id": "rien", "label": "Je n'ai rien de tout ça…"})
		M.talk(vieux, "Je fais ma fameuse soupe aux cailloux. La recette de mon arrière-arrière-grand-mère. Il ne me manque plus… qu'un caillou. Ou quelque chose qui pique.", ch, func(id):
			if id == "caillou" or id == "braise":
				inv.remove("caillou" if id == "caillou" else "champignon_braise", 1)
				M.state()["soupe"] = true
				M.main.sfx("plongeon")
				vieux.gesture("joie", 2.5)
				var t: String = "PLOUF ! Parfait. Le secret, c'est le caillou. Personne ne sait pourquoi. Tiens, goûte !"
				if id == "braise":
					t = "Un champignon de braise ?! Ho ho ! Ça, c'est une soupe de nain ! Ça pique les yeux ET la barbe ! Tiens, goûte, et prends-en pour la route."
				M.talk(vieux, t, I._bye("Miam !"), func(_i):
					M.give([["ragout_nain", 2 if id == "braise" else 1], ["piece", 4]], "")
					M.close_talk())
			else:
				M.talk(vieux, "Pas de caillou ?! Dans une MONTAGNE ?! Va donc en ramasser un dehors, le grand. Il y en a partout. C'est même un peu le principe d'une montagne.", I._bye("J'y vais !"), I._close(M))
		, "jovial")
	M.talk_spot(vieux, cb)
	M.ctx["entree"] = str(_pick(M, ["Une grosse marmite fume devant le feu. Un vieux nain la goûte et fronce les sourcils : « Il manque quelque chose… »", "Ça sent la soupe. Une soupe épaisse, mystérieuse… et curieusement minérale.", "Une cuisine de nain : des marmites de fer, des louches énormes, et un vieux cuisinier qui chantonne."]))
