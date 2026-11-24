extends Node
## V205 : jouer debout ou assis, en VR. Le jeu prend la hauteur réelle du casque : assis dans un fauteuil,
## on se retrouvait à hauteur d'enfant. En posture « assis », le joueur est rehaussé pour que ses yeux
## soient à la hauteur d'un adulte debout (1,65 m). La rehausse est mesurée au moment du choix, là où est
## le casque : on la règle donc une fois bien installé dans son siège.
## Comment : le joueur VR (Joueur_VR) est posé sur un socle (main.socle_v205) ; on monte le socle. Tout ce
## qui tient au joueur (la tête, les mains, le menu, le rayon, la vue de dehors) monte avec lui, et le
## reste du jeu continue de régler la place des pieds comme avant.
## Menu > Paramètres > « Posture VR » : debout (au départ) ou assis.

const REGLAGES := "user://reglages_son.cfg"
const YEUX_DEBOUT := 1.65        # m : la hauteur des yeux qu'on donne au joueur assis
const REHAUSSE_MAX := 0.9        # m
const REHAUSSE_DEFAUT := 0.45    # m : si le casque ne donne pas encore sa hauteur

var main: Node
var assis: bool = false
var rehausse: float = REHAUSSE_DEFAUT


func setup(main_node: Node) -> void:
	main = main_node
	name = "Posture_VR_v205"
	var cfg := ConfigFile.new()
	if cfg.load(REGLAGES) == OK:
		assis = bool(cfg.get_value("vr", "assis", false))
		rehausse = clampf(float(cfg.get_value("vr", "rehausse", REHAUSSE_DEFAUT)), 0.0, REHAUSSE_MAX)
	main.add_child(self)
	appliquer()
	print("ILE_MANGA_V205: posture VR ", "assis (rehaussé de %d cm)" % int(round(rehausse * 100.0)) if assis else "debout")


func libelle() -> String:
	return ("Posture VR : assis (+%d cm)" % int(round(rehausse * 100.0))) if assis else "Posture VR : debout"


## La rehausse qu'il faut au joueur, d'après la hauteur de son casque au-dessus du sol de la pièce.
func mesurer(hauteur_casque: float) -> float:
	if hauteur_casque < 0.3:
		return REHAUSSE_DEFAUT
	return clampf(YEUX_DEBOUT - hauteur_casque, 0.0, REHAUSSE_MAX)


func basculer() -> void:
	assis = not assis
	if assis:
		var tete: Node3D = main.get("xr_camera")
		rehausse = mesurer(tete.position.y if tete != null else 0.0)
	var cfg := ConfigFile.new()
	cfg.load(REGLAGES)
	cfg.set_value("vr", "assis", assis)
	cfg.set_value("vr", "rehausse", rehausse)
	cfg.save(REGLAGES)
	appliquer()


func appliquer() -> void:
	var socle: Node3D = main.get("socle_v205")
	if socle != null:
		socle.position = Vector3(0.0, rehausse if assis else 0.0, 0.0)
