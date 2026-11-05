extends "res://scripts/pnj/pnj_brain_v31.gd"
## V68 : le cerveau d'un pirate de Port-Coutelas (et des gens du port). Le même que celui de
## tous les habitants (pnj_brain_v31.gd), avec en plus une TENSION (de 0, tranquille, à 1, la
## bagarre) :
##  - un mot de travers la fait monter : une provocation (« Joli rafiot. Il flotte encore ? »),
##    son point sensible (la jambe de bois de Lestrange, la balafre de la capitaine…), une
##    question de trop quand il est de mauvaise humeur, et surtout quand le joueur a trop bu :
##    les mots sortent de travers (« Comment ça va ? » devient « Ça va, face de morue ? ») ;
##  - elle redescend avec des excuses (pas toujours), une tournée, et le temps qui passe ;
##  - à mi-chemin, il menace ; à 1, c'est la bagarre (pirates_v68 / bagarre_v68) ;
##  - les joueurs jouent aux dés (trois dés, le plus gros total, un brelan bat tout ; les dés
##    pipés du receleur aident, mais gare si l'on se fait prendre) ;
##  - les costauds acceptent un duel à la loyale ; après une bagarre, il s'en souvient.
## V109 : tout ce que le pirate dit (et les choix proposés) est traduit dans la langue du joueur
## (_t / _tf / _m du cerveau commun).
## V111 : en Public averti, le ton est plus cru : des provocations plus salées, des mots de
## travers plus vexants, et une fois sur deux, des menaces et des cris de bagarre bien sentis.

const Public = preload("res://scripts/public_v111.gd")

static var mgr: Node                     # pirates_v68.gd (l'ivresse du joueur, les quêtes, les sons)

const PROVOCS := {
	"navire": "Joli rafiot. Il flotte encore ?",
	"odeur": "Tu sens le poisson pourri, matelot.",
	"capitaine": "Paraît que ton capitaine a peur de l'eau.",
	"nage": "Je parie que tu ne sais même pas nager.",
	"vue": "Pousse-toi, tu me bouches la vue.",
	"dents": "Il t'en reste combien, des dents ?",
	"perroquet": "Ton perroquet est plus malin que toi.",
	"grog": "Ton grog a un goût de vieille chaussette.",
	"cartes": "Tes cartes, c'est des gribouillis d'enfant.",
}
const SLIPS := {
	"humeur": ["« Comment ça va ? »", "« Ça va, face de morue ? »"],
	"lui": ["« Qui es-tu ? »", "« T'es qui, toi, le moche ? »"],
	"ile": ["« Parle-moi de cette île. »", "« Elle est pourrie, ton île, hein ? »"],
	"rumeur": ["« Tu as entendu des rumeurs ? »", "« Paraît que tu ronfles comme un phoque. »"],
	"histoire": ["« Raconte-moi ton histoire. »", "« Raconte ta vie, ça va m'endormir. »"],
	"gens": ["« Tu connais du monde, ici ? »", "« Tes copains, ils sont aussi laids que toi ? »"],
	"blague": ["« Raconte-moi une blague. »", "« La meilleure blague, c'est ta tête. »"],
	"reve": ["« Tu rêves de quoi ? »", "« Tu rêves de prendre un bain, j'espère ? »"],
}
## V111 : Public averti seulement
const PROVOCS_AVERTI := {
	"bulot": "T'as une cervelle de bulot. Et encore, le bulot se vexerait.",
	"rat": "Retourne dans ta cale, rat mouillé. Ça sent le fromage moisi, par ici.",
	"rhum": "T'as pas les épaules pour un rhum de la Balafre, gamin. Bois ton lait.",
	"ancre": "Ta grand-mère nageait mieux que toi. Avec une ancre au pied.",
	"gelee": "Tu trembles comme une gelée de méduse, moussaillon.",
}
const SLIPS_AVERTI := {
	"humeur": "« Ça va, vieux sac à rhum mal rincé ? »",
	"lui": "« T'es qui, toi, tête de bulot pas frais ? »",
	"ile": "« Elle pue la vase, ton île. Et toi aussi. »",
	"rumeur": "« Paraît que ton équipage t'a vendu pour trois sardines. »",
	"histoire": "« Ta vie, c'est une épave. Ça se voit d'ici. »",
	"gens": "« T'as des amis, toi, avec une tronche pareille ? »",
	"blague": "« Une blague ? T'en es une, de blague, espèce de moule. »",
	"reve": "« Tu rêves d'un bain ? Parce que tu sens la cale à plein nez. »",
}
const MENACES_AVERTI := [
	"Répète ça, et je te fais manger ta casquette, sac à puces !",
	"Encore un mot, tête de thon, et tu rentres chez toi à la nage.",
	"Tu cherches les ennuis, crevette ? T'es au bon comptoir.",
	"Je vais te ranger dans un tonneau de harengs, et m'asseoir sur le couvercle.",
	"Approche encore, et je te repeins le nez en violet.",
]
const BAGARRE_AVERTI := [
	"Viens là, que je t'arrange le portrait, face de mérou !",
	"Ça va cogner ! Prévenez le Doc, il va avoir du boulot !",
	"Je vais te démonter comme une vieille barque pourrie !",
	"À la baille, le terrien ! Mais d'abord, une beigne !",
]
const SEUIL_MENACE: float = 0.5
const BAGARRE: float = 1.0

var _provoc_du_jour: String = ""


func reset() -> void:
	super.reset()
	memoire["tension"] = 0.0
	memoire["bagarres"] = {"gagnees": 0, "perdues": 0, "fuites": 0}
	memoire["des"] = {"parties": 0, "gains": 0, "serie": 0}


func pir() -> Dictionary:
	return data.get("pirate", {})


func tension() -> float:
	return float(memoire.get("tension", 0.0))


func set_tension(v: float) -> void:
	memoire["tension"] = clampf(v, 0.0, 1.2)


func can_fight() -> bool:
	return not bool(pir().get("pacifique", false))


## La tension retombe toute seule (lentement ; moins vite pour un rancunier).
func tick(delta: float) -> void:
	super.tick(delta)
	var t: float = tension()
	if t > 0.0:
		var rancune: float = float((data.get("traits", {}) as Dictionary).get("rancunier", 0.5))
		set_tension(t - delta * 0.005 * (1.0 - 0.6 * rancune))


func humeur_mot() -> String:
	var t: float = tension()
	if t >= 0.85:
		return "prêt à cogner"  # (traduit à l'affichage, comme les autres humeurs)
	if t >= SEUIL_MENACE:
		return "menaçant"
	if t >= 0.25:
		return "agacé"
	return super.humeur_mot()


func _ivresse() -> float:
	if mgr == null or mgr.main == null:
		return 0.0
	var o: Node = mgr.main.get("objets_v66")
	return float(o.get("ivresse")) if o != null else 0.0


## Le tatouage de Coralie : les pirates cherchent un peu moins de noises à ceux qui portent sa marque.
## Et le Roi de la Bagarre, on y regarde à deux fois avant de lui chercher querelle.
func _respect() -> float:
	var k: float = 1.0
	if mgr != null and mgr.get("state") is Dictionary and bool((mgr.state as Dictionary).get("tatouage", false)):
		k *= 0.75
	if mgr != null and mgr.main != null and mgr.main.get("journal_v56") != null and (mgr.main.journal_v56.titres as Array).has("Roi de la Bagarre"):
		k *= 0.8
	return k


func _susceptible() -> float:
	return float((data.get("traits", {}) as Dictionary).get("susceptible", 0.5))


# =================================================================== conversation

func start(ctx: Dictionary) -> Dictionary:
	var pool: Array = (pir().get("provocs", ["odeur", "vue", "nage"]) as Array).duplicate()
	if Public.averti():
		pool.append_array(PROVOCS_AVERTI.keys())
	_provoc_du_jour = str(pool[rng.randi() % pool.size()]) if not pool.is_empty() else ""
	var r: Dictionary = super.start(ctx)
	# encore fâché : il le fait savoir tout de suite
	if tension() >= SEUIL_MENACE and _pending_question.is_empty():
		var m: Dictionary = say("menace", ctx, false)
		r["texte"] = str(m["texte"]) if str(m["texte"]) != "…" else str(r["texte"])
		r["geste"] = "colere"
	return r


func topics(ctx: Dictionary) -> Array:
	var t: Array = super.topics(ctx)
	var extra: Array = []
	var p: Dictionary = pir()
	if tension() >= 0.3:
		extra.append({"id": "calme", "label": _t("Du calme, je plaisantais.")})
	if bool(p.get("joueur", false)) and tension() < SEUIL_MENACE:
		extra.append({"id": "des", "label": _t("⚄ Une partie de dés ?")})
	if int((ctx.get("objets", {}) as Dictionary).get("piece", 0)) >= 3 and not bool(p.get("tavernier", false)):
		extra.append({"id": "tournee", "label": _t("Je t'offre un verre ? (3 pièces)")})
	for sp in _quest_topics(ctx):
		extra.append(sp)
	if bool(p.get("costaud", false)) and can_fight():
		extra.append({"id": "duel", "label": _t("⚔ Je te défie, à la loyale !")})
	if _provoc_du_jour != "" and PROVOCS_AVERTI.has(_provoc_du_jour) and Public.averti():
		extra.append({"id": "pv:" + _provoc_du_jour, "label": _t(str(PROVOCS_AVERTI[_provoc_du_jour]))})
	elif _provoc_du_jour != "" and PROVOCS.has(_provoc_du_jour):
		var label: String = _t(str(PROVOCS[_provoc_du_jour]))
		if _provoc_du_jour == "capitaine" and str(p.get("role", "")) == "capitaine":
			label = _t("Paraît que tu as peur de l'eau, capitaine.")
		extra.append({"id": "pv:" + _provoc_du_jour, "label": label})
	if p.has("point_sensible"):
		extra.append({"id": "pv:sensible", "label": _t(str((p["point_sensible"] as Dictionary).get("label", "…")))})
	# avant « Au revoir »
	var out: Array = []
	for c in t:
		if str(c.get("id", "")) == "au_revoir":
			out.append_array(extra)
			extra = []
		out.append(c)
	out.append_array(extra)
	# un pirate ne raconte pas de blagues aux inconnus : on retire « blague » s'il est fâché
	if tension() >= SEUIL_MENACE:
		out = out.filter(func(c): return str(c.get("id", "")) != "blague")
	return out


## Les sujets des quêtes de l'île (la dette de Jambe-de-Bois), selon l'état du carnet.
func _quest_topics(ctx: Dictionary) -> Array:
	var out: Array = []
	var id: String = str(data.get("id", ""))
	var q: Dictionary = ctx.get("q56", {})
	if id == "lestrange" and str(q.get("bal_dette", "")) == "en_cours" and _dette_step() >= 1 and not _has_fact("bourse_donnee"):
		if _has_fact("dette_perdue"):
			out.append({"id": "dette_bourse", "label": _t("★ Alors, cette bourse pour Mama Grog ?")})
		else:
			out.append({"id": "dette_payer", "label": _t("★ Je règle ta dette moi-même. (40 pièces)")})
			if can_fight():
				out.append({"id": "dette_duel", "label": _t("★ Alors on règle ça à la loyale !")})
	return out


func _dette_step() -> int:
	if mgr == null or mgr.main == null or mgr.main.get("journal_v56") == null:
		return 0
	return int(mgr.main.journal_v56.step_of("bal_dette"))


func choose(choice: String, ctx: Dictionary) -> Dictionary:
	var now: float = float(ctx.get("now", 0.0))
	if choice.begins_with("pv:"):
		return _provoc(choice.substr(3), ctx)
	if choice.begins_with("des_triche:"):
		return _dice(int(choice.substr(11)), true, ctx)
	if choice.begins_with("des:"):
		return _dice(int(choice.substr(4)), false, ctx)
	match choice:
		"calme":
			return _calm(ctx)
		"tournee":
			return _round(ctx)
		"des":
			return _dice_menu(ctx, "")
		"duel":
			if tension() >= BAGARRE * 0.9:
				return _fight_reply("bagarre", ctx, false, "provoc")
			var r: Dictionary = say("duel", ctx, false)
			if str(r["texte"]) == "…":
				r["texte"] = _t("À la loyale ? Toi et moi, personne ne s'en mêle ? … Ha ! D'accord. Lève les poings !")
			return _with_fight(r, true, "duel")
		"dette_payer":
			if int((ctx.get("objets", {}) as Dictionary).get("piece", 0)) < 40:
				return {"texte": _t("Tu ne les as même pas, les quarante pièces ! Ha ! Reviens quand tu seras riche."), "geste": "rire", "choix": topics(ctx)}
			memoire["faits"]["bourse_donnee"] = true
			_bond(4.0)
			_remember("a payé ma dette à Mama Grog", now)
			return {"texte": _t("Tu paies MA dette ? … T'es un drôle de numéro, toi. Tiens, prends ma bourse, donne-la à la grosse, et qu'elle me fiche la paix. (Il fourre tes pièces dans sa bourse et te la tend.)"), "geste": "rire",
				"prendre": [["piece", 40]], "donner": [["bourse_lestrange", 1]], "choix": topics(ctx)}
		"dette_duel":
			return _with_fight({"texte": _t("À la loyale ? Avec ma jambe de bois ? … Tu vas voir ce qu'elle cogne, ma jambe de bois ! Si tu gagnes, la bourse est à toi. Si je gagne, tu me paies une tournée. Allez !"), "geste": "colere"}, true, "dette")
		"dette_bourse":
			memoire["faits"]["bourse_donnee"] = true
			return {"texte": _t("(Jambe-de-Bois se frotte la mâchoire.) Tu cognes dur, pour un terrien. Tiens, la bourse. Quarante pièces. Dis à Mama que c'est la dernière fois. … Et que son grog est quand même le meilleur."), "geste": "parle",
				"donner": [["bourse_lestrange", 1]], "choix": topics(ctx)}
	# un mot de travers : quand on a trop bu, les mots sortent tout seuls
	if SLIPS.has(choice) and can_fight():
		var iv: float = _ivresse()
		var chance: float = clampf((iv - 0.6) * 0.75, 0.0, 0.6)
		if iv >= 0.75 and rng.randf() < chance:
			var s: Array = (SLIPS[choice] as Array).duplicate()
			if Public.averti() and SLIPS_AVERTI.has(choice) and rng.randf() < 0.5:
				s[1] = SLIPS_AVERTI[choice]
			var add: float = 0.42 * (0.6 + _susceptible()) * _respect()
			set_tension(tension() + add)
			_mood(-0.15)
			var head: String = _tf("(Tu voulais dire %s… mais le grog a parlé à ta place : %s)", [_t(str(s[0])), _t(str(s[1]))]) + "\n\n"
			return _stage_reply(head, ctx, "travers")
		# sobre, mais de mauvaise humeur : une question de trop
		if _susceptible() >= 0.7 and humeur < -0.1 and choice in ["lui", "humeur", "histoire", "gens"] and rng.randf() < 0.3:
			set_tension(tension() + 0.2)
			var r2: Dictionary = say("agace", ctx, false)
			r2["choix"] = topics(ctx)
			r2["geste"] = "colere"
			return r2
	if choice == "au_revoir" and tension() >= SEUIL_MENACE:
		var bye: Dictionary = say("menace_depart", ctx, false)
		if str(bye["texte"]) == "…":
			bye["texte"] = _t("C'est ça, file. Et ne reviens pas me chercher.")
		bye["fin"] = true
		bye["choix"] = []
		memoire["derniere"] = now
		return bye
	return super.choose(choice, ctx)


## Une provocation : la tension monte (selon le caractère, l'humeur et l'amitié).
func _provoc(k: String, ctx: Dictionary) -> Dictionary:
	var base: float = 0.38
	if k == "sensible":
		base = 0.62
	elif k == "capitaine" and str(pir().get("role", "")) == "capitaine":
		base = 0.5
	var add: float = base * (0.6 + _susceptible()) * (1.0 - clampf(affinite / 160.0, 0.0, 0.4))
	if humeur < -0.2:
		add *= 1.25
	add *= _respect()
	set_tension(tension() + add)
	_mood(-0.12)
	_bond(-1.5)
	_remember("m'a cherché des noises", float(ctx.get("now", 0.0)))
	var head: String = ""
	if k == "sensible":
		var ps: Dictionary = pir().get("point_sensible", {})
		if tension() < BAGARRE and ps.has("t"):
			var r: Dictionary = {"texte": _fill(str(ps["t"]), ctx), "geste": "colere", "choix": topics(ctx)}
			return r
	return _stage_reply(head, ctx, k)


## Selon la tension : il est agacé, il menace, ou c'est la bagarre.
func _stage_reply(head: String, ctx: Dictionary, motif: String) -> Dictionary:
	var t: float = tension()
	if t >= BAGARRE and can_fight():
		var rb: Dictionary = _fight_reply("bagarre", ctx, false, motif)
		rb["texte"] = _m(head + str(rb["texte"]))
		return rb
	var intent: String = "menace" if t >= SEUIL_MENACE else "agace"
	if not can_fight():
		intent = "pacifique_fache" if t >= SEUIL_MENACE else "agace"
	var r: Dictionary = say(intent, ctx, false)
	if str(r["texte"]) == "…":
		r["texte"] = _t("Répète un peu, pour voir ?") if intent == "menace" else _t("Hé. Fais attention à ce que tu dis.")
	if intent == "menace" and Public.averti() and rng.randf() < 0.5:
		r["texte"] = _t(str(MENACES_AVERTI[rng.randi() % MENACES_AVERTI.size()]))
	r["texte"] = _m(head + str(r["texte"]))
	r["geste"] = "colere"
	r["choix"] = topics(ctx)
	return r


func _fight_reply(intent: String, ctx: Dictionary, loyal: bool, motif: String) -> Dictionary:
	var r: Dictionary = say(intent, ctx, false)
	if str(r["texte"]) == "…":
		r["texte"] = _t("Ça, tu vas le regretter !")
	if intent == "bagarre" and Public.averti() and rng.randf() < 0.5:
		r["texte"] = _t(str(BAGARRE_AVERTI[rng.randi() % BAGARRE_AVERTI.size()]))
	return _with_fight(r, loyal, motif)


func _with_fight(r: Dictionary, loyal: bool, motif: String) -> Dictionary:
	r["geste"] = "colere"
	r["fin"] = true
	r["choix"] = []
	r["_bagarre68"] = {"id": str(data.get("id", "")), "loyal": loyal, "motif": motif}
	return r


func _calm(ctx: Dictionary) -> Dictionary:
	var iv: float = _ivresse()
	# ivre, même les excuses sortent de travers
	if iv >= 0.9 and rng.randf() < 0.35:
		set_tension(tension() + 0.3)
		return _stage_reply(_t("(Tu voulais t'excuser… mais ça sort comme ça : « Du calme, la sardine ! »)") + "\n\n", ctx, "travers")
	var ok: bool = rng.randf() > _susceptible() * 0.45 * (1.0 if tension() > 0.7 else 0.5)
	if ok:
		set_tension(tension() - 0.42)
		_mood(0.06)
		var r: Dictionary = say("excuse_ok", ctx, false)
		if str(r["texte"]) == "…":
			r["texte"] = _t("Hm. Bon. Ça va pour cette fois.")
		r["choix"] = topics(ctx)
		return r
	set_tension(tension() + 0.08)
	var r2: Dictionary = say("excuse_ko", ctx, false)
	if str(r2["texte"]) == "…":
		r2["texte"] = _t("Tu plaisantais ? Moi je ne plaisante jamais.")
	r2["geste"] = "colere"
	r2["choix"] = topics(ctx)
	return r2


## Une tournée : on trinque (le joueur boit un grog avec lui).
func _round(ctx: Dictionary) -> Dictionary:
	if int((ctx.get("objets", {}) as Dictionary).get("piece", 0)) < 3:
		return {"texte": _t("Tu m'offres un verre avec quoi ? Tes poches sonnent creux."), "geste": "rire", "choix": topics(ctx)}
	set_tension(tension() - 0.6)
	_mood(0.25)
	_bond(4.0)
	_remember("m'a payé un verre", float(ctx.get("now", 0.0)))
	var r: Dictionary = say("tournee", ctx, false)
	if str(r["texte"]) == "…":
		r["texte"] = _t("Un verre ? Ha ! Voilà qui cause bien. À la tienne, matelot !")
	r["geste"] = "rire"
	r["prendre"] = [["piece", 3]]
	r["fin"] = true
	r["choix"] = []
	r["_trinque68"] = "grog_bordee"
	return r


# =================================================================== les dés

func _dice_menu(ctx: Dictionary, lead: String) -> Dictionary:
	if tension() >= SEUIL_MENACE:
		return {"texte": _t("Jouer avec toi ? Pas aujourd'hui."), "geste": "colere", "choix": topics(ctx)}
	var have: int = int((ctx.get("objets", {}) as Dictionary).get("piece", 0))
	var maxi: int = int(pir().get("mise_max", 10))
	var ch: Array = []
	for m in [2, 5, 10, 20, 50]:
		if m <= maxi and m <= have:
			ch.append({"id": "des:%d" % m, "label": _tf("Miser %d pièces", m)})
	if int((ctx.get("objets", {}) as Dictionary).get("des_pipes", 0)) > 0:
		for m2 in [5, 10, 20]:
			if m2 <= maxi and m2 <= have:
				ch.append({"id": "des_triche:%d" % m2, "label": _tf("Miser %d pièces… avec tes dés pipés", m2)})
				break
	ch.append({"id": "retour", "label": _t("Finalement, non.")})
	var txt: String = lead
	if txt == "":
		var r: Dictionary = say("des", ctx, false)
		txt = str(r["texte"]) if str(r["texte"]) != "…" else _t("Trois dés chacun. Le plus gros total gagne, et un brelan bat tout. Combien tu mises ?")
	if ch.size() == 1:
		txt += "\n\n" + _t("(Tu n'as pas assez de pièces pour miser.)")
	return {"texte": _m(txt), "geste": "parle", "choix": ch}


static func _roll3(rng2: RandomNumberGenerator, loaded: bool) -> Array:
	var d: Array = []
	for i in range(3):
		var v: int = rng2.randi_range(1, 6)
		if loaded:
			v = maxi(v, rng2.randi_range(3, 6))
		d.append(v)
	return d


## La force d'un lancer : un brelan vaut plus que tout le reste.
static func dice_score(d: Array) -> int:
	var s: int = int(d[0]) + int(d[1]) + int(d[2])
	if int(d[0]) == int(d[1]) and int(d[1]) == int(d[2]):
		return 100 + int(d[0])
	return s


static func dice_text(d: Array) -> String:
	var s: String = "%d · %d · %d" % [int(d[0]), int(d[1]), int(d[2])]
	if dice_score(d) >= 100:
		return s + " — " + _t("brelan !")
	return s + " (%d)" % (int(d[0]) + int(d[1]) + int(d[2]))


func _dice(stake: int, cheat: bool, ctx: Dictionary) -> Dictionary:
	var have: int = int((ctx.get("objets", {}) as Dictionary).get("piece", 0))
	if stake <= 0 or stake > have:
		return _dice_menu(ctx, _t("Tu n'as pas de quoi miser ça."))
	var nom: String = str(data.get("nom", "?")).split(" ")[0]
	var mine: Array = _roll3(rng, cheat)
	var his: Array = _roll3(rng, false)
	var dm: Dictionary = memoire["des"]
	dm["parties"] = int(dm.get("parties", 0)) + 1
	var txt: String = _t("(Les dés roulent sur la table…)") + "\n\n" + _tf("Tes dés : %s", dice_text(mine)) + "\n" + _tf("Ceux de %s : %s", [nom, dice_text(his)]) + "\n\n"
	# pris la main dans le sac ?
	# (le croupier les repère au bruit, une fois sur deux ; s'il ne se bat pas, ses amis s'en chargent)
	if cheat and rng.randf() < (0.55 if bool(pir().get("croupier", false)) else 0.3):
		set_tension(BAGARRE + 0.1)
		_bond(-12.0)
		memoire["faits"]["tricheur"] = true
		var rc: Dictionary = say("tricheur", ctx, false)
		if str(rc["texte"]) == "…":
			rc["texte"] = _t("… Attends. (Il ramasse un de tes dés, le soupèse.) Il est lourd, ton dé. Il est PIPÉ ! TRICHEUR !")
		rc["texte"] = _m(txt + str(rc["texte"]))
		rc["_sfx68"] = "des_roule"
		return _with_fight(rc, false, "tricherie")
	var a: int = dice_score(mine)
	var b: int = dice_score(his)
	var r: Dictionary = {"geste": "parle", "_sfx68": "des_roule"}
	if a == b:
		txt += _t("Égalité ! On remet ça ?")
		r["texte"] = _m(txt)
	elif a > b:
		dm["gains"] = int(dm.get("gains", 0)) + stake
		dm["serie"] = int(dm.get("serie", 0)) + 1
		r["donner"] = [["piece", stake]]
		r["_des68"] = "gagne"
		# un mauvais perdant : la tension monte à chaque partie perdue
		set_tension(tension() + 0.1 * (0.4 + _susceptible()) * (1.4 if int(dm["serie"]) >= 2 else 1.0))
		var w: Dictionary = say("des_perd", ctx, false)
		txt += _tf("Tu gagnes %d pièces !", stake) + " " + (str(w["texte"]) if str(w["texte"]) != "…" else _t("Grrr. La chance du débutant."))
		if tension() >= BAGARRE and can_fight():
			var rb: Dictionary = _fight_reply("tricheur", ctx, false, "des")
			rb["texte"] = _m(txt + "\n\n" + str(rb["texte"]))
			rb["donner"] = [["piece", stake]]
			rb["_sfx68"] = "des_roule"
			rb["_des68"] = "gagne"
			return rb
		if tension() >= SEUIL_MENACE:
			txt += "\n\n" + _t("(Il te regarde de travers. Ses doigts tapotent la table.)")
		# la grande table de la Dent du Requin : trois victoires d'affilée…
		if bool(pir().get("croupier", false)) and int(dm["serie"]) >= 3 and str((ctx.get("q56", {}) as Dictionary).get("bal_carte", "")) == "en_cours" and not _has_fact("carte_donnee"):
			memoire["faits"]["carte_donnee"] = true
			txt += "\n\n" + _t("(Sylvain repousse sa chaise.) Trois fois d'affilée. Personne ne fait ça à ma table. … Bon. Une promesse est une promesse : ce bout de parchemin était ma mise de réserve. Il paraît qu'il vient de la carte de Barbe-Sanglante. Il est à toi.")
			r["donner"] = [["piece", stake], ["carte_morceau", 1]]
			dm["serie"] = 0
		r["texte"] = _m(txt)
	else:
		dm["gains"] = int(dm.get("gains", 0)) - stake
		dm["serie"] = 0
		r["prendre"] = [["piece", stake]]
		r["_des68"] = "perd"
		set_tension(tension() - 0.1)
		_mood(0.1)
		_bond(1.0)
		var l: Dictionary = say("des_gagne", ctx, false)
		txt += _tf("Tu perds %d pièces.", stake) + " " + (str(l["texte"]) if str(l["texte"]) != "…" else _t("Ha ! Merci pour les pièces !"))
		r["texte"] = _m(txt)
	var again: Array = []
	if have - (stake if a < b else 0) + (stake if a > b else 0) >= stake:
		again.append({"id": ("des_triche:%d" if cheat else "des:%d") % stake, "label": _tf("On remet ça ! (%d pièces)", stake)})
	again.append({"id": "des", "label": _t("Changer de mise.")})
	again.append({"id": "retour", "label": _t("J'arrête là.")})
	r["choix"] = again
	return r


# =================================================================== après une bagarre

## La bagarre est finie : il s'en souvient (perdue, gagnée, le joueur a fui).
func after_fight(result: String, now: float) -> void:
	var b: Dictionary = memoire.get("bagarres", {"gagnees": 0, "perdues": 0, "fuites": 0})
	match result:
		"perdue":
			b["perdues"] = int(b.get("perdues", 0)) + 1
			memoire["faits"]["bagarre_perdue"] = true
			set_tension(0.15)
			_bond(6.0)
			humeur = minf(humeur, -0.2)
			_remember("m'a mis au tapis", now)
		"gagnee":
			b["gagnees"] = int(b.get("gagnees", 0)) + 1
			memoire["faits"]["bagarre_gagnee"] = true
			set_tension(0.0)
			_mood(0.4)
			_remember("je l'ai mis au tapis", now)
		"fuite":
			b["fuites"] = int(b.get("fuites", 0)) + 1
			memoire["faits"]["a_fui"] = true
			set_tension(0.45)
			_bond(-4.0)
			_remember("s'est enfui devant moi", now)
	memoire["bagarres"] = b


func hit(ctx: Dictionary) -> String:
	var line: String = super.hit(ctx)
	set_tension(BAGARRE + 0.1)
	return line
