extends SceneTree
## Vérifie que des scripts du jeu se chargent sans erreur de syntaxe (ni dans leurs dépendances).
##     godot --headless --path pcvr --script res://../tests/outils/analyser_scripts.gd -- res://scripts/a.gd res://scripts/b.gd
## (lancé par tests/outils/analyser.sh, qui copie ce fichier dans la copie de travail)
## Affiche « OK chemin » ou « ÉCHEC chemin », puis « ANALYSE n échec(s) ».


func _initialize() -> void:
	var bad: int = 0
	for p in OS.get_cmdline_user_args():
		var s: Script = load(p)
		if s == null or not s.can_instantiate():
			print("ÉCHEC ", p)
			bad += 1
		else:
			print("OK ", p)
	print("ANALYSE %d échec(s)" % bad)
	quit(1 if bad > 0 else 0)
