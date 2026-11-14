## La roue des sorts et les gestes (V145) : les icônes ; au PC, B tapé (sort suivant), B maintenu (la
## roue, le temps ralenti, la souris désigne, on relâche) ; en VR (gestes simulés) : la gâchette tapée
## lance, maintenue ouvre la roue autour de la main, on pousse la main vers un sort ; le geste de
## lancer (le sort part dans sa direction), la main levée (Lévitation), la main sur le cœur (Soin) ;
## la main gauche ne frappe pas pendant la magie ; l'anglais.
const NOM := "roue"


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


func _remplir() -> void:
	sorts_v67.mana = float(sorts_v67.mana_max())
	sorts_v67._cd.clear()
	pouvoirs_v63._cd.clear()


## Une gâchette gauche simulée : n images (72 par seconde), la main suivant la fonction pos(k).
func _vr(n: int, trig: bool, pos: Callable) -> void:
	for k in range(n):
		roue_v145.geste_tick(1.0 / 72.0, trig, pos.call(k), TETE, Vector3.FORWARD)


const TETE := Vector3(0, 1.6, 0)


func _serie() -> void:
	var R: Node = roue_v145
	_ok(R != null, "le module de la roue existe")
	R.test_mode = true
	testeur_v78._pick("h_tout")
	await _att(0.3)
	_close_dialogue_v31()
	await _att(0.3)
	await _sol()
	var O: Array = sorts_v67.ORDRE
	# --- les icônes
	var vues: Dictionary = {}
	var toutes: bool = true
	for id in O:
		var img: Image = R.icone(str(id)).get_image()
		var somme: float = 0.0
		for y in range(0, 64, 2):
			for x in range(0, 64, 2):
				somme += img.get_pixel(x, y).a
		var cle: String = "%.0f" % somme
		toutes = toutes and img.get_width() == 64 and somme > 60.0 and somme < 900.0 and not vues.has(cle)
		vues[cle] = true
	_ok(toutes, "sept icônes, toutes dessinées et différentes %s" % str(vues.keys()))
	# --- PC : B tapé = le sort suivant
	sorts_v67.select("lumiere")
	R.pc_appui_b()
	R.pc_tick(0.1, true)
	R.pc_tick(0.02, false)
	_ok(str(sorts_v67.choisi) == "feu" and not R.ouverte, "B tapé : le sort suivant (%s)" % str(sorts_v67.choisi))
	# --- PC : B maintenu = la roue, le temps ralentit
	R.pc_appui_b()
	R.pc_tick(0.15, true)
	_ok(not R.ouverte, "B tenu un instant : pas encore de roue")
	R.pc_tick(0.15, true)
	_ok(R.ouverte and absf(Engine.time_scale - R.RALENTI) < 0.01, "B maintenu : la roue s'ouvre, le temps ralentit (%.2f)" % Engine.time_scale)
	_ok(R._hud != null and R._hud.visible, "la roue se voit à l'écran")
	R.pc_souris(R.dir_pc(2) * 20.0)
	_ok(R.survol == -1, "la souris à peine bougée : rien de désigné")
	R.pc_souris(R.dir_pc(2) * 60.0)
	_ok(R.survol == 2, "la souris vers le Gel : il est désigné (%d)" % R.survol)
	R.pc_souris(-R._souris + R.dir_pc(6) * 90.0)
	_ok(R.survol == 6, "puis vers la Foudre (%d)" % R.survol)
	R.pc_souris(-R._souris + R.dir_pc(2) * 90.0)
	R.pc_tick(0.02, false)
	_ok(not R.ouverte and str(sorts_v67.choisi) == "gel", "B relâché : le Gel est choisi (%s)" % str(sorts_v67.choisi))
	_ok(is_equal_approx(Engine.time_scale, 1.0), "le temps reprend son cours")
	# un sort pas encore appris ne se prend pas
	sorts_v67.known.erase("foudre")
	R.pc_appui_b()
	R.pc_tick(0.3, true)
	R.pc_souris(R.dir_pc(6) * 90.0)
	R.pc_tick(0.02, false)
	_ok(str(sorts_v67.choisi) == "gel", "un sort pas encore appris ne se prend pas")
	sorts_v67.known["foudre"] = true
	# Échap referme sans rien changer
	R.pc_appui_b()
	R.pc_tick(0.3, true)
	R.pc_souris(R.dir_pc(0) * 90.0)
	var ev := InputEventKey.new()
	ev.keycode = KEY_ESCAPE
	ev.pressed = true
	R._input(ev)
	R.pc_tick(0.02, false)
	_ok(not R.ouverte and str(sorts_v67.choisi) == "gel" and is_equal_approx(Engine.time_scale, 1.0), "Échap : la roue se referme, rien ne change")
	# --- VR : la gâchette tapée lance le sort choisi
	await _sol()
	_remplir()
	sorts_v67.select("lumiere")
	var n0: int = int(sorts_v67.casts.get("lumiere", 0))
	var p0 := Vector3(0.2, 1.15, -0.35)
	_vr(6, true, func(_k): return p0)
	_ok(R.main_gauche_occupee(), "gâchette tenue : la main gauche fait de la magie (pas de coup de poing)")
	_vr(2, false, func(_k): return p0)
	_ok(int(sorts_v67.casts.get("lumiere", 0)) == n0 + 1 and not R.ouverte, "gâchette tapée : le sort part")
	_ok(not R.main_gauche_occupee(), "gâchette relâchée : la main gauche frappe de nouveau")
	# --- VR : maintenue, la roue autour de la main ; on pousse la main vers un sort
	var nl: int = int(sorts_v67.casts.get("levitation", 0))
	_vr(24, true, func(_k): return p0)
	_ok(R.ouverte and R._roue3d != null and R._roue3d.visible, "gâchette maintenue : la roue s'ouvre autour de la main")
	var d3: Vector2 = R.dir_vr(3)
	var vers: Vector3 = R._plan * Vector3(d3.x, d3.y, 0.0)
	_vr(20, true, func(k): return p0 + vers * (0.08 * float(k + 1) / 20.0))
	_ok(R.survol == 3, "la main poussée vers la Lévitation : elle est désignée (%d)" % R.survol)
	_vr(2, false, func(_k): return p0 + vers * 0.08)
	_ok(str(sorts_v67.choisi) == "levitation" and not R.ouverte, "gâchette relâchée : la Lévitation est choisie (%s)" % str(sorts_v67.choisi))
	_ok(int(sorts_v67.casts.get("levitation", 0)) == nl, "… sans la lancer")
	# --- VR : le geste de lancer : le sort part dans la direction du geste
	await _sol()
	_remplir()
	sorts_v67.select("feu")
	var nf: int = int(sorts_v67.casts.get("feu", 0))
	var b0: int = pouvoirs_v63._balls.size()
	var dl := Vector3(0.6, 0.0, -1.0).normalized()
	var p1 := Vector3(0.15, 1.25, -0.2)
	var g0: Dictionary = R.gestes.duplicate()
	_vr(3, true, func(_k): return p1)
	_vr(8, true, func(k): return p1 + dl * 0.05 * float(k + 1))
	_ok(int(R.gestes.get("lancer", 0)) == int(g0.get("lancer", 0)) + 1 and int(sorts_v67.casts.get("feu", 0)) == nf + 1, "le geste de lancer : la boule de feu part")
	var attendu: Vector3 = (xr_origin.global_basis * dl).normalized()
	var dir_boule: Vector3 = pouvoirs_v63._balls[pouvoirs_v63._balls.size() - 1]["dir"] if pouvoirs_v63._balls.size() > b0 else Vector3.ZERO
	_ok(dir_boule.dot(attendu) > 0.95, "… dans la direction du geste (%.2f)" % dir_boule.dot(attendu))
	var o_boule: Vector3 = pouvoirs_v63._balls[pouvoirs_v63._balls.size() - 1]["node"].global_position if pouvoirs_v63._balls.size() > b0 else Vector3.INF
	_ok(o_boule.distance_to(xr_origin.to_global(p1 + dl * 0.4)) < 1.6, "… et depuis la main")
	_ok(not R.ouverte, "le geste n'ouvre pas la roue")
	_vr(2, false, func(_k): return p1)
	_ok(int(sorts_v67.casts.get("feu", 0)) == nf + 1, "relâcher après le geste ne lance rien de plus")
	# un mouvement lent, ce n'est pas un lancer
	await _att(1.0)
	_remplir()
	_vr(3, true, func(_k): return p1)
	_vr(10, true, func(k): return p1 + dl * 0.012 * float(k + 1))
	_vr(2, false, func(_k): return p1)
	_ok(int(R.gestes.get("lancer", 0)) == int(g0.get("lancer", 0)) + 1, "un mouvement lent n'est pas un lancer")
	# --- VR : la main levée vite : la Lévitation
	await _sol()
	_remplir()
	sorts_v67.select("gel")
	var p2 := Vector3(0.2, 1.3, -0.3)
	_vr(3, true, func(_k): return p2)
	_vr(10, true, func(k): return p2 + Vector3.UP * 0.045 * float(k + 1))
	_vr(2, false, func(_k): return p2 + Vector3.UP * 0.45)
	_ok(int(R.gestes.get("lever", 0)) == int(g0.get("lever", 0)) + 1 and sorts_v67.levitating(), "la main levée vite : la Lévitation")
	await _att(4.5)
	# --- VR : la main sur le cœur : le Soin
	await _sol()
	_remplir()
	var ns: int = int(sorts_v67.casts.get("soin", 0))
	var coeur := TETE + Vector3.DOWN * 0.38 + Vector3.FORWARD * 0.12
	_vr(20, true, func(_k): return coeur)
	_ok(int(sorts_v67.casts.get("soin", 0)) == ns, "la main sur le cœur : pas encore")
	_vr(30, true, func(_k): return coeur)
	_ok(int(R.gestes.get("coeur", 0)) == int(g0.get("coeur", 0)) + 1 and int(sorts_v67.casts.get("soin", 0)) == ns + 1, "la main sur le cœur un instant : le Soin")
	_ok(not R.ouverte, "… et la roue ne s'ouvre pas")
	_vr(2, false, func(_k): return coeur)
	_ok(int(sorts_v67.casts.get("soin", 0)) == ns + 1, "relâcher ne relance pas le Soin")
	R.test_mode = false
	R.reset()
	# --- l'écran du carnet, l'anglais
	_ok(sorts_v67.page_text().contains("la roue des sorts"), "le carnet explique la roue et les gestes")
	var L = load("res://scripts/langue_v104.gd")
	L.choisir("en", false)
	var t1: String = L.t("Roue des sorts")
	var t2: String = L.t("Foudre : ce sort ne s'apprend qu'à Arcanelle.")
	L.choisir("fr", false)
	_ok(t1 == "Spell wheel", "anglais : « %s »" % t1)
	_ok(t2 == "Lightning: this spell can only be learned at Arcanelle.", "anglais : « %s »" % t2)
	var debout: bool = await _debout("après la roue")
	_ok(debout, "le héros tient debout")
	_ranger()
