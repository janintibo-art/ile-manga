## La magie élémentaire (V143) : les familles et leurs faiblesses ; la brûlure, la gangue de glace,
## l'ennemi trempé ; les réactions (Brisé, Vapeur, Éclats, Surcharge, Électrocuté, Gelé à cœur,
## Attisé) ; le sort de Foudre et sa chaîne ; les armes qui portent un élément ; la leçon de
## l'archimage ; la sauvegarde ; les textes en anglais.
const NOM := "elements"


func _vider() -> void:
	for b in faune_v132.betes.duplicate():
		if is_instance_valid(b):
			b.queue_free()
	faune_v132.betes.clear()
	elements_v143.reset()


## Une bête immobile devant le héros (à « avant » mètres, décalée de « cote » mètres).
func _bete(kind: String, avant: float = 2.5, cote: float = 0.0) -> Node3D:
	var f: Vector3 = hero_v28.facing
	var q: Vector3 = _pos() + f * avant + f.cross(Vector3.UP) * cote
	q.y = _height_at(q.x, q.z) + 0.1
	var b: Node3D = faune_v132.spawn(kind, q)
	b.set_physics_process(false)
	return b


## Un coin bien plat autour du héros (les bêtes y sont à sa hauteur) : on s'y pose, tourné vers le nord.
func _plat() -> bool:
	var o: Vector3 = _pos()
	var best: Vector3 = o
	var bd: float = INF
	for r in range(0, 60, 4):
		for k in range(12):
			var a: float = TAU * k / 12.0
			var c := Vector3(o.x + cos(a) * r, 0, o.z + sin(a) * r)
			var h0: float = _height_at(c.x, c.z)
			if h0 < 1.0:
				continue
			var d: float = 0.0
			for dz in [0.0, -3.0, -6.0, -9.0, -12.0]:
				for dx in [-3.0, 0.0, 3.0]:
					d = maxf(d, absf(_height_at(c.x + dx, c.z + dz) - h0))
			if d < bd:
				bd = d
				best = Vector3(c.x, h0, c.z)
		if bd < 0.25:
			break
	_poser(best + Vector3.UP * 0.2, Vector3.FORWARD)
	return bd < 0.5


func _sol() -> void:
	for k in range(40):
		if str(hero_v28.state) == "sol":
			return
		await _att(0.05)


func _pret() -> void:
	sorts_v67.mana = float(sorts_v67.mana_max())
	sorts_v67._cd.clear()
	pouvoirs_v63._cd.clear()
	await _sol()


func _serie() -> void:
	testeur_v78._faune_v132("elfes")
	await _att(0.5)
	faune_v132.enabled = false
	var plat: bool = _plat()
	await _att(0.6)
	await _sol()
	_ok(plat, "un coin plat pour l'essai")
	var el: Node = elements_v143
	_ok(el != null, "le module des éléments existe")
	_vider()
	await _images(2)
	testeur_v78._pick("h_tout")
	await _att(0.3)
	_close_dialogue_v31()
	await _att(0.2)
	inventory_v28.equip_item("")
	await _att(0.3)
	_ok(sorts_v67.ORDRE.size() == 7 and sorts_v67.knows("foudre"), "sept sorts : la Foudre est apprise (testeur)")
	# --- les familles et leurs faiblesses
	var ro: Node3D = _bete("ronceux_sauvage", 3.0, -2.0)
	var sa: Node3D = _bete("salamandre", 3.0, 0.0)
	var cr: Node3D = _bete("crabe_plage", 3.0, 2.0)
	var mo: Node3D = _bete("mouette", 4.5, 0.0)
	await _images(2)
	_ok(el.famille(ro) == "plante" and el.famille(sa) == "feu" and el.famille(cr) == "eau" and el.famille(mo) == "vol",
		"familles : %s, %s, %s, %s" % [el.famille(ro), el.famille(sa), el.famille(cr), el.famille(mo)])
	_ok(el.faiblesse(ro) == "feu" and el.faiblesse(cr) == "foudre" and el.faiblesse(mo) == "foudre" and el.faiblesse(sa) in ["glace", "eau"], "faiblesses : plante/feu, eau/foudre, vol/foudre, feu/glace")
	ro.hp = 40
	sa.hp = 40
	var d1: int = el.hit(ro, "feu", 4, _pos())
	var d2: int = el.hit(sa, "feu", 4, _pos())
	_ok(d1 == 6 and int(ro.hp) == 34 and el.etat(ro) == "brule", "le feu sur une plante : 6 au lieu de 4, elle brûle (%d, %s)" % [d1, el.etat(ro)])
	_ok(d2 == 2 and el.etat(sa) == "", "le feu sur une salamandre : 2 au lieu de 4, elle ne brûle pas (%d, « %s »)" % [d2, el.etat(sa)])
	_ok(int(el.reactions.get("faible", 0)) >= 1 and int(el.reactions.get("resiste", 0)) >= 1, "« Faiblesse ! » et « Résiste… » sont comptés")
	_vider()
	await _images(2)
	# --- la boule de feu : l'ennemi brûle, un point par seconde
	await _pret()
	var b: Node3D = _bete("sanglier", 3.5)
	b.hp = 60
	_ok(sorts_v67.cast("feu"), "la boule de feu part")
	await _att(0.7)
	var hp1: int = int(b.hp)
	_ok(hp1 < 60 and el.etat(b) == "brule", "boule de feu : touché (%d) et en feu (%s)" % [hp1, el.etat(b)])
	await _att(2.3)
	_ok(int(b.hp) <= hp1 - 2, "la brûlure : deux points de plus en deux secondes (%d -> %d)" % [hp1, int(b.hp)])
	await _att(3.0)
	_ok(el.etat(b) == "", "la brûlure s'éteint d'elle-même (« %s »)" % el.etat(b))
	# --- la brûlure achève : butin et expérience
	var p0: int = inventory_v28.count("piece")
	b.hp = 1
	el.enflammer(b)
	await _att(1.5)
	_ok(not is_instance_valid(b) or str(b.state) == "mort", "la brûlure achève l'ennemi")
	_ok(inventory_v28.count("piece") > p0, "… et il laisse son butin (%d -> %d pièces)" % [p0, inventory_v28.count("piece")])
	_vider()
	await _images(2)
	# --- le gel : la gangue de glace ; un coup d'arme la brise (dégâts doublés)
	await _pret()
	b = _bete("sanglier", 2.5)
	b.hp = 60
	_ok(sorts_v67.cast("gel"), "le gel part")
	await _att(0.3)
	_ok(el.etat(b) == "gele" and b.has_node("Glace_v143") and str(b.state) == "recul", "gel : l'ennemi est pris dans la glace (%s, %s)" % [el.etat(b), str(b.state)])
	var hp2: int = int(b.hp)
	combat_v28.strike(_pos(), hero_v28.facing, 3.5, 3)
	await _images(2)
	_ok(int(b.hp) == hp2 - 6 and el.etat(b) == "" and int(el.reactions.get("brise", 0)) == 1, "« Brisé ! » : 6 au lieu de 3, la glace éclate (%d -> %d)" % [hp2, int(b.hp)])
	_ok(not b.has_node("Glace_v143") or b.get_node("Glace_v143").is_queued_for_deletion(), "la gangue de glace a disparu")
	# --- le dégel tout seul
	el.geler(b, 0.6)
	await _att(0.9)
	_ok(el.etat(b) == "", "la glace fond toute seule")
	# --- Vapeur : le feu sur la glace touche les voisins
	var v: Node3D = _bete("sanglier", 2.5, 2.0)
	b.hp = 60
	v.hp = 60
	el.geler(b)
	var dv: int = el.hit(b, "feu", 4, _pos())
	_ok(dv == 6 and el.last_reaction == "vapeur" and el.etat(b) == "" and int(v.hp) == 58, "« Vapeur ! » : 6 sur l'ennemi gelé, 2 sur son voisin (%d, voisin %d)" % [dv, int(v.hp)])
	el.enflammer(b)
	el.hit(b, "glace", 1, _pos())
	_ok(int(el.reactions.get("vapeur", 0)) == 2 and el.etat(b) == "", "la glace sur le feu : vapeur aussi, et le feu s'éteint")
	# --- Éclats, Surcharge
	el.geler(b)
	v.hp = 60
	el.hit(b, "foudre", 4, _pos())
	_ok(el.last_reaction == "eclats" and int(v.hp) == 58, "« Éclats ! » : la foudre sur la glace touche le voisin (%d)" % int(v.hp))
	el.enflammer(b)
	v.hp = 60
	el.hit(b, "foudre", 4, _pos())
	_ok(el.last_reaction == "surcharge" and int(v.hp) == 58 and el.etat(b) == "brule", "« Surcharge ! » : la foudre sur le feu (voisin %d)" % int(v.hp))
	# --- trempé : la foudre double, le gel dure, le feu ne prend pas
	el._efface(b)
	b.hp = 60
	el.tremper(b)
	_ok(el.etat(b) == "trempe", "l'ennemi est trempé")
	var de: int = el.hit(b, "foudre", 4, _pos())
	_ok(de == 8 and el.last_reaction == "electrocute", "« Électrocuté ! » : 8 au lieu de 4 (%d)" % de)
	el.tremper(b)
	var df: int = el.hit(b, "feu", 4, _pos())
	_ok(df == 2 and el.etat(b) == "", "le feu sur un ennemi trempé : 2 au lieu de 4, il sèche sans brûler (%d, « %s »)" % [df, el.etat(b)])
	el.tremper(b)
	el.hit(b, "glace", 1, _pos())
	var tg: float = float(el._st[b.get_instance_id()]["t"]) if el.etat(b) == "gele" else 0.0
	_ok(tg > el.GEL_TEMPS * 1.5, "« Gelé à cœur ! » : la glace dure plus longtemps (%.1f s)" % tg)
	_vider()
	await _images(2)
	# --- la Foudre : l'éclair frappe, puis saute sur deux voisins
	await _pret()
	var f1: Node3D = _bete("sanglier", 5.0)
	var f2: Node3D = _bete("sanglier", 8.0, 1.5)
	var f3: Node3D = _bete("sanglier", 11.0, -1.0)
	for f in [f1, f2, f3]:
		f.hp = 60
	var fx0: int = int(combat_fx_v129.count.get("foudre", 0))
	_ok(sorts_v67.cast("foudre"), "la Foudre part")
	await _images(3)
	_ok(el.last_chain.size() == 3 and int(f1.hp) == 55 and int(f2.hp) == 57 and int(f3.hp) == 58, "l'éclair : 5, puis 3, puis 2 (%d, %d, %d)" % [int(f1.hp), int(f2.hp), int(f3.hp)])
	_ok(int(combat_fx_v129.count.get("foudre", 0)) > fx0, "l'éclair se voit")
	_ok(int(sorts_v67.mana) == sorts_v67.mana_max() - sorts_v67.cost("foudre"), "la Foudre coûte %d de magie" % sorts_v67.cost("foudre"))
	_vider()
	await _images(2)
	await _pret()
	_ok(sorts_v67.cast("foudre"), "sans ennemi, l'éclair frappe le sol")
	_ok(handle_ok_v143(), "la touche à droite du 0 choisit la Foudre")
	await _att(0.5)
	# --- la Bourrasque attise le feu
	await _pret()
	var a1: Node3D = _bete("sanglier", 3.0, -1.0)
	var a2: Node3D = _bete("sanglier", 4.0, 1.5)
	a1.hp = 60
	a2.hp = 60
	el.enflammer(a1)
	await _images(2)
	_ok(pouvoirs_v63.use("vent"), "la Bourrasque part")
	await _images(3)
	_ok(int(el.reactions.get("attise", 0)) == 1 and el.etat(a2) == "brule", "« Attisé ! » : le feu saute sur le voisin (%s)" % el.etat(a2))
	_vider()
	await _images(2)
	# --- les armes : l'épée naine enflamme, le trident trempe, l'épée des nuées fait sauter un arc
	for essai in [["epee_naine", "brule"], ["trident_marees", "trempe"]]:
		if inventory_v28.count(str(essai[0])) == 0:
			inventory_v28.add(str(essai[0]), 1)
		inventory_v28.equip_item(str(essai[0]))
		await _att(0.3)
		var w: Node3D = _bete("sanglier", 1.4)
		w.hp = 60
		combat_v28.strike(_pos(), hero_v28.facing, 2.5, 3)
		_ok(el.etat(w) == str(essai[1]), "%s : l'ennemi est « %s » (%s)" % [str(essai[0]), str(essai[1]), el.etat(w)])
		_vider()
		await _images(2)
	if inventory_v28.count("epee_nuees") == 0:
		inventory_v28.add("epee_nuees", 1)
	inventory_v28.equip_item("epee_nuees")
	await _att(0.3)
	var n1: Node3D = _bete("crabe_plage", 1.3)
	var n2: Node3D = _bete("sanglier", 1.4, 3.2)
	n1.hp = 60
	n2.hp = 60
	combat_v28.strike(_pos(), hero_v28.facing, 2.0, 4)
	_ok(int(n1.hp) == 54 and int(n2.hp) == 59, "épée des nuées : 6 au lieu de 4 sur un crabe (faiblesse), un arc saute sur le voisin (%d, %d)" % [int(n1.hp), int(n2.hp)])
	_vider()
	inventory_v28.equip_item("")
	await _att(0.3)
	# --- la leçon de l'archimage
	var q: Dictionary = journal_v56.quest("arc_foudre")
	_ok(not q.is_empty() and str(q.get("donneur", "")) == "archimage", "la quête « Le septième sort » existe (l'archimage)")
	var cible: bool = false
	for t in sorts_v67.targets:
		if str(t.get("id", "")) == "pierre_lune_foudre":
			cible = true
	_ok(cible, "la plus haute Pierre-Lune attend l'éclair")
	_ok(int(arcanelle_v67.trouvailles().get("lecon_foudre", 0)) == 0, "la leçon de Foudre n'est pas encore faite")
	arcanelle_v67._strike_stone()
	_ok(int(arcanelle_v67.trouvailles().get("lecon_foudre", 0)) == 1, "l'éclair sur la Pierre-Lune : la leçon est faite")
	_ok(sorts_v67.page_text().contains("Foudre") and sorts_v67.page_text().contains("Les éléments"), "le carnet parle de la Foudre et des éléments")
	# --- les conseils (une seule fois), la sauvegarde
	_ok(el.vus.has("vapeur") and el.vus.has("brise") and el.vus.has("faible"), "les conseils ont été donnés (%d)" % el.vus.size())
	var sv: Dictionary = el.serialize()
	el.load_data({})
	_ok(el.vus.is_empty(), "nouvelle partie : aucun conseil vu")
	el.load_data(sv)
	_ok(el.vus.has("vapeur"), "la partie rechargée : les conseils vus sont retenus")
	# --- en anglais
	var L = load("res://scripts/langue_v104.gd")
	L.choisir("en", false)
	var t1: String = L.t("Brisé !")
	var t2: String = L.t("Foudre")
	var t3: String = L.t("Le septième sort")
	L.choisir("fr", false)
	_ok(t1 == "Shattered!", "anglais : « %s »" % t1)
	_ok(t2 == "Lightning", "anglais : « %s »" % t2)
	_ok(t3 == "The seventh spell", "anglais : « %s »" % t3)
	await _att(0.5)
	var debout: bool = await _debout("après la magie")
	_ok(debout, "le héros tient debout")
	_ranger()


## La touche physique à droite du 0 (« ) » en AZERTY, « - » en QWERTY) choisit la Foudre.
func handle_ok_v143() -> bool:
	sorts_v67.select("feu")
	var ev := InputEventKey.new()
	ev.physical_keycode = KEY_MINUS
	ev.keycode = KEY_PARENRIGHT
	sorts_v67.handle_key(_digit_key_v80(ev))
	return str(sorts_v67.choisi) == "foudre"
