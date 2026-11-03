extends RefCounted
## V102 : des conversations plus variées et un panneau plus léger.
##
## Avant, chaque habitant proposait toujours la même longue liste de questions, toujours avec les
## mêmes mots. Maintenant :
##   - le panneau ne montre que l'essentiel (quêtes, boutique, sujets du moment) et trois ou quatre
##     sujets de conversation tirés au hasard (pas ceux dont on vient de parler) ;
##   - « D'autres sujets… » montre le reste ;
##   - chaque question se pose avec des mots qui changent d'une fois à l'autre ;
##   - quatre sujets nouveaux, valables pour tous les habitants de l'archipel : ce qu'il est en train
##     de faire, le moment de la journée, ce qui lui ferait plaisir (une piste pour les cadeaux), un
##     conseil de voyageur.
## La liste complète des sujets (brain.topics) ne change pas : seul l'affichage est allégé.

const PLUS := "plus102"
const NOUVEAUX := ["activite", "moment", "gout", "conseil"]
## les sujets de bavardage : on en tire quelques-uns ; tout le reste (quêtes, boutique, sujets
## spéciaux d'une île) est toujours montré
const BAVARDAGE := ["humeur", "lui", "ile", "rumeur", "blague", "peche", "souvenir", "gens", "cadeau",
	"activite", "moment", "gout", "conseil"]
## les sujets qui font avancer une relation (une histoire pas finie, un rêve pas encore confié)
const PROGRES := ["histoire", "reve"]
const MAX_BAVARDAGE := 4

var main: Node
var rng := RandomNumberGenerator.new()
var _reste: Dictionary = {}            # habitant (id d'instance) -> sujets non montrés
var _recents: Dictionary = {}          # habitant -> derniers sujets choisis


func _init(main_node: Node) -> void:
	main = main_node
	rng.randomize()


# =================================================================== le menu

## La liste allégée à montrer (les libellés changent d'une fois à l'autre).
func compacter(npc: Node, choices: Array) -> Array:
	var bye: Dictionary = {}
	for c in choices:
		if str(c.get("id", "")) == "au_revoir":
			bye = c
	if bye.is_empty():
		return choices
	var brain = npc.get("brain")
	var full: Array = []
	for c in choices:
		if str(c.get("id", "")) != "au_revoir":
			full.append(c)
	for id in NOUVEAUX:
		if _offert(npc, id):
			full.append({"id": id, "label": ""})
	var toujours: Array = []
	var bavard: Array = []
	var progres: Array = []
	for c in full:
		var id: String = str(c.get("id", ""))
		if id in BAVARDAGE:
			bavard.append(c)
		elif id in PROGRES:
			progres.append(c)
		else:
			toujours.append(c)
	var recents: Array = _recents.get(npc.get_instance_id(), [])
	# une histoire en cours passe devant ; le reste est tiré au hasard, les sujets récents en dernier
	var frais: Array = bavard.filter(func(c): return not recents.has(str(c["id"])))
	var vus: Array = bavard.filter(func(c): return recents.has(str(c["id"])))
	_melanger(frais)
	_melanger(vus)
	var n: int = maxi(2, MAX_BAVARDAGE - progres.size() - maxi(0, toujours.size() - 3))
	var tri: Array = frais + vus
	var montres: Array = tri.slice(0, n)
	var caches: Array = tri.slice(n)
	var out: Array = toujours + progres + montres
	for i in range(out.size()):
		out[i] = {"id": str(out[i]["id"]), "label": libelle(brain, str(out[i]["id"]), str(out[i].get("label", "")))}
	_reste[npc.get_instance_id()] = caches
	if not caches.is_empty():
		out.append({"id": PLUS, "label": _un(["D'autres sujets…", "Parlons d'autre chose…", "J'ai d'autres questions…"])})
	out.append({"id": "au_revoir", "label": libelle(brain, "au_revoir", str(bye.get("label", "Au revoir.")))})
	return out


## « D'autres sujets… » : la suite de la liste.
func plus(npc: Node) -> Dictionary:
	var brain = npc.get("brain")
	var caches: Array = _reste.get(npc.get_instance_id(), [])
	var list: Array = []
	for c in caches:
		list.append({"id": str(c["id"]), "label": libelle(brain, str(c["id"]), str(c.get("label", "")))})
	list.append({"id": "au_revoir", "label": libelle(brain, "au_revoir", "Au revoir.")})
	var t: String = _un(["Je t'écoute.", "Oui ?", "Vas-y, demande.", "De quoi veux-tu parler ?", "Dis-moi tout."])
	if brain != null and bool(brain.get("vous")):
		t = _un(["Je vous écoute.", "Oui ?", "Allez-y, demandez.", "De quoi voulez-vous parler ?"])
	return {"texte": t, "geste": "parle", "choix": list, "_complet": true}


## Le sujet choisi est retenu : il ne revient pas tout de suite dans les sujets tirés au hasard.
func retenir(npc: Node, id: String) -> void:
	var k: int = npc.get_instance_id()
	var r: Array = _recents.get(k, [])
	r.erase(id)
	r.append(id)
	while r.size() > 5:
		r.pop_front()
	_recents[k] = r


func _offert(npc: Node, id: String) -> bool:
	var brain = npc.get("brain")
	if brain == null:
		return false
	match id:
		"gout":
			return not (brain.data.get("aime", {}) as Dictionary).is_empty()
		"activite":
			return npc.get("pose") != null
	return true


func _melanger(a: Array) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp = a[i]
		a[i] = a[j]
		a[j] = tmp


func _un(list: Array) -> String:
	return str(list[rng.randi() % list.size()])


func _heure() -> float:
	var t: Node = main.get("temps_v56")
	return float(t.hour) if t != null else 12.0


# =================================================================== les mots des questions

## Les mots du joueur, qui changent d'une fois à l'autre.
func libelle(brain, id: String, d: String) -> String:
	var h: float = _heure()
	var nuit: bool = h >= 21.0 or h < 6.0
	var fam: String = brain.humeur_famille() if brain != null else "neutre"
	var deja: bool = false
	if brain != null:
		deja = int((brain.memoire["sujets"] as Dictionary).get(id, 0)) > 0
	match id:
		"humeur":
			if fam in ["triste", "colere"]:
				return _un(["Quelque chose ne va pas ?", "Tu as l'air soucieux…", "Ça n'a pas l'air d'aller ?", "Qu'est-ce qui t'arrive ?"])
			return _un(["Comment ça va ?", "Ça va, aujourd'hui ?", "Tu vas bien ?", "Comment tu te sens ?", "Bien dormi ?" if h < 11.0 and h >= 5.0 else "La journée se passe bien ?"])
		"lui":
			if not deja:
				return _un(["Qui es-tu ?", "On ne se connaît pas, je crois. Tu es qui ?", "Comment tu t'appelles ?", "Présente-toi !"])
			return _un(["Raconte-moi encore ta vie.", "Parle-moi un peu de toi.", "Tu fais quoi dans la vie, déjà ?", "Rappelle-moi qui tu es ?"])
		"ile":
			return _un(["Parle-moi de cette île.", "C'est comment, la vie ici ?", "Qu'est-ce qu'il y a à voir par ici ?", "Tu aimes vivre ici ?", "Qu'est-ce qui rend cet endroit spécial ?"])
		"rumeur":
			return _un(["Tu as entendu des rumeurs ?", "Quoi de neuf, ces temps-ci ?", "Il se passe des choses, par ici ?", "On raconte quoi, en ce moment ?", "Des nouvelles ?"])
		"blague":
			return _un(["Raconte-moi une blague.", "Fais-moi rire !", "Tu connais une bonne blague ?", "Une petite histoire drôle ?"])
		"peche":
			if not deja:
				return _un(["Tu sais pêcher ?", "Ça mord, par ici ?", "Tu pêches, toi ?"])
			return _un(["Parlons pêche.", "Alors, la pêche ?", "Ça mord, en ce moment ?", "Encore un mot sur la pêche ?"])
		"souvenir":
			return _un(["Tu te souviens de moi ?", "On s'est déjà vus, non ?", "Tu me reconnais ?", "Qu'est-ce que tu retiens de moi ?"])
		"cadeau":
			return _un(["Je voudrais t'offrir quelque chose.", "J'ai quelque chose pour toi.", "Un petit cadeau, ça te dit ?"])
		"gens":
			return _un(["Parle-moi des gens que tu connais.", "Tu connais du monde, ici ?", "Qui sont tes amis ?", "Et tes voisins, ils sont comment ?"])
		"histoire":
			if d.begins_with("Et ensuite"):
				return _un(["Et ensuite ? Raconte-moi la suite.", "Tu me racontes la suite ?", "Et après, que s'est-il passé ?", "La suite de ton histoire ?"])
			return _un(["Raconte-moi ton histoire.", "Tu as une histoire à me raconter ?", "Comment ta vie a commencé, ici ?"])
		"reve":
			return _un(["Et toi, de quoi tu rêves ?", "Tu as un rêve ?", "Qu'est-ce que tu aimerais faire, un jour ?"])
		"activite":
			return _un(["Qu'est-ce que tu fais ?", "Je te dérange ?", "Tu fais quoi, là ?", "Tu es bien installé, ici ?"])
		"moment":
			if nuit:
				return _un(["Il est tard, non ?", "Tu ne dors pas ?", "Belle nuit, tu ne trouves pas ?"])
			if h < 11.0:
				return _un(["Belle matinée, non ?", "Tu es matinal, toi.", "Le matin, c'est ton moment ?"])
			if h >= 18.0:
				return _un(["Belle soirée, non ?", "Tu aimes le soir, toi ?", "La journée se termine…"])
			return _un(["Belle journée, non ?", "Il fait bon, aujourd'hui.", "Tu profites de la journée ?"])
		"gout":
			return _un(["Qu'est-ce qui te ferait plaisir ?", "Qu'est-ce que tu aimes, toi ?", "Tu as un péché mignon ?", "Qu'est-ce qui te rend heureux ?"])
		"conseil":
			return _un(["Tu as un conseil pour moi ?", "Un conseil pour un voyageur ?", "Qu'est-ce que je devrais savoir ?", "Une astuce, peut-être ?"])
		"au_revoir":
			if nuit:
				return _un(["Au revoir.", "Bonne nuit !", "À demain !", "Je te laisse dormir."])
			return _un(["Au revoir.", "À bientôt !", "Je dois y aller.", "Bonne journée !" if h < 17.0 else "Bonne soirée !", "À plus tard !"])
	return d


# =================================================================== les réponses

func gere(id: String) -> bool:
	return id in NOUVEAUX


## La réponse d'un habitant à l'un des quatre sujets nouveaux.
func repondre(npc: Node, id: String, ctx: Dictionary) -> Dictionary:
	var brain = npc.get("brain")
	retenir(npc, id)
	var sujets: Dictionary = brain.memoire["sujets"]
	sujets[id] = int(sujets.get(id, 0)) + 1
	if int(sujets[id]) <= 4:
		brain._bond(0.4)
	var t: String = ""
	match id:
		"activite":
			t = _activite(npc, brain)
		"moment":
			t = _moment(brain)
		"gout":
			t = _gout(brain, ctx)
		"conseil":
			t = _conseil(brain)
	if brain.has_method("_fr"):
		t = brain._fr(t)
	return {"texte": t, "geste": "parle", "choix": brain.topics(ctx)}


func _tv(brain, tu: String, vs: String) -> String:
	return vs if brain != null and bool(brain.get("vous")) else tu


func _activite(npc: Node, brain) -> String:
	var pose: String = str(npc.get("pose")) if npc.get("pose") != null else "debout"
	var spot: String = str(npc.get("target_spot")) if npc.get("target_spot") != null else ""
	var h: float = _heure()
	if spot.begins_with("course:"):
		return _un(["Je cours ! Trois tours tous les jours. Enfin, deux et demi.", "Je garde la forme. Tu veux faire un tour avec moi ?", "Je m'entraîne. Le souffle, c'est comme l'amitié : ça s'entretient."])
	var p: String = pose.to_lower()
	if p.contains("pech"):
		return _un(["Je pêche. Enfin, j'attends. La pêche, c'est surtout de l'attente.", "Chut… ça mord peut-être. Non. Bon. Je pêche.", "J'attends le gros poisson. Ça fait trois ans."])
	if p.contains("forg") or p.contains("bricol"):
		return _un(["Je répare, je façonne. Un objet bien fait, ça dure toute une vie.", "Je travaille. Attention aux étincelles.", "Je bricole. Il y a toujours quelque chose à réparer."])
	if p.contains("cuisin"):
		return _un(["Je cuisine. Ça sent bon, hein ?", "Je prépare le repas. Si tu restes, il y en aura pour toi.", "Une pincée de ceci, une pincée de cela… je cuisine."])
	if p.contains("jardin"):
		return _un(["Je jardine. Les plantes, c'est patient. Moi aussi, j'essaie.", "J'arrose, je taille, je parle aux fleurs.", "Je m'occupe du jardin. Il me le rend bien."])
	if p.contains("dans") or p.contains("pogo"):
		return _un(["Je danse ! Tu viens ?", "Je danse, ça se voit, non ?", "La musique me prend les pieds. Je n'y peux rien."])
	for m in ["guitare", "violon", "flute", "tambour", "taiko", "chanter", "batterie", "basse"]:
		if p.contains(m):
			return _un(["Je joue un peu de musique. Ça fait du bien à tout le monde.", "Je répète. Tu aimes ce morceau ?", "Un air pour la journée. Tu veux une chanson ?"])
	match p:
		"assis":
			return _un(["Je me repose un peu. Les jambes, ça s'use.", "Je regarde passer les gens. C'est le meilleur spectacle de l'île, et c'est gratuit.", "Je profite du banc. Il est à tout le monde, mais là, il est à moi.", "Rien. Absolument rien. C'est très reposant."])
		"lire":
			return _un(["Je lis. Enfin, je lisais.", "Un bon livre. J'en suis au meilleur passage, alors fais vite.", "Je lis un peu. Les livres, ça fait voyager sans bouger."])
		"peindre":
			return _un(["Je peins. Ne regarde pas, ce n'est pas fini.", "Je peins ce que je vois. Enfin, ce que j'aimerais voir.", "Un coup de pinceau à la fois."])
		"comptoir", "boire":
			return _un(["Je prends un jus de fruits, tranquillement.", "Je bavarde, je bois un jus. La belle vie.", "Une limonade bien fraîche. Tu en veux une ?"])
		"allonge":
			return _un(["Je me repose au soleil. Ne me fais pas d'ombre.", "Je bronze. Enfin, j'essaie.", "Je fais la sieste. Enfin, je la faisais."])
		"petanque":
			return _un(["Je joue aux boules. Tu sais pointer, toi ?", "Une partie de pétanque. Je gagne. Presque.", "Je vise le cochonnet. Il ne bouge pas, mais il est rusé."])
		"jouer":
			return _un(["Je joue ! Tu veux jouer avec moi ?", "On joue à chat. C'est toi le chat !", "Je joue, c'est le plus important de la journée !"])
		"bras_croises":
			return _un(["Je surveille. Il faut bien que quelqu'un le fasse.", "J'attends. Je suis très doué pour attendre.", "Je réfléchis. Ça se voit, non ?"])
	if h < 9.0 and h >= 5.0:
		return _un(["Je prends l'air avant de commencer ma journée.", "Je me réveille doucement. Le matin, je suis lent.", "Je regarde le jour se lever. Ça ne se lasse pas."])
	if h >= 20.0 or h < 5.0:
		return _un(["Je profite de la fraîcheur du soir.", "Je regarde les étoiles. Tu connais leurs noms ?", "Je n'ai pas encore sommeil. Alors je traîne un peu."])
	return _un(["Je fais une pause. Une petite.", "Je me dégourdis les jambes.", "Je regarde ce qui se passe. Il se passe toujours quelque chose.", "J'attends quelqu'un. Ou rien. Je ne sais plus.", _tv(brain, "Je réfléchis. Tu m'as interrompu, mais ce n'est pas grave.", "Je réfléchis. Vous m'avez interrompu, mais ce n'est pas grave.")])


func _moment(brain) -> String:
	var h: float = _heure()
	var fam: String = brain.humeur_famille()
	var l: Array = []
	if h >= 5.0 and h < 8.0:
		l = ["Le matin, l'air sent bon. C'est le meilleur moment pour réfléchir.", "J'aime l'aube : tout le monde dort encore, sauf les oiseaux.", "Le soleil se lève. Une journée toute neuve, pas encore abîmée."]
	elif h < 12.0:
		l = ["Belle matinée, oui. Il faut en profiter avant la chaleur.", "Le matin, j'ai toujours plein d'idées. L'après-midi, je les oublie.", "C'est l'heure où tout le monde s'active. J'aime bien ce bruit-là."]
	elif h < 14.0:
		l = ["C'est l'heure de manger. Mon ventre me le rappelle.", "Midi ! Le soleil est tout en haut. L'ombre est toute petite.", "À cette heure-ci, je pense surtout au repas."]
	elif h < 18.0:
		l = ["L'après-midi est long et doux. Parfait pour une sieste.", "Il fait bon. Les heures passent tranquillement.", "L'après-midi, l'île devient paresseuse. Moi aussi."]
	elif h < 21.0:
		l = ["Le soir tombe. C'est l'heure où les gens se retrouvent.", "J'aime quand le ciel devient orange. On dirait qu'il rougit.", "La journée se termine. On se raconte ce qu'on a fait."]
	else:
		l = ["La nuit, l'île est plus calme. On entend la mer.", "Regarde toutes ces étoiles. On ne s'en lasse pas.", "Il est tard, oui. Mais la nuit a ses secrets."]
	var t: String = _un(l)
	if fam == "joie" and rng.randf() < 0.5:
		t += " " + _un(["Et puis aujourd'hui, je suis de bonne humeur.", "Tout me semble beau, aujourd'hui."])
	elif fam in ["triste", "colere"] and rng.randf() < 0.6:
		t += " " + _un(["Même si, aujourd'hui, le cœur n'y est pas.", "Enfin… ce n'est pas mon meilleur jour."])
	return t


func _gout(brain, ctx: Dictionary) -> String:
	var aime: Dictionary = brain.data.get("aime", {})
	var noms: Dictionary = ctx.get("noms", {})
	var ok: Array = []
	for k in aime:
		if float(aime[k]) > 0.0 and noms.has(str(k)):
			ok.append(str(k))
	if ok.is_empty():
		return _un(["Ce qui me ferait plaisir ? Une visite, comme celle-ci. C'est déjà beaucoup.", "Oh, pas grand-chose. Un sourire, une bonne nouvelle.", "Je ne suis pas difficile. Une conversation, ça me suffit."])
	ok.sort_custom(func(a, b): return float(aime[a]) > float(aime[b]))
	var pick: String = ok[0] if rng.randf() < 0.6 or ok.size() == 1 else ok[rng.randi_range(1, ok.size() - 1)]
	var nom: String = brain._item_name(pick, ctx)
	return _un([
		"Ce qui me ferait plaisir ? %s. Je ne dis jamais non à ça." % (nom.substr(0, 1).to_upper() + nom.substr(1)),
		"Si tu veux me faire plaisir, pense à %s. Mais je ne t'ai rien dit." % nom,
		"Mon péché mignon ? %s. Rien qu'en y pensant, je souris." % (nom.substr(0, 1).to_upper() + nom.substr(1)),
		"J'adore %s. Tout le monde le sait, ici." % nom,
	])


const CONSEILS := [
	"Reviens voir les gens souvent : à force de bavarder, on finit par te raconter des choses qu'on ne dit à personne.",
	"Un cadeau qu'on aime, ça ouvre les cœurs. Un cadeau qu'on n'aime pas… ça les referme un peu.",
	"Les gens d'ici ont leurs habitudes : le matin au travail, le soir ailleurs. Si tu ne trouves pas quelqu'un, reviens à une autre heure.",
	"La nuit, beaucoup rentrent chez eux. Si tu veux parler à quelqu'un, viens de jour.",
	"Ne frappe jamais personne. Ici, tout le monde a de la mémoire.",
	"Ton carnet garde tout ce qu'on te demande. Relis-le quand tu ne sais plus où aller.",
	"Si ton sac est plein, va vendre ce que tu as en trop chez un marchand.",
	"Regarde partout, même en l'air et sous les pierres. Les îles adorent cacher des choses.",
	"Quand tu ne sais plus quoi faire, demande aux gens les rumeurs. Il y a toujours une piste.",
	"Prends le temps de te reposer. Un voyageur fatigué rate les plus belles choses.",
	"Les gens qui se connaissent parlent les uns des autres. Écoute bien : c'est souvent là qu'on apprend le plus.",
	"Écoute la musique des lieux : la mer, le vent, les oiseaux. Ils te disent où tu es.",
	"Ne te presse pas. Une île, ça se découvre doucement.",
	"Si quelqu'un a l'air triste, va lui parler. Ça fait toujours du bien. À lui comme à toi.",
]


func _conseil(brain) -> String:
	var t: String = _un(CONSEILS)
	if bool(brain.get("vous")):
		t = _vous(t)
	var intro: String = _un(["Un conseil ? ", "Écoute bien : ", "Hm. ", "", "Je vais te dire une chose : "])
	if bool(brain.get("vous")):
		intro = intro.replace("Écoute bien", "Écoutez bien").replace("te dire", "vous dire")
	return intro + t


## Passe un conseil au vouvoiement (les tournures utilisées dans CONSEILS).
func _vous(t: String) -> String:
	var pairs := [["Reviens", "Revenez"], ["Regarde", "Regardez"], ["Ne frappe", "Ne frappez"], ["Relis-le", "Relisez-le"], ["Prends", "Prenez"],
		["Écoute", "Écoutez"], ["Ne te presse", "Ne vous pressez"], ["va lui parler", "allez lui parler"], ["va vendre", "allez vendre"],
		["reviens", "revenez"], ["viens de jour", "venez de jour"], ["demande", "demandez"], ["si tu veux", "si vous voulez"], ["Si tu veux", "Si vous voulez"],
		["Si tu ne trouves", "Si vous ne trouvez"], ["quand tu ne sais", "quand vous ne savez"], ["Quand tu ne sais", "Quand vous ne savez"],
		["ton sac", "votre sac"], ["Ton carnet", "Votre carnet"], ["tu as", "vous avez"], ["te raconter", "vous raconter"], ["te demande", "vous demande"],
		["te disent", "vous disent"], ["tu es", "vous êtes"], ["à toi", "à vous"], ["on te ", "on vous "], ["de te reposer", "de vous reposer"]]
	for p in pairs:
		t = t.replace(p[0], p[1])
	return t
