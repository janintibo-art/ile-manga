## V186 : les enfants. Les tenues près du corps sont pour les adultes : aucun enfant n'en porte, et un enfant
## a un corps d'enfant. Le générateur des corps (pcvr/tools/habitants_v64/appearance.py : tenue_enfant, et la
## fin de decide) écrit dans chaque corps (pnj64/<id>.bin) sa tenue et s'il est un enfant : on relit tous les
## corps du jeu.
##   - il y a des enfants (plus de 130) ;
##   - chaque enfant a un haut couvrant (tee-shirt, chemise, tunique, pull, djellaba) : ni torse nu, ni haut
##     sans manches, ni corsage ajusté ;
##   - chaque enfant a une pièce ample sur les hanches (jupe, tunique, djellaba, blouse) ;
##   - ni short, ni collant porté sans jupe ;
##   - les fiches de la réserve des figurants : les enfants de chaque style ont leur corps, et c'est un corps
##     d'enfant.
const NOM := "43_enfants"
const HAUTS := ["chemise_courte", "chemise_longue", "chemise_rentree", "tshirt", "pull", "tunique_haut", "djellaba_haut"]
const INTERDITS := ["corsage_nu", "debardeur", "corsage", "corsage_long", "short"]
const AMPLES := ["jupe", "jupe_longue", "tunique_bas", "djellaba_bas", "blouse_bas"]


func _serie() -> void:
	var C = load("res://scripts/pnj/corps_v64.gd")
	var G = load("res://scripts/pnj/maisons_habitants_v81.gd")
	var enfants: Dictionary = {}
	var sans_haut: Array = []
	var interdits: Array = []
	var sans_ample: Array = []
	var collants: Array = []
	var d := DirAccess.open(C.DIR)
	var fichiers: Array = []
	if d != null:
		for f in d.get_files():
			# (dans le jeu exporté, les fichiers portent parfois « .remap » ou « .import » en plus)
			var nom: String = str(f).trim_suffix(".remap")
			if nom.ends_with(".bin") and nom != "base.bin":
				fichiers.append(nom)
	for nom in fichiers:
		var b: Dictionary = C.read_bin(C.DIR + nom)
		var look: Dictionary = b.get("look", {})
		if not bool(look.get("enfant", false)):
			continue
		var id: String = str(nom).trim_suffix(".bin")
		var noms: Array = []
		for g in look.get("tenue", []):
			if g is Dictionary:
				noms.append(str((g as Dictionary).get("v", "")))
		enfants[id] = noms
		var a_haut: bool = false
		var a_ample: bool = false
		var a_jupe: bool = false
		for v in noms:
			if v in HAUTS:
				a_haut = true
			if v in AMPLES:
				a_ample = true
			if v in ["jupe", "jupe_longue", "djellaba_bas"]:
				a_jupe = true
			if v in INTERDITS:
				interdits.append("%s (%s)" % [id, v])
		if not a_haut:
			sans_haut.append(id)
		if not a_ample:
			sans_ample.append(id)
		if "collant" in noms and not a_jupe:
			collants.append(id)
	_ok(fichiers.size() > 1300 and enfants.size() > 130, "les corps du jeu relus (%d), dont %d enfants" % [fichiers.size(), enfants.size()])
	_ok(sans_haut.is_empty(), "chaque enfant a un haut couvrant%s" % _liste(sans_haut))
	_ok(interdits.is_empty(), "aucun enfant en haut sans manches, en corsage ajusté ni en short%s" % _liste(interdits))
	_ok(sans_ample.is_empty(), "chaque enfant a une pièce ample sur les hanches (jupe, tunique)%s" % _liste(sans_ample))
	_ok(collants.is_empty(), "aucun enfant en collant sans jupe%s" % _liste(collants))
	# la réserve des figurants : les enfants de chaque style (les rôles « garcon » et « fille ») sont bien des
	# corps d'enfant (les petits nains ont leur propre fiche : tunique et pantalon, ils ne comptent pas ici)
	var manquent: Array = []
	var n: int = 0
	for p in G.all_profiles():
		var android: bool = (p as Dictionary).has("neo") and bool(((p as Dictionary)["neo"] as Dictionary).get("android", false))
		if str(p.get("role", "")) in ["garcon", "fille"] and str(p.get("village", "")) != "nains" and not android:
			n += 1
			if not enfants.has(str(p["id"])):
				manquent.append(str(p["id"]))
	_ok(n >= 80 and manquent.is_empty(), "les %d enfants de la réserve des figurants ont un corps d'enfant%s" % [n, _liste(manquent)])


func _liste(a: Array) -> String:
	if a.is_empty():
		return ""
	return " ; pas : " + ", ".join(PackedStringArray(a.slice(0, 8))) + (" (et %d autres)" % (a.size() - 8) if a.size() > 8 else "")
